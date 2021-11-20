provider "aws" {
  region="us-east-1"
}

resource "aws_instance" "webserver"{
  ami = data.aws_ami.latest_hvm_ubuntu.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.webserver.name]
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p 80 &
    EOF
  tags = {
    Name = "EC2_Instance_Exercise_1"
    Project = "TF_Training"
    LastModifiedAt = formatdate("EEEE, DD.MM.YYYY hh:mm:ss ZZZ",timestamp())
  }
  lifecycle {
    ignore_changes = [tags]
  }

}
resource "aws_security_group" "webserver"{
  name="webserver"
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
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

