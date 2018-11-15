data "template_file" "logstash-cloudinit" {
  template = "${file("${path.module}/templates/base-cloudinit.yml")}"

  vars {
    ecs_cluster = "${aws_ecs_cluster.logstash-cluster.id}"
  }
}

resource "aws_launch_configuration" "logstash-service-lc" {
  image_id = "${var.aws_ami}"
  instance_type = "${var.logstash_conf["instance_type"]}"

  iam_instance_profile = "${aws_iam_instance_profile.logstash-ecs-instance-profile.arn}"

  security_groups = [
    "${aws_security_group.logstash-cluster-sg.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
    delete_on_termination = true
  }

  user_data = "${data.template_file.logstash-cloudinit.rendered}"

  key_name = "${var.aws_conf["key_name"]}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "logstash-cluster-sg" {
  name = "${var.logstash_conf["service"]}-cluster-sg"
  description = "${var.logstash_conf["service"]}-sg"

  vpc_id = "${module.vpc.vpc_conf["id"]}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags {
    Service = "${var.logstash_conf["service"]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "logstash-asg" {
  vpc_zone_identifier = [
    "${split(",", module.vpc.vpc_conf["subnets_private"])}"]
  name = "${var.logstash_conf["service"]}-asg"
  max_size = "${var.logstash_conf["capacity_max"]}"
  min_size = "${var.logstash_conf["capacity_min"]}"
  desired_capacity = "${var.logstash_conf["capacity_desired"]}"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.logstash-service-lc.name}"

  tag {
    key                 = "Name"
    value               = "${var.logstash_conf["service"]} ecs container instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = "${var.logstash_conf["service"]}"
    propagate_at_launch = true
  }
}
