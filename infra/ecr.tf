resource "aws_ecr_repository" "headercheck_ecr" {

  name                 = "headercheck"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

}

import {
  to = aws_ecr_repository.headercheck_ecr
  id = "headercheck"
}