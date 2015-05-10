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
unit JCtrl2;

{$O+}
{$F+}
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  WinSock2,
  Other,
  Tree,
  uDialogs,
  LogStuff,
  LogGrid,
  LogSCP,
  LogCW,
  LogWind,
  LogDupe,
  ZoneCont,
  LogCfg,
  LogDom,
  LOGDVP,
  Country9,
  LogEdit,
  LogK1EA,
  LOGWAE,
  LogPack,
  LOGDDX,
  JCtrl1,
  LogRadio,
  LogNet,
  BeepUnit
{$IF LANG = 'ENG'}, TR4W_CONSTS_ENG{$IFEND}
{$IF LANG = 'RUS'}, TR4W_CONSTS_RUS{$IFEND}
{$IF LANG = 'SER'}, TR4W_CONSTS_SER{$IFEND}
{$IF LANG = 'ESP'}, TR4W_CONSTS_ESP{$IFEND}
  ;

procedure DisplayStatus(FirstEntryDisplayed: MenuEntryType; ActiveEntry: MenuEntryType);
function GetActiveLineFromEntryString(EntryString: Str80): MenuEntryType;
procedure ParameterToString(Line: MenuEntryType; var Value: ShortString);

//procedure ProcessInput(ActiveLine: MenuEntryType);
function ProcessInput(ActiveLine: MenuEntryType): boolean;
procedure SendParameterToNetwork(Line: MenuEntryType);
procedure WriteParameterToLOGCFGFile(FileName: Str80; Line: MenuEntryType);

implementation
uses
  uNet,
  uSpots,
  uOption,
  MainUnit;

procedure DisplayStatus(FirstEntryDisplayed: MenuEntryType; ActiveEntry: MenuEntryType);

var
  LastEntry, Entry                      : MenuEntryType;
  Line                                  : Word;

begin
  //{WLI}    ClrScr;
  LastEntry := FirstEntryDisplayed;

  if LastEntry < LastMenuEntry then
    for Line := 1 to 16 do
    begin
      if LastEntry = Pred(LastMenuEntry) then Break;
      LastEntry := Succ(LastEntry);
    end;

  for Entry := FirstEntryDisplayed to LastEntry do
  begin
    if Entry > FirstEntryDisplayed then WriteLn;
      //      DisplayStatusLine(Entry, Entry = ActiveEntry);

            //{WLI}        WHILE WhereX < 40 DO Write (' ');

    DisplayInfoLine(Entry, Entry = ActiveEntry);
  end;
end;

function ProcessInput(ActiveLine: MenuEntryType): boolean;

var
  TempHour, TempMinute, TempInt, Result1: integer;
  TempReal                              : REAL;
  TempString                            : ShortString;
  TempChar                              : Char;
  TempLongInt                           : LONGINT;
begin
  RESULT := True;
//  Changed[ActiveLine] := True;

  case ActiveLine of
    //W_L_I    DMF, DVK, MCL, MCN, MCU, MZN, VER:
    //W_L_I      begin
    //W_L_I        result := false;
    //W_L_I        MessageBox(, 'You can only change this in your config file.', 'TR4W', MB_OK or MB_ICONWARNING);
    //W_L_I        exit;
    //W_L_I        QuickDisplay('You can only change this in your config file.' + Beep);
    //W_L_I        Wait(3000);
    //W_L_I        RemoveWindow(QuickCommandWindow);
    //W_L_I      end;

    ABE: InvertBoolean(AltDBufferEnable); // := not AltDBufferEnable;
    ABC: InvertBoolean(AlwaysCallBlindCQ); // := not AlwaysCallBlindCQ;
    ACC: InvertBoolean(AllCWMessagesChainable); // := not AllCWMessagesChainable;
    AAU: InvertBoolean(tAllowAutoUpdate);
    AFF: InvertBoolean(AskForFrequencies); // := not AskForFrequencies;
    //    AIO: InvertBoolean(AskIfContestOver); // := not AskIfContestOver;
    ACT: InvertBoolean(AutoCallTerminate); // := not AutoCallTerminate;
    AAD: InvertBoolean(K5KA.ModeEnabled); // := not K5KA.ModeEnabled;
    ADP: InvertBoolean(AutoDisplayDupeQSO); // := not AutoDisplayDupeQSO;
    ADE: InvertBoolean(AutoDupeEnableCQ); // := not AutoDupeEnableCQ;
    ADS: InvertBoolean(AutoDupeEnableSandP); // := not AutoDupeEnableSandP;

    AQI:
      begin
        inc(AutoQSLInterval);
        if AutoQSLInterval > 6 then AutoQSLInterval := 0;
        AutoQSLCount := AutoQSLInterval;
      end;

    AQD:
      begin
        AutoQSONumberDecrement := not AutoQSONumberDecrement;
        DisplayNextQSONumber;
      end;
    ASP: InvertBoolean(AutoSAPEnable); // := not AutoSAPEnable;
    ASR:
      begin {KK1L: 6.72}
        TempInt := QuickEditInteger(TC_NEWAUTOSAPENABLESENSITIVITYINHZSEC, 5);
        if (TempInt > 9) and (TempInt < 10001) then
          AutoSAPEnableRate := TempInt;
      end;
    Arc: InvertBoolean(AutoReturnToCQMode); // := not AutoReturnToCQMode;

    asc:
      begin
        inc(AutoSendCharacterCount);

        if AutoSendCharacterCount > 6 then
        begin
          AutoSendCharacterCount := 0;
          AutoSendEnable := False;
        end
        else
          AutoSendEnable := True;

        DisplayAutoSendCharacterCount;
      end;

    ATI:
      begin
        inc(AutoTimeIncrementQSOs);
        if (AutoTimeIncrementQSOs > 6) then AutoTimeIncrementQSOs := 0;
      end;

    BEN:
      begin
        InvertBoolean(BackCopyEnable); //wli
        {wli
                if DVPEnable then
                begin
                  BackCopyEnable := not BackCopyEnable;
                  if (BackCopyEnable) and DVPActive then
                    StartBackCopy
                  else
                    StopBackCopy;
                end
                else
                  BackCopyEnable := False;
        }
      end;

    BAB:
      begin
        InvertBoolean(BandMapAllBands); // := not BandMapAllBands;
        DisplayBandMap;
      end;

    BAM:
      begin
        InvertBoolean(BandMapAllModes); // := not BandMapAllModes;
        DisplayBandMap;
      end;
    {
        BMO:
          begin
            InvertBoolean(BandMapMultsOnly); // := not BandMapAllModes;
            DisplayBandMap;
          end;
    }
        { BMO: BEGIN                                                         }
        {      BandMapMultsOnly        := NOT BandMapMultsOnly; {KK1L: 6.xx}
        {      DisplayBandMap;                                               }
        {      END;                                                          }

    BCW: InvertBoolean(BandMapCallWindowEnable); // := not BandMapCallWindowEnable;

    BDD:
      begin
        InvertBoolean(BandMapDupeDisplay); // := not BandMapDupeDisplay;
        DisplayBandMap;
      end;

    BMD:
      begin
        TempInt := QuickEditInteger(TC_NEWBANDMAPDECAYTIMEMINUTES, 3);
        if TempInt <> -1 then
        begin
          BandMapDecayValue := TempInt; {KK1L: 6.65}
          BandMapDecayMultiplier := (BandMapDecayValue div 64) + 1; {KK1L: 6.65}
          BandMapDecayTime := BandMapDecayValue div BandMapDecayMultiplier; {KK1L: 6.65}
          SpotsList.ResetSpotsTimes;
            //ResetBandMapTimes; {KK1L: 6.70 Need to set BM times to new decay time}
            {ForcedEntry := True; {KK1L: 6.70 Switch to add comment since I wrote the entry automatically}
            {WriteParameterToLOGCFGFile (LogConfigFileName, ActiveLine); {KK1L: 6.70}
        end;
      end;

    BCQ: InvertBoolean(BandMapDisplayCQ); // := not BandMapDisplayCQ;

    BME:
      begin
        InvertBoolean(BandMapEnable); // := not BandMapEnable;
        {if BandMapEnable then }DisplayBandMap; // else RemoveWindow(BandMapWindow);
      end;

    BMG:
      begin
        TempInt := QuickEditInteger(TC_NEWBANDMAPGUARDBANDHERTZ, 6);
        if TempInt <> -1 then
          BandMapGuardBand := TempInt;
      end;

    {KK1L: 6.64}
    BSM: case BandMapSplitMode of
        ByCutoffFrequency: BandMapSplitMode := AlwaysPhone;
        AlwaysPhone: BandMapSplitMode := ByCutoffFrequency;
      end;

    BNA: InvertBoolean(BeepEnable); // := not BeepEnable;
    BET: InvertBoolean(BeepEvery10QSOs); // := not BeepEvery10QSOs;

    {      BRL:
             begin
                BigRemainingList := not BigRemainingList;
                CountryTable.MakeDefaultRemainingCountryList;
                ChangedRemainingMults := true;
             end;
    }
    BPD: InvertBoolean(Packet.BroadcastAllPacketData); // := not Packet.BroadcastAllPacketData;

    {KK1L: 6.65}
    SAS: InvertBoolean(CallWindowShowAllSpots); // := not CallWindowShowAllSpots;

    //    CAL: InvertBoolean(tr4w_CallsignAsLogin); // := not tr4w_CallsignAsLogin; //wli
    CAU: InvertBoolean(CallsignUpdateEnable); // := not CallsignUpdateEnable;
    CCA: InvertBoolean(tr4w_CustomCaret); // := not tr4w_CustomCaret; //wli

    CLF: InvertBoolean(CheckLogFileSize); // := not CheckLogFileSize;

    {      CDE:
             begin
                ColumnDupeSheetEnable := not ColumnDupeSheetEnable;

                //            if VisibleDupesheetEnable then
                begin
                   VisibleDupeSheetChanged := True;
                   VisibleLog.DisplayVisibleDupeSheet(ActiveBand, ActiveMode);
                end;
             end;
    }

    CAS: InvertBoolean(tConnectionAtStartup); // := not tr4w_ConnectionAtStartup;

    CCO:
      begin
        Windows.ZeroMemory(@ConnectionCommand, SizeOf(ConnectionCommand));
        ConnectionCommand := QuickEditResponse(TC_COMMANDWHICHWILLBESENDATTELNETCON, 80);
      end;

    CID:
      begin
        if NetSocket <> 0 then
        begin
          ShowMessage(TC_YOUCANONLYCHANGETHISWHENCLIENTDISC);
          Exit;
        end;
        TempString := QuickEditResponse(TC_COMPUTERIDAZRETURNNONE, 1);

        if length(TempString) > 0 then
        begin
          TempChar := TempString[1];
          if TempChar in ['A'..'Z'] then
            ComputerID := TempChar
          else
            ComputerID := CHR(0);
        end
        else
          ComputerID := CHR(0);

        tDispalyMyComputerID;
      end;

    CNA:
      begin
        TempString := QuickEditResponse(TC_COMPUTERNAME, 7);
        ComputerName := Copy(TempString, 1, 7);
        SetComputerName;
      end;

    CEC: ConfirmEditChanges := not ConfirmEditChanges;

    CIF: CountryInformationFile := QuickEditResponse(TC_NEWCOUNTRYINFORMATIONFILENAME, 30);

//    CKM: InvertBoolean(CPUKeyer.CurtisModeA); // := not CPUKeyer.CurtisModeA;
    CWE: InvertBoolean(CWEnable); // := not cwenable;
    CWS: InvertBoolean(CWSpeedFromDataBase); // := not CWSpeedFromDataBase;

    CSI:
      begin {KK1L: 6.72}
        TempInt := QuickEditInteger(TC_NEWCWINCREMENT, 3);
        if (TempInt > 0) and (TempInt < 11) then
          CodeSpeedIncrement := TempInt;
      end;

    CWT:
      begin
        TempInt := QuickEditInteger(TC_NEWCWMONITORTONE, 6);
        if TempInt <> -1 then
        begin
          CWTone := TempInt;
            //        AddStringToBuffer('', CWTone);
          MonitorTone := TempInt; //wli
        end;
      end;
    DEE: InvertBoolean(DEEnable); // := not DEEnable;
    DIG: InvertBoolean(DigitalModeEnable); // := not DigitalModeEnable;

    DIS: case DistanceMode of
        NoDistanceDisplay: DistanceMode := DistanceMiles;
        DistanceMiles: DistanceMode := DistanceKM;
        DistanceKM: DistanceMode := NoDistanceDisplay;
      end;

    DAR: InvertBoolean(Sheet.tAutoReset);

    DCS: case DupeCheckSound of
        DupeCheckNoSound: DupeCheckSound := DupeCheckBeepIfDupe;
        DupeCheckBeepIfDupe: DupeCheckSound := DupeCheckGratsIfMult;
        DupeCheckGratsIfMult: DupeCheckSound := DupeCheckNoSound;
      end;

    //      DSE: Sheet.DupeSheetEnable := not Sheet.DupeSheetEnable;

    DVE:
      begin
        if DVPSetUp then InvertBoolean(DVPEnable);
        {wli
        if  not  DVPActive DVPSetUp then
        begin
          DoABeep(ThreeHarmonics);
          QuickDisplay('SORRY!  DVPTSR was not loaded.');
          Wait(3000);
        end;

        DVPEnable := (not DVPEnable) and DVPActive;
        if DVPEnable then
          DVPInit
        else
               //          RemoveWindow(CodeSpeedWindow);
        }
      end;

    //      DVP: DVPPath := QuickEditResponse('Enter new DVP PATH = ', 40);

{      DVP:

       begin
          TempString := SelectFolder(JCTRFormHandle, 'text', 'Secect New DVP Path = ', DVPPath, True);
          if TempString <> '' then DVPPath := TempString;

       end;
}
    EES: InvertBoolean(EscapeExitsSearchAndPounce); // := not EscapeExitsSearchAndPounce;
    //    EEE: InvertBoolean(EthernetNetworkEnable);

    EME: InvertBoolean(ExchangeMemoryEnable); // := not ExchangeMemoryEnable;
    FWE: InvertBoolean(FarnsworthEnable); // := not FarnsworthEnable;

    FWS:
      begin
        TempInt := QuickEditInteger(TC_NEWFARNSWORTHSPEEDCUTINVALUE, 2);
        if TempInt <> -1 then
          FarnsworthSpeed := TempInt;
      end;

    FSF:
      begin
        TempInt := QuickEditInteger(TC_NEWFLOPPYFILESAVEFREQUENCY, 5);
        if TempInt <> -1 then
          FloppyFileSaveFrequency := TempInt;
      end;

    FSE:

      if OpenFileDlg(TC_SELECTNEWFLOPPYFILESAVENAME, settingswindowhandle, nil, TempString, OpenMMTTYFlags)
        then FloppyFileSaveName := TempString;

    FSM: case FootSwitchMode of
        FootSwitchDisabled: FootSwitchMode := Normal;
        Normal: FootSwitchMode := FootSwitchF1;
        FootSwitchF1: FootSwitchMode := FootSwitchLastCQFreq;
        FootSwitchLastCQFreq: FootSwitchMode := FootSwitchNextBandMap;
        FootSwitchNextBandMap: FootSwitchMode := FootSwitchNextDisplayedBandMap; {KK1L: 6.64}
        FootSwitchNextDisplayedBandMap: FootSwitchMode := FootSwitchNextMultBandMap; {KK1L: 6.68}
        FootSwitchNextMultBandMap: FootSwitchMode := FootSwitchNextMultDisplayedBandMap; {KK1L: 6.68}
        FootSwitchNextMultDisplayedBandMap: FootSwitchMode := FootSwitchUpdateBandMapBlinkingCall;
        FootSwitchUpdateBandMapBlinkingCall: FootSwitchMode := FootSwitchDupecheck;
        FootSwitchDupecheck: FootSwitchMode := QSONormal;
        QSONormal: FootSwitchMode := QSOQuick;
        QSOQuick: FootSwitchMode := FootSwitchControlEnter;
        FootSwitchControlEnter: FootSwitchMode := StartSending;
        StartSending: FootSwitchMode := SwapRadio;
        SwapRadio: FootSwitchMode := CWGrant;
        CWGrant: FootSwitchMode := FootSwitchDisabled;
      end;

    FPR:
      begin {KK1L: 6.71}
        TempLongInt := QuickEditInteger(TC_FREQPOLLRATEINMS, 4);
        if (TempLongInt >= 10) and (TempLongInt <= 1000) then FreqPollRate := TempLongInt; {KK1L: 6.72}
      end;

    FME: InvertBoolean(FrequencyMemoryEnable); // := not FrequencyMemoryEnable;

    FCR:
      begin
        InvertBoolean(Radio1.FT1000MPCWReverse); // := not Radio1.FT1000MPCWReverse;
        Radio2.FT1000MPCWReverse := Radio1.FT1000MPCWReverse;
      end;

    GMC:
      begin
        TempString := QuickEditResponse(TC_NEWCENTERFORGRIDMAP, 4);
        if GoodLookingGrid(TempString) or (TempString = '') then
          GridMapCenter := TempString;
      end;

    HFE: InvertBoolean(HFBandEnable); // := not HFBandEnable;

    HDP: case HourDisplay of
        ThisHour: HourDisplay := LastSixtyMins;
        LastSixtyMins: HourDisplay := ThisHour;
      end;
    {
        HOF:
          begin
            TempString := QuickEditResponse('new hour offset', 5);

            if TempString <> '' then
            begin
              Val(TempString, TempInt, Result1);
              if Result1 = 0 then HourOffset := TempInt;
            end;
          end;
    }
    ITE: InvertBoolean(IncrementTimeEnable); // := not IncrementTimeEnable;

    IFE:
      begin
        InvertBoolean(IntercomFileenable); // := not IntercomFileenable;

        {
        if IntercomFileenable then
          begin
            OpenFileForAppend(IntercomFileWrite, 'INTERCOM.TXT');
            IntercomFileOpen := True;
          end
        else
          if IntercomFileOpen then
            begin
              Close(IntercomFileWrite);
              IntercomFileOpen := False;
            end;
           }
      end;

    {    IEX:
          begin
            inc(ActiveInitialExchange);

            if ActiveInitialExchange > CustomInitialExchange then
              ActiveInitialExchange := NoInitialExchange;
          end;
    }
    IXO: InvertBoolean(InitialExchangeOverwrite); // := not InitialExchangeOverwrite; {KK1L: 6.70}

    IEC:
      if InitialExchangeCursorPos = AtEnd then
        InitialExchangeCursorPos := AtStart
      else
        InitialExchangeCursorPos := AtEnd;

    //    KNE: InvertBoolean(K1EANetworkEnable); // := not K1EANetworkEnable;
    {
        KSI:
          begin
            TempString := UpperCase(QuickEditResponse('station ID character', 1));

            if length(TempString) > 0 then
            begin
              TempChar := TempString[1];

              if (TempChar >= '0') and (TempChar <= 'Z') then
                K1EAStationID := TempChar
              else
                K1EAStationID := CHR(0);
            end
            else
              K1EAStationID := CHR(0);
          end;
    }
    KCM: KeypadCWMemories := not KeypadCWMemories;

    LDZ: case LeadingZeros of
        0: LeadingZeros := 1;
        1: LeadingZeros := 2;
        2: LeadingZeros := 3;
        3: LeadingZeros := 0;
      end;

    LZC: case LeadingZeroCharacter of
        'T': LeadingZeroCharacter := 'O';
        'O': LeadingZeroCharacter := '0';
        '0': LeadingZeroCharacter := 'T';
      end;

    LCI: InvertBoolean(LeaveCursorInCallWindow); // := not LeaveCursorInCallWindow;
    LFE: InvertBoolean(LogFrequencyEnable);

    LRS: LogRSSent := QuickEditInteger(TC_RSTOSHOWASSENTINLOG, 2);

    LDQ: InvertBoolean(LiteralDomesticQTH); // := not LiteralDomesticQTH;

    LRT: LogRSTSent := QuickEditInteger(TC_RSTTOSHOWASSENTINLOG, 3);

    LSE: InvertBoolean(LogWithSingleEnter); // := not LogWithSingleEnter;
    LFR: InvertBoolean(LookForRSTSent); // := not LookForRSTSent;
    MSE: InvertBoolean(MessageEnable); // := not MessageEnable;
    MCF: InvertBoolean(tMissCallsFileEnable);
    //      MEN: MouseEnable := not MouseEnable;

    MFD: MyFDClass := QuickEditResponse(TC_FIELDDAYCLASS, 6);

    MGR:
      begin
        TempString := QuickEditResponse(TC_NEWGRIDSQUARE, 4);
        if GoodLookingGrid(TempString) or (TempString = '') then
          MyGrid := tMakeGridFromString(TempString);
      end;

    MIO:
      begin
        TempString := QuickEditResponse(TC_NEWVALUEFORMYIOTA, 6);
        MyIOTA := TempString;
      end;

    MRM:
      begin
        inc(MultReportMinimumBands);
        if MultReportMinimumBands >= 6 then
          MultReportMinimumBands := 2;
      end;

    MIM:
      begin
        MultiInfoMessage := QuickEditResponse(TC_NEWMULTIINFOMESSAGE15CHARSMAX, 15);

        if OpMode = CQOpMode then
          CreateAndSendCQMultiInfoMessage
        else
          CreateAndSendSAPMultiInfoMessage;
      end;

    MMO: InvertBoolean(MultiMultsOnly); // := not MultiMultsOnly;
    {
        MMP:
          begin
            if not OpenFileDlg('', settingswindowhandle, 'MixW2.exe'#0'MixW2.exe;'#0#0, MMTTYPATH, OpenMMTTYFlags) then
              //          MMTTYPath := TempString;
              MMTTYPATH[0] := #0;
          end;
    }
    MRT:
      begin
        TempInt := QuickEditInteger('new multi retry timeout (minimum 3 seconds)', 6);
        if TempInt >= 3 then MultiRetryTime := TempInt;
      end;

    MUM: InvertBoolean(MultiUpdateMultDisplay); // := not MultiUpdateMultDisplay;
    //    MBA: MultipleBandsEnabled := not MultipleBandsEnabled;
    //    MMD: MultipleModesEnabled := not MultipleModesEnabled;
    NFE: InvertBoolean(NameFlagEnable); // := not NameFlagEnable;
    NLQ: InvertBoolean(NoLog); // := not NoLog;
    NPP: InvertBoolean(NoPollDuringPTT); // := not NoPollDuringPTT;
    PAL: InvertBoolean(PacketAddLF); // := not PacketAddLF;
    PAR: InvertBoolean(PacketAutoCR); // := not PacketAutoCR;

    PBS: InvertBoolean(Packet.PacketBandSpots); // := not Packet.PacketBandSpots;
    PBP: InvertBoolean(Packet.PacketBeep); // := not Packet.PacketBeep;

    PLF: Packet.PacketLogFileName := QuickEditResponse('packet log file name (none to disable)', 20);

    PRM:
      begin
        inc(PacketReturnPerMinute);
        if PacketReturnPerMinute > 10 then
          PacketReturnPerMinute := 0;
      end;

    psc:
      begin {KK1L: 6.71 Implimented what I started in 6.68}
        PacketSpotComment := QuickEditResponse(TC_ACOMMENTTOSENDWITHEACHSPOT, 15);
      end;

    PKD: InvertBoolean(PacketSpotDisable); // := not PacketSpotDisable;
    PSE: InvertBoolean(PacketSpotEditEnable); // := not PacketSpotEditEnable;
    SPO: InvertBoolean(PacketSpotPrefixOnly); // := not PacketSpotPrefixOnly; {KK1L: 6.72}

    PSP:
      if Packet.PacketSpots = AllSpots then
        Packet.PacketSpots := MultSpots
      else
        Packet.PacketSpots := AllSpots;

    PBE: PaddleBug := not PaddleBug;

    PHC:
      begin
        TempInt := QuickEditInteger(TC_NEWPTTHOLDCOUNT, 4);
        if TempInt <> -1 then PaddlePTTHoldCount := TempInt;
        PaddlePTTOffTimerCount := ElementLength * PaddlePTTHoldCount
      end;

    PMT:
      begin
        TempInt := QuickEditInteger(TC_NEWPADDLEMONITORTONE, 4);
        if TempInt <> -1 then PaddleMonitorTone := TempInt;
        NoSound;
      end;

    PSD:
      begin
        TempInt := QuickEditInteger(TC_NEWPADDLESPEED0TODISABLE, 4);

        if TempInt <> -1 then
        begin
          PaddleSpeed := TempInt;
          CPUKeyer.SetSpeed(PaddleSpeed);
          tSetPaddleElementLength;
        end;
      end;

    PCE: InvertBoolean(PartialCallEnable); // := not PartialCallEnable;
    //      PCL: InvertBoolean(PartialCallLoadLogEnable); // := not PartialCallLoadLogEnable;
    PCM: InvertBoolean(PartialCallMultsEnable); // := not PartialCallMultsEnable;
    PCA: InvertBoolean(PossibleCallEnable); // := not PossibleCallEnable;

    PCN: case CD.PossibleCallAction of {KK1L: 6.69 support log only check partial}
        AnyCall: CD.PossibleCallAction := OnlyCallsWithNames;
        OnlyCallsWithNames: CD.PossibleCallAction := LogOnly;
        LogOnly: CD.PossibleCallAction := AnyCall;
      end;

    //W_L_I    PEN: PrinterEnabled := not PrinterEnabled;

    PBL: InvertBoolean(PTTLockout);
    PTT: InvertBoolean(PTTEnable); // := not PTTEnable;

    PTD:
      begin
        TempInt := QuickEditInteger(TC_PTTDELAYCOUNT, 4);
        if TempInt <> -1 then PTTTurnOnDelay := TempInt;
      end;

    PVC: InvertBoolean(tPTTViaCommand);

    QMD: case ParameterOkayMode of
        Standard: ParameterOkayMode := QSLButDoNotLog;
        QSLButDoNotLog: ParameterOkayMode := QSLAndLog;
        QSLAndLog: ParameterOkayMode := Standard;
      end;

    QNB: InvertBoolean(QSONumberByBand); // := not QSONumberByBand;
    QSX: InvertBoolean(QSXEnable); // := not QSXEnable;

    QES: InvertBoolean(QTCExtraSpace); // := not QTCExtraSpace;
    QRS: InvertBoolean(QTCQRS); // := not QTCQRS;

    QMC:
      begin
        TempString := QuickEditResponse(TC_KEYBOARDCHARACTERTOUSEFORQUESTION, 1);

        if length(TempString) > 0 then
          QuestionMarkChar := TempString[1];
      end;
    {
        R1CP:
          begin
            TempString := QuickEditResponse('radio 1 command delay (ms or none to abort)', 5);

            if TempString <> '' then
              begin
                Val(TempString, TempInt, Result1);

                if Result1 = 0 then
                  Radio1.CommandPause := TempInt;
              end;
          end;
    }
    R1FA:
      begin
        TempLongInt := QuickEditInteger(TC_RADIO1FREQUENCYADDER, 11);

        if TempLongInt <> -1 then
          Radio1.FrequencyAdder := TempLongInt;
      end;
{
    R1ID:
      begin
        TempString := QuickEditResponse('rig 1 ID character (A-Z or RETURN for none)', 1);

        if length(TempString) > 0 then
        begin
          TempChar := TempString[1];

          if (TempChar >= 'A') and (TempChar <= 'Z') then
            Radio1.IDCharacter := TempChar
          else
            Radio1.IDCharacter := CHR(0);
        end
        else
          Radio1.IDCharacter := CHR(0);
      end;
}
    {
        R1PT:
          begin
            TempString := QuickEditResponse('new Radio One timeout (ms - none to abort)', 5);

            if TempString <> '' then
              begin
                Val(TempString, TempInt, Result1);

                if Result1 = 0 then
                  Radio1.PollTimeout := TempInt;
              end;
          end;
    }
    //    R1TE: InvertBoolean(Radio1.TrackingEnable); // := not Radio1.TrackingEnable;
    {
        R1US:
          begin
            TempInt := QuickEditInteger('new value for RADIO ONE UPDATE SECONDS', 3);
            if TempInt <> -1 then Radio1.UpdateSeconds := TempInt;
          end;
    }
    {
        R2CP:
          begin
            TempString := QuickEditResponse('radio 2 command delay (ms or none to abort)', 5);

            if TempString <> '' then
              begin
                Val(TempString, TempInt, Result1);

                if Result1 = 0 then
                  Radio2.CommandPause := TempInt;
              end;
          end;
    }
    R2FA:
      begin
        TempLongInt := QuickEditInteger(TC_RADIO2FREQUENCYADDER, 11);

        if TempLongInt <> -1 then
          Radio2.FrequencyAdder := TempLongInt;
      end;
{
    R2ID:
      begin
        TempString := QuickEditResponse('rig 2 ID character (A-Z or RETURN for none)', 1);

        if length(TempString) > 0 then
        begin
          TempChar := TempString[1];

          if (TempChar >= 'A') and (TempChar <= 'Z') then
            Radio2.IDCharacter := TempChar
          else
            Radio2.IDCharacter := CHR(0);
        end
        else
          Radio2.IDCharacter := CHR(0);
      end;
}
    {
        R2PT:
          begin
            TempString := QuickEditResponse('new Radio Two timeout (ms - none to abort)', 5);

            if TempString <> '' then
              begin
                Val(TempString, TempInt, Result1);

                if Result1 = 0 then
                  Radio2.PollTimeout := TempInt;
              end;
          end;
    }
    //    R2TE: InvertBoolean(Radio2.TrackingEnable); // := not Radio2.TrackingEnable;
    {
        R2US:
          begin
            TempInt := QuickEditInteger('new value for RADIO TWO UPDATE SECONDS', 3);
            if TempInt <> -1 then Radio2.UpdateSeconds := TempInt;
          end;
    }
    RCQ: InvertBoolean(RandomCQMode); // := not RandomCQMode;

    RDS:
      begin
        case RateDisplay of
          QSOs: RateDisplay := Points;
          Points: RateDisplay := BandQSOs;
          BandQSOs: RateDisplay := QSOs;
        end;
      end;

    RMD:
      begin
        case RemainingMultDisplayMode of
          NoRemainingMults: RemainingMultDisplayMode := Erase;
          Erase: RemainingMultDisplayMode := HiLight;
          HiLight: RemainingMultDisplayMode := NoRemainingMults;
        end;
        VisibleLog.ShowRemainingMultipliers;
      end;

    SHE: InvertBoolean(SayHiEnable); // := not SayHiEnable;

    SHC:
      begin
        TempInt := QuickEditInteger(TC_NEWSAYHIRATECUTOFF, 5);
        if TempInt <> -1 then SayHiRateCutOff := TempInt;
      end;

    SCS:
      begin
        CD.CountryString := QuickEditResponse(TC_NEWSCPCOUNTRYSTRING, 40);

        if CD.CountryString <> '' then
          if Copy(CD.CountryString, length(CD.CountryString), 1) <> ',' then
            CD.CountryString := CD.CountryString + ',';
      end;

    SML:
      if not WRTC2002 then {KK1L: 6.68 Keep WRTC folks from using SCP}
        case SCPMinimumLetters of
          0: SCPMinimumLetters := 3;
          3: SCPMinimumLetters := 4;
          4: SCPMinimumLetters := 5;
        else SCPMinimumLetters := 0;
        end
      else SCPMinimumLetters := 0;

    SAD: InvertBoolean(SendAltDSpotsToPacket); // := not SendAltDSpotsToPacket;

    SCF: InvertBoolean(SendCompleteFourLetterCall); // := not SendCompleteFourLetterCall;

    SSN:
      begin
        TempString := QuickEditResponse(TC_KEYBOARDCHARACTERTOSTARTSENDING, 1);
        if TempString <> '' then
          StartSendingNowKey := TempString[1];
      end;

    SPS: InvertBoolean(StereoPinState); // := not StereoPinState; {KK1L: 6.71}

    SQI: InvertBoolean(SendQSOImmediately); // := not SendQSOImmediately;

    SIA:
      begin
        {
        if WindowsOSversion = VER_PLATFORM_WIN32_NT then
          TempString := ShowServerDialog(settingswindowhandle)
        else
        }
        TempString := QuickEditResponse(TC_NETWORKSERVERADDRESS, 40);
        //        if length(TempString) > 1 then if (TempString[1] = '\') and (TempString[2] = '\') then TempString := Copy(TempString, 3, 255);
        if TempString <> '' then
        begin
          Windows.ZeroMemory(@ServerAddress, SizeOf(ServerAddress));
          ServerAddress := TempString;
        end;
      end;

    SPA:
      begin
        TempString := QuickEditResponse(TC_NEWSERVERPASSWORD10CHARS, 10);
        if (length(TempString) = 10) then
          if pos(' ', TempString) = 0 then
            ServerPassword := TempString;
      end;

    SEP:
      begin
        TempInt := QuickEditInteger(TC_NETWORKSERVERPORT, 5);
        if TempInt <> -1 then ServerPort := TempInt;
      end;

    SKE: InvertBoolean(ShiftKeyEnable); // := not ShiftKeyEnable;
    SIN: InvertBoolean(ShortIntegers); // := not ShortIntegers;
    //    SSP: InvertBoolean(ShowSearchAndPounce); // := not ShowSearchAndPounce;
    SLG:
      begin
        InvertBoolean(tLogLogGridlines);
        DispalayLogGridLines;
      end;

    {    SEN:
          if DDXState = Off then
            DDXState := StandBy
          else
            DDXState := Off;
    }
    SRM: InvertBoolean(SingleRadioMode); // := not SingleRadioMode;
    SAB: InvertBoolean(SkipActiveBand); // := not SkipActiveBand;

    SMC:
      begin
        TempString := QuickEditResponse(TC_KEYBOARDCHARACTERTOUSEFORSLASH, 1);

        if length(TempString) > 0 then
          SlashMarkChar := TempString[1];
      end;

    SBD: InvertBoolean(SpaceBarDupeCheckEnable); // := not SpaceBarDupeCheckEnable;

    SQR: InvertBoolean(SprintQSYRule); // := not SprintQSYRule;
    SRP: InvertBoolean(SwapPacketSpotRadios); // := not SwapPacketSpotRadios;
    SWP: InvertBoolean(SwapPaddles); // := not SwapPaddles;
    SWR: InvertBoolean(SwapRadioRelaySense); // := not SwapRadioRelaySense;
    {
        TAB: case TabMode of
            NormalTabMode: TabMode := ControlFTabMode;
            ControlFTabMode: TabMode := NormalTabMode;
          end;
    }
    TMR: case TenMinuteRule of
        NoTenMinuteRule: TenMinuteRule := TimeOfFirstQSO;
        TimeOfFirstQSO: TenMinuteRule := NoTenMinuteRule;
      end;

    TOT:
      begin
        TempString := QuickEditResponse(TC_NEWOFFTIMEVALUEMINUTES, 6);

        if StringHas(TempString, ':') then
        begin
          Val(PrecedingString(TempString, ':'), TempHour, Result1);
          if Result1 = 0 then
          begin
            Val(PostcedingString(TempString, ':'), TempMinute, Result1);
            if Result1 = 0 then
              TotalOffTime := TempHour * 60 + TempMinute;
          end;
        end
        else
        begin
          Val(TempString, TempMinute, Result1);
          if Result1 = 0 then TotalOffTime := TempMinute {TempInt};
        end;
      end;

    TDE:
      begin
        InvertBoolean(TuneDupeCheckEnable); // := not TuneDupeCheckEnable; {KK1L: 6.73}
        TwoRadioState := Idle;
      end;

    TWD: InvertBoolean(TuneWithDits); // := not TuneWithDits;

    TRM:
      InvertBoolean(TwoRadioMode);
{
      if TwoRadioState = TwoRadiosDisabled then
        TwoRadioState := Idle
      else
        TwoRadioState := TwoRadiosDisabled;
}
    URF: InvertBoolean(UpdateRestartFileEnable); // := not UpdateRestartFileEnable;

    //      UBC: UseBIOSKeyCalls := not UseBIOSKeyCalls;

    UIS:
      begin
        //            inc(UserInfoShown);
        //            if UserInfoShown > CustomInfo then UserInfoShown := NoUserInfo;

        if UserInfoShown <> CustomInfo then
          inc(UserInfoShown)
        else
          UserInfoShown := NoUserInfo;

      end;
    URS: InvertBoolean(tUseRecordedSigns);

    //      VDE: VGADisplayEnable := not VGADisplayEnable;
    VBE:
      begin
        InvertBoolean(VHFBandsEnabled); // := not VHFBandsEnabled;
        DisplayBandMap;
      end;

    //      VDS: VisibleDupesheetEnable := not VisibleDupesheetEnable;

    WFS: InvertBoolean(WaitForStrength); // := not WaitForStrength;

    WUT:
      begin
        TempInt := QuickEditInteger(TC_NEWVALUEFORWAKEUPTIMEOUT, 5);
        if TempInt <> -1 then
          WakeUpTimeOut := TempInt;
      end;

    WBE:
      begin
        InvertBoolean(WARCBandsEnabled); // := not WARCBandsEnabled;
        DisplayBandMap;
      end;

    WEI:
      begin
        TempReal := QuickEditReal(TC_NEWWEIGHTVALUE, 7);
        //W_L_I        Write(TempReal, ' ');
        if TempReal >= 0.5 then
          if TempReal <= 1.5 then
            Weight := TempReal;
      end;

    WCP: InvertBoolean(WildCardPartials); // := not WildCardPartials;

  end;

end;

procedure WriteParameterToLOGCFGFile(FileName: Str80; Line: MenuEntryType);

var
//  TempString                            : Str80;
  FileWrite                             : Text;

begin
  OpenFileForAppend(FileWrite, FileName);

  if ForcedEntry then {KK1L: 6.70} {KK1L: 6.70 turned this off. Chose to save value in BANDMAP.BIN}
  begin
    case Line of
      BMD: WriteLn(FileWrite, ';**Added automatically to keep band map decay consistent');
    end;
    ForcedEntry := False; {KK1L: 6.70 Done using the switch}
  end;

  Write(FileWrite, Description(Line), ' = ');

  case Line of

    ACC: WriteLn(FileWrite, AllCWMessagesChainable);
    ABE: WriteLn(FileWrite, AltDBufferEnable);
    ABC: WriteLn(FileWrite, AlwaysCallBlindCQ);
    AFF: WriteLn(FileWrite, AskForFrequencies);
    //    AIO: WriteLn(FileWrite, AskIfContestOver);
    ACT: WriteLn(FileWrite, AutoCallTerminate);
    AAD: WriteLn(FileWrite, K5KA.ModeEnabled);
    ADP: WriteLn(FileWrite, AutoDisplayDupeQSO);
    ADE: WriteLn(FileWrite, AutoDupeEnableCQ);
    ADS: WriteLn(FileWrite, AutoDupeEnableSandP);
    AQI: WriteLn(FileWrite, AutoQSLInterval);
    AQD: WriteLn(FileWrite, AutoQSONumberDecrement);
    ASP: WriteLn(FileWrite, AutoSAPEnable);
    ASR: WriteLn(FileWrite, AutoSAPEnableRate); {KK1L: 6.72}
    Arc: WriteLn(FileWrite, AutoReturnToCQMode);
    asc: WriteLn(FileWrite, AutoSendCharacterCount);
    ATI: WriteLn(FileWrite, AutoTimeIncrementQSOs);

    BEN: WriteLn(FileWrite, BackCopyEnable);
    BAB: WriteLn(FileWrite, BandMapAllBands);
    BAM: WriteLn(FileWrite, BandMapAllModes);
    {BMO: WriteLn (FileWrite, BandMapMultsOnly); {KK1L: 6.xx}
    BCW: WriteLn(FileWrite, BandMapCallWindowEnable);
    BDD: WriteLn(FileWrite, BandMapDupeDisplay);
    BMD: WriteLn(FileWrite, BandMapDecayValue);
    BCQ: WriteLn(FileWrite, BandMapDisplayCQ);
    BME: WriteLn(FileWrite, BandMapEnable);
    BMG: WriteLn(FileWrite, BandMapGuardBand);

    {KK1L: 6.64}
    BSM: case BandMapSplitMode of
        ByCutoffFrequency: WriteLn(FileWrite, 'BY CUTOFF FREQ');
        AlwaysPhone: WriteLn(FileWrite, 'ALWAYS PHONE');
      end;

    BNA: WriteLn(FileWrite, BeepEnable);
    BET: WriteLn(FileWrite, BeepEvery10QSOs);
    //      BRL: WriteLn(FileWrite, BigRemainingList);
    BPD: WriteLn(FileWrite, Packet.BroadcastAllPacketData);
    CAU: WriteLn(FileWrite, CallsignUpdateEnable);
    CLF: WriteLn(FileWrite, CheckLogFileSize);
    //      CDE: WriteLn(FileWrite, ColumnDupeSheetEnable);
    CID: WriteLn(FileWrite, ComputerID);
    //      CEC: WriteLn(FileWrite, ConfirmEditChanges);
    CIF: WriteLn(FileWrite, CountryInformationFile);

{    CKM:
      if CPUKeyer.CurtisModeA then
        WriteLn(FileWrite, 'A')
      else
        WriteLn(FileWrite, 'B');
}
    CWE: WriteLn(FileWrite, CWEnable);
    CWS: WriteLn(FileWrite, CWSpeedFromDataBase);
    CSI: WriteLn(FileWrite, CodeSpeedIncrement); {KK1L: 6.72}
    CWT: WriteLn(FileWrite, CWTone);

    DEE: WriteLn(FileWrite, DEEnable);

    DIG: WriteLn(FileWrite, DigitalModeEnable);

    DIS: case DistanceMode of
        NoDistanceDisplay: WriteLn(FileWrite, 'NONE');
        DistanceMiles: WriteLn(FileWrite, 'MILES');
        DistanceKM: WriteLn(FileWrite, 'KM');
      end;

    DCS: case DupeCheckSound of
        DupeCheckNoSound: WriteLn(FileWrite, 'NONE');
        DupeCheckBeepIfDupe: WriteLn(FileWrite, 'DUPE BEEP');
        DupeCheckGratsIfMult: WriteLn(FileWrite, 'MULT FANFARE');
      end;

    //      DSE: WriteLn(FileWrite, Sheet.DupeSheetEnable);

    DVE: WriteLn(FileWrite, DVPEnable);
    //      DVP: WriteLn(FileWrite, DVPPath);

    EES: WriteLn(FileWrite, EscapeExitsSearchAndPounce);
    EME: WriteLn(FileWrite, ExchangeMemoryEnable);
    FWE: WriteLn(FileWrite, FarnsworthEnable);
    FWS: WriteLn(FileWrite, FarnsworthSpeed);
    FSF: WriteLn(FileWrite, FloppyFileSaveFrequency);
    FSE: WriteLn(FileWrite, FloppyFileSaveName);

    FSM: case FootSwitchMode of
        FootSwitchDisabled: WriteLn(FileWrite, 'DISABLED');
        FootSwitchF1: WriteLn(FileWrite, 'F1');
        FootSwitchLastCQFreq: WriteLn(FileWrite, 'LAST CQ FREQ');
        FootSwitchNextBandMap: WriteLn(FileWrite, 'NEXT BANDMAP');
        FootSwitchNextDisplayedBandMap: WriteLn(FileWrite, 'NEXT DISP BANDMAP'); {KK1L: 6.64}
        FootSwitchNextMultBandMap: WriteLn(FileWrite, 'NEXT MULT BANDMAP'); {KK1L: 6.68}
        FootSwitchNextMultDisplayedBandMap: WriteLn(FileWrite, 'NEXT MULT DISP BANDMAP'); {KK1L: 6.68}
        FootSwitchUpdateBandMapBlinkingCall: WriteLn(FileWrite, 'UPDATE BLINKING CALL');
        FootSwitchDupecheck: WriteLn(FileWrite, 'DUPE CHECK');
        Normal: WriteLn(FileWrite, 'NORMAL');
        QSONormal: WriteLn(FileWrite, 'QSO NORMAL');
        QSOQuick: WriteLn(FileWrite, 'QSO QUICK');
        FootSwitchControlEnter: WriteLn(FileWrite, 'CONTROL ENTER');
        StartSending: WriteLn(FileWrite, 'START SENDING');
        SwapRadio: WriteLn(FileWrite, 'SWAP RADIOS');
        CWGrant: WriteLn(FileWrite, 'CW GRANT');
      end;

    FPR: WriteLn(FileWrite, FreqPollRate); {KK1L: 6.71}
    FME: WriteLn(FileWrite, FrequencyMemoryEnable);
    FCR: WriteLn(FileWrite, Radio1.FT1000MPCWReverse);
    GMC: WriteLn(FileWrite, GridMapCenter);
    HFE: WriteLn(FileWrite, HFBandEnable);

    HDP: case HourDisplay of
        ThisHour: WriteLn(FileWrite, 'THIS HOUR');
        LastSixtyMins: WriteLn(FileWrite, 'LAST SIXTY MINUTES');
      end;

    //    HOF: WriteLn(FileWrite, HourOffset);

    ITE: WriteLn(FileWrite, IncrementTimeEnable);
    IFE: WriteLn(FileWrite, IntercomFileenable);
    {
        IEX: case ActiveInitialExchange of
            NoInitialExchange: WriteLn(FileWrite, 'NONE');
            NameInitialExchange: WriteLn(FileWrite, 'NAME');
            NameQTHInitialExchange: WriteLn(FileWrite, 'NAME QTH');
            CheckSectionInitialExchange: WriteLn(FileWrite, 'CHECK SECTION');
            SectionInitialExchange: WriteLn(FileWrite, 'SECTION');
            QTHInitialExchange: WriteLn(FileWrite, 'QTH');
            FOCInitialExchange: WriteLn(FileWrite, 'FOC NUMBER');
            GridInitialExchange: WriteLn(FileWrite, 'GRID');
            ZoneInitialExchange: WriteLn(FileWrite, 'ZONE');
            User1InitialExchange: WriteLn(FileWrite, 'USER 1');
            User2InitialExchange: WriteLn(FileWrite, 'USER 2');
            User3InitialExchange: WriteLn(FileWrite, 'USER 3');
            User4InitialExchange: WriteLn(FileWrite, 'USER 4');
            User5InitialExchange: WriteLn(FileWrite, 'USER 5');
            CustomInitialExchange: WriteLn(FileWrite, 'CUSTOM');
          end;
    }
    IXO: WriteLn(FileWrite, InitialExchangeOverwrite); {KK1L: 6.70}

    IEC:
      if InitialExchangeCursorPos = AtStart then
        WriteLn(FileWrite, 'AT START')
      else
        WriteLn(FileWrite, 'AT END');

    //    KNE: WriteLn(FileWrite, K1EANetworkEnable);
    //    KSI: WriteLn(FileWrite, K1EAStationID);
    KCM: WriteLn(FileWrite, KeypadCWMemories);

    LDZ: WriteLn(FileWrite, LeadingZeros);
    LZC: WriteLn(FileWrite, LeadingZeroCharacter);
    LCI: WriteLn(FileWrite, LeaveCursorInCallWindow);
    LFE: WriteLn(FileWrite, LogFrequencyEnable);
    LRS: WriteLn(FileWrite, LogRSSent);
    LDQ: WriteLn(FileWrite, LiteralDomesticQTH);
    LRT: WriteLn(FileWrite, LogRSTSent);
    LSE: WriteLn(FileWrite, LogWithSingleEnter);
    LFR: WriteLn(FileWrite, LookForRSTSent);

    MSE: WriteLn(FileWrite, MessageEnable);
    //      MEN: WriteLn(FileWrite, MouseEnable);
    MFD: WriteLn(FileWrite, MyFDClass);
    MGR: WriteLn(FileWrite, MyGrid);
    MIO: WriteLn(FileWrite, MyIOTA);
    MRM: WriteLn(FileWrite, MultReportMinimumBands);
    MIM: WriteLn(FileWrite, MultiInfoMessage);

    MMO: WriteLn(FileWrite, MultiMultsOnly);
    MRT: WriteLn(FileWrite, MultiRetryTime);
    MUM: WriteLn(FileWrite, MultiUpdateMultDisplay);
    //    MBA: WriteLn(FileWrite, MultipleBandsEnabled);
    //    MMD: WriteLn(FileWrite, MultipleModesEnabled);

    NFE: WriteLn(FileWrite, NameFlagEnable);
    NLQ: WriteLn(FileWrite, NoLog);
    NPP: WriteLn(FileWrite, NoPollDuringPTT);
    PAL: WriteLn(FileWrite, PacketAddLF);
    PAR: WriteLn(FileWrite, PacketAutoCR);
    PBS: WriteLn(FileWrite, Packet.PacketBandSpots);
    PBP: WriteLn(FileWrite, Packet.PacketBeep);
    PLF: WriteLn(FileWrite, Packet.PacketLogFileName);

    PRM: WriteLn(FileWrite, PacketReturnPerMinute);
    psc: WriteLn(FileWrite, PacketSpotComment); {KK1L: 6.71 Implimented what I started in 6.68}
    PKD: WriteLn(FileWrite, PacketSpotDisable);
    PSE: WriteLn(FileWrite, PacketSpotEditEnable);
    SPO: WriteLn(FileWrite, PacketSpotPrefixOnly); {KK1L: 6.72}

    PSP:
      if Packet.PacketSpots = AllSpots then
        WriteLn(FileWrite, 'ALL')
      else
        WriteLn(FileWrite, 'MULT');

    PBE: WriteLn(FileWrite, PaddleBug);

    PHC: WriteLn(FileWrite, PaddlePTTHoldCount);
    PMT: WriteLn(FileWrite, PaddleMonitorTone);
    PSD: WriteLn(FileWrite, PaddleSpeed);
    PCE: WriteLn(FileWrite, PartialCallEnable);
    //      PCL: WriteLn(FileWrite, PartialCallLoadLogEnable);
    PCM: WriteLn(FileWrite, PartialCallMultsEnable);
    PCA: WriteLn(FileWrite, PossibleCallEnable);

    PCN: case CD.PossibleCallAction of {KK1L: 6.69 support log only check partial}
        AnyCall: WriteLn(FileWrite, 'ALL');
        OnlyCallsWithNames: WriteLn(FileWrite, 'NAMES');
        LogOnly: WriteLn(FileWrite, 'LOG ONLY');
      end;

    //W_L_I    PEN: WriteLn(FileWrite, PrinterEnabled);
    PTT: WriteLn(FileWrite, PTTEnable);
    PTD: WriteLn(FileWrite, PTTTurnOnDelay);

    QMD: case ParameterOkayMode of
        Standard: WriteLn(FileWrite, 'STANDARD');
        QSLButDoNotLog: WriteLn(FileWrite, 'QSL BUT DO NOT LOG');
        QSLAndLog: WriteLn(FileWrite, 'QSL AND LOG');
      end;

    QNB: WriteLn(FileWrite, QSONumberByBand);
    QSX: WriteLn(FileWrite, QSXEnable);
    QES: WriteLn(FileWrite, QTCExtraSpace);
    QRS: WriteLn(FileWrite, QTCQRS);
    QMC: WriteLn(FileWrite, QuestionMarkChar);

    //    R1CP: WriteLn(FileWrite, Radio1.CommandPause);
    R1FA: WriteLn(FileWrite, Radio1.FrequencyAdder);
//    R1ID: WriteLn(FileWrite, Radio1.IDCharacter);
    //    R1PT: WriteLn(FileWrite, Radio1.PollTimeout);
    //    R1TE: WriteLn(FileWrite, Radio1.TrackingEnable);
    //    R1US: WriteLn(FileWrite, Radio1.UpdateSeconds);

    //    R2CP: WriteLn(FileWrite, Radio2.CommandPause);
    R2FA: WriteLn(FileWrite, Radio2.FrequencyAdder);
//    R2ID: WriteLn(FileWrite, Radio2.IDCharacter);
    //{WLI-dup}      R1PT: WriteLn (FileWrite, Radio2.PollTimeout);
//    R2TE: WriteLn(FileWrite, Radio2.TrackingEnable);
//    R2US: WriteLn(FileWrite, Radio2.UpdateSeconds);

    RCQ: WriteLn(FileWrite, RandomCQMode);

    RDS: case RateDisplay of
        QSOs: WriteLn(FileWrite, 'QSOs');
        Points: WriteLn(FileWrite, 'QSO Points');
        BandQSOs: WriteLn(FileWrite, 'Band QSOs');
      end;

    RMD: case RemainingMultDisplayMode of
        NoRemainingMults: WriteLn(FileWrite, 'None');
        Erase: WriteLn(FileWrite, 'Erase');
        HiLight: WriteLn(FileWrite, 'HiLight');
      end;

    SHE: WriteLn(FileWrite, SayHiEnable);
    SHC: WriteLn(FileWrite, SayHiRateCutOff);
    SCS: WriteLn(FileWrite, CD.CountryString);
    SML: WriteLn(FileWrite, SCPMinimumLetters);
    SAD: WriteLn(FileWrite, SendAltDSpotsToPacket);
    SCF: WriteLn(FileWrite, SendCompleteFourLetterCall);
    SPS: WriteLn(FileWrite, StereoPinState); {KK1L: 6.71}
    SQI: WriteLn(FileWrite, SendQSOImmediately);
    SKE: WriteLn(FileWrite, ShiftKeyEnable);
    SIN: WriteLn(FileWrite, ShortIntegers);
    //    SSP: WriteLn(FileWrite, ShowSearchAndPounce);

    {    SEN:
          if DDXState = Off then
            WriteLn(FileWrite, 'FALSE')
          else
            WriteLn(FileWrite, 'TRUE');
    }
    SRM: WriteLn(FileWrite, SingleRadioMode);
    SAB: WriteLn(FileWrite, SkipActiveBand);
    {KK1L: 6.65}
    SAS: WriteLn(FileWrite, CallWindowShowAllSpots);
    SMC: WriteLn(FileWrite, SlashMarkChar);
    SBD: WriteLn(FileWrite, SpaceBarDupeCheckEnable);
    SQR: WriteLn(FileWrite, SprintQSYRule);
    SRP: WriteLn(FileWrite, SwapPacketSpotRadios);
    SWP: WriteLn(FileWrite, SwapPaddles);
    SWR: WriteLn(FileWrite, SwapRadioRelaySense);
    {
        TAB: case TabMode of
            NormalTabMode: WriteLn(FileWrite, 'NORMAL');
            ControlFTabMode: WriteLn(FileWrite, 'CONTROLF');
          end;
    }
    TMR: case TenMinuteRule of
        NoTenMinuteRule: WriteLn(FileWrite, 'NONE');
        TimeOfFirstQSO: WriteLn(FileWrite, 'TIME OF FIRST QSO');
      end;

    TDE: WriteLn(FileWrite, TuneDupeCheckEnable); {KK1L: 6.73}

    TWD: WriteLn(FileWrite, TuneWithDits);

    TRM:
      if TwoRadioState <> TwoRadiosDisabled then
        WriteLn(FileWrite, 'TRUE')
      else
        WriteLn(FileWrite, 'FALSE');

    URF: WriteLn(FileWrite, UpdateRestartFileEnable);
    //      UBC: WriteLn(FileWrite, UseBIOSKeyCalls);

    UIS: case UserInfoShown of
        NoUserInfo: WriteLn(FileWrite, 'NONE');
        NameInfo: WriteLn(FileWrite, 'NAME');
        QTHInfo: WriteLn(FileWrite, 'QTH');
        CheckSectionInfo: WriteLn(FileWrite, 'CHECK SECTION');
        SectionInfo: WriteLn(FileWrite, 'SECTION');
        OldCallInfo: WriteLn(FileWrite, 'OLD CALL');
        FocInfo: WriteLn(FileWrite, 'FOC NUMBER');
        GridInfo: WriteLn(FileWrite, 'GRID');
        ITUZoneInfo: WriteLn(FileWrite, 'ITU ZONE');
        CQZoneInfo: WriteLn(FileWrite, 'CQ ZONE');
        User1Info: WriteLn(FileWrite, 'USER 1');
        User2Info: WriteLn(FileWrite, 'USER 2');
        User3Info: WriteLn(FileWrite, 'USER 3');
        User4Info: WriteLn(FileWrite, 'USER 4');
        User5Info: WriteLn(FileWrite, 'USER 5');
        CustomInfo: WriteLn(FileWrite, 'CUSTOM');
      end;

    //      VDE: WriteLn(FileWrite, VGADisplayEnable);
    VBE: WriteLn(FileWrite, VHFBandsEnabled);
    //      VDS: WriteLn(FileWrite, VisibleDupesheetEnable);
    WFS: WriteLn(FileWrite, WaitForStrength);
    WUT: WriteLn(FileWrite, WakeUpTimeOut);
    WBE: WriteLn(FileWrite, WARCBandsEnabled);
    WEI: WriteLn(FileWrite, Weight: 3: 2);
    WCP: WriteLn(FileWrite, WildCardPartials);
  end;

  Close(FileWrite);
end;

procedure ParameterToString(Line: MenuEntryType; var Value: ShortString);

{ Returns string with value for indictated line parameter }
label
  NoTrue;
var
  TempString                            : ShortString;
  TempStringIsTrue                      : boolean;
begin
  Windows.ZeroMemory(@Value, SizeOf(Value));
  TempStringIsTrue := False;

  TempString := 'FALSE';

  asm xor ebx,ebx
  end; //=TempStringIsTrue := True;

  case Line of
    ACC: TempStringIsTrue := AllCWMessagesChainable;
    AAU: TempStringIsTrue := tAllowAutoUpdate;

    ABE: TempStringIsTrue := AltDBufferEnable;
    ABC: TempStringIsTrue := AlwaysCallBlindCQ;
    AFF: TempStringIsTrue := AskForFrequencies;
    //    AIO: TempStringIsTrue := AskIfContestOver;
    ACT: TempStringIsTrue := AutoCallTerminate;
    AAD: TempStringIsTrue := K5KA.ModeEnabled;
    ADP: TempStringIsTrue := AutoDisplayDupeQSO;
    ADE: TempStringIsTrue := AutoDupeEnableCQ;
    ADS: TempStringIsTrue := AutoDupeEnableSandP;
    AQI: Str(AutoQSLInterval, TempString);
    AQD: TempStringIsTrue := AutoQSONumberDecrement;
    Arc: TempStringIsTrue := AutoReturnToCQMode;
    ASP: TempStringIsTrue := AutoSAPEnable;
    ASR: Str(AutoSAPEnableRate, TempString); {KK1L: 6.72}
    //    ASR: TempString := inttopchar(AutoSAPEnableRate);

    asc: Str(AutoSendCharacterCount, TempString);//TempString := inttopchar(AutoSendCharacterCount);
    ATI: Str(AutoTimeIncrementQSOs, TempString);
    //    ATI: TempString := inttopchar(AutoTimeIncrementQSOs);

    BEN: TempStringIsTrue := BackCopyEnable;
    BAB: TempStringIsTrue := BandMapAllBands;
    BAM: TempStringIsTrue := BandMapAllModes;
    //    BMO: TempStringIsTrue := BandMapMultsOnly;
        {BMO: IF BandMapMultsOnly then asm inc ebx end;//TempStringIsTrue := True; //TempString := 'TRUE'; {KK1L: 6.xx}
    BCW: TempStringIsTrue := BandMapCallWindowEnable;
    BDD: TempStringIsTrue := BandMapDupeDisplay;
    BMD: Str(BandMapDecayValue, TempString);
    BCQ: TempStringIsTrue := BandMapDisplayCQ;
    BME: TempStringIsTrue := BandMapEnable;
    BMG: Str(BandMapGuardBand, TempString);

    {KK1L: 6.64}
    BSM: case BandMapSplitMode of
        ByCutoffFrequency: TempString := 'BY CUTOFF FREQ';
        AlwaysPhone: TempString := 'ALWAYS PHONE';
      end;

    BNA: TempStringIsTrue := BeepEnable;
    BET: TempStringIsTrue := BeepEvery10QSOs;
    //      BRL:         if BigRemainingList then asm inc ebx end;//TempStringIsTrue := True; //TempString := 'TRUE';
    BPD: TempStringIsTrue := Packet.BroadcastAllPacketData;
    CAU: TempStringIsTrue := CallsignUpdateEnable;
    CCA: TempStringIsTrue := tr4w_CustomCaret;
    CLF: TempStringIsTrue := CheckLogFileSize;
    //      CDE:
    //         if ColumnDupeSheetEnable then asm inc ebx end;//TempStringIsTrue := True; //TempString := 'TRUE';
    CAS: TempStringIsTrue := tConnectionAtStartup;
    CCO: TempString := ConnectionCommand;
    CID: TempString := ComputerID;
    CNA: TempString := ComputerName;
    CEC: TempStringIsTrue := ConfirmEditChanges;
    CIF: TempString := CountryInformationFile;
{
    CKM:
      if CPUKeyer.CurtisModeA then
        TempString := 'A'
      else
        TempString := 'B';
}
    CWE: TempStringIsTrue := CWEnable;
    CWS: TempStringIsTrue := CWSpeedFromDataBase;
    CSI: Str(CodeSpeedIncrement, TempString);
    CWT: Str(CWTone, TempString);
    DEE: TempStringIsTrue := DEEnable;
    DIG: TempStringIsTrue := DigitalModeEnable;

    DIS: case DistanceMode of
        NoDistanceDisplay: TempString := 'NONE';
        DistanceMiles: TempString := 'MILES';
        DistanceKM: TempString := 'KM';
      end;
    //    DMF: TempString := DomQTHTable.ActiveDomQTHFile;
    DAR: TempStringIsTrue := Sheet.tAutoReset;

    DCS: case DupeCheckSound of
        DupeCheckNoSound: TempString := 'NONE';
        DupeCheckBeepIfDupe: TempString := 'DUPE BEEP';
        DupeCheckGratsIfMult: TempString := 'MULT FANFARE';
      end;
    DVE: TempStringIsTrue := DVPEnable;
    //      DVP: TempString := DVPPath;
    EES: TempStringIsTrue := EscapeExitsSearchAndPounce;
    EME: TempStringIsTrue := ExchangeMemoryEnable;
    FWE: TempStringIsTrue := FarnsworthEnable;
    FWS: Str(FarnsworthSpeed, TempString);
    FSF: Str(FloppyFileSaveFrequency, TempString);
    FSE: TempString := FloppyFileSaveName;

    FSM: case FootSwitchMode of
        FootSwitchDisabled: TempString := 'DISABLED';
        FootSwitchF1: TempString := 'F1';
        FootSwitchLastCQFreq: TempString := 'LAST CQ FREQ';
        FootSwitchNextBandMap: TempString := 'NEXT BANDMAP';
        FootSwitchNextDisplayedBandMap: TempString := 'NEXT DISP BANDMAP'; {KK1L: 6.64}
        FootSwitchNextMultBandMap: TempString := 'NEXT MULT BANDMAP'; {KK1L: 6.68}
        FootSwitchNextMultDisplayedBandMap: TempString := 'NEXT MULT DISP BANDMAP'; {KK1L: 6.68}
        FootSwitchUpdateBandMapBlinkingCall: TempString := 'UPDATE BAND MAP BLINKING CALL';
        FootSwitchDupecheck: TempString := 'DUPE CHECK';
        Normal: TempString := 'NORMAL';
        QSONormal: TempString := 'QSO NORMAL';
        QSOQuick: TempString := 'QSO QUICK';
        FootSwitchControlEnter: TempString := 'CONTROL ENTER';
        StartSending: TempString := 'START SENDING';
        SwapRadio: TempString := 'SWAP RADIOS';
        CWGrant: TempString := 'CW GRANT';
      end;

    FPR: Str(FreqPollRate, TempString); {KK1L: 6.71}
    FME:
      TempStringIsTrue := FrequencyMemoryEnable;
    FCR: TempStringIsTrue := Radio1.FT1000MPCWReverse;
    GMC: TempString := GridMapCenter;
    HFE: TempStringIsTrue := HFBandEnable;

    HDP: case HourDisplay of
        ThisHour: TempString := 'THIS HOUR';
        LastSixtyMins: TempString := 'LAST SIXTY MINUTES';
      end;
    ITE: TempStringIsTrue := IncrementTimeEnable;
    IFE: TempStringIsTrue := IntercomFileenable;

    {    IEX: case ActiveInitialExchange of
            NoInitialExchange: TempString := 'NONE';
            NameInitialExchange: TempString := 'NAME';
            NameQTHInitialExchange: TempString := 'NAME QTH';
            CheckSectionInitialExchange: TempString := 'CHECK SECTION';
            SectionInitialExchange: TempString := 'SECTION';
            QTHInitialExchange: TempString := 'QTH';
            FOCInitialExchange: TempString := 'FOC NUMBER';
            GridInitialExchange: TempString := 'GRID';
            ZoneInitialExchange: TempString := 'ZONE';
            User1InitialExchange: TempString := 'USER 1';
            User2InitialExchange: TempString := 'USER 2';
            User3InitialExchange: TempString := 'USER 3';
            User4InitialExchange: TempString := 'USER 4';
            User5InitialExchange: TempString := 'USER 5';
            CustomInitialExchange: TempString := 'CUSTOM';
          end;
    }
    IXO: TempStringIsTrue := InitialExchangeOverwrite; {KK1L: 6.70}

    IEC: case InitialExchangeCursorPos of
        AtStart: TempString := 'AT START';
        AtEnd: TempString := 'AT END';
      end;

    //    KNE: TempStringIsTrue := K1EANetworkEnable;
    //    KSI: TempString := K1EAStationID;
    KCM: TempStringIsTrue := KeypadCWMemories;
    LDZ: Str(LeadingZeros, TempString);
    LZC: TempString := LeadingZeroCharacter;
    LCI: TempStringIsTrue := LeaveCursorInCallWindow;
    LFE: TempStringIsTrue := LogFrequencyEnable;
    LRS: Str(LogRSSent, TempString);
    LDQ: TempStringIsTrue := LiteralDomesticQTH;
    LRT: Str(LogRSTSent, TempString);
    LSE: TempStringIsTrue := LogWithSingleEnter;
    LFR: TempStringIsTrue := LookForRSTSent;
    MSE: TempStringIsTrue := MessageEnable;
    MCF: TempStringIsTrue := tMissCallsFileEnable;
    MCN: TempString := GetContinentName(MyContinent);
    MCU: TempString := MyCountry;

    MRM: Str(MultReportMinimumBands, TempString);
    MIM: TempString := MultiInfoMessage;
    MMO: TempStringIsTrue := MultiMultsOnly;
    //    MMP: TempString := MMTTYPATH;

    MRT: Str(MultiRetryTime, TempString);
    MUM: TempStringIsTrue := MultiUpdateMultDisplay;
    //    MBA:      if MultipleBandsEnabled then asm inc ebx end;//TempStringIsTrue := True; //TempString := 'TRUE';
    //    MMD:      if MultipleModesEnabled then asm inc ebx end;//TempStringIsTrue := True; //TempString := 'TRUE';
    MFD: TempString := MyFDClass;
    MGR: TempString := tMakeGridFromCardinal(MyGrid);
    MZN: TempString := MyZone;
    MIO: TempString := MyIOTA;
    NFE: TempStringIsTrue := NameFlagEnable;
    NLQ: TempStringIsTrue := NoLog;
    NPP: TempStringIsTrue := NoPollDuringPTT;
    PAL: TempStringIsTrue := PacketAddLF;
    PAR: TempStringIsTrue := PacketAutoCR;
    PBS: TempStringIsTrue := Packet.PacketBandSpots;
    PBP: TempStringIsTrue := Packet.PacketBeep;

    PRM: Str(PacketReturnPerMinute, TempString);
    psc: TempString := PacketSpotComment; {KK1L: 6.71 Implimented what I started in 6.68}
    PKD: TempStringIsTrue := PacketSpotDisable;
    PSE: TempStringIsTrue := PacketSpotEditEnable;
    SPO: TempStringIsTrue := PacketSpotPrefixOnly; {KK1L: 6.72}

    PSP:
      if Packet.PacketSpots = AllSpots then
        TempString := 'ALL'
      else
        TempString := 'MULT';

    PBE: TempStringIsTrue := PaddleBug;
    PMT: Str(PaddleMonitorTone, TempString);
    PHC: Str(PaddlePTTHoldCount, TempString);
    PSD: Str(PaddleSpeed, TempString);
    PCE: TempStringIsTrue := PartialCallEnable;
    //      PCL: TempStringIsTrue := PartialCallLoadLogEnable;
    PCM: TempStringIsTrue := PartialCallMultsEnable;
    PCA: TempStringIsTrue := PossibleCallEnable;

    PCN: case CD.PossibleCallAction of {KK1L: 6.69 support log only check partial}
        AnyCall: TempString := 'ALL';
        OnlyCallsWithNames: TempString := 'NAMES';
        LogOnly: TempString := 'LOG ONLY';
      end;

    PBL: TempStringIsTrue := PTTLockout;
    PTT: TempStringIsTrue := PTTEnable;
    PTD: Str(PTTTurnOnDelay, TempString);
    PVC: TempStringIsTrue := tPTTViaCommand;

    QMD: case ParameterOkayMode of
        Standard: TempString := 'Standard';
        QSLButDoNotLog: TempString := 'QSL but no log';
        QSLAndLog: TempString := 'QSL and log';
      end;

    QNB: TempStringIsTrue := QSONumberByBand;
    QSX: TempStringIsTrue := QSXEnable;
    QMC: TempString := QuestionMarkChar;

    //    R1CP: Str(Radio1.CommandPause, TempString);
    R1FA: Str(Radio1.FrequencyAdder, TempString);
//    R1ID: TempString := Radio1.IDCharacter;
    //    R1PT: Str(Radio1.PollTimeout, TempString);
    //    R1TE: TempStringIsTrue := Radio1.TrackingEnable;
    //    R1US: Str(Radio1.UpdateSeconds, TempString);

    //    R2CP: Str(Radio2.CommandPause, TempString);
    R2FA: Str(Radio2.FrequencyAdder, TempString);
//    R2ID: TempString := Radio2.IDCharacter;
    //    R2PT: Str(Radio2.PollTimeout, TempString);
    //    R2TE: TempStringIsTrue := Radio2.TrackingEnable;
    //    R2US: Str(Radio2.UpdateSeconds, TempString);
    RCQ: TempStringIsTrue := RandomCQMode;

    RDS: case RateDisplay of
        QSOs: TempString := 'QSOs';
        Points: TempString := 'QSO Points';
        BandQSOs: TempString := 'Band QSOs';
      end;

    RMD: case RemainingMultDisplayMode of
        NoRemainingMults: TempString := 'None';
        Erase: TempString := 'Erase';
        HiLight: TempString := 'HiLight';
      end;
    SHE: TempStringIsTrue := SayHiEnable;
    SHC: Str(SayHiRateCutOff, TempString);
    SCS: TempString := CD.CountryString;
    SML: Str(SCPMinimumLetters, TempString);
    SAD: TempStringIsTrue := SendAltDSpotsToPacket;
    SCF: TempStringIsTrue := SendCompleteFourLetterCall;
    SSN:
      begin
        if StartSendingNowKey = ' ' then TempString := 'SPACE' else TempString := StartSendingNowKey;
      end;

    SPS: TempStringIsTrue := StereoPinState; {KK1L: 6.71}
    SQI: TempStringIsTrue := SendQSOImmediately;

    SIA: TempString := ServerAddress;
    SPA: TempString := ServerPassword;
    SEP: TempString := IntToStr(ServerPort);

    SKE: TempStringIsTrue := ShiftKeyEnable;
    SIN: TempStringIsTrue := ShortIntegers;
    //    SSP: TempStringIsTrue := ShowSearchAndPounce;
    SLG: TempStringIsTrue := tLogLogGridlines;
    //    SEN:      if DDXState <> Off then asm inc ebx end;//TempStringIsTrue := True; //TempString := 'TRUE';

    SRM: TempStringIsTrue := SingleRadioMode;
    SAB: TempStringIsTrue := SkipActiveBand;

    {KK1L: 6.65}
    SAS: TempStringIsTrue := CallWindowShowAllSpots;
    SMC: TempString := SlashMarkChar;
    SBD: TempStringIsTrue := SpaceBarDupeCheckEnable;
    SQR: TempStringIsTrue := SprintQSYRule;
    SRP: TempStringIsTrue := SwapPacketSpotRadios;
    SWP: TempStringIsTrue := SwapPaddles;
    SWR: TempStringIsTrue := SwapRadioRelaySense;
    {
        TAB:
          begin
            if TabMode = NormalTabMode then TempString := 'NORMAL';
            if TabMode = ControlFTabMode then TempString := 'CONTROLF';
          end;
    }
    TMR: case TenMinuteRule of
        NoTenMinuteRule: TempString := 'NONE';
        TimeOfFirstQSO: TempString := 'TIME OF FIRST QSO';
      end;

    TOT: TempString := MinutesToTimeString(TotalOffTime);
    TDE: TempStringIsTrue := TuneDupeCheckEnable;
    TWD: TempStringIsTrue := TuneWithDits;
    TRM: TempStringIsTrue := TwoRadioMode; //if TwoRadioState <> TwoRadiosDisabled then asm inc ebx        end;

    URF: TempStringIsTrue := UpdateRestartFileEnable;
    UIS: case UserInfoShown of
        NoUserInfo: TempString := 'NONE';
        NameInfo: TempString := 'NAME';
        QTHInfo: TempString := 'QTH';
        CheckSectionInfo: TempString := 'CHECK SECTION';
        SectionInfo: TempString := 'SECTION';
        OldCallInfo: TempString := 'OLD CALL';
        FocInfo: TempString := 'FOC NUMBER';
        GridInfo: TempString := 'GRID';
        ITUZoneInfo: TempString := 'ITU ZONE';
        CQZoneInfo: TempString := 'CQ ZONE';
        User1Info: TempString := 'USER 1';
        User2Info: TempString := 'USER 2';
        User3Info: TempString := 'USER 3';
        User4Info: TempString := 'USER 4';
        User5Info: TempString := 'USER 5';
        CustomInfo: TempString := 'CUSTOM';
      end;
    URS: TempStringIsTrue := tUseRecordedSigns;

    VBE: TempStringIsTrue := VHFBandsEnabled;

    VER:
      TempString := TR4W_CURRENTVERSION;

    //      VDS:         if VisibleDupesheetEnable then asm inc ebx end;//TempStringIsTrue := True; //TempString := 'TRUE';
    WFS: TempStringIsTrue := WaitForStrength;
    WUT: Str(WakeUpTimeOut, TempString);
    WBE: TempStringIsTrue := WARCBandsEnabled;
    WEI: Str(Weight: 3: 2, TempString);
    WCP: TempStringIsTrue := WildCardPartials;
  else TempString := '';
  end;
  if TempStringIsTrue = True then TempString := 'TRUE';
  {
  asm
  cmp ebx,1
  jnz NoTrue
  end;
  TempString := 'TRUE';
  NoTrue:
  }
  Value := TempString;
end;

procedure SendParameterToNetwork(Line: MenuEntryType);
begin
  if NetSocket = 0 then Exit;
  Windows.ZeroMemory(@ParameterToNetwork.pnCommand, SizeOf(ParameterToNetwork.pnCommand) + SizeOf(ParameterToNetwork.pnValue));
  ParameterToNetwork.pnCommand := ShortString(Description(Line));
  ParameterToString(Line, ParameterToNetwork.pnValue);
  SendToNet(ParameterToNetwork, SizeOf(ParameterToNetwork));
end;

function GetActiveLineFromEntryString(EntryString: Str80): MenuEntryType;

var
  Entry                                 : MenuEntryType;

begin
  while EntryString <> '' do
  begin
    for Entry := NoMenuEntry to LastMenuEntry do
      if Copy(Description(Entry), 1, length(EntryString)) = EntryString then
      begin
            //W_L_I                 IF Entry = LastMenuEntry THEN Entry := Pred (Entry);

        GetActiveLineFromEntryString := Entry;
        Exit;
      end;

      { Not found - Delete last letter and go from there }

    Delete(EntryString, length(EntryString), 1);
  end;

  { No good - go to first line }

  Entry := NoMenuEntry;
  Entry := Succ(Entry);
  GetActiveLineFromEntryString := Entry;

end;

begin

end.

