### vpc module

variable "cidr_block" {}
variable "env" {}
variable "eks_name" {}
variable "zone1" {}
variable "zone2" {}
variable "region" {}
variable "availability_zones" {}
variable "public_subnet_cidrs" {}
variable "private_subnet_cidrs" {}


### eks module 

variable "eks_name" {}
variable "env" {}
variable "project" {}
variable "vpc_id" {}
variable "private_subnet_ids" { type = list(string) }

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "endpoint_public_access" {
  type    = bool
  default = false
}

variable "service_ipv4_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "172.20.0.0/16"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "cluster_log_types" {
  description = "EKS control plane logs to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to access EKS API"
  type        = list(string)
  default     = ["0.0.0.0/0"] #  tighten in production
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}