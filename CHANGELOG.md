# Wijzigingen

## 2.10.0 — Nieuwe WebUI in ASUS-stijl, IPTV-apparaten kiezen, overzichtelijker amtm-menu

**WebUI**
- Vormgeving sluit aan op de standaard ASUS/Merlin-pagina's: FormTable-secties, `button_gen`-knoppen, ASUS-tabbladen en kleuren.
- Zes statustegels, nu met **Vaste routes** (VPN Director / VPN Routing) en het aantal IP's op de **wachtlijst**.
- **IPTV-apparaten kiezen** uit de ASUS-apparatenlijst (met namen) in plaats van IP's typen. Zolang er naar alle apparaten wordt gekeken, toont het overzicht een duidelijke tip.
- **Liveflows** tonen per bestemming een leesbare status: via VPN, wacht op einde stream, in beoordeling, via WAN, vaste route, vast apparaat, uitgesloten, router zelf of lokaal. De bronkolom toont apparaatnamen; extra filters voor wachtlijst, vaste route en router/lokaal.
- Verkeer van de router zelf (bijv. het WAN-adres achter een modem) staat als "router zelf" en is niet meer verwarrend.
- Onderhoud: dagelijkse acties eerst; acties die instellingen overschrijven staan apart onder "Geavanceerd".
- Presets die "Gedeeltelijk" zijn (bijv. door nieuwe domeinen na een update) leggen uit waarom.
- Uitleg toont naast de standaardwaarde ook **jouw waarde**.
- Bytetellers boven 2 GB worden correct weergegeven.

**amtm**
- Uitsluitingenmanager volledig in het Nederlands, alle categorieën (incl. AI-assistenten) vóór de acties, letters voor acties en overal **E) Terug**.
- Nieuw: **Instellingen → 7) IPTV-apparaten kiezen** met apparaatnamen uit DHCP en ASUS-clientnamen; ook via `vpn_ipcatcher.sh choose-devices`.
- Statuskop toont vaste routes en de gekozen IPTV-apparaten.
- Eerste installatie vraagt direct na de VPN-keuze naar je IPTV-apparaten.

**Tests:** `tests/menu-checks.sh` en `tests/webui-flow-status-checks.sh`.

## 2.9.17 — Gastnetwerken weer meegenomen in de flow-scan

- **Herstel van een 2.9.16-beperking:** de flow-scan keek alleen naar het subnet van de capture-interface (`br0`). Apparaten op een gastnetwerk of IoT-VLAN (bijv. `192.168.179.x` via Guest Network Pro) werden daardoor niet meer geleerd. Nu telt elk apparaat in een privé-netwerk mee (10/8, 172.16/12, 192.168/16, 100.64/10).
- De router zelf blijft uitgesloten, nu op basis van al zijn eigen adressen (LAN, WAN en VPN-tunnels). Ook een WAN-adres in een privé-reeks (dubbele NAT) wordt zo herkend.
- amtm-menu: **VPN en routing → 3) Vaste routes tonen**.

## 2.9.16 — Vaste routes, minder CPU en betrouwbaardere caches

- **Vaste routes worden nooit geleerd.** IP Catcher leest elke minuut de VPN Director-regels (`/jffs/openvpn/vpndirector_rulelist`) en de Domain VPN Routing-policies (v3.2.5) uit. Bestemmingen uit VPN Director (ook WAN-regels), apparaten die VPN Director volledig routeert (alleen lokaal IP, geen extern IP), domeinen uit andere VPN Routing-policies en IP's in hun `DVR-<policy>-v4`-IPSets worden overgeslagen. Er volgt geen leer- of routecontrole: die regels bepalen zelf al VPN of WAN. Eerder geleerde IP's die nu vast gerouteerd zijn, worden uit de candidate/wacht/finale lijst gehaald (alleen eigen entries met `src=`-comment). Overzicht: `vpn_ipcatcher.sh fixed-routes`.
- **Veel minder CPU tijdens streamen.** tcpdump vangt alleen nog TLS-handshakes en HTTP-headers (BPF-filter op de eerste payloadbytes) in plaats van alle streamdata, en één awk-proces verwerkt de uitvoer. Voorheen startte elke tcpdump-regel twee tot drie extra processen.
- Bytes-promotie leest conntrack één keer per ronde in plaats van één keer per kandidaat; de flow-scan koppelt de vorige meting in één awk-pass (was O(n²)).
- De flow-scan kijkt alleen naar LAN-apparaten van de capture-interfaces en nooit naar de router zelf. Downloads van amtm-scripts, Skynet, AdGuardHome, spdMerlin, MerlinAU of Entware worden daardoor niet meer als stream geleerd.
- **DNS-cache verloopt nu na 5 minuten.** Voorheen bleef een domein-IP-koppeling tot de reboot bewaard, waardoor nieuwe CDN-adressen nooit werden geleerd en de cache onbeperkt groeide in RAM. Ontbrekende PTR-records worden nu ook gecachet (1 uur), zodat niet bij elke scan opnieuw `nslookup` draait. Caches worden begrensd.
- **Provider-ranges kunnen niet meer permanent vastlopen.** Een refresh die werd onderbroken (bijv. door een herstart) liet een lock of werkmap achter, waarna tot de volgende reboot niets meer werd ververst. Dode of verouderde locks worden nu opgeruimd.
- Zelfde typfout als in 2.9.14 hersteld op drie plekken (`.$` in plaats van een uniek pad) en tijdelijke bestanden/IPSets zijn nu uniek per worker; capture-workers op meerdere interfaces deelden voorheen hetzelfde tijdelijke bestand.
- Preset-menu: een nummer uit een eerder, langer menu kon een preset uit een andere categorie omzetten.
- Nieuwe opt-in presets: TikTok, HBO Max, SkyShowtime, NPO Start, Spotify, Twitch, cloudopslag (Dropbox/OneDrive) en snelheidstests (Ookla/nPerf/Fast); Prime Video uitgebreid met extra CDN-domeinen.
- Nieuwe regressietest `tests/fixed-routes-checks.sh`.

## 2.9.15 — Watchdog/PID herstel

- **Kritieke stabiliteitsfix:** 2.9.14 overschreef iedere 10 seconden het geldige proces-ID in `/tmp/vpn_ipcatcher.lock` en `/tmp/vpn_ipcatcher_pids/engine.pid` met een letterlijk dollarteken. De watchdog zag daardoor bij iedere cron-run een ongeldig engine-PID en herstartte de service telkens opnieuw (zoals in de gebruikerslog van 2026-10-27 tussen 02:09 en 02:12).
- De hoofdloop overschrijft het start-PID niet meer. Start schrijft de juiste numerieke PID eenmaal; de watchdog verifieert behalve een geldig nummer ook dat het PID bij de werkelijke `vpn_ipcatcher.real.sh run` hoort.
- Cleanup van een vorige engine mag de gedeelde PID-bestanden en capture/promote-workers van een nieuw gestart proces niet meer verwijderen.
- Nieuwe regressietest draait drie echte engine-hoofdloop-iteraties met mockworkers; test de PID/lock-integriteit, cleanup-eigenaarschap en weigering van ongeldige/dode/vreemde PID's.
- VPN- en EPG-routing, Google/Netflix-netwerken, provider-uitsluitingen en persoonlijke configuratie zijn inhoudelijk ongewijzigd.
- Na update is een gecontroleerde herstart aanbevolen om een eerder opgebouwde worker-herstartlus op te ruimen.


## 2.9.14 — Altijd-VPN voor EPG/XMLTV en handmatige domeinen

- **Altijd via VPN** in de WebGUI: plak een volledige HTTP(S) EPG/XMLTV-URL of hostnaam en kies de bestaande Domain VPN Routing-policy (met de juiste OpenVPN/WireGuard-client). Alleen de gevalideerde hostname wordt opgeslagen: geen URL-pad, token of inloggegevens.
- Directe `adddomain` + `querypolicy` van DVR v3.2.5, dus geen leerdrempel, wachtrij of automatische IPTV-herkenning. Controleer na verversen dat de host werkelijk als IPv4-bestemming in de gekozen DVR-IPSet staat; anders duidelijke foutmelding.
- Weiger hetzelfde expliciete domein in twee verschillende DVR-policies. Controleer dat de VPN-markering en tunnel beschikbaar zijn alvorens de DVR-lijst te wijzigen.
- **Automatisch beheerde IPTV-markregels** schrijven geen al ingestelde VPN-markering meer over (`-m mark --mark 0x0/0xf000`), inclusief herstel van eerdere onbeschermde markregels; bij VPN-wissel worden oude markregels met én zonder bescherming verwijderd. Bestaande handmatig beheerde DVR-markregels blijven onaangeraakt.
- Nieuwe regressietests voor EPG-URL-verwerking, privacy, DNS/route-check, dubbele policies en markvolgorde.
- **Begrenzing:** IP-routering kan bij gedeelde CDN-IP's niet per URL-pad differentiëren. Een HTTP-redirect naar een andere hostname is een afzonderlijke bestemming die apart via VPN gerouteerd moet worden. Cliënten moeten de DNS-antwoorden gebruiken die de DVR-policy heeft geleerd.


## 2.9.13 — Provider-owned network exclusions

- De uitsluitingen op domeinniveau worden aangevuld met **automatisch opgehaalde, door de provider aangekondigde IPv4-BGP-prefixen** voor geselecteerde eigen netwerken. De bron is RIPEstat (announced-prefixes), uitsluitend voor vooraf gecontroleerde ASNs: Google 15169/36040/19527, Netflix Open Connect 2906/40027, Meta 32934, GitHub 36459, Apple 714.
- Een provider is actief als een corresponderend domein in EXCLUDE_DOMAINS staat. Geselecteerde netwerkprefixen worden toegevoegd aan de bestaande _exclude hash:net-IPSet, niet aan een VPN-route. EXCLUDE_NETS/IPs, SOURCE_IPS en de NordVPN/DVR-policies blijven onveranderd.
- Eenmaal per dag controleren, zonder de IPTV-leerworker te blokkeren. Bij mislukte API-respons blijven de laatst gecontroleerde prefixen per provider behouden; atomisch vervangen van de exclusion-IPSet na opbouwen.
- WebGUI: PROVIDER_RANGE_AUTO aan/uit. SSH: provider-ranges-refresh en provider-ranges-status. De cache wordt persistent bewaard onder /jffs/addons/vpn_ipcatcher.d/provider_ranges.cache.
- Regressietests voor selectie, fallback, corrupte/gevaarlijk brede netwerken, batchgewijze IPSet-import en onbekende IPTV-adressen.
- **Beperkingen:** een ASN is niet hetzelfde als alle servers van een merk. Dahua/Imou en Reddit gebruiken gedeelde cloud/CDN-netwerken. AWS, Azure, Alibaba, Fastly en Cloudflare worden daarom niet volledig uitgesloten; bestaande DNS-uitsluitingen blijven hiervoor nodig. Geen IPv6-provider-IPSet of garantie op alle Google/Netflix-frontends. Dit voorkomt onnodig blokkeren van onbekende IPTV-hosting.
- Reeds geleerde conflicterende IPTV-IP's worden niet tijdens een stream gewist; gebruik clean-excluded wanneer geen stream actief is.


## 2.9.12

- Bekende Google/YouTube-omgeving beschermen: de aan YouTube LLC toegewezen IPv4-range `136.22.128.0/19` wordt niet langer geleerd door de IPTV-catcher. Dit bevat het door de gebruiker aangetroffen `136.22.151.14`.
- Dezelfde provider-exclusion wordt ook aan de runtime hash:net exclude-IPSet toegevoegd, zonder een nieuwe routeringspolicy aan te maken. Bestaande foutieve final-entries worden **niet automatisch tijdens actieve verbindingen** verwijderd; voer `clean-excluded` op een rustig moment uit.
- Nieuwe optionele Reddit-, Claude- en ChatGPT-presets in zowel WebGUI als amtm-menu. Bestaande gebruikersinstellingen en SOURCE_IPS blijven intact.
- Wanneer DNS-resolutie tijdelijk geen enkel IP oplevert, behoudt de resolver de vorige geldige cache en retourneert een fout. Het `resolve-excludes`-commando maskeert fouten niet langer.
- Extra regressietest voor het problematische Google-IP, grensgevallen en onbekende IPTV-bestemmingen.
- **Beperking:** deze gerichte YouTube/Google-range is niet de volledige Google-IP-ruimte. Een zuivere IPTV-classificatie is zonder protocol- of app-context onmogelijk op basis van alleen IP/bytes.


## 2.9.11

- De WebGUI uploadt bij opslaan uitsluitend gewijzigde velden, zodat het aanvinken van een gedeeltelijke Google Play-preset geen volledige routerconfiguratie opnieuw hoeft te versturen.
- Na bevestiging wordt de configuratie direct vanuit de router opnieuw geladen; de status Volledig/Gedeeltelijk komt voortaan overeen met de opgeslagen velden.
- Een opslagcontrole vergelijkt uitsluitend de daadwerkelijk gewijzigde uitsluitingsvelden.
- Tijdelijke upload-bevestiging krijgt weer unieke proces-PID in de bestandsnaam.
- Regressietest: bestaande twee gedeelde Google-domains, aanvinken nieuwe preset, daarna alle vier opgeslagen; niet-gerelateerde routing behouden.


## 2.9.10

- WebGUI wacht op expliciete routerbevestiging voor ieder configuratiedeel en verifieert uitsluitingen na opslaan.
- Onvolledige presetopslag toont een fout zonder de lokale wijzigingen te wissen.
- Geen wijzigingen aan VPN-route of automatisch aangevinkte opties.


## 2.9.9

- Herstelt de WebGUI die op **LADEN** bleef doordat `/www/user/vpn_ipcatcher_status.json` ontbrak.
- Herkent achtergebleven `vpn_ipcatcher_webui_status.lock` directories zonder PID, met wachttijd voor nieuwe locks en zonder actieve PID-locks te verwijderen.
- Geen recursieve verwijdering van onbekende lockinhoud; locks worden uitsluitend door de eigenaar vrijgegeven.
- Publicatie meldt voortaan een foutcode bij een bezette lock of mislukte JSON-output, in plaats van onterecht exitcode 0.
- Status wordt eerst tijdelijk geschreven, waar mogelijk als JSON gevalideerd en pas daarna atomair gepubliceerd.
- Regressietest voor actieve/stale/PID-loze locks, onbekende inhoud en opnieuw aanmaken van het JSON-statusbestand.
- Alleen WebGUI/statuspublicatie aangepast; geen wijziging aan VPN-configuratie, domeinregels of IPSets.


## 2.9.8

- Optionele, afzonderlijke preset **Google Play Store / app downloads** onder **OS / app updates**, zichtbaar in WebGUI en amtm.
- Nieuwe afzonderlijk aanvinkbare uitsluitdomeinen: `dl.google.com`, `play.googleapis.com`, `android.clients.google.com`, `redirector.gvt1.com`.
- Bestaande uitsluitingsresolver zoekt de IPv4-adressen automatisch op; geen vaste IP-lijst nodig.
- **Handmatig inschakelen:** de update wijzigt geen EXCLUDE_DOMAINS, SOURCE_IPS, bestaande VPN-routing of geleerde IPsets.
- Na opt-in kan de gebruiker de cache verversen (`resolve-excludes`) en eerder uitgesloten adressen gericht opruimen (`clean-excluded`).
- Uitsluiten is niet hetzelfde als verplicht via WAN sturen; gedeelde CDN-IPv4-adressen blijven een beperking.
- Regressietest voor opt-in, gedeelde WebGUI/amtm-registratie, presetstatus en IPv4-cache.


## 2.9.7

- Lokale Lifecycle-regels voor start/stop/restart, routing-setup, update/herstel en watchdog-herstel.
- Procesnummer, parent en ancestor met begrensde proces-/scriptnamen; geen volledige commandoregels, parameters of omgeving.
- Engine logt echte start/stopacties en procescontext bij INT/TERM. Externe signaalafzender blijft expliciet onbekend.
- Geen Skynet-aanpassingen, automatische firewall-uitzonderingen of extra netwerkverkeer.
- Regresstests voor lifecyclecontext, bewuste Stop, watchdog en het weglaten van geheime argumenten.

## 2.9.6

- Bij een mislukte routingvoorbereiding meteen een extra alleen-lezen routingcontrole uitvoeren.
- Lokale logregel bevat exitcodes en begrensde fouttekst van prepare en check; geen volledige routerdump of upload.
- Gelijke fouten maximaal eenmaal per vijf minuten loggen; gewijzigde fouten direct, herstel eenmaal melden.
- Vergrendelde routingvoorbereiding krijgt een expliciete melding, zodat deze niet wordt verward met een verdwenen VPN.
- Regresstests voor foutdetails, herhaalbegrenzing, gewijzigde oorzaak en herstel.

## 2.9.5

- Hotfix voor een live-update die bij 60% wordt geweigerd met 'Update bezig; start overgeslagen'.
- Interne starttoestemming wordt expliciet in een subshell geexporteerd, onafhankelijk van BusyBox-gedrag rond functie-assignments.
- De updateblokkering blijft actief; geen ongecontroleerde start door watchdog of gebruikerscommando tijdens het kopieren.
- Strikte regressietest controleert de interne marker bij een draaiende installatie, daarna rollback en foutafhandeling.
- Eenmalig bijwerken met install.sh update gebruikt de nieuwe updater; een oudere menu-updater blijft zelf de oude code uitvoeren.

## 2.9.4

- Onderhoudsrelease na vergelijking van alle 36 bestaande publieke bestanden en herhaling van de testreeks.
- WebUI toont effectieve enginewaarden, ook bij een minimale configuratie van een nieuwe installatie.
- Bewust lege domein-/netwerkuitsluitingen blijven leeg; verwijderde configvelden houden geen oude waarden vast.
- Verwijderde uitsluitdomeinen werken niet langer door via oude DNS-cacheregels. Gedeelde IPs bewaren hun afzonderlijke domeinkoppelingen.
- Timers met voorloopnullen worden als decimale waarden verwerkt, zonder octale rekenfouten.
- Diagnose sorteert tijden op echte tijdwaarden en verkeer op ongeronde bytes; nulwaarden blijven zichtbaar.
- CI controleert syntax van alle publieke shellscripts en start ook bij codewijzigingen en pull requests. Alleen main kan een release publiceren.
- Gewone release in plaats van prerelease; testdekking en praktische grenzen beschreven in TESTING.md.
- Geen reset van je instellingen, nieuwe standaarduitsluitingen of automatische WAN-fallback.

## 2.9.3

- Compact hoofdmenu met submenu's voor liveweergave, instellingen, VPN en onderhoud. E gaat terug; updateacties alleen UC/U/FU.
- Een bevestiging voor handmatige update inclusief verplichte lokale back-up; reset vraagt bevestiging.
- Rustige update-uitvoer: een voortgangsregel in een terminal, technische meldingen naar prive-log en back-uppad aan het einde.
- Losse presetkeuze duidelijker benoemd. Standaardwaarden en promotiemodi uitgelegd in de NL/EN WebUI.
- NL/EN stap-voor-stap installatie en volledige beschrijving van nieuwe menu's. Bestaande configuratie behouden.

## 2.9.2

- Vaste kolomkoppen in alle live-tabellen, ook tijdens scrollen.
- Klikbare kolomkoppen voor oplopend/aflopend sorteren; sortering per tab behouden bij verversen en wisselen van tab.
- Numerieke sortering voor IP-adressen, poorten, aantallen en leesbare verkeersvolumes.
- Desktop- en mobiele browsertests voor sortering, vaste koppen en scrollpositie.

## 2.9.0

- Diagnose-tijdlijn met waarnemingstijd, lokale zender-/gebeurtenismarkeringen, pauzeren/hervatten en JSON-export.
- Stoppen en verlopen bewaren maximaal 2000 waarnemingen in de geopende browserpagina; pagina herladen wist die geschiedenis.
- Optionele, begrensde DNS-meting voor het gekozen IPv4-apparaat: maximaal twee minuten / 400 UDP-DNS-pakketten. Alleen tijd, domein en antwoord-IP; geen URL, token of pakketbestand.
- DNS-domeinen worden als aanwijzing getoond, niet als bewezen dienst of route. Versleutelde DNS, gecachte antwoorden en IPv6 vallen buiten deze meting.
- Scrollpositie standaard behouden in alle live-tabbladen; actuele gegevens blijven verversen.
- Menu UC/U/FU, expliciete update/back-upbevestiging en een fasegebonden voortgangsbalk. Gewone update slaat dezelfde versie over; FU repareert die.
- Back-upbeheer (26): geselecteerd archief verwijderen, vijf kleine archieven behouden of oude programmakopieen opruimen. Actief herstelpunt, laatste twee programmakopieen en legacy-migratie blijven bij programma-opruiming behouden.
- Gewone updates herstellen nu ook de ASUS-eventkoppelingen, met herstel bij mislukte installatie.
- Dynamische geldigheid van de routingcontrole: twee scan-intervallen, minimaal vijftien seconden.
- Synthetische browser- en shelltests uitgebreid. Praktijktest op de router blijft nodig; geen garantie dat alle IPTV-fouten hiermee zijn opgelost.

## 2.8.9

- Diagnose-apparatenkeuze via de ASUS-clientlijst: online IPv4-apparaten op naam/IP, plus handmatige invoer.
- WebUI verstuurt action_script, action_wait en http_id elk precies eenmaal.
- Diagnose-start wacht op een unieke routerbevestiging; ontbrekende bevestiging is een zichtbare fout.
- Aparte statussen voor niet gestart, starten, actief zonder verbindingen, afgerond en fout.
- Live-tabbladen in drie kolommen met meegroeiende hoogte, zonder afgebroken woorden.
- Geen verandering aan VPN-routering; apparaatnamen blijven uitsluitend in de lokale browser.

## 2.8.8

- Aparte WebUI-diagnose voor een handmatig gekozen IPv4-apparaat, maximaal twee minuten.
- Verbindingsmomentopnamen op alle poorten, ook zonder bytecounters; geen leerdrempel of top-30-filter.
- Alleen protocol, bron/bestemming, doelpoort, verbindingsstatus en bytes; geen pakketinhoud of URL.
- Maximaal 2000 regels per momentopname met expliciete melding bij afkappen.
- Nieuwe ASUS-eventkoppeling; normale VPN-routering en configuratie blijven ongewijzigd.

## 2.8.7

- Liveweergave filteren op zoektekst, bronapparaat, poort en lijststatus.
- Zoektekst werkt ook in logs, status en IP-overzichten; filters blijven bij verversen behouden.
- Compactere statuskaarten, kop en live-tabbladen; minder hoge tabelregels.
- Verkeer leesbaar in B/KB/MB/GB, met exacte bytes bij aanwijzen.
- Deze wijziging verandert geen VPN-routing of persoonlijke instellingen.

## 2.8.6

- Het amtm-menu leest de versie uit het daadwerkelijk geopende script, ook vanuit een andere werkmap.
- Extra regressietest voor openen vanuit amtm; alle interfaceverbeteringen van 2.8.5 blijven behouden.

## 2.8.5

- Compact amtm-hoofdmenu met versienummer, VPN-keuze en korte servicestatus.
- WebUI toont de addon-versie, geselecteerde VPN en IP-lijst bovenaan.
- Instellingen gegroepeerd; geavanceerde velden en presetdetails inklapbaar.
- Duidelijke NL/EN-status voor uitsluitingen en zichtbare niet-opgeslagen wijzigingen.
- Lange uitsluitlijsten blijven binnen hun eigen scrollbare overzicht.
- VPN-namen worden gelezen zonder de ongeschikte `tr`-tekenklassen.
- Geen verandering aan bestaande VPN-selectie of persoonlijke configuratie.

## 2.8.4

- VPN-herkenning gebruikt vaste OpenVPN/WireGuard-sleutels in plaats van hoofdletteromzetting met `tr`.
- Werkt ook op Merlin-builds waar `tr` de POSIX-tekenklassen niet ondersteunt.
- Regresstest voor alle tien VPN-sleutels met een gesimuleerde ongeschikte `tr`.
- Controles op ontbrekende instellingen, juiste VPN-route en actieve tunnel blijven behouden.

## 2.8.3

- Aparte `migrate`-optie voor bestaande legacy-installaties zonder updater.
- Migratie controleert downloads en maakt een volledige prive-back-up voor wijzigingen.
- Ontbrekende helpers worden aangevuld; VPN-keuze wordt eenmalig gecontroleerd.
- Fouten tijdens migratie herstellen programma's, gewijzigde hooks en configuratie.
- Gestopte/onbekende engine blijft gestopt; gewone updates en crashherstel blijven beschikbaar.
- Installer en back-ups werken ook zonder het losse `id`-commando.
- Entry-point heeft nu een expliciete PATH voor cron/watchdog.
- Legacy terugzetten vereist de volledige back-up; geen onvolledige menu-rollback.

## 2.8.2

- WebUI-status-JSON blijft geldig bij tabs, aanhalingstekens, backslashes en andere log-controltekens.
- Regresstest controleert deze logregels in de echte statuspublisher.
- Automatische GitHub-testrelease met openbare downloads; 2.8.1 blijft onveranderd beschikbaar.

## 2.8.1

- Menu 24: kleine of uitgebreide privéback-up, zonder SSH-commando.
- Automatische kleine privéback-up voor installatie/update; update stopt bij back-upfouten.
- Menu 25: amtm personal-script-registratie met controle op ondersteuning, dubbelen en vier plaatsen.
- Reset van leerinstellingen behoudt de gekozen VPN/lijst en maakt eerst een back-up.
- WebUI toont de wachtlijst en bruikbare status in plaats van een tijdelijke placeholder; backend-, JavaScript- en NL/EN-tests toegevoegd.
- Volledig hoofdmenu en submenu-overzicht in beide talen op dezelfde GitHub-startpagina.
- Release-workflow test en publiceert openbare downloads als testrelease; routervalidatie blijft nodig.

## 2.8.0

- Kies alleen een VPN-nummer; bij een werkende VPN automatisch geselecteerd.
- LAN automatisch detecteren, geschikte lijst hergebruiken of eigen lijst/regels aanmaken.
- Eigen regels herstellen zonder andere DVR-policies over te nemen.
- Benodigde tcpdump/conntrack/jq via bestaande Entware installeren.
- Updates bewaren keuze en maken ook lokale snapshots van instellingen.
- Diagnostiek blijft read-only. Routervalidatie blijft nodig.

## 2.7.1

- Stel nieuwe finale routes uit zolang conntrack verbindingen naar het adres toont.
- Bewaar gekwalificeerde adressen in een niet-gerouteerde wacht-IPSet en probeer na idle opnieuw.
- Bescherm ook andere clients/poorten en UDP; blokkeer toevoegingen bij mislukte conntrackcontrole.
- Handmatig prive-back-uparchief via `backup.sh`, inclusief instellingen en hooks.
- Lokale regressietests voor streambescherming. Echte routervalidatie blijft nodig.

## 2.7.0

- Interactieve keuze van VPN-client, DVR-policy en LAN-capture-interface.
- Controle van tools, routingtabel, tunnel, markeringen en IPSet-schema.
- Finale learning pauzeert bij een mislukte routingcontrole.
- Eerste installatie en updates via het publieke `install.sh`.
- Uitgebreide Nederlandse uitleg over installatie, herstel en videoproblemen.

## 2.6.2

- Handmatige Stop geldt tot Start/Restart of routerreboot.
- Watchdog herstelt onverwachte crashes, niet een bewuste Stop.

## 2.6.1

- Tooldetectie zonder `command -v` voor beperkte routershells.

## 2.6.0

- Veiliger configuratieparser, kandidaatleeftijd en bytegebaseerde promotie.
- Veilige updates met checksums, back-up en rollback.
- Zorgvuldiger procesbeheer, startup-hooks en WebUI-installatie.
# 2.9.1

- Browser: updatecontrole/installatie/reparatie met bevestiging, lokale verplichte back-up en activiteitindicator.
- Browser: domein toevoegen aan bestaande DVR-policy via DVR v3.2.5, met uitgebreide back-up en validatie.
- NL/EN Uitleg-tab en losse presetitems onder Details.
- DNS-diagnose: expliciete capturestatus, PATH, TCP/UDP 53 en grotere begrensde packetlezing. Pauze behoudt scrollpositie.
- amtmupdate-protocol: opt-in, juiste check-exitcodes, alleen nieuwere versies; geen automatische centrale AU-registratie.
- Systeemcontrole gebruikt gekozen IPSet; wachtlijst verwerkt een conntrack-snapshot per batch.
- Firewall-herstart herstelt eigen gemarkeerde routingregels; overige addon-hooks blijven behouden.
- Merlin 3006.102.9-archief/checksum en changelog onderzocht; hardwarecompatibiliteit vereist routertest.
