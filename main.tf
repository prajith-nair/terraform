variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {}
provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_launch_configuration" "lab" {
  image_id        = "ami-0c55b159cbfafe1f0"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  user_data       = <<-EOF
    #!/bin/bash
    echo "Terraform world" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asglab" {
  launch_configuration = aws_launch_configuration.lab.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns = [aws_alb_target_group.asg_target.arn]
  health_check_type = "ELB"
  max_size             = 10
  min_size             = 2
  tag {
    key                 = "Name"
    value               = "terraform-asg"
    propagate_at_launch = true
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP request"
  type        = number
  default     = 8080
}
resource "aws_security_group" "instance" {
  name = "terraform-sg"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "lb" {
  name               = "terraform-loadbalacer"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = data.aws_subnet_ids.default.ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page Not Found"
      status_code  = 404
    }
  }
}
data "aws_vpc" "default"{
  default = true
}
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
resource "aws_security_group" "alb-sg" {
  name = "terraform-alb-sg"
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
}

resource "aws_alb_target_group" "asg_target" {
  name = "terraform-asg-target-group"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.asg_target.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
output "alb_dns_name" {
  value = aws_lb.lb.dns_name
  description = "The FQDN of load balancer"
}