resource "aws_cloudwatch_log_group" "elk-cwl-log-group" {
  name = "${var.service}"

  retention_in_days = "${var.cwl_retention_in_days}"

  tags {
    Service = "${var.service}"
  }
}
