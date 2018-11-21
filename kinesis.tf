
data "template_file" "kms-policy" {
  template = "${file("${path.module}/policies/kms-policy.json")}"

  vars {
    public_logstash_role = "${aws_iam_role.logstash-ecs-instance-role.arn}"
    logstash_role = "${aws_iam_role.public_logstash-ecs-instance-role.arn}"
    account_id = "${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_kms_key" "elk-data-key" {
  description             = "Key to encrypt data in kinesis"

  policy = "${data.template_file.kms-policy.rendered}"
}

resource "aws_kinesis_stream" "elk_kinesis" {
  name             = "${var.service}-kinesis"
  shard_count      = 1
  retention_period = 48
  encryption_type = "KMS"
  kms_key_id = "${aws_kms_key.elk-data-key.key_id}"

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes"
  ]
}

resource "aws_kinesis_stream" "elk_kinesis_from_cloudwatch" {
  name             = "${var.service}-kinesis-from-cloudwatch"
  shard_count      = 1
  retention_period = 48
  encryption_type = "KMS"
  kms_key_id = "${aws_kms_key.elk-data-key.key_id}"

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes"
  ]
}

output "kms-id" {
  value = "${aws_kms_key.elk-data-key.id}"
}

output "kms-key-id" {
  value = "${aws_kms_key.elk-data-key.key_id}"
}





