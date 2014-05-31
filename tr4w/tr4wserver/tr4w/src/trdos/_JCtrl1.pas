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
    CEC,
    CAS,
    CCO,
    CIF,
    CKM,
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
  Changed                               : array[MenuEntryType] of boolean;

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

    CEC: Description := 'CONFIRM EDIT CHANGES';
    CAS: Description := 'CONNECTION AT STARTUP';
    CCO: Description := 'CONNECTION COMMAND';

    CIF: Description := 'COUNTRY INFORMATION FILE';
    CKM: Description := 'CURTIS KEYER MODE';
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
        RESULT := ('Start exchange when auto CW done')
      else
        RESULT := ('Requires ENTER key before exchange sent');

    AAD:
      if K5KA.ModeEnabled then
        RESULT := ('Alt-D window enabled during XMIT')
      else
        RESULT := ('Alt-D window not automatically enabled');

    ADP:
      if AutoDisplayDupeQSO then
        RESULT := ('Display previous dupes of station')
      else
        RESULT := ('Do not display previous dupe QSOs');

    ADE:
      if AutoDupeEnableCQ then
        RESULT := ('Send QSO BEFORE MESSAGE to dupes')
      else
        RESULT := ('Work and log dupes in CQ mode');

    ADS:
      if AutoDupeEnableSandP then
        RESULT := ('Do not call dupes in S&P with RETURN')
      else
        RESULT := ('Call dupes in S&P mode with RETURN');

    AQI:
      if AutoQSLInterval > 0 then
        RESULT := ('Number QSOs that use QUICK QSL message')
      else
        RESULT := ('Always use QSL MESSAGE when QSLing');

    AQD:
      if AutoQSONumberDecrement then
        RESULT := ('If in S&P & blank windows, decrement #')
      else
        RESULT := ('No auto decrement if in S&P & no input');

    ASP:
      if AutoSAPEnable then
        RESULT := ('Jump into S&P mode if tuning VFO')
      else
        RESULT := ('Do not jump into S&P mode when tuning');

    ASR: RESULT := ('Auto SAP Enable Sensitivity (Hz/sec)');

    Arc:
      if AutoReturnToCQMode then
        RESULT := ('CQ F1 if RETURN in S&P & blank windows')
      else
        RESULT := ('Stay in S&P if RETURN with blank windows');

    asc:
      if AutoSendCharacterCount = 0 then
        RESULT := ('Auto start send feature disabled')
      else
        RESULT := ('Char position where auto CW starts');

    ATI:
      if AutoTimeIncrementQSOs > 0 then
        RESULT := ('Number QSOs for auto minute increment')
      else
        RESULT := ('Auto time increment disabled');

    BEN:
      if BackCopyEnable then
        RESULT := ('DVP BackCopy is enabled')
      else
        RESULT := ('DVP BackCopy is disabled');

    BAB:
      if BandMapAllBands then
        RESULT := ('All bands shown on band map')
      else
        RESULT := ('Only active band shown on band map');

    BAM:
      if BandMapAllModes then
        RESULT := ('All modes shown on band map')
      else
        RESULT := ('Only active mode shown on band map');

    BCW:
      if BandMapCallWindowEnable then
        RESULT := ('Band map blinking call in call window')
      else
        RESULT := ('No band map calls in call window');

    BMD: RESULT := ('Band map entry decay time (minutes)');

    BCQ:
      if BandMapDisplayCQ then
        RESULT := ('CQs entered into bandmap')
      else
        RESULT := ('CQs not entered into bandmap');

    BDD:
      if BandMapDupeDisplay then
        RESULT := ('Band map shows all calls - even dupes')
      else
        RESULT := ('Band map does not show dupes');

    BME:
      if BandMapEnable then
        //            Result := ('Band map enabled (needs 42/50 lines)')
        RESULT := ('Band map enabled')
      else
        RESULT := ('Band map display is disabled');

    BMG: RESULT := ('Blink if freq is within this limit (hz)');

    BSM: case BandMapSplitMode of
        ByCutoffFrequency: RESULT := ('Use BandMapCutoffFrequency to set mode.');
        AlwaysPhone: RESULT := ('Split entries always phone mode.');
      end;

    BNA:
      if BeepEnable then
        RESULT := ('Beeps enabled')
      else
        RESULT := ('Beeps disabled - computer speaker quiet');

    BET:
      if BeepEvery10QSOs then
        RESULT := ('Short beep after each 10th QSO')
      else
        RESULT := ('No beep to signal each 10th QSO');

    {      BRL:
             if BigRemainingList then
                Result := ('Large window for remaining mults')
             else
                Result := ('Normal remaining mults window');
    }
    BPD:
      if Packet.BroadcastAllPacketData then
        RESULT := ('All packet data sent to network')
      else
        RESULT := ('Only spots and talk data to network');

    SAS:
      if CallWindowShowAllSpots then
        RESULT := ('All spots shown in call window')
      else
        RESULT := ('Displayed spots shown in call window');

    CAU:
      if CallsignUpdateEnable then
        RESULT := ('Updated calls looked for in exchange')
      else
        RESULT := ('No call updates looked for in exchange');

    //    CAL: Result := ('Send your callsign to telnet server as login');

    CCA:
      if tr4w_CustomCaret then
        RESULT := ('Custom caret shape')
      else
        RESULT := ('Default caret shape and width');

    CLF:
      if CheckLogFileSize then
        RESULT := ('Log file size checked after each QSO')
      else
        RESULT := ('No special checking of log file size');

    {      CDE:
             if ColumnDupeSheetEnable then
                Result := ('Vis dupesheet uses new column/district')
             else
                Result := ('Visible sheet runs districts together');
    }

    CAS: RESULT := 'Connect to a telnet server at start of the program';

    CCO: RESULT := 'Command which will be send at telnet connection';

    CID:
      if ComputerID = CHR(0) then
        RESULT := ('No computer ID set (used for multi')
      else
        RESULT := ('Computer ID as shown appears in log');

    CEC:
      if ConfirmEditChanges then
        //        Result := ('Prompt for Y key when exiting AltE')
        RESULT := ('Prompt for YES when exiting AltE')
      else
        RESULT := ('Save AltE changes without asking if ok');

    CIF: RESULT := ('Name of country information file');

    CKM: RESULT := ('Select desired keyer operation mode');

    CWE:
      if CWEnable then
        RESULT := ('CW enabled')
      else
        RESULT := ('CW disabled (except from paddle)');

    CWS:
      if CWSpeedFromDataBase then
        RESULT := ('CQ exchange speed in WPM from TRMASTER')
      else
        RESULT := ('Exchange speed from database disabled');

    CSI: RESULT := ('PGUP/PGDN increment from 1 to 10 WPM');

    CWT:
      begin
        if CWTone > 0 then
          RESULT := ('Computer speaker CW monitor in Hertz')
        else
          RESULT := ('Computer speaker CW monitor disabled');
        NoSound;
      end;

    DEE:
      if DEEnable then
        RESULT := ('Send DE when calling in S&P mode')
      else
        RESULT := ('No DE sent when calling in S&P mode');

    DIG:
      if DigitalModeEnable then
        RESULT := ('CW, DIG and SSB modes enabled')
      else
        RESULT := ('CW and SSB modes enabled');

    DIS: case DistanceMode of
        NoDistanceDisplay: RESULT := ('No display of distance');
        DistanceMiles: RESULT := ('Distance shown in miles');
        DistanceKM: RESULT := ('Distance shown in KM');
      end;

    //    DMF: Result := ('Name of domestic mult file');

    DAR:
      if Sheet.tDupeSheetAutoReset then
        RESULT := ('Automatical sheet clear')
      else
        RESULT := ('User sheet clear');

    DCS: case DupeCheckSound of
        DupeCheckNoSound: RESULT := ('SILENT DUPE CHECKING');
        DupeCheckBeepIfDupe: RESULT := ('BEEP IF DUPE WHEN SPACE BAR');
        DupeCheckGratsIfMult: RESULT := ('BEEP IF DUPE - FANFARE IF MULT');
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
          RESULT := ('DVP is enabled')
        else
          RESULT := ('DVP is not enabled');
        DisplayCodeSpeed;
      end;
    //      DVP: Result := ('DVP PATH = ');

    EES:
      if EscapeExitsSearchAndPounce then
        RESULT := ('ESCAPE key will exit S&P mode')
      else
        RESULT := ('Use SHIFT-TAB to exist S&P mode');

    {
  EEE:
    if EthernetNetworkEnable then
      Result := ('TCP network is enabled')
    else
      Result := ('TCP network is disabled');
     }

    EME:
      if ExchangeMemoryEnable then
        RESULT := ('Exchange memory is enabled')
      else
        RESULT := ('Exchange memory is not enabled');

    FWE:
      if FarnsworthEnable then
        RESULT := ('Expand character spaces < 25 WPM')
      else
        RESULT := ('No expanding of spaces < 25 WPM');

    FWS: RESULT := ('Speed where farnsworth cuts in below');

    FSF:
      if FloppyFileSaveFrequency = 0 then
        RESULT := ('Floppy backups of LOG.DAT are disabled')
      else
        RESULT := ('Number QSOs between saves to floppy');

    FSE: RESULT := ('File to save to when doing floppy save');

    FSM: case FootSwitchMode of
        FootSwitchF1: RESULT := ('Foot switch sends F1 message');
        FootSwitchDisabled: RESULT := ('Foot switch disabled');
        FootSwitchLastCQFreq: RESULT := ('Go to last CQ frequency');
        FootSwitchNextBandMap: RESULT := ('Next non dupe band/mode entry in bandmap');
        FootSwitchNextDisplayedBandMap: RESULT := ('Next non dupe displayed band map entry');
        FootSwitchNextMultBandMap: RESULT := ('Next mult band/mode entry in bandmap');
        FootSwitchNextMultDisplayedBandMap: RESULT := ('Next multiplier displayed band map');
        FootSwitchUpdateBandMapBlinkingCall: RESULT := ('Update blinking band map call if one');
        FootSwitchDupecheck: RESULT := ('Do Alt-D dupe check command');
        Normal: RESULT := ('Foot switch keys active radio PTT');
        QSONormal: RESULT := ('Acts like pressing ENTER key');
        QSOQuick: RESULT := ('Like ENTER key except for Quick QSL msg');
        FootSwitchControlEnter: RESULT := ('Execute Control-Enter function (no cw)');
        StartSending: RESULT := ('Start sending call in call window on CW');
        SwapRadio: RESULT := ('Swaps radios (like Alt-R command)');
        CWGrant: RESULT := ('CW Grant mode - no CW until pressed');
      end;

    FPR: RESULT := ('Rate in ms the radio is polled for freq');

    FME:
      if FrequencyMemoryEnable then
        RESULT := ('Remember freqs for each band/mode')
      else
        RESULT := ('Do not remember freqs from band/mode');

    FCR:
      if Radio1.FT1000MPCWReverse then
        RESULT := ('FT1000MP / FT920 use CW Reverse mode')
      else
        RESULT := ('FT1000MP / FT920 use normal CW mode');

    GMC:
      if GridMapCenter = '' then
        RESULT := ('No grid map defined')
      else
        RESULT := ('Grid map center location');

    HFE:
      if HFBandEnable then
        RESULT := ('HF Bands enabled.')
      else
        RESULT := ('HF Bands no enabled.');

    HDP: case HourDisplay of
        ThisHour: RESULT := ('Show # of QSOs in this hour');
        LastSixtyMins: RESULT := ('Show # of QSOs in last 60 minutes');
      end;

    //    HOF: RESULT := ('Offset from computer time to UTC time');

    //    ICP: Result := ('Command delay in ms (default = 300)');

    ITE:
      if IncrementTimeEnable then
        RESULT := ('Alt1 to Alt0 keys enabled to bump time')
      else
        RESULT := ('Alt1 to Alt0 keys disabled to bump time');

    IFE:
      if IntercomFileenable then
        RESULT := ('Inter-station messages to INTERCOM.TXT')
      else
        RESULT := ('INTERCOM.TXT file disabled');

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
        RESULT := ('Keystrokes overwrite initial exchange')
      else
        RESULT := ('Keystrokes add to initial exchange');

    IEC: case InitialExchangeCursorPos of
        AtStart: RESULT := ('Cursor at start of initial exchange');
        AtEnd: RESULT := ('Cursor at end of initial exhange');
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
        RESULT := ('Numeric keypad sends CQ Ctrl-F1 to F10')
      else
        RESULT := ('Normal function for keypad (no cw)');

    LDZ:
      if LeadingZeros > 0 then
        RESULT := ('Number leading zeros in serial number')
      else
        RESULT := ('Leading zeros not sent with serial #s');

    LZC: RESULT := ('Used for serial number leading zeros');

    LCI:
      if LeaveCursorInCallWindow then
        RESULT := ('Cursor stays in call window during QSO')
      else
        RESULT := ('Cursor moves to exchange window for ex');

    LFE:
      if LogFrequencyEnable then
        RESULT := 'Freq in log instead of QSO number'
      else
        RESULT := 'QSO number in log - not freq';

    LRS: RESULT := ('Default SSB report shown in logsheet');

    LDQ:
      if LiteralDomesticQTH then
        RESULT := ('Domestic QTHs shown as entered')
      else
        RESULT := ('Domestic QTHs shown as in .DOM file');

    LRT: RESULT := ('Default CW report shown in logsheet');

    LSE:
      if LogWithSingleEnter then
        RESULT := ('Log QSOs with first ENTER')
      else
        RESULT := ('Log QSOs with second ENTER');

    LFR:
      if LookForRSTSent then
        RESULT := ('Look for S579 or S57 in exchange')
      else
        RESULT := ('Do not look for sent RS(T) in exchange');

    MSE:
      if MessageEnable then
        RESULT := ('Alt-P O messages enabled')
      else
        RESULT := ('Automatic Alt-P O messages disabled');

    MCF:
      if tMissingCallsignsFileEnable then
        RESULT := ('Unrecorded callsigns to MISSINGCALLSIGNS.TXT')
      else
        RESULT := ('MISSINGCALLSIGNS.TXT file disabled');

    {      MEN:
             if MouseEnable then
                Result := ('Mouse activity enabled')
             else
                Result := ('Mouse disabled');
    }
    MRM: RESULT := ('Threshold # bands for Control-O report');

    MIM: RESULT := ('Multi status msg - $=Freq/S&P %=Rate ');

    //    MMP:      Result := 'Full file name of MMTTY.exe';

    MMO:
      if MultiMultsOnly then
        RESULT := ('Only mult QSOs are passed to other stns')
      else
        RESULT := ('All QSOs are passed to other stns');

    MRT: RESULT := ('Multi network retry time in seconds');

    MUM:
      if MultiUpdateMultDisplay then
        RESULT := ('Rem mult display updated from net QSOs')
      else
        RESULT := ('Mults updated when QSO made or band chg');

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
    MCN: RESULT := ('Continent set by MY CALL in cfg file');
    MCU: RESULT := ('Country as set by MY CALL');
    MFD: RESULT := ('Class for ARRL Field Day');
    MGR: RESULT := ('Reference grid used for beam headings');
    MIO: RESULT := ('IOTA Reference Designator');
    MZN: RESULT := ('Set by MY CALL / MY ZONE in cfg file');

    NFE:
      if NameFlagEnable then
        RESULT := ('Asterisk shows calls with known name')
      else
        RESULT := ('No asterisk to flag known names');

    NLQ:
      if NoLog then
        RESULT := ('No QSOs can be logged on this computer')
      else
        RESULT := ('QSOs may be logged on this computer');

    NPP:
      if NoPollDuringPTT then
        RESULT := ('Interfaced radio not polled when xmit')
      else
        RESULT := ('Interfaced radio polled during xmit');

    PAL:
      if PacketAddLF then
        RESULT := ('Line feed added after return for packet')
      else
        RESULT := ('No line feeds added to packet returns');

    PAR:
      if PacketAutoCR then
        RESULT := ('Return sent when exiting Control-B')
      else
        RESULT := ('No return sent when exiting Control-B');

    PBS:
      if Packet.PacketBandSpots then
        RESULT := ('Packet spots shown only for active band')
      else
        RESULT := ('All spots shown regardless of band');

    PBP:
      if Packet.PacketBeep then
        RESULT := ('Beep when packet spots come in')
      else
        RESULT := ('Display incoming spots without beep');

    PLF:
      if Packet.PacketLogFileName = '' then
        RESULT := ('Packet log file disabled')
      else
        RESULT := ('Packet log file enabled to file shown');

    PRM:
      if PacketReturnPerMinute = 0 then
        RESULT := 'Normal packet operation'
      else
      begin
        asm
        push PacketReturnPerMinute
        end;
        wsprintf(wsprintfBuffer, 'RETURN sent every %u minutes');
        asm add esp,12
        end;
        RESULT := wsprintfBuffer;
      end;
    psc: RESULT := 'Comment sent with each packet spot'; //KK1L: 6.71 Implimented what I started in 6.68

    PKD:
      if PacketSpotDisable then
        RESULT := ('Making spots with ` key is disabled')
      else
        RESULT := ('Making spots with ` key is enabled.');

    PSE:
      if PacketSpotEditEnable then
        RESULT := ('Outgoing spots shown for edit')
      else
        RESULT := ('Outgoing spots not shown for edit');

    SPO:
      if PacketSpotPrefixOnly then
        RESULT := ('Outgoing spot prefix only')
      else
        RESULT := ('Outgoing spot is full call');

    PSP:
      if Packet.PacketSpots = AllSpots then
        RESULT := ('All spots from packet are shown')
      else
        RESULT := ('Only multiplier spots are shown');

    PBE:
      if PaddleBug then
        RESULT := ('Dah contact of paddle = bug')
      else
        RESULT := ('Normal keyer dahs');

    PHC: RESULT := ('Number dit times before PTT drops out');

    PMT: RESULT := ('Monitor tone for CW sent with paddle');

    PSD:
      if PaddleSpeed = 0 then
        RESULT := ('Paddle speed same as computer speed')
      else
        RESULT := ('Speed to send paddle CW with');

    PCE:
      if PartialCallEnable then
        RESULT := ('Partial calls will be shown')
      else
        RESULT := ('Partial calls will not be shown');
    {
        PCL:
          if PartialCallLoadLogEnable then
            RESULT := ('If new LOG.TRW, partial calls loaded')
          else
            RESULT := ('Partials not loaded from new LOG.TRW');
    }
    PCM:
      if PartialCallMultsEnable then
        RESULT := ('Mult info shown for partial calls')
      else
        RESULT := ('Mult info not shown for partial calls');

    PCA:
      if PossibleCallEnable then
        RESULT := ('Possible (unique-1) calls will be shown')
      else
        RESULT := ('Possible (unique-1) calls not shown');

    PCN: case CD.PossibleCallAction of
        AnyCall: RESULT := ('Show all possible calls');
        OnlyCallsWithNames: RESULT := ('Only show possible calls with names');
        LogOnly: RESULT := ('Only show possible calls from log');
      end;

    //W_L_I    PEN:      if PrinterEnabled then        Result:=('Each QSO off editable window is printed')      else        Result:=('Real time printing is disabled');
    PBL:
      if PTTBlocking then
        RESULT := ('Network TX lockout is enabled')
      else
        RESULT := ('Network TX lockout is disabled');

    PTT:
      if PTTEnable then
        RESULT := ('PTT control signal is enabled')
      else
        RESULT := ('PTT control signal is disabled (QSK)');

    //      PTD: Result := ('PTT delay before CW sent (* 1.7 ms)');
    PTD: RESULT := ('PTT delay before CW sent (* 1.0 ms)');

    PVC:
      if tPTTViaCommand then
        RESULT := ('PTT control via CAT commands enabled')
      else
        RESULT := ('PTT control via CAT commands diseabled');

    QMD: case ParameterOkayMode of
        Standard: RESULT := ('Needs correct info to QSL & log');
        QSLButDoNotLog: RESULT := ('Needs correct info to log, not to QSL');
        QSLAndLog: RESULT := ('No syntax checking of exchange');
      end;

    QNB:
      if QSONumberByBand then
        RESULT := ('Separate QSO numbers sent by band')
      else
        RESULT := ('Total QSOs used for QSO number');

    QES:
      if QTCExtraSpace then
        RESULT := ('Add extra spaces when sending QTCs')
      else
        RESULT := ('No extra spaces when sending QTCs');

    QRS:
      if QTCQRS then
        RESULT := ('QRS when sending QTCs')
      else
        RESULT := ('No QRS when sending QTCs');

    QSX:
      if QSXEnable then
        RESULT := ('QSX info from packet spots enabled')
      else
        RESULT := ('QSX info from packet spots disabled');

    QMC: RESULT := ('Keyboard character used for ?');

    //    R1CP: Result := ('Time between commands to radio 1');

    R1FA:
      if Radio1.FrequencyAdder <> 0 then
        RESULT := ('Amount to add to radio 1 frequency')
      else
        RESULT := ('No adder to radio 1 frequency');

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
        RESULT := ('Amount to add to radio 1 frequency')
      else
        RESULT := ('No adder to radio 2 frequency');

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
        RESULT := ('Auto CQ picks F1-F4 at random')
      else
        RESULT := ('Auto CQ works normally');

    RDS: case RateDisplay of
        QSOs: RESULT := ('Rate displays show QSOs');
        Points: RESULT := ('Rate displays show QSO points');
        BandQSOs: RESULT := ('Rate for active band only');
      end;

    RMD: case RemainingMultDisplayMode of
        NoRemainingMults: RESULT := ('No remaining mult display');
        Erase: RESULT := ('Remaining mult erased when worked');
        HiLight: RESULT := ('Unworked remaining mults highlighted');
      end;

    SHE:
      if SayHiEnable then
        RESULT := ('Name database available to send names')
      else
        RESULT := ('Name sending is disabled');

    SHC: RESULT := ('Rate above which name calling will stop');

    SCS:
      if CD.CountryString = '' then
        RESULT := ('All SCP calls displayed')
      else
        RESULT := ('Countries that SCP calls displayed');

    SML:
      if SCPMinimumLetters = 0 then
        RESULT := ('Auto Super Check Partial disabled')
      else
        RESULT := ('Minimum characters for Auto SCP');

    SAD:
      if SendAltDSpotsToPacket then
        RESULT := ('Alt-D entries sent to packet')
      else
        RESULT := ('Alt-D entries not sent to packet');

    SCF:
      if SendCompleteFourLetterCall then
        RESULT := ('Send all of 4 letter corrected callsign')
      else
        RESULT := ('Send prefix/suffix of 4 letter calls');

    SSN:
      if StartSendingNowKey <> ' ' then
      begin
        asm
        movzx eax, StartSendingNowKey
        push eax
        end;
        wsprintf(wsprintfBuffer, 'Use a %c key for the sending beginning');
        asm add esp,12
        end;
        RESULT := wsprintfBuffer;
      end
      else
        RESULT := ('Use a SPACE key for the sending beginning');

    SPS:
      if StereoPinState then
        RESULT := ('Stereo Control Pin high')
      else
        RESULT := ('Stereo Control Pin low');

    SQI:
      if SendQSOImmediately then
        RESULT := ('QSO sent to Multi port when logged')
      else
        RESULT := ('QSO sent when scrolled off edit window');

    SIA: RESULT := '';
    SPA: RESULT := '';
    SEP: RESULT := '';
    SKE:
      if ShiftKeyEnable then
        RESULT := ('Shift keys enabled for RIT and S&P QSY')
      else
        RESULT := ('Shift keys disabled for RIT and S&P QSY');

    SIN:
      if ShortIntegers then
        RESULT := ('Short integers used in QSO numbers')
      else
        RESULT := ('No short integers used in QSO numbers');
    SLG:
      if tLogLogGridlines then
        RESULT := ('Add lines that separate the items in the log window')
      else
        RESULT := ('TR Log style of the log window');

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
        RESULT := 'Swap radio command (Alt-R) disabled'
      else
        RESULT := 'Swap radio command (Alt-R) enabled';

    SAB:
      if SkipActiveBand then
        RESULT := ('Alt-B skips active band of other rig')
      else
        RESULT := ('Alt-B doesn''t skip other active band');

    SMC: RESULT := ('Keyboard character used for / character');

    SBD:
      if SpaceBarDupeCheckEnable then
        RESULT := ('Space does dupe check if call entered')
      else
        RESULT := ('Space always sends call & puts in S&P');

    SQR:
      if SprintQSYRule then
        RESULT := ('After S&P QSO, goes into CQ mode')
      else
        RESULT := ('Stay in S&P mode after S&P QSO');

    SRP:
      if SwapPacketSpotRadios then
        RESULT := ('Radio 1 is left of radio 2')
      else
        RESULT := ('Radio 1 is right of radio 2');

    SWP:
      if SwapPaddles then
        RESULT := ('Swap dit and dah paddle connections')
      else
        RESULT := ('Normal dit and dah paddle connections');

    SWR:
      if SwapRadioRelaySense then
        RESULT := ('Radio One = 0 volts on relay output')
      else
        RESULT := ('Radio One = 5 volts on relay output');
    {
        TAB: case TabMode of
            NormalTabMode: RESULT := ('When edit, tab moves to next field');
            ControlFTabMode: RESULT := ('When edit, tab moves to next word');
          end;
    }
    TMR: case TenMinuteRule of
        NoTenMinuteRule: RESULT := ('No ten minute display');
        TimeOfFirstQSO: RESULT := ('Show time since first QSO on band/mode');
      end;

    TOT: RESULT := ('Total off time taken so far');

    TDE:
      if TuneDupeCheckEnable then
        RESULT := ('Tuning enables 2nd radio dupe check')
      else
        RESULT := ('Only ALT-D enables 2nd radio dupe check');

    TWD:
      if TuneWithDits then
        RESULT := ('Left Control & Shift keys tune w/dits')
      else
        RESULT := ('Left Control & Shift keys key rig');

    TRM:
      if TwoRadioMode {TwoRadioState <> TwoRadiosDisabled} then
        RESULT := ('Special two radio mode is enabled')
      else
        RESULT := ('Special two radio mode is disabled');

    URF:
      if UpdateRestartFileEnable then
        RESULT := ('RESTART.BIN updated after each QSO')
      else
        RESULT := ('RESTART.BIN updated when exiting LOG');

    {      UBC:
             if UseBIOSKeyCalls then
                Result := ('Use BIOS for keys - no F11 or F12')
             else
                Result := ('Bypass BIOS - enable F11 and F12 keys');
    }
    URS:
      if tUseRecordedSigns then
        RESULT := ('Play recorded letters/ number files')
      else
        RESULT := ('Use own voice to send callsigns and serial exchange nubers');

    UIS: case UserInfoShown of
        NoUserInfo: RESULT := 'No user data shown from TRMASTER';

        NameInfo: RESULT := ('Name from TRMASTER');
        QTHInfo: RESULT := ('QTH from TRMASTER');
        CheckSectionInfo: RESULT := ('Check and ARRL section from TRMASTER');
        SectionInfo: RESULT := ('ARRL section from TRMASTER');
        OldCallInfo: RESULT := ('Previous callsign from TRMASTER');
        FocInfo: RESULT := ('FOC number from TRMASTER');
        GridInfo: RESULT := ('Grid square from TRMASTER');
        CQZoneInfo: RESULT := ('CQ zone from TRMASTER or CTY.DAT');
        ITUZoneInfo: RESULT := ('ITU zone from TRMASTER or CTY.DAT');
        User1Info..User5Info:
          begin
            I := Cardinal(UserInfoShown) - 9;
            asm
                  push i
            end;
            wsprintf(wsprintfBuffer, 'Data from TRMASTER USER %u shown');
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
       }CustomInfo: RESULT := ('Use CUSTOM USER STRING');
      end;

    VER: RESULT := ('Program version (can''t be changed)');

    {      VDE:
             if VGADisplayEnable then
                Result := ('VGA mode enabled at program start')
             else
                Result := ('VGA mode disabled at program start');
    }
    VBE:
      if VHFBandsEnabled then
        RESULT := ('6 and 2 meters are enabled')
      else
        RESULT := ('VHF bands skipped with Alt-B or Alt-V');

    {      VDS:
             if VisibleDupesheetEnable then
                Result := ('Visible dupesheet is displayed')
             else
                Result := ('Visible dupesheet is not displayed');
    }
    WFS:
      if WaitForStrength then
        RESULT := ('If [ in CW message - wait for input')
      else
        RESULT := ('Assume Strength = 9 if CW done with [');

    WUT:
      if WakeUpTimeOut = 0 then
        RESULT := ('Wake up time out is disabled')
      else
        RESULT := ('# minutes without a QSO causing alarm');

    WBE:
      if WARCBandsEnabled then
        RESULT := ('WARC bands are enabled')
      else
        RESULT := ('WARC bands skipped with Alt-B or Alt-V');

    WEI: RESULT := ('Keying weight');

    WCP:
      if WildCardPartials then
        RESULT := ('Calls with partial anywhere are shown')
      else
        RESULT := ('Only calls starting with partial shown');

  end;

  if Active then
  begin
      //W_L_I         TextColor (ActiveColor);
      //W_L_I         TextBackground (ActiveBackground);
  end;

end;

begin

end.

