# AWS and pod networking

## The AWS pieces

| Resource | What it does | Cost |
|---|---|---|
| **VPC** `10.240.0.0/24` | An isolated private network; its CIDR is the pool of private addresses | Free |
| **Subnet** `10.240.0.0/24` | Where instances live (one AZ). Same range as the VPC; AWS reserves 5 addresses, leaving 251 | Free |
| **Internet gateway** | Translates between each instance's public and private IP. It doesn't pick machines | Free (data transfer billed) |
| **Route table** | Rulebook for the VPC's built-in router; checked for every packet leaving the subnet | Free |
| **Security group** | Stateful firewall on each instance's network interface | Free |
| **EC2 instances, EBS disks, public IPv4** | The machines | Billed |

### What makes a subnet public

All three are needed:

1. an internet gateway attached to the VPC,
2. a route `0.0.0.0/0 → internet gateway` in the subnet's route table,
3. public IPs on the instances.

### Route table

| Destination | Target | Origin |
|---|---|---|
| `10.240.0.0/24` | `local` | automatic; keeps VPC traffic inside the VPC |
| `0.0.0.0/0` | internet gateway | added by hand |

The most specific match wins. Each instance also has its own Linux route table (`ip route`). Linux decides the next hop first; the VPC route table decides what happens once the packet is on the network.

### Security group rules

| Rule | Why |
|---|---|
| TCP 22 from my IP only | SSH from my laptop |
| All from `10.240.0.0/24` | Traffic between the machines |
| All from `10.200.0.0/16` | Pod ranges; probably redundant because the CNI masquerades cross-node pod traffic, but harmless |

Security groups are stateful, so replies are allowed automatically, and outbound traffic is open by default.

### SSH from my laptop, packet by packet

1. Laptop → jumpbox public IP :22.
2. The internet gateway rewrites the destination to the jumpbox's private IP.
3. The security group allows it (port 22 from my IP).
4. The reply matches `0.0.0.0/0`, goes to the internet gateway, which rewrites the source back to the public IP.

### Stopping and starting

| | Stop → start | Terminate |
|---|---|---|
| Private IP | same | released |
| Auto-assigned public IP | new | released |
| Disk contents | kept | deleted |

`machines.txt`, `/etc/hosts` and certificates use hostnames and private IPs, so they survive. Only laptop-side commands need the new public IPs.

## Pod networking

Kubernetes requires every pod to have its own IP and to reach every other pod. It delegates this to a CNI plugin:

```text
kubelet ──CRI──▶ containerd ──CNI──▶ /opt/cni/bin/* using /etc/cni/net.d/*.conf
```

### Within a node (Lab 09, bridge plugin)

When the first pod starts on node-0, the bridge plugin:

1. creates a Linux bridge `cni0` with `10.200.0.1`,
2. connects each pod with a veth pair (`eth0` inside the pod),
3. assigns IPs from the node's range with `host-local` IPAM,
4. adds a default route in the pod via `cni0`,
5. with `ipMasq`, rewrites the source of traffic leaving the pod range to the node's IP.

```text
 node-0
  pod A 10.200.0.2   pod B 10.200.0.3
       │ veth             │ veth
       └──── cni0 10.200.0.1 ────┐
                                 │ routing + iptables
                               ens5 ──▶ VPC
```

`br_netfilter` and `net.bridge.bridge-nf-call-iptables = 1` make traffic between pods on the same bridge pass through iptables. Without them, Service traffic between pods on the same node breaks, because kube-proxy's translation is skipped on the return path.

### Between nodes (Lab 11, static routes)

The bridge plugin only knows its own node. Without extra routes, node-0 sends `10.200.1.x` to the VPC router, which sends it to the internet gateway, which drops it.

```bash
ip route add 10.200.1.0/24 via <node-1 private IP>   # on node-0 (and the reverse on node-1; both on server)
```

On AWS this also needs **source/destination check turned off** on server, node-0 and node-1. node-1 receives packets addressed to pod IPs, not its own IP, and EC2 drops those by default.

The Linux routes don't survive reboots. Adding the same routes to the VPC route table (target: the node's instance) does, and removes the need for the Linux routes.

### How production does it

- **Calico:** advertises pod ranges with BGP.
- **Flannel / Cilium:** wrap pod traffic in node-to-node packets (VXLAN overlays).
- **AWS VPC CNI (EKS):** gives pods real VPC IPs, so no extra routes are needed.

## Connection types between Kubernetes components

See [pki.md](pki.md#the-six-connections).
