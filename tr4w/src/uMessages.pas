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
unit uMessages;
{$IMPORTEDDATA OFF}
interface

uses
  uAltP,
  TF,
  VC,
  Windows,
  Messages,
  Tree;

function MESDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  MessagesKeys                          : array[1..12] of HWND;
  MessagesValues                        : array[1..12] of HWND;

implementation
uses uRadioPolling,
  MainUnit;

function MESDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  i                                     : integer;
const
  LineHeight                            = 15;
  ceoa                                  : array[1..3] of PChar = (RC_PRESS_C, RC_PRESS_E, RC_PRESS_O);
label
  1;

begin
  Result := False;
  case Msg of

    WM_INITDIALOG:
      begin

        Windows.SetWindowText(hwnddlg, RC_MEMPROGFUNC);

        for i := 1 to 3 do
        begin
          CreateButton(BS_LEFT, ceoa[i], 30, -10 + i * 30, 350, hwnddlg, i + 100);
        end;

      end;

    WM_COMMAND:
      begin
        if wParam = 2 then goto 1;
        if HiWord(wParam) = BN_CLICKED then
        begin
          MesWindow := CQMsgWin;
          if LoWord(wParam) = 102 then MesWindow := ExMsgWin;
          if LoWord(wParam) = 103 then MesWindow := OtherMsgWin;
          EndDialog(hwnddlg, 0);
          OpenListOfMessages;
        end;

      end;

    WM_CLOSE: 1: EndDialog(hwnddlg, 0);

  end;
end;

end.

