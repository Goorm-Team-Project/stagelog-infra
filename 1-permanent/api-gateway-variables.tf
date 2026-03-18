variable "log_retention_days" {
  description = "CloudWatch log retention days for API Gateway access logs"
  type        = number
  default     = 30
}
