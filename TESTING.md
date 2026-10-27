# Release Verification / Releasecontrole

## 2.9.15 watchdog PID regression

`tests/watchdog-pid-checks.sh` loads the production engine loop and runs it through three mocked iterations, checking `engine.pid` and lock never change to invalid text. It also checks that cleanup from a non-owner process preserves newer PID/worker files, and that watchdog rejects malformed, dead and unrelated PID references. Live ASUS validation remains necessary, ideally observe at least two watchdog cron invocations before declaring stability.


## 2.9.14 explicit VPN priority

`tests/force-vpn-routing-checks.sh` verifies EPG URL-to-host conversion, never stores tokens, refuses invalid/personal-credential URLs, requires the selected VPN and a resolved DVR policy IPSet, and detects conflicting cross-policy assignments. `tests/routing-checks.sh` covers the existing DVR adapter; `tests/managed-routing-checks.sh` validates that automatic managed MARK rules only mark unmarked traffic and that both old and new managed rules are removed when changing VPN. This is a mocked CI test, not proof of live VPN tunnel routing; verify on ASUS after update.


## 2.9.13 provider-owned ranges

`tests/provider-range-checks.sh` uses mocked HTTPS/RIPE responses and kernel-IPSet commands; confirms selected providers, daily refresh interval, fallback after failure, refusal of corrupt/overbroad prefixes, batch import, and no block for unrelated unknown IPTV destinations. GitHub CI cannot establish live ASN API availability, ASUS ipset compatibility or playback stability; validate on router before general rollout.


## 2.9.12 Google/YouTube false-positive protection

`tests/known-service-guard-checks.sh` ensures `136.22.151.14` is rejected before learning, range boundaries are respected, and a different unknown IPTV destination still can be learned. CI validates both registries; on-router validation is still required. Be careful: existing previously learned final-IPSet members stay active until cleanup/timeout.


## 2.9.11 Partial preset persistence

Frontend regression verifies a partially selected Google Play preset becoming fully selected, a one-field upload and status remaining fully selected after reload. Backend regression verifies the persisted four-host list and unchanged streaming/source config values. Tests cannot guarantee a Google Play download works through the live network.


## v2.9.10

Run `tests/webui-stream-ack-checks.sh` and existing WebUI tests. The actual router requires verification.


## 2.9.9 WebGUI status lock recovery

`tests/webui-lock-checks.sh` verifies a live PID lock is preserved, an orphan lock with no PID is reclaimed, dead-PID recovery works, unknown lock-directory contents are left alone, status publication does not silently return success on lock contention, and a recovered publication creates valid JSON. The existing WebUI backend fixture still checks status schema and escaped strings. Final live-router verification is required.


## 2.9.8 Google Play selectable presets

`tests/google-play-presets-checks.sh` checks the four Google Play hostnames, shared WebUI/amtm preset registry, opt-in default state, partial/full selection, unrestricted source IPs and cached-IP exclusions. No WAN override is added or asserted; validate router behavior separately.


## 2.9.7 Lifecycle Diagnostics

Fixtures verify lifecycle request/recovery logs and intentional-stop/update guards.
A secret test argument must never appear in the log. Process labels expose only
bounded process names and selected local script basenames, never complete argv
or environment contents. Signal context is not represented as sender attribution.
No test or change disables Skynet, modifies its schedule or bypasses its rules.

## 2.9.6 Routing Diagnostics

Regression fixtures verify immediate prepare/check error details, duplicate
suppression for five minutes, immediate changed-error reporting and one recovery
message. A failed prepare still removes routing readiness even if the additional
read-only check succeeds. Errors stay in the local log, with no external upload.

## 2.9.5 Hotfix

The 2.9.4 fixtures did not require the simulated engine to validate the internal
start marker. A live-router report exposed that gap. The updater now exports
`VPNIPC_INTERNAL=1` explicitly inside a subshell, not via an assignment on a shell
function. The regression fixture requires that marker while the update guard
still exists, then verifies rollback and failed-start recovery too.

This test is deliberately stricter than the previous successful no-op engine
fixture. Synthetic tests still do not replace actual BusyBox/router validation.

## Scope

Version 2.9.4 is a maintenance release. The public GitHub tree was compared with
the local source before editing: all 36 existing public files matched exactly.
No router configuration, diagnostic export, backup, screenshot or firmware file
is part of the publication allowlist.

The release workflow checks shell syntax, executes all shell fixtures and the
WebUI JavaScript tests, builds both packages and verifies the committed runtime
SHA-256 manifest. A failed check prevents publication. Pull requests run tests
but cannot publish a release through this workflow.

## Reproduce

From the repository root, with POSIX sh, Node.js and the standard tools used by
the fixtures available:

```sh
for script in install.sh backup.sh scripts/vpn_ipcatcher*.sh addons/vpn_ipcatcher.d/*.sh tests/*-checks.sh; do
  sh -n "$script" || exit 1
done
for test in tests/*-checks.sh; do
  sh "$test" || exit 1
done
node tests/webui-checks.js
```

Build packages with PowerShell using `./tools/build-release.ps1`. The builder
uses an explicit public-file allowlist, never the whole working directory.

## Covered Behaviors

- Download checksums, corrupt-update rejection and configuration preservation.
- Mandatory private backups, confirmed cleanup and previous-version recovery.
- Failed startup/hook installation and interrupted legacy-routing recovery.
- Intentional Stop, watchdog crash recovery and reboot behavior.
- VPN/list binding, managed marking rules and firewall hook idempotence.
- Active-connection protection and shared conntrack snapshots.
- Safe configuration parsing, empty exclusions, removed keys and decimal timers.
- Effective engine defaults in the WebUI for minimal first-install configs.
- Removed exclusion domains no longer taking effect through old DNS cache rows.
- Escaped HTML/JSON, language parity, preset parts, filters and table sorting.
- Bounded device diagnostics, DNS metadata, pause, retained history and export.
- Opt-in amtmupdate protocol and refusing automatic downgrades/reinstalls.

Local browser checks additionally exercised desktop (1440px) and mobile (390px)
views with synthetic data: controls, presets, language, routing/update actions,
diagnostic history, sticky headers, sorting and scroll retention. These browser
checks are separate from the Node.js tests in GitHub Actions.

## Limits / Grenzen

Fixtures use synthetic router files and commands. They do not prove the actual
VPN egress, tunnel recovery, firmware behavior, all browser versions or packet
visibility on a real router. No claim is made that all IPTV services work or
that websites will accept the VPN exit IP.

Op de router: controleer na bijwerken het versienummer, **6 > 2** (VPN/lijst),
**7 > 1** (systeemcontrole), de WebUI met Ctrl+F5 en een echte afspeelsessie.
Een gewone update bewaart de configuratie en maakt vooraf een lokale back-up.
Reset de configuratie niet om alleen deze onderhoudsrelease te installeren.

Cloudflare/websiteblokkades worden niet automatisch herkend of omzeild. Er is
geen stilzwijgende WAN-fallback of nieuwe standaarduitsluiting toegevoegd.
Diagnosegegevens worden niet naar GitHub of een externe analysedienst gestuurd.
