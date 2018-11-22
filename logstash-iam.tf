
resource "aws_iam_instance_profile" "logstash-ecs-instance-profile" {
    name = "${var.logstash_conf["service"]}-ecs"
    role = "${aws_iam_role.logstash-ecs-instance-role.id}"
}

resource "aws_iam_role" "logstash-ecs-instance-role" {
    name = "${var.logstash_conf["service"]}-ecs_role"
    path = "/"

    assume_role_policy = "${data.aws_iam_policy_document.logstash-ecs-instance-role.json}"
}

data "aws_iam_policy_document" "logstash-ecs-instance-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "ecs.amazonaws.com",
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "logstash-autoscaling-role" {
    name = "${var.logstash_conf["service"]}-autoscaling_role"
    path = "/"

    assume_role_policy = "${data.aws_iam_policy_document.logstash-autoscaling-role.json}"
}

data "aws_iam_policy_document" "logstash-autoscaling-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}
