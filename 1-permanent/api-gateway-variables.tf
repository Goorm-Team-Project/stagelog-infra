variable "aws_region" {
  description = "AWS region for API Gateway resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "api_name" {
  description = "API Gateway REST API base name"
  type        = string
  default     = "stagelog-http-api"
}

variable "stage_name" {
  description = "Core REST API stage name"
  type        = string
  default     = "prod"
}

variable "core_api_url" {
  description = "Fallback integration URI when ephemeral listener output is not available."
  type        = string
  default     = ""
}

variable "core_api_host" {
  description = "Core upstream host for TLS verify (optional)."
  type        = string
  default     = ""
}





variable "allowed_cors_origins" {
  description = "Allowed CORS origins for API Gateway"
  type        = list(string)
  default     = ["https://pearlinvest.click"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention days for API Gateway access logs"
  type        = number
  default     = 30
}

variable "api_domain_name" {
  description = "Custom domain name to expose API Gateway"
  type        = string
  # 사용자 요청 기준 고정 도메인
  default = "pearlinvest.click"
}

variable "api_domain_certificate_arn" {
  description = "ACM certificate ARN for API custom domain"
  type        = string
}

variable "create_route53_api_record" {
  description = "Whether to create Route53 A alias record for API custom domain"
  type        = bool
  default     = false
}

variable "route53_hosted_zone_id" {
  description = "Route53 Hosted Zone ID for API custom domain alias record"
  type        = string
  default     = ""
  validation {
    condition     = !var.create_route53_api_record || length(trimspace(var.route53_hosted_zone_id)) > 0
    error_message = "route53_hosted_zone_id is required when create_route53_api_record is true."
  }
}

variable "rest_auth_stage_name" {
  description = "Stage name for REST API auth gateway"
  type        = string
  default     = "prod"
}
