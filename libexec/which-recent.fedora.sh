#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CACHE="${1:-""}"

case "$MACHTYPE" in
aarch64*)
  ARCH=aarch64
  ;;
*)
  ARCH=x86_64
  ;;
esac

CADENCE=6
CONSERVE=7

BASE_YEAR=2023
BASE_MONTH=4
BASE_VERSION=38

TIME="$(date -- '+%Y %m')"
YEAR="${TIME%% *}"
MONTH="${TIME##* }"
MONTH="${MONTH#0}"

ELAPSED=$(((YEAR - BASE_YEAR) * 12 + MONTH - BASE_MONTH))

CONSERVE=$((ELAPSED > CONSERVE ? CONSERVE : ELAPSED - CONSERVE))
CONSERVE=$((CONSERVE < 0 ? 0 : CONSERVE))

VERSION=$((BASE_VERSION + (ELAPSED - CONSERVE) / CADENCE))

URI="https://download.fedoraproject.org/pub/fedora/linux/releases/$VERSION/Cloud/$ARCH/images"

if [[ -f "$CACHE" ]]; then
  HTML="$(<"$CACHE")"
else
  HTML="$(curl --fail --location -- "$URI")"
  if [[ -n "$CACHE" ]]; then
    mkdir -p -- "${CACHE%/*}"
    printf -- '%s' "$HTML" >"$CACHE"
  fi
fi

HREF="$(perl -w -CASD -ne '/href="(.+?\.raw\.xz)"/ && print $1' <<<"$HTML")"
printf -- '%s' "$URI/$HREF"
