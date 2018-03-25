# Vault and Consul
The module and scripts in this folder are from Hashicorp's GitHub repository -
[terraform-aws-vault](https://github.com/hashicorp/terraform-aws-vault).

[Vault](https://www.vaultproject.io/intro/index.html) is used to manage secrets;
[Consul](https://www.consul.io/intro/index.html) as a storage back end.

## Instructions
First you will generate a Certificate Authority (CA) public key and the public and private keys of a TLS certificate
signed by this CA. As this is a private cluster, there's no need to get the keys from a commercial CA. The
keys generated here are to be baked into the
[Amazon Machine Images (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) created in
[vault-consul](https://github.com/mfabriczy/terraform-moodle/tree/master/packer/vault-consul) using
[Packer](https://www.packer.io/intro/index.html).

1. Open `variables.tf` and fill in the variables that do not have a default.

1. DO NOT configure Terraform remote state storage for this code. You do NOT want to store the state files as they 
   will contain the private keys for the certificates.

1. Run `terraform apply`. The output will show you the paths to the generated files:

    ```
    Outputs:
    
    ca_public_key_file_path = ca.key.pem
    private_key_file_path = vault.key.pem
    public_key_file_path = vault.crt.pem
    ```
    
1. Delete your local Terraform state:

    ```
    rm -rf terraform.tfstate*
    ```

   The Terraform state will contain the private keys for the certificates, so it's important to clean it up!

1. To inspect a certificate, you can use OpenSSL:

    ```
    openssl x509 -inform pem -noout -text -in vault.crt.pem
    ```
    
These certificates are used in
[vault-consul](https://github.com/mfabriczy/terraform-moodle/tree/master/packer/vault-consul) Packer template.