{
 Copyright Larry Tyree, N6TR, 2011,2012,2013,2014,2015.

 This file is part of TR4W    (TRDOS)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W.  If not, see
 <http: www.gnu.org/licenses/>.
 }
unit LogCfg;

{$IMPORTEDDATA OFF}
interface

uses

  TF,
  VC,
  uIO,
  utils_text,
  idUDPClient,
  idGlobal,
  LogStuff,
  Windows,
  PostUnit,
  LogSCP,
  LogCW,
  LogWind,
  LogDupe,
  ZoneCont,
  LogGrid,
  LogDom,
  FCONTEST,
  LOGDVP,
  //Country9,
  LogEdit,
  //LOGDDX,
  LOGWAE,
//  LOGHP,
  LogPack,
  LogK1EA, {DOS,}
//  Help,
//  LOGPROM,
  CFGCMD,
  {SlowTree,}Tree, {Crt,}
//  LOGMENU,
  LogNet,
  LogRadio,
  CFGDEF,
  SysUtils,
  Log4D
  ;

type
  TCFGType = (cfgCFG, cfgINI, cfgINPUT, cfgCommMes);

function LoadInSeparateConfigFile(FileName: ShortString;
  var FirstCommand: boolean;
  Call: CallString): boolean;

procedure LookForCommands(var ContestConfigFileTitle: Str20);
procedure ReadInConfigFile(ConfigFileName: TCFGType);
procedure SetUpGlobalsAndInitialize;
procedure TryRunPaddleAndFootSwitchThread;
procedure tSetupExchangeNumbers;
procedure InitializeOtherLPTPorts;
procedure EnmuCFGFile(FileString: PShortString);

const
  CFGFilesArray                         : array[TCFGType] of PChar = (@TR4W_CFG_FILENAME, @TR4W_INI_FILENAME, @TR4W_INPUT_CFG_FILENAME, @TR4W_DEFMESSAGES_FILENAME);

var
  LineNumberInConfigFile                : integer;
  CurrentConfigFile                     : TCFGType;

implementation

uses
  uCFG,
  MainUnit,
  uRadioPolling;

procedure PushLogFiles(var LastPushedLogName: Str20);

{ This procedure will take the current active log file and create a
  backup file with the filename PLOG###.BAK.  ## is intially 01, and
  then increments each time.  The active log file is removed. }

//var
//  FileNumber                            : integer;
//  TempString                            : Str20;

begin
  {
    FileNumber := 0;

    repeat
      Str(FileNumber, TempString);
      while length(TempString) < 3 do
        TempString := '0' + TempString;

      TempString := 'PLOG' + TempString + '.BAK';

      if not FileExists(TempString) then
      begin
        RenameFile(LogFileName, TempString);

        LastPushedLogName := TempString;
        Exit;
      end;

      inc(FileNumber);

    until FileNumber > 1000;

    showmessage('Unable to create backup file!!');
    halt;
   }
end;

function ConfigurationOkay: boolean;
begin
{$IF MAKE_DEFAULT_VALUES = TRUE}
  Result := True;
  Exit;
{$IFEND}

  ConfigurationOkay := False;

  if MyCall = '' then
  begin
    showwarning(TC_NOCALLSIGNSPECIFIED);
    Exit;
  end;
{
  if FloppyFileSaveFrequency > 0 then
    if FloppyFileSaveName = '' then
    begin
      showwarning(TC_NOFLOPPYFILESAVENAMESPECIFIED);
      Exit;
    end;
}
  ConfigurationOkay := True;
end;

procedure InitializeOtherLPTPorts;
begin

  if ActivePaddlePort <> NoPort then
    if ActivePaddlePort = RelayControlPort then
    begin
      showwarning('RELAY CONTROL PORT = PADDLE PORT');
//      Exit;
    end;

  tRelayControlPortBaseAddress := INVALID_HANDLE_VALUE;
  if tGetPortType(RelayControlPort) = ParallelInterface then
    OpenLPT(tRelayControlPortBaseAddress, RelayControlPort);

  tActiveStereoPortBaseAddress := INVALID_HANDLE_VALUE;
  if tGetPortType(ActiveStereoPort) = ParallelInterface then
    OpenLPT(tActiveStereoPortBaseAddress, ActiveStereoPort);

  Radio1.tBandOutputPortBaseAddress := INVALID_HANDLE_VALUE;
  if tGetPortType(Radio1.BandOutputPort) = ParallelInterface then
    OpenLPT(Radio1.tBandOutputPortBaseAddress, Radio1.BandOutputPort);

  Radio2.tBandOutputPortBaseAddress := INVALID_HANDLE_VALUE;
  if tGetPortType(Radio2.BandOutputPort) = ParallelInterface then
    OpenLPT(Radio2.tBandOutputPortBaseAddress, Radio2.BandOutputPort);
end;

procedure TryRunPaddleAndFootSwitchThread;
begin

  if tUseControlPort then
    if Radio1.tCATPortHandle <> INVALID_HANDLE_VALUE then
    begin
      DoingPaddle := True;
      tDoingFootSwitchEnable := True;
      tRuntPaddleAndFootSwitchThread;
      Exit;
    end;

  if tGetPortType(ActiveFootSwitchPort) = ParallelInterface then
    if OpenLPT(tFootSwitchPortBaseAddress, ActiveFootSwitchPort) then
    begin
      tRuntPaddleAndFootSwitchThread;
      tDoingFootSwitchEnable := True;
    end;

  if tGetPortType(ActivePaddlePort) = ParallelInterface then
    if OpenLPT(tPaddlePortBaseAddress, ActivePaddlePort) then
    begin
      tRuntPaddleAndFootSwitchThread;
      DoingPaddle := True;
    end;

end;

procedure CheckAndInitializeSerialPorts;
var
  BaudRate                              : Cardinal;
begin

  if ActiveRotatorPort <> NoPort then
  begin
    BaudRate := 1200;
    if ActiveRotatorType = DCU1Rotator then BaudRate := 4800;
    InitializeSerialPort(ActiveRotatorPort, BaudRate, 8, tNoParity, 1, FILE_ATTRIBUTE_NORMAL, #0);
  end;
 

  Radio1.CheckAndInitializeSerialPorts_ForThisRadio;
  Radio2.CheckAndInitializeSerialPorts_ForThisRadio;

end;

procedure SetUpGlobalsAndInitialize;
var
FileName : str40;
begin

  StartCPU := GetTickCount;
  udp := TIdUDPClient.Create(nil); // ny4i Issue #99
  if QTCsEnabled then New(QTCDataArray); //LoadQTCDataFile;

//  if TempDomesticQTHDataFileName <> nil then
//    Format(DomQTHDataFileName, '%sDOM\%s.DOM', TR4W_PATH_NAME, TempDomesticQTHDataFileName);

  if DomQTHDataFileName[0] <> #0 then
  begin
   if fileexists(TR4W_DOM_FILENAME) then                       // 4.100.2
    Format(wsprintfBuffer, '%s', TR4W_DOM_FILENAME)
    else
    Format(wsprintfBuffer, '%sdom\%s', TR4W_PATH_NAME, DomQTHDataFileName);
    Windows.ZeroMemory(@DomQTHDataFileName, SizeOf(DomQTHDataFileName));
    Windows.lstrcat(DomQTHDataFileName, wsprintfBuffer);
    if not DomQTHTable.LoadInDomQTHFile(DomQTHDataFileName) then halt;
  end;


  //wli  if DVPEnable then
  begin
    //         WriteLn('DVP Initialization in process...');
    DVPInit;
  end;

//  ActiveRadio := RadioOne;
//  InactiveRadio := RadioTwo; {KK1L: 6.73}

//  TotalQSOPoints := 0;

  if AutoTimeIncrementQSOs <> 0 then IncrementTimeEnable := True;

  DoingDomesticMults := ActiveDomesticMult <> NoDomesticMults;
  DoingDXMults := ActiveDXMult <> NoDXMults;
  DoingPrefixMults := ActivePrefixMult <> NoPrefixMults;
  DoingZoneMults := ActiveZoneMult <> NoZoneMults;

  //  NumberDifferentMults := 0;

  {KK1L: 6.68 This may need to change to something like...don't know. It works as is.  }
  {IF (DoingDomesticMults)AND                                                          }
  {   ((DomesticQTHDataFileName <> '') OR (ActiveDomesticMult = WYSIWYGDomestic)) THEN }

  if DoingDomesticMults then                              // Gav 4.44.8      Display remaining domestic Mults
  begin
    if RemainingMultDisplay = rmNoRemMultDisplay then
      RemainingMultDisplay := rmDomestic;
    inc(NumberDifferentMults);
  end;

  if DoingDXMults then
  begin
    inc(NumberDifferentMults);
    if RemainingMultDisplay = rmNoRemMultDisplay then
      RemainingMultDisplay := rmDX;
  end;

  if DoingZoneMults then
  begin
    inc(NumberDifferentMults);
    if RemainingMultDisplay = rmNoRemMultDisplay then
      RemainingMultDisplay := rmZone;
  end;

  if DoingPrefixMults then
  begin
    inc(NumberDifferentMults);
    if RemainingMultDisplay = rmNoRemMultDisplay then
      RemainingMultDisplay := rmPrefix;
  end;

  LoadSpecialHelloFile;

  //   !!! ����� �� ���� ������ ��� ���� ���
  //��������� ptt �  ����������
  {
    if DDXState <> Off then
    begin
      RadioOneKeyerOutputPort := NoPort;
      RadioTwoKeyerOutputPort := NoPort;
    end;
  }
//  TailEnding := False;

  {Before restart.bin load}
  Windows.CopyMemory(@FreqMemory, @DefaultFreqMemory, SizeOf(TFreqMemoryType));

  Sheet.SheetInitAndLoad;
  LoadBandMap;
  DisplayContestTitle;

  if CurrentOperator[0] = #0 then  // ny4i Issue #97
     begin
     StrPLCopy(CurrentOperator, MyCall, High(CurrentOperator)); // This copies the string MyCall to char array CurrentOperator (I love mixed types :) ) // ny4i
     end;

  CheckAndInitializeSerialPorts;
  InitializeKeyer;
//  ActiveKeyerPort := ActiveRadioPtr.tKeyerPort;
//  tActiveKeyerHandle := ActiveRadioPtr.tKeyerPortHandle;

  TryRunPaddleAndFootSwitchThread;
  InitializeOtherLPTPorts;
  MonitorTone := CWTone;

//  ActiveBand := ActiveRadioPtr.BandMemory;
//  ActiveMode := ActiveRadioPtr.ModeMemory;

  DisplayCodeSpeed;
  Str(Radio1.SpeedMemory, SpeedString); {KK1L: 6.73 Initialize SpeedString for ALT-D use.}
  // SetSpeed(CodeSpeed);  // ny4i Issue 153 Not necessary as SetUpToSendOnActiveRadio is called and sets the speed

  if AutoSendCharacterCount > 0 then
  begin
    AutoSendEnable := True;
    DisplayAutoSendCharacterCount;
  end;
{
  if ReadInLog then
  begin
    AutoDupeEnableCQ := False;

    if CWTone = 0 then
    begin
      FlushCWBufferAndClearPTT;
      CWEnabled := False;
    end;
  end;
}
//  K5KA.AltDString := '';
//  K5KA.State := KAIdle;
//  MarkTime(RITCommandTimeStamp);


end;

function LoadInSeparateConfigFile(FileName: ShortString; var FirstCommand: boolean; Call: CallString): boolean;

var
  ConfigRead                            : Text;
  FileString                            : ShortString;
  LineNumber                            : integer;

begin
 //n4af 4.36.3 ADDED FUNCTION
  LoadInSeparateConfigFile := False;
  LineNumber := 1;

  GetRidOfPrecedingSpaces(FileName);

   if OpenFileForRead_old(ConfigRead, FileName) then         // ADDED 4.36.3
 //if tf.topenFileForRead(h, FileName) then

  begin
     while not Eof(ConfigRead) do
    begin
      ReadLn(ConfigRead, FileString);

      if StringHas(UpperCase(FileString), 'MY CALL') and (Call <> '') then
      begin
        FirstCommand := False;
        Continue;
      end;

      if not ProcessConfigInstruction(FileString, FirstCommand) then
      begin
              //        WriteLn;
              //        WriteLn('INVALID STATEMENT IN ', FileName, '!!  Line ', LineNumber);
              //        WriteLn(FileString);
        FileString[length(FileString) + 1] := #0;
        asm
        lea eax,[FileString+1]
        push eax
        push LineNumber
        lea eax,[FileName+1]
        push eax
        end;
        wsprintf(wsprintfBuffer, TC_INVALIDSTATEMENTIN);
        asm add esp,20
        end;
        showwarning(wsprintfBuffer);
        Exit;
      end;

      inc(LineNumber);
    end;

    Close(ConfigRead);
    LoadInSeparateConfigFile := True;
  end   
  
  else
  begin
    FileName[Ord(FileName[0]) + 1] := #0;
    asm
    lea eax, [FileName+1]
    push eax
    end;
    wsprintf(wsprintfBuffer, TC_UNABLETOFIND);
    asm add esp,12
    end;
    showwarning(wsprintfBuffer);
    Exit;
  end;
 // n4af }
end;

procedure ReadInConfigFile(ConfigFileName: TCFGType);

{ This procedure will read in the config file which contains the
  initial values for several global variables.  This makes it easier to
  restart the program in case of a power failure. }

begin
  if ConfigFileName = cfgCFG then ClearDomesticCountryList;
  LineNumberInConfigFile := 0;
  CurrentConfigFile := ConfigFileName;
  EnumerateLinesInFile(CFGFilesArray[ConfigFileName], EnmuCFGFile, True);

  if ConfigFileName = cfgCFG then if not ConfigurationOkay then halt;
end;

procedure LookForCommands(var ContestConfigFileTitle: Str20);

var
  Result, ParameterCount                : integer;
  LastPushedLogName                     : Str20; {KK1L: 6.71}
  TempString                            : Str40;

begin
  PacketFile := False;
   for ParameterCount := 1 to ParamCount do
  begin


    if UpperCase(ParamStr(ParameterCount)) = 'BANDMAP' then
      FakeBandMap := True;

    if UpperCase(ParamStr(ParameterCount)) = 'DEBUG' then
       begin
       DebugFlag := True;
       logger.Level := Debug;
       end;

     if UpperCase(ParamStr(ParameterCount)) = 'TRACE' then
       begin
       DebugFlag := True;
       logger.Level := Trace;
       end;

    if UpperCase(ParamStr(ParameterCount)) = 'FOOTSWITCHDEBUG' then
      FootSwitchDebug := True;


    if UpperCase(ParamStr(ParameterCount)) = 'NETDEBUG' then NetDebug := True;

    if UpperCase(ParamStr(ParameterCount)) = 'PACKET' then
      FakePacket := True;

    if UpperCase(ParamStr(ParameterCount)) = 'PACKETFILE' then
    begin
      WriteLn('Opening ', ParamStr(ParameterCount + 1), ' as a packet file to process.');
    end;

    if UpperCase(ParamStr(ParameterCount)) = 'PACKETINPUTFILE' then
    begin
      Packet.PacketInputFileName := ParamStr(ParameterCount + 1);

      if StringIsAllNumbers(ParamStr(ParameterCount + 2)) then
      begin
        TempString := ParamStr(ParameterCount + 2);
        Val(TempString, PacketInputFileDelay, Result);
      end;
    end;

    if UpperCase(ParamStr(ParameterCount)) = 'READ' then
    begin
//      ReadInLog := True;
      ReadInLogFileName := ParamStr(ParameterCount + 1);
          ////{WLI}            Inc (ParameterCount);
    end;

      {KK1L: 6.71 Added as a multiplier and dupe check}

    if UpperCase(ParamStr(ParameterCount)) = 'RESCORE' then
    begin
      PushLogFiles(LastPushedLogName);
      ReadInLogFileName := LastPushedLogName;
      WriteLn('Ready to rescore ', ReadInLogFileName, '!');
    end;

    if (UpperCase(ParamStr(ParameterCount)) = 'RADIODEBUG') or
      (UpperCase(ParamStr(ParameterCount)) = 'SERIALDEBUG') or
      (UpperCase(ParamStr(ParameterCount)) = 'TALKDEBUG') then
      CPUKeyer.SerialPortDebug := True;


  end;
end;

procedure tSetupExchangeNumbers;
var
  tCQExchange, tSPExchange              : ShortString;
  Grid                                  : ShortString;
begin


  tSPExchange := '';
  tCQExchange := '';
  Grid := Copy(MyGrid, 1, 4);
  case Contest of

    MAKROTHEN:
      begin
        tCQExchange := ' ' + Grid + ' ' + Grid;
      end;

    RADIOMEMORY, WISCONSINQSOPARTY: tCQExchange := ' ' + MyState;

    LQP, NCCCSPRINT: tCQExchange := ' # ' + MyName + ' ' + MyState;

//    JTDX, REGION1FIELDDAY, REGION1FIELDDAY_RCC_CW, UCG: tCQExchange := ' 5NN #';

    R9W_UW9WK_MEMORIAL, CUPURAL, UKRAINECHAMPIONSHIP, RFASCHAMPIONSHIPCW, RFCHAMPIONSHIPCW, RFCHAMPIONSHIPSSB: tCQExchange := ' ' + MyState + '#';

    ALRS_UA1DZ_CUP, OLDNEWYEAR, TENNESSEEQSOPARTY, SALMONRUN, ALLASIANCW, ALLASIANSSB, SEVENQP, ARRL160, ARRLDXCW: tCQExchange := ' 5NN ' + MyState;

    OHIOQSOPARTY, CALQSOPARTY, UA4WCHAMPIONSHIP, RAEM, CUPRFCW, CUPRFSSB: tCQExchange := ' # ' + MyState;
{
    ARI, SPDX, ARKTIKA_SPRING, PACC, WAG, CUPUA1DZ, RUSSIANDX, RDA, OKDX, UKRAINIAN, OLDNEWYEAR, ARRL10, HADX, YODX, RSGB18, DARCXMAS:
      begin
        if MyState <> '' then tCQExchange := ' 5NN ' + MyState else tCQExchange := ' 5NN #';
      end;
}
    JIDXCW, JIDXSSB, CQ160SSB, CQ160CW, LZDX, IARU, OZCR_O, OZCR_Z:
      begin
        if MyState <> '' then
          tCQExchange := ' 5NN ' + MyState
        else
          tCQExchange := ' 5NN ' + MyZone;
      end;

    CQIR:
      begin
        if MyState <> '' then
          tCQExchange := ' ' + MyState + ' #'
        else
          tCQExchange := ' #';
      end;

    NZFIELDDAY:
      tCQExchange := ' 5NN # ' + MyZone;

//    EUROPEANHFC, CQWWCW, CQWWSSB, GACWWWSACW, GAGARINCUP: tCQExchange := ' 5NN ' + MyZone;
    {CZECH_ACTIVITY_VHF,}OZHCRVHF, RADIOVHFFD: tCQExchange := ' 5NN # ' + MyGrid;

    NRAUBALTICCW, NRAUBALTICSSB, RU3AXMEMORIAL, {WWPMC,} UBACW, UBASSB: tCQExchange := ' 5NN # ' + MyState;

   PCC, IOTA, HELVETIA: if MyState <> '' then tCQExchange := ' 5NN # ' + MyState else tCQExchange := ' 5NN #';

    EUSPRINT_SPRING_SSB, EUSPRINT_AUTUMN_CW, EUSPRINT_AUTUMN_SSB, EUSPRINT_SPRING_CW:
      begin
        tCQExchange := ' DE \ # ' + MyName;
        tSPExchange := '@' + tCQExchange;
      end;

    CWOPEN:
      begin
        tCQExchange := ' # ' + MyName;
      end;

  end;

{$IF MMTTYMODE}
{
  case Contest of
    CQWWRTTY:
      begin
        tCQExchange := ' 599 ' + MyZone + ' ' + MyZone;
      end;

    CUPRFDIG:
      begin

      end;
  end;
  CQExchange := tCQExchange;
  SearchAndPounceExchange := tCQExchange;
  RepeatSearchAndPounceExchange := tCQExchange;
  CQExchangeNameKnown := tCQExchange;
  Exit;
}
{$IFEND}

  if CQExchange = '' then
    CQExchange := tCQExchange;

  if SearchAndPounceExchange = '' then
    SearchAndPounceExchange := {$IF MMTTYMODE} '_@_' + {$IFEND}CQExchange;

  if RepeatSearchAndPounceExchange = '' then
    RepeatSearchAndPounceExchange := tSPExchange;

  if CQExchangeNameKnown = '' then
    CQExchangeNameKnown := tCQExchange;
end;

procedure EnmuCFGFile(FileString: PShortString);
var
  ID                                    : ShortString;
  CMD                                   : ShortString;
 begin

  if FileString^[1] in [';', '[', '_'] then Exit;

  GetRidOfPrecedingSpaces(FileString^);
  GetRidOfPostcedingSpaces(FileString^);


  ID := PrecedingString(FileString^, '=');
  CMD := PostcedingString(FileString^, '=');

  if ID = '' then Exit;

  GetRidOfPrecedingSpaces(ID);
  GetRidOfPrecedingSpaces(CMD);
  GetRidOfPostcedingSpaces(ID);
  GetRidOfPostcedingSpaces(CMD);

  inc(LineNumberInConfigFile);

  if CurrentConfigFile = cfgINI then
    if LineNumberInConfigFile > 155 then
      asm nop end;

  if CurrentConfigFile = cfgCFG then
  begin
    if LineNumberInConfigFile = 1 then
      if ID <> 'MY CALL' then
      begin
        showwarning(TC_THEFIRSTCOMMANDINCONFIGFILEMUSTBE);
        halt;
      end;

  end;

  if CMD = 'SPACE' then CMD[1] := ' ';
   if cmd = 'FM' then
  CMD := 'FM';
  if not CheckCommand(@ID, CMD) then
  begin
    Format(wsprintfBuffer, TC_INVALIDSTATEMENTINCONFIGFILE, CFGFilesArray[CurrentConfigFile], LineNumberInConfigFile, @FileString^[1]);
    showwarning(wsprintfBuffer);
//    halt;
  end;
end;

//begin
  //  RemainingMultDisplayMode := NoRemainingMults;
  //  RunningConfigFile := False;
end.
