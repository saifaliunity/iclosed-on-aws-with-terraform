resource "aws_lb" "iclosed_lb" {
  name                       = "iclosed-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb_sg.id]
  subnets                    = aws_subnet.public_subnets.*.id
  enable_deletion_protection = false

  tags = {
    Environment = var.env
  }
}

output "lb_dns_name" {
  value = aws_lb.iclosed_lb.dns_name
}

resource "aws_lb_target_group" "iclosed_tg" {
  name_prefix = "bktg"
  port        = var.iclosed_service_container_port
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.iclosed_vpc.id

  health_check {
    interval            = 30
    port                = var.iclosed_service_container_port
    path                = var.healthcheck_path
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 3
    matcher             = "200"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http_listner" {
  load_balancer_arn = aws_lb.iclosed_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "secure-listener" {
  load_balancer_arn = aws_lb.iclosed_lb.arn # Referencing our load balancer
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.iclosed-ssl-validator.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Nothing Here!"
      status_code  = "200"
    }
  }
}

resource "aws_acm_certificate" "iclosed-ssl-cert" {
  domain_name       = var.bk_domain_name
  validation_method = "DNS"

  tags = {
    Environment = var.env
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "iclosed" {
  name         = var.hosted_zone_domain
  private_zone = false
}

#SSL records from AWS ACM

resource "aws_route53_record" "iclosed-ssl-records" {
  for_each = {
    for dvo in aws_acm_certificate.iclosed-ssl-cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.iclosed.zone_id
  depends_on = [
    aws_acm_certificate.iclosed-ssl-cert
  ]
}

# Load balancer CNAME record to iclosed.io


resource "aws_route53_record" "iclosed-ecs-record" {

  allow_overwrite = true
  name            = var.bk_domain_name
  records         = [aws_lb.iclosed_lb.dns_name]
  ttl             = 60
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.iclosed.zone_id

}

resource "aws_acm_certificate_validation" "iclosed-ssl-validator" {
  certificate_arn         = aws_acm_certificate.iclosed-ssl-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.iclosed-ssl-records : record.fqdn]
}
