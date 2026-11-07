#!/bin/sh
# 2.10.5: final-list persistence, safe restore, Entware/USB waiting, log
# rotation, health/incident report, EPG/DVR check and publish-skip limits.
# Everything here runs against mocks; see TESTING.md for router checks.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/vpnipc-persist-$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
fail(){ echo "FAIL: $*" >&2; exit 1; }

sed '/^case "\$1" in/,$d' "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$TMP/library"
set +e
. "$TMP/library"
set -e
AWK=awk; SED=sed; GREP=grep; TR=tr; TAIL=tail; HEAD=head
CONF="$TMP/config"; default_config > "$CONF"; load_config
IPSET_NAME=TestSet; WAIT_SET=TestSet_wait; CAND_SET=TestSet_cand
FINAL_TIMEOUT=7200
CACHE_DIR="$TMP/cache"; mkdir -p "$CACHE_DIR"
FINAL_SAVE_FILE="$TMP/jffs/final_ipset.save"
LOGFILE="$TMP/engine.log"
PREREQ_STATUS="$TMP/prereq"
EXCLUDE_RESOLVE_CACHE=no
log(){ printf '%s\n' "$*" >> "$TMP/events"; }
schedule_webui_publish(){ :; }
refresh_fixed_routes(){ :; }
NOW=1800000000
current_epoch(){ echo "$NOW"; }

# --- file-backed ipset mock: one "ip timeout_left_at_set_time set_epoch comment" per line
ipset_mock(){
  cmd="$1"; set_name="${2:-}"; store="$TMP/set_$set_name"
  [ -f "$store" ] || : > "$store"
  case "$cmd" in
    save)
      echo "create $set_name hash:ip family inet timeout 0 counters comment"
      awk -v s="$set_name" -v now="$NOW" '{left=$2-(now-$3); if (left>0) printf "add %s %s timeout %d packets 0 bytes 0 comment \"%s\"\n", s, $1, left, $4}' "$store" ;;
    list)
      echo "Name: $set_name"; echo "Members:"
      awk -v now="$NOW" '{left=$2-(now-$3); if (left>0) print $1 " timeout " left}' "$store" ;;
    test) awk -v ip="$3" -v now="$NOW" '$1==ip && $2-(now-$3)>0 {f=1} END{exit f?0:1}' "$store" ;;
    add)
      ip="$3"; shift 3; t=0; c=x
      while [ "$#" -gt 0 ]; do case "$1" in timeout) t="$2"; shift 2 ;; comment) c="$2"; shift 2 ;; *) shift ;; esac; done
      awk -v ip="$ip" '$1!=ip' "$store" > "$store.n"; mv "$store.n" "$store"
      printf '%s %s %s %s\n' "$ip" "$t" "$NOW" "$c" >> "$store" ;;
    del) awk -v ip="$3" '$1!=ip' "$store" > "$store.n"; mv "$store.n" "$store" ;;
    flush) : > "$store" ;;
  esac
}
IPSET=ipset_mock
set_has(){ ipset_mock test "$1" "$2"; }
left_of(){ awk -v ip="$2" -v now="$NOW" '$1==ip {print $2-(now-$3)}' "$TMP/set_$1"; }
ROUTE_OK=yes
ROUTING_HELPER="$TMP/routing"
printf '#!/bin/sh\n[ "$1" = ready ] && [ "$(cat "%s/route")" = yes ]\n' "$TMP" > "$ROUTING_HELPER"; chmod +x "$ROUTING_HELPER"
echo yes > "$TMP/route"
CT=""

# ---------------------------------------------------------------- saving
ipset_mock add TestSet 81.2.69.10 -exist timeout 7200 comment "src=flow-delta1b-total2b-192.168.1.20-80;seen=x"
ipset_mock add TestSet 81.2.69.11 -exist timeout 3000 comment "src=promoted-bytes;seen=x"
save_final_set auto
[ -f "$FINAL_SAVE_FILE" ] || fail "first save missing"
head -n 1 "$FINAL_SAVE_FILE" | grep -q "^# vpn_ipcatcher final v2 $NOW TestSet$" || fail "header"
grep -q "^81.2.69.10 $((NOW+7200)) " "$FINAL_SAVE_FILE" || fail "expiry stored per IP"
grep -q "^81.2.69.11 $((NOW+3000)) " "$FINAL_SAVE_FILE" || fail "real remaining expiry stored"
cp "$FINAL_SAVE_FILE" "$TMP/first"
echo 'PASS: save stores origin and real expiry per IP'

# Unchanged members, timeout refreshed a little: no flash write.
NOW=$((NOW+900)); ipset_mock add TestSet 81.2.69.10 -exist timeout 7200 comment "src=refreshed;seen=y"
save_final_set auto
cmp -s "$FINAL_SAVE_FILE" "$TMP/first" || fail "rewrote on small refresh"
# Refreshed beyond the slack (max(FINAL_SAVE_EVERY, FINAL_TIMEOUT/4)=1800) and interval passed: rewrite.
NOW=$((NOW+1500)); ipset_mock add TestSet 81.2.69.10 -exist timeout 7200 comment "src=refreshed;seen=z"
save_final_set auto
grep -q "^81.2.69.10 $((NOW+7200)) " "$FINAL_SAVE_FILE" || fail "refresh save missing"
grep -q 'vervaltijden ververst' "$TMP/events" || fail "refresh reason"
echo 'PASS: unchanged-but-refreshed IPs keep a valid stored expiry with bounded rewrites'

# Membership change inside FINAL_CHANGE_EVERY: wait; afterwards: write.
cp "$FINAL_SAVE_FILE" "$TMP/second"
NOW=$((NOW+60)); ipset_mock add TestSet 81.2.69.12 -exist timeout 7200 comment "src=new;seen=z"
save_final_set auto
cmp -s "$FINAL_SAVE_FILE" "$TMP/second" || fail "change written inside minimum interval"
NOW=$((NOW+600)); save_final_set auto
grep -q '^81.2.69.12 ' "$FINAL_SAVE_FILE" || fail "change not saved after interval"
echo 'PASS: membership changes are saved with a minimum interval'

# Power loss: an interrupted temporary file never replaces the good file;
# a failed rename keeps the previous save.
cp "$FINAL_SAVE_FILE" "$TMP/good"
printf '# vpn_ipcatcher final v2 1 TestSet\n198.51.100' > "$FINAL_SAVE_FILE.tmp.999"
NOW=$((NOW+700)); ipset_mock add TestSet 81.2.69.13 -exist timeout 7200 comment "src=new;seen=z"
mv(){ return 1; }
save_final_set auto || :
unset -f mv
cmp -s "$FINAL_SAVE_FILE" "$TMP/good" || fail "failed rename damaged previous save"
ls "$FINAL_SAVE_FILE".tmp.* 2>/dev/null | grep -v '999$' && fail "own temp file left behind"
echo 'PASS: interrupted or failed write keeps the last good save'

# ---------------------------------------------------------------- restoring
reset_sets(){ for s in TestSet TestSet_wait; do : > "$TMP/set_$s"; done; : > "$TMP/events"; }
SAVED_AT=$NOW
write_save(){
  { echo "# vpn_ipcatcher final v2 $SAVED_AT TestSet"; cat; } > "$FINAL_SAVE_FILE"
}
reset_sets
printf '%s\n' \
  "81.2.69.20 $((SAVED_AT+5000)) src=flow-a-192.168.1.20-80;seen=a" \
  "81.2.69.21 $((SAVED_AT+30)) src=almost-gone;seen=a" \
  "81.2.69.22 $((SAVED_AT+999999)) src=long;seen=a" \
  "bogus line here" \
  "300.1.1.1 $((SAVED_AT+5000)) src=bad;seen=a" | write_save
NOW=$((SAVED_AT+1000))
FINAL_RESTORE_PENDING=0
restore_final_set || fail "restore should complete"
# No conntrack on this host: restored IPs must wait, never route blindly.
set_has TestSet 81.2.69.20 && fail "restored to final without connection check"
set_has TestSet_wait 81.2.69.20 || fail "no conntrack: IP must wait"
set_has TestSet_wait 81.2.69.21 && fail "expired IP restored"
grep -q '1 verlopen' "$TMP/events" || fail "expired count"
echo 'PASS: missing conntrack keeps restored IPs waiting; expired and damaged lines skipped'

conntrack_mock(){ printf 'tcp 6 300 ESTABLISHED src=192.168.1.30 dst=81.2.69.22 sport=1 dport=443\n'; }
CT=conntrack_mock
reset_sets
restore_final_set
set_has TestSet 81.2.69.20 || fail "idle IP not restored"
[ "$(left_of TestSet 81.2.69.20)" = 4000 ] || fail "restore must keep remaining time, got $(left_of TestSet 81.2.69.20)"
set_has TestSet 81.2.69.22 && fail "IP with active connection routed"
set_has TestSet_wait 81.2.69.22 || fail "active IP not waiting"
echo 'PASS: remaining validity kept (no fresh FINAL_TIMEOUT); active connections wait'

# Long-lived entry is capped at FINAL_TIMEOUT.
conntrack_mock(){ :; }
reset_sets; restore_final_set
[ "$(left_of TestSet 81.2.69.22)" = 7200 ] || fail "cap at FINAL_TIMEOUT"
# Excluded destination and VPN Director fixed source device are skipped.
reset_sets
ip_is_excluded(){ [ "$1" = 81.2.69.22 ]; }
source_is_fixed(){ [ "$1" = 192.168.1.20 ]; }
restore_final_set
set_has TestSet 81.2.69.20 && fail "fixed source device restored"
set_has TestSet 81.2.69.22 && fail "excluded IP restored"
ip_is_excluded(){ return 1; }; source_is_fixed(){ return 1; }
echo 'PASS: current exclusions and VPN Director source rules are re-checked'

# Late VPN start / VPN reconnect: wait until the route is usable.
reset_sets; echo no > "$TMP/route"
if restore_final_set; then fail "restored while VPN not usable"; fi
[ "$FINAL_RESTORE_PENDING" = 1 ] || fail "pending flag"
[ ! -s "$TMP/set_TestSet" ] || fail "something added before route ready"
cp "$FINAL_SAVE_FILE" "$TMP/pending-copy"
save_final_set force; cmp -s "$FINAL_SAVE_FILE" "$TMP/pending-copy" || fail "save overwrote list while restore pending"
echo yes > "$TMP/route"; restore_final_set || fail "restore after VPN came up"
set_has TestSet 81.2.69.20 || fail "not restored after VPN start"
echo 'PASS: late VPN start defers restore; saving is blocked meanwhile'

# Wrong boot clock (before NTP): wait, then give up after 30 minutes.
reset_sets; NOW=1000; FINAL_RESTORE_FIRST=0
if restore_final_set; then fail "restored with insane clock"; fi
grep -q 'nog niet gesynchroniseerd' "$TMP/events" || fail "clock wait note"
NOW=2900; restore_final_set || fail "should give up"
grep -q 'niet teruggezet' "$TMP/events" || fail "give-up note"
[ ! -s "$TMP/set_TestSet" ] || fail "insane clock restored IPs"
# Clock sane but before the save moment: wait.
reset_sets; NOW=$((SAVED_AT-100)); FINAL_RESTORE_FIRST=0
if restore_final_set; then fail "restored with clock before save"; fi
NOW=$((SAVED_AT+1000)); restore_final_set
echo 'PASS: wrong boot clock never restores with guessed expiries'

# Damaged and foreign files never crash the engine.
reset_sets; printf 'garbage\n\001\002' > "$FINAL_SAVE_FILE"
restore_final_set || fail "damaged file must not fail"
grep -q 'beschadigd' "$TMP/events" || fail "damaged note"
printf '# vpn_ipcatcher final v2 %s Other\n81.2.69.20 %s src=x\n' "$SAVED_AT" "$((NOW+999))" > "$FINAL_SAVE_FILE"
reset_sets; restore_final_set; [ ! -s "$TMP/set_TestSet" ] || fail "foreign set restored"
rm -f "$FINAL_SAVE_FILE"; reset_sets; restore_final_set || fail "missing file"
echo 'PASS: missing, damaged or foreign save files are ignored safely'

# DVR reload recreated the set empty: reconcile restores, rate limited.
printf '81.2.69.20 %s src=x;seen=a\n' "$((NOW+5000))" | write_save
reset_sets; FINAL_RECONCILE_LAST=0
ipset_member_count(){ awk 'END{print NR}' "$TMP/set_$1"; }
final_reconcile; set_has TestSet 81.2.69.20 || fail "reconcile after DVR reload"
: > "$TMP/set_TestSet"; NOW=$((NOW+60)); final_reconcile
[ ! -s "$TMP/set_TestSet" ] || fail "reconcile not rate limited"
# Meanwhile an empty live set must never overwrite still-valid saved IPs.
cp "$FINAL_SAVE_FILE" "$TMP/before-empty"; FINAL_SAVE_LAST=0
save_final_set force
cmp -s "$FINAL_SAVE_FILE" "$TMP/before-empty" || fail "empty recreated set overwrote the save"
echo 'PASS: empty DVR set after reload/reconnect is refilled at most every 10 minutes'

# ---------------------------------------------------------------- USB / Entware
OPT_DIR="$TMP/opt"; TCPDUMP=""
reason="$(prereq_problem_text)" || fail "missing opt not detected"
case "$reason" in *"niet beschikbaar"*USB*) ;; *) fail "opt reason: $reason" ;; esac
: > "$TMP/events"
note_prereq_problem "$reason"; NOW=$((NOW+60)); note_prereq_problem "$reason"
[ "$(grep -c 'LET OP' "$TMP/events")" = 1 ] || fail "prereq message not rate limited"
NOW=$((NOW+3600)); note_prereq_problem "$reason"
[ "$(grep -c 'LET OP' "$TMP/events")" = 2 ] || fail "prereq reminder after an hour"
mkdir -p "$OPT_DIR/bin"; reason="$(prereq_problem_text)"
case "$reason" in *"opkg install tcpdump"*) ;; *) fail "tcpdump reason: $reason" ;; esac
# Engine running while USB disappears: no capture restart loop, final set untouched.
start_capture_workers(){ echo started >> "$TMP/capture-starts"; }
start_promote_worker(){ :; }
kill_pid_list(){ :; }
PROMOTE_PIDFILE="$TMP/promote.pid"; echo $$ > "$PROMOTE_PIDFILE"; CAP_PIDFILE="$TMP/cap.pids"; : > "$CAP_PIDFILE"
INTERFACES=br0
printf '81.2.69.50 7200 %s x\n' "$NOW" > "$TMP/set_TestSet"
ensure_workers_alive; ensure_workers_alive
[ ! -f "$TMP/capture-starts" ] || fail "capture restarted without tcpdump"
set_has TestSet 81.2.69.50 || fail "final set touched while waiting"
# Late USB mount: binaries are found again and capture restarts once.
printf '#!/bin/sh\n' > "$OPT_DIR/bin/tcpdump"; chmod +x "$OPT_DIR/bin/tcpdump"
find_bin(){ for p in "$@"; do case "$p" in /opt/*) p="$OPT_DIR${p#/opt}" ;; esac; [ -x "$p" ] && { echo "$p"; return 0; }; done; return 1; }
validate_prereqs(){ return 0; }
ensure_workers_alive
[ "$(cat "$TMP/capture-starts")" = started ] || fail "capture not restarted after late mount"
[ ! -f "$PREREQ_STATUS" ] || fail "marker not cleared"
grep -q 'Hersteld' "$TMP/events" || fail "recovery note"
echo 'PASS: missing Entware waits quietly, keeps routes, re-finds binaries after late mount'
grep -q 'watchdog_engine_alive "$watchdog_pid" || \[ -f "$PREREQ_STATUS" \] || lifecycle_note' "$ROOT/scripts/vpn_ipcatcher.sh" || fail "watchdog note not suppressed"
grep -q 'prereq_gate || return 1' "$ROOT/scripts/vpn_ipcatcher.real.sh" || fail "start gate"
echo 'PASS: watchdog does not log a recovery line every minute while waiting'

# ---------------------------------------------------------------- log rotation
LOG_MAX_BYTES=100
printf 'small\n' > "$LOGFILE"; rotate_log_if_needed; [ ! -f "$LOGFILE.1" ] || fail "rotated small log"
awk 'BEGIN{for(i=0;i<20;i++) print "line " i " xxxxxxxxxx"}' > "$LOGFILE"
rotate_log_if_needed
[ -f "$LOGFILE.1" ] && grep -q 'line 19' "$LOGFILE.1" || fail "rotation lost data"
grep -q 'geroteerd' "$LOGFILE" && [ "$(wc -l < "$LOGFILE")" -eq 1 ] || fail "log not truncated"
echo 'PASS: log rotation keeps at most two bounded parts'

# ---------------------------------------------------------------- health
sed '/^case "\${1:-check}" in/,$d' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_health.sh" > "$TMP/health-lib"
(
  set +e; . "$TMP/health-lib"; set -e
  ADDON="$TMP/addon"; mkdir -p "$ADDON"; REPORT="$ADDON/incident-last.txt"
  STATE="$TMP/health.state"; LOCKDIR="$TMP/health.lock"; LOGFILE="$TMP/health.log"
  logger(){ :; }; nvram(){ :; }
  start=$(date +%s)
  out="$(with_timeout 2 sleep 30)" && fail "timeout not enforced"
  [ $(( $(date +%s) - start )) -le 6 ] || fail "timeout took too long"
  T=1800000000; now(){ echo "$T"; }
  result="dns|lokale DNS (127.0.0.1) geeft geen antwoord"; classify(){ echo "$result"; }
  write_report(){ printf 'report %s\n' "$1" > "$REPORT"; echo w >> "$TMP/report-writes"; }
  tick; [ ! -f "$REPORT" ] || fail "report on first failed check"
  T=$((T+120)); tick; grep -q 'report dns' "$REPORT" || fail "report after confirmed fault"
  grep -q 'Storing vastgesteld (dns)' "$LOGFILE" || fail "fault note"
  T=$((T+120)); tick; [ "$(wc -l < "$TMP/report-writes")" -eq 1 ] || fail "report written more than once"
  T=$((T+60)); tick; [ "$(wc -l < "$TMP/report-writes")" -eq 1 ] || fail "throttle ignored"
  result="ok|"; T=$((T+120)); tick; grep -q 'Hersteld na storing (dns)' "$LOGFILE" || fail "recovery note"
  result="wan|x"; T=$((T+120)); tick; T=$((T+120)); tick
  [ "$(wc -l < "$TMP/report-writes")" -eq 1 ] || fail "second report inside 30 minutes"
  # Real report writer: bounded size, no secrets source.
  unset -f write_report; . "$TMP/health-lib" 2>/dev/null || :
  ADDON="$TMP/addon"; LOGFILE="$TMP/health.log"
  HEALTH_REPORT_MAX=600; REPORT="$ADDON/incident-last.txt"; nvram(){ :; }
  check_dns(){ echo dns-test; return 1; }; check_vpn(){ return 0; }; check_opt(){ return 0; }
  write_report dns "test"
  [ "$(wc -c < "$REPORT")" -le 600 ] || fail "report not bounded"
  grep -q 'soort: dns' "$REPORT" || fail "report content"
  if grep -v '^ *#' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_health.sh" | grep -q 'nvram show'; then fail "nvram show used"; fi
  ls "$ADDON"/incident-last.txt.tmp.* 2>/dev/null && fail "report temp left"
  echo 'PASS: health check confirms faults twice, writes one bounded report, logs recovery'
)

# ---------------------------------------------------------------- EPG / DVR
sed '/^case "\${1:-check}" in/,$d' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh" > "$TMP/routing-lib"
(
  set +e; . "$TMP/routing-lib"; set -e
  POLICIES="$TMP/dvr/domain_vpn_routing.conf"; mkdir -p "$TMP/dvr"
  printf 'VPNSW|x|x|ovpnc1\nNordPL|x|x|ovpnc2\n' > "$POLICIES"
  printf '*.skywayplatform.com\nline.lux-4k.cc\nsh: \n: not found\n#comment\n' > "$TMP/dvr/policy_VPNSW_domainlist"
  printf 'player.pl\n' > "$TMP/dvr/policy_NordPL_domainlist"
  [ "$(policy_for_host europe.skywayplatform.com)" = 'VPNSW|ovpnc1' ] || fail "wildcard policy match"
  [ "$(policy_for_host skywayplatform.com)" = 'VPNSW|ovpnc1' ] || fail "wildcard apex match"
  [ -z "$(policy_for_host notskywayplatform.com)" ] || fail "wildcard boundary"
  [ "$(policy_for_host player.pl)" = 'NordPL|ovpnc2' ] || fail "exact match"
  lint="$(lint_domainlists)"
  printf '%s\n' "$lint" | grep -q 'regel 3 in policy VPNSW' || fail "lint sh: line"
  printf '%s\n' "$lint" | grep -q 'regel 4 in policy VPNSW' || fail "lint not found line"
  printf '%s\n' "$lint" | grep -q 'skywayplatform' && fail "valid wildcard flagged"
  domain_check_one unknown.example.org 2>"$TMP/epg-err" && fail "unknown host accepted"
  grep -q 'geen enkele DVR-policy' "$TMP/epg-err" || fail "unknown host message"
  # OpenVPN state must be connected, an UP interface alone is not enough.
  find_bin(){ [ "$1" = /bin/nvram ] && { echo nvram_mock; return 0; }; return 1; }
  nvram_mock(){ [ "$2" = vpn_client1_state ] && echo "$TEST_STATE"; }
  CONNECTION=ovpnc1; TEST_STATE=1
  tunnel_usable 2>/dev/null && fail "connecting OpenVPN accepted"
  TEST_STATE=2; tunnel_usable || fail "connected OpenVPN rejected"
  echo 'PASS: EPG host -> DVR policy matching, list lint and VPN client state check'
)

# ---------------------------------------------------------------- WebUI skip log
sed '/^case "\$1" in/,$d' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh" > "$TMP/webui-lib"
(
  set +e; TEST_PATH="$PATH"; . "$TMP/webui-lib"; PATH="$TEST_PATH"; set -e
  PUBLISH_SKIP_STATE="$TMP/skip"; : > "$TMP/webui-events"
  log(){ printf '%s\n' "$*" >> "$TMP/webui-events"; }
  note_publish_skipped; note_publish_skipped; note_publish_skipped
  [ "$(grep -c 'Statuspublicatie overgeslagen' "$TMP/webui-events")" = 1 ] || fail "skip log not limited"
  printf '%s 7\n' "$(( $(date +%s) - 4000 ))" > "$PUBLISH_SKIP_STATE"
  note_publish_skipped; grep -q '8x sinds vorige melding' "$TMP/webui-events" || fail "skip counter"
  echo 'PASS: busy WebUI publisher is logged at most every 30 minutes with a counter'
)
echo 'ALL PASS: persistence-health-checks'
