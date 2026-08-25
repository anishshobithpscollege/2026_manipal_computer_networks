#import "/template/lib.typ": *

#show: assignment.with(
  title: "Understanding the OSI Model",
  number: "Assignment 02",
  kind: "Lab",
  keywords: ("OSI model", "Packet Tracer", "encapsulation", "ARP", "DNS", "TCP/IP"),
)

= Aim

To trace a single web request from a client to a server inside a Cisco Packet
Tracer topology and to map each stage of the request onto the seven layers of
the OSI reference model. The exercise identifies the addresses, protocols,
ports, and error-detection fields that operate at each layer, follows the
encapsulation of one packet along its path, and observes how a physical-layer
fault propagates up the stack.

= Topology and Method

The topology models a client LAN, a router, and a remote server that hosts
`www.cyber.com`. Host `Tom` (Laptop0) issues the request, `Server0` resolves
the name through DNS, `Router0` joins the two networks, and `Server1` serves the
page. Every value in this report was read from the live devices over the Packet
Tracer bridge, that is, the interface state, the MAC and IP addresses, and the
NAT mode, and was confirmed with real pings. The canvas labels were not trusted,
since a label such as the one on Laptop3 still reads `10.1.1.2` while the device
itself holds no configured address.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, left, left, left, left),
    [Device], [Role], [Port], [IP / mask], [MAC],
    [Laptop0 (Tom)], [Client host], [Fa0], [`10.1.1.2` /8], [`0060.3E57.B509`],
    [Server0], [DNS server], [Fa0], [`10.1.1.10` /8], [`0001.6466.E9D9`],
    [Router0], [Gateway], [Gi0/0], [`10.1.1.1` /8], [`000A.F36D.3101`],
    [Router0], [Gateway], [Gi0/1], [`23.227.38.1` /8], [`000A.F36D.3102`],
    [Server1], [Web server], [Fa0], [`23.227.38.65` /24], [`0060.7044.7973`],
    [Switch0], [LAN switch], [2960-24TT], [none, L2 only], [--],
    [Switch1], [Server switch], [2960-24TT], [none, L2 only], [--],
  ),
  caption: [Devices and addresses, read from the live topology. `/8` is the
  mask `255.0.0.0` and `/24` is `255.255.255.0`. `Server1` answers to
  `www.cyber.com`.],
)

The forwarding path from Tom to the web server is Laptop0, Switch0, Router0,
Switch1, Server1, and the reply retraces it. Router0 runs no address
translation: `nat_mode` reads `none` on both interfaces, so this is plain
routing.

#figure(
  image("assets/01-topology.png", width: 100%),
  caption: [The live topology. The client LAN `10.1.1.0` sits on Switch0 with
  Tom and the DNS server; Router0 joins it to the server subnet `23.227.38.0`
  on Switch1, where the web server sits.],
)

= Packet Capture and Inspection

== Packets exchanged in one request

A single page fetch is not a single packet. Opening `www.cyber.com` from Tom
sets off a short sequence of exchanges, each serving a different layer. The
logical steps are listed below.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [Step], [Protocol], [Layer], [Purpose],
    [1], [DNS query], [L7 over UDP], [ask Server0 for the address of `www.cyber.com`],
    [2], [DNS response], [L7 over UDP], [Server0 returns `23.227.38.65`],
    [3], [ARP], [L2], [resolve the next-hop MAC on first contact],
    [4], [TCP SYN], [L4], [Tom opens a connection to port 80],
    [5], [TCP SYN-ACK], [L4], [the server agrees and returns its parameters],
    [6], [TCP ACK], [L4], [Tom completes the handshake],
    [7], [HTTP GET], [L7], [Tom requests the page],
    [8], [HTTP 200 OK], [L7], [the server returns the page in one or more segments],
    [9], [TCP ACK], [L4], [Tom acknowledges the segments received],
    [10], [TCP FIN, ACK], [L4], [the connection is closed in both directions],
  ),
  caption: [The logical exchange behind one web request.],
)

Counting distinct end-to-end packets, a warm exchange runs to roughly fifteen to
twenty; the exact figure depends on how many TCP segments the page occupies and
on how many ARP lookups are still needed. Packet Tracer's simulation event list
reports a larger number, because it records the same packet again at every
switch and router it crosses. A packet from Tom to the server is logged five
times on the way out, once at each of Laptop0, Switch0, Router0, Switch1, and
Server1, so the event count is several times the number of packets on the wire.

== OSI layers visible in the capture

Five layers appear directly in the per-packet detail.

- *Application (L7)*: the DNS query and reply, and the HTTP GET and 200 OK.
- *Transport (L4)*: UDP for DNS, and TCP for HTTP, with ports, sequence and
  acknowledgement numbers, and a maximum segment size negotiated in the handshake.
- *Network (L3)*: the source and destination IP addresses, the time-to-live
  field, and the router's forwarding decision.
- *Data Link (L2)*: Ethernet framing, and ARP, which resolves the next-hop MAC.
- *Physical (L1)*: the transmission of the frame on the copper link between two ports.

The Session (L5) and Presentation (L6) layers do not appear as separate entries.
Packet Tracer folds their functions into the application logic, which is a fair
simplification for a stateless HTTP fetch that carries no separate session
negotiation or data-format translation.

= Source and Destination Addresses

== IP addresses and the layer that handles them

The source IP is `10.1.1.2` (Tom) and the destination IP is `23.227.38.65` (the
web server, obtained from the DNS reply). These addresses belong to the
*Network layer (L3)*. They are set once by the source and are not changed in
transit: Router0 runs no NAT, so the same pair is present in the IP header when
the packet leaves Tom and when it reaches the server.

== MAC addresses and the layer that handles them

The MAC addresses belong to the *Data Link layer (L2)*. Unlike the IP pair, the
MAC pair does not survive the journey; it is rewritten on each subnet. On the
client LAN the frame travels from Tom's card `0060.3E57.B509` to Router0's inward
interface Gi0/0 `000A.F36D.3101`. On the server subnet it travels from Router0's
outward interface Gi0/1 `000A.F36D.3102` to the server's card `0060.7044.7973`.
The full rewrite is shown in the section on data flow at the network layer.

= Functions of the Layers in the Request

== Establishing the connection

The *Transport layer (L4)* establishes the connection. Before any HTTP data is
sent, TCP performs a three-way handshake: Tom sends a SYN, the server answers
with SYN-ACK, and Tom returns an ACK. Only then does the GET travel.

== Translating the domain name to an IP address

The *Application layer (L7)* performs name resolution. DNS is itself an
application-layer protocol; it uses UDP at the transport layer for delivery, but
the query and answer are application data. Server0 receives the query for
`www.cyber.com` and returns the address record `23.227.38.65`.

== Ensuring data is error-free

Reliability rests mainly with the *Transport layer (L4)*. TCP numbers every
byte, acknowledges what it receives, and retransmits anything left
unacknowledged, so lost or reordered segments are detected and repaired. A
16-bit checksum in the TCP header guards the segment contents, and the Ethernet
trailer at L2 adds a frame check sequence that catches bit errors on the wire.
These fields are covered in the section on error detection.

= Data Encapsulation Across the Path

Encapsulation is the wrapping of data in a header, and at L2 a trailer, as it
passes down the stack, and decapsulation is the reverse on the way up. The table
lists what each device does to one outbound packet.

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    [Device], [Layer], [What it does to the packet],
    [Laptop0 (source)], [L7 to L1], [wraps the HTTP data in a TCP segment (ports,
      sequence, MSS), then an IP packet (`10.1.1.2` to `23.227.38.65`, TTL), then
      an Ethernet frame with FCS addressed to the gateway],
    [Switch0], [L2], [reads the destination MAC and forwards on the matching
      port; no header is added or removed],
    [Router0], [L3], [strips the incoming Ethernet header, decrements the IP TTL,
      looks up the route, and builds a new Ethernet header with new source and
      destination MACs for the outbound interface],
    [Switch1], [L2], [forwards on the destination MAC; the frame is unchanged],
    [Server1 (dest)], [L1 to L7], [strips Ethernet, then IP, then TCP, and hands
      the HTTP request to the server process],
  ),
  caption: [Encapsulation and decapsulation along the path.],
)

The layer that changes the packet most is *L2*. The IP header loses only its
TTL, decremented by one at each router, whereas the Ethernet header is discarded
and rebuilt in full at every router hop, with both MAC addresses replaced. A
switch changes nothing above the physical port on which it forwards.

= Protocol Identification

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    [Layer], [Protocol], [Evidence in the capture],
    [Application (L7)], [DNS, then HTTP], [the name lookup, then the GET and 200 OK],
    [Transport (L4)], [UDP for DNS, TCP for HTTP], [connectionless lookup; a
      handshake and teardown for the page],
    [Network (L3)], [IPv4], [32-bit addresses, TTL, and router forwarding],
  ),
  caption: [Protocol at each layer of the request.],
)

DNS resolves the name over UDP, which is connectionless and needs no handshake.
HTTP then runs over TCP on port 80, which is why the handshake and teardown
appear for the page but not for the lookup. Both ride on IPv4.

= IP Addressing

The source IP `10.1.1.2` and destination IP `23.227.38.65` are added at *L3*,
when Tom's TCP stack passes the segment down to IP. Because the destination is
not on Tom's local network, L3 sends the packet to the configured default
gateway `10.1.1.1` rather than resolving the destination directly.

At the server, L3 compares the packet's destination IP with its own interface
address `23.227.38.65`. The two match, so the packet is decapsulated and passed
up the stack instead of being forwarded on. The addresses are not rewritten
anywhere along the path, because Router0 performs no address translation.

= Port Numbers and Sockets

The destination port is *80*, the well-known port for HTTP, which tells the
server that the request is for its web service. The source port is an
*ephemeral port* that Tom's stack allocates for this one connection; Packet
Tracer assigns `1025`. Ports belong to the *Transport layer (L4)*.

A socket is the pair of an IP address and a port. Ports matter because the IP
pair alone identifies only two machines, whereas the port pair lets each machine
deliver the traffic to the correct process. Port 80 directs the request to the
web server, and port 1025 is the return address that lets the reply reach the
process that opened the connection rather than any other on the host. DNS uses
UDP port `53` on Server0 by the same well-known-port convention.

= Error Detection

Error detection is applied at more than one layer.

- *Data Link (L2)*: the Ethernet trailer carries a 4-byte Frame Check Sequence,
  a CRC-32 computed over the frame. The receiver recomputes it and discards the
  frame if it does not match, which catches bit errors introduced on the
  physical link.
- *Network (L3)*: the IPv4 header carries a 16-bit header checksum that protects
  the header fields.
- *Transport (L4)*: the TCP header carries a 16-bit checksum over the segment,
  and TCP's sequence and acknowledgement numbers detect loss, duplication, and
  reordering, so a missing segment is retransmitted.

The layer that guarantees a reliable, ordered byte stream to the application is
L4. The frame check sequence at L2 is the first line of defence against
corruption on the wire.

= Path Analysis

The forwarding path is Laptop0, Switch0, Router0, Switch1, Server1, retraced by
the reply. Three kinds of device handle the frame differently.

- *Switches (Switch0 and Switch1, 2960-24TT), L2*: forward on the destination
  MAC using the MAC address table. They do not inspect the IP header, do not
  change the TTL, and pass the frame on unchanged.
- *Router (Router0, 2911), L3*: the only device that reads the IP header. It
  decrements the TTL, consults its routing table to choose the outbound
  interface, and rebuilds the L2 header with new source and destination MAC
  addresses before forwarding.
- *End hosts (Laptop0 and Server1)*: the only devices that process the frame all
  the way up to L7.

One behaviour was captured directly. The first ICMP echo of a cold ping from Tom
to the server was lost while the others succeeded.

#figure(
  ```
  Laptop0  ->  23.227.38.65
  Packets: Sent = 4, Received = 3, Lost = 1 (25% loss)
  ```,
  caption: [First, cold ping: one echo lost during ARP resolution.],
)

On first contact the sender has no ARP entry for the next hop, so the first
packet is dropped while the ARP request and reply complete, then forwarding
proceeds normally. A repeated ping showed no loss. This is expected on a cold
path, not a fault.

= DNS Resolution

Before Tom can address the connection, the browser needs an IP for
`www.cyber.com`. Resolution costs two packets, both inside the client LAN and
both exchanged with Server0 (`10.1.1.10`): a query carrying the name, and a
response carrying the address record `23.227.38.65`. The layers involved are L7
(the query and answer), L4 (UDP, so there is no handshake), L3 (IP, delivered
within the same subnet, so there is no router hop), and L2 and L1 (Ethernet and
the physical link, with an ARP lookup for the server's MAC on first contact).
Resolution completes before the TCP SYN toward the resolved address is built, so
the name lookup is a prerequisite for the connection, not a parallel step.

= Transport Protocol: TCP Versus UDP

The lab asks for the web request to be moved from TCP to UDP. Packet Tracer's
Server-PT HTTP service is bound to TCP port 80 in its application model and
offers no option, in the interface or through the bridge, to rebind it to UDP.
This restriction is itself the point: HTTP is specified to run over TCP.

Reasoning from the captured exchange, replacing TCP with UDP would remove the
three-way handshake, the sequence and acknowledgement numbers, and the
retransmission of lost segments. The single echo lost to ARP on the cold path
was recovered under TCP because that layer retransmits; under UDP it would
simply be gone, and the application would have to detect and recover on its own.
A segment lost in the middle of a multi-segment page would leave a gap that UDP
has no way to notice, so the page could be truncated silently. Reliability of
the transfer would move from the transport layer to the application, which is
why web content uses TCP.

= Data Flow at the Network Layer

Holding the packet at a network-layer decision on Router0 shows the same pattern
in each direction: the frame arrives with one MAC pair and leaves with a
different one, while the IP addresses inside stay fixed.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [Segment], [Source MAC], [Destination MAC], [IP payload (unchanged)],
    [Tom to Router0 (client LAN)], [`0060.3E57.B509`], [`000A.F36D.3101` (Gi0/0)],
      [`10.1.1.2` to `23.227.38.65`],
    [Router0 to Server1 (server subnet)], [`000A.F36D.3102` (Gi0/1)],
      [`0060.7044.7973`], [`10.1.1.2` to `23.227.38.65`],
  ),
  caption: [The MAC pair is rewritten at the router; the IP pair is not.],
)

The router is the only device that writes a new MAC pair; each switch leaves both
addresses as it received them. The rule that follows is that MAC addresses are
link-local, valid for a single hop and rebuilt by every router, whereas IP
addresses are end-to-end, set once by the source and read unchanged by the
destination.

= Simulating a Link Failure

To observe a fault, the cable on Router0 `GigabitEthernet0/1`, the only path
from the client LAN to the server subnet, was removed, and a ping was issued
from Tom to `23.227.38.65`.

#figure(
  image("assets/02-link-down.png", width: 100%),
  caption: [With the Router0 to Switch1 cable removed, the server subnet on the
  right is isolated from the rest of the topology.],
)

The result was total loss.

#figure(
  ```
  Laptop0  ->  23.227.38.65
  Packets: Sent = 4, Received = 0, Lost = 4 (100% loss)
  ```,
  caption: [The ping with the link removed.],
)

With the cable gone, the directly connected route to `23.227.38.0` disappears
from Router0's table, so every layer above the physical fault fails at once for
that destination: there is no next hop to ARP for, no route to select, no
handshake to begin, and no page to fetch. A single L1 failure removes L2 through
L7 for any traffic that depended on the link, which shows that the layers form a
dependency chain rather than a set of independent checks.

The cable was then reconnected on the same interfaces, Router0 Gi0/1 to Switch1
Gi0/1. After the switch port finished its spanning-tree transition, a repeated
ping returned zero loss, which confirmed that the topology was restored.

= Conclusion

One web request exercises the whole stack: DNS and HTTP at L7, UDP and TCP at
L4, IPv4 at L3, Ethernet and ARP at L2, and the copper link at L1. The IP pair
is end-to-end and the MAC pair is per-hop. The router is the only device that
reads L3 and rewrites L2, while the switches act only at L2. Error detection is
layered, with the TCP checksum and sequence numbers above the IP and Ethernet
checks. Removing one cable showed that each layer depends on the ones beneath it.
