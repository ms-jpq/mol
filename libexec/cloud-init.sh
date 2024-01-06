#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

HOSTNAME="$1"
DST="$2"
export -- HOSTNAME PASSWD AUTHORIZED_KEYS

./libexec/envsubst.pl <./cloud-init/meta-data.yml >"$DST/meta-data"

SALT="$(uuidgen)"
PASSWD="$(openssl passwd -1 -salt "$SALT" root)"
AUTHORIZED_KEYS="$(cat -- ~/.ssh/*.pub | jq --raw-input --slurp --compact-output 'split("\n") | map(select(. != ""))')"
./libexec/envsubst.pl ./cloud-init/user-data.yml >"$DST/user-data"

cp -a -R -f -- ./cloud-init/scripts "$DST/scripts"
