# Lab 09: Bootstrapping the worker nodes

**Goal:** install runc, containerd, CNI plugins, the kubelet and kube-proxy on node-0 and node-1.

**CNI networking:**
- `10-bridge.conf` creates a `cni0` bridge per node and gives each pod an IP from that node's range (`10.200.0.0/24` / `10.200.1.0/24`). `SUBNET` is filled in from `machines.txt`.
- `99-loopback.conf` gives each pod its own `lo`.
- `br_netfilter` and `bridge-nf-call-iptables = 1` make same-node pod traffic pass through iptables, so Services work between pods on the same node.

**How nodes register:** the kubelet connects with `node-X.crt` (`system:node:node-X`), the node authorizer and `NodeRestriction` let it create only its own Node object, and it renews a Lease every ~10 s as a heartbeat. The node is `Ready` once containerd and the CNI config are in place.

**My bug:** pods failed with `failed to setup network for sandbox ... invalid CIDR address:`. `10-bridge.conf` had an empty subnet because I ran the `sed` loop outside the repo folder, where `machines.txt` and `configs/` weren't. Fix: move `machines.txt` into the repo, regenerate `10-bridge.conf`, copy it to `/etc/cni/net.d/`, restart containerd and the kubelet, delete the pods.

`MissingClusterDNS` warnings are expected: the guide doesn't install CoreDNS.
