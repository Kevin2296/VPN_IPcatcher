#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/vpnipc-google-play-$$"
mkdir "$TMP"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
EXPECTED='dl.google.com play.googleapis.com android.clients.google.com redirector.gvt1.com'
sed '/^case "\$1" in/,$d' "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$TMP/library"
set +e
. "$TMP/library"
set -e
AWK=awk; SED=sed; GREP=grep; TR=tr; TAIL=tail
[ "$(preset_domains upd_google_play)" = "$EXPECTED" ]
[ "$(preset_label upd_google_play)" = "Google Play Store / app downloads" ]
CONF="$TMP/config"
default_config > "$CONF"
load_config
[ "$SOURCE_IPS" = "" ]
[ "$(preset_is_active upd_google_play)" = off ]
for domain in $EXPECTED; do
  case " $EXCLUDE_DOMAINS " in *" $domain "*) echo "Unexpected Google Play default: $domain" >&2; exit 1 ;; esac
done
EXCLUDE_DOMAINS='dl.google.com'
[ "$(preset_is_active upd_google_play)" = PART ]
EXCLUDE_DOMAINS="$EXPECTED"
[ "$(preset_is_active upd_google_play)" = ON ]
EXCLUDE_RESOLVE_CACHE=yes
CACHE_EXCLUDE_IPS="$TMP/cached-ips"
printf '142.250.102.136 dl.google.com\n142.250.102.137 unrelated.example\n' > "$CACHE_EXCLUDE_IPS"
ip_in_resolved_exclude_cache 142.250.102.136
if ip_in_resolved_exclude_cache 142.250.102.137; then echo 'Unexpected IP excluded' >&2; exit 1; fi
EXCLUDE_DOMAINS=''
if ip_in_resolved_exclude_cache 142.250.102.136; then echo 'Disabled preset still active' >&2; exit 1; fi
. "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_presets.sh"
[ "$(preset_domains upd_google_play)" = "$EXPECTED" ]
[ "$(preset_label upd_google_play)" = "Google Play Store / app downloads" ]
case " $(preset_keys_for_category 'OS / app updates') " in *' upd_google_play '*) ;; *) echo 'Google Play missing from group' >&2; exit 1 ;; esac
preset_write_json "$TMP/presets.json"
grep -q '"key":"upd_google_play"' "$TMP/presets.json"
grep -q '"dl.google.com"' "$TMP/presets.json"
grep -q "upd_google_play:'Google Play Store / app-downloads'" "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher.asp"
echo 'PASS: Google Play opt-in, domain registry, locale, cached IPv4 and all source devices'
