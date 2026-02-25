# Network Radio Class Factory Analysis

## Current Architecture

### Class Hierarchy

```
TNetRadioBase (Abstract Base Class)
    │
    ├─ TK4Radio (Elecraft K4 implementation)
    ├─ [Future: TFlexRadio]
    ├─ [Future: TYaesuRadio]
    └─ [Future: TIcomRadio]
```

### TNetRadioBase Responsibilities

**Connection Management:**
- `TIdTCPClient socket` - Indy TCP client for network communication
- `TReadingThread rt` - Dedicated thread for reading from radio
- `Connect(address: string; port: integer)` - Establish TCP connection
- `Disconnect()` - Clean shutdown of socket and thread

**State Management:**
- `vfo[Low(TVFO)..High(TVFO)]` - Array of VFO objects (VFOA, VFOB)
- `TRadioVFO` - Encapsulates frequency, mode, band, RIT/XIT, filter per VFO
- Properties with indexed accessors: `frequency[vfo]`, `mode[vfo]`, `band[vfo]`

**Message Handling:**
- `baseProcMsg: TProcessMsgRef` - Callback for processing incoming messages
- `TReadingThread.Execute` - Reads from socket using `ReadLn(readTerminator)`
- Calls `msgHandler(cmd)` for each received message

**Abstract Interface:**
```pascal
procedure ProcessMsg(msg: string); Virtual; Abstract;
procedure SetFrequency(freq: longint; vfo: TVFO); Virtual; Abstract;
procedure SetMode(mode:TRadioMode); Virtual; Abstract;
// ... 20+ abstract methods
```

### TK4Radio Implementation

**Constructor:**
```pascal
Constructor TK4Radio.Create;
begin
   inherited Create(ProcessMessage);  // Pass own ProcessMessage as callback
end;
```

**Key Features:**
- Implements K4-specific command protocol (e.g., `FA` = VFO A frequency, `MD` = mode)
- `ProcessMessage(sMessage: string)` - Parses K4 responses
- VFO-specific commands via `$` suffix (e.g., `MD$` = mode for VFO B)
- Maintains readTerminator = `;` for K4 protocol

**Example Commands:**
```pascal
procedure TK4Radio.SetFrequency(freq: longint; vfo: TVFO);
begin
   case vfo of
      nrVFOA: sCmd := 'FA';
      nrVFOB: sCmd := 'FB';
   end;
   Self.SendToRadio(Format('%2s%.11d;',[sCmd,freq]));
end;
```

---

## Class Factory Pattern Design

### Option 1: Simple Factory with Enumeration

**Advantages:**
- Straightforward implementation
- Centralized radio creation logic
- Easy to extend with new radio types

**Implementation:**

```pascal
unit uRadioFactory;

interface
uses uNetRadioBase, uRadioElecraftK4;

type
  TRadioModel = (rmElecraftK4, rmFlexRadio, rmYaesuFTdx101, rmIcomIC7610);

  TRadioFactory = class
  public
    class function CreateRadio(model: TRadioModel;
                               address: string;
                               port: integer;
                               msgCallback: TProcessMsgRef): TNetRadioBase;
  end;

implementation

class function TRadioFactory.CreateRadio(model: TRadioModel;
                                         address: string;
                                         port: integer;
                                         msgCallback: TProcessMsgRef): TNetRadioBase;
begin
  Result := nil;

  case model of
    rmElecraftK4:
      begin
        Result := TK4Radio.Create;
        Result.radioAddress := address;
        Result.radioPort := port;
      end;

    rmFlexRadio:
      begin
        // Result := TFlexRadio.Create(msgCallback);
        // Result.radioAddress := address;
        // Result.radioPort := port;
        raise Exception.Create('FlexRadio not yet implemented');
      end;

    // ... other radio types
  end;
end;

end.
```

**Usage:**
```pascal
var
  radio1: TNetRadioBase;
  radio2: TNetRadioBase;
begin
  // Create two K4 radios on different addresses
  radio1 := TRadioFactory.CreateRadio(rmElecraftK4, '192.168.1.100', 7373,
                                      @ProcessRadio1Message);
  radio2 := TRadioFactory.CreateRadio(rmElecraftK4, '192.168.1.101', 7373,
                                      @ProcessRadio2Message);

  radio1.Connect;
  radio2.Connect;

  // Use radios independently
  radio1.SetFrequency(14025000, nrVFOA);
  radio2.SetFrequency(7025000, nrVFOA);
end;
```

---

### Option 2: Registration Pattern (More Flexible)

**Advantages:**
- Runtime registration of radio types
- No need to modify factory when adding new radios
- Supports plugins/dynamic loading

**Implementation:**

```pascal
unit uRadioRegistry;

interface
uses uNetRadioBase, SysUtils, Generics.Collections;

type
  TRadioConstructor = function(msgCallback: TProcessMsgRef): TNetRadioBase;

  TRadioRegistry = class
  private
    class var FRegistry: TDictionary<string, TRadioConstructor>;
    class constructor Create;
    class destructor Destroy;
  public
    class procedure RegisterRadio(modelName: string; constructor: TRadioConstructor);
    class function CreateRadio(modelName: string;
                               address: string;
                               port: integer;
                               msgCallback: TProcessMsgRef): TNetRadioBase;
    class function GetRegisteredModels: TArray<string>;
  end;

implementation

class constructor TRadioRegistry.Create;
begin
  FRegistry := TDictionary<string, TRadioConstructor>.Create;
end;

class destructor TRadioRegistry.Destroy;
begin
  FRegistry.Free;
end;

class procedure TRadioRegistry.RegisterRadio(modelName: string;
                                             constructor: TRadioConstructor);
begin
  FRegistry.AddOrSetValue(modelName, constructor);
end;

class function TRadioRegistry.CreateRadio(modelName: string;
                                          address: string;
                                          port: integer;
                                          msgCallback: TProcessMsgRef): TNetRadioBase;
var
  constructor: TRadioConstructor;
begin
  if not FRegistry.TryGetValue(modelName, constructor) then
    raise Exception.CreateFmt('Radio model "%s" not registered', [modelName]);

  Result := constructor(msgCallback);
  Result.radioAddress := address;
  Result.radioPort := port;
end;

class function TRadioRegistry.GetRegisteredModels: TArray<string>;
begin
  Result := FRegistry.Keys.ToArray;
end;

end.
```

**Registration (in initialization section of each radio unit):**

```pascal
// In uRadioElecraftK4.pas
initialization
  TRadioRegistry.RegisterRadio('Elecraft K4',
    function(cb: TProcessMsgRef): TNetRadioBase
    begin
      Result := TK4Radio.Create;
    end);

// In uRadioFlexRadio.pas
initialization
  TRadioRegistry.RegisterRadio('FlexRadio 6600',
    function(cb: TProcessMsgRef): TNetRadioBase
    begin
      Result := TFlexRadio.Create(cb);
    end);
```

**Usage:**
```pascal
var
  radio: TNetRadioBase;
  models: TArray<string>;
begin
  // Discover available radios
  models := TRadioRegistry.GetRegisteredModels;
  // models = ['Elecraft K4', 'FlexRadio 6600', ...]

  // Create by name (could come from config file)
  radio := TRadioRegistry.CreateRadio('Elecraft K4', '192.168.1.100', 7373,
                                      @ProcessMessage);
  radio.Connect;
end;
```

---

## Multiple Instance Management

### Challenge: Message Routing

**Problem:** Each radio instance needs its own message handler, but TR4W currently expects a single radio.

**Solution 1: Radio Manager with Dispatch**

```pascal
unit uRadioManager;

interface
uses uNetRadioBase, Generics.Collections;

type
  TRadioManager = class
  private
    FRadios: TDictionary<string, TNetRadioBase>;
    procedure DispatchMessage(radioId: string; msg: string);
  public
    constructor Create;
    destructor Destroy; override;

    function AddRadio(radioId: string; radio: TNetRadioBase): boolean;
    function GetRadio(radioId: string): TNetRadioBase;
    procedure RemoveRadio(radioId: string);

    // Convenience methods
    procedure ConnectAll;
    procedure DisconnectAll;
    function GetRadioList: TArray<string>;
  end;

implementation

constructor TRadioManager.Create;
begin
  FRadios := TDictionary<string, TNetRadioBase>.Create;
end;

destructor TRadioManager.Destroy;
var
  radio: TNetRadioBase;
begin
  for radio in FRadios.Values do
  begin
    radio.Disconnect;
    radio.Free;
  end;

  FRadios.Free;
  inherited;
end;

function TRadioManager.AddRadio(radioId: string; radio: TNetRadioBase): boolean;
begin
  if FRadios.ContainsKey(radioId) then
    Exit(False);

  FRadios.Add(radioId, radio);

  // Wrap the radio's message handler to include radioId
  // This requires modifying TNetRadioBase constructor or adding a SetMessageHandler method

  Result := True;
end;

procedure TRadioManager.DispatchMessage(radioId: string; msg: string);
begin
  // Route message to appropriate handler based on radioId
  // Could update UI elements specific to this radio
  logger.info('[RadioManager] Radio %s: %s', [radioId, msg]);
end;

function TRadioManager.GetRadio(radioId: string): TNetRadioBase;
begin
  if not FRadios.TryGetValue(radioId, Result) then
    Result := nil;
end;

procedure TRadioManager.ConnectAll;
var
  radio: TNetRadioBase;
begin
  for radio in FRadios.Values do
    radio.Connect;
end;

procedure TRadioManager.DisconnectAll;
var
  radio: TNetRadioBase;
begin
  for radio in FRadios.Values do
    radio.Disconnect;
end;

function TRadioManager.GetRadioList: TArray<string>;
begin
  Result := FRadios.Keys.ToArray;
end;

end.
```

**Usage Example:**

```pascal
var
  radioManager: TRadioManager;
  radio1, radio2: TNetRadioBase;
begin
  radioManager := TRadioManager.Create;
  try
    // Create radios via factory
    radio1 := TRadioFactory.CreateRadio(rmElecraftK4, '192.168.1.100', 7373, nil);
    radio2 := TRadioFactory.CreateRadio(rmElecraftK4, '192.168.1.101', 7373, nil);

    // Register with manager
    radioManager.AddRadio('Radio1', radio1);
    radioManager.AddRadio('Radio2', radio2);

    // Connect all
    radioManager.ConnectAll;

    // Access individual radios
    radioManager.GetRadio('Radio1').SetFrequency(14025000, nrVFOA);
    radioManager.GetRadio('Radio2').SetFrequency(7025000, nrVFOA);

  finally
    radioManager.Free;  // Automatically disconnects and frees all radios
  end;
end;
```

---

### Solution 2: Closure-Based Message Handlers

**Modify TK4Radio constructor to accept a radio identifier:**

```pascal
unit uRadioElecraftK4;

type
  TK4Radio = class(TNetRadioBase)
  private
    FRadioId: string;
    procedure InternalProcessMessage(sMessage: string);
  public
    Constructor Create(radioId: string);
    property RadioId: string read FRadioId;
  end;

implementation

Constructor TK4Radio.Create(radioId: string);
begin
  FRadioId := radioId;

  // Create a closure that captures radioId
  inherited Create(
    procedure(msg: string)
    begin
      InternalProcessMessage(msg);
    end
  );
end;

procedure TK4Radio.InternalProcessMessage(sMessage: string);
begin
  logger.Trace('[%s ProcessMessage] Received: (%s)', [FRadioId, sMessage]);

  // ... existing ProcessMessage logic

  // Could call global handler with radio ID
  if Assigned(GlobalRadioMessageHandler) then
    GlobalRadioMessageHandler(FRadioId, sMessage);
end;
```

**Benefits:**
- Each radio instance has a unique identifier
- Message handling can be routed based on radio ID
- No global state pollution
- Easy to correlate logs with specific radios

---

## Configuration Management

### Radio Configuration File

**Example JSON configuration:**

```json
{
  "radios": [
    {
      "id": "Radio1",
      "enabled": true,
      "model": "Elecraft K4",
      "connection": {
        "type": "tcp",
        "address": "192.168.1.100",
        "port": 7373
      },
      "role": "SO2R_Main",
      "defaultVFO": "A"
    },
    {
      "id": "Radio2",
      "enabled": true,
      "model": "Elecraft K4",
      "connection": {
        "type": "tcp",
        "address": "192.168.1.101",
        "port": 7373
      },
      "role": "SO2R_Sub",
      "defaultVFO": "A"
    }
  ]
}
```

**Configuration Loader:**

```pascal
unit uRadioConfig;

interface
uses System.JSON, System.Generics.Collections;

type
  TRadioConnectionType = (rctTCP, rctSerial, rctHamLib);

  TRadioConfig = record
    Id: string;
    Enabled: boolean;
    Model: string;
    ConnectionType: TRadioConnectionType;
    Address: string;
    Port: integer;
    Role: string;
    DefaultVFO: TVFO;
  end;

  TRadioConfigLoader = class
  public
    class function LoadFromFile(filename: string): TArray<TRadioConfig>;
    class procedure SaveToFile(filename: string; configs: TArray<TRadioConfig>);
  end;

implementation

class function TRadioConfigLoader.LoadFromFile(filename: string): TArray<TRadioConfig>;
var
  jsonObj: TJSONObject;
  jsonArray: TJSONArray;
  i: integer;
  config: TRadioConfig;
  radioObj: TJSONObject;
begin
  // Parse JSON and populate TRadioConfig array
  // Implementation details...
end;

end.
```

---

## Integration with TR4W

### Recommended Approach

**1. Add RadioManager to MainUnit:**

```pascal
// In MainUnit.pas
var
  RadioManager: TRadioManager;

initialization
  RadioManager := TRadioManager.Create;

finalization
  RadioManager.Free;
```

**2. Load Radio Configuration on Startup:**

```pascal
procedure TMainForm.FormCreate(Sender: TObject);
var
  configs: TArray<TRadioConfig>;
  cfg: TRadioConfig;
  radio: TNetRadioBase;
begin
  configs := TRadioConfigLoader.LoadFromFile('radios.json');

  for cfg in configs do
  begin
    if not cfg.Enabled then
      Continue;

    radio := TRadioFactory.CreateRadio(cfg.Model, cfg.Address, cfg.Port,
      procedure(msg: string)
      begin
        ProcessRadioMessage(cfg.Id, msg);
      end);

    RadioManager.AddRadio(cfg.Id, radio);
  end;

  RadioManager.ConnectAll;
end;
```

**3. Update Existing Radio Commands:**

```pascal
// Current TR4W code expects single radio
procedure SetRadioFrequency(freq: integer);
begin
  // Old way (single radio):
  // Radio.SetFrequency(freq, nrVFOA);

  // New way (multiple radios):
  ActiveRadio := RadioManager.GetRadio(ActiveRadioId);
  if Assigned(ActiveRadio) then
    ActiveRadio.SetFrequency(freq, nrVFOA);
end;
```

---

## Advantages of Factory Pattern

### Extensibility
- **Add new radio models:** Create new class inheriting from `TNetRadioBase`
- **No modification to existing code:** Factory handles instantiation
- **Plugin architecture:** Load radio modules dynamically

### Testability
- **Mock radios:** Create `TMockRadio` for testing without hardware
- **Simulation:** Implement `TSimulatedRadio` for development

### Flexibility
- **Runtime configuration:** Select radios from config file
- **SO2R support:** Manage two radios independently
- **Multi-op support:** Each operator can have different radio model

### Maintainability
- **Centralized creation logic:** All radio instantiation in one place
- **Type safety:** Factory enforces correct types
- **Resource management:** RadioManager handles cleanup

---

## Implementation Recommendations

### Phase 1: Single Radio with Factory
1. Implement `TRadioFactory` with simple enumeration
2. Refactor existing radio creation to use factory
3. Test with existing K4 radio

### Phase 2: Multiple Radio Support
1. Implement `TRadioManager`
2. Add radio ID to message handlers
3. Create configuration file format
4. Test with two K4 radios on different addresses

### Phase 3: Additional Radio Models
1. Implement additional radio classes (Yaesu, Icom, Flex)
2. Register with factory
3. Test mixed radio configurations

### Phase 4: Advanced Features
1. Implement registration pattern for dynamic loading
2. Add radio capability discovery
3. Create radio selection UI

---

## Potential Issues and Solutions

### Issue 1: Thread Safety
**Problem:** Multiple radios = multiple reading threads accessing shared resources

**Solution:**
- Use critical sections for shared state
- Each radio has isolated state in `vfo[]` array
- RadioManager uses thread-safe dictionary

### Issue 2: Resource Cleanup
**Problem:** Ensuring all sockets and threads are properly freed

**Solution:**
- RadioManager destructor handles cleanup
- Use try-finally blocks consistently
- Implement `IInterface` for automatic reference counting (optional)

### Issue 3: Message Handler Complexity
**Problem:** TK4Radio.Create expects `TProcessMsgRef` but also implements `ProcessMessage`

**Solution:**
- Constructor creates internal closure
- Closure routes to instance method with radio ID
- Maintains backward compatibility

### Issue 4: Global State in TR4W
**Problem:** TR4W has global variables for radio state

**Solution:**
- Introduce `ActiveRadioId: string` global
- Access via `RadioManager.GetRadio(ActiveRadioId)`
- Gradually refactor global state into radio instances

---

## Example: Complete Implementation

```pascal
program MultiRadioExample;

uses
  uRadioFactory, uRadioManager, uRadioConfig, uNetRadioBase;

var
  radioManager: TRadioManager;
  configs: TArray<TRadioConfig>;
  cfg: TRadioConfig;
  radio: TNetRadioBase;

begin
  radioManager := TRadioManager.Create;
  try
    // Load configuration
    configs := TRadioConfigLoader.LoadFromFile('radios.json');

    // Create and register radios
    for cfg in configs do
    begin
      if cfg.Enabled then
      begin
        radio := TRadioFactory.CreateRadio(
          cfg.Model,
          cfg.Address,
          cfg.Port,
          procedure(msg: string)
          begin
            WriteLn(Format('[%s] %s', [cfg.Id, msg]));
          end
        );

        radioManager.AddRadio(cfg.Id, radio);
      end;
    end;

    // Connect all radios
    radioManager.ConnectAll;

    // Use radios
    radioManager.GetRadio('Radio1').SetFrequency(14025000, nrVFOA);
    radioManager.GetRadio('Radio2').SetFrequency(7025000, nrVFOA);

    // Wait for input
    ReadLn;

  finally
    radioManager.Free;
  end;
end.
```

---

## Conclusion

The current `TNetRadioBase` / `TK4Radio` architecture is well-suited for a class factory pattern. Key recommendations:

1. **Use Simple Factory initially** - Easiest to implement and test
2. **Implement RadioManager** - Centralizes multi-radio management
3. **Add radio IDs to constructors** - Enables message routing
4. **Load from configuration** - Flexible radio setup without code changes
5. **Gradual migration** - Don't break existing single-radio code

The architecture already provides good separation of concerns:
- Base class handles networking and threading
- Derived classes handle radio-specific protocols
- Factory pattern adds clean instantiation
- Manager pattern adds lifecycle management

This approach supports both current single-radio usage and future multi-radio scenarios (SO2R, multi-op) without breaking existing code.
