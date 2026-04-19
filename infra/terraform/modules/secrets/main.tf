variable "github_token_secret_name" {
  type = string
}

variable "secret_key_base_secret_name" {
  type = string
}

variable "active_record_encryption_primary_key_secret_name" {
  type = string
}

variable "active_record_encryption_deterministic_key_secret_name" {
  type = string
}

variable "active_record_encryption_key_derivation_salt_secret_name" {
  type = string
}

resource "aws_secretsmanager_secret" "github_token" {
  name = var.github_token_secret_name
}

resource "aws_secretsmanager_secret" "secret_key_base" {
  name = var.secret_key_base_secret_name
}

resource "aws_secretsmanager_secret" "active_record_encryption_primary_key" {
  name = var.active_record_encryption_primary_key_secret_name
}

resource "aws_secretsmanager_secret" "active_record_encryption_deterministic_key" {
  name = var.active_record_encryption_deterministic_key_secret_name
}

resource "aws_secretsmanager_secret" "active_record_encryption_key_derivation_salt" {
  name = var.active_record_encryption_key_derivation_salt_secret_name
}

output "github_token_secret_arn" {
  value = aws_secretsmanager_secret.github_token.arn
}

output "secret_key_base_secret_arn" {
  value = aws_secretsmanager_secret.secret_key_base.arn
}

output "active_record_encryption_primary_key_secret_arn" {
  value = aws_secretsmanager_secret.active_record_encryption_primary_key.arn
}

output "active_record_encryption_deterministic_key_secret_arn" {
  value = aws_secretsmanager_secret.active_record_encryption_deterministic_key.arn
}

output "active_record_encryption_key_derivation_salt_secret_arn" {
  value = aws_secretsmanager_secret.active_record_encryption_key_derivation_salt.arn
}
