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
unit uQuickEdit;

interface
uses TF, VC, uCommctrl, Windows, Messages;

function QuickEditDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation

uses MainUnit;

function QuickEditDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  temprect                              : TRect;
  Offset                                : integer;
  Width                                 : integer;
  h                                     : HWND;
  TempColumn                            : LogColumnsType;
  Align                                 : Cardinal;
begin
  Result := False;
  case Msg of

    WM_CTLCOLOREDIT:
      begin
        SetBkMode(HDC(wParam), TRANSPARENT);
        Result := LongBool(tr4wBrushArray[trYellow]);
      end;

    WM_INITDIALOG:
      begin

        ListView_GetItemRect(wh[mweEditableLog], 1, temprect, 0);
        Offset := temprect.Top;

        Windows.GetWindowRect(wh[mweEditableLog], temprect);

        Windows.SetWindowPos(hwnddlg, HWND_TOPMOST, temprect.Left, temprect.Top + Offset, MainWindowWidth, 10, SWP_SHOWWINDOW);

        Offset := -4;
        for TempColumn := Low(LogColumnsType) to High(LogColumnsType) do
        begin
          if not ColumnsArray[TempColumn].Enable then Continue;
          Width := ListView_GetColumnWidth(wh[mweEditableLog], ColumnsArray[TempColumn].pos);
          ListView_GetItemText(wh[mweEditableLog], 1, ColumnsArray[TempColumn].pos, @TempBuffer1, SizeOf(TempBuffer1));
          Align := ES_LEFT;
          if ColumnsArray[TempColumn].Align = LVCFMT_CENTER then Align := ES_CENTER;
          if ColumnsArray[TempColumn].Align = LVCFMT_RIGHT then Align := ES_RIGHT;

          h := tCreateEditWindow(WS_EX_STATICEDGE, TempBuffer1, Align + WS_TABSTOP + WS_CHILD + WS_VISIBLE, Offset, 0, Width, 21, hwnddlg, 0);
          tWM_SETFONT(h, MainFont);
          Offset := Offset + Width;
        end;

      end;

    WM_COMMAND:
      begin
        if wParam = 2 then goto 1;
//        if HiWord(wParam) = LBN_DBLCLK then ProcessMenu(menu_send_message);
      end;

    WM_CLOSE: 1:
      begin
        EndDialog(hwnddlg, 0);
      end;

  end;
end;

end.

