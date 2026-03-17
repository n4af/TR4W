# Icom RS-BA1 v2 UDP Network Protocol Guide

## Purpose

This guide documents Icom's proprietary UDP network protocol used for controlling Icom radios over Ethernet and WiFi. It covers the protocol specification, authentication, CI-V command framing, and — critically — the implementation quirks that are not documented anywhere else. These quirks were discovered through packet capture analysis (Wireshark/tshark) of wfview sessions, examination of wfview and TR4QT source code, and extensive trial-and-error testing against IC-7760 and IC-9700 hardware.

**Audience**: Developers implementing Icom network radio control in any language.

**Sources**: Reverse-engineered from wfview (open source), TR4QT (Qt/C++), and TR4W (Delphi 7) implementations, verified against IC-7760 and IC-9700 hardware. Icom does not publish this protocol.

---

## Table of Contents

1. [Protocol Overview](#1-protocol-overview)
2. [Transport Layer](#2-transport-layer)
3. [Byte Order (Mixed Endianness)](#3-byte-order-mixed-endianness)
4. [Client ID Generation](#4-client-id-generation)
5. [Connection Handshake](#5-connection-handshake)
6. [Authentication](#6-authentication)
7. [CI-V Socket Setup](#7-civ-socket-setup)
8. [Packet Structures](#8-packet-structures)
9. [Sequence Number Management](#9-sequence-number-management)
10. [Keepalives and Timers](#10-keepalives-and-timers)
11. [CI-V Command Framing](#11-civ-command-framing)
12. [CI-V Commands for Contest Operation](#12-civ-commands-for-contest-operation)
13. [Transceive (Push Updates)](#13-transceive-push-updates)
14. [Data Mode Overlay ($1A $06)](#14-data-mode-overlay-1a-06)
15. [Disconnection Protocol](#15-disconnection-protocol)
16. [Password Encoding](#16-password-encoding)
17. [Broadcast Discovery](#17-broadcast-discovery)
18. [Radio-Specific Notes](#18-radio-specific-notes)
19. [Implementation Quirks and Gotchas](#19-implementation-quirks-and-gotchas)
20. [Debugging Tips](#20-debugging-tips)

---

## 1. Protocol Overview

The Icom RS-BA1 v2 protocol allows software to control Icom radios over a local network (Ethernet or WiFi) as an alternative to serial/USB connections. It wraps standard Icom CI-V commands inside a custom UDP framing protocol with authentication, keepalives, and session management.

**Key characteristics:**
- **Two UDP sockets** — one for control/authentication, one for CI-V data
- **Session-based** — a full handshake must complete before CI-V commands can be sent
- **Mixed endianness** — header fields are little-endian, payload fields are big-endian
- **Single client** — most Icom radios allow only one network control session at a time
- **No encryption** — passwords are obfuscated with a simple substitution cipher
- **No audio** — this guide covers the control protocol only (audio streaming is a separate topic)

### Supported Radios

| Radio | CI-V Address | Controller Address | Network Port | Notes |
|-------|-------------|-------------------|-------------|-------|
| IC-705 | $A4 | $E0 | 50001 | WiFi or USB |
| IC-7300MK2 | $B6 | $E0 | 50001 | Network version of IC-7300 |
| IC-7600 | $7A | $E0 | 50001 | Older model |
| IC-7610 | $98 | $E0 | 50001 | |
| IC-7760 | $B2 | **$E1** | 50001 | Many protocol quirks |
| IC-7850/7851 | $8E | $E0 | 50001 | Identical protocol |
| IC-905 | $AC | $E0 | 50001 | VHF/UHF/SHF |
| IC-9700 | $A2 | $E0 | 50001 | |
| IC-R8600 | $96 | $E0 | 50001 | Receiver only |

The original IC-7300 (non-MK2) does NOT have network capability.

---

## 2. Transport Layer

- **Protocol**: UDP (connectionless, unreliable)
- **Control Port**: 50001 (configurable on radio's Network Settings menu)
- **CI-V Data Port**: Learned from radio during handshake (typically 50002)
- **IPv4 only**
- **MTU**: Packets are always well under 1500 bytes; no fragmentation concerns

You need TWO separate UDP sockets:
1. **Control socket** — binds to any local port, sends/receives on the radio's control port (50001)
2. **CI-V socket** — binds to any local port, sends/receives on the radio's CI-V port (learned during handshake)

> **QUIRK**: The CI-V port is reported by the radio in the Status Packet during the handshake. Some radios (IC-9700) may report port 0 — use 50002 as a fallback.

---

## 3. Byte Order (Mixed Endianness)

This is one of the most confusing aspects of the protocol. The same packet uses **both** byte orders:

| Field Location | Endianness | Examples |
|---------------|-----------|---------|
| Packet header (offset $00-$0F) | **Little-endian** | Len, PktType, Seq, SentID, RcvdID |
| Payload fields (offset $10+) | **Big-endian** | PayloadSize, InnerSeq, CivPort, RxSample |
| Data packet DataLen (offset $11) | **Little-endian** | CI-V data length |
| Data packet SendSeq (offset $13) | **Big-endian** | Inner CI-V sequence |

> **QUIRK**: `DataLen` and `SendSeq` are adjacent fields (offsets $11 and $13) with DIFFERENT byte orders. DataLen is little-endian, SendSeq is big-endian. Getting DataLen wrong causes the radio to read a wildly incorrect data length and NAK all CI-V write commands.

### Helper Functions

```
SwapWord(value):    return (value >> 8) | (value << 8)
SwapLongWord(value): return byte-reverse all 4 bytes
```

Use SwapWord/SwapLongWord for all big-endian fields. Do NOT swap header fields.

---

## 4. Client ID Generation

Each client needs a unique 32-bit identifier (`SentID` / `myId`). It's computed from the local IP address and the local UDP socket port:

```
myId = (ip_octet_3 << 24) | (ip_octet_4 << 16) | (local_port & 0xFFFF)
```

Example: IP 192.168.73.218, local port 52066 → myId = `(73 << 24) | (218 << 16) | 52066`

> **QUIRK**: You must use the **routed IP address** that reaches the radio, not 127.0.0.1. On multi-homed systems, determine the correct local IP by creating a temporary UDP socket, "connecting" it to the radio's IP (this doesn't send anything for UDP), then calling `getsockname()` to get the OS-selected source address. This is a standard trick for route detection.

> **QUIRK**: The myId only needs to be **unique**, not follow a specific formula. The radio uses it as a session identifier. However, matching the formula used by wfview/TR4QT helps with debugging since you can correlate packet captures.

---

## 5. Connection Handshake

The full connection requires a 13-step handshake across two sockets:

### Control Socket Handshake (Steps 1-8)

```
Step  Direction      Packet Type    Size    Description
----  ---------      -----------    ----    -----------
1     Client→Radio   0x03 (AYT)    0x10    "Are You There"
2     Radio→Client   0x04 (IAH)    0x10    "I Am Here" (learn radio's SentID)
3     Client→Radio   0x06 (AYR)    0x10    "Are You Ready"
4     Radio→Client   0x06 (IAR)    0x10    "I Am Ready"
5     Client→Radio   Login          0x80    Encoded username/password
6     Radio→Client   LoginResponse  0x60    Token (or error)
7     Client→Radio   TokenAck       0x40    Acknowledge token
      Radio→Client   Capabilities   var     Radio list with CI-V address
8     Client→Radio   ConnInfo       0x90    Stream request (includes local CI-V port)
      Radio→Client   StatusPacket   0x50    CI-V port number (big-endian)
```

### CI-V Socket Handshake (Steps 9-13)

After learning the CI-V port from step 8, open a second UDP socket:

```
Step  Direction      Packet Type    Size    Description
----  ---------      -----------    ----    -----------
9     Client→Radio   0x03 (AYT)    0x10    "Are You There" (CI-V socket)
10    Radio→Client   0x04 (IAH)    0x10    "I Am Here" (DIFFERENT SentID!)
11    Client→Radio   0x06 (AYR)    0x10    "Are You Ready"
12    Radio→Client   0x06 (IAR)    0x10    "I Am Ready"
13    Client→Radio   OpenClose      0x16    CI-V Open (magic=$04)
      → CI-V stream is now active
```

> **CRITICAL QUIRK**: The radio's SentID on the CI-V socket is **different** from the control socket. You must store both as separate variables (`remoteId` for control, `civRemoteId` for CI-V). Using the wrong ID causes the radio to ignore your packets.

> **QUIRK**: After sending the CI-V Open packet (step 13), wait approximately **200ms** before sending CI-V commands. Commands sent immediately after Open are silently ignored by the radio (it sends ACKs but no data responses).

---

## 6. Authentication

### Login Packet (0x80 = 128 bytes)

The login packet contains:
- Encoded username (16 bytes at offset $40)
- Encoded password (16 bytes at offset $50)
- ASCII client name (16 bytes at offset $60, e.g. "TR4W" or "wfview")
- PayloadSize at offset $10 = SwapLongWord($70) (big-endian)
- RequestReply = $01, RequestType = $00
- InnerSeq = SwapWord(authSeq) where authSeq starts at $30
- TokRequest = random 16-bit value
- Token = 0 (initial login)

### Login Response (0x60 = 96 bytes)

- Error at offset $30: 0 = success, $FEFFFFFF = authentication failed
- Token at offset $1C: save this — needed for all subsequent auth packets
- AuthStartID at offset $20: save this

### Token Acknowledgment (0x40 = 64 bytes)

After successful login, send a token ack:
- RequestType = $02 (ack)
- Token = the token from login response
- AuthStartID from login response
- ResetCap at offset $24 = SwapWord($0798)
- Include MAC address or GUID from login response

### 24-Byte Rejection Packet

The radio sometimes sends a 24-byte packet instead of the expected 96-byte login response:

```
18 00 00 00 01 00 00 00 [radioId 4B] [ourId 4B] 82 FF FF FF 00 00 00 00
```

The `$82 FF FF FF` payload means "session busy" or "stale session." This happens when:
- A previous session wasn't cleanly disconnected
- The radio still has an active session from a crashed client

**Handling**: Retry the login after a few seconds. Implement a login retry timer (e.g., 5 seconds, 6 attempts). The radio's session timeout will eventually clear the stale session.

---

## 7. CI-V Socket Setup

### Capabilities Packet

After token acknowledgment, the radio sends a capabilities packet containing:
- Number of radios (offset $40, big-endian Word)
- Per-radio entries (102 bytes each) with:
  - Radio name (32 bytes at offset $10, e.g. "IC-7760")
  - **CI-V address** (1 byte at offset $52, e.g. $B2 for IC-7760)
  - MAC address (6 bytes at offset $0A)
  - CommonCap (Word at offset $07)

> **QUIRK**: The DataLen guard for dispatch must be per-state. The capabilities packet (66 bytes minimum) and status packet (80 bytes) have different minimum sizes than the login response (96 bytes). If you use a single `>= 96` guard for all auth packets, you'll silently drop capabilities and status packets. This was a bug that took significant debugging to find.

### Stream Request (ConnInfo, 0x90 = 144 bytes)

After receiving capabilities, send a stream request:
- RadioName at offset $40 = name from capabilities (copy the 32 bytes)
- Encoded username at offset $60
- RxEnable = 1, TxEnable = 0 (control only, no audio)
- RxCodec = $04 (LPCM), TxCodec = 0
- RxSample = SwapLongWord(8000)
- CivPort = SwapLongWord(your_local_civ_port) — the port your CI-V socket is bound to
- AudioPort = 0 (no audio)

### Status Packet Response (0x50 = 80 bytes)

The radio responds with CI-V port information:
- CivPort at offset $42 = SwapWord(port) — **big-endian!** This is the port to send CI-V data TO
- Disc at offset $40: $01 means disconnected (connection refused)

---

## 8. Packet Structures

All structures use packed alignment (no padding). Sizes shown in hex.

### Control Packet ($10 = 16 bytes)

```
Offset  Size  Field    Description
$00     4     Len      Always $10
$04     2     PktType  $03=AYT, $04=IAH, $05=Disconnect, $06=AYR/IAR
$06     2     Seq      Sequence number (LE)
$08     4     SentID   Sender's ID (LE)
$0C     4     RcvdID   Receiver's ID (LE, 0 for initial AYT)
```

### Ping Packet ($15 = 21 bytes)

```
Offset  Size  Field    Description
$00     4     Len      Always $15
$04     2     PktType  Always $07
$06     2     Seq      Ping sequence (LE, separate counter)
$08     4     SentID   (LE)
$0C     4     RcvdID   (LE)
$10     1     Reply    0=request, 1=response
$11     4     Time     Uptime in milliseconds
```

### Data Packet ($15 = 21 byte header + CI-V payload)

```
Offset  Size  Field    Description
$00     4     Len      Total packet length (header + CI-V data) (LE)
$04     2     PktType  Always $00
$06     2     Seq      Outer UDP sequence (LE)
$08     4     SentID   (LE)
$0C     4     RcvdID   (LE)
$10     1     Reply    $C1 for data
$11     2     DataLen  CI-V data length (*** LITTLE-ENDIAN ***)
$13     2     SendSeq  Inner CI-V sequence (*** BIG-ENDIAN ***)
$15+    var   CivData  Raw CI-V frame(s)
```

### Open/Close Packet ($16 = 22 bytes)

```
Offset  Size  Field    Description
$00     4     Len      Always $16
$04     2     PktType  Always $00
$06     2     Seq      Outer sequence (LE)
$08     4     SentID   (LE)
$0C     4     RcvdID   (LE)
$10     2     Data     Always $01C0
$12     1     Unused   0
$13     2     SendSeq  Inner sequence (BE)
$15     1     Magic    $04=Open, $00=Close
```

### Login Packet ($80 = 128 bytes)

```
Offset  Size  Field         Description
$00     4     Len           Always $80
$04     2     PktType       (LE)
$06     2     Seq           (LE)
$08     4     SentID        (LE)
$0C     4     RcvdID        (LE)
$10     4     PayloadSize   SwapLongWord($70) (BE)
$14     1     RequestReply  $01
$15     1     RequestType   $00
$16     2     InnerSeq      SwapWord(authSeq) (BE)
$18     2     UnusedB       0
$1A     2     TokRequest    Random 16-bit value
$1C     4     Token         0 (initial login)
$20     32    UnusedC       0
$40     16    Username      Encoded (see Password Encoding)
$50     16    Password      Encoded (see Password Encoding)
$60     16    ClientName    ASCII, null-padded (e.g. "TR4W")
$70     16    UnusedF       0
```

### Login Response ($60 = 96 bytes)

```
Offset  Size  Field         Description
$00-$0F       (header)      Standard 16-byte header
$10     4     PayloadSize   (BE)
$14     1     RequestReply
$15     1     RequestType
$16     2     InnerSeq      (BE)
$18     2     UnusedB
$1A     2     TokRequest
$1C     4     Token         *** SAVE THIS ***
$20     2     AuthStartID   *** SAVE THIS ***
$22     14    UnusedD
$30     4     Error         0=success, $FEFFFFFF=auth failed
$34     12    UnusedE
$40     16    Connection
$50     16    UnusedF
```

### Token Packet ($40 = 64 bytes)

```
Offset  Size  Field         Description
$00-$0F       (header)
$10     4     PayloadSize   (BE)
$14     1     RequestReply  $01
$15     1     RequestType   $02=ack, $05=renew
$16     2     InnerSeq      (BE)
$18     2     UnusedB
$1A     2     TokRequest
$1C     4     Token
$20     2     AuthStartID
$22     2     UnusedG2
$24     2     ResetCap      SwapWord($0798) (BE)
$26     1     UnusedG1
$27     2     CommonCap
$29     1     UnusedH
$2A     6     MacAddress
$30     4     Response
$34     12    UnusedE
```

### Status Packet ($50 = 80 bytes)

```
Offset  Size  Field         Description
$00-$0F       (header)
$10     4     PayloadSize   (BE)
$14-$1F       (auth fields)
$20-$2F       (MAC/GUID)
$30     4     Error         $FFFFFFFF = connection failed
$34     12    UnusedG
$40     1     Disc          $01 = disconnected/refused
$41     1     UnusedH
$42     2     CivPort       *** BIG-ENDIAN *** — CI-V UDP port
$44     2     UnusedI
$46     2     AudioPort
$48     7     UnusedJ
```

### ConnInfo / Stream Request ($90 = 144 bytes)

```
Offset  Size  Field         Description
$00-$0F       (header)
$10     4     PayloadSize   SwapLongWord($80) (BE)
$14     1     RequestReply  $01
$15     1     RequestType   $03
$16     2     InnerSeq      (BE)
$18     2     UnusedB
$1A     2     TokRequest
$1C     4     Token
$20     16    GUID/MAC
$30     16    UnusedAB
$40     32    RadioName     Copied from capabilities response
$60     16    Username      Encoded
$70     1     RxEnable      1
$71     1     TxEnable      0 (control only)
$72     1     RxCodec       $04 (LPCM)
$73     1     TxCodec       0
$74     4     RxSample      SwapLongWord(8000) (BE)
$78     4     TxSample      0
$7C     4     CivPort       SwapLongWord(your_local_civ_port) (BE)
$80     4     AudioPort     0
$84     4     TxBuffer      0
$88     1     Convert       1
$89     7     UnusedL       0
```

### Capabilities Packet ($42 = 66 byte header)

```
Offset  Size  Field         Description
$00-$0F       (header)
$10     4     PayloadSize   (BE)
$14-$1F       (auth fields)
$20     32    UnusedD
$40     2     NumRadios     SwapWord(count) (BE)
```

Followed by `NumRadios` entries of 102 ($66) bytes each:

```
Offset  Size  Field         Description
$00     7     UnusedE
$07     2     CommonCap     $8010 = uses MAC addressing
$09     1     Unused
$0A     6     MacAddress
$10     32    RadioName     Null-terminated ASCII (e.g. "IC-7760")
$30     32    AudioName
$50     2     ConnType
$52     1     CivAddress    *** CI-V address (e.g. $B2) ***
$53     2     RxSample
$55     2     TxSample
$57     1     EnableA
$58     1     EnableB
$59     1     EnableC
$5A     4     BaudRate      (BE)
$5E     2     CapF
$60     1     UnusedI
$61     2     CapG
$63     3     UnusedJ
```

---

## 9. Sequence Number Management

This is the single most error-prone aspect of the protocol. There are **three independent** sequence counters, plus a separate auth sequence and ping sequence.

### Counter Summary

| Counter | Socket | Initial Value | Byte Order | Packet Field |
|---------|--------|--------------|-----------|-------------|
| sendSeq | Control | 0 | Little-endian | Seq ($06) |
| civSeq | CI-V | 0 | Little-endian | Seq ($06) |
| civInnerSeq | CI-V | 0 | Big-endian | SendSeq ($13) |
| authSeq | Control | $30 | Big-endian | InnerSeq ($16) |
| pingSendSeq | Both | 0 | Little-endian | Seq ($06) |

### Pattern: Use-Then-Increment

For `civSeq` and `civInnerSeq`, use the **use-then-increment** pattern:

```
packet.Seq = civSeq        // Use current value
send(packet)
civSeq = civSeq + 1        // Increment AFTER send
```

> **QUIRK — AYT and AYR Sequences**: The initial "Are You There" on the control socket must be sent with Seq=0. The "Are You Ready" must be sent with Seq=1. This is NOT "increment before send" — it's the result of: AYT sends Seq=0, then sendSeq becomes 1, then AYR sends Seq=1.
>
> The same pattern applies on the CI-V socket: CI-V AYT sends Seq=0 (civSeq=0, then civSeq becomes 1), CI-V AYR sends Seq=1 (civSeq=1, NO increment after AYR — this matches wfview behavior).

> **QUIRK — Auth Inner Sequence**: The auth inner sequence starts at $30 and increments for each auth packet (login, token ack, stream request). It's stored big-endian in the InnerSeq field at offset $16.

> **COMMON BUG — Double Increment**: If your packet-building function increments the sequence AND your send function also increments it, you get double-increment. The radio sees sequence gaps and requests retransmits for "missing" packets that were never sent. Centralize the increment in ONE place.

### Verified Working Sequence (from pcap analysis)

```
Control Socket:
  AYT:      Seq=0   (sendSeq: 0→1)
  AYR:      Seq=1   (sendSeq: 1→2)
  Login:    Seq=2   (sendSeq: 2→3)
  TokenAck: Seq=3   (sendSeq: 3→4)
  ConnInfo: Seq=4   (sendSeq: 4→5)

CI-V Socket:
  AYT:      Seq=0   (civSeq: 0→1)
  AYR:      Seq=1   (civSeq stays at 1, no increment)
  Open:     Seq=1   (civSeq: 1→2)  ← Same as AYR! No increment between them.
  CivData:  Seq=2   (civSeq: 2→3)
```

> **QUIRK**: On the CI-V socket, AYR and Open use the SAME outer sequence (both Seq=1). This means civSeq is NOT incremented after sending AYR. Only Open (and subsequent CivData/Idle/Close) increment it. This was verified against wfview pcap captures.

---

## 10. Keepalives and Timers

| Timer | Interval | Purpose |
|-------|----------|---------|
| Ping | 500ms | Keepalive on control socket (bidirectional) |
| Idle | 100ms | Send idle data packet on CI-V socket if no other traffic |
| Token Renewal | 60,000ms | Renew authentication token |
| CI-V Watchdog | 500ms check, 2s threshold | Detect dead CI-V stream, re-send Open |
| AYT Retry | 500ms initial, exponential backoff to 5s | Connection establishment |
| Login Retry | 5,000ms | Retry login on "session busy" rejection |

### Ping Protocol

- Radio sends ping request (Reply=0) → respond immediately with Reply=1, swap SentID/RcvdID
- Client sends ping request (Reply=0) → radio responds with Reply=1
- Ping has its own sequence counter, separate from tracked packet sequences
- Carry over the Time field from the request into the response

> **QUIRK — Ping Address Filtering**: Only respond to pings addressed to YOUR session ID. On a busy network, you may receive pings intended for other sessions (audio, other clients). Check that RcvdID matches your myId before responding.

### CI-V Watchdog

If no CI-V data is received for 2 seconds while in Connected state, re-send the CI-V Open packet. This restarts the CI-V data stream without a full reconnection.

---

## 11. CI-V Command Framing

CI-V commands are wrapped in Data Packets (21-byte header + CI-V frame):

### CI-V Frame Format

```
FE FE <to_addr> <from_addr> <command> [sub_command] [data...] FD
```

- `FE FE` — preamble (always 2 bytes)
- `<to_addr>` — destination (radio CI-V address for commands, $00 for broadcast)
- `<from_addr>` — source (controller address: $E0 or $E1)
- `<command>` — CI-V command code
- `FD` — end marker

### CI-V Response Frame

Responses swap source/destination:
```
FE FE <ctrl_addr> <radio_addr> <command> [data...] FD
```

### ACK / NAK

- `FE FE <ctrl> <radio> FB FD` — ACK (command accepted)
- `FE FE <ctrl> <radio> FA FD` — NAK (command rejected)

### Extracting CI-V from UDP Packets

When receiving data on the CI-V socket:
1. Check packet length >= 21 (minimum data packet)
2. Search for `FE FE` byte pattern in raw packet data (after the 21-byte header)
3. Find matching `FD` after the `FE FE`
4. Extract bytes from `FE FE` to `FD` inclusive — this is one CI-V frame
5. Continue scanning for additional `FE FE` patterns — **a single UDP packet may contain multiple CI-V frames**

> **QUIRK — No Echo Over Network**: Unlike serial CI-V where your own transmitted command echoes back, network CI-V does NOT echo. You only receive responses and unsolicited transceive pushes. Do not implement echo filtering for network connections.

---

## 12. CI-V Commands for Contest Operation

### Frequency

| Function | Command | Data | Notes |
|----------|---------|------|-------|
| Read freq VFO A | $03 | — | Response: 5 BCD bytes (LSB first) |
| Set freq VFO A | $05 | 5 BCD bytes | LSB first |
| Read freq VFO B | $25 | — or $01 | IC-7760: requires sub-command $01 |

### BCD Frequency Encoding

Frequencies are 5 bytes of BCD, **least significant digit first**:

Example: 14,250,000 Hz = `00 00 25 41 00`
```
Byte 0: 1Hz,10Hz     → $00
Byte 1: 100Hz,1kHz   → $00
Byte 2: 10kHz,100kHz → $25  (250 kHz)
Byte 3: 1MHz,10MHz   → $41  (14 MHz)
Byte 4: 100MHz,GHz   → $00
```

### Mode

| Function | Command | Data | Notes |
|----------|---------|------|-------|
| Read mode VFO A | $04 | — | Response: mode byte + filter byte |
| Set mode VFO A | $06 | mode + filter | |
| Read mode VFO B | $26 | — or $01 | IC-7760: requires sub-command $01 |

### Mode Byte Values

| Mode | Hex Value | Decimal |
|------|-----------|---------|
| LSB | $00 | 0 |
| USB | $01 | 1 |
| AM | $02 | 2 |
| CW | $03 | 3 |
| RTTY (FSK) | $04 | 4 |
| FM | $05 | 5 |
| CW-R | $07 | 7 |
| RTTY-R (FSK-R) | $08 | 8 |
| PSK | $12 | 18 |
| PSK-R | $13 | 19 |

> **QUIRK — PSK Mode Values**: PSK mode is $12 (decimal 18), NOT $0C (decimal 12). It's easy to confuse hex and decimal here. The Icom CI-V manual uses hex notation; if you see "Mode: 18" in a debug log, that's decimal 18 = hex $12 = PSK mode.

### Filter Byte Values

| Filter | Value | Description |
|--------|-------|-------------|
| FIL1 | $01 | Widest |
| FIL2 | $02 | Medium |
| FIL3 | $03 | Narrowest |

### Other Essential Commands

| Function | Command | Sub-Cmd | Notes |
|----------|---------|---------|-------|
| Split on/off | $0F | — | Data: 0=off, 1=on |
| CW speed | $14 | $0C | 2 BCD bytes, 0-255 scale |
| S-meter | $15 | $02 | Response: 2 BCD bytes |
| Power meter | $15 | $11 | Response: 2 BCD bytes |
| Send CW text | $17 | $00 | Up to 30 ASCII chars |
| Stop CW | $17 | $FF | Abort CW sending |
| PTT status | $1C | $00 | Response: 0=RX, 1=TX |
| Data mode | $1A | $06 | See section 14 |
| RIT offset | $21 | $00 | See RIT section |
| RIT on/off | $21 | $01 | 0=off, 1=on |
| XIT on/off | $21 | $02 | 0=off, 1=on |
| Transceiver ID | $19 | $00 | Used for initialization |

### CW Speed Conversion (IC-7760)

The IC-7760 reports CW speed as a 0-255 BCD value, not direct WPM:

```
WPM = 6 + (bcd_value * 42 + 127) / 255    // BCD to WPM (integer division)
BCD_value = ((WPM - 6) * 255) / 42          // WPM to BCD
```

> **QUIRK — Firmware Bug**: IC-7760 sends value 250 ($02 $50) for 48 WPM instead of the expected 255 ($02 $55). This is a radio firmware bug, not a protocol issue.

### RIT/XIT (IC-7760)

The IC-7760 uses a **shared offset** for both RIT and XIT — a single value applied to whichever is active.

Read offset response format: `$21 $00 <bcd-high> <bcd-low> <sign>`
- Range: ±9999 Hz
- Sign byte: $00 = positive, non-zero = negative

---

## 13. Transceive (Push Updates)

When CI-V Transceive is enabled on the radio (menu setting), the radio pushes unsolicited changes to some — but NOT all — operating parameters when the user operates the front panel controls.

### What the radio pushes (confirmed via testing with IC-7610)

| CI-V Command | Parameter | Pushed? | Notes |
|-------------|-----------|---------|-------|
| $00 | VFO A frequency | **YES** | Pushed instantly on VFO knob turn |
| $01 | Operating mode | **YES** | Pushed instantly on mode change |
| $21 $00/$01/$02 | RIT/XIT state and offset | **NO** | Must poll |
| $0F | Split on/off | **NO** | Must poll |
| $1C $00 | TX/RX status (PTT) | **NO** | Must poll |
| $14 $0C | CW speed | Untested | Assumed NO — poll to be safe |
| $25/$26 | VFO B freq/mode | Untested | Not confirmed either way |
| $1A $06 | Data mode overlay | **NO** | See section 14 |

These arrive as broadcast CI-V frames (destination address = $00):
```
FE FE 00 <radio_addr> <command> <data...> FD
```

Your CI-V parser should accept packets addressed to both:
- Your controller address ($E0/$E1) — responses to your commands
- Broadcast address ($00) — unsolicited transceive pushes

> **CRITICAL DESIGN INSIGHT**: The radio only transceive-pushes frequency ($00) and mode ($01). Everything else — RIT, XIT, split, TX status, CW speed — must be explicitly polled. This was confirmed by testing with an IC-7610, and cross-validated against SDR-Control (a confirmed working reference implementation for IC-7610), which also detects RIT/XIT/split changes from the front panel, confirming it polls those states.

> **QUIRK — $1A $06 Not Pushed**: When the user activates Data Mode (USB-D1, LSB-D1, etc.) on the radio's front panel, the radio sends a $01 transceive push with the base mode (USB or LSB) but does **NOT** send a $1A $06 push for the data mode overlay. This means your software will see "USB" but not know that data mode is active. See section 14 for the fix.

### Recommended Polling Architecture

Because only frequency and mode are pushed, a selective polling strategy is required:

**Do NOT poll:**
- VFO A frequency ($03) — arrives via $00 transceive push
- Operating mode ($04) — arrives via $01 transceive push

**Must poll (every 1 second):**
- RIT state and offset ($21 $00, $21 $01)
- XIT state ($21 $02)
- Split on/off ($0F)
- TX/RX status ($1C $00)

**Query once at connection (after $19 response):**
- All of the above, plus VFO A/B frequency, mode, CW speed

> **QUIRK — Data Mode Flicker Bug**: Polling $04 (mode query) causes a subtle but serious bug. The poll response returns the base mode (e.g., USB), which overwrites the current DIGI state in your software. Before the follow-up $1A $06 query can re-detect data mode, the UI briefly flickers to "SSB". The fix: do NOT poll $04 — rely on the $01 transceive push for mode changes, and only query $1A $06 when a $01 push arrives with a voice mode (USB/LSB/FM/AM). This is why selective polling matters — you cannot just poll everything.

> **SDR-Control Reference**: SDR-Control for Icom (a confirmed working commercial implementation for IC-7610) does NOT poll frequency or mode — it relies entirely on transceive pushes for those. It DOES detect RIT/XIT/split changes from the front panel, confirming it polls those states on a timer.

---

## 14. Data Mode Overlay ($1A $06)

Many modern Icom radios support a "Data Mode" overlay that modifies USB/LSB into USB-D/LSB-D (for digital modes like FT8, RTTY via soundcard, etc.). This is controlled via CI-V command $1A sub-command $06.

### Query Data Mode

```
TX: FE FE <radio> <ctrl> 1A 06 FD
RX: FE FE <ctrl> <radio> 1A 06 <dm> <filter> FD
```

Where `<dm>`:
- $00 = Data mode OFF (normal USB/LSB)
- $01 = Data mode D1 (DATA 1)
- $02 = Data mode D2 (DATA 2)
- $03 = Data mode D3 (DATA 3)

All non-zero values mean "data mode active" for contest logging purposes.

### Set Data Mode

```
TX: FE FE <radio> <ctrl> 1A 06 <dm> <filter> FD
```

### The Transceive Gap

> **CRITICAL QUIRK**: The radio does NOT transceive-push $1A $06 changes. When the user switches from LSB to USB-D1 on the front panel:
>
> 1. Radio pushes: `FE FE 00 B2 01 01 01 FD` (command $01, mode=USB, filter=1)
> 2. Radio does NOT push: any $1A $06 frame
>
> Your software sees USB and displays "SSB" — it never learns about the data mode overlay.
>
> **Fix**: Whenever you receive a $01 transceive push with a voice mode — USB ($01), LSB ($00), FM ($05), or AM ($02) — immediately query the data mode:
> ```
> TX: FE FE <radio> <ctrl> 1A 06 FD
> ```
> The response will tell you if data mode is active. If so, override the displayed mode to "DATA" or "DIGITAL".
>
> This query adds minimal overhead (one 8-byte CI-V frame) and only triggers on voice mode changes, not on every transceive push.
>
> **Race condition**: If the user quickly switches from a data overlay mode (e.g., USB-D1) to a non-voice mode (e.g., RTTY), the $1A $06 response from the previous query may arrive after the mode has already changed to RTTY. If you blindly apply "data mode ON", you'll overwrite the correct RTTY mode with DATA. **Fix**: Only apply "data mode ON" from a $1A $06 response if the current mode is still a voice mode (USB/LSB/FM/AM). If the mode has already changed to CW/FSK/PSK, discard the stale response.
>
> **FM-D and AM-D**: The IC-7760 (and other modern Icom radios) supports data mode overlay on FM and AM in addition to USB/LSB. Query $1A $06 after ALL four voice modes, not just USB/LSB.
>
> **Verification**: Analysis of wfview pcap captures against both IC-7760 (310 CI-V packets) and IC-9700 (927 CI-V packets) confirmed that wfview does NOT query $1A $06. wfview only sends $03 (freq), $04 (mode), and $19 $00 (transceiver ID). It has the same blind spot and cannot detect front-panel data mode changes.

---

## 15. Disconnection Protocol

Proper disconnection is **critical**. If you don't disconnect cleanly, the radio retains the "connected" state and will refuse new connections until its session timeout expires (which can be minutes).

### Disconnect Sequence

1. Send CI-V Close (OpenClose packet with magic=$00) on CI-V socket
2. Send Disconnect (control packet type $05) on CI-V socket
3. Send Disconnect (control packet type $05) on control socket
4. **Wait 100ms** before closing sockets
5. Close both sockets

> **CRITICAL QUIRK**: The 100ms delay in step 4 is essential. UDP `sendto()` is asynchronous — the data is queued in the OS network stack but may not have been transmitted yet when the function returns. If you close the socket immediately, the disconnect packets may be silently discarded. The radio never receives them and stays in "connected" state, blocking all reconnection attempts.

### Program Exit

When your program exits, you MUST disconnect the radio BEFORE calling WSACleanup (Windows) or closing the socket library. If WSACleanup runs first, the sockets are already invalid and no disconnect packets can be sent.

```
// CORRECT order:
radio1.Disconnect()     // Sends disconnect packets
radio2.Disconnect()     // Sends disconnect packets
WSACleanup()            // Clean up socket library

// WRONG order (radio stays connected):
WSACleanup()            // Kills sockets!
radio1.Disconnect()     // Too late — sockets are dead
```

---

## 16. Password Encoding

Icom uses a substitution cipher for username/password encoding. This is NOT encryption — it's trivially reversible obfuscation.

### Algorithm

```
For each character at position i (0-based):
  p = ascii_value + i
  if p > 126:
    p = 32 + (p mod 127)
  encoded_byte = SUBSTITUTION_TABLE[p]
```

### Substitution Table (128 bytes)

```
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
47 5D 4C 42 66 20 23 46 4E 57 45 3D 67 76 60 41
62 39 59 2D 68 7E 7C 65 7D 49 29 72 73 78 21 6E
5A 5E 4A 3E 71 2C 2A 54 3C 3A 63 4F 43 75 27 79
5B 35 70 48 6B 56 6F 34 32 6C 30 61 6D 7B 2F 4B
64 38 2B 2E 50 40 3F 55 33 37 25 77 24 26 74 6A
28 53 4D 69 22 5C 44 31 36 58 3B 7A 51 5F 52 00
```

Output is always 16 bytes, zero-padded if the input is shorter than 16 characters.

### Example

Username "NY4I" encoded:
- 'N' (78) + 0 = 78 → table[78] = $4A
- 'Y' (89) + 1 = 90 → table[90] = $6C
- '4' (52) + 2 = 54 → table[54] = $6F
- 'I' (73) + 3 = 76 → table[76] = $26
- Result: $4A $6C $6F $26 $00 $00 ... (zero-padded to 16 bytes)

---

## 17. Broadcast Discovery

To find Icom radios on the local network without knowing their IP:

1. Create a UDP socket, bind to any local port
2. For each network interface, send an "Are You There" (type $03) control packet to the subnet broadcast address on port 50001
   - SentID = your calculated ID
   - RcvdID = 0
3. Listen for 3 seconds for "I Am Here" (type $04) responses
4. Each response comes from a radio — the UDP source address is the radio's IP
5. No authentication is needed for discovery

---

## 18. Radio-Specific Notes

### IC-7760

The IC-7760 has the most protocol quirks of any supported radio:

- **Controller address $E1** (all other radios use $E0)
- **VFO B sub-command**: Commands $25 and $26 require sub-command byte $01. Without it, the commands are ignored.
- **Shared RIT/XIT offset**: Single offset value shared between RIT and XIT (only one can be active)
- **CW speed BCD**: Uses 0-255 BCD scale, not direct WPM
- **Firmware bug**: CW speed 48 WPM reports 250 instead of 255

### IC-9700

- May report CI-V port as 0 in the status packet → use 50002 as fallback
- Standard VFO B format (no sub-command needed)
- Three bands (144/430/1296 MHz) — each band is essentially a separate receiver

### IC-705

- Can connect via WiFi — may have higher latency than Ethernet
- Battery-powered — consider power-saving implications for polling frequency

---

## 19. Implementation Quirks and Gotchas

This section collects all the non-obvious behaviors discovered during implementation and testing.

### Quirk 1: PktType for Auth Packets

All outgoing auth packets (login, token ack, stream request) use `PktType = $0000` (ICOM_PKT_DATA), NOT `PktType = $0001` (ICOM_PKT_AUTH). This was confirmed from wfview pcap analysis. The radio's responses use PktType $0001, but your outgoing packets must use $0000.

### Quirk 2: Auth Inner Sequence

Auth packets have their own inner sequence counter starting at $30 (decimal 48). It increments per auth packet and is stored big-endian in the InnerSeq field at offset $16. This is independent of the CI-V inner sequence.

### Quirk 3: 24-Byte Rejection

See section 6. The radio can send a 24-byte "session busy" packet instead of a proper login response. This is not an error — it means a stale session exists. Retry after a few seconds.

### Quirk 4: DataLen Byte Order

The `DataLen` field in data packets (offset $11) is **little-endian**, unlike most payload fields which are big-endian. If you accidentally byte-swap this field, the radio reads a wildly wrong length (e.g., 2816 instead of 11) and NAKs all write commands. This is especially insidious because read commands (which have no data payload) still work — only write commands fail.

### Quirk 5: CI-V Open Delay

After sending the CI-V Open packet, wait ~200ms before sending CI-V commands. The radio acknowledges the Open immediately but needs processing time. Commands sent too early are acknowledged but produce no data responses.

### Quirk 6: GetIsConnected Must Cover All States

If your polling loop checks `IsConnected` to decide whether to poll, make sure `IsConnected` returns true for ALL non-disconnected states (not just the final "Connected" state). Otherwise the polling loop may try to reconnect while the handshake is still in progress, creating a reconnection loop.

### Quirk 7: Indy SendBuffer Deadlock

If using Indy networking library (Delphi), calling `TIdUDPServer.SendBuffer` from the main thread can deadlock due to Indy's internal threading. Use raw WinSock `sendto()` instead for sending UDP packets.

### Quirk 8: Multiple CI-V Frames Per Packet

When the radio sends transceive data (e.g., user is turning the VFO knob quickly), it may batch multiple CI-V frames into a single UDP data packet. Your CI-V extraction code must loop and find ALL `FE FE...FD` frames in the packet, not just the first one.

### Quirk 9: CI-V Transceive Must Be Enabled

The radio will only push frequency/mode changes if "CI-V Transceive" is enabled in the radio's menu. This is a user setting, not something you can enable via the protocol (sending the CI-V transceive-on command when it's already on can actually disrupt the transceive mechanism on some firmware versions). Check the setting via `$1A $05 $01 $50` and warn the user if it's off.

### Quirk 10: Use Same SentID on Both Sockets

Use the SAME `myId` (SentID) for packets on both the control socket and the CI-V socket. Some implementations tried using a different ID for the CI-V socket, but this is incorrect — wfview uses the same ID for both. The REMOTE ID is different between sockets (the radio assigns different IDs for control vs CI-V), but YOUR ID stays the same.

---

## 20. Debugging Tips

### Essential Tool: Wireshark

Capture on the network interface connected to the radio, filter by `udp.port == 50001 || udp.port == 50002`.

### Packet Identification

Quick way to identify packet types by size:
- 16 bytes ($10): Control packet (AYT/IAH/Disconnect/AYR)
- 21 bytes ($15): Ping or minimal data packet
- 22 bytes ($16): Open/Close
- 64 bytes ($40): Token
- 80 bytes ($50): Status
- 96 bytes ($60): Login response
- 128 bytes ($80): Login
- 144 bytes ($90): ConnInfo/Stream request
- Variable: Capabilities or CI-V data

### Common Failure Modes

| Symptom | Likely Cause |
|---------|-------------|
| No response to AYT | Wrong IP/port, firewall blocking, radio not in network mode |
| Login gets 24-byte response | Stale session — previous client didn't disconnect cleanly |
| Login response Error=$FEFFFFFF | Wrong username/password |
| CI-V commands get ACK but no data | Sent commands too soon after CI-V Open (need 200ms delay) |
| CI-V write commands get NAK | DataLen byte order wrong (should be little-endian) |
| Radio requests retransmits | Double sequence increment |
| Can't reconnect after restart | Didn't send disconnect packets on exit |
| Mode shows USB instead of USB-D | $1A $06 not queried after transceive mode push |
| Mode flickers between DIGI and SSB | Polling $04 overwrites DIGI before $1A $06 response arrives — remove $04 from polling |
| RIT/XIT/Split not updating from front panel | These are NOT transceive-pushed — must poll them |
| Responds to wrong pings | Not filtering pings by session ID |

### Log Everything

During development, log every packet sent and received with:
- Packet type and size
- Sequence numbers (both outer and inner)
- SentID and RcvdID
- Full hex dump for auth packets
- CI-V frame contents for data packets

### Compare with wfview

wfview is the most mature open-source implementation. When something doesn't work:
1. Capture a working wfview session with Wireshark
2. Compare your packet sequences side-by-side
3. Look for differences in sequence numbers, byte order, packet sizes, field values

---

## References

- wfview project (open source): https://gitlab.com/eliggett/wfview
- Icom CI-V Reference Manuals (per radio model): Available from Icom's website
- TR4W implementation (Delphi 7): https://github.com/n4af/TR4W
- TR4QT implementation (Qt/C++): https://github.com/n4af/TR4QT
