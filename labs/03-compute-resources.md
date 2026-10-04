# Lab 03: Provisioning compute resources

**Goal:** every machine has a stable hostname, and every machine can reach the others by name.

| Section | On AWS |
|---|---|
| Machine database | Skip: `machines.txt` already exists |
| Enable root SSH, generate and distribute SSH keys | Skip: done in Lab 02 prep. Still run the verify loop |
| Hostnames | As written |
| Host lookup table and `/etc/hosts` sections | As written |

**Optional but useful:** Debian's cloud-init can reset the hostname and `/etc/hosts` on boot. To keep them across stop/start, on each machine:

```bash
printf 'preserve_hostname: true\nmanage_etc_hosts: false\n' > /etc/cloud/cloud.cfg.d/99-kthw.cfg
```

**Why hostnames matter later:** certificates (Lab 04) and node registration (Lab 09) use them. A kubelet whose hostname doesn't match its certificate can't register.
