# Lab 07: Bootstrapping etcd

**Goal:** run etcd, the cluster's database, on the server.

- One member, listening on `http://127.0.0.1:2379`, so only processes on the server can reach it.
- No TLS in this version of the guide, because traffic never leaves the machine. Production uses mTLS and usually three or five members.
- Only the API server talks to etcd.

Check: `ssh root@server etcdctl member list`
