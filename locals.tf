locals {

  # All Resource Configuration
  region       = "us-east-1"
  environment  = "dev"
  project_name = "customer"
  additional_aws_tags = {
    Owner      = "DevOpsTeam"
    Expires    = "Never"
    Department = "Engineering"
    ManagedBy  = "Terraform"
  }

  # VPC Configuration
  cidr_block           = "10.200.0.0/18"
  vpc_additional_cidrs = []

  public_subnets = [
    {
      name              = "public-1a"
      cidr              = "10.200.48.0/24"
      availability_zone = "us-east-1a"
    },
    {
      name              = "public-1b"
      cidr              = "10.200.49.0/24"
      availability_zone = "us-east-1b"
    }
  ]

  private_subnets = [
    {
      name              = "private-1a"
      cidr              = "10.200.0.0/20"
      availability_zone = "us-east-1a"
    },
    {
      name              = "private-1b"
      cidr              = "10.200.16.0/20"
      availability_zone = "us-east-1b"
    }
  ]

  database_subnets = [
    {
      name              = "database-1a"
      cidr              = "10.200.51.0/24"
      availability_zone = "us-east-1a"
    },
    {
      name              = "database-1b"
      cidr              = "10.200.52.0/24"
      availability_zone = "us-east-1b"
    }
  ]

  # EKS Control Plane Configuration
  k8s_version_control_plane  = "1.33"
  project_name_control_plane = "control-plane"

  # EKS Worker 01 Configuration
  k8s_version_worker_01  = "1.33"
  project_name_worker_01 = "worker-01"

}