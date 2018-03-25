variable "name" {}
variable "aws_region" {}
variable "vpc_cidr" {}
variable "azs" {}
variable "private_subnets" {}
variable "public_subnets" {}
variable "hosted_zone_id" {}

variable "bastion_ami_id" {}
variable "bastion_ssh_key_name" {}
variable "bastion_min" {}
variable "bastion_max" {}
variable "bastion_desired" {}
variable "bastion_root_volume_size" {}
variable "bastion_root_volume_type" {}

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

variable "certificate_arn" {}
variable "region_alb_account_id" {}

variable "vault_consul_ami_id" {}
variable "vault_cluster_size" {}
variable "vault_instance_type" {}

variable "consul_cluster_size" {}
variable "consul_instance_type" {}
variable "consul_cluster_join_key" {}
variable "consul_cluster_join_value" {}

variable "environment" {}

# ----------------------------------------------------------------------------------------------------------------------
# VPC and Subnets
# ----------------------------------------------------------------------------------------------------------------------
module "vpc" {
  source = "./vpc"

  name            = "${var.name}-vpc"
  vpc_cidr        = "${var.vpc_cidr}"
  azs             = "${var.azs}"
  private_subnets = "${var.private_subnets}"
  public_subnets  = "${var.public_subnets}"
  environment     = "${var.environment}"
}

output "subnet_public_ids" {
  value = "${module.vpc.subnet_public_ids}"
}

# ----------------------------------------------------------------------------------------------------------------------
# Security Groups
# ----------------------------------------------------------------------------------------------------------------------
module "security_groups" {
  source = "./security_groups"

  vpc_id                    = "${module.vpc.vpc_id}"
  public_subnet_cidr_ranges = "${var.public_subnets}"
}

output "sg_http_id" {
  value = "${module.security_groups.sg_http_id}"
}

# ----------------------------------------------------------------------------------------------------------------------
# Bastion
# ----------------------------------------------------------------------------------------------------------------------
module "bastion" {
  source = "./bastion"

  name                     = "${var.name}"
  bastion_ami_id           = "${var.bastion_ami_id}"
  public_subnet_ids        = "${module.vpc.subnet_public_ids}"
  sg_rds_bastion_id        = "${module.security_groups.sg_rds_bastion_id}"
  bastion_ssh_key_name     = "${var.bastion_ssh_key_name}"
  bastion_min              = "${var.bastion_min}"
  bastion_max              = "${var.bastion_max}"
  bastion_desired          = "${var.bastion_desired}"
  bastion_root_volume_size = "${var.bastion_root_volume_size}"
  bastion_root_volume_type = "${var.bastion_root_volume_type}"
  environment              = "${var.environment}"
}

# ----------------------------------------------------------------------------------------------------------------------
# Amazon Aurora
# ----------------------------------------------------------------------------------------------------------------------
module "rds_aurora" {
  source = "./aurora"

  subnet_private_ids             = "${module.vpc.subnet_private_ids}"
  rds_aurora_name                = "${var.rds_aurora_name}"
  rds_aurora_instance_size       = "${var.rds_aurora_instance_size}"
  rds_aurora_allocated_storage   = "${var.rds_aurora_allocated_storage}"
  rds_aurora_engine_version      = "${var.rds_aurora_engine_version}"
  rds_aurora_db_name             = "${var.rds_aurora_db_name}"
  rds_aurora_user_name           = "${var.rds_aurora_user_name}"
  rds_aurora_password            = "${var.rds_aurora_password}"
  rds_aurora_port                = "${var.rds_aurora_port}"
  rds_aurora_family              = "${var.rds_aurora_family}"
  rds_aurora_maintenance_window  = "${var.rds_aurora_maintenance_window}"
  rds_aurora_backup_window       = "${var.rds_aurora_backup_window}"
  rds_aurora_monitoring_interval = "${var.rds_aurora_monitoring_interval}"
  sg_rds_aurora_id               = "${module.security_groups.sg_rds_aurora_postgres_id}"
  environment                    = "${var.environment}"
  hosted_zone_id                 = "${var.hosted_zone_id}"
}

# ----------------------------------------------------------------------------------------------------------------------
# Application Load Balancer
# ----------------------------------------------------------------------------------------------------------------------
module "alb" {
  source = "./alb"

  vpc_id                = "${module.vpc.vpc_id}"
  name                  = "${var.name}"
  subnet_public_ids     = "${module.vpc.subnet_public_ids}"
  sg_http_id            = "${module.security_groups.sg_http_id}"
  certificate_arn       = "${var.certificate_arn}"
  region_alb_account_id = "${var.region_alb_account_id}"
  environment           = "${var.environment}"
}

output "tg_http_arn" {
  value = "${module.alb.tg_http_arn}"
}

output "alb_mdl_zone_id" {
  value = "${module.alb.alb_mdl_zone_id}"
}

output "alb_mdl_dns_name" {
  value = "${module.alb.alb_mdl_dns_name}"
}

# ----------------------------------------------------------------------------------------------------------------------
# Consul
# ----------------------------------------------------------------------------------------------------------------------
module "consul" {
  source = "./consul"

  name                      = "${var.name}"
  vpc_id                    = "${module.vpc.vpc_id}"
  subnet_ids                = "${module.vpc.subnet_public_ids}"              // TODO: Private
  consul_ami_id             = "${var.vault_consul_ami_id}"
  consul_cluster_size       = "${var.consul_cluster_size}"
  consul_instance_type      = "${var.consul_instance_type}"
  consul_cluster_join_key   = "${var.consul_cluster_join_key}"
  consul_cluster_join_value = "${var.consul_cluster_join_value}"
  depends_on_rds            = "${module.rds_aurora.rds_db_instance_address}"
}

output "iam_instance_profile_consul_id" {
  value = "${module.consul.iam_instance_profile_consul_id}"
}

output "tf_user_data_moodle_consul_rendered" {
  value = "${module.consul.tf_user_data_consul_moodle_rendered}"
}

# ----------------------------------------------------------------------------------------------------------------------
# Vault
# ----------------------------------------------------------------------------------------------------------------------
module "vault" {
  source = "./vault"

  name                      = "${var.name}"
  aws_region                = "${var.aws_region}"
  vpc_id                    = "${module.vpc.vpc_id}"
  subnet_ids                = "${module.vpc.subnet_public_ids}"
  vault_ami_id              = "${var.vault_consul_ami_id}"
  vault_cluster_size        = "${var.vault_cluster_size}"
  vault_instance_type       = "${var.vault_instance_type}"
  consul_cluster_join_key   = "${var.consul_cluster_join_key}"
  consul_cluster_join_value = "${var.consul_cluster_join_value}"
}