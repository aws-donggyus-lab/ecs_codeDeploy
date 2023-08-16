#############################################################
# ECS Cluster
#############################################################
resource "aws_ecs_cluster" "cluster" {
  name = "todolist-cluster-poc"
}

resource "aws_ecs_cluster_capacity_providers" "cluster-provider" {
  cluster_name       = aws_ecs_cluster.cluster.name
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

#############################################################
# ECS Task Definition
#############################################################
resource "aws_security_group" "todolist-ecs-sg" {
  name   = "pipeline-todolist-ecs-sg"
  vpc_id = local.vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = ["sg-0635d82f308852a7a"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "todolist-ecs-sg"
  }
}

#########################################################################
#### container_definitions.name 과 aws_ecs_service의 load_balancer에 container name이 같아야합니다.
#########################################################################
resource "aws_ecs_task_definition" "task_definition" {
  family                   = "todolist-family"
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
          "awslogs-group"         = "/ecs/todolist-ecs-poc" # CloudWatch 로그 그룹 이름
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
resource "aws_ecs_service" "service" {
  launch_type     = "FARGATE"
  name            = "todolist-container"
  cluster         = aws_ecs_cluster.cluster.arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = true
    subnets          = values(local.public_subnets)
    security_groups  = [aws_security_group.todolist-ecs-sg.id]
  }

  force_new_deployment = true

  #   deployment_controller {
  #     type = "CODE_DEPLOY"
  #   }

  load_balancer {
    target_group_arn = aws_lb_target_group.green.arn
    container_name   = "todolist-container"
    container_port   = 3000
  }

  ## 서비스를 중단하지 않고, 새로운 서비스가 활성화된 경우에만 폐기된다.
    lifecycle {
      ignore_changes = [ 
        task_definition
       ]
    }
}
