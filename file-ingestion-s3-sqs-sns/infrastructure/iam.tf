
data "aws_iam_policy" "aws_lambda_sqs_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

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

resource "aws_iam_role_policy_attachment" "file_processor_role_policy_attachment" {
  role       = aws_iam_role.file_processor_role.name
  policy_arn = data.aws_iam_policy.aws_lambda_sqs_execution_role_policy.arn
}
