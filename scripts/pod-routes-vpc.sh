#!/usr/bin/env bash
# Optional alternative to Lab 11: put the pod routes in the VPC route table.
# Unlike `ip route add`, these survive instance restarts.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

RT_ID=$(route_table_id)
for N in 0 1; do
  aws ec2 create-route --route-table-id "${RT_ID}" \
    --destination-cidr-block "10.200.${N}.0/24" --instance-id "$(instance_id "node-${N}")" >/dev/null
  echo "10.200.${N}.0/24 -> node-${N}"
done

aws ec2 describe-route-tables --route-table-ids "${RT_ID}" \
  --query 'RouteTables[0].Routes[].{Dest:DestinationCidrBlock,Target:GatewayId||NetworkInterfaceId,State:State}' \
  --output table
