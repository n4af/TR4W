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
unit uLogCompare;
{$IMPORTEDDATA OFF}
interface

uses
  VC,
  TF,

  PostUnit,
  uCommctrl,
  Windows,
  LogDupe,
  Messages
  ;

function LogCompareDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

var
  LogCompareListView                    : HWND;
  TimeDifference                        : integer;

implementation
uses
  uGetServerLog,
  MainUnit,
  uNet,
  uTelnet;

function LogCompareDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose, setitem;
var
  OpenGetServerLogDlg                   : LongBool;
  s                                     : PLogFileInformation;
  elvi                                  : TLVItem;
  elvc                                  : tagLVCOLUMNA;
 
begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin

        Windows.SetWindowText(hwnddlg, RC_DIFFINLOG);

        LogCompareListView := tWM_SETFONT(CreateListView2(0, 0, 440, 150, hwnddlg), MainFixedFont);

        CreateButton(0, RC_SYNCHRONIZE, 55, 160, 160, hwnddlg, 1);
        CreateButton(0, RC_CLEARALLLOGS, 55, 190, 160, hwnddlg, 103);
        CreateButton(0, EXIT_WORD, 220, 160, 160, hwnddlg, 2);

        SendMessage(hwnddlg, WM_SETICON, ICON_SMALL, LoadIcon(0, IDI_WARNING));
        if not OpenLogFile then Exit;
//        b := Windows.GetFileInformationByHandle(LogHandle, c);
        CloseLogFile;

        s := PLogFileInformation(lParam);
        LogCompareListView := Get101Window(hwnddlg);
        asm
        mov edx,[MainFixedFont]
        call tWM_SETFONT
        end;
        ListView_SetExtendedListViewStyle(LogCompareListView, LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT);

        elvc.Mask := LVCF_TEXT or LVCF_WIDTH or LVCF_FMT;

        elvc.fmt := LVCFMT_CENTER;
        elvc.pszText := nil;
        elvc.cx := 130;
        ListView_InsertColumn(LogCompareListView, 0, elvc);

        elvc.pszText := TC_SERVERLOG;
        elvc.cx := 150;
        ListView_InsertColumn(LogCompareListView, 1, elvc);

        elvc.pszText := TC_LOCALLOG;
        elvc.cx := 150;
        ListView_InsertColumn(LogCompareListView, 2, elvc);

        elvi.Mask := LVIF_TEXT {+ LVIF_STATE};
{        if s^.liServerLogSize <> s^.liLocalLogSize then
          elvi.State := LVIS_SELECTED + LVIS_DROPHILITED
        else}
//        elvi.State := LVIS_SELECTED;

        elvi.iItem := 0;
        elvi.iSubItem := 0;
        elvi.pszText := TC_SIZEBYTES;
        ListView_InsertItem(LogCompareListView, elvi);

        elvi.iSubItem := 1;
        elvi.pszText := inttopchar(s^.liServerLogSize);
        asm call setitem
        end;

        elvi.iSubItem := 2;
        elvi.pszText := inttopchar(s^.liLocalLogSize);
        asm call setitem
        end;

        //----------------------------------------------------

        elvi.iItem := 1;
        elvi.iSubItem := 0;
        elvi.pszText := TC_RECORDS;
        ListView_InsertItem(LogCompareListView, elvi);

        elvi.iSubItem := 1;

//        I := s^.liServerLogSize - s^.liLocalLogSize;

        elvi.pszText := inttopchar(s^.liServerLogSize div SizeOf(ContestExchange) - 1);
        asm call setitem
        end;

        elvi.iSubItem := 2;
        elvi.pszText := inttopchar(s^.liLocalLogSize div SizeOf(ContestExchange) - 1);
        asm call setitem
        end;

        //----------------------------------------------------
{
        if s^.liSeverCRC32 <> s^.liLocalCRC32 then
          elvi.State := LVIS_SELECTED + LVIS_DROPHILITED
        else
          elvi.State := LVIS_SELECTED;
}
        elvi.iItem := 2;
        elvi.iSubItem := 0;
        elvi.pszText := 'CRC32';
        ListView_InsertItem(LogCompareListView, elvi);

        elvi.iSubItem := 1;
        elvi.pszText := inttopcharHEX(integer(s^.liSeverCRC32));
        asm call setitem
        end;

        elvi.iSubItem := 2;
        elvi.pszText := inttopcharHEX(integer(s^.liLocalCRC32));
        asm call setitem
        end;

        //----------------------------------------------------
{
        elvi.iItem := 3;
        elvi.iSubItem := 0;
        elvi.pszText := TC_MODIFIED;
        ListView_InsertItem(LogCompareListView, elvi);

        elvi.iSubItem := 1;
        Windows.FileTimeToSystemTime(s^.liInformation.ftLastWriteTime, St);
        elvi.pszText := SystemTimeToString(St);
        asm call setitem
        end;

        elvi.iSubItem := 2;
        Windows.FileTimeToSystemTime(c.ftLastWriteTime, St);
        elvi.pszText := SystemTimeToString(St);
        asm call setitem
        end;
}
        //----------------------------------------------------
{
        elvi.iItem := 3;
        elvi.iSubItem := 0;
        elvi.pszText := TC_TIMEDIFF;
        ListView_InsertItem(LogCompareListView, elvi);

        elvi.iSubItem := 2;
        if TimeDifference > 0 then p := '+' else p := '-';
        if TimeDifference = 0 then p := nil;
        TimeDifference := Abs(TimeDifference);
        Min := TimeDifference div 60;
        Sec := TimeDifference mod 60;
        asm
                push sec
                push min
                push p
        end;
        wsprintf(wsprintfBuffer, '%s %.2hd' + TC_M + ' %.2hd' + TC_S);
        asm add esp,20
        end;
        elvi.pszText := wsprintfBuffer;
        asm call setitem
        end;
}
        //----------------------------------------------------
{
        if tUSQ <> 0 then
          elvi.State := LVIS_SELECTED + LVIS_DROPHILITED
        else
          elvi.State := LVIS_SELECTED;
}
        elvi.iItem := 3;
        elvi.iSubItem := 0;
        elvi.pszText := 'USQ';
        ListView_InsertItem(LogCompareListView, elvi);

        elvi.iSubItem := 2;
        elvi.pszText := inttopchar(tUSQ);
        asm call setitem end;
        //----------------------------------------------------
{
        if tUSQE <> 0 then
          elvi.State := LVIS_SELECTED + LVIS_DROPHILITED
        else
          elvi.State := LVIS_SELECTED;
}
        elvi.iItem := 4;
        elvi.iSubItem := 0;
        elvi.pszText := 'USQE';
        ListView_InsertItem(LogCompareListView, elvi);

        elvi.iSubItem := 2;
        elvi.pszText := inttopchar(tUSQE);
        asm call setitem end;
        //----------------------------------------------------
{
        if s^.liContest <> Contest then
          elvi.State := LVIS_SELECTED + LVIS_DROPHILITED
        else
          elvi.State := LVIS_SELECTED;
}
        elvi.iItem := 5;
        elvi.iSubItem := 0;
        elvi.pszText := 'Contest';
        ListView_InsertItem(LogCompareListView, elvi);

        elvi.iSubItem := 1;
        elvi.pszText := ContestTypeSA[s^.liContest];
        asm call setitem
        end;

        elvi.iSubItem := 2;
        elvi.pszText := ContestTypeSA[Contest];
        asm call setitem
        end;

        DifferentContests := s^.liContest <> Contest;
        if s^.liContest = DUMMYCONTEST then DifferentContests := False;
        if DifferentContests then EnableWindowFalse(hwnddlg, 1);
        //if DifferentContests then Windows.PostMessage(tr4w_WindowsArray[tw_NETWINDOW_INDEX].WndHandle, WM_CLOSE, 0, 0);
        Exit;

        setitem:
        ListView_SetItem(LogCompareListView, elvi);
        asm ret
        end;
        OpenGetServerLogDlg := False;
      end;

//    WM_HELP: tWinHelp(48);

    WM_COMMAND:

      case wParam of
        1:
          begin
            OpenGetServerLogDlg := True;
            goto ExitAndClose;
          end;

        2:
          begin
            goto ExitAndClose;
          end;

        103:
          begin
            ProcessMenu(menu_clearserverlog);
            goto ExitAndClose;
          end;

      end;

    WM_CLOSE:
      begin
        ExitAndClose:

        EndDialog(hwnddlg, 0);
        if OpenGetServerLogDlg then tDialogBox(73, @GetServerLogDlgProc);
      end;

  end;

end;

end.

