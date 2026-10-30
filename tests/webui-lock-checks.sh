#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
work="${TMPDIR:-/tmp}/vpnipc-status-lock-$$"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed '/^case "\$1" in/,$d' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh" > "$work/library"
set +e
TEST_PATH="$PATH"
. "$work/library"
PATH="$TEST_PATH"
set -e
PUBLISH_LOCK="$work/status.lock"
STATUS_JSON="$work/status.json"
CONF="$work/config"
LOGFILE="$work/log"
ADDON_DIR="$work/addon"
PRESET_LIB="$work/no-presets"
ACTION_STATUS="$work/no-action"
mkdir -p "$ADDON_DIR"
printf 'TestPolicy\novpnc3\n' > "$ADDON_DIR/routing-selection"
printf 'IPSET_NAME="Example"\nINTERFACES="br0"\n' > "$CONF"
AWK=awk; SED=sed; TAIL=tail
log(){ printf '%s\n' "$*" >> "$work/events"; }
# An active process owns its PID lock: do not interrupt or delete it.
mkdir "$PUBLISH_LOCK"
printf '%s\n' "$$" > "$PUBLISH_LOCK/pid"
if publish_lock_acquire; then echo 'Live lock acquired twice' >&2; exit 1; fi
[ "$(cat "$PUBLISH_LOCK/pid")" = "$$" ]
if publish_status; then echo 'Busy publisher returned success' >&2; exit 1; fi
[ ! -e "$STATUS_JSON" ]
echo 'PASS: live lock remains intact; skipped status publication is not success'

# A dead owner can be safely reclaimed (never recursively delete the directory).
printf '%s\n' 99999999 > "$PUBLISH_LOCK/pid"
publish_lock_acquire
[ "$(cat "$PUBLISH_LOCK/pid")" = "$$" ]
publish_lock_release
[ ! -e "$PUBLISH_LOCK" ]
echo 'PASS: dead process lock recovered and released'

# Exact user failure: orphaned lock directory without a pid file.
mkdir "$PUBLISH_LOCK"
touch -t 202001010101 "$PUBLISH_LOCK"
publish_lock_acquire
[ "$(cat "$PUBLISH_LOCK/pid")" = "$$" ]
publish_lock_release
[ ! -e "$PUBLISH_LOCK" ]
grep -q 'achtergebleven lock veilig opgeruimd' "$work/events"
echo 'PASS: pid-less orphan directory recovered without manual cleanup'

# An unknown non-empty directory must not be removed.
mkdir "$PUBLISH_LOCK"
printf 'other addon\n' > "$PUBLISH_LOCK/keep"
touch -t 202001010101 "$PUBLISH_LOCK"
if publish_lock_acquire; then echo 'Non-empty lock removed' >&2; exit 1; fi
[ -f "$PUBLISH_LOCK/keep" ]
rm -f "$PUBLISH_LOCK/keep"
rmdir "$PUBLISH_LOCK"
echo 'PASS: unknown lock contents preserved'

# Publishing must actually produce readable JSON after automatic recovery.
ensure_engine(){ return 0; }
publish_presets(){ return 0; }
is_running(){ return 1; }
ipset_count(){ echo 0; }
ipset_text(){ echo 'Members:'; }
live_flows_text(){ echo 'No test flows'; }
ENGINE=fixture_engine
fixture_engine(){
  case "$1" in effective-config) cat "$CONF";; *) return 1;; esac
}
mkdir "$PUBLISH_LOCK"
touch -t 202001010101 "$PUBLISH_LOCK"
publish_status
[ -s "$STATUS_JSON" ]
node -e 'const d=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));if(d.version!=="2.10.2"||d.vpn_connection!=="ovpnc3")process.exit(1)' "$STATUS_JSON"
[ ! -e "$PUBLISH_LOCK" ]
echo 'PASS: WebGUI status generated as valid JSON and lock released'
