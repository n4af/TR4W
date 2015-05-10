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
unit tr4wserverUnit;
{$IMPORTEDDATA OFF}
interface

uses
  Windows,
  WinSock2,
  VC,
  TF,
  uCRC32,
  Messages;
const

  SERVERDEBUG                           = False;

type
  _TRANSMIT_FILE_BUFFERS = record
    Head: Pointer {lpvoid};
    HeadLength: DWORD;
    Tail: Pointer {lpvoid};
    TailLength: DWORD;
  end;

  TRANSMIT_FILE_BUFFERS = _TRANSMIT_FILE_BUFFERS;
  PTRANSMIT_FILE_BUFFERS = ^TRANSMIT_FILE_BUFFERS;
  LPTRANSMIT_FILE_BUFFERS = ^TRANSMIT_FILE_BUFFERS;
  TTransmitFileBuffers = TRANSMIT_FILE_BUFFERS;
  PTransmitFileBuffers = LPTRANSMIT_FILE_BUFFERS;

  TTransmitFile = function
    (
    hSocket: TSocket;
    hFile: HWND;
    nNumberOfBytesToWrite, nNumberOfBytesPerSend: DWORD;
    lpOverlapped: POverlapped;
    lpTransmitBuffers: LPTRANSMIT_FILE_BUFFERS;
    dwReserved: DWORD
    ): BOOL; stdcall;

  TAcceptEx = function
    (
    sListenSocket, sAcceptSocket: TSocket;
    lpOutputBuffer: PChar;
    dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: DWORD;
    var lpdwBytesReceived: DWORD;
    lpOverlapped: POverlapped
    ): BOOL; stdcall;
{
  function AcceptEx(sListenSocket, sAcceptSocket: TSocket; lpOutputBuffer: LPVOID;
  dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: DWORD;
  var lpdwBytesReceived: DWORD; lpOverlapped: POVERLAPPED): BOOL; stdcall;
  }

type
  TServerLogArray = packed record
    slaCID: Byte;
    slaID1: Word;
    slaID2: Cardinal;
    slaAddress: Word;
    slaQSOTime: SYSTEMTIME;
  end;

type
  SocketPtr = ^Cardinal;

//  ServerLogArray = array of ContestExchange;
//  ServerLogArrayPtr = ^ServerLogArray;

type
  TClientEntry = packed record
    clSerialNumber: integer;
    clSocket: Cardinal;
    clIPAdr: array[0..15] of Char;
    clName: array[0..31] of Char;

    clSerialNumberStatus: TSerialNumberType;
    clConnectedToTelnet: boolean;
    clID: Char;
  end;

type
  DebugMessageType =
    (
    dmSpotViaNet,
    dmRX,
    dmTX,
    dmRun,
    dmDisc,
    dmMF,
    dmRXDisc,
    dmQSOInfo,
    dmList,
    dmAccept,
    dmTransmitFile,
    dmLogInfo,
    dmPass,
    dmStationStatus,
    dmDXSpot,
    dmTimeSyn,
    dmParam,
    dmIntercom,
    dmEditQSO,
    dmClearLogs,
    dmClearDupeSheet,
    dmSeverLogChanged,
    dmMessage,
    dmTR4W,
    dmROLQ
    );

const
  DebugMessagesArray                    : array[DebugMessageType] of PChar =
    ('SVN', 'RX ', 'TX ', 'RUN', 'DSC', 'MF ', 'RXD', 'QSO', 'LST', 'ACC', 'TF ', 'LI ', 'PAS', 'SS ', 'DXS', 'TS ', 'PAR', 'INT', 'EQ ', 'CLL', 'CLD', 'SLC', 'MES', 'TR ', 'OLQ');

  _TR4WSERVER                           = 'TR4WSERVER';
  _TR4WSERVERINIFILE                    = 'TR4WSERVER.INI';

  tsIPADDRESS                           = 106;
  tsCLIENTS                             = 110;
  MAXCLIENTS                            = 26;
  FullServerVersion                     = _TR4WSERVER + ' ' + TR4WSERVER_CURRENTVERSION;
  MaxContestExchangesBufferSize         = 30;
//  MAXSERIALNUMBER                       = 20000;
var
//  SerialsNumber                         : array[1..MAXSERIALNUMBER] of TSerialNumberType;

  MSWSOCKLoaded                         : boolean = False;
  sAllowTimeSynchronizing               : boolean = True;
  SerialNumberLockoutEnable             : boolean = False;
//  tGetLogTimeout                        : integer = 50;
  lpdwBytesReceived                     : DWORD;
  ServerMessagePtr                      : TServerMessagePtr;
  ServerMessage                         : TServerMessage = (smID: NET_SERVERMESSAGE_ID);
{
  ServerMF                              : MultsFrequencies =
    (
    (1810000, 3550000, 7040000, 14070000, 21070000, 28070000),
    (0000000, 0000000, 0000000, 00000000, 00000000, 00000000),
    (1890000, 3680000, 7100000, 14110000, 21160000, 28505000)
    );
}
//  NetMF                                 : NetMultsFrequencies = (mfID: NET_MULTSFREQUENCIES_ID);

  Server_TRANSMIT_FILE_BUFFERS          : _TRANSMIT_FILE_BUFFERS;

  TransmitFile                          : TTransmitFile;
//  AcceptEx                              : TAcceptEx;

//  LogArrayPtr                           : ServerLogArray;
  TempCE                                : ContestExchange;

  EditedQSOPtr                          : NetQSOInformationPtr;
  ServerNewQSOPtr                       : NetQSOInformationPtr;
  ServerLogFileInformation              : TLogFileInformation = (liID: NET_LOGCOMPARE_ID);

  SENDTR4W                              : array[0..3] of Char = 'TR4W';
  PASSTR4W                              : array[0..3] of Char = 'PASS';

  ContestExchangesBuffer                : array[1..MaxContestExchangesBufferSize] of ContestExchange;

  ServerSyncMode                        : boolean;
  ServerLogOpened                       : boolean = False;
  ServerDebugMode                       : boolean = False;

  NetSynQSOInformation                  : TNetSynQSOInformation = (qsID: NET_TAKESERVERQSO_ID);

  TempLongBool                          : LongBool;
  CorrectPortNumber                     : LongBool;

  answer                                : array[1..2] of Char;
  ClientsSoocketsArray                  : array[1..MAXCLIENTS] of TClientEntry;
  ServerBuffer                          : array[0..4096 - 1] of Char;
  tr4wServerPassword                    : array[0..010] of Char;
  ServerLogFileName                     : array[0..255] of Char;
{$IF SERVERDEBUG}
  ServerDebugFileName                   : array[0..255] of Char;
{$IFEND}
//  MultsFrequenciesFileName              : array[0..255] of Char;
  DisplayBuffer                         : array[0..063] of Char;

  client_addr                           : sockaddr_in;
  mysaddr                               : sockaddr_in;
  net_mywsadata                         : TWSAData;
  myhostent                             : Phostent;

  hIpAddr                               : HWND;
  ApplicationHandle                     : HWND;
  ServerLogHandle                       : HWND = INVALID_HANDLE_VALUE;
  ServerTempLogHandle                   : HWND = INVALID_HANDLE_VALUE;

  LogArraySize                          : integer;
  ENABLE_TCP_NODELAY                    : integer = 1;
  Bufindex                              : integer;
  net_sock_rx                           : integer = 0;
  net_sock_tx                           : integer = 0;
  nclients                              : integer;
  addrlen                               : integer = SizeOf(sockaddr_in);

  MSWSOCK_DLL                           : Cardinal;
  ServerOS                              : Cardinal;
  PortNumber                            : Cardinal;
  ContestExchangesBufferIndex           : Cardinal = 0;
//  SetPointerEvent                       : Cardinal;
  BytesWritten                          : Cardinal;

  LastDisplayedBytesRCVD                : Cardinal = 0;
  LastDisplayedBytesSEND                : Cardinal = 0;

  BytesRCVD                             : Cardinal = 0;
  BytesSEND                             : Cardinal = 0;

  ServerSocket                          : Cardinal;
  ListenerSocket                        : Cardinal;
  ServerThread                          : Cardinal;
  ServerThreadID                        : Cardinal;
  NewClientThread                       : Cardinal;
  NewClientThreadID                     : Cardinal;
  ThreadID                              : Cardinal;
  SendLogTo                             : Cardinal;
  ServerCRC32                           : Cardinal;
  ServerCRC32Changed                    : boolean = True;
const
  WM_SOCK_NET_RX                        = WM_USER + 131;
  WM_SOCK_NET_ACCEPT                    = WM_USER + 132;
  WM_SOCK_NET_SYNLISTNER                = WM_SOCK_NET_ACCEPT + 1;

//procedure SortServerLog;
//function SortServerLogArrayShell: boolean;

function tUpdateServerLog(UpdAction: UpadateAction): boolean;
procedure SendConfirmMessage(s: TSocket);
procedure SerialNumbersChanged;
procedure UpdateSerialNumbersStatus(s: TSocket; Status: TSerialNumberType);
procedure RunServerThread;
procedure RunServer;
procedure GetServerLogCRC32;
function sSend(s: TSocket; var buf; Len: integer; mt: DebugMessageType): integer;
function sRecv(s: TSocket; var buf; Len: integer): integer;
function ServerMessageBox(Text: PChar; uType: UINT): integer;
procedure ScanLogForSerialsNumbers;
procedure StopServer;
procedure AddSocketToArray(soc: Cardinal; IP: PChar; Name: PChar);
procedure DeleteSocketFromArray(soc: Cardinal);
procedure SendMessageToClients(From: Cardinal; Count: integer; ToAll: boolean; mt: DebugMessageType);
procedure DisplayRCVDBytes;
procedure DisplaySENDBytes;
procedure DisplayClients;
procedure DisplayServerLogSize;
//procedure SetServerIcon(Icon: PChar);
procedure UpdateQSOInServerlog(CE: ContestExchange);
function Load_MSWSOCK: boolean;
function RunSyncListener: boolean;
function TransmitServerLog(s: TSocket): DWORD; stdcall;
function OpenServerLog(dwCreationDistribution: DWORD): boolean;
procedure CloseServerLog;
procedure AddContestExchangeToBuffer(CE: ContestExchange);
procedure WriteContestExchangesBufferToServerLog;
procedure SendLogFileInformation(s: TSocket);
function ClearServerLog: boolean;
procedure WriteToServerDebugFile(Count: Cardinal; s: TSocket; comment: PChar; mt: DebugMessageType);
procedure SendDisconnectMessage(Client: Char);
procedure SetComputerID(ID: Char; s: TSocket);
procedure SetStatus(Status: TClientStatus; s: TSocket);
procedure SendSpotViaNet(Status: TSendSpotViaNetwork; s: TSocket);
function CorrectPassword(s: TSocket; BytesReceived: integer): boolean;
//procedure LoadinMultsFrequencies;
//procedure SaveMultsFrequencies;
//procedure SendMFToClients;

implementation

function RunSyncListener: boolean;
label
  UnSucc;
begin
  Result := False;
  ListenerSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_IP {IPPROTO_TCP});
  if ListenerSocket = INVALID_SOCKET then goto UnSucc;
  mysaddr.sin_family := AF_INET;
  mysaddr.sin_port := htons(PortNumber + 1);
  mysaddr.sin_addr.S_addr := 0;
  if WinSock2.bind(ListenerSocket, @mysaddr, SizeOf(mysaddr)) <> 0 then goto UnSucc;
  if listen(ListenerSocket, maxclients) <> 0 then goto UnSucc;

  WSAAsyncSelect(ListenerSocket, ApplicationHandle, WM_SOCK_NET_SYNLISTNER, FD_ACCEPT);
  Result := True;
  Exit;
  UnSucc:
  ServerMessageBox('Failed to run sync listener', MB_OK or MB_ICONWARNING or MB_TOPMOST);
end;

procedure RunServerThread;
begin
  //  ServerThread := CreateThread(nil, 0, @RunServer, nil, 0, ServerThreadID);
  RunServer;
end;

procedure RunServer;
label
  UnSucc;
begin

  DisplayRCVDBytes;
  DisplaySENDBytes;
  DisplayClients;
//  Windows.ZeroMemory(@ClientsSoocketsArray, SizeOf(ClientsSoocketsArray));
  Gethostname(@ServerBuffer, 128);
  myhostent := WinSock2.gethostbyname(@ServerBuffer);
  Windows.SendDlgItemMessage(ApplicationHandle, tsIPADDRESS, WM_SETTEXT, 0, integer(iNet_ntoa(PInAddr(myhostent^.h_addr_list^)^)));
  ServerSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if ServerSocket = INVALID_SOCKET then Exit;
  mysaddr.sin_family := AF_INET;
  mysaddr.sin_port := htons(PortNumber);
  mysaddr.sin_addr.S_addr := 0;
  if WinSock2.bind(ServerSocket, @mysaddr, SizeOf(mysaddr)) <> 0 then
  begin
    ServerMessageBox(TF.SysErrorMessage(GetLastError), MB_OK or MB_ICONWARNING or MB_TOPMOST);
//    tf.ShowSysErrorMessage('BIND');
    goto UnSucc;
  end;
  if listen(ServerSocket, maxclients) <> 0 then goto UnSucc;
  Windows.EnableWindow(GetDlgItem(ApplicationHandle, 103), False);
  Windows.EnableWindow(GetDlgItem(ApplicationHandle, 104), True);
  WSAAsyncSelect(ServerSocket, ApplicationHandle, WM_SOCK_NET_ACCEPT, FD_ACCEPT);
//  SetServerIcon(IDI_APPLICATION);
//  DisplayClients;
  Exit;
  UnSucc:
  closesocket(ServerSocket);

end;

procedure StopServer;
var
  i                                     : integer;
begin
  for i := 1 to maxclients do if ClientsSoocketsArray[i].clSocket <> 0 then
    begin
      WSAAsyncSelect(ClientsSoocketsArray[i].clSocket, ApplicationHandle, 0, 0);
      closesocket(ClientsSoocketsArray[i].clSocket);
      ClientsSoocketsArray[i].clSocket := 0;
    end;
  WSAAsyncSelect(ServerSocket, ApplicationHandle, 0, 0);
  closesocket(ServerSocket);
  nclients := 0;
end;

procedure SendMessageToClients(From: Cardinal; Count: integer; ToAll: boolean; mt: DebugMessageType);
var
  i                                     : Cardinal;
  I2                                    : integer;
begin
  for i := 1 to maxclients do
    if ClientsSoocketsArray[i].clSocket <> 0 then
    begin
      if ToAll = False then if ClientsSoocketsArray[i].clSocket = From then Continue;
      I2 := sSend(ClientsSoocketsArray[i].clSocket, ServerBuffer[Bufindex], Count, mt);

      Sleep(0);
    end;
end;

procedure AddSocketToArray(soc: Cardinal; IP: PChar; Name: PChar);
var
  i                                     : integer;
begin
  for i := 1 to maxclients do
    if ClientsSoocketsArray[i].clSocket = 0 then
    begin
      Windows.ZeroMemory(@ClientsSoocketsArray[i].clSocket, SizeOf(TClientEntry) - 4); //skip clSerialNumber
      ClientsSoocketsArray[i].clSocket := soc;
      lstrcpy(@ClientsSoocketsArray[i].clIPAdr[0], IP);
      lstrcpy(@ClientsSoocketsArray[i].clName[0], Name);
      if Name = nil then ClientsSoocketsArray[i].clName[0] := '?';
      inc(nclients);
      Break;
    end;
end;

procedure DeleteSocketFromArray(soc: Cardinal);
var
  b                                     : Byte;
begin
  for b := 1 to maxclients do
    if ClientsSoocketsArray[b].clSocket = soc then
    begin
      ClientsSoocketsArray[b].clSocket := 0;
      SendDisconnectMessage(ClientsSoocketsArray[b].clID);
      dec(nclients);
      Break;
    end;
end;

procedure DisplayRCVDBytes;
begin
  if (BytesRCVD - LastDisplayedBytesRCVD) < 1024 then Exit;
  SetDlgItemInt(ApplicationHandle, 108, BytesRCVD div 1024, False);
  LastDisplayedBytesRCVD := BytesRCVD
end;

procedure DisplaySENDBytes;
begin
  if (BytesSEND - LastDisplayedBytesSEND) < 1024 then Exit;
  SetDlgItemInt(ApplicationHandle, 112, BytesSEND div 1024, False);
  LastDisplayedBytesSEND := BytesSEND;
end;

procedure DisplayClients;
var
  i                                     : integer;
  s1, s2                                : PChar;
begin
  Windows.SendDlgItemMessage(ApplicationHandle, 109, LB_RESETCONTENT, 0, 0);
  for i := 1 to maxclients do
    if ClientsSoocketsArray[i].clSocket <> 0 then
    begin
      Format(DisplayBuffer, '%s: %s', ClientsSoocketsArray[i].clIPAdr, ClientsSoocketsArray[i].clName);
      Windows.SendDlgItemMessage(ApplicationHandle, 109, LB_ADDSTRING, 0, integer(@DisplayBuffer));
    end;

  Format(DisplayBuffer, 'TR4WSERVER [%d]', nclients);
  Windows.SetWindowText(ApplicationHandle, DisplayBuffer);
  Windows.SetDlgItemInt(ApplicationHandle, tsCLIENTS, nclients, False);
end;

procedure DisplayServerLogSize;
begin
  ServerCRC32Changed := True;
  SetDlgItemInt(ApplicationHandle, 115, (Windows.GetFileSize(ServerLogHandle, nil) - 4) div SizeOf(ContestExchange), False);
end;
{
procedure SetServerIcon(Icon: PChar);
begin
  SendMessage(ApplicationHandle, WM_SETICON, ICON_SMALL, LoadIcon(0, Icon));
end;
}
{
procedure CreateServerLog;
var
   I, i2                           : Cardinal;
begin

      begin
         for I := 1 to maxclients do
            if ClientsSoocketsArray[I].clSocket <> 0 then
               begin
                  i2 := Send(ClientsSoocketsArray[I].clSocket, SYNCMESSAGE, SizeOf(SYNCMESSAGE), 0);
                  BytesSEND := BytesSEND + i2;
               end;

      end;
end;
}

{
procedure SendServerLog ;
label
  1, 2;
var
  pNumberOfBytesRead               : Cardinal;
  i2, FilePointer                  : integer;
  wc                               : Cardinal;
  syst                             : SYSTEMTIME;
  QSO                              : integer;
begin
  Windows.GetSystemTime(syst);
  //   Windows.SetWindowText(ApplicationHandle, PChar(IntToStr(SendLogTo)));
     //   SetFilePointer(ServerLogHandle, 4, nil, FILE_BEGIN);
  FilePointer := 0;
  QSO := 0;
  NetSynQSOInformation.qsRes1 := 0;

  1:
  ResetEvent(SetPointerEvent);
  SetFilePointer(ServerLogHandle, 4 + FilePointer * SizeOf(ContestExchange), nil, FILE_BEGIN);
  Windows.ReadFile(ServerLogHandle, NetSynQSOInformation.qsInformation, SizeOf(ContestExchange), pNumberOfBytesRead, nil);
  SetEvent(SetPointerEvent);
  if pNumberOfBytesRead = SizeOf(ContestExchange) then
    begin
      inc(FilePointer);
      if Abs(syst.wDay - NetSynQSOInformation.qsInformation.tSysTime.wDay) > 3 then goto 1;
      if syst.wMonth <> NetSynQSOInformation.qsInformation.tSysTime.wMonth then goto 1;
      if syst.wYear <> NetSynQSOInformation.qsInformation.tSysTime.wYear then goto 1;
      2:
      if AllowNextPacket then
        begin
          AllowNextPacket := False;
          i2 := WinSock2.Send(SendLogTo , NetSynQSOInformation, SizeOf(NetSynQSOInformation), 0);
          BytesSEND := BytesSEND + i2;
          Sleep(0);
          inc(QSO);
          ws := 0;
        end
      else
        begin
          inc(ws);
          Sleep(0);
          if ws < 1000000 then goto 2
          else
            begin
              AllowNextPacket := True;
              goto 2;
            end;
        end;

      if FilePointer mod 32 = 0 then DisplaySENDBytes;

      goto 1;
    end;
  NetSynQSOInformation.qsRes1 := 1;

  NetSynQSOInformation.qsInformation.TenTenNum := QSO * SizeOf(ContestExchange) + 4;
  i2 := WinSock2.Send(SendLogTo , NetSynQSOInformation, SizeOf(NetSynQSOInformation), 0);
  BytesSEND := BytesSEND + i2;
  DisplaySENDBytes;
  ServerSyncMode := False;
  SetEvent(SetPointerEvent);
end;
}

procedure UpdateQSOInServerlog(CE: ContestExchange);
label
  1, 2;
var
  pNumberOfBytesRead                    : Cardinal;
  FilePointer                           : integer;

begin
  FilePointer := -1;
  if OpenServerLog(OPEN_EXISTING) then
  begin
    1:
    SetFilePointer(ServerLogHandle, FilePointer * SizeOf(ContestExchange), nil, FILE_END);
    Windows.ReadFile(ServerLogHandle, TempCE, SizeOf(ContestExchange), pNumberOfBytesRead, nil);
    if pNumberOfBytesRead = SizeOf(ContestExchange) then
    begin
      if TempCE.ceQSOID1 = CE.ceQSOID1 then
        if TempCE.ceQSOID2 = CE.ceQSOID2 then
        begin
          SetFilePointer(ServerLogHandle, FilePointer * SizeOf(ContestExchange), nil, FILE_END);
          WriteFile(ServerLogHandle, CE, SizeOf(ContestExchange), pNumberOfBytesRead, nil);
          ServerCRC32Changed := True;
          goto 2;
        end;
      dec(FilePointer);
      goto 1;
    end;
    2:
    CloseServerLog;
  end;
end;
{
procedure SortServerLog;
label
  1, 3;
var
  pNumberOfBytesRead                    : Cardinal;
  dwSize                                : integer;
  MapFin                                : Cardinal;
  MapBase                               : Pointer;
begin

  dwSize := Windows.GetFileSize(ServerLogHandle, nil) - SizeOfTLogHeader;
  if dwSize <= SizeOfTLogHeader + SizeOf(ContestExchange) then Exit;
  LogArraySize := dwSize div SizeOf(ContestExchange);

  MapFin := Windows.CreateFileMapping(ServerLogHandle, nil, PAGE_READWRITE, 0, 0, nil);
  if MapFin = 0 then Exit;

  MapBase := Windows.MapViewOfFile(MapFin, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if MapBase = nil then goto 3;

  asm
     add eax,SizeOfTLogHeader
     mov LogArrayPtr,eax
  end;

  if SortServerLogArrayShell then FlushViewOfFile(MapBase, 0);
  Windows.UnmapViewOfFile(MapBase);
  3: CloseHandle(MapFin);

end;
}

{

function SortServerLogArrayShell: boolean;
var
  bis, i, J, k                          : LONGINT;
  h                                     : ContestExchange;
  T1, T2                                : Cardinal;
begin

  Result := False;
  bis := LogArraySize - 1;
  k := bis shr 1; // div 2
  while k > 0 do
  begin
    for i := 0 to bis - k do
    begin
      J := i;
      T1 := LogArrayPtr[J].tSysTime.qtSecond + LogArrayPtr[J].tSysTime.qtMinute * 60 + LogArrayPtr[J].tSysTime.qtHour * 60 * 60 + +LogArrayPtr[J].tSysTime.qtDay * 60 * 60 * 24;
      T2 := LogArrayPtr[J + k].tSysTime.qtSecond + LogArrayPtr[J + k].tSysTime.qtMinute * 60 + LogArrayPtr[J + k].tSysTime.qtHour * 60 * 60 + +LogArrayPtr[J + k].tSysTime.qtDay * 60 * 60 * 24;
      //      while (J >= 0) and (STToInt64(LogArrayPtr[J].tSysTime) > STToInt64(LogArrayPtr[J + k].tSysTime)) do
      while (J >= 0) and (T1 > T2) do
      begin
        Result := True;
        h := LogArrayPtr[J];
        LogArrayPtr[J] := LogArrayPtr[J + k];
        LogArrayPtr[J + k] := h;
        if J > k then
          dec(J, k)
        else
          J := 0;
        T1 := LogArrayPtr[J].tSysTime.qtSecond + LogArrayPtr[J].tSysTime.qtMinute * 60 + LogArrayPtr[J].tSysTime.qtHour * 60 * 60 + +LogArrayPtr[J].tSysTime.qtDay * 60 * 60 * 24;
        T2 := LogArrayPtr[J + k].tSysTime.qtSecond + LogArrayPtr[J + k].tSysTime.qtMinute * 60 + LogArrayPtr[J + k].tSysTime.qtHour * 60 * 60 + +LogArrayPtr[J + k].tSysTime.qtDay * 60 * 60 * 24;

      end;
    end;
    k := k shr 1; // div 2
  end;

end;
}

function Load_MSWSOCK: boolean;
begin
  Result := True;
  MSWSOCK_DLL := LoadLibrary('MSWSOCK.DLL');
  if MSWSOCK_DLL <> 0 then
  begin

    @TransmitFile := GetProcAddress(MSWSOCK_DLL, 'TransmitFile');
    if @TransmitFile = nil then Result := False;

//    @AcceptEx := GetProcAddress(MSWSOCK_DLL, 'AcceptEx');
//    if @AcceptEx = nil then RESULT := False;

  end
  else
    Result := False;

  if Result = False then
    ServerMessageBox('Failed to load in MSWSOCK.DLL', MB_OK or MB_ICONWARNING or MB_TOPMOST);
end;

function TransmitServerLog(s: TSocket): DWORD; stdcall;
label
  1;
var
  TempCardinal                          : Cardinal;
  i                                     : integer;
  //  tGetNetLogEvent                  : HWND;
  //  r                                : integer;
//  ServerTFDSet                          : TFDSet;
//  ServerTTimeVal                        : TTimeVal;
begin
  //  tGetNetLogEvent := WSACreateEvent;
  //  WinSock2.WSAEventSelect(s, tGetNetLogEvent, FD_WRITE);
//  ServerTFDSet.fd_array[0] := s;
//  ServerTFDSet.fd_count := 1;
//  ServerTTimeVal.tv_sec := 5;
//  ServerTTimeVal.tv_usec := 0;
  sSend(s, ServerLogFileInformation.liServerLogSize, SizeOf(ServerLogFileInformation.liServerLogSize), dmTransmitFile);

//  Send(s, ServerLogFileInformation.liInformation, SizeOf(TByHandleFileInformation), 0);

  1:
  Windows.ReadFile(ServerLogHandle, ServerBuffer, SizeOf(ServerBuffer), TempCardinal, nil);

  if TempCardinal > 0 then
  begin
      //  WSAWaitForMultipleEvents(1, @tGetNetLogEvent, False, 5500, False);
      //  I := SELECT(0, nil, @ServerTFDSet, nil, @ServerTTimeVal);
//      if I < 1 then r := r + I;
    i := sSend(s, ServerBuffer, TempCardinal, dmTransmitFile);
    if DWORD(i) = TempCardinal then
    begin
      Sleep(10);
    end;
    goto 1;
  end;
  //  MessageBox(ApplicationHandle, PChar(IntToStr(r)), _TR4WSERVER, MB_OK or MB_ICONWARNING or MB_TOPMOST);
  //  WSACloseEvent(tGetNetLogEvent);
  CloseServerLog;
  closesocket(s);
  WriteContestExchangesBufferToServerLog;
end;

function OpenServerLog(dwCreationDistribution: DWORD): boolean;
begin
  Result := False;
  if ServerLogOpened then Exit;
  ServerLogHandle := CreateFile(@ServerLogFileName, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, dwCreationDistribution, FILE_ATTRIBUTE_ARCHIVE, 0);
  Result := ServerLogHandle <> INVALID_HANDLE_VALUE;
  ServerLogOpened := Result;

end;

procedure CloseServerLog;
begin
  if ServerLogHandle <> INVALID_HANDLE_VALUE then CloseHandle(ServerLogHandle);
  ServerLogHandle := INVALID_HANDLE_VALUE;
  ServerLogOpened := False;
end;

procedure AddContestExchangeToBuffer(CE: ContestExchange);
begin
  if ContestExchangesBufferIndex = MaxContestExchangesBufferSize then Exit;
  inc(ContestExchangesBufferIndex);
  ContestExchangesBuffer[ContestExchangesBufferIndex] := CE;
end;

procedure WriteContestExchangesBufferToServerLog;
var
  c, lpNumberOfBytesWritten             : Cardinal;
begin
  if ContestExchangesBufferIndex = 0 then Exit;
  if not OpenServerLog(OPEN_EXISTING) then
  begin
    ContestExchangesBufferIndex := 0;
    Exit;
  end;
  SetFilePointer(ServerLogHandle, 0, nil, FILE_END);
  for c := 1 to ContestExchangesBufferIndex do
    WriteFile(ServerLogHandle, ContestExchangesBuffer[c], SizeOf(ContestExchange), lpNumberOfBytesWritten, nil);
  FlushFileBuffers(ServerLogHandle);
  DisplayServerLogSize;
  CloseServerLog;
  ContestExchangesBufferIndex := 0;
end;

procedure SendLogFileInformation(s: TSocket);
var
  pNumberOfBytesRead                    : Cardinal;
begin
  if not OpenServerLog(OPEN_EXISTING) then Exit;
  ServerLogFileInformation.liServerLogSize := Windows.GetFileSize(ServerLogHandle, nil);
  ServerLogFileInformation.liContest := DUMMYCONTEST;
  if ServerLogFileInformation.liServerLogSize > SizeOfTLogHeader then
  begin
    SetFilePointer(ServerLogHandle, SizeOfTLogHeader, nil, FILE_BEGIN);
    Windows.ReadFile(ServerLogHandle, TempCE, SizeOf(TempCE), pNumberOfBytesRead, nil);
    ServerLogFileInformation.liContest := TempCE.ceContest;
  end;
  CloseServerLog;
  GetServerLogCRC32;
  ServerLogFileInformation.liSeverCRC32 := ServerCRC32;
  sSend(s, ServerLogFileInformation, SizeOf(TLogFileInformation), dmLogInfo);
end;

function ClearServerLog: boolean;
begin
  Result := False;
  if not OpenServerLog(OPEN_EXISTING) then Exit;
  SetFilePointer(ServerLogHandle, SizeOfTLogHeader, nil, FILE_BEGIN);
  SetEndOfFile(ServerLogHandle);
  DisplayServerLogSize;
  CloseServerLog;
  ScanLogForSerialsNumbers;
  Result := True;
end;

procedure WriteToServerDebugFile(Count: Cardinal; s: TSocket; comment: PChar; mt: DebugMessageType);
var
  h                                     : HWND;
  lpNumberOfBytesWritten                : Cardinal;
  TempBuffer                            : array[0..255] of Char;
  stored                                : integer;
  Time                                  : PChar;
begin
{$IF SERVERDEBUG}
  if not ServerDebugMode then Exit;
  h := CreateFile(@ServerDebugFileName, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);
  if h = INVALID_HANDLE_VALUE then Exit;
  SetFilePointer(h, 0, nil, FILE_END);
  asm
  push  comment

  push  BytesSEND
  push  BytesRCVD

  push  Count
  push  s
  push  time
  end;

  stored := wsprintf(TempBuffer, '%s  Client: %-6u   Bytes: %-7u  RX: %-7d  TX: %-7d   %s'#13#10);
  asm add esp,32
  end;

  WriteFile(h, TempBuffer, stored, lpNumberOfBytesWritten, nil);
  CloseHandle(h);
{$IFEND}
end;

procedure SendDisconnectMessage(Client: Char);
var
  i                                     : Cardinal;
begin
  for i := 1 to maxclients do
    if ClientsSoocketsArray[i].clSocket <> 0 then
    begin
      ServerMessage.smMessage := SM_DISCONECT_CLIENT_MESSAGE;
      ServerMessage.smParam := integer(Client);
      sSend(ClientsSoocketsArray[i].clSocket, ServerMessage, SizeOf(ServerMessage), dmDisc);
      Sleep(0);
    end;
end;

procedure SetComputerID(ID: Char; s: TSocket);
var
  i                                     : integer;
begin
  for i := 1 to maxclients do
    if ClientsSoocketsArray[i].clSocket = s then
    begin
      ClientsSoocketsArray[i].clID := ID;
      Break;
    end;
end;

procedure SetStatus(Status: TClientStatus; s: TSocket);
var
  i                                     : integer;
begin
  for i := 1 to maxclients do
    if ClientsSoocketsArray[i].clSocket = s then
    begin
      ClientsSoocketsArray[i].clConnectedToTelnet := Status.csTelnet;
      Break;
    end;
end;

procedure SendSpotViaNet(Status: TSendSpotViaNetwork; s: TSocket);
var
  i                                     : integer;
begin
  for i := 1 to maxclients do
    if ClientsSoocketsArray[i].clConnectedToTelnet then
      if ClientsSoocketsArray[i].clSocket <> s then
      begin
        sSend(ClientsSoocketsArray[i].clSocket, Status, SizeOf(Status), dmSpotViaNet);
        Break;
      end;
end;

function CorrectPassword(s: TSocket; BytesReceived: integer): boolean;
var
  i                                     : integer;
  Offset                                : integer;
begin
  Offset := 0;
  if BytesReceived > 10 then
  begin
    if PInteger(@ServerBuffer[0])^ = 542393671 {'GET '} then
      if PInteger(@ServerBuffer[6])^ = 1397965136 {'PASS'} then
          //          MessageBox(ApplicationHandle, @ServerBuffer, _TR4WSERVER, MB_OK or MB_ICONWARNING or MB_TOPMOST);
        Offset := 11;
  end;
  Result := False;
  for i := 0 to 9 do
    if ServerBuffer[i + Offset] <> tr4wServerPassword[i] then
    begin
      sSend(s, PASSTR4W, SizeOf(PASSTR4W), dmPass);
      Exit;
    end;
  Result := True;
end;
{
procedure LoadinMultsFrequencies;
label
  1;
var
  h                                     : HWND;
  pNumberOfBytesRead                    : Cardinal;
begin

  if not Tree.tOpenFileForRead(h, MultsFrequenciesFileName) then Exit;
  if Windows.GetFileSize(h, nil) <> SizeOf(MultsFrequencies) then goto 1;
  Windows.ReadFile(h, ServerMF, SizeOf(MultsFrequencies), pNumberOfBytesRead, nil);
  1: CloseHandle(h);

end;
}
{
procedure SaveMultsFrequencies;
var
  h                                     : HWND;
  lpNumberOfBytesWritten                : Cardinal;
begin
  if not Tree.tOpenFileForWrite(h, MultsFrequenciesFileName) then Exit;
  Windows.WriteFile(h, ServerMF, SizeOf(MultsFrequencies), lpNumberOfBytesWritten, nil);
  CloseHandle(h);
end;
}
{
procedure SendMFToClients;
var
  i                                     : Cardinal;
  I2                                    : integer;
begin
  NetMF.mfQSOTotals := ServerMF;
  for i := 1 to maxclients do
    if ClientsSoocketsArray[i].clSocket <> 0 then
    begin
      I2 := sSend(ClientsSoocketsArray[i].clSocket, NetMF, SizeOf(NetMultsFrequencies), dmMF);
    end;
end;
}

procedure GetServerLogCRC32;
label
  1, 3;
var
  dwSize                                : integer;
  MapFin                                : Cardinal;
  MapBase                               : Pointer;
begin
  if not ServerCRC32Changed then Exit;
  ServerCRC32 := 0;
  if not OpenServerLog(OPEN_EXISTING) then Exit;
  dwSize := Windows.GetFileSize(ServerLogHandle, nil);
  MapFin := Windows.CreateFileMapping(ServerLogHandle, nil, PAGE_READWRITE, 0, 0, nil);
  if MapFin = 0 then Exit;
  MapBase := Windows.MapViewOfFile(MapFin, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if MapBase = nil then goto 3;

  ServerCRC32 := uCRC32.GetCRC32(MapBase^, dwSize);
  ServerCRC32Changed := False;

  FlushViewOfFile(MapBase, 0);
  Windows.UnmapViewOfFile(MapBase);
  3: CloseHandle(MapFin);
  CloseServerLog;
end;

function sSend(s: TSocket; var buf; Len: integer; mt: DebugMessageType): integer;
begin
  Result := Send(s, buf, Len, 0);
  BytesSEND := BytesSEND + DWORD(Result);
  DisplaySENDBytes;
{$IF SERVERDEBUG}
  WriteToServerDebugFile(Result, s, nil, mt);
{$IFEND}

end;

function sRecv(s: TSocket; var buf; Len: integer): integer;
begin
  Result := recv(s, buf, Len, 0);
  BytesRCVD := BytesRCVD + DWORD(Result);
  DisplayRCVDBytes;
end;

function tUpdateServerLog(UpdAction: UpadateAction): boolean;
label
  1, 2, 3;
var
  MapFin                                : Cardinal;
  MapBase                               : Pointer;
  RescoredRXData                        : ContestExchangePtr;
  LogSize                               : Cardinal;
  QSOCounter                            : Cardinal;
begin
  Result := False;
  if not OpenServerLog(OPEN_EXISTING) then Exit;

  LogSize := Windows.GetFileSize(ServerLogHandle, nil);

  if LogSize <= SizeOf(TLogHeader) then goto 2;
  LogSize := ((LogSize - SizeOf(TLogHeader)) div SizeOfContestExchange);
  QSOCounter := 0;

  MapFin := Windows.CreateFileMapping(ServerLogHandle, nil, PAGE_READWRITE, 0, 0, nil);
  if MapFin = 0 then goto 2;

  MapBase := Windows.MapViewOfFile(MapFin, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if MapBase = nil then goto 3;
  asm
   add eax, SizeOfTLogHeader
   mov RescoredRXData,eax
  end;

  1:

  if RescoredRXData^.ceRecordKind = rkQSO then
  begin
    if UpdAction = actSetClearDupesheetBit then RescoredRXData^.ceClearDupeSheet := True;

    if UpdAction = actClearMults then
    begin
      RescoredRXData^.ceClearMultSheet := True;
      RescoredRXData^.DomesticMult := False;
      RescoredRXData^.DXMult := False;
      RescoredRXData^.PrefixMult := False;
      RescoredRXData^.ZoneMult := False;
    end;

  end;
  inc(QSOCounter);
  if QSOCounter <> LogSize then
  begin
    asm
    mov eax,RescoredRXData
    add eax,SizeOfContestExchange
    mov RescoredRXData,eax
    end;
    goto 1;
  end;

  Result := True;
  ServerCRC32Changed := True;

  FlushViewOfFile(MapBase, 0);
  Windows.UnmapViewOfFile(MapBase);
  3:
  CloseHandle(MapFin);
  2:
  CloseServerLog;

end;

procedure SendConfirmMessage(s: TSocket);
begin
  ServerMessage.smMessage := SM_RECEIVED_UPDATED_QSO_MESSAGE;
  sSend(s, ServerMessage, SizeOf(ServerMessage), dmROLQ);
end;

function ServerMessageBox(Text: PChar; uType: UINT): integer;
begin
  Result := MessageBox(ApplicationHandle, Text, _TR4WSERVER, uType);
end;

procedure ScanLogForSerialsNumbers;
label
  Next;
var
  i                                     : Cardinal;
  NextNumberToSend                      : integer;
begin
  if not SerialNumberLockoutEnable then Exit;
  if not OpenServerLog(OPEN_EXISTING) then Exit;
  NextNumberToSend := 0;

  SetFilePointer(ServerLogHandle, SizeOf(ContestExchange), nil, FILE_BEGIN);
  Next:
  Windows.ReadFile(ServerLogHandle, TempCE, SizeOf(ContestExchange), i, nil);
  if i = SizeOf(ContestExchange) then
  begin
    if NextNumberToSend < TempCE.NumberSent then NextNumberToSend := TempCE.NumberSent;
    goto Next;
  end;
  CloseServerLog;

  NextNumberToSend := NextNumberToSend + 1;

  for i := 1 to MAXCLIENTS do
  begin
    ClientsSoocketsArray[i].clSerialNumber := NextNumberToSend;
    ClientsSoocketsArray[i].clSerialNumberStatus := sntFree;
  end;
  SerialNumbersChanged;
end;

procedure SerialNumbersChanged;
var
  i                                     : integer;
begin
  if not SerialNumberLockoutEnable then Exit;
  for i := 1 to maxclients do
  begin
    if ClientsSoocketsArray[i].clSocket <> 0 then
      if ClientsSoocketsArray[i].clSerialNumberStatus = sntFree then
      begin
        ServerMessage.smMessage := SM_SERIAL_NUMBER_CHANGED;
        ServerMessage.smParam := ClientsSoocketsArray[i].clSerialNumber;
        sSend(ClientsSoocketsArray[i].clSocket, ServerMessage, SizeOf(ServerMessage), dmROLQ);
      end;
  end;
end;

procedure UpdateSerialNumbersStatus(s: TSocket; Status: TSerialNumberType);
var
  i                                     : integer;
begin
  if not SerialNumberLockoutEnable then Exit;
  for i := 1 to maxclients do
  begin
    if ClientsSoocketsArray[i].clSocket = s then
    begin
      ClientsSoocketsArray[i].clSerialNumberStatus := Status;
      Break;
    end;
  end;

  if Status = sntReserved then
    for i := 1 to maxclients do inc(ClientsSoocketsArray[i].clSerialNumber);

  SerialNumbersChanged;

end;

end.
{

Serial number server

N1MM logger supports a single sequence of serial numbers for SO2R, MS, M2 and MM.

The serial number is reserved in
S&P mode when the cursor leaves the callsign field or the Exchange key (F2 default) is sent.
Either through spacing, tabbing, or hitting Enter in ESM or pressing the Exchange key.
This is needed so you can enter calls to check for dupes while not reserving a serial number.
RUN mode as soon as you enter a letter in the call-sign field.
This because on SSB people frequently talk before they type, and they need to see the serial number displayed earlier. A serial number is not assigned in S&P mode until the space bar is pressed, so you can do dupe and check multipliers without committing a serial number to it, by entering it in the callsign field without pressing [Enter] or [Space].
In SO2R and SO2V, doing Alt+W (wipe) after a serial number has been reserved or wipe through QSY will "un-reserve" that number.

Because of the way the serial number server works, there are a couple of cautions:
Serial numbers issued by the second radio may be out of time sequence with those issued by the main one. This occurs because certain program actions cause a serial number to be reserved for the use of a station, and if that station does not use that number until after the other station has made several QSOs, when the log is viewed in chronological order the serial number will appear to be out of order. I don't think there is anything to be done about this.
For similar reasons, depending on operator actions at one or the other station, such as shutting down the program while a number is reserved, there may be some gaps (numbers not issued) when reviewing the final log.
The most important aspects of serial numbering are that the serial sent to a station be correctly logged, and that there be no duplicate serial numbers sent; N1MM logger seems to meet both these criteria.
Sometimes it's possible a number will be skipped when given out but not used (example: QSO not made after all or deleted). Contest committees do accept this behavior!.
The maximum sent number to give is 32767. The maximum receive number is 99999.
 Most sponsors are more interested in serial number accuracy than in serial number time order. If you think about it, it is impossible to guarantee the order of serial numbers in a two radio situation. This assumes that you always log the time when the QSO is added to the log, which is the right time from a rules point of view. i.e. end of contact.
Addendum by Steve, N2IC
Let me say a few words about the way serial numbers are "reserved" in N1MM Logger. For the sake of this discussion, I'll assume that ESM is being used.

When you enter a callsign in the Entry Window, and hit the Enter or Space key, a serial number is reserved and locked-in to that QSO. If it turns out that the QSO is not completed and logged, that serial number is "lost", and will be not used for a subsequent QSO.

This gets to be especially interesting with SO2R and SO2V. Let's say you are running on Radio 1, and search-and-pouncing on Radio 2. You enter a call on Radio 2, and hit the Enter key, reserving a serial number on Radio 2. You get beaten out on Radio 2, and go back to running stations on Radio 1, advancing the serial number beyond the number reserved on Radio 2. A few minutes pass, and you finally work the station on Radio 2. Your log now appears to have non-sequential serial numbers. If you never work that station on Radio 2, the reserved serial number on Radio 2 is lost, and will not be used for any subsequent QSO.

I can't speak for all contest sponsors, but for Sweepstakes and CW/SSB WPX, this is not an issue. There is no problem for these log adjudicators if your serial numbers are out-of-sequence, or if there are missing serial numbers in your log. Your log will be correctly processed. In addition, the N1MM Logger Summary window reports the correct number of successfully completed QSO's.

In summary, stop fretting about out-of-sequence or missing serial numbers. The software is working as designed
}

