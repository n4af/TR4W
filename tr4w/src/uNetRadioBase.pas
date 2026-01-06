unit uNetRadioBase;

interface

uses
   Windows, IdTCPClient, IdComponent, IdTCPConnection,IdThreadComponent, IdExceptionCore, SysUtils,
   Classes, StrUtils, Log4D, VC, Tree, IdException, IdStack, SyncObjs, uSerialPort;

Type TProcessMsgRef = procedure (sMessage: string) of Object;
Type TBinary = (bOn, bOff);
Type TVFO = (nrVFOA, nrVFOB);  // Keep in sync with vfoNames in var section below

(* A question yet to resolve in this generalization is how to handle multiple
   slices in Flex radios. Should there be a nrVFOA and VFOB for each slice? Or should
   there be a radio object for each (but with a common connection). Once the K4
   is completed, I can experiment with the FLex 6600 and see what makes sense.
   NY4I 26-Nov-2021
*)

Type TRadioMode = (rmNone,rmCW, rmCWRev, rmLSB, rmUSB, rmFM, rmAM,
                   rmData, rmDataRev, rmFSK, rmFSKRev, rmPSK, rmPSKRev,
                   rmAFSK, rmAFSKRev);
Type TRadioBand = (rbNone,rb160m, rb80m, rb60m, rb40m, rb30m, rb20m, rb17m, rb15m,
                   rb12m, rb10m, rb6m, rb4m, rb2m, rb70cm);
Type TRadioFilter = (rfNarrow, rfMid, rfWide);
Type TRadioState = (rsOff, rsReceive, rsTransmit);
Type TRadioVFO = class(TObject)
   public
      ID: TVFO;
      frequency: integer;
      active: boolean;
      mode: TRadioMode;
      dataMode: TRadioMode;
      band: TRadioBand;
      priorBand: TRadioBand;
      filterWidth: TRadioFilter;
      filterHz: integer;
      RITState: boolean;
      XITState: boolean;
      RITOffset: integer;
      XITOffset: integer;
      IFShift: integer;
      filterWidthHz: integer;
      filter: integer;
     // NR: boolean;
     // NRLevel: integer;   // Are things like notch and NR set per VFO or radio wide?
     // Notch: integer;
end;

Type TSimpleEventProc = procedure(const aStrParam:string) of object;
Type PBoolean = ^Boolean;  // Pointer to Boolean type
Type TReadingThread = class(TThread)
  protected
    readTerminator: string;
    FConn: TIdTCPConnection;
    FSerialPort: TSerialPort;
    FSerialBuffer: string;  // Buffer for accumulating serial data
    msgHandler: TProcessMsgRef;
    FSocketLock: TCriticalSection;
    FDisconnecting: PBoolean;  // Pointer to parent's Disconnecting flag
    procedure Execute; override;
    procedure DoTerminate; override;
  public
    radioWasDisconnected: boolean;
    constructor Create(AConn: TIdTCPConnection; proc: TProcessMsgRef; ASocketLock: TCriticalSection; ADisconnecting: PBoolean); reintroduce; overload;
    constructor Create(ASerialPort: TSerialPort; proc: TProcessMsgRef; ASocketLock: TCriticalSection; ADisconnecting: PBoolean); reintroduce; overload;
    procedure ClearSerialBuffer;  // Clear accumulated serial buffer data
  end;

//tr4w_ClassName                        : array[0..4] of Char = ('T', 'R', '4', 'W', #0);
const
   vfoNames: array[Low(TVFO)..High(TVFO)] of string = ('VFOA','VFOB');

   // Reconnection configuration
   RECONNECT_INITIAL_DELAY = 1000;    // 1 second initial delay
   RECONNECT_MAX_DELAY = 30000;       // 30 seconds max delay
   RECONNECT_BACKOFF_MULTIPLIER = 2;  // Double delay each retry

   // Serial disconnect detection
   SERIAL_RESPONSE_TIMEOUT = 5.0;     // 5 seconds - consider disconnected if no valid response
{var
   logger: TLogLogger;
   appender: TLogFileAppender;
}

function BoolToString(b: boolean): string;

// Add telnet client to this base class
// Add property for IP address, port, type (tcp or udp but just implement tcp right now).
// Add a connect and disconnect method

Type TNetRadioBase = class(TObject)
   private
      //socket: TIdTCPClient;
      //idThreadComponent   : TIdThreadComponent;
      localAddress: string;
      localPort: integer;
      localSerialPort: portType;
      rt: TReadingThread;
      baseProcMsg: TProcessMsgRef;
      SocketLock: TCriticalSection;
      FLastValidResponse: TDateTime;  // Track last valid response for timeout detection

      function GetRadioPort: integer;
      procedure SetRadioPort(Value: Integer);
      function GetRadioAddress: string;
      procedure SetRadioAddress(Value: string);
      function GetSerialPort: portType;
      procedure SetSerialPort (Value: portType);
      function GetCWSpeed: integer;
      function GetIsTransmitting: boolean;
      function GetIsReceiving: boolean;
      function GetBand(whichVFO: TVFO): TRadioBand;
      function GetFrequency(whichVFO: TVFO): integer;
      function GetIsRITOn(whichVFO: TVFO): boolean;
      function GetRITOffset(whichVFO: TVFO): integer;
      function GetIsXITOn(whichVFO: TVFO): boolean;
      function GetXITOffset(whichVFO: TVFO): integer;
      function GetMode(whichVFO: TVFO): TRadioMode;
      function GetDataMode(whichVFO: TVFO): TRadioMode;
      function GetIFShift(whichVFO: TVFO): integer;
      function GetFilter(whichVFO: TVFO): integer;
      function GetSplitEnabled: boolean;
      function GetVFO(whichVFO: TVFO): TRadioVFO;

      procedure SetPTTviaCAT(Value: boolean);
      function  GetPTTviaCAT: boolean;
      procedure OnRadioConnected(Sender:TObject);
      procedure OnRadioDisconnected(Sender: TObject);
      procedure OnRadioStatus(Sender: TObject; const Status: TIdStatus; const AStatusText: string);
      //procedure IdThreadComponentRun(Sender: TIdThreadComponent);

   protected
      Disconnecting: Boolean;
      readTerminator: string;
      socket: TIdTCPClient;
      serialPortObj: TSerialPort;
      localCWSpeed: integer;
      RITState: boolean;
      XITState: boolean;
      vfo: array[Low(TVFO)..High(TVFO)] of TRadioVFO;
      radioState: TRadioState;
      localMode: TRadioMode;
      localDataMode: TRadioMode;
      localSplitEnabled: boolean;
      localRITOffset: integer;
      localXITOffset: integer;
      bandIndependence: boolean;
      procRef: TProcessMsgRef;

      function GetISConnected: boolean; virtual;





   public
      radioModel: string;
      serialBaudRate: DWORD;
      serialDataBits: Byte;
      serialStopBits: Byte;
      serialParity: Byte;

      // Polling configuration
      requiresPolling: Boolean;        // True for most radios, False for K4 with AI5
      autoUpdateCommand: string;       // Command to enable push updates (e.g., 'AI5;')
      pollingInterval: Integer;        // Milliseconds between polls (default 100)

      constructor Create(ProcRef: TProcessMsgRef); overload;
      constructor Create(address: string; port: integer;ProcRef: TProcessMsgRef); overload;
      Destructor Destroy; overload; Virtual;

      procedure SendToRadio(s: string); overload;
      procedure SendToRadio(whichVFO: TVFO; sCmd: string; sData: string); overload; Virtual; Abstract;
      function ModeToString(mode: TRadioMode): string;
      property radioPort: integer read GetRadioPort write SetRadioPort;
      property radioAddress: string read GetRadioAddress write SetRadioAddress;
      property serialPort: portType read GetSerialPort write SetSerialPort;
      property PTTviaCAT: boolean read GetPTTviaCAT write SetPTTviaCAT;
      property CWSpeed: integer read GetCWSpeed;
      function Connect: integer; overload; virtual;
      function Connect (address: string; port: integer): integer; overload;
      function VFOToString(whichVFO: TVFO): string;
      procedure UpdateLastValidResponse;  // Call when valid radio response received

      procedure Disconnect; overload; virtual;
      property IsTransmitting: boolean read GetIsTransmitting;
      property IsReceiving: boolean read GetIsReceiving;
      property IsConnected: boolean read GetIsConnected;
      property IsRITOn[whichVFO: TVFO]: boolean read GetIsRITOn;
      property IsXITOn[whichVFO: TVFO]: boolean read GetIsXITOn;
      property IsSplitEnabled: boolean read GetSplitEnabled;
      property band[whichVFO: TVFO]: TRadioBand read GetBand;
      property frequency[whichVFO: TVFO]: integer read GetFrequency;
      property mode[whichVFO: TVFO]: TRadioMode read GetMode;
      property dataMode[whichVFO: TVFO]: TRadioMode read GetDataMode;
      property RITOffset[whichVFO: TVFO]: integer read GetRITOffset;
      property XITOffset[whichVFO: TVFO]: integer read GetXITOffset;
      property IFShift[whichVFO: TVFO]: integer read GetIFShift;
      property filter[whichVFO: TVFO]: integer read GetFilter;
      // property Fields[Index: Integer]: TFieldSpec read GetField;
      //property FVFO[whichVFO: TVFO]: TRadioVFO read GetVFO;


   published

      // Polling interface - radios override to send appropriate query commands
      procedure QueryVFOAFrequency; Virtual;     // Query VFO A frequency
      procedure QueryVFOBFrequency; Virtual;     // Query VFO B frequency
      procedure QueryMode; Virtual;              // Query current mode
      procedure QueryTXStatus; Virtual;          // Query TX/RX status
      procedure QueryRITState; Virtual;          // Query RIT on/off and value
      procedure QueryXITState; Virtual;          // Query XIT on/off and value
      procedure QueryBand; Virtual;              // Query current band
      procedure QuerySplitState; Virtual;        // Query split on/off
      procedure PollRadioState; Virtual;         // Main polling method - calls Query* methods

      procedure ProcessMsg(msg: string); Virtual; Abstract;
      procedure Transmit; Virtual; Abstract;
      procedure Receive; Virtual; Abstract;
      procedure BufferCW(msg: string); Virtual; Abstract;
      procedure SendCW; Virtual; Abstract;
      procedure StopCW; Virtual; Abstract;
      procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode); Virtual; Abstract;
      procedure SetMode(mode: TRadioMode; vfo: TVFO = nrVFOA); Virtual; Abstract;
      function  ToggleMode(vfo: TVFO = nrVFOA): TRadioMode; Virtual; Abstract;
      procedure SetCWSpeed(speed: integer); Virtual; Abstract;
      procedure RITClear(vfo: TVFO);  Virtual; Abstract;
      procedure XITClear(vfo: TVFO); Virtual; Abstract;
      procedure RITBumpDown; Virtual; Abstract;
      procedure RITBumpUp; Virtual; Abstract;
      procedure RITOn(vfo: TVFO); Virtual; Abstract;
      procedure RITOff(vfo: TVFO); Virtual; Abstract;
      procedure XITOn(vfo: TVFO); Virtual; Abstract;
      procedure XITOff(vfo: TVFO); Virtual; Abstract;
      procedure Split(splitOn: boolean); Virtual; Abstract;
      procedure SetRITFreq(vfo: TVFO; hz: integer); Virtual; Abstract;
      procedure SetXITFreq(vfo: TVFO; hz: integer); Virtual; Abstract;
      procedure SetBand(band: TRadioBand; vfo: TVFO = nrVFOA); Virtual; Abstract;
      function  ToggleBand(vfo: TVFO = nrVFOA): TRadioBand; Virtual; Abstract;
      procedure SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA); Virtual; Abstract;
      function  SetFilterHz(hz: integer; vfo: TVFO = nrVFOA): integer; Virtual; Abstract;
      function  MemoryKeyer(mem: integer): boolean; Virtual; Abstract;
      procedure VFOBumpDown(whichVFO: TVFO); Virtual; Abstract;
      procedure VFOBumpUp(whichVFO: TVFO); Virtual; Abstract;


end;


implementation

//Uses Unit1;
Uses MainUnit, LogRadio;

//var
//   rt: TReadingThread = nil;
Constructor TNetRadioBase.Create(ProcRef: TProcessMsgRef);
var iVFO: TVFO;
begin
   {appender := TLogRollingFileAppender.Create('name','K4Test.log');
   appender.Layout := TLogPatternLayout.Create('%d ' + TTCCPattern);

   TLogBasicConfigurator.Configure(appender);
   TLogLogger.GetRootLogger.Level := Trace;
   logger := TLogLogger.GetLogger('K4TestDebugLog');
   logger.info('******************** uNetRadioBase STARTUP ******************');
   logger.Trace('trace output');
   }
   baseProcMsg := ProcRef;
   for iVFO := Low(TVFO) to High(TVFO) do
      begin
      Self.vfo[iVFO] := TRadioVFO.Create;
      Self.vfo[iVFO].ID := iVFO;
      end;
   //Self.vfo[nrVFOB] := TRadioVFO.Create;
   //Self.vfo[nrVFOB].ID := nrVFOB;
   
   socket := TIdTCPClient.Create();
   socket.ConnectTimeout := 10000;  // TODO Make this a property
   socket.OnDisconnected := Self.OnRadioDisconnected;
   socket.OnConnected := Self.OnRadioConnected;
   socket.OnStatus := Self.OnRadioStatus;

   serialPortObj := nil;  // Will be created when needed for serial connections

   // Default serial port settings (can be overridden)
   serialBaudRate := 38400;
   serialDataBits := 8;
   serialStopBits := 1;
   serialParity := 0;  // No parity

   // Default polling settings (radios override as needed)
   requiresPolling := True;        // Most radios need polling
   autoUpdateCommand := '';        // No auto-update by default
   pollingInterval := 100;         // 100ms default poll interval

   SocketLock := TCriticalSection.Create;
   Disconnecting := False;
   FLastValidResponse := Now;  // Initialize to current time
end;

{Constructor TNetRadioBase.Create(ProcRef: TProcessMsgRef);
begin
   baseProcMsg := ProcRef;
   inherited Create;
end;}

Constructor TNetRadioBase.Create(address: string; port: integer; ProcRef: TProcessMsgRef);
begin
   Self.radioAddress := address;
   Self.radioPort := port;
   Self.Create(ProcRef);
end;

// Default polling method implementations - radios override as needed
procedure TNetRadioBase.QueryVFOAFrequency;
begin
  // Default: do nothing - radio classes override
end;

procedure TNetRadioBase.QueryVFOBFrequency;
begin
  // Default: do nothing - radio classes override
end;

procedure TNetRadioBase.QueryMode;
begin
  // Default: do nothing - radio classes override
end;

procedure TNetRadioBase.QueryTXStatus;
begin
  // Default: do nothing - radio classes override
end;

procedure TNetRadioBase.QueryRITState;
begin
  // Default: do nothing - radio classes override
end;

procedure TNetRadioBase.QueryXITState;
begin
  // Default: do nothing - radio classes override
end;

procedure TNetRadioBase.QueryBand;
begin
  // Default: do nothing - radio classes override
end;

procedure TNetRadioBase.QuerySplitState;
begin
  // Default: do nothing - radio classes override
end;

procedure TNetRadioBase.PollRadioState;
begin
  // Default implementation - query all radio state
  QueryVFOAFrequency;
  QueryVFOBFrequency;
  QueryMode;
  QueryTXStatus;
  QueryRITState;
  QueryXITState;
  QueryBand;
  QuerySplitState;
end;

Destructor TNetRadioBase.Destroy;
var iVFO: TVFO;
begin
   if rt <> nil then
      begin
      rt.Terminate;
      rt.WaitFor;
      FreeAndNil(rt);
      end;

   if socket <> nil then
      begin
      if socket.Connected then
         begin
         socket.Disconnect;
         end;
      FreeAndNil(socket);
      end;

   if serialPortObj <> nil then
      begin
      if serialPortObj.IsOpen then
         serialPortObj.Close;
      FreeAndNil(serialPortObj);
      end;

   for iVFO := Low(TVFO) to High(TVFO) do
      begin
      FreeAndNil(Self.vfo[iVFO]);
      end;
   //FreeAndNil(Self.vfo[1]);
   //FreeAndNil(Self.vfo[2]);

   FreeAndNil(SocketLock);
end;

// Events

procedure TNetRadioBase.OnRadioConnected(Sender: TObject);
begin
   logger.Info('Network Radio connected');

   // Clear disconnecting flag on successful connection
   Disconnecting := False;

   // Only create reading thread if one doesn't already exist
   // (the thread creates itself during reconnection)
   if rt = nil then
      begin
      rt := TReadingThread.Create(socket, baseProcMsg, SocketLock, @Disconnecting);
      rt.readTerminator := Self.readTerminator;
      logger.Info('Created new reading thread');
      end
   else
      begin
      logger.Info('Reading thread already exists, no need to create new one');
      end;

   // Send ID command to verify connection and wake up communication
   try
      logger.Info('[OnRadioConnected] Sending ID; command to verify connection');
      Self.SendToRadio('ID;');
   except
      on E: Exception do
         logger.Error('[OnRadioConnected] Exception sending ID command: %s', [E.Message]);
   end;
end;

procedure TNetRadioBase.OnRadioDisconnected(Sender: TObject);
begin
   logger.Info('<<<<<<<<<<<<<< Network Radio disconnected');
   {if rt <> nil then
      begin
      rt.Terminate;
      rt.WaitFor;
      FreeAndNil(rt);
      end;  }
end;

procedure TNetRadioBase.OnRadioStatus(Sender: TObject; const Status: TIdStatus; const AStatusText: string);
begin
   logger.trace('Received text from radio: [%s]',[AStatusText]);
end;

{procedure TNetRadioBase.IdThreadComponentRun(Sender: TIdThreadComponent);
var
    msgFromServer : string;
begin
    // ... read message from server
    msgFromServer := socket.IOHandler.ReadLn();

    // ... messages log
    logger.info('[IdThreadComponentRun] Received from NetRadio: [%s]', [msgFromServer]);
end;
// .............................................................................
}

function TNetRadioBase.GetRadioPort: integer;
begin
   Result := Self.localPort;
end;

procedure TNetRadioBase.SetRadioPort(Value: Integer);
begin
   Self.localPort := Value;
   // Since the port was changed, disconnect? Or just wait until next time?

end;

function TNetRadioBase.GetSerialPort: portType;
begin
   Result := Self.localSerialPort;
end;

procedure TNetRadioBase.SetSerialPort(Value: portType);
begin
   Self.localSerialPort := Value;
   // Since the port was changed, disconnect? Or just wait until next time?

end;

function TNetRadioBase.GetPTTviaCAT: boolean;
begin
   Result := Self.PTTviaCAT;
   logger.trace('[GetPTTviaCAT] Returning %s for PTTviaCAT',[BoolToStr(Result)]);
end;

procedure TNetRadioBase.SetPTTviaCAT(Value: boolean);
begin
   Self.PTTviaCAT := Value;
   logger.Debug('[SetPTTviaCAT] Setting PTTviaCAT to %s',[BoolToStr(Value)]);
end;

function TNetRadioBase.GetRadioAddress: string;
begin
   Result := Self.localAddress;
end;

procedure TNetRadioBase.SetRadioAddress(Value: string);
begin
  Self.localAddress := Value;
end;

function TNetRadioBase.Connect: integer;
var
   comPortName: string;
   portNum: Integer;
begin
   Result := 0;

   // Check if this is a serial or network connection
   if Self.serialPort <> NoPort then
      begin
      // Serial connection
      portNum := Ord(Self.serialPort);  // Serial1=1, Serial2=2, etc.
      comPortName := Format('COM%d', [portNum]);

      logger.Info('[TNetRadioBase.Connect] Connecting to serial radio on %s', [comPortName]);

      try
         // Create serial port if needed
         if serialPortObj = nil then
            serialPortObj := TSerialPort.Create(comPortName);

         // For serial ports: if already open with reading thread, don't close/reopen
         // This prevents race conditions during reconnection attempts
         if serialPortObj.IsOpen and (rt <> nil) then
            begin
            logger.Debug('[TNetRadioBase.Connect] Serial port already open with reading thread, keeping connection alive');
            // Clear any accumulated garbage from the buffer
            rt.ClearSerialBuffer;
            Result := 0;
            Exit;
            end;

         // Close if already open (for initial setup or error recovery)
         if serialPortObj.IsOpen then
            begin
            logger.Debug('[TNetRadioBase.Connect] Serial port already open, closing first');
            serialPortObj.Close;
            end;

         // Open with configured port settings
         serialPortObj.OpenRaw(serialBaudRate, serialDataBits, serialStopBits, serialParity);
         logger.Info('[TNetRadioBase.Connect] Serial port %s opened: %d baud, %d data bits, parity %d, %d stop bits',
                     [comPortName, serialBaudRate, serialDataBits, serialParity, serialStopBits]);

         // Clear disconnecting flag on successful connection
         Disconnecting := False;

         // Create reading thread for serial port
         if rt = nil then
            begin
            rt := TReadingThread.Create(serialPortObj, baseProcMsg, SocketLock, @Disconnecting);
            rt.readTerminator := Self.readTerminator;
            logger.Info('[TNetRadioBase.Connect] Created serial reading thread');
            end;

         Result := 0;
      except
         on E: Exception do
            begin
            logger.Error('[TNetRadioBase.Connect] Exception opening serial port %s: %s', [comPortName, E.Message]);
            Result := -1;
            end;
      end;
      end
   else
      begin
      // Network connection
      logger.Info('[TNetRadioBase.Connect] Connecting to network radio at address %s, port = %d',[Self.radioAddress,Self.radioPort]);

      if Self.radioPort = 0 then
         begin
         logger.Error('Called connect with port = 0. result = -1');
         Result := -1;
         Exit;
         end;

      if length(Self.radioAddress) = 0 then
         begin
         logger.Error('Called connect with address = 0. result = -2');
         Result := -2;
         Exit;
         end;

      if not Assigned(socket) then
         begin
         logger.fatal('In TNetRadioBase.Connect, socket is NUL');
         end;

      socket.Port := Self.radioPort;
      socket.Host := Self.radioAddress;
      socket.ConnectTimeout := 10;

      try
          // Force disconnect to clear any corrupted socket state
          try
             if socket.Connected then
                begin
                logger.Debug('[TNetRadioBase.Connect] Socket already connected, disconnecting first');
                socket.Disconnect;
                end;
          except
             on E: Exception do
                begin
                logger.Debug('[TNetRadioBase.Connect] Exception during disconnect check: %s - forcing disconnect', [E.Message]);
                // Force disconnect even if Connected check fails
                try
                   socket.Disconnect;
                except
                   // Ignore disconnect errors
                end;
                end;
          end;

          Sleep(100);  // Brief delay to ensure cleanup

          logger.Debug('[TNetRadioBase.Connect] Attempting to connect to %s:%d', [socket.Host, socket.Port]);
          socket.Connect;
          logger.Info('[TNetRadioBase.Connect] Connected successfully to network radio');
      except
          on E: Exception do begin
             logger.Error('[TNetRadioBase.Connect] Exception when connecting to radio (%s:%d]: %s', [socket.Host, socket.Port, E.Message]);
             // Try to disconnect to clear bad state for next attempt
             try
                socket.Disconnect;
             except
                // Ignore disconnect errors
             end;
          end;
      end;
      end;
end;

function TNetRadioBase.Connect(address: string; port: integer): integer;
begin
   Self.radioAddress := address;
   Self.radioPort := port;
   Result := Self.Connect;
end;

procedure TNetRadioBase.Disconnect;
begin
   if socket.Connected then
      begin
      try
         logger.debug('Calling Disconnect - user request');
         // Disconnect the socket to pull it off the ReadLn so the thread in Execute sees that it is Terminated.
         socket.Disconnect;
         if rt <> nil then
            begin
            rt.Terminate;
            rt.WaitFor;
            FreeAndNil(rt);
            end;
      except
         on E: Exception do
            begin
            logger.Error('Exception when disconnecting from radio: %s', [E.Message]);
            end;
      end;
      end;
end;

procedure TNetRadioBase.UpdateLastValidResponse;
begin
   FLastValidResponse := Now;
   logger.Trace('[UpdateLastValidResponse] Updated last valid response timestamp');
end;

procedure TNetRadioBase.SendToRadio(s: string);
var nLen: integer;
begin
   // Don't try to send if we're disconnecting
   if Disconnecting then
      begin
      logger.debug('[SendToRadio] Ignoring command (%s) - radio is disconnecting',[s]);
      Exit;
      end;

   SocketLock.Enter;
   try
      try
         // Check if using serial or network
         if (Self.serialPort <> NoPort) and Assigned(serialPortObj) and serialPortObj.IsOpen then
            begin
            // Serial connection
            logger.Trace('[%s SendToRadio] Sending to serial radio: (%s) Hex:[%s]',[Self.radioModel,s, String2Hex(s)]);
            serialPortObj.WriteString(s + #13);  // K4 expects CR terminator
            end
         else if socket.Connected then
            begin
            // Network connection
            logger.Trace('[%s SendToRadio] Sending to radio: (%s) Hex:[%s]',[Self.radioModel,s, String2Hex(s)]);
            nLen := length(s);
            socket.IOHandler.WriteLn(s);
            //socket.IOHandler.Write(s,nLen,0);
            end
         else
            begin
            logger.error('[SendToRadio] Cannot send command (%s) to radio as not connected',[s]);
            end;
      except
         on E: Exception do
            begin
            logger.error('Exception caught on TNetRadioBase.SendToRadio - Command was (%s) - Exception: %s - %s',[s, E.ClassName, E.Message]);
            end;
      end;
   finally
      SocketLock.Leave;
   end;
end;

function TNetRadioBase.GetIsTransmitting: boolean;
begin
   Result := (Self.radioState = rsTransmit);
end;

function TNetRadioBase.GetIsReceiving: boolean;
begin
   Result := (Self.radioState = rsReceive);
end;

function TNetRadioBase.GetCWSpeed: integer;
begin
   Result := Self.localCWSpeed;
end;

function TNetRadioBase.GetIsRITOn(whichVFO: TVFO): boolean;
begin
   Result := Self.vfo[whichVFO].RITState;
   //logger.debug('In GetIsRITON, result = %s',[BoolToString(Result)]);
end;

function TNetRadioBase.GetRITOffset(whichVFO: TVFO): integer;
begin
   Result := Self.vfo[whichVFO].RITOffset;
end;


function TNetRadioBase.GetIsXITOn(whichVFO: TVFO): boolean;
begin
   Result := Self.vfo[whichVFO].XITState;
end;

function TNetRadioBase.GetXITOffset(whichVFO: TVFO): integer;
begin
   Result := Self.vfo[whichVFO].XITOffset;
end;

function TNetRadioBase.GetIsConnected: boolean;
begin
   // If we're disconnecting, immediately return false
   if Disconnecting then
      begin
      Result := false;
      Exit;
      end;

   // Check serial connection first
   if (Self.serialPort <> NoPort) and Assigned(serialPortObj) then
      begin
      try
         // For serial, port being "open" isn't enough - radio might be powered off
         // Check if we've received valid responses recently
         if not serialPortObj.IsOpen then
            Result := false
         else if (Now - FLastValidResponse) * 86400 > SERIAL_RESPONSE_TIMEOUT then
            begin
            logger.Info('[GetIsConnected] Serial radio not responding (%.1f seconds since last valid response)',
                        [(Now - FLastValidResponse) * 86400]);
            Result := false;
            end
         else
            Result := true;
      except
         on E: Exception do
            begin
            logger.debug('Exception checking serial connection: %s - %s', [E.ClassName, E.Message]);
            Result := false;
            end;
      end;
      end
   // Otherwise check network connection
   else if Assigned(Self.socket) then
      begin
      try
         Result := socket.Connected;
      except
         on E: Exception do
            begin
            logger.debug('Exception in GetIsConnected: %s - %s', [E.ClassName, E.Message]);
            Result := false;
            end;
      end;
      end
   else
      begin
      logger.debug('In TNetRadioBase.GetIsConnected, socket is nil');
      Result := false;
      end;
end;

function TNetRadioBase.GetFrequency(whichVFO: TVFO) : integer;
begin

   Result := Self.vfo[whichVFO].frequency;
end;

function TNetRadioBase.GetBand(whichVFO: TVFO): TRadioBand;
begin
   Result := Self.vfo[whichVFO].band;
end;

function TNetRadioBase.GetMode(whichVFO: TVFO): TRadioMode;
begin
   Result := Self.vfo[whichVFO].mode;
end;

function TNetRadioBase.GetDataMode(whichVFO: TVFO): TRadioMode;
begin
   Result := Self.vfo[whichVFO].dataMode;
end;

function TNetRadioBase.GetIFShift(whichVFO: TVFO): integer;
begin
   Result := Self.vfo[whichVFO].IFShift;
end;

function TNetRadioBase.GetFilter(whichVFO: TVFO): integer;
begin
   Result := Self.vfo[whichVFO].filter;
end;

function TNetRadioBase.GetSplitEnabled: boolean;
begin
   Result := Self.localSplitEnabled;
end;

function TNetRadioBase.GetVFO(whichVFO: TVFO): TRadioVFO;
begin
   if Assigned(Self.vfo[whichVFO]) then
      begin
      Result := Self.vfo[whichVFO];
      end;
  
end;

function TNetRadioBase.VFOToString(whichVFO: TVFO): string;
begin
   Result := vfoNames[whichVFO];
end;

function TNetRadioBase.ModeToString(mode: TRadioMode): string;
begin
   case mode of
      rmNone: Result := 'mode not set';
      rmCW: Result := 'CW';
      rmCWRev: Result := 'CW-R';
      rmLSB: Result := 'LSB';
      rmUSB: Result := 'USB';
      rmFM: Result := 'FM';
      rmAM: Result := 'AM';
      rmData: Result := 'Data';
      rmDataRev: Result := 'DataRev';
      rmFSK: Result := 'FSK';
      rmFSKRev: Result := 'FSK-R';
      rmPSK: Result := 'PSK';
      rmPSKRev: Result := 'PSK-R';
      rmAFSK: Result := 'AFSK';
      rmAFSKRev: Result := 'AFSK-R';
      end;
  // logger.trace('In ModeToString, %d converted to %s',[Ord(mode), Result]);
end;
{ Moved to TF
function IntegerBetween(v: integer; i: integer; k: integer): boolean;
begin
   Result := (v >= i) and (v <= k);
end;
 }
constructor TReadingThread.Create(AConn: TIdTCPConnection; proc: TProcessMsgRef; ASocketLock: TCriticalSection; ADisconnecting: PBoolean);
begin
  logger.debug('************* DEBUG: TReadingThread.Create (network)');
  FConn := AConn;
  FSerialPort := nil;
  msgHandler := proc;
  FSocketLock := ASocketLock;
  FDisconnecting := ADisconnecting;

  logger.Info('Created NetRadioBase::TReadingThread (network) with id %d',[Self.ThreadID]);
  inherited Create(False);
end;

constructor TReadingThread.Create(ASerialPort: TSerialPort; proc: TProcessMsgRef; ASocketLock: TCriticalSection; ADisconnecting: PBoolean);
begin
  logger.debug('************* DEBUG: TReadingThread.Create (serial)');
  FConn := nil;
  FSerialPort := ASerialPort;
  FSerialBuffer := '';  // Initialize empty buffer
  msgHandler := proc;
  FSocketLock := ASocketLock;
  FDisconnecting := ADisconnecting;

  logger.Info('Created NetRadioBase::TReadingThread (serial) with id %d',[Self.ThreadID]);
  inherited Create(False);
end;

procedure TReadingThread.Execute;
var
   cmd: string;
   wasConnected: boolean;
   termPos: Integer;
   completeCmd: string;
begin
   logger.trace('[TNetRadioBase.TReadingThread.Execute] Entered');
   logger.info('[TNetRadioBase.TReadingThread.Execute] readTerminator is [%s]',[Self.readTerminator]);

   wasConnected := False;

   while not Terminated do
      begin
      try
         // Check if connected (serial or network)
         try
            if (FSerialPort <> nil) and FSerialPort.IsOpen then
               begin
               // Serial port reading
               if not wasConnected then
                  begin
                  logger.Info('[TNetRadioBase.TReadingThread] Serial port open, starting to read');
                  wasConnected := True;
                  Self.radioWasDisconnected := False;
                  end;

               // Read data from serial port and buffer it
               try
                  cmd := FSerialPort.ReadString(1024);
                  if Length(cmd) > 0 then
                     begin
                     // Add to buffer
                     FSerialBuffer := FSerialBuffer + cmd;
                     logger.trace('[TNetRadioBase.TReadingThread.Execute] Serial received: (%s) Hex:[%s], Buffer now %d chars',[cmd, String2Hex(cmd), Length(FSerialBuffer)]);

                     // Process complete commands (terminated by readTerminator)
                     while Pos(Self.readTerminator, FSerialBuffer) > 0 do
                        begin
                        termPos := Pos(Self.readTerminator, FSerialBuffer);
                        completeCmd := Copy(FSerialBuffer, 1, termPos - 1);  // Get command without terminator
                        Delete(FSerialBuffer, 1, termPos);  // Remove from buffer including terminator

                        if Length(completeCmd) > 0 then
                           begin
                           logger.trace('[TNetRadioBase.TReadingThread.Execute] Processing command: Hex:[%s]',[String2Hex(completeCmd)]);
                           if Assigned(Self.msgHandler) then
                              begin
                              try
                                 Self.msgHandler(completeCmd);
                              except
                                 on E: Exception do
                                    begin
                                    logger.Error('[TNetRadioBase.TReadingThread] Exception in message handler: %s - %s', [E.ClassName, E.Message]);
                                    end;
                              end;
                              end;
                           end;
                        end;
                     end
                  else
                     Sleep(10);  // Brief sleep if no data
               except
                  on E: Exception do
                     begin
                     logger.Debug('[TNetRadioBase.TReadingThread] Exception during serial read: %s - %s', [E.ClassName, E.Message]);
                     Sleep(100);
                     end;
               end;
               end
            else if (FConn <> nil) and FConn.Connected then
               begin
               // Network socket reading
               if not wasConnected then
                  begin
                  logger.Info('[TNetRadioBase.TReadingThread] Radio connected, starting to read');
                  wasConnected := True;
                  Self.radioWasDisconnected := False;
                  end;

            // Read data from radio
            // NOTE: Do NOT lock during ReadLn - it's a blocking call!
            try
               cmd := FConn.IOHandler.ReadLn(Self.readTerminator);
               logger.trace('[TNetRadioBase.TReadingThread.Execute] Cmd received: (%s)',[cmd]);

               // Call message handler with exception protection
               try
                  Self.msgHandler(cmd);
               except
                  on E: Exception do
                     begin
                     logger.Error('[TNetRadioBase.TReadingThread] Exception in message handler: %s - %s', [E.ClassName, E.Message]);
                     // Continue reading despite handler error
                     end;
               end;
            except
               on EIdNotConnected do
                  begin
                  logger.Warn('[TNetRadioBase.TReadingThread] Lost connection while reading');
                  wasConnected := False;
                  Self.radioWasDisconnected := True;
                  FDisconnecting^ := True;  // Set disconnecting flag
                  end;
               on EIdConnClosedGracefully do
                  begin
                  logger.Info('[TNetRadioBase.TReadingThread] Radio closed connection gracefully');
                  wasConnected := False;
                  Self.radioWasDisconnected := True;
                  FDisconnecting^ := True;  // Set disconnecting flag
                  end;
               on E: Exception do
                  begin
                  logger.Debug('[TNetRadioBase.TReadingThread] Exception during read: %s - %s', [E.ClassName, E.Message]);
                  wasConnected := False;
                  Self.radioWasDisconnected := True;
                  FDisconnecting^ := True;  // Set disconnecting flag
                  end;
            end;
            end
         else
            begin
            // Not connected - wait for polling thread to reconnect
            if wasConnected then
               begin
               logger.Warn('[TNetRadioBase.TReadingThread] Radio disconnected, waiting for reconnection');
               wasConnected := False;
               Self.radioWasDisconnected := True;
               FDisconnecting^ := True;  // Set disconnecting flag
               end;

            // Just wait - polling thread will handle reconnection
            Sleep(500);
            end;
         except
            on E: EIdSocketError do
               begin
               // Socket in corrupted state - treat as disconnected
               logger.Debug('[TNetRadioBase.TReadingThread] Socket error during connection check: %s - treating as disconnected', [E.Message]);
               if wasConnected then
                  begin
                  wasConnected := False;
                  Self.radioWasDisconnected := True;
                  FDisconnecting^ := True;
                  end;
               Sleep(500);
               end;
            on E: Exception do
               begin
               // Other exception during connection check
               logger.Debug('[TNetRadioBase.TReadingThread] Exception during connection check: %s - %s', [E.ClassName, E.Message]);
               Sleep(500);
               end;
         end;
      except
         on E: Exception do
            begin
            logger.Error('[TNetRadioBase.TReadingThread] Unexpected exception in main loop: %s - %s',
                         [E.ClassName, E.Message]);
            Sleep(1000);  // Brief pause before continuing
            end;
      end;
      end;

   logger.info('<<<<<<<<<<<< Leaving TReadingThread.Execute >>>>>>>>>>>>>>>>>>');
end;

procedure TReadingThread.DoTerminate;
begin
  logger.debug('DEBUG: TReadingThread.DoTerminate');
  inherited;
end;

procedure TReadingThread.ClearSerialBuffer;
begin
  FSerialBuffer := '';
  logger.Info('[TReadingThread.ClearSerialBuffer] Serial buffer cleared');
end;

function BoolToString(b: boolean): string;
begin
   Result := IfThen(b,'True','False');
end;

end.


