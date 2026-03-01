terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.32.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.2.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.7.0"
    }
  }
  backend "s3" {
    bucket       = "terraform-state-files-409021554022"
    key          = "labs/vpc_stuffs/terraform.tfstate"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      purpose   = "lab"
      retention = "< 1 Day"
    }
  }
}
