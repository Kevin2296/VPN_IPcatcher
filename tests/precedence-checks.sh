#!/bin/sh
set -eu
root="$(pwd)"
work="${TMPDIR:-/tmp}/vpnipc-precedence-$$"
mkdir -p "$work/addon"
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed '/^case "${1:-check}" in/,$d' addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh > "$work/lib"
set +e
. "$work/lib"
set -e
PYTHON="${PYTHON:-python3}"
export ROUTER_MODEL="$work/kernel.json"
model(){ "$PYTHON" "$root/tests/router-model.py" "$@"; }
IPSET=mock_set; IPTABLES=mock_firewall; IP=mock_ip
mock_set(){ model ipset "$@"; }
mock_firewall(){ model iptables "$@"; }
mock_ip(){
  case "$1" in
    rule) model ip "$@" ;;
    route) [ "${offline:-no}" != yes ] || return 0; echo 'default dev tun12' ;;
    link) echo '12: tun12: <UP> mtu 1500' ;;
  esac
}
# When run by CI's BusyBox ash, exercise the actual BusyBox awk parser too.
if command -v busybox >/dev/null 2>&1; then awk(){ busybox awk "$@"; }; fi
ADDON="$work/addon"; CONF="$work/conf"; GLOBAL="$work/global"
POLICIES="$work/policies"; DIRECTOR="$work/director"; TABLES="$work/tables"
SELECTION="$work/selection"; PRECEDENCE_CACHE="$work/cache"; PRECEDENCE_STATUS="$work/status"
printf 'IPSET_NAME="DVR-VIPC-ovpnc2-v4"\nBYPASS_SOURCE_IPS="192.168.178.83"\n' > "$CONF"
printf 'ENABLE=1\nOVPNC2FWMARK=0x2000\nOVPNC2MASK=0xf000\n' > "$GLOBAL"
printf '<1>Fixed TV>192.168.178.82>>OVPN1<1>Subnet>192.168.20.0/24>>WGC2<0>Disabled>192.168.178.84>>OVPN1<1>Remote>>198.51.100.0/24>WAN' > "$DIRECTOR"
printf 'Movies|domains|ips|wgc1\nDirect|domains|ips|wan\n' > "$POLICIES"
: > "$TABLES"
POLICY=VIPC-ovpnc2; CONNECTION=ovpnc2; MODE=managed-v1
model ip rule add from all fwmark 0x2000/0xf000 lookup ovpnc2 priority 2000
model ip rule add from 192.168.178.82 lookup ovpnc1 priority 10000
mock_set create DVR-Movies-v4 hash:ip family inet timeout 100 counters comment
mock_set create DVR-Direct-v4 hash:ip family inet timeout 100 counters comment
mock_set add DVR-Movies-v4 203.0.113.10
mock_set add DVR-Direct-v4 203.0.113.11
managed_prepare && binding_check && release_hold
if source_unprotected 192.168.20.99; then echo 'Director CIDR source accepted'; exit 1; fi
source_unprotected 192.168.21.99
# Reserved bit/priority collisions must never silently repurpose foreign rules.
model ip rule add from all fwmark 0x2000000/0x3000000 lookup main priority 29999
if dynamic_rule_prepare; then echo 'Overlapping mark mask accepted'; exit 1; fi
model ip rule del from all fwmark 0x2000000/0x3000000 lookup main priority 29999
model ip rule add from all lookup main priority 31000
if dynamic_rule_prepare; then echo 'Foreign reserved priority accepted'; exit 1; fi
model ip rule del from all lookup main priority 31000
model ip rule del unreachable from all fwmark "$DYNAMIC_MARK" priority 31001
if binding_check; then echo 'Missing terminal RPDB rule accepted'; exit 1; fi
dynamic_rule_prepare && binding_check
mock_set add "$SET" 203.0.113.10
mock_set add "$SET" 203.0.113.11
mock_set add "$SET" 203.0.113.12
mock_set add "$SET" 198.51.100.10
packet(){ actual="$(model packet "$@")"; [ "$actual" = "$expected" ] || { echo "Unexpected packet result: $* => $actual expected $expected"; exit 1; }; }
expected='0x0 allowed'
packet 192.168.178.82 203.0.113.12 eth0 0
packet 192.168.178.83 203.0.113.12 eth0 0
packet 192.168.20.99 203.0.113.12 eth0 0
packet 192.168.178.84 203.0.113.10 eth0 0
packet 192.168.178.84 203.0.113.11 eth0 0
packet 192.168.178.84 198.51.100.10 eth0 0
expected='0xa000 allowed'; packet 192.168.178.84 203.0.113.12 eth0 0xa000
expected='0x1000000 allowed'; packet 192.168.178.84 203.0.113.12 tun12 0
expected='0x1000000 blocked'; packet 192.168.178.84 203.0.113.12 eth0 0
expected='0x0 blocked'; packet 192.168.178.84 203.0.113.12 eth0 0 clear-mark
# A newly applied source rule wins at RPDB level even if a packet still carries
# the Catcher bit before the next guard refresh. An empty VPN table terminates.
[ "$(model lookup 192.168.178.82 0x1000000 none)" = ovpnc1 ]
[ "$(model lookup 192.168.178.84 0x1000000 none)" = ovpnc2 ]
[ "$(model lookup 192.168.178.84 0x1000000 ovpnc2)" = unreachable ]
# DVR populates a protected set after prepare: no Catcher refresh is needed.
mock_set add DVR-Movies-v4 203.0.113.12
expected='0x0 allowed'; packet 192.168.178.84 203.0.113.12 eth0 0
# A failed refresh must keep old guards. Offline means reject, never erase marks.
before="$(mock_set save VPNIPC-SOURCE)"
printf '<1>Broken>999.1.1.1>>OVPN1' > "$DIRECTOR"
if precedence_prepare; then echo 'Malformed director accepted'; exit 1; fi
[ "$(mock_set save VPNIPC-SOURCE)" = "$before" ]
offline=yes
if managed_prepare; then echo 'Offline VPN accepted'; exit 1; fi
hold_routing
expected='0x0 blocked'; packet 192.168.178.84 203.0.113.12 eth0 0
offline=no
printf '<1>Fixed TV>192.168.178.82>>OVPN1' > "$DIRECTOR"
managed_prepare && binding_check && release_hold
# Missing director data must not be interpreted as an empty configuration.
mv "$DIRECTOR" "$DIRECTOR.saved"
if precedence_prepare; then echo 'Missing director accepted'; exit 1; fi
mv "$DIRECTOR.saved" "$DIRECTOR"
for invalid in 999.1.1.1 1.2.3 01.2.3.4 1.2.3.4/33 '1.2.3.4;id'; do
  if valid_network "$invalid"; then echo "Invalid network accepted: $invalid"; exit 1; fi
done
valid_network 192.168.20.0/24
# Legacy shared binding migration preserves all external policy data and records
# a private restore point. It deliberately does not copy mixed learned/domain IPs.
export ROUTER_MODEL="$work/migration-kernel.json"
model ip rule add from all fwmark 0x2000/0xf000 lookup ovpnc2 priority 2000
printf 'Bound|domains|ips|ovpnc2\n' > "$POLICIES"
mock_set create DVR-Bound-v4 hash:ip family inet timeout 100 counters comment
mock_set add DVR-Bound-v4 203.0.113.55
printf 'IPSET_NAME="DVR-Bound-v4"\n' > "$CONF"
printf 'Bound\novpnc2\n' > "$SELECTION"
for chain in PREROUTING OUTPUT; do
  mock_firewall -t mangle -A "$chain" -m set --match-set DVR-Bound-v4 dst -j MARK --set-xmark 0x2000/0xf000
done
selection_read && migrate_binding && binding_check && release_hold
[ "$(setting "$CONF" IPSET_NAME)" = DVR-VIPC-ovpnc2-v4 ]
[ "$(cat "$ADDON/precedence-migration/state")" = committed ]
mock_set test DVR-Bound-v4 203.0.113.55
if mock_set test DVR-VIPC-ovpnc2-v4 203.0.113.55; then echo 'Mixed external IPs copied'; exit 1; fi
rollback_migration
[ "$(model lookup 192.168.178.84 0x1000000 none)" = main ]
[ "$(setting "$CONF" IPSET_NAME)" = DVR-Bound-v4 ]
mock_set test DVR-Bound-v4 203.0.113.55
# Simulate termination after replacing config, before selecting the new binding.
printf pending > "$ADDON/precedence-migration/state"
printf 'IPSET_NAME="Interrupted"\n' > "$CONF"
recover_migration
[ "$(setting "$CONF" IPSET_NAME)" = DVR-Bound-v4 ]
[ ! -d "$ADDON/precedence-migration" ]
echo 'PASS: shared binding migration, no external set mutation/copy, explicit rollback and interrupted transaction recovery'
# Production learning source checks must use the same live source guard.
sed -n '/^source_ip_allowed(){/,/^}/p' scripts/vpn_ipcatcher.real.sh > "$work/source-lib"
. "$work/source-lib"
valid_ipv4(){ valid_network "$1"; }
SOURCE_IPS=''; BYPASS_SOURCE_IPS=''
ROUTING_HELPER="$work/source-probe"
printf '#!/bin/sh\n[ "$1" = source-unprotected ]\n' > "$ROUTING_HELPER"
chmod +x "$ROUTING_HELPER"
if source_unprotected 192.168.178.82; then echo 'Current director source accepted'; exit 1; fi
source_unprotected 192.168.178.84
# Verify source discovery does not wait for kernel set refresh.
printf '<1>New source>192.168.178.85>>OVPN1' >> "$DIRECTOR"
if source_unprotected 192.168.178.85; then echo 'New director source accepted'; exit 1; fi
if source_ip_allowed 192.168.178.82; then echo 'Protected source learned'; exit 1; fi
source_ip_allowed 192.168.178.84
sed -n '/^capture_iface(){/,/^}/p' scripts/vpn_ipcatcher.real.sh > "$work/capture-lib"
. "$work/capture-lib"
mock_capture(){
  printf '%s\n' 'Host: orphan.example.invalid' \
    '12:00:00.123456 IP 192.168.178.82.5000 > 203.0.113.12.80: Flags [P.]' \
    'Host: protected.example.invalid' \
    '12:00:00.234567 IP 203.0.113.12.80 > 192.168.178.82.5000: Flags [P.]' \
    'Location: https://203.0.113.66/movie' \
    '12:00:01.123456 IP 192.168.178.84.5000 > 203.0.113.12.80: Flags [P.]' \
    'Host: allowed.example.invalid'
}
safe_domain(){ printf '%s\n' "$1"; }
domain_is_excluded(){ return 1; }
resolve_once(){ echo 203.0.113.81; }
add_final_immediate(){ printf '%s\n' "$2" >> "$work/learned"; }
add_candidate_once(){ printf '%s\n' "$2" >> "$work/learned"; }
log(){ :; }
TCPDUMP=mock_capture; SED=sed; GREP=grep; IPBIN=''; LOGFILE="$work/capture.log"
RETRY_DELAY=1; MAX_RETRY_DELAY=1; PROMOTE_MODE=immediate; CAPTURE_GENERIC_HOSTNAMES=no
BPF=tcp
(sleep(){ exit 0; }; capture_iface br0)
[ "$(cat "$work/learned")" = allowed.example.invalid ]
echo 'PASS: production HTTP capture rejects protected-source and orphan payload'
echo 'PASS: production rules preserve sources, CIDRs, disabled rules, WAN policies, overlapping/live DVR IPs, foreign marks and fail-closed egress'
