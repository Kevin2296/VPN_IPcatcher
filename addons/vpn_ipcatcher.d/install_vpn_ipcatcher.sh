#!/bin/sh
# install_vpn_ipcatcher.sh - safe installer/repair script for vpn_ipcatcher WebGUI setup
# Version: 2.6.1
set -e

ADDON_DIR="/jffs/addons/vpn_ipcatcher.d"
ENGINE="/jffs/scripts/vpn_ipcatcher.sh"
CONF="/jffs/scripts/vpn_ipcatcher.conf"
WATCHDOG="/jffs/scripts/vpn_ipcatcher_watchdog.sh"
WEBUI="$ADDON_DIR/vpn_ipcatcher_webui.sh"
ASP="$ADDON_DIR/vpn_ipcatcher.asp"
SERVICE_EVENT="/jffs/scripts/service-event"
SERVICES_START="/jffs/scripts/services-start"
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

backup_file(){
  f="$1"
  [ -f "$f" ] || return 0
  cp "$f" "${f}.bak.$(date '+%Y%m%d-%H%M%S')" 2>/dev/null
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
  backup_file "$SERVICE_EVENT"

  tmp="${SERVICE_EVENT}.$$"
  awk '
    /# BEGIN vpn_ipcatcher WebGUI/{skip=1; next}
    /# END vpn_ipcatcher WebGUI/{skip=0; next}
    /### vpn_ipcatcher WebUI start/{skip=1; next}
    /### vpn_ipcatcher WebUI end/{skip=0; next}
    skip!=1 {print}
  ' "$SERVICE_EVENT" > "$tmp" 2>/dev/null

  cat >> "$tmp" <<'EOS'

# BEGIN vpn_ipcatcher WebGUI
# Handles ASUS/Merlin WebUI action_script=restart_vpnipcatcher.
case "$1" in
  restart)
    case "$2" in
      vpnipcatcher|vpn_ipcatcher|vpnipcatcher_webui|vipcR*|vipcA*|vipcZ*|vipcX*)
        /jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh service_event "$@"
      ;;
    esac
  ;;
esac
# END vpn_ipcatcher WebGUI
EOS

  sh -n "$tmp"
  mv "$tmp" "$SERVICE_EVENT"
  chmod 755 "$SERVICE_EVENT"
  log "service-event bijgewerkt."
}

install_services_start_block(){
  [ -f "$SERVICES_START" ] || {
    cat > "$SERVICES_START" <<'EOS'
#!/bin/sh
EOS
  }
  backup_file "$SERVICES_START"

  tmp="${SERVICES_START}.$$"
  awk '
    /# BEGIN vpn_ipcatcher startup/{skip=1; next}
    /# END vpn_ipcatcher startup/{skip=0; next}
    /# BEGIN vpn_ipcatcher SAFE/{skip=1; next}
    /# END vpn_ipcatcher SAFE/{skip=0; next}
    skip!=1 {print}
  ' "$SERVICES_START" > "$tmp" 2>/dev/null

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

  sh -n "$tmp"
  mv "$tmp" "$SERVICES_START"
  chmod 755 "$SERVICES_START"
  log "services-start bijgewerkt."
}

main(){
  mkdir -p "$ADDON_DIR" /jffs/scripts /www/user 2>/dev/null

  ok=1
  ensure_file "$ENGINE" || ok=0
  ensure_file /jffs/scripts/vpn_ipcatcher.real.sh || ok=0
  ensure_file "$ADDON_DIR/vpn_ipcatcher_presets.sh" || ok=0
  ensure_file "$ADDON_DIR/vpn_ipcatcher_update.sh" || ok=0
  ensure_file "$ADDON_DIR/vpn_ipcatcher_doctor.sh" || ok=0
  ensure_file "$CONF" || ok=0
  ensure_file "$WATCHDOG" || ok=0
  ensure_file "$WEBUI" || ok=0
  ensure_file "$ASP" || ok=0
  [ "$ok" = "1" ] || { log "Installatie afgebroken: eerst ontbrekende bestanden plaatsen."; exit 1; }

  ensure_executable "$ENGINE"
  ensure_executable /jffs/scripts/vpn_ipcatcher.real.sh
  ensure_executable "$ADDON_DIR/vpn_ipcatcher_update.sh"
  ensure_executable "$ADDON_DIR/vpn_ipcatcher_doctor.sh"
  ensure_executable "$WATCHDOG"
  ensure_executable "$WEBUI"
  ensure_executable "$0"
  chmod 600 "$CONF" 2>/dev/null
  chmod 644 "$ASP" 2>/dev/null

  install_service_event_block
  install_services_start_block

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
  /jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh publish >/dev/null 2>&1

  log "Klaar. Test met: /jffs/scripts/vpn_ipcatcher.sh status"
  log "Open daarna ASUS WebUI > Tools. Als tab niet zichtbaar is, router WebUI verversen of opnieuw inloggen."
}

main "$@"
