variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {}

provider "aws" {
  region  = "us-east-2"
  profile = "prajithnairsolutions"
}

resource "aws_s3_bucket" "terraform_state" {
  // This is only here so we can destroy the bucket as part of automated tests. You should not copy this for production
  // usage
  bucket        = "tf-prajith-bucket"
  force_destroy = true

  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
