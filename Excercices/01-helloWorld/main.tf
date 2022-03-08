provider "aws" {
  region="us-east-1"
}

locals {
  project = "jakielskis-lb"
  env = upper(terraform.workspace)
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

resource "aws_lb" "webservers" {
  name = "${local.project}-${local.env}"
  load_balancer_type = "application"
  security_groups = [aws_security_group.lb.id]
  subnets = data.aws_subnet_ids.subnets.ids
}

data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "lb" {
  name = "${local.project}-lb-${local.env}"
  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow http from all"
  }
  ingress {
    from_port = 443
    protocol  = "tcp"
    to_port   = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow https from all"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webservers.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.webservers.arn
  }
}

resource "aws_lb_target_group" "webservers" {
  name = "${local.project}-webservers-${local.env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webservers.arn
  }

  condition {
    path_pattern {
      values = ["/static"]
    }
  }
}

resource "aws_lb_target_group_attachment" "webservers" {
  count = length(aws_instance.webserver)
  target_group_arn = aws_lb_target_group.webservers.arn
  target_id        = aws_instance.webserver[count.index].id
  port             = 80
}

resource "aws_autoscaling_group" "webservers" {
  max_size = var.instanceCount
  desired_capacity = var.instanceCount
  min_size = var.instanceCount
  name = "${local.project}-webservers-${local.env}"

  launch_configuration = aws_launch_configuration.webserver.name
  vpc_zone_identifier  = data.aws_subnet_ids.subnets.ids

  target_group_arns = [aws_lb_target_group.webservers.arn]
  health_check_type = "ELB"
}

resource "aws_launch_configuration" "webserver"{
  image_id = data.aws_ami.latest_hvm_ubuntu.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.webserver.id]
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p 80 &
    EOF

  lifecycle {
    create_before_destroy = true
  }
}
