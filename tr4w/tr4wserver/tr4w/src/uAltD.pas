unit uAltD;
{$IMPORTEDDATA OFF}

interface

uses
  VC,
  TF,
  Windows,
  Tree,
  uCallsigns,
  uMaster,
  LogEdit,
  LogStuff,
  LOGSend,
  LogCW,
  LogRadio,
  LogK1EA,
  LogWind,
  Messages
  ;

function AltDDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
function NewAltDEditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT; stdcall;

var
  AltDEditWindowHandle                  : HWND;
  OldAltDEditProc                       : Pointer;
implementation
uses
  MainUnit;

function AltDDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  P1, P2                                : PChar;
begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin

        Windows.SetWindowText(hwnddlg, RC_DUPECHECKOAR);

        Format(TempBuffer1, TC_ENTERCALLTOBECHECKEDON, BandStringsArray[InActiveRadioPtr.BandMemory], ModeStringArray[InActiveRadioPtr.ModeMemory]);
        CreateStatic(TempBuffer1, 15, 3, 250, hwnddlg, 102);

        AltDEditWindowHandle := CreateEdit(ES_CENTER or ES_UPPERCASE or WS_BORDER, 15, 27, 250, 30, hwnddlg, 101);
        asm
    mov edx,[MainWindowEditFont]
    call tWM_SETFONT
        end;
        CreateOKCancelButtons(hwnddlg);

//        AltDEditWindowHandle := Get101Window(hwnddlg);

        SendMessage(AltDEditWindowHandle, EM_LIMITTEXT, 12, 0);
        OldAltDEditProc := Pointer(Windows.SetWindowLong(AltDEditWindowHandle, GWL_WNDPROC, integer(@NewAltDEditProc)));

        if AltDBufferEnable then
          Windows.SetWindowText(AltDEditWindowHandle, @DupeInfoCall[1]);
      end;

    WM_CTLCOLOREDIT:
      begin
//        SetBkMode(HDC(wParam), TRANSPARENT);
        SetBkColor(HDC(wParam), tr4wColorsArray[trYellow]);
        Result := BOOL(tr4wBrushArray[trYellow]);
      end;

    WM_COMMAND:
      begin
        if HiWord(wParam) = EN_CHANGE then
        begin
          tClearDupeInfoCall;
          DupeInfoCall[0] := CHR(Windows.GetDlgItemText(hwnddlg, 101, @DupeInfoCall[1], SizeOf(DupeInfoCall) - 1));
//          DupeInfoCall := GetDialogItemText(hwnddlg, 101);
          if SCPMinimumLetters > 0 then
          begin
            ClearMasterListBox;
            VisibleLog.SuperCheckPartial(DupeInfoCall, True, InActiveRadioPtr);
          end;
          CallsignsList.CreatePartialsList(DupeInfoCall);
        end;
        case wParam of
          1, 2:
            begin
              if wParam = 2 then
                tClearDupeInfoCall;
              goto 1;
            end;
        end;
      end;

    WM_CLOSE:
      begin
        1:
        EndDialog(hwnddlg, 0);
      end;
  end;
end;

function NewAltDEditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT; stdcall;
begin
  if Msg = WM_CHAR then
  begin
    if KeyboardCallsignChar(wParam, False) = False then Exit;
  end;

  Result := CallWindowProc(OldAltDEditProc, hwnddlg, Msg, wParam, lParam);
end;
end.

