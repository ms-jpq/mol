#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

SOCKS=(./var/*.vm/*.sock)
BOTTOM=60022
PORT=$((BOTTOM + ${#SOCKS[@]}))
printf -- '%s' $((PORT))
