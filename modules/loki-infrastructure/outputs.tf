output "aws_nlb_dns" {
  value = aws_lb.loki.dns_name
}

output "aws_nlb_target_group_arn" {
  value = aws_lb_target_group.loki.arn
}