#!/bin/sh
# Version: 2.7.1
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
ADDON="/jffs/addons/vpn_ipcatcher.d"
SELECTION="$ADDON/routing-selection"
CONF="/jffs/scripts/vpn_ipcatcher.conf"
DVR="/jffs/scripts/domain_vpn_routing.sh"
POLICIES="/jffs/configs/domain_vpn_routing/domain_vpn_routing.conf"
GLOBAL="/jffs/configs/domain_vpn_routing/global.conf"
TABLES="/etc/iproute2/rt_tables"
CONFIG_LOCK="/tmp/vpn_ipcatcher_config.lock"
find_bin(){ for file in "$@"; do [ -f "$file" ] && [ -x "$file" ] && { printf '%s\n' "$file"; return 0; }; done; return 1; }
IP="$(find_bin /usr/sbin/ip /sbin/ip /bin/ip /opt/sbin/ip /opt/bin/ip)"
IPTABLES="$(find_bin /usr/sbin/iptables /sbin/iptables /opt/sbin/iptables)"
IPSET="$(find_bin /usr/sbin/ipset /sbin/ipset /opt/sbin/ipset /opt/bin/ipset)"
error(){ printf 'Routing: %s\n' "$*" >&2; return 1; }
setting(){
  awk -v key="$2" 'index($0,key "=")==1 {v=substr($0,length(key)+2); gsub(/^["\047]|["\047]$/, "",v); result=v} END{print result}' "$1"
}
dependencies(){
  failures=0
  for tool in "$IP" "$IPTABLES" "$IPSET"; do
    [ -n "$tool" ] && [ -x "$tool" ] || failures=1
  done
  [ "$failures" = 0 ] || { error 'ip, iptables of ipset ontbreekt.'; return 1; }
  [ -s "$DVR" ] && [ -r "$POLICIES" ] && [ -r "$GLOBAL" ] || {
    error 'Domain-based VPN Routing is niet volledig geinstalleerd. Installeer/configureer dit via amtm.'; return 1;
  }
  [ "$(setting "$GLOBAL" ENABLE)" = 1 ] || { error 'Domain-based VPN Routing staat uit.'; return 1; }
  for name in tcpdump awk sed grep nslookup tr conntrack curl jq sha256sum cru; do
    located=0
    for directory in /opt/bin /opt/sbin /usr/sbin /usr/bin /sbin /bin; do
      [ -f "$directory/$name" ] && [ -x "$directory/$name" ] && { located=1; break; }
    done
    [ "$located" = 1 ] || { error "Benodigd programma ontbreekt: $name. Installeer via Entware/amtm."; failures=1; }
  done
  [ "$failures" = 0 ]
}
set_check(){
  header="$($IPSET save "$SET" 2>/dev/null | awk '$1=="create" {print; exit}')"
  printf '%s\n' "$header" | awk '$3=="hash:ip" {for(i=4;i<=NF;i++){if($i=="timeout") t=1; if($i=="counters") c=1; if($i=="comment") m=1; if($i=="inet6") v6=1}} END{exit (!t || !c || !m || v6)?1:0}' || {
    error 'Deze DVR-IPSet mist hash:ip/IPv4, timeout, counters of comment. De installer verandert geen bestaande set met een onverenigbaar schema.'; return 1;
  }
}
valid_policy(){
  case "$1" in ''|*[!A-Za-z0-9_-]*) return 1 ;; esac
  [ "${#1}" -le 16 ]
}
valid_connection(){
  case "$1" in ovpnc[1-5]|wgc[1-5]) return 0 ;; esac
  return 1
}
policy_rows(){
  awk -F '|' 'NF>=4 && $1 !~ /^#/ && $4 ~ /^(ovpnc|wgc)[1-5]$/ {print $1 "|" $4}' "$POLICIES"
}
selection_read(){
  [ -f "$SELECTION" ] || { error 'Nog geen VPN/lijst gekozen. Gebruik routing-setup of de installer.'; return 1; }
  POLICY="$(sed -n '1p' "$SELECTION")"
  CONNECTION="$(sed -n '2p' "$SELECTION")"
  valid_policy "$POLICY" && valid_connection "$CONNECTION" || { error 'Ongeldige VPN/lijstselectie.'; return 1; }
  SET="DVR-${POLICY}-v4"
}
binding_read(){
  valid_policy "$POLICY" && valid_connection "$CONNECTION" || return 1
  rows="$(awk -F '|' -v policy="$POLICY" '$1==policy {print $4}' "$POLICIES")"
  [ "$rows" = "$CONNECTION" ] || { error 'De geselecteerde lijst ontbreekt, is dubbel of hoort bij een andere VPN.'; return 1; }
  key="$(printf '%s' "$CONNECTION" | tr '[:lower:]' '[:upper:]')"
  MARK="$(setting "$GLOBAL" "${key}FWMARK")"
  MASK="$(setting "$GLOBAL" "${key}MASK")"
  printf '%s\n' "$MARK/$MASK" | grep -Eq '^0x[0-9a-fA-F]+/0x[0-9a-fA-F]+$' || { error 'VPN-markering ontbreekt of is ongeldig.'; return 1; }
  SET="DVR-${POLICY}-v4"
}
rule_check(){
  rules="$($IP rule show 2>/dev/null)" || return 1
  table_number="$(awk -v table="$CONNECTION" '$2==table {print $1}' "$TABLES" 2>/dev/null)"
  printf '%s\n' "$rules" | awk -v expected="$MARK/$MASK" -v name="$CONNECTION" -v number="$table_number" '
    {mark=""; table=""; for(i=1;i<=NF;i++){if($i=="fwmark") mark=$(i+1); if($i=="lookup" || $i=="table") table=$(i+1)}
     if(mark==expected && (table==name || (number!="" && table==number))) good=1;
     if(mark==expected && (table!="" && table!=name && (number=="" || table!=number))) bad=1}
    END{exit (!good || bad)?1:0}' || { error 'Geen eenduidige markering naar de gekozen VPN-routingtabel.'; return 1; }
}
firewall_check(){
  rules="$($IPTABLES -t mangle -S 2>/dev/null)" || return 1
  printf '%s\n' "$rules" | awk -v set="$SET" -v expected="$MARK/$MASK" -v plain="$MARK" '
    {name=""; mark=""; for(i=1;i<=NF;i++) {if($i=="--match-set") name=$(i+1); if($i=="--set-xmark" || $i=="--set-mark") mark=$(i+1)}
     if(name==set && mark!="") {if(mark!=expected && mark!=plain) bad=1; else {if($2=="PREROUTING") pre=1; if($2=="OUTPUT") out=1}}
     if((name==set "_cand" || name==set "_exclude" || name==set "_wait") && mark!="") bad=1}
    END{exit (bad || !pre || !out)?1:0}' || { error 'Lijstmarkeringen ontbreken of conflicteren. Herstel de gekozen DVR-policy en verwijder conflicterende oude regels gericht.'; return 1; }
}
route_check(){
  routes="$($IP route show table "$CONNECTION" 2>/dev/null)" || return 1
  TUNNEL="$(printf '%s\n' "$routes" | awk '$1=="default" || $1=="0.0.0.0/1" || $1=="128.0.0.0/1" {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | sort -u)"
  case "$TUNNEL" in ''|*[!A-Za-z0-9_.:-]*) error 'Geen eenduidige actieve VPN-uitgang gevonden.'; return 1 ;; esac
  case "$CONNECTION:$TUNNEL" in ovpnc*:tun*|ovpnc*:tap*|wgc*:wgc*) ;; *) error 'De gekozen routingtabel wijst niet naar een herkenbare VPN-tunnel.'; return 1 ;; esac
  link="$($IP link show "$TUNNEL" 2>/dev/null)" || { error 'VPN-interface is niet beschikbaar.'; return 1; }
  printf '%s\n' "$link" | grep -Eq '<([^>]*,)?UP(,|>)' || { error 'VPN-interface staat niet UP.'; return 1; }
}
binding_check(){
  binding_read && rule_check && firewall_check && route_check || return 1
  $IPSET list "$SET" >/dev/null 2>&1 || { error 'De finale DVR-IPSet ontbreekt.'; return 1; }
  set_check || return 1
  configured_set="$(setting "$CONF" IPSET_NAME)"
  [ "$configured_set" = "$SET" ] || { error 'IP Catcher schrijft naar een andere lijst dan de geselecteerde DVR-policy.'; return 1; }
  printf 'OK: %s -> %s -> %s (mark %s/%s)\n' "$SET" "$CONNECTION" "$TUNNEL" "$MARK" "$MASK"
}
list_choices(){
  [ -r "$POLICIES" ] || return 1
  policy_rows | while IFS='|' read -r policy connection; do
    valid_policy "$policy" || continue
    printf '%s | %s | DVR-%s-v4\n' "$connection" "$policy" "$policy"
  done
}
configure(){
  dependencies || return 1
  if [ ! -t 0 ]; then error 'VPN-selectie vereist een interactief SSH/menu-venster.'; return 1; fi
  echo 'Beschikbare VPN-verbindingen met DVR-policy:'
  policy_rows | cut -d '|' -f 2 | sort -u
  printf 'Kies verbinding (bijvoorbeeld ovpnc1 of wgc1): '
  read -r CONNECTION || return 1
  valid_connection "$CONNECTION" || { error 'Kies een OpenVPN- of WireGuard-client uit de lijst.'; return 1; }
  echo 'Bijbehorende policies:'
  policy_rows | awk -F '|' -v connection="$CONNECTION" '$2==connection {print $1}'
  printf 'Kies policynaam: '
  read -r POLICY || return 1
  binding_read && rule_check && firewall_check && route_check || return 1
  $IPSET list "$SET" >/dev/null 2>&1 || { error 'DVR-IPSet ontbreekt; herstel eerst deze policy via Domain-based VPN Routing.'; return 1; }
  set_check || return 1
  echo 'LAN-interface(s) om verkeer te observeren (bijvoorbeeld br0):'
  $IP -o link show 2>/dev/null | awk -F ': ' '{print $2}'
  printf 'Interface(s): '
  read -r CAPTURE || return 1
  [ -n "$CAPTURE" ] || return 1
  for interface in $CAPTURE; do
    case "$interface" in *[!A-Za-z0-9_.:-]*) return 1 ;; esac
    $IP link show "$interface" >/dev/null 2>&1 || { error "Interface ontbreekt: $interface"; return 1; }
    case "$interface" in tun*|tap*|wgc*) error 'Kies de LAN-ingang, niet de versleutelde VPN-uitgang.'; return 1 ;; esac
  done
  mkdir "$CONFIG_LOCK" 2>/dev/null || { error 'Configuratie is vergrendeld.'; return 1; }
  echo $$ > "$CONFIG_LOCK/pid"
  trap 'rm -f "${CONF}.routing-new" "$SELECTION.new" "$CONFIG_LOCK/pid"; rmdir "$CONFIG_LOCK" 2>/dev/null' EXIT
  trap 'exit 1' HUP INT TERM
  backup="${CONF}.bak-routing-$(date +%Y%m%d-%H%M%S)-$$"
  if ! cp -p "$CONF" "$backup"; then rm -f "$CONFIG_LOCK/pid"; rmdir "$CONFIG_LOCK"; return 1; fi
  awk -v set="$SET" -v capture="$CAPTURE" '
    /^IPSET_NAME=/ {if(!s++) print "IPSET_NAME=\"" set "\""; next}
    /^INTERFACES=/ {if(!c++) print "INTERFACES=\"" capture "\""; next}
    {print}
    END{if(!s) print "IPSET_NAME=\"" set "\""; if(!c) print "INTERFACES=\"" capture "\""}
  ' "$CONF" > "${CONF}.routing-new"
  rc=$?
  if [ "$rc" = 0 ]; then
    chmod 600 "${CONF}.routing-new"
    mv "${CONF}.routing-new" "$CONF" || rc=1
    mkdir -p "$ADDON"
    printf '%s\n%s\n' "$POLICY" "$CONNECTION" > "$SELECTION.new" || rc=1
    chmod 600 "$SELECTION.new"
    [ "$rc" != 0 ] || mv "$SELECTION.new" "$SELECTION" || rc=1
  fi
  if [ "$rc" != 0 ]; then cp -p "$backup" "$CONF"; fi
  rm -f "${CONF}.routing-new" "$SELECTION.new" "$CONFIG_LOCK/pid"
  rmdir "$CONFIG_LOCK"
  [ "$rc" = 0 ] && binding_check
}
case "${1:-check}" in
  configure) configure ;;
  check) selection_read && binding_check ;;
  list) list_choices ;;
  dependencies) dependencies ;;
  *) error 'Gebruik: routing {configure|check|list|dependencies}' ;;
esac
