########################################################################################################################################
### ALB Default
########################################################################################################################################
####################################################################
### aws lb
####################################################################
resource "aws_security_group" "alb_sg" {
  name = "pipeline-todolist-alb-sg"

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
}

resource "aws_lb" "alb" {
  name               = "pipeline-todolist-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = values(local.public_subnets)

  enable_deletion_protection = true

  tags = {
    Name = "pipeline-todolist-alb-sg"
  }
}

####################################################################
### aws target group
####################################################################
resource "aws_lb_target_group" "green" {
  name        = "pipeline-todolist-green-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = local.vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 6
    unhealthy_threshold = 3
  }

  tags = {
    Name = "pipeline-todolist-green-tg"
  }
}

####################################################################
### aws listener
####################################################################
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }
}

########################################################################################################################################
### ALB CodeDeploy
########################################################################################################################################
####################################################################
### aws lb
####################################################################
resource "aws_security_group" "alb_sg-2" {
  name = "pipeline-todolist-alb-sg"

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
}

resource "aws_lb" "alb-2" {
  name               = "pipeline-todolist-alb-bluegreen"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = values(local.public_subnets)

  enable_deletion_protection = true
}

####################################################################
### aws target group
####################################################################
resource "aws_lb_target_group" "blue-2" {
  name        = "blue-tg-bluegreen"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = local.vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 6
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "green-2" {
  name        = "green-tg-bluegreen"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = local.vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 6
    unhealthy_threshold = 3
  }
}

####################################################################
### aws listener
####################################################################
resource "aws_lb_listener" "listener-2" {
  load_balancer_arn = aws_lb.alb-2.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green-2.arn
  }
}