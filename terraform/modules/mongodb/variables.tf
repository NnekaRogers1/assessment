variable "vpc_id" {
  description = "VPC ID where the MongoDB instance will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the MongoDB instance"
  type        = list(string)
}

variable "key_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
}

variable "backup_bucket_name" {
  description = "Name of the S3 bucket for MongoDB backups"
  type        = string
  default     = ""
}

