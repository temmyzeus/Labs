terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.37.0"
    }
  }
  backend "s3" {
    bucket       = "terraform-state-files-409021554022"
    key          = "labs/file-ingestion-s3-sqs-sns/terraform.tfstate"
    use_lockfile = true
    region       = "us-west-2"
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = "production"
    }
  }
}
