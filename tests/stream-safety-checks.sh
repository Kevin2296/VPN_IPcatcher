#!/bin/sh
set -eu
work="${TMPDIR:-/tmp}/vpnipc-stream-test-$$"
mkdir "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed '/^case "\$1" in/,$d' scripts/vpn_ipcatcher.real.sh > "$work/lib"
set +e
. "$work/lib"
set -e
CACHE_DIR="$work"; AWK=awk; CT=mock_conntrack; IPSET=mock_ipset
IPSET_NAME=Final; WAIT_SET=Waiting; CAND_SET=Candidate; FINAL_TIMEOUT=86400
learning_route_ready(){ return 0; }
should_skip_service_ip(){ return 1; }
make_ipset_comment(){ echo "$1"; }
mock_conntrack(){ [ ! -f "$work/fail" ] || return 1; cat "$work/connections"; }
mock_ipset(){
  case "$1" in
    test) [ "$2" = Final ] && [ -f "$work/existing" ] ;;
    add) printf '%s %s\n' "$2" "$3" >> "$work/additions" ;;
    save) echo 'add Waiting 203.0.113.20' ;;
    del) printf '%s %s\n' "$2" "$3" >> "$work/deletions" ;;
  esac
}
printf '%s\n' 'tcp 6 200 ESTABLISHED src=192.0.2.10 dst=203.0.113.20 sport=1234 dport=443 src=203.0.113.20 dst=192.0.2.10' > "$work/connections"
if add_final_immediate 203.0.113.20 test; then echo 'Active stream rerouted' >&2; exit 1; fi
[ "$(cat "$work/additions")" = 'Waiting 203.0.113.20' ]
rm "$work/additions"
printf '%s\n' 'udp 17 100 src=192.0.2.11 dst=203.0.113.20 sport=5555 dport=8443 src=203.0.113.20 dst=192.0.2.11' > "$work/connections"
if add_final_immediate 203.0.113.20 test; then echo 'UDP/other client rerouted' >&2; exit 1; fi
rm "$work/additions"
: > "$work/connections"
promote_deferred
[ "$(cat "$work/additions")" = 'Final 203.0.113.20' ]
[ "$(cat "$work/deletions")" = "$(printf 'Waiting 203.0.113.20\nCandidate 203.0.113.20')" ]
rm "$work/additions"
: > "$work/fail"
if add_final_immediate 203.0.113.20 test; then echo 'Failed conntrack check accepted' >&2; exit 1; fi
[ "$(cat "$work/additions")" = 'Waiting 203.0.113.20' ]
rm "$work/additions"
: > "$work/existing"
add_final_immediate 203.0.113.20 test
[ "$(cat "$work/additions")" = 'Final 203.0.113.20' ]
echo 'PASS: TCP/UDP active destinations defer, idle destinations drain, failures block, existing routes refresh'
