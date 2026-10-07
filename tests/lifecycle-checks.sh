#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/vpnipc-lifecycle-tests-$$"
mkdir -p "$TMP/jffs/scripts" "$TMP/jffs/addons/vpn_ipcatcher.d" "$TMP/runtime"
trap 'rm -rf "$TMP"' EXIT
STATE="$TMP/state"; export STATE
sed -e "s|/jffs/|$TMP/jffs/|g" -e "s|/tmp/vpn_ipcatcher|$TMP/runtime/vpn_ipcatcher|g" \
  "$ROOT/scripts/vpn_ipcatcher.sh" > "$TMP/guard"
cat > "$TMP/jffs/scripts/vpn_ipcatcher.real.sh" <<'EOF'
#!/bin/sh
[ "${VPNIPC_INTERNAL:-0}" = 1 ] || exit 1
printf '%s\n' "$1" >> "$STATE"
EOF
chmod 755 "$TMP/jffs/scripts/vpn_ipcatcher.real.sh"
sh "$TMP/guard" stop
[ -f "$TMP/jffs/addons/vpn_ipcatcher.d/disabled" ]
sh "$TMP/guard" watchdog
[ "$(cat "$STATE")" = stop ]
sh "$TMP/guard" start
[ ! -f "$TMP/jffs/addons/vpn_ipcatcher.d/disabled" ]
[ "$(cat "$STATE")" = "$(printf 'stop\nstart')" ]
: > "$TMP/jffs/addons/vpn_ipcatcher.d/updating"
sh "$TMP/guard" watchdog
if sh "$TMP/guard" start; then echo 'Started during update'; exit 1; fi
[ "$(cat "$STATE")" = "$(printf 'stop\nstart')" ]
[ ! -d "$TMP/runtime/vpn_ipcatcher_lifecycle.lock" ]
echo 'PASS: explicit stop survives watchdog; explicit start re-enables; update blocks starts'
