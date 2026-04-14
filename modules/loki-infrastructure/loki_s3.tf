# LOKI CHUNKS - DATA

resource "aws_s3_bucket" "loki-chunks" {
  bucket = "eks-loki-chunks-${var.project_name}"
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
  bucket = "eks-loki-admin-${var.project_name}"
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
  bucket = "eks-loki-ruler-${var.project_name}"
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