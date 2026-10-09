<div align="center">

# 🛡️ VPN IP Catcher

### 📡 Observe. 🧠 Learn. 🔀 Route.

IPv4-learning voor jouw Asuswrt-Merlin VPN-routing.

![Version 2.8.4](https://img.shields.io/badge/version-2.8.4-087F8C?style=for-the-badge)
![Asuswrt Merlin](https://img.shields.io/badge/platform-Asuswrt--Merlin-30363D?style=for-the-badge)
![POSIX Shell](https://img.shields.io/badge/runtime-POSIX%20shell-476A30?style=for-the-badge)
![Router validation required](https://img.shields.io/badge/status-router%20validation%20required-B45309?style=for-the-badge)

🇳🇱 [Nederlands](#nederlands) &nbsp; | &nbsp; 🇬🇧 [English](#english)

[🚀 Installeren](#eerste-installatie) &nbsp; / &nbsp; [🔄 Bijwerken](#bijwerken) &nbsp; / &nbsp; [💾 Terugzetten](#back-up-en-terugzetten) &nbsp; / &nbsp; [🎬 Problemen oplossen](#video-stopt-tijdens-afspelen)

</div>

---

<a name="nederlands"></a>

## ✨ In het kort

IPv4-leeraddon voor Asuswrt-Merlin. IP Catcher leert adressen uit verkeer en
regelt automatisch de bijbehorende lijst en eigen routingregels. Het gebruikt
de VPN-routingtabellen van je router/DVR; IP Catcher is zelf geen VPN-client.

**Versie: 2.8.4.** [Wijzigingen](CHANGELOG.md) |
[Releases](https://github.com/Kevin2296/VPN_IPcatcher/releases)

> [!IMPORTANT]
> **Voor een gecontroleerde routertest.** Lokaal getest, maar volledige
> compatibiliteit en de echte verkeersroute moeten op de router worden
> gecontroleerd. Geen VPN-killswitch of officieel amtm-addon.

| Onderdeel | Wat je kunt verwachten |
| --- | --- |
| 🔀 VPN-keuze | Een werkende VPN kiezen met een nummer; bij een VPN automatisch |
| 📋 Lijsten | Automatisch hergebruiken of een eigen lijst maken; geen handwerk |
| 🧠 Leren | IPv4-kandidaten beoordelen op ingestelde leeftijd/bytegrenzen |
| 🔎 Routingcontrole | Tools, lijstkoppeling, markeringen, routingtabel en tunnel controleren |
| 💾 Herstel | Vorige programmacode lokaal bewaren en terugzetten |
| 🔄 Watchdog | Onverwachte crashes herstellen; bewuste Stop respecteren tot Start of reboot |
| 🔒 Privacy | Geen routerconfiguratie, sleutels of logs in deze repository |

```text
LAN-verkeer  -->  IP Catcher  -->  automatische lijst  -->  gekozen VPN
                    |
              routingcontrole
```

## 🧰 Vereisten

**Kort:** start het installatie/updatecommando, kies zo nodig een VPN-nummer,
klaar. Geen lijstnamen of LAN-instellingen invullen. Je router-VPN, Entware en
DVR moeten eenmalig zijn ingesteld; daarna bewaart het script je keuze.

- Asuswrt-Merlin met JFFS custom scripts en configs ingeschakeld.
- Een ingestelde, verbonden OpenVPN- of WireGuard-client en ingeschakelde DVR-addon.
- Entware op je USB-opslag voor eventueel ontbrekende pakketten.
- `ip`, `iptables`, `ipset`, `tcpdump`, `nslookup`, `awk`, `sed`, `grep`, `tr`, `cru`.
- Voor volledige leerfunctie/updates: `conntrack`, `curl`, `jq`, `sha256sum`.
- Conntrack accounting, correcte routerklok en HTTPS-certificaten.
- Voor de WebUI: Merlin Addons-helper en een bestaand Addons-menu.

Ontbrekende `tcpdump`, `conntrack` en `jq` worden via je bestaande Entware
geinstalleerd. Ontbrekende routertools worden gemeld. VPN-providergegevens,
Entware-opslag en DVR moet je eenmalig instellen; dat wordt niet blind gewijzigd.
Je hoeft geen lijst aan te maken. Bestaande onverenigbare lijsten blijven intact.
De code gebruikt `/bin/sh`, zonder architectuurspecifieke meegeleverde binaries.

<a name="eerste-installatie"></a>

## 🚀 Eerste installatie

Open een interactief SSH-venster op de router, bijvoorbeeld MobaXterm.
Alleen uitvoeren wanneer IP Catcher nog niet is geinstalleerd:

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh install
```

Kies alleen het nummer van je VPN. Bij een werkende VPN gaat dat automatisch.
De lijst en LAN-instellingen worden automatisch geregeld en gecontroleerd.
Je hoeft geen policynaam of interface in te typen.
Gebruik geen `curl | sh`: de wizard heeft je invoer nodig.
De taalkeuze op GitHub geldt voor de documentatie; installatievragen en het
routermenu zijn momenteel Nederlands.

Een eerste installatie is niet volledig transactioneel. Na een onderbreking of
afgebroken wizard blijven geplaatste bestanden staan. Herstel de oorzaak en hervat:

```sh
sh /jffs/addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh
```

<a name="bijwerken"></a>

## 🔄 Bijwerken

Voor een bestaande installatie met veilige updater (2.6.0 of nieuwer):

**Van 2.8.0 naar 2.8.1 of nieuwer:** gebruik eenmaal het onderstaande updatecommando om ook
de nieuwe back-up/amtm-helpers te plaatsen. Daarna werkt bijwerken via het menu.

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh update
```

Bij de eerste inrichting kies je hoogstens een VPN-nummer. Updates bewaren deze
keuze en je instellingen; geen nieuwe lijstvragen. Volgende updates kunnen
vanuit het menu of met:

```sh
/jffs/scripts/vpn_ipcatcher.sh check-update
/jffs/scripts/vpn_ipcatcher.sh update
```

De updater gebruikt een vaste GitHub-commit, SHA-256 en shellsyntaxcontrole
voordat de app wordt gestopt. Dit vertrouwt de repository; hashes zijn geen
afzonderlijke digitale handtekening. Publiceren op GitHub voert niet automatisch
een update op de router uit.

**Oude installatie zonder updater?** Maak eerst een prive-back-up met `backup.sh`
en download die naar je computer. Gebruik daarna eenmaal de aparte migratie:

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh migrate
```

De migratie controleert de downloads, maakt een volledige prive-back-up, vraagt
welke actieve VPN je wilt gebruiken en vult ontbrekende helpers aan. Andere
instellingen blijven behouden; de gekozen VPN/lijst en LAN-instelling worden
bijgewerkt. De oude map met een koppelteken blijft staan als referentie. Bij een
fout tijdens vervangen worden de vorige bestanden en aangepaste hooks hersteld.
Een gestopte of niet herkende engine blijft uit: kies daarna zelf **Start**.
Na migratie werken gewone updates via het menu. **Terug naar de oude legacy-addon
vereist de volledige prive-back-up; menu-rollback is alleen voor gewone updates.**
Gebruik niet `install` om een bestaande installatie te overschrijven.

<a name="back-up-en-terugzetten"></a>

## 💾 Back-up en terugzetten

**Geen commando nodig:** open het IP Catcher-menu, kies **24 · Maak back-up**:

- **1 · Klein:** programmacode, instellingen, VPN-keuze, updatebron en aanwezige hooks.
- **2 · Uitgebreid:** ook beide addonmappen, hun historie en DVR-code/configuratie.

Elke installatie bewaart de aanwezige bestanden/hooks voordat de addon wordt
geplaatst; elke update maakt automatisch een kleine privéback-up. Bij een echt
lege eerste installatie is er nog niets om te bewaren. Daarnaast bewaart een
update altijd de vorige programmaversie voor **21 · Restore previous version**.
Bij onvoldoende ruimte of een mislukte back-up gaat de update niet door.

Voor een oude installatie zonder deze menuoptie blijft dit commando beschikbaar:

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/backup.sh -o /tmp/vpn_ipcatcher_backup.sh && sh /tmp/vpn_ipcatcher_backup.sh
```

Het commando toont het archiefpad onder `/jffs/vpn-ipcatcher-backups/`. Open die
map in de SFTP-zijbalk van MobaXterm en download het `.tar.gz`-bestand naar je pc.
Het bevat IP Catcher-addondirectories, instellingen, aanwezige betrokken hooks
en DVR-configuratie/code. **🔒 Dit archief is prive; upload het nooit naar GitHub.**
Het bevat geen volledige nvram/routerback-up. Controleer voldoende JFFS-ruimte;
oude addonback-ups kunnen het archief groter maken. Herstel deze handmatige
snapshot niet blind over een draaiende installatie; rollback hieronder gebruikt
de afzonderlijke, automatische programmaback-up.

Iedere update bewaart de vorige **programmabestanden** op de router onder:

```text
/jffs/addons/vpn_ipcatcher.d/backups/update-<datum>-<tijd>-<pid>/
```

`last-backup` verwijst naar de laatste geslaagde updateback-up. Terugzetten:

```sh
/jffs/scripts/vpn_ipcatcher.sh rollback
```

Configuratie wordt bij gewone updates en rollback niet vervangen. Dit is geen
volledige router- of configuratieback-up. De installer bewaart afzonderlijke
back-ups van startup-hooks die hij wijzigt. Bij de eerste VPN/lijstmigratie wordt
de oude configuratie lokaal bewaard voor foutherstel.
Vanaf 2.8.0 bevat iedere updateback-up ook prive-snapshots van de configuratie,
VPN-keuze en updatebron. Rollback zet deze instellingen niet automatisch terug.

Vanaf 2.8.1 verschijnt ook een klein privéarchief onder
`/jffs/vpn-ipcatcher-backups/`. Dit is geen publiek downloadbestand in de WebUI.
Oude back-ups blijven staan; controleer de vrije JFFS-ruimte en bewaar belangrijke
archieven ook op je pc. De uitgebreide optie is evenmin een volledige routerback-up.

Een mislukte start tijdens de update herstelt automatisch de vorige code. Een
bewust gestopte app blijft gestopt. Stroomuitval kan niet door een lopende shell
worden hersteld: inspecteer dan back-ups, locks en `updating` voordat je hervat.
Verwijder markers niet blind. Back-ups worden niet automatisch opgeruimd;
controleer vrije JFFS-ruimte en maak daarnaast je eigen routerback-up.

## 🎛️ Bediening en amtm

**Toevoegen aan amtm:** kies **25 · Toevoegen aan amtm** in het IP Catcher-menu.
De registratie bewaart bestaande vermeldingen, voorkomt dubbelen en controleert
de vier beschikbare plaatsen. Open amtm opnieuw; IP Catcher staat bij `p1` t/m
`p4`. Werk amtm eerst bij wanneer persoonlijke scripts nog niet worden herkend.
Dit maakt het geen officieel amtm-addon; updates lopen via IP Catcher zelf.

### 📋 Volledig hoofdmenu

| Nr. | Optie | Functie |
| --- | --- | --- |
| 1 | Start service | Start en schakel crashherstel in |
| 2 | Stop service | Bewust stoppen tot Start/Restart of reboot |
| 3 | Restart service | Configuratie opnieuw laden |
| 4 | Refresh status | Actuele status bekijken |
| 5 | Live activity | Live lijst- en capture-overzicht |
| 6 | Live log | Log volgen |
| 7 | Live stream flows | Verkeer en bytegroei bekijken |
| 8 | Candidate IPs | Tijdelijke kandidaten bekijken |
| 9 | Final IPs | Geleerde adressen voor de VPN-route |
| 10 | Show config | Instellingen lezen |
| 11 | Guided settings | Geavanceerde instellingen met uitleg |
| 12 | Profielen | Leerprofiel kiezen |
| 13 | Exclusion manager | Uitsluitingen en presets beheren |
| 14 | Edit full config | Handmatig bewerken, alleen voor gevorderden |
| 15 | Reset config | Leerinstellingen resetten; VPN-keuze behouden; eerst back-up |
| 16 | Clean excluded IPs | Uitgesloten adressen uit lijsten verwijderen |
| 17 | Exit | Menu verlaten, service blijft draaien |
| 18 | Check update | GitHub-versie controleren |
| 19 | Install update | Veilig bijwerken met back-up |
| 20 | Compatibility check | Router en benodigde tools controleren |
| 21 | Restore previous version | Vorige programmaversie terugzetten |
| 22 | VPN / routing setup | VPN kiezen; lijsten en regels automatisch regelen |
| 23 | Check VPN / list routing | VPN/lijstkoppeling controleren |
| **24** | **Maak back-up** | **1 klein · 2 uitgebreid · Enter terug** |
| **25** | **Toevoegen aan amtm** | **Registreren als persoonlijk script** |

**Profielen (12):** 1 Stabiel TV, 2 Voorzichtig leren, 3 Snel zappen,
4 Analyse/review, 5 Alleen bestaande lijst gebruiken, 6 Terug.

**Guided settings (11):** 1 Interfaces, 2 IPSet-naam, 3 Poorten,
4 Promotiemodus, 5 Minimumleeftijd, 6 Minimumbytes, 7 Domeinuitsluitingen,
8 IP-uitsluitingen, 8b Netwerkbereiken, 9 Profielen, 10 Exclusion manager,
11 Timers/cleanup, 12 Generieke hostscan, 13 Externe DNS, 14 Streamflow-scan,
15 Bron-IP's, 16 Streamdrempel, 17 Streamtoename, 18 Streamdoel, 19 Terug.
Wijzig de VPN via **22**, niet door zelf een nieuwe lijstnaam te verzinnen.

**Exclusion manager (13):** 1 Bekijk alles, 2 Veilige basis toevoegen,
3 DNS, 4 Social/messaging, 5 Camera/IoT, 6 GitHub/dev-CDN, 7 Games,
8 OS/app-updates, 9 TV-telemetrie, 10 Streamingdiensten, 11 Eigen domeinen,
12 Eigen IP's, 13 Resolver/cache, 14 Uitgesloten IP's opruimen, 15 Terug.
Binnen een presetgroep: nummers schakelen diensten om; `a` alles toevoegen,
`r` alles verwijderen, `v` details, `q` terug.

### 🧠 De lijsten worden automatisch aangemaakt

- **Final:** definitieve adressen voor de gekozen VPN-route.
- **`_cand`:** kandidaten die nog worden beoordeeld.
- **`_wait`:** gekwalificeerde adressen met nog actieve verbindingen; routewissel wacht.
- **`_exclude`:** uitgesloten netwerkbereiken.

Je hoeft deze lijsten **niet zelf te maken**. Tijdelijke lijsten krijgen geen
VPN-markering. De uiteindelijke routecontrole voorkomt nieuwe toevoegingen bij
een onjuiste koppeling. Dit is geen garantie dat elke bestaande verbinding of
videowebsite via de gewenste VPN werkt.

### 🌐 Webinterface

De WebUI biedt Overzicht, Liveweergave, Configuratie, Uitsluitingen en Presetlijsten.
Acties: Start, Stop, Herstarten, Status vernieuwen, Uitsluitingen oplossen,
Veilige basis, Veilige uitsluitingen herstellen, Uitgesloten IP's opruimen en Log wissen.
Liveweergave: Flows, Log, Status, Candidate, Wachtlijst, Final, Opgeloste IP's en
Uitsluitbereiken. Opslaan, Opslaan + herstarten en Opnieuw laden zijn aanwezig;
taalkeuze is NL/EN/automatisch. Back-ups en amtm-registratie zitten in het SSH-menu.

**Controle:** lokale JavaScript-, taal- en weergavetests zijn toegevoegd. De echte
Merlin-menukoppeling, opslaan via `service-event` en routerstatus moeten nog op
de router worden getest. Daarom staat hier niet 'volledig werkend gegarandeerd'.

Wil je later een andere VPN? Gebruik het menu of `routing-setup`. Dat stelt
de eigen lijst/regels opnieuw in. De installatie hergebruikt automatisch een
passende bestaande DVR-lijst, of maakt een eigen `DVR-VIPC-...-v4`-lijst. Alleen
de eigen, gemarkeerde regels worden beheerd. Andere DVR-policies blijven staan.
Bij ontbrekende eigen regels herstelt de draaiende app deze automatisch.
Diagnostiek (`doctor`, `routing-check`) wijzigt niets.

```sh
/jffs/scripts/vpn_ipcatcher.sh
/jffs/scripts/vpn_ipcatcher.sh start
/jffs/scripts/vpn_ipcatcher.sh stop
/jffs/scripts/vpn_ipcatcher.sh status
/jffs/scripts/vpn_ipcatcher.sh doctor
/jffs/scripts/vpn_ipcatcher.sh routing-check
/jffs/scripts/vpn_ipcatcher.sh routing-setup
```

Stop onderdrukt de watchdog tot Start/Restart of reboot. Na reboot wordt
automatisch gestart; onverwachte crashes worden ongeveer iedere minuut
gecontroleerd. Bij een mislukte routingcontrole worden geen nieuwe adressen aan
de finale lijst toegevoegd. Dit schakelt bestaande VPN-routing niet uit.

Voeg `/jffs/scripts/vpn_ipcatcher.sh` toe via amtm's personal-scriptfunctie.
De amtm-updatemanager beheert dit script niet automatisch.
[Officiele amtm-uitleg](https://github.com/RMerl/asuswrt-merlin.ng/wiki/AMTM).

<a name="video-stopt-tijdens-afspelen"></a>

## 🎬 Video stopt tijdens afspelen

**Vanaf 2.7.1:** nieuwe finale adressen wachten in de niet-gerouteerde
`<finale-lijst>_wait`-IPSet zolang conntrack een verbinding naar dat adres toont.
De controle omvat alle clients/poorten en TCP/UDP. Zodra het adres vrij is, wordt
het opnieuw op routing en uitsluitingen gecontroleerd en toegevoegd. Bestaande
finale adressen mogen worden vernieuwd; hun route verandert daarmee niet.
Bij een mislukte conntrackcontrole wordt een nieuwe toevoeging uitgesteld.

Dit beperkt de vermoedelijke routewissel door IP Catcher tijdens het afspelen,
maar is geen volledige connection-pinning: tussen controle en toevoeging kan een
nieuwe verbinding beginnen. Andere addons, bestaande finale leden, verlopen
lijsten, VPN-uitval en IPv6 kunnen nog steeds invloed hebben. Het kan leren naar
de finale lijst vertragen; probeer dezelfde site opnieuw na het sluiten van de
eerste sessie. De wachtlijst bevat alleen eerder gekwalificeerde adressen.

Een stop na ongeveer een minuut bewijst niet dat een website VPN blokkeert.
IP Catcher kan na een leeftijd/byte-drempel een adres aan de VPN-lijst toevoegen.
Afhankelijk van de firewallregels kan daardoor de route tijdens een bestaande
stream veranderen. Dit is een mogelijke oorzaak, geen bevestigde diagnose.

Andere mogelijkheden: nieuwe CDN-adressen, afwijkende IPv6/DNS-routing, QUIC/UDP,
MTU-problemen of een blokkade van de VPN-uitgang. Een browser-VPN kan bovendien
een andere uitgang of protocol gebruiken.

Vergelijk dezelfde website met het hele testapparaat vanaf het begin via
dezelfde router-VPN. Werkt dat wel, onderzoek dan dynamische lijstrouting.
Een vooraf ingestelde DVR-policy kan helpen, maar moet ook de juiste CDN's
omvatten; start daarna een nieuwe browsersessie. Wis niet blind lijsten of
conntrack-verbindingen en verlaag niet zomaar leerdrempels: daarmee kan een
routewissel juist eerder plaatsvinden.

HTTPS-inhoud is versleuteld; tcpdump-tekst herkent niet betrouwbaar alle
HTTPS-domeinen. Conntrack levert bytegebaseerde leerinformatie. Hardwareversnelling
kan de zichtbaarheid verminderen. Deze finale IPv4-lijst dekt geen IPv6-learning.
Deel diagnosegegevens prive, niet als openbare issue met IP's, logs of config.

## 🔐 Privacy en releases

Bij een nieuwe `VERSION` test GitHub Actions eerst de openbare code en maakt
daarna een **testrelease** met versie-tag, routerpakket, openbaar bronpakket en
checksums. Een bestaande release wordt niet overschreven. De workflow kan ook
handmatig via Actions worden gestart. Routervalidatie blijft nodig; publiceren
voert nooit automatisch een routerupdate uit.

Alleen programmacode, documentatie en tests horen in deze repository.
Geen configuratie, sleutels, logs, VPN-keuzes of routerexports. De installatie
verstuurt geen persoonlijke routerconfiguratie naar GitHub.

Een versie in `VERSION` of een commit is nog geen GitHub Release. Releases moeten
apart worden gepubliceerd. Tot die tijd haalt het installatiecommando code van
`main` op. De publieke releasebeschrijving staat in [RELEASE-NOTES.md](RELEASE-NOTES.md).
Publiceer nooit een eigen routerexport als release-asset.

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

Tests gebruiken fixtures en namaakdownloads voor configuratieveiligheid,
leren, stop/crashgedrag, routingkoppeling, beschadigde downloads, behoud van
instellingen en rollback. Kernel, WebUI en echt VPN-verkeer vereisen routertests.

---

**🌍 Taal:** 🇳🇱 [Nederlands](#nederlands) | 🇬🇧 [English](#english)  
[Wijzigingen](CHANGELOG.md) / [Releasebeschrijving](RELEASE-NOTES.md) / [Repository](https://github.com/Kevin2296/VPN_IPcatcher)

<!-- ENGLISH_SECTION -->

---

<a name="english"></a>

# English

[Nederlands](#nederlands) | **English**

## ✨ At a glance

VPN IP Catcher observes traffic, learns suitable IPv4 addresses and automatically
manages a corresponding list and its own routing rules. It uses your router/DVR
VPN routing tables. IP Catcher itself is not a VPN client.

**Version: 2.8.4.** [Changelog, Dutch](CHANGELOG.md) |
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

**No command needed:** open the IP Catcher menu and select **24 · Maak back-up**:

- **1 · Small:** program code, settings, VPN selection, update source and existing hooks.
- **2 · Full:** also both addon directories/history and DVR configuration/code.

Installation backs up existing files/hooks before placing the addon. Every
update automatically creates a small private archive and separately preserves
the previous program version for menu **21**. A completely empty first install
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

## 🎛️ Controls and amtm

Choose **25 · Toevoegen aan amtm** to register IP Catcher as a personal script.
Existing entries are preserved; duplicates and the four-slot limit are checked.
Reopen amtm to see it under `p1`–`p4`. Update amtm first if unsupported.
This is not an official amtm addon. Its own updater manages updates.

### 📋 Complete main menu

| No. | Option | Purpose |
| --- | --- | --- |
| 1 | Start service | Start and enable crash recovery |
| 2 | Stop service | Stop until Start/Restart or reboot |
| 3 | Restart service | Reload configuration |
| 4 | Refresh status | View current status |
| 5 | Live activity | Live list/capture overview |
| 6 | Live log | Follow logs |
| 7 | Live stream flows | Inspect traffic and byte growth |
| 8 | Candidate IPs | Inspect temporary candidates |
| 9 | Final IPs | Learned destinations for the VPN route |
| 10 | Show config | Read settings |
| 11 | Guided settings | Advanced settings with explanations |
| 12 | Profielen | Choose a learning profile |
| 13 | Exclusion manager | Manage exclusions and presets |
| 14 | Edit full config | Manual editing, advanced users only |
| 15 | Reset config | Reset learning settings; preserve VPN choice; back up first |
| 16 | Clean excluded IPs | Remove excluded addresses from sets |
| 17 | Exit | Leave menu without stopping service |
| 18 | Check update | Check GitHub version |
| 19 | Install update | Update with backups |
| 20 | Compatibility check | Check router/tools |
| 21 | Restore previous version | Restore previous program files |
| 22 | VPN / routing setup | Choose VPN; manage lists/rules automatically |
| 23 | Check VPN / list routing | Check VPN/list binding |
| **24** | **Maak back-up** | **1 small · 2 full · Enter back** |
| **25** | **Toevoegen aan amtm** | **Register a personal script** |

**Profiles (12):** 1 Stable TV, 2 Cautious learning, 3 Fast zapping,
4 Analysis/review, 5 Existing list only, 6 Back.

**Guided settings (11):** 1 Interfaces, 2 IPSet name, 3 Ports, 4 Promotion mode,
5 Minimum age, 6 Minimum bytes, 7 Excluded domains, 8 Excluded IPs, 8b Network ranges,
9 Profiles, 10 Exclusion manager, 11 Timers/cleanup, 12 Generic host scan,
13 External DNS, 14 Streamflow scan, 15 Source IPs, 16 Stream threshold,
17 Stream growth, 18 Stream target, 19 Back. Change VPN via **22**, not a made-up list name.

**Exclusion manager (13):** 1 Show all, 2 Safe defaults, 3 DNS, 4 Social/messaging,
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
