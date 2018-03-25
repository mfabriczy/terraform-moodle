variable "vpc_id" {}
variable "public_subnet_cidr_ranges" {}

// TODO: Insert the argument "version" into all modules from the Module Registry for stability.
module "sg_http" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "http-sg"
  description = "Allow HTTP(S) traffic"
  vpc_id      = "${var.vpc_id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]

  // TODO: Remove ssh-tcp
  ingress_rules = ["http-80-tcp", "https-443-tcp", "consul-serf-lan-tcp"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 8200
      to_port     = 8200
      protocol    = "tcp"
      description = "Vault"
      cidr_blocks = "10.10.0.0/16" // TODO: Variable
    },
  ]

  egress_rules = ["all-all"]
}

module "sg_rds_aurora" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "postgres-sg"
  description = "Security group for RDS instance"
  vpc_id      = "${var.vpc_id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]      // TODO: Variable
  ingress_rules       = ["postgresql-tcp"]

  // TODO: Needed?
  egress_rules = ["all-all"]
}

module "sg_rds_bastion" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "db-bastion-sg"
  description = "Allow inbound SSH traffic from Bastions"
  vpc_id      = "${var.vpc_id}"

  // TODO: Test forwarding/proxy works with RDS. Test outside these CIDR ranges.
  ingress_cidr_blocks = ["${element(split(",", var.public_subnet_cidr_ranges), 0)}", "${element(split(",", var.public_subnet_cidr_ranges), 1)}", "${element(split(",", var.public_subnet_cidr_ranges), 2)}"]
  ingress_rules       = ["ssh-tcp"]

  egress_rules = ["all-all"]
}

output "sg_http_id" {
  value = "${module.sg_http.this_security_group_id}"
}

output "sg_rds_aurora_postgres_id" {
  value = "${module.sg_rds_aurora.this_security_group_id}"
}

output "sg_rds_bastion_id" {
  value = "${module.sg_rds_bastion.this_security_group_id}"
}
