# Icom Network Protocol Implementation Status

**Branch:** `IcomNetwork`
**Last commit:** `09fca46` - Compiles clean with Delphi 7
**Date:** 2026-02-26

## Build

```
cd tr4w
"C:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE" tr4w.dpr -E"target"
```

Verified clean compile: 12,291 lines, 0 errors, 0 warnings, 1,672,704 bytes.

---

## COMPLETED

### Protocol Layer (3 new units)

| Unit | Lines | Description |
|------|-------|-------------|
| `uIcomNetworkTypes.pas` | 432 | All packed record types matching the Icom UDP spec: `TControlPacket`, `TPingPacket`, `TDataPacket`, `TOpenClosePacket`, `TLoginPacket`, `TLoginResponsePacket`, `TTokenPacket`, `TStatusPacket`, `TConnInfoPacket`, `TCapabilitiesPacket`, `TRadioCapPacket`. Byte-order helpers (`SwapWord`, `SwapLongWord`), `IcomPasscode` encoder, `CalculateMyId`, state-to-string. |
| `uIcomNetworkTransport.pas` | ~1540 | Full 13-step handshake state machine: AYT→IAH→AYR→IAR→Login→TokenAck→Capabilities→StreamRequest→Status→CI-V handshake→CI-V Open→Connected. Two `TIdUDPServer` instances (control + CI-V) with threaded callbacks. Six Windows timers (ping 500ms, idle 100ms, token renewal 60s, retransmit 100ms, CI-V watchdog 500ms, AYT with exponential backoff). Retransmit buffer (100 packets, 3 retries). Thread-safe sends via `TCriticalSection`. |
| `uIcomNetworkDiscovery.pas` | 127 | Broadcast discovery: sends AYT to `255.255.255.255:50001`, collects IAH responses with IP and RemoteId. |

### Radio Subclasses (6 new units)

| Unit | CI-V Address | Notes |
|------|-------------|-------|
| `uRadioIcom705.pas` | `$A4` | Portable HF/VHF/UHF, WiFi capable |
| `uRadioIcom7300MK2.pas` | `$B6` | Updated IC-7300 |
| `uRadioIcom7600.pas` | `$7A` | HF/50MHz |
| `uRadioIcom7760.pas` | `$B2` | Controller address `$E1`, VFO B via `$25/$26`, shared RIT/XIT with sign byte, `ProcessCIVFrame` override |
| `uRadioIcom7850.pas` | `$8E` | Also covers IC-7851 |
| `uRadioIcom905.pas` | `$AC` | VHF/UHF/SHF |

### Modified Existing Files (8 files)

- **`VC.pas`** - Added `IC905`, `IC7300MK2` to `InterfacedRadioType` enum (after `ACLOG`, before `HAMLIBANY` - preserves binary log compatibility)
- **`LOGRADIO.PAS`** - `RadioParametersArray` entries, `InterfacedRadioTypeSA` strings, `MapRadioModelToFactory` mappings, all Icom radio sets (`IcomRadiosThatSupportRIT`, `IcomRadiosThatSupportVFOB`, `RadioSupportsCWByCAT`, `ICOMRadios`, etc.) updated. `SetUpRadioInterface` wires `IcomNetworkUsername`/`IcomNetworkPassword` onto `TIcomRadio` before calling `Connect`. Added `uRadioIcomBase` to uses clause.
- **`uRadioIcomBase.pas`** - `TIcomNetworkTransport` composition, `IsNetworkConnection`/`Connect`/`Disconnect`/`SendToRadio`/`GetIsConnected` delegate to transport for network mode. `ProcessNetworkCivData` callback. `NetworkUsername`/`NetworkPassword` properties. Fixed `RadioAddress` property shadowing (CI-V `Byte` vs IP `string`) using `TNetRadioBase(Self)` cast.
- **`uRadioFactory.pas`** - All 6 new `TRadioModel` entries, `CreateRadioNetwork` + `CreateRadioSerial` cases, `IsModelSupported`, `ModelToString`, `GetSupportedModels` updated.
- **`uCFG.pas`** - 4 new config commands: `RADIO ONE/TWO ICOM NETWORK USERNAME/PASSWORD` bound to `RadioObject.IcomNetworkUsername`/`IcomNetworkPassword` fields.
- **`uNetRadioBase.pas`** - Minor (unchanged structurally, needed for compilation).
- **`tr4w.dpr`** - All new units added to project uses clause.
- **`tr4w.cfg`** - Compiler config (unchanged structurally).

### Compile Fixes Applied

1. `uIcomNetworkTransport.pas:439` - `TIdUDPReadEvent` → `TUDPReadEvent` (bundled Indy 10 uses this name)
2. `uIcomNetworkTransport.pas:734` - `IfThen` function used before declaration → replaced with inline `if/else`
3. `uIcomNetworkTransport.pas:1300` - Removed unused variable `I`
4. `uRadioIcomBase.pas:213,225,235,240` - `radioAddress` property shadowing: `TIcomRadio.RadioAddress: Byte` (CI-V) hid `TNetRadioBase.radioAddress: string` (IP) → fixed with explicit `TNetRadioBase(Self).radioAddress` cast

---

## REMAINING WORK

### Priority 1 - Required for Basic Functionality

**Band calculation from frequency (uRadioIcomBase.pas:508)**
When frequency response (`$03`) arrives, `vfo[nrVFOA].Band` is never updated. There's a commented-out TODO citing circular dependency with `CalculateBandMode`. Band display and band-dependent logic won't work until this is resolved.

**RITBumpDown/RITBumpUp stubs (uRadioIcomBase.pas:727-734)**
Both methods log a message and do nothing. They need to read `vfo[nrVFOA].RITOffset`, add/subtract 10 Hz, and send CI-V `$21 $02` with the new offset. Used during contest operation.

### Priority 2 - User Experience

**Radio config dialog UI (uCAT.pas) - NOT STARTED**
No dialog support for entering Icom network credentials. The spec called for:
- Username/Password text fields (IDs 132/133) shown when an Icom network radio is selected with TCP/IP
- Port auto-fill to 50001 for Icom network radios
- "Discover" button (ID 134) opening a modal list of discovered radios

Currently users must set credentials via config file commands only:
```
RADIO ONE ICOM NETWORK USERNAME = myuser
RADIO ONE ICOM NETWORK PASSWORD = mypass
```

**Status bar / UI feedback for connection state**
`OnNetworkStateChange` callback only logs to `tr4w.log`. Users see no visible indication that the network connection is connecting, failed, or connected. The spec defined status messages like "Icom Network: Connecting to {IP}...", "Authentication failed", "{RadioName} connected", etc.

### Priority 3 - Model-Specific

**IC-7760 CW speed scaling**
`SetCWSpeed` sends a single BCD byte (WPM value). IC-7760 uses a 0-255 BCD scale requiring two bytes and a WPM-to-scale conversion. `TIcom7760Radio` needs to override `SetCWSpeed`.

### Priority 4 - Robustness

**SO2R with two Icom network radios**
`GTransportInstance` is a global singleton used by the timer window procedure. A second `Connect` call overwrites it, breaking the first radio's timers. Fix: use per-window-instance data (e.g., `SetWindowLongPtr` with `GWLP_USERDATA` or a TList lookup by window handle).

**Discovery returns incomplete info**
`uIcomNetworkDiscovery` only gets IP and RemoteId from the IAH packet. RadioName and CivAddress require a full auth handshake (capabilities packet). Discovery results will show IP addresses only, not model names.

### Priority 5 - Quality

**No automated tests**
No tests exist for:
- Packet serialization/deserialization (critical given mixed endianness)
- `IcomPasscode` encoding
- `CalculateMyId` computation
- `FreqToBCD`/`BCDToFreq` conversion
- State machine transitions

The spec identified byte-order mistakes as the highest risk for silent failures.

---

## Configuration Reference

To use Icom network protocol, set in contest config file or `tr4w.ini`:

```
RADIO ONE TYPE = IC7760          ; or IC705, IC7300, IC7300MK2, IC7600, IC7610, IC7850, IC9700, IC905
RADIO ONE IP ADDRESS = 192.168.1.100
RADIO ONE TCP PORT = 50001
RADIO ONE ICOM NETWORK USERNAME = myuser
RADIO ONE ICOM NETWORK PASSWORD = mypass
```

For serial/USB connection (unchanged behavior):
```
RADIO ONE TYPE = IC7760
RADIO ONE SERIAL PORT = SERIAL1
```

The code auto-detects network vs serial: if `serialPort = NoPort` AND `radioAddress` is set AND `radioPort > 0`, it uses the Icom network transport. Otherwise it falls back to serial CI-V.

---

## Architecture Notes

```
RadioObject.SetUpRadioInterface
  └─> TRadioFactory.CreateRadioNetwork(rmIcomIC7760, ...)
       └─> TIcom7760Radio.Create  (inherits TIcomRadio → TNetRadioBase)
            ├─ Sets CI-V address $B2, controller $E1
            └─ Overrides ProcessCIVFrame for IC-7760 specifics

TIcomRadio.Connect (network mode)
  └─> TIcomNetworkTransport.Create
       ├─ Control TIdUDPServer (port 0 → OS-assigned)
       ├─ CI-V TIdUDPServer (created after handshake learns CI-V port)
       └─ Hidden HWND for Windows timers
  └─> Transport.Connect(IP, 50001, user, pass)
       └─> State machine: AYT → Login → Token → Stream → CI-V Open → Connected

TIcomRadio.SendToRadio(civFrame)
  └─> TIcomNetworkTransport.SendCivData(civFrame)
       └─> Wraps in TDataPacket header, sends via CI-V UDP socket

TIcomNetworkTransport.HandleCivUDPRead (Indy thread callback)
  └─> ExtractCivFrames (FE FE ... FD)
       └─> FOnCivData callback → TIcomRadio.ProcessNetworkCivData
            └─> ProcessCIVMessage → ProcessCIVFrame
```
