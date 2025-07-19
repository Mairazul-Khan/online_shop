# =============================================================================
# CONDITIONAL TERRAFORM BACKEND RESOURCES
# =============================================================================
# These resources use 'count' for conditional creation based on var.create_backend
# - If var.create_backend = true  → count = 1 (create resources)
# - If var.create_backend = false → count = 0 (skip resources)
# This prevents "resource already exists" errors in CI/CD pipeline
# =============================================================================


resource "aws_s3_bucket" "terraform_aws_s3_bucket" {
  # CONDITIONAL CREATION: count = var.create_backend ? 1 : 0
  # - true = create 1 bucket, false = create 0 buckets (skip)
  # - Value comes from GitHub Actions: -var="create_backend=$CREATE_BACKEND"
  count  = var.create_backend ? 1 : 0
  bucket = var.aws_s3_bucket_name
  force_destroy = true

  tags = {
    Name = var.aws_s3_bucket_name
    Purpose = "Terraform State Storage"
    ManagedBy = "GitHub Actions CI/CD"
  }
      
  lifecycle {
    # prevent_destroy = true
    ignore_changes = [tags]
  }
}

resource "aws_dynamodb_table" "terraform_aws_db" {
  # CONDITIONAL CREATION: Same logic as S3 bucket above
  # This table provides state locking to prevent concurrent Terraform runs
  count        = var.create_backend ? 1 : 0
  name         = var.aws_dynamodb_table_name
  billing_mode = var.aws_db_billing_mode
  hash_key     = var.aws_db_hashkey

  attribute {
    name = "LockID"  # Must match hash_key above
    type = "S"       # String type
  }

  tags = {
    Name = var.aws_dynamodb_table_name
    Purpose = "Terraform State Locking"
    ManagedBy = "GitHub Actions CI/CD"
  }

  lifecycle {
    # prevent_destroy = true
    ignore_changes = [tags]
  }
}

