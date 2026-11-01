#import "/template/lib.typ": *

#show: assignment.with(
  title: "Digital Certificate Chain Practice Lab",
  number: "Assignment 07",
  kind: "Lab",
  keywords: ("TLS", "X.509", "certificate chain", "PKI", "certificate authority"),
  date: datetime(year: 2026, month: 11, day: 1),
)

#heading(level: 1, numbering: none)[Aim]

To inspect a real website's TLS certificate chain, identify the leaf, intermediate, and root
certificates, read their fields, and distinguish what a certificate chain shows from what a
browser's trust decision actually requires.

#let note(body) = block(
  width: 100%,
  above: 1.15em, below: 0.6em,
  fill: theme.head-fill,
  inset: (x: 11pt, y: 8pt),
  radius: 4pt,
  stroke: (left: 2.5pt + theme.link),
)[#strong[Tooling note.] #body]

#note[
  XCA is not installed in this environment, and GUI automation (to drive a browser's
  certificate viewer or XCA's certificate tree) is not available here either. Both are
  substituted with `openssl s_client -showcerts` and `openssl x509 -text`, run from the
  terminal against the real, live sites below on 2026-11-01 at 17:35 IST. This gives the same
  underlying evidence the lab asks for — each certificate's Subject, Issuer, validity dates,
  SAN, and CA/key-usage extensions, read directly off the wire — in place of a browser or XCA
  screenshot. The exported public certificates (`.pem`, no private keys) are saved in
  `Digital_Certificate_Lab/`, named by site and role as the brief asks.
]

#heading(level: 1, numbering: none)[Section A: github.com]

#heading(level: 2, numbering: none)[1. Inspecting the chain]

`openssl s_client -connect github.com:443 -servername github.com -showcerts` returned three
certificates: the leaf and two intermediates. The connection negotiated TLS 1.3 with
`TLS_AES_128_GCM_SHA256`, and verification against openssl's own trust store returned
`Verify return code: 0 (ok)` — the equivalent of a browser reporting the connection as secure.
To keep the table readable, the two Sectigo CA names below are abbreviated: *Sectigo CA DV
E36* for "Sectigo Public Server Authentication CA DV E36", and *Sectigo Root E46* for
"Sectigo Public Server Authentication Root E46" (the full names appear once here).

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, left, left, left, left),
    [Role], [Subject], [Issuer], [Valid from / to], [CA? / key usage],
    [Website (leaf)],
    [CN=github.com \ SAN: github.com, www.github.com],
    [Sectigo CA DV E36],
    [2026-10-30 to 2027-01-27],
    [CA:FALSE; Digital Signature; TLS Server Auth],

    [Intermediate CA 1],
    [Sectigo CA DV E36],
    [Sectigo Root E46],
    [2021-03-22 to 2036-03-21],
    [CA:TRUE, pathlen:0; Digital Signature, Certificate Sign, CRL Sign],

    [Intermediate CA 2],
    [Sectigo Root E46 \ (Issuer $eq.not$ Subject, so not a trust anchor)],
    [CN=USERTrust ECC Certification Authority],
    [2021-03-22 to 2038-01-18],
    [CA:TRUE; Digital Signature, Certificate Sign, CRL Sign],

    [Root / trust anchor],
    [not present],
    [not present],
    [not present],
    [not present],
  ),
  caption: [github.com's certificate chain, read from `openssl x509 -text` on each exported
  certificate. The root was not sent: only 3 certificates were returned, and USERTrust ECC
  Certification Authority never appears as a Subject here, so it must come from the local
  trust store if the chain validates.],
)

#heading(level: 2, numbering: none)[Analysis questions]

#strong[1. Which certificate belongs to the website? Which fields helped identify it?] The
leaf certificate, Subject `CN=github.com`. It is identified by: its Subject CN and SAN
(`github.com`, `www.github.com`) matching the site visited, `Basic Constraints: CA:FALSE`
(it cannot sign other certificates), and its position as the first certificate the server
sends.

#strong[2. For each certificate, how does its Issuer relate to the Subject of the next
certificate in the path?] They match exactly. The leaf's Issuer, "Sectigo Public Server
Authentication CA DV E36", is character-for-character Intermediate CA 1's Subject;
Intermediate CA 1's Issuer is Intermediate CA 2's Subject. This Issuer $arrow.r$ Subject
link is how the chain is built and verified.

#strong[3. Which certificate(s) are CA certificates? What extension supports this?] Both
intermediates. `X509v3 Basic Constraints` reads `CA:TRUE` on both (versus `CA:FALSE` on the
leaf), and their `Key Usage` includes `Certificate Sign`, which only a CA certificate needs.

#strong[4. Does the website certificate contain a SAN for the name visited? Why does this
matter?] Yes: `DNS:github.com, DNS:www.github.com`. Modern browsers validate the hostname
against the SAN list, not the Subject CN (CN-based hostname matching was deprecated); a
certificate without a matching SAN entry is rejected even if the CN looks right, which stops
a certificate issued for one name from being reused to impersonate another.

#strong[5. Are the certificates within their validity periods? What would a browser do if the
website certificate were expired?] Yes, checked 2026-11-01: the leaf is valid
2026-10-30 to 2027-01-27, and both intermediates cover this date with years to spare. An
expired leaf would make the browser block the page behind a certificate-date error (e.g.
Chrome's `NET::ERR_CERT_DATE_INVALID`) instead of loading it silently.

#strong[6. Did the website provide the root certificate, or did it come from the local trust
store?] The website did not provide it. Exactly 3 certificates were returned; the last one's
own Issuer field ("USERTrust ECC Certification Authority") never appears as any certificate's
Subject in the capture, so that root was never transmitted. It must already be in the
validating client's trust store, which is consistent with openssl reporting `Verify return
code: 0` using its own bundled store, not a root fetched from github.com.

#strong[7. What does the connection report say? Does the certificate tree alone establish
trust?] The connection reports TLS 1.3, cipher `TLS_AES_128_GCM_SHA256`, and
`Verify return code: 0 (ok)` — a secure connection. The Issuer/Subject tree built from the
exported certificates only shows that the certificates are internally consistent (each links
to the next); it does not by itself prove trust. Trust additionally needs the root checked
against the *validating party's own* trusted root store, the hostname checked against the
SAN, the dates checked, and revocation checked (OCSP/CRL) — none of which "the tree looks
connected" can show on its own. A forged chain built by an attacker who controls every
certificate in it would look exactly as connected.

#strong[8. Identify one certificate-related problem. What risk, and what should be done?]
Not a defect here, but a real operational risk visible directly in this data: the leaf
certificate's validity window is short, about 90 days (2026-10-30 to 2027-01-27). Short-lived
certificates are standard practice now, but they raise the cost of a missed renewal: if
automated renewal fails even once, the certificate expires with no grace period and every
visitor hits a hard TLS error. An administrator should automate renewal well ahead of expiry
and monitor it; a user who hits an expired-certificate warning should not click through it
and should report it rather than assume it is safe.

#heading(level: 1, numbering: none)[Section B: www.wikipedia.org]

`openssl s_client -connect www.wikipedia.org:443 -servername www.wikipedia.org -showcerts`
returned *four* certificates (one more than github.com). The connection also negotiated TLS
1.3 with `TLS_AES_128_GCM_SHA256`, and `Verify return code: 0 (ok)`.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, left, left, left, left),
    [Role], [Subject], [Issuer], [Valid from / to], [CA? / key usage],
    [Website (leaf)],
    [CN=\*.wikipedia.org],
    [YE2 (Let's Encrypt)],
    [2026-10-04 to 2027-01-02],
    [CA:FALSE; Digital Signature; TLS Server Auth],

    [Intermediate CA 1],
    [YE2 (Let's Encrypt)],
    [Root YE (ISRG)],
    [2025-09-03 to 2028-09-02],
    [CA:TRUE, pathlen:0; Digital Signature, Certificate Sign, CRL Sign],

    [Intermediate CA 2],
    [Root YE (ISRG)],
    [ISRG Root X2],
    [2026-05-13 to 2032-09-02],
    [CA:TRUE; Certificate Sign, CRL Sign],

    [Intermediate CA 3 \ (4th cert sent)],
    [ISRG Root X2],
    [ISRG Root X1],
    [2026-05-13 to 2032-09-02],
    [CA:TRUE; Certificate Sign, CRL Sign],
  ),
  caption: [www.wikipedia.org's certificate chain. All four certificates the server sent are
  shown; none is self-signed, so the true root (ISRG Root X1, presumably self-signed) was not
  sent.],
)

The leaf's SAN list is large, about forty Wikimedia-family domains in one certificate
(`wikipedia.org`, `wikidata.org`, `wiktionary.org`, and similar, each with a wildcard
variant), rather than the two names on github.com's leaf.

#heading(level: 1, numbering: none)[Section B: Comparison]

Both chains terminate one step short of a self-signed root that the server never transmits,
but otherwise the two have little in common. github.com's three-certificate chain runs
through Sectigo's commercial PKI (a DV leaf $arrow.r$ Sectigo CA DV E36 $arrow.r$ an unsent
USERTrust ECC root) and scopes its leaf to exactly two names. www.wikipedia.org's
four-certificate chain runs through Let's Encrypt's automated PKI (a leaf $arrow.r$ YE2
$arrow.r$ ISRG Root YE $arrow.r$ ISRG Root X2, itself cross-signed by an unsent ISRG Root X1)
and scopes its leaf to roughly forty Wikimedia domains in one wildcard-heavy SAN list. Despite
using different certificate authorities, different chain lengths, and different issuance
models, both connections negotiated identical TLS 1.3 / `TLS_AES_128_GCM_SHA256` sessions and
validated cleanly, so a visitor's browser would report the same "connection is secure" outcome
for either site.

#heading(level: 1, numbering: none)[Conclusion]

Both inspected sites build their certificate chain the same structural way — each
certificate's Issuer field matches the next certificate's Subject field, climbing from a
narrowly-scoped leaf through one or more CA certificates (`CA:TRUE`, with `Certificate Sign`
in their key usage) — while neither actually transmits the self-signed root that anchors
trust; that root has to already be in the validating party's trust store. A chain that "looks
connected" when read this way confirms internal consistency, not trust: trust also depends on
the SAN matching the visited name, the dates being current, revocation status, and the root
being one the client already trusts, none of which the chain alone demonstrates. github.com
and www.wikipedia.org differ in every concrete detail — issuing CA, chain length, leaf scope —
yet produce an identical negotiated TLS 1.3 connection and an identical "trusted" outcome,
which is the clearest evidence that the chain's shape and the trust decision, while related,
are not the same thing.
