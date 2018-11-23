resource "aws_cloudwatch_log_group" "elk-cwl-log-group" {
  name = "${var.service}"

  retention_in_days = "${var.cwl_retention_in_days}"

  tags {
    Service = "${var.service}"
  }
}

resource "aws_cloudwatch_log_destination" "cross_account_to_kinesis" {
  name       = "${var.service}-cross_account"
  role_arn   = "${aws_iam_role.cloudwatch_logs_put_kinesis_records.arn}"
  target_arn = "${aws_kinesis_stream.elk_kinesis_from_cloudwatch.arn}"
}

resource "aws_cloudwatch_log_destination_policy" "cross_account_to_kinesis" {
  destination_name = "${aws_cloudwatch_log_destination.cross_account_to_kinesis.name}"
  access_policy    = "${data.aws_iam_policy_document.cross_account_to_kinesis.json}"
}

data "aws_iam_policy_document" "cross_account_to_kinesis" {
  statement {
    actions = ["logs:PutSubscriptionFilter"]

    principals {
      type        = "AWS"
      identifiers = ["${var.cross_account_to_kinesis_source_account_ids}"]
    }

    resources = [
      "${aws_cloudwatch_log_destination.cross_account_to_kinesis.arn}",
    ]
  }
}

resource "aws_iam_role" "cloudwatch_logs_put_kinesis_records" {
  name               = "${var.service}-cloudwatch-logs-put-kinesis-records"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.cloudwatch_logs_put_kinesis_records_assume_role.json}"
}

data "aws_iam_policy_document" "cloudwatch_logs_put_kinesis_records_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_conf["region"]}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_put_kinesis_records" {
  role       = "${aws_iam_role.cloudwatch_logs_put_kinesis_records.name}"
  policy_arn = "${aws_iam_policy.cloudwatch_logs_put_kinesis_records.arn}"
}

resource "aws_iam_policy" "cloudwatch_logs_put_kinesis_records" {
  name        = "${var.service}-cloudwatch-logs-put-kinesis-records"
  path        = "/"
  policy       = "${data.aws_iam_policy_document.cloudwatch_logs_put_kinesis_records.json}"
}

data "aws_iam_policy_document" "cloudwatch_logs_put_kinesis_records" {
  statement {
    actions = [
      "kinesis:PutRecord",
      "kinesis:PutRecords",
    ]

    resources = [
      "${aws_kinesis_stream.elk_kinesis_from_cloudwatch.arn}",
    ]
  }

  statement {
    actions = [
      "kms:GenerateDataKey",
    ]

    resources = [
      "${aws_kms_key.elk-data-key.arn}",
    ]
  }

  statement {
    actions = [
      "iam:PassRole",
    ]

    resources = [
      "${aws_iam_role.cloudwatch_logs_put_kinesis_records.arn}",
    ]
  }
}
