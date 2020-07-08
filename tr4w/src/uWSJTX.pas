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
  ;

type
  TWSJTXServer = class(TObject)
  private
      udpServ : TIdUDPServer;
      UFreq, UModeRX, UModeTX, UDXCall, URSTs, UHeureDeb : string;
      UCall,ULoc : string;
      UIndex:integer;
      peerPort: word;
      SNR: LongInt;
      firstTime: boolean;
      isConnected: boolean;
  protected
    procedure OnServerRead(ASender: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure OnBeforeBind(AHandle: TIdSocketHandle);
  public
    constructor Create;
    procedure Start;    // May want to add the port number to a constructor - for now use default
    procedure Stop;
    destructor Destroy;
    procedure HighlightCall(sCall: string; color: integer; sId: string);
    procedure ClearColors(sId: string);
    property connected: boolean read isConnected;
  end;

(*
type
  TForm1 = class(TForm)
    IdUDPServer1: TIdUDPServer;
    Memo1: TMemo;
    Button1: TButton;
    procedure IdUDPServer1UDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure IdUDPServer1BeforeBind(AHandle: TIdSocketHandle);
    procedure IdUDPServer1UDPException(AThread: TIdUDPListenerThread;
      ABinding: TIdSocketHandle; const AMessage: String;
      const AExceptionClass: TClass);
    procedure Button1Click(Sender: TObject);
    procedure IdUDPServer1Status(ASender: TObject;
      const AStatus: TIdStatus; const AStatusText: String);
    procedure IdUDPServer1AfterBind(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
 *)
{var
  udpServ: TIdUDPServer;
  UFreq, UModeRX, UModeTX, UDXCall, URSTs, UHeureDeb : string;
  UCall,ULoc : string;
  UIndex:integer;
  peerPort: qword;
  SNR: LongInt;
 }
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

   end;

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
  frequency: QWord;
  isNew, TXEnabled, transmitting, Decoding: Boolean;
  tm: Longword;
  ztime: TDateTime;
  DT: Double;
  DF: Cardinal;
  date: TDateTime;
  {Ajout ici}
  z: TStringList;
  Memomessage,locator: string;
  rst, RXDF, TXDF: integer;
  TempRXData: ContestExchange;
  lpNumberOfBytesWritten: Cardinal;
  inx: integer;
  TempMode: ModeType;
  TempBand: BandType;

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
               UnpackIntQWord(AData,index,frequency);
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
               Memomessage := IntToStr(frequency.Hi);
               {DEBUGMSG('WSJTX >>> Status: Frequency: ' + IntToStr(frequency.Hi) + ' Mode: ' + mode + ' DX Call: ' + DXCall
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
               ///////DEBUGMSG('WSJTX >>> ' + Memomessage);
               if MidStr(message,1,2) = 'CQ' then
                  begin
                  DXCall := MidStr(message,4,length(message)-4);
                  inx := AnsiPos(' ',DXCall);
                  DXCall := MidStr(DXCall,1,inx);
                  call := DXCall;
                  GetBandMapBandModeFromFrequency(frequency.Hi, TempBand, TempMode);
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

               // This is where we need to look for CQ decodes and highlight the call by sending back
               // a message to the UDP receiver in WSJT-X. Hence this unit also needs a
               // udp client to send messages back.
               // Decide if I only want to highlight the CQs or all calls. That could perhaps
               // be a program option WSJTXHIGHLIGHTCQONLY
          (*
          rst:=SNR;                                                             // Ajout rst
          mode:=decodeMode(mode);   {.......................................... #=JT65 et @=JT9 tilde = FT8 ou :=qra64}
          try
          z:=TStringList.Create;
          z.Delimiter:=' ';
          z.DelimitedText:=message;
          if z.count > 1 then begin
             z.Add(message);
             if z[1] = 'DX' then begin
                DXCall := z[2];
                locator := z[3];
             end
             else begin
                  DXCall := z[1];
                  locator := z[2];
             end;

             UCall := z[0];
             locator := z[2];
             Pvalid(UCall,DXCall,mode,locator,rst);                             // Ajout rst
//             saveinfo(FormatDateTime('hhmm',time),DXCall,mode,SNR);             { en test }
          end;
          except
            on E : Exception do WriteLn(Format('ERROR : %s',[e.Message]));
          end;
          z.Free;
          *)
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
               //DEBUGMSG('WSJTX >>> ADIF Record to log: ' + adif);
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
               DEBUGMSG('WSJTX >>> Unrecognized message type:' + IntToStr(messageType));
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
      // Yellow  RGB(0,255,255)
      Pack(AData,colorType);
      PackFF00(AData);   //Pack(AData,Word(65280));     // Alpha
      Pack(AData,Word(0));     // R
      PackFF00(AData); //Pack(AData,Word(65280));   // G
      PackFF00(AData);  // B
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

   DEBUGMSG('Sending command to highlight ' + Trim(sCall) + ' to RED');
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

end.
