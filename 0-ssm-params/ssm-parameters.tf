locals {
  prefix = "/${var.project}/${var.environment}"

  unified_string_params = {
    DEBUG                         = "False"
    ALLOWED_HOSTS                 = "api.pearlinvest.click,pearlinvest.click"
    CORS_ALLOWED_ORIGINS          = "https://pearlinvest.click,https://www.pearlinvest.click"
    DB_MODE                       = "mysql"
    USE_INTERNAL_SERVICE_API      = "True"
    DB_HOST                       = "stagelog-db-managed.c922amcmeywm.ap-northeast-2.rds.amazonaws.com"
    DB_NAME_CORE                  = "stagelog_core"
    DB_USER_CORE                  = "stagelog_core_user"
    DB_NAME_AUTH                  = "stagelog_auth"
    DB_USER_AUTH                  = "stagelog_auth_user"
    DB_NAME_EVENTS                = "stagelog_events"
    DB_USER_EVENTS                = "stagelog_events_user"
    AWS_REGION                    = var.aws_region
    S3_UPLOAD_BUCKET              = "replace-me"
    AWS_STORAGE_BUCKET_NAME       = ""
    S3_BUCKET                     = ""
    S3_UPLOAD_PREFIX              = "uploads/"
    S3_PRESIGN_EXPIRES            = "300"
    S3_PUBLIC_BASE_URL            = ""
    REDIS_HOST                    = ""
    REDIS_PORT                    = "6379"
    REDIS_DB                      = "0"
    REDIS_PASSWORD                = ""
    REDIS_SSL                     = "False"
    AUTO_BAN_ENABLED              = "False"
    AUTO_BAN_LIMIT_WINDOW_SECONDS = "60"
    AUTO_BAN_MAX_REQUESTS         = "100"
    AUTO_BAN_BLOCK_TIME_SECONDS   = "3600"
    AUTH_INTERNAL_BASE_URL        = "http://auth-svc:8000"
    EVENTS_INTERNAL_BASE_URL      = "http://events-svc:8000"
    CORE_INTERNAL_BASE_URL        = "http://core-svc:8000"
    GATEWAY_USER_ID_HEADER        = "X-User-Id"

    NOTIFICATION_EVENT_BUS_NAME             = "stagelog-notification-bus"
    NOTIFICATION_SQS_QUEUE_URL              = ""
    NOTIFICATION_DDB_TABLE_NAME             = "stagelog-notifications"
    NOTIFICATION_CONSUMER_MAX_MESSAGES      = "10"
    NOTIFICATION_CONSUMER_WAIT_TIME_SECONDS = "20"
    NOTIFICATION_DDB_TTL_DAYS               = "30"
    NOTIFICATION_DEDUPE_TTL_SECONDS         = "86400"
    NOTIFICATION_UNREAD_CACHE_TTL_SECONDS   = "3600"

    OUTBOX_PUBLISH_BATCH_SIZE          = "50"
    OUTBOX_MAX_RETRIES                 = "5"
    OUTBOX_RETRY_BASE_DELAY_SECONDS    = "30"
    OUTBOX_NOTIFICATION_AGGREGATE_TYPE = "notification"
    OUTBOX_DATABASE                    = "default"
    OUTBOX_DATABASES                   = "default,auth_db,events_db"
    OUTBOX_PUBLISH_INTERVAL_SECONDS    = "3"
  }

  unified_secure_params = {
    SECRET_KEY         = var.secret_key
    DB_PASSWORD_CORE   = var.db_password_core
    DB_PASSWORD_AUTH   = var.db_password_auth
    DB_PASSWORD_EVENTS = var.db_password_events
  }

  string_parameters = {
    for k, v in local.unified_string_params :
    "${local.prefix}/${var.service_name}/${k}" => v
  }

  secure_parameters = {
    for k, v in local.unified_secure_params :
    "${local.prefix}/${var.service_name}/${k}" => v
  }
}

resource "aws_ssm_parameter" "string_params" {
  for_each = local.string_parameters

  name      = each.key
  type      = "String"
  value     = each.value
  overwrite = true

  tags = {
    Service = var.service_name
    Kind    = "runtime"
  }
}

resource "aws_ssm_parameter" "secure_params" {
  for_each = local.secure_parameters

  name      = each.key
  type      = "SecureString"
  value     = each.value
  overwrite = true
  key_id    = var.kms_key_id != "" ? var.kms_key_id : null

  tags = {
    Service = var.service_name
    Kind    = "secret"
  }
}
