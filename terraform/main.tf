terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  
  backend "s3" {
    bucket = "state-bucket001"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
  
  skip_credentials_validation = true
  skip_metadata_api_check    = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  
  default_tags {
    tags = {
      Project     = "devsecops-assessment"
      Environment = var.environment
    }
  }
}

resource "tls_private_key" "mongodb_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "mongodb_key" {
  key_name   = "${var.environment}-mongodb-key"
  public_key = tls_private_key.mongodb_key.public_key_openssh

  tags = {
    Name = "${var.environment}-mongodb-key"
  }
}

module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  cluster_name       = var.cluster_name
}

module "mongodb_vm" {
  source = "./modules/mongodb"
  
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  key_name          = aws_key_pair.mongodb_key.key_name
  backup_bucket_name = var.backup_bucket_name
  
  depends_on = [module.vpc, aws_key_pair.mongodb_key]
}

module "backup_bucket" {
  source = "./modules/s3"
  
  bucket_name = var.backup_bucket_name
}

module "eks" {
  source = "./modules/eks"
  
  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "security" {
  source = "./modules/security"
  
  environment = var.environment
}

module "ecr" {
  source = "./modules/ecr"
  
  repository_name = var.ecr_repository_name
  environment     = var.environment
}
