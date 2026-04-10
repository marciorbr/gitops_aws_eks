data "aws_iam_policy_document" "external_secrets_assume_role" {

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "external_secrets" {

  name               = "eks-external-secrets-iam-role-${local.project_name_control_plane}"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json

}

data "aws_iam_policy_document" "external_secrets" {

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets"
    ]
    resources = [
      "arn:aws:secretsmanager:${local.region}:*:secret:*"
    ]
  }
  statement {
    sid    = "AllowSSMParameters"
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:AddTagsToResource",
      "ssm:ListTagsForResource"
    ]

    resources = [
      "arn:aws:ssm:${local.region}:*:parameter/*"
    ]
  }
}

resource "aws_iam_policy" "external_secrets" {


  name   = "eks-external-secrets-policy-${local.project_name_control_plane}"
  policy = data.aws_iam_policy_document.external_secrets.json
}

resource "aws_iam_role_policy_attachment" "external_secrets" {


  policy_arn = aws_iam_policy.external_secrets.arn
  role       = aws_iam_role.external_secrets.name
}

resource "aws_eks_pod_identity_association" "external_secrets" {

  cluster_name    = module.eks_control_plane.eks_cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.external_secrets.arn
}
