#!/bin/sh
set -eux
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
work="/tmp/vpnipc-force-vpn-$$"
mkdir -p "$work/bin" "$work/addon"
trap 'rm -rf "$work"' EXIT HUP INT TERM

sed '/^case "\${1:-check}" in/,$d' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh" > "$work/lib"
set +e
. "$work/lib"
set -e

# URL path and tokens are deliberately not part of the forced routing host.
[ "$(normalize_force_vpn_host 'https://EPG.Example.ORG:8443/guide.xml.gz?token=private')" = "epg.example.org" ]
[ "$(normalize_force_vpn_host 'EPG.Example.ORG')" = "epg.example.org" ]
for invalid in 'ftp://epg.example.org/guide' 'https://user:secret@epg.example.org/file' 'https://[2001:db8::1]/file' 'https://epg.example.org.evil@evil.org/file' 'epg.example.org/path'; do
  if normalize_force_vpn_host "$invalid" >/dev/null 2>&1; then
    echo "Unsafe/invalid force-VPN domain accepted" >&2; exit 1
  fi
done
echo "PASS: full EPG URLs safely normalize to hostname only"

ADDON="$work/addon"
POLICIES="$work/domain_vpn_routing.conf"
GLOBAL="$work/global.conf"
DVR="$work/dvr"
TABLES="$work/rt_tables"
IPSET=mock_set
CONF="$work/config"
printf 'ENABLE=1\n' > "$GLOBAL"
printf 'epg|x|x|ovpnc3\nother|x|x|ovpnc2\n' > "$POLICIES"
: > "$work/policy_epg_domainlist"
: > "$work/policy_other_domainlist"
: > "$CONF"
: > "$TABLES"
cat > "$ADDON/vpn_ipcatcher_backup.sh" <<'EOS'
#!/bin/sh
echo backed-up >> "$TEST_DVR_DIR/backups"
EOS
cat > "$DVR" <<'EOS'
#!/bin/sh
# Version: v3.2.5
case "$1" in
  adddomain)
    file="$TEST_DVR_DIR/policy_${POLICY}_domainlist"
    grep -Fx "$2" "$file" >/dev/null 2>&1 || printf '%s\n' "$2" >> "$file"
    ;;
  querypolicy)
    host="$(tail -n 1 "$TEST_DVR_DIR/policy_${2}_domainlist")"
    if [ "${NO_DNS:-no}" = yes ]; then
      : > "$TEST_DVR_DIR/policy_${2}_domaintoIP"
    else
      printf '%s>>198.51.100.77\n' "$host" > "$TEST_DVR_DIR/policy_${2}_domaintoIP"
    fi
    ;;
esac
EOS
cat > "$work/bin/timeout" <<'EOS'
#!/bin/sh
[ "$1" = '-s' ] && shift 2
case "$1" in -t) shift 2 ;; esac
shift
exec "$@"
EOS
cat > "$work/bin/flock" <<'EOS'
#!/bin/sh
[ "$1" = '-n' ] && shift 2
exec "$@"
EOS
chmod 755 "$ADDON/vpn_ipcatcher_backup.sh" "$DVR" "$work/bin/timeout" "$work/bin/flock"
export TEST_DVR_DIR="$work"
find_bin(){
  case "$1" in
    /usr/bin/timeout) printf '%s\n' "$work/bin/timeout" ;;
    /opt/bin/flock) printf '%s\n' "$work/bin/flock" ;;
    *) return 1 ;;
  esac
}
# Mock a VPN with a valid fwmark/route; never query actual host routing.
mark_read(){ [ "$CONNECTION" = ovpnc3 ]; }
rule_check(){ [ "$CONNECTION" = ovpnc3 ]; }
route_check(){ [ "$CONNECTION" = ovpnc3 ]; }
mock_set(){
  case "$1" in
    list) [ "$2" = DVR-epg-v4 ] ;;
    test) [ "$2" = DVR-epg-v4 ] && [ "$3" = 198.51.100.77 ] ;;
    *) return 1 ;;
  esac
}
domain_add epg 'https://EPG.Example.ORG:8443/guide.xml.gz?token=secret' > "$work/result"
[ "$(cat "$work/policy_epg_domainlist")" = epg.example.org ]
grep -q 'Altijd-VPN: epg.example.org -> policy epg -> ovpnc3' "$work/result"
[ -s "$work/backups" ]
if grep -rq 'token=secret' "$work/policy_epg_domainlist" "$work/policy_epg_domaintoIP"; then
  echo "Private URL token was saved to a DVR file" >&2; exit 1
fi
echo "PASS: selected VPN receives EPG hostname and active IPSet route is verified"

printf 'epg.example.org\n' > "$work/policy_other_domainlist"
if domain_add epg epg.example.org > /dev/null 2>&1; then
  echo "Conflicting duplicate policy was accepted" >&2; exit 1
fi
: > "$work/policy_other_domainlist"
NO_DNS=yes; export NO_DNS
if domain_add epg epg.example.org > /dev/null 2>&1; then
  echo "Unresolved forced VPN host incorrectly reported success" >&2; exit 1
fi
unset NO_DNS
echo "PASS: conflicting policy and unresolved EPG route report failures"
