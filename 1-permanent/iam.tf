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
}

resource "aws_iam_role_policy_attachment" "rds_lambda_attach_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.stagelog_rds_lambda_role_managed.name
}

resource "aws_iam_role_policy_attachment" "rds_lambda_attach_vpc_access" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.stagelog_rds_lambda_role_managed.name
}