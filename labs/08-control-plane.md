# Lab 08: Bootstrapping the control plane

**Goal:** run kube-apiserver, kube-controller-manager and kube-scheduler as systemd services on the server.

| Service | Role |
|---|---|
| kube-apiserver :6443 | The front door; the only component that talks to etcd |
| kube-controller-manager | Keeps actual state matching desired state; signs certificate requests with `ca.key` |
| kube-scheduler | Assigns pods to nodes |

**Kubelet RBAC step:** kubelets run with `authorization.mode: Webhook`, so they ask the API server whether a caller is allowed. The API server's certificate is user `kubernetes`, which has no kubelet permissions by default. The `system:kube-apiserver-to-kubelet` ClusterRole and its binding grant them. Without it, `kubectl logs` and `exec` are `Forbidden`.

**Problem I hit:** `curl: (77) error setting certificate file: ca.crt`. I was on the server, where `ca.crt` had moved to `/var/lib/kubernetes/`. The verification command runs on the jumpbox from the repo folder.
