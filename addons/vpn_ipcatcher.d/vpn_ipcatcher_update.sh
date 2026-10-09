#!/bin/sh
# Version: 2.8.9
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
HOOKS_CHANGED=0
HOOKS='scripts/services-start scripts/service-event'
CRON_CHANGED=0
WATCHDOG_JOB=''
STATUS_JOB=''

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
  restore_list="$FILES"
  [ "$HOOKS_CHANGED" != 1 ] || restore_list="$restore_list $HOOKS"
  for relative in $restore_list; do
    if [ -f "$BACKUP/$relative.missing" ]; then rm -f "/jffs/$relative"; continue; fi
    [ -f "$BACKUP/$relative" ] || continue
    cp -p "$BACKUP/$relative" "/jffs/$relative.restore" || return 1
    mv "/jffs/$relative.restore" "/jffs/$relative" || return 1
  done
}
finish(){
  result=$?
  trap - EXIT INT TERM
  if [ "$MODIFIED" = 1 ] && [ "$result" != 0 ]; then
    echo "Update mislukt; vorige bestanden herstellen."
    VPNIPC_INTERNAL=1 /jffs/scripts/vpn_ipcatcher.real.sh stop || WAS_RUNNING=0
    if ! restore_files; then
      echo "Herstel mislukt. Backup: $BACKUP" >&2
      result=1
      WAS_RUNNING=0
    fi
  fi
  if [ "$SELECTION_CHANGED" = 1 ] && [ "$result" != 0 ]; then
    # A failed wizard can have created our own empty routing rules.
    if [ -s "$ADDON/routing-selection" ] && [ "$(sed -n '3p' "$ADDON/routing-selection")" = managed-v1 ]; then
      policy="$(sed -n '1p' "$ADDON/routing-selection")"
      sed '/^case "${1:-check}" in/,$d' "$STAGE/addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh" > "$STAGE/routing-library"
      sh -c '. "$1"; remove_managed_rules "$2"' sh "$STAGE/routing-library" "$policy" || result=1
    fi
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
  if [ "$CRON_CHANGED" = 1 ] && [ "$result" != 0 ]; then
    cru d vpn_ipcatcher_watchdog >/dev/null 2>&1 || result=1
    cru d vpn_ipcatcher_status >/dev/null 2>&1 || result=1
    [ -z "$WATCHDOG_JOB" ] || cru a vpn_ipcatcher_watchdog "$WATCHDOG_JOB" || result=1
    [ -z "$STATUS_JOB" ] || cru a vpn_ipcatcher_status "$STATUS_JOB" || result=1
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

case "$action" in check-update|update|rollback|migrate) ;; *) fail "Onbekende actie: $action" ;; esac
if [ "$action" = migrate ]; then
  [ "$#" = 3 ] && valid_repo "$2" && valid_ref "$3" || fail 'Gebruik: migrate eigenaar/repository commit'
  [ -s "$ENGINE" ] && [ -s /jffs/scripts/vpn_ipcatcher.real.sh ] && [ -f /jffs/scripts/vpn_ipcatcher.conf ] || fail 'Oude engine/configuratie ontbreekt.'
  [ ! -s "$ADDON/vpn_ipcatcher_update.sh" ] && [ ! -e "$ADDON/routing-selection" ] || fail 'Gebruik update voor een installatie met updater/VPN-selectie.'
fi
STAGE="/tmp/vpn_ipcatcher_update-$(date +%Y%m%d-%H%M%S)-$$"
mkdir "$STAGE"

if [ "$action" = rollback ]; then
  [ -f "$ADDON/last-backup" ] || fail "Geen backup beschikbaar."
  BACKUP="$(cat "$ADDON/last-backup")"
  case "$BACKUP" in "$ADDON"/backups/update-*) ;; *) fail "Ongeldig backuppad." ;; esac
  [ -d "$BACKUP" ] || fail "Backup ontbreekt."
  if [ -f "$BACKUP/legacy-migration" ]; then
    fail "Dit is een legacy-migratiebackup. Gebruik de volledige prive-back-up voor herstel van de oude addon en hooks; menu-rollback is alleen voor gewone updates."
  fi
  for relative in $FILES; do
    [ ! -f "$BACKUP/$relative.missing" ] || continue
    [ -s "$BACKUP/$relative" ] || fail "Backup is onvolledig: $relative"
    case "$relative" in *.sh) sh -n "$BACKUP/$relative" || fail "Ongeldige backup: $relative" ;; esac
  done
else
  for program in curl jq sha256sum; do find_on_path "$program" >/dev/null || fail "$program ontbreekt (installeer via Entware)."; done
  if [ "$action" = migrate ]; then repo="$2"; ref="$3"
  else
    [ -f "$SOURCE" ] || fail "Stel eerst update-source in met je GitHub repository en branch/tag."
    repo="$(sed -n '1p' "$SOURCE")"
    ref="$(sed -n '2p' "$SOURCE")"
  fi
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
  backup_mode=small
  [ "$action" != migrate ] || backup_mode=full
  if [ "$action" = migrate ]; then
    sh "$STAGE/scripts/vpn_ipcatcher.real.sh" validate-config || fail 'De oude configuratie is niet compatibel; niets vervangen. Pas geen instellingen blind aan.'
  fi
  sh "$STAGE/addons/vpn_ipcatcher.d/vpn_ipcatcher_backup.sh" "$backup_mode" --update-owner "$$"
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
        *) [ "$action" = migrate ] || fail "Huidige installatie onvolledig: $relative" ;;
      esac
      : > "$BACKUP/$relative.missing"
      continue
    fi
    cp -p "/jffs/$relative" "$BACKUP/$relative"
  done
  if [ "$action" = migrate ]; then
    : > "$BACKUP/legacy-migration"
    for relative in $HOOKS; do
      mkdir -p "$BACKUP/$(dirname "$relative")"
      if [ -e "/jffs/$relative" ]; then cp -p "/jffs/$relative" "$BACKUP/$relative"
      else : > "$BACKUP/$relative.missing"; fi
    done
  fi
fi

[ ! -f "$ADDON/updating" ] || fail "Een update of herstel staat al als actief geregistreerd."
[ ! -f "$DISABLED" ] || WAS_DISABLED=1
pid="$(cat /tmp/vpn_ipcatcher_pids/engine.pid 2>/dev/null || true)"
case "$pid" in ''|*[!0-9]*) ;; *) if kill -0 "$pid" 2>/dev/null; then WAS_RUNNING=1; fi ;; esac
: > "$ADDON/updating"
OWN_UPDATE=1
if [ "$action" = migrate ]; then
  WATCHDOG_JOB="$(cru l | awk '/#vpn_ipcatcher_watchdog#$/ {sub(/[[:space:]]*#vpn_ipcatcher_watchdog#$/, ""); print}')"
  STATUS_JOB="$(cru l | awk '/#vpn_ipcatcher_status#$/ {sub(/[[:space:]]*#vpn_ipcatcher_status#$/, ""); print}')"
  case "$WATCHDOG_JOB$STATUS_JOB" in *'
'*) fail 'Meerdere watchdog-cronregels gevonden; migratie afgebroken.' ;; esac
  CRON_CHANGED=1
  cru d vpn_ipcatcher_watchdog
  cru d vpn_ipcatcher_status
fi
"$ENGINE" stop
if [ "$action" != rollback ] && [ ! -f "$ADDON/routing-selection" ]; then
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
    mkdir -p "/jffs/$(dirname "$relative")"
    cp "$STAGE/$relative" "/jffs/$relative.new"
    case "$relative" in *.sh) chmod 755 "/jffs/$relative.new" ;; *) chmod 644 "/jffs/$relative.new" ;; esac
    mv "/jffs/$relative.new" "/jffs/$relative"
  done
fi
if [ "$action" = migrate ]; then
  HOOKS_CHANGED=1
  sh "$ADDON/install_vpn_ipcatcher.sh" hooks
  # An unrecognized legacy running state stays stopped until explicit Start.
  [ "$WAS_RUNNING" = 1 ] || WAS_DISABLED=1
fi
# Check startup before accepting the new files; finish restores them on failure.
if [ "$WAS_RUNNING" = 1 ]; then
  VPNIPC_INTERNAL=1 /jffs/scripts/vpn_ipcatcher.real.sh start
fi
if [ "$action" = migrate ]; then
  cru a vpn_ipcatcher_watchdog '* * * * * /jffs/scripts/vpn_ipcatcher_watchdog.sh'
  "$ADDON/vpn_ipcatcher_webui.sh" cron
fi
MODIFIED=0
if [ "$action" != rollback ]; then printf '%s\n' "$BACKUP" > "$ADDON/last-backup"; fi
"$ADDON/vpn_ipcatcher_webui.sh" mount || echo "WebUI mount niet gelukt; controleer doctor."
echo "Bestanden bijgewerkt. Persoonlijke configuratie behouden."
