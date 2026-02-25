# Radio Factory Pattern Implementation

**Branch:** `feature/radio-factory`
**Date:** December 29, 2025
**Status:** Initial Implementation

## Overview

This branch implements a **Factory Pattern** for creating and managing multiple network radio instances in TR4W. The implementation provides:

- **TRadioFactory**: Centralized radio creation based on model type
- **TRadioManager**: Management of multiple radio instances
- **Extensible architecture**: Easy to add new radio models

## Files Added

### Core Implementation
- **`tr4w/src/uRadioFactory.pas`** - Factory class for radio creation
- **`tr4w/src/uRadioManager.pas`** - Manager class for multiple radios
- **`tr4w/src/TestRadioFactory.pas`** - Test/demonstration program

### Documentation
- **`NETWORK_RADIO_FACTORY_ANALYSIS.md`** - Detailed architecture analysis
- **`RADIO_FACTORY_README.md`** - This file

## Quick Start

### Single Radio (Traditional Usage)

```pascal
uses uRadioFactory, uNetRadioBase;

var
  radio: TNetRadioBase;

procedure MyProcessMessage(msg: string);
begin
  // Handle radio messages
end;

begin
  // Create radio using factory
  radio := TRadioFactory.CreateRadio(
    rmElecraftK4,              // Radio model
    '192.168.1.100',           // IP address
    7373,                      // Port
    @MyProcessMessage          // Callback
  );

  // Connect and use
  radio.Connect;
  radio.SetFrequency(14025000, nrVFOA);

  // Cleanup
  radio.Disconnect;
  radio.Free;
end;
```

### Multiple Radios (SO2R / Multi-Op)

```pascal
uses uRadioFactory, uRadioManager, uNetRadioBase;

var
  manager: TRadioManager;
  radio1, radio2: TNetRadioBase;

procedure ProcessRadio1Msg(msg: string);
begin
  WriteLn('[Radio1] ', msg);
end;

procedure ProcessRadio2Msg(msg: string);
begin
  WriteLn('[Radio2] ', msg);
end;

begin
  manager := TRadioManager.Create;
  try
    // Create two K4 radios
    radio1 := TRadioFactory.CreateRadio(rmElecraftK4, '192.168.1.100', 7373, @ProcessRadio1Msg);
    radio2 := TRadioFactory.CreateRadio(rmElecraftK4, '192.168.1.101', 7373, @ProcessRadio2Msg);

    // Add to manager
    manager.AddRadio('Radio1', radio1);
    manager.AddRadio('Radio2', radio2);

    // Connect all
    manager.ConnectAll;

    // Use individually
    manager.GetRadio('Radio1').SetFrequency(14025000, nrVFOA);
    manager.GetRadio('Radio2').SetFrequency(7025000, nrVFOA);

    // Or use active radio
    manager.ActiveRadioId := 'Radio1';
    manager.ActiveRadio.SetMode(rmCW, nrVFOA);

  finally
    manager.Free;  // Auto-disconnects and frees all radios
  end;
end;
```

## Supported Radio Models

### Currently Implemented
- ✅ **Elecraft K4** (`rmElecraftK4`)

### Planned
- ⏳ Elecraft K3 (`rmElecraftK3`)
- ⏳ Yaesu FTdx101 (`rmYaesuFTdx101`)
- ⏳ Yaesu FT-991 (`rmYaesuFT991`)
- ⏳ Icom IC-7610 (`rmIcomIC7610`)
- ⏳ Icom IC-7300 (`rmIcomIC7300`)
- ⏳ FlexRadio 6000 (`rmFlexRadio6000`)
- ⏳ HamLib Generic (`rmHamLibGeneric`)

## TRadioFactory API

### Class Methods

#### CreateRadio
```pascal
class function CreateRadio(
  model: TRadioModel;
  address: string;
  port: integer;
  msgCallback: TProcessMsgRef
): TNetRadioBase;
```
Creates a radio instance of the specified model.

**Raises:** `ERadioFactoryException` if model not supported

#### IsModelSupported
```pascal
class function IsModelSupported(model: TRadioModel): boolean;
```
Checks if a radio model is implemented.

#### GetSupportedModels
```pascal
class function GetSupportedModels: string;
```
Returns a string listing all supported models.

## TRadioManager API

### Radio Management

| Method | Description |
|--------|-------------|
| `AddRadio(id, radio)` | Add radio to manager |
| `RemoveRadio(id)` | Remove and free radio |
| `GetRadio(id)` | Get radio by ID |
| `HasRadio(id)` | Check if radio exists |
| `GetRadioCount` | Number of managed radios |
| `GetRadioList` | Array of radio IDs |

### Connection Management

| Method | Description |
|--------|-------------|
| `ConnectAll` | Connect all radios |
| `DisconnectAll` | Disconnect all radios |
| `ConnectRadio(id)` | Connect specific radio |
| `DisconnectRadio(id)` | Disconnect specific radio |

### Active Radio

```pascal
property ActiveRadioId: string read/write;
property ActiveRadio: TNetRadioBase read;
```

The "active" radio is the currently selected radio for operations. Setting `ActiveRadioId` allows quick access via the `ActiveRadio` property.

### Utility Methods

| Method | Description |
|--------|-------------|
| `ClearAll` | Remove all radios |
| `GetStatusReport` | Formatted status string |

## Testing

### Run Test Program

```bash
cd tr4w
dcc32 src/TestRadioFactory.pas
TestRadioFactory.exe
```

The test program demonstrates:
1. Factory methods (GetSupportedModels, IsModelSupported)
2. Single radio creation
3. Multiple radios with manager
4. Exception handling for unsupported radios

### Expected Output

```
===============================================
Radio Factory Pattern - Test Program
===============================================

=== Test 1: Single Radio Creation ===

Created radio: Elecraft K4
Address: 192.168.1.100
Port: 7373

Attempting to connect...
Connection failed (this is normal if no radio present)
Test 1 complete

=== Test 2: Multiple Radios with Manager ===

Added Radio1 to manager
Added Radio2 to manager
Total radios: 2
Active radio: Radio1

=== Radio Manager Status Report ===
Total Radios: 2
Active Radio: Radio1

Radio Details:
  [Radio1]
    Model: Elecraft K4
    Address: 192.168.1.100:7373
    Connected: False

  [Radio2]
    Model: Elecraft K4
    Address: 192.168.1.101:7373
    Connected: False

...
```

## Integration with TR4W

### Option 1: Replace Existing Radio Creation

**Current TR4W code:**
```pascal
// Direct instantiation
radio := TK4Radio.Create;
radio.radioAddress := '192.168.1.100';
radio.radioPort := 7373;
```

**New factory pattern:**
```pascal
radio := TRadioFactory.CreateRadio(rmElecraftK4, '192.168.1.100', 7373, @ProcessMsg);
```

### Option 2: Use RadioManager for SO2R

```pascal
// In MainUnit.pas
var
  RadioManager: TRadioManager;

initialization
  RadioManager := TRadioManager.Create;

// In radio setup code
procedure SetupRadios;
begin
  radio1 := TRadioFactory.CreateRadio(rmElecraftK4, cfg.Radio1Address, 7373, @ProcessRadio1);
  radio2 := TRadioFactory.CreateRadio(rmElecraftK4, cfg.Radio2Address, 7373, @ProcessRadio2);

  RadioManager.AddRadio('Radio1', radio1);
  RadioManager.AddRadio('Radio2', radio2);
  RadioManager.ConnectAll;
end;

// In radio command handlers
procedure SetActiveRadioFrequency(freq: integer);
begin
  if Assigned(RadioManager.ActiveRadio) then
    RadioManager.ActiveRadio.SetFrequency(freq, nrVFOA);
end;
```

## Architecture Benefits

### Extensibility
- Add new radio models by creating new class inheriting from `TNetRadioBase`
- Register in factory's `CreateRadio` method
- No changes to calling code

### Type Safety
- Enum-based model selection prevents typos
- Compile-time checking of model types

### Resource Management
- RadioManager handles cleanup automatically
- No memory leaks from forgotten `Free` calls

### Testing
- Easy to create mock radios for testing
- Can test multi-radio scenarios without hardware

### Flexibility
- Runtime selection of radio models
- Configuration-driven radio setup
- Support for mixed radio types (K4 + Yaesu + Icom)

## Future Enhancements

### Configuration File Support
```json
{
  "radios": [
    {
      "id": "Radio1",
      "model": "Elecraft K4",
      "address": "192.168.1.100",
      "port": 7373,
      "enabled": true
    },
    {
      "id": "Radio2",
      "model": "Yaesu FTdx101",
      "address": "192.168.1.101",
      "port": 4532,
      "enabled": true
    }
  ]
}
```

### Registration Pattern
Allow runtime registration of radio types for plugin architecture:
```pascal
TRadioRegistry.RegisterRadio('Elecraft K4', @CreateK4Radio);
```

### Radio Capability Discovery
Query radios for supported features:
```pascal
if radio.SupportsFeature(rfDualWatch) then
  radio.EnableDualWatch;
```

## Compilation

The factory and manager units should compile with existing TR4W build system:

```bash
cd tr4w
"C:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE" tr4w.dpr
```

## Logging

Both factory and manager use Log4D for logging:
- `[RadioFactory]` - Radio creation events
- `[RadioManager]` - Radio management events

Set log level in tr4w.ini:
```ini
DEBUG LOG LEVEL = DEBUG
```

## Known Limitations

1. **Single callback per radio:** Each radio instance requires its own message handler
2. **No dynamic radio discovery:** Radios must be manually configured
3. **K4 only:** Currently only Elecraft K4 is fully implemented

## Contributing

To add a new radio model:

1. Create new unit inheriting from `TNetRadioBase`:
   ```pascal
   type TYaesuRadio = class(TNetRadioBase)
   ```

2. Implement all abstract methods from base class

3. Add enum to `TRadioModel` in `uRadioFactory.pas`

4. Add case to `CreateRadio` method

5. Test with TestRadioFactory program

## Questions?

See `NETWORK_RADIO_FACTORY_ANALYSIS.md` for detailed architectural analysis and design decisions.

## License

Same as TR4W (GPL v2 or later)
