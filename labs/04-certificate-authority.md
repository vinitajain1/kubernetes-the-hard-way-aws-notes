# Lab 04: Certificate authority and TLS certificates

**Goal:** a private CA, and a certificate for every component, generated from [`ca.conf`](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/ca.conf).

**How each certificate is made:**

```bash
openssl genrsa -out node-0.key 4096
openssl req -new -key node-0.key -config ca.conf -section node-0 -out node-0.csr
openssl x509 -req -in node-0.csr -copy_extensions copyall -CA ca.crt -CAkey ca.key -days 3653 -out node-0.crt
```

**Key ideas:**
- The certificate's CN becomes the Kubernetes username and O the group. RBAC decides permissions.
- The API server certificate's SANs must list every name clients use (`server.kubernetes.local`, `10.32.0.1`, `kubernetes.default`…).
- Components don't share certificates. Each holds its own certificate and key, plus `ca.crt`.
- At the end of this lab the files exist but nothing uses them yet.

Full write-up: [docs/pki.md](../docs/pki.md).

**Check a certificate:**

```bash
openssl x509 -in kube-api-server.crt -noout -subject -ext subjectAltName,extendedKeyUsage
openssl verify -CAfile ca.crt node-0.crt
```
