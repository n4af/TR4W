unit uGetScores;
{$IMPORTEDDATA OFF}
interface

uses

  TF,
  VC,
//  ShellAPI,
  uMults,
  LogEdit,
  PostUnit,
  Windows,
  Messages,
  LogStuff,
  LogDupe,
  LogWind,
  utils_net,
  utils_file,
  WinSock2,
  Tree
  ;
type

  TUrlGetPart = function(pszIn: PChar; pszOut: PChar; pcchOut: LPDWORD; dwPart, dwFlags: DWORD): HRESULT; stdcall;

function GetScoresDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure CreateConnectionAndSendReportToGetScores;
procedure RunPOSTGetScoresThread;
//function MakePOSTRequest: integer;
//function MakePOSTRequestForRDXC2010: integer;
function MakePOSTRequestNew: integer;
procedure ShowGetScoresStatus(Status: PChar);
procedure CheckServerAnswer(AnswerLength: integer);
//procedure SendOnLineResultsToRDXC2010Site;

var
  GetScoresPostingID                    : integer;
  GetScoresSeverPostingAddress          : ShortString {= 'http://www.getscores.org/postscore.aspx'};
  GetScoresSeverReadingAddress          : ShortString {= 'http://www.getscores.org/'};
  GetScoresHost                         : array[0..31] of Char;
  GetScoresQuery                        : array[0..127] of Char;
  GetScoresPortAsString                 : array[0..7] of Char;
  GetScoresPort                         : Cardinal;

  GetScoresSocket                       : Cardinal;
  GetScoresBuffer                       : array[0..4096 - 1] of Char;
  GetScoresThreadID                     : Cardinal;
  GetScoresThreadHandle                 : Cardinal;
  GetScoresAnswerFileName               : array[0..255] of Char;
const

  GSCR                                  = ''; //#13#10;
//  GetScoresIP                           = 'www.getscores.org'; //'66.203.151.196';
  PostMethodRequestHeader               =
    'POST /%s HTTP/1.1'#13#10 +
    'Content-Type: application/x-www-form-urlencoded'#13#10 +
//    'User-Agent: ' + TR4W_CURRENTVERSION + #13#10 +
  'Content-Length: %u'#13#10 +
    'Host: %s'#13#10 +
    'Connection: close'#13#10#13#10;
{
  XML                                   =
    'xml=<?xml version="1.0"?><dynamicresults>' +
    GSCR + '<contest>%s</contest>' +
    GSCR + '<call>%s</call>' +
    GSCR + '<class ops="%s" mode="%s" power="%s" bands="%s"></class>' +
    GSCR + '<breakdown>' +
//    '%s' +
  '</breakdown>' +
    GSCR + '<score>%u</score>' +
    GSCR + '<timestamp>%s</timestamp>' + GSCR + '</dynamicresults>';
}
implementation
uses MainUnit;

function GetScoresDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
begin
  Result := False;
  case Msg of
    WM_LBUTTONDOWN, WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);
    WM_INITDIALOG:
      begin

        CreateButton(0, RC_POSTNOW, 5, 35, 200, hwnddlg, 101);
        CreateButton(0, RC_GOTOGS, 5, 35 + 30, 200, hwnddlg, 106);
        CreateStatic(nil, 5, 5, 200, hwnddlg, 105);

        SetTimer(hwnddlg, 1, 1000 * 60 * 5 {minutes}, nil);
        Format(GetScoresAnswerFileName, '%sscoresserveranswer.html', TR4W_LOG_PATH_NAME);

//        windows.SetWindowText(hwnddlg,'asdasd')

      end;
    WM_TIMER: RunPOSTGetScoresThread;

    WM_COMMAND:
      begin
        if wParam = 101 then RunPOSTGetScoresThread;
        if wParam = 106 then OpenUrl(@GetScoresSeverReadingAddress[1]);

{$IF LANG = 'RUS'}
//        if wParam = 104 then ShowHelp('ru_getscores');
{$IFEND}

        if HiWord(wParam) = BN_CLICKED then FrmSetFocus;
      end;
    WM_CLOSE: 1:
      begin
        KillTimer(hwnddlg, 1);
        CloseTR4WWindow(tw_POSTSCORESWINDOW_INDEX);
      end;
  end;
end;

procedure RunPOSTGetScoresThread;
begin
  if GetScoresThreadID = 0 then
    GetScoresThreadHandle := tCreateThread(@CreateConnectionAndSendReportToGetScores, GetScoresThreadID);
//  CreateConnectionAndSendReportToGetScores;
end;

procedure CreateConnectionAndSendReportToGetScores;
var
  h                                     : HWND;
  c                                     : Cardinal;
  Module                                : HWND;
  UrlGetPart                            : TUrlGetPart;
  pcchOut                               : DWORD;
const
  URL_PART_NONE                         = 0;
  URL_PART_SCHEME                       = 1;
  URL_PART_HOSTNAME                     = 2;
  URL_PART_USERNAME                     = 3;
  URL_PART_PASSWORD                     = 4;
  URL_PART_PORT                         = 5;
  URL_PART_QUERY                        = 6;
label
  1;
begin
  ShowGetScoresStatus(TC_CONNECT);

  Module := LoadLibrary('shlwapi.dll');
  @UrlGetPart := GetProcAddress(Module, 'UrlGetPartA');
  pcchOut := SizeOf(GetScoresHost);
  if UrlGetPart(@GetScoresSeverPostingAddress[1], GetScoresHost, @pcchOut, URL_PART_HOSTNAME, 0) = ERROR_SUCCESS then
  begin
    pcchOut := SizeOf(GetScoresQuery);
    Windows.ZeroMemory(@GetScoresPortAsString, SizeOf(GetScoresPortAsString));
    UrlGetPart(@GetScoresSeverPostingAddress[1], GetScoresPortAsString, @pcchOut, URL_PART_PORT, 0);
    GetScoresPort := PCharToInt(GetScoresPortAsString);
    if GetScoresPort = 0 then GetScoresPort := 80;

    Windows.ZeroMemory(@GetScoresQuery, SizeOf(GetScoresQuery));
    for c := 8 to length(GetScoresSeverPostingAddress) - 1 do
      if GetScoresSeverPostingAddress[c] = '/' then
      begin
        Windows.CopyMemory(@GetScoresQuery, @GetScoresSeverPostingAddress[c + 1], length(GetScoresSeverPostingAddress) - c);
        Break;
      end;
  end;
  FreeLibrary(Module);

  if not GetConnection(GetScoresSocket, GetScoresHost, GetScoresPort, SOCK_STREAM) then
  begin
//    showmessage(SysErrorMessage(WSAGetLastError));
    ShowGetScoresStatus(TC_FAILEDTOCONNECTTOGETSCORESORG);
    goto 1;
  end;

{
  if strpos(@GetScoresSeverPostingAddress[1], 'http://rdxc.org/asp/pages/update.asp') <> nil then
    SendOnLineResultsToRDXC2010Site
  else
   }
//  MakePOSTRequest;

  WinSock2.Send(GetScoresSocket, GetScoresBuffer, MakePOSTRequestNew, 0);
  c := WinSock2.recv(GetScoresSocket, GetScoresBuffer, SizeOf(GetScoresBuffer), 0);
//  ShowMessage(GetScoresBuffer);

  if not tOpenFileForWrite(h, GetScoresAnswerFileName) then goto 1;
  sWriteFile(h, GetScoresBuffer, c);
  CloseHandle(h);

  CheckServerAnswer(c);
  1:
  closesocket(GetScoresSocket);

  GetScoresThreadID := 0;
  CloseHandle(GetScoresThreadHandle);
end;
{
function MakePOSTRequestForRDXC2010: integer;
var
  stored                                : integer;
  m                                     : RemainingMultiplierType;
  QSOs                                  : integer;
  DXm, DOMm                             : integer;
begin

  QSOs := QSOTotals[All, Both];
  DXm := mo.MTotals[All, Both, rmDX];
  DOMm := mo.MTotals[All, Both, rmDomestic];

  asm
  push GetScoresPostingID
  call TotalScore
  push eax
  push DOMm//reg
  push DXm//dxcc
  push TotalQSOPoints//pts
  push QSOs//qso
  call GetTimeString
  push eax
  end;

  stored := wsprintf(GetScoresXMLBuffer, 'TIME=%s&QSO=%u&PTS=%u&DXCC=%u&REG=%u&TOTAL=%u&NOTES=&ID=%u');

  asm
  add esp,36
  push offset GetScoresHost
  push stored
  push offset GetScoresQuery
  end;
  wsprintf(GetScoresBuffer, PostMethodRequestHeader);
  asm add esp,20
  end;

  Windows.lstrcat(GetScoresBuffer, GetScoresXMLBuffer);
  Result := Windows.lstrlen(GetScoresBuffer);

end;

function MakePOSTRequest: integer;
var
  pContest                              : PChar;
  pCall                                 : PChar;
  stored                                : integer;
  TempBand                              : BandType;
  TempMode                              : ModeType;
  m                                     : RemainingMultiplierType;
  BandPchar                             : PChar;
const
  GetScoresMults                        : array[RemainingMultiplierType] of PChar = (nil, 'state', 'country', 'zone', 'prefix');
  GetScoresModesArray                   : array[ModeType] of PChar = ('CW', 'DIG', 'PH', 'ALL', nil, nil);
begin

  pContest := ContestTypeSA[Contest];
  pCall := @MyCall[1];

  Windows.ZeroMemory(@GetScoresQsoByBandArray, SizeOf(GetScoresQsoByBandArray));

  for TempBand := Band160 to All do
    for TempMode := CW to Both do
    begin
      if QSOTotals[TempBand, TempMode] = 0 then Continue;

      BandPchar := BandStringsArrayWithOutSpaces[TempBand];
      if TempBand = All then
        BandPchar := 'total';

      Format(GetScoresXMLBuffer,
        GSCR + '<qso band="%s" mode="%s">%u</qso>',
        BandPchar,
        GetScoresModesArray[TempMode],
        QSOTotals[TempBand, TempMode]);

      Windows.lstrcat(GetScoresQsoByBandArray, GetScoresXMLBuffer);

    end;

  for TempBand := Band160 to All do
    for TempMode := CW to Both do
      for m := Succ(Low(RemainingMultiplierType)) to High(RemainingMultiplierType) do
      begin
        if mo.MTotals[TempBand, TempMode, m] = 0 then Continue;

        BandPchar := BandStringsArrayWithOutSpaces[TempBand];
        if TempBand = All then
          BandPchar := 'total';

        Format(GetScoresXMLBuffer,
          #13#10#9'<mult band="%s" mode="%s" type="%s">%u</mult>',
          BandPchar,
          GetScoresModesArray[TempMode],
          GetScoresMults[m],
          mo.MTotals[TempBand, TempMode, m]
          );
        Windows.lstrcat(GetScoresQsoByBandArray, GetScoresXMLBuffer);
      end;
  ShowMessage(GetScoresQsoByBandArray);
  tGetSystemTime;
  SystemTimeToString(UTC);

  asm
  push eax

  call TotalScore
  push eax

  lea eax, GetScoresQsoByBandArray
  push eax

//  call TotalContacts;
//  push eax

  xor  eax,eax
  mov  al,[CategoryBand]
  mov  eax,[eax*4+tCategoryBandSA]
  push eax

//  push pPower
  xor  eax,eax
  mov  al,[CategoryPower]
  mov  eax,[eax*4+tCategoryPowerSA]
  push eax
//  push pMode

  xor  eax,eax
  mov  al,[CategoryMode]
  mov  eax,[eax*4+tCategoryModeSA]
  push eax

//  push pOps

  xor  eax,eax
  mov  al,[CategoryOperator]
  mov  eax,[eax*4+tCategoryOperatorSA]
  push eax

  push pCall
  push pContest
  end;

  stored := wsprintf(GetScoresXMLBuffer, XML);

  asm
  add esp,40
  push offset GetScoresHost
  push stored
  push offset GetScoresQuery
  end;
  wsprintf(GetScoresBuffer, PostMethodRequestHeader);
  asm add esp,20
  end;

  Windows.lstrcat(GetScoresBuffer, GetScoresXMLBuffer);
  Result := Windows.lstrlen(GetScoresBuffer);

end;
}

procedure ShowGetScoresStatus(Status: PChar);
var
  tempbuffer                            : array[0..255] of Char;
begin
  Format(tempbuffer, '%s : %s', GetTimeString, Status);
  Windows.SetDlgItemText(tr4w_WindowsArray[tw_POSTSCORESWINDOW_INDEX].WndHandle, 105, tempbuffer);
end;

procedure CheckServerAnswer(AnswerLength: integer);
label
  1;
var
  i                                     : integer;
  TempInteger                           : integer;
  p                                     : PChar;
begin
  p := nil;
  if AnswerLength < 1 then
  begin
    p := TC_NOANSWERFROMSERVER;
    goto 1;
  end;

  for i := 0 to AnswerLength - 1 - 4 do
    if GetScoresBuffer[i] in [#13, #10] then
    begin
      GetScoresBuffer[i] := #0;
      p := @GetScoresBuffer[13];
      Break;
    end;

  for i := 0 to AnswerLength - 1 - 4 do
  begin
//    TempInteger := PInteger(@GetScoresBuffer[i])^;
//    if TempInteger = $462D4B4F then {OK-F} p := TC_UPLOADEDSUCCESSFULLY;
//    if TempInteger = $6176614A then {Java} p := TC_UPLOADEDSUCCESSFULLY;
//    if TempInteger = $4C494146 then {FAIL} p := TC_FAILEDTOLOAD;
  end;
  1:
  ShowGetScoresStatus(p);
end;
{
procedure SendOnLineResultsToRDXC2010Site;
begin
  WinSock2.Send(GetScoresSocket, GetScoresBuffer, MakePOSTRequestForRDXC2010, 0);
end;
}

function MakePOSTRequestNew: integer;
var
  TempBand                              : BandType;
  TempMode                              : ModeType;
  m                                     : RemainingMultiplierType;
  BandPchar                             : PChar;
  RequestBody                           : array[0..10000] of Char;
  Index                                 : integer;
//  h                                     : HWND;
const
  GetScoresMults                        : array[RemainingMultiplierType] of PChar = (nil, 'state', 'country', 'zone', 'prefix');
  GetScoresModesArray                   : array[ModeType] of PChar = ('CW', 'DIG', 'PH', 'ALL', nil, nil);

begin

  Index := Format(RequestBody,

    'xml=<?xml version="1.0"?><dynamicresults>' +
    GSCR + '<soft>' + TR4W_CURRENTVERSION + '</soft>' +
    GSCR + '<contest>%s</contest>' +
    GSCR + '<call>%s</call>' +
    GSCR + '<class ops="%s" mode="%s" power="%s" bands="%s" transmitter="%s"></class>' +
    GSCR + '<breakdown>',
    ContestTypeSA[Contest],
    @MyCall[1],
    tCategoryOperatorSA[CategoryOperator],
    tCategoryModeSA[CategoryMode],
    tCategoryPowerSA[CategoryPower],
    tCategoryBandSA[CategoryBand],
    tCategoryTransmitterSA[CategoryTransmitter]
    );

  for TempBand := Band160 to All do
    for TempMode := CW to Both do
    begin
      if QSOTotals[TempBand, TempMode] = 0 then Continue;

      BandPchar := BandStringsArrayWithOutSpaces[TempBand];
      if TempBand = All then
        BandPchar := 'total';

      Index := Index + Format(@RequestBody[Index],
        GSCR + '<qso band="%s" mode="%s">%u</qso>',
        BandPchar,
        GetScoresModesArray[TempMode],
        QSOTotals[TempBand, TempMode]);
    end;

  for TempBand := Band160 to All do
    for TempMode := CW to Both do
      for m := Succ(Low(RemainingMultiplierType)) to High(RemainingMultiplierType) do
      begin
        if mo.MTotals[TempBand, TempMode, m] = 0 then Continue;

        BandPchar := BandStringsArrayWithOutSpaces[TempBand];
        if TempBand = All then
          BandPchar := 'total';

        Index := Index + Format(@RequestBody[Index],
          GSCR + '<mult band="%s" mode="%s" type="%s">%u</mult>',
          BandPchar,
          GetScoresModesArray[TempMode],
          GetScoresMults[m],
          mo.MTotals[TempBand, TempMode, m]
          );
      end;

  tGetSystemTime;
  Index := Index + Format(@RequestBody[Index],

    '</breakdown>' +
    GSCR + '<score>%u</score>' +
    GSCR + '<timestamp>%s</timestamp>' + GSCR + '</dynamicresults>', TotalScore, SystemTimeToString(UTC));

  Format(GetScoresBuffer, PostMethodRequestHeader, GetScoresQuery, Index, GetScoresHost);
//  ShowMessage(GetScoresBuffer);
  Windows.lstrcat(GetScoresBuffer, RequestBody);
//  ShowMessage(GetScoresBuffer);
  Result := Windows.lstrlen(GetScoresBuffer);
{
  if not Tree.tOpenFileForWrite(h, 'GetScoresAnswerFileName') then Exit;
  sWriteFile(h, GetScoresBuffer, Result);
  CloseHandle(h);
}
end;

end.

