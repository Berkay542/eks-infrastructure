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
  version    = "4.10.1"

  namespace  = "ingress-nginx"
  create_namespace = true

  values = [file("${path.modules}/values/nginx-ingres.yaml")]

  depends_on = [ helm_release.aws_lb_controller ]
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
  version    = "v1.14.5"   # check for latest stable version

  namespace  = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = true
  }

  depends_on = [ helm_release.nginx_ingress ]
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
  depends_on = [module.eks]
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
  depends_on = [module.eks]
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
  depends_on = [module.eks]
}

### Redis 

resource "helm_release" "redis" {
  name       = "redis"
  namespace  = "default"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "19.5.4" # or the latest tested version

  values = [file("${path.module}/values/redis-values.yaml")]

  set {
    name  = "auth.enabled"
    value = "false"
  }

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "master.persistence.enabled"
    value = "false"
  }

  depends_on = [module.eks]
}




### ArgoCD

# helm install argocd -n argocd --create-namespace argo/argo-cd --version 7.3.11 -f terraform/values/argocd.yaml
resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.3.11"

  values = [file("values/argocd.yaml")]

  depends_on = [module.eks]
}




## Image Updater for ArgoCD

data "aws_iam_policy_document" "argocd_image_updater" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "argocd_image_updater" {
  name               = "${var.cluster_name}-argocd-image-updater"
  assume_role_policy = data.aws_iam_policy_document.argocd_image_updater.json
}

resource "aws_iam_role_policy_attachment" "argocd_image_updater" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.argocd_image_updater.name
}

resource "aws_eks_pod_identity_association" "argocd_image_updater" {
  cluster_name    = var.cluster_name
  namespace       = "argocd"
  service_account = "argocd-image-updater"
  role_arn        = aws_iam_role.argocd_image_updater.arn
}

resource "helm_release" "updater" {
  name = "updater"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  namespace        = "argocd"
  create_namespace = true
  version          = "0.11.0"

  values = [file("values/image-updater.yaml")]

  depends_on = [helm_release.argocd]
}