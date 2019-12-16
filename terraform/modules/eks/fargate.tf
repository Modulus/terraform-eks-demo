resource "aws_eks_fargate_profile" "eks_fargate_profile" {
    count = var.enable_fargate ? 1 : 0
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "${aws_eks_cluster.cluster.name}-fargate-profile"
  pod_execution_role_arn = aws_iam_role.pod_iam_role.arn
  subnet_ids             = var.subnet_ids

    dynamic "selector" {
        for_each = var.fargate_namespaces
        content {
            namespace = selector.value

            labels = {
              aws = "fargate"
            }
        }
    }

  depends_on = [
      aws_iam_role.pod_iam_role
  ]
}


resource "aws_iam_role" "pod_iam_role" {
  name = "eks-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "amazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.pod_iam_role.name
}