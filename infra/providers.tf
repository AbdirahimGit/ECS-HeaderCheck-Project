terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      ##specify the version of the AWS provider you want to use
      version = "~> 6.0"
    }
  }

  backend "s3" {
    ##specify the S3 bucket name and key for storing the Terraform state file
    bucket       = "headercheck-tfstate-951662620871"
    key          = "headercheck/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }

}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      environment = "prod"
      project     = "headercheck"
      managedby   = "Terraform"
    }
  }
}

