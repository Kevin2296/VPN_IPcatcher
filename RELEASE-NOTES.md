# 🛡️ VPN IP Catcher 2.9.1 · Testrelease / Prerelease

**2.9.1:** browserupdates met bevestiging en verplichte lokale back-up; domeinen
toevoegen aan bestaande DVR v3.2.5-policies; losse presetitems; NL/EN uitleg;
zichtbare DNS-capturestatus en behoud van scrollpositie bij pauze.
amtmupdate-protocol opt-in toegevoegd, maar geen centrale AU-registratie of eigen
automatisch tijdschema. Merlin 3006.102.9-archief gecontroleerd, geen hardwaregarantie.

**2.9.1:** confirmed browser updates with mandatory local backup; existing DVR
v3.2.5 domain-policy adapter; individual preset entries; NL/EN help; DNS capture
states and retained paused scroll. Opt-in amtmupdate protocol, not central AU
enrollment or a separate scheduler. Firmware archive checked, hardware test required.

**2.9.0:** Bewaar de diagnose na Stop, pauzeer/hervat, markeer een zender en
exporteer de tijdlijn als JSON. DNS-aanwijzingen verschijnen waar zichtbaar
(alleen normale IPv4/UDP-DNS; twee minuten of 400 pakketten). Geen URL of
inloggegevens. Scrollpositie blijft behouden. Updates vragen bevestiging,
maken verplicht een prive-back-up, tonen voortgang en herstellen ASUS-hooks.
UC/U/FU en back-upbeheer via menu 26 toegevoegd. Geen automatische amtm-AU
integratie en geen garantie op een oplossing voor alle IPTV-providers.

**2.9.0:** Retained diagnostics, pause/resume, timestamped channel markers and
JSON export. Bounded plain-DNS hints for one IPv4 device, not proof of service
identity. Scroll positions retained. Confirmed updates with mandatory private
backup, phase progress and automatic ASUS hook repair. UC/U/FU aliases and
backup cleanup in menu 26. Router verification still required.

**Privacy:** Diagnose-export bevat prive-verbindingsmetadata en mogelijk
domeinen. Niet publiceren op GitHub. Geschiedenis blijft in de geopende pagina;
exporteer voordat je de pagina sluit of herlaadt.

**2.8.9:** Kies een online IPv4-apparaat uit de ASUS-clientlijst. De diagnose
wacht nu op bevestiging van de router en onderscheidt lege metingen van fouten.
Dubbele actievelden in WebUI-verzoeken opgelost. Live-tabbladen breken geen
woorden meer af. Geen nieuwe VPN- of IPTV-routingwijziging.

**2.8.9:** Select an online IPv4 device from the ASUS client list. Diagnostics
wait for router confirmation and distinguish empty snapshots from failures.
Duplicate WebUI action fields fixed. Live tabs no longer split words. No new
VPN or IPTV routing changes. Router testing remains required.

**2.8.8:** WebUI-tab Diagnose: vul een IPv4-apparaat in en start twee minuten
verbindingsmomentopnamen, op alle poorten en zonder leerdrempel/top-30-filter.
Alleen verbindingsmetadata; geen URL, inloggegevens of pakketinhoud. Maximaal
2000 regels per momentopname, met afkapmelding. Geen routingwijzigingen.

**2.8.8:** WebUI Diagnostics tab: enter a device IPv4 address for two minutes
of all-port connection snapshots, without learning thresholds/top-30 filters.
Metadata only, no URLs, credentials or payloads. Explicit truncation above
2000 records per snapshot. No routing changes. Short-lived requests between
snapshots and IPv6 traffic are not captured.

**2.8.7:** Compactere WebUI met livefilters voor zoektekst, bronapparaat,
poort en lijststatus. Filters blijven bij verversen behouden. Leesbare
verkeersvolumes. Alleen weergavewijzigingen: geen nieuwe stream- of routingfix.

**2.8.7:** More compact WebUI with live search, source-device, port and
list-status filters retained across refreshes. Readable traffic volumes.
Display changes only: no new streaming or routing fix.

**2.8.6:** Versienummer in het amtm-menu werkt ook wanneer amtm het script
vanuit een andere map opent. Inclusief alle dashboardverbeteringen hieronder.

**2.8.6:** Menu version detection works when amtm invokes the script from a
different directory. Includes all dashboard improvements below.

**2.8.5:** Rustiger WebUI-dashboard en compact amtm-menu met versie en VPN-keuze.
Instellingen zijn gegroepeerd, technische details inklapbaar en uitsluitingen
hebben duidelijke NL/EN-statuslabels. VPN-namen blijven intact zonder `tr`.
Persoonlijke instellingen en de gekozen VPN blijven behouden.

**2.8.5:** Quieter WebUI dashboard and compact amtm menu with version and VPN
selection. Grouped settings, collapsible technical details and clear NL/EN
exclusion labels. VPN names no longer depend on `tr`. Existing configuration
and VPN selection are preserved. Personal-script registration is not AU enrollment.

**2.8.4 fix:** VPN-herkenning werkt zonder POSIX-tekenklassen in `tr`. De juiste
OpenVPN/WireGuard-instellingssleutel wordt rechtstreeks opgebouwd. Alle tien
sleutels zijn getest met een gesimuleerde ongeschikte `tr`; veiligheidscontroles
op markering, VPN-route en tunnelstatus blijven actief.

**2.8.4 fix:** VPN detection no longer depends on POSIX character classes in
`tr`. OpenVPN/WireGuard setting keys are constructed directly. All ten keys are
tested with an incompatible `tr`; marking, route and tunnel checks remain active.

**Migratie:** aparte `migrate`-optie voor oudere installaties zonder updater,
met gecontroleerde downloads, een volledige prive-back-up en herstel bij fouten
tijdens het vervangen. De VPN-keuze wordt eenmalig gecontroleerd. Back-ups werken
nu ook zonder `id`; de wrapper heeft een expliciete PATH voor cron/watchdog.

**Migration:** dedicated `migrate` action for legacy installations without an
updater, verified downloads, full private backup and recovery from replacement
failures. One-time VPN selection; backups support missing `id`; explicit wrapper PATH.

**Legacy rollback:** terug naar de oude addon vereist de volledige prive-back-up.
Returning to the legacy addon requires the full private backup. Menu rollback
is supported for ordinary updates only. Power-loss recovery is not guaranteed.

🇳🇱 [Nederlandse uitleg](https://github.com/Kevin2296/VPN_IPcatcher#nederlands) · 🇬🇧 [English documentation](https://github.com/Kevin2296/VPN_IPcatcher#english)

## 🇳🇱 Nieuw

- 💾 Menu **24 · Maak back-up**: klein of uitgebreid, zonder los commando.
- 🔒 Automatische kleine privéback-up voor installatie/update; fout = update stopt.
- 🎛️ Menu **25 · Toevoegen aan amtm**: persoonlijke registratie, geen dubbele vermeldingen.
- 🧠 Automatische candidate/final/wait/exclude-lijsten; wachtlijst zichtbaar in de WebUI.
- 🔧 Reset van leerinstellingen behoudt de gekozen VPN/lijst en maakt eerst een back-up.
- 📚 Alle hoofdmenuopties uitgelegd, NL en EN op dezelfde repositorypagina.

Gebruik het installatie/updatecommando in de README. **Voor de overgang van
2.8.0 naar 2.8.1 of nieuwer gebruik je eenmaal het README-updatecommando**, zodat ook de
nieuwe helpers worden meegenomen. Daarna zijn menu-updates weer voldoende.
De downloads bevatten uitsluitend openbare code, documentatie en tests.
Privé-back-ups blijven op de router en horen nooit op GitHub.

## 🇬🇧 What's New

- 💾 Menu **24** creates a small/full private backup without a separate command.
- 🔒 Automatic small backup before install/update; backup failures stop the update.
- 🎛️ Menu **25** registers the addon as an amtm personal script without duplicates.
- 🧠 Automatic lists and a visible Waiting tab in the WebUI.
- 🔧 Learning-settings reset preserves the VPN/list binding and backs up first.
- 📚 Full main-menu overview, Dutch and English on the same repository page.

**Use the README update command once when upgrading 2.8.0 to 2.8.1 or newer**, to install
the newly added helpers. Future updates can use the menu. Downloads contain
public files only; private backups remain on your router.

## ⚠️ Status / Limitations

Local tests do not prove full RT-AX86U Pro / Merlin WebUI compatibility. Validate
on the router before treating this as stable. No VPN killswitch, no IPv6 learning,
and no guarantee against every streaming-site error. A first installation is not
fully transactional if interrupted. Archives are not full router/nvram backups.

The router archive includes runtime code, VERSION and SHA256SUMS. The source ZIP
also includes docs and tests. Prefer the verified installer over manual extraction.
