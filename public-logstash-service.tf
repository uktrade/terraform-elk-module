resource "aws_ecs_cluster" "public_logstash-cluster" {
    name = "${var.public_logstash_conf["service"]}"
}

data "template_file" "public_logstash-ecs-task" {
  template = "${file("${path.module}/tasks/public-logstash-task.json")}"

  vars {
    cluster_name = "${aws_ecs_cluster.public_logstash-cluster.name}"

    region = "${var.aws_conf["region"]}"
    elastic_url = "${aws_elb.elastic-elb.dns_name}"

    docker_image = "${var.public_logstash_conf["docker_image"]}"

    logstash_cpu = "${var.public_logstash_conf["logstash_cpu"]}"
    logstash_memory = "${var.public_logstash_conf["logstash_memory"]}"

    logstash_password = "${var.public_logstash_conf["logstash_password"]}"

    log_group = "${aws_cloudwatch_log_group.elk-cwl-log-group.name}"
    stream_prefix = "awslogs-${var.public_logstash_conf["service"]}"
    kinesis_stream_name = "${aws_kinesis_stream.elk_kinesis.name}"
  }
}

resource "aws_ecs_task_definition" "public_logstash-ecs-task-definition" {
    family = "${var.public_logstash_conf["service"]}"
    container_definitions = "${data.template_file.public_logstash-ecs-task.rendered}"
}

resource "aws_ecs_service" "public_logstash-ecs-service" {
    name = "${var.public_logstash_conf["service"]}-service"
    cluster = "${aws_ecs_cluster.public_logstash-cluster.id}"
    task_definition = "${aws_ecs_task_definition.public_logstash-ecs-task-definition.arn}"
    iam_role = "${aws_iam_role.public_logstash-ecs-instance-role.id}"
    desired_count = "${var.public_logstash_conf["capacity_desired"]}"
    deployment_minimum_healthy_percent = 50
    deployment_maximum_percent = 100


    load_balancer {
        elb_name = "${aws_elb.public_logstash-elb.id}"
        container_name = "logstash"
        container_port = 3332
    }
}
