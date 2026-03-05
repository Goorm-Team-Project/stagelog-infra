# Notification infra (Outbox -> EventBridge -> SQS -> Notification Consumer -> DynamoDB)

variable "notification_table_name" {
  description = "DynamoDB table name for notifications"
  type        = string
  default     = "stagelog-notifications"
}

variable "notification_event_bus_name" {
  description = "EventBridge bus name for notification events"
  type        = string
  default     = "stagelog-notification-bus"
}

variable "notification_event_source" {
  description = "EventBridge event source emitted by outbox worker"
  type        = string
  default     = "stagelog.core"
}

variable "notification_event_detail_types" {
  description = "EventBridge detail-types to route to notification queue"
  type        = list(string)
  default = [
    "notification.comment.created",
    "notification.post.liked",
    "notification.reply.created",
    "notification.system.broadcast"
  ]
}

variable "notification_sqs_visibility_timeout_seconds" {
  description = "SQS visibility timeout for notification consumer"
  type        = number
  default     = 60
}

variable "notification_sqs_message_retention_seconds" {
  description = "SQS message retention period"
  type        = number
  default     = 345600
}

variable "notification_sqs_max_receive_count" {
  description = "Max receive count before moving messages to DLQ"
  type        = number
  default     = 5
}

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

  tags = {
    Name = "stagelog-notification-table"
  }
}

resource "aws_cloudwatch_event_bus" "notification" {
  name = var.notification_event_bus_name
}

resource "aws_sqs_queue" "notification_dlq" {
  name                       = "stagelog-notification-dlq"
  message_retention_seconds  = var.notification_sqs_message_retention_seconds
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = var.notification_sqs_visibility_timeout_seconds

  tags = {
    Name = "stagelog-notification-dlq"
  }
}

resource "aws_sqs_queue" "notification" {
  name                       = "stagelog-notification-queue"
  message_retention_seconds  = var.notification_sqs_message_retention_seconds
  visibility_timeout_seconds = var.notification_sqs_visibility_timeout_seconds
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn
    maxReceiveCount     = var.notification_sqs_max_receive_count
  })

  tags = {
    Name = "stagelog-notification-queue"
  }
}

resource "aws_cloudwatch_event_rule" "notification_to_sqs" {
  name           = "stagelog-notification-to-sqs"
  description    = "Route notification events to SQS"
  event_bus_name = aws_cloudwatch_event_bus.notification.name

  event_pattern = jsonencode({
    source      = [var.notification_event_source]
    detail-type = var.notification_event_detail_types
  })
}

resource "aws_cloudwatch_event_target" "notification_queue_target" {
  rule           = aws_cloudwatch_event_rule.notification_to_sqs.name
  event_bus_name = aws_cloudwatch_event_bus.notification.name
  target_id      = "notification-sqs"
  arn            = aws_sqs_queue.notification.arn
}

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
