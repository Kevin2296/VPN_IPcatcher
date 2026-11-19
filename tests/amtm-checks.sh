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
# The firmware menu takes precedence over stale modules and their help text.
printf 'personalscript.conf\n  [Pp][1-4]) case_pr "$selection";;\n' > "$work/jffs/addons/amtm/a_fw/amtm.mod"
printf 'personalscript.conf\n  [Pp][1-8]|[Pp][1-8]e) case_pr "$selection";;\n' > "$work/jffs/addons/amtm/amtm.mod"
printf '# Add up to eight scripts\n' > "$work/jffs/addons/amtm/personal_script.mod"
printf '/a /b\n/c\n/d\n' > "$registry"
cp "$registry" "$work/expected"
if sh "$work/register"; then echo 'Full legacy registry overwritten' >&2; exit 1; fi
cmp "$registry" "$work/expected"
rm "$work/jffs/addons/amtm/amtm.mod" "$work/jffs/addons/amtm/personal_script.mod"

# In the legacy registry, the second word on a line is also a script path.
printf '/a %s\n' "$work/jffs/scripts/vpn_ipcatcher.sh" > "$registry"
cp "$registry" "$work/expected"
sh "$work/register" >/dev/null
cmp "$registry" "$work/expected"
# amtm 7.1+: eight slots, one entry per line, arguments allowed.
# Match the personal-script dispatch in upstream amtm_modules/amtm.mod.
printf 'personalscript.conf\n  [Pp][1-8]|[Pp][1-8]e) case_pr $selection;break;;\n' > "$work/jffs/addons/amtm/a_fw/amtm.mod"
printf '/a x y\n/b\n/c\n/d' > "$registry"
out="$(sh "$work/register")"
case "$out" in *'bij p5.'*) ;; *) echo "Wrong slot reported: $out" >&2; exit 1 ;; esac
[ "$(wc -l < "$registry")" = 5 ]
[ "$(sed -n 5p "$registry")" = "$work/jffs/scripts/vpn_ipcatcher.sh" ]
grep -Fxq '/a x y' "$registry"
printf '/a\n\n/b\n' > "$registry"
sh "$work/register" >/dev/null
if grep -q '^[[:space:]]*$' "$registry"; then echo 'Blank line shifts amtm slots' >&2; exit 1; fi
[ "$(sed -n 3p "$registry")" = "$work/jffs/scripts/vpn_ipcatcher.sh" ]
printf '/a\n%s menu\n' "$work/jffs/scripts/vpn_ipcatcher.sh" > "$registry"
first="$(cat "$registry")"
sh "$work/register" >/dev/null
[ "$(cat "$registry")" = "$first" ]
# A path passed to another script is an argument, so slot p8 is still free.
printf '/a %s\n/b\n/c\n/d\n/e\n/f\n/g\n' "$work/jffs/scripts/vpn_ipcatcher.sh" > "$registry"
cp "$registry" "$work/expected"
printf '%s\n' "$work/jffs/scripts/vpn_ipcatcher.sh" >> "$work/expected"
out="$(sh "$work/register")"
case "$out" in *'bij p8.'*) ;; *) echo "Wrong slot reported: $out" >&2; exit 1 ;; esac
cmp "$registry" "$work/expected"

# Fill p8 with another script so a repeated call exercises the capacity check.
printf '/a\n/b\n/c\n/d\n/e\n/f\n/g\n/h\n' > "$registry"
cp "$registry" "$work/expected"
if sh "$work/register" 2>/dev/null; then echo 'Full eight-slot registry overwritten' >&2; exit 1; fi
cmp "$registry" "$work/expected"
rm "$work/jffs/addons/amtm/a_fw/amtm.mod"
if sh "$work/register"; then echo 'Unsupported amtm accepted' >&2; exit 1; fi
echo 'PASS: amtm preserves entries, prevents duplicates/full registry (4 and 8 slots), checks support'
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
