resource "aws_s3_bucket" "elastic-backup" {
  bucket = "${var.service}-elastic-backups"
  acl    = "private"

  tags {
    Name = "${var.service} elastic backups"
  }
}
