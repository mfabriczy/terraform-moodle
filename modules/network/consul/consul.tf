variable "name" {}
variable "vpc_id" {}

variable "subnet_ids" {
  type = "list"
}

variable "consul_ami_id" {}
variable "consul_cluster_size" {}
variable "consul_instance_type" {}
variable "consul_cluster_join_key" {}
variable "consul_cluster_join_value" {}

# As there's currently no way to declare module to module dependencies - this will be used as an alternative.
# https://github.com/hashicorp/terraform/issues/1178
variable "depends_on_rds" {}

module "consul_cluster" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-cluster?ref=v0.3.3"

  cluster_name  = "${var.name}-consul"
  cluster_size  = "${var.consul_cluster_size}"
  instance_type = "${var.consul_instance_type}"

  cluster_tag_key   = "${var.consul_cluster_join_key}"
  cluster_tag_value = "${var.consul_cluster_join_value}"

  ami_id    = "${var.consul_ami_id}"
  user_data = "${data.template_file.user_data_consul.rendered}"

  vpc_id     = "${var.vpc_id}"
  subnet_ids = "${var.subnet_ids}" // TODO: Change to be in private subnets

  # TODO: To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.

  allowed_ssh_cidr_blocks     = ["0.0.0.0/0"]
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ssh_key_name                = "id_rsa"      // TODO: Remove later.
  tags = [
    {
      key                 = "depends_on_rds"
      value               = "${var.depends_on_rds}"
      propagate_at_launch = true
    },
  ]
}

module "consul_iam_policies_servers" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.3.3"

  iam_role_id = "${aws_iam_role.consul.id}"
}

resource "aws_iam_role" "consul" {
  name               = "Consul"
  assume_role_policy = "${data.aws_iam_policy_document.consul_assume_role.json}"
  description        = "Allows Moodle to talk with and join the Consul cluster; retrieve and store database credentials."
}

resource aws_iam_instance_profile "consul" {
  name = "Consul"
  role = "${aws_iam_role.consul.name}"
}

data "aws_iam_policy_document" "consul_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "rds_consul" {
  name        = "ConsulRDSDescribeInstances"
  policy      = "${data.aws_iam_policy_document.rds_describe_instances_document.json}"
  description = "Provides access to the RDS instance to retrieve and store the database's credentials."
}

data "aws_iam_policy_document" "rds_describe_instances_document" {
  statement {
    effect = "Allow"

    actions = [
      "rds:DescribeDBInstances",
    ]

    // TODO: For more security make it specific to the RDS instance.
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "rds_consul" {
  role       = "${module.consul_cluster.iam_role_id}"
  policy_arn = "${aws_iam_policy.rds_consul.arn}"
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH CONSUL SERVER WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_consul" {
  template = "${file("${path.module}/user-data-consul.sh")}"

  vars {
    consul_cluster_tag_key   = "${var.consul_cluster_join_key}"
    consul_cluster_tag_value = "${var.consul_cluster_join_value}"
  }
}

output "iam_instance_profile_consul_id" {
  value = "${aws_iam_instance_profile.consul.id}"
}

output "tf_user_data_consul_moodle_rendered" {
  value = "${data.template_file.user_data_consul.rendered}"
}
