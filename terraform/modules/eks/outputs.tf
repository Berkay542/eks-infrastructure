output "eks_cluster_id" {
  value = aws_eks_cluster.eks_cluster.id
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_arn" {
  value = aws_eks_cluster.eks_cluster.arn
}

output "eks_security_group_id" {
  value = aws_security_group.eks_sg.id
}

output "kms_key_arn" {
  value = aws_kms_key.eks_key.arn
}


output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "eks_name" {
  value = aws_eks_cluster.eks_cluster.name
}