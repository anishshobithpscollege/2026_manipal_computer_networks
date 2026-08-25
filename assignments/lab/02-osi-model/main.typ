#import "/template/lib.typ": *

#show: assignment.with(
  title: "Understanding the OSI Model",
  number: "Assignment 02",
  kind: "Lab",
  keywords: ("OSI model", "Packet Tracer", "encapsulation", "ARP", "DNS", "TCP/IP"),
)

// Each question from the assignment is shown verbatim in a shaded box, with the
// answer written underneath. Pure procedure instructions are not reproduced.
#let q(body) = block(
  width: 100%,
  above: 1.15em, below: 0.6em,
  fill: theme.head-fill,
  inset: (x: 11pt, y: 8pt),
  radius: 4pt,
)[#strong[Q.] #body]

#heading(level: 1, numbering: none)[Aim]

To capture and analyse a single web (HTTP) request between a client and a server
in Cisco Packet Tracer, and to identify how each stage of the request maps to the
layers of the OSI reference model, including the addresses, protocols, ports, and
error-checking fields used at each layer.

#heading(level: 1, numbering: none)[Packet Capture and Inspection]

#figure(
  image("assets/01-topology.png", width: 100%),
  caption: [The network topology. The client network `10.1.1.0` on Switch0 is
  joined by Router0 to the server network `23.227.38.0` on Switch1.],
)

#q[Which layers of the OSI model are visible in the packet capture?]

Five layers are directly visible in the capture:

- *Layer 7 (Application):* the DNS query and response, and the HTTP request and response.
- *Layer 4 (Transport):* UDP for DNS and TCP for HTTP, including port numbers and sequence/acknowledgement numbers.
- *Layer 3 (Network):* the source and destination IP addresses and the routing decision.
- *Layer 2 (Data Link):* Ethernet framing and ARP.
- *Layer 1 (Physical):* transmission of the frame over the cable.

#heading(level: 1, numbering: none)[Source and Destination]

// Reset the section counter so the assignment questions are numbered 1 onward.
#counter(heading).update(0)

#q[What are the source and destination IP addresses in the packet capture? Which
OSI layer handles these addresses?]

The source IP address is `10.1.1.2` (the client, Laptop0) and the destination IP
address is `23.227.38.65` (the web server, Server1). IP addresses are handled at
*Layer 3 (Network)*.

#q[Identify the source and destination MAC addresses. Which OSI layer is
responsible for handling these?]

On the client network segment, the source MAC address is `0060.3E57.B509` (the
client) and the destination MAC address is `000A.F36D.3101` (Router0, interface
Gi0/0). MAC addresses are handled at *Layer 2 (Data Link)*. The MAC address pair
is replaced on each segment; the full change is detailed under Data Flow.

= Identify the Layers Involved in This Communication

#q[For each step in the communication, identify the OSI layer involved.]

In summary, DNS resolution
and the HTTP request and response operate at Layer 7; the TCP handshake and data
transfer at Layer 4; IP addressing and routing at Layer 3; ARP and Ethernet
framing at Layer 2; and transmission over the medium at Layer 1.

#q[Which layer is responsible for:
- Establishing the connection between the PC and the server?
- Translating the domain name into an IP address?
- Ensuring data is error-free?]

- *Establishing the connection:* Layer 4 (Transport). TCP establishes the
  connection through a three-way handshake (SYN, SYN-ACK, ACK) before any data is
  transferred.
- *Translating the domain name into an IP address:* Layer 7 (Application),
  performed by the DNS protocol.
- *Ensuring data is error-free:* Layer 4 (Transport). TCP uses sequence and
  acknowledgement numbers together with a checksum to detect loss or corruption
  and to retransmit missing segments.

= Examine the Data Encapsulation Process

#q[For each hop, identify the headers and trailers added or removed at each OSI
layer.]

Encapsulation adds a header at each layer, and a trailer at Layer 2, as data
descends the stack; decapsulation removes them as data ascends the stack. The
action at each device is shown below.

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    [Device], [Layer], [Action on the packet],
    [Laptop0 (source)], [7 to 1], [adds the TCP header (ports, sequence numbers),
      then the IP header (source and destination IP, TTL), then the Ethernet
      header and trailer (source and destination MAC, FCS)],
    [Switch0], [2], [forwards using the destination MAC address; no header is added or removed],
    [Router0], [3], [removes the Ethernet header, decrements the TTL, selects the
      route, and adds a new Ethernet header with new source and destination MAC addresses],
    [Switch1], [2], [forwards using the destination MAC address; frame unchanged],
    [Server1 (destination)], [1 to 7], [removes the Ethernet, IP, and TCP headers
      in turn and delivers the HTTP request to the web service],
  ),
  caption: [Headers and trailers added or removed at each hop.],
)

#q[Which layers modify the packet the most during its journey?]

Layer 2 (Data Link) is modified the most. The IP header changes only in its TTL
field, which is decremented by one at each router, whereas the Ethernet header and
trailer are removed and rebuilt at every router hop, with both MAC addresses
replaced. The switches forward frames without modifying them.

= Protocol Identification

#q[Identify the following: the application layer protocol, the transport layer
protocol, and the network layer protocol.]

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    [Layer], [Protocol], [Use in this exchange],
    [Application (7)], [HTTP (and DNS)], [request the web page; resolve the domain name],
    [Transport (4)], [TCP (and UDP)], [reliable delivery of the page; UDP for the DNS lookup],
    [Network (3)], [IPv4], [addressing and routing between the two networks],
  ),
  caption: [Protocols used at each layer.],
)

The application layer protocol is *HTTP* (with *DNS* for name resolution), the
transport layer protocol is *TCP* (and *UDP* for DNS), and the network layer
protocol is *IP (IPv4)*.

= Analyze IP Addressing

#q[Identify the source and destination IP addresses of the packet.]

Source IP: `10.1.1.2` (client). Destination IP: `23.227.38.65` (web server).

#q[At which OSI layer are these addresses added?]

The IP addresses are added at *Layer 3 (Network)*. As the destination is on a
different network, the packet is sent to the default gateway (`10.1.1.1`) for
forwarding.

#q[What happens to the IP addresses when the packet reaches the server?]

The server compares the destination IP address with its own interface address
(`23.227.38.65`). They match, so the packet is accepted and decapsulated rather
than forwarded. The IP addresses are not changed anywhere along the path, as no
NAT is configured on the router.

= Port Numbers and Sockets

#q[What are the source and destination port numbers for this website request?]

The destination port is `80` (HTTP). The source port is `1025`, an ephemeral port
assigned by the client for this connection.

#q[Which OSI layer uses these port numbers, and why are they important?]

Port numbers are used at *Layer 4 (Transport)*. A port number identifies the
specific process or service at each host, so a host running several applications
can deliver each segment to the correct process. Port 80 directs the request to
the web service, and the ephemeral source port ensures the reply returns to the
requesting process. The combination of an IP address and a port number is called
a socket.

= Error Detection

#q[Find the layer where error detection mechanisms are applied to ensure reliable
transmission.]

Error checking is present at Layers 2, 3, and 4. Reliable transmission, meaning
ordered and complete delivery with retransmission of lost data, is provided at
*Layer 4 (Transport)* by TCP. *Layer 2 (Data Link)* additionally checks each frame
for corruption on the link.

#q[What specific mechanism or field in the packet is responsible for error
checking?]

- *Layer 2:* the Frame Check Sequence (FCS), a CRC-32 value in the Ethernet trailer.
- *Layer 3:* the IPv4 header checksum.
- *Layer 4:* the TCP checksum, together with sequence and acknowledgement numbers
  for detecting loss and triggering retransmission.

= Path Analysis

#q[Trace the path of the packet from the PC to the server and back.]

The packet travels Laptop0, Switch0, Router0, Switch1, Server1, and the reply
follows the reverse path.

#q[Identify the devices involved at each hop (switches, routers, etc.).]

Two switches and one router lie between the end hosts: Switch0 on the client side,
Router0 in the middle, and Switch1 on the server side. The end hosts are Laptop0
(client) and Server1 (web server).

#q[How does each device process the packet differently based on its OSI layer?]

- *Switches (Switch0, Switch1) at Layer 2:* forward the frame using the
  destination MAC address and the MAC address table; they do not examine the IP
  header or modify the packet.
- *Router (Router0) at Layer 3:* examines the destination IP address, selects the
  outgoing interface from its routing table, decrements the TTL, and builds a new
  Layer 2 frame with updated MAC addresses.
- *End hosts (Laptop0, Server1) at Layer 7:* originate and process the data
  through all seven layers.

= DNS Resolution

#q[Analyze the process of resolving the domain name to an IP address.]

Before the connection is opened, the client sends a DNS query for `www.cyber.com`
to the DNS server (`10.1.1.10`). The DNS server returns the corresponding IP
address `23.227.38.65`. This resolution completes before the TCP connection to the
web server is initiated.

#q[What additional packets are sent, and which OSI layers are involved in this
resolution?]

Two additional packets are sent: one DNS query and one DNS response. The layers
involved are Layer 7 (the DNS query and response), Layer 4 (UDP), Layer 3 (IP,
within the same subnet), and Layers 2 and 1 (Ethernet framing and physical
transmission), with ARP used at Layer 2 to resolve the MAC address on first
contact.

= Data Flow

#q[Examine and explain how the source and destination MAC addresses change as the
packet passes through different network devices.]

At each router hop the Layer 2 frame is rebuilt, so the source and destination MAC
addresses are replaced, while the Layer 3 IP addresses remain unchanged.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [Segment], [Source MAC], [Destination MAC], [IP addresses (unchanged)],
    [Laptop0 to Router0], [`0060.3E57.B509`], [`000A.F36D.3101`],
      [`10.1.1.2` to `23.227.38.65`],
    [Router0 to Server1], [`000A.F36D.3102`], [`0060.7044.7973`],
      [`10.1.1.2` to `23.227.38.65`],
  ),
  caption: [MAC addresses are rewritten at the router; IP addresses are not.],
)

The switches do not change the MAC addresses; only the router rewrites them. MAC
addresses are therefore local to a single link, whereas IP addresses remain
constant from source to destination.

= Simulate Network Issues

#q[Disconnect a device (e.g., a router or switch) and observe how the
communication fails. Identify which OSI layers are affected and how the failure
manifests in the packet analysis.]

The link between Router0 (interface Gi0/1) and Switch1 was disconnected, removing
the only path to the server network. A ping from the client to `23.227.38.65` then
failed completely.

#figure(
  image("assets/02-link-down.png", width: 100%),
  caption: [With the Router0 to Switch1 link removed, the server network is
  isolated from the rest of the topology.],
)

#figure(
  ```
  Laptop0  ->  23.227.38.65
  Packets: Sent = 4, Received = 0, Lost = 4 (100% loss)
  ```,
  caption: [Ping result with the link removed.],
)

The failure originates at *Layer 1 (Physical)*, the disconnected link. Because
each layer depends on the layer below it, Layers 2 to 7 also fail for this
destination: the next-hop MAC address cannot be resolved (Layer 2), no route to
the network is available (Layer 3), the TCP connection cannot be established
(Layer 4), and the web page cannot be requested (Layer 7). In the packet analysis
this appears as 100% packet loss, with no reply returned. After the link was
reconnected, a further ping reported 0% loss, confirming that connectivity was
restored.

#heading(level: 1, numbering: none)[Conclusion]

A single web request uses the full OSI stack: DNS and HTTP at Layer 7, TCP and
UDP at Layer 4, IP at Layer 3, Ethernet and ARP at Layer 2, and the physical link
at Layer 1. The IP addresses remain constant from source to destination, while the
MAC addresses are rewritten at each router hop. Switches operate only at Layer 2,
and the router is the only device that operates at Layer 3. Error detection is
applied at Layers 2, 3, and 4. Disconnecting a single link caused the request to
fail completely, demonstrating that each layer depends on the layers below it.
