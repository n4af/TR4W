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
unit uGetServerLog;
{$IMPORTEDDATA OFF}
interface

uses

  TF,
  VC,
  utils_net,
  WinSock2,
  utils_file,
  uCommctrl,
  Windows,
  Messages,
  LogStuff,
  LogWind,
  uNet,
  LogDupe,
  Tree
  ;
procedure ReplaceLogByServerLog(Replace: boolean);
function GetServerLogDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure RunSyncThread;

var

  NewServerLogHandle                    : HWND;
  AmountQSOsFromServer                  : Cardinal;
  GetServerLogWnd                       : HWND;
  SynQSOTotalArray                      : QSOTotalArray;
  SyncMode                              : boolean;
  ServerLogListView                     : HWND;
  LogSyncThreadID                       : Cardinal;
  showresverlogcontent                  : boolean = True;

implementation
uses MainUnit;

function GetServerLogDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label CloseLabel;

begin
  Result := False;
  case Msg of

    WM_INITDIALOG:
      begin
        AmountQSOsFromServer := 0;
        GetServerLogWnd := hwnddlg;
        Windows.ZeroMemory(@SynQSOTotalArray, SizeOf(SynQSOTotalArray));
        ServerLogListView := CreateEditableLog(hwnddlg, 1, 60, 770, 330, True);
        Windows.SendDlgItemMessage(hwnddlg, 110, BM_SETCHECK, integer(showresverlogcontent), 0);
      end;
    WM_COMMAND:
      begin
        case LoWord(wParam) of
          102:
            begin
              SyncMode := True;
              EnableWindowFalse(hwnddlg, 102);
              NewServerLogHandle := CreateFile(TR4W_SYN_FILENAME, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);
              if NewServerLogHandle = INVALID_HANDLE_VALUE then goto CloseLabel;
              if LogSyncThreadID = 0 then tCreateThread(@RunSyncThread, LogSyncThreadID);
            end;
          103: goto CloseLabel;
          104: ShowHelp('rulogsynchronize');
          107:
            begin
              ReplaceLogByServerLog(True);
              goto CloseLabel;
            end;

          110: showresverlogcontent := boolean(TF.SendDlgItemMessage(hwnddlg, 110, BM_GETCHECK));
        end;
      end;
    WM_CLOSE: CloseLabel:
      begin

        if NewServerLogHandle <> INVALID_HANDLE_VALUE then
          CloseHandle(NewServerLogHandle);
        EndDialog(hwnddlg, 0);
      end;

  end;

end;

procedure ReplaceLogByServerLog(Replace: boolean);
var
  counter                               : Cardinal;
begin
  for counter := 1 to 1000 do
  begin
    Format(TempBuffer2, '%sLOGBACKUP_%03d.TRW', TR4W_LOG_PATH_NAME, counter);
    if Windows.CopyFile(TR4W_LOG_FILENAME, TempBuffer2, True) = True then
    begin
      Format(TempBuffer2, '%sRSTBACKUP_%03d.RST', TR4W_LOG_PATH_NAME, counter);
      Windows.CopyFile(TR4W_RST_FILENAME, TempBuffer2, False);
      Break;
    end;
  end;
  if Replace then
  begin
    Windows.CopyFile(TR4W_SYN_FILENAME, TR4W_LOG_FILENAME, False);
    LoadinLog;
  end;
  SendStationStatus(sstQSOs);
end;

procedure RunSyncThread;
label
  e, 1, 2;
var
  i                                     : integer;
  TotalBytes, TotalRecords, TotalQ      : integer;
  lpNumberOfBytesWritten                : Cardinal;
  TempRXData                            : ContestExchange;
  IndexInServerLogListView              : integer;
  tGetNetLogEvent                       : HWND;
  FirstPacket                           : boolean;
  Offset                                : integer;
  LogSize                               : integer;
begin

  CommitChangesInLocalLog;

  FirstPacket := True;

  if not GetConnection(LogSyncSocket, @ServerAddress[1], ServerPort + 1, SOCK_STREAM) then goto e;
{
  LogSyncSocket :=GetSocket;// socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  tr4w_saddr.sin_addr.S_addr := inet_addr(tgethostbyname(@ServerAddress[1]));
  tr4w_saddr.sin_port := htons(ServerPort + 1);
  if LogSyncSocket = INVALID_SOCKET then goto e;
  if tConnect(LogSyncSocket, @tr4w_saddr) <> 0 then goto e;
}
  WinSock2.Send(LogSyncSocket, ServerPassword[1], 10, 0);
  //  Sleep(100);
  TotalBytes := 0;
  TotalRecords := 0;
  TotalQ := 0;
  tGetNetLogEvent := WSACreateEvent;
  WinSock2.WSAEventSelect(LogSyncSocket, tGetNetLogEvent, FD_READ or FD_CLOSE);

  1:
  i := WSAWaitForMultipleEvents(1, @tGetNetLogEvent, False, 2000, True);
  if i = 0 then
  begin

    i := recv(LogSyncSocket, SyncNetBuffer, SizeOf(SyncNetBuffer), 0);
    if i > 0 then
    begin
      Offset := 0;
      if FirstPacket then
      begin
        Offset := SizeOf(Cardinal);
        FirstPacket := False;
        LogSize := PInteger(@SyncNetBuffer)^;
      end;
      sWriteFile(NewServerLogHandle, SyncNetBuffer[Offset], i - Offset);
      TotalBytes := TotalBytes + i - Offset;
      tSetDlgItemIntFalse(GetServerLogWnd, 108, TotalBytes);
    end;
    if i <> 0 then
      goto 1;
  end;
  WSACloseEvent(tGetNetLogEvent);
  closesocket(LogSyncSocket);

  if TotalBytes > SizeOfTLogHeader then
  begin
    if (LogSize <> TotalBytes) or ((TotalBytes - SizeOfTLogHeader) mod SizeOf(ContestExchange) <> 0) then
    begin
      showwarning(TC_FAILEDTORECEIVESERVERLOG);
      goto e;
    end;
    if showresverlogcontent then
      SendMessage(ServerLogListView, LVM_SETITEMCOUNT, TotalBytes div SizeOf(ContestExchange), 0);
    Windows.SetFilePointer(NewServerLogHandle, SizeOfTLogHeader, nil, FILE_BEGIN);

    IndexInServerLogListView := 0;
    tSetWindowRedraw(ServerLogListView, False);
    2:
    Windows.ReadFile(NewServerLogHandle, TempRXData, SizeOf(ContestExchange), lpNumberOfBytesWritten, nil);
    if lpNumberOfBytesWritten = SizeOf(ContestExchange) then
    begin
      inc(TotalRecords);
      if ((TempRXData.Band <> NoBand) and
        (TempRXData.Mode <> NoMode) and
        (not TempRXData.ceQSO_Deleted)) and
        (TempRXData.ceQSO_Skiped = False) then inc(TotalQ);

      if TotalRecords mod 10 = 0 then
        tSetDlgItemIntFalse(GetServerLogWnd, 101, TotalRecords);
      if showresverlogcontent then
        tAddContestExchangeToLog(TempRXData, ServerLogListView, IndexInServerLogListView);
      goto 2;
    end;
    tSetWindowRedraw(ServerLogListView, True);
  end;
  tSetDlgItemIntFalse(GetServerLogWnd, 101, TotalRecords);
  tSetDlgItemIntFalse(GetServerLogWnd, 109, TotalQ);
  if TotalQ > 0 then EnableWindowTrue(GetServerLogWnd, 107);
  e:
  LogSyncThreadID := 0;
end;

end.

