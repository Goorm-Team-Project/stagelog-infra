resource "aws_iam_role" "SSM_CloudWatchlog_Role_Managed" {
  name = "SSM-CloudWatchlog-Role-Managed"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_role" "Combine_SSM_CloudWatchlog_S3_Uploader_Managed" {
    name = "Combine-SSM-CloudWatchlog-S3-Uploader-Managed"

    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  managed_policy_arns = [ 
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::430118823715:policy/stagelog-dev-s3-uploads-policy"
   ]
}

resource "aws_iam_role" "stagelog_rds_rambda_role_managed" {
  name = "stagelog-rds-rambda-role-managed"

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