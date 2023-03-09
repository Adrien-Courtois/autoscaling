### Provider definition

provider "aws" {
  region = var.aws_region
}

# ## STATE SUR S3 BUCKET
# terraform {
#   backend "s3" {
#     # Nom du bucket
#     bucket = "adrien-isri-upjv"

#     # Chemin où on veut mettre le fichier dans le bucket
#     key = "terraform/autoscaling/terraform.tfstate"

#     # Region du bucket
#     region = "us-east-1"

#     # Nom de la dynamo DB pour lock l'accès au fichier
#     dynamodb_table = "lock-s3"
#   }
# }

## LOAD BALANCER
resource "aws_lb" "alb" {
  load_balancer_type = "application"
  security_groups    = [aws_security_group.secu_group_alb.id]
  subnets            = [for subnet in module.discovery.public_subnets : subnet]

  tags = {
    Name = "${var.vpc_name}-${var.app_name}-alb-public"
  }
}

## TARGET GROUP LOAD BALANCER
resource "aws_lb_target_group" "target_group_alb" {
  name     = "${var.vpc_name}-${var.app_name}-target"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.discovery.vpc_id

  tags = {
    Name = "${var.vpc_name}-${var.app_name}-alb-http"
  }
}

resource "aws_lb_target_group" "target_group_alb_netdata" {
  name     = "${var.vpc_name}-${var.app_name}-netdata"
  port     = 19999
  protocol = "HTTP"
  vpc_id   = module.discovery.vpc_id

  tags = {
    Name = "${var.vpc_name}-${var.app_name}-alb-netdata"
  }
}

## SECURITY GROUPS
resource "aws_security_group" "secu_group_alb" {
  name        = "${var.vpc_name}-${var.app_name}-security_group_alb"
  description = "Groupe de securite pour le load balancer entree sur le port 80"
  vpc_id      = module.discovery.vpc_id

  tags = {
    Name = "${var.vpc_name}-${var.app_name}-security_group_alb"
  }
}

resource "aws_security_group" "secu_group_app" {
  name        = "${var.vpc_name}-${var.app_name}-security_group_app"
  description = "Groupe de securite pour application entree sur le port 8080"
  vpc_id      = module.discovery.vpc_id

  tags = {
    Name = "${var.vpc_name}-${var.app_name}-security_group_app"
  }
}

## LOAD BALANCER LISTENER
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_alb.arn
  }

  tags = {
    Name = "${var.vpc_name}-${var.app_name}-lb_listener"
  }
}

resource "aws_lb_listener" "lb_listener_netdata" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "19999"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_alb_netdata.arn
  }

  tags = {
    Name = "${var.vpc_name}-netdata-lb_listener"
  }
}

## LAUNCH TEMPLATE
resource "aws_launch_template" "launch_app" {
  instance_type          = "t2.micro"
  key_name               = "${var.vpc_name}-deployer-key"
  vpc_security_group_ids = [aws_security_group.secu_group_app.id]
  image_id               = module.discovery.images_id[0]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.vpc_name}-${var.app_name}-lt"
    }
  }

}

## AUTOSCALING GROUP
resource "aws_autoscaling_group" "alg" {
  name                = "${var.vpc_name}-${var.app_name}-asg"
  vpc_zone_identifier = [for subnet in module.discovery.private_subnets : subnet]
  max_size            = 2
  min_size            = 1
  target_group_arns   = ["${aws_lb_target_group.target_group_alb.arn}", "${aws_lb_target_group.target_group_alb_netdata.arn}"]

  launch_template {
    id      = aws_launch_template.launch_app.id
    version = "$Latest"
  }

}

## SECURITY RULES
# Security rules d'entrées sur le load balancer
resource "aws_security_group_rule" "rule_ingress_alb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secu_group_alb.id
}

# Security rules d'entrées sur le load balancer
resource "aws_security_group_rule" "rule_ingress_alb_netdata" {
  type              = "ingress"
  from_port         = 19999
  to_port           = 19999
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secu_group_alb.id
}

# Security rules de sorties sur le load balancer
resource "aws_security_group_rule" "rule_egress_alb" {
  type              = "egress"
  from_port         = -1
  to_port           = -1
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secu_group_alb.id
}

# Security rules d'entrées sur le launch template, utilisé sur les instances lancer par l'autoscaling
resource "aws_security_group_rule" "rule_ingress_app" {
  type                     = "ingress"
  from_port                = -1 # Avant 8080
  to_port                  = -1 # Avant 8080
  protocol                 = -1
  source_security_group_id = aws_security_group.secu_group_alb.id
  security_group_id        = aws_security_group.secu_group_app.id
}

# Security rules de sorties sur le launch template, utilisé sur les instances lancer par l'autoscaling
resource "aws_security_group_rule" "rule_egress_app" {
  type              = "egress"
  from_port         = -1
  to_port           = -1
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secu_group_app.id
}

## AUTO SCALING POLICIES
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "auto_scaling_policies_up_${var.app_name}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.alg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "auto_scaling_policies_down_${var.app_name}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.alg.name
}

## METRICS
resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name          = "terraform-scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "10"
  metric_name         = "CPUUtilization"
  evaluation_periods  = "1"
  period              = "360"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  alarm_description   = "This metric monitors ec2 cpu utilization and activate alarm when cpu utilization is over 5%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.alg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name          = "terraform-scale-down"
  comparison_operator = "LessThanThreshold"
  threshold           = "5"
  metric_name         = "CPUUtilization"
  evaluation_periods  = "1"
  period              = "360"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  alarm_description   = "This metric monitors ec2 cpu utilization and activate alarm when cpu utilization is less than 5%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.alg.name
  }
}

### Module Main
module "discovery" {
  source         = "github.com/Lowess/terraform-aws-discovery"
  vpc_name       = var.vpc_name
  aws_region     = var.aws_region
  ec2_ami_names  = var.ami_names
  ec2_ami_owners = var.ami_owners
}

output "disco" {
  value = module.discovery
}
