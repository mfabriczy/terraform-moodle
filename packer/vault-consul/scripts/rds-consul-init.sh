#!/bin/bash

# When the Terraform stack is initialised with a Consul cluster, this script will retrieve the details of the RDS
# instance and store them within Consul's KV store for the Moodle EC2 instance(s) to consume.

# TODO: https://gist.github.com/jkordish/95bd29084ec2907cf60697ccfc66e553

not_exist_message () {
    echo "The database $1 has not been stored in Consul. Storing the value retrieved from the describe-db-instances AWS CLI call."
}

rdsendpoint=$(consul kv get moodle/rds/endpoint)
rdsdbname=$(consul kv get moodle/rds/dbname)
rdsusername=$(consul kv get moodle/rds/username)

if [ -z "$rdsendpoint" ] || [ -z "$rdsdbname" ] || [ -z "$rdsusername" ]; then
  dbinstance=$(aws rds describe-db-instances --db-instance-identifier moodle-rds-aurora --region ap-southeast-2 | jq -r '.[][]')
fi

if [ -z "$rdsendpoint" ]; then
  not_exist_message "endpoint"
  consul kv put moodle/rds/endpoint "$(echo $dbinstance | jq .Endpoint.Address)"
fi

if [ -z "$rdsdbname" ]; then
  not_exist_message "name"
  consul kv put moodle/rds/dbname "$(echo $dbinstance | jq .DBName)"
fi

if [[ -z "$rdsusername" ]]; then
  not_exist_message "username"
  consul kv put moodle/rds/username "$(echo $dbinstance | jq .MasterUsername)"
fi