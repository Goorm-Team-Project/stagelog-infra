locals {
  prefix = "/${var.project}/${var.environment}"

  api_string_params = {
    DEBUG                              = "False"
    ALLOWED_HOSTS                      = "api.pearlinvest.click,pearlinvest.click"
    CORS_ALLOWED_ORIGINS               = "https://pearlinvest.click,https://www.pearlinvest.click"
    DB_MODE                            = "mysql"
    DB_HOST                            = "stagelog-db-managed.c922amcmeywm.ap-northeast-2.rds.amazonaws.com"
    DB_NAME_CORE                       = "stagelog_core"
    DB_USER_CORE                       = "stagelog_core_user"
    DB_NAME_AUTH                       = "stagelog_auth"
    DB_USER_AUTH                       = "stagelog_auth_user"
    DB_NAME_EVENTS                     = "stagelog_events"
    DB_USER_EVENTS                     = "stagelog_events_user"
    AWS_REGION                         = var.aws_region
    S3_UPLOAD_BUCKET                   = "replace-me"
    S3_UPLOAD_PREFIX                   = "uploads/"
    S3_PRESIGN_EXPIRES                 = "300"
    S3_PUBLIC_BASE_URL                 = ""
    REDIS_HOST                         = ""
    REDIS_PORT                         = "6379"
    REDIS_DB                           = "0"
    REDIS_SSL                          = "False"
    AUTO_BAN_ENABLED                   = "False"
    AUTO_BAN_LIMIT_WINDOW_SECONDS      = "60"
    AUTO_BAN_MAX_REQUESTS              = "100"
    AUTO_BAN_BLOCK_TIME_SECONDS        = "3600"
    NOTIFICATION_EVENT_BUS_NAME        = "stagelog-notification-bus"
    NOTIFICATION_SQS_QUEUE_URL         = ""
    NOTIFICATION_DDB_TABLE_NAME        = "stagelog-notifications"
    OUTBOX_PUBLISH_BATCH_SIZE          = "50"
    OUTBOX_MAX_RETRIES                 = "5"
    OUTBOX_RETRY_BASE_DELAY_SECONDS    = "30"
    OUTBOX_NOTIFICATION_AGGREGATE_TYPE = "notification"
  }

  outbox_string_params = {
    DEBUG                              = "False"
    DB_MODE                            = "mysql"
    DB_HOST                            = "stagelog-db-managed.c922amcmeywm.ap-northeast-2.rds.amazonaws.com"
    DB_NAME_CORE                       = "stagelog_core"
    DB_USER_CORE                       = "replace-me"
    DB_NAME_AUTH                       = "stagelog_auth"
    DB_USER_AUTH                       = "replace-me"
    DB_NAME_EVENTS                     = "stagelog_events"
    DB_USER_EVENTS                     = "replace-me"
    AWS_REGION                         = var.aws_region
    NOTIFICATION_EVENT_BUS_NAME        = "stagelog-notification-bus"
    OUTBOX_PUBLISH_BATCH_SIZE          = "50"
    OUTBOX_MAX_RETRIES                 = "5"
    OUTBOX_RETRY_BASE_DELAY_SECONDS    = "30"
    OUTBOX_NOTIFICATION_AGGREGATE_TYPE = "notification"
    OUTBOX_DATABASE                    = "default"
    OUTBOX_PUBLISH_INTERVAL_SECONDS    = "3"
  }

  notification_string_params = {
    DEBUG                                   = "False"
    DB_MODE                                 = "mysql"
    DB_HOST                                 = "stagelog-db-managed.c922amcmeywm.ap-northeast-2.rds.amazonaws.com"
    DB_NAME_CORE                            = "stagelog_core"
    DB_USER_CORE                            = "replace-me"
    DB_NAME_AUTH                            = "stagelog_auth"
    DB_USER_AUTH                            = "replace-me"
    DB_NAME_EVENTS                          = "stagelog_events"
    DB_USER_EVENTS                          = "replace-me"
    AWS_REGION                              = var.aws_region
    NOTIFICATION_SQS_QUEUE_URL              = ""
    NOTIFICATION_DDB_TABLE_NAME             = "stagelog-notifications"
    NOTIFICATION_CONSUMER_MAX_MESSAGES      = "10"
    NOTIFICATION_CONSUMER_WAIT_TIME_SECONDS = "20"
    NOTIFICATION_DDB_TTL_DAYS               = "30"
    NOTIFICATION_DEDUPE_TTL_SECONDS         = "86400"
    NOTIFICATION_UNREAD_CACHE_TTL_SECONDS   = "3600"
    REDIS_HOST                              = ""
    REDIS_PORT                              = "6379"
    REDIS_DB                                = "0"
    REDIS_SSL                               = "False"
  }

  string_parameters = merge(
    { for k, v in local.api_string_params : "${local.prefix}/api/${k}" => v },
    { for k, v in local.outbox_string_params : "${local.prefix}/outbox-worker/${k}" => v },
    { for k, v in local.notification_string_params : "${local.prefix}/notification-consumer/${k}" => v }
  )

  api_secure_params = {
    SECRET_KEY         = var.secret_key
    DB_PASSWORD_CORE   = var.db_password_core
    DB_PASSWORD_AUTH   = var.db_password_auth
    DB_PASSWORD_EVENTS = var.db_password_events
  }

  outbox_secure_params = {
    SECRET_KEY         = var.secret_key
    DB_PASSWORD_CORE   = var.db_password_core
    DB_PASSWORD_AUTH   = var.db_password_auth
    DB_PASSWORD_EVENTS = var.db_password_events
  }

  notification_secure_params = {
    SECRET_KEY         = var.secret_key
    DB_PASSWORD_CORE   = var.db_password_core
    DB_PASSWORD_AUTH   = var.db_password_auth
    DB_PASSWORD_EVENTS = var.db_password_events
  }

  secure_parameters = merge(
    { for k, v in local.api_secure_params : "${local.prefix}/api/${k}" => v },
    { for k, v in local.outbox_secure_params : "${local.prefix}/outbox-worker/${k}" => v },
    { for k, v in local.notification_secure_params : "${local.prefix}/notification-consumer/${k}" => v }
  )
}

resource "aws_ssm_parameter" "string_params" {
  for_each = local.string_parameters

  name      = each.key
  type      = "String"
  value     = each.value
  overwrite = true

  tags = {
    Service = split("/", each.key)[3]
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
    Service = split("/", each.key)[3]
    Kind    = "secret"
  }
}
