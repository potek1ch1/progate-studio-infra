
resource "aws_s3_bucket_policy" "tfstate_bucket_policy" {
  bucket = aws_s3_bucket.tfstate.id

  depends_on = [aws_s3_bucket_public_access_block.tfstate_public_access_block]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "*" # 作成したIAMロールを指定
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::my-terraform-tfstate-bucket-20250321",
          "arn:aws:s3:::my-terraform-tfstate-bucket-20250321/*"
        ]
      }
    ]
  })
}