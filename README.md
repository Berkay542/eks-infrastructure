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


### node-group

This module provisions one or more managed node groups for an Amazon EKS cluster using `aws_eks_node_group`.

## ✅ Features

- Supports multiple node groups via a `map` input (`general`, `spot`, `gpu`, etc.)
- IAM Role setup with necessary policies
- Private subnet support for worker nodes
- Configurable:
  - Instance types
  - Capacity types (ON_DEMAND / SPOT)
  - Scaling configuration
  - Pod labels
  - Update configuration
- Lifecycle rule to ignore desired size changes (allows cluster autoscaler or manual scaling)

---



# Helm Module for Kubernetes Add-ons

This module manages the deployment of essential Kubernetes components and tools on the EKS cluster using Helm charts.

---

## Included Components

- **NGINX Ingress Controller**  
  Deploys the community NGINX ingress controller for routing external HTTP/S traffic into the cluster.

- **AWS Load Balancer Controller**  
  Integrates with AWS to provision and manage AWS Application Load Balancers (ALB) or Network Load Balancers (NLB) for Kubernetes services.

- **Cert-Manager**  
  Automates the management and issuance of TLS certificates for secure ingress (SSL termination), typically using Let’s Encrypt.

- **Metrics Server**  
  Provides resource metrics (CPU, memory) required for Kubernetes autoscaling components like Horizontal Pod Autoscaler (HPA).
  Metrics server do not come automatically with EKS, you must install additionally like we are doing here.

- **Horizontal Pod Autoscaler (HPA)**  
  Automatically scales your workloads based on resource usage (e.g., CPU utilization) to improve availability and cost efficiency.

---

## Important Notes

- The Helm module installs these components but **does not apply** Kubernetes manifests for workload resources like Deployments or HPAs directly.  
- Because this cluster uses **ArgoCD** for GitOps-based deployment and lifecycle management, **HPA manifests should exclude resource requests/limits** to avoid conflicts with ArgoCD policies or syncing issues.  
- You should manage application workloads, HPA specs, and other custom Kubernetes resources in your ArgoCD Git repositories.

---