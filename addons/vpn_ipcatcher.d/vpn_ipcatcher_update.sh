#!/bin/sh
# Version: 2.8.2
set -eu
PATH="/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
umask 077
ADDON="/jffs/addons/vpn_ipcatcher.d"
ENGINE="/jffs/scripts/vpn_ipcatcher.sh"
SOURCE="$ADDON/update-source"
DISABLED="/tmp/vpn_ipcatcher.disabled"
LOCK="/tmp/vpn_ipcatcher_update.lock"
FILES="scripts/vpn_ipcatcher.sh scripts/vpn_ipcatcher.real.sh scripts/vpn_ipcatcher_watchdog.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_presets.sh addons/vpn_ipcatcher.d/vpn_ipcatcher.asp addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_doctor.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_backup.sh addons/vpn_ipcatcher.d/vpn_ipcatcher_amtm.sh"
STAGE=""
BACKUP=""
MODIFIED=0
WAS_RUNNING=0
WAS_DISABLED=0
OWN_UPDATE=0
SELECTION_CHANGED=0

fail(){ printf 'FOUT: %s\n' "$*" >&2; exit 1; }
find_on_path(){
  (
    IFS=:
    for directory in $PATH; do
      [ -n "$directory" ] || directory=.
      if [ -f "$directory/$1" ] && [ -x "$directory/$1" ]; then
        printf '%s\n' "$directory/$1"
        exit 0
      fi
    done
    exit 1
  )
}
valid_repo(){
  printf '%s\n' "$1" | grep -Eq '^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$'
}
valid_ref(){
  case "$1" in ''|*[!A-Za-z0-9._-]*) return 1 ;; esac
  [ "${#1}" -le 100 ]
}
restore_files(){
  for relative in $FILES; do
    if [ -f "$BACKUP/$relative.missing" ]; then rm -f "/jffs/$relative"; continue; fi
    [ -f "$BACKUP/$relative" ] || continue
    cp "$BACKUP/$relative" "/jffs/$relative.restore" || return 1
    mv "/jffs/$relative.restore" "/jffs/$relative" || return 1
  done
}
finish(){
  result=$?
  trap - EXIT INT TERM
  if [ "$MODIFIED" = 1 ] && [ "$result" != 0 ]; then
    echo "Update mislukt; vorige bestanden herstellen."
    if ! restore_files; then
      echo "Herstel mislukt. Backup: $BACKUP" >&2
      result=1
      WAS_RUNNING=0
    fi
  fi
  if [ "$SELECTION_CHANGED" = 1 ] && [ "$result" != 0 ]; then
    cp -p "$BACKUP/private-config" /jffs/scripts/vpn_ipcatcher.conf || result=1
    rm -f "$ADDON/routing-selection"
  fi
  if [ "$OWN_UPDATE" = 1 ]; then
    rm -f "$ADDON/updating"
    if [ "$WAS_DISABLED" = 1 ]; then : > "$DISABLED"; else rm -f "$DISABLED"; fi
    if [ "$WAS_RUNNING" = 1 ]; then
      "$ENGINE" start || result=1
    fi
  fi
  [ -z "$STAGE" ] || rm -rf "$STAGE"
  rm -f "$LOCK/pid"
  rmdir "$LOCK" 2>/dev/null || true
  exit "$result"
}

action="${1:-check-update}"
mkdir -p "$ADDON"
mkdir "$LOCK" 2>/dev/null || fail "Update-lock bestaat. Controleer of een andere update bezig is."
echo "$$" > "$LOCK/pid"
trap finish EXIT
trap 'exit 1' INT TERM

if [ "$action" = update-source ]; then
  [ "$#" = 3 ] || fail "Gebruik: $ENGINE update-source eigenaar/repository branch-of-tag"
  valid_repo "$2" && valid_ref "$3" || fail "Ongeldige repository of branch/tag."
  printf '%s\n%s\n' "$2" "$3" > "$SOURCE.new"
  mv "$SOURCE.new" "$SOURCE"
  echo "Updatebron opgeslagen. Gebruik check-update om deze te controleren."
  exit 0
fi

case "$action" in check-update|update|rollback) ;; *) fail "Onbekende actie: $action" ;; esac
STAGE="/tmp/vpn_ipcatcher_update-$(date +%Y%m%d-%H%M%S)-$$"
mkdir "$STAGE"

if [ "$action" = rollback ]; then
  [ -f "$ADDON/last-backup" ] || fail "Geen backup beschikbaar."
  BACKUP="$(cat "$ADDON/last-backup")"
  case "$BACKUP" in "$ADDON"/backups/update-*) ;; *) fail "Ongeldig backuppad." ;; esac
  [ -d "$BACKUP" ] || fail "Backup ontbreekt."
  for relative in $FILES; do
    [ ! -f "$BACKUP/$relative.missing" ] || continue
    [ -s "$BACKUP/$relative" ] || fail "Backup is onvolledig: $relative"
    case "$relative" in *.sh) sh -n "$BACKUP/$relative" || fail "Ongeldige backup: $relative" ;; esac
  done
else
  for program in curl jq sha256sum; do find_on_path "$program" >/dev/null || fail "$program ontbreekt (installeer via Entware)."; done
  [ -f "$SOURCE" ] || fail "Stel eerst update-source in met je GitHub repository en branch/tag."
  repo="$(sed -n '1p' "$SOURCE")"
  ref="$(sed -n '2p' "$SOURCE")"
  valid_repo "$repo" && valid_ref "$ref" || fail "Ongeldige updatebron."
  curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 \
    "https://api.github.com/repos/$repo/commits/$ref" -o "$STAGE/commit.json"
  commit="$(jq -er '.sha | select(type == "string")' "$STAGE/commit.json")"
  printf '%s\n' "$commit" | grep -Eq '^[0-9a-f]{40}$' || fail "GitHub gaf geen geldige commit."
  base="https://raw.githubusercontent.com/$repo/$commit"
  download(){
    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 120 "$base/$1" -o "$STAGE/$1"
  }
  download VERSION
  download SHA256SUMS
  remote="$(cat "$STAGE/VERSION")"
  printf '%s\n' "$remote" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail "Ongeldige releaseversie."
  local_version="$(sed -n 's/^# Version: //p' "$ENGINE" | head -n 1)"
  printf 'Geinstalleerd: %s\nGitHub: %s\nCommit: %s\n' "$local_version" "$remote" "$commit"
  [ "$action" = check-update ] && exit 0
  for relative in $FILES; do
    mkdir -p "$STAGE/$(dirname "$relative")"
    download "$relative"
    [ -s "$STAGE/$relative" ] || fail "Leeg bestand: $relative"
    expected="$(awk -v p="$relative" '$2==p || $2=="*"p {print $1; n++} END{if(n!=1) exit 1}' "$STAGE/SHA256SUMS")" || fail "Checksum ontbreekt of is dubbel: $relative"
    printf '%s\n' "$expected" | grep -Eq '^[0-9a-f]{64}$' || fail "Ongeldige checksum: $relative"
    actual="$(sha256sum "$STAGE/$relative")"; actual="${actual%% *}"
    [ "$actual" = "$expected" ] || fail "Checksum klopt niet: $relative"
    case "$relative" in *.sh) sh -n "$STAGE/$relative" || fail "Shellsyntax fout: $relative" ;; esac
  done
  sh "$STAGE/addons/vpn_ipcatcher.d/vpn_ipcatcher_backup.sh" small --update-owner "$$"
  sh "$STAGE/addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh" install-dependencies
  BACKUP="$ADDON/backups/update-$(date +%Y%m%d-%H%M%S)-$$"
  mkdir -p "$BACKUP"
  cp -p /jffs/scripts/vpn_ipcatcher.conf "$BACKUP/private-config"
  for private_file in routing-selection update-source; do
    [ ! -f "$ADDON/$private_file" ] || cp -p "$ADDON/$private_file" "$BACKUP/private-$private_file"
  done
  for relative in $FILES; do
    mkdir -p "$BACKUP/$(dirname "$relative")"
    if [ ! -s "/jffs/$relative" ]; then
      case "$relative" in
        addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh|addons/vpn_ipcatcher.d/vpn_ipcatcher_backup.sh|addons/vpn_ipcatcher.d/vpn_ipcatcher_amtm.sh) ;;
        *) fail "Huidige installatie onvolledig: $relative" ;;
      esac
      : > "$BACKUP/$relative.missing"
      continue
    fi
    cp -p "/jffs/$relative" "$BACKUP/$relative"
  done
fi

[ ! -f "$ADDON/updating" ] || fail "Een update of herstel staat al als actief geregistreerd."
[ ! -f "$DISABLED" ] || WAS_DISABLED=1
pid="$(cat /tmp/vpn_ipcatcher_pids/engine.pid 2>/dev/null || true)"
case "$pid" in ''|*[!0-9]*) ;; *) if kill -0 "$pid" 2>/dev/null; then WAS_RUNNING=1; fi ;; esac
: > "$ADDON/updating"
OWN_UPDATE=1
"$ENGINE" stop
if [ "$action" = update ] && [ ! -f "$ADDON/routing-selection" ]; then
  cp -p /jffs/scripts/vpn_ipcatcher.conf "$BACKUP/private-config"
  SELECTION_CHANGED=1
  sh "$STAGE/addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh" configure
  [ -s "$ADDON/routing-selection" ] || fail "VPN/lijstselectie niet opgeslagen."
fi
MODIFIED=1
if [ "$action" = rollback ]; then
  restore_files
else
  for relative in $FILES; do
    cp "$STAGE/$relative" "/jffs/$relative.new"
    case "$relative" in *.sh) chmod 755 "/jffs/$relative.new" ;; *) chmod 644 "/jffs/$relative.new" ;; esac
    mv "/jffs/$relative.new" "/jffs/$relative"
  done
fi
# Check startup before accepting the new files; finish restores them on failure.
if [ "$WAS_RUNNING" = 1 ]; then
  VPNIPC_INTERNAL=1 /jffs/scripts/vpn_ipcatcher.real.sh start
fi
MODIFIED=0
if [ "$action" = update ]; then printf '%s\n' "$BACKUP" > "$ADDON/last-backup"; fi
"$ADDON/vpn_ipcatcher_webui.sh" mount || echo "WebUI mount niet gelukt; controleer doctor."
echo "Bestanden bijgewerkt. Persoonlijke configuratie behouden."
