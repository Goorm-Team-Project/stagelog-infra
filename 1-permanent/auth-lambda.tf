# Auth Lambda resources (auth api + custom authorizer)
# Deployment model:
# - Terraform bootstraps the Lambda resources and runtime settings
# - CI in stagelog-auth updates Lambda function code directly via AWS CLI
# - Runtime config is loaded from SSM prefixes at Lambda cold start

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

variable "redis_port" {
  description = "Redis port used by ElastiCache resources"
  type        = number
  default     = 6379
}

variable "auth_lambda_ssm_prefixes" {
  description = "Optional override for auth lambda SSM prefixes"
  type        = list(string)
  default     = []
}

variable "auth_lambda_ssm_kms_key_arn" {
  description = "Optional customer-managed KMS key ARN used by SecureString auth lambda params"
  type        = string
  default     = ""
}

locals {
  auth_lambda_bootstrap_ssm_prefix = "/${var.project}/${var.env}/bootstrap/auth-lambda"
}

data "aws_ssm_parameter" "auth_lambda_s3_key" {
  name = "${local.auth_lambda_bootstrap_ssm_prefix}/AUTH_LAMBDA_S3_KEY"
}

data "aws_ssm_parameter" "authorizer_lambda_s3_key" {
  name = "${local.auth_lambda_bootstrap_ssm_prefix}/AUTHORIZER_LAMBDA_S3_KEY"
}

data "aws_ssm_parameter" "auth_lambda_s3_object_version" {
  name = "${local.auth_lambda_bootstrap_ssm_prefix}/AUTH_LAMBDA_S3_OBJECT_VERSION"
}

data "aws_ssm_parameter" "authorizer_lambda_s3_object_version" {
  name = "${local.auth_lambda_bootstrap_ssm_prefix}/AUTHORIZER_LAMBDA_S3_OBJECT_VERSION"
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
  auth_lambda_ssm_prefixes = length(var.auth_lambda_ssm_prefixes) > 0 ? var.auth_lambda_ssm_prefixes : [
    "/${var.project}/${var.env}/shared",
    "/${var.project}/${var.env}/auth-lambda",
  ]

  auth_lambda_artifact_config = {
    auth_api_s3_key              = data.aws_ssm_parameter.auth_lambda_s3_key.value
    authorizer_s3_key            = data.aws_ssm_parameter.authorizer_lambda_s3_key.value
    auth_api_s3_object_version   = trimspace(data.aws_ssm_parameter.auth_lambda_s3_object_version.value) != "" ? data.aws_ssm_parameter.auth_lambda_s3_object_version.value : null
    authorizer_s3_object_version = trimspace(data.aws_ssm_parameter.authorizer_lambda_s3_object_version.value) != "" ? data.aws_ssm_parameter.authorizer_lambda_s3_object_version.value : null
  }

  auth_lambda_ssm_parameter_arns = flatten([
    for prefix in local.auth_lambda_ssm_prefixes : [
      "arn:aws:ssm:ap-northeast-2:${data.aws_caller_identity.current.account_id}:parameter${prefix}",
      "arn:aws:ssm:ap-northeast-2:${data.aws_caller_identity.current.account_id}:parameter${prefix}/*",
    ]
  ])

  auth_lambda_env = {
    AUTH_SSM_PREFIXES = join(",", local.auth_lambda_ssm_prefixes)
  }
}

resource "aws_iam_role_policy" "auth_lambda_ssm_read" {
  name = "stagelog-auth-lambda-ssm-read"
  role = aws_iam_role.auth_lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
        ]
        Resource = local.auth_lambda_ssm_parameter_arns
      }
    ]
  })
}

resource "aws_iam_role_policy" "auth_lambda_kms_decrypt" {
  count = var.auth_lambda_ssm_kms_key_arn != "" ? 1 : 0

  name = "stagelog-auth-lambda-kms-decrypt"
  role = aws_iam_role.auth_lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.auth_lambda_ssm_kms_key_arn
      }
    ]
  })
}

resource "aws_lambda_function" "auth_api" {
  function_name     = var.auth_lambda_function_name
  role              = aws_iam_role.auth_lambda_execution_role.arn
  handler           = "app.lambda_handler"
  runtime           = var.auth_lambda_runtime
  architectures     = var.auth_lambda_architectures
  s3_bucket         = aws_s3_bucket.auth_lambda_artifacts.bucket
  s3_key            = local.auth_lambda_artifact_config.auth_api_s3_key
  s3_object_version = local.auth_lambda_artifact_config.auth_api_s3_object_version
  timeout           = var.auth_lambda_timeout
  memory_size       = var.auth_lambda_memory_size

  lifecycle {
    ignore_changes = [
      s3_bucket,
      s3_key,
      s3_object_version,
    ]
  }

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
    aws_iam_role_policy.auth_lambda_ssm_read,
  ]
}

resource "aws_lambda_function" "auth_authorizer" {
  function_name     = var.authorizer_lambda_function_name
  role              = aws_iam_role.auth_lambda_execution_role.arn
  handler           = "handlers.authorizer.lambda_handler"
  runtime           = var.auth_lambda_runtime
  architectures     = var.auth_lambda_architectures
  s3_bucket         = aws_s3_bucket.auth_lambda_artifacts.bucket
  s3_key            = local.auth_lambda_artifact_config.authorizer_s3_key
  s3_object_version = local.auth_lambda_artifact_config.authorizer_s3_object_version
  timeout           = var.authorizer_lambda_timeout
  memory_size       = var.authorizer_lambda_memory_size

  lifecycle {
    ignore_changes = [
      s3_bucket,
      s3_key,
      s3_object_version,
    ]
  }

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
    aws_iam_role_policy.auth_lambda_ssm_read,
  ]
}

output "auth_lambda_invoke_arn" {
  value = aws_lambda_function.auth_api.invoke_arn
}

output "authorizer_lambda_invoke_arn" {
  value = aws_lambda_function.auth_authorizer.invoke_arn
}
