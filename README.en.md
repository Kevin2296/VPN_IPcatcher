<div align="center">

# 🛡️ VPN IP Catcher

### 📡 Observe. 🧠 Learn. 🔀 Route.

IPv4 learning for your Asuswrt-Merlin VPN routing.

![Version 2.9.3](https://img.shields.io/badge/version-2.9.3-087F8C?style=for-the-badge)
![Asuswrt Merlin](https://img.shields.io/badge/platform-Asuswrt--Merlin-30363D?style=for-the-badge)
![POSIX Shell](https://img.shields.io/badge/runtime-POSIX%20shell-476A30?style=for-the-badge)
![Router validation required](https://img.shields.io/badge/status-router%20validation%20required-B45309?style=for-the-badge)

🇳🇱 [Nederlands](https://github.com/Kevin2296/VPN_IPcatcher#nederlands) &nbsp; | &nbsp; 🇬🇧 [English](https://github.com/Kevin2296/VPN_IPcatcher#english)

[🚀 Install](#first-installation) &nbsp; / &nbsp; [🔄 Update](#updates) &nbsp; / &nbsp; [💾 Restore](#backup-and-rollback) &nbsp; / &nbsp; [🎬 Troubleshooting](#video-stops-during-playback)

</div>

---

## 🧭 Where would you like to start?

| 🚀 Get started | 🎛️ Everyday use | 🛟 Maintenance |
| :--- | :--- | :--- |
| [First installation](#-first-installation) | [Menu, WebGUI and VPN selection](#en-controls) | [Install updates](#-updates) |
| [Requirements](#-requirements) | [Investigate a stream problem](#-video-stops-during-playback) | [Backup and recovery](#-backup-and-rollback) |
| [Download a release](https://github.com/Kevin2296/VPN_IPcatcher/releases) | [Nederlands, on the project page](https://github.com/Kevin2296/VPN_IPcatcher#nederlands) | [Privacy and security](#-privacy-and-releases) |

> 🏠 **Your router, your data.** Diagnostics and backups stay local.
> 🔀 **You choose the VPN.** The catcher learns destinations, not your username or password.
> 🧩 **Browser or amtm.** One configuration, without manually creating temporary lists.

## ✨ At a glance

VPN IP Catcher observes traffic, learns suitable IPv4 addresses and automatically
manages a corresponding list and its own routing rules. It uses your router/DVR
VPN routing tables. IP Catcher itself is not a VPN client.

**Version: 2.9.3.** [Changelog, Dutch](CHANGELOG.md) |
[Releases](https://github.com/Kevin2296/VPN_IPcatcher/releases)

> [!IMPORTANT]
> **Ready for controlled router testing.** Local tests do not prove complete
> compatibility or the actual traffic path on your router. This is not a VPN
> kill switch or an officially listed amtm addon.

| Component | What to expect |
| --- | --- |
| 🔀 VPN selection | Choose a working VPN by number; automatic if only one is available |
| 📋 Lists | Automatically reuse a suitable list or create a dedicated one |
| 🧠 Learning | Evaluate IPv4 candidates using configured age/byte thresholds |
| 🔎 Routing checks | Check tools, list binding, marks, routing table and tunnel |
| 💾 Recovery | Keep previous program files locally and restore them |
| 🔄 Watchdog | Recover crashes; respect manual Stop until Start or reboot |
| 🔒 Privacy | No router configurations, keys or logs in this repository |

```text
LAN traffic  -->  IP Catcher  -->  automatic list  -->  selected VPN
                     |
                routing checks
```

## 🧰 Requirements

**Short version:** run the installation/update command, choose a VPN number if
needed, done. No list names or LAN settings to enter. Set up your router VPN,
Entware and DVR once; the script remembers your choice afterwards.

- Asuswrt-Merlin with JFFS custom scripts and configs enabled.
- A configured, connected OpenVPN/WireGuard client and an enabled DVR addon.
- Entware on USB storage for any missing packages.
- `ip`, `iptables`, `ipset`, `tcpdump`, `nslookup`, `awk`, `sed`, `grep`, `tr`, `cru`.
- For full learning/updates: `conntrack`, `curl`, `jq`, `sha256sum`.
- Conntrack accounting, a correct router clock and HTTPS certificates.
- For the WebUI: Merlin Addons helper and an existing Addons menu.

Missing `tcpdump`, `conntrack` and `jq` are installed using your existing Entware.
Missing router tools are reported. VPN credentials, Entware storage and DVR
require one-time setup; these are not blindly changed. No manual list creation
is needed. Incompatible existing lists are left intact. Scripts use
`/bin/sh`, without bundled architecture-specific binaries.

<a name="first-installation"></a>

## 🚀 First installation

Open an interactive SSH session on the router, for example using MobaXterm.
Use this only when VPN IP Catcher is not already installed:

1. Enable SSH and **JFFS custom scripts/configs** under ASUS **Administration > System**. Keep SSH LAN-only.
2. Ensure Entware and Domain VPN Routing are installed. Configure and connect your VPN in ASUS first.
3. Connect MobaXterm to the router using SSH and run the installation command below.
4. Choose an active VPN when the wizard offers multiple choices. Lists and LAN are configured automatically.
5. Open `/jffs/scripts/vpn_ipcatcher.sh`. Choose **7 > 1** for system checks and **6 > 2** for VPN checks.
6. Choose **7 > 5** to register IP Catcher as a personal script in amtm.
7. Open ASUS **Addons > vpn_ipcatcher**. Check the version and use Ctrl+F5 after updating.
8. Optionally restrict **Configuration > Source IPs** to media devices, save and test a stream. Updates preserve these settings.

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh install
```

Choose only your VPN's number; one working VPN is selected automatically.
Lists and LAN settings are managed and checked automatically. You do not need
to type policy or interface names.
Do not use `curl | sh`: the wizard needs interactive input. The installation
prompts and router menu are currently Dutch; these language links select documentation.

A first installation is not fully transactional. Files remain after an interrupted
installation or cancelled wizard. Fix the cause and resume using:

```sh
sh /jffs/addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh
```

<a name="updates"></a>

## 🔄 Updates

**Upgrading 2.8.0 to 2.8.1 or newer:** use the README update command once to install the
new backup/amtm helpers. Future updates can use the menu.

For an existing installation with the safe updater (2.6.0 or later):

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh update
```

Initial setup asks for at most a VPN number. Updates preserve that choice and
your settings without new list questions. Subsequent updates
can run from the menu or directly:

```sh
/jffs/scripts/vpn_ipcatcher.sh check-update
/jffs/scripts/vpn_ipcatcher.sh update
```

The updater uses an immutable GitHub commit, SHA-256 checks and shell syntax
validation before stopping the app. You still trust this repository: hashes are
not independent digital signatures. Publishing on GitHub does not automatically
execute an update on your router.

**Old installation without an updater?** Create a private backup using `backup.sh`
and download it to your computer. Then run the dedicated migration once:

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh migrate
```

Migration verifies downloads, creates a full private backup, asks which active
VPN to use and installs missing helpers. Other settings are preserved; the chosen
VPN/list and LAN setting are updated. The old hyphenated directory is retained.
Failures while replacing files restore the previous files and modified hooks.
A stopped or unrecognized engine stays off until you select **Start**.
Future updates work through the menu. **Returning to the legacy addon requires
the full private backup; menu rollback is only supported for ordinary updates.**
Do not overwrite an existing installation with the first-install command.

<a name="backup-and-rollback"></a>

## 💾 Backup and rollback

**No command needed:** open the IP Catcher menu and select **7 > 2 · Maak back-up**:

- **1 · Small:** program code, settings, VPN selection, update source and existing hooks.
- **2 · Full:** also both addon directories/history and DVR configuration/code.

Installation backs up existing files/hooks before placing the addon. Every
update automatically creates a small private archive and separately preserves
the previous program version for menu **7 > 4**. A completely empty first install
has nothing to back up. Backup failures stop the update. Archives stay under
`/jffs/vpn-ipcatcher-backups/`, never on the public WebUI path. They are not
automatically pruned; monitor JFFS space and keep important copies on your PC.

For older installations without this menu option:

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/backup.sh -o /tmp/vpn_ipcatcher_backup.sh && sh /tmp/vpn_ipcatcher_backup.sh
```

The command prints the archive path under `/jffs/vpn-ipcatcher-backups/`. Open
that folder in MobaXterm's SFTP sidebar and download the `.tar.gz` to your PC.
It includes IP Catcher addon directories, settings, present affected hooks and
DVR configuration/code. **🔒 Private archive: never upload it to GitHub.** It is
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
Since 2.8.0 every update backup also includes private snapshots of configuration,
VPN selection and update source. Rollback does not automatically restore settings.

Failed startup during an update automatically restores the previous code. A
deliberately stopped app stays stopped. Power loss cannot be recovered by a
running shell: inspect backups, locks and `updating` before resuming. Do not
blindly delete markers. Backups are not automatically pruned; monitor JFFS free
space and maintain your own router backup as well.

<a name="en-controls"></a>

## 🎛️ Controls and amtm

Choose **7 > 5 · Toevoegen aan amtm** to register IP Catcher as a personal script.
Existing entries are preserved; duplicates and the four-slot limit are checked.
Reopen amtm to see it under `p1`–`p4`. Update amtm first if unsupported.
This is not an official amtm addon. Its own updater manages updates.

### 🔄 amtm AU

`au` manages automatic updates for the supported scripts shown by amtm.
Option **1** configures the schedule, **2** enables/disables participation,
**3** shows the update log and **4** resets the supported-script list.
Registration under `p1`–`p4` does not automatically provide AU support.
Version 2.9.1 supports the `amtmupdate` protocol, disabled by default. Opt in through
WebUI > Maintenance or `vpn_ipcatcher.sh auto-update enable`. This does **not** enroll
the addon in the central amtm AU catalog; enrollment requires the amtm maintainer.
No independent schedule is created. Automatic updates only install a higher version,
with a mandatory local backup. Manual browser and terminal updates remain available.
See the [amtm maintainer's guide](https://www.snbforums.com/threads/automatic-script-updates-a-guide-for-script-developers-of-how-to-add-amtmupdate-support-into-scripts-deadline-set-to-july-7-2026.97061/).

### 🖥️ Dashboard 2.9.0

### 🧭 Browser controls from 2.9.1

- **Maintenance:** check, install or reinstall an update with confirmation and a
  mandatory backup before changes. The progress indicator shows activity, not an ETA.
- **Domain routes:** enter a domain without URL/credentials and choose an existing
  DVR policy. After confirmation: local full backup, DVR `adddomain`, then `querypolicy`.
  The adapter is verified against DVR **v3.2.5**; unknown versions are refused.
  Existing connections may change route. Managed temporary `VIPC-*` sets are not
  permanent DVR policies and do not appear in this picker.
- **Presets > Details:** select individual domains/IPs/networks. Shared entries affect
  multiple presets; protected resolver IPs cannot be removed here.
- **Help:** explains learning lists, exclusions, routing and diagnostics.

**Candidate:** discovered, under assessment. **Waiting:** eligible but existing
connections to that destination must end before changing the route. **Final:**
currently in the VPN IPSet, still subject to TTL expiry, not permanent.

**DNS names:** visible DNS from the selected device during measurement provides
hints. Cached/encrypted DNS or direct-IP URLs may have no name. Capture status now
reports missing tools and failures; TCP and UDP port 53 are observed. No upload or
external reverse lookup is performed. Paused diagnostics retain their scroll position.

**Merlin 3006.102.9 / RT-AX86U Pro:** the supplied archive and its internal firmware
checksum were checked. Its changelog includes amtm 7.0, OpenVPN 2.7.7 and OpenSSL
3.5.8. Source/mock checks do not replace hardware tests. After upgrading, test system
and VPN checks, WebUI saving and diagnostics. No firmware was flashed; full hardware
compatibility is not guaranteed.

**Diagnostics:** open Live view > Diagnostics, select an online IPv4 device
from the ASUS list or enter its IP manually, then choose Start 2 minutes.
Router confirmation, errors and active empty snapshots have separate states.
Connection snapshots refresh every five seconds
while this tab is open, on all ports and without requiring byte counters.
Stop ends the session without deleting results. No VPN or configuration changes.
Short connections between snapshots and IPv6 are not fully covered.
More than 2000 connections for the device produce a truncation notice.
The local WebUI displays metadata only, never URLs or payloads. Do not publish
diagnostic screenshots on public GitHub.

**New in 2.9.0:** timestamped history, channel/event markers, pause/resume and
JSON export. Resume starts a new bounded two-minute measurement while retaining
history. Stop and expiry keep results; only the last 2000 observations remain
in the open page. Export before reloading/closing it. Timestamps identify when
an observation was made, not when a connection originally started.

Optional tcpdump/timeout collection observes only plain UDP-DNS for the selected
IPv4 device, limited to two minutes or 400 packets. It retains timestamp, domain
and answer IP only, not packet files, URLs or credentials. Domains are hints,
not proof of service identity; shared CDN addresses, cached/encrypted DNS and
TCP-DNS can leave names unknown. IP snapshots still work without DNS tools.
Exports are private metadata: never upload them to public GitHub.

**Keep scroll position** is enabled by default in all live tabs.
**7 > UC** checks for updates, **7 > U** confirms installation and mandatory
private backup, **FU** reinstalls the same version for repair. Progress follows
installation phases, not an estimated completion time. Ordinary updates now
refresh ASUS event hooks too.

**Backup management (7 > 3):** list archive names/dates and sizes, delete a selected
archive, keep the five newest small archives, or clean old program snapshots.
Deletion requires confirmation. Full archives are not automatically pruned.
Program cleanup preserves the two newest snapshots, the active rollback point
and legacy migrations. Cleanup is manual, not an automatic retention schedule.

Live view supports search and source-device, port and list-status filters.
Search also works in the other live views. Filters persist across refreshes
and affect the display only, never VPN routing.

Version, selected VPN and list appear at the top. The main menu has a compact
service summary; **4 > 1** shows full details. The WebUI groups settings and collapses
advanced fields and preset details. **Excluded** means a service is not learned
by IP Catcher, not that it is sent through the VPN. Unsaved changes are visible.
Use **6 > 1 · VPN kiezen** to select another VPN already configured in the ASUS client.

### ⚙️ Defaults and choosing a profile

There is no universally best configuration. These are new-install defaults;
updates preserve your settings. The wizard selects LAN and VPN/list. Source IPs
are empty by default (all devices).

| Setting | Built-in default |
| --- | --- |
| Promotion mode | `auto`: bytes with working conntrack accounting, otherwise age |
| Promotion interval / minimum age | 15 s / 30 s |
| Minimum candidate bytes | 1000000 B (1 MB) |
| Stream scan / target / interval | Enabled / candidate / 5 s |
| Stream threshold / minimum growth per scan | 15000000 B (15 MB) / 750000 B (750 KB) |
| Growth required | Yes |
| Candidate / final expiry | 10 minutes / 7 days |
| Exclusion resolver / interval | Enabled / 1 hour |
| Generic scan / external DNS / reverse DNS | Disabled / disabled / disabled |
| Ports | 80,443 |

**bytes** requires sufficient traffic and minimum age; **age** only minimum age;
**immediate** makes an IP eligible immediately. Existing connections are still
protected from switching routes mid-session. Stream scanning also has separate
thresholds; promotion mode is not the only learning setting.

Prefer restricting Source IPs to media devices for targeted IPTV learning.
**Stable TV** learns faster (3 MB); **Cautious** is more conservative (25 MB).
Profiles change several values: back up first and compare Configuration.
Do not blindly expand exclusions; shared CDNs may serve wanted streams too.

**Individual preset entries:** open **Preset lists > Choose individual entries**,
select domains/IPs/ranges and use **Save + restart**. Protected resolver IPs
cannot be unchecked; shared entries may affect multiple presets. If missing,
check the version: at least 2.9.1 is required. Use Ctrl+F5 after updating.

### 📋 Menu and submenus

From 2.9.3: compact submenus and **E** to go back. Updates appear only under
**7 > UC / U / FU**. Older versions still use the long numbered menu.

| Choice | Option | Purpose |
| --- | --- | --- |
| 1 / 2 / 3 | Start / stop / restart | Intentional Stop is respected until Start or reboot |
| 4 | Status and live views | 1 status, 2 activity, 3 log, 4 connections, 5 candidates, 6 VPN destinations, 7 configuration |
| 5 | Settings and presets | 1 guided, 2 profiles, 3 exclusions, 4 manual editing, 5 confirmed reset with backup, 6 cleanup |
| 6 | VPN and routing | 1 select VPN, 2 check VPN/list |
| 7 | Maintenance and updates | UC check, U update, FU reinstall; no duplicate update numbers |
| 7 > 1 | System check | Check router/tools |
| 7 > 2 | Create backup | Small or full |
| 7 > 3 | Manage backups | Inspect and confirm cleanup |
| 7 > 4 | Previous version | Restore previous program files |
| 7 > 5 | Add to amtm | Register a personal script |
| E | Back | Submenu: main menu. Main menu: amtm. Service keeps running |

**Profiles (5 > 2):** 1 Stable TV, 2 Cautious learning, 3 Fast zapping,
4 Analysis/review, 5 Existing list only, 6 Back.

**Guided settings (5 > 1):** 1 Interfaces, 2 IPSet name, 3 Ports, 4 Promotion mode,
5 Minimum age, 6 Minimum bytes, 7 Excluded domains, 8 Excluded IPs, 8b Network ranges,
9 Profiles, 10 Exclusion manager, 11 Timers/cleanup, 12 Generic host scan,
13 External DNS, 14 Streamflow scan, 15 Source IPs, 16 Stream threshold,
17 Stream growth, 18 Stream target, 19 Back. Change VPN via **6 > 1**, not a made-up list name.

**Exclusion manager (5 > 3):** 1 Show all, 2 Safe defaults, 3 DNS, 4 Social/messaging,
5 Camera/IoT, 6 GitHub/dev-CDN, 7 Games, 8 OS/app updates, 9 TV telemetry,
10 Streaming services, 11 Custom domains, 12 Custom IPs, 13 Resolver/cache,
14 Remove excluded addresses, 15 Back. Within a group: numbers toggle services,
`a` add all, `r` remove all, `v` details, `q` back.

### 🧠 Automatic lists

You do **not** create lists manually. Final holds VPN destinations; `_cand`
holds candidates, `_wait` holds qualified destinations with active connections,
and `_exclude` holds excluded ranges. Temporary lists receive no VPN marking.
This does not guarantee every existing connection or video website uses your VPN.

### 🌐 Web interface

Views: Overview, Live view, Configuration, Exclusions, Preset lists. Actions:
Start, Stop, Restart, Refresh, Resolve exclusions, Safe defaults, Repair exclusions,
Clean excluded IPs, Clear log. Live tabs: Flows, Log, Status, Candidate, Waiting,
Final, Resolved IPs, Exclude ranges. Save, Save + restart, Reload and NL/EN/auto
language selection are present. Backup/amtm registration are SSH-menu actions.

Local JavaScript, language and rendering checks are included. Actual Merlin
mounting, saving through `service-event`, and router status still require a
router test. Full WebUI operation is **not yet guaranteed**.

To change VPN later, use the menu or `routing-setup`. Setup automatically reuses
a compatible existing DVR list or creates a dedicated `DVR-VIPC-...-v4` list.
Only its own tagged rules are managed; other DVR policies remain untouched.
The running app repairs missing owned rules automatically. Diagnostic commands
(`doctor`, `routing-check`) remain read-only.

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

<a name="video-stops-during-playback"></a>

## 🎬 Video stops during playback

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

## 🔐 Privacy and releases

When `VERSION` changes, GitHub Actions tests the public code and publishes a
**prerelease** with a version tag, router archive, public source archive and
checksums. Existing releases are not overwritten. It can also be run manually
from Actions. Publishing never updates the router automatically.

Only program code, documentation and tests belong in this repository. No
configuration, keys, logs, VPN selections or router exports. Installation does
not upload your personal router configuration to GitHub.

A version in `VERSION` or a commit is not a GitHub Release. Releases must be
published separately. Until then, installation fetches code from `main`.
The public release description is in [RELEASE-NOTES.md, Dutch](RELEASE-NOTES.md).
Never publish a personal router export as a release asset.

## 🧪 Tests

```sh
sh tests/engine-checks.sh
sh tests/installer-checks.sh
sh tests/lifecycle-checks.sh
sh tests/path-checks.sh
sh tests/routing-checks.sh
sh tests/managed-routing-checks.sh
sh tests/update-checks.sh
sh tests/bootstrap-checks.sh
sh tests/stream-safety-checks.sh
sh tests/backup-checks.sh
```

Tests use fixtures and mocked downloads for configuration safety, learning,
stop/crash behavior, routing bindings, corrupt downloads, preserved settings and
rollback. Kernel, WebUI and real VPN traffic require router-side tests.

---

**🌍 Language:** 🇳🇱 [Nederlands](https://github.com/Kevin2296/VPN_IPcatcher#nederlands) | 🇬🇧 [English](https://github.com/Kevin2296/VPN_IPcatcher#english)  
[Changelog, Dutch](CHANGELOG.md) / [Release notes, Dutch](RELEASE-NOTES.md) / [Repository](https://github.com/Kevin2296/VPN_IPcatcher)
