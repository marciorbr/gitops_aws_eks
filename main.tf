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

  source                   = "github.com/marciorbr/terraform-aws-eks.git?ref=v1.4.3"
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
    min     = 3
  }
  addons = ["eks-pod-identity-agent", "vpc-cni", "kube-proxy", "coredns"]

  karpenter_capacity = [
    {
      name               = "loki"
      workload           = "loki"
      ami_family         = "AL2023"
      ami_ssm            = "/aws/service/eks/optimized-ami/1.34/amazon-linux-2023/x86_64/standard/recommended/image_id"
      instance_family    = ["t3", "t3a"]
      instance_sizes     = ["small", "medium", "large"]
      capacity_type      = ["spot", "on-demand"]
      availability_zones = ["us-east-1a", "us-east-1b"]
    }
  ]

  enable_aws_lb_controller = true

  enable_efs_csi = true

  enable_nginx_controller_with_nlb_target_group_bind = true
}

module "eks_worker_01" {

  providers = {
    kubectl = kubectl.worker_01
    helm    = helm.worker_01
  }

  source                   = "github.com/marciorbr/terraform-aws-eks.git?ref=v1.4.3"
  k8s_version              = local.k8s_version_worker_01
  project_name             = local.project_name_worker_01
  environment              = local.environment
  public_subnets           = module.vpc.public_subnets_ids
  private_subnets          = module.vpc.private_subnets_ids
  vpc_id                   = module.vpc.vpc_id
  on_demand_instance_types = ["t3.medium", "t3a.medium"]
  on_demand_auto_scale_options = {
    desired = 1
    max     = 2
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
      name               = "dev"
      workload           = "dev"
      ami_family         = "AL2023"
      ami_ssm            = "/aws/service/eks/optimized-ami/1.34/amazon-linux-2023/x86_64/standard/recommended/image_id"
      instance_family    = ["t3", "t3a"]
      instance_sizes     = ["small", "medium", "large"]
      capacity_type      = ["spot"]
      availability_zones = ["us-east-1a", "us-east-1b"]
    }
  ]

  enable_aws_lb_controller = false

  enable_nginx_controller_with_nlb_target_group_bind = false
}

module "loki" {
  source = "./modules/loki-infrastructure"

  project_name        = local.project_name_control_plane
  cluster_name        = module.eks_control_plane.eks_cluster_name
  vpc_id              = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets_ids
}

module "external_secrets_control_plane" {
  source = "./modules/external-secrets"

  project_name = local.project_name_control_plane
  region       = local.region
  cluster_name = module.eks_control_plane.eks_cluster_name
}

module "efs_storage_control_plane" {
  source = "./modules/efs-storage"

  project_name          = local.project_name_control_plane
  private_subnets_ids   = module.vpc.private_subnets_ids
  efs_security_group_id = module.eks_control_plane.efs_security_group_id
}


resource "kubectl_manifest" "loki_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: loki
YAML
  depends_on = [
    module.eks_control_plane
  ]
}

resource "kubectl_manifest" "loki" {
  yaml_body = <<YAML
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: loki-gateway
  namespace: loki
spec:
  serviceRef:
    name: loki-gateway
    port: 80
  targetGroupARN: ${module.loki.aws_nlb_target_group_arn}
  targetType: instance
YAML
  depends_on = [
    kubectl_manifest.loki_namespace
  ]
}

resource "kubectl_manifest" "dynamic_efs_storage_class" {

  provider = kubectl.control_plane

  yaml_body = <<YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: dynamic-efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${module.efs_storage_control_plane.aws_efs_file_system_id}
  subPathPattern: "$${.PVC.name}"
  directoryPerms: "777"
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
YAML

  depends_on = [
    module.efs_storage_control_plane
  ]
}