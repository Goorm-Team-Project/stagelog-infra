# RDS Lambda 역할
resource "aws_iam_role" "stagelog_rds_lambda_role_managed" {
  name = "stagelog-rds-lambda-role-managed"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::430118823715:policy/service-role/AWSLambdaBasicExecutionRole-dfc0340f-2e3b-4f7c-891c-98b53cfeccec",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
}