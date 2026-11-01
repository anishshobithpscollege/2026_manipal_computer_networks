#import "/template/lib.typ": *

#show: assignment.with(
  title: "TLS 1.2 RSA Handshake: Capture, Inspection and Decryption",
  number: "Assignment 08",
  kind: "Lab",
  keywords: ("TLS 1.2", "RSA key exchange", "Wireshark", "OpenSSL", "packet capture"),
  date: datetime(year: 2026, month: 11, day: 1),
)

#heading(level: 1, numbering: none)[Aim]

To run a TLS client and server on the same machine with TLS 1.2 forced to the RSA
key-exchange cipher `TLS_RSA_WITH_AES_128_GCM_SHA256`, capture the connection, identify the
full handshake sequence, and decrypt the session with the server's RSA private key.

#let note(body) = block(
  width: 100%,
  above: 1.15em, below: 0.6em,
  fill: theme.head-fill,
  inset: (x: 11pt, y: 8pt),
  radius: 4pt,
  stroke: (left: 2.5pt + theme.link),
)[#strong[Tooling note.] #body]

#note[
  The manual is written for Windows PowerShell and the Wireshark GUI. This run uses macOS,
  `zsh`, and command-line `tshark` instead, with the `wireshark-mcp` tool suite for
  packet-level inspection — the same OpenSSL commands, the same capture filter and loopback
  interface (`lo0` in place of the Npcap Loopback Adapter), and the same RSA-key decryption
  mechanism (Wireshark's RSA Keys list, set here via `tshark`'s `rsa_keys` UAT instead of
  Edit $arrow.r$ Preferences $arrow.r$ RSA Keys). The two required screenshots are replaced
  with the equivalent packet-list and decrypted-stream text below, pulled directly from the
  capture.
]

#heading(level: 1, numbering: none)[Part 1: Lab Setup]

A working folder (`~/tls-lab`) held a one-day self-signed certificate and its matching 2048-bit
RSA key, generated with:

#code("
openssl req -x509 -newkey rsa:2048 -nodes -keyout server.key -out server.crt -days 1 \\
  -subj \"/CN=localhost\" -addext \"subjectAltName=DNS:localhost\"
", lang: "text")

`openssl ciphers -v AES128-GCM-SHA256` confirmed the cipher is `TLSv1.2 Kx=RSA Au=RSA`, i.e.
RSA key exchange.

#heading(level: 1, numbering: none)[Part 2: Capture and Handshake]

A loopback capture (`tcp port 4433`) was started, then the server:

#code("
openssl s_server -accept 127.0.0.1:4433 -cert server.crt -key server.key -www \\
  -tls1_2 -cipher AES128-GCM-SHA256 -msg -state
", lang: "text")

and the client, which sent `GET / HTTP/1.0` followed by a blank line:

#code("
openssl s_client -connect 127.0.0.1:4433 -servername localhost -tls1_2 \\
  -cipher AES128-GCM-SHA256 -CAfile server.crt -verify_hostname localhost \\
  -verify_return_error -msg -state
", lang: "text")

The client reported a successful connection: `Verification: OK`, `New, TLSv1.2, Cipher is
AES128-GCM-SHA256`, `Protocol: TLSv1.2`, and received the server's small HTTP response before
both sides exchanged a `close_notify` alert.

#heading(level: 1, numbering: none)[Part 3: Inspecting the Packets]

#heading(level: 2, numbering: none)[Before decryption]

Filtering on `tcp.port == 4433` in the saved capture (`tls-rsa-handshake.pcapng`, 24 packets)
shows the full handshake in order, each message matching the class diagram:

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    [Frame], [Message], [Direction],
    [5], [ClientHello (SNI=localhost)], [Client $arrow.r$ Server],
    [7], [ServerHello, Certificate, ServerHelloDone], [Server $arrow.r$ Client],
    [9], [ClientKeyExchange, ChangeCipherSpec, Finished (encrypted)], [Client $arrow.r$ Server],
    [11], [NewSessionTicket, ChangeCipherSpec, Finished (encrypted)], [Server $arrow.r$ Client],
    [13], [Application Data (103 bytes, encrypted)], [Client $arrow.r$ Server],
    [15], [Encrypted Alert], [Server $arrow.r$ Client],
    [19], [Application Data (2069 bytes, encrypted)], [Server $arrow.r$ Client],
    [21], [Encrypted Alert], [Client $arrow.r$ Server],
  ),
  caption: [The handshake and data exchange, read from `tshark`'s packet list before any
  decryption key is supplied. Frame 7's ServerHello carries `Cipher Suite:
  TLS_RSA_WITH_AES_128_GCM_SHA256 (0x009c)`, confirmed by `tshark -V` on that frame.],
)

Frame 9's `ClientKeyExchange` is 258 bytes of handshake payload — the size of an RSA-2048
encrypted block (256 bytes) plus its 2-byte length prefix — and is unreadable in the capture
without the server's private key, as it must be.

#heading(level: 2, numbering: none)[Decrypting with the server's private key]

`tshark`'s equivalent of Wireshark's Edit $arrow.r$ Preferences $arrow.r$ RSA Keys list is its
`rsa_keys` UAT, loaded with:

#code("
tshark -r tls-rsa-handshake.pcapng -o 'uat:rsa_keys:\"/Users/.../tls-lab/server.key\",\"\"' \\
  -Y \"tls\" -T fields -e frame.number -e _ws.col.protocol -e _ws.col.info
", lang: "text")

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    [Frame], [Protocol (after decryption)], [Info],
    [5], [TLSv1], [ClientHello (SNI=localhost)],
    [7], [TLSv1.2], [ServerHello, Certificate, ServerHelloDone],
    [9], [TLSv1.2], [ClientKeyExchange, ChangeCipherSpec, *Finished*],
    [11], [TLSv1.2], [NewSessionTicket, ChangeCipherSpec, *Finished*],
    [13], [*HTTP*], [*GET / HTTP/1.0*],
    [19], [TLSv1.2], [TLS segment of a reassembled PDU (HTTP response)],
  ),
  caption: [The same capture after the RSA key is supplied. Frames 9 and 11 now show their
  real message name, `Finished`, instead of an opaque "Encrypted Handshake Message"; frame
  13, previously "Application Data", is now dissected as a complete `HTTP` request.],
)

`tshark -z follow,tls,ascii,0` with the same key reassembles the decrypted session:

#code("
GET / HTTP/1.0

	1984
HTTP/1.0 200 ok
Content-type: text/html

<HTML><BODY BGCOLOR=\"#ffffff\">
<pre>
...
</pre></BODY></HTML>
", lang: "text")

the plaintext HTTP request and the server's default `-www` status page, both fully readable
once the matching private key is supplied.

#heading(level: 1, numbering: none)[Part 4: Analysis]

#strong[1. Which TLS version and cipher suite were negotiated? Where did you find this in
OpenSSL and Wireshark?] TLS 1.2 with `TLS_RSA_WITH_AES_128_GCM_SHA256`. OpenSSL's client
output states it directly: "New, TLSv1.2, Cipher is AES128-GCM-SHA256" and "Protocol:
TLSv1.2". In the capture, frame 7's ServerHello carries `Version: TLS 1.2 (0x0303)` and
`Cipher Suite: TLS_RSA_WITH_AES_128_GCM_SHA256 (0x009c)` — the server's actual selection,
which is what gets used.

#strong[2. Which handshake messages came from the client, and which from the server?] Client:
ClientHello (frame 5), ClientKeyExchange + its ChangeCipherSpec/Finished (frame 9), the HTTP
request once decrypted (frame 13), and a closing alert. Server: ServerHello, Certificate,
ServerHelloDone (frame 7), NewSessionTicket + its ChangeCipherSpec/Finished (frame 11), the
HTTP response (frame 19), and its own closing alert.

#strong[3. What information does the server certificate provide? Which key is used by the
client during this RSA key exchange?] The Certificate message (inside frame 7) carries the
server's X.509 certificate: Subject `CN=localhost`, its 2048-bit RSA public key, validity
dates, and the `subjectAltName=DNS:localhost` extension added at generation. The client
extracts the server's *public* key from this certificate and uses it to encrypt the
pre-master secret in ClientKeyExchange; only the server's matching *private* key (`server.key`)
can decrypt it back.

#strong[4. Is the pre-master secret visible as plaintext in the capture? Explain what is
actually sent.] No. Frame 9's ClientKeyExchange carries a 256-byte RSA-encrypted block (the
pre-master secret encrypted under the server's public key), which only the holder of
`server.key` can recover. Nothing in the capture shows the pre-master secret itself in the
clear, before or after decryption — decryption recovers the handshake and application
*records*, not a plaintext copy of that one field, since it never crosses the wire unencrypted
in the first place.

#strong[5. What do the client and server derive from the pre-master secret and the two random
values?] Both sides independently compute the same *master secret* from the pre-master
secret plus the ClientHello and ServerHello random values (visible in frames 5 and 7,
unencrypted, since randoms are sent in the clear), using the TLS PRF. From the master secret
plus the same two randoms, both derive the matching set of symmetric session keys (for AES
encryption and the GCM authentication) used for everything after ChangeCipherSpec — without
ever sending the master secret or session keys over the network.

#strong[6. What changes in Wireshark after you configure the matching private key?] Frames 9
and 11 show their real handshake type, `Finished`, instead of an undifferentiated encrypted
record. Frame 13, previously generic "Application Data", is re-dissected as a complete `HTTP`
request (`GET / HTTP/1.0`), and following the TLS stream reassembles the full plaintext
request and response, including the server's HTML status page — none of which was readable
before the key was supplied.

#strong[7. Why would this private key not decrypt a TLS 1.3 connection or a TLS 1.2 ECDHE
connection?] This key only recovers the pre-master secret from an RSA *key-transport*
ClientKeyExchange, where the client itself chooses the pre-master secret and encrypts it
directly with the server's static public key — the one operation this specific private key
can reverse. ECDHE instead has each side generate an ephemeral Diffie–Hellman key pair per
session and derive a shared secret that the server's long-term RSA key never touches, so
having that key gives no way back to the shared secret. TLS 1.3 removed static RSA key
exchange entirely — every TLS 1.3 handshake is (EC)DHE-based — so a captured RSA private key
can never decrypt a TLS 1.3 session, regardless of what certificate it belongs to.

#heading(level: 1, numbering: none)[Submission]

- Packet capture: `tls-rsa-handshake.pcapng` (24 packets, included alongside this report).
- "Before decryption" evidence: the handshake-sequence table in Part 3, from the unmodified
  capture.
- "After decryption" evidence: the re-dissected packet table and the decrypted
  `follow,tls,ascii` stream in Part 3, both produced only once `server.key` was supplied.
- Answers to all seven analysis questions, above.
