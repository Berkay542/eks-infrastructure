variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    scaling_config = object({
      desired_size = number
      min_size     = number
      max_size     = number
    })
    labels = map(string)
    update_config = object({
      max_unavailable = number
    })
  }))
}


variable "env" {}

variable "eks_name" {}

variable "private_subnet_ids" {}

variable "tags" {
  type        = map(string)
  default     = {}
}