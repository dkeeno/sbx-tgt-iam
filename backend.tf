# =============================================================================
# backend.tf — S3 + DynamoDB remote state (shared backend, isolated key)
# =============================================================================
#
# Reuses the project-wide bootstrap bucket + lock table created by
# github-terraform-aws/bootstrap/. We DON'T provision them here.
#
# `key` is unique to this stack — does NOT collide with any sbx-* state.

terraform {
  backend "s3" {
    bucket         = "sbx-tfstate-784916389752-us-east-1"
    key            = "sbx-tgt-iam/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sbx-tfstate-locks"
    encrypt        = true
  }
}
