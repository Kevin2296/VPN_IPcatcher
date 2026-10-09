#!/bin/sh
# Version: 2.8.8
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
find_on_path(){
  (
    IFS=:
    for directory in $PATH; do
      [ -n "$directory" ] || directory=.
      if [ -f "$directory/$1" ] && [ -x "$directory/$1" ]; then
        printf '%s\n' "$directory/$1"
        exit 0
      fi
    done
    exit 1
  )
}
rc=0
printf 'Model: '; nvram get productid
printf 'Architectuur: '; uname -m
printf 'Kernel: '; uname -r
printf 'Firmware basis: '; nvram get firmver
printf 'Firmware build: '; nvram get buildno
printf 'Firmware extensie: '; nvram get extendno
printf 'JFFS scripts: '; nvram get jffs2_scripts
for tool in ipset tcpdump sed grep awk nslookup ip cru tr; do
  if location="$(find_on_path "$tool")"; then
    printf 'OK: %s (%s)\n' "$tool" "$location"
  else printf 'ONTBREEKT: %s\n' "$tool"; rc=1; fi
done
for tool in conntrack curl jq sha256sum; do
  if location="$(find_on_path "$tool")"; then
    printf 'OK: %s (%s)\n' "$tool" "$location"
  else
    case "$tool" in conntrack) purpose=flow-scan ;; *) purpose=updates ;; esac
    printf 'OPTIONEEL: %s ontbreekt (%s)\n' "$tool" "$purpose"
  fi
done
ipset --version 2>/dev/null || true
tcpdump --version 2>/dev/null | head -n 2
if [ -r /proc/sys/net/netfilter/nf_conntrack_acct ]; then
  printf 'Conntrack accounting: '; cat /proc/sys/net/netfilter/nf_conntrack_acct
else echo 'Conntrack accounting ontbreekt.'; fi
[ -f /usr/sbin/helper.sh ] && echo 'OK: Merlin Addons helper' || echo 'WebUI: Merlin helper ontbreekt.'
ipset list -n 2>/dev/null | grep '^DVR-' || true
echo '=== Routing rules (controleer VPN-policy) ==='
ip rule show 2>/dev/null
echo '=== IP Catcher mark rules ==='
iptables -t mangle -S 2>/dev/null | grep 'DVR-StreamsVPNSW-v4' || true
echo '=== VPN IP Catcher cron ==='
cru l 2>/dev/null | grep vpn_ipcatcher || true
echo '=== Routing addon / geselecteerde VPN ==='
routing_helper=/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh
if [ -f "$routing_helper" ]; then
  sh "$routing_helper" dependencies || rc=1
  sh "$routing_helper" list || true
  sh "$routing_helper" check || rc=1
else
  echo 'VPN/lijstkeuze vereist installatie van de routing-helper.'
fi
exit "$rc"
