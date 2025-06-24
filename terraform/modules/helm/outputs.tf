output "nginx_ingress_status" {
  value = helm_release.nginx_ingress.status
}

output "aws_lb_controller_status" {
  value = helm_release.aws_lb_controller.status
}
