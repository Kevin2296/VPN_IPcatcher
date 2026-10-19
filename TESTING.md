# Release Verification / Releasecontrole

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
