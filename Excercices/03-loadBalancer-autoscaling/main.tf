locals {
  env     = upper(terraform.workspace)
  project = var.project
}

resource "aws_lb" "webserver" {
  name               = "${local.project}-webserver-lb-${local.env}"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.webserver.id]
}

data "aws_vpc" "default" {}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_launch_configuration" "webserver"{
  image_id        = data.aws_ami.latest_hvm_ubuntu.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instances.id]
  user_data       = templatefile("./scripts/initWebserver.sh", tomap({port =var.port }))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "webserver"{
  name="${local.project}-webserver-loadbalancer-${local.env}"
  ingress {
    from_port   = var.port
    protocol    = "tcp"
    to_port     = var.port
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instances"{
  name="${local.project}-webserver-instances-${local.env}"
  ingress {
    from_port       = var.port
    protocol        = "tcp"
    to_port         = var.port
    security_groups = [aws_security_group.webserver.id]
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

resource "aws_autoscaling_group" "webserver" {
  count = var.autoscaling_active ? 1 : 0
  name              = "${local.project}-webserver-asg-${local.env}"
  launch_configuration  = aws_launch_configuration.webserver.name
  vpc_zone_identifier   = data.aws_subnet_ids.default.ids

  target_group_arns     = [aws_lb_target_group.webserver_asg[0].arn]
  health_check_type     = "ELB"

  max_size              = var.maxNumberOfInstances
  min_size              = var.maxNumberOfInstances
}

resource "aws_lb_target_group" "webserver_asg" {
  count = var.autoscaling_active ? 1 : 0
  name = "${local.project}-webserver-asg-tg-${local.env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 60
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webserver.arn
  port              = var.port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "forward_all" {
  listener_arn = aws_lb_listener.http.arn
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = var.autoscaling_active ? aws_lb_target_group.webserver_asg[0].arn : aws_lb_target_group.webserver_instances[0].arn
  }
}

resource "aws_instance" "webserver"{
  count           = var.autoscaling_active ? 0 : var.numberOfInstances
  ami             = data.aws_ami.latest_hvm_ubuntu.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.webserver.name]
  user_data       = templatefile("./scripts/initWebserver.sh", tomap({port =var.port }))
  tags = {
    Name            = "${local.project}-webserver-${count.index}-${local.env}"
    Project         = local.project
    LastModifiedAt  = formatdate("EEEE, DD.MM.YYYY hh:mm:ss ZZZ",timestamp())
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_lb_target_group" "webserver_instances" {
  count = var.autoscaling_active ? 0 : 1
  name      = "${local.project}-webserver-${local.env}"
  port      = var.port
  protocol  = "HTTP"
  vpc_id    = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 60
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "webserver_instances" {
  count             = length(aws_instance.webserver)
  target_group_arn  = aws_lb_target_group.webserver_instances[0].arn
  target_id         = aws_instance.webserver[count.index].id
}


