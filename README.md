**Online Boutique** is a cloud-first microservices demo application.  The application is a
web-based e-commerce app where users can browse items, add them to the cart, and purchase them.

Google uses this application to demonstrate how developers can modernize enterprise applications using Google Cloud products, including: [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine), [Cloud Service Mesh (CSM)](https://cloud.google.com/service-mesh), [gRPC](https://grpc.io/), [Cloud Operations](https://cloud.google.com/products/operations), [Spanner](https://cloud.google.com/spanner), [Memorystore](https://cloud.google.com/memorystore), [AlloyDB](https://cloud.google.com/alloydb), and [Gemini](https://ai.google.dev/). This application works on any Kubernetes cluster.


## Architecture

**Online Boutique** is composed of 11 microservices written in different
languages that talk to each other over gRPC.

🧩 Why does Online Boutique use gRPC?
Because it:

- Has 11 microservices that talk a lot — gRPC reduces network overhead.
- Defines communication clearly using .proto files.
- Is optimized for internal communication (inside Kubernetes) where speed matters more than human readability.

[![Architecture of
microservices](/docs/img/architecture-diagram.png)](/docs/img/architecture-diagram.png)

Find **Protocol Buffers Descriptions** at the [`./protos` directory](/protos).

| Service                                              | Language      | Description                                                                                                                       |
| ---------------------------------------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| [frontend](/src/frontend)                           | Go            | Exposes an HTTP server to serve the website. Does not require signup/login and generates session IDs for all users automatically. |
| [cartservice](/src/cartservice)                     | C#            | Stores the items in the user's shopping cart in Redis and retrieves it.                                                           |
| [productcatalogservice](/src/productcatalogservice) | Go            | Provides the list of products from a JSON file and ability to search products and get individual products.                        |
| [currencyservice](/src/currencyservice)             | Node.js       | Converts one money amount to another currency. Uses real values fetched from European Central Bank. It's the highest QPS service. |
| [paymentservice](/src/paymentservice)               | Node.js       | Charges the given credit card info (mock) with the given amount and returns a transaction ID.                                     |
| [shippingservice](/src/shippingservice)             | Go            | Gives shipping cost estimates based on the shopping cart. Ships items to the given address (mock)                                 |
| [emailservice](/src/emailservice)                   | Python        | Sends users an order confirmation email (mock).                                                                                   |
| [checkoutservice](/src/checkoutservice)             | Go            | Retrieves user cart, prepares order and orchestrates the payment, shipping and the email notification.                            |
| [recommendationservice](/src/recommendationservice) | Python        | Recommends other products based on what's given in the cart.                                                                      |
| [adservice](/src/adservice)                         | Java          | Provides text ads based on given context words.                                                                                   |
| [loadgenerator](/src/loadgenerator)                 | Python/Locust | Continuously sends requests imitating realistic user shopping flows to the frontend.                                              |

## Screenshots

| Home Page                                                                                                         | Checkout Screen                                                                                                    |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| [![Screenshot of store homepage](/docs/img/online-boutique-frontend-1.png)](/docs/img/online-boutique-frontend-1.png) | [![Screenshot of checkout screen](/docs/img/online-boutique-frontend-2.png)](/docs/img/online-boutique-frontend-2.png) |







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