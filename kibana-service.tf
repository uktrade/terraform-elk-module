resource "aws_ecs_cluster" "kibana-cluster" {
    name = "${var.kibana_conf["service"]}"
}

data "template_file" "kibana-ecs-task" {
  template = "${file("${path.module}/tasks/kibana-task.json")}"

  vars {
    cluster_name = "${aws_ecs_cluster.kibana-cluster.name}"
    log_group = "${var.aws_conf["log_group"]}"
    region = "${var.aws_conf["region"]}"
    elastic_url = "${aws_route53_record.elastic-internal-alias.fqdn}"
    elastic_username = "${var.kibana_conf["kibana_username"]}"
    elastic_password = "${var.kibana_conf["kibana_password"]}"
    log_group = "${aws_cloudwatch_log_group.elk-cwl-log-group.name}"
    stream_prefix = "awslogs-${var.kibana_conf["service"]}"

    kibana_cpu = "${var.kibana_conf["kibana_cpu"]}"
    kibana_memory = "${var.kibana_conf["kibana_memory"]}"
    kibana_nginx_cpu = "${var.kibana_conf["kibana_nginx_cpu"]}"
    kibana_nginx_memory = "${var.kibana_conf["kibana_nginx_memory"]}"

    kibana_password = "${var.kibana_conf["kibana_password"]}"

    docker_image = "${var.kibana_conf["docker_image"]}"

    xpack_encryption_key = "${var.kibana_conf["xpack_encryption_key"]}"
  }
}

resource "aws_ecs_task_definition" "kibana-ecs-task-definition" {
    family = "${var.kibana_conf["service"]}"
    container_definitions = "${data.template_file.kibana-ecs-task.rendered}"
}

resource "aws_ecs_service" "kibana-ecs-service" {
    name = "${var.kibana_conf["service"]}-service"
    cluster = "${aws_ecs_cluster.kibana-cluster.id}"
    task_definition = "${aws_ecs_task_definition.kibana-ecs-task-definition.arn}"
    iam_role = "${aws_iam_role.kibana-ecs-instance-role.id}"
    desired_count = "${var.kibana_conf["capacity_desired"]}"
    deployment_minimum_healthy_percent = 50
    deployment_maximum_percent = 100

    load_balancer {
        elb_name = "${aws_elb.kibana-elb.id}"
        container_name = "nginx"
        container_port = 443
    }
}
