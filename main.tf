variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {}
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

resource "aws_instance" "lab" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  user_data     = <<-EOF
    #!/bin/bash
    echo "Terraform world" > index.html
    nohup busybox httpd -f -p 8080 &
    EOF
  tags = {
    Name = "terraform-lab"
  }
}

resource "aws_security_group" "instance" {
  name  = "terraform-sg"
  ingress
  {
   from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}