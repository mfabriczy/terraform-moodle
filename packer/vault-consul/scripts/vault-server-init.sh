#!/bin/bash

# After Vault has been initialised, this script will configure a role and policy to allow Moodle EC2 instance(s) to talk
# with Vault.

mac=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
vpc_id=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac}/vpc-id)

if [[ -z "${VAULT_TOKEN}" ]]; then
    echo "VAULT_TOKEN variable has not been set."
    exit
fi

# Enable EC2 auth method.
curl
  -X POST
  -H "X-Vault-Token: $VAULT_TOKEN"
  -d '{"type":"aws"}'
  "https://127.0.0.1:8200/v1/sys/auth/aws"

# Setup policy.
curl -X PUT -H "X-Vault-Token: $VAULT_TOKEN" -d @vault-moodle-policy.json https://127.0.0.1:8200/v1/sys/policy/moodle

payload=$(cat <<EOF
{
  "bound_vpc_id":"${vpc_id}",
  "policies":"moodle",
  "max_ttl":"500h",
  "auth_type":"ec2"
}
EOF
)

# Configure the policy on the role.
curl \
  -X POST \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  -d "${payload}" \
  "https://127.0.0.1:8200/v1/auth/aws/role/Consul"