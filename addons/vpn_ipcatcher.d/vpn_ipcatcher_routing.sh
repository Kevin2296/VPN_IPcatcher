#!/bin/sh
# Version: 2.9.2
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
install_dependencies(){
  packages=''
  for name in tcpdump conntrack jq; do
    if ! find_bin "/opt/bin/$name" "/opt/sbin/$name" "/usr/sbin/$name" "/usr/bin/$name" "/sbin/$name" "/bin/$name" >/dev/null; then packages="$packages $name"; fi
  done
  [ -n "$packages" ] || return 0
  [ -x /opt/bin/opkg ] || { error 'Entware ontbreekt. Installeer dit eerst via amtm op je USB-opslag; daarna regel ik de pakketten.'; return 1; }
  echo 'Ontbrekende pakketten worden via je bestaande Entware-installatie opgehaald.'
  /opt/bin/opkg update && /opt/bin/opkg install $packages
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
domain_add(){
  requested_policy="${1:-}"; requested_domain="${2:-}"
  case "$requested_policy" in ''|*[!A-Za-z0-9_-]*) error 'Ongeldige DVR-policy.'; return 1 ;; esac
  [ "${#requested_policy}" -le 24 ] || return 1
  case "$requested_domain" in *[!0-9.]*) ;; *) error 'Gebruik een domein, geen IP-adres.'; return 1 ;; esac
  printf '%s\n' "$requested_domain" | awk -F. '
    length($0)>253 || NF<2 {exit 1}
    {for(i=1;i<=NF;i++)if(length($i)>63 || $i!~/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/)exit 1}
    END{}' || { error 'Gebruik alleen een domeinnaam, zonder URL of login.'; return 1; }
  # This adapter is verified against the supplied DVR version, not unknown APIs.
  grep -q '^# Version: v3.2.5' "$DVR" || { error 'Browserkoppeling vereist DVR v3.2.5; gebruik anders het DVR-menu.'; return 1; }
  row="$(policy_rows | awk -F '|' -v p="$requested_policy" '$1==p{print $2}')"
  valid_connection "$row" || { error 'DVR-policy ontbreekt of is dubbel.'; return 1; }
  list_dir="$(dirname "$POLICIES")"
  domain_list="$list_dir/policy_${requested_policy}_domainlist"
  [ -f "$domain_list" ] && [ ! -L "$domain_list" ] || { error 'DVR-domeinlijst ontbreekt of is een symlink.'; return 1; }
  [ "$(setting "$GLOBAL" ENABLE)" = 1 ] || { error 'DVR staat uit.'; return 1; }
  timeout_bin="$(find_bin /usr/bin/timeout /bin/timeout /opt/bin/timeout)"
  flock_bin="$(find_bin /opt/bin/flock /usr/bin/flock /bin/flock)"
  [ -n "$timeout_bin" ] && [ -n "$flock_bin" ] || { error 'timeout of flock ontbreekt voor veilige DVR-koppeling.'; return 1; }
  "$ADDON/vpn_ipcatcher_backup.sh" full || return 1
  case "$("$timeout_bin" --help 2>&1)" in *'[-t '*|*'-t SECS'*) timeout_flag=-t ;; *) timeout_flag='' ;; esac
  POLICY="$requested_policy" "$timeout_bin" -s TERM $timeout_flag 60 "$flock_bin" -n /var/lock/domain_vpn_routing.lock "$DVR" adddomain "$requested_domain" </dev/null || return 1
  grep -Fx "$requested_domain" "$domain_list" >/dev/null || { error 'DVR heeft het domein niet opgeslagen.'; return 1; }
  "$timeout_bin" -s TERM $timeout_flag 90 "$DVR" querypolicy "$requested_policy" </dev/null || { error 'Domein opgeslagen, maar verversen van DVR is mislukt.'; return 1; }
}
selection_read(){
  [ -f "$SELECTION" ] || { error 'Nog geen VPN/lijst gekozen. Gebruik routing-setup of de installer.'; return 1; }
  POLICY="$(sed -n '1p' "$SELECTION")"
  CONNECTION="$(sed -n '2p' "$SELECTION")"
  MODE="$(sed -n '3p' "$SELECTION")"
  case "$MODE" in ''|managed-v1) ;; *) error 'Onbekende installatie-instelling.'; return 1 ;; esac
  valid_policy "$POLICY" && valid_connection "$CONNECTION" || { error 'Ongeldige VPN/lijstselectie.'; return 1; }
  SET="DVR-${POLICY}-v4"
}
binding_read(){
  valid_policy "$POLICY" && valid_connection "$CONNECTION" || return 1
  if [ "${MODE:-}" = managed-v1 ]; then
    [ "$POLICY" = "VIPC-$CONNECTION" ] || return 1
  else
  rows="$(awk -F '|' -v policy="$POLICY" '$1==policy {print $4}' "$POLICIES")"
  [ "$rows" = "$CONNECTION" ] || { error 'De geselecteerde lijst ontbreekt, is dubbel of hoort bij een andere VPN.'; return 1; }
  fi
  mark_read || return 1
  SET="DVR-${POLICY}-v4"
}
mark_read(){
  valid_connection "$CONNECTION" || return 1
  # Some Merlin tr builds do not support POSIX character classes.
  case "$CONNECTION" in
    ovpnc*) key="OVPNC${CONNECTION#ovpnc}" ;;
    wgc*) key="WGC${CONNECTION#wgc}" ;;
  esac
  MARK="$(setting "$GLOBAL" "${key}FWMARK")"
  MASK="$(setting "$GLOBAL" "${key}MASK")"
  printf '%s\n' "$MARK/$MASK" | grep -Eq '^0x[0-9a-fA-F]+/0x[0-9a-fA-F]+$' || { error 'VPN-markering ontbreekt of is ongeldig.'; return 1; }
}
managed_prepare(){
  [ "${MODE:-}" = managed-v1 ] || return 0
  [ "$(setting "$GLOBAL" ENABLE)" = 1 ] || { error 'De VPN-routing addon staat uit.'; return 1; }
  binding_read && rule_check && route_check || return 1
  owner="$ADDON/managed-$POLICY"
  [ -z "$(awk -F '|' -v policy="$POLICY" '$1==policy {print $1}' "$POLICIES")" ] || { error 'De automatische lijstnaam is al door DVR gebruikt; niets gewijzigd.'; return 1; }
  if [ -f "$owner" ]; then
    [ "$(sed -n '1p' "$owner")" = "$SET" ] || { error 'Onbekende eigenaar van de automatische lijst.'; return 1; }
    if [ "$(sed -n '2p' "$owner")" != "$MARK/$MASK" ]; then
      [ "${ALLOW_REBIND:-no}" = yes ] || { error 'VPN-instelling gewijzigd; kies opnieuw via routing-setup.'; return 1; }
      remove_managed_rules "$POLICY" || return 1
      (umask 077; printf '%s\n%s\n' "$SET" "$MARK/$MASK" > "$owner.new") && mv "$owner.new" "$owner" || return 1
    fi
  elif $IPSET list "$SET" >/dev/null 2>&1; then
    error 'Deze lijst bestaat al maar is niet van IP Catcher. Niets overschreven.'; return 1
  fi
  if ! $IPSET list "$SET" >/dev/null 2>&1; then
    $IPSET create "$SET" hash:ip family inet timeout 604800 counters comment || return 1
  fi
  set_check || return 1
  if [ ! -f "$owner" ]; then
    mkdir -p "$ADDON" || return 1
    (umask 077; printf '%s\n%s\n' "$SET" "$MARK/$MASK" > "$owner.new") && mv "$owner.new" "$owner" || return 1
  fi
  for chain in PREROUTING OUTPUT; do
    $IPTABLES -t mangle -C "$chain" -m set --match-set "$SET" dst -m comment --comment "VPNIPC-$POLICY" -j MARK --set-xmark "$MARK/$MASK" 2>/dev/null && continue
    $IPTABLES -t mangle -A "$chain" -m set --match-set "$SET" dst -m comment --comment "VPNIPC-$POLICY" -j MARK --set-xmark "$MARK/$MASK" || return 1
  done
}
remove_managed_rules(){
  old_policy="$1"
  case "$old_policy" in VIPC-ovpnc[1-5]|VIPC-wgc[1-5]) ;; *) return 1 ;; esac
  old_owner="$ADDON/managed-$old_policy"
  [ -r "$old_owner" ] || return 1
  old_set="$(sed -n '1p' "$old_owner")"
  old_mark="$(sed -n '2p' "$old_owner")"
  [ "$old_set" = "DVR-$old_policy-v4" ] || return 1
  printf '%s\n' "$old_mark" | grep -Eq '^0x[0-9a-fA-F]+/0x[0-9a-fA-F]+$' || return 1
  for old_chain in PREROUTING OUTPUT; do
    count=0
    while $IPTABLES -t mangle -C "$old_chain" -m set --match-set "$old_set" dst -m comment --comment "VPNIPC-$old_policy" -j MARK --set-xmark "$old_mark" 2>/dev/null; do
      $IPTABLES -t mangle -D "$old_chain" -m set --match-set "$old_set" dst -m comment --comment "VPNIPC-$old_policy" -j MARK --set-xmark "$old_mark" || return 1
      count=$((count+1)); [ "$count" -lt 20 ] || return 1
    done
  done
}
available_connections(){
  for connection in ovpnc1 ovpnc2 ovpnc3 ovpnc4 ovpnc5 wgc1 wgc2 wgc3 wgc4 wgc5; do
    if (CONNECTION="$connection"; mark_read && rule_check && route_check) >/dev/null 2>&1; then printf '%s\n' "$connection"; fi
  done
}
connection_label(){
  case "$1" in
    ovpnc*) number="${1#ovpnc}"; kind=OpenVPN; name="$(nvram get "vpn_client${number}_desc" 2>/dev/null)" ;;
    wgc*) number="${1#wgc}"; kind=WireGuard; name="$(nvram get "wgc${number}_desc" 2>/dev/null)" ;;
  esac
  name="$(printf '%s\n' "$name" | awk 'NR==1 {gsub(/[[:cntrl:]]/, ""); printf "%s", substr($0,1,60)}')"
  printf '%s %s%s\n' "$kind" "$number" "${name:+ - $name}"
}
automatic_lan(){
  CAPTURE="$(setting "$CONF" INTERFACES)"
  if [ -z "$CAPTURE" ]; then
    CAPTURE="$($IP -o link show 2>/dev/null | awk -F ': ' '$2 ~ /^br[0-9]+$/ && $0 ~ /<([^>]*,)?UP(,|>)/ {print $2}' | tr '\n' ' ')"
  fi
  [ -n "$CAPTURE" ] || { error 'Geen actief LAN gevonden; installatie afgebroken.'; return 1; }
  for interface in $CAPTURE; do
    case "$interface" in *[!A-Za-z0-9_.:-]*|tun*|tap*|wgc*) error 'Opgeslagen LAN-instelling is ongeldig.'; return 1 ;; esac
    $IP link show "$interface" >/dev/null 2>&1 || { error 'Opgeslagen LAN is niet aanwezig.'; return 1; }
  done
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
  [ "$(setting "$GLOBAL" ENABLE)" = 1 ] || { error 'De VPN-routing addon staat uit.'; return 1; }
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
  install_dependencies || return 1
  dependencies || return 1
  if [ ! -t 0 ]; then error 'VPN-selectie vereist een interactief SSH/menu-venster.'; return 1; fi
  previous_mode="$(sed -n '3p' "$SELECTION" 2>/dev/null)"
  previous_policy="$(sed -n '1p' "$SELECTION" 2>/dev/null)"
  choices="$(available_connections)"
  [ -n "$choices" ] || { error 'Geen werkende VPN gevonden. Zet je gewenste VPN aan in de ASUS WebUI en probeer opnieuw.'; return 1; }
  total="$(printf '%s\n' "$choices" | wc -l | tr -d ' ')"
  echo 'Welke VPN wil je gebruiken? De lijsten regel ik automatisch.'
  index=0
  for connection in $choices; do index=$((index+1)); printf '  %s) %s\n' "$index" "$(connection_label "$connection")"; done
  if [ "$total" = 1 ]; then answer=1; echo 'Een werkende VPN gevonden; automatisch geselecteerd.'
  else printf 'Kies nummer: '; read -r answer || return 1; fi
  case "$answer" in ''|*[!0-9]*) error 'Vul een nummer uit het overzicht in.'; return 1 ;; esac
  [ "${#answer}" -le 2 ] && [ "$answer" -ge 1 ] && [ "$answer" -le "$total" ] || return 1
  CONNECTION="$(printf '%s\n' "$choices" | sed -n "${answer}p")"
  MODE=managed-v1
  POLICY="VIPC-$CONNECTION"
  # Reuse a compatible configured list without asking users for technical names.
  previous_set="$(setting "$CONF" IPSET_NAME)"
  reuse="$(policy_rows | awk -F '|' -v set="$previous_set" -v connection="$CONNECTION" '$2==connection && "DVR-"$1"-v4"==set {print $1}')"
  if valid_policy "$reuse" && (POLICY="$reuse"; MODE=''; binding_read && firewall_check && set_check) >/dev/null 2>&1; then POLICY="$reuse"; MODE=''; fi
  binding_read && rule_check && route_check && automatic_lan || return 1
  ALLOW_REBIND=yes
  managed_prepare || return 1
  firewall_check && set_check || return 1
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
    printf '%s\n%s\n%s\n' "$POLICY" "$CONNECTION" "$MODE" > "$SELECTION.new" || rc=1
    chmod 600 "$SELECTION.new"
    [ "$rc" != 0 ] || mv "$SELECTION.new" "$SELECTION" || rc=1
  fi
  if [ "$rc" != 0 ]; then cp -p "$backup" "$CONF"; fi
  rm -f "${CONF}.routing-new" "$SELECTION.new" "$CONFIG_LOCK/pid"
  rmdir "$CONFIG_LOCK"
  [ "$rc" = 0 ] && binding_check || return 1
  if [ "$previous_mode" = managed-v1 ] && [ "$previous_policy" != "$POLICY" ]; then remove_managed_rules "$previous_policy" || return 1; fi
  echo 'Klaar: VPN gekozen, lijsten en LAN automatisch ingesteld.'
}
case "${1:-check}" in
  configure) configure ;;
  check) selection_read && binding_check ;;
  prepare)
    (
      # Firewall hooks and periodic checks must not add the same mark concurrently.
      mkdir "$CONFIG_LOCK" 2>/dev/null || exit 1
      echo $$ > "$CONFIG_LOCK/pid"
      trap 'rm -f "$CONFIG_LOCK/pid"; rmdir "$CONFIG_LOCK" 2>/dev/null' EXIT
      trap 'exit 1' HUP INT TERM
      selection_read && managed_prepare && binding_check
    )
    ;;
  domain-add) shift; domain_add "$@" ;;
  policies) policy_rows ;;
  list) list_choices ;;
  dependencies) dependencies ;;
  install-dependencies) install_dependencies && dependencies ;;
  *) error 'Gebruik: routing {configure|check|list|dependencies}' ;;
esac
