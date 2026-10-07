#!/bin/sh
# Version: 2.6.0
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
rc=0
printf 'Model: '; nvram get productid
printf 'Architectuur: '; uname -m
printf 'Kernel: '; uname -r
printf 'Firmware basis: '; nvram get firmver
printf 'Firmware build: '; nvram get buildno
printf 'Firmware extensie: '; nvram get extendno
printf 'JFFS scripts: '; nvram get jffs2_scripts
for tool in ipset tcpdump sed grep awk nslookup ip cru tr; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf 'OK: %s\n' "$tool"
  else printf 'ONTBREEKT: %s\n' "$tool"; rc=1; fi
done
for tool in conntrack curl jq sha256sum; do
  command -v "$tool" >/dev/null 2>&1 && printf 'OK: %s\n' "$tool" || printf 'OPTIONEEL: %s ontbreekt (flow-scan of updates)\n' "$tool"
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
exit "$rc"
