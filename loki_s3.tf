# LOKI CHUNKS - DATA

resource "aws_s3_bucket" "loki-chunks" {
#   bucket = format("%s-%s-loki-chunks", var.project_name, data.aws_caller_identity.current.account_id)
  bucket = "eks-loki-chunks-${local.project_name_control_plane}"
}

resource "aws_s3_bucket_ownership_controls" "loki-chunks" {
  bucket = aws_s3_bucket.loki-chunks.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "loki-chunks" {
  bucket = aws_s3_bucket.loki-chunks.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.loki-chunks
  ]
}

# LOKI ADMIN

resource "aws_s3_bucket" "loki-admin" {
  bucket = "eks-loki-admin-${local.project_name_control_plane}"
}

resource "aws_s3_bucket_ownership_controls" "loki-admin" {
  bucket = aws_s3_bucket.loki-admin.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "loki-admin" {
  bucket = aws_s3_bucket.loki-admin.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.loki-admin
  ]
}

## LOKI RULER

resource "aws_s3_bucket" "loki-ruler" {
  bucket = "eks-loki-ruler-${local.project_name_control_plane}"
}

resource "aws_s3_bucket_ownership_controls" "loki-ruler" {
  bucket = aws_s3_bucket.loki-ruler.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "loki-ruler" {
  bucket = aws_s3_bucket.loki-ruler.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.loki-ruler
  ]
}