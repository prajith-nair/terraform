output "alb_dns_name" {
  value = aws_lb.lb.dns_name
  description = "The FQDN of load balancer"
}




