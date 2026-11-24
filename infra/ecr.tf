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

resource "aws_ecr_lifecycle_policy" "headercheck_ecr_lifecycle_policy" {
  repository = aws_ecr_repository.headercheck_ecr.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the last 10 tagged images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*"]
          countType      = "imageCountMoreThan"
          countNumber    = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
