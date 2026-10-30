# VPN IP Catcher 2.10.0 — Nieuwe WebUI in ASUS-stijl

**NL:** De WebUI is opnieuw vormgegeven in de stijl van de ASUS/Merlin-pagina's en een stuk overzichtelijker. Nieuw: een tegel voor **vaste routes**, de **wachtlijst** in beeld, en **IPTV-apparaten kiezen** uit de ASUS-apparatenlijst met namen. Liveflows tonen per verbinding een duidelijke status (via VPN, wacht op einde stream, via WAN, vaste route, router zelf, …) en de naam van het apparaat. Het amtm-menu is volledig Nederlands en logischer ingedeeld, met een apparatenkiezer onder **Instellingen → 7**. Een nieuwe installatie vraagt direct naar je IPTV-apparaten.

Tip na de update: kies via de WebUI of amtm je IPTV-box/tv als bronapparaat. Dan kan ander verkeer nooit per ongeluk via de VPN gaan.

**EN:** Redesigned WebUI in the ASUS/Merlin style: fixed-route and waiting-list tiles, IPTV device picker from the ASUS client list, readable per-flow status with device names, grouped maintenance actions and a "your value" column in the help. amtm menus are fully Dutch and better organised, with an IPTV device chooser; first installation asks for IPTV devices.

---

# VPN IP Catcher 2.9.17 — Gastnetwerken weer meegenomen

**NL:** In 2.9.16 keek de flow-scan alleen naar apparaten in het subnet van `br0`, waardoor streams vanaf een gastnetwerk of IoT-VLAN niet meer werden geleerd. 2.9.17 neemt alle apparaten in privé-netwerken weer mee en sluit de router zelf uit op basis van al zijn eigen adressen (LAN, WAN, VPN-tunnels). Nieuw in het amtm-menu: **VPN en routing → Vaste routes tonen**. Alle wijzigingen uit 2.9.16 blijven gelden.

**EN:** 2.9.16 limited the flow scan to the `br0` subnet, so guest-network/IoT-VLAN clients were no longer learned. 2.9.17 includes every private-network client again and excludes the router by all of its own addresses (LAN, WAN, VPN tunnels). New amtm entry: VPN and routing → show fixed routes.

---

# VPN IP Catcher 2.9.16 — Vaste routes, minder CPU, betrouwbaardere caches

**NL:** IP Catcher laat vaste routes voortaan volledig met rust. Bestemmingen en apparaten uit **VPN Director** (VPN- én WAN-regels) en de domeinen en IPSets van je andere **VPN Routing**-policies worden nooit geleerd en niet gecontroleerd; die regels bepalen zelf al de route. De lijst wordt elke minuut opnieuw ingelezen; eerder geleerde IP's die nu vast gerouteerd zijn, worden opgeruimd. Controleer met `/jffs/scripts/vpn_ipcatcher.sh fixed-routes`.

Daarnaast vangt tcpdump alleen nog TLS-handshakes en HTTP-headers in plaats van alle streamdata, wat tijdens het kijken veel router-CPU scheelt. De flow-scan negeert downloads van de router zelf (amtm, Skynet, AdGuardHome, spdMerlin), de DNS-cache verloopt na 5 minuten zodat wisselende CDN-adressen opnieuw worden geleerd, en een onderbroken provider-refresh kan het verversen niet meer blokkeren tot de volgende reboot. Nieuwe opt-in presets voor TikTok, HBO Max, SkyShowtime, NPO Start, Spotify, Twitch, cloudopslag en snelheidstests.

Bestaande configuratie, EPG/Domain VPN Routing-toewijzingen en geleerde lijsten blijven behouden. Herstart de catcher na de update en controleer de log op de regel "Vaste routes bijgewerkt".

**EN:** Fixed routes are now left alone: VPN Director destinations and device-wide rules (VPN and WAN) plus domains and IPSets of other Domain VPN Routing policies are never learned or checked; previously learned fixed destinations are purged (own `src=` entries only). tcpdump now captures only TLS handshakes and HTTP headers, cutting CPU use during playback. Flow scan ignores router-originated downloads. DNS cache entries expire after 5 minutes, missing PTR records are cached, stale provider-refresh locks are recovered, and temporary paths are unique per worker. New opt-in presets. Validate on ASUS hardware after updating.

---

# VPN IP Catcher 2.9.15 — Stabiliteitsfix voor herstartlus

**NL:** Versie 2.9.14 had een fout in de hoofdloop waardoor een geldig numeriek engine-PID elke 10 seconden werd overschreven met een dollarteken. De watchdog kon de actieve service daardoor niet herkennen en startte hem om de minuut opnieuw. Dat leidde tot dubbele workers, tcpdump-onderbrekingen en SIGTERM-meldingen. In 2.9.15 blijft het PID correct, controleert de watchdog de procesidentiteit en verwijdert een oude engine de PID/workerstatus van een nieuw proces niet meer.

Geen wijzigingen aan de EPG/Domain VPN Routing-toewijzingen, IPTV-leerlijsten of provider-uitsluitingen. Bestaande configuratie blijft bewaard. Start de service na update gecontroleerd opnieuw en controleer het numerieke PID en de status gedurende meer dan één watchdog-interval.

**EN:** Fix repeated watchdog recovery in v2.9.14: the engine loop overwrote the actual process PID with a literal dollar sign, resulting in cron-triggered restarts, duplicate capture/promote workers, tcpdump interruptions and SIGTERM. The numeric PID is now stable; watchdog validates the real engine process identity; superseded engines cannot delete replacement state. No routing/DNS/provider exclusion configuration changes. Regression fixture and CI pass; confirm on ASUS hardware after updating.

---

# VPN IP Catcher v2.9.14 — Altijd via VPN voor EPG/XMLTV

**NL:** Plak voortaan direct een volledige EPG/XMLTV-link onder **Domeinroutes / Altijd via VPN** en kies de VPN-policy die je wilt gebruiken. Alleen de hostname wordt naar Domain VPN Routing v3.2.5 gestuurd; pad, eventuele tokens en credentials worden niet opgeslagen. IP Catcher wacht niet op automatische IPTV-detectie: `adddomain` en `querypolicy` worden onmiddellijk uitgevoerd, waarna het IP-adres in de gekozen policy-IPSet wordt geverifieerd. De geselecteerde VPN moet actief zijn; dubbele hostname-toewijzingen aan een andere DVR-policy worden geweigerd.

Bij door IP Catcher beheerde `managed-v1`-markregels respecteert de automatische IPTV-route voortaan bestaande VPN-markeringen. Bestaande markregels worden gericht gemigreerd; handmatig door DVR beheerde regels worden niet aangepast. De Google/Netflix-provideruitsluitingen blijven onafhankelijk van expliciete DVR-domeinroutes.

**Let op:** de juiste hostname en DNS-resolutie zijn vereist; een URL-pad of andere host na redirect valt niet onder dezelfde IP-routeringsregel. Een gedeeld CDN-IP kan niet tegelijkertijd per URL naar twee verschillende VPNs worden gestuurd. Controleer de gekozen policy op je ASUS na de update.

**EN:** Users can paste full HTTP(S) EPG/XMLTV URLs and assign their hostname immediately to an explicit existing Domain VPN Routing policy. Never send or save URL paths/tokens/credentials. Check active VPN and resolved IPSet, reject duplicate conflicting policies, preserve pre-existing VPN fwmarks when the owned automatic IPTV rule matches. Shared-CDN IP and redirect limitations apply.

---

# VPN IP Catcher v2.9.13 — Netwerkbereiken van bekende diensten

**NL:** Als een bekende dienst in je uitsluitingsdomeinen staat, kan VPN IP Catcher voortaan automatisch de IPv4-prefixen van de aantoonbaar eigen provider-ASNs ophalen via RIPEstat en in de bestaande uitsluitings-IPSet opnemen. Nu voor Google/YouTube, Netflix Open Connect, Meta, Apple en GitHub. De update draait buiten de IPTV-scan, met dagelijkse controle en behoud van laatst werkende data bij lookup-fouten. Handmatige uitsluitingen en NordVPN/DVR-routes worden niet aangepast.

**Bediening:** WebGUI-optie "Eigen provider-netwerken automatisch ophalen" (standaard ja). SSH: `/jffs/scripts/vpn_ipcatcher.sh provider-ranges-refresh` en `/jffs/scripts/vpn_ipcatcher.sh provider-ranges-status`. Verwijder oude foutieve final-matches alleen wanneer je geen stream bekijkt via `clean-excluded`.

**Reikwijdte:** niet alle IP-adressen waarop een dienst bij derden draait zijn ondubbelzinnig aan die dienst toe te schrijven. Dahua/Imou, Reddit en veel cloud/CDN-verkeer gebruiken gedeelde infrastructuur; die volledige ASN's uitsluiten zou IPTV op dezelfde hosting blokkeren. Google Cloud-klantnetten worden niet blind meegenomen. IPv4-only, echte ASUS-routertest blijft noodzakelijk.

**EN:** Automatically supplement selected domain exclusions with RIPEstat owner-originated IPv4 prefixes for Google, Netflix Open Connect, Meta, GitHub and Apple; background daily refresh, persistent per-provider fallback, atomic exclusion IPSet rebuild, no changes to VPN policies. Shared AWS/Azure/Fastly/Alibaba hosting is intentionally not blanket-excluded; not a guarantee to cover all service endpoints.

---

# VPN IP Catcher 2.9.12 — Google/YouTube false-positive guard

**NL:** Beschermt de geverifieerde YouTube/Google-IPv4-range `136.22.128.0/19` tegen nieuwe IPTV-IP-learning. Inclusief `136.22.151.14`, dat eerder onbedoeld door de catcher naar NordVPN werd gerouteerd. Nieuwe optionele presets voor Reddit, Claude en ChatGPT. De DNS-resolver behoudt een eerder geldige cache bij een tijdelijke totale DNS-uitval. Bestaande routeringspolicies, IPTV-IPSet en SOURCE_IPS worden niet automatisch vervangen. Om oude foutieve entries op te schonen: wacht tot er geen streams zijn en gebruik `vpn_ipcatcher.sh clean-excluded`.

**EN:** Prevent accidental IPTV learning of the documented Google/YouTube range 136.22.128.0/19. Adds optional Reddit/Claude/ChatGPT presets and preserves the last valid DNS exclusion cache on total DNS outage. Existing VPN rules and learned IPTV entries are not silently erased. This does not cover all Google IPs; source-specific IPTV attribution requires further work.

---

# VPN IP Catcher v2.9.11 · Gedeeltelijke presetopslag

**Nederlands:** De WebGUI stuurt bij het selecteren van een preset alleen gewijzigde instellingen naar de router en verifieert de opgeslagen uitsluitingen. De nieuwe status verschijnt op basis van de werkelijk opgeslagen configuratie. Dit vermindert het aantal Merlin-service-events aanzienlijk en behoudt alle andere VPN- en apparaatinstellingen. Tevens is een fout in de tijdelijke ontvangstbevestiging gecorrigeerd.

**English:** Send only changed configuration values when saving presets, verify saved exclusions and reload the confirmed values. The unique temporary acknowledgement filename is restored. No VPN-routing changes.

---

# VPN IP Catcher v2.9.10 · Presetopslag

De router bevestigt nu elk deel van de configuratie afzonderlijk. Een succesvolle opslag wordt alleen getoond na vergelijking van de opgeslagen uitsluitingen met de geselecteerde opties. Router/VPN-instellingen blijven verder ongewijzigd.

# 🛡️ VPN IP Catcher 2.9.9 · WebGUI status lock recovery

**Nederlands:** herstelt automatisch een achtergebleven WebGUI-publicatie-lock zonder PID. Dit was de oorzaak van ontbrekende `vpn_ipcatcher_status.json`, een dashboard dat op 'LADEN' bleef en een melding 'Unexpected token <' bij het ophalen van JSON. De nieuwe versie bewaart actieve locks, verwijdert geen onbekende bestanden en retourneert een fout wanneer publicatie niet lukt. Status-JSON wordt atomair gepubliceerd en met `jq` gecontroleerd waar beschikbaar. Bestaande VPN-routes, domein-uitsluitingen en instellingen veranderen niet.

**Installeren:** update via het bestaande U/Update-menu. De eerstvolgende statuspublicatie herstelt een oude PID-loze lock automatisch. Bij een blijvende fout controleer `ls -ld /tmp/vpn_ipcatcher_webui_status.lock` en `ls -l /www/user/vpn_ipcatcher_status.json` zonder router-reboot.

**English:** recover abandoned PID-less WebUI status publication locks safely. Fail closed for active or non-empty foreign locks, report actual failure codes, validate JSON with jq where installed, and write status atomically. No VPN or configuration changes. Regression coverage includes active, dead and absent PIDs and recreated status JSON.

---

# 🛡️ VPN IP Catcher 2.9.8 · Optional Google Play exclusions

**Nederlands:** onder **Presetlijsten → OS / app updates** staat nu **Google Play Store / app downloads**. De vier domeinen zijn afzonderlijk aanvinkbaar: `dl.google.com`, `play.googleapis.com`, `android.clients.google.com` en `redirector.gvt1.com`. De bestaande resolver haalt automatisch de wisselende IPv4-adressen op nadat je de uitsluiting zelf hebt geselecteerd. De update **activeert niets automatisch**: alle apparaten, ook de telefoon, kunnen streaming blijven leren. Na het aanvinken en opslaan kan de cache worden ververst met `resolve-excludes` en kunnen reeds geleerde uitgesloten IP's met `clean-excluded` worden verwijderd. Geen aanpassing van normale WAN-/VPN-routeringsregels; geen gegarandeerde fix voor Play Store als de blokkade elders zit.

**English:** a new manually selectable **Google Play Store / app downloads** option appears under **Preset lists → OS / app updates**. Four hostnames can be selected individually. The existing IPv4 exclusion resolver handles addresses after manual opt-in; no source-device restrictions or default exclusions change. Shared CDN IPs and other routing rules remain limitations.

---

# 🛡️ VPN IP Catcher 2.9.7 · Lifecycle Diagnostics

**Nederlands:** nieuwe lokale Lifecycle-regels helpen onverwachte herstarts te
onderzoeken. Start/stopaanvragen, watchdog-herstel en engineacties tonen PID en
begrensde procescontext. Bij INT/TERM wordt context gelogd, maar niet beweerd dat
de parent ook de afzender is. Een directe externe signaalafzender blijft onbekend.
Skynet en firewallbeleid blijven ongewijzigd; dit is diagnose, geen bewezen fix
voor de eerder waargenomen onderbreking rond 10:25. Geen upload of commandoparameters.

**English:** local lifecycle diagnostics for requests, watchdog recovery and
engine start/stop/signals. Bounded process context only; no full command arguments
or environment. A signal's parent is not assumed to be its sender. No Skynet or
firewall policy changes; diagnostics do not prove or fix the original cause.

---

**Nederlands:** bij een routingfout wordt direct een extra alleen-lezen controle
uitgevoerd. Het lokale log toont de exitcodes en begrensde foutteksten van zowel
prepare als check. Identieke fouten verschijnen maximaal eenmaal per vijf minuten;
een gewijzigde oorzaak en herstel worden meteen gemeld. Geen upload of routerdump.
De beveiliging die nieuwe VPN-bestemmingen tegenhoudt bij routingproblemen blijft intact.

**English:** immediate read-only routing diagnostics on preparation failure, with
bounded local error details and exit codes. Duplicate logs are limited to once per
five minutes; changed errors and recovery are logged immediately. No upload or
automatic WAN fallback. Existing learning safeguards remain in place.

---

**Nederlands:** herstel voor 'Update bezig; start overgeslagen' bij een live-update.
De interne startmarker wordt expliciet geexporteerd. De updateblokkering blijft
intact en de vorige configuratie blijft behouden. De test-engine controleert nu
de marker en het bestaan van de updateblokkering tijdens de interne start.

**Bij 2.9.3/2.9.4 met dit probleem:** gebruik eenmaal het installatiecommando met
`update` uit de README. Dat voert de nieuwe, geverifieerde updater uit. Alleen
opnieuw U kiezen gebruikt nog de oude updater. Geen migratie of reset nodig.

**English:** explicitly export the internal-start marker during live updates.
The update guard remains active, configuration is preserved and strict regression
tests verify the start context. For affected older installations, run the README
bootstrap command with `update` once to execute the corrected updater.

---

**Nederlands:** gecontroleerde onderhoudsrelease. Effectieve standaardwaarden in
de WebUI, blijvend lege uitsluitingen, correcte config-herlading en decimalen met
voorloopnullen. Verwijderde domeinen werken niet door via oude uitsluitcache;
gedeelde IPs houden hun domeinkoppelingen. Tijdsortering gebruikt echte tijdwaarden.

Werk bij via **7 > U** en herlaad de WebUI met Ctrl+F5. Configuratie blijft
behouden; de updater maakt vooraf een verplichte lokale back-up. Geen reset nodig.
Geen nieuwe uitsluitpresets of automatische omleiding buiten VPN toegevoegd.

**English:** verified maintenance release. Effective WebUI defaults, explicit
empty exclusions, clean config reloads, decimal timers, current-domain DNS cache
matching and chronological diagnostic sorting. Update through **7 > U**; private
backup is mandatory and configuration is preserved. Reload the WebUI afterward.

See [TESTING.md](TESTING.md) for test coverage and limits. Automated/synthetic
tests and browser checks do not guarantee every real router, VPN or IPTV service.

---

**2.9.3:** compacte submenu's, E om terug te gaan en alleen UC/U/FU voor updates.
Een bevestiging inclusief back-up, rustige voortgang en technische details in een
prive-log. Duidelijkere losse presetkeuze, standaardwaarden en NL/EN installatiestappen.
Updates bewaren je configuratie; er is geen universeel beste leerprofiel.

**2.9.3:** compact submenus, E navigation and unique UC/U/FU update actions.
One confirmation including backup, clean progress and private technical logs.
Clear individual preset selection, defaults and bilingual installation steps.
Updates preserve configuration; no universally best learning profile is claimed.

**2.9.2:** vaste, aanklikbare kolomkoppen in alle live-tabellen. Oplopend/aflopend
sorteren en sortering per tab behouden bij verversen. Scrollpositie blijft behouden.

**2.9.2:** sticky, clickable column headers in all live tables. Ascending/descending
sorting persists per tab across refreshes. Scroll position remains preserved.

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
