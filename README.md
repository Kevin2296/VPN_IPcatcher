# VPN IP Catcher

IPv4-leeraddon voor Asuswrt-Merlin. IP Catcher leert adressen uit waargenomen
verkeer en voegt deze toe aan een bestaande Domain-based VPN Routing-lijst.
De routing-addon bepaalt de VPN-uitgang; IP Catcher is zelf geen VPN-client.

**Versie: 2.7.0.** [Wijzigingen](CHANGELOG.md) |
[Releases](https://github.com/Kevin2296/VPN_IPcatcher/releases)

Lokaal getest, maar volledige compatibiliteit en de echte verkeersroute moeten
op de router worden gecontroleerd. Geen VPN-killswitch of officieel amtm-addon.

## Vereisten

- Asuswrt-Merlin met JFFS custom scripts en configs ingeschakeld.
- Een werkende OpenVPN- of WireGuard-client met een bestaande DVR-policy.
- Een IPv4 `hash:ip`-lijst met `timeout`, `counters` en `comment`.
- `ip`, `iptables`, `ipset`, `tcpdump`, `nslookup`, `awk`, `sed`, `grep`, `tr`, `cru`.
- Voor volledige leerfunctie/updates: `conntrack`, `curl`, `jq`, `sha256sum`.
- Conntrack accounting, correcte routerklok en HTTPS-certificaten.
- Voor de WebUI: Merlin Addons-helper en een bestaand Addons-menu.

Ontbrekende tools worden gemeld. Installeer deze via Entware/amtm. De installer
configureert geen VPN-wachtwoorden en bouwt geen onverenigbare IPSet om.
De code gebruikt `/bin/sh`, zonder architectuurspecifieke meegeleverde binaries.

## Eerste installatie

Open een interactief SSH-venster op de router, bijvoorbeeld MobaXterm.
Alleen uitvoeren wanneer IP Catcher nog niet is geinstalleerd:

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh install
```

Kies de VPN-client, DVR-policy en LAN-interface(s). De installer controleert
lijstkoppeling, firewallmarkering, routingtabel en tunnel voordat leren begint.
Gebruik geen `curl | sh`: de wizard heeft je invoer nodig.

Een eerste installatie is niet volledig transactioneel. Na een onderbreking of
afgebroken wizard blijven geplaatste bestanden staan. Herstel de oorzaak en hervat:

```sh
sh /jffs/addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh
```

## Bijwerken

Voor een bestaande installatie met veilige updater (2.6.0 of nieuwer):

```sh
curl -fL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/Kevin2296/VPN_IPcatcher/main/install.sh -o /tmp/vpn_ipcatcher_install.sh && sh /tmp/vpn_ipcatcher_install.sh update
```

De eerste update naar 2.7.0 vraagt om je VPN/lijstkeuze. Volgende updates kunnen
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

## Back-up en terugzetten

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

Een mislukte start tijdens de update herstelt automatisch de vorige code. Een
bewust gestopte app blijft gestopt. Stroomuitval kan niet door een lopende shell
worden hersteld: inspecteer dan back-ups, locks en `updating` voordat je hervat.
Verwijder markers niet blind. Back-ups worden niet automatisch opgeruimd;
controleer vrije JFFS-ruimte en maak daarnaast je eigen routerback-up.

## Bediening en amtm

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

## Video stopt tijdens afspelen

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

## Privacy en releases

Alleen programmacode, documentatie en tests horen in deze repository.
Geen configuratie, sleutels, logs, VPN-keuzes of routerexports. De installatie
verstuurt geen persoonlijke routerconfiguratie naar GitHub.

Een versie in `VERSION` of een commit is nog geen GitHub Release. Releases moeten
apart worden gepubliceerd. Tot die tijd haalt het installatiecommando code van
`main` op. De publieke releasebeschrijving staat in [RELEASE-NOTES.md](RELEASE-NOTES.md).
Publiceer nooit een eigen routerexport als release-asset.

## Tests

```sh
sh tests/engine-checks.sh
sh tests/installer-checks.sh
sh tests/lifecycle-checks.sh
sh tests/path-checks.sh
sh tests/routing-checks.sh
sh tests/update-checks.sh
sh tests/bootstrap-checks.sh
```

Tests gebruiken fixtures en namaakdownloads voor configuratieveiligheid,
leren, stop/crashgedrag, routingkoppeling, beschadigde downloads, behoud van
instellingen en rollback. Kernel, WebUI en echt VPN-verkeer vereisen routertests.
