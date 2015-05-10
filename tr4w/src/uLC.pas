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
unit uLC; {LC WinAPI}
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  LogGrid,
  Tree,
  Messages;

function LCDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation
uses MainUnit;

function LCDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose;
var
  l, f, c                               : REAL;
  lb                                    : LongBool;
  I                                     : Byte;
  TempByte                              : Byte;
begin
  RESULT := False;
  case Msg of

    WM_INITDIALOG:
      begin
        //        for Resul := 103 to 104 do SendDlgItemMessage(hwnddlg, Resul, EM_LIMITTEXT, 6, 0);

      end;
    WM_COMMAND:
      begin
        if HiWord(wParam) = EN_CHANGE then

        begin

          f := GetDlgItemInt(hwnddlg, 105, lb, lb) / 1000;
          f := f * f;
          f := f * 0.00003948;
          for I := 103 to 104 do
            if lParam = GetDlgItem(hwnddlg, I) then
            begin
              if GetFocus <> DWORD(lParam) then Exit;
              TempByte := 104;
              if I = 104 then TempByte := 103;

              SetDlgItemText(hwnddlg, TempByte, nil);
              c := GetDlgItemInt(hwnddlg, integer(I), lb, lb);
              if c = 0 then Exit;
              l := f * c;
              l := 1.0 / l;
              TR4W_WM_SetTest(hwnddlg, TempByte, RealToStr2(l));
            end;

        end;

        if wParam = 2 then goto ExitAndClose;
      end;
    WM_CLOSE: ExitAndClose: EndDialog(hwnddlg, 0);

  end;
end;
end.

