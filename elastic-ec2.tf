data "template_file" "elastic-cloudinit" {
  template = "${file("${path.module}/templates/elastic-cloudinit.yml")}"

  vars {
    ecs_cluster = "${aws_ecs_cluster.elastic-cluster.id}"
  }
}

resource "aws_security_group" "elastic-elb-sg" {
  name = "${var.elastic_conf["service"]}-elb-sg"
  description = "${var.elastic_conf["service"]} ELB security group"

  vpc_id = "${module.vpc.vpc_conf["id"]}"

  ingress {
    from_port = 9200
    to_port = 9200
    protocol = "tcp"
    security_groups = ["${aws_security_group.kibana-cluster-sg.id}", "${aws_security_group.logstash-cluster-sg.id}"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.aws_conf["cidr_block"]}"]
  }

  tags {
    Environment = "${var.environment}"
    Service = "${var.elastic_conf["service"]}"
  }
}

resource "aws_elb" "elastic-elb" {
  name = "${var.elastic_conf["service"]}-elb"
  subnets = [
    "${split(",", module.vpc.vpc_conf["subnets_private"])}"]

  security_groups = [
    "${aws_security_group.elastic-elb-sg.id}"
  ]

  listener {
    lb_port = 9200
    lb_protocol = "https"
    instance_port = 9200
    instance_protocol = "https"
    ssl_certificate_id = "${var.elastic_conf["ssl_certificate_id"]}"
  }

  connection_draining = false
  cross_zone_load_balancing = true
  internal = true

  tags {
    Environment = "${var.environment}"
    Service = "${var.elastic_conf["service"]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "elastic-service-lc" {
  image_id = "${var.aws_ami}"
  instance_type = "${var.elastic_conf["instance_type"]}"

  iam_instance_profile = "${aws_iam_instance_profile.elastic-ecs-instance-profile.arn}"

  security_groups = [
    "${aws_security_group.elastic-cluster-sg.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
    delete_on_termination = true
  }

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = "${var.elastic_conf["ebs_vol_size"]}"
    delete_on_termination = false
    encrypted = true
  }

  user_data = "${data.template_file.elastic-cloudinit.rendered}"

  key_name = "${var.aws_conf["key_name"]}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elastic-cluster-sg" {
  name = "${var.elastic_conf["service"]}-cluster-sg"
  description = "${var.elastic_conf["service"]}-sg"

  vpc_id = "${module.vpc.vpc_conf["id"]}"

  ingress {
    from_port = 9200
    to_port = 9200
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.elastic-elb-sg.id}"]
  }

  ingress {
    from_port = 9300
    to_port = 9300
    protocol = "tcp"
    self = true
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags {
    Service = "${var.elastic_conf["service"]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "elastic-asg" {
  vpc_zone_identifier = [
    "${split(",", module.vpc.vpc_conf["subnets_private"])}"]
  name = "${var.elastic_conf["service"]}-asg"
  max_size = "${var.elastic_conf["capacity_max"]}"
  min_size = "${var.elastic_conf["capacity_min"]}"
  desired_capacity = "${var.elastic_conf["capacity_desired"]}"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.elastic-service-lc.name}"
  load_balancers = [
    "${aws_elb.elastic-elb.id}"]

  tag {
    key                 = "Name"
    value               = "${var.elastic_conf["service"]} ecs container instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = "${var.elastic_conf["service"]}"
    propagate_at_launch = true
  }

  tag {
    key                 = "elastic-instance"
    value               = "true"
    propagate_at_launch = true
  }
}

output "elastic-elb-name" {
  value = "${aws_elb.elastic-elb.dns_name}"
}

