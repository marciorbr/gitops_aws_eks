resource "aws_lb" "loki" {

  name = "eks-loki-nlb-${local.project_name_control_plane}"

  internal           = true
  load_balancer_type = "network"

  subnets = module.vpc.private_subnets_ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false

  tags = {
    Name = local.project_name_control_plane
  }

}

resource "aws_lb_target_group" "loki" {
  name     = "eks-loki-tg-http-${local.project_name_control_plane}"
  port     = 80
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_listener" "loki" {
  load_balancer_arn = aws_lb.loki.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loki.arn
  }
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
  targetGroupARN: ${aws_lb_target_group.loki.arn}
  targetType: instance
YAML
  depends_on = [
    kubectl_manifest.loki_namespace
  ]
}