# Shared settings and helpers. Other scripts source this file.
# You can also load it into your shell:  source scripts/env.sh

export AWS_PROFILE="${AWS_PROFILE:-kthw}"
export AWS_REGION="${AWS_REGION:-us-east-2}"

TAG="kubernetes-the-hard-way"
KEY_FILE="${KEY_FILE:-./kubernetes-the-hard-way.id_rsa}"

# Instance ID by Name tag (any non-terminated state)
instance_id() {
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$1" "Name=tag:Project,Values=${TAG}" \
              "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --output text --query 'Reservations[].Instances[].InstanceId'
}

# Public IP of a running instance by Name tag
public_ip() {
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$1" "Name=tag:Project,Values=${TAG}" "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress'
}

# Private IP by Name tag
private_ip() {
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$1" "Name=tag:Project,Values=${TAG}" \
              "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --output text --query 'Reservations[].Instances[].PrivateIpAddress'
}

# All project instance IDs in the given states (comma-separated)
instance_ids_in_state() {
  aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=${TAG}" "Name=instance-state-name,Values=$1" \
    --output text --query 'Reservations[].Instances[].InstanceId'
}

# Resource IDs by Name tag
vpc_id()            { aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${TAG}" --output text --query 'Vpcs[0].VpcId'; }
subnet_id()         { aws ec2 describe-subnets --filters "Name=tag:Name,Values=${TAG}" --output text --query 'Subnets[0].SubnetId'; }
security_group_id() { aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${TAG}" --output text --query 'SecurityGroups[0].GroupId'; }
route_table_id()    { aws ec2 describe-route-tables --filters "Name=tag:Name,Values=${TAG}" --output text --query 'RouteTables[0].RouteTableId'; }
igw_id()            { aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=${TAG}" --output text --query 'InternetGateways[0].InternetGatewayId'; }
