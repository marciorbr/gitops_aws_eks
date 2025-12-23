data "aws_iam_policy_document" "argocd_assume_role" {
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

resource "aws_iam_role" "argocd" {
  assume_role_policy = data.aws_iam_policy_document.argocd_assume_role.json
  name               = format("%s-argocd", local.project_name_control_plane)
}

data "aws_iam_policy_document" "argocd_policy" {
  version = "2012-10-17"

  statement {

    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    resources = [
      aws_iam_role.argo_deployer.arn
    ]

  }

}

resource "aws_iam_policy" "argocd_policy" {
  name        = format("%s-argocd-policy", local.project_name_control_plane)
  path        = "/"
  description = local.project_name_control_plane

  policy = data.aws_iam_policy_document.argocd_policy.json
}

resource "aws_iam_policy_attachment" "argocd_policy" {
  name = "argocd_policy"

  roles = [aws_iam_role.argocd.name]

  policy_arn = aws_iam_policy.argocd_policy.arn
}

resource "aws_eks_pod_identity_association" "argo_application_controller" {
  cluster_name    = module.eks_control_plane.eks_cluster_name
  namespace       = "argocd"
  service_account = "argocd-application-controller"
  role_arn        = aws_iam_role.argocd.arn
}

##### IAM Role for ArgoCD Deployer to assume ArgoCD Role

data "aws_iam_policy_document" "argocd_deployer_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.argocd.arn]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "argo_deployer" {
  assume_role_policy = data.aws_iam_policy_document.argocd_deployer_assume_role.json
  name               = format("%s-argocd-deployer", local.project_name_control_plane)
}

resource "aws_eks_access_policy_association" "argocd" {
  cluster_name  = module.eks_worker_01.eks_cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.argo_deployer.arn

  access_scope {
    type = "cluster"
  }
}