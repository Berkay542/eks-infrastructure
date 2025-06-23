






module "vpc" {
  source                = "../modules/vpc" 
  env                   = var.env
  cidr_block            = var.cidr_block
  eks_name              = var.eks_name
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
}
