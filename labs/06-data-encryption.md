# Lab 06: Data encryption config and key

**Goal:** encrypt Kubernetes Secrets before they're written to etcd.

The lab generates a random 32-byte key and an `EncryptionConfiguration` using the `aescbc` provider. The API server loads it with `--encryption-provider-config`. Lab 12 checks it: the Secret's value in etcd starts with `k8s:enc:aescbc:v1:key1` instead of plain text.

TLS protects data in transit; this protects data at rest.
