unit uDXLabPathfinder;

{
  DXLab Pathfinder DDE Integration for TR4W

  Registers TR4W as "Pathfinder" on the DDE service bus, then sends a
  "002start" handshake to SpotCollector. When a user double-clicks a spot in
  SpotCollector the callsign arrives via a DDE EXECUTE command and is placed
  in TR4W's call-entry window.

  Enable in tr4w.cfg / tr4w.ini:
    SPOT COLLECTOR ENABLED = TRUE

  If the real DXLab PathFinder application is already running, TR4W will not
  attempt to register and will silently do nothing.
}

interface

function  StartDXLabPathfinder: boolean;
procedure StopDXLabPathfinder;
function  IsDXLabPathfinderRunning: boolean;

implementation

uses
  Windows, SysUtils, VC, MainUnit;

// ---------------------------------------------------------------------------
// Raw DDEML Win32 API declarations
// (All handle types map to THandle to avoid conflicts with Windows.pas)
// ---------------------------------------------------------------------------

const
  DMLERR_NO_ERROR      = 0;
  APPCLASS_STANDARD    = $00000000;
  APPCMD_CLIENTONLY    = $00000010;
  DNS_REGISTER         = $0001;
  DNS_UNREGISTER       = $0002;
  XTYP_CONNECT         = $1062;
  XTYP_CONNECT_CONFIRM = $8072;
  XTYP_EXECUTE         = $4050;
  XTYP_WILDCONNECT     = $20A2;
  XTYP_ADVSTART        = $1030;
  DDE_FACK             = $8000;
  DDE_FNOTPROCESSED    = 0;
  CP_WINANSI_          = 1004;  // DDEML CP_WINANSI value (renamed to avoid clash with Windows unit)
  QSLINFO_SERVER_ID    = 2;     // PathFinder (QSLInfoServer) ID in DXLab

function DdeInitializeA(var pidInst: DWORD; pfnCallback: Pointer;
  afCmd: DWORD; ulRes: DWORD): UINT;
  stdcall; external 'user32.dll' name 'DdeInitializeA';

function DdeUninitialize(idInst: DWORD): BOOL;
  stdcall; external 'user32.dll' name 'DdeUninitialize';

function DdeCreateStringHandleA(idInst: DWORD; psz: PAnsiChar;
  iCodePage: Integer): THandle;
  stdcall; external 'user32.dll' name 'DdeCreateStringHandleA';

function DdeFreeStringHandle(idInst: DWORD; hsz: THandle): BOOL;
  stdcall; external 'user32.dll' name 'DdeFreeStringHandle';

function DdeNameService(idInst: DWORD; hsz1: THandle; hsz2: THandle;
  afCmd: UINT): THandle;
  stdcall; external 'user32.dll' name 'DdeNameService';

function DdeConnect(idInst: DWORD; hszService: THandle; hszTopic: THandle;
  pCC: Pointer): THandle;
  stdcall; external 'user32.dll' name 'DdeConnect';

function DdeDisconnect(hConv: THandle): BOOL;
  stdcall; external 'user32.dll' name 'DdeDisconnect';

function DdeClientTransaction(pData: Pointer; cbData: DWORD; hConv: THandle;
  hszItem: THandle; wFmt: UINT; wType: UINT; dwTimeout: DWORD;
  pdwResult: PDWORD): THandle;
  stdcall; external 'user32.dll' name 'DdeClientTransaction';

function DdeGetData(hData: THandle; pDst: Pointer; cbMax: DWORD;
  cbOff: DWORD): DWORD;
  stdcall; external 'user32.dll' name 'DdeGetData';

// ---------------------------------------------------------------------------
// Module-level state
// ---------------------------------------------------------------------------

var
  GInstId  : DWORD   = 0;
  GHszSvc  : THandle = 0;
  GRunning : boolean = false;

// ---------------------------------------------------------------------------
// Parse callsign from SpotCollector EXECUTE command
// Format example: "002getqslinfo<callsign:4>AK7G"
// ---------------------------------------------------------------------------

function ParseCallsign(const cmd: string): string;
var
  tag    : string;
  p, q   : integer;
  lenVal : integer;
begin
  Result := '';
  tag := '<callsign:';
  p := Pos(tag, LowerCase(cmd));
  if p = 0 then Exit;
  Inc(p, Length(tag));
  q := p;
  while (q <= Length(cmd)) and (cmd[q] <> '>') do
    Inc(q);
  if q > Length(cmd) then Exit;
  lenVal := StrToIntDef(Copy(cmd, p, q - p), 0);
  if lenVal <= 0 then Exit;
  Result := Trim(Copy(cmd, q + 1, lenVal));
end;

// ---------------------------------------------------------------------------
// DDE callback — must be a plain stdcall function (not a class method)
// ---------------------------------------------------------------------------

function DdeCallback(uType: UINT; uFmt: UINT; hConv: THandle;
  hsz1: THandle; hsz2: THandle; hData: THandle;
  dwData1: DWORD; dwData2: DWORD): THandle; stdcall;
var
  dataSize : DWORD;
  buf      : array[0..511] of AnsiChar;
  cmd      : string;
  callsign : string;
  cs       : CallString;
begin
  Result := DDE_FNOTPROCESSED;

  logger.debug('[uDXLabPathfinder] DdeCallback uType=$%x', [uType]);

  case uType of
    XTYP_CONNECT:
      begin
        logger.debug('[uDXLabPathfinder] XTYP_CONNECT received');
        Result := 1; // TRUE
      end;

    XTYP_CONNECT_CONFIRM:
      begin
        logger.debug('[uDXLabPathfinder] XTYP_CONNECT_CONFIRM received');
        Result := DDE_FNOTPROCESSED;
      end;

    XTYP_WILDCONNECT:
      begin
        logger.debug('[uDXLabPathfinder] XTYP_WILDCONNECT received');
        Result := 1; // TRUE
      end;

    XTYP_EXECUTE:
      begin
        logger.debug('[uDXLabPathfinder] XTYP_EXECUTE received hData=%d', [hData]);
        Result := DDE_FACK;
        if hData = 0 then
        begin
          logger.debug('[uDXLabPathfinder] XTYP_EXECUTE: hData is nil, ignoring');
          Exit;
        end;
        dataSize := DdeGetData(hData, nil, 0, 0);
        logger.debug('[uDXLabPathfinder] XTYP_EXECUTE: dataSize=%d', [dataSize]);
        if (dataSize = 0) or (dataSize > SizeOf(buf)) then
        begin
          logger.debug('[uDXLabPathfinder] XTYP_EXECUTE: bad dataSize, ignoring');
          Exit;
        end;
        FillChar(buf, SizeOf(buf), 0);
        DdeGetData(hData, @buf, dataSize, 0);
        cmd      := string(PAnsiChar(@buf));
        logger.debug('[uDXLabPathfinder] XTYP_EXECUTE: command="%s"', [cmd]);
        callsign := ParseCallsign(cmd);
        logger.debug('[uDXLabPathfinder] XTYP_EXECUTE: parsed callsign="%s"', [callsign]);
        if callsign <> '' then
        begin
          cs := callsign;
          logger.debug('[uDXLabPathfinder] Calling PutCallToCallWindow with "%s"', [callsign]);
          PutCallToCallWindow(cs);
        end;
      end;

    XTYP_ADVSTART:
      begin
        logger.debug('[uDXLabPathfinder] XTYP_ADVSTART received');
        Result := DDE_FACK;
      end;
  end;
end;

// ---------------------------------------------------------------------------
// Send "002start" handshake to SpotCollector
// ---------------------------------------------------------------------------

procedure InformSpotCollector;
var
  hszSvc, hszTop : THandle;
  hConv          : THandle;
  hResult        : THandle;
  cmd            : AnsiString;
begin
  logger.debug('[uDXLabPathfinder] InformSpotCollector: connecting to SpotCollector|DDEClient');
  hszSvc := DdeCreateStringHandleA(GInstId, 'SpotCollector', CP_WINANSI_);
  hszTop := DdeCreateStringHandleA(GInstId, 'DDEClient',     CP_WINANSI_);
  if (hszSvc = 0) or (hszTop = 0) then
  begin
    logger.debug('[uDXLabPathfinder] InformSpotCollector: failed to create string handles');
    if hszSvc <> 0 then DdeFreeStringHandle(GInstId, hszSvc);
    if hszTop <> 0 then DdeFreeStringHandle(GInstId, hszTop);
    Exit;
  end;
  hConv := DdeConnect(GInstId, hszSvc, hszTop, nil);
  if hConv = 0 then
  begin
    logger.debug('[uDXLabPathfinder] InformSpotCollector: DdeConnect failed - SpotCollector not running?');
  end
  else
  begin
    cmd := Format('%.3d', [QSLINFO_SERVER_ID]) + 'start' + #0;
    logger.debug('[uDXLabPathfinder] InformSpotCollector: sending "%s"', [string(cmd)]);
    hResult := DdeClientTransaction(PAnsiChar(cmd), Length(cmd), hConv,
                                    0, 0, XTYP_EXECUTE, 5000, nil);
    if hResult <> 0 then
      logger.debug('[uDXLabPathfinder] InformSpotCollector: handshake OK')
    else
      logger.debug('[uDXLabPathfinder] InformSpotCollector: handshake FAILED');
    DdeDisconnect(hConv);
  end;
  DdeFreeStringHandle(GInstId, hszSvc);
  DdeFreeStringHandle(GInstId, hszTop);
end;

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

function StartDXLabPathfinder: boolean;
var
  checkInst      : DWORD;
  hszSvc, hszTop : THandle;
  hTest          : THandle;
begin
  Result := false;
  logger.debug('[uDXLabPathfinder] StartDXLabPathfinder called');

  if GRunning then
  begin
    logger.debug('[uDXLabPathfinder] Already running, returning true');
    Result := true;
    Exit;
  end;

  // Check if the real PathFinder is already running — if so, do nothing
  checkInst := 0;
  if DdeInitializeA(checkInst, nil, APPCMD_CLIENTONLY, 0) = DMLERR_NO_ERROR then
  begin
    hszSvc := DdeCreateStringHandleA(checkInst, 'Pathfinder', CP_WINANSI_);
    hszTop := DdeCreateStringHandleA(checkInst, 'DDEServer',  CP_WINANSI_);
    hTest  := 0;
    if (hszSvc <> 0) and (hszTop <> 0) then
      hTest := DdeConnect(checkInst, hszSvc, hszTop, nil);
    if hszSvc <> 0 then DdeFreeStringHandle(checkInst, hszSvc);
    if hszTop <> 0 then DdeFreeStringHandle(checkInst, hszTop);
    if hTest <> 0 then
    begin
      DdeDisconnect(hTest);
      DdeUninitialize(checkInst);
      logger.debug('[uDXLabPathfinder] Real PathFinder already running - not registering');
      Exit;
    end;
    DdeUninitialize(checkInst);
  end;

  // Register TR4W as the "Pathfinder" DDE server
  logger.debug('[uDXLabPathfinder] Calling DdeInitializeA as server');
  if DdeInitializeA(GInstId, @DdeCallback, APPCLASS_STANDARD, 0) <> DMLERR_NO_ERROR then
  begin
    logger.debug('[uDXLabPathfinder] DdeInitializeA failed');
    Exit;
  end;

  GHszSvc := DdeCreateStringHandleA(GInstId, 'Pathfinder', CP_WINANSI_);
  if GHszSvc = 0 then
  begin
    logger.debug('[uDXLabPathfinder] DdeCreateStringHandleA for Pathfinder failed');
    DdeUninitialize(GInstId);
    GInstId := 0;
    Exit;
  end;

  if DdeNameService(GInstId, GHszSvc, 0, DNS_REGISTER) = 0 then
  begin
    logger.debug('[uDXLabPathfinder] DdeNameService registration failed');
    DdeFreeStringHandle(GInstId, GHszSvc);
    GHszSvc := 0;
    DdeUninitialize(GInstId);
    GInstId := 0;
    Exit;
  end;

  GRunning := true;
  Result   := true;
  logger.debug('[uDXLabPathfinder] Registered as Pathfinder DDE server OK');

  InformSpotCollector;
end;

procedure StopDXLabPathfinder;
begin
  logger.debug('[uDXLabPathfinder] StopDXLabPathfinder called');
  if not GRunning then Exit;
  if GHszSvc <> 0 then
  begin
    DdeNameService(GInstId, GHszSvc, 0, DNS_UNREGISTER);
    DdeFreeStringHandle(GInstId, GHszSvc);
    GHszSvc := 0;
  end;
  if GInstId <> 0 then
  begin
    DdeUninitialize(GInstId);
    GInstId := 0;
  end;
  GRunning := false;
  logger.debug('[uDXLabPathfinder] Stopped');
end;

function IsDXLabPathfinderRunning: boolean;
begin
  Result := GRunning;
end;

end.
