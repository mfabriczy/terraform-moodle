variable "vpc_id" {}
variable "name" {}

variable "subnet_public_ids" {
  type = "list"
}

variable "sg_http_id" {}
variable "certificate_arn" {}
variable "region_alb_account_id" {}
variable "environment" {}

resource "aws_s3_bucket" "s3_alb_logs" {
  bucket = "s3-alb-logs-${var.name}"

  policy = <<EOF
{
  "Id": "Policy1521353710343",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1521353704574",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::s3-alb-logs-${var.name}/*",
      "Principal": {
        "AWS": [
          "${var.region_alb_account_id}"
        ]
      }
    }
  ]
}
EOF

  tags {
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}

resource "aws_alb" "alb_mdl" {
  name            = "alb-${var.name}"
  security_groups = ["${var.sg_http_id}"]
  subnets         = ["${element(var.subnet_public_ids, 0)}", "${element(var.subnet_public_ids, 1)}", "${element(var.subnet_public_ids, 2)}"]

  access_logs {
    bucket  = "${aws_s3_bucket.s3_alb_logs.bucket}"
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.alb_mdl.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.tg_http.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = "${aws_alb.alb_mdl.arn}"
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${var.certificate_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.tg_http.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "tg_http" {
  name     = "alb-http-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    port = 80
    path = "/health"
  }

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}

output "tg_http_arn" {
  value = "${aws_alb_target_group.tg_http.arn}"
}

output "alb_mdl_zone_id" {
  value = "${aws_alb.alb_mdl.zone_id}"
}

output "alb_mdl_dns_name" {
  value = "${aws_alb.alb_mdl.dns_name}"
}
