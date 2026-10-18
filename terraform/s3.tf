resource "aws_s3_bucket" "hr_documents" {
  bucket = "${local.name_prefix}-documents-${local.account_id}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "hr_documents" {
  bucket = aws_s3_bucket.hr_documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "hr_documents" {
  bucket = aws_s3_bucket.hr_documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "hr_documents" {
  bucket = aws_s3_bucket.hr_documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "employee_handbook" {
  bucket       = aws_s3_bucket.hr_documents.id
  key          = "documents/employee-handbook.txt"
  source       = "${path.module}/../documents/employee-handbook.txt"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/../documents/employee-handbook.txt")
  tags         = var.tags
}

resource "aws_s3_object" "leave_policy" {
  bucket       = aws_s3_bucket.hr_documents.id
  key          = "documents/leave-policy.txt"
  source       = "${path.module}/../documents/leave-policy.txt"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/../documents/leave-policy.txt")
  tags         = var.tags
}

resource "aws_s3_object" "benefits_faq" {
  bucket       = aws_s3_bucket.hr_documents.id
  key          = "documents/benefits-faq.txt"
  source       = "${path.module}/../documents/benefits-faq.txt"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/../documents/benefits-faq.txt")
  tags         = var.tags
}

resource "aws_s3_object" "onboarding_guide" {
  bucket       = aws_s3_bucket.hr_documents.id
  key          = "documents/onboarding-guide.txt"
  source       = "${path.module}/../documents/onboarding-guide.txt"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/../documents/onboarding-guide.txt")
  tags         = var.tags
}
