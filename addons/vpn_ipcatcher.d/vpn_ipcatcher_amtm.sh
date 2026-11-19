#!/bin/sh
# Version: 2.10.10
# Documented amtm personal_script.mod registry, not the amtm program itself.
set -eu
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
umask 077
DIRECTORY=/jffs/addons/amtm
REGISTRY="$DIRECTORY/personalscript.conf"
ENGINE=/jffs/scripts/vpn_ipcatcher.sh
LOCK=/tmp/vpn_ipcatcher_amtm.lock
[ -s "$ENGINE" ] || { echo 'IP Catcher ontbreekt.' >&2; exit 1; }
# The firmware launcher loads a_fw/amtm.mod. Older installations can use amtm.mod.
MENU_MODULE="$DIRECTORY/a_fw/amtm.mod"
[ -f "$MENU_MODULE" ] || MENU_MODULE="$DIRECTORY/amtm.mod"
if [ -f "$MENU_MODULE" ]; then
  SUPPORT_MODULE="$MENU_MODULE"
else
  SUPPORT_MODULE="$DIRECTORY/personal_script.mod"
fi
if ! grep -Eq 'personalscript\.conf|personal_script\.mod' "$SUPPORT_MODULE" 2>/dev/null; then
  echo 'Open eerst amtm en werk amtm bij. Persoonlijke scripts worden door deze versie nog niet herkend.' >&2
  exit 1
fi
[ ! -L "$REGISTRY" ] || { echo 'Registratie is een symlink; niets gewijzigd.' >&2; exit 1; }
mkdir "$LOCK" 2>/dev/null || { echo 'Registratie bezig; probeer later opnieuw.' >&2; exit 1; }
trap 'rm -f "$REGISTRY.new"; rmdir "$LOCK" 2>/dev/null || true' EXIT
trap 'exit 1' HUP INT TERM
# amtm 7.1+ keeps one entry per line (arguments allowed) and offers eight
# slots; older versions split on whitespace and reach four.
slots=4
if grep -Eq '^[[:blank:]]*\(?\[Pp\]\[1-8\][|)]' "$MENU_MODULE" 2>/dev/null; then
  slots=8
fi
count=0
if [ -f "$REGISTRY" ]; then
  if awk -v engine="$ENGINE" -v slots="$slots" '
    {
      fields = (slots == 8 ? 1 : NF)
      for (i = 1; i <= fields; i++) {
        if ($i == engine) found = 1
      }
    }
    END { exit !found }
  ' "$REGISTRY"; then
    echo 'IP Catcher staat al bij de persoonlijke scripts in amtm.'; exit 0
  fi
  if [ "$slots" = 8 ]; then
    count="$(awk 'NF{n++} END{print n+0}' "$REGISTRY")"
  else
    count="$(awk '{n+=NF} END{print n+0}' "$REGISTRY")"
  fi
  [ "$count" -lt "$slots" ] || { echo "Alle $slots amtm-plaatsen zijn bezet. Verwijder eerst een vermelding via amtm > p." >&2; exit 1; }
  cp -p "$REGISTRY" "$REGISTRY.bak-vpnipc-$(date +%Y%m%d-%H%M%S)-$$"
  # No blank lines: amtm numbers p1..p8 by line, so a gap shifts every entry.
  awk 'NF' "$REGISTRY" > "$REGISTRY.new"
else
  : > "$REGISTRY.new"
fi
printf '%s\n' "$ENGINE" >> "$REGISTRY.new"
chmod 600 "$REGISTRY.new"
mv "$REGISTRY.new" "$REGISTRY"
echo "Toegevoegd. Open amtm opnieuw: IP Catcher staat bij p$((count + 1))."
echo 'Dit is een persoonlijk script, geen officieel amtm-addon.'
