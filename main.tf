provider "aws" {
  region = "eu-central-1"
}

# ---
# Variables
# ---

variable "aws_key_pair_name" {
  description = "ssh key"
  type        = string
  default     = "terraform-crud-app"
}

variable "ami_id" {
  description = "aws ami id for ec2"
  type        = string
  default     = "ami-02003f9f0fde924ea"
}

variable "instance_type" {
  description = "type of ec2"
  type        = string
  default     = "t2.micro"
}

variable "my_ip_address" {
  description = "your puplic ip4 addres"
  type        = string
  default     = "93.159.2.113/32"
}

# ---
# Resources
# ---

# Security Group for EC2
# Open ports
resource "aws_security_group" "crud_app_sg" {
  name        = "crud-app-security-group"
  description = "Security group for CRUD App with PostgreSQL and Spring Boot"

  # Inbound/Ingress
  ingress {
    description = "SSH access from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address] 
  }

  ingress {
    description = "PostgreSQL access from your IP (for pgAdmin)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }

  ingress {
    description = "Spring Boot App access from anywhere"
    from_port   = 9080
    to_port     = 9080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound/Egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "crud-app-sg"
  }
}

# EC2 instace, host for docker containers
resource "aws_instance" "crud_app_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.aws_key_pair_name
  vpc_security_group_ids      = [aws_security_group.crud_app_sg.id] # Security Group created before
  associate_public_ip_address = true 

  # User data 
  # Install Docker & Docker Compose
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y docker.io docker-compose git
              sudo usermod -aG docker ubuntu
              newgrp docker 
              EOF

  tags = {
    Name = "crud-app-docker-host"
  }
}

# ---
# Outputs
# ---

# Show public ip4
output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.crud_app_ec2.public_ip
}

# Show ssh command to connect with
output "ssh_connection_string" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ~/.ssh/${var.aws_key_pair_name}.pem ubuntu@${aws_instance.crud_app_ec2.public_ip}"
}
