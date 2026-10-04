#!/usr/bin/env bash
# Prepare the instances for Kelsey's labs (replaces parts of Labs 02 and 03):
# - write machines.txt from the private IPs and copy it to the jumpbox
# - allow root SSH with the AWS key on all machines, and give the jumpbox the key
# - add the 127.0.1.1 line Kelsey's hostname step expects, and name the jumpbox
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

JUMPBOX_IP=$(public_ip jumpbox)
OTHERS=()
for NAME in server node-0 node-1; do OTHERS+=("$(public_ip "${NAME}")"); done
SSH=(ssh -i "${KEY_FILE}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)
SCP=(scp -i "${KEY_FILE}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

echo "== machines.txt"
cat > machines.txt <<EOF
$(private_ip server) server.kubernetes.local server
$(private_ip node-0) node-0.kubernetes.local node-0 10.200.0.0/24
$(private_ip node-1) node-1.kubernetes.local node-1 10.200.1.0/24
EOF
cat machines.txt

echo "== Root SSH access"
for IP in "${JUMPBOX_IP}" "${OTHERS[@]}"; do
  "${SSH[@]}" "admin@${IP}" \
    "sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
     && sudo systemctl restart sshd \
     && sudo sed -i 's/.*ssh-rsa/ssh-rsa/' /root/.ssh/authorized_keys"
done
"${SCP[@]}" "${KEY_FILE}" "root@${JUMPBOX_IP}:/root/.ssh/id_rsa"
"${SCP[@]}" machines.txt "root@${JUMPBOX_IP}:/root/machines.txt"

echo "== /etc/hosts and jumpbox hostname"
for IP in "${JUMPBOX_IP}" "${OTHERS[@]}"; do
  "${SSH[@]}" "root@${IP}" "grep -q '127.0.1.1' /etc/hosts || echo '127.0.1.1 localhost' >> /etc/hosts"
done
"${SSH[@]}" "root@${JUMPBOX_IP}" \
  "sed -i 's/^127.0.1.1.*/127.0.1.1\tjumpbox/' /etc/hosts && hostnamectl set-hostname jumpbox && systemctl restart systemd-hostnamed"

cat <<EOF

Done. Next:
  ./scripts/ssh-jumpbox.sh
Then follow Kelsey's Lab 02. After cloning the repo, move the machine database into it:
  mv /root/machines.txt /root/kubernetes-the-hard-way/
EOF
