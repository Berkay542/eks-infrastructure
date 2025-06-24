output "node_group_names" {
  description = "Names of created node groups"
  value       = [for name in keys(var.node_groups) : name]
}

output "node_role_arn" {
  description = "IAM Role ARN used by node groups"
  value       = aws_iam_role.nodes.arn
}