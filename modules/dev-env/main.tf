# Define a local variable for the cluster name
locals {
  cluster_name = "${var.user}-dev-kind-cluster"
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "allow_all" {
  name        = "${var.user}-allow-all"
  description = "Security group that allows all inbound access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.user}-dev-sg"
  }
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "${var.user}-dev-key"
  public_key = file(var.public_ssh_key_path)
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "dev_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  user_data = filebase64("${path.module}/user_data.sh")

  tags = {
    Name = "${var.user}-dev-server"
  }

  root_block_device {
    volume_size = 200
  }

}

output "dev_server_public_ip" {
  description = "Public IP address of the dev server instance"
  value       = aws_instance.dev_server.public_ip
}