#!/bin/sh
set -eu
work="${TMPDIR:-/tmp}/vpnipc-webui-test-$$"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed '/^case "\$1" in/,$d' addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh > "$work/library"
set +e
TEST_PATH="$PATH"
. "$work/library"
PATH="$TEST_PATH"
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
DIAGNOSTIC_DNS_STATE="$work/dns-state"
DIAGNOSTIC_DNS_LOCK="$work/dns-lock"
DIAGNOSTIC_DNS="$work/dns-records"
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

ACTION_STATUS="$work/diagnostic-action"
TCPDUMP=''; TIMEOUT=''
case "$WEBUI" in /jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh) ;; *) exit 1 ;; esac
service_event restart vipcDfixture-nonce_192.0.2.10
node -e 'const d=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); if(d.last_action_nonce!=="fixture-nonce" || d.diagnostic_target!=="192.0.2.10" || d.diagnostic_status!=="active")process.exit(1);' "$STATUS_JSON"
service_event restart vipcDstop
node -e 'const d=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); if(d.diagnostic_status!=="idle" || d.diagnostic_text!=="")process.exit(1);' "$STATUS_JSON"
echo 'PASS: diagnostic start confirms nonce and target; stop clears the published snapshot'
TCPDUMP=''; TIMEOUT=''
diagnostic_dns_start 192.0.2.10 1760000000
[ "$(cat "$DIAGNOSTIC_DNS_STATE")" = tools-missing ]
printf '192.0.2.10 %s\n' "$(date +%s)" > "$DIAGNOSTIC_TARGET"
[ "$(diagnostic_dns_state)" = tools-missing ]
echo 'PASS: missing DNS capture tools produce an explicit state, not silent unknown domains'
printf '%s\n' \
  '1760000000.123456 IP (ttl 64)' \
  '    192.0.2.10.12345 > 192.0.2.1.53: 123+ A? stream.example.invalid. (40)' \
  '1760000001.123456 IP (ttl 64)' \
  '    192.0.2.1.53 > 192.0.2.10.12345: 123 q: A? stream.example.invalid. 1/0/0 A 203.0.113.1 (56)' \
  '1760000002.123456 IP A? https://secret.invalid/token. A 203.0.113.2' \
  '1760000003.123456 IP A? bad.example.invalid. A 999.0.2.1' | diagnostic_dns_parse 192.0.2.10 > "$work/dns-output"
grep -q '192.0.2.10 stream.example.invalid 203.0.113.1' "$work/dns-output"
grep -q '192.0.2.10 stream.example.invalid -' "$work/dns-output"
if grep -q 'secret\|token\|999.0.2.1' "$work/dns-output"; then exit 1; fi
echo 'PASS: multiline DNS query/answer metadata, timestamps and no URL or invalid-IP leakage'
DIAGNOSTIC_DNS_LOCK="$work/dns-lock"
DIAGNOSTIC_DNS="$work/dns-records"
mkdir "$DIAGNOSTIC_DNS_LOCK"
TCPDUMP="$work/fake-tcpdump"
TIMEOUT="$work/fake-timeout"
cat > "$TCPDUMP" <<'EOF'
#!/bin/sh
printf '%s\n' '1760000000.123456 IP q: A? stream.example.invalid. 1/0/0 A 203.0.113.1'
EOF
cat > "$TIMEOUT" <<'EOF'
#!/bin/sh
[ "${1:-}" != --help ] || { echo 'timeout SECS PROG'; exit 0; }
[ "$1" = -s ] && [ "$2" = TERM ] && [ "$3" = 120 ] || exit 1
shift 3
exec "$@"
EOF
chmod +x "$TCPDUMP" "$TIMEOUT"
printf '192.0.2.10 1760000000\n' > "$DIAGNOSTIC_TARGET"
(diagnostic_dns_worker 192.0.2.10 1760000000)
grep -q 'stream.example.invalid 203.0.113.1' "$DIAGNOSTIC_DNS"
[ ! -d "$DIAGNOSTIC_DNS_LOCK" ]
echo 'PASS: DNS worker bounds the producer, writes only parsed metadata and cleans its FIFO/lock'
