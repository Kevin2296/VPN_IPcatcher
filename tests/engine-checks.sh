#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/vpnipc-tests-$$"
mkdir "$TMP"
trap 'rm -rf "$TMP"' EXIT
# Load definitions only; never run the router engine on the development host.
sed '/^case "\$1" in/,$d' "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$TMP/library"
set +e
. "$TMP/library"
set -e
AWK=awk; SED=sed; GREP=grep; TR=tr; TAIL=tail
CONF="$TMP/config"
default_config > "$CONF"
load_config
[ "$PROMOTE_MODE" = auto ] && [ "$STREAM_MIN_BYTES" = 15000000 ] && [ "$STREAM_MIN_DELTA" = 750000 ]
[ "$STREAM_FLOW_TARGET" = candidate ] && [ "$FINAL_TIMEOUT" = 604800 ]
[ "$(menu_action_key main 7)" = maintenance ]
[ "$(menu_action_key maintenance uc)" = UC ]
[ "$(menu_action_key maintenance U)" = U ]
[ "$(menu_action_key maintenance FU)" = FU ]
[ "$(menu_action_key maintenance 19)" = invalid ]
[ "$(menu_action_key main E)" = back ]
[ "$(menu_action_key settings e)" = back ]
[ "$(menu_action_key vpn 2)" = 23 ]
[ "$(menu_action_key view 1)" = 4 ]
echo 'PASS: documented defaults, compact submenus, E navigation and unique update keys'
printf 'PROMOTE_EVERY="008"\nEXCLUDE_DOMAINS=""\nEXCLUDE_NETS=""\n' > "$CONF"
load_config
[ "$PROMOTE_EVERY" = 8 ] && [ "$EXCLUDE_DOMAINS" = '' ] && [ "$EXCLUDE_NETS" = '' ]
[ "$((PROMOTE_EVERY * 2))" = 16 ]
printf 'INTERFACES="br0"\n' > "$CONF"
load_config
[ "$PROMOTE_EVERY" = 15 ] && [ -n "$EXCLUDE_DOMAINS" ]
effective_config > "$TMP/effective-config"
grep -q '^STREAM_MIN_BYTES="15000000"$' "$TMP/effective-config"
grep -q '^PROMOTE_MODE="auto"$' "$TMP/effective-config"
EXCLUDE_RESOLVE_CACHE=yes; EXCLUDE_DOMAINS='kept.example.invalid'
CACHE_EXCLUDE_IPS="$TMP/exclude-cache"
printf '203.0.113.10 removed.example.invalid\n203.0.113.10 kept.example.invalid\n203.0.113.11 removed.example.invalid\n' > "$CACHE_EXCLUDE_IPS"
ip_in_resolved_exclude_cache 203.0.113.10
if ip_in_resolved_exclude_cache 203.0.113.11; then echo 'Removed domain still excluded'; exit 1; fi
default_config > "$CONF"
load_config
echo 'PASS: effective defaults, explicit empty exclusions, removed keys, decimal timers and shared-domain cache'
menu_output="$(printf '7\nE\nE\n' | (soft_clear(){ :; }; print_header(){ :; }; menu_loop))"
printf '%s\n' "$menu_output" | grep -q 'UC) Update controleren'
if printf '%s\n' "$menu_output" | grep -Eq '18\)|19\)|17\)'; then exit 1; fi
echo 'PASS: maintenance navigation returns with E and displays no duplicate numbered update actions'
ROUTING_STATUS="$TMP/routing-status"
IPSET_NAME=Example
current_epoch(){ echo 1000; }
STREAM_SCAN_EVERY=10
printf '981 Example\n' > "$ROUTING_STATUS"
learning_route_ready
printf '979 Example\n' > "$ROUTING_STATUS"
if learning_route_ready; then echo 'Stale routing accepted' >&2; exit 1; fi
STREAM_SCAN_EVERY=1
printf '985 Example\n' > "$ROUTING_STATUS"
learning_route_ready
printf '1001 Example\n' > "$ROUTING_STATUS"
if learning_route_ready; then echo 'Future routing timestamp accepted' >&2; exit 1; fi
echo 'PASS: routing readiness scales with scan interval, has a 15s floor and rejects future timestamps'
(
  ROUTING_HELPER="$TMP/routing-probe"
  cat > "$ROUTING_HELPER" <<'EOF'
#!/bin/sh
case "$1" in
  prepare) printf 'Routing: test tunnel missing\n' >&2; exit 3 ;;
  check) printf 'Routing: test default route missing\n' >&2; exit 4 ;;
esac
EOF
  chmod +x "$ROUTING_HELPER"
  log(){ printf '%s\n' "$*" >> "$TMP/routing-log"; }
  test_epoch=1000
  current_epoch(){ echo "$test_epoch"; }
  check_learning_route
  [ ! -f "$ROUTING_STATUS" ]
  grep -q 'prepare=3: Routing: test tunnel missing; check=4: Routing: test default route missing' "$TMP/routing-log"
  check_learning_route
  [ "$(wc -l < "$TMP/routing-log")" -eq 1 ]
  test_epoch=1301
  check_learning_route
  [ "$(wc -l < "$TMP/routing-log")" -eq 2 ]
  printf '#!/bin/sh\nprintf "Routing: changed reason\\n" >&2\nexit 2\n' > "$ROUTING_HELPER"
  check_learning_route
  [ "$(wc -l < "$TMP/routing-log")" -eq 3 ]
  printf '#!/bin/sh\nexit 0\n' > "$ROUTING_HELPER"
  check_learning_route
  [ -f "$ROUTING_STATUS" ] && [ ! -f "${ROUTING_STATUS}.failure" ]
  grep -q 'Routingcontrole hersteld' "$TMP/routing-log"
  check_learning_route
  [ "$(wc -l < "$TMP/routing-log")" -eq 4 ]
  printf '#!/bin/sh\ncase "$1" in prepare) echo "Routing: config locked";exit 1;;check) echo "OK: test route";exit 0;;esac\n' > "$ROUTING_HELPER"
  check_learning_route
  [ ! -f "$ROUTING_STATUS" ]
  grep -q 'prepare=1: Routing: config locked; check=0: OK: test route' "$TMP/routing-log"
  ROUTING_HELPER="$TMP/missing-routing-helper"
  check_learning_route
  grep -q 'prepare=127:' "$TMP/routing-log"
)
echo 'PASS: routing failure logs immediate prepare/check details, throttles duplicates and logs recovery'
[ "$PROMOTE_EVERY" = 15 ]
EXCLUDE_DOMAINS="google.com"
domain_is_excluded google.com
domain_is_excluded video.google.com
if domain_is_excluded notgoogle.com; then echo 'Domain boundary failed'; exit 1; fi
if domain_is_excluded google.com.example.org; then echo 'Domain suffix failed'; exit 1; fi
SOURCE_IPS="192.168.1.20 192.168.1.21"
PORTS="80,443"
build_bpf
case "$BPF" in *'src host 192.168.1.20 or src host 192.168.1.21'*) ;; *) exit 1 ;; esac
SOURCE_IPS="invalid"
if build_bpf; then echo 'Invalid source accepted'; exit 1; fi
# Configuration is data, including potentially executable text.
printf 'INTERFACES="$(touch %s)"\n' "$TMP/executed" > "$CONF"
if load_config; then echo 'Unsafe config accepted'; exit 1; fi
[ ! -e "$TMP/executed" ]
printf 'PROMOTE_EVERY="zero"\n' > "$CONF"
if load_config; then echo 'Invalid number accepted'; exit 1; fi
echo 'PASS: config safety, numeric validation, domain boundaries, source filter'

ipset_mock(){
  case "$1" in
    test) return 0 ;;
    add) echo add >> "$TMP/ipset-calls" ;;
  esac
}
should_skip_service_ip(){ return 1; }
IPSET=ipset_mock
CAND_SET=test
CANDIDATE_TIMEOUT=600
add_candidate_once 8.8.4.5 test
[ ! -f "$TMP/ipset-calls" ]
echo 'PASS: candidate timeout is not refreshed for existing members'

CT=conntrack_mock
conntrack_mock(){
  printf '%s\n' 'tcp 6 300 ESTABLISHED src=192.168.1.20 dst=8.8.4.5 sport=50000 dport=443 packets=2 bytes=100 src=8.8.4.5 dst=192.168.1.20 sport=443 dport=50000 packets=20 bytes=4000000'
}
ipset_mock(){
  case "$1" in
    list) printf 'Members:\n8.8.4.5 timeout 500 packets 0 bytes 0\n' ;;
    del) echo del >> "$TMP/promoted" ;;
  esac
}
add_final_immediate(){ echo final >> "$TMP/promoted"; }
SOURCE_IPS="192.168.1.20"
PORTS=443
PROMOTE_MODE=bytes
MIN_AGE=20
MIN_BYTES=3000000
promote_candidates
[ "$(cat "$TMP/promoted")" = "$(printf 'final\ndel')" ]
rm "$TMP/promoted"
SOURCE_IPS="192.168.1.99"
promote_candidates
[ ! -f "$TMP/promoted" ]
echo 'PASS: promotion includes download bytes and respects source filter'
sed "s|^CONF=.*|CONF=\"$TMP/cli-config\"|" "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$TMP/validator"
default_config > "$TMP/cli-config"
sh "$TMP/validator" validate-config
sh "$TMP/validator" effective-config > "$TMP/cli-effective"
grep -q '^PROMOTE_MODE="auto"$' "$TMP/cli-effective"
grep -q '^STREAM_MIN_BYTES="15000000"$' "$TMP/cli-effective"
printf 'INTERFACES="$(touch %s)"\n' "$TMP/cli-executed" > "$TMP/cli-config"
if sh "$TMP/validator" validate-config; then echo 'CLI validator accepted executable config'; exit 1; fi
[ ! -e "$TMP/cli-executed" ]
echo 'PASS: migration CLI validates configuration without executing it or starting the engine'

# The menu is opened from amtm's directory, not the engine's own directory.
{
  head -n 5 "$ROOT/scripts/vpn_ipcatcher.real.sh"
  sed -n '/^menu_colors(){/,/^}/p;/^menu_line(){/p;/^print_header(){/,/^}/p' "$ROOT/scripts/vpn_ipcatcher.real.sh"
  printf '%s\n' 'SED=sed' 'load_config(){ :; }' 'say(){ printf "%s\n" "$*"; }' 'status_report(){ :; }' 'print_header'
} > "$TMP/header-fixture"
header_output="$(cd / && sh "$TMP/header-fixture")"
case "$header_output" in *"VPN IP Catcher $(cat "$ROOT/VERSION") "*) ;; *) echo 'Menu version missing'; exit 1 ;; esac
echo 'PASS: menu version is read from the invoked script outside its directory'
