# MoL

Minimal hardware accelerated `curl -- linux.iso | qemu-system-aarch64` scripts.

- SSH connection

- ROOT password (root)

- ROOT partition expansion

## Dependencies

```bash
brew install -- qemu bash gnu-getopt make
```

## RUN

```bash
# [RELEASE=...] is optional
# [SSH=...] is optional
# [NAME=...] is optional
gmake run.<ubuntu | fedora> [RELEASE=22.04|38] [SSH=127.0.0.1:60022] [NAME=_]
```

## SSH

```bash
# $PORT +1 for every additional running VM
ssh -p 60022 root@localhost
```

## Qemu Monitor

```bash
# Additional dependency
brew install -- socat
```

```bash
gmake qm.<ubuntu | fedora> [RELEASE=38] [NAME=_]
```
