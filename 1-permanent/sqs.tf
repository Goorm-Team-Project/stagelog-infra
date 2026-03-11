# SQS + DLQ

# Variables
variable "project" {
  type        = string
  description = "stagelog"
  default     = "stagelog"
}

variable "env" {
  type        = string
  description = "dev, stg, prod"
  default     = "dev"
}

variable "name_prefix" {
  type        = string
  description = "Optional prefix override"
  default     = ""
}

# 메시지 중복 처리, 데이터 유실 예방
variable "sqs_visibility_timeout_seconds" {
  type        = number
  description = "Visibility timeout must be > max message processing time"
  default     = "60"
}

# 메시지 보관 기간: 처리 삭제 전까지 Queue에서 보관되는 기간(TTL)
variable "sqs_message_retention_seconds" {
  type        = number
  description = "How long messages are kept in the queue"
  default     = 1209600 # 14일
}

# Short Polling(0): Trade-offs(즉시 응답, 높은 비용), Long Polling(10~20): Trade-offs(대기후 응답, 비용 절감)
variable "sqs_receive_wait_time_seconds" {
  type        = number
  description = "Long polling wait time (0~20). Recommend 10~20 for cost reduction"
  default     = 10
}

# 실패 메시지가 DLQ로 이동 전 재시도 횟수(5, 중위값): Trade-offs(일시적 오류 일부 해소, 자원 소모 일부 해소)
variable "dlq_max_receive_count" {
  type        = number
  description = "How many times a message can be received before going to DLQ"
  default     = 5
}

variable "common_tags" {
  type        = map(string)
  description = "common tags for all resources"
  default = {
    ManagedBy = "terraform"
    Project   = "stagelog"
  }
}

# ESO용 Queue 관련 정보 SSM Parameter Store 저장-가져오기 구조
variable "create_ssm_params" {
  type        = bool
  description = "Create SSM parameters for queue url/arn"
  default     = true
}

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

  # SQS 암호화(SSE-SQS) 코드 레벨 명시
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

  # DLQ Policy : redrive to DLQ N receives
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = var.dlq_max_receive_count
  })

  tags = local.tags
}

# Queue와 DLQ를 1:1 매핑하여 보안, 관리 효율성 확보
resource "aws_sqs_queue_redrive_allow_policy" "dlq_allow_from_main" {
  queue_url = aws_sqs_queue.notifications_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.notifications_queue.arn]
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