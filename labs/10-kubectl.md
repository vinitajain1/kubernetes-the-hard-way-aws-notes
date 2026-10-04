# Lab 10: Configuring kubectl for remote access

**Goal:** run `kubectl` from the jumpbox as `admin`.

"Remote" means the jumpbox: port 6443 isn't open to the internet. The admin kubeconfig points at `https://server.kubernetes.local:6443`, which resolves through `/etc/hosts`.

Check: `kubectl version` and `kubectl get nodes`.
