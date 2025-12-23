resource "aws_efs_file_system" "dynamic" {
  creation_token   = "eks-efs-dynamic-${local.project_name_control_plane}"
  performance_mode = "generalPurpose"

  tags = {
    Name = "efs-dynamic-${local.project_name_control_plane}"
  }
}

resource "aws_efs_mount_target" "dynamic" {
  count = length(module.vpc.private_subnets_ids)


  file_system_id = aws_efs_file_system.dynamic.id
  subnet_id      = module.vpc.private_subnets_ids[count.index]
  security_groups = [
    module.eks_control_plane.efs_security_group_id
  ]
}