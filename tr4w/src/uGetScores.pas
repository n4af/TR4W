{
 Copyright Dmitriy Gulyaev UA4WLI 2015.

 This file is part of TR4W  (SRC)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W in  GPL_License.TXT. 
If not, ref: 
http://www.gnu.org/licenses/gpl-3.0.txt
 }
unit uGetScores;
{$IMPORTEDDATA OFF}
interface

uses

  TF,
  Version,
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
  Classes,
  SysUtils,
  IdHTTP,
  IdSSLOpenSSL,
  Tree
  ;
function GetScoresDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure CreateConnectionAndSendReportToGetScores;
procedure RunPOSTGetScoresThread;
//function MakePOSTRequest: integer;
//function MakePOSTRequestForRDXC2010: integer;
function MakePOSTRequestNew: integer;
procedure ShowGetScoresStatus(Status: PChar);
procedure CheckServerAnswer(AnswerLength: integer);

// Issue #783 -- HamScore RTC support reuses the dynamicresults fragment
// the existing scoreboard poster already builds.  This returns just the
// XML container (no <?xml> prolog, no `xml=` form-encoding prefix), so
// the RTC uploader can wrap it in a multi-container POST.
function BuildDynamicResultsXml: AnsiString;
//procedure SendOnLineResultsToRDXC2010Site;

var
  GetScoresPostingID                    : integer;
  GetScoresSeverPostingAddress          : ShortString {= 'https://post.contestonlinescore.com/post/'};
  GetScoresSeverReadingAddress          : ShortString {= 'https://contestonlinescore.com/scoreboard/'};
  GetScoresBuffer                       : array[0..4096 - 1] of Char;
  GetScoresThreadID                     : Cardinal;
  GetScoresThreadHandle                 : Cardinal;
  GetScoresAnswerFileName               : array[0..255] of Char;
const

  GSCR                                  = ''; //#13#10;
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
     begin
     logger.Debug('Calling tCreateThread from RunPOSTGetScoresThread');
     GetScoresThreadHandle := tCreateThread(@CreateConnectionAndSendReportToGetScores, GetScoresThreadID);
     logger.Debug('Created GetScores thread with threadid of %d',[GetScoresThreadID] );
     end;
//  CreateConnectionAndSendReportToGetScores;
end;

procedure CreateConnectionAndSendReportToGetScores;
var
   http : TIdHTTP;
   ssl  : TIdSSLIOHandlerSocketOpenSSL;
   PostBody  : TStringStream;
   sURL      : string;
   h         : HWND;
begin
   ShowGetScoresStatus(TC_CONNECT);
   MakePOSTRequestNew; // fills GetScoresBuffer with the URL-encoded POST body

   sURL := string(GetScoresSeverPostingAddress);

   http := TIdHTTP.Create(nil);
   ssl  := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
   try
      // Attach SSL handler only for https:// URLs so plain http:// custom
      // URLs (if configured by the operator) still work without TLS.
      if (Length(sURL) >= 8) and
         (LowerCase(Copy(sURL, 1, 8)) = 'https://') then
         begin
         ssl.SSLOptions.Method := TIdSSLVersion(sslvTLSv1_2);
         http.IOHandler := ssl;
         end;

      http.HandleRedirects := True;
      http.Request.UserAgent    := TR4W_CURRENTVERSION;
      http.Request.ContentType  := 'application/x-www-form-urlencoded';

      PostBody := TStringStream.Create(string(PChar(@GetScoresBuffer)));
      try
         logger.Debug('Score post: URL = %s', [sURL]);
         http.Post(sURL, PostBody);
      finally
         PostBody.Free;
      end;

      if http.ResponseCode = 200 then
         begin
         // Save the server response for diagnostics
         if tOpenFileForWrite(h, GetScoresAnswerFileName) then
            begin
            sWriteFile(h, GetScoresBuffer, lstrlen(GetScoresBuffer));
            CloseHandle(h);
            end;
         ShowGetScoresStatus(TC_UPLOADEDSUCCESSFULLY);
         end
      else
         begin
         logger.Warn('Score post: server returned %d for %s', [http.ResponseCode, sURL]);
         ShowGetScoresStatus(TC_FAILEDTOCONNECTTOGETSCORESORG);
         end;

   except
      on E: Exception do
         begin
         logger.Error('Score post failed for %s: %s', [sURL, E.Message]);
         ShowGetScoresStatus(TC_FAILEDTOCONNECTTOGETSCORESORG);
         end;
   end;

   http.Free;
   ssl.Free;
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
  nTotal                                : integer;
  nQSOs                                 : integer;
  sContestName                          : string;
const
  GetScoresMults                        : array[RemainingMultiplierType] of PChar = (nil, 'state', 'country', 'zone', 'prefix');
  GetScoresModesArray                   : array[ModeType] of PChar = ('CW', 'DIG', 'PH', 'ALL', nil, nil);

begin
  nTotal := 0;
  nQSOs := 0;

  if length(ContestsArray[Contest].ADIFName) = 0 then
     begin
     sContestName := ContestTypeSA[Contest]
     end
  else
     begin
     sContestName := ContestsArray[Contest].ADIFName;
     end;

  Index := Format(RequestBody,

   'xml=<?xml version="1.0"?><dynamicresults>' +
    GSCR + '<soft>' + TR4W_CURRENTVERSION + '</soft>' +
    GSCR + '<contest>%s</contest>' +
    GSCR + '<call>%s</call>' +
    GSCR + '<class ops="%s" mode="%s" power="%s" bands="%s" transmitter="%s"></class>' +
    GSCR + '<breakdown>',
    PChar(sContestName),
    @MyCall[1],
    tCategoryOperatorSA[CategoryOperator],
    tCategoryModeSA[CategoryMode],
    tCategoryPowerSA[CategoryPower],
    tCategoryBandSA[CategoryBand],
    tCategoryTransmitterSA[CategoryTransmitter]
    );

    { QSOTotals is set to the high number even after contacts are deleted. That is not the right score so add up the totals each time  // ny4i


    **** NOTE ****
    You cannot use QSOTotals[TempBand, TempMode] for an accurate score for the total QSOs. QSOTotals[TempBand, TempMode] is not decremented for ALL as that is the log's total QSO count including deleted contacts.
    QSOTotals[TempBand, TempMode] is accurate for the individual bands so just sum those values to calculate the total     ny4i
  }
    
  for TempBand := Band160 to AllBands do
    for TempMode := CW to {Both} Phone do  // ModeType goes CW, Digital, Phone
    begin
      if QSOTotals[TempBand, TempMode] = 0 then Continue;

      BandPchar := BandStringsArrayWithOutSpaces[TempBand];
      if TempBand = AllBands then
         begin
         BandPchar := 'total';
         nQSOs := nTotal;
         end
      else
         begin
         nQSOs := QSOTotals[TempBand, TempMode];
         nTotal := nTotal + nQSOs;
         end;

     // nTotal := nTotal + QSOTotals[TempBand, TempMode];
      Index := Index + Format(@RequestBody[Index],
        GSCR + '<qso band="%s" mode="%s">%u</qso>',
        BandPchar,
        GetScoresModesArray[TempMode],
        nQSOs {QSOTotals[TempBand, TempMode]});
    end;
    Index := Index + Format(@RequestBody[Index],
        GSCR + '<qso band="total" mode="ALL">%u</qso>',
        nQSOs {QSOTotals[TempBand, TempMode]});

  for TempBand := Band160 to AllBands do
    for TempMode := CW to Both do
      for m := Succ(Low(RemainingMultiplierType)) to High(RemainingMultiplierType) do
      begin
        if mo.MTotals[TempBand, TempMode, m] = 0 then Continue;

        BandPchar := BandStringsArrayWithOutSpaces[TempBand];
        if TempBand = AllBands then
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

  // Copy the URL-encoded XML body into GetScoresBuffer for use by the caller.
  // HTTP framing is now handled by TIdHTTP in CreateConnectionAndSendReportToGetScores.
  lstrcpy(GetScoresBuffer, RequestBody);
  logger.Debug('[MakePOSTRequestNew] %s', [GetScoresBuffer]);
  Result := Windows.lstrlen(GetScoresBuffer);
{
  if not Tree.tOpenFileForWrite(h, 'GetScoresAnswerFileName') then Exit;
  sWriteFile(h, GetScoresBuffer, Result);
  CloseHandle(h);
}
end;

// ---------------------------------------------------------------------------
// Issue #783 -- standalone <dynamicresults> builder for the HamScore RTC
// uploader (uHamScore).  Mirrors the XML produced by MakePOSTRequestNew but
// returns an AnsiString so the RTC worker thread can build its own copy
// without sharing the GetScoresBuffer global with the existing 5-minute
// scoreboard poster.
//
// IMPORTANT: when MakePOSTRequestNew's XML schema changes, mirror the change
// here.  The two functions must stay aligned because hamscore.com expects
// the same dynamicresults shape.
// ---------------------------------------------------------------------------

function BuildDynamicResultsXml: AnsiString;
var
  TempBand:    BandType;
  TempMode:    ModeType;
  m:           RemainingMultiplierType;
  BandStr:     string;
  nTotal:      Integer;
  nQSOs:       Integer;
  sContest:    string;
  ts:          string;
const
  RTCMultStr:  array[RemainingMultiplierType] of string = ('', 'state', 'country', 'zone', 'prefix');
  RTCModeStr:  array[ModeType] of string = ('CW', 'DIG', 'PH', 'ALL', '', '');
begin
  nTotal := 0;
  nQSOs  := 0;

  if Length(ContestsArray[Contest].ADIFName) = 0 then
    sContest := ContestTypeSA[Contest]
  else
    sContest := ContestsArray[Contest].ADIFName;

  Result := AnsiString(Format(
    '<dynamicresults>' +
    '<soft>%s</soft>' +
    '<contest>%s</contest>' +
    '<call>%s</call>' +
    '<class ops="%s" mode="%s" power="%s" bands="%s" transmitter="%s"></class>' +
    '<breakdown>',
    [TR4W_CURRENTVERSION,
     sContest,
     string(MyCall),
     tCategoryOperatorSA[CategoryOperator],
     tCategoryModeSA[CategoryMode],
     tCategoryPowerSA[CategoryPower],
     tCategoryBandSA[CategoryBand],
     tCategoryTransmitterSA[CategoryTransmitter]]));

  for TempBand := Band160 to AllBands do
    for TempMode := CW to Phone do
    begin
      if QSOTotals[TempBand, TempMode] = 0 then Continue;

      if TempBand = AllBands then
        begin
        BandStr := 'total';
        nQSOs   := nTotal;
        end
      else
        begin
        BandStr := string(BandStringsArrayWithOutSpaces[TempBand]);
        nQSOs   := QSOTotals[TempBand, TempMode];
        nTotal  := nTotal + nQSOs;
        end;

      Result := Result + AnsiString(Format(
        '<qso band="%s" mode="%s">%d</qso>',
        [BandStr, RTCModeStr[TempMode], nQSOs]));
    end;

  Result := Result + AnsiString(Format(
    '<qso band="total" mode="ALL">%d</qso>', [nQSOs]));

  for TempBand := Band160 to AllBands do
    for TempMode := CW to Both do
      for m := Succ(Low(RemainingMultiplierType)) to High(RemainingMultiplierType) do
      begin
        if mo.MTotals[TempBand, TempMode, m] = 0 then Continue;

        if TempBand = AllBands then
          BandStr := 'total'
        else
          BandStr := string(BandStringsArrayWithOutSpaces[TempBand]);

        Result := Result + AnsiString(Format(
          '<mult band="%s" mode="%s" type="%s">%d</mult>',
          [BandStr, RTCModeStr[TempMode], RTCMultStr[m],
           mo.MTotals[TempBand, TempMode, m]]));
      end;

  tGetSystemTime;
  ts := SystemTimeToString(UTC);
  Result := Result + AnsiString(Format(
    '</breakdown><score>%d</score><timestamp>%s</timestamp></dynamicresults>',
    [TotalScore, ts]));
end;

end.

