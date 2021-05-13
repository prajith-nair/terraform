variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
  profile = "prajithnairsolutions"
  region  = "us-east-2"
}

resource "aws_launch_configuration" "lab" {
  image_id        = "ami-0c55b159cbfafe1f0"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.id]
  user_data       = data.template_file.user_data.rendered
  /*
user_data       = <<-EOF
  #!/bin/bash
  echo "Terraform world" >> index.html
  echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
  echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
  nohup busybox httpd -f -p ${var.server_port} &
  EOF
*/
  lifecycle {
    create_before_destroy = true
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  }
}

resource "aws_autoscaling_group" "asglab" {
  launch_configuration = aws_launch_configuration.lab.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns    = [aws_alb_target_group.asg_target.arn]
  health_check_type    = "ELB"
  max_size             = var.max_size
  min_size             = var.min_size
  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.custom_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")
  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "lb" {
  name               = "${var.cluster_name}-loadbalacer"
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

locals {
  http_port    = 80
  any_port     = 80
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = [
  "0.0.0.0/0"]
}

data "aws_vpc" "default" {
  default = true
}
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
resource "aws_security_group" "alb-sg" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb-sg.id
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
}


resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb-sg.id
  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
}

resource "aws_alb_target_group" "asg_target" {
  name     = "${var.cluster_name}-target-group"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 20
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.asg_target.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}