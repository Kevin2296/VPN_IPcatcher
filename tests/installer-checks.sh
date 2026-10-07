#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/vpnipc-installer-tests-$$"
mkdir -p "$TMP/jffs/scripts"
trap 'rm -rf "$TMP"' EXIT
printf '%s\n' '#!/bin/sh' '/jffs/scripts/ExampleEventAddon "$@"' \
  '### vpn_ipcatcher WebUI start' 'echo legacy-webui' \
  '### vpn_ipcatcher WebUI end' > "$TMP/jffs/scripts/service-event"
printf '%s\n' '#!/bin/sh' '/jffs/scripts/ExampleOtherAddon startup' \
  '# BEGIN vpn_ipcatcher SAFE' 'echo legacy-startup' \
  '# END vpn_ipcatcher SAFE' > "$TMP/jffs/scripts/services-start"
sed -e '/^main "\$@"/,$d' -e "s|/jffs/|$TMP/jffs/|g" \
  "$ROOT/addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh" > "$TMP/library"
. "$TMP/library"
log(){ :; }
install_service_event_block
install_services_start_block
install_service_event_block
install_services_start_block
sh -n "$SERVICE_EVENT"
sh -n "$SERVICES_START"
[ "$(grep -c '# BEGIN vpn_ipcatcher WebGUI' "$SERVICE_EVENT")" = 1 ]
[ "$(grep -c '# BEGIN vpn_ipcatcher startup' "$SERVICES_START")" = 1 ]
if grep -q '### vpn_ipcatcher WebUI start' "$SERVICE_EVENT"; then exit 1; fi
if grep -q '# BEGIN vpn_ipcatcher SAFE' "$SERVICES_START"; then exit 1; fi
grep -q 'vipcR\*|vipcA\*|vipcZ\*|vipcX\*' "$SERVICE_EVENT"
grep -q '/jffs/scripts/ExampleOtherAddon startup' "$SERVICES_START"
grep -q '/jffs/scripts/ExampleEventAddon' "$SERVICE_EVENT"
grep -q 'vpn_ipcatcher.sh watchdog' "$SERVICES_START"
echo 'PASS: installer preserves other addons, migrates legacy blocks, handles current WebUI events and is repeatable'
