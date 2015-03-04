unit uProcessCommand;

{$IMPORTEDDATA OFF}

interface

uses
  uMMTTY,
utils_text,
  VC,
  TF,
  uWinKey,
  uCFG,
  uTelnet,
  LogCfg,
  uNet,
  uIO,
  LOGSUBS1,
  LOGSUBS2,
  Windows,
  Tree,
  LogWind,
  LogRadio,
  uRadioPolling,
  MainUnit,
  LogEdit,
  LogCW,
  LogK1EA,
  CFGCMD,
  LogStuff;

type
  TsCommandsArrayType = packed record
    caCommand: PChar;
    caAddress: Pointer;
  end;

  type
  TsCWCharsArrayType = packed record
    CWChars: PChar;
    CWAddress: Pointer;
  end;
  
procedure scSRS;
procedure scSRSI;
procedure scSRS1;
procedure scSRS2;

procedure scWK_SWAPTUNE;
procedure scEXCHANGERADIOS;
procedure scWK_RESET;
procedure scSENDMESSAGE;
procedure scTOGGLECW;
procedure scBANDUP;
procedure scBANDDOWN;
procedure scCWMONITORON;
procedure scCWMONITOROFF;
procedure scWINEXEC;
procedure scDISABLECW;
procedure scENABLECW;
procedure scSAPMODE;
procedure scCQMODE;
procedure scCWENABLETOGGLE;
procedure scEXECUTE;
procedure scRADIOONELPTMASK;
procedure scCABRILLO;
procedure scFLUSHINITIALEX;
procedure scSNLOCKOUT;
procedure scSNRELEASE;
procedure scLASTSPFREQ;
procedure scLASTCQFREQ;
procedure scSENDTOCLUSTER;
procedure scDUPECHECK;
procedure scBOOLSWAP;

procedure csMMTTY_GRABLASTCALL;
procedure csMMTTY_SWITCH_TO_RX_IMMEDIATELY;
procedure csMMTTY_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED;
procedure csMMTTY_SWITCH_TO_TX;
procedure csMMTTY_CLEAR_THE_TX_BUFFER;

const

  sCommands                             = 57      {$IF MMTYMODE} + 5 {$IFEND} ;  //n4af
  sCommandsArray                        : array[0..sCommands - 1] of TsCommandsArrayType =
    (

{$IF MMTTYMODE}    //5
    (caCommand: 'MM_CLEAR_THE_TX_BUFFER'; caAddress: @csMMTTY_CLEAR_THE_TX_BUFFER),
    (caCommand: 'MM_SWITCH_TO_TX'; caAddress: @csMMTTY_SWITCH_TO_TX),
    (caCommand: 'MM_SWITCH_TO_RX_IMMEDIATELY'; caAddress: @csMMTTY_SWITCH_TO_RX_IMMEDIATELY),
    (caCommand: 'MM_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED'; caAddress: @csMMTTY_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED),
    (caCommand: 'MM_GRABLASTCALL'; caAddress: @csMMTTY_GRABLASTCALL),
{$IFEND}

//{$IF CWMODE}     //20

(caCommand: '  # = QSO Number '; caAddress: @scEXCHANGERADIOS),     //n4af 04.33.2
(caCommand: '  @ = HisCall '; caAddress: @scEXCHANGERADIOS),
(caCommand: '  $ = Salutation/Name '; caAddress: @scEXCHANGERADIOS),
(caCommand: '  % = Name from Names DB'; caAddress: @scEXCHANGERADIOS),
(caCommand: ' : = Send from K.B.'; caAddress: @scEXCHANGERADIOS),
(caCommand: ' ~ = Salutation - no name'; caAddress: @scEXCHANGERADIOS),
(caCommand: '  \ = My Call'; caAddress: @scEXCHANGERADIOS),
(caCommand: ' | = Name from Exch Window'; caAddress: @scEXCHANGERADIOS),
(caCommand: ' [ = Wait for # (RST)'; caAddress: @scEXCHANGERADIOS),
(caCommand: ' ] = Repeat last RST from ['; caAddress: @scEXCHANGERADIOS),
(caCommand: '  ^ = Half space'; caAddress: @scEXCHANGERADIOS),
(caCommand: '  CTRL-P CTRL-F = Faster'; caAddress: @scEXCHANGERADIOS),
(caCommand: '  CTRL-P CTRL-S = Slower'; caAddress: @scWK_SWAPTUNE),
(caCommand: ' + = AR'; caAddress: @scWK_RESET),
(caCommand: '  > = Reset RIT'; caAddress: @scSENDMESSAGE),
(caCommand: ' < = SK'; caAddress: @scBOOLSWAP),
(caCommand: ' = = BT'; caAddress: @tClearDupesheet),
(caCommand: ' ! = SN'; caAddress: @tClearMultSheet),
(caCommand: ' & = AS'; caAddress: @scDUPECHECK),
(caCommand: ' ) = Last QSOs Call'; caAddress: @scDUPECHECK),
//{$IFEND}
    (caCommand: 'NEXTBANDMAP'; caAddress: @GoToNextBandMapFrequency),
    (caCommand: 'SENDTOCLUSTER'; caAddress: @scSENDTOCLUSTER),
    (caCommand: 'LASTCQFREQ'; caAddress: @scLASTCQFREQ),
    (caCommand: 'LASTSPFREQ'; caAddress: @scLASTSPFREQ),
    (caCommand: 'ENTER'; caAddress: @ProcessReturn),
    (caCommand: 'ESCAPE'; caAddress: @Escape_proc),
    (caCommand: 'COMPLETECALL'; caAddress: @CompleteCallsign),
    (caCommand: 'SWAPRADIOS'; caAddress: @SwapRadios),
    (caCommand: 'TOGGLEMODES'; caAddress: @ToggleModes),
    (caCommand: 'TOGGLESTEREOPIN'; caAddress: @ToggleStereoPin),
    (caCommand: 'TOGGLECW'; caAddress: @scTOGGLECW),
    (caCommand: 'BANDUP'; caAddress: @scBANDUP),
    (caCommand: 'BANDDOWN'; caAddress: @scBANDDOWN),
    (caCommand: 'CWMONITORON'; caAddress: @scCWMONITORON),
    (caCommand: 'CWMONITOROFF'; caAddress: @scCWMONITOROFF),
    (caCommand: 'WINEXEC'; caAddress: @scWINEXEC),
    (caCommand: 'DISABLECW'; caAddress: @scDISABLECW),
    (caCommand: 'ENABLECW'; caAddress: @scENABLECW),
    (caCommand: 'EXCHANGERADIOS'; caAddress: @scEXCHANGERADIOS),
    (caCommand: 'SAPMODE'; caAddress: @scSAPMODE),
    (caCommand: 'CQMODE'; caAddress: @scCQMODE),
    (caCommand: 'CONTROLENTER'; caAddress: @tr4w_log_qso_without_cw),
    (caCommand: 'CWENABLETOGGLE'; caAddress: @scCWENABLETOGGLE),
    (caCommand: 'EXECUTE'; caAddress: @scEXECUTE),
    (caCommand: 'CABRILLO'; caAddress: @scCABRILLO),
    (caCommand: 'INITIALIZEQSO'; caAddress: @InitializeQSO),
    (caCommand: 'AUTOCQ'; caAddress: @RunAutoCQ),
    (caCommand: 'SPACEBAR'; caAddress: @SpaceBarProc2),
    (caCommand: 'SRS'; caAddress: @scSRS),
    (caCommand: 'SRSI'; caAddress: @scSRSI),
    (caCommand: 'SRS1'; caAddress: @scSRS1),
    (caCommand: 'SRS2'; caAddress: @scSRS2),
    (caCommand: 'RADIOONELPTMASK'; caAddress: @scRADIOONELPTMASK),
    (caCommand: 'FLUSHINITIALEX'; caAddress: @scFLUSHINITIALEX),
    (caCommand: 'SNLOCKOUT'; caAddress: @scSNLOCKOUT),
    (caCommand: 'CLEARDUPESHEET'; caAddress: @tClearDupesheet_Ctrl_K)  ,
    (caCommand: 'CLEARMULTSHEET'; caAddress: @ClearMultSheet_CtrlC) 
    )
    ;

function FoundCommand(var SendString: Str160): boolean;

var
  scFileName                            : ShortString;
implementation

function FoundCommand(var SendString: Str160): boolean;

var
  CommandString                         : ShortString;
  TempInt, Result1                      : integer;
  i                                     : integer;
  p                                     : Pointer;
begin
  FoundCommand := False;

  CommandUseInactiveRadio := False;

  while StringHas(SendString, ControlC) do
  begin
    if not StringHas(SendString, ControlD) then Exit;

    FoundCommand := StringHas(SendString, ControlD);

    CommandString := {UpperCase}(BracketedString(SendString, ControlC, ControlD));
    Delete(SendString, pos(ControlC, SendString), pos(ControlD, SendString) - pos(ControlC, SendString) + 1);

    if Copy(CommandString, 1, 1) = ControlA then {KK1L: 6.73 Vector commands to inactive radio with CTRL-A}
    begin
      CommandUseInactiveRadio := True;
      Delete(CommandString, 1, 1);
    end;

    if StringHas(CommandString, '=') then
    begin
      scFileName := PostcedingString(CommandString, '=');
      CommandString := PrecedingString(CommandString, '=');
    end;

    CommandString[Ord(CommandString[0]) + 1] := #0;
    scFileName[length(scFileName) + 1] := #0;

    for i := 0 to sCommands - 1 do
    begin
      if StrComp(sCommandsArray[i].caCommand, @CommandString[1]) = 0 then
      begin
        p := sCommandsArray[i].caAddress;
        asm
        call p
        end;

        p := PChar(sCommandsArray[i].caCommand);
        asm push p end;
        wsprintf(QuickDisplayBuffer, '"%s" command is executed.');
        asm add esp,12 end;
        QuickDisplay(QuickDisplayBuffer);
 
        Break;

      end;
    end;
{
    if CommandString = 'WINEXEC' then
    begin
      if Windows.WinExec(@scFileName[1], SW_SHOWMINIMIZED) < 31 then
        ShowSysErrorMessage('WINEXEC');
    end;
}
{
    if CommandString = 'SRS' then
    begin
      if ActiveRadioPtr.RadioModel in [IC706..IC7800, OMNI6] then
        ActiveRadioPtr.ICOM_COMMAND_CUSTOM := scFileName
      else
        WriteToSerialCATPort(scFileName, ActiveRadioPtr.tCATPortHandle);
    end;

    if CommandString = 'SRSI' then
    begin
      if InActiveRadioPtr.RadioModel in [IC706..IC7800, OMNI6] then
        InActiveRadioPtr.ICOM_COMMAND_CUSTOM := scFileName
      else
        WriteToSerialCATPort(scFileName, InActiveRadioPtr.tCATPortHandle);
    end;

    if CommandString = 'SRS1' then
    begin
      if Radio1.RadioModel in [IC706..IC7800, OMNI6] then
        Radio1.ICOM_COMMAND_CUSTOM := scFileName
      else
        WriteToSerialCATPort(scFileName, Radio1.tCATPortHandle);
    end;

    if CommandString = 'SRS2' then
    begin
      if Radio2.RadioModel in [IC706..IC7800, OMNI6] then
        Radio2.ICOM_COMMAND_CUSTOM := scFileName
      else
        WriteToSerialCATPort(scFileName, Radio2.tCATPortHandle);
    end;
}
//    if CommandString = 'MEMORYIN' then PushFrequencyToStack;
//    if CommandString = 'MEMORYREAD' then PopFrequencyFromStack;
//    if CommandString = 'ADDMULTFREQ' then AddFrequencyToMFArray;
{
    if (CommandString = 'COMPLETECALL') or (CommandString = 'COMPLETECALLSIGN') then
    begin
      CompleteCallsign;
    end;
}

    if CommandString = 'ENTER' then ProcessReturn;
    if CommandString = 'ESCAPE' then Escape_proc;
 

{
    if CommandString = 'BANDUP' then
    begin
          //WLI             RememberFrequency; KK1L: 6.72 Added to match all other calls. Needed for loss of coms
      BandDownOrUp(DirectionUp);
    end;

    if CommandString = 'BANDDOWN' then
    begin
          //             RememberFrequency; //KK1L: 6.72 Added to match all other calls. Needed for loss of coms
      BandDownOrUp(DirectionDown);
    end;
}
//    if CommandString = 'CONTROLENTER' then CWMessageCommand := CWCommandControlEnter;

//    if CommandString = 'CWENABLETOGGLE' then CWEnable := not CWEnable;
{
    if CommandString = 'CWMONITORON' then
    begin
      if OldCWTone = 0 then OldCWTone := 700;
      CWTone := OldCWTone;
      AddStringToBuffer('', CWTone);
    end;
}
{
    if CommandString = 'DVKDELAY' then
      if StringIsAllNumbers(scFileName) then
      begin
        Val(scFileName, TempInt, Result1);
        SetDVKDelay(TempInt);
      end;
}
{
    if CommandString = 'CWMONITOROFF' then
      if CWTone <> 0 then
      begin
        OldCWTone := CWTone;
        CWTone := 0;
        AddStringToBuffer('', CWTone);
      end;
}
//    if CommandString = 'DISABLECW' then CWEnable := False;
      //      if CommandString = 'DUPECHECK' then DupeCheckOnInactiveRadio;

//    if CommandString = 'ENABLECW' then CWEnable := True;

      //{WLI}         IF CommandString = 'EXCHANGERADIOS' THEN ExchangeRadios; {KK1L: 6.71}
{
    if CommandString = 'EXECUTE' then
    begin
      RunningConfigFile := True;
      ClearDupeSheetCommandGiven := False;

      FirstCommand := False;

//      if FileExists(FileName) then        LoadInSeparateConfigFile(FileName, FirstCommand, MyCall);
  }
      if ClearDupeSheetCommandGiven then
      begin
        tClearDupesheet;
              //        MoveEditableLogIntoLogFile;
              //        UpdateTotals2;
              //        Sheet.ClearDupeSheet;
      end;
 {
      RunningConfigFile := False;
    end;


    if CommandString = 'NEXTBANDMAP' then
    begin
      if not CommandUseInactiveRadio then
        CallWindowString := '';

      GoToNextBandMapFrequency;

      if not CommandUseInactiveRadio then //KK1L: 6.73 applies to active radio only
        CWMessageCommand := CWCommandSAPMode; //KK1L: 6.68 Takes you to S&P mode when surfing band map
    end;

      //KK1L: 6.64 finds next entry from displayed bandmap rather than just current band/mode
    if CommandString = 'NEXTDISPLAYEDBANDMAP' then
    begin
      if not CommandUseInactiveRadio then
        CallWindowString := '';

      GoToNextDisplayedBandMapFrequency;

      if not CommandUseInactiveRadio then
        CWMessageCommand := CWCommandSAPMode;
    end;

    if CommandString = 'NEXTMULTBANDMAP' then
    begin
      if not CommandUseInactiveRadio then
        CallWindowString := '';

      GoToNextMultBandMapFrequency;

      if not CommandUseInactiveRadio then
        CWMessageCommand := CWCommandSAPMode;
    end;

    if CommandString = 'NEXTMULTDISPLAYEDBANDMAP' then
    begin
      if not CommandUseInactiveRadio then
        CallWindowString := '';

      GoToNextMultDisplayedBandMapFrequency;

      if not CommandUseInactiveRadio then
        CWMessageCommand := CWCommandSAPMode;
    end;
 
 }
//    if CommandString = 'LASTCQFREQ' then
//    begin
//      if not CommandUseInactiveRadio then {KK1L: 6.73 applies to active radio only}
//        CallWindowString := ''; {KK1L: 6.69 clears callwindow}

//      if not CommandUseInactiveRadio then {KK1L: 6.73 applies to active radio only}
//        CWMessageCommand := CWCommandCQMode; {KK1L: 6.68 Takes you to CQ mode when returning to CQ freq}
//    end;

      //{WLI}         IF CommandString = 'LOGLASTCALL'    THEN LogLastCall;

    if CommandString = 'QSY' then CWMessageCommand := CWCommandQSY;

//    if CommandString = 'SAPMODE' then CWMessageCommand := CWCommandSAPMode;
//    if CommandString = 'CQMODE' then CWMessageCommand := CWCommandCQMode;

    if Copy(CommandString, 1, 5) = 'SPEED' then
    begin
      Delete(CommandString, 1, 5);

      if StringIsAllNumbers(CommandString) then
      begin
        Val(CommandString, TempInt, Result1);
        SetSpeed(TempInt);
        DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
      end
      else
      begin
        while Copy(CommandString, 1, 1) = '+' do
        begin
          Delete(CommandString, 1, 1);

          if CodeSpeed < 99 then
          begin
            SetSpeed(CodeSpeed + 1);
            DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
          end;
        end;

        while Copy(CommandString, 1, 1) = '-' do
        begin
          Delete(CommandString, 1, 1);

          if CodeSpeed > 1 then
          begin
            SetSpeed(CodeSpeed - 1);
            DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
          end;
        end;
      end;
    end;
  end;

  CommandUseInactiveRadio := False; {KK1L: 6.73 Put back to normal so other calls default to active radio}
end;

procedure scTOGGLECW;
begin
  ToggleCW(False);
end;

procedure scBANDUP;
begin
  ProcessMenu(menu_alt_bandup);
end;

procedure scBANDDOWN;
begin
  ProcessMenu(menu_alt_banddown);
end;

procedure scCWMONITORON;
begin
  if OldCWTone = 0 then OldCWTone := 700;
  CWTone := OldCWTone;
  AddStringToBuffer('', CWTone);
end;

procedure scCWMONITOROFF;
begin
  if CWTone <> 0 then
  begin
    OldCWTone := CWTone;
    CWTone := 0;
    AddStringToBuffer('', CWTone);
  end;
end;

procedure scWINEXEC;
begin
  if Windows.WinExec(@scFileName[1], SW_SHOWMINIMIZED) < 31 then
    ShowSysErrorMessage('WINEXEC');
end;

procedure scDISABLECW;
begin
  CWEnable := False;
end;

procedure scENABLECW;
begin
  CWEnable := True;
end;

procedure scSAPMODE;
begin
  SetOpMode(SearchAndPounceOpMode);
end;

procedure scCQMODE;
begin
  SetOpMode(CQOpMode);
end;

procedure scCWENABLETOGGLE;
begin
  CWEnable := not CWEnable;
end;

procedure scEXECUTE;

begin
  ExecuteConfigurationFile(scFileName);
{
  RunningConfigFile := True;
  ClearDupeSheetCommandGiven := False;
  FirstCommand := False;
  if FileExists(@scFileName[1]) then
    LoadInSeparateConfigFile(scFileName, FirstCommand, MyCall);
  if ClearDupeSheetCommandGiven then tClearDupesheet;
  RunningConfigFile := False;
  }
end;

procedure scSRS;
begin
  if ActiveRadioPtr.RadioModel in [IC706..IC7800, OMNI6] then
  begin
//    ActiveRadioPtr.ICOM_COMMAND_CUSTOM := scFileName;
//    ActiveRadioPtr.CommandsTempBuffer
    Windows.CopyMemory(@ActiveRadioPtr.CommandsTempBuffer[1], @scFileName[1], length(scFileName));
    ActiveRadioPtr.CommandsTempBuffer[0] := CHR(length(scFileName));
    ActiveRadioPtr.AddCommandToBuffer;
  end
  else
//    WriteToSerialCATPort(scFileName, ActiveRadioPtr.tCATPortHandle);
    ActiveRadioPtr.WriteToCATPort(scFileName[1], length(scFileName));
end;

procedure scSRSI;
begin
  if InActiveRadioPtr.RadioModel in [IC706..IC7800, OMNI6] then
  begin
    Windows.CopyMemory(@InActiveRadioPtr.CommandsTempBuffer[1], @scFileName[1], length(scFileName));
    InActiveRadioPtr.CommandsTempBuffer[0] := CHR(length(scFileName));
    InActiveRadioPtr.AddCommandToBuffer;
  end
//    InActiveRadioPtr.ICOM_COMMAND_CUSTOM := scFileName
  else
//    WriteToSerialCATPort(scFileName, InActiveRadioPtr.tCATPortHandle);
    InActiveRadioPtr.WriteToCATPort(scFileName[1], length(scFileName));
end;

procedure scSRS1;
begin
  if Radio1.RadioModel in [IC706..IC7800, OMNI6] then
  begin
    Windows.CopyMemory(@Radio1.CommandsTempBuffer[1], @scFileName[1], length(scFileName));
    Radio1.CommandsTempBuffer[0] := CHR(length(scFileName));
    Radio1.AddCommandToBuffer;
  end
//    Radio1.ICOM_COMMAND_CUSTOM := scFileName
  else
//    WriteToSerialCATPort(scFileName, Radio1.tCATPortHandle);
    Radio1.WriteToCATPort(scFileName[1], length(scFileName));
end;

procedure scSRS2;
begin
  if Radio2.RadioModel in [IC706..IC7800, OMNI6] then
  begin
    Windows.CopyMemory(@Radio2.CommandsTempBuffer[1], @scFileName[1], length(scFileName));
    Radio2.CommandsTempBuffer[0] := CHR(length(scFileName));
    Radio2.AddCommandToBuffer;
  end
//    Radio2.ICOM_COMMAND_CUSTOM := scFileName
  else
//    WriteToSerialCATPort(scFileName, Radio2.tCATPortHandle);
    Radio2.WriteToCATPort(scFileName[1], length(scFileName));
end;

procedure scRADIOONELPTMASK;
var
  TempByte                              : Byte;
  r                                     : integer;
begin
  if Radio1.tPTTStatus = PTT_ON then Exit;
  if not DriverIsLoaded() then Exit;
  if not (Radio1.tKeyerPort in [Parallel1, Parallel2, Parallel3]) then Exit;
  Val(scFileName, TempByte, r);
  if r <> 0 then Exit;
  SetPortByte(Radio1.tKeyerPortHandle, otData, TempByte);
end;

procedure scCABRILLO;
begin
  ProcessMenu(menu_cabrillo);
end;

procedure scFLUSHINITIALEX;
begin
  GenerateCallsignsList(TR4W_INITIALEX_FILENAME);
  QuickDisplay('FLUSHINITIALEX command is executed.');
end;

procedure scSNLOCKOUT;
begin
  SendSerialNumberChange(sntReserved);
end;

procedure scSNRELEASE;
begin
  SendSerialNumberChange(sntFree);
end;

procedure scLASTSPFREQ;
begin
  if LastSPFrequency = 0 then Exit;
  SetRadioFreq(ActiveRadio, LastSPFrequency, LastSPMode, 'A');
  SetOpMode(SearchAndPounceOpMode);
end;

procedure scLASTCQFREQ;
begin
  if LastCQFrequency = 0 then Exit;
  SetRadioFreq(ActiveRadio, LastCQFrequency, LastCQMode, 'A');
  tCleareCallWindow;
  SetOpMode(CQOpMode);
end;

procedure scSENDTOCLUSTER;
begin
  uTelnet.SendViaTelnetSocket(@scFileName[1]);
end;

procedure scDUPECHECK;
begin
  DupeCheckOnInactiveRadio(False);
end;

procedure scBOOLSWAP;
var
  i                                     : integer;
  p                                     : Pointer;
begin
  for i := 1 to CommandsArraySize do
    if StrComp(@scFileName[1], CFGCA[i].crCommand) = 0 then
      if CFGCA[i].crType = ctBoolean then
      begin
        PBoolean(CFGCA[i].crAddress)^ := not PBoolean(CFGCA[i].crAddress)^;
        if CFGCA[i].crP <> 0 then
        begin
          p := CommandsProcArray[CFGCA[i].crP];
          asm call P end;
          Format(QuickDisplayBuffer, '%s=%s', @scFileName[1], BA[PBoolean(CFGCA[i].crAddress)^]);
          QuickDisplay(QuickDisplayBuffer);
        end;
        Break;
      end;
end;

procedure scWK_RESET;
begin
  wkSendAdminCommand(wkRESET);
end;

procedure scSENDMESSAGE;
begin
  if scFileName <> '' then
  begin
    NetIntercomMessage.imSender := ComputerID;
    Windows.ZeroMemory(@NetIntercomMessage.imMessage, SizeOf(NetIntercomMessage.imMessage));
    NetIntercomMessage.imMessage := scFileName;
    SendToNet(NetIntercomMessage, SizeOf(NetIntercomMessage));
    Exit;
  end;
  ProcessMenu(menu_send_message);
end;

procedure scWK_SWAPTUNE;
begin
  if wkSendTwoBytes($0B, Byte(not wkTune)) = 2 then
    TF.InvertBoolean(wkTune);
end;

procedure scEXCHANGERADIOS;

var
//  R1VFO                                 : VFOStatusType;
//  R2VFO                                 : VFOStatusType;

  R1REC                                 : RadioStatusRecord;
  R2REC                                 : RadioStatusRecord;
const

  VFPLETTERARRAY                        : array[ActiveVFOStatusType] of Char = ('A', 'A', 'B', 'A');
begin
{
  if Radio1.FilteredStatus.VFO[VFOA].Frequency = 0 then Exit;
  if Radio2.FilteredStatus.VFO[VFOA].Frequency = 0 then Exit;

  Windows.CopyMemory(@R2VFO, @Radio1.FilteredStatus.VFO[VFOA], SizeOf(VFOStatusType));
  Windows.CopyMemory(@R1VFO, @Radio2.FilteredStatus.VFO[VFOA], SizeOf(VFOStatusType));

  Radio1.SetRadioFreq(R1VFO.Frequency, R1VFO.Mode, 'A');
  Radio2.SetRadioFreq(R2VFO.Frequency, R2VFO.Mode, 'A');
}

  if Radio1.FilteredStatus.Freq = 0 then Exit;
  if Radio2.FilteredStatus.Freq = 0 then Exit;

  Windows.CopyMemory(@R2REC, @Radio1.FilteredStatus, SizeOf(RadioStatusRecord));
  Windows.CopyMemory(@R1REC, @Radio2.FilteredStatus, SizeOf(RadioStatusRecord));

  Radio1.SetRadioFreq(R1REC.Freq, R1REC.Mode, 'A'{VFPLETTERARRAY[Radio1.FilteredStatus.VFOStatus]});
  Radio2.SetRadioFreq(R2REC.Freq, R2REC.Mode, 'A'{VFPLETTERARRAY[Radio2.FilteredStatus.VFOStatus]});
end;

procedure csMMTTY_GRABLASTCALL;
begin
{$IF MMTTYMODE}
  PutCallToCallWindow(MMTTY.mmttyLastCallsign);
{$IFEND}
end;

procedure csMMTTY_SWITCH_TO_RX_IMMEDIATELY;
begin
{$IF MMTTYMODE}
  PostMmttyMessage(RXM_PTT, RXM_PTT_SWITCH_TO_RX_IMMEDIATELY);
{$IFEND}
end;

procedure csMMTTY_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED;
begin
{$IF MMTTYMODE}
  PostMmttyMessage(RXM_PTT, RXM_PTT_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED);
{$IFEND}
end;

procedure csMMTTY_SWITCH_TO_TX;
begin
{$IF MMTTYMODE}
  PostMmttyMessage(RXM_PTT, RXM_PTT_SWITCH_TO_TX);
{$IFEND}
end;

procedure csMMTTY_CLEAR_THE_TX_BUFFER;
begin
{$IF MMTTYMODE}
  PostMmttyMessage(RXM_PTT, RXM_PTT_CLEAR_THE_TX_BUFFER);
{$IFEND}
end;

end.

