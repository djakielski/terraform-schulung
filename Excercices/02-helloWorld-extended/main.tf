locals {
  env = upper(terraform.workspace)
  project = var.project
}

resource "aws_instance" "webserver"{
  ami = data.aws_ami.latest_hvm_ubuntu.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.webserver.name]
  user_data = templatefile("./scripts/initWebserver.sh", tomap({port =var.port
  }))
  tags = {
    Name = "${local.project}-webserver-${local.env}"
    Project = local.project
    LastModifiedAt = formatdate("EEEE, DD.MM.YYYY hh:mm:ss ZZZ",timestamp())
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_security_group" "webserver"{
  name="${local.project}-webserver-${local.env}"
  ingress {
    from_port = var.port
    protocol = "tcp"
    to_port = var.port
    cidr_blocks = ["0.0.0.0/0"]
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

