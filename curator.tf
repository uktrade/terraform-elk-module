//# This task is set up to run on the kibana cluster
//
//data "template_file" "curator-ecs-task" {
//  template = "${file("${path.module}/tasks/curator-task.json")}"
//
//  vars {
//    cluster_name = "${aws_ecs_cluster.kibana-cluster.name}"
//    log_group = "${var.aws_conf["log_group"]}"
//    region = "${var.aws_conf["region"]}"
//    elastic_url = "${aws_elb.elastic-elb.dns_name}"
//    elastic_username = "${var.elastic_conf["elastic_username"]}"
//    elastic_password = "${var.elastic_conf["elastic_password"]}"
//    cluster_security_group = "${var.kibana_conf["service"]}-cluster-sg"
//    repository_url = "${aws_ecr_repository.elk-ecr-curator.repository_url}"
//    curator_cpu = "${var.curator_conf["cpu"]}"
//    curator_memory = "${var.curator_conf["memory"]}"
//
//    log_group = "${aws_cloudwatch_log_group.elk-cwl-log-group.name}"
//    stream_prefix = "awslogs-${var.elastic_conf["service"]}"
//  }
//}
//
//resource "aws_ecs_task_definition" "curator-ecs-task-definition" {
//    family = "${var.kibana_conf["service"]}"
//    container_definitions = "${data.template_file.curator-ecs-task.rendered}"
//}
