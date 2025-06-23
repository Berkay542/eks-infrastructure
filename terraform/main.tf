

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