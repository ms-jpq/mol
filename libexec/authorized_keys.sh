#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

KEYS="$(cat -- ~/.ssh/*.pub | base64 --wrap 0)"
printf -- '%s' "io.systemd.credential.binary:ssh.authorized_keys.root=$KEYS"
