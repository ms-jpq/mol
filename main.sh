#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ -L "$0" ]]; then
  DIR="${0%/*}"
  REAL="$DIR/$(readlink -- "$0")"
else
  REAL="$0"
fi

DIR="${REAL%/*}"

BREW="$(brew --prefix)"
export -- BREW

OPTS='n:,a:,f:'
LONG_OPTS='name:,os:,fork:,vnc'
GO="$("$BREW/opt/gnu-getopt/bin/getopt" --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

NAME='vm'
VNC=0
while (($#)); do
  case "$1" in
  -n | --name)
    NAME="$2"
    shift -- 2
    ;;
  -f | --fork)
    FORK="$2"
    shift -- 2
    ;;
  --vnc)
    VNC=1
    shift -- 1
    ;;
  --)
    ACTION="${2:-run}"
    shift -- 2 || shift -- 1
    break
    ;;
  *)
    exec -- gmake -- help >&2
    ;;
  esac
done

LIB="$DIR/var/lib"
CACHE="$DIR/var/cache"
ROOT="$LIB/$NAME"

QMP_SOCK="$ROOT/qmp.sock"
CON_SOCK="$ROOT/con.sock"
QM_SOCK="$ROOT/qm.sock"
VNC_SOCK="$ROOT/vnc.sock"

KERNEL=("$CACHE"/*-vmlinuz-*)
INITRD=("$CACHE"/*-initrd-*)
FS_ROOT='/dev/vda1'

RAW=run.raw
DRIVE="$ROOT/$RAW"
CLOUD_INIT="$ROOT/cloud-init.iso"

SSH_LOCATION="$ROOT/ssh.conn"
SSH_CMD=(ssh -l root -p)

fwait() {
  {
    mkdir -v -p -- "$1"
    set -x
    until flock --nonblock "$1" true; do
      sleep -- 1
    done
    set +x
  } >&2
}

lsa() {
  {
    mkdir -v -p -- "$LIB"
    ls -AFhl --color=auto -- "$LIB"
  } >&2
}

new() {
  {
    fwait "$ROOT"
    if [[ -v FORK ]]; then
      F_DRIVE="$LIB/$FORK/$RAW"

      printf -- '%q%s%q\n' "$F_DRIVE" ' -> ' "$DRIVE" >&2
      if ! [[ -f "$F_DRIVE" ]]; then
        printf -- '%s%q\n' '>? ' "$F_DRIVE"
        exit 1
      fi
      if [[ -f "$DRIVE" ]]; then
        printf -- '%s%q\n' '>! ' "$DRIVE"
        lsa
        exit 1
      fi

      mkdir -v -p -- "$ROOT" >&2
      flock --nonblock "$ROOT" cp -v -f -- "$F_DRIVE" "$DRIVE"
    else
      flock --nonblock "$ROOT" gmake --directory "$DIR" -- NAME="$NAME" run
    fi
  } >&2
}

ssh_pp() {
  local -- conn="$1"
  SSH_HOST="${conn%%:*}"
  SSH_PORT="${conn##*:}"
  {
    printf -- '\n%s' '>>> '
    printf -- '%q ' "${SSH_CMD[@]}" "$SSH_PORT" "$SSH_HOST"
    printf -- '<<<\n\n'
  } >&2
}

case "$ACTION" in
n | new)
  new
  exec -- true
  ;;
r | run)
  SMBIOS="$("$DIR/libexec/authorized_keys.sh")"
  SSH_CONN="${SSH:-"127.0.0.1:$("$DIR/libexec/ssh-port.sh")"}"

  QARGV=(
    "$DIR/libexec/run.sh"
    --qmp "$QMP_SOCK"
    --monitor "$QM_SOCK"
    --smbios "$SMBIOS"
    --ssh "$SSH_CONN"
    --kernel "${KERNEL[@]}"
    --initrd "${INITRD[@]}"
    --drive "$DRIVE"
    --root "$FS_ROOT"
    --drive "$CLOUD_INIT"
  )
  if ! [[ -t 0 ]]; then
    QARGV+=(--console "$CON_SOCK")
  fi
  if ((VNC)); then
    QARGV+=(--vnc "unix:$VNC_SOCK")
  fi
  QARGV+=("$@")

  if ! [[ -f "$DRIVE" ]] || [[ -v FORK ]]; then
    new
  fi

  fwait "$ROOT"
  ssh_pp "$SSH_CONN"
  printf -- '%s' "$SSH_CONN" >"$SSH_LOCATION"
  exec -- flock "$ROOT" "${QARGV[@]}"
  ;;
l | ls)
  lsa
  exec -- true
  ;;
rm | remove)
  set -x
  if ! [[ -k "$ROOT" ]]; then
    mkdir -p -- "$ROOT" >&2
    exec -- flock --nonblock "$ROOT" rm -v -rf -- "$ROOT"
  else
    exit 1
  fi
  ;;
pin)
  exec -- chmod -v +t "$ROOT" >&2
  ;;
unpin)
  exec -- chmod -v -t "$ROOT" >&2
  ;;
v | vnc)
  SOCK="$VNC_SOCK"
  {
    nc -U -- "$QM_SOCK" <<<'set_password vnc root'
    open -u 'vnc://localhost'
  } >&2
  exec -- socat 'TCP-LISTEN:5900,reuseaddr,fork' "UNIX-CONNECT:$SOCK"
  ;;
c | console)
  SOCK="$CON_SOCK"
  ;;
s | ssh)
  LOCATION="$(<"$SSH_LOCATION")"
  ssh_pp "$LOCATION"
  AV=()
  if (($#)); then
    printf -v A -- '%q ' "$@"
    AV+=("$A")
  fi
  exec -- "${SSH_CMD[@]}" "$SSH_PORT" "$SSH_HOST" "${AV[@]}"
  ;;
m | monitor)
  SOCK="$QM_SOCK"
  ;;
q | qmp)
  SOCK="$QMP_SOCK"
  ;;
*)
  exec -- gmake -- help >&2
  ;;
esac

exec -- socat "READLINE,history=$SOCK.hist" "UNIX-CONNECT:$SOCK"
