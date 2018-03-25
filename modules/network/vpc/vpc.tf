variable "name" {}
variable "vpc_cidr" {}
variable "azs" {}
variable "private_subnets" {}
variable "public_subnets" {}
variable "environment" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-${var.name}"
  cidr = "${var.vpc_cidr}"

  azs             = ["${element(split(",", var.azs), 0)}", "${element(split(",", var.azs), 1)}", "${element(split(",", var.azs), 2)}"]
  private_subnets = ["${element(split(",", var.private_subnets), 0)}", "${element(split(",", var.private_subnets), 1)}", "${element(split(",", var.private_subnets), 2)}"]
  public_subnets  = ["${element(split(",", var.public_subnets), 0)}", "${element(split(",", var.public_subnets), 1)}", "${element(split(",", var.public_subnets), 2)}"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "subnet_public_ids" {
  value = "${module.vpc.public_subnets}"
}

output "subnet_private_ids" {
  value = "${module.vpc.private_subnets}"
}
