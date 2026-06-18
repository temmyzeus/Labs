
resource "aws_iam_role" "file_processor_role" {
  name        = "FileIngestionSQSToLambdaFunctionRole"
  description = "Role for the lambda function which processes the files sent by client."

  # Trusted Entities for the Role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AllowsLambdaToAssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
