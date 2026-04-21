variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_port" {
  type    = number
  default = 80
}

variable "container_image" {
  type = string
}

variable "health_check_path" {
  type    = string
  default = "/up"
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 6
}

variable "cpu" {
  type    = number
  default = 512
}

variable "memory" {
  type    = number
  default = 1024
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "env_manager"
}

variable "db_username" {
  type    = string
  default = "envmanager"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "certificate_arn" {
  type    = string
  default = null
}

variable "environment_file_object_arns" {
  type        = list(string)
  description = "Ordered list of S3 object ARNs used as ECS environment files."

  validation {
    condition     = length(var.environment_file_object_arns) > 0
    error_message = "Provide at least one S3 environment file object ARN."
  }
}

variable "s3_bucket_name" {
  type    = string
  default = null
}
