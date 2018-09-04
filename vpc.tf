module "vpc" {
  source="git::https://github.com/uktrade/terraform-module-aws-vpc/?ref=10ac78df2d8200777a4495b6a3290c3356fb2013"
  aws_conf = "${var.aws_conf}"
}

