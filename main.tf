variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {}
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

resource "aws_instance" "lab" {
ami = "ami-0c55b159cbfafe1f0"
instance_type = "t2.micro"
  tags = {
    Name = "terraform-lab"
  }
}