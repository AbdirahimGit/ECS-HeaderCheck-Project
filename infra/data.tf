# Look up the existing ACM certificate for the tm. subdomain (managed outside Terraform).
# The "most_recent" argument is set to true to ensure that the most recent certificate is retrieved.
data "aws_acm_certificate" "headercheck_cert" {
  domain      = "tm.abdirahimabdi.co.uk"
  statuses    = ["ISSUED"]
  most_recent = true
}
