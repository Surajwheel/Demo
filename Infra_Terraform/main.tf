# ============================================================================
# AWS EC2 TERRAFORM CONFIGURATION FOR K3D
# Deploy EC2 instance ready for k3d Kubernetes
# ============================================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================================
# VPC and Network Configuration
# ============================================================================

resource "aws_vpc" "k3d_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "k3d_igw" {
  vpc_id = aws_vpc.k3d_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "k3d_subnet" {
  vpc_id                  = aws_vpc.k3d_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet"
  }
}

resource "aws_route_table" "k3d_rt" {
  vpc_id = aws_vpc.k3d_vpc.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.k3d_igw.id
  }

  tags = {
    Name = "${var.project_name}-rt"
  }
}

resource "aws_route_table_association" "k3d_rta" {
  subnet_id      = aws_subnet.k3d_subnet.id
  route_table_id = aws_route_table.k3d_rt.id
}

# ============================================================================
# Security Group
# ============================================================================

resource "aws_security_group" "k3d_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for k3d cluster"
  vpc_id      = aws_vpc.k3d_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # Custom ports for microservices
  ingress {
    from_port   = 3000
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Egress - Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# ============================================================================
# Data Source for AMI
# ============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================================
# EC2 Instance
# ============================================================================

resource "aws_instance" "k3d_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.k3d_subnet.id
  vpc_security_group_ids = [aws_security_group.k3d_sg.id]
  
  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  # Use key pair if provided
  key_name = var.key_pair_name != "" ? var.key_pair_name : null

  # User data script
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    prerequisites_script = file("${path.module}/prerequisites.sh")
  }))

  monitoring              = true
  iam_instance_profile    = aws_iam_instance_profile.k3d_profile.name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-instance"
  }

  depends_on = [
    aws_internet_gateway.k3d_igw
  ]
}

# ============================================================================
# IAM Role and Instance Profile
# ============================================================================

resource "aws_iam_role" "k3d_role" {
  name = "${var.project_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "k3d_policy" {
  name = "${var.project_name}-policy"
  role = aws_iam_role.k3d_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "k3d_profile" {
  name = "${var.project_name}-profile"
  role = aws_iam_role.k3d_role.name
}

# ============================================================================
# Outputs
# ============================================================================

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.k3d_instance.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.k3d_instance.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.k3d_instance.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh -i /path/to/key.pem ubuntu@${aws_instance.k3d_instance.public_ip}"
}

output "k3d_setup_command" {
  description = "Command to setup k3d cluster"
  value       = "cd /home/ubuntu/k3d-microservices && ./setup-k3d-cluster.sh"
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.k3d_sg.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.k3d_vpc.id
}

