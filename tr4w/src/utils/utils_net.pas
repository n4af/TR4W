unit utils_net;

interface

uses

  Windows,
  WinSock2;
function GetConnection(var socket: DWORD; Host: PChar; port: Cardinal; struct: integer): boolean;

var
  WindowsSocketsInitialised             : boolean;
  WSData                                : TWSAData;

implementation

function GetConnection(var socket: DWORD; Host: PChar; port: Cardinal; struct: integer): boolean;
var
  TempSockaddr                          : sockaddr_in;
  TempHostent                           : Phostent;
  connErr                               : integer;   // Issue #23
//  Protocol                              : integer;
begin
  Result := False;
  // Issue #23 -- never hand the caller a stale/garbage or already-closed handle
  // on any failure path.  Every caller tests Result and several closesocket()
  // unconditionally; INVALID_SOCKET makes that a safe no-op.
  socket := INVALID_SOCKET;

  if not WindowsSocketsInitialised then
    WindowsSocketsInitialised := WSAStartup($0202, WSData) = 0;
  if not WindowsSocketsInitialised then Exit;   // WinSock unavailable

  TempHostent := WinSock2.gethostbyname(Host);
  if TempHostent = nil then Exit;               // name resolution failed

  TempSockaddr.sa_family := AF_INET;
  TempSockaddr.sin_addr.S_addr := inet_addr(iNet_ntoa(PInAddr(TempHostent^.h_addr_list^)^));
  TempSockaddr.sin_port := htons(port);

//  if struct = SOCK_DGRAM then Protocol := IPPROTO_UDP{IPPROTO_IP} else Protocol := IPPROTO_TCP;
  socket := WinSock2.socket(AF_INET, struct, IPPROTO_IP {Protocol});
  if socket = INVALID_SOCKET then Exit;          // socket creation failed

  Result := WinSock2.Connect(socket, @TempSockaddr, SizeOf(TSockAddrIn)) = 0;
  if not Result then
  begin
    // Issue #23 -- closesocket() resets WSAGetLastError to 0 (its own success),
    // wiping the real connect error before the caller can read it (which is why
    // a failed connect reported "The operation completed successfully").
    // Capture the connect error and restore it after the cleanup.
    connErr := WSAGetLastError;
    closesocket(socket);
    socket := INVALID_SOCKET;                    // closed -- don't expose the dead handle
    WSASetLastError(connErr);
  end;
end;

end.

