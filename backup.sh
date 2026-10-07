#!/bin/sh
# Private local archive: never upload this backup to GitHub.
set -eu
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
umask 077
[ "$(id -u)" = 0 ] || { echo 'Voer de back-up als root op de router uit.' >&2; exit 1; }
UPDATE_LOCK=/tmp/vpn_ipcatcher_update.lock
CONFIG_LOCK=/tmp/vpn_ipcatcher_config.lock
OWN_CONFIG=0
ARCHIVE=''
mkdir "$UPDATE_LOCK" 2>/dev/null || { echo 'Update/back-up vergrendeld. Probeer later opnieuw.' >&2; exit 1; }
echo $$ > "$UPDATE_LOCK/pid"
finish(){
  result=$?
  trap - EXIT
  [ -z "$ARCHIVE" ] || rm -f "$ARCHIVE.new"
  if [ "$OWN_CONFIG" = 1 ]; then rm -f "$CONFIG_LOCK/pid"; rmdir "$CONFIG_LOCK" 2>/dev/null || true; fi
  rm -f "$UPDATE_LOCK/pid"
  rmdir "$UPDATE_LOCK" 2>/dev/null || true
  exit "$result"
}
trap finish EXIT
trap 'exit 1' HUP INT TERM
mkdir "$CONFIG_LOCK" 2>/dev/null || { echo 'Configuratie wordt gewijzigd. Probeer later opnieuw.' >&2; exit 1; }
OWN_CONFIG=1
echo $$ > "$CONFIG_LOCK/pid"
set --
for relative in addons/vpn_ipcatcher.d addons/vpn-ipcatcher.d configs/domain_vpn_routing \
  scripts/vpn_ipcatcher.sh scripts/vpn_ipcatcher.real.sh scripts/vpn_ipcatcher.conf \
  scripts/vpn_ipcatcher_watchdog.sh scripts/domain_vpn_routing.sh \
  scripts/services-start scripts/services-stop scripts/service-event scripts/service-event-end \
  scripts/firewall-start scripts/wan-event scripts/wgclient-start scripts/openvpn-event \
  scripts/dnsmasq.postconf scripts/dnsmasq-sdn.postconf; do
  [ ! -e "/jffs/$relative" ] || set -- "$@" "$relative"
done
[ "$#" -gt 0 ] || { echo 'Geen bestanden gevonden voor de back-up.' >&2; exit 1; }
DIRECTORY=/jffs/vpn-ipcatcher-backups
mkdir -p "$DIRECTORY"
chmod 700 "$DIRECTORY"
ARCHIVE="$DIRECTORY/vpn-ipcatcher-$(date +%Y%m%d-%H%M%S)-$$.tar.gz"
tar -czf "$ARCHIVE.new" -C /jffs "$@"
chmod 600 "$ARCHIVE.new"
mv "$ARCHIVE.new" "$ARCHIVE"
printf '\nBack-up gereed (prive, niet uploaden naar GitHub):\n%s\n' "$ARCHIVE"
echo 'Download via de SFTP-zijbalk van MobaXterm. Geen volledige router/nvram-back-up.'
