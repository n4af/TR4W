unit uNetRadioBase;

interface

uses
   IdTCPClient, IdComponent, IdTCPConnection,IdThreadComponent, SysUtils;

Type TVFO = (VFOA, VFOB);
Type TRadioMode = (rmNone,rmCW, rmCWRev, rmLSB, rmUSB, rmFM, rmAM,
                   rmData, rmDataRev, rmFSK, rmFSKRev, rmPSK, rmPSKRev,
                   rmAFSK, rmAFSKRev);
Type TRadioBand = (rb160m, rb60m, rb40m, rb30m, rb20m, rb17m, rb15m,
                   rb12m, rb10m, rb6m, rb4m, rb2m, rb70cm);
Type TRadioFilter = (rfNarrow, rfMid, rfWide);


// Add telnet client to this base class
// Add property for IP address, port, type (tcp or udp but just implement tcp right now).
// Add a connect and disconnect method

Type TNetRadioBase = class(TObject)
   private
      socket: TIdTCPClient;
      idThreadComponent   : TIdThreadComponent;
      function GetRadioPort: integer;
      procedure SetRadioPort(Value: Integer);
      function GetRadioAddress: string;
      procedure SetRadioAddress(Value: string);
      procedure OnRadioConnected(Sender:TObject);
      procedure OnRadioDisconnected(Sender: TObject);
      procedure IdThreadComponentRun(Sender: TIdThreadComponent);

   protected
      procedure SendToRadio(s: string);
   public
      constructor Create; overload;

      Destructor Destroy; overload;
      property radioPort: integer read GetRadioPort write SetRadioPort;
      property radioAddress: string read GetRadioAddress write SetRadioAddress;
      function Connect: integer; overload;
      function Connect (address: string; port: integer): integer; overload;
   published
      constructor Create(address: string; port: integer); overload;
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
      procedure SetRITFreq(hz: integer); Virtual; Abstract;
      procedure SetXITFreq(hz: integer); Virtual; Abstract;
      procedure SetBand(band: TRadioBand); Virtual; Abstract;
      function  ToggleBand: TRadioBand; Virtual; Abstract;
      procedure SetFilter(filter:TRadioFilter); Virtual; Abstract;
      function  SetFilterHz(hz: integer): integer; Virtual; Abstract;
      procedure MemoryKeyer(mem: integer); Virtual; Abstract;

end;

implementation

Uses MainUnit;

Constructor TNetRadioBase.Create;
begin
   socket := TIdTCPClient.Create();
   socket.OnDisconnected := Self.OnRadioDisconnected;
   socket.OnConnected := Self.OnRadioConnected;

   idThreadComponent := TIdThreadComponent.Create();
   idThreadComponent.OnRun := IdThreadComponentRun;

end;

Constructor TNetRadioBase.Create(address: string; port: integer);
begin
   Self.radioAddress := address;
   Self.radioPort := port;
   Self.Create;
end;

Destructor TNetRadioBase.Destroy;
begin

   if idThreadComponent.active then
      begin
      idThreadComponent.active := False;
      end;
   if socket <> nil then
      begin
      if socket.Connected then
         begin
         socket.Disconnect;
         end;
      FreeAndNil(socket);
      end;
   FreeAndNil(idThreadComponent);
end;

// Events

procedure TNetRadioBase.OnRadioConnected(Sender: TObject);
begin
   logger.Info('Network Radio connected');
end;

procedure TNetRadioBase.OnRadioDisconnected(Sender: TObject);
begin
   logger.Info('Network Radio disconnected');
end;

procedure TNetRadioBase.IdThreadComponentRun(Sender: TIdThreadComponent);
var
    msgFromServer : string;
begin
    // ... read message from server
    msgFromServer := socket.IOHandler.ReadLn();
 
    // ... messages log
    logger.info('Received from NetRadio: [%s]', [msgFromServer]);
end;
// .............................................................................


function TNetRadioBase.GetRadioPort: integer;
begin
   Result := Self.radioPort;
end;

procedure TNetRadioBase.SetRadioPort(Value: Integer);
begin
   Self.radioPort := Value;
   // Since the port was changed, disconnect? Or just wait until next time?

end;

function TNetRadioBase.GetRadioAddress: string;
begin
   Result := Self.radioAddress;
end;

procedure TNetRadioBase.SetRadioAddress(Value: string);
begin
  Self.radioAddress := Value;
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

procedure TNetRadioBase.SendToRadio(s: string);
begin
   if socket.Connected then
      begin
      socket.IOHandler.WriteLn(s);
      end;

end;
end.
