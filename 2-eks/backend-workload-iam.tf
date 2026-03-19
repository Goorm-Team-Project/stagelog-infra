data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  backend_uploads_bucket_name = data.terraform_remote_state.permanent.outputs.uploads_bucket_name
  backend_notification_table  = data.terraform_remote_state.permanent.outputs.notification_dynamodb_table_name
  backend_event_bus_arn       = data.terraform_remote_state.permanent.outputs.notification_event_bus_arn
  backend_queue_arn           = data.terraform_remote_state.permanent.outputs.notification_sqs_queue_arn
  backend_dlq_arn             = data.terraform_remote_state.permanent.outputs.notification_sqs_dlq_arn
}

resource "aws_iam_policy" "backend_workload" {
  name        = "stagelog-backend-workload-policy"
  description = "Allow backend pods to access S3 uploads, DynamoDB notifications, SQS notifications, and EventBridge"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UploadsBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.backend_uploads_bucket_name}",
          "arn:aws:s3:::${local.backend_uploads_bucket_name}/uploads/*"
        ]
      },
      {
        Sid    = "NotificationsTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.backend_notification_table}",
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.backend_notification_table}/index/*"
        ]
      },
      {
        Sid    = "NotificationQueueAccess"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          local.backend_queue_arn,
          local.backend_dlq_arn
        ]
      },
      {
        Sid    = "NotificationEventBusAccess"
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = [
          local.backend_event_bus_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "backend_workload" {
  name = "stagelog-backend-workload-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_oidc.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:dev-backend:stagelog-backend-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backend_workload_attach" {
  role       = aws_iam_role.backend_workload.name
  policy_arn = aws_iam_policy.backend_workload.arn
}
