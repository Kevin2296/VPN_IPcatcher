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
[ -f "$TMP/runtime/vpn_ipcatcher.disabled" ]
sh "$TMP/guard" watchdog
[ "$(cat "$STATE")" = stop ]
sh "$TMP/guard" start
[ ! -f "$TMP/runtime/vpn_ipcatcher.disabled" ]
[ "$(cat "$STATE")" = "$(printf 'stop\nstart')" ]
: > "$TMP/jffs/addons/vpn_ipcatcher.d/updating"
sh "$TMP/guard" watchdog
if sh "$TMP/guard" start; then echo 'Started during update'; exit 1; fi
[ "$(cat "$STATE")" = "$(printf 'stop\nstart')" ]
[ ! -d "$TMP/runtime/vpn_ipcatcher_lifecycle.lock" ]
rm "$TMP/jffs/addons/vpn_ipcatcher.d/updating"
# Repeated watchdog calls model an unexpected engine exit after explicit Start.
sh "$TMP/guard" watchdog
[ "$(tail -n 1 "$STATE")" = start ]
sh "$TMP/guard" stop
sh "$TMP/guard" watchdog
[ "$(tail -n 1 "$STATE")" = stop ]
# A reboot clears volatile /tmp, but preserves the addon directory.
rm "$TMP/runtime/vpn_ipcatcher.disabled"
sh "$TMP/guard" watchdog
[ "$(tail -n 1 "$STATE")" = start ]
echo 'PASS: stop suppresses watchdog until Start or reboot; crash recovery resumes; update blocks starts'
