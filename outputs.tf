output "eks_s3_buckets_loki_chunks_id" {
  description = "EKS Control Plane S3 Buckets for Loki Chunks ID"
  value       = aws_s3_bucket.loki-chunks.id
}

output "eks_s3_buckets_loki_admin_id" {
  description = "EKS Control Plane S3 Buckets for Loki Admin ID"
  value       = aws_s3_bucket.loki-admin.id
}

output "eks_s3_buckets_loki_ruler_id" {
  description = "EKS Control Plane S3 Buckets for Loki Ruler ID"
  value       = aws_s3_bucket.loki-ruler.id
}