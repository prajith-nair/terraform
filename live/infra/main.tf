provider "aws" {
  region  = "us-east-2"
  profile = "prajithnairsolutions"
}

resource "aws_security_group" "instance" {
  ingress {
    from_port = 22
    protocol  = "tcp"
    to_port   = 22

    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "sample" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  public_key = tls_private_key.sample.public_key_openssh
}

resource "aws_instance" "sample" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = aws_key_pair.generated_key.key_name

  provisioner "remote-exec" {
    inline = ["echo \"Hello, Terraformers! from $(uname -smp)\""]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.sample.private_key_pem
  }
}