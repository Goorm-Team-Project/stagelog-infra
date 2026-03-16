# API Gateway (REST) auth routes were moved to 3-ephemeral.
#
# Current target architecture:
# - single REST API Gateway in 3-ephemeral
# - /api/auth/* -> auth Lambda
# - /api/*, /health -> EKS ingress(ALB) via VPC Link
#
# This file is intentionally kept as a placeholder to prevent
# accidental reintroduction of a separate auth-only API Gateway.
