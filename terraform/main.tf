

module "vpc" {
  source                = "../modules/vpc" 
  env                   = var.env
  cidr_block            = var.cidr_block
  eks_name              = var.eks_name
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
}


module "eks" {
  source = "./modules/eks"

  env                   = var.env
  eks_name              = var.eks_name
  project               = var.project
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  endpoint_private_access = true
  endpoint_public_access  = true

  k8s_version           = var.k8s_version
  service_ipv4_cidr     = var.service_ipv4_cidr
  cluster_log_types     = var.cluster_log_types

  allowed_cidrs         = var.allowed_cidrs

  tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}


module "node_groups" {
  source = "./modules/node_groups"

  cluster_name        = module.eks.cluster_name
  private_subnet_ids  = module.vpc.private_subnet_ids
  tags                = local.tags

  node_groups         = var.node_groups
}


module "helm" {
  source = "./modules/helm"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  k8s_token              = data.aws_eks_cluster_auth.token.token
  region                 = var.region
  vpc_id                 = module.vpc.vpc_id
}