unit uExternalLogger;

interface
uses uExternalLoggerBase, StrUtils, SysUtils, Math, TF, VC, LOGSUBS2, LogWind, Tree, uCFG;


Type TExternalLogger = class(TExternalLoggerBase)
   private
      localCE: ContestExchange;
      procedure Initialize;
      procedure SendToLogger(sCmd: string; sData: string); overload;
      function AddADIFField(sFieldName: string; sValue: string): string; overload;
      function AddADIFField(sFieldName: string; nValue: integer): string; overload;
      function LogQSOToDXKeeper(ce: ContestExchange): integer;

      // Add a QueueQSO to copy the record then return to the caller. THis allows the actual sending of th eTCP message ot be done from a different thread to not slow down the program.

      // I could also generalize this into postQSOProcessing and let the UDP happen from the thread too. Worth exploring the actual amont of time per QSO to send to UDP and TCP. If it is very fast, this complicatyion may not be necessary.
   public
      Constructor Create(sLoggerType: string);
      function Connect: integer; overload;
      procedure ProcessMessage(sMessage: string);
      function LogQSO(ce: ContestExchange): integer;

end;

var
   firstProcessMessage: boolean = true;
implementation

Uses MainUnit;

Constructor TExternalLogger.Create(sLoggerType: string);
begin
   Self.loggerID := sLoggerType;
   inherited Create(ProcessMessage);
end;

function TExternalLogger.Connect: integer;
begin
   Self.readTerminator := ';';
   Result := Inherited Connect;
   if Self.IsConnected then
      begin
      end;
end;

procedure TExternalLogger.ProcessMessage(sMessage: string);
var
   sCommand: string;
   i: integer;
begin
// This is called by the process that receives data on the socket - Event
   logger.Debug('[TExternalLogger.ProcessMessage] Received from external logger: (%s)',[sMessage]);
   sCommand := AnsiLeftStr(sMessage,2);

   {Case AnsiIndexText(AnsiUppercase(sCommand), ['AI','BI','BN','DT','FA','FB','FT','IF','KS','MA','MD','RT','RX','TX','XT','RO', 'FP']) of
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
            Self.SendToRadio('BN;MD;MD$;DT;DT$;FA;FB;IF;');
            end;
         vfo.band := Self.BandNumToBand(sData);
         logger.debug('[ProcessMessage] Received band number of %s',[sData]);
         end;
      3: begin             // DT
         sDataMode := AnsiLeftStr(sData,1);
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
            Self.vfo[nrVFOA].frequency := hz;
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
            Self.vfo[nrVFOB].frequency := hz;
            end
         else
            begin
            logger.error('[ProcessMessage] non-numeric passed in sData with FB command (%s)',[AnsiLeftStr(sData,11)]);
            end;
         end;
      6: begin             // FT
         Self.localSplitEnabled := AnsiLeftStr(sData,1) = '1';
         logger.debug('[ProcessMessage] FT (Split) received - Split is %s - localSplitEnabled = %s',[AnsiLeftStr(sData,1),BoolToString(Self.localSplitEnabled)]);
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

   end; // of case
   }
   if firstProcessMessage then
      begin
      firstProcessMessage := false;
      Initialize;
      end;
end;



procedure TExternalLogger.Initialize;
begin

end;

procedure TExternalLogger.SendToLogger(sCmd: string; sData: string);
begin
   if not Self.IsConnected then
      begin
      Self.Connect;
      end;
   Inherited SendTologger(Format('%s%s;',[sCmd,sData])); // Build the externalcommand ADIF here

end;

function TExternalLogger.LogQSO(ce: ContestExchange): integer;
begin
   if Self.loggerID = 'DXKEEPER' then
      begin
      Result := Self.LogQSOToDXKeeper(ce);
      end
   else
      begin
      logger.Warn('[LogQSO] Called LogQSO without an expected loggerID (%s)',[Self.loggerID]);
      end;
end;

function TExternalLogger.LogQSOToDXKeeper(ce: ContestExchange): integer;
var sCoreADIF: string;
    n: integer;
    sMode: string;
    sOperator: string;
    nCoreADIFLength: integer;
    sOptions: string;
    nOptionsLength: integer;
    sMessage: string;
    sSubMode: string;
    sTemp: string;
    saveDecimalSeparator: char;
begin
{   This is the example from https://www.dxlabsuite.com/Interoperation.htm
<command:11>externallog<parameters:341><ExternalLogADIF:187><CALL:4>P5DX <RST_SENT:3>599
<RST_RCVD:3>599 <FREQ:6>14.004 <BAND:3>20M <MODE:2>CW <QSO_DATE:8>20220411 <TIME_ON:6>072800
<STATION_CALLSIGN:5>AA6YQ <TX_PWR:4>1000 <GRIDSQUARE:4>PM29 <EOR><UploadeQSL:1>Y
<UploadLoTW:1>Y<UploadClubLog:1>Y<DeduceMissing:1>Y<QueryCallbook:1>Y<UpdateeQSL:1>Y<UpdateLoTW:1>Y<CheckOverrides:1>Y

This is all we need to send as we DO NOT want to send every contact to any of the online QSL services like LOTW, QRZ, eQSL or ClubLog.

<command:11>externallog<parameters:341><ExternalLogADIF:187><CALL:4>P5DX <RST_SENT:3>599
<RST_RCVD:3>599 <FREQ:6>14.004 <BAND:3>20M <MODE:2>CW <QSO_DATE:8>20220411 <TIME_ON:6>072800
<STATION_CALLSIGN:5>AA6YQ <TX_PWR:4>1000 <GRIDSQUARE:4>PM29 <EOR><UploadeQSL:1>N
<UploadLoTW:1>N<UploadClubLog:1>N<DeduceMissing:1>Y<QueryCallbook:1>Y<UpdateeQSL:1>N<UpdateLoTW:1>N<CheckOverrides:1>Y

}
   if CurrentOperator[0] = #0 then
       begin
       sOperator := MyCall;
       end
   else
      begin
      sOperator := ce.ceOperator;
      end;

   if ce.ExtMode <> eNoMode then
      begin
      sMode := ExtendedModeStringArray[ce.extMode];
      if ce.ExtMode = eFT4 then    // ??? In MFSKModes[TempRXData.ExtMode]?
         begin
         sMode := 'MFSK';
         sSubMode := ExtendedModeStringArray[ce.ExtMode];
         end
      end
   else
      begin
      case ce.Mode of
         CW: sMode := 'CW';
         Phone: sMode := 'SSB';
         Digital: sMode := 'RTTY';
         FM: sMode := 'FM';
         else sMode := 'CW';
         end; // of case
      end;

  sCoreADIF :=   AddADIFField('CALL',ce.Callsign)
               + AddADIFField('RST_SENT',ce.RSTSent)
               + AddADIFField('RST_RCVD',ce.RSTReceived);
  if ce.Frequency <> 0 then //14149280  or 7025000
     begin
     saveDecimalSeparator := DecimalSeparator;
     try
        DecimalSeparator := '.';
        sTemp := FloatToStr((ce.Frequency/1000000));
        sCoreADIF := sCoreADIF + AddADIFField('FREQ',sTemp);
     finally
        DecimalSeparator := saveDecimalSeparator;
     end;
     end;
     sCoreADIF :=   sCoreADIF
                  + AddADIFField('BAND',ADIFBANDSTRINGSARRAY[ce.Band])
                  + ADDADIFField('MODE',sMode)
                  + AddADIFField('QSO_DATE',SysUtils.format('20%0.2d%0.2d%0.2d',
                                                            [ce.tSysTime.qtYear,
                                                             ce.tSysTime.qtMonth,
                                                             ce.tSysTime.qtDay]))
                  + AddADIFField('TIME_ON',SysUtils.format('%0.2d%0.2d%0.2d',
                                                          [ce.tSysTime.qtHour,
                                                           ce.tSysTime.qtMinute,
                                                           ce.tSysTime.qtSecond]))
                  + AddADIFField('STATION_CALLSIGN',MyCall)
                  + AddADIFField('OPERATOR',sOperator)
                  ;
  if sSubMode <> '' then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('SUBMODE',sSubMode);
     end;
  if LooksLikeAGrid(ce.QTHString) then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('GRIDSQUARE',ce.QTHString);
     end
  else if LooksLikeAGrid(ce.ExchString) then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('GRIDSQUARE',ce.ExchString);
     end
  else if LooksLikeAGrid(ce.DomesticQTH) then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('GRIDSQUARE',ce.DomesticQTH);
     end;

  sCoreADIF := sCoreADIF + '<EOR>';
  nCoreADIFLength := length(sCoreADIF);
  sCoreADIF := '<ExternalLogADIF:' + IntToStr(nCoreADIFLength) + '>' + sCoreADIF;
  nCoreADIFLength := length(sCoreADIF); // Update to include the ExternalLogADIF field
  sOptions :=   AddADIFField('DeduceMissing','Y')
              + AddADIFField('QueryCallbook','Y')
              + AddADIFField('CheckOverrides','Y')
              + AddADIFField('UploadeQSL','N')
              + AddADIFField('UploadLoTW','N')
              + AddADIFField('UploadClubLog','N')
              + AddADIFField('UploadQRZ','N')     // Note if the AutoUpload options in DXkeeper are checked, this is not honored.
              ;
  nOptionsLength := length(sOptions);
  sMessage := '<command:11>externallog<parameters:' + IntToStr(nCoreADIFLength + nOptionsLength) + '>' + sCoreADIF + sOptions;
  logger.Debug('[TExternalLogger.LogQSO] Sending message to external logger: [%s]',[sMessage]);
  Self.SendToLogger(sMessage);

end;

function TExternalLogger.AddADIFField(sFieldName: string; sValue: string): string;
begin
   result := '<' + sFieldName + ':' + IntToStr(length(sValue)) + '>' + sValue + ' ';
end;

function TExternalLogger.AddADIFField(sFieldName: string; nValue: integer): string;
begin
   result := '<' + sFieldName + ':' + IntToStr(DigitsIn(nValue)) + '>' + IntToStr(nValue) + ' ';
end;

end.
