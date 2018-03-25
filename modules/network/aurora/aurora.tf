variable "subnet_private_ids" {
  type = "list"
}

variable "rds_aurora_name" {}
variable "rds_aurora_instance_size" {}
variable "rds_aurora_allocated_storage" {}
variable "rds_aurora_engine_version" {}
variable "rds_aurora_db_name" {}
variable "rds_aurora_user_name" {}
variable "rds_aurora_password" {}
variable "rds_aurora_port" {}
variable "rds_aurora_family" {}
variable "rds_aurora_maintenance_window" {}
variable "rds_aurora_backup_window" {}
variable "rds_aurora_monitoring_interval" {}
variable "sg_rds_aurora_id" {}
variable "environment" {}
variable "hosted_zone_id" {}

module "rds_postgres_moodle" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.rds_aurora_name}"

  engine            = "postgres"
  engine_version    = "${var.rds_aurora_engine_version}"
  instance_class    = "${var.rds_aurora_instance_size}"
  allocated_storage = "${var.rds_aurora_allocated_storage}"

  name     = "${var.rds_aurora_db_name}"
  username = "${var.rds_aurora_user_name}"
  password = "${var.rds_aurora_password}"
  port     = "${var.rds_aurora_port}"

  vpc_security_group_ids = ["${var.sg_rds_aurora_id}"]

  maintenance_window = "${var.rds_aurora_maintenance_window}"
  backup_window      = "${var.rds_aurora_backup_window}"

  # Enhanced Monitoring
  monitoring_interval    = "${var.rds_aurora_monitoring_interval}"
  create_monitoring_role = true

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
  }

  subnet_ids = ["${element(var.subnet_private_ids, 0)}", "${element(var.subnet_private_ids, 1)}"]

  family = "${var.rds_aurora_family}"
}

resource "aws_route53_record" "aurora_endpoint" {
  name    = "moodle.mfabriczy.com"
  zone_id = "${var.hosted_zone_id}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${module.rds_postgres_moodle.this_db_instance_endpoint}"]
}

# This is declared for Terraform to wait for the creation of the RDS instance before creating the Consul cluster.
output "rds_db_instance_address" {
  value = "${module.rds_postgres_moodle.this_db_instance_address}"
}
