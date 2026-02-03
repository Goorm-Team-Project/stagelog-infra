# 이미지 s3
resource "aws_s3_bucket" "stagelog-dev-uploads" {
    bucket = "stagelog-dev-uploads"
    # 모든 퍼블릭 액세스 차단 허용

    tags = { Name = "stagelog-s3-uploads" }
}

resource "aws_s3_bucket_public_access_block" "stagelog-dev-uploads-block" {
    bucket = aws_s3_bucket.stagelog-dev-uploads.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
}

# 이미지 S3 버킷 정책
resource "aws_s3_bucket_policy" "stagelog-dev-uploads-policy" {
    bucket = aws_s3_bucket.stagelog-dev-uploads.id

    depends_on = [aws_s3_bucket_public_access_block.stagelog-dev-uploads-block] // S3 버킷 퍼블릭 액세스 블록 리소스에 의존

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = "*"
                Action = [
                    "s3:GetObject"
                ]
                Resource = "${aws_s3_bucket.stagelog-dev-uploads.arn}/uploads/*"
            }
        ]
    })
}

# 이미지 S3 CORS
resource "aws_s3_bucket_cors_configuration" "stagelog-dev-uploads-cors" {
    bucket = aws_s3_bucket.stagelog-dev-uploads.id

    cors_rule {
        allowed_headers = ["*"]
        allowed_methods = ["GET", "PUT", "HEAD"]
        allowed_origins = ["*"]
        expose_headers = ["ETag", "x-amz-request-id", "x-amz-id-2"]
        max_age_seconds = 3000
    }
}