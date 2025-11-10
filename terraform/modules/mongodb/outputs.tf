output "public_ip" {
  description = "Public IP address of the MongoDB instance"
  value       = aws_instance.mongodb.public_ip
}

output "private_ip" {
  description = "Private IP address of the MongoDB instance"
  value       = aws_instance.mongodb.private_ip
}

output "instance_id" {
  description = "Instance ID of the MongoDB instance"
  value       = aws_instance.mongodb.id
}

output "instance_connect_endpoint_id" {
  description = "EC2 Instance Connect Endpoint ID for SSH access"
  value       = aws_ec2_instance_connect_endpoint.mongodb.id
}

output "instance_connect_endpoint_dns_name" {
  description = "EC2 Instance Connect Endpoint DNS name"
  value       = aws_ec2_instance_connect_endpoint.mongodb.dns_name
}

