#!/bin/sh
# 2.10.6: idempotent hook install, DVR mark restore after a firewall restart,
# known-service guard by looked-up DNS name, curl in /usr/sbin.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
work="${TMPDIR:-/tmp}/vpnipc-2106-$$"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
fail(){ echo "FAIL: $*" >&2; exit 1; }

# ---------------------------------------------------------------- installer
sed '$d' "$ROOT/addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh" > "$work/installer"
grep -q '^main "\$@"$' "$ROOT/addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh" || fail "installer layout changed"
(
  set +e
  . "$work/installer"
  set -e
  log(){ :; }
  hooks="$work/scripts"; mkdir -p "$hooks"
  ADDON_DIR="$work/addon"; HOOK_BACKUP_DIR="$ADDON_DIR/hook-backups"
  SERVICE_EVENT="$hooks/service-event"; SERVICES_START="$hooks/services-start"; FIREWALL_START="$hooks/firewall-start"
  # A hook as found on a router: other addons, our old block and the blank
  # lines that older installers left behind on every run.
  printf '#!/bin/sh\nsh /jffs/addons/flexqos/flexqos.sh -start & # FlexQoS Addition\n\n\n\n# BEGIN vpn_ipcatcher firewall\nold\n# END vpn_ipcatcher firewall\n\n\n' > "$FIREWALL_START"
  printf '#!/bin/sh\n/jffs/scripts/scribe service_event "$@" & # added by scribe\n' > "$SERVICE_EVENT"
  printf '#!/bin/sh\n/jffs/scripts/YazDHCP startup "$@" & # YazDHCP\n' > "$SERVICES_START"
  # Five legacy backups next to the hook, plus one the user made.
  for s in 20261001-000001 20261002-000001 20261003-000001 20261004-000001 20261005-000001; do
    printf 'x\n' > "$FIREWALL_START.bak.$s"
  done
  printf 'x\n' > "$SERVICE_EVENT.bak-vpnipc-20260712-185415"
  printf 'mine\n' > "$FIREWALL_START.bak"
  migrate_hook_backups
  [ ! -e "$FIREWALL_START.bak.20261005-000001" ] || fail "legacy backup not moved"
  [ -f "$FIREWALL_START.bak" ] || fail "user backup touched"
  [ "$(ls "$HOOK_BACKUP_DIR" | grep -c '^firewall-start\.')" = 3 ] || fail "more than 3 firewall-start backups kept"
  [ -f "$HOOK_BACKUP_DIR/firewall-start.20261005-000001" ] || fail "newest backup not kept"
  [ ! -f "$HOOK_BACKUP_DIR/firewall-start.20261001-000001" ] || fail "oldest backup not pruned"
  [ -f "$HOOK_BACKUP_DIR/service-event.20260712-185415" ] || fail "vpnipc backup not moved"

  install_firewall_start_block; install_service_event_block; install_services_start_block
  [ "$(grep -c 'BEGIN vpn_ipcatcher firewall' "$FIREWALL_START")" = 1 ] || fail "block duplicated"
  grep -q '^old$' "$FIREWALL_START" && fail "old block kept"
  grep -q 'FlexQoS Addition' "$FIREWALL_START" || fail "foreign line lost"
  # Exactly one blank line before our block, none at the end.
  awk '/# BEGIN vpn_ipcatcher firewall/{ if (prev!="" || prev2=="") bad=1 } {prev2=prev; prev=$0} END{exit bad}' "$FIREWALL_START" || fail "blank lines before block"
  [ -n "$(tail -n 1 "$FIREWALL_START")" ] || fail "trailing blank line"
  cp "$FIREWALL_START" "$work/fw1"; cp "$SERVICE_EVENT" "$work/se1"; cp "$SERVICES_START" "$work/ss1"
  before="$(ls "$HOOK_BACKUP_DIR" | wc -l)"
  for i in 1 2 3; do
    install_firewall_start_block; install_service_event_block; install_services_start_block
  done
  cmp -s "$FIREWALL_START" "$work/fw1" || fail "firewall-start grows on reinstall"
  cmp -s "$SERVICE_EVENT" "$work/se1" || fail "service-event grows on reinstall"
  cmp -s "$SERVICES_START" "$work/ss1" || fail "services-start grows on reinstall"
  [ "$(ls "$HOOK_BACKUP_DIR" | wc -l)" = "$before" ] || fail "backup made although nothing changed"
  ls "$hooks" | grep -q '\.bak\.[0-9]' && fail "backup written to the scripts folder"
  sh -n "$FIREWALL_START" && sh -n "$SERVICE_EVENT" && sh -n "$SERVICES_START"
) || exit 1
echo "PASS installer hooks idempotent, backups bounded"

# ------------------------------------------------- DVR mark restore (helper)
sed '/^case "${1:-check}" in/,$d' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh" > "$work/routing"
(
  set +e
  . "$work/routing"
  set -e
  POLICIES="$work/policies"; GLOBAL="$work/global"; TABLES="$work/tables"
  printf 'StreamsVPNSW|d|a|ovpnc1\n' > "$POLICIES"
  printf 'ENABLE=1\nOVPNC1FWMARK=0x1000\nOVPNC1MASK=0xf000\n' > "$GLOBAL"
  printf '111 ovpnc1\n' > "$TABLES"
  : > "$work/mangle"
  logger(){ :; }
  mock_ip(){ [ "$1" = rule ] && echo '1000: from all fwmark 0x1000/0xf000 lookup ovpnc1'; return 0; }
  mock_ipt(){
    case "$*" in
      "-t mangle -S") cat "$work/mangle" ;;
      "-t mangle -A "*) shift 2; printf '%s\n' "$*" >> "$work/mangle" ;;
      *) return 1 ;;
    esac
  }
  mock_set(){ [ "$1" = list ] && [ "$2" = DVR-StreamsVPNSW-v4 ]; }
  IP=mock_ip; IPTABLES=mock_ipt; IPSET=mock_set
  POLICY=StreamsVPNSW; CONNECTION=ovpnc1; MODE=""
  # Firewall restart wiped the rules: both are restored in DVR's own format.
  dvr_bound_restore
  [ "$(grep -c 'match-set DVR-StreamsVPNSW-v4 dst -j MARK --set-xmark 0x1000/0xf000' "$work/mangle")" = 2 ] || fail "marks not restored"
  grep -q '^-A PREROUTING ' "$work/mangle" && grep -q '^-A OUTPUT ' "$work/mangle" || fail "chain missing"
  # Rules present: nothing is added again (also not every periodic check).
  dvr_bound_restore; dvr_bound_restore
  [ "$(wc -l < "$work/mangle")" = 2 ] || fail "marks duplicated"
  # A different existing rule is left alone (firewall_check reports it).
  printf '%s\n' '-A PREROUTING -m set --match-set DVR-StreamsVPNSW-v4 dst -j MARK --set-xmark 0x2000/0xf000' > "$work/mangle"
  dvr_bound_restore
  [ "$(grep -c '^-A PREROUTING' "$work/mangle")" = 1 ] || fail "existing PREROUTING rule overridden"
  # Managed mode, DVR off, missing set or missing ip rule: no change.
  : > "$work/mangle"
  MODE=managed-v1; dvr_bound_restore; MODE=""
  printf 'ENABLE=0\nOVPNC1FWMARK=0x1000\nOVPNC1MASK=0xf000\n' > "$GLOBAL"; dvr_bound_restore
  printf 'ENABLE=1\nOVPNC1FWMARK=0x1000\nOVPNC1MASK=0xf000\n' > "$GLOBAL"
  mock_set(){ return 1; }; dvr_bound_restore
  mock_set(){ [ "$1" = list ]; }
  mock_ip(){ return 0; }; dvr_bound_restore
  [ ! -s "$work/mangle" ] || fail "rules added without a safe binding"
) || exit 1
echo "PASS DVR marks restored after firewall restart, never duplicated"

# --------------------------------------------- known-service guard (engine)
sed '/^case "\$1" in/,$d' "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$work/engine"
(
  set +e
  . "$work/engine"
  set -e
  AWK=awk; SED=sed; GREP=grep; TR=tr; TAIL=tail
  CONF="$work/conf"; default_config > "$CONF"
  # An older config that pinned EXCLUDE_DOMAINS without Microsoft/TikTok.
  printf 'EXCLUDE_DOMAINS="quad9.net github.com"\n' >> "$CONF"
  load_config
  DNS_NAMES="$work/dns_names"
  cat > "$DNS_NAMES" <<'EOF'
80.90.20.131 1794086040 endpoints.leaflets.schwarz
48.209.138.168 1794086361 settings-win.data.microsoft.com
71.18.240.1 1794089140 bsync31-normal-no1a.tiktokv.eu
23.194.190.207 1794086633 apps.smartadserver.com
172.67.196.194 1794085960 epg.ott-app.cc
104.16.1.1 1794085960 www.ikea.com
104.16.1.1 1794085961 line.someiptv.cc
198.51.100.9 1794085960 notmicrosoft.com
198.51.100.10 1794085960 evilschwarz
EOF
  for ip in 80.90.20.131 48.209.138.168 71.18.240.1 23.194.190.207; do
    ip_excluded_by_dns_name "$ip" || fail "known service not skipped: $ip"
  done
  # IPTV names, a shared CDN IP that also serves an IPTV name, look-alike
  # names and an IP without any looked-up name stay eligible.
  for ip in 172.67.196.194 104.16.1.1 198.51.100.9 198.51.100.10 203.0.113.50; do
    if ip_excluded_by_dns_name "$ip"; then fail "wrongly skipped: $ip"; fi
  done
  log(){ printf '%s\n' "$*" >> "$work/log"; }
  ip_is_fixed(){ return 1; }; ip_is_excluded(){ return 1; }; ip_excluded_by_reverse_dns(){ return 1; }
  should_skip_service_ip final 71.18.240.1 test || fail "guard not used for final"
  grep -q 'Skip bekende dienst final: 71.18.240.1 naam=bsync31-normal-no1a.tiktokv.eu' "$work/log" || fail "no log line"
  if should_skip_service_ip final 172.67.196.194 test; then fail "IPTV EPG skipped"; fi
  # No DNS names file at all: guard is neutral.
  DNS_NAMES="$work/missing"
  if ip_excluded_by_dns_name 71.18.240.1; then fail "guard without names"; fi
) || exit 1
echo "PASS known services skipped by looked-up name, IPTV kept"

# ------------------------------------------------------------- curl lookup
grep -q 'CURL="$(find_bin /opt/bin/curl /usr/sbin/curl ' "$ROOT/scripts/vpn_ipcatcher.real.sh" || fail "curl in /usr/sbin not looked up"
[ "$(grep -c 'find_bin /opt/bin/curl /usr/sbin/curl ' "$ROOT/scripts/vpn_ipcatcher.real.sh")" = 2 ] || fail "refind_bins misses /usr/sbin/curl"
echo "PASS curl in /usr/sbin found"
echo "ALL PASS: hardening-2106-checks"
