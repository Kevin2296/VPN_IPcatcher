#!/bin/sh
# Version: 2.8.4
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
REAL="/jffs/scripts/vpn_ipcatcher.real.sh"
ADDON="/jffs/addons/vpn_ipcatcher.d"
# Temporary stop lasts for this boot only; /tmp is cleared on reboot.
DISABLED="/tmp/vpn_ipcatcher.disabled"
UPDATING="$ADDON/updating"
LIFECYCLE_LOCK="/tmp/vpn_ipcatcher_lifecycle.lock"

lock(){
  tries=0
  while ! mkdir "$LIFECYCLE_LOCK" 2>/dev/null; do
    tries=$((tries+1))
    [ "$tries" -ge 30 ] && { echo "Service is bezig; probeer later opnieuw."; return 1; }
    oldpid="$(cat "$LIFECYCLE_LOCK/pid" 2>/dev/null)"
    # A missing PID may belong to a process that just acquired the lock.
    if [ -n "$oldpid" ] && ! kill -0 "$oldpid" 2>/dev/null; then
      rm -f "$LIFECYCLE_LOCK/pid"
      rmdir "$LIFECYCLE_LOCK" 2>/dev/null
    fi
    sleep 1
  done
  echo "$$" > "$LIFECYCLE_LOCK/pid"
  trap 'rm -f "$LIFECYCLE_LOCK/pid"; rmdir "$LIFECYCLE_LOCK" 2>/dev/null' EXIT
  trap 'exit 1' INT TERM
}

case "$1" in
  start|stop|restart|watchdog)
    lock || exit 1
    mkdir -p "$ADDON" || exit 1
    case "$1" in
      stop) : > "$DISABLED"; VPNIPC_INTERNAL=1 "$REAL" stop; exit $? ;;
      watchdog) { [ -f "$DISABLED" ] || [ -f "$UPDATING" ]; } && exit 0 ;;
      start|restart)
        [ -f "$UPDATING" ] && { echo "Update bezig; start overgeslagen."; exit 1; }
        rm -f "$DISABLED"
        ;;
    esac
    [ "$1" = restart ] && VPNIPC_INTERNAL=1 "$REAL" stop
    VPNIPC_INTERNAL=1 "$REAL" start
    ;;
  run) exec "$REAL" run ;;
  check-update|update|update-source|rollback)
    action="$1"; shift
    exec "$ADDON/vpn_ipcatcher_update.sh" "$action" "$@"
    ;;
  doctor) exec "$ADDON/vpn_ipcatcher_doctor.sh" ;;
  backup) shift; exec "$ADDON/vpn_ipcatcher_backup.sh" "$@" ;;
  amtm-add) exec "$ADDON/vpn_ipcatcher_amtm.sh" ;;
  routing-check) exec "$ADDON/vpn_ipcatcher_routing.sh" check ;;
  routing-list) exec "$ADDON/vpn_ipcatcher_routing.sh" list ;;
  routing-setup)
    lock || exit 1
    [ ! -f "$UPDATING" ] || { echo 'Update bezig; configuratie overgeslagen.'; exit 1; }
    : > "$DISABLED"
    VPNIPC_INTERNAL=1 "$REAL" stop || exit 1
    "$ADDON/vpn_ipcatcher_routing.sh" configure || exit 1
    rm -f "$DISABLED"
    VPNIPC_INTERNAL=1 "$REAL" start
    ;;
  guard-status) "$REAL" status ;;
  *) exec "$REAL" "$@" ;;
esac
