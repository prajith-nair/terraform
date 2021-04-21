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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}