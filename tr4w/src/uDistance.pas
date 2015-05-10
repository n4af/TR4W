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
unit uDistance; {Distance WinAPI}
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  LogGrid,
  Tree,
  Messages;

function DistanceDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation
uses MainUnit;

function DistanceDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose;
var

  I                                     : integer;
  Grid1, Grid2                          : Str20;
  s                                     : string;
begin
  RESULT := False;
  case Msg of

    WM_INITDIALOG:
      begin
        for I := 103 to 104 do
          SendDlgItemMessage(hwnddlg, I, EM_LIMITTEXT, 6, 0);

      end;
    WM_COMMAND:
      begin
        if HiWord(wParam) = EN_CHANGE then

        begin
          for I := 108 to 109 do Windows.SetDlgItemText(hwnddlg, I, nil);

          Grid1 := GetDialogItemText(hwnddlg, 103);
          if Grid1 = '' then Exit;

          Grid2 := GetDialogItemText(hwnddlg, 104);
          if Grid2 = '' then Exit;

          I := GetDistanceBetweenGrids(Grid1, Grid2);
          asm
          push i
          end;
          wsprintf(wsprintfBuffer, '%u km');
          asm add esp,12    end;
          Windows.SetDlgItemText(hwnddlg, 108, wsprintfBuffer);

          TR4W_WM_SetTest(hwnddlg, 108, IntToStr(GetDistanceBetweenGrids(Grid1, Grid2)) + ' km');
          TR4W_WM_SetTest(hwnddlg, 109, IntToStr(GetEuropeanDistanceBetweenGrids(Grid1, Grid2)) + ' km');
        end;

        if wParam = 2 then goto ExitAndClose;
      end;
    WM_CLOSE: ExitAndClose: EndDialog(hwnddlg, 0);

  end;
end;
end.

