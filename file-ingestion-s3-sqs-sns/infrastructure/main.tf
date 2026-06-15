
locals {
  bucket_name   = "client-traffic"
  bucket_region = "us-east-1"
}

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

# SQS Resources

resource "aws_sqs_queue" "client_traffic_arrival_queue" {
  name                      = "client-traffic-files-arrival-queue"
  fifo_queue                = false # Standard Queue
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

resource "aws_sqs_queue_policy" "allow" {
  queue_url = aws_sqs_queue.client_traffic_arrival_queue.url
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowS3EventSendMessage",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "s3.amazonaws.com"
          },
          "Action" : [
            "sqs:SendMessage"
          ],
          "Resource" : [
            "${aws_sqs_queue.client_traffic_arrival_queue.arn}"
          ]
          "Condition" : {
            "ArnEquals" : {
              "aws:SourceArn" : "${aws_s3_bucket.client_traffic_bucket.arn}"
            }
          }
        }
      ]
    }
  )
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


