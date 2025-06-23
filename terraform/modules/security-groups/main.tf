variable "env" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security groups will be created"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

locals {
  common_tags = {
    Environment = var.env
    Project     = "eks-cluster"
    Owner       = "DevOps"
  }
}

# EKS Node Group SG
resource "aws_security_group" "eks_nodes" {
  name        = "${var.env}-eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all traffic from other nodes (cluster)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.env}-eks-node-sg"
  })
}

# ALB SG
resource "aws_security_group" "alb_sg" {
  name        = "${var.env}-alb-sg"
  description = "Allow internet traffic to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.env}-alb-sg"
  })
}

# EKS Control Plane SG 
resource "aws_security_group" "eks_control_plane" {
  name        = "${var.env}-eks-control-plane"
  description = "Allow communication from control plane to node group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.env}-eks-control-plane"
  })
}

# Outputs
output "eks_nodes_sg_id" {
  description = "ID of the EKS node security group"
  value       = aws_security_group.eks_nodes.id
}

output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "eks_control_plane_sg_id" {
  description = "ID of control plane SG"
  value       = aws_security_group.eks_control_plane.id
} 
