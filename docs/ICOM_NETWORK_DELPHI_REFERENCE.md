# Icom Network Radio Control Protocol Reference

## Purpose

This document describes Icom's proprietary UDP network protocol for controlling Icom radios over Ethernet/WiFi. It covers the full connection lifecycle, packet structures, CI-V command framing, authentication, and radio-specific quirks. Written for implementation in Delphi 7 (or any language with UDP socket support).

**Source**: Reverse-engineered from working implementation in TR4QT (Qt/C++) and wfview, verified against IC-7760 and IC-9700 hardware.

---

## Supported Radios

Network-capable Icom radios:
- IC-905
- IC-9700
- IC-7850 / IC-7851
- IC-7760
- IC-7610
- IC-7600
- IC-7300MK2 (original IC-7300 is serial-only, NOT supported)
- IC-705
- IC-R8600

---

## Transport Layer

- **Protocol**: UDP (not TCP)
- **Control Port**: 50001 (configurable on radio)
- **CI-V Data Port**: Reported by radio during handshake (typically 50002)
- **Two separate UDP sockets required**: one for control/auth, one for CI-V data
- **IPv4 only** (no IPv6 support)
- **No encryption** - password encoding is simple substitution cipher (obfuscation only)
- **No audio** - this protocol covers control commands only

---

## Byte Order

- **Packet header fields** (len, type, seq, sentid, rcvdid): **Little-endian**
- **Payload fields** (payloadsize, innerseq, civport, rxsample, etc.): **Big-endian**
- **CI-V data**: Raw bytes as documented in Icom CI-V manuals

This mixed endianness is critical. Getting it wrong causes silent failures.

---

## Connection Flow (8-Step Handshake)

```
Step  Direction    Packet Type    Size    Description
----  ---------    -----------    ----    -----------
1     Client→Radio  0x03          0x10    "Are You There" (control socket)
2     Radio→Client  0x04          0x10    "I Am Here" (provides radio's sentid)
3     Client→Radio  0x06          0x10    "Are You Ready" (seq=1)
4     Radio→Client  0x06          0x10    "I Am Ready"
5     Client→Radio  login_packet  0x80    Login (encoded username/password)
6     Radio→Client  login_resp    0x60    Login response (token)
7     Client→Radio  token_packet  0x40    Token acknowledgment (magic=0x02)
      Radio→Client  capabilities  var     Radio list (capabilities packet)
8     Client→Radio  conninfo      0x90    Stream request (requests CI-V port)
      Radio→Client  status_packet 0x50    Stream info (CI-V port number)
```

After step 8, the CI-V data socket handshake begins:

```
Step  Direction    Packet Type    Size    Description
----  ---------    -----------    ----    -----------
9     Client→Radio  0x03          0x10    "Are You There" (CI-V socket, rcvdid=0)
10    Radio→Client  0x04          0x10    "I Am Here" (CI-V socket, different sentid!)
11    Client→Radio  0x06          0x10    "Are You Ready" (CI-V socket)
12    Radio→Client  0x06          0x10    "I Am Ready" (CI-V socket)
13    Client→Radio  openclose     0x16    CI-V Open (magic=0x04)
      --> CI-V commands can now be sent/received
```

**CRITICAL**: The CI-V socket has a DIFFERENT remote ID (`civRemoteId`) than the control socket (`remoteId`). You must track both separately.

---

## Packet Structures

All packets are packed (no alignment padding). In Delphi 7, use `packed record`.

### Control Packet (0x10 = 16 bytes)

Used for: Are You There (0x03), I Am Here (0x04), Disconnect (0x05), Are You Ready / I Am Ready (0x06)

```pascal
TControlPacket = packed record
  Len:      LongWord;   // $00 - Always $10 (16)
  PktType:  Word;       // $04 - Packet type
  Seq:      Word;       // $06 - Sequence number
  SentID:   LongWord;   // $08 - Sender's ID
  RcvdID:   LongWord;   // $0C - Receiver's ID
end;
```

### Ping Packet (0x15 = 21 bytes)

```pascal
TPingPacket = packed record
  Len:      LongWord;   // $00 - Always $15 (21)
  PktType:  Word;       // $04 - Always $07
  Seq:      Word;       // $06 - Ping sequence number
  SentID:   LongWord;   // $08
  RcvdID:   LongWord;   // $0C
  Reply:    Byte;       // $10 - 0=request, 1=response
  Time:     LongWord;   // $11 - Uptime in ms
end;
```

### Data Packet Header (0x15 = 21 bytes + CI-V data)

CI-V commands are wrapped in this header:

```pascal
TDataPacket = packed record
  Len:      LongWord;   // $00 - Total packet length (header + CI-V data)
  PktType:  Word;       // $04 - Always $00
  Seq:      Word;       // $06 - Outer UDP sequence number
  SentID:   LongWord;   // $08
  RcvdID:   LongWord;   // $0C
  Reply:    Byte;       // $10 - $C1 for data
  DataLen:  Word;       // $11 - Length of CI-V data following this header
  SendSeq:  Word;       // $13 - Inner CI-V stream sequence (big-endian!)
  // Followed by DataLen bytes of CI-V data
end;
```

### Open/Close Packet (0x16 = 22 bytes)

Opens or closes the CI-V data stream:

```pascal
TOpenClosePacket = packed record
  Len:      LongWord;   // $00 - Always $16 (22)
  PktType:  Word;       // $04 - Always $00
  Seq:      Word;       // $06 - Outer sequence
  SentID:   LongWord;   // $08
  RcvdID:   LongWord;   // $0C
  Data:     Word;       // $10 - Always $01C0
  Unused:   Byte;       // $12
  SendSeq:  Word;       // $13 - Inner sequence (big-endian!)
  Magic:    Byte;       // $15 - $04=Open, $00=Close
end;
```

### Login Packet (0x80 = 128 bytes)

```pascal
TLoginPacket = packed record
  Len:          LongWord;      // $00 - Always $80 (128)
  PktType:      Word;          // $04
  Seq:          Word;          // $06
  SentID:       LongWord;      // $08
  RcvdID:       LongWord;      // $0C
  PayloadSize:  LongWord;      // $10 - Big-endian! Value = $80 - $10 = $70
  RequestReply: Byte;          // $14 - Always $01
  RequestType:  Byte;          // $15 - Always $00
  InnerSeq:     Word;          // $16 - Big-endian! Auth sequence
  UnusedB:      array[0..1] of Byte;  // $18
  TokRequest:   Word;          // $1A - Random token request ID
  Token:        LongWord;      // $1C - 0 for initial login
  UnusedC:      array[0..31] of Byte; // $20
  Username:     array[0..15] of Byte; // $40 - Encoded username
  Password:     array[0..15] of Byte; // $50 - Encoded password
  ClientName:   array[0..15] of Byte; // $60 - ASCII client name (e.g. "TR4QT")
  UnusedF:      array[0..15] of Byte; // $70
end;
```

### Login Response Packet (0x60 = 96 bytes)

```pascal
TLoginResponsePacket = packed record
  Len:          LongWord;      // $00 - Always $60 (96)
  PktType:      Word;          // $04
  Seq:          Word;          // $06
  SentID:       LongWord;      // $08
  RcvdID:       LongWord;      // $0C
  PayloadSize:  LongWord;      // $10 - Big-endian
  RequestReply: Byte;          // $14
  RequestType:  Byte;          // $15
  InnerSeq:     Word;          // $16 - Big-endian
  UnusedB:      array[0..1] of Byte;  // $18
  TokRequest:   Word;          // $1A
  Token:        LongWord;      // $1C - THE TOKEN (save this!)
  AuthStartID:  Word;          // $20
  UnusedD:      array[0..13] of Byte; // $22
  Error:        LongWord;      // $30 - $FEFFFFFF = auth failed, 0 = success
  UnusedE:      array[0..11] of Byte; // $34
  Connection:   array[0..15] of Byte; // $40
  UnusedF:      array[0..15] of Byte; // $50
end;
```

**Authentication failure**: Error = `$FEFFFFFF` means invalid username/password.

### Token Packet (0x40 = 64 bytes)

Used for token acknowledgment and renewal:

```pascal
TTokenPacket = packed record
  Len:          LongWord;      // $00 - Always $40 (64)
  PktType:      Word;          // $04
  Seq:          Word;          // $06
  SentID:       LongWord;      // $08
  RcvdID:       LongWord;      // $0C
  PayloadSize:  LongWord;      // $10 - Big-endian
  RequestReply: Byte;          // $14 - $01
  RequestType:  Byte;          // $15 - $02=ack, $05=renew
  InnerSeq:     Word;          // $16 - Big-endian
  UnusedB:      array[0..1] of Byte;  // $18
  TokRequest:   Word;          // $1A
  Token:        LongWord;      // $1C
  // $20-$2F: MAC/GUID union (see below)
  AuthStartID:  Word;          // $20
  UnusedG2:     array[0..1] of Byte;  // $22
  ResetCap:     Word;          // $24 - Big-endian, send $0798
  UnusedG1:     Byte;          // $26
  CommonCap:    Word;          // $27
  UnusedH:      Byte;          // $29
  MacAddress:   array[0..5] of Byte;  // $2A
  Response:     LongWord;      // $30
  UnusedE:      array[0..11] of Byte; // $34
end;
```

### Status Packet (0x50 = 80 bytes)

Received after stream request, contains CI-V port:

```pascal
TStatusPacket = packed record
  Len:          LongWord;      // $00 - Always $50 (80)
  PktType:      Word;          // $04
  Seq:          Word;          // $06
  SentID:       LongWord;      // $08
  RcvdID:       LongWord;      // $0C
  PayloadSize:  LongWord;      // $10 - Big-endian
  RequestReply: Byte;          // $14
  RequestType:  Byte;          // $15
  InnerSeq:     Word;          // $16 - Big-endian
  UnusedB:      array[0..1] of Byte;  // $18
  TokRequest:   Word;          // $1A
  Token:        LongWord;      // $1C
  // MAC/GUID fields at $20-$2F
  AuthStartID:  Word;          // $20
  UnusedD:      array[0..4] of Byte;  // $22
  CommonCap:    Word;          // $27
  UnusedE:      Byte;          // $29
  MacAddress:   array[0..5] of Byte;  // $2A
  Error:        LongWord;      // $30 - $FFFFFFFF = connection failed
  UnusedG:      array[0..11] of Byte; // $34
  Disc:         Byte;          // $40 - $01 = disconnected
  UnusedH:      Byte;          // $41
  CivPort:      Word;          // $42 - Big-endian! CI-V UDP port
  UnusedI:      Word;          // $44
  AudioPort:    Word;          // $46
  UnusedJ:      array[0..6] of Byte;  // $48
end;
```

### Conninfo / Stream Request Packet (0x90 = 144 bytes)

Sent to request CI-V data stream:

```pascal
TConnInfoPacket = packed record
  Len:          LongWord;      // $00 - Always $90 (144)
  PktType:      Word;          // $04
  Seq:          Word;          // $06
  SentID:       LongWord;      // $08
  RcvdID:       LongWord;      // $0C
  PayloadSize:  LongWord;      // $10 - Big-endian ($90 - $10 = $80)
  RequestReply: Byte;          // $14 - $01
  RequestType:  Byte;          // $15 - $03
  InnerSeq:     Word;          // $16 - Big-endian
  UnusedB:      array[0..1] of Byte;  // $18
  TokRequest:   Word;          // $1A
  Token:        LongWord;      // $1C
  // $20-$2F: MAC or GUID
  GUID:         array[0..15] of Byte; // $20 (or MAC at $2A with CommonCap at $27)
  UnusedAB:     array[0..15] of Byte; // $30
  RadioName:    array[0..31] of Byte; // $40 - Radio name from capabilities
  Username:     array[0..15] of Byte; // $60 - Encoded username
  RxEnable:     Byte;          // $70 - 1 = enable
  TxEnable:     Byte;          // $71 - 0 = disable (control only)
  RxCodec:      Byte;          // $72 - $04 = LPCM
  TxCodec:      Byte;          // $73 - 0
  RxSample:     LongWord;      // $74 - Big-endian, 8000
  TxSample:     LongWord;      // $78 - 0
  CivPort:      LongWord;      // $7C - Big-endian, YOUR local CI-V port
  AudioPort:    LongWord;      // $80 - 0
  TxBuffer:     LongWord;      // $84 - 0
  Convert:      Byte;          // $88 - 1
  UnusedL:      array[0..6] of Byte;  // $89
end;
```

### Capabilities Packet (0x42 header + N * 0x66 radio entries)

```pascal
TCapabilitiesPacket = packed record
  Len:          LongWord;      // $00
  PktType:      Word;          // $04
  Seq:          Word;          // $06
  SentID:       LongWord;      // $08
  RcvdID:       LongWord;      // $0C
  PayloadSize:  LongWord;      // $10 - Big-endian
  RequestReply: Byte;          // $14
  RequestType:  Byte;          // $15
  InnerSeq:     Word;          // $16 - Big-endian
  UnusedB:      array[0..1] of Byte;  // $18
  TokRequest:   Word;          // $1A
  Token:        LongWord;      // $1C
  UnusedD:      array[0..31] of Byte; // $20
  NumRadios:    Word;          // $40 - Big-endian, number of radio entries
  // Followed by NumRadios * TRadioCapPacket
end;

TRadioCapPacket = packed record   // 0x66 = 102 bytes each
  // $00-$0F: GUID or MAC union
  UnusedE:      array[0..6] of Byte;  // $00
  CommonCap:    Word;          // $07 - $8010 = uses MAC, else uses GUID
  Unused:       Byte;          // $09
  MacAddress:   array[0..5] of Byte;  // $0A
  RadioName:    array[0..31] of Byte; // $10 - e.g. "IC-7760" null-terminated
  AudioName:    array[0..31] of Byte; // $30
  ConnType:     Word;          // $50
  CivAddress:   Byte;          // $52 - CI-V address (e.g. $B2 for IC-7760)
  RxSample:     Word;          // $53
  TxSample:     Word;          // $55
  EnableA:      Byte;          // $57
  EnableB:      Byte;          // $58
  EnableC:      Byte;          // $59
  BaudRate:     LongWord;      // $5A - Big-endian
  CapF:         Word;          // $5E
  UnusedI:      Byte;          // $60
  CapG:         Word;          // $61
  UnusedJ:      array[0..2] of Byte;  // $63
end;
```

---

## Password Encoding

Icom uses a simple substitution cipher for username/password encoding. This is NOT encryption.

```pascal
procedure IcomPasscode(const Input: string; var Output: array of Byte);
const
  Sequence: array[0..127] of Byte = (
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    $47,$5D,$4C,$42,$66,$20,$23,$46,$4E,$57,$45,$3D,$67,$76,$60,$41,
    $62,$39,$59,$2D,$68,$7E,$7C,$65,$7D,$49,$29,$72,$73,$78,$21,$6E,
    $5A,$5E,$4A,$3E,$71,$2C,$2A,$54,$3C,$3A,$63,$4F,$43,$75,$27,$79,
    $5B,$35,$70,$48,$6B,$56,$6F,$34,$32,$6C,$30,$61,$6D,$7B,$2F,$4B,
    $64,$38,$2B,$2E,$50,$40,$3F,$55,$33,$37,$25,$77,$24,$26,$74,$6A,
    $28,$53,$4D,$69,$22,$5C,$44,$31,$36,$58,$3B,$7A,$51,$5F,$52,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  );
var
  I, P: Integer;
begin
  FillChar(Output, 16, 0);
  for I := 1 to Min(Length(Input), 16) do
  begin
    P := Ord(Input[I]) + (I - 1);  // Delphi strings are 1-based
    if P > 126 then
      P := 32 + (P mod 127);
    Output[I - 1] := Sequence[P];
  end;
end;
```

---

## Client ID Generation

The client ID (`myId`) is computed from local IP and socket port:

```pascal
function CalculateMyId(LocalIP: LongWord; LocalPort: Word): LongWord;
begin
  // LocalIP is in host byte order (e.g., 192.168.1.100 = $C0A80164)
  Result := ((LocalIP shr 8) and $FF) shl 24   // 3rd octet
         or ((LocalIP) and $FF) shl 16          // 4th octet
         or (LocalPort and $FFFF);              // local port
end;
```

---

## Sequence Number Management

**CRITICAL** - Getting this wrong causes the radio to request retransmits or ignore commands.

### Three Independent Sequence Counters

| Counter | Socket | Start | Scope | Endianness |
|---------|--------|-------|-------|------------|
| `sendSeq` (control outer) | Control | 1 | Per UDP packet on control socket | Little-endian (in Seq field) |
| `civSeq` (CI-V outer) | CI-V | 1 | Per UDP packet on CI-V socket | Little-endian (in Seq field) |
| `civInnerSeq` (CI-V inner) | CI-V | 0 | Per CI-V stream command | Big-endian (in SendSeq field) |

### Rules

1. **Outer sequences** (`sendSeq`, `civSeq`): Increment ONCE per UDP packet sent. Stored in the `Seq` field at offset `$06`. Little-endian.
2. **Inner sequence** (`civInnerSeq`): Increment once per CI-V command or open/close. Stored in the `SendSeq` field at offset `$13`. **Big-endian**.
3. **Reset CI-V sequences** when opening a new CI-V connection: `civSeq := 1`, `civInnerSeq := 0`.
4. **Auth sequence** (`authSeq`): Starts at `$30`, increments per auth-related packet (login, token, stream request). Stored in `InnerSeq` at offset `$16`. **Big-endian**.
5. **Common bug**: Incrementing outer sequence in BOTH the packet-building function AND the send function causes double-increment. The radio sees gaps and requests retransmits for "missing" packets.

---

## Timers and Keepalives

| Timer | Interval | Purpose |
|-------|----------|---------|
| Are You There | 500ms initial, exponential backoff to 5000ms | Connection probe (max 10 retries) |
| Ping | 500ms | Keepalive on control socket |
| Idle | 100ms | Send idle packet if no other traffic |
| Token Renewal | 60,000ms (60s) | Renew authentication token |
| Retransmit Check | 100ms | Check for missing packets needing retransmit |
| CI-V Watchdog | 500ms | Detect CI-V data timeout (2s threshold) |

### Ping Protocol

- Radio sends ping with `Reply = 0` → respond with `Reply = 1`, swap SentID/RcvdID
- Client sends ping with `Reply = 0` → radio responds with `Reply = 1`
- Ping uses its own sequence counter (`pingSendSeq`), separate from tracked packets

---

## CI-V Command Format

Once the CI-V stream is open, commands follow standard Icom CI-V format wrapped in the data packet header:

### CI-V Frame

```
FE FE <radio_addr> <ctrl_addr> <command> [sub_command] [data...] FD
```

- `FE FE` - Preamble (2 bytes, always)
- `<radio_addr>` - Radio's CI-V address (from capabilities, e.g., `$B2` for IC-7760, `$A2` for IC-9700)
- `<ctrl_addr>` - Controller address (`$E0` for most radios, `$E1` for IC-7760)
- `<command>` - CI-V command code
- `[sub_command]` - Optional sub-command
- `[data...]` - Optional data (BCD-encoded for frequencies)
- `FD` - End marker

### CI-V Response Frame

```
FE FE <ctrl_addr> <radio_addr> <command> [data...] FD
```

Note: In responses, the source/destination are **swapped** compared to the command.

### ACK/NAK

- `FE FE <ctrl_addr> <radio_addr> FB FD` = ACK (command accepted)
- `FE FE <ctrl_addr> <radio_addr> FA FD` = NAK (command rejected)

---

## CI-V Command Reference

### Essential Commands for Contest Operation

| Function | Command | Sub-Cmd | Data | Notes |
|----------|---------|---------|------|-------|
| Get Frequency (VFO A) | `$03` | - | - | Response: 5 BCD bytes (LSB first) |
| Get Mode (VFO A) | `$04` | - | - | Response: mode byte + filter byte |
| Set Frequency (VFO A) | `$05` | - | 5 BCD bytes | LSB first |
| Set Mode (VFO A) | `$06` | - | mode + filter | |
| Get Split | `$0F` | - | - | Response: 1 byte (0=off, 1=on) |
| Set Split | `$0F` | - | 1 byte | 0=off, 1=on |
| Set CW Keyer Speed | `$14` | `$0C` | 2 BCD bytes | See BCD-to-WPM conversion below |
| Read S-Meter | `$15` | `$02` | - | Response: 2 bytes (0-255 scale) |
| Send CW Text | `$17` | - | ASCII chars | Up to 30 characters |
| Get TX Status (PTT) | `$1C` | `$00` | - | Response: 1 byte (0=RX, 1=TX) |
| RIT/XIT Offset | `$21` | `$00` | 4 bytes | See RIT section below |
| RIT On/Off | `$21` | `$01` | 1 byte | 0=off, 1=on |
| XIT On/Off | `$21` | `$02` | 1 byte | 0=off, 1=on |
| Get VFO B Frequency | `$25` | varies | - | See VFO B section |
| Get VFO B Mode | `$26` | varies | - | See VFO B section |

### Mode Byte Values

| Mode | Value |
|------|-------|
| LSB | $00 |
| USB | $01 |
| AM | $02 |
| CW | $03 |
| RTTY | $04 |
| FM | $05 |
| CW-R | $07 |
| RTTY-R | $08 |
| PSK | $12 |
| PSK-R | $13 |

### Filter Byte Values

| Filter | Value |
|--------|-------|
| FIL1 (widest) | $01 |
| FIL2 | $02 |
| FIL3 (narrowest) | $03 |

---

## BCD Frequency Encoding

Frequencies are encoded as 5 bytes of BCD (Binary Coded Decimal), **LSB first** (1 Hz digit first).

### Encoding (Hz to BCD)

Example: 14,250,000 Hz = 14.250 MHz

```
Digit pairs (from Hz, LSB first):
  00 00 25 41 00
  ^  ^  ^  ^  ^
  |  |  |  |  +-- 100MHz, 10MHz
  |  |  |  +-- 1MHz, 100kHz
  |  |  +-- 10kHz, 1kHz
  |  +-- 100Hz, 10Hz
  +-- 1Hz, 0.1Hz (usually 00)
```

```pascal
procedure FreqToBCD(FreqHz: Int64; var BCD: array of Byte);
var
  I: Integer;
  Lo, Hi: Byte;
begin
  for I := 0 to 4 do
  begin
    Lo := FreqHz mod 10; FreqHz := FreqHz div 10;
    Hi := FreqHz mod 10; FreqHz := FreqHz div 10;
    BCD[I] := (Hi shl 4) or Lo;
  end;
end;
```

### Decoding (BCD to Hz)

```pascal
function BCDToFreq(const BCD: array of Byte): Int64;
var
  I: Integer;
  Multiplier: Int64;
begin
  Result := 0;
  Multiplier := 1;
  for I := 0 to 4 do
  begin
    Result := Result + (BCD[I] and $0F) * Multiplier;
    Multiplier := Multiplier * 10;
    Result := Result + ((BCD[I] shr 4) and $0F) * Multiplier;
    Multiplier := Multiplier * 10;
  end;
end;
```

---

## VFO B Support (Commands $25 and $26)

### Standard Format (IC-7610, IC-9700, IC-705, etc.)

**Query VFO B frequency:**
```
TX: FE FE <radio> <ctrl> 25 FD
RX: FE FE <ctrl> <radio> 25 <5 BCD bytes> FD
```

**Set VFO B frequency:**
```
TX: FE FE <radio> <ctrl> 25 <5 BCD bytes> FD
```

### IC-7760 Extended Format

The IC-7760 requires a sub-command byte `$01`:

**Query VFO B frequency:**
```
TX: FE FE B2 E1 25 01 FD
RX: FE FE E1 B2 25 01 <5 BCD bytes> FD
```

**Set VFO B frequency:**
```
TX: FE FE B2 E1 25 01 <5 BCD bytes> FD
```

### Detection

When parsing command $25/$26 responses:
- If data after command byte is 6 bytes → IC-7760 format (first byte is sub-command, skip it)
- If data after command byte is 5 bytes → standard format (all 5 bytes are BCD frequency)

---

## CW Keyer Speed (Command $14 $0C)

The IC-7760 uses a 2-byte BCD value representing a 0-255 scale, NOT direct WPM.

### BCD to WPM

```pascal
function IcomBCDToWPM(BCDHigh, BCDLow: Byte): Integer;
var
  Value: Integer;
begin
  Value := ((BCDHigh shr 4) * 10 + (BCDHigh and $0F)) * 100 +
           ((BCDLow shr 4) * 10 + (BCDLow and $0F));
  Result := 6 + (Value * 42 + 127) div 255;  // Round properly
end;
```

### WPM to BCD

```pascal
procedure WPMToIcomBCD(WPM: Integer; var BCDHigh, BCDLow: Byte);
var
  Value, Hundreds, Tens, Ones: Integer;
begin
  Value := ((WPM - 6) * 255) div 42;
  Hundreds := Value div 100;
  Tens := (Value mod 100) div 10;
  Ones := Value mod 10;
  BCDHigh := ((Hundreds div 10) shl 4) or (Hundreds mod 10);
  BCDLow := (Tens shl 4) or Ones;
end;
```

**Known firmware bug**: IC-7760 sends value 250 (`$02 $50`) for 48 WPM instead of 255 (`$02 $55`). This causes calculated speed to show ~47 WPM. Radio firmware issue, not protocol bug.

---

## RIT/XIT (Command $21)

### IC-7760: Shared Offset

The IC-7760 uses a **single shared offset** for both RIT and XIT.

**Read offset** (`$21 $00`):
```
TX: FE FE B2 E1 21 00 FD
RX: FE FE E1 B2 21 00 <bcd-high> <bcd-low> <sign> FD
```

**Offset format**: 3 bytes after sub-command
- `<bcd-high>`: Thousands/Hundreds digits as BCD
- `<bcd-low>`: Tens/Ones digits as BCD
- `<sign>`: `$00` = positive, non-zero = negative
- Range: +/- 9999 Hz

```pascal
function ParseRITOffset(BCDHigh, BCDLow, Sign: Byte): Integer;
begin
  Result := ((BCDHigh shr 4) and $0F) * 1000 +
            (BCDHigh and $0F) * 100 +
            ((BCDLow shr 4) and $0F) * 10 +
            (BCDLow and $0F);
  if Sign <> $00 then
    Result := -Result;
end;
```

**RIT on/off** (`$21 $01`): 1 byte, `$00`=off, `$01`=on
**XIT on/off** (`$21 $02`): 1 byte, `$00`=off, `$01`=on (Icom calls this "Delta TX")

**Note**: `$21 $03` is NOT supported on IC-7760 (returns echo only, no data).

---

## Radio-Specific Notes

### IC-7760
- CI-V address: `$B2` (default)
- Controller address: `$E1` (NOT the typical `$E0`)
- VFO B uses sub-command byte `$01` with commands `$25`/`$26`
- Shared RIT/XIT offset
- CW speed uses BCD 0-255 scale

### IC-9700
- CI-V address: `$A2` (typical)
- Controller address: `$E0`
- Standard VFO B format (no sub-command)
- May report CI-V port as 0 in status packet → use 50002 as fallback

### Default Credentials
- Username: blank or "user" (radio-dependent)
- Password: blank (radio-dependent)
- Check radio's Network menu settings

---

## Broadcast Discovery

To find Icom radios on the network without knowing their IP:

1. Create UDP socket, bind to any port
2. For each network interface, send "Are You There" (type `$03`, 16-byte control packet) to the subnet broadcast address (e.g., `192.168.1.255`) on port 50001
3. Set `SentID` to your calculated ID, `RcvdID` to 0
4. Listen 3 seconds for "I Am Here" (type `$04`) responses
5. Each response contains the radio's IP (from UDP source address) and its `SentID`
6. No authentication required for discovery

---

## Disconnection Protocol

Proper disconnection prevents the radio from staying in "connected" state:

1. Send CI-V Close packet (openclose with magic=`$00`) on CI-V socket
2. Send Disconnect (type `$05`) on CI-V socket
3. Send Disconnect (type `$05`) on control socket
4. **CRITICAL**: Wait ~100ms for packets to transmit before closing sockets. UDP `writeDatagram()` is asynchronous - closing immediately can cause disconnect packets to never leave. This causes the radio to remain in "connected" state and refuse new connections.

---

## Packet Reception and CI-V Extraction

When receiving on the CI-V socket, extract CI-V data as follows:

1. Read UDP datagram
2. Check length >= 16 bytes (minimum control packet)
3. If length = 16: handle as control packet (type `$04` = I Am Here, type `$06` = I Am Ready)
4. If length >= 21: handle as data packet
   - Search for `FE FE` byte pattern in the raw packet data
   - Find matching `FD` byte after the `FE FE`
   - Extract bytes from `FE FE` to `FD` inclusive - this is the CI-V frame
   - A single UDP packet may contain multiple CI-V frames (transceive data)

---

## Transceive (Push Updates)

When the radio's frequency, mode, or other settings change (user turns the dial), the radio pushes unsolicited CI-V messages. These arrive as normal data packets on the CI-V socket. Your code should handle these the same way as responses to your commands.

Common push messages:
- `$00` or `$03` - Frequency changed
- `$01` or `$04` - Mode changed
- `$1C $00` - PTT status changed

---

## Implementation Checklist for Delphi 7

1. **UDP Sockets**: Use `TIdUDPClient`/`TIdUDPServer` (Indy) or raw Winsock (`sendto`/`recvfrom`)
2. **Packed Records**: All packet structures must use `packed record`
3. **Big-Endian Helpers**: Write `SwapWord()` and `SwapLongWord()` for big-endian fields
4. **Timer System**: Use `TTimer` components or Windows `SetTimer` for keepalives
5. **State Machine**: Implement the connection states (Disconnected → WaitingForHere → ... → Connected)
6. **Sequence Tracking**: Three separate counters, increment correctly
7. **Packet Buffer**: Store sent packets for retransmission (map by sequence number)
8. **Worker Thread**: Radio I/O should NOT block the main UI thread. Use a dedicated thread for UDP send/receive.

### Big-Endian Helpers for Delphi 7

```pascal
function SwapWord(Value: Word): Word;
begin
  Result := (Value shr 8) or (Value shl 8);
end;

function SwapLongWord(Value: LongWord): LongWord;
begin
  Result := ((Value and $000000FF) shl 24) or
            ((Value and $0000FF00) shl 8) or
            ((Value and $00FF0000) shr 8) or
            ((Value and $FF000000) shr 24);
end;
```

---

## Timing Considerations

- After sending CI-V Open (`$04` magic), wait **~200ms** before sending CI-V commands. The radio needs time to process the open packet.
- "Are You There" retries: 10 attempts with exponential backoff (500ms → 1000ms → 2000ms → 4000ms → 5000ms cap). Total timeout ~50 seconds.
- Token renewal every 60 seconds to maintain session.
- If no CI-V data received for 2 seconds, re-send CI-V Open to restart the stream.

---

## References

- wfview project (open source Icom network control): https://gitlab.com/eliggett/wfview
- TR4W Icom CI-V wiki: https://github.com/n4af/TR4W/wiki/Icom-CI-V-Information
- Icom CI-V Reference Manuals (per radio model, from Icom website)
