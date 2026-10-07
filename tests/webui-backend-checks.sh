#!/bin/sh
set -eu
work="${TMPDIR:-/tmp}/vpnipc-webui-test-$$"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed '/^case "\$1" in/,$d' addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh > "$work/library"
set +e
. "$work/library"
set -e
CONF="$work/config"
STATUS_JSON="$work/status.json"
LOGFILE="$work/log"
PRESET_LIB="$work/no-presets"
ACTION_STATUS="$work/no-action"
AWK=awk
printf 'IPSET_NAME="Example"\nINTERFACES="br0"\n' > "$CONF"
printf 'Quoted "test" and backslash \\ and tab\tend\n' > "$LOGFILE"
ensure_engine(){ return 0; }
publish_lock_acquire(){ return 0; }
publish_lock_release(){ return 0; }
publish_presets(){ return 0; }
is_running(){ return 1; }
ipset_count(){ case "$1" in *_cand) echo 2 ;; *_wait) echo 1 ;; *) echo 0 ;; esac; }
ipset_text(){ printf 'Name: %s\nMembers:\n203.0.113.10 timeout 60 packets 0 bytes 0 comment "src=test"\n' "$1"; }
live_flows_text(){ printf 'No test flows\n'; }
publish_status
node -e 'const d=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); if(d.waiting_count!=="1" || !d.waiting_text.includes("203.0.113.10") || !d.waiting_text.includes("\"src=test\"") || !d.status_text.includes("Deferred IPs") || !d.status_text.includes("Engine") || !d.log_text.includes("\"test\"") || !d.log_text.includes("\\") || !d.log_text.includes("\t")) process.exit(1);' "$STATUS_JSON"
echo 'PASS: WebUI backend emits valid JSON, waiting list and meaningful status snapshot'
