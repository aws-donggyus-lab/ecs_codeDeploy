# Donggyu AWS Architecture

![arch](./public/arch.png)

## AWS Resource

- s3_bucket

  - dk-poc-tfstate

- ECS (Default)
  - infra/ecs/ecs.tf
- ECS (Blue/green)

  - infra/ecs-alb-code-deploy.tf

- ECS ALB (alb-bluegreen-505545945.ap-northeast-2.elb.amazonaws.com)

## use AWS Secret Manager

- AWS secret Manager는 -> KMS가 보안을 지켜준다.
- Access Token 같은 경우 사용해도 될듯 (계속 변하게도 해준다...)

- 원래의 Task-Definition

```json
{
  "containerDefinitions": [
    {
      "name": "todolist-container",
      "image": "182024812696.dkr.ecr.ap-northeast-2.amazonaws.com/todolist-repository:build-&&BUILD_ID&&",
      "cpu": 256,
      "memory": 512,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "environment": [
        {
          "name": "DB_NAME",
          "value": "todomini"
        },
        {
          "name": "PORT",
          "value": "3000"
        },
        {
          "name": "DB_PORT",
          "value": "3306"
        },
        {
          "name": "DB_HOST",
          "value": "leedonggyu-todolist-rds.cklbb0dz81o2.ap-northeast-2.rds.amazonaws.com"
        },
        {
          "name": "DB_USER",
          "value": "root"
        },
        {
          "name": "DB_PASSWORD",
          "value": "12341234"
        },
        {
          "name": "VERSION",
          "value": "&&BUILD_ID&&"
        },
        {
          "name": "NAME",
          "value": "leedonggyu"
        },
        {
          "name": "AGE",
          "value": "30"
        },
        {
          "name": "PER",
          "value": "Good"
        }
      ],
      "mountPoints": [],
      "volumesFrom": [],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-create-group": "true",
          "awslogs-group": "/ecs/todolist-ecs-family",
          "awslogs-region": "ap-northeast-2",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "family": "todolist-family",
  "taskRoleArn": "arn:aws:iam::182024812696:role/ecs-deploy-role",
  "executionRoleArn": "arn:aws:iam::182024812696:role/ecs-deploy-role",
  "networkMode": "awsvpc",
  "volumes": [],
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512"
}
```

- AWS Secret Manager를 사용하려면

  1. iam에 추가 secretemanagers 추가해야함

  ```
    추가 안해주면 에러남...
    ResourceInitializationError: unable to pull secrets or registry auth: execution resource retrieval failed: unable to retrieve secret from asm: service call has been retried 1 time(s): failed to fetch secret arn:aws:secretsmanager:ap-northeast-2:182024812696:secret:ecs/todolist/env-fRgf7a/NAME from secrets manager: ResourceNotFoundException: Secrets Manager can't find the specified secret.
  ```

  ```terraform
    resource "aws_iam_policy" "secret_manager" {
      name = "secret_manager"
      path = "/"

      policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameters",
            "secretsmanager:GetSecretValue",
            "kms:Decrypt"
          ],
          "Resource" : [
            "arn:aws:ssm:*",
            "arn:aws:secretsmanager:*",
            "arn:aws:kms:*"
          ]
        }
      ]
    })
  }
  ```

  2. secerts 블록에 넣어야 함

  ```
  "secrets": [
        {
          "name": "NAME",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-2:182024812696:secret:ecs/todolist/env-fRgf7a:NAME::"
        },
        {
          "name": "AGE",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-2:182024812696:secret:ecs/todolist/env-fRgf7a:AGE::"
        },
        {
          "name": "PER",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-2:182024812696:secret:ecs/todolist/env-fRgf7a:PER::"
        }
      ],
  ```

  3. 특징

  - 민감한 자료들은 env로 관리...
  - env수정해도 배포 따로 안해도 될듯???

- S3 bucket에 .env를 넣는다면

  - environmentsFiles에 넣어도 되는데 과연 S3가 보안적으로 이슈가 없을까?

- codeDeploy 문제
  - codeDeploy 상태에서 ecs 문제가 생겼을때, codeDeploy 상태에서 멈춤
  - blue + green 배포 시 green 상태에서 롤백하면 -> blue로 타겟이 됨... 그상태에서 terraform apply 하면 난리남 (ecs service의 alb가 없어짐..)
  - blue가 default로 되어있다면 -> blue 상태에서 배포 -> 배포 그리고 롤백하면 green으로 바뀜

## (ECS) Rolling Update vs Blue/Green 배포 Benchmark

1.  두 케이스 모두 같은 이미지사용 (/apiserver/Dockerfile)
2.  ECS DeploymentChange 값으로 측정 (EventBridge -> Lambda -> Slack Notification)
3.  Deploy (Bluegreen Refactroing)

- Deregistration delay (등록 취소 지연) 값 300 -> 5
- 등록취소가 진행중 일때, 대상에서 실행중인 요청이 모두 완료될때까지 대기함 -> 느린업로드나 스트리밍 연결에서는 Requied

| seconds                        | Rolling Update | Blue/green (AllAtOnce) |
| ------------------------------ | -------------- | ---------------------- |
| Deploy (Default)               | 163 (seconds)  | 170 (seconds)          |
| Deploy (Deregistration deploy) | 133 (seconds)  | 143 (seconds)          |
