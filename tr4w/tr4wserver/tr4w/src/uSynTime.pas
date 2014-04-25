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
  Messages
  ;

function SynchronizeTimeDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure ShowTime(Control: integer; LocalTime: SYSTEMTIME);
procedure GetServerAnswerOffset;
procedure GetInt64AndSysTimeFromBuffer(BufPtr: Byte; var St: SYSTEMTIME);

procedure ConnectToNTPServer;

implementation
uses
  MainUnit,
  uTelnet;

var
  st_window_handle                      : HWND;
//  ST_saddr                              : sockaddr_in = (sin_family: AF_INET; sin_port: 31488);
  ST_SOCKET                             : Cardinal = INVALID_SOCKET;
  ST_Buffer                             : array[1..48] of Byte;
  T1                                    : SYSTEMTIME; //Время отправки запроса клиента
  T2                                    : SYSTEMTIME; //Время получения запроса сервером
  T3                                    : SYSTEMTIME; //Время посылки отклика сервером
  T4                                    : SYSTEMTIME; //Время получения отклика клиентом
  Offset                                : int64;
  local_time_timer_handle               : HWND;
  NTPThreadID                           : Cardinal;
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
        GetInt64AndSysTimeFromBuffer(41, T3); ////Время посылки отклика сервером
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
                SetDlgItemText(st_window_handle, 106, SysErrorMessage(GetLastError));
              end;
              EnableWindowFalse(hwnddlg, 201);
            end;

          203, 2: goto ExitAndClose;

          200: {Get Time}
            begin
              if NTPThreadID <> 0 then Exit;
              tCreateThread(@ConnectToNTPServer, NTPThreadID);

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

  //9435484800-кол-во секунд между 1.1.1900 и 1.1.1601

end;

procedure ConnectToNTPServer;
label
  1, Unsuccessful;
var
  i                                     : integer;
  p                                     : PChar;
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
  SetDlgItemText(st_window_handle, 106, p);
  NTPThreadID := 0;
end;

end.

