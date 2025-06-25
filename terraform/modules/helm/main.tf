## metrics server
resource "helm_release" "metrics_server" {
  provider   = helm.eks

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "5.12.2"  # Check latest version

  namespace  = "kube-system"
  create_namespace = false
}

# metric server is not built-in with EKS, you must install additionally.


# -- NGINX Ingress Controller --

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.7.1"

  namespace  = "ingress-nginx"

  create_namespace = true

  provider = helm.eks


  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.replicaCount"
    value = 2
  }
}

# -- AWS Load Balancer Controller --

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.4.7"

  namespace  = "kube-system"

  create_namespace = false

  provider = helm.eks

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }
}


##### cert manager   

resource "helm_release" "cert_manager" {
  provider   = helm.eks

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.12.0"   # check for latest stable version

  namespace  = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = true
  }

  set {
    name  = "global.leaderElection.namespace"
    value = "cert-manager"
  }
}

## Cert-Manager is installed via Helm in this module to automate TLS certificates for ingress SSL termination. 
## You must configure ClusterIssuer or Issuer resources to enable Let's Encrypt integration. /kubernetes/cluster-issuer.yaml



resource "helm_release" "prometheus" {
  provider   = helm.eks

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "45.6.0"  # Use latest stable version

  namespace  = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/values/prometheus-values.yaml")
  ]
}



resource "helm_release" "grafana" {
  provider   = helm.eks

  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "6.17.4"  # Check for latest version

  namespace  = "monitoring"
  create_namespace = false

  values = [
    file("${path.module}/values/grafana-values.yaml")
  ]
}



resource "helm_release" "node_exporter" {
  provider   = helm.eks

  name       = "node-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"
  version    = "4.24.0" # Use latest stable

  namespace  = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/values/node-exporter-values.yaml")
  ]
}
