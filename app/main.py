"""
HeaderCheck - a tiny website security-headers checker.

What it does:
    You give it a website address. It fetches the site, looks at the HTTP
    response headers, checks for six important security headers, reads the
    HTTPS certificate expiry date, and returns a grade plus a pass/fail list.

Routes:
    GET /              the web page (index.html)
    GET /health        health check for the load balancer -> {"status": "ok"}
    GET /check?url=..  runs the audit and returns JSON
    GET /docs          free auto-generated API docs (FastAPI feature)

Run locally:
    pip install -r requirements.txt
    uvicorn main:app --host 0.0.0.0 --port 8080
Then open http://localhost:8080
"""

# --- Imports -----------------------------------------------------------------
# Standard library (nothing to install)
import ipaddress  # understands IP addresses and can tell if one is private/internal
import socket     # DNS lookups and raw network connections
import ssl        # TLS support, used to read the site's HTTPS certificate
import time       # current time, used for certificate expiry maths
from pathlib import Path
from urllib.parse import urlparse  # splits a URL into scheme, host, port, etc.

# Third-party (listed in requirements.txt)
import httpx  # HTTP client used to fetch the website being checked
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import FileResponse

# --- App and settings --------------------------------------------------------
# This object is the web application. uvicorn runs it.
app = FastAPI(
    title="HeaderCheck",
    description="Checks a website's security headers and HTTPS certificate.",
    version="1.0.0",
)

TIMEOUT_SECONDS = 5   # give up on slow sites, so one request can't hang the container
MAX_REDIRECTS = 3     # how many redirects we're willing to follow by hand
ALLOWED_PORTS = {None, 80, 443}  # None means "no port in the URL", i.e. the default

# Path to the web page, found relative to this file so it works from any folder
HTML_FILE = Path(__file__).parent / "index.html"

# The six headers we look for, each with a plain-English explanation that the
# web page shows when a header is missing.
SECURITY_HEADERS = {
    "Strict-Transport-Security": "Forces browsers to use HTTPS, which stops downgrade attacks.",
    "Content-Security-Policy": "Limits where scripts and styles can load from, which helps block cross-site scripting.",
    "X-Frame-Options": "Stops other sites embedding this page in a frame, which prevents clickjacking.",
    "X-Content-Type-Options": "Stops browsers guessing file types, which blocks some injection tricks.",
    "Referrer-Policy": "Controls how much of the page address is shared with other sites.",
    "Permissions-Policy": "Controls which browser features, like camera or location, the page can use.",
}

# Number of headers present -> letter grade. Change these to make it stricter.
GRADES = {6: "A", 5: "A", 4: "B", 3: "C", 2: "D"}


# --- Step 1: tidy up the URL the user typed ----------------------------------
def normalise_url(raw: str) -> str:
    """Turn 'example.com' into 'https://example.com'."""
    raw = raw.strip()
    if "://" not in raw:
        raw = "https://" + raw
    return raw


# --- Step 2: SSRF protection -------------------------------------------------
# SSRF (server-side request forgery): this app fetches URLs that strangers type
# in. Without a check, someone could enter an internal address (like
# http://169.254.169.254, which on AWS hands out credentials) and use our
# server to look inside our network. So before every fetch we make sure the
# address points at the public internet.
def assert_public_url(url: str) -> None:
    """Raise ValueError unless the URL is a normal public web address."""
    parsed = urlparse(url)

    # Only web addresses. Blocks file://, ftp://, gopher:// and similar.
    if parsed.scheme not in ("http", "https"):
        raise ValueError("Only http and https addresses are allowed.")
    if not parsed.hostname:
        raise ValueError("That doesn't look like a valid address.")

    # Only the standard web ports, so the tool can't be used to probe other
    # services (like databases) on a host.
    try:
        port = parsed.port
    except ValueError:
        raise ValueError("That doesn't look like a valid address.") from None
    if port not in ALLOWED_PORTS:
        raise ValueError("Only the standard web ports (80 and 443) are allowed.")

    # Turn the hostname into IP addresses. A name can have several, so we
    # check all of them.
    try:
        results = socket.getaddrinfo(parsed.hostname, port or 443)
    except socket.gaierror:
        raise ValueError("Couldn't find that website. Check the address.") from None

    for result in results:
        ip = ipaddress.ip_address(result[4][0])
        # An IPv6 address can wrap an IPv4 one (::ffff:127.0.0.1). Unwrap it
        # so it can't be used to sneak past the checks.
        if ip.version == 6 and ip.ipv4_mapped:
            ip = ip.ipv4_mapped
        # is_global is False for private ranges (10.x, 192.168.x), loopback
        # (127.x), link-local (169.254.x), reserved and similar internal ranges.
        if not ip.is_global or ip.is_multicast:
            raise ValueError("That address points to a private or internal network, so it can't be checked.")


# --- Step 3: fetch the site and collect its headers --------------------------
def fetch_headers(url: str):
    """
    Request the site and return (status code, headers, final URL).

    We follow redirects ourselves, one at a time, instead of letting the HTTP
    library do it. That way every redirect target is checked by
    assert_public_url too. Otherwise a public site could redirect us to an
    internal address and bypass the protection.
    """
    for _ in range(MAX_REDIRECTS + 1):
        assert_public_url(url)

        # stream() reads only the status and headers. We never download the
        # body, so a huge page can't eat our memory or time.
        with httpx.stream(
            "GET",
            url,
            timeout=TIMEOUT_SECONDS,
            follow_redirects=False,
            headers={"User-Agent": "HeaderCheck/1.0"},
        ) as response:
            if response.is_redirect:
                # Work out the next address (it may be relative) and go round again
                url = str(response.url.join(response.headers["location"]))
                continue
            # Lowercase the names because header names are case-insensitive
            headers = {name.lower(): value for name, value in response.headers.items()}
            return response.status_code, headers, url

    raise ValueError("That website redirected too many times.")


# --- Step 4: read the HTTPS certificate --------------------------------------
def get_cert_days_left(url: str):
    """Return the number of days until the HTTPS certificate expires, or None."""
    parsed = urlparse(url)
    if parsed.scheme != "https" or not parsed.hostname:
        return None  # plain http has no certificate to read
    try:
        context = ssl.create_default_context()  # also verifies the certificate is valid
        with socket.create_connection((parsed.hostname, 443), timeout=TIMEOUT_SECONDS) as sock:
            with context.wrap_socket(sock, server_hostname=parsed.hostname) as tls:
                cert = tls.getpeercert()
        expires_at = ssl.cert_time_to_seconds(cert["notAfter"])  # seconds since 1970
        return int((expires_at - time.time()) // 86400)          # 86400 seconds per day
    except (OSError, ssl.SSLError, KeyError):
        return None  # couldn't read it (or it's invalid); the page shows "unavailable"


# --- Step 5: score the headers -----------------------------------------------
# This function is pure: headers in, report out, no network. That makes it easy
# to test on its own.
def analyse_headers(headers: dict) -> dict:
    """Compare the headers we got against our list and build the report."""
    present_names = {name.lower() for name in headers}
    results = []
    for name, description in SECURITY_HEADERS.items():
        results.append({
            "header": name,
            "present": name.lower() in present_names,
            "description": description,
        })
    score = sum(1 for item in results if item["present"])
    return {
        "grade": GRADES.get(score, "F"),
        "score": score,
        "total": len(SECURITY_HEADERS),
        "results": results,
    }


# --- Routes ------------------------------------------------------------------
# These are plain `def` (not `async def`) on purpose: they make blocking
# network calls, and FastAPI runs plain functions in a thread pool so they
# don't freeze the whole server.

@app.get("/health")
def health():
    """Health check. The load balancer calls this to see if the container is alive."""
    return {"status": "ok"}


@app.get("/check")
def check(url: str = Query(..., min_length=3, max_length=2048, description="Website to check, e.g. example.com")):
    """Run the audit on the given website and return the report as JSON."""
    target = normalise_url(url)
    try:
        status_code, headers, final_url = fetch_headers(target)
    except ValueError as error:
        # Our own checks failed (bad URL, private address, too many redirects).
        # 400 means "your request was wrong".
        raise HTTPException(status_code=400, detail=str(error))
    except (httpx.HTTPError, httpx.InvalidURL):
        # The site didn't answer, timed out, or refused us. 502 means "the
        # site we tried to reach had a problem".
        raise HTTPException(status_code=502, detail="Couldn't reach that website.")

    report = analyse_headers(headers)
    report["url"] = final_url
    report["status_code"] = status_code
    report["cert_days_left"] = get_cert_days_left(final_url)
    return report


@app.get("/", include_in_schema=False)
def home():
    """Serve the web page."""
    return FileResponse(HTML_FILE)