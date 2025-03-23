resource "aws_lambda_function" "log_filter" {
  function_name = "alb-log-to-cloudwatch"
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "python3.10" # Node.js でもOK
  handler       = "main.lambda_handler"
  filename      = "lambda_function_payload.zip" # Zip済みコード

  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {
      LOG_GROUP_NAME = "/alb/webhook"
    }
  }
}

resource "aws_lambda_permission" "allow_s3_to_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_filter.function_name
  principal     = "s3.amazonaws.com"

  source_arn = aws_s3_bucket.alb_logs.arn
}