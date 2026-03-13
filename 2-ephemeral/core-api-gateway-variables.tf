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
  description = "REST API integration URI for core service (must be full http/https URL)."
  type        = string

  validation {
    condition     = can(regex("^https?://", trimspace(var.core_api_url)))
    error_message = "core_api_url must be a non-empty URL starting with http:// or https://."
  }
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
  default     = "pearlinvest.click"
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

variable "authorizer_lambda_function_name" {
  description = "Auth authorizer Lambda function name managed in 1-permanent stack"
  type        = string
  default     = "stagelog-auth-authorizer"
}
