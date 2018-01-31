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
unit uLogEdit;
{$IMPORTEDDATA OFF}
interface
uses
  TF,
  VC,
  uEditQSO,
  Windows,
  LogDupe,
  Tree,
  uCommctrl,
  PostUnit,
  Messages;
function LogEditDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure EditFullLog;
var
  LogEditListView                       : HWND;
  FullLogEditHandle                     : HWND;
  FullLogEditIndex                      : integer;
implementation
uses MainUnit;
function LogEditDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1, 2;
var
  i                                     : integer;
  CurrentRecord                         : integer;
begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin
        FullLogEditHandle := hwnddlg;
        Windows.SetWindowText(hwnddlg, RC_VIEWEDITLOG2);
        LogEditListView := CreateEditableLog(hwnddlg, 0, 0, 790, 420, True);
        i := 0;
        //        if not Tree.tOpenFileForRead(h, TR4W_LOG_FILENAME) then Exit;
        if not OpenLogFile then Exit;
        CurrentRecord := 0;
        ReadVersionBlock;
        2:
        if ReadLogFile then
        begin
          tAddContestExchangeToLog(TempRXData, LogEditListView, i);
          inc(CurrentRecord);
          goto 2;
        end;
        CloseLogFile;
        EnsureListViewColumnVisible(LogEditListView);
        Windows.SetFocus(LogEditListView);
        ListView_SetItemState(LogEditListView, 0, LVIS_FOCUSED or LVIS_SELECTED, LVIS_FOCUSED or LVIS_SELECTED);
        //            RegisterHotKey(hwnddlg, 1, 0, VK_RETURN);
      end;
    WM_COMMAND:
      begin
        if lParam = 0 then if LoWord(wParam) = 1 then EditFullLog;
        case wParam of
          2: goto 1;
        end;
      end;
    WM_CLOSE: 1:
      begin
        FullLogEditHandle := 0;
        EndDialog(hwnddlg, 0);
      end;
    WM_NOTIFY:
      begin
        with PNMHdr(lParam)^ do
          case code of
            NM_DBLCLK: EditFullLog;
          end;
      end;
  end;
end;
procedure EditFullLog;
begin
  FullLogEditIndex := ListView_GetNextItem(LogEditListView, -1, LVNI_SELECTED);
  if FullLogEditIndex = -1 then Exit;
  IndexOfItemInLogForEdit := FullLogEditIndex * SizeOf(ContestExchange) + SizeOfTLogHeader;
  OpenEditQSOWindow(FullLogEditHandle);
end;
end.
