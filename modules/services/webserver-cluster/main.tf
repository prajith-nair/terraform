variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
  profile = "prajithnairsolutions"
  region  = "us-east-2"
}

resource "aws_launch_configuration" "lab" {
  image_id        = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.id]
  user_data = data.template_file.user_data.rendered

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
  name = "${var.cluster_name}-${aws_launch_configuration.lab.name}"

  launch_configuration = aws_launch_configuration.lab.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns = [
  aws_alb_target_group.asg_target.arn]
  health_check_type = "ELB"

  max_size = var.max_size
  min_size = var.min_size

  min_elb_capacity = var.min_size
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")
  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
    server_text = var.server_text
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

#Increase the number of servers to 2 during morning 9 am everyday
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name  = "${var.cluster_name}-scale-out-during-business-hours"
  min_size               = 1
  max_size               = 2
  desired_capacity       = 2
  recurrence             = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.asglab.name
}

#Decrease the number of servers to 2 at 5pm everyday
resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name  = "${var.cluster_name}-scale-in-at-night"
  min_size               = 1
  max_size               = 2
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
  autoscaling_group_name = aws_autoscaling_group.asglab.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name  = "${var.cluster_name}-high-cpu-utilization"
  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asglab.name
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Average"
  threshold           = 90
  unit                = "Percent"
}

#Create an alarm only for "txx" instances as other don't use CPU credits and don't report CPUCreditBalance metric
resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  count       = format("%.1s", var.instance_type) == "t" ? 1 : 0
  alarm_name  = "${var.cluster_name}-low-cpu-credit-balance"
  namespace   = "AWS/EC2"
  metric_name = "CPUCreditBalance"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asglab.name
  }
  comparison_operator = "LessThanThreshold"
  period              = 300
  statistic           = "Minimum"
  threshold           = 10
  unit                = "Count"
  evaluation_periods  = 1
}