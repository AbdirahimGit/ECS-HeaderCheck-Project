locals {
  # Naming prefix used by every resource in this module, e.g. "headercheck-prod"
  name_prefix = "${var.project_name}-${var.environment}"

  # Must be identical in the task definition and the service's load_balancer block,
  # otherwise the service can't attach to the target group
  container_name = "${local.name_prefix}-container"

  # Must match the port the app listens on (Dockerfile), the target group, and the tasks SG
  container_port = 8080
}