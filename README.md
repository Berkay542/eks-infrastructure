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