resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"
  
  tags = {
    Name = "${var.repository_name}-ecr"
  }
}

