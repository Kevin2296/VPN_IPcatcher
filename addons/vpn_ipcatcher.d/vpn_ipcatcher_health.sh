#!/bin/sh
# Version: 2.10.8
# Light, read-only health check: WAN, DNS, VPN and Entware/USB.
# "tick" runs from the watchdog cron and throttles itself to HEALTH_EVERY
# seconds. A fault must be seen twice in a row before it counts. On a
# transition to a fault it logs once and writes ONE small report to /jffs
# (overwritten, max HEALTH_REPORT_MAX bytes, at most every 30 minutes), so the
# cause survives a reboot without continuous flash logging. Never prints
# passwords, keys or tokens: no "nvram show", only named non-secret values.
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
ADDON="${VPNIPC_ADDON_DIR:-/jffs/addons/vpn_ipcatcher.d}"
STATE="${VPNIPC_HEALTH_STATE:-/tmp/vpn_ipcatcher_health.state}"
LOCKDIR="/tmp/vpn_ipcatcher_health.lock"
REPORT="$ADDON/incident-last.txt"
LOGFILE="/tmp/vpn_ipcatcher.log"
ROUTING="$ADDON/vpn_ipcatcher_routing.sh"
HEALTH_EVERY=120
HEALTH_REPORT_MAX=12288
HEALTH_REPORT_EVERY=1800
DNS_TEST_NAME="one.one.one.one"
WAN_TEST_IPS="9.9.9.9 1.1.1.1"
OPT_DIR="/opt"

now(){ date +%s 2>/dev/null || echo 0; }
note(){
  logger -t vpn_ipcatcher_health "$*" 2>/dev/null || true
  [ -L "$LOGFILE" ] || printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOGFILE" 2>/dev/null
}
nv(){ nvram get "$1" 2>/dev/null; }
# Run a command with a hard time limit (BusyBox has no reliable timeout).
with_timeout(){
  limit="$1"; shift
  "$@" > /tmp/vpn_ipcatcher_health.out.$$ 2>&1 &
  child=$!
  waited=0
  while kill -0 "$child" 2>/dev/null; do
    if [ "$waited" -ge "$limit" ]; then kill "$child" 2>/dev/null; sleep 1; kill -9 "$child" 2>/dev/null; break; fi
    sleep 1; waited=$((waited+1))
  done
  wait "$child" 2>/dev/null; rc=$?
  [ "$waited" -lt "$limit" ] || rc=124
  cat /tmp/vpn_ipcatcher_health.out.$$ 2>/dev/null; rm -f /tmp/vpn_ipcatcher_health.out.$$
  return "$rc"
}

check_opt(){
  [ -d "$OPT_DIR/bin" ] || { echo "Entware ($OPT_DIR) niet beschikbaar"; return 1; }
  for t in "$OPT_DIR/bin/tcpdump" "$OPT_DIR/sbin/tcpdump"; do [ -x "$t" ] && return 0; done
  echo "tcpdump ontbreekt"; return 1
}
check_wan(){
  wan_state="$(nv wan0_state_t)"
  case "$wan_state" in ''|2) ;; *) echo "WAN-status wan0_state_t=$wan_state"; return 1 ;; esac
  ip route show 2>/dev/null | grep -q '^default ' || { echo "geen default route in main-tabel"; return 1; }
  for target in $WAN_TEST_IPS; do
    with_timeout 4 ping -c 1 -W 2 "$target" >/dev/null && return 0
  done
  echo "geen antwoord van $WAN_TEST_IPS"; return 1
}
check_dns(){
  out="$(with_timeout 6 nslookup "$DNS_TEST_NAME" 127.0.0.1)" || { echo "lokale DNS (127.0.0.1) geeft geen antwoord"; return 1; }
  printf '%s\n' "$out" | awk '/^Name:/ {n=1} n && /^Address/ && /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {f=1} END{exit f?0:1}' ||
    { echo "lokale DNS geeft geen IPv4-antwoord"; return 1; }
}
check_vpn(){
  [ -x "$ROUTING" ] || return 0
  [ -s "$ADDON/routing-selection" ] || return 0
  out="$(with_timeout 10 sh "$ROUTING" ready)" || { printf '%s\n' "$out" | head -n 2 | tr '\n' ' '; return 1; }
}

# One classification, most fundamental first: wan > dns > vpn > opt.
classify(){
  detail=''
  if d="$(check_wan)"; then :; else echo "wan|$d"; return; fi
  if d="$(check_dns)"; then :; else echo "dns|$d"; return; fi
  if d="$(check_vpn)"; then :; else echo "vpn|$d"; return; fi
  if d="$(check_opt)"; then :; else echo "opt|$d"; return; fi
  echo "ok|"
}

write_report(){
  kind="$1"; detail="$2"
  mkdir -p "$ADDON" 2>/dev/null || return 1
  tmp="$REPORT.tmp.$$"
  {
    echo "# VPN IP Catcher storingsrapport (overschreven bij de volgende storing)"
    echo "tijd: $(date '+%F %T')  soort: $kind  detail: $detail"
    echo "uptime: $(cat /proc/uptime 2>/dev/null)  load: $(cat /proc/loadavg 2>/dev/null)"
    awk '/^(MemTotal|MemAvailable|MemFree):/ {printf "%s %s kB  ", $1, $2} END{print ""}' /proc/meminfo 2>/dev/null
    echo "--- USB/Entware"
    grep -E ' /tmp/mnt/| /opt ' /proc/mounts 2>/dev/null | awk '{print $1, $2, $3}'
    ls -ld /opt /tmp/opt 2>&1 | awk '{print $1, $(NF-2), $(NF-1), $NF}'
    check_opt >/dev/null 2>&1 && echo "tcpdump: aanwezig" || echo "tcpdump: ontbreekt"
    echo "--- engine"
    pid="$(cat /tmp/vpn_ipcatcher_pids/engine.pid 2>/dev/null)"
    case "$pid" in ''|*[!0-9]*) echo "engine: geen pid" ;; *) kill -0 "$pid" 2>/dev/null && echo "engine: draait ($pid)" || echo "engine: pid $pid dood" ;; esac
    echo "capture tcpdump: $(ps 2>/dev/null | grep -c '[t]cpdump -i')"
    [ -r /tmp/vpn_ipcatcher.prereq ] && echo "wacht op: $(cut -d' ' -f2- /tmp/vpn_ipcatcher.prereq)"
    echo "--- WAN"
    for key in wan0_state_t wan0_sbstate_t wan0_auxstate_t wan0_proto wan0_gateway; do echo "$key=$(nv "$key")"; done
    ip route show 2>/dev/null | grep '^default'
    echo "--- DNS"
    ps 2>/dev/null | awk '/[d]nsmasq|[A]dGuardHome|[u]nbound|[s]tubby/ {print $NF}' | sort | uniq -c
    check_dns 2>&1 | head -n 2
    echo "--- VPN"
    for i in 1 2 3 4 5; do s="$(nv vpn_client${i}_state)"; [ -z "$s" ] || [ "$s" = 0 ] || echo "vpn_client$i state=$s errno=$(nv vpn_client${i}_errno)"; done
    selection="$(sed -n '1,2p' "$ADDON/routing-selection" 2>/dev/null | tr '\n' ' ')"
    echo "IP Catcher policy/VPN: ${selection:-onbekend}"
    check_vpn 2>&1 | head -n 3
    ip rule show 2>/dev/null | grep -E 'fwmark|ovpnc|wgc' | head -n 12
    set_name="$(sed -n '1p' "$ADDON/routing-selection" 2>/dev/null)"
    case "$set_name" in ''|*[!A-Za-z0-9_-]*) ;; *) echo "DVR-$set_name-v4 leden: $(ipset list "DVR-$set_name-v4" 2>/dev/null | grep -cE '^[0-9]+\.')" ;; esac
    echo "--- laatste logregels"
    tail -n 15 "$LOGFILE" 2>/dev/null
  } 2>/dev/null | awk -v max="$HEALTH_REPORT_MAX" '{n+=length($0)+1; if (n>max) exit; print}' > "$tmp" || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$REPORT"
}

tick(){
  mkdir "$LOCKDIR" 2>/dev/null || {
    # A lock older than 5 minutes belongs to a killed run.
    age=$(( $(now) - $(date -r "$LOCKDIR" +%s 2>/dev/null || echo 0) ))
    [ "$age" -gt 300 ] || return 0
    rmdir "$LOCKDIR" 2>/dev/null; mkdir "$LOCKDIR" 2>/dev/null || return 0
  }
  trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT
  tick_locked "$@"
  rmdir "$LOCKDIR" 2>/dev/null
  trap - EXIT
  return 0
}
tick_locked(){
  t="$(now)"
  last=0; state=ok; streak=0; since=0; reported=0
  [ -r "$STATE" ] && read -r last state streak since reported < "$STATE"
  for v in "$last" "$streak" "$since" "$reported"; do case "$v" in ''|*[!0-9]*) last=0; state=ok; streak=0; since=0; reported=0 ;; esac; done
  if [ "$t" -ge "$last" ] && [ $((t - last)) -lt "$HEALTH_EVERY" ] && [ "${1:-}" != force ]; then return 0; fi
  result="$(classify)"; kind="${result%%|*}"; detail="${result#*|}"
  if [ "$kind" = ok ]; then
    if [ "$state" != ok ] && [ "$streak" -ge 2 ]; then
      note "Hersteld na storing ($state); duur ongeveer $(( (t - since) / 60 )) min."
    fi
    printf '%s ok 0 0 %s\n' "$t" "$reported" > "$STATE"; return 0
  fi
  if [ "$kind" = "$state" ]; then streak=$((streak+1)); else state="$kind"; streak=1; since="$t"; fi
  if [ "$streak" = 2 ]; then
    note "Storing vastgesteld ($kind): $detail"
    if [ "$t" -lt "$reported" ] || [ $((t - reported)) -ge "$HEALTH_REPORT_EVERY" ]; then
      write_report "$kind" "$detail" && reported="$t" && note "Storingsrapport bewaard: $REPORT"
    fi
  fi
  printf '%s %s %s %s %s\n' "$t" "$state" "$streak" "$since" "$reported" > "$STATE"
}

case "${1:-check}" in
  tick) tick ;;
  check)
    r="$(classify)"; kind="${r%%|*}"; detail="${r#*|}"
    if [ -n "$detail" ]; then echo "Status: $kind - $detail"; else echo "Status: $kind"; fi
    [ "$kind" = ok ] ;;
  report) cat "$REPORT" 2>/dev/null || echo "Nog geen storingsrapport." ;;
  status) [ -r "$STATE" ] && cat "$STATE" || echo "Nog geen status." ;;
  *) echo "Gebruik: vpn_ipcatcher_health.sh {check|report|status|tick}"; exit 1 ;;
esac
