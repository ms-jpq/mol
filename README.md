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
# The `--` are required to distinguish convenience / raw qemu args
./main.sh ACTION [-n --name NAME='_'] [-f --fork FORK] [--os OS] [--vnc] -- ...convenience args -- ...raw qemu args
```

| Action           | Description                                        |
| ---------------- | -------------------------------------------------- |
| `n` \| `new`     | create VM                                          |
| `r` \| `run`     | run VM                                             |
| `l` \| `ls`      | list VMs                                           |
| `rm` \| `remove` | remove VM                                          |
| `lock`           | protect VM from `rm`                               |
| `unlock`         | safety-off                                         |
| `c` \| `console` | connect to VM serial console                       |
| `m` \| `monitor` | connect to qemu text console                       |
| `v` \| `vnc`     | connect to VNC display (if VM was provisioned one) |
| `q` \| `qmp`     | connect to qemu JSON console                       |

| OS     | Description   |
| ------ | ------------- |
| ubuntu | ubuntu-lts    |
| fedora | fedora-latest |

### Convenience Arguments

| Arg     | Description | Default           |
| ------- | ----------- | ----------------- |
| `--cpu` | # cores     | physical cpus / 2 |
| `--mem` | memory      | 1G                |

## Files

`./main.sh` will create a VM @ `./var/$NAME.$OS.vm` (ROOT)

- `$ROOT/ssh.conn` in addition to console output will contain the path of SSH socket

- `rm` on a running VM will fail. Running VMs are protected via `flock $ROOT`

## Serial Console

- You will have to **PRESS THE ENTER KEY** before you see anything, the OS is waiting for your input.

- `root` user's password is `root`
