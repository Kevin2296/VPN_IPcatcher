#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/vpnipc-update-tests-$$"
mkdir -p "$TMP/jffs/addons/vpn_ipcatcher.d" "$TMP/jffs/scripts" "$TMP/bin" "$TMP/runtime" "$TMP/remote"
trap 'rm -rf "$TMP"' EXIT
TEST_BIN="$TMP/bin"; TEST_REMOTE="$TMP/remote"; export TEST_BIN TEST_REMOTE
FILES="scripts/vpn_ipcatcher.sh scripts/vpn_ipcatcher.real.sh scripts/vpn_ipcatcher_watchdog.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_presets.sh addons/vpn_ipcatcher.d/vpn_ipcatcher.asp addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_doctor.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_backup.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_amtm.sh"
for f in $FILES; do
  mkdir -p "$TMP/remote/$(dirname "$f")"
  printf '#!/bin/sh\n# Version: 2.6.0\nexit 0\n' > "$TMP/jffs/$f"
  printf '#!/bin/sh\n# Version: 2.6.1\nexit 0\n' > "$TMP/remote/$f"
  chmod 755 "$TMP/jffs/$f"
done
printf 'PRIVATE_CONFIG_KEEP\n' > "$TMP/jffs/scripts/vpn_ipcatcher.conf"
printf 'ExamplePolicy\novpnc1\n' > "$TMP/jffs/addons/vpn_ipcatcher.d/routing-selection"
printf '2.6.1\n' > "$TMP/remote/VERSION"
(cd "$TMP/remote"; sha256sum $FILES) > "$TMP/remote/SHA256SUMS"
cat > "$TMP/bin/jq" <<'EOF'
#!/bin/sh
echo 1111111111111111111111111111111111111111
EOF
cat > "$TMP/bin/curl" <<'EOF'
#!/bin/sh
set -eu
url=''; out=''
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) out="$2"; shift ;;
    https:*) url="$1" ;;
  esac
  shift
done
case "$url" in
  https://api.github.com/*) printf '{}\n' > "$out" ;;
  https://raw.githubusercontent.com/*)
    relative="${url#*1111111111111111111111111111111111111111/}"
    cp "$TEST_REMOTE/$relative" "$out"
    ;;
  *) exit 1 ;;
esac
EOF
chmod 755 "$TMP/bin/curl" "$TMP/bin/jq"
sed -e "s|/jffs/|$TMP/jffs/|g" -e "s|/tmp/vpn_ipcatcher|$TMP/runtime/vpn_ipcatcher|g" \
  -e 's|^PATH=.*|PATH="$TEST_BIN:$PATH"|' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh" > "$TMP/updater"
sh "$TMP/updater" update-source example/vpn-ipcatcher main
sh "$TMP/updater" check-update
# A corrupt download must fail before any installed file is changed.
printf '#corrupt\n' >> "$TMP/remote/scripts/vpn_ipcatcher.real.sh"
if sh "$TMP/updater" update; then echo 'Corrupt update accepted'; exit 1; fi
grep -q '2.6.0' "$TMP/jffs/scripts/vpn_ipcatcher.sh"
echo 'PASS: corrupt update rejected without changing installed files'
(cd "$TMP/remote"; sha256sum $FILES) > "$TMP/remote/SHA256SUMS"
: > "$TMP/runtime/vpn_ipcatcher.disabled"
sh "$TMP/updater" update
grep -q '2.6.1' "$TMP/jffs/scripts/vpn_ipcatcher.sh"
grep -q PRIVATE_CONFIG_KEEP "$TMP/jffs/scripts/vpn_ipcatcher.conf"
[ -f "$TMP/runtime/vpn_ipcatcher.disabled" ]
[ ! -f "$TMP/jffs/addons/vpn_ipcatcher.d/updating" ]
echo 'PASS: update preserves configuration and intentionally stopped state'
sh "$TMP/updater" rollback
grep -q '2.6.0' "$TMP/jffs/scripts/vpn_ipcatcher.sh"
echo 'PASS: rollback restores the previous version'
# Simulate a live engine and a downloaded engine that cannot start.
mkdir -p "$TMP/runtime/vpn_ipcatcher_pids"
sleep 120 &
test_pid=$!
echo "$test_pid" > "$TMP/runtime/vpn_ipcatcher_pids/engine.pid"
printf '#!/bin/sh\nexit 1\n' > "$TMP/remote/scripts/vpn_ipcatcher.real.sh"
(cd "$TMP/remote"; sha256sum $FILES) > "$TMP/remote/SHA256SUMS"
if sh "$TMP/updater" update; then kill "$test_pid"; echo 'Failed startup accepted'; exit 1; fi
kill "$test_pid"
grep -q '2.6.0' "$TMP/jffs/scripts/vpn_ipcatcher.sh"
grep -q PRIVATE_CONFIG_KEEP "$TMP/jffs/scripts/vpn_ipcatcher.conf"
[ ! -f "$TMP/jffs/addons/vpn_ipcatcher.d/updating" ]
echo 'PASS: failed startup automatically restores previous files'
# A legacy installation has only the core scripts, private config and old hooks.
rm "$TMP/runtime/vpn_ipcatcher_pids/engine.pid"
for f in $FILES; do
  case "$f" in scripts/*) ;; *) rm -f "$TMP/jffs/$f" ;; esac
done
rm -f "$TMP/jffs/addons/vpn_ipcatcher.d/routing-selection"
printf '#!/bin/sh\n# Version: 2.6.1\nexit 0\n' > "$TMP/remote/scripts/vpn_ipcatcher.real.sh"
printf '#!/bin/sh\necho old-hook\n' > "$TMP/jffs/scripts/services-start"
printf '#!/bin/sh\necho old-event\n' > "$TMP/jffs/scripts/service-event"
export TEST_LEGACY_ROOT="$TMP/jffs"
cat > "$TMP/bin/cru" <<'EOF'
#!/bin/sh
case "$1" in
  l) echo '* * * * * old-watchdog #vpn_ipcatcher_watchdog#' ;;
  *) printf '%s\n' "$*" >> "$TEST_LEGACY_ROOT/cron-events" ;;
esac
EOF
chmod +x "$TMP/bin/cru"
cat > "$TMP/remote/addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh" <<'EOF'
#!/bin/sh
case "$1" in
  configure)
    printf 'CHANGED_CONFIG\n' > "$TEST_LEGACY_ROOT/scripts/vpn_ipcatcher.conf"
    printf 'ExamplePolicy\novpnc1\n\n' > "$TEST_LEGACY_ROOT/addons/vpn_ipcatcher.d/routing-selection"
    [ ! -f "$TEST_LEGACY_ROOT/cancel-routing" ]
    ;;
  *) exit 0 ;;
esac
EOF
: > "$TMP/jffs/cancel-routing"
(cd "$TMP/remote"; sha256sum $FILES) > "$TMP/remote/SHA256SUMS"
if sh "$TMP/updater" migrate example/vpn-ipcatcher main; then echo 'Canceled migration accepted'; exit 1; fi
grep -q PRIVATE_CONFIG_KEEP "$TMP/jffs/scripts/vpn_ipcatcher.conf"
[ ! -f "$TMP/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh" ]
[ ! -f "$TMP/jffs/addons/vpn_ipcatcher.d/routing-selection" ]
grep -q 'a vpn_ipcatcher_watchdog .*old-watchdog' "$TMP/jffs/cron-events"
echo 'PASS: canceled legacy routing restores configuration and watchdog without installing files'
rm "$TMP/jffs/cancel-routing"
cat > "$TMP/remote/addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh" <<'EOF'
#!/bin/sh
[ "$1" = hooks ] || exit 1
printf '#!/bin/sh\necho new-hook\n' > "$TEST_LEGACY_ROOT/scripts/services-start"
[ ! -f "$TEST_LEGACY_ROOT/fail-hooks" ]
EOF
: > "$TMP/jffs/fail-hooks"
(cd "$TMP/remote"; sha256sum $FILES) > "$TMP/remote/SHA256SUMS"
if sh "$TMP/updater" migrate example/vpn-ipcatcher main; then echo 'Failed hooks accepted'; exit 1; fi
grep -q old-hook "$TMP/jffs/scripts/services-start"
grep -q PRIVATE_CONFIG_KEEP "$TMP/jffs/scripts/vpn_ipcatcher.conf"
[ ! -f "$TMP/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh" ]
[ ! -f "$TMP/jffs/addons/vpn_ipcatcher.d/routing-selection" ]
echo 'PASS: failed legacy hook installation restores files, missing helpers, hooks and private config'
rm "$TMP/jffs/fail-hooks"
sh "$TMP/updater" migrate example/vpn-ipcatcher main
for f in $FILES; do [ -s "$TMP/jffs/$f" ]; done
grep -q new-hook "$TMP/jffs/scripts/services-start"
[ -f "$TMP/runtime/vpn_ipcatcher.disabled" ]
[ ! -f "$TMP/jffs/addons/vpn_ipcatcher.d/updating" ]
grep -q 'a vpn_ipcatcher_watchdog .*vpn_ipcatcher_watchdog.sh' "$TMP/jffs/cron-events"
if sh "$TMP/updater" rollback; then echo 'Incomplete legacy menu rollback accepted'; exit 1; fi
echo 'PASS: legacy migration installs missing helpers, registers watchdog, preserves stopped state and rejects unsafe legacy rollback'
sh "$TMP/updater" update-source example/vpn-ipcatcher main
before="$(cat "$TMP/jffs/addons/vpn_ipcatcher.d/last-backup")"
sh "$TMP/updater" update
[ "$(cat "$TMP/jffs/addons/vpn_ipcatcher.d/last-backup")" = "$before" ]
sh "$TMP/updater" force-update
[ "$(cat "$TMP/jffs/addons/vpn_ipcatcher.d/last-backup")" != "$before" ]
grep -q new-hook "$TMP/jffs/scripts/services-start"
echo 'PASS: same-version update is skipped; forced repair creates backup and refreshes hooks'
