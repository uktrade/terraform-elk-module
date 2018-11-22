
resource "aws_iam_instance_profile" "kibana-ecs-instance-profile" {
    name = "${var.kibana_conf["service"]}-ecs"
    role = "${aws_iam_role.kibana-ecs-instance-role.id}"
}

resource "aws_iam_role" "kibana-ecs-instance-role" {
    name = "${var.kibana_conf["service"]}-ecs_role"
    path = "/"
    assume_role_policy = "${data.aws_iam_policy_document.kibana-ecs-instance-role.json}"
}

data "aws_iam_policy_document" "kibana-ecs-instance-role" {
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

resource "aws_iam_role" "kibana-autoscaling-role" {
    name = "${var.kibana_conf["service"]}-autoscaling_role"
    path = "/"

    assume_role_policy = "${data.aws_iam_policy_document.kibana-autoscaling-role.json}"
}

data "aws_iam_policy_document" "kibana-autoscaling-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}
