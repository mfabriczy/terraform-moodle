# terraform-moodle

Creates a Multi-AZ AWS cluster running Moodle using Terraform.

The following stack is used:
* Ubuntu 16.04
* Nginx
* [Amazon Aurora](https://aws.amazon.com/rds/aurora/)
* PHP

Additionally, [Vault](https://www.vaultproject.io/intro/index.html) is used to handle secrets, with
[Consul](https://www.consul.io/intro/index.html) used as a storage
back end, and for service discovery.

## Instructions
1. Fill in the required fields in `variables.tf`

1. Vault and Consul needs to be prepared. Create the CA public and private keys to be used in Vault and Consul in the
[private-tls-cert](https://github.com/mfabriczy/terraform-moodle/tree/master/modules/vault-consul/private-tls-cert)
module.

1. Now, bake in the keys created in the above step into a
[Amazon Machine Images (AMIs)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) via
[Packer](https://www.packer.io/intro/index.html) using the `vault-consul.json` template in the
[vault-consul](https://github.com/mfabriczy/terraform-moodle/tree/master/packer/vault-consul) module.

Work in progress...