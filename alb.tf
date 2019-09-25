
# Firewall
resource "aws_security_group" "alb" {
  name        = "ALB Security group"
  description = "Allow Web traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

####################################################################

data "aws_subnet_ids" "alb" {
  vpc_id = "${var.vpc_id}"
  tags {
    Name = "*public*"
  }

  # filter {
  #   name   = "tag:Name"
  #   values = ["*public*"]
  # }
}

output "public_subnets" {
  value = "${data.aws_subnet_ids.alb.ids}"
}

# Load balancer
resource "aws_lb" "alb" {
  name               = "api-alb-public"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.alb.id}"]
  subnets            = ["${data.aws_subnet_ids.alb.ids}"]

  tags = {
    Name = "api-alb-public"
  }
}

resource "aws_lb_target_group" "alb" {
  name     = "api-tg-80"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    path = "/heartbeat"
    unhealthy_threshold = 8
    matcher = "200"
  }
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.alb.arn}"
  }
}
