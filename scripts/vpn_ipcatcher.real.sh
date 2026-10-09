#!/bin/sh
# vpn_ipcatcher.sh - ASUS Merlin / amtm menu edition
# Built from the previously working engine, with menu controls and safer process handling.
# Version: 2.9.2

CONF="/jffs/scripts/vpn_ipcatcher.conf"
CACHE_DIR="/tmp/vpn_ipcatcher"
CACHE_DOM2IP="$CACHE_DIR/dom2ip"
FLOW_STATE="$CACHE_DIR/flow_prev"
LIVE_FLOW_STATE="$CACHE_DIR/live_flow_prev"
CACHE_EXCLUDE_IPS="$CACHE_DIR/exclude_ips"
CACHE_EXCLUDE_TS="$CACHE_DIR/exclude_ips.ts"
CACHE_PTR="$CACHE_DIR/ptr_cache"
LOGFILE="/tmp/vpn_ipcatcher.log"
LOCK="/tmp/vpn_ipcatcher.lock"
PIDDIR="/tmp/vpn_ipcatcher_pids"
ENGINE_PIDFILE="$PIDDIR/engine.pid"
PROMOTE_PIDFILE="$PIDDIR/promote.pid"
CAP_PIDFILE="$PIDDIR/capture.pids"
STATUS_FILE="$CACHE_DIR/runtime.status"
WEB_STATUS_FILE="/www/user/vpn_ipcatcher_status.json"
WEBUI_HELPER="/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh"
PRESET_LIB="/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_presets.sh"
ROUTING_HELPER="/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh"
ROUTING_STATUS="$CACHE_DIR/routing.ok"
CONFIG_WRITE_LOCK="/tmp/vpn_ipcatcher_config.lock"
EXCLUDE_CACHE_LOCK="/tmp/vpn_ipcatcher_exclude_cache.lock"
SELF="${0##*/}"

find_bin(){ for p in "$@"; do [ -x "$p" ] && { echo "$p"; return 0; }; done; return 1; }

LOGGER="$(find_bin /usr/bin/logger /bin/logger)"; [ -z "$LOGGER" ] && LOGGER="logger"
IPSET="$(find_bin /usr/sbin/ipset /sbin/ipset /opt/sbin/ipset /opt/bin/ipset)"
TCPDUMP="$(find_bin /opt/bin/tcpdump /opt/sbin/tcpdump /usr/sbin/tcpdump /usr/bin/tcpdump /sbin/tcpdump /bin/tcpdump)"
SED="$(find_bin /bin/sed /usr/bin/sed /opt/bin/sed)"
GREP="$(find_bin /bin/grep /usr/bin/grep /opt/bin/grep)"
AWK="$(find_bin /bin/awk /usr/bin/awk /opt/bin/awk)"
NSLOOKUP="$(find_bin /usr/bin/nslookup /bin/nslookup /opt/bin/nslookup)"
IPBIN="$(find_bin /sbin/ip /bin/ip /usr/sbin/ip /usr/bin/ip /opt/sbin/ip /opt/bin/ip)"
CT="$(find_bin /opt/sbin/conntrack /opt/bin/conntrack /usr/sbin/conntrack /usr/bin/conntrack /sbin/conntrack)"
TAIL="$(find_bin /usr/bin/tail /bin/tail /opt/bin/tail)"
HEAD="$(find_bin /usr/bin/head /bin/head /opt/bin/head)"
CAT="$(find_bin /bin/cat /usr/bin/cat /opt/bin/cat)"
VI="$(find_bin /opt/bin/nano /bin/vi /usr/bin/vi /opt/bin/vi)"
PSBIN="$(find_bin /bin/ps /usr/bin/ps)"
CLEAR="$(find_bin /usr/bin/clear /bin/clear)"
TR="$(find_bin /usr/bin/tr /bin/tr /opt/bin/tr)"
DATEBIN="$(find_bin /bin/date /usr/bin/date)"
SLEEPBIN="$(find_bin /bin/sleep /usr/bin/sleep)"

CAP_PIDS=""
PROMOTE_PID=""
ACCT_OK=0
STOPPING=0
CONFIG_CHANGED=0
SUPPRESS_RESTART_PROMPT=0

say(){ printf '%s\n' "$*"; }
soft_clear(){ [ -n "$CLEAR" ] && "$CLEAR" 2>/dev/null || printf '\033c'; }
press_enter(){ printf "\nDruk op Enter om verder te gaan... "; read -r _dummy; }

schedule_webui_publish(){
  [ -x "$WEBUI_HELPER" ] || return 0
  marker="/tmp/vpn_ipcatcher_webui_publish.pending"
  if mkdir "$marker" 2>/dev/null; then
    (
      sleep 1
      "$WEBUI_HELPER" publish >/dev/null 2>&1
      rmdir "$marker" 2>/dev/null
    ) >/dev/null 2>&1 &
  fi
}
config_write_lock(){
  tries=0
  while ! mkdir "$CONFIG_WRITE_LOCK" 2>/dev/null; do
    oldpid="$(cat "$CONFIG_WRITE_LOCK/pid" 2>/dev/null)"
    if [ -n "$oldpid" ] && ! kill -0 "$oldpid" 2>/dev/null; then
      rm -rf "$CONFIG_WRITE_LOCK" 2>/dev/null
      continue
    fi
    tries=$((tries+1)); [ "$tries" -ge 10 ] && return 1
    sleep 1
  done
  echo $$ > "$CONFIG_WRITE_LOCK/pid" 2>/dev/null
}
config_write_unlock(){ rm -rf "$CONFIG_WRITE_LOCK" 2>/dev/null; }

log(){
  $LOGGER -t vpn_ipcatcher "$*"
  echo "$(date '+%F %T') $*" >> "$LOGFILE"
}
human_duration(){
  s="$1"
  case "$s" in ''|*[!0-9]*) echo "$s sec"; return 0 ;; esac
  d=$((s/86400)); r=$((s%86400)); h=$((r/3600)); r=$((r%3600)); m=$((r/60)); sec=$((r%60))
  out=""
  [ "$d" -gt 0 ] && out="${out}${d}d "
  [ "$h" -gt 0 ] && out="${out}${h}u "
  [ "$m" -gt 0 ] && out="${out}${m}m "
  [ -z "$out" ] && out="${sec}s"
  echo "$out" | $SED 's/[ ]*$//'
}

default_config(){
  cat <<'EOC'
# Interfaces waar tcpdump op luistert.
# Meestal br0 voor LAN clients. Gebruik liever niet eth5/WAN, anders vang je te veel ruis.
INTERFACES="br0"

# IPSet die VPN Director gebruikt.
IPSET_NAME="DVR-StreamsVPNSW-v4"

# Poorten die worden bekeken.
PORTS="80,443"

# auto = bytes indien conntrack bytes werkt, anders age.
# age = na MIN_AGE seconden promoveren.
# bytes = pas promoveren na MIN_BYTES verkeer.
# immediate = direct naar final set.
PROMOTE_MODE="auto"
PROMOTE_EVERY="15"
CANDIDATE_TIMEOUT="600"
FINAL_TIMEOUT="604800"
MIN_AGE="30"
MIN_BYTES="1000000"

# Domeinen die nooit mogen worden toegevoegd.
# De exclusion resolver zet deze hostnames periodiek om naar tijdelijke IP-exclusions.
# Hierdoor worden o.a. Meta/WhatsApp/Instagram/Snapchat/GitHub/camera-clouds niet per ongeluk in de VPN-set gezet.
EXCLUDE_DOMAINS="quad9.net one.one.one.one dns.google github.com api.github.com githubusercontent.com githubassets.com facebook.com www.facebook.com graph.facebook.com fbcdn.net fbsbx.com whatsapp.com web.whatsapp.com static.whatsapp.net mqtt-mini.facebook.com edge-mqtt.facebook.com instagram.com www.instagram.com cdninstagram.com i.instagram.com snapchat.com app.snapchat.com sc-analytics.appspot.com feelinsonice.appspot.com eufylife.com security-app.eufylife.com eufy.com anker.com anker-in.com imoulife.com easy4ip.com lechange.com dahuasecurity.com dahuatech.com dahuap2p.com"

# Eigen IP-exclusions die jij zelf beheert via het menu of configbestand.
# Voorbeeld: EXCLUDE_IPS="34.117.59.81 172.217.168.10"
# Let op: DNS resolvers zoals 1.1.1.1 en 9.9.9.9 zitten daarnaast in een vaste safety-blocklist.
EXCLUDE_IPS=""

# Netwerk/range-exclusions. Deze zijn belangrijk voor diensten met veel wisselende IP's,
# zoals Meta/WhatsApp/Instagram. Losse hostname-resolves zijn hiervoor niet genoeg.
EXCLUDE_NETS="57.144.0.0/14 157.240.0.0/16 31.13.64.0/18 185.60.216.0/22 129.134.0.0/16"

# DNS fallback is bewust UIT. Het script gebruikt alleen lokale resolver 127.0.0.1.
# Zet alleen op yes als je expliciet externe resolvers wilt gebruiken.
ALLOW_EXTERNAL_DNS="no"
EXTERNAL_DNS_SERVER=""

# Generic hostname scan leest losse domeinnamen uit 80/443 payloads.
# Dit kan veel ruis opleveren. Standaard UIT; zet op yes als je bewust breder wilt leren.
CAPTURE_GENERIC_HOSTNAMES="no"

# Stream-flow learning kijkt niet naar vaste URL's/IP's, maar naar gedrag:
# veel verkeer vanaf je TV/mediabox naar een externe 80/443 bestemming.
# Vul SOURCE_IPS met je TV/mediabox IP's om ruis van telefoons/laptops te voorkomen.
STREAM_FLOW_SCAN="yes"
SOURCE_IPS=""
STREAM_SCAN_EVERY="5"
STREAM_MIN_BYTES="15000000"
# Minimum groei tussen twee scans voordat een flow als actief telt.
# Dit voorkomt dat oude conntrack-counters steeds als above-threshold blijven staan.
STREAM_MIN_DELTA="750000"
STREAM_REQUIRE_GROWTH="yes"
STREAM_FLOW_TARGET="candidate"

# Exclusion resolver: zet geselecteerde exclude-domeinen periodiek om naar tijdelijke IP-exclusions.
# Dit is belangrijk voor conntrack-first detectie, omdat conntrack meestal alleen dst-IP ziet.
EXCLUDE_RESOLVE_CACHE="yes"
EXCLUDE_RESOLVE_EVERY="3600"

# Reverse DNS check bij nieuwe stream-flow IPs. Minder betrouwbaar dan forward-resolve cache,
# maar kan helpen als een dst-IP een bruikbare PTR/naam teruggeeft. Standaard uit voor stabiliteit.
REVERSE_DNS_CHECK="no"

RETRY_DELAY="20"
MAX_RETRY_DELAY="60"
EOC
}

ensure_config(){
  [ -f "$CONF" ] && return 0
  mkdir -p "$(dirname "$CONF")" 2>/dev/null
  default_config > "$CONF"
  chmod 600 "$CONF" 2>/dev/null
}

load_config(){
  ensure_config
  # Parse data without executing shell commands from a configuration file.
  while IFS= read -r config_line || [ -n "$config_line" ]; do
    case "$config_line" in ''|\#*) continue ;; esac
    config_key="${config_line%%=*}"
    case "$config_key" in
      INTERFACES|IPSET_NAME|PORTS|PROMOTE_MODE|PROMOTE_EVERY|MIN_AGE|MIN_BYTES|CANDIDATE_TIMEOUT|FINAL_TIMEOUT|STREAM_FLOW_SCAN|SOURCE_IPS|STREAM_SCAN_EVERY|STREAM_MIN_BYTES|STREAM_MIN_DELTA|STREAM_REQUIRE_GROWTH|STREAM_FLOW_TARGET|EXCLUDE_DOMAINS|EXCLUDE_IPS|EXCLUDE_NETS|EXCLUDE_RESOLVE_CACHE|EXCLUDE_RESOLVE_EVERY|REVERSE_DNS_CHECK|CAPTURE_GENERIC_HOSTNAMES|ALLOW_EXTERNAL_DNS|EXTERNAL_DNS_SERVER|RETRY_DELAY|MAX_RETRY_DELAY) ;;
      *) say "Ongeldige configuratieregel: $config_key" >&2; return 1 ;;
    esac
    config_value="${config_line#*=}"
    case "$config_value" in
      \"*\") config_value="${config_value#\"}"; config_value="${config_value%\"}" ;;
    esac
    case "$config_value" in *[!A-Za-z0-9.,:/_\ -]*) say "Ongeldige configuratiewaarde: $config_key" >&2; return 1 ;; esac
    export "$config_key=$config_value"
  done < "$CONF"

  INTERFACES="${INTERFACES:-br0}"
  IPSET_NAME="${IPSET_NAME:-DVR-StreamsVPNSW-v4}"
  CAND_SET="${IPSET_NAME}_cand"
  WAIT_SET="${IPSET_NAME}_wait"
  PORTS="${PORTS:-80,443}"

  PROMOTE_MODE="${PROMOTE_MODE:-auto}"
  PROMOTE_EVERY="${PROMOTE_EVERY:-15}"
  CANDIDATE_TIMEOUT="${CANDIDATE_TIMEOUT:-600}"
  FINAL_TIMEOUT="${FINAL_TIMEOUT:-604800}"
  MIN_AGE="${MIN_AGE:-30}"
  MIN_BYTES="${MIN_BYTES:-1000000}"

  DEFAULT_EXCLUDE_DOMAINS="quad9.net one.one.one.one dns.google xboxlive.com xboxservices.com xbox.com officecdn.microsoft.com office.com office365.com microsoft.com msedge.net azureedge.net apple.com icloud.com mzstatic.com aaplimg.com apple-dns.net appldnld.apple.com swcdn.apple.com github.com api.github.com github.io raw.githubusercontent.com githubusercontent.com githubassets.com objects.githubusercontent.com facebook.com www.facebook.com graph.facebook.com fbcdn.net fbsbx.com mqtt-mini.facebook.com edge-mqtt.facebook.com gateway.facebook.com whatsapp.com web.whatsapp.com static.whatsapp.net mmg.whatsapp.net media.whatsapp.net instagram.com www.instagram.com cdninstagram.com i.instagram.com snapchat.com app.snapchat.com sc-analytics.appspot.com feelinsonice.appspot.com eufylife.com security-app.eufylife.com eufy.com anker.com anker-in.com imoulife.com easy4ip.com lechange.com dahuasecurity.com dahuatech.com dahua2w.com dahuap2p.com"
  DEFAULT_EXCLUDE_NETS="31.13.24.0/21 31.13.64.0/18 45.64.40.0/22 57.144.0.0/14 66.220.144.0/20 69.63.176.0/20 69.171.224.0/19 74.119.76.0/22 102.132.96.0/20 103.4.96.0/22 129.134.0.0/16 157.240.0.0/16 163.70.128.0/17 173.252.64.0/18 179.60.192.0/22 185.60.216.0/22 204.15.20.0/22"
  EXCLUDE_DOMAINS="${EXCLUDE_DOMAINS:-$DEFAULT_EXCLUDE_DOMAINS}"
  EXCLUDE_IPS="${EXCLUDE_IPS:-}"
  EXCLUDE_NETS="${EXCLUDE_NETS:-$DEFAULT_EXCLUDE_NETS}"
  EXCLUDE_NET_SET="${IPSET_NAME}_exclude"

  # Vaste safety-blocklist: deze mogen nooit in candidate/final ipset komen,
  # ook niet als EXCLUDE_IPS leeg is. Dit voorkomt dat DNS resolvers via VPN Director gaan.
  SYSTEM_EXCLUDE_IPS="1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220"
  ALLOW_EXTERNAL_DNS="${ALLOW_EXTERNAL_DNS:-no}"
  EXTERNAL_DNS_SERVER="${EXTERNAL_DNS_SERVER:-}"
  CAPTURE_GENERIC_HOSTNAMES="${CAPTURE_GENERIC_HOSTNAMES:-no}"
  STREAM_FLOW_SCAN="${STREAM_FLOW_SCAN:-yes}"
  SOURCE_IPS="${SOURCE_IPS:-}"
  STREAM_SCAN_EVERY="${STREAM_SCAN_EVERY:-5}"
  STREAM_MIN_BYTES="${STREAM_MIN_BYTES:-15000000}"
  STREAM_MIN_DELTA="${STREAM_MIN_DELTA:-750000}"
  STREAM_REQUIRE_GROWTH="${STREAM_REQUIRE_GROWTH:-yes}"
  STREAM_FLOW_TARGET="${STREAM_FLOW_TARGET:-candidate}"
  EXCLUDE_RESOLVE_CACHE="${EXCLUDE_RESOLVE_CACHE:-yes}"
  EXCLUDE_RESOLVE_EVERY="${EXCLUDE_RESOLVE_EVERY:-3600}"
  REVERSE_DNS_CHECK="${REVERSE_DNS_CHECK:-no}"

  RETRY_DELAY="${RETRY_DELAY:-20}"
  MAX_RETRY_DELAY="${MAX_RETRY_DELAY:-60}"
  for numeric_pair in "PROMOTE_EVERY=$PROMOTE_EVERY" "CANDIDATE_TIMEOUT=$CANDIDATE_TIMEOUT" "FINAL_TIMEOUT=$FINAL_TIMEOUT" "MIN_AGE=$MIN_AGE" "MIN_BYTES=$MIN_BYTES" "STREAM_SCAN_EVERY=$STREAM_SCAN_EVERY" "STREAM_MIN_BYTES=$STREAM_MIN_BYTES" "STREAM_MIN_DELTA=$STREAM_MIN_DELTA" "EXCLUDE_RESOLVE_EVERY=$EXCLUDE_RESOLVE_EVERY" "RETRY_DELAY=$RETRY_DELAY" "MAX_RETRY_DELAY=$MAX_RETRY_DELAY"; do
    numeric_key="${numeric_pair%%=*}"
    numeric_value="${numeric_pair#*=}"
    case "$numeric_value" in *[!0-9]*|'') say "Ongeldig getal: $numeric_key" >&2; return 1 ;; esac
    [ "${#numeric_value}" -le 10 ] || return 1
  done
  [ "$PROMOTE_EVERY" -gt 0 ] && [ "$STREAM_SCAN_EVERY" -gt 0 ] && [ "$RETRY_DELAY" -gt 0 ] || return 1
  [ "${#IPSET_NAME}" -le 23 ] || { say "IPSet-naam te lang voor afgeleide sets" >&2; return 1; }
  case "$IPSET_NAME" in ''|*[!A-Za-z0-9_-]*) return 1 ;; esac
  case "$PROMOTE_MODE" in auto|bytes|age|immediate) ;; *) return 1 ;; esac
  case "$STREAM_FLOW_TARGET" in candidate|final) ;; *) return 1 ;; esac
  for boolean_value in "$ALLOW_EXTERNAL_DNS" "$CAPTURE_GENERIC_HOSTNAMES" "$STREAM_FLOW_SCAN" "$STREAM_REQUIRE_GROWTH" "$EXCLUDE_RESOLVE_CACHE" "$REVERSE_DNS_CHECK"; do
    case "$boolean_value" in yes|no) ;; *) return 1 ;; esac
  done
  for interface_value in $INTERFACES; do
    case "$interface_value" in *[!A-Za-z0-9_.:-]*) return 1 ;; esac
  done
  case "$PORTS" in ''|*[!0-9,]*|,*|*,|*,,*) return 1 ;; esac
  OLDIFS="$IFS"; IFS=','; set -- $PORTS; IFS="$OLDIFS"
  for port_value in "$@"; do
    [ "${#port_value}" -le 5 ] && [ "$port_value" -ge 1 ] && [ "$port_value" -le 65535 ] || return 1
  done
}

validate_prereqs(){
  [ -x "$IPSET" ] || { echo "ipset missing"; return 1; }
  [ -x "$TCPDUMP" ] || { echo "tcpdump missing"; return 1; }
  [ -x "$SED" ] || { echo "sed missing"; return 1; }
  [ -x "$GREP" ] || { echo "grep missing"; return 1; }
  [ -x "$AWK" ] || { echo "awk missing"; return 1; }
  [ -x "$NSLOOKUP" ] || { echo "nslookup missing"; return 1; }
  return 0
}

is_pid_alive(){
  p="$1"
  [ -n "$p" ] && kill -0 "$p" 2>/dev/null
}

is_running(){
  [ -f "$ENGINE_PIDFILE" ] || return 1
  pid="$(cat "$ENGINE_PIDFILE" 2>/dev/null)"
  is_pid_alive "$pid" || return 1
  cmd="$($TR '\000' ' ' < "/proc/$pid/cmdline" 2>/dev/null)"
  case "$cmd" in *"/jffs/scripts/vpn_ipcatcher.real.sh run"*) return 0 ;; esac
  return 1
}


set_runtime_state(){
  mkdir -p "$CACHE_DIR" 2>/dev/null
  printf '%s\n' "$1" > "$STATUS_FILE"
}

json_safe(){
  v="$1"
  v=$(printf '%s' "$v" | ${TR:-tr} '\r\n' '  ')
  v=$(printf '%s' "$v" | ${SED:-sed} 's/\\/\\\\/g; s/"/\\"/g')
  printf '%s' "$v"
}

flow_snapshot_text(){
  load_config
  [ -n "$CT" ] || { echo "Conntrack niet gevonden."; return 0; }
  mkdir -p "$CACHE_DIR" 2>/dev/null
  curfile="${LIVE_FLOW_STATE}.webcur"
  tmpstate="${LIVE_FLOW_STATE}.webnew"
  : > "$curfile"
  : > "$tmpstate"

  printf "%-12s %-15s %-15s %-5s %-5s %-5s %s\n" "Bytes" "Source" "Destination" "Port" "Cand" "Final" "Hint"

  $CT -L 2>/dev/null | $AWK -v ports="$PORTS" '
    BEGIN { m=split(ports,pa,","); for(i=1;i<=m;i++) if(pa[i] != "") portok[pa[i]]=1 }
    /^(tcp|udp)/ && /bytes=/ {
      src=""; dst=""; dport=""; bytes=0
      for(i=1;i<=NF;i++){
        if($i ~ /^src=/ && src=="") { src=$i; sub(/^src=/,"",src) }
        if($i ~ /^dst=/ && dst=="") { dst=$i; sub(/^dst=/,"",dst) }
        if($i ~ /^dport=/ && dport=="") { dport=$i; sub(/^dport=/,"",dport) }
        if($i ~ /^bytes=/) { b=$i; sub(/^bytes=/,"",b); bytes+=b }
      }
      if(src=="" || dst=="" || dport=="") next
      if(!(dport in portok)) next
      key=src"|"dst"|"dport
      total[key]+=bytes
    }
    END { for(k in total){ split(k,a,"|"); print a[1], a[2], a[3], total[k] } }
  ' > "$curfile"

  while IFS=' ' read -r src dst dport bytes; do
    [ -z "$dst" ] && continue
    key="${src}|${dst}|${dport}"
    prev=""
    [ -f "$LIVE_FLOW_STATE" ] && prev="$($AWK -v k="$key" '$1==k {print $2; exit}' "$LIVE_FLOW_STATE" 2>/dev/null)"
    [ -z "$prev" ] && prev=0
    delta=$((bytes - prev)); [ "$delta" -lt 0 ] && delta="$bytes"
    printf '%s %s\n' "$key" "$bytes" >> "$tmpstate"
    printf '%012d %s %s %s\n' "$bytes" "$src" "$dst" "$dport"
  done < "$curfile" | sort -k1,1nr | head -25 | while IFS=' ' read -r bytes src dst dport; do
    cand="no"; final="no"; hint="watch"
    $IPSET test "$CAND_SET" "$dst" >/dev/null 2>&1 && cand="yes"
    $IPSET test "$IPSET_NAME" "$dst" >/dev/null 2>&1 && final="yes"
    ip_is_excluded "$dst" && hint="excluded-range"
    printf "%-12s %-15s %-15s %-5s %-5s %-5s %s\n" "$bytes" "$src" "$dst" "$dport" "$cand" "$final" "$hint"
  done

  mv "$tmpstate" "$LIVE_FLOW_STATE" 2>/dev/null
  rm -f "$curfile" 2>/dev/null
}

live_flow_snapshot_text(){
  flow_snapshot_text
}

write_web_status(){
  if [ -x "$WEBUI_HELPER" ]; then
    "$WEBUI_HELPER" publish >/dev/null 2>&1
    return 0
  fi
  load_config
  mkdir -p "$(dirname "$WEB_STATUS_FILE")" 2>/dev/null
  now="$(date '+%F %T')"
  engine_pid="-"
  promote_pid="-"
  runtime_state=""
  [ -f "$ENGINE_PIDFILE" ] && engine_pid="$(cat "$ENGINE_PIDFILE" 2>/dev/null)"
  [ -f "$PROMOTE_PIDFILE" ] && promote_pid="$(cat "$PROMOTE_PIDFILE" 2>/dev/null)"
  [ -f "$STATUS_FILE" ] && runtime_state="$(cat "$STATUS_FILE" 2>/dev/null)"
  if [ -n "$engine_pid" ] && [ "$engine_pid" != "-" ] && is_pid_alive "$engine_pid"; then
    engine_state="running"
  else
    engine_state="stopped"
    engine_pid="-"
  fi
  td_count="$(tcpdump_count)"
  cand_count="$(ipset_member_count "$CAND_SET")"
  final_count="$(ipset_member_count "$IPSET_NAME")"
  resolved_count="$([ -f "$CACHE_EXCLUDE_IPS" ] && wc -l < "$CACHE_EXCLUDE_IPS" 2>/dev/null || echo 0)"
  exclude_net_count="$($IPSET list "$EXCLUDE_NET_SET" 2>/dev/null | ${AWK:-awk} '/^Members:/ {m=1; next} m && NF {c++} END{print c+0}')"
  status_text="$(status_report 2>/dev/null | ${TR:-tr} '\r\n' '  ')"
  log_text="$(${TAIL:-tail} -n 20 "$LOGFILE" 2>/dev/null | ${TR:-tr} '\r\n' '  ')"
  candidate_text="$(show_ipset_compact "$CAND_SET" 2>/dev/null | ${TR:-tr} '\r\n' '  ')"
  final_text="$(show_ipset_compact "$IPSET_NAME" 2>/dev/null | ${TR:-tr} '\r\n' '  ')"
  flows_text="$(live_flow_snapshot_text 2>/dev/null | ${TR:-tr} '\r\n' '  ')"
  resolved_text="$([ -f "$CACHE_EXCLUDE_IPS" ] && ${CAT:-cat} "$CACHE_EXCLUDE_IPS" 2>/dev/null | ${TR:-tr} '\r\n' '  ')"
  exclude_net_text="$($IPSET list "$EXCLUDE_NET_SET" 2>/dev/null | ${TR:-tr} '\r\n' '  ')"
  tmp="${WEB_STATUS_FILE}.$$"
  {
    printf '{\n'
    printf '  "version":"%s",\n' "$(json_safe '2.8.2')"
    printf '  "last_update":"%s",\n' "$(json_safe "$now")"
    printf '  "engine":"%s",\n' "$(json_safe "$engine_state")"
    printf '  "engine_pid":"%s",\n' "$(json_safe "$engine_pid")"
    printf '  "runtime_state":"%s",\n' "$(json_safe "$runtime_state")"
    printf '  "promote_pid":"%s",\n' "$(json_safe "$promote_pid")"
    printf '  "tcpdump_count":"%s",\n' "$(json_safe "$td_count")"
    printf '  "candidate_count":"%s",\n' "$(json_safe "$cand_count")"
    printf '  "final_count":"%s",\n' "$(json_safe "$final_count")"
    printf '  "resolved_count":"%s",\n' "$(json_safe "$resolved_count")"
    printf '  "exclude_net_count":"%s",\n' "$(json_safe "$exclude_net_count")"
    printf '  "exclude_net_set":"%s",\n' "$(json_safe "$EXCLUDE_NET_SET")"
    printf '  "ipset_name":"%s",\n' "$(json_safe "$IPSET_NAME")"
    printf '  "candidate_set":"%s",\n' "$(json_safe "$CAND_SET")"
    printf '  "config":{\n'
    printf '    "INTERFACES":"%s",\n' "$(json_safe "$INTERFACES")"
    printf '    "IPSET_NAME":"%s",\n' "$(json_safe "$IPSET_NAME")"
    printf '    "PORTS":"%s",\n' "$(json_safe "$PORTS")"
    printf '    "PROMOTE_MODE":"%s",\n' "$(json_safe "$PROMOTE_MODE")"
    printf '    "MIN_AGE":"%s",\n' "$(json_safe "$MIN_AGE")"
    printf '    "MIN_BYTES":"%s",\n' "$(json_safe "$MIN_BYTES")"
    printf '    "CANDIDATE_TIMEOUT":"%s",\n' "$(json_safe "$CANDIDATE_TIMEOUT")"
    printf '    "FINAL_TIMEOUT":"%s",\n' "$(json_safe "$FINAL_TIMEOUT")"
    printf '    "STREAM_FLOW_SCAN":"%s",\n' "$(json_safe "$STREAM_FLOW_SCAN")"
    printf '    "SOURCE_IPS":"%s",\n' "$(json_safe "$SOURCE_IPS")"
    printf '    "STREAM_MIN_BYTES":"%s",\n' "$(json_safe "$STREAM_MIN_BYTES")"
    printf '    "STREAM_MIN_DELTA":"%s",\n' "$(json_safe "$STREAM_MIN_DELTA")"
    printf '    "STREAM_FLOW_TARGET":"%s",\n' "$(json_safe "$STREAM_FLOW_TARGET")"
    printf '    "EXCLUDE_DOMAINS":"%s",\n' "$(json_safe "$EXCLUDE_DOMAINS")"
    printf '    "EXCLUDE_IPS":"%s",\n' "$(json_safe "$EXCLUDE_IPS")"
    printf '    "EXCLUDE_NETS":"%s",\n' "$(json_safe "$EXCLUDE_NETS")"
    printf '    "EXCLUDE_RESOLVE_CACHE":"%s",\n' "$(json_safe "$EXCLUDE_RESOLVE_CACHE")"
    printf '    "EXCLUDE_RESOLVE_EVERY":"%s",\n' "$(json_safe "$EXCLUDE_RESOLVE_EVERY")"
    printf '    "REVERSE_DNS_CHECK":"%s",\n' "$(json_safe "$REVERSE_DNS_CHECK")"
    printf '    "CAPTURE_GENERIC_HOSTNAMES":"%s",\n' "$(json_safe "$CAPTURE_GENERIC_HOSTNAMES")"
    printf '    "ALLOW_EXTERNAL_DNS":"%s",\n' "$(json_safe "$ALLOW_EXTERNAL_DNS")"
    printf '    "EXTERNAL_DNS_SERVER":"%s"\n' "$(json_safe "$EXTERNAL_DNS_SERVER")"
    printf '  },\n'
    printf '  "status_text":"%s",\n' "$(json_safe "$status_text")"
    printf '  "log_text":"%s",\n' "$(json_safe "$log_text")"
    printf '  "candidate_text":"%s",\n' "$(json_safe "$candidate_text")"
    printf '  "final_text":"%s",\n' "$(json_safe "$final_text")"
    printf '  "flows_text":"%s",\n' "$(json_safe "$flows_text")"
    printf '  "resolved_text":"%s",\n' "$(json_safe "$resolved_text")"
    printf '  "exclude_net_text":"%s"\n' "$(json_safe "$exclude_net_text")"
    printf '}\n'
  } > "$tmp"
  mv "$tmp" "$WEB_STATUS_FILE"
}

engine_run_pids(){
  # Match uitsluitend echte engine/worker-processen met het argument "run".
  # De oude ps-match op elk proces met "vpn_ipcatcher" doodde ook WebUI-
  # helpers en gelijktijdige restart-acties, waardoor restarts elkaar konden
  # onderbreken en de resolvercache soms verdween.
  for proc in /proc/[0-9]*; do
    [ -r "$proc/cmdline" ] || continue
    pid="${proc##*/}"
    [ "$pid" = "$$" ] && continue
    cmd="$($TR '\000' ' ' < "$proc/cmdline" 2>/dev/null)"
    case "$cmd" in
      *"/jffs/scripts/vpn_ipcatcher.real.sh run"*|*"/jffs/scripts/vpn_ipcatcher.sh run"*)
        echo "$pid"
        ;;
    esac
  done
}

hard_stop_all_instances(){
  vpids="$(engine_run_pids)"
  for p in $vpids; do
    [ -n "$p" ] && kill_process_tree "$p"
  done

  sleep 1

  for p in $vpids; do
    is_pid_alive "$p" && kill -9 "$p" 2>/dev/null
  done
}

kill_process_tree(){
  # Kill only descendants of our recorded workers, never a generic tcpdump match.
  (
    parent="$1"
    case "$parent" in ''|*[!0-9]*|0|1) exit 0 ;; esac
    [ "$parent" = "$$" ] && exit 0
    for child_proc in /proc/[0-9]*; do
      [ -r "$child_proc/status" ] || continue
      child_parent="$($AWK '/^PPid:/ {print $2}' "$child_proc/status" 2>/dev/null)"
      [ "$child_parent" = "$parent" ] || continue
      kill_process_tree "${child_proc##*/}"
    done
    kill "$parent" 2>/dev/null || true
  )
}


cleanup_stale_state(){
  stale=0

  if [ -f "$LOCK" ]; then
    pid="$(cat "$LOCK" 2>/dev/null)"
    is_pid_alive "$pid" || stale=1
  fi

  if [ -f "$ENGINE_PIDFILE" ]; then
    pid="$(cat "$ENGINE_PIDFILE" 2>/dev/null)"
    is_pid_alive "$pid" || stale=1
  fi

  if [ "$stale" = "1" ]; then
    log "Stale state gevonden; oude lock/pidfiles worden opgeschoond"
    kill_pid_list "$PROMOTE_PIDFILE"
    kill_pid_list "$CAP_PIDFILE"
    rm -f "$LOCK" "$ENGINE_PIDFILE" "$PROMOTE_PIDFILE" "$CAP_PIDFILE"
  fi
}

start_promote_worker(){
  (
    last_promote=0
    while true; do
      check_learning_route
      flow_scan_candidates
      promote_deferred
      now="$(current_epoch)"
      if [ "$((now - last_promote))" -ge "$PROMOTE_EVERY" ]; then
        promote_candidates
        last_promote="$now"
      fi
      sleep "$STREAM_SCAN_EVERY"
    done
  ) &
  PROMOTE_PID=$!
  echo "$PROMOTE_PID" > "$PROMOTE_PIDFILE"
  log "Promote worker gestart pid=$PROMOTE_PID"
}

start_capture_workers(){
  : > "$CAP_PIDFILE"
  CAP_PIDS=""
  for i in $INTERFACES; do
    (
      capture_iface "$i"
    ) &
    pid="$!"
    CAP_PIDS="$CAP_PIDS $pid"
    record_cap_pid "$pid"
    log "Capture worker gestart iface=$i pid=$pid"
  done
}

count_alive_pids_in_file(){
  file="$1"
  count=0
  [ -f "$file" ] || { echo 0; return; }
  for p in $(cat "$file" 2>/dev/null); do
    is_pid_alive "$p" && count=$((count+1))
  done
  echo "$count"
}

ensure_workers_alive(){
  alive_promote=0
  alive_capture=0

  if [ -f "$PROMOTE_PIDFILE" ]; then
    p="$(cat "$PROMOTE_PIDFILE" 2>/dev/null)"
    is_pid_alive "$p" && alive_promote=1
  fi

  alive_capture="$(count_alive_pids_in_file "$CAP_PIDFILE")"

  if [ "$alive_promote" -ne 1 ]; then
    log "Promote worker is weggevallen; opnieuw starten"
    kill_pid_list "$PROMOTE_PIDFILE"
    rm -f "$PROMOTE_PIDFILE"
    start_promote_worker
  fi

  expected_caps=0
  for _i in $INTERFACES; do
    expected_caps=$((expected_caps+1))
  done

  if [ "$alive_capture" -lt "$expected_caps" ]; then
    log "Een of meer capture workers zijn weggevallen ($alive_capture/$expected_caps); opnieuw starten"
    kill_pid_list "$CAP_PIDFILE"
    rm -f "$CAP_PIDFILE"
    start_capture_workers
  fi
}

write_pidfiles(){
  mkdir -p "$PIDDIR" 2>/dev/null
  echo "$$" > "$ENGINE_PIDFILE"
  : > "$CAP_PIDFILE"
}

record_cap_pid(){
  mkdir -p "$PIDDIR" 2>/dev/null
  echo "$1" >> "$CAP_PIDFILE"
}

kill_pid_list(){
  file="$1"
  [ -f "$file" ] || return 0
  for p in $(cat "$file" 2>/dev/null); do
    [ -n "$p" ] && kill_process_tree "$p"
  done
}

cleanup(){
  [ "$STOPPING" = "1" ] && exit 0
  STOPPING=1

  log "cleanup aangeroepen STOPPING=$STOPPING pid=$$ parent=$PPID"

  [ -n "$PROMOTE_PID" ] && kill "$PROMOTE_PID" 2>/dev/null
  for p in $CAP_PIDS; do
    kill "$p" 2>/dev/null
  done

  kill_pid_list "$PROMOTE_PIDFILE"
  kill_pid_list "$CAP_PIDFILE"
  sleep 1
  kill_pid_list "$PROMOTE_PIDFILE"
  kill_pid_list "$CAP_PIDFILE"

  for p in $CAP_PIDS; do
    is_pid_alive "$p" && kill -9 "$p" 2>/dev/null
  done
  [ -n "$PROMOTE_PID" ] && is_pid_alive "$PROMOTE_PID" && kill -9 "$PROMOTE_PID" 2>/dev/null

  rm -f "$LOCK" "$ENGINE_PIDFILE" "$PROMOTE_PIDFILE" "$CAP_PIDFILE" "$STATUS_FILE" "$WEB_STATUS_FILE"

  log "Script gestopt"
  exit 0
}

valid_ipv4(){
  ip="$1"
  echo "$ip" | $GREP -Eq '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' || return 1
  OLDIFS="$IFS"; IFS='.'; set -- $ip; IFS="$OLDIFS"
  for o in "$@"; do
    [ "$o" -ge 0 ] 2>/dev/null || return 1
    [ "$o" -le 255 ] 2>/dev/null || return 1
  done
  return 0
}

ip_is_base_excluded(){
  ip="$1"
  valid_ipv4 "$ip" || return 0

  # Nooit DNS-resolver/gateway-achtige ruis toevoegen.
  for ex in $SYSTEM_EXCLUDE_IPS $EXCLUDE_IPS; do
    [ "$ip" = "$ex" ] && return 0
  done

  # Lokale/private/reserved IPs horen niet in een VPN Director streaming-ipset.
  case "$ip" in
    0.*|10.*|127.*|169.254.*|192.168.*|192.0.2.*|198.18.*|198.19.*|198.51.100.*|203.0.113.*|224.*|225.*|226.*|227.*|228.*|229.*|230.*|231.*|232.*|233.*|234.*|235.*|236.*|237.*|238.*|239.*|255.255.255.255) return 0 ;;
  esac

  # 172.16.0.0/12 en 100.64.0.0/10 uitsluiten.
  OLDIFS="$IFS"; IFS='.'; set -- $ip; IFS="$OLDIFS"
  first="$1"; second="$2"
  if [ "$first" = "172" ] && [ "$second" -ge 16 ] 2>/dev/null && [ "$second" -le 31 ] 2>/dev/null; then return 0; fi
  if [ "$first" = "100" ] && [ "$second" -ge 64 ] 2>/dev/null && [ "$second" -le 127 ] 2>/dev/null; then return 0; fi

  return 1
}

ip_in_resolved_exclude_cache(){
  ip="$1"
  [ "$EXCLUDE_RESOLVE_CACHE" = "yes" ] || return 1
  [ -f "$CACHE_EXCLUDE_IPS" ] || return 1
  $AWK -v ip="$ip" '$1==ip {found=1} END{exit found?0:1}' "$CACHE_EXCLUDE_IPS" 2>/dev/null
}

valid_cidr(){
  net="$1"
  echo "$net" | $GREP -Eq '^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$' || return 1
  ip="${net%/*}"; mask="${net#*/}"
  valid_ipv4 "$ip" || return 1
  [ "$mask" -ge 0 ] 2>/dev/null || return 1
  [ "$mask" -le 32 ] 2>/dev/null || return 1
  return 0
}

ensure_exclude_net_set(){
  [ -n "$IPSET" ] || return 1
  [ -n "$EXCLUDE_NET_SET" ] || EXCLUDE_NET_SET="${IPSET_NAME}_exclude"
  $IPSET list "$EXCLUDE_NET_SET" >/dev/null 2>&1 && return 0
  $IPSET create "$EXCLUDE_NET_SET" hash:net family inet comment >/dev/null 2>&1 || \
    $IPSET create "$EXCLUDE_NET_SET" hash:net family inet >/dev/null 2>&1
}

rebuild_exclude_net_set(){
  load_config || return 1
  [ -n "$IPSET" ] || return 1
  ensure_exclude_net_set || return 1
  exclude_build="vpnipc_ex_$$"
  exclude_comment=""
  $IPSET save "$EXCLUDE_NET_SET" 2>/dev/null | $GREP -q ' comment' && exclude_comment=comment
  $IPSET create "$exclude_build" hash:net family inet $exclude_comment >/dev/null 2>&1 || return 1
  for net in $EXCLUDE_NETS; do
    valid_cidr "$net" || { log "Skip invalid EXCLUDE_NETS entry: $net"; continue; }
    if ! $IPSET add "$exclude_build" "$net" -exist >/dev/null 2>&1; then
      $IPSET destroy "$exclude_build" >/dev/null 2>&1
      return 1
    fi
  done
  # Keep the previous exclusions active until the entire replacement is ready.
  $IPSET swap "$EXCLUDE_NET_SET" "$exclude_build" >/dev/null 2>&1
  exclude_result=$?
  $IPSET destroy "$exclude_build" >/dev/null 2>&1
  return "$exclude_result"
}

ip_in_exclude_net_set(){
  ip="$1"
  valid_ipv4 "$ip" || return 1
  [ -n "$IPSET" ] || return 1
  [ -n "$EXCLUDE_NET_SET" ] || EXCLUDE_NET_SET="${IPSET_NAME}_exclude"
  $IPSET test "$EXCLUDE_NET_SET" "$ip" >/dev/null 2>&1
}

ip_is_excluded(){
  ip="$1"
  ip_is_base_excluded "$ip" && return 0
  ip_in_exclude_net_set "$ip" && return 0
  ip_in_resolved_exclude_cache "$ip" && return 0
  return 1
}

domain_is_excluded(){
  dom="$1"
  for ex in $EXCLUDE_DOMAINS; do
    case "$dom" in "$ex"|*."$ex") return 0 ;; esac
  done
  return 1
}

current_epoch(){ date '+%s' 2>/dev/null || echo 0; }

cache_age_seconds(){
  [ -f "$CACHE_EXCLUDE_TS" ] || { echo 999999; return; }
  now="$(current_epoch)"
  old="$(cat "$CACHE_EXCLUDE_TS" 2>/dev/null)"
  case "$now:$old" in *[!0-9:]*) echo 999999; return ;; esac
  echo $((now - old))
}

resolve_exclude_domain(){
  dom="$(safe_domain "$1")"
  [ -z "$dom" ] && return 0
  # Let op: NIET domain_is_excluded toepassen, want dit zijn juist exclude-domeinen.
  $NSLOOKUP "$dom" 127.0.0.1 2>/dev/null | extract_nslookup_ips | $AWK '!seen[$0]++'
  if [ "$ALLOW_EXTERNAL_DNS" = "yes" ] && [ -n "$EXTERNAL_DNS_SERVER" ]; then
    $NSLOOKUP "$dom" "$EXTERNAL_DNS_SERVER" 2>/dev/null | extract_nslookup_ips | $AWK '!seen[$0]++'
  fi
}

exclude_cache_lock(){
  tries=0
  while ! mkdir "$EXCLUDE_CACHE_LOCK" 2>/dev/null; do
    oldpid="$(cat "$EXCLUDE_CACHE_LOCK/pid" 2>/dev/null)"
    if [ -n "$oldpid" ] && ! kill -0 "$oldpid" 2>/dev/null; then
      rm -rf "$EXCLUDE_CACHE_LOCK" 2>/dev/null
      continue
    fi
    tries=$((tries+1))
    [ "$tries" -ge 120 ] && { log "Resolverlock timeout; refresh overgeslagen"; return 1; }
    sleep 1
  done
  read lockpid _rest < /proc/self/stat
  echo "$lockpid" > "$EXCLUDE_CACHE_LOCK/pid" 2>/dev/null
  return 0
}

exclude_cache_unlock(){ rm -rf "$EXCLUDE_CACHE_LOCK" 2>/dev/null; }

refresh_exclusion_ip_cache(){
  force="$1"
  load_config
  [ "$EXCLUDE_RESOLVE_CACHE" = "yes" ] || { say "Exclusion resolver staat uit."; return 0; }
  age="$(cache_age_seconds)"
  if [ "$force" != "force" ] && [ "$age" -lt "$EXCLUDE_RESOLVE_EVERY" ] 2>/dev/null; then
    return 0
  fi

  exclude_cache_lock || return 1
  # Een tweede worker kan tijdens het wachten de cache al hebben vernieuwd.
  age="$(cache_age_seconds)"
  if [ "$force" != "force" ] && [ "$age" -lt "$EXCLUDE_RESOLVE_EVERY" ] 2>/dev/null; then
    exclude_cache_unlock
    return 0
  fi

  mkdir -p "$CACHE_DIR" 2>/dev/null
  tmp="$CACHE_EXCLUDE_IPS.$$"
  : > "$tmp"

  for dom in $EXCLUDE_DOMAINS; do
    d="$(safe_domain "$dom")"
    [ -z "$d" ] && continue
    case "$d" in
      *awwle*|*iclold*|*elfy*|*githlb*|*whatsaww*|*snawchat*|*dahla*) log "Skip corrupt exclude-domain token: $d"; continue ;;
    esac

    # Gebruik één gedeelde BusyBox-compatibele nslookup-parser. De vorige
    # inline AWK-regex bevatte dubbel ge-escapete punten (\\.) en verwierp
    # daardoor ieder geldig IPv4-adres.
    $NSLOOKUP "$d" 127.0.0.1 2>/dev/null | extract_nslookup_ips | while IFS= read -r ip; do
      valid_ipv4 "$ip" && ! ip_is_base_excluded "$ip" && echo "$ip $d" >> "$tmp"
    done

    if [ "$ALLOW_EXTERNAL_DNS" = "yes" ] && [ -n "$EXTERNAL_DNS_SERVER" ]; then
      $NSLOOKUP "$d" "$EXTERNAL_DNS_SERVER" 2>/dev/null | extract_nslookup_ips | while IFS= read -r ip; do
        valid_ipv4 "$ip" && ! ip_is_base_excluded "$ip" && echo "$ip $d" >> "$tmp"
      done
    fi
  done

  if [ -s "$tmp" ]; then
    $AWK '!seen[$1]++ {print}' "$tmp" > "${tmp}.uniq"
    mv "${tmp}.uniq" "$CACHE_EXCLUDE_IPS"
  else
    : > "$CACHE_EXCLUDE_IPS"
  fi
  rm -f "$tmp" "${tmp}.uniq" 2>/dev/null
  current_epoch > "$CACHE_EXCLUDE_TS"
  rebuild_exclude_net_set
  log "Exclusion IP cache ververst ($(wc -l < "$CACHE_EXCLUDE_IPS" 2>/dev/null) IPs), exclude_nets=$(ipset_member_count "$EXCLUDE_NET_SET" 2>/dev/null)"
  exclude_cache_unlock
}

reverse_lookup_ip(){
  ip="$1"
  valid_ipv4 "$ip" || return 0
  [ -f "$CACHE_PTR" ] && cached="$($AWK -v ip="$ip" '$1==ip {print $2; found=1} END{if(!found) exit 1}' "$CACHE_PTR" 2>/dev/null)" && [ -n "$cached" ] && { echo "$cached"; return 0; }
  name="$($NSLOOKUP "$ip" 127.0.0.1 2>/dev/null | $AWK '
    /name =/ {gsub(/\.$/,"",$NF); print $NF; exit}
    /^Name:/ {print $2; exit}
  ' | $TR '[:upper:]' '[:lower:]' | $TR -cd 'A-Za-z0-9.-')"
  [ -n "$name" ] && { mkdir -p "$CACHE_DIR" 2>/dev/null; echo "$ip $name" >> "$CACHE_PTR"; echo "$name"; }
}

ip_excluded_by_reverse_dns(){
  [ "$REVERSE_DNS_CHECK" = "yes" ] || return 1
  ip="$1"
  name="$(reverse_lookup_ip "$ip")"
  [ -z "$name" ] && return 1
  domain_is_excluded "$name" && return 0
  return 1
}

should_skip_service_ip(){
  stage="$1"
  ip="$2"
  comment="$3"

  [ -z "$ip" ] && return 0

  if ip_is_excluded "$ip"; then
    log "Skip excluded IP ${stage}: $ip ($comment)"
    return 0
  fi

  if ip_excluded_by_reverse_dns "$ip"; then
    rdns="$(reverse_lookup_ip "$ip")"
    log "Skip reverse-DNS excluded ${stage}: $ip rdns=${rdns:-unknown} ($comment)"
    return 0
  fi

  return 1
}

safe_domain(){
  # Gebruik bewust geen tr -cd meer; awk+sed voorkomt corrupte domeinen zoals apple->awwle.
  printf '%s' "$1" | $AWK '{print tolower($0)}' | $SED 's/[^a-z0-9.-]//g'
}

cache_get(){
  dom="$1"
  $AWK -v d="$dom" '$1==d { $1=""; sub(/^ /,""); print }' "$CACHE_DOM2IP" 2>/dev/null | $TAIL -n 1
}

cache_put(){
  dom="$1"; ips="$2"
  tmpfile="${CACHE_DOM2IP}.$$"
  $AWK -v d="$dom" '$1!=d {print}' "$CACHE_DOM2IP" 2>/dev/null > "$tmpfile"
  echo "$dom $ips" >> "$tmpfile"
  mv "$tmpfile" "$CACHE_DOM2IP"
}

extract_nslookup_ips(){
  # BusyBox nslookup op Asus/Merlin toont eerst de DNS-server:
  #   Address 1: 127.0.0.1 localhost.localdomain
  # en daarna pas de echte antwoorden na "Name:".
  # De oude parser pakte alleen regels die direct eindigden op het IP,
  # waardoor regels zoals "Address 1: 157.240.0.13 edge-star..." werden gemist.
  $AWK '
    /^Name:/ { in_answer=1; next }
    in_answer && /^Address[[:space:]][0-9]+:/ {
      ip=$3
      if (ip ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) print ip
      next
    }
    in_answer && /^Address:/ {
      ip=$2
      if (ip ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) print ip
      next
    }
  ' | while IFS= read -r ip; do
    valid_ipv4 "$ip" && ! ip_is_base_excluded "$ip" && echo "$ip"
  done
}
resolve_once(){
  dom="$(safe_domain "$1")"
  [ -z "$dom" ] && return 0
  domain_is_excluded "$dom" && return 0

  line="$(cache_get "$dom")"
  [ -n "$line" ] && { echo "$line"; return 0; }

  # Bewust alleen de router/lokale resolver gebruiken.
  ips="$($NSLOOKUP "$dom" 127.0.0.1 2>/dev/null | extract_nslookup_ips | $AWK '!seen[$0]++' | tr '\n' ' ' | $SED 's/[ ]*$//')"

  # Alleen optioneel externe DNS, nooit standaard.
  if [ -z "$ips" ] && [ "$ALLOW_EXTERNAL_DNS" = "yes" ] && [ -n "$EXTERNAL_DNS_SERVER" ]; then
    ips="$($NSLOOKUP "$dom" "$EXTERNAL_DNS_SERVER" 2>/dev/null | extract_nslookup_ips | $AWK '!seen[$0]++' | tr '\n' ' ' | $SED 's/[ ]*$//')"
  fi

  [ -n "$ips" ] && cache_put "$dom" "$ips"
  echo "$ips"
}

ensure_set(){
  setname="$1"; timeout="$2"

  if $IPSET list "$setname" >/dev/null 2>&1; then
    if $IPSET save "$setname" 2>/dev/null | $GREP -q "create $setname hash:ip .*timeout .*counters .*comment"; then
      return 0
    fi

    tmp="${setname}_tmp$$"
    $IPSET create "$tmp" hash:ip timeout "$timeout" counters comment || return 1
    $IPSET list "$setname" 2>/dev/null | $SED -n '/^Members:/,$p' | tail -n +2 | \
    while IFS= read -r line; do
      ip="$(echo "$line" | $SED -n 's/^[[:space:]]*\([0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}\).*/\1/p')"
      [ -n "$ip" ] && ! ip_is_excluded "$ip" && ! ip_excluded_by_reverse_dns "$ip" && $IPSET add "$tmp" "$ip" >/dev/null 2>&1
    done
    if ! $IPSET swap "$setname" "$tmp"; then
      $IPSET destroy "$tmp" >/dev/null 2>&1
      return 1
    fi
    $IPSET destroy "$tmp"
  else
    $IPSET create "$setname" hash:ip timeout "$timeout" counters comment || return 1
  fi
}

make_ipset_comment(){
  src="$1"
  ts="$(date '+%Y%m%d-%H%M%S' 2>/dev/null)"
  [ -z "$ts" ] && ts="unknown"
  src="$(printf '%s' "$src" | $TR '[:upper:]' '[:lower:]' | $TR -cd 'a-z0-9._:-')"
  [ -z "$src" ] && src="unknown"
  # Geen spaties gebruiken in ipset-comments; dat houdt parsing op BusyBox betrouwbaar.
  printf 'src=%s;seen=%s' "$src" "$ts"
}

add_candidate_once(){
  ip="$1"; comment="$2"
  [ -z "$ip" ] && return 0
  should_skip_service_ip "candidate" "$ip" "$comment" && return 0
  # Preserve first-seen age; repeated packets must not reset the timeout.
  $IPSET test "$CAND_SET" "$ip" >/dev/null 2>&1 && return 0
  comment="$(make_ipset_comment "$comment")"
  $IPSET add "$CAND_SET" "$ip" -exist timeout "$CANDIDATE_TIMEOUT" comment "$comment" >/dev/null 2>&1
}

check_learning_route(){
  if [ -x "$ROUTING_HELPER" ] && "$ROUTING_HELPER" prepare >/dev/null 2>&1; then
    printf '%s %s\n' "$(current_epoch)" "$IPSET_NAME" > "${ROUTING_STATUS}.new"
    mv "${ROUTING_STATUS}.new" "$ROUTING_STATUS"
  else
    rm -f "$ROUTING_STATUS"
    log "Routingcontrole faalt; geen nieuwe IPs naar de finale lijst."
  fi
}
learning_route_ready(){
  [ -r "$ROUTING_STATUS" ] || return 1
  read -r checked_at checked_set < "$ROUTING_STATUS"
  case "$checked_at" in ''|*[!0-9]*) return 1 ;; esac
  [ "$checked_set" = "$IPSET_NAME" ] || return 1
  route_age=$(( $(current_epoch) - checked_at ))
  max_age=$(( STREAM_SCAN_EVERY * 2 ))
  [ "$max_age" -ge 15 ] || max_age=15
  [ "$route_age" -ge 0 ] && [ "$route_age" -le "$max_age" ]
}
destination_is_idle(){
  [ -n "$CT" ] || return 1
  if [ -n "${PROMOTION_SNAPSHOT:-}" ]; then
    [ -r "$PROMOTION_SNAPSHOT" ] || return 1
    destination_snapshot_is_idle "$1" "$PROMOTION_SNAPSHOT"
    return $?
  fi
  probe="$CACHE_DIR/promotion-probe"
  mkdir "$probe" 2>/dev/null || return 1
  (
    trap 'rm -f "$probe/connections"; rmdir "$probe" 2>/dev/null' EXIT
    trap 'exit 1' HUP INT TERM
    # Check all clients and ports: the DVR destination rule affects them all.
    $CT -L -f ipv4 > "$probe/connections" 2>/dev/null || exit 1
    destination_snapshot_is_idle "$1" "$probe/connections"
  )
}
destination_snapshot_is_idle(){
    $AWK -v target="$1" '
      {for(i=1;i<=NF;i++) if($i ~ /^dst=/) {
        destination=$i; sub(/^dst=/,"",destination);
        if(destination==target) active=1;
        break
      }}
      END{exit active?1:0}' "$2"
}
promote_deferred(){
  (
  [ -n "$CT" ] || exit 1
  probe="$CACHE_DIR/promotion-batch"
  mkdir "$probe" 2>/dev/null || exit 1
  trap 'rm -f "$probe/connections" "$probe/set" "$probe/waiting"; rmdir "$probe" 2>/dev/null' EXIT
  trap 'exit 1' HUP INT TERM
  $IPSET save "$WAIT_SET" > "$probe/set" 2>/dev/null || exit 1
  $AWK '$1=="add" {print $3}' "$probe/set" > "$probe/waiting"
  [ -s "$probe/waiting" ] || exit 0
  $CT -L -f ipv4 > "$probe/connections" 2>/dev/null || exit 1
  PROMOTION_SNAPSHOT="$probe/connections"
  while IFS= read -r deferred_ip; do
    valid_ipv4 "$deferred_ip" || continue
    if add_final_immediate "$deferred_ip" 'promoted-after-idle'; then
      $IPSET del "$WAIT_SET" "$deferred_ip" >/dev/null 2>&1
      $IPSET del "$CAND_SET" "$deferred_ip" >/dev/null 2>&1
    fi
  done < "$probe/waiting"
  )
}
add_final_immediate(){
  (
  ip="$1"; comment="$2"
  [ -z "$ip" ] && return 0
  learning_route_ready || return 1
  should_skip_service_ip "final" "$ip" "$comment" && return 0
  comment="$(make_ipset_comment "$comment")"
  # Refreshing an existing member does not introduce a new destination route.
  if ! $IPSET test "$IPSET_NAME" "$ip" >/dev/null 2>&1 && ! destination_is_idle "$ip"; then
    $IPSET add "$WAIT_SET" "$ip" -exist timeout 86400 comment "$comment" >/dev/null 2>&1
    return 1
  fi
  $IPSET add "$IPSET_NAME" "$ip" -exist timeout "$FINAL_TIMEOUT" comment "$comment" >/dev/null 2>&1
  )
}

enable_conntrack_acct(){
  ACCT_OK=0
  if [ -n "$CT" ] && [ -f /proc/sys/net/netfilter/nf_conntrack_acct ]; then
    [ "$(cat /proc/sys/net/netfilter/nf_conntrack_acct 2>/dev/null)" != "1" ] && echo 1 > /proc/sys/net/netfilter/nf_conntrack_acct 2>/dev/null
    [ "$(cat /proc/sys/net/netfilter/nf_conntrack_acct 2>/dev/null)" = "1" ] && ACCT_OK=1
  fi
}


source_ip_allowed(){
  ip="$1"
  [ -z "$SOURCE_IPS" ] && return 0
  for s in $SOURCE_IPS; do
    [ "$ip" = "$s" ] && return 0
  done
  return 1
}

port_allowed(){
  port="$1"
  OLDIFS="$IFS"; IFS=','; set -- $PORTS; IFS="$OLDIFS"
  for p in "$@"; do
    [ "$port" = "$p" ] && return 0
  done
  return 1
}

flow_scan_candidates(){
  [ "$STREAM_FLOW_SCAN" = "yes" ] || return 0
  [ -n "$CT" ] || return 0
  [ "$ACCT_OK" = "1" ] || return 0
  refresh_exclusion_ip_cache auto

  mkdir -p "$CACHE_DIR" 2>/dev/null
  curfile="${FLOW_STATE}.cur"
  tmpstate="${FLOW_STATE}.new"
  : > "$curfile"
  : > "$tmpstate"

  # Aggregateer per source+destination+port. Daarna vergelijken we met de vorige scan.
  # Belangrijk: conntrack bytes zijn cumulatief zolang de verbinding bestaat. Daarom kijken we naar DELTA.
  $CT -L 2>/dev/null | $AWK -v sources="$SOURCE_IPS" -v ports="$PORTS" '
    BEGIN {
      n=split(sources,sa," "); for(i=1;i<=n;i++) if(sa[i] != "") srcok[sa[i]]=1
      use_src_filter=(n>0 && sources!="")
      m=split(ports,pa,","); for(i=1;i<=m;i++) if(pa[i] != "") portok[pa[i]]=1
    }
    /^(tcp|udp)/ {
      src=""; dst=""; dport=""; bytes=0
      for(i=1;i<=NF;i++){
        if($i ~ /^src=/ && src=="") { src=$i; sub(/^src=/,"",src) }
        if($i ~ /^dst=/ && dst=="") { dst=$i; sub(/^dst=/,"",dst) }
        if($i ~ /^dport=/ && dport=="") { dport=$i; sub(/^dport=/,"",dport) }
        if($i ~ /^bytes=/) { b=$i; sub(/^bytes=/,"",b); bytes+=b }
      }
      if(src=="" || dst=="" || dport=="") next
      if(use_src_filter && !(src in srcok)) next
      if(!(dport in portok)) next
      key=src"|"dst"|"dport
      total[key]+=bytes
    }
    END { for(k in total){ split(k,a,"|"); print a[1], a[2], a[3], total[k] } }
  ' > "$curfile"

  while IFS=' ' read -r src ip dport bytes; do
    [ -z "$ip" ] && continue
    key="${src}|${ip}|${dport}"
    prev=""
    [ -f "$FLOW_STATE" ] && prev="$($AWK -v k="$key" '$1==k {print $2; exit}' "$FLOW_STATE" 2>/dev/null)"
    [ -z "$prev" ] && prev=0
    delta=$((bytes - prev))
    [ "$delta" -lt 0 ] && delta="$bytes"

    printf '%s %s\n' "$key" "$bytes" >> "$tmpstate"

    if [ "$STREAM_REQUIRE_GROWTH" = "yes" ]; then
      [ "$prev" = "0" ] && continue
      [ "$delta" -lt "$STREAM_MIN_DELTA" ] && continue
    fi

    [ "$bytes" -lt "$STREAM_MIN_BYTES" ] && continue

    if valid_ipv4 "$ip" && ! ip_is_excluded "$ip"; then
      if ip_excluded_by_reverse_dns "$ip"; then
        log "Skip reverse-DNS excluded flow IP: $ip"
        continue
      fi
      if [ "$STREAM_FLOW_TARGET" = "final" ]; then
        add_final_immediate "$ip" "flow-delta${delta}b-total${bytes}b-${src}-${dport}"
      else
        add_candidate_once "$ip" "flow-delta${delta}b-total${bytes}b-${src}-${dport}"
      fi
    fi
  done < "$curfile"

  mv "$tmpstate" "$FLOW_STATE" 2>/dev/null
  rm -f "$curfile" 2>/dev/null
}

promote_candidates(){
  mode="$PROMOTE_MODE"
  [ "$mode" = "auto" ] && mode="$( [ "$ACCT_OK" = "1" ] && [ -n "$CT" ] && echo bytes || echo age )"

  $IPSET list "$CAND_SET" 2>/dev/null | $SED -n '/^Members:/,$p' | tail -n +2 | \
  while IFS= read -r line; do
    ip="$(echo "$line" | $SED -n 's/^[[:space:]]*\([0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}\).*/\1/p')"
    [ -z "$ip" ] && continue
    if should_skip_service_ip "promote" "$ip" "candidate-promote"; then
      $IPSET del "$CAND_SET" "$ip" >/dev/null 2>&1
      continue
    fi

    rem_tmo="$(echo "$line" | $SED -n 's/.*timeout \([0-9]\+\).*/\1/p')"
    [ -z "$rem_tmo" ] && rem_tmo=0
    age=$(( CANDIDATE_TIMEOUT - rem_tmo ))

    case "$mode" in
      immediate)
        add_final_immediate "$ip" "promoted-immediate" && $IPSET del "$CAND_SET" "$ip" >/dev/null 2>&1
        ;;
      age)
        [ "$age" -lt "$MIN_AGE" ] && continue
        add_final_immediate "$ip" "promoted-age" && $IPSET del "$CAND_SET" "$ip" >/dev/null 2>&1
        ;;
      bytes)
        [ "$age" -lt "$MIN_AGE" ] && continue
        total_bytes="$($CT -L 2>/dev/null | $AWK -v target="$ip" -v sources="$SOURCE_IPS" -v ports="$PORTS" '
          BEGIN { n=split(sources,s," "); for(i=1;i<=n;i++) allowed[s[i]]=1;
                  n=split(ports,p,","); for(i=1;i<=n;i++) portok[p[i]]=1 }
          /^(tcp|udp)/ {
            src=""; dst=""; port=""; bytes=0
            for(i=1;i<=NF;i++) {
              if($i ~ /^src=/ && src=="") {src=$i; sub(/^src=/,"",src)}
              if($i ~ /^dst=/ && dst=="") {dst=$i; sub(/^dst=/,"",dst)}
              if($i ~ /^dport=/ && port=="") {port=$i; sub(/^dport=/,"",port)}
              if($i ~ /^bytes=/) {b=$i; sub(/^bytes=/,"",b); bytes+=b}
            }
            if(dst==target && (sources=="" || src in allowed) && port in portok) sum+=bytes
          }
          END {printf "%.0f\n",sum+0}')"
        [ -z "$total_bytes" ] && total_bytes=0
        if [ "$total_bytes" -ge "$MIN_BYTES" ]; then
          add_final_immediate "$ip" "promoted-bytes" && $IPSET del "$CAND_SET" "$ip" >/dev/null 2>&1
        fi
        ;;
    esac
  done
}

build_bpf(){
  pexp=""
  OLDIFS="$IFS"; IFS=','; set -- $PORTS; IFS="$OLDIFS"
  for p in "$@"; do
    [ -z "$p" ] && continue
    [ -n "$pexp" ] && pexp="$pexp or "
    pexp="${pexp}port ${p}"
  done
  [ -z "$pexp" ] && pexp="port 80 or port 443"
  BPF="tcp and ($pexp)"
  if [ -n "$SOURCE_IPS" ]; then
    sexp=""
    for src in $SOURCE_IPS; do
      valid_ipv4 "$src" || return 1
      [ -n "$sexp" ] && sexp="$sexp or "
      sexp="${sexp}src host $src"
    done
    BPF="$BPF and ($sexp)"
  fi
}

capture_iface(){
  iface="$1"
  backoff="$RETRY_DELAY"

  while true; do
    if [ -n "$IPBIN" ] && ! $IPBIN link show "$iface" >/dev/null 2>&1; then
      log "[$iface] interface niet beschikbaar; retry ${backoff}s"
      sleep "$backoff"
      continue
    fi

    log "[$iface] Start tcpdump filter '($BPF)'"
    "$TCPDUMP" -i "$iface" -A -n -s 1024 -l "$BPF" 2>>"$LOGFILE" | \
    while IFS= read -r line; do
      # HTTP Location met direct IP
      echo "$line" | $SED -n 's/.*[Ll]ocation: http[s]*:\/\/\([0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}\).*/\1/p' | \
      while IFS= read -r ip; do
        [ -z "$ip" ] && continue
        [ "$PROMOTE_MODE" = "immediate" ] && add_final_immediate "$ip" "http-location" || add_candidate_once "$ip" "http-location"
      done

      # HTTP Host header
      echo "$line" | $SED -n 's/.*[Hh]ost:[[:space:]]*\([A-Za-z0-9.-]\+\).*/\1/p' | \
      while IFS= read -r dom; do
        [ -z "$dom" ] && continue
        dom_lc="$(safe_domain "$dom")"
        [ -z "$dom_lc" ] && continue
        domain_is_excluded "$dom_lc" && continue
        ips="$(resolve_once "$dom_lc")"
        [ -z "$ips" ] && continue
        for ip in $ips; do
          [ "$PROMOTE_MODE" = "immediate" ] && add_final_immediate "$ip" "$dom_lc" || add_candidate_once "$ip" "$dom_lc"
        done
      done

      # Generic hostnames / TLS SNI-achtige strings
      # Dit kan veel ruis geven; standaard uit via CAPTURE_GENERIC_HOSTNAMES=no.
      if [ "$CAPTURE_GENERIC_HOSTNAMES" = "yes" ]; then
        echo "$line" | $GREP -aoE '([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}' | \
        while IFS= read -r dom; do
          [ -z "$dom" ] && continue
          case "$dom" in *..*|*.local|localhost|localdomain) continue ;; esac
          dom_lc="$(safe_domain "$dom")"
          [ -z "$dom_lc" ] && continue
          domain_is_excluded "$dom_lc" && continue
          ips="$(resolve_once "$dom_lc")"
          [ -z "$ips" ] && continue
          for ip in $ips; do
            [ "$PROMOTE_MODE" = "immediate" ] && add_final_immediate "$ip" "$dom_lc" || add_candidate_once "$ip" "$dom_lc"
          done
        done
      fi
    done

    log "[$iface] tcpdump stream ended; retry ${backoff}s"
    sleep "$backoff"
    backoff=$((backoff * 2))
    [ "$backoff" -gt "$MAX_RETRY_DELAY" ] && backoff="$MAX_RETRY_DELAY"
  done
}

run_engine(){
  load_config || exit 1
  validate_prereqs || exit 1
  [ -x "$ROUTING_HELPER" ] && "$ROUTING_HELPER" prepare || { log "De gekozen VPN is niet klaar. Zet deze aan of kies opnieuw via routing-setup."; exit 1; }

  mkdir -p "$CACHE_DIR" "$PIDDIR"
  [ -f "$CACHE_DOM2IP" ] || : > "$CACHE_DOM2IP"

  cleanup_stale_state

  if is_running; then
    log "Reeds actief (pid $(cat "$ENGINE_PIDFILE" 2>/dev/null)) - start afgebroken."
    exit 0
  fi

  echo $$ > "$LOCK"
  write_pidfiles
  set_runtime_state "STARTING"

  trap 'log "SIGINT ontvangen"; cleanup' INT
  trap 'log "SIGTERM ontvangen"; cleanup' TERM

  ensure_set "$CAND_SET" "$CANDIDATE_TIMEOUT" || { log "FOUT: '$CAND_SET'"; cleanup; }
  ensure_set "$IPSET_NAME" "$FINAL_TIMEOUT"   || { log "FOUT: '$IPSET_NAME'"; cleanup; }
  ensure_set "$WAIT_SET" 86400 || { log "FOUT: '$WAIT_SET'"; cleanup; }
  rm -f "$CACHE_DIR/promotion-probe/connections"
  rmdir "$CACHE_DIR/promotion-probe" 2>/dev/null || true
  rebuild_exclude_net_set || { log "FOUT: exclusion IPSet kon niet worden opgebouwd"; cleanup; }
  check_learning_route

  enable_conntrack_acct
  build_bpf || { log "Ongeldig SOURCE_IPS filter"; cleanup; }

  log "Gebruik tcpdump: $TCPDUMP"
  log "Interfaces: $INTERFACES"
  log "Filter: ($BPF) acct=$ACCT_OK promote=$PROMOTE_MODE every=${PROMOTE_EVERY}s"
  log "External DNS fallback: $ALLOW_EXTERNAL_DNS ${EXTERNAL_DNS_SERVER:+server=$EXTERNAL_DNS_SERVER}"
  log "Generic hostname scan: $CAPTURE_GENERIC_HOSTNAMES"
  log "Stream flow scan: $STREAM_FLOW_SCAN source_ips=${SOURCE_IPS:-all-devices} min_bytes=$STREAM_MIN_BYTES min_delta=$STREAM_MIN_DELTA require_growth=$STREAM_REQUIRE_GROWTH scan_every=$STREAM_SCAN_EVERY target=$STREAM_FLOW_TARGET"
  log "Exclusion resolver: $EXCLUDE_RESOLVE_CACHE every=${EXCLUDE_RESOLVE_EVERY}s reverse_dns=$REVERSE_DNS_CHECK"
  log "Exclude net set: $EXCLUDE_NET_SET nets=$(echo "$EXCLUDE_NETS" | $AWK '{print NF+0}')"

  # Start workers first; exclusion refresh mag startup niet blokkeren.
  start_promote_worker
  start_capture_workers
  set_runtime_state "RUNNING"
  write_web_status

  # Exclusion cache verversen op de achtergrond.
  (
    refresh_exclusion_ip_cache auto
  ) &

  while true; do
    echo $$ > "$LOCK"
    echo $$ > "$ENGINE_PIDFILE"
    ensure_workers_alive
    write_web_status
    sleep 10
  done
}

ipset_member_count(){
  setname="$1"
  $IPSET list "$setname" 2>/dev/null | $AWK '
    /^Members:/ {members=1; next}
    members && $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\/[0-9]+)?$/ {count++}
    END{print count+0}'
}

ipset_remove_excluded(){
  load_config
  rebuild_exclude_net_set
  for setname in "$CAND_SET" "$WAIT_SET" "$IPSET_NAME"; do
    $IPSET list "$setname" >/dev/null 2>&1 || continue
    $IPSET list "$setname" 2>/dev/null | $SED -n '/^Members:/,$p' | tail -n +2 | \
    while IFS= read -r line; do
      ip="$(echo "$line" | $SED -n 's/^[[:space:]]*\([0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}\).*/\1/p')"
      [ -z "$ip" ] && continue
      if ip_is_excluded "$ip"; then
        $IPSET del "$setname" "$ip" >/dev/null 2>&1
        echo "Removed excluded IP from $setname: $ip"
      fi
    done
  done
}

tcpdump_count(){
  [ -n "$PSBIN" ] || { echo 0; return; }
  $PSBIN 2>/dev/null | $AWK '/tcpdump/ && / -A / && / -l / && $0 !~ /awk/ {c++} END{print c+0}'
}

show_ipset_compact(){
  setname="$1"
  if ! $IPSET list "$setname" >/dev/null 2>&1; then
    say "IPSet '$setname' bestaat nog niet."
    return 0
  fi
  $IPSET list "$setname" 2>/dev/null | $AWK '
    BEGIN { members=0 }
    /^Name:/ {print; next}
    /^Type:/ {print; next}
    /^Header:/ {print; next}
    /^Size in memory:/ {next}
    /^References:/ {next}
    /^Number of entries:/ {print; next}
    /^Members:/ { members=1; print; printf "%-16s  %-15s %-10s %-12s %-16s %s\n", "IP", "timeout", "packets", "bytes", "seen", "source"; next }
    members && $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ {
      ip=$1; timeout="-"; packets="-"; bytes="-"; comment=""; seen="-"; src="-"
      for(i=2;i<=NF;i++){
        if($i=="timeout" && (i+1)<=NF) timeout=$(i+1)
        if($i=="packets" && (i+1)<=NF) packets=$(i+1)
        if($i=="bytes" && (i+1)<=NF) bytes=$(i+1)
        if($i=="comment" && (i+1)<=NF) { comment=$(i+1); gsub(/"/, "", comment) }
      }
      if(comment != "") {
        n=split(comment, parts, ";")
        for(j=1;j<=n;j++){
          if(parts[j] ~ /^seen=/) { seen=parts[j]; sub(/^seen=/, "", seen) }
          if(parts[j] ~ /^src=/) { src=parts[j]; sub(/^src=/, "", src) }
        }
        if(seen == "-" && src == "-") src=comment
      }
      printf "%-16s  timeout=%-7s packets=%-8s bytes=%-10s seen=%-15s %s\n", ip, timeout, packets, bytes, seen, src
    }'
}
status_report(){
  load_config
  cand_count="$(ipset_member_count "$CAND_SET")"
  final_count="$(ipset_member_count "$IPSET_NAME")"
  td_count="$(tcpdump_count)"
  now="$(date '+%F %T')"

  engine_pid="-"
  promote_pid="-"
  capture_alive="$(count_alive_pids_in_file "$CAP_PIDFILE")"

  if [ -f "$ENGINE_PIDFILE" ]; then
    engine_pid="$(cat "$ENGINE_PIDFILE" 2>/dev/null)"
  fi

  if [ -f "$PROMOTE_PIDFILE" ]; then
    promote_pid="$(cat "$PROMOTE_PIDFILE" 2>/dev/null)"
  fi

  runtime_state=""
  [ -f "$STATUS_FILE" ] && runtime_state="$(cat "$STATUS_FILE" 2>/dev/null)"

  if [ -n "$engine_pid" ] && [ "$engine_pid" != "-" ] && is_pid_alive "$engine_pid"; then
    case "$runtime_state" in
      STARTING) engine_state="STARTING initializing" ;;
      *) engine_state="OK running" ;;
    esac
  else
    engine_state="STOP stopped"
    engine_pid="-"
  fi

  if [ "$runtime_state" = "STARTING" ] && [ "$capture_alive" -eq 0 ]; then
    capture_state="STARTING waiting for workers"
  elif [ "$capture_alive" -gt 0 ] && [ "$td_count" -gt 0 ]; then
    capture_state="OK active ($td_count tcpdump / $capture_alive workers)"
  elif [ "$capture_alive" -gt 0 ]; then
    capture_state="WARN workers alive, tcpdump inactive"
  else
    capture_state="OFF inactive"
  fi

  if [ -n "$promote_pid" ] && [ "$promote_pid" != "-" ] && is_pid_alive "$promote_pid"; then
    promote_state="OK running"
  else
    promote_state="OFF inactive"
    promote_pid="-"
  fi

  if [ "$final_count" -gt 0 ]; then
    ipset_state="PRESENT populated"
  else
    ipset_state="EMPTY no final IPs"
  fi

  if [ "${1:-}" = compact ]; then
    printf '  Engine: %-24s Capture: %s\n' "$engine_state" "$capture_state"
    printf '  Promotie: %-22s Lijst: %s\n' "$promote_state" "$IPSET_NAME"
    printf '  IPs: %s definitief | %s kandidaat | %s wachtend\n' "$final_count" "$(ipset_member_count "$CAND_SET")" "$(ipset_member_count "$WAIT_SET")"
    printf '  LAN: %s | Controle: %ss | Bijgewerkt: %s\n' "$INTERFACES" "$STREAM_SCAN_EVERY" "$now"
    return
  fi
  say "Service"
  printf '  %-20s %s\n' 'Deferred IPs' "$(ipset_member_count "$WAIT_SET")"
  printf "  %-20s %s
" "Last refresh" "$now"
  printf "  %-20s %s
" "Engine" "$engine_state"
  printf "  %-20s %s
" "Engine PID" "$engine_pid"
  printf "  %-20s %s
" "Promote loop" "$promote_state"
  printf "  %-20s %s
" "Promote PID" "$promote_pid"
  printf "  %-20s %s
" "Capture" "$capture_state"
  printf "  %-20s %s
" "Final IPSet" "$ipset_state"

  say
  say "Config"
  printf "  %-20s %s
" "Interfaces" "$INTERFACES"
  printf "  %-20s %s
" "Ports" "$PORTS"
  printf "  %-20s %s
" "Promote mode" "$PROMOTE_MODE"
  printf "  %-20s %s
" "IPSet" "$IPSET_NAME"
  printf "  %-20s %s
" "External DNS" "$ALLOW_EXTERNAL_DNS"
  printf "  %-20s %s
" "Generic scan" "$CAPTURE_GENERIC_HOSTNAMES"
  printf "  %-20s %s
" "Stream flow scan" "$STREAM_FLOW_SCAN"
  printf "  %-20s %s
" "Source IPs" "${SOURCE_IPS:-alle apparaten (LAN + Wi-Fi) - meer ruis}"
  printf "  %-20s %s bytes
" "Stream min bytes" "$STREAM_MIN_BYTES"
  printf "  %-20s %s
" "User exclude IPs" "${EXCLUDE_IPS:-none}"
  printf "  %-20s %s
" "Exclude nets" "${EXCLUDE_NETS:-none}"
  printf "  %-20s %s
" "Exclude net set" "${EXCLUDE_NET_SET:-none}"
  printf "  %-20s %s
" "Exclude resolver" "$EXCLUDE_RESOLVE_CACHE ($( [ -f "$CACHE_EXCLUDE_IPS" ] && wc -l < "$CACHE_EXCLUDE_IPS" 2>/dev/null || echo 0 ) cached IPs)"

  say
  say "Timers"
  printf "  %-20s %s (%s)
" "Promote check" "${PROMOTE_EVERY}s" "$(human_duration "$PROMOTE_EVERY")"
  printf "  %-20s %s (%s)
" "Flow scan" "${STREAM_SCAN_EVERY}s" "$(human_duration "$STREAM_SCAN_EVERY")"
  printf "  %-20s %s (%s)
" "Min age" "${MIN_AGE}s" "$(human_duration "$MIN_AGE")"
  printf "  %-20s %s (%s)
" "Candidate TTL" "${CANDIDATE_TIMEOUT}s" "$(human_duration "$CANDIDATE_TIMEOUT")"
  printf "  %-20s %s (%s)
" "Final TTL" "${FINAL_TIMEOUT}s" "$(human_duration "$FINAL_TIMEOUT")"

  say
  say "Activity"
  printf "  %-20s %s
" "Candidate IPs" "$cand_count"
  printf "  %-20s %s
" "Final IPs" "$final_count"
  printf "  %-20s %s
" "Log file" "$LOGFILE"
}

start_service(){
  if [ "${VPNIPC_INTERNAL:-0}" != 1 ]; then
    /jffs/scripts/vpn_ipcatcher.sh start
    return $?
  fi
  load_config || return 1
  cleanup_stale_state

  if is_running; then
    say "vpn_ipcatcher draait al (pid $(cat "$ENGINE_PIDFILE" 2>/dev/null))."
    return 0
  fi

  mkdir -p "$PIDDIR" "$CACHE_DIR"
  hard_stop_all_instances
  rm -f "$LOCK" "$ENGINE_PIDFILE" "$PROMOTE_PIDFILE" "$CAP_PIDFILE" "$STATUS_FILE" "$WEB_STATUS_FILE"

  nohup "$0" run >/dev/null 2>&1 &
  sleep 2

  if is_running; then
    say "vpn_ipcatcher gestart (pid $(cat "$ENGINE_PIDFILE" 2>/dev/null))."
  else
    say "Start mislukt. Bekijk $LOGFILE"
    return 1
  fi
}

stop_service(){
  if [ "${VPNIPC_INTERNAL:-0}" != 1 ]; then
    /jffs/scripts/vpn_ipcatcher.sh stop
    return $?
  fi
  hard_stop_all_instances
  sleep 1

  pid=""
  [ -f "$ENGINE_PIDFILE" ] && pid="$(cat "$ENGINE_PIDFILE" 2>/dev/null)"
  [ -z "$pid" ] && [ -f "$LOCK" ] && pid="$(cat "$LOCK" 2>/dev/null)"

  if [ -n "$pid" ] && is_pid_alive "$pid"; then
    kill "$pid" 2>/dev/null
    sleep 2
    if is_pid_alive "$pid"; then
      say "Proces leeft nog, stuur SIGKILL naar $pid"
      kill -9 "$pid" 2>/dev/null
      sleep 1
    fi
  fi

  kill_pid_list "$PROMOTE_PIDFILE"
  kill_pid_list "$CAP_PIDFILE"
  sleep 1
  kill_pid_list "$PROMOTE_PIDFILE"
  kill_pid_list "$CAP_PIDFILE"
  hard_stop_all_instances

  rm -f "$LOCK" "$ENGINE_PIDFILE" "$PROMOTE_PIDFILE" "$CAP_PIDFILE" "$STATUS_FILE" "$WEB_STATUS_FILE"
  say "vpn_ipcatcher gestopt."
}

restart_service(){
  if [ "${VPNIPC_INTERNAL:-0}" != 1 ]; then
    /jffs/scripts/vpn_ipcatcher.sh restart
    return $?
  fi
  stop_service
  start_service
}

show_log(){
  [ -f "$LOGFILE" ] || { say "Nog geen logbestand: $LOGFILE"; return 0; }
  ${TAIL:-tail} -n 80 "$LOGFILE"
}

live_log(){
  [ -f "$LOGFILE" ] || : > "$LOGFILE"

  # Geen Ctrl+C nodig: binnen amtm kan Ctrl+C soms de hele parent-shell raken.
  while true; do
    soft_clear
    say "============================================================"
    say " vpn_ipcatcher live log"
    say "============================================================"
    say "Laatste refresh : $(date '+%F %T')"
    say "Logbestand      : $LOGFILE"
    say "Gebruik         : druk op q + Enter om terug te gaan naar het menu"
    say "------------------------------------------------------------"
    ${TAIL:-tail} -n 25 "$LOGFILE" 2>/dev/null
    say "------------------------------------------------------------"
    printf "q + Enter = terug | Enter = verversen: "
    read -t 2 -r key 2>/dev/null || key=""
    case "$key" in q|Q) return 0 ;; esac
  done
}

show_config(){
  ensure_config
  ${CAT:-cat} "$CONF"
}

edit_config(){
  ensure_config
  if [ -n "$VI" ]; then
    "$VI" "$CONF"
    schedule_webui_publish
  else
    say "Geen editor gevonden. Bewerk handmatig: $CONF"
  fi
}

config_get_value_raw(){
  key="$1"
  ensure_config
  # Read simple KEY="value" lines without executing user input.
  $SED -n "s#^${key}=\"\(.*\)\"#\1#p; s#^${key}=\([^\"].*\)#\1#p" "$CONF" | $TAIL -n 1
}

set_config_value(){
  key="$1"; value="$2"
  case "$key" in ''|*[!A-Z_0-9]*) return 1 ;; esac
  case "$value" in *[!A-Za-z0-9.,:/_\ -]*) say "Ongeldige configuratiewaarde"; return 1 ;; esac
  ensure_config
  config_write_lock || { say "Config is tijdelijk vergrendeld; probeer opnieuw."; return 1; }
  oldval="$(config_get_value_raw "$key")"
  tmp="${CONF}.$$"
  $AWK -v key="$key" -v value="$value" '
    index($0,key "=")==1 {if(!seen++) print key "=\"" value "\""; next}
    {print}
    END {if(!seen) print key "=\"" value "\""}
  ' "$CONF" > "$tmp" || { rm -f "$tmp"; config_write_unlock; return 1; }
  mv "$tmp" "$CONF" || { rm -f "$tmp"; config_write_unlock; return 1; }
  chmod 600 "$CONF" 2>/dev/null
  config_write_unlock
  if [ "$oldval" != "$value" ]; then
    CONFIG_CHANGED=1
    schedule_webui_publish
  fi
}

normalize_words(){
  echo "$*" | $TR ',;' '  ' | $AWK '{for(i=1;i<=NF;i++) if($i!="") print $i}'
}

config_get_value(){
  key="$1"
  load_config
  eval "printf '%s' \"\${$key}\""
}

maybe_restart_after_config_change(){
  [ "${SUPPRESS_RESTART_PROMPT:-0}" = "1" ] && return 0
  if is_running; then
    say
    say "Let op: config-wijzigingen worden actief na een herstart van de catcher-engine."
    say "Dit is dus géén router-reboot, alleen deze vpn_ipcatcher service/tool."
    printf "Catcher nu herstarten? (j/N): "
    read -r ans
    case "$ans" in
      j|J|y|Y|yes|YES) restart_service; CONFIG_CHANGED=0 ;;
      *) say "Niet herstart. Gebruik later: Restart service." ;;
    esac
  fi
}

maybe_restart_once_after_batch(){
  [ "${CONFIG_CHANGED:-0}" = "1" ] || return 0
  maybe_restart_after_config_change
}

add_items_to_config_list(){
  key="$1"; item_type="$2"; items_raw="$3"
  current="$(config_get_value "$key")"
  new="$current"
  added=0
  skipped=0

  for item in $(normalize_words "$items_raw"); do
    case "$item_type" in
      ip) valid_ipv4 "$item" || { say "Ongeldig IP overgeslagen: $item"; skipped=$((skipped+1)); continue; } ;;
      net) valid_cidr "$item" || { say "Ongeldige range overgeslagen: $item"; skipped=$((skipped+1)); continue; } ;;
      *) item="$(safe_domain "$item")"; [ -n "$item" ] || { skipped=$((skipped+1)); continue; } ;;
    esac

    found=0
    for existing in $new; do [ "$existing" = "$item" ] && found=1; done
    if [ "$found" = "1" ]; then
      say "Bestaat al: $item"
      skipped=$((skipped+1))
    else
      new="$(echo "$new $item" | $AWK '{for(i=1;i<=NF;i++) if(!seen[$i]++) printf (out++?" ":"") $i; print ""}')"
      say "Toegevoegd: $item"
      added=$((added+1))
    fi
  done

  [ "$added" -gt 0 ] && set_config_value "$key" "$new"
  say "Klaar. Toegevoegd: $added, overgeslagen: $skipped"
  [ "$added" -gt 0 ] && maybe_restart_after_config_change
}

remove_items_from_config_list(){
  key="$1"; item_type="$2"; items_raw="$3"
  current="$(config_get_value "$key")"
  remove_list=""
  for item in $(normalize_words "$items_raw"); do
    case "$item_type" in
      domain) item="$(safe_domain "$item")" ;;
      ip) valid_ipv4 "$item" || item="" ;;
      net) valid_cidr "$item" || item="" ;;
    esac
    [ -n "$item" ] && remove_list="$remove_list $item"
  done

  new=""
  removed=0
  for existing in $current; do
    drop=0
    for r in $remove_list; do [ "$existing" = "$r" ] && drop=1; done
    if [ "$drop" = "1" ]; then
      say "Verwijderd: $existing"
      removed=$((removed+1))
    else
      new="$new $existing"
    fi
  done
  new="$(echo "$new" | $AWK '{for(i=1;i<=NF;i++) if(!seen[$i]++) printf (out++?" ":"") $i; print ""}')"
  [ "$removed" -gt 0 ] && set_config_value "$key" "$new"
  say "Klaar. Verwijderd: $removed"
  [ "$removed" -gt 0 ] && maybe_restart_after_config_change
}

manage_domain_exclusions(){
  while true; do
    soft_clear
    load_config
    say "============================================================"
    say " Exclude domains beheren"
    say "============================================================"
    say "Huidige domeinen: ${EXCLUDE_DOMAINS:-none}"
    say
    say " 1) Domein(en) toevoegen"
    say " 2) Domein(en) verwijderen"
    say " 3) Domeinlijst volledig vervangen"
    say " 4) Domeinlijst leegmaken"
    say " 5) Terug"
    printf "Choose: "
    read -r choice
    case "$choice" in
      1)
        say "Voer domeinen in, gescheiden met spaties of komma's."
        printf "Toevoegen: "; read -r v
        [ -n "$v" ] && add_items_to_config_list "EXCLUDE_DOMAINS" "domain" "$v"
        press_enter ;;
      2)
        say "Voer exacte domeinen in die je wilt verwijderen."
        printf "Verwijderen: "; read -r v
        [ -n "$v" ] && remove_items_from_config_list "EXCLUDE_DOMAINS" "domain" "$v"
        press_enter ;;
      3)
        say "Nieuwe volledige domeinlijst, gescheiden met spaties."
        printf "EXCLUDE_DOMAINS= "; read -r v
        cleaned=""
        for d in $(normalize_words "$v"); do d="$(safe_domain "$d")"; [ -n "$d" ] && cleaned="$cleaned $d"; done
        cleaned="$(echo "$cleaned" | $AWK '{for(i=1;i<=NF;i++) if(!seen[$i]++) printf (out++?" ":"") $i; print ""}')"
        set_config_value "EXCLUDE_DOMAINS" "$cleaned"
        say "Domeinlijst vervangen."
        maybe_restart_after_config_change
        press_enter ;;
      4)
        printf "Weet je zeker dat je EXCLUDE_DOMAINS leeg wilt maken? (j/N): "; read -r ans
        case "$ans" in j|J|y|Y) set_config_value "EXCLUDE_DOMAINS" ""; say "Domeinlijst leeggemaakt."; maybe_restart_after_config_change ;; esac
        press_enter ;;
      5|q|Q) return 0 ;;
      *) say "Ongeldige keuze."; press_enter ;;
    esac
  done
}

manage_ip_exclusions(){
  while true; do
    soft_clear
    load_config
    say "============================================================"
    say " Exclude IPs beheren"
    say "============================================================"
    say "Eigen EXCLUDE_IPS : ${EXCLUDE_IPS:-none}"
    say "Protected IPs    : $SYSTEM_EXCLUDE_IPS"
    say
    say " 1) IP(s) toevoegen"
    say " 2) IP(s) verwijderen"
    say " 3) Eigen IP-lijst volledig vervangen"
    say " 4) Eigen IP-lijst leegmaken"
    say " 5) Verwijder uitgesloten IPs uit ipsets"
    say " 6) Terug"
    printf "Choose: "
    read -r choice
    case "$choice" in
      1)
        say "Voer IP's in, gescheiden met spaties of komma's."
        printf "Toevoegen: "; read -r v
        [ -n "$v" ] && add_items_to_config_list "EXCLUDE_IPS" "ip" "$v"
        press_enter ;;
      2)
        say "Voer exacte IP's in die je wilt verwijderen."
        printf "Verwijderen: "; read -r v
        [ -n "$v" ] && remove_items_from_config_list "EXCLUDE_IPS" "ip" "$v"
        press_enter ;;
      3)
        say "Nieuwe volledige IP-lijst, gescheiden met spaties. Ongeldige IP's worden overgeslagen."
        printf "EXCLUDE_IPS= "; read -r v
        cleaned=""
        for ip in $(normalize_words "$v"); do valid_ipv4 "$ip" && cleaned="$cleaned $ip" || say "Ongeldig IP overgeslagen: $ip"; done
        cleaned="$(echo "$cleaned" | $AWK '{for(i=1;i<=NF;i++) if(!seen[$i]++) printf (out++?" ":"") $i; print ""}')"
        set_config_value "EXCLUDE_IPS" "$cleaned"
        say "Eigen IP-lijst vervangen."
        maybe_restart_after_config_change
        press_enter ;;
      4)
        printf "Weet je zeker dat je EXCLUDE_IPS leeg wilt maken? (j/N): "; read -r ans
        case "$ans" in j|J|y|Y) set_config_value "EXCLUDE_IPS" ""; say "Eigen IP-lijst leeggemaakt."; maybe_restart_after_config_change ;; esac
        press_enter ;;
      5) ipset_remove_excluded; press_enter ;;
      6|q|Q) return 0 ;;
      *) say "Ongeldige keuze."; press_enter ;;
    esac
  done
}

# Preset-database. Alles gaat via EXCLUDE_DOMAINS / EXCLUDE_IPS in de config.
# Dus: toevoegen = in config erbij, verwijderen = uit config eruit.
preset_domains(){
  case "$1" in
    dns_cloudflare) echo "one.one.one.one cloudflare-dns.com" ;;
    dns_quad9) echo "quad9.net" ;;
    dns_google) echo "dns.google" ;;
    dns_opendns) echo "opendns.com" ;;

    dev_github) echo "github.com api.github.com githubusercontent.com githubassets.com github.io raw.githubusercontent.com objects.githubusercontent.com" ;;

    social_meta) echo "facebook.com www.facebook.com graph.facebook.com fbcdn.net fbsbx.com mqtt-mini.facebook.com edge-mqtt.facebook.com gateway.facebook.com" ;;
    social_whatsapp) echo "whatsapp.com web.whatsapp.com static.whatsapp.net mmg.whatsapp.net media.whatsapp.net" ;;
    social_instagram) echo "instagram.com www.instagram.com cdninstagram.com i.instagram.com" ;;
    social_snapchat) echo "snapchat.com app.snapchat.com sc-analytics.appspot.com feelinsonice.appspot.com" ;;

    cam_eufy) echo "eufylife.com security-app.eufylife.com eufy.com anker.com anker-in.com" ;;
    cam_dahua_imou) echo "imoulife.com easy4ip.com lechange.com dahuasecurity.com dahuatech.com dahuap2p.com" ;;

    game_steam) echo "steamcontent.com steampowered.com steamstatic.com steamserver.net" ;;
    game_epic) echo "epicgames.com epicgamescdn.com unrealengine.com" ;;
    game_xbox) echo "xboxlive.com xboxservices.com xbox.com xsts.auth.xboxlive.com" ;;
    game_playstation) echo "playstation.net playstation.com sonyentertainmentnetwork.com" ;;
    game_nintendo) echo "nintendo.net nintendo.com nintendo-europe.com" ;;
    game_battlenet) echo "battle.net blizzard.com blzstatic.com blizzardgearstore.com" ;;

    upd_windows) echo "windowsupdate.com update.microsoft.com delivery.mp.microsoft.com download.windowsupdate.com wustat.windows.com" ;;
    upd_msstore) echo "storeedgefd.dsx.mp.microsoft.com dl.delivery.mp.microsoft.com displaycatalog.mp.microsoft.com" ;;
    upd_office) echo "officecdn.microsoft.com office.com office365.com microsoft.com msedge.net azureedge.net" ;;
    upd_apple) echo "apple.com icloud.com mzstatic.com aaplimg.com apple-dns.net appldnld.apple.com swcdn.apple.com" ;;
    upd_google) echo "googleapis.com gvt1.com gvt2.com android.clients.google.com play.googleapis.com" ;;

    tv_samsung) echo "samsungcloudsolution.net samsungcloudsolution.com samsungacr.com samsung.com" ;;
    tv_philips) echo "philips.com tpv-tech.com philips-tvconsumercare.com" ;;
    tv_android) echo "androidtv.com android.com gstatic.com googleapis.com" ;;
    tv_lg) echo "lge.com lgsmartad.com lgtvcommon.com" ;;

    stream_netflix) echo "netflix.com nflxvideo.net nflxso.net nflxext.com nflximg.net" ;;
    stream_youtube) echo "youtube.com googlevideo.com ytimg.com youtubei.googleapis.com" ;;
    stream_disney) echo "disneyplus.com disney-plus.net dssott.com bamgrid.com" ;;
    stream_prime) echo "primevideo.com amazonvideo.com aiv-cdn.net media-amazon.com" ;;
    stream_videoland) echo "videoland.com rtl.nl" ;;
    stream_viaplay) echo "viaplay.com viaplaycontent.com" ;;
  esac
}

preset_ips(){
  case "$1" in
    dns_cloudflare) echo "1.1.1.1 1.0.0.1" ;;
    dns_quad9) echo "9.9.9.9 149.112.112.112" ;;
    dns_google) echo "8.8.8.8 8.8.4.4" ;;
    dns_opendns) echo "208.67.222.222 208.67.220.220" ;;
    *) echo "" ;;
  esac
}

preset_label(){
  case "$1" in
    dns_cloudflare) echo "Cloudflare DNS" ;;
    dns_quad9) echo "Quad9 DNS" ;;
    dns_google) echo "Google DNS" ;;
    dns_opendns) echo "OpenDNS" ;;
    dev_github) echo "GitHub" ;;
    social_meta) echo "Meta / Facebook" ;;
    social_whatsapp) echo "WhatsApp" ;;
    social_instagram) echo "Instagram" ;;
    social_snapchat) echo "Snapchat" ;;
    cam_eufy) echo "Eufy / Anker Security" ;;
    cam_dahua_imou) echo "Dahua / Imou / Easy4IP" ;;
    game_steam) echo "Steam" ;;
    game_epic) echo "Epic Games" ;;
    game_xbox) echo "Xbox / Game Pass" ;;
    game_playstation) echo "PlayStation" ;;
    game_nintendo) echo "Nintendo" ;;
    game_battlenet) echo "Battle.net / Blizzard" ;;
    upd_windows) echo "Windows Update" ;;
    upd_msstore) echo "Microsoft Store" ;;
    upd_office) echo "Office / Microsoft CDN" ;;
    upd_apple) echo "Apple / iCloud updates" ;;
    upd_google) echo "Google / Android updates" ;;
    tv_samsung) echo "Samsung Smart TV telemetry" ;;
    tv_philips) echo "Philips Smart TV telemetry" ;;
    tv_android) echo "Android TV telemetry" ;;
    tv_lg) echo "LG Smart TV telemetry" ;;
    stream_netflix) echo "Netflix" ;;
    stream_youtube) echo "YouTube" ;;
    stream_disney) echo "Disney+" ;;
    stream_prime) echo "Prime Video" ;;
    stream_videoland) echo "Videoland" ;;
    stream_viaplay) echo "Viaplay" ;;
    *) echo "$1" ;;
  esac

}

# Shared registry overrides the embedded fallback database above.
[ -f "$PRESET_LIB" ] && . "$PRESET_LIB"
type preset_nets >/dev/null 2>&1 || preset_nets(){ echo ""; }
type preset_keys_for_category >/dev/null 2>&1 || preset_keys_for_category(){ echo ""; }
type preset_category_note >/dev/null 2>&1 || preset_category_note(){ echo ""; }

preset_is_active(){
  key="$1"
  doms="$(preset_domains "$key")"
  ips="$(preset_ips "$key")"
  nets="$(preset_nets "$key")"
  any=0
  all=1
  domain_haystack=" $EXCLUDE_DOMAINS "
  ip_haystack=" $EXCLUDE_IPS $SYSTEM_EXCLUDE_IPS "
  net_haystack=" $EXCLUDE_NETS "
  for d in $doms; do
    case "$domain_haystack" in *" $d "*) any=1 ;; *) all=0 ;; esac
  done
  for ip in $ips; do
    case "$ip_haystack" in *" $ip "*) any=1 ;; *) all=0 ;; esac
  done
  for net in $nets; do
    case "$net_haystack" in *" $net "*) any=1 ;; *) all=0 ;; esac
  done
  [ -z "$doms$ips$nets" ] && { echo "-"; return; }
  [ "$all" = "1" ] && { echo "ON"; return; }
  [ "$any" = "1" ] && { echo "PART"; return; }
  echo "off"
}

apply_preset(){
  key="$1"; action="$2"
  label="$(preset_label "$key")"
  doms="$(preset_domains "$key")"
  ips="$(preset_ips "$key")"
  nets="$(preset_nets "$key")"
  say "Preset: $label"
  [ -n "$doms" ] && say "Domeinen: $doms"
  [ -n "$ips" ] && say "IPs     : $ips"
  [ -n "$nets" ] && say "Ranges  : $nets"
  case "$action" in
    add)
      [ -n "$doms" ] && add_items_to_config_list "EXCLUDE_DOMAINS" "domain" "$doms"
      [ -n "$ips" ] && add_items_to_config_list "EXCLUDE_IPS" "ip" "$ips"
      [ -n "$nets" ] && add_items_to_config_list "EXCLUDE_NETS" "net" "$nets"
      ;;
    remove)
      [ -n "$doms" ] && remove_items_from_config_list "EXCLUDE_DOMAINS" "domain" "$doms"
      [ -n "$ips" ] && remove_items_from_config_list "EXCLUDE_IPS" "ip" "$ips"
      [ -n "$nets" ] && remove_items_from_config_list "EXCLUDE_NETS" "net" "$nets"
      ;;
  esac
}

apply_preset_silent(){
  key="$1"; action="$2"
  old_suppress="$SUPPRESS_RESTART_PROMPT"
  SUPPRESS_RESTART_PROMPT=1
  apply_preset "$key" "$action"
  SUPPRESS_RESTART_PROMPT="$old_suppress"
}

repair_safe_excludes(){
  load_config
  say "Repair: EXCLUDE_DOMAINS en EXCLUDE_NETS worden vervangen door een schone veilige basislijst."
  set_config_value "EXCLUDE_DOMAINS" "$DEFAULT_EXCLUDE_DOMAINS"
  set_config_value "EXCLUDE_NETS" "$DEFAULT_EXCLUDE_NETS"
  rm -f "$CACHE_EXCLUDE_IPS" "$CACHE_EXCLUDE_TS" 2>/dev/null
  refresh_exclusion_ip_cache force
  ipset_remove_excluded
  maybe_restart_after_config_change
}

apply_recommended_safe_excludes(){
  load_config
  CONFIG_CHANGED=0
  old_suppress="$SUPPRESS_RESTART_PROMPT"
  SUPPRESS_RESTART_PROMPT=1

  # Basis die je meestal NIET via de streaming-VPN-ipset wilt laten leren.
  set_config_value "EXCLUDE_NETS" "$DEFAULT_EXCLUDE_NETS"
  for key in dns_cloudflare dns_quad9 dns_google dns_opendns dev_github social_meta social_whatsapp social_instagram social_snapchat cam_eufy cam_dahua_imou; do
    apply_preset "$key" add
  done

  SUPPRESS_RESTART_PROMPT="$old_suppress"
  refresh_exclusion_ip_cache force
  ipset_remove_excluded
  maybe_restart_once_after_batch
}

category_state(){
  keys="$1"
  any=0
  all=1
  for key in $keys; do
    st="$(preset_is_active "$key")"
    case "$st" in
      ON) any=1 ;;
      PART) any=1; all=0 ;;
      off) all=0 ;;
      *) all=0 ;;
    esac
  done
  [ "$all" = "1" ] && { echo "ON"; return; }
  [ "$any" = "1" ] && { echo "PART"; return; }
  echo "off"
}

preset_category_menu(){
  title="$1"; keys="$2"; note="$3"
  while true; do
    soft_clear
    load_config
    say "============================================================"
    say " Exclusion presets - $title"
    say "============================================================"
    [ -n "$note" ] && say "$note" && say "------------------------------------------------------------"
    say "Status: ON = volledig uitgesloten, PART = deels, off = niet actief"
    say "Tip: voer meerdere nummers in, bijv. 1 2 5. Daarna krijg je maar één restart-vraag."
    say "------------------------------------------------------------"
    i=1
    for key in $keys; do
      eval "k$i='$key'"
      printf " %2s) [%-4s] %-34s\n" "$i" "$(preset_is_active "$key")" "$(preset_label "$key")"
      i=$((i+1))
    done
    say "------------------------------------------------------------"
    say "  a) Alles toevoegen      r) Alles verwijderen"
    say "  v) Toon details         q) Terug"
    printf "Keuze(s): "
    read -r choice
    case "$choice" in
      q|Q) return 0 ;;
      v|V)
        say
        for key in $keys; do
          say "$(preset_label "$key") [$(preset_is_active "$key")]"
          d="$(preset_domains "$key")"; [ -n "$d" ] && say "  Domeinen: $d"
          ip="$(preset_ips "$key")"; [ -n "$ip" ] && say "  IPs     : $ip"
          net="$(preset_nets "$key")"; [ -n "$net" ] && say "  Ranges  : $net"
        done
        press_enter ;;
      a|A)
        CONFIG_CHANGED=0
        old_suppress="$SUPPRESS_RESTART_PROMPT"; SUPPRESS_RESTART_PROMPT=1
        for key in $keys; do apply_preset "$key" add; done
        SUPPRESS_RESTART_PROMPT="$old_suppress"
        maybe_restart_once_after_batch
        press_enter ;;
      r|R)
        CONFIG_CHANGED=0
        old_suppress="$SUPPRESS_RESTART_PROMPT"; SUPPRESS_RESTART_PROMPT=1
        for key in $keys; do apply_preset "$key" remove; done
        SUPPRESS_RESTART_PROMPT="$old_suppress"
        maybe_restart_once_after_batch
        press_enter ;;
      *)
        CONFIG_CHANGED=0
        old_suppress="$SUPPRESS_RESTART_PROMPT"; SUPPRESS_RESTART_PROMPT=1
        did=0
        for n in $(normalize_words "$choice"); do
          case "$n" in
            ''|*[!0-9]*) say "Ongeldige keuze overgeslagen: $n"; continue ;;
          esac
          eval "sel=\${k$n}"
          if [ -n "$sel" ]; then
            st="$(preset_is_active "$sel")"
            # Toggle: ON/PART = verwijderen, off = toevoegen.
            case "$st" in
              ON|PART) say "Toggle uit: $(preset_label "$sel")"; apply_preset "$sel" remove ;;
              *)       say "Toggle aan:  $(preset_label "$sel")"; apply_preset "$sel" add ;;
            esac
            did=1
          else
            say "Ongeldige keuze overgeslagen: $n"
          fi
        done
        SUPPRESS_RESTART_PROMPT="$old_suppress"
        [ "$did" = "1" ] && maybe_restart_once_after_batch
        press_enter ;;
    esac
  done
}

show_all_exclusions(){
  load_config
  say "============================================================"
  say " Alle exclusions"
  say "============================================================"
  say "Vaste protected IPs  : $SYSTEM_EXCLUDE_IPS"
  say "Eigen exclude IPs    : ${EXCLUDE_IPS:-none}"
  say "Exclude domains      : ${EXCLUDE_DOMAINS:-none}"
  say "Exclude nets         : ${EXCLUDE_NETS:-none}"
  say "Exclude net ipset    : ${EXCLUDE_NET_SET:-none}"
  say "Resolved cache       : ${CACHE_EXCLUDE_IPS}"
  if [ -f "$CACHE_EXCLUDE_IPS" ]; then
    say "Resolved cache IPs   : $(wc -l < "$CACHE_EXCLUDE_IPS" 2>/dev/null)"
    say "Cache age            : $(human_duration "$(cache_age_seconds)")"
  else
    say "Resolved cache IPs   : none"
  fi
  say
  say "Let op: protected IPs zijn hard geblokkeerd in de tool en mogen nooit naar ipset."
}

show_resolved_exclusion_cache(){
  load_config
  say "============================================================"
  say " Resolved exclude-cache"
  say "============================================================"
  say "Bestand : $CACHE_EXCLUDE_IPS"
  say "Status  : $EXCLUDE_RESOLVE_CACHE | refresh elke $(human_duration "$EXCLUDE_RESOLVE_EVERY")"
  [ -f "$CACHE_EXCLUDE_IPS" ] && say "Leeftijd: $(human_duration "$(cache_age_seconds)")"
  say "------------------------------------------------------------"
  if [ -s "$CACHE_EXCLUDE_IPS" ]; then
    $AWK '{printf "%-16s %s\n", $1, $2}' "$CACHE_EXCLUDE_IPS" | ${HEAD:-head} -n 200
  else
    say "Cache is leeg. Kies 'cache verversen' of voeg domein-exclusions toe."
  fi
}

exclusion_resolver_settings(){
  while true; do
    soft_clear
    load_config
    say "============================================================"
    say " Exclusion resolver instellingen"
    say "============================================================"
    say "Deze resolver zet EXCLUDE_DOMAINS tijdelijk om naar IP-exclusions."
    say "Belangrijk voor conntrack-first, omdat conntrack meestal alleen dst-IP ziet."
    say "------------------------------------------------------------"
    say " 1) Exclusion resolver aan/uit      [$EXCLUDE_RESOLVE_CACHE]"
    say " 2) Cache refresh interval          [$EXCLUDE_RESOLVE_EVERY sec = $(human_duration "$EXCLUDE_RESOLVE_EVERY")]"
    say " 3) Reverse DNS check aan/uit       [$REVERSE_DNS_CHECK]"
    say " 4) Cache nu verversen"
    say " 5) Cache bekijken"
    say " 6) Terug"
    printf "Choose: "
    read -r c
    case "$c" in
      1) printf "Waarde (yes/no) [$EXCLUDE_RESOLVE_CACHE]: "; read -r v; [ -n "$v" ] && case "$v" in yes|no) set_config_value "EXCLUDE_RESOLVE_CACHE" "$v"; maybe_restart_after_config_change ;; *) say "Ongeldig"; press_enter ;; esac ;;
      2) printf "Seconden [$EXCLUDE_RESOLVE_EVERY]: "; read -r v; [ -n "$v" ] && case "$v" in *[!0-9]*|'') say "Ongeldig"; press_enter ;; *) set_config_value "EXCLUDE_RESOLVE_EVERY" "$v"; maybe_restart_after_config_change ;; esac ;;
      3) say "Reverse DNS is handig als een IP een bruikbare PTR-naam heeft, maar is niet waterdicht en kan iets trager zijn."; printf "Waarde (yes/no) [$REVERSE_DNS_CHECK]: "; read -r v; [ -n "$v" ] && case "$v" in yes|no) set_config_value "REVERSE_DNS_CHECK" "$v"; maybe_restart_after_config_change ;; *) say "Ongeldig"; press_enter ;; esac ;;
      4) refresh_exclusion_ip_cache force; show_resolved_exclusion_cache; press_enter ;;
      5) show_resolved_exclusion_cache; press_enter ;;
      6|q|Q) return 0 ;;
      *) say "Ongeldige keuze."; press_enter ;;
    esac
  done
}

preset_exclusion_menu(){
  while true; do
    soft_clear
    load_config
    say "============================================================"
    say " Exclusion manager"
    say "============================================================"
    say "Hier beheer je wat NIET automatisch naar candidate/final mag."
    say "De tool past EXCLUDE_DOMAINS en EXCLUDE_IPS in $CONF aan."
    say "Streamingdiensten alleen uitsluiten als die juist NIET via de VPN-regel mogen."
    say "------------------------------------------------------------"
    dns_keys="$(preset_keys_for_category "DNS providers")"; [ -n "$dns_keys" ] || dns_keys="dns_cloudflare dns_quad9 dns_google dns_opendns"
    social_keys="$(preset_keys_for_category "Social / messaging")"; [ -n "$social_keys" ] || social_keys="social_meta social_whatsapp social_instagram social_snapchat"
    cam_keys="$(preset_keys_for_category "Security cameras / IoT cloud")"; [ -n "$cam_keys" ] || cam_keys="cam_eufy cam_dahua_imou"
    dev_keys="$(preset_keys_for_category "GitHub / dev CDN")"; [ -n "$dev_keys" ] || dev_keys="dev_github"
    game_keys="$(preset_keys_for_category "Games / downloads")"; [ -n "$game_keys" ] || game_keys="game_steam game_epic game_xbox game_playstation game_nintendo game_battlenet"
    upd_keys="$(preset_keys_for_category "OS / app updates")"; [ -n "$upd_keys" ] || upd_keys="upd_windows upd_msstore upd_office upd_apple upd_google"
    tv_keys="$(preset_keys_for_category "Smart TV telemetry")"; [ -n "$tv_keys" ] || tv_keys="tv_samsung tv_philips tv_android tv_lg"
    stream_keys="$(preset_keys_for_category "Streamingdiensten")"; [ -n "$stream_keys" ] || stream_keys="stream_netflix stream_youtube stream_disney stream_prime stream_videoland stream_viaplay"
    say " 1) Bekijk alles"
    say " 2) Veilige basis toevoegen       DNS + GitHub + Social + Camera clouds"
    printf " 3) DNS providers                 [%-4s]\n" "$(category_state "$dns_keys")"
    printf " 4) Social / messaging            [%-4s]\n" "$(category_state "$social_keys")"
    printf " 5) Security cameras / IoT cloud  [%-4s]\n" "$(category_state "$cam_keys")"
    printf " 6) GitHub / dev CDN              [%-4s]\n" "$(category_state "$dev_keys")"
    printf " 7) Games / downloads             [%-4s]\n" "$(category_state "$game_keys")"
    printf " 8) OS / app updates              [%-4s]\n" "$(category_state "$upd_keys")"
    printf " 9) Smart TV telemetry            [%-4s]\n" "$(category_state "$tv_keys")"
    printf "10) Streamingdiensten uitsluiten  [%-4s]\n" "$(category_state "$stream_keys")"
    say "11) Handmatig domeinen beheren"
    say "12) Handmatig IPs beheren"
    say "13) Resolved exclude-cache bekijken/verversen"
    say "14) Verwijder uitgesloten IPs uit ipsets"
    say "15) Terug"
    printf "Choose: "
    read -r choice
    case "$choice" in
      1) show_all_exclusions; press_enter ;;
      2) apply_recommended_safe_excludes; press_enter ;;
      3) preset_category_menu "DNS providers" "$dns_keys" "Advies: deze meestal uitsluiten, zodat DNS-resolvers nooit via VPN Director gaan." ;;
      4) preset_category_menu "Social / messaging" "$social_keys" "Aanrader als je alle apparaten monitort: voorkomt Meta/WhatsApp/Instagram/Snapchat bijvangst." ;;
      5) preset_category_menu "Security cameras / IoT cloud" "$cam_keys" "Aanrader voor Eufy, Dahua en Imou Life camera/cloud-verkeer." ;;
      6) preset_category_menu "GitHub / dev CDN" "$dev_keys" "Voorkomt dat GitHub/CDN-verkeer van laptops onbedoeld via de VPN-ipset gaat." ;;
      7) preset_category_menu "Games / downloads" "$game_keys" "Handig om grote downloads niet per ongeluk als stream te leren." ;;
      8) preset_category_menu "OS / app updates" "$upd_keys" "Kies per platform. Apple hoeft dus niet aan als je dat niet wilt." ;;
      9) preset_category_menu "Smart TV telemetry" "$tv_keys" "Dit vermindert achtergrondruis van smart-TV-platformen." ;;
      10) preset_category_menu "Streamingdiensten" "$stream_keys" "Alleen kiezen als deze diensten juist NIET via deze VPN mogen." ;;
      11) manage_domain_exclusions ;;
      12) manage_ip_exclusions ;;
      13) exclusion_resolver_settings ;;
      14) ipset_remove_excluded; press_enter ;;
      15|q|Q) return 0 ;;
      *) say "Ongeldige keuze."; press_enter ;;
    esac
  done
}

apply_profile(){
  profile="$1"
  case "$profile" in
    stable_tv)
      set_config_value "STREAM_FLOW_SCAN" "yes"
      set_config_value "STREAM_FLOW_TARGET" "final"
      set_config_value "STREAM_MIN_BYTES" "3000000"
      set_config_value "STREAM_SCAN_EVERY" "5"
      set_config_value "PROMOTE_MODE" "bytes"
      set_config_value "MIN_AGE" "30"
      set_config_value "MIN_BYTES" "3000000"
      set_config_value "CANDIDATE_TIMEOUT" "600"
      set_config_value "FINAL_TIMEOUT" "1800"
      set_config_value "CAPTURE_GENERIC_HOSTNAMES" "no"
      say "Profiel ingesteld: Stabiel TV-profiel"
      say "Direct naar final vanaf ca. 3 MB; final blijft 30 minuten."
      ;;
    cautious)
      set_config_value "STREAM_FLOW_SCAN" "yes"
      set_config_value "STREAM_FLOW_TARGET" "candidate"
      set_config_value "STREAM_MIN_BYTES" "25000000"
      set_config_value "STREAM_SCAN_EVERY" "10"
      set_config_value "PROMOTE_MODE" "bytes"
      set_config_value "MIN_AGE" "60"
      set_config_value "MIN_BYTES" "25000000"
      set_config_value "CANDIDATE_TIMEOUT" "600"
      set_config_value "FINAL_TIMEOUT" "86400"
      set_config_value "CAPTURE_GENERIC_HOSTNAMES" "no"
      say "Profiel ingesteld: Voorzichtig leren"
      say "Eerst candidate; final pas bij ca. 25 MB; final blijft 1 dag."
      ;;
    fast_zap)
      set_config_value "STREAM_FLOW_SCAN" "yes"
      set_config_value "STREAM_FLOW_TARGET" "final"
      set_config_value "STREAM_MIN_BYTES" "1000000"
      set_config_value "STREAM_SCAN_EVERY" "3"
      set_config_value "PROMOTE_MODE" "bytes"
      set_config_value "MIN_AGE" "15"
      set_config_value "MIN_BYTES" "1000000"
      set_config_value "CANDIDATE_TIMEOUT" "300"
      set_config_value "FINAL_TIMEOUT" "900"
      set_config_value "CAPTURE_GENERIC_HOSTNAMES" "no"
      say "Profiel ingesteld: Snel zappen"
      say "Direct naar final vanaf ca. 1 MB; final blijft 15 minuten. Meer kans op bijvangst."
      ;;
    analysis)
      set_config_value "STREAM_FLOW_SCAN" "yes"
      set_config_value "STREAM_FLOW_TARGET" "candidate"
      set_config_value "STREAM_MIN_BYTES" "1000000"
      set_config_value "STREAM_SCAN_EVERY" "5"
      set_config_value "PROMOTE_MODE" "bytes"
      set_config_value "MIN_AGE" "300"
      set_config_value "MIN_BYTES" "50000000"
      set_config_value "CANDIDATE_TIMEOUT" "1800"
      set_config_value "FINAL_TIMEOUT" "86400"
      set_config_value "CAPTURE_GENERIC_HOSTNAMES" "no"
      say "Profiel ingesteld: Analyse / review"
      say "Veel zichtbaar in candidate; promotie naar final is bewust streng."
      ;;
    freeze)
      set_config_value "STREAM_FLOW_SCAN" "no"
      set_config_value "CAPTURE_GENERIC_HOSTNAMES" "no"
      set_config_value "PROMOTE_MODE" "bytes"
      say "Profiel ingesteld: Alleen bestaande final-lijst gebruiken"
      say "Nieuw leren staat uit. Bestaande final ipset blijft werken tot timeout."
      ;;
  esac
  maybe_restart_after_config_change
}

profile_menu(){
  while true; do
    soft_clear
    load_config
    say "============================================================"
    say " Profielen"
    say "============================================================"
    say "Kies een startprofiel. Dit past meerdere configwaarden tegelijk aan."
    say "Huidig: scan=$STREAM_FLOW_SCAN target=$STREAM_FLOW_TARGET threshold=$STREAM_MIN_BYTES final=$(human_duration "$FINAL_TIMEOUT") generic=$CAPTURE_GENERIC_HOSTNAMES"
    say "------------------------------------------------------------"
    say " 1) Stabiel TV-profiel"
    say "    Direct naar final vanaf ca. 3 MB, final 30 min. Aanrader voor TV-stabiliteit."
    say " 2) Voorzichtig leren"
    say "    Eerst candidate, pas final bij ca. 25 MB, final 1 dag. Minder rommel, trager."
    say " 3) Snel zappen"
    say "    Direct naar final vanaf ca. 1 MB, final 15 min. Snel, maar meer risico op bijvangst."
    say " 4) Analyse / review"
    say "    Eerst candidate, streng promoveren. Handig om te kijken wat hij ziet."
    say " 5) Alleen bestaande lijst gebruiken"
    say "    Nieuw leren uit. Handig als TV nu werkt en je geen risico wilt."
    say " 6) Terug"
    printf "Choose: "
    read -r choice
    case "$choice" in
      1) apply_profile stable_tv; press_enter ;;
      2) apply_profile cautious; press_enter ;;
      3) apply_profile fast_zap; press_enter ;;
      4) apply_profile analysis; press_enter ;;
      5) apply_profile freeze; press_enter ;;
      6|q|Q) return 0 ;;
      *) say "Ongeldige keuze."; press_enter ;;
    esac
  done
}

timeout_settings_menu(){
  while true; do
    soft_clear
    load_config
    say "============================================================"
    say " Timers / cleanup instellingen"
    say "============================================================"
    printf "  1) Promote check    : %s sec (%s)\n" "$PROMOTE_EVERY" "$(human_duration "$PROMOTE_EVERY")"
    printf "  2) Min age          : %s sec (%s)\n" "$MIN_AGE" "$(human_duration "$MIN_AGE")"
    printf "  3) Candidate timeout: %s sec (%s)\n" "$CANDIDATE_TIMEOUT" "$(human_duration "$CANDIDATE_TIMEOUT")"
    printf "  4) Final timeout    : %s sec (%s)\n" "$FINAL_TIMEOUT" "$(human_duration "$FINAL_TIMEOUT")"
    say "  5) Veilige testwaarden zetten: age, min_age 120, final 1 dag"
    say "  6) Terug"
    say "------------------------------------------------------------"
    say "Candidate timeout = hoe lang tijdelijke IPs blijven staan."
    say "Final timeout     = hoe lang VPN Director IPs blijven staan."
    printf "Choose: "
    read -r choice
    case "$choice" in
      1) printf "PROMOTE_EVERY seconden [$PROMOTE_EVERY]: "; read -r v; [ -n "$v" ] && set_config_value "PROMOTE_EVERY" "$v" && maybe_restart_after_config_change ;;
      2) printf "MIN_AGE seconden [$MIN_AGE]: "; read -r v; [ -n "$v" ] && set_config_value "MIN_AGE" "$v" && maybe_restart_after_config_change ;;
      3) printf "CANDIDATE_TIMEOUT seconden [$CANDIDATE_TIMEOUT]: "; read -r v; [ -n "$v" ] && set_config_value "CANDIDATE_TIMEOUT" "$v" && maybe_restart_after_config_change ;;
      4) printf "FINAL_TIMEOUT seconden [$FINAL_TIMEOUT]: "; read -r v; [ -n "$v" ] && set_config_value "FINAL_TIMEOUT" "$v" && maybe_restart_after_config_change ;;
      5)
        set_config_value "PROMOTE_MODE" "age"
        set_config_value "MIN_AGE" "120"
        set_config_value "CANDIDATE_TIMEOUT" "600"
        set_config_value "FINAL_TIMEOUT" "86400"
        say "Veilige testwaarden ingesteld."
        maybe_restart_after_config_change
        press_enter ;;
      6|q|Q) return 0 ;;
      *) say "Ongeldige keuze."; press_enter ;;
    esac
  done
}

quick_settings_menu(){
  while true; do
    soft_clear
    load_config
    say "============================================================"
    say " vpn_ipcatcher instellingen"
    say "============================================================"
    say "Kies een onderdeel. Elke optie toont eerst uitleg, de huidige waarde en een voorbeeld."
    say "Wijzigingen worden in $CONF opgeslagen."
    say "------------------------------------------------------------"
    say " 1) Interfaces        : $INTERFACES"
    say "    Waar luistert tcpdump? Meestal br0 voor LAN-clients."
    say " 2) IPSet name        : $IPSET_NAME"
    say "    De ipset die VPN Director gebruikt."
    say " 3) Ports             : $PORTS"
    say "    Welke TCP-poorten worden bekeken, meestal 80,443."
    say " 4) Promote mode      : $PROMOTE_MODE"
    say "    Wanneer gaat candidate naar final: auto/age/bytes/immediate."
    say " 5) Min age           : $MIN_AGE ($(human_duration "$MIN_AGE"))"
    say "    Minimum leeftijd voordat een candidate mag promoveren."
    say " 6) Min bytes         : $MIN_BYTES"
    say "    Minimum verkeer bij promote mode bytes/auto."
    say " 7) Beheer exclude domains"
    say "    Domeinen die nooit vertaald/toegevoegd mogen worden."
    say " 8) Beheer exclude IPs"
    say "    Eigen IP's die nooit naar candidate/final mogen."
    say " 8b) Exclude nets/ranges : ${EXCLUDE_NETS:-none}"
    say "    CIDR-ranges zoals Meta/WhatsApp/Instagram, bv. 57.144.0.0/14."
    say " 9) Profielen"
    say "    Stabiel TV, voorzichtig leren, snel zappen, analyse of freeze."
    say "10) Exclusion manager"
    say "    Granulair: DNS, Games, OS updates, TV telemetry, streamingdiensten."
    say "11) Timers / cleanup"
    say "    Bekijk/wijzig promote-tijd, candidate TTL en final TTL."
    say "12) Generic host scan : $CAPTURE_GENERIC_HOSTNAMES"
    say "    Brede domeinscan op 80/443. Kan veel ruis geven; standaard no."
    say "13) External DNS      : $ALLOW_EXTERNAL_DNS / ${EXTERNAL_DNS_SERVER:-none}"
    say "    Standaard UIT. Niet aanzetten tenzij je dit bewust wilt."
    say "14) Stream flow scan  : $STREAM_FLOW_SCAN"
    say "    Gedragsdetectie: veel verkeer vanaf apparaten = waarschijnlijk stream."
    say "15) Source IPs        : ${SOURCE_IPS:-all LAN devices}"
    say "    Leeg = alle LAN-apparaten. Invullen beperkt de detectie."
    say "16) Stream threshold  : $STREAM_MIN_BYTES bytes"
    say "    Totaal verkeer voordat een flow interessant is."
    say "17) Stream delta      : $STREAM_MIN_DELTA bytes/scan"
    say "    Actuele groei tussen scans. Voorkomt oude/stale conntrack-hits."
    say "18) Stream target     : $STREAM_FLOW_TARGET"
    say "    candidate = buffer, final = direct via VPN Director."
    say "19) Terug"
    printf "Choose: "
    read -r choice
    case "$choice" in
      1)
        say
        say "Interfaces bepalen waar de catcher meekijkt."
        say "Advies: br0. Gebruik liever geen WAN-interface, anders vang je te veel ruis."
        say "Voorbeeld: br0"
        printf "Nieuwe interfaces [$INTERFACES]: "; read -r v
        [ -n "$v" ] && set_config_value "INTERFACES" "$v" && maybe_restart_after_config_change
        ;;
      2)
        say
        say "Dit is de naam van de ipset die VPN Director moet gebruiken."
        say "Laat dit gelijk aan je VPN Director-regel."
        printf "Nieuwe IPSet naam [$IPSET_NAME]: "; read -r v
        [ -n "$v" ] && set_config_value "IPSET_NAME" "$v" && maybe_restart_after_config_change
        ;;
      3)
        say
        say "Poorten die tcpdump bekijkt. Voor streaming is 80,443 meestal genoeg."
        say "Let op: dit is niet hetzelfde als alleen videostreaming; alle TCP 80/443 verkeer op br0 kan zichtbaar zijn."
        printf "Nieuwe ports [$PORTS]: "; read -r v
        [ -n "$v" ] && set_config_value "PORTS" "$v" && maybe_restart_after_config_change
        ;;
      4)
        say
        say "Promote mode bepaalt hoe voorzichtig IPs naar de final ipset gaan."
        say "auto      = gebruikt bytes als conntrack werkt, anders age"
        say "age       = promoveert na MIN_AGE seconden"
        say "bytes     = promoveert pas na MIN_BYTES verkeer"
        say "immediate = direct toevoegen; snel maar minder veilig"
        printf "Promote mode [$PROMOTE_MODE]: "; read -r v
        case "$v" in auto|age|bytes|immediate) set_config_value "PROMOTE_MODE" "$v"; maybe_restart_after_config_change ;; "") ;; *) say "Ongeldige waarde."; press_enter ;; esac
        ;;
      5)
        say
        say "MIN_AGE voorkomt dat korte/irrelevante verbindingen meteen final worden."
        say "Voor jouw situatie is 60-180 sec veiliger dan 30 sec."
        printf "MIN_AGE seconden [$MIN_AGE]: "; read -r v
        [ -n "$v" ] && set_config_value "MIN_AGE" "$v" && maybe_restart_after_config_change
        ;;
      6)
        say
        say "MIN_BYTES voorkomt dat mini-verkeer meteen final wordt."
        say "Voorbeeld: 1000000 (= ongeveer 1 MB)"
        printf "MIN_BYTES [$MIN_BYTES]: "; read -r v
        [ -n "$v" ] && set_config_value "MIN_BYTES" "$v" && maybe_restart_after_config_change
        ;;
      7) manage_domain_exclusions ;;
      8) manage_ip_exclusions ;;
      8b|8B)
        say "CIDR-ranges die nooit naar candidate/final mogen. Voorbeeld: 57.144.0.0/14 157.240.0.0/16"
        printf "EXCLUDE_NETS [$EXCLUDE_NETS]: "; read -r v
        [ -n "$v" ] && set_config_value "EXCLUDE_NETS" "$v" && rebuild_exclude_net_set && ipset_remove_excluded && maybe_restart_after_config_change
        ;;
      9) profile_menu ;;
      10) preset_exclusion_menu ;;
      11) timeout_settings_menu ;;
      12)
        say
        say "Generic host scan zoekt losse domeinnamen in alle 80/443 payloads."
        say "Dit is handig voor brede detectie, maar veroorzaakt vaak heel veel extra IPs."
        say "Advies voor jouw situatie: no. Zet alleen op yes bij gericht testen."
        printf "Generic host scan aanzetten? (yes/no) [$CAPTURE_GENERIC_HOSTNAMES]: "; read -r v
        [ -z "$v" ] && v="$CAPTURE_GENERIC_HOSTNAMES"
        case "$v" in yes|no) set_config_value "CAPTURE_GENERIC_HOSTNAMES" "$v"; maybe_restart_after_config_change ;; *) say "Ongeldige waarde."; press_enter ;; esac
        ;;
      13)
        say
        say "External DNS fallback staat bewust standaard UIT."
        say "Als je dit aanzet, kan het script domeinen resolven via een externe DNS-server."
        say "Advies voor jouw setup: no."
        printf "External DNS toestaan? (yes/no) [$ALLOW_EXTERNAL_DNS]: "; read -r v
        [ -z "$v" ] && v="$ALLOW_EXTERNAL_DNS"
        case "$v" in yes|no) set_config_value "ALLOW_EXTERNAL_DNS" "$v" ;; *) say "Ongeldige waarde."; press_enter; continue ;; esac
        if [ "$v" = "yes" ]; then
          printf "External DNS server IP [$EXTERNAL_DNS_SERVER]: "; read -r dns
          [ -n "$dns" ] && set_config_value "EXTERNAL_DNS_SERVER" "$dns"
        else
          set_config_value "EXTERNAL_DNS_SERVER" ""
        fi
        maybe_restart_after_config_change
        ;;
      14)
        say
        say "Stream flow scan kijkt naar gedrag in conntrack: veel bytes vanaf je apparaten naar een externe 80/443 bestemming."
        say "Dit is juist bedoeld voor providers zonder vaste URL/IP-lijst."
        printf "Stream flow scan aanzetten? (yes/no) [$STREAM_FLOW_SCAN]: "; read -r v
        [ -z "$v" ] && v="$STREAM_FLOW_SCAN"
        case "$v" in yes|no) set_config_value "STREAM_FLOW_SCAN" "$v"; maybe_restart_after_config_change ;; *) say "Ongeldige waarde."; press_enter ;; esac
        ;;
      15)
        say
        say "Vul hier optioneel bron-IP's in, gescheiden door spatie."
        say 'Voorbeeld: SOURCE_IPS="192.168.1.20 192.168.1.21"'
        say "Leeg laten = alle LAN-apparaten, maar dat geeft veel meer ruis."
        printf "Source IPs [$SOURCE_IPS]: "; read -r v
        set_config_value "SOURCE_IPS" "$v"; maybe_restart_after_config_change
        ;;
      16)
        say
        say "STREAM_MIN_BYTES bepaalt hoeveel verkeer een verbinding moet hebben voordat deze kandidaat/final wordt."
        say "Advies startwaarde: 15000000 (ongeveer 15 MB). Lager = meer IPs, hoger = minder maar mogelijk trager."
        printf "Stream min bytes [$STREAM_MIN_BYTES]: "; read -r v
        [ -n "$v" ] && set_config_value "STREAM_MIN_BYTES" "$v" && maybe_restart_after_config_change
        ;;
      17)
        say "STREAM_MIN_DELTA bepaalt hoeveel de conntrack-bytes moeten groeien tussen twee scans."
        say "Hiermee zie je beter wat NU actief is, in plaats van oude conntrack-totalen."
        say "Advies: 500000 tot 2000000. Lager = sneller, hoger = schoner."
        printf "Stream min delta [$STREAM_MIN_DELTA]: "; read -r v
        [ -n "$v" ] && set_config_value "STREAM_MIN_DELTA" "$v" && maybe_restart_after_config_change
        ;;
      18)
        say "Stream flow target: candidate = eerst tijdelijk, final = direct in VPN Director ipset."
        printf "Stream flow target (candidate/final) [$STREAM_FLOW_TARGET]: "; read -r v
        [ -z "$v" ] && v="$STREAM_FLOW_TARGET"
        case "$v" in candidate|final) set_config_value "STREAM_FLOW_TARGET" "$v"; maybe_restart_after_config_change ;; *) say "Ongeldige waarde."; press_enter ;; esac
        ;;
      19|q|Q) return 0 ;;
      *) say "Ongeldige keuze."; press_enter ;;
    esac
  done
}

show_candidate(){ load_config; show_ipset_compact "$CAND_SET"; }
show_final(){ load_config; show_ipset_compact "$IPSET_NAME"; }

live_sets(){
  load_config

  # Geen Ctrl+C nodig: q + Enter is betrouwbaarder wanneer dit vanuit amtm draait.
  while true; do
    soft_clear
    now="$(date '+%F %T')"
    td_count="$(tcpdump_count)"
    say "============================================================"
    say " vpn_ipcatcher live activity"
    say "============================================================"
    say "Laatste refresh : $now"
    say "Gebruik         : druk op q + Enter om terug te gaan naar het menu"
    say "------------------------------------------------------------"
    if is_running; then say "Engine          : running (pid $(cat "$LOCK" 2>/dev/null))"; else say "Engine          : stopped"; fi
    if [ "$td_count" -gt 0 ]; then say "Capture         : active ($td_count tcpdump)"; else say "Capture         : inactive"; fi
    say "IPs             : candidate $(ipset_member_count "$CAND_SET") | final $(ipset_member_count "$IPSET_NAME")"
    say
    say "Candidate = tijdelijke IPs die nog beoordeeld/gepromoveerd worden."
    say "Final     = IPs die echt in de VPN Director ipset staan."
    say
    say "--- Candidate (laatste 12 regels) ---"
    $IPSET list "$CAND_SET" 2>/dev/null | $TAIL -n 12
    say
    say "--- Final (laatste 12 regels) ---"
    $IPSET list "$IPSET_NAME" 2>/dev/null | $TAIL -n 12
    say "------------------------------------------------------------"
    printf "q + Enter = terug | Enter = verversen: "
    read -t 2 -r key 2>/dev/null || key=""
    case "$key" in q|Q) return 0 ;; esac
  done
}

live_stream_flows(){
  load_config
  [ -n "$CT" ] || { say "conntrack is niet gevonden."; press_enter; return 1; }
  mkdir -p "$CACHE_DIR" 2>/dev/null
  while true; do
    curfile="${LIVE_FLOW_STATE}.cur"
    tmpstate="${LIVE_FLOW_STATE}.new"
    : > "$curfile"; : > "$tmpstate"

    soft_clear
    say "============================================================"
    say " Live stream flows - actuele groei per refresh"
    say "============================================================"
    say "Laatste refresh : $(date '+%F %T')"
    say "q + Enter = terug | Enter = verversen"
    say "Totaal-drempel: $STREAM_MIN_BYTES bytes | Groei-drempel: $STREAM_MIN_DELTA bytes/refresh | Target: $STREAM_FLOW_TARGET"
    say "Let op: total is conntrack-cumulatief; delta/groei is wat nu echt oploopt."
    say "------------------------------------------------------------"
    printf "%-12s %-10s %-15s %-15s %-5s %-5s %-5s %s\n" "Total" "Delta" "Source" "Destination" "Port" "Cand" "Final" "Hint"
    say "------------------------------------------------------------"

    $CT -L 2>/dev/null | $AWK -v ports="$PORTS" '
      BEGIN { m=split(ports,pa,","); for(i=1;i<=m;i++) if(pa[i] != "") portok[pa[i]]=1 }
      /^(tcp|udp)/ && /bytes=/ {
        src=""; dst=""; dport=""; bytes=0
        for(i=1;i<=NF;i++){
          if($i ~ /^src=/ && src=="") { src=$i; sub(/^src=/,"",src) }
          if($i ~ /^dst=/ && dst=="") { dst=$i; sub(/^dst=/,"",dst) }
          if($i ~ /^dport=/ && dport=="") { dport=$i; sub(/^dport=/,"",dport) }
          if($i ~ /^bytes=/) { b=$i; sub(/^bytes=/,"",b); bytes+=b }
        }
        if(src=="" || dst=="" || dport=="") next
        if(!(dport in portok)) next
        key=src"|"dst"|"dport
        total[key]+=bytes
      }
      END { for(k in total){ split(k,a,"|"); print a[1], a[2], a[3], total[k] } }
    ' > "$curfile"

    while IFS=' ' read -r src dst dport bytes; do
      [ -z "$dst" ] && continue
      key="${src}|${dst}|${dport}"
      prev=""
      [ -f "$LIVE_FLOW_STATE" ] && prev="$($AWK -v k="$key" '$1==k {print $2; exit}' "$LIVE_FLOW_STATE" 2>/dev/null)"
      [ -z "$prev" ] && prev=0
      delta=$((bytes - prev)); [ "$delta" -lt 0 ] && delta="$bytes"
      printf '%s %s\n' "$key" "$bytes" >> "$tmpstate"
      printf '%012d %010d %s %s %s\n' "$bytes" "$delta" "$src" "$dst" "$dport"
    done < "$curfile" | sort -k2,2nr -k1,1nr | head -25 | while IFS=' ' read -r bytes delta src dst dport; do
      cand="no"; final="no"; hint="watching"
      $IPSET test "$CAND_SET" "$dst" >/dev/null 2>&1 && cand="yes"
      $IPSET test "$IPSET_NAME" "$dst" >/dev/null 2>&1 && final="yes"
      ip_is_excluded "$dst" && hint="excluded"
      [ "$hint" != "excluded" ] && ip_excluded_by_reverse_dns "$dst" && hint="ptr-excluded"
      if [ "$hint" != "excluded" ] && [ "$hint" != "ptr-excluded" ]; then
        if [ "$bytes" -ge "$STREAM_MIN_BYTES" ] && [ "$delta" -ge "$STREAM_MIN_DELTA" ]; then
          hint="active-threshold"
        elif [ "$bytes" -ge "$STREAM_MIN_BYTES" ]; then
          hint="total-high/stale?"
        fi
      fi
      printf "%-12s %-10s %-15s %-15s %-5s %-5s %-5s %s\n" "$bytes" "$delta" "$src" "$dst" "$dport" "$cand" "$final" "$hint"
    done

    mv "$tmpstate" "$LIVE_FLOW_STATE" 2>/dev/null
    rm -f "$curfile" 2>/dev/null
    say "------------------------------------------------------------"
    say "Hint: active-threshold = total boven drempel EN bytes groeien nu actief."
    printf "q + Enter = terug | Enter = verversen: "
    read -t 2 -r key 2>/dev/null || key=""
    case "$key" in q|Q) return 0 ;; esac
  done
}

print_header(){
  load_config
  say "============================================================"
  version="$($SED -n 's/^# Version: //p' "$0" | head -n 1)"
  say " VPN IP Catcher ${version:-onbekend} | ASUS Merlin / amtm"
  connection="$($SED -n '2p' /jffs/addons/vpn_ipcatcher.d/routing-selection 2>/dev/null)"
  case "$connection" in
    ovpnc[1-5]) say " VPN: OpenVPN ${connection#ovpnc}" ;;
    wgc[1-5]) say " VPN: WireGuard ${connection#wgc}" ;;
  esac
  say "============================================================"
  status_report compact
  say "------------------------------------------------------------"
}

reset_config(){
  load_config || return 1
  /jffs/scripts/vpn_ipcatcher.sh backup small || return 1
  config_write_lock || return 1
  tmp="${CONF}.$$"
  # Reset learning settings without losing the installer's VPN/list binding.
  if ! default_config | $AWK -v list="$IPSET_NAME" -v interfaces="$INTERFACES" '
    /^IPSET_NAME=/ {print "IPSET_NAME=\"" list "\""; next}
    /^INTERFACES=/ {print "INTERFACES=\"" interfaces "\""; next}
    {print}
  ' > "$tmp"; then
    rm -f "$tmp"; config_write_unlock; return 1
  fi
  chmod 600 "$tmp" && mv "$tmp" "$CONF" || { rm -f "$tmp"; config_write_unlock; return 1; }
  config_write_unlock
  : > "$CACHE_DOM2IP"
  say "Leerinstellingen teruggezet. VPN/lijstkeuze behouden; back-up gemaakt."
  maybe_restart_after_config_change
}

menu_loop(){
  # Belangrijk: Ctrl+C in live schermen mag het hoofdmenu niet doden.
  trap ':' INT

  while true; do
    soft_clear
    print_header
    say "Bediening"
    say "  1) Starten              Start de catcher op de achtergrond"
    say "  2) Stoppen              Blijft gestopt tot Start of een router-reboot"
    say "  3) Herstarten           Herlaad de instellingen en start opnieuw"
    say "  4) Volledige status     Toon alle actuele details"
    say "  5) Live activiteit      IP-lijsten en capture, q + Enter = terug"
    say "  6) Live log             Logbestand volgen, q + Enter = terug"
    say "  7) Live verbindingen    Verkeer per bestemming en lijststatus"
    say
    say "Bekijken"
    say "  8) Kandidaten           Tijdelijke IPs voor beoordeling"
    say "  9) VPN-bestemmingen     IPs in de definitieve VPN-lijst"
    say " 10) Configuratie tonen   Lees huidige configuratie"
    say
    say "Instellingen"
    say " 11) Instellingen kiezen  Begeleide instellingen"
    say " 12) Profielen            Stabiel TV / voorzichtig / snel zappen / analyse"
    say " 13) Uitsluitingen        Presets per dienst toevoegen/verwijderen"
    say " 14) Configuratie bewerken Handmatig het configbestand bewerken"
    say " 15) Configuratie resetten Terug naar standaardinstellingen"
    say " 16) Lijsten opschonen    Uitgesloten IPs uit de leerlijsten verwijderen"
    say
    say "Onderhoud en updates"
    say " 18) Update controleren   Geen wijzigingen aan je installatie"
    say " 19) Update installeren   Met automatische prive-back-up"
    say " 20) Systeemcontrole      Tools, firmware, cron en VPN controleren"
    say " 21) Vorige versie        Programma terugzetten na gewone update"
    say " 22) VPN kiezen           Andere actieve VPN/lijst instellen"
    say " 23) VPN controleren      Bestaande lijst en route controleren"
    say " 24) Maak back-up         Klein (code/settings/hooks) of uitgebreid"
    say " 25) Toevoegen aan amtm   Registreren als persoonlijk script"
    say " 26) Back-ups beheren     Bekijken, verwijderen of laatste vijf kleine behouden"
    say " UC) Update controleren   U) Bijwerken   FU) Dezelfde versie repareren"
    say " 17) Terug naar amtm"
    printf "Keuze: "
    read -r choice
    echo
    case "$choice" in
      1) start_service; press_enter ;;
      2) stop_service; press_enter ;;
      3) restart_service; press_enter ;;
      4) status_report; press_enter ;;
      5) live_sets ;;
      6) live_log ;;
      7) live_stream_flows ;;
      8) show_candidate; press_enter ;;
      9) show_final; press_enter ;;
      10) show_config; say; say "Opslaan na handmatig bewerken hoeft hier niet; dit is alleen bekijken."; press_enter ;;
      11) quick_settings_menu ;;
      12) profile_menu ;;
      13) preset_exclusion_menu ;;
      14) edit_config; say; say "Opslaan in nano: Ctrl+O, Enter, Ctrl+X. Opslaan in vi: Esc, :wq, Enter."; press_enter ;;
      15) reset_config; press_enter ;;
      16) ipset_remove_excluded; press_enter ;;
      17|q|Q|exit) trap - INT; exit 0 ;;
      18|UC|uc) /jffs/scripts/vpn_ipcatcher.sh check-update; press_enter ;;
      19|U|u|FU|fu)
        update_action=update
        case "$choice" in FU|fu) update_action=force-update ;; esac
        printf "Update installeren / repareren? [j/N]: "; read -r update_answer
        case "$update_answer" in j|J|y|Y)
          printf "Eerst een verplichte prive-back-up maken en daarna bijwerken? [j/N]: "; read -r backup_answer
          case "$backup_answer" in j|J|y|Y) /jffs/scripts/vpn_ipcatcher.sh "$update_action"; press_enter; exec /jffs/scripts/vpn_ipcatcher.sh menu ;; esac
        esac
        ;;
      20) /jffs/scripts/vpn_ipcatcher.sh doctor; press_enter ;;
      21) /jffs/scripts/vpn_ipcatcher.sh rollback; exec /jffs/scripts/vpn_ipcatcher.sh menu ;;
      22) /jffs/scripts/vpn_ipcatcher.sh routing-setup; press_enter ;;
      23) /jffs/scripts/vpn_ipcatcher.sh routing-check; press_enter ;;
      24)
        say "1) Kleine back-up: code, instellingen en hooks"
        say "2) Uitgebreid: ook DVR-configuratie en addonhistorie"
        printf "Keuze [1/2, Enter=terug]: "; read -r backup_choice
        case "$backup_choice" in
          1) /jffs/scripts/vpn_ipcatcher.sh backup small; press_enter ;;
          2) /jffs/scripts/vpn_ipcatcher.sh backup full; press_enter ;;
        esac
        ;;
      25) /jffs/scripts/vpn_ipcatcher.sh amtm-add; press_enter ;;
      26)
        /jffs/scripts/vpn_ipcatcher.sh backup list
        say "1) Een archief verwijderen  2) Laatste vijf kleine archieven behouden"
        say "3) Oude programmakopieen opruimen (actief herstelpunt blijft)"
        say "Programmaherstel (optie 21) wordt niet verwijderd."
        printf "Keuze [1/2/3, Enter=terug]: "; read -r backup_choice
        case "$backup_choice" in
          1)
            printf "Exacte bestandsnaam: "; read -r backup_name
            printf "Deze back-up definitief verwijderen? [j/N]: "; read -r backup_answer
            case "$backup_answer" in j|J|y|Y) /jffs/scripts/vpn_ipcatcher.sh backup delete "$backup_name" --confirmed ;; esac
            ;;
          2)
            printf "Oudere kleine archieven verwijderen (uitgebreide blijven)? [j/N]: "; read -r backup_answer
            case "$backup_answer" in j|J|y|Y) /jffs/scripts/vpn_ipcatcher.sh backup prune-small --confirmed ;; esac
            ;;
          3)
            printf "Oude programmakopieen opruimen (laatste twee en herstelpunt blijven)? [j/N]: "; read -r backup_answer
            case "$backup_answer" in j|J|y|Y) /jffs/scripts/vpn_ipcatcher.sh backup prune-code --confirmed ;; esac
            ;;
        esac
        press_enter
        ;;
      *) say "Ongeldige keuze."; press_enter ;;
    esac
  done
}

usage(){
  cat <<EOF2
Gebruik: $SELF [menu|start|stop|restart|status|show-config|edit-config|log|live-log|show-cand|show-final|live-sets|safe-excludes|repair-excludes|resolve-excludes|show-excludes|clean-excluded|webstatus|run]

menu           Interactief menu (standaard)
start          Start engine op achtergrond
stop           Stop engine + bekende child-processen
restart        Restart engine
status         Toon status
show-config    Toon configbestand
edit-config    Open configbestand in editor
log            Toon laatste logregels
live-log       Volg log live
show-cand      Toon candidate IPSet
show-final     Toon final IPSet
live-sets      Live monitor van candidate + final
safe-excludes   Voeg DNS/GitHub/Social/Camera basis-exclusions toe en schoon ipsets op
resolve-excludes Ververs resolved exclude-cache nu
show-excludes   Toon domein/IP/range exclusions
clean-excluded Verwijder uitgesloten IPs uit candidate/final
webstatus      Schrijf actuele WebGUI status JSON
run            Start capture-engine direct
EOF2
}


case "$1" in
  ""|menu) menu_loop ;;
  start) start_service ;;
  stop) stop_service ;;
  restart) restart_service ;;
  status) status_report ;;
  show-config) show_config ;;
  validate-config) load_config ;;
  edit-config) edit_config ;;
  log) show_log ;;
  live-log) live_log ;;
  live-flows) live_stream_flows ;;
  show-cand) show_candidate ;;
  show-final) show_final ;;
  live-sets) live_sets ;;
  safe-excludes) apply_recommended_safe_excludes ;;
  repair-excludes) repair_safe_excludes ;;
  resolve-excludes) refresh_exclusion_ip_cache force; show_resolved_exclusion_cache ;;
  show-excludes) show_all_exclusions ;;
  clean-excluded) ipset_remove_excluded ;;
  webstatus) write_web_status ;;
  run) run_engine ;;
  -h|--help|help) usage ;;
  *) usage; exit 1 ;;
esac
