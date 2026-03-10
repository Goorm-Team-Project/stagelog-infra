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

# Required secure values
variable "secret_key" {
  description = "Django SECRET_KEY"
  type        = string
  sensitive   = true
}

variable "db_password_core" {
  description = "Core DB password"
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
