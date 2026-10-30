#!/bin/sh
# 2.9.16: fixed routes (VPN Director / Domain VPN Routing), capture parsing,
# LAN-only flow scan, single conntrack dump per promotion, cache expiry and
# provider lock recovery. Mocked: no router commands run on the CI host.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/vpnipc-fixed-$$"
mkdir -p "$TMP/ipsets" "$TMP/cache" "$TMP/dvr"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
sed '/^case "\$1" in/,$d' "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$TMP/library"
set +e
. "$TMP/library"
set -e
AWK=awk; SED=sed; GREP=grep; TR=tr; TAIL=tail
CACHE_DIR="$TMP/cache"
CACHE_DOM2IP="$CACHE_DIR/dom2ip"
CACHE_PTR="$CACHE_DIR/ptr_cache"
CACHE_FIXED_DOMAINS="$CACHE_DIR/fixed_domains"
CACHE_FIXED_SETS="$CACHE_DIR/fixed_sets"
CACHE_FIXED_SIG="$CACHE_DIR/fixed.sig"
FLOW_STATE="$CACHE_DIR/flow_prev"
VPNDIRECTOR_RULES="$TMP/vpndirector_rulelist"
DVR_POLICY_DIR="$TMP/dvr"
LOGFILE="$TMP/log"
SYSTEM_EXCLUDE_IPS=""; EXCLUDE_IPS=""; EXCLUDE_RESOLVE_CACHE=no; REVERSE_DNS_CHECK=no
EXCLUDE_NET_SET="vpnipc_test_exclude"
log(){ printf '%s\n' "$*" >> "$TMP/log"; }

# Minimal file-backed ipset. hash:net membership is evaluated with CIDR math.
ipset_mock(){
  case "$1" in
    -n) ls "$TMP/ipsets" ;;
    create) : > "$TMP/ipsets/$2" ;;
    list)
      [ "${2:-}" = -t ] && { for f in "$TMP/ipsets"/*; do [ -e "$f" ] && echo "Name: ${f##*/}"; done; return 0; }
      [ -f "$TMP/ipsets/$2" ] || return 1
      printf 'Name: %s\nMembers:\n' "$2"; cat "$TMP/ipsets/$2" ;;
    add) [ -f "$TMP/ipsets/$2" ] || return 1; grep -qx "$3" "$TMP/ipsets/$2" 2>/dev/null || echo "$3" >> "$TMP/ipsets/$2" ;;
    del) [ -f "$TMP/ipsets/$2" ] || return 1; awk -v e="$3" '$1!=e' "$TMP/ipsets/$2" > "$TMP/ipsets/.del"; mv "$TMP/ipsets/.del" "$TMP/ipsets/$2" ;;
    destroy) rm -f "$TMP/ipsets/$2" ;;
    swap) mv "$TMP/ipsets/$2" "$TMP/ipsets/.swap"; mv "$TMP/ipsets/$3" "$TMP/ipsets/$2"; mv "$TMP/ipsets/.swap" "$TMP/ipsets/$3" ;;
    save) [ -f "$TMP/ipsets/$2" ] || return 1
      echo "create $2 hash:ip"
      awk -v s="$2" '{c=$2; print "add", s, $1, (c!=""?"comment \"" c "\"":"")}' "$TMP/ipsets/$2" ;;
    test)
      [ -f "$TMP/ipsets/$2" ] || return 1
      awk -v ip="$3" '
        function n(x, a) {split(x, a, "."); return ((a[1]*256+a[2])*256+a[3])*256+a[4]}
        { split($1, c, "/"); len = (c[2] == "" ? 32 : c[2]); size = 2 ^ (32 - len)
          if (int(n(ip) / size) == int(n(c[1]) / size)) f = 1 }
        END {exit f ? 0 : 1}' "$TMP/ipsets/$2" ;;
  esac
}
IPSET=ipset_mock
IPSET_NAME="DVR-VIPC-wgc1-v4"
FIXED_DST_SET="${IPSET_NAME}_fixed"
FIXED_SRC_SET="${IPSET_NAME}_fixsrc"
CAND_SET="${IPSET_NAME}_cand"
WAIT_SET="${IPSET_NAME}_wait"

# --- VPN Director parsing ----------------------------------------------------
printf '%s' '<1>Tv-box>192.168.178.50>>WGC1<0>Uit>192.168.178.51>>OVPN1<1>Nieuws>>203.0.113.0/24>WAN<1>Mix>192.168.178.60>198.51.100.7>OVPN2<1>Alles>192.168.178.70>0.0.0.0/0>WAN<1>Fout>>999.1.1.1>WAN<1>Breed>>10.0.0.0/0>WAN' > "$VPNDIRECTOR_RULES"
vpndirector_fixed_entries > "$TMP/director"
expected="$(printf 'src 192.168.178.50\ndst 203.0.113.0/24\ndst 198.51.100.7\nsrc 192.168.178.70')"
[ "$(cat "$TMP/director")" = "$expected" ] || { echo 'VPN Director parse mismatch:'; cat "$TMP/director"; exit 1; }
echo 'PASS: VPN Director rules: enabled only, device-wide vs destination, WAN included, /0 and invalid rejected'

# --- Domain VPN Routing policies ---------------------------------------------
printf '%s\n' '# comment' 'Streams|x|y|ovpnc1' 'Bank|x|y|wan' 'VIPC-ovpnc1|x|y|ovpnc1' 'DVR-own|x|y|wgc1' > "$DVR_POLICY_DIR/domain_vpn_routing.conf"
printf '%s\n' 'epg.example.org' '*.Wildcard.Example' > "$DVR_POLICY_DIR/policy_Streams_domainlist"
printf '%s\n' 'mijnbank.nl' > "$DVR_POLICY_DIR/policy_Bank_domainlist"
ipset_mock create DVR-Streams-v4; ipset_mock add DVR-Streams-v4 192.0.2.44
ipset_mock create DVR-Bank-v4; ipset_mock add DVR-Bank-v4 192.0.2.80
[ "$(dvr_fixed_policies | tr '\n' ' ')" = 'Streams Bank DVR-own ' ]
IPSET_NAME="DVR-Streams-v4"
[ "$(dvr_fixed_policies | tr '\n' ' ')" = 'Bank DVR-own ' ] || { echo 'Own reused policy not excluded'; exit 1; }
IPSET_NAME="DVR-VIPC-wgc1-v4"
echo 'PASS: VPN Routing policies exclude the own target list and IP Catcher managed lists'

refresh_fixed_routes force
[ "$FIXED_ROUTES_CHANGED" = 1 ]
grep -qx 'epg.example.org' "$CACHE_FIXED_DOMAINS"
grep -qx 'wildcard.example' "$CACHE_FIXED_DOMAINS"
grep -qx 'mijnbank.nl' "$CACHE_FIXED_DOMAINS"
[ "$(cat "$CACHE_FIXED_SETS" | tr '\n' ' ')" = 'DVR-Streams-v4 DVR-Bank-v4 ' ]
ip_is_fixed 203.0.113.200
ip_is_fixed 198.51.100.7
ip_is_fixed 192.0.2.44
ip_is_fixed 192.0.2.80
if ip_is_fixed 198.51.100.8; then echo 'Unrelated destination treated as fixed'; exit 1; fi
source_is_fixed 192.168.178.50
if source_is_fixed 192.168.178.60; then echo 'Destination-specific rule treated as device-wide'; exit 1; fi
if source_is_fixed 192.168.178.51; then echo 'Disabled rule used'; exit 1; fi
domain_is_fixed epg.example.org
domain_is_fixed cdn.epg.example.org
if domain_is_fixed notepg.example.org; then echo 'Domain boundary failed'; exit 1; fi
if domain_is_fixed example.org; then echo 'Parent domain treated as fixed'; exit 1; fi
ip_is_excluded 192.0.2.44
echo 'PASS: fixed destinations, devices, VPN Routing IPSets and domains are recognised'

refresh_fixed_routes auto
[ "$FIXED_ROUTES_CHANGED" = 0 ] || { echo 'Unchanged configuration rebuilt'; exit 1; }
printf '%s' '<1>Tv-box>192.168.178.50>>WGC1<1>Extra>>203.0.114.9>OVPN1' > "$VPNDIRECTOR_RULES"
refresh_fixed_routes auto
[ "$FIXED_ROUTES_CHANGED" = 1 ]
ip_is_fixed 203.0.114.9
if ip_is_fixed 203.0.113.200; then echo 'Removed VPN Director rule still active'; exit 1; fi
echo 'PASS: fixed routes rebuild only after a router configuration change'

# Learned entries for a newly fixed destination are purged; DVR-owned entries
# (no src= comment) in the target list are left alone.
ipset_mock create "$IPSET_NAME"; ipset_mock create "$CAND_SET"; ipset_mock create "$WAIT_SET"
printf '%s\n' '203.0.114.9 src=flow;seen=1' '192.0.2.44 dvr' '198.51.100.99 src=flow;seen=1' > "$TMP/ipsets/$IPSET_NAME"
purge_fixed_from_sets
cut -d' ' -f1 "$TMP/ipsets/$IPSET_NAME" | tr '\n' ' ' | grep -qx '192.0.2.44 198.51.100.99 ' || { echo 'Purge mismatch'; cat "$TMP/ipsets/$IPSET_NAME"; exit 1; }
echo 'PASS: purge removes only IP Catcher-learned fixed destinations'

# --- Capture path --------------------------------------------------------------
PORTS="80,443"; CAPTURE_GENERIC_HOSTNAMES=no; PROMOTE_MODE=bytes
printf '%s\n' \
  '00:12:28.1 IP 192.168.178.20.51234 > 203.0.113.9.80: Flags [P.], length 119' 'GET /live.ts HTTP/1.1' 'Host: Stream.Example.TV' \
  '00:12:28.2 IP 203.0.113.9.80 > 192.168.178.20.51234: Flags [P.], length 90' 'HTTP/1.1 302 Found' 'Location: http://198.51.100.7/live.ts' \
  '00:12:28.3 IP 192.168.178.20.51235 > 203.0.113.9.80: Flags [P.], length 119' 'Host: stream.example.tv' \
  | capture_parse > "$TMP/parsed"
[ "$(cat "$TMP/parsed")" = "$(printf 'dom 192.168.178.20 stream.example.tv\nip 192.168.178.20 198.51.100.7')" ] || { cat "$TMP/parsed"; exit 1; }
CAPTURE_GENERIC_HOSTNAMES=yes
printf '%s\n' '00:12:30.0 IP 192.168.178.21.5000 > 203.0.113.10.443: Flags [P.], length 500' '....cdn.iptv-example.net....' | capture_parse | grep -qx 'dom 192.168.178.21 cdn.iptv-example.net'
echo 'PASS: one awk parser extracts Host/Location/SNI with client address and suppresses duplicates'

SOURCE_IPS=""
build_bpf
case "$BPF" in *'tcp[((tcp[12:1] & 0xf0) >> 2):1] = 0x16'*'0x47455420'*) ;; *) echo "BPF lacks payload filter: $BPF"; exit 1 ;; esac
echo 'PASS: BPF only captures TLS handshakes and HTTP headers'

(
  learned=""
  learn_ip(){ learned="$learned $1"; }
  resolve_once(){ echo 203.0.113.77; }
  EXCLUDE_DOMAINS=""
  handle_capture_finding dom 192.168.178.50 stream.example.tv
  handle_capture_finding dom 192.168.178.20 cdn.epg.example.org
  handle_capture_finding ip 192.168.178.50 198.51.100.40
  [ -z "$learned" ] || { echo "Fixed source/domain learned:$learned"; exit 1; }
  handle_capture_finding dom 192.168.178.20 stream.example.tv
  [ "$learned" = ' 203.0.113.77' ]
)
echo 'PASS: findings from VPN Director devices or VPN Routing domains are never learned'

# --- Flow scan -----------------------------------------------------------------
flow_rows(){
  cat <<EOF
tcp 6 300 ESTABLISHED src=192.168.178.20 dst=145.53.10.30 sport=50000 dport=443 packets=9 bytes=$1 src=145.53.10.30 dst=192.168.178.20 sport=443 dport=50000 packets=9 bytes=0
tcp 6 300 ESTABLISHED src=192.168.178.1 dst=145.53.10.31 sport=50001 dport=443 packets=9 bytes=$1 src=145.53.10.31 dst=192.168.178.1 sport=443 dport=50001 packets=9 bytes=0
tcp 6 300 ESTABLISHED src=100.70.1.2 dst=145.53.10.32 sport=50002 dport=443 packets=9 bytes=$1 src=145.53.10.32 dst=100.70.1.2 sport=443 dport=50002 packets=9 bytes=0
tcp 6 300 ESTABLISHED src=192.168.178.50 dst=145.53.10.33 sport=50003 dport=443 packets=9 bytes=$1 src=145.53.10.33 dst=192.168.178.50 sport=443 dport=50003 packets=9 bytes=0
EOF
}
FLOW_BYTES=20000000
conntrack_mock(){ echo call >> "$TMP/ct-calls"; flow_rows "$FLOW_BYTES"; }
CT=conntrack_mock; ACCT_OK=1; STREAM_FLOW_SCAN=yes; SOURCE_IPS=""; PORTS="80,443"
STREAM_MIN_BYTES=15000000; STREAM_MIN_DELTA=750000; STREAM_REQUIRE_GROWTH=yes; STREAM_FLOW_TARGET=candidate
REVERSE_DNS_CHECK=no; EXCLUDE_RESOLVE_CACHE=no; EXCLUDE_IPS=""
LAN_NETS=" 192.168.178.1/24"; ROUTER_IPS=" 192.168.178.1"
refresh_exclusion_ip_cache(){ :; }
candidates=""
add_candidate_once(){ candidates="$candidates $1"; }
rm -f "$FLOW_STATE"
flow_scan_candidates
[ -z "$candidates" ] || { echo "First scan without growth learned:$candidates"; exit 1; }
FLOW_BYTES=40000000
flow_scan_candidates
[ "$candidates" = ' 145.53.10.30' ] || { echo "Flow scan learned:$candidates"; exit 1; }
grep -q '^192.168.178.20|145.53.10.30|443 40000000$' "$FLOW_STATE"
echo 'PASS: flow scan uses deltas, LAN clients only, never the router itself or VPN Director devices'

# --- Promotion: one conntrack dump per cycle -------------------------------------
: > "$TMP/ct-calls"
ipset_promote(){
  case "$1" in
    list) printf 'Members:\n145.53.10.30 timeout 500\n145.53.10.33 timeout 500\n145.53.10.31 timeout 500\n' ;;
    del) echo "del $3" >> "$TMP/promoted" ;;
    *) ipset_mock "$@" ;;
  esac
}
IPSET=ipset_promote
should_skip_service_ip(){ return 1; }
add_final_immediate(){ echo "final $1" >> "$TMP/promoted"; }
PROMOTE_MODE=bytes; MIN_AGE=20; MIN_BYTES=3000000; CANDIDATE_TIMEOUT=600; SOURCE_IPS=""
promote_candidates
[ "$(wc -l < "$TMP/ct-calls" | tr -d ' ')" = 1 ] || { echo 'conntrack dumped more than once per cycle'; exit 1; }
grep -qx 'final 145.53.10.30' "$TMP/promoted"
grep -qx 'final 145.53.10.31' "$TMP/promoted"
[ -z "$(ls "$CACHE_DIR" | grep promote-totals || :)" ] || { echo 'Totals file left behind'; exit 1; }
echo 'PASS: bytes promotion reads conntrack once per cycle and cleans up'
IPSET=ipset_mock

# --- DNS / PTR cache expiry ---------------------------------------------------
test_now=10000
current_epoch(){ echo "$test_now"; }
printf '%s\n' 'old.example 198.51.100.1' > "$CACHE_DOM2IP"
[ -z "$(cache_get old.example)" ] || { echo 'Pre-2.9.16 cache line used'; exit 1; }
cache_put fresh.example '198.51.100.2 198.51.100.3'
[ "$(cache_get fresh.example)" = '198.51.100.2 198.51.100.3' ]
test_now=$((10000 + DNS_CACHE_TTL))
[ -z "$(cache_get fresh.example)" ] || { echo 'Expired DNS cache entry used'; exit 1; }
cache_put other.example 198.51.100.4
if grep -q 'fresh.example\|old.example' "$CACHE_DOM2IP"; then echo 'Expired entries not pruned'; exit 1; fi
[ ! -e "${CACHE_DOM2IP}.lock" ]
NSLOOKUP=nslookup_mock
nslookup_mock(){ echo call >> "$TMP/ns-calls"; }
reverse_lookup_ip 198.51.100.9 >/dev/null
reverse_lookup_ip 198.51.100.9 >/dev/null
[ "$(wc -l < "$TMP/ns-calls" | tr -d ' ')" = 1 ] || { echo 'Missing PTR not cached'; exit 1; }
echo 'PASS: DNS answers expire, old cache lines are ignored, missing PTR records are cached'

# --- Unique temp paths in subshells ---------------------------------------------
MKTEMP=""
( make_temp_file "$CACHE_DIR/race" > "$TMP/t1" ) &
( make_temp_file "$CACHE_DIR/race" > "$TMP/t2" ) &
wait
[ -s "$TMP/t1" ] && [ -s "$TMP/t2" ] && [ "$(cat "$TMP/t1")" != "$(cat "$TMP/t2")" ] || { echo 'Temp path collision between workers'; exit 1; }
echo 'PASS: temporary files are unique between background workers'

# --- Provider lock recovery -----------------------------------------------------
PROVIDER_LOCK="$TMP/provider-lock"
mkdir "$PROVIDER_LOCK"; echo 999999 > "$PROVIDER_LOCK/pid"
provider_lock_acquire || { echo 'Stale provider lock not recovered'; exit 1; }
if provider_lock_acquire; then echo 'Live provider lock taken twice'; exit 1; fi
provider_lock_release
[ ! -e "$PROVIDER_LOCK" ]
echo 'PASS: an interrupted provider refresh no longer blocks later refreshes'
