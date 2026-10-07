#!/bin/sh
# Version: 2.8.3
# Archives stay private on the router, never under /www.
set -eu
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
umask 077
ADDON=/jffs/addons/vpn_ipcatcher.d
UPDATE_LOCK=/tmp/vpn_ipcatcher_update.lock
CONFIG_LOCK=/tmp/vpn_ipcatcher_config.lock
DIRECTORY=/jffs/vpn-ipcatcher-backups
OWN_UPDATE=0
OWN_CONFIG=0
ARCHIVE=''
mode="${1:-small}"
case "$mode" in small|full) ;; *) echo 'Gebruik: backup small|full' >&2; exit 1 ;; esac
effective_uid(){
  for directory in /opt/bin /opt/sbin /usr/sbin /usr/bin /sbin /bin; do
    if [ -f "$directory/id" ] && [ -x "$directory/id" ]; then "$directory/id" -u; return; fi
  done
  [ -r /proc/self/status ] || return 1
  while read -r field real effective rest; do
    case "$field" in Uid:) printf '%s\n' "$effective"; return 0 ;; esac
  done < /proc/self/status
  return 1
}
[ "$(effective_uid)" = 0 ] || { echo 'Rootrechten konden niet worden bevestigd; back-up afgebroken.' >&2; exit 1; }
finish(){
  result=$?
  trap - EXIT
  [ -z "$ARCHIVE" ] || rm -f "$ARCHIVE.new"
  if [ "$OWN_CONFIG" = 1 ]; then rm -f "$CONFIG_LOCK/pid"; rmdir "$CONFIG_LOCK" 2>/dev/null || true; fi
  if [ "$OWN_UPDATE" = 1 ]; then rm -f "$UPDATE_LOCK/pid"; rmdir "$UPDATE_LOCK" 2>/dev/null || true; fi
  exit "$result"
}
trap finish EXIT
trap 'exit 1' HUP INT TERM
if [ "${2:-}" = --update-owner ]; then
  # The updater already holds this lock; only its direct child may reuse it.
  parent="${PPID:-}"
  [ -n "$parent" ] || parent="$(awk '$1=="PPid:" {print $2; exit}' "/proc/$$/status")"
  [ "${3:-}" = "$parent" ] && [ "$(cat "$UPDATE_LOCK/pid" 2>/dev/null)" = "$parent" ] || {
    echo 'Ongeldige update-lock eigenaar.' >&2; exit 1;
  }
else
  mkdir "$UPDATE_LOCK" 2>/dev/null || { echo 'Update/back-up bezig. Probeer later opnieuw.' >&2; exit 1; }
  OWN_UPDATE=1
  echo $$ > "$UPDATE_LOCK/pid"
fi
mkdir "$CONFIG_LOCK" 2>/dev/null || { echo 'Configuratie wordt gewijzigd. Probeer later opnieuw.' >&2; exit 1; }
OWN_CONFIG=1
echo $$ > "$CONFIG_LOCK/pid"
set --
for relative in scripts/vpn_ipcatcher.sh scripts/vpn_ipcatcher.real.sh scripts/vpn_ipcatcher.conf \
  scripts/vpn_ipcatcher_watchdog.sh scripts/services-start scripts/services-stop \
  scripts/service-event scripts/service-event-end scripts/firewall-start scripts/wan-event \
  scripts/wgclient-start scripts/openvpn-event scripts/dnsmasq.postconf scripts/dnsmasq-sdn.postconf \
  addons/amtm/personalscript.conf; do
  [ ! -e "/jffs/$relative" ] || set -- "$@" "$relative"
done
if [ "$mode" = full ]; then
  for relative in addons/vpn_ipcatcher.d addons/vpn-ipcatcher.d configs/domain_vpn_routing scripts/domain_vpn_routing.sh; do
    [ ! -e "/jffs/$relative" ] || set -- "$@" "$relative"
  done
else
  for file in "$ADDON"/*.sh "$ADDON"/*.asp "$ADDON"/*.conf "$ADDON"/routing-selection "$ADDON"/update-source; do
    [ ! -f "$file" ] || set -- "$@" "${file#/jffs/}"
  done
fi
[ "$#" -gt 0 ] || { echo 'Geen bestaande addonbestanden of hooks om te bewaren (nieuwe installatie).'; exit 0; }
mkdir -p "$DIRECTORY"
chmod 700 "$DIRECTORY"
ARCHIVE="$DIRECTORY/vpn-ipcatcher-$mode-$(date +%Y%m%d-%H%M%S)-$$.tar.gz"
tar -czf "$ARCHIVE.new" -C /jffs "$@"
chmod 600 "$ARCHIVE.new"
mv "$ARCHIVE.new" "$ARCHIVE"
printf '\nPrive-back-up gereed:\n%s\n' "$ARCHIVE"
echo 'Niet uploaden naar GitHub. Download desgewenst via MobaXterm/SFTP.'
echo 'Geen volledige router/nvram-back-up. Oude archieven worden niet automatisch verwijderd.'
