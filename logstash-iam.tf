
resource "aws_iam_instance_profile" "logstash-ecs-instance-profile" {
    name = "${var.logstash_conf["service"]}-ecs"
    role = "${aws_iam_role.logstash-ecs-instance-role.id}"
}

resource "aws_iam_role" "logstash-ecs-instance-role" {
    name = "${var.logstash_conf["service"]}-ecs_role"
    path = "/"

    assume_role_policy = "${file("${path.module}/policies/ecs-trust-role-policy.json")}"
}

resource "aws_iam_role" "logstash-autoscaling-role" {
    name = "${var.logstash_conf["service"]}-autoscaling_role"
    path = "/"

    assume_role_policy = "${file("${path.module}/policies/ecs-autoscaling-trust-role-policy.json")}"
}
