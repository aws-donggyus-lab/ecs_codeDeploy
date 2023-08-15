###########################################################################
### ECS EventBridge (Default)
###########################################################################
resource "aws_cloudwatch_event_rule" "ecs_rolling" {
  name = "trigger_on_ecr_deploy_ecs"

  event_pattern = jsonencode({
    detail-type = [
      "ECS Deployment State Change"
    ]
    source = [
      "aws.ecs"
    ]
  })
}


###########################################################################
### ECS EventBridge (Blue/green)
###########################################################################
resource "aws_cloudwatch_event_rule" "ecs_blue_green" {
  name = "ecs_blue_green_bus"

  event_pattern = jsonencode({
    detail = {
      state = [
        "SUCCESS",
        "FAILURE",
        "START",
      ]
    },
    detail-type = [
      "CodeDeploy Deployment State-change Notification"
    ]
    source = [
      "aws.codedeploy"
    ]
  })
}

