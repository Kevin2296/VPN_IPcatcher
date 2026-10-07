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
printf 'ENABLE=1\nOVPNC2FWMARK=0x2000\nOVPNC2MASK=0xf000\n' > "$GLOBAL"
: > "$POLICIES"; : > "$CONF"; : > "$TABLES"; : > "$work/firewall"
printf '2000: from all fwmark 0x2000/0xf000 lookup ovpnc2\n' > "$work/rules"
mock_ip(){
  case "$1" in
    rule) cat "$work/rules" ;;
    route) echo 'default dev tun12' ;;
    -o) printf '1: br0: <BROADCAST,UP,LOWER_UP> mtu 1500\n2: br1: <BROADCAST> mtu 1500\n3: tun12: <UP> mtu 1500\n' ;;
    link) echo '12: interface: <UP> mtu 1500' ;;
  esac
}
mock_set(){
  action="$1"; name="$2"
  case "$action" in
    list) [ -f "$work/sets/$name" ] ;;
    create) echo "create $name hash:ip family inet timeout 604800 counters comment" > "$work/sets/$name" ;;
    save) cat "$work/sets/$name" ;;
  esac
}
mock_firewall(){
  shift 2
  action="$1"; shift
  if [ "$action" = -S ]; then cat "$work/firewall"; return; fi
  chain="$1"; shift
  if [ "$action" = -I ]; then shift; fi
  line="-A $chain $*"
  case "$action" in
    -C) grep -Fxq -- "$line" "$work/firewall" ;;
    -I|-A) printf '%s\n' "$line" >> "$work/firewall" ;;
    -D) awk -v line="$line" '$0!=line' "$work/firewall" > "$work/firewall.new"; mv "$work/firewall.new" "$work/firewall" ;;
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
