resource "aws_iam_role" "autoscaling-role" {
  name = "${var.service}-autoscaling_role"
  path = "/"
  assume_role_policy = "${file("${path.module}/policies/ecs-autoscaling-trust-role-policy.json")}"
}

resource "aws_iam_policy" "ecs-autoscaling-policy" {
  name = "${var.service}-ecs-autoscaling_policy"
  policy = "${file("${path.module}/policies/AmazonEC2ContainerServiceAutoscaleRole.json")}"
}

resource "aws_iam_policy" "ecs-service-for-ec2-policy" {
  name = "${var.service}-ecs-service-for-ec2_policy"
  policy = "${file("${path.module}/policies/AmazonEC2ContainerServiceforEC2Role.json")}"
}

resource "aws_iam_policy" "ecs-service-policy" {
  name = "${var.service}-ecs-service_policy"
  policy = "${file("${path.module}/policies/AmazonEC2ContainerServiceRole.json")}"
}

resource "aws_iam_policy" "dynamodb-policy" {
  name = "${var.service}-dynamodb-policy"

  policy = "${file("${path.module}/policies/dynamodb-policy.json")}"
}

data "template_file" "kinesis_put_template" {
  template = "${file("${path.module}/policies/kinesis-put.json")}"

  vars {
    kinesis_arn = "${aws_kinesis_stream.elk_kinesis.arn}"
    kms_arn = "${aws_kms_key.elk-data-key.arn}"
  }
}

data "template_file" "kinesis_get_template" {
  template = "${file("${path.module}/policies/kinesis-get.json")}"

  vars {
    kinesis_arn = "${aws_kinesis_stream.elk_kinesis.arn}"
    kms_arn = "${aws_kms_key.elk-data-key.arn}"
  }
}

resource "aws_iam_policy" "kinesis_put-policy" {
  name = "${var.service}-kinesis-put-policy"

  policy = "${data.template_file.kinesis_put_template.rendered}"
}

resource "aws_iam_policy" "kinesis_get-policy" {
  name = "${var.service}-kinesis-get-policy"

  policy = "${data.template_file.kinesis_get_template.rendered}"
}

resource "aws_iam_policy_attachment" "ecs-service-ec2-policy-attachment" {
  name = "${var.service}-ecs-ec2_role"
  roles = [
    "${aws_iam_role.logstash-ecs-instance-role.name}",
    "${aws_iam_role.public_logstash-ecs-instance-role.name}",
    "${aws_iam_role.elastic-ecs-instance-role.name}",
    "${aws_iam_role.kibana-ecs-instance-role.name}"
  ]

  policy_arn = "${aws_iam_policy.ecs-service-for-ec2-policy.arn}"
}

resource "aws_iam_policy_attachment" "ecs-service-policy-attachment" {
  name = "${var.service}-ecs-role"
  roles = [
    "${aws_iam_role.logstash-ecs-instance-role.name}",
    "${aws_iam_role.public_logstash-ecs-instance-role.name}",
    "${aws_iam_role.elastic-ecs-instance-role.name}",
    "${aws_iam_role.kibana-ecs-instance-role.name}"
  ]

  policy_arn = "${aws_iam_policy.ecs-service-policy.arn}"
}

resource "aws_iam_policy_attachment" "ecs-dynamodb-policy-attachment" {
  name = "${var.service}-ecs-role"
  roles = [
    "${aws_iam_role.logstash-ecs-instance-role.name}",
  ]

  policy_arn = "${aws_iam_policy.dynamodb-policy.id}"
}

resource "aws_iam_policy_attachment" "kinesis-put-policy-attachment" {
  name = "${var.service}-kinesis-put-policy-attachment"
  roles = [
    "${aws_iam_role.public_logstash-ecs-instance-role.name}"
  ]

  policy_arn = "${aws_iam_policy.kinesis_put-policy.arn}"
}

resource "aws_iam_policy_attachment" "kinesis-get-policy-attachment" {
  name = "${var.service}-kinesis-get-policy-attachment"
  roles = [
    "${aws_iam_role.logstash-ecs-instance-role.name}"
  ]

  policy_arn = "${aws_iam_policy.kinesis_get-policy.arn}"
}

resource "aws_iam_policy_attachment" "autoscaling-policy-attachment" {
  name = "${var.service}-autoscaling_policy_attachment"
  roles = [
    "${aws_iam_role.autoscaling-role.id}"
  ]

  policy_arn = "${aws_iam_policy.ecs-autoscaling-policy.arn}"
}

