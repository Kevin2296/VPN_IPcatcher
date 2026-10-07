#!/bin/sh
set -eu
work="${TMPDIR:-/tmp}/vpnipc-bootstrap-test-$$"
mkdir -p "$work/bin" "$work/payload" "$work/jffs"
trap 'rm -rf "$work"' EXIT HUP INT TERM
export BOOTSTRAP_TEST_WORK="$work"
sed -e "s|/jffs|$work/jffs|g" -e "s|/tmp/vpnipc-install-|$work/stage-|g" \
  -e "s|^PATH=.*|PATH=\"$work/bin:\$PATH\"|" \
  -e "s|for directory in /opt/bin /opt/sbin /usr/sbin /usr/bin /sbin /bin;|for directory in $work/bin;|" \
  -e '/^\[ -t 0 \]/d' install.sh > "$work/bootstrap"
for tool in awk sed grep sha256sum; do
  toolpath="$(command -v "$tool")"
  printf '#!/bin/sh\nexec "%s" "$@"\n' "$toolpath" > "$work/bin/$tool"
done
printf '#!/bin/sh\necho 0\n' > "$work/bin/id"
printf '#!/bin/sh\necho 1\n' > "$work/bin/nvram"
printf '#!/bin/sh\necho 1111111111111111111111111111111111111111\n' > "$work/bin/jq"
cat > "$work/bin/curl" <<'EOF'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  case "$1" in https://*) url="$1" ;; -o) shift; target="$1" ;; esac
  shift
done
case "$url" in
  *api.github.com*) printf '{}\n' > "$target" ;;
  *) relative="${url#*1111111111111111111111111111111111111111/}"; cp "$BOOTSTRAP_TEST_WORK/payload/$relative" "$target" ;;
esac
EOF
chmod +x "$work/bin/"*
files="$(sed -n "s/^FILES='\(.*\)'$/\1/p" install.sh)"
for relative in $files; do
  mkdir -p "$work/payload/$(dirname "$relative")"
  printf '#!/bin/sh\nexit 0\n' > "$work/payload/$relative"
  hash="$(sha256sum "$work/payload/$relative")"; hash="${hash%% *}"
  printf '%s  %s\n' "$hash" "$relative" >> "$work/payload/SHA256SUMS"
done
printf 'corrupt\n' >> "$work/payload/scripts/vpn_ipcatcher.real.sh"
if sh "$work/bootstrap" install; then echo 'Corrupt bootstrap accepted' >&2; exit 1; fi
[ ! -e "$work/jffs/scripts/vpn_ipcatcher.sh" ]
printf '#!/bin/sh\nexit 0\n' > "$work/payload/scripts/vpn_ipcatcher.real.sh"
sh "$work/bootstrap" install
[ -f "$work/jffs/scripts/vpn_ipcatcher.conf" ]
[ -x "$work/jffs/scripts/vpn_ipcatcher.sh" ]
if sh "$work/bootstrap" install; then echo 'Existing installation overwritten' >&2; exit 1; fi
echo 'PASS: bootstrap validates downloads before writes and refuses reinstall'
if sh "$work/bootstrap" migrate; then echo 'Modern installation migrated again' >&2; exit 1; fi
rm "$work/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh"
cat > "$work/payload/addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" > "$BOOTSTRAP_TEST_WORK/migration-action"
cp "$0" "$BOOTSTRAP_TEST_WORK/jffs/addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh"
EOF
: > "$work/payload/SHA256SUMS"
for relative in $files; do
  hash="$(sha256sum "$work/payload/$relative")"; hash="${hash%% *}"
  printf '%s  %s\n' "$hash" "$relative" >> "$work/payload/SHA256SUMS"
done
sh "$work/bootstrap" migrate
grep -q '^migrate Kevin2296/VPN_IPcatcher 1111111111111111111111111111111111111111$' "$work/migration-action"
echo 'PASS: bootstrap dispatches explicit legacy migration without calling the old update interface'
sed '/^action=/,$d' "$work/bootstrap" > "$work/identity-library"
. "$work/identity-library"
[ "$(effective_uid)" = 0 ]
rm "$work/bin/id"
sed "s|/proc/self/status|$work/process-status|g" "$work/identity-library" > "$work/identity-fallback"
. "$work/identity-fallback"
printf 'Name:\ttest\nUid:\t1000\t0\t0\t0\n' > "$work/process-status"
[ "$(effective_uid)" = 0 ]
printf 'Uid:\t0\t1000\t0\t0\n' > "$work/process-status"
[ "$(effective_uid)" = 1000 ]
printf 'Name:\ttest\n' > "$work/process-status"
if effective_uid; then echo 'Missing UID accepted' >&2; exit 1; fi
echo 'PASS: root check supports missing id and uses the effective, not real, UID'
