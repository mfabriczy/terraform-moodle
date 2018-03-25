#!/bin/bash

# Allows Moodle EC2 instance(s) to retrieve a Vault token and nonce; the retrieved is stored within the instance. This
# script is to be periodically executed in order to rotate the token.

token_path=/var/token
nonce_path=/var/nonce
domain=vault.service.consul

role=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)

# If curl pkcs7 fails, exit with error logged
token_exists () {
  if [ -f $token_path ]; then
    return 0
  else
    return 1
  fi
}

token_is_valid () {
  # https://www.vaultproject.io/api/auth/token/index.html#lookup-a-token-self-
  echo "Checking token validity"
  token_lookup=$(curl \
       -X GET \
       -H "X-Vault-Token: $(cat $token_path)" \
       -w %{http_code} \
       -s \
       -o /dev/null \
       https://$domain:8200/v1/auth/token/lookup-self)
  if [ "$token_lookup" == "200" ]; then
    echo "Valid token found, exiting."
    return 0
  else
    echo "Invalid token found"
    return 1
  fi
}

aws_login () {
  pkcs7=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7 | tr -d '\n')

  if [ -z "$1" ]; then
    # Do not load nonce if initial login
    login_payload=$(cat <<EOF
    {
      "role": "${role}",
      "pkcs7": "${pkcs7}"
    }
EOF
)
  else
    # Load nonce in payload for reauthentication
    login_payload=$(cat <<EOF
    {
      "role": "${role}",
      "pkcs7": "${pkcs7}",
      "nonce": "$1"
    }
EOF
)
  fi

curl \
  -s \
  -X POST \
  -d "${login_payload}" \
  https://$domain:8200/v1/auth/aws/login | tee \
  >(jq -r .auth.client_token > $token_path) \
  >(jq -r .auth.metadata.nonce > $nonce_path)
}

if ! token_exists; then
  aws_login ""
elif token_exists && ! token_is_valid; then
  aws_login "$(cat $nonce_path)"
else
  logger $0 'current vault token is still valid'
  exit 0
fi