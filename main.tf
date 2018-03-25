provider "aws" {
  access_key = "${var.AWS_ACCESS_KEY_ID}"
  secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
  region     = "${var.aws_region}"
}

module "network" {
  source = "./modules/network"

  name                     = "${var.name}"
  aws_region               = "${var.aws_region}"
  vpc_cidr                 = "${var.vpc_cidr}"
  certificate_arn          = "${var.certificate_arn}"
  region_alb_account_id    = "${var.region_alb_account_id}"
  azs                      = "${var.availability_zones}"
  private_subnets          = "${var.private_subnets_cidr}"
  public_subnets           = "${var.public_subnets_cidr}"
  hosted_zone_id           = "${var.hosted_zone_id}"
  bastion_ami_id           = "${data.aws_ami.ubuntu.id}"
  bastion_ssh_key_name     = "${aws_key_pair.bastion.key_name}"
  bastion_min              = "${var.bastion_min}"
  bastion_max              = "${var.bastion_max}"
  bastion_desired          = "${var.bastion_desired}"
  bastion_root_volume_size = "${var.bastion_root_volume_size}"
  bastion_root_volume_type = "${var.bastion_root_volume_type}"

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

  vault_consul_ami_id = "${var.vault_consul_ami_id}"

  vault_cluster_size  = "${var.vault_cluster_size}"
  vault_instance_type = "${var.vault_instance_type}"

  consul_cluster_size       = "${var.consul_cluster_size}"
  consul_instance_type      = "${var.consul_instance_type}"
  consul_cluster_join_key   = "${var.consul_cluster_join_key}"
  consul_cluster_join_value = "${var.consul_cluster_join_value}"

  environment = "${var.environment}"
}

module "asg_public_web_moodle" {
  source = "terraform-aws-modules/autoscaling/aws"

  // TODO: Use count
  name = "${var.name}-web"

  # Launch configuration
  lc_name = "lc-${var.name}"

  image_id             = "${var.moodle_ami}"
  instance_type        = "${var.moodle_instance_type}"
  security_groups      = ["${module.network.sg_http_id}"]
  iam_instance_profile = "${module.network.iam_instance_profile_consul_id}"
  key_name             = "id_rsa"                                           // TODO: Remove after

  root_block_device = [
    {
      volume_size = "${var.bastion_root_volume_size}"
      volume_type = "${var.bastion_root_volume_type}"
    },
  ]

  # Auto scaling group
  asg_name = "asg-public-${var.name}"

  vpc_zone_identifier = ["${element(module.network.subnet_public_ids, 0)}", "${element(module.network.subnet_public_ids, 1)}",
    "${element(module.network.subnet_public_ids, 2)}",
  ]

  health_check_type = "EC2"
  min_size          = "${var.moodle_min}"
  max_size          = "${var.moodle_max}"
  desired_capacity  = "${var.moodle_desired}"

  target_group_arns = ["${module.network.tg_http_arn}"]

  user_data = "${module.network.tf_user_data_moodle_consul_rendered}"
  tags = [
    {
      key                 = "Terraform"
      value               = "true"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
  ]
}

resource "aws_key_pair" "bastion" {
  key_name   = "${var.name}"
  public_key = "${file("${var.bastion_public_key_path}")}"
}
