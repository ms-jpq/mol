#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ -L "$0" ]]; then
  DIR="${0%/*}"
  REAL="$DIR/$(readlink -- "$0")"
else
  REAL="$0"
fi

cd -- "${REAL%/*}"

BREW="$(brew --prefix)"
export -- BREW

OPTS='n:,a:'
LONG_OPTS='name:,action:,os:,vnc'
GO="$("$BREW/opt/gnu-getopt/bin/getopt" --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

NAME='_'
OS='ubuntu'
VNC=0
while (($#)); do
  case "$1" in
  -n | --name)
    NAME="$2"
    shift -- 2
    ;;
  -a | --action)
    ACTION="$2"
    shift -- 2
    ;;
  --os)
    OS="$2"
    shift -- 2
    ;;
  --vnc)
    VNC=1
    shift -- 1
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    exit 1
    ;;
  esac
done

ROOT="./var/$NAME.$OS.vm"
LOG="$ROOT/qemu.log"
QMP_SOCK="$ROOT/qmp.sock"
CON_SOCK="$ROOT/con.sock"
QM_SOCK="$ROOT/qm.sock"
VNC_SOCK="$ROOT/vnc.sock"
DRIVE="$ROOT/run.raw"

mkdir -v -p -- "$ROOT"

case "${ACTION:-"run"}" in
run)
  SMBIOS="$(./libexec/authorized_keys.sh)"
  SSH_CONN="${SSH:-"127.0.0.1:$(./libexec/ssh-port.sh)"}"
  SSH_HOST="${SSH_CONN%%:*}"
  SSH_PORT="${SSH_CONN##*:}"

  QARGV=(
    ./libexec/run.sh
    --log "$LOG"
    --qmp "$QMP_SOCK"
    --console "$CON_SOCK"
    --monitor "$QM_SOCK"
    --smbios "$SMBIOS"
    --ssh "$SSH_CONN"
    --drive "$DRIVE"
    --drive ./var/cloud-init.iso
  )
  if ((VNC)); then
    QARGV+=(--vnc "$VNC_SOCK")
  fi
  QARGV+=(-- "$@")

  set -x
  until flock --nonblock "$ROOT" true; do
    sleep -- 1
  done
  set +x

  flock "$ROOT" gmake --debug -- NAME="$NAME" "run.$OS"
  {
    printf -- '\n'
    printf -- '%q ' ssh -p "$SSH_PORT" -u root "$SSH_HOST"
    printf -- '\n\n'
  } >&2
  printf -- '%s' "$SSH_CONN" >"$ROOT/ssh.conn"
  flock "$ROOT" "${QARGV[@]}"
  ;;
rm | remove)
  set -x
  if ! [[ -k "$ROOT" ]]; then
    exec -- flock --nonblock "$ROOT" rm -v -rf -- "$ROOT"
  else
    exit 1
  fi
  ;;
lock)
  exec -- chmod -v +t "$ROOT"
  ;;
unlock)
  exec -- chmod -v -t "$ROOT"
  ;;
con | console)
  SOCK="$CON_SOCK"
  ;;
qmp)
  SOCK="$QMP_SOCK"
  ;;
qm | monitor)
  SOCK="$QM_SOCK"
  ;;
vnc)
  SOCK="$VNC_SOCK"
  ;;
*)
  exec -- gmake help
  ;;
esac

exec -- socat "READLINE,history=$SOCK.hist" "UNIX-CONNECT:$SOCK"
