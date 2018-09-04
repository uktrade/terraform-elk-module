resource "aws_cloudwatch_log_group" "elk-cwl-log-group" {
  name = "${var.service}"

  tags {
    Service = "${var.service}"
  }
}
