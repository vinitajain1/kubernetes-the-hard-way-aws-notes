# Lab notes

One file per lab in [Kelsey's guide](https://github.com/kelseyhightower/kubernetes-the-hard-way#labs). Each note covers what the lab does, why, what changes on AWS, and problems I hit. Follow the original lab for the actual commands.

| Lab | AWS changes? |
|---|---|
| [01 Prerequisites](01-prerequisites.md) | Yes: provision EC2 |
| [02 Jumpbox](02-jumpbox.md) | Yes: prepare hosts first |
| [03 Compute resources](03-compute-resources.md) | Partly skipped |
| [04 CA and TLS certificates](04-certificate-authority.md) | No |
| [05 Kubeconfig files](05-kubeconfig-files.md) | No |
| [06 Data encryption key](06-data-encryption.md) | No |
| [07 etcd](07-etcd.md) | No |
| [08 Control plane](08-control-plane.md) | No |
| [09 Worker nodes](09-worker-nodes.md) | No |
| [10 kubectl access](10-kubectl.md) | No |
| [11 Pod network routes](11-pod-network-routes.md) | Yes: source/dest check |
| [12 Smoke test](12-smoke-test.md) | Extra cross-node check |
| [13 Cleanup](13-cleanup.md) | Yes: AWS cleanup |

Rule I learned the hard way: run every jumpbox command from `/root/kubernetes-the-hard-way`.
