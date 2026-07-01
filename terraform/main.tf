terraform {
  required_version = ">= 1.3.0"

  # Local state on purpose (simpler solo setup — no S3 bucket to create/destroy).
  # Production equivalent: an S3 backend with DynamoDB state locking.

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "8byte-devops"
      ManagedBy = "terraform"
    }
  }
}
