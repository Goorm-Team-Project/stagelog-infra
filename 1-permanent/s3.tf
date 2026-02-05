# 이미지 s3
resource "aws_s3_bucket" "stagelog-dev-uploads-v2" {
    bucket = "stagelog-dev-uploads-v2"
    # 모든 퍼블릭 액세스 차단

    tags = { Name = "stagelog-s3-uploads" }
}

# 이미지 S3 PAB All True -> public 회귀 구조적 차단
resource "aws_s3_bucket_public_access_block" "stagelog-dev-uploads-block" {
    bucket = aws_s3_bucket.stagelog-dev-uploads-v2.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

# 이미지 S3 버킷 정책
resource "aws_s3_bucket_policy" "stagelog-dev-uploads-policy" {
    bucket = aws_s3_bucket.stagelog-dev-uploads-v2.id

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
    bucket = aws_s3_bucket.stagelog-dev-uploads-v2.id

    cors_rule {
        allowed_headers = ["*"]
        allowed_methods = ["GET", "PUT", "HEAD"]
        allowed_origins = ["*"]
        expose_headers = ["ETag", "x-amz-request-id", "x-amz-id-2"]
        max_age_seconds = 3000
    }
}

# 이미지 S3 객체 소유권 (ACL 비활성화 = BucketOwnerEnforced)
resource "aws_s3_bucket_ownership_controls" "uploads_ownership" {
    bucket = aws_s3_bucket.stagelog-dev-uploads-v2.id

    rule {
        object_ownership = "BucketOwnerEnforced"
    }
}

# 이미지 S3 수명 주기 (삭제 비활성화 + 멀티파트 정리)
resource "aws_s3_bucket_lifecycle_configuration" "uploads_lifecycle" {
    bucket = aws_s3_bucket.stagelog-dev-uploads-v2.id

    rule {
        id = "uploads-abort-incomplete-mpu"
        status = "Enabled"

        filter {
            prefix = "uploads/"
        }

        abort_incomplete_multipart_upload {
            days_after_initiation = 7
        }
    }
}