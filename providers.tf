terraform {
  required_version = ">= 1.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.11.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}
provider "aws" {
  region  = local.region
  profile = "devops"
  default_tags {
    tags = local.additional_aws_tags
  }
}

provider "helm" {
  alias = "control_plane"
  kubernetes = {
    host                   = module.eks_control_plane.eks_endpoint
    cluster_ca_certificate = base64decode(module.eks_control_plane.eks_certificate_authority)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks_control_plane.eks_cluster_name]
    }
  }
}

provider "helm" {
  alias = "worker_01"
  kubernetes = {
    host                   = module.eks_worker_01.eks_endpoint
    cluster_ca_certificate = base64decode(module.eks_worker_01.eks_certificate_authority)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_worker_01.eks_cluster_name]
    }
  }
}

provider "kubectl" {
  host                   = module.eks_control_plane.eks_endpoint
  cluster_ca_certificate = base64decode(module.eks_control_plane.eks_certificate_authority)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks_control_plane.eks_cluster_name]
    command     = "aws"
  }
  alias = "control_plane"
}

provider "kubectl" {
  alias                  = "worker_01"
  host                   = module.eks_worker_01.eks_endpoint
  cluster_ca_certificate = base64decode(module.eks_worker_01.eks_certificate_authority)
  token                  = module.eks_worker_01.aws_eks_cluster_auth.token
}