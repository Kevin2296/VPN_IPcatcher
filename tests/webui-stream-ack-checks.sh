#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
tmp="/tmp/vpnipc-ack-$$"
mkdir "$tmp"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
sed '/^case "\$1" in/,$d' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh" > "$tmp/lib"
set +e
KEEP_PATH="$PATH"
. "$tmp/lib"
PATH="$KEEP_PATH"
set -e
STREAM_ROOT="$tmp/data"
STREAM_ACK="$tmp/ack.json"
log(){ :; }
stream_reset abc
node -e 'const d=JSON.parse(require("fs").readFileSync(process.argv[1]));if(d.next!==0||d.state!=="ready")process.exit(1)' "$STREAM_ACK"
stream_append abc 0 Zm9v
node -e 'const d=JSON.parse(require("fs").readFileSync(process.argv[1]));if(d.next!==1||d.state!=="received")process.exit(1)' "$STREAM_ACK"
if stream_append abc 3 YmFy; then exit 1; fi
node -e 'const d=JSON.parse(require("fs").readFileSync(process.argv[1]));if(d.state!=="error")process.exit(1)' "$STREAM_ACK"
stream_append abc 1 YmFy
[ "$(cat "${STREAM_ROOT}_abc/data")" = "Zm9vYmFy" ]
echo 'PASS: streamed configuration acknowledged and ordered'
