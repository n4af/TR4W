unit uMMTTY;
{$IMPORTEDDATA OFF}

interface

uses
  //  Richedit,
  TF,
  VC,
  uCommctrl,
  Windows,
  Messages,
  LogK1EA,
  LogWind,
  Tree;

type
  TCharFormatA = record
    cbSize: UINT;
    dwMask: LONGINT;
    dwEffects: LONGINT;
    yHeight: LONGINT;
    yOffset: LONGINT;
    crTextColor: TColorRef;
    bCharSet: Byte;
    bPitchAndFamily: Byte;
    szFaceName: array[0..LF_FACESIZE - 1] of AnsiChar;
  end;

const
  EM_SETCHARFORMAT                      = WM_USER + 68;
  SCF_SELECTION                         = $0001;

  RXM_HANDLE                            = $0000;
  RXM_REQHANDLE                         = $0001;
  RXM_EXIT                              = $0002;

  RXM_PTT                               = $0003;

  RXM_PTT_SWITCH_TO_RX_IMMEDIATELY      = $00000000;
  RXM_PTT_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED = $00000001;
  RXM_PTT_SWITCH_TO_TX                  = $00000002;
  RXM_PTT_CLEAR_THE_TX_BUFFER           = $00000004;

  RXM_CHAR                              = $0004;

  RXM_WINPOS                            = $0005;
  RXM_WIDTH                             = $0006;
  RXM_REQPARA                           = $0007;
  RXM_SETBAUD                           = $0008;
  RXM_SETMARK                           = $0009;

  RXM_SETSPACE                          = $000A;
  RXM_SETSWITCH                         = $000B;
  RXM_SETHAM                            = $000C;
  RXM_SHOWSETUP                         = $000D;
  RXM_SETVIEW                           = $000E;

  RXM_SETSQLVL                          = 15;
  RXM_SHOW                              = 16;
  RXM_SETFIG                            = 17;
  RXM_SETRESO                           = 18;
  RXM_SETLPF                            = 19;

  RXM_SETTXDELAY                        = 20;
  RXM_UPDATECOM                         = 21;
  RXM_SUSPEND                           = 22;
  RXM_NOTCH                             = 23;
  RXM_PROFILE                           = 24;

  RXM_TIMER                             = 25;
  //    RXM_ENBFOCUS =0;	// added on Ver1.63A
  //    RXM_SETDEFFREQ =0;	// added on Ver1.63B
  //    RXM_SETLENGTH =0;	// added on Ver1.63B
  //--------------------------------------
  TXM_HANDLE                            = $8000; // MMTTY -> APP
  TXM_REQHANDLE                         = $8001;
  TXM_START                             = $8002;
  TXM_CHAR                              = $8003;
  TXM_PTTEVENT                          = $8004;

  TXM_HEIGHT                            = $8005;
  TXM_BAUD                              = $8006;
  TXM_MARK                              = $8007;
  TXM_SPACE                             = $8008;
  TXM_SWITCH                            = $8009;

  TXM_VIEW                              = $800A;
  TXM_LEVEL                             = $800B;
  TXM_FIGEVENT                          = $800C;
  TXM_RESO                              = $800D;
  TXM_LPF                               = $800E;

  TXM_THREAD                            = $800F;
  TXM_PROFILE                           = $8010;
  TXM_NOTCH                             = $8011;
  TXM_DEFSHIFT                          = $8012;
  //    TXM_RADIOFREQ = $8000;	// added on Ver1.63

type

  TCallSignProcessObject = record
    cpBuffer: array[0..15] of Char;
    cpEnable: boolean;
    cpPos: integer;
    cpPos1: integer;
    cpPos2: integer;
    cpContainN: boolean;
    cpContainA: boolean;
    cpStartPos: integer;
  end;

  MMTTYObject = record
    mmttyMSG: Cardinal;
    mmttyEngine: HWND;
    mmttyRichEdit: HWND;
    mmttyTXIsOn: boolean;
    mmttyTwoBytes: array[0..1] of Char;
    mmttyCF: TCharFormatA;
    mmttyCallProcess: TCallSignProcessObject;
    mmttyLastCallsign: CallString;
    mmttyCurrentPos: integer;
  end;

function MMTTYDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure mmttyProcessMessage(wp: integer; lp: integer);
procedure PostMmttyMessage(Command: integer; lParam: integer);
function NewMMTTYRichEditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): integer; stdcall;

var

  MMTTY                                 : MMTTYObject;
{
  mmttyMSG                             : Cardinal;
  mmttyEngine                           : HWND;
  mmttyRichEdit                         : HWND;
  mmttyTXIsOn                           : boolean;
//  MMTTY_FIRST_TX_CHAR                   : boolean = True;
  mmttyTwoBytes                       : array[0..1] of Byte = (73, 0);
  mmttyCF                               : TCharFormatA;
}
  OldMMTTYRichEditProc                  : Pointer;

implementation
uses
  LogEdit,
  uFileView,
  MainUnit;

function MMTTYDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
begin
  Result := False;
  case Msg of
    {
        WM_MOUSEACTIVATE:
          begin
            tCleareCallWindow;
            PostMessage(MMTTYRichEdit, WM_COPY, 0, 0);
            PostMessage(CallWindowHandle, WM_PASTE, 0, 0);
            Windows.SetFocus(CallWindowHandle);
          end;
    }
    WM_WINDOWPOSCHANGING: WINDOWPOSCHANGINGPROC(PWindowPos(lParam));
    WM_EXITSIZEMOVE: FrmSetFocus;

    WM_INITDIALOG:
      begin

        tr4w_WindowsArray[tw_MMTTYWINDOW_INDEX].WndHandle := hwnddlg;

//        if TR4W_MMTTYPATH[0] = #0 then SetCommand('MMTTY ENGINE');

        Format(wsprintfBuffer, '"%s" -t -s -u -r', TR4W_MMTTYPATH);
{
-t FFT spectrum, Waterfall, and XY scope are displayed.
-s Control menus are displayed in addition to the above components.
-u Control buttons are displayed.
-r Control menus are also displayed in addition to the above components.
}
        WinExec(wsprintfBuffer, SW_SHOW);
{
        if WinExec(wsprintfBuffer, SW_SHOW) < 31 then
        begin

          asm
          push p
          call SysErrorMessage
          push eax
          end;
          wsprintf(wsprintfBuffer, '%s'#13'MMTTY PATH = %s');
          asm add esp,16
          end;
          showwarning(wsprintfBuffer);
          goto 1;
        end;
}
        MMTTY.mmttyMSG := RegisterWindowMessage('MMTTY');
        MMTTY.MMTTYRichEdit := CreateRichEdit(hwnddlg);
        tListBoxClientAlign(hwnddlg);

        MMTTY.mmttyCallProcess.cpEnable := True;

        MMTTY.mmttyCF.cbSize := SizeOf(TCharFormatA);
        //MMTTY.mmttyCF.yHeight :=20;
        MMTTY.mmttyCF.szFaceName := 'Lucida Console'; //}'Courier New';
        MMTTY.mmttyCF.dwMask := CFM_COLOR + CFM_FACE + CFM_BOLD;
        SendMessage(MMTTY.MMTTYRichEdit, EM_SETCHARFORMAT, SCF_SELECTION, integer(@MMTTY.mmttyCF));
//        OldMMTTYRichEditProc := Pointer(Windows.SetWindowLong(MMTTYRichEdit, GWL_WNDPROC, integer(@NewMMTTYRichEditProc)));
      end;
    WM_COMMAND:
      begin
        case LoWord(wParam) of
          100:

            begin
              //              PostMessage(MMTTY_Handle, MSG_MMTTY, RXM_SHOWSETUP, 0);

            end;
        end;
      end;
    WM_LBUTTONDOWN: DragWindow(hwnddlg);
    WM_DESTROY:
      begin
        PostMmttyMessage(RXM_EXIT, 0);
        Windows.ZeroMemory(@MMTTY, SizeOf(MMTTY));
      end;

    WM_NCDESTROY:
      begin
        RichEditOperation(False);
{
        if RichEditViewer = INVALID_HANDLE_VALUE then
        begin
          FreeLibrary(RICHED32DLLHANDLE);
          RICHED32DLLHANDLE := 0;
        end;
      }end;

    WM_CLOSE:
      1: CloseTR4WWindow(tw_MMTTYWINDOW_INDEX);
    WM_SIZE: tListBoxClientAlign(hwnddlg);
  end;

end;

procedure mmttyUpdateCharFormat();
begin
  SendMessage(MMTTY.MMTTYRichEdit, EM_SETCHARFORMAT, SCF_SELECTION, integer(@MMTTY.mmttyCF));
end;

procedure mmttyProcessChar(c: Char);
var
  isDupe                                : boolean;
begin
  if MMTTY.mmttyTXIsOn then Exit;

  if c in ['.', ' ', #13, #10] then
  begin

    if MMTTY.mmttyCallProcess.cpEnable then
      if MMTTY.mmttyCallProcess.cpPos in [3..8] then
        if MMTTY.mmttyCallProcess.cpContainN then
          if MMTTY.mmttyCallProcess.cpContainA then
          begin
            Windows.SetWindowText(tr4w_WindowsArray[tw_MMTTYWINDOW_INDEX].WndHandle, MMTTY.mmttyCallProcess.cpBuffer);

            Windows.ZeroMemory(@MMTTY.mmttyLastCallsign, SizeOf(MMTTY.mmttyLastCallsign));
            Windows.CopyMemory(@MMTTY.mmttyLastCallsign[1], @MMTTY.mmttyCallProcess.cpBuffer, MMTTY.mmttyCallProcess.cpPos);
            MMTTY.mmttyLastCallsign[0] := Char(MMTTY.mmttyCallProcess.cpPos);
            isDupe := VisibleLog.CallIsADupe(MMTTY.mmttyLastCallsign, ActiveBand, ActiveMode);
//            PutCallToCallWindow(MMTTY.mmttyLastCallsign);

            SendMessage(MMTTY.mmttyRichEdit,
              EM_SETSEL,
              MMTTY.mmttyCallProcess.cpStartPos,
              MMTTY.mmttyCallProcess.cpStartPos + MMTTY.mmttyCallProcess.cpPos + 1 - 1);

            MMTTY.mmttyCF.dwMask := CFM_COLOR + CFM_BOLD + CFM_STRIKEOUT;
//            MMTTY.mmttyCF.crTextColor := $00FF0000;
            //MMTTY.mmttyCF.crTextColor := $000000FF;

            MMTTY.mmttyCF.dwEffects := CFE_BOLD;
            if isDupe then
            begin
              MMTTY.mmttyCF.dwEffects := {CFE_STRIKEOUT + }CFE_BOLD;
              MMTTY.mmttyCF.crTextColor := $000000FF;
            end;

            mmttyUpdateCharFormat;

            SendMessage(MMTTY.mmttyRichEdit, EM_SETSEL, -1, -1);

//            MMTTY.mmttyCF.dwMask := CFM_COLOR + CFM_BOLD + CFM_STRIKEOUT;
            MMTTY.mmttyCF.crTextColor := $00000000;
            MMTTY.mmttyCF.dwEffects := 0;
            mmttyUpdateCharFormat;

          end;

    Windows.ZeroMemory(@MMTTY.mmttyCallProcess, SizeOf(MMTTY.mmttyCallProcess));
    MMTTY.mmttyCallProcess.cpEnable := True;
    MMTTY.mmttyCallProcess.cpStartPos := MMTTY.mmttyCurrentPos;
    Exit;
  end;

  if MMTTY.mmttyCallProcess.cpPos = 15 then MMTTY.mmttyCallProcess.cpEnable := False;

  if not MMTTY.mmttyCallProcess.cpEnable then Exit;

  MMTTY.mmttyCallProcess.cpBuffer[MMTTY.mmttyCallProcess.cpPos] := c;

  if c in ['0'..'9'] then MMTTY.mmttyCallProcess.cpContainN := True
  else
    if c in ['A'..'Z', {'a'..'z',} '/'] then MMTTY.mmttyCallProcess.cpContainA := True
    else
      MMTTY.mmttyCallProcess.cpEnable := False;

  inc(MMTTY.mmttyCallProcess.cpPos);

end;

procedure mmttyProcessMessage(wp: integer; lp: integer);
var
  h                                     : HWND;
begin
  case wp of

    TXM_PTTEVENT:
      begin
        if lp = 0 then
        begin
          PTTOff;
          MMTTY.mmttyTXIsOn := False;

          MMTTY.mmttyCF.dwMask := CFM_COLOR;
          MMTTY.mmttyCF.crTextColor := clblack;
          mmttyUpdateCharFormat;
          tStartAutoCQ;
        end;
        if lp = 1 then
        begin
          MMTTY.mmttyTXIsOn := True;
          MMTTY.mmttyCF.dwMask := CFM_COLOR;
          MMTTY.mmttyCF.crTextColor := $00AAAAAA;
          mmttyUpdateCharFormat;
        end;
      end;

    TXM_HANDLE:
      begin
        MMTTY.MMTTYEngine := lp;
        PostMmttyMessage(RXM_HANDLE, tr4whandle);
      end;

    TXM_CHAR:
      begin
        MMTTY.mmttyTwoBytes[0] := Char(lp);
        h := MMTTY.MMTTYRichEdit;
        SendMessage(h, EM_SETSEL, -1, -1);
//        SendMessage(h, EM_SCROLLCARET, 0, 0);
        SendMessage(h, EM_REPLACESEL, integer(False), integer(@MMTTY.mmttyTwoBytes));
        mmttyProcessChar(Char(lp));
        inc(MMTTY.mmttyCurrentPos);
      end;
  end;

end;

procedure PostMmttyMessage(Command: integer; lParam: integer);
begin
  if MMTTY.MMTTYEngine = 0 then Exit;
  PostMessage(MMTTY.MMTTYEngine, MMTTY.mmttyMSG, Command, lParam);
end;

function NewMMTTYRichEditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): integer; stdcall;
begin
  Result := 0;
  if Msg = WM_LBUTTONDBLCLK then
  begin
    tCleareCallWindow;
    PostMessage(MMTTY.MMTTYRichEdit, WM_COPY, 0, 0);
    PostMessage(wh[mweCall], WM_PASTE, 0, 0);
    PostMessage(wh[mweCall], WM_SETFOCUS, 0, 0);

      //      Windows.SetFocus(CallWindowHandle);
      //      Exit;
  end;
  Result := CallWindowProc(OldMMTTYRichEditProc, hwnddlg, Msg, wParam, lParam);

end;

end.

