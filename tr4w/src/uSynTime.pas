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
unit uSynTime;

{$IMPORTEDDATA OFF}

interface

uses
  VC,
  TF,
//  tr4wutils,
utils_net,
  Windows,
  Tree,
  uNet,
  WinSock2,
  Messages,
  SysUtils,
  Registry
  ;

function SynchronizeTimeDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure ShowTime(Control: integer; LocalTime: SYSTEMTIME);
procedure GetServerAnswerOffset;
procedure GetInt64AndSysTimeFromBuffer(BufPtr: Byte; var St: SYSTEMTIME);

procedure ConnectToNTPServer;
procedure CheckNTPAtStartup;

implementation
uses
  MainUnit,
  uTelnet;

var
  st_window_handle                      : HWND;
//  ST_saddr                              : sockaddr_in = (sin_family: AF_INET; sin_port: 31488);
  ST_SOCKET                             : Cardinal = INVALID_SOCKET;
  ST_Buffer                             : array[1..48] of Byte;
  T1                                    : SYSTEMTIME; //����� �������� ������� �������
  T2                                    : SYSTEMTIME; //����� ��������� ������� ��������
  T3                                    : SYSTEMTIME; //����� ������� ������� ��������
  T4                                    : SYSTEMTIME; //����� ��������� ������� ��������
  Offset                                : int64;
  local_time_timer_handle               : HWND;
  NTPThreadID                           : Cardinal;
  NTPStartupThreadID                    : Cardinal;
const
  NTP_SERVER                            = 'pool.ntp.org';

function SynchronizeTimeDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose, ShowCurrentTime;
var
  LocalTime                             : SYSTEMTIME;
  i                                     : integer;
const
  l                                     : array[0..5] of PChar = (RC_NTPSERVER, RC_LOCALTIME, 'PC UTC', 'Server UTC', RC_SERVERANSWER, RC_LOCALOFFSET);
  b                                     : array[0..3] of PChar = (RC_GETOFFSET, RC_SYNCLOCK, RC_TIMESYN, EXIT_WORD);
begin
  Result := False;
  case Msg of

    WM_INITDIALOG:
      begin
        Windows.SetWindowText(hwnddlg, RC_SYNPCTIME);
        for i := 0 to 3 do
          CreateButton(0, b[i], 270, 5 + i * 35, 190, hwnddlg, 200 + i);

        for i := 0 to 5 do
        begin
          CreateStatic(l[i], 5, 5 + i * 23, 100 + 10, hwnddlg, 0);
          CreateEdit(ES_READONLY or ES_CENTER, 120, 5 + i * 23, 140, 20, hwnddlg, 100 + i);
        end;

        CreateStatic(nil, 0, 157, 470, hwnddlg, 106);

        Windows.SetDlgItemText(hwnddlg, 100, NTP_SERVER);

        st_window_handle := hwnddlg;
        Windows.SetTimer(hwnddlg, local_time_timer_handle, 1000, nil);
        if NetSocket = 0 then
          EnableWindowFalse(hwnddlg, 202);
        EnableWindowFalse(hwnddlg, 201);
        goto ShowCurrentTime;
      end;

//    WM_HELP: tWinHelp(48);

{$IF LANG = 'RUS'}
    WM_HELP: ShowHelp('ru_synchronizepctime');
{$IFEND}

    WM_TIMER:
      begin
        ShowCurrentTime:
        Windows.GetLocalTime(LocalTime);
        ShowTime(101, LocalTime);
      end;

    WM_SOCK_SYNC_TIME:
      begin
        Windows.GetSystemTime(T4);
        if recv(ST_SOCKET, ST_Buffer, 48, 0) <> 48 then Exit;
        GetServerAnswerOffset;
        GetInt64AndSysTimeFromBuffer(41, T3); ////����� ������� ������� ��������
        GetInt64AndSysTimeFromBuffer(41 - 8, T2);
        ShowTime(103, T3); //server
        ShowTime(102, T4); //local

        //t = ((T2 - T1) + (T3 - T4)) / 2.
        Offset := round((STToInt64(T2) - STToInt64(T1) + STToInt64(T3) - STToInt64(T4)) / 2);

        Format(wsprintfBuffer, '%d ' + TC_MS, integer(Offset));
        SetDlgItemText(hwnddlg, 105, wsprintfBuffer);

//        TR4W_WM_SetTest(hwnddlg, 123, _StrInt64(Offset, 1) + TC_MS);

        EnableWindowTrue(hwnddlg, 201);
      end;
    WM_COMMAND:
      begin

        case wParam of
          201:
            begin
              Windows.GetSystemTime(T2);
              IncSystemTime(T2, Offset);
              if not Windows.SetSystemTime(T2) then
              begin
                SetDlgItemText(st_window_handle, 106, PChar(SysErrorMessage(GetLastError)));
              end;
              EnableWindowFalse(hwnddlg, 201);
            end;

          203, 2: goto ExitAndClose;

          200: {Get Time}
            begin
              if NTPThreadID <> 0 then Exit;
              logger.Info('Calling tCreateThread from NTP');
              tCreateThread(@ConnectToNTPServer, NTPThreadID);
              logger.Info('Created NTP thread with threadid of %d',[NTPThreadID] );

            end;

          202: ProcessMenu(menu_alt_setnettime);
        end;

      end;
    WM_CLOSE:
      begin
        ExitAndClose:
        Windows.KillTimer(hwnddlg, local_time_timer_handle);
        closesocket(ST_SOCKET);
        ST_SOCKET := INVALID_SOCKET;
        EndDialog(hwnddlg, 0);
      end;

  end;

end;

procedure ShowTime(Control: integer; LocalTime: SYSTEMTIME);
begin
  SetDlgItemText(st_window_handle, Control, TF.SystemTimeToString(LocalTime));
end;

procedure GetServerAnswerOffset;
begin
//  TR4W_WM_SetTest(st_window_handle, 122, IntToStr(STToInt64(T4) - STToInt64(T1)) + TC_MS);
  Format(wsprintfBuffer, '%d ' + TC_MS, integer(STToInt64(T4) - STToInt64(T1)));
  SetDlgItemText(st_window_handle, 104, wsprintfBuffer);
end;

procedure GetInt64AndSysTimeFromBuffer(BufPtr: Byte; var St: SYSTEMTIME);
const
  t                                     = {4311810304;} $0101010101;
var

  TEMPFILETIME                          : FILETIME;
  t64                                   : int64;
  Sec                                   : int64;
  msec                                  : int64;
begin

  Sec := int64(ST_Buffer[BufPtr + 3])
    + int64(ST_Buffer[BufPtr + 2]) * 256
    + int64(ST_Buffer[BufPtr + 1]) * 256 * 256
    + int64(ST_Buffer[BufPtr]) * 256 * 256 * 256;

  msec :=
    int64(ST_Buffer[BufPtr + 7]) +
    int64(ST_Buffer[BufPtr + 6]) * 256 +
    int64(ST_Buffer[BufPtr + 5]) * 256 * 256 +
    int64(ST_Buffer[BufPtr + 4]) * 256 * 256 * 256;

  msec := round((msec / t) * 1000);

  t64 := (msec + Sec * 1000) * 10000 + 9435484800 * 10000000;
  TEMPFILETIME := FILETIME(t64);
  Windows.FileTimeToSystemTime(TEMPFILETIME, St);

  //9435484800-���-�� ������ ����� 1.1.1900 � 1.1.1601

end;

procedure ConnectToNTPServer;
label
  1, Unsuccessful;
var
  i                                     : integer;
  p                                     : string;
begin

  EnableWindowFalse(st_window_handle, 201);
  for i := 102 to 106 do Windows.SetDlgItemText(st_window_handle, i, nil);
  Windows.ZeroMemory(@ST_Buffer, SizeOf(ST_Buffer));
  ST_Buffer[1] := 27;
  if ST_SOCKET = INVALID_SOCKET then
  begin

//    InitiatesUseOfTheWindowsSockets;
//    ST_SOCKET := socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);

    if not GetConnection(ST_SOCKET, NTP_SERVER, 123, SOCK_DGRAM) then goto Unsuccessful;
{
    InitiatesUseOfTheWindowsSockets;

    ST_SOCKET := socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
    ST_saddr.sin_addr.S_addr := inet_addr(tgethostbyname(TempBuffer1));
    if ST_saddr.sin_addr.S_addr = INADDR_NONE then goto Unsuccessful;

    if ST_SOCKET = INVALID_SOCKET then goto Unsuccessful;
    if tConnect(ST_SOCKET, @ST_saddr) <> 0 then goto Unsuccessful;
}
    if WinSock2.WSAAsyncSelect(ST_SOCKET, st_window_handle, WM_SOCK_SYNC_TIME, FD_READ or FD_CLOSE or FD_CONNECT) <> 0 then goto Unsuccessful;
  end;
  Windows.GetSystemTime(T1);
  WinSock2.Send(ST_SOCKET, ST_Buffer, 48, 0);
  goto 1;
  Unsuccessful:
  ST_SOCKET := INVALID_SOCKET;
  1:
  p := SysErrorMessage(WSAGetLastError);
  SetDlgItemText(st_window_handle, 106, PChar(p));
  NTPThreadID := 0;
end;

// Returns the NTP server configured for Windows W32Time (from registry),
// falling back to pool.ntp.org if not set.
function GetWindowsNTPServer: string;
var
   reg: TRegistry;
   spacePos: integer;
   commaPos: integer;
begin
   Result := '';
   reg := TRegistry.Create(KEY_READ);
   try
      reg.RootKey := HKEY_LOCAL_MACHINE;
      if reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Services\W32Time\Parameters') then
         begin
         if reg.ValueExists('NtpServer') then
            Result := reg.ReadString('NtpServer');
         reg.CloseKey;
         end;
   finally
      reg.Free;
   end;
   // Multiple servers are space-separated; take the first
   spacePos := Pos(' ', Result);
   if spacePos > 0 then
      Result := Copy(Result, 1, spacePos - 1);
   // Strip flags suffix e.g. "time.windows.com,0x9" -> "time.windows.com"
   commaPos := Pos(',', Result);
   if commaPos > 0 then
      Result := Copy(Result, 1, commaPos - 1);
   if Result = '' then
      Result := NTP_SERVER;
end;

// Background thread proc: queries NTP, warns if clock offset exceeds 2 seconds.
procedure NTPStartupCheck;
const
   SOL_SOCKET_C  = $FFFF;  // from winsock.h — not defined in this project's WinSock2.pas
var
   ntpServer: string;
   sock: TSocket;
   recvBuf: array[1..48] of Byte;
   t1, t4: SYSTEMTIME;
   t2Time, t3Time: SYSTEMTIME;
   offset: int64;
   timeoutMs: DWORD;
   msg: string;
   i: integer;
begin
   // Wait for main window to finish initialising before touching the network.
   // gethostbyname can block for 10-15s on DNS failure; we must not delay startup.
   Sleep(3000);

   ntpServer := GetWindowsNTPServer;
   logger.Info('[NTP] Startup time check against %s', [ntpServer]);

   if not GetConnection(sock, PChar(ntpServer), 123, SOCK_DGRAM) then
      begin
      logger.Warn('[NTP] Could not connect to NTP server %s', [ntpServer]);
      NTPStartupThreadID := 0;
      Exit;
      end;

   // 2-second receive timeout — avoids blocking startup if server is unreachable
   timeoutMs := 2000;
   setsockopt(sock, SOL_SOCKET_C, SO_RCVTIMEO, PChar(@timeoutMs), SizeOf(timeoutMs));

   ZeroMemory(@recvBuf, SizeOf(recvBuf));
   recvBuf[1] := 27;  // LI=0, VN=3, Mode=3 (NTP client request)
   Windows.GetSystemTime(t1);
   WinSock2.Send(sock, recvBuf, 48, 0);

   if recv(sock, recvBuf, 48, 0) <> 48 then
      begin
      logger.Warn('[NTP] No response from %s (timeout or error)', [ntpServer]);
      closesocket(sock);
      NTPStartupThreadID := 0;
      Exit;
      end;
   Windows.GetSystemTime(t4);
   closesocket(sock);

   // Copy into ST_Buffer to reuse existing timestamp parser
   for i := 1 to 48 do
      ST_Buffer[i] := recvBuf[i];
   GetInt64AndSysTimeFromBuffer(33, t2Time);  // T2: server receive timestamp (bytes 33-40)
   GetInt64AndSysTimeFromBuffer(41, t3Time);  // T3: server transmit timestamp (bytes 41-48)

   // NTP offset = ((T2-T1) + (T3-T4)) / 2, in milliseconds
   offset := Round((STToInt64(t2Time) - STToInt64(t1) +
                    STToInt64(t3Time) - STToInt64(t4)) / 2);

   if Abs(offset) > 2000 then
      begin
      logger.Warn('[NTP] Clock offset %d ms from %s - time sync needed', [offset, ntpServer]);
      msg := 'Warning: PC clock is ' + IntToStr(Abs(offset) div 1000) +
             ' seconds off from NTP server (' + ntpServer +
             '). Please synchronize your Windows time.';
      MessageBox(0, PChar(msg), 'TR4W Time Warning',
         MB_OK or MB_ICONWARNING or MB_TOPMOST);
      end
   else
      logger.Info('[NTP] Clock OK: offset=%d ms from %s', [offset, ntpServer]);

   NTPStartupThreadID := 0;
end;

procedure CheckNTPAtStartup;
begin
   logger.Info('[NTP] Scheduling startup NTP time check');
   tCreateThread(@NTPStartupCheck, NTPStartupThreadID);
end;

end.

