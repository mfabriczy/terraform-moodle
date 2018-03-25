variable "name" {}
variable "aws_region" {}
variable "vpc_id" {}

variable "subnet_ids" {
  type = "list"
}

variable "vault_ami_id" {}
variable "vault_cluster_size" {}
variable "vault_instance_type" {}
variable "consul_cluster_join_key" {}
variable "consul_cluster_join_value" {}

# TODO: Add documentation: https://www.vaultproject.io/docs/concepts/seal.html#unsealing
module "vault_cluster" {
  source = "github.com/hashicorp/terraform-aws-vault.git//modules/vault-cluster?ref=v0.6.0"

  cluster_name  = "${var.name}-vault"
  cluster_size  = "${var.vault_cluster_size}"
  instance_type = "${var.vault_instance_type}"

  ami_id    = "${var.vault_ami_id}"
  user_data = "${data.template_file.user_data_vault_cluster.rendered}"

  vpc_id     = "${var.vpc_id}"
  subnet_ids = "${var.subnet_ids}"

  # TODO: To make testing easier, allow requests from any IP address here but in a production deployment, it is *strongly*
  # recommended to limit this to the IP address ranges of known trusted servers inside your VPC.

  allowed_ssh_cidr_blocks            = ["0.0.0.0/0"]
  allowed_inbound_cidr_blocks        = ["0.0.0.0/0"]
  allowed_inbound_security_group_ids = []
  ssh_key_name                       = "id_rsa"
}

module "consul_iam_policies_servers" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.3.3"

  iam_role_id = "${module.vault_cluster.iam_role_id}"
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH VAULT SERVER WHEN IT'S BOOTING
# This script will configure and start Vault
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_vault_cluster" {
  template = "${file("${path.module}/user-data-vault.sh")}"

  vars {
    aws_region               = "${var.aws_region}"
    consul_cluster_tag_key   = "${var.consul_cluster_join_key}"
    consul_cluster_tag_value = "${var.consul_cluster_join_value}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PERMIT CONSUL SPECIFIC TRAFFIC IN VAULT CLUSTER
# To allow our Vault servers consul agents to communicate with other consul agents and participate in the LAN gossip,
# we open up the consul specific protocols and ports for consul traffic
# ---------------------------------------------------------------------------------------------------------------------

module "security_group_rules" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-client-security-group-rules?ref=v0.3.3"

  security_group_id = "${module.vault_cluster.security_group_id}"

  # TODO: To make testing easier, we allow requests from any IP address here but in a production deployment, we *strongly*
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.

  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
}
