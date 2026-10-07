# Wijzigingen

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
