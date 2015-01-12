unit JCtrl1;

{$O+}
{$F+}
{$IMPORTEDDATA OFF}
interface

uses Tree,
  TF,
  VC,
  Windows,
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
  LogRadio,
  LogNet,
  BeepUnit,
  LogStuff
{$IF LANG = 'ENG'}, TR4W_CONSTS_ENG{$IFEND}
{$IF LANG = 'RUS'}, TR4W_CONSTS_RUS{$IFEND}
{$IF LANG = 'SER'}, TR4W_CONSTS_SER{$IFEND}
{$IF LANG = 'ESP'}, TR4W_CONSTS_ESP{$IFEND}
  ;

type
  MenuEntryType = (NoMenuEntry,
    ACC,
    AAU,
    ABE,
    ABC,
    AFF,
    //    AIO,
    ACT,
    AAD,
    ADP,
    ADE,
    ADS,
    AQI,
    AQD,
    ASP,
    ASR, {KK1L: 6.72}
    Arc,
    asc,
    ATI,
    BEN,
    BAB,
    BAM,
    BCW,
    BMD,
    //    BMO, {KK1L: 6.xx}
    BCQ,
    BDD,
    BME,
    BMG,
    BSM,
    BNA,
    BET,
    //      BRL,wli
    BPD,
    SAS,
    CAU,
    CCA, //wli custom caret
    CLF,
    //      CDE,

    CID,
    CNA,
    CEC,
    CAS,
    CCO,
    CIF,
//    CKM,
    CWE,
    CWS,
    CSI, {KK1L: 6.72}
    CWT,
    DEE,
    DIG,
    DIS,
    //    DMF,
    DAR, //DUPE SHEET AUTO RESET
    DCS,
    //      DSE,
    //      DVK,
    DVE,
    //    DVP,
    EES,
    //    EEE,

    EME,
    FWE,
    FWS,
    FSF,
    FSE,
    FSM,
    FPR, {KK1L: 6.71a FrequencyPollRate}
    FME,
    FCR,
    GMC,
    HFE,
    HDP,
    //    HOF,{hour offset}
    //    ICP,
    ITE,
    //    IEX,wli
    IXO, {KK1L: 6.70}
    IEC,
    IFE,
    //    KNE,
    //    KSI,
    KCM,
    LDZ,
    LZC,
    LCI,
    LDQ,
    LFE,
    LRS,
    LRT,
    LSE,
    LFR,
    MSE,
    MCF,
    //      MEN,
    MRM,
    MIM,
    MMO,
    //    MMP,
    MRT,
    MUM,
    //    MBA,// надо записывать в *.cfg
    //    MMD,// надо записывать в *.cfg
    //    MCL,// надо записывать только в *.cfg
    MCN,
    MCU,
    MFD,
    MGR,
    MIO,
    MZN,
    NFE,
    NLQ,
    NPP,
    PAL,
    PAR,
    PBS,
    PBP,
    PLF,
    PRM,
    psc, {KK1L: 6.71 Coded for PacketSpotComment started in 6.68}
    PKD,
    PSE,
    SPO, {KK1L: 6.72}
    PSP,
    PBE,
    PMT,
    PHC,
    PSD,
    PCE,
    //    PCL,
    PCM,
    PCA,
    PCN,
    //W_L_I    PEN,
    PBL,
    PTT,
    PTD,
    PVC, {PTT VIA COMMANDS}
    QMD,
    QNB,
    QSX,
    QES,
    QRS,
    QMC,

    { Radio One things }

//    R1CP, { Command Pause }
    R1FA, { Frequency adder }
//    R1ID, { ID Character }
    //    R1PT, { Poll Timeout }
    //    R1TE, { Tracking Enable }
    //    R1US, { Update Seconds }

        { Radio Two things }

    //    R2CP, { Command Pause }
    R2FA, { Frequency adder }
//    R2ID, { ID Character }
    //    R2PT, { Poll Timeout }
    //    R2TE, { Tracking Enable }
    //    R2US, { Update Seconds }

    RCQ,
    RDS,
    RMD,
    SHE,
    SHC,
    SCS,
    SML,
    SAD,
    SCF,
    SQI,
    SIA,
    SPA,
    SEP,
    SKE,
    SIN,
    SLG,
    //    SSP,
    //    SEN,
    SRM,
    SAB,
    SMC,
    SBD,
    SQR,
    SSN, {2.01 wli start sending now key}
    SPS, {KK1L: 6.71 StereoPinState}
    SRP,
    SWP,
    SWR,
    //    TAB,
    TMR,
    TOT,
    TDE, {KK1L: 6.73 TuneDupeCheckEnable}
    TWD,
    TRM,
    URF,
    //      UBC,
    UIS,
    URS,
    VER,
    //      VDE,
    VBE,
    //      VDS,wli
    WFS,
    WUT,
    WBE,
    WEI,
    WCP,
    LastMenuEntry);

var
  FileRead                              : Text;
  ChangedRemainingMults                 : boolean;
  DisplayString                         : Str80;
//  Changed                               : array[MenuEntryType] of boolean;

function Description(Line: MenuEntryType): PChar;
function DisplayInfoLine(Line: MenuEntryType; Active: boolean): PChar;

implementation
uses MainUnit,
  uNet;

function Description(Line: MenuEntryType): PChar;

begin
  case Line of
    NoMenuEntry: Description := '0';

    ACC: Description := 'ALL CW MESSAGES CHAINABLE';
    AAU: Description := 'ALLOW AUTO UPDATE';
    ABE: Description := 'ALT-D BUFFER ENABLE';
    ABC: Description := 'ALWAYS CALL BLIND CQ';
    AFF: Description := 'ASK FOR FREQUENCIES';
    //    AIO: Description := 'ASK IF CONTEST OVER';
    ACT: Description := 'AUTO CALL TERMINATE';
    AAD: Description := 'AUTO ALT-D ENABLE';
    ADP: Description := 'AUTO DISPLAY DUPE QSO';
    ADE: Description := 'AUTO DUPE ENABLE CQ';
    ADS: Description := 'AUTO DUPE ENABLE S AND P';
    AQI: Description := 'AUTO QSL INTERVAL';
    AQD: Description := 'AUTO QSO NUMBER DECREMENT';
    ASP: Description := 'AUTO S&P ENABLE';
    ASR: Description := 'AUTO S&P ENABLE SENSITIVITY'; {KK1L: 6.72}
    Arc: Description := 'AUTO RETURN TO CQ MODE';
    asc: Description := 'AUTO SEND CHARACTER COUNT';
    ATI: Description := 'AUTO TIME INCREMENT';

    BEN: Description := 'BACKCOPY ENABLE';
    BAB: Description := 'BAND MAP ALL BANDS';
    BAM: Description := 'BAND MAP ALL MODES';
    BCW: Description := 'BAND MAP CALL WINDOW ENABLE';
    BMD: Description := 'BAND MAP DECAY TIME';
    BCQ: Description := 'BAND MAP DISPLAY CQ';
    BDD: Description := 'BAND MAP DUPE DISPLAY';
    BME: Description := 'BAND MAP ENABLE';
    BMG: Description := 'BAND MAP GUARD BAND';
    //    BMO: Description := 'BAND MAP MULTS ONLY';
    BSM: Description := 'BAND MAP SPLIT MODE';
    BNA: Description := 'BEEP ENABLE';
    BET: Description := 'BEEP EVERY 10 QSOS';
    //      BRL: Description := 'BIG REMAINING LIST';
    BPD: Description := 'BROADCAST ALL PACKET DATA';

    {KK1L: 6.65}
    SAS: Description := 'CALL WINDOW SHOW ALL SPOTS';
    CAU: Description := 'CALLSIGN UPDATE ENABLE';
    //    CAL: Description := 'CALLSIGN AS LOGIN';
    CCA: Description := 'CUSTOM CARET';
    CLF: Description := 'CHECK LOG FILE SIZE';
    //      CDE: Description := 'COLUMN DUPESHEET ENABLE';
    CID: Description := 'COMPUTER ID';
    CNA: Description := 'COMPUTER NAME';
    CEC: Description := 'CONFIRM EDIT CHANGES';
    CAS: Description := 'CONNECTION AT STARTUP';
    CCO: Description := 'CONNECTION COMMAND';

    CIF: Description := 'COUNTRY INFORMATION FILE';
//    CKM: Description := 'CURTIS KEYER MODE';
    CWE: Description := 'CW ENABLE';
    CWS: Description := 'CW SPEED FROM DATABASE';
    CSI: Description := 'CW SPEED INCREMENT'; {KK1L: 6.72}
    CWT: Description := 'CW TONE';

    DEE: Description := 'DE ENABLE';
    DIG: Description := 'DIGITAL MODE ENABLE';
    DIS: Description := 'DISTANCE MODE';
    //    DMF: Description := 'DOMESTIC FILENAME';

    DAR: Description := 'DUPE SHEET AUTO RESET';
    DCS: Description := 'DUPE CHECK SOUND';
    //      DSE: Description := 'DUPE SHEET ENABLE';
    //      DVK: Description := 'DVK PORT';
    DVE: Description := 'DVP ENABLE';
    //      DVP: Description := 'DVP PATH';

    EES: Description := 'ESCAPE EXITS SEARCH AND POUNCE';
    //    EEE: Description := 'ETHERNET NETWORK ENABLE';

    EME: Description := 'EXCHANGE MEMORY ENABLE';

    FWE: Description := 'FARNSWORTH ENABLE';
    FWS: Description := 'FARNSWORTH SPEED';

    FSF: Description := 'FLOPPY FILE SAVE FREQUENCY';
    FSE: Description := 'FLOPPY FILE SAVE NAME';
    FSM: Description := 'FOOT SWITCH MODE';
    FPR: Description := 'FREQUENCY POLL RATE'; {KK1L: 6.71a}
    FME: Description := 'FREQUENCY MEMORY ENABLE';
    FCR: Description := 'FT1000MP CW REVERSE';

    GMC: Description := 'GRID MAP CENTER';

    HFE: Description := 'HF BAND ENABLE';
    HDP: Description := 'HOUR DISPLAY';
    //    HOF: Description := 'HOUR OFFSET';

    //    ICP: Description := 'ICOM COMMAND PAUSE';
    ITE: Description := 'INCREMENT TIME ENABLE';
    IFE: Description := 'INTERCOM FILE ENABLE';
    //    IEX: Description := 'INITIAL EXCHANGE';
    IXO: Description := 'INITIAL EXCHANGE OVERWRITE'; {KK1L: 6.70}
    IEC: Description := 'INITIAL EXCHANGE CURSOR POS';

    //    KNE: Description := 'K1EA NETWORK ENABLE';
    //    KSI: Description := 'K1EA STATION ID';

    KCM: Description := 'KEYPAD CW MEMORIES';

    LDZ: Description := 'LEADING ZEROS';
    LZC: Description := 'LEADING ZERO CHARACTER';
    LCI: Description := 'LEAVE CURSOR IN CALL WINDOW';
    LDQ: Description := 'LITERAL DOMESTIC QTH';
    LFE: Description := 'LOG FREQUENCY ENABLE';
    LRS: Description := 'LOG RS SENT';
    LRT: Description := 'LOG RST SENT';
    LSE: Description := 'LOG WITH SINGLE ENTER';
    LFR: Description := 'LOOK FOR RST SENT';

    MSE: Description := 'MESSAGE ENABLE';
    MCF: Description := 'MISSINGCALLSIGNS FILE ENABLE';
    //      MEN: Description := 'MOUSE ENABLE';
    MRM: Description := 'MULT REPORT MINIMUM BANDS';
    MIM: Description := 'MULTI INFO MESSAGE';
    MMO: Description := 'MULTI MULTS ONLY';
    //    MMP: Description := 'MMTTY PATH';

    MRT: Description := 'MULTI RETRY TIME';
    MUM: Description := 'MULTI UPDATE MULT DISPLAY';
    //    MBA: Description := 'MULTIPLE BANDS';
    //    MMD: Description := 'MULTIPLE MODES';
    //    MCL: Description := 'MY CALL';
    MCN: Description := 'MY CONTINENT';
    MCU: Description := 'MY COUNTRY';
    MFD: Description := 'MY FD CLASS';
    MGR: Description := 'MY GRID';
    MIO: Description := 'MY IOTA';
    MZN: Description := 'MY ZONE';

    NFE: Description := 'NAME FLAG ENABLE';
    NLQ: Description := 'NO LOG';
    NPP: Description := 'NO POLL DURING PTT';

    PAL: Description := 'PACKET ADD LF';
    PAR: Description := 'PACKET AUTO CR';
    PBS: Description := 'PACKET BAND SPOTS';
    PBP: Description := 'PACKET BEEP';
    PLF: Description := 'PACKET LOG FILENAME';
    PRM: Description := 'PACKET RETURN PER MINUTE';
    psc: Description := 'PACKET SPOT COMMENT'; {KK1L: 6.71 Implimented what I started in 6.68}
    PKD: Description := 'PACKET SPOT DISABLE';
    PSE: Description := 'PACKET SPOT EDIT ENABLE';
    SPO: Description := 'PACKET SPOT PREFIX ONLY'; {KK1L: 6.72}
    PSP: Description := 'PACKET SPOTS';
    PBE: Description := 'PADDLE BUG ENABLE';
    PMT: Description := 'PADDLE MONITOR TONE';
    PHC: Description := 'PADDLE PTT HOLD COUNT';
    PSD: Description := 'PADDLE SPEED';
    PCE: Description := 'PARTIAL CALL ENABLE';
    //    PCL: Description := 'PARTIAL CALL LOAD LOG ENABLE';
    PCM: Description := 'PARTIAL CALL MULT INFO ENABLE';
    PCA: Description := 'POSSIBLE CALLS';
    PCN: Description := 'POSSIBLE CALL MODE';
    //W_L_I    PEN: Description := 'PRINTER ENABLE';
    PBL: Description := 'PTT LOCKOUT';
    PTT: Description := 'PTT ENABLE';
    PTD: Description := 'PTT TURN ON DELAY';
    PVC: Description := 'PTT VIA COMMANDS';

    QMD: Description := 'QSL MODE';
    QNB: Description := 'QSO NUMBER BY BAND';
    QSX: Description := 'QSX ENABLE';
    QES: Description := 'QTC EXTRA SPACE';
    QRS: Description := 'QTC QRS';
    QMC: Description := 'QUESTION MARK CHAR';

    //    R1CP: Description := 'RADIO ONE COMMAND PAUSE';
    R1FA: Description := 'RADIO ONE FREQUENCY ADDER';
//    R1ID: Description := 'RADIO ONE ID CHARACTER';
    //    R1PT: Description := 'RADIO ONE RESPONSE TIMEOUT';
    //    R1TE: Description := 'RADIO ONE TRACKING ENABLE';
    //    R1US: Description := 'RADIO ONE UPDATE SECONDS';

    //    R2CP: Description := 'RADIO TWO COMMAND PAUSE';
    R2FA: Description := 'RADIO TWO FREQUENCY ADDER';
//    R2ID: Description := 'RADIO TWO ID CHARACTER';
    //    R2PT: Description := 'RADIO TWO RESPONSE TIMEOUT';
    //    R2TE: Description := 'RADIO TWO TRACKING ENABLE';
    //    R2US: Description := 'RADIO TWO UPDATE SECONDS';

    RCQ: Description := 'RANDOM CQ MODE';
    RDS: Description := 'RATE DISPLAY';
    RMD: Description := 'REMAINING MULT DISPLAY MODE';

    SHE: Description := 'SAY HI ENABLE';
    SHC: Description := 'SAY HI RATE CUTOFF';
    SCS: Description := 'SCP COUNTRY STRING';
    SML: Description := 'SCP MINIMUM LETTERS';
    SAD: Description := 'SEND ALT-D SPOTS TO PACKET';
    SCF: Description := 'SEND COMPLETE FOUR LETTER CALL';
    SQI: Description := 'SEND QSO IMMEDIATELY';

    SIA: Description := 'SERVER ADDRESS';
    SPA: Description := 'SERVER PASSWORD';
    SEP: Description := 'SERVER PORT';

    SKE: Description := 'SHIFT KEY ENABLE';
    SIN: Description := 'SHORT INTEGERS';
    SLG: Description := 'SHOW LOG GRIDLINES';
    //    SSP: Description := 'SHOW SEARCH AND POUNCE';
    //    SEN: Description := 'SIMULATOR ENABLE';
    SRM: Description := 'SINGLE RADIO MODE';
    SAB: Description := 'SKIP ACTIVE BAND';
    SMC: Description := 'SLASH MARK CHAR';
    SBD: Description := 'SPACE BAR DUPE CHECK ENABLE';
    SQR: Description := 'SPRINT QSY RULE';
    SSN: Description := 'START SENDING NOW KEY'; {KK1L: 6.71}
    SPS: Description := 'STEREO PIN HIGH'; {KK1L: 6.71}
    SRP: Description := 'SWAP PACKET SPOT RADIOS';
    SWP: Description := 'SWAP PADDLES';
    SWR: Description := 'SWAP RADIO RELAY SENSE';

    //    TAB: Description := 'TAB MODE';
    TMR: Description := 'TEN MINUTE RULE';
    TOT: Description := 'TOTAL OFF TIME';
    TDE: Description := 'TUNE ALT-D ENABLE'; {KK1L: 6.73}
    TWD: Description := 'TUNE WITH DITS';
    TRM: Description := 'TWO RADIO MODE';

    URF: Description := 'UPDATE RESTART FILE ENABLE';
    //      UBC: Description := 'USE BIOS KEY CALLS';
    UIS: Description := 'USER INFO SHOWN';
    URS: Description := 'USE RECORDED SIGNS';

    VER: Description := 'VERSION';
    //      VDE: Description := 'VGA DISPLAY ENABLE';
    VBE: Description := 'VHF BAND ENABLE';
    //      VDS: Description := 'VISIBLE DUPESHEET';

    WFS: Description := 'WAIT FOR STRENGTH';
    WUT: Description := 'WAKE UP TIME OUT';
    WBE: Description := 'WARC BAND ENABLE';
    WEI: Description := 'WEIGHT';
    WCP: Description := 'WILDCARD PARTIALS';

    LastMenuEntry: Description := 'ZZZ';
  else Description := '???';
  end;

end;

function DisplayInfoLine(Line: MenuEntryType; Active: boolean): PChar;
var
  I                                     : integer;
begin
  case Line of
    ACC: if AllCWMessagesChainable then RESULT := ACC1 else RESULT := ACC2;

    AAU: if tAllowAutoUpdate then RESULT := AAU1 else RESULT := AAU2;

    ABE: if AltDBufferEnable then RESULT := ABE1 else RESULT := ABE2;

    ABC: if AlwaysCallBlindCQ then RESULT := ABC1 else RESULT := ABC2;

    AFF: if AskForFrequencies then RESULT := AFF1 else RESULT := AFF2;
    {
        AIO:
          if AskIfContestOver then
            RESULT := ('When program exit, ask if contest over')
          else
            RESULT := ('Do not ask if contest over when exiting');
    }
    ACT:
      if AutoCallTerminate then
        RESULT := ACT1
      else
        RESULT := ACT2;

    AAD:
      if K5KA.ModeEnabled then
        RESULT := AAD1
      else
        RESULT := AAD2;

    ADP:
      if AutoDisplayDupeQSO then
        RESULT := ADP1
      else
        RESULT := ADP2;

    ADE:
      if AutoDupeEnableCQ then
        RESULT := ADE1
      else
        RESULT := ADE2;

    ADS:
      if AutoDupeEnableSandP then
        RESULT := ADS1
      else
        RESULT := ADS2;

    AQI:
      if AutoQSLInterval > 0 then
        RESULT := AQI1
      else
        RESULT := AQI2;

    AQD:
      if AutoQSONumberDecrement then
        RESULT := AQD1
      else
        RESULT := AQD2;

    ASP:
      if AutoSAPEnable then
        RESULT := ASP1
      else
        RESULT := ASP2;

    ASR: RESULT := ASR1;

    Arc:
      if AutoReturnToCQMode then
        RESULT := ARC1
      else
        RESULT := ARC2;

    asc:
      if AutoSendCharacterCount = 0 then
        RESULT := ASC1
      else
        RESULT := ASC2;

    ATI:
      if AutoTimeIncrementQSOs > 0 then
        RESULT := ATI1
      else
        RESULT := ATI2;

    BEN:
      if BackCopyEnable then
        RESULT := BEN1
      else
        RESULT := BEN2;

    BAB:
      if BandMapAllBands then
        RESULT := BAB1
      else
        RESULT := BAB2;

    BAM:
      if BandMapAllModes then
        RESULT := BAM1
      else
        RESULT := BAM2;

    BCW:
      if BandMapCallWindowEnable then
        RESULT := BCW1
      else
        RESULT := BCW2;

    BMD: RESULT := BMD1;

    BCQ:
      if BandMapDisplayCQ then
        RESULT := BCQ1
      else
        RESULT := BCQ2;

    BDD:
      if BandMapDupeDisplay then
        RESULT := BDD1
      else
        RESULT := BDD2;

    BME:
      if BandMapEnable then
        //            Result := ('Band map enabled (needs 42/50 lines)')
        RESULT := BME1
      else
        RESULT := BME2;

    BMG: RESULT := BMG1;

    BSM: case BandMapSplitMode of
        ByCutoffFrequency: RESULT := BSM1;
        AlwaysPhone: RESULT := BSM2;
      end;

    BNA:
      if BeepEnable then
        RESULT := BNA1
      else
        RESULT := BNA2;
    BET:
      if BeepEvery10QSOs then
        RESULT := BET1
      else
        RESULT := BET2;

    {      BRL:
             if BigRemainingList then
                Result := ('Large window for remaining mults')
             else
                Result := ('Normal remaining mults window');
    }
    BPD:
      if Packet.BroadcastAllPacketData then
        RESULT := BPD1
      else
        RESULT := BPD2;

    SAS:
      if CallWindowShowAllSpots then
        RESULT := SAS1
      else
        RESULT := SAS2;

    CAU:
      if CallsignUpdateEnable then
        RESULT := CAU1
      else
        RESULT := CAU2;

    //    CAL: Result := ('Send your callsign to telnet server as login');

    CCA:
      if tr4w_CustomCaret then
        RESULT := CCA1
      else
        RESULT := CCA2;

    CLF:
      if CheckLogFileSize then
        RESULT := CLF1
      else
        RESULT := CLF2;

    {      CDE:
             if ColumnDupeSheetEnable then
                Result := ('Vis dupesheet uses new column/district')
             else
                Result := ('Visible sheet runs districts together');
    }

    CAS: RESULT := CAS1;

    CCO: RESULT := CCO1;

    CID:
      if ComputerID = CHR(0) then
        RESULT := ('No computer ID set (used for multi')
      else
        RESULT := ('Computer ID as shown appears in log');

    CNA: RESULT := CNA1;

    CEC:
      if ConfirmEditChanges then
        //        Result := ('Prompt for Y key when exiting AltE')
        RESULT := CEC1
      else
        RESULT := CEC2;

    CIF: RESULT := CIF1;

//    CKM: RESULT := CKM1;

    CWE:
      if CWEnable then
        RESULT := CWE1
      else
        RESULT := CWE2;

    CWS:
      if CWSpeedFromDataBase then
        RESULT := CWS1
      else
        RESULT := CWS2;

    CSI: RESULT := CSI1;

    CWT:
      begin
        if CWTone > 0 then
          RESULT := CWT1
        else
          RESULT := CWT2; NoSound;
      end;

    DEE:
      if DEEnable then
        RESULT := DEE1
      else
        RESULT := DEE2;

    DIG:
      if DigitalModeEnable then
        RESULT := DIG1
      else
        RESULT := DIG2;

    DIS: case DistanceMode of
        NoDistanceDisplay: RESULT := DIS1;
        DistanceMiles: RESULT := DIS2;
        DistanceKM: RESULT := DIS3;
      end;

    //    DMF: Result := ('Name of domestic mult file');

    DAR:
      if Sheet.tAutoReset then
        RESULT := DAR1
      else
        RESULT := DAR2;

    DCS: case DupeCheckSound of
        DupeCheckNoSound: RESULT := DCS1;
        DupeCheckBeepIfDupe: RESULT := DCS2;
        DupeCheckGratsIfMult: RESULT := DCS3;
      end;

    {      DSE:
             if Sheet.DupeSheetEnable then
                Result := ('Calls will be added to dupesheet')
             else
                Result := ('Calls will not be added to dupesheet');
    }
    {      DVK:
             if ActiveDVKPort = Tree.NoPort then
                Result := ('No DVK port selected')
             else
                Result := ('DVK enabled on the port shown');
    }
    DVE:
      begin
        if DVPEnable then
          RESULT := DVE1
        else
          RESULT := DVE2;
        DisplayCodeSpeed;
      end;
    //      DVP: Result := ('DVP PATH = ');

    EES:
      if EscapeExitsSearchAndPounce then
        RESULT := EES1
      else
        RESULT := EES2;
    {
  EEE:
    if EthernetNetworkEnable then
      Result := ('TCP network is enabled')
    else
      Result := ('TCP network is disabled');
     }

    EME:
      if ExchangeMemoryEnable then
        RESULT := EME1
      else
        RESULT := EME2;

    FWE:
      if FarnsworthEnable then
        RESULT := FWE1
      else
        RESULT := FWE2;

    FWS: RESULT := FWS1;
    FSF:
      if FloppyFileSaveFrequency = 0 then
        RESULT := FSF1
      else
        RESULT := FSF2;

    FSE: RESULT := FSE1;

    FSM: case FootSwitchMode of
        FootSwitchF1: RESULT := FSM1;
        FootSwitchDisabled: RESULT := FSM2;
        FootSwitchLastCQFreq: RESULT := FSM3;
        FootSwitchNextBandMap: RESULT := FSM4; FootSwitchNextDisplayedBandMap: RESULT := FSM5;
        FootSwitchNextMultBandMap: RESULT := FSM6;
        FootSwitchNextMultDisplayedBandMap: RESULT := FSM7;
        FootSwitchUpdateBandMapBlinkingCall: RESULT := FSM8;
        FootSwitchDupecheck: RESULT := FSM9;
        Normal: RESULT := FSM10;
        QSONormal: RESULT := FSM11;
        QSOQuick: RESULT := FSM12;
        FootSwitchControlEnter: RESULT := FSM13;
        StartSending: RESULT := FSM14;
        SwapRadio: RESULT := FSM15;
        CWGrant: RESULT := FSM16;
      end;

    FPR: RESULT := FPR1;

    FME:
      if FrequencyMemoryEnable then
        RESULT := FME1
      else
        RESULT := FME2;

    FCR:
      if Radio1.FT1000MPCWReverse then
        RESULT := FCR1
      else
        RESULT := FCR2;

    GMC:
      if GridMapCenter = '' then
        RESULT := GMC1
      else
        RESULT := GMC2;

    HFE:
      if HFBandEnable then
        RESULT := HFE1
      else
        RESULT := HFE2;

    HDP: case HourDisplay of
        ThisHour: RESULT := HDP1;
        LastSixtyMins: RESULT := HDP2;
      end;

    //    HOF: RESULT := ('Offset from computer time to UTC time');

    //    ICP: Result := ('Command delay in ms (default = 300)');

    ITE:
      if IncrementTimeEnable then
        RESULT := ITE1
      else
        RESULT := ITE2;

    IFE:
      if IntercomFileenable then
        RESULT := IFE1
      else
        RESULT := IFE2;

    {    IEX: case ActiveInitialExchange of
            NoInitialExchange: Result := ('Only exchange memory used');
            NameInitialExchange: Result := ('Name from TRMASTER database');
            NameQTHInitialExchange: Result := ('Name and QTH from TRMASTER database');
            CheckSectionInitialExchange: Result := ('Check section from TRMASTER database');
            SectionInitialExchange: Result := ('ARRL Section from TRMASTER database');
            QTHInitialExchange: Result := ('QTH from TRMASTER database');
            FOCInitialExchange: Result := ('FOC number from TRMASTER database');
            GridInitialExchange: Result := ('Grid from TRMASTER database');
            ZoneInitialExchange: Result := ('Compute zone from callsign');
            User1InitialExchange: Result := ('Use TRMASTER user 1 field initial ex');
            User2InitialExchange: Result := ('Use TRMASTER user 2 field initial ex');
            User3InitialExchange: Result := ('Use TRMASTER user 3 field initial ex');
            User4InitialExchange: Result := ('Use TRMASTER user 4 field initial ex');
            User5InitialExchange: Result := ('Use TRMASTER user 5 field initial ex');
            CustomInitialExchange: Result := ('Uses CUSTOM INITIAL EXCHANGE STRING');
          end;
    }
          //KK1L: 6.70 KK1L: 6.73 Changed wording to cover expansion of feature to ALL initial exhanges
    IXO:
      if InitialExchangeOverwrite then
        RESULT := IXO1
      else
        RESULT := IXO2;

    IEC: case InitialExchangeCursorPos of
        AtStart: RESULT := IEC1;
        AtEnd: RESULT := IEC2;
      end;
    {
        KNE:
          if K1EANetworkEnable then
            RESULT := ('Use K1EA network protocol')
          else
            RESULT := ('Use N6TR network protocol');
    }
    //    KSI: RESULT := ('Station ID used on K1EA network');

    KCM:
      if KeypadCWMemories then
        RESULT := KCM1
      else
        RESULT := KCM1;

    LDZ:
      if LeadingZeros > 0 then
        RESULT := LDZ1
      else
        RESULT := LDZ2;

    LZC: RESULT := LZC1;

    LCI:
      if LeaveCursorInCallWindow then
        RESULT := LCI1
      else
        RESULT := LCI2;

    LFE:
      if LogFrequencyEnable then
        RESULT := LFE1
      else
        RESULT := LFE2;

    LRS: RESULT := LRS1;

    LDQ:
      if LiteralDomesticQTH then
        RESULT := LDQ1
      else
        RESULT := LDQ2;

    LRT: RESULT := LRT1;

    LSE:
      if LogWithSingleEnter then
        RESULT := LSE1
      else
        RESULT := LSE2;

    LFR:
      if LookForRSTSent then
        RESULT := LFR1
      else
        RESULT := LFR2;

    MSE:
      if MessageEnable then
        RESULT := MSE1
      else
        RESULT := MSE2;

    MCF:
      if tMissCallsFileEnable then
        RESULT := MCF1
      else
        RESULT := MCF2;

    {      MEN:
             if MouseEnable then
                Result := ('Mouse activity enabled')
             else
                Result := ('Mouse disabled');
    }
    MRM: RESULT := MRM1;

    MIM: RESULT := MIM1;

    //    MMP:      Result := 'Full file name of MMTTY.exe';

    MMO:
      if MultiMultsOnly then
        RESULT := MMO1
      else
        RESULT := MMO2;
    MRT: RESULT := MRT1;

    MUM:
      if MultiUpdateMultDisplay then
        RESULT := MUM1
      else
        RESULT := MUM2;

    {    MBA:
          if MultipleBandsEnabled then
            Result := ('You can change bands after 1st QSO')
          else
            Result := ('You can''t change bands after 1st QSO');

        MMD:
          if MultipleModesEnabled then
            Result := ('You can change modes after 1st QSO')
          else
            Result := ('You can''t change modes after 1st QSO');
    }
    //    MCL: Result := ('Call as set by MY CALL in cfg file');
    MCN: RESULT := MCN1;
    MCU: RESULT := MCU1;
    MFD: RESULT := MFD1;
    MGR: RESULT := MGR1;
    MIO: RESULT := MIO1;
    MZN: RESULT := MZN1;
    NFE:
      if NameFlagEnable then
        RESULT := NFE1
      else
        RESULT := NFE2;

    NLQ:
      if NoLog then
        RESULT := NLQ1
      else
        RESULT := NLQ2;

    NPP:
      if NoPollDuringPTT then
        RESULT := NPP1
      else
        RESULT := NPP2;

    PAL:
      if PacketAddLF then
        RESULT := PAL1
      else
        RESULT := PAL2;

    PAR:
      if PacketAutoCR then
        RESULT := PAR1
      else
        RESULT := PAR2;

    PBS:
      if Packet.PacketBandSpots then
        RESULT := PBS1
      else
        RESULT := PBS2;

    PBP:
      if Packet.PacketBeep then
        RESULT := PBP1
      else
        RESULT := PBP2;

    PLF:
      if Packet.PacketLogFileName = '' then
        RESULT := PLF1
      else
        RESULT := PLF2;

    PRM:
      if PacketReturnPerMinute = 0 then
        RESULT := PRM1
      else
      begin
        asm
        push PacketReturnPerMinute
        end;
        wsprintf(wsprintfBuffer, PRM2);
        asm add esp,12
        end;
        RESULT := wsprintfBuffer;
      end;

    psc: RESULT := PSC1;

//KK1L: 6.71 Implimented what I started in 6.68

    PKD:
      if PacketSpotDisable then
        RESULT := PKD1
      else
        RESULT := PKD2;

    PSE:
      if PacketSpotEditEnable then
        RESULT := PSE1
      else
        RESULT := PSE2;

    SPO:
      if PacketSpotPrefixOnly then
        RESULT := SPO1
      else
        RESULT := SPO2;

    PSP:
      if Packet.PacketSpots = AllSpots then
        RESULT := PSP1
      else
        RESULT := PSP2;

    PBE:
      if PaddleBug then
        RESULT := PBE1
      else
        RESULT := PBE2;

    PHC: RESULT := PHC1;

    PMT: RESULT := PMT1;

    PSD:
      if PaddleSpeed = 0 then
        RESULT := PSD1
      else
        RESULT := PSD2;

    PCE:
      if PartialCallEnable then
        RESULT := PCE1
      else
        RESULT := PCE2;
    {
        PCL:
          if PartialCallLoadLogEnable then
            RESULT := ('If new LOG.TRW, partial calls loaded')
          else
            RESULT := ('Partials not loaded from new LOG.TRW');
    }
    PCM:
      if PartialCallMultsEnable then
        RESULT := PCM1
      else
        RESULT := PCM2;

    PCA:
      if PossibleCallEnable then
        RESULT := PCA1
      else
        RESULT := PCA2;

    PCN: case CD.PossibleCallAction of
        AnyCall: RESULT := PCN1;
        OnlyCallsWithNames: RESULT := PCN2;
        LogOnly: RESULT := PCN3;
      end;

    //W_L_I    PEN:      if PrinterEnabled then        Result:=('Each QSO off editable window is printed')      else        Result:=('Real time printing is disabled');
    PBL:
      if PTTLockout then
        RESULT := PBL1
      else
        RESULT := PBL2;

    PTT:
      if PTTEnable then
        RESULT := PTT1
      else
        RESULT := PTT2;

    //      PTD: Result := ('PTT delay before CW sent (* 1.7 ms)');
    PTD: RESULT := PTD1;

    PVC:
      if tPTTViaCommand then
        RESULT := PVC1
      else
        RESULT := PVC2;

    QMD: case ParameterOkayMode of
        Standard: RESULT := QMD1;
        QSLButDoNotLog: RESULT := QMD2;
        QSLAndLog: RESULT := QMD3;
      end;

    QNB:
      if QSONumberByBand then
        RESULT := QNB1
      else
        RESULT := QNB2;

    QES:
      if QTCExtraSpace then
        RESULT := QES1
      else
        RESULT := QES2;

    QRS:
      if QTCQRS then
        RESULT := QRS1
      else
        RESULT := QRS2;

    QSX:
      if QSXEnable then
        RESULT := QSX1
      else
        RESULT := QSX2;

    QMC: RESULT := QMC1;

    //    R1CP: Result := ('Time between commands to radio 1');

    R1FA:
      if Radio1.FrequencyAdder <> 0 then
        RESULT := R1FA1
      else
        RESULT := R1FA2;

//    R1ID: Result := ('Char appended to QSO number for rig 1');

    //    R1PT: Result := ('Response timeout in milliseconds');
    {
        R1TE:
          if Radio1.TrackingEnable then
            Result := ('Radio 1 band/mode tracking enabled')
          else
            Result := ('Radio 1 band/mode tracking disabled');
    }
    {
        R1US:
          if Radio1.UpdateSeconds = 0 then
            Result := ('Normal operation')
          else
            Result := ('# seconds between frequency updates');
    }
    //    R2CP: Result := ('Time between commands to radio 2');

    R2FA:
      if Radio2.FrequencyAdder <> 0 then
        RESULT := R2FA1
      else
        RESULT := R2FA2;

//    R2ID: Result := ('Char appended to QSO number for rig 2');

    //    R2PT: Result := ('Response timeout in milliseconds');
    {
        R2TE:
          if Radio2.TrackingEnable then
            Result := ('Radio 2 band/mode tracking enabled')
          else
            Result := ('Radio 2 band/mode tracking disabled');
    }
    {
        R2US:
          if Radio2.UpdateSeconds = 0 then
            Result := ('Normal operation')
          else
            Result := ('# seconds between frequency updates');
    }
    RCQ:
      if RandomCQMode then
        RESULT := RCQ1
      else
        RESULT := RCQ2;

    RDS: case RateDisplay of
        QSOs: RESULT := RDS1;
        Points: RESULT := RDS2;
        BandQSOs: RESULT := RDS3;
      end;

    RMD: case RemainingMultDisplayMode of
        NoRemainingMults: RESULT := RMD1;
        Erase: RESULT := RMD2;
        HiLight: RESULT := RMD3;
      end;

    SHE:
      if SayHiEnable then
        RESULT := SHE1
      else
        RESULT := SHE2;

    SHC: RESULT := SHC1;

    SCS:
      if CD.CountryString = '' then
        RESULT := SCS1
      else
        RESULT := SCS2;

    SML:
      if SCPMinimumLetters = 0 then
        RESULT := SML1
      else
        RESULT := SML2;

    SAD:
      if SendAltDSpotsToPacket then
        RESULT := SAD1
      else
        RESULT := SAD2;

    SCF:
      if SendCompleteFourLetterCall then
        RESULT := SCF1
      else
        RESULT := SCF2;

    SSN:
      if StartSendingNowKey <> ' ' then
      begin
        asm
        movzx eax, StartSendingNowKey
        push eax
        end;
        wsprintf(wsprintfBuffer, SSN1);
        asm add esp,12
        end;
        RESULT := wsprintfBuffer;
      end
      else
        RESULT := SSN2;

    SPS:
      if StereoPinState then
        RESULT := SPS1
      else
        RESULT := SPS2;

    SQI:
      if SendQSOImmediately then
        RESULT := SQI1
      else
        RESULT := SQI2;

    SIA: RESULT := SIA1;
    SPA: RESULT := SPA1;
    SEP: RESULT := SEP1;
    SKE:
      if ShiftKeyEnable then
        RESULT := SKE1
      else
        RESULT := SKE2;

    SIN:
      if ShortIntegers then
        RESULT := SIN1
      else
        RESULT := SIN2;
    SLG:
      if tLogLogGridlines then
        RESULT := SLG1
      else
        RESULT := SLG2;

    {
        SSP:
          if ShowSearchAndPounce then
            RESULT := ('S&P QSOs marked with "s" in log')
          else
            RESULT := ('S&P QSOs not marked in log');
    }
    {    SEN:
          if DDXState = Off then
            Result := ('Simulator operation disabled')
          else
            Result := ('Simulator operation enabled');
    }

    SRM:
      if SingleRadioMode = True then
        RESULT := SRM1
      else
        RESULT := SRM2;

    SAB:
      if SkipActiveBand then
        RESULT := SAB1
      else
        RESULT := SAB2;

    SMC: RESULT := SMC1;

    SBD:
      if SpaceBarDupeCheckEnable then
        RESULT := SBD1
      else
        RESULT := SBD2;

    SQR:
      if SprintQSYRule then
        RESULT := SQR1
      else
        RESULT := SQR2;

    SRP:
      if SwapPacketSpotRadios then
        RESULT := SRP1
      else
        RESULT := SRP2;

    SWP:
      if SwapPaddles then
        RESULT := SWP1
      else
        RESULT := SWP2;

    SWR:
      if SwapRadioRelaySense then
        RESULT := SWR1
      else
        RESULT := SWR2;
    {
        TAB: case TabMode of
            NormalTabMode: RESULT := ('When edit, tab moves to next field');
            ControlFTabMode: RESULT := ('When edit, tab moves to next word');
          end;
    }
    TMR: case TenMinuteRule of
        NoTenMinuteRule: RESULT := TMR1;
        TimeOfFirstQSO: RESULT := TMR2;
      end;

    TOT: RESULT := TOT1;

    TDE:
      if TuneDupeCheckEnable then
        RESULT := TDE1
      else
        RESULT := TDE2;

    TWD:
      if TuneWithDits then
        RESULT := TWD1
      else
        RESULT := TWD2;

    TRM:
      if TwoRadioMode {TwoRadioState <> TwoRadiosDisabled} then
        RESULT := TRM1
      else
        RESULT := TRM2;

    URF:
      if UpdateRestartFileEnable then
        RESULT := URF1
      else
        RESULT := URF2;

    {      UBC:
             if UseBIOSKeyCalls then
                Result := ('Use BIOS for keys - no F11 or F12')
             else
                Result := ('Bypass BIOS - enable F11 and F12 keys');
    }
    URS:
      if tUseRecordedSigns then
        RESULT := URS1
      else
        RESULT := URS2;

    UIS: case UserInfoShown of
        NoUserInfo: RESULT := UIS1;
        NameInfo: RESULT := UIS2;
        QTHInfo: RESULT := UIS3;
        CheckSectionInfo: RESULT := UIS4;
        SectionInfo: RESULT := UIS5;
        OldCallInfo: RESULT := UIS6;
        FocInfo: RESULT := UIS7;
        GridInfo: RESULT := UIS8;
        CQZoneInfo: RESULT := UIS9;
        ITUZoneInfo: RESULT := UIS10;
        User1Info..User5Info:
          begin
            I := Cardinal(UserInfoShown) - 9;
            asm
                  push i
            end;
            wsprintf(wsprintfBuffer, UIS11);
            asm add esp,12
            end;
            RESULT := wsprintfBuffer;
          end;
        {
        User1Info: Result := ('Data from TRMASTER USER 1 shown');
        User2Info: Result := ('Data from TRMASTER USER 2 shown');
        User3Info: Result := ('Data from TRMASTER USER 3 shown');
        User4Info: Result := ('Data from TRMASTER USER 4 shown');
        User5Info: Result := ('Data from TRMASTER USER 5 shown');
       }
        CustomInfo: RESULT := UIS12;
      end;

    VER: RESULT := VER1;

    {      VDE:
             if VGADisplayEnable then
                Result := ('VGA mode enabled at program start')
             else
                Result := ('VGA mode disabled at program start');
    }
    VBE:
      if VHFBandsEnabled then
        RESULT := VBE1
      else
        RESULT := VBE2;

    {      VDS:
             if VisibleDupesheetEnable then
                Result := ('Visible dupesheet is displayed')
             else
                Result := ('Visible dupesheet is not displayed');
    }
    WFS:
      if WaitForStrength then
        RESULT := WFS1
      else
        RESULT := WFS2;

    WUT:
      if WakeUpTimeOut = 0 then
        RESULT := WUT1
      else
        RESULT := WUT2;

    WBE:
      if WARCBandsEnabled then
        RESULT := WBE1
      else
        RESULT := WBE2;

    WEI: RESULT := WEI1;

    WCP:
      if WildCardPartials then
        RESULT := WCP1
      else
        RESULT := WCP2;

  end;

  if Active then
  begin
      //W_L_I         TextColor (ActiveColor);
      //W_L_I         TextBackground (ActiveBackground);
  end;

end;

begin

end.

