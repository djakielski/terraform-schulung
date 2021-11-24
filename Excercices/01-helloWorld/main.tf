provider "aws" {
  region="us-east-1"
}

resource "aws_instance" "webserver"{
  ami = "ami-07957d39ebba800d5"
  instance_type = "t3.nano"
  security_groups = [aws_security_group.webserver.name]
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p 80 &
    EOF
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

