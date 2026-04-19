variable "name_prefix" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "github_token_secret_arn" {
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

variable "db_password_secret_arn" {
  type = string
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name_prefix}-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name               = "${var.name_prefix}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "task_inline" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      var.s3_bucket_arn,
      "${var.s3_bucket_arn}/*"
    ]
  }

  statement {
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      var.github_token_secret_arn,
      var.secret_key_base_secret_arn,
      var.active_record_encryption_primary_key_secret_arn,
      var.active_record_encryption_deterministic_key_secret_arn,
      var.active_record_encryption_key_derivation_salt_secret_arn,
      var.db_password_secret_arn
    ]
  }
}

resource "aws_iam_role_policy" "task_inline" {
  name   = "${var.name_prefix}-task-inline"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_inline.json
}

output "task_execution_role_arn" {
  value = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  value = aws_iam_role.task_role.arn
}
