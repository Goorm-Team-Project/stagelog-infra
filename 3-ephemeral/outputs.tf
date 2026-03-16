output "core_api_execute_domain_name" {
  description = "Execute API domain for core REST API (for CloudFront origin)"
  value       = "${aws_api_gateway_rest_api.stagelog_core_rest_api.id}.execute-api.${var.aws_region}.amazonaws.com"
}

output "core_api_stage_name" {
  description = "Stage name for core REST API (for CloudFront origin path)"
  value       = aws_api_gateway_stage.stagelog_core_rest_stage.stage_name
}
