#!/bin/sh
# install_vpn_ipcatcher.sh - safe installer/repair script for vpn_ipcatcher WebGUI setup
# Version: 2.10.9
set -e
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH

ADDON_DIR="/jffs/addons/vpn_ipcatcher.d"
ENGINE="/jffs/scripts/vpn_ipcatcher.sh"
CONF="/jffs/scripts/vpn_ipcatcher.conf"
WATCHDOG="/jffs/scripts/vpn_ipcatcher_watchdog.sh"
WEBUI="$ADDON_DIR/vpn_ipcatcher_webui.sh"
ASP="$ADDON_DIR/vpn_ipcatcher.asp"
SERVICE_EVENT="/jffs/scripts/service-event"
SERVICES_START="/jffs/scripts/services-start"
FIREWALL_START="/jffs/scripts/firewall-start"
LOG="/tmp/vpn_ipcatcher_install.log"

log(){ echo "$(date '+%F %T') $*" | tee -a "$LOG"; logger -t vpn_ipcatcher_install "$*" 2>/dev/null; }

ensure_file(){
  f="$1"
  if [ ! -f "$f" ]; then
    log "ERROR: Bestand ontbreekt: $f"
    return 1
  fi
  return 0
}

# Backups of the shared Merlin hook scripts live in our own addon folder
# (Addons API: keep /jffs/scripts clean), at most HOOK_BACKUP_KEEP per hook.
HOOK_BACKUP_DIR="$ADDON_DIR/hook-backups"
HOOK_BACKUP_KEEP=3

prune_hook_backups(){
  base="$1"
  # Names carry a sortable timestamp; keep the newest HOOK_BACKUP_KEEP.
  ls -1 "$HOOK_BACKUP_DIR" 2>/dev/null | grep -E "^${base}\.[0-9]{8}-[0-9]{6}" | sort -r |
    tail -n +$((HOOK_BACKUP_KEEP+1)) | while IFS= read -r old; do
      rm -f "$HOOK_BACKUP_DIR/$old"
    done
}

backup_file(){
  f="$1"
  [ -f "$f" ] || return 0
  mkdir -p "$HOOK_BACKUP_DIR" 2>/dev/null || return 0
  base="$(basename "$f")"
  cp -p "$f" "$HOOK_BACKUP_DIR/$base.$(date '+%Y%m%d-%H%M%S')" 2>/dev/null
  prune_hook_backups "$base"
}

# Older versions left a timestamped backup next to the hook on every run.
# Move only those (exact names this installer made) into the backup folder.
migrate_hook_backups(){
  for hook in "$SERVICE_EVENT" "$SERVICES_START" "$FIREWALL_START"; do
    base="$(basename "$hook")"
    found=0
    for old in "$hook".bak.[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9] \
               "$hook".bak-vpnipc-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]; do
      [ -f "$old" ] || continue
      mkdir -p "$HOOK_BACKUP_DIR" 2>/dev/null || return 0
      stamp="$(printf '%s\n' "$old" | sed -n 's/.*\([0-9]\{8\}-[0-9]\{6\}\)$/\1/p')"
      mv -f "$old" "$HOOK_BACKUP_DIR/$base.$stamp" 2>/dev/null && found=1
    done
    [ "$found" = 1 ] && prune_hook_backups "$base"
  done
  return 0
}

# Remove our marker blocks plus the blank lines right before them and at the
# end of the file, so reinstalling never grows the hook by a blank line.
strip_blocks(){
  awk -v begin="$2" -v end="$3" '
    skip { if ($0 ~ end) skip=0; next }
    $0 ~ begin { pend=0; skip=1; next }
    /^[[:space:]]*$/ { pend++; next }
    { while (pend > 0) { print ""; pend-- } print }
  ' "$1"
}

# Install tmp over hook only when the content really changed.
replace_hook(){
  hook="$1"; tmp="$2"; label="$3"
  sh -n "$tmp" || { rm -f "$tmp"; log "FOUT: $label niet geldig, niets gewijzigd."; return 1; }
  if cmp -s "$tmp" "$hook"; then
    rm -f "$tmp"
    chmod 755 "$hook"
    log "$label ongewijzigd."
    return 0
  fi
  backup_file "$hook"
  mv "$tmp" "$hook"
  chmod 755 "$hook"
  log "$label bijgewerkt."
}

ensure_executable(){
  f="$1"
  [ -f "$f" ] && chmod 755 "$f" 2>/dev/null
}

install_service_event_block(){
  [ -f "$SERVICE_EVENT" ] || {
    cat > "$SERVICE_EVENT" <<'EOS'
#!/bin/sh
EOS
  }
  tmp="${SERVICE_EVENT}.$$"
  strip_blocks "$SERVICE_EVENT" \
    '# BEGIN vpn_ipcatcher WebGUI|### vpn_ipcatcher WebUI start' \
    '# END vpn_ipcatcher WebGUI|### vpn_ipcatcher WebUI end' > "$tmp" 2>/dev/null

  cat >> "$tmp" <<'EOS'

# BEGIN vpn_ipcatcher WebGUI
# Handles ASUS/Merlin WebUI action_script=restart_vpnipcatcher.
case "$1" in
  restart)
    case "$2" in
      vpnipcatcher|vpn_ipcatcher|vpnipcatcher_webui|vipcR*|vipcA*|vipcZ*|vipcX*|vipcD*|vipcE)
        /jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh service_event "$@"
      ;;
    esac
  ;;
esac
# END vpn_ipcatcher WebGUI
EOS

  replace_hook "$SERVICE_EVENT" "$tmp" service-event
}

install_services_start_block(){
  [ -f "$SERVICES_START" ] || {
    cat > "$SERVICES_START" <<'EOS'
#!/bin/sh
EOS
  }
  tmp="${SERVICES_START}.$$"
  strip_blocks "$SERVICES_START" \
    '# BEGIN vpn_ipcatcher (startup|SAFE)' \
    '# END vpn_ipcatcher (startup|SAFE)' > "$tmp" 2>/dev/null

  cat >> "$tmp" <<'EOS'

# BEGIN vpn_ipcatcher startup
# Mount WebGUI page and keep status/watchdog active after reboot.
/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh mount >/dev/null 2>&1
/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh cron >/dev/null 2>&1
cru d vpn_ipcatcher_watchdog >/dev/null 2>&1
cru a vpn_ipcatcher_watchdog "* * * * * /jffs/scripts/vpn_ipcatcher_watchdog.sh" >/dev/null 2>&1
# Start engine at boot. If already running, this does nothing harmful.
/jffs/scripts/vpn_ipcatcher.sh watchdog >/dev/null 2>&1
# END vpn_ipcatcher startup
EOS

  replace_hook "$SERVICES_START" "$tmp" services-start
}

install_firewall_start_block(){
  [ -f "$FIREWALL_START" ] || printf '#!/bin/sh\n' > "$FIREWALL_START"
  tmp="${FIREWALL_START}.$$"
  strip_blocks "$FIREWALL_START" '# BEGIN vpn_ipcatcher firewall' '# END vpn_ipcatcher firewall' > "$tmp"
  cat >> "$tmp" <<'EOS'

# BEGIN vpn_ipcatcher firewall
# Restore our managed marks; existing DVR policies remain owned by DVR.
/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh prepare >/dev/null 2>&1 &
# END vpn_ipcatcher firewall
EOS
  replace_hook "$FIREWALL_START" "$tmp" firewall-start
}

main(){
  migrate_hook_backups
  if [ "${1:-}" = hooks ]; then
    install_service_event_block
    install_services_start_block
    install_firewall_start_block
    return
  fi
  mkdir -p "$ADDON_DIR" /jffs/scripts /www/user 2>/dev/null

  ok=1
  ensure_file "$ENGINE" || ok=0
  ensure_file /jffs/scripts/vpn_ipcatcher.real.sh || ok=0
  ensure_file "$ADDON_DIR/vpn_ipcatcher_presets.sh" || ok=0
  ensure_file "$ADDON_DIR/vpn_ipcatcher_update.sh" || ok=0
  ensure_file "$ADDON_DIR/vpn_ipcatcher_doctor.sh" || ok=0
  ensure_file "$ADDON_DIR/vpn_ipcatcher_health.sh" || ok=0
  ensure_file "$ADDON_DIR/vpn_ipcatcher_routing.sh" || ok=0
  ensure_file "$CONF" || ok=0
  ensure_file "$WATCHDOG" || ok=0
  ensure_file "$WEBUI" || ok=0
  ensure_file "$ASP" || ok=0
  [ "$ok" = "1" ] || { log "Installatie afgebroken: eerst ontbrekende bestanden plaatsen."; exit 1; }

  ensure_executable "$ENGINE"
  ensure_executable /jffs/scripts/vpn_ipcatcher.real.sh
  ensure_executable "$ADDON_DIR/vpn_ipcatcher_update.sh"
  ensure_executable "$ADDON_DIR/vpn_ipcatcher_doctor.sh"
  ensure_executable "$ADDON_DIR/vpn_ipcatcher_health.sh"
  ensure_executable "$ADDON_DIR/vpn_ipcatcher_routing.sh"
  ensure_executable "$WATCHDOG"
  ensure_executable "$WEBUI"
  ensure_executable "$0"
  chmod 600 "$CONF" 2>/dev/null
  chmod 644 "$ASP" 2>/dev/null

  "$ADDON_DIR/vpn_ipcatcher_routing.sh" install-dependencies
  "$ENGINE" stop
  # Choose the tunnel and policy interactively before registering startup.
  if [ -s "$ADDON_DIR/routing-selection" ]; then
    "$ADDON_DIR/vpn_ipcatcher_routing.sh" prepare
  else
    "$ADDON_DIR/vpn_ipcatcher_routing.sh" configure
    # First installation: offer to choose the IPTV devices right away, so
    # learning is limited to them from the start instead of all devices.
    if [ -t 0 ]; then
      printf '\nWil je nu je IPTV-box(en) of tv kiezen? Dan leert IP Catcher alleen van die apparaten. (J/n): '
      read -r choose_answer || choose_answer=n
      case "$choose_answer" in
        n|N|nee|Nee) log "IPTV-apparaten later kiezen via amtm (5 > 7) of de WebGUI." ;;
        *) SUPPRESS_RESTART_PROMPT=1 "$ENGINE" choose-devices || true ;;
      esac
    fi
  fi

  install_service_event_block
  install_services_start_block
  install_firewall_start_block

  log "Cron jobs instellen."
  /jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh cron >/dev/null 2>&1
  cru d vpn_ipcatcher_watchdog >/dev/null 2>&1
  cru a vpn_ipcatcher_watchdog "* * * * * /jffs/scripts/vpn_ipcatcher_watchdog.sh" >/dev/null 2>&1

  log "WebGUI mounten."
  rc=0
  /jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh mount >/tmp/vpn_ipcatcher_webui_mount.out 2>&1 || rc=$?
  if [ "$rc" != "0" ]; then
    log "WAARSCHUWING: WebGUI mount gaf exitcode $rc. Bekijk /tmp/vpn_ipcatcher_webui_mount.out"
  fi

  log "Status publiceren."
  "$ENGINE" start
  /jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh publish >/dev/null 2>&1

  log "Klaar. Test met: /jffs/scripts/vpn_ipcatcher.sh status"
  log "Open daarna ASUS WebUI > Tools. Als tab niet zichtbaar is, router WebUI verversen of opnieuw inloggen."
}

main "$@"
