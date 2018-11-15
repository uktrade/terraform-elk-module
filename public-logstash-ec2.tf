data "template_file" "public_logstash-cloudinit" {
  template = "${file("${path.module}/templates/base-cloudinit.yml")}"

  vars {
    ecs_cluster = "${aws_ecs_cluster.public_logstash-cluster.id}"
  }
}

resource "aws_security_group" "public_logstash-elb-sg" {
  name = "${var.public_logstash_conf["service"]}-elb-sg"
  description = "${var.public_logstash_conf["service"]} ELB security group"

  vpc_id = "${module.vpc.vpc_conf["id"]}"

  ingress {
    from_port = 3332
    to_port = 3332
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Environment = "${var.environment}"
    Service = "public-logstash"
  }
}

resource "aws_elb" "public_logstash-elb" {
  name = "${var.public_logstash_conf["service"]}-elb"
  subnets = [
    "${split(",", module.vpc.vpc_conf["subnets_public"])}"]

  security_groups = [
    "${aws_security_group.public_logstash-elb-sg.id}"
  ]

  listener {
    lb_port = 3332
    lb_protocol = "https"
    instance_port = 3332
    instance_protocol = "https"
    ssl_certificate_id = "${var.public_logstash_conf["ssl_certificate_id"]}"
  }

  connection_draining = false
  cross_zone_load_balancing = true
  internal = false

  tags {
    Environment = "${var.environment}"
    Service = "logstash"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "public_logstash-service-lc" {
  image_id = "${var.aws_ami}"
  instance_type = "${var.public_logstash_conf["instance_type"]}"

  iam_instance_profile = "${aws_iam_instance_profile.public_logstash-ecs-instance-profile.arn}"

  security_groups = [
    "${aws_security_group.public_logstash-cluster-sg.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
    delete_on_termination = true
  }

  user_data = "${data.template_file.public_logstash-cloudinit.rendered}"

  key_name = "${var.aws_conf["key_name"]}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "public_logstash-cluster-sg" {
  name = "${var.public_logstash_conf["service"]}-cluster-sg"
  description = "${var.public_logstash_conf["service"]}-sg"

  vpc_id = "${module.vpc.vpc_conf["id"]}"

  ingress {
    from_port = 3332
    to_port = 3332
    protocol = "tcp"
    security_groups = ["${aws_security_group.public_logstash-elb-sg.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags {
    Service = "${var.public_logstash_conf["service"]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "public_logstash-asg" {
  vpc_zone_identifier = [
    "${split(",", module.vpc.vpc_conf["subnets_public"])}"]
  name = "${var.public_logstash_conf["service"]}-asg"
  max_size = "${var.public_logstash_conf["capacity_max"]}"
  min_size = "${var.public_logstash_conf["capacity_min"]}"
  desired_capacity = "${var.public_logstash_conf["capacity_desired"]}"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.public_logstash-service-lc.name}"
  load_balancers = [
    "${aws_elb.public_logstash-elb.id}"]

  tag {
    key                 = "Name"
    value               = "${var.public_logstash_conf["service"]} ecs container instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = "${var.public_logstash_conf["service"]}"
    propagate_at_launch = true
  }
}

output "public_logstash-elb-name" {
  value = "${aws_elb.public_logstash-elb.dns_name}"
}
