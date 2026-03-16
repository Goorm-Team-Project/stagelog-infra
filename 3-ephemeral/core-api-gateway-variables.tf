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

variable "authorizer_lambda_function_name" {
  description = "Auth authorizer Lambda function name managed in 1-permanent stack"
  type        = string
  default     = "stagelog-auth-authorizer"
}

variable "auth_api_lambda_function_name" {
  description = "Auth API Lambda function name managed in 1-permanent stack"
  type        = string
  default     = "stagelog-auth-api"
}
