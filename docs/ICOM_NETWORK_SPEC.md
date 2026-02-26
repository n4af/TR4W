# Icom Network Radio Control - Implementation Specification

## 1. Goals

- Implement Icom's proprietary UDP network protocol for controlling Icom radios over Ethernet/WiFi in TR4W
- Support all network-capable Icom radios: IC-705, IC-7300MK2, IC-7600, IC-7610, IC-7760, IC-7850/IC-7851, IC-905, IC-9700
- Integrate via the existing RadioFactory pattern as a new transport layer (composition) inside the Icom radio class hierarchy
- Support both serial AND network connections for all supported radios (including radios currently serial-only like IC-9700)
- Provide broadcast discovery to find Icom radios on the LAN
- Full contest operation: frequency/mode/split/RIT/XIT control, CW text sending, CW speed, DVK memory playback, PTT
- Username/password authentication configurable via both the radio setup dialog and config file commands

## 2. Non-Goals

- Audio streaming (the Icom network protocol supports it, but TR4W has no use for it)
- IC-R8600 support (receiver only, not contest-relevant)
- IPv6 support (Icom radios are IPv4 only)
- Encryption (Icom's password encoding is simple substitution cipher by design)
- Replacing existing serial CI-V support (serial and network coexist as connection options)

## 3. Assumptions

- Delphi 7 compiler with Indy 10 library (already in project)
- WinSock2.pas already available in `include/`
- Users have configured their Icom radio's network settings (IP address, username/password)
- Single-client per radio (Icom radios typically support only one network control connection at a time)
- The Icom network protocol reference document (`docs/ICOM_NETWORK_DELPHI_REFERENCE.md`) is accurate and verified against IC-7760 and IC-9700 hardware

---

## 4. Architecture

### 4.1 Class Hierarchy

```
TNetRadioBase (existing, unchanged)
└── TIcomRadio (existing uRadioIcomBase.pas, modified)
    │   Owns: TIcomNetworkTransport (new, composition)
    │   When network: delegates send/receive to TIcomNetworkTransport
    │   When serial: uses existing TNetRadioBase serial transport
    │
    ├── TIcom7300Radio (existing, unchanged - serial only, IC-7300 has no network)
    ├── TIcom7300MK2Radio (NEW - network + serial)
    ├── TIcom7600Radio (NEW - network + serial)
    ├── TIcom7610Radio (existing, modified - add network support)
    ├── TIcom7760Radio (NEW - network + serial, IC-7760-specific quirks)
    ├── TIcom7850Radio (NEW - network + serial)
    ├── TIcom9700Radio (existing, modified - add network support)
    ├── TIcom705Radio (NEW - network + serial)
    └── TIcom905Radio (NEW - network + serial)
```

### 4.2 New Files

| File | Purpose | Estimated Lines |
|------|---------|----------------|
| `src/uIcomNetworkTransport.pas` | UDP protocol: handshake, auth, packet framing, keepalives, retransmit | ~1200 |
| `src/uIcomNetworkTypes.pas` | Packed record types for all packet structures, constants | ~300 |
| `src/uIcomNetworkDiscovery.pas` | Broadcast discovery to find radios on LAN | ~200 |
| `src/uRadioIcom7300MK2.pas` | IC-7300MK2 subclass | ~60 |
| `src/uRadioIcom7600.pas` | IC-7600 subclass | ~60 |
| `src/uRadioIcom7760.pas` | IC-7760 subclass (extended VFO B format, shared RIT/XIT, $E1 controller addr) | ~150 |
| `src/uRadioIcom7850.pas` | IC-7850/7851 subclass | ~60 |
| `src/uRadioIcom705.pas` | IC-705 subclass | ~60 |
| `src/uRadioIcom905.pas` | IC-905 subclass | ~60 |

### 4.3 Modified Files

| File | Changes |
|------|---------|
| `src/uRadioIcomBase.pas` | Add `TIcomNetworkTransport` field, override `Connect`/`Disconnect`/`SendToRadio` to delegate to transport when network mode, add `IsNetworkConnection` property |
| `src/uRadioIcom7610.pas` | Add network support (CI-V address already correct) |
| `src/uRadioIcom9700.pas` | Add network support (CI-V address already correct) |
| `src/uRadioFactory.pas` | Add new `TRadioModel` enum entries, factory creation cases |
| `src/uCAT.pas` | Add username/password fields to dialog, auto-fill port 50001 for Icom network radios |
| `src/VC.pas` | Add new `InterfacedRadioType` entries for new radios |
| `src/trdos/LOGRADIO.PAS` | Add `MapRadioModelToFactory` cases for new radios, add network config fields to radio record |
| `src/trdos/CFGCMD.pas` | Add config commands for Icom network username/password |

---

## 5. Component Design

### 5.1 TIcomNetworkTransport (`uIcomNetworkTransport.pas`)

**Responsibility:** Manages the Icom UDP network protocol lifecycle. Provides a clean interface for sending/receiving CI-V data over the Icom proprietary UDP protocol.

**Interface:**

```pascal
TIcomConnectionState = (
  icsDisconnected,
  icsWaitingForHere,      // Sent "Are You There", waiting for "I Am Here"
  icsWaitingForReady,     // Sent "Are You Ready", waiting for "I Am Ready"
  icsWaitingForLogin,     // Sent login, waiting for response
  icsWaitingForToken,     // Sent token ack, waiting for capabilities
  icsWaitingForStream,    // Sent stream request, waiting for CI-V port
  icsCIVHandshake,        // CI-V socket handshake in progress
  icsConnected,           // Fully connected, CI-V stream open
  icsDisconnecting        // Graceful disconnect in progress
);

TIcomNetworkTransport = class(TObject)
private
  // State
  FState: TIcomConnectionState;
  FRadioAddress: string;        // IP address
  FControlPort: Word;           // Default 50001
  FCivPort: Word;               // Learned from radio during handshake
  FUsername: string;
  FPassword: string;
  FClientName: string;          // "TR4W"

  // IDs
  FMyId: LongWord;              // Calculated from local IP/port
  FRemoteId: LongWord;          // Radio's control socket ID
  FCivRemoteId: LongWord;       // Radio's CI-V socket ID (DIFFERENT from control)
  FToken: LongWord;             // Auth token from login response
  FAuthStartId: Word;           // From login response

  // Sockets
  FControlSocket: TIdUDPClient; // Control/auth socket
  FCivSocket: TIdUDPClient;     // CI-V data socket

  // Sequence counters (3 independent)
  FSendSeq: Word;               // Control socket outer sequence
  FCivSeq: Word;                // CI-V socket outer sequence
  FCivInnerSeq: Word;           // CI-V stream inner sequence
  FAuthSeq: Word;               // Auth-related inner sequence (starts $30)
  FPingSendSeq: Word;           // Ping sequence (separate from tracked packets)

  // Capabilities
  FRadioName: string;           // From capabilities packet
  FCivAddress: Byte;            // CI-V address from capabilities
  FMacAddress: array[0..5] of Byte;
  FCommonCap: Word;
  FGUID: array[0..15] of Byte;

  // Timers/Keepalives
  FPingTimer: THandle;          // 500ms ping keepalive
  FIdleTimer: THandle;          // 100ms idle packet
  FTokenRenewalTimer: THandle;  // 60s token renewal
  FRetransmitTimer: THandle;    // 100ms retransmit check
  FCivWatchdogTimer: THandle;   // 500ms CI-V data timeout (2s threshold)
  FLastCivData: TDateTime;      // Last CI-V data received timestamp

  // Retransmit buffer
  FSentPackets: TList;          // Buffer of sent packets for retransmit

  // Callbacks
  FOnCivData: TProcessMsgRef;   // Called when CI-V data received
  FOnStateChange: TNotifyEvent; // Called when connection state changes
  FOnStatusMessage: TSimpleEventProc; // Status messages for UI

  // Worker thread
  FWorkerThread: TThread;       // Background thread for UDP receive loop

  // Internal methods
  procedure SendControlPacket(PktType: Word);
  procedure SendPing;
  procedure SendLoginPacket;
  procedure SendTokenAck;
  procedure SendStreamRequest;
  procedure SendCivOpen;
  procedure SendCivClose;
  procedure HandleReceivedPacket(const Data: array of Byte; DataLen: Integer; FromCivSocket: Boolean);
  procedure HandleControlPacket(const Data: array of Byte; DataLen: Integer; FromCivSocket: Boolean);
  procedure HandleDataPacket(const Data: array of Byte; DataLen: Integer);
  procedure HandlePingPacket(const Data: array of Byte; DataLen: Integer; FromCivSocket: Boolean);
  procedure HandleLoginResponse(const Data: array of Byte; DataLen: Integer);
  procedure HandleCapabilities(const Data: array of Byte; DataLen: Integer);
  procedure HandleStatusPacket(const Data: array of Byte; DataLen: Integer);
  procedure EncodePassword(const Input: string; var Output: array of Byte);
  function CalculateMyId: LongWord;
  procedure RenewToken;
  procedure CheckRetransmit;
  procedure OnCivWatchdog;

public
  constructor Create;
  destructor Destroy; override;

  // Connection lifecycle
  function Connect(Address: string; Port: Word; Username, Password: string): Integer;
  procedure Disconnect;

  // CI-V data send
  procedure SendCivData(const CivFrame: string);

  // Properties
  property State: TIcomConnectionState read FState;
  property IsConnected: Boolean read GetIsConnected;
  property RadioName: string read FRadioName;
  property CivAddress: Byte read FCivAddress;
  property OnCivData: TProcessMsgRef read FOnCivData write FOnCivData;
  property OnStateChange: TNotifyEvent read FOnStateChange write FOnStateChange;
  property OnStatusMessage: TSimpleEventProc read FOnStatusMessage write FOnStatusMessage;
end;
```

**Threading model:**
- A dedicated worker thread runs a `recvfrom` loop on both UDP sockets (using `select()` or dual threads)
- CI-V data received is extracted from the UDP data packet and forwarded via `FOnCivData` callback
- Timers for ping/idle/token renewal/retransmit run on Windows timer callbacks (`SetTimer`)
- All socket sends are protected by a critical section

**State machine transitions:**

```
Disconnected
  → [Connect called] → Send "Are You There" (0x03) → WaitingForHere
WaitingForHere
  → [Receive "I Am Here" (0x04)] → Send "Are You Ready" (0x06) → WaitingForReady
  → [10 retries exhausted] → Disconnected (error: radio not found)
WaitingForReady
  → [Receive "I Am Ready" (0x06)] → Send Login → WaitingForLogin
WaitingForLogin
  → [Receive Login Response, Error=0] → Send Token Ack → WaitingForToken
  → [Receive Login Response, Error=$FEFFFFFF] → Disconnected (error: auth failed)
WaitingForToken
  → [Receive Capabilities] → Send Stream Request → WaitingForStream
WaitingForStream
  → [Receive Status with CivPort] → Start CI-V socket handshake → CIVHandshake
CIVHandshake
  → [CI-V "I Am Ready" received] → Send CI-V Open → Connected
Connected
  → [CI-V data timeout 2s] → Re-send CI-V Open
  → [Disconnect called] → Send CI-V Close, Send Disconnect → Disconnecting
Disconnecting
  → [100ms delay for packets to transmit] → Close sockets → Disconnected
```

### 5.2 TIcomNetworkTypes (`uIcomNetworkTypes.pas`)

All packed record types from the protocol reference document, plus constants:

```pascal
const
  ICOM_DEFAULT_CONTROL_PORT = 50001;
  ICOM_DEFAULT_CIV_PORT = 50002;      // Fallback if radio reports 0
  ICOM_CLIENT_NAME = 'TR4W';

  // Packet types
  ICOM_PKT_ARE_YOU_THERE = $03;
  ICOM_PKT_I_AM_HERE = $04;
  ICOM_PKT_DISCONNECT = $05;
  ICOM_PKT_ARE_YOU_READY = $06;
  ICOM_PKT_PING = $07;
  ICOM_PKT_DATA = $00;

  // Timer intervals (ms)
  ICOM_PING_INTERVAL = 500;
  ICOM_IDLE_INTERVAL = 100;
  ICOM_TOKEN_RENEWAL_INTERVAL = 60000;
  ICOM_RETRANSMIT_CHECK_INTERVAL = 100;
  ICOM_CIV_WATCHDOG_INTERVAL = 500;
  ICOM_CIV_TIMEOUT_THRESHOLD = 2000;   // 2 seconds

  // "Are You There" retry config
  ICOM_AYT_MAX_RETRIES = 10;
  ICOM_AYT_INITIAL_INTERVAL = 500;
  ICOM_AYT_MAX_INTERVAL = 5000;

  // Auth
  ICOM_AUTH_SEQ_START = $30;
  ICOM_AUTH_FAILED = $FEFFFFFF;

type
  TControlPacket = packed record ... end;   // 16 bytes
  TPingPacket = packed record ... end;      // 21 bytes
  TDataPacket = packed record ... end;      // 21 bytes + CI-V data
  TOpenClosePacket = packed record ... end; // 22 bytes
  TLoginPacket = packed record ... end;     // 128 bytes
  TLoginResponsePacket = packed record ... end;  // 96 bytes
  TTokenPacket = packed record ... end;     // 64 bytes
  TStatusPacket = packed record ... end;    // 80 bytes
  TConnInfoPacket = packed record ... end;  // 144 bytes
  TCapabilitiesPacket = packed record ... end;
  TRadioCapPacket = packed record ... end;  // 102 bytes each

  // Helper functions
  function SwapWord(Value: Word): Word;
  function SwapLongWord(Value: LongWord): LongWord;
  procedure IcomPasscode(const Input: string; var Output: array of Byte);
```

### 5.3 TIcomNetworkDiscovery (`uIcomNetworkDiscovery.pas`)

**Responsibility:** Broadcast discovery of Icom radios on the local network.

```pascal
TDiscoveredRadio = record
  IPAddress: string;
  RadioName: string;
  CivAddress: Byte;
  RemoteId: LongWord;
end;

TIcomNetworkDiscovery = class(TObject)
public
  class function DiscoverRadios(TimeoutMs: Integer = 3000): TList; // Returns list of TDiscoveredRadio
end;
```

**Flow:**
1. Create UDP socket, bind to any port
2. For each network interface, send "Are You There" to broadcast address on port 50001
3. Wait `TimeoutMs` for "I Am Here" responses
4. Return list of discovered radios with IP, name, CI-V address

### 5.4 Modifications to TIcomRadio (`uRadioIcomBase.pas`)

Add network transport support via composition:

```pascal
TIcomRadio = class(TNetRadioBase)
protected
  // Existing CI-V fields...
  FNetworkTransport: TIcomNetworkTransport;  // NEW: UDP transport (nil when serial)
  FNetworkUsername: string;                   // NEW
  FNetworkPassword: string;                  // NEW

  procedure ProcessNetworkCivData(msg: string);  // NEW: callback from transport

public
  // Override connection methods to support network
  function Connect: integer; override;
  procedure Disconnect; override;
  procedure SendToRadio(s: string); overload; override;  // Delegates to transport or base

  // NEW: Network configuration
  property NetworkUsername: string read FNetworkUsername write FNetworkUsername;
  property NetworkPassword: string read FNetworkPassword write FNetworkPassword;
  function IsNetworkConnection: Boolean;
end;
```

**Connect override logic:**

```
IF serialPort <> NoPort THEN
  // Serial connection - use existing TNetRadioBase.Connect
  inherited Connect
ELSE IF radioAddress <> '' THEN
  // Network connection - use Icom UDP transport
  Create TIcomNetworkTransport if nil
  Set OnCivData callback to ProcessNetworkCivData
  Call FNetworkTransport.Connect(radioAddress, radioPort, username, password)
END
```

**SendToRadio override logic:**

```
IF FNetworkTransport <> nil AND FNetworkTransport.IsConnected THEN
  // Wrap the CI-V frame string and send via UDP transport
  FNetworkTransport.SendCivData(civFrame)
ELSE
  // Serial - use existing base class send
  inherited SendToRadio(s)
END
```

**CI-V data flow (network mode):**
1. `TIcomNetworkTransport` worker thread receives UDP datagram
2. Extracts CI-V frame(s) from data packet (search for `FE FE ... FD`)
3. Calls `FOnCivData` callback with each CI-V frame as a string
4. `ProcessNetworkCivData` in `TIcomRadio` calls existing `ProcessCIVFrame`
5. Existing CI-V parsing logic handles frequency/mode/status updates unchanged

### 5.5 IC-7760 Specific Subclass (`uRadioIcom7760.pas`)

The IC-7760 has several protocol differences from standard Icom radios:

```pascal
TIcom7760Radio = class(TIcomRadio)
public
  constructor Create;
  // Override VFO B query/set to use sub-command byte $01
  procedure QueryVFOBFrequency; override;
  procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode); override;
  // Override CI-V frame parsing for extended VFO B format
  procedure ProcessCIVFrame(frame: string); override;
end;

constructor TIcom7760Radio.Create;
begin
  inherited Create;
  RadioAddress_CIV := $B2;      // IC-7760 CI-V address
  ControllerAddress := $E1;     // NOT the typical $E0
  radioModel := 'Icom IC-7760';
end;
```

**IC-7760 quirks handled:**
- Controller address `$E1` (not `$E0`)
- VFO B commands `$25`/`$26` require sub-command byte `$01`
- Shared RIT/XIT offset (single offset for both)
- CW speed: BCD 0-255 scale, not direct WPM

### 5.6 RadioFactory Updates (`uRadioFactory.pas`)

**New TRadioModel entries:**

```pascal
TRadioModel = (
  rmNone,
  rmElecraftK4,        // Existing - implemented
  rmElecraftK3,        // NOT IMPLEMENTED - do not add to MapRadioModelToFactory
  rmYaesuFTdx101,      // NOT IMPLEMENTED - do not add to MapRadioModelToFactory
  rmYaesuFT991,        // NOT IMPLEMENTED - do not add to MapRadioModelToFactory
  rmIcomIC7610,        // Existing - implemented (add network support)
  rmIcomIC7300,        // Existing - implemented (serial only, original IC-7300 has no network)
  rmIcomIC7300MK2,     // NEW - implement in this feature
  rmIcomIC9700,        // Existing - implemented (add network support)
  rmIcomIC7760,        // NEW - implement in this feature
  rmIcomIC7850,        // NEW - implement in this feature
  rmIcomIC705,         // NEW - implement in this feature
  rmIcomIC905,         // NEW - implement in this feature
  rmIcomIC7600,        // NEW - implement in this feature
  rmFlexRadio6000,     // NOT IMPLEMENTED - do not add to MapRadioModelToFactory
  rmHamLibDirect       // Existing - implemented
);
```

### CRITICAL: Factory/Legacy Boundary Safety

The `MapRadioModelToFactory` function in `LOGRADIO.PAS` is the **sole gatekeeper** between the legacy serial code path and the modern factory path. It maps `InterfacedRadioType` (the legacy enum used in configuration) to `TRadioModel` (the factory enum).

**How the boundary works:**
1. User selects a radio (e.g., FT-991) in the config dialog → stored as `InterfacedRadioType`
2. `SetUpRadioInterface` calls `MapRadioModelToFactory`
3. If result is `rmNone` → legacy serial code handles the radio (existing, proven behavior)
4. If result is not `rmNone` → factory creates the radio instance

**Invariant: `MapRadioModelToFactory` MUST ONLY return a non-`rmNone` value for radios that have a working factory implementation.** Violating this invariant causes the factory to raise `ERadioFactoryException`, breaking the radio for the user.

Radios like FT-991, FTdx101, K3, and FlexRadio 6000 exist in the `TRadioModel` enum but have NO factory implementation. They MUST continue to return `rmNone` from `MapRadioModelToFactory` so they fall through to the legacy code path that actually works.

**What we add to `MapRadioModelToFactory` in this feature:**

```pascal
function RadioObject.MapRadioModelToFactory: TRadioModel;
begin
   Result := rmNone;
   case Self.RadioModel of
      K4:       Result := rmElecraftK4;       // Existing
      IC7610:   Result := rmIcomIC7610;        // Existing
      IC7300:   Result := rmIcomIC7300;        // Existing
      IC9700:   Result := rmIcomIC9700;        // Existing
      IC7760:   Result := rmIcomIC7760;        // NEW
      IC7850:   Result := rmIcomIC7850;        // NEW
      IC705:    Result := rmIcomIC705;         // NEW
      IC905:    Result := rmIcomIC905;         // NEW
      IC7600:   Result := rmIcomIC7600;        // NEW
      IC7300MK2: Result := rmIcomIC7300MK2;    // NEW
   else
      Result := rmNone;  // ALL OTHER RADIOS: legacy path
   end;
end;
```

**Also update `IsModelSupported` to include the new radios:**

```pascal
class function TRadioFactory.IsModelSupported(model: TRadioModel): boolean;
begin
   Result := model in [
      rmElecraftK4,
      rmIcomIC7610, rmIcomIC7300, rmIcomIC9700,  // Existing
      rmIcomIC7760, rmIcomIC7850, rmIcomIC705,    // New
      rmIcomIC905, rmIcomIC7600, rmIcomIC7300MK2, // New
      rmHamLibDirect
   ];
end;
```

**Factory creation:** For Icom radios, `CreateRadioNetwork` creates the appropriate subclass and sets up the network transport. `CreateRadioSerial` creates the same subclass but leaves the transport as nil (uses base class serial). Radios NOT in the factory (FT-991, K3, etc.) never reach this code — they are handled entirely by the legacy serial path in `LOGRADIO.PAS`.

### 5.7 Radio Config Dialog Updates (`uCAT.pas`)

**New fields (added to dialog when Icom network radio selected with TCP/IP):**

| ID | Control | Purpose | When Visible |
|----|---------|---------|--------------|
| 132 | Text Field | Icom Network Username | TCP/IP selected AND Icom network radio model |
| 133 | Text Field | Icom Network Password | TCP/IP selected AND Icom network radio model |
| 134 | Button | Discover Radios | TCP/IP selected AND Icom network radio model |

**Behavior changes:**
- When an Icom network-capable radio is selected AND port type is TCP/IP:
  - Auto-fill port field with 50001
  - Show username/password fields (IDs 132/133)
  - Show "Discover" button (ID 134)
- "Discover" button opens a modal list of discovered radios; selecting one fills the IP address field

### 5.8 Config Commands (`CFGCMD.pas`)

New config file commands:

```
ICOM NETWORK USERNAME = <string>    // Default: empty (some radios allow blank)
ICOM NETWORK PASSWORD = <string>    // Default: empty
```

These are per-radio settings stored in the radio record, persisted to `settings/tr4w.ini`.

---

## 6. Data Flow

### 6.1 Connection Sequence

```
User selects IC-7760 + TCP/IP in dialog
  → Enters IP 192.168.1.100, Port 50001, Username "user", Password "pass"
  → Clicks OK
    → RestartPollingThread()
      → RadioFactory.CreateRadioNetwork(rmIcomIC7760, "192.168.1.100", 50001, callback)
        → Creates TIcom7760Radio
        → Sets radioAddress, radioPort, NetworkUsername, NetworkPassword
      → radio.Connect()
        → IsNetworkConnection = true (serialPort = NoPort, radioAddress set)
        → Creates TIcomNetworkTransport
        → Transport.Connect("192.168.1.100", 50001, "user", "pass")
          → UDP handshake (steps 1-13 from protocol reference)
          → CI-V stream opens
          → Status: "Icom IC-7760: Connected"
      → pNetworkRadio polling loop starts
        → radio.PollRadioState() sends CI-V queries via transport
        → Transport wraps CI-V in UDP data packets, sends via socket
        → Worker thread receives responses, extracts CI-V, calls callback
        → TIcomRadio.ProcessCIVFrame() updates VFO state
        → Polling loop copies to RadioStatusRecord → UI updates
```

### 6.2 CI-V Command Send Path (Network Mode)

```
radio.SetFrequency(14250000, nrVFOA, rmCW)
  → TIcomRadio.BuildCIVCommand($05, FreqToBCD(14250000))
    → "FE FE B2 E1 05 00 00 25 41 00 FD"
  → TIcomRadio.SendToRadio(civFrame)
    → FNetworkTransport.SendCivData(civFrame)
      → Build TDataPacket header (21 bytes)
      → Append CI-V frame
      → Set Len = 21 + length(civFrame)
      → Set PktType = $00
      → Set Seq = FCivSeq (little-endian), increment FCivSeq
      → Set SendSeq = SwapWord(FCivInnerSeq) (big-endian), increment FCivInnerSeq
      → Set SentID = FMyId, RcvdID = FCivRemoteId
      → sendto(FCivSocket, packet, radioAddress, civPort)
      → Store in retransmit buffer
```

### 6.3 CI-V Response Receive Path (Network Mode)

```
Worker thread: recvfrom(FCivSocket) → raw UDP datagram
  → HandleReceivedPacket(data, len, fromCivSocket=true)
    → If len = 16: HandleControlPacket (ping response, etc.)
    → If len >= 21: HandleDataPacket
      → Search for FE FE in raw data
      → Find matching FD
      → Extract CI-V frame bytes
      → Convert to string
      → Call FOnCivData(civFrameString)  // callback to TIcomRadio
        → ProcessNetworkCivData(msg)
          → ProcessCIVFrame(msg)  // existing CI-V parser
            → Updates vfo[nrVFOA].frequency, mode, etc.
```

---

## 7. Supported Radios - CI-V Details

| Radio | CI-V Addr | Ctrl Addr | VFO B Format | RIT/XIT | In InterfacedRadioType? | In RadioParametersArray? | Notes |
|-------|-----------|-----------|--------------|---------|-------------------------|--------------------------|-------|
| IC-705 | $A4 | $E0 | Standard ($25) | Standard | Yes | Yes (RA: $A4) | WiFi or USB |
| IC-7300MK2 | $B6 | $E0 | Standard ($25) | Standard | **No - must add** | **No - must add** | Network version of IC-7300. |
| IC-7600 | $7A | $E0 | Standard ($25) | Standard | Yes | Yes (RA: $7A) | Older radio |
| IC-7610 | $98 | $E0 | Standard ($25) | Standard | Yes | Yes (RA: $98) | Already in TR4W (serial) |
| IC-7760 | $B2 | **$E1** | **Extended ($25 $01)** | **Shared offset** | Yes | Yes (RA: $B2) | Most quirks |
| IC-7850/7851 | $8E | $E0 | Standard ($25) | Standard | Yes (both) | Yes (both, RA: $8E) | Identical protocol. |
| IC-905 | $AC | $E0 | Standard ($25) | Standard | **No - must add** | **No - must add** | VHF/UHF/SHF |
| IC-9700 | $A2 | $E0 | Standard ($25) | Standard | Yes | Yes (RA: $A2) | Already in TR4W (serial) |

**CI-V address source:** The `RA` field in `RadioParametersArray` (LOGRADIO.PAS) is the authoritative source for CI-V addresses for radios already in the codebase. For IC-905 and IC-7300MK2 (not yet in codebase), addresses need verification. The capabilities packet received during handshake also reports the CI-V address and can be used to confirm/override.

**New entries required in VC.pas `InterfacedRadioType` and LOGRADIO.PAS `RadioParametersArray`:**
- `IC7300MK2` - must be added at end of enum. CI-V address $B6.
- `IC905` - must be added in the Icom range. CI-V address $AC (to be verified).

**CRITICAL ordering constraint:** `InterfacedRadioType` is a Delphi enumerated type. The `RadioParametersArray` and `InterfacedRadioTypeSA` arrays are indexed by this enum and **must be in the exact same order**. Adding new entries at the END of the Icom range (before `OMNI6`) is safest. However, since `InterfacedRadioType` is stored in QSO log records (`ContestExchange.Radio` field), adding entries mid-enum shifts the ordinal values of all subsequent entries, corrupting existing log files. New entries **must go at the end of the enum** (before `HAMLIBANY` or after it) to preserve binary compatibility with existing log data.

---

## 8. Error Handling & Status

### 8.1 Connection Status Messages (shown in main window status area)

| State | Status Message |
|-------|---------------|
| Connecting | "Icom Network: Connecting to {IP}..." |
| Auth failed | "Icom Network: Authentication failed - check username/password" |
| Radio not found | "Icom Network: Radio not found at {IP}:{port}" |
| Connected | "Icom Network: {RadioName} connected" |
| Reconnecting | "Icom Network: Connection lost, reconnecting..." |
| Disconnected | "Icom Network: Disconnected" |

### 8.2 Error Recovery

- **Connection timeout:** Exponential backoff retries (same as existing radio reconnection in `pNetworkRadio`)
- **Auth failure:** Log error, report to status bar, stop retrying (user must fix credentials)
- **CI-V timeout (2s no data):** Re-send CI-V Open packet to restart stream
- **Token expiry:** Automatic renewal every 60 seconds
- **Missing packets:** Retransmit from buffer when radio requests (sequence gap detection)

### 8.3 Logging

All protocol-level events logged via Log4D:
- **TRACE:** Raw packet hex dumps, sequence numbers, timer events
- **DEBUG:** State transitions, CI-V frame extraction, keepalive timing
- **INFO:** Connection/disconnection events, radio capabilities received
- **WARN:** Retransmit requests, CI-V timeouts, unexpected packet types
- **ERROR:** Auth failures, socket errors, protocol violations

---

## 9. Configuration Persistence

### 9.1 INI File Format (`settings/tr4w.ini`)

```ini
[Radio1]
RADIO TYPE = IC-7760
CAT PORT = TCP/IP
RADIO TCP ADDRESS = 192.168.1.100
RADIO TCP PORT = 50001
ICOM NETWORK USERNAME = user
ICOM NETWORK PASSWORD = pass
```

### 9.2 Config File Commands

```
ICOM NETWORK USERNAME = user
ICOM NETWORK PASSWORD = pass
```

---

## 10. Implementation Order

### Phase 1: Foundation (no hardware needed to compile)
1. `uIcomNetworkTypes.pas` - Packet structures and constants
2. `uIcomNetworkTransport.pas` - UDP protocol state machine
3. `uIcomNetworkDiscovery.pas` - Broadcast discovery

### Phase 2: Integration
4. Modify `uRadioIcomBase.pas` - Add network transport composition
5. Create new radio subclasses (IC-7760, IC-705, IC-7850, IC-905, IC-7600, IC-7300MK2)
6. Modify existing subclasses (IC-7610, IC-9700) for network support
7. Update `uRadioFactory.pas` - New enum entries and factory cases

### Phase 3: Configuration
8. Update `uCAT.pas` - Dialog fields for username/password/discover
9. Update `CFGCMD.pas` - Config commands
10. Update `VC.pas` and `LOGRADIO.PAS` - Radio type enum entries and mapping

### Phase 4: Testing
11. Test with IC-7760 hardware (primary test radio)
12. Test with IC-9700 hardware (verify serial+network dual mode)
13. Verify discovery on local network
14. Verify reconnection/error recovery

---

## 11. Open Questions / Risks

### 11.1 Resolved Questions

1. **IC-7600 CI-V address:** **RESOLVED.** Confirmed `$7A` from `RadioParametersArray` in LOGRADIO.PAS (RA field).
2. **IC-905 CI-V address:** **RESOLVED.** Confirmed `$AC`. IC-905 does not exist in the codebase yet — needs to be added to `InterfacedRadioType` and `RadioParametersArray`.
3. **IC-7850 vs IC-7851:** **RESOLVED.** Confirmed identical from protocol perspective. Both use CI-V address `$8E` in `RadioParametersArray`. Treat as same radio.
4. **Firewall considerations:** **RESOLVED.** Windows will prompt the user to allow UDP through the firewall on first connection. Document this requirement in user documentation; do not programmatically modify firewall rules.

### 11.2 Remaining Open Questions

1. **Multiple radios on same network:** If a user has two Icom radios (e.g., SO2R with two IC-7610s), does the discovery correctly distinguish them? Each radio has a different `SentID` and MAC address, so discovery should return separate entries. Needs testing with actual hardware to confirm.
2. **IC-7300MK2 CI-V address:** **RESOLVED.** Confirmed `$B6`.
3. **InterfacedRadioType enum ordering:** Adding IC-905 and IC-7300MK2 mid-enum would shift ordinal values and corrupt existing log files (the `Radio` field in `ContestExchange` is stored as this enum). New entries must go at the end. Need to verify exact safe insertion point.

### 11.2 Risks

1. **Mixed endianness:** The protocol uses little-endian for header fields and big-endian for payload fields. A single byte-order mistake causes silent failures. **Mitigation:** Thorough unit test of packet serialization/deserialization.
2. **Sequence number management:** Three independent sequence counters with different endianness. Getting this wrong causes the radio to request retransmits or ignore commands. **Mitigation:** Centralized sequence management in transport class with clear naming.
3. **Timer interactions:** Six concurrent timers (ping, idle, token, retransmit, watchdog, AYT backoff) must not interfere with each other. **Mitigation:** Each timer has a single, well-defined responsibility.
4. **Thread safety:** Worker thread receives packets while main thread (via polling loop) sends CI-V commands. **Mitigation:** Critical section on socket send, lock-free callback queue for received data.
5. **UDP reliability:** UDP is unreliable. Packets can be lost, duplicated, or reordered. **Mitigation:** Retransmit buffer, sequence tracking, watchdog timer.
6. **Delphi 7 limitations:** No generics, limited threading primitives, no modern async patterns. **Mitigation:** Use proven patterns from existing codebase (TThread, TCriticalSection, SetTimer).

---

## 12. References

- Protocol reference: `docs/ICOM_NETWORK_DELPHI_REFERENCE.md`
- wfview project: https://gitlab.com/eliggett/wfview
- TR4W Icom CI-V wiki: https://github.com/n4af/TR4W/wiki/Icom-CI-V-Information
- Existing codebase: `uRadioIcomBase.pas`, `uNetRadioBase.pas`, `uRadioFactory.pas`
