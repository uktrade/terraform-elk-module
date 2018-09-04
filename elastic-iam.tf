
resource "aws_iam_instance_profile" "elastic-ecs-instance-profile" {
    name = "${var.elastic_conf["service"]}-ecs"
    role = "${aws_iam_role.elastic-ecs-instance-role.id}"
}

resource "aws_iam_role" "elastic-ecs-instance-role" {
    name = "${var.elastic_conf["service"]}-ecs_role"
    path = "/"

    assume_role_policy = "${file("${path.module}/policies/ecs-trust-role-policy.json")}"
}

resource "aws_iam_policy" "elastic-policy" {
  policy = "${file("${path.module}/policies/elastic-sg-policy.json")}"
}

resource "aws_iam_policy_attachment" "elastic-policy-attachment" {
  name = "${var.elastic_conf["service"]}-elasticsearch-policy"
  roles = ["${aws_iam_role.elastic-ecs-instance-role.id}"]

  policy_arn = "${aws_iam_policy.elastic-policy.arn}"
}

# Allow elastic instances to have access to the s3 backup bucket
data "template_file" "elastic-s3-policy-template" {
  template = "${file("${path.module}/policies/elastic-s3-backup-policy.json")}"

  vars {
    bucket_arn = "${aws_s3_bucket.elastic-backup.arn}"
  }
}

resource "aws_iam_policy" "elastic-s3-backup-policy" {
  name = "${var.elastic_conf["service"]}-backup-policy"

  policy = "${data.template_file.elastic-s3-policy-template.rendered}"
}

resource "aws_iam_policy_attachment" "elastic-s3-backup-policy-attachment" {
  name = "${var.elastic_conf["service"]}-s3-backup-policy-attachment"

  roles = ["${aws_iam_role.elastic-ecs-instance-role.id}"]

  policy_arn = "${aws_iam_policy.elastic-s3-backup-policy.arn}"
}
