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
unit uRadio12;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  Messages,
  LogRadio,
  Tree;

function RadioInterfaceWindowDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation
uses
  LOGSUBS2,
  MainUnit;

function RadioInterfaceWindowDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  p                                     : PChar;
  i                                     : integer;
const
  l                                     : array[0..3] of PChar = (nil, 'RIT', 'XIT', 'SPLIT');
begin
  Result := False;
  case Msg of
    WM_LBUTTONDOWN, WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);
    WM_INITDIALOG:
      begin
        CreateStatic('VFO A', 5, 5, 45, hwnddlg, 101);
        CreateStatic('VFO B', 5, 30, 45, hwnddlg, 103);

        tWM_SETFONT(CreateStatic(nil, 50, 5, 135, hwnddlg, 102), CATWindowFont);
        tWM_SETFONT(CreateStatic(nil, 50, 30, 135, hwnddlg, 104), CATWindowFont);

        for i := 0 to 3 do
          tWM_SETFONT(CreateStatic(l[i], 5 + i * 45, 55, 45, hwnddlg, 120 + i), MainFixedFont);

//        tWM_SETFONT(GetDlgItem(hwnddlg, 102), CATWindowFont);
//        tWM_SETFONT(GetDlgItem(hwnddlg, 104), CATWindowFont);
//        for i := 120 to 123 do          tWM_SETFONT(GetDlgItem(hwnddlg, i), MainFixedFont);

//        if lParam = tr4w_RADIOINTERFACEWINDOW1_INDEX then p := Radio1AsPchar else p := Radio2AsPchar;
//        Windows.SetWindowText(hwnddlg, p);
      end;

    WM_CLOSE:
      begin
        if hwnddlg = Radio1.tRadioInterfaceWndHandle then
          CloseTR4WWindow(tw_RADIOINTERFACEWINDOW1_INDEX)
        else
          CloseTR4WWindow(tw_RADIOINTERFACEWINDOW2_INDEX);
      end;

    WM_CTLCOLORSTATIC, WM_CTLCOLORDLG:
      begin
        SetBkMode(HDC(wParam), TRANSPARENT);
        if hwnddlg = ActiveRadioPtr.tRadioInterfaceWndHandle then
        begin
          Result := BOOL(tr4wBrushArray[trLightBlue]);
        end;
        if Windows.GetDlgCtrlID(lParam) in [121..123] then
          if Windows.IsWindowEnabled(lParam) then
          begin
            Result := BOOL(tr4wBrushArray[trYellow]);
          end;
      end;
  end;
end;
end.

