# Notification infra (Outbox -> EventBridge -> SQS -> Notification Consumer -> DynamoDB)

# DynamoDB 알림 테이블 이름
variable "notification_table_name" {
  description = "DynamoDB table name for notifications"
  type        = string
  default     = "stagelog-notifications"
}

# 알림 이벤트를 수신할 EventBridge 버스 이름
variable "notification_event_bus_name" {
  description = "EventBridge bus name for notification events"
  type        = string
  default     = "stagelog-notification-bus"
}

# EventBridge rule에서 필터링할 source 값 목록
variable "notification_event_sources" {
  description = "EventBridge event sources emitted by outbox workers"
  type        = list(string)
  default = [
    "stagelog.core",
    "stagelog.auth",
  ]
}

# EventBridge rule에서 SQS로 전달할 detail-type 목록
variable "notification_event_detail_types" {
  description = "EventBridge detail-types to route to notification queue"
  type        = list(string)
  default = [
    "notification.comment.created",
    "notification.post.liked",
    "notification.post.disliked",
    "notification.event.updated",
    "notification.system.broadcast"
  ]
}

# 변경: consumer 처리 시간 여유를 더 주기 위해 visibility timeout 기본값을 120초로 상향
variable "notification_sqs_visibility_timeout_seconds" {
  description = "SQS visibility timeout for notification consumer"
  type        = number
  default     = 120
}

# 알림 큐/DLQ 메시지 보관 기간
variable "notification_sqs_message_retention_seconds" {
  description = "SQS message retention period"
  type        = number
  default     = 345600
}

# 변경 이유: 빈 응답을 줄이고 비용을 낮추기 위해 long polling 20초로 변경
variable "notification_sqs_receive_wait_time_seconds" {
  description = "SQS long polling wait time"
  type        = number
  default     = 20
}

# 본 큐에서 재시도 실패 시 DLQ로 이동시키는 횟수
variable "notification_sqs_max_receive_count" {
  description = "Max receive count before moving messages to DLQ"
  type        = number
  default     = 5
}

# 변경: SSM 파라미터 경로와 태그에 사용할 환경명을 하드코딩하지 않기 위해 추가
variable "notification_env_name" {
  description = "Environment name used for SSM parameter path and tags"
  type        = string
  default     = "dev"
}

# 변경: backend / consumer / 운영자가 동일한 값을 보게 하기 위해 SSM parameter 저장 여부를 제어
variable "notification_create_ssm_params" {
  description = "Create SSM parameters for notification queue references"
  type        = bool
  default     = true
}

# 변경: 공통 태그를 한 곳에서 관리해 queue / ddb 리소스 관리성을 높임
locals {
  notification_tags = {
    ManagedBy   = "terraform"
    Project     = "stagelog"
    Environment = var.notification_env_name
    Component   = "notifications"
  }
}

# 알림 최종 저장소(DynamoDB): 사용자별 알림 조회 용도
resource "aws_dynamodb_table" "notification" {
  name         = var.notification_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "gsi1pk"
    type = "S"
  }

  attribute {
    name = "gsi1sk"
    type = "S"
  }

  global_secondary_index {
    name            = "gsi1"
    hash_key        = "gsi1pk"
    range_key       = "gsi1sk"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  # 변경: Name 태그만 두지 않고 공통 태그와 함께 관리
  tags = merge(local.notification_tags, {
    Name = "stagelog-notification-table"
  })
}

# 알림 이벤트 전용 커스텀 EventBridge 버스
resource "aws_cloudwatch_event_bus" "notification" {
  name = var.notification_event_bus_name
}

# 실패 메시지 격리를 위한 DLQ
resource "aws_sqs_queue" "notification_dlq" {
  name = "stagelog-notification-dlq"

  message_retention_seconds = var.notification_sqs_message_retention_seconds

  sqs_managed_sse_enabled = true

  # 변경: consumer 처리 시간 여유를 위해 120초 기준으로 통일
  visibility_timeout_seconds = var.notification_sqs_visibility_timeout_seconds

  # 변경: long polling을 명시, 빈 응답과 불필요한 polling을 줄임
  receive_wait_time_seconds = var.notification_sqs_receive_wait_time_seconds

  # 변경: Name 태그만 두지 않고 공통 태그와 함께 관리되도록
  tags = merge(local.notification_tags, {
    Name = "stagelog-notification-dlq"
  })
}

# 알림 소비용 메인 큐
resource "aws_sqs_queue" "notification" {
  name = "stagelog-notification-queue"

  message_retention_seconds = var.notification_sqs_message_retention_seconds

  # 변경: consumer 처리 시간 여유를 위해 120초 기준으로 통일
  visibility_timeout_seconds = var.notification_sqs_visibility_timeout_seconds

  sqs_managed_sse_enabled = true

  # 변경: long polling을 명시, 빈 응답과 불필요한 polling을 줄임
  receive_wait_time_seconds = var.notification_sqs_receive_wait_time_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn
    maxReceiveCount     = var.notification_sqs_max_receive_count
  })

  # 변경: 공통 태그와 함께 관리되도록 정리
  tags = merge(local.notification_tags, {
    Name = "stagelog-notification-queue"
  })
}

# 변경: DLQ를 현재 main queue 1개만 사용하도록 제한
resource "aws_sqs_queue_redrive_allow_policy" "notification_dlq_allow_from_main" {
  queue_url = aws_sqs_queue.notification_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.notification.arn]
  })
}

# EventBridge에서 source/detail-type 기준으로 알림 이벤트를 선별
resource "aws_cloudwatch_event_rule" "notification_to_sqs" {
  name           = "stagelog-notification-to-sqs"
  description    = "Route notification events to SQS"
  event_bus_name = aws_cloudwatch_event_bus.notification.name

  event_pattern = jsonencode({
    source      = var.notification_event_sources
    detail-type = var.notification_event_detail_types
  })
}

# 선별된 이벤트를 메인 SQS 큐로 전달
resource "aws_cloudwatch_event_target" "notification_queue_target" {
  rule           = aws_cloudwatch_event_rule.notification_to_sqs.name
  event_bus_name = aws_cloudwatch_event_bus.notification.name
  target_id      = "notification-sqs"
  arn            = aws_sqs_queue.notification.arn
}

# EventBridge 서비스가 SQS로 SendMessage 할 수 있도록 큐 정책 부여
resource "aws_sqs_queue_policy" "notification_allow_eventbridge" {
  queue_url = aws_sqs_queue.notification.id

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
        Resource = aws_sqs_queue.notification.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.notification_to_sqs.arn
          }
        }
      }
    ]
  })
}

# 변경: backend / consumer / 운영자가 queue URL을 SSM에서 공통으로 읽을 수 있도록 변경
resource "aws_ssm_parameter" "notification_sqs_queue_url" {
  count = var.notification_create_ssm_params ? 1 : 0

  name  = "/stagelog/${var.notification_env_name}/sqs/notifications_queue_url"
  type  = "String"
  value = aws_sqs_queue.notification.id

  tags = local.notification_tags
}

# 변경: IAM / policy / 운영 확인용으로 queue ARN도 SSM에 저장
resource "aws_ssm_parameter" "notification_sqs_queue_arn" {
  count = var.notification_create_ssm_params ? 1 : 0

  name  = "/stagelog/${var.notification_env_name}/sqs/notifications_queue_arn"
  type  = "String"
  value = aws_sqs_queue.notification.arn

  tags = local.notification_tags
}

# 변경: DLQ URL - SSM에 저장 운영 점검과 추후 주입 활용
resource "aws_ssm_parameter" "notification_sqs_dlq_url" {
  count = var.notification_create_ssm_params ? 1 : 0

  name  = "/stagelog/${var.notification_env_name}/sqs/notifications_dlq_url"
  type  = "String"
  value = aws_sqs_queue.notification_dlq.id

  tags = local.notification_tags
}

# 변경: DLQ ARN - SSM에 저장해 정책/운영 점검에 활용
resource "aws_ssm_parameter" "notification_sqs_dlq_arn" {
  count = var.notification_create_ssm_params ? 1 : 0

  name  = "/stagelog/${var.notification_env_name}/sqs/notifications_dlq_arn"
  type  = "String"
  value = aws_sqs_queue.notification_dlq.arn

  tags = local.notification_tags
}

# Notification 서비스에서 참조할 출력값들
output "notification_dynamodb_table_name" {
  value = aws_dynamodb_table.notification.name
}

output "notification_event_bus_name" {
  value = aws_cloudwatch_event_bus.notification.name
}

output "notification_event_bus_arn" {
  value = aws_cloudwatch_event_bus.notification.arn
}

output "notification_sqs_queue_url" {
  value = aws_sqs_queue.notification.url
}

output "notification_sqs_queue_arn" {
  value = aws_sqs_queue.notification.arn
}

output "notification_sqs_dlq_url" {
  value = aws_sqs_queue.notification_dlq.url
}

output "notification_sqs_dlq_arn" {
  value = aws_sqs_queue.notification_dlq.arn
}