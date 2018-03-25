# Vault and Consul AMI

Creates an [Amazon Machine Images (AMIs)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) which installs
Vault and Consul.

## Instructions
1. Add the paths of the generated keys from the
[private-tls-cert](https://github.com/mfabriczy/terraform-moodle/tree/master/modules/vault-consul/private-tls-cert)
module to the variables fields in `vault-consul.json` template:
```
"ca_public_key_path": "ca.crt.pem",
"tls_public_key_path": "vault.crt.pem",
"tls_private_key_path": "vault.key.pem"
```
