###########################################################################
### ECS EventBridge (Default)
###########################################################################

resource "aws_cloudwatch_event_rule" "ecs" {
  name        = "capture-aws-sign-in"
  description = "Capture each AWS Console Sign In"

  event_pattern = jsonencode({
    detail-type = [
      "AWS Console Sign In via CloudTrail"
    ]
  })
}