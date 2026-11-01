#import "/template/lib.typ": *

#show: assignment.with(
  title: "MSIS Campus Network: Subnetting, Routing, DHCP and DNS",
  number: "Assignment 06",
  kind: "Lab",
  keywords: ("VLSM", "subnetting", "static routing", "DHCP relay", "DNS", "HTTP", "wireless LAN", "Packet Tracer"),
  date: datetime(year: 2026, month: 11, day: 2),
)

#heading(level: 1, numbering: none)[Aim]

To VLSM-subnet `172.16.0.0/16` for four MSIS departments, build the resulting topology in
Cisco Packet Tracer, configure static routing, two centralized DHCP servers with DHCP relay,
a DNS server, and an HTTP web server, and verify end-to-end connectivity including DNS-based
web access from a wireless client.

#heading(level: 1, numbering: none)[Scenario]

Four departments share `172.16.0.0/16`: CDC (Career Development Center), CYS (Cyber
Security), VLSI (VLSI Design), and MVT (Medical Verification & Testing). Router R1 connects
CDC and CYS; Router R2 connects VLSI and MVT, joined to R1 by a dedicated link. DHCP Server 1
sits in CDC and serves the CDC and CYS pools; DHCP Server 2 sits in VLSI and serves the VLSI
and MVT pools. A DNS server in MVT resolves `www.msis.edu` to an HTTP server in VLSI, which
hosts the MSIS web portal.

#let note(body) = block(
  width: 100%,
  above: 1.15em, below: 0.6em,
  fill: theme.head-fill,
  inset: (x: 11pt, y: 8pt),
  radius: 4pt,
  stroke: (left: 2.5pt + theme.link),
)[#strong[Correction.] #body]

#note[
  Task 1's host counts (CDC 13, VLSI 6) size each subnet for its *end-user* PCs and laptops
  plus a gateway, but Task 2 also places an infrastructure server inside CDC (DHCP Server 1)
  and *two* inside VLSI (DHCP Server 2 and the HTTP server) — addresses Task 1's own numbers
  do not budget for. VLSI is the one that actually breaks: a `/29` has only 6 usable
  addresses, but VLSI alone needs 1 gateway + 5 end devices (3 PCs, 2 laptops) + 2 servers = 8.
  This report sizes VLSI as a `/28` (14 usable) instead, which absorbs the two extra servers
  with room to spare and does not require moving any other department's block. CDC's `/28` (14
  usable) already covers its 1 gateway + 5 end devices + 1 server (7 of 14) without changes.
]

#heading(level: 1, numbering: none)[Task 1: VLSM Subnetting Table]

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    align: (left, right, left, left, left, left, left, right),
    [Subnet], [Hosts], [Mask (CIDR)], [Network], [First usable], [Last usable], [Broadcast], [Usable],
    [MVT], [102], [/25 (255.255.255.128)], [172.16.0.0], [172.16.0.1], [172.16.0.126], [172.16.0.127], [126],
    [CYS], [28], [/27 (255.255.255.224)], [172.16.0.128], [172.16.0.129], [172.16.0.158], [172.16.0.159], [30],
    [CDC], [13], [/28 (255.255.255.240)], [172.16.0.160], [172.16.0.161], [172.16.0.174], [172.16.0.175], [14],
    [VLSI], [6 $arrow.r$ 14], [/28 (255.255.255.240)], [172.16.0.176], [172.16.0.177], [172.16.0.190], [172.16.0.191], [14],
    [R1--R2 Link], [2], [/30 (255.255.255.252)], [172.16.0.192], [172.16.0.193], [172.16.0.194], [172.16.0.195], [2],
  ),
  caption: [VLSM allocation, largest to smallest, with VLSI corrected from /29 to /28 per the
  note above. The five blocks use $128+32+16+16+4=196$ addresses, contiguous and
  non-overlapping, out of the 256 in the first `/24` of the allocated `/16`.],
)

#heading(level: 1, numbering: none)[Task 2: Topology]

#figure(
  image("assets/01-topology.png", width: 100%),
  caption: [R1 (CDC + CYS) and R2 (VLSI + MVT), joined by a point-to-point link. Each
  department has its own switch, three wired PCs, and an access point for two wireless
  laptops (dashed lines). DHCP Server 1 is in CDC; DHCP Server 2 and the HTTP server are in
  VLSI; the DNS server is in MVT. All links are up.],
)

The topology has two Cisco 2911 routers (R1, R2), four Cisco 2960-24TT switches (one per
department), four Server-PT devices (DHCP Server 1, DHCP Server 2, the HTTP server, and the
DNS server), twelve PCs (three per department), four AccessPoint-PT units (one per
department), and eight laptops (two per department). Each laptop's wired FastEthernet card
was changed for a `Linksys-WPC300N` wireless card, as the brief specifies, so it connects to
its department's access point over WiFi.

#heading(level: 1, numbering: none)[Addressing Plan]

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [Device], [Interface], [IP Address], [Subnet Mask],
    [R1], [Gi0/0 (CDC)], [172.16.0.161], [255.255.255.240],
    [R1], [Gi0/1 (CYS)], [172.16.0.129], [255.255.255.224],
    [R1], [Gi0/2 (inter-router)], [172.16.0.193], [255.255.255.252],
    [R2], [Gi0/0 (inter-router)], [172.16.0.194], [255.255.255.252],
    [R2], [Gi0/1 (VLSI)], [172.16.0.177], [255.255.255.240],
    [R2], [Gi0/2 (MVT)], [172.16.0.1], [255.255.255.128],
    [DHCP Server 1], [FastEthernet0], [172.16.0.162], [255.255.255.240],
    [DHCP Server 2], [FastEthernet0], [172.16.0.178], [255.255.255.240],
    [HTTP Server], [FastEthernet0], [172.16.0.179], [255.255.255.240],
    [DNS Server], [FastEthernet0], [172.16.0.2], [255.255.255.128],
  ),
  caption: [Router and server addressing, read back from the live devices.],
)

#heading(level: 1, numbering: none)[Task 3.1: Router Configuration (Static Routing)]

#code("
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip address 172.16.0.161 255.255.255.240
R1(config-if)# no shutdown
R1(config-if)# exit
R1(config)# interface GigabitEthernet0/1
R1(config-if)# ip address 172.16.0.129 255.255.255.224
R1(config-if)# ip helper-address 172.16.0.162
R1(config-if)# no shutdown
R1(config-if)# exit
R1(config)# interface GigabitEthernet0/2
R1(config-if)# ip address 172.16.0.193 255.255.255.252
R1(config-if)# no shutdown
R1(config)# ip route 172.16.0.176 255.255.255.240 172.16.0.194
R1(config)# ip route 172.16.0.0 255.255.255.128 172.16.0.194
", lang: "text")

#code("
R2(config)# interface GigabitEthernet0/0
R2(config-if)# ip address 172.16.0.194 255.255.255.252
R2(config-if)# no shutdown
R2(config-if)# exit
R2(config)# interface GigabitEthernet0/1
R2(config-if)# ip address 172.16.0.177 255.255.255.240
R2(config-if)# no shutdown
R2(config-if)# exit
R2(config)# interface GigabitEthernet0/2
R2(config-if)# ip address 172.16.0.1 255.255.255.128
R2(config-if)# ip helper-address 172.16.0.178
R2(config-if)# no shutdown
R2(config)# ip route 172.16.0.160 255.255.255.240 172.16.0.193
R2(config)# ip route 172.16.0.128 255.255.255.224 172.16.0.193
", lang: "text")

Each router has one static route per remote department: R1 to VLSI and MVT (behind R2), R2 to
CDC and CYS (behind R1).

#heading(level: 1, numbering: none)[Task 3.2: DHCP Servers and Relay Agent]

DHCP Server 1 hosts two pools, both with the CDC/CYS default gateways and the DNS server's
address:

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, left, left, left, left),
    [Server], [Pool], [Network], [Range], [Gateway / DNS],
    [DHCP Server 1], [CDC], [172.16.0.160/28], [172.16.0.163 -- .174], [172.16.0.161 / .2],
    [DHCP Server 1], [CYS], [172.16.0.128/27], [172.16.0.130 -- .158], [172.16.0.129 / .2],
    [DHCP Server 2], [VLSI], [172.16.0.176/28], [172.16.0.180 -- .190], [172.16.0.177 / .2],
    [DHCP Server 2], [MVT], [172.16.0.0/25], [172.16.0.3 -- .126], [172.16.0.1 / .2],
  ),
  caption: [DHCP pools, read back from each server's Services $>$ DHCP configuration.],
)

CDC and VLSI each sit on the same LAN as their own DHCP server, so their broadcasts reach the
pool directly. CYS and MVT do not, so each router relays for its remote department:

#code("
R1(config-if)# ip helper-address 172.16.0.162    (on Gi0/1, the CYS interface, toward DHCP Server 1 in CDC)
R2(config-if)# ip helper-address 172.16.0.178    (on Gi0/2, the MVT interface, toward DHCP Server 2 in VLSI)
", lang: "text")

#note[
  With all four access points left on Packet Tracer's default SSID, wireless association
  across departments was initially arbitrary — two of the eight laptops associated with the
  wrong department's access point and leased from the wrong pool, the same behaviour seen in
  earlier labs. The fix was MAC address filtering on each access point (`mac_filter`, with an
  allow-list of only that department's two laptops' `Wireless0` MAC addresses), followed by
  power-cycling the laptops so they re-scanned. After this, every laptop associated with its
  own department's access point and leased correctly.
]

#heading(level: 1, numbering: none)[Task 3.3: DNS and Web Hosting]

The HTTP server in VLSI has its `index.html` replaced and HTTP/HTTPS enabled:

#code("
<html><head><title>MSIS Web Portal</title></head>
<body><h1>Welcome to MSIS Web Portal</h1></body></html>
", lang: "html")

The DNS server in MVT holds one A record:

#code("
www.msis.edu  A  172.16.0.179
", lang: "text")

#heading(level: 1, numbering: none)[Task 4: Verification & Testing]

#heading(level: 2, numbering: none)[1. DHCP acquisition]

All 20 end-user devices (12 PCs, 8 laptops) were set to DHCP and renewed; every address came
back inside its own department's pool, with the correct gateway and DNS server:

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [Department], [Devices], [Address range leased], [Gateway],
    [CDC], [3 PC + 2 laptop], [172.16.0.163 -- .167], [172.16.0.161],
    [CYS], [3 PC + 2 laptop], [172.16.0.130 -- .134], [172.16.0.129],
    [VLSI], [3 PC + 2 laptop], [172.16.0.183 -- .188], [172.16.0.177],
    [MVT], [3 PC + 2 laptop], [172.16.0.3 -- .7], [172.16.0.1],
  ),
  caption: [All 20 devices acquired a correct lease, including the two relayed departments
  (CYS, MVT) and both wireless laptops in every department.],
)

#heading(level: 2, numbering: none)[2. CYS $arrow$ DNS Server ping]

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    [From], [To], [Result],
    [PC-CYS1 (172.16.0.132)], [DNS Server (172.16.0.2)], [4 sent, 2 received (first-ping ARP warm-up)],
    [PC-CYS1 (172.16.0.132)], [DNS Server (172.16.0.2)], [4/4 received, 0% loss],
  ),
  caption: [Real ping from a CYS PC to the MVT DNS server, crossing R1, the inter-router
  link, and R2.],
)

#heading(level: 2, numbering: none)[3. Web browser test from a CDC wireless laptop]

Laptop-CDC1 (wireless, 172.16.0.164) opened `http://www.msis.edu` in its Desktop web browser.
The DNS server resolved the name to the HTTP server's address, `172.16.0.179`, and the page
loaded successfully:

#code("
MSIS Web Portal
Welcome to MSIS Web Portal
", lang: "text")

This confirms DNS resolution, cross-department routing from a relayed, wireless CDC client
all the way to VLSI, and the HTTP server's content, in a single request.

#heading(level: 1, numbering: none)[Conclusion]

VLSM-allocating MVT, CYS, CDC, and VLSI largest to smallest fits all four departments and the
inter-router link inside the first `/24` of the assigned `/16`, once VLSI is corrected from a
`/29` to a `/28` to make room for its two infrastructure servers alongside its five end-user
devices — a sizing gap Task 1's host counts did not anticipate. Two static routes per router
and `ip helper-address` on each department that does not host its own DHCP server were
sufficient for every subnet, including both relayed ones, to lease correctly and reach each
other. As in earlier wireless builds, Packet Tracer's default-SSID access points needed MAC
filtering to stop cross-department association; once applied, all 20 end-user devices
acquired the right address, a CYS PC reached the MVT DNS server with 0% loss, and a wireless
CDC laptop loaded `www.msis.edu` end to end through DNS, routing, and HTTP.
