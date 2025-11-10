output "mongodb_private_ip" {
  value       = module.mongodb_vm.private_ip
  description = "Private IP of MongoDB VM"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL for tasky images"
}

output "ecr_repository_name" {
  value       = module.ecr.repository_name
  description = "ECR repository name"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "List of public subnet IDs for ALB"
}

output "mongodb_private_key" {
  value       = tls_private_key.mongodb_key.private_key_pem
  description = "Private key for MongoDB SSH access (save this securely)"
  sensitive   = true
}

output "mongodb_key_name" {
  value       = aws_key_pair.mongodb_key.key_name
  description = "Name of the AWS key pair for MongoDB SSH access"
}

