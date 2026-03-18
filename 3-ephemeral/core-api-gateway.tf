# Core REST API moved from 1-permanent to 3-ephemeral.
# This stack depends on EKS ingress/ALB readiness.

data "aws_lambda_function" "auth_authorizer" {
  function_name = var.authorizer_lambda_function_name
}

data "aws_lambda_function" "auth_api" {
  function_name = var.auth_api_lambda_function_name
}

data "aws_security_group" "lambda_sg" {
  vpc_id = local.vpc_id
  name   = "stagelog-lambda-sg"
}

# API Gateway (REST API v1) - core /api routes
# - 공개 API GET /api/events*, /api/posts* : Authorizer 제외
# - 보호 API: 그 외 /api/{proxy+} 는 Authorizer 적용

#------------------------------------------------------------
# Core REST API
#------------------------------------------------------------
locals {
  core_api_integration_uri   = trimspace(data.terraform_remote_state.eks.outputs.core_api_url)
  core_api_alb_arn           = trimspace(data.terraform_remote_state.eks.outputs.alb_arn)
  auth_api_lambda_invoke_uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${data.aws_lambda_function.auth_api.arn}/invocations"
  alb_request_templates = {
    "application/json" = <<-VTL
#set($context.requestOverride.path = $context.resourcePath)
$input.body
VTL
  }
}

resource "aws_api_gateway_rest_api" "stagelog_core_rest_api" {
  name = "${var.api_name}-core-rest"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  lifecycle {
    precondition {
      condition     = can(regex("^https?://", local.core_api_integration_uri))
      error_message = "EKS remote state output core_api_url must be a non-empty URL starting with http:// or https://."
    }
  }
}

resource "aws_cloudwatch_log_group" "apigw_access_logs" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = var.log_retention_days
}

# API Gateway stage access log를 사용하려면 계정 레벨 CloudWatch role이 선행되어야 한다.
resource "aws_iam_role" "apigw_cloudwatch_logs_role" {
  name = "stagelog-apigw-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch_logs_attach" {
  role       = aws_iam_role.apigw_cloudwatch_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch_logs_role.arn

  depends_on = [
    aws_iam_role_policy_attachment.apigw_cloudwatch_logs_attach
  ]
}

# API Gateway -> private ALB 연결용 VPC Link
# NOTE: REST API에서도 v2 VPC Link를 사용해 ALB listener ARN을 integration URI로 연결한다.
resource "aws_apigatewayv2_vpc_link" "core_vpc_link" {
  name               = "stagelog-core-vpc-link"
  subnet_ids         = [local.subnet_private_01, local.subnet_private_02]
  security_group_ids = [data.aws_security_group.lambda_sg.id]
}

#------------------------------------------------------------
# Resources
#------------------------------------------------------------
resource "aws_api_gateway_resource" "core_api_root_api" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "core_api_auth" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_resource.core_api_root_api.id
  path_part   = "auth"
}

resource "aws_api_gateway_resource" "core_api_auth_proxy" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_resource.core_api_auth.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_resource" "core_api_auth_keep" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_resource.core_api_auth.id
  path_part   = "keep"
}

resource "aws_api_gateway_resource" "core_api_auth_logout" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_resource.core_api_auth.id
  path_part   = "logout"
}

resource "aws_api_gateway_resource" "core_api_proxy" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_resource.core_api_root_api.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_resource" "core_api_events" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_resource.core_api_root_api.id
  path_part   = "events"
}

resource "aws_api_gateway_resource" "core_api_events_event_id" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_resource.core_api_events.id
  path_part   = "{event_id}"
}

resource "aws_api_gateway_resource" "core_api_posts" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_resource.core_api_root_api.id
  path_part   = "posts"
}

resource "aws_api_gateway_resource" "core_api_posts_post_id" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_resource.core_api_posts.id
  path_part   = "{post_id}"
}

resource "aws_api_gateway_resource" "core_api_posts_post_comments" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_resource.core_api_posts_post_id.id
  path_part   = "comments"
}

resource "aws_api_gateway_resource" "core_api_posts_post_inquiry" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_resource.core_api_posts_post_id.id
  path_part   = "inquiry"
}

resource "aws_api_gateway_resource" "core_health" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  parent_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.root_resource_id
  path_part   = "health"
}

#------------------------------------------------------------
# Authorizer
#------------------------------------------------------------
resource "aws_api_gateway_authorizer" "core_jwt_authorizer" {
  name           = "jwt-authorizer-core-rest"
  rest_api_id    = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  type           = "REQUEST"
  authorizer_uri = data.aws_lambda_function.auth_authorizer.invoke_arn

  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 0
}

#------------------------------------------------------------
# Methods
#------------------------------------------------------------
resource "aws_api_gateway_method" "core_public_events_get" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_api_events.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "core_public_event_detail_get" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_api_events_event_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "core_public_posts_get" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_api_posts.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "core_public_post_detail_get" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_api_posts_post_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "core_public_post_comments_get" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_api_posts_post_comments.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "core_public_post_inquiry_get" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_api_posts_post_inquiry.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "core_health_get" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_health.id
  http_method   = "GET"
  authorization = "NONE"
}

# /api/auth (ANY) -> auth-api Lambda (public)
resource "aws_api_gateway_method" "core_auth_root_any" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_api_auth.id
  http_method   = "ANY"
  authorization = "NONE"
}

# /api/auth/{proxy+} (ANY) -> auth-api Lambda (public)
resource "aws_api_gateway_method" "core_auth_proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_api_auth_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

# /api/auth/keep (GET) -> auth-api Lambda (protected)
resource "aws_api_gateway_method" "core_auth_keep_get" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_api_auth_keep.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.core_jwt_authorizer.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

# /api/auth/logout (POST) -> auth-api Lambda (protected)
resource "aws_api_gateway_method" "core_auth_logout_post" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_api_auth_logout.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.core_jwt_authorizer.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_method" "core_api_proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id   = aws_api_gateway_resource.core_api_proxy.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.core_jwt_authorizer.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

#------------------------------------------------------------
# Integrations
#------------------------------------------------------------
resource "aws_api_gateway_integration" "core_public_events_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_api_events.id
  http_method             = aws_api_gateway_method.core_public_events_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.core_vpc_link.id
  integration_target      = local.core_api_alb_arn
  uri                     = local.core_api_integration_uri
  request_templates       = local.alb_request_templates

  # 공개 라우트에서 spoofed 헤더가 백엔드로 전달되지 않게 빈 값으로 덮어씀
  request_parameters = {
    "integration.request.header.X-User-Id" = "''"
  }
}

resource "aws_api_gateway_integration" "core_public_event_detail_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_api_events_event_id.id
  http_method             = aws_api_gateway_method.core_public_event_detail_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.core_vpc_link.id
  integration_target      = local.core_api_alb_arn
  uri                     = local.core_api_integration_uri
  request_templates       = local.alb_request_templates

  request_parameters = {
    "integration.request.header.X-User-Id" = "''"
  }
}

resource "aws_api_gateway_integration" "core_public_posts_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_api_posts.id
  http_method             = aws_api_gateway_method.core_public_posts_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.core_vpc_link.id
  integration_target      = local.core_api_alb_arn
  uri                     = local.core_api_integration_uri
  request_templates       = local.alb_request_templates

  request_parameters = {
    "integration.request.header.X-User-Id" = "''"
  }
}

resource "aws_api_gateway_integration" "core_public_post_detail_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_api_posts_post_id.id
  http_method             = aws_api_gateway_method.core_public_post_detail_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.core_vpc_link.id
  integration_target      = local.core_api_alb_arn
  uri                     = local.core_api_integration_uri
  request_templates       = local.alb_request_templates

  request_parameters = {
    "integration.request.header.X-User-Id" = "''"
  }
}

resource "aws_api_gateway_integration" "core_public_post_comments_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_api_posts_post_comments.id
  http_method             = aws_api_gateway_method.core_public_post_comments_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.core_vpc_link.id
  integration_target      = local.core_api_alb_arn
  uri                     = local.core_api_integration_uri
  request_templates       = local.alb_request_templates

  request_parameters = {
    "integration.request.header.X-User-Id" = "''"
  }
}

resource "aws_api_gateway_integration" "core_public_post_inquiry_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_api_posts_post_inquiry.id
  http_method             = aws_api_gateway_method.core_public_post_inquiry_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.core_vpc_link.id
  integration_target      = local.core_api_alb_arn
  uri                     = local.core_api_integration_uri
  request_templates       = local.alb_request_templates

  request_parameters = {
    "integration.request.header.X-User-Id" = "''"
  }
}

resource "aws_api_gateway_integration" "core_health_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_health.id
  http_method             = aws_api_gateway_method.core_health_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.core_vpc_link.id
  integration_target      = local.core_api_alb_arn
  uri                     = local.core_api_integration_uri
  request_templates       = local.alb_request_templates

  request_parameters = {
    "integration.request.header.X-User-Id" = "''"
  }
}

resource "aws_api_gateway_integration" "core_auth_root_any_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_api_auth.id
  http_method             = aws_api_gateway_method.core_auth_root_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.auth_api_lambda_invoke_uri
}

resource "aws_api_gateway_integration" "core_auth_proxy_any_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_api_auth_proxy.id
  http_method             = aws_api_gateway_method.core_auth_proxy_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.auth_api_lambda_invoke_uri
}

resource "aws_api_gateway_integration" "core_auth_keep_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_api_auth_keep.id
  http_method             = aws_api_gateway_method.core_auth_keep_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.auth_api_lambda_invoke_uri
}

resource "aws_api_gateway_integration" "core_auth_logout_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_api_auth_logout.id
  http_method             = aws_api_gateway_method.core_auth_logout_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.auth_api_lambda_invoke_uri
}

resource "aws_api_gateway_integration" "core_protected_proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  resource_id             = aws_api_gateway_resource.core_api_proxy.id
  http_method             = aws_api_gateway_method.core_api_proxy_any.http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.core_vpc_link.id
  integration_target      = local.core_api_alb_arn
  uri                     = local.core_api_integration_uri
  request_templates       = local.alb_request_templates

  request_parameters = {
    "integration.request.header.X-User-Id" = "context.authorizer.user_id"
  }
}

#------------------------------------------------------------
# Gateway Responses (common_response envelope)
#------------------------------------------------------------
resource "aws_api_gateway_gateway_response" "core_unauthorized" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  response_type = "UNAUTHORIZED"
  status_code   = "401"

  response_parameters = {
    "gatewayresponse.header.Content-Type"                 = "'application/json'"
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.allowed_cors_origins[0]}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Authorization,Content-Type,Origin,Accept,X-Requested-With,X-CSRF-Token'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,PATCH,DELETE,OPTIONS'"
  }

  response_templates = {
    "application/json" = jsonencode({
      success = false
      message = "유효하지 않거나 만료된 토큰입니다."
      data    = null
    })
  }
}

resource "aws_api_gateway_gateway_response" "core_access_denied" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  response_type = "ACCESS_DENIED"
  status_code   = "403"

  response_parameters = {
    "gatewayresponse.header.Content-Type"                 = "'application/json'"
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.allowed_cors_origins[0]}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Authorization,Content-Type,Origin,Accept,X-Requested-With,X-CSRF-Token'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,PATCH,DELETE,OPTIONS'"
  }

  response_templates = {
    "application/json" = jsonencode({
      success = false
      message = "권한이 없습니다."
      data    = null
    })
  }
}

#------------------------------------------------------------
# Deployment & Stage
#------------------------------------------------------------
resource "aws_api_gateway_deployment" "stagelog_core_rest_deployment" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_core_rest_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.core_public_events_get.id,
      aws_api_gateway_method.core_public_event_detail_get.id,
      aws_api_gateway_method.core_public_posts_get.id,
      aws_api_gateway_method.core_public_post_detail_get.id,
      aws_api_gateway_method.core_public_post_comments_get.id,
      aws_api_gateway_method.core_public_post_inquiry_get.id,
      aws_api_gateway_method.core_health_get.id,
      aws_api_gateway_method.core_auth_root_any.id,
      aws_api_gateway_method.core_auth_proxy_any.id,
      aws_api_gateway_method.core_auth_keep_get.id,
      aws_api_gateway_method.core_auth_logout_post.id,
      aws_api_gateway_method.core_api_proxy_any.id,
      local.core_api_alb_arn,
      local.core_api_integration_uri,
      aws_apigatewayv2_vpc_link.core_vpc_link.id,
      aws_api_gateway_integration.core_public_events_integration.id,
      aws_api_gateway_integration.core_public_event_detail_integration.id,
      aws_api_gateway_integration.core_public_posts_integration.id,
      aws_api_gateway_integration.core_public_post_detail_integration.id,
      aws_api_gateway_integration.core_public_post_comments_integration.id,
      aws_api_gateway_integration.core_public_post_inquiry_integration.id,
      aws_api_gateway_integration.core_health_integration.id,
      aws_api_gateway_integration.core_auth_root_any_integration.id,
      aws_api_gateway_integration.core_auth_proxy_any_integration.id,
      aws_api_gateway_integration.core_auth_keep_get_integration.id,
      aws_api_gateway_integration.core_auth_logout_post_integration.id,
      aws_api_gateway_integration.core_protected_proxy_integration.id,
      aws_api_gateway_gateway_response.core_unauthorized.id,
      aws_api_gateway_gateway_response.core_access_denied.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.core_public_events_integration,
    aws_api_gateway_integration.core_public_event_detail_integration,
    aws_api_gateway_integration.core_public_posts_integration,
    aws_api_gateway_integration.core_public_post_detail_integration,
    aws_api_gateway_integration.core_public_post_comments_integration,
    aws_api_gateway_integration.core_public_post_inquiry_integration,
    aws_api_gateway_integration.core_health_integration,
    aws_api_gateway_integration.core_auth_root_any_integration,
    aws_api_gateway_integration.core_auth_proxy_any_integration,
    aws_api_gateway_integration.core_auth_keep_get_integration,
    aws_api_gateway_integration.core_auth_logout_post_integration,
    aws_api_gateway_integration.core_protected_proxy_integration,
    aws_api_gateway_gateway_response.core_unauthorized,
    aws_api_gateway_gateway_response.core_access_denied,
  ]
}

resource "aws_api_gateway_stage" "stagelog_core_rest_stage" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_core_rest_api.id
  stage_name    = var.stage_name
  deployment_id = aws_api_gateway_deployment.stagelog_core_rest_deployment.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_access_logs.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      method             = "$context.httpMethod"
      path               = "$context.path"
      protocol           = "$context.protocol"
      status             = "$context.status"
      responseLength     = "$context.responseLength"
      responseTime       = "$context.responseLatency"
      integrationLatency = "$context.integrationLatency"
      errorMessage       = "$context.error.message"
      integrationError   = "$context.integration.error"
    })
  }

  depends_on = [
    aws_api_gateway_account.this
  ]
}

#------------------------------------------------------------
# Permissions (API Gateway -> Lambda invoke)
#------------------------------------------------------------
resource "aws_lambda_permission" "allow_apigw_rest_core_authorizer" {
  statement_id  = "AllowExecutionFromRestApiGatewayCoreAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.auth_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.stagelog_core_rest_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_rest_core_auth_api" {
  statement_id  = "AllowExecutionFromRestApiGatewayCoreAuthApi"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.auth_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.stagelog_core_rest_api.execution_arn}/*/*"
}

#------------------------------------------------------------
# Outputs
#------------------------------------------------------------
output "api_invoke_url" {
  value = aws_api_gateway_stage.stagelog_core_rest_stage.invoke_url
}
