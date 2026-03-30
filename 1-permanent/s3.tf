# 이미지 s3
resource "aws_s3_bucket" "stagelog_dev_uploads_v2" {
  bucket = "stagelog-dev-uploads-v2"
  # 모든 퍼블릭 액세스 차단

  tags = { Name = "stagelog-s3-uploads" }
}

# 이미지 S3 PAB All True -> public 회귀 구조적 차단
resource "aws_s3_bucket_public_access_block" "stagelog-dev-uploads-block" {
  bucket = aws_s3_bucket.stagelog_dev_uploads_v2.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 이미지 S3 버킷 정책
resource "aws_s3_bucket_policy" "stagelog-dev-uploads-policy" {
  bucket = aws_s3_bucket.stagelog_dev_uploads_v2.id
  policy = data.aws_iam_policy_document.uploads_cdn_read.json
}

# 이미지 S3 CORS
resource "aws_s3_bucket_cors_configuration" "stagelog-dev-uploads-cors" {
  bucket = aws_s3_bucket.stagelog_dev_uploads_v2.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "HEAD"]
    allowed_origins = var.uploads_cors_allowed_origins # FE 도메인만 허용
    expose_headers  = ["ETag", "x-amz-request-id", "x-amz-id-2"]
    max_age_seconds = 3000
  }
}

# 이미지 S3 객체 소유권 (ACL 비활성화 = BucketOwnerEnforced)
resource "aws_s3_bucket_ownership_controls" "uploads_ownership" {
  bucket = aws_s3_bucket.stagelog_dev_uploads_v2.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 이미지 S3 수명 주기 (삭제 비활성화 + 멀티파트 정리)
resource "aws_s3_bucket_lifecycle_configuration" "uploads_lifecycle" {
  bucket = aws_s3_bucket.stagelog_dev_uploads_v2.id

  rule {
    id     = "uploads-abort-incomplete-mpu"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "uploads_cdn_read" {
  statement {
    sid    = "AllowCloudFrontOACRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.stagelog_dev_uploads_v2.arn}/uploads/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.uploads_cdn.arn]
    }
  }
}

# 1. 프론트엔드 S3 버킷
resource "aws_s3_bucket" "stagelog_frontend" {
  bucket = "stagelog-frontend-bucket"

  tags = {
    Name = "stagelog-frontend"
  }
}

# 2. S3 퍼블릭 액세스 차단 (보안 필수)
resource "aws_s3_bucket_public_access_block" "frontend_all_block" {
  bucket = aws_s3_bucket.stagelog_frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. 정책 연결
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.stagelog_frontend.id
  policy = data.aws_iam_policy_document.frontend_cdn_read.json
}

# 4. 프론트엔드 S3용 정책 (전체 객체 읽기)
data "aws_iam_policy_document" "frontend_cdn_read" {
  statement {
    sid    = "AllowCloudFrontOACRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.stagelog_frontend.arn}/*"] # 모든 정적 파일

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.stagelog_cdn.arn]
    }
  }
}
# Auth Lambda artifact S3 bucket (CI zip upload target)
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "auth_lambda_artifacts" {
  bucket = "stagelog-auth-lambda-artifacts-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "stagelog-auth-lambda-artifacts"
  }
}

resource "aws_s3_bucket_public_access_block" "auth_lambda_artifacts_block" {
  bucket = aws_s3_bucket.auth_lambda_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "auth_lambda_artifacts_ownership" {
  bucket = aws_s3_bucket.auth_lambda_artifacts.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "auth_lambda_artifacts_versioning" {
  bucket = aws_s3_bucket.auth_lambda_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "auth_lambda_artifacts_sse" {
  bucket = aws_s3_bucket.auth_lambda_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
