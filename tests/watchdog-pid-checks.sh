#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="/tmp/vpnipc-pid-test-$$"
mkdir -p "$TMP/cache" "$TMP/pids" "$TMP/addon"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

# Execute the actual run_engine function with mocked external dependencies and
# a finite loop. This catches an inadvertent "echo $" (the 2.9.14 regression).
sed -n '/^run_engine(){/,/^}/p' "$ROOT/scripts/vpn_ipcatcher.real.sh" |
  sed 's/^  while true; do$/  while [ "$LOOP_COUNT" -lt 3 ]; do/' > "$TMP/run-function"
sed -n '/^cleanup(){/,/^}/p' "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$TMP/cleanup-function"
sed -n '/^watchdog_engine_alive(){/,/^}/p' "$ROOT/scripts/vpn_ipcatcher.sh" > "$TMP/watchdog-function"
. "$TMP/run-function"
. "$TMP/cleanup-function"
. "$TMP/watchdog-function"

CACHE_DIR="$TMP/cache"
PIDDIR="$TMP/pids"
LOCK="$TMP/engine.lock"
ENGINE_PIDFILE="$PIDDIR/engine.pid"
PROMOTE_PIDFILE="$PIDDIR/promote.pid"
CAP_PIDFILE="$PIDDIR/capture.pids"
STATUS_FILE="$TMP/status"
WEB_STATUS_FILE="$TMP/web-status.json"
CACHE_DOM2IP="$CACHE_DIR/dom2ip"
ROUTING_HELPER="$TMP/route"
EXCLUDE_NETS=""
EXCLUDE_NET_SET="FixtureExcludes"
IPSET_NAME="FixtureIPTV"
CAND_SET="FixtureCandidates"
WAIT_SET="FixtureWaiting"
INTERFACES="br0"
PORTS="80,443"
SOURCE_IPS=""
PROMOTE_MODE="bytes"
PROMOTE_EVERY=60
EXCLUDE_RESOLVE_CACHE=yes
EXCLUDE_RESOLVE_EVERY=3600
REVERSE_DNS_CHECK=no
CAPTURE_GENERIC_HOSTNAMES=no
ALLOW_EXTERNAL_DNS=no
EXTERNAL_DNS_SERVER=""
STREAM_FLOW_SCAN=yes
STREAM_MIN_BYTES=3000000
STREAM_MIN_DELTA=500000
STREAM_REQUIRE_GROWTH=yes
STREAM_SCAN_EVERY=5
STREAM_FLOW_TARGET=final
TCPDUMP="mock-tcpdump"
BPF='tcp and (port 80 or port 443)'
ACCT_OK=1
LOOP_COUNT=0
PROMOTE_PID=""
CAP_PIDS=""
STOPPING=0
cat > "$ROUTING_HELPER" <<'EOS'
#!/bin/sh
[ "$1" = prepare ]
EOS
chmod 755 "$ROUTING_HELPER"

load_config(){ :; }
validate_prereqs(){ :; }
cleanup_stale_state(){ :; }
is_running(){ return 1; }
write_pidfiles(){ printf '%s\n' "$$" > "$ENGINE_PIDFILE"; : > "$CAP_PIDFILE"; }
set_runtime_state(){ printf '%s\n' "$1" > "$STATUS_FILE"; }
ensure_set(){ :; }
rebuild_exclude_net_set(){ :; }
check_learning_route(){ :; }
enable_conntrack_acct(){ :; }
build_bpf(){ :; }
start_promote_worker(){ :; }
start_capture_workers(){ :; }
ensure_workers_alive(){ :; }
write_web_status(){ :; }
refresh_exclusion_ip_cache(){ :; }
refresh_provider_ranges(){ :; }
current_epoch(){ echo 1000; }
log(){ printf '%s\n' "$*" >> "$TMP/engine.log"; }
sleep(){ LOOP_COUNT=$((LOOP_COUNT+1)); }
is_pid_alive(){ return 1; }
kill_pid_list(){ :; }

run_engine
[ "$(cat "$ENGINE_PIDFILE")" = "$$" ] || { echo 'Engine PID corrupted by run loop' >&2; exit 1; }
[ "$(cat "$LOCK")" = "$$" ] || { echo 'Engine lock corrupted by run loop' >&2; exit 1; }
[ "$LOOP_COUNT" = 3 ] || { echo 'Mock engine did not loop' >&2; exit 1; }
echo 'PASS: engine PID and lock remain numeric and stable after three loops'

# An older engine must never remove a newer engine's global PID files.
printf '999\n' > "$ENGINE_PIDFILE"
printf '123\n' > "$PROMOTE_PIDFILE"
printf '456\n' > "$CAP_PIDFILE"
( cleanup )
[ "$(cat "$ENGINE_PIDFILE")" = 999 ]
[ "$(cat "$PROMOTE_PIDFILE")" = 123 ]
[ "$(cat "$CAP_PIDFILE")" = 456 ]
[ -f "$LOCK" ]
echo 'PASS: stale engine cleanup does not kill/delete replacement state'

printf '%s\n' "$$" > "$ENGINE_PIDFILE"
( cleanup )
[ ! -f "$ENGINE_PIDFILE" ] && [ ! -f "$LOCK" ]
echo 'PASS: current-owner engine cleanup removes its own runtime state'

if watchdog_engine_alive '$'; then echo 'Invalid nonnumeric PID accepted by watchdog' >&2; exit 1; fi
if watchdog_engine_alive 999999999; then echo 'Nonexistent PID accepted by watchdog' >&2; exit 1; fi
if watchdog_engine_alive "$$"; then echo 'Unrelated live shell PID accepted as engine' >&2; exit 1; fi
echo 'PASS: watchdog rejects malformed, dead, and unrelated PIDs'
