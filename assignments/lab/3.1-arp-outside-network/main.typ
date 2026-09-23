#import "/template/lib.typ": *
#import "@preview/cetz:0.5.2": canvas, draw

#show: assignment.with(
  title: "Examining the ARP Table",
  number: "Assignment 3.1",
  kind: "Lab",
  keywords: ("ARP", "MAC address table", "default gateway", "Packet Tracer", "routing"),
  date: datetime(year: 2026, month: 9, day: 23),
)

// Each question from the assignment is shown verbatim in a shaded box, with the
// answer written underneath.
#let q(body) = block(
  width: 100%,
  sticky: true,
  above: 1.15em, below: 0.6em,
  fill: theme.head-fill,
  inset: (x: 11pt, y: 8pt),
  radius: 4pt,
)[#strong[Q.] #body]

// Topology diagram. `sent` lists frames drawn on top: (from, to, style) where
// style is "ok" (accepted) or "drop" (discarded by the receiver).
#let topology(sent: ()) = {
  let pos = (
    PC0: (0, 4.4), PC1: (0, 2.2), PC2: (0, 0),
    Switch0: (4.4, 2.2), Router0: (9.4, 2.2), Switch1: (14.4, 2.2),
    Laptop0: (18.8, 3.6), Laptop1: (18.8, 0.8),
  )
  let host(name, ip) = {
    let (x, y) = pos.at(name)
    draw.rect((x - 1.25, y - 0.55), (x + 1.25, y + 0.55), radius: 3pt,
      fill: white, stroke: 0.7pt + theme.ink)
    draw.content((x, y + 0.17), text(size: 8pt, weight: "bold")[#name])
    draw.content((x, y - 0.22), text(size: 6.5pt, fill: theme.muted)[#ip])
  }
  let box(name, fill) = {
    let (x, y) = pos.at(name)
    draw.rect((x - 0.95, y - 0.4), (x + 0.95, y + 0.4), radius: 3pt,
      fill: fill, stroke: 0.7pt + theme.ink)
    draw.content((x, y), text(size: 8pt, weight: "bold")[#name])
  }
  let link(a, b) = draw.line(pos.at(a), pos.at(b), stroke: 0.7pt + theme.rule)
  let port(x, y, t) = draw.content((x, y), text(size: 6pt, fill: theme.muted)[#t],
    fill: white, padding: 0.03)

  for (a, b) in (("PC0", "Switch0"), ("PC1", "Switch0"), ("PC2", "Switch0"),
    ("Switch0", "Router0"), ("Router0", "Switch1"),
    ("Switch1", "Laptop0"), ("Switch1", "Laptop1")) { link(a, b) }

  host("PC0", "192.168.13.2"); host("PC1", "192.168.13.3"); host("PC2", "192.168.13.4")
  host("Laptop0", "10.0.0.2"); host("Laptop1", "10.0.0.3")
  box("Switch0", theme.head-fill); box("Switch1", theme.head-fill)
  box("Router0", white)
  draw.content((9.4, 1.4), text(size: 6.5pt, fill: theme.muted)[192.168.13.1 | 10.0.0.1])

  port(3.0, 3.6, "Fa0/1"); port(2.9, 2.2, "Fa0/2"); port(3.0, 0.8, "Fa0/3")
  port(5.9, 2.6, "Gi0/1"); port(7.5, 2.6, "Gi0/0")
  port(11.3, 2.6, "Gi0/1"); port(12.9, 2.6, "Gi0/1")
  port(16.4, 3.35, "Fa0/1"); port(16.4, 1.05, "Fa0/2")

  for (a, b, style) in sent {
    let (x1, y1) = pos.at(a)
    let (x2, y2) = pos.at(b)
    let dx = x2 - x1
    let dy = y2 - y1
    let len = calc.sqrt(dx * dx + dy * dy)
    let ux = dx / len
    let uy = dy / len
    let (nx, ny) = (-uy * 0.16, ux * 0.16)
    let clip(n) = if n.starts-with("Sw") or n.starts-with("Ro") { 1.0 } else { 1.35 }
    let c = if style == "ok" { theme.link } else { theme.muted }
    draw.line(
      (x1 + ux * clip(a) + nx, y1 + uy * clip(a) + ny),
      (x2 - ux * clip(b) + nx, y2 - uy * clip(b) + ny),
      stroke: (paint: c, thickness: 1.2pt, dash: if style == "ok" { none } else { "dashed" }),
      mark: (end: ">", fill: c, scale: 0.7),
    )
  }
}

#let diagram(sent: ()) = align(center, canvas(length: 0.69cm, topology(sent: sent)))

#heading(level: 1, numbering: none)[Aim]

To examine how ARP requests and replies work inside one network, how a switch builds
its MAC address table, and how ARP behaves when the destination is on a different
network and traffic must pass through the default gateway.

#heading(level: 1, numbering: none)[Setup]

#figure(
  image("assets/01-topology.png", width: 100%),
  caption: [The topology in Packet Tracer. The PCs and Switch0 form `192.168.13.0/24`;
  Switch1 and the laptops form `10.0.0.0/24`. Router0 joins the two.],
)

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [Device], [Interface and IP address], [MAC address], [Switch interface],
    [Router0], [Gi0/0, `192.168.13.1`], [`000A.416B.4B01`], [Switch0 G0/1],
    [Router0], [Gi0/1, `10.0.0.1`], [`000A.416B.4B02`], [Switch1 G0/1],
    [Laptop0], [F0, `10.0.0.2`], [`0001.430B.3A10`], [Switch1 F0/1],
    [Laptop1], [F0, `10.0.0.3`], [`00E0.F99A.2881`], [Switch1 F0/2],
    [PC0], [F0, `192.168.13.2`], [`00E0.F763.E594`], [Switch0 F0/1],
    [PC1], [F0, `192.168.13.3`], [`00D0.BA5A.DE85`], [Switch0 F0/2],
    [PC2], [F0, `192.168.13.4`], [`00D0.971A.9AD2`], [Switch0 F0/3],
  ),
  caption: [The completed addressing table. Hosts use the router as their default gateway.],
)

Three details of the assignment sheet needed a choice. Its addressing table lists the
router as `12.1.1.1` and `12.1.1.2`, but its steps ping `10.0.0.1` as the router, so
the router interfaces are `192.168.13.1` and `10.0.0.1`. Step 1 is headed "from
`192.168.13.3`", but its sub-steps end at `192.168.13.2`, so the ping is sent from
PC0 to PC1. In Part 3 the sheet mentions Switch1, but PC0's switch is Switch0.

#heading(level: 1, numbering: none)[Part 1: Examine an ARP Request]

// Reset the section counter so the assignment questions are numbered 1 onward.
#counter(heading).update(0)

PC0 pinged PC1 in simulation mode. Two PDUs appeared: the ICMP echo, held back
because PC0 did not know PC1's MAC address, and an ARP broadcast asking for it.

#figure(
  diagram(sent: (
    ("PC0", "Switch0", "ok"), ("Switch0", "PC1", "ok"),
    ("Switch0", "PC2", "drop"), ("Switch0", "Router0", "drop"),
  )),
  caption: [The ARP request. Switch0 floods it out of every other port. PC1 accepts it;
  PC2 and Router0 discard it.],
)

#q[Open the PDU and record the destination MAC address.]

The destination MAC address is `FFFF.FFFF.FFFF`, the broadcast address. The request
carries PC1's IP address as its target, but the MAC address is unknown, so the frame
goes to everyone.

#q[How many copies of the PDU did Switch0 make? What is the IP address of the
device that accepted the PDU?]

Switch0 made three copies, one each to PC1, PC2, and Router0, which are all the
ports except the one the frame arrived on. Only PC1, `192.168.13.3`, accepted it. PC2
and Router0 dropped it because the target IP was not their own.

#q[Open the PDU and examine Layer 2. What happened to the source and destination
MAC addresses?]

The switch did not change the frame. PC1 then built a reply with the addresses
swapped: the source became PC1's MAC address `00D0.BA5A.DE85`, and the destination
became PC0's MAC address `00E0.F763.E594`. The reply is a unicast, not a broadcast.

#q[How many copies of the PDU did the switch make during the ARP reply?]

One. Switch0 had already learned PC0's port from the request, so it forwarded the
reply out of Fa0/1 only.

#q[Open the ICMP PDU and examine the MAC addresses. Do the MAC addresses of the
source and destination align with their IP addresses?]

Yes. The ICMP echo now goes from `00E0.F763.E594` (PC0) to `00D0.BA5A.DE85` (PC1),
matching `192.168.13.2` to `192.168.13.3`.

#q[Click 192.168.13.2 and enter the arp -a command. To what IP address does the MAC
address entry correspond?]

#figure(
  ```
  C:\> arp -a
    Internet Address      Physical Address      Type
    192.168.13.3          00d0.ba5a.de85        dynamic
  ```,
  caption: [ARP table of PC0 after the ping.],
)

The entry belongs to `192.168.13.3`, PC1.

#q[In general, when does an end device issue an ARP request?]

When it has to send a packet to an IPv4 address, either on its own network or its
default gateway, and that address has no MAC entry in its ARP table.

#heading(level: 1, numbering: none)[Part 2: Examine a Switch MAC Address Table]

#q[Ping 192.168.13.4 from 192.168.13.2, and ping 10.0.0.3 from 10.0.0.2. How many
replies were sent and received?]

Both pings sent four echo requests and received four replies, with 0% loss.

#q[Enter show mac-address-table on Switch1 and on Switch0. Do the entries
correspond to those in the table above?]

Yes. Each host appears on the port it is cabled to, and the router appears on the
uplink port once routed traffic has passed. The output below was taken after a ping
had crossed the router.

#figure(
  ```
  Switch0>show mac address-table
  Vlan    Mac Address       Type        Ports
     1    000a.416b.4b01    DYNAMIC     Gig0/1     (Router0 Gi0/0)
     1    00d0.971a.9ad2    DYNAMIC     Fa0/3      (PC2)
     1    00d0.ba5a.de85    DYNAMIC     Fa0/2      (PC1)
     1    00e0.f763.e594    DYNAMIC     Fa0/1      (PC0)

  Switch1>show mac address-table
  Vlan    Mac Address       Type        Ports
     1    0001.430b.3a10    DYNAMIC     Fa0/1      (Laptop0)
     1    000a.416b.4b02    DYNAMIC     Gig0/1     (Router0 Gi0/1)
     1    00e0.f99a.2881    DYNAMIC     Fa0/2      (Laptop1)
  ```,
  caption: [MAC address tables of the two switches.],
)

#q[Why are two MAC addresses associated with one port?]

In this topology they are not: every port shows exactly one MAC address, including
the router-facing port, because each switch only ever sees the router's own
interface as the source of routed frames. A port shows two or more addresses when
more than one device sits behind it, for example a second switch or a hub. The
address of the router's other interface does not appear at all, since it belongs to
the other network.

#heading(level: 1, numbering: none)[Part 3: ARP in Remote Communication]

#q[Ping 10.0.0.1 from 192.168.13.2 and type arp -a. What is the IP address of the new
ARP table entry?]

#figure(
  ```
  C:\> arp -a
    Internet Address      Physical Address      Type
    192.168.13.1          000a.416b.4b01        dynamic
    192.168.13.3          00d0.ba5a.de85        dynamic
    192.168.13.4          00d0.971a.9ad2        dynamic
  ```,
  caption: [ARP table of PC0 after pinging `10.0.0.1`.],
)

The new entry is `192.168.13.1`, the default gateway, not `10.0.0.1`.

#q[Clear the ARP table with arp -d, switch to simulation mode, and repeat the ping.
How many PDUs appear?]

Two: an ICMP echo request, held back, and an ARP broadcast.

#q[What is the target destination IP address of the ARP request? The destination IP
address is not 10.0.0.1. Why?]

#figure(
  diagram(sent: (
    ("PC0", "Switch0", "ok"), ("Switch0", "PC1", "drop"),
    ("Switch0", "PC2", "drop"), ("Switch0", "Router0", "ok"),
  )),
  caption: [The ARP request for `192.168.13.1`. Only Router0 answers.],
)

The target is `192.168.13.1`, the address of Router0's Gi0/0. `10.0.0.1` is on a
different network (`10.0.0.0/24`), and ARP broadcasts do not cross a router, so PC0
cannot learn that MAC address directly. PC0 compares the destination with its own
subnet, sees that it is remote, and sends the packet to its default gateway. It
therefore needs the gateway's MAC address, and that is what it asks for. The router
then handles the packet at Layer 3.

#q[Click Router0 and enter privileged EXEC mode, then show mac-address-table. How
many MAC addresses are in the table? Why?]

None. A router forwards packets by IP address using its routing table and has no
MAC learning table; that is a switch function. What a router keeps is an ARP table.

#q[Enter the show arp command. Is there an entry for 192.168.13.2?]

#figure(
  ```
  Router#show arp
  Protocol  Address          Age (min)  Hardware Addr   Type   Interface
  Internet  10.0.0.1                -   000A.416B.4B02  ARPA   Gi0/1
  Internet  10.0.0.2                1   0001.430B.3A10  ARPA   Gi0/1
  Internet  192.168.13.1            -   000A.416B.4B01  ARPA   Gi0/0
  Internet  192.168.13.2            2   00E0.F763.E594  ARPA   Gi0/0
  ```,
  caption: [ARP table of Router0 (interface names shortened).],
)

Yes. Router0 learned PC0's MAC address `00E0.F763.E594` from the ARP request itself.

#q[What happens to the first ping in a situation where the router responds to the ARP
request?]

The first ICMP echo waits at the sender until the ARP reply arrives, and is sent only
then. In simulation, the buffered echo left PC0 right after the reply, and the ping
to `10.0.0.1` completed with four replies. When a ping is routed onward to another
network, as with PC0 to Laptop0, the router must also ARP for the destination on the
far side. In that run the first request timed out and the remaining three succeeded
(25% loss). The first ping is slower or lost, and later ones succeed because the
entries are cached.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [Segment], [Source MAC], [Destination MAC], [IP addresses (unchanged)],
    [PC0 to Router0], [`00E0.F763.E594`], [`000A.416B.4B01`],
      [`192.168.13.2` to `10.0.0.2`],
    [Router0 to Laptop0], [`000A.416B.4B02`], [`0001.430B.3A10`],
      [`192.168.13.2` to `10.0.0.2`],
  ),
  caption: [Addresses on a ping from PC0 to Laptop0. The MAC addresses change at the
  router; the IP addresses do not.],
)

#heading(level: 1, numbering: none)[Conclusion]

ARP resolves an IPv4 address to a MAC address on the local network only. The request
is a broadcast that every host on the segment receives, but only the target replies,
by unicast. A switch learns which port each MAC address is on from the frames it
sees, and it floods only broadcasts and unknown destinations. For a remote
destination the host ARPs for its default gateway rather than the destination, and
the router rewrites the MAC addresses at each hop while the IP addresses stay
the same. A router keeps an ARP table, not a MAC address table.
