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
unit uRemMults_DX;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  LogEdit,
  uGradient,
  Country9,
  LogDom,
  LogDupe,
  Messages;

function RemainingMultsDXDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  RemainingMultsDXWindowHandle: HWND;

implementation
uses MainUnit;

function RemainingMultsDXDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  p                           : PChar;
  DS                          : PDrawItemStruct;
  I                           : integer;
  Index                       : integer;
begin
  RESULT := False;
  case Msg of
    WM_SIZE, WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);
    WM_DRAWITEM:
      begin
        DS := PDrawItemStruct(lParam);

        if (DS^.itemAction = ODA_FOCUS) then
        begin
          DrawFocusRect(DS^.HDC, DS^.rcItem);
          Exit;
        end;

        Index := SendMessage(DS^.hwndItem, LB_GETITEMDATA, DS^.ItemID, 0);
        p := CountryTable.RemainingDXMultTemplate^[Index];
        I := Windows.lstrlen(p);
        if RemainingMultDisplayMode = HiLight then

          if not RemainingMultsDX^[Index] then
          begin
            Windows.SetTextColor(DS^.HDC, tr4wColorsArray[trWhite {ColorColors.RemainingMultsWindowSubdue}]);
            GradientRect(DS^.HDC, DS^.rcItem, tr4wColorsArray[trBlue {ColorColors.RemainingMultsWindowSubdue}], tr4wColorsArray[trWhite {ColorColors.RemainingMultsWindowBackground}], gdHorizontal);
          end
          else
          begin
            Windows.SetTextColor(DS^.HDC, tr4wColorsArray[trBlack {ColorColors.RemainingMultsWindowColor}]);
          end;

        SetBkMode(DS^.HDC, TRANSPARENT);
        Windows.TextOut(DS^.HDC, DS^.rcItem.Left + 2, DS^.rcItem.Top, p, I);

      end;

    WM_INITDIALOG:
      begin
        RemainingMultsDXWindowHandle := GetDlgItem(hwnddlg, 101);
        asm
        mov edx,[MainFixedFont]
       call tWM_SETFONT
        end;
        tLB_SETCOLUMNWIDTH(hwnddlg, 40);
        tr4w_WindowsArray[tw_STATIONS_RM_DX].WndHandle := hwnddlg;
        VisibleLog.ShowRemainingMultipliers;
      end;

    WM_CLOSE: CloseTR4WWindow(tw_STATIONS_RM_DX);

  end;
end;
end.

