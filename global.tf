resource "aws_route53_record" "alb_record" {
  name    = ""
  zone_id = "${var.hosted_zone_id}"
  type    = "A"

  alias {
    name                   = "${module.network.alb_mdl_dns_name}"
    zone_id                = "${module.network.alb_mdl_zone_id}"
    evaluate_target_health = true
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}
