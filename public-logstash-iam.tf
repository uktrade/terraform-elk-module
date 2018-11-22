
resource "aws_iam_instance_profile" "public_logstash-ecs-instance-profile" {
    name = "${var.public_logstash_conf["service"]}-ecs"
    role = "${aws_iam_role.public_logstash-ecs-instance-role.id}"
}

resource "aws_iam_role" "public_logstash-ecs-instance-role" {
    name = "${var.public_logstash_conf["service"]}-ecs_role"
    path = "/"

    assume_role_policy = "${file("${path.module}/policies/ecs-trust-role-policy.json")}"
}

resource "aws_iam_role" "public_logstash-autoscaling-role" {
    name = "${var.public_logstash_conf["service"]}-autoscaling_role"
    path = "/"

    assume_role_policy = "${data.aws_iam_policy_document.public_logstash-autoscaling-role.json}"
}

data "aws_iam_policy_document" "public_logstash-autoscaling-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}
