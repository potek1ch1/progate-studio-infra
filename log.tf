resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/progate-service"
  retention_in_days = 7 # 必要に応じてログ保持期間を設定
  tags = {
    Environment = "production"
    Project     = "ProgateHackathon"
  }
}