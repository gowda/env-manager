variable "github_token_secret_name" {
  type = string
}

variable "rails_master_key_secret_name" {
  type = string
}

resource "aws_secretsmanager_secret" "github_token" {
  name = var.github_token_secret_name
}

resource "aws_secretsmanager_secret" "rails_master_key" {
  name = var.rails_master_key_secret_name
}

output "github_token_secret_arn" {
  value = aws_secretsmanager_secret.github_token.arn
}

output "rails_master_key_secret_arn" {
  value = aws_secretsmanager_secret.rails_master_key.arn
}
