#!/usr/bin/env bash
# Start all four instances and print what to check afterwards.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

IDS=$(instance_ids_in_state stopped)
if [ -z "${IDS}" ]; then echo "Nothing stopped."; else
  aws ec2 start-instances --instance-ids ${IDS} --output table --query 'StartingInstances[].InstanceId'
  aws ec2 wait instance-running --instance-ids ${IDS}
fi

echo "jumpbox public IP: $(public_ip jumpbox)"
cat <<'EOF'

After a restart:
  1. If your laptop's IP changed:   ./scripts/allow-my-ip.sh
  2. Connect:                        ./scripts/ssh-jumpbox.sh   (answer "yes" to the new host key)
  3. On the jumpbox, check hostnames: for h in server node-0 node-1; do ssh root@$h hostname; done
  4. Re-add Lab 11 pod routes (unless you used scripts/pod-routes-vpc.sh); see labs/11-pod-network-routes.md
  5. kubectl get nodes   (both Ready after a minute or two)
EOF
