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
