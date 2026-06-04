unit uK4Discovery;

{
  Elecraft K4 Network Radio Discovery -- Issue #853

  Stimulus/response model (mirrors uIcomNetworkDiscovery):
    1. Broadcast the ASCII string 'findk4' as a UDP datagram to
       255.255.255.255 on port 9100.
    2. Each K4 on the subnet unicasts back a colon-delimited ASCII reply
       'k4:<index>:<ip>:<serial>'  (or 'k4z:...' for a K4 Zero).
    3. Collect replies for TimeoutMs, de-duped by IP.

  Usage:
    var Radios: TList;
    Radios := TK4Discovery.DiscoverRadios(5000);
    // each item is a PK4DiscoveredRadio; the caller frees the items + the list.

  ParseResponse is exposed as a class function so the (Indy-free) reply parsing
  can be unit-tested without a live radio.
}

interface

uses
  Windows, SysUtils, Classes,
  IdUDPClient, IdGlobal, IdStack,
  Log4D;

const
  K4_DISCOVERY_PORT       = 9100;        // UDP discovery port (probe + reply)
  K4_DISCOVERY_TIMEOUT_MS = 5000;        // default collect window
  K4_DISCOVERY_STIMULUS   = 'findk4';    // broadcast probe string
  K4_RESPONSE_PREFIX      = 'k4';        // valid replies start with this (also matches 'k4z')

type
  TK4DiscoveredRadio = record
    RigType      : string;    // 'k4' or 'k4z'
    RigIndex     : Integer;   // radio index, typically 0
    IPAddress    : string;    // the radio's IP, from the reply
    SerialNumber : string;    // radio serial, e.g. '278'
  end;
  PK4DiscoveredRadio = ^TK4DiscoveredRadio;

  TK4Discovery = class(TObject)
  public
    // Broadcasts 'findk4' and collects K4 replies for TimeoutMs.  Returns a
    // TList of PK4DiscoveredRadio (caller owns the list and the items).
    class function DiscoverRadios(TimeoutMs: Integer = K4_DISCOVERY_TIMEOUT_MS): TList;

    // Parses one reply ('k4:0:192.168.1.100:278').  Returns False unless it
    // starts with 'k4' AND has exactly four ':'-separated fields with a
    // non-empty IP.  No Indy / network dependency -- unit-testable.
    class function ParseResponse(const Reply: string; var Radio: TK4DiscoveredRadio): Boolean;

    // Friendly mDNS-style host name, e.g. K4 serial 278 -> 'K4-SN00278.local'
    // (serial left-padded with zeros to 5 digits; 'K4Z' prefix for a K4 Zero).
    class function Hostname(const Radio: TK4DiscoveredRadio): string;
  end;

implementation

uses
  StrUtils;

var
  logger: TLogLogger;

class function TK4Discovery.ParseResponse(const Reply: string;
                                          var Radio: TK4DiscoveredRadio): Boolean;
var
  c1, c2, c3: Integer;
begin
  Result := False;
  Radio.RigType := '';
  Radio.RigIndex := 0;
  Radio.IPAddress := '';
  Radio.SerialNumber := '';

  if LowerCase(Copy(Reply, 1, Length(K4_RESPONSE_PREFIX))) <> K4_RESPONSE_PREFIX then
     begin
     Exit;
     end;

  // Exactly four fields: rigType : rigIndex : ip : serial
  c1 := Pos(':', Reply);
  if c1 = 0 then Exit;
  c2 := PosEx(':', Reply, c1 + 1);
  if c2 = 0 then Exit;
  c3 := PosEx(':', Reply, c2 + 1);
  if c3 = 0 then Exit;
  if PosEx(':', Reply, c3 + 1) <> 0 then Exit;   // a 5th ':' means malformed

  // Trim() also strips any trailing #0/CR/LF the datagram may carry.
  Radio.RigType      := LowerCase(Trim(Copy(Reply, 1, c1 - 1)));
  Radio.RigIndex     := StrToIntDef(Trim(Copy(Reply, c1 + 1, c2 - c1 - 1)), 0);
  Radio.IPAddress    := Trim(Copy(Reply, c2 + 1, c3 - c2 - 1));
  Radio.SerialNumber := Trim(Copy(Reply, c3 + 1, Length(Reply) - c3));

  Result := Radio.IPAddress <> '';
end;

class function TK4Discovery.Hostname(const Radio: TK4DiscoveredRadio): string;
var
  prefix, sn: string;
begin
  if Radio.RigType = 'k4z' then
     begin
     prefix := 'K4Z';
     end
  else
     begin
     prefix := 'K4';
     end;

  sn := Radio.SerialNumber;
  while Length(sn) < 5 do
     begin
     sn := '0' + sn;
     end;

  Result := prefix + '-SN' + sn + '.local';
end;

class function TK4Discovery.DiscoverRadios(TimeoutMs: Integer): TList;
var
  clients: TList;
  client: TIdUDPClient;
  SendBytes: TIdBytes;
  RecvBuf: TIdBytes;
  RecvLen: Integer;
  PeerIP: string;
  PeerPort: Word;
  StartTime: LongWord;
  Reply: string;
  Parsed: TK4DiscoveredRadio;
  Radio: PK4DiscoveredRadio;
  localIPs: TStrings;
  ip: string;
  i, c: Integer;
  isDuplicate: Boolean;
begin
  Result := TList.Create;

  // Stimulus is the literal ASCII 'findk4'.
  SetLength(SendBytes, Length(K4_DISCOVERY_STIMULUS));
  for i := 1 to Length(K4_DISCOVERY_STIMULUS) do
     begin
     SendBytes[i - 1] := Byte(K4_DISCOVERY_STIMULUS[i]);
     end;

  clients := TList.Create;
  TIdStack.IncUsage;   // ensure the Indy stack so GStack.LocalAddresses is valid
  try
    localIPs := GStack.LocalAddresses;   // GStack-owned -- do NOT free

    // Broadcast 'findk4' out EACH local IPv4 interface.  A single
    // 255.255.255.255 send only leaves the default-route interface, so a K4 on
    // another subnet is never reached; binding a socket to each interface IP
    // makes the broadcast go out that NIC.  Mirrors the QK4 per-interface send.
    // The K4's reply (to the source port) is received on the same socket.
    for i := 0 to localIPs.Count - 1 do
    begin
      ip := localIPs[i];
      if (ip = '') or (ip = '127.0.0.1') or (Pos(':', ip) > 0) then
         Continue;   // skip blanks, loopback, and IPv6

      client := TIdUDPClient.Create(nil);
      try
        client.BoundIP := ip;            // send out this specific interface
        client.BroadcastEnabled := True;
        client.ReceiveTimeout := 150;
        client.SendBuffer('255.255.255.255', K4_DISCOVERY_PORT, SendBytes);
        logger.Info('[K4Discovery] Sent findk4 from %s to 255.255.255.255:%d',
                    [ip, K4_DISCOVERY_PORT]);
        clients.Add(client);
      except
        on E: Exception do
        begin
          logger.Warn('[K4Discovery] Send from %s failed: %s', [ip, E.Message]);
          client.Free;
        end;
      end;
    end;

    // Collect replies across all interface sockets for TimeoutMs.
    StartTime := GetTickCount;
    while (clients.Count > 0) and ((GetTickCount - StartTime) < LongWord(TimeoutMs)) do
    begin
      for c := 0 to clients.Count - 1 do
      begin
        client := TIdUDPClient(clients[c]);
        try
          SetLength(RecvBuf, 1024);
          RecvLen := client.ReceiveBuffer(RecvBuf, PeerIP, PeerPort);

          if RecvLen > 0 then
          begin
            SetString(Reply, PAnsiChar(@RecvBuf[0]), RecvLen);
            logger.Debug('[K4Discovery] RX %d bytes from %s:%d = [%s]',
                         [RecvLen, PeerIP, PeerPort, Reply]);

            if ParseResponse(Reply, Parsed) then
            begin
              isDuplicate := False;
              for i := 0 to Result.Count - 1 do
                 if PK4DiscoveredRadio(Result[i])^.IPAddress = Parsed.IPAddress then
                    begin
                    isDuplicate := True;
                    Break;
                    end;

              if not isDuplicate then
              begin
                New(Radio);
                Radio^ := Parsed;
                Result.Add(Radio);
                logger.Info('[K4Discovery] Found %s serial %s at %s',
                            [Parsed.RigType, Parsed.SerialNumber, Parsed.IPAddress]);
              end;
            end
            else
              logger.Info('[K4Discovery] reply did not parse as K4: [%s]', [Reply]);
          end;
        except
          on E: Exception do
          begin
            // ReceiveTimeout on this socket -- move to the next interface.
          end;
        end;
      end;
    end;

    logger.Info('[K4Discovery] Discovery complete: %d interface(s) probed, %d radio(s) found',
                [clients.Count, Result.Count]);
  finally
    for c := 0 to clients.Count - 1 do
       TIdUDPClient(clients[c]).Free;
    clients.Free;
    TIdStack.DecUsage;
  end;
end;

initialization
  logger := TLogLogger.GetLogger('uK4Discovery');

end.
