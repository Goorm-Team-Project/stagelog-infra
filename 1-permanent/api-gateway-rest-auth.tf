# REST API (v1) for /api/auth/*
# Goal: enforce monolith-like common_response on auth-related 401/403 via GatewayResponse

locals {
  auth_api_lambda_invoke_uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.auth_api.arn}/invocations"
}

resource "aws_api_gateway_rest_api" "stagelog_auth_rest_api" {
  name = "${var.api_name}-auth-rest"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "rest_api_root_api" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  parent_id   = aws_api_gateway_rest_api.stagelog_auth_rest_api.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "rest_api_root_auth" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  parent_id   = aws_api_gateway_resource.rest_api_root_api.id
  path_part   = "auth"
}

resource "aws_api_gateway_resource" "rest_api_auth_proxy" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  parent_id   = aws_api_gateway_resource.rest_api_root_auth.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_resource" "rest_api_auth_keep" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  parent_id   = aws_api_gateway_resource.rest_api_root_auth.id
  path_part   = "keep"
}

resource "aws_api_gateway_resource" "rest_api_auth_logout" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  parent_id   = aws_api_gateway_resource.rest_api_root_auth.id
  path_part   = "logout"
}

resource "aws_api_gateway_authorizer" "rest_jwt_authorizer" {
  name           = "jwt-authorizer-rest"
  rest_api_id    = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  type           = "REQUEST"
  authorizer_uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.auth_authorizer.arn}/invocations"

  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 0
}

# /api/auth (ANY) -> auth lambda (public)
resource "aws_api_gateway_method" "rest_auth_root_any" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  resource_id   = aws_api_gateway_resource.rest_api_root_auth.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "rest_auth_root_any_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  resource_id             = aws_api_gateway_resource.rest_api_root_auth.id
  http_method             = aws_api_gateway_method.rest_auth_root_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.auth_api_lambda_invoke_uri
}

# /api/auth/{proxy+} (ANY) -> auth lambda (public; login/refresh etc)
resource "aws_api_gateway_method" "rest_auth_proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  resource_id   = aws_api_gateway_resource.rest_api_auth_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "rest_auth_proxy_any_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  resource_id             = aws_api_gateway_resource.rest_api_auth_proxy.id
  http_method             = aws_api_gateway_method.rest_auth_proxy_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.auth_api_lambda_invoke_uri
}

# /api/auth/keep (GET) -> auth lambda (protected)
resource "aws_api_gateway_method" "rest_auth_keep_get" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  resource_id   = aws_api_gateway_resource.rest_api_auth_keep.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.rest_jwt_authorizer.id
}

resource "aws_api_gateway_integration" "rest_auth_keep_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  resource_id             = aws_api_gateway_resource.rest_api_auth_keep.id
  http_method             = aws_api_gateway_method.rest_auth_keep_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.auth_api_lambda_invoke_uri
}

# /api/auth/logout (POST) -> auth lambda (protected)
resource "aws_api_gateway_method" "rest_auth_logout_post" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  resource_id   = aws_api_gateway_resource.rest_api_auth_logout.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.rest_jwt_authorizer.id
}

resource "aws_api_gateway_integration" "rest_auth_logout_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  resource_id             = aws_api_gateway_resource.rest_api_auth_logout.id
  http_method             = aws_api_gateway_method.rest_auth_logout_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.auth_api_lambda_invoke_uri
}

# Monolith-style common_response for auth rejections
resource "aws_api_gateway_gateway_response" "rest_auth_unauthorized" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
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

resource "aws_api_gateway_gateway_response" "rest_auth_access_denied" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
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

resource "aws_api_gateway_deployment" "stagelog_auth_rest_deployment" {
  rest_api_id = aws_api_gateway_rest_api.stagelog_auth_rest_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.rest_auth_root_any.id,
      aws_api_gateway_method.rest_auth_proxy_any.id,
      aws_api_gateway_method.rest_auth_keep_get.id,
      aws_api_gateway_method.rest_auth_logout_post.id,
      aws_api_gateway_integration.rest_auth_root_any_integration.id,
      aws_api_gateway_integration.rest_auth_proxy_any_integration.id,
      aws_api_gateway_integration.rest_auth_keep_get_integration.id,
      aws_api_gateway_integration.rest_auth_logout_post_integration.id,
      aws_api_gateway_gateway_response.rest_auth_unauthorized.id,
      aws_api_gateway_gateway_response.rest_auth_access_denied.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.rest_auth_root_any_integration,
    aws_api_gateway_integration.rest_auth_proxy_any_integration,
    aws_api_gateway_integration.rest_auth_keep_get_integration,
    aws_api_gateway_integration.rest_auth_logout_post_integration,
    aws_api_gateway_gateway_response.rest_auth_unauthorized,
    aws_api_gateway_gateway_response.rest_auth_access_denied,
  ]
}

resource "aws_api_gateway_stage" "stagelog_auth_rest_stage" {
  rest_api_id   = aws_api_gateway_rest_api.stagelog_auth_rest_api.id
  stage_name    = var.rest_auth_stage_name
  deployment_id = aws_api_gateway_deployment.stagelog_auth_rest_deployment.id
}

resource "aws_lambda_permission" "allow_apigw_rest_auth" {
  statement_id  = "AllowExecutionFromRestApiGatewayAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.stagelog_auth_rest_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_rest_authorizer" {
  statement_id  = "AllowExecutionFromRestApiGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.stagelog_auth_rest_api.execution_arn}/*/*"
}

output "auth_rest_api_invoke_url" {
  description = "Invoke URL for REST API auth gateway"
  value       = aws_api_gateway_stage.stagelog_auth_rest_stage.invoke_url
}
