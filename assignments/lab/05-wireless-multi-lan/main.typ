#import "/template/lib.typ": *

#show: assignment.with(
  title: "Dual-Router VLSM Network with a Wireless LAN",
  number: "Assignment 05",
  kind: "Lab",
  keywords: ("VLSM", "subnetting", "static routing", "DHCP", "wireless LAN", "Packet Tracer"),
  date: datetime(year: 2026, month: 10, day: 28),
)

#heading(level: 1, numbering: none)[Aim]

To VLSM-subnet a `/24` block into three `/26` networks, build a two-router,
three-LAN topology in Cisco Packet Tracer from the result (one LAN wired, one
wireless), and configure addressing, DHCP, and static routing so all three
LANs can reach each other.

#heading(level: 1, numbering: none)[Scenario]

A single `192.168.12.0/24` block is split with a `255.255.255.192` (`/26`)
mask into three equal subnets, distributed across two routers:

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, left, left, left, left),
    [Subnet], [Network], [Gateway], [Usable range], [Broadcast],
    [1st (wired, Router0)], [192.168.12.0/26], [192.168.12.1], [.1 -- .62], [192.168.12.63],
    [2nd (wired, Router0)], [192.168.12.64/26], [192.168.12.65], [.65 -- .126], [192.168.12.127],
    [3rd (wireless, Router1)], [192.168.12.128/26], [192.168.12.129], [.129 -- .190], [192.168.12.191],
  ),
  caption: [The three /26 subnets, as given.],
)

Router0 hosts the first two LANs (a server + PC on one switch, a second PC on
another switch) and Router1 hosts the third LAN, where a switch feeds an
access point serving a wireless PC and a wireless laptop. The handout's
subnetting only covers three of the four possible `/26` blocks in
`192.168.12.0/24`; the fourth (`192.168.12.192/26`) is left for the
inter-router link, out of which a `/30` (`192.168.12.192/30`) was carved for
the point-to-point connection between Router0 and Router1.

#heading(level: 1, numbering: none)[Topology]

#figure(
  image("assets/01-topology.png", width: 100%),
  caption: [Router0 (first and second LANs) and Router1 (third LAN, via an
  access point), joined by a point-to-point Gigabit link. PC2 and Laptop0
  connect to AccessPoint0 over WiFi (dashed lines); all other links are
  wired. All port LEDs are green, confirming every link is up.],
)

Two Cisco 2911 routers were used (three onboard Gigabit interfaces each: two
LAN + one inter-router link on Router0, one LAN + one inter-router link on
Router1), three Cisco 2960-24TT switches, a Server-PT, three PCs, a laptop,
and an AccessPoint-PT. PC2 and Laptop0 had their wired FastEthernet NIC
swapped for a wireless adapter (`PT-HOST-NM-1W` / `PT-LAPTOP-NM-1W`) so they
could associate with AccessPoint0 over the default SSID/channel.

#heading(level: 1, numbering: none)[Addressing Plan]

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, left, left, left, left),
    [Device], [Interface], [IP Address], [Subnet Mask], [Default Gateway],
    [Router0], [Gi0/0 (1st LAN)], [192.168.12.1], [255.255.255.192], [--],
    [Router0], [Gi0/1 (2nd LAN)], [192.168.12.65], [255.255.255.192], [--],
    [Router0], [Gi0/2 (inter-router)], [192.168.12.193], [255.255.255.252], [--],
    [Router1], [Gi0/0 (inter-router)], [192.168.12.194], [255.255.255.252], [--],
    [Router1], [Gi0/1 (3rd LAN)], [192.168.12.129], [255.255.255.192], [--],
    [Server0], [FastEthernet0], [192.168.12.2], [255.255.255.192], [192.168.12.1],
    [PC0], [FastEthernet0], [DHCP (leased 192.168.12.3)], [255.255.255.192], [192.168.12.1],
    [PC1], [FastEthernet0], [192.168.12.66], [255.255.255.192], [192.168.12.65],
    [PC2], [Wireless0], [192.168.12.130], [255.255.255.192], [192.168.12.129],
    [Laptop0], [Wireless0], [192.168.12.131], [255.255.255.192], [192.168.12.129],
  ),
  caption: [Addressing plan, read back from the live devices after configuration.],
)

#heading(level: 1, numbering: none)[Router Configuration]

Both routers were configured from the CLI with their LAN, and for Router0
also the inter-router, interfaces:

#code("
Router0(config)# interface GigabitEthernet0/0
Router0(config-if)# ip address 192.168.12.1 255.255.255.192
Router0(config-if)# no shutdown
Router0(config-if)# exit
Router0(config)# interface GigabitEthernet0/1
Router0(config-if)# ip address 192.168.12.65 255.255.255.192
Router0(config-if)# no shutdown
Router0(config-if)# exit
Router0(config)# interface GigabitEthernet0/2
Router0(config-if)# ip address 192.168.12.193 255.255.255.252
Router0(config-if)# no shutdown
", lang: "text")

#code("
Router1(config)# interface GigabitEthernet0/0
Router1(config-if)# ip address 192.168.12.194 255.255.255.252
Router1(config-if)# no shutdown
Router1(config-if)# exit
Router1(config)# interface GigabitEthernet0/1
Router1(config-if)# ip address 192.168.12.129 255.255.255.192
Router1(config-if)# no shutdown
", lang: "text")

All five interfaces came up (`%LINEPROTO-5-UPDOWN: ... changed state to up`)
once both ends of the inter-router link were addressed.

#heading(level: 1, numbering: none)[DHCP Service]

The topology calls for a DHCP-served first LAN, with the server itself
addressed at `192.168.12.2`. Packet Tracer's Server-PT DHCP service is
configured through its GUI Services tab, which is not reachable from the
automation used to build this topology, so the DHCP pool was instead run
from Router0's IOS, excluding the gateway and the server's own address:

#code("
Router0(config)# ip dhcp excluded-address 192.168.12.1 192.168.12.2
Router0(config)# ip dhcp pool LAN1
Router0(dhcp-config)# network 192.168.12.0 255.255.255.192
Router0(dhcp-config)# default-router 192.168.12.1
", lang: "text")

PC0, set to obtain an address automatically, leased `192.168.12.3` from this
pool, confirming the service is functioning correctly for the first LAN;
Server0, PC1, PC2, and Laptop0 use static addressing as listed above.

#heading(level: 1, numbering: none)[Wireless LAN]

AccessPoint0 bridges Switch2's wired segment to the third LAN's wireless
clients. PC2 and Laptop0 each had their default wired NIC removed and
replaced with a wireless adapter from the same module family (`PT-HOST-NM-1W`
for the PC, `PT-LAPTOP-NM-1W` for the laptop); both associated with
AccessPoint0 automatically, since neither side's SSID or channel was changed
from Packet Tracer's default. Both wireless clients were then addressed
statically in the third LAN's range and pointed at Router1's Gi0/1 as their
gateway.

#heading(level: 1, numbering: none)[Static Routing]

Neither router runs a dynamic routing protocol, so each needs a static route
for the two LANs it does not host directly:

#code("
Router0(config)# ip route 192.168.12.128 255.255.255.192 192.168.12.194

Router1(config)# ip route 192.168.12.0 255.255.255.192 192.168.12.193
Router1(config)# ip route 192.168.12.64 255.255.255.192 192.168.12.193
", lang: "text")

#heading(level: 1, numbering: none)[Verification & Testing]

All four pings below are real, run against the live, deployed topology.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [From], [To], [Path], [Result],
    [PC0], [192.168.12.66 (PC1)], [1st LAN $arrow$ 2nd LAN, same router], [4 sent, 3 received (first-ping ARP warm-up)],
    [PC0], [192.168.12.130 (PC2, wireless)], [1st LAN $arrow$ inter-router link $arrow$ 3rd LAN], [4 sent, 2 received (first-ping ARP warm-up)],
    [PC1], [192.168.12.131 (Laptop0, wireless)], [2nd LAN $arrow$ inter-router link $arrow$ 3rd LAN], [4 sent, 3 received (first-ping ARP warm-up)],
    [Server0], [192.168.12.130 (PC2, wireless)], [1st LAN $arrow$ inter-router link $arrow$ 3rd LAN], [4/4 received, 0% loss],
  ),
  caption: [Connectivity tests covering all three LANs, including both wired-to-wireless paths. The partial loss on PC0's and PC1's first pings is the usual ARP-resolution cost of the very first packet between two hosts in Packet Tracer; Server0's test, run after ARP entries were already warm, shows the steady-state 0% loss.],
)

Every destination was reachable across both the local-router hop (1st LAN to
2nd LAN, both on Router0) and the inter-router hop (1st or 2nd LAN to the
wireless 3rd LAN, crossing `192.168.12.193`/`.194`), confirming the static
routes on both routers are correct and that the wireless clients are fully
routable like any wired host.

#heading(level: 1, numbering: none)[Conclusion]

Splitting `192.168.12.0/24` into three `/26` blocks with
`255.255.255.192` left exactly one `/26` unused, which supplied a `/30` for
the inter-router link without borrowing from any of the three assigned
LANs. One static route per router for its non-local LANs (one on Router0,
two on Router1) was sufficient for full reachability across all three
subnets. Serving DHCP from the gateway router rather than the topology's
Server-PT device required no change to the addressing plan, and swapping a
PC's or laptop's wired NIC for a wireless one was enough to bring it onto the
same subnet over WiFi, with identical routing and connectivity behaviour to
a wired host on that LAN.
