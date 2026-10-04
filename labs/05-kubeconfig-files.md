# Lab 05: Kubeconfig files

**Goal:** package each certificate with the API server address and CA, so each component knows where to connect and how to prove who it is.

| Field | Contains |
|---|---|
| `server` (`--server`) | API server URL; the host must be a SAN in the API server certificate |
| `certificate-authority-data` | `ca.crt`, to verify the API server |
| `client-certificate-data` / `client-key-data` | the component's own certificate and key |

| Kubeconfig | `--server` |
|---|---|
| node-0, node-1, kube-proxy, controller manager, scheduler | `https://server.kubernetes.local:6443` |
| admin (Lab 05, used on the server) | `https://127.0.0.1:6443` |
| admin (Lab 10, used on the jumpbox) | `https://server.kubernetes.local:6443` |

Kubeconfigs with embedded keys are secrets.
