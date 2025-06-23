# eks-infrastructure

# VPC Module

This Terraform module creates a production-ready AWS VPC designed specifically for EKS clusters with best practices for networking and Kubernetes integration.

---

## What it does

- Creates a VPC with your specified CIDR block.
- Creates public and private subnets across multiple Availability Zones for high availability.
- Adds Kubernetes-specific tags to subnets:
  - Public subnets tagged with `kubernetes.io/role/elb = 1` to allow external load balancers (ELB/ALB).
  - Private subnets tagged with `kubernetes.io/role/internal-elb = 1` for internal load balancers.
  - Both subnets tagged with `kubernetes.io/cluster/<eks_name> = owned` for cluster ownership identification.
- Creates an Internet Gateway for public internet access.
- Creates one NAT Gateway (for test purposes) to enable internet access from private subnets.
- Creates route tables and associates them correctly with public and private subnets.
- Enables DNS hostnames and DNS support in the VPC to support cluster DNS functionality.




# EKS Module

This Terraform module provisions a  **Amazon EKS Cluster**, including:

- EKS control plane
- IAM roles and required policy attachments
- Custom IAM policy for EC2 Describe access (for ELB controller)
- KMS key for secrets encryption
- Security Group for API server access
- Full tagging and logging support

---

## 🚀 Features

- IAM Role and policies for EKS
- VPC integration with private subnets
- Public/private endpoint access options
- Kubernetes secrets encryption via KMS
- Cluster logging enabled (configurable)
- Customizable ingress CIDRs via security group


🛠️ Heads up: This module sets up the EKS control plane only.

I’m installing essential add-ons like the AWS Load Balancer Controller, NGINX Ingress Controller, and Cert-Manager separately using Helm; check out the `helm/` modules in this repo!
