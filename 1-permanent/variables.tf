variable "project" {
  description = "Project name used for shared naming and SSM path prefixes"
  type        = string
  default     = "stagelog"
}

variable "env" {
  description = "Environment name used for shared naming and SSM path prefixes"
  type        = string
  default     = "dev"
}

variable "db_password" {
  description = "RDS master password used only when manage_new_rds=true"
  type        = string
  sensitive   = true
  default     = null
}

########################################
# EC2 Key Pair name
########################################
variable "key_name" {
  description = "AWS EC2 Key Pair name (without .pem)"
  type        = string
  default     = "mykey-251114"
}

########################################
# My public IP for SSH
########################################
variable "my_ip" {
  description = "My public IP address for SSH access"
  type        = list(string)
  default = [
    "58.120.222.88/32",   # 신희씨 IP
    "118.216.139.140/32", # 우성씨 IP
    "180.66.77.93/32",    # 두용씨 IP
    "58.120.222.88/32",   # 희수씨 IP
    "116.121.59.73/32"    # 한용씨 IP
  ]
}

variable "uploads_cors_allowed_origins" {
  description = "Allowed origins for browser PUT to S3 (presigned upload)"
  type        = list(string)
  default     = ["https://pearlinvest.click"] #localhost 접속 미허용
}
