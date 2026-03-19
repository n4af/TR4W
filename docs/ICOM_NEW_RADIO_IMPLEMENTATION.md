# Adding a New Icom Network Radio to TR4W

This document is a practical checklist for implementing a new Icom radio in TR4W.
For each item, look up the value in the radio's CI-V manual and compare against the defaults.
If a value differs from the default, override it in the radio's constructor (see examples below).

---

## Step 1: Values to Look Up in the CI-V Manual

### 1.1 CI-V Address (required)
Every radio has a unique factory default CI-V address.

| Radio | CI-V Address |
|-------|-------------|
| IC-705 | $A4 |
| IC-7100 | $88 |
| IC-7300 | $94 |
| IC-7300MK2 | $B6 |
| IC-7600 | $7A |
| IC-7610 | $98 |
| IC-7760 | $B2 |
| IC-7850/7851 | $8E |
| IC-9700 | $A2 |
| IC-905 | $AC |

Set via: `RadioAddress := $XX;` in the constructor.

### 1.2 Controller Address (usually $E0)
The CI-V controller address identifies TR4W (the PC). Almost all radios expect $E0.
**Exception: IC-7760 uses $E1.** If packets are silently ignored, check this first.

Set via: override `ControllerAddress` if the radio differs from $E0.

### 1.3 CI-V Transceive Menu Item (required — varies by radio)
TR4W queries whether CI-V Transceive is enabled at startup to warn the user if it is off.
This is a two-byte menu item number in command `$1A $05 <byte1> <byte2>`, value $00=off/$01=on.

| Radio | Menu Item | Notes |
|-------|-----------|-------|
| IC-7610 | $01 $50 | Default in base class |
| IC-7760 | $01 $50 | Same as IC-7610 |
| IC-9700 | $01 $27 | Different — must override |
| IC-705 | $01 $31 | Different — must override |
| IC-7100 | $00 $95 | Different — must override |
| IC-7300MK2 | $00 $89 | Different — must override |
| IC-7600 | TBD | Check manual |
| IC-7850/7851 | $01 $55 | Different — must override (TBD, verify) |
| IC-905 | $01 $42 | Different — must override |

Set via: `FTransceiveMenuBytes := #$XX + #$XX;` in the constructor.
Look up in: SET menu > Connectors > CI-V Transceive. Note the item number shown in the manual's command table for `$1A $05`.

### 1.4 VFO B Query Format
Most radios use `$25 $01` to query VFO B frequency (5 BCD bytes in response).
**IC-7760 is an exception** — it uses an extended format with an extra sub-command byte in both query and response.

If the radio has an extended `$25`/`$26` format, override `QueryVFOBFrequency`, `SetFrequency`, and `ProcessCIVFrame` as done in `uRadioIcom7760.pas`.

---

## Step 2: Commands TR4W Uses (Verify Each Works on the New Radio)

These are all CI-V commands sent or handled by TR4W. Verify they exist and behave as expected on the new radio. Most are standard across all Icom radios, but sub-command numbers and data formats can differ.

### Frequency
| Command | Direction | Purpose |
|---------|-----------|---------|
| `$03` | Query → Radio | Read VFO A frequency (response: 5 BCD bytes, 10 Hz resolution) |
| `$00` | Transceive ← Radio | VFO A frequency push (unsolicited, same 5 BCD format) |
| `$05 <5 BCD>` | Set → Radio | Write VFO A frequency |
| `$25 $01` | Query → Radio | Read VFO B frequency |
| `$25 $00/$01 <5 BCD>` | Set → Radio | Write VFO A/B frequency |
| `$26` | Transceive ← Radio | VFO B full state push (freq + mode + filter) |

### Mode
| Command | Direction | Purpose |
|---------|-----------|---------|
| `$04` | Query → Radio | Read current mode (response: 1 byte) |
| `$01` | Transceive ← Radio | Mode push (1 byte) |
| `$06 <mode> <filter>` | Set → Radio | Write mode + filter |
| `$1A $06` | Query → Radio | Read data mode sub-mode ($00=off, $01/$02/$03=D1/D2/D3) |

**Mode byte mapping** (standard across all Icom radios):

| Byte | Mode |
|------|------|
| $00 | LSB |
| $01 | USB |
| $02 | AM |
| $03 | CW |
| $04 | FSK (RTTY) |
| $05 | FM |
| $06 | WFM (mapped to FM in TR4W) |
| $07 | CW-R |
| $08 | FSK-R |
| $12 | PSK |
| $13 | PSK-R |
| $17 | DV (D-STAR; mapped to Phone/D-STAR in TR4W) |

### Split
| Command | Direction | Purpose |
|---------|-----------|---------|
| `$0F` | Query → Radio | Read split status (response: $00=off, $01=on) |
| `$0F $00/$01` | Set → Radio | Disable/enable split |

### RIT / XIT
| Command | Direction | Purpose |
|---------|-----------|---------|
| `$21 $00` | Query → Radio | Read shared RIT/XIT offset (3 BCD bytes + sign byte) |
| `$21 $01` | Query → Radio | Read RIT on/off ($00/$01) |
| `$21 $02` | Query → Radio | Read XIT on/off ($00/$01) |
| `$21 $01 $00/$01` | Set → Radio | RIT off/on |
| `$21 $02 $00/$01` | Set → Radio | XIT off/on |
| `$21 $00 <3 BCD> <sign>` | Set → Radio | Write RIT/XIT offset |

> **IC-7760 uses different `$21` sub-commands**: `$21 $00`=offset, `$21 $01`=RIT on/off, `$21 $02`=XIT on/off. This matches the base class. No override needed for RIT/XIT on IC-7760.

### TX / PTT
| Command | Direction | Purpose |
|---------|-----------|---------|
| `$1C $00` | Query → Radio | Read TX/RX status (response: $00=RX, $01=TX) |
| `$1C $00 $01` | Set → Radio | Enable TX (PTT on) |
| `$1C $01 $00` | Set → Radio | Enable RX (PTT off) |

### CW
| Command | Direction | Purpose |
|---------|-----------|---------|
| `$17 $00 <text>` | Set → Radio | Send CW text string |
| `$17 $FF` | Set → Radio | Stop CW transmission |
| `$14 $0C` | Query → Radio | Read CW speed (response: $0C + 2 BCD bytes, 0-255 range) |
| `$14 $0C <BCD-hi> <BCD-lo>` | Set → Radio | Write CW speed |

**CW speed formula**: `icomValue = (wpm - 6) * 255 div 42` (range: 6 WPM=0, 48 WPM=255).
Encoded as two BCD bytes: `high = icomValue div 100`, `low = icomValue mod 100`.
Not all radios support all speeds — check the radio's CW speed range.

### Transceiver ID / Init Trigger
| Command | Direction | Purpose |
|---------|-----------|---------|
| `$19 $00` | Query → Radio | Read transceiver ID; radio responds with its CI-V address, triggering TR4W's full-state query sequence |

After `$19` response, TR4W queries: `$03` (freq), `$04` (mode), `$1A $06` (data mode), `$1C $00` (TX status), `$21 $00/$01` (RIT), `$21 $02` (XIT), `$0F` (split), `$14 $0C` (CW speed), `$1A $05 <menu>` (transceive check).

---

## Step 3: Implementation Checklist

1. **Create `src/uRadioIcomXXXX.pas`** — copy `uRadioIcom705.pas` as the minimal template.
2. **Set `RadioAddress`** — from the CI-V manual.
3. **Set `radioModel`** — human-readable string shown in UI and logs.
4. **Set `FTransceiveMenuBytes`** — look up the CI-V Transceive menu item (Step 1.3 above). Only needed if different from `$01 $50`.
5. **Check controller address** — if not $E0, override it.
6. **Check VFO B format** — if not standard `$25 $01`, override `QueryVFOBFrequency`, `SetFrequency`, `ProcessCIVFrame`.
7. **Register in `uRadioFactory.pas`** — add the new class to the factory's creation logic.
8. **Register in `uCAT.pas`** — add to `UpdateIcomCredentialsVisibility` so username/password fields appear for network mode.
9. **Register in `LOGRADIO.PAS`** — add to `SetUpRadioInterface` so the factory creates the correct class.

---

## Step 4: Minimal Template

```pascal
unit uRadioIcomXXXX;

interface

uses
  uRadioIcomBase, VC;

type
  TIcomXXXXRadio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  Log4D;

var
  logger: TLogLogger;

constructor TIcomXXXXRadio.Create;
begin
  inherited Create;
  RadioAddress := $XX;          // From CI-V manual
  radioModel := 'Icom IC-XXXX';
  // Only set FTransceiveMenuBytes if different from default $01 $50:
  // FTransceiveMenuBytes := #$01 + #$XX;
  logger.Info('[TIcomXXXXRadio.Create] Created IC-XXXX radio instance with CI-V address $XX');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcomXXXX');

end.
```

---

## Known Radio-Specific Quirks

| Radio | Quirk | Fix |
|-------|-------|-----|
| IC-7760 | Controller address is $E1, not $E0 | Hardcoded in `BuildCIVCommand7760()` override |
| IC-7760 | VFO B uses extended `$25 $01` / `$26 $01` format with extra sub-command byte | `ProcessCIVFrame`, `QueryVFOBFrequency`, `SetFrequency` overrides in `uRadioIcom7760.pas` |
| IC-7760 | Shared RIT/XIT offset (`$21 $00`) — one offset controls both | Handled in base class RIT/XIT set/query |
| IC-9700 | CI-V Transceive menu item is `$01 $27` (not `$01 $50`) | `FTransceiveMenuBytes` override in constructor |
| IC-705 | CI-V Transceive menu item is `$01 $31` (not `$01 $50`) | `FTransceiveMenuBytes` override in constructor |
| IC-7100 | Serial-only (no network); CI-V address `$88`; transceive menu `$00 $95` | `FTransceiveMenuBytes` override in constructor |
| IC-7300 | Serial-only — no network support | Use legacy serial path; no network class |
