resource "aws_iam_role" "eks_iam_role" {
  name = "${var.cluster_name}-eks-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_iam_role.name
}

resource "aws_iam_role_policy_attachment" "amazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_iam_role.name
}


resource "aws_cloudwatch_log_group" "eks_log_group" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

}


resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_iam_role.arn

  version = "1.14"
  vpc_config {
    subnet_ids = var.subnet_ids
    endpoint_private_access = false
    endpoint_public_access = true

  //security_group_ids = []

  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.amazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.amazonEKSServicePolicy,
    aws_cloudwatch_log_group.eks_log_group
  ]

  enabled_cluster_log_types = ["api", "audit"]

  tags = {
      env = "test"
  }

}

output "endpoint" {
  value = "${aws_eks_cluster.cluster.endpoint}"
}


output "kubeconfig-certificate-authority-data" {
  value = "${aws_eks_cluster.cluster.certificate_authority.0.data}"
}

resource "aws_iam_role" "eks_node_group_iam_role" {
  name = "eks-node-group-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


resource "aws_iam_policy" "autoscaling_policy" {
  name        = "${aws_eks_cluster.cluster.name}_autoscaling_policy"
  path        = "/"
  description = "${aws_eks_cluster.cluster.name} autoscaling policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "amazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_iam_role.name
}

resource "aws_iam_role_policy_attachment" "amazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_iam_role.name
}

resource "aws_iam_role_policy_attachment" "amazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_iam_role.name
}

resource "aws_iam_role_policy_attachment" "amazonEKSWorkerNodeAutoscalingPolicy" {
  policy_arn = aws_iam_policy.autoscaling_policy.arn
  role       = aws_iam_role.eks_node_group_iam_role.name
}

resource "aws_eks_node_group" "main_group" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_iam_role.arn
  subnet_ids      = var.subnet_ids

  labels = {
    cluster = aws_eks_cluster.cluster.name
  }


  tags = {
    cluster = aws_eks_cluster.cluster.name
  }


  instance_types = var.instance_types

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.amazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.amazonEC2ContainerRegistryReadOnly,
    aws_eks_cluster.cluster
  ]
}


# output "resources" {
#     value = aws_eks_cluster.cluster.resources
# }

output "status" {
    value = aws_eks_cluster.cluster.status
}

output "id" {
    value = aws_eks_cluster.cluster.id
}

output "node_groups" {
    value = aws_eks_node_group.main_group
}