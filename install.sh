#!/bin/sh
# Public bootstrap: downloads verified program files, never private configuration.
set -eu
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
REPO="Kevin2296/VPN_IPcatcher"
ENGINE="/jffs/scripts/vpn_ipcatcher.sh"
ADDON="/jffs/addons/vpn_ipcatcher.d"
FILES='scripts/vpn_ipcatcher.sh scripts/vpn_ipcatcher.real.sh scripts/vpn_ipcatcher_watchdog.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_presets.sh addons/vpn_ipcatcher.d/vpn_ipcatcher.asp addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_doctor.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh'
fail(){ echo "Installatie: $*" >&2; exit 1; }
find_bin(){ for directory in /opt/bin /opt/sbin /usr/sbin /usr/bin /sbin /bin; do [ -f "$directory/$1" ] && [ -x "$directory/$1" ] && { echo "$directory/$1"; return; }; done; return 1; }
action="${1:-install}"
case "$action" in install|update) ;; *) fail 'Gebruik: sh install.sh install|update' ;; esac
[ "$(id -u)" = 0 ] || fail 'Voer dit uit als root op de router.'
[ -t 0 ] || fail 'Open een interactief SSH-venster; stuur het script niet via een pipe naar sh.'
if ! find_bin jq >/dev/null && [ -x /opt/bin/opkg ]; then /opt/bin/opkg update && /opt/bin/opkg install jq; fi
for tool in curl jq sha256sum awk sed grep; do find_bin "$tool" >/dev/null || fail "Ontbreekt: $tool. Installeer eerst via Entware/amtm."; done
if [ "$action" = install ]; then
  [ ! -e "$ENGINE" ] && [ ! -e /jffs/scripts/vpn_ipcatcher.real.sh ] || fail 'Bestaande installatie gevonden. Gebruik update, niet install.'
  [ "$(nvram get jffs2_scripts)" = 1 ] || fail 'Schakel JFFS custom scripts en configs in.'
else
  [ -s "$ENGINE" ] && [ -s "$ADDON/vpn_ipcatcher_update.sh" ] || fail 'Deze oude installatie heeft geen veilige updater. Maak eerst een back-up; automatische legacy-migratie wordt niet uitgevoerd.'
fi
umask 077
STAGE="/tmp/vpnipc-install-$(date +%s)-$$"
mkdir "$STAGE" || fail 'Tijdelijke map kon niet worden aangemaakt.'
trap 'rm -rf "$STAGE"' EXIT
trap 'exit 1' HUP INT TERM
curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 "https://api.github.com/repos/$REPO/commits/main" -o "$STAGE/commit.json"
commit="$(jq -r '.sha // empty' "$STAGE/commit.json")"
printf '%s\n' "$commit" | grep -Eq '^[0-9a-f]{40}$' || fail 'Geen geldige GitHub-commit ontvangen.'
base="https://raw.githubusercontent.com/$REPO/$commit"
download(){ curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 120 "$base/$1" -o "$STAGE/$1"; }
download SHA256SUMS
for relative in $FILES; do
  mkdir -p "$STAGE/$(dirname "$relative")"
  download "$relative"
  [ -s "$STAGE/$relative" ] || fail "Leeg bestand: $relative"
  expected="$(awk -v path="$relative" '$2==path {print $1; n++} END {if(n!=1) exit 1}' "$STAGE/SHA256SUMS")" || fail "Checksum ontbreekt: $relative"
  printf '%s\n' "$expected" | grep -Eq '^[0-9a-f]{64}$' || fail 'Ongeldige checksum.'
  actual="$(sha256sum "$STAGE/$relative")"; actual="${actual%% *}"
  [ "$actual" = "$expected" ] || fail "Checksum verschilt: $relative"
  case "$relative" in *.sh) sh -n "$STAGE/$relative" ;; esac
done
if [ "$action" = update ]; then
  # Use the new updater to support migration to a newly added program file.
  "$ENGINE" update-source "$REPO" "$commit"
  sh "$STAGE/addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh" update
  "$ENGINE" update-source "$REPO" main
  exit 0
fi
sh "$STAGE/addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh" install-dependencies
for relative in $FILES; do
  [ ! -e "/jffs/$relative" ] || fail "Bestaand bestand gevonden: $relative. Gebruik geen eerste installatie."
done
for relative in $FILES; do
  mkdir -p "/jffs/$(dirname "$relative")"
  cp "$STAGE/$relative" "/jffs/$relative.new"
  case "$relative" in *.sh) chmod 755 "/jffs/$relative.new" ;; *) chmod 644 "/jffs/$relative.new" ;; esac
  mv "/jffs/$relative.new" "/jffs/$relative"
done
# The wizard fills in the policy and interfaces; all other engine defaults apply.
if [ ! -f /jffs/scripts/vpn_ipcatcher.conf ]; then
  printf '# VPN IP Catcher settings; configured by the installation wizard.\n' > /jffs/scripts/vpn_ipcatcher.conf
  chmod 600 /jffs/scripts/vpn_ipcatcher.conf
fi
sh "$ADDON/install_vpn_ipcatcher.sh"
"$ENGINE" update-source "$REPO" main
echo 'Installatie voltooid. Controleer de verkeersroute op de router.'
