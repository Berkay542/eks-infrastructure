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