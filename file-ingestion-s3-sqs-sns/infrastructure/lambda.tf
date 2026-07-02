
data "archive_file" "archived_lambda_file" {
  type        = "zip"
  source_file = "${path.module}/../lambda/client_file_ingest.py"
  output_path = "${path.module}/../lambda/client_file_ingest_output.zip"
}

data "aws_ssm_parameter" "powertools" {
  name = "/aws/service/powertools/python/x86_64/python3.14/latest"
}

resource "aws_lambda_function" "file_processor" {
  filename      = data.archive_file.archived_lambda_file.output_path
  function_name = "client-file-ingestion"
  role          = aws_iam_role.file_processor_role.arn
  handler       = "client_file_ingest.lambda_handler"
  code_sha256   = data.archive_file.archived_lambda_file.output_base64sha256

  runtime = "python3.14"

  layers = [data.aws_ssm_parameter.powertools.value]

  environment {
    variables = {
      POWERTOOLS_LOG_LEVEL    = "INFO"
      POWERTOOLS_SERVICE_NAME = "client-file-ingestion"
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda_mapping" {
  event_source_arn                   = aws_sqs_queue.client_traffic_arrival_queue.arn
  function_name                      = aws_lambda_function.file_processor.function_name
  batch_size                         = 10
  maximum_batching_window_in_seconds = 60
  enabled                            = true

  scaling_config {
    maximum_concurrency = 10 # Maximum number of Lambda invocations, SQS can concurrently create
  }
}
