unit utils_net;

interface

uses

  Windows,
  WinSock2;
function GetConnection(var socket: DWORD; Host: PChar; port: Cardinal; struct: integer; sError: string): boolean;

var
  WindowsSocketsInitialised             : boolean;
  WSData                                : TWSAData;

implementation

function GetConnection(var socket: DWORD; Host: PChar; port: Cardinal; struct: integer; sError: string): boolean;
var
  TempSockaddr                          : sockaddr_in;
  TempHostent                           : Phostent;
//  Protocol                              : integer;
begin
  Result := False;

  if not WindowsSocketsInitialised then
    WindowsSocketsInitialised := WSAStartup($0202, WSData) = 0;

  TempHostent := WinSock2.gethostbyname(Host);
  if TempHostent = nil then Exit;

  TempSockaddr.sa_family := AF_INET;
  TempSockaddr.sin_addr.S_addr := inet_addr(iNet_ntoa(PInAddr(TempHostent^.h_addr_list^)^));
  TempSockaddr.sin_port := htons(port);

//  if struct = SOCK_DGRAM then Protocol := IPPROTO_UDP{IPPROTO_IP} else Protocol := IPPROTO_TCP;
  socket := WinSock2.socket(AF_INET, struct, IPPROTO_IP {Protocol});

  Result := WinSock2.Connect(socket, @TempSockaddr, SizeOf(TSockAddrIn)) = 0;
  if not Result then
  begin
    closesocket(socket);
  end;
end;

end.

