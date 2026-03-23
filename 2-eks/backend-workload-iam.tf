data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  backend_uploads_bucket_name = data.terraform_remote_state.permanent.outputs.uploads_bucket_name
  backend_notification_table  = data.terraform_remote_state.permanent.outputs.notification_dynamodb_table_name
  backend_event_bus_arn       = data.terraform_remote_state.permanent.outputs.notification_event_bus_arn
  backend_queue_arn           = data.terraform_remote_state.permanent.outputs.notification_sqs_queue_arn
  backend_dlq_arn             = data.terraform_remote_state.permanent.outputs.notification_sqs_dlq_arn

  workload_namespace                          = "dev-backend"
  legacy_backend_service_account_name         = "stagelog-backend-sa"
  posts_service_account_name                  = "stagelog-posts-sa"
  notifications_api_service_account_name      = "stagelog-notifications-api-sa"
  notifications_consumer_service_account_name = "stagelog-notifications-consumer-sa"
  outbox_worker_service_account_name          = "stagelog-outbox-worker-sa"
  oidc_sub_key                                = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
}

resource "aws_iam_policy" "backend_workload" {
  name        = "stagelog-backend-workload-policy"
  description = "Legacy combined backend workload policy"

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
            (local.oidc_sub_key) = "system:serviceaccount:${local.workload_namespace}:${local.legacy_backend_service_account_name}"
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

resource "aws_iam_policy" "posts_workload" {
  name        = "stagelog-posts-workload-policy"
  description = "Allow posts API pod to create S3 presigned uploads"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UploadsObjectPutAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.backend_uploads_bucket_name}/uploads/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "posts_workload" {
  name = "stagelog-posts-workload-role"

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
            (local.oidc_sub_key) = "system:serviceaccount:${local.workload_namespace}:${local.posts_service_account_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "posts_workload_attach" {
  role       = aws_iam_role.posts_workload.name
  policy_arn = aws_iam_policy.posts_workload.arn
}

resource "aws_iam_policy" "notifications_api_workload" {
  name        = "stagelog-notifications-api-workload-policy"
  description = "Allow notifications API pod to query and update notification records in DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "NotificationsQueryAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.backend_notification_table}",
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.backend_notification_table}/index/*"
        ]
      },
      {
        Sid    = "NotificationsUpdateAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.backend_notification_table}"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "notifications_api_workload" {
  name = "stagelog-notifications-api-workload-role"

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
            (local.oidc_sub_key) = "system:serviceaccount:${local.workload_namespace}:${local.notifications_api_service_account_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "notifications_api_workload_attach" {
  role       = aws_iam_role.notifications_api_workload.name
  policy_arn = aws_iam_policy.notifications_api_workload.arn
}

resource "aws_iam_policy" "notifications_consumer_workload" {
  name        = "stagelog-notifications-consumer-workload-policy"
  description = "Allow notifications consumer pod to consume SQS messages and persist them into DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "NotificationQueueConsumeAccess"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          local.backend_queue_arn
        ]
      },
      {
        Sid    = "NotificationsWriteAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.backend_notification_table}"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "notifications_consumer_workload" {
  name = "stagelog-notifications-consumer-workload-role"

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
            (local.oidc_sub_key) = "system:serviceaccount:${local.workload_namespace}:${local.notifications_consumer_service_account_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "notifications_consumer_workload_attach" {
  role       = aws_iam_role.notifications_consumer_workload.name
  policy_arn = aws_iam_policy.notifications_consumer_workload.arn
}

resource "aws_iam_policy" "outbox_worker_workload" {
  name        = "stagelog-outbox-worker-workload-policy"
  description = "Allow outbox worker pod to publish notification events to EventBridge"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "NotificationEventBusPublishAccess"
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

resource "aws_iam_role" "outbox_worker_workload" {
  name = "stagelog-outbox-worker-workload-role"

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
            (local.oidc_sub_key) = "system:serviceaccount:${local.workload_namespace}:${local.outbox_worker_service_account_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "outbox_worker_workload_attach" {
  role       = aws_iam_role.outbox_worker_workload.name
  policy_arn = aws_iam_policy.outbox_worker_workload.arn
}
