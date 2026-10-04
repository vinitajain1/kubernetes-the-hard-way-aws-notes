# Lab 02: Set up the jumpbox

**Goal:** a home base with SSH access to every machine, Kelsey's repo, all binaries, and `kubectl`.

**AWS prep first** ([`scripts/02-prepare-hosts.sh`](../scripts/02-prepare-hosts.sh)):
1. **Machine database:** write `machines.txt` (private IP, FQDN, hostname, pod subnet) from the AWS CLI.
2. **Root SSH:** Debian EC2 images only allow `admin`. Enable `PermitRootLogin`, remove the prefix that blocks root in `/root/.ssh/authorized_keys`, and copy the AWS key to the jumpbox as `/root/.ssh/id_rsa`.
3. **Hosts file:** add the `127.0.1.1` line Kelsey's Lab 03 `sed` expects.

**How SSH keys were "generated and distributed":** AWS generated the key pair (`create-key-pair`), cloud-init installed the public key on every instance at launch, and the script unlocked it for root. This replaces Kelsey's `ssh-keygen` and `ssh-copy-id`.

**Then Kelsey's lab, with two edits:**
- Connect with `scripts/ssh-jumpbox.sh` instead of `ssh root@jumpbox`.
- After `cd kubernetes-the-hard-way`, run `mv /root/machines.txt .`

**Mistake I made:** I left `machines.txt` in `/root`. Later labs read it from the repo folder and got nothing, which caused the Lab 09 bug.
