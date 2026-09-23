#import "/template/lib.typ": *
#import "@preview/cetz:0.5.2": canvas, draw

#show: assignment.with(
  title: "ARP and Switch Learning within a Network",
  number: "Assignment 03",
  kind: "Lab",
  keywords: ("ARP", "Ethernet switching", "MAC address table", "Packet Tracer", "flooding"),
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

// Topology used in every diagram below. `sent` lists the frames drawn on top:
// (from, to, style) where style is "ok" (delivered/accepted) or "drop" (discarded).
#let topology(sent: ()) = {
  let pos = (
    PC1: (0, 3.2), PC2: (0, 0.4), SW1: (4, 1.8),
    SW2: (9, 1.8), PC3: (13, 3.2), PC4: (13, 0.4),
  )
  let host(name, ip) = {
    let (x, y) = pos.at(name)
    draw.rect((x - 1.15, y - 0.55), (x + 1.15, y + 0.55), radius: 3pt,
      fill: white, stroke: 0.7pt + theme.ink)
    draw.content((x, y + 0.17), text(size: 8.5pt, weight: "bold")[#name])
    draw.content((x, y - 0.22), text(size: 7pt, fill: theme.muted)[#ip])
  }
  let sw(name) = {
    let (x, y) = pos.at(name)
    draw.rect((x - 0.8, y - 0.4), (x + 0.8, y + 0.4), radius: 3pt,
      fill: theme.head-fill, stroke: 0.7pt + theme.ink)
    draw.content((x, y), text(size: 8.5pt, weight: "bold")[#name])
  }
  let link(a, b) = draw.line(pos.at(a), pos.at(b), stroke: 0.7pt + theme.rule)
  let port(x, y, t) = draw.content((x, y), text(size: 6.5pt, fill: theme.muted)[#t],
    fill: white, padding: 0.03)

  link("PC1", "SW1"); link("PC2", "SW1"); link("SW1", "SW2")
  link("SW2", "PC3"); link("SW2", "PC4")

  host("PC1", "192.168.1.1"); host("PC2", "192.168.1.2")
  host("PC3", "192.168.1.3"); host("PC4", "192.168.1.4")
  sw("SW1"); sw("SW2")

  port(2.7, 2.6, "Fa0/1"); port(2.7, 1.05, "Fa0/2"); port(5.4, 2.25, "Gi0/1")
  port(7.6, 2.25, "Gi0/1"); port(10.5, 2.6, "Fa0/1"); port(10.5, 1.05, "Fa0/2")

  // Frames are drawn as arrows slightly shortened and offset from the link.
  for (a, b, style) in sent {
    let (x1, y1) = pos.at(a)
    let (x2, y2) = pos.at(b)
    let dx = x2 - x1
    let dy = y2 - y1
    let len = calc.sqrt(dx * dx + dy * dy)
    let ux = dx / len
    let uy = dy / len
    let (nx, ny) = (-uy * 0.16, ux * 0.16)
    let s = if a.starts-with("SW") { 0.85 } else { 1.25 }
    let e = if b.starts-with("SW") { 0.85 } else { 1.25 }
    draw.line(
      (x1 + ux * s + nx, y1 + uy * s + ny),
      (x2 - ux * e + nx, y2 - uy * e + ny),
      stroke: (
        paint: if style == "ok" { theme.link } else { theme.muted },
        thickness: 1.2pt,
        dash: if style == "ok" { none } else { "dashed" },
      ),
      mark: (end: ">", fill: if style == "ok" { theme.link } else { theme.muted }, scale: 0.7),
    )
  }
}

#let diagram(sent: ()) = align(center, canvas(length: 0.82cm, topology(sent: sent)))

#heading(level: 1, numbering: none)[Aim]

To study how ARP resolves an IPv4 address to a MAC address inside one network, and
how the two switches learn MAC addresses and decide whether to flood, forward, or
filter a frame.

#heading(level: 1, numbering: none)[Setup]

#figure(
  diagram(),
  caption: [One subnet, `192.168.1.0/24`, split across two 2960 switches. At the
  start both switches have empty MAC tables and all PCs have empty ARP tables.],
)

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, left, left, left, left),
    [Host], [IP address], [MAC address], [Port on its switch], [Seen from the other switch via],
    [PC1], [`192.168.1.1`], [`00D0.D3AD.9CAB`], [SW1 Fa0/1], [SW2 Gi0/1],
    [PC2], [`192.168.1.2`], [`0060.5C56.14D3`], [SW1 Fa0/2], [SW2 Gi0/1],
    [PC3], [`192.168.1.3`], [`0004.9A6E.D870`], [SW2 Fa0/1], [SW1 Gi0/1],
    [PC4], [`192.168.1.4`], [`0001.647B.3119`], [SW2 Fa0/2], [SW1 Gi0/1],
  ),
  caption: [Addressing and cabling.],
)

#heading(level: 1, numbering: none)[Ping and ARP Messages]

// Reset the section counter so the assignment tasks are numbered 1 onward.
#counter(heading).update(0)

#q[If PC1 pings to PC3, what messages will be sent over the network, and which
devices will receive them?]

Four messages are sent. PC1 does not know PC3's MAC address, so the ping cannot
be sent until ARP resolves it.

+ *ARP request (broadcast).* PC1 asks "who has `192.168.1.3`?" in a frame sent to
  `FFFF.FFFF.FFFF`. SW1 has no entry for that address, so it floods the frame out
  every port except the one it arrived on. It reaches PC2, SW2, and (through SW2)
  PC3 and PC4. PC2 and PC4 discard it because the target IP is not theirs. PC3
  accepts it and stores PC1's MAC address.
+ *ARP reply (unicast).* PC3 answers PC1 directly with its MAC address. Both
  switches now know where PC1 is, so the reply travels PC3, SW2, SW1, PC1 only.
  PC2 and PC4 never see it.
+ *ICMP echo request (unicast).* PC1 sends the ping to PC3's MAC address along the
  same path.
+ *ICMP echo reply (unicast).* PC3 returns it along the reverse path.

#figure(
  diagram(sent: (
    ("PC1", "SW1", "ok"), ("SW1", "PC2", "drop"), ("SW1", "SW2", "ok"),
    ("SW2", "PC3", "ok"), ("SW2", "PC4", "drop"),
  )),
  caption: [ARP request (broadcast). The switches flood it to every host. Solid
  arrows are frames that are accepted, dashed arrows are copies discarded by the
  receiving host.],
)

#figure(
  diagram(sent: (
    ("PC3", "SW2", "ok"), ("SW2", "SW1", "ok"), ("SW1", "PC1", "ok"),
  )),
  caption: [ARP reply (unicast). Only the switches on the path to PC1 carry it. The
  ICMP echo request and reply follow the same path.],
)

#q[Send the ping and use Packet Tracer's 'simulation mode' to verify your answer.]

In simulation mode the ping produced exactly the sequence above. The ICMP packet
was held at PC1 while the ARP request went out as a broadcast. The event list showed
the broadcast copy arriving at PC2 and PC4, where it was *dropped*, and at PC3,
where it was *accepted*. The ARP reply then went back as a single unicast frame
(PC3, SW2, SW1, PC1), after which the ICMP request and reply each crossed the two
switches once. The ARP tables confirm the same picture:

#figure(
  ```
  C:\> arp -a                       (on PC1)
    192.168.1.3     0004.9a6e.d870   dynamic

  C:\> arp -a                       (on PC3)
    192.168.1.1     00d0.d3ad.9cab   dynamic

  C:\> arp -a                       (on PC2)
  No ARP Entries Found
  ```,
  caption: [PC1 and PC3 learned each other; PC2, which discarded the broadcast, learned nothing.],
)

#heading(level: 1, numbering: none)[Switch Learning]

#q[Use pings to generate network traffic and allow the switches to learn the MAC
addresses of all PCs on the network. Understand the actions performed by the switch.]

The switch performs four actions on every frame:

- *Learn:* it records the *source* MAC address against the port the frame arrived on.
- *Flood:* if the destination is a broadcast or is not yet in the table, it sends
  the frame out of every port except the arrival port.
- *Forward:* if the destination is in the table, it sends the frame out of that one port.
- *Filter:* it never sends a frame back out of the port it came in on.

After only PC1 pinged PC3, each switch had learned just the two hosts whose frames
it had seen. A second ping, PC2 to PC4, taught both switches the remaining two.

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    [Table], [PC1 to PC3 only], [After PC2 to PC4 as well],
    [SW1], [PC1 on Fa0/1, PC3 on Gi0/1],
      [PC1 Fa0/1, PC2 Fa0/2, PC3 Gi0/1, PC4 Gi0/1],
    [SW2], [PC1 on Gi0/1, PC3 on Fa0/1],
      [PC1 Gi0/1, PC2 Gi0/1, PC3 Fa0/1, PC4 Fa0/2],
  ),
  caption: [What each switch had learned after each stage.],
)

The trunk port Gi0/1 carries two MAC addresses on each switch, because every host
on the far side of the link is reached through it.

In Packet Tracer, `arp -d` makes every PC send frames of its own, which fills the
switch tables on its own. The switch tables were therefore cleared after `arp -d`
and before the test ping.

#heading(level: 1, numbering: none)[Show Commands]

#q[Use 'show' commands on the switches to identify the MAC address of each PC.]

The command `show mac address-table` lists the learned addresses on each switch.

#figure(
  ```
  SW1>show mac address-table
  Vlan    Mac Address       Type        Ports
  ----    -----------       --------    -----
     1    0001.647b.3119    DYNAMIC     Gig0/1
     1    0004.9a6e.d870    DYNAMIC     Gig0/1
     1    0060.5c56.14d3    DYNAMIC     Fa0/2
     1    00d0.d3ad.9cab    DYNAMIC     Fa0/1

  SW2>show mac address-table
  Vlan    Mac Address       Type        Ports
  ----    -----------       --------    -----
     1    0001.647b.3119    DYNAMIC     Fa0/2
     1    0004.9a6e.d870    DYNAMIC     Fa0/1
     1    0060.5c56.14d3    DYNAMIC     Gig0/1
     1    00d0.d3ad.9cab    DYNAMIC     Gig0/1
  ```,
  caption: [MAC tables of both switches once all four PCs had sent traffic.],
)

Matching the entries to hosts gives PC1 `00D0.D3AD.9CAB`, PC2 `0060.5C56.14D3`,
PC3 `0004.9A6E.D870`, and PC4 `0001.647B.3119`, as listed in the setup table. All
entries have type DYNAMIC, meaning they were learned from traffic and will age out.

#heading(level: 1, numbering: none)[Clearing the Table]

#q[Clear the dynamic MAC addresses from the MAC address table of each switch.]

The command is entered in privileged EXEC mode on each switch:

#figure(
  ```
  SW1> enable
  SW1# clear mac address-table dynamic
  SW1# show mac address-table
  Vlan    Mac Address       Type        Ports
  ----    -----------       --------    -----
  ```,
  caption: [The same commands were repeated on SW2. Both tables are empty afterwards.],
)

The next frame a switch receives will be learned again from scratch, and until then
it floods any unicast frame.

#heading(level: 1, numbering: none)[Conclusion]

A host must resolve the destination MAC address with ARP before it can send an IP
packet inside its own network. The ARP request is a broadcast, so switches flood it
to every host, but only the target replies; the reply is unicast and reaches only the
requester. Switches learn source MAC addresses from every frame, then forward
known unicast traffic to a single port and flood only broadcasts and unknown
destinations.
