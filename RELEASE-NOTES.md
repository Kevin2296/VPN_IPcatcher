# VPN IP Catcher 2.7.0

POSIX-shell addon voor Asuswrt-Merlin met interactieve VPN/policy-keuze en
controle van actieve routing voordat adressen worden geleerd. Een bestaande
geschikte Domain-based VPN Routing-policy is vereist.

Gebruik de installatie/updatecommando's in [README.md](README.md) via interactief
SSH. Oude installaties zonder veilige updater vereisen handmatige migratie en
een persoonlijke back-up.

De updater bewaart vorige programmabestanden lokaal. Terugzetten:
`/jffs/scripts/vpn_ipcatcher.sh rollback`. Persoonlijke instellingen blijven
staan; dit is geen volledige routerback-up.

## Beperkingen

- Routervalidatie blijft nodig; lokale tests bewijzen geen volledige compatibiliteit.
- Geen VPN-killswitch en geen IPv6-learning via de IPv4-lijst.
- Dynamische routing kan afhankelijk van firewallregels streams verstoren.
- Eerste installatie is niet volledig transactioneel bij onderbreking.

Publiceer alleen gecontroleerde programmacode en publieke documentatie.
Geen configuratie, sleutels, logs, opgeslagen VPN-keuzes of routerexports.
