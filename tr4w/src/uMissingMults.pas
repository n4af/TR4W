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
unit uMissingMults; {Missing Mults Report WinAPI}
{$IMPORTEDDATA OFF}
interface

uses

  Windows,
  LogEdit,
  Messages;

function MissingMultsReportProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation

function MissingMultsReportProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
begin
  RESULT := False;
  case Msg of
    WM_INITDIALOG:
      VisibleLog.ShowMissingMultiplierReport(hwnddlg);

    WM_COMMAND:
      if wParam = 2 then goto 1;

    WM_CLOSE: 1: EndDialog(hwnddlg, 0);

  end;

end;

end.

