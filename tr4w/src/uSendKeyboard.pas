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
unit uSendKeyboard;
{$IMPORTEDDATA OFF}

interface

uses
  uMMTTY,
  uTelnet,
  VC,
  TF,
  Windows,
  Tree,
  LOGSend,
  LogCW,
  LogWind,
  LogK1EA,
  Messages
  ;

function SendKeyboardCWDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
function NewSendKeyboardEditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT; stdcall;
procedure CloseSendKeyboardInputDialog(StopSending: boolean);

implementation
uses
  MainUnit;

var
  newpos, oldpos                        : integer;
  OldSendKeyboardEditProc               : Pointer;
  SendKeyboardWindow                    : HWND;

function SendKeyboardCWDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
s{, nextfilename}                       : ShortString;
//label  1;
begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin

        Windows.SetWindowText(hwnddlg, RC_SENDINGCW);
        tWM_SETFONT(CreateEdit(ES_LEFT or ES_AUTOHSCROLL or ES_UPPERCASE, 5, 5, 380, 26, hwnddlg, 101), MainWindowEditFont);
        CreateButton(BS_DEFPUSHBUTTON, CLOSE_WORD, 390, 5, 60, hwnddlg, 102);

        SendKeyboardWindow := hwnddlg;
        tAutoSendMode := True;
        SendDlgItemMessage(hwnddlg, 101, EM_LIMITTEXT, 255, 0);
        OldSendKeyboardEditProc := Pointer(Windows.SetWindowLong(Get101Window(hwnddlg), GWL_WNDPROC, integer(@NewSendKeyboardEditProc)));
        ControlAMode := True;
        if ActiveMode = Phone then Windows.SetWindowText(hwnddlg, TC_SENDINGSSBWAVFILENAME);
//        Windows.SetDlgItemText(hwnddlg, 101, CHR(153));
      end;

    WM_COMMAND:
      begin
        if HiWord(wParam) = EN_CHANGE then
        begin
//          s := GetDialogItemText(hwnddlg, 101);
          s[0] := Char(Windows.GetDlgItemText(hwnddlg, 101, @s[1], SizeOf(s) - 1));
          if ActiveMode <> Phone then
          begin
            if s <> '' then
            begin
//              CPUKeyer.CodeSpeed := CPUKeyer.CodeSpeed;
              newpos := length(s);
              if newpos > oldpos then
              begin
                AddStringToBuffer(s[newpos], CWTone);
              end
              else
                AddStringToBuffer(#8, CWTone);
              oldpos := newpos;
            end
            else
              oldpos := 0;
          end;
        end;
        case wParam of
{
          102:
            begin
              if ActiveMode = Phone then
              begin
                s := GetDialogItemText(hwnddlg, 101);
                if s = '' then CloseSendKeyboardInputDialog(False);
                if DVPEnable then
                  while s <> '' do
                  begin
                    nextfilename := RemoveFirstString(s);
                    GetRidOfPrecedingSpaces(nextfilename);
                    SendCrypticDVPString(nextfilename + '.WAV');
                  end;
              end;
              CloseSendKeyboardInputDialog(False);
            end;
}
          102, 2:
            CloseSendKeyboardInputDialog(True);
        end;
      end;

    WM_CLOSE:
      begin
        CloseSendKeyboardInputDialog(False);
{
        1:
        oldpos := 0;
        newpos := 0;
        ControlAMode := False;
        tAutoSendMode := False;
//        CPUKeyer.PTTUnForce;
        CPUKeyer.FlushCWBuffer;
        EndDialog(hwnddlg, 0);
      }end;
  end;
end;

function NewSendKeyboardEditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT; stdcall;
var
  s, nextfilename                       : ShortString;
begin
  if Msg = WM_KEYUP then
    if wParam = VK_RETURN then
    begin
      if ActiveMode = Phone then
      begin
        s := GetDialogItemText(hwnddlg, 101);
        if s = '' then CloseSendKeyboardInputDialog(False);
        if DVKEnable then
          while s <> '' do
          begin
            nextfilename := RemoveFirstString(s);
            GetRidOfPrecedingSpaces(nextfilename);
            SendCrypticDVPString(nextfilename + '.WAV');
          end;
      end;
      CloseSendKeyboardInputDialog(False);
    end;

  if Msg = WM_KEYDOWN then
  begin
//    if wParam in [VK_F1..vk_f12] then ProcessFuntionKeys(wParam);
    if wParam = VK_PRIOR then ProcessMenu(menu_cwspeedup);
    if wParam = VK_NEXT then ProcessMenu(menu_cwspeeddown);
  end;
  if Msg = WM_SYSKEYDOWN then if wParam = VK_F10 then
    CloseSendKeyboardInputDialog(False); //Windows.PostMessage(SendKeyboardWindow, WM_CLOSE, 0, 0);
    {$RangeChecks Off}     // 4.79.4
   Result := CallWindowProc(OldSendKeyboardEditProc, hwnddlg, Msg, wParam, lParam);
    {$RangeChecks On}
  end;

procedure CloseSendKeyboardInputDialog(StopSending: boolean);
begin
  oldpos := 0;
  newpos := 0;
  ControlAMode := False;
  tAutoSendMode := False;
  if StopSending then
  begin
    CPUKeyer.FlushCWBuffer;
  end;
{$IF MMTTYMODE}
  PostMmttyMessage(RXM_PTT, RXM_PTT_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED);
{$IFEND}

  EndDialog(SendKeyboardWindow, 0);
end;

end.

