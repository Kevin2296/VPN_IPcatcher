#!/bin/sh
# vpn_ipcatcher WebUI helper for Asuswrt-Merlin Addons API
# Version: 2.8.0

ADDON_NAME="vpn_ipcatcher"
ADDON_DIR="/jffs/addons/vpn_ipcatcher.d"
ASP_SRC="$ADDON_DIR/vpn_ipcatcher.asp"
ENGINE="/jffs/scripts/vpn_ipcatcher.sh"
CONF="/jffs/scripts/vpn_ipcatcher.conf"
LOGFILE="/tmp/vpn_ipcatcher.log"
LOCK="/tmp/vpn_ipcatcher.lock"
PIDDIR="/tmp/vpn_ipcatcher_pids"
STATUS_JSON="/www/user/vpn_ipcatcher_status.json"
MENU_TREE="/www/require/modules/menuTree.js"
TMP_MENU_TREE="/tmp/menuTree.js"
CRON_ID="vpn_ipcatcher_status"
PRESET_LIB="$ADDON_DIR/vpn_ipcatcher_presets.sh"
PRESET_JSON="/www/user/vpn_ipcatcher_presets.json"
CONFIG_WRITE_LOCK="/tmp/vpn_ipcatcher_config.lock"
PUBLISH_LOCK="/tmp/vpn_ipcatcher_webui_status.lock"
ACTION_STATUS="/tmp/vpn_ipcatcher_webui_action.status"
ACTION_RUN_LOCK="/tmp/vpn_ipcatcher_webui_action.lock"
STREAM_ROOT="/tmp/vpn_ipcatcher_webui_stream"

find_bin(){ for p in "$@"; do [ -x "$p" ] && { echo "$p"; return 0; }; done; return 1; }
IPSET="$(find_bin /usr/sbin/ipset /sbin/ipset /opt/sbin/ipset /opt/bin/ipset)"
AWK="$(find_bin /bin/awk /usr/bin/awk /opt/bin/awk)"
SED="$(find_bin /bin/sed /usr/bin/sed /opt/bin/sed)"
TAIL="$(find_bin /usr/bin/tail /bin/tail /opt/bin/tail)"
CAT="$(find_bin /bin/cat /usr/bin/cat /opt/bin/cat)"
PSBIN="$(find_bin /bin/ps /usr/bin/ps)"
CT="$(find_bin /opt/sbin/conntrack /opt/bin/conntrack /usr/sbin/conntrack /usr/bin/conntrack /sbin/conntrack)"
CRU="$(find_bin /usr/sbin/cru /sbin/cru /usr/bin/cru /bin/cru)"
LOGGER="$(find_bin /usr/bin/logger /bin/logger)"; [ -z "$LOGGER" ] && LOGGER="logger"
DATEBIN="$(find_bin /bin/date /usr/bin/date)"
BASE64="$(find_bin /usr/bin/base64 /bin/base64 /opt/bin/base64)"

[ -f "$PRESET_LIB" ] && . "$PRESET_LIB"

log(){ $LOGGER -t vpn_ipcatcher_webui "$*" 2>/dev/null; }

ensure_engine(){ [ -x "$ENGINE" ] || chmod +x "$ENGINE" 2>/dev/null; [ -x "$ENGINE" ]; }

json_escape(){
  # Robust JSON string escaping for BusyBox/Asus.
  # Handles quotes inside ipset comments, backslashes and multiline text.
  ${AWK:-awk} '
    BEGIN { first=1 }
    {
      gsub(/\\/, "\\\\")
      gsub(/"/, "\\\"")
      gsub(/\r/, "")
      if (!first) printf "\\n"
      printf "%s", $0
      first=0
    }
  '
}

cfg_get(){
  key="$1"
  [ -f "$CONF" ] || { echo ""; return; }
  ${SED:-sed} -n "s#^${key}=\"\(.*\)\"#\1#p; s#^${key}=\([^\"].*\)#\1#p" "$CONF" | ${TAIL:-tail} -n 1
}

valid_key(){
  case "$1" in
    INTERFACES|IPSET_NAME|PORTS|PROMOTE_MODE|PROMOTE_EVERY|MIN_AGE|MIN_BYTES|CANDIDATE_TIMEOUT|FINAL_TIMEOUT|STREAM_FLOW_SCAN|SOURCE_IPS|STREAM_SCAN_EVERY|STREAM_MIN_BYTES|STREAM_MIN_DELTA|STREAM_REQUIRE_GROWTH|STREAM_FLOW_TARGET|EXCLUDE_DOMAINS|EXCLUDE_IPS|EXCLUDE_NETS|EXCLUDE_RESOLVE_CACHE|EXCLUDE_RESOLVE_EVERY|REVERSE_DNS_CHECK|CAPTURE_GENERIC_HOSTNAMES|ALLOW_EXTERNAL_DNS|EXTERNAL_DNS_SERVER|RETRY_DELAY|MAX_RETRY_DELAY) return 0 ;;
  esac
  return 1
}

sanitize_value(){
  # Avoid shell-breaking config content. Domains/IPs/settings do not need quotes/backticks/dollars.
  printf '%s' "$1" | tr -d '\r' | tr '\n' ' ' | sed 's/["`$\\]//g' | sed 's/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//'
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

set_cfg(){
  key="$1"; value="$(sanitize_value "$2")"
  valid_key "$key" || return 1
  [ -f "$CONF" ] || "$ENGINE" show-config >/dev/null 2>&1
  config_write_lock || { log "Config lock timeout for $key"; return 1; }
  tmp="${CONF}.$$"
  ${AWK:-awk} -v key="$key" -v value="$value" '
    index($0,key "=")==1 {if(!seen++) print key "=\"" value "\""; next}
    {print}
    END {if(!seen) print key "=\"" value "\""}
  ' "$CONF" > "$tmp" || { rm -f "$tmp"; config_write_unlock; return 1; }
  mv "$tmp" "$CONF" || { rm -f "$tmp"; config_write_unlock; return 1; }
  chmod 600 "$CONF" 2>/dev/null
  config_write_unlock
}

is_pid_alive(){ p="$1"; [ -n "$p" ] && kill -0 "$p" 2>/dev/null; }
is_running(){ [ -f "$LOCK" ] || return 1; pid="$(cat "$LOCK" 2>/dev/null)"; is_pid_alive "$pid"; }

ipset_count(){
  setname="$1"
  [ -n "$IPSET" ] || { echo 0; return; }
  $IPSET list "$setname" 2>/dev/null | ${AWK:-awk} '
    /^Members:/ {m=1; next}
    m && $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\/[0-9]+)?$/ {c++}
    END{print c+0}'
}

ipset_text(){
  setname="$1"; limit="${2:-80}"
  [ -n "$IPSET" ] || { echo "ipset not found"; return; }
  $IPSET list "$setname" 2>/dev/null | ${AWK:-awk} -v limit="$limit" '
    BEGIN{m=0; n=0}
    /^Name:|^Type:|^Header:|^Number of entries:/ {print; next}
    /^Members:/ {m=1; print "Members:"; next}
    m && $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\/[0-9]+)?$/ {
      n++; if(n<=limit) print $0
    }
    END{if(n>limit) print "... truncated ..."}'
}

live_flows_text(){
  [ -n "$CT" ] || { echo "conntrack not found"; return; }
  ports="$(cfg_get PORTS)"; [ -z "$ports" ] && ports="80,443"
  ipset="$(cfg_get IPSET_NAME)"; [ -z "$ipset" ] && ipset="DVR-StreamsVPNSW-v4"
  cand="${ipset}_cand"; exnet="${ipset}_exclude"
  printf "%-12s %-15s %-15s %-5s %-5s %-5s %s\n" "Bytes" "Source" "Destination" "Port" "Cand" "Final" "Hint"
  $CT -L 2>/dev/null | ${AWK:-awk} -v ports="$ports" '
    BEGIN{m=split(ports,p,","); for(i=1;i<=m;i++) portok[p[i]]=1}
    /^(tcp|udp)/ && /bytes=/ {src=""; dst=""; dport=""; bytes=0; for(i=1;i<=NF;i++){if($i~/^src=/ && src==""){src=$i; sub(/^src=/,"",src)}; if($i~/^dst=/ && dst==""){dst=$i; sub(/^dst=/,"",dst)}; if($i~/^dport=/ && dport==""){dport=$i; sub(/^dport=/,"",dport)}; if($i~/^bytes=/){b=$i; sub(/^bytes=/,"",b); bytes+=b}}; if(src==""||dst==""||dport=="") next; if(!(dport in portok)) next; key=src"|"dst"|"dport; total[key]+=bytes}
    END{for(k in total){split(k,a,"|"); printf "%012d %s %s %s\n", total[k], a[1], a[2], a[3]}}
  ' | sort -rn | head -30 | while read -r bytes src dst dport; do
    candmark=no; finalmark=no; hint=watch
    [ -n "$IPSET" ] && $IPSET test "$cand" "$dst" >/dev/null 2>&1 && candmark=yes
    [ -n "$IPSET" ] && $IPSET test "$ipset" "$dst" >/dev/null 2>&1 && finalmark=yes
    [ -n "$IPSET" ] && $IPSET test "$exnet" "$dst" >/dev/null 2>&1 && hint=excluded-range
    printf "%-12s %-15s %-15s %-5s %-5s %-5s %s\n" "$bytes" "$src" "$dst" "$dport" "$candmark" "$finalmark" "$hint"
  done
}

json_array_words(){
  words="$1"; first=1; printf '['
  for word in $words; do
    [ "$first" = "1" ] || printf ','
    printf '"%s"' "$(printf '%s' "$word" | json_escape)"
    first=0
  done
  printf ']'
}
config_revision(){
  [ -f "$CONF" ] || { echo "none"; return; }
  checksum_bin="$(find_bin /opt/bin/cksum /usr/bin/cksum /bin/cksum)"
  if [ -n "$checksum_bin" ]; then
    "$checksum_bin" "$CONF" 2>/dev/null | ${AWK:-awk} '{print $1 ":" $2}'
  else
    wc -c < "$CONF" 2>/dev/null | tr -d ' '
  fi
}
publish_lock_acquire(){
  if mkdir "$PUBLISH_LOCK" 2>/dev/null; then echo $$ > "$PUBLISH_LOCK/pid" 2>/dev/null; return 0; fi
  oldpid="$(cat "$PUBLISH_LOCK/pid" 2>/dev/null)"
  if [ -n "$oldpid" ] && ! kill -0 "$oldpid" 2>/dev/null; then
    rm -rf "$PUBLISH_LOCK" 2>/dev/null
    mkdir "$PUBLISH_LOCK" 2>/dev/null && { echo $$ > "$PUBLISH_LOCK/pid" 2>/dev/null; return 0; }
  fi
  return 1
}
publish_lock_release(){ rm -rf "$PUBLISH_LOCK" 2>/dev/null; }
publish_presets(){
  [ -f "$PRESET_LIB" ] || return 1
  [ -f "$PRESET_JSON" ] && [ "$PRESET_JSON" -nt "$PRESET_LIB" ] && return 0
  type preset_write_json >/dev/null 2>&1 || . "$PRESET_LIB"
  preset_write_json "$PRESET_JSON"
}

publish_status(){
  publish_lock_acquire || return 0
  ensure_engine >/dev/null 2>&1
  [ -f "$CONF" ] || "$ENGINE" show-config >/dev/null 2>&1

  IPSET_NAME="$(cfg_get IPSET_NAME)"; [ -z "$IPSET_NAME" ] && IPSET_NAME="DVR-StreamsVPNSW-v4"
  CAND_SET="${IPSET_NAME}_cand"
  EXCLUDE_NET_SET="${IPSET_NAME}_exclude"
  if is_running; then engine="running"; engine_pid="$(cat "$LOCK" 2>/dev/null)"; else engine="stopped"; engine_pid="-"; fi
  td_count="0"
  if [ -n "$PSBIN" ]; then td_count="$($PSBIN 2>/dev/null | ${AWK:-awk} '/tcpdump/ && / -A / && / -l / && $0 !~ /awk/ {c++} END{print c+0}')"; fi
  cand_count="$(ipset_count "$CAND_SET")"
  final_count="$(ipset_count "$IPSET_NAME")"
  last_update="$(${DATEBIN:-date} '+%F %T' 2>/dev/null)"

  status_text="$(echo "Status via directe engine-call tijdelijk uitgeschakeld." | json_escape)"
  if [ -f "$LOGFILE" ]; then
    log_text="$(${TAIL:-tail} -n 120 "$LOGFILE" 2>/dev/null | json_escape)"
  else
    log_text="$(echo 'Nog geen logbestand.' | json_escape)"
  fi
  cand_text="$(ipset_text "$CAND_SET" 120 | json_escape)"
  final_text="$(ipset_text "$IPSET_NAME" 120 | json_escape)"
  flows_text="$(live_flows_text | json_escape)"
  exclude_net_count="$(ipset_count "$EXCLUDE_NET_SET")"
  exclude_net_text="$(ipset_text "$EXCLUDE_NET_SET" 160 | json_escape)"

  resolved_file="/tmp/vpn_ipcatcher/exclude_ips"
  if [ -s "$resolved_file" ]; then
    resolved_text="$(${TAIL:-tail} -n 120 "$resolved_file" 2>/dev/null | json_escape)"
    resolved_count="$(wc -l < "$resolved_file" 2>/dev/null | tr -d ' ')"
  else
    resolved_text="$(echo 'Geen resolved exclude-cache.' | json_escape)"
    resolved_count="0"
  fi

  publish_presets >/dev/null 2>&1
  protected_ips="${VPNIPC_SYSTEM_EXCLUDE_IPS:-1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220}"
  revision="$(config_revision)"
  last_action_nonce=""; last_action_name=""; last_action_status=""; last_action_message=""
  if [ -f "$ACTION_STATUS" ]; then
    last_action_nonce="$(sed -n '1p' "$ACTION_STATUS" 2>/dev/null)"
    last_action_name="$(sed -n '2p' "$ACTION_STATUS" 2>/dev/null)"
    last_action_status="$(sed -n '3p' "$ACTION_STATUS" 2>/dev/null)"
    last_action_message="$(sed -n '4p' "$ACTION_STATUS" 2>/dev/null)"
  fi
  tmp_json="${STATUS_JSON}.$$"
  cat > "$tmp_json" <<JSON
{
  "version":"2.8.0",
  "last_update":"$last_update",
  "engine":"$engine",
  "engine_pid":"$engine_pid",
  "tcpdump_count":"$td_count",
  "candidate_count":"$cand_count",
  "final_count":"$final_count",
  "resolved_count":"$resolved_count",
  "exclude_net_count":"$exclude_net_count",
  "exclude_net_set":"$(printf '%s' "$EXCLUDE_NET_SET" | json_escape)",
  "ipset_name":"$(printf '%s' "$IPSET_NAME" | json_escape)",
  "candidate_set":"$(printf '%s' "$CAND_SET" | json_escape)",
  "config_revision":"$revision",
  "last_action_nonce":"$(printf '%s' "$last_action_nonce" | json_escape)",
  "last_action_name":"$(printf '%s' "$last_action_name" | json_escape)",
  "last_action_status":"$(printf '%s' "$last_action_status" | json_escape)",
  "last_action_message":"$(printf '%s' "$last_action_message" | json_escape)",
  "protected_ips":$(json_array_words "$protected_ips"),
  "config":{
    "INTERFACES":"$(cfg_get INTERFACES | json_escape)",
    "IPSET_NAME":"$(cfg_get IPSET_NAME | json_escape)",
    "PORTS":"$(cfg_get PORTS | json_escape)",
    "PROMOTE_MODE":"$(cfg_get PROMOTE_MODE | json_escape)",
    "PROMOTE_EVERY":"$(cfg_get PROMOTE_EVERY | json_escape)",
    "MIN_AGE":"$(cfg_get MIN_AGE | json_escape)",
    "MIN_BYTES":"$(cfg_get MIN_BYTES | json_escape)",
    "CANDIDATE_TIMEOUT":"$(cfg_get CANDIDATE_TIMEOUT | json_escape)",
    "FINAL_TIMEOUT":"$(cfg_get FINAL_TIMEOUT | json_escape)",
    "STREAM_FLOW_SCAN":"$(cfg_get STREAM_FLOW_SCAN | json_escape)",
    "SOURCE_IPS":"$(cfg_get SOURCE_IPS | json_escape)",
    "STREAM_SCAN_EVERY":"$(cfg_get STREAM_SCAN_EVERY | json_escape)",
    "STREAM_MIN_BYTES":"$(cfg_get STREAM_MIN_BYTES | json_escape)",
    "STREAM_MIN_DELTA":"$(cfg_get STREAM_MIN_DELTA | json_escape)",
    "STREAM_REQUIRE_GROWTH":"$(cfg_get STREAM_REQUIRE_GROWTH | json_escape)",
    "STREAM_FLOW_TARGET":"$(cfg_get STREAM_FLOW_TARGET | json_escape)",
    "EXCLUDE_DOMAINS":"$(cfg_get EXCLUDE_DOMAINS | json_escape)",
    "EXCLUDE_IPS":"$(cfg_get EXCLUDE_IPS | json_escape)",
    "EXCLUDE_NETS":"$(cfg_get EXCLUDE_NETS | json_escape)",
    "EXCLUDE_RESOLVE_CACHE":"$(cfg_get EXCLUDE_RESOLVE_CACHE | json_escape)",
    "EXCLUDE_RESOLVE_EVERY":"$(cfg_get EXCLUDE_RESOLVE_EVERY | json_escape)",
    "REVERSE_DNS_CHECK":"$(cfg_get REVERSE_DNS_CHECK | json_escape)",
    "CAPTURE_GENERIC_HOSTNAMES":"$(cfg_get CAPTURE_GENERIC_HOSTNAMES | json_escape)",
    "ALLOW_EXTERNAL_DNS":"$(cfg_get ALLOW_EXTERNAL_DNS | json_escape)",
    "EXTERNAL_DNS_SERVER":"$(cfg_get EXTERNAL_DNS_SERVER | json_escape)",
    "RETRY_DELAY":"$(cfg_get RETRY_DELAY | json_escape)",
    "MAX_RETRY_DELAY":"$(cfg_get MAX_RETRY_DELAY | json_escape)"
  },
  "status_text":"$status_text",
  "log_text":"$log_text",
  "candidate_text":"$cand_text",
  "final_text":"$final_text",
  "flows_text":"$flows_text",
  "resolved_text":"$resolved_text",
  "exclude_net_text":"$exclude_net_text"
}
JSON
  mv -f "$tmp_json" "$STATUS_JSON"
  chmod 644 "$STATUS_JSON" 2>/dev/null
  publish_lock_release
}

mount_webui(){
  say(){ printf '%s\n' "$*"; }
  say "[vpn_ipcatcher] Veilige WebUI-mount starten..."

  [ -f /usr/sbin/helper.sh ] || { say "[ERROR] /usr/sbin/helper.sh niet gevonden. Stop."; log "helper.sh not found"; return 5; }
  # shellcheck disable=SC1091
  . /usr/sbin/helper.sh 2>/dev/null

  [ -f "$ASP_SRC" ] || { say "[ERROR] ASP-bron ontbreekt: $ASP_SRC"; log "ASP source missing: $ASP_SRC"; return 5; }

  # Veiligheidsregel: bestaande Addons-menuTree moet al bestaan.
  # We bouwen het Addons-menu NIET zelf opnieuw, want dat kan bestaande addons slopen.
  if [ ! -f "$TMP_MENU_TREE" ]; then
    say "[ERROR] $TMP_MENU_TREE bestaat niet."
    say "[INFO] Herstel eerst je bestaande Addons via services-start / addon startup force."
    log "Refusing mount: $TMP_MENU_TREE missing"
    return 5
  fi

  if ! grep -q 'menuName: "Addons"' "$TMP_MENU_TREE" 2>/dev/null; then
    say "[ERROR] Bestaand Addons-menu niet gevonden in $TMP_MENU_TREE."
    say "[INFO] Ik maak expres geen nieuw Addons-blok aan. Eerst bestaande addons herstellen."
    log "Refusing mount: Addons menu missing"
    return 5
  fi

  mkdir -p /www/user 2>/dev/null

  # Hergebruik bestaande pagina als vpn_ipcatcher al in menuTree staat.
  page="$(sed -n 's/.*{url: "\(user[0-9][0-9]*\.asp\)", tabName: "vpn_ipcatcher"}.*/\1/p' "$TMP_MENU_TREE" 2>/dev/null | head -n 1)"

  if [ -z "$page" ]; then
    if type am_get_webui_page >/dev/null 2>&1; then
      am_get_webui_page "$ASP_SRC" >/dev/null 2>&1
      page="$am_webui_page"
    elif type get_webui_page >/dev/null 2>&1; then
      page="$(get_webui_page 2>/dev/null)"
    fi
  fi

  [ -z "$page" ] && page="none"

  # Fallback wanneer de Merlin Addons API geen vrije userXX.asp teruggeeft.
  # Dit kan gebeuren wanneer de helper alleen de standaard user-slots controleert,
  # terwijl er nog wel ongebruikte hogere userXX.asp-slots bruikbaar zijn.
  if [ "$page" = "none" ]; then
    say "[WARN] Addons API gaf geen vrije pagina terug; veilige fallback zoekt bestaand/ongebruikt userXX.asp-slot."

    # 1) Hergebruik een oude/stale vpn_ipcatcher pagina als die bestaat.
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32; do
      cand="user${i}.asp"
      if [ -f "/www/user/$cand" ] && grep -qi "vpn_ipcatcher" "/www/user/$cand" 2>/dev/null; then
        page="$cand"
        say "[INFO] Oude vpn_ipcatcher WebUI-pagina hergebruikt: $page"
        break
      fi
    done

    # 2) Kies een ongebruikt slot dat niet in de bestaande menuTree voorkomt.
    #    Voorkeur vanaf user9/user11 zodat we bestaande Merlin-addons niet raken.
    if [ "$page" = "none" ]; then
      for i in 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32; do
        cand="user${i}.asp"
        [ -e "/www/user/$cand" ] && continue
        grep -q "{url: \"$cand\"" "$TMP_MENU_TREE" 2>/dev/null && continue
        page="$cand"
        say "[INFO] Ongebruikt WebUI-slot gekozen: $page"
        break
      done
    fi
  fi

  [ -z "$page" ] && page="none"
  [ "$page" = "none" ] && { say "[ERROR] Geen bruikbaar userXX.asp WebUI-slot gevonden."; log "No usable WebUI page slot"; return 5; }

  case "$page" in
    user*.asp) ;;
    *) say "[ERROR] Ongeldige WebUI-pagina ontvangen: $page"; log "Invalid WebUI page: $page"; return 5 ;;
  esac

  cp -f "$ASP_SRC" "/www/user/$page" || { say "[ERROR] Kopiëren naar /www/user/$page mislukt."; return 5; }
  sed -i "s#__VPNIPC_PAGE__#$page#g" "/www/user/$page" 2>/dev/null
  echo "$ADDON_NAME" > "/www/user/$(echo "$page" | cut -f1 -d'.').title" 2>/dev/null
  chmod 644 "/www/user/$page" "/www/user/$(echo "$page" | cut -f1 -d'.').title" 2>/dev/null

  bak="/tmp/menuTree.js.bak_vpn_$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
  cp -f "$TMP_MENU_TREE" "$bak" 2>/dev/null
  say "[INFO] Backup gemaakt: $bak"

  # Verwijder alleen oude vpn_ipcatcher-regels, niet de rest van Addons.
  sed -i '/tabName: "vpn_ipcatcher"/d' "$TMP_MENU_TREE" 2>/dev/null

  tmpout="${TMP_MENU_TREE}.vpnnew.$$"
  awk -v page="$page" '
    BEGIN { inaddons=0; inserted=0 }
    /menuName: "Addons"/ { inaddons=1 }
    inaddons && inserted==0 && /tabName: "__INHERIT__"/ {
      print "{url: \"" page "\", tabName: \"vpn_ipcatcher\"},"
      inserted=1
    }
    { print }
    END { if (inserted==0) exit 2 }
  ' "$TMP_MENU_TREE" > "$tmpout"
  rc="$?"

  if [ "$rc" -ne 0 ]; then
    rm -f "$tmpout" 2>/dev/null
    cp -f "$bak" "$TMP_MENU_TREE" 2>/dev/null
    say "[ERROR] Kon vpn_ipcatcher niet veilig invoegen in Addons-menu. Backup teruggezet."
    log "Safe Addons insert failed; backup restored"
    return 5
  fi

  mv -f "$tmpout" "$TMP_MENU_TREE"
  chmod 664 "$TMP_MENU_TREE" 2>/dev/null

  # Alleen bind-mounten als die nog niet actief is. Bestaande bind-mount niet loshalen.
  if ! mount | grep -q "on $MENU_TREE "; then
    mount -o bind "$TMP_MENU_TREE" "$MENU_TREE" 2>/dev/null || {
      say "[ERROR] Bind-mount naar $MENU_TREE mislukt."
      log "Bind mount failed"
      return 5
    }
  fi

  publish_status
  say "[OK] vpn_ipcatcher veilig toegevoegd onder bestaande Addons via /user/$page"
  say "[OK] Controle: grep -n 'menuName: \"Addons\"\|vpn_ipcatcher' /tmp/menuTree.js"
  log "Mounted vpn_ipcatcher safely under Addons as /user/$page"
}

install_cron(){
  [ -n "$CRU" ] || return 0
  $CRU d "$CRON_ID" >/dev/null 2>&1
  $CRU a "$CRON_ID" "*/1 * * * * $ADDON_DIR/vpn_ipcatcher_webui.sh publish" >/dev/null 2>&1
}

read_setting(){
  key="$1"
  if [ -f /usr/sbin/helper.sh ]; then
    . /usr/sbin/helper.sh 2>/dev/null
    if type am_settings_get >/dev/null 2>&1; then
      am_settings_get "$key" 2>/dev/null
      return
    fi
  fi
  ${AWK:-awk} -v k="$key" '$1==k {$1=""; sub(/^ /,""); print; exit}' /jffs/addons/custom_settings.txt 2>/dev/null
}
read_setting_combined(){
  key="$1"
  count="$(read_setting "${key}_chunks")"
  case "$count" in
    ''|*[!0-9]*) ;;
    0) read_setting "$key"; return ;;
    *)
      out=""; i=1
      while [ "$i" -le "$count" ]; do
        part="$(read_setting "${key}_${i}")"
        out="${out}${part}"
        i=$((i+1))
      done
      printf '%s' "$out"
      return
      ;;
  esac
  out=""; i=1; found_chunks=0
  while :; do
    part="$(read_setting "${key}_${i}")"
    [ -n "$part" ] || break
    out="${out}${part}"; found_chunks=1; i=$((i+1))
  done
  [ "$found_chunks" = "1" ] && { printf '%s' "$out"; return; }
  read_setting "$key"
}


write_setting(){
  key="$1"; val="$2"
  if [ -f /usr/sbin/helper.sh ]; then
    . /usr/sbin/helper.sh 2>/dev/null
    if type am_settings_set >/dev/null 2>&1; then
      am_settings_set "$key" "$val" 2>/dev/null
      return
    fi
  fi
}

save_config_from_settings(){
  rc=0
  for k in INTERFACES IPSET_NAME PORTS PROMOTE_MODE PROMOTE_EVERY MIN_AGE MIN_BYTES CANDIDATE_TIMEOUT FINAL_TIMEOUT STREAM_FLOW_SCAN SOURCE_IPS STREAM_SCAN_EVERY STREAM_MIN_BYTES STREAM_MIN_DELTA STREAM_REQUIRE_GROWTH STREAM_FLOW_TARGET EXCLUDE_DOMAINS EXCLUDE_IPS EXCLUDE_NETS EXCLUDE_RESOLVE_CACHE EXCLUDE_RESOLVE_EVERY REVERSE_DNS_CHECK CAPTURE_GENERIC_HOSTNAMES ALLOW_EXTERNAL_DNS EXTERNAL_DNS_SERVER RETRY_DELAY MAX_RETRY_DELAY; do
    v="$(read_setting_combined "vpnipc_cfg_$k")"
    set_cfg "$k" "$v" || rc=1
  done
  return "$rc"
}

record_action_status(){
  nonce="$1"; action="$2"; status="$3"; message="$4"
  tmp="${ACTION_STATUS}.$$"
  {
    printf '%s\n' "$nonce"
    printf '%s\n' "$action"
    printf '%s\n' "$status"
    printf '%s\n' "$message"
  } > "$tmp"
  mv -f "$tmp" "$ACTION_STATUS"
  chmod 600 "$ACTION_STATUS" 2>/dev/null
}

run_action(){
  ensure_engine || { log "Engine missing at $ENGINE"; return 1; }
  action="$1"; rc=0
  case "$action" in
    start) "$ENGINE" start || rc=$? ;;
    stop) "$ENGINE" stop || rc=$? ;;
    restart) "$ENGINE" restart || rc=$? ;;
    clean_excluded) "$ENGINE" clean-excluded || rc=$? ;;
    safe_excludes) "$ENGINE" safe-excludes || rc=$? ;;
    repair_excludes) "$ENGINE" repair-excludes || rc=$? ;;
    resolve_excludes) "$ENGINE" resolve-excludes || rc=$? ;;
    clear_log) : > "$LOGFILE" || rc=$? ;;
    save_config)
      if save_config_from_settings; then
        # Een gewijzigde domeinlijst moet meteen opnieuw worden opgelost.
        # De resolvercache mag niet wachten op EXCLUDE_RESOLVE_EVERY, anders
        # lijken nieuwe presets opgeslagen maar zijn hun IPs nog niet actief.
        "$ENGINE" resolve-excludes >/dev/null 2>&1 || rc=$?
        if [ "$rc" -eq 0 ]; then
          "$ENGINE" clean-excluded >/dev/null 2>&1 || log "Clean excluded returned non-zero after config save"
        fi
      else
        rc=1
        log "Config save failed; exclusion refresh skipped"
      fi
      ;;
    save_config_restart)
      if save_config_from_settings; then
        # Forceer direct een nieuwe forward-DNS cache voor alle exclude-domeinen.
        # De gevonden adressen blijven losse tijdelijke IP-exclusions; alleen
        # expliciete CIDRs uit EXCLUDE_NETS komen in de exclude-range ipset.
        "$ENGINE" resolve-excludes >/dev/null 2>&1 || rc=$?
        if [ "$rc" -eq 0 ]; then
          "$ENGINE" clean-excluded >/dev/null 2>&1 || log "Clean excluded returned non-zero before restart"
          "$ENGINE" restart || rc=$?
        fi
      else
        rc=1
        log "Config save failed; resolver refresh and restart skipped"
      fi
      ;;
    publish|refresh|"") : ;;
    *) log "Unknown action: $action"; rc=2 ;;
  esac
  return "$rc"
}

valid_nonce(){
  case "$1" in ''|*[!A-Za-z0-9-]*) return 1 ;; esac
  return 0
}

base64url_decode_file(){
  src="$1"; dst="$2"
  [ -f "$src" ] || return 1
  data="$(cat "$src" 2>/dev/null)"
  case "$data" in *[!A-Za-z0-9_-]*) return 1 ;; esac
  mod=$((${#data} % 4))
  case "$mod" in
    0) pad="" ;;
    2) pad="==" ;;
    3) pad="=" ;;
    *) return 1 ;;
  esac
  if [ -n "$BASE64" ]; then
    printf '%s' "${data}${pad}" | tr '_-' '/+' | "$BASE64" -d > "$dst" 2>/dev/null
  else
    printf '%s' "${data}${pad}" | tr '_-' '/+' | busybox base64 -d > "$dst" 2>/dev/null
  fi
}

apply_stream_config(){
  payload="$1"
  [ -s "$payload" ] || return 1
  updates="${payload}.updates"
  : > "$updates" || return 1
  count=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      *=*) key="${line%%=*}"; value="${line#*=}" ;;
      *) rm -f "$updates"; return 1 ;;
    esac
    valid_key "$key" || { rm -f "$updates"; log "Rejected streamed config key: $key"; return 1; }
    value="$(sanitize_value "$value")"
    printf '%s\t%s\n' "$key" "$value" >> "$updates" || { rm -f "$updates"; return 1; }
    count=$((count+1))
  done < "$payload"
  [ "$count" -gt 0 ] || { rm -f "$updates"; return 1; }

  [ -f "$CONF" ] || "$ENGINE" show-config >/dev/null 2>&1
  config_write_lock || { rm -f "$updates"; return 1; }
  tmp="${CONF}.$$"
  ${AWK:-awk} '
    NR==FNR {
      p=index($0,"\t")
      if(p<2) next
      k=substr($0,1,p-1)
      v=substr($0,p+1)
      upd[k]=v
      order[++n]=k
      next
    }
    {
      eq=index($0,"=")
      if(eq>1){
        k=substr($0,1,eq-1)
        if(k in upd){
          print k "=\"" upd[k] "\""
          seen[k]=1
          next
        }
      }
      print
    }
    END {
      for(i=1;i<=n;i++){
        k=order[i]
        if(!(k in seen)) print k "=\"" upd[k] "\""
      }
    }
  ' "$updates" "$CONF" > "$tmp"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    mv -f "$tmp" "$CONF" || rc=1
    chmod 600 "$CONF" 2>/dev/null
  else
    rm -f "$tmp"
  fi
  config_write_unlock
  rm -f "$updates"
  return "$rc"
}

action_run_lock(){
  tries=0
  while ! mkdir "$ACTION_RUN_LOCK" 2>/dev/null; do
    oldpid="$(cat "$ACTION_RUN_LOCK/pid" 2>/dev/null)"
    if [ -n "$oldpid" ] && ! kill -0 "$oldpid" 2>/dev/null; then
      rm -rf "$ACTION_RUN_LOCK" 2>/dev/null
      continue
    fi
    tries=$((tries+1))
    [ "$tries" -ge 120 ] && return 1
    sleep 1
  done
  read lockpid _rest < /proc/self/stat
  echo "$lockpid" > "$ACTION_RUN_LOCK/pid" 2>/dev/null
  return 0
}

action_run_unlock(){ rm -rf "$ACTION_RUN_LOCK" 2>/dev/null; }

stream_reset(){
  nonce="$1"; valid_nonce "$nonce" || return 1
  dir="${STREAM_ROOT}_${nonce}"
  rm -rf "$dir" 2>/dev/null
  mkdir "$dir" 2>/dev/null || return 1
  : > "$dir/data"
  echo 0 > "$dir/next"
  log "Stream reset: nonce=$nonce"
  return 0
}

stream_append(){
  nonce="$1"; seq="$2"; chunk="$3"
  valid_nonce "$nonce" || return 1
  case "$seq" in ''|*[!0-9]*) return 1 ;; esac
  case "$chunk" in ''|*[!A-Za-z0-9_-]*) return 1 ;; esac
  dir="${STREAM_ROOT}_${nonce}"
  [ -d "$dir" ] || return 1
  expected="$(cat "$dir/next" 2>/dev/null)"
  [ "$seq" = "$expected" ] || { log "Stream sequence mismatch nonce=$nonce expected=$expected got=$seq"; return 1; }
  printf '%s' "$chunk" >> "$dir/data" || return 1
  echo $((expected+1)) > "$dir/next"
  return 0
}

stream_finalize(){
  nonce="$1"; action="$2"
  valid_nonce "$nonce" || return 1
  dir="${STREAM_ROOT}_${nonce}"
  [ -s "$dir/data" ] || { record_action_status "$nonce" "$action" "error" "Geen configuratiegegevens ontvangen."; publish_status; return 1; }
  decoded="$dir/config.txt"
  if ! base64url_decode_file "$dir/data" "$decoded"; then
    record_action_status "$nonce" "$action" "error" "Configuratie kon niet worden gedecodeerd."
    rm -rf "$dir" 2>/dev/null
    publish_status
    return 1
  fi
  if ! apply_stream_config "$decoded"; then
    record_action_status "$nonce" "$action" "error" "Configuratie kon niet atomair worden opgeslagen."
    rm -rf "$dir" 2>/dev/null
    publish_status
    return 1
  fi
  rm -rf "$dir" 2>/dev/null

  case "$action" in
    save)
      log "Streamed config saved; async resolver refresh queued: nonce=$nonce"
      (
        rc=0
        if ! action_run_lock; then
          rc=75
        else
          "$ENGINE" resolve-excludes >/dev/null 2>&1 || rc=$?
          [ "$rc" -eq 0 ] && "$ENGINE" clean-excluded >/dev/null 2>&1 || true
          action_run_unlock
        fi
        if [ "$rc" -eq 0 ]; then
          record_action_status "$nonce" "$action" "ok" "Configuratie opgeslagen en exclusions vernieuwd."
        else
          record_action_status "$nonce" "$action" "error" "Configuratie opgeslagen, maar exclusion-refresh faalde met exitcode $rc."
        fi
        publish_status
      ) >/dev/null 2>&1 &
      return 0
      ;;
    saverestart)
      # Cache blijft tijdens de refresh bestaan; de engine vervangt hem atomair.
      # Een actielock voorkomt overlappende resolve/restart-races.
      log "Streamed config saved; async resolve/restart queued: nonce=$nonce"
      (
        rc=0
        if ! action_run_lock; then
          rc=75
        else
          "$ENGINE" resolve-excludes >/dev/null 2>&1 || rc=$?
          [ "$rc" -eq 0 ] && "$ENGINE" clean-excluded >/dev/null 2>&1 || true
          [ "$rc" -eq 0 ] && "$ENGINE" restart >/dev/null 2>&1 || rc=$?
          action_run_unlock
        fi
        if [ "$rc" -eq 0 ]; then
          record_action_status "$nonce" "$action" "ok" "Configuratie opgeslagen, exclusions vernieuwd en engine herstart."
          log "Async resolve/restart completed: nonce=$nonce"
        else
          record_action_status "$nonce" "$action" "error" "Configuratie opgeslagen, maar resolve/herstart faalde met exitcode $rc."
          log "Async resolve/restart failed: nonce=$nonce rc=$rc"
        fi
        publish_status
      ) >/dev/null 2>&1 &
      return 0
      ;;
    *)
      record_action_status "$nonce" "$action" "error" "Onbekende opslagactie."
      publish_status
      return 2
      ;;
  esac
}

simple_event_action(){
  nonce="$1"; action="$2"
  valid_nonce "$nonce" || return 1
  log "Direct event action start: action=$action nonce=$nonce"
  if ! action_run_lock; then
    rc=75
    record_action_status "$nonce" "$action" "error" "Een andere vpn_ipcatcher-actie is nog bezig."
  elif run_action "$action"; then
    rc=0
    action_run_unlock
    record_action_status "$nonce" "$action" "ok" "Actie succesvol uitgevoerd."
  else
    rc=$?
    action_run_unlock
    record_action_status "$nonce" "$action" "error" "Actie mislukt met exitcode $rc."
  fi
  publish_status
  return "$rc"
}

service_event(){
  type="$1"; event="$2"
  [ "$type" = "restart" ] || return 0

  case "$event" in
    vipcR*)
      nonce="${event#vipcR}"
      stream_reset "$nonce"
      return $?
      ;;
    vipcA*)
      rest="${event#vipcA}"
      nonce="${rest%%_*}"
      rest="${rest#*_}"
      seq="${rest%%_*}"
      chunk="${rest#*_}"
      stream_append "$nonce" "$seq" "$chunk"
      return $?
      ;;
    vipcZ*)
      rest="${event#vipcZ}"
      nonce="${rest%%_*}"
      action="${rest#*_}"
      stream_finalize "$nonce" "$action"
      return $?
      ;;
    vipcX*)
      rest="${event#vipcX}"
      nonce="${rest%%_*}"
      action="${rest#*_}"
      # Start/stop/restart/refresh kunnen enkele seconden duren. De browser
      # pollt op action.status, dus service-event hoeft hier niet op te wachten.
      simple_event_action "$nonce" "$action" >/dev/null 2>&1 &
      return 0
      ;;
  esac

  # Legacy custom_settings channel retained for older cached pages.
  [ "$event" = "vpnipcatcher" ] || [ "$event" = "vpn_ipcatcher" ] || [ "$event" = "vpnipcatcher_webui" ] || return 0
  action="$(read_setting vpnipc_action)"
  nonce="$(read_setting vpnipc_nonce)"
  [ -n "$action" ] || { log "Legacy service event received without vpnipc_action"; return 0; }
  [ -n "$nonce" ] || nonce="legacy-$(date +%s 2>/dev/null || echo 0)"
  if run_action "$action"; then
    rc=0
    record_action_status "$nonce" "$action" "ok" "Actie succesvol uitgevoerd."
  else
    rc=$?
    record_action_status "$nonce" "$action" "error" "Actie mislukt met exitcode $rc."
  fi
  write_setting vpnipc_action ""
  publish_status
  return "$rc"
}

case "$1" in
  mount) mount_webui ;;
  cron) install_cron ;;
  publish|status) publish_status ;;
  action)
    shift
    action="$1"; nonce="cli-$(date +%s 2>/dev/null || echo 0)"
    if run_action "$action"; then rc=0; record_action_status "$nonce" "$action" "ok" "Actie succesvol uitgevoerd."; else rc=$?; record_action_status "$nonce" "$action" "error" "Actie mislukt met exitcode $rc."; fi
    publish_status
    exit "$rc"
    ;;
  service_event) shift; service_event "$@" ;;
  *) echo "Usage: $0 {mount|cron|publish|action <name>|service_event <type> <event>}" ;;
esac
