terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
  }
}

provider "aws" {
  region="us-east-1"
}

provider "aws" {
  region="eu-central-1"
  alias = "eu"
}

resource "aws_instance" "webserver"{
  ami = data.aws_ami.latest_hvm_ubuntu.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.webserver.name]
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p 8080 &
    EOF
  tags = {
    Name = "webserver - ${terraform.workspace}"
    Project = "TF_Training"
    LastModifiedAt = formatdate("EEEE, DD.MM.YYYY hh:mm:ss ZZZ",timestamp())
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_security_group" "webserver"{
  name="webserver-${random_pet.postfix.id}"
  ingress {
    from_port = 8080
    protocol = "tcp"
    to_port = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_pet" "postfix" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    ami_id = data.aws_ami.latest_hvm_ubuntu.id
  }
}

data "aws_ami" "latest_hvm_ubuntu" {
  most_recent = true
  owners = ["099720109477"] # Canonical
  filter {
    name = "name"
    values = ["ubuntu/images/hvm/ubuntu-*-*-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

