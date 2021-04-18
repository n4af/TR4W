program tr4wserver;

{$DEFINE LINUX}

{$IMPORTEDDATA OFF}
uses
  Windows,
  Messages,
  tr4wserverUnit in 'src\tr4wserverUnit.pas',
  uCRC32 in '..\src\uCRC32.pas',
  winsock2 in '..\include\WinSock2.pas',
  TF in '..\src\TF.pas',
  VC in '..\src\vc.pas';

{$R res\tr4wserver.res}

function TR4wServerDlgProc(hwnddlg: HWND; uMsg: UINT; wp: wParam; lp: lParam): BOOL; stdcall;
label
  1, 2, CheckBuffer, Exit1, Exit2;
var
  BytesReceived                         : integer;
  counter                               : Cardinal;
  client_socket                         : Cardinal;
//  IntPtr                                : ^integer;
begin
  Result := False;
  case uMsg of
    WM_INITDIALOG:
      begin
//        SendMessage(hwnddlg, WM_SETICON, ICON_SMALL, LoadIcon(0, IDI_APPLICATION));
        Windows.SetDlgItemText(hwnddlg, 117, FullServerVersion);

        ApplicationHandle := hwnddlg;
        PortNumber := GetPrivateProfileInt(_TR4WSERVER, 'PORT', 1061, _TR4WSERVERINIFILE);
        Windows.SetDlgItemInt(hwnddlg, 102, PortNumber, False);
        sAllowTimeSynchronizing := GetPrivateProfileInt(_TR4WSERVER, 'ALLOW TIME SYNCHRONIZING', 1, _TR4WSERVERINIFILE) = 1;
        SerialNumberLockoutEnable := GetPrivateProfileInt(_TR4WSERVER, 'SERIAL NUMBER LOCKOUT', 0, _TR4WSERVERINIFILE) = 1;
        Windows.EnableWindow(GetDlgItem(ApplicationHandle, 118), SerialNumberLockoutEnable);

//        tGetLogTimeout := GetPrivateProfileInt(_TR4WSERVER, 'GET LOG TIMEOUT', 50, _TR4WSERVERINIFILE);
{$IF SERVERDEBUG}
        ServerDebugMode := GetPrivateProfileInt(_TR4WSERVER, 'DEBUG', 0, _TR4WSERVERINIFILE) = 1;
{$IFEND}
        GetPrivateProfileString(_TR4WSERVER, 'SERVER PASSWORD', _TR4WSERVER, @tr4wServerPassword, 11, _TR4WSERVERINIFILE);

        //if not Load_MSWSOCK then goto Exit2;
        MSWSOCKLoaded := Load_MSWSOCK;
        WSAStartup($0202, net_mywsadata);
        if not RunSyncListener then goto Exit1;

        BytesReceived := Windows.GetModuleFileName(0, @ServerLogFileName, SizeOf(ServerLogFileName));
        ServerLogFileName[BytesReceived - 14] := #0;
        Windows.lstrcat(@ServerLogFileName, 'SERVERLOG.TRW');
{$IF SERVERDEBUG}
        BytesReceived := Windows.GetModuleFileName(0, @ServerDebugFileName, SizeOf(ServerDebugFileName));
        ServerDebugFileName[BytesReceived - 14] := #0;
        Windows.lstrcat(@ServerDebugFileName, 'DEBUG.TXT');
{$IFEND}
{
        BytesReceived := Windows.GetModuleFileName(0, @MultsFrequenciesFileName, SizeOf(MultsFrequenciesFileName));
        MultsFrequenciesFileName[BytesReceived - 14] := #0;
        Windows.lstrcat(@MultsFrequenciesFileName, 'MULTS_FREQ.BIN');
        LoadinMultsFrequencies;
}
        if OpenServerLog(OPEN_ALWAYS) then
          if ServerLogHandle <> INVALID_HANDLE_VALUE then
          begin
            if (Windows.GetFileSize(ServerLogHandle, nil) mod SizeOf(ContestExchange)) <> 0 then
            begin
              ServerMessageBox('Error in serverlog.trw', MB_OK or MB_ICONWARNING or MB_TOPMOST);
              goto Exit1;
            end;
            if Windows.GetFileSize(ServerLogHandle, nil) = 0 then
              WriteFile(ServerLogHandle, LogHeader, SizeOfTLogHeader, BytesWritten, nil);

            DisplayServerLogSize;
            CloseServerLog;
          end
          else
          begin
            ServerMessageBox('Failed to open/create serverlog.trw', MB_OK or MB_ICONWARNING or MB_TOPMOST);
            goto Exit1;
          end;
        //        SortServerLog;
        ScanLogForSerialsNumbers;

//        SetPointerEvent := CreateEvent(nil, False, False, nil);
        RunServerThread;

        tr4w_osverinfo.dwOSVersionInfoSize := SizeOf(OSVERSIONINFO);
        Windows.GetVersionEx(tr4w_osverinfo);
        ServerOS := tr4w_osverinfo.dwPlatformId;
{
        Windows.SendDlgItemMessage(ApplicationHandle, 109, WM_SETFONT,
          integer(Windows.CreateFont(14, 0, 0, 0, FW_NORMAL, 0, 0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, Clip_Default_Precis, Default_Quality, 34, 'Courier New')),
          0);
}
      end;
    WM_COMMAND:
      begin
        if LoWord(wp) = 104 then goto Exit1;
      end;

    WM_CLOSE:
      begin
        Exit1:
        if nclients <> 0 then
          if ServerMessageBox('Do you really want to disconnect servers`s clients?', MB_YESNO or MB_ICONQUESTION or MB_TOPMOST or MB_DEFBUTTON2) = IDno then Exit;
        StopServer;
//        SaveMultsFrequencies;
        FreeLibrary(MSWSOCK_DLL);
        WSACleanup;
        Exit2:
        PostQuitMessage(0);
      end;

    WM_SOCK_NET_RX:
      begin
        BytesReceived := sRecv(wp, ServerBuffer, SizeOf(ServerBuffer));
        if BytesReceived <= 0 then
        begin
          DeleteSocketFromArray(wp);
          DisplayClients;
          Exit;
        end;

        Bufindex := 0;
        counter := 0;
        //            if br mod 5 <> 0 then MessageBox(ApplicationHandle, PChar(IntToStr(br)), 'recv', MB_YESNO or MB_ICONQUESTION or MB_TOPMOST or MB_DEFBUTTON2);

        CheckBuffer:

        case PWORD(@ServerBuffer[Bufindex])^ of

          NET_MESSAGESTATE_ID:
            begin
              SendMessageToClients(wp, SizeOf(TMessageState), True, dmMessage);
              Bufindex := Bufindex + SizeOf(TMessageState);
            end;

          NET_STATIONSTATUS_ID:
            begin
              SendMessageToClients(wp, SizeOf(TStationState), True, dmStationStatus);
              Bufindex := Bufindex + SizeOf(TStationState);
              if Bufindex = BytesReceived then goto 1;
            end;

          NET_NETWORKDXSPOT_ID:
            begin
              SendMessageToClients(wp, SizeOf(TNetDXSpot), False, dmDXSpot);
              Bufindex := Bufindex + SizeOf(TNetDXSpot);
            end;

          NET_TIMESYN_ID:
            begin
              if sAllowTimeSynchronizing then SendMessageToClients(wp, SizeOf(TNetTimeSync), False, dmTimeSyn);
              Bufindex := Bufindex + SizeOf(TNetTimeSync);
            end;

          NET_PARAMETER_ID:
            begin
              SendMessageToClients(wp, SizeOf(TParameterToNetwork), False, dmParam);
              Bufindex := Bufindex + SizeOf(TParameterToNetwork);
            end;

          NET_INTERCOMMESSAGE_ID:
            begin
              SendMessageToClients(wp, SizeOf(TIntercomMessage), True, dmIntercom);
              Bufindex := Bufindex + SizeOf(TIntercomMessage);
            end;

          NET_EDITEDQSO_ID:
            begin
              SendMessageToClients(wp, SizeOf(TNetQSOInformation), False, dmEditQSO);
              EditedQSOPtr := @ServerBuffer[Bufindex];
              UpdateQSOInServerlog(EditedQSOPtr^.qiInformation);
              SendConfirmMessage(wp);

              Bufindex := Bufindex + SizeOf(TNetQSOInformation);
            end;

          NET_OFFLINEQSO_ID:
            begin
              ServerNewQSOPtr := @ServerBuffer[Bufindex];
              if OpenServerLog(OPEN_EXISTING) then
              begin
                SetFilePointer(ServerLogHandle, 0, nil, FILE_END);
                WriteFile(ServerLogHandle, ServerNewQSOPtr.qiInformation, SizeOf(ContestExchange), BytesWritten, nil);
                FlushFileBuffers(ServerLogHandle);
                DisplayServerLogSize;
                CloseServerLog;
                SendConfirmMessage(wp);
              end;
              Bufindex := Bufindex + SizeOf(TNetQSOInformation);
            end;

          NET_QSOINFO_ID:
            begin
              ServerNewQSOPtr := @ServerBuffer[Bufindex];
              SendMessageToClients(wp, SizeOf(TNetQSOInformation), False, dmQSOInfo);
              if OpenServerLog(OPEN_EXISTING) then
              begin
                SetFilePointer(ServerLogHandle, 0, nil, FILE_END);
                WriteFile(ServerLogHandle, ServerNewQSOPtr.qiInformation, SizeOf(ContestExchange), BytesWritten, nil);
                FlushFileBuffers(ServerLogHandle);
                DisplayServerLogSize;
                CloseServerLog;
              end
              else
                AddContestExchangeToBuffer(ServerNewQSOPtr.qiInformation);
              Bufindex := Bufindex + SizeOf(TNetQSOInformation);
            end;

          NET_CLIENTSTATUS_ID:
            begin
              SetStatus(TClientStatusPtr(@ServerBuffer[Bufindex])^, wp);
              inc(Bufindex, SizeOf(TClientStatus));
            end;

          NET_SPOTVIANETWORK_ID:
            begin
              SendSpotViaNet(TSendSpotViaNetworkPtr(@ServerBuffer[Bufindex])^, wp);
              inc(Bufindex, SizeOf(TSendSpotViaNetwork));
            end;

          NET_COMPUTERID_ID:
            begin
              SetComputerID(TComputerNetIDPtr(@ServerBuffer[Bufindex])^.ciComputerID, wp);
              Bufindex := Bufindex + SizeOf(TComputerNetID);
            end;
{
          NET_MULTSFREQUENCIES_ID:
            begin
              Windows.CopyMemory(@ServerMF, @ServerBuffer[Bufindex + 2], SizeOf(MultsFrequencies));
              SendMFToClients;
              Bufindex := Bufindex + SizeOf(NetMultsFrequencies);
            end;
}
          NET_SERVERMESSAGE_ID:
            begin
              ServerMessagePtr := @ServerBuffer[Bufindex];
              case ServerMessagePtr.smMessage of
{
                SM_CLEARSERVERLOG_MESSAGE:
                  begin
                    if ClearServerLog then SendMessageToClients(wp, SizeOf(TServerMessage), True, dmClearLogs);
                  end;
}

                SM_SERIAL_NUMBER_CHANGED:
                  begin
                    if SerialNumberLockoutEnable then
                      UpdateSerialNumbersStatus(wp, TSerialNumberType(ServerMessagePtr.smParam));
                  end;

                SM_CLEARALLLOGS_MESSAGE:
                  begin
                    if ClearServerLog then SendMessageToClients(wp, SizeOf(TServerMessage), True, dmClearLogs);
                  end;

                SM_CLEAR_DUPESHEET_MESSAGE:
                  begin
                    if tUpdateServerLog(actSetClearDupesheetBit) then SendMessageToClients(wp, SizeOf(TServerMessage), True, dmClearLogs);
                  end;

                SM_CLEAR_MULTSHEET_MESSAGE:
                  begin
                    if tUpdateServerLog(actClearMults) then SendMessageToClients(wp, SizeOf(TServerMessage), True, dmClearLogs);
                  end;
{
                SM_SORTLOG_MESSAGE:
                  begin
                    if OpenServerLog(OPEN_EXISTING) then
                    begin
                      SortServerLog;
                      CloseServerLog;
                    end;
                  end;
}
                SM_SERVERLOG_CHANGED_MESSAGE:
                  begin
                    SendMessageToClients(wp, SizeOf(TServerMessage), False, dmClearLogs);
                  end;

                SM_GETSTATUS_MESSAGE:
                  SendMessageToClients(wp, SizeOf(TServerMessage), False, dmClearLogs);

              end;
              Bufindex := Bufindex + SizeOf(TServerMessage);

            end;

        end;

        if Bufindex = BytesReceived then goto 1;

        if PDWORD(@ServerBuffer[Bufindex])^ = NET_LOGINFO_MESSAGE then
        begin
          SendLogFileInformation(wp);
          Bufindex := Bufindex + SizeOf(NET_LOGINFO_MESSAGE);
          if Bufindex = BytesReceived then goto 1;
        end;

        inc(counter);

        if counter < 25 then goto CheckBuffer;
        1:
        DisplayRCVDBytes;

      end;
    WM_SOCK_NET_SYNLISTNER:
      begin

        client_socket := WinSock2.Accept(ListenerSocket, client_addr, addrlen);
        if client_socket <> INVALID_SOCKET then
        begin

          Sleep(50);
          BytesReceived := sRecv(client_socket, ServerBuffer, 50);
            //убрать!!!!!
{
            if OpenServerLog(OPEN_EXISTING) then
              begin
                SetFilePointer(ServerLogHandle, 0, nil, FILE_BEGIN);
                WriteFile(ServerLogHandle, ServerBuffer, br, BytesWritten, nil);
                CloseServerLog;
              end;
}
          if not CorrectPassword(client_socket, BytesReceived) then
          begin
            closesocket(client_socket);
            Exit;
          end;

          if OpenServerLog(OPEN_EXISTING) then
          begin
            SetFilePointer(ServerLogHandle, 0, nil, FILE_BEGIN);
                //                ServerLogSize := Windows.GetFileSize(ServerLogHandle, nil);
//            Windows.GetFileInformationByHandle(ServerLogHandle, ServerLogFileInformation.liInformation);
            ServerLogFileInformation.liServerLogSize := Windows.GetFileSize(ServerLogHandle, nil);
            Server_TRANSMIT_FILE_BUFFERS.Head := @ServerLogFileInformation.liServerLogSize {ServerLogSize};
            Server_TRANSMIT_FILE_BUFFERS.HeadLength := SizeOf(ServerLogFileInformation.liServerLogSize);
            Server_TRANSMIT_FILE_BUFFERS.Tail := nil;
            Server_TRANSMIT_FILE_BUFFERS.TailLength := 0;
            //if ServerOS = VER_PLATFORM_WIN32_NT then
            if MSWSOCKLoaded then
            begin

              if TransmitFile(client_socket, ServerLogHandle, 0, 0, nil, @Server_TRANSMIT_FILE_BUFFERS, TF_DISCONNECT) then
              begin
                BytesSEND := BytesSEND + Windows.GetFileSize(ServerLogHandle, nil);
                DisplaySENDBytes;
              end;
              CloseServerLog;
              closesocket(client_socket);
            end
            else
              ServerThread := CreateThread(nil, 0, @TransmitServerLog, Pointer(client_socket), 0, ServerThreadID);
                //                  TransmitServerLog(client_socket);

          end;

        end;
      end;

    WM_SOCK_NET_ACCEPT:
      begin
//        AcceptEx(ListenerSocket, client_socket, ServerBuffer, 10, 10, 10, lpdwBytesReceived, nil);
        client_socket := WinSock2.Accept(ServerSocket, client_addr, addrlen);
        if client_socket <> INVALID_SOCKET then
        begin
          Sleep(200);

          BytesReceived := sRecv(client_socket, ServerBuffer, 10);
          if BytesReceived = -1 then goto 2;
          if not CorrectPassword(client_socket, BytesReceived) then
          begin
            sSend(client_socket, ServerBuffer, BytesReceived, dmAccept);
            closesocket(client_socket);
            Exit;
          end;

          BytesReceived := sSend(client_socket, SENDTR4W, SizeOf(SENDTR4W), dmTR4W);
          if BytesReceived <> 4 then
          begin
            2:
            closesocket(client_socket);
            Exit;
          end;

          WinSock2.setsockopt(client_socket, IPPROTO_TCP, TCP_NODELAY, @ENABLE_TCP_NODELAY, SizeOf(integer));
          myhostent := WinSock2.gethostbyaddr(@client_addr.sin_addr.S_addr, 4, AF_INET);

          if myhostent = nil then
            AddSocketToArray(client_socket, WinSock2.iNet_ntoa(client_addr.sin_addr), nil)
          else
            AddSocketToArray(client_socket, WinSock2.iNet_ntoa(client_addr.sin_addr), myhostent.h_Name);

          DisplayClients;
          WinSock2.WSAAsyncSelect(client_socket, hwnddlg, WM_SOCK_NET_RX, FD_READ or FD_CLOSE or FD_CONNECT);
//          SendMFToClients;
          SendLogFileInformation(client_socket);
          SerialNumbersChanged;
        end;
      end;
  end;
end;

begin
  if CreateMutex(nil, False, _TR4WSERVER) = 0 then Exit;
  if GetLastError = ERROR_ALREADY_EXISTS then Exit;
  DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @TR4wServerDlgProc);
end.

