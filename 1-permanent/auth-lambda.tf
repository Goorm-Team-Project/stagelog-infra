# Auth Lambda resources (auth api + custom authorizer)
# Deployment model:
# - CI builds zip artifacts in stagelog-auth repo
# - CI uploads zip to S3
# - Terraform deploys Lambda from S3 object key/version

variable "auth_lambda_s3_bucket" {
  description = "S3 bucket that stores auth lambda zip artifacts"
  type        = string
}

variable "auth_lambda_s3_key" {
  description = "S3 object key for auth API lambda artifact"
  type        = string
}

variable "authorizer_lambda_s3_key" {
  description = "S3 object key for authorizer lambda artifact"
  type        = string
}

variable "auth_lambda_s3_object_version" {
  description = "S3 object version for auth API lambda artifact (optional)"
  type        = string
  default     = null
}

variable "authorizer_lambda_s3_object_version" {
  description = "S3 object version for authorizer lambda artifact (optional)"
  type        = string
  default     = null
}

variable "auth_lambda_function_name" {
  description = "Auth API lambda function name"
  type        = string
  default     = "stagelog-auth-api"
}

variable "authorizer_lambda_function_name" {
  description = "Authorizer lambda function name"
  type        = string
  default     = "stagelog-auth-authorizer"
}

variable "auth_lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "auth_lambda_architectures" {
  description = "Lambda CPU architecture"
  type        = list(string)
  default     = ["arm64"]
}

variable "auth_lambda_timeout" {
  description = "Auth API lambda timeout in seconds"
  type        = number
  default     = 10
}

variable "authorizer_lambda_timeout" {
  description = "Authorizer lambda timeout in seconds"
  type        = number
  default     = 5
}

variable "auth_lambda_memory_size" {
  description = "Auth API lambda memory in MB"
  type        = number
  default     = 512
}

variable "authorizer_lambda_memory_size" {
  description = "Authorizer lambda memory in MB"
  type        = number
  default     = 256
}

variable "jwt_issuer" {
  type    = string
  default = "stagelog-auth"
}

variable "jwt_audience" {
  type    = string
  default = "stagelog-api"
}

variable "jwt_algorithm" {
  type    = string
  default = "HS256"
}

variable "jwt_access_ttl_seconds" {
  type    = string
  default = "1800"
}

variable "jwt_refresh_ttl_seconds" {
  type    = string
  default = "1209600"
}

variable "jwt_secret_key" {
  type      = string
  sensitive = true
}

variable "jwt_public_jwk" {
  type    = string
  default = "{}"
}

variable "db_host" {
  type = string
}

variable "db_port" {
  type    = string
  default = "3306"
}

variable "db_user" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_ssl_ca" {
  type    = string
  default = "/opt/certs/global-bundle.pem"
}

variable "redis_host" {
  type    = string
  default = ""
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "redis_db" {
  type    = string
  default = "0"
}

variable "redis_username" {
  type    = string
  default = ""
}

variable "redis_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "redis_ssl" {
  type    = string
  default = "false"
}

variable "kakao_rest_api_key" {
  type      = string
  sensitive = true
}

variable "kakao_access_token_client_secret" {
  type      = string
  sensitive = true
}

variable "kakao_redirect_uri" {
  type = string
}

variable "google_rest_api_key" {
  type      = string
  sensitive = true
}

variable "google_access_token_client_secret" {
  type      = string
  sensitive = true
}

variable "google_redirect_uri" {
  type = string
}

variable "naver_rest_api_key" {
  type      = string
  sensitive = true
}

variable "naver_access_token_client_secret" {
  type      = string
  sensitive = true
}

variable "naver_redirect_uri" {
  type = string
}

resource "aws_iam_role" "auth_lambda_execution_role" {
  name = "stagelog-auth-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "auth_lambda_basic" {
  role       = aws_iam_role.auth_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "auth_lambda_vpc" {
  role       = aws_iam_role.auth_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

locals {
  auth_lambda_env = {
    JWT_ISSUER                        = var.jwt_issuer
    JWT_AUDIENCE                      = var.jwt_audience
    JWT_ALGORITHM                     = var.jwt_algorithm
    JWT_ACCESS_TTL_SECONDS            = var.jwt_access_ttl_seconds
    JWT_REFRESH_TTL_SECONDS           = var.jwt_refresh_ttl_seconds
    JWT_SECRET_KEY                    = var.jwt_secret_key
    JWT_PUBLIC_JWK                    = var.jwt_public_jwk
    DB_HOST                           = var.db_host
    DB_PORT                           = var.db_port
    DB_USER                           = var.db_user
    DB_PASSWORD                       = var.db_password
    DB_NAME                           = var.db_name
    DB_SSL_CA                         = var.db_ssl_ca
    REDIS_HOST                        = var.redis_host
    REDIS_PORT                        = tostring(var.redis_port)
    REDIS_DB                          = var.redis_db
    REDIS_USERNAME                    = var.redis_username
    REDIS_PASSWORD                    = var.redis_password
    REDIS_SSL                         = var.redis_ssl
    KAKAO_REST_API_KEY                = var.kakao_rest_api_key
    KAKAO_ACCESS_TOKEN_CLIENT_SECRET  = var.kakao_access_token_client_secret
    KAKAO_REDIRECT_URI                = var.kakao_redirect_uri
    GOOGLE_REST_API_KEY               = var.google_rest_api_key
    GOOGLE_ACCESS_TOKEN_CLIENT_SECRET = var.google_access_token_client_secret
    GOOGLE_REDIRECT_URI               = var.google_redirect_uri
    NAVER_REST_API_KEY                = var.naver_rest_api_key
    NAVER_ACCESS_TOKEN_CLIENT_SECRET  = var.naver_access_token_client_secret
    NAVER_REDIRECT_URI                = var.naver_redirect_uri
  }
}

resource "aws_lambda_function" "auth_api" {
  function_name     = var.auth_lambda_function_name
  role              = aws_iam_role.auth_lambda_execution_role.arn
  handler           = "app.lambda_handler"
  runtime           = var.auth_lambda_runtime
  architectures     = var.auth_lambda_architectures
  s3_bucket         = var.auth_lambda_s3_bucket
  s3_key            = var.auth_lambda_s3_key
  s3_object_version = var.auth_lambda_s3_object_version
  timeout           = var.auth_lambda_timeout
  memory_size       = var.auth_lambda_memory_size

  vpc_config {
    subnet_ids = [
      aws_subnet.stagelog-subnet-private-2a.id,
      aws_subnet.stagelog-subnet-private-2c.id,
    ]
    security_group_ids = [aws_security_group.lambda-sg.id]
  }

  environment {
    variables = local.auth_lambda_env
  }

  depends_on = [
    aws_iam_role_policy_attachment.auth_lambda_basic,
    aws_iam_role_policy_attachment.auth_lambda_vpc,
  ]
}

resource "aws_lambda_function" "auth_authorizer" {
  function_name     = var.authorizer_lambda_function_name
  role              = aws_iam_role.auth_lambda_execution_role.arn
  handler           = "handlers.authorizer.lambda_handler"
  runtime           = var.auth_lambda_runtime
  architectures     = var.auth_lambda_architectures
  s3_bucket         = var.auth_lambda_s3_bucket
  s3_key            = var.authorizer_lambda_s3_key
  s3_object_version = var.authorizer_lambda_s3_object_version
  timeout           = var.authorizer_lambda_timeout
  memory_size       = var.authorizer_lambda_memory_size

  vpc_config {
    subnet_ids = [
      aws_subnet.stagelog-subnet-private-2a.id,
      aws_subnet.stagelog-subnet-private-2c.id,
    ]
    security_group_ids = [aws_security_group.lambda-sg.id]
  }

  environment {
    variables = local.auth_lambda_env
  }

  depends_on = [
    aws_iam_role_policy_attachment.auth_lambda_basic,
    aws_iam_role_policy_attachment.auth_lambda_vpc,
  ]
}

output "auth_lambda_invoke_arn" {
  value = aws_lambda_function.auth_api.invoke_arn
}

output "authorizer_lambda_invoke_arn" {
  value = aws_lambda_function.auth_authorizer.invoke_arn
}
