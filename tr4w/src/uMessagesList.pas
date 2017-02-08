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
unit uMessagesList;

interface

uses
  VC,
  TF,
  Windows,
  Messages;

function MessagesListDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation

uses
  uProcessCommand,
  MainUnit;

function MessagesListDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  TempHWND                              : HWND;
  i                                     : integer;
begin
  Result := False;
  case Msg of
    WM_SETFONT:
      begin
        asm nop end;
      end;

    WM_INITDIALOG:
      begin
//        CreateButton('OK', 180, 305, 70, hwnddlg, 1);
        CreateOKCancelButtons( hwnddlg);
        Windows.SetWindowText(hwnddlg, TC_LIST_OF_COMMAND);
        TempHWND := CreateListBox(5, 5, 440, 280, hwnddlg, 90);

        for i := 0 to sCommands - 1 do
        begin
          Format(wsprintfBuffer, '%s', sCommandsArray[i].caCommand);
          tLB_ADDSTRING(TempHWND, wsprintfBuffer);
        end;

      end;

    WM_COMMAND:
      begin
        case wParam of
          1, 2: goto 1;
        end;
//        if HiWord(wParam) = LBN_DBLCLK then ProcessMenu(menu_send_message);
      end;

    WM_CLOSE: 1: EndDialog(hwnddlg, 0);

  end;
end;

end.

