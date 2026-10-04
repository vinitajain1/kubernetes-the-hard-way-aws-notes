#!/usr/bin/env bash
# Allow SSH from your current public IP (use after changing networks or VPN).
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

MY_IP="$(curl -s https://checkip.amazonaws.com)/32"
if aws ec2 authorize-security-group-ingress --group-id "$(security_group_id)" \
     --protocol tcp --port 22 --cidr "${MY_IP}" >/dev/null 2>&1; then
  echo "SSH allowed from ${MY_IP}"
else
  echo "Rule for ${MY_IP} already exists (or the security group wasn't found)."
fi
