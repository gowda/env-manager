# Terraform infrastructure (Milestone G)

This Terraform project provisions the core AWS infrastructure for deploying `env-manager` on ECS Fargate with RDS PostgreSQL.

## What it creates

- ECR repository for the Rails container image
- S3 bucket for environment file artifacts
- Secrets Manager secrets for GitHub token and Rails master key
- RDS PostgreSQL instance in private subnets
- Application Load Balancer (HTTP, optional HTTPS)
- ECS cluster, task definition, service, and autoscaling policy
- IAM roles/policies for ECS task execution and app runtime

## Requirements

- Terraform `>= 1.8.0`
- AWS provider `~> 5.80`
- Existing VPC and subnets

## Quick start

1. Copy the example vars file.
2. Fill values for your AWS account and network.
3. Initialize Terraform.
4. Plan and apply.

```bash
cp envs/dev.tfvars.example envs/dev.tfvars
terraform init
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars
```

## Required variables

- `name_prefix`
- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`
- `container_image`

All other variables have defaults and can be overridden as needed.

## Outputs

- `ecr_repository_url`
- `alb_dns_name`
- `s3_bucket_name`
- `db_address`
- `ecs_cluster_name`
- `ecs_service_name`

## Notes for ECS deployment

- Set `container_image` to a tag that exists in ECR.
- App container receives database and secret values through ECS task `environment` and `secrets`.
- ECS service security group accepts traffic only from the ALB security group.
