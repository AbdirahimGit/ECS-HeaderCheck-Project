resource "aws_ecs_cluster" "headercheck_ecs_cluster" {
  name = "${local.name_prefix}-ecs-cluster"
}

resource "aws_cloudwatch_log_group" "headercheck_ecs_log_group" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 7
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.name_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "headercheck_ecs_task_definition" {
  family                   = "${local.name_prefix}-ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn # execution role for the ECS task (allows pulling images from ECR and writing logs to CloudWatch)

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64" # Must match docker build --platform linux/amd64.
  }

  container_definitions = jsonencode([{
    name         = local.container_name
    image        = "${var.ecr_repository_url}:${var.ecr_image_tag}"
    portMappings = [{ containerPort = local.container_port, protocol = "tcp" }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.headercheck_ecs_log_group.name # log group's name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = local.name_prefix
      }
    }
  }])
}

resource "aws_ecs_service" "headercheck_ecs_service" {
  name            = "${local.name_prefix}-ecs-service"
  cluster         = aws_ecs_cluster.headercheck_ecs_cluster.id # cluster's id
  task_definition = aws_ecs_task_definition.headercheck_ecs_task_definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids      # private subnets for the tasks (one per AZ)
    security_groups  = [var.ecs_security_group_id] # security group for the tasks (allows 8080 from the ALB only)
    assign_public_ip = false                       # false because the tasks go through the NAT gateway to reach the internet, not directly
  }

  load_balancer {
    target_group_arn = var.load_balancer_target_group_arn # the ALB target group for the ECS service
    container_name   = local.container_name
    container_port   = local.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}