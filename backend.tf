terraform {
  backend "s3" {
    bucket  = "my-terraform-tfstate-bucket-20250321" # 使用するS3バケット名
    key     = "terraform/terraform.tfstate"          # S3内で保存するファイルのパス
    region  = "us-west-2"                            # バケットのリージョン
    encrypt = true                                   # 状態ファイルを暗号化
  }
}

# S3バケット
resource "aws_s3_bucket" "tfstate" {
  bucket = "my-terraform-tfstate-bucket-20250321" # 一意な名前を使うこと
  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = {
    Name = "Terraform State Bucket"
  }
}
resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowAllActions",
        Effect = "Allow",
        Principal = "*", # すべてのエンティティを許可
        Action = "s3:*", # すべてのアクションを許可
        Resource = "${aws_s3_bucket.alb_logs.arn}/*" # バケット内のすべてのオブジェクトを対象
      },
      {
        Sid = "AllowLambdaAccess",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "tfstate_versioning" {
  bucket = aws_s3_bucket.tfstate.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_public_access_block" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "alb-logs-progate-hackathon-20250321" # 一意な名前を使うこと
  force_destroy = true

  tags = {
    Name = "ALB Logs Bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs_public_access" {
  bucket                  = aws_s3_bucket.alb_logs.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_notification" "alb_logs_notification" {
  bucket = aws_s3_bucket.alb_logs.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.log_filter.arn
    events              = ["s3:ObjectCreated:*"] # オブジェクト作成時にトリガー
    filter_prefix       = "logs"               # ログファイルのプレフィックス
  }

  depends_on = [aws_lambda_permission.allow_s3_to_invoke] # Lambda 関数の権限設定に依存
}