terraform {
  required_version = ">= 1.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.11.0"
    }
  }
}

resource "aws_efs_file_system" "dynamic" {
  creation_token   = "eks-efs-dynamic-${var.project_name}"
  performance_mode = "generalPurpose"

  tags = {
    Name = "efs-dynamic-${var.project_name}"
  }
}

resource "aws_efs_mount_target" "dynamic" {
  count = length(var.private_subnets_ids)


  file_system_id = aws_efs_file_system.dynamic.id
  subnet_id      = var.private_subnets_ids[count.index]
  security_groups = [
    var.efs_security_group_id
  ]
}