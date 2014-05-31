unit t_; {Telnet WINAPI}

interface

uses
   winsock,
   ComCtrls,
   LogWind,
   WINDOWS,
   richedit,
   tree,
   LogPack,
   LogEdit,
   Lenin_Commctrl,
   Messages;
const
   SOCK_IDLE                       = 0;
   SOCK_CLIENT                     = 3;
   WM_SOCK                         = WM_USER + 100 {100};

   ID_SERVPORT                     = $101;
   ID_HOSTNAME                     = $103;
   ID_GETHOSTBYNAME                = $104;
   ID_IPADDR                       = $105;
   ID_PORT                         = $106;
   ID_CONNECT                      = $107;
   ID_STATUS                       = $108;
   ID_COMMAND                      = $109;
   ID_SEND                         = $10A;
   sys_mess                        = ';OS Message: ';
   _connected                      = 'Connected.';
   _disconnect                     = 'Disconnect';
   _disconnected                   = 'Disconnected.';
   _connect                        = 'Connect';

var
   somevar                         : boolean = false;
   icc                             : TInitCommonControlsEx =
      (
      dwSize: sizeof(TInitCommonControlsEx);
      dwICC: ICC_INTERNET_CLASSES;
      );

   iiii, hwn                       : integer;
   //   initcomctl                      : INITCOMMONCONTROLSEX;
   mywsadata                       : wsadata;
   sock                            : integer;
   temp                            : integer;
   focus                           : integer;
   status                          : INTEGER;
   buff                            : string;
   buffer                          : array[1..2000] of Char;
   mycharformat                    : CHARFORMAT2A {tCHARFORMAT};
   myhostent                       : Phostent;
   saddr                           : sockaddr_in;

function DlgProc(hwnddlg: HWND; msg: UINT; wparam: WPARAM; lparam: LPARAM): bool; stdcall;
procedure TelnetInitProc;

procedure wmclose;
procedure gethostbyname;
procedure connect;
procedure disconnect;

//procedure listen;
procedure send;
//procedure setfocus(i: integer);
//procedure killfocus;
procedure write_status(eax, esi: integer);
procedure wmsock;

var
   ii                              : cardinal;
   commandsfile                    : text;
   //const   sectionname                     = 'TELNETCOMMANDS';
implementation

uses unit1;

function DlgProc(hwnddlg: HWND; msg: UINT; wparam: WPARAM; lparam: LPARAM): bool; STDCALL;

begin
   Result := false;
   case Msg of

      WM_INITDIALOG:
         begin

            hwn := hwnddlg;

            status := SOCK_IDLE;
            hwn := hwnddlg;
            WSAStartup($0101, mywsadata);
            buff := mywsadata.szDescription;
            buff := buff + ' ' + mywsadata.szSystemStatus;
            write_status($C0C0C0, integer(pchar(';' + buff + #13 + #10 + #0)));

            assignfile(commandsfile, TR4W_PATH_NAME + 'telnetcommands.txt');
            reset(commandsfile);
            if IORESULT = 0 then
               while not eof(commandsfile) do
                  begin
                     ReadLn(commandsfile, buff);
                     SendDlgItemMessage(hwn, 265, CB_ADDSTRING, 0, integer(pchar(buff)));
                  end;
            closefile(commandsfile);

            assignfile(commandsfile, TR4W_PATH_NAME + 'telnetclusters.txt');
            reset(commandsfile);
            if IORESULT = 0 then
               while not eof(commandsfile) do
                  begin
                     ReadLn(commandsfile, buff);
                     SendDlgItemMessage(hwn, 259, CB_ADDSTRING, 0, integer(pchar(buff)));
                  end;
            closefile(commandsfile);
            buff := '';
            SendDlgItemMessage(hwn, 259, CB_SETCURSEL, 0, 0);

         end;
      //      WM_NCMOUSEMOVE:showclosewindow(hwnddlg,msg);
      //      WM_MOUSEMOVE:showclosewindow(hwnddlg,msg);

      WM_COMMAND:
         begin
            case wparam of
               //               IDCANCEL: wmclose;

               IDOK:
                  begin
                     if focus = ID_HOSTNAME then gethostbyname;
                     if focus = ID_PORT then connect;
                     //                     if focus = ID_SERVPORT then listen;
                     if focus = ID_COMMAND then send;
                  end;

               //               ID_LISTEN: listen;
               ID_GETHOSTBYNAME: gethostbyname;
               ID_CONNECT: connect;
               ID_SEND: send;

               2: wmclose;
               //               ID_MINI: sendmessage(hwnddlg, WM_SYSCOMMAND, SC_MINIMIZE, 0);
      //              EN_SETFOCUS: setfocus(lparam);
      //               EN_KILLFOCUS: killfocus;
      //               CBN_SETFOCUS: setfocus(lparam);
      //               CBN_KILLFOCUS: killfocus;

            end;

         end;

      {      WM_DESTROY, }WM_CLOSE: wmclose;
      WM_SOCK: wmsock;

   end;

end;

procedure wmclose;
begin

   closesocket(sock);
   WSACleanup;
   destroywindow(hwn);
   FRM.m4.Checked := false;

end;

procedure gethostbyname;
var
   e                               : integer;

label
   exitt, badname;
begin

   GetDlgItemText(hwn, ID_HOSTNAME, (@buffer), 20);
   e := integer(@buffer);

   asm


           push e
           call winsock.gethostbyname
           or eax,eax
           jz  badname
           mov eax,[eax+12]
           mov eax,[eax]
           mov eax,[eax]
           bswap eax
           mov   e,eax
           jmp exitt

   end;

   badname:
   begin
      write_status($FF0001, integer(pchar(sys_mess + SysErrorMessage(WSAGetLastError) + ': ' + buff + #13 + #10)));
      SendDlgItemMessage(hwn, ID_IPADDR, WM_USER + 100 {IPM_CLEARADDRESS}, 0, 0);
      exit;
   end;

   exitt:
   //   write_status($FF0000, integer(pchar(sys_mess + SysErrorMessage(WSAGetLastError) + ': ' + buff + #13 + #10)));
   SendDlgItemMessage(hwn, ID_IPADDR, WM_USER + 101 {IPM_SETADDRESS}, 0, e);

end;

procedure connect;
var
   timestring                      : string[6];
label
   processed;
begin
   if status = SOCK_CLIENT then
      begin
         disconnect;
         closefile(tr4wfile);
         exit;
      end;
   if status <> SOCK_IDLE then exit;
   sock := 0;
   write_status($C0C0C0, integer(pchar(';Get IP address...' + #13 + #10 + #0)));
   gethostbyname;
   GetDlgItemText(hwn, ID_IPADDR, @buffer, 20);
   saddr.sin_addr.S_addr := inet_addr(@buffer);
   write_status($C0C0C0, integer(pchar(';Server IP: ')));
   write_status($C0C0C0, integer(@buffer));
   write_status($C0C0C0, integer(pchar(' :')));
   GetDlgItemText(hwn, 262, @buffer, 5);
   write_status($C0C0C0, integer(@buffer));

   saddr.sin_port := htons(GetDlgItemInt(hwn, ID_PORT, longbool(temp), FALSE));
   saddr.sin_family := PF_INET;
   closesocket(sock);
   socket(AF_INET, { SOCK_DGRAM} SOCK_STREAM, IPPROTO_IP);
   asm
      cmp eax, -1
      je processed
      mov[sock], eax
   end;

   //   write_status($FF0000, integer(pchar(sys_mess + SysErrorMessage(WSAGetLastError)+  #13 + #10)));
   buff := #13 + #10 + ';' + _connect + '...' + #13 + #10;
   write_status($C0C0C0, integer(pchar(buff)));
   if winsock.connect(sock, saddr, sizeof(sockaddr_in)) <> 0 then

      begin
         write_status($FF0001, integer(pchar(sys_mess + SysErrorMessage(WSAGetLastError) + #13 + #10 + #0)));
         exit;
      end;
   write_status($FF0001, integer(pchar(sys_mess + SysErrorMessage(WSAGetLastError) + #13 + #10 + #0)));
   write_status($C0C0C0, integer(pchar(';Socket ' + inttostr(sock) + #13 + #10 + #0)));
   write_status($9F00, integer(pchar(_connected) + #13 + #10 + #0));
   status := SOCK_CLIENT;
   WSAAsyncSelect(sock, hwn, WM_SOCK, FD_READ or FD_CLOSE);
   SetDlgItemText(hwn, ID_CONNECT, pchar(_disconnect));
   EnableWindow(GetDlgItem(hwn, ID_SEND), TRUE);
   //   EnableWindow(GetDlgItem(hwn, ID_LISTEN), FALSE);
   SendMessage(hwn, WM_NEXTDLGCTL, GetDlgItem(hwn, ID_COMMAND), 1);
   SetDlgItemText(hwn, 265, pchar(mycall));
   windows.SetFocus(GetDlgItem(hwn, 266)); // focus to send button
   {Telnet Logs}
   SetCurrentDirectory(pchar(TR4W_PATH_NAME));
   CreateDirectory(pchar('TelnetLogs'), nil);
   timestring := GetTimeString;
   timestring[3] := '_';
   assignfile(tr4wfile, TR4W_PATH_NAME + '\TelnetLogs\' + 'telnet_' + GetDateString + '_' + timestring + '.txt');
   Rewrite(tr4wfile, 1);

   processed:
end;

//procedure listen;
//begin
//   send;
//end;

procedure send;

var
   da, res                         : integer;
begin
   da := GetDlgItemText(hwn, ID_COMMAND, @buffer, 8000);

   buffer[da + 1] := #13;
   buffer[da + 2] := #10;
   buffer[da + 3] := #0;
   SendDlgItemMessage(hwn, ID_COMMAND, CB_ADDSTRING, 0, integer(@buffer));
   winsock.send(sock, buffer, da + 2, 0);
   BlockWrite(tr4wfile, buffer, da + 2, res);
   write_status($FF0000, integer(@buffer));
   buffer[1] := #0;
   SetDlgItemText(hwn, ID_COMMAND, @buffer);
end;

//procedure setfocus(i: integer);
//begin
//   focus := i;
//end;

//procedure killfocus;
//begin

//end;

procedure write_status(eax, esi: integer);
var
   ebx                             : integer;
begin
   //   mycharformat.sSpacing:=50;

   mycharformat.cbSize := sizeof(CHARFORMAT2A);
   mycharformat.dwMask := CFM_BOLD or CFM_COLOR or CFM_FACE or CFM_SIZE or CFM_UNDERLINE or CFM_LINK;
   mycharformat.szFaceName := 'Arial';
   //   mycharformat.dwEffects := 0;
   mycharformat.crTextColor := eax;
   if eax = $FF0001 then
      mycharformat.szFaceName := 'Comic Sans MS';
   {   if eax = $FF0001 then
      begin

         mycharformat.dwEffects := CFE_BOLD;
      end
   else
      begin
         mycharformat.dwEffects := 0;

      end;
 }ebx := GetDlgItem(hwn, ID_STATUS);

   SendMessage(ebx, EM_SETSEL, -1, -1);
   SendMessage(ebx, EM_SCROLLCARET, 0, 0);
   SendMessage(ebx, EM_SETCHARFORMAT, SCF_SELECTION, integer(@mycharformat));

   SendMessage(ebx, EM_REPLACESEL, 0, esi);
   //      BlockWrite(tr4wfile, esi, 10, ebx);
end;

procedure disconnect;
begin
   closesocket(sock);
   write_status($FF0001, integer(pchar(sys_mess + SysErrorMessage(WSAGetLastError) + #13 + #10)));
   status := SOCK_IDLE;
   write_status($FF, integer(pchar(_disconnected) + #13 + #10));
   SetDlgItemText(hwn, ID_CONNECT, _connect);
   EnableWindow(GetDlgItem(hwn, ID_SEND), FALSE);
   //   EnableWindow(GetDlgItem(hwn, ID_CONNECT), TRUE);
   SendMessage(hwn, WM_NEXTDLGCTL, GetDlgItem(hwn, ID_HOSTNAME), 1);

end;

procedure wmsock;
var
   i, res, iiii                    : integer;
   spot                            : string[100];
   spoti                           : integer;
   Start, Stop                     : Integer;
   TelnetDXspot                    : DXSpotType;
begin
   try

      i := recv(sock, buffer, 2000, 0);

      if i < 0 then exit;
      write_status($C0C0C0, integer(pchar(inttostr(i) { + #13 + #10 + #0})));

      spoti := 1;
      stop := -1;
      Start := -1;
      spot := '                                                                                                               ';
      if i < 86 then
         begin
            for spoti := 1 to i do
               begin
                  if buffer[spoti] = 'D' then
                     if buffer[spoti + 1] = 'X' then
                        if buffer[spoti + 2] = ' ' then
                           Start := spoti;
                  if buffer[spoti] = #13 then
                     if start <> -1 then stop := spoti;
                  if stop - Start > 50 then
                     if stop - Start < 85 then
                        begin
                           for res := Start to stop do spot[res] := buffer[res];

                           if FoundDXSpot(spot, TelnetDXspot) then LogPack.Packet.ProcessPacketSpot(TelnetDXspot);
                           //                     showmessage(inttostr(start) + #13 + inttostr(stop) + #13 + spot);
                           stop := -1;
                           Start := -1;
                        end;
               end;
         end;
      BlockWrite(tr4wfile, buffer, i, res);
      buffer[i] := #0;
      write_status($000000, integer(@buffer));
   except
      showmessage('e' + #13 + 'stop ' + inttostr(stop) + #13 + 'start ' + inttostr(start) + #13 + inttostr(i));
   end
end;

procedure TelnetInitProc;

begin

   InitCommonControlsEx(icc);
   ;
   windows.LoadLibrary('RICHED32.DLL');
   CreateDialog(GetModuleHandle(0), MAKEINTRESOURCE(37), 0, @DlgProc); //, SW_SHOWNOrmal);
end;














end.

