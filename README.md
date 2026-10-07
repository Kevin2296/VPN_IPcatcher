# VPN IP Catcher 2.7.0

## Routercommando's: eerste installatie of update

Voer dit uit in een interactief SSH-venster op de router, bijvoorbeeld MobaXterm.
Vereist: werkende Domain-based VPN Routing-policy, ingeschakelde JFFS-scripts,
curl, jq en sha256sum. Ontbrekende tools worden gemeld, niet automatisch geinstalleerd.
Gebruik geen `curl | sh`: de installatie heeft je invoer nodig voor de VPN-keuze.

**Eerste installatie (alleen wanneer IP Catcher nog niet is geinstalleerd):**

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh install
```

**Bestaande installatie bijwerken (met veilige updater, versie 2.6.0 of nieuwer):**

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh update
```

De eerste update naar 2.7.0 vraagt om je VPN/lijstkeuze. Configuratie en de bewust
gestopte status blijven behouden. Oudere installaties zonder veilige updater
worden geweigerd: gebruik dan de handmatige migratie hieronder met een back-up.

**Volgende updates kunnen ook direct vanuit het menu of met:**

```sh
/jffs/scripts/vpn_ipcatcher.sh update
```

De download gebruikt HTTPS en de programmacontrole gebruikt SHA-256 en een vaste
GitHub-commit. Dit vertrouwt deze openbare repository; het is geen afzonderlijke
digitale handtekening. De eerste installatie is niet volledig transactioneel:
bij onderbreking of een afgebroken wizard blijven de geplaatste bestanden staan.
Herstel de oorzaak en voer dan de installer onder `/jffs/addons/vpn_ipcatcher.d/`
opnieuw uit. Er worden geen persoonlijke routerbestanden naar GitHub verstuurd.

2.7.0 adds interactive VPN/policy selection during installation and first update.
Choose an existing Domain-based VPN Routing OpenVPN or WireGuard policy, then
the LAN interface(s) to observe. Required tools, policy binding, firewall marks,
routing table, tunnel and IPSet schema are checked before learning starts.
Use the menu or `/jffs/scripts/vpn_ipcatcher.sh routing-setup` to change selection.
The private selection and configuration remain on the router, not in GitHub.

The routing addon must already have a working IPv4 policy with a hash:ip set
supporting timeout, counters and comment. Incompatible existing sets are rejected,
not recreated. This installer does not configure VPN credentials, install DVR,
or rewrite other addons' policies. Learning pauses when routing checks fail;
this is not a VPN kill switch and does not prove every client's traffic path.

2.6.2 makes Stop temporary for the current boot. The watchdog leaves an explicitly
stopped service alone until Start or Restart is selected. Reboot automatically
re-enables startup and crash recovery. The stop marker is stored only in `/tmp`.

2.6.1 fixes executable detection on router shells where `command -v` is not
supported. Diagnostics and updates inspect executable paths directly. The WebUI
also detects cksum without relying on that shell builtin.

Shell addon for Asuswrt-Merlin using the router's POSIX shell.
Router runtime verification is still required; local tests do not prove VPN
traffic actually follows the intended tunnel.

## amtm

VPN IP Catcher is a personal script, not an officially listed amtm addon.
Add `/jffs/scripts/vpn_ipcatcher.sh` using amtm's personal-script feature.
This opens its own menu, including check-update, update, doctor and rollback.
The official amtm update manager does not automatically manage a personal script.
No modification of amtm itself is required.

Reference: https://github.com/RMerl/asuswrt-merlin.ng/wiki/AMTM

## Router requirements

Enable JFFS custom scripts and configs. The engine needs ipset with hash:ip,
timeouts, counters and comments, tcpdump, nslookup, awk, sed and grep.
Byte-based learning needs conntrack and nf_conntrack_acct. Entware supplies
missing binaries for the router architecture. HTTPS updates additionally need
curl, jq, sha256sum and a functioning certificate store and router clock.
The WebUI uses the Merlin helper and requires an existing Addons menu.

The scripts use the router's `/bin/sh`; they do not contain architecture-specific
binaries. HTTPS payload is encrypted: ASCII tcpdump output cannot reliably
extract HTTPS Host/SNI information. The conntrack flow scanner is the main
learning mechanism for encrypted streams, including UDP flows.
Hardware flow acceleration can reduce visibility into packets and byte counters;
validate on the router rather than changing acceleration automatically.

## Run the diagnostic without installing

Upload `addons/vpn_ipcatcher.d/vpn_ipcatcher_doctor.sh` to `/tmp` using MobaXterm:

```sh
sh /tmp/vpn_ipcatcher_doctor.sh
```

This reads information; it does not change settings or start the service.

## Upgrade the existing installation

The provided archive contains only the ten program files. It excludes personal
configuration, startup hooks, logs, keys and unrelated addons. Before installing,
run the diagnostic and make a backup of the existing program files and hooks.
Stop the engine and remove its watchdog cron during the one-time migration.
Extract the archive to `/jffs`, set the shell files executable, then run:

```sh
sh /jffs/addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh
/jffs/scripts/vpn_ipcatcher.sh doctor
/jffs/scripts/vpn_ipcatcher.sh start
```

The installer checks all required program files. It backs up service-event and
services-start, replaces only recognized VPN IP Catcher blocks, and checks hook
syntax before replacement. Other addons remain in those hooks. Existing
`/jffs/scripts/vpn_ipcatcher.conf` is required and preserved. A stopped service
stays stopped across watchdog runs until explicitly started or the router reboots.

## GitHub updates

Publish only the allowlisted program files, VERSION, SHA256SUMS, documentation
and tests. Do not publish the original router export. A public repository is
required by this updater; private-repository authentication is not implemented.
Choose a stable branch or release tag, then configure it once:

```sh
/jffs/scripts/vpn_ipcatcher.sh update-source OWNER/REPOSITORY main
/jffs/scripts/vpn_ipcatcher.sh check-update
/jffs/scripts/vpn_ipcatcher.sh update
```

For this project the configured command is:

```sh
/jffs/scripts/vpn_ipcatcher.sh update-source Kevin2296/VPN_IPcatcher main
```

Repository: https://github.com/Kevin2296/VPN_IPcatcher

Updates also work through
menu items 18 and 19. Publishing a commit to GitHub does not itself execute
commands on the router. Run update over SSH or through the personal script's menu.

The updater resolves the selected ref to one immutable GitHub commit before
downloading. It checks each allowlisted file's SHA-256 hash and shell syntax
before stopping the service. It backs up the program files, preserves config,
and restarts only if the engine was running. Failed startup restores old files.
Hashes detect mismatched/corrupt files; they are not a separate signature and
do not protect against compromise of the trusted repository.

```sh
/jffs/scripts/vpn_ipcatcher.sh rollback
```

Backups are retained under `/jffs/addons/vpn_ipcatcher.d/backups/`; monitor flash
space and remove obsolete backups deliberately. A power interruption cannot
be rolled back by a running shell trap. After an interrupted update, inspect the
backup and `updating` marker before restarting. An abandoned lock with no PID
requires inspection; the code does not automatically erase an unowned lock.

## Validation

```sh
sh tests/engine-checks.sh
sh tests/update-checks.sh
sh tests/lifecycle-checks.sh
sh tests/installer-checks.sh
```

Tests cover non-executable configuration, invalid numeric settings, exclusion
boundaries, capture source filters, stable candidate age, bidirectional byte
promotion, corrupt updates, preserved configuration/stopped state, rollback and
failed-startup recovery. Downloads and router processes are mocked in update tests.
Kernel modules, Merlin WebUI, busybox specifics, VPN routing and accelerated
traffic require router-side verification.
