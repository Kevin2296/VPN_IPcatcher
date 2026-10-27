# PR #9: explicit VPN policies before dynamic learning

Draft branch only. Do not install this branch on a production router or merge it
until isolated ASUS validation below is complete. No router was changed during
development. The release version remains 2.9.15; this is not a published release.

## Behavior

* Merlin's `/jffs/openvpn/vpndirector_rulelist` is read as
  `<enabled>description>source>destination>WAN|OVPNn|WGCn`. Only enabled records
  count. Missing, unreadable or malformed data fails validation; it does not mean
  that no policies exist. IPv4 addresses and CIDRs are validated with POSIX awk.
* Every explicit source is protected from learning and Catcher marking, including
  source+destination rules. Protecting the whole source is deliberately
  conservative. Explicit remote destinations are also protected, including WAN
  rules. `/0` is represented by two `/1` entries for hash:net compatibility.
* The additional `BYPASS_SOURCE_IPS` setting accepts space-separated IPv4 hosts.
  It supplements automatic discovery; an empty field does not disable discovery.
  WebUI shows the effective protected sources and last routing validation state.
* Private `VPNIPC-SOURCE` and `VPNIPC-REMOTE` hash:net sets and a
  `VPNIPC-DOMAINS` list:set guard owned marks in PREROUTING and OUTPUT. All
  explicit DVR policy sets, including WAN and the original manually bound set,
  are protected. Live changes to their members take effect immediately, even
  when a destination is also in Catcher's learned set. Existing nonzero VPN
  marks are never overwritten. Unsupported DVR mark masks are rejected.
* Catcher owns a separate `0x1000000/0x1000000` bit. Its RPDB lookup at 31000
  follows Director/DVR policy rules and is followed by a permanent unreachable
  rule at 31001, before main. This preserves precedence for newly applied source
  rules before the next guard refresh. Conflicting priorities, masks or late
  explicit rules are refused. Other mark bits are preserved. Existing owned DVR
  marks are migrated under HOLD, without changing the external DVR RPDB rules.
* DVR and Director keep their own relative policy ordering and offline policy.
  Catcher does not add WAN rules, change their killswitch settings, flush foreign
  firewall chains, or rewrite external policy files/sets. A missing explicit
  policy set is ambiguous and blocks Catcher validation. IPv6 is not learned or
  marked by this IPv4 tool; it must be managed by the router's IPv6 VPN policy.
* Owned filter REJECT rules in FORWARD and OUTPUT reject unprotected learned
  destinations without an explicit DVR mark leaving through anything other than
  the validated tunnel. They also work if another rule clears the Catcher bit. They
  remain in place if the tunnel or RPDB lookup disappears, including between
  checks, so ordinary fall-through to main cannot expose WAN traffic. A failed
  prepare also installs a conservative HOLD for the owned final set. Existing
  guards/marks remain; learning readiness is withdrawn. Successful validation
  removes HOLD. This can temporarily block more traffic than the explicit policy
  would require. It never silently selects WAN as an availability workaround.

Source filtering applies to tcpdump HTTP/generic/Location learning, conntrack
flow learning and byte promotion. The learning check reads current Director
policy as well as the kernel guard, without waiting for periodic guard refresh.
Capture checks both packet endpoints once per packet, including server responses
to protected clients, so an old BPF cannot bypass a newly discovered source.
Orphan payload and IPv6 headers are rejected. Candidate/age queues may retain
historical destination-only evidence; protected sources still cannot be marked.

## Installation, migration and recovery

The existing installer/updater backup and stop/start flow remains in use. New
installations choose an owned `DVR-VIPC-<connection>-v4` set. `routing prepare`
automatically migrates a legacy manually bound DVR set to an owned empty list.
It does not copy the mixed old list: there is no reliable way to tell previous
learned addresses from explicit policy entries. The old DVR list and all its
existing routes remain unchanged and protected. Consequently, historical learned
entries that were already mixed into that external list still follow DVR until
the user reviews them through DVR. Catcher cannot safely delete those entries.

The original config/selection are preserved privately in
`/jffs/addons/vpn_ipcatcher.d/precedence-migration/`. Config and selection use
temporary files and rename. A pending journal restores both originals after an
interrupted migration; failed journals are retained for inspection. A normal
failed transaction restores both immediately. Only one routing/config operation
is allowed by the existing config lock.

To undo a completed binding migration, first stop Catcher through its normal
menu, then use the routing helper's `rollback-migration` command. It refuses an
active engine lock, holds the owned destinations while removing only owned
rules, restores both saved files, validates the original binding, and only then
releases HOLD. If validation fails it stays blocked. Restore the known-good
program backup before restarting the old shared setup, or run routing setup to
choose an owned list again. Never delete an external DVR set as rollback.

Guards are staged and swapped under HOLD when policy membership changes. Stable
checks do not rewrite the ownership file or rebuild sets. Runtime status and
membership signatures live in `/tmp`, avoiding periodic JFFS writes. Old staging
list references are flushed after swap. Live list:set references mean a DVR
policy deletion/recreation must be checked in isolated QA: they can temporarily
prevent deletion of a referenced set until the next guard refresh. Failure is
reported and blocked rather than guessed around.

## Validation boundaries and isolated ASUS gate

`tests/precedence-checks.sh` executes the production adapter with stateful command
models and evaluates the emitted packet rules. It covers host/CIDR bypass,
disabled Director rules, remote/WAN rules, overlap and live DVR member changes,
foreign marks, offline WAN rejection, invalid/missing files, manual migration,
rollback, journal recovery and production HTTP capture. Engine regressions test
that bypassed download bytes cannot promote a destination; WebUI tests cover
validation, persistence, clearing and status. CI additionally runs this suite in
BusyBox ash with BusyBox awk. Existing watchdog PID tests must keep passing:
the 2.9.14 PID corruption fix is preserved and the main loop never rewrites it.

These are synthetic checks, not proof of netfilter, hardware acceleration,
conntrack or firmware behavior. Before merge/deployment, use a disposable ASUS
test router/config with console recovery and a private full backup:

1. Verify ipset hash:net/list:set support and canonical `iptables -S` rendering;
   check first install, old guarded/unguarded rule migration and repeated hooks.
2. Test both OpenVPN and WireGuard source hosts/subnets, different domain VPNs,
   overlapping CDN IPs, explicit WAN, and a genuinely dynamic destination. Verify
   actual egress externally, with both DVR-before-Catcher and reverse rule order.
3. Remove the tunnel and its RPDB rule separately while traffic is active; capture
   on WAN and prove no dynamic VPN traffic escapes. Check strict and permissive
   existing Director/DVR offline policies without changing those policies.
4. Exercise Director edits, DVR query/add/delete/recreate, firewall reload, reboot,
   active conntrack and acceleration. Check temporary HOLD recovery and logs.
5. Interrupt migration between each rename, restore via journal/rollback and the
   full program backup. Observe at least two watchdog cron runs and verify stable
   numeric owner PIDs, worker count, process/CPU load and uninterrupted playback.

Upstream references inspected on 2026-10-27:
[Merlin routing implementation](https://github.com/RMerl/asuswrt-merlin.ng/blob/main/release/src/router/libovpn/amvpn_routing.c)
(blob `ac8c89ff52d370f1d84b502feb3b469fcad29c75`) and
[Ranger802004 DVR v3.2.5](https://github.com/Ranger802004/asusmerlin/blob/main/domain_vpn_routing/domain_vpn_routing.sh).
