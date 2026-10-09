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
ADDON_DIR="$work/addon"
mkdir "$ADDON_DIR"
printf 'Example\novpnc1\n' > "$ADDON_DIR/routing-selection"
AWK=awk
DIAGNOSTIC_TARGET="$work/diagnostic"
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
node -e 'const d=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); if(d.vpn_connection!=="ovpnc1") process.exit(1);' "$STATUS_JSON"
echo 'PASS: selected VPN metadata is published without private credentials'

CT=diagnostic_fixture
diagnostic_fixture(){
  printf '%s\n' \
    'tcp 6 120 SYN_SENT src=192.0.2.10 dst=203.0.113.1 sport=1234 dport=8080 [UNREPLIED] src=203.0.113.1 dst=192.0.2.10 sport=8080 dport=1234 secret=never-publish' \
    'udp 17 30 src=192.0.2.10 dst=203.0.113.2 sport=1235 dport=53 bytes=20 src=203.0.113.2 dst=192.0.2.10 bytes=40' \
    'tcp 6 120 ESTABLISHED src=192.0.2.11 dst=203.0.113.3 sport=1236 dport=443 bytes=99999'
}
printf '192.0.2.10 %s\n' "$(date +%s)" > "$DIAGNOSTIC_TARGET"
diagnostic_text > "$work/diagnostic-output"
grep -q 'tcp 192.0.2.10 203.0.113.1 8080' "$work/diagnostic-output"
grep -q 'udp 192.0.2.10 203.0.113.2 53 - 60' "$work/diagnostic-output"
if grep -q 'secret\|192.0.2.11' "$work/diagnostic-output"; then exit 1; fi
printf '192.0.2.10 %s\n' "$(( $(date +%s) - 121 ))" > "$DIAGNOSTIC_TARGET"
[ -z "$(diagnostic_text)" ]
if valid_diagnostic_ip '192.0.2.10;id'; then exit 1; fi
if valid_diagnostic_ip '999.0.2.10'; then exit 1; fi
echo 'PASS: device diagnostics include all ports and missing counters, redact extras and expire'
