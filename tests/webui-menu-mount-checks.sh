#!/bin/sh
# 2.10.9: after an update the IP Catcher tab must stay visible. The WebUI
# serves /www/require/modules/menuTree.js, a bind mount of /tmp/menuTree.js.
# Replacing /tmp/menuTree.js (mv, sed -i) leaves the mount on the old file.
# A hard link models the bind mount: it keeps pointing at the old inode.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
work="${TMPDIR:-/tmp}/vpnipc-menu-$$"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
fail(){ echo "FAIL: $*" >&2; exit 1; }
sed '/^case "\$1" in/,$d' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh" > "$work/webui"
(
  set +e
  . "$work/webui"
  set -e
  say(){ :; }; log(){ printf '%s\n' "$*" >> "$work/log"; }
  TMP_MENU_TREE="$work/tmp-menuTree.js"; MENU_TREE="$work/www-menuTree.js"
  mounted=0
  mount(){
    if [ "$#" = 0 ]; then [ "$mounted" = 1 ] && echo "tmpfs on $MENU_TREE type tmpfs (rw)"; return 0; fi
    [ "$1" = "-o" ] && [ "$2" = bind ] || return 1
    rm -f "$4"; ln "$3" "$4"; mounted=1
  }
  umount(){ mounted=0; }
  cat > "$TMP_MENU_TREE" <<'EOF'
{menuName: "Addons",
{url: "user2.asp", tabName: "scMerlin"},
{url: "user11.asp", tabName: "vpn_ipcatcher"},
{url: "NULL", tabName: "__INHERIT__"}
EOF
  # First mount: tab inserted once and served.
  menu_apply user11.asp "$work/bak" || fail "first apply"
  [ "$(grep -c 'tabName: "vpn_ipcatcher"' "$MENU_TREE")" = 1 ] || fail "tab not served after first mount"
  # Update: apply again while mounted. The served menu must still show it.
  menu_apply user11.asp "$work/bak" || fail "second apply"
  [ "$(grep -c 'tabName: "vpn_ipcatcher"' "$MENU_TREE")" = 1 ] || fail "tab lost or doubled after update"
  cmp -s "$TMP_MENU_TREE" "$MENU_TREE" || fail "served menu differs from /tmp after update"
  # Another addon replaced /tmp/menuTree.js (new inode): served copy is stale.
  sed 's/scMerlin/scMerlinNew/' "$TMP_MENU_TREE" > "$work/new" && mv "$work/new" "$TMP_MENU_TREE"
  cmp -s "$TMP_MENU_TREE" "$MENU_TREE" && fail "fixture: mount should be stale now"
  menu_apply user11.asp "$work/bak" || fail "repair apply"
  cmp -s "$TMP_MENU_TREE" "$MENU_TREE" || fail "stale bind mount not repaired"
  grep -q 'scMerlinNew' "$MENU_TREE" || fail "other addon change not served"
  grep -q 'opnieuw gekoppeld' "$work/log" || fail "remount not logged"
  # No Addons inherit line: nothing changes, error returned.
  printf '{menuName: "Addons",\n{url: "user2.asp", tabName: "scMerlin"},\n' > "$TMP_MENU_TREE"
  cp "$TMP_MENU_TREE" "$work/before"
  if menu_apply user11.asp "$work/bak"; then fail "insert without anchor accepted"; fi
  cmp -s "$TMP_MENU_TREE" "$work/before" || fail "menu changed on failed insert"
) || exit 1
# The menu file is never replaced by mv or sed -i anymore.
awk '/^menu_apply\(\)/,/^}/' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh" | grep -E 'mv -f "\$tmpout" "\$TMP_MENU_TREE"|sed -i .*TMP_MENU_TREE' && fail "menu file still replaced"
echo "ALL PASS: webui-menu-mount-checks"
