# MoL

Minimal hardware accelerated `curl -- linux.iso | qemu-system-aarch64` scripts.

- SSH connection

- ROOT password (root)

- ROOT partition expansion

## Dependencies

```bash
brew install -- qemu bash gnu-getopt make flock socat
```

## Usage

```bash
./main.sh [-n --name NAME='_'] [-a --action ACTION='run'] [--os OS] [--vnc]
```

| Action             | Description                                        |
| ------------------ | -------------------------------------------------- |
| `run`              | run VM                                             |
| `rm` \| `remove`   | remove VM                                          |
| `lock`             | protect VM from `rm`                               |
| `unlock`           | safety-off                                         |
| `con` \| `console` | connect to VM console                              |
| `qmp`              | connect to qemu console                            |
| `qm` \| `monitor`  | connect to qemu json console                       |
| `vnc`              | connect to VNC display (if VM was provisioned one) |

| OS     | Description   |
| ------ | ------------- |
| ubuntu | ubuntu-lts    |
| fedora | fedora-latest |

## SSH
