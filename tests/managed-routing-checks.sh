#!/bin/sh
set -eu
work="${TMPDIR:-/tmp}/vpnipc-managed-test-$$"
mkdir -p "$work/addon" "$work/sets"
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed -e '/^case "${1:-check}" in/,$d' -e '/if \[ ! -t 0 \]; then/d' addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh > "$work/lib"
set +e
. "$work/lib"
set -e
ADDON="$work/addon"; SELECTION="$ADDON/selection"; CONF="$work/conf"
GLOBAL="$work/global"; POLICIES="$work/policies"; TABLES="$work/tables"; CONFIG_LOCK="$work/config.lock"
DIRECTOR="$work/director"; PRECEDENCE_CACHE="$work/precedence.cache"
: > "$DIRECTOR"; : > "$work/filter"
printf 'ENABLE=1\nOVPNC2FWMARK=0x2000\nOVPNC2MASK=0xf000\n' > "$GLOBAL"
: > "$POLICIES"; : > "$CONF"; : > "$TABLES"; : > "$work/firewall"
printf '2000: from all fwmark 0x2000/0xf000 lookup ovpnc2\n' > "$work/rules"
mock_ip(){
  case "$1" in
    rule)
      case "$2" in
        show) cat "$work/rules" ;;
        add) case "$3" in
          unreachable) echo '31001: from all fwmark 0x1000000/0x1000000 unreachable' >> "$work/rules" ;;
          *) echo "31000: from all fwmark 0x1000000/0x1000000 lookup $CONNECTION" >> "$work/rules" ;;
        esac ;;
        del) awk -v old="$old_connection" '!($1=="31000:" && $NF==old)' "$work/rules" > "$work/rules.new"; mv "$work/rules.new" "$work/rules" ;;
      esac ;;
    route) echo 'default dev tun12' ;;
    -o) printf '1: br0: <BROADCAST,UP,LOWER_UP> mtu 1500\n2: br1: <BROADCAST> mtu 1500\n3: tun12: <UP> mtu 1500\n' ;;
    link) echo '12: interface: <UP> mtu 1500' ;;
  esac
}
mock_set(){
  action="$1"; name="$2"
  case "$action" in
    list) [ -f "$work/sets/$name" ] ;;
    create) [ -f "$work/sets/$name" ] || echo "create $name hash:ip family inet timeout 604800 counters comment" > "$work/sets/$name" ;;
    save) cat "$work/sets/$name" ;;
    add|flush) return 0 ;;
    swap) mv "$work/sets/$name" "$work/swap"; mv "$work/sets/$3" "$work/sets/$name"; mv "$work/swap" "$work/sets/$3" ;;
  esac
}
mock_firewall(){
  firewall_file="$work/firewall"
  [ "$2" != filter ] || firewall_file="$work/filter"
  shift 2
  action="$1"; shift
  if [ "$action" = -S ]; then cat "$firewall_file"; return; fi
  chain="$1"; shift
  if [ "$action" = -I ]; then shift; fi
  line="-A $chain $*"
  case "$action" in
    -C) grep -Fxq -- "$line" "$firewall_file" ;;
    -I|-A) printf '%s\n' "$line" >> "$firewall_file" ;;
    -D) awk -v line="$line" '$0!=line' "$firewall_file" > "$firewall_file.new"; mv "$firewall_file.new" "$firewall_file" ;;
  esac
}
nvram(){ echo 'Example VPN'; }
dependencies(){ return 0; }
install_dependencies(){ return 0; }
IP=mock_ip; IPSET=mock_set; IPTABLES=mock_firewall
configure || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
[ "$(sed -n '1p' "$SELECTION")" = VIPC-ovpnc2 ]
[ "$(sed -n '3p' "$SELECTION")" = managed-v1 ]
[ "$(setting "$CONF" INTERFACES)" = 'br0 ' ]
[ ! -s "$POLICIES" ]
[ "$(wc -l < "$work/firewall" | tr -d ' ')" = 2 ]
selection_read && binding_check
[ "$(wc -l < "$work/firewall" | tr -d ' ')" = 2 ]
# The owned IPTV rule must not override existing explicit DVR policy marks.
[ "$(grep -c -- '-m mark --mark 0x0/0xf000' "$work/firewall")" = 2 ]
# Simulate an upgrade from old unguarded managed-v1 rules.
sed 's/ -m set ! --match-set VPNIPC-SOURCE src -m set ! --match-set VPNIPC-DOMAINS dst -m mark --mark 0x0\/0xf000//' "$work/firewall" > "$work/old"
mv "$work/old" "$work/firewall"
if binding_check; then echo 'Old unguarded rule accepted' >&2; exit 1; fi
managed_prepare && binding_check
[ "$(grep -c -- '-m mark --mark 0x0/0xf000' "$work/firewall")" = 2 ]
[ "$(wc -l < "$work/firewall" | tr -d ' ')" = 2 ]
rm "$work/sets/$SET"
: > "$work/firewall"
if binding_check; then echo 'Missing owned routing accepted' >&2; exit 1; fi
[ ! -f "$work/sets/$SET" ]
[ ! -s "$work/firewall" ]
managed_prepare && binding_check
[ -f "$work/sets/$SET" ]
POLICY=VIPC-ovpnc1; CONNECTION=ovpnc1; MODE=managed-v1
printf 'OVPNC1FWMARK=0x1000\nOVPNC1MASK=0xf000\n' >> "$GLOBAL"
printf '1000: from all fwmark 0x1000/0xf000 lookup ovpnc1\n' >> "$work/rules"
mock_set create DVR-VIPC-ovpnc1-v4
if managed_prepare; then echo 'Unowned set overwritten' >&2; exit 1; fi
[ ! -f "$ADDON/managed-VIPC-ovpnc1" ]
rm "$work/sets/DVR-VIPC-ovpnc1-v4"
printf '1\n' > "$work/answer"
configure < "$work/answer" || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
[ "$(sed -n '1p' "$SELECTION")" = VIPC-ovpnc1 ]
if grep -q 'VPNIPC-VIPC-ovpnc2' "$work/firewall"; then echo 'Old owned VPN rules retained' >&2; exit 1; fi
[ "$(wc -l < "$work/firewall" | tr -d ' ')" = 2 ]
echo 'PASS: single VPN auto-selected, LAN detected, list/rules created and recovered, foreign policy untouched'
