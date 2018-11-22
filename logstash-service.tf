resource "aws_ecs_cluster" "logstash-cluster" {
    name = "${var.logstash_conf["service"]}"
}

data "template_file" "logstash-ecs-task" {
  template = "${file("${path.module}/tasks/logstash-task.json")}"

  vars {
    cluster_name = "${aws_ecs_cluster.logstash-cluster.name}"

    region = "${var.aws_conf["region"]}"
    elastic_url = "${aws_route53_record.elastic-internal-alias.fqdn}"

    docker_image = "${var.logstash_conf["docker_image"]}"

    logstash_cpu = "${var.logstash_conf["logstash_cpu"]}"
    logstash_memory = "${var.logstash_conf["logstash_memory"]}"

    logstash_password = "${var.logstash_conf["logstash_password"]}"

    log_group = "${aws_cloudwatch_log_group.elk-cwl-log-group.name}"
    stream_prefix = "awslogs-${var.logstash_conf["service"]}"
//  temporary override:
//    kinesis_stream_name = "${aws_kinesis_stream.elk_kinesis.name}"
    kinesis_stream_name = "webops-elk-kinesis"
  }
}

resource "aws_ecs_task_definition" "logstash-ecs-task-definition" {
    family = "${var.logstash_conf["service"]}"
    container_definitions = "${data.template_file.logstash-ecs-task.rendered}"
}

resource "aws_ecs_service" "logstash-ecs-service" {
    name = "${var.logstash_conf["service"]}-service"
    cluster = "${aws_ecs_cluster.logstash-cluster.id}"
    task_definition = "${aws_ecs_task_definition.logstash-ecs-task-definition.arn}"
    #iam_role = "${aws_iam_role.logstash-ecs-instance-role.id}"
    desired_count = "${var.logstash_conf["capacity_desired"]}"
    deployment_minimum_healthy_percent = 50
    deployment_maximum_percent = 100

    lifecycle {
        ignore_changes = ["desired_count"]
    }
}
