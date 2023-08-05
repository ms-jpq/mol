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
./main.sh [-n --name NAME='_'] [-a --action ACTION='run'] [--os OS] [--vnc] -- ...raw qemu args
```

| Action           | Description                                        |
| ---------------- | -------------------------------------------------- |
| `r` \| `run`     | run VM                                             |
| `rm` \| `remove` | remove VM                                          |
| `lock`           | protect VM from `rm`                               |
| `unlock`         | safety-off                                         |
| `c` \| `console` | connect to VM serial console                       |
| `q` \| `monitor` | connect to qemu text console                       |
| `v` \| `vnc`     | connect to VNC display (if VM was provisioned one) |
| `j` \| `qmp`     | connect to qemu JSON console                       |

| OS     | Description   |
| ------ | ------------- |
| ubuntu | ubuntu-lts    |
| fedora | fedora-latest |

## Files

`./main.sh` will create a VM @ `./var/$NAME.$OS.vm` (ROOT)

- `$ROOT/ssh.conn` in addition to console output will contain the path of SSH socket

## Serial Console

The OS is waiting for a keyboard input before it respond with any text.

- You will have to **PRESS THE ENTER KEY** before you see any output.

- `root` user's password is `root`

- `rm` on a running VM will fail. Running VMs are protected via `flock` `$ROOT`
