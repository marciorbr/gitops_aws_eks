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
  name               = "eks-argocd-role-${var.project_name}"
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
  name        = "eks-argocd-policy-${var.project_name}"
  path        = "/"
  description = var.project_name

  policy = data.aws_iam_policy_document.argocd_policy.json
}

resource "aws_iam_policy_attachment" "argocd_policy" {
  name = "argocd_policy"

  roles = [aws_iam_role.argocd.name]

  policy_arn = aws_iam_policy.argocd_policy.arn
}

resource "aws_eks_pod_identity_association" "argo_application_controller" {
  cluster_name    = var.cluster_name_control_plane
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
  name               = "eks-argocd-deployer-${var.project_name}"
}

resource "aws_eks_access_policy_association" "argocd" {
  for_each = toset(var.cluster_names_workers)

  cluster_name  = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_iam_role.argo_deployer.arn

  access_scope {
    type = "cluster"
  }
}