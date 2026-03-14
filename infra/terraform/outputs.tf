output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "alb_dns_name" {
  value = module.alb.dns_name
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "db_address" {
  value = module.rds.db_address
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}
