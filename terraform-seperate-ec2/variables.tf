variable "region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type_backend" {
  description = "Instance type for backend EC2"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_frontend" {
  description = "Instance type for frontend EC2"
  type        = string
  default     = "t3.micro"
}

variable "ami" {
  description = "AMI ID for the EC2 instances (Amazon Linux 2023 recommended)"
  type        = string
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "allowed_cidr" {
  description = "CIDR allowed to access servers"
  type        = string
  default     = "0.0.0.0/0"
}
