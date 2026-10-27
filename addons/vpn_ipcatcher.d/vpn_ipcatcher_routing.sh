#!/bin/sh
# Version: 2.9.14
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
DIRECTOR="/jffs/openvpn/vpndirector_rulelist"
SOURCE_SET=VPNIPC-SOURCE
REMOTE_SET=VPNIPC-REMOTE
DOMAIN_SET=VPNIPC-DOMAINS
PRECEDENCE_CACHE=/tmp/vpn_ipcatcher_precedence.cache
PRECEDENCE_STATUS=/tmp/vpn_ipcatcher_precedence.status
# Separate from DVR's 0xf000 and Merlin source rules. The late RPDB lookup is
# essential: a newly applied Director rule wins even before guard refresh.
DYNAMIC_MARK=0x1000000/0x1000000
dynamic_rule_prepare(){
  dynamic_rules="$($IP rule show)" || return 1
  old_connection="$(sed -n '2p' "$SELECTION" 2>/dev/null)"
  if [ "${ALLOW_REBIND:-no}" = yes ] && valid_connection "$old_connection" && [ "$old_connection" != "$CONNECTION" ] &&
     [ "$(sed -n '2p' "$ADDON/managed-VIPC-$old_connection" 2>/dev/null)" = "$DYNAMIC_MARK" ]; then
    hold_routing || return 1
    $IP rule del from all fwmark "$DYNAMIC_MARK" lookup "$old_connection" priority 31000 || return 1
    dynamic_rules="$($IP rule show)" || return 1
  fi
  printf '%s\n' "$dynamic_rules" | awk '{for(i=1;i<=NF;i++)if($i=="fwmark")print $(i+1)}' |
    while IFS= read -r other_mark; do
      [ "$other_mark" = "$DYNAMIC_MARK" ] && continue
      printf '%s\n' "$other_mark" | grep -Eq '^0x[0-9a-fA-F]{1,8}(/0x[0-9a-fA-F]{1,8})?$' || exit 1
      case "$other_mark" in */*) other_mask="${other_mark#*/}" ;; *) other_mask=0xffffffff ;; esac
      [ "$((other_mask & 0x1000000))" = 0 ] || exit 1
    done || { error 'Dynamisch mark-bit conflicteert met bestaande RPDB-maskers.'; return 1; }
  printf '%s\n' "$dynamic_rules" | awk -v mark="$DYNAMIC_MARK" -v connection="$CONNECTION" '
    {p=$1+0; if((p==31000 || p==31001) && $0 !~ /fwmark/) bad=1
     if(p>=31000 && ($3!="all" || $4=="to")) bad=1}
    /fwmark/ {for(i=1;i<=NF;i++)if($i=="fwmark")m=$(i+1)
      p=$1+0
      if(m==mark && p==31000 && $NF==connection) next
      if(m==mark && p==31001 && $NF=="unreachable") next
      if(p>=31000 || m==mark) bad=1}
    END{exit bad?1:0}' || { error 'Dynamische RPDB-prioriteit/mark is al in gebruik.'; return 1; }
  # Terminal failure rule is installed first and remains if the VPN table empties.
  printf '%s\n' "$dynamic_rules" | grep -F "fwmark $DYNAMIC_MARK" | grep -q 'unreachable' ||
    $IP rule add unreachable from all fwmark "$DYNAMIC_MARK" priority 31001 || return 1
  printf '%s\n' "$dynamic_rules" | grep -F "fwmark $DYNAMIC_MARK" | grep -q "lookup $CONNECTION\$" ||
    $IP rule add from all fwmark "$DYNAMIC_MARK" lookup "$CONNECTION" priority 31000 || return 1
}
# These sets belong exclusively to Catcher. External rule files/sets are read-only.
valid_network(){
  printf '%s\n' "$1" | awk '
    NF!=1 {exit 1}
    {n=split($0,a,"/"); if(n>2 || (n==2 && (a[2]!~/^[0-9]+$/ || a[2]>32))) exit 1
     if(split(a[1],b,".")!=4) exit 1
     for(i=1;i<=4;i++) if(b[i]!~/^[0-9]+$/ || b[i]>255 || (length(b[i])>1 && substr(b[i],1,1)=="0")) exit 1}
    END{if(NR!=1) exit 1}'
}
director_rows(){
  # Merlin stores five > separated fields, with < between records (not nvram).
  [ -f "$DIRECTOR" ] && [ -r "$DIRECTOR" ] && [ ! -L "$DIRECTOR" ] || {
    error 'VPN Director-regelbestand ontbreekt/onleesbaar; automatische voorrang niet bewezen.'; return 1;
  }
  awk -v RS='<' -F '>' '
    {sub(/[\r\n]+$/, "", $0)}
    NF==0 {next}
    NF!=5 {bad=1; next}
    $1=="0" {next}
    $1!="1" || $5!~/^(WAN|OVPN[1-5]|WGC[1-5])$/ {bad=1; next}
    {print $3 "|" $4 "|" $5}
    END{exit bad?1:0}' "$DIRECTOR"
}
protected_sources(){
  rows="$(director_rows)" || return 1
  manual="$(setting "$CONF" BYPASS_SOURCE_IPS)"
  for source in $manual; do valid_network "$source" || return 1; printf '%s\n' "$source"; done
  printf '%s\n' "$rows" | while IFS='|' read -r source remote target; do
    [ -n "$source" ] && [ "$source" != 0.0.0.0 ] || continue
    valid_network "$source" || exit 1
    # Conservatively protect the entire source even for source+destination rules.
    printf '%s\n' "$source"
  done
}
source_unprotected(){
  valid_network "$1" || return 1
  source_networks="$(protected_sources)" || return 1
  printf '%s\n' "$source_networks" | awk -v source="$1" '
    function number(ip, a){split(ip,a,"."); return ((a[1]*256+a[2])*256+a[3])*256+a[4]}
    NF {n=split($1,a,"/"); prefix=n==2?a[2]:32; block=1
      for(bit=prefix;bit<32;bit++) block*=2
      if(int(number(source)/block)==int(number(a[1])/block)) protected=1}
    END{exit protected?1:0}'
}
guard_add(){
  # hash:net cannot store /0. Cover it with two /1 networks instead.
  case "$2" in */0)
    $IPSET add "$1" 0.0.0.0/1 -exist && $IPSET add "$1" 128.0.0.0/1 -exist ;;
    *) $IPSET add "$1" "$2" -exist ;;
  esac
}
precedence_prepare(){
  # Stage, validate and atomically swap membership. Never flush a live guard.
  sources="$(protected_sources)" || return 1
  rows="$(director_rows)" || return 1
  [ -r "$POLICIES" ] || return 1
  explicit="$(awk -F '|' 'NF && $1 !~ /^#/ {if(NF<4)exit 1; print $1}' "$POLICIES")" || return 1
  for policy in $explicit; do
    valid_policy "$policy" || return 1
    $IPSET list "DVR-$policy-v4" >/dev/null 2>&1 || { error "Expliciete DVR-lijst ontbreekt: $policy"; return 1; }
  done
  signature="$(printf '%s\n%s\n%s\n' "$sources" "$rows" "$explicit" | cksum)"
  if [ "$(cat "$PRECEDENCE_CACHE" 2>/dev/null)" = "$signature" ] &&
     $IPSET list "$SOURCE_SET" >/dev/null 2>&1 && $IPSET list "$REMOTE_SET" >/dev/null 2>&1 && $IPSET list "$DOMAIN_SET" >/dev/null 2>&1; then return 0; fi
  for guard in "$SOURCE_SET" "$REMOTE_SET"; do
    $IPSET create "$guard" hash:net family inet -exist || return 1
    $IPSET create "$guard-new" hash:net family inet -exist || return 1
    $IPSET flush "$guard-new" || return 1
  done
  for source in $sources; do guard_add "$SOURCE_SET-new" "$source" || return 1; done
  printf '%s\n' "$rows" | while IFS='|' read -r source remote target; do
    [ -n "$remote" ] && [ "$remote" != 0.0.0.0 ] || continue
    valid_network "$remote" || exit 1
    guard_add "$REMOTE_SET-new" "$remote" || exit 1
  done || return 1
  $IPSET create "$DOMAIN_SET" list:set size 256 -exist || return 1
  $IPSET create "$DOMAIN_SET-new" list:set size 256 -exist || return 1
  $IPSET flush "$DOMAIN_SET-new" || return 1
  $IPSET add "$DOMAIN_SET-new" "$REMOTE_SET" -exist || return 1
  # Include every explicit policy, including WAN, and even the old bound list.
  # Missing sets are ambiguous (e.g. offline VPN); retain old guards and fail closed.
  for policy in $explicit; do
    valid_policy "$policy" || return 1
    $IPSET list "DVR-$policy-v4" >/dev/null 2>&1 || { error "Expliciete DVR-lijst ontbreekt: $policy"; return 1; }
    $IPSET add "$DOMAIN_SET-new" "DVR-$policy-v4" -exist || return 1
  done
  hold_routing || return 1
  $IPSET swap "$SOURCE_SET-new" "$SOURCE_SET" &&
    $IPSET swap "$REMOTE_SET-new" "$REMOTE_SET" &&
    $IPSET swap "$DOMAIN_SET-new" "$DOMAIN_SET" || return 1
  # Drop obsolete external set references, so removed DVR policies can be deleted.
  $IPSET flush "$DOMAIN_SET-new" || return 1
  printf '%s\n' "$signature" > "$PRECEDENCE_CACHE"
}
hold_routing(){
  # Conservative failure state. Never remove the last VPN mark and expose WAN.
  for hold_chain in FORWARD OUTPUT; do
    $IPTABLES -t filter -C "$hold_chain" -m set --match-set "$SET" dst -m comment --comment "VPNIPC-HOLD-$POLICY" -j REJECT 2>/dev/null ||
      $IPTABLES -t filter -I "$hold_chain" 1 -m set --match-set "$SET" dst -m comment --comment "VPNIPC-HOLD-$POLICY" -j REJECT || return 1
  done
}
release_hold(){
  for hold_chain in FORWARD OUTPUT; do
    hold_count=0
    while $IPTABLES -t filter -C "$hold_chain" -m set --match-set "$SET" dst -m comment --comment "VPNIPC-HOLD-$POLICY" -j REJECT 2>/dev/null; do
      $IPTABLES -t filter -D "$hold_chain" -m set --match-set "$SET" dst -m comment --comment "VPNIPC-HOLD-$POLICY" -j REJECT || return 1
      hold_count=$((hold_count+1)); [ "$hold_count" -lt 20 ] || return 1
    done
  done
}
migrate_binding(){
  [ "${MODE:-}" != managed-v1 ] || return 0
  # A shared DVR set cannot distinguish old learned IPs from explicit domains.
  # Leave it intact; start with an empty owned set, and protect the original set.
  binding_read && rule_check && route_check || return 1
  [ ! -e "$ADDON/precedence-migration" ] || { error 'Onvoltooide migratie; herstel de bewaarde configuratie/selectie.'; return 1; }
  mkdir "$ADDON/precedence-migration" || return 1
  chmod 700 "$ADDON/precedence-migration" || return 1
  cp -p "$CONF" "$ADDON/precedence-migration/config" &&
    cp -p "$SELECTION" "$ADDON/precedence-migration/selection" || return 1
  printf '%s\n' pending > "$ADDON/precedence-migration/state" || return 1
  POLICY="VIPC-$CONNECTION"; MODE=managed-v1; SET="DVR-$POLICY-v4"
  if managed_prepare && firewall_check; then
    awk -v set="$SET" '/^IPSET_NAME=/{if(!seen++) print "IPSET_NAME=\"" set "\""; next} {print} END{if(!seen)print "IPSET_NAME=\"" set "\""}' "$CONF" > "$CONF.routing-new" &&
      chmod 600 "$CONF.routing-new" && mv "$CONF.routing-new" "$CONF" &&
      printf '%s\n%s\nmanaged-v1\n' "$POLICY" "$CONNECTION" > "$SELECTION.new" &&
      chmod 600 "$SELECTION.new" && mv "$SELECTION.new" "$SELECTION" && binding_check &&
      printf '%s\n' committed > "$ADDON/precedence-migration/state" && return 0
  fi
  cp -p "$ADDON/precedence-migration/config" "$CONF"
  cp -p "$ADDON/precedence-migration/selection" "$SELECTION"
  error 'Migratie afgebroken; oorspronkelijke binding hersteld. Geen gedeelde DVR-lijst gewijzigd.'
  return 1
}
recover_migration(){
  [ "$(cat "$ADDON/precedence-migration/state" 2>/dev/null)" = pending ] || return 0
  cp -p "$ADDON/precedence-migration/config" "$CONF" &&
    cp -p "$ADDON/precedence-migration/selection" "$SELECTION" &&
    mv "$ADDON/precedence-migration" "$ADDON/precedence-migration-failed-$(date +%s)-$$" || return 1
}
rollback_migration(){
  [ ! -e /tmp/vpn_ipcatcher.lock ] || { error 'Stop IP Catcher voordat je de binding herstelt.'; return 1; }
  [ "$(cat "$ADDON/precedence-migration/state" 2>/dev/null)" = committed ] || return 1
  selection_read && [ "$MODE" = managed-v1 ] || return 1
  rollback_policy="$POLICY"; rollback_set="$SET"
  rollback_connection="$CONNECTION"
  hold_routing && remove_managed_rules "$POLICY" || return 1
  cp -p "$ADDON/precedence-migration/config" "$CONF" &&
    cp -p "$ADDON/precedence-migration/selection" "$SELECTION" &&
    selection_read && binding_check || return 1
  $IP rule del from all fwmark "$DYNAMIC_MARK" lookup "$rollback_connection" priority 31000 &&
    $IP rule del unreachable from all fwmark "$DYNAMIC_MARK" priority 31001 || return 1
  (POLICY="$rollback_policy"; SET="$rollback_set"; release_hold) || return 1
  printf '%s\n' rolled-back > "$ADDON/precedence-migration/state"
}
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
  [ "${#1}" -le 24 ]
}
valid_connection(){
  case "$1" in ovpnc[1-5]|wgc[1-5]) return 0 ;; esac
  return 1
}
policy_rows(){
  awk -F '|' 'NF>=4 && $1 !~ /^#/ && $4 ~ /^(ovpnc|wgc)[1-5]$/ {print $1 "|" $4}' "$POLICIES"
}
# Convert HTTP(S) XMLTV/EPG URLs to just their hostname. Never store
# username, password, token, query, path or port as a DVR domain rule.
normalize_force_vpn_host(){
  input="$1"
  [ -n "$input" ] && [ "$(printf '%s' "$input" | wc -c)" -le 2048 ] || return 1
  printf '%s\n' "$input" | awk '
    BEGIN {valid=1}
    {
      host=tolower($0)
      if(host ~ /^https?:\/\//){
        sub(/^https?:\/\//,"",host)
        sub(/[\/?#].*$/,"",host)
        if(host ~ /@/){valid=0;exit}
        if(host ~ /:/){
          n=split(host,parts,":")
          if(n!=2 || parts[2]!~/^[0-9]+$/){valid=0;exit}
          host=parts[1]
        }
      } else {
        if(host ~ /[\/?#@:]/){valid=0;exit}
      }
      if(host ~ /^[0-9.]+$/){valid=0;exit}
      n=split(host,labels,".")
      if(n<2 || length(host)>253){valid=0;exit}
      for(i=1;i<=n;i++){
        if(length(labels[i])>63 || labels[i]!~/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/){valid=0;exit}
      }
      if(valid) print host
    }
    END {if(!valid)exit 1}
  '
}

# Never leave the same force-VPN host simultaneously in multiple policies.
force_domain_conflict(){
  chosen="$1"; host="$2"
  policy_rows | while IFS="|" read -r other_policy other_connection; do
    [ "$other_policy" = "$chosen" ] && continue
    valid_policy "$other_policy" || continue
    other_file="$(dirname "$POLICIES")/policy_$other_policy""_domainlist"
    [ -f "$other_file" ] && [ ! -L "$other_file" ] || continue
    if grep -Fxi "$host" "$other_file" >/dev/null 2>&1; then
      printf '%s (%s)\n' "$other_policy" "$other_connection"
    fi
  done
  return 0
}

# Querying does not imply routing. Check DVR produced an active IPv4 route.
verify_force_domain_route(){
  chosen="$1"; host="$2"; vpn="$3"
  ipfile="$(dirname "$POLICIES")/policy_$chosen""_domaintoIP"
  setname="DVR-$chosen-v4"
  [ -r "$ipfile" ] && $IPSET list "$setname" >/dev/null 2>&1 ||
    { error "Geen DVR-IPSet/DNS-resultaat voor $host"; return 1; }
  found=0
  ips="$(awk -F '>>' -v host="$host" '$1==host && $2 ~ /^[0-9.]+$/ {print $2}' "$ipfile")"
  for ip in $ips; do
    if $IPSET test "$setname" "$ip" >/dev/null 2>&1; then
      found=$((found+1))
    fi
  done
  [ "$found" -gt 0 ] ||
    { error "Domein opgeslagen, maar $host heeft geen actief IPv4-adres in de DVR-IPSet. Controleer DNS en querypolicy."; return 1; }
  printf 'Altijd-VPN: %s -> policy %s -> %s (%s actieve IPv4-adressen)\n' "$host" "$chosen" "$vpn" "$found"
}

domain_add(){
  requested_policy="$1"; requested_url="$2"
  case "$requested_policy" in ''|*[!A-Za-z0-9_-]*) error 'Ongeldige DVR-policy.'; return 1 ;; esac
  [ "$(printf '%s' "$requested_policy" | wc -c)" -le 24 ] || return 1
  requested_domain="$(normalize_force_vpn_host "$requested_url")" ||
    { error 'Gebruik een hostnaam of volledige http(s) EPG-URL zonder gebruikersnaam/wachtwoord.'; return 1; }
  # Explicit DVR rules are independent of excludes and of IPTV learning.
  grep -q '^# Version: v3.2.5' "$DVR" ||
    { error 'DVR-koppeling vereist Domain VPN Routing v3.2.5; gebruik anders DVR-menu.'; return 1; }
  row="$(policy_rows | awk -F '|' -v p="$requested_policy" '$1==p{print $2}')"
  valid_connection "$row" ||
    { error 'DVR-policy ontbreekt of is dubbel.'; return 1; }
  ( CONNECTION="$row"; mark_read && rule_check && route_check ) ||
    { error "De VPN van policy $requested_policy ($row) is niet klaar; domein niet gewijzigd."; return 1; }
  list_dir="$(dirname "$POLICIES")"
  domain_list="$list_dir/policy_$requested_policy""_domainlist"
  [ -f "$domain_list" ] && [ ! -L "$domain_list" ] ||
    { error 'DVR-domeinlijst ontbreekt of is een symlink.'; return 1; }
  [ "$(setting "$GLOBAL" ENABLE)" = 1 ] ||
    { error 'DVR staat uit.'; return 1; }
  conflict="$(force_domain_conflict "$requested_policy" "$requested_domain")"
  [ -z "$conflict" ] ||
    { error "Domein $requested_domain staat al in policy: $conflict. Kies een unieke VPN-policy."; return 1; }
  timeout_bin="$(find_bin /usr/bin/timeout /bin/timeout /opt/bin/timeout)"
  flock_bin="$(find_bin /opt/bin/flock /usr/bin/flock /bin/flock)"
  [ -n "$timeout_bin" ] && [ -n "$flock_bin" ] ||
    { error 'timeout of flock ontbreekt voor veilige DVR-koppeling.'; return 1; }
  "$ADDON/vpn_ipcatcher_backup.sh" full || return 1
  case "$("$timeout_bin" --help 2>&1)" in *'[-t '*|*'-t SECS'*) timeout_flag=-t ;; *) timeout_flag='' ;; esac
  POLICY="$requested_policy" "$timeout_bin" -s TERM $timeout_flag 60 "$flock_bin" -n /var/lock/domain_vpn_routing.lock "$DVR" adddomain "$requested_domain" </dev/null || return 1
  grep -Fx "$requested_domain" "$domain_list" >/dev/null ||
    { error 'DVR heeft het domein niet opgeslagen.'; return 1; }
  "$timeout_bin" -s TERM $timeout_flag 90 "$DVR" querypolicy "$requested_policy" </dev/null ||
    { error 'Domein opgeslagen, maar verversen van DVR is mislukt.'; return 1; }
  verify_force_domain_route "$requested_policy" "$requested_domain" "$row"
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
  # All supported DVR v3.2.5 policies reserve these bits. Reject unknown layouts.
  [ "$MASK" = 0xf000 ] || { error 'Onbekend VPN-masker; geen dynamische routing.'; return 1; }
  legacy_mark="$MARK/$MASK"
  MARK=0x1000000; MASK=0x1000000
  owner="$ADDON/managed-$POLICY"
  [ -z "$(awk -F '|' -v policy="$POLICY" '$1==policy {print $1}' "$POLICIES")" ] || { error 'De automatische lijstnaam is al door DVR gebruikt; niets gewijzigd.'; return 1; }
  if [ -f "$owner" ]; then
    [ "$(sed -n '1p' "$owner")" = "$SET" ] || { error 'Onbekende eigenaar van de automatische lijst.'; return 1; }
    if [ "$(sed -n '2p' "$owner")" != "$MARK/$MASK" ]; then
      [ "${ALLOW_REBIND:-no}" = yes ] || [ "$(sed -n '2p' "$owner")" = "$legacy_mark" ] || { error 'VPN-instelling gewijzigd; kies opnieuw via routing-setup.'; return 1; }
      hold_routing || return 1
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
  precedence_prepare || return 1
  dynamic_rule_prepare || return 1
  # Install the egress kill switch BEFORE introducing a dynamic mark. It survives
  # tunnel removal and prevents RPDB fall-through to main/WAN between hook runs.
  for chain in FORWARD OUTPUT; do
    $IPTABLES -t filter -C "$chain" -m set --match-set "$SET" dst -m set ! --match-set "$SOURCE_SET" src -m set ! --match-set "$DOMAIN_SET" dst -m mark --mark 0x0/0xf000 ! -o "$TUNNEL" -m comment --comment "VPNIPC-$POLICY" -j REJECT 2>/dev/null ||
      $IPTABLES -t filter -I "$chain" 1 -m set --match-set "$SET" dst -m set ! --match-set "$SOURCE_SET" src -m set ! --match-set "$DOMAIN_SET" dst -m mark --mark 0x0/0xf000 ! -o "$TUNNEL" -m comment --comment "VPNIPC-$POLICY" -j REJECT || return 1
  done
  previous_tunnel="$(sed -n '3p' "$owner")"
  case "$previous_tunnel" in tun[0-9]*|tap[0-9]*|wgc[0-9]*)
    if [ "$previous_tunnel" != "$TUNNEL" ]; then
      for chain in FORWARD OUTPUT; do
        $IPTABLES -t filter -D "$chain" -m set --match-set "$SET" dst -m set ! --match-set "$SOURCE_SET" src -m set ! --match-set "$DOMAIN_SET" dst -m mark --mark 0x0/0xf000 ! -o "$previous_tunnel" -m comment --comment "VPNIPC-$POLICY" -j REJECT 2>/dev/null || return 1
      done
    fi ;;
  esac
  if [ "$previous_tunnel" != "$TUNNEL" ]; then
    (umask 077; printf '%s\n%s\n%s\n' "$SET" "$MARK/$MASK" "$TUNNEL" > "$owner.new") && mv "$owner.new" "$owner" || return 1
  fi
  for chain in PREROUTING OUTPUT; do
    # Managed auto-IPTV routing must never overwrite a preceding explicit
    # domain-policy VPN mark. Migrate the old unguarded rule in-place.
    # Guarded rules exclude explicit policies regardless of mangle rule order.
    $IPTABLES -t mangle -C "$chain" -m set --match-set "$SET" dst -m set ! --match-set "$SOURCE_SET" src -m set ! --match-set "$DOMAIN_SET" dst -m mark --mark 0x0/0xf000 -m comment --comment "VPNIPC-$POLICY" -j MARK --set-xmark "$MARK/$MASK" 2>/dev/null ||
      $IPTABLES -t mangle -A "$chain" -m set --match-set "$SET" dst -m set ! --match-set "$SOURCE_SET" src -m set ! --match-set "$DOMAIN_SET" dst -m mark --mark 0x0/0xf000 -m comment --comment "VPNIPC-$POLICY" -j MARK --set-xmark "$MARK/$MASK" || return 1
    old_count=0
    while $IPTABLES -t mangle -C "$chain" -m set --match-set "$SET" dst -m comment --comment "VPNIPC-$POLICY" -j MARK --set-xmark "$MARK/$MASK" 2>/dev/null; do
      $IPTABLES -t mangle -D "$chain" -m set --match-set "$SET" dst -m comment --comment "VPNIPC-$POLICY" -j MARK --set-xmark "$MARK/$MASK" || return 1
      old_count=$((old_count+1))
      [ "$old_count" -lt 20 ] || { error 'Te veel oude managed markregels; controleer handmatig.'; return 1; }
    done
    while $IPTABLES -t mangle -C "$chain" -m set --match-set "$SET" dst -m mark --mark 0x0/0xf000 -m comment --comment "VPNIPC-$POLICY" -j MARK --set-xmark "$MARK/$MASK" 2>/dev/null; do
      $IPTABLES -t mangle -D "$chain" -m set --match-set "$SET" dst -m mark --mark 0x0/0xf000 -m comment --comment "VPNIPC-$POLICY" -j MARK --set-xmark "$MARK/$MASK" || return 1
      old_count=$((old_count+1)); [ "$old_count" -lt 20 ] || return 1
    done
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
    while $IPTABLES -t mangle -C "$old_chain" -m set --match-set "$old_set" dst -m set ! --match-set "$SOURCE_SET" src -m set ! --match-set "$DOMAIN_SET" dst -m mark --mark 0x0/0xf000 -m comment --comment "VPNIPC-$old_policy" -j MARK --set-xmark "$old_mark" 2>/dev/null; do
      $IPTABLES -t mangle -D "$old_chain" -m set --match-set "$old_set" dst -m set ! --match-set "$SOURCE_SET" src -m set ! --match-set "$DOMAIN_SET" dst -m mark --mark 0x0/0xf000 -m comment --comment "VPNIPC-$old_policy" -j MARK --set-xmark "$old_mark" || return 1
      count=$((count+1)); [ "$count" -lt 20 ] || return 1
    done
    # Remove both historical unguarded marks and 2.9.14 guarded marks, but
    # only for IP Catcher-owned rules, never external DVR policies.
    while $IPTABLES -t mangle -C "$old_chain" -m set --match-set "$old_set" dst -m mark --mark 0x0/0xf000 -m comment --comment "VPNIPC-$old_policy" -j MARK --set-xmark "$old_mark" 2>/dev/null; do
      $IPTABLES -t mangle -D "$old_chain" -m set --match-set "$old_set" dst -m mark --mark 0x0/0xf000 -m comment --comment "VPNIPC-$old_policy" -j MARK --set-xmark "$old_mark" || return 1
      count=$((count+1)); [ "$count" -lt 20 ] || return 1
    done
    while $IPTABLES -t mangle -C "$old_chain" -m set --match-set "$old_set" dst -m comment --comment "VPNIPC-$old_policy" -j MARK --set-xmark "$old_mark" 2>/dev/null; do
      $IPTABLES -t mangle -D "$old_chain" -m set --match-set "$old_set" dst -m comment --comment "VPNIPC-$old_policy" -j MARK --set-xmark "$old_mark" || return 1
      count=$((count+1)); [ "$count" -lt 20 ] || return 1
    done
  done
  old_tunnel="$(sed -n '3p' "$old_owner")"
  case "$old_tunnel" in tun[0-9]*|tap[0-9]*|wgc[0-9]*)
    for old_chain in FORWARD OUTPUT; do
      $IPTABLES -t filter -D "$old_chain" -m set --match-set "$old_set" dst -m set ! --match-set "$SOURCE_SET" src -m set ! --match-set "$DOMAIN_SET" dst -m mark --mark 0x0/0xf000 ! -o "$old_tunnel" -m comment --comment "VPNIPC-$old_policy" -j REJECT 2>/dev/null || return 1
    done ;;
  esac
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
  firewall_mark="$MARK/$MASK"
  [ "${MODE:-}" != managed-v1 ] || firewall_mark="$DYNAMIC_MARK"
  printf '%s\n' "$rules" | awk -v set="$SET" -v expected="$firewall_mark" -v plain="${firewall_mark%/*}" -v mode="${MODE:-}" '
    {name=""; mark=""; guard=""; for(i=1;i<=NF;i++) {
       if($i=="--match-set" && name=="") name=$(i+1)
       if($i=="--set-xmark" || $i=="--set-mark") mark=$(i+1)
       if($i=="--mark") guard=$(i+1)
     }
     if(name==set && mark!="") {
       if(mark!=expected && mark!=plain) bad=1
       else {
         if(mode=="managed-v1" && guard!="0x0/0xf000") bad=1
         if(mode=="managed-v1" && (index($0,"-m set ! --match-set VPNIPC-SOURCE src")==0 || index($0,"-m set ! --match-set VPNIPC-DOMAINS dst")==0)) bad=1
         if($2=="PREROUTING") pre=1
         if($2=="OUTPUT") out=1
       }
     }
     if((name==set "_cand" || name==set "_exclude" || name==set "_wait") && mark!="") bad=1}
    END{exit (bad || !pre || !out)?1:0}' || { error 'Lijstmarkeringen ontbreken of conflicteren. Herstel de gekozen DVR-policy en verwijder conflicterende oude regels gericht.'; return 1; }
}
route_check(){
  routes="$($IP route show table "$CONNECTION" 2>/dev/null)" || return 1
  printf '%s\n' "$routes" | awk '$1=="default"{d=1} $1=="0.0.0.0/1"{a=1} $1=="128.0.0.0/1"{b=1} END{exit (d || (a && b))?0:1}' || { error 'VPN heeft geen volledige IPv4-default route.'; return 1; }
  TUNNEL="$(printf '%s\n' "$routes" | awk '$1=="default" || $1=="0.0.0.0/1" || $1=="128.0.0.0/1" {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | sort -u)"
  case "$TUNNEL" in ''|*[!A-Za-z0-9_.:-]*) error 'Geen eenduidige actieve VPN-uitgang gevonden.'; return 1 ;; esac
  case "$CONNECTION:$TUNNEL" in ovpnc*:tun*|ovpnc*:tap*|wgc*:wgc*) ;; *) error 'De gekozen routingtabel wijst niet naar een herkenbare VPN-tunnel.'; return 1 ;; esac
  link="$($IP link show "$TUNNEL" 2>/dev/null)" || { error 'VPN-interface is niet beschikbaar.'; return 1; }
  printf '%s\n' "$link" | grep -Eq '<([^>]*,)?UP(,|>)' || { error 'VPN-interface staat niet UP.'; return 1; }
}
binding_check(){
  [ "$(setting "$GLOBAL" ENABLE)" = 1 ] || { error 'De VPN-routing addon staat uit.'; return 1; }
  binding_read && rule_check && firewall_check && route_check || return 1
  if [ "${MODE:-}" = managed-v1 ]; then
    dynamic_rules="$($IP rule show)" || return 1
    printf '%s\n' "$dynamic_rules" | awk -v mark="$DYNAMIC_MARK" -v connection="$CONNECTION" -v number="$table_number" '
      $1=="31000:" && $4=="fwmark" && $5==mark && ($NF==connection || (number!="" && $NF==number)) {route=1}
      $1=="31001:" && $4=="fwmark" && $5==mark && $NF=="unreachable" {stop=1}
      END{exit (route && stop)?0:1}' || { error 'Late VPN-route of terminale blokkade ontbreekt.'; return 1; }
    for check_chain in FORWARD OUTPUT; do
      $IPTABLES -t filter -C "$check_chain" -m set --match-set "$SET" dst -m set ! --match-set "$SOURCE_SET" src -m set ! --match-set "$DOMAIN_SET" dst -m mark --mark 0x0/0xf000 ! -o "$TUNNEL" -m comment --comment "VPNIPC-$POLICY" -j REJECT || { error 'WAN-lekbeveiliging ontbreekt.'; return 1; }
    done
  fi
  $IPSET list "$SET" >/dev/null 2>&1 || { error 'De finale DVR-IPSet ontbreekt.'; return 1; }
  set_check || return 1
  configured_set="$(setting "$CONF" IPSET_NAME)"
  [ "$configured_set" = "$SET" ] || { error 'IP Catcher schrijft naar een andere lijst dan de geselecteerde DVR-policy.'; return 1; }
  printf 'OK: %s -> %s -> %s (mark %s)\n' "$SET" "$CONNECTION" "$TUNNEL" "$firewall_mark"
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
  [ "$rc" = 0 ] && binding_check && release_hold || return 1
  if [ "$previous_mode" = managed-v1 ] && [ "$previous_policy" != "$POLICY" ]; then remove_managed_rules "$previous_policy" || return 1; fi
  echo 'Klaar: VPN gekozen, lijsten en LAN automatisch ingesteld.'
}
case "${1:-check}" in
  configure) configure ;;
  check) selection_read && binding_check ;;
  prepare)
    (
      # Firewall hooks and periodic checks must not add the same mark concurrently.
      mkdir "$CONFIG_LOCK" 2>/dev/null || { error 'Configuratie is vergrendeld; prepare overgeslagen.'; exit 1; }
      echo $$ > "$CONFIG_LOCK/pid"
      trap 'rm -f "$CONFIG_LOCK/pid"; rmdir "$CONFIG_LOCK" 2>/dev/null' EXIT
      trap 'exit 1' HUP INT TERM
      recover_migration && selection_read || exit 1
      if migrate_binding && managed_prepare && binding_check && release_hold; then
        printf '%s\n' 'VPN Director + DVR protected; WAN fallback blocked' > "$PRECEDENCE_STATUS.new"
        mv "$PRECEDENCE_STATUS.new" "$PRECEDENCE_STATUS"
      else
        hold_routing || error 'KRITIEK: blokkeerregel kon niet worden geplaatst.'
        printf '%s\n' 'BLOCKED: precedence/tunnel validation failed' > "$PRECEDENCE_STATUS"
        exit 1
      fi
    )
    ;;
  domain-add) shift; domain_add "$@" ;;
  policies) policy_rows ;;
  sources) protected_sources ;;
  source-unprotected) source_unprotected "${2:-}" ;;
  rollback-migration)
    (
      mkdir "$CONFIG_LOCK" 2>/dev/null || exit 1
      echo $$ > "$CONFIG_LOCK/pid"
      trap 'rm -f "$CONFIG_LOCK/pid"; rmdir "$CONFIG_LOCK" 2>/dev/null' EXIT
      trap 'exit 1' HUP INT TERM
      rollback_migration
    ) ;;
  list) list_choices ;;
  dependencies) dependencies ;;
  install-dependencies) install_dependencies && dependencies ;;
  *) error 'Gebruik: routing {configure|check|list|dependencies}' ;;
esac
