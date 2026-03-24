locals {
  prefix = "/${var.project}/${var.environment}"

  shared_string_params = {
    DEBUG                         = "False"
    ALLOWED_HOSTS                 = "localhost,pearlinvest.click,.ap-northeast-2.elb.amazonaws.com,auth-svc,events-svc,posts-svc,notifications-svc,auth-svc.dev-backend.svc.cluster.local,events-svc.dev-backend.svc.cluster.local,posts-svc.dev-backend.svc.cluster.local,notifications-svc.dev-backend.svc.cluster.local"
    CORS_ALLOWED_ORIGINS          = "https://pearlinvest.click,https://www.pearlinvest.click"
    DB_MODE                       = "mysql"
    DB_HOST                       = "stagelog-db-managed-v2.c922amcmeywm.ap-northeast-2.rds.amazonaws.com"
    DB_USE_SSL                    = "True"
    DB_SSL_CA                     = "/etc/ssl/certs/rds-global-bundle.pem"
    AWS_REGION                    = var.aws_region
    S3_UPLOAD_BUCKET              = "stagelog-dev-uploads-v2"
    S3_UPLOAD_PREFIX              = "uploads/"
    S3_PRESIGN_EXPIRES            = "300"
    S3_PUBLIC_BASE_URL            = "https://dsbbv32h70cvl.cloudfront.net"
    REDIS_HOST                    = "stagelog-redis.uaksc2.ng.0001.apn2.cache.amazonaws.com"
    REDIS_PORT                    = "6379"
    REDIS_DB                      = "0"
    REDIS_PASSWORD                = "None"
    REDIS_SSL                     = "False"
    AUTO_BAN_ENABLED              = "False"
    AUTO_BAN_LIMIT_WINDOW_SECONDS = "60"
    AUTO_BAN_MAX_REQUESTS         = "100"
    AUTO_BAN_BLOCK_TIME_SECONDS   = "3600"
    AUTH_INTERNAL_BASE_URL        = "http://auth-svc:8000"
    EVENTS_INTERNAL_BASE_URL      = "http://events-svc:8000"
    POSTS_INTERNAL_BASE_URL       = "http://posts-svc:8000"
    GATEWAY_USER_ID_HEADER        = "X-User-Id"
    NOTIFICATION_EVENT_BUS_NAME   = "stagelog-notification-bus"
  }

  shared_secure_params = {
    SECRET_KEY = var.secret_key
  }

  auth_string_params = {
    DB_NAME_AUTH             = "stagelog_auth"
    DB_USER_AUTH             = "stagelog_auth_user"
    USE_INTERNAL_SERVICE_API = "True"
  }

  auth_secure_params = {
    DB_PASSWORD_AUTH = var.db_password_auth
  }

  events_string_params = {
    DB_NAME_EVENTS           = "stagelog_events"
    DB_USER_EVENTS           = "stagelog_events_user"
    USE_INTERNAL_SERVICE_API = "True"
  }

  events_secure_params = {
    DB_PASSWORD_EVENTS = var.db_password_events
  }

  posts_string_params = {
    DB_NAME_POSTS            = "stagelog_core"
    DB_USER_POSTS            = "stagelog_core_user"
    USE_INTERNAL_SERVICE_API = "True"
  }

  posts_secure_params = {
    DB_PASSWORD_POSTS = var.db_password_posts
  }

  notifications_string_params = {
    DB_NAME_NOTIFICATIONS                   = "stagelog_notifications"
    DB_USER_NOTIFICATIONS                   = "stagelog_notifications_user"
    USE_INTERNAL_SERVICE_API                = "False"
    NOTIFICATION_SQS_QUEUE_URL              = "https://sqs.ap-northeast-2.amazonaws.com/430118823715/stagelog-notification-queue"
    NOTIFICATION_DDB_TABLE_NAME             = "stagelog-notifications"
    NOTIFICATION_CONSUMER_MAX_MESSAGES      = "10"
    NOTIFICATION_CONSUMER_WAIT_TIME_SECONDS = "20"
    NOTIFICATION_DDB_TTL_DAYS               = "30"
    NOTIFICATION_DEDUPE_TTL_SECONDS         = "86400"
    NOTIFICATION_UNREAD_CACHE_TTL_SECONDS   = "3600"
  }

  notifications_secure_params = {
    DB_PASSWORD_NOTIFICATIONS = var.db_password_notifications
  }

  outbox_worker_string_params = {
    OUTBOX_DATABASES                = "posts_db,auth_db,events_db"
    OUTBOX_PUBLISH_BATCH_SIZE       = "50"
    OUTBOX_MAX_RETRIES              = "5"
    OUTBOX_RETRY_BASE_DELAY_SECONDS = "30"
    OUTBOX_PUBLISH_INTERVAL_SECONDS = "3"
  }

  auth_lambda_string_params = {
    JWT_ISSUER              = "stagelog-auth"
    JWT_AUDIENCE            = "stagelog-api"
    JWT_ALGORITHM           = "HS256"
    JWT_ACCESS_TTL_SECONDS  = "1800"
    JWT_REFRESH_TTL_SECONDS = "1209600"
    JWT_PUBLIC_JWK          = var.jwt_public_jwk
    DB_USER                 = "stagelog_auth_user"
    DB_NAME                 = "stagelog_auth"
    KAKAO_REDIRECT_URI      = var.kakao_redirect_uri
    GOOGLE_REDIRECT_URI     = var.google_redirect_uri
    NAVER_REDIRECT_URI      = var.naver_redirect_uri
  }

  auth_lambda_secure_params = {
    JWT_SECRET_KEY                    = var.jwt_secret_key
    DB_PASSWORD                       = var.db_password_auth
    KAKAO_REST_API_KEY                = var.kakao_rest_api_key
    KAKAO_ACCESS_TOKEN_CLIENT_SECRET  = var.kakao_access_token_client_secret
    GOOGLE_REST_API_KEY               = var.google_rest_api_key
    GOOGLE_ACCESS_TOKEN_CLIENT_SECRET = var.google_access_token_client_secret
    NAVER_REST_API_KEY                = var.naver_rest_api_key
    NAVER_ACCESS_TOKEN_CLIENT_SECRET  = var.naver_access_token_client_secret
  }

  parameter_scopes = [
    "shared",
    "auth",
    "events",
    "posts",
    "notifications",
    "outbox-worker",
    "auth-lambda",
  ]

  string_parameters = merge(
    { for k, v in local.shared_string_params : "${local.prefix}/shared/${k}" => { value = v, scope = "shared" } },
    { for k, v in local.auth_string_params : "${local.prefix}/auth/${k}" => { value = v, scope = "auth" } },
    { for k, v in local.events_string_params : "${local.prefix}/events/${k}" => { value = v, scope = "events" } },
    { for k, v in local.posts_string_params : "${local.prefix}/posts/${k}" => { value = v, scope = "posts" } },
    { for k, v in local.notifications_string_params : "${local.prefix}/notifications/${k}" => { value = v, scope = "notifications" } },
    { for k, v in local.outbox_worker_string_params : "${local.prefix}/outbox-worker/${k}" => { value = v, scope = "outbox-worker" } },
    { for k, v in local.auth_lambda_string_params : "${local.prefix}/auth-lambda/${k}" => { value = v, scope = "auth-lambda" } },
  )

  secure_parameters = merge(
    { for k, v in local.shared_secure_params : "${local.prefix}/shared/${k}" => { value = v, scope = "shared" } },
    { for k, v in local.auth_secure_params : "${local.prefix}/auth/${k}" => { value = v, scope = "auth" } },
    { for k, v in local.events_secure_params : "${local.prefix}/events/${k}" => { value = v, scope = "events" } },
    { for k, v in local.posts_secure_params : "${local.prefix}/posts/${k}" => { value = v, scope = "posts" } },
    { for k, v in local.notifications_secure_params : "${local.prefix}/notifications/${k}" => { value = v, scope = "notifications" } },
    { for k, v in local.auth_lambda_secure_params : "${local.prefix}/auth-lambda/${k}" => { value = v, scope = "auth-lambda" } },
  )
}

resource "aws_ssm_parameter" "string_params" {
  for_each = local.string_parameters

  name      = each.key
  type      = "String"
  value     = each.value.value
  overwrite = true

  tags = {
    Scope = each.value.scope
    Kind  = "runtime"
  }
}

resource "aws_ssm_parameter" "secure_params" {
  for_each = local.secure_parameters

  name      = each.key
  type      = "SecureString"
  value     = each.value.value
  overwrite = true
  key_id    = var.kms_key_id != "" ? var.kms_key_id : null

  tags = {
    Scope = each.value.scope
    Kind  = "secret"
  }
}
