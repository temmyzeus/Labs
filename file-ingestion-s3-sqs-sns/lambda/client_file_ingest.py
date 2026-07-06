import json
from typing import Any

from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext
import awswrangler as wr

logger = Logger()


def extract_s3_details_from_sqs(sqs_message: dict[str, Any]) -> list[dict[str, str]]:
    """
    Extract S3 bucket and key information from SQS message body.
    Handles S3:ObjectCreated:Put event notifications from SNS through SQS.
    """
    s3_files = []

    try:
        message_body = json.loads(sqs_message.get("body", "{}"))

        if "Message" in message_body:
            message_content = json.loads(message_body["Message"])
        else:
            message_content = message_body

        for record in message_content["Records"]:
            s3_info = record["s3"]
            bucket = s3_info.get("bucket", {}).get("name")
            key = s3_info.get("object", {}).get("key")

            if bucket and key:
                s3_files.append({"bucket": bucket, "key": key})
            else:
                logger.warning("Missing bucket or key in S3 record", extra={"record": record})

        logger.debug("Extracted S3 files from SQS message", extra={"count": len(s3_files)})

    except json.JSONDecodeError as e:
        logger.exception("Error parsing SQS message", extra={"error": str(e)})
    except KeyError as e:
        logger.exception("Missing expected key in SQS message", extra={"error": str(e)})

    return s3_files


@logger.inject_lambda_context(log_event=True)
def lambda_handler(event: dict[str, Any], context: LambdaContext) -> dict[str, Any]:
    """
    Lambda handler that validates and processes S3 files from the S3 Event Notification in SQS Queue.


    Arguments:
        event (dict[str, Any]): Records: List of SQS message records from event source mapping.
        context (LambdaContext)

    Returns:
        result: str
    """

    logger.info("Lambda Invoked")

    sqs_records: list = event.get("Records", [])

    response: dict[str, Any] = {
        "statusCode": 200,
        "processedFiles": [],
        "failedFiles": [],
        "summary": {},
    }

    if not sqs_records:
        response["statusCode"] = 400
        response["error"] = "No SQS records found in event"
        logger.warning(response["error"])
        return response
    
    logger.info("Processing SQS messages", extra={"record_count": len(sqs_records)})

    for sqs_record in sqs_records:
        s3_files = extract_s3_details_from_sqs(sqs_record)

        logger.debug("S3 files extracted from SQS record", extra={"s3_files": s3_files})

    response["summary"] = {
        "total_processed": None,
        "total_failed": None,
        "total_sqs_records": len(sqs_records)
    }

    logger.info("Lambda execution complete")

    return response
