unit uExternalLoggerBase;

interface

uses
   IdTCPClient, IdComponent, IdTCPConnection,IdThreadComponent, IdExceptionCore, SysUtils,
   Classes, StrUtils, Log4D, VC, Tree;

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

function BoolToString(b: boolean): string;

// Add telnet client to this base class
// Add property for IP address, port, type (tcp or udp but just implement tcp right now).
// Add a connect and disconnect method

Type TExternalLoggerBase = class(TObject)
   private
      //socket: TIdTCPClient;
      //idThreadComponent   : TIdThreadComponent;
      localAddress: string;
      localPort: integer;
      localLoggerID: string;
      rt: TReadingThread;
      baseProcMsg: TProcessMsgRef;

      function GetLoggerPort: integer;
      procedure SetLoggerPort(Value: Integer);
      function GetLoggerID: string;
      procedure SetLoggerID (Value: string);
      function GetLoggerAddress: string;
      procedure SetLoggerAddress(Value: string);
      function GetISConnected: boolean;
      procedure OnLoggerConnected(Sender:TObject);
      procedure OnLoggerDisconnected(Sender: TObject);
      procedure OnLoggerStatus(Sender: TObject; const Status: TIdStatus; const AStatusText: string);

   protected
      readTerminator: string;
      socket: TIdTCPClient;
      procRef: TProcessMsgRef;

   public
      constructor Create(ProcRef: TProcessMsgRef); overload;
      constructor Create(address: string; port: integer;ProcRef: TProcessMsgRef); overload;
      Destructor Destroy; overload; Virtual;

      procedure SendToLogger(s: string); overload;
      property loggerPort: integer read GetLoggerPort write SetLoggerPort;
      property loggerAddress: string read GetLoggerAddress write SetLoggerAddress;
      property loggerID: string read GetLoggerID write SetLoggerID;
      property IsConnected: boolean read GetIsConnected;
      function Connect: integer; overload;
      function Connect (address: string; port: integer): integer; overload;

      procedure Disconnect; overload;


   published

      procedure ProcessMsg(msg: string); Virtual; Abstract;

end;


implementation

Uses MainUnit;

Constructor TExternalLoggerBase.Create(ProcRef: TProcessMsgRef);
begin
   baseProcMsg := ProcRef;
   
   socket := TIdTCPClient.Create();
   socket.ConnectTimeout := 10000;  // TODO Make this a property
   socket.OnDisconnected := Self.OnLoggerDisconnected;
   socket.OnConnected := Self.OnLoggerConnected;
   socket.OnStatus := Self.OnLoggerStatus;

end;

{Constructor TExternalLoggerBase.Create(ProcRef: TProcessMsgRef);
begin
   baseProcMsg := ProcRef;
   inherited Create;
end;}

Constructor TExternalLoggerBase.Create(address: string; port: integer; ProcRef: TProcessMsgRef);
begin
   Self.loggerAddress := address;
   Self.loggerPort := port;
   Self.Create(ProcRef);
end;

Destructor TExternalLoggerBase.Destroy;
begin

   if socket <> nil then
      begin
      if socket.Connected then
         begin
         socket.Disconnect;
         end;
      FreeAndNil(socket);
      end;

      if assigned(rt) then
         begin
         FreeAndNil(rt)
         end;
end;

// Events

procedure TExternalLoggerBase.OnLoggerConnected(Sender: TObject);
begin
   logger.Info('External logger connected');
   rt := TReadingThread.Create(socket, baseProcMsg);
   rt.readTerminator := Self.readTerminator;
end;

procedure TExternalLoggerBase.OnLoggerDisconnected(Sender: TObject);
begin
   logger.Info('<<<<<<<<<<<<<< External logger disconnected');
   if rt <> nil then
      begin
      rt.Terminate;
      rt.WaitFor;
      FreeAndNil(rt);
      end;
end;

procedure TExternalLoggerBase.OnLoggerStatus(Sender: TObject; const Status: TIdStatus; const AStatusText: string);
begin
   logger.trace('Received text from external logger: [%s]',[AStatusText]);
end;

function TExternalLoggerBase.GetLoggerPort: integer;
begin
   Result := Self.localPort;
end;

procedure TExternalLoggerBase.SetLoggerID(Value: string);
begin
  Self.localLoggerID := Value;
end;

function TExternalLoggerBase.GetLoggerID: string;
begin
  result := Self.localLoggerID;
end;

procedure TExternalLoggerBase.SetLoggerPort(Value: Integer);
begin
   Self.localPort := Value;
   // Since the port was changed, disconnect? Or just wait until next time?

end;

function TExternalLoggerBase.GetLoggerAddress: string;
begin
   Result := Self.localAddress;
end;

procedure TExternalLoggerBase.SetLoggerAddress(Value: string);
begin
  Self.localAddress := Value;
end;

function TExternalLoggerBase.Connect: integer;
begin

   logger.Info('[TExternalLoggerBase.Connect] Connecting to external logger at address %s, port = %d',[Self.loggerAddress,Self.loggerPort]);
    if Self.loggerPort = 0 then
       begin
       logger.Error('[TExternalLoggerBase.Connect] Called connect with port = 0. result = -1');
       Result := -1;
       Exit;
       end;

    if length(Self.loggerAddress) = 0 then
       begin
       logger.Error('[TExternalLoggerBase.Connect] Called connect with address = 0. result = -2');
       Result := -2;
       Exit;
       end;
    if not Assigned(socket) then
       begin
       logger.fatal('In TExternalLoggerBase.Connect, socket is NUL');
       end;
       
    socket.Port := Self.loggerPort;
    socket.Host := Self.loggerAddress;
    socket.ConnectTimeout := 10;

    try
        socket.Connect;
        logger.Info('[TExternalLoggerBase.Connect] Connected successfully to external logger');
    except
        on E: Exception do begin
           logger.Error('[TExternalLoggerBase.Connect] Exception when connecting to external logger (%s:%d]: %s', [socket.Host, socket.Port, E.Message]);
        end;
    end;
end;

function TExternalLoggerBase.Connect(address: string; port: integer): integer;
begin
   Self.loggerAddress := address;
   Self.loggerPort := port;
   Result := Self.Connect;
end;

procedure TExternalLoggerBase.Disconnect;
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

procedure TExternalLoggerBase.SendToLogger(s: string);
var nLen: integer;
begin
   try
      if not socket.Connected then
         begin
         Self.Connect;
         end;
      if socket.Connected then
         begin
         logger.Trace('[%s SendToLogger] Sending to radio: (%s) Hex:[%s]',[Self.loggerID,s, String2Hex(s)]);
         nLen := length(s);
         socket.IOHandler.WriteLn(s);
         //socket.IOHandler.Write(s,nLen,0);
         end
      else
         begin
         logger.error('[SendToLogger] Cannot send command (%s) to logger as not connected',[s]);
         end;
   except
      logger.error('Exception caught on TExternalLoggerBase.SendToLogger - Command to send was %s',[s]);
   end;

end;

function TExternalLoggerBase.GetIsConnected: boolean;
begin
   if Assigned(Self.socket) then
      begin
      Result := socket.Connected;
      end
   else
      begin
      logger.debug('In TExternalLoggerBase.GetIsConnected, socket is nil');
      Result := false;
      end;
end;
constructor TReadingThread.Create(AConn: TIdTCPConnection; proc: TProcessMsgRef);
begin
  logger.debug('************* DEBUG: TExternalLoggerBase.TReadingThread.Create');
  FConn := AConn;

  msgHandler := proc;

  inherited Create(False);
end;

procedure TReadingThread.Execute;
var
  cmd: string;
begin
   logger.trace('DEBUG: TExternalLoggerBase.TReadingThread.Execute');
   logger.info('In TExternalLoggerBase.ReadingThread.Execute, readTerminator is [%s]',[Self.readTerminator]);
   while not Terminated do
      begin
      try
         if FConn.Connected then
            begin
            //logger.Trace('[TExternalLoggerBase.TReadingThread.Execute] Calling ReadLn on socket');
            cmd := FConn.IOHandler.ReadLn(Self.readTerminator); // Need a variable for the stop character as hamlibn is #10 and K4 is ;(';');
            logger.trace('[TExternalLoggerBase.TReadingThread.Execute] Cmd received: (%s)',[cmd]);
            Self.msgHandler(cmd);
            end
         else
            begin
            logger.Trace('[TExternalLoggerBase.TReadingThread.Execute] socket is not connected');
            end;
         except
            on EIdNotConnected do
               logger.info('Socket exception on TExternalLoggerBase.TReadingThread.Execute');
            else
               begin
               logger.debug('Unknown exception on TExternalLoggerBase.TReadingThread.Execute');
               end;
         end;
      end;
   logger.info('<<<<<<<<<<<< Leaving TExternalLoggerBase.TReadingThread.Execute >>>>>>>>>>>>>>>>>>');
end;

procedure TReadingThread.DoTerminate;
begin
  logger.debug('DEBUG: TExternalLoggerBase.TReadingThread.DoTerminate');
  inherited;
end;

function BoolToString(b: boolean): string;
begin
   Result := IfThen(b,'True','False');
end;

end.


 