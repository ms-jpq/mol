#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ -L "$0" ]]; then
  DIR="${0%/*}"
  REAL="$DIR/$(/usr/bin/readlink -- "$0")"
else
  REAL="$0"
fi

if (($#)); then
  ARGV=(-- run."$1")
  shift -- 1
  if (($#)); then
    printf -v AV -- '%q ' "$@"
    ARGV+=("ARGV=$AV")
  fi
else
  ARGV=(-- run.ubuntu)
fi

exec -- gmake --directory "${REAL%/*}" "${ARGV[@]}"
