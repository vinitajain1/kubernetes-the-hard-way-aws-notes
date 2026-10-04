#!/usr/bin/env bash
# Delete everything: instances, disks, key pair, security group, route table,
# internet gateway, subnet and VPC. Looks every ID up by tag, so it works in a fresh shell.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

read -r -p "Delete ALL ${TAG} resources in ${AWS_REGION} (profile ${AWS_PROFILE})? Type 'delete' to continue: " ANSWER
[ "${ANSWER}" = "delete" ] || { echo "Cancelled."; exit 1; }

echo "== Instances"
IDS=$(instance_ids_in_state pending,running,stopping,stopped)
if [ -n "${IDS}" ]; then
  aws ec2 terminate-instances --instance-ids ${IDS} --output table --query 'TerminatingInstances[].InstanceId'
  aws ec2 wait instance-terminated --instance-ids ${IDS}
fi
aws ec2 delete-key-pair --key-name "${TAG}" || true

echo "== Networking"
VPC_ID=$(vpc_id); SG_ID=$(security_group_id); RT_ID=$(route_table_id); IGW_ID=$(igw_id); SUBNET_ID=$(subnet_id)

[ "${SG_ID}" != "None" ] && aws ec2 delete-security-group --group-id "${SG_ID}"
if [ "${RT_ID}" != "None" ]; then
  for ASSOC in $(aws ec2 describe-route-tables --route-table-ids "${RT_ID}" \
                   --output text --query 'RouteTables[].Associations[].RouteTableAssociationId'); do
    aws ec2 disassociate-route-table --association-id "${ASSOC}"
  done
  aws ec2 delete-route-table --route-table-id "${RT_ID}"
fi
if [ "${IGW_ID}" != "None" ]; then
  aws ec2 detach-internet-gateway --internet-gateway-id "${IGW_ID}" --vpc-id "${VPC_ID}"
  aws ec2 delete-internet-gateway --internet-gateway-id "${IGW_ID}"
fi
[ "${SUBNET_ID}" != "None" ] && aws ec2 delete-subnet --subnet-id "${SUBNET_ID}"
[ "${VPC_ID}" != "None" ] && aws ec2 delete-vpc --vpc-id "${VPC_ID}"

rm -f "${KEY_FILE}" machines.txt

echo "== Anything left tagged ${TAG} (should be empty):"
aws resourcegroupstaggingapi get-resources --tag-filters "Key=Name,Values=${TAG}" \
  --query 'ResourceTagMappingList[].ResourceARN' --output table
echo "Check Billing in the AWS console tomorrow to confirm EC2 charges have stopped."
