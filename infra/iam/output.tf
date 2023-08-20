output "value" {
  value = {
    ecs_iam        = aws_iam_role.ecs.arn
    codeDeploy_iam = aws_iam_role.codedeploy.arn
  }
}