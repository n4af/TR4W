unit uHamScore;

(*
  HamScore Real-Time Contest (RTC) uploader -- Issue #783.

  Sends QSO contact data and dynamicresults score data to hamscore.com
  (Contest Online ScoreBoard) over HTTPS every 2 minutes per the
  RTC v2.3.3-xml specification (June 2024).

  Architecture
  ------------
  - The main thread enqueues lightweight TRTCContact objects via the
    HamScoreOn{Log,Edit,Delete,DeleteLog} entry points.  Each object
    carries its pre-rendered XML body so the main thread holds no live
    references to mutable globals after enqueue and the worker can post
    without taking any TR4W locks.
  - A worker THamScoreUploader thread sleeps on a stop event with a
    120-second timeout.  Every wake builds one POST containing the
    current <dynamicresults> snapshot plus all queued QSO containers,
    POSTs over HTTPS with HTTP Basic Auth (username = MyCall by default),
    and parses the JSON-style status response.
  - Reliability per spec: if the server's reply does not contain
    "Status":"CFM" (or "Status":"OK" for posts with no QSO data) the
    queued contacts STAY queued and are resent on the next 2-minute
    cycle.  Only an explicit CFM clears the pending list.

  Configuration (uCFG.pas)
  ------------------------
    HAMSCORE ENABLE   = TRUE | FALSE   (default FALSE)
    HAMSCORE URL      = https://...    (default hamscore.com)
    HAMSCORE USERNAME = <call>         (empty -> uses MY CALL)
    HAMSCORE PASSWORD = <pw>           (empty disables uploader at start)

  Integration points
  ------------------
    LOGSUBS2.PAS:LogContact   -> HamScoreOnLog(RXData)
    uEditQSO.pas              -> HamScoreOnEdit(RXData)
                                 HamScoreOnDelete(RXData)
    Tools menu                -> HamScoreResyncFromScratch (Phase 3)

  All entry points are cheap no-ops when the uploader is not running.

  Default decisions made without spec guidance, flagged for review:
  - Mode map: CW->CW, Phone->PH, Digital->RTTY (FT8/FT4/PSK if ExtMode set),
    FM->FM
  - X-QSO records are SENT with <x-qso>1</x-qso>, not skipped
  - No per-contest filtering -- the server returns "Contest not supported"
    for unknown contests; we log and stop trying for the rest of the cycle
  - Both radios share one uploader -- RTC is per-callsign
*)

interface

uses
  Windows, Classes, SysUtils, SyncObjs, IdHTTP, IdSSLOpenSSL,
  VC, Log4D, Version;

type
  TRTCEventKind = (
    rckInfo,         // <contactinfo>    new QSO
    rckReplace,      // <contactreplace> edited QSO
    rckDelete,       // <contactdelete>  deleted QSO
    rckDeleteLog     // <deletelog>      wipe entire log on the server
  );

  // One queue entry. The XML body is rendered at enqueue time on the main
  // thread so the worker can serialise without touching shared globals.
  TRTCContact = class
  public
    Kind:    TRTCEventKind;
    QSOID:   AnsiString;       // RXData.id (TR4W per-QSO GUID); empty for rckDeleteLog
    XmlBody: AnsiString;       // Complete <contactinfo>...</contactinfo> fragment
    constructor Create(AKind: TRTCEventKind; const AQSOID, AXmlBody: AnsiString);
  end;

  THamScoreUploader = class(TThread)
  private
    FQueueLock:    TCriticalSection;
    FPending:      TList;            // FIFO of TRTCContact owned by the uploader
    FStopEvent:    TEvent;
    FCycleEvent:   TEvent;           // signaled by PushNow to wake the worker early
    FURL:          string;
    FUsername:     string;
    FPassword:     string;
    FCycleMs:      Integer;          // 120000 in production; injectable for tests
    FLogger:       TLogLogger;

    // Status snapshot for the Phase 4 UI window.  Updated from the worker
    // thread inside DoCycle; read by the dialog from the main thread.  All
    // reads/writes go through FQueueLock so we never tear a multi-byte field.
    FLastCycleTime:   TDateTime;     // time the most recent cycle completed
    FLastCycleStatus: string;        // human-readable last-cycle outcome

    function  TakePendingSnapshot: TList;     // moves FPending to a local list, replaces with new empty list
    procedure RestorePending(snapshot: TList); // puts un-CFMed contacts back at the head of FPending
    function  BuildPayload(snapshot: TList; out hadQSOs: Boolean): AnsiString;
    function  PostToServer(const xml: AnsiString; out responseBody: string): Integer;  // returns HTTP status
    function  ResponseStatusKind(const responseBody: string): string;  // 'CFM' | 'OK' | 'Error' | 'ResyncLog' | ''
    procedure DoCycle;
    procedure FreeContactList(list: TList);
    procedure SetCycleStatus(const status: string);
  protected
    procedure Execute; override;
  public
    constructor Create(const AURL, AUsername, APassword: string);
    destructor  Destroy; override;
    procedure   Enqueue(contact: TRTCContact);   // takes ownership
    procedure   RequestStop;
    procedure   PushNow;                         // wake the worker for an immediate cycle

    // Read-only status accessors for the Phase 4 dialog (thread-safe snapshot).
    function    GetPendingCount: Integer;
    function    GetLastCycleStatus: string;
    function    GetLastCycleTime: TDateTime;

    property    URL:      string  read FURL;
    property    Username: string  read FUsername;
    property    CycleMs:  Integer read FCycleMs write FCycleMs;
  end;

// ---------------------------------------------------------------------------
// Module-level configuration (parsed by uCFG via CFGCA entries)
// ---------------------------------------------------------------------------

var
  HamScoreEnable:   Boolean = False;
  HamScoreURL:      ShortString = 'https://hamscore.com/postxml/index.php';
  HamScoreUsername: ShortString = '';   // empty -> falls back to MyCall
  HamScorePassword: ShortString = '';

// ---------------------------------------------------------------------------
// Lifecycle (called from tr4w.dpr / shutdown path)
// ---------------------------------------------------------------------------

procedure HamScoreInit;       // No-op if HamScoreEnable is False or password missing
procedure HamScoreShutdown;   // Safe to call even if Init didn't start the worker

// ---------------------------------------------------------------------------
// QSO event hooks (cheap no-ops when uploader is not running)
// ---------------------------------------------------------------------------

procedure HamScoreOnLog(const RXData: ContestExchange);
procedure HamScoreOnEdit(const RXData: ContestExchange);
procedure HamScoreOnDelete(const RXData: ContestExchange);

// Tools-menu entry point (Phase 3): wipe the server-side log and re-send
// every QSO from the current binary log file.
procedure HamScoreResyncFromScratch;

// Phase 4 -- HamScore status window dialog procedure.  Wired into
// tr4w_WindowsArray[tw_HAMSCOREWINDOW_INDEX].WndProcAdr by MainUnit.
function HamScoreDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation

uses
  StrUtils, IdAuthentication, Messages,
  LogWind,           // MyCall global
  ZoneCont,          // GetContinentName, ContinentType
  TF,                // CreateButton, CreateStatic
  MainUnit,          // CloseTR4WWindow, DefTR4WProc, FrmSetFocus (impl/impl cycle is OK)
  uGetScores;        // BuildDynamicResultsXml (added by this PR)

const
  DEFAULT_CYCLE_MS = 120000;   // 2 minutes per RTC spec section 1.2

var
  Uploader: THamScoreUploader = nil;
  ModuleLogger: TLogLogger = nil;

function GetModuleLogger: TLogLogger;
begin
  if ModuleLogger = nil then
    ModuleLogger := TLogLogger.GetLogger('TR4WDebugLog.HamScore');
  Result := ModuleLogger;
end;

// ===========================================================================
// XML helpers -- escape and field rendering
// ===========================================================================

function XmlEscape(const s: AnsiString): AnsiString;
var
  i: Integer;
  c: AnsiChar;
begin
  // RTC fields are short identifiers (callsigns, exchanges, mode names).
  // Operator typo could still introduce <, >, &, " or ' -- escape defensively
  // so we don't break the server's XML parser.
  Result := '';
  for i := 1 to Length(s) do
  begin
    c := s[i];
    case c of
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '&': Result := Result + '&amp;';
      '"': Result := Result + '&quot;';
      '''': Result := Result + '&apos;';
    else
      Result := Result + c;
    end;
  end;
end;

// Map a QSO mode to the RTC <mode> string.  Spec examples list:
//   CW, PH, RTTY, PSK, FT8, FT4
// We prefer ExtMode when available for digital-mode specificity.
function MapModeForRTC(const RXData: ContestExchange): AnsiString;
begin
  if RXData.ExtMode <> eNoMode then
    case RXData.ExtMode of
      eCW, eCW_R:               Result := 'CW';
      eRTTY, eRTTY_R:           Result := 'RTTY';
      eFT8:                     Result := 'FT8';
      eFT4:                     Result := 'FT4';
      eJT65:                    Result := 'JT65';
      ePSK31, ePSK63, ePSK_R:   Result := 'PSK';
      eMFSK, eJS8:              Result := 'DATA';
      eSSB, eUSB, eLSB:         Result := 'PH';
      eFM, eFM_N, eData_FM:     Result := 'FM';
      eAM, eAM_N:               Result := 'AM';
      eC4FM:                    Result := 'C4FM';
      eDStar:                   Result := 'DSTAR';
    else
      Result := 'CW';
    end
  else
    case RXData.Mode of
      CW:      Result := 'CW';
      Phone:   Result := 'PH';
      Digital: Result := 'RTTY';   // generic digital fallback
      FM:      Result := 'FM';
    else
      Result := 'CW';
    end;
end;

// Map BandType to the MHz integer string the spec lists:
// 1.8, 3.5, 7, 14, 21, 28, 50, 144 (also 10/18/24/...)
function MapBandForRTC(band: BandType): AnsiString;
begin
  case band of
    Band160: Result := '1.8';
    Band80:  Result := '3.5';
    Band40:  Result := '7';
    Band30:  Result := '10';
    Band20:  Result := '14';
    Band17:  Result := '18';
    Band15:  Result := '21';
    Band12:  Result := '24';
    Band10:  Result := '28';
    Band6:   Result := '50';
    Band2:   Result := '144';
  else
    Result := '0';   // unknown / general coverage; server will likely reject
  end;
end;

function CountMultipliers(const RXData: ContestExchange): Integer;
begin
  Result := 0;
  if RXData.DXMult       then Inc(Result);
  if RXData.DomesticMult then Inc(Result);
  if RXData.PrefixMult   then Inc(Result);
  if RXData.ZoneMult     then Inc(Result);
end;

function FormatTimestamp(const tSysTime: TQSOTime): AnsiString;
begin
  // ISO-style YYYY-MM-DD HH:MM:SS in UTC, matching the BuildUDPContact format.
  Result := AnsiString(Format('20%.2d-%.2d-%.2d %.2d:%.2d:%.2d',
    [tSysTime.qtYear, tSysTime.qtMonth, tSysTime.qtDay,
     tSysTime.qtHour, tSysTime.qtMinute, tSysTime.qtSecond]));
end;

// Render a <contactinfo> or <contactreplace> body for one QSO.
// Used by HamScoreOnLog / HamScoreOnEdit on the main thread; the result
// goes into TRTCContact.XmlBody and is held until CFM by the worker.
function RenderContactBody(AKind: TRTCEventKind; const RXData: ContestExchange): AnsiString;
var
  tag:        AnsiString;
  multCount:  Integer;
  multBits:   array[1..3] of Integer;
  i:          Integer;
  freq:       Integer;
  txFreq:     Integer;
begin
  case AKind of
    rckInfo:    tag := 'contactinfo';
    rckReplace: tag := 'contactreplace';
  else
    Result := '';   // delete / deletelog use other renderers
    Exit;
  end;

  // Frequency: RXData.Frequency is Hz; spec wants 10-Hz units.
  freq   := RXData.Frequency div 10;
  txFreq := freq;   // TR4W's UDP path checks split state via ActiveRadioPtr;
                    // we deliberately use the QSO's recorded frequency for both
                    // sides because the QSO record is what's authoritative AFTER
                    // the contact, regardless of split state at moment of post.

  // Multiplier flags 1..N: TR4W tracks 4 mult dimensions (DX, Domestic,
  // Prefix, Zone); RTC has slots for up to 3.  Map by rank:
  // first claimed -> slot 1, second -> slot 2, third -> slot 3.
  multCount := CountMultipliers(RXData);
  for i := 1 to 3 do
    if i <= multCount then multBits[i] := 1 else multBits[i] := 0;

  Result :=
    '<' + tag + '>' + sLineBreak +
    #9 + '<ID>' + AnsiString(RXData.id) + '</ID>' + sLineBreak +
    #9 + '<timestamp>' + FormatTimestamp(RXData.tSysTime) + '</timestamp>' + sLineBreak +
    #9 + '<band>' + MapBandForRTC(RXData.Band) + '</band>' + sLineBreak +
    #9 + '<rxfreq>' + AnsiString(IntToStr(freq))   + '</rxfreq>' + sLineBreak +
    #9 + '<txfreq>' + AnsiString(IntToStr(txFreq)) + '</txfreq>' + sLineBreak +
    #9 + '<mode>' + MapModeForRTC(RXData) + '</mode>' + sLineBreak +
    #9 + '<call>' + XmlEscape(AnsiString(RXData.Callsign)) + '</call>' + sLineBreak +
    #9 + '<SentExchange>' + XmlEscape(Trim(AnsiString(RXData.ExchString))) + '</SentExchange>' + sLineBreak +
    #9 + '<RxExchange>'   + XmlEscape(Trim(AnsiString(RXData.ExchString))) + '</RxExchange>' + sLineBreak +
    // RxExchange: TR4W does not store the received exchange string verbatim
    // separate from the parsed fields; ExchString reflects what was typed.
    // Spec tolerates a single exchange string; refine later if needed.
    #9 + '<countryprefix>' + XmlEscape(AnsiString(RXData.QTH.CountryID)) + '</countryprefix>' + sLineBreak +
    #9 + '<wpxprefix>'     + XmlEscape(AnsiString(RXData.QTH.Prefix))    + '</wpxprefix>' + sLineBreak +
    #9 + '<continent>' + AnsiString(GetContinentName(RXData.QTH.Continent)) + '</continent>' + sLineBreak +
    #9 + '<zone>' + AnsiString(IntToStr(RXData.Zone)) + '</zone>' + sLineBreak +
    #9 + '<ismultiplier1>' + AnsiString(IntToStr(multBits[1])) + '</ismultiplier1>' + sLineBreak +
    #9 + '<ismultiplier2>' + AnsiString(IntToStr(multBits[2])) + '</ismultiplier2>' + sLineBreak +
    #9 + '<ismultiplier3>' + AnsiString(IntToStr(multBits[3])) + '</ismultiplier3>' + sLineBreak +
    #9 + '<x-qso>' + AnsiString(IntToStr(Ord(RXData.ceXQSO))) + '</x-qso>' + sLineBreak +
    #9 + '<points>'  + AnsiString(IntToStr(RXData.QSOPoints))   + '</points>' + sLineBreak +
    #9 + '<radionr>' + AnsiString(IntToStr(Ord(RXData.ceRadio))) + '</radionr>' + sLineBreak +
    #9 + '<IsRunQSO>' + AnsiString(IntToStr(Ord(not RXData.ceSearchAndPounce))) + '</IsRunQSO>' + sLineBreak +
    '</' + tag + '>' + sLineBreak;
end;

function RenderDeleteBody(const QSOID: AnsiString): AnsiString;
begin
  Result :=
    '<contactdelete>' + sLineBreak +
    #9 + '<ID>' + QSOID + '</ID>' + sLineBreak +
    '</contactdelete>' + sLineBreak;
end;

function RenderDeleteLogBody: AnsiString;
begin
  // Spec section 1.7: empty container is acceptable.
  Result := '<deletelog></deletelog>' + sLineBreak;
end;

// ===========================================================================
// TRTCContact
// ===========================================================================

constructor TRTCContact.Create(AKind: TRTCEventKind; const AQSOID, AXmlBody: AnsiString);
begin
  inherited Create;
  Kind    := AKind;
  QSOID   := AQSOID;
  XmlBody := AXmlBody;
end;

// ===========================================================================
// THamScoreUploader
// ===========================================================================

constructor THamScoreUploader.Create(const AURL, AUsername, APassword: string);
begin
  // Create suspended; caller must Start() us once configured.
  inherited Create(True);
  FreeOnTerminate := False;

  FURL        := AURL;
  FUsername   := AUsername;
  FPassword   := APassword;
  FCycleMs    := DEFAULT_CYCLE_MS;
  FQueueLock  := TCriticalSection.Create;
  FPending    := TList.Create;
  FStopEvent  := TEvent.Create(nil, True, False, '');     // manual reset
  FCycleEvent := TEvent.Create(nil, False, False, '');    // auto reset (unused for now)
  FLogger     := TLogLogger.GetLogger('TR4WDebugLog.HamScore.Uploader');
  FLastCycleStatus := 'Not yet run';
  FLastCycleTime   := 0;
  FLogger.Info('[HamScore] Created uploader: URL=%s user=%s cycle=%dms',
    [FURL, FUsername, FCycleMs]);
end;

destructor THamScoreUploader.Destroy;
begin
  FreeContactList(FPending);
  FPending.Free;
  FStopEvent.Free;
  FCycleEvent.Free;
  FQueueLock.Free;
  inherited;
end;

procedure THamScoreUploader.FreeContactList(list: TList);
var i: Integer;
begin
  if list = nil then Exit;
  for i := 0 to list.Count - 1 do
    if list[i] <> nil then TRTCContact(list[i]).Free;
  list.Clear;
end;

procedure THamScoreUploader.RequestStop;
begin
  FStopEvent.SetEvent;
end;

procedure THamScoreUploader.PushNow;
begin
  // Manual push from the Phase 4 UI: signal the worker to wake before the
  // 2-minute timer expires.  Auto-reset event so the next post-then-sleep
  // cycle returns to its normal cadence.
  if FCycleEvent <> nil then
    FCycleEvent.SetEvent;
end;

procedure THamScoreUploader.SetCycleStatus(const status: string);
begin
  FQueueLock.Acquire;
  try
    FLastCycleStatus := status;
    FLastCycleTime   := Now;
  finally
    FQueueLock.Release;
  end;
end;

function THamScoreUploader.GetPendingCount: Integer;
begin
  FQueueLock.Acquire;
  try
    Result := FPending.Count;
  finally
    FQueueLock.Release;
  end;
end;

function THamScoreUploader.GetLastCycleStatus: string;
begin
  FQueueLock.Acquire;
  try
    Result := FLastCycleStatus;
  finally
    FQueueLock.Release;
  end;
end;

function THamScoreUploader.GetLastCycleTime: TDateTime;
begin
  FQueueLock.Acquire;
  try
    Result := FLastCycleTime;
  finally
    FQueueLock.Release;
  end;
end;

procedure THamScoreUploader.Enqueue(contact: TRTCContact);
begin
  if contact = nil then Exit;
  FQueueLock.Acquire;
  try
    FPending.Add(contact);
  finally
    FQueueLock.Release;
  end;
end;

// Move all current pending entries to a fresh list and reset FPending.
// Caller owns the returned list; new items enqueued during the cycle land
// in the new FPending and survive a CFM clearing of the in-flight batch.
function THamScoreUploader.TakePendingSnapshot: TList;
var i: Integer;
begin
  Result := TList.Create;
  FQueueLock.Acquire;
  try
    for i := 0 to FPending.Count - 1 do
      Result.Add(FPending[i]);
    FPending.Clear;
  finally
    FQueueLock.Release;
  end;
end;

// Put un-CFMed contacts back at the HEAD of FPending so they go out next
// cycle alongside any QSOs enqueued in the meantime.
procedure THamScoreUploader.RestorePending(snapshot: TList);
var
  i: Integer;
  combined: TList;
begin
  if (snapshot = nil) or (snapshot.Count = 0) then
  begin
    snapshot.Free;
    Exit;
  end;

  FQueueLock.Acquire;
  try
    combined := TList.Create;
    try
      for i := 0 to snapshot.Count - 1 do combined.Add(snapshot[i]);
      for i := 0 to FPending.Count - 1 do combined.Add(FPending[i]);
      FPending.Clear;
      for i := 0 to combined.Count - 1 do FPending.Add(combined[i]);
    finally
      combined.Free;
    end;
  finally
    FQueueLock.Release;
  end;
  snapshot.Free;
end;

function THamScoreUploader.BuildPayload(snapshot: TList; out hadQSOs: Boolean): AnsiString;
var
  i:           Integer;
  contact:     TRTCContact;
  dynResults:  AnsiString;
begin
  hadQSOs := (snapshot <> nil) and (snapshot.Count > 0);

  // Build the dynamicresults fragment fresh every cycle (snapshot of current
  // score totals).  Falls back to a minimal shell if uGetScores can't be
  // called -- we still want the post to be valid XML.
  try
    dynResults := uGetScores.BuildDynamicResultsXml;
  except
    on E: Exception do
    begin
      FLogger.Warn('[HamScore] dynamicresults build failed: %s -- sending shell',
        [E.Message]);
      dynResults := '<dynamicresults></dynamicresults>';
    end;
  end;

  Result := '<?xml version="1.0"?>' + sLineBreak + dynResults + sLineBreak;

  if snapshot <> nil then
    for i := 0 to snapshot.Count - 1 do
    begin
      contact := TRTCContact(snapshot[i]);
      if contact <> nil then
        Result := Result + contact.XmlBody;
    end;
end;

function THamScoreUploader.PostToServer(const xml: AnsiString; out responseBody: string): Integer;
var
  http: TIdHTTP;
  ssl:  TIdSSLIOHandlerSocketOpenSSL;
  body: TStringStream;
  resp: TStringStream;
  effectiveUser: string;
begin
  Result := 0;
  responseBody := '';

  // Username defaults to MyCall when the operator left HAMSCORE USERNAME blank.
  if FUsername <> '' then
    effectiveUser := FUsername
  else
    effectiveUser := string(MyCall);

  http := TIdHTTP.Create(nil);
  ssl  := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  body := TStringStream.Create(string(xml));
  resp := TStringStream.Create('');
  try
    if AnsiStartsText('https://', FURL) then
      begin
      ssl.SSLOptions.Method := sslvTLSv1_2;
      http.IOHandler := ssl;
      end;

    http.HandleRedirects        := True;
    http.Request.UserAgent      := 'TR4W RTC ' + string(TR4W_CURRENTVERSION_NUMBER);
    http.Request.ContentType    := 'application/xml';
    http.Request.BasicAuthentication := True;
    http.Request.Username       := effectiveUser;
    http.Request.Password       := FPassword;
    http.Request.AcceptEncoding := 'gzip,deflate';
    http.ConnectTimeout         := 15000;
    http.ReadTimeout            := 30000;

    try
      http.Post(FURL, body, resp);
      Result := http.ResponseCode;
      responseBody := resp.DataString;
      FLogger.Debug('[HamScore] POST %s -> %d, body=%s',
        [FURL, Result, responseBody]);
    except
      on E: Exception do
      begin
        FLogger.Warn('[HamScore] POST %s failed: %s', [FURL, E.Message]);
        Result := 0;
      end;
    end;
  finally
    body.Free;
    resp.Free;
    http.Free;
    ssl.Free;
  end;
end;

// Parse the simple JSON status line.  We don't need a real JSON parser;
// the server's responses are always single-line objects with quoted strings.
function THamScoreUploader.ResponseStatusKind(const responseBody: string): string;
begin
  if Pos('"Status":"CFM"',       responseBody) > 0 then Result := 'CFM'
  else if Pos('"Status":"OK"',         responseBody) > 0 then Result := 'OK'
  else if Pos('"Status":"ResyncLog"',  responseBody) > 0 then Result := 'ResyncLog'
  else if Pos('"Status":"Error"',      responseBody) > 0 then Result := 'Error'
  else Result := '';
end;

procedure THamScoreUploader.DoCycle;
var
  snapshot:     TList;
  payload:      AnsiString;
  responseBody: string;
  httpCode:     Integer;
  status:       string;
  hadQSOs:      Boolean;
begin
  snapshot := TakePendingSnapshot;
  try
    payload := BuildPayload(snapshot, hadQSOs);
    httpCode := PostToServer(payload, responseBody);

    if httpCode = 0 then
    begin
      // Network error -- keep snapshot for next cycle.
      FLogger.Info('[HamScore] Cycle: network error, %d QSO(s) retained for retry',
        [snapshot.Count]);
      SetCycleStatus(Format('Network error -- %d QSO(s) retained', [snapshot.Count]));
      RestorePending(snapshot);
      snapshot := nil;   // ownership transferred
      Exit;
    end;

    if (httpCode < 200) or (httpCode >= 300) then
    begin
      FLogger.Warn('[HamScore] Cycle: HTTP %d, %d QSO(s) retained',
        [httpCode, snapshot.Count]);
      SetCycleStatus(Format('HTTP %d -- %d QSO(s) retained', [httpCode, snapshot.Count]));
      RestorePending(snapshot);
      snapshot := nil;
      Exit;
    end;

    status := ResponseStatusKind(responseBody);
    if (status = 'CFM') or ((status = 'OK') and not hadQSOs) then
    begin
      FLogger.Info('[HamScore] Cycle CFM (%d QSO(s) confirmed)', [snapshot.Count]);
      if status = 'CFM' then
        SetCycleStatus(Format('CFM -- %d QSO(s) confirmed', [snapshot.Count]))
      else
        SetCycleStatus('OK -- score-only post accepted');
      // snapshot will be freed in finally -- contacts are released
      Exit;
    end;

    if status = 'ResyncLog' then
    begin
      // Future: trigger a full resync flow.  For now, log and retain so a
      // manual Tools-menu resync remains the operator's escape hatch.
      FLogger.Warn('[HamScore] Server requested ResyncLog -- retaining queue, ' +
        'use Tools menu HamScore Resync to comply');
      SetCycleStatus('ResyncLog requested -- use Tools menu Resync');
      RestorePending(snapshot);
      snapshot := nil;
      Exit;
    end;

    if status = 'Error' then
    begin
      FLogger.Error('[HamScore] Server error: %s -- retaining %d QSO(s)',
        [responseBody, snapshot.Count]);
      SetCycleStatus('Server error: ' + responseBody);
      RestorePending(snapshot);
      snapshot := nil;
      Exit;
    end;

    // No recognised status (server might be down/proxied).  Keep retrying.
    FLogger.Warn('[HamScore] Unexpected response, retaining %d QSO(s): %s',
      [snapshot.Count, responseBody]);
    SetCycleStatus(Format('Unexpected response -- %d QSO(s) retained', [snapshot.Count]));
    RestorePending(snapshot);
    snapshot := nil;
  finally
    if snapshot <> nil then
    begin
      FreeContactList(snapshot);
      snapshot.Free;
    end;
  end;
end;

procedure THamScoreUploader.Execute;
var
  handles:   array[0..1] of THandle;
  waitRet:   DWORD;
begin
  FLogger.Info('[HamScore] Worker thread started');
  // Wait on TWO events: stop (priority) and cycle-now (push button).
  // WaitForMultipleObjects returns WAIT_OBJECT_0+i for the signaled handle,
  // WAIT_TIMEOUT after FCycleMs ms, or WAIT_FAILED on error.  WaitAll = False
  // means "any of these wakes us".
  handles[0] := FStopEvent.Handle;
  handles[1] := FCycleEvent.Handle;
  try
    while not Terminated do
    begin
      waitRet := WaitForMultipleObjects(2, @handles, False, Cardinal(FCycleMs));
      if Terminated then Break;
      if waitRet = WAIT_OBJECT_0 then Break;     // FStopEvent
      // Either FCycleEvent fired (waitRet = WAIT_OBJECT_0+1) or the 2-minute
      // timer expired (WAIT_TIMEOUT).  Both run a cycle.
      try
        DoCycle;
      except
        on E: Exception do
        begin
          FLogger.Error('[HamScore] DoCycle exception: %s', [E.Message]);
          SetCycleStatus('Exception: ' + E.Message);
        end;
      end;
    end;
  finally
    FLogger.Info('[HamScore] Worker thread exiting');
  end;
end;

// ===========================================================================
// Module entry points
// ===========================================================================

procedure HamScoreInit;
begin
  if Uploader <> nil then Exit;   // already running
  if not HamScoreEnable then Exit;

  if HamScorePassword = '' then
  begin
    GetModuleLogger.Warn('[HamScore] HAMSCORE ENABLE = TRUE but HAMSCORE PASSWORD is empty -- uploader not started');
    Exit;
  end;

  if HamScoreURL = '' then
    HamScoreURL := 'https://hamscore.com/postxml/index.php';

  Uploader := THamScoreUploader.Create(
    string(HamScoreURL),
    string(HamScoreUsername),
    string(HamScorePassword));
  Uploader.Resume;   // Delphi 7 TThread; later Delphis renamed to Start.
  GetModuleLogger.Info('[HamScore] Started');
end;

procedure HamScoreShutdown;
begin
  if Uploader = nil then Exit;
  GetModuleLogger.Info('[HamScore] Shutdown requested');
  Uploader.RequestStop;
  Uploader.WaitFor;
  FreeAndNil(Uploader);
end;

procedure HamScoreOnLog(const RXData: ContestExchange);
var body: AnsiString;
begin
  if Uploader = nil then Exit;
  body := RenderContactBody(rckInfo, RXData);
  if body = '' then Exit;
  Uploader.Enqueue(TRTCContact.Create(rckInfo, AnsiString(RXData.id), body));
end;

procedure HamScoreOnEdit(const RXData: ContestExchange);
var body: AnsiString;
begin
  if Uploader = nil then Exit;
  body := RenderContactBody(rckReplace, RXData);
  if body = '' then Exit;
  Uploader.Enqueue(TRTCContact.Create(rckReplace, AnsiString(RXData.id), body));
end;

procedure HamScoreOnDelete(const RXData: ContestExchange);
var body: AnsiString;
begin
  if Uploader = nil then Exit;
  body := RenderDeleteBody(AnsiString(RXData.id));
  Uploader.Enqueue(TRTCContact.Create(rckDelete, AnsiString(RXData.id), body));
end;

procedure HamScoreResyncFromScratch;
begin
  // Phase 3 -- enqueue the <deletelog> separator.  The full-log walk that
  // re-uploads every QSO lives in LOGSUBS2.SendFullLogToHamScore, which is
  // called by the Tools-menu handler in MainUnit immediately after this.
  if Uploader = nil then Exit;
  Uploader.Enqueue(TRTCContact.Create(rckDeleteLog, '', RenderDeleteLogBody));
end;

// ===========================================================================
// Phase 4 -- HamScore status dialog
// ===========================================================================

const
  HAMSCORE_TIMER_ID         = 1;
  HAMSCORE_REFRESH_MS       = 1000;   // refresh queued count + status every 1s
  HAMSCORE_BTN_PUSH_NOW     = 101;
  HAMSCORE_BTN_RESYNC       = 102;
  HAMSCORE_LBL_URL          = 110;
  HAMSCORE_LBL_USERNAME     = 111;
  HAMSCORE_LBL_QUEUE_TITLE  = 112;
  HAMSCORE_LBL_QUEUE_VAL    = 113;
  HAMSCORE_LBL_STATUS_TITLE = 114;
  HAMSCORE_LBL_STATUS_VAL   = 115;
  HAMSCORE_LBL_LASTRUN_VAL  = 116;

procedure SetTextSafe(hwnddlg: HWND; ctrlId: Integer; const s: string);
begin
  Windows.SetDlgItemText(hwnddlg, ctrlId, PChar(s));
end;

procedure HamScoreRefreshStatus(hwnddlg: HWND);
var
  pendCount: Integer;
  status:    string;
  lastTime:  TDateTime;
  url:       string;
  user:      string;
begin
  if Uploader = nil then
    begin
    SetTextSafe(hwnddlg, HAMSCORE_LBL_URL,         'URL: (uploader not running -- HAMSCORE ENABLE = FALSE or password missing)');
    SetTextSafe(hwnddlg, HAMSCORE_LBL_USERNAME,    'User: --');
    SetTextSafe(hwnddlg, HAMSCORE_LBL_QUEUE_VAL,   '--');
    SetTextSafe(hwnddlg, HAMSCORE_LBL_STATUS_VAL,  'Disabled');
    SetTextSafe(hwnddlg, HAMSCORE_LBL_LASTRUN_VAL, '');
    Exit;
    end;

  pendCount := Uploader.GetPendingCount;
  status    := Uploader.GetLastCycleStatus;
  lastTime  := Uploader.GetLastCycleTime;
  url       := Uploader.URL;
  user      := Uploader.Username;
  if user = '' then
    user := string(MyCall) + ' (default; HAMSCORE USERNAME empty)';

  SetTextSafe(hwnddlg, HAMSCORE_LBL_URL,         'URL: ' + url);
  SetTextSafe(hwnddlg, HAMSCORE_LBL_USERNAME,    'User: ' + user);
  SetTextSafe(hwnddlg, HAMSCORE_LBL_QUEUE_VAL,   IntToStr(pendCount));
  SetTextSafe(hwnddlg, HAMSCORE_LBL_STATUS_VAL,  status);
  if lastTime = 0 then
    SetTextSafe(hwnddlg, HAMSCORE_LBL_LASTRUN_VAL, 'Last cycle: never')
  else
    SetTextSafe(hwnddlg, HAMSCORE_LBL_LASTRUN_VAL,
      'Last cycle: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', lastTime));
end;

function HamScoreDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  Done;
begin
  Result := False;
  case Msg of
    WM_LBUTTONDOWN, WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE:
      DefTR4WProc(Msg, lParam, hwnddlg);

    WM_INITDIALOG:
      begin
        // Layout (single column).  Y in pixels.
        CreateStatic(nil, 5,   5, 360, hwnddlg, HAMSCORE_LBL_URL);
        CreateStatic(nil, 5,  25, 360, hwnddlg, HAMSCORE_LBL_USERNAME);

        CreateStatic('Queued contacts:', 5, 55, 130, hwnddlg, HAMSCORE_LBL_QUEUE_TITLE);
        CreateStatic('--',               140, 55, 60, hwnddlg, HAMSCORE_LBL_QUEUE_VAL);

        CreateStatic('Last status:',     5, 75, 130, hwnddlg, HAMSCORE_LBL_STATUS_TITLE);
        CreateStatic('--',               140, 75, 220, hwnddlg, HAMSCORE_LBL_STATUS_VAL);
        CreateStatic('',                 5, 95, 360, hwnddlg, HAMSCORE_LBL_LASTRUN_VAL);

        CreateButton(0, 'Push Now',       5, 125, 100, hwnddlg, HAMSCORE_BTN_PUSH_NOW);
        CreateButton(0, 'Resync from log', 110, 125, 130, hwnddlg, HAMSCORE_BTN_RESYNC);

        SetTimer(hwnddlg, HAMSCORE_TIMER_ID, HAMSCORE_REFRESH_MS, nil);
        HamScoreRefreshStatus(hwnddlg);
      end;

    WM_TIMER:
      HamScoreRefreshStatus(hwnddlg);

    WM_COMMAND:
      begin
        case wParam of
          HAMSCORE_BTN_PUSH_NOW:
            begin
              if Uploader <> nil then
                begin
                Uploader.PushNow;
                SetTextSafe(hwnddlg, HAMSCORE_LBL_STATUS_VAL, 'Push Now signaled -- cycle will run shortly');
                end;
            end;

          HAMSCORE_BTN_RESYNC:
            begin
              // Tools-menu equivalent inline; calls into the same helpers.
              // (We cannot pull SendFullLogToHamScore from here without a
              // circular reference, so the resync button only enqueues the
              // <deletelog>; user should also use Tools menu Resync to
              // walk the full log.  Documented in the help dialog later.)
              HamScoreResyncFromScratch;
              SetTextSafe(hwnddlg, HAMSCORE_LBL_STATUS_VAL,
                '<deletelog> queued -- use Tools menu Resync to enqueue all QSOs');
            end;
        end;
        if HiWord(wParam) = BN_CLICKED then FrmSetFocus;
      end;

    WM_CLOSE:
      begin
        Done:
        KillTimer(hwnddlg, HAMSCORE_TIMER_ID);
        CloseTR4WWindow(tw_HAMSCOREWINDOW_INDEX);
      end;
  end;
end;

end.
