variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  description = "Project name for SSM path prefix"
  type        = string
  default     = "stagelog"
}

variable "environment" {
  description = "Environment name for SSM path prefix"
  type        = string
  default     = "dev"
}

variable "kms_key_id" {
  description = "Optional KMS Key ID/ARN for SecureString (empty = aws/ssm)"
  type        = string
  default     = ""
}

variable "secret_key" {
  description = "Django SECRET_KEY"
  type        = string
  sensitive   = true
}

variable "db_password_posts" {
  description = "Posts DB password"
  type        = string
  sensitive   = true
}

variable "db_password_auth" {
  description = "Auth DB password"
  type        = string
  sensitive   = true
}

variable "db_password_events" {
  description = "Events DB password"
  type        = string
  sensitive   = true
}

variable "db_password_notifications" {
  description = "Notifications DB password"
  type        = string
  sensitive   = true
}

variable "jwt_secret_key" {
  description = "Auth Lambda JWT secret key"
  type        = string
  sensitive   = true
}

variable "jwt_public_jwk" {
  description = "Auth Lambda JWT public JWK payload"
  type        = string
  default     = "{}"
}

variable "kakao_rest_api_key" {
  description = "Kakao OAuth REST API key"
  type        = string
  sensitive   = true
}

variable "kakao_access_token_client_secret" {
  description = "Kakao OAuth client secret"
  type        = string
  sensitive   = true
}

variable "kakao_redirect_uri" {
  description = "Kakao OAuth redirect URI"
  type        = string
}

variable "google_rest_api_key" {
  description = "Google OAuth client ID"
  type        = string
  sensitive   = true
}

variable "google_access_token_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  sensitive   = true
}

variable "google_redirect_uri" {
  description = "Google OAuth redirect URI"
  type        = string
}

variable "naver_rest_api_key" {
  description = "Naver OAuth client ID"
  type        = string
  sensitive   = true
}

variable "naver_access_token_client_secret" {
  description = "Naver OAuth client secret"
  type        = string
  sensitive   = true
}

variable "naver_redirect_uri" {
  description = "Naver OAuth redirect URI"
  type        = string
}


variable "auth_lambda_s3_key" {
  description = "Bootstrap S3 object key for auth API lambda artifact"
  type        = string
}

variable "authorizer_lambda_s3_key" {
  description = "Bootstrap S3 object key for authorizer lambda artifact"
  type        = string
}

variable "auth_lambda_s3_object_version" {
  description = "Bootstrap S3 object version for auth API lambda artifact"
  type        = string
  default     = ""
}

variable "authorizer_lambda_s3_object_version" {
  description = "Bootstrap S3 object version for authorizer lambda artifact"
  type        = string
  default     = ""
}
