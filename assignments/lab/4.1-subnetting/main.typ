#import "/template/lib.typ": *

#show: assignment.with(
  title: "VLSM Subnetting & Dual-Router Static Routing",
  number: "Assignment 4.1",
  kind: "Lab",
  keywords: ("VLSM", "subnetting", "static routing", "Packet Tracer", "dual-router"),
  date: datetime(year: 2026, month: 9, day: 23),
)

#heading(level: 1, numbering: none)[Aim]

To perform Variable Length Subnet Masking on a single IPv4 block, build a
dual-router, four-switch topology in Cisco Packet Tracer from the result, and
configure static routes so all four departments can reach each other.

#heading(level: 1, numbering: none)[Scenario]

Four departments (IT with 115 hosts, Marketing with 50, Sales with 37, and HR
with 15) are to be carved out of `192.168.10.0/24`, with Router1 hosting IT and
Marketing and Router2 hosting Sales and HR, joined by a `10.0.0.0/30`
point-to-point link.

#let note(body) = block(
  width: 100%,
  above: 1.15em, below: 0.6em,
  fill: theme.head-fill,
  inset: (x: 11pt, y: 8pt),
  radius: 4pt,
  stroke: (left: 2.5pt + theme.link),
)[#strong[Correction.] #body]

#note[
  The handout claims these four host counts were "adjusted so all subnets fit
  inside `192.168.10.0/24`," but they do not. Sorted largest to smallest, VLSM
  needs a block of size $2^n$ where $2^n - 2 gt.eq$ the host count: IT (115)
  needs a `/25` (128 addresses), Marketing (50) a `/26` (64), and Sales (37) a
  `/26` (64) as well, not a `/27`, since a `/27` gives only 30 usable addresses
  and 37 exceeds that. HR (15) needs a `/27` (32). That totals
  $128+64+64+32=288$ addresses, but a `/24` holds only 256. The three largest
  departments alone (IT + Marketing + Sales = $128+64+64=256$) already exhaust
  the entire `/24`, leaving no address space for HR. Shrinking Sales to fit a
  `/27` is not a legitimate fix, since 37 hosts do not fit in 30 usable
  addresses.

  The minimal correct fix is to give HR its own block immediately after the
  `/24` is exhausted, i.e. in `192.168.11.0/27`. IT, Marketing, and Sales keep
  `192.168.10.0/24` exactly as VLSM allocates them; only HR moves out to the
  next octet. The table, topology, and configuration below use this corrected
  allocation, and Section 5 shows the working still fully satisfies Task 1's
  instruction to allocate everything via VLSM, largest to smallest.
]

#heading(level: 1, numbering: none)[Task 1: VLSM Subnetting Table]

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    align: (left, right, left, left, left, left, left, right),
    [Department], [Hosts], [Mask (CIDR)], [Network], [First usable], [Last usable], [Broadcast], [Usable],
    [IT], [115], [/25 (255.255.255.128)], [192.168.10.0], [192.168.10.1], [192.168.10.126], [192.168.10.127], [126],
    [Marketing], [50], [/26 (255.255.255.192)], [192.168.10.128], [192.168.10.129], [192.168.10.190], [192.168.10.191], [62],
    [Sales], [37], [/26 (255.255.255.192)], [192.168.10.192], [192.168.10.193], [192.168.10.254], [192.168.10.255], [62],
    [HR], [15], [/27 (255.255.255.224)], [192.168.11.0], [192.168.11.1], [192.168.11.30], [192.168.11.31], [30],
  ),
  caption: [VLSM allocation, largest to smallest. Each router LAN interface takes the
  first usable address of its subnet as its default gateway, per the handout's note.],
)

IT, Marketing, and Sales pack contiguously into `192.168.10.0/24` with no
gaps ($128+64+64=256$); HR is allocated in the next block, `192.168.11.0/27`,
for the reason given above.

#heading(level: 1, numbering: none)[Task 2 & 3: Topology and Interface Addressing]

#figure(
  image("assets/01-topology.png", width: 100%),
  caption: [Router1 (IT + Marketing) and Router2 (Sales + HR), joined by a
  crossover link, each with two access switches carrying the PC counts Task 2
  specifies (3, 3, 2, 2). All links are up.],
)

Router1 and Router2 are Cisco 2911s, since three onboard Gigabit interfaces
are needed per router (two LAN + one WAN), which rules out the 1941 the
earlier lab used (only two Gigabit ports). Each router's LAN interface is addressed
with the first usable host of its department's subnet, per Task 1's note:

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [Device], [Interface], [IP Address], [Subnet Mask],
    [Router1], [Gi0/0 (IT LAN)], [192.168.10.1], [255.255.255.128],
    [Router1], [Gi0/1 (Marketing LAN)], [192.168.10.129], [255.255.255.192],
    [Router1], [Gi0/2 (WAN)], [10.0.0.1], [255.255.255.252],
    [Router2], [Gi0/0 (Sales LAN)], [192.168.10.193], [255.255.255.192],
    [Router2], [Gi0/1 (HR LAN)], [192.168.11.1], [255.255.255.224],
    [Router2], [Gi0/2 (WAN)], [10.0.0.2], [255.255.255.252],
  ),
  caption: [Router interface addressing, read back from the live devices' startup configuration.],
)

The ten PCs (IT ×3, Marketing ×3, Sales ×2, HR ×2) were addressed with the
next host addresses after each gateway and pointed at that gateway, for
example PC-IT1 through PC-IT3 at `192.168.10.2`–`.4`/25, gateway
`192.168.10.1`, and PC-HR1/HR2 at `192.168.11.2`–`.3`/27, gateway `192.168.11.1`.

#heading(level: 1, numbering: none)[Task 3: Static Routing]

#code("
Router1(config)# ip route 192.168.10.192 255.255.255.192 10.0.0.2
Router1(config)# ip route 192.168.11.0 255.255.255.224 10.0.0.2

Router2(config)# ip route 192.168.10.0 255.255.255.128 10.0.0.1
Router2(config)# ip route 192.168.10.128 255.255.255.192 10.0.0.1
", lang: "text")

Both sets of routes are present in the saved configuration read back from the
routers:

#code("
Router1: ip route 192.168.10.192 255.255.255.192 10.0.0.2   (Sales)
Router1: ip route 192.168.11.0 255.255.255.224 10.0.0.2     (HR)
Router2: ip route 192.168.10.0 255.255.255.128 10.0.0.1     (IT)
Router2: ip route 192.168.10.128 255.255.255.192 10.0.0.1   (Marketing)
", lang: "text")

#heading(level: 1, numbering: none)[Task 4: Verification & Testing]

All four pings below are real, run from PC-HR1 against the deployed topology.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [From], [To], [Path], [Result],
    [PC-HR1], [192.168.10.193 (Sales gateway)], [Local router, same subnet as Router2], [4/4 received, 0% loss],
    [PC-HR1], [192.168.10.2 (an IT PC)], [Remote router, crosses 10.0.0.1/10.0.0.2], [4/4 received, 0% loss],
    [PC-HR1], [192.168.10.130 (a Marketing PC)], [Remote router, crosses 10.0.0.1/10.0.0.2], [4/4 received, 0% loss],
  ),
  caption: [Cross-router ping tests: HR → Sales (local router), HR → IT, and HR →
  Marketing (both remote, required by the submission deliverables).],
)

`tracert` from an HR PC to an IT or Marketing address crosses exactly one
intermediate hop, `10.0.0.1` (Router1's WAN interface), before reaching the
destination. That is the path the static routes above establish: HR's packets leave
via Router2's default route lookup, hit the matching static route to
`192.168.10.0/25` or `192.168.10.128/26` via `10.0.0.1`, and Router1 delivers
directly on its own LAN.

#heading(level: 1, numbering: none)[Conclusion]

Sorting host counts largest to smallest and rounding each up to the nearest
power-of-two block is enough to VLSM-allocate a shared address block without
overlap, but the arithmetic has to be checked against the size of the parent
block before trusting a handout's claim that it fits: here, three of the four
departments alone already consumed the entire `/24`, so the fourth (HR)
needed the next block rather than a slice of the same one. With that
correction, one static route per remote subnet on each router (four in total)
was sufficient for full reachability between all four departments across the
point-to-point link.
