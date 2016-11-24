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
unit uAltD;
{$IMPORTEDDATA OFF}

interface

uses
  VC,
  TF,
  Windows,
  Tree,
  uCallsigns,
  uDupeSheet,   // 4.53.7
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




  //      tcreatestaticwindow(tempbuffer1,es_center,15,3,250,30,hwnddlg,0);
  //      tcreateeditwindow($00020014,tempbuffer1,$50010014,es_center,15,27,250,30,hwnddlg);
          AltDEditWindowHandle := CreateEdit( WS_MaximizeBox or WS_MinimizeBOX or  ES_CENTER or ES_UPPERCASE or WS_BORDER,15, 27, 250, 30, hwnddlg, 101);
      //  altdeditwindowhandle := createmodaldialog( 250,15,hwnddlg,@newaltdeditproc,0);

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
      //    tClearDupeInfoCall;   4.39.4
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
              begin
                tClearDupeInfoCall;
            //    ClearAltD; // 4.53.7
             end;
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


