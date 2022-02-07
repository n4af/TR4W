unit uNetRadioBase;

interface

uses
   IdTCPClient, IdComponent, IdTCPConnection,IdThreadComponent, SysUtils,
   Classes, StrUtils, Log4D;

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
Type TReadingThread = class(TThread)
  protected
    FConn: TIdTCPConnection;
    msgHandler: TProcessMsgRef;
    procedure Execute; override;
    procedure DoTerminate; override;
  public
    constructor Create(AConn: TIdTCPConnection; proc: TProcessMsgRef); reintroduce;
  end;

//tr4w_ClassName                        : array[0..4] of Char = ('T', 'R', '4', 'W', #0);
const
   vfoNames: array[Low(TVFO)..High(TVFO)] of string = ('VFOA','VFOB');
{var
   logger: TLogLogger;
   appender: TLogFileAppender;
}

function BoolToString(b: boolean): string;
function IntegerBetween(v: integer; i: integer; k: integer): boolean;

// Add telnet client to this base class
// Add property for IP address, port, type (tcp or udp but just implement tcp right now).
// Add a connect and disconnect method

Type TNetRadioBase = class(TObject)
   private
      //socket: TIdTCPClient;
      //idThreadComponent   : TIdThreadComponent;
      localAddress: string;
      localPort: integer;
      rt: TReadingThread;
      baseProcMsg: TProcessMsgRef;

      function GetRadioPort: integer;
      procedure SetRadioPort(Value: Integer);
      function GetRadioAddress: string;
      procedure SetRadioAddress(Value: string);
      function GetCWSpeed: integer;
      function GetIsTransmitting: boolean;
      function GetIsReceiving: boolean;
      function GetISConnected: boolean;
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
      socket: TIdTCPClient;
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





   public


      constructor Create(ProcRef: TProcessMsgRef); overload;
      constructor Create(address: string; port: integer;ProcRef: TProcessMsgRef); overload;
      Destructor Destroy; overload;

      procedure SendToRadio(s: string); overload;
      procedure SendToRadio(whichVFO: TVFO; sCmd: string; sData: string); overload; Virtual; Abstract;
      function ModeToString(mode: TRadioMode): string;
      property radioPort: integer read GetRadioPort write SetRadioPort;
      property radioAddress: string read GetRadioAddress write SetRadioAddress;
      property PTTviaCAT: boolean read GetPTTviaCAT write SetPTTviaCAT;
      property CWSpeed: integer read GetCWSpeed;
      function Connect: integer; overload;
      function Connect (address: string; port: integer): integer; overload;
      function VFOToString(whichVFO: TVFO): string;

      procedure Disconnect; overload;
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
      procedure ProcessMsg(msg: string); Virtual; Abstract;
      procedure Transmit; Virtual; Abstract;
      procedure Receive; Virtual; Abstract;
      procedure SendCW(cwChars: string); Virtual; Abstract;
      procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode); Virtual; Abstract;
      procedure SetMode(mode:TRadioMode); Virtual; Abstract;
      function  ToggleMode: TRadioMode; Virtual; Abstract;
      procedure SetCWSpeed(speed: integer); Virtual; Abstract;
      procedure RITClear(vfo: TVFO);  Virtual; Abstract;
      procedure XITClear(vfo: TVFO); Virtual; Abstract;
      procedure RITOn(vfo: TVFO); Virtual; Abstract;
      procedure RITOff(vfo: TVFO); Virtual; Abstract;
      procedure XITOn(vfo: TVFO); Virtual; Abstract;
      procedure XITOff(vfo: TVFO); Virtual; Abstract;
      procedure Split(splitOn: boolean); Virtual; Abstract;
      procedure SetRITFreq(vfo: TVFO; hz: integer); Virtual; Abstract;
      procedure SetXITFreq(vfo: TVFO; hz: integer); Virtual; Abstract;
      procedure SetBand(vfo: TVFO; band: TRadioBand); Virtual; Abstract;
      function  ToggleBand: TRadioBand; Virtual; Abstract;
      procedure SetFilter(filter:TRadioFilter); Virtual; Abstract;
      function  SetFilterHz(hz: integer): integer; Virtual; Abstract;
      procedure MemoryKeyer(mem: integer); Virtual; Abstract;


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

Destructor TNetRadioBase.Destroy;
var iVFO: TVFO;
begin

   if socket <> nil then
      begin
      if socket.Connected then
         begin
         socket.Disconnect;
         end;
      FreeAndNil(socket);
      end;

   for iVFO := Low(TVFO) to High(TVFO) do
      begin
      FreeAndNil(Self.vfo[iVFO]);
      end;
   //FreeAndNil(Self.vfo[1]);
   //FreeAndNil(Self.vfo[2]);
end;

// Events

procedure TNetRadioBase.OnRadioConnected(Sender: TObject);
begin
   logger.Info('Network Radio connected');
   rt := TReadingThread.Create(socket, baseProcMsg);
end;

procedure TNetRadioBase.OnRadioDisconnected(Sender: TObject);
begin
   logger.Info('<<<<<<<<<<<<<< Network Radio disconnected');
   if rt <> nil then
      begin
      rt.Terminate;
      rt.WaitFor;
      FreeAndNil(rt);
      end;
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
begin

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
        socket.Connect;
        logger.Info('[TNetRadioBase.Connect] Connected successfully to network radio');
    except
        on E: Exception do begin
           logger.Error('[TNetRadioBase.Connect] Exception when connecting to radio (%s:%d]: %s', [socket.Host, socket.Port, E.Message]);
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

procedure TNetRadioBase.SendToRadio(s: string);
begin
   if socket.Connected then
      begin
      logger.Trace('[SendToRadio] Sending to radio: (%s)',[s]);
      socket.IOHandler.Write(s);
      end
   else
      begin
      logger.error('[SendToRadio] Cannot send command (%s) to radio as not connected',[s]);
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
   Result := socket.Connected;
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

function IntegerBetween(v: integer; i: integer; k: integer): boolean;
begin
   Result := (v >= i) and (v <= k);
end;

constructor TReadingThread.Create(AConn: TIdTCPConnection; proc: TProcessMsgRef);
begin
  logger.debug('************* DEBUG: TReadingThread.Create');
  FConn := AConn;

  msgHandler := proc;

  inherited Create(False);
end;

procedure TReadingThread.Execute;
var
  cmd: string;
begin
  logger.trace('DEBUG: TReadingThread.Execute');

   while not Terminated do
      begin
      if FConn.Connected then
         begin
         //logger.Trace('[TReadingThread.Execute] Calling ReadLn on socket');
         cmd := FConn.IOHandler.ReadLn(';');
         //logger.trace('[TReadingThread.Execute] Cmd received: (%s)',[cmd]);
         Self.msgHandler(cmd);
         end
      else
         begin
         logger.Trace('[TReadingThread.Execute] socket is not connected');
         end;
      end;
   logger.info('<<<<<<<<<<<< Leaving TReadingThread.Execute >>>>>>>>>>>>>>>>>>');
end;

procedure TReadingThread.DoTerminate;
begin
  logger.debug('DEBUG: TReadingThread.DoTerminate');
  inherited;
end;

function BoolToString(b: boolean): string;
begin
   Result := IfThen(b,'True','False');
end;

end.


