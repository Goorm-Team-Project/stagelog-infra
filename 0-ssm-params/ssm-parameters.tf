locals {
  prefix = "/${var.project}/${var.environment}"

  core_api_string_params = {
    DEBUG                         = "False"
    ALLOWED_HOSTS                 = "api.pearlinvest.click,pearlinvest.click"
    CORS_ALLOWED_ORIGINS          = "https://pearlinvest.click,https://www.pearlinvest.click"
    DB_MODE                       = "mysql"
    DB_HOST                       = "stagelog-db-managed.c922amcmeywm.ap-northeast-2.rds.amazonaws.com"
    DB_NAME_CORE                  = "stagelog_core"
    DB_USER_CORE                  = "stagelog_core_user"
    AWS_REGION                    = var.aws_region
    S3_UPLOAD_BUCKET              = "replace-me"
    S3_UPLOAD_PREFIX              = "uploads/"
    S3_PRESIGN_EXPIRES            = "300"
    S3_PUBLIC_BASE_URL            = ""
    REDIS_HOST                    = ""
    REDIS_PORT                    = "6379"
    REDIS_DB                      = "0"
    REDIS_SSL                     = "False"
    AUTO_BAN_ENABLED              = "False"
    AUTO_BAN_LIMIT_WINDOW_SECONDS = "60"
    AUTO_BAN_MAX_REQUESTS         = "100"
    AUTO_BAN_BLOCK_TIME_SECONDS   = "3600"
    AUTH_INTERNAL_BASE_URL        = "http://auth-svc:8000"
    EVENTS_INTERNAL_BASE_URL      = "http://events-svc:8000"
  }

  events_api_string_params = {
    DEBUG                         = "False"
    ALLOWED_HOSTS                 = "api.pearlinvest.click,pearlinvest.click"
    CORS_ALLOWED_ORIGINS          = "https://pearlinvest.click,https://www.pearlinvest.click"
    DB_MODE                       = "mysql"
    DB_HOST                       = "stagelog-db-managed.c922amcmeywm.ap-northeast-2.rds.amazonaws.com"
    DB_NAME_EVENTS                = "stagelog_events"
    DB_USER_EVENTS                = "stagelog_events_user"
    AWS_REGION                    = var.aws_region
    REDIS_HOST                    = ""
    REDIS_PORT                    = "6379"
    REDIS_DB                      = "0"
    REDIS_SSL                     = "False"
    AUTO_BAN_ENABLED              = "False"
    AUTO_BAN_LIMIT_WINDOW_SECONDS = "60"
    AUTO_BAN_MAX_REQUESTS         = "100"
    AUTO_BAN_BLOCK_TIME_SECONDS   = "3600"
    CORE_INTERNAL_BASE_URL        = "http://core-svc:8000"
    AUTH_INTERNAL_BASE_URL        = "http://auth-svc:8000"
  }

  auth_api_string_params = {
    DEBUG                         = "False"
    ALLOWED_HOSTS                 = "api.pearlinvest.click,pearlinvest.click"
    CORS_ALLOWED_ORIGINS          = "https://pearlinvest.click,https://www.pearlinvest.click"
    DB_MODE                       = "mysql"
    DB_HOST                       = "stagelog-db-managed.c922amcmeywm.ap-northeast-2.rds.amazonaws.com"
    DB_NAME_AUTH                  = "stagelog_auth"
    DB_USER_AUTH                  = "stagelog_auth_user"
    AWS_REGION                    = var.aws_region
    REDIS_HOST                    = ""
    REDIS_PORT                    = "6379"
    REDIS_DB                      = "0"
    REDIS_SSL                     = "False"
    AUTO_BAN_ENABLED              = "False"
    AUTO_BAN_LIMIT_WINDOW_SECONDS = "60"
    AUTO_BAN_MAX_REQUESTS         = "100"
    AUTO_BAN_BLOCK_TIME_SECONDS   = "3600"
    CORE_INTERNAL_BASE_URL        = "http://core-svc:8000"
    EVENTS_INTERNAL_BASE_URL      = "http://events-svc:8000"
  }

  outbox_worker_string_params = {
    DEBUG                              = "False"
    DB_MODE                            = "mysql"
    DB_HOST                            = "stagelog-db-managed.c922amcmeywm.ap-northeast-2.rds.amazonaws.com"
    DB_NAME_CORE                       = "stagelog_core"
    DB_USER_CORE                       = "stagelog_core_user"
    DB_NAME_AUTH                       = "stagelog_auth"
    DB_USER_AUTH                       = "stagelog_auth_user"
    DB_NAME_EVENTS                     = "stagelog_events"
    DB_USER_EVENTS                     = "stagelog_events_user"
    AWS_REGION                         = var.aws_region
    NOTIFICATION_EVENT_BUS_NAME        = "stagelog-notification-bus"
    OUTBOX_PUBLISH_BATCH_SIZE          = "50"
    OUTBOX_MAX_RETRIES                 = "5"
    OUTBOX_RETRY_BASE_DELAY_SECONDS    = "30"
    OUTBOX_NOTIFICATION_AGGREGATE_TYPE = "notification"
    OUTBOX_DATABASE                    = "default"
    OUTBOX_PUBLISH_INTERVAL_SECONDS    = "3"
  }

  notification_consumer_string_params = {
    DEBUG                                   = "False"
    DB_MODE                                 = "sqlite"
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
    { for k, v in local.core_api_string_params : "${local.prefix}/core-api/${k}" => v },
    { for k, v in local.events_api_string_params : "${local.prefix}/events-api/${k}" => v },
    { for k, v in local.auth_api_string_params : "${local.prefix}/auth-api/${k}" => v },
    { for k, v in local.outbox_worker_string_params : "${local.prefix}/outbox-worker/${k}" => v },
    { for k, v in local.notification_consumer_string_params : "${local.prefix}/notification-consumer/${k}" => v }
  )

  core_api_secure_params = {
    SECRET_KEY       = var.secret_key
    DB_PASSWORD_CORE = var.db_password_core
  }

  events_api_secure_params = {
    SECRET_KEY         = var.secret_key
    DB_PASSWORD_EVENTS = var.db_password_events
  }

  auth_api_secure_params = {
    SECRET_KEY       = var.secret_key
    DB_PASSWORD_AUTH = var.db_password_auth
  }

  outbox_worker_secure_params = {
    SECRET_KEY         = var.secret_key
    DB_PASSWORD_CORE   = var.db_password_core
    DB_PASSWORD_AUTH   = var.db_password_auth
    DB_PASSWORD_EVENTS = var.db_password_events
  }

  notification_consumer_secure_params = {
    SECRET_KEY = var.secret_key
  }

  secure_parameters = merge(
    { for k, v in local.core_api_secure_params : "${local.prefix}/core-api/${k}" => v },
    { for k, v in local.events_api_secure_params : "${local.prefix}/events-api/${k}" => v },
    { for k, v in local.auth_api_secure_params : "${local.prefix}/auth-api/${k}" => v },
    { for k, v in local.outbox_worker_secure_params : "${local.prefix}/outbox-worker/${k}" => v },
    { for k, v in local.notification_consumer_secure_params : "${local.prefix}/notification-consumer/${k}" => v }
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
