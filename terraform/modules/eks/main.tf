## Create IAM role

resource "aws_iam_role" "eks_master_role" {
  name = "${var.eks_name}-ControlPlane-iam-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.eks_name}-ControlPlane-iam-role-${var.env}"
    ManagedBy   = "Terraform"
    Product     = var.project
    Environment = var.env
  }
}

# Associate IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_master_role.name
}


resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_master_role.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_master_role.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_master_role.name
}

resource "aws_iam_role_policy_attachment" "eks-ec2-describe-policy" {
  policy_arn = aws_iam_policy.ec2-describe-policy.arn
  role       = aws_iam_role.eks_master_role.name
}

resource "aws_iam_policy" "ec2-describe-policy" {
  name        = "${var.eks_name}-ec2-describe-policy-${var.env}"
  tags = {
    "Name" = "${var.eks_name}-ec2-describe-policy-${var.env}"
    "Managed-by" = "Terraform"
    "Product"  = "${var.project}"
    "Environment" = "${var.env}"
  }
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeInternetGateways"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
})
}

data "aws_eks_cluster_auth" "token" {
  name = aws_eks_cluster.eks_cluster.name
}

######### KMS KEY #######

resource "aws_kms_key" "eks-key" {

  description              = "KMS key for EKS cluster"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  multi_region             = true
  tags = {
    "Name"         = "${var.eks_name}-KMS-key-${var.env}"
    "Managed by"   = "Terraform"
    "Product"      = "${var.project}"
    "Environment" = "${var.env}"
  }
}

resource "aws_kms_alias" "alias" {
  name          = "alias/${var.eks_name}-master-key-${var.env}"
  target_key_id = aws_kms_key.eks-key.key_id
}

# EKS Security Group
######################
resource "aws_security_group" "eks_sg" {
  name        = "${var.eks_name}-eks-sg-${var.env}"
  description = "Security group for EKS control plane"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow EKS control plane access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.eks_name}-eks-sg-${var.env}"
  })
}

# EKS Cluster
######################
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.eks_name}-${var.env}"
  role_arn = aws_iam_role.eks_master_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = [aws_security_group.eks_sg.id]
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_key.arn
    }
  }

  enabled_cluster_log_types = var.cluster_log_types

  tags = merge(var.tags, {
    Name = "${var.eks_name}-${var.env}"
  })

  depends_on = [
  aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
  aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  aws_iam_role_policy_attachment.eks-AmazonEKSServicePolicy,
  aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  aws_iam_role_policy_attachment.eks-ec2-describe-policy
]

}


### pod identity addon

#runs as a daemonset
resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name = "eks-pod-identity-agent"
  addon_version = "v1.3.0-eksbuild.1"
  
}



## helm resources




###    AWS Load balancer controller


data "aws_iam_policy_document" "aws_lbc" {
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

resource "aws_iam_role" "aws_lbc" {
  name               = "${aws_eks_cluster.eks.name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
}

resource "aws_iam_policy" "aws_lbc" {
  policy = file("./iam/AWSLoadBalancerController.json")
  name   = "AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc.arn
}

resource "helm_release" "aws_lbc" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks_cluster.name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [helm_release.cluster_autoscaler]
}



## metrics server
resource "helm_release" "metrics_server" {

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "5.12.2"  # Check latest version

  namespace  = "kube-system"
  create_namespace = false
}

# metric server is not built-in with EKS, you must install additionally.


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
  name               = "${aws_eks_cluster.eks_cluster.name}-argocd-image-updater"
  assume_role_policy = data.aws_iam_policy_document.argocd_image_updater.json
}

resource "aws_iam_role_policy_attachment" "argocd_image_updater" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.argocd_image_updater.name
}

resource "aws_eks_pod_identity_association" "argocd_image_updater" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
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