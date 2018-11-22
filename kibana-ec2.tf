data "template_file" "kibana-cloudinit" {
  template = "${file("${path.module}/templates/base-cloudinit.yml")}"

  vars {
    ecs_cluster = "${aws_ecs_cluster.kibana-cluster.id}"
  }
}

resource "aws_security_group" "kibana-elb-sg" {
  name = "${var.kibana_conf["service"]}-elb-sg"
  description = "${var.kibana_conf["service"]} ELB security group"

  vpc_id = "${module.vpc.vpc_conf["id"]}"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "${var.peered_vpc_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Environment = "${var.environment}"
    Service = "kibana"
  }
}

resource "aws_elb" "kibana-elb" {
  name = "${var.kibana_conf["service"]}-elb"

  subnets = [
    "${split(",", module.vpc.vpc_conf["subnets_private"])}"]

  security_groups = [
    "${aws_security_group.kibana-elb-sg.id}"
  ]

  listener {
    lb_port = 443
    lb_protocol = "https"
    instance_port = 443
    instance_protocol = "https"
    ssl_certificate_id = "${var.kibana_conf["ssl_certificate_id"]}"
  }

  connection_draining = false
  cross_zone_load_balancing = true
  internal = true

  tags {
    Environment = "${var.environment}"
    Service = "kibana"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "kibana-service-lc" {
  image_id = "${var.aws_ami}"
  instance_type = "${var.kibana_conf["instance_type"]}"

  iam_instance_profile = "${aws_iam_instance_profile.kibana-ecs-instance-profile.arn}"

  security_groups = [
    "${aws_security_group.kibana-cluster-sg.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
    delete_on_termination = true
  }

  user_data = "${data.template_file.kibana-cloudinit.rendered}"

  key_name = "${var.aws_conf["key_name"]}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "kibana-cluster-sg" {
  name = "${var.kibana_conf["service"]}-cluster-sg"
  description = "${var.kibana_conf["service"]}-sg"

  vpc_id = "${module.vpc.vpc_conf["id"]}"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.aws_conf["cidr_block"]}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags {
    Service = "${var.kibana_conf["service"]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kibana-asg" {
  vpc_zone_identifier = [
    "${split(",", module.vpc.vpc_conf["subnets_private"])}"]
  name = "${var.kibana_conf["service"]}-asg"
  max_size = "${var.kibana_conf["capacity_max"]}"
  min_size = "${var.kibana_conf["capacity_min"]}"
  desired_capacity = "${var.kibana_conf["capacity_desired"]}"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.kibana-service-lc.name}"
  load_balancers = [
    "${aws_elb.kibana-elb.id}"]

  tag {
    key                 = "Name"
    value               = "${var.kibana_conf["service"]} ecs container instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = "${var.kibana_conf["service"]}"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = ["desired_capacity"]
  }
}

output "kibana-elb-name" {
  value = "${aws_elb.kibana-elb.dns_name}"
}
