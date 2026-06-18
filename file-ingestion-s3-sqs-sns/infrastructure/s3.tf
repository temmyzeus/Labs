
resource "aws_s3_bucket" "client_traffic_bucket" {
  bucket              = "${local.bucket_name}-${local.bucket_region}"
  region              = local.bucket_region
  force_destroy       = false
  object_lock_enabled = false

  tags = {
    Content     = "Client traffic files"
    Description = "Bucket to receive traffic files from clients"
  }
}

resource "aws_s3_bucket_notification" "client_traffic_bucket_notification" {
  bucket = aws_s3_bucket.client_traffic_bucket.id

  queue {
    id            = "ClientFileArrivalNotification"
    queue_arn     = aws_sqs_queue.client_traffic_arrival_queue.arn
    events        = ["s3:ObjectCreated:Put"]
    filter_prefix = "Client-"
  }

  depends_on = [
    aws_sqs_queue_policy.allow
  ]
}
