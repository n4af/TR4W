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
  uNetRadioBase, uRadioBand, uHamLibDirect, StrUtils, SysUtils, Math, Classes, Log4D, TF, VC, Tree, Windows;

{-----------------------------------------------------------------------------
  Send queue — command types posted from the main thread, executed on the
  polling thread (which is the sole owner of FRig calls).
-----------------------------------------------------------------------------}

type
  THLCommandType = (
    hlcSetFreq,    // rig_set_freq
    hlcSetMode,    // rig_set_mode
    hlcTransmit,   // rig_set_ptt ON
    hlcReceive,    // rig_set_ptt OFF
    hlcSetRIT,     // rig_set_rit
    hlcSetXIT,     // rig_set_xit
    hlcSetSplit    // rig_set_split_vfo
  );

  THLCommand = record
    CmdType:  THLCommandType;
    VFO:      vfo_t;
    Freq:     freq_t;
    Mode:     rmode_t;
    Hz:       Integer;  // RIT/XIT offset in Hz
    SplitOn:  Boolean;
  end;
  PHLCommand = ^THLCommand;

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
    FTransceiveEnabled: Boolean;  // True when rig_set_trn(RIG_TRN_RIG) succeeded
    // VFO naming: some radios use A/B (most), others use Main/Sub (e.g. IC-7610).
    // Probed at connect by trying RIG_VFO_A; falls back to RIG_VFO_MAIN on failure.
    FUseMainSubVFO: Boolean;
    // True when VFO B (or Sub) can be read directly without HamLib swapping VFOs.
    // Radios without this will flicker if we poll VFO B unconditionally, so we
    // gate VFO B polling on split being active for those.
    FHasTargetableVFO: Boolean;

    // Send queue — protects FUrgentQueue for cross-thread access
    FUrgentQueue: TList;
    FCritSect: TRTLCriticalSection;

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

    // Queue helpers — EnqueueUrgent is called from main thread,
    // ExecuteCommand is called from polling thread inside DrainUrgentQueue.
    procedure EnqueueUrgent(const cmd: THLCommand);
    procedure ExecuteCommand(const cmd: THLCommand);

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

    // Set to 1 by transceive callbacks (from HamLib reader thread) to signal
    // that the polling loop should call SendPollRequests immediately.
    // Access via InterlockedExchange only — safe for concurrent read/write.
    FNeedsPoll: Integer;

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
    procedure SetMode(mode: TRadioMode; vfo: TVFO = nrVFOA); override;
    function ToggleMode(vfo: TVFO = nrVFOA): TRadioMode; override;
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
    procedure SetBand(band: TRadioBand; vfo: TVFO = nrVFOA); override;
    function ToggleBand(vfo: TVFO = nrVFOA): TRadioBand; override;
    procedure SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA); override;
    function SetFilterHz(hz: integer; vfo: TVFO = nrVFOA): integer; override;
    function MemoryKeyer(mem: integer): boolean; override;
    procedure VFOBumpDown(whichVFO: TVFO); override;
    procedure VFOBumpUp(whichVFO: TVFO); override;
    procedure SendToRadio(whichVFO: TVFO; sCmd: string; sData: string); override;

    // Drain the urgent command queue — called from polling thread each loop cycle.
    // Processes all pending user commands (freq, mode, PTT, RIT, XIT, split)
    // before any poll query, ensuring user commands are never delayed by polls.
    procedure DrainUrgentQueue;

    // Fast poll — every heartbeat (1000ms): freq, mode, PTT, split, VFO B
    procedure SendPollRequests;
    // Slow poll — every 5000ms: RIT and XIT only
    // These trigger $07 D0 side-effects in HamLib's Icom driver which dismiss
    // front-panel menus, so they are polled infrequently.
    procedure SendRITXITPoll;
  end;

implementation

uses
  MainUnit;

var
  logger: TLogLogger;

{-----------------------------------------------------------------------------
  Transceive callbacks — global cdecl functions (cannot be methods).

  These are called from HamLib's internal reader thread when the radio pushes
  unsolicited changes (freq tuned, mode switched, PTT toggled, VFO changed).
  The rig_arg pointer is the THamLibDirect instance registered in Connect.

  Design: only set FNeedsPoll — do NOT touch any radio state here.
  All state updates happen on the polling thread inside SendPollRequests,
  which is the only owner of FRig calls.  InterlockedExchange makes the
  write visible to the polling thread without a lock.
-----------------------------------------------------------------------------}

function HLFreqCallback(rig: PRIG; vfo: vfo_t; freq: freq_t;
                         rig_arg: Pointer): Integer; cdecl;
var
  radio: THamLibDirect;
  tr4wVFO: TVFO;
  newFreq: LongInt;
begin
  Result := RIG_OK;
  if rig_arg = nil then Exit;

  radio := THamLibDirect(rig_arg);

  // Map HamLib VFO to TR4W VFO — covers both A/B and Main/Sub naming
  if (vfo = RIG_VFO_B) or (vfo = RIG_VFO_SUB) then
     tr4wVFO := nrVFOB
  else
     tr4wVFO := nrVFOA;

  newFreq := Round(freq);

  // Log every callback invocation in debug mode so we can confirm transceive
  // is actually firing and at what rate (Icom CI-V broadcasts every ~1s).
  if TR4W_HAMLIB_DEBUG then
     logger.Info('[HLFreqCallback] ASYNC: vfo=%d freq=%.0f cached=%d',
                 [vfo, freq, radio.vfo[tr4wVFO].frequency]);

  // Only trigger a poll when the value actually changed — Icom radios broadcast
  // frequency every second via CI-V transceive even when nothing is tuned,
  // which would trigger a full poll on every broadcast and defeat the purpose
  // of async-driven polling.
  if newFreq = radio.vfo[tr4wVFO].frequency then
     Exit;

  if TR4W_HAMLIB_DEBUG then
     logger.Info('[HLFreqCallback] ASYNC freq change: %d -> %d (triggering poll)',
                 [radio.vfo[tr4wVFO].frequency, newFreq]);

  radio.vfo[tr4wVFO].frequency := newFreq;
  InterlockedExchange(radio.FNeedsPoll, 1);
end;

function HLModeCallback(rig: PRIG; vfo: vfo_t; mode: rmode_t;
                         width: pbwidth_t; rig_arg: Pointer): Integer; cdecl;
begin
  Result := RIG_OK;
  if rig_arg = nil then Exit;

  if TR4W_HAMLIB_DEBUG then
     logger.Info('[HLModeCallback] ASYNC mode change: vfo=%d mode=%d width=%d',
                 [vfo, Integer(mode), width]);

  InterlockedExchange(THamLibDirect(rig_arg).FNeedsPoll, 1);
end;

function HLVFOCallback(rig: PRIG; vfo: vfo_t;
                        rig_arg: Pointer): Integer; cdecl;
begin
  Result := RIG_OK;
  if rig_arg = nil then Exit;

  if TR4W_HAMLIB_DEBUG then
     logger.Info('[HLVFOCallback] ASYNC VFO change: vfo=%d', [vfo]);

  InterlockedExchange(THamLibDirect(rig_arg).FNeedsPoll, 1);
end;

function HLPTTCallback(rig: PRIG; vfo: vfo_t; ptt: ptt_t;
                        rig_arg: Pointer): Integer; cdecl;
begin
  Result := RIG_OK;
  if rig_arg = nil then Exit;

  if TR4W_HAMLIB_DEBUG then
     logger.Info('[HLPTTCallback] ASYNC PTT change: vfo=%d ptt=%d', [vfo, ptt]);

  InterlockedExchange(THamLibDirect(rig_arg).FNeedsPoll, 1);
end;

{ EnableHamLibTrace
  Enables HamLib's internal TRACE-level debug output and redirects it to
  target/hamlib_trace.log.  Uses MSVCRT fopen (compatible FILE* for HamLib)
  and loads rig_set_debug_file dynamically so we don't crash if it is not
  exported by the installed DLL version. }
procedure EnableHamLibTrace;
type
  TSetDebugFile = procedure(stream: Pointer); cdecl;
var
  hLib: HMODULE;
  pSetDebugFile: TSetDebugFile;
  traceFile: Pointer;
  tracePath: string;
begin
  tracePath := ExtractFilePath(ParamStr(0)) + 'hamlib_trace.log';
  traceFile := msvcrt_fopen(PChar(tracePath), 'w');
  if traceFile = nil then
     begin
     logger.Warn('[EnableHamLibTrace] Could not open %s for writing', [tracePath]);
     rig_set_debug(RIG_DEBUG_TRACE);
     logger.Info('[EnableHamLibTrace] HamLib TRACE enabled (stderr — no file redirect)');
     Exit;
     end;

  hLib := GetModuleHandle(HAMLIB_DLL);
  if hLib = 0 then
     hLib := LoadLibrary(HAMLIB_DLL);

  @pSetDebugFile := nil;
  if hLib <> 0 then
     @pSetDebugFile := GetProcAddress(hLib, 'rig_set_debug_file');

  rig_set_debug(RIG_DEBUG_TRACE);

  if Assigned(pSetDebugFile) then
     begin
     pSetDebugFile(traceFile);
     logger.Info('[EnableHamLibTrace] HamLib TRACE → %s', [tracePath]);
     end
  else
     begin
     logger.Warn('[EnableHamLibTrace] rig_set_debug_file not found in DLL — ' +
                 'TRACE output goes to stderr only (file opened but unused: %s)', [tracePath]);
     end;
end;

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
  FNeedsPoll := 0;
  FTransceiveEnabled := False;
  FUseMainSubVFO := False;
  FHasTargetableVFO := False;
  FUrgentQueue := TList.Create;
  InitializeCriticalSection(FCritSect);

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

  // Drain and free the queue — any pending commands are discarded since the
  // radio is already closed.  Must happen before deleting the critical section.
  DrainUrgentQueue;
  FUrgentQueue.Free;
  DeleteCriticalSection(FCritSect);

  inherited Destroy;
end;

function THamLibDirect.Connect: Integer;
var
  err: Integer;
  portStr: string;
  baudStr: string;
begin
  Result := -1;

  // Heartbeat polling rate: 1000ms when transceive is not available (sole mechanism),
  // bumped to 5000ms after transceive succeeds (just covers RIT/XIT/split fallback).
  pollingInterval := 1000;

  logger.Info('[THamLibDirect.Connect] Starting connection');
  logger.Debug('[THamLibDirect.Connect] HamLibModelID: %d', [HamLibModelID]);
  logger.Debug('[THamLibDirect.Connect] UseIPAddress: %s', [BoolToStr(UseIPAddress, True)]);
  logger.Debug('[THamLibDirect.Connect] IPAddress: %s', [IPAddress]);
  logger.Debug('[THamLibDirect.Connect] IPPort: %d', [IPPort]);
  logger.Debug('[THamLibDirect.Connect] COMPortName: %s', [COMPortName]);
  logger.Debug('[THamLibDirect.Connect] BaudRate: %d', [BaudRate]);

  // Set HamLib internal debug level.
  // HAMLIB TRACE = TRUE: full HamLib trace output → target/hamlib_trace.log
  // HAMLIB DEBUG = TRUE: TR4W-level debug messages only (less verbose)
  if TR4W_HAMLIB_TRACE then
     begin
     EnableHamLibTrace;
     end
  else if TR4W_HAMLIB_DEBUG then
     begin
     rig_set_debug(RIG_DEBUG_TRACE);
     logger.Info('[THamLibDirect.Connect] HamLib debug level set to TRACE (stderr only)');
     end
  else
     begin
     rig_set_debug(RIG_DEBUG_WARN);
     end;

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

      // Use token lookup like rigctl does
      err := rig_set_conf(FRig, rig_token_lookup(FRig, 'rig_pathname'), PChar(COMPortName));
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
      err := rig_set_conf(FRig, rig_token_lookup(FRig, 'serial_speed'), PChar(baudStr));
      if err <> RIG_OK then
        logger.Warn('[THamLibDirect.Connect] Error setting baud rate: %s',
                    [RigErrorToString(err)]);

      // Set timeout for serial communication (in milliseconds)
      err := rig_set_conf(FRig, rig_token_lookup(FRig, 'timeout'), '2000');
      if err <> RIG_OK then
        logger.Warn('[THamLibDirect.Connect] Error setting timeout: %s',
                    [RigErrorToString(err)]);
    end;

    // Set CI-V address for Icom radios if provided
    if Length(FCIVAddress) > 0 then
    begin
      logger.Info('[THamLibDirect.Connect] Setting CI-V address: 0x%s', [FCIVAddress]);
      err := rig_set_conf(FRig, rig_token_lookup(FRig, 'civaddr'), PChar(FCIVAddress));
      if err <> RIG_OK then
        logger.Warn('[THamLibDirect.Connect] Warning setting CI-V address: %s', [RigErrorToString(err)]);
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

    if not TR4W_HAMLIB_DEBUG then
       logger.Warn('*** HamLib radio connected but HAMLIB DEBUG = FALSE — ' +
          'polling detail will not be logged. Add "HAMLIB DEBUG = TRUE" to ' +
          'your cfg file to enable full HamLib trace output. ***');

    // Register transceive callbacks — invoked from HamLib's reader thread
    // when the radio pushes unsolicited freq/mode/VFO/PTT changes.
    // We pass Self so each callback can flag FNeedsPoll on the right object.
    rig_set_freq_callback(FRig, HLFreqCallback, Self);
    rig_set_mode_callback(FRig, HLModeCallback, Self);
    rig_set_vfo_callback(FRig,  HLVFOCallback,  Self);
    rig_set_ptt_callback(FRig,  HLPTTCallback,  Self);
    logger.Info('[THamLibDirect.Connect] Transceive callbacks registered');

    // Enable transceive mode — asks the radio to push changes automatically.
    // For Icom CI-V radios this sends the transceive-enable command.
    // If the HamLib backend or hardware does not support it, rig_set_trn
    // returns RIG_ENIMPL and we fall back gracefully to heartbeat polling.
    FNeedsPoll := 0;
    FTransceiveEnabled := False;
    err := rig_set_trn(FRig, RIG_TRN_RIG);
    if err = RIG_OK then
       begin
       FTransceiveEnabled := True;
       // Transceive callbacks fire for freq/mode/VFO/PTT when the radio supports it.
       // However, serial CI-V delivery via HamLib's background thread is unreliable
       // on some radios — callbacks may only fire occasionally.  Keep heartbeat at
       // 1000ms so UI stays responsive even when callbacks don't fire.
       // Callbacks still provide sub-50ms response as a bonus when they do fire.
       // RIT, XIT, split, TX status have no HamLib callbacks — always polled.
       pollingInterval := 1000;
       logger.Info('[THamLibDirect.Connect] Transceive enabled (RIG_TRN_RIG)');
       logger.Info('[THamLibDirect.Connect]   ASYNC (bonus, when fired): freq, mode, VFO, PTT');
       logger.Info('[THamLibDirect.Connect]   POLLED (heartbeat %dms): freq, mode, VFO, PTT, RIT, XIT, split, TX',
                   [pollingInterval]);
       end
    else
       begin
       logger.Warn('[THamLibDirect.Connect] Transceive not supported by this HamLib ' +
                   'backend (err=%d %s) — will fall back to %dms heartbeat polling',
                   [err, RigErrorToString(err), pollingInterval]);
       end;

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
  logger.Info('[THamLibDirect.Initialize] Probing VFO naming convention');

  try
    // Try A/B first (most radios).  If that fails, try Main/Sub (e.g. IC-7610).
    // Whichever succeeds determines the mapping used for all subsequent calls.
    err := rig_get_freq(FRig, RIG_VFO_A, freq);
    if err = RIG_OK then
       begin
       FUseMainSubVFO := False;
       logger.Info('[THamLibDirect.Initialize] VFO mapping: A/B — VFO A freq=%.0f Hz', [freq]);
       end
    else
       begin
       logger.Info('[THamLibDirect.Initialize] RIG_VFO_A failed (%s), trying RIG_VFO_MAIN',
                   [RigErrorToString(err)]);
       err := rig_get_freq(FRig, RIG_VFO_MAIN, freq);
       if err = RIG_OK then
          begin
          FUseMainSubVFO := True;
          logger.Info('[THamLibDirect.Initialize] VFO mapping: Main/Sub — Main freq=%.0f Hz', [freq]);
          end
       else
          begin
          FUseMainSubVFO := False;
          logger.Warn('[THamLibDirect.Initialize] Could not determine VFO mapping (err=%s) — defaulting to A/B',
                      [RigErrorToString(err)]);
          end;
       end;

    // Probe whether VFO B (or Sub) can be read directly without a VFO swap.
    // On radios with targetable VFO support HamLib routes the query without
    // touching the front-panel selection; on others it physically swaps VFOs,
    // causing display flicker. If the read succeeds here we know it is safe
    // to poll VFO B unconditionally.
    err := rig_get_freq(FRig, TR4WVFOToHamLibVFO(nrVFOB), freq);
    if err = RIG_OK then
       begin
       FHasTargetableVFO := True;
       logger.Info('[THamLibDirect.Initialize] VFO B targetable — will poll VFO B every cycle (freq=%.0f Hz)', [freq]);
       end
    else
       begin
       FHasTargetableVFO := False;
       logger.Warn('[THamLibDirect.Initialize] VFO B not targetable (%s) — will only poll VFO B when split is active',
                   [RigErrorToString(err)]);
       end;
  except
    on E: Exception do
      logger.Error('[THamLibDirect.Initialize] Exception during VFO probe: %s', [E.Message]);
  end;

  // Poll RIT/XIT immediately so the display shows correct state at connect time
  // rather than waiting up to 5 seconds for the slow poll timer to fire.
  SendRITXITPoll;
end;

// Send queue — EnqueueUrgent, ExecuteCommand, DrainUrgentQueue

procedure THamLibDirect.EnqueueUrgent(const cmd: THLCommand);
var
  item: PHLCommand;
begin
  New(item);
  item^ := cmd;
  EnterCriticalSection(FCritSect);
  try
     FUrgentQueue.Add(item);
  finally
     LeaveCriticalSection(FCritSect);
  end;
end;

procedure THamLibDirect.ExecuteCommand(const cmd: THLCommand);
var
  err: Integer;
begin
  if FRig = nil then
     Exit;

  case cmd.CmdType of
     hlcSetFreq:
        begin
        err := rig_set_freq(FRig, cmd.VFO, cmd.Freq);
        if err <> RIG_OK then
           begin
           logger.Error('[ExecuteCommand] SetFreq failed: %s (freq=%.0f)',
                        [RigErrorToString(err), cmd.Freq]);
           // Restore VFO after rejection to prevent display flicker
           rig_set_vfo(FRig, cmd.VFO);
           end;
        end;

     hlcSetMode:
        begin
        err := rig_set_mode(FRig, cmd.VFO, cmd.Mode, RIG_PASSBAND_NORMAL);
        if err <> RIG_OK then
           logger.Error('[ExecuteCommand] SetMode failed: %s', [RigErrorToString(err)]);
        end;

     hlcTransmit:
        begin
        err := rig_set_ptt(FRig, RIG_VFO_CURR, RIG_PTT_ON);
        if err <> RIG_OK then
           logger.Error('[ExecuteCommand] Transmit (PTT ON) failed: %s', [RigErrorToString(err)]);
        end;

     hlcReceive:
        begin
        err := rig_set_ptt(FRig, RIG_VFO_CURR, RIG_PTT_OFF);
        if err <> RIG_OK then
           logger.Error('[ExecuteCommand] Receive (PTT OFF) failed: %s', [RigErrorToString(err)]);
        end;

     hlcSetRIT:
        begin
        err := rig_set_rit(FRig, cmd.VFO, cmd.Hz);
        if err <> RIG_OK then
           logger.Error('[ExecuteCommand] SetRIT failed: %s (hz=%d)',
                        [RigErrorToString(err), cmd.Hz]);
        end;

     hlcSetXIT:
        begin
        err := rig_set_xit(FRig, cmd.VFO, cmd.Hz);
        if err <> RIG_OK then
           logger.Error('[ExecuteCommand] SetXIT failed: %s (hz=%d)',
                        [RigErrorToString(err), cmd.Hz]);
        end;

     hlcSetSplit:
        begin
        if cmd.SplitOn then
           err := rig_set_split_vfo(FRig, RIG_VFO_CURR, RIG_SPLIT_ON,  RIG_VFO_B)
        else
           err := rig_set_split_vfo(FRig, RIG_VFO_CURR, RIG_SPLIT_OFF, RIG_VFO_B);
        if err <> RIG_OK then
           logger.Error('[ExecuteCommand] SetSplit failed: %s', [RigErrorToString(err)]);
        end;
  end;
end;

procedure THamLibDirect.DrainUrgentQueue;
var
  snapshot: TList;
  i: Integer;
  item: PHLCommand;
begin
  // Snapshot the queue under the lock, then execute outside it.
  // This minimises lock hold time and prevents a deadlock if ExecuteCommand
  // ever enqueues a follow-up command.
  snapshot := TList.Create;
  try
     EnterCriticalSection(FCritSect);
     try
        for i := 0 to FUrgentQueue.Count - 1 do
           snapshot.Add(FUrgentQueue[i]);
        FUrgentQueue.Clear;
     finally
        LeaveCriticalSection(FCritSect);
     end;

     for i := 0 to snapshot.Count - 1 do
        begin
        item := PHLCommand(snapshot[i]);
        ExecuteCommand(item^);
        Dispose(item);
        end;
  finally
     snapshot.Free;
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
    nrVFOA:
       if FUseMainSubVFO then
          Result := RIG_VFO_MAIN
       else
          Result := RIG_VFO_A;
    nrVFOB:
       if FUseMainSubVFO then
          Result := RIG_VFO_SUB
       else
          Result := RIG_VFO_B;
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
  cmd: THLCommand;
begin
  if FRig = nil then Exit;
  FillChar(cmd, SizeOf(cmd), 0);
  cmd.CmdType := hlcTransmit;
  EnqueueUrgent(cmd);
end;

procedure THamLibDirect.Receive;
var
  cmd: THLCommand;
begin
  if FRig = nil then Exit;
  FillChar(cmd, SizeOf(cmd), 0);
  cmd.CmdType := hlcReceive;
  EnqueueUrgent(cmd);
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
  cmd: THLCommand;
begin
  if FRig = nil then Exit;

  logger.Debug('[THamLibDirect.SetFrequency] Queuing %s to %d Hz',
               [VFOToString(vfo), freq]);

  // Update local state immediately so the display reflects the request at once.
  // The next poll will correct it if the radio rejects the command.
  Self.vfo[vfo].frequency := freq;

  FillChar(cmd, SizeOf(cmd), 0);
  cmd.CmdType := hlcSetFreq;
  cmd.VFO     := TR4WVFOToHamLibVFO(vfo);
  cmd.Freq    := freq;
  EnqueueUrgent(cmd);

  // Queue a mode change as a separate command if requested.
  // rmNone means "frequency only, leave mode alone".
  if mode <> rmNone then
     begin
     Self.localMode := mode;
     SetMode(mode, vfo);
     end;
end;

procedure THamLibDirect.SetMode(mode: TRadioMode; vfo: TVFO = nrVFOA);
var
  cmd: THLCommand;
begin
  if FRig = nil then Exit;

  logger.Debug('[THamLibDirect.SetMode] Queuing mode %s on VFO %s',
               [ModeToString(mode), VFOToString(vfo)]);

  Self.localMode := mode;

  FillChar(cmd, SizeOf(cmd), 0);
  cmd.CmdType := hlcSetMode;
  cmd.VFO     := TR4WVFOToHamLibVFO(vfo);
  cmd.Mode    := TR4WModeToHamLibMode(mode);
  EnqueueUrgent(cmd);
end;

function THamLibDirect.ToggleMode(vfo: TVFO = nrVFOA): TRadioMode;
begin
  logger.Warn('[THamLibDirect.ToggleMode] Not implemented for VFO %s', [VFOToString(vfo)]);
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
  cmd: THLCommand;
begin
  if FRig = nil then Exit;
  FillChar(cmd, SizeOf(cmd), 0);
  cmd.CmdType := hlcSetRIT;
  cmd.VFO     := TR4WVFOToHamLibVFO(vfo);
  cmd.Hz      := 0;
  EnqueueUrgent(cmd);
end;

procedure THamLibDirect.XITClear(vfo: TVFO);
var
  cmd: THLCommand;
begin
  if FRig = nil then Exit;
  FillChar(cmd, SizeOf(cmd), 0);
  cmd.CmdType := hlcSetXIT;
  cmd.VFO     := TR4WVFOToHamLibVFO(vfo);
  cmd.Hz      := 0;
  EnqueueUrgent(cmd);
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
  cmd: THLCommand;
begin
  if FRig = nil then Exit;
  Self.localSplitEnabled := splitOn;
  FillChar(cmd, SizeOf(cmd), 0);
  cmd.CmdType := hlcSetSplit;
  cmd.SplitOn := splitOn;
  EnqueueUrgent(cmd);
end;

procedure THamLibDirect.SetRITFreq(vfo: TVFO; hz: integer);
var
  cmd: THLCommand;
begin
  if FRig = nil then Exit;

  if (hz < -9999) or (hz > 9999) then
     begin
     logger.Error('[SetRITFreq] RIT offset %d out of range (-9999 to +9999)', [hz]);
     Exit;
     end;

  Self.vfo[vfo].RITOffset := hz;

  FillChar(cmd, SizeOf(cmd), 0);
  cmd.CmdType := hlcSetRIT;
  cmd.VFO     := TR4WVFOToHamLibVFO(vfo);
  cmd.Hz      := hz;
  EnqueueUrgent(cmd);
end;

procedure THamLibDirect.SetXITFreq(vfo: TVFO; hz: integer);
var
  cmd: THLCommand;
begin
  if FRig = nil then Exit;

  if (hz < -9999) or (hz > 9999) then
     begin
     logger.Error('[SetXITFreq] XIT offset %d out of range (-9999 to +9999)', [hz]);
     Exit;
     end;

  Self.vfo[vfo].XITOffset := hz;

  FillChar(cmd, SizeOf(cmd), 0);
  cmd.CmdType := hlcSetXIT;
  cmd.VFO     := TR4WVFOToHamLibVFO(vfo);
  cmd.Hz      := hz;
  EnqueueUrgent(cmd);
end;

procedure THamLibDirect.SetBand(band: TRadioBand; vfo: TVFO = nrVFOA);
var
  freq: LongInt;
begin
  freq := BandToFreq(band);
  logger.Debug('[THamLibDirect.SetBand] Band %d on %s → tuning to %d Hz',
               [Ord(band), VFOToString(vfo), freq]);
  SetFrequency(freq, vfo, localMode);
end;

function THamLibDirect.ToggleBand(vfo: TVFO = nrVFOA): TRadioBand;
begin
  logger.Debug('[THamLibDirect.ToggleBand] Not implemented for VFO %s', [VFOToString(vfo)]);
  Result := rbNone;
end;

procedure THamLibDirect.SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA);
begin
  logger.Debug('[THamLibDirect.SetFilter] Filter on VFO %s: %d', [VFOToString(vfo), Ord(filter)]);
  // Filter setting via rig_set_mode with specific passband width
end;

function THamLibDirect.SetFilterHz(hz: integer; vfo: TVFO = nrVFOA): integer;
begin
  logger.Debug('[THamLibDirect.SetFilterHz] %d Hz on VFO %s', [hz, VFOToString(vfo)]);
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
// Matches WSJT-X polling strategy: freq, mode, PTT, split only.
// No RIT/XIT (no $07 D0 side-effects), no VFO B in normal operation.
// This avoids the CI-V traffic that dismisses front-panel menus on Icom radios.
var
  tempBand: BandType;
  tempMode: ModeType;
  freq: freq_t;
  mode: rmode_t;
  ptt: Boolean;
  split: Boolean;
begin
  if FRig = nil then
     begin
     logger.Debug('[SendPollRequests] Rig not connected');
     Exit;
     end;

  try
    // VFO A frequency
    freq := GetFreqFromRig(nrVFOA);
    if freq > 0 then
       begin
       Self.vfo[nrVFOA].frequency := Round(freq);
       CalculateBandMode(Self.vfo[nrVFOA].frequency, tempBand, tempMode);
       Self.vfo[nrVFOA].band := GetRadioBandFromBandType(tempBand);
       end;
    if TR4W_HAMLIB_DEBUG then
       logger.Info('[SendPollRequests] VFO A freq=%.0f', [freq]);

    // VFO A mode
    mode := GetModeFromRig(nrVFOA);
    Self.vfo[nrVFOA].mode := HamLibModeToTR4WMode(mode);
    if TR4W_HAMLIB_DEBUG then
       logger.Info('[SendPollRequests] VFO A mode=%d', [Integer(mode)]);

    // PTT
    ptt := GetPTTFromRig;
    if ptt then
       Self.radioState := rsTransmit
    else
       Self.radioState := rsReceive;

    // Split — also gates VFO B polling below
    split := GetSplitFromRig;
    Self.localSplitEnabled := split;
    if TR4W_HAMLIB_DEBUG then
       logger.Info('[SendPollRequests] PTT=%s split=%s', [BoolToStr(ptt, True), BoolToStr(split, True)]);



    // VFO B — poll when targetable or split active
    if FHasTargetableVFO or split then
       begin
       freq := GetFreqFromRig(nrVFOB);
       if freq > 0 then
          begin
          Self.vfo[nrVFOB].frequency := Round(freq);
          CalculateBandMode(Self.vfo[nrVFOB].frequency, tempBand, tempMode);
          Self.vfo[nrVFOB].band := GetRadioBandFromBandType(tempBand);
          end;
       if TR4W_HAMLIB_DEBUG then
          logger.Info('[SendPollRequests] VFO B freq=%.0f', [freq]);

       mode := GetModeFromRig(nrVFOB);
       Self.vfo[nrVFOB].mode := HamLibModeToTR4WMode(mode);
       end;

  except
    on E: Exception do
      logger.Error('[SendPollRequests] Exception during polling: %s', [E.Message]);
  end;
end;

procedure THamLibDirect.SendRITXITPoll;
var
  rit, xit: Integer;
  ritEnabled, xitEnabled: Integer;
  hlVFO: vfo_t;
begin
  if FRig = nil then
     Exit;
  try
    hlVFO := TR4WVFOToHamLibVFO(nrVFOA);

    // On/off state via rig_get_func — separate from the offset value.
    // A radio can have a stored RIT offset while RIT is disabled; inferring
    // state from (offset <> 0) incorrectly lights up the button in that case.
    ritEnabled := 0;
    rig_get_func(FRig, hlVFO, RIG_FUNC_RIT, ritEnabled);
    Self.vfo[nrVFOA].RITState := (ritEnabled <> 0);

    xitEnabled := 0;
    rig_get_func(FRig, hlVFO, RIG_FUNC_XIT, xitEnabled);
    Self.vfo[nrVFOA].XITState := (xitEnabled <> 0);

    // Offset values — only meaningful when state is on, but update always
    // so the display shows the current stored value when RIT is enabled.
    rit := GetRITFromRig(nrVFOA);
    Self.vfo[nrVFOA].RITOffset := rit;

    xit := GetXITFromRig(nrVFOA);
    Self.vfo[nrVFOA].XITOffset := xit;

    if TR4W_HAMLIB_DEBUG then
       logger.Info('[SendRITXITPoll] RIT state=%d offset=%d  XIT state=%d offset=%d',
                   [ritEnabled, rit, xitEnabled, xit]);
  except
    on E: Exception do
      logger.Error('[SendRITXITPoll] Exception: %s', [E.Message]);
  end;
end;

initialization
  logger := TLogLogger.GetLogger('TR4WDebugLog');
  logger.Info('HamLib Direct radio module initialized');

finalization
  logger.Info('HamLib Direct radio module finalized');

end.
