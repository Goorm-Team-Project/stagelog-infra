# API Gateway (HTTP API v2) - /api 라우트 계약의 1차 뼈대
# - /api/auth/* : Auth Service(권한 검증 제외)
# - 공개 API GET /api/events*, /api/posts* : Authorizer 제외
# - 보호 API: 그 외 /api/{proxy+} 는 Authorizer 적용

#------------------------------------------------------------
# API Gateway
#------------------------------------------------------------
resource "aws_apigatewayv2_api" "stagelog_http_api" {
  name          = var.api_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = true
    allow_headers = [
      "Authorization",
      "Content-Type",
      "Origin",
      "Accept",
      "X-Requested-With",
      "X-CSRF-Token"
    ]
    allow_methods = [
      "GET",
      "POST",
      "PUT",
      "PATCH",
      "DELETE",
      "OPTIONS"
    ]
    allow_origins = var.allowed_cors_origins
    max_age       = 86400
    expose_headers = [
      "Location",
      "X-Request-Id"
    ]
  }
}

resource "aws_cloudwatch_log_group" "apigw_access_logs" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = var.log_retention_days
}

#------------------------------------------------------------
# Integrations
#------------------------------------------------------------
# API Gateway -> private ALB 연결용 VPC Link
resource "aws_apigatewayv2_vpc_link" "core_vpc_link" {
  name               = "stagelog-core-vpc-link"
  subnet_ids         = [aws_subnet.stagelog-subnet-private-2a.id, aws_subnet.stagelog-subnet-private-2c.id]
  security_group_ids = [aws_security_group.lambda-sg.id]
}

# Auth Lambda (예: /home/woosupar/stagelog-auth 의 Lambda auth 핸들러)
resource "aws_apigatewayv2_integration" "auth_integration" {
  api_id                 = aws_apigatewayv2_api.stagelog_http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth_api.invoke_arn
  payload_format_version = "2.0"
  integration_method     = "POST"
}

# Core/API 통합 (ALB / EKS 서비스 오리진)
# private ALB HTTPS listener ARN 사용 (from ephemeral remote state)
resource "aws_apigatewayv2_integration" "core_integration" {
  api_id                 = aws_apigatewayv2_api.stagelog_http_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = data.terraform_remote_state.ephemeral.outputs.alb_https_listener_arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.core_vpc_link.id
  payload_format_version = "1.0"

  # HTTPS ALB/도메인을 쓰는 경우 verify 필수사항이면 주석 해제
  # tls_config {
  #   server_name_to_verify = var.core_api_host
  # }
}

# Authorizer 전용 Lambda (예: auth_service.handlers.authorizer)
resource "aws_apigatewayv2_authorizer" "jwt_authorizer" {
  api_id          = aws_apigatewayv2_api.stagelog_http_api.id
  name            = "jwt-authorizer"
  authorizer_type = "REQUEST"

  authorizer_uri                    = aws_lambda_function.auth_authorizer.invoke_arn
  authorizer_payload_format_version = "2.0"
  identity_sources                  = ["$request.header.Authorization"]
}

#------------------------------------------------------------
# Routes
#------------------------------------------------------------
# Auth 경로는 gateway에서 직접 auth 서비스로, 토큰 검증 예외
resource "aws_apigatewayv2_route" "auth_proxy" {
  api_id    = aws_apigatewayv2_api.stagelog_http_api.id
  route_key = "ANY /api/auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
}

# 인증이 필요한 auth 하위 라우트(예: 로그인 유지)
resource "aws_apigatewayv2_route" "auth_keep" {
  api_id             = aws_apigatewayv2_api.stagelog_http_api.id
  route_key          = "GET /api/auth/keep"
  target             = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

# 공개 GET 라우트(Authorizer 제외)
resource "aws_apigatewayv2_route" "public_events_list" {
  api_id    = aws_apigatewayv2_api.stagelog_http_api.id
  route_key = "GET /api/events"
  target    = "integrations/${aws_apigatewayv2_integration.core_integration.id}"
}

resource "aws_apigatewayv2_route" "public_event_detail" {
  api_id    = aws_apigatewayv2_api.stagelog_http_api.id
  route_key = "GET /api/events/{event_id}"
  target    = "integrations/${aws_apigatewayv2_integration.core_integration.id}"
}

resource "aws_apigatewayv2_route" "public_event_posts_list" {
  api_id    = aws_apigatewayv2_api.stagelog_http_api.id
  route_key = "GET /api/events/{event_id}/posts"
  target    = "integrations/${aws_apigatewayv2_integration.core_integration.id}"
}

resource "aws_apigatewayv2_route" "public_posts_list" {
  api_id    = aws_apigatewayv2_api.stagelog_http_api.id
  route_key = "GET /api/posts"
  target    = "integrations/${aws_apigatewayv2_integration.core_integration.id}"
}

resource "aws_apigatewayv2_route" "public_post_detail" {
  api_id    = aws_apigatewayv2_api.stagelog_http_api.id
  route_key = "GET /api/posts/{post_id}"
  target    = "integrations/${aws_apigatewayv2_integration.core_integration.id}"
}

resource "aws_apigatewayv2_route" "public_post_comments_list" {
  api_id    = aws_apigatewayv2_api.stagelog_http_api.id
  route_key = "GET /api/posts/{post_id}/comments"
  target    = "integrations/${aws_apigatewayv2_integration.core_integration.id}"
}

# 보호 API 라우트 (기본) : 그 외 /api 경로는 Authorizer 적용
resource "aws_apigatewayv2_route" "api_proxy" {
  api_id             = aws_apigatewayv2_api.stagelog_http_api.id
  route_key          = "ANY /api/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.core_integration.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

# health용 테스트 경로 (필요 시 제거 가능)
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.stagelog_http_api.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.core_integration.id}"
}

#------------------------------------------------------------
# Permissions (API Gateway -> Lambda invoke)
#------------------------------------------------------------
resource "aws_lambda_permission" "allow_apigw_auth" {
  statement_id  = "AllowExecutionFromApiGatewayAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.stagelog_http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_authorizer" {
  statement_id  = "AllowExecutionFromApiGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.stagelog_http_api.execution_arn}/*/*"
}

#------------------------------------------------------------
# Auto deploy Stage
#------------------------------------------------------------
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.stagelog_http_api.id
  name        = var.stage_name
  auto_deploy = true

  default_route_settings {
    data_trace_enabled     = true
    logging_level          = "INFO"
    throttling_burst_limit = 1000
    throttling_rate_limit  = 1000
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_access_logs.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      method             = "$context.http.method"
      path               = "$context.http.path"
      protocol           = "$context.protocol"
      status             = "$context.status"
      responseLength     = "$context.responseLength"
      responseTime       = "$context.responseLatency"
      integrationLatency = "$context.integrationLatency"
      errorMessage       = "$context.error.message"
      integrationError   = "$context.integration.error"
    })
  }
}

resource "aws_apigatewayv2_domain_name" "api_custom_domain" {
  domain_name = var.api_domain_name

  domain_name_configuration {
    certificate_arn = var.api_domain_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "api_domain_mapping" {
  api_id      = aws_apigatewayv2_api.stagelog_http_api.id
  domain_name = aws_apigatewayv2_domain_name.api_custom_domain.id
  stage       = aws_apigatewayv2_stage.default.name
}

#------------------------------------------------------------
# Outputs
#------------------------------------------------------------
output "api_invoke_url" {
  value = aws_apigatewayv2_api.stagelog_http_api.api_endpoint
}

output "api_custom_domain_url" {
  value = "https://${var.api_domain_name}"
}
