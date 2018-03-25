variable "name" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "bastion_ami_id" {}
variable "bastion_ssh_key_name" {}
variable "sg_rds_bastion_id" {}
variable "bastion_min" {}
variable "bastion_max" {}
variable "bastion_desired" {}
variable "bastion_root_volume_size" {}
variable "bastion_root_volume_type" {}
variable "environment" {}

module "bastion" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "${var.name}-bastion"

  # Launch configuration
  lc_name = "lc-${var.name}"

  image_id        = "${var.bastion_ami_id}"
  instance_type   = "t2.micro"
  security_groups = ["${var.sg_rds_bastion_id}"]
  key_name        = "${var.bastion_ssh_key_name}"

  root_block_device = [
    {
      volume_size = "${var.bastion_root_volume_size}"
      volume_type = "${var.bastion_root_volume_type}"
    },
  ]

  # Auto scaling group
  asg_name                  = "asg-bastion-${var.name}"
  vpc_zone_identifier       = ["${element(var.public_subnet_ids, 0)}", "${element(var.public_subnet_ids, 1)}"]
  health_check_type         = "EC2"
  min_size                  = "${var.bastion_min}"
  max_size                  = "${var.bastion_max}"
  desired_capacity          = "${var.bastion_desired}"
  wait_for_capacity_timeout = 0

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
