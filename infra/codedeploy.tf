########################
# CodeDeploy Application
########################
resource "aws_codedeploy_app" "this" {
  name             = var.codedeploy_app_name
  compute_platform = "Server"
  tags             = local.common_tags
}

########################
# CodeDeploy Deployment Group (ASG 대상 / IN_PLACE 롤링)
########################
resource "aws_codedeploy_deployment_group" "this" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = var.codedeploy_deployment_group_name
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn

  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  autoscaling_groups = [aws_autoscaling_group.app.name]

  deployment_config_name = "CodeDeployDefault.OneAtATime"

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.api.name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE",
      "DEPLOYMENT_STOP_ON_ALARM",
      "DEPLOYMENT_STOP_ON_REQUEST"
    ]
  }

  tags = local.common_tags
}