unit uExternalLogger;

interface
uses uExternalLoggerBase, StrUtils, SysUtils, Math, TF, VC, LOGSUBS2, LogWind, LogDupe, Tree, uCFG, PostUnit;


Type TExternalLogger = class(TExternalLoggerBase)
   private
      localCE: ContestExchange;
      procedure Initialize;
      procedure SendToLogger(sCmd: string; sData: string); overload;
      function AddADIFField(sFieldName: string; sValue: string): string; overload;
      function AddADIFField(sFieldName: string; nValue: integer): string; overload;

      // DXKeeper
      function LogQSOToDXKeeper(ce: ContestExchange): integer;
      function DeleteQSOToDXKeeper(ce: ContestExchange): integer; // There functions hsould be changed to an interface so we just call one based onthe interface (by log type). ny4i
      function LookupCallsignToDXKeeper(ce: ContestExchange): integer;

      // ACLog
      function LogQSOToACLog(ce: ContestExchange): integer;

      // HRD
      function LogQSOToHRD(ce: ContestExchange): integer;



      // Add a QueueQSO to copy the record then return to the caller. This allows the actual sending of the TCP message ot be done from a different thread to not slow down the program.

      // I could also generalize this into post QSO Processing and let the UDP happen from the thread too. Worth exploring the actual amont of time per QSO to send to UDP and TCP. If it is very fast, this complication may not be necessary.
   public
      Constructor Create(); overload;
      Constructor Create(logType: ExternalLoggerType{sLoggerType: string}); overload;

      function Connect: integer; overload;
      procedure ProcessMessage(sMessage: string);
      function LogQSO(ce: ContestExchange): integer;
      function DeleteQSO(ce: ContestExchange): integer;
      function LookupCallsign(ce:ContestExchange): integer;

end;


var
   firstProcessMessage: boolean = true;
implementation

Uses MainUnit;

Constructor TExternalLogger.Create();
begin
   inherited Create(ProcessMessage);
end;

Constructor TExternalLogger.Create(logType: ExternalLoggerType) {sLoggerType: string)};
begin
  // Self.loggerID := sLoggerType;
  Self.logType := logType;
  Self.logTypeSet := true;
   Self.Create(ProcessMessage);
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
   case Self.logType of
      lt_NoExternalLogger:
         begin
         Result := -1;
         logger.Error('Within TExternalLogger.LogQSO, logType set to NoExternalLogger');
         end;
      lt_DxKeeper: Result := Self.LogQSOToDXKeeper(ce);
      lt_ACLog: Result := Self.LogQSOToACLog(ce);
      lt_HRD: Result := Self.LogQSOToHRD(ce);
   end;
end;

function TExternalLogger.DeleteQSO(ce: ContestExchange): integer;
begin
   case Self.logType of
      lt_NoExternalLogger:
         begin
         Result := -1;
         logger.Error('Within TExternalLogger.DeleteQSO, logType set to NoExternalLogger');
         end;
      lt_DxKeeper: Result := Self.DeleteQSOToDXKeeper(ce);
      //lt_ACLog: Result := Self.LogQSOToACLog(ce);
      //lt_HRD: Result := Self.LogQSOToHRD(ce);
   end;
end;

function TExternalLogger.LookupCallsign(ce: ContestExchange): integer;
begin
   case Self.logType of
      lt_NoExternalLogger:
         begin
         Result := -1;
         logger.Error('Within TExternalLogger.LookupCallsign, logType set to NoExternalLogger');
         end;
      lt_DxKeeper: Result := Self.LookupCallsign(ce);
      //lt_ACLog: Result := Self.LogQSOToACLog(ce);
      //lt_HRD: Result := Self.LogQSOToHRD(ce);
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
                  + AddADIFField('CONTEST_ID',ContestTypeSA[ce.ceContest])
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

                  + AddADIFField('SRX_STRING', ce.ExchString)
                  + AddADIFField( 'STX_STRING',Trim(DeleteRepeatedSpaces(GetMyExchangeForExport)))



                  ;
  if ExchangeInformation.QSONumber then
     begin
     if ce.NumberReceived <> -1 then
        begin
        sCoreADIF := sCoreADIF + AddADIFField('SRX',IntToStr(ce.NumberReceived));
        end;
     if ce.NumberSent <> -1 then
        begin
        sCoreADIF := sCoreADIF + AddADIFField('STX',IntToStr(ce.NumberSent));
        end;
      end;

  if ce.Age <> 0 then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('AGE',IntToStr( ce.Age));
     end;

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
  if LooksLikeASection(ce.QTHString) then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('ARRL_SECT', ce.QTHString);
     end;
   // TODO To include ARRL_SECTION, the EXCHANGEINFORMATION record should have a section indicator, thenuse that to grab section from   QTHString
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

//-------------------------------
function TExternalLogger.DeleteQSOToDXKeeper(ce: ContestExchange): integer;
var sCoreADIF: string;
    n: integer;

    nCoreADIFLength: integer;

    sMessage: string;

    sTemp: string;

begin

  sCoreADIF :=   AddADIFField('CALL',ce.Callsign)
               + AddADIFField('QSO_DATE',SysUtils.format('20%0.2d%0.2d%0.2d',
                                                         [ce.tSysTime.qtYear,
                                                          ce.tSysTime.qtMonth,
                                                          ce.tSysTime.qtDay]))
               + AddADIFField('TIME_ON',SysUtils.format('%0.2d%0.2d%0.2d',
                                                        [ce.tSysTime.qtHour,
                                                         ce.tSysTime.qtMinute,
                                                         ce.tSysTime.qtSecond]))
               ;

  sCoreADIF := sCoreADIF + '<EOR>';
  nCoreADIFLength := length(sCoreADIF);
 // sCoreADIF := '<ExternalLogADIF:' + IntToStr(nCoreADIFLength) + '>' + sCoreADIF;
  nCoreADIFLength := length(sCoreADIF); // Update to include the ExternalLogADIF field
  sMessage := '<command:9>deleteqso<parameters:' + IntToStr(nCoreADIFLength {+ nOptionsLength}) + '>' + sCoreADIF;
  logger.Debug('[TExternalLogger.DeleteQSO] Sending message to external logger: [%s]',[sMessage]);
  Self.SendToLogger(sMessage);

end;

function TExternalLogger.LookupCallsignToDXKeeper(ce: ContestExchange): integer;
var sMessage: string;
begin
  sMessage := '<command:5>check<parameters:' + IntToStr(length(ce.Callsign)) + '>' + ce.Callsign;
  logger.Debug('[TExternalLogger.LookupQSOToDXKeeper] Sending message to external logger: [%s]',[sMessage]);
  Self.SendToLogger(sMessage);
end;
//--------------------------------
function TExternalLogger.LogQSOToACLog(ce: ContestExchange): integer;
begin
   logger.Info('Logging to ACLog not yet implemented');
end;

function TExternalLogger.LogQSOToHRD(ce: ContestExchange): integer;
begin
   logger.Info('Logging to HRD not yet implemented');
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
