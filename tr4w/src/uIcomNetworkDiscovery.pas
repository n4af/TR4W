unit uIcomNetworkDiscovery;

{
  Icom Network Radio Discovery

  Sends broadcast "Are You There" packets on the local network
  and collects "I Am Here" responses from Icom radios.

  Usage:
    var Radios: TList;
    Radios := TIcomNetworkDiscovery.DiscoverRadios(3000);
    // Process TDiscoveredRadio records from Radios
    // Caller must free the list and its items
}

interface

uses
  Windows, SysUtils, Classes,
  IdUDPClient, IdGlobal, IdSocketHandle,
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
  UDPClient: TIdUDPClient;
  Pkt: TControlPacket;
  IdBytes: TIdBytes;
  RecvBuf: TIdBytes;
  RecvLen: Integer;
  PeerIP: string;
  PeerPort: Word;
  StartTime: LongWord;
  Radio: ^TDiscoveredRadio;
  ResponsePkt: TControlPacket;
begin
  Result := TList.Create;

  UDPClient := TIdUDPClient.Create(nil);
  try
    UDPClient.BroadcastEnabled := True;
    UDPClient.Port := 0;  // Bind to any port
    UDPClient.ReceiveTimeout := 500;  // 500ms receive timeout for polling loop

    // Build "Are You There" packet
    FillChar(Pkt, SizeOf(Pkt), 0);
    Pkt.Len := ICOM_CONTROL_PKT_SIZE;
    Pkt.PktType := ICOM_PKT_ARE_YOU_THERE;
    Pkt.Seq := 1;
    Pkt.SentID := $12345678;  // Temporary ID for discovery
    Pkt.RcvdID := 0;

    // Convert to TIdBytes
    SetLength(IdBytes, SizeOf(Pkt));
    Move(Pkt, IdBytes[0], SizeOf(Pkt));

    // Send broadcast on port 50001
    try
      UDPClient.SendBuffer('255.255.255.255', ICOM_DEFAULT_CONTROL_PORT, IdBytes);
      logger.Info('[IcomDiscovery] Sent broadcast discovery on port %d',
                  [ICOM_DEFAULT_CONTROL_PORT]);
    except
      on E: Exception do
      begin
        logger.Error('[IcomDiscovery] Failed to send broadcast: %s', [E.Message]);
        Exit;
      end;
    end;

    // Collect responses for TimeoutMs
    StartTime := GetTickCount;
    while (GetTickCount - StartTime) < LongWord(TimeoutMs) do
    begin
      try
        SetLength(RecvBuf, 1024);
        RecvLen := UDPClient.ReceiveBuffer(RecvBuf, PeerIP, PeerPort);

        if RecvLen >= SizeOf(TControlPacket) then
        begin
          Move(RecvBuf[0], ResponsePkt, SizeOf(TControlPacket));

          if ResponsePkt.PktType = ICOM_PKT_I_AM_HERE then
          begin
            New(Radio);
            Radio^.IPAddress := PeerIP;
            Radio^.RadioName := '';  // Not available from I Am Here
            Radio^.CivAddress := 0; // Not available from I Am Here
            Radio^.RemoteId := ResponsePkt.SentID;
            Result.Add(Radio);

            logger.Info('[IcomDiscovery] Found radio at %s, remoteId=$%.8x',
                        [PeerIP, ResponsePkt.SentID]);
          end;
        end;
      except
        on E: Exception do
        begin
          // Timeout or other receive error - continue listening
        end;
      end;
    end;

    logger.Info('[IcomDiscovery] Discovery complete, found %d radio(s)',
                [Result.Count]);

  finally
    FreeAndNil(UDPClient);
  end;
end;

initialization
  logger := TLogLogger.GetLogger('uIcomNetworkDiscovery');
  logger.Level := All;

end.
