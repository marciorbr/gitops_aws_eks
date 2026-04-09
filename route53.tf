resource "aws_route53_zone" "private" {
  name = "customer.local"

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}


resource "aws_route53_record" "loki" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "loki.customer.local"
  type    = "CNAME"
  ttl     = "30"
  records = [aws_lb.loki.dns_name]
}