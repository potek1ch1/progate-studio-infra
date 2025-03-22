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