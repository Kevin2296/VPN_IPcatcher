<div align="center">

# VPN IP Catcher

### Observe. Learn. Route.

IPv4 learning for your Asuswrt-Merlin VPN routing.

![Version 2.7.1](https://img.shields.io/badge/version-2.7.1-087F8C?style=for-the-badge)
![Asuswrt Merlin](https://img.shields.io/badge/platform-Asuswrt--Merlin-30363D?style=for-the-badge)
![POSIX Shell](https://img.shields.io/badge/runtime-POSIX%20shell-476A30?style=for-the-badge)
![Router validation required](https://img.shields.io/badge/status-router%20validation%20required-B45309?style=for-the-badge)

[Nederlands](README.md) | **English**

[Install](#first-installation) &nbsp; / &nbsp; [Update](#updates) &nbsp; / &nbsp; [Restore](#backup-and-rollback) &nbsp; / &nbsp; [Troubleshooting](#video-stops-during-playback)

</div>

---

## At a glance

VPN IP Catcher observes traffic, learns suitable IPv4 addresses and adds them
to an existing Domain-based VPN Routing (DVR) list on Asuswrt-Merlin. The routing
addon chooses the VPN exit. IP Catcher itself is not a VPN client.

**Version: 2.7.1.** [Changelog, Dutch](CHANGELOG.md) |
[Releases](https://github.com/Kevin2296/VPN_IPcatcher/releases)

> **Ready for controlled router testing.** Local tests do not prove complete
> compatibility or the actual traffic path on your router. This is not a VPN
> kill switch or an officially listed amtm addon.

| Component | What to expect |
| --- | --- |
| VPN selection | Choose an existing OpenVPN/WireGuard client and DVR policy |
| Learning | Evaluate IPv4 candidates using configured age/byte thresholds |
| Routing checks | Check tools, list binding, marks, routing table and tunnel |
| Recovery | Keep previous program files locally and restore them |
| Watchdog | Recover crashes; respect manual Stop until Start or reboot |
| Privacy | No router configurations, keys or logs in this repository |

```text
LAN traffic  -->  IP Catcher  -->  existing DVR list  -->  selected VPN
                     |
                routing checks
```

## Requirements

- Asuswrt-Merlin with JFFS custom scripts and configs enabled.
- A working OpenVPN or WireGuard client and an existing DVR policy.
- An IPv4 `hash:ip` set supporting `timeout`, `counters` and `comment`.
- `ip`, `iptables`, `ipset`, `tcpdump`, `nslookup`, `awk`, `sed`, `grep`, `tr`, `cru`.
- For full learning/updates: `conntrack`, `curl`, `jq`, `sha256sum`.
- Conntrack accounting, a correct router clock and HTTPS certificates.
- For the WebUI: Merlin Addons helper and an existing Addons menu.

Missing tools are reported; install them through Entware/amtm. The installer
does not configure VPN credentials or rebuild incompatible IPSets. Scripts use
`/bin/sh`, without bundled architecture-specific binaries.

## First installation

Open an interactive SSH session on the router, for example using MobaXterm.
Use this only when VPN IP Catcher is not already installed:

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh install
```

Choose the VPN client, DVR policy and LAN observation interface(s). The installer
checks the list binding, firewall marks, routing table and tunnel before learning.
Do not use `curl | sh`: the wizard needs interactive input. The installation
prompts and router menu are currently Dutch; these language links select documentation.

A first installation is not fully transactional. Files remain after an interrupted
installation or cancelled wizard. Fix the cause and resume using:

```sh
sh /jffs/addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh
```

## Updates

For an existing installation with the safe updater (2.6.0 or later):

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh update
```

The first upgrade to 2.7.0 asks for your VPN/list selection. Subsequent updates
can run from the menu or directly:

```sh
/jffs/scripts/vpn_ipcatcher.sh check-update
/jffs/scripts/vpn_ipcatcher.sh update
```

The updater uses an immutable GitHub commit, SHA-256 checks and shell syntax
validation before stopping the app. You still trust this repository: hashes are
not independent digital signatures. Publishing on GitHub does not automatically
execute an update on your router.

Old installations without the safe updater are rejected. Back up program files,
configuration and affected hooks privately before manual migration. Place the
verified program package under `/jffs`, make shell files executable and run the
installer. Do not overwrite an old installation with the first-install command.

## Backup and rollback

Before testing, make a private manual backup over SSH:

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/backup.sh -o /tmp/vpn_ipcatcher_backup.sh && sh /tmp/vpn_ipcatcher_backup.sh
```

The command prints the archive path under `/jffs/vpn-ipcatcher-backups/`. Open
that folder in MobaXterm's SFTP sidebar and download the `.tar.gz` to your PC.
It includes IP Catcher addon directories, settings, present affected hooks and
DVR configuration/code. **Private archive: never upload it to GitHub.** It is
not a full nvram/router backup. Check JFFS space; existing addon backups can make
the archive larger. Do not blindly restore it over a running installation.
Rollback below uses the separate automatic program backup.

Each update saves the previous **program files** locally under:

```text
/jffs/addons/vpn_ipcatcher.d/backups/update-<date>-<time>-<pid>/
```

`last-backup` points to the backup from the last successful update. Restore it:

```sh
/jffs/scripts/vpn_ipcatcher.sh rollback
```

Normal updates and rollback do not replace configuration. This is not a full
router/configuration backup. The installer separately backs up startup hooks
it changes. During the first VPN/list migration, the previous configuration is
also saved locally for failure recovery.

Failed startup during an update automatically restores the previous code. A
deliberately stopped app stays stopped. Power loss cannot be recovered by a
running shell: inspect backups, locks and `updating` before resuming. Do not
blindly delete markers. Backups are not automatically pruned; monitor JFFS free
space and maintain your own router backup as well.

## Controls and amtm

```sh
/jffs/scripts/vpn_ipcatcher.sh
/jffs/scripts/vpn_ipcatcher.sh start
/jffs/scripts/vpn_ipcatcher.sh stop
/jffs/scripts/vpn_ipcatcher.sh status
/jffs/scripts/vpn_ipcatcher.sh doctor
/jffs/scripts/vpn_ipcatcher.sh routing-check
/jffs/scripts/vpn_ipcatcher.sh routing-setup
```

Stop suppresses the watchdog until Start/Restart or reboot. Reboot enables
automatic startup; unexpected crashes are checked roughly once per minute.
Failed routing checks prevent new additions to the final list. Existing VPN
routing is not disabled by these checks.

Add `/jffs/scripts/vpn_ipcatcher.sh` through amtm's personal-script feature.
The amtm update manager does not automatically manage this personal script.
[Official amtm documentation](https://github.com/RMerl/asuswrt-merlin.ng/wiki/AMTM).

## Video stops during playback

**Since 2.7.1:** new final destinations wait in the unrouted
`<final-list>_wait` IPSet while conntrack shows a connection to that address.
Checks cover all clients/ports and TCP/UDP. Once idle, routing and exclusions
are checked again before addition. Existing final members can be refreshed
without introducing a new route. Failed conntrack checks defer new additions.

This reduces the suspected mid-stream route change caused by IP Catcher, but
is not complete connection pinning: a new connection can start between checking
and adding. Other addons, existing final entries, expiring lists, VPN outages
and IPv6 may still affect routing. Learning into the final list may be slower;
retry the site after closing the first session. Only previously qualified
addresses enter the waiting list.

A stream stopping after about a minute does not prove the website blocks VPNs.
IP Catcher may add an address to the VPN list after an age/byte threshold. Depending
on firewall rules, this could change routing during an existing stream. This is
a possible cause, not a confirmed diagnosis.

Other possibilities include new CDN addresses, different IPv6/DNS routing,
QUIC/UDP, MTU issues or VPN exit blocking. A browser VPN may use a different
exit or protocol.

Compare the same website with the entire test device routed through the same
router VPN from the start. If that works, investigate dynamic list routing.
A predefined DVR policy may help, but must include relevant CDN domains; start
a new browser session afterwards. Do not blindly clear lists/conntrack entries
or lower learning thresholds: that may cause a route change even sooner.

HTTPS content is encrypted; tcpdump text cannot reliably identify all HTTPS
domains. Conntrack provides byte-based learning data. Hardware acceleration can
reduce visibility. The final IPv4 list does not cover IPv6 learning. Share
diagnostics privately, not in public issues containing IPs, logs or configurations.

## Privacy and releases

Only program code, documentation and tests belong in this repository. No
configuration, keys, logs, VPN selections or router exports. Installation does
not upload your personal router configuration to GitHub.

A version in `VERSION` or a commit is not a GitHub Release. Releases must be
published separately. Until then, installation fetches code from `main`.
The public release description is in [RELEASE-NOTES.md, Dutch](RELEASE-NOTES.md).
Never publish a personal router export as a release asset.

## Tests

```sh
sh tests/engine-checks.sh
sh tests/installer-checks.sh
sh tests/lifecycle-checks.sh
sh tests/path-checks.sh
sh tests/routing-checks.sh
sh tests/update-checks.sh
sh tests/bootstrap-checks.sh
sh tests/stream-safety-checks.sh
sh tests/backup-checks.sh
```

Tests use fixtures and mocked downloads for configuration safety, learning,
stop/crash behavior, routing bindings, corrupt downloads, preserved settings and
rollback. Kernel, WebUI and real VPN traffic require router-side tests.

---

**Language:** [Nederlands](README.md) | English  
[Changelog, Dutch](CHANGELOG.md) / [Release notes, Dutch](RELEASE-NOTES.md) / [Repository](https://github.com/Kevin2296/VPN_IPcatcher)
