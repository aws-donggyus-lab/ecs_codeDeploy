locals {
  vpc            = data.terraform_remote_state.vpc.outputs.value
  vpc_id         = local.vpc.id
  public_subnets = local.vpc.public_subnets

  iam            = data.terraform_remote_state.iam.outputs.value
  ecs_iam        = local.iam.ecs_iam
  codeDeploy_iam = local.iam.codeDeploy_iam
}