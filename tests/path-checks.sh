#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/vpnipc-path-tests-$$"
mkdir -p "$TMP/bin" "$TMP/second"
trap 'rm -rf "$TMP"' EXIT
printf '#!/bin/sh\nexit 0\n' > "$TMP/bin/present"
cp "$TMP/bin/present" "$TMP/second/present"
chmod 755 "$TMP/bin/present" "$TMP/second/present"
for source in addons/vpn_ipcatcher.d/vpn_ipcatcher_doctor.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh; do
  sed -n '/^find_on_path(){/,/^}/p' "$ROOT/$source" > "$TMP/library"
  . "$TMP/library"
  previous_path="$PATH"
  PATH="$TMP/bin:$TMP/second"
  command(){ return 127; }
  [ "$(find_on_path present)" = "$TMP/bin/present" ]
  if find_on_path missing; then echo 'Missing tool accepted'; exit 1; fi
  [ "$PATH" = "$TMP/bin:$TMP/second" ]
  PATH="$previous_path"
done
echo 'PASS: executable detection works without command -v and preserves PATH'
