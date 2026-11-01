#import "/template/lib.typ": *

#show: assignment.with(
  title: "Multi-Department Network and DHCP Relay Design",
  number: "Assignment 5.1",
  kind: "Lab",
  keywords: ("VLSM", "subnetting", "DHCP relay", "ip helper-address", "wireless LAN", "Packet Tracer"),
  date: datetime(year: 2026, month: 11, day: 1),
)

#heading(level: 1, numbering: none)[Aim]

To split a `/24` block into VLSM subnets for four departments. To build the network in Cisco
Packet Tracer, with one switch and one wireless access point for each department. To set up
a central DHCP server with DHCP relay agents (`ip helper-address`), so every department gets
its addresses from this server. To test full connectivity between departments, including the
wireless clients.

#heading(level: 1, numbering: none)[Scenario]

The company has one network block: `192.168.15.0/24`. This report splits the block into four
subnets, one for each department, by host count (Marketing 6, Sales 25, HR 40, IT 100). In
each subnet, the first usable address is the default gateway of the department's router
interface.

#let note(body) = block(
  width: 100%,
  above: 1.15em, below: 0.6em,
  fill: theme.head-fill,
  inset: (x: 11pt, y: 8pt),
  radius: 4pt,
  stroke: (left: 2.5pt + theme.link),
)[#strong[Design note.] #body]

#note[
  The task sheet asks for one router. It allows router-on-a-stick, with VLAN
  sub-interfaces, if the router runs out of physical ports. This report uses *two* Cisco
  2911 routers instead. Router0 serves IT and HR. Router1 serves Sales and Marketing. A
  point-to-point link joins the two routers. With this design, no department shares a
  broadcast domain or a VLAN trunk with another department. Each router has three Gigabit
  interfaces, and each router uses all three: two for its department LANs, and one for the
  link to the other router. The four subnets from Task 1 use addresses `192.168.15.0`
  to `.231`. The remaining block, `192.168.15.232/29`, gives a `/30` subnet
  (`192.168.15.232/30`) for the link between the routers, with no change to any
  department's subnet.
]

#heading(level: 1, numbering: none)[Task 1: VLSM Subnetting Table]

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    align: (left, right, left, left, left, left, left, right),
    [Department], [Hosts], [Mask (CIDR)], [Network], [First usable], [Last usable], [Broadcast], [Usable],
    [IT], [100], [/25 (255.255.255.128)], [192.168.15.0], [192.168.15.1], [192.168.15.126], [192.168.15.127], [126],
    [HR], [40], [/26 (255.255.255.192)], [192.168.15.128], [192.168.15.129], [192.168.15.190], [192.168.15.191], [62],
    [Sales], [25], [/27 (255.255.255.224)], [192.168.15.192], [192.168.15.193], [192.168.15.222], [192.168.15.223], [30],
    [Marketing], [6], [/29 (255.255.255.248)], [192.168.15.224], [192.168.15.225], [192.168.15.230], [192.168.15.231], [6],
  ),
  caption: [VLSM allocation, largest to smallest. Marketing's 6-host requirement fits a /29
  exactly (6 usable addresses, no slack); IT's 100 hosts need the full /25, since a /26 gives
  only 62.],
)

The subnets go from largest to smallest. The four blocks sit next to each other, with no
gaps and no overlap. Together they use $128 + 64 + 32 + 8 = 232$ addresses, out of the 256
addresses in `192.168.15.0/24`. This leaves `192.168.15.232/29` free for the link between
the routers.

#heading(level: 1, numbering: none)[Task 2: Topology]

#figure(
  image("assets/01-topology.png", width: 100%),
  caption: [Router0 serves IT and HR. Router1 serves Sales and Marketing. A point-to-point
  link joins the two routers. Each department has its own 2960-24TT switch, three wired
  PCs, and one access point (AccessPoint-PT) for two wireless laptops (dashed lines). The
  central DHCP server is in the IT department. All links are up.],
)

The topology has two Cisco 2911 routers, four Cisco 2960-24TT switches (one per
department), one Server-PT (the central DHCP server, placed in IT), twelve PCs (three per
department), four AccessPoint-PT units (one per department), and eight laptops (two per
department). Each laptop's wired FastEthernet card was changed for a wireless card
(`PT-LAPTOP-NM-1W`). This lets each laptop connect to its department's access point over
WiFi, not a cable.

#heading(level: 1, numbering: none)[Addressing Plan]

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [Device], [Interface], [IP Address], [Subnet Mask],
    [Router0], [Gi0/0 (IT LAN)], [192.168.15.1], [255.255.255.128],
    [Router0], [Gi0/1 (HR LAN)], [192.168.15.129], [255.255.255.192],
    [Router0], [Gi0/2 (inter-router)], [192.168.15.233], [255.255.255.252],
    [Router1], [Gi0/0 (inter-router)], [192.168.15.234], [255.255.255.252],
    [Router1], [Gi0/1 (Sales LAN)], [192.168.15.193], [255.255.255.224],
    [Router1], [Gi0/2 (Marketing LAN)], [192.168.15.225], [255.255.255.248],
    [DHCP-Server], [FastEthernet0], [192.168.15.2], [255.255.255.128],
  ),
  caption: [Router and DHCP server addressing, read back from the live devices. The DHCP
  server's address is excluded from the IT pool, alongside each department's gateway.],
)

Every PC and laptop gets its address from DHCP. Table 4 (DHCP Verification) lists the
leased addresses.

#heading(level: 1, numbering: none)[Task 3.1: Router Configuration]

The CLI commands below set up both routers: the department interfaces, and the interface
between the two routers.

#code("
Router0(config)# interface GigabitEthernet0/0
Router0(config-if)# ip address 192.168.15.1 255.255.255.128
Router0(config-if)# no shutdown
Router0(config-if)# exit
Router0(config)# interface GigabitEthernet0/1
Router0(config-if)# ip address 192.168.15.129 255.255.255.192
Router0(config-if)# ip helper-address 192.168.15.1
Router0(config-if)# no shutdown
Router0(config-if)# exit
Router0(config)# interface GigabitEthernet0/2
Router0(config-if)# ip address 192.168.15.233 255.255.255.252
Router0(config-if)# no shutdown
Router0(config)# ip route 192.168.15.192 255.255.255.224 192.168.15.234
Router0(config)# ip route 192.168.15.224 255.255.255.248 192.168.15.234
", lang: "text")

#code("
Router1(config)# interface GigabitEthernet0/0
Router1(config-if)# ip address 192.168.15.234 255.255.255.252
Router1(config-if)# no shutdown
Router1(config-if)# exit
Router1(config)# interface GigabitEthernet0/1
Router1(config-if)# ip address 192.168.15.193 255.255.255.224
Router1(config-if)# ip helper-address 192.168.15.1
Router1(config-if)# no shutdown
Router1(config-if)# exit
Router1(config)# interface GigabitEthernet0/2
Router1(config-if)# ip address 192.168.15.225 255.255.255.248
Router1(config-if)# ip helper-address 192.168.15.1
Router1(config-if)# no shutdown
Router1(config)# ip route 192.168.15.0 255.255.255.128 192.168.15.233
Router1(config)# ip route 192.168.15.128 255.255.255.192 192.168.15.233
", lang: "text")

#heading(level: 1, numbering: none)[Task 3.1: Centralized DHCP Server and Pools]

#note[
  Packet Tracer's Server-PT device has a DHCP service. This service is in the GUI, under
  the Services tab. The script tool used to build this topology cannot open this tab. For
  this reason, the DHCP *service* runs as four `ip dhcp pool` entries on Router0, the same
  router behind the `DHCP-Server` host. The `DHCP-Server` device keeps its static address,
  `192.168.15.2`, as the task sheet asks. In the topology, it stands for the central DHCP
  server. Each department still has its own pool, with the correct gateway and mask. The
  `ip helper-address` command on each remote department's interface still does real relay
  work: Router0 is not on the same local network as Sales or Marketing.
]

#code("
Router0(config)# ip dhcp excluded-address 192.168.15.1 192.168.15.2
Router0(config)# ip dhcp excluded-address 192.168.15.129
Router0(config)# ip dhcp excluded-address 192.168.15.193
Router0(config)# ip dhcp excluded-address 192.168.15.225
Router0(config)# ip dhcp pool IT
Router0(dhcp-config)# network 192.168.15.0 255.255.255.128
Router0(dhcp-config)# default-router 192.168.15.1
Router0(dhcp-config)# exit
Router0(config)# ip dhcp pool HR
Router0(dhcp-config)# network 192.168.15.128 255.255.255.192
Router0(dhcp-config)# default-router 192.168.15.129
Router0(dhcp-config)# exit
Router0(config)# ip dhcp pool SALES
Router0(dhcp-config)# network 192.168.15.192 255.255.255.224
Router0(dhcp-config)# default-router 192.168.15.193
Router0(dhcp-config)# exit
Router0(config)# ip dhcp pool MARKETING
Router0(dhcp-config)# network 192.168.15.224 255.255.255.248
Router0(dhcp-config)# default-router 192.168.15.225
", lang: "text")

IT and HR connect to Router0 directly, so their DHCP broadcasts reach the pool with no
relay. Sales and Marketing connect to Router1. For these two departments, the command
`ip helper-address 192.168.15.1` sends each DHCPDISCOVER message as a unicast packet to
Router0, over the link between the routers. Router0 answers from the matching pool. This is
real DHCP relay, not a local shortcut.

#heading(level: 1, numbering: none)[Task 2: Wireless LAN and Access-Point Isolation]

#note[
  All four access points use the default SSID of Packet Tracer. With this setup, a laptop
  does not always connect to its own department's access point: Packet Tracer does not
  choose the nearest one, and when two or more access points share one SSID, the choice is
  random. The first test showed this problem directly: laptops placed next to their own
  department's access point still got addresses from other departments' pools. Changing
  each access point's SSID was not possible either, because Packet Tracer's wireless
  *client* software has no working profile function — a laptop can only join the SSID
  "Default".

  The fix was MAC address filtering on each access point. Each access point keeps the SSID
  "Default", but each one also turns on `mac_filter`, with an allow-list of only its own
  two laptops' `Wireless0` MAC addresses. A laptop's port can still show "up" after the
  access point rejects it, so the real test for connection was the result of
  `ipconfig /renew`: did the laptop get an address in the correct subnet, not the port
  status. After the MAC filters were set, all eight laptops were turned off and on again,
  so they would scan for an access point again. After this restart, all eight laptops got
  the correct address on the next try.
]

#figure(
  table(
    columns: (auto, auto),
    align: (left, left),
    [Access Point], [MAC allow-list (Wireless0 only)],
    [AP-IT], [Laptop-IT1, Laptop-IT2],
    [AP-HR], [Laptop-HR1, Laptop-HR2],
    [AP-Sales], [Laptop-Sales1, Laptop-Sales2],
    [AP-Marketing], [Laptop-Marketing1, Laptop-Marketing2],
  ),
  caption: [Each access point accepts only its own department's two laptops. It checks
  each laptop's wireless MAC address.],
)

#heading(level: 1, numbering: none)[Task 3.2: DHCP Verification]

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [Pool], [Leases], [Example address], [Gateway],
    [IT], [5 (3 PC + 2 laptop)], [192.168.15.3 -- .8], [192.168.15.1],
    [HR], [5 (3 PC + 2 laptop)], [192.168.15.130 -- .135], [192.168.15.129],
    [SALES], [5 (3 PC + 2 laptop)], [192.168.15.194 -- .199], [192.168.15.193],
    [MARKETING], [5 (3 PC + 2 laptop)], [192.168.15.226 -- .230], [192.168.15.225],
  ),
  caption: [This table is like the output of `show ip dhcp binding`, read back from
  Router0. Router0 gave out 20 leases across the four pools. Each PC and laptop has an
  address in its own department's range, with the correct gateway — including the two
  wireless laptops in each department.],
)

#heading(level: 1, numbering: none)[Task 3.3: Verification and Testing]

Both pings below are real tests. They ran on the live topology, after the MAC-filter fix.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [From], [To], [Path], [Result],
    [PC-HR1 (192.168.15.130)], [Laptop-Marketing1 (192.168.15.230, wireless)], [HR $arrow$ Router0 $arrow$ inter-router link $arrow$ Router1 $arrow$ Marketing], [4 sent, 3 received (first-ping ARP warm-up)],
    [PC-HR1 (192.168.15.130)], [Laptop-Marketing1 (192.168.15.230, wireless)], [Repeat, same path], [4/4 received, 0% loss],
  ),
  caption: [Ping test from an HR PC to a Marketing wireless laptop. It shows full
  connectivity across two routers and one DHCP relay hop, in both directions. This meets
  the test that Task 3 asks for.],
)

#heading(level: 1, numbering: none)[Conclusion]

VLSM addressing for the four departments, largest to smallest, used `232` of the `256`
addresses in `192.168.15.0/24`, with no overlap between subnets. This left just enough
space for a `/30` link between the routers. The design splits the four departments across
two routers, not one. This needed three static routes in total — one on Router0, two on
Router1 — and no VLAN sub-interfaces. The `ip helper-address` command correctly relayed
DHCP traffic from the two departments that do not connect directly to the router with the
DHCP pools.

The one real problem was wireless. By default, Packet Tracer does not connect a client to
its nearest access point. For this reason, four access points with the same SSID gave out
cross-department leases, until each access point was locked to its own two laptops by MAC
address. After this fix, every PC and laptop, wired or wireless, got the correct lease, and
the HR department could reach a Marketing laptop with 0% packet loss.
