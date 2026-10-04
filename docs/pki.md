# PKI and how Kubernetes uses it

Notes on public key infrastructure (PKI), built up one step at a time, then applied to the certificates in Lab 04.

## Part 1: PKI from first principles

### 1. Key pairs

Asymmetric cryptography gives you two linked keys:

- The **private key** stays secret with its owner.
- The **public key** can be shared with anyone.

They have two useful properties:

- Encrypt with the public key → only the private key can decrypt.
- Sign with the private key → anyone with the public key can verify.

You can't work out the private key from the public one.

```bash
openssl genrsa -out ca.key 4096
```

### 2. Hashes

A hash (such as SHA-256) is a fixed-size fingerprint of any data. Change one byte and the hash changes completely, and you can't work backwards from it. Signatures sign the hash, not the whole file.

### 3. Signatures

```text
sign:   hash(data) → encrypt with private key → signature
verify: hash(data) ⇄ decrypt signature with public key → match?
```

A match proves **authenticity** (only the key holder could sign it) and **integrity** (the data hasn't changed).

### 4. The trust problem

A signature proves that the holder of some key signed something, not who that holder is. Anyone can claim "this public key belongs to node-1." Someone you already trust has to vouch for that link.

### 5. Certificates

An X.509 certificate is a signed statement: this public key belongs to this name.

| Field | Example |
|---|---|
| Subject | `CN=system:node:node-1, O=system:nodes` |
| Subject Alternative Names (SANs) | `node-1`, `127.0.0.1` |
| Public key | node-1's public key |
| Issuer | `CN=CA` |
| Validity | not before / not after |
| Usage | client auth, server auth, signing other certificates |
| Signature | the issuer's signature over all of the above |

A certificate is public. It's useless without the matching private key.

### 6. The certificate authority

A CA is a key pair whose certificate signs itself (the **root**). You copy `ca.crt` to every machine and trust whatever it signs. That's the trust anchor. Browsers work the same way, except their root CAs come pre-installed.

```bash
openssl req -x509 -new -key ca.key -days 3653 -config ca.conf -out ca.crt
```

### 7. Issuing a certificate

1. Generate a key pair for the component.
2. Create a certificate signing request (CSR) with the public key and requested names, signed with the component's own key.
3. The CA checks the request and signs it, producing the certificate.
4. Deliver the certificate, its key and `ca.crt` to the component.

In production, the key is created on the machine that uses it and never travels. Kubernetes The Hard Way creates everything on the jumpbox for convenience.

### 8. Verifying a certificate

1. **Signature:** signed by a CA I trust?
2. **Validity:** within its dates?
3. **Usage:** allowed for this purpose?
4. **Name:** for server certificates, does a SAN match the address I dialed?
5. **Possession:** can the other side prove it holds the private key? (Checked during the handshake.)

Step 5 matters because anyone can present a copy of a public certificate.

### 9. The TLS handshake (mutual TLS)

1. Client says hello and lists the ciphers it supports.
2. Server sends its certificate.
3. Client verifies it (step 8).
4. Server asks for the client's certificate.
5. Client sends its certificate and signs part of the handshake with its private key.
6. Server verifies it and now knows who the client is.
7. Both agree on a shared session key; from here on, traffic uses fast symmetric encryption.
8. The application authorizes each request based on the identity from step 6.

### 10. Lifecycle

- **Expiry:** certificates have end dates (about 10 years in this tutorial; usually 1 year or less in production).
- **Revocation:** public PKI uses CRLs or OCSP. Kubernetes has no built-in revocation, so production prefers short-lived certificates.
- **CA compromise:** whoever has `ca.key` can create any identity, including cluster admin.

## Part 2: How Kubernetes uses it

### Certificates prove identity; RBAC decides permissions

The API server takes your identity from the certificate:

- **CN** → username
- **O** → group

Then RBAC and the node authorizer decide what that user or group may do. A valid certificate with the wrong CN still gets `Forbidden`.

### Why bother inside a private VPC?

- Pods share the network, so being able to reach the API server can't be the same as being allowed to use it.
- Several components share one IP (kubelet, kube-proxy and pods on a node). Only certificates tell them apart.
- The API server also calls the kubelets. Without authentication, anything in the VPC could `exec` into containers.
- Secrets and tokens travel over these connections.

The VPC is the locked building; certificates are the ID badges inside it.

### The certificates in `ca.conf`

| Certificate | CN (user) | O (group) | Used by | Notes |
|---|---|---|---|---|
| `ca` | `CA` | | trust anchor | `CA:TRUE`, may sign other certificates |
| `admin` | `admin` | `system:masters` | kubectl | `system:masters` has full control |
| `node-0`, `node-1` | `system:node:<name>` | `system:nodes` | kubelet | Required format for the node authorizer. Also the kubelet's server certificate on :10250 |
| `kube-proxy` | `system:kube-proxy` | `system:node-proxier` | kube-proxy | Bound to a built-in role |
| `kube-controller-manager` | `system:kube-controller-manager` | same | controller manager | Bound to a built-in role |
| `kube-scheduler` | `system:kube-scheduler` | `system:system:kube-scheduler` | scheduler | The doubled `system:` looks like a typo; harmless because RBAC binds the CN |
| `kube-api-server` | `kubernetes` | | API server | Server certificate, and client certificate when calling kubelets |
| `service-accounts` | `service-accounts` | | API server | Not used for connections: its key signs pod tokens |

Each section in `ca.conf` sets:

- `basicConstraints = CA:FALSE`: can't sign other certificates
- `extendedKeyUsage = clientAuth, serverAuth`: allowed roles
- `subjectAltName`: names it's valid for as a server

The API server's SANs list every name clients dial: `127.0.0.1`, `10.32.0.1` (the `kubernetes` service IP), `kubernetes.default…`, and `server.kubernetes.local`.

### Kubeconfig anatomy

```yaml
clusters:
- cluster:
    server: https://server.kubernetes.local:6443   # where to connect (must be a SAN)
    certificate-authority-data: <ca.crt>           # which CA to trust for the server
users:
- user:
    client-certificate-data: <component.crt>       # who I am
    client-key-data: <component.key>               # proof I own it
```

Every kubeconfig embeds the same `ca.crt`; only the client certificate and key differ. A kubeconfig with an embedded key is a secret.

### The six connections

| # | Connection | Type |
|---|---|---|
| 1 | kubectl → API server | mTLS (`admin.crt`) |
| 2 | kubelet → API server | mTLS (`node-X.crt`) |
| 3 | kube-proxy, scheduler, controller manager → API server | mTLS |
| 4 | API server → kubelet :10250 | mTLS (`kube-api-server.crt` as client) |
| 5 | pod → API server | TLS + service account token |
| 6 | API server → etcd | plain HTTP on 127.0.0.1 |

### Why the API server needs an RBAC rule to reach kubelets

The kubelet runs with `authorization.mode: Webhook`. After authenticating the API server's certificate (user `kubernetes`), it asks the API server whether that user may access `nodes/proxy`, `nodes/log`, `nodes/stats`, `nodes/metrics` and `nodes/spec`. Nothing grants that by default, so Lab 08 creates the `system:kube-apiserver-to-kubelet` ClusterRole and binds it to user `kubernetes`. Without it, `kubectl logs` and `kubectl exec` return `Forbidden`.

### Node registration

1. The kubelet reads its kubeconfig and connects as `system:node:node-0`.
2. The node authorizer allows nodes to create Node objects; the `NodeRestriction` admission plugin limits each node to its own.
3. The kubelet creates its Node object (addresses, capacity, versions, labels).
4. It renews a Lease in `kube-node-lease` about every 10 seconds. If leases stop, the node controller marks the node `NotReady`.

The hostname must match the certificate CN, or registration fails.

### Production differences

| | This tutorial | Production |
|---|---|---|
| Certificate creation | `openssl` by hand | kubeadm, or the cloud provider |
| Private keys | created on the jumpbox and copied | created where they're used |
| Nodes | certificate copied over SSH | TLS bootstrapping: bootstrap token → CSR → signed by the controller manager → auto-rotated |
| Lifetime | about 10 years | 1 year or less |
| CAs | one | usually three (cluster, etcd, front proxy) |
| etcd | plain HTTP on localhost | mTLS, often on separate machines |
| Humans | `admin` client certificate | SSO (OIDC) or cloud identity; admin certificate kept for emergencies |
| Managed (EKS/GKE/AKS) | | provider holds the CA key; you authenticate with cloud identity |

### Useful commands

```bash
openssl x509 -in node-0.crt -noout -text                     # read every field
openssl x509 -in kube-api-server.crt -noout -subject -ext subjectAltName
openssl verify -CAfile ca.crt node-0.crt                     # should print OK
```

| Error | Meaning |
|---|---|
| `x509: certificate signed by unknown authority` | wrong CA |
| `x509: certificate is valid for X, not Y` | the dialed name isn't in the server certificate's SANs |
| `Forbidden` | authenticated, but RBAC doesn't allow it (often a wrong CN) |
