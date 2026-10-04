# Lab 11: Pod network routes

**Goal:** let pods on different nodes reach each other.

The bridge plugin only knows its own node. Without routes, node-0 sends `10.200.1.x` to the VPC router, which sends it to the internet gateway, which drops it.

**Kelsey's way** (run on the jumpbox from the repo folder):

```bash
NODE_0_IP=$(grep node-0 machines.txt | cut -d " " -f 1); NODE_0_SUBNET=$(grep node-0 machines.txt | cut -d " " -f 4)
NODE_1_IP=$(grep node-1 machines.txt | cut -d " " -f 1); NODE_1_SUBNET=$(grep node-1 machines.txt | cut -d " " -f 4)
ssh root@server "ip route add ${NODE_0_SUBNET} via ${NODE_0_IP}; ip route add ${NODE_1_SUBNET} via ${NODE_1_IP}"
ssh root@node-0 "ip route add ${NODE_1_SUBNET} via ${NODE_1_IP}"
ssh root@node-1 "ip route add ${NODE_0_SUBNET} via ${NODE_0_IP}"
```

**AWS specifics:**
- **Source/destination check must be off** on server, node-0 and node-1, or EC2 drops packets addressed to pod IPs.
- The interface is `ens5`, not `ens160`.
- `ip route add` doesn't survive reboots. Re-run after stop/start.
- Alternative that survives reboots: [`scripts/pod-routes-vpc.sh`](../scripts/pod-routes-vpc.sh) puts the routes in the VPC route table (visible in the console under VPC → Route tables → Routes).

Production clusters automate this with Calico (BGP), overlays (Flannel, Cilium), or the AWS VPC CNI.
