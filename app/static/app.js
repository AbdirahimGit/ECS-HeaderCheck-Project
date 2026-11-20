// HeaderCheck front-end behaviour. Kept in its own file (not inline in
// index.html) so the Content-Security-Policy can block all inline scripts.

// Grab the elements we need to change
const form = document.getElementById("form");
const input = document.getElementById("url");
const button = document.getElementById("go");
const errorBox = document.getElementById("error");
const report = document.getElementById("report");

// Runs when the user clicks "Check site" or presses Enter
form.addEventListener("submit", async (event) => {
  event.preventDefault();  // stop the browser reloading the page

  const url = input.value.trim();
  if (!url) {
    showError("Enter a website address.");
    return;
  }

  button.disabled = true;
  button.textContent = "Checking…";
  errorBox.classList.add("hidden");

  try {
    // Call our own backend: GET /check?url=...
    const response = await fetch("/check?url=" + encodeURIComponent(url));
    const data = await response.json();

    if (!response.ok) {
      // The backend sends {"detail": "..."} when something is wrong.
      // For validation errors "detail" is a list, so use a generic message.
      showError(typeof data.detail === "string" ? data.detail : "That address wasn't valid.");
      return;
    }
    showReport(data);
  } catch (err) {
    showError("Couldn't reach the server. Try again.");
  } finally {
    // Always runs, whether it worked or not
    button.disabled = false;
    button.textContent = "Check site";
  }
});

function showError(message) {
  report.classList.add("hidden");
  errorBox.textContent = message;  // textContent is safe: it never runs HTML
  errorBox.classList.remove("hidden");
}

function showReport(data) {
  document.getElementById("grade").textContent = data.grade;
  document.getElementById("score").textContent = data.score + " of " + data.total;
  document.getElementById("cert").textContent =
    data.cert_days_left === null ? "Unavailable" : data.cert_days_left + " days";

  // Rebuild the list of headers from the JSON the backend returned
  const list = document.getElementById("list");
  list.replaceChildren();
  for (const item of data.results) {
    const row = document.createElement("div");
    row.className = "row";

    const top = document.createElement("div");
    top.className = "row-top";

    const name = document.createElement("span");
    name.className = "name";
    name.textContent = item.header;

    const badge = document.createElement("span");
    badge.className = "badge " + (item.present ? "ok" : "missing");
    badge.textContent = item.present ? "Present" : "Missing";

    top.append(name, badge);
    row.append(top);

    // Only missing headers get an explanation of why they matter
    if (!item.present) {
      const hint = document.createElement("p");
      hint.className = "hint";
      hint.textContent = item.description;
      row.append(hint);
    }
    list.append(row);
  }

  errorBox.classList.add("hidden");
  report.classList.remove("hidden");
}
