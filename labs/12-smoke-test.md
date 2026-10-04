# Lab 12: Smoke test

**Goal:** check encryption at rest, deployments, port forwarding, logs, exec and NodePort services.

For "in a new terminal", open a second session with `scripts/ssh-jumpbox.sh`.

**Extra check for AWS:** Kelsey's tests don't cover pod-to-pod traffic across nodes, which is what source/dest check and Lab 11 affect.

```bash
kubectl scale deployment nginx --replicas=2
kubectl get pods -l app=nginx -o wide          # note a pod IP on node-1
ssh root@node-0 "curl -sI http://<node-1 pod IP> | head -1"   # HTTP/1.1 200 OK
```
