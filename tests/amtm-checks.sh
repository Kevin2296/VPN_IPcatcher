#!/bin/sh
set -eu
work="${TMPDIR:-/tmp}/vpnipc-amtm-test-$$"
mkdir -p "$work/jffs/addons/amtm/a_fw" "$work/jffs/scripts" "$work/tmp"
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed -e "s|/jffs|$work/jffs|g" -e "s|/tmp/vpn_ipcatcher|$work/tmp/vpn_ipcatcher|g" \
  addons/vpn_ipcatcher.d/vpn_ipcatcher_amtm.sh > "$work/register"
printf '#!/bin/sh\n' > "$work/jffs/scripts/vpn_ipcatcher.sh"
printf 'personalscript.conf\n' > "$work/jffs/addons/amtm/a_fw/amtm.mod"
registry="$work/jffs/addons/amtm/personalscript.conf"
printf '/jffs/scripts/other.sh\n' > "$registry"
sh "$work/register"
grep -Fxq '/jffs/scripts/other.sh' "$registry"
grep -Fxq "$work/jffs/scripts/vpn_ipcatcher.sh" "$registry"
first="$(cat "$registry")"
sh "$work/register"
[ "$(cat "$registry")" = "$first" ]
printf '/a\n/b\n/c\n/d\n' > "$registry"
if sh "$work/register"; then echo 'Full registry overwritten' >&2; exit 1; fi
[ "$(awk '{n+=NF} END{print n}' "$registry")" = 4 ]
rm "$work/jffs/addons/amtm/a_fw/amtm.mod"
if sh "$work/register"; then echo 'Unsupported amtm accepted' >&2; exit 1; fi
echo 'PASS: amtm preserves entries, prevents duplicates/full registry, checks support'
mkdir -p "$work/jffs/addons/vpn_ipcatcher.d"
sed -e "s|/jffs|$work/jffs|g" -e "s|/tmp/vpn_ipcatcher|$work/tmp/vpn_ipcatcher|g" scripts/vpn_ipcatcher.sh > "$work/wrapper"
if sh "$work/wrapper" amtmupdate check; then echo 'Automatic updates enabled without consent'; exit 1; fi
printf '#!/bin/sh\n[ "$1" = automatic-update ]\n' > "$work/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh"
chmod +x "$work/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh"
printf 'example/project\nmain\n' > "$work/jffs/addons/vpn_ipcatcher.d/update-source"
sh "$work/wrapper" auto-update enable
sh "$work/wrapper" amtmupdate check
sh "$work/wrapper" amtmupdate
sh "$work/wrapper" auto-update disable
if sh "$work/wrapper" amtmupdate check; then exit 1; fi
echo 'PASS: amtmupdate opt-in, check exit codes and noninteractive updater dispatch'
