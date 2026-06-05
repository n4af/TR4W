unit uIcomNetworkDiscovery;

{
  Icom Network Radio Discovery

  Sends broadcast "Are You There" packets on the local network
  and collects "I Am Here" responses from Icom radios.

  Usage:
    var Radios: TList;
    Radios := TIcomNetworkDiscovery.DiscoverRadios(3000);
    // each item is a PDiscoveredRadio; the caller frees the items + the list.
}

interface

uses
  Windows, SysUtils, Classes,
  IdUDPClient, IdGlobal, IdSocketHandle, IdStack,
  IdUDPServer,
  uIcomNetworkTypes, Log4D;

type
  TIcomNetworkDiscovery = class(TObject)
  public
    class function DiscoverRadios(TimeoutMs: Integer = 3000): TList;
  end;

implementation

var
  logger: TLogLogger;

class function TIcomNetworkDiscovery.DiscoverRadios(TimeoutMs: Integer): TList;
var
  clients: TList;
  client: TIdUDPClient;
  Pkt: TControlPacket;
  SendBytes: TIdBytes;
  RecvBuf: TIdBytes;
  RecvLen: Integer;
  PeerIP: string;
  PeerPort: Word;
  StartTime: LongWord;
  ResponsePkt: TControlPacket;
  Radio: PDiscoveredRadio;
  localIPs: TStrings;
  ip: string;
  i, c: Integer;
  isDuplicate: Boolean;
begin
  Result := TList.Create;

  // Build the "Are You There" control packet once.
  FillChar(Pkt, SizeOf(Pkt), 0);
  Pkt.Len := ICOM_CONTROL_PKT_SIZE;
  Pkt.PktType := ICOM_PKT_ARE_YOU_THERE;
  Pkt.Seq := 1;
  Pkt.SentID := $12345678;   // temporary ID for discovery
  Pkt.RcvdID := 0;
  SetLength(SendBytes, SizeOf(Pkt));
  Move(Pkt, SendBytes[0], SizeOf(Pkt));

  clients := TList.Create;
  TIdStack.IncUsage;   // ensure the Indy stack so GStack.LocalAddresses is valid
  try
    localIPs := GStack.LocalAddresses;   // GStack-owned -- do NOT free

    // Broadcast the AYT out EACH local IPv4 interface.  A single
    // 255.255.255.255 send only leaves the default-route NIC, so an Icom on
    // another subnet is never reached; binding a socket per interface IP makes
    // the broadcast go out that NIC.  Mirrors the K4 per-interface discovery.
    for i := 0 to localIPs.Count - 1 do
    begin
      ip := localIPs[i];
      if (ip = '') or (ip = '127.0.0.1') or (Pos(':', ip) > 0) then
         Continue;   // skip blanks, loopback, and IPv6

      client := TIdUDPClient.Create(nil);
      try
        client.BoundIP := ip;             // send out this specific interface
        client.BroadcastEnabled := True;
        client.ReceiveTimeout := 150;
        client.SendBuffer('255.255.255.255', ICOM_DEFAULT_CONTROL_PORT, SendBytes);
        logger.Info('[IcomDiscovery] Sent AYT from %s to 255.255.255.255:%d',
                    [ip, ICOM_DEFAULT_CONTROL_PORT]);
        clients.Add(client);
      except
        on E: Exception do
        begin
          logger.Warn('[IcomDiscovery] Send from %s failed: %s', [ip, E.Message]);
          client.Free;
        end;
      end;
    end;

    // Collect "I Am Here" replies across all interface sockets for TimeoutMs.
    StartTime := GetTickCount;
    while (clients.Count > 0) and ((GetTickCount - StartTime) < LongWord(TimeoutMs)) do
    begin
      for c := 0 to clients.Count - 1 do
      begin
        client := TIdUDPClient(clients[c]);
        try
          SetLength(RecvBuf, 1024);
          RecvLen := client.ReceiveBuffer(RecvBuf, PeerIP, PeerPort);

          if RecvLen >= SizeOf(TControlPacket) then
          begin
            Move(RecvBuf[0], ResponsePkt, SizeOf(TControlPacket));
            if ResponsePkt.PktType = ICOM_PKT_I_AM_HERE then
            begin
              isDuplicate := False;
              for i := 0 to Result.Count - 1 do
                 begin
                 if PDiscoveredRadio(Result[i])^.IPAddress = PeerIP then
                    begin
                    isDuplicate := True;
                    Break;
                    end;
                 end;

              if not isDuplicate then
              begin
                New(Radio);
                Radio^.IPAddress := PeerIP;
                Radio^.RadioName := '';   // not carried in "I Am Here"
                Radio^.CivAddress := 0;
                Radio^.RemoteId := ResponsePkt.SentID;
                Result.Add(Radio);
                logger.Info('[IcomDiscovery] Found radio at %s, remoteId=$%.8x',
                            [PeerIP, ResponsePkt.SentID]);
              end;
            end;
          end;
        except
          on E: Exception do
          begin
            // ReceiveTimeout on this socket -- move to the next interface.
          end;
        end;
      end;
    end;

    logger.Info('[IcomDiscovery] Discovery complete: %d interface(s) probed, %d radio(s) found',
                [clients.Count, Result.Count]);
  finally
    for c := 0 to clients.Count - 1 do
       begin
       TIdUDPClient(clients[c]).Free;
       end;
    clients.Free;
    TIdStack.DecUsage;
  end;
end;

initialization
  logger := TLogLogger.GetLogger('uIcomNetworkDiscovery');

end.
