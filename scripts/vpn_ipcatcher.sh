#!/bin/sh
# Version: 2.10.0
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
REAL="/jffs/scripts/vpn_ipcatcher.real.sh"
ADDON="/jffs/addons/vpn_ipcatcher.d"
# Temporary stop lasts for this boot only; /tmp is cleared on reboot.
DISABLED="/tmp/vpn_ipcatcher.disabled"
UPDATING="$ADDON/updating"
LIFECYCLE_LOCK="/tmp/vpn_ipcatcher_lifecycle.lock"
LOGFILE="/tmp/vpn_ipcatcher.log"

process_label(){
  (
    trace_pid="$1"
    case "$trace_pid" in ''|*[!0-9]*) printf 'unknown'; exit 0 ;; esac
    trace_name="$(awk '/^Name:/ {gsub(/[^A-Za-z0-9_.:-]/,"",$2);print substr($2,1,32);exit}' "/proc/$trace_pid/status" 2>/dev/null)"
    trace_script=''
    if [ -r "/proc/$trace_pid/cmdline" ]; then
      trace_script="$(tr '\000' '\n' < "/proc/$trace_pid/cmdline" 2>/dev/null | awk 'NR<=3 && /^\/jffs\/(scripts|addons)\// && !/[^A-Za-z0-9_.\/-]/ {sub(/^.*\//,"");print substr($0,1,64);exit}')"
    fi
    printf '%s' "${trace_name:-gone}"
    [ -z "$trace_script" ] || printf '/%s' "$trace_script"
    exit 0
  )
}
lifecycle_note(){
  (
    trace_parent="${PPID:-0}"
    trace_ancestor="$(awk '/^PPid:/ {print $2;exit}' "/proc/$trace_parent/status" 2>/dev/null)"
    trace_disabled=no; [ ! -f "$DISABLED" ] || trace_disabled=yes
    trace_updating=no; [ ! -f "$UPDATING" ] || trace_updating=yes
    trace_message="Lifecycle request=$1 pid=$$ parent=$trace_parent($(process_label "$trace_parent")) ancestor=${trace_ancestor:-0}($(process_label "${trace_ancestor:-0}")) disabled=$trace_disabled updating=$trace_updating"
    [ ! -L "$LOGFILE" ] || exit 0
    umask 077
    printf '%s %s\n' "$(date '+%F %T')" "$trace_message" >> "$LOGFILE"
    logger -t vpn_ipcatcher "$trace_message" 2>/dev/null || true
  )
}

# A numeric PID may be reused by an unrelated process. Verify that it is
# the real run engine before suppressing watchdog recovery.
watchdog_engine_alive(){
  checked_pid="$1"
  case "$checked_pid" in ''|*[!0-9]*|0|1) return 1 ;; esac
  kill -0 "$checked_pid" 2>/dev/null || return 1
  [ -r "/proc/$checked_pid/cmdline" ] || return 1
  checked_cmd="$(tr '\000' ' ' < "/proc/$checked_pid/cmdline" 2>/dev/null)"
  case "$checked_cmd" in
    *"/jffs/scripts/vpn_ipcatcher.real.sh run"*) return 0 ;;
  esac
  return 1
}

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

case "${1:-}" in
  start|stop|restart|routing-setup|update|force-update|rollback) lifecycle_note "$1" ;;
esac

case "$1" in
  auto-update)
    case "${2:-status}" in
      enable) mkdir -p "$ADDON" && (umask 077; : > "$ADDON/amtmupdate.enabled") ;;
      disable) rm -f "$ADDON/amtmupdate.enabled" ;;
      status) if [ -f "$ADDON/amtmupdate.enabled" ]; then echo enabled; else echo disabled; fi ;;
      *) exit 1 ;;
    esac
    ;;
  amtmupdate)
    [ -f "$ADDON/amtmupdate.enabled" ] && [ -s "$ADDON/update-source" ] && [ -x "$ADDON/vpn_ipcatcher_update.sh" ] || exit 1
    [ "${2:-}" != check ] || exit 0
    [ "$#" = 1 ] || exit 1
    update_log=/tmp/vpn_ipcatcher_amtmupdate.log
    if (umask 077; "$ADDON/vpn_ipcatcher_update.sh" automatic-update > "$update_log" 2>&1); then
      echo 'VPN IP Catcher: amtmupdate voltooid.'
      exit 0
    fi
    echo 'VPN IP Catcher: amtmupdate mislukt; lokaal log /tmp/vpn_ipcatcher_amtmupdate.log.' >&2
    exit 1
    ;;
  start|stop|restart|watchdog)
    lock || exit 1
    mkdir -p "$ADDON" || exit 1
    case "$1" in
      stop) : > "$DISABLED"; VPNIPC_INTERNAL=1 "$REAL" stop; exit $? ;;
      watchdog)
        { [ -f "$DISABLED" ] || [ -f "$UPDATING" ]; } && exit 0
        watchdog_pid="$(cat /tmp/vpn_ipcatcher_pids/engine.pid 2>/dev/null)"
        watchdog_engine_alive "$watchdog_pid" || lifecycle_note watchdog-recovery
        ;;
      start|restart)
        [ -f "$UPDATING" ] && { echo "Update bezig; start overgeslagen."; exit 1; }
        rm -f "$DISABLED"
        ;;
    esac
    [ "$1" = restart ] && VPNIPC_INTERNAL=1 "$REAL" stop
    VPNIPC_INTERNAL=1 "$REAL" start
    ;;
  run) exec "$REAL" run ;;
  check-update|update|force-update|update-source|rollback)
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
