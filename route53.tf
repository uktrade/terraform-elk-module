// -----
// Private hosted zone
// -----

resource "aws_route53_zone" "elastic-private-zone" {
  name = "${var.elastic_conf["internal_hosted_zone"]}"
  vpc_id = "${module.vpc.vpc_conf["id"]}"
}

resource "aws_route53_record" "elastic-internal-alias" {
  zone_id = "${aws_route53_zone.elastic-private-zone.zone_id}"
  name    = "es.${var.elastic_conf["internal_hosted_zone"]}"
  type    = "A"

  alias {
    name                   = "${aws_elb.elastic-elb.dns_name}"
    zone_id                = "${aws_elb.elastic-elb.zone_id}"
    evaluate_target_health = false
  }
}
