#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$MACHTYPE" in
aarch64*)
  ARCH=arm64
  ;;
*)
  ARCH=amd64
  ;;
esac

if ! [[ -v RELEASE ]]; then
  TIME="$(date -- '+%y %m')"
  YEAR="${TIME%% *}"
  MONTH="${TIME##* }"
  MONTH="${MONTH#0}"

  if ! ((YEAR % 2)) && ((MONTH < 6)); then
    YEAR=$((YEAR - 1))
  fi

  RELEASE="$((YEAR / 2 * 2)).04"
fi

printf -- '%s' "https://cloud-images.ubuntu.com/releases/$RELEASE/release/ubuntu-$RELEASE-server-cloudimg-$ARCH.img"
