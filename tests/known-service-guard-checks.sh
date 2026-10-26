#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
work="${TMPDIR:-/tmp}/vpnipc-yt-guard-$$"
mkdir "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed '/^case "\$1" in/,$d' "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$work/library"
set +e
. "$work/library"
set -e
AWK=awk; SED=sed; GREP=grep; TR=tr; TAIL=tail
CONF="$work/config"
default_config > "$CONF"
load_config
[ "$SYSTEM_EXCLUDE_NETS" = "136.22.128.0/19" ]
for ip in 136.22.128.0 136.22.151.14 136.22.151.15 136.22.159.255; do
  ip_is_base_excluded "$ip" || { echo "Google/YouTube edge was learned: $ip" >&2; exit 1; }
  ip_is_excluded "$ip" || { echo "Not excluded by combined guard: $ip" >&2; exit 1; }
done
for ip in 136.22.127.255 136.22.160.0 203.0.113.7; do
  # For 203.0.113.7 the normal reserved-address guard still applies.
  case "$ip" in 203.0.113.*) continue ;; esac
  if ip_is_base_excluded "$ip"; then echo "Guard was too broad: $ip" >&2; exit 1; fi
done
# A new IPTV destination outside protected networks must remain eligible.
CAND_SET="FixtureCand"; CANDIDATE_TIMEOUT=600
IPSET=ipset_stub
ipset_stub(){
 case "$1" in
  test) return 1 ;;
  add) printf '%s %s\n' "$2" "$3" >> "$work/learned" ;;
 esac
}
add_candidate_once 136.22.151.14 suspicious-google
[ ! -s "$work/learned" ]
add_candidate_once 203.0.114.14 unknown-iptv
grep -q '^FixtureCand 203.0.114.14$' "$work/learned"
. "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_presets.sh"
[ "$(preset_domains social_reddit)" = "reddit.com www.reddit.com redd.it redditstatic.com redditmedia.com v.redd.it" ]
[ "$(preset_domains ai_claude)" = "claude.ai anthropic.com api.anthropic.com" ]
case " $(preset_keys_for_category 'AI assistants') " in
 *' ai_claude ai_openai '*) ;;
 *) echo 'Missing AI category' >&2; exit 1 ;;
esac
preset_write_json "$work/presets.json"
grep -q '"key":"social_reddit"' "$work/presets.json"
grep -q '"key":"ai_claude"' "$work/presets.json"
echo "PASS: Google/YouTube edge is never learned; unknown IPTV destination remains eligible; AI/Reddit presets present"
