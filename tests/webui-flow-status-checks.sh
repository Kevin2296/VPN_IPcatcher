#!/bin/sh
# 2.10: live flows carry a readable status (router, fixed, waiting, final,
# candidate, excluded, local, watch) and the status JSON carries a fixed-route
# summary. Mocked conntrack/ipset/ip; no router commands run.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
work="${TMPDIR:-/tmp}/vpnipc-flowstatus-$$"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed '/^case "\$1" in/,$d' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh" > "$work/library"
set +e
. "$work/library"
set -e
AWK=awk
CONF="$work/config"
printf 'IPSET_NAME="Example"\nPORTS="80,443"\n' > "$CONF"
ENGINE=fixture_engine
fixture_engine(){ cat "$CONF"; }
FIXED_SETS_FILE="$work/fixed_sets"
FIXED_DOMAINS_FILE="$work/fixed_domains"
printf 'DVR-Bank-v4\n' > "$FIXED_SETS_FILE"
printf 'mijnbank.nl\nepg.example.org\n' > "$FIXED_DOMAINS_FILE"

CT=ct_mock
ct_mock(){
  row(){ printf 'tcp 6 300 ESTABLISHED src=%s dst=%s sport=5%s dport=%s packets=9 bytes=%s src=%s dst=%s sport=%s dport=5%s packets=9 bytes=0\n' "$1" "$2" "$3" "$4" "$5" "$2" "$1" "$4" "$3"; }
  row 192.168.178.20 203.0.113.1 001 443 9000000
  row 192.168.178.20 203.0.113.2 002 443 8000000
  row 192.168.178.20 203.0.113.3 003 443 7000000
  row 192.168.178.20 203.0.113.4 004 443 6000000
  row 192.168.178.20 203.0.113.5 005 443 5000000
  row 192.168.178.50 203.0.113.6 006 443 4000000
  row 192.168.179.3 203.0.113.7 007 443 3000000
  row 192.168.178.20 192.168.178.1 008 80 2000000
  row 192.168.178.20 203.0.113.9 009 443 1000000
  row 192.168.178.20 203.0.113.10 010 443 6000000000
}
IPSET=ipset_mock
ipset_mock(){
  [ "$1" = test ] || { [ "$1" = list ] && { printf 'Members:\n'; case "$2" in *_fixed) echo 203.0.113.4 ;; *_fixsrc) echo 192.168.178.50 ;; esac; }; return 0; }
  case "$2:$3" in
    Example:203.0.113.1|Example:203.0.113.10) return 0 ;;
    Example_cand:203.0.113.2) return 0 ;;
    Example_wait:203.0.113.3) return 0 ;;
    Example_fixed:203.0.113.4) return 0 ;;
    DVR-Bank-v4:203.0.113.5) return 0 ;;
    Example_fixsrc:192.168.178.50) return 0 ;;
    Example_exclude:203.0.113.9) return 0 ;;
  esac
  return 1
}
IPBIN=ip_mock
ip_mock(){ printf '%s\n' '5: br0    inet 192.168.178.1/24 scope global br0' '9: eth0    inet 192.168.179.3/24 scope global eth0'; }

live_flows_text > "$work/flows"
status_of(){ awk -v d="$1" '$3==d {print $7}' "$work/flows"; }
[ "$(status_of 203.0.113.1)" = final ]
[ "$(status_of 203.0.113.2)" = candidate ]
[ "$(status_of 203.0.113.3)" = waiting ]
[ "$(status_of 203.0.113.4)" = fixed-route ]
[ "$(status_of 203.0.113.5)" = fixed-route ]
[ "$(status_of 203.0.113.6)" = fixed-device ]
[ "$(status_of 203.0.113.7)" = router ]
[ "$(status_of 192.168.178.1)" = local ]
[ "$(status_of 203.0.113.9)" = excluded-range ]
# Byte counters above 2^31 keep their value (no integer overflow).
awk '$3=="203.0.113.10" {exit ($1+0==6000000000)?0:1}' "$work/flows"
echo 'PASS: live flows show final, candidate, waiting, fixed route/device, router, local and excluded status'

ipset_count(){ case "$1" in *_fixed) echo 1 ;; *_fixsrc) echo 1 ;; *) echo 0 ;; esac; }
fixed_routes_json > "$work/fixed.json"
if command -v jq >/dev/null 2>&1; then
  jq -e '.destinations=="1" and .devices=="1" and .destination_list=="203.0.113.4" and .device_list=="192.168.178.50" and .policies=="Bank" and .domains=="2"' "$work/fixed.json" >/dev/null
else
  grep -q '"policies":"Bank"' "$work/fixed.json"
fi
echo 'PASS: status JSON fixed-route summary'

# --- 2.10.1: destination names -------------------------------------------
NSLOOKUP=ns_mock; TIMEOUT_BIN=""
ns_mock(){
  case "$1" in
    151.101.193.140) printf 'Server:    127.0.0.1\nAddress 1: 127.0.0.1 localhost\n\nName:      151.101.193.140\nAddress 1: 151.101.193.140 fastly-edge.example.net\n' ;;
    203.0.113.66) printf '66.113.0.203.in-addr.arpa\tname = Box.Example.ORG.\n' ;;
    *) printf 'Server: 127.0.0.1\nName: %s\nAddress 1: %s\n' "$1" "$1" ;;
  esac
}
[ "$(ptr_lookup 151.101.193.140)" = fastly-edge.example.net ]
[ "$(ptr_lookup 203.0.113.66)" = box.example.org ]
[ -z "$(ptr_lookup 198.51.100.1)" ]
DIAGNOSTIC_DNS="$work/dns"; DOM2IP_CACHE="$work/dom2ip"; PTR_CACHE="$work/ptr"
printf '1761868800.1 192.168.178.20 live.iptv.example 203.0.113.70\n' > "$DIAGNOSTIC_DNS"
printf 'cdn.example.tv %s 203.0.113.71 203.0.113.72\n' "$(date +%s)" > "$DOM2IP_CACHE"
: > "$PTR_CACHE"
members='203.0.113.73 timeout 50 packets 0 bytes 0 comment "src=epg.example.org;seen=20261031-000000"
203.0.113.70 timeout 50 packets 0 bytes 0 comment "src=flow-delta1b-total2b-192.168.178.20-443;seen=x"'
destination_names_json "203.0.113.70 203.0.113.71 203.0.113.73 151.101.193.140 198.51.100.1" "$members" > "$work/names.json"
if command -v jq >/dev/null 2>&1; then
  jq -e '."203.0.113.70".n=="live.iptv.example" and ."203.0.113.70".k=="dns"
    and ."203.0.113.71".n=="cdn.example.tv"
    and ."203.0.113.73".n=="epg.example.org" and ."203.0.113.73".k=="host"
    and ."151.101.193.140".n=="fastly-edge.example.net" and ."151.101.193.140".k=="ptr"
    and (has("198.51.100.1")|not)' "$work/names.json" >/dev/null
fi
grep -q '^198.51.100.1 [0-9]* -$' "$PTR_CACHE"
echo 'PASS: destination names from DNS answers, learned hostnames and PTR (both BusyBox styles), missing PTR cached'

# --- 2.10.4: Asuswrt-Merlin has no mktemp and no "command" builtin ----------
(
  mktemp(){ echo 'mktemp: not found' >&2; return 127; }
  command(){ echo 'command: not found' >&2; return 127; }
  printf '35.190.46.17 %s downloads.claude.ai\n' "$(date +%s)" > "$work/dns_names"
  DNS_NAMES_FILE="$work/dns_names"; DIAGNOSTIC_DNS="$work/none"; DOM2IP_CACHE="$work/none"; PTR_CACHE="$work/ptr2"
  out="$(destination_names_json "35.190.46.17" "")"
  case "$out" in *'"35.190.46.17":{"n":"downloads.claude.ai","k":"dns"}'*) ;; *) echo "Names failed without mktemp: $out"; exit 1 ;; esac
  [ -z "$(ls -d /tmp/vpn_ipcatcher/names.* 2>/dev/null)" ] || { echo 'Temporary names directory left behind'; exit 1; }
)
if grep -n 'mktemp -d\|command -v' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh" "$ROOT/scripts/vpn_ipcatcher.real.sh" | grep -v '^\s*#'; then
  echo 'Router scripts depend on mktemp/command, which Asuswrt-Merlin lacks'; exit 1
fi
echo 'PASS: destination names work without mktemp and without the command builtin'
