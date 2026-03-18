# Notification SQS + DLQ
# - main queue 1개
# - DLQ 1개
# - EventBridge -> SQS 허용 policy
# - SSM Parameter 저장

# Variables

variable "project" {
  type        = string
  description = "Project name"
  default     = "stagelog"
}

variable "env" {
  type        = string
  description = "Environment name (dev, stg, prod)"
  default     = "dev"
}

variable "name_prefix" {
  type        = string
  description = "Optional prefix override"
  default     = ""
}

# 메시지 처리 시간이 길어도 중복 수신되지 않도록: 기본값 120초
variable "sqs_visibility_timeout_seconds" {
  type        = number
  description = "Visibility timeout must be longer than max processing time"
  default     = 120
}

# 메시지 보관 기간: 14일
variable "sqs_message_retention_seconds" {
  type        = number
  description = "How long messages are kept in the queue"
  default     = 1209600
}

# Long polling: 비용/빈 응답 감소를 위해 20초
variable "sqs_receive_wait_time_seconds" {
  type        = number
  description = "Long polling wait time (0~20)"
  default     = 20
}

# 여러 번 실패한 메시지는 DLQ로 이동
variable "dlq_max_receive_count" {
  type        = number
  description = "How many times a message can be received before moving to DLQ"
  default     = 5
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default = {
    ManagedBy = "terraform"
    Project   = "stagelog"
  }
}

variable "create_ssm_params" {
  type        = bool
  description = "Create SSM parameters for queue url/arn"
  default     = true
}

# EventBridge rule ARN 목록
# - 아직 rule이 없으면 [] 그대로 두면 queue policy는 생성되지 않음
variable "eventbridge_rule_arns" {
  type        = string
  description = "EventBridge rule ARNs allowed to send messages to notifications queue"
  default     = "arn:aws:events:ap-northeast-2:430118823715:rule/stagelog-notification-bus/stagelog-notification-to-sqs"
}


# Locals

locals {
  prefix = length(var.name_prefix) > 0 ? var.name_prefix : "${var.project}-${var.env}"

  queue_name = "${local.prefix}-notifications-queue"
  dlq_name   = "${local.prefix}-notifications-dlq"

  tags = merge(var.common_tags, {
    Environment = var.env
    Component   = "notifications"
  })
}


# DLQ

resource "aws_sqs_queue" "notifications_dlq" {
  name = local.dlq_name

  # SQS 기본 서버사이드 암호화
  sqs_managed_sse_enabled = true

  message_retention_seconds = var.sqs_message_retention_seconds
  receive_wait_time_seconds = var.sqs_receive_wait_time_seconds

  tags = local.tags
}


# Main Queue


resource "aws_sqs_queue" "notifications_queue" {
  name = local.queue_name

  sqs_managed_sse_enabled = true

  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds
  receive_wait_time_seconds  = var.sqs_receive_wait_time_seconds

  # 실패 메시지는 DLQ로 이동
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = var.dlq_max_receive_count
  })

  tags = local.tags
}


# DLQ allow policy

# 이 DLQ는 현재 main queue 1개만 redrive 허용
resource "aws_sqs_queue_redrive_allow_policy" "dlq_allow_from_main" {
  queue_url = aws_sqs_queue.notifications_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.notifications_queue.arn]
  })
}


# EventBridge -> SQS policy

# EventBridge rule이 실제로 있을 때만 생성
resource "aws_sqs_queue_policy" "notifications_from_eventbridge" {
  count = length(var.eventbridge_rule_arns) > 0 ? 1 : 0

  queue_url = aws_sqs_queue.notifications_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.notifications_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.eventbridge_rule_arns
          }
        }
      }
    ]
  })
}


# SSM Parameters

resource "aws_ssm_parameter" "notifications_queue_url" {
  count = var.create_ssm_params ? 1 : 0

  name  = "/${var.project}/${var.env}/sqs/notifications_queue_url"
  type  = "String"
  value = aws_sqs_queue.notifications_queue.id

  tags = local.tags
}

resource "aws_ssm_parameter" "notifications_queue_arn" {
  count = var.create_ssm_params ? 1 : 0

  name  = "/${var.project}/${var.env}/sqs/notifications_queue_arn"
  type  = "String"
  value = aws_sqs_queue.notifications_queue.arn

  tags = local.tags
}

resource "aws_ssm_parameter" "notifications_dlq_url" {
  count = var.create_ssm_params ? 1 : 0

  name  = "/${var.project}/${var.env}/sqs/notifications_dlq_url"
  type  = "String"
  value = aws_sqs_queue.notifications_dlq.id

  tags = local.tags
}

resource "aws_ssm_parameter" "notifications_dlq_arn" {
  count = var.create_ssm_params ? 1 : 0

  name  = "/${var.project}/${var.env}/sqs/notifications_dlq_arn"
  type  = "String"
  value = aws_sqs_queue.notifications_dlq.arn

  tags = local.tags
}