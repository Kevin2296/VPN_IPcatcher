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
cp "$ROOT/scripts/vpn_ipcatcher.conf" "$CONF"
load_config
[ "$PROMOTE_EVERY" = 60 ]
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
