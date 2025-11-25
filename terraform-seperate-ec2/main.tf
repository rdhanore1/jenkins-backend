terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# -----------------------------
# VPC
# -----------------------------
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "project-vpc"
  }
}

# -----------------------------
# PUBLIC SUBNET
# -----------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# -----------------------------
# INTERNET GATEWAY
# -----------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "project-igw" }
}

# -----------------------------
# PUBLIC ROUTE TABLE
# -----------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

# -----------------------------
# SECURITY GROUP - BACKEND
# -----------------------------
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Backend Flask security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "backend-sg" }
}

# -----------------------------
# SECURITY GROUP - FRONTEND
# -----------------------------
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Frontend Express security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "frontend-sg" }
}

# Allow frontend to talk to backend
resource "aws_security_group_rule" "frontend_to_backend" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_sg.id
  source_security_group_id = aws_security_group.frontend_sg.id
}

# -----------------------------
# BACKEND EC2
# -----------------------------
resource "aws_instance" "backend" {
  ami                         = var.ami
  instance_type               = var.instance_type_backend
  subnet_id                   = aws_subnet.public.id
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]

  user_data = file("${path.module}/backend_user_data.sh")

  tags = { Name = "backend-instance" }
}

# -----------------------------
# FRONTEND EC2
# -----------------------------
resource "aws_instance" "frontend" {
  ami                         = var.ami
  instance_type               = var.instance_type_frontend
  subnet_id                   = aws_subnet.public.id
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]

  user_data = file("${path.module}/frontend_user_data.sh")

  tags = { Name = "frontend-instance" }
}
