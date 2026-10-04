#!/usr/bin/env bash
# Stop all four instances. Disks (and the whole cluster state) are kept.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

IDS=$(instance_ids_in_state running)
if [ -z "${IDS}" ]; then echo "Nothing running."; exit 0; fi
aws ec2 stop-instances --instance-ids ${IDS} --output table --query 'StoppingInstances[].InstanceId'
aws ec2 wait instance-stopped --instance-ids ${IDS}
echo "All stopped. You now pay only for the disks (about \$0.20/day)."
