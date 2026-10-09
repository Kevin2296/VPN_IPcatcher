#!/bin/sh
set -eu
work="${TMPDIR:-/tmp}/vpnipc-routing-test-$$"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed '/^case "${1:-check}" in/,$d' addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh > "$work/lib"
set +e
. "$work/lib"
set -e
POLICIES="$work/policies"; GLOBAL="$work/global"; CONF="$work/conf"; TABLES="$work/tables"
printf 'Streams|domains|addresses|ovpnc2\n' > "$POLICIES"
printf 'ENABLE=1\nOVPNC2FWMARK=0x2000\nOVPNC2MASK=0xf000\n' > "$GLOBAL"
printf 'IPSET_NAME="DVR-Streams-v4"\n' > "$CONF"
printf '200 ovpnc2\n' > "$TABLES"
printf '2000: from all fwmark 0x2000/0xf000 lookup ovpnc2\n' > "$work/rules"
printf '%s\n' '-A PREROUTING -m set --match-set DVR-Streams-v4 dst -j MARK --set-xmark 0x2000/0xf000' '-A OUTPUT -m set --match-set DVR-Streams-v4 dst -j MARK --set-xmark 0x2000/0xf000' > "$work/firewall"
mock_ip(){
  case "$1" in
    rule) cat "$work/rules" ;;
    route) echo 'default dev tun12' ;;
    link) echo '12: tun12: <UP> mtu 1500' ;;
  esac
}
mock_firewall(){ cat "$work/firewall"; }
mock_set(){ [ "$1" != save ] || echo 'create DVR-Streams-v4 hash:ip family inet timeout 86400 counters comment'; }
IP=mock_ip; IPTABLES=mock_firewall; IPSET=mock_set
POLICY=Streams; CONNECTION=ovpnc2
binding_check
printf '2000: from all fwmark 0x2000/0xf000 lookup 200\n' > "$work/rules"
binding_check
printf '2000: from all fwmark 0x2000/0xf000 lookup ovpnc1\n' > "$work/rules"
if binding_check; then echo 'Wrong VPN accepted' >&2; exit 1; fi
printf '2000: from all fwmark 0x2000/0xf000 lookup ovpnc2\n' > "$work/rules"
printf '%s\n' '-A OUTPUT -m set --match-set DVR-Streams-v4_cand dst -j MARK --set-xmark 0x2000/0xf000' >> "$work/firewall"
if binding_check; then echo 'Candidate routing accepted' >&2; exit 1; fi
mock_set(){ [ "$1" != save ] || echo 'create DVR-Streams-v4 hash:ip family inet'; }
if set_check; then echo 'Incompatible set accepted' >&2; exit 1; fi
CONNECTION=ovpnc1
if binding_read; then echo 'Wrong policy binding accepted' >&2; exit 1; fi
echo 'Routing checks passed'
# Model a router whose tr interprets character classes incorrectly.
tr(){ printf 'pvpnc1\n'; }
for number in 1 2 3 4 5; do
  printf 'OVPNC%sFWMARK=0x1000\nOVPNC%sMASK=0xf000\nWGC%sFWMARK=0x2000\nWGC%sMASK=0xf000\n' "$number" "$number" "$number" "$number" > "$GLOBAL"
  CONNECTION="ovpnc$number"
  mark_read
  [ "$key" = "OVPNC$number" ] && [ "$MARK/$MASK" = 0x1000/0xf000 ]
  CONNECTION="wgc$number"
  mark_read
  [ "$key" = "WGC$number" ] && [ "$MARK/$MASK" = 0x2000/0xf000 ]
done
CONNECTION=ovpnc6
if mark_read; then echo 'Invalid VPN accepted' >&2; exit 1; fi
CONNECTION=ovpnc1
: > "$GLOBAL"
if mark_read; then echo 'Missing VPN mark accepted' >&2; exit 1; fi
echo 'PASS: all OpenVPN/WireGuard keys work with broken tr; invalid/missing settings remain rejected'
nvram(){ printf 'Example VPN - Europe\n'; }
[ "$(connection_label ovpnc1)" = 'OpenVPN 1 - Example VPN - Europe' ]
[ "$(connection_label wgc2)" = 'WireGuard 2 - Example VPN - Europe' ]
echo 'PASS: VPN labels retain complete names even with incompatible tr'
