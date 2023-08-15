#######################################################################################################################################
### ALB CodeDeploy
########################################################################################################################################
####################################################################
### aws lb
####################################################################
resource "aws_security_group" "alb_sg-2" {
  name = "bluegreen-todolist-alb-sg"

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

resource "aws_lb" "alb-bluegreen" {
  name               = "alb-bluegreen"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = values(local.public_subnets)

  enable_deletion_protection = true
}

####################################################################
### aws target group
####################################################################
resource "aws_lb_target_group" "blue-bluegreen" {
  name        = "bluegreen-blue-tg"
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

resource "aws_lb_target_group" "green-bluegreen" {
  name        = "bluegreen-green-tg"
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
resource "aws_lb_listener" "listener-bluegreen" {
  load_balancer_arn = aws_lb.alb-bluegreen.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green-bluegreen.arn
  }
}


#############################################################
# ECS Cluster
#############################################################
resource "aws_ecs_cluster" "cluster-codedeploy" {
  name = "todolist-cluster-codedeploy"
}

resource "aws_ecs_cluster_capacity_providers" "cluster-provider-codedeploy" {
  cluster_name       = aws_ecs_cluster.cluster-codedeploy.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 3
  }
}

#########################################################################
#### container_definitions.name 과 aws_ecs_service의 load_balancer에 container name이 같아야합니다.
#########################################################################
resource "aws_ecs_task_definition" "task_definition-codedeploy" {
  family                   = "todolist-codedeploy-family"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  execution_role_arn = local.ecs_iam
  task_role_arn      = local.ecs_iam
  network_mode       = "awsvpc"

  container_definitions = jsonencode([
    {
      name      = "todolist-container"
      image     = "zkfmapf123/healthcheck"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [{
        "containerPort" : 3000,
        "hostPort" : 3000,
        "protocol" : "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/todolist-codedeploy-ecs-poc" # CloudWatch 로그 그룹 이름
          "awslogs-create-group"  = "true"
          "awslogs-region"        = "ap-northeast-2" # AWS 리전 이름
          "awslogs-stream-prefix" = "ecs"            # 로그 스트림의 접두사
        }
      },
      environment = [
        {
          "name" : "PORT",
          "value" : "3000"
        }
      ]
    }
  ])
}

## 기존 서비스는 삭제되고 만들어짐 (CodeDeploy용으로...)
resource "aws_ecs_service" "service-codedeploy" {
  launch_type     = "FARGATE"
  name            = "todolist-container"
  cluster         = aws_ecs_cluster.cluster-codedeploy.arn
  task_definition = aws_ecs_task_definition.task_definition-codedeploy.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = true
    subnets          = values(local.public_subnets)
    security_groups  = [aws_security_group.todolist-ecs-sg.id]
  }

  force_new_deployment = true

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green-bluegreen.arn
    container_name   = "todolist-container"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [
    #   "load_balancer",
      "task_definition",
    ]
  }
}


############################################
## ECS Code Deploy
############################################
resource "aws_codedeploy_app" "ecs_code_deploy" {
  compute_platform = "ECS"
  name             = "todolist-codeDeploy"
}

resource "aws_codedeploy_deployment_group" "ecs_code_deploy_group" {
  app_name               = aws_codedeploy_app.ecs_code_deploy.name
  deployment_group_name  = "bluegreen-deploy"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = local.codeDeploy_iam

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster-codedeploy.name
    service_name = aws_ecs_service.service-codedeploy.name
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.listener-bluegreen.arn]
      }

      ## Blue
      target_group {
        name = aws_lb_target_group.blue-bluegreen.name
      }

      ## Green
      target_group {
        name = aws_lb_target_group.green-bluegreen.name
      }
    }
  }
}


