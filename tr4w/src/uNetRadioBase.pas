unit uNetRadioBase;

interface

uses
   IdTCPClient, IdComponent, IdTCPConnection,IdThreadComponent, SysUtils,
   Classes, StrUtils, Log4D;

Type TProcessMsgRef = procedure (sMessage: string) of Object;
Type TBinary = (bOn, bOff);
Type TVFO = (VFOA, VFOB);
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
      IFShift: integer;
      NR: boolean;
      NRLevel: integer;   // Are things like notch and NR set per VFO or radio wide?
      Notch: integer;
end;

TReadingThread = class(TThread)
  protected
    FConn: TIdTCPConnection;
    msgHandler: TProcessMsgRef;
    procedure Execute; override;
    procedure DoTerminate; override;
  public
    constructor Create(AConn: TIdTCPConnection; proc: TProcessMsgRef); reintroduce;
  end;


var
   logger: TLogLogger;
      appender: TLogFileAppender; 

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
      function GetFrequency: integer;
      function GetMode: TRadioMode;
      function GetDataMode: TRadioMode;
      procedure SetPTTviaCAT(Value: boolean);
      function  GetPTTviaCAT: boolean;
      procedure OnRadioConnected(Sender:TObject);
      procedure OnRadioDisconnected(Sender: TObject);
      procedure OnRadioStatus(Sender: TObject; const Status: TIdStatus; const AStatusText: string);
      //procedure IdThreadComponentRun(Sender: TIdThreadComponent);

   protected
      socket: TIdTCPClient;
      localCWSpeed: integer;
      RITState: TBinary;
      XITState: TBinary;
      vfo: array[1..2] of TRadioVFO;
      radioState: TRadioState;
      localMode: TRadioMode;
      localDataMode: TRadioMode;
      localSplitEnabled: boolean;
      bandIndependence: boolean;
      procRef: TProcessMsgRef;





   public

      procedure SendToRadio(s: string);
      constructor Create(ProcRef: TProcessMsgRef); overload;
      constructor Create(address: string; port: integer;ProcRef: TProcessMsgRef); overload;
      Destructor Destroy; overload;
      function ModeToString(mode: TRadioMode): string;
      property radioPort: integer read GetRadioPort write SetRadioPort;
      property radioAddress: string read GetRadioAddress write SetRadioAddress;
      property PTTviaCAT: boolean read GetPTTviaCAT write SetPTTviaCAT;
      property CWSpeed: integer read GetCWSpeed;
      function Connect: integer; overload;
      function Connect (address: string; port: integer): integer; overload;
      procedure Disconnect; overload;
      property IsTransmitting: boolean read GetIsTransmitting;
      property IsReceiving: boolean read GetIsReceiving;
      property IsConnected: boolean read GetIsConnected;
      property frequency: integer read GetFrequency;
      property mode: TRadioMode read GetMode;
      property dataMode: TRadioMode read GetDataMode;

   published

      procedure ProcessMsg(msg: string); Virtual; Abstract;
      procedure Transmit; Virtual; Abstract;
      procedure Receive; Virtual; Abstract;
      procedure SendCW(cwChars: string); Virtual; Abstract;
      procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode); Virtual; Abstract;
      procedure SetMode(mode:TRadioMode); Virtual; Abstract;
      function  ToggleMode: TRadioMode; Virtual; Abstract;
      procedure SetCWSpeed(speed: integer); Virtual; Abstract;
      procedure RITClear;  Virtual; Abstract;
      procedure XITClear; Virtual; Abstract;
      procedure RITOn; Virtual; Abstract;
      procedure RITOff; Virtual; Abstract;
      procedure XITOn; Virtual; Abstract;
      procedure XITOff; Virtual; Abstract;
      procedure Split(splitOn: boolean); Virtual; Abstract;
      procedure SetRITFreq(hz: integer); Virtual; Abstract;
      procedure SetXITFreq(hz: integer); Virtual; Abstract;
      procedure SetBand(band: TRadioBand); Virtual; Abstract;
      function  ToggleBand: TRadioBand; Virtual; Abstract;
      procedure SetFilter(filter:TRadioFilter); Virtual; Abstract;
      function  SetFilterHz(hz: integer): integer; Virtual; Abstract;
      procedure MemoryKeyer(mem: integer); Virtual; Abstract;


end;


implementation

Uses Unit1; //MainUnit;

//var
//   rt: TReadingThread = nil;
Constructor TNetRadioBase.Create(ProcRef: TProcessMsgRef);
begin
   appender := TLogRollingFileAppender.Create('name','K4Test.log');
   appender.Layout := TLogPatternLayout.Create('%d ' + TTCCPattern);

   TLogBasicConfigurator.Configure(appender);
   TLogLogger.GetRootLogger.Level := Trace;
   logger := TLogLogger.GetLogger('K4TestDebugLog');
   logger.info('******************** uNetRadioBase STARTUP ******************');
   logger.Trace('trace output');

   baseProcMsg := ProcRef;
   Self.vfo[1] := TRadioVFO.Create;
   Self.vfo[1].ID := VFOA;

   Self.vfo[2] := TRadioVFO.Create;
   Self.vfo[2].ID := VFOB;
   
   socket := TIdTCPClient.Create();
   socket.ConnectTimeout := 5000;  // TODO Make this a property
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
begin

   if socket <> nil then
      begin
      if socket.Connected then
         begin
         socket.Disconnect;
         end;
      FreeAndNil(socket);
      end;

   FreeAndNil(Self.vfo[1]);
   FreeAndNil(Self.vfo[2]);
end;

// Events

procedure TNetRadioBase.OnRadioConnected(Sender: TObject);
begin
   logger.Info('Network Radio connected');
   rt := TReadingThread.Create(socket, baseProcMsg);
   Form1.memoStatus.Lines.Add('Radio Connected');
end;

procedure TNetRadioBase.OnRadioDisconnected(Sender: TObject);
begin
   logger.Info('Network Radio disconnected');
   Form1.memoStatus.Lines.Add('Radio disconnected');
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
   Form1.memoStatus.Lines.Add('[OnRadioStatus] Received ' + AStatusText);
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

    try
        socket.Connect;
    except
        on E: Exception do begin
           logger.Error('Exception when connecting to radio: %s', [E.Message]);
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
         if rt <> nil then
            begin
            rt.Terminate;
            //rt.WaitFor;
            //FreeAndNil(rt);
            end;
         socket.Disconnect;
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
      socket.IOHandler.Write(s);
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

function TNetRadioBase.GetIsConnected: boolean;
begin
   Result := socket.Connected;
end;

function TNetRadioBase.GetFrequency: integer;
begin
   Result := Self.vfo[1].frequency;
end;

function TNetRadioBase.GetMode: TRadioMode;
begin
   Result := Self.vfo[1].mode;
end;

function TNetRadioBase.GetDataMode: TRadioMode;
begin
   Result := Self.vfo[1].dataMode;
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
  logger.debug('DEBUG: TReadingThread.Create');
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
         cmd := FConn.IOHandler.ReadLn(';');
         logger.debug('DEBUG: TReadingThread.Execute. Cmd: %s',[cmd]);
         Self.msgHandler(cmd);
         end;
      end;

end;

procedure TReadingThread.DoTerminate;
begin
  logger.debug('DEBUG: TReadingThread.DoTerminate');
  inherited;
end;



end.
