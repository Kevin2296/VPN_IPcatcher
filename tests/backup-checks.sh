#!/bin/sh
set -eu
work="${TMPDIR:-/tmp}/vpnipc-backup-test-$$"
mkdir -p "$work/bin" "$work/jffs/scripts" "$work/jffs/addons/vpn_ipcatcher.d" "$work/tmp"
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed -e "s|/jffs|$work/jffs|g" -e "s|/tmp/vpn_ipcatcher|$work/tmp/vpn_ipcatcher|g" \
  -e "s|^PATH=.*|PATH=\"$work/bin:\$PATH\"|" backup.sh > "$work/backup"
printf '#!/bin/sh\necho 0\n' > "$work/bin/id"
chmod +x "$work/bin/id"
printf 'IPSET_NAME="Example"\n' > "$work/jffs/scripts/vpn_ipcatcher.conf"
printf '#!/bin/sh\n' > "$work/jffs/scripts/services-start"
printf 'Example\novpnc1\n' > "$work/jffs/addons/vpn_ipcatcher.d/routing-selection"
sh "$work/backup"
set -- "$work/jffs/vpn-ipcatcher-backups/"*.tar.gz
[ "$#" = 1 ] && [ -f "$1" ]
tar -tzf "$1" > "$work/entries"
grep -q '^scripts/vpn_ipcatcher.conf$' "$work/entries"
grep -q '^scripts/services-start$' "$work/entries"
grep -q '^addons/vpn_ipcatcher.d/routing-selection$' "$work/entries"
[ ! -d "$work/tmp/vpn_ipcatcher_update.lock" ]
[ ! -d "$work/tmp/vpn_ipcatcher_config.lock" ]
mkdir "$work/tmp/vpn_ipcatcher_update.lock"
if sh "$work/backup"; then echo 'Concurrent update lock ignored' >&2; exit 1; fi
[ -d "$work/tmp/vpn_ipcatcher_update.lock" ]
echo 'PASS: private backup includes settings/hooks, cleans owned locks, respects update lock'
rmdir "$work/tmp/vpn_ipcatcher_update.lock"
sed -e "s|/jffs|$work/jffs|g" -e "s|/tmp/vpn_ipcatcher|$work/tmp/vpn_ipcatcher|g" \
  -e "s|^PATH=.*|PATH=\"$work/bin:\$PATH\"|" \
  addons/vpn_ipcatcher.d/vpn_ipcatcher_backup.sh > "$work/helper"
mkdir -p "$work/jffs/addons/vpn_ipcatcher.d/backups/history"
printf 'Private history\n' > "$work/jffs/addons/vpn_ipcatcher.d/backups/history/old"
sh "$work/helper" small
set -- "$work/jffs/vpn-ipcatcher-backups/"*small*.tar.gz
tar -tzf "$1" > "$work/small-entries"
grep -q 'scripts/vpn_ipcatcher.conf' "$work/small-entries"
if grep -q 'backups/history' "$work/small-entries"; then echo 'Small backup contains history' >&2; exit 1; fi
sh "$work/helper" full
set -- "$work/jffs/vpn-ipcatcher-backups/"*full*.tar.gz
tar -tzf "$1" > "$work/full-entries"
grep -q 'backups/history/old' "$work/full-entries"
mkdir "$work/tmp/vpn_ipcatcher_update.lock"
export BACKUP_HELPER="$work/helper" BACKUP_TEST_LOCK="$work/tmp/vpn_ipcatcher_update.lock"
sh -c 'echo $$ > "$BACKUP_TEST_LOCK/pid"; sh "$BACKUP_HELPER" small --update-owner $$; test -f "$BACKUP_TEST_LOCK/pid"'
if sh "$work/helper" small --update-owner 999999; then echo 'Wrong lock owner accepted' >&2; exit 1; fi
[ -f "$work/tmp/vpn_ipcatcher_update.lock/pid" ]
echo 'PASS: small/full archives, parent update-lock reuse, invalid lock owner refused'
