unit LogStuff;

{ This unit has a bunch of subroutines that are generic for the logging
  program.  They are stuck here because they can stand alone, or need
  very little VAR interfacing.  This is so they will be out of the way
  and be common to all programs.                                      }

{$O+}
{$F+}
{$IMPORTEDDATA OFF}
interface

uses {Dos, Printer,} Tree,
  uCommctrl,
  WinSock2,
  TF,
  VC,
  Country9,
  ZoneCont,
  LogSCP, {Crt,}
  LogWind,
  LogCW,
  LogDupe,
  LogGrid,
//  Help,
  LogK1EA,
  LOGDVP,
  LogDom, {SlowTree,}
  LogNet,
  LogRadio,
  Other,
  Messages,
  Windows
  ;

const
  SSPrec                                : set of Char = ['A', 'B', 'Q', 'U', 'M', 'S'];

  { Control Byte Constants for Multi-Multi communications }

  MultiMessageBufferSize                = 32;

  MultiTalkMessage                      = 1; { TR6.75 - Supported by K1EANetwork }
  MultiPacketReceivedSpot               = 2; { No longer used.  Uses 4 all the time }
  MultiPacketMessageToSend              = 3;
  MultiPacketReceivedMessage            = 4;
  MultiQSOData                          = 5; { TR6.75 - Supported by CT Network }
  MultiBandMapMessage                   = 6; { TR6.76 - Supported by CT Network }
  MultiTimeMessage                      = 7; { TR6.75 - Reception only from CT Network }
  MultiInformationMessage               = 8;
  MultiConfigurationMessage             = 9; { Not supported on CT Network }

  DefaultTimeToLive                     = 30;
  LookForDupes                          = True;
  DoNotLookForDupes                     = not LookForDupes;

  ProcessedMultiMessageBufferLength     = 256;

  {
  Очки за связи начисляются по таблице (см. "комментарий").
  За каждую новую зону на каждом диапазоне, независимо от периода, начисляется 50 очков.
  За каждую новую область, независимо от диапазона и периода, начисляется 50 очков.

  Зоны 1-я 2-я 3-я 4-я 5-я 6-я 7-я
  --------------------------------
  1-я  11  12  13  14  16  20  25
  2-я  12  11  12  13  15  19  23
  3-я  13  12  11  12  14  18  21
  4-я  14  13  12  11  12  15  18
  5-я  16  15  14  12  11  12  14
  6-я  20  19  18  15  12  11  12
  7-я  25  23  21  18  14  12  11
  }

  ChampionshipRFPointsArray             : array[1..49] of Byte =
    (

    11, 12, 13, 14, 16, 20, 25,
    12, 11, 12, 13, 15, 19, 23,
    13, 12, 11, 12, 14, 18, 21,
    14, 13, 12, 11, 12, 15, 18,
    16, 15, 14, 12, 11, 12, 14,
    20, 19, 18, 15, 12, 11, 12,
    25, 23, 21, 18, 14, 12, 11

    );

  ZeroZuluOffsetCQZoneArray             : array[1..39] of Byte =
    (
    14,
    19,
    16,
    18,
    19,
    17,
    18,
    19,
    18,
    19,
    21,
    19,
    20,
    0,
    1,
    2,
    4,
    6,
    9,
    2,
    4,
    5,
    7,
    8,
    9,
    7,
    8,
    7,
    8,
    10,
    14,
    12,
    0,
    2,
    0,
    0,
    2,
    1,
    3

    );

  ZeroZuluOffsetITUZoneArray            : array[1..66] of Byte =
    (
    14,
    16,
    17,
    18,
    19,
    16,
    18,
    19,
    19,
    17,

    19,
    19,
    21,
    19,
    21,
    20,
    23,
    1,
    2,
    4,

    4,
    5,
    6,
    7,
    8,
    9,
    1,
    2,
    3,
    4,

    5,
    6,
    7,
    8,
    9,
    1,
    1,
    3,
    3,
    4,

    5,
    5,
    6,
    8,
    9,
    0,
    1,
    2,
    6,
    8,

    9,
    0,
    3,
    7,
    9,
    12,
    2,
    8,
    10,
    11,

    13,
    13,
    13,
    10,
    10,
    22

    );
  {
  CQ-M положение 2007 года
  Список федеральных округов:
  Дальневосточный федеральный округ: R0 C, D, F, I, J, K, L, Q, X, Z.
  Приволжский федеральный округ: R3T; R4 C, F, H, L, N, P, S, U, W,Y; R9 F, S, W.
  Северо-Западный федеральный округ: R1 A, C, N, O, P, Q, T, W, Z; R2F; R9X.
  Сибирский федеральный округ: R8 V, T; R9 H, M, O, U, Y, Z; R0 A, B, H, O, S, U, W, Y.
  Уральский федеральный округ: R9 A, C, J, L, K, Q.
  Центральный федеральный округ: R3 A, D, E, G, I, J, L, M, N, P, Q, R, S, U, V, W, X, Y, Z.
  Южный федеральный округ: R4A; R6 A, E, H, I, J, L, P, Q, U, W, X, Y.
  }

type

  FederalOkrugs =
    (
    UnKnownOkrug,
    DalneVostochnyiy,
    Privolzhskiy,
    SeveroZapadniy,
    Sibirskiy,
    Uralskiy,
    Centralniy,
    Yuzhniy
    );

  SSExchangeType = record
    Number: string[4];
    Check: string[2];
    Section: Str10;
    Prec: Char;
  end;

  RememberRecord = record
    Frequency: LONGINT;
    Band: BandType;
    Mode: ModeType;
  end;

  RememberRadioType = array[RadioOne..RadioTwo] of RememberRecord;

  HelloRecPtr = ^HelloRec;

  HelloRec = record
    ID: string[6];
    Greeting: string[6];
    NextRecord: HelloRecPtr;
  end;

  EntryArray = array[1..10] of Str20;

  QuickQSLKeyType = (NoQuickQSLKey,
    QuickKey1,
    QuickKey2);

  ParameterOkayModeType = (
    NoParameterOkayMode,
    Standard,
    QSLButDoNotLog,
    QSLAndLog);

  EntryName = (Unknown,
    Number,
    Precedence,
    Call,
    Check,
    Section,
    NumberPrecedence,
    CheckSection,
    NumberPrecedenceCheckSection);

  KeyHistoryRecord = record
    Key: Char;
    Time: Cardinal {TimeRecord};
  end;

  DirectionType = (DirectionDown, DirectionUp);

  TwoRadioAction = (CallPutUp,
    SpaceBarPressed,
    F1Pressed,
    F2Pressed,
    FootSwitchWasPressed,
    ReturnPressed,
    EscapePressed,
    ContactDone);

  DualingCQStates = (NoDualingCQs,
    DualGettingExchange,
    DualSendingCQ,
    DualSendingExchange,
    DualSendingQSL,
    SendingDupeMessage,
    WaitingForCallsignInput);

  DupeCheckSoundType =
    (
    DupeCheckNoSound,
    DupeCheckBeepIfDupe,
    DupeCheckGratsIfMult
    );

  ProcessedMultiMessageRecord = record
    Source: Byte;
    Serial: Byte;
    Check: integer;
  end;

  ProcessedMultiMessageBufferType = array[0..ProcessedMultiMessageBufferLength - 1] of
    ProcessedMultiMessageRecord;

  MultiMessageMemoryRecord = record
    Message: string[100];
    TimeMark: Cardinal {TimeRecord};
    RetryCount: Byte;
    QSL: boolean;
    Warnings: Byte;
  end;

  MultiMessageListArrayType = array[0..MultiMessageBufferSize - 1] of MultiMessageMemoryRecord;
  MultiMessageListPointer = ^MultiMessageListArrayType;

const
  DupeCheckSoundTypeSA                  : array[DupeCheckSoundType] of PChar =
    (
    'NONE',
    'DUPE BEEP',
    'MULT FANFARE'
    );

  ParameterOkayModeTypeStringArray      : array[ParameterOkayModeType] of PChar = (
    'NONE',
    'STANDARD',
    'QSL BUT DO NOT LOG',
    'QSL AND LOG'
    );

var
  SSEx                                  : SSExchangeType;

  _showstarttime                        : boolean = False;
  _networktest                          : boolean = False;
  //  _showDevCaps                     : boolean = False;
    //  _KeyboardDebug                        : boolean = False;

  AddedNoteString                       : string[100] = '';
  AllCWMessagesChainable                : boolean = False;
  AlwaysCallBlindCQ                     : boolean = False;
  //  AskIfContestOver                      : boolean = True;
  AutoAltDWindowString                  : Str20;
  AutoCallTerminate                     : boolean = False;
  AutoAltDEnable                        : boolean;
  AutoDisplayDupeQSO                    : boolean;
  AutoQSLCount                          : Byte = 0;
  AutoQSLInterval                       : integer = 0;
  AutoQSONumberDecrement                : boolean = False;
  AutoSAPEnable                         : boolean = False;

  BandMapCallWindowEnable               : boolean = True;
  BandMapInfoCall                       : CallString = '';
  BeepEvery10QSOs                       : boolean = False;
  BeSilent                              : boolean = False;

  CallAlreadySent                       : boolean = False;
  CallWindowString                      : CallString {string};
  tCallWindowStringIsDupe               : boolean;
  CallWindowEmpty                       : boolean = True;
  CallsignIsPasted                      : boolean = False;
  CallsignICameBackTo                   : CallString;
  CheckLogFileSize                      : boolean = False;
  ColumnDupeSheetEnable                 : boolean = False;
  ComputerID                            : Char = CHR(0);
  ComputerName                          : Str10 = 'ChangeMe';
  ControlBreakStatus                    : boolean;
  CountryInformationFile                : ShortString;

  Debug                                 : boolean;
  DEEnable                              : boolean = True;
  DefaultRST                            : Word = 0 {Str10};
  //  DoingRescore                     : boolean; {KK1L: 6.71}
  DualingCQState                        : DualingCQStates = NoDualingCQs;
  DupeCheckSound                        : DupeCheckSoundType = DupeCheckBeepIfDupe;
  DupeInfoCall                          : CallString = '';
  DupeInfoCallPrompt                    : CallString; {KK1L: 6.73}
  DupeSheetFileEnable                   : boolean;
  DVKPlaying                            : boolean = False;
  DVKStartTime                          : Cardinal {TimeRecord};

  EscapeDeletedCallEntry                : CallString {Str20} = '';
  EscapeDeletedExchangeEntry            : Str40 = '';
  EscapeExitsSearchAndPounce            : boolean = True;
  ExchangeHasBeenSent                   : boolean = False;
  ExchangeErrorMessage                  : PChar = nil;
  ExchangeMemoryFileEnable              : boolean;
  ExchangeWindowString                  : Str30; //CallString {ShortString} {Str80} = '';

  FakePacket                            : boolean;
  FakeBandMap                           : boolean;
  FirstHelloRecord                      : HelloRecPtr = nil;
  FirstMultiMessage                     : integer = 0;
  FloppyFileSaveFrequency               : integer = 0;
//  FloppyFileSaveName                    : ShortString = 'LOGBACK.TRW';
  ForcedEntry                           : boolean = False; {KK1L: 6.70 switch used in JCTRL2 to add comments to LOGCFG}

  GridMapCenter                         : GridString = '';

  InactiveRigCallingCQ                  : boolean = False;
  InitialExchangePutUp                  : boolean;
  InitialExchangeOverwrite              : boolean = False; {KK1L: 6.70}
  InsertMode                            : boolean = True;
  IntercomFileenable                    : boolean = False;
  //  IntercomFileOpen                 : boolean;
  //  IntercomFileWrite                : Text;

  KeyHistory                            : KeyHistoryRecord;
  KeypadCWMemories                      : boolean = False;

  //   LastDeletedLogEntry             : Str160;
  tLastLogEntryIsDeleted                : boolean = False;
  //  LastDeletedContestExchange       : ContestExchange;
  LastDisplayedBreakTime                : integer = -1;
  LastHelloRecord                       : HelloRecPtr = nil;
  LastMultiMessage                      : integer = 0;
  LastMultiInfoMessageSum               : array[BandType, ModeType] of Byte;
  //  LastQSOLogged                    : ContestExchange;

  LeaveCursorInCallWindow               : boolean = False;
  LogBadQSOString                       : Str80 = '';
  LogFileRead                           : Text;
  LogFrequencyEnable                    : boolean = False;
  LogRSSent                             : Word = 59;
  LogRSTSent                            : Word = 599;
  LogWithSingleEnter                    : boolean = False;
  LookForRSTSent                        : boolean = False;
  LookingForCQExchange                  : boolean = False;

  MessageEnable                         : boolean = True;
  //   ModemPortBaudRate               : integer;
  MultiInfoMessageTimeout               : TimeRecord;
  MultiMultsOnly                        : boolean = False;
  MultiplierFileEnable                  : boolean;
  //  MultiMessageBuffer               : array[1..5] of Str80;
  MultiRememberBuffer                   : MultiMessageListPointer;
  MultiRetryTime                        : integer = 30;
  MultiSerialNumber                     : integer = 0;
  MultiUpdateMultDisplay                : boolean = True;
  MultReportMinimumBands                : integer = 4;
  MyIOTA                                : Str20;

  NameCallsignPutUp                     : CallString = '';
  NameFlagEnable                        : boolean = True;
  NoLog                                 : boolean = False;

  OldCWTone                             : integer;

  PacketAutoCR                          : boolean = False;
  PacketFile                            : boolean;
  PacketFileRead                        : file;
  PacketSpotDisable                     : boolean = False;
  PacketSpotEditEnable                  : boolean = False;
  ParameterOkayMode                     : ParameterOkayModeType = Standard;
  PartialCallFileEnable                 : boolean;
  PartialCallMultsEnable                : boolean = True;
  PossibleCallAcceptKey                 : Char = ';';
  PossibleCallEnable                    : boolean = True;
  PossibleCallLeftKey                   : Char = ',';
  PossibleCallRightKey                  : Char = '.';
  PreviousQSOReceivedData               : ContestExchange;
  //W_L_I  PrinterEnabled: boolean;
  ProcessedMultiMessages                : ProcessedMultiMessageBufferType;

  ProcessedMultiMessagesStart           : integer = 0;
  ProcessedMultiMessagesEnd             : integer = 0;

  QSONumberByBand                       : boolean = False;
  QSXEnable                             : boolean = True;

  QuickQSL                              : QuickQSLKeyType; { to indicate a quick QSL is desired }
  QuickQSLKey1                          : Char = '\';
  QuickQSLKey2                          : Char = '=';

  RadioSetFreq                          : LONGINT = 0;
  RandomCQMode                          : boolean = False;
  RandomNameEnable                      : boolean = False;
  ReadInCallsign                        : CallString;
  ReadInLogComputerID                   : Char;
//  ReadInLog                        : boolean;
  ReadInLogBand                         : BandType;
  ReadInLogDateString                   : Str10;
  ReadInLogExchange                     : ShortString {Str40};
  ReadInLogFileName                     : Str40;
  ReadInLogFileOpen                     : boolean = False;
  ReadInLogFileRead                     : Text;
  ReadInLogMode                         : ModeType;
  ReadInLogRST                          : Str10;
  ReadinLogTimeString                   : Str10;

  ReceivedData                          : ContestExchange;
  Remember                              : RememberRadioType;
  RememberBand                          : BandType;
  RememberMode                          : ModeType;
  {
    RemoteTerminalBand                    : BandType;
    RemoteTerminalMode                    : ModeType;
    RemoteTerminalPort                    : PortType = NoPort;
  }

  SayHiRateCutOff                       : integer = 200;
  SendCompleteFourLetterCall            : boolean = False;
  SendQSOImmediately                    : boolean = True;
  SeventyThreeMessageSent               : boolean = False;
  SCPMinimumLetters                     : integer = 0;

  SendExchangeKeyWhenCWHasStopped       : Char = NullKey;

  Sheet                                 : DupeAndMultSheet = (tAutoReset: True);
  ShortIntegers                         : boolean = False;
  ShowQSOStatusCall                     : CallString;
  //  ShowSearchAndPounce                   : boolean = False;
  SingleRadioMode                       : boolean = False;
  SkipActiveBand                        : boolean = False;
  SpaceBarDupeCheckEnable               : boolean = True;
  StartSendingNowKey                    : Char = '''';

  StationInformationCall                : CallString = '';
  SwitchRadioKey                        : Char;

  TailEnding                            : boolean = False;
  TailEndKey                            : Char = ']';
  TailEndCallString                     : CallString;

  TotalDomesticContacts                 : integer;
  TotalDXContacts                       : integer;
  TotalIntermediateContacts             : integer;

  UpdateRestartFileEnable               : boolean = False;

  WaitForStrength                       : boolean = True;

  WindowDupeCheckCall                   : CallString = '';

  tPreviousDupeQSOsShowed               : boolean = False;
  tPreviousDupeQSOsWndHandle            : HWND;
  //const  tr4w_StartSendingNowKey                    : ;

procedure AgeReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
procedure AgeReceivedHeader(var LogString: Str80; var Underline: Str80);

procedure BandChange(var ActiveBand: BandType; Direction: DirectionType);

procedure CalculateQSOPoints(var RXData: ContestExchange);
procedure ChapterReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
procedure ChapterReceivedHeader(var LogString: Str80; var Underline: Str80);

procedure CheckForLostMultiMessages;
procedure CreateAndSendCQMultiInfoMessage;
procedure CreateAndSendSAPMultiInfoMessage;

procedure DisplayGridSquareStatus(Call: CallString);
procedure DisplayMultiMessageBuffer;

function DVKRecentlyStarted(MaxElaspedSec100: LONGINT): boolean;
procedure DVKStamp;

function GetCorrectedCallFromExchangeString(var ExchangeString: ShortString {Str80}): Str80;
function GetMultiPortCommand: string;
function GetSentRSTFromExchangeString(var ExchangeString: ShortString {Str40}): Word;

procedure IncrementQTCCount(Call: CallString);

function KeyRecentlyPressed(Key: Char; MaxElaspedSec100: LONGINT): boolean;
procedure KeyStamp(Key: Char);

procedure LoadSpecialHelloFile;
function LogFileLooksOkay: boolean;
procedure LogStringToRXData(LogString: Str80; var RXData: ContestExchange);
function LooksLikeACallSign(Call: Str40): boolean;

function MakeLogString(RXData: ContestExchange): Str80;
function MarineOrAirMobileStation(Call: CallString): boolean; {KK1L: 6.68 Used in WRTC 2002}

procedure NextPage;
{
procedure NewBandMapEntry(Call: CallString;
  Frequency: LONGINT;
  QSXFrequency: LONGINT;
  Mode: ModeType;
  Dupe: boolean;
  Mult: boolean;
  MinutesLeft: integer;
  SendToMulti: boolean;
  Source: CallString);
}
function NumberQTCsThisStation(Call: CallString): integer;
procedure NameReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
procedure NameReceivedHeader(var LogString: Str80; var Underline: Str80);

procedure PassStationToCTNetwork;

procedure PrintLogHeader;

function ProcessExchange(ExchangeString: Str80; var RData: ContestExchange): boolean;
procedure ProcessPartialCallAndInitialExchange(RXData: ContestExchange);
function ProperSalutation(Call: CallString): Str80;

procedure PushMultiMessageBuffer(Message: Str80);

procedure RestoreRadioFrequency(Radio: RadioType);

procedure ReviewBackCopyFiles;
procedure RotorControl(Heading: integer);

procedure SaveLogFileToFloppy;
procedure SayHello(Call: CallString);
procedure SayName(Call: CallString);
procedure SendMultiInfoMessage(Band: BandType; Mode: ModeType; Message: Str80);
procedure SendMultiCommand(Source: Byte; Destination: Byte; ControlByte: Byte; Message: string);

procedure SendSalutation(Call: CallString);
procedure ShowName(Call: CallString);

procedure ShowPreviousDupeQSOs(Call: CallString;
  Band: BandType;
  Mode: ModeType);
procedure SlowDown;
procedure SpeedUp;

procedure StuffInit;

{ Header and Stamp routines - used when generating a log string }

procedure BandModeDateTimeNumberCallNameSentStamp(Exchange: ContestExchange; var LogString: Str80);
procedure BandModeDateTimeNumberCallNameSentHeader(var LogString: Str80; var Underline: Str80);
procedure CheckReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure CheckReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
procedure ClassReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure ClassReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

procedure KidsReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure KidsReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

procedure MultiplierHeader(var LogString: Str80; var Underline: Str80);
procedure MultiplierStamp(Exchange: ContestExchange; var LogString: Str80);
procedure PowerReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure PowerReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
procedure PrecedenceReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure PrecedenceReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
procedure QSONumberReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure QSONumberReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
procedure QSOPointHeader(var LogString: Str80; var Underline: Str80);
procedure QSOPointStamp(Exchange: ContestExchange; var LogString: Str80);
procedure QTHReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure QTHReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

procedure PostalCodeReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure PostalCodeReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

procedure RandomCharsSentAndReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure RandomCharsSentAndReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

procedure RSTReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure RSTReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
procedure RSTSentHeader(var LogString: Str80; var Underline: Str80);
procedure RSTSentStamp(Exchange: ContestExchange; var LogString: Str80);

procedure TenTenNumReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure TenTenNumReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

procedure ZoneReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure ZoneReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

procedure WriteLogEntry(Entry: Str80);

function GetFederalOkrug(OblastDigit, OblastChar: Char): FederalOkrugs;
function InSameFederalOkrug(HisCallsign: CallString): boolean;
function IsR150Country(OblastDigit, OblastChar: Char): boolean;

implementation

uses uNet,
  PostUnit,
  MainUnit;

procedure BandChange(var ActiveBand: BandType; Direction: DirectionType);

label NextBand;
const
  MAXBANDS                              = 21;
  BandChangeArray                       : array[1..MAXBANDS] of BandChangeType =
    (

    (bcBand: Band160; bcWARC: False; bcVHF: False),
    (bcBand: Band80; bcWARC: False; bcVHF: False),
    (bcBand: Band40; bcWARC: False; bcVHF: False),
    (bcBand: Band30; bcWARC: True; bcVHF: False),
    (bcBand: Band20; bcWARC: False; bcVHF: False),
    (bcBand: Band17; bcWARC: True; bcVHF: False),
    (bcBand: Band15; bcWARC: False; bcVHF: False),
    (bcBand: Band12; bcWARC: True; bcVHF: False),
    (bcBand: Band10; bcWARC: False; bcVHF: False),
    (bcBand: Band6; bcWARC: False; bcVHF: True),
    (bcBand: Band2; bcWARC: False; bcVHF: True),
    (bcBand: Band222; bcWARC: False; bcVHF: True),
    (bcBand: Band432; bcWARC: False; bcVHF: True),
    (bcBand: Band902; bcWARC: False; bcVHF: True),
    (bcBand: Band1296; bcWARC: False; bcVHF: True),
    (bcBand: Band2304; bcWARC: False; bcVHF: True),
    (bcBand: Band3456; bcWARC: False; bcVHF: True),
    (bcBand: Band5760; bcWARC: False; bcVHF: True),
    (bcBand: Band10G; bcWARC: False; bcVHF: True),
    (bcBand: Band24G; bcWARC: False; bcVHF: True),
    (bcBand: BandLight; bcWARC: False; bcVHF: True)
    );

var
  TempInteger                           : integer;
begin

  NextBand:

  for TempInteger := 1 to MAXBANDS do
    if BandChangeArray[TempInteger].bcBand = ActiveBand then Break;

  if ActiveBand = NoBand then TempInteger := MAXBANDS;

  if Direction = DirectionDown then
  begin
    TempInteger := TempInteger - 1;
    if TempInteger = 0 then TempInteger := MAXBANDS;
  end;

  if Direction = DirectionUp then
  begin
    TempInteger := TempInteger + 1;
    if TempInteger >= MAXBANDS + 1 then TempInteger := 1;
  end;

  ActiveBand := BandChangeArray[TempInteger].bcBand;
  if (not WARCBandsEnabled) and (BandChangeArray[TempInteger].bcWARC) then goto NextBand;
  if (not VHFBandsEnabled) and (BandChangeArray[TempInteger].bcVHF) then goto NextBand;

  if VHFBandsEnabled then
    if (not HFBandEnable) and (not BandChangeArray[TempInteger].bcVHF) then goto NextBand;

  if SkipActiveBand then
  begin
    if (Radio1.BandMemory = ActiveBand) then goto NextBand;
    if (Radio2.BandMemory = ActiveBand) then goto NextBand;
  end;

{
  if Direction = DirectionUp then
  begin
    case ActiveBand of
      Band160: ActiveBand := Band80;
      Band80: ActiveBand := Band40;

      Band40:
        if WARCBandsEnabled then
          ActiveBand := Band30
        else
          ActiveBand := Band20;

      Band30: ActiveBand := Band20;

      Band20:
        if WARCBandsEnabled then
          ActiveBand := Band17
        else
          ActiveBand := Band15;

      Band17: ActiveBand := Band15;

      Band15:
        if WARCBandsEnabled then
          ActiveBand := Band12
        else
          ActiveBand := Band10;

      Band12: ActiveBand := Band10;

      Band10:
        if VHFBandsEnabled then
          ActiveBand := Band6
        else
          ActiveBand := Band160;

      Band6: ActiveBand := Band2;
      Band2: ActiveBand := Band222;
      Band222: ActiveBand := Band432;
      Band432: ActiveBand := Band902;
      Band902: ActiveBand := Band1296;
      Band1296: ActiveBand := Band2304;
      Band2304: ActiveBand := Band3456;
      Band3456: ActiveBand := Band5760;
      Band5760: ActiveBand := Band10G;
      Band10G: ActiveBand := Band24G;
      Band24G: ActiveBand := BandLight;
      BandLight:
        if HFBandEnable then
          ActiveBand := Band160
        else
          ActiveBand := Band6;

    else ActiveBand := Band160;

      BandChange(ActiveBand, Direction);
    end;

    if SkipActiveBand and ((Radio1.BandMemory
//        BandMemory[RadioOne]
      = ActiveBand) or
      (Radio2.BandMemory
//          BandMemory[RadioTwo]
      = ActiveBand)) then
      BandChange(ActiveBand, Direction);
  end

  else
//      KK1l: 6.72 Note Direction = DirectionDown
  begin
    case ActiveBand of
      Band160:
        if VHFBandsEnabled then
          ActiveBand := BandLight
        else
          ActiveBand := Band10;

      Band80: ActiveBand := Band160;
      Band40: ActiveBand := Band80;

      Band30: ActiveBand := Band40;

      Band20:
        if WARCBandsEnabled then
          ActiveBand := Band30
        else
          ActiveBand := Band40;

      Band17: ActiveBand := Band20;

      Band15:
        if WARCBandsEnabled then
          ActiveBand := Band17
        else
          ActiveBand := Band20;

      Band12: ActiveBand := Band15;

      Band10:
        if WARCBandsEnabled then
          ActiveBand := Band12
        else
          ActiveBand := Band15;

      Band6:
        if HFBandEnable then
          ActiveBand := Band10
        else
          ActiveBand := BandLight;

      Band2: ActiveBand := Band6;
      Band222: ActiveBand := Band2;
      Band432: ActiveBand := Band222;
      Band902: ActiveBand := Band432;
      Band1296: ActiveBand := Band902;
      Band2304: ActiveBand := Band1296;
      Band3456: ActiveBand := Band2304;
      Band5760: ActiveBand := Band3456;
      Band10G: ActiveBand := Band5760;
      Band24G: ActiveBand := Band10G;
      BandLight: ActiveBand := Band24G;

    else ActiveBand := Band160;
    end;

    if SkipActiveBand and ((Radio1.BandMemory
//        BandMemory[RadioOne]
      = ActiveBand) or
      (Radio2.BandMemory
//          BandMemory[RadioTwo]
      = ActiveBand)) then
      BandChange(ActiveBand, Direction);
  end;
}
  SendStationStatus(sstBandModeFreq);

  //{WLI}
  DisplayBandMode(ActiveBand, ActiveMode, True);

  //ТО ЧТО НИЖЕ УБРАНО В ИСХОДНИКЕ
  {
      IF ((ActiveRadio = RadioOne) AND (Radio1Type <> NoInterfacedRadio)) OR
         ((ActiveRadio = RadioTwo) AND (Radio2Type <> NoInterfacedRadio)) THEN
             DisplayBandMode (ActiveBand, ActiveMode, True)
         ELSE
             DisplayBandMode (ActiveBand, ActiveMode, False);
  }

end;

function NumberQTCsThisStation(Call: CallString): integer;

var
  Station                               : integer;
begin
  NumberQTCsThisStation := 0;
  if NumberQTCStations = 0 then Exit;

  for Station := 0 to NumberQTCStations - 1 do
    if QTCDataArray^[Station].Call = Call then
    begin
      Result := QTCDataArray^[Station].NumberQTCs;
      Exit;
    end;
end;

procedure IncrementQTCCount(Call: CallString);
var
  Station                               : integer;
begin
  inc(TotalNumberQTCsProcessed);
  if NumberQTCStations = 0 then
  begin
    QTCDataArray^[NumberQTCStations].Call := Call;
    QTCDataArray^[NumberQTCStations].NumberQTCs := 1;
    inc(NumberQTCStations);
    Exit;
  end;

  for Station := 0 to NumberQTCStations - 1 do
    if QTCDataArray^[Station].Call = Call then
    begin
      inc(QTCDataArray^[Station].NumberQTCs);
      Exit;
    end;

//  if NumberQTCStations > 499 then showint(NumberQTCStations);
//  if NumberQTCStations < 0 then showint(NumberQTCStations);

  QTCDataArray^[NumberQTCStations].Call := Call;
  QTCDataArray^[NumberQTCStations].NumberQTCs := 1;
  inc(NumberQTCStations);
  Windows.SetWindowText(tr4whandle, inttopchar(NumberQTCStations));
end;

procedure BandModeDateTimeNumberCallNameSentStamp(Exchange: ContestExchange; var LogString: Str80);

var
  TimeString, CallString, QSONumberString: Str20;
  TempChar                              : Char;
  MonthString                           : PChar;
  Year                                  : Word;
begin
  {
    if Exchange.ceFMMode then
      LogString := string(BandStringsArray[Exchange.Band]) + ModeString[FM]
    else
  }
  LogString := string(BandStringsArray[Exchange.Band]) + ModeString[Exchange.Mode];

  while length(LogString) < LogEntryDayAddress - 1 do LogString := LogString + ' ';

  //if ReadInLog then
  //LogString := LogString + ReadInLogDateString
  //else
  //       if Exchange.Date <> '' then
  //         LogString := LogString + Exchange.Date
  //       else

  SetLength(TimeString, 9);
  MonthString := MonthTags[Exchange.tSysTime.qtMonth];
  Year := (Exchange.tSysTime.qtYear + 2000) mod 100;
  asm
   mov ax,word ptr Year
   movzx eax,ax
   push eax

   push MonthString

   movzx eax,Exchange.tSysTime.qtDay
   push eax
  end;
  wsprintf(@TimeString[1], '%02u-%s-%02u');
  asm add esp,20
  end;
  LogString := LogString + TimeString;

  //         LogString := LogString + GetDateString;

  while length(LogString) < LogEntryHourAddress - 1 do LogString := LogString + ' ';
  SetLength(TimeString, 5);
  asm

   movzx eax, Exchange.tSysTime.qtMinute
   push eax

   movzx eax, Exchange.tSysTime.qtHour
   push eax

  end;
  wsprintf(@TimeString[1], '%.2hu:%.2hu');
  asm add esp,16
  end;
  LogString := LogString + TimeString;

  //   TimeString := IntToStr(Exchange.tSysTime.wHour);
  //   if Exchange.tSysTime.wHour < 10 then TimeString := '0' + TimeString;
  //   TimeString := ':' + TimeString;

     {
        if ReadInLog then
           LogString := LogString + ReadinLogTimeString
        else
           if Exchange.Time >= 0 then
              begin
                 Str(Exchange.Time, TimeString);
                 while length(TimeString) < 4 do TimeString := '0' + TimeString;
                 Insert(':', TimeString, 3);
                 LogString := LogString + TimeString;
              end
           else
              LogString := LogString + GetTimeString;
     }

     //GetTimeString
  while length(LogString) < LogEntryQSONumberAddress - 1 do
    LogString := LogString + ' ';

  if LogFrequencyEnable then
  begin
    case Exchange.Band of
      Band160: Exchange.Frequency := Exchange.Frequency - 1000000;
      Band80: Exchange.Frequency := Exchange.Frequency - 3000000;
      Band40: Exchange.Frequency := Exchange.Frequency - 7000000;
      Band30: Exchange.Frequency := Exchange.Frequency - 10000000;
      Band20: Exchange.Frequency := Exchange.Frequency - 14000000;
      Band17: Exchange.Frequency := Exchange.Frequency - 18000000;
      Band15: Exchange.Frequency := Exchange.Frequency - 21000000;
      Band12: Exchange.Frequency := Exchange.Frequency - 24000000;
      Band10: Exchange.Frequency := Exchange.Frequency - 28000000;
      Band6: Exchange.Frequency := Exchange.Frequency - 54000000;
      Band2: Exchange.Frequency := Exchange.Frequency - 144000000;
    end;

    if Exchange.Frequency < 0 then Exchange.Frequency := 0;

    Exchange.Frequency := Exchange.Frequency div 1000;

    Str(Exchange.Frequency, QSONumberString);

    while length(QSONumberString) < 3 do
      QSONumberString := '0' + QSONumberString;

    QSONumberString := '.' + QSONumberString;
  end
  else
    Str(Exchange.NumberSent, QSONumberString);

  while length(QSONumberString) < 4 do
    QSONumberString := ' ' + QSONumberString;

  LogString := LogString + QSONumberString;
  {
     if ReadInLog then
        LogString := LogString + ReadInLogComputerID
     else
        if ComputerID <> CHR(0) then
           LogString := LogString + ComputerID
        else
           if (ActiveRadio = radioone) and (Radio1.IDCharacter <> CHR(0)) then
              LogString := LogString + Radio1.IDCharacter
           else
              if (ActiveRadio = RadioTwo) and (Radio2.IDCharacter <> CHR(0)) then
                 LogString := LogString + Radio2.IDCharacter;
  }
  TempChar := ' ';
//  if ReadInLog then
//    TempChar := ReadInLogComputerID
//  else
  if Exchange.ceComputerID <> CHR(0) then
    TempChar := Exchange.ceComputerID
  else
    if (ActiveRadio = RadioOne) and (Radio1.IDCharacter <> CHR(0)) then
      TempChar := Radio1.IDCharacter
    else
      if (ActiveRadio = RadioTwo) and (Radio2.IDCharacter <> CHR(0)) then
        TempChar := Radio2.IDCharacter;

//  if Exchange.ceComputerID <> CHR(0) then TempChar := Exchange.ceComputerID;
  LogString := LogString + TempChar;

  while length(LogString) < LogEntryCallAddress - 1 do
    LogString := LogString + ' ';

  LogString := LogString + Exchange.Callsign;

  while length(LogString) < LogEntryNameSentAddress - 1 do
    LogString := LogString + ' ';

  if NameFlagEnable then
    if Exchange.NameSent then
      LogString := LogString + '*';

  while length(LogString) < LogEntryExchangeAddress - 1 do
    LogString := LogString + ' ';

end;

procedure BandModeDateTimeNumberCallNameSentHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := ' Band    Date    Time  QSO#  Call worked';
  Underline := ' ----    ----    ----  ----  -----------';

  while length(LogString) < LogEntryExchangeAddress - 1 do
  begin
    LogString := LogString + ' ';
    Underline := Underline + ' ';
  end;
end;

procedure ClassReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  ClassString                           : Str20;

begin
  ClassString := Exchange.ceClass;
  while length(ClassString) < 7 do
    ClassString := ClassString + ' ';

  LogString := LogString + '  ' + ClassString;
end;

procedure ClassReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Class  ';
  Underline := Underline + '-----  ';
end;

procedure KidsReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

begin
  LogString := LogString + Exchange.Kids;
end;

procedure KidsReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Exchange';
  Underline := Underline + '--------  ';
end;

procedure QSONumberReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  QSONumberString                       : Str80;
  Result                                : integer;

begin
  QSONumberString := '';
  if Exchange.NumberReceived >= 0 then
    Str(Exchange.NumberReceived, QSONumberString);

  {KK1L: 6.70 Sometimes there is just not a pretty way to do it!!}
  {           Keeps the Power and QSO numbers lined up in log.}
  if (ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange) and
    (length(QSONumberString) = 0) then Exit;

  if (ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange) then {KK1L: 6.70}
    while length(QSONumberString) < 5 do
      QSONumberString := ' ' + QSONumberString
  else
    while length(QSONumberString) < 4 do
      QSONumberString := ' ' + QSONumberString;

  QSONumberString := QSONumberString + '  ';
  //{WLI}    QSONumberString [0] := Chr (6);
  QSONumberString := Copy(QSONumberString, 1, 6);

  LogString := LogString + QSONumberString;
end;

procedure QSONumberReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Rcvd  ';
  Underline := Underline + '----  ';
end;

procedure RSTSentStamp(Exchange: ContestExchange; var LogString: Str80);

var
  RSTString                             : Str80;

begin

//  if ReadInLog then
//    RSTString := ' ' + ReadInLogRST + '     '
//  else
  RSTString := ' ' + IntToStr(Exchange.RSTSent) + '     ';

  RSTString[0] := CHR(5);
  RSTString := Copy(RSTString, 1, 5);
  LogString := LogString + RSTString;

end;

procedure RSTSentHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Sent ';
  Underline := Underline + '---- ';
end;

procedure RSTReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  RSTString                             : Str80;

begin

  RSTString := ' ' + IntToStr(Exchange.RSTReceived) + '     ';
  RSTString[0] := CHR(5);
  RSTString := Copy(RSTString, 1, 5);
  LogString := LogString + RSTString;

end;

procedure RandomCharsSentAndReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Sent   Rcvd   ';
  Underline := Underline + '----   ----   ';
end;

procedure RandomCharsSentAndReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  CharsString                           : Str20;

begin
  CharsString := Exchange.RandomCharsSent;

  while length(CharsString) < 7 do
    CharsString := CharsString + ' ';

  LogString := LogString + CharsString;

  CharsString := Exchange.RandomCharsReceived;

  while length(CharsString) < 7 do
    CharsString := CharsString + ' ';

  LogString := LogString + CharsString;
end;

procedure PostalCodeReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Post Code ';
  Underline := Underline + '--------- ';
end;

procedure PostalCodeReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  CharsString                           : Str20;

begin
  CharsString := Exchange.PostalCode;

  while length(CharsString) < 10 do
    CharsString := CharsString + ' ';

  LogString := LogString + CharsString;
end;

procedure RSTReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Rcvd ';
  Underline := Underline + '---- ';
end;

procedure CheckReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  CheckString                           : Str80;

begin
  CheckString := IntToStr(Exchange.Check) + '     ';
  //{WLI}    CheckString [0] := Chr (3);
  CheckString := Copy(CheckString, 1, 3);

  LogString := LogString + CheckString;
end;

procedure CheckReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Ck ';
  Underline := Underline + '-- ';
end;

procedure PrecedenceReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  PrecedenceString                      : Str80;

begin
  PrecedenceString := Exchange.Precedence + '   ';
  //{WLI}    PrecedenceString [0] := Chr (2);
  PrecedenceString := Copy(PrecedenceString, 1, 2);
  LogString := LogString + PrecedenceString;
end;

procedure PrecedenceReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'P ';
  Underline := Underline + '- ';
end;

procedure QTHReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

{ QTH must always be last before mults.  We will now always log what was
  actually typed in by the operator if it is a domesitc QTH. }
{KK1L: 6.70 Except for FISTS Sprint! For this the QTH comes after RST}

var
  QTHString, PrefectureString           : Str80;

begin
  {KK1L: 6.70 removed because the QTH is part of the exchange. DUH!}
  {IF ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange THEN Exit; {KK1L: 6.67 Fix for name truncated}

  {ua4wli для российских тестов}
  if (ActiveExchange = QSONumberAndGridSquare) or
    (ActiveExchange = QSONumberAndGeoCoordinates) or
    (ActiveExchange = QSONumberAndCoordinatesSum)
    then
  begin
    QTHString := Exchange.QTHString + '                      ';
    QTHString := Copy(QTHString, 1, 22);
    LogString := LogString + QTHString;
    Exit;
  end;

  if (ActiveExchange = RSTQTHExchange) or
    (ActiveExchange = QSONumberDomesticOrDXQTHExchange) or
    (ActiveExchange = QSONumberAndGridSquare) or
    (ActiveExchange = QSONumberAndGeoCoordinates)
    then
  begin
    if (LiteralDomesticQTH) or
      (ActiveExchange = QSONumberAndGeoCoordinates) or
      (ActiveExchange = QSONumberAndGridSquare)

    then
      QTHString := Exchange.QTHString + '                      '
    else
      QTHString := Exchange.DomesticQTH + '                      ';

      //{WLI}        QTHString [0] := Chr (22);
    QTHString := Copy(QTHString, 1, 22);

    LogString := LogString + QTHString;
    Exit;
  end;

  if ActiveExchange = RSTAndContinentExchange then
  begin
    QTHString := Exchange.QTHString;
    while length(QTHString) < 22 do QTHString := QTHString + ' ';
    LogString := LogString + QTHString;
    Exit;
  end;

  if (ActiveExchange = RSTALLJAPrefectureAndPrecedenceExchange) or
    (ActiveExchange = RSTPrefectureExchange) then
  begin
    PrefectureString := Exchange.DomesticQTH;
    Delete(PrefectureString, 1, 1);

    case length(PrefectureString) of
      0: PrefectureString := '    ';
      1: PrefectureString := '  ' + PrefectureString + ' ';
      2: PrefectureString := ' ' + PrefectureString + ' ';
      3: PrefectureString := PrefectureString + ' ';
    else
      if length(PrefectureString) > 4 then
            //{WLI}                    PrefectureString [0] := Chr (4);
        PrefectureString := Copy(PrefectureString, 1, 4);

    end;

    LogString := LogString + PrefectureString + ' ';
    Exit;
  end;

  if ActiveExchange = RSTNameAndQTHExchange then
  begin
    QTHString := Exchange.QTHString + '               ';
      //{WLI}        QTHString [0] := Chr (10);
    QTHString := Copy(QTHString, 1, 10);
    LogString := LogString + QTHString;
    Exit;
  end;

  if ActiveExchange = RSTQSONumberAndPossibleDomesticQTHExchange then
  begin
    QTHString := '';

    if Exchange.DomesticQTH <> '' then
    begin
      if LiteralDomesticQTH then
        QTHString := Exchange.QTHString
      else
        QTHString := Exchange.DomesticQTH;
    end;

    LogString := LogString + QTHString;

    if length(LogString) > LogEntryMultAddress - 2 then
        //{WLI}            LogString [0] := Chr (LogEntryMultAddress - 2);
      LogString := Copy(LogString, 1, LogEntryMultAddress - 2);

    Exit;
  end;

  if ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange then {KK1L: 6.70}
  begin
    QTHString := Exchange.QTHString;
    while length(QTHString) < 2 do QTHString := QTHString + ' ';
    LogString := LogString + QTHString + '  ';
    Exit;
  end;

  { All other exchanges }

  if Exchange.DomesticQTH <> '' then
  begin
    if LiteralDomesticQTH then
      QTHString := Exchange.QTHString
    else
      QTHString := Exchange.DomesticQTH;
  end
  else
  begin
    GetDXQTH(Exchange); { 6.30 }
    QTHString := Exchange.DXQTH; {KK1L: 6.72 NOTE this is where DXQTH makes it to the log}
  end;

  if QTHString = '' then QTHString := Exchange.QTHString;

  LogString := LogString + QTHString;

  if length(LogString) > LogEntryMultAddress - 2 then
    //{WLI}        LogString [0] := Chr (LogEntryMultAddress - 2);
    LogString := Copy(LogString, 1, LogEntryMultAddress - 2);

end;

procedure QTHReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  if ActiveExchange = RSTQTHExchange then
  begin
    LogString := LogString + 'Qth Received          ';
    Underline := Underline + '------------          ';
    Exit;
  end;

  if (ActiveExchange = RSTALLJAPrefectureAndPrecedenceExchange) or
    (ActiveExchange = RSTPrefectureExchange) then
  begin
    LogString := LogString + 'Pref ';
    Underline := Underline + '---- ';
    Exit;
  end;

  if ActiveExchange = RSTNameAndQTHExchange then
  begin
    LogString := LogString + 'Qth       ';
    Underline := Underline + '---       ';
  end
  else
  begin
    LogString := LogString + ' Qth  ';
    Underline := Underline + '----- ';
  end;
end;

procedure MultiplierStamp(Exchange: ContestExchange; var LogString: Str80);

{ The first instruction of this procedure deserves some explaining.  Since
  this routine gets used for two things: making log strings to put into
  the editable window and fixing multipier strings.  The first instruction
  allows it to be used for both but not add spaces if we are fixing a
  multiplier string.                                                   }

var
  MultString, ZoneString                : Str80;

begin

  if (ActiveDomesticMult = NoDomesticMults) and (ActiveDXMult = NoDXMults) and
    (ActivePrefixMult = NoPrefixMults) and (ActiveZoneMult = NoZoneMults) then
    Exit;

  if ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange then Exit;

  if length(LogString) > 20 then
    while length(LogString) < LogEntryMultAddress - 1 do
      LogString := LogString + ' ';

  MultString := '';

  if Exchange.DomesticMult then
  begin
    MultString := Exchange.DomMultQTH;
  end;

  if Exchange.DXMult then
    if MultString = '' then
      MultString := Exchange.DXQTH
    else
      MultString := MultString + ' ' + Exchange.DXQTH;

  if Exchange.PrefixMult then
    if MultString = '' then
      MultString := Exchange.Prefix
    else
      MultString := MultString + ' ' + Exchange.Prefix;

  if Exchange.ZoneMult then
  begin
    ZoneString := IntToStr(Exchange.Zone);

    while length(ZoneString) < 2 do
      ZoneString := '0' + ZoneString;

    if MultString = '' then
      MultString := ZoneString
    else
      MultString := MultString + ' ' + ZoneString;
  end;

  LogString := LogString + MultString;

end;

procedure MultiplierHeader(var LogString: Str80; var Underline: Str80);

begin
  if (ActiveDomesticMult = NoDomesticMults) and (ActiveDXMult = NoDXMults) and
    (ActivePrefixMult = NoPrefixMults) and (ActiveZoneMult = NoZoneMults) then
    Exit;

  if ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange then Exit;

  while length(LogString) < LogEntryMultAddress - 1 do
    LogString := LogString + ' ';

  while length(Underline) < LogEntryMultAddress - 1 do
    Underline := Underline + ' ';

  LogString := LogString + 'Mults   ';
  Underline := Underline + '-----   ';
end;

procedure PowerReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  TempString                            : Str80;

begin
  TempString := Exchange.Power;

  {KK1L: 6.70 Sometimes there is just not a pretty way to do it!!}
  {           Keeps the Power and QSO numbers lined up in log.}
  if (ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange) and
    (length(TempString) = 0) then Exit;

  if (ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange) then {KK1L: 6.70}
    while length(TempString) < 5 do
      TempString := ' ' + TempString
  else
    while length(TempString) < 4 do
      TempString := ' ' + TempString;

  LogString := LogString + TempString + '  ';
end;

procedure PowerReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Power ';
  Underline := Underline + '----- ';
end;

procedure ZoneReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  TempString                            : Str80;

begin

  if Exchange.Zone <> 255 {''} then
  begin
    TempString := IntToStr(Exchange.Zone);

    while length(TempString) < 2 do
      TempString := '0' + TempString;

    TempString := ' ' + TempString + ' ';
    LogString := LogString + TempString + ' ';
  end
  else
    LogString := LogString + '     ';

end;

procedure TenTenNumReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + ' 1010# ';
  Underline := Underline + ' ----- ';
end;

procedure TenTenNumReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  TenTenNumberString                    : Str20;

begin
  if Exchange.TenTenNum > 0 then
  begin
    Str(Exchange.TenTenNum, TenTenNumberString);

    while length(TenTenNumberString) < 6 do
      TenTenNumberString := ' ' + TenTenNumberString;
  end
  else
    TenTenNumberString := '      ';

  LogString := LogString + TenTenNumberString + ' ';
end;

procedure ZoneReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Zone ';
  Underline := Underline + '---- ';
end;

procedure AgeReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  TempString                            : Str80;

begin
  TempString := IntToStr(Exchange.Age);

  while length(TempString) < 2 do
    TempString := '0' + TempString;

  TempString := ' ' + TempString + ' ';

  LogString := LogString + TempString;
end;

procedure AgeReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Age ';
  Underline := Underline + '--- ';
end;

procedure NameReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  TempString                            : Str80;

begin
  TempString := Exchange.Name;

  {KK1L: 6.70 Changed spacing slightly to line up with output}
  if ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange then
    while length(TempString) < 10 do
      TempString := TempString + ' '
  else
    while length(TempString) < 12 do
      TempString := TempString + ' ';

  LogString := LogString + TempString;
end;

procedure NameReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Name        ';
  Underline := Underline + '----        ';
end;

procedure ChapterReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Chp ';
  Underline := Underline + '--- ';
end;

procedure ChapterReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  TempString                            : Str20;

begin
  TempString := Copy(Exchange.Chapter, 1, 4);

  TempString := TempString + ' ';

  while length(TempString) < 4 do TempString := ' ' + TempString;

  LogString := LogString + TempString;
end;

procedure QSOPointStamp(Exchange: ContestExchange; var LogString: Str80);

var
  QSOPointString                        : Str80;

begin

  while length(LogString) < LogEntryPointsAddress - 1 do
    LogString := LogString + ' ';

  Str(Exchange.QSOPoints, QSOPointString);

  if length(QSOPointString) = 1 then
    QSOPointString := ' ' + QSOPointString;

  LogString := LogString + QSOPointString;

  //     if ShowSearchAndPounce then
  //       if Exchange.ceSearchAndPounce then
  if Exchange.ceSearchAndPounce then LogString := LogString + '$';

end;

procedure QSOPointHeader(var LogString: Str80; var Underline: Str80);

begin
  while length(LogString) < LogEntryPointsAddress - 2 do
    LogString := LogString + ' ';

  while length(Underline) < LogEntryPointsAddress - 3 do
    Underline := Underline + ' ';

  LogString := LogString + 'Pts';
  Underline := Underline + '---';
end;

function ProperSalutation(Call: CallString): Str80;

var
  TempQTHData                           : QTHRecord;
  Hours, Minutes, Seconds, Hundredths, ZeroZuluOffset: Word;

  RandomNumber                          : integer;
  CurrentHelloRecord                    : HelloRecPtr;
  ID                                    : CallString;

begin
  LocateCall(Call, TempQTHData, True);

  if FirstHelloRecord <> nil then
  begin
    ID := UpperCase(CountryTable.GetCountryID(TempQTHData.Country));
    CurrentHelloRecord := FirstHelloRecord;

    repeat
      if UpperCase(CurrentHelloRecord^.ID) = ID then
      begin
        ProperSalutation := CurrentHelloRecord^.Greeting;
        Exit;
      end;

      CurrentHelloRecord := CurrentHelloRecord^.NextRecord;
    until CurrentHelloRecord = nil;
  end;

  if CountryTable.ZoneMode = CQZoneMode then
  begin
    if (TempQTHData.Zone >= 1) and (TempQTHData.Zone <= 39) then
      ZeroZuluOffset := ZeroZuluOffsetCQZoneArray[TempQTHData.Zone];

    if TempQTHData.Zone = -1 then ZeroZuluOffset := 18;
    if TempQTHData.Zone = 40 then
    begin
      ProperSalutation := 'TU';
      Exit;
    end;

      {
          case TempQTHData.Zone of
            -1: ZeroZuluOffset := 18; // These are US calls not in a proper zone
            1: ZeroZuluOffset := 14;
            2: ZeroZuluOffset := 19;
            3: ZeroZuluOffset := 16;
            4: ZeroZuluOffset := 18;
            5: ZeroZuluOffset := 19;
            6: ZeroZuluOffset := 17;
            7: ZeroZuluOffset := 18;
            8: ZeroZuluOffset := 19;
            9: ZeroZuluOffset := 18;
            10: ZeroZuluOffset := 19;
            11: ZeroZuluOffset := 21;
            12: ZeroZuluOffset := 19;
            13: ZeroZuluOffset := 20;
            14: ZeroZuluOffset := 0;
            15: ZeroZuluOffset := 1;
            16: ZeroZuluOffset := 2;
            17: ZeroZuluOffset := 4;
            18: ZeroZuluOffset := 6;
            19: ZeroZuluOffset := 9;
            20: ZeroZuluOffset := 2;
            21: ZeroZuluOffset := 4;
            22: ZeroZuluOffset := 5;
            23: ZeroZuluOffset := 7;
            24: ZeroZuluOffset := 8;
            25: ZeroZuluOffset := 9;
            26: ZeroZuluOffset := 7;
            27: ZeroZuluOffset := 8;
            28: ZeroZuluOffset := 7;
            29: ZeroZuluOffset := 8;
            30: ZeroZuluOffset := 10;
            31: ZeroZuluOffset := 14;
            32: ZeroZuluOffset := 12;
            33: ZeroZuluOffset := 0;
            34: ZeroZuluOffset := 2;
            35: ZeroZuluOffset := 0;
            36: ZeroZuluOffset := 0;
            37: ZeroZuluOffset := 2;
            38: ZeroZuluOffset := 1;
            39: ZeroZuluOffset := 3;
            40:
              begin
                ProperSalutation := 'TU';
                Exit;
              end;

          end;
      }
  end
  else
  begin
    if (TempQTHData.Zone >= 1) and (TempQTHData.Zone <= 66) then ZeroZuluOffset :=
      ZeroZuluOffsetITUZoneArray[TempQTHData.Zone]
    else
    begin
      ProperSalutation := 'TU';
      Exit;
    end;

      {
          case TempQTHData.Zone of
            1: ZeroZuluOffset := 14;
            2: ZeroZuluOffset := 16;
            3: ZeroZuluOffset := 17;
            4: ZeroZuluOffset := 18;
            5: ZeroZuluOffset := 19;
            6: ZeroZuluOffset := 16;
            7: ZeroZuluOffset := 18;
            8: ZeroZuluOffset := 19;
            9: ZeroZuluOffset := 19;
            10: ZeroZuluOffset := 17;

            11: ZeroZuluOffset := 19;
            12: ZeroZuluOffset := 19;
            13: ZeroZuluOffset := 21;
            14: ZeroZuluOffset := 19;
            15: ZeroZuluOffset := 21;
            16: ZeroZuluOffset := 20;
            17: ZeroZuluOffset := 23;
            18: ZeroZuluOffset := 1;
            19: ZeroZuluOffset := 2;
            20: ZeroZuluOffset := 4;

            21: ZeroZuluOffset := 4;
            22: ZeroZuluOffset := 5;
            23: ZeroZuluOffset := 6;
            24: ZeroZuluOffset := 7;
            25: ZeroZuluOffset := 8;
            26: ZeroZuluOffset := 9;
            27: ZeroZuluOffset := 1;
            28: ZeroZuluOffset := 2;
            29: ZeroZuluOffset := 3;
            30: ZeroZuluOffset := 4;

            31: ZeroZuluOffset := 5;
            32: ZeroZuluOffset := 6;
            33: ZeroZuluOffset := 7;
            34: ZeroZuluOffset := 8;
            35: ZeroZuluOffset := 9;
            36: ZeroZuluOffset := 1;
            37: ZeroZuluOffset := 1;
            38: ZeroZuluOffset := 3;
            39: ZeroZuluOffset := 3;
            40: ZeroZuluOffset := 4;

            41: ZeroZuluOffset := 5;
            42: ZeroZuluOffset := 5;
            43: ZeroZuluOffset := 6;
            44: ZeroZuluOffset := 8;
            45: ZeroZuluOffset := 9;
            46: ZeroZuluOffset := 0;
            47: ZeroZuluOffset := 1;
            48: ZeroZuluOffset := 2;
            49: ZeroZuluOffset := 6;
            50: ZeroZuluOffset := 8;

            51: ZeroZuluOffset := 9;
            52: ZeroZuluOffset := 0;
            53: ZeroZuluOffset := 3;
            54: ZeroZuluOffset := 7;
            55: ZeroZuluOffset := 9;
            56: ZeroZuluOffset := 12;
            57: ZeroZuluOffset := 2;
            58: ZeroZuluOffset := 8;
            59: ZeroZuluOffset := 10;
            60: ZeroZuluOffset := 11;

            61: ZeroZuluOffset := 13;
            62: ZeroZuluOffset := 13;
            63: ZeroZuluOffset := 13;
            64: ZeroZuluOffset := 10;
            65: ZeroZuluOffset := 10;
            66: ZeroZuluOffset := 22;

          else
            begin
              ProperSalutation := 'TU';
              Exit;
            end;
          end;
      }
  end;

  Hours := GetIntegerTime div 100;
  Hours := (Hours + ZeroZuluOffset) mod 24;

  if (Hours >= 2) and (Hours <= 11) then ProperSalutation := 'GM';
  if (Hours >= 12) and (Hours <= 17) then ProperSalutation := 'GA';
  if (Hours >= 18) or (Hours <= 1) then ProperSalutation := 'GE';
end;

procedure LoadSpecialHelloFile;

var
  FileRead                              : Text;
  FileName, FileString                  : ShortString {Str80}; {WLI}
  Greeting, ID                          : Str20;

begin
  if FirstHelloRecord <> nil then Exit;
  {WLI}
  //    FileName := FindDirectory ('HELLO.DAT') + '\HELLO.DAT';
//  FileName := 'HELLO.DAT';

  if OpenFileForRead(FileRead, 'HELLO.DAT' { FileName}) then
  begin
    while not Eof(FileRead) do
    begin
      ReadLn(FileRead, FileString);
      GetRidOfPrecedingSpaces(FileString);
      ID := RemoveFirstString(FileString);
      GetRidOfPrecedingSpaces(FileString);
      GetRidOfPostcedingSpaces(FileString);
      Greeting := FileString;

      if FirstHelloRecord = nil then
      begin
        FirstHelloRecord := New(HelloRecPtr);
        FirstHelloRecord^.ID := ID;
        FirstHelloRecord^.Greeting := Greeting;
        FirstHelloRecord^.NextRecord := nil;
        LastHelloRecord := FirstHelloRecord;
      end
      else
      begin
        LastHelloRecord^.NextRecord := New(HelloRecPtr);
        LastHelloRecord := LastHelloRecord^.NextRecord;
        LastHelloRecord^.ID := ID;
        LastHelloRecord^.Greeting := Greeting;
        LastHelloRecord^.NextRecord := nil;
      end;
    end;

    Close(FileRead);
  end;
end;

procedure SendSalutation(Call: CallString);

var
  TempString                            : Str80;
  Country                               : integer;
  ID                                    : CallString;

begin
  if Call = '' then Exit;
  AddStringToBuffer(ProperSalutation(Call), CWTone);
end;

procedure SayHello(Call: CallString);

var
  Salutation, Name                      : Str20;
  RandomNumber                          : integer;

begin
  Call := RootCall(Call);
  Name := UpperCase(CD.GetName(Call));

  if (Name <> '') and (Name <> 'CLUB') then
  begin
    Salutation := ProperSalutation(Call);
    if Salutation = 'TU' then Salutation := 'HI';
    RandomNumber := Random(10);
    if RandomNumber >= 7 then Salutation := 'HI';
    AddStringToBuffer(Salutation + ' ' + Name + ' ', CWTone);
    ReceivedData.NameSent := True;
  end
  else
    //    ReceivedData.NameSent := False;
end;

procedure ShowName(Call: CallString);

var
  Name                                  : CallString; // Str20;
  p                                     : PChar;
begin
  Call := RootCall(Call);

  NameCallsignPutUp := Call;
  Name := CD.GetName(Call);
  if Name <> '' then
    p := PChar(string(Name))
  else
    p := nil;

  Windows.SetWindowText(NameSentWindowHandle, p);
  {  p := @Name[1];

    if Name <> '' then
      tSetWindowText(NameSentWindowHandle, Name)
    else
      Windows.SetWindowText(NameSentWindowHandle, nil);
  }
end;

procedure SayName(Call: CallString);

var
  Name                                  : Str20;

begin
  Call := RootCall(Call);
  Name := UpperCase(CD.GetName(Call));

  if (Name <> '') and (Name <> 'CLUB') then
  begin
    AddStringToBuffer(Name + ' ', CWTone);
    ReceivedData.NameSent := True;
  end
  else
    //    RemoveWindow(NameSentWindow);
end;

function DVKRecentlyStarted(MaxElaspedSec100: LONGINT): boolean;

begin
  if not DVKPlaying then
  begin
    DVKRecentlyStarted := False;
    Exit;
  end;

  DVKRecentlyStarted := MaxElaspedSec100 >= ElaspedSec100(DVKStartTime);
end;

procedure DVKStamp;

begin
  //пока не знаю что тут надо сделать или изменить
  {
    DVKPlaying := True;

    GetTime(DVKStartTime.Hour,
      DVKStartTime.Minute,
      DVKStartTime.Second,
      DVKStartTime.Sec100);
  }
end;

function KeyRecentlyPressed(Key: Char; MaxElaspedSec100: LONGINT): boolean;

begin
  KeyRecentlyPressed := False;
  if Key <> KeyHistory.Key then Exit;
  KeyRecentlyPressed := MaxElaspedSec100 >= ElaspedSec100(KeyHistory.Time);
end;

procedure KeyStamp(Key: Char);

begin
  KeyHistory.Key := Key;
  KeyHistory.Time := GetTickCount;
  {  with KeyHistory do
    begin
      GetTime(Time.Hour, Time.Minute, Time.Second, Time.Sec100);
    end;
  }
end;

procedure ParseExchange(Exchange: ShortString {Str80} {WLI}; var FirstString, SecondString, ThirdString: Str10 {Str20});

begin
  FirstString := '';
  SecondString := '';
  ThirdString := '';

  if length(Exchange) = 0 then Exit;

  if StringHas(Exchange, ' ') then
  begin
    FirstString := PrecedingString(Exchange, ' ');
    Delete(Exchange, 1, length(FirstString) + 1);
    GetRidOfPrecedingSpaces(Exchange);

    if StringHas(Exchange, ' ') then
    begin
      SecondString := PrecedingString(Exchange, ' ');
      Delete(Exchange, 1, length(SecondString));
      GetRidOfPrecedingSpaces(Exchange);
      ThirdString := Exchange;
    end
    else
      SecondString := Exchange;
  end
  else
    FirstString := Exchange;
end;

function ProcessKidsExchange(ExchangeString: Str80; var RData: ContestExchange): boolean;

begin
  RData.Kids := ExchangeString;
  ProcessKidsExchange := True;
end;

function ProcessClassAndDomesticOrDXQTHExchange(Exchange: string {Str80}; var RXData: ContestExchange): boolean;

{ If the call is a domestic call, there must be a space with the Class
  before the space and the Domestic QTH after it.  If it is a not a domestic
  call the exchange must just be the Class.  In both cases, the Class must
  be at least two characters in length. }
{KK1L: 6.68 This needed to change for the new FD rules which allow all of Region 2 to participate.}
{           Now DX can send a class. Let's still force a check for domesticity and require both a }
{           class and section. For others if the second string of the exchange is blank I will }
{           "let it slide" and assume the first string is class (likely "DX"). }

var
  TempString, TempString2               : Str10 {Str20};

begin
  ProcessClassAndDomesticOrDXQTHExchange := False;

  if DomesticCountryCall(RXData.Callsign) then
  begin
    ParseExchange(Exchange, Str10(RXData.ceClass), RXData.QTHString, TempString);
    if not FoundDomesticQTH(RXData) then Exit;
  end
  else
  begin
      {ParseExchange (Exchange, RXData.Class, RXData.QTHString, TempString);}{pre 6.68 statement}
    ParseExchange(Exchange, Str10(RXData.ceClass), TempString, TempString2);
    if TempString <> '' then RXData.QTHString := TempString;
  end;

  ProcessClassAndDomesticOrDXQTHExchange := (length(RXData.ceClass) = 2) or
    (length(RXData.ceClass) = 3);
end;

function ProcessRSTAndContinentExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

{ Any digits found at the start of the exchange will be used to determine
  the RS(T).  If the first character is not a digit, the default RS(T)
  will be used and the whole exchange will be used as the QTH. }

var
  TempString                            : Str80;
  QTHFound                              : boolean;
  ContPrefix                            : Str20;

begin
  QTHFound := False;
  RXData.QTH.Continent := UnknownContinent;

  ProcessRSTAndContinentExchange := False;
  GetRidOfPrecedingSpaces(Exchange);
  GetRidOfPostcedingSpaces(Exchange);

  if not StringHas(Exchange, ' ') and not StringIsAllNumbers(Exchange) then
  begin
    RXData.RSTReceived := DefaultRST;

    ContPrefix := UpperCase(Copy(Exchange, 1, 2));
    RXData.QTH.Continent := GetContinentFromString(ContPrefix);
      {
            if ContPrefix = 'AF' then RXData.QTH.Continent := Africa;
            if ContPrefix = 'AS' then RXData.QTH.Continent := Asia;
            if ContPrefix = 'OC' then RXData.QTH.Continent := Oceania;
            if ContPrefix = 'EU' then RXData.QTH.Continent := Europe;
            if ContPrefix = 'AN' then RXData.QTH.Continent := Antartica;
            if (ContPrefix = 'SO') or (ContPrefix = 'SA') then RXData.QTH.Continent := SouthAmerica;
            if (ContPrefix = 'NO') or (ContPrefix = 'NA') then RXData.QTH.Continent := NorthAmerica;
      }
    RXData.QTHString := Exchange;

    ProcessRSTAndContinentExchange := RXData.QTH.Continent <> UnknownContinent;
    Exit;
  end;

  while Exchange <> '' do
  begin
    TempString := RemoveLastString(Exchange);

    if StringIsAllNumbers(TempString) and (RXData.RSTReceived = 0) then
    begin
      if length(TempString) = 1 then
      begin
        case ActiveMode of
          CW: RXData.RSTReceived := 509 + (Ord(TempString[1]) - 48) * 10;
          Phone: RXData.RSTReceived := 5 + (Ord(TempString[1]) - 48);
        end;
      end
      else
        RXData.RSTReceived := StrToInt(TempString)
    end
    else
      if not QTHFound then
      begin
        ContPrefix := UpperCase(Copy(Exchange, 1, 2));
        RXData.QTH.Continent := GetContinentFromString(ContPrefix);
            {
                        if ContPrefix = 'AF' then RXData.QTH.Continent := Africa;
                        if ContPrefix = 'AS' then RXData.QTH.Continent := Asia;
                        if ContPrefix = 'OC' then RXData.QTH.Continent := Oceania;
                        if ContPrefix = 'EU' then RXData.QTH.Continent := Europe;

                        if (ContPrefix = 'SO') or (ContPrefix = 'SA') then RXData.QTH.Continent := SouthAmerica;
                        if (ContPrefix = 'NO') or (ContPrefix = 'NA') then RXData.QTH.Continent := NorthAmerica;
            }
        RXData.QTHString := Exchange;

        if RXData.QTH.Continent <> UnknownContinent then
        begin
          QTHFound := True;
          RXData.QTHString := TempString;
        end;
      end;
  end;

  if QTHFound then
  begin
    if RXData.RSTReceived = 0 then
      RXData.RSTReceived := DefaultRST;
    ProcessRSTAndContinentExchange := True;
  end;
end;

function ProcessNameQTHAndPossibleTenTenNumberExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

var
  TempString                            : ShortString {Str80};
  ThirdString, NumberString             : Str10 {Str20};
  Result1                               : integer;
  //   tempstr20                       : Str20;
begin
  ProcessNameQTHAndPossibleTenTenNumberExchange := False;

  if Exchange = '' then Exit;

  TempString := Exchange;
  Exchange := '';

  RXData.TenTenNum := MAXWORD {-1};

  while TempString <> '' do
  begin
    NumberString := RemoveFirstString(TempString);

    if StringIsAllNumbers(NumberString) then
      Val(NumberString, RXData.TenTenNum, Result1)
    else
      Exchange := Exchange + NumberString + ' ';
  end;

  ParseExchange(Exchange, RXData.Name, RXData.QTHString, ThirdString);

  if not DomesticCountryCall(RXData.Callsign) then
    ProcessNameQTHAndPossibleTenTenNumberExchange := True
  else
    ProcessNameQTHAndPossibleTenTenNumberExchange := FoundDomesticQTH(RXData);

end;

function ProcessNameAndDomesticOrDXQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ Two entries with space, name is first. IF DX, then no QTH. }

var
  ThirdString                           : Str10 {Str20};

begin
  ProcessNameAndDomesticOrDXQTHExchange := False;
  if Exchange = '' then Exit;

  ParseExchange(Exchange, RXData.Name, RXData.QTHString, ThirdString);

  if not DomesticCountryCall(RXData.Callsign) then
    ProcessNameAndDomesticOrDXQTHExchange := True
  else
    ProcessNameAndDomesticOrDXQTHExchange := FoundDomesticQTH(RXData);

end;

function ProcessQSONumberAndDomesticQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ If the the two entries are separated by a space, they may appear in either
  order.  If only one entry appears, it is assumed to be the Domestic QTH
  and the QSO number will be one.  }

var
//  Result1                               : integer;
  {NumberString,}Str1, Str2 {, Str3, Str4}: Str10 {Str20};
//  Parsed                                : boolean;
  sp                                    : integer;
  c                                     : integer;
  i                                     : integer;
begin
  ProcessQSONumberAndDomesticQTHExchange := False;
  if length(Exchange) = 0 then Exit;

  Str1 := '';
  Str2 := '';
//  Str3 := '';
//  Str4 := '';

//  NumberString := '';

  RXData.QTHString := '';

  for i := 1 to length(Exchange) - 1 do
  begin
    if (tCharIsNumbers(Exchange[i]) <> tCharIsNumbers(Exchange[i + 1])) or (Exchange[i + 1] = ' ') then
    begin
      Str1 := Copy(Exchange, 1, i);
      Break;
    end;
  end;

  for i := length(Exchange) downto 2 do
  begin
    if (tCharIsNumbers(Exchange[i]) <> tCharIsNumbers(Exchange[i - 1])) or (Exchange[i - 1] = ' ') then
    begin
      Str2 := Copy(Exchange, i, 80);
      Break;
    end;
  end;

  if Str1 = '' then Exit;
  if Str2 = '' then Exit;

  if StringIsAllNumbers(Str1) then
  begin
    RXData.NumberReceived := StrToInt(Str1);
    RXData.QTHString := Str2;
  end
  else
    if StringIsAllNumbers(Str2) then
    begin
      RXData.NumberReceived := StrToInt(Str2);
      RXData.QTHString := Str1;
    end
    else Exit;
  ProcessQSONumberAndDomesticQTHExchange := FoundDomesticQTH(RXData);
  if not Result then ExchangeErrorMessage := TC_IMPROPERDOMESITCQTH;
{
  Exit;

  ParseExchange(Exchange, Str1, Str2, Str3);

  if StringHas(Str3, ' ') then
  begin
    Str4 := PostcedingString(Str3, ' ');
    Str3 := PrecedingString(Str3, ' ');
  end;

  // Do the number - it is easy

  if StringIsAllNumbers(Str4) then
    NumberString := Str4
  else
    if StringIsAllNumbers(Str3) then
      NumberString := Str3
    else
      if StringIsAllNumbers(Str2) then
        NumberString := Str2
      else
        if StringIsAllNumbers(Str1) then
          NumberString := Str1;
  //wli        else          NumberString := '1';

    // Now the QTH - which isn't so hard either

  if (not StringIsAllNumbers(Str4)) and (Str4 <> '') then
    RXData.QTHString := Str4
  else
    if (not StringIsAllNumbers(Str3)) and (Str3 <> '') then
      RXData.QTHString := Str3
    else
      if (not StringIsAllNumbers(Str2)) and (Str2 <> '') then
        RXData.QTHString := Str2
      else
        if (not StringIsAllNumbers(Str1)) and (Str1 <> '') then
          RXData.QTHString := Str1;

  if RXData.QTHString = '' then Exit;
  if NumberString = '' then
  begin
    Parsed := False;
    for Result1 := 1 to length(RXData.QTHString) - 1 do
      if (not tCharIsNumbers(RXData.QTHString[Result1])) and (tCharIsNumbers(RXData.QTHString[Result1 + 1])) then
      begin
        Parsed := True;
        Break;
      end;
    if Parsed then
    begin
      NumberString := Copy(RXData.QTHString, Result1 + 1, 10);
      RXData.QTHString := Copy(RXData.QTHString, 1, Result1);
    end;

    if Parsed = False then
    begin
      for Result1 := 1 to length(RXData.QTHString) - 1 do
        if (tCharIsNumbers(RXData.QTHString[Result1])) and (not tCharIsNumbers(RXData.QTHString[Result1 + 1])) then
        begin
          Parsed := True;
          Break;
        end;
      if Parsed then
      begin
        NumberString := Copy(RXData.QTHString, 1, Result1);
        RXData.QTHString := Copy(RXData.QTHString, Result1 + 1, 10);
      end;
    end;

  end;

  Val(NumberString, RXData.NumberReceived, Result1);
  if Result1 <> 0 then Exit;
  ProcessQSONumberAndDomesticQTHExchange := FoundDomesticQTH(RXData);
}
end;
{
function ProcessQSONumberAndGridSquareExchange(Exchange: string; var RXData: ContestExchange): boolean;
var
  TempString, NumberString         : Str40;
  GridString                       : Str20;
  Result1                          : integer;

begin
  NumberString := '';
  GridString := '';

  Result := False;

  while (Exchange <> '') and ((NumberString = '') or (GridString = '')) do
    begin
      TempString := RemoveLastString(Exchange);

      if StringIsAllNumbers(TempString) then
        NumberString := TempString
      else
        GridString := TempString;

    end;

  if (NumberString = '') or (GridString = '') then Exit;
  if not GoodLookingGrid(GridString) then Exit;

  RXData.QTHString := GridString;

  Val(NumberString, RXData.NumberReceived, Result1);

  if Result1 <> 0 then Exit;
  Result := FoundDomesticQTH(RXData);
end;
}

function ProcessQSONumberAndGridSquareExchange(Exchange: ShortString; var RXData: ContestExchange): boolean;
var
  TempString, NumberString              : Str40;
  GridString                            : Str20;
  Result1                               : integer;

begin
  NumberString := '';
  GridString := '';

  Result := False;

  while (Exchange <> '') and ((NumberString = '') or (GridString = '')) do
  begin
    TempString := RemoveLastString(Exchange);

    if StringIsAllNumbers(TempString) then
      NumberString := TempString
    else
      GridString := TempString;

  end;

  if GridString = '' then Exit;
  if NumberString = '' then
  begin
    NumberString := Copy(GridString, 1, length(GridString) - 4);
    if not StringIsAllNumbers(NumberString) then Exit;
    GridString := Copy(GridString, length(GridString) - 3, 4);
  end;

  if not GoodLookingGrid(GridString) then Exit;

  RXData.QTHString := GridString;

  Val(NumberString, RXData.NumberReceived, Result1);

  if Result1 <> 0 then Exit;
  Result := FoundDomesticQTH(RXData);
end;

function ProcessQSONumberAndNameExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

var
  TempString, NumberString, NameString  : Str40;
  Result1                               : integer;

begin
  NumberString := '';
  NameString := '';

  ProcessQSONumberAndNameExchange := False;

  while (Exchange <> '') and ((NumberString = '') or (NameString = '')) do
  begin
    TempString := RemoveLastString(Exchange);

    if StringIsAllNumbers(TempString) then
      NumberString := TempString
    else
      NameString := TempString;

  end;

  if (NumberString = '') or (NameString = '') then Exit;

  RXData.Name := NameString;

  Val(NumberString, RXData.NumberReceived, Result1);

  ProcessQSONumberAndNameExchange := Result1 = 0;
end;

function ProcessQSONumberAndZoneExchange(Exchange: ShortString; var RXData: ContestExchange): boolean;
var
  string1, string2, string3             : Str10;
begin

  Result := False;

  if StringIsAllNumbersOrSpaces(Exchange) then
  begin
    ParseExchange(Exchange, string1, string2, string3);
    if string2 <> '' then
    begin
      RXData.Zone := StrToInt(string1);
      RXData.NumberReceived := StrToInt(string2);
      Result := True;
      Exit;
    end;
  end;

  if length(Exchange) < 4 then
  begin
    ExchangeErrorMessage := TC_NOTENOUGHINFOINEXCHANGE;
    Exit;
  end;

  if not StringIsAllNumbers(Exchange) then Exit;

  RXData.Zone := Ord(Exchange[1]) - 48;
  RXData.NumberReceived := StrToInt(Copy(Exchange, 2, 4));

  if (Contest = UA4N) then
  begin
    if length(Exchange) > 4 then
    begin
      RXData.Zone := StrToInt(Copy(Exchange, 1, 2));
      RXData.NumberReceived := StrToInt(Copy(Exchange, 3, 4));
    end
    else
      Exit;
  end;

  Result := True;
end;

function ProcessQSONumberAndGeoCoordinatesExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

var
  TempString, NumberString, QTHString   : Str20;
  Result1                               : integer;
  Lat, Long                             : integer;
begin

  NumberString := '';
  QTHString := '';

  Result := False;

  while (Exchange <> '') and ((NumberString = '') or (QTHString = '')) do
  begin
    TempString := RemoveLastString(Exchange);

    if StringIsAllNumbers(TempString) then
      NumberString := TempString
    else
    begin
          //      if Contest = RUSSIAN160 then if LooksLikeRadio160Square(TempString) then QTHString := TempString;
      if LooksLikeAGeoCoordinates(TempString, Lat, Long) then QTHString := TempString;
    end;

  end;

  if (NumberString = '') or (QTHString = '') then Exit;

  RXData.QTHString := QTHString;

  Val(NumberString, RXData.NumberReceived, Result1);

  Result := Result1 = 0;

end;

function ProcessQSONumberAndCoordinatesSumExchange(Exchange: ShortString; var RXData: ContestExchange): boolean;
var
  NumberString, QTHString               : Str20;
  Result1, i                            : integer;

begin

  NumberString := '';
  QTHString := '';

  Result := False;

  NumberString := RemoveLastString(Exchange);
  QTHString := RemoveLastString(Exchange);
  if not StringIsAllNumbers(NumberString) then Exit;
  if not StringIsAllNumbers(QTHString) then
  begin
    if length(NumberString) < 3 then Exit;
    if (NumberString[1] = '1') or (NumberString[2] = '1') then
      i := 3
    else
      i := 2;

    QTHString := Copy(NumberString, 1, i);
    NumberString := Copy(NumberString, i + 1, 10);
    if QTHString = '' then Exit;
  end;

  if length(QTHString) = 1 then Exit;
  if length(QTHString) > 3 then Exit;

  RXData.QTHString := QTHString;
  Val(NumberString, RXData.NumberReceived, Result1);
  Result := Result1 = 0;
end;

{
function ProcessQSONumberAndCoordinatesSumExchange(Exchange: string; var RXData: ContestExchange): boolean;
var
  NumberString, QTHString          : Str20;
  Result1                          : integer;
begin

  NumberString := '';
  QTHString := '';

  Result := False;

  NumberString := RemoveLastString(Exchange);
  QTHString := RemoveLastString(Exchange);
  if not StringIsAllNumbers(NumberString) then Exit;
  if not StringIsAllNumbers(QTHString) then Exit;
  if length(QTHString) = 1 then Exit;
  if length(QTHString) > 3 then Exit;

  RXData.QTHString := QTHString;
  Val(NumberString, RXData.NumberReceived, Result1);
  Result := Result1 = 0;
end;
}

function ProcessRSTAndOrGridSquareExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

var
  TestString                            : Str20;

begin
  ProcessRSTAndOrGridSquareExchange := False;
  RXData.DomesticQTH := '';
  RXData.RSTReceived := 0;

  if length(Exchange) = 0 then Exit;

  while Exchange <> '' do
  begin
    TestString := RemoveLastString(Exchange);

    if GoodLookingGrid(TestString) then
    begin
      if RXData.DomesticQTH = '' then
      begin
        RXData.DomesticQTH := TestString;
        RXData.QTHString := TestString;
        ProcessRSTAndOrGridSquareExchange := True;
      end;
    end
    else
      if (RXData.RSTReceived = 0) and StringIsAllNumbers(TestString) then
      begin
        if length(TestString) = 1 then
        begin

          case ActiveMode of
            CW: RXData.RSTReceived := 509 + (Ord(TestString[1]) - 48) * 10;
            Phone: RXData.RSTReceived := 50 + (Ord(TestString[1]) - 48);
          end;
        end
        else
          RXData.RSTReceived := StrToInt(TestString);

        ProcessRSTAndOrGridSquareExchange := True;
      end;
  end;

  {ua4wli}
  if (RXData.DomesticQTH <> '') and (RXData.RSTReceived = 0) then
  begin
    case ActiveMode of
      Phone: RXData.RSTReceived := 59;
    else RXData.RSTReceived := 599;
    end;
  end;

end;

function ProcessRSTAndGridSquareExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

var
  TestString                            : Str20;

begin
  ProcessRSTAndGridSquareExchange := False;
  RXData.DomesticQTH := '';
  RXData.RSTReceived := 0;

  if length(Exchange) = 0 then Exit;

  while Exchange <> '' do
  begin
    TestString := RemoveLastString(Exchange);

    if GoodLookingGrid(TestString) then
    begin
      if RXData.QTHString = '' then
        RXData.QTHString := TestString;
    end
    else
      if (RXData.RSTReceived = 0) and StringIsAllNumbers(TestString) then
      begin
        if length(TestString) = 1 then
        begin
          case ActiveMode of
            CW: RXData.RSTReceived := 509 + (Ord(TestString[1]) - 48) * 10;
            Phone: RXData.RSTReceived := 50 + (Ord(TestString[1]) - 48);
          end;
        end
        else
          RXData.RSTReceived := StrToInt(TestString);

      end;
  end;

  if (RXData.DomesticQTH <> '') and (RXData.RSTReceived = 0) then
  begin
    case ActiveMode of
      Phone: RXData.RSTReceived := 59;
    else RXData.RSTReceived := 599;
    end;
  end;

  ProcessRSTAndGridSquareExchange := FoundDomesticQTH(RXData);
end;

function ProcessNameAndPossibleGridSquareExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

var
  TestString                            : Str80;

begin
  ProcessNameAndPossibleGridSquareExchange := False;
  RXData.DomesticQTH := '';
  RXData.Name := '';

  if length(Exchange) = 0 then Exit;

  while Exchange <> '' do
  begin
    TestString := RemoveLastString(Exchange);

    if GoodLookingGrid(TestString) then
    begin
      if RXData.DomesticQTH = '' then
      begin
        RXData.DomesticQTH := TestString;
        RXData.QTHString := TestString;
      end;
    end
    else
      if RXData.Name = '' then RXData.Name := TestString;
  end;

  ProcessNameAndPossibleGridSquareExchange := RXData.Name <> '';
end;

function ProcessQSONumberAndDomesticOrDXQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

var
  Result1                               : integer;
  FirstString, SecondString, ThirdString: Str10 {Str20};

begin
  ProcessQSONumberAndDomesticOrDXQTHExchange := False;
  if length(Exchange) = 0 then Exit;

  if not DomesticCountryCall(RXData.Callsign) then
  begin
    ParseExchange(Exchange, FirstString, SecondString, ThirdString);

    if StringIsAllNumbers(FirstString) then
    begin
      Val(FirstString, RXData.NumberReceived, Result1);
      ProcessQSONumberAndDomesticOrDXQTHExchange := Result1 = 0;
    end
    else
      if StringIsAllNumbers(SecondString) then
      begin
        Val(SecondString, RXData.NumberReceived, Result1);
        ProcessQSONumberAndDomesticOrDXQTHExchange := Result1 = 0;
      end;

    RXData.QTHString := CountryTable.GetCountryID(RXData.QTH.Country);
  end
  else
    ProcessQSONumberAndDomesticOrDXQTHExchange :=
      ProcessQSONumberAndDomesticQTHExchange(Exchange, RXData);

end;

procedure ParseExchangeIntoFields(Exchange: ShortString {Str80};
  var Entries: EntryArray;
  var NumberEntries: integer);

begin
  NumberEntries := 0;

  while Exchange <> '' do
  begin
    inc(NumberEntries);
    Entries[NumberEntries] := RemoveFirstString(Exchange);
    if NumberEntries = 10 then Exit;
  end;
end;

procedure ParseFourFields(sExch: Str80; var s1, s2, s3, s4: Str20);

type
  pSTRING = ^string;

var
  CharIndex, iDstPtrIndex               : integer;
  bInField                              : boolean;
  aps                                   : array[0..3] of pShortString;
  ps                                    : pShortString;
  c                                     : Char;

begin

  s1 := '';
  s2 := '';
  s3 := '';
  s4 := '';

  aps[0] := @s1;
  aps[1] := @s2;
  aps[2] := @s3;
  aps[3] := @s4;

  CharIndex := 1;
  iDstPtrIndex := 0;
  bInField := False;

  while (CharIndex <= length(sExch)) and (iDstPtrIndex <= 3) do
  begin
    c := sExch[CharIndex];
    inc(CharIndex);
    if c <> ' ' then
    begin
      if not bInField then
      begin
        bInField := True;
        ps := aps[iDstPtrIndex];
        ps^ := ps^ + c;
      end
      else
        ps^ := ps^ + c;
    end
    else
      if bInField then
      begin
        bInField := False;
        inc(iDstPtrIndex);
      end
  end;

end;

function LooksLikeACallSign(Call: Str40): boolean;

type
  GOT = (gotNIL, gotLETTER, gotNUMBER);

var
  CharIndex, nChanges                   : integer;
  gotWhat                               : GOT;

begin
  LooksLikeACallSign := False;

  gotWhat := gotNIL;
  nChanges := 0;

  for CharIndex := 1 to length(Call) do
  begin
    if (Call[CharIndex] >= 'A') and (Call[CharIndex] <= 'Z') then
    begin
      if gotWhat = gotNUMBER then inc(nChanges);
      gotWhat := gotLETTER;
    end
    else
      if (Call[CharIndex] >= '0') and (Call[CharIndex] <= '9') then
      begin
            { Calls don't end with numbers unless already have '/' }

        if CharIndex = length(Call) then Exit;

            { Calls don't start with two numbers }

        if (gotWhat = gotNUMBER) and (CharIndex = 2) then Exit;

        if gotWhat = gotLETTER then inc(nChanges);

        gotWhat := gotNUMBER;
      end
      else
        if Call[CharIndex] = '/' then
        begin
          if ((CharIndex > 3) and (CharIndex <> length(Call)) or
            ((CharIndex < length(Call)) and (CharIndex > 1))) then
          begin
            LooksLikeACallSign := True;
            Exit;
          end;
        end;

    if ((CharIndex = 1) or (CharIndex = length(Call))) and (Call[CharIndex] = '/') then
    begin
      LooksLikeACallSign := False;
      Exit;
    end;
  end;

  LooksLikeACallSign := (nChanges >= 2) and (gotWhat = gotLETTER);
end;

function ProcessQSONumberNameChapterAndQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ Used for the QCWA contest.  The Chapter might be 2 or 3 integers, of AL
  for At Large.

  Valid formats:
      QSO# NAME CHAPTER QTH or NAME CHAPTER QTH QSO#

  }

var
  FirstString, SecondString, ThirdString, FourthString: Str20;
  Result1                               : integer;

begin
  ProcessQSONumberNameChapterAndQTHExchange := False;

  if length(Exchange) < 9 then Exit;

  ParseFourFields(Exchange, FirstString, SecondString, ThirdString, FourthString);

  if StringIsAllNumbers(FirstString) then
  begin
    if not (StringIsAllNumbers(ThirdString) or (UpperCase(ThirdString) = 'AL')) then Exit;

    Val(FirstString, RXData.NumberReceived, Result1);

    RXData.Name := SecondString;
    RXData.Chapter := UpperCase(ThirdString);
    RXData.DomesticQTH := FourthString;
  end

  else { Number at end? }

  begin
    if not StringIsAllNumbers(FourthString) then Exit;
    if not (StringIsAllNumbers(SecondString) or (UpperCase(SecondString) = 'AL')) then Exit;

    Val(FourthString, RXData.NumberReceived, Result1);

    RXData.Name := FirstString;
    RXData.Chapter := UpperCase(SecondString);
    RXData.DomesticQTH := ThirdString;
  end;

  ProcessQSONumberNameChapterAndQTHExchange := True;
end;

function ProcessCheckAndChapterOrQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ Used for the QCWA Golden Anniversay contest.  The Chapter might be 2 or 3
  integers, or AL for At Large with QTH.  The CHECK is two numbers (year).

  Valid formats:
      CHECK CHAPTER or CHECK QTH

  }

var
  FirstString, SecondString, ThirdString, FourthString: Str20;
  //    Result1: INTEGER;

begin
  ProcessCheckAndChapterOrQTHExchange := False;

  if length(Exchange) < 4 then Exit;

  ParseFourFields(Exchange, FirstString, SecondString, ThirdString, FourthString);

  if StringIsAllNumbers(FirstString) then
  begin
    RXData.Check := StrToInt(FirstString);

    if SecondString <> '' then
    begin
      RXData.DomesticQTH := SecondString;
      RXData.QTHString := SecondString;
      ProcessCheckAndChapterOrQTHExchange := True;
      Exit;
    end;
  end;
end;

function ProcessQSONumberNameAndDomesticOrDXQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ $Id: proc-nas.pas 1.2 94/09/09 01:48:52 jzap Exp $ }

{ The exchange must be at least 6 characters in length, with each entry
  separated by a space.

  > The new parse routine will put the first four exchange fields into
  > separate strings.  Each is checked to see if it looks like a callsign.
  > If it does, it is used to update the call and is removed; the other
  > strings move up.  What's left constitute the first, second, and third
  > entries described below.

  If the first entry is the QSO number, the second
  entry must be the name and the last entry the QTH string.  If the second
  entry is the QSO number, the first entry must be the name and the last
  entry the QTH.  If the last entry is to be the QSO number (this is
  normal if the program already knew the name and QTH as an initial
  exchange), then the first entry is the name, the second the QTH.  The
  QTH string is ignored if the call is outside the 49 states or Canada.
  If the name is different than that in the name database, it will be
  changed.  }

var
  TempString, Call, Name                : Str20;
  NumberEntries, Result1                : integer;
  DX                                    : boolean;
  EntryList                             : EntryArray;

begin
  ProcessQSONumberNameAndDomesticOrDXQTHExchange := False;

  if length(Exchange) < 4 then
  begin
    ExchangeErrorMessage := TC_NOTENOUGHINFOINEXCHANGE;
    Exit;
  end;

  DX := not DomesticCountryCall(RXData.Callsign);

  ParseExchangeIntoFields(Exchange, EntryList, NumberEntries);

  { If we have multiple number entries at the end of the exchange,
    filter out the previous ones }

  while (NumberEntries > 3) and
    StringIsAllNumbers(EntryList[NumberEntries]) and
    StringIsAllNumbers(EntryList[NumberEntries - 1]) do
  begin
    EntryList[NumberEntries - 1] := EntryList[NumberEntries];
    dec(NumberEntries);
  end;

  if NumberEntries <= 3 then { Use old method }
  begin
    if StringIsAllNumbers(EntryList[1]) then
    begin
      Val(EntryList[1], RXData.NumberReceived, Result1);
      RXData.Name := EntryList[2];
      if NumberEntries >= 3 then RXData.QTHString := EntryList[3];
    end
    else
      if StringIsAllNumbers(EntryList[2]) then
      begin
        Val(EntryList[2], RXData.NumberReceived, Result1);
        RXData.Name := EntryList[1];
        if NumberEntries >= 3 then RXData.QTHString := EntryList[3];
      end
      else
        if StringIsAllNumbers(EntryList[3]) then
        begin
          Val(EntryList[3], RXData.NumberReceived, Result1);
          RXData.Name := EntryList[1];
          RXData.QTHString := EntryList[2];
        end
        else
        begin
          ExchangeErrorMessage := TC_NOQSONUMBERFOUND;
          Exit;
        end;
  end

  else { We have four or more entries, use new procedure }
    if (NumberEntries = 4) then
    begin
      if StringIsAllNumbers(EntryList[2]) then
      begin
        Val(EntryList[2], RXData.NumberReceived, Result1);
        RXData.Name := EntryList[3];
        RXData.QTHString := EntryList[4];
      end
      else
        if StringIsAllNumbers(EntryList[3]) then
        begin
          Val(EntryList[3], RXData.NumberReceived, Result1);
          RXData.Name := EntryList[4];
          RXData.QTHString := EntryList[2];
        end
        else
          if StringIsAllNumbers(EntryList[1]) and StringIsAllNumbers(EntryList[4]) then
          begin
            Val(EntryList[4], RXData.NumberReceived, Result1);
            RXData.Name := EntryList[2];
            RXData.QTHString := EntryList[3];
          end;

    end
    else

      { Last chance - five or more entries }

      if StringIsAllNumbers(EntryList[NumberEntries - 2]) then
      begin
        Val(EntryList[NumberEntries - 2], RXData.NumberReceived, Result1);
        RXData.Name := EntryList[NumberEntries - 1];
        RXData.QTHString := EntryList[NumberEntries];
      end;

  if (RXData.Name = '') or ((RXData.QTHString = '') and not DX) then
  begin
    ExchangeErrorMessage := TC_MISSINGQTHANDORNAME;
    Exit;
  end;

  if length(RXData.Name) < length(RXData.QTHString) then
  begin
    if RXData.Name <> CD.GetName(RXData.Callsign) then
      if (length(RXData.Name) = 2) or (length(RXData.Name) = 3) then
      begin
        TempString := RXData.Name;
        RXData.Name := RXData.QTHString;
        RXData.QTHString := TempString;
      end;
  end;

  { The DX QTH gets put in by the GetDXQTH routine in LogDupe when the mult
    check was performmed.  Otherwise, FoundDomesticQTH will put the domestic
    QTH in there for us.  }

  if not DomesticCountryCall(RXData.Callsign) then
    ProcessQSONumberNameAndDomesticOrDXQTHExchange := True
  else
    if FoundDomesticQTH(RXData) then
      ProcessQSONumberNameAndDomesticOrDXQTHExchange := True
    else
    begin
      TempString := RXData.Name;
      RXData.Name := RXData.QTHString;
      RXData.QTHString := TempString;

      if FoundDomesticQTH(RXData) then
        ProcessQSONumberNameAndDomesticOrDXQTHExchange := True
      else
        ExchangeErrorMessage := TC_IMPROPERDOMESITCQTHORMISSINGNAME;

    end;
end;

procedure ProcessSSEntry(InputString: Str80);

var
  NumberStr, TempString                 : Str20;
  TempChar                              : Char;
begin
  TempString := InputString;

  NumberStr := '';

  { Gobble up all the leading numbers }

  while StringIsAllNumbers(Copy(TempString, 1, 1)) do
  begin
    NumberStr := NumberStr + Copy(TempString, 1, 1);
    Delete(TempString, 1, 1);
  end;

  if length(NumberStr) > 4 then Exit; { I don't like this! }

  if (TempString = '') then { All we had was numbers.  Is it a check? }
  begin
    if (length(NumberStr) = 2) then
    begin
      if SSEx.Check = '' then
        SSEx.Check := NumberStr
      else
        if (SSEx.Number = '') and (SSEx.Prec <> CHR(0)) then
          SSEx.Number := NumberStr;
    end
    else
      if SSEx.Number = '' then SSEx.Number := NumberStr;

    Exit;
  end;

  { Gee, this next one works even if the guy only entered A B or Q! }
  if length(TempString) > 0 then
  begin
    TempChar := TempString[1];
    if TempChar in SSPrec then
//      if (TempString = 'A') or (TempString = 'B') or (TempString = 'Q') or
//        (TempString = 'U') or (TempString = 'M') or (TempString = 'S') then
    begin
      if SSEx.Number = '' then SSEx.Number := NumberStr;
      if SSEx.Prec = CHR(0) then SSEx.Prec := TempString[1];
     // Exit;   {wli}
    end;
  end;
  { There is more than one character left in the string. }
  if length(TempString) > 0 then
  begin
    TempChar := TempString[1];
    if TempChar in SSPrec then
//    if (TempString[1] = 'A') or (TempString[1] = 'B') or (TempString[1] = 'Q') or (TempString[1] = 'U') or (TempString[1] = 'M') or (TempString[1] = 'S') then

          { We might have a precedence and more info.  The only legal thing after
            a real precedence is a number.  Otherwise, it must be part of the
            section (ie: AB or AL) }

      if StringIsAllNumbers(Copy(TempString, 2, 1)) then

      { Okay, we have the A/B/Q/U/M/S followed by a number.  We will
        assume this to be the precedence. }

      begin
        if SSEx.Number = '' then SSEx.Number := NumberStr;
        if SSEx.Prec = CHR(0) then SSEx.Prec := TempString[1];
        if SSEx.Check = '' then SSEx.Check := Copy(TempString, 2, 2);
        Delete(TempString, 1, 3);
        if SSEx.Section = '' then SSEx.Section := TempString;
        Exit;
      end;
  end;
  { We must be looking at a check and section, or maybe just a section }

  if length(NumberStr) = 2 then
    if SSEx.Check = '' then SSEx.Check := NumberStr;

  if SSEx.Section = '' then SSEx.Section := TempString;
end;

function ProcessQSONumberPrecedenceCheckDomesticQTHExchange(Exchange: ShortString {Str80};
  var RXData: ContestExchange): boolean;

{ A new improved version!  It tries to maintain compatability with the old
  version, but allows the following:

  If an entry has one, two, three or four digits and the letter A, B or Q
  at the end, then it is assumed to be a number and a precedence.  The last
  of any of these type of entries is used.

  If an entry has two numbers and then at least two letters after it, it is
  assumed to be a check and a section.  Again, the last of any of these type
  of entries is used.

  If an entry is at least four chars long and does not start or end with a
  number or if it has a / in it, then it is assumed to be a callsign.  The
  call will override the callsign window call if it is different.  Again,
  the last on of these is used.
}

var
  Entries                               : array[0..10] of Str20;
  NumberEntries                         : integer;
  Entry, Result1                        : integer;

begin
  ProcessQSONumberPrecedenceCheckDomesticQTHExchange := False;

  Windows.ZeroMemory(@SSEx, SizeOf(SSEx));
  Windows.ZeroMemory(@Entries, SizeOf(Entries));
  if length(Exchange) < 6 then Exit;

  NumberEntries := 0;

  while (Exchange <> '') and (NumberEntries <= 10) do
  begin
    Entries[NumberEntries] := RemoveFirstString(Exchange);
    inc(NumberEntries);
  end;

  for Entry := NumberEntries - 1 downto 0 do
  begin
    ProcessSSEntry(Entries[Entry]);

    if (SSEx.Number <> '') and
      (SSEx.Prec <> CHR(0)) and
      (SSEx.Check <> '') and
      (SSEx.Section <> '') then
    begin
      Val(SSEx.Number, RXData.NumberReceived, Result1);
      if Result1 <> 0 then Exit;

      RXData.Precedence := SSEx.Prec;
      RXData.Check := StrToInt(SSEx.Check);

      if (length(SSEx.Check) <> 2) or not StringIsAllNumbers(SSEx.Check) then Exit;

      RXData.QTHString := SSEx.Section;

      if FoundDomesticQTH(RXData) then
      begin
        ProcessQSONumberPrecedenceCheckDomesticQTHExchange := True;
        Exit;
      end;
    end;
  end;
end;

function LooksLikeRST(Ex: Str80; var RST: Word {RSTString}; Mode: ModeType): boolean;

begin
  LooksLikeRST := False;

  if Mode = CW then
  begin
    if length(Ex) <> 3 then Exit;

    if (Ex[1] >= '1') and (Ex[1] <= '5') and
      (Ex[2] >= '1') and (Ex[2] <= '9') and
      (((Ex[3] >= '1') and (Ex[3] <= '9')) or (UpCase(Ex[3]) = 'A')) then
    begin
      LooksLikeRST := True;
      RST := StrToInt(Ex);
    end;
    Exit;
  end
  else
    case length(Ex) of

      2:
        if (Ex[1] >= '1') and (Ex[1] <= '5') and
          (Ex[2] >= '1') and (Ex[2] <= '9') then
        begin
          LooksLikeRST := True;
          RST := StrToInt(Ex);
        end;

      3:
        if UpperCase(Copy(Ex, length(Ex), 1)) = 'A' then
          if (ActiveBand = Band6) or (ActiveBand = Band2) then
            if (Ex[1] >= '1') and (Ex[1] <= '5') and
              (Ex[2] >= '1') and (Ex[2] <= '9') then
            begin
              LooksLikeRST := True;
              RST := StrToInt(Ex);
            end;
    end;

end;

function ValidAllJAPrefecture(Prefecture: Str20): boolean;

var
  PrefectureValue, Result1              : integer;

begin
  if Copy(Prefecture, 1, 1) = 'p' then Delete(Prefecture, 1, 1);

  Val(Prefecture, PrefectureValue, Result1);

  if Result1 <> 0 then
  begin
    ValidAllJAPrefecture := False;
    Exit;
  end;

  ValidAllJAPrefecture := ((PrefectureValue > 1) and (PrefectureValue < 51)) or
    ((PrefectureValue > 100) and (PrefectureValue < 115));
end;

function ProcessRSTAllJAPrefectureAndPrecedenceExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

{ Updated for new rules.  Exchange now RS(T) + Prefixture # + Power (A/B/C) }

var
  RSTString, PowerString, PrefectureString, TempString: Str20;
  ExchangeString                        : ShortString; {STR20} {WLI}
  Entries                               : array[0..10] of ShortString {Str20}; {WLI}
  NumberEntries                         : integer;
  Entry, Result1                        : integer;

begin
  Exchange := UpperCase(Exchange);
  //su(Exchange);

  RXData.RSTReceived := DefaultRST;

  ProcessRSTAllJAPrefectureAndPrecedenceExchange := False;

  { Get power out of the way }

  if StringHas(Exchange, 'H') then
  begin
    RXData.Precedence := 'H';
    Delete(Exchange, pos('H', Exchange), 1);
  end
  else
    if StringHas(Exchange, 'M') then
    begin
      RXData.Precedence := 'M';
      Delete(Exchange, pos('M', Exchange), 1);
    end
    else
      if StringHas(Exchange, 'L') then
      begin
        RXData.Precedence := 'L';
        Delete(Exchange, pos('L', Exchange), 1);
      end
      else
        if StringHas(Exchange, 'P') then
        begin
          RXData.Precedence := 'P';
          Delete(Exchange, pos('P', Exchange), 1);
        end;

  GetRidOfPostcedingSpaces(Exchange);

  NumberEntries := 0;

  ExchangeString := Exchange;

  while ExchangeString <> '' do
  begin
    Entries[NumberEntries] := RemoveFirstString(ExchangeString);
    GetRidOfPrecedingSpaces(Entries[NumberEntries]);
    inc(NumberEntries);
  end;

  if NumberEntries = 1 then { Everything as one entry }
  begin
    if ActiveMode = CW then
    begin
      case length(Entries[0]) of
        2, 3:
          if ValidAllJAPrefecture(Entries[0]) then
            RXData.QTHString := 'p' + Entries[0];

        4:
          if Copy(Entries[0], 2, 1) = '1' then { S + 3 dig Pref? }
            if ValidAllJAPrefecture(Copy(Entries[0], 2, 3)) then
            begin
              RXData.QTHString := 'p' + Copy(Entries[0], 2, 3);
                    //              RXData.RSTReceived[2] := Entries[0][1];
            end;

        5:
          if ValidAllJAPrefecture(Copy(Entries[0], 4, 2)) then
          begin
            RXData.QTHString := 'p' + Copy(Entries[0], 4, 2);
                  //            RXData.RSTReceived := Copy(Entries[0], 1, 3);
          end;

        6:
          if ValidAllJAPrefecture(Copy(Entries[0], 4, 3)) then
          begin
            RXData.QTHString := 'p' + Copy(Entries[0], 4, 3);
                  //            RXData.RSTReceived := Copy(Entries[0], 1, 3);
          end;

      end;
    end
    else
    begin { SSB }
      case length(Entries[0]) of

        2:
          if ValidAllJAPrefecture(Entries[0]) then
            RXData.QTHString := 'p' + Entries[0];

        3:
          if ValidAllJAPrefecture(Entries[0]) then
            RXData.QTHString := 'p' + Entries[0]
          else
            if ValidAllJAPrefecture(Copy(Entries[0], 2, 2)) then
            begin
              RXData.QTHString := Copy(Entries[0], 2, 2);
                    //              RXData.RSTReceived[2] := Entries[0][1];
            end;

        4:
          if Copy(Entries[0], 2, 1) = '1' then
          begin
            if ValidAllJAPrefecture(Copy(Entries[0], 2, 3)) then
            begin
              RXData.QTHString := 'p' + Copy(Entries[0], 2, 3);
                      //              RXData.RSTReceived[2] := Entries[0][1];
            end;
          end
          else
            if ValidAllJAPrefecture(Copy(Entries[0], 3, 2)) then
            begin
              RXData.QTHString := 'p' + Copy(Entries[0], 3, 2);
                    //              RXData.RSTReceived := Copy(Entries[0], 1, 2);
            end;

        5:
          if ValidAllJAPrefecture(Copy(Entries[0], 3, 3)) then
          begin
            RXData.QTHString := 'p' + Copy(Entries[0], 3, 3);
                  //            RXData.RSTReceived := Copy(Entries[0], 1, 2);
          end;

      end;

    end;
  end;

  { Two entries to look at }

  if NumberEntries = 2 then
  begin
    if ValidAllJAPrefecture(Entries[0]) then
      if not ValidAllJAPrefecture(Entries[1]) then
      begin
            {
                    RXData.QTHString := Entries[0];

                    case length(Entries[1]) of
                      1: RXData.RSTReceived[2] := Entries[1][1];

                      2:
                        if ActiveMode = Phone then
                          RXData.RSTReceived := Entries[1];

                      3:
                        if ActiveMode = CW then
                          RXData.RSTReceived := Entries[1];
                    end;
            }
      end;

    if ValidAllJAPrefecture(Entries[1]) then
      if not ValidAllJAPrefecture(Entries[0]) then
      begin
        RXData.QTHString := Entries[1];
            {
                    case length(Entries[0]) of
                      1: RXData.RSTReceived[2] := Entries[0][1];

                      2:
                        if ActiveMode = Phone then
                          RXData.RSTReceived := Entries[0];

                      3:
                        if ActiveMode = CW then
                          RXData.RSTReceived := Entries[0];

                    end;
                  }
      end;

    if ValidAllJAPrefecture(Entries[0]) then
      if ValidAllJAPrefecture(Entries[1]) then { Both valid }
      begin
            {
                    case length(Entries[0]) of
                      1: RXData.RSTReceived[2] := Entries[0][1];
                      2:
                        if ActiveMode = Phone then RXData.RSTReceived := Entries[0];
                      3:
                        if ActiveMode = CW then RXData.RSTReceived := Entries[0];
                    end;
            }
        RXData.QTHString := Entries[1];
      end;

  end;

  if not ValidAllJAPrefecture(RXData.QTHString) then Exit;
  if not FoundDomesticQTH(RXData) then Exit;

  ProcessRSTAllJAPrefectureAndPrecedenceExchange := RXData.Precedence <> '';
end;

function ProcessRSTAndAgeExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ The exchange must be made of only digits and spaces.  If the exchange has
  a space, the RS(T) is assumed to be the first entry, and the age the
  second.  You can enter just the strength of the RS(T) or the full report.
  The age must be two digits.  You can omit the space if you like.  The
  last two digits will be used for the age and the digits before that for
  the RS(T) information.                        }

var
  RSTString, AgeString, TempString      : Str20;
  ExchangeString                        : ShortString;
  Entries                               : array[0..10] of ShortString {Str20};
  NumberEntries                         : integer;
  Entry, Result1                        : integer;
  TempInt                               : integer;
begin
  RXData.RSTReceived := DefaultRST;

  ProcessRSTAndAgeExchange := False;

  if not StringIsAllNumbersOrSpaces(Exchange) then Exit;

  NumberEntries := 0;

  ExchangeString := Exchange;

  while ExchangeString <> '' do
  begin
    Entries[NumberEntries] := RemoveFirstString(ExchangeString);
    GetRidOfPrecedingSpaces(Entries[NumberEntries]);
    inc(NumberEntries);
  end;

  if (NumberEntries = 1) and ((length(Entries[0]) = 2) or (length(Entries[0]) = 3)) then
  begin
    TempInt := StrToInt(Entries[0]);
    if TempInt > 255 then Exit;
    RXData.Age := Byte(TempInt);
    ProcessRSTAndAgeExchange := True;
    Exit;
  end;

  if NumberEntries = 2 then
  begin
    if LooksLikeRST(Entries[0], RXData.RSTReceived, ActiveMode) then
      RXData.Age := StrToInt(Entries[1])
    else
      if LooksLikeRST(Entries[1], RXData.RSTReceived, ActiveMode) then
        RXData.Age := StrToInt(Entries[0])
      else
        RXData.Age := StrToInt(Entries[1]);

    ProcessRSTAndAgeExchange := RXData.Age <> 0 {length(RXData.Age) = 2};
    Exit;
  end;

  if NumberEntries = 3 then
  begin
    if LooksLikeRST(Entries[1], RXData.RSTReceived, ActiveMode) then
      RXData.Age := StrToInt(Entries[2])
    else
      if LooksLikeRST(Entries[2], RXData.RSTReceived, ActiveMode) then
        RXData.Age := StrToInt(Entries[1])
      else
        RXData.Age := StrToInt(Entries[2]);

    ProcessRSTAndAgeExchange := RXData.Age <> 0 {length(RXData.Age) = 2};
    Exit;
  end;

  case length(Exchange) of
    2:
      begin
        RXData.Age := StrToInt(Exchange);
        ProcessRSTAndAgeExchange := True;
      end;

    3:
      begin
        //        Delete(DefaultRST, 2, 1);
        //        Insert(Exchange[1], DefaultRST, 2);
        //        RXData.RSTReceived := DefaultRST;
        Delete(Exchange, 1, 1);
        RXData.Age := StrToInt(Exchange);
        ProcessRSTAndAgeExchange := RXData.Age <> 0 {length(RXData.Age) = 2};
      end;

    4:
      begin
        if ActiveMode <> Phone then Exit;
        //        RXData.RSTReceived := Copy(Exchange, 1, 2);
        RXData.Age := StrToInt(Copy(Exchange, 3, 2));
        ProcessRSTAndAgeExchange := True;
      end;

    5:
      begin
        if ActiveMode <> CW then Exit;
        //        RXData.RSTReceived := Copy(Exchange, 1, 3);
        RXData.Age := StrToInt(Copy(Exchange, 4, 2));
        ProcessRSTAndAgeExchange := True;
      end;
  end; { of case Length (Exchange) }
end;

function ProcessRSTAndFOCNumber(Exchange: Str80; var RXData: ContestExchange): boolean;
 begin
end;

function ProcessRSTAndPrefectureExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

var
  RSTString, TempString                 : ShortString {Str20};
  ExchangeString                        : Str80;
  Entries                               : array[0..3] of Str80;
  NumberEntries                         : integer;
  Entry, Result1                        : integer;

begin
  RXData.RSTReceived := DefaultRST;

  ProcessRSTAndPrefectureExchange := False;

  if not StringIsAllNumbersOrSpaces(Exchange) then Exit;

  if length(RXData.QTH.CountryID) < 2 then Exit;
  if not ((RXData.QTH.CountryID[1] = 'J') and (RXData.QTH.CountryID[2] in ['A', 'D'])) then Exit;

  NumberEntries := 0;

  ExchangeString := Exchange;

  while ExchangeString <> '' do
  begin
    Entries[NumberEntries] := RemoveFirstString(ExchangeString);
    GetRidOfPrecedingSpaces(Entries[NumberEntries]);
    inc(NumberEntries);
  end;

  if (NumberEntries = 1) then
  begin
    RXData.QTHString := {'p' +} Entries[0];
    ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
    Exit;
  end;

  if NumberEntries = 2 then
  begin
    if LooksLikeRST(Entries[0], RXData.RSTReceived, ActiveMode) then
      RXData.QTHString := Entries[1]
    else
      if LooksLikeRST(Entries[1], RXData.RSTReceived, ActiveMode) then
        RXData.QTHString := Entries[0]
      else
        RXData.QTHString := Entries[1];

    ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
    Exit;
  end;

{
  if NumberEntries = 3 then
  begin
    if LooksLikeRST(Entries[1], RXData.RSTReceived, ActiveMode) then
      RXData.QTHString := 'p' + Entries[2]
    else
      if LooksLikeRST(Entries[2], RXData.RSTReceived, ActiveMode) then
        RXData.QTHString := 'p' + Entries[1]
      else
        RXData.QTHString := 'p' + Entries[2];

    ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
    Exit;
  end;
}
  case length(Exchange) of
    2:
      begin
//        RXData.QTHString := 'p' + Exchange;
//        ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
      end;

    3:
      begin
{
        Delete(DefaultRST, 2, 1);
        Insert(Exchange[1], DefaultRST, 2);
        RXData.RSTReceived := DefaultRST;
        Delete(Exchange, 1, 1);
        RXData.QTHString := 'p' + Exchange;
        ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
}
      end;

    4:
      begin
{
        if ActiveMode <> Phone then Exit;
        RXData.RSTReceived := Copy(Exchange, 1, 2);
        RXData.QTHString := 'p' + Copy(Exchange, 3, 2);
        ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
}
      end;

    5:
      begin
{
        if ActiveMode <> CW then Exit;
        RXData.RSTReceived := Copy(Exchange, 1, 3);
        RXData.QTHString := 'p' + Copy(Exchange, 4, 2);
        ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
}
      end;
  end; { of case Length (Exchange) }
end;

function ProcessAgeAndQSONumberExchange(Exchange: ShortString; var RXData: ContestExchange): boolean;
begin
  Result := False;
  if length(Exchange) < 3 then Exit;
  //  if length(Exchange) > 5 then Exit;
  if not StringIsAllNumbers(Exchange) then Exit;
  RXData.Age := StrToInt(Copy(Exchange, 1, 2));
  RXData.NumberReceived := StrToInt(Copy(Exchange, 3, 10));
  Result := True;
end;

function ProcessRSTAndDomesticQTHExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

{ Any digits found at the start of the exchange will be used to determine
  the RS(T).  If the first character is not a digit, the default RS(T)
  will be used and the whole exchange will be used as the QTH. }

var
  TempString                            : Str80;
  QTHFound                              : boolean;

begin
  QTHFound := False;

  ProcessRSTAndDomesticQTHExchange := False;
  GetRidOfPrecedingSpaces(Exchange);
  GetRidOfPostcedingSpaces(Exchange);

  if not StringHas(Exchange, ' ') and not StringIsAllNumbers(Exchange) then
  begin
    RXData.RSTReceived := DefaultRST;
    RXData.QTHString := Exchange;
    ProcessRSTAndDomesticQTHExchange := FoundDomesticQTH(RXData);
    if Result = False then ExchangeErrorMessage := TC_IMPROPERDOMESITCQTH;
      {WLI}
//    if ActiveExchange = RSTZoneOrSocietyExchange then
//      if CONTEST <> IARU then RXData.Zone := CountryTable.GetITUZone(RXData.Callsign);
    Exit;
  end;

  while Exchange <> '' do
  begin
    TempString := RemoveLastString(Exchange);

    if StringIsAllNumbers(TempString) and (RXData.RSTReceived = 0) then
    begin
      if length(TempString) = 1 then
      begin

        case ActiveMode of
          CW: RXData.RSTReceived := 509 + (Ord(TempString[1]) - 48) * 10;
          Phone: RXData.RSTReceived := 50 + (Ord(TempString[1]) - 48);
        end;
      end
      else
        RXData.RSTReceived := StrToInt(TempString);
    end
    else
      if not QTHFound then
      begin
        RXData.QTHString := TempString;
        if FoundDomesticQTH(RXData) then QTHFound := True;
      end;
  end;

  if QTHFound then
  begin
    if RXData.RSTReceived = 0 then
      RXData.RSTReceived := DefaultRST;
    ProcessRSTAndDomesticQTHExchange := True;
      //      Exit;
  end
  else
    ExchangeErrorMessage := TC_IMPROPERDOMESITCQTH;

end;

{KK1L: 6.72}

function ProcessRSTAndJAPrefectureExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

{ A single entry is assumed to be the exchange and not RST. Two entries assume }
{ the RS(T) is the first provided it is 3 characters or less                   }

var
  TempString                            : Str80;
  QTHFound                              : boolean;

begin
  QTHFound := False;

  ProcessRSTAndJAPrefectureExchange := False;
  GetRidOfPrecedingSpaces(Exchange);
  GetRidOfPostcedingSpaces(Exchange);

  if not StringHas(Exchange, ' ') then
  begin
    RXData.RSTReceived := DefaultRST;
    RXData.QTHString := Exchange;
    ProcessRSTAndJAPrefectureExchange := FoundDomesticQTH(RXData);
    Exit;
  end;

  while Exchange <> '' do
  begin
    TempString := RemoveLastString(Exchange);

    if StringIsAllNumbers(TempString) and (RXData.RSTReceived = 0) and (length(TempString) < 4) then
    begin
      if length(TempString) = 1 then
      begin
        case ActiveMode of
          CW: RXData.RSTReceived := 509 + (Ord(TempString[1]) - 48) * 10;
          Phone: RXData.RSTReceived := 5 + (Ord(TempString[1]) - 48);
        end;
      end
      else
        RXData.RSTReceived := StrToInt(TempString)

    end
    else
      if not QTHFound then
      begin
        RXData.QTHString := TempString;
        if FoundDomesticQTH(RXData) then QTHFound := True;
      end;
  end;

  if QTHFound then
  begin
    if RXData.RSTReceived = 0 then
      RXData.RSTReceived := DefaultRST;
    ProcessRSTAndJAPrefectureExchange := True;
    Exit;
  end;

end;

function ProcessRSTAndQTHExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

var
  RSTString                             : Str20;

begin
  GetRidOfPrecedingSpaces(Exchange);
  GetRidOfPostcedingSpaces(Exchange);

  if Exchange = '' then
  begin
    ProcessRSTAndQTHExchange := False;
    Exit;
  end;

  ProcessRSTAndQTHExchange := True;

  RSTString := PrecedingString(Exchange, ' ');

  if StringIsAllNumbersOrSpaces(RSTString) then
  begin
    RXData.RSTReceived := StrToInt(RSTString);
    RXData.QTHString := PostcedingString(Exchange, ' ');
  end
  else
  begin
    RSTString := Exchange;

    while StringHas(RSTString, ' ') do
      RSTString := PostcedingString(RSTString, ' ');

    if StringIsAllNumbersOrSpaces(RSTString) then
    begin
      RXData.RSTReceived := StrToInt(RSTString);
      RXData.QTHString := Copy(Exchange, 1, length(Exchange) - length(RSTString) - 1);
    end
    else
    begin
      RXData.RSTReceived := DefaultRST;
      RXData.QTHString := Exchange;
    end;
  end;
end;

function ProcessRSTAndDomesticOrDXQTHExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

begin
  ProcessRSTAndDomesticOrDXQTHExchange := False;

  if DomesticCountryCall(RXData.Callsign) then
  begin
    ProcessRSTAndDomesticOrDXQTHExchange := ProcessRSTAndDomesticQTHExchange(Exchange, RXData);
    Exit;
  end;

//  if not ValidRST(Exchange, RXData.RSTReceived, ActiveMode) then Exit;
//  ProcessRSTAndDomesticOrDXQTHExchange := True;

  ProcessRSTAndDomesticOrDXQTHExchange := ProcessRSTAndQTHExchange(Exchange, RXData);
end;

function ProcessRSTNameAndQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
                                         (RS(T) = default, no QTH or name)
   Name                                  (RS(T) = default, no QTH)
   Name        QTH                       (RS(T) = default)
   Name        QTH         RS(T)         (Enter whole RS(T))
   Name        RS(T)                     (No QTH)
   Name        RS(T)       QTH           (Enter whole RS(T))
   RS(T)                                 (Enter whole RS(T), no QTH or name)
   RS(T)       Name                      (Enter whole RS(T), no QTH)
   RS(T)       QTH         Name          (Enter whole RS(T))             }

var
  FirstString, SecondString, ThirdString: Str10 {Str20};

begin
  ProcessRSTNameAndQTHExchange := True;

  if Exchange = '' then
  begin
    RXData.RSTReceived := DefaultRST;
    Exit;
  end;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if StringIsAllNumbers(FirstString) then
  begin
    RXData.RSTReceived := StrToInt(FirstString);
    if ThirdString <> '' then
    begin
      RXData.QTHString := SecondString;
      RXData.Name := ThirdString;
    end
    else
      RXData.Name := SecondString;
    Exit;
  end;

  if StringIsAllNumbers(SecondString) then
  begin
    RXData.Name := FirstString;
    RXData.RSTReceived := StrToInt(SecondString);
    RXData.QTHString := ThirdString;
    Exit;
  end;

  if StringIsAllNumbers(ThirdString) then
  begin
    RXData.Name := FirstString;
    RXData.QTHString := SecondString;
    RXData.RSTReceived := StrToInt(ThirdString);
    Exit;
  end;

  if ThirdString <> '' then
  begin
    ProcessRSTNameAndQTHExchange := False;
    Exit;
  end;

  RXData.Name := FirstString;
  RXData.QTHString := SecondString;
  RXData.RSTReceived := DefaultRST;
end;

procedure LookForCutNumbers(var Exchange: ShortString {Str80});

var
  TempString, NewExchange               : ShortString {Str80};
  Address                               : integer;

begin
  NewExchange := '';

  while Exchange <> '' do
  begin
    TempString := RemoveFirstString(Exchange);

    if not StringIsAllNumbers(TempString) then
    begin
      for Address := 1 to length(TempString) do
        case TempString[Address] of

          'T', 'O': TempString[Address] := '0';
          'A': TempString[Address] := '1';
          'U': TempString[Address] := '2';
          'E': TempString[Address] := '5';
          'N': TempString[Address] := '9';
        end;
    end;

    NewExchange := NewExchange + TempString + ' '
  end;

  GetRidOfPostcedingSpaces(NewExchange);
  Exchange := NewExchange;
end;

function ProcessRSTAndQSONumberExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2
   ---------   ---------
   RS(T)       QSO Number
   QSO Number                (RS(T) = default)

  You can enter just the strength of the RS(T) if you like.

  Cut QSO numbers are changed to numeric. }

var
  code                                  : integer;

begin
  ProcessRSTAndQSONumberExchange := False;

  LookForCutNumbers(Exchange);

  if StringIsAllNumbers(Exchange) then
  begin
    Val(Exchange, RXData.NumberReceived, code);
    if code <> 0 then Exit;
    RXData.RSTReceived := DefaultRST;
    ProcessRSTAndQSONumberExchange := True;
  end
  else
    if ValidRST(Exchange, RXData.RSTReceived, ActiveMode) then
    begin
      Exchange := RemoveFirstString(Exchange);
      Val(Exchange, RXData.NumberReceived, code);
      if code <> 0 then Exit;
      ProcessRSTAndQSONumberExchange := True;
    end
    else
      ExchangeErrorMessage := TC_NOQSONUMBERFOUND;
end;

function LooksLikePower(TestString: Str20): boolean;

{ Returns true if entry is all numbers, or all numbers with a W at the end }

var
  CharPos                               : integer;

begin
  LooksLikePower := False;

  if TestString = '' then Exit;

  TestString := UpperCase(TestString);

  for CharPos := 1 to length(TestString) do
  begin
    if not (TestString[CharPos] in ['0'..'9', 'W', 'M', 'R']) then Exit;
    {
    if ((TestString[CharPos] < '0') or (TestString[CharPos] > '9')) and
      (TestString[CharPos] <> 'W') and (TestString[CharPos] <> 'M') and
      (TestString[CharPos] <> 'R') then Exit;
    }
  end;

  LooksLikePower := True;
end;

function ProcessRSTPossibleDomesticQTHAndPowerExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ RST MaybeQTH and Power.  Power will either have numbers and a W in it, or
  four numbers (for ARCI member number) }

var
  FirstString, SecondString, ThirdString: {STRING} Str10;
  ThirdStringRST, SecondStringRST, FirstStringRST: ShortString;

begin
  ProcessRSTPossibleDomesticQTHAndPowerExchange := False;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if StringIsAllNumbers(ThirdString) and (length(ThirdString) <= 3) then
  begin
    ThirdStringRST := ThirdString;
    if not ValidRST(ThirdStringRST, RXData.RSTReceived, ActiveMode) then Exit;
  end
  else
    if StringIsAllNumbers(SecondString) and (length(SecondString) <= 3) then
    begin
      SecondStringRST := SecondString;
      if not ValidRST(SecondStringRST, RXData.RSTReceived, ActiveMode) then Exit;
    end
    else
      if StringIsAllNumbers(FirstString) and (length(FirstString) <= 3) then
      begin
        FirstStringRST := FirstString;
        if not ValidRST(FirstStringRST, RXData.RSTReceived, ActiveMode) then Exit;
      end
      else
        if ActiveMode = CW then
          RXData.RSTReceived := 599
        else
          RXData.RSTReceived := 59;

  if LooksLikePower(ThirdString) then
    RXData.Power := ThirdString
  else
    if LooksLikePower(SecondString) then
      RXData.Power := SecondString
    else
      if LooksLikePower(FirstString) then RXData.Power := FirstString;

  if (ThirdString <> '') and (not LooksLikePower(ThirdString)) then
    RXData.QTHString := ThirdString
  else
    if (SecondString <> '') and (not LooksLikePower(SecondString)) then
      RXData.QTHString := SecondString
    else
      if (FirstString <> '') and (not LooksLikePower(FirstString)) then
        RXData.QTHString := FirstString;

  if RXData.Power = '' then Exit;

  { RXData.DXQTH is only there if it is a DX call }

  if RXData.DXQTH = '' then
    ProcessRSTPossibleDomesticQTHAndPowerExchange := FoundDomesticQTH(RXData)
  else
    ProcessRSTPossibleDomesticQTHAndPowerExchange := True;
end;

function ProcessQSONumberAndPreviousQSONumber(Exchange: Str80; var RXData: ContestExchange): boolean;
var
  l                                     : integer;
begin
  Result := False;
  l := length(Exchange);
  if not (l in [4..6]) then
  begin
//    ExchangeErrorMessage := TC_NOTENOUGHINFOINEXCHANGE;
    Exit;
  end;
  if not StringIsAllNumbers(Exchange) then Exit;
//  RXData.Kids := Copy(Exchange, l - 3, 3);
//  RXData.NumberReceived := StrToInt(Copy(Exchange, 1, l - 3));
  RXData.NumberReceived := StrToInt(Exchange);
  Result := True;
end;

function ProcessRSTQSONumberAndDomesticQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   QTH                                    (RS(T) = default, QSO number = 1)
   QTH         QSO Number                 (RS(T) = default)
   QTH         RS(T)       QSO Number
   QSO Number  QTH                        (RS(T) = default)
   RS(T)       QTH         QSO Number
   RS(T)       QSO Number  QTH

  You can enter just the strength of the RS(T) if desired.      }

var
  NumberString, FirstString, SecondString, ThirdString: Str10;

begin
  ProcessRSTQSONumberAndDomesticQTHExchange := False;
  if Exchange = '' then Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if not StringIsAllNumbers(FirstString) then
  begin
    RXData.QTHString := FirstString;
    if ThirdString <> '' then
      NumberString := SecondString + ' ' + ThirdString
    else
      NumberString := SecondString;
  end
  else
    if not StringIsAllNumbers(SecondString) then
    begin
      RXData.QTHString := SecondString;
      if ThirdString <> '' then
        NumberString := FirstString + ' ' + ThirdString
      else
        NumberString := FirstString;
    end
    else
    begin
      RXData.QTHString := ThirdString;
      NumberString := FirstString + ' ' + SecondString;
    end;

  if ProcessRSTAndQSONumberExchange(NumberString, RXData) then
    if RXData.QTHString <> '' then
      ProcessRSTQSONumberAndDomesticQTHExchange := FoundDomesticQTH(RXData);
end;

function ProcessRSTQSONumberAndGridSquareExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   Grid                                    (RS(T) = default, QSO number = 1)
   Grid        QSO Number                  (RS(T) = default)
   Grid        RS(T)       QSO Number
   QSO Number  Grid                        (RS(T) = default)
   RS(T)       Grid        QSO Number
   RS(T)       QSO Number  Grid

  You can enter just the strength of the RS(T) if desired.      }

var
  NumberString, FirstString, SecondString, ThirdString: Str10;

begin
  ProcessRSTQSONumberAndGridSquareExchange := False;
  if Exchange = '' then Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if not StringIsAllNumbers(FirstString) then
  begin
    RXData.QTHString := FirstString;

    if ThirdString <> '' then
      NumberString := SecondString + ' ' + ThirdString
    else
      NumberString := SecondString;
  end
  else
    if not StringIsAllNumbers(SecondString) then
    begin
      RXData.QTHString := SecondString;
      if ThirdString <> '' then
        NumberString := FirstString + ' ' + ThirdString
      else
        NumberString := FirstString;
    end
    else
    begin
      RXData.QTHString := ThirdString;
      NumberString := FirstString + ' ' + SecondString;
    end;

  if ProcessRSTAndQSONumberExchange(NumberString, RXData) then
    if GoodLookingGrid(RXData.QTHString) then
      ProcessRSTQSONumberAndGridSquareExchange := FoundDomesticQTH(RXData);
end;

function ProcessRSTQSONumberAndPossibleDomesticQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   QSO Number                             (RS(T) = default, No QTH)
   QTH                                    (RS(T) = default, QSO number = 1)
   QTH         QSO Number                 (RS(T) = default)
   QTH         RS(T)       QSO Number
   QSO Number  QTH                        (RS(T) = default)
   RS(T)       QTH         QSO Number
   RS(T)       QSO Number                 (No QTH)
   RS(T)       QSO Number  QTH

  You can enter just the strength of the RS(T) if desired.      }

var
  NumberString, FirstString, SecondString, ThirdString: Str10;

begin
  ProcessRSTQSONumberAndPossibleDomesticQTHExchange := False;
  if Exchange = '' then Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if not StringIsAllNumbers(FirstString) then
  begin
    RXData.QTHString := FirstString;

    if ThirdString <> '' then
      NumberString := SecondString + ' ' + ThirdString
    else
      NumberString := SecondString;
  end
  else
    if not StringIsAllNumbers(SecondString) then
    begin
      RXData.QTHString := SecondString;
      if ThirdString <> '' then
        NumberString := FirstString + ' ' + ThirdString
      else
        NumberString := FirstString;
    end
    else
    begin
      RXData.QTHString := ThirdString;
      NumberString := FirstString + ' ' + SecondString;
    end;

  if ProcessRSTAndQSONumberExchange(NumberString, RXData) then
    if RXData.QTHString = '' then
      ProcessRSTQSONumberAndPossibleDomesticQTHExchange := True
    else
      ProcessRSTQSONumberAndPossibleDomesticQTHExchange := FoundDomesticQTH(RXData);
end;

{KK1L: 6.73 For Michigan QSO Party NOT WORKING!!!!!!}

function ProcessQSONumberAndPossibleDomesticQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   QSO Number                             (No QTH)
   QTH                                    (QSO number = 1)
   QTH         QSO Number
   QSO Number  QTH                                            }

var
  NumberString, FirstString, SecondString, ThirdString: Str10;

begin
  ProcessQSONumberAndPossibleDomesticQTHExchange := False;
  if Exchange = '' then Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if not StringIsAllNumbers(FirstString) then
  begin
    RXData.QTHString := FirstString;
    NumberString := SecondString;
  end
  else
    if not StringIsAllNumbers(SecondString) then
    begin
      RXData.QTHString := SecondString;
      NumberString := FirstString;
    end;

  if StringIsAllNumbers(NumberString) then
    if RXData.QTHString = '' then
      ProcessQSONumberAndPossibleDomesticQTHExchange := True
    else
      ProcessQSONumberAndPossibleDomesticQTHExchange := FoundDomesticQTH(RXData);
end;

function ProcessNZFieldDayExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The RST is
  optional.  The following formats will work:

  If in New Zealand:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   RST         QSO Number  Zone
   QSO Number  Zone

  You can enter just the strength of the RS(T) if desired.

  If not in New Zealand:

   Entry  #1   Entry  #2
   ---------   ---------
   RST         QSO Number
   QSO Number

    }

var
  NumberString, FirstString, SecondString, ThirdString: Str10;

begin
  ProcessNZFieldDayExchange := False;
  if Exchange = '' then Exit;

  if CountryTable.GetCountryID(RXData.QTH.Country) = 'ZL' then
  begin
    ParseExchange(Exchange, FirstString, SecondString, ThirdString);

    if ThirdString <> '' then
    begin
      if length(ThirdString) > 2 then Exit;
      RXData.Zone := StrToInt(ThirdString);
    end
    else
    begin
      if (SecondString = '') or (length(SecondString) > 2) then Exit;
      RXData.Zone := StrToInt(SecondString);
          //      if length(RXData.Zone) = 1 then RXData.Zone := '0' + RXData.Zone;
    end;

      //    if length(RXData.Zone) = 1 then RXData.Zone := '0' + RXData.Zone;
    RemoveLastString(Exchange);

      //    if not StringIsAllNumbers(RXData.Zone) then Exit;
  end;

  if ProcessRSTAndQSONumberExchange(Exchange, RXData) then
    ProcessNZFieldDayExchange := True;

end;

function ProcessRSTQTHNameAndFistsNumberOrPowerExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ 599 QTH NAME FISTS# or 599 QTH NAME POWER.  Assumed to be FISTS # unless
  the number has a W at the end of it.  RST is optional.  QTH is required
  even for DX.  Name can only be one word.  Spaces required for each entry. }

var
  NumberEntries, Address, Result1       : integer;
  DX                                    : boolean;
  EntryList                             : EntryArray;

begin
  ProcessRSTQTHNameAndFistsNumberOrPowerExchange := False;

  if length(Exchange) < 4 then
  begin
    ExchangeErrorMessage := TC_NOTENOUGHINFOINEXCHANGE;
    Exit;
  end;

  DX := not DomesticCountryCall(RXData.Callsign);

  ParseExchangeIntoFields(Exchange, EntryList, NumberEntries);

  if StringIsAllNumbers(EntryList[1]) then
  begin
    RXData.RSTReceived := StrToInt(EntryList[1]);

      { Remove the RST from the entry list }

    if NumberEntries > 1 then
      for Address := 1 to NumberEntries - 1 do
        EntryList[Address] := EntryList[Address + 1];
    dec(NumberEntries);
  end
  else
    RXData.RSTReceived := 599; { Use default RST }

  { We have removed the RST if it was there.  Should have QTH, Name
    and power or member # }

  if NumberEntries < 2 then Exit; { Not enough data }

  if (NumberEntries = 2) and DX then
  begin
    RXData.QTHString := RXData.QTH.CountryID;
    RXData.Name := EntryList[1];

    if NumberEntries > 1 then
      for Address := 1 to NumberEntries - 1 do
        EntryList[Address] := EntryList[Address + 1];
    dec(NumberEntries);
  end
  else
  begin
    RXData.QTHString := EntryList[1];
    RXData.Name := EntryList[2];

    for Address := 1 to NumberEntries - 2 do
      EntryList[Address] := EntryList[Address + 2];
    NumberEntries := NumberEntries - 2;
  end;

  { We should now just have the power or member number left }

  if NumberEntries <> 1 then Exit;

  if StringIsAllNumbers(EntryList[1]) then { member number }
    Val(EntryList[1], RXData.NumberReceived, Result1)
  else
    RXData.Power := EntryList[1];

  if DX then
    ProcessRSTQTHNameAndFistsNumberOrPowerExchange := True
  else
    ProcessRSTQTHNameAndFistsNumberOrPowerExchange := FoundDomesticQTH(RXData);
end;

function ProcessRSTQSONumberAndRandomCharactersExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   Chars                                  (RS(T) = default, QSO number = 1)
   Chars       QSO Number                 (RS(T) = default)
   Chars       RS(T)       QSO Number
   QSO Number  Chars                      (RS(T) = default)
   RS(T)       Chars       QSO Number
   RS(T)       QSO Number  Chars

  You can enter just the strength of the RS(T) if desired.      }

var
  NumberString, FirstString, SecondString, ThirdString: Str10;

begin
  ProcessRSTQSONumberAndRandomCharactersExchange := False;
  if Exchange = '' then Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if not StringIsAllNumbers(FirstString) then
  begin
    RXData.RandomCharsReceived := FirstString;
    if ThirdString <> '' then
      NumberString := SecondString + ' ' + ThirdString
    else
      NumberString := SecondString;
  end
  else
    if not StringIsAllNumbers(SecondString) then
    begin
      RXData.RandomCharsReceived := SecondString;
      if ThirdString <> '' then
        NumberString := FirstString + ' ' + ThirdString
      else
        NumberString := FirstString;
    end
    else
    begin
      RXData.RandomCharsReceived := ThirdString;
      NumberString := FirstString + ' ' + SecondString;
    end;

  if ProcessRSTAndQSONumberExchange(NumberString, RXData) then
    ProcessRSTQSONumberAndRandomCharactersExchange := (length(RXData.RandomCharsReceived) = 5) and
      (length(RXData.RandomCharsSent) = 5);

end;

function ProcessRSTAndPostalCodeExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ Legal entries HA1 1TA, RS(T) HA1 1TA or HA1 1TA RS(T) }

var
  FirstString, SecondString, ThirdString: Str10;

begin
  ProcessRSTAndPostalCodeExchange := False;
  if Exchange = '' then Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if not StringIsAllNumbers(FirstString) then
  begin
    RXData.PostalCode := FirstString + ' ' + SecondString;
    RXData.RSTReceived := StrToInt(ThirdString);

    if RXData.RSTReceived = 0 then
      RXData.RSTReceived := DefaultRST;
  end
  else
  begin
    RXData.PostalCode := SecondString + ' ' + ThirdString;
    RXData.RSTReceived := StrToInt(FirstString);
  end;

  RXData.QTHString := Copy(RXData.PostalCode, 1, 2);

  ProcessRSTAndPostalCodeExchange := FoundDomesticQTH(RXData);
end;

function ProcessRSTAndQSONumberOrDomesticQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;
label
  1;
begin
  if (ActiveQSOPointMethod = RACQSOPointMethod) and (Copy(RXData.Callsign, 1, 3) = 'VE0') then
  begin
    ProcessRSTAndQSONumberOrDomesticQTHExchange := ProcessRSTAndQSONumberExchange(Exchange, RXData);
    Exit;
  end;

  if ActiveQSOPointMethod = CupUA1DZMethod then
  begin
    if CountryTable.GetCountryID(CountryTable.GetCountry(RXData.Callsign, True)) = 'UA' then
    begin
      if (GetRussiaOblastID(RXData.Callsign) = 'SP') or
        (GetRussiaOblastID(RXData.Callsign) = 'LO')
        or (pos('/1', RXData.Callsign) <> 0)
        then goto 1;
    end;
    ProcessRSTAndQSONumberOrDomesticQTHExchange := ProcessRSTAndQSONumberExchange(Exchange, RXData);
    Exit;
  end;

  if ActiveQSOPointMethod = ArktikaSpringQSOPointMethod then
  begin
    if Tree.StringIsAllNumbersOrSpaces(Exchange) then
      ProcessRSTAndQSONumberOrDomesticQTHExchange := ProcessRSTAndQSONumberExchange(Exchange, RXData)
    else
      ProcessRSTAndQSONumberOrDomesticQTHExchange := ProcessRSTAndDomesticQTHExchange(Exchange, RXData);
    Exit;
  end;

  1:
  if DomesticCountryCall(RXData.Callsign) then
    ProcessRSTAndQSONumberOrDomesticQTHExchange := ProcessRSTAndDomesticQTHExchange(Exchange, RXData)
  else
    ProcessRSTAndQSONumberOrDomesticQTHExchange := ProcessRSTAndQSONumberExchange(Exchange, RXData);
end;

function ProcessRSTZoneAndPossibleDomesticQTHExchange(Exchange: Str80; var RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   RS(T)       Zone        QTH
   RS(T)       Zone                      (No QTH)
   Zone                                  (RS(T) = default, no QTH)
   Zone        QTH                       (RS(T) = default)

  You can enter just the strength of the RS(T) if you like.       }

var

  FirstString, SecondString, ThirdString: Str10;
  FirstStringRST, SecondStringRST, ThirdStringRST: ShortString;

begin
  ProcessRSTZoneAndPossibleDomesticQTHExchange := False;
  if Exchange = '' then Exit;

  RXData.QTHString := '';

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if ThirdString <> '' then
  begin
    FirstStringRST := FirstString;
    if not ValidRST(FirstStringRST, RXData.RSTReceived, ActiveMode) then Exit;
    RXData.Zone := StrToInt(SecondString);
    RXData.QTHString := ThirdString;
  end
  else
    if SecondString <> '' then
    begin
      if not StringIsAllNumbers(SecondString) then
      begin
        RXData.RSTReceived := DefaultRST;
        RXData.Zone := StrToInt(FirstString);
        RXData.QTHString := SecondString;
      end
      else
      begin
        if not ValidRST(FirstStringRST, RXData.RSTReceived, ActiveMode) then Exit;
        RXData.Zone := StrToInt(SecondString);
      end;
    end
    else
    begin
      RXData.RSTReceived := DefaultRST;
      RXData.Zone := StrToInt(Exchange);
    end;

  //  if not StringIsAllNumbers(RXData.Zone) then Exit;

  //  if length(RXData.Zone) = 1 then RXData.Zone := '0' + RXData.Zone;

  if RXData.QTHString <> '' then
    ProcessRSTZoneAndPossibleDomesticQTHExchange := FoundDomesticQTH(RXData)
  else
    ProcessRSTZoneAndPossibleDomesticQTHExchange := True;
end;

function ProcessRSTAndPowerExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2
   ---------   ---------
   RS(T)       Power
   Power                     (RS(T) = default)

  You can enter just the strength of the RS(T) if you like.       }

begin
  ProcessRSTAndPowerExchange := False;

  if StringHas(Exchange, ' ') then
  begin
    if not ValidRST(Exchange, RXData.RSTReceived, ActiveMode) then Exit;
    GetRidOfPrecedingSpaces(Exchange);
    RXData.Power := Exchange;
  end
  else
  begin
    RXData.RSTReceived := DefaultRST;
    RXData.Power := Exchange;
  end;

  ProcessRSTAndPowerExchange := RXData.Power <> '';
end;

function ProcessRSTAndZoneExchange(Exchange: ShortString {Str80}; var RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2
   ---------   ---------
   RS(T)       Zone
   Zone                       (RS(T) = default)
   Zone        RST            (RST must be three characters, CW only)

  You can enter just the strength of the RS(T) if you like.    }

var
  FirstString, SecondString, ThirdString: Str10;

begin
  ProcessRSTAndZoneExchange := False;
  if not StringIsAllNumbersOrSpaces(Exchange) then Exit;
  RXData.RSTReceived := DefaultRST;

  if StringHas(Exchange, ' ') then
  begin
    if ActiveMode = CW then
    begin
      ParseExchange(Exchange, FirstString, SecondString, ThirdString);

      if (length(SecondString) = 3) and (length(FirstString) < 3) then
      begin
        RXData.RSTReceived := StrToInt(SecondString);
        RXData.Zone := StrToInt(FirstString);
              //        if length(RXData.Zone) = 1 then          Insert('0', RXData.Zone, 1);
        ProcessRSTAndZoneExchange := True;
        Exit;
      end;
    end;

    if not ValidRST(Exchange, RXData.RSTReceived, ActiveMode) then Exit;
    GetRidOfPrecedingSpaces(Exchange);
  end;

  case length(Exchange) of
    1:
      begin
        RXData.Zone := {'0' + } StrToInt(Exchange);
        ProcessRSTAndZoneExchange := True;
      end;

    2:
      begin
        RXData.Zone := StrToInt(Exchange);

        if ActiveZoneMult = EUHFCYear then
        begin
          ProcessRSTAndZoneExchange := True;
          Exit;
        end;

        if (CountryTable.ZoneMode = CQZoneMode) and (ActiveZoneMult <> JAPrefectures) then
          if (Exchange[1] > '5') or ((Exchange[1] = '4') and (Exchange[2] >= '1')) then
            Exit;

        if ActiveZoneMult = JAPrefectures then
          if (Exchange[1] > '6') or ((Exchange[1] = '5') and (Exchange[2] >= '1')) then
            Exit;

        ProcessRSTAndZoneExchange := True;
      end;

  end;
end;

procedure SaveLogFileToFloppy;
begin
  if TR4W_FLOPPY_FILENAME[0] = #0 then Exit;
  asm
  lea  eax,TR4W_FLOPPY_FILENAME
  push eax
  lea  eax,TR4W_LOG_FILENAME
  push eax
  end;
  wsprintf(QuickDisplayBuffer, TC_SAVINGTO);
  asm add esp,16  end;
  QuickDisplay(QuickDisplayBuffer);

  if not Windows.CopyFile(TR4W_LOG_FILENAME, TR4W_FLOPPY_FILENAME, False) then
  begin
    SysErrorMessage(GetLastError);
    asm
    push eax
    lea  eax,TR4W_FLOPPY_FILENAME
    push eax
    end;
    wsprintf(QuickDisplayBuffer, '%s: %s');
    asm add esp,16  end;
    QuickDisplay(QuickDisplayBuffer);

    DoABeep(Warning);
  end
  else
  begin
    asm
      lea eax,  TR4W_FLOPPY_FILENAME
      push eax
    end;
    wsprintf(QuickDisplayBuffer, TC_FILESAVEDTOSUCCESSFULLY);
    asm add esp,12 end;
    QuickDisplay(QuickDisplayBuffer);
  end;
{
  if FloppyFileSaveName = '' then Exit;
  Windows.ZeroMemory(@TR4W_FLOPPY_FILENAME, SizeOf(TR4W_FLOPPY_FILENAME));
  I := pos(':', FloppyFileSaveName);
  if I = 0 then I := 3 else I := 0;
  TR4W_FLOPPY_FILENAME[0] := 'A';
  TR4W_FLOPPY_FILENAME[1] := ':';
  TR4W_FLOPPY_FILENAME[2] := '/';
  Windows.CopyMemory(@TR4W_FLOPPY_FILENAME[I], @FloppyFileSaveName[1], length(FloppyFileSaveName));
  asm
  lea  eax,TR4W_FLOPPY_FILENAME
  push eax
  lea  eax,TR4W_LOG_FILENAME
  push eax
  end;
  wsprintf(QuickDisplayBuffer, TC_SAVINGTO);
  asm add esp,16  end;
  QuickDisplay(QuickDisplayBuffer);

  if not Windows.CopyFile(TR4W_LOG_FILENAME, TR4W_FLOPPY_FILENAME, False) then
  begin
    SysErrorMessage(GetLastError);
    asm
    push eax
    lea  eax,TR4W_FLOPPY_FILENAME
    push eax
    end;
    wsprintf(QuickDisplayBuffer, '%s: %s');
    asm add esp,16  end;
    QuickDisplay(QuickDisplayBuffer);

    DoABeep(Warning);
  end
  else
  begin
    if I <> 0 then QuickDisplay(TC_FILESAVEDTOFLOPPYSUCCESSFULLY)
    else
    begin
      asm
      lea  eax,FloppyFileSaveName[1]
      push eax
      end;
      wsprintf(QuickDisplayBuffer, TC_FILESAVEDTOSUCCESSFULLY);
      asm add esp,12 end;
      QuickDisplay(QuickDisplayBuffer);
    end;
  end;
}
end;

procedure RestoreRadioFrequency(Radio: RadioType);

begin
  {    IF Remember [Radio].Frequency = 0 THEN Exit;
      WITH Remember [Radio] DO SetRadioFreq (Radio, Frequency, Mode, 'A');
     }
end;

procedure ReviewBackCopyFiles;

var
  FileNames                             : FileNameRecord;
  LastFile                              : Str40;
  Command                               : Str20;

begin
  {WLI}
  {    SaveSetAndClearActiveWindow (BigWindow);
      LastFile := '';

      REPEAT
          QuickDisplay ('Use cursor to select the file you want to process and press RETURN');
          ClrScr;
          WriteLnCenter ('BACKCOPY FILE REVIEW');
          WriteLn;
          WriteLn ('Select backcopy file to review or delete : ');

          LastFile := ShowDirectoryAndSelectFile ('*.bcp', '', False);

          IF (LastFile = '') OR (LastFile = EscapeKey) THEN
              BEGIN
              //RestorePreviousWindow;
              VisibleDupesheetRemoved := True;
              Exit;
              END;

          REPEAT
              Command := UpperCase (QuickEditResponse (LastFile + ': R to review   D to delete  ESCAPE to quit', 1));
              IF Command = 'R' THEN DVPListenMessage (LastFile, False);
              IF Command = 'D' THEN DeleteFile (LastFile);
          UNTIL (Command = '') OR (Command = 'D') OR (Command = EscapeKey);

      UNTIL False;
     }
end;

function GetCorrectedCallFromExchangeString(var ExchangeString: ShortString {Str80}): Str80;

var
  PotentialCall, TempString             : ShortString {Str40};

begin
  GetCorrectedCallFromExchangeString := '';

  TempString := ExchangeString;

  if CallsignUpdateEnable and StringHas(TempString, ' ') then
    while TempString <> '' do
    begin
      PotentialCall := RemoveLastString(TempString);

      if LooksLikeACallSign(PotentialCall) then
      begin
        GetCorrectedCallFromExchangeString := PotentialCall;

            { Delete all the stuff we have }

        Delete(ExchangeString, 1, length(TempString));

            { Remove the callsign }

        RemoveFirstString(ExchangeString);

            { Rebuild the exchange string without the callsign }

        ExchangeString := TempString + ' ' + ExchangeString;
        Exit;
      end;
    end;
end;

function ISentThisMultiMessage(MultMessage: string): boolean;

{ Works for both N6TR and K1EA network }

var
  LookAddress                           : integer;
  s1                                    : string;

begin
  ISentThisMultiMessage := False;

  if NetDebug then
  begin
      //    SaveSetAndClearActiveWindow(DupeSheetWindow);

    WriteLn('ISentThisMultiMessage called with : ');
      {
          if K1EANetworkEnable then
            WriteLn(Copy(MultMessage, 1, length(MultMessage) - 1))
          else
            WriteLn(Copy(MultMessage, 10, ord(MultMessage[8])));
      }
    WriteLn;
    WriteLn('The following messages are in the message list : ');
  end;
  {
    if K1EANetworkEnable then // K1EA network
    begin
      if MultMessage[2] = K1EAStationID then
      begin
        ISentThisMultiMessage := True;

        if NetDebug then
        begin
          WriteLn('I found my station ID - found!');
                       ////RestorePreviousWindow;
          Exit;
        end;

      end
      else
        if NetDebug then
          WriteLn('This is not my message');
    end

    else // N6TR Network

    begin
           // See if there is anything in the list to check

      if FirstMultiMessage = LastMultiMessage then
      begin
        if NetDebug then
        begin
          WriteLn('Nothing in the remember list.');
                       //RestorePreviousWindow;
        end;
        Exit;
      end;

      LookAddress := LastMultiMessage;

      while LookAddress <> FirstMultiMessage do
      begin
        s1 := MultiRememberBuffer^[LookAddress].message;

        if NetDebug and (not MultiRememberBuffer^[LookAddress].QSL) then
          WriteLn(Copy(s1, 10, ord(s1[8])));

        if (Copy(s1, 1, 5) = Copy(MultMessage, 1, 5)) and
          (s1[8] = MultMessage[8]) and
          (Copy(s1, 10, ord(s1[8])) = Copy(MultMessage, 10, ord(s1[8]))) then
        begin
          if NetDebug then
          begin
            WriteLn('Found it!!');
                             //RestorePreviousWindow;
          end;

          MultiRememberBuffer^[LookAddress].QSL := True;

          ISentThisMultiMessage := True;
          Exit;
        end;

        LookAddress := (LookAddress + 1) mod MultiMessageBufferSize;
      end;
    end;
  }
  if NetDebug then
  begin
    WriteLn('Entry not found.');
      //RestorePreviousWindow;
  end;
end;

procedure CheckForLostMultiMessages;

{ This procedure will look at the MultiMessageMemory and see if there are
  any entries that should either be resent or deleted.  It will stop after
  it finds one to send so it doesn't hog the computer too long. }

var
  LookAddress                           : integer;

begin
  LookAddress := LastMultiMessage;

  while LookAddress <> FirstMultiMessage do
  begin
    with MultiRememberBuffer^[LookAddress] do
      if not QSL then
      begin
        if RetryCount <= 10 then
        begin

          if ((RetryCount < 2) and (ElaspedSec100(TimeMark) > MultiRetryTime * 100) or
            (RetryCount >= 2) and (ElaspedSec100(TimeMark) > 3000)) then
          begin
            if RetryCount >= 3 then DoABeep(single);
            SendMultiMessage(Message);
            MarkTime(TimeMark);
            inc(RetryCount);
          end;
        end;

        if (RetryCount >= 5) and (Warnings = 0) then
        begin
          DoABeep(Warning);
          QuickDisplay('Please check multi network');
                //                        ReminderPostedCount := 60;
          Warnings := 1;
        end;

        if (RetryCount > 10) and (Warnings = 1) then
        begin
          DoABeep(Warning);
          QuickDisplay('Possible data loss on multi network.');
                //                        ReminderPostedCount := 60;
          Warnings := 2;
        end;

      end;

    LookAddress := (LookAddress + 1) mod MultiMessageBufferSize;
  end;
end;

function ValidCheckSum(Message: string): boolean;

{ Returns TRUE if the check sum looks valid for the message.  Works for
  both K1EA and N6TR network. }

var
  CharPointer                           : integer;
  CheckSum                              : Word;
  K1EACheckSum                          : Byte;
  TempString                            : string;

begin
  if length(Message) < 8 then
  begin
    ValidCheckSum := False;
    Exit;
  end;

  if 1 = 1 {K1EANetworkEnable} then { K1EA network }
  begin
    K1EACheckSum := 0;

      { We count up to all but the last character }

    for CharPointer := 1 to length(Message) - 1 do
      K1EACheckSum := K1EACheckSum + Ord(Message[CharPointer]);

    K1EACheckSum := K1EACheckSum or $80;

    ValidCheckSum := K1EACheckSum = Ord(Message[length(Message)]);

      {       ValidCheckSum := True;}

    if K1EACheckSum <> Ord(Message[length(Message)]) then
      if NetDebug then
      begin
        TempString := '*** NOT VALID CHECKSUM BUT USED ANYWAY ***';
        BlockWrite(NetDebugBinaryInput, TempString[1], length(TempString));
      end;
  end

  else { TR network }
  begin
    CheckSum := 0;

    for CharPointer := 1 to 5 do
      CheckSum := CheckSum + Ord(Message[CharPointer]);

    for CharPointer := 8 to length(Message) do
      CheckSum := CheckSum + Ord(Message[CharPointer]);

    ValidCheckSum := (Hi(CheckSum) = Ord(Message[6])) and
      (Lo(CheckSum) = Ord(Message[7]));
  end;
end;

function TimeToDie(var Message: string): boolean;

{ This function will decrement the hop count in the message.  If it has
  expired, it will return TRUE.  Will always return False if we are in
  the K1EANetworkMode }

var
  TimeToLive                            : Byte;
  CheckSum                              : Word;

begin
  {
    if K1EANetworkEnable then
    begin
      TimeToDie := False;
      Exit;
    end;
  }
  TimeToLive := Ord(Message[9]);
  dec(TimeToLive);

  if TimeToLive <= 0 then
  begin
    TimeToDie := True;
    Exit;
  end;

  TimeToDie := False;
  Message[9] := CHR(TimeToLive);

  CheckSum := Ord(Message[6]);
  CheckSum := Swap(CheckSum);
  CheckSum := CheckSum + Ord(Message[7]);
  dec(CheckSum);
  Message[6] := CHR(Hi(CheckSum));
  Message[7] := CHR(Lo(CheckSum));
end;

function ThisMessageIsForMe(Message: string): boolean;

{ This function will return TRUE if the message is addressed to us or is
  a broadcast message. }

var
  Destination                           : Byte;

begin
  if not 1 = 1 {K1EANetworkEnable} then { N6TR Network mode }
  begin
    Destination := Ord(Message[2]);

    ThisMessageIsForMe := (Destination = $FF) or
      (Destination = MultiBandAddressArray[ActiveBand]);
  end
  else
    { At this point, I am not aware of any commands on the K1EA network
      that would not be for me.  This might change as I get into it
      more }

    ThisMessageIsForMe := True;
end;

function WeHaveProcessedThisMessage(Message: string): boolean;

{ This function will look at the message passed to it and see if we have
  seen this message before.  If we have, it will return TRUE.  If not, it
  will add it to the list of messages we have seen and return FALSE. }

var
  Source, Serial                        : Byte;
  ActiveMessage                         : integer;
  CheckSum                              : Word;

begin
  {
    if K1EANetworkEnable then // Do not expect repeat messages without retries
    begin
      WeHaveProcessedThisMessage := False;
      Exit;
    end

    else
    begin // N6TR Network Mode
      Source := ord(message[1]);
      Serial := ord(message[5]);

      CheckSum := ord(message[6]);
      CheckSum := Swap(CheckSum);
      CheckSum := CheckSum + ord(message[7]);

      CheckSum := CheckSum - ord(message[9]); // Make sure TTL isn't a factor
    end;
  }
     { See if we have a virgin list.  If so, add the entry }

  if ProcessedMultiMessagesStart = ProcessedMultiMessagesEnd then
  begin
    WeHaveProcessedThisMessage := False;
    ProcessedMultiMessages[ProcessedMultiMessagesStart].Source := Source;
    ProcessedMultiMessages[ProcessedMultiMessagesStart].Serial := Serial;
    ProcessedMultiMessages[ProcessedMultiMessagesStart].Check := CheckSum;
    inc(ProcessedMultiMessagesEnd); { Increments to one }
    Exit;
  end;

  { Start at the end of the list }

  ActiveMessage := ProcessedMultiMessagesEnd - 1;

  if ActiveMessage < 0 then
    ActiveMessage := ProcessedMultiMessageBufferLength - 1;

  repeat
    if (ProcessedMultiMessages[ActiveMessage].Source = Source) and
      (ProcessedMultiMessages[ActiveMessage].Serial = Serial) and
      (ProcessedMultiMessages[ActiveMessage].Check = CheckSum) then
    begin
      WeHaveProcessedThisMessage := True;
      Exit;
    end;

    if ActiveMessage = ProcessedMultiMessagesStart then { End of list }
    begin
      ActiveMessage := ProcessedMultiMessagesEnd;
      ProcessedMultiMessages[ActiveMessage].Source := Source;
      ProcessedMultiMessages[ActiveMessage].Serial := Serial;
      ProcessedMultiMessages[ActiveMessage].Check := CheckSum;

      inc(ProcessedMultiMessagesEnd);

      if ProcessedMultiMessagesEnd >= ProcessedMultiMessageBufferLength then
        ProcessedMultiMessagesEnd := 0;

      if ProcessedMultiMessagesEnd = ProcessedMultiMessagesStart then
      begin
        inc(ProcessedMultiMessagesStart);

        if ProcessedMultiMessagesStart >= ProcessedMultiMessageBufferLength then
          ProcessedMultiMessagesStart := 0;
      end;

      WeHaveProcessedThisMessage := False;
      Exit;
    end;

    dec(ActiveMessage);

    if ActiveMessage < 0 then
      ActiveMessage := ProcessedMultiMessageBufferLength - 1;

  until False;
end;

function ThisIsAMultiTalkMessage(MessageString: string): boolean;

begin
  {
    if K1EANetworkEnable then
      ThisIsAMultiTalkMessage := MessageString[1] = 'T'
    else
      ThisIsAMultiTalkMessage := ord(MessageString[3]) = MultiTalkMessage;
     }
end;

function GetMultiPortCommand: string;

{ This will retrieve a multi command string from the MultiReceiveCharBuffer.
  It works for either K1EA or N6TR network modes!! }

var
  TempString                            : string;
  CharPointer                           : integer;

begin
  //WLI ВРЕМЕННО
//  Result := TR4W_MULTIMESSAGE_STRING;
  Exit;

  GetMultiPortCommand := '';
  {
    if K1EANetworkEnable then
    begin
  //wli    if not CPUKeyer.SerialPortInputBuffer[ActiveMultiPort].GetNextLine(TempString) then      Exit;
    end
    else // TR Network
    begin
  //    if not CPUKeyer.SerialPortInputBuffer[ActiveMultiPort].GetSlippedString(TempString) then Exit;
      asm nop end;
    end;
  }
  if TempString = '' then Exit;

  if NetDebug then
    BlockWrite(NetDebugBinaryInput, TempString[1], length(TempString));

  if not ValidCheckSum(TempString) then { Works for TR and CT }
  begin
    if NetDebug then
    begin
      TempString := '*** NOT VALID CHECKSUM ***';
      BlockWrite(NetDebugBinaryInput, TempString[1], length(TempString));
    end;

    Exit;
  end;

  { Okay, we have a valid message to deal with.  If it is one of ours,
    we will ignore it, unless it was MultiTalkMessage }

  if ISentThisMultiMessage(TempString) then { It is one of ours }
  begin
    if ThisMessageIsForMe(TempString) then
      if not WeHaveProcessedThisMessage(TempString) then
        if ThisIsAMultiTalkMessage(TempString) then
          GetMultiPortCommand := TempString; { Process my own message }

    Exit;
  end;

  { If this message has been hoping around too long, ignore it }

  if TimeToDie(TempString) then Exit;

  { Okay, we have a valid message, and it isn't ours, pass it on. }
{
 if K1EANetworkEnable then
     // LineFeed Makes SendMultiMessage not add checksum or LF

   SendMultiMessage(TempString + LineFeed)
 else
   SendMultiMessage(TempString);
}
  if not ThisMessageIsForMe(TempString) then Exit;

  { We have a message for me to act on (unless I have already seen it) }

  if WeHaveProcessedThisMessage(TempString) then
  begin
    if NetDebug then
    begin
      TempString := '*** PROCESSED BEFORE ***';
      BlockWrite(NetDebugBinaryInput, TempString[1], length(TempString));
    end;

    Exit;
  end;

  GetMultiPortCommand := TempString;
end;

procedure RememberSentMessage(MultMessage: string);

{ This procedure will take the message that was sent and remember it along
  with a time stamp, so that if it doesn't get QSLed after a certain amount
  of time, the message can be resent. }

begin
  with MultiRememberBuffer^[FirstMultiMessage] do
  begin
    Message := MultMessage;
    MarkTime(TimeMark);
    RetryCount := 0;
    QSL := False;
    Warnings := 0;
  end;

  FirstMultiMessage := (FirstMultiMessage + 1) mod MultiMessageBufferSize;

  if FirstMultiMessage = LastMultiMessage then
    LastMultiMessage := (LastMultiMessage + 1) mod MultiMessageBufferSize;

end;

procedure SendMultiCommand(Source: Byte; Destination: Byte; ControlByte: Byte; Message: string);

{ This procedure will generate the multi command and pass it to the engine
  in LOGK1EA that sends the bytes to the port.  The format for the message
  is as follows:

    Source:        BYTE;
    Destination:   BYTE;
    ControlByte:   BYTE;
    SerialNumber:  WORD;
    CheckSum:      WORD;
    MessageLength: BYTE;
    TimeToLive:    INTEGER;
    Message:       A bunch of ASCII characters (MessageLength of them);

}

var
  TempString                            : string;
  CheckSum                              : Word;
  CharPointer                           : integer;

begin
  {
    TempString := Concat(CHR(Source),
      CHR(Destination),
      CHR(ControlByte),

        //      CHR(Hi(MultiSerialNumber)),
        //      CHR(Lo(MultiSerialNumber)),

      CHR(Hi(MultiSerialNumber) + 1),
      CHR(Lo(MultiSerialNumber) + 1),
        //wli      CHR(0),
        //wli      CHR(0),
      CHR(1),
      CHR(1),

      CHR(length(message)),
      CHR(DefaultTimeToLive),
      message);

    inc(MultiSerialNumber);

    CheckSum := 0;

    for CharPointer := 1 to length(TempString) do
      CheckSum := CheckSum + ord(TempString[CharPointer]);

    TempString[6] := CHR(Hi(CheckSum));
    TempString[7] := CHR(Lo(CheckSum));

    SendMultiMessage(TempString);
    RememberSentMessage(TempString);
  }
end;

procedure StuffInit;
begin
  DVKStamp;
end;

procedure SpeedUp;
//var   I                               : BYTE;
begin

  if CodeSpeed < (99 - CodeSpeedIncrement) then {KK1L: 6.72}
  begin
      //         I := CodeSpeed;
               {SetSpeed (CodeSpeed + 3);}

    SetSpeed(CodeSpeed + CodeSpeedIncrement); {KK1L: 6.72}
    DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};

  end;
end;

procedure ShowPreviousDupeQSOs(Call: CallString;
  Band: BandType;
  Mode: ModeType);
label
  1;
  { This routine will display previous duplicate QSOs with the station
    indicated. }

var
  pNumberOfBytesRead                    : Cardinal;
  TempIndex                             : integer;
  FirstTime                             : boolean;
begin
  if Call = '' then Exit;
  TempIndex := 0;
  FirstTime := True;
  if not OpenLogFile then Exit;
  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin

    if ((Band = TempRXData.Band) or not QSOByBand) and
      ((Mode = TempRXData.Mode) or not QSOByMode) then

      if TempRXData.Callsign = Call then
      begin
        if FirstTime then
        begin
//          if tPreviousDupeQSOsShowed = False then
          Windows.ShowWindow(tPreviousDupeQSOsWndHandle, SW_SHOW);

          Windows.EnableWindow(_NewELogWindow, False);
          tPreviousDupeQSOsShowed := True;
//          CreateThread(nil, 0, @cpdw, nil, 0, tPaddleThreadID);
//          tPreviousDupeQSOsWndHandle := CreateEditableLog(tr4whandle, col1, StaticWindowHeight * 7, MainWindowChildsWidth - 1, EditableLogWindowHeight, False);
//          Windows.SetWindowLong(tPreviousDupeQSOsWndHandle, GWL_STYLE, $5000C005);
          ListView_DeleteAllItems(tPreviousDupeQSOsWndHandle);
          FirstTime := False;
        end;
        tAddContestExchangeToLog(TempRXData, tPreviousDupeQSOsWndHandle, TempIndex);
//        EnsureListViewColumnVisible(tPreviousDupeQSOsWndHandle);
      end;
    goto 1;
  end;
  CloseLogFile;
end;

procedure SlowDown;

begin
  {IF CodeSpeed > 4 THEN}
  if CodeSpeed > (CodeSpeedIncrement + 1) then {KK1L: 6.72}
  begin
      {SetSpeed (CodeSpeed - 3);}
   //   CW_SPEED1 := CW_SPEED1 - CodeSpeedIncrement;
    SetSpeed(CodeSpeed - CodeSpeedIncrement); {KK1L: 6.72}
    DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
  end;
end;
{
procedure NewBandMapEntry(Call: CallString;
  Frequency: LONGINT;
  QSXFrequency: LONGINT;
  Mode: ModeType;
  Dupe: boolean;
  Mult: boolean;
  MinutesLeft: integer;
  SendToMulti: boolean;
  Source: CallString);

begin
  AddBandMapEntry(Call, Frequency, QSXFrequency, Mode, Dupe, Mult, MinutesLeft, Source);

  if NetSocket <> 0 then
    begin
      NetDXSpot.dsCall := Call;
      NetDXSpot.dsFrequency := Frequency;
      NetDXSpot.dsQSXFrequency := 0;
      NetDXSpot.dsMode := Mode;
      NetDXSpot.dsDupe := Dupe;
      NetDXSpot.dsMult := Mult;
      NetDXSpot.dsMinutesLeft := MinutesLeft;
      NetDXSpot.dsSource := Source;
      winsock2.Send(NetSocket, NetDXSpot, SizeOf(NetDXSpot), 0);
    end;

  DisplayBandMap;
end;
}

procedure PushMultiMessageBuffer(Message: Str80);

begin
  {
    MultiMessageBuffer[1] := MultiMessageBuffer[2];
    MultiMessageBuffer[2] := MultiMessageBuffer[3];
    MultiMessageBuffer[3] := MultiMessageBuffer[4];
    MultiMessageBuffer[4] := MultiMessageBuffer[5];
    MultiMessageBuffer[5] := Message;
  }
end;

procedure DisplayMultiMessageBuffer;

begin
  //   if ActiveMultiPort <> NoPort then
  begin
    //    SaveSetAndClearActiveWindow(EditableLogWindow);
    {
    WriteLn(MultiMessageBuffer[1]);
    WriteLn(MultiMessageBuffer[2]);
    WriteLn(MultiMessageBuffer[3]);
    WriteLn(MultiMessageBuffer[4]);
    Write(MultiMessageBuffer[5]);
    }
    //RestorePreviousWindow;
  end;
end;

procedure DisplayGridSquareStatus(Call: CallString);

var
  Range, Address                        : integer;
  Change                                : boolean;
  TempCall                              : CallString;

begin
  NumberGridSquaresInList := 0;

  if (ActiveDomesticMult = GridSquares) {wli and RoverCall(Call)} then
  begin
    CreateGridSquareList(Call, ActiveBand);

    if NumberGridSquaresInList > 0 then
    begin
      if NumberGridSquaresInList > 1 then
      begin
        Range := NumberGridSquaresInList - 2;

        repeat
          Change := False;

          for Address := 0 to Range do
            if GridSquareList[Address] > GridSquareList[Address + 1] then
            begin
              TempCall := GridSquareList[Address];
              GridSquareList[Address] := GridSquareList[Address + 1];
              GridSquareList[Address + 1] := TempCall;
              Change := True;
            end;

          dec(Range);
        until (not Change) or (Range < 0);
      end;

          //      SaveSetAndClearActiveWindow(EditableLogWindow);

      for Address := 0 to NumberGridSquaresInList - 1 do
      begin
              //{WLI}                IF WhereX >= 76 THEN WriteLn;

              //{WLI}                IF WhereX > 1 THEN Write (' ');

              //{WLI}                Write (GridSquareList [Address]);

              //   FRM.POSSIBLECALLWINDOW.Items.Add(GridSquareList [Address]);
      end;

          //            //RestorePreviousWindow;

      GridSquareListShown := True;
    end;
  end;
end;

function LogFileLooksOkay: boolean;

{ Returns TRUE if the LOG.DAT file looks about right for the number of
  QSOs the program thinks we have }

var
  NumberContacts                        : LONGINT;
  ErrorPercent                          : REAL;
  //  h                                : HWND;
begin
  Result := False;
  if not OpenLogFile then Exit;
  if Windows.GetFileSize(LogHandle, nil) = tRestartInfo.riTotalRecordsInLog {QSOTotals[All, Both] } * SizeOf(ContestExchange) + SizeOfTLogHeader then
    Result := True;
  CloseLogFile;

  {
     NumberContacts := (GetFileSize_TR(LogFileName)) div 84;

     if NumberContacts = 0 then
        if QSOTotals[All, Both] > 2 then
           Exit
        else
           begin
              LogFileLooksOkay := True;
              Exit;
           end;

     if QSOTotals[All, Both] = 0 then Exit;

     if Abs(QSOTotals[All, Both] - NumberContacts) < 10 then
        begin
           LogFileLooksOkay := True;
           Exit;
        end;

     ErrorPercent := ((QSOTotals[All, Both] - NumberContacts) / QSOTotals[All, Both]) * 100;
     LogFileLooksOkay := (ErrorPercent < 3.0) and (ErrorPercent > -3.0);
  }
end;

procedure WriteLogEntry(Entry: Str80);

var
  FileWrite                             : Text;
  //  I, i2                           : Cardinal;
begin
  //Assign(FileWrite, LogFileName);
  //{ $ I-}
  //Append(FileWrite);
  //{ $ I+}

   {  I := IORESULT;
     if I <> 0
        then
        begin
           I := GetFileAttributes(PChar(LogFileName));
           i2 := I;

           if ((I or FILE_ATTRIBUTE_READONLY) = i2) then
              begin
                 if MessageBox(TR4WHandle, 'read only',
                    'TR4W', MB_YESNO or MB_ICONQUESTION or MB_TOPMOST or MB_DEFBUTTON2 ) = IDno then Exit;
              end;

        end;

  }
  WriteLn(LOGDATFileWrite {FileWrite}, Entry);
  //Close(FileWrite);

  //W_L_I  if PrinterEnabled then
  //W_L_I  begin
{$I-}
  //{WLI}        WriteLn (Lst, Entry);
  //{WLI}        IF IOResult <> 0 THEN SendMorse ('PRINTER FAILURE');
{$I+}
  //W_L_I  end;
end;

procedure NextPage;

var
  FileWrite                             : Text;

begin
  Assign(FileWrite, LogFileName);
  Append(FileWrite);
  Write(FileWrite, ControlL);
  Close(FileWrite);

  //W_L_I  if PrinterEnabled then
  //W_L_I  begin
{$I-}
  //{WLI}        Write (Lst, ControlL);
  //{WLI}        IF IOResult <> 0 THEN SendMorse ('     PRINTER FAILURE');
{$I+}
  //W_L_I  end;

end;

procedure PrintLogHeader;

var
  //   PageNumber                      : integer;
  LogString, Underline                  : Str80;

begin
  //   PageNumber := (QSOTotals[All, Both] div 50) + 1;

  WriteLogEntry(ContestTitle);
  WriteLogEntry(LogSubTitle);
  WriteLogEntry('');

  BandModeDateTimeNumberCallNameSentHeader(LogString, Underline);

  { These are hacks when the very nice way just isn't efficient enough }

  { Note that the RSTQTHNameAndFistsNumberOrPowerExchange has the
    multiplier header and stamp functions wired to do nothing }

  {KK1L: 6.70 Changed spacing slightly to line up with output}
  if ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange then
  begin
    LogString := LogString + ' TXR  RXR QTH NAME      NUM/PWR';
    Underline := Underline + ' ---  --- --- ----      -------';
  end
  else
  begin
      { Very nice generic way of doing things }

    with ExchangeInformation do
    begin
      if RST then
      begin
        RSTSentHeader(LogString, Underline);
        RSTReceivedHeader(LogString, Underline);
      end;

      if ClassEI then ClassReceivedHeader(LogString, Underline);
      if QSONumber then QSONumberReceivedHeader(LogString, Underline);
      if PostalCode then PostalCodeReceivedHeader(LogString, Underline);
      if RandomChars then RandomCharsSentAndReceivedHeader(LogString, Underline);
      if Power then PowerReceivedHeader(LogString, Underline);
      if Name then NameReceivedHeader(LogString, Underline);
      if Chapter then ChapterReceivedHeader(LogString, Underline);
      if Age then AgeReceivedHeader(LogString, Underline);
      if Precedence then PrecedenceReceivedHeader(LogString, Underline);
      if Check then CheckReceivedHeader(LogString, Underline);
      if Zone then ZoneReceivedHeader(LogString, Underline);
      if TenTenNum then TenTenNumReceivedHeader(LogString, Underline);
      if QTH then QTHReceivedHeader(LogString, Underline);
    end;
  end;

  MultiplierHeader(LogString, Underline);
  QSOPointHeader(LogString, Underline);
  WriteLogEntry(LogString);
  WriteLogEntry(Underline);
end;

function MakeLogString(RXData: ContestExchange): Str80;

{ This function will take the information in the contest exchange record
  passed to it and generate a log entry string from it.  }

var
  LogString                             : Str80;

begin

  LogString := '';

  BandModeDateTimeNumberCallNameSentStamp(RXData, LogString);

  with ExchangeInformation do
  begin
    if RST then
    begin
      RSTSentStamp(RXData, LogString);
      RSTReceivedStamp(RXData, LogString);
    end;

    if LogBadQSOString <> '' then
    begin
      LogString := LogString + LogBadQSOString;
      MultiplierStamp(RXData, LogString);
      QSOPointStamp(RXData, LogString);
      MakeLogString := LogString;
      Exit;
    end;

      //KK1L: 6.70 Sometimes there is just not a pretty way to do it!!

    if ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange then
    begin
      if QTH then QTHReceivedStamp(RXData, LogString);
      if Name then NameReceivedStamp(RXData, LogString);
      if QSONumber then QSONumberReceivedStamp(RXData, LogString);
      if Power then PowerReceivedStamp(RXData, LogString);
    end
    else
    begin
      if Kids then KidsReceivedStamp(RXData, LogString);
      if ClassEI then ClassReceivedStamp(RXData, LogString);
      if QSONumber then QSONumberReceivedStamp(RXData, LogString);
      if PostalCode then PostalCodeReceivedStamp(RXData, LogString);
      if RandomChars then RandomCharsSentAndReceivedStamp(RXData, LogString);
      if Power then PowerReceivedStamp(RXData, LogString);
      if Age then AgeReceivedStamp(RXData, LogString);
      if Name then NameReceivedStamp(RXData, LogString);
      if Chapter then ChapterReceivedStamp(RXData, LogString);
      if Precedence then PrecedenceReceivedStamp(RXData, LogString);
      if Check then CheckReceivedStamp(RXData, LogString);
      if Zone then ZoneReceivedStamp(RXData, LogString);
      if TenTenNum then TenTenNumReceivedStamp(RXData, LogString);
      if QTH then QTHReceivedStamp(RXData, LogString);
    end;

  end;
  MultiplierStamp(RXData, LogString);
  QSOPointStamp(RXData, LogString);
  MakeLogString := LogString;

end;

procedure CalculateQSOPoints(var RXData: ContestExchange);

var
  Points, MyZoneValue, RXDataZoneValue, Result: integer;
  Distance                              : LONGINT;
  RXCty, TheirID, CountryID             : CallString;
  TempOblast                            : string[2];
  la1, la2, lo1, lo2                    : integer;
begin
  RXData.QSOPoints := 0;

  if (QSOPointsDomesticCW >= 0) and (RXData.Mode = CW) and (RXData.DomesticQTH <> '') then
  begin
    RXData.QSOPoints := QSOPointsDomesticCW;
    Exit;
  end;

  if (QSOPointsDXCW >= 0) and (RXData.Mode = CW) and (RXData.DomesticQTH = '') then
  begin
    RXData.QSOPoints := QSOPointsDXCW;
    Exit;
  end;

  if (QSOPointsDomesticPhone >= 0) and (RXData.Mode = Phone) and (RXData.DomesticQTH <> '') then
  begin
    RXData.QSOPoints := QSOPointsDomesticPhone;
    Exit;
  end;

  if (QSOPointsDXPhone >= 0) and (RXData.Mode = Phone) and (RXData.DomesticQTH = '') then
  begin
    RXData.QSOPoints := QSOPointsDXPhone;
    Exit;
  end;

  RXCty := CountryTable.GetCountryID(RXData.QTH.Country);

  case ActiveQSOPointMethod of

    AllAsianQSOPointMethod:
      begin
        if MyContinent = Asia then
        begin
          if RXData.QTH.Continent <> Asia then
          begin
            case RXData.Band of
              Band160: RXData.QSOPoints := 9;
              Band80: RXData.QSOPoints := 6;
              Band10: RXData.QSOPoints := 6;
            else RXData.QSOPoints := 3;
            end;
          end
          else
            if MyCountry <> RXCty then
            begin
              case RXData.Band of
                Band160: RXData.QSOPoints := 3;
                Band80: RXData.QSOPoints := 2;
                Band10: RXData.QSOPoints := 2;
              else RXData.QSOPoints := 1;
              end;
            end
            else
            begin
              RXData.QSOPoints := 0;
              RXData.InhibitMults := True; { Same country }
            end;

        end

        else { I am not in Asia }

          if RXData.QTH.Continent = Asia then
          begin
            case RXData.Band of
              Band160: RXData.QSOPoints := 3;
              Band80: RXData.QSOPoints := 2;
              Band10: RXData.QSOPoints := 2;
            else RXData.QSOPoints := 1;
            end;
          end
          else
          begin
            RXData.QSOPoints := 0;
            RXData.InhibitMults := True;
          end;

      end;

    ARCIQSOPointMethod:
      begin
        if StringIsAllNumbers(RXData.Power) then
          RXData.QSOPoints := 5
        else
          if MyContinent = RXData.QTH.Continent then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 4;
      end;

    ARIQSOPointMethod:
      if (RXCty = 'I') or (RXCty = 'IS') or (RXCty = 'IT9') then
//      if RXCty[1] = 'I' then
        RXData.QSOPoints := 10
      else
        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 3
        else
          if RXCty <> MyCountry then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 0;

    ARRLDXQSOPointMethod:
      if (MyCountry = 'K') or
        (MyCountry = 'VE') then
      begin
        if (RXCty <> 'K') and (RXCty <> 'VE') then
          RXData.QSOPoints := 3
        else
        begin
          RXData.QSOPoints := 0;
          RXData.InhibitMults := True;
        end;
      end
      else
        if (RXCty = 'K') or (RXCty = 'VE') then
          RXData.QSOPoints := 3
        else
        begin
          RXData.QSOPoints := 0;
          RXData.InhibitMults := True;
        end;

    ARRLFieldDayQSOPointMethod:
      if StringHas(UpperCase(MyFDClass), 'D') and
        StringHas(UpperCase(RXData.ceClass), 'D') then
        RXData.QSOPoints := 0
      else
        if RXData.Mode = Phone then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 2;

    ARRL160QSOPointMethod:
      if DomesticCountryCall(RXData.Callsign) then
        RXData.QSOPoints := 2
      else
        if DomesticCountryCall(MyCall) then
          RXData.QSOPoints := 5
        else
          RXData.QSOPoints := 0;

    ARRL10QSOPointMethod:
      if ((Copy(RXData.Callsign, length(RXData.Callsign) - 1, 2) = '/T') or
        (Copy(RXData.Callsign, length(RXData.Callsign) - 1, 2) = '/N')) and
        (RXData.Mode = CW) then
        RXData.QSOPoints := 8
      else
        if RXData.Mode = CW then
          RXData.QSOPoints := 4
        else
          RXData.QSOPoints := 2;

    ARRLVHFQSOPointMethod:
      case RXData.Band of
        Band6: RXData.QSOPoints := 1;
        Band2: RXData.QSOPoints := 1;
        Band222: RXData.QSOPoints := 2;
        Band432: RXData.QSOPoints := 2;
        Band902: RXData.QSOPoints := 3;
        Band1296: RXData.QSOPoints := 3;
        Band2304: RXData.QSOPoints := 4;
        Band3456: RXData.QSOPoints := 4;
        Band5760: RXData.QSOPoints := 4;
        Band10G: RXData.QSOPoints := 4;
        Band24G: RXData.QSOPoints := 4;
        BandLight: RXData.QSOPoints := 4;
      else RXData.QSOPoints := 0;
      end;

    ARRLVHFSSPointMethod:
      case RXData.Band of
        Band6: RXData.QSOPoints := 1;
        Band2: RXData.QSOPoints := 1;
        Band222: RXData.QSOPoints := 2;
        Band432: RXData.QSOPoints := 2;
        Band902: RXData.QSOPoints := 4;
        Band1296: RXData.QSOPoints := 4;
        Band2304: RXData.QSOPoints := 8;
        Band3456: RXData.QSOPoints := 8;
        Band5760: RXData.QSOPoints := 8;
        Band10G: RXData.QSOPoints := 8;
        Band24G: RXData.QSOPoints := 8;
        BandLight: RXData.QSOPoints := 8;
      else RXData.QSOPoints := 0;
      end;

    BalticQSOPointMethod:
      begin
        if (MyCountry = 'ES') or (MyCountry = 'YL') or (MyCountry = 'LY') then
        begin
          if RXData.QTH.Continent = Europe then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 2;
        end
        else
          if (RXCty = 'ES') or (RXCty = 'YL') or (RXCty = 'LY') then
          begin
            if MyContinent = Europe then
              RXData.QSOPoints := 10
            else
              RXData.QSOPoints := 20;
          end
          else
            RXData.QSOPoints := 1;
      end;

    CISQSOPointMethod:
      begin
        RXData.QSOPoints := 1;

        if RXCty <> MyCountry then
        begin
          if RXData.QTH.Continent = MyContinent then RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 3;
        end;

        if not CISCountry(MyCountry) then
          if CISCountry(RXCty) then RXData.QSOPoints := 5;

      end;

    CQ160QSOPointMethod:
      if RXCty = MyCountry then
        RXData.QSOPoints := 2
      else
        if RXData.QTH.Continent = MyContinent then
          RXData.QSOPoints := 5
        else
          RXData.QSOPoints := 10;

    CQMQSOPointMethod:
      begin
        {
                if RussianID(RXCty) then
                  begin
                    TempOblast := GetOblast(RXData.Callsign);
                    if TempOblast <> '' then
                      begin
                        if IsR150Country(TempOblast[1], TempOblast[2]) then
                          RXData.DXQTH := 'R' + TempOblast;
                      end;
                  end;
        }
        if RussianID(MyCountry) then
        begin
          if not RussianID(RXCty) then
          begin
            if (RXData.QTH.Continent = Europe) or (RXData.QTH.Continent = Asia) then RXData.QSOPoints := 2
            else RXData.QSOPoints := 3;
          end
          else
            if InSameFederalOkrug(RXData.Callsign) then
              RXData.QSOPoints := 1 else RXData.QSOPoints := 2;
        end
            {Outside Russia}
        else
        begin
          if RussianID(RXCty) then
          begin
            if ((MyContinent = Europe) or (MyContinent = Asia)) then
              RXData.QSOPoints := 2
            else
              RXData.QSOPoints := 3;
            Exit;
          end;
          if MyCountry = RXCty then RXData.QSOPoints := 1 else RXData.QSOPoints := 2;
          if MyContinent <> RXData.QTH.Continent then RXData.QSOPoints := 3;
        end;

      end;

    CQVHFQSOPointMethod:
      begin
        case RXData.Band of
          { Band6, Band2:      RXData.QSOPoints := 1;}{KK1L: 6.73 new rules for 2002}
          { Band222, Band432:  RXData.QSOPoints := 2;}{KK1L: 6.73 new rules for 2002}
          { Band902, Band1296: RXData.QSOPoints := 4;}{KK1L: 6.73 new rules for 2002}
          { Band2304:          RXData.QSOPoints := 6;}{KK1L: 6.73 new rules for 2002}
          { Band3456:          RXData.QSOPoints := 6;}{KK1L: 6.73 new rules for 2002}
          { Band5760:          RXData.QSOPoints := 6;}{KK1L: 6.73 new rules for 2002}
          { Band10G:           RXData.QSOPoints := 6;}{KK1L: 6.73 new rules for 2002}
          { Band24G:           RXData.QSOPoints := 6;}{KK1L: 6.73 new rules for 2002}
          { BandLight:         RXData.QSOPoints := 6;}{KK1L: 6.73 new rules for 2002}
          Band2: RXData.QSOPoints := 2; {KK1L: 6.73 new rules for 2002}
          Band6: RXData.QSOPoints := 1; {KK1L: 6.73 new rules for 2002}
        else RXData.QSOPoints := 0;
        end;

        if (RXData.Mode = CW) and (RXData.QSOPoints > 0) then
          inc(RXData.QSOPoints);
      end;

    CQWPXQSOPointMethod:
      if RXData.QTH.Continent = MyContinent then
      begin
        if RXCty = MyCountry then
          RXData.QSOPoints := 1
        else
        begin
          case RXData.Band of
            Band160: RXData.QSOPoints := 2;
            Band80: RXData.QSOPoints := 2;
            Band40: RXData.QSOPoints := 2;
            Band20: RXData.QSOPoints := 1;
            Band15: RXData.QSOPoints := 1;
            Band10: RXData.QSOPoints := 1;
          end;

          if MyContinent = NorthAmerica then
            RXData.QSOPoints := RXData.QSOPoints + RXData.QSOPoints;
        end;
      end
      else
        case RXData.Band of
          Band160: RXData.QSOPoints := 6;
          Band80: RXData.QSOPoints := 6;
          Band40: RXData.QSOPoints := 6;
          Band20: RXData.QSOPoints := 3;
          Band15: RXData.QSOPoints := 3;
          Band10: RXData.QSOPoints := 3;
        end;

    CQWPXRTTYQSOPointMethod:
      begin
        if RXData.QTH.Continent = MyContinent then
        begin
          if RXCty = MyCountry then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 2
        end
        else
          RXData.QSOPoints := 3;

        if (RXData.Band = Band80) or (RXData.Band = Band40) then
          RXData.QSOPoints := RXData.QSOPoints + RXData.QSOPoints;

      end;

    CQWWQSOPointMethod:
      if RXData.QTH.Continent <> MyContinent then
        RXData.QSOPoints := 3
      else
        if RXCty <> MyCountry then
          if MyContinent <> NorthAmerica then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 2
        else RXData.QSOPoints := 0;

    CQWWRTTYQSOPointMethod:
      if RXData.QTH.Continent <> MyContinent then
        RXData.QSOPoints := 3
      else
        if RXCty <> MyCountry then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 1;

    CroatianQSOPointMethod:
      if RXCty = '9A' then
      begin
        case RXData.Band of
          Band160: RXData.QSOPoints := 10;
          Band80: RXData.QSOPoints := 10;
          Band40: RXData.QSOPoints := 10;
          Band20: RXData.QSOPoints := 6;
          Band15: RXData.QSOPoints := 6;
          Band10: RXData.QSOPoints := 6;
        end;
      end
      else
        if RXData.QTH.Continent = MyContinent then
        begin
          case RXData.Band of
            Band160: RXData.QSOPoints := 2;
            Band80: RXData.QSOPoints := 2;
            Band40: RXData.QSOPoints := 2;
            Band20: RXData.QSOPoints := 1;
            Band15: RXData.QSOPoints := 1;
            Band10: RXData.QSOPoints := 1;
          end;
        end
        else
          case RXData.Band of
            Band160: RXData.QSOPoints := 6;
            Band80: RXData.QSOPoints := 6;
            Band40: RXData.QSOPoints := 6;
            Band20: RXData.QSOPoints := 3;
            Band15: RXData.QSOPoints := 3;
            Band10: RXData.QSOPoints := 3;
          end;

    EuropeanFieldDayQSOPointMethod:
      begin
        RXData.QSOPoints := 1;

        CountryID := MyCountry;

        if (CountryID = 'F') or (CountryID = 'OE') then
        begin
          if RXCty = MyCountry then
          begin
            if PortableStation(RXData.Callsign) then
              RXData.QSOPoints := 50
            else
              RXData.QSOPoints := 10;
          end
          else
            if RXData.QTH.Continent = Europe then
            begin
              if PortableStation(RXData.Callsign) then
                RXData.QSOPoints := 5
              else
                RXData.QSOPoints := 1;
            end
            else
              RXData.QSOPoints := 3;

          Exit;
        end;

        if CountryID = 'OZ' then
        begin
          if RXCty = MyCountry then
          begin
            if PortableStation(RXData.Callsign) then
              RXData.QSOPoints := 10
            else
              RXData.QSOPoints := 1;
          end
          else
            if RXData.QTH.Continent = Europe then
            begin
              if PortableStation(RXData.Callsign) then
                RXData.QSOPoints := 5
              else
                RXData.QSOPoints := 3;
            end
            else
              RXData.QSOPoints := 6;

          Exit;
        end;

        if CountryID = 'HB' then
        begin
          if PortableStation(RXData.Callsign) then
            RXData.QSOPoints := 5
          else
            if RXData.QTH.Continent = Europe then
              RXData.QSOPoints := 1
            else
              RXData.QSOPoints := 2;
          Exit;
        end;

        if CountryID = 'I' then
        begin
          if PortableStation(RXData.Callsign) then
            RXData.QSOPoints := 6
          else
            if RXData.QTH.Continent = Europe then
              RXData.QSOPoints := 1
            else
              RXData.QSOPoints := 2;

          if (RXData.Band = Band160) or (RXData.Band = Band80) then
            RXData.QSOPoints := RXData.QSOPoints * 2;
          Exit;
        end;

        { Anywhere else, including DL and PA }

        if PortableStation(RXData.Callsign) then
        begin
          if RXData.QTH.Continent = Europe then
            RXData.QSOPoints := 4
          else
            RXData.QSOPoints := 6;
        end
        else
        begin
          if RXData.QTH.Continent = Europe then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 3;
        end;

        if CountryID[1] = 'G' then
          if (RXData.Band = Band160) or (RXData.Band = Band10) then
            RXData.QSOPoints := RXData.QSOPoints * 2;

      end;

    EuropeanSprintQSOPointMethod:
      if MyContinent = Europe then
        RXData.QSOPoints := 1
      else
        if RXData.QTH.Continent = Europe then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 0;

    RadioVHFFDQSOPointMethod {, ChampionshipRFVHFQSOPointMethod}:
      begin
        if MyGrid <> '' then
        begin
          Points := GetDistanceBetweenGrids {GetEuropeanDistanceBetweenGrids}(MyGrid, RXData.DomesticQTH);
          if RXData.Band = Band2 then RXData.QSOPoints := Points * 2;
          if RXData.Band = Band432 then RXData.QSOPoints := Points * 8;
          if RXData.Band = Band1296 then RXData.QSOPoints := Points * 20;
          asm
          nop
          end;
            //            if ActiveQSOPointMethod = ChampionshipRFVHFQSOPointMethod then RXData.QSOPoints := RXData.QSOPoints div 2;
        end;
      end;

    EuropeanVHFQSOPointMethod:
//      if MyGrid <> '' then
//        if RXData.DomesticQTH <> '' then
      RXData.QSOPoints := GetEuropeanDistanceBetweenGrids(MyGrid, RXData.DomesticQTH);

    FistsQSOPointMethod:
      if RXData.NumberReceived > 0 then
        RXData.QSOPoints := 5
      else
        RXData.QSOPoints := 2;

    HADXQSOPointMethod:
      if RXCty = 'HA' then
        RXData.QSOPoints := 6
      else
        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 1;

    HelvetiaQSOPointMethod:
      if MyCountry <> 'HB' then
      begin
        if RXCty = 'HB' then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 0;
      end
      else
        if RXData.QTH.Continent = Europe then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 3;

    IARUQSOPointMethod:
      if RXData.DomesticQTH = '' then
      begin
          //        Val(RXData.Zone, RXDataZoneValue, RESULT);
        Val(MyZone, MyZoneValue, Result);

        if RXData.Zone = MyZoneValue then
          RXData.QSOPoints := 1
        else
          if RXData.QTH.Continent = MyContinent then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 5;
      end
      else
        RXData.QSOPoints := 1;
    {
      if RXData.DomesticQTH = '' then
      begin
        Val(RXData.Zone, RXDataZoneValue, RESULT);
        Val(MyZone, MyZoneValue, RESULT);

        if RXDataZoneValue = MyZoneValue then
          RXData.QSOPoints := 1
        else
          if RXData.QTH.Continent = MyContinent then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 5;
      end
      else
        RXData.QSOPoints := 1;
        }
    InternetSixQSOPointMethod:
      begin
        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 3
        else
          if MyContinent <> NorthAmerica then
            RXData.QSOPoints := 1
          else
          begin
            TheirID := RXCty;
            if TheirID = 'VE' then TheirID := 'K';

            if {(MyCounty <> 'K') and}(MyCountry <> 'VE') then
            begin { I am DX }
              if TheirID = 'K' then
                RXData.QSOPoints := 3
              else
                RXData.QSOPoints := 1;
            end
            else
              if TheirID <> 'K' then { I am W/VE }
                RXData.QSOPoints := 3
              else
                RXData.QSOPoints := 1;
          end;
      end;

    IOTAQSOPointMethod:
      if (RXData.DomesticQTH <> '') and
        (UpperCase(RXData.DomesticQTH) <> UpperCase(MyIOTA)) then
        RXData.QSOPoints := 15
      else
        RXData.QSOPoints := 3;

    JapanInternationalDXQSOPointMethod:
      begin
        case RXData.Band of
          Band160: RXData.QSOPoints := 4;
          Band80: RXData.QSOPoints := 2;
          Band40: RXData.QSOPoints := 1;
          Band20: RXData.QSOPoints := 1;
          Band15: RXData.QSOPoints := 1;
          Band10: RXData.QSOPoints := 2;
        end;

        if MyCountry = 'JA' then
        begin
          if RXCty = 'JA' then
          begin
            RXData.QSOPoints := 0;
            RXData.InhibitMults := True;
          end;
        end
        else
          if (RXCty <> 'JA') and (Copy(RXCty, 1, 2) <> 'JD') then
          begin
            RXData.QSOPoints := 0;
            RXData.InhibitMults := True;
          end;
      end;

    KCJQSOPointMethod:
      if MyCountry = 'JA' then
      begin
        if (RXCty = 'JA') or (RXCty = 'JD1') then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 5;
      end
      else
      begin
        if (RXCty = 'JA') or (RXCty = 'JD1') then
          RXData.QSOPoints := 1
      end;

    MQPQSOPointMethod:
      if RXData.Callsign = 'W0EF' then
        RXData.QSOPoints := 10
      else
        if RXData.Mode = CW then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 1;

    NZFieldDayQSOPointMethod:
      if RXCty = 'ZL' then
      begin
        if RXData.Mode = CW then
          RXData.QSOPoints := 5
        else
          RXData.QSOPoints := 3;
      end
      else
        RXData.QSOPoints := 10;

    OKDXQSOPointMethod:
//      if (MyCountry = 'OK') or (MyCountry = 'OM') then
      if OKOMStation(MyCountry) then
      begin
        if RXData.QTH.Continent <> Europe then
          RXData.QSOPoints := 3
        else
//          if (RXCty <> 'OK') and (RXCty <> 'OM') then
          if not OKOMStation(RXCty) then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 0;
      end
      else
//        if (RXCty = 'OK') or (RXCty = 'OM') then
        if OKOMStation(RXCty) then
        begin
          if MyContinent = Europe then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 3;
        end
        else
          RXData.QSOPoints := 0;

    RAEMQSOPointMethod:
      begin

        if LooksLikeAGeoCoordinates(MyState, la1, lo1) then
          if LooksLikeAGeoCoordinates(RXData.QTHString, la2, lo2) then
          begin
            Distance := Abs(lo1 - lo2);
            if Distance > 180 then Distance := 360 - Distance;
            RXData.QSOPoints := 50 + Abs(la2 - la1) + Distance;
            if RXData.Callsign = 'RAEM' then RXData.QSOPoints := RXData.QSOPoints + 300;
            if la2 > 65 + 90 then RXData.QSOPoints := RXData.QSOPoints + 100;
            if la1 > 65 + 90 then RXData.QSOPoints := round(RXData.QSOPoints * 1.1);
          end;
      end;

    RACQSOPointMethod:
      if RXCty = 'VE' then
      begin
        if pos('RAC', RXData.Callsign) > 0 then
          RXData.QSOPoints := 20
        else
          RXData.QSOPoints := 10;
      end
      else
        RXData.QSOPoints := 2;

    RSGBQSOPointMethod:
      if MyCountry = RXCty then
        RXData.QSOPoints := 0
      else
        case RXData.QTH.Continent of
          Europe: RXData.QSOPoints := 5;
          Oceania: RXData.QSOPoints := 30;
        else RXData.QSOPoints := 15;
        end;

    RDAQSOPointMethod:
      begin
        RXData.QSOPoints := 0;
        if RussianID(MyCountry) then
        begin
          if RussianID(RXCty) then
          begin
            if pos('/P', RXData.Callsign) = length(RXData.Callsign) - 1 then
            begin
              RXData.QSOPoints := 10;
              Exit;
            end;
            RXData.QSOPoints := 1;
            if RXData.QTH.Continent <> MyContinent then RXData.QSOPoints := 2;
            Exit;
          end;
          if RXData.QTH.Continent = MyContinent then RXData.QSOPoints := 3 else RXData.QSOPoints := 5;
        end
        else
          if RussianID(RXCty) then
            RXData.QSOPoints := 10;
      end;

    RussianDXQSOPointMethod:
      begin

        if RussianID(MyCountry) then
        begin
          if RXData.QTH.Continent <> MyContinent then
            RXData.QSOPoints := 5
          else
            if RXCty <> MyCountry then
              RXData.QSOPoints := 3
            else
              RXData.QSOPoints := 2;
        end

            { I am not in Russia }

        else
          if RussianID(RXCty) then
            RXData.QSOPoints := 10
          else
            if RXData.QTH.Continent <> MyContinent then
              RXData.QSOPoints := 5
            else
              if RXCty <> MyCountry then
                RXData.QSOPoints := 3
              else
                RXData.QSOPoints := 2;
      end;

    SalmonRunQSOPointMethod:
      begin
        if RXData.Mode = CW then
          RXData.QSOPoints := 4
        else
          RXData.QSOPoints := 2;
      end;

    ScandinavianQSOPointMethod:
      begin
        if ScandinavianCountry(MyCountry) then
        begin
          if ScandinavianCountry(RXCty) then
            RXData.QSOPoints := 0
          else
            if RXData.QTH.Continent = Europe then
              RXData.QSOPoints := 2
            else
              RXData.QSOPoints := 3;
        end
        else
        begin
          if ScandinavianCountry(RXCty) then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 0;

          if MyContinent <> Europe then
            if RXData.Band in [Band80, Band40] then
              RXData.QSOPoints := RXData.QSOPoints * 3;
        end;
        if RXData.Band = Band160 then RXData.QSOPoints := 0;
      end;

    SLFivePointQSOMethod:
      if Copy(RXData.Callsign, 1, 2) = 'SL' then
        RXData.QSOPoints := 5
      else
        RXData.QSOPoints := 1;

    SouthAmericanWWQSOPointMethod:
      begin
        if MyContinent = SouthAmerica then
        begin
          if RXData.QTH.Continent = SouthAmerica then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 10;
        end
        else
          if RXData.QTH.Continent = SouthAmerica then
            RXData.QSOPoints := 10
          else
            RXData.QSOPoints := 2;
      end;

    StewPerryQSOPointMethod:
      begin
        if (MyGrid <> '') and (RXData.DomesticQTH <> '') then
        begin
          Distance := GetDistanceBetweenGrids(MyGrid, RXData.DomesticQTH);
          RXData.QSOPoints := (Distance div 500) + 1;
        end
        else
          RXData.QSOPoints := 1;
      end;

    TenTenQSOPointMethod:
      if RXData.TenTenNum <> -1 then
        RXData.QSOPoints := 2
      else
        RXData.QSOPoints := 1;

    TOECQSOPointMethod:
      if RXData.QTH.Continent <> MyContinent then
        RXData.QSOPoints := 3
      else
        if StringHas(RXData.Callsign, '/M') then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 1;

    UBAQSOPointMethod:
      begin
        if RXCty = 'ON' then
          RXData.QSOPoints := 10
        else
          if UBACountry(RXCty) then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 1;
      end;

    UkrainianQSOPointMethod:
      begin

        if RXCty = 'UR' then
          RXData.QSOPoints := 10
        else
          if RXCty = MyCountry then
            RXData.QSOPoints := 1
          else
            if RXData.QTH.Continent = MyContinent then
              RXData.QSOPoints := 2
            else
              RXData.QSOPoints := 3;
        if MyCountry = 'UR' then
        begin
          if RXCty = 'UR' then RXData.QSOPoints := 1;
          RXData.DomesticMult := False;
        end;
      end;

    VKZLQSOPointMethod:
      if ((MyContinent = Oceania) or (RXData.QTH.Continent = Oceania)) then
      begin
        case RXData.Band of
          Band160: RXData.QSOPoints := 20;
          Band80: RXData.QSOPoints := 10;
          Band40: RXData.QSOPoints := 5;
          Band20: RXData.QSOPoints := 1;
          Band15: RXData.QSOPoints := 2;
          Band10: RXData.QSOPoints := 3;
        end;
      end
      else
        RXData.QSOPoints := 0;

    WAGQSOPointMethod:
      if MyCountry = 'DL' then
      begin
        if RXCty = 'DL' then
          RXData.QSOPoints := 1
        else
          if RXData.QTH.Continent = Europe then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 5;
      end
      else
      begin
        if RXCty = 'DL' then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 0;
      end;

    WAEQSOPointMethod:
      if MyContinent = Europe then
        if (RXData.QTH.Continent <> Europe) and (RXData.Band <> Band160) then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 0
      else
        if (RXData.QTH.Continent = Europe) and (RXData.Band <> Band160) then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 0;

    WWLQSOPointMethod:
      begin
        if (MyGrid <> '') and (RXData.DomesticQTH <> '') then
        begin
          Distance := GetDistanceBetweenGrids(MyGrid, RXData.DomesticQTH);
          RXData.QSOPoints := (Distance div 500) + 1;

          if (RXData.Band = Band80) or (RXData.Band = Band160) then
            RXData.QSOPoints := RXData.QSOPoints + RXData.QSOPoints;

          if RXData.Band = Band160 then
            RXData.QSOPoints := RXData.QSOPoints + RXData.QSOPoints;
        end
        else
          RXData.QSOPoints := 1;
      end;

    YODXQSOPointMethod:
      if RXCty = 'YO' then RXData.QSOPoints := 8
      else

        if MyCountry <> RXCty then
          if RXData.QTH.Continent <> MyContinent then RXData.QSOPoints := 4
          else
            RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 1; {KK1L: 6.71 Same country QSO}

    NoQSOPointMethod: RXData.QSOPoints := 0;

    AlwaysOnePointPerQSO: RXData.QSOPoints := 1;
    OnePointPerQSO: RXData.QSOPoints := 1;
    TwoPointsPerQSO: RXData.QSOPoints := 2;
    ThreePointsPerQSO: RXData.QSOPoints := 3;
    TenPointsPerQSO: RXData.QSOPoints := 10;

    TwoPhoneFourCW:
      if RXData.Mode = CW then RXData.QSOPoints := 4
      else RXData.QSOPoints := 2;

    TwoPhoneThreeCW:
      if RXData.Mode = CW then RXData.QSOPoints := 3
      else RXData.QSOPoints := 2;

    OnePhoneTwoCW:
      if RXData.Mode = CW then RXData.QSOPoints := 2
      else RXData.QSOPoints := 1;

    ThreePhoneFiveCW:
      if RXData.Mode = CW then RXData.QSOPoints := 5
      else RXData.QSOPoints := 3;

    OneEuropeTwoOther: {KK1L: 6.68 Used for WRTC 2002}
      if MarineOrAirMobileStation(RXData.Callsign) then
        RXData.QSOPoints := 2
      else
        if RXData.QTH.Continent = Europe then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 2;

    CupRFMethod:
      begin

        if (MyGrid <> '') and (RXData.QTHString { .DomesticQTH} <> '') then
        begin
          Distance := GetDistanceBetweenGrids(MyGrid, RXData.QTHString {DomesticQTH});

          if Distance > 7000 then RXData.QSOPoints := 62;
          if Distance <= 7000 then RXData.QSOPoints := 57;
          if Distance <= 6000 then RXData.QSOPoints := 52;
          if Distance <= 5000 then RXData.QSOPoints := 47;
          if Distance <= 4000 then RXData.QSOPoints := 42;
          if Distance <= 3000 then RXData.QSOPoints := 38;
          if Distance <= 2000 then RXData.QSOPoints := 35;
          if Distance <= 1000 then RXData.QSOPoints := 31;
            //            if RXData.Band = Band160 then RXData.QSOPoints := round(RXData.QSOPoints * 1.3);
            //            if RXData.Band = Band80 then RXData.QSOPoints := round(RXData.QSOPoints * 1.25);
            //            if RXData.Band = Band40 then RXData.QSOPoints := round(RXData.QSOPoints * 1.15);
            //            if RXData.Band = Band10 then RXData.QSOPoints := round(RXData.QSOPoints * 1.1);
        end
        else
          RXData.QSOPoints := 1;

      end;
    UA4WMethod:
      begin
        RXData.QSOPoints := 2;

        if GetOblast(MyCall) = '4W' then
        begin
          if RXData.DomesticQTH <> LowerCase(MyState)
            then RXData.QSOPoints := 4;
          Exit;
        end;

        if RXData.DomesticQTH <> LowerCase(MyState) then
        begin
          if RXData.Band = Band80 then RXData.QSOPoints := 3;
          if RXData.Band = Band160 then RXData.QSOPoints := 5;

          if GetOblast(RXData.Callsign) = '4W' then
          begin
            if RXData.Band = Band80 then RXData.QSOPoints := 5;
            if RXData.Band = Band160 then RXData.QSOPoints := 10;
            MyZoneValue := CountryTable.GetCQZone(MyCall);
            if (MyZoneValue = 18) or (MyZoneValue = 19) then
            begin
              if RXData.Band = Band80 then RXData.QSOPoints := 10;
              if RXData.Band = Band160 then RXData.QSOPoints := 20;
            end;
          end;
        end;

      end;
    {2007
    Очки за связи начисляются по таблице (см. "комментарий").
    За каждую новую зону на каждом диапазоне, независимо от периода, начисляется 50 очков.
    За каждую новую область, независимо от диапазона и периода, начисляется 50 очков.
    }
    ChampionshipRFMethod:
      begin
        if RussianID(RXCty) then
        begin
          RXData.DomMultQTH := GetRussiaOblastID(RXData.Callsign);
          if MyState = '' then Exit;
          if not (MyState[1] in ['1'..'7']) then Exit;
          if not (RXData.Zone in [1..7]) then Exit;
          RXData.QSOPoints := ChampionshipRFPointsArray[Ord(MyState[1]) - 48 + (RXData.Zone - 1) * 7];
        end;
      end;

    ChampionshipUkrMethod:
      begin
        if RXCty <> 'UR' then Exit;
        //if (RXData.Band = Band80) or (RXData.Band = Band160) then
        RXData.QSOPoints := 2;
      end;

    CupUA1DZMethod:
      begin
        RXData.QSOPoints := 1;
        if MyState <> '' then
        begin
          if RussianID(RXCty) then
//            if RXData.DomMultQTH = '' then
            RXData.DomMultQTH := GetRussiaOblastID(RXData.Callsign);
        end
        else
          if RXData.Callsign = 'RM1DZ' then RXData.QSOPoints := 20;
        //        RXData.Prefix := RXData.Callsign;
      end;

    UA4NQSOPointMethod:
      begin
        if RXData.Zone <> StrToInt(MyState) then RXData.QSOPoints := 2 else RXData.QSOPoints := 1;
      end;

    WWPMCQSOPointMethod:
      begin
        RXData.QSOPoints := 5;
        if MyState = '' then
        begin
          if RXData.QTHString <> '' then RXData.QSOPoints := 25;
        end
        else
        begin
          if RXData.QTHString <> '' then if MyState <> RXData.QTHString then RXData.QSOPoints := 10;
        end;
      end;

    JTDXQSOPointMethod:
      begin
{
        if RXCty = 'JT' then
        begin
          RXData.Prefix := RXData.Callsign;
          if MyContinent = Asia then RXData.QSOPoints := 4 else RXData.QSOPoints := 8;
          if MyCountry = 'JT' then RXData.QSOPoints := 0;
          Exit;
        end;
}
        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 3
        else
          if RXCty <> MyCountry then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 1;

        if RXCty = 'JT' then if MyCountry = 'JT' then RXData.QSOPoints := 0;

      end;

    LZDXQSOPointMethod:
      begin
        begin
          if RXCty = 'LZ' then RXData.QSOPoints := 10
          else
          begin
            if MyContinent <> RXData.QTH.Continent then
              RXData.QSOPoints := 3
            else
              RXData.QSOPoints := 1;
          end;
        end;
      end;
    OldNewYearQSOPointMethod:
      begin
        RXData.QSOPoints := RXData.Age {RXData.NumberReceived};
      end;

    YouthChampionshipRFMethod:
      begin
        //        if RussianID(RXCty) then
        if RXData.Band in [Band40, Band20] then
        begin

          RXData.QSOPoints := 1;
          RXData.DomMultQTH := GetRussiaOblastID(RXData.Callsign);

        end;
      end;

    ChampionshipRFASMethod:
      if (MyState <> '') and (RXData.QTHString { .DomesticQTH} <> '') then
        if StringIsAllNumbers(MyState) then
        begin
          la1 := StrToInt(RXData.QTHString[1]);
          lo1 := StrToInt(Copy(RXData.QTHString, 2, 2));

          la2 := StrToInt(MyState[1]);
          lo2 := StrToInt(Copy(MyState, 2, 2));
          RXData.QSOPoints := Abs(la1 - la2) + Abs(lo1 - lo2) + 4;
        end;
    YUDXQSOPointMethod:
      begin
        if (RXCty = 'YU') and (MyCountry = 'YU') then
        begin
          RXData.QSOPoints := 1;
          Exit;
        end;

        if MyContinent = RXData.QTH.Continent then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 4;
      end;

    RegionOneFieldDayRCCQSOPointMethod:
      begin
        if MyContinent = RXData.QTH.Continent then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 3;
        Result := pos('/P', RXData.Callsign);
        if Result = 0 then
          Result := pos('/M', RXData.Callsign);
        if Result = length(RXData.Callsign) - 1 then RXData.QSOPoints := 4;
      end;

    GACWWWSACWQSOPointMethod:
      begin
        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 3
        else
          if RXCty <> MyCountry then
            RXData.QSOPoints := 1
          else RXData.QSOPoints := 0;
        if RXData.QTH.Continent = SouthAmerica then RXData.QSOPoints := 5;
      end;

    LQPQSOPointMethod:
      begin
        RXData.QSOPoints := 1000;
        if (RXData.Name = 'LOCUST') or (RXData.Callsign = 'K6VVA') then RXData.QSOPoints := 5000;
      end;

    ArktikaSpringQSOPointMethod:
      begin
        if RXData.DomMultQTH <> '' then RXData.QSOPoints := 3 else RXData.QSOPoints := 1;
      end;

    UNDXQSOPointMethod:
      begin
        if RXData.QTH.Continent <> MyContinent then RXData.QSOPoints := 5
        else
          if RXCty <> MyCountry then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 2;

        if RXCty = 'UN' then
          if MyCountry <> 'UN' then
            RXData.QSOPoints := 10;
      end;

    KingOfSpainQSOPointMethod:
      begin
        if not SpanishStation(RXCty) then
          RXData.QSOPoints := 1
        else
        begin
          if SpanishStation(MyCountry) then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 3;
        end;
      end;

    GagarinCupQSOPointMethod:
      begin

        if RXData.QTH.Continent <> MyContinent then RXData.QSOPoints := 4
        else
          if RXCty <> MyCountry then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 2;

        if RXData.Band in [Band160, Band80] then RXData.QSOPoints := RXData.QSOPoints * 3;
        if RXData.Band in [Band40] then RXData.QSOPoints := RXData.QSOPoints * 2;
      end;
{
    MMAAQSOPointMethod:
      begin
        if RXData.Band in [Band80..Band10] then
        begin
          if RXData.QTH.Continent <> MyContinent then RXData.QSOPoints := 3
          else
            if RXCty <> MyCountry then
              RXData.QSOPoints := 2
            else
              RXData.QSOPoints := 1;
          if pos('M', RXData.QTHString) <> 0 then RXData.QSOPoints := 5;
          if pos('YL', RXData.QTHString) <> 0 then RXData.QSOPoints := 5;
          if pos('QRP', RXData.QTHString) <> 0 then RXData.QSOPoints := 5;
        end;
      end;
}
    Radio160QSOPointMethod:
      begin
        if length(RXData.DomMultQTH) = 2 then
        begin
          if RXData.DomMultQTH[1] in ['a'..'z'] then
          begin
            if RXData.DomMultQTH[2] in ['0'..'9'] then
              if length(MyState) >= 2 then
              begin
                la1 := Abs(Ord(UpCase(RXData.DomMultQTH[1])) - Ord(MyState[1])) + 1;
                la2 := Abs(Ord(UpCase(RXData.DomMultQTH[2])) - Ord(MyState[2])) + 1;
                if la1 >= la2 then RXData.QSOPoints := la1 else RXData.QSOPoints := la2;
                Exit;
              end;
            if RXData.DomMultQTH[2] = 'x' then RXData.QSOPoints := 30;
          end;
        end;
      end;

    R9WUW9WKMemorialQSOPointMethod:
      begin
//        if RXData.Callsign = 'R100W' then RXData.QSOPoints := 10
//        else
        case RXData.Zone of
          1, 2: RXData.QSOPoints := 3;
          3: RXData.QSOPoints := 4;
          5: RXData.QSOPoints := 10;
        end;
      end;

    WRTCQSOPointMethod:
      if RXData.Band in [Band80..Band10] then
      begin

        if RXData.Zone = 29 then
          RXData.QSOPoints := 2
        else
          if RXData.QTH.Continent = Europe then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 5;
      end;

  end; { of case }
end;

procedure SendMultiInfoMessage(Band: BandType; Mode: ModeType; Message: Str80);

var
  Sum                                   : Byte;

begin
  Sum := CheckSum(Message);

  if Sum = LastMultiInfoMessageSum[Band, Mode] then Exit;

  LastMultiInfoMessageSum[Band, Mode] := Sum;

  Message := AddBand(Band) + AddMode(Mode) + Message;

  SendMultiCommand(MultiBandAddressArray[Band], $FF, MultiInformationMessage, Message);
end;

procedure RotorControl(Heading: integer);
var
  nNumberOfBytesToWrite                 : Cardinal;
  TempPchar                             : PChar;
begin
  if ActiveRotatorPort = NoPort then Exit;
  case ActiveRotatorType of
    OrionRotator: TempPchar := '#%03u'#$D;
    DCU1Rotator: TempPchar := 'AP1%03u;AM1;';
    YaesuRotator: TempPchar := 'M%03u'#$D;
    AlfaSpidRotator:
      begin
        TempPchar := 'W%03u0'#01;
        inc(Heading, 360);
      end;
  end;
  Windows.ZeroMemory(@wsprintfBuffer, SizeOf(wsprintfBuffer));
  asm
  push heading
  end;
  nNumberOfBytesToWrite := wsprintf(wsprintfBuffer, TempPchar);
  asm add esp,12
  end;

  if ActiveRotatorType = AlfaSpidRotator then
  begin
    nNumberOfBytesToWrite := 13;
    wsprintfBuffer[11] := #$2F;
    wsprintfBuffer[12] := #$20;
  end;

  sWriteFile(CPUKeyer.SerialPortConfigured_Handle[ActiveRotatorPort], wsprintfBuffer, nNumberOfBytesToWrite);
end;

function MarineOrAirMobileStation(Call: CallString): boolean;

{KK1L: 6.68 This function will return TRUE if the callsign passed to it is marine
  or air mobile station. }

var
  TempString                            : Str20;
  l                                     : integer;
begin
  MarineOrAirMobileStation := False;
  l := length(Call);
  if l < 4 then Exit;
  if Call[l - 2] <> '/' then Exit;
  if (Call[l] = 'M') and (Call[l - 1] in ['A', 'M']) then MarineOrAirMobileStation := True;
{
  MarineOrAirMobileStation := False;
  TempString := PostcedingString(Call, '/');
  if StringHas(TempString, '/') then TempString := PostcedingString(TempString, '/');
  if length(TempString) = 2 then if ((TempString = 'MM') or (TempString = 'AM')) then MarineOrAirMobileStation := True;
}
end;

function IsR150Country(OblastDigit, OblastChar: Char): boolean;

begin
  Result := True;
  case OblastDigit of
    '0': if OblastChar in ['F', 'O', 'Q', 'Y', 'W'] then Exit;
    '1': if OblastChar = 'N' then Exit;
    '4': if OblastChar in ['P', 'S', 'U', 'W', 'Y'] then Exit;
    '6': if OblastChar in ['E', 'I', 'J', 'W', 'X', 'Y'] then Exit;
    '9': if OblastChar in ['W', 'X', 'Z'] then Exit;
  end;
  Result := False;
end;

function InSameFederalOkrug(HisCallsign: CallString): boolean;
var
  MyOBlast, HisOblast                   : string[2];
  MyFederalOkrug, HisFederalOkrug       : FederalOkrugs;
begin
  Result := True;
  if StringHas(MyCall, '/') then Exit;
  MyOBlast := GetOblast(MyCall);
  if MyOBlast = '' then Exit;

  if StringHas(HisCallsign, '/') then Exit;
  HisOblast := GetOblast(HisCallsign);
  if HisOblast = '' then Exit;

  MyFederalOkrug := GetFederalOkrug(MyOBlast[1], MyOBlast[2]);
  if MyFederalOkrug = UnKnownOkrug then Exit;

  HisFederalOkrug := GetFederalOkrug(HisOblast[1], HisOblast[2]);
  if HisFederalOkrug = UnKnownOkrug then Exit;
  Result := HisFederalOkrug = MyFederalOkrug;
end;

function GetFederalOkrug(OblastDigit, OblastChar: Char): FederalOkrugs;

begin
  Result := UnKnownOkrug;
  case OblastDigit of
    '1', '2': Result := SeveroZapadniy;
    '3':
      begin
        if OblastChar = 'T' then Result := Privolzhskiy else
          Result := Centralniy;
      end;
    '4':
      begin
        if OblastChar = 'A' then Result := Yuzhniy else
          Result := Privolzhskiy;
      end;
    '6': Result := Yuzhniy;
    '8': Result := Sibirskiy;
    '9':
      begin
        if OblastChar = 'X' then Result := SeveroZapadniy
        else
          if OblastChar in ['F', 'T', 'S', 'W'] then Result := Privolzhskiy
          else
            if OblastChar in ['A', 'C', 'D', 'J', 'L', 'K', 'Q'] then Result := Uralskiy
            else
              Result := Sibirskiy;
      end;
    '0':
      begin
        if OblastChar in ['A', 'B', 'H', 'O', 'S', 'U', 'W', 'Y'] then Result := Sibirskiy
        else
          Result := DalneVostochnyiy;
      end;
  end;
end;

function ProcessExchange(ExchangeString: Str80; var RData: ContestExchange): boolean;

begin
  case ActiveExchange of

    CheckAndChapterOrQTHExchange:
      ProcessExchange := ProcessCheckAndChapterOrQTHExchange(ExchangeString, RData);

    ClassDomesticOrDXQTHExchange:
      ProcessExchange := ProcessClassAndDomesticOrDXQTHExchange(ExchangeString, RData);

    KidsDayExchange:
      ProcessExchange := ProcessKidsExchange(ExchangeString, RData);

    NameQTHAndPossibleTenTenNumber:
      ProcessExchange := ProcessNameQTHAndPossibleTenTenNumberExchange(ExchangeString, RData);

    NameAndDomesticOrDXQTHExchange:
      ProcessExchange := ProcessNameAndDomesticOrDXQTHExchange(ExchangeString, RData);

    NameAndPossibleGridSquareExchange:
      ProcessExchange := ProcessNameAndPossibleGridSquareExchange(ExchangeString, RData);

    QSONumberAndNameExchange:
      ProcessExchange := ProcessQSONumberAndNameExchange(ExchangeString, RData);

    QSONumberAndGeoCoordinates:
      ProcessExchange := ProcessQSONumberAndGeoCoordinatesExchange(ExchangeString, RData);

    QSONumberAndCoordinatesSum:
      ProcessExchange := ProcessQSONumberAndCoordinatesSumExchange(ExchangeString, RData);

    QSONumberAndZone:
      ProcessExchange := ProcessQSONumberAndZoneExchange(ExchangeString, RData);

    QSONumberDomesticOrDXQTHExchange:
      ProcessExchange := ProcessQSONumberAndDomesticOrDXQTHExchange(ExchangeString, RData);

    QSONumberDomesticQTHExchange:
      ProcessExchange := ProcessQSONumberAndDomesticQTHExchange(ExchangeString, RData);

    QSONumberAndGridSquare:
      ProcessExchange := ProcessQSONumberAndGridSquareExchange(ExchangeString, RData);

    QSONumberNameChapterAndQTHExchange:
      ProcessExchange := ProcessQSONumberNameChapterAndQTHExchange(ExchangeString, RData);

    QSONumberNameDomesticOrDXQTHExchange:
      ProcessExchange := ProcessQSONumberNameAndDomesticOrDXQTHExchange(ExchangeString, RData);

    RSTAgeExchange:
      ProcessExchange := ProcessRSTAndAgeExchange(ExchangeString, RData);

    AgeAndQSONumberExchange: ProcessExchange := ProcessAgeAndQSONumberExchange(ExchangeString, RData);

    RSTAndContinentExchange:
      ProcessExchange := ProcessRSTAndContinentExchange(ExchangeString, RData);

    RSTALLJAPrefectureAndPrecedenceExchange:
      ProcessExchange := ProcessRSTAllJAPrefectureAndPrecedenceExchange(ExchangeString, RData);

    RSTAndGridExchange:
      ProcessExchange := ProcessRSTAndGridSquareExchange(ExchangeString, RData);

    RSTAndOrGridExchange:
      ProcessExchange := ProcessRSTAndOrGridSquareExchange(ExchangeString, RData);

    RSTAndPostalCodeExchange:
      ProcessExchange := ProcessRSTAndPostalCodeExchange(ExchangeString, RData);

    RSTAndQSONumberOrDomesticQTHExchange:
      ProcessExchange := ProcessRSTAndQSONumberOrDomesticQTHExchange(ExchangeString, RData);

    RSTDomesticQTHExchange:
      ProcessExchange := ProcessRSTAndDomesticQTHExchange(ExchangeString, RData);

    RSTDomesticOrDXQTHExchange:
      ProcessExchange := ProcessRSTAndDomesticOrDXQTHExchange(ExchangeString, RData);

    {       RSTDomesticQTHOrQSONumberExchange:
                IF RData.DXQTH <> '' THEN
                    ProcessExchange := ProcessRSTAndQSONumberExchange (ExchangeString, RData)
                ELSE
                    ProcessExchange := ProcessRSTAndDomesticQTHExchange (ExchangeString, RData);

                    Changed in 6.57

    }
    RSTDomesticQTHOrQSONumberExchange:
      if DomesticCountryCall(RData.Callsign) then
        ProcessExchange := ProcessRSTAndDomesticQTHExchange(ExchangeString, RData)
      else
        ProcessExchange := ProcessRSTAndQSONumberExchange(ExchangeString, RData);

    RSTNameAndQTHExchange:
      ProcessExchange := ProcessRSTNameAndQTHExchange(ExchangeString, RData);

    RSTPossibleDomesticQTHAndPower:
      ProcessExchange := ProcessRSTPossibleDomesticQTHAndPowerExchange(ExchangeString, RData);

    RSTPowerExchange:
      ProcessExchange := ProcessRSTAndPowerExchange(ExchangeString, RData);

    RSTPrefectureExchange:
      ProcessExchange := ProcessRSTAndPrefectureExchange(ExchangeString, RData);

    RSTQSONumberExchange:
      ProcessExchange := ProcessRSTAndQSONumberExchange(ExchangeString, RData);

    NZFieldDayExchange:
      ProcessExchange := ProcessNZFieldDayExchange(ExchangeString, RData);

    RSTQSONumberAndDomesticQTHExchange:
      ProcessExchange := ProcessRSTQSONumberAndDomesticQTHExchange(ExchangeString, RData);

    QSONumberAndPreviousQSONumber:
      ProcessExchange := ProcessQSONumberAndPreviousQSONumber(ExchangeString, RData);

    RSTQSONumberAndGridSquareExchange:
      ProcessExchange := ProcessRSTQSONumberAndGridSquareExchange(ExchangeString, RData);

    RSTQSONumberAndPossibleDomesticQTHExchange:
      ProcessExchange := ProcessRSTQSONumberAndPossibleDomesticQTHExchange(ExchangeString, RData);

    QSONumberAndPossibleDomesticQTHExchange:
      ProcessExchange := ProcessQSONumberAndPossibleDomesticQTHExchange(ExchangeString, RData); {KK1L: 6.73}

    RSTQSONumberAndRandomCharactersExchange:
      ProcessExchange := ProcessRSTQSONumberAndRandomCharactersExchange(ExchangeString, RData);

    RSTQTHNameAndFistsNumberOrPowerExchange:
      ProcessExchange := ProcessRSTQTHNameAndFistsNumberOrPowerExchange(ExchangeString, RData);

    RSTQTHExchange:
      ProcessExchange := ProcessRSTAndQTHExchange(ExchangeString, RData);

    RSTZoneAndPossibleDomesticQTHExchange:
      ProcessExchange := ProcessRSTZoneAndPossibleDomesticQTHExchange(ExchangeString, RData);

    RSTZoneExchange:
      ProcessExchange := ProcessRSTAndZoneExchange(ExchangeString, RData);

    RSTZoneOrSocietyExchange:
      if StringIsAllNumbersOrSpaces(ExchangeString) then
        ProcessExchange := ProcessRSTAndZoneExchange(ExchangeString, RData)
      else
      begin
        ExchangeString := UpperCase(ExchangeString);
        ProcessExchange := ProcessRSTAndDomesticQTHExchange(ExchangeString, RData);
      end;

    QSONumberPrecedenceCheckDomesticQTHExchange:
      ProcessExchange := ProcessQSONumberPrecedenceCheckDomesticQTHExchange(ExchangeString, RData);

    RSTLongJAPrefectureExchange: {KK1L: 6.72 JA}
      begin
        ExchangeString := UpperCase(ExchangeString);
        ProcessExchange := ProcessRSTAndJAPrefectureExchange(ExchangeString, RData);
      end;
    RSTZoneOrDomesticQTH:
      if DomesticCountryCall(RData.Callsign) then
        ProcessExchange := ProcessRSTAndDomesticQTHExchange(ExchangeString, RData)
      else
        ProcessExchange := ProcessRSTAndZoneExchange(ExchangeString, RData);

  end; { of case }
end;

procedure LogStringToRXData(LogString: Str80; var RXData: ContestExchange);

var
  ExchangeString                        : ShortString {Str80};

begin
  ExchangeString := GetLogEntryExchangeString(LogString);

  if ExchangeInformation.RST then RemoveFirstString(ExchangeString);

  ProcessExchange(ExchangeString, RXData);
end;

procedure ProcessPartialCallAndInitialExchange(RXData: ContestExchange);

begin
  // if PartialCallEnable or ExchangeMemoryEnable then
  //    AddCallToPartialList(RXData.Callsign, GetInitialExchangeStringFromContestExchange(RXData));
end;

procedure CreateAndSendSAPMultiInfoMessage;

var
  TempString                            : Str80;
  NumberString                          : Str20;
  Index                                 : integer;

begin
  {
    if K1EANetworkEnable then Exit;

    TempString := MultiInfoMessage;

    if TempString = '' then Exit;

    if pos('$', TempString) > 0 then
    begin
      Index := pos('$', TempString);
      Delete(TempString, Index, 1);
      Insert('S&P', TempString, Index);
    end;

    if pos('%', MultiInfoMessage) > 0 then
    begin
      Index := pos('%', TempString);
      Delete(TempString, Index, 1);
      Str(Rate, NumberString);
      Insert(NumberString, TempString, Index);
    end;

    SendMultiInfoMessage(ActiveBand, ActiveMode, TempString);
  }
end;

procedure CreateAndSendCQMultiInfoMessage;

var
  TempString, NumberString              : Str80;
  Index                                 : integer;
  Freq                                  : LONGINT;
  FreqStr                               : Str20;

begin
  {
    TempString := MultiInfoMessage;

    if K1EANetworkEnable then
    begin

           //Send run message with current stable frequency

      case ActiveRadio of
        radioone: Freq := Radio1.FilteredStatus.Freq;
        RadioTwo: Freq := Radio2.FilteredStatus.Freq;
      else Freq := 0;
      end;

      if Freq > 0 then
      begin
        Str(Freq, FreqStr);
        TempString := 'M' + K1EAStationID + ' ' + FreqStr + ' ';
        SendMultiMessage(TempString);
        UpdateK1EAStationInfo(Run, K1EAStationID, FreqStr);
      end;

      Exit;
    end;

     // TR Network

    if MultiInfoMessage = '' then Exit;

    if pos('$', TempString) > 0 then
    begin
      Index := pos('$', TempString);
      Delete(TempString, Index, 1);

      if LastDisplayedFreq[radioone] > 0 then
        Str(LastDisplayedFreq[radioone], NumberString)
      else
        if RadioSetFreq > 0 then
          Str(RadioSetFreq, NumberString)
        else
          NumberString := '00000';

      Delete(NumberString, length(NumberString), 1);
      Delete(NumberString, length(NumberString), 1);
      Insert('.', NumberString, length(NumberString));
      Insert(NumberString, TempString, Index);
    end;

    if pos('%', MultiInfoMessage) > 0 then
    begin
      Index := pos('%', TempString);
      Delete(TempString, Index, 1);
      Str(Rate, NumberString);
      Insert(NumberString, TempString, Index);
    end;

    SendMultiInfoMessage(ActiveBand, ActiveMode, TempString);
  }
end;

function GetSentRSTFromExchangeString(var ExchangeString: ShortString {Str40}): Word;

var
  PotentialRSTSent                      : Str80 {40};
  TempString                            : ShortString {Str40};
//  RSTString                   : string[3] {Str20};

begin
  GetSentRSTFromExchangeString := 0;

  if not LookForRSTSent then Exit;

  TempString := ExchangeString;

  while TempString <> '' do
  begin
    PotentialRSTSent := RemoveLastString(TempString);

    if Copy(PotentialRSTSent, 1, 1) = 'S' then
    begin
      Delete(PotentialRSTSent, 1, 1);

      if StringIsAllNumbers(PotentialRSTSent) then
        if LooksLikeRST(PotentialRSTSent, Result, ActiveMode) then
        begin
          GetSentRSTFromExchangeString := Result;

                { Delete all the stuff we have }

          Delete(ExchangeString, 1, length(TempString));

                { Remove the callsign }

          RemoveFirstString(ExchangeString);

                { Rebuild the exchange string without the callsign }

          ExchangeString := TempString + ' ' + ExchangeString;
          Exit;
        end;

    end;
  end;
end;

function SpecAndExchangeMatch(Spec: Str40; Exchange: Str40): boolean;

begin
  SpecAndExchangeMatch := False;
end;

function FoundExchangeFromTemplate(Template: string; ExchangeString: Str40; var RData: ContestExchange): boolean;

var
  FormatSpec, Exchange                  : ShortString;
  TestSpec, TestExchange                : Str40;

begin
  FoundExchangeFromTemplate := False;

  FormatSpec := PrecedingString(Template, '|');

  Exchange := ExchangeString;

  while (FormatSpec <> '') and (Exchange <> '') do
  begin
    TestSpec := RemoveFirstString(FormatSpec);
    TestExchange := RemoveFirstString(Exchange);

    if not SpecAndExchangeMatch(TestSpec, TestExchange) then Exit;
  end;

  { We have found that the format spec and the exchange match up }

end;

function ProcessTemplateExchange(ExchangeString: Str40; var RData: ContestExchange): boolean;

var
  Entry                                 : integer;

begin
  ProcessTemplateExchange := False;

  if NumberExchangeTemplates = 0 then Exit;

  for Entry := 0 to NumberExchangeTemplates - 1 do
    if FoundExchangeFromTemplate(ExchangeTemplateList[Entry]^, ExchangeString, RData) then
    begin
      ProcessTemplateExchange := True;
      Exit;
    end;

end;

procedure PassStationToCTNetwork;

var
  PassString                            : Str40;

begin
  {
    if not K1EANetworkEnable then Exit;

    PassString := QuickEditResponse('Enter pass info (i.e., KQ2M 14150.2) : ', 30);

    if PassString <> '' then
      SendMultiMessage('P' + K1EAStationID + ' ' + PassString + ' ');
     }
end;

begin
  CD.CellBuffer.MaximumMemoryToUse := 40000 * ua4wliscpconst {*4 - ua4wli};
  StuffInit;
end.

