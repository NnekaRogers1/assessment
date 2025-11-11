resource "aws_security_group" "mongodb" {
  name        = "mongodb-sg"
  description = "Security group for MongoDB VM"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from public internet"
  }
  
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "MongoDB"
  }
  
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound for updates and S3"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound for updates"
  }
  
  tags = {
    Name = "mongodb-sg"
  }
}

resource "aws_iam_role" "mongodb_instance" {
  name = "mongodb-instance-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "mongodb_perms" {
  name = "mongodb-permissions"
  role = aws_iam_role.mongodb_instance.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:RunInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.backup_bucket_name}",
          "arn:aws:s3:::${var.backup_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "mongodb" {
  name = "mongodb-instance-profile"
  role = aws_iam_role.mongodb_instance.name
}

data "aws_ami" "ubuntu_20" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.ubuntu_20.id
  instance_type          = "t3.medium"
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.mongodb.id]
  iam_instance_profile   = aws_iam_instance_profile.mongodb.name
  key_name               = var.key_name
  associate_public_ip_address = true
  
  ebs_optimized     = true
  monitoring        = true
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
  }
  
  user_data = templatefile("${path.module}/userdata.sh", {
    backup_bucket = var.backup_bucket_name
  })
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }
  
  tags = {
    Name = "mongodb-server"
  }
}

resource "aws_ec2_instance_connect_endpoint" "mongodb" {
  subnet_id          = var.public_subnet_ids[0]
  security_group_ids = [aws_security_group.mongodb.id]
  
  preserve_client_ip = false
  
  tags = {
    Name = "mongodb-eice"
  }
}