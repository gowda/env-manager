variable "name_prefix" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "service_security_group_id" {
  type = string
}

variable "app_port" {
  type = number
}

variable "desired_count" {
  type = number
}

variable "min_capacity" {
  type = number
}

variable "max_capacity" {
  type = number
}

variable "cpu" {
  type = number
}

variable "memory" {
  type = number
}

variable "container_image" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password_secret_arn" {
  type = string
}

variable "secret_key_base_secret_arn" {
  type = string
}

variable "active_record_encryption_primary_key_secret_arn" {
  type = string
}

variable "active_record_encryption_deterministic_key_secret_arn" {
  type = string
}

variable "active_record_encryption_key_derivation_salt_secret_arn" {
  type = string
}

variable "github_token_secret_arn" {
  type = string
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = 30
}

locals {
  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "RAILS_ENV", value = "production" },
        { name = "DB_HOST", value = var.db_host },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USERNAME", value = var.db_username }
      ]
      secrets = [
        { name = "DB_PASSWORD", valueFrom = var.db_password_secret_arn },
        { name = "SECRET_KEY_BASE", valueFrom = var.secret_key_base_secret_arn },
        { name = "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY", valueFrom = var.active_record_encryption_primary_key_secret_arn },
        { name = "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY", valueFrom = var.active_record_encryption_deterministic_key_secret_arn },
        { name = "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT", valueFrom = var.active_record_encryption_key_derivation_salt_secret_arn },
        { name = "GITHUB_TOKEN", valueFrom = var.github_token_secret_arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])
}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn
  container_definitions    = local.container_definitions
}

resource "aws_ecs_service" "app" {
  name            = "${var.name_prefix}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.service_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.app_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.name_prefix}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}
