resource "aws_ecs_cluster" "elastic-cluster" {
  name = "${var.elastic_conf["service"]}"
}

data "template_file" "elastic-ecs-task" {
  template = "${file("${path.module}/tasks/elastic-task.json")}"

  vars {
    cluster_name = "${aws_ecs_cluster.elastic-cluster.name}"
    log_group = "${var.aws_conf["log_group"]}"
    region = "${var.aws_conf["region"]}"
    elastic_username = "${var.elastic_conf["elastic_username"]}"
    elastic_password = "${var.elastic_conf["elastic_password"]}"
    cluster_security_group = "${var.elastic_conf["service"]}-cluster-sg"
    docker_image = "${var.elastic_conf["docker_image"]}"
    elastic_cpu = "${var.elastic_conf["elastic_cpu"]}"
    elastic_memory = "${var.elastic_conf["elastic_memory"]}"

    log_group = "${aws_cloudwatch_log_group.elk-cwl-log-group.name}"
    stream_prefix = "awslogs-${var.elastic_conf["service"]}"

    es_ssl_key = "${var.elastic_conf["es_ssl_key"]}"
    es_ssl_cert = "${var.elastic_conf["es_ssl_cert"]}"
    es_ssl_ca = "${var.elastic_conf["es_ssl_ca"]}"
  }
}

resource "aws_ecs_task_definition" "elastic-ecs-task-definition" {
  family = "${var.elastic_conf["service"]}"
  container_definitions = "${data.template_file.elastic-ecs-task.rendered}"

  volume {
    name = "data"
        host_path = "/ecs/es-data"
  }
}

resource "aws_ecs_service" "elastic-ecs-service" {
  name = "${var.elastic_conf["service"]}-service"
  cluster = "${aws_ecs_cluster.elastic-cluster.id}"
  task_definition = "${aws_ecs_task_definition.elastic-ecs-task-definition.arn}"
  iam_role = "${aws_iam_role.elastic-ecs-instance-role.id}"
  desired_count = "${var.elastic_conf["capacity_desired"]}"
  deployment_minimum_healthy_percent = 66
  deployment_maximum_percent = 100

  load_balancer {
    elb_name = "${aws_elb.elastic-elb.id}"
    container_name = "elasticsearch"
    container_port = 9200
  }
}
