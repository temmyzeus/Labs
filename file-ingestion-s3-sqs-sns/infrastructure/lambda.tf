
data "archive_file" "archived_lambda_file" {
  type        = "zip"
  source_file = "${path.module}/../lambda/client_file_ingest.py"
  output_path = "${path.module}/../lambda/client_file_ingest_output.zip"
}

resource "aws_lambda_function" "file_processor" {
  filename      = data.archive_file.archived_lambda_file.output_path
  function_name = "client-file-ingestion"
  role          = aws_iam_role.file_processor_role.arn
  handler       = "client_file_ingest.handler"

  runtime = "python3.14"
  environment {

  }
}
