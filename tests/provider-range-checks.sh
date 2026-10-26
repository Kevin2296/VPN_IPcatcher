#!/bin/sh
set -eux
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="/tmp/vpnipc-provider-test-$$"
mkdir "$TMP"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
sed '/^case "\$1" in/,$d' "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$TMP/library"
sed -n '/^rebuild_exclude_net_set(){/,/^}/p' "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$TMP/real-rebuild"
set +e
. "$TMP/library"
set -e
AWK=awk; SED=sed; GREP=grep; TR=tr; TAIL=tail
JQ="$(command -v jq || true)"
[ -n "$JQ" ] || { echo "jq missing"; exit 1; }
CONF="$TMP/config"
printf 'EXCLUDE_DOMAINS="google.com netflix.com imoulife.com"\nPROVIDER_RANGE_AUTO="yes"\n' > "$CONF"
load_config
[ "$PROVIDER_RANGE_AUTO" = yes ]
provider_is_selected google
provider_is_selected netflix
if provider_is_selected meta; then echo "Unselected Meta provider accepted"; exit 1; fi
if provider_is_selected imou; then echo "Unknown provider accepted"; exit 1; fi
PROVIDER_CACHE="$TMP/provider-cache"
PROVIDER_CACHE_TS="$TMP/provider-cache.ts"
PROVIDER_ATTEMPT="$TMP/provider-attempt"
PROVIDER_LOCK="$TMP/provider-lock"
CACHE_DIR="$TMP"
CURL=mock_curl
mock_curl(){
  url=''; outfile=''
  while [ "$#" -gt 0 ]; do
    if [ "$1" = '-o' ]; then shift; outfile="$1"
    else case "$1" in https://*) url="$1" ;; esac; fi
    shift
  done
  [ -n "$outfile" ]
  echo "$url" >> "$TMP/queries"
  case "$url" in *"AS$MOCK_FAIL_AS") return 22 ;; esac
  case "$url" in
    *AS15169*|*AS36040*|*AS19527*) prefix='142.250.0.0/15' ;;
    *AS2906*|*AS40027*) prefix='23.246.0.0/18' ;;
    *) return 1 ;;
  esac
  printf '{"status":"ok","data":{"prefixes":[{"prefix":"%s"}]}}\n' "$prefix" > "$outfile"
}
MOCK_FAIL_AS=0
rebuild_exclude_net_set(){ echo rebuilt >> "$TMP/rebuilt"; }
refresh_provider_ranges force
grep -q '^google 142.250.0.0/15$' "$PROVIDER_CACHE"
grep -q '^netflix 23.246.0.0/18$' "$PROVIDER_CACHE"
[ "$(wc -l < "$PROVIDER_CACHE")" -eq 2 ]
[ -s "$PROVIDER_CACHE_TS" ]
[ -s "$TMP/rebuilt" ]
before="$(wc -l < "$TMP/queries")"
refresh_provider_ranges auto
[ "$before" -eq "$(wc -l < "$TMP/queries")" ]
echo "PASS: selected services are cached and throttled; no third-party cloud networks"

MOCK_FAIL_AS=2906
if refresh_provider_ranges force; then echo "Failed provider ASN accepted"; exit 1; fi
grep -q '^netflix 23.246.0.0/18$' "$PROVIDER_CACHE"
grep -q '^google 142.250.0.0/15$' "$PROVIDER_CACHE"
echo "PASS: per-provider source failure retains last verified list"

printf 'google 0.0.0.0/0\n' > "$TMP/invalid"
if provider_cache_validate "$TMP/invalid"; then echo "Accidental /0 accepted"; exit 1; fi
printf 'unknown 45.45.0.0/16\n' > "$TMP/invalid"
if provider_cache_validate "$TMP/invalid"; then echo "Unknown provider accepted"; exit 1; fi
echo "PASS: malformed, overbroad and foreign prefix entries rejected"

# Restore the real function after mocking the downloader's refresh callback.
. "$TMP/real-rebuild"
IPSET=mock_ipset
mock_ipset(){
  command="$1"; shift
  case "$command" in
    list|save) return 0 ;;
    create|add|swap|destroy) printf '%s %s\n' "$command" "$*" >> "$TMP/ipset-actions" ;;
    restore) cat >> "$TMP/restores" ;;
    test) return 1 ;;
    *) return 1 ;;
  esac
}
rebuild_exclude_net_set
grep -q '142.250.0.0/15' "$TMP/restores"
grep -q '23.246.0.0/18' "$TMP/restores"
printf 'EXCLUDE_DOMAINS="google.com imoulife.com"\nPROVIDER_RANGE_AUTO="yes"\n' > "$CONF"
: > "$TMP/restores"
rebuild_exclude_net_set
grep -q '142.250.0.0/15' "$TMP/restores"
if grep -q '23.246.0.0/18' "$TMP/restores"; then echo "Disabled Netflix still excluded"; exit 1; fi
echo "PASS: provider-owned prefixes merged only for selected excluded services"

ip_is_base_excluded 136.22.151.14
if ip_is_base_excluded 45.125.42.11; then echo "Unrelated IPTV destination excluded"; exit 1; fi
echo "PASS: Google CDN guard remains active; unknown IPTV servers stay eligible"
