locals {
  # One entry per subnet. The key (e.g. public_a) becomes part of each
  # subnet's Terraform address, so never rename a key once it's applied.
  subnets = {
    public_a = {
      type   = "public"
      az     = "eu-west-2a"
      netnum = 1
    }
    public_b = {
      type   = "public"
      az     = "eu-west-2b"
      netnum = 2
    }
    private_a = {
      type   = "private"
      az     = "eu-west-2a"
      netnum = 3
    }
    private_b = {
      type   = "private"
      az     = "eu-west-2b"
      netnum = 4
    }
  }
}