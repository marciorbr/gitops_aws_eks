resource "aws_lb" "loki" {

  name = "eks-loki-nlb-${var.project_name}"

  internal           = true
  load_balancer_type = "network"

  subnets = var.private_subnets_ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false

  tags = {
    Name = var.project_name
  }

}

resource "aws_lb_target_group" "loki" {
  name     = "eks-loki-tg-http-${var.project_name}"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.vpc_id
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