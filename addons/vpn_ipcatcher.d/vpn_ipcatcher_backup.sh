#!/bin/sh
# Version: 2.9.0
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
selection="${2:-}"
confirmation="${3:-}"
case "$mode" in small|full|list|delete|prune-small|prune-code) ;; *) echo 'Gebruik: backup small|full|list|delete NAAM --confirmed|prune-small --confirmed|prune-code --confirmed' >&2; exit 1 ;; esac
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
[ ! -L "$DIRECTORY" ] || { echo 'Back-upmap mag geen symlink zijn.' >&2; exit 1; }
valid_archive(){
  printf '%s\n' "$1" | grep -Eq '^vpn-ipcatcher-(small|full|[0-9]{8})-[0-9-]+\.tar\.gz$'
}
if [ "$mode" = list ]; then
  for archive in "$DIRECTORY"/vpn-ipcatcher-*.tar.gz; do
    [ -f "$archive" ] && [ ! -L "$archive" ] || continue
    valid_archive "${archive##*/}" || continue
    printf '%s  %s bytes\n' "${archive##*/}" "$(wc -c < "$archive")"
  done
  exit 0
fi
if [ "$mode" = delete ]; then
  [ "$confirmation" = --confirmed ] && valid_archive "$selection" || { echo 'Ongeldige naam of bevestiging ontbreekt.' >&2; exit 1; }
  archive="$DIRECTORY/$selection"
  [ -f "$archive" ] && [ ! -L "$archive" ] || { echo 'Back-up bestaat niet of is een symlink.' >&2; exit 1; }
  rm -f "$archive"
  echo 'Geselecteerde archiefback-up verwijderd. Programmaherstel blijft behouden.'
  exit 0
fi
if [ "$mode" = prune-small ]; then
  [ "$selection" = --confirmed ] || { echo 'Bevestiging ontbreekt.' >&2; exit 1; }
  count=0
  for name in $(printf '%s\n' "$DIRECTORY"/vpn-ipcatcher-small-*.tar.gz | sort -r); do
    [ -f "$name" ] && [ ! -L "$name" ] || continue
    valid_archive "${name##*/}" || continue
    count=$((count + 1))
    [ "$count" -le 5 ] || rm -f "$name"
  done
  echo 'Laatste vijf kleine archiefback-ups behouden. Uitgebreide back-ups en programmaherstel zijn niet gewijzigd.'
  exit 0
fi
if [ "$mode" = prune-code ]; then
  [ "$selection" = --confirmed ] || { echo 'Bevestiging ontbreekt.' >&2; exit 1; }
  [ ! -L "$ADDON" ] && [ ! -L "$ADDON/backups" ] || { echo 'Programma-back-upmap mag geen symlink zijn.' >&2; exit 1; }
  protected="$(cat "$ADDON/last-backup" 2>/dev/null || true)"
  count=0
  for directory in $(printf '%s\n' "$ADDON"/backups/update-* | sort -r); do
    [ -d "$directory" ] && [ ! -L "$directory" ] || continue
    printf '%s\n' "${directory##*/}" | grep -Eq '^update-[0-9]{8}-[0-9]{6}-[0-9]+$' || continue
    [ ! -f "$directory/legacy-migration" ] || continue
    count=$((count + 1))
    [ "$count" -gt 2 ] && [ "$directory" != "$protected" ] || continue
    case "$directory" in "$ADDON"/backups/update-*) rm -rf "$directory" ;; esac
  done
  echo 'Laatste twee programmakopieen, actief herstelpunt en legacy-migratie bewaard.'
  exit 0
fi
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
printf 'Prive-back-up: %s\n' "$ARCHIVE"
echo 'Alleen lokaal bewaren; geen volledige routerback-up.'
