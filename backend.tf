terraform {
  backend "s3" {
    bucket       = "terraform-dev-tfstate-2025-12"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    profile      = "devops"
  }
}