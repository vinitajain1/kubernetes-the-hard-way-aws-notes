# Lab 01: Prerequisites (and provisioning EC2)

**Goal:** four Debian 12 machines on one network.

| Machine | Role | EC2 type | Disk |
|---|---|---|---|
| jumpbox | admin host | t3.micro | 10 GB |
| server | control plane | t3.small (2 GB) | 20 GB |
| node-0, node-1 | workers | t3.small (2 GB) | 20 GB |

**How:** [`scripts/01-provision.sh`](../scripts/01-provision.sh), based on Slawek Zachcial's AWS commands.

**Changes from Slawek's guide:**
- t3.small with 20 GB disks instead of t2.micro (1 GB RAM, 8 GB disk is below Kelsey's spec)
- SSH allowed only from my IP, not `0.0.0.0/0`
- a security group rule for the pod ranges `10.200.0.0/16`
- source/destination check disabled on server, node-0 and node-1 (needed for Lab 11)
- `CpuCredits=standard` so burstable instances can't run up extra CPU charges

**Things I learned:**
- The VPC, subnet, internet gateway, route table and security group are free. Charges start with instances, disks and public IPv4 addresses.
- Typing `yes` at the first SSH host-key prompt is normal: it's a new machine.
- Verify the OS: `ssh -i kubernetes-the-hard-way.id_rsa admin@<ip> grep PRETTY_NAME /etc/os-release`
