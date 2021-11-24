unit uRadioElecraftK4;

interface
uses uNetRadioBase, StrUtils, SysUtils, Math;

Type TK4Radio = class(TNetRadioBase)
   private
      function ParseIFCommand(cmd: string): boolean;
      function ModeStrToMode(sMode: string; sDataMode: string): TRadioMode;
      function BandNumToBand(sBand: string): TRadioBand;
      function ProcessMessage_DT(sMessage: string): TRadioMode;
      procedure ProcessMessage_FA(sMessage: string);
      //procedure ProcessMessage(sMessage: string);
      function Connect: integer; overload;

   public
      Constructor Create;
      procedure Transmit;
      procedure Receive;
      procedure SendCW(cwChars: string);
      procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
      procedure SetMode(mode:TRadioMode; vfo: TVFO);
      function  ToggleMode(vfo: TVFO): TRadioMode;
      procedure SetCWSpeed(speed: integer);
      procedure RITClear;
      procedure XITClear;
      procedure RITOn;
      procedure RITOff;
      procedure XITOn;
      procedure XITOff;
      procedure Split(splitOn: boolean);
      procedure SetRITFreq(hz: integer);
      procedure SetXITFreq(hz: integer);
      procedure SetBand(band: TRadioBand; vfo: TVFO);
      function  ToggleBand(vfo: TVFO): TRadioBand;
      procedure SetFilter(filter:integer);
      function  SetFilterHz(hz: integer): integer;
      procedure MemoryKeyer(mem: integer);
      procedure SetAIMode(i: integer);
      procedure ProcessMessage(sMessage: string);
end;


implementation

Constructor TK4Radio.Create;
begin
   inherited Create(ProcessMessage);
end;

function TK4Radio.Connect: integer;
begin
   Result := Inherited Connect;
   if Self.IsConnected then
      begin
      Self.SetAIMode(5);
      Self.SendToRadio('RT;XT;RO;FT;ID;MD;DT;');
      end;
end;
procedure TK4Radio.Transmit;
begin
   Self.SendToRadio('TX;');
end;

procedure TK4Radio.Receive;
begin
   Self.SendToRadio('RX;');
end;

procedure TK4Radio.SendCW(cwChars: string);
var s: string;
begin
   if length(cwChars) > 60 then
      begin
      s := AnsiLeftStr(cwChars,60);
      logger.Info('Cannot send more than 60 characters to a K4 - Truncating to %s',[s]);
      end
   else
      begin
      s := cwChars;
      end;
   Self.SendToRadio('KY ' + s + ';');
end;

procedure TK4Radio.SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
begin
end;

procedure TK4Radio.SetMode(mode:TRadioMode; vfo: TVFO);
begin
   case mode of
      rmNone: Self.SendToRadio('MD');
      rmCW:  Self.SendToRadio('MD');
      rmCWRev: Self.SendToRadio('MD');
      rmLSB:  Self.SendToRadio('MD');
      rmUSB: Self.SendToRadio('MD');
      rmFM:   Self.SendToRadio('MD');
      rmAM:  Self.SendToRadio('MD');
      rmData: Self.SendToRadio('MD');
      rmDataRev: Self.SendToRadio('MD');
      rmFSK:    Self.SendToRadio('MD');
      rmFSKRev:  Self.SendToRadio('MD');
      rmPSK:  Self.SendToRadio('MD');
      rmPSKRev:Self.SendToRadio('MD');
      rmAFSK:  Self.SendToRadio('MD');
      rmAFSKRev: Self.SendToRadio('MD');
    else
       begin
       end;
    end;
end;

function  TK4Radio.ToggleMode(vfo: TVFO): TRadioMode;
begin
end;

procedure TK4Radio.SetCWSpeed(speed: integer);
begin
   if IntegerBetween(speed,8,100) then
      begin
      Self.localCWSpeed := speed;
      Self.SendToRadio(Format('KS%3d;',[speed]));
      end
   else
      begin
      logger.Error ('K4 supports a CW speed of 8 wpm to 100 wpm');
      end;
end;

procedure TK4Radio.RITClear;
begin
   Self.SendToRadio('RC;');
end;

procedure TK4Radio.XITClear;
begin
   Self.SendToRadio('RC;');
end;

procedure TK4Radio.RITOn;
begin
   Self.SendToRadio('RT1;');
end;

procedure TK4Radio.RITOff;
begin
   Self.SendToRadio('RT0;');
end;

procedure TK4Radio.XITOn;
begin
   Self.SendToRadio('XT1;');
end;

procedure TK4Radio.XITOff;
begin
   Self.SendToRadio('XT0;');
end;

procedure TK4Radio.Split(splitOn: boolean);
begin
   if splitOn then
      begin
      Self.SendToRadio('FT1;');
      end
   else
      begin
      Self.SendToRadio('FT0;');
      end;
end;
procedure TK4Radio.SetRITFreq(hz: integer);
var s: string;
begin
   if (hz > -10000) and (hz < 10000) then
      begin
      if hz >= 0 then
         begin
         s := '+';
         end
      else
         begin
         s := '-';
         end;
      s := s + Format('%4d',[Abs(hz)]);
      Self.SendToRadio('RO' + s + ';');
      end
   else
      begin
      logger.Error('[SetRITFreq] RIT frequency must be between -9999 and 9999 (%d)',[hz]);
      end;
end;

procedure TK4Radio.SetXITFreq(hz: integer);
begin
   Self.SetRITFreq(hz); // Same on K4
end;

procedure TK4Radio.SetBand(band: TRadioBand; vfo: TVFO);
var s: string;
begin

   case band of
      rb160m: s := '00';
      rb80m: s := '01';
      rb60m: s := '02';
      rb40m: s := '03';
      rb30m: s := '04';
      rb20m: s := '05';
      rb17m: s := '06';
      rb15m: s := '07';
      rb12m: s := '08';
      rb10m: s := '09';
      rb6m:  s := '10';
   else
      begin
      logger.Error('Invalid band requested %d',[Ord(band)]);
      Exit;
      end;
   end;
   Self.SendToRadio(Format('BN%2d;',[Ord(band)]));
end;


function  TK4Radio.ToggleBand(vfo: TVFO): TRadioBand;
var newBand: TRadioBand;
begin
   //newBand := Self.priorBand;
   //Self.priorBand := Self.band;
   //Self.SetBand(newBand);
   //Result := newBand;
   logger.Warn('ToggleBand not yet implemented');
end;

procedure TK4Radio.SetFilter(filter: integer);
begin
   if IntegerBetween(filter, 1, 5) then
      begin
      logger.Info('[SetFilter] Setting filter to %d',[filter]);
      Self.SendToRadio(Format('XF%d',[filter]));
      end
   else
      begin
      logger.error('[SetFilter] filter out of range 1..5 - %d',[filter]);
      end;

end;

function  TK4Radio.SetFilterHz(hz: integer): integer;
begin
end;

procedure TK4Radio.MemoryKeyer(mem: integer);
begin
   logger.Warn('Memory keying is not yet implemented on the K4');
end;

function TK4Radio.ParseIFCommand(cmd: string): boolean;
var
   s: string;
   hz: integer;
   ritMultiplier: integer;
   xitMultiplier: integer;
   ritOffset: integer;
   xitOffset: integer;
   sVFO: string;
   sMode: string;
   sDataMode: string;
   vfo: TRadioVFO;
begin
{
IF (Transceiver Information; GET only)
RSP format: IF[f]*****+yyyyrx*00tmvspbd1*; where the fields are defined as follows:
[f] Operating frequency, excluding any RIT/XIT offset (11 digits; see FA command format)
* represents a space (BLANK, or ASCII 0x20)
+ either "+" or "-" (sign of RIT/XIT offset)
yyyy RIT/XIT offset in Hz (range is -9999 to +9999 Hz when computer-controlled)
r 1 if RIT is on, 0 if off
x 1 if XIT is on, 0 if off
t 1 if the K3 is in transmit mode, 0 if receive
m operating mode (see MD command)
v receive-mode VFO selection, 0 for VFO A, 1 for VFO B
s 1 if scan is in progress, 0 otherwise
p 1 if the transceiver is in split mode, 0 otherwise
b Basic RSP format: always 0; K2 Extended RSP format (K22): 1 if present IF response
is due to a band change; 0 otherwise
d Basic RSP format: always 0; K3 Extended RSP format (K31): DATA sub-mode,
if applicable (0=DATA A, 1=AFSK A, 2= FSK D, 3=PSK D)
}
   Result := false;
   if not length(cmd) in [36,38] then
      begin
      logger.Error('[ParseIFCommand] length of IF command not 36 or 38 bytes - %s',[cmd]);
      Exit;
      end;

   s := cmd;
   if AnsiLeftStr(s,2) = 'IF' then
      begin
      Delete(s,1,2);
      end;
   hz := StrToIntDef(AnsiLeftStr(s,11),-999);   //[f]*****+yyyyrx*00tmvspbd1*;
   if hz = -999 then
      begin
      logger.Error('[ParseIFCommand] frequency returned in IF command was not a number %s',[AnsiLeftStr(s,11)]);
      Exit;
      end;
   

   Delete(s,1,11); // Remove frequency
   Delete(s,1,5); // Remove 5 blanks          // *****+yyyyrx*00tmvspbd1*;
   if AnsiLeftStr(s,1) = '-' then
      begin
      ritMultiplier := -1;
      xitMultiplier := -1;
      end
   else if AnsiLeftStr(s,1) = '+' then
      begin
      ritMultiplier := 1;
      xitMultiplier := 1;
      end;
   Delete(s,1,1);                      // yyyyrx*00tmvspbd1*;
   ritOffset := StrToIntDef(AnsiLeftStr(s,4),-999);
   if ritOffset = -999 then
      begin
      logger.Error('[ParseIFCommand] RIT offset returned in IF command was not a number %s',[AnsiLeftStr(s,4)]);
      Exit;
      end;

   Self.localRITOffset := (ritOffset * ritMultiplier);
   Self.localXITOffset := (Self.localRITOffset); // Because on K4, these are the same
   logger.debug('[ParseIFCommand] RITOffset = %d',[Self.localRITOffset]);
   
   Delete(s,1,4);                      // rx*00tmvspbd1*;
   Self.RITState := AnsiLeftStr(s,1) = '1';
   logger.Debug('In IF processor, RIT is %s',[AnsiLeftStr(s,1)]);

   Delete(s,1,1);                      // x*00tmvspbd1*;
   Self.XITState := AnsiLeftStr(s,1) = '1';
   logger.Debug('In IF processor, XIT is %s',[AnsiLeftStr(s,1)]);

   Delete(s,1,1);
   Delete(s,1,1); // Skip space       // *00tmvspbd1*;
   Delete(s,1,2); // Skip 00          // 00tmvspbd1*;

   if AnsiLeftStr(s,1) = '1' then     // tmvspbd1*;
      begin
      Self.RadioState := rsTransmit;
      end
   else
      begin
      Self.RadioState := rsReceive;
      end;
   Delete(s,1,1);
   logger.debug('[ParseIFCommand] string at mode = %s',[s]);
   sMode := AnsiLeftStr(s,1);          // mvspbd1*;

   Delete(s,1,1);
   logger.debug('[ParseIFCommand] string at vfo = %s',[s]);
   sVFO := AnsiLeftStr(s,1);           // vspbd1*;

   Delete(s,1,2); // Skip s as we do not care if scanning  // spbd1*;
   logger.debug('[ParseIFComand] Checking split command in %s',[s]);
   Self.localSplitEnabled := AnsiLeftStr(s,1) = '1';           // pbd1*;


   Delete(s,1,1);

   Delete(s,1,1); // Skip the b // bd1*;

   // (0=DATA A, 1=AFSK A, 2= FSK D, 3=PSK D)

   sDataMode := AnsiLeftStr(s,1);

   // Post processing from gathered variables to the right VFO
   if sVFO = '0' then // VFO A
      begin
      vfo := Self.vfo[1];
      end
   else
      begin
      vfo := Self.vfo[2];
      end;

   vfo.frequency := hz;
   vfo.mode := ModeStrToMode(sMode,sDataMode);



end;

{
Type TRadioMode = (rmNone,rmCW, rmCWRev, rmLSB, rmUSB, rmFM, rmAM,
                   rmData, rmDataRev, rmFSK, rmFSKRev, rmPSK, rmPSKRev,
                   rmAFSK, rmAFSKRev);
                   }

// Helper functions
function TK4Radio.ModeStrToMode(sMode: string; sDataMode: string): TRadioMode;
var iMode: integer;
begin
   iMode := StrToIntDef(sMode,-999);
   case iMode of
      0: Result := rmNone;
      1: Result := rmLSB;
      2: Result := rmUSB;
      3: Result := rmCW;
      4: Result := rmFM;
      5: Result := rmAM;
      6: begin
            case StrToIntDef(sDataMode,-9) of
            0: Result := rmData;
            1: Result := rmAFSK;
            2: Result := rmFSK;
            3: Result := rmPSK;
            -9:begin
               logger.Error('[ModeStrToMode] Non-numeric string passed for sDataMode (%s)',[sDataMode]);
               Result := rmData;
               end;
            else
               begin
               logger.Error('[ModeStrToMode] Unexpected string passed for sDataMode (%s)',[sDataMode]);
               Result := rmData;
               end;
            end;
         end;
      7: Result := rmCWRev;
      9: Result := rmDataRev;
      -999: begin
            logger.error('[ModeStrToMode] Non-numeric string passed for sMode (%s)',[sMode]);
            Result := rmNone;
            end;
      else
         begin
         logger.error('[ModeStrToMode] Unexpected string passed for sMode (%s)',[sMode]);
         Result := rmNone;
         end;
      end; // case
end;

function TK4Radio.ProcessMessage_DT(sMessage: string): TRadioMode;
begin
end;

procedure TK4Radio.ProcessMessage_FA(sMessage: string);
begin
end;

procedure TK4Radio.ProcessMessage(sMessage: string);
var
   sCommand: string;
   sData: string;
   sMode: string;
   hz: integer;
   i: integer;
   RITSign: integer;
   ritHz : integer;
   sDataMode: string;
   vfo: TRadioVFO;
   vfoBCommand: boolean;
begin
// This is called by the process that receives data on the socket - Event
// K4 messages are seperated by semi-colons (;) but each message should not have the ; as that is the ReadLn delimiter.
// This is a command that has been parsed into its parts. For example, if the radio
// sends RX;DT5;, this procedure is called once with RX; and once with DT5;
   sCommand := AnsiLeftStr(sMessage,2);
   if AnsiMidStr(sMessage,3,1) = '$' then
      begin
      vfoBCommand := true;
      sData := ANsiMidStr(sMessage,4,length(sMessage));
      vfo := Self.vfo[2];
      end
   else
      begin
      vfoBCommand := false;
      sData := AnsiMidStr(sMessage,3,length(sMessage));
      vfo := Self.vfo[1];
      end;

   Case AnsiIndexText(AnsiUppercase(sCommand), ['AI','BI','BN','DT','FA','FB','FT','IF','KS','MA','MD','RT','RX','TX','XT','RO']) of
      0: begin                                     // AI
         logger.info('[ProcessMessage] AI command set to %s',[sData]);
         end;
      1: begin            // BI
         if sData = '1' then
            begin
            Self.bandIndependence := true;
            end;
         end;
      2: begin              // BN
         if Self.BandNumToBand(sData) <> vfo.band then
            begin    // band change so prime RIT, MD settings
            Self.SendToRadio('MD;MD$;DT;DT$;FA;FB;IF;');
            end;
         vfo.band := Self.BandNumToBand(sData);
         logger.debug('[ProcessMessage] Received band number of %s',[sData]);
         end;
      3: begin             // DT
         if vfoBCommand then
            begin
            sDataMode := AnsiMidStr(sData,2,1);
            end
         else
            begin
            sDataMode := AnsiLeftStr(sData,1);
            end;
         case StrToIntDef(sDataMode,-9) of
            0: vfo.datamode := rmData;
            1: vfo.datamode := rmAFSK;
            2: vfo.datamode := rmFSK;
            3: vfo.datamode := rmPSK;
            -9:logger.error('[ProcessMessage] Non-numeric passed with DT command (%s)',[sData]);
            end;
         end;
      4: begin             // FA
         hz := StrToIntDef(AnsiLeftStr(sData,11),-9);
         if hz >= 0 then
            begin
            Self.vfo[1].frequency := hz;
            end
         else
            begin
            logger.error('[ProcessMessage] non-numeric passed in sData with FA command (%s)',[AnsiLeftStr(sData,11)]);
            end;
         end;
      5: begin             // FB
         hz := StrToIntDef(AnsiLeftStr(sData,11),-9);
         if hz >= 0 then
            begin
            Self.vfo[2].frequency := hz;
            end
         else
            begin
            logger.error('[ProcessMessage] non-numeric passed in sData with FB command (%s)',[AnsiLeftStr(sData,11)]);
            end;
         end;
      6: begin             // FT
         Self.localSplitEnabled := AnsiLeftStr(sData,1) = '1';
         logger.debug('[ProcessMessage] FT (Split) received - Split is %s',[AnsiLeftStr(sData,1)]);
         end;
      7: begin             // IF
         Self.ParseIFCommand(sData);
         end;
      8: begin             // KS
         i := StrToIntDef(AnsiLeftStr(sData,3),-1);
         if IntegerBetween(i,8,100) then
            begin
            Self.localCWSpeed := i;
            end
         else
            begin
            logger.Warn('[ProcessMessage] Invalid CW speed received in KS command (%s)',[AnsiLeftStr(sData,3)]);
            end;
         end;
      9: begin             // MA
         end;
      10:begin             // MD
         vfo.mode := Self.ModeStrToMode(AnsiLeftStr(sData,1),' ');
         logger.trace('[ProcessMessage] Mode data = %s',[sData]);
         end;
      11:begin              // RT
         vfo.RITState := AnsiLeftStr(sData,1) = '1';
         //Self.RITState := AnsiLeftStr(sData,1) = '1';
         logger.debug('[ProcessMsg] RIT Enabled is %s',[AnsiLeftStr(sData,1)]);
         end;
      12:Self.radioState := rsReceive; // RX
      13:Self.radioState := rsTransmit; // TX
      14:begin              // XT
         vfo.XITState := AnsiLeftStr(sData,1) = '1';
         //Self.XITState := AnsiLeftStr(sData,1) = '1';
         logger.debug('[ProcessMessage] XIT Enabled is %s',[AnsiLeftStr(sData,1)]);
         end;
      15:begin    // RO
         RITSign := IfThen(AnsiLeftStr(sData,1) = '-',-1,1);
         {if AnsiLeftStr(sData,1) = '-' then
            begin
            RITSign := -1;
            end
         else
            begin
            RITSign := 1;
            end;}
         ritHz := StrToIntDef(AnsiMidStr(sData,2,4),99999);
         if ritHz = 99999 then
            begin
            ritHz := 0;
            logger.error('[ProcessMessage] Invalid value passed in RO command: %s',[sData]);
            end
         else
            begin
            ritHz := ritHz * ritSign;
            vfo.RITOffset := ritHz;
            vfo.XITOffset := ritHz;
            //Self.localRITOffset := ritHz;
            //Self.localXITOffset := ritHz; // Because on K4, this is the same value
            end;

         end;
   end; // of case

end;

function TK4Radio.BandNumToBand(sBand: string): TRadioBand;
var
   iBand: integer;
begin
   iBand := StrToIntDef(AnsiLeftStr(sBand,1),-9);
   case iBand of
      0: Result := rb160m;
      1: Result := rb80m;
      2: Result := rb60m;
      3: Result := rb40m;
      4: Result := rb30m;
      5: Result := rb20m;
      6: Result := rb17m;
      7: Result := rb15m;
      8: Result := rb12m;
      9: Result := rb10m;
      10:Result := rb6m;
      -9:begin
         logger.Error('[BandNumToBand] Invalid band requested %s',[sBand]);
         Result := rbNone;
         end;
   end;
end;

procedure TK4Radio.SetAIMode(i: integer);
begin
   Self.SendToRadio(Format('AI%d;',[i]));
   
end;


end.
