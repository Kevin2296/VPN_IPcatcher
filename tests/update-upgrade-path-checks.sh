#!/bin/sh
# 2.10.7: an update from an older release must not stop with "Huidige
# installatie onvolledig" for a file that the older release never shipped.
# The older updater downloads only its own file list, so a file added later
# (2.10.5: vpn_ipcatcher_health.sh) is absent until the next update.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
U="$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh"
fail(){ echo "FAIL: $*" >&2; exit 1; }
files="$(sed -n 's/^FILES="\(.*\)"$/\1/p' "$U" | head -n 1)"
[ -n "$files" ] || fail "FILES list not found"
allow="$(awk '/fail "Huidige installatie onvolledig/ {print prev} {prev=$0}' "$U" | sed 's/^[[:space:]]*//; s/) ;;$//')"
[ -n "$allow" ] || fail "missing-file allowlist not found"
# Files every supported older release (2.9.x and later) already installed.
core="scripts/vpn_ipcatcher.sh scripts/vpn_ipcatcher.real.sh scripts/vpn_ipcatcher_watchdog.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_presets.sh addons/vpn_ipcatcher.d/vpn_ipcatcher.asp addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_doctor.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh"
for f in $files; do
  case " $core " in *" $f "*) continue ;; esac
  case "|$allow|" in *"|$f|"*) ;; *) fail "$f was added after older releases but blocks their update when absent" ;; esac
done
case "|$allow|" in *"|addons/vpn_ipcatcher.d/vpn_ipcatcher_health.sh|"*) ;; *) fail "health script not allowed to be missing" ;; esac
# Every shipped file must also be in the installer's FILES and the checksums.
for f in $files; do
  grep -q "  $f\$" "$ROOT/SHA256SUMS" || fail "$f missing from SHA256SUMS"
done
echo "ALL PASS: update-upgrade-path-checks"
