unit uWSJTX;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,  IdComponent, IdUDPBase, IdUDPServer, IdUDPClient, IdBaseComponent, IdSocketHandle,
  IdGlobal, IdStackConsts, StdCtrls, NetworkMessageUtils, DateUtils, StrUtils
{  ,VC       // For ContestExchange
  ,MainUnit // For ParseADIFRecord
  ,LogDupe  // For ClearContestExchange - Stuff is all over the place in this code! de NY4I
  ,uCTYDAT  // For ctyLocateCall
  ,utils_file // For tWriteFile }
  ,LOGRADIO
  ;

type
   TColorRec = record
      R: byte;
      G: byte;
      B: byte;
   end;
type
  TWSJTXServer = class(TObject)
  private
      udpServ : TIdUDPServer;
      UFreq, UModeRX, UModeTX, UDXCall, URSTs, UHeureDeb : string;
      UCall,ULoc : string;
      UIndex:integer;
      peerPort: word;
      SNR: LongInt;
      frequency: Int64; //QWord;
      firstTime: boolean;
      isConnected: boolean;
      colorsMult: TColorRec;
      colorsDupe: TColorRec;
      //radio: radioObject;
  protected
    procedure OnServerRead(ASender: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure OnBeforeBind(AHandle: TIdSocketHandle);
  public
    constructor Create; overload;
    //constructor Create(radio: radioObject); overload;
    procedure Start;    // May want to add the port number to a constructor - for now use default
    procedure Stop;
    destructor Destroy;
    procedure HighlightCall(sCall: string; color: integer; sId: string);
    procedure ClearColors(sId: string);
    property connected: boolean read isConnected;
    procedure SetDupeColor(bRed: byte; bGreen: byte; bBlue: byte);
    procedure SetMultColor(bRed: byte; bGreen: byte; bBlue: byte);

  end;

implementation

uses
    VC            // For ContestExchange
   ,MainUnit      // For ParseADIFRecord
   ,LogDupe       // For ClearContestExchange - Stuff is all over the place in this code! de NY4I
   ,uCTYDAT       // For ctyLocateCall
   ,utils_file    // For tWriteFile
   ,LOGSUBS2      // For LogContact
   ,LogStuff      // For CalculateQSOPoints
   ,LogEdit       // For ShowStationInformation and DetermineIfNewMult
   ,LOGWIND       // for GetBandMapBandModeFromFrequency
   ,TF            // for SetMainWindowText
   ;
// {$R *.dfm}

constructor TWSJTXServer.Create;
begin
   firstTime := true;
   udpServ := TIdUDPServer.Create(nil);
   udpServ.ThreadedEvent := true;
   udpServ.DefaultPort := 2237; // Make a config option
   udpServ.Bindings.Add.IP := '';
   udpServ.OnUDPRead := Self.OnServerRead;
   udpServ.OnBeforeBind := Self.OnBeforeBind;
   colorsDupe.R := $FF;
   colorsDupe.G := $00;
   colorsDupe.B := $00;

   colorsMult.R := $FF;
   colorsMult.G := $FF;
   colorsMult.B := $00;

end;

{constructor TWSJTXServer.Create(radio: radioObject);
begin
   inherited Create;
   Self.radio := radio;
end;
}
procedure TWSJTXServer.Start;
begin
   udpServ.Active := true;
end;

procedure TWSJTXServer.Stop;
begin
   udpServ.Active := false;
end;

destructor TWSJTXServer.Destroy;
begin
   udpServ.Active := false;
   FreeAndNil(udpServ);


end;

procedure TWSJTXServer.OnBeforeBind(AHandle: TIdSocketHandle);
begin
  AHandle.SetSockOpt( Id_SOL_SOCKET, Id_SO_REUSEADDR, Id_SO_True);
end;

procedure TWSJTXServer.OnServerRead(ASender: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  index: Integer;
  magic, schema, messageType: LongInt;
  id, mode, DXCall, report, TXMode, message, DXGrid, DEGrid, DECall, reportReceived: string;
  call : CallString;
  TXPower, comments, DXName, adif: string;

  isNew, TXEnabled, transmitting, Decoding: Boolean;
  tm: Longword;
  ztime: TDateTime;
  DT: Double;
  DF: Cardinal;
  date: TDateTime;
  {Ajout ici}
  slCQMessage: TStringList;
  Memomessage,locator: string;
  rst, RXDF, TXDF: integer;
  TempRXData: ContestExchange;
  lpNumberOfBytesWritten: Cardinal;
  inx: integer;
  TempMode: ModeType;
  TempBand: BandType;
  grid: string;

begin
     //FUDP.IdUDPServer1.Bindings := '127.0.0.1:2237,[::]:2237';
  index := 0;
  peerPort := ABinding.PeerPort;     {............................................récupération du port d'écoute}

//  peerPort := 2237;

  //DEBUGMSG('WSJTX >>> Datagram received - length: ' + IntToStr(Length(AData))); { DO NOT DELETE THIS }
   while index < Length(AData) do
   begin
      UnpackIntLongInt(AData, index, magic);
      //DEBUGMSG('WSJTX >>> index:' + IntToStr(index) + ' magic:$' + IntToHex(magic,8)); { DO NOT DELETE THIS }
      if (magic = LongInt($ADBCCBDA)) and (index < Length(AData)) then
         begin
         UnpackIntLongInt(AData, index, schema);
         if (schema = 2) and (index < Length(AData)) then
            begin
            UnpackIntLongInt(AData,index,messageType);
            UnpackIntString(AData,index,id);
            //DEBUGMSG('Message type:' + IntToStr(messageType) + ' from:[' + id + ']');   { DO NOT DELETE THIS }

            case messageType of
            0: begin
               DEBUGMSG('WSJTX >>> Heartbeat!');  { DO NOT DELETE THIS }
               SetMainWindowText(mweWSJTX,'WSJTX');
               Windows.ShowWindow(wh[mweWSJTX], SW_SHOW);
               isConnected := true;
               if firstTime then
                  begin
                  ClearColors(id);
                  firstTime := false;
                  end;
               end;
            1:         {............................................................Status}
               begin
               UnpackIntInt64(AData,index,frequency);
               UnpackIntString(AData,index,mode);
               UnpackIntString(AData,index,DXCall);
               UnpackIntString(AData,index,report);
               UnpackIntString(AData,index,TXMode);
               UnpackIntBoolean(AData,index,TXEnabled);
               UnpackIntBoolean(AData,index,transmitting);

               UnpackIntBoolean(AData,index,Decoding);
               UnpackIntLongInt(AData,index,RXDF);
               UnpackIntLongInt(AData,index,TXDF);
               UnpackIntString(AData,index,DECall);
               UnpackIntString(AData,index,DEGrid);
               UnpackIntString(AData,index,DXGrid);
              // Memomessage := IntToStr(frequency.Hi);
               {DEBUGMSG('WSJTX >>> Status: Frequency: ' + IntToStr(frequency) + ' Mode: ' + mode + ' DX Call: ' + DXCall
                                    + ' Report: ' + report + ' TX Mode: ' + TXMode + ' TX Enabled: ' + BoolToStr(TXEnabled)
                                    + ' Transmitting: ' + BoolToStr(transmitting) + ' Decoding: ' + BoolToStr(Decoding)
                                    + ' RXDF: ' + intToStr(RXDF) + ' TXDF: ' + intToStr(TXDF) + ' DECall: ' + DECall + ' DEGrid: ' + DEGrid
                                    + ' DXGrid: ' + DXGrid);
               }

               // if transmitting then
               //    FalarmeJT.SLedTransmit.Brush.Color:=clRed
               // else
               //   FalarmeJT.SLedTransmit.Brush.Color:=clGreen;
               end;

            2: begin        {............................................................Decode}
                           // This is where we need to look for CQ decodes and highlight the call by sending back
                           // a message to the UDP receiver in WSJT-X.
               UnpackIntBoolean(AData,index,isNew);
               UnpackIntLongword(AData,index,tm);
               ztime := IncMilliSecond(0,tm);
               UnpackIntLongInt(AData,index,SNR);
               UnpackIntDouble(AData,index,DT);
               UnpackIntLongword(AData,index,DF);
               UnpackIntString(AData,index,mode);
               UnpackIntString(AData,index,message);

               Memomessage :='Decode:'+' '+BoolToStr(isNew)+' '+FormatDateTime('hhmm',ztime)+' '+IntToStr(SNR)
                                   +' '+ FloatToStrF(DT, ffGeneral,4,1)+' '+IntToStr(DF)
                                   +' '+ mode +' '+ message +' '+ timeToStr(ztime) +' '+ FloatToStr(DT) +' '+ intToStr(tm);
               DEBUGMSG('WSJTX >>> ' + Memomessage);
               if MidStr(message,1,2) = 'CQ' then
                  begin
                  slCQMessage := TStringList.Create;
                  try
                     slCQMessage.Delimiter := ' ';              // cq ny4i el87     a1   OR cq fd ny4i el87  a1
                     slCQMessage.DelimitedText := message;
                     try
                        if slCQMessage[0] = 'CQ' then
                           begin
                           if slCQMessage.Count = 2 then
                              begin
                              DXCall := slCQMessage[1];
                              end
                           else if slCQMessage.Count > 2 then
                              begin
                              if length(slCQMessage[1]) = 2 then // most likely directed or contest
                                 begin
                                 DXCall := slCQMessage[2];
                                 grid := slCQMessage[3];
                                 end
                              else if slCQMessage.Count = 3 then
                                 begin  // standard CQ CALL GRID
                                 DXCall := slCQMessage[1];
                                 grid := slCQMessage[2];
                              end;
                           call := DXCall;

                           // Here we cheat a little bit on Frequency. The idea is that the status command is send enough that it gives
                           // us the frequency. SO turn the frequency into the band.
                           // We could also use the radio object to check
                           GetBandMapBandModeFromFrequency(frequency, TempBand, TempMode);
                           TempMode := Digital;   // override TempMode since we know it is digital. Until a contest differentiates between FT8 and FT4 that is ok

                           if  VisibleLog.CallIsADupe(call, TempBand, TempMode) then
                              begin
                              DEBUGMSG(DXCall + ' is a DUPE');
                              HighLightCall(message,1,id);
                              end
                           else if VisibleLog.DetermineIfNewMult(call, TempBand, TempMode) then
                              begin
                              DEBUGMSG(DXCall + ' is a MULT');
                              HighLightCall(message,2, id); // Pass back id as given to us
                              end;
                          end;
                        end;
                     except
                        DEBUGMSG('*** Error in stringList access - sl.Count = ' + IntToStr(slCQMessage.Count));
                        DEBUGMSG('*** Message = ' + message);
                     end;
                  finally
                     slCQMessage.Free;
                  end;


                  end;
               end;

            3: begin        {............................................................Clear}
               DEBUGMSG('WSJTX >>> Clear');
               end;

            5: begin        {..........I may grab this from the ADIF record so this would not be needed   QSO logged}
            {
               UnpackIntDateTime(AData,index,date);
               UnpackIntString(AData,index,DXCall);
               UnpackIntString(AData,index,DXGrid);
               UnpackIntQWord(AData,index,frequency);
               UnpackIntString(AData,index,mode);
               UnpackIntString(AData,index,report);
               UnpackIntString(AData,index,reportReceived);
               UnpackIntString(AData,index,TXPower);
               UnpackIntString(AData,index,comments);
               UnpackIntString(AData,index,DXName);

               DEBUGMSG('QSO logged: Date:' + FormatDateTime('dd-mmm-yyyy hh:mm:ss',date)
                               + ' DX Call:' + DXCall + ' DX Grid:' + DXGrid
                               + ' Frequency:' + IntToStr(frequency.Hi) + ' Mode:' + mode + ' Report sent: ' + report
                               + ' Report received:' + reportReceived + ' TX Power:' + TXPower
                               + ' Comments:' + comments + ' Name:' + DXName);
            }  end;
            6:
               begin
               DEBUGMSG('WSJT-X close message received'); // We may want to indicate it somehow on main screen
               SetMainWindowText(mweWSJTX,'');
               Windows.ShowWindow(wh[mweWSJTX], SW_HIDE);
               isConnected := false;
               end;
            10: begin
                DEBUGMSG('Received message 10');
                end;
            12: begin
               UnpackIntString(AData,index,adif);
               DEBUGMSG('WSJTX >>> ADIF Record to log: ' + adif);
               ClearContestExchange(TempRXData);
               if ParseADIFRecord(adif, TempRXData) then // processed a record if true
                  begin
                  ctyLocateCall(TempRXData.Callsign, TempRXData.QTH);
                  CalculateQSOPoints(TempRXData);
                  LogContact(TempRXData, true);

                  ShowStationInformation(@TempRXData.Callsign);
                  UpdateWindows;
                  end;
               end;
            else
               begin
               DEBUGMSG('WSJTX >>> Unrecognized message type:' + IntToStr(messageType));
               end;
         end;
      end;
    end;
  end;
end;

{
Highlight Callsign In   13                     quint32    Integer
                           Id (unique key)        utf8
                           Callsign               utf8
                           Background Color       QColor
                           Foreground Color       QColor
                           Highlight last         bool
}
procedure TWSJTXServer.HighlightCall(sCall: string; color: integer; sId: string);
var
   sBuffer: string;
   AData: TIdBytes;
   messageType, magic, schema: LongInt;
   id, Ip, message: String;
   colorType: byte;
begin
// Build a header for a message
   magic := $ADBCCBDA;
   schema := 2;
   messageType := 13;
   id := sID;
   colorType := 1; // RGB
   pack(AData, magic);            {.............................................Magic number}
   pack(AData, schema);          {..............................................Schema}
   Pack(AData,messageType);        {............................................MessageType}
   pack(AData,id);                   {..........................................ID}
   Pack(AData,Trim(sCall));

   if color = 1 then // DUPE  defaults to red - Add code to pull from config if there
      begin
      // Background QColor first
      Pack(AData,colorType); // RGB
      PackFF00(AData);   //Pack(AData,Word(65280));     // Alpha
      Pack(AData,Byte(colorsDupe.R)); Pack(AData,Byte(0)); // Red
      Pack(AData,Byte(colorsDupe.G)); Pack(AData,Byte(0)); // Green
      Pack(AData,Byte(colorsDupe.B)); Pack(AData,Byte(0)); // Blue
      PackFF00(AData); //Pack(AData,Word(65280));   // R
      Pack(AData,Word(0));     // Padding
      end
   else if color = 2 then // multiplier
      begin
      // Background QColor first

      Pack(AData,colorType);
      PackFF00(AData);   //Pack(AData,Word(65280));     // Alpha
      Pack(AData,Byte(colorsMult.R)); Pack(AData,Byte(0)); // Red
      Pack(AData,Byte(colorsMult.G)); Pack(AData,Byte(0)); // Green
      Pack(AData,Byte(colorsMult.B)); Pack(AData,Byte(0)); // Blue
      Pack(AData,Word(0));     // Padding
      end;

   // Foreground QColor
   // Black RGB(0,0,0)
   Pack(AData,colorType);
   PackFF00(AData); //Pack(AData,Word(65280));     // Alpha     // 65280 is FF 00 (255 in Big Endian
   Pack(AData,Word(0));   // R
   Pack(AData,Word(0));   // G
   Pack(AData,Word(0));   // B
   Pack(AData,Word(0));     // Padding

   Pack(AData,true);        // Highlight last only

   (*
   if color = 1 then // DUPE  defaults to red - Add code to pull from config if there
      begin
      // Background QColor first
      // Red  RGB(255,0,0)
      Pack(AData,colorType);
      PackFF00(AData);   //Pack(AData,Word(65280));     // Alpha
      PackFF00(AData); //Pack(AData,Word(65280));   // R
      Pack(AData,Word(0));     // G
      Pack(AData,Word(0));     // B
      Pack(AData,Word(0));     // Padding
      end
   else if color = 2 then // multiplier
      begin
      // Background QColor first
      // Yellow  RGB(255,255,0)
      Pack(AData,colorType);
      PackFF00(AData);   //Pack(AData,Word(65280));     // Alpha
      PackFF00(AData);     // R
      PackFF00(AData);     // G
      Pack(AData,Word(0)); // B
      Pack(AData,Word(0));     // Padding
      end;
    *)
   // Foreground QColor
   // Black RGB(0,0,0)
   Pack(AData,colorType);
   PackFF00(AData); //Pack(AData,Word(65280));     // Alpha     // 65280 is FF 00 (255 in Big Endian
   Pack(AData,Word(0));   // R
   Pack(AData,Word(0));   // G
   Pack(AData,Word(0));   // B
   Pack(AData,Word(0));     // Padding

   Pack(AData,true);        // Highlight last only

   DEBUGMSG('Sending command to highlight ' + Trim(sCall));
   udpServ.SendBuffer('127.0.0.1', PeerPort, AData);

end;

procedure TWSJTXServer.ClearColors(sId: string);
var
   sBuffer: string;
   AData: TIdBytes;
   messageType, magic, schema: LongInt;
   id, Ip, message: String;
   colorType: byte;
begin
// Build a header for a message
   magic := $ADBCCBDA;
   schema := 2;
   messageType := 13;
   id := sID;
   colorType := 1; // RGB
   pack(AData, magic);            {.............................................Magic number}
   pack(AData, schema);          {..............................................Schema}
   Pack(AData,messageType);        {............................................MessageType}
   pack(AData,id);                   {..........................................ID}
   Pack(AData,' ');                // blank call?


   // Background QColor first
   //
   Pack(AData,Byte(0));
   Pack(AData,Word(0));
   Pack(AData,Word(0));
   Pack(AData,Word(0));
   Pack(AData,Word(0));

   Pack(AData,Byte(0));
   Pack(AData,Word(0));
   Pack(AData,Word(0));
   Pack(AData,Word(0));
   Pack(AData,Word(0));


   Pack(AData,true);        // Highlight last only

   DEBUGMSG('Sending Reset Colors');
   udpServ.SendBuffer('127.0.0.1', PeerPort, AData);

end;

procedure TWSJTXServer.SetDupeColor(bRed: byte; bGreen: byte; bBlue: byte);
begin
   Self.colorsDupe.R := bRed;
   Self.colorsDupe.G := bGreen;
   Self.colorsDupe.B := bBlue;
end;

procedure TWSJTXServer.SetMultColor(bRed: byte; bGreen: byte; bBlue: byte);
begin
   Self.colorsMult.R := bRed;
   Self.colorsMult.G := bGreen;
   Self.colorsMult.B := bBlue;
end;

end.
