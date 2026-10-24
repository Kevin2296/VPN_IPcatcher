#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
temp="/tmp/vpnipc-play-save-$$"
mkdir "$temp"
trap 'rm -rf "$temp"' EXIT HUP INT TERM
sed '/^case "\$1" in/,$d' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh" > "$temp/library"
set +e
SAVE_PATH="$PATH"
. "$temp/library"
PATH="$SAVE_PATH"
set -e
CONF="$temp/config"
CONFIG_WRITE_LOCK="$temp/conf-lock"
AWK="$(command -v awk)"
SED="$(command -v sed)"
TAIL="$(command -v tail)"
log(){ :; }
config_write_lock(){ mkdir "$CONFIG_WRITE_LOCK"; }
config_write_unlock(){ rmdir "$CONFIG_WRITE_LOCK"; }
cat > "$CONF" <<EOF
EXCLUDE_DOMAINS="play.googleapis.com android.clients.google.com"
EXCLUDE_IPS=""
EXCLUDE_NETS=""
SOURCE_IPS=""
STREAM_FLOW_TARGET="final"
EOF
cat > "$temp/delta" <<EOF
EXCLUDE_DOMAINS=play.googleapis.com android.clients.google.com dl.google.com redirector.gvt1.com
EOF
apply_stream_config "$temp/delta"
for domain in dl.google.com play.googleapis.com android.clients.google.com redirector.gvt1.com; do
  grep "^EXCLUDE_DOMAINS=" "$CONF" | grep -Fq "$domain" || { echo "Missing: $domain" >&2; exit 1; }
done
grep -q 'STREAM_FLOW_TARGET="final"' "$CONF"
grep -q 'SOURCE_IPS=""' "$CONF"
grep -q 'EXCLUDE_NETS=""' "$CONF"
echo "PASS: partial Google Play => full, unrelated config preserved"
