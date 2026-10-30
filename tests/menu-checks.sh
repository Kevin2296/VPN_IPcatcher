#!/bin/sh
# 2.10: amtm menus - Dutch exclusion manager with all categories before the
# actions, E as back key everywhere, IPTV device chooser with toggling, and
# DHCP/ASUS client names. Mocked; no router commands run.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/vpnipc-menu-$$"
mkdir -p "$TMP/cache"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
sed '/^case "\$1" in/,$d' "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$TMP/library"
set +e
. "$TMP/library"
. "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_presets.sh"
set -e
AWK=awk; SED=sed; GREP=grep; TR=tr; TAIL=tail
CONF="$TMP/config"; CACHE_DIR="$TMP/cache"
default_config > "$CONF"
soft_clear(){ :; }; press_enter(){ :; }; maybe_restart_after_config_change(){ :; }

out="$(printf 'E\n' | preset_exclusion_menu)"
printf '%s\n' "$out" | grep -q 'Uitsluitingen en presets'
printf '%s\n' "$out" | grep -q ' 3) AI-assistenten'
printf '%s\n' "$out" | grep -q ' 9) Streamingdiensten'
printf '%s\n' "$out" | grep -q ' E) Terug'
if printf '%s\n' "$out" | grep -Eq 'Choose|Exclusion manager|1[0-9]\)'; then echo 'Exclusion menu still mixed/long'; exit 1; fi
last_category="$(printf '%s\n' "$out" | grep -n ' 9) Streamingdiensten' | cut -d: -f1)"
back_line="$(printf '%s\n' "$out" | grep -n ' E) Terug' | cut -d: -f1)"
[ "$last_category" -lt "$back_line" ]
if grep -q 'printf "Choose: "' "$ROOT/scripts/vpn_ipcatcher.real.sh"; then echo 'English prompt left'; exit 1; fi
echo 'PASS: Dutch exclusion manager lists all categories before actions and returns with E'

lan_device_list(){ printf '192.168.178.20 Woonkamer IPTV-box\n192.168.178.146 Slaapkamer TV\n192.168.178.14 Laptop\n'; }
printf '1 2\nE\n' | choose_source_devices >/dev/null
grep -qx 'SOURCE_IPS="192.168.178.20 192.168.178.146"' "$CONF"
printf '2 9\nE\n' | choose_source_devices > "$TMP/chooser"
grep -qx 'SOURCE_IPS="192.168.178.20"' "$CONF"
grep -q 'Ongeldige keuze overgeslagen: 9' "$TMP/chooser"
printf 'A\nE\n' | choose_source_devices >/dev/null
grep -qx 'SOURCE_IPS=""' "$CONF"
printf 'M\n999.1.1.1\nE\n' | choose_source_devices >/dev/null
grep -qx 'SOURCE_IPS=""' "$CONF"
[ "$(menu_action_key settings 7)" = 28 ]
[ "$(menu_action_key vpn 3)" = 27 ]
echo 'PASS: IPTV device chooser toggles, rejects invalid entries and resets to all devices'
