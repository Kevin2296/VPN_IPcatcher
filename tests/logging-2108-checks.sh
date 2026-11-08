#!/bin/sh
# 2.10.8: syslog level per message and LOG_SYSLOG=all|important.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
work="${TMPDIR:-/tmp}/vpnipc-2108-$$"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
fail(){ echo "FAIL: $*" >&2; exit 1; }
sed '/^case "\$1" in/,$d' "$ROOT/scripts/vpn_ipcatcher.real.sh" > "$work/engine"
(
  set +e
  . "$work/engine"
  set -e
  AWK=awk; SED=sed; GREP=grep; TR=tr; TAIL=tail
  LOGFILE="$work/catcher.log"
  mock_logger(){ printf '%s\n' "$*" >> "$work/syslog"; }
  LOGGER=mock_logger
  # Levels: problems warning, state changes notice, detail info.
  for pair in "warning|LET OP: Entware ontbreekt" "warning|Provider lookup failed for google, existing prefixes retained" \
              "warning|Promote worker is weggevallen; opnieuw starten" "notice|Routingcontrole hersteld; nieuwe IPs mogen weer" \
              "notice|Lifecycle engine=start pid=1" "notice|Finale lijst teruggezet van /jffs: 1 direct" \
              "info|Skip excluded IP final: 1.2.3.4 (x)" "info|Finale lijst bewaard op /jffs: 10 IP's (leden gewijzigd)."; do
    want="${pair%%|*}"; msg="${pair#*|}"
    log_priority "$msg"
    [ "$LOG_PRIO" = "$want" ] || fail "level $LOG_PRIO for: $msg (want $want)"
  done
  # Default (unset) and all: every line to syslog with its level; file gets all.
  unset LOG_SYSLOG
  log "Skip excluded IP final: 1.2.3.4 (x)"
  log "LET OP: Entware ontbreekt"
  grep -q -- '-t vpn_ipcatcher -p user.info Skip excluded IP final: 1.2.3.4 (x)' "$work/syslog" || fail "detail not sent at info"
  grep -q -- '-t vpn_ipcatcher -p user.warning LET OP: Entware ontbreekt' "$work/syslog" || fail "problem not sent at warning"
  # important: detail stays in the file only.
  : > "$work/syslog"; : > "$LOGFILE"
  LOG_SYSLOG=important
  log "Skip excluded IP final: 5.6.7.8 (y)"
  log "Routingcontrole hersteld; nieuwe IPs mogen weer"
  grep -q '5.6.7.8' "$work/syslog" && fail "detail sent with LOG_SYSLOG=important"
  grep -q -- '-p user.notice Routingcontrole hersteld' "$work/syslog" || fail "notice not sent with LOG_SYSLOG=important"
  grep -q '5.6.7.8' "$LOGFILE" || fail "detail missing from the log file"
  # A logger without -p support still logs once.
  : > "$work/syslog"
  strict_logger(){ case "$*" in *" -p "*) return 1 ;; esac; printf '%s\n' "$*" >> "$work/syslog"; }
  LOGGER=strict_logger
  log "Routingcontrole hersteld; test"
  [ "$(grep -c 'Routingcontrole hersteld; test' "$work/syslog")" = 1 ] || fail "fallback logger"
  # Config: key accepted, wrong value rejected.
  CONF="$work/conf"; default_config > "$CONF"
  grep -q '^LOG_SYSLOG="all"$' "$CONF" || fail "default config lacks LOG_SYSLOG"
  load_config >/dev/null 2>&1 || fail "default config rejected"
  [ "$LOG_SYSLOG" = all ] || fail "default value"
  sed 's/^LOG_SYSLOG="all"$/LOG_SYSLOG="important"/' "$CONF" > "$CONF.2" && mv "$CONF.2" "$CONF"
  load_config >/dev/null 2>&1 && [ "$LOG_SYSLOG" = important ] || fail "important not loaded"
  sed 's/^LOG_SYSLOG=.*/LOG_SYSLOG="debug"/' "$CONF" > "$CONF.2" && mv "$CONF.2" "$CONF"
  if load_config >/dev/null 2>&1; then fail "invalid LOG_SYSLOG accepted"; fi
) || exit 1
grep -q 'LOG_SYSLOG) return 0 ;;' "$ROOT/addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh" || fail "WebUI would drop LOG_SYSLOG"
grep -q 'stonden er al' "$ROOT/scripts/vpn_ipcatcher.real.sh" || fail "restore message lacks already-present count"
echo "ALL PASS: logging-2108-checks"
