<div align="center">

# 🛡️ VPN IP Catcher

### 📡 Observe. 🧠 Learn. 🔀 Route.

IPv4-learning voor jouw Asuswrt-Merlin VPN-routing.

![Version 2.8.0](https://img.shields.io/badge/version-2.8.0-087F8C?style=for-the-badge)
![Asuswrt Merlin](https://img.shields.io/badge/platform-Asuswrt--Merlin-30363D?style=for-the-badge)
![POSIX Shell](https://img.shields.io/badge/runtime-POSIX%20shell-476A30?style=for-the-badge)
![Router validation required](https://img.shields.io/badge/status-router%20validation%20required-B45309?style=for-the-badge)

🇳🇱 **Nederlands** &nbsp; | &nbsp; 🇬🇧 [English](README.en.md)

[🚀 Installeren](#eerste-installatie) &nbsp; / &nbsp; [🔄 Bijwerken](#bijwerken) &nbsp; / &nbsp; [💾 Terugzetten](#back-up-en-terugzetten) &nbsp; / &nbsp; [🎬 Problemen oplossen](#video-stopt-tijdens-afspelen)

</div>

---

## ✨ In het kort

IPv4-leeraddon voor Asuswrt-Merlin. IP Catcher leert adressen uit verkeer en
regelt automatisch de bijbehorende lijst en eigen routingregels. Het gebruikt
de VPN-routingtabellen van je router/DVR; IP Catcher is zelf geen VPN-client.

**Versie: 2.8.0.** [Wijzigingen](CHANGELOG.md) |
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

Oude installaties zonder veilige updater worden geweigerd. Maak eerst een
persoonlijke back-up van programma's, configuratie en betrokken hooks. Handmatige
migratie vereist het gecontroleerde programmapakket onder `/jffs`, uitvoerbare
shellbestanden en daarna de installer. Gebruik geen eerste installatie om een
oude installatie te overschrijven.

<a name="back-up-en-terugzetten"></a>

## 💾 Back-up en terugzetten

Maak voor het testen ook een handmatige back-up via SSH:

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

Een mislukte start tijdens de update herstelt automatisch de vorige code. Een
bewust gestopte app blijft gestopt. Stroomuitval kan niet door een lopende shell
worden hersteld: inspecteer dan back-ups, locks en `updating` voordat je hervat.
Verwijder markers niet blind. Back-ups worden niet automatisch opgeruimd;
controleer vrije JFFS-ruimte en maak daarnaast je eigen routerback-up.

## 🎛️ Bediening en amtm

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

**🌍 Taal:** 🇳🇱 Nederlands | 🇬🇧 [English](README.en.md)  
[Wijzigingen](CHANGELOG.md) / [Releasebeschrijving](RELEASE-NOTES.md) / [Repository](https://github.com/Kevin2296/VPN_IPcatcher)
