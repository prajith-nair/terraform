output "alb_dns_name" {
  value       = aws_lb.lb.dns_name
  description = "The FQDN of load balancer"
}
output "asg_name" {
  value       = aws_autoscaling_group.asglab.name
  description = "The name of the Autoscaling group"
}
output "alb_security_group_id" {
  value       = aws_security_group.alb-sg.id
  description = "The ID of the security group attached to the load balancer"
}