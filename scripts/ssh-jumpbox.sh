#!/usr/bin/env bash
# Open a root shell on the jumpbox.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

JUMPBOX_IP=$(public_ip jumpbox)
if [ -z "${JUMPBOX_IP}" ] || [ "${JUMPBOX_IP}" = "None" ]; then
  echo "The jumpbox isn't running. Start the instances with scripts/start.sh" >&2
  exit 1
fi
exec ssh -i "${KEY_FILE}" -o StrictHostKeyChecking=accept-new \
  -o SetEnv='LC_ALL=C.UTF-8 LANG=C.UTF-8' "root@${JUMPBOX_IP}"
