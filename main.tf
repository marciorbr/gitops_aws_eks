module "vpc" {
  source               = "github.com/marciorbr/terraform-aws-vpc?ref=main"
  cidr_block           = local.cidr_block
  environment          = local.environment
  project_name         = local.project_name
  vpc_additional_cidrs = local.vpc_additional_cidrs
  public_subnets       = local.public_subnets
  private_subnets      = local.private_subnets
  database_subnets     = local.database_subnets
}

module "eks_control_plane" {

  providers = {
    kubectl = kubectl.control_plane
    helm    = helm.control_plane
  }

  source                   = "github.com/marciorbr/terraform-aws-eks.git?ref=v1.3.0"
  k8s_version              = local.k8s_version_control_plane
  project_name             = local.project_name_control_plane
  environment              = local.environment
  public_subnets           = module.vpc.public_subnets_ids
  private_subnets          = module.vpc.private_subnets_ids
  vpc_id                   = module.vpc.vpc_id
  on_demand_instance_types = ["t3.medium", "t3a.medium"]
  on_demand_auto_scale_options = {
    desired = 3
    max     = 4
    min     = 1
  }
  addons = ["eks-pod-identity-agent", "vpc-cni", "kube-proxy", "coredns"]

  enable_aws_lb_controller = true

  enable_nginx_controller_with_nlb_target_group_bind = true
}

module "eks_worker_01" {

  providers = {
    kubectl = kubectl.worker_01
    helm    = helm.worker_01
  }

  source                   = "github.com/marciorbr/terraform-aws-eks.git?ref=v1.3.0"
  k8s_version              = local.k8s_version_worker_01
  project_name             = local.project_name_worker_01
  environment              = local.environment
  public_subnets           = module.vpc.public_subnets_ids
  private_subnets          = module.vpc.private_subnets_ids
  vpc_id                   = module.vpc.vpc_id
  on_demand_instance_types = ["t3.medium", "t3a.medium"]
  on_demand_auto_scale_options = {
    desired = 2
    max     = 4
    min     = 1
  }
  addons = ["eks-pod-identity-agent", "vpc-cni", "kube-proxy", "coredns"]

  custom_access_entries = [
    {
      name              = "argocd-admin-access"
      principal_arn     = aws_iam_role.argo_deployer.arn
      type              = "STANDARD"
      kubernetes_groups = ["cluster-admin"]
    }
  ]

  custom_security_group_rule_cluster = [
    {
      name        = "allow-access-control-plane"
      cidr_blocks = [local.cidr_block]
      from_port   = 443
      to_port     = 443
      protocol    = "TCP"
      description = "Allow access from EKS Control Plane"
      type        = "ingress"
    }
  ]

  karpenter_capacity = [
    {
      name               = "karpenter-dev"
      workload           = "dev"
      ami_family         = "AL2023"
      ami_ssm            = "/aws/service/eks/optimized-ami/1.33/amazon-linux-2023/x86_64/standard/recommended/image_id"
      instance_family    = ["t3", "t3a"]
      instance_sizes     = ["small", "medium", "large"]
      capacity_type      = ["spot"]
      availability_zones = ["us-east-1a", "us-east-1b"]
    }
  ]

  enable_aws_lb_controller = false

  enable_nginx_controller_with_nlb_target_group_bind = false
}