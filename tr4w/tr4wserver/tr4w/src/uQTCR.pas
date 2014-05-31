unit uQTCR;
{$IMPORTEDDATA OFF}
interface

uses
  VC,
  TF,
utils_text,
uCallSignRoutines,
  LogStuff,
  LogWind,
  LOGWAE,
  LogCW,
  LogDupe,
  LOGSUBS2,
  uTotal,
  Tree,
  Windows,
  Messages
  ;

function QTCRDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
function PutQTCSignInExchangeField(s: string): boolean;
function CheckQTCInfo(Control: integer): integer;
function NewQTCREditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT; stdcall;
function CheckQTCNr: boolean;
function CheckQTCR(Item: integer): boolean;

procedure SaveQTCR;
procedure SetItemEnabled(Item: integer);

const

  QTCRXButtonsPChar                     : array[1..10] of PChar =
    (
    '&AGN',
    'R&PT?',
    '&TIME?',
    '&CALL?',
    '&NR?',
    '&R',
    nil,
    '&QTC?',
    'QR&V',
    nil
    );

var
  QTCRWindow                            : HWND;
  QTCsReceived                          : integer;

implementation
uses MainUnit;

var
  QTCRCallsignWndHandle                 : HWND;
  QTCNrWndHandle                        : HWND;
  OldQTCREditProc                       : Pointer;
  QTCBuffer                             : array[0..63] of Char;
  QTCsInCurrentGroup                    : integer;
  CurrentGroup                          : integer;

function QTCRDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
const

  QTCLEFT                               = 5;
//  QTCHEIGHT                        = 22;
//  QTCROWSDIS                       = 2;
  QTCWIDTHARRAY                         : array[1..4] of integer = (20, 60, 160, 80);
  QTCLEFTARRAY                          : array[1..4] of integer = (5, 27, 89, 251);
//  LeftArray                        : array[1..3] of integer = (30, 95 - 3, 95 + 170 - 1);
  NumberStyle                           = WS_DISABLED or WS_CHILD or WS_VISIBLE or WS_TABSTOP or ES_UPPERCASE or ES_NUMBER;
  CallsignStyle                         = WS_DISABLED or WS_CHILD or WS_VISIBLE or WS_TABSTOP or ES_UPPERCASE;
var
  TempString                            : string;
  r                                     : integer;
  h                                     : HWND;
label
  1, 2;
begin
  Result := False;
  case Msg of

    WM_INITDIALOG:
      begin
        Windows.SetWindowText(hwnddlg, RC_RECVQTC);
        CreateStatic(nil, 5, 285, 325, hwnddlg, 106);

        QTCRWindow := hwnddlg;
        SendStringAndStop('QTC?');
        tCreateStaticWindow(TC_QTC_CALLSIGN, WS_CHILD or SS_SUNKEN or SS_NOTIFY or SS_CENTER or WS_VISIBLE, QTCLEFT, 5, QTCWIDTHARRAY[1] + QTCROWSDIS + QTCWIDTHARRAY[2], 18, hwnddlg, 10);
        QTCRCallsignWndHandle := tCreateEditWindow(WS_EX_STATICEDGE, PChar(string(QTCCallsign)), WS_CHILD or SS_SUNKEN or SS_NOTIFY or SS_CENTER or WS_VISIBLE or ES_UPPERCASE, QTCLEFT + QTCWIDTHARRAY[1] + QTCROWSDIS + QTCWIDTHARRAY[2] + QTCROWSDIS, 5, 120, 18, hwnddlg, 88);
        OldQTCREditProc := Pointer(Windows.SetWindowLong(QTCRCallsignWndHandle, GWL_WNDPROC, integer(@NewQTCREditProc)));
        asm
        push MaxQTCsThisStation
        end;
        wsprintf(wsprintfBuffer, TC_ENTERQTCMAXOF);
        asm add esp,12
        end;
        tCreateStaticWindow(wsprintfBuffer, WS_CHILD or SS_SUNKEN or SS_NOTIFY or SS_CENTER or WS_VISIBLE, 212, 5, 140, 18, hwnddlg, 10);
        QTCNrWndHandle := tCreateEditWindow(WS_EX_STATICEDGE, nil, WS_CHILD or SS_SUNKEN or SS_NOTIFY or SS_CENTER or WS_VISIBLE, 355, 5, 90, 18, hwnddlg, 73);
        OldQTCREditProc := Pointer(Windows.SetWindowLong(QTCNrWndHandle, GWL_WNDPROC, integer(@NewQTCREditProc)));

        for r := 1 to 10 do
        begin
          tCreateStaticWindow(
            inttopchar(r),
            WS_CHILD or SS_SUNKEN or SS_NOTIFY or SS_CENTER or WS_VISIBLE,
            QTCLEFTARRAY[1],
            r * (QTCHEIGHT + QTCROWSDIS) + QTCTOP,
            QTCWIDTHARRAY[1],
            QTCHEIGHT,
            hwnddlg,
            r + 9
            );

          h := CreateWindowEx(
            WS_EX_STATICEDGE,
            EditPChar,
            nil,
            WS_CHILD or WS_DISABLED or WS_VISIBLE or WS_TABSTOP or ES_UPPERCASE or ES_NUMBER or SS_LEFT,
            QTCLEFTARRAY[2],
            r * (QTCHEIGHT + QTCROWSDIS) + QTCTOP,
            QTCWIDTHARRAY[2],
            QTCHEIGHT,
            hwnddlg,
            r + 200, hInstance, nil);
          asm
            mov edx,[MainWindowEditFont]
            call tWM_SETFONT
          end;
          OldQTCREditProc := Pointer(Windows.SetWindowLong(h, GWL_WNDPROC, integer(@NewQTCREditProc)));

          h := CreateWindowEx(
            WS_EX_STATICEDGE,
            EditPChar,
            nil,
            WS_CHILD or WS_DISABLED or WS_VISIBLE or WS_TABSTOP or ES_UPPERCASE,
            QTCLEFTARRAY[3],
            r * (QTCHEIGHT + QTCROWSDIS) + QTCTOP,
            QTCWIDTHARRAY[3],
            QTCHEIGHT,
            hwnddlg,
            r + 300, hInstance, nil);
          asm
            mov edx,[MainWindowEditFont]
            call tWM_SETFONT
          end;
          OldQTCREditProc := Pointer(Windows.SetWindowLong(h, GWL_WNDPROC, integer(@NewQTCREditProc)));

          h := CreateWindowEx(
            WS_EX_STATICEDGE,
            EditPChar,
            nil,
            WS_CHILD or WS_DISABLED or WS_VISIBLE or WS_TABSTOP or ES_UPPERCASE or ES_NUMBER,
            QTCLEFTARRAY[4],
            r * (QTCHEIGHT + QTCROWSDIS) + QTCTOP,
            QTCWIDTHARRAY[4],
            QTCHEIGHT,
            hwnddlg,
            r + 400, hInstance, nil);
          asm
            mov edx,[MainWindowEditFont]
            call tWM_SETFONT
          end;
          OldQTCREditProc := Pointer(Windows.SetWindowLong(h, GWL_WNDPROC, integer(@NewQTCREditProc)));

{
          tCreateStaticWindow(
            '101/10',
            WS_CHILD or SS_SUNKEN or SS_NOTIFY or SS_center or WS_VISIBLE,
            QTCLEFT + QTCWIDTHARRAY[1] + QTCROWSDIS,
            r * (QTCHEIGHT + QTCROWSDIS) + QTCTOP,
            QTCWIDTHARRAY[2],
            QTCHEIGHT,
            hwnddlg,
            r + 9
            );
}
          tCreateButtonWindow(
            WS_EX_STATICEDGE,
            QTCRXButtonsPChar[r],
            BS_PUSHBUTTON or BS_CENTER or WS_CHILD or WS_VISIBLE,
            370,
            r * (QTCHEIGHT + QTCROWSDIS) + QTCTOP,
            QTCWIDTHARRAY[4],
            QTCHEIGHT,
            hwnddlg, r + 89);

        end;
        asm
        lea  eax, MyCall[1]
        push eax
        end;
        wsprintf(wsprintfBuffer, '&DE %s');
        asm add esp,12
        end;
        SetDlgItemText(hwnddlg, 96, wsprintfBuffer);
        SetFocus(QTCNrWndHandle);
        QTCsReceived := 0;
        CurrentGroup := 0;
        QTCsInCurrentGroup := 0;
        CreateOKCancelButtons(hwnddlg)
      end;
//    WM_HELP: tWinHelp(62);

    WM_COMMAND:
      begin

        case wParam of
          2: goto 1;
          90..98:
            begin
              TempString := GetDialogItemText(hwnddlg, wParam);
              SendStringAndStop(TempString);
            end;
          1: SaveQTCR;
          110: SetFocus(QTCNrWndHandle);

        end;

      end;
    WM_CLOSE: 1:
      begin
        if wParam <> 1 then
          if CurrentGroup <> 0 then
            if YesOrNo(QTCRWindow, TC_DOYOUREALLYWANTTOABORTTHISQTC) = IDno then Exit;
        2:
        QTCRWindow := 0;
        EndDialog(hwnddlg, 0);

      end;

    {
        WM_CTLCOLORSTATIC:
          if GetDlgCtrlID(lParam) <> 0 then
          begin
            SetBkMode(hDC(wParam), TRANSPARENT);
            SetTextColor(HDC(wParam), $00FFFFFF);

            RESULT := BOOL(BlueBrush);
          end;
    }

  end;

end;

procedure SaveQTCR;
var
  i                                     : integer;
  QTCRXData                             : ContestExchange;
  lpTranslated                          : BOOL;
begin
  if QTCsReceived = 0 then Exit;
  if QTCsInCurrentGroup <> QTCsReceived then
    if YesOrNo(QTCRWindow, TC_DOYOUREALLYWANTTOSAVETHISQTC) = IDno then Exit;
  if YesOrNo(QTCRWindow, TC_EDITQTCPRESSYESTOEDITQTCORNOTOLOG) = IDYES then Exit;

  for i := 1 to QTCsReceived do
  begin
    IncrementQTCCount(QTCCallsign);
    Windows.ZeroMemory(@QTCRXData, SizeOf(ContestExchange));
    QTCRXData.ceRecordKind := rkQTCR;
//    tGetQSOSystemTime(QTCRXData.tSysTime);
//    QTCRXData.Band := ActiveBand;
//    QTCRXData.Mode := ActiveMode;
//    QTCRXData.ceComputerID := ComputerID;
    QTCRXData.Callsign := QTCCallsign;
    {Time}
    QTCRXData.NumberSent := Windows.GetDlgItemInt(QTCRWindow, 200 + i, lpTranslated, False);
    {EU Callsign}
    QTCRXData.Kids := GetDialogItemText(QTCRWindow, 300 + i);
    {Number}
    QTCRXData.NumberReceived := Windows.GetDlgItemInt(QTCRWindow, 400 + i, lpTranslated, False);
    {QTCNumber}
    QTCRXData.RandomCharsReceived := GetDialogItemText(QTCRWindow, 73);
//    tAddQSOToLog(QTCRXData);
    if AddRecordToLogAndSendToNetwork(QTCRXData) then
      Sleep(50);
  end;
  SendStringAndStop('QSL ' + GetDialogItemText(QTCRWindow, 73) + ' TU');
  SendMessage(QTCRWindow, WM_CLOSE, 1, 0);
end;

function PutQTCSignInExchangeField(s: string): boolean;
var
  c, i                                  : integer;
  NumbreinCallsign                      : boolean;
begin
  Result := False;
  i := length(s);
  if i < 4 then Exit;
  NumbreinCallsign := False;
  for c := 1 to i - 2 do
  begin
    if not tCharIsNumbers(s[c]) then if tCharIsNumbers(s[c + 1]) then NumbreinCallsign := True;
    if s[c] = '/' then NumbreinCallsign := False;
  end;
  if s[i - 1] = '/' then NumbreinCallsign := False;
  if NumbreinCallsign = False then Exit;

  if not tCharIsNumbers(s[i]) then Exit;
  Result := True;
end;

function CheckQTCInfo(Control: integer): integer;
var
  FirstField                            : integer;
  c                                     : integer;
begin

  FirstField := Control - Control mod 3;
  Result := -FirstField - 3;
  for c := FirstField to FirstField + 2 do
    if GetDialogItemText(QTCRWindow, c) = '' then
    begin
      Result := c;
      Break;
    end;
end;

function NewQTCREditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT; stdcall;
var
  i                                     : integer;
  P1, P2                                : integer;
begin
  Result := 0;
  case Msg of
    EM_SETSEL: Exit;
    WM_CHAR:
      begin
        if hwnddlg = QTCNrWndHandle then if not (Char(wParam) in ['0'..'9', '/', #8]) then Exit;
        if not (Char(wParam) in ['0'..'9', 'a'..'z', 'A'..'Z', '/', #8]) then Exit;
//        if (Windows.GetDlgCtrlID(hwnddlg) div 100) = 2 then
//          if Windows.GetWindowTextLength(hwnddlg) = 3 then SendMessage(QTCRWindow, WM_NEXTDLGCTL, 0, 0);
      end;
    WM_KEYUP:
      begin

        if wParam = VK_RETURN then
        begin
          if hwnddlg = QTCRCallsignWndHandle then Exit;

          if hwnddlg = QTCNrWndHandle then
          begin
            if CheckQTCNr then
            begin
              SetItemEnabled(1);
              SetFocus(GetDlgItem(QTCRWindow, 201));
              SendStringAndStop('QRV');
            end
            else
              Windows.SetDlgItemText(QTCRWindow, 106, TC_CHECKQTCNUMBER);
            Exit;
          end;

          i := Windows.GetDlgCtrlID(hwnddlg) mod 100;
          if CheckQTCR(i) then
          begin
            inc(QTCsReceived);
            if QTCsReceived < QTCsInCurrentGroup then
            begin
              SendStringAndStop('R');
              SetItemEnabled(i + 1);
              Windows.SetFocus(Windows.GetDlgItem(QTCRWindow, 201 + i));
            end
            else
            begin
              SaveQTCR;
            end;

          end;
//          Windows.SetWindowText(QTCRWindow, inttopchar(integer(TryParseQTCBuffer(hwnddlg))));
        end;

      end;

    WM_SYSKEYUP:
      begin

        if wParam = VK_F10 then ProcessMenu(menu_ctrl_sendkeyboardinput);
      end;

    WM_KEYDOWN:
      begin

        if (wParam = VK_RIGHT) or (wParam = VK_SPACE) then
        begin
          SendMessage(hwnddlg, EM_GETSEL, integer(@P1), integer(@P2));
          if GetWindowTextLength(hwnddlg) = P1 then SendMessage(QTCRWindow, WM_NEXTDLGCTL, 0, 0);
//          SendMessage(Windows.GetFocus, EM_SETSEL, 0, 0);
        end;

        if wParam = VK_LEFT then
        begin
          SendMessage(hwnddlg, EM_GETSEL, integer(@P1), integer(@P2));
          if P1 = 0 then SendMessage(QTCRWindow, WM_NEXTDLGCTL, 1, 0);
//          SendMessage(Windows.GetFocus, EM_SETSEL, 255, 255);
        end;

        if wParam = VK_DOWN then
        begin
//          SendMessage(hwnddlg, EM_GETSEL, integer(@P1), integer(@P2));
          SendMessage(QTCRWindow, WM_NEXTDLGCTL, 0, 0);
          SendMessage(QTCRWindow, WM_NEXTDLGCTL, 0, 0);
          SendMessage(QTCRWindow, WM_NEXTDLGCTL, 0, 0);
//          SendMessage(Windows.GetFocus, EM_SETSEL, p1, p2);
          Exit;
        end;
        if wParam = VK_UP then
        begin
          SendMessage(QTCRWindow, WM_NEXTDLGCTL, 1, 0);
          SendMessage(QTCRWindow, WM_NEXTDLGCTL, 1, 0);
          SendMessage(QTCRWindow, WM_NEXTDLGCTL, 1, 0);
          Exit;
        end;

        if wParam = VK_PRIOR then ProcessMenu(menu_cwspeedup);
        if wParam = VK_NEXT then ProcessMenu(menu_cwspeeddown);
//    if wParam = 5 then ProcessMenu(menu_ctrl_sendkeyboardinput);
      end;
  end;
  Result := CallWindowProc(OldQTCREditProc, hwnddlg, Msg, wParam, lParam);
end;

function CheckQTCNr: boolean;
var
  l                                     : integer;
  i                                     : integer;
  SlashPos                              : integer;
begin
//  Windows.SetDlgItemText(QTCRWindow, 106, nil);
  Result := False;
  l := Windows.GetWindowText(QTCNrWndHandle, QTCBuffer, SizeOf(QTCBuffer));
  if l <= 2 then Exit;
  if QTCBuffer[l - 1] = '/' then Exit;
  SlashPos := -1;
  for i := 0 to l - 2 do
  begin
    if QTCBuffer[i] = '/' then if SlashPos = -1 then SlashPos := i else Exit;
  end;
  if SlashPos = -1 then Exit;
  CurrentGroup := GetNumberFromCharBuffer(QTCBuffer);
  if CurrentGroup = 0 then Exit;
  QTCsInCurrentGroup := GetNumberFromCharBuffer(@QTCBuffer[SlashPos + 1]);
  if not (QTCsInCurrentGroup in [1..10]) then Exit;
  if QTCsInCurrentGroup > MaxQTCsThisStation then Exit;
  Result := True;
end;

function CheckQTCR(Item: integer): boolean;
var
  lpTranslated                          : BOOL;
  Time                                  : Cardinal;
  Call                                  : CallString;
//  Number                           : Cardinal;
begin
  Result := False;
  Time := Windows.GetDlgItemInt(QTCRWindow, 200 + Item, lpTranslated, False);
  if (lpTranslated = False) or ((Time mod 100) > 59) or (Time div 100 > 23) {or ((Item = 1) and (Time < 100))} then
  begin
    Windows.SetDlgItemText(QTCRWindow, 106, TC_CHECKTIME);
    Windows.SetFocus(Windows.GetDlgItem(QTCRWindow, 200 + Item));
    Exit;
  end;
  Call := GetDialogItemText(QTCRWindow, 300 + Item);
  if not GoodCallSyntax(Call) then
  begin
    if Call <> '' then Windows.SetDlgItemText(QTCRWindow, 106, TC_CHECKCALLSIGN);
    Windows.SetFocus(Windows.GetDlgItem(QTCRWindow, 300 + Item));
    Exit;
  end;

{  Number := }Windows.GetDlgItemInt(QTCRWindow, 400 + Item, lpTranslated, False);
  if lpTranslated = False then
  begin
//    Windows.SetDlgItemText(QTCRWindow, 106, 'Check number');
    Windows.SetFocus(Windows.GetDlgItem(QTCRWindow, 400 + Item));
    Exit;
  end;
  Windows.SetDlgItemText(QTCRWindow, 106, nil);
  Result := True;
end;

procedure SetItemEnabled(Item: integer);
begin
  EnableWindowTrue(QTCRWindow, 200 + Item);
  EnableWindowTrue(QTCRWindow, 300 + Item);
  EnableWindowTrue(QTCRWindow, 400 + Item);
end;

end.

