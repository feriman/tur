provider "aws" {
  region = "eu-north-1"
}

resource "aws_launch_configuration" "example" {
  # AMI - Amazon Machine Image
  #
  image_id = "ami-0705384c0b33c194c"
  instance_type = "t3.micro"

  # To access the ID of the security group resource, you are going to need
  # to use a resource attribute reference, which uses the following syntax
  #   <PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>
  # where PROVIDER is the name of the provider (e.g., aws), TYPE is the type
  # of resource (e.g., security_group), NAME is the name of that resource
  # (e.g., the security group is named "instance"), and ATTRIBUTE is either
  # one of the arguments of that resource (e.g., name) or one of the
  # attributes exported by the resource (you can find the list of available
  # attributes in the documentation for each resource). The security group
  # exports an attribute called 'id', so the expression to reference it will
  # look like this:
  #   aws_security_group.instance.id
  #
  security_groups = [aws_security_group.instance.id]

  # The '<<-EOF' and 'EOF' are Terraform's heredoc syntax, which allows you
  # to create multiline strings without having to insert '\n' characters
  # all over the place.
  #
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World!" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }
}

# By default, AWS does not allow any incoming or outgoing traffic from
# an EC2 Instance. To allow the EC2 Instance to receive traffic on port
# 8080, you need to create a security group.
#
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_vpc" "default" {
  default = true
}
