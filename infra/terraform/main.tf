provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_security_group" "ecs_service" {
  name   = "${var.name_prefix}-ecs-service"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ecs_service_ingress" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service.id
  source_security_group_id = module.alb.security_group_id
}

resource "aws_security_group_rule" "ecs_service_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service.id
}

module "ecr" {
  source      = "./modules/ecr"
  name_prefix = var.name_prefix
}

module "s3" {
  source         = "./modules/s3"
  name_prefix    = var.name_prefix
  s3_bucket_name = var.s3_bucket_name
}

module "secrets" {
  source                                                   = "./modules/secrets"
  github_token_secret_name                                 = var.github_token_secret_name
  secret_key_base_secret_name                              = var.secret_key_base_secret_name
  active_record_encryption_primary_key_secret_name         = var.active_record_encryption_primary_key_secret_name
  active_record_encryption_deterministic_key_secret_name   = var.active_record_encryption_deterministic_key_secret_name
  active_record_encryption_key_derivation_salt_secret_name = var.active_record_encryption_key_derivation_salt_secret_name
}

module "alb" {
  source            = "./modules/alb"
  name_prefix       = var.name_prefix
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  app_port          = var.app_port
  health_check_path = var.health_check_path
  certificate_arn   = var.certificate_arn
}

module "rds" {
  source                     = "./modules/rds"
  name_prefix                = var.name_prefix
  vpc_id                     = var.vpc_id
  private_subnet_ids         = var.private_subnet_ids
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  db_name                    = var.db_name
  db_username                = var.db_username
  allowed_security_group_ids = [aws_security_group.ecs_service.id]
}

module "iam" {
  source                                                  = "./modules/iam"
  name_prefix                                             = var.name_prefix
  s3_bucket_arn                                           = module.s3.bucket_arn
  github_token_secret_arn                                 = module.secrets.github_token_secret_arn
  secret_key_base_secret_arn                              = module.secrets.secret_key_base_secret_arn
  active_record_encryption_primary_key_secret_arn         = module.secrets.active_record_encryption_primary_key_secret_arn
  active_record_encryption_deterministic_key_secret_arn   = module.secrets.active_record_encryption_deterministic_key_secret_arn
  active_record_encryption_key_derivation_salt_secret_arn = module.secrets.active_record_encryption_key_derivation_salt_secret_arn
  db_password_secret_arn                                  = module.rds.db_password_secret_arn
}

module "ecs" {
  source                                                  = "./modules/ecs"
  name_prefix                                             = var.name_prefix
  private_subnet_ids                                      = var.private_subnet_ids
  service_security_group_id                               = aws_security_group.ecs_service.id
  app_port                                                = var.app_port
  desired_count                                           = var.desired_count
  min_capacity                                            = var.min_capacity
  max_capacity                                            = var.max_capacity
  cpu                                                     = var.cpu
  memory                                                  = var.memory
  container_image                                         = var.container_image
  target_group_arn                                        = module.alb.target_group_arn
  task_execution_role_arn                                 = module.iam.task_execution_role_arn
  task_role_arn                                           = module.iam.task_role_arn
  db_host                                                 = module.rds.db_address
  db_name                                                 = var.db_name
  db_username                                             = var.db_username
  db_password_secret_arn                                  = module.rds.db_password_secret_arn
  github_token_secret_arn                                 = module.secrets.github_token_secret_arn
  secret_key_base_secret_arn                              = module.secrets.secret_key_base_secret_arn
  active_record_encryption_primary_key_secret_arn         = module.secrets.active_record_encryption_primary_key_secret_arn
  active_record_encryption_deterministic_key_secret_arn   = module.secrets.active_record_encryption_deterministic_key_secret_arn
  active_record_encryption_key_derivation_salt_secret_arn = module.secrets.active_record_encryption_key_derivation_salt_secret_arn
}
