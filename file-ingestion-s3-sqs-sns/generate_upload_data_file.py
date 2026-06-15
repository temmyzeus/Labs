"""
generate_upload_data_file.py
----------------------
Simulates a client randomly dropping either a CSV or JSON file
into an S3 landing bucket. Both formats share the same schema.

Schema: transaction records
  - transaction_id   : str   (UUID)
  - client_id        : str
  - amount           : float
  - currency         : str
  - status           : str   (pending | completed | failed)
  - timestamp        : str   (ISO-8601)

Usage:
    python file_drop_simulator.py \
        --bucket my-landing-bucket \
        --client-id client-a \
        --prefix raw/        # optional S3 key prefix

AWS credentials must be configured via one of:
    - Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
    - ~/.aws/credentials
    - IAM role (if running on EC2 / Lambda / ECS)
"""

import argparse
import csv
import io
import json
import random
import uuid
from datetime import datetime, timezone

import boto3
from botocore.exceptions import BotoCoreError, ClientError


CURRENCIES = ["USD", "EUR", "GBP", "NGN", "JPY"]
STATUSES   = ["pending", "completed", "failed"]
NUM_RECORDS_RANGE = (3, 10)
SCHEMA_FIELDS = ["transaction_id", "client_id", "amount", "currency", "status", "timestamp"]


def generate_records(client_id: str) -> list[dict]:
    """Return a list of random transaction records."""
    n = random.randint(*NUM_RECORDS_RANGE)
    records = []
    for _ in range(n):
        records.append({
            "transaction_id": str(uuid.uuid4()),
            "client_id":      client_id,
            "amount":         round(random.uniform(10.0, 10_000.0), 2),
            "currency":       random.choice(CURRENCIES),
            "status":         random.choice(STATUSES),
            "timestamp":      datetime.now(timezone.utc).isoformat(),
        })
    return records


def to_csv(records: list[dict]) -> bytes:
    """Serialise records to CSV bytes."""
    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=SCHEMA_FIELDS)
    writer.writeheader()
    writer.writerows(records)
    return buf.getvalue().encode("utf-8")


def to_json(records: list[dict]) -> bytes:
    """Serialise records to JSON bytes (array of objects)."""
    return json.dumps(records, indent=2).encode("utf-8")


def upload_to_s3(
    data:        bytes,
    bucket:      str,
    s3_key:      str,
    content_type: str,
) -> None:
    """Upload bytes to S3 and print the resulting URI."""
    s3 = boto3.client("s3")
    try:
        s3.put_object(
            Bucket=bucket,
            Key=s3_key,
            Body=data,
            ContentType=content_type,
        )
        print(f"✅  Uploaded  →  s3://{bucket}/{s3_key}")
    except (BotoCoreError, ClientError) as exc:
        print(f"❌  Upload failed: {exc}")
        raise


def main(cli_args: argparse.Namespace) -> None:
    # Randomly pick the file format — simulates unpredictable client drops
    fmt = random.choice(["csv", "json"])

    # Build a timestamped filename so repeated runs never collide in S3
    ts       = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    filename = f"{args.client_id}_{ts}.{fmt}"
    s3_key   = f"{args.prefix.rstrip('/')}/{filename}"
    no_files = int(args.no_files)

    for _ in range(no_files):
        # Generate records
        records = generate_records(args.client_id)
        print(f"📄  Format     : {fmt.upper()}")
        print(f"📦  Records    : {len(records)}")
        print(f"🗂️   S3 key     : {s3_key}")

        # Serialise and upload
        if fmt == "csv":
            data         = to_csv(records)
            content_type = "text/csv"
        else:
            data         = to_json(records)
            content_type = "application/json"

        upload_to_s3(data, args.bucket, s3_key, content_type)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Simulate a random client file drop to S3.")
    parser.add_argument("--bucket",    required=True, help="Target S3 bucket name")
    parser.add_argument("--client-id", default="client-a", help="Client identifier (default: client-a)")
    parser.add_argument("--prefix",    default="raw/",      help="S3 key prefix (default: raw/)")
    parser.add_argument("--no-files",    default="50",      help="Number of files to generate (default: 50)")
    args = parser.parse_args()

    main(
        cli_args=args
    )
