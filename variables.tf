data "aws_availability_zones" "vpc_az" {
  state = "available"
}

data "aws_caller_identity" "current" {}

variable "aws_conf" {
  type = "map"
  default = {}
}

variable "elastic_conf" {
  type = "map"
}

variable "logstash_conf" {
  type = "map"
}

variable "public_logstash_conf" {
  type = "map"
}

variable "kibana_conf" {
  type = "map"
}

variable "curator_conf" {
  type = "map"
}

variable "aws_ami" {}
variable "environment" {}
variable "service" {}

variable "cwl_retention_in_days" {}

variable "peered_vpc_cidr" {}

variable "additional_kinesis_arn" {}
variable "cross_account_to_kinesis_source_account_ids" {
  type = "list"
}
