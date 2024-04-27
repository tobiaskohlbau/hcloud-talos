# Purpose

This is a demonstration repository to install a talos kubernetes cluster within hetzner cloud with working
CNI (cilium) and storage provider (mayastor).

# Prerequisite

The user needs to create a namespace within HCloud and confiogure the hcloud cli with the respective token.

```bash
hcloud context create talos
```

Within the namespace a server needs to be created which serves as the base image.

1. Create a various server and configure ssh access to it.
2. Reboot into rescue system.
3. `cd /tmp`
4. `curl -L -o /tmp/talos.raw.xz https://github.com/siderolabs/talos/releases/download/v1.7.0/hcloud-amd64.raw.xz`
5. `xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync`
6. Shutdown the instance.
7. Create an Snapshot with the name talos-1_7_0

# Creation

For the creation run `./create.sh`.

# Cleanup

Every resource created by `./create.sh` can be cleanped up by calling `./cleanup.sh`. Notice that the snapshot and
attached server still exists.



