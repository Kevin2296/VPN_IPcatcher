# Wijzigingen

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
