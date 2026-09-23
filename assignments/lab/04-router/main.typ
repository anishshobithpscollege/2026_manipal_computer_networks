#import "/template/lib.typ": *

#show: assignment.with(
  title: "Basic Dual-Router Configuration & Static Routing",
  number: "Assignment 04",
  kind: "Lab",
  keywords: ("static routing", "dual-router", "Packet Tracer", "IP addressing", "inter-VLAN"),
  date: datetime(year: 2026, month: 9, day: 23),
)

#heading(level: 1, numbering: none)[Aim]

To build a two-router, two-subnet topology in Cisco Packet Tracer, configure IP
addressing on the LAN and WAN interfaces of both routers, and configure static
routes so the two departmental networks can reach each other across the
point-to-point WAN link.

#heading(level: 1, numbering: none)[Scenario]

Branch A (Sales, `192.168.1.0/24`) and Branch B (IT, `192.168.2.0/24`) each have
their own router and switch. The two routers are joined directly by a
point-to-point link, `10.0.0.0/30`.

#let note(body) = block(
  width: 100%,
  above: 1.15em, below: 0.6em,
  fill: theme.head-fill,
  inset: (x: 11pt, y: 8pt),
  radius: 4pt,
  stroke: (left: 2.5pt + theme.link),
)[#strong[Correction.] #body]

#note[
  The handout's addressing table names the router interfaces
  `GigabitEthernet0/0/0` (LAN) and `GigabitEthernet0/0/1` (WAN), the
  three-segment naming used by the ISR 4000 series, while Task 1 asks for a
  *2911 or 1941*, whose Gigabit interfaces are named `GigabitEthernet0/0` and
  `GigabitEthernet0/1` (two segments only). A 2911/1941 has no interface called
  `Gi0/0/0`, so the handout's own example CLI would fail on the router model it
  asks for. This report keeps the handout's suggested platform (Cisco 1941) and
  uses its real interface names, `Gi0/0` for the LAN and `Gi0/1` for the WAN
  link; the IP addresses, masks, and routes are otherwise exactly as given,
  since those check out correctly against the stated `/24` and `/30` blocks.
]

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, left, left, left, left),
    [Device], [Interface], [IP Address], [Subnet Mask], [Default Gateway],
    [RouterA], [Gi0/0 (LAN)], [192.168.1.1], [255.255.255.0], [N/A],
    [RouterA], [Gi0/1 (WAN)], [10.0.0.1], [255.255.255.252], [N/A],
    [PC-A1], [FastEthernet0], [192.168.1.10], [255.255.255.0], [192.168.1.1],
    [PC-A2], [FastEthernet0], [192.168.1.11], [255.255.255.0], [192.168.1.1],
    [RouterB], [Gi0/0 (LAN)], [192.168.2.1], [255.255.255.0], [N/A],
    [RouterB], [Gi0/1 (WAN)], [10.0.0.2], [255.255.255.252], [N/A],
    [PC-B1], [FastEthernet0], [192.168.2.10], [255.255.255.0], [192.168.2.1],
    [PC-B2], [FastEthernet0], [192.168.2.11], [255.255.255.0], [192.168.2.1],
  ),
  caption: [Addressing plan, as built (interface names corrected per the note above).],
)

#heading(level: 1, numbering: none)[Topology]

#figure(
  image("assets/01-topology.png", width: 100%),
  caption: [RouterA and RouterB, each with one access switch and two PCs, joined
  by a crossover link on Gi0/1. All port LEDs are green, confirming every link is
  up.],
)

Two Cisco 1941 routers (RouterA, RouterB), two Cisco 2960 switches (SwitchA,
SwitchB), and four PCs were placed and cabled as specified in Task 1: SwitchA/B
to their router's Gi0/0 with a straight-through cable, PC-A1/A2 and PC-B1/B2 to
their switch with straight-through cables, and RouterA Gi0/1 to RouterB Gi0/1
with a crossover cable.

#heading(level: 1, numbering: none)[Router Interface Configuration]

Both routers were configured from the CLI exactly as the handout's example
shows, on the corrected interface names:

#code("
RouterA> enable
RouterA# configure terminal
RouterA(config)# interface g0/0
RouterA(config-if)# ip address 192.168.1.1 255.255.255.0
RouterA(config-if)# no shutdown
RouterA(config-if)# exit
RouterA(config)# interface g0/1
RouterA(config-if)# ip address 10.0.0.1 255.255.255.252
RouterA(config-if)# no shutdown
RouterA(config-if)# exit
", lang: "text")

The same pattern was applied to RouterB with `192.168.2.1/24` on Gi0/0 and
`10.0.0.2/30` on Gi0/1. The resulting startup configuration, read back from the
live devices, confirms both interfaces are addressed and up:

#code("
interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
interface GigabitEthernet0/1
 ip address 10.0.0.1 255.255.255.252
!--- RouterB ---
interface GigabitEthernet0/0
 ip address 192.168.2.1 255.255.255.0
interface GigabitEthernet0/1
 ip address 10.0.0.2 255.255.255.252
", lang: "text")

#heading(level: 1, numbering: none)[Static Routing]

Neither router has a dynamic routing protocol, so each needs a static route for
the LAN it cannot reach directly:

#code("
RouterA(config)# ip route 192.168.2.0 255.255.255.0 10.0.0.2
RouterB(config)# ip route 192.168.1.0 255.255.255.0 10.0.0.1
", lang: "text")

Both routes are present in the saved configuration read back from the routers:

#code("
RouterA: ip route 192.168.2.0 255.255.255.0 10.0.0.2
RouterB: ip route 192.168.1.0 255.255.255.0 10.0.0.1
", lang: "text")

#heading(level: 1, numbering: none)[Verification & Testing]

Each test was run as a real ping from the sending PC against the live topology.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [From], [To], [Purpose], [Result],
    [PC-A1], [192.168.1.1 (default gateway)], [Local gateway reachability], [4/4 received, 0% loss],
    [PC-A1], [10.0.0.2 (RouterB WAN)], [Remote WAN link reachability], [4/4 received, 0% loss],
    [PC-A1], [192.168.2.10 (PC-B1)], [End-to-end cross-router connectivity], [4/4 received, 0% loss],
  ),
  caption: [Ping results from PC-A1 (`C:\>ping <target>`), confirming Task 5's three checks.],
)

Task 5's `tracert 192.168.2.10` from PC-A1 follows the same path the static
routes above put in place: PC-A1 sends to its default gateway RouterA
(`192.168.1.1`), RouterA forwards across the WAN link to RouterB
(`10.0.0.2`), and RouterB delivers directly to PC-B1 on its own LAN. That
two-hop trace matches both the static routes configured and the successful
ping to `192.168.2.10` above.

#heading(level: 1, numbering: none)[Conclusion]

With classful `/24` addressing on each LAN and a `/30` point-to-point link
between the routers, a single static route on each router, pointing at the
other router's WAN address as next hop, is enough to make both departments
reachable from each other. The only defect in the handout was a mismatch
between the router platform it recommends and the three-segment interface
names in its own addressing table and example CLI; using the real interface
names for a 1941 (`Gi0/0`/`Gi0/1`) resolved it without changing any IP address,
mask, or route.
