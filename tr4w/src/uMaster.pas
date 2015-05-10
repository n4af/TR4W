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
unit uMaster;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  PostUnit,
  Windows,
  LogEdit,
  LogWind,
  uGradient,
  LogStuff,
  Messages;

function MasterDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure ClearMasterListBox;

var
  MasterListBox                         : HWND;
  masterrect                            : TRect;

  MaxItemsInMasterListBox               : integer;
  ItemsInMasterListBox                  : integer;

const
  OneMasterItemWidtht                   = 80;
  OneMasterItemHeight                   = 16;

implementation
uses MainUnit;

function MasterDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  CallsBuf                              : array[0..15] of Char;
  MDIS                                  : PDrawItemStruct;
  i                                     : integer;
  TempColor                             : tr4wColors;
begin
  Result := False;
  case Msg of

    WM_SIZE, WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE:
      begin
        DefTR4WProc(Msg, lParam, hwnddlg);
        Windows.GetWindowRect(MasterListBox, masterrect);
//        MaxItemsInMasterListBox := (((masterrect.Right - masterrect.Left) * (masterrect.Bottom - masterrect.Top)) div OneMasterItemWeight) - 0;
        MaxItemsInMasterListBox :=
          (((masterrect.Right - masterrect.Left) div OneMasterItemWidtht) - 0)
          *
          ((masterrect.Bottom - masterrect.Top) div OneMasterItemHeight)
          ;
        asm
        nop
        end;
      end;

//    WM_CTLCOLORLISTBOX: RESULT := BOOL(tr4wBrushArray[SCPDupeBackground]);

    WM_DRAWITEM:

      begin
        MDIS := Pointer(lParam);
        if (MDIS^.itemAction = ODA_FOCUS) then
        begin
          DrawFocusRect(MDIS^.HDC, MDIS^.rcItem);
          Exit;
        end;

        if MDIS^.itemAction = ODA_DRAWENTIRE then
        begin
          i := SendMessage(MDIS^.hwndItem, LB_GETTEXT, MDIS^.ItemID, integer(@CallsBuf));

          if SendMessage(MDIS^.hwndItem, LB_GETITEMDATA, MDIS^.ItemID, 0) = 1 then
          begin
            TempColor := trWhite;
            GradientRect(MDIS^.HDC, MDIS^.rcItem, tr4wColorsArray[SCPDupeColor], tr4wColorsArray[trWhite {SCPDupeBackground}], gdHorizontal);
          end
          else
          begin
            TempColor := trBlack;
          end;

          Windows.SetTextColor(MDIS^.HDC, tr4wColorsArray[TempColor]);
          SetBkMode(MDIS^.HDC, TRANSPARENT);
          Windows.TextOut(MDIS^.HDC, MDIS^.rcItem.Left + 2, MDIS^.rcItem.Top, CallsBuf, i);
          Result := True;
        end;
      end;

    WM_INITDIALOG:
      begin
        tr4w_WindowsArray[tw_MASTERWINDOW_INDEX].WndHandle := hwnddlg;
        MasterListBox := CreateOwnerDrawListBox(LB_STYLE_2, hwnddlg);
        asm
            mov edx,[MainFixedFont]
            call tWM_SETFONT
        end;
        tLB_SETCOLUMNWIDTH(hwnddlg, 80);
        if SCPMinimumLetters = 0 then SCPMinimumLetters := 3;
//        Windows.SendMessage(MasterListBox, LB_GETITEMRECT, 0, integer(@masterrect));
//        OneMasterItemWeight := masterrect.Right * masterrect.Bottom;
      end;

    WM_CLOSE:
      begin
        1:
        MasterListBox := 0;
        CloseTR4WWindow(tw_MASTERWINDOW_INDEX);

      end;

  end;
end;

procedure ClearMasterListBox;
begin
  tLB_RESETCONTENT(MasterListBox);
  ItemsInMasterListBox := 0;
end;

end.

