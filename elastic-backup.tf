resource "aws_s3_bucket" "elastic-backup" {
  bucket = "${var.service}-elastic-backups"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
}
