provider "aws" {
  region  = "us-east-1"
  profile = "devops"
  default_tags {
    tags = {
      Owner       = "DevOpsTeam"
      Environment = "dev"
      Expires     = "Never"
      System      = "TerraformBackend"
      Department  = "Infra"
      ManagedBy   = "Terraform"
    }
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-dev-tfstate-2025-12"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "terraform_backend_access" {
  name        = "iam-policy-terraform-state-backend"
  description = "Policy for least privilege access to Terraform backend resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      }
    ]
  })
}

resource "aws_iam_group" "terraform_executors" {
  name = "TerraformExecutors"
}

resource "aws_iam_group_policy_attachment" "terraform_backend_access_attachment" {
  group      = aws_iam_group.terraform_executors.name
  policy_arn = aws_iam_policy.terraform_backend_access.arn
}