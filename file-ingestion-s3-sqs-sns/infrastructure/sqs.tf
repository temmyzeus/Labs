
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
