# Wijzigingen

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
