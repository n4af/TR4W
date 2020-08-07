{
 Copyright Thomas M. Schaefer, NY4I (c) 2020.
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
unit uWSJTX;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,  IdComponent, IdUDPBase, IdUDPServer, IdTCPServer,IdUDPClient, IdContext,
  IdBaseComponent, IdSocketHandle, IdGlobal, IdStackConsts, StdCtrls,
  NetworkMessageUtils, DateUtils, StrUtils, LOGRADIO, IdThreadSafe, IdThread
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
      tcpServ: TIdTCPServer;
      UModeRX, UModeTX, UDXCall, URSTs, UHeureDeb : string;
      started: boolean;
      ULoc : string;
      peerPort: word;
      FUDPPort: integer;
      FTCPPort: integer;
      SNR: LongInt;
      frequency: Int64;
      firstTime: boolean;
      isConnected: boolean;
      colorsMultFore: TColorRec;
      colorsDupeFore: TColorRec;
      colorsMultBack: TColorRec;
      colorsDupeBack: TColorRec;
      buffer: TIdBytes;
      sBuffer: string;
      TXKludge: boolean;
      txKludgeStart: TDateTime;
      RXKludge: boolean;
      FSendColorization: boolean;
      rxKludgeStart: TDateTime;
      processingCmdSplit: boolean;
      processingCmdSetTXFreq: boolean;
      processingCmdQSXSplit: boolean;
      processingCmdSetFreq: boolean;
      requestedTXFreq: extended;
      procedure SetUDPPort(nPort: integer);
      procedure SetTCPPort(nPort: integer);
      function GetNextADIFField(var sBuffer: string; var fieldName: string; var fieldValue: string): boolean;
  protected
    procedure OnServerRead(ASender: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure OnBeforeBind(AHandle: TIdSocketHandle);
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure IdTCPServer1Connect(AContext: TIdContext);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);
  public
    constructor Create; overload;
    constructor Create(nUDPPort: integer; nTCPPort: integer); overload;
    //constructor Create(radio: radioObject); overload;
    procedure Start;    // May want to add the port number to a constructor - for now use default
    procedure Stop;
    destructor Destroy;
    procedure HighlightCall(sCall: string; color: integer; sId: string);
    procedure ClearColors(sId: string);
    property connected: boolean read isConnected;

    //procedure SetDupeBackgroundColor(bRed: byte; bGreen: byte; bBlue: byte);
    procedure SetDupeBackgroundColor(rgb: cardinal);
    //procedure SetMultBackgroundColor(bRed: byte; bGreen: byte; bBlue: byte);
    procedure SetMultBackgroundColor(rgb: cardinal);

   //procedure SetDupeForegroundColor(bRed: byte; bGreen: byte; bBlue: byte);
    procedure SetDupeForegroundColor(rgb: cardinal);

    //procedure SetMultForegroundColor(bRed: byte; bGreen: byte; bBlue: byte);
    procedure SetMultForegroundColor(rgb: cardinal);

    function ConvertSNRToRST(snr: integer): integer;
    procedure Display(p_sender : String; p_message : string);

    Property UDPPort: integer read FUDPPort write SetUDPPort;

    Property TCPPort: integer read FTCPPort write SetTCPPort;

    Property SendColorization: boolean read FSendColorization write FSendColorization;


  end;

const KLUDGESECONDSV = 2;
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
   ,utils_text
   ,LogK1EA       // to access tPTTViaCommand
   ;
// {$R *.dfm}

constructor TWSJTXServer.Create;
begin
   started := false;
   FSendColorization := true;
   firstTime := true;
   udpServ := TIdUDPServer.Create(nil);
   // udpServ.Binding.SetSockOpt(Id_SOL_SOCKET,Id_SO_REUSEADDR,Id_SO_True);
   udpServ.ThreadedEvent := true;
   if FUDPPort = 0 then
      begin
      FUDPPort := 2237;
   end;

   if FTCPPort = 0 then
      begin
      FTCPPort := 52002;
      end;

   udpServ.DefaultPort := FUDPPort;
   udpServ.Bindings.Add.IP := '';
   udpServ.OnUDPRead := Self.OnServerRead;
   udpServ.OnBeforeBind := Self.OnBeforeBind;
   colorsDupeBack.R := $FF;
   colorsDupeBack.G := $00;
   colorsDupeBack.B := $00;

   colorsMultBack.R := $FF;
   colorsMultBack.G := $FF;
   colorsMultBack.B := $00;

   colorsDupeFore.R := $00;
   colorsDupeFore.G := $00;
   colorsDupeFore.B := $00;

   colorsMultFore.R := $00;
   colorsMultFore.G := $00;
   colorsMultFore.B := $00;

   tcpServ := TIdTCPServer.Create(nil);
   tcpServ.OnExecute := Self.IdTCPServer1Execute;
   tcpServ.OnConnect := Self.IdTCPServer1Connect;
   tcpServ.OnDisconnect := Self.IdTCPServer1Disconnect;
end;

constructor TWSJTXServer.Create(nUDPPort: integer; nTCPPort: integer);
begin
   FUDPPort := nUDPPort;
   FTCPPort := nTCPPort;
   inherited Create;
end;

{constructor TWSJTXServer.Create(radio: radioObject);
begin
   inherited Create;
   Self.radio := radio;
end;
}
procedure TWSJTXServer.Start;
begin
   if not started then
      begin
      udpServ.Active := true;
      started := true;

      tcpServ.Bindings.Clear;
      tcpServ.MaxConnections := 1; // Just allow the single client
      tcpServ.Bindings.Add.Port := FTCPPort;
      tcpServ.Active := true;
      end;
end;

procedure TWSJTXServer.Stop;
begin
   if started then
      begin
      udpServ.Active := false;
      tcpServ.IOHandler.Shutdown;
      tcpServ.Active := false;
      started := false;
      end;
end;

destructor TWSJTXServer.Destroy;
begin
   udpServ.Active := false;
   FreeAndNil(udpServ);

   tcpServ.IOHandler.Shutdown;
   tcpServ.Active := false;
   FreeAndNil(tcpServ);


end;

procedure TWSJTXServer.SetUDPPort(nPort: integer);
begin
   Self.FUDPPort := nPort;
   if Self.udpServ.Active then
      begin
      Self.udpServ.active := false;
      udpServ.DefaultPort := Self.FUDPPort;
      udpServ.Active := true;
      end;
end;

procedure TWSJTXServer.SetTCPPort(nPort: integer);
begin
   Self.FTCPPort := nPort;
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
  Memomessage: string;
  RXDF, TXDF: integer;
  TempRXData: ContestExchange;
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
      Unpack(AData, index, magic);
      //DEBUGMSG('WSJTX >>> index:' + IntToStr(index) + ' magic:$' + IntToHex(magic,8)); { DO NOT DELETE THIS }
      if (magic = LongInt($ADBCCBDA)) and (index < Length(AData)) then
         begin
         Unpack(AData, index, schema);
         if (schema = 2) and (index < Length(AData)) then
            begin
            Unpack(AData,index,messageType);
            Unpack(AData,index,id);
            if logger.IsTraceEnabled then
               begin
               logger.trace('Message type:' + IntToStr(messageType) + ' from:[' + id + ']');   { DO NOT DELETE THIS }
               end;

            case messageType of
            0: begin
               logger.trace('WSJTX >>> Heartbeat!');  { DO NOT DELETE THIS }
               if logger.IsTraceEnabled then
                  begin
                  logger.trace('In UDP Heartbeat, Radio frequency = ' + IntToStr(radio1.CurrentStatus.VFO[VFOA].Frequency));
                  end;
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
               Unpack(AData,index,frequency);
               Unpack(AData,index,mode);
               Unpack(AData,index,DXCall);
               Unpack(AData,index,report);
               Unpack(AData,index,TXMode);
               Unpack(AData,index,TXEnabled);
               Unpack(AData,index,transmitting);

               Unpack(AData,index,Decoding);
               Unpack(AData,index,RXDF);
               Unpack(AData,index,TXDF);
               Unpack(AData,index,DECall);
               Unpack(AData,index,DEGrid);
               Unpack(AData,index,DXGrid);
               if logger.IsTraceEnabled then
                  begin
                  logger.trace('WSJTX Status>>> Frequency: ' + IntToStr(frequency) + ' Mode: ' + mode + ' DX Call: ' + DXCall
                                    + ' Report: ' + report + ' TX Mode: ' + TXMode + ' TX Enabled: ' + BooleanToStr(TXEnabled)
                                    + ' Transmitting: ' + BooleanToStr(transmitting) + ' Decoding: ' + BooleanToStr(Decoding)
                                    + ' RXDF: ' + intToStr(RXDF) + ' TXDF: ' + intToStr(TXDF) + ' DECall: ' + DECall + ' DEGrid: ' + DEGrid
                                    + ' DXGrid: ' + DXGrid);
                  end;
               if transmitting then
                  begin
                  logger.debug('Calling station ' + DXCall + ' TotalContacts = ' + IntToStr(TotalContacts));
                  PutCalltoCallWindow(DXCall);
                  DisplayBeamHeading(DXCall,DXGrid);
                  end;
               end;

            2: begin        {............................................................Decode}
                           // This is where we need to look for CQ decodes and highlight the call by sending back
                           // a message to the UDP receiver in WSJT-X.
               Unpack(AData,index,isNew);
               Unpack(AData,index,tm);
               ztime := IncMilliSecond(0,tm);
               Unpack(AData,index,SNR);
               Unpack(AData,index,DT);
               Unpack(AData,index,DF);
               Unpack(AData,index,mode);
               Unpack(AData,index,message);

              if logger.IsTraceEnabled then
                 begin
                 Memomessage :='Decode:'+' '+BoolToStr(isNew)+' '+FormatDateTime('hhmm',ztime)+' '+IntToStr(SNR)
                                   +' '+ FloatToStrF(DT, ffGeneral,4,1)+' '+IntToStr(DF)
                                   +' '+ mode +' '+ message +' '+ timeToStr(ztime) +' '+ FloatToStr(DT) +' '+ intToStr(tm);
                 logger.trace('WSJTX Decode >>> ' + Memomessage);
                 end;
                 
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

                           // Here we cheat a little bit on Frequency. The idea is that the status command is sent enough that it gives
                           // us the frequency. SO turn the frequency into the band.
                           // We could also use the radio object to check
                           GetBandMapBandModeFromFrequency(frequency, TempBand, TempMode);
                           TempMode := Digital;   // override TempMode since we know it is digital. Until a contest differentiates between FT8 and FT4 that is ok

                           if  VisibleLog.CallIsADupe(call, TempBand, TempMode) then
                              begin
                              logger.trace(DXCall + ' is a DUPE');
                              HighLightCall(message,1,id);
                              end
                           else if VisibleLog.DetermineIfNewMult(call, TempBand, TempMode) then
                              begin
                              logger.trace(DXCall + ' is a MULT');
                              HighLightCall(message,2, id); // Pass back id as given to us
                              end;
                          end;
                        end;
                     except
                        logger.Error('*** Error in stringList access - sl.Count = ' + IntToStr(slCQMessage.Count));
                        logger.Error('*** Message = ' + message);
                     end;
                  finally
                     slCQMessage.Free;
                  end;


                  end;
               end;

            3: begin        {............................................................Clear}
               logger.Trace('WSJTX >>> Clear');
               end;

            5: begin        {..........I may grab this from the ADIF record so this would not be needed   QSO logged}

               Unpack(AData,index,date);
               Unpack(AData,index,DXCall);
               Unpack(AData,index,DXGrid);
               Unpack(AData,index,frequency);
               Unpack(AData,index,mode);
               Unpack(AData,index,report);
               Unpack(AData,index,reportReceived);
               Unpack(AData,index,TXPower);
               Unpack(AData,index,comments);
               Unpack(AData,index,DXName);

               logger.Trace('QSO logged: Date:' + FormatDateTime('dd-mmm-yyyy hh:mm:ss',date)
                               + ' DX Call:' + DXCall + ' DX Grid:' + DXGrid
                               + ' Frequency:' + IntToStr(frequency) + ' Mode:' + mode + ' Report sent: ' + report
                               + ' Report received:' + reportReceived + ' TX Power:' + TXPower
                               + ' Comments:' + comments + ' Name:' + DXName);
              end;
            6:
               begin
               logger.Info('WSJT-X close message received'); // We may want to indicate it somehow on main screen
               SetMainWindowText(mweWSJTX,'');
               Windows.ShowWindow(wh[mweWSJTX], SW_HIDE);
               isConnected := false;
               end;
            10: begin
                logger.Trace('Received message 10');
                end;
            12: begin                         // Note that ParseADIFRecord has some logic to determine where to put the gridsquare
                if logger.IsDebugEnabled then
                   begin
                   logger.debug('TotalContacts at start of uWSJTX ADIF UDP message = ' + IntToStr(TotalContacts));
                   end;
                Unpack(AData,index,adif);
               logger.Trace('WSJTX >>> ADIF Record to log: ' + adif);
               ClearContestExchange(TempRXData);

               if ParseADIFRecord(adif, TempRXData) then // processed a record if true
                  begin
                  ctyLocateCall(TempRXData.Callsign, TempRXData.QTH);

                  if DoingDXMults then
                     begin
                     GetDXQTH(TempRXData);
                     end;
                  if DoingPrefixMults then
                     begin
                     SetPrefix(TempRXData);
                     end;

                  //CalculateQSOPoints(TempRXData);
                   if logger.IsDebugEnabled then
                   begin
                   logger.debug('TotalContacts right before update of NumberSent in uWSJTX ADIF UDP message = ' + IntToStr(TotalContacts));
                   end;
                  //TempRXData.NumberSent := TotalContacts;
                  //LogContact(TempRXData, true);
                  if ParametersOkay(TempRXData.Callsign, TempRXData.QTHString, ActiveBand, ActiveMode, ActiveRadioPtr.LastDisplayedFreq {LastDisplayedFreq[ActiveRadio]}, TempRXData) then
                     begin
                     ReceivedData.ceSearchAndPounce := OpMode = SearchAndPounceOpMode;
                     ReceivedData.ceComputerID := ComputerID;
                     LogContact(TempRXData, True);
                     tElapsedTimeFromLastQSO := Windows.GetTickCount;
                     UpdateWindows;
                     //ShowStationInformation(@TempRXData.Callsign);
                     ClearContestExchange(TempRXData);
                     LastTwoLettersCrunchedOn := '';
                     CallAlreadySent := False;
                     ExchangeHasBeenSent := False;
                     EditingCallsignSent := False;
                     SeventyThreeMessageSent := False;
                     EscapeDeletedCallEntry := CallWindowString;
                     tCleareCallWindow;
                     tCleareExchangeWindow;
                     tCallWindowSetFocus;
                     CleanUpDisplay;
                     end;

                  //tCleareCallWindow;

                  //ShowStationInformation(@TempRXData.Callsign);
                  //UpdateWindows;
                  end;
               end;
            else
               begin
               logger.Error('WSJTX >>> Unrecognized message type:' + IntToStr(messageType));
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
   AData: TIdBytes;
   messageType, magic, schema: LongInt;
   id: String;
   colorType: byte;
begin

   if not FSendColorization then
      begin
      Exit;
      end;
// Build a header for a message

   // Send colors for Dupes (QSOB4)
   
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
      PackFF00(AData);    // Alpha
      Pack(AData,Byte(colorsDupeBack.R)); Pack(AData,Byte(0)); // Red
      Pack(AData,Byte(colorsDupeBack.G)); Pack(AData,Byte(0)); // Green
      Pack(AData,Byte(colorsDupeBack.B)); Pack(AData,Byte(0)); // Blue
      PackFF00(AData); //Pack(AData,Word(65280));   // R
      Pack(AData,Word(0));     // Padding

      // foreground
      Pack(AData,colorType); // RGB
      PackFF00(AData);    // Alpha
      Pack(AData,Byte(colorsDupeFore.R)); Pack(AData,Byte(0)); // Red
      Pack(AData,Byte(colorsDupeFore.G)); Pack(AData,Byte(0)); // Green
      Pack(AData,Byte(colorsDupeFore.B)); Pack(AData,Byte(0)); // Blue
      PackFF00(AData); //Pack(AData,Word(65280));   // R
      Pack(AData,Word(0));     // Padding
      end

   else if color = 2 then // multiplier
      begin               // Background QColor first
      Pack(AData,colorType);
      PackFF00(AData);   //Pack(AData,Word(65280));     // Alpha
      Pack(AData,Byte(colorsMultBack.R)); Pack(AData,Byte(0)); // Red
      Pack(AData,Byte(colorsMultBack.G)); Pack(AData,Byte(0)); // Green
      Pack(AData,Byte(colorsMultBack.B)); Pack(AData,Byte(0)); // Blue
      Pack(AData,Word(0));     // Padding
      Pack(AData,colorType);
      PackFF00(AData);   //Pack(AData,Word(65280));     // Alpha
      Pack(AData,Byte(colorsMultFore.R)); Pack(AData,Byte(0)); // Red
      Pack(AData,Byte(colorsMultFore.G)); Pack(AData,Byte(0)); // Green
      Pack(AData,Byte(colorsMultFore.B)); Pack(AData,Byte(0)); // Blue
      Pack(AData,Word(0));     // Padding
      end;

   Pack(AData,true);        // Highlight last only
   logger.trace('Sending command to highlight ' + Trim(sCall));
   udpServ.SendBuffer('127.0.0.1', PeerPort, AData);


end;


procedure TWSJTXServer.ClearColors(sId: string);

var
   AData: TIdBytes;
   messageType, magic, schema: LongInt;
   id: String;
   colorType: byte;

begin

// Build a header for a message

   magic := $ADBCCBDA;

   schema := 2;
   messageType := 13;
   id := sID;

   colorType := 0; // RGB

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


   logger.trace('Sending Reset Colors');

   udpServ.SendBuffer('127.0.0.1', PeerPort, AData);


end;


(*procedure TWSJTXServer.SetDupeBackgroundColor(bRed: byte; bGreen: byte; bBlue: byte);
begin
   Self.colorsDupeBack.R := bRed;
   Self.colorsDupeBack.G := bGreen;
   Self.colorsDupeBack.B := bBlue;
end;
*)
procedure TWSJTXServer.SetDupeBackgroundColor(rgb: cardinal);
//var rgb: cardinal;
begin
   //rgb := ColorToRGB(tc);
   logger.Debug('Setting DupeBackgroundColor to %d',[rgb]);
   Self.colorsDupeBack.R := GetRValue(rgb);
   Self.colorsDupeBack.G := GetGValue(rgb);
   Self.colorsDupeBack.B := GetBValue(rgb);
end;

{
procedure TWSJTXServer.SetMultBackgroundColor(bRed: byte; bGreen: byte; bBlue: byte);
begin
   Self.colorsMultBack.R := bRed;
   Self.colorsMultBack.G := bGreen;
   Self.colorsMultBack.B := bBlue;
end;
}
procedure TWSJTXServer.SetMultBackgroundColor(rgb: cardinal);
//var rgb: cardinal;
begin
   //rgb := ColorToRGB(tc);
   logger.Debug('Setting MultBackgroundColor to %d',[rgb]);
   Self.colorsMultBack.R := GetRValue(rgb);
   Self.colorsMultBack.G := GetGValue(rgb);
   Self.colorsMultBack.B := GetBValue(rgb);
end;

{
procedure TWSJTXServer.SetDupeForegroundColor(bRed: byte; bGreen: byte; bBlue: byte);
begin
   Self.colorsDupeFore.R := bRed;
   Self.colorsDupeFore.G := bGreen;
   Self.colorsDupeFore.B := bBlue;
end;
}
procedure TWSJTXServer.SetDupeForegroundColor(rgb: cardinal);
//var rgb: cardinal;
begin
   //rgb := ColorToRGB(tc);
   logger.Debug('Setting DupeForegroundColor to %d',[rgb]);
   Self.colorsDupeFore.R := GetRValue(rgb);
   Self.colorsDupeFore.G := GetGValue(rgb);
   Self.colorsDupeFore.B := GetBValue(rgb);
end;
{
procedure TWSJTXServer.SetMultForegroundColor(bRed: byte; bGreen: byte; bBlue: byte);
begin
   Self.colorsMultFore.R := bRed;
   Self.colorsMultFore.G := bGreen;
   Self.colorsMultFore.B := bBlue;
end;
}
procedure TWSJTXServer.SetMultForegroundColor(rgb: cardinal);
//var rgb: cardinal;
begin
   //rgb := ColorToRGB(tc);
   logger.Debug('Setting MultForegroundColor to %d',[rgb]);
   Self.colorsMultFore.R := GetRValue(rgb);
   Self.colorsMultFore.G := GetGValue(rgb);
   Self.colorsMultFore.B := GetBValue(rgb);
end;

procedure TWSJTXServer.IdTCPServer1Execute(AContext: TIdContext);
var
    Port          : Integer;
    PeerPort      : Integer;
    PeerIP        : string;

    msgFromClient : string;
    msgToClient   : string;
    bytesWritten: integer;
    sFreq: string;
    sLen: string;
    sDebug: string;
    s: string;
    sReply: string;

    nPos, len, n0, n1, newEnd: integer;
    freq: extended;
    fieldName, fieldValue: string;


begin
    // ... get message from client
    try
    AContext.Connection.IOHandler.ReadBytes(buffer,-1,true);
    sBuffer := BytesToString(buffer);
    RemoveBytes(buffer,length(sBuffer));


    // ... getting IP address, Port and PeerPort from Client that connected
    peerIP    := AContext.Binding.PeerIP;
    peerPort  := AContext.Binding.PeerPort;

    // ... message log
    Display('CLIENT', '(Peer=' + PeerIP + ':' + IntToStr(PeerPort) + ') ' + sBuffer);
    // ...

    { The TX and RX Kludge business is just that...a kludge. The problem is that WSJT-X wants to see the effected state change
      (TX on in response to a CmdTX or RX on in response to a CmdRX) in one second. Due to the polling interval of the attached radio
      we may not have a reply that fast. If WSJT-X does not get that, it aborts the connection. So we fool it. When the TX status
      change is requested, we force it to be what WSJT-X wants for 5 seconds to give us plenty of time to get the status from the radio.
      Not a great system but short of a much faster indication if we are transmitting, this seems to work.
      Work should be done to speed up the actual state change notification so this can be a truer indication or at least the
      timer lowered from 5 seconds.   // NY4I wrote this and the kludge--lest anyone else get blamed for this nastiness...
    }
   while Self.GetNextADIFField(sBuffer,fieldName, fieldValue) do
      begin
      if TXKludge then
         begin
         if SecondsBetween(txKludgeStart,Now) > KLUDGESECONDSV then
            begin
            TXKludge := false;
            end
         else
            begin
            logger.trace('TXKludge is true');
            end;
         end;

      if RXKludge then
         begin
         if SecondsBetween(rxKludgeStart,Now) > KLUDGESECONDSV then
            begin
            RXKludge := false;
            end
         else
            begin
            logger.trace('RXKludge is true');
            end;
         end;

      if fieldValue = 'CmdGetFreq' then
         begin
         if (ActiveRadioPtr.RadioModel = NoInterfacedRadio) or
            (radio1.CurrentStatus.VFO[VFOA].Frequency = 0) then
            begin
            logger.error('**** radio1.CurrentStatus.VFO[VFOA].Frequency = 0');
            logger.trace('Sending VFOA frequency as .000');
            AContext.Connection.IOHandler.Write('<CmdFreq:4>.000');
            end
         else
            begin
            sFreq := SysUtils.FormatFloat(',0.000',radio1.CurrentStatus.VFO[VFOA].Frequency/1000);
            logger.Trace('Sending VFOA frequency: ' + SysUtils.Format('<CmdFreq:%u>%s',[length(sFreq),sFreq]));
            AContext.Connection.IOHandler.Write(SysUtils.Format('<CmdFreq:%u>%s',[length(sFreq),sFreq]));
            end;
         end
      else if fieldValue = 'CmdSetFreq' then
         begin
         processingCmdSetFreq := true;
         logger.Trace('Setting processingCmdSetFreq');
         end
      else if fieldName = 'xcvrfreq' then
         begin
         freq := SafeFloat(fieldValue);
         if processingCmdSetFreq then // Set Main VFO
            begin
            logger.Trace('Setting VFOA to frequency ' + IntToStr(Trunc(freq)));
            ActiveRadioPtr.SetRadioFreq(Trunc(freq * 1000),Digital,'A');  // A is for VFO A
            processingCmdSetFreq := false;
            logger.Trace('Resetting processingCmdSetFreq');
            end
         else if processingCmdSetTXFreq then
            begin
            logger.Trace('[processingCmdSetTXFreq] Setting VFOB to frequency ' + IntToStr(Trunc(freq)));
            Self.requestedTXFreq := Trunc(freq * 1000);
            ActiveRadioPtr.SetRadioFreq(Trunc(freq * 1000),Digital,'B');  // B is for VFO B
            processingCmdSetTXFreq := false;
            logger.Trace('Resetting processingCmdSetTXFreq');
            end
         else if processingCmdQSXSplit then
            begin
            logger.Trace('[processingCmdQSXSplit] Setting VFOB to frequency ' + IntToStr(Trunc(freq)));
            Self.requestedTXFreq := Trunc(freq * 1000);
            radio1.SetRadioFreq(Trunc(freq * 1000),Digital,'B');  // B is for VFO B
            ActiveRadioPtr.PutRadioIntoSplit;
            processingCmdQSXSplit := false;
            logger.Trace('Resetting processingCmdQSXSplit');
            end
         else
            begin
            logger.Debug('<***** ERROR ******> Received xcvrfreq to ' + IntToStr(Trunc(freq)) + ' without state variable');
            end;

         end
      else if fieldValue = 'CmdSetTXFreq' then
         begin
         processingCmdSetTXFreq := true;
         logger.Trace('Setting processingCmdSetTXFreq');
         end
      else if fieldName = 'SuppressDual' then
         begin
         end
      else if fieldValue = 'CmdSetMode' then
         begin
         logger.Trace('CmdSetMode received ' + sBuffer);
         end
      else if fieldValue = 'CmdSendSplit' then
         begin
         if ActiveRadioPtr.CurrentStatus.Split then
            begin
            AContext.Connection.IOHandler.Write('<CmdSplit:2>ON');
            logger.trace('Sending ' + '<CmdSplit:2>ON');
            end
         else
            begin
            AContext.Connection.IOHandler.Write('<CmdSplit:3>OFF');
            logger.trace('Sending ' + '<CmdSplit:3>OFF');
            end;
         end
      else if fieldValue = 'CmdRX' then     // No reply
         begin
         if not tPTTViaCommand then
            begin
            QuickDisplay('PTT VIA COMMANDS (CTRL-J) option must be true for WSJT-X use - Setting to true');
            tPTTViaCommand := true;
            end;
         logger.Debug('<<<<<<<<<<<<<<<<<<<<< PTT OFF *********************');
         tPTTVIACAT(false);
         TXKludge := false;
         RXKludge := true;
         rxKludgeStart := Now;
         end
      else if fieldValue = 'CmdTX' then
         begin
         if not tPTTViaCommand then
            begin
            QuickDisplay('PTT VIA COMMANDS (CTRL-J) option must be true for WSJT-X use - Setting to true');
            logger.Info('Set tPTTViaCommand for user');
            tPTTViaCommand := true;
            end;
         logger.debug('>>>>>>>>>>>>>>>>>>> PTT ON *********************');
         tPTTVIACAT(true);
         txKludgeStart := Now;
         TXKludge := true;
         RXKludge := false;
         end
      else if fieldValue = 'CmdSendMode' then
         begin
         case ActiveRadioPtr.CurrentStatus.ExtendedMode of
            eAM: s := 'AM';
            eCW: s := 'CW';
            eCW_R: s := 'CW-R';
            eDATA_R: s := 'DATA-L';
            eDATA: s := 'DATA-U';
            eFM: s := 'FM';
            eLSB: s := 'LSB';
            eUSB: s := 'USB';
            eRTTY: s := 'RTTY';
            eRTTY_R: s := 'RTTY-R';
            ePSK31: s := 'DATA-U';
            else
               begin
               logger.Error('<***** ERROR ******> Mode not handled in SENDMODE ' + IntToStr(Ord(ActiveRadioPtr.CurrentStatus.ExtendedMode)));
               s := 'DATA-U';
               end;
            end;
         AContext.Connection.IOHandler.Write(SysUtils.Format('<CmdMode:%u>%s',[length(s),s]));
         logger.Trace('Sending ' + SysUtils.Format('<CmdMode:%u>%s',[length(s),s]));
         end
      else if fieldValue = 'CmdSendTx' then
         begin
         if TXKludge then
            begin
            sReply := '<CmdTX:2>ON';
            end
         else if RXKludge then
            begin
            sReply := '<CmdTX:3>OFF';
            end
         else
            begin
            if  ActiveRadioPtr.CurrentStatus.TXOn then
               begin
               sReply := '<CmdTX:2>ON';
               end
            else
               begin
               sReply := '<CmdTX:3>OFF';
               end;
            end;
         sDebug := '';
         if TXKludge then
            begin
            sDebug := ' TXKludge ';
            end;
         if RXKludge then
            begin
            sDebug := sDebug + ' RXKludge ';
            end;
         if Length(sDebug) > 0 then
            begin
            sDebug := '[' + sDebug + '] ';
            end;
         sDebug := sDebug + 'Sending ' + sReply;
         logger.Trace(sDebug);
         AContext.Connection.IOHandler.Write(sReply);
         end
      else if fieldValue = 'CmdGetTXFreq' then
         begin             // Return VFO B
         if (ActiveRadioPtr.RadioModel = NoInterfacedRadio) or
            (ActiveRadioPtr.CurrentStatus.VFO[VFOB].Frequency = 0) then
            begin
            //DEBUGMSG('**** radio1.CurrentStatus.VFO[VFOB].Frequency = 0');
            logger.error('       ActiveRadioPtr.CurrentStatus.VFO[VFOB] = ' + SysUtils.FormatFloat(',0.000',ActiveRadioPtr.CurrentStatus.VFO[VFOB].Frequency/1000));
            logger.trace('Sending VFOB frequency as requestedTXFreq since we do not have frequency [' + SysUtils.Format('<CmdFreq:%u>%s',[length(sFreq),sFreq]) + ']');
            sFreq := SysUtils.FormatFloat(',0.000',Self.requestedTXFreq/1000);
            AContext.Connection.IOHandler.Write(SysUtils.Format('<CmdTXFreq:%u>%s',[length(sFreq),sFreq]));
            end
         else
            begin
            sFreq := SysUtils.FormatFloat(',0.000',ActiveRadioPtr.CurrentStatus.VFO[VFOB].Frequency/1000);
            logger.Trace('Sending VFOB frequency as ' + SysUtils.Format('<CmdFreq:%u>%s',[length(sFreq),sFreq]));
            AContext.Connection.IOHandler.Write(SysUtils.Format('<CmdTXFreq:%u>%s',[length(sFreq),sFreq]));
            end;
         end
      else if fieldValue = 'CmdQSXSplit' then
         begin
         processingCmdQSXSplit := true;
         logger.Trace('Setting processingCmdQSXSplit');
         end
      else if fieldValue = 'CmdSplit' then
         begin
         processingCmdSplit := true;
         logger.Trace('Setting processingCmdSplit');
         end
      else if fieldValue = 'off' then
         begin
         if processingCmdSplit then
            begin
            processingCmdSplit := false;
            logger.Trace('Resetting processingCmdSplit');
            ActiveRadioPtr.PutRadioOutOfSplit;
            end
         else
            begin
            logger.Error('<***** ERROR ******> off command received for unknown reason');
            end;
         end
      else if fieldValue = 'on' then
         begin
         if processingCmdSplit then
            begin
            processingCmdSplit := false;
            logger.Trace('Resetting processingCmdSplit');
            ActiveRadioPtr.PutRadioIntoSplit;
            end
         else
            begin
            logger.Error('<***** ERROR ******> on command received for unknown reason');
            end;
         end;

      end;

        logger.Trace('length(sBuffer) = ' + IntToStr(length(sBuffer)));
     except
      on E : Exception do
         logger.error(' Error processing UDP message', E);
      end;
end;

procedure TWSJTXServer.IdTCPServer1Connect(AContext: TIdContext);
begin
logger.debug('TCP client Connected');
end;


procedure TWSJTXServer.IdTCPServer1Disconnect(AContext: TIdContext);

begin

   logger.debug('TCP Client disconnected');

end;



function TWSJTXServer.GetNextADIFField(var sBuffer: string; var fieldName: string; var fieldValue: string): boolean;

var

   i, z, n, x, dataLen: integer;

   aaa, sLen: string;

begin

   Result := false;

// Assumes we are pointing at the < in the next field

   z := AnsiPos('<',sBuffer);

   if z = 0 then
      begin
      if length(sBuffer) > 0 then
         begin
         logger.Trace('sBuffer does not start with < ' + sBuffer);
         sBuffer := '';
         end;
      exit;//  there is no other record - disappearing.
      end;



   aaa := copy(sBuffer,z+1,length(sBuffer));

   z := AnsiPos(':',aaa);
   x := AnsiPos('>',aaa);
   if x = 0 then

      begin

      exit; //  the record was not terminated ... disappearing

      end;

   for i := z + 1 to x do

      begin
      if aaa[i] in ['0'..'9'] then
         begin
         slen := slen + aaa[i];
         end;
      end;

    if slen = '' then
      begin
      DataLen := 0;
      end
    else
      begin
      DataLen := StrToInt(slen);
      end;
    logger.Trace('Got length:' + IntToStr(DataLen));

    if z<>0 then
      begin
      fieldName := trim(copy(aaa,1,z-1));
      end
    else
      begin
      fieldName := trim(copy(aaa,1,x-1));
      end;

    aaa := copy(aaa,x+1,length(aaa));

    z := AnsiPos('<',aaa);
    i := AnsiPos('_INTL',AnsiUppercase(fieldName));
    //if dmData.DebugLevel >=1 then Write(' pos INTL:',i);
    if z = 0 then
      begin
      fieldValue := copy(aaa,1,DataLen);
      logger.Trace('1-Trimming sBuffer to [' + copy(aaa,z,length(aaa)) + ']');
      sBuffer := copy(aaa,z,length(aaa)); // Was vstup:=''
      end
    else
      begin
      fieldValue := copy(aaa,1,DataLen);
      logger.Trace('2-Trimming sBuffer to [' + copy(aaa,z,length(aaa)) + ']');
      sBuffer := copy(aaa,z,length(aaa))
      end;
    fieldValue := Trim(fieldValue);

    Result := true;

    logger.Trace(fieldName + '=' + fieldValue);

end;

(*--------------------------------------------------------------------------------------------------------------------------------*)


procedure TWSJTXServer.Display(p_sender : String; p_message : string);

begin
   try
      logger.trace(p_message);
   except
   end;

end;

function TWSJTXServer.ConvertSNRToRST(snr: integer): integer;
begin
   if snr <= -20 then
      begin
      Result := 509;
      end
   else if snr < -14 then
      begin
      Result := 519;
      end
   else if snr < -8 then
      begin
      Result := 529;
      end
   else if snr < -2 then
      begin
      Result := 539;
      end
   else if snr < 4 then
      begin
      Result := 549;
      end
   else if snr < 10 then
      begin
      Result := 559;
      end
   else if snr < 16 then
      begin
      Result := 569;
      end
   else if snr < 22 then
      begin
      Result := 579;
      end
   else if snr < 28 then
      begin
      Result := 589;
      end
   else
      begin
      Result := 599;
      end;
   end;



end.




