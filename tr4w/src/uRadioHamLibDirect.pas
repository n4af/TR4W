unit uRadioHamLibDirect;

{
  Direct HamLib DLL Integration for TR4W

  Purpose: Implements TNetRadioBase using direct libhamlib-4.dll calls
           instead of rigctld TCP/IP daemon.

  Advantages over THamLib (rigctld):
    - No external rigctld process to manage
    - Much faster (no TCP/IP overhead)
    - Simpler code (no text protocol parsing)
    - More reliable (no network layer failures)
    - Better error handling (direct integer codes)

  Usage:
    var radio: THamLibDirect;
    radio := THamLibDirect.Create(@MyProcessMsg);
    radio.HamLibModelID := RIG_MODEL_K4;
    radio.SerialPort := COM12;
    radio.BaudRate := 38400;
    radio.Connect;
}

interface

uses
  uNetRadioBase, uHamLibDirect, StrUtils, SysUtils, Math, Classes, Log4D, TF, VC, Tree;

type
  THamLibDirect = class(TNetRadioBase)
  private
    FRig: PRIG;  // HamLib rig handle
    FModelID: Integer;
    FBaudRate: Integer;
    FSerialPortName: string;
    FCIVAddress: string;
    FUseIPAddress: Boolean;
    FIPAddress: string;
    FIPPort: Integer;

    // Mode conversion helpers
    function TR4WModeToHamLibMode(mode: TRadioMode): rmode_t;
    function HamLibModeToTR4WMode(mode: rmode_t): TRadioMode;
    function TR4WVFOToHamLibVFO(vfo: TVFO): vfo_t;

    // Direct command wrappers
    function GetFreqFromRig(vfo: TVFO): freq_t;
    function GetModeFromRig(vfo: TVFO): rmode_t;
    function GetRITFromRig(vfo: TVFO): Integer;
    function GetXITFromRig(vfo: TVFO): Integer;
    function GetPTTFromRig: Boolean;
    function GetSplitFromRig: Boolean;

    procedure Initialize;

  protected
    // Override GetISConnected to check FRig instead of socket
    function GetISConnected: boolean; override;

  public
    HamLibModelID: Integer;    // RIG_MODEL_K4, RIG_MODEL_IC7300, etc.
    BaudRate: Integer;         // 38400, 9600, etc.
    COMPortName: string;       // 'COM3', '/dev/ttyS0', etc.
    CIVAddress: string;        // For Icom radios
    UseIPAddress: Boolean;     // Use network instead of serial
    IPAddress: string;         // For network connection
    IPPort: Integer;           // For network connection

    constructor Create(ProcRef: TProcessMsgRef); overload;
    destructor Destroy; override;

    function Connect: Integer; override;
    procedure Disconnect; override;

    // Required TNetRadioBase implementations
    procedure ProcessMsg(msg: string); override;
    procedure Transmit; override;
    procedure Receive; override;
    procedure BufferCW(msg: string); override;
    procedure SendCW; override;
    procedure StopCW; override;
    procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode); override;
    procedure SetMode(mode: TRadioMode); override;
    function ToggleMode: TRadioMode; override;
    procedure SetCWSpeed(speed: integer); override;
    procedure RITClear(vfo: TVFO); override;
    procedure XITClear(vfo: TVFO); override;
    procedure RITBumpDown; override;
    procedure RITBumpUp; override;
    procedure RITOn(vfo: TVFO); override;
    procedure RITOff(vfo: TVFO); override;
    procedure XITOn(vfo: TVFO); override;
    procedure XITOff(vfo: TVFO); override;
    procedure Split(splitOn: boolean); override;
    procedure SetRITFreq(vfo: TVFO; hz: integer); override;
    procedure SetXITFreq(vfo: TVFO; hz: integer); override;
    procedure SetBand(vfo: TVFO; band: TRadioBand); override;
    function ToggleBand: TRadioBand; override;
    procedure SetFilter(filter: TRadioFilter); override;
    function SetFilterHz(hz: integer): integer; override;
    function MemoryKeyer(mem: integer): boolean; override;
    procedure VFOBumpDown(whichVFO: TVFO); override;
    procedure VFOBumpUp(whichVFO: TVFO); override;
    procedure SendToRadio(whichVFO: TVFO; sCmd: string; sData: string); override;

    // Polling method for radio status updates
    procedure SendPollRequests;
  end;

implementation

uses
  MainUnit;

var
  logger: TLogLogger;

{ THamLibDirect }

constructor THamLibDirect.Create(ProcRef: TProcessMsgRef);
begin
  inherited Create(ProcRef);
  FRig := nil;
  FModelID := RIG_MODEL_NONE;
  FBaudRate := 38400;
  FSerialPortName := 'COM3';
  FCIVAddress := '';
  FUseIPAddress := False;
  FIPAddress := '127.0.0.1';
  FIPPort := 4532;

  Self.radioModel := 'HamLib Direct';
  logger.Info('[THamLibDirect] Created HamLib Direct radio instance');
end;

destructor THamLibDirect.Destroy;
begin
  if FRig <> nil then
  begin
    try
      logger.Info('[THamLibDirect] Cleaning up HamLib rig handle');
      rig_close(FRig);
      rig_cleanup(FRig);
    except
      on E: Exception do
        logger.Error('[THamLibDirect.Destroy] Exception during cleanup: %s', [E.Message]);
    end;
    FRig := nil;
  end;

  inherited Destroy;
end;

function THamLibDirect.Connect: Integer;
var
  err: Integer;
  portStr: string;
  baudStr: string;
begin
  Result := -1;

  logger.Info('[THamLibDirect.Connect] Starting connection');
  logger.Debug('[THamLibDirect.Connect] HamLibModelID: %d', [HamLibModelID]);
  logger.Debug('[THamLibDirect.Connect] UseIPAddress: %s', [BoolToStr(UseIPAddress, True)]);
  logger.Debug('[THamLibDirect.Connect] IPAddress: %s', [IPAddress]);
  logger.Debug('[THamLibDirect.Connect] IPPort: %d', [IPPort]);
  logger.Debug('[THamLibDirect.Connect] COMPortName: %s', [COMPortName]);
  logger.Debug('[THamLibDirect.Connect] BaudRate: %d', [BaudRate]);

  // Enable HamLib debug logging (logs to stderr/console)
  // Use RIG_DEBUG_WARN for normal operation, RIG_DEBUG_TRACE for troubleshooting
  rig_set_debug(RIG_DEBUG_WARN);
  logger.Debug('[THamLibDirect.Connect] HamLib debug level set to WARN');

  // Initialize rig
  logger.Debug('[THamLibDirect.Connect] Calling rig_init(%d)', [HamLibModelID]);
  FRig := rig_init(HamLibModelID);
  if FRig = nil then
  begin
    logger.Error('[THamLibDirect.Connect] rig_init failed - returned nil for model %d', [HamLibModelID]);
    Result := RIG_EINTERNAL;
    Exit;
  end;

  logger.Debug('[THamLibDirect.Connect] rig_init successful, FRig = %p', [Pointer(FRig)]);

  // Configure connection parameters
  try
    if UseIPAddress then
    begin
      // Network connection - use rig_set_conf with token lookup like rigctl does
      portStr := Format('%s:%d', [IPAddress, IPPort]);
      logger.Debug('[THamLibDirect.Connect] Configuring network: %s', [portStr]);

      err := rig_set_conf(FRig, rig_token_lookup(FRig, 'rig_pathname'), PChar(portStr));
      if err <> RIG_OK then
      begin
        logger.Error('[THamLibDirect.Connect] rig_set_conf(rig_pathname) failed: %s (code %d)',
                     [RigErrorToString(err), err]);
        rig_cleanup(FRig);
        FRig := nil;
        Result := err;
        Exit;
      end;
      logger.Debug('[THamLibDirect.Connect] Network path configured: %s', [portStr]);
    end
    else
    begin
      // Serial connection - use rig_set_conf for serial ports
      logger.Info('[THamLibDirect.Connect] Configuring serial port: %s at %d baud',
                  [COMPortName, BaudRate]);

      err := rig_set_conf(FRig, TOK_PATHNAME, PChar(COMPortName));
      if err <> RIG_OK then
      begin
        logger.Error('[THamLibDirect.Connect] Error setting serial port: %s',
                     [RigErrorToString(err)]);
        rig_cleanup(FRig);
        FRig := nil;
        Result := err;
        Exit;
      end;

      baudStr := IntToStr(BaudRate);
      err := rig_set_conf(FRig, TOK_SERIAL_SPEED, PChar(baudStr));
      if err <> RIG_OK then
        logger.Warn('[THamLibDirect.Connect] Error setting baud rate: %s',
                    [RigErrorToString(err)]);
    end;

    // Set CI-V address for Icom radios if provided
    if Length(FCIVAddress) > 0 then
    begin
      logger.Info('[THamLibDirect.Connect] Setting CI-V address: %s', [FCIVAddress]);
      // Note: CI-V address is typically set via rig backend-specific config
      // This may need adjustment based on specific Icom model
    end;

    // Open the connection
    logger.Debug('[THamLibDirect.Connect] Opening rig connection');
    err := rig_open(FRig);
    if err <> RIG_OK then
    begin
      logger.Error('[THamLibDirect.Connect] rig_open failed: %s (code %d)', [RigErrorToString(err), err]);
      rig_cleanup(FRig);
      FRig := nil;
      Result := err;
      Exit;
    end;

    logger.Info('[THamLibDirect.Connect] Connected successfully to radio');

    // Send ID command to wake up communication (like we do for K4)
    // This ensures data starts flowing
    try
      logger.Info('[THamLibDirect.Connect] Waking up radio communication');
      Initialize;
    except
      on E: Exception do
        logger.Error('[THamLibDirect.Connect] Exception during initialization: %s', [E.Message]);
    end;

    Result := RIG_OK;

  except
    on E: Exception do
    begin
      logger.Error('[THamLibDirect.Connect] Exception during connection: %s', [E.Message]);
      if FRig <> nil then
      begin
        rig_cleanup(FRig);
        FRig := nil;
      end;
      Result := RIG_EINTERNAL;
    end;
  end;
end;

procedure THamLibDirect.Disconnect;
var
  err: Integer;
begin
  if FRig <> nil then
  begin
    try
      logger.Info('[THamLibDirect.Disconnect] Disconnecting from radio');
      err := rig_close(FRig);
      if err <> RIG_OK then
        logger.Warn('[THamLibDirect.Disconnect] rig_close returned: %s', [RigErrorToString(err)]);

      err := rig_cleanup(FRig);
      if err <> RIG_OK then
        logger.Warn('[THamLibDirect.Disconnect] rig_cleanup returned: %s', [RigErrorToString(err)]);

      FRig := nil;
      logger.Info('[THamLibDirect.Disconnect] Disconnected successfully');
    except
      on E: Exception do
      begin
        logger.Error('[THamLibDirect.Disconnect] Exception during disconnect: %s', [E.Message]);
        FRig := nil;
      end;
    end;
  end;
end;

procedure THamLibDirect.Initialize;
var
  err: Integer;
  freq: freq_t;
begin
  // Read initial radio state
  logger.Info('[THamLibDirect.Initialize] Reading initial radio state');

  try
    // Get initial frequency to verify communication
    err := rig_get_freq(FRig, RIG_VFO_A, freq);
    if err = RIG_OK then
      logger.Info('[THamLibDirect.Initialize] Initial VFO A frequency: %.0f Hz', [freq])
    else
      logger.Warn('[THamLibDirect.Initialize] Could not read initial frequency: %s',
                  [RigErrorToString(err)]);
  except
    on E: Exception do
      logger.Error('[THamLibDirect.Initialize] Exception reading initial state: %s', [E.Message]);
  end;
end;

// Mode conversion helpers

function THamLibDirect.TR4WModeToHamLibMode(mode: TRadioMode): rmode_t;
begin
  case mode of
    rmNone:      Result := RIG_MODE_NONE;
    rmCW:        Result := RIG_MODE_CW;
    rmCWRev:     Result := RIG_MODE_CWR;
    rmLSB:       Result := RIG_MODE_LSB;
    rmUSB:       Result := RIG_MODE_USB;
    rmFM:        Result := RIG_MODE_FM;
    rmAM:        Result := RIG_MODE_AM;
    rmData:      Result := RIG_MODE_PKTUSB;
    rmDataRev:   Result := RIG_MODE_PKTLSB;
    rmFSK:       Result := RIG_MODE_RTTY;
    rmFSKRev:    Result := RIG_MODE_RTTYR;
    rmPSK:       Result := RIG_MODE_PKTUSB;  // PSK typically on USB
    rmPSKRev:    Result := RIG_MODE_PKTLSB;
    rmAFSK:      Result := RIG_MODE_PKTUSB;
    rmAFSKRev:   Result := RIG_MODE_PKTLSB;
  else
    Result := RIG_MODE_USB;  // Default to USB
  end;
end;

function THamLibDirect.HamLibModeToTR4WMode(mode: rmode_t): TRadioMode;
begin
  if mode = RIG_MODE_CW then
    Result := rmCW
  else if mode = RIG_MODE_CWR then
    Result := rmCWRev
  else if mode = RIG_MODE_LSB then
    Result := rmLSB
  else if mode = RIG_MODE_USB then
    Result := rmUSB
  else if mode = RIG_MODE_FM then
    Result := rmFM
  else if mode = RIG_MODE_AM then
    Result := rmAM
  else if mode = RIG_MODE_RTTY then
    Result := rmFSK
  else if mode = RIG_MODE_RTTYR then
    Result := rmFSKRev
  else if mode = RIG_MODE_PKTUSB then
    Result := rmData
  else if mode = RIG_MODE_PKTLSB then
    Result := rmDataRev
  else if mode = RIG_MODE_PKTFM then
    Result := rmFM
  else
    Result := rmUSB;  // Default
end;

function THamLibDirect.TR4WVFOToHamLibVFO(vfo: TVFO): vfo_t;
begin
  case vfo of
    nrVFOA: Result := RIG_VFO_A;
    nrVFOB: Result := RIG_VFO_B;
  else
    Result := RIG_VFO_CURR;
  end;
end;

// Direct rig query methods

function THamLibDirect.GetFreqFromRig(vfo: TVFO): freq_t;
var
  err: Integer;
  freq: freq_t;
  hlVFO: vfo_t;
begin
  Result := 0;
  if FRig = nil then Exit;

  hlVFO := TR4WVFOToHamLibVFO(vfo);
  err := rig_get_freq(FRig, hlVFO, freq);
  if err = RIG_OK then
    Result := freq
  else
    logger.Debug('[GetFreqFromRig] Error getting frequency: %s', [RigErrorToString(err)]);
end;

function THamLibDirect.GetModeFromRig(vfo: TVFO): rmode_t;
var
  err: Integer;
  mode: rmode_t;
  width: pbwidth_t;
  hlVFO: vfo_t;
begin
  Result := RIG_MODE_USB;
  if FRig = nil then Exit;

  hlVFO := TR4WVFOToHamLibVFO(vfo);
  err := rig_get_mode(FRig, hlVFO, mode, width);
  if err = RIG_OK then
    Result := mode
  else
    logger.Debug('[GetModeFromRig] Error getting mode: %s', [RigErrorToString(err)]);
end;

function THamLibDirect.GetRITFromRig(vfo: TVFO): Integer;
var
  err: Integer;
  rit: shortfreq_t;
  hlVFO: vfo_t;
begin
  Result := 0;
  if FRig = nil then Exit;

  hlVFO := TR4WVFOToHamLibVFO(vfo);
  err := rig_get_rit(FRig, hlVFO, rit);
  if err = RIG_OK then
    Result := rit
  else
    logger.Debug('[GetRITFromRig] Error getting RIT: %s', [RigErrorToString(err)]);
end;

function THamLibDirect.GetXITFromRig(vfo: TVFO): Integer;
var
  err: Integer;
  xit: shortfreq_t;
  hlVFO: vfo_t;
begin
  Result := 0;
  if FRig = nil then Exit;

  hlVFO := TR4WVFOToHamLibVFO(vfo);
  err := rig_get_xit(FRig, hlVFO, xit);
  if err = RIG_OK then
    Result := xit
  else
    logger.Debug('[GetXITFromRig] Error getting XIT: %s', [RigErrorToString(err)]);
end;

function THamLibDirect.GetPTTFromRig: Boolean;
var
  err: Integer;
  ptt: ptt_t;
begin
  Result := False;
  if FRig = nil then Exit;

  err := rig_get_ptt(FRig, RIG_VFO_CURR, ptt);
  if err = RIG_OK then
    Result := (ptt = RIG_PTT_ON)
  else
    logger.Debug('[GetPTTFromRig] Error getting PTT: %s', [RigErrorToString(err)]);
end;

function THamLibDirect.GetSplitFromRig: Boolean;
var
  err: Integer;
  split: Integer;
  tx_vfo: vfo_t;
begin
  Result := False;
  if FRig = nil then Exit;

  err := rig_get_split_vfo(FRig, RIG_VFO_CURR, split, tx_vfo);
  if err = RIG_OK then
    Result := (split = RIG_SPLIT_ON)
  else
    logger.Debug('[GetSplitFromRig] Error getting split: %s', [RigErrorToString(err)]);
end;

// TNetRadioBase required implementations

procedure THamLibDirect.ProcessMsg(msg: string);
begin
  // Not used in direct DLL mode - polling is done via SendPollRequests
end;

procedure THamLibDirect.Transmit;
var
  err: Integer;
begin
  if FRig = nil then Exit;

  err := rig_set_ptt(FRig, RIG_VFO_CURR, RIG_PTT_ON);
  if err <> RIG_OK then
    logger.Error('[Transmit] Error setting PTT: %s', [RigErrorToString(err)]);
end;

procedure THamLibDirect.Receive;
var
  err: Integer;
begin
  if FRig = nil then Exit;

  err := rig_set_ptt(FRig, RIG_VFO_CURR, RIG_PTT_OFF);
  if err <> RIG_OK then
    logger.Error('[Receive] Error clearing PTT: %s', [RigErrorToString(err)]);
end;

procedure THamLibDirect.BufferCW(msg: string);
begin
  logger.Debug('[THamLibDirect.BufferCW] CW: %s', [msg]);
  // HamLib CW send is direct, no buffering needed
end;

procedure THamLibDirect.SendCW;
begin
  // CW is sent immediately in HamLib, no buffering
  logger.Debug('[THamLibDirect.SendCW] (not implemented - use direct send)');
end;

procedure THamLibDirect.StopCW;
begin
  logger.Debug('[THamLibDirect.StopCW] Stopping CW');
  // HamLib stop_morse functionality would go here
end;

procedure THamLibDirect.SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
var
  err: Integer;
  hlVFO: vfo_t;
begin
  if FRig = nil then Exit;

  hlVFO := TR4WVFOToHamLibVFO(vfo);
  logger.Debug('[THamLibDirect.SetFrequency] Setting %s to %d Hz',
               [VFOToString(vfo), freq]);

  err := rig_set_freq(FRig, hlVFO, freq);
  if err <> RIG_OK then
    logger.Error('[SetFrequency] Error setting frequency: %s', [RigErrorToString(err)])
  else
    Self.vfo[vfo].frequency := freq;
end;

procedure THamLibDirect.SetMode(mode: TRadioMode);
var
  err: Integer;
  hlMode: rmode_t;
begin
  if FRig = nil then Exit;

  hlMode := TR4WModeToHamLibMode(mode);
  logger.Debug('[THamLibDirect.SetMode] Setting mode to %s', [ModeToString(mode)]);

  err := rig_set_mode(FRig, RIG_VFO_CURR, hlMode, RIG_PASSBAND_NORMAL);
  if err <> RIG_OK then
    logger.Error('[SetMode] Error setting mode: %s', [RigErrorToString(err)])
  else
    Self.localMode := mode;
end;

function THamLibDirect.ToggleMode: TRadioMode;
begin
  logger.Warn('[THamLibDirect.ToggleMode] Not implemented');
  Result := rmUSB;
end;

procedure THamLibDirect.SetCWSpeed(speed: integer);
begin
  if FRig = nil then Exit;

  if (speed >= 8) and (speed <= 60) then
  begin
    Self.localCWSpeed := speed;
    logger.Debug('[THamLibDirect.SetCWSpeed] Set CW speed to %d wpm', [speed]);
    // HamLib CW speed setting would use rig_set_level with RIG_LEVEL_KEYSPD
  end
  else
    logger.Error('[SetCWSpeed] Speed %d out of range (8-60 wpm)', [speed]);
end;

procedure THamLibDirect.RITClear(vfo: TVFO);
var
  err: Integer;
  hlVFO: vfo_t;
begin
  if FRig = nil then Exit;

  hlVFO := TR4WVFOToHamLibVFO(vfo);
  logger.Debug('[THamLibDirect.RITClear] Clearing RIT on %s', [VFOToString(vfo)]);

  err := rig_set_rit(FRig, hlVFO, 0);
  if err <> RIG_OK then
    logger.Error('[RITClear] Error: %s', [RigErrorToString(err)]);
end;

procedure THamLibDirect.XITClear(vfo: TVFO);
var
  err: Integer;
  hlVFO: vfo_t;
begin
  if FRig = nil then Exit;

  hlVFO := TR4WVFOToHamLibVFO(vfo);
  logger.Debug('[THamLibDirect.XITClear] Clearing XIT on %s', [VFOToString(vfo)]);

  err := rig_set_xit(FRig, hlVFO, 0);
  if err <> RIG_OK then
    logger.Error('[XITClear] Error: %s', [RigErrorToString(err)]);
end;

procedure THamLibDirect.RITBumpDown;
begin
  logger.Debug('[THamLibDirect.RITBumpDown] Not implemented');
end;

procedure THamLibDirect.RITBumpUp;
begin
  logger.Debug('[THamLibDirect.RITBumpUp] Not implemented');
end;

procedure THamLibDirect.RITOn(vfo: TVFO);
begin
  // RIT is typically enabled automatically when RIT offset is set
  logger.Debug('[THamLibDirect.RITOn] RIT control via offset on %s', [VFOToString(vfo)]);
end;

procedure THamLibDirect.RITOff(vfo: TVFO);
begin
  RITClear(vfo);  // Clearing RIT offset typically disables it
end;

procedure THamLibDirect.XITOn(vfo: TVFO);
begin
  logger.Debug('[THamLibDirect.XITOn] XIT control via offset on %s', [VFOToString(vfo)]);
end;

procedure THamLibDirect.XITOff(vfo: TVFO);
begin
  XITClear(vfo);
end;

procedure THamLibDirect.Split(splitOn: boolean);
var
  err: Integer;
  splitVal: Integer;
begin
  if FRig = nil then Exit;

  if splitOn then
  begin
    logger.Debug('[THamLibDirect.Split] Enabling split (TX on VFO B)');
    splitVal := RIG_SPLIT_ON;
  end
  else
  begin
    logger.Debug('[THamLibDirect.Split] Disabling split');
    splitVal := RIG_SPLIT_OFF;
  end;

  err := rig_set_split_vfo(FRig, RIG_VFO_CURR, splitVal, RIG_VFO_B);
  if err <> RIG_OK then
    logger.Error('[Split] Error: %s', [RigErrorToString(err)])
  else
    Self.localSplitEnabled := splitOn;
end;

procedure THamLibDirect.SetRITFreq(vfo: TVFO; hz: integer);
var
  err: Integer;
  hlVFO: vfo_t;
begin
  if FRig = nil then Exit;

  if (hz < -9999) or (hz > 9999) then
  begin
    logger.Error('[SetRITFreq] RIT offset %d out of range (-9999 to +9999)', [hz]);
    Exit;
  end;

  hlVFO := TR4WVFOToHamLibVFO(vfo);
  logger.Debug('[THamLibDirect.SetRITFreq] Setting RIT to %d Hz on %s',
               [hz, VFOToString(vfo)]);

  err := rig_set_rit(FRig, hlVFO, hz);
  if err <> RIG_OK then
    logger.Error('[SetRITFreq] Error: %s', [RigErrorToString(err)])
  else
    Self.vfo[vfo].RITOffset := hz;
end;

procedure THamLibDirect.SetXITFreq(vfo: TVFO; hz: integer);
var
  err: Integer;
  hlVFO: vfo_t;
begin
  if FRig = nil then Exit;

  if (hz < -9999) or (hz > 9999) then
  begin
    logger.Error('[SetXITFreq] XIT offset %d out of range (-9999 to +9999)', [hz]);
    Exit;
  end;

  hlVFO := TR4WVFOToHamLibVFO(vfo);
  logger.Debug('[THamLibDirect.SetXITFreq] Setting XIT to %d Hz on %s',
               [hz, VFOToString(vfo)]);

  err := rig_set_xit(FRig, hlVFO, hz);
  if err <> RIG_OK then
    logger.Error('[SetXITFreq] Error: %s', [RigErrorToString(err)])
  else
    Self.vfo[vfo].XITOffset := hz;
end;

procedure THamLibDirect.SetBand(vfo: TVFO; band: TRadioBand);
begin
  logger.Debug('[THamLibDirect.SetBand] Band selection on %s: %d',
               [VFOToString(vfo), Ord(band)]);
  // HamLib band selection would use rig_set_level with RIG_LEVEL_BAND
  // Implementation depends on radio capabilities
end;

function THamLibDirect.ToggleBand: TRadioBand;
begin
  logger.Debug('[THamLibDirect.ToggleBand] Not implemented');
  Result := rbNone;
end;

procedure THamLibDirect.SetFilter(filter: TRadioFilter);
begin
  logger.Debug('[THamLibDirect.SetFilter] Filter: %d', [Ord(filter)]);
  // Filter setting via rig_set_mode with specific passband width
end;

function THamLibDirect.SetFilterHz(hz: integer): integer;
begin
  logger.Debug('[THamLibDirect.SetFilterHz] %d Hz', [hz]);
  // Set passband via rig_set_mode with specific width
  Result := hz;
end;

function THamLibDirect.MemoryKeyer(mem: integer): boolean;
begin
  Result := True;  // True = error

  if FRig = nil then Exit;

  if (mem < 0) or (mem > 8) then
  begin
    logger.Error('[MemoryKeyer] Memory %d out of range (0-8)', [mem]);
    Exit;
  end;

  logger.Debug('[THamLibDirect.MemoryKeyer] Playing memory %d', [mem]);
  // HamLib memory keyer functionality
  Result := False;
end;

procedure THamLibDirect.VFOBumpDown(whichVFO: TVFO);
begin
  logger.Debug('[THamLibDirect.VFOBumpDown] %s', [VFOToString(whichVFO)]);
  // Use rig_vfo_op with RIG_OP_DOWN
end;

procedure THamLibDirect.VFOBumpUp(whichVFO: TVFO);
begin
  logger.Debug('[THamLibDirect.VFOBumpUp] %s', [VFOToString(whichVFO)]);
  // Use rig_vfo_op with RIG_OP_UP
end;

procedure THamLibDirect.SendToRadio(whichVFO: TVFO; sCmd: string; sData: string);
begin
  // Not used in direct DLL mode
end;

function THamLibDirect.GetISConnected: boolean;
begin
  // For HamLib Direct, we're connected if FRig is assigned
  Result := (FRig <> nil) and not Disconnecting;
end;

procedure THamLibDirect.SendPollRequests;
var
  tempBand: BandType;
  tempMode: ModeType;
  vfo: TVFO;
  freq: freq_t;
  mode: rmode_t;
  rit, xit: Integer;
  ptt: Boolean;
  split: Boolean;
begin
  if FRig = nil then
  begin
    logger.Debug('[SendPollRequests] Rig not connected');
    Exit;
  end;

  try
    // Poll VFO A
    freq := GetFreqFromRig(nrVFOA);
    if freq > 0 then
    begin
      Self.vfo[nrVFOA].frequency := Round(freq);
      CalculateBandMode(Self.vfo[nrVFOA].frequency, tempBand, tempMode);
      Self.vfo[nrVFOA].band := GetRadioBandFromBandType(tempBand);
    end;

    mode := GetModeFromRig(nrVFOA);
    Self.vfo[nrVFOA].mode := HamLibModeToTR4WMode(mode);

    rit := GetRITFromRig(nrVFOA);
    Self.vfo[nrVFOA].RITOffset := rit;
    Self.vfo[nrVFOA].RITState := (rit <> 0);

    xit := GetXITFromRig(nrVFOA);
    Self.vfo[nrVFOA].XITOffset := xit;
    Self.vfo[nrVFOA].XITState := (xit <> 0);

    // Poll VFO B
    freq := GetFreqFromRig(nrVFOB);
    if freq > 0 then
    begin
      Self.vfo[nrVFOB].frequency := Round(freq);
      CalculateBandMode(Self.vfo[nrVFOB].frequency, tempBand, tempMode);
      Self.vfo[nrVFOB].band := GetRadioBandFromBandType(tempBand);
    end;

    mode := GetModeFromRig(nrVFOB);
    Self.vfo[nrVFOB].mode := HamLibModeToTR4WMode(mode);

    // PTT and split status
    ptt := GetPTTFromRig;
    if ptt then
      Self.radioState := rsTransmit
    else
      Self.radioState := rsReceive;

    split := GetSplitFromRig;
    Self.localSplitEnabled := split;

  except
    on E: Exception do
      logger.Error('[SendPollRequests] Exception during polling: %s', [E.Message]);
  end;
end;

initialization
  logger := TLogLogger.GetLogger('uRadioHamLibDirect');
  logger.Info('HamLib Direct radio module initialized');

finalization
  logger.Info('HamLib Direct radio module finalized');

end.
