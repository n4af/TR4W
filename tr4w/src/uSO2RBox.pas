unit uSO2RBox;

{
A lot of the commands can be skipped for now.
REQUIRED:
  The *TX1, TX2, RX1, RX2*, *RX1S, RX2S*, RX1R, and RX2R commands. RX1R and
RX2R can be treated as RX1S and RX2S. RTS as a PTT control if appropriate.
I am guessing Mode would be nice, but suspect TR4W can already control that
based on radio physical settings ?
}
interface
uses
   IdTCPClient, IdComponent, IdTCPConnection,IdThreadComponent, IdExceptionCore,
   SysUtils, Classes, StrUtils, Log4D, VC, Tree;

Type TProcessMsgRef = procedure (sMessage: string) of Object;
Type TSimpleEventProc = procedure(const aStrParam:string) of object;
Type TReadingThread = class(TThread)
  protected
    readTerminator: string;
    FConn: TIdTCPConnection;
    msgHandler: TProcessMsgRef;
    procedure Execute; override;
    procedure DoTerminate; override;
  public
    constructor Create(AConn: TIdTCPConnection; proc: TProcessMsgRef); reintroduce;
  end;

Type TSO2RBox = class(TObject)
   private
      localAddress: string;
      localPort: integer;
      rt: TReadingThread;
      baseProcMsg: TProcessMsgRef;
      function GetSO2RBoxPort: integer;
      procedure SetSO2RBoxPort(Value: Integer);
      function GetSO2RBoxAddress: string;
      procedure SetSO2RBoxAddress(Value: string);
      procedure OnSO2RBoxConnected(Sender:TObject);
      procedure OnSO2RBoxDisconnected(Sender: TObject);
      procedure OnSO2RBoxStatus(Sender: TObject; const Status: TIdStatus; const AStatusText: string);

   protected
      readTerminator: string;
      socket: TIdTCPClient;
   public
      constructor Create(ProcRef: TProcessMsgRef); overload; virtual;
      constructor Create(address: string; port: integer{;ProcRef: TProcessMsgRef}); overload; virtual;
      Destructor Destroy; overload; Virtual;
      procedure Connect;
      function Send(s: string): boolean;
      procedure ProcessMessage(sMessage: string);
      property SO2RBoxPort: integer read GetSO2RBoxPort write SetSO2RBoxPort;
      property SO2RBoxAddress: string read GetSO2RBoxAddress write SetSO2RBoxAddress;
   published
   end;


implementation

Uses MainUnit, LogRadio;

Constructor TSO2RBox.Create(ProcRef: TProcessMsgRef);

begin

   baseProcMsg := ProcRef;


   socket := TIdTCPClient.Create();
   socket.ConnectTimeout := 10000;  // TODO Make this a property
   socket.OnDisconnected := Self.OnSO2RBoxDisconnected;
   socket.OnConnected := Self.OnSO2RBoxConnected;
   socket.OnStatus := Self.OnSO2RBoxStatus;

end;

Constructor TSO2RBox.Create(address: string; port: integer{; ProcRef: TProcessMsgRef});
begin
   Self.localAddress := address;
   Self.localPort := port;
   Self.Create(ProcessMessage);
end;

Destructor TSO2RBox.Destroy;
begin

   if socket <> nil then
      begin
      if socket.Connected then
         begin
         socket.Disconnect;
         end;
      FreeAndNil(socket);
      end;
end;

procedure TSO2RBox.Connect;
begin
   if socket <> nil then
      begin
      socket.Host := Self.localAddress;
      socket.Port := Self.localPort;
      Self.socket.Connect;
      Self.Send('TX?');
      end;
end;

function TSO2RBox.GetSO2RBoxAddress: string;
begin
   Result := Self.localAddress;
end;

procedure TSO2RBox.SetSO2RBoxAddress(Value: string);
begin
  Self.localAddress := Value;
end;

function TSO2RBox.GetSO2RBoxPort: integer;
begin
   Result := Self.localPort;
end;

procedure TSO2RBox.SetSO2RBoxPort(Value: Integer);
begin
   Self.localPort := Value;
   // Since the port was changed, disconnect? Or just wait until next time?

end;
procedure TSO2RBox.OnSO2RBoxConnected(Sender: TObject);
begin
   logger.Info('So2RBox connected via network');
   rt := TReadingThread.Create(socket, baseProcMsg);
   rt.readTerminator := Self.readTerminator;
end;

procedure TSO2RBox.OnSO2RBoxDisconnected(Sender: TObject);
begin
   logger.Info('<<<<<<<<<<<<<< SO2R Box  Radio disconnected');
   if rt <> nil then
      begin
      rt.Terminate;
      rt.WaitFor;
      FreeAndNil(rt);
      end;
end;

procedure TSO2RBox.OnSO2RBoxStatus(Sender: TObject; const Status: TIdStatus; const AStatusText: string);
begin
   logger.trace('Received status from SO2R Box: [%s]',[AStatusText]);
end;

function TSO2RBox.Send(s: string): boolean;
var nLen: integer;
begin
   Result := false;
   try
      if socket.Connected then
         begin
         logger.Trace('[SO2RBox::Send] Sending to SO2RBox: (%s)',[s]);
         nLen := length(s);
         socket.IOHandler.WriteLn(s);
         //socket.IOHandler.Write(s,nLen,0);
         Result := true;
         end
      else
         begin
         logger.error('[SO2RBox::Send] Cannot send command (%s) to SO2RBox as not connected',[s]);
         Result := false;
         end;
   except
      logger.error('Exception caught on TSO2RBox::Send - Command to send was %s',[s]);
      Result := false;
   end;

end;
procedure TSO2RBox.ProcessMessage(sMessage: string);
var
   sCommand: string;
begin
// This is called by the process that receives data on the socket - Event
   logger.Trace('[SO2RBox.ProcessMessage] Received from SO2R Box: (%s)',[sMessage]);
   sCommand := AnsiLeftStr(sMessage,2);
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
   logger.info('In ReadingThread.Execute, readTerminator is [%s]',[Self.readTerminator]);
   while not Terminated do
      begin
      try
         if FConn.Connected then
            begin
            //logger.Trace('[TReadingThread.Execute] Calling ReadLn on socket');
            cmd := FConn.IOHandler.ReadLn('\n'); // OTRSP docuent states on page 5 that CR is the delimiter
            logger.trace('[TReadingThread.Execute] Cmd received: (%s)',[cmd]);
            Self.msgHandler(cmd);
            end
         else
            begin
            logger.Trace('[TReadingThread.Execute] socket is not connected');
            end;
         except
            on EIdNotConnected do
               logger.info('Socket exception on TReadingThread.Execute');
            else
               begin
               logger.debug('Unknown exception on TReadingThread.Execute');
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
end.
