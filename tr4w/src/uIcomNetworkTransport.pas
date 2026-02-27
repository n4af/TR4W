unit uIcomNetworkTransport;

{
  Icom Network Transport Layer

  Implements the Icom proprietary UDP network protocol for controlling
  Icom radios over Ethernet/WiFi. Manages the full connection lifecycle:
  handshake, authentication, CI-V data framing, keepalives, and retransmit.

  Architecture:
    - Two TIdUDPServer instances (control + CI-V) with threaded OnUDPRead callbacks
    - Windows SetTimer for keepalive/ping/token timers
    - Critical section protects all socket sends
    - CI-V data extracted from UDP packets and forwarded via OnCivData callback

  Reference: docs/ICOM_NETWORK_DELPHI_REFERENCE.md
}

interface

uses
  Windows, Messages, SysUtils, Classes, SyncObjs, StrUtils,
  IdUDPServer, IdSocketHandle, IdGlobal, IdComponent,
  uIcomNetworkTypes, uNetRadioBase, Log4D;

// Direct WinSock sendto declaration using const/untyped params to avoid
// type conflicts with Windows unit's TSockAddr vs WinSock2.TSockAddr.
function ws2_sendto(s: Integer; const buf; len, flags: Integer;
                    const addr; addrlen: Integer): Integer;
  stdcall; external 'ws2_32.dll' name 'sendto';

type
  TIcomNetworkTransport = class(TObject)
  private
    // State
    FState: TIcomConnectionState;
    FRadioAddress: string;           // IP address of radio
    FControlPort: Word;              // Default 50001
    FCivPort: Word;                  // Learned from radio during handshake
    FUsername: string;
    FPassword: string;
    FClientName: string;             // "TR4W"

    // IDs
    FMyId: LongWord;                 // Calculated from local IP/port
    FCivMyId: LongWord;              // Calculated from CI-V local IP/port
    FRemoteId: LongWord;             // Radio's control socket ID
    FCivRemoteId: LongWord;          // Radio's CI-V socket ID (DIFFERENT!)
    FToken: LongWord;               // Auth token from login response
    FAuthStartId: Word;             // From login response
    FTokRequest: Word;              // Random token request ID

    // Sockets
    FControlSocket: TIdUDPServer;    // Control/auth socket
    FCivSocket: TIdUDPServer;        // CI-V data socket

    // Sequence counters
    FSendSeq: Word;                  // Control socket outer sequence
    FCivSeq: Word;                   // CI-V socket outer sequence
    FCivInnerSeq: Word;              // CI-V stream inner sequence
    FAuthSeq: Word;                  // Auth-related inner sequence (inner payload)
    FAuthOuterSeq: Word;             // Auth outer Seq (separate from control Seq, starts at 1)
    FPingSendSeq: Word;              // Ping sequence (separate from tracked)

    // Capabilities
    FRadioName: string;              // From capabilities packet
    FCivAddress: Byte;               // CI-V address from capabilities
    FMacAddress: array[0..5] of Byte;
    FCommonCap: Word;
    FGUID: array[0..15] of Byte;

    // Timers
    FTimerWnd: HWND;                 // Hidden window for timer messages
    FLastCivData: LongWord;          // GetTickCount of last CI-V data
    FStartTick: LongWord;            // GetTickCount at connect start
    FAYTRetryCount: Integer;         // Are You There retry counter
    FAYTInterval: Integer;           // Current AYT retry interval (backoff)
    FLoginRetryCount: Integer;       // Login retry counter (for stale-session recovery)

    // Retransmit buffer
    FRetransmitList: TList;          // List of PRetransmitEntry

    // Thread safety
    FSendLock: TCriticalSection;

    // Callbacks
    FOnCivData: TProcessMsgRef;
    FOnStateChange: TNotifyEvent;
    FOnInitialPoll: TNotifyEvent;  // Fired once, 250ms after connect, to seed freq/mode

    // Internal - packet building and sending
    procedure SendControlPacket(PktType: Word; Socket: TIdUDPServer;
      RemoteId: LongWord; TargetAddr: string; TargetPort: Word;
      var SeqCounter: Word);
    procedure SendPingResponse(const Data: array of Byte; DataLen: Integer;
      Socket: TIdUDPServer; TargetAddr: string; TargetPort: Word);
    procedure SendPing;
    procedure SendLoginPacket;
    procedure SendTokenAck;
    procedure SendTokenRenew;
    procedure SendStreamRequest;
    procedure SendCivOpen;
    procedure SendCivClose;
    procedure SendIdlePacket;
    procedure SendRawPacket(Socket: TIdUDPServer; const Data; DataLen: Integer;
      TargetAddr: string; TargetPort: Word);

    // Internal - packet handling
    procedure HandleControlUDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure HandleCivUDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure HandleReceivedPacket(const Data: array of Byte; DataLen: Integer;
      FromCivSocket: Boolean; PeerIP: string; PeerPort: Word);
    procedure HandleControlResponse(const Data: array of Byte; DataLen: Integer;
      FromCivSocket: Boolean);
    procedure HandlePingPacket(const Data: array of Byte; DataLen: Integer;
      FromCivSocket: Boolean; PeerIP: string; PeerPort: Word);
    procedure HandleLoginResponse(const Data: array of Byte; DataLen: Integer);
    procedure HandleCapabilities(const Data: array of Byte; DataLen: Integer);
    procedure HandleStatusPacket(const Data: array of Byte; DataLen: Integer);
    procedure HandleDataPacket(const Data: array of Byte; DataLen: Integer);
    procedure ExtractCivFrames(const Data: array of Byte; DataLen: Integer);

    // Internal - state management
    procedure SetState(NewState: TIcomConnectionState);
    function GetIsConnected: Boolean;

    // Internal - timer callbacks
    procedure StartTimers;
    procedure StopTimers;
    procedure OnPingTimer;
    procedure OnIdleTimer;
    procedure OnTokenRenewalTimer;
    procedure OnRetransmitTimer;
    procedure OnCivWatchdogTimer;
    procedure OnAYTTimer;
    procedure OnLoginTimer;
    procedure OnInitialPollTimer;

    // Internal - retransmit management
    procedure AddToRetransmitBuffer(Seq: Word; const Data: string);
    procedure RemoveFromRetransmitBuffer(Seq: Word);
    procedure ClearRetransmitBuffer;

    // Internal - socket setup
    procedure CreateSockets;
    procedure DestroySockets;

    // Internal - ID calculation
    function GetLocalIPForRoute: string;
    function CalculateMyIdFromSocket(Socket: TIdUDPServer): LongWord;

  public
    constructor Create;
    destructor Destroy; override;

    // Connection lifecycle
    function Connect(Address: string; Port: Word;
      Username, Password: string): Integer;
    procedure Disconnect;

    // CI-V data send
    procedure SendCivData(const CivFrame: string);

    // Properties
    property State: TIcomConnectionState read FState;
    property IsConnected: Boolean read GetIsConnected;
    property RadioName: string read FRadioName;
    property CivAddress: Byte read FCivAddress;
    property OnCivData: TProcessMsgRef read FOnCivData write FOnCivData;
    property OnStateChange: TNotifyEvent read FOnStateChange write FOnStateChange;
    property OnInitialPoll: TNotifyEvent read FOnInitialPoll write FOnInitialPoll;
  end;

implementation

uses
  WinSock;

var
  logger: TLogLogger;

  // Global transport reference for timer window procedure
  // (Windows SetTimer requires a window proc, not a method pointer)
  GTransportInstance: TIcomNetworkTransport;

function BytesToHexStr(const Data; DataLen: Integer): string; forward;

// Timer window procedure
function TimerWndProc(Wnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin
  if (Msg = WM_TIMER) and Assigned(GTransportInstance) then
  begin
    case wParam of
      ICOM_TIMER_PING:          GTransportInstance.OnPingTimer;
      ICOM_TIMER_IDLE:          GTransportInstance.OnIdleTimer;
      ICOM_TIMER_TOKEN:         GTransportInstance.OnTokenRenewalTimer;
      ICOM_TIMER_RETRANSMIT:    GTransportInstance.OnRetransmitTimer;
      ICOM_TIMER_CIV_WATCHDOG:  GTransportInstance.OnCivWatchdogTimer;
      ICOM_TIMER_AYT:           GTransportInstance.OnAYTTimer;
      ICOM_TIMER_LOGIN:         GTransportInstance.OnLoginTimer;
      ICOM_TIMER_INITIAL_POLL:  GTransportInstance.OnInitialPollTimer;
    end;
    Result := 0;
  end
  else
    Result := DefWindowProc(Wnd, Msg, wParam, lParam);
end;

const
  TIMER_WND_CLASS = 'IcomNetworkTimerWnd';

var
  TimerWndClassRegistered: Boolean = False;

procedure RegisterTimerWndClass;
var
  WC: TWndClass;
begin
  if TimerWndClassRegistered then Exit;

  FillChar(WC, SizeOf(WC), 0);
  WC.lpfnWndProc := @TimerWndProc;
  WC.hInstance := HInstance;
  WC.lpszClassName := TIMER_WND_CLASS;
  Windows.RegisterClass(WC);
  TimerWndClassRegistered := True;
end;

// ============================================================================
// Constructor / Destructor
// ============================================================================

constructor TIcomNetworkTransport.Create;
begin
  inherited Create;

  FState := icsDisconnected;
  FClientName := ICOM_CLIENT_NAME;
  FControlPort := ICOM_DEFAULT_CONTROL_PORT;
  FSendLock := TCriticalSection.Create;
  FRetransmitList := TList.Create;
  FTimerWnd := 0;

  // Register timer window class
  RegisterTimerWndClass;
end;

destructor TIcomNetworkTransport.Destroy;
begin
  if FState <> icsDisconnected then
    Disconnect;

  ClearRetransmitBuffer;
  FreeAndNil(FRetransmitList);
  FreeAndNil(FSendLock);

  inherited Destroy;
end;

// ============================================================================
// Public API
// ============================================================================

function TIcomNetworkTransport.Connect(Address: string; Port: Word;
  Username, Password: string): Integer;
begin
  Result := 0;

  if FState <> icsDisconnected then
  begin
    logger.Warn('[IcomTransport] Connect called while in state %s',
                [IcomStateToString(FState)]);
    Disconnect;
  end;

  FRadioAddress := Address;
  FControlPort := Port;
  FUsername := Username;
  FPassword := Password;

  // Reset sequence counters
  FSendSeq := 0;
  FCivSeq := 0;
  FCivInnerSeq := 0;
  FAuthSeq := ICOM_AUTH_SEQ_START;
  FPingSendSeq := 0;
  FToken := 0;
  FRemoteId := 0;
  FCivRemoteId := 0;
  FRadioName := '';
  FCivAddress := 0;
  FAYTRetryCount := 0;
  FAYTInterval := ICOM_AYT_INITIAL_INTERVAL;
  FStartTick := GetTickCount;
  FLastCivData := GetTickCount;

  ClearRetransmitBuffer;

  logger.Info('[IcomTransport] Connecting to %s:%d user=%s',
              [Address, Port, Username]);

  try
    // Create sockets
    CreateSockets;

    // Create timer window
    GTransportInstance := Self;
    FTimerWnd := CreateWindow(TIMER_WND_CLASS, '', 0,
      0, 0, 0, 0, 0, 0, HInstance, nil);
    if FTimerWnd = 0 then
    begin
      logger.Error('[IcomTransport] Failed to create timer window');
      DestroySockets;
      Result := -1;
      Exit;
    end;

    // Calculate our ID from the control socket's local port
    FMyId := CalculateMyIdFromSocket(FControlSocket);
    logger.Debug('[IcomTransport] My control ID: $%.8x', [FMyId]);

    // Send "Are You There" to start handshake
    // AYT uses Seq=0 (FSendSeq starts at 0); do NOT increment here
    SendControlPacket(ICOM_PKT_ARE_YOU_THERE, FControlSocket,
      0, FRadioAddress, FControlPort, FSendSeq);
    SetState(icsWaitingForHere);

    // Start AYT retry timer
    SetTimer(FTimerWnd, ICOM_TIMER_AYT, FAYTInterval, nil);

  except
    on E: Exception do
    begin
      logger.Error('[IcomTransport] Exception during connect: %s', [E.Message]);
      DestroySockets;
      if FTimerWnd <> 0 then
      begin
        DestroyWindow(FTimerWnd);
        FTimerWnd := 0;
      end;
      Result := -1;
    end;
  end;
end;

procedure TIcomNetworkTransport.Disconnect;
begin
  logger.Info('[IcomTransport] Disconnect called from state %s',
              [IcomStateToString(FState)]);

  if FState = icsDisconnected then Exit;

  SetState(icsDisconnecting);

  // Stop all timers
  StopTimers;

  // Send CI-V Close if connected
  if (FCivSocket <> nil) and (FCivRemoteId <> 0) then
  begin
    try
      SendCivClose;
      // Send disconnect on CI-V socket
      Inc(FCivSeq);
      SendControlPacket(ICOM_PKT_DISCONNECT, FCivSocket,
        FCivRemoteId, FRadioAddress, FCivPort, FCivSeq);
    except
      on E: Exception do
        logger.Debug('[IcomTransport] Exception during CI-V disconnect: %s', [E.Message]);
    end;
  end;

  // Send disconnect on control socket
  if (FControlSocket <> nil) and (FRemoteId <> 0) then
  begin
    try
      Inc(FSendSeq);
      SendControlPacket(ICOM_PKT_DISCONNECT, FControlSocket,
        FRemoteId, FRadioAddress, FControlPort, FSendSeq);
    except
      on E: Exception do
        logger.Debug('[IcomTransport] Exception during control disconnect: %s', [E.Message]);
    end;
  end;

  // Wait for disconnect packets to transmit (UDP is async)
  Sleep(100);

  // Cleanup
  DestroySockets;
  ClearRetransmitBuffer;

  if FTimerWnd <> 0 then
  begin
    DestroyWindow(FTimerWnd);
    FTimerWnd := 0;
  end;

  GTransportInstance := nil;
  SetState(icsDisconnected);
end;

procedure TIcomNetworkTransport.SendCivData(const CivFrame: string);
var
  Pkt: TDataPacket;
  FullPacket: string;
  I: Integer;
begin
  if FState <> icsConnected then
  begin
    logger.Warn('[IcomTransport] SendCivData called while not connected (state=%s)',
                [IcomStateToString(FState)]);
    Exit;
  end;

  // Build data packet header
  FillChar(Pkt, SizeOf(Pkt), 0);
  Pkt.Len := ICOM_DATA_HDR_SIZE + Length(CivFrame);
  Pkt.PktType := ICOM_PKT_DATA;
  Inc(FCivSeq);
  Pkt.Seq := FCivSeq;
  Pkt.SentID := FMyId;
  Pkt.RcvdID := FCivRemoteId;
  Pkt.Reply := ICOM_DATA_REPLY_MARKER;
  Pkt.DataLen := Length(CivFrame);  // Little-endian (no swap) — matches wfview
  Pkt.SendSeq := SwapWord(FCivInnerSeq);
  Inc(FCivInnerSeq);

  // Combine header + CI-V data into single packet
  SetLength(FullPacket, SizeOf(Pkt) + Length(CivFrame));
  Move(Pkt, FullPacket[1], SizeOf(Pkt));
  if Length(CivFrame) > 0 then
    Move(CivFrame[1], FullPacket[SizeOf(Pkt) + 1], Length(CivFrame));

  FSendLock.Enter;
  try
    SendRawPacket(FCivSocket, FullPacket[1], Length(FullPacket),
      FRadioAddress, FCivPort);
  finally
    FSendLock.Leave;
  end;

  logger.Debug('[IcomTransport] Sent CI-V data, outer seq=%d, inner seq=%d, len=%d hex: %s',
               [FCivSeq, FCivInnerSeq - 1, Length(CivFrame),
                BytesToHexStr(FullPacket[1], Length(FullPacket))]);
end;

// ============================================================================
// Socket Creation / Destruction
// ============================================================================

procedure TIcomNetworkTransport.CreateSockets;

  procedure SetupSocket(var Socket: TIdUDPServer;
    OnRead: TUDPReadEvent; BindPort: Word);
  var
    Binding: TIdSocketHandle;
    RcvBufSize: Integer;
  begin
    Socket := TIdUDPServer.Create(nil);
    Socket.ThreadedEvent := True;
    Socket.OnUDPRead := OnRead;

    // Bind to any available port (or specific port for CI-V)
    Binding := Socket.Bindings.Add;
    Binding.IP := '0.0.0.0';
    Binding.Port := BindPort;

    Socket.Active := True;

    // Increase UDP receive buffer to 256KB to reduce packet loss under load
    RcvBufSize := 256 * 1024;
    WinSock.setsockopt(Binding.Handle, SOL_SOCKET, SO_RCVBUF,
      PChar(@RcvBufSize), SizeOf(RcvBufSize));

    logger.Debug('[IcomTransport] Socket bound to port %d', [Binding.Port]);
  end;

begin
  // Control socket - bind to any port
  SetupSocket(FControlSocket, HandleControlUDPRead, 0);

  // CI-V socket will be created after we learn the CI-V port from the radio
  FCivSocket := nil;
end;

procedure TIcomNetworkTransport.DestroySockets;
begin
  if FControlSocket <> nil then
  begin
    try
      FControlSocket.Active := False;
    except
      on E: Exception do
        logger.Debug('[IcomTransport] Exception deactivating control socket: %s', [E.Message]);
    end;
    FreeAndNil(FControlSocket);
  end;

  if FCivSocket <> nil then
  begin
    try
      FCivSocket.Active := False;
    except
      on E: Exception do
        logger.Debug('[IcomTransport] Exception deactivating CI-V socket: %s', [E.Message]);
    end;
    FreeAndNil(FCivSocket);
  end;
end;

// Use the UDP connect trick to find which local interface routes to the radio.
// A UDP "connect" sets routing without sending any packet, then getsockname
// returns the local interface IP that the OS would use for that route.
function TIcomNetworkTransport.GetLocalIPForRoute: string;
var
  Sock: TSocket;
  DestAddr: TSockAddr;
  LocalAddr: TSockAddr;
  AddrLen: Integer;
  DestIP: u_long;
begin
  Result := '';
  try
    Sock := WinSock.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if Sock = INVALID_SOCKET then Exit;
    try
      DestIP := WinSock.inet_addr(PChar(FRadioAddress));
      if DestIP = INADDR_NONE then Exit;

      FillChar(DestAddr, SizeOf(DestAddr), 0);
      DestAddr.sin_family := AF_INET;
      DestAddr.sin_port := WinSock.htons(FControlPort);
      DestAddr.sin_addr.S_addr := DestIP;

      if WinSock.connect(Sock, DestAddr, SizeOf(DestAddr)) <> 0 then Exit;

      AddrLen := SizeOf(LocalAddr);
      FillChar(LocalAddr, SizeOf(LocalAddr), 0);
      if WinSock.getsockname(Sock, LocalAddr, AddrLen) <> 0 then Exit;

      Result := string(WinSock.inet_ntoa(LocalAddr.sin_addr));
    finally
      WinSock.closesocket(Sock);
    end;
  except
    Result := '';
  end;
end;

function TIcomNetworkTransport.CalculateMyIdFromSocket(Socket: TIdUDPServer): LongWord;
var
  LocalIP: LongWord;
  LocalPort: Word;
  IPParts: array[0..3] of Byte;
  IPStr: string;
  DotPos: Integer;
  I: Integer;
  Part: string;
begin
  // Get the local port from the socket binding
  if Socket.Bindings.Count > 0 then
    LocalPort := Socket.Bindings[0].Port
  else
    LocalPort := 0;

  // Get local IP - use the binding's IP, or use routing trick to detect it
  IPStr := Socket.Bindings[0].IP;
  if (IPStr = '') or (IPStr = '0.0.0.0') then
  begin
    IPStr := GetLocalIPForRoute;
    if IPStr = '' then
      IPStr := '127.0.0.1';  // Last-resort fallback
    logger.Debug('[IcomTransport] Detected local routing IP: %s', [IPStr]);
  end;

  // Parse IP string to bytes
  FillChar(IPParts, SizeOf(IPParts), 0);
  I := 0;
  while (Length(IPStr) > 0) and (I < 4) do
  begin
    DotPos := Pos('.', IPStr);
    if DotPos = 0 then
    begin
      IPParts[I] := StrToIntDef(IPStr, 0);
      IPStr := '';
    end
    else
    begin
      Part := Copy(IPStr, 1, DotPos - 1);
      IPParts[I] := StrToIntDef(Part, 0);
      Delete(IPStr, 1, DotPos);
    end;
    Inc(I);
  end;

  // Build host-order IP (e.g., 192.168.1.100 = $C0A80164)
  LocalIP := (LongWord(IPParts[0]) shl 24) or
             (LongWord(IPParts[1]) shl 16) or
             (LongWord(IPParts[2]) shl 8) or
             LongWord(IPParts[3]);

  Result := CalculateMyId(LocalIP, LocalPort);
end;

// ============================================================================
// Hex dump helper (for debug logging)
// ============================================================================

function BytesToHexStr(const Data; DataLen: Integer): string;
var
  Bytes: array[0..1023] of Byte absolute Data;
  I: Integer;
begin
  Result := '';
  for I := 0 to DataLen - 1 do
  begin
    if I > 0 then Result := Result + ' ';
    Result := Result + IntToHex(Bytes[I], 2);
  end;
end;

// ============================================================================
// UDP Read Handlers (called from Indy listener threads)
// ============================================================================

procedure TIcomNetworkTransport.HandleControlUDPRead(
  AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  RawData: array of Byte;
begin
  if Length(AData) < SizeOf(TControlPacket) then Exit;

  SetLength(RawData, Length(AData));
  Move(AData[0], RawData[0], Length(AData));

  HandleReceivedPacket(RawData, Length(RawData), False,
    ABinding.PeerIP, ABinding.PeerPort);
end;

procedure TIcomNetworkTransport.HandleCivUDPRead(
  AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  RawData: array of Byte;
begin
  if Length(AData) < SizeOf(TControlPacket) then Exit;

  SetLength(RawData, Length(AData));
  Move(AData[0], RawData[0], Length(AData));

  HandleReceivedPacket(RawData, Length(RawData), True,
    ABinding.PeerIP, ABinding.PeerPort);
end;

// ============================================================================
// Packet Dispatch
// ============================================================================

procedure TIcomNetworkTransport.HandleReceivedPacket(
  const Data: array of Byte; DataLen: Integer;
  FromCivSocket: Boolean; PeerIP: string; PeerPort: Word);
var
  Pkt: TControlPacket;
  PktType: Word;
begin
  if DataLen < SizeOf(TControlPacket) then Exit;

  Move(Data[0], Pkt, SizeOf(TControlPacket));
  PktType := Pkt.PktType;

  logger.Trace('[IcomTransport] Received packet: type=$%.4x len=%d fromCIV=%s state=%s peer=%s:%d',
               [PktType, DataLen, BoolToStr(FromCivSocket, True),
                IcomStateToString(FState), PeerIP, PeerPort]);
  logger.Trace('[IcomTransport] Packet hex: %s', [BytesToHexStr(Data[0], DataLen)]);
  if FState = icsWaitingForLogin then
    logger.Debug('[IcomTransport] WaitingForLogin raw: %s', [BytesToHexStr(Data[0], DataLen)]);

  case PktType of
    ICOM_PKT_I_AM_HERE,
    ICOM_PKT_ARE_YOU_READY,
    ICOM_PKT_DISCONNECT:
      HandleControlResponse(Data, DataLen, FromCivSocket);

    ICOM_PKT_PING:
      HandlePingPacket(Data, DataLen, FromCivSocket, PeerIP, PeerPort);

    ICOM_PKT_DATA,
    ICOM_PKT_AUTH:
      begin
        if FromCivSocket then
          HandleDataPacket(Data, DataLen)
        else
        begin
          // Data packets on control socket: login response, capabilities, status
          // Each state requires a different minimum packet size - check per-state
          case FState of
            icsWaitingForLogin:
              if DataLen >= SizeOf(TLoginResponsePacket) then  // 96 bytes
                HandleLoginResponse(Data, DataLen)
              else
                logger.Debug('[IcomTransport] WaitingForLogin: too small (%d < %d)',
                  [DataLen, SizeOf(TLoginResponsePacket)]);
            icsWaitingForToken:
              if DataLen >= SizeOf(TCapabilitiesPacket) then   // 66 bytes
                HandleCapabilities(Data, DataLen)
              else
                logger.Debug('[IcomTransport] WaitingForToken: too small (%d < %d)',
                  [DataLen, SizeOf(TCapabilitiesPacket)]);
            icsWaitingForStream:
              if DataLen = SizeOf(TStatusPacket) then          // exactly 80 bytes
                HandleStatusPacket(Data, DataLen)
              else
                logger.Debug('[IcomTransport] WaitingForStream: ignoring non-status pkt len=%d (expected %d)',
                  [DataLen, SizeOf(TStatusPacket)]);
          else
            logger.Debug('[IcomTransport] Control data pkt len=%d dropped (state=%s)',
              [DataLen, IcomStateToString(FState)]);
          end;
        end;
      end;
  end;
end;

// ============================================================================
// Control Packet Handling (Are You Here/Ready, Disconnect)
// ============================================================================

procedure TIcomNetworkTransport.HandleControlResponse(
  const Data: array of Byte; DataLen: Integer; FromCivSocket: Boolean);
var
  Pkt: TControlPacket;
begin
  Move(Data[0], Pkt, SizeOf(TControlPacket));

  case Pkt.PktType of
    ICOM_PKT_I_AM_HERE:
      begin
        if FromCivSocket then
        begin
          // CI-V socket handshake
          if FState = icsCIVWaitingForHere then
          begin
            FCivRemoteId := Pkt.SentID;
            logger.Info('[IcomTransport] CI-V I Am Here received, remoteId=$%.8x',
                        [FCivRemoteId]);

            // Send "Are You Ready" on CI-V socket
            Inc(FCivSeq);
            SendControlPacket(ICOM_PKT_ARE_YOU_READY, FCivSocket,
              FCivRemoteId, FRadioAddress, FCivPort, FCivSeq);
            SetState(icsCIVWaitingForReady);
          end;
        end
        else
        begin
          // Control socket handshake
          if FState = icsWaitingForHere then
          begin
            FRemoteId := Pkt.SentID;
            logger.Info('[IcomTransport] Control I Am Here received, remoteId=$%.8x',
                        [FRemoteId]);

            // Kill AYT timer
            KillTimer(FTimerWnd, ICOM_TIMER_AYT);

            // Send "Are You Ready"
            Inc(FSendSeq);
            SendControlPacket(ICOM_PKT_ARE_YOU_READY, FControlSocket,
              FRemoteId, FRadioAddress, FControlPort, FSendSeq);
            SetState(icsWaitingForReady);
          end;
        end;
      end;

    ICOM_PKT_ARE_YOU_READY:
      begin
        if FromCivSocket then
        begin
          if FState = icsCIVWaitingForReady then
          begin
            logger.Info('[IcomTransport] CI-V I Am Ready received');

            // Send CI-V Open BEFORE transitioning to connected so the radio
            // is ready to respond when our initial freq/mode queries arrive
            // (OnNetworkStateChange fires synchronously inside SetState)
            SendCivOpen;

            // Start keepalive timers
            StartTimers;

            // Transition to connected — fires OnNetworkStateChange which
            // sends initial QueryVFOAFrequency / QueryMode / transceive check
            SetState(icsConnected);

            // Small delay before sending CI-V commands
            FLastCivData := GetTickCount;
            logger.Info('[IcomTransport] Fully connected to %s', [FRadioName]);
          end;
        end
        else
        begin
          if FState = icsWaitingForReady then
          begin
            logger.Info('[IcomTransport] Control I Am Ready received');

            // Send Login
            SendLoginPacket;
            SetState(icsWaitingForLogin);
          end;
        end;
      end;

    ICOM_PKT_DISCONNECT:
      begin
        logger.Warn('[IcomTransport] Disconnect received from radio');
        Disconnect;
      end;
  end;
end;

// ============================================================================
// Ping Handling
// ============================================================================

procedure TIcomNetworkTransport.HandlePingPacket(
  const Data: array of Byte; DataLen: Integer;
  FromCivSocket: Boolean; PeerIP: string; PeerPort: Word);
var
  Pkt: TPingPacket;
  ExpectedId: LongWord;
begin
  if DataLen < SizeOf(TPingPacket) then Exit;
  Move(Data[0], Pkt, SizeOf(TPingPacket));

  if Pkt.Reply = 0 then
  begin
    // Only respond to pings addressed to our own session.
    // Pings addressed to a different RcvdID belong to a stale/other session -
    // ignoring them lets the radio time out dead sessions faster.
    // Always use FMyId — radio identifies us by the control-socket ID from authentication
    ExpectedId := FMyId;

    if (ExpectedId <> 0) and (Pkt.RcvdID <> ExpectedId) then
    begin
      logger.Debug('[IcomTransport] Ignoring ping to stale session $%.8x (ours: $%.8x)',
                   [Pkt.RcvdID, ExpectedId]);
      Exit;
    end;

    // Ping request addressed to us - send response
    if FromCivSocket then
      SendPingResponse(Data, DataLen, FCivSocket, PeerIP, PeerPort)
    else
      SendPingResponse(Data, DataLen, FControlSocket, PeerIP, PeerPort);
  end;
  // Ping response - ignore (just keepalive confirmation)
end;

// ============================================================================
// Login Response
// ============================================================================

procedure TIcomNetworkTransport.HandleLoginResponse(
  const Data: array of Byte; DataLen: Integer);
var
  Pkt: TLoginResponsePacket;
begin
  if DataLen < SizeOf(TLoginResponsePacket) then Exit;
  Move(Data[0], Pkt, SizeOf(TLoginResponsePacket));

  // Check for auth failure
  if Pkt.Error = ICOM_AUTH_FAILED then
  begin
    logger.Error('[IcomTransport] Authentication failed - check username/password');
    Disconnect;
    Exit;
  end;

  // Save token and auth start ID
  FToken := Pkt.Token;
  FAuthStartId := Pkt.AuthStartID;
  logger.Info('[IcomTransport] Login successful, token=$%.8x, authStartId=$%.4x',
              [FToken, FAuthStartId]);

  // Send Token Acknowledgment
  SendTokenAck;
  SetState(icsWaitingForToken);
end;

// ============================================================================
// Capabilities
// ============================================================================

procedure TIcomNetworkTransport.HandleCapabilities(
  const Data: array of Byte; DataLen: Integer);
var
  CapHdr: TCapabilitiesPacket;
  NumRadios: Word;
  RadioCap: TRadioCapPacket;
  Offset: Integer;
  I: Integer;
  NameStr: string;
  RcvBufSize: Integer;
begin
  if DataLen < SizeOf(TCapabilitiesPacket) then Exit;
  Move(Data[0], CapHdr, SizeOf(TCapabilitiesPacket));

  NumRadios := SwapWord(CapHdr.NumRadios);
  logger.Info('[IcomTransport] Capabilities received, %d radio(s)', [NumRadios]);

  // Parse first radio entry (we only care about the first one)
  Offset := SizeOf(TCapabilitiesPacket);
  if (NumRadios > 0) and (DataLen >= Offset + SizeOf(TRadioCapPacket)) then
  begin
    Move(Data[Offset], RadioCap, SizeOf(TRadioCapPacket));

    // Extract radio name (null-terminated string)
    SetLength(NameStr, 32);
    Move(RadioCap.RadioName[0], NameStr[1], 32);
    I := Pos(#0, NameStr);
    if I > 0 then
      SetLength(NameStr, I - 1);
    FRadioName := Trim(NameStr);

    // Save CI-V address and MAC
    FCivAddress := RadioCap.CivAddress;
    Move(RadioCap.MacAddress, FMacAddress, 6);
    FCommonCap := RadioCap.CommonCap;

    logger.Info('[IcomTransport] Radio: %s, CI-V address=$%.2x, CommonCap=$%.4x',
                [FRadioName, FCivAddress, FCommonCap]);
  end;

  // Create CI-V socket now so we can tell the radio our local CI-V port in the stream request
  if FCivSocket = nil then
  begin
    FCivSocket := TIdUDPServer.Create(nil);
    FCivSocket.ThreadedEvent := True;
    FCivSocket.OnUDPRead := HandleCivUDPRead;
    FCivSocket.Bindings.Add;  // Let OS pick any available port (IP and Port left as defaults)
    FCivSocket.Active := True;

    // Increase UDP receive buffer to 256KB to reduce packet loss under load
    RcvBufSize := 256 * 1024;
    WinSock.setsockopt(FCivSocket.Bindings[0].Handle, SOL_SOCKET, SO_RCVBUF,
      PChar(@RcvBufSize), SizeOf(RcvBufSize));

    logger.Debug('[IcomTransport] CI-V socket pre-bound to port %d',
                 [FCivSocket.Bindings[0].Port]);
  end;

  // Send Stream Request (includes our local CI-V port so radio knows where to connect)
  SendStreamRequest;
  SetState(icsWaitingForStream);
end;

// ============================================================================
// Status Packet (CI-V port info)
// ============================================================================

procedure TIcomNetworkTransport.HandleStatusPacket(
  const Data: array of Byte; DataLen: Integer);
var
  Pkt: TStatusPacket;
begin
  if DataLen < SizeOf(TStatusPacket) then Exit;
  Move(Data[0], Pkt, SizeOf(TStatusPacket));

  // Check for connection error
  if Pkt.Error = $FFFFFFFF then
  begin
    logger.Error('[IcomTransport] Stream request failed (error=$FFFFFFFF)');
    Disconnect;
    Exit;
  end;

  // Extract CI-V port (big-endian)
  FCivPort := SwapWord(Pkt.CivPort);
  if FCivPort = 0 then
    FCivPort := ICOM_DEFAULT_CIV_PORT;  // Fallback

  logger.Info('[IcomTransport] Status received, CI-V port=%d', [FCivPort]);

  // CI-V socket was already created in HandleCapabilities before the stream request,
  // so the radio already knows our local CI-V port from the conninfo packet.
  FCivMyId := CalculateMyIdFromSocket(FCivSocket);
  logger.Debug('[IcomTransport] My CI-V ID: $%.8x', [FCivMyId]);

  // Start CI-V socket handshake
  FCivSeq := 0;
  FCivInnerSeq := 0;

  // Send "Are You There" on CI-V socket — Seq=0 (do NOT increment, matches control socket AYT pattern)
  logger.Debug('[IcomTransport] Sending CI-V AYT: localPort=%d -> %s:%d myId=$%.8x',
    [FCivSocket.Bindings[0].Port, FRadioAddress, FCivPort, FMyId]);
  SendControlPacket(ICOM_PKT_ARE_YOU_THERE, FCivSocket,
    0, FRadioAddress, FCivPort, FCivSeq);
  SetState(icsCIVWaitingForHere);
end;

// ============================================================================
// CI-V Data Packet Handling
// ============================================================================

procedure TIcomNetworkTransport.HandleDataPacket(
  const Data: array of Byte; DataLen: Integer);
begin
  if DataLen < ICOM_DATA_HDR_SIZE then Exit;

  FLastCivData := GetTickCount;

  // Extract CI-V frames from the data
  ExtractCivFrames(Data, DataLen);
end;

procedure TIcomNetworkTransport.ExtractCivFrames(
  const Data: array of Byte; DataLen: Integer);
var
  I, FrameStart, FrameEnd: Integer;
  Frame: string;
begin
  // Search for FE FE ... FD patterns in raw packet data
  I := 0;
  while I < DataLen - 1 do
  begin
    // Look for preamble FE FE
    if (Data[I] = CIV_PREAMBLE) and (Data[I + 1] = CIV_PREAMBLE) then
    begin
      FrameStart := I;

      // Find matching FD
      FrameEnd := -1;
      I := I + 2;
      while I < DataLen do
      begin
        if Data[I] = CIV_EOM then
        begin
          FrameEnd := I;
          Break;
        end;
        Inc(I);
      end;

      if FrameEnd > FrameStart then
      begin
        // Extract frame as string (FE FE ... FD inclusive)
        SetLength(Frame, FrameEnd - FrameStart + 1);
        Move(Data[FrameStart], Frame[1], Length(Frame));

        logger.Trace('[IcomTransport] Extracted CI-V frame, len=%d', [Length(Frame)]);

        // Forward to callback
        if Assigned(FOnCivData) then
        begin
          try
            FOnCivData(Frame);
          except
            on E: Exception do
              logger.Error('[IcomTransport] Exception in CI-V callback: %s', [E.Message]);
          end;
        end;
      end;
    end;

    Inc(I);
  end;
end;

// ============================================================================
// Packet Building and Sending
// ============================================================================

procedure TIcomNetworkTransport.SendControlPacket(PktType: Word;
  Socket: TIdUDPServer; RemoteId: LongWord;
  TargetAddr: string; TargetPort: Word; var SeqCounter: Word);
var
  Pkt: TControlPacket;
begin
  // Always use FMyId — radio identifies us by the control-socket ID from authentication

  FillChar(Pkt, SizeOf(Pkt), 0);
  Pkt.Len := ICOM_CONTROL_PKT_SIZE;
  Pkt.PktType := PktType;
  Pkt.Seq := SeqCounter;
  Pkt.SentID := FMyId;
  Pkt.RcvdID := RemoteId;

  FSendLock.Enter;
  try
    SendRawPacket(Socket, Pkt, SizeOf(Pkt), TargetAddr, TargetPort);
  finally
    FSendLock.Leave;
  end;

  logger.Trace('[IcomTransport] Sent control packet: type=$%.4x seq=%d myId=$%.8x rcvdId=$%.8x',
               [PktType, SeqCounter, FMyId, RemoteId]);
end;

procedure TIcomNetworkTransport.SendPingResponse(
  const Data: array of Byte; DataLen: Integer;
  Socket: TIdUDPServer; TargetAddr: string; TargetPort: Word);
var
  Pkt: TPingPacket;
  MyId: LongWord;
begin
  if DataLen < SizeOf(TPingPacket) then Exit;
  Move(Data[0], Pkt, SizeOf(TPingPacket));

  // Always use FMyId — same ID used across both sockets
  // Swap sender/receiver and set reply flag
  Pkt.RcvdID := Pkt.SentID;
  Pkt.SentID := FMyId;
  Pkt.Reply := 1;
  Inc(FPingSendSeq);
  Pkt.Seq := FPingSendSeq;

  FSendLock.Enter;
  try
    SendRawPacket(Socket, Pkt, SizeOf(Pkt), TargetAddr, TargetPort);
  finally
    FSendLock.Leave;
  end;
end;

procedure TIcomNetworkTransport.SendPing;
var
  Pkt: TPingPacket;
begin
  FillChar(Pkt, SizeOf(Pkt), 0);
  Pkt.Len := ICOM_PING_PKT_SIZE;
  Pkt.PktType := ICOM_PKT_PING;
  Inc(FPingSendSeq);
  Pkt.Seq := FPingSendSeq;
  Pkt.SentID := FMyId;
  Pkt.RcvdID := FRemoteId;
  Pkt.Reply := 0;
  Pkt.Time := GetTickCount - FStartTick;

  FSendLock.Enter;
  try
    SendRawPacket(FControlSocket, Pkt, SizeOf(Pkt),
      FRadioAddress, FControlPort);
  finally
    FSendLock.Leave;
  end;
end;

procedure TIcomNetworkTransport.SendLoginPacket;
var
  Pkt: TLoginPacket;
  I: Integer;
begin
  FillChar(Pkt, SizeOf(Pkt), 0);
  Pkt.Len := ICOM_LOGIN_PKT_SIZE;
  Pkt.PktType := ICOM_PKT_DATA;  // Auth packets use PktType=0 (same as DATA)
  // Auth packets use their own seq counter starting at 1 (separate from control seq)
  FAuthOuterSeq := 1;
  Pkt.Seq := FAuthOuterSeq;
  Pkt.SentID := FMyId;
  Pkt.RcvdID := FRemoteId;
  Pkt.PayloadSize := SwapLongWord(ICOM_LOGIN_PKT_SIZE - $10);
  Pkt.RequestReply := $01;
  Pkt.RequestType := $00;
  Pkt.InnerSeq := SwapWord(FAuthSeq);
  Inc(FAuthSeq);

  // Random token request
  Randomize;
  FTokRequest := Word(Random($FFFF));
  Pkt.TokRequest := FTokRequest;
  Pkt.Token := 0;  // No token yet

  // Encode username and password
  IcomPasscode(FUsername, Pkt.Username);
  IcomPasscode(FPassword, Pkt.Password);

  // Client name (ASCII, null-padded)
  for I := 1 to Length(FClientName) do
  begin
    if I > 16 then Break;
    Pkt.ClientName[I - 1] := Byte(FClientName[I]);
  end;

  FSendLock.Enter;
  try
    SendRawPacket(FControlSocket, Pkt, SizeOf(Pkt),
      FRadioAddress, FControlPort);
  finally
    FSendLock.Leave;
  end;

  logger.Debug('[IcomTransport] Sent login packet, authSeq=$%.4x', [FAuthSeq]);
  logger.Debug('[IcomTransport] Login packet hex: %s', [BytesToHexStr(Pkt, SizeOf(Pkt))]);
end;

procedure TIcomNetworkTransport.SendTokenAck;
var
  Pkt: TTokenPacket;
begin
  FillChar(Pkt, SizeOf(Pkt), 0);
  Pkt.Len := ICOM_TOKEN_PKT_SIZE;
  Pkt.PktType := ICOM_PKT_DATA;  // Auth packets use PktType=0 (same as DATA)
  Inc(FAuthOuterSeq);
  Pkt.Seq := FAuthOuterSeq;
  Pkt.SentID := FMyId;
  Pkt.RcvdID := FRemoteId;
  Pkt.PayloadSize := SwapLongWord(ICOM_TOKEN_PKT_SIZE - $10);
  Pkt.RequestReply := $01;
  Pkt.RequestType := ICOM_TOKEN_ACK;
  Pkt.InnerSeq := SwapWord(FAuthSeq);
  Inc(FAuthSeq);
  Pkt.TokRequest := FTokRequest;
  Pkt.Token := FToken;
  Pkt.AuthStartID := FAuthStartId;
  Pkt.ResetCap := SwapWord(ICOM_RESET_CAP);
  Pkt.CommonCap := FCommonCap;
  Move(FMacAddress, Pkt.MacAddress, 6);

  FSendLock.Enter;
  try
    SendRawPacket(FControlSocket, Pkt, SizeOf(Pkt),
      FRadioAddress, FControlPort);
  finally
    FSendLock.Leave;
  end;

  logger.Debug('[IcomTransport] Sent token ack, token=$%.8x', [FToken]);
end;

procedure TIcomNetworkTransport.SendTokenRenew;
var
  Pkt: TTokenPacket;
begin
  FillChar(Pkt, SizeOf(Pkt), 0);
  Pkt.Len := ICOM_TOKEN_PKT_SIZE;
  Pkt.PktType := ICOM_PKT_DATA;  // Auth packets use PktType=0 (same as DATA)
  Inc(FAuthOuterSeq);
  Pkt.Seq := FAuthOuterSeq;
  Pkt.SentID := FMyId;
  Pkt.RcvdID := FRemoteId;
  Pkt.PayloadSize := SwapLongWord(ICOM_TOKEN_PKT_SIZE - $10);
  Pkt.RequestReply := $01;
  Pkt.RequestType := ICOM_TOKEN_RENEW;
  Inc(FAuthSeq);
  Pkt.InnerSeq := SwapWord(FAuthSeq);
  Pkt.TokRequest := FTokRequest;
  Pkt.Token := FToken;
  Pkt.AuthStartID := FAuthStartId;
  Pkt.ResetCap := SwapWord(ICOM_RESET_CAP);
  Pkt.CommonCap := FCommonCap;
  Move(FMacAddress, Pkt.MacAddress, 6);

  FSendLock.Enter;
  try
    SendRawPacket(FControlSocket, Pkt, SizeOf(Pkt),
      FRadioAddress, FControlPort);
  finally
    FSendLock.Leave;
  end;

  logger.Trace('[IcomTransport] Sent token renewal');
end;

procedure TIcomNetworkTransport.SendStreamRequest;
var
  Pkt: TConnInfoPacket;
  I: Integer;
  NameBytes: string;
begin
  FillChar(Pkt, SizeOf(Pkt), 0);
  Pkt.Len := ICOM_CONNINFO_PKT_SIZE;
  Pkt.PktType := ICOM_PKT_DATA;  // Auth packets use PktType=0 (same as DATA)
  Inc(FAuthOuterSeq);
  Pkt.Seq := FAuthOuterSeq;
  Pkt.SentID := FMyId;
  Pkt.RcvdID := FRemoteId;
  Pkt.PayloadSize := SwapLongWord(ICOM_CONNINFO_PKT_SIZE - $10);
  Pkt.RequestReply := $01;
  Pkt.RequestType := ICOM_CONNINFO_REQUEST;
  Pkt.InnerSeq := SwapWord(FAuthSeq);
  Inc(FAuthSeq);
  Pkt.TokRequest := FTokRequest;
  Pkt.Token := FToken;

  // Copy MAC/GUID based on capabilities
  if (FCommonCap and $8010) = $8010 then
  begin
    // MAC-based
    Move(FMacAddress, Pkt.GUID[10], 6);  // MAC at offset $0A within GUID field
    Pkt.GUID[7] := Hi(FCommonCap);
    Pkt.GUID[8] := Lo(FCommonCap);
  end
  else
    Move(FGUID, Pkt.GUID, 16);

  // Radio name
  NameBytes := FRadioName;
  for I := 1 to Length(NameBytes) do
  begin
    if I > 32 then Break;
    Pkt.RadioName[I - 1] := Byte(NameBytes[I]);
  end;

  // Encoded username
  IcomPasscode(FUsername, Pkt.Username);

  // Stream parameters (CI-V control only, no audio)
  Pkt.RxEnable := 1;
  Pkt.TxEnable := 0;
  Pkt.RxCodec := $04;  // LPCM
  Pkt.TxCodec := 0;
  Pkt.RxSample := SwapLongWord(8000);
  Pkt.TxSample := 0;

  // Tell radio our local CI-V port so it knows where to send CI-V data
  if (FCivSocket <> nil) and (FCivSocket.Bindings.Count > 0) then
    Pkt.CivPort := SwapLongWord(FCivSocket.Bindings[0].Port)
  else
    Pkt.CivPort := 0;
  Pkt.AudioPort := 0;
  Pkt.TxBuffer := 0;
  Pkt.Convert := 1;

  FSendLock.Enter;
  try
    SendRawPacket(FControlSocket, Pkt, SizeOf(Pkt),
      FRadioAddress, FControlPort);
  finally
    FSendLock.Leave;
  end;

  logger.Debug('[IcomTransport] Sent stream request for radio %s (civport field=$%.8x)',
    [FRadioName, Pkt.CivPort]);
  logger.Debug('[IcomTransport] Stream request hex: %s', [BytesToHexStr(Pkt, SizeOf(Pkt))]);
end;

procedure TIcomNetworkTransport.SendCivOpen;
var
  Pkt: TOpenClosePacket;
begin
  FillChar(Pkt, SizeOf(Pkt), 0);
  Pkt.Len := ICOM_OPENCLOSE_PKT_SIZE;
  Pkt.PktType := ICOM_PKT_DATA;
  Inc(FCivSeq);
  Pkt.Seq := FCivSeq;
  Pkt.SentID := FMyId;
  Pkt.RcvdID := FCivRemoteId;
  Pkt.Data := ICOM_OPENCLOSE_DATA;
  Pkt.SendSeq := SwapWord(FCivInnerSeq);
  Inc(FCivInnerSeq);
  Pkt.Magic := ICOM_MAGIC_OPEN;

  FSendLock.Enter;
  try
    SendRawPacket(FCivSocket, Pkt, SizeOf(Pkt),
      FRadioAddress, FCivPort);
  finally
    FSendLock.Leave;
  end;

  logger.Debug('[IcomTransport] Sent CI-V Open');
end;

procedure TIcomNetworkTransport.SendCivClose;
var
  Pkt: TOpenClosePacket;
begin
  FillChar(Pkt, SizeOf(Pkt), 0);
  Pkt.Len := ICOM_OPENCLOSE_PKT_SIZE;
  Pkt.PktType := ICOM_PKT_DATA;
  Inc(FCivSeq);
  Pkt.Seq := FCivSeq;
  Pkt.SentID := FMyId;
  Pkt.RcvdID := FCivRemoteId;
  Pkt.Data := ICOM_OPENCLOSE_DATA;
  Pkt.SendSeq := SwapWord(FCivInnerSeq);
  Inc(FCivInnerSeq);
  Pkt.Magic := ICOM_MAGIC_CLOSE;

  FSendLock.Enter;
  try
    SendRawPacket(FCivSocket, Pkt, SizeOf(Pkt),
      FRadioAddress, FCivPort);
  finally
    FSendLock.Leave;
  end;

  logger.Debug('[IcomTransport] Sent CI-V Close');
end;

procedure TIcomNetworkTransport.SendIdlePacket;
var
  Pkt: TControlPacket;
begin
  if FCivSocket = nil then Exit;

  FillChar(Pkt, SizeOf(Pkt), 0);
  Pkt.Len := ICOM_CONTROL_PKT_SIZE;
  Pkt.PktType := ICOM_PKT_DATA;
  Inc(FCivSeq);
  Pkt.Seq := FCivSeq;
  Pkt.SentID := FMyId;
  Pkt.RcvdID := FCivRemoteId;

  FSendLock.Enter;
  try
    SendRawPacket(FCivSocket, Pkt, SizeOf(Pkt),
      FRadioAddress, FCivPort);
  finally
    FSendLock.Leave;
  end;
end;

procedure TIcomNetworkTransport.SendRawPacket(Socket: TIdUDPServer;
  const Data; DataLen: Integer; TargetAddr: string; TargetPort: Word);
type
  // Minimal sockaddr_in layout - avoids type conflicts between Windows/WinSock2
  TSockAddrIn4 = packed record
    sin_family: Word;
    sin_port:   Word;
    sin_addr:   LongWord;
    sin_zero:   array[0..7] of Byte;
  end;
var
  SockHandle: Integer;
  Addr: TSockAddrIn4;
  Ret: Integer;
begin
  // Use direct WinSock sendto() to avoid TIdUDPServer.SendBuffer deadlock
  // when called from the main thread while Indy read threads are active.
  if Socket.Bindings.Count = 0 then
  begin
    logger.Error('[IcomTransport] SendRawPacket: no socket binding');
    Exit;
  end;

  SockHandle := Socket.Bindings[0].Handle;

  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := 2;  // AF_INET
  Addr.sin_port   := (TargetPort shr 8) or ((TargetPort and $FF) shl 8);  // htons
  Addr.sin_addr   := LongWord(inet_addr(PChar(TargetAddr)));

  Ret := ws2_sendto(SockHandle, Data, DataLen, 0, Addr, SizeOf(Addr));
  if Ret < 0 then
    logger.Error('[IcomTransport] SendRawPacket sendto failed');
end;

// ============================================================================
// State Management
// ============================================================================

procedure TIcomNetworkTransport.SetState(NewState: TIcomConnectionState);
begin
  if FState <> NewState then
  begin
    logger.Info('[IcomTransport] State: %s -> %s',
                [IcomStateToString(FState), IcomStateToString(NewState)]);
    FState := NewState;

    // Manage the login retry timer
    if (NewState = icsWaitingForLogin) and (FTimerWnd <> 0) then
    begin
      FLoginRetryCount := 0;
      SetTimer(FTimerWnd, ICOM_TIMER_LOGIN, ICOM_LOGIN_TIMEOUT, nil);
    end
    else if FTimerWnd <> 0 then
      KillTimer(FTimerWnd, ICOM_TIMER_LOGIN);

    // On connect: fire a one-shot 250ms timer to seed freq/mode after the radio
    // has had time to process the CI-V Open packet (radio ignores queries sent
    // immediately after Open — this matches TR4QT/wfview behaviour)
    if (NewState = icsConnected) and (FTimerWnd <> 0) then
      SetTimer(FTimerWnd, ICOM_TIMER_INITIAL_POLL, 250, nil);

    if Assigned(FOnStateChange) then
    begin
      try
        FOnStateChange(Self);
      except
        on E: Exception do
          logger.Error('[IcomTransport] Exception in state change callback: %s', [E.Message]);
      end;
    end;
  end;
end;

function TIcomNetworkTransport.GetIsConnected: Boolean;
begin
  Result := (FState = icsConnected);
end;

// ============================================================================
// Timer Management
// ============================================================================

procedure TIcomNetworkTransport.StartTimers;
begin
  if FTimerWnd = 0 then Exit;

  SetTimer(FTimerWnd, ICOM_TIMER_PING, ICOM_PING_INTERVAL, nil);
  SetTimer(FTimerWnd, ICOM_TIMER_IDLE, ICOM_IDLE_INTERVAL, nil);
  SetTimer(FTimerWnd, ICOM_TIMER_TOKEN, ICOM_TOKEN_RENEWAL_INTERVAL, nil);
  // Retransmit timer disabled — CI-V over LAN doesn't need app-level retransmit
  SetTimer(FTimerWnd, ICOM_TIMER_CIV_WATCHDOG, ICOM_CIV_WATCHDOG_INTERVAL, nil);

  logger.Debug('[IcomTransport] All timers started');
end;

procedure TIcomNetworkTransport.StopTimers;
begin
  if FTimerWnd = 0 then Exit;

  KillTimer(FTimerWnd, ICOM_TIMER_PING);
  KillTimer(FTimerWnd, ICOM_TIMER_IDLE);
  KillTimer(FTimerWnd, ICOM_TIMER_TOKEN);
  KillTimer(FTimerWnd, ICOM_TIMER_RETRANSMIT);
  KillTimer(FTimerWnd, ICOM_TIMER_CIV_WATCHDOG);
  KillTimer(FTimerWnd, ICOM_TIMER_AYT);
  KillTimer(FTimerWnd, ICOM_TIMER_LOGIN);

  logger.Debug('[IcomTransport] All timers stopped');
end;

procedure TIcomNetworkTransport.OnPingTimer;
begin
  if FState = icsConnected then
    SendPing;
end;

procedure TIcomNetworkTransport.OnIdleTimer;
begin
  if FState = icsConnected then
    SendIdlePacket;
end;

procedure TIcomNetworkTransport.OnTokenRenewalTimer;
begin
  if FState = icsConnected then
    SendTokenRenew;
end;

procedure TIcomNetworkTransport.OnRetransmitTimer;
var
  I: Integer;
  Entry: PRetransmitEntry;
  Now: LongWord;
begin
  if FState <> icsConnected then Exit;

  Now := GetTickCount;
  for I := FRetransmitList.Count - 1 downto 0 do
  begin
    Entry := PRetransmitEntry(FRetransmitList[I]);
    if (Now - Entry^.SendTime) > 1000 then  // 1 second timeout
    begin
      if Entry^.Retries < 3 then
      begin
        // Retransmit
        Inc(Entry^.Retries);
        Entry^.SendTime := Now;

        FSendLock.Enter;
        try
          if (FCivSocket <> nil) and (Length(Entry^.Data) > 0) then
            SendRawPacket(FCivSocket, Entry^.Data[1], Length(Entry^.Data),
              FRadioAddress, FCivPort);
        finally
          FSendLock.Leave;
        end;

        logger.Debug('[IcomTransport] Retransmit seq=%d, attempt=%d',
                     [Entry^.Seq, Entry^.Retries]);
      end
      else
      begin
        // Too many retries - remove
        Dispose(Entry);
        FRetransmitList.Delete(I);
      end;
    end;
  end;
end;

procedure TIcomNetworkTransport.OnCivWatchdogTimer;
var
  Elapsed: LongWord;
begin
  if FState <> icsConnected then Exit;

  Elapsed := GetTickCount - FLastCivData;
  if Elapsed > ICOM_CIV_TIMEOUT_THRESHOLD then
  begin
    logger.Warn('[IcomTransport] CI-V data timeout (%d ms), re-sending CI-V Open',
                [Elapsed]);
    SendCivOpen;
    FLastCivData := GetTickCount;
  end;
end;

procedure TIcomNetworkTransport.OnAYTTimer;
begin
  if FState <> icsWaitingForHere then
  begin
    KillTimer(FTimerWnd, ICOM_TIMER_AYT);
    Exit;
  end;

  Inc(FAYTRetryCount);
  if FAYTRetryCount > ICOM_AYT_MAX_RETRIES then
  begin
    logger.Error('[IcomTransport] Radio not found at %s:%d after %d retries',
                 [FRadioAddress, FControlPort, ICOM_AYT_MAX_RETRIES]);
    KillTimer(FTimerWnd, ICOM_TIMER_AYT);
    Disconnect;
    Exit;
  end;

  // Exponential backoff
  FAYTInterval := FAYTInterval * 2;
  if FAYTInterval > ICOM_AYT_MAX_INTERVAL then
    FAYTInterval := ICOM_AYT_MAX_INTERVAL;

  // Resend "Are You There" — AYT always uses Seq=0, same as initial send
  SendControlPacket(ICOM_PKT_ARE_YOU_THERE, FControlSocket,
    0, FRadioAddress, FControlPort, FSendSeq);

  // Update timer interval
  KillTimer(FTimerWnd, ICOM_TIMER_AYT);
  SetTimer(FTimerWnd, ICOM_TIMER_AYT, FAYTInterval, nil);

  logger.Debug('[IcomTransport] AYT retry %d/%d, interval=%dms',
               [FAYTRetryCount, ICOM_AYT_MAX_RETRIES, FAYTInterval]);
end;

procedure TIcomNetworkTransport.OnLoginTimer;
begin
  if FState <> icsWaitingForLogin then
  begin
    KillTimer(FTimerWnd, ICOM_TIMER_LOGIN);
    Exit;
  end;

  Inc(FLoginRetryCount);
  if FLoginRetryCount > ICOM_LOGIN_MAX_RETRIES then
  begin
    logger.Error('[IcomTransport] No login response after %d retries - giving up',
                 [ICOM_LOGIN_MAX_RETRIES]);
    KillTimer(FTimerWnd, ICOM_TIMER_LOGIN);
    Disconnect;
    Exit;
  end;

  // Resend login packet. The radio may have been busy or a stale session
  // (from a previous run) may still be active on the radio. By not responding
  // to pings for that stale session we allow the radio to time it out, after
  // which a retry of the login should succeed.
  logger.Debug('[IcomTransport] Login timeout - resending login packet (retry %d/%d)',
               [FLoginRetryCount, ICOM_LOGIN_MAX_RETRIES]);
  SendLoginPacket;
end;

procedure TIcomNetworkTransport.OnInitialPollTimer;
begin
  // One-shot timer: kill ourselves immediately so we only fire once
  KillTimer(FTimerWnd, ICOM_TIMER_INITIAL_POLL);

  if FState <> icsConnected then Exit;

  // 250ms has elapsed since CI-V Open — radio is ready to respond to queries.
  // Use the dedicated OnInitialPoll callback so TIcomRadio can send its
  // initial freq/mode queries without conflating with general state changes.
  logger.Info('[IcomTransport] Initial poll delay complete - seeding freq/mode');
  if Assigned(FOnInitialPoll) then
  begin
    try
      FOnInitialPoll(Self);
    except
      on E: Exception do
        logger.Error('[IcomTransport] Exception in initial poll callback: %s', [E.Message]);
    end;
  end;
end;

// ============================================================================
// Retransmit Buffer
// ============================================================================

procedure TIcomNetworkTransport.AddToRetransmitBuffer(Seq: Word; const Data: string);
var
  Entry: PRetransmitEntry;
begin
  New(Entry);
  Entry^.Seq := Seq;
  Entry^.Data := Data;
  Entry^.SendTime := GetTickCount;
  Entry^.Retries := 0;
  FRetransmitList.Add(Entry);

  // Limit buffer size
  while FRetransmitList.Count > 100 do
  begin
    Entry := PRetransmitEntry(FRetransmitList[0]);
    Dispose(Entry);
    FRetransmitList.Delete(0);
  end;
end;

procedure TIcomNetworkTransport.RemoveFromRetransmitBuffer(Seq: Word);
var
  I: Integer;
  Entry: PRetransmitEntry;
begin
  for I := FRetransmitList.Count - 1 downto 0 do
  begin
    Entry := PRetransmitEntry(FRetransmitList[I]);
    if Entry^.Seq = Seq then
    begin
      Dispose(Entry);
      FRetransmitList.Delete(I);
      Break;
    end;
  end;
end;

procedure TIcomNetworkTransport.ClearRetransmitBuffer;
var
  I: Integer;
begin
  for I := FRetransmitList.Count - 1 downto 0 do
    Dispose(PRetransmitEntry(FRetransmitList[I]));
  FRetransmitList.Clear;
end;

// ============================================================================
// Initialization
// ============================================================================

initialization
  logger := TLogLogger.GetLogger('uIcomNetworkTransport');
  logger.Level := All;
  GTransportInstance := nil;

end.
