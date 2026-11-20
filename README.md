# HeaderCheck

A security-header auditing service, deployed on AWS with ECS Fargate.

Give it a website and it checks six key HTTP security headers, reads the TLS certificate's expiry date, and returns a grade.

**Live:** https://tm.abdirahimabdi.co.uk

<!-- TODO: screenshot of a result page, e.g. screenshots/result.png -->

---

## Architecture

Adding at the end

| Layer | What's used | Why |
|---|---|---|
| App | Python, FastAPI, uvicorn | Small, fast, with a dedicated `/health` route for the load balancer |
| Container | Multi-stage Docker build, base image pinned by digest, non-root user | Small, reproducible images with a reduced attack surface |
| Registry | Amazon ECR, images tagged with the Git commit | Every running version traces back to an exact commit |
| Compute | ECS on Fargate, 2 tasks across 2 AZs | No servers to manage; survives a task failure |
| Network | VPC, public and private subnets, NAT gateway | Containers have no public IPs and can't be reached from the internet |
| Load balancing | Application Load Balancer, TLS terminated with ACM | One stable HTTPS entry point; health checks route only to healthy tasks |
| DNS | Domain at Porkbun, delegated to Route 53, alias record to the ALB | The alias follows the ALB's changing IPs |
| Infrastructure as code | *TODO: Terraform* | |
| CI/CD | *TODO: GitHub Actions* | |

---

## Security

### Security headers this app sends

A security-header checker should pass its own test. Every response includes:

| Header | Value | Protects against |
|---|---|---|
| Strict-Transport-Security | `max-age=31536000` | Being downgraded to unencrypted HTTP |
| Content-Security-Policy | `default-src 'self'; script-src 'self'; ...` | Injected scripts (cross-site scripting) |
| X-Frame-Options | `DENY` | The page being hidden inside another site (clickjacking) |
| X-Content-Type-Options | `nosniff` | The browser guessing file types |
| Referrer-Policy | `no-referrer` | Page addresses leaking to other sites |
| Permissions-Policy | `camera=(), microphone=(), geolocation=()` | Silent use of the camera, microphone or location |

HeaderCheck grades its own domain **A**.

<!-- TODO: screenshot of HeaderCheck grading tm.abdirahimabdi.co.uk -->

**Design decision: no inline code.** A strict Content-Security-Policy blocks inline `<style>` and `<script>`. Rather than weakening the policy with `'unsafe-inline'`, the CSS and JavaScript live in `app/static/`. The auto-generated `/docs` pages are disabled, because they load scripts from an external CDN and a public service doesn't need to publish its API docs.

### Application

- **SSRF protection:** the app fetches URLs that strangers type in, so every address, and every redirect target, is checked against private and internal ranges (including the instance metadata endpoint) before it's fetched. Only ports 80 and 443 are allowed.
- **Timeouts:** each fetch gives up after 5 seconds, so a slow or unresponsive site can't tie up the service.
- **Bounded work:** only headers are read, never the page body, and redirects are capped.

### Network

- **Private subnets:** tasks have no public IPs and no inbound route from the internet. Outbound traffic goes through a NAT gateway.
- **Least-privilege security groups:**
  - ALB: inbound TCP 80 and 443 from anywhere
  - Tasks: inbound TCP 8080 **only from the ALB's security group**, referenced by group rather than IP

Together, these are defence in depth: one mistake in either layer doesn't expose the containers.

---

## How a change gets deployed

Every change follows the same flow, tracked in [GitHub Issues](https://github.com/AbdirahimGit/ECS-HeaderCheck-Project/issues):

1. Open an issue with acceptance criteria
2. Create a branch named after it, e.g. `1-security-headers`
3. Make the change and test locally
4. Open a pull request with `Closes #N`, review, and merge into `main`
5. Build the image for `linux/amd64` and tag it with the merge commit
6. Push the image to ECR
7. Register a new task definition revision and update the ECS service
8. The rolling deployment starts new tasks, waits for health checks, then retires the old ones. The deployment circuit breaker rolls back automatically if new tasks keep failing.
9. Verify on the live site and close out the issue

Steps 5 to 8 are currently manual. *TODO: automate with a CI/CD pipeline.*

---

## Incidents

Real problems hit while building this, with diagnosis and fixes:

<!-- TODO: check these issue numbers match your board -->
- [Tasks failed with `CannotPullContainerError: not found`](https://github.com/AbdirahimGit/ECS-HeaderCheck-Project/issues/10): wrong image tag in the task definition
- [ALB returned 504, all targets unhealthy](https://github.com/AbdirahimGit/ECS-HeaderCheck-Project/issues/11): security group inbound rule on port 0 instead of 8080
- [Domain didn't resolve after creating the DNS record](https://github.com/AbdirahimGit/ECS-HeaderCheck-Project/issues/12): negative DNS caching

The lesson running through all three: before changing anything, work out whether something answered. An answer points to what was requested; silence points to the network path.

---

## Running locally

```bash
cd app
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --port 8080
```

Then open http://localhost:8080.

---

## Infrastructure as code

*TODO: Terraform setup and usage.*

## CI/CD

*TODO: GitHub Actions pipeline.*

## Running costs

*TODO: estimated monthly cost (ALB, NAT gateway, Fargate tasks, Route 53).*

## Project board

Planned and completed work: *TODO: link to the GitHub Project board.*
