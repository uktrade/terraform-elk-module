
resource "aws_iam_instance_profile" "kibana-ecs-instance-profile" {
    name = "${var.kibana_conf["service"]}-ecs"
    role = "${aws_iam_role.kibana-ecs-instance-role.id}"
}

resource "aws_iam_role" "kibana-ecs-instance-role" {
    name = "${var.kibana_conf["service"]}-ecs_role"
    path = "/"

    assume_role_policy = "${file("${path.module}/policies/ecs-trust-role-policy.json")}"
}

resource "aws_iam_role" "kibana-autoscaling-role" {
    name = "${var.kibana_conf["service"]}-autoscaling_role"
    path = "/"

    assume_role_policy = "${file("${path.module}/policies/ecs-autoscaling-trust-role-policy.json")}"
}
