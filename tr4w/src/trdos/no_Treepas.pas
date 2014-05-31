unit Treepas;

{ This unit contains all the neat little library routines that are used
    in most of the N6TR programs.  They are not specfic to any program
    which is a requirement for adding new routines. }

{$O+}
{$F+}

interface

uses
  BeepUnit,
  Classes,
  Math,
  LPTIO,

  WINDOWS;


type
  Str10 = string[10];
  Str20 = string[20];
  Str30 = string[30];
  Str40 = string[40];
  Str80 = string[80];
  Str160 = string[160];
  Str255 = string[255];

  CallString = string[12];
  GridString = string[4];
  PrefixString = string[5];
  NameString = string[6];
  RSTString = string[3];

  MouseTypeType = (NoMouse, OneButton, TwoButton, ThreeButton);

  ParityType = (NoParity, EvenParity, OddParity);

  TwoBytes = array[1..2] of BYTE;
  fourBYTEs = array[1..4] of BYTE;
  EightBytes = array[1..8] of BYTE;

  PortType = (NoPort, Serial1, Serial2, Serial3, Serial4, Serial5, Serial6,
    Parallel1, Parallel2, Parallel3, DRSI);

  BandType = (Band160, Band80, Band40, Band20, Band15, Band10,
    Band30, Band17, Band12, Band6, Band2, Band222, Band432,
    Band902, Band1296, Band2304, Band3456, Band5760, Band10G,
    Band24G, BandLight, All, NoBand);

  ModeType = (cw, Digital, Phone, Both, NoMode, FM);
 {   ModeType = (CW, Phone, Both, NoMode, FM, Digital); }

  MultiBandAddressArrayType = array[BandType] of BYTE;

const

  HexChars                    : array[0..$F] of Char = '0123456789ABCDEF';

  BandString                  : array[BandType] of string[3] = (
    '160',
    ' 80',
    ' 40',
    ' 20',
    ' 15',
    ' 10',
    ' 30',
    ' 17',
    ' 12',
    '  6',
    '  2',
    '222',
    '432',
    '902',
    '1GH',
    '2GH',
    '3GH',
    '5GH',
    '10G',
    '24G',
    'LGT',
    'All',
    'NON');

  ModeString                  : array[ModeType] of string[3] = ('CW ',
    'DIG',
    'SSB',
    'BTH',
    'NON',
    'FM ');

  MonthTags                   : array[1..12] of string[3] = ('Jan', 'Feb', 'Mar', 'Apr',
    'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

  BufferLength                = 2048;

  MultiBandAddressArray       : MultiBandAddressArrayType =
    ($E0, $E1, $E2, $E3, $E4, $E5, {160/80/40/20/15/10}
    $E6, $E7, $E8, $E9, $EA, $EB, $EC, {30/17/12/6/2/222/432}
    $ED, $EE, $EF, $F0, $F1, $F2, $F3, $F4, {902/1GH/2GH/3GH/5GH/10G/24G/LGT}
    $FF, $FF); {All/Non}

type

  FileComparisonType = (Before, Same, After);

  TimeRecord = record
    Hour: Word;
    Minute: Word;
    Second: Word;
    Sec100: Word;
  end;

const
  FrameEnd                    = $C0;
  FrameEscape                 = $DB;
  TransposedFrameEnd          = $DC;
  TransposedFrameEscape       = $DD;

  FrameEndChr                 = CHR($C0);
  FrameEscapeChr              = CHR($DB);
  TransposedFrameEndChr       = CHR($DC);
  TransposedFrameEscapeChr    = CHR($DD);

  MaximumFileNames            = 200;

  DegreeSymbol                = 'ш';

  ModemStatusAddressOffset    = 6;
  ModemControlAddressOffset   = 4;
  ModemLineControlAddressOffset = 3;
  PortStatusAddressOffset     = 5;
  ReceiveDataAddressOffset    = 0;
  TransmitDataAddressOffset   = 0;

 { Key code definitions }

  NullCharacter               = CHR(0);
  NullKey                     = CHR(0);
  Beep                        = CHR(7);
  BackSpace                   = CHR(8);
  TabKey                      = CHR(9);
  CarriageReturn              = CHR($D);
  LineFeed                    = CHR($A);
  EscapeKey                   = CHR($1B);
  SpaceBar                    = ' ';
  ShiftTab                    = CHR(15); { After null char }

  F1                          = CHR(59); { Function key codes }
  F2                          = CHR(60);
  F3                          = CHR(61);
  F4                          = CHR(62);
  F5                          = CHR(63);
  F6                          = CHR(64);
  F7                          = CHR(65);
  F8                          = CHR(66);
  F9                          = CHR(67);
  F10                         = CHR(68);
  F11                         = CHR($85);
  F12                         = CHR($86);
  {временно???}
const
  AltDash                     = CHR(130);
  ControlInsert               = CHR(146);
  ControlDelete               = CHR(147);
  AltQ                        = CHR(16);
  AltW                        = CHR(17);
  AltE                        = CHR(18);
  AltR                        = CHR(19);
  AltT                        = CHR(20);
  AltY                        = CHR(21);
  AltU                        = CHR(22);
  AltI                        = CHR(23);
  AltO                        = CHR(24);
  AltP                        = CHR(25);
  AltA                        = CHR(30);
  AltS                        = CHR(31);
  AltD                        = CHR(32);
  AltF                        = CHR(33);
  AltG                        = CHR(34);
  AltH                        = CHR(35);
  AltJ                        = CHR(36);
  AltK                        = CHR(37);
  AltL                        = CHR(38);
  AltZ                        = CHR(44);
  AltX                        = CHR(45);
  AltC                        = CHR(46);
  AltV                        = CHR(47);
  AltB                        = CHR(48);
  AltN                        = CHR(49);
  AltM                        = CHR(50);

  ShiftF1                     = CHR(84);
  ShiftF2                     = CHR(85);
  ShiftF3                     = CHR(86);
  ShiftF4                     = CHR(87);
  ShiftF5                     = CHR(88);
  ShiftF6                     = CHR(89);
  ShiftF7                     = CHR(90);
  ShiftF8                     = CHR(91);
  ShiftF9                     = CHR(92);
  ShiftF10                    = CHR(93);
  ShiftF11                    = CHR($87);
  ShiftF12                    = CHR($88);



  ControlF1                   = CHR(94);
  ControlF2                   = CHR(95);
  ControlF3                   = CHR(96);
  ControlF4                   = CHR(97);
  ControlF5                   = CHR(98);
  ControlF6                   = CHR(99);
  ControlF7                   = CHR(100);
  ControlF8                   = CHR(101);
  ControlF9                   = CHR(102);
  ControlF10                  = CHR(103);
  ControlF11                  = CHR($89);
  ControlF12                  = CHR($8A);

  AltF1                       = CHR(104);
  AltF2                       = CHR(105);
  AltF3                       = CHR(106);
  AltF4                       = CHR(107);
  AltF5                       = CHR(108);
  AltF6                       = CHR(109);
  AltF7                       = CHR(110);
  AltF8                       = CHR(111);
  AltF9                       = CHR(112);
  AltF10                      = CHR(113);
  AltF11                      = CHR($8B);
  AltF12                      = CHR($8C);


  Alt1                        = CHR(120);
  Alt2                        = CHR(121);
  Alt3                        = CHR(122);
  Alt4                        = CHR(123);
  Alt5                        = CHR(124);
  Alt6                        = CHR(125);
  Alt7                        = CHR(126);
  Alt8                        = CHR(127);
  Alt9                        = CHR(128);
  Alt0                        = CHR(129);
  AltEqual                    = CHR(131);


  HomeKey                     = CHR(71);
  UpArrow                     = CHR(72);
  PageUpKey                   = CHR(73);
  LeftArrow                   = CHR(75);
  RightArrow                  = CHR(77);
  EndKey                      = CHR(79);
  DownArrow                   = CHR(80);
  PageDownKey                 = CHR(81);
  InsertKey                   = CHR(82);
  DeleteKey                   = CHR(83);

 {KK1L: 6.65 Added following eight definitions}
  AltInsert                   = CHR(162);
  AltDelete                   = CHR(163);


  AltDownArrow                = CHR(160);
  AltUpArrow                  = CHR(152);
  ControlDownArrow            = CHR(145);
  ControlUpArrow              = CHR(141);

 { These are all extended keys }

  ControlLeftArrow            = CHR(115);
  ControlRightArrow           = CHR(116);
  ControlEnd                  = CHR(117);
  ControlPageDown             = CHR(118);
  ControlHome                 = CHR(119);
  ControlPageUp               = CHR(132);

 { Not extended }

  ControlA                    = CHR(1);
  ControlB                    = CHR(2);
  ControlC                    = CHR(3);
  ControlD                    = CHR(4);
  ControlE                    = CHR(5);
  ControlF                    = CHR(6);
  ControlG                    = CHR(7);
  ControlH                    = CHR(8);
  ControlI                    = CHR(9);
  ControlJ                    = CHR(10);
  ControlK                    = CHR(11);
  ControlL                    = CHR(12);
  ControlM                    = CHR(13);
  ControlN                    = CHR(14);
  ControlO                    = CHR(15);
  ControlP                    = CHR(16);
  ControlQ                    = CHR(17);
  ControlR                    = CHR(18);

  Controls                    = CHR(19);
  ControlT                    = CHR(20);
  ControlU                    = CHR(21);
  ControlV                    = CHR(22);
  ControlW                    = CHR(23);
  ControlX                    = CHR(24);
  ControlY                    = CHR(25);
  ControlZ                    = CHR(26);

  ControlLeftBracket          = CHR(27);
  ControlBackSlash            = CHR(28);
  ControlRightBracket         = CHR(29);
  ControlDash                 = CHR(31);

 { The following addresses are used as the bible for finding things in log
     entries from the logging program.         }

  LogEntryBandAddress         = 1;
  LogEntryBandWidth           = 3;
  LogEntryModeAddress         = 4;
  LogEntryModeWidth           = 3;
  LogEntryDayAddress          = 8;
  LogEntryDayWidth            = 2;
  LogEntryMonthAddress        = 11;
  LogEntryMonthWidth          = 3;
  LogEntryYearAddress         = 15;
  LogEntryYearWidth           = 4;
  LogEntryHourAddress         = 18;
  LogEntryHourWidth           = 2;
  LogEntryMinuteAddress       = 21;
  LogEntryMinuteWidth         = 2;
  LogEntryQSONumberAddress    = 24;
  LogEntryQSONumberWidth      = 4;
  LogEntryComputerIDAddress   = 28;
  LogEntryComputerIDWidth     = 1;
  LogEntryCallAddress         = 30;
  LogEntryCallWidth           = 12;
  LogEntryNameSentAddress     = 42;
  LogEntryNameSentWidth       = 1;
  LogEntryExchangeAddress     = 44;
  LogEntryExchangeWidth       = 24;
  LogEntryMultAddress         = 69;
  LogEntryMultWidth           = 8;
  LogEntryPointsAddress       = 77;
  LogEntryPointsWidth         = 2;

type

  BufferArrayType = array[0..BufferLength] of BYTE;

  CharacterBuffer = object
    Tail: integer; { Oldest entry address }
    Head: integer; { Place where new entry goes }
    List: ^BufferArrayType;

      { Set Debug = TRUE to have all activity logged.  This isn't
        actually done in this unit, since we really don't know
        what serial port we are dealing with and if we are coming
        or going.  But it seemed like putting the variables here
        made it easier to think about. }

    Debug: boolean; { Set TRUE to enable debug activity }
    DebugFile: file; { Is setup as a read file if this is an input
      buffer, write file if an output buffer }

    procedure InitializeBuffer;
    procedure AddEntry(Entry: BYTE);
    procedure AddString(Entry: string);
    procedure ClearBuffer;
    function FreeSpace: integer;
    function GetNextByte(var Entry: BYTE): boolean;
    function GetSlippedString(var Entry: string): boolean;
    function GetNextLine(var Entry: string): boolean;
    procedure GoAway;
    function IsEmpty: boolean;
  end;

  ContinentType = (NorthAmerica, SouthAmerica, Europe, Africa, Asia,
    Oceania, UnknownContinent);

  FileNameRecord = record
    NumberFiles: integer;
    List: array[0..MaximumFileNames - 1] of string[12];
  end;

  QTHRecord = record
    Country: integer;
    Continent: ContinentType;
    CountryID: string[6];
    Zone: integer;
    Prefix: PrefixString;
    StandardCall: CallString;
  end;

var
  UseBIOSCOMIO                : boolean;
  UseBIOSKeyCalls             : boolean;
  CodeSpeed                   : BYTE;
  FMMode                      : boolean;
  HourOffset                  : integer;
  QuestionMarkChar            : Char;
  SlashMarkChar               : Char;

  Com5PortBaseAddress         : Word;
  Com6PortBaseAddress         : Word;
  TR4WLpt                     : TLptPortConnection;



function OpenLPT(ISRadio1: boolean; LPT: PortType): boolean;

procedure PTTOn;
procedure PTTOff;


procedure QuickBeep;
function ReadFromSerialPort(port: integer; BytesToRead: Cardinal): string;
function WriteToSerialPort(data: string; port: integer): Cardinal;




function AddBand(Band: BandType): Char;
function AddMode(Mode: ModeType): Char;

function AlphaPartOfString(InputString: Str160): Str80;
function ArcCos(X: REAL): REAL;
function ATan2(Y, X: REAL): REAL;

function BigCompressedCallsAreEqual(Call1, Call2: EightBytes): boolean;
procedure BigCompressFormat(Call: CallString; var CompressedBigCall: EightBytes);
//procedure BigCursor;
function BigExpandedString(Input: EightBytes): Str80;
function BracketedString(LongString: Str160; StartString: Str80; StopString: Str80): Str80;
//{WLI}    FUNCTION  BYTADDR  (Call: Pointer; NumberCalls: INTEGER; A: Pointer): INTEGER;
//{WLI}    FUNCTION  BYTDUPE  (Call: Pointer; NumberCalls: INTEGER; A: Pointer): BOOLEAN;
function HexString(HexByte: BYTE): Str20;
//{WLI}    FUNCTION  BYTSTOCR (List: Pointer; Start: INTEGER): INTEGER;

procedure CalculateBandMode(Freq: LONGINT; var Band: BandType; var Mode: ModeType);
function CaliforniaCall(Call: CallString): boolean;
function CallFitsFormat(Format: CallString; Call: CallString): boolean;
function CallFoundInFile(Callsign: CallString; FileName: Str40): boolean;
function CallSortValue(Call: CallString): LONGINT;
function CharReady(SerialPort: PortType): boolean;

function CheckMouse(var XPos: integer;
  var YPos: integer;
  var Button1: boolean;
  var Button2: boolean): boolean;

function CheckSum(InputString: string): BYTE;

procedure ClearScreen;
function CompareFileTimes(FirstFileName: Str80; SecondFileName: Str80): FileComparisonType;
procedure CompressFormat(Call: CallString; var Output: fourBYTEs);

function Com1PortBaseAddress: Word;
function Com2PortBaseAddress: Word;
function Com3PortBaseAddress: Word;
function Com4PortBaseAddress: Word;

procedure Congrats;
function ControlKeyPressed: boolean;
function CopyFile(SourceFile: Str80; DestFile: Str80): boolean;
function CopyFiles(SourceDirectory: Str80; FileMask: Str80; DestDirectory: Str80): boolean;

procedure DecrementASCIIInteger(var ASCIIString: Str80);
procedure DelayOrKeyPressed(DelayTime: integer);
procedure DeleteFile(FileName: Str80);
function DeleteMult(var LogString: Str80; MultString: Str20): boolean;
procedure DirectoryClearCursor(Entry: integer; StartY: integer);
function DirectoryExists(DirName: Str80): boolean;
procedure DirectoryShowCursor(Entry: integer; StartY: integer);
function DupeTest(Call: Str80): boolean;
function DupingFileExists(Name: Str80): boolean;

function ElaspedTimeString(StartTime: TimeRecord): Str20;
function ElaspedSec100(StartTime: TimeRecord): LONGINT;
function ElaspedMinutes(StartTime: TimeRecord): integer;

function ExpandedString(Input: fourBYTEs): Str80;
procedure ExpandTabs(var InputString: string);
function ExpandTwoBytes(Input: TwoBytes): Str80;

function FileExists(FileName: Str80): boolean;
function FindDirectory(FileName: Str80): Str80;
function FirstLetter(InputString: Str80): Char;
procedure FormFeed;

function GetChecksum8(Call: fourBYTEs): integer;
function GetColorInteger(ColorString: Str80): integer;
function GetDateString: Str80;
function GetDayString: Str80;
procedure GetFileNames(Path: Str80; Mask: Str80; var FileNames: FileNameRecord);
function GetFileSize(FileName: Str80): LONGINT;
function GetFirstString(var LongString: string): Str80;
function GetFullTimeString: Str80;
function GetIntegerTime: integer;

function GetLastString(var LongString: string): Str80;

function GetLogEntryBand(LogEntry: Str160): BandType;
function GetLogEntryCall(LogEntry: Str160): CallString;
function GetLogEntryComputerID(LogEntry: Str160): Char;
function GetLogEntryDateString(LogEntry: Str160): Str160;
function GetLogEntryExchangeString(LogEntry: Str160): Str160;
function GetLogEntryHour(LogEntry: Str160): integer;
function GetLogEntryMode(LogEntry: Str160): ModeType;
function GetLogEntryMultString(LogEntry: Str160): Str160;
function GetLogEntryQSONumber(LogEntry: Str160): integer;
function GetLogEntryQSOPoints(LogEntry: Str160): integer;
function GetLogEntryRSTString(LogEntry: Str160): Str160;
function GetLogEntryIntegerTime(LogEntry: Str160): integer;
function GetLogEntryTimeString(LogEntry: Str160): Str160;
//wli
function GetFileSize_TR(FileName: Str80): LONGINT;


function GetKey(Prompt: Str80): Char;
function GetPrefix(Call: CallString): PrefixString;
function GetReal(Prompt: Str80): REAL;
function GetResponse(Prompt: Str80): Str80;
procedure GetRidOfCarriageReturnLineFeeds(var s: string);
procedure GetRidOfPostcedingSpaces(var s: string);
procedure GetRidOfPrecedingSpaces(var s: string);
function GetSCPCharFromInteger(Index: integer): Char;
function GetSCPIntegerFromChar(InputChar: Char): integer;
function GetStateFromSection(Section: Str20): Str20;
function GetSuffix(Call: CallString): CallString;
function GetTimeString: Str80;
function GetTomorrowString: Str80;
function GetValue(Prompt: Str80): LONGINT;
function GetYearString: Str20;
function GoodCallSyntax(Call: CallString): boolean;
function GoodLookingGrid(Grid: Str20): boolean;

procedure HexToInteger(InputString: Str80; var OutputInteger: integer; var Result: integer);
procedure HexToWord(InputString: Str80; var OutputWord: Word; var Result: integer);

procedure IncrementASCIIInteger(var ASCIIString: Str80);
procedure IncrementMinute(var DateString: Str20; var TimeString: Str80);
function WordValueFromCharacter(Character: Char): Word;
{
procedure InitializeSerialPort(SerialPort: PortType;
  BaudRate: Word;
  Bits: integer;
  Parity: ParityType;
  StopBits: integer);
}
function KeyId(Key: Char): Str80;

function LastLetter(InputString: Str160): Char;
function LastString(InputString: string): Str160;

function LineInput(Prompt: Str160;
  InitialString: Str160;
  OverwriteEnable: boolean;
  ExitOnAltKey: boolean): Str160;

function LowerCase(const S: string): string;
function LooksLikeAGrid(var GridString: Str20): boolean;
function Lpt1BaseAddress: Word;
function Lpt2BaseAddress: Word;
function Lpt3BaseAddress: Word;

function MakeDupeFilename(Band: BandType; Mode: ModeType): Str80;
function MakeTitle(Band: BandType; Mode: ModeType; Contest: Str80; CallUsed: Str80): Str80;
procedure MarkTime(var StartTime: TimeRecord);
function MicroTimeElapsed(StartTime: TimeRecord): LONGINT;
function MinutesToTimeString(Minutes: integer): Str20;
function MultiMessageSourceBand(Source: BYTE): BandType;

function NewKeyPressed: boolean;
function NextMinute(PreviousDateString: Str20; DateString: Str20;
  PreviousTimeString: Str20; TimeString: Str20): boolean;

function NewReadKey: Char;

procedure NoCursor;
//{WLI}    FUNCTION  NUMBYTES (Call1: Pointer; Call2: Pointer): INTEGER;
function NumberPartOfString(InputString: Str160): Str80;

function OkayToProceed: boolean;
function OpenDupeFileForRead(var FileHandle: Text; FileName: Str80): boolean;
function OpenFileForAppend(var FileHandle: Text; FileName: Str80): boolean;
function OpenFileForRead(var FileHandle: Text; FileName: Str80): boolean;
function OpenFileForWrite(var FileHandle: Text; FileName: Str80): boolean;
function OperatorEscape: boolean;

function PacketCharReady(SerialPort: PortType; var CIn: Char): boolean;
procedure PacketSendChar(SerialPort: PortType; CharToSend: Char);
function PartialCall(Pattern: CallString; Call: CallString): boolean;
procedure PinWheel;
function PortableStation(Call: CallString): boolean;
function PostcedingString(LongString: string; Deliminator: string): string;
function PrecedingString(LongString: string; Deliminator: string): string;



function ReadChar(SerialPort: PortType): Char;

function RemoveBand(var LongString: string): BandType;
function RemoveFirstChar(var LongString: string): Char;
function RemoveFirstLongInteger(var LongString: string): LONGINT;
function RemoveFirstReal(var LongString: string): REAL;
function RemoveFirstString(var LongString: string): Str80;
function RemoveLastString(var LongString: string): Str80;
function RemoveMode(var LongString: string): ModeType;

procedure RenameFile(OldName: Str80; NewName: Str80);
procedure ReportError(Prompt: Str80);
function RootCall(Call: CallString): CallString;
function RoverCall(Call: CallString): boolean;

function SameMinute(PreviousDateString: Str20; DateString: Str20;
  PreviousTimeString: Str20; TimeString: Str20): boolean;

procedure SendByte(SerialPort: PortType; ByteToSend: BYTE);
procedure SendChar(SerialPort: PortType; CharToSend: Char);
procedure SendIntegerInMorse(Value: integer);
procedure SendMorse(Message: Str255);
function SendPortEmpty(SerialPort: PortType): boolean;
procedure SendString(SerialPort: PortType; StringToSend: Str160);
procedure SetMorseSpeed(Speed: integer; Pitch: integer);
//procedure SETRTS(SerialPort: PortType);

function ShowDirectoryAndSelectFile(PathAndMask: Str80;
  InitialFile: Str80;
  ClearOnCarriageReturn: boolean): Str80;

function SimilarCall(Call1: CallString; Call2: CallString): boolean;
function SlipMessage(Message: string): string;
procedure SmallCursor;
function StandardCallFormat(Call: CallString; Complete: boolean): CallString;
function StringHas(LongString: Str160; SearchString: Str80): boolean;
function StringHasNumber(Prompt: Str80): boolean;
function StringHasLowerCase(InputString: Str160): boolean;
function StringIsAllNumbers(InputString: Str160): boolean;
function StringIsAllNumbersOrSpaces(InputString: Str160): boolean;
function StringIsAllNumbersOrDecimal(InputString: Str160): boolean;

function StringWithFirstWordDeleted(InputString: Str160): Str160;

function Tan(X: REAL): REAL;
function TimeElasped(StartHour, StartMinute, StartSecond, NumberOfMinutes: integer): boolean;
procedure TimeStamp(var FileWrite: Text);

function UartEmpty(SerialPort: PortType): boolean;
function UpperCase(const S: string): string;

function ValidCallCharacter(CallChar: Char): boolean;
function ValidRST(var Ex: string; var RST: RSTString; Mode: ModeType): boolean;

procedure WaitForKeyPressed;

procedure WriteHexByte(HexByte: BYTE);
procedure WriteHexWord(HexWord: Word);
procedure WriteLnCenter(Prompt: Str80);
procedure WriteLnVarCenter(var FileWrite: Text; Prompt: Str80);
procedure WriteLnLstCenter(Prompt: Str80);
procedure WriteColor(Prompt: Str80; FColor: integer; BColor: integer);
procedure WritePortType(port: PortType);

{ New disk functions }

function GetDiskStatus(Drive: BYTE): integer;

function ReadSectors(NumberSectors: BYTE; Cylinder: Word;
  Sector: BYTE; Head: BYTE;
  Drive: BYTE; Seg, Ofs: Word): integer;

function GetDriveParameters(Drive: BYTE; var DriveType: BYTE;
  var MaxCylinder: Word; var MaxSector: BYTE;
  var MaxHead: BYTE; var NumberDrives: BYTE): integer;


function GetOblast(Call: CallString): Str20;

function InitializeSerialPort(SerialPort: PortType;
  BaudRate: Word;
  Bits: integer;
  Parity: ParityType;
  StopBits: integer): integer;

function BinToDec(b: string): integer;
function power(a, b: integer): integer;


implementation


//{WLI}USES {DOS, Crt,} Printer;
uses
//  BeepUnit,
  Other,
  Unit1,
  LogRadio,
  LogK1EA;


{WLI}
//USES DOS, Crt, Printer;

const
  NoteVeryLoA                 = 220;
  NoteVeryLoASharp            = 235;
  NoteVeryLoBFlat             = 235;
  NoteVeryLoB                 = 250;
  NoteVeryLoBSharp            = 265;
  NoteLoC                     = 265;
  NoteLoCSharp                = 280;
  NoteLoDFlat                 = 280;
  NoteLoD                     = 295;
  NoteLoDSharp                = 312;
  NoteLoEFlat                 = 312;
  NoteLoE                     = 330;
  NoteLoESharp                = 350;
  NoteLoFFlat                 = 330;
  NoteLoF                     = 350;
  NoteLoFSharp                = 372;
  NoteLoGFlat                 = 372;
  NoteLoG                     = 395;
  NoteLoGSharp                = 417;
  NoteLoAFlat                 = 417;
  NoteLoA                     = 440;
  NoteLoASharp                = 470;
  NoteLoBFlat                 = 470;
  NoteLoB                     = 500;
  NoteLoBSharp                = 530;
  NoteCFlat                   = 500;
  NoteC                       = 530;
  NoteCSharp                  = 560;
  NoteDFlat                   = 560;
  NoteD                       = 590;
  NoteDSharp                  = 625;
  NoteEFlat                   = 625;
  NoteE                       = 660;
  NoteESharp                  = 700;
  NoteFFlat                   = 660;
  NoteF                       = 700;
  NoteFSharp                  = 745;
  NoteGFlat                   = 745;
  NoteG                       = 790;
  NoteGSharp                  = 835;
  NoteAFlat                   = 835;
  NoteA                       = 880;
  NoteASharp                  = 940;
  NoteBFlat                   = 940;
  NoteB                       = 1000;
  NoteBSharp                  = 1060;
  NoteHiCFlat                 = 1000;
  NoteHiC                     = 1060;
  NoteHiCSharp                = 1120;
  NoteHiDFlat                 = 1120;
  NoteHiD                     = 1180;
  NoteHiDSharp                = 1250;
  NoteHiEFlat                 = 1250;
  NoteHiE                     = 1320;
  NoteHiESharp                = 1400;
  NoteHiFFlat                 = 1320;
  NoteHiF                     = 1400;
  NoteHiFSharp                = 1490;
  NoteHiGFlat                 = 1490;
  NoteHiG                     = 1580;
  NoteHiGSharp                = 1670;
  NoteHiAFlat                 = 1670;
  NoteHiA                     = 1760;
  NoteHiASharp                = 1880;
  NoteHiBFlat                 = 1880;
  NoteHiB                     = 2000;
  NoteVeryHiE                 = 2640;
  NoNote                      = 0;

 //{WLI}FUNCTION  BYTADDR  (Call: Pointer; NumberCalls: INTEGER; A: Pointer): INTEGER; EXTERNAL;
 //{WLI}FUNCTION  BYTDUPE  (Call: Pointer; NumberCalls: INTEGER; A: Pointer): BOOLEAN; EXTERNAL;
 //{WLI}FUNCTION  NUMBYTES (Call1: Pointer; Call2: Pointer): INTEGER; EXTERNAL;
 //{WLI}FUNCTION  BYTSTOCR (List: Pointer; Start: INTEGER): INTEGER; EXTERNAL;

type
  FileControlBlockType = record
    DriveIdentification: BYTE;
    Name: array[1..8] of Char;
    Extension: array[1..3] of Char;
    CurrentBlockNumber: integer;
    RecordSize: integer;
    FileSize: LONGINT;
    Date: integer;
    Time: integer;
    Reserved: array[1..8] of Char;
    CurrentRecord: BYTE;
    RelativeRecord: LONGINT;
  end;

  BufferType = array[0..$FF] of Char;
  BufferTypePtr = ^BufferType;

var
  ActivityCounter             : integer;
  Beat                        : integer;
  CBuffer                     : BufferTypePtr;
  CharacterSpace              : integer;
  CWPitch                     : integer;
  DahLength                   : integer;
  DitLength                   : integer;
  ExtendedKey                 : BYTE;
  MouseType                   : MouseTypeType;

  WordSpace                   : integer;



//  CodeSpeed                   : BYTE;
//  FMMode                      : boolean;
//  HourOffset                  : integer;
//  QuestionMarkChar            : Char;
//  SlashMarkChar               : Char;


//  Com1PortBaseAddress         : Word;
//  Com2PortBaseAddress         : Word;
//  Com3PortBaseAddress         : Word;
//  Com4PortBaseAddress         : Word;
//  Com5PortBaseAddress         : Word;
//  Com6PortBaseAddress         : Word;





 {WLI}
 //{$L dupe}

 { The first set of routines are local to TREE }

function CharacterFromIntegerValue(IntegerValue: integer): Char;

{ This table is used for compressing data. }

begin
  case IntegerValue of
    0: CharacterFromIntegerValue := ' ';
    1: CharacterFromIntegerValue := '0';
    2: CharacterFromIntegerValue := '1';
    3: CharacterFromIntegerValue := '2';
    4: CharacterFromIntegerValue := '3';
    5: CharacterFromIntegerValue := '4';
    6: CharacterFromIntegerValue := '5';
    7: CharacterFromIntegerValue := '6';
    8: CharacterFromIntegerValue := '7';
    9: CharacterFromIntegerValue := '8';

    10: CharacterFromIntegerValue := '9';
    11: CharacterFromIntegerValue := 'A';
    12: CharacterFromIntegerValue := 'B';
    13: CharacterFromIntegerValue := 'C';
    14: CharacterFromIntegerValue := 'D';
    15: CharacterFromIntegerValue := 'E';
    16: CharacterFromIntegerValue := 'F';
    17: CharacterFromIntegerValue := 'G';
    18: CharacterFromIntegerValue := 'H';
    19: CharacterFromIntegerValue := 'I';
    20: CharacterFromIntegerValue := 'J';
    21: CharacterFromIntegerValue := 'K';
    22: CharacterFromIntegerValue := 'L';
    23: CharacterFromIntegerValue := 'M';
    24: CharacterFromIntegerValue := 'N';
    25: CharacterFromIntegerValue := 'O';
    26: CharacterFromIntegerValue := 'P';
    27: CharacterFromIntegerValue := 'Q';
    28: CharacterFromIntegerValue := 'R';
    29: CharacterFromIntegerValue := 'S';
    30: CharacterFromIntegerValue := 'T';
    31: CharacterFromIntegerValue := 'U';
    32: CharacterFromIntegerValue := 'V';
    33: CharacterFromIntegerValue := 'W';
    34: CharacterFromIntegerValue := 'X';
    35: CharacterFromIntegerValue := 'Y';
    36: CharacterFromIntegerValue := 'Z';
  else CharacterFromIntegerValue := '?';
  end;
end;

function WordValueFromCharacter(Character: Char): Word;

var
  TempInteger                 : Word;

 { This table is used for compressing data. }

begin
  if (Character = CHR(0)) or (Character = ' ') or
    (Character = '/') or (Character = '?') then
  begin
    WordValueFromCharacter := 0;
    exit;
  end;

  if (Character >= 'A') and (Character <= 'Z') then
  begin
    WordValueFromCharacter := Ord(Character) - Ord('A') + 11;
    exit;
  end;

  if (Character >= 'a') and (Character <= 'z') then
  begin
    WordValueFromCharacter := Ord(Character) - Ord('a') + 11;
    exit;
  end;

  if (Character >= '0') and (Character <= '9') then
  begin
    WordValueFromCharacter := Ord(Character) - Ord('0') + 1;
    exit;
  end;

  if Character = 'н' then
  begin
    WordValueFromCharacter := 1;
    exit;
  end;

  WordValueFromCharacter := 0;
end;

procedure CompressThreeCharacters(Input: Str80; var Output: TwoBytes);

{ This procedure will compress a string of up to 3 characters to 2 bytes. }

var
  Multiplier, Value, Sum      : Word;
  LoopCount, CharPosition     : integer;

begin
  if Input = '' then
  begin
    Output[1] := 0;
    Output[2] := 0;
    exit;
  end;

  Multiplier := 1;
  Sum := 0;
  LoopCount := 0;

  if length(Input) > 3 then
  begin
    Output[1] := 0;
    Output[2] := 0;
    exit;
  end;

  for CharPosition := length(Input) downto 1 do
  begin
    Value := WordValueFromCharacter(Input[CharPosition]);
    Sum := Sum + Value * Multiplier;
    inc(LoopCount);
    if LoopCount >= 3 then Break;
    Multiplier := Multiplier * 37;
  end;

  Output[2] := Lo(Sum);
  Output[1] := Hi(Sum);
end;

function ExpandTwoBytes(Input: TwoBytes): Str80;

var
  Sum                         : LONGINT;
  TempString                  : Str80;
  TempInt1, TempInt2          : LONGINT;

begin
  TempInt1 := Input[1];
  if TempInt1 < 0 then TempInt1 := TempInt1 + 256;
  TempInt2 := Input[2];
  if TempInt2 < 0 then TempInt2 := TempInt2 + 256;
  Sum := TempInt1 * 256 + TempInt2;

  if Sum = 0 then
  begin
    ExpandTwoBytes := '';
    exit;
  end;

  TempString := CharacterFromIntegerValue(Sum div 1369);
  if TempString[1] = CHR(0) then TempString := '';
  Sum := Sum mod 1369;
  TempString := TempString + CharacterFromIntegerValue(Sum div 37);
  if TempString[1] = CHR(0) then TempString := '';
  Sum := Sum mod 37;
  TempString := TempString + CharacterFromIntegerValue(Sum);
  if TempString[1] = CHR(0) then TempString := '';
  ExpandTwoBytes := TempString;
end;

procedure SixteenthNote(Pitch: integer);

begin
  if Pitch > 0 then
  begin
    Sound(Pitch);
  end;
  Delay(Beat div 4);
  NoSound;
end;

procedure EigthNote(Pitch: integer);

begin
  if Pitch > 0 then
  begin
    Sound(Pitch);
  end;
  Delay(Beat div 2);
  NoSound;
end;

procedure QuarterNote(Pitch: integer);

begin
  if Pitch > 0 then
  begin
    Sound(Pitch);
  end;
  Delay(Beat);
  NoSound;
end;

procedure Dit;

begin
  Sound(CWPitch);
  Delay(DitLength);
  NoSound;
  Delay(DitLength);
end;

procedure Dah;

begin
  Sound(CWPitch);
  Delay(DahLength);
  NoSound;
  Delay(DitLength);
end;

{ Now for the external routines in alphabetical order. }

function AddBand(Band: BandType): Char;

var
  TempChar                    : Char;

begin
  Move(Band, TempChar, 1);
  AddBand := TempChar;
end;

function AddMode(Mode: ModeType): Char;

var
  TempChar                    : Char;

begin
  Move(Mode, TempChar, 1);
  AddMode := TempChar;
end;

function AlphaPartOfString(InputString: Str160): Str80;

var
  TempString                  : Str80;
  CharPointer                 : integer;

begin
  if InputString = '' then
  begin
    AlphaPartOfString := '';
    exit;
  end;

  TempString := '';

  for CharPointer := 1 to length(InputString) do
    if (InputString[CharPointer] >= 'A') and (InputString[CharPointer] <= 'Z') then
      TempString := TempString + InputString[CharPointer];

  AlphaPartOfString := TempString;
end;

function BigCompressedCallsAreEqual(Call1, Call2: EightBytes): boolean;

begin
  BigCompressedCallsAreEqual := (Call1[1] = Call2[1]) and
    (Call1[2] = Call2[2]) and (Call1[3] = Call2[3]) and
    (Call1[4] = Call2[4]) and (Call1[5] = Call2[5]) and
    (Call1[6] = Call2[6]) and (Call1[7] = Call2[7]) and
    (Call1[8] = Call2[8]);
end;

procedure BigCompressFormat(Call: CallString; var CompressedBigCall: EightBytes);

var
  CompressedCall              : fourBYTEs;
  BYTE                        : integer;
  ShortCall                   : Str20;

begin
  while length(Call) < 12 do
    Call := ' ' + Call;
  ShortCall := Copy(Call, 1, 6);
  CompressFormat(ShortCall, CompressedCall);
  for BYTE := 1 to 4 do
    CompressedBigCall[BYTE] := CompressedCall[BYTE];
  Delete(Call, 1, 6);
  CompressFormat(Call, CompressedCall);
  for BYTE := 1 to 4 do
    CompressedBigCall[BYTE + 4] := CompressedCall[BYTE];
end;

function BigExpandedString(Input: EightBytes): Str80;

var
  TempBytes                   : TwoBytes;
  TempString                  : Str80;

begin
  TempBytes[1] := Input[1];
  TempBytes[2] := Input[2];
  TempString := ExpandTwoBytes(TempBytes);
  TempBytes[1] := Input[3];
  TempBytes[2] := Input[4];
  TempString := TempString + ExpandTwoBytes(TempBytes);
  TempBytes[1] := Input[5];
  TempBytes[2] := Input[6];
  TempString := TempString + ExpandTwoBytes(TempBytes);
  TempBytes[1] := Input[7];
  TempBytes[2] := Input[8];
  TempString := TempString + ExpandTwoBytes(TempBytes);
  while (TempString[1] = ' ') and (length(TempString) > 1) do
    Delete(TempString, 1, 1);
  BigExpandedString := TempString;
end;

function BracketedString(LongString: Str160; StartString: Str80; StopString: Str80): Str80;

{ This function will return any string sits between the StartString and the
  StopString.  The shortest possible string to meet this criteria is
  returned.  If the start string is null, then the returned string will
  be the preceding string to the StopString.  If the StopString is null, the
  returned string will be the postceding string to the StartString.         }

var
  StartLocation, StopLocation : integer;

begin
  BracketedString := '';

  if StartString <> '' then
  begin
    StartLocation := pos(StartString, LongString);
    if StartLocation = 0 then exit;
  end
  else
    StartLocation := 0;

  if StartLocation > 0 then
    Delete(LongString, 1, StartLocation + length(StartString) - 1);

  if StopString = '' then
  begin
    BracketedString := LongString;
    exit;
  end
  else
  begin
    StopLocation := pos(StopString, LongString);
    if StopLocation = 0 then exit;
  end;

  BracketedString := Copy(LongString, 1, StopLocation - 1);
end;

function HexString(HexByte: BYTE): Str20;

begin
  HexString := HexChars[HexByte shr 4] + HexChars[HexByte and $F];
end;

procedure CalculateBandMode(Freq: LONGINT; var Band: BandType; var Mode: ModeType);

begin
  if (Freq >= 1790000) and (Freq < 2000000) then
  begin
    Band := Band160; { Leave mode alone }
    exit;
  end;

  if (Freq >= 3490000) and (Freq < 3530000) then
  begin
    Band := Band80;
    Mode := cw;
    exit;
  end;

  if (Freq >= 3530000) and (Freq < 3600000) then
  begin
    Band := Band80; { Leave mode alone }
    exit;
  end;

  if (Freq >= 3600000) and (Freq < 4000000) then
  begin
    Band := Band80;
    Mode := Phone;
    exit;
  end;

  if (Freq >= 6990000) and (Freq < 7030000) then
  begin
    Band := Band40;
    Mode := cw;
    exit;
  end;

  if (Freq >= 7030000) and (Freq < 7100000) then
  begin
    Band := Band40; { Leave the mode alone }
    exit;
  end;

  if (Freq >= 7100000) and (Freq < 7300000) then
  begin
    Band := Band40;
    Mode := Phone;
    exit;
  end;

  if (Freq >= 10099000) and (Freq < 10150000) then
  begin
    Band := Band30;
    Mode := cw;
    exit;
  end;

  if (Freq >= 13990000) and (Freq < 14100000) then
  begin
    Band := Band20;
    Mode := cw;
    exit;
  end;

  if (Freq >= 14100000) and (Freq < 14350000) then
  begin
    Band := Band20;
    Mode := Phone;
    exit;
  end;

  if (Freq >= 18068000) and (Freq < 18110000) then
  begin
    Band := Band17;
    Mode := cw;
    exit;
  end;

  if (Freq >= 18110000) and (Freq < 18168000) then
  begin
    Band := Band17;
    Mode := Phone;
    exit;
  end;

  if (Freq >= 20990000) and (Freq < 21000000) then
  begin
    Band := Band15;
    Mode := cw;
    exit;
  end;

  if (Freq >= 21000000) and (Freq < 21200000) then
  begin
    Band := Band15; { Leave mode alone }
    if Mode <> Digital then Mode := cw; {KK1L: 6.70 band map gets hosed not setting mode}
    exit;
  end;

  if (Freq >= 21100000) and (Freq < 21450000) then
  begin
    Band := Band15;
    Mode := Phone;
    exit;
  end;

  if (Freq >= 24890000) and (Freq < 24930000) then
  begin
    Band := Band12;
    Mode := cw;
    exit;
  end;

  if (Freq >= 24930000) and (Freq < 24990000) then
  begin
    Band := Band12;
    Mode := Phone;
    exit;
  end;

  if (Freq >= 27990000) and (Freq < 28300000) then
  begin
    Band := Band10;
    Mode := cw;
    exit;
  end;

  if (Freq >= 28300000) and (Freq < 29700000) then
  begin
    Band := Band10;
    Mode := Phone;
    exit;
  end;

  if (Freq >= 50000000) and (Freq < 50100000) then
  begin
    Band := Band6;
    Mode := cw;
    exit;
  end;

  if (Freq >= 50100000) and (Freq < 54000000) then
  begin
    Band := Band6;
    Mode := Phone;
    exit;
  end;

  if (Freq >= 144000000) and (Freq < 144100000) then
  begin
    Band := Band2;
    Mode := cw;
    exit;
  end;

  if (Freq >= 144100000) and (Freq < 148000000) then
  begin
    Band := Band2;
    Mode := Phone;
    exit;
  end;

  if (Freq >= 218000000) and (Freq < 250000000) then
  begin
    Band := Band222;
    Mode := Phone;
    exit;
  end;

  if (Freq >= 400000000) and (Freq <= 500000000) then
  begin
    Band := Band432;
    Mode := Phone;
    exit;
  end;

  if (Freq >= 900000000) and (Freq <= 1000000000) then
  begin
    Band := Band902;
    Mode := Phone;
    exit;
  end;

  if (Freq > 1000000000) and (Freq <= 1500000000) then
  begin
    Band := Band1296;
    Mode := Phone;
    exit;
  end;

  Band := NoBand;
  Mode := NoMode;
end;

function CallFitsFormat(Format: CallString; Call: CallString): boolean;

{ Format includes ? and * characters }

var
  CallAddress, Address        : integer;
  TestString                  : Str20;
  WildCardSearch              : boolean;

begin
  if (Format = '') or (Call = '') then
  begin
    CallFitsFormat := False;
    exit;
  end;

  CallFitsFormat := true;

  TestString := '';

  for Address := 1 to length(Format) do
    if (Copy(Format, Address, 1) <> '?') and (Copy(Format, Address, 1) <> '*') then
      TestString := TestString + Copy(Format, Address, 1)
    else
    begin
      if TestString <> '' then
        if pos(TestString, Call) = 0 then { Letters not found in call }
        begin
          CallFitsFormat := False;
          exit;
        end;

      TestString := '';
    end;

 { We might a match }

  CallAddress := 0;
  WildcardSearch := False;

  for Address := 1 to length(Format) do
  begin
    if WildCardSearch then
    begin
      while CallAddress <= length(Call) do
        if Format[Address] <> Call[CallAddress] then
          inc(CallAddress)
        else
        begin
          WildCardSearch := False;
          Break;
        end;

      if WildCardSearch then
      begin
        CallFitsFormat := False;
        exit;
      end;
    end
    else
      inc(CallAddress);

    case Format[Address] of
      '?':
        begin
        end;

      '*': WildcardSearch := true;

    else
      if Format[Address] <> Call[CallAddress] then
      begin
        CallFitsFormat := False;
        exit;
      end;

    end;

    if not WildcardSearch then
      if (Address = length(Format)) or (CallAddress = length(Call)) then
        if CallAddress <> length(Call) then
        begin
          CallFitsFormat := False;
          exit;
        end;

  end;
end;

function CaliforniaCall(Call: CallString): boolean;

begin
  CaliforniaCall := False;

  if not StringHas(Call, '6') then exit;

  Call := StandardCallFormat(Call, true);

  if StringHas(Call, '/') then
    if not StringHas(Call, '6/') then exit;

  if (Call[1] <> 'A') and (Call[1] <> 'K') and
    (Call[1] <> 'N') and (Call[1] <> 'W') then exit;

  if Call[2] = 'H' then exit;
  CaliforniaCall := true;
end;

function PacketCharReady(SerialPort: PortType; var CIn: Char): boolean;

{ This funtion will see if a char is waiting in the packet port. }

var
  PortAddress                 : Word;
 //    Regs: Registers;
  Ready                       : boolean;

begin
 {    PortAddress := 0;
 
     CASE SerialPort OF
         Serial1: PortAddress := Com1PortBaseAddress;
         Serial2: PortAddress := Com2PortBaseAddress;
         Serial3: PortAddress := Com3PortBaseAddress;
         Serial4: PortAddress := Com4PortBaseAddress;
         Serial5: PortAddress := Com5PortBaseAddress;
         Serial6: PortAddress := Com6PortBaseAddress;
 
         DRSI: BEGIN
               Regs.AX := 0;
               Intr ($FF, Regs);
               CIn := Chr (Regs.AL);
               PacketCharReady := Regs.AH <> 0;
               Exit;
               END;
         END;
 
     IF PortAddress <> 0 THEN
         BEGIN
         Ready := (Port [PortAddress + 5] AND 1) = 1;
 
         IF Ready THEN Cin := Chr (Port [PortAddress]);
 
         PacketCharReady := Ready;
         END
     ELSE
         PacketCharReady := False;
 
  }
end;

function CharReady(SerialPort: PortType): boolean;

{ This funtion will see if a char is waiting in the UART }

var
  PortAddress                 : Word;

begin
 {    PortAddress := 0;
 
     CASE SerialPort OF
         Serial1: PortAddress := Com1PortBaseAddress;
         Serial2: PortAddress := Com2PortBaseAddress;
         Serial3: PortAddress := Com3PortBaseAddress;
         Serial4: PortAddress := Com4PortBaseAddress;
         Serial5: PortAddress := Com5PortBaseAddress;
         Serial6: PortAddress := Com6PortBaseAddress;
         END;
 
     IF PortAddress <> 0 THEN
         BEGIN
         PortAddress := PortAddress + 5;
         CharReady := (Port [PortAddress] AND 1) = 1;
         END
     ELSE
         CharReady := False;
 
    }
end;

function CheckSum(InputString: string): BYTE;

var
  Index, Sum                  : Word;

begin
  Sum := 0;

  if length(InputString) > 0 then
    for Index := 1 to length(InputString) do
      Sum := Sum + Ord(InputString[Index]);

  CheckSum := Lo(Sum);
end;

procedure ClearScreen;

begin
 //    ClrScr;
end;

function CompareFileTimes(FirstFileName: Str80; SecondFileName: Str80): FileComparisonType;

var
  FirstFile, SecondFile       : Text;
  FirstTime, SecondTime       : LONGINT;
 //    FirstDateTime, SecondDateTime: DateTime;

begin
 {    Assign (FirstFile, FirstFileName);
     Reset (FirstFile);
     GetFTime (FirstFile, FirstTime);
     Close (FirstFile);
 
     Assign (SecondFile, SecondFileName);
     Reset (SecondFile);
     GetFTime (SecondFile, SecondTime);
     Close (SecondFile);
 
     IF FirstTime > SecondTime THEN
         CompareFileTimes := After
     ELSE
         IF FirstTime < SecondTime THEN
             CompareFileTimes := Before
         ELSE
             CompareFileTimes := Same;
    }
end;

procedure CompressFormat(Call: CallString; var Output: fourBYTEs);

{ This function will give the compressed representation for the string
    passed to it.  The string must be no longer than 6 characters.  }

var
  TempBytes                   : TwoBytes;

begin
  if Call = '' then
  begin
    Output[1] := 0;
    Output[2] := 0;
    Output[3] := 0;
    Output[4] := 0;
    exit;
  end;

  Call := UpperCase(Call);

  while length(Call) < 6 do
    Call := ' ' + Call;

  CompressThreeCharacters(Copy(Call, 1, 3), TempBytes);
  Output[1] := TempBytes[1];
  Output[2] := TempBytes[2];
  CompressThreeCharacters(Copy(Call, 4, 3), TempBytes);
  Output[3] := TempBytes[1];
  Output[4] := TempBytes[2];
end;

function Com1PortBaseAddress: Word;

var
  Address                     : Word;

begin
 //{WLI}    Address := MemW [ $0040:0 ];

  if Address = 0 then
    Com1PortBaseAddress := $3F8
  else
    Com1PortBaseAddress := Address;
end;

function Com2PortBaseAddress: Word;

var
  Address                     : Word;

begin
 //{WLI}    Address := MemW [ $0040:2 ];

  if Address = 0 then
    Com2PortBaseAddress := $2F8
  else
    Com2PortBaseAddress := Address;
end;

function Com3PortBaseAddress: Word;

var
  Address                     : Word;

begin
 //    Address := MemW [ $0040:4 ];

  if Address <> 0 then
    Com3PortBaseAddress := Address
  else
    Com3PortBaseAddress := $3E8;
end;

function Com4PortBaseAddress: Word;

var
  Address                     : Word;

begin
 //    Address := MemW [ $0040:6 ];

  if Address <> 0 then
    Com4PortBaseAddress := Address
  else
    Com4PortBaseAddress := $2E8;
end;

procedure Congrats;

var
  OldBeat                     : integer;

begin
  OldBeat := Beat;
  Beat := 200;
  SixteenthNote(NoteC);
  SixteenthNote(NoteE);
  SixteenthNote(NoteG);
  EigthNote(NoteHiC);
  SixteenthNote(NoteG);
  EigthNote(NoteHiC);
  Beat := OldBeat;
end;

function CopyFiles(SourceDirectory: Str80;
  FileMask: Str80;
  DestDirectory: Str80): boolean;

var
  FileNames                   : FileNameRecord;
  FileNumber                  : integer;

begin
  if not (SourceDirectory[length(SourceDirectory)] = '\') then
    if SourceDirectory <> '' then
      SourceDirectory := SourceDirectory + '\';

  if not (DestDirectory[length(DestDirectory)] = '\') then
    if DestDirectory <> '' then
      DestDirectory := DestDirectory + '\';

  GetFileNames(SourceDirectory, FileMask, FileNames);

  if FileNames.NumberFiles > 0 then
    for FileNumber := 0 to FileNames.NumberFiles - 1 do
      CopyFile(SourceDirectory + FileNames.List[FileNumber],
        DestDirectory + FileNames.List[FileNumber]);

  if IORESULT = 0 then ;
end;

function CopyFile(SourceFile: Str80; DestFile: Str80): boolean;

var
  FileBuffer                  : Pointer;
  FileRead, FileWrite         : file;
  BytesRead, BytesWritten, BufferSize: Word;
  FileSize                    : LONGINT;

begin
 {    {$I-}
 {    CopyFile := False;
     IF NOT FileExists (SourceFile) THEN Exit;
 
     IF MaxAvail > 65000 THEN
         BufferSize := 65000
     ELSE
         BufferSize := MaxAvail - 4000;
 
     IF BufferSize < 1000 THEN Exit;
 
     FileSize := GetFileSize (SourceFile);
 
     IF FileSize < BufferSize THEN BufferSize := FileSize;
 
     GetMem (FileBuffer, BufferSize);
 
     Assign  (FileRead, SourceFile);
     Reset   (FileRead,        1);
 
     IF IoResult = 0 THEN
         BEGIN
         Assign  (FileWrite, DestFile);
         Rewrite (FileWrite, 1);
 
         IF IoResult = 0 THEN
             BEGIN
             REPEAT
                 BlockRead  (FileRead, FileBuffer^, BufferSize, BytesRead);
                 BlockWrite (FileWrite, FileBuffer^, BytesRead, BytesWritten);
 
                 IF BytesWritten <> BytesRead THEN  { Disk full? }
 {                    BEGIN
                     Close (FileRead);
                     Close (FileWrite);
                     FreeMem (FileBuffer, BufferSize);
                     Exit;
                     END;
 
             UNTIL Eof (FileRead);
             Close (FileRead);
             END
         ELSE
             BEGIN
             Close (FileRead);
             FreeMem (FileBuffer, BufferSize);
             Exit;
             END;
 
         Close (FileWrite);
         END
     ELSE
         BEGIN
         FreeMem (FileBuffer, BufferSize);
         Exit;
         END;
 
     FreeMem (FileBuffer, BufferSize);
     CopyFile := True;
 }
{$I+}
end;

procedure DecrementASCIIInteger(var ASCIIString: Str80);

var
  TempValue, Result           : integer;

begin
  Val(ASCIIString, TempValue, Result);
  if Result <> 0 then
  begin
    ASCIIString := '';
    exit;
  end;
  Dec(TempValue);
  Str(TempValue, ASCIIString);
end;

procedure DelayOrKeyPressed(DelayTime: integer);

begin
 {    WHILE DelayTime > 0 DO
         BEGIN
         IF KeyPressed THEN Exit;
         Delay (1);
         Dec (DelayTime);
         END;
    }
end;

procedure DeleteFile(FileName: Str80);

{ This procedure will unceramonisly delete the filename specified.  If the
    file doesn't exist, it is not deleted.           }

var
  f                           : Text;

begin
  if FileExists(FileName) then
  begin
    Assign(f, FileName);
    Erase(f);
  end;
end;

function DeleteMult(var LogString: Str80; MultString: Str20): boolean;

var
  CharPointer, Position       : integer;
  TempString                  : Str20;

begin
  DeleteMult := False;
  TempString := Copy(LogString, LogEntryMultAddress, LogEntryMultWidth);

  Position := pos(MultString, TempString);

  if (Position >= 1) and
    (Position < LogEntryMultWidth) then
  begin
    Position := Position + LogEntryMultAddress - 1;

    for CharPointer := Position to Position + length(MultString) - 1 do
      LogString[CharPointer] := ' ';

    DeleteMult := true;
    exit;
  end;
end;

function DupeTest(Call: Str80): boolean;

{ This function will check the string passed to it and return TRUE if
    the call starts with the letters DUPE.                                 }

begin
  Call := Copy(Call, 1, 4);
  DupeTest := Call = 'DUPE';
end;

function DupingFileExists(Name: Str80): boolean;

var
  FileThere                   : boolean;
  TempString                  : Str80;
  FileTest                    : Text;

begin
  DupingFileExists := False;
  if not OpenFileForRead(FileTest, Name) then exit;
  ReadLn(FileTest, TempString);
  DupingFileExists := TempString = 'DUPE';
  Close(FileTest);
end;

procedure MarkTime(var StartTime: TimeRecord);

begin
 //    WITH StartTime DO
 //        GetTime (Hour, Minute, Second, Sec100);
end;

function ElaspedTimeString(StartTime: TimeRecord): Str20;

{ Returns a string in the format HH:MM:SS with how long it has been }

var
  Hours, Mins, Secs, TotalSeconds: LONGINT;
  HourString, MinsString, SecsString: Str20;

begin
  TotalSeconds := ElaspedSec100(StartTime) div 100;

  Hours := TotalSeconds div 3600;

  TotalSeconds := TotalSeconds - (Hours * 60);

  Mins := TotalSeconds div 60;

  TotalSeconds := TotalSeconds - (Mins * 60);

  Str(Hours, HourString);
  Str(Mins, MinsString);
  Str(TotalSeconds, SecsString);

  if length(SecsString) < 2 then SecsString := '0' + SecsString;
  if length(MinsString) < 2 then MinsString := '0' + MinsString;

  ElaspedTimeString := HourString + ':' + MinsString + ':' + SecsString;
end;

function ElaspedSec100(StartTime: TimeRecord): LONGINT;

var
  Hour, Minute, Second, Sec100: Word;
  TempMinute, TempSecond, TempSec100: LONGINT;

begin
 //{WLI}    GetTime (Hour, Minute, Second, Sec100);

  if StartTime.Hour > Hour then Hour := Hour + 24;

  if StartTime.Hour > Hour then
  begin
    ElaspedSec100 := 0;
    exit;
  end;

  if StartTime.Minute > Minute then
  begin
    Minute := Minute + 60;
    Dec(Hour);

    if StartTime.Hour > Hour then
      Hour := Hour + 24;
  end;

  if StartTime.Second > Second then
  begin
    Second := Second + 60;
    Dec(Minute);
    if Minute < 0 then
    begin
      Minute := Minute + 60;
      Dec(Hour);
      if StartTime.Hour > Hour then
        Hour := Hour + 24;
    end;
  end;

  if StartTime.Sec100 > Sec100 then
  begin
    Sec100 := Sec100 + 100;
    Dec(Second);
    if Second < 0 then
    begin
      Second := Second + 60;
      Dec(Minute);
      if Minute < 0 then
      begin
        Minute := Minute + 60;
        Dec(Hour);
        if Hour < 0 then
          Hour := Hour + 24;
      end;
    end;
  end;

  if Sec100 > StartTime.Sec100 then
    TempSec100 := Sec100 - StartTime.Sec100
  else
    TempSec100 := 0;

  if Minute > StartTime.Minute then
    TempMinute := Minute - StartTime.Minute
  else
    TempMinute := 0;

  TempMinute := TempMinute * 6000;

  if Second > StartTime.Second then
    TempSecond := Second - StartTime.Second
  else
    TempSecond := 0;

  TempSecond := TempSecond * 100;

  ElaspedSec100 := TempMinute + TempSecond + TempSec100;
end;

function ElaspedMinutes(StartTime: TimeRecord): integer;

var
  Hour, Minute, Second, Sec100: Word;
  TempHour, TempMinute, TempSecond, TempSec100: LONGINT;

begin
 //{WLI}    GetTime (Hour, Minute, Second, Sec100);

  if StartTime.Hour > Hour then Hour := Hour + 24;

  if StartTime.Minute > Minute then
  begin
    Minute := Minute + 60;
    Dec(Hour);

    if StartTime.Hour > Hour then
      Hour := Hour + 24;
  end;

  if StartTime.Second > Second then
  begin
    Second := Second + 60;
    Dec(Minute);
    if Minute < 0 then
    begin
      Minute := Minute + 60;
      Dec(Hour);
      if StartTime.Hour > Hour then
        Hour := Hour + 24;
    end;
  end;

  if StartTime.Sec100 > Sec100 then
  begin
    Sec100 := Sec100 + 100;
    Dec(Second);
    if Second < 0 then
    begin
      Second := Second + 60;
      Dec(Minute);
      if Minute < 0 then
      begin
        Minute := Minute + 60;
        Dec(Hour);
        if Hour < 0 then
          Hour := Hour + 24;
      end;
    end;
  end;

 { Runtime 215 error on the next line - 273b:1e93 }

  TempHour := Hour - StartTime.Hour;

  TempMinute := Minute - StartTime.Minute;

  ElaspedMinutes := (TempHour * 60) + TempMinute;
end;

function ExpandedString(Input: fourBYTEs): Str80;

{ Returns the expanded string for the compressed integer passed to it. }

var
  TempBytes                   : TwoBytes;
  TempString                  : Str80;

begin
  TempBytes[1] := Input[1];
  TempBytes[2] := Input[2];
  TempString := ExpandTwoBytes(TempBytes);
  TempBytes[1] := Input[3];
  TempBytes[2] := Input[4];
  TempString := TempString + ExpandTwoBytes(TempBytes);
  while (TempString[1] = ' ') and (length(TempString) > 1) do
    Delete(TempString, 1, 1);
  ExpandedString := TempString;
end;

procedure ExpandTabs(var InputString: string);

var
  TabPos                      : integer;

begin
  TabPos := pos(TabKey, InputString);

  while TabPos > 0 do
  begin
    Delete(InputString, TabPos, 1);
    Insert(' ', InputString, TabPos);
    inc(TabPos);

    while TabPos mod 8 <> 0 do
    begin
      Insert(' ', InputString, TabPos);
      inc(TabPos);
    end;

    TabPos := pos(TabKey, InputString);
  end;
end;

function FileExists(FileName: Str80): boolean;

{ This function will return TRUE if the filename specified exists. }

//var  DirInfo: TSearchRec;

begin
//  FindFirst(FileName, faArchive, DirInfo);
//  FileExists := IORESULT = 0;
end;

//procedure BigCursor;

//{WLI}VAR Regs: REGISTERS;

//begin
 {    Regs.AH := $1;
     Regs.CH := $0;
     Regs.CL := $D;
     Intr ($10, Regs);
    }
//end;

procedure SmallCursor;

//{WLI}VAR Regs: REGISTERS;

begin
 {    Regs.AH := $1;
     Regs.CH := $B;
     Regs.CL := $D;
     Intr ($10, Regs);
    }
end;

function SlipMessage(Message: string): string;

var
  CharPointer                 : integer;
  TempString                  : string;

begin
  TempString := '';

  if Message = '' then
  begin
    SlipMessage := '';
    exit;
  end;

  for CharPointer := 1 to length(Message) do
  begin
    if Message[CharPointer] = CHR(FrameEnd) then
      TempString := Concat(TempString, CHR(FrameEscape), CHR(TransposedFrameEnd))
    else
      if Message[CharPointer] = CHR(FrameEscape) then
        TempString := Concat(TempString, CHR(FrameEscape), CHR(TransposedFrameEscape))
      else
        TempString := TempString + Message[CharPointer];
  end;

  SlipMessage := CHR(FrameEnd) + TempString + CHR(FrameEnd);
end;

function FoundDirectory(FileName: Str80; Path: Str80; var Directory: Str80): boolean;

var
  TempString                  : Str80;
 //{WLI}    S: PathStr;
  CharPos                     : integer;

begin
 {    FoundDirectory := False;
 
     S := FSearch (FileName, Path);
 
     IF S = '' THEN
         Exit
     ELSE
         BEGIN
         TempString := FExpand (S);
 
         WHILE TempString [Length (TempString)] <> '\' DO
             Delete (TempString, Length (TempString), 1);
 
         Delete (TempString, Length (TempString), 1);
 
         Directory := TempString;
         FoundDirectory := True;
         END;
  }
end;

function FindDirectory(FileName: Str80): Str80;

{ This procedure will attempt to find the directory for the filename
  passed to it.  It will first check the current working directory, the
  directory above the working one, then check the environment variable
  TRLOG.

  If still no luck, it will check to see it can be found in the command
  string used to execute the program that is running.

  Then it will check the PATH environment string directories.

  Finally, it will check the old \log\name directory.  If it isn't found,
  it will return a null string.

  If a directory was found, it will end without \. }

var
  TempString, Directory       : Str80;

begin
 {    FindDirectory := '';
 
     IF FoundDirectory (FileName, '.', Directory) THEN
         BEGIN
         FindDirectory := Directory;
         Exit;
         END;
 
     IF FoundDirectory (FileName, '..', Directory) THEN
         BEGIN
         FindDirectory := Directory;
         Exit;
         END;
 
     IF FoundDirectory (FileName, GetEnv ('TRLOG'), Directory) THEN
         BEGIN
         FindDirectory := Directory;
         Exit;
         END;
 
     { All this will check to see what command was typed in to run the
       active program and see if a path was specified. }

 {    TempString := ParamStr (0);
 
     IF StringHas (TempString, '\') THEN
         BEGIN
         WHILE TempString [Length (TempString)] <> '\' DO
             Delete (TempString, Length (TempString), 1);
 
         Delete (TempString, Length (TempString), 1);
 
         IF FoundDirectory (FileName, TempString, Directory) THEN
             BEGIN
             FindDirectory := Directory;
             Exit;
             END;
         END;
 
     IF FoundDirectory (FileName, GetEnv ('PATH'), Directory) THEN
         BEGIN
         FindDirectory := Directory;
         Exit;
         END;
 
     IF FoundDirectory (FileName, '\log\name', Directory) THEN
         BEGIN
         FindDirectory := Directory;
         Exit;
         END;
  }
end;

function FirstLetter(InputString: Str80): Char;

var
  TempString                  : Str20;

begin
  TempString := Copy(InputString, 1, 1);
  if length(TempString) > 0 then
    FirstLetter := TempString[1]
  else
    FirstLetter := CHR(0);
end;

function LastLetter(InputString: Str160): Char;

var
  TempString                  : Str20;

begin
  TempString := Copy(InputString, length(InputString), 1);
  if length(TempString) > 0 then
    LastLetter := TempString[1]
  else
    LastLetter := CHR(0);
end;

procedure FormFeed;

begin
 //{WLI}    Write (Lst, Chr (12));
end;

function GetChecksum8(Call: fourBYTEs): integer;

var
  Sum                         : integer;

begin
  Sum := Call[1] + Call[2] + Call[3] + Call[4];
  Sum := Sum and 7;
end;

function GetColorInteger(ColorString: Str80): integer;

begin
  ColorString := UpperCase(ColorString);
  if ColorString = 'BLACK' then GetColorInteger := 0;
  if ColorString = 'BLUE' then GetColorInteger := 1;
  if ColorString = 'GREEN' then GetColorInteger := 2;
  if ColorString = 'CYAN' then GetColorInteger := 3;
  if ColorString = 'RED' then GetColorInteger := 4;
  if ColorString = 'MAGENTA' then GetColorInteger := 5;
  if ColorString = 'BROWN' then GetColorInteger := 6;
  if ColorString = 'LIGHT GRAY' then GetColorInteger := 7;
  if ColorString = 'DARK GRAY' then GetColorInteger := 8;
  if ColorString = 'LIGHT BLUE' then GetColorInteger := 9;
  if ColorString = 'LIGHT GREEN' then GetColorInteger := 10;
  if ColorString = 'LIGHT CYAN' then GetColorInteger := 11;
  if ColorString = 'LIGHT RED' then GetColorInteger := 12;
  if ColorString = 'LIGHT MAGENTA' then GetColorInteger := 13;
  if ColorString = 'YELLOW' then GetColorInteger := 14;
  if ColorString = 'WHITE' then GetColorInteger := 15;
end;

function GetDateString: Str80;

{ This function goes off and reads the DOS clock and generates a nice
  looking ASCII string using the format 25-DEC-90.  It takes the Time
  Offset variable into account.

  If the HOUR OFFSET variable is non zero, the hours will get 24 added
  to it and then the HOUR OFFSET added.  This is done to keep the
  HOURS word variable from wrapping around to 65536 since there are no
  negative numbers for a WORD variable.  Thus a value greater than 47
  after adding the HOUR OFFSET indicates that a day must be added.  If
  the value is less than 24, then a day must be subtracted.
   }

var
  TempString, DString         : Str80;

const
  DayTags                     : array[0..6] of string[9] = ('Sunday', 'Monday', 'Tuesday',
    'Wednesday', 'Thursday', 'Friday', 'Saturday');

var
  Year, Month, Day, DayOfWeek : Word;
  Hours, Minutes, Seconds, Hundredths: Word;
  I                           : integer;

begin
 {    GetDate (Year, Month, Day, DayOfWeek);
 
     IF HourOffset <> 0 THEN
         BEGIN
         GetTime (Hours, Minutes, Seconds, Hundredths);
         I := Hours;
         I := I + HourOffset;
 
         IF I > 23 THEN                     { Add a day }
 {            BEGIN
             Inc (Day);
             Inc (DayOfWeek);
             IF DayOfWeek = 8 THEN DayOfWeek := 1;
 
             CASE Month OF
                 4, 6, 9, 11:                   { 30 day month }
 {                    IF Day > 30 THEN
                         BEGIN
                         Day := 1;
                         Inc (Month);
                         END;
 
                 2: IF ((Year MOD 4) = 0) AND (Year <> 2000) THEN  { tricky }
 {                       BEGIN
                        IF Day > 29 THEN
                            BEGIN
                            Day := 1;
                            Inc (Month);
                            END;
                        END
                    ELSE
                        BEGIN
                        IF Day > 28 THEN
                            BEGIN
                            Day := 1;
                            Inc (Month);
                            END;
                        END;
 
                 ELSE                           { 31 day month }
 {                    IF Day > 31 THEN
                         BEGIN
                         Day := 1;
                         Inc (Month);
                         IF Month = 13 THEN
                             BEGIN
                             Month := 1;
                             Inc (Year);
                             END;
                         END;
                 END;
 
             END;
 
         IF I < 0 THEN                      { Subtract a day }
 {            BEGIN
             Dec (Day);
             Dec (DayOfWeek);
             IF DayOfWeek = 0 THEN DayOfWeek := 7;
 
             IF Day = 0 THEN
                 BEGIN
                 Dec (Month);
 
                 CASE Month OF
                     4, 6, 9, 11: Day := 30;
                     2: IF ((Year MOD 4) = 0) AND (Year <> 2000) THEN  { tricky }
 {                           Day := 29
                        ELSE
                            Day := 28;
                     ELSE
                         BEGIN
                         IF Month = 12 THEN Dec (Year);
                         Day := 31;
                         END;
                     END;
                 END;
 
             END;
         END;
 
     Str (Day, TempString);
     IF Day < 10 THEN TempString := '0' + TempString;
     DString := TempString + '-' + MonthTags [Month] + '-';
     Year := Year MOD 100;
     STR (Year, TempString);
     IF Year < 10 THEN TempString := '0' + TempString;
     GetDateString := DString + TempString;
  }
end;

function GetDayString: Str80;

{ This function will look at the DOS clock and generate a nice looking
    ASCII string showing the name of the day of the week (ie: Monday).  }

const
  DayTags                     : array[0..6] of string[9] = ('Sunday', 'Monday', 'Tuesday',
    'Wednesday', 'Thursday', 'Friday', 'Saturday');

var
  TempString                  : Str80;
  Year, Month, Day, DayOfWeek : Word;
  Hours, Minutes, Seconds, Hundredths: Word;
  I                           : integer;

begin
 //{WLI}    GetDate (Year, Month, Day, DayOfWeek);

  if HourOffset <> 0 then
  begin
   //{WLI}        GetTime (Hours, Minutes, Seconds, Hundredths);

    I := Hours;
    I := I + HourOffset;

    if I > 23 then { Add a day }
    begin
      inc(DayOfWeek);
      if DayOfWeek = 8 then DayOfWeek := 1;
    end
    else
      if I < 0 then
      begin
        Dec(DayOfWeek);
        if DayOfWeek = 0 then DayOfWeek := 7;
      end;

  end;

  GetDayString := DayTags[DayOfWeek];
end;

procedure GetFileNames(Path: Str80;
  Mask: Str80;
  var FileNames: FileNameRecord);

{ This function will get files names for you until all of them have been
  returned.  When this happens, you will get a null string as a result. }

//var  DirInfo: TSearchRec;

begin
 {    FileNames.NumberFiles := 0;
 
     IF (Path <> '') AND (Path [Length (Path)] <> '\') THEN
         Path := Path + '\';
 
     FindFirst (Path + Mask, Archive, DirInfo);
 
     WHILE (DosError = 0) AND (FileNames.NumberFiles < MaximumFileNames) DO
         BEGIN
         FileNames.List [FileNames.NumberFiles] := DirInfo.Name;
         Inc (FileNames.NumberFiles);
         FindNext (DirInfo);
         END;
  }
end;

function GetFileSize(FileName: Str80): LONGINT;

var
  FileRead                    : file of BYTE;

begin
  Assign(FileRead, FileName);
  Reset(FileRead);
  GetFileSize := FileSize(FileRead);
  Close(FileRead);
end;

function GetIntegerTime: integer;

{ This function will return the present time in N6TR integer format. }

var
  Hours, Minutes, Seconds, Hundredths: Word;
  I                           : integer;

begin
 //{WLI}    GetTime (Hours, Minutes, Seconds, Hundredths);
  I := Hours;

  if HourOffset <> 0 then
  begin
    I := I + HourOffset;
    if I > 23 then I := I - 24;
    if I < 0 then I := I + 24;
  end;

  GetIntegerTime := I * 100 + Minutes;
end;

function GetLogEntryBand(LogEntry: Str160): BandType;

var
  TempString                  : Str80;

begin
  if length(LogEntry) < 4 then
  begin
    GetLogEntryBand := NoBand;
    exit;
  end;

  TempString := Copy(LogEntry, 1, 3);

  if TempString = 'LGT' then
  begin
    GetLogEntryBand := BandLight;
    exit;
  end;

  if TempString = '24G' then
  begin
    GetLogEntryBand := Band24G;
    exit;
  end;
  if TempString = '10G' then
  begin
    GetLogEntryBand := Band10G;
    exit;
  end;
  if TempString = '5GH' then
  begin
    GetLogEntryBand := Band5760;
    exit;
  end;
  if TempString = '3GH' then
  begin
    GetLogEntryBand := Band3456;
    exit;
  end;
  if TempString = '2GH' then
  begin
    GetLogEntryBand := Band2304;
    exit;
  end;
  if TempString = '1GH' then
  begin
    GetLogEntryBand := Band1296;
    exit;
  end;
  if TempString = '902' then
  begin
    GetLogEntryBand := Band902;
    exit;
  end;
  if TempString = '432' then
  begin
    GetLogEntryBand := Band432;
    exit;
  end;
  if TempString = '222' then
  begin
    GetLogEntryBand := Band222;
    exit;
  end;

  if TempString = '  2' then
  begin
    GetLogEntryBand := Band2;
    exit;
  end;
  if TempString = '  6' then
  begin
    GetLogEntryBand := Band6;
    exit;
  end;
  if TempString = ' 10' then
  begin
    GetLogEntryBand := Band10;
    exit;
  end;
  if TempString = ' 12' then
  begin
    GetLogEntryBand := Band12;
    exit;
  end;
  if TempString = ' 15' then
  begin
    GetLogEntryBand := Band15;
    exit;
  end;
  if TempString = ' 17' then
  begin
    GetLogEntryBand := Band17;
    exit;
  end;
  if TempString = ' 20' then
  begin
    GetLogEntryBand := Band20;
    exit;
  end;
  if TempString = ' 30' then
  begin
    GetLogEntryBand := Band30;
    exit;
  end;
  if TempString = ' 40' then
  begin
    GetLogEntryBand := Band40;
    exit;
  end;
  if TempString = ' 75' then
  begin
    GetLogEntryBand := Band80;
    exit;
  end;
  if TempString = ' 80' then
  begin
    GetLogEntryBand := Band80;
    exit;
  end;
  if TempString = '160' then
  begin
    GetLogEntryBand := Band160;
    exit;
  end;
  GetLogEntryBand := NoBand;
end;

function GetLogEntryCall(LogEntry: Str160): CallString;

var
  TempString                  : string;

begin
  TempString := Copy(LogEntry, LogEntryCallAddress, LogEntryCallWidth);
  GetRidOfPostcedingSpaces(TempString);
  GetLogEntryCall := TempString;
end;

function GetLogEntryComputerID(LogEntry: Str160): Char;

var
  TempString                  : Str20;

begin
  TempString := Copy(LogEntry, LogEntryComputerIDAddress, LogEntryComputerIDWidth);

  if TempString = '' then
    GetLogEntryComputerID := CHR(0)
  else
    GetLogEntryComputerID := TempString[1];
end;

function GetLogEntryDateString(LogEntry: Str160): Str160;

begin
  GetLogEntryDateString := Copy(LogEntry, LogEntryDayAddress, 9);
end;

function GetLogEntryExchangeString(LogEntry: Str160): Str160;

var
  TempString                  : string;

begin
  TempString := Copy(LogEntry, LogEntryExchangeAddress, LogEntryExchangeWidth);
  GetRidOfPostcedingSpaces(TempString);
  GetLogEntryExchangeString := TempString;
end;

function GetLogEntryHour(LogEntry: Str160): integer;

var
  HourString                  : Str80;
  Hour, Result1               : integer;

begin
  HourString := Copy(LogEntry, LogEntryHourAddress, LogEntryHourWidth);
  Val(HourString, Hour, Result1);
  if Result1 = 0 then GetLogEntryHour := Hour else GetLogEntryHour := -1;
end;

function GetLogEntryMode(LogEntry: Str160): ModeType;

var
  TempString                  : Str80;

begin
  TempString := Copy(LogEntry, LogEntryModeAddress, LogEntryModeWidth);

  if TempString = 'CW ' then
    GetLogEntryMode := cw
  else
    if TempString = 'DIG' then
      GetLogEntryMode := Digital
    else
      if (TempString = 'SSB') or (TempString = 'FM ') then
        GetLogEntryMode := Phone
      else
        GetLogEntryMode := NoMode;
end;

function GetLogEntryMultString(LogEntry: Str160): Str160;

var
  TempString                  : string;

begin
  TempString := Copy(LogEntry, LogEntryMultAddress, LogEntryMultWidth);
  GetRidOfPostcedingSpaces(TempString);
  GetRidOfPrecedingSpaces(TempString);
  GetLogEntryMultString := TempString;
end;

function GetLogEntryQSONumber(LogEntry: Str160): integer;

var
  TempString                  : string;
  QSONumber, Result1          : integer;

begin
  TempString := Copy(LogEntry, LogEntryQSONumberAddress, LogEntryQSONumberWidth);
  GetRidOfPrecedingSpaces(TempString);
  Val(TempString, QSONumber, Result1);
  if Result1 = 0 then
    GetLogEntryQSONumber := QSONumber
  else
    GetLogEntryQSONumber := -1;
end;

function GetLogEntryQSOPoints(LogEntry: Str160): integer;

var
  TempString                  : string;
  Address, QSOPoints, Result1 : integer;

begin
  TempString := Copy(LogEntry, LogEntryPointsAddress, LogEntryPointsWidth);

  Address := LogEntryPointsAddress + LogEntryPointsWidth;

  while (Copy(LogEntry, Address, 1) >= '0') and (Copy(LogEntry, Address, 1) <= '9') do
  begin
    TempString := TempString + LogEntry[Address];
    inc(Address);
  end;

  GetRidOfPrecedingSpaces(TempString);

  if not StringIsAllNumbers(TempString) then
    GetLogEntryQSOPoints := 0
  else
  begin
    Val(TempString, QSOPoints, Result1);
    GetLogEntryQSOPoints := QSOPoints;
  end;
end;

function GetLogEntryRSTString(LogEntry: Str160): Str160;

var
  TempString                  : Str80;

begin
  TempString := Copy(LogEntry, LogEntryExchangeAddress, 4);
  GetLogEntryRSTString := NumberPartOfString(TempString);
end;

function GetLogEntryIntegerTime(LogEntry: Str160): integer;

var
  TempString                  : Str20;
  Time, Result1               : integer;

begin
  TempString := Copy(LogEntry, LogEntryHourAddress, 5);
  Delete(TempString, 3, 1);
  Val(TempString, Time, Result1);
  if Result1 = 0 then
    GetLogEntryIntegerTime := Time
  else
    GetLogEntryIntegerTime := -1;
end;

function GetLogEntryTimeString(LogEntry: Str160): Str160;

begin
  GetLogEntryTimeString := Copy(LogEntry, LogEntryHourAddress, 5);
end;

function GetKey(Prompt: Str80): Char;

var
  Key                         : Char;

begin
 {    GoToXY (1, WhereY);
     ClrEol;
     TextColor (Cyan);
     Write (Prompt);
     REPEAT UNTIL KeyPressed;
     Key := ReadKey;
     TextColor (Yellow);
     IF Key >= ' ' THEN Write (Key);
     GetKey := Key;
  }
end;

function GetPrefix(Call: CallString): PrefixString;

{ This function will return the prefix for the call passed to it. This is
    a new and improved version that will handle calls as they are usaully
    sent on the air.                                                          }

var
  CallPointer, PrefixPointer, Count: integer;
  CallHasPortableSign         : boolean;
  FirstPart, SecondPart, TempString: Str80;

begin
  for CallPointer := 1 to length(Call) do
    if Call[CallPointer] = '/' then
    begin
      FirstPart := Call;
      FirstPart[0] := CHR(CallPointer - 1);
      SecondPart := '';

      for Count := CallPointer + 1 to length(Call) do
        SecondPart := SecondPart + Call[Count];

      if length(SecondPart) = 1 then
        if (SecondPart >= '0') and (SecondPart <= '9') then
        begin
          TempString := GetPrefix(FirstPart);
          TempString[0] := CHR(length(TempString) - 1);
          GetPrefix := TempString + SecondPart;
          exit;
        end
        else
        begin
          GetPrefix := GetPrefix(FirstPart);
          exit;
        end;

    {KK1L: 6.68 Added AM check to allow /AM as aeronautical mobile rather than Spain}
      if (Copy(SecondPart, 1, 2) = 'MM') or (Copy(SecondPart, 1, 2) = 'AM') then
      begin
        GetPrefix := GetPrefix(FirstPart);
        exit;
      end;

      if length(FirstPart) > length(SecondPart) then
      begin
        GetPrefix := GetPrefix(SecondPart);
        exit;
      end;

      if length(FirstPart) <= length(SecondPart) then
      begin
        GetPrefix := GetPrefix(FirstPart);
        exit;
      end;
    end;

 { Call does not have portable sign.  Find natural prefix. }

  for CallPointer := length(Call) downto 2 do
    if Call[CallPointer] <= '9' then
    begin
      GetPrefix := Call;
      GetPrefix[0] := CHR(CallPointer);
      exit;
    end;

  if (Call[1] <= '9') and (length(Call) = 2) then
  begin
    GetPrefix := Call + '0';
    exit;
  end;

  GetPrefix := ''; { We have no idea what the prefix is }
end;

function GetResponse(Prompt: Str80): Str80;

var
  InputString                 : string;
  Key                         : Char;

begin
 {    TextColor (Cyan);
 
     Write (Prompt);
     TextColor (Yellow);
 
     InputString := '';
 
     REPEAT
         REPEAT UNTIL KeyPressed;
 
         Key := ReadKey;
 
         IF Key = CarriageReturn THEN
             BEGIN
             GetResponse := InputString;
             WriteLn;
             Exit;
             END;
 
         IF Key = BackSpace THEN
             BEGIN
             IF InputString <> '' THEN
                 BEGIN
                 GoToXY (WhereX - 1, WhereY);
                 Write (' ');
                 GoToXY (WhereX - 1, WhereY);
                 Delete (InputString, Length (InputString), 1);
                 END;
             END
         ELSE
             BEGIN
             Write (Key);
             InputString := InputString + Key;
             END;
 
     UNTIL Length (InputString) > 250;
  }
end;

procedure GetRidOfCarriageReturnLineFeeds(var s: string);

begin
  while pos(CarriageReturn, s) > 0 do
    s[pos(CarriageReturn, s)] := ' ';

  while pos(LineFeed, s) > 0 do
    Delete(s, pos(LineFeed, s), 1);
end;

procedure GetRidOfPostcedingSpaces(var s: string);

begin
  while length(s) > 0 do
    if (s[length(s)] = ' ') or (s[length(s)] = TabKey) then
      Delete(s, length(s), 1)
    else
      exit;
end;

procedure GetRidOfPrecedingSpaces(var s: string);

begin
  if s = '' then exit;
  while ((s[1] = ' ') or (s[1] = TabKey)) and (length(s) > 0) do
    Delete(s, 1, 1);
end;

function GetSuffix(Call: CallString): CallString;

var
  TempString                  : Str20;
  CharPointer                 : integer;

begin
  CharPointer := length(Call);
  TempString := '';

  while (Call[CharPointer] >= 'A') and (CharPointer > 0) do
  begin
    TempString := Call[CharPointer] + TempString;
    Dec(CharPointer);
  end;

  GetSuffix := TempString;
end;

function GetFullTimeString: Str80;

{ This function will look at the DOS clock and generate a nice looking
  ASCII string showing the time using the format 23:42:32.  It will take
  the HourOffset variable into account. }

var
  Temp1, Temp2, Temp3         : string[5];
  Hours, Minutes, Seconds, Hundredths: Word;
  I                           : integer;

begin
 {    GetTime (Hours, Minutes, Seconds, Hundredths);
     I := Hours;
 
     IF HourOffset <> 0 THEN
         BEGIN
         I := I + HourOffset;
         IF I > 23 THEN I := I - 24;
         IF I < 0  THEN I := I + 24;
         END;
 
     Str (I,       Temp1);
     Str (Minutes, Temp2);
     Str (Seconds, Temp3);
 
     IF Length (Temp1) < 2 THEN Temp1 := '0' + Temp1;
     IF Length (Temp2) < 2 THEN Temp2 := '0' + Temp2;
     IF Length (Temp3) < 2 THEN Temp3 := '0' + Temp3;
 
     GetFullTimeString := Temp1 + ':' + Temp2 + ':' + Temp3;
    }
end;

function GetTimeString: Str80;

{ This function will look at the DOS clock and generate a nice looking
  ASCII string showing the time using the format 23:42.  It will take
  the HourOffset variable into account. }

var
  Temp1, Temp2                : string[5];
  Hours, Minutes, Seconds, Hundredths: Word;
  I                           : integer;

begin
 {    GetTime (Hours, Minutes, Seconds, Hundredths);
     I := Hours;
 
     IF HourOffset <> 0 THEN
         BEGIN
         I := I + HourOffset;
         IF I > 23 THEN I := I - 24;
         IF I < 0  THEN I := I + 24;
         END;
 
     Str (I,       Temp1);
     Str (Minutes, Temp2);
 
     IF Length (Temp1) < 2 THEN Temp1 := '0' + Temp1;
     IF Length (Temp2) < 2 THEN Temp2 := '0' + Temp2;
     GetTimeString := Temp1 + ':' + Temp2;
    }
end;

function GetTomorrowString: Str80;

{ This function will look at the DOS clock and generate a nice looking
    ASCII string showing the name of tomorrow (ie: Monday).  }

const
  DayTags                     : array[0..6] of string[9] = ('Sunday', 'Monday', 'Tuesday',
    'Wednesday', 'Thursday', 'Friday', 'Saturday');

var
  TempString                  : Str80;
  Year, Month, Day, DayOfWeek : Word;
  Hours, Minutes, Seconds, Hundredths: Word;
  I                           : integer;

begin
 {    GetDate (Year, Month, Day, DayOfWeek);
 
     IF HourOffset <> 0 THEN
         BEGIN
         GetTime (Hours, Minutes, Seconds, Hundredths);
         I := Hours;
 
         I := I + HourOffset;
 
         IF Hours > 23 THEN                { Add a day }
 {            BEGIN
             Inc (DayOfWeek);
             IF DayOfWeek = 8 THEN DayOfWeek := 1;
             END
         ELSE
             IF Hours < 0 THEN             { Subtract a day }
 {                BEGIN
                 Dec (DayOfWeek);
                 IF DayOfWeek = 0 THEN DayOfWeek := 7;
                 END;
 
        END;
 
     Inc (DayOfWeek);
     IF DayOfWeek = 8 THEN DayOfWeek := 1;
 
     GetTomorrowString := DayTags [DayOfWeek];
    }
end;

function GetValue(Prompt: Str80): LONGINT;

{ This function will display the prompt passed to it and return a
  integer value input by the operator.  If the input is illegal, the
  prompt will be reprinted and a new value read.  }

var
  TempValue, Result1, Pointer : integer;
  TempString                  : Str80;

begin
  repeat

    ReadLn(TempString);
    Val(TempString, TempValue, Result1);
  until Result1 = 0;
  GetValue := TempValue;
end;

function GetReal(Prompt: Str80): REAL;

{ This function will display the prompt passed to it and return a
    integer value input by the operator.  If the input is illegal, the
    prompt will be reprinted and a new value read.                   }

var
  TempValue                   : REAL;
  Result1                     : integer;
  TempString                  : Str80;

begin
  TempString := GetResponse(Prompt);
  Val(TempString, TempValue, Result1);

  if Result1 = 0 then
    GetReal := TempValue
  else
    GetReal := 0;
end;

function GetYearString: Str20;

var
  TempString                  : Str80;
  Year, Month, Day, DayOfWeek : Word;

begin
 {    GetDate (Year, Month, Day, DayOfWeek);
     Str (Year, TempString);
     GetYearString := TempString;
  }
end;

function GoodCallSyntax(Call: CallString): boolean;

{ This function will look at the callsign passed to it and see if it
    looks like a real callsign.                                           }

var
  CharacterPointer            : integer;

begin
  Call := UpperCase(Call);
  GoodCallSyntax := False;
  if length(Call) < 3 then exit;

  for CharacterPointer := 1 to length(Call) do
    if not ValidCallCharacter(Call[CharacterPointer]) then exit;

  for CharacterPointer := 1 to length(Call) do
    if Call[CharacterPointer] = '/' then
    begin
      if CharacterPointer = 1 then exit;
      if CharacterPointer = length(Call) then exit;
      GoodCallSyntax := true;
      exit;
    end;

  if (Call[1] <= '9') and (Call[2] <= '9') then exit;

  if length(Call) = 3 then
  begin
    if ((Call[2] < '0') or (Call[2] > '9')) and
      ((Call[3] < '0') or (Call[3] > '9')) then
      exit;
  end
  else
    if ((Call[2] < '0') or (Call[2] > '9')) and
      ((Call[3] < '0') or (Call[3] > '9')) and
      ((Call[4] < '0') or (Call[4] > '9')) then
      exit;

  GoodCallSyntax := true;
end;

procedure HexToInteger(InputString: Str80; var OutputInteger: integer; var Result: integer);

var
  Multiplier                  : integer;

begin
  Result := 1;
  Multiplier := 1;
  OutputInteger := 0;
  if InputString = '' then exit;

  Result := 0;

  while length(InputString) > 0 do
  begin
    case UpCase(InputString[length(InputString)]) of
      '0': OutputInteger := OutputInteger + Multiplier * 0;
      '1': OutputInteger := OutputInteger + Multiplier * 1;
      '2': OutputInteger := OutputInteger + Multiplier * 2;
      '3': OutputInteger := OutputInteger + Multiplier * 3;
      '4': OutputInteger := OutputInteger + Multiplier * 4;
      '5': OutputInteger := OutputInteger + Multiplier * 5;
      '6': OutputInteger := OutputInteger + Multiplier * 6;
      '7': OutputInteger := OutputInteger + Multiplier * 7;
      '8': OutputInteger := OutputInteger + Multiplier * 8;
      '9': OutputInteger := OutputInteger + Multiplier * 9;
      'A': OutputInteger := OutputInteger + Multiplier * 10;
      'B': OutputInteger := OutputInteger + Multiplier * 11;
      'C': OutputInteger := OutputInteger + Multiplier * 12;
      'D': OutputInteger := OutputInteger + Multiplier * 13;
      'E': OutputInteger := OutputInteger + Multiplier * 14;
      'F': OutputInteger := OutputInteger + Multiplier * 15;

    else
      begin
        Result := 1;
        exit;
      end;
    end;

    Delete(InputString, length(InputString), 1);
    Multiplier := Multiplier * 16;
  end;

  Result := 0;
end;

procedure HexToWord(InputString: Str80; var OutputWord: Word; var Result: integer);

var
  Multiplier                  : Word;

begin
  Result := 1;
  Multiplier := 1;
  OutputWord := 0;
  if InputString = '' then exit;

  Result := 0;

  while length(InputString) > 0 do
  begin
    case UpCase(InputString[length(InputString)]) of
      '0': OutputWord := OutputWord + Multiplier * 0;
      '1': OutputWord := OutputWord + Multiplier * 1;
      '2': OutputWord := OutputWord + Multiplier * 2;
      '3': OutputWord := OutputWord + Multiplier * 3;
      '4': OutputWord := OutputWord + Multiplier * 4;
      '5': OutputWord := OutputWord + Multiplier * 5;
      '6': OutputWord := OutputWord + Multiplier * 6;
      '7': OutputWord := OutputWord + Multiplier * 7;
      '8': OutputWord := OutputWord + Multiplier * 8;
      '9': OutputWord := OutputWord + Multiplier * 9;
      'A': OutputWord := OutputWord + Multiplier * 10;
      'B': OutputWord := OutputWord + Multiplier * 11;
      'C': OutputWord := OutputWord + Multiplier * 12;
      'D': OutputWord := OutputWord + Multiplier * 13;
      'E': OutputWord := OutputWord + Multiplier * 14;
      'F': OutputWord := OutputWord + Multiplier * 15;

    else
      begin
        Result := 1;
        exit;
      end;
    end;

    Delete(InputString, length(InputString), 1);
    Multiplier := Multiplier * 16;
  end;

  Result := 0;
end;

procedure IncrementASCIIInteger(var ASCIIString: Str80);

var
  TempValue, Result           : integer;

begin
  Val(ASCIIString, TempValue, Result);
  if Result <> 0 then
  begin
    ASCIIString := '';
    exit;
  end;
  inc(TempValue);
  Str(TempValue, ASCIIString);
end;

function KeyId(Key: Char): Str80;

begin
  case Key of
    F1: KeyId := 'F1';
    F2: KeyId := 'F2';
    F3: KeyId := 'F3';
    F4: KeyId := 'F4';
    F5: KeyId := 'F5';
    F6: KeyId := 'F6';
    F7: KeyId := 'F7';
    F8: KeyId := 'F8';
    F9: KeyId := 'F9';
    F10: KeyId := 'F10';
    F11: KeyId := 'F11';
    F12: KeyId := 'F12';

    AltF1: KeyId := 'AltF1';
    AltF2: KeyId := 'AltF2';
    AltF3: KeyId := 'AltF3';
    AltF4: KeyId := 'AltF4';
    AltF5: KeyId := 'AltF5';
    AltF6: KeyId := 'AltF6';
    AltF7: KeyId := 'AltF7';
    AltF8: KeyId := 'AltF8';
    AltF9: KeyId := 'AltF9';
    AltF10: KeyId := 'AltF10';
    AltF11: KeyId := 'AltF11';
    AltF12: KeyId := 'AltF12';

    ControlF1: KeyId := 'ControlF1';
    ControlF2: KeyId := 'ControlF2';
    ControlF3: KeyId := 'ControlF3';
    ControlF4: KeyId := 'ControlF4';
    ControlF5: KeyId := 'ControlF5';
    ControlF6: KeyId := 'ControlF6';
    ControlF7: KeyId := 'ControlF7';
    ControlF8: KeyId := 'ControlF8';
    ControlF9: KeyId := 'ControlF9';
    ControlF10: KeyId := 'ControlF10';
    ControlF11: KeyId := 'ControlF11';
    ControlF12: KeyId := 'ControlF12';

  else KeyId := '';
  end;

end;

procedure DisplayLineInputString(Str: Str160; Cursor: integer; EndOfPrompt: integer);

var
  DisplayArea, Offset         : integer;

begin
 {    GoToXY (EndOfPrompt, WhereY);
     ClrEol;
 
     DisplayArea := Lo (WindMax) - EndOfPrompt - 2;
 
     IF Length (Str) < DisplayArea THEN
         BEGIN
         Write (Str);
         GoToXY (Cursor + EndOfPrompt - 1, WhereY);
         END
     ELSE
         BEGIN
         Offset := 0;
 
         IF Cursor >= DisplayArea - 1 THEN
             BEGIN
             REPEAT
                 Offset := Offset + 8
             UNTIL Cursor - Offset < DisplayArea - 3;
 
             IF Length (Str) - Offset > DisplayArea THEN
                 Write ('+', Copy (Str, Offset, DisplayArea - 3), '+')
             ELSE
                 Write ('+', Copy (Str, Offset, DisplayArea - 2));
             GoToXY (Cursor - Offset + EndOfPrompt + 1, WhereY);
             END
         ELSE
             BEGIN
             Write (Copy (Str, 1, DisplayArea - 2), '+');
             GoToXY (Cursor - Offset + EndOfPrompt - 1, WhereY);
             END;
 
         END;
  }
end;

function ControlKeyPressed: boolean;

begin
 //{WLI}    ControlKeyPressed := (Mem [$40:$17] AND 4) <> 0;
end;

function LastString(InputString: string): Str160;

var
  CharPointer                 : integer;

begin
  LastString := '';
  if InputString = '' then exit;

  GetRidOfPostcedingSpaces(InputString);

  for CharPointer := length(InputString) downto 1 do
    if (InputString[CharPointer] = ' ') or
      (InputString[CharPointer] = ControlI) then
    begin
      LastString := Copy(InputString, CharPointer + 1, length(InputString) - CharPointer);
      exit;
    end;

  LastString := InputString;
end;
{
procedure InitializeSerialPort(SerialPort: PortType;
  BaudRate: Word;
  Bits: integer;
  Parity: ParityType;
  StopBits: integer);

var
  BaseAddress                 : Word;
  TempByte                    : BYTE;

begin
  case SerialPort of
    Serial1: BaseAddress := Com1PortBaseAddress;
    Serial2: BaseAddress := Com2PortBaseAddress;
    Serial3: BaseAddress := Com3PortBaseAddress;
    Serial4: BaseAddress := Com4PortBaseAddress;
    Serial5: BaseAddress := Com5PortBaseAddress;
    Serial6: BaseAddress := Com6PortBaseAddress;
  else exit;
  end;

    Port [BaseAddress + ModemLineControlAddressOffset] := $80;

  case BaudRate of

    300:
      begin
               Port [BaseAddress]     := $80;
               Port [BaseAddress + 1] := $01;
      end;

    1200:
      begin
              Port [BaseAddress]     := $60;
               Port [BaseAddress + 1] := $00;
      end;

    2400:
      begin
               Port [BaseAddress]     := $30;
               Port [BaseAddress + 1] := $00;
      end;

    4800:
      begin
              Port [BaseAddress]     := $18;
               Port [BaseAddress + 1] := $00;
      end;

    9600:
      begin
              Port [BaseAddress]     := $0C;
               Port [BaseAddress + 1] := $00;
      end;

    19200:
      begin
              Port [BaseAddress]     := $06;
             Port [BaseAddress + 1] := $00;
      end;

    38400:
      begin
               Port [BaseAddress]     := $03;
            Port [BaseAddress + 1] := $00;
      end;

    57600:
      begin
               Port [BaseAddress]     := $02;
              Port [BaseAddress + 1] := $00;
      end;

  end;

  TempByte := $00;

// Do the Parity

  if Parity <> NoParity then
    if Parity = EvenParity then
      TempByte := TempByte or $18 // Even parity
    else
      TempByte := TempByte or $08; // Odd parity

//  Stop bits

  if StopBits = 2 then TempByte := TempByte or $04;

 // Seven or Eight bits

  if Bits = 8 then
    TempByte := TempByte or $03
  else
    TempByte := TempByte or $02;

 { Send new byte to the Modem Line Control register }

//{WLI}    Port [BaseAddress + ModemLineControlAddressOffset] := TempByte;

 { Now we need to set RTS and DTR }

//{WLI}    Port [BaseAddress + ModemControlAddressOffset] := 3;
//end;

function LineInput(Prompt: Str160;
  InitialString: Str160;
  OverwriteEnable: boolean;
  ExitOnAltKey: boolean): Str160;

{ This function will display the prompt and allow the operator to input
  a response to the prompt.  If an InitialString is passed along, it will
  be displayed as the initial entry value.  It can be edited, or written
  over as desired.  An escape with no entry will give a result of escape
  key.  If the input or initial entry goes beyond the right of the window,
  it will be handled nicely I hope. }

var
  Key                         : Char;
  InputString, TempString     : Str160;
  CursorPosition, EndOfPrompt, InputArea, InputShift: integer;
  VirginEntry, InsertMode, InputTooLong: boolean;

begin
 //{WLI}    ClrScr;
 //{WLI}    Write (Prompt);
 //{WLI}    EndOfPrompt := WhereX;
 {    CursorPosition := Length (InitialString) + 1;
 
     DisplayLineInputString (InitialString, CursorPosition, EndOfPrompt);
 
     InputString := InitialString;
     InsertMode := True;
     VirginEntry := OverWriteEnable;
 
     REPEAT
         REPEAT UNTIL KeyPressed;
         Key := ReadKey;
 
         CASE Key OF
             EscapeKey:
                 BEGIN
                 IF InputString = '' THEN
                     BEGIN
                     LineInput := EscapeKey;
                     Exit;
                     END;
 
                 InputString := '';
                 CursorPosition := 1;
                 VirginEntry := False;
                 END;
 
             BackSpace:
                 BEGIN
                 IF CursorPosition > 1 THEN
                     BEGIN
                     Delete (InputString, CursorPosition - 1, 1);
                     Dec (CursorPosition);
                     END;
                 VirginEntry := False;
                 END;
 
             ControlA:
                 IF CursorPosition > 1 THEN
                     BEGIN
                     REPEAT
                         Dec (CursorPosition);
                     UNTIL (CursorPosition = 1) OR
                           ((InputString [CursorPosition - 1] = ' ') AND
                            (InputString [CursorPosition] <> ' '));
                     VirginEntry := False;
                     END;
 
             ControlS:
                 IF CursorPosition > 1 THEN
                     BEGIN
                     Dec (CursorPosition);
                     VirginEntry := False;
                     END;
 
             ControlD:
                 IF CursorPosition < (Length (InputString) + 1) THEN
                     BEGIN
                     Inc (CursorPosition);
                     VirginEntry := False;
                     END;
 
             ControlF:
                 IF CursorPosition < (Length (InputString) + 1) THEN
                     BEGIN
                     REPEAT
                         Inc (CursorPosition);
                     UNTIL (CursorPosition = Length (InputString) + 1) OR
                           ((InputString [CursorPosition - 1] = ' ') AND
                            (InputString [CursorPosition] <> ' '));
                     VirginEntry := False;
                     END;
 
             ControlG:
                 IF CursorPosition < Length (InputString) + 1 THEN
                     BEGIN
                     Delete (InputString, CursorPosition, 1);
                     VirginEntry := False;
                     END;
 
 
 
             ControlP:
                 BEGIN
                 REPEAT UNTIL KeyPressed;
                 Key := ReadKey;
 
                 IF VirginEntry THEN
                     BEGIN
                     InputString := Key;
                     VirginEntry := False;
                     CursorPosition := 2;
                     END
                 ELSE
                     BEGIN
                     IF InsertMode THEN
                         Insert (Key, InputString, CursorPosition)
                     ELSE
                         InputString [CursorPosition] := Key;
                     Inc (CursorPosition);
                     END;
                 END;
 
             ControlT:
                 BEGIN
                 TempString := Copy (InputString, CursorPosition, 200);
                 Delete (InputString, CursorPosition, 200);
                 TempString := StringWithFirstWordDeleted (TempString);
                 InputString := InputString + TempString;
                 VirginEntry := False;
                 END;
 
             ControlY:
                 BEGIN
                 InputString := '';
                 VirginEntry := False;
                 END;
 
             NullKey:
                 BEGIN
                 VirginEntry := False;
                 Key := ReadKey;
 
                 CASE Key OF
                     HomeKey: CursorPosition := 1;
 
                     LeftArrow:
                         IF CursorPosition > 1 THEN
                             Dec (CursorPosition);
 
                     RightArrow:
                         IF CursorPosition < Length (InputString) + 1 THEN
                             Inc (CursorPosition);
 
                     EndKey:
                         CursorPosition := Length (InputString) + 1;
 
                     InsertKey: InsertMode := NOT InsertMode;
 
                     DeleteKey:
                         IF CursorPosition <= Length (InputString) THEN
                             Delete (InputString, CursorPosition, 1);
 
                     ELSE
                         IF ExitOnAltKey THEN
                             BEGIN
                             LineInput := NullKey + Key;
                             Exit;
                             END;
                     END;
 
                 END
 
 
 
             ELSE
                 IF Key >= ' ' THEN
                     BEGIN
                     IF VirginEntry THEN
                         BEGIN
                         InputString := Key;
                         VirginEntry := False;
                         CursorPosition := 2;
                         END
                     ELSE
                         BEGIN
                         IF InsertMode THEN
                             Insert (Key, InputString, CursorPosition)
                         ELSE
                             InputString [CursorPosition] := Key;
                         Inc (CursorPosition);
                         END;
                     END
                 ELSE
                     IF Key = CarriageReturn THEN
                         BEGIN
                         LineInput := InputString;
                         Exit;
                         END;
 
             END;
 
     DisplayLineInputString (InputString, CursorPosition, EndOfPrompt);
     UNTIL False;
  }
end;

function LooksLikeAGrid(var GridString: Str20): boolean;

{ If it does look like a grid, it will make the first two letters lower
  case so it looks like a domestic QTH. }

var
  TestString                  : Str20;

begin
  TestString := UpperCase(GridString);

  LooksLikeAGrid := False;

  if (length(TestString) <> 4) and (length(TestString) <> 6) then exit;

  if (TestString[1] < 'A') or (TestString[1] > 'R') then exit;
  if (TestString[2] < 'A') or (TestString[2] > 'R') then exit;
  if (TestString[3] < '0') or (TestString[3] > '9') then exit;
  if (TestString[4] < '0') or (TestString[4] > '9') then exit;

  if GridString[1] > 'Z' then
    GridString[1] := CHR(Ord(GridString[1]) - Ord('a') + Ord('A'));

  if GridString[2] > 'Z' then
    GridString[2] := CHR(Ord(GridString[2]) - Ord('a') + Ord('A'));

  LooksLikeAGrid := true;
end;

function LowerCase(const S: string): string;
var
  Ch                          : Char;
  L                           : Integer;
  Source, Dest                : PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'A') and (Ch <= 'Z') then Inc(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;

 {    ASM

     CLD
     LEA     SI, Input
     LES     DI, @Result
     SEGSS   LODSB
     STOSB
     XOR     AH, AH
     XCHG    AX, CX
     JCXZ    @3
     @1:
     SEGSS   LODSB
     CMP     AL, 'A'
     JB      @2
     CMP     AL, 'Z'
     JA      @2
     ADD     AL, 20H
     @2:
     STOSB
     LOOP    @1
     @3:
     END;
  }


function Lpt1BaseAddress: Word;

var
  Address                     : Word;

begin
 {    Address := MemW [ $40:8 ];
 
     IF Address = 0 THEN
         Lpt1BaseAddress := $3BC
     ELSE
         Lpt1BaseAddress := Address;
  }
end;

function Lpt2BaseAddress: Word;

var
  Address                     : Word;

begin
 {    Address := MemW [ $40:$A ];
 
     IF Address = 0 THEN
         Lpt2BaseAddress := $278
     ELSE
         Lpt2BaseAddress := Address;
  }
end;

function Lpt3BaseAddress: Word;

var
  Address                     : Word;

begin
 {    Address := MemW [ $40:$C ];
 
     IF Address = 0 THEN
         Lpt3BaseAddress := $378
     ELSE
         Lpt3BaseAddress := Address;
  }
end;

function MakeDupeFilename(Band: BandType; Mode: ModeType): Str80;

{ This procedure will generate the duping filename for the band and mode
    specified.                                                                }

begin
  MakeDupeFilename := 'L' + ModeString[Mode] + BandString[Band];
end;

function MakeTitle(Band: BandType; Mode: ModeType; Contest: Str80; CallUsed: Str80): Str80;

begin
  MakeTitle := Contest + '   ' + CallUsed + '   ' + BandString[Band] + ' ' + ModeString[Mode];
end;

function MicroTimeElapsed(StartTime: TimeRecord): LONGINT;

{ Gives answer in Sec100s }

var
  ElaspedTime                 : LONGINT;
  Hour, Min, Sec, Sec100      : Word;

begin
 //{WLI}    GetTime (Hour, Min, Sec, Sec100);

  ElaspedTime := 0;

  if Sec <> StartTime.Second then
  begin
    if Sec < StartTime.Second then
      ElaspedTime := (Sec + 60) - StartTime.Second
    else
      ElaspedTime := Sec - StartTime.Second;
    ElaspedTime := ElaspedTime * 100;
  end;

  if Sec100 <> StartTime.Sec100 then
  begin
    if Sec100 < StartTime.Sec100 then
    begin
      ElaspedTime := ElaspedTime + Sec100;
      ElaspedTime := ElaspedTime - StartTime.Sec100;
    end
    else
      ElaspedTime := ElaspedTime + (Sec100 - StartTime.Sec100);
  end;

  MicroTimeElapsed := ElaspedTime;
end;

function MinutesToTimeString(Minutes: integer): Str20;

var
  Hours                       : integer;
  HourString, MinuteString    : Str20;

begin
  Hours := Minutes div 60;
  Minutes := Minutes mod 60;

  Str(Hours, HourString);
  Str(Minutes, MinuteString);
  while length(MinuteString) < 2 do MinuteString := '0' + MinuteString;
  MinutesToTimeString := HourString + ':' + MinuteString;
end;

function MultiMessageSourceBand(Source: BYTE): BandType;

begin
  case Source of
    $E0: MultiMessageSourceBand := Band160;
    $E1: MultiMessageSourceBand := Band80;
    $E2: MultiMessageSourceBand := Band40;
    $E3: MultiMessageSourceBand := Band20;
    $E4: MultiMessageSourceBand := Band15;
    $E5: MultiMessageSourceBand := Band10;

    $E6: MultiMessageSourceBand := Band30;
    $E7: MultiMessageSourceBand := Band17;
    $E8: MultiMessageSourceBand := Band12;
    $E9: MultiMessageSourceBand := Band6;
    $EA: MultiMessageSourceBand := Band2;
    $EB: MultiMessageSourceBand := Band222;
    $EC: MultiMessageSourceBand := Band432;

    $ED: MultiMessageSourceBand := Band902;
    $EE: MultiMessageSourceBand := Band1296;
    $EF: MultiMessageSourceBand := Band2304;
    $F0: MultiMessageSourceBand := Band3456;
    $F1: MultiMessageSourceBand := Band5760;
    $F2: MultiMessageSourceBand := Band10G;
    $F3: MultiMessageSourceBand := Band24G;
    $F4: MultiMessageSourceBand := BandLight;

  else
    MultiMessageSourceBand := NoBand;
  end;
end;

procedure NoCursor;

//{WLI}VAR Regs: REGISTERS;

begin
 {    Regs.AH := $1;
     Regs.CH := $10;
     Regs.CL := $00;
     Intr ($10, Regs);
  }
end;

function NumberPartOfString(InputString: Str160): Str80;

var
  TempString                  : Str80;
  CharPointer                 : integer;

begin
  if InputString = '' then
  begin
    NumberPartOfString := '';
    exit;
  end;
  TempString := '';
  for CharPointer := 1 to length(InputString) do
    if (InputString[CharPointer] >= '0') and (InputString[CharPointer] <= '9') then
      TempString := TempString + InputString[CharPointer];
  NumberPartOfString := TempString;
end;

function OkayToProceed: boolean;

var
  Key                         : Char;

begin
  OkayToProceed := False;

  repeat
    Key := UpCase(GetKey('Okay to proceed? (Y/N): '));
  until (Key = 'N') or (Key = EscapeKey) or (Key = 'Y');

 //{WLI}    GoToXY (1, WhereY);
 //{WLI}    ClrEol;

  OkayToProceed := Key = 'Y';
end;

function OpenDupeFileForRead(var FileHandle: Text; FileName: Str80): boolean;

{ This function will open a duping file and make it ready to read in.  If
    the file does not exist or does not appear to be a duping file, it will
    return FALSE.  If it does exist, the next line to be read will be the
    title.                                                                  }

var
  TempString                  : Str80;

begin
  OpenDupeFileForRead := False;
  if not OpenFileForRead(FileHandle, FileName) then exit;
  ReadLn(FileHandle, TempString);
  OpenDupeFileForRead := TempString = 'DUPE';
end;

function OpenFileForAppend(var FileHandle: Text; FileName: Str80): boolean;

{ This function will open the filename indicated for append.  If the file
    does not exist, it is opened for write.  At this time, the function
    always returns TRUE (must of been lazy the day I wrote it).                 }

begin
  OpenFileForAppend := true;

  if FileExists(FileName) then
  begin
    Assign(FileHandle, FileName);
    Append(FileHandle);
  end
  else
  begin
    Assign(FileHandle, FileName);
    ReWrite(FileHandle);
  end;
end;

function OpenFileForRead(var FileHandle: Text; FileName: Str80): boolean;

begin
  Assign(FileHandle, FileName);
{$I-}
  Reset(FileHandle);
{$I+}
  OpenFileForRead := IORESULT = 0;
end;

function OpenFileForWrite(var FileHandle: Text; FileName: Str80): boolean;

begin
  Assign(FileHandle, FileName);
{$I-}
  ReWrite(FileHandle);
{$I+}
  OpenFileForWrite := IORESULT = 0;
end;

function OperatorEscape: boolean;

var
  Key                         : Char;

begin
 {    OperatorEscape := False;
 
     IF KeyPressed THEN
         BEGIN
         Key := ReadKey;
         IF Key = EscapeKey THEN
             BEGIN
             OperatorEscape := True;
             Exit;
             END
         ELSE
             IF Key = NullKey THEN
                 Key := ReadKey;
         END;
  }
end;

procedure PinWheel;

begin
 {    GoToXY (1, WhereY);
     Inc (ActivityCounter);
 
     CASE ActivityCounter OF
         1: Write ('-');
         2: Write ('\');
         3: Write ('|');
         ELSE BEGIN
              Write ('/');
              ActivityCounter := 0;
              END;
         END;
  }
end;

function PortableStation(Call: CallString): boolean;

{ This function will return TRUE if the callsign passed to it is a portable
    station.                                                        }

var
  TempString                  : Str20;
  TempChar                    : Char;

begin
  PortableStation := False;
  TempString := PostcedingString(Call, '/');

  if StringHas(TempString, '/') then
    TempString := PostcedingString(TempString, '/');

  if length(TempString) = 1 then
  begin
    TempChar := TempString[1];
    if ((TempChar >= '0') and (TempChar <= '9')) or (TempChar = 'P') then
      PortableStation := true;
  end;
end;

function PostcedingString(LongString: string; Deliminator: string): string;

var
  Position                    : integer;

begin
  Position := pos(Deliminator, LongString);

  if Position > 0 then
    PostcedingString := Copy(LongString,
      Position + length(Deliminator),
      length(LongString) - Position - (length(Deliminator) - 1))
  else
    PostcedingString := '';
end;

function PrecedingString(LongString: string; Deliminator: string): string;

var
  Position                    : integer;

begin
  Position := pos(Deliminator, LongString);

  if Position >= 2 then
    PrecedingString := Copy(LongString, 1, Position - 1)
  else
    PrecedingString := '';
end;


function ReadChar(SerialPort: PortType): Char;

{ This funtion will get the char that is waiting in the UART }

var
  PortAddress                 : Word;

begin
  repeat until CharReady(SerialPort);

  PortAddress := 0;

  case SerialPort of
    Serial1: PortAddress := Com1PortBaseAddress;
    Serial2: PortAddress := Com2PortBaseAddress;
    Serial3: PortAddress := Com3PortBaseAddress;
    Serial4: PortAddress := Com4PortBaseAddress;
    Serial5: PortAddress := Com5PortBaseAddress;
    Serial6: PortAddress := Com6PortBaseAddress;
  end;

 //{WLI}    IF PortAddress <> 0 THEN        ReadChar := Chr (Port [PortAddress])
 //{WLI}    ELSE        ReadChar := Chr (0);

end;

function RemoveBand(var LongString: string): BandType;

var
  TempByte                    : BYTE;
  Band                        : BandType;

begin
  TempByte := Ord(LongString[1]);
  Move(TempByte, Band, 1);
  RemoveBand := Band;
  Delete(LongString, 1, 1);
end;

function RemoveMode(var LongString: string): ModeType;

var
  TempByte                    : BYTE;
  Mode                        : ModeType;

begin
  TempByte := Ord(LongString[1]);
  Move(TempByte, Mode, 1);
  RemoveMode := Mode;
  Delete(LongString, 1, 1);
end;

function RemoveFirstChar(var LongString: string): Char;

var
  CharCount                   : integer;
  FirstWordFound              : boolean;
  FirstWordCursor             : integer;

begin
  while (LongString <> '') and ((Copy(LongString, 1, 1) = ' ') or (Copy(LongString, 1, 1) = TabKey)) do
    Delete(LongString, 1, 1);

  if LongString = '' then
  begin
    RemoveFirstChar := NullCharacter;
    exit;
  end;

  RemoveFirstChar := LongString[1];
  Delete(LongString, 1, 1);

  while (LongString <> '') and ((Copy(LongString, 1, 1) = ' ') or (Copy(LongString, 1, 1) = TabKey)) do
    Delete(LongString, 1, 1);
end;

function RemoveFirstLongInteger(var LongString: string): LONGINT;

var
  IntegerString               : Str80;
  Number                      : LONGINT;
  Result1                     : integer;

begin
  IntegerString := RemoveFirstString(LongString);
  Val(IntegerString, Number, Result1);
  if Result = 0 then
    RemoveFirstLongInteger := Number
  else
    RemoveFirstLongInteger := 0;
end;

function RemoveFirstReal(var LongString: string): REAL;

var
  Result1                     : integer;
  TempString                  : Str80;
  TempReal                    : REAL;

begin
  TempString := RemoveFirstString(LongString);

  Val(TempString, TempReal, Result1);

  if Result1 = 0 then
    RemoveFirstReal := TempReal
  else
    RemoveFirstReal := 0;
end;

function GetFirstString(var LongString: string): Str80;

var
  CharCount                   : integer;
  FirstWordFound              : boolean;
  FirstWordCursor             : integer;

begin
  if LongString = '' then
  begin
    GetFirstString := '';
    exit;
  end;

  FirstWordFound := False;

  for CharCount := 1 to length(LongString) do
    if FirstWordFound then
    begin
      if (LongString[CharCount] = ' ') or (LongString[CharCount] = TabKey) then
      begin
        GetFirstString := Copy(LongString, FirstWordCursor, CharCount - FirstWordCursor);
        exit;
      end;
    end
    else
      if (LongString[CharCount] <> ' ') and (LongString[CharCount] <> TabKey) then
      begin
        FirstWordFound := true;
        FirstWordCursor := CharCount;
      end;

  if FirstWordFound then
    GetFirstString := Copy(LongString, FirstWordCursor, length(LongString) - FirstWordCursor + 1)
  else
    GetFirstString := '';
end;

function RemoveFirstString(var LongString: string): Str80;

var
  CharCount                   : integer;
  FirstWordFound              : boolean;
  FirstWordCursor             : integer;

begin
  if LongString = '' then
  begin
    RemoveFirstString := '';
    exit;
  end;

  for CharCount := 1 to length(LongString) do
    if (LongString[CharCount] = CarriageReturn) or
      (LongString[CharCount] = LineFeed) then
      LongString[CharCount] := ' ';

  FirstWordFound := False;

  for CharCount := 1 to length(LongString) do
    if FirstWordFound then
    begin
      if (LongString[CharCount] = ' ') or (LongString[CharCount] = TabKey) then
      begin
        RemoveFirstString := Copy(LongString, FirstWordCursor, CharCount - FirstWordCursor);
        Delete(LongString, 1, CharCount);
        exit;
      end;
    end
    else
      if (LongString[CharCount] <> ' ') and (LongString[CharCount] <> TabKey) then
      begin
        FirstWordFound := true;
        FirstWordCursor := CharCount;
      end;

  if FirstWordFound then
    RemoveFirstString := Copy(LongString, FirstWordCursor, length(LongString) - FirstWordCursor + 1)
  else
    RemoveFirstString := '';
  LongString := '';
end;

function RemoveLastString(var LongString: string): Str80;

var
  CharPos                     : integer;

begin
  if length(LongString) > 0 then
  begin
    GetRidOfPostcedingSpaces(LongString);
    for CharPos := length(LongString) downto 1 do
      if (LongString[CharPos] = ' ') or (LongString[CharPos] = TabKey) then
      begin
        RemoveLastString := Copy(LongString, CharPos + 1, length(LongString) - CharPos);
        Delete(LongString, CharPos, length(LongString) - CharPos + 1);
        exit;
      end;

    RemoveLastString := LongString;
    LongString := '';
  end
  else
    RemoveLastString := '';
end;

function GetLastString(var LongString: string): Str80;

var
  CharPos                     : integer;

begin
  if length(LongString) > 0 then
  begin
    GetRidOfPostcedingSpaces(LongString);
    for CharPos := length(LongString) downto 1 do
      if (LongString[CharPos] = ' ') or (LongString[CharPos] = TabKey) then
      begin
        GetLastString := Copy(LongString, CharPos + 1, length(LongString) - CharPos);
        exit;
      end;

    GetLastString := LongString;
  end
  else
    GetLastString := '';
end;

procedure RenameFile(OldName: Str80; NewName: Str80);

{ This procedure will rename the filename specified to the new name
    indicated.  If a file existed with the newname, it is deleted first. }

var
  f                           : Text;

begin
  DeleteFile(NewName);
  Assign(f, OldName);
  Rename(f, NewName);
end;

procedure ReportError(Prompt: Str80);

{ This procedure will print the string passed to it in red and beep }

begin
//  SHOWMESSAGE(Prompt);
 {    TextColor (Red);
     WriteLn (Prompt, Beep);
     TextColor (Yellow);
    }
end;

function RootCall(Call: CallString): CallString;

var
  TempCall                    : CallString;

begin
  TempCall := StandardCallFormat(Call, true);

  if StringHas(TempCall, '/') then
    TempCall := PostcedingString(TempCall, '/');

  if length(TempCall) <= 2 then
  begin
    TempCall := PrecedingString(StandardCallFormat(Call, true), '/');

    if length(TempCall) >= 3 then
    begin
      RootCall := TempCall;
      exit;
    end;
  end;

  if StringHas(TempCall, '/') then
    TempCall := PrecedingString(TempCall, '/');

  if length(TempCall) > 6 then
    TempCall[0] := CHR(6);
  RootCall := TempCall;
end;

function RoverCall(Call: CallString): boolean;

begin
  RoverCall := UpperCase(Copy(Call, length(Call) - 1, 2)) = '/R';
end;

procedure SendByte(SerialPort: PortType; ByteToSend: BYTE);

{ This procedure will send a byte to the serial port. }

begin
  SendChar(SerialPort, CHR(ByteToSend));
end;

procedure PacketSendChar(SerialPort: PortType; CharToSend: Char);

var
  PortAddress                 : Word;
 //{WLI}    Regs: REGISTERS;

begin
 {    PortAddress := 0;
 
     CASE SerialPort OF
         Serial1: PortAddress := Com1PortBaseAddress;
         Serial2: PortAddress := Com2PortBaseAddress;
         Serial3: PortAddress := Com3PortBaseAddress;
         Serial4: PortAddress := Com4PortBaseAddress;
         Serial5: PortAddress := Com5PortBaseAddress;
         Serial6: PortAddress := Com6PortBaseAddress;
 
         DRSI: BEGIN
               Regs.AH := 1;
               Regs.AL := Ord (CharToSend);
               Intr ($FF, Regs);
               Exit;
               END;
         END;
 
     IF PortAddress = 0 THEN Exit;
 
 {    REPEAT UNTIL (Port [PortAddress + 5] AND $20) = $20;  }

 //{WLI}    Port [PortAddress] := Ord (CharToSend);
end;

function UartEmpty(SerialPort: PortType): boolean;

var
  PortAddress                 : Word;

begin
 {    PortAddress := 0;
 
     CASE SerialPort OF
         Serial1: PortAddress := Com1PortBaseAddress;
         Serial2: PortAddress := Com2PortBaseAddress;
         Serial3: PortAddress := Com3PortBaseAddress;
         Serial4: PortAddress := Com4PortBaseAddress;
         Serial5: PortAddress := Com5PortBaseAddress;
         Serial6: PortAddress := Com6PortBaseAddress;
         END;
 
     IF PortAddress = 0 THEN
         BEGIN
         UartEmpty := True;
         Exit;
         END;
 
     UartEmpty := (Port [PortAddress + 5] AND $20) = $20;
    }
end;

procedure SendChar(SerialPort: PortType; CharToSend: Char);

var
  PortAddress                 : Word;

begin
  PortAddress := 0;

  case SerialPort of
    Serial1: PortAddress := Com1PortBaseAddress;
    Serial2: PortAddress := Com2PortBaseAddress;
    Serial3: PortAddress := Com3PortBaseAddress;
    Serial4: PortAddress := Com4PortBaseAddress;
    Serial5: PortAddress := Com5PortBaseAddress;
    Serial6: PortAddress := Com6PortBaseAddress;
  end;

  if PortAddress = 0 then exit;

 //{WLI}    REPEAT UNTIL (Port [PortAddress + 5] AND $20) = $20;

 //{WLI}    Port [PortAddress] := Ord (CharToSend);
end;

procedure SendIntegerInMorse(Value: integer);

var
  TempString                  : Str20;

begin
  Str(Value, TempString);
  SendMorse(TempString);
end;

procedure SendMorse(Message: Str255);

var
  Pointer                     : integer;

begin
  Message := UpperCase(Message);
  for Pointer := 1 to length(Message) do
  begin
    case Message[Pointer] of
      'A':
        begin
          Dit;
          Dah;
        end;
      'B':
        begin
          Dah;
          Dit;
          Dit;
          Dit;
        end;
      'C':
        begin
          Dah;
          Dit;
          Dah;
          Dit;
        end;
      'D':
        begin
          Dah;
          Dit;
          Dit;
        end;
      'E':
        begin
          Dit;
        end;
      'F':
        begin
          Dit;
          Dit;
          Dah;
          Dit;
        end;
      'G':
        begin
          Dah;
          Dah;
          Dit;
        end;
      'H':
        begin
          Dit;
          Dit;
          Dit;
          Dit;
        end;
      'I':
        begin
          Dit;
          Dit;
        end;
      'J':
        begin
          Dit;
          Dah;
          Dah;
          Dah;
        end;
      'K':
        begin
          Dah;
          Dit;
          Dah;
        end;
      'L':
        begin
          Dit;
          Dah;
          Dit;
          Dit;
        end;
      'M':
        begin
          Dah;
          Dah;
        end;
      'N':
        begin
          Dah;
          Dit;
        end;
      'O':
        begin
          Dah;
          Dah;
          Dah;
        end;
      'P':
        begin
          Dit;
          Dah;
          Dah;
          Dit;
        end;
      'Q':
        begin
          Dah;
          Dah;
          Dit;
          Dah;
        end;
      'R':
        begin
          Dit;
          Dah;
          Dit;
        end;
      'S':
        begin
          Dit;
          Dit;
          Dit;
        end;
      'T':
        begin
          Dah;
        end;
      'U':
        begin
          Dit;
          Dit;
          Dah;
        end;
      'V':
        begin
          Dit;
          Dit;
          Dit;
          Dah;
        end;
      'W':
        begin
          Dit;
          Dah;
          Dah;
        end;
      'X':
        begin
          Dah;
          Dit;
          Dit;
          Dah;
        end;
      'Y':
        begin
          Dah;
          Dit;
          Dah;
          Dah;
        end;
      'Z':
        begin
          Dah;
          Dah;
          Dit;
          Dit;
        end;
      '0':
        begin
          Dah;
          Dah;
          Dah;
          Dah;
          Dah;
        end;
      '1':
        begin
          Dit;
          Dah;
          Dah;
          Dah;
          Dah;
        end;
      '2':
        begin
          Dit;
          Dit;
          Dah;
          Dah;
          Dah;
        end;
      '3':
        begin
          Dit;
          Dit;
          Dit;
          Dah;
          Dah;
        end;
      '4':
        begin
          Dit;
          Dit;
          Dit;
          Dit;
          Dah;
        end;
      '5':
        begin
          Dit;
          Dit;
          Dit;
          Dit;
          Dit;
        end;
      '6':
        begin
          Dah;
          Dit;
          Dit;
          Dit;
          Dit;
        end;
      '7':
        begin
          Dah;
          Dah;
          Dit;
          Dit;
          Dit;
        end;
      '8':
        begin
          Dah;
          Dah;
          Dah;
          Dit;
          Dit;
        end;
      '9':
        begin
          Dah;
          Dah;
          Dah;
          Dah;
          Dit;
        end;
      '.':
        begin
          Dit;
          Dah;
          Dit;
          Dah;
          Dit;
          Dah;
        end;
      ',':
        begin
          Dah;
          Dah;
          Dit;
          Dit;
          Dah;
          Dah;
        end;
      '?':
        begin
          Dit;
          Dit;
          Dah;
          Dah;
          Dit;
          Dit;
        end;
      '/':
        begin
          Dah;
          Dit;
          Dit;
          Dah;
          Dit;
        end;
      '<':
        begin
          Dit;
          Dit;
          Dit;
          Dah;
          Dit;
          Dah;
        end;
      ' ': Delay(WordSpace);
    end;
    Delay(CharacterSpace);
  end;
end;

function SendPortEmpty(SerialPort: PortType): boolean;

var
  Status                      : BYTE;
  PortAddress                 : integer;

begin
  case SerialPort of
    Serial1: PortAddress := Com1PortBaseAddress + PortStatusAddressOffset;
    Serial2: PortAddress := Com2PortBaseAddress + PortStatusAddressOffset;
    Serial3: PortAddress := Com3PortBaseAddress + PortStatusAddressOffset;
    Serial4: PortAddress := Com4PortBaseAddress + PortStatusAddressOffset;
    Serial5: PortAddress := Com5PortBaseAddress + PortStatusAddressOffset;
    Serial6: PortAddress := Com6PortBaseAddress + PortStatusAddressOffset;
  else exit;
  end;

 //{WLI}    Status := Port [PortAddress];
  Status := Status and $20;
  SendPortEmpty := Status <> 0;
end;

procedure SendString(SerialPort: PortType; StringToSend: Str160);

{ This procedure will sent a string to the serial port }

var
  StringPointer               : integer;

begin
  if length(StringToSend) > 0 then
    for StringPointer := 1 to length(StringToSend) do
      SendChar(SerialPort, StringToSend[StringPointer]);
end;

procedure SetMorseSpeed(Speed: integer; Pitch: integer);

begin
  if Speed > 0 then
  begin
    DitLength := 1200 div Speed;
    DahLength := DitLength * 3;
    CharacterSpace := DitLength;
    WordSpace := 2 * DitLength + (DitLength div 2);
  end;
  CWPitch := Pitch;
end;
{
procedure SETRTS(SerialPort: PortType);

var
  PortAddress                 : Word;

begin
  PortAddress := 0;

  case SerialPort of
    Serial1: PortAddress := Com1PortBaseAddress;
    Serial2: PortAddress := Com2PortBaseAddress;
    Serial3: PortAddress := Com3PortBaseAddress;
    Serial4: PortAddress := Com4PortBaseAddress;
    Serial5: PortAddress := Com5PortBaseAddress;
    Serial6: PortAddress := Com6PortBaseAddress;
  end;

   IF PortAddress <> 0 THEN Port [PortAddress + 4] := 2;
end;
}

function DirectoryExists(DirName: Str80): boolean;

//var  DirInfo: TSearchRec;

begin
 {    FindFirst (DirName, Directory, DirInfo);
     DirectoryExists := DosError = 0;
    }
end;

procedure DirectoryShowCursor(Entry: integer; StartY: integer);

var
  Row, col                    : integer;

begin
 {    NoCursor;
     Row := Entry DIV 5 + 1;
     Col := (Entry MOD 5) * 15 + 1;
     GoToXY (Col, Row + StartY);
     Write ('<');
     Col := (Entry MOD 5) * 15 + 14;
     GoToXY (Col, Row + StartY);
     Write ('>');
    }
end;

procedure DirectoryClearCursor(Entry: integer; StartY: integer);

var
  Row, col                    : integer;

begin
 {    Row := Entry DIV 5 + 1;
     Col := (Entry MOD 5) * 15 + 1;
     GoToXY (Col, Row + StartY);
     Write (' ');
     Col := (Entry MOD 5) * 15 + 14;
     GoToXY (Col, Row + StartY);
     Write (' ');
  }
end;

function ShowDirectoryAndSelectFile(PathAndMask: Str80;
  InitialFile: Str80;
  ClearOnCarriageReturn: boolean): Str80;

{ This procedure will show the directory of files found in the specified
    path.  The files are shown 5 across starting on the line the cursor is
    on.  The available window will be filled with entries and if there are
    more, moving the cursor below the window will scroll the entries up.
    The cursor can select a file by pressing return. The complete filename
    with path will be returned.  If an escape is hit, the string will be
    the escape char.  The complete window will be cleared before returning. }
{
var
  DirInfo: TSearchRec;
  NumberFiles, FileNumber, SelectedFile, StartX, StartY, Row, col: integer;
  StartIndex, Line, NumberLines, Address, BubbleCount, Range, Index: integer;
  FileNames: array[0..255] of string[12];
  InputString, TempString, Dir, Name, Ext: Str20;
  Key: Char;
}
begin
 {    ShowDirectoryAndSelectFile := '';
     NumberFiles := 0;
     StartIndex := 0;
 
     FSplit (PathAndMask, Dir, Name, Ext);
     IF Name = '' THEN PathAndMask := Dir + '*.*';
 
     FindFirst (PathAndMask, Archive, DirInfo);
 
     WHILE DosError = 0 DO
         BEGIN
         FileNames [NumberFiles] := DirInfo.Name;
         Inc (NumberFiles);
         FindNext (DirInfo);
         END;
 
     StartX := WhereX;
     StartY := WhereY;
     SelectedFile := 0;
 
     IF InitialFile = '' THEN
         WriteLn ('DIRECTORY for ', PathAndMask, ' : ')
     ELSE
         GoToXY (1, WhereY + 1);
 
     NumberLines := 1;
 
     IF NumberFiles > 0 THEN
         BEGIN
         IF NumberFiles > 1 THEN
             BEGIN
             Index := NumberFiles - 2;
 
             FOR BubbleCount := 1 TO NumberFiles - 1 DO
                 BEGIN
                 FOR Address := 0 TO Index DO
                     IF FileNames [Address] > FileNames [Address + 1] THEN
                         BEGIN
                         TempString := FileNames [Address + 1];
                         FileNames [Address + 1] := FileNames [Address];
                         FileNames [Address] := TempString;
                         END;
                 Dec (Index);
                 END;
             END;
 
         FOR FileNumber := 0 TO NumberFiles - 1 DO
             BEGIN
             Row := FileNumber DIV 5;
             Col := (FileNumber MOD 5) * 15 + 2;
             GoToXY (Col, Row + StartY + 1);
 
             IF InitialFile = '' THEN
                 Write (Copy (FileNames [FileNumber], 1, 12));
 
             IF FileNames [FileNumber] = InitialFile THEN
                 StartIndex := FileNumber;
             IF Col = 2 THEN Inc (NumberLines);
             END;
 
         DirectoryShowCursor (StartIndex, StartY);
 
         SelectedFile := StartIndex;
 
         InputString := '';
 
         REPEAT
             Key := UpCase (ReadKey);
 
             CASE Key OF
                 EscapeKey, ControlC:
                     BEGIN
                     ShowDirectoryAndSelectFile := Key;
                     GoToXY (1, StartY);
                     FOR Line := 1 TO NumberLines DO
                         BEGIN
                         ClrEol;
                         GoToXY (1, WhereY + 1);
                         END;
                     GoToXY (1, StartY);
                     SmallCursor;
                     Exit;
                     END;
 
                 CarriageReturn:
                     BEGIN
                     ShowDirectoryAndSelectFile := Dir + FileNames [SelectedFile];
                     IF ClearOnCarriageReturn THEN
                         BEGIN
                         GoToXY (1, StartY);
                         FOR Line := 1 TO NumberLines DO
                             BEGIN
                             ClrEol;
                             GoToXY (1, WhereY + 1);
                             END;
                         GoToXY (1, StartY);
                         SmallCursor;
                         END;
                     Exit;
                     END;
 
                 BackSpace:
                     IF InputString <> '' THEN
                         BEGIN
                         Delete (InputString, Length (InputString), 1);
 
                         FOR FileNumber := 0 TO NumberFiles - 1 DO
                             BEGIN
                             IF Pos (InputString, FileNames [FileNumber]) = 1 THEN
                                 BEGIN
                                 DirectoryClearCursor (SelectedFile, StartY);
                                 SelectedFile := FileNumber;
                                 DirectoryShowCursor (SelectedFile, StartY);
                                 Break;
                                 END;
                             END;
                         END;
 
                 NullKey:
                     BEGIN
                     Key := ReadKey;
 
                     CASE Key OF
                         RightArrow:
                             IF SelectedFile < NumberFiles - 1 THEN
                                 BEGIN
                                 DirectoryClearCursor (SelectedFile, StartY);
                                 Inc (SelectedFile);
                                 DirectoryShowCursor (SelectedFile, StartY);
                                 END;
 
                         LeftArrow:
                             IF SelectedFile > 0 THEN
                                 BEGIN
                                 DirectoryClearCursor (SelectedFile, StartY);
                                 Dec (SelectedFile);
                                 DirectoryShowCursor (SelectedFile, StartY);
                                 END;
 
                         UpArrow:
                             IF SelectedFile - 5 >= 0 THEN
                                 BEGIN
                                 DirectoryClearCursor (SelectedFile, StartY);
                                 SelectedFile := SelectedFile - 5;
                                 DirectoryShowCursor (SelectedFile, StartY);
                                 END;
 
                         DownArrow:
                             IF SelectedFile + 5 <= NumberFiles - 1 THEN
                                 BEGIN
                                 DirectoryClearCursor (SelectedFile, StartY);
                                 SelectedFile := SelectedFile + 5;
                                 DirectoryShowCursor (SelectedFile, StartY);
                                 END;
 
                         HomeKey:
                             BEGIN
                             DirectoryClearCursor (SelectedFile, StartY);
                             SelectedFile := 0;
                             DirectoryShowCursor (SelectedFile, StartY);
                             END;
 
                         EndKey:
                             BEGIN
                             DirectoryClearCursor (SelectedFile, StartY);
                             SelectedFile := NumberFiles - 1;
                             DirectoryShowCursor (SelectedFile, StartY);
                             END;
 
                         END;
                     END;
 
                 ELSE
                     IF ((Key >= 'A') AND (Key <= 'Z')) OR
                        ((Key >= '0') AND (Key <= '9')) THEN
                         BEGIN
                         InputString := InputString + Key;
 
                         FOR FileNumber := 0 TO NumberFiles - 1 DO
                             BEGIN
                             IF Pos (InputString, FileNames [FileNumber]) = 1 THEN
                                 BEGIN
                                 DirectoryClearCursor (SelectedFile, StartY);
                                 SelectedFile := FileNumber;
                                 DirectoryShowCursor (SelectedFile, StartY);
                                 Break;
                                 END;
                             END;
                         END;
 
                 END;
         UNTIL False;
         END
     ELSE
         BEGIN
         Write ('No files found!!  Press any key to continue.', Beep);
         REPEAT UNTIL KeyPressed;
         WHILE KeyPressed DO Key := ReadKey;
         GoToXY (1, WhereY);
         ClrEol;
         ShowDirectoryAndSelectFile := EscapeKey;
         SmallCursor;
         END;
  }
end;

function SimilarCall(Call1: CallString; Call2: CallString): boolean;

{ This function will return true if the two calls only differ in one
    character position.         }

var
  NumberDifferentChars, NumberTestChars, TestChar: integer;
  c1, c2                      : string[1];

begin
  if pos('/', Call1) > 0 then Call1 := RootCall(Call1);
  if pos('/', Call2) > 0 then Call2 := RootCall(Call2);

  SimilarCall := False;

  if Abs(length(Call1) - length(Call2)) > 1 then exit;

  NumberTestChars := length(Call1);
  if (length(Call2) > NumberTestChars) then inc(NumberTestChars);

 { NumberTestChars is equal to length of longest call. }

  NumberDifferentChars := 0;

  for TestChar := NumberTestChars downto 1 do
  begin
    c1 := Copy(Call1, TestChar, 1);
    c2 := Copy(Call2, TestChar, 1);

    if (c1 <> c2) and (c1 <> '?') and (c2 <> '?') then
    begin
      inc(NumberDifferentChars);
      if (NumberDifferentChars) = 2 then Break;
    end;
  end;

  if NumberDifferentChars <= 1 then
  begin
    SimilarCall := true;
    exit;
  end;

 { Let's see if either call shows up in the other - finds I4COM PI4COM }

  if (pos(Call1, Call2) = 0) and (pos(Call2, Call1) = 0) then exit;
  SimilarCall := true;
end;

function StandardCallFormat(Call: CallString; Complete: boolean): CallString;

{ This fucntion will take the call passed to it and put it into a
  standard format with the country indicator as the first part of
  the call.  It is intended to convert calls as they would be sent
  on the air to N6TR duping service perferred format.  This means
  that a callsign as normally sent on the air would be converted to
  a callsign that can be passed to GetCountry, GetContinent, GetZone
  and so on with probable success.

  A change made on 4 November adds the complete flag.  If the flag is
  TRUE, the routine works the way it always has.  If the flag is false,
  the call is unchanged if the call has a single integer after the / sign.
  This is intended to eliminate problems with KC8UNP/6 showing up as
  KC6/KC8UNP which gets reported as the Carolines. }

var
  CallPointer, PrefixPointer, Count: integer;
  FirstPart, SecondPart, TempString: Str80;
  LastTwoLetters, LastThreeLetters, LastFourLetters: string[5];

begin
  if not StringHas(Call, '/') then
  begin
    StandardCallFormat := Call;
    exit;
  end;

  LastTwoLetters := Copy(Call, length(Call) - 1, 2);
  LastThreeLetters := Copy(Call, length(Call) - 2, 3);
  LastFourLetters := Copy(Call, length(Call) - 3, 4);

  if (LastTwoLetters = '/P') or (LastTwoLetters = '/M') or
    (LastTwoLetters = '/N') or (LastTwoLetters = '/T') then
    Delete(Call, length(Call) - 1, 2);

  if (LastThreeLetters = '/AG') or (LastThreeLetters = '/AA') or
    (LastThreeLetters = '/AE') then
    Delete(Call, length(Call) - 2, 3);

  if (LastFourLetters = '/QRP') then
    Delete(Call, length(Call) - 3, 4);

  if not StringHas(Call, '/') then
  begin
    StandardCallFormat := Call;
    exit;
  end;

  FirstPart := PrecedingString(Call, '/');
  SecondPart := PostcedingString(Call, '/');

  if SecondPart = 'MM' then
  begin
    StandardCallFormat := 'MM/' + FirstPart;
    exit;
  end;

  if SecondPart = 'R' then
  begin
    StandardCallFormat := FirstPart + '/' + SecondPart;
    exit;
  end;

  if SecondPart[1] = 'M' then
    if length(SecondPart) = 1 then
    begin
      StandardCallFormat := FirstPart;
      exit;
    end
    else
    begin
      Delete(SecondPart, 1, 1);
      StandardCallFormat := StandardCallFormat(FirstPart + '/' + SecondPart, Complete);
      exit;
    end;

  if length(Call) = 11 then
    if (Copy(Call, 1, 2) = 'VU') and (Copy(Call, 7, 1) = '/') then
      if (Copy(Call, 8, 1) >= '0') and (Copy(Call, 8, 1) <= '9') then
      begin
        StandardCallFormat := Call;
        exit;
      end;

  if length(SecondPart) = 1 then
    if (SecondPart >= '0') and (SecondPart <= '9') then
    begin
      if Complete then
      begin
        TempString := GetPrefix(FirstPart);
        Delete(TempString, length(TempString), 1);
        SecondPart := TempString + SecondPart;
        StandardCallFormat := SecondPart + '/' + FirstPart;
      end
      else
        StandardCallFormat := Call;
      exit;
    end
    else
    begin
      case SecondPart[1] of
        'F': StandardCallFormat := 'F/' + FirstPart;
        'G': StandardCallFormat := 'G/' + FirstPart;
        'I': StandardCallFormat := 'I/' + FirstPart;
        'K': StandardCallFormat := 'K/' + FirstPart;
        'N': StandardCallFormat := 'N/' + FirstPart;
        'W': StandardCallFormat := 'W/' + FirstPart;
      else StandardCallFormat := FirstPart;
      end;
      exit;
    end;

  if length(FirstPart) > length(SecondPart) then
  begin
    StandardCallFormat := SecondPart + '/' + FirstPart;
    exit;
  end;

  if length(FirstPart) < length(SecondPart) then
  begin
    StandardCallFormat := Call;
    exit;
  end;

  if length(FirstPart) = length(SecondPart) then
  begin
    StandardCallFormat := Call;
    exit;
  end;

end;

function StringHas(LongString: Str160; SearchString: Str80): boolean;

{ This function will return TRUE if the SearchString is contained in the
    LongString.                                                                }

begin
  StringHas := pos(SearchString, LongString) <> 0;
end;

function StringHasLowerCase(InputString: Str160): boolean;

var
  CharPos                     : integer;

begin
  for CharPos := 1 to length(InputString) do

    if (InputString[CharPos] <= 'z') and (InputString[CharPos] >= 'a') then
    begin
      StringHasLowerCase := true;
      exit;
    end;

  StringHasLowerCase := False;
end;

function StringHasNumber(Prompt: Str80): boolean;

var
  ChrPtr                      : integer;

begin
  StringHasNumber := False;
  if length(Prompt) = 0 then exit;

  for ChrPtr := 1 to length(Prompt) do
    if (Prompt[ChrPtr] >= '0') and (Prompt[ChrPtr] <= '9') then
    begin
      StringHasNumber := true;
      exit;
    end;
end;

function StringIsAllNumbers(InputString: Str160): boolean;

var
  CharPos                     : integer;

begin
  StringIsAllNumbers := False;
  if InputString = '' then exit;

  for CharPos := 1 to length(InputString) do
    if (InputString[CharPos] < '0') or (InputString[CharPos] > '9') then
      exit;

  StringIsAllNumbers := true;
end;

function StringIsAllNumbersOrSpaces(InputString: Str160): boolean;

var
  CharPos                     : integer;

begin
  StringIsAllNumbersOrSpaces := False;
  if InputString = '' then exit;

  for CharPos := 1 to length(InputString) do
    if (InputString[CharPos] < '0') or (InputString[CharPos] > '9') then
      if InputString[CharPos] <> ' ' then exit;

  StringIsAllNumbersOrSpaces := true;
end;

function StringIsAllNumbersOrDecimal(InputString: Str160): boolean;

var
  CharPos                     : integer;

begin
  StringIsAllNumbersOrDecimal := False;
  if InputString = '' then exit;

  for CharPos := 1 to length(InputString) do
    if (InputString[CharPos] < '0') or (InputString[CharPos] > '9') then
      if InputString[CharPos] <> '.' then exit;

  StringIsAllNumbersOrDecimal := true;
end;

function StringWithFirstWordDeleted(InputString: Str160): Str160;

{ This function performs a wordstar like control-T operation on the
    string passed to it.                                                   }

var
  DeletedChar                 : Char;

begin
  if (InputString = '') or (not StringHas(InputString, ' ')) then
  begin
    StringWithFirstWordDeleted := '';
    exit;
  end;

  repeat
    DeletedChar := InputString[1];
    Delete(InputString, 1, 1);

    if length(InputString) = 0 then
    begin
      StringWithFirstWordDeleted := '';
      exit;
    end;

  until (DeletedChar = ' ') and (InputString[1] <> ' ');
  StringWithFirstWordDeleted := InputString;
end;

function TimeElasped(StartHour, StartMinute, StartSecond, NumberOfMinutes: integer): boolean;

{ This function will compare the present time to the start time given to
  it and decide if the NumberOfMinutes have elasped since the start time.
  It will return TRUE at least the NumberOfMinutes have elasped since
  the start time.                                                          }

var
  Hour, Minute, Second, Sec100: Word;
  ElaspedMinutes              : integer;

begin
 {    GetTime (Hour, Minute, Second, Sec100);
     IF StartHour > Hour THEN Hour := Hour + 24;
 
     IF StartMinute > Minute THEN
         BEGIN
         Minute := Minute + 60;
         Dec (Hour);
         IF StartHour > Hour THEN
           Hour := Hour + 24;
         END;
 
     IF StartSecond > Second THEN
         BEGIN
         Second := Second + 60;
         Dec (Minute);
         IF Minute < 0 THEN
           BEGIN
           Minute := Minute + 60;
           Dec (Hour);
           IF StartHour > Hour THEN
                 Hour := Hour + 24;
           END;
         END;
 
     ElaspedMinutes := (Hour - StartHour) * 60 + (Minute - StartMinute);
     TimeElasped := ElaspedMinutes >= NumberOfMinutes;
    }
end;

procedure TimeStamp(var FileWrite: Text);

begin
  WriteLn(FileWrite, '      This report generated on ', GetDayString,
    ', ', GetDateString, ' at ', GetTimeString, '.');
end;






function UpperCase(const S: string): string;
var
  Ch                          : Char;
  L                           : Integer;
  Source, Dest                : PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then Dec(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;






//  if input = '' then result := '' else
//    result := windows.CharUpper(@Input);

 {    ASM

     CLD
     LEA     SI, Input
     LES     DI, @Result
     SEGSS   LODSB
     STOSB
     XOR     AH, AH
     XCHG    AX, CX
     JCXZ    @3
     @1:
     SEGSS   LODSB
     CMP     AL, 'a'
     JB      @2
     CMP     AL, 'z'
     JA      @2
     SUB     AL, 20H
     @2:
     STOSB
     LOOP    @1
     @3:
     END;
  }


function ValidCallCharacter(CallChar: Char): boolean;

begin
  if (CallChar = '/') or ((CallChar >= '0') and (CallChar <= '9')) or
    ((CallChar >= 'A') and (CallChar <= 'Z')) then
    ValidCallCharacter := true
  else
    ValidCallCharacter := False;
end;

function ValidRST(var Ex: string; var RST: RSTString; Mode: ModeType): boolean;

var
  TempString, RSTString, DefaultRST: Str20;

begin
  ValidRST := False;

  if (Mode = cw) or (Mode = Digital) then
    DefaultRST := '599'
  else
    DefaultRST := '59';

  if length(Ex) = 0 then
  begin
    RST := DefaultRST;
    ValidRST := true;
    exit;
  end;

  GetRidOfPrecedingSpaces(Ex);
  RSTString := '';

  while (Copy(Ex, 1, 1) >= '0') and (Copy(Ex, 1, 1) <= '9') do
  begin
    RSTString := RSTString + Copy(Ex, 1, 1);
    Delete(Ex, 1, 1);
  end;

  case length(RSTString) of
    0:
      begin
        RST := DefaultRST;
        ValidRST := true;
      end;

    1:
      begin
        Delete(DefaultRST, 2, 1);
        Insert(RSTString, DefaultRST, 2);
        RST := DefaultRST;
        ValidRST := true;
      end;

    2: if Mode = Phone then
      begin
        RST := RSTString;
        ValidRST := (RST[1] >= '1') and (RST[1] <= '5');
      end;

    3: if (Mode = cw) or (Mode = Digital) then
      begin
        RST := RSTString;
        ValidRST := (RST[1] >= '1') and (RST[1] <= '5');
      end;
  end;
end;

procedure WaitForKeyPressed;

var
  Key                         : Char;
  OrigMode                    : integer;

begin
 {    OrigMode := LastMode;
     WriteLn;
     TextColor (Cyan);
     Write ('Press any key to continue...');
     REPEAT UNTIL KeyPressed;
     Key := ReadKey;
     GoToXY (1, WhereY);
     ClrEol;
     TextMode(OrigMode);
    }
end;

procedure WriteColor(Prompt: Str80; FColor: integer; BColor: integer);

begin
 {    TextColor (FColor);
     TextBackground (BColor);
     Write (Prompt);
    }
end;

procedure WriteLnCenter(Prompt: Str80);

var
  ScreenWidth, CenterSpaces   : integer;

begin
 {    ScreenWidth := Lo (WindMax);
 
     CenterSpaces := (ScreenWidth DIV 2) - (Length (Prompt) DIV 2);
     IF CenterSpaces > 0 THEN GoToXY (CenterSpaces, WhereY);
     WriteLn (Prompt);
    }
end;

procedure WriteLnVarCenter(var FileWrite: Text; Prompt: Str80);

var
  Space, CenterSpaces         : integer;

begin
  CenterSpaces := 40 - (length(Prompt) div 2);

  if CenterSpaces > 0 then for Space := 1 to CenterSpaces do
      Prompt := ' ' + Prompt;

  WriteLn(FileWrite, Prompt);
end;

procedure WriteLnLstCenter(Prompt: Str80);

var
  Space, CenterSpaces         : integer;

begin
 {    CenterSpaces := 40 - (Length (Prompt) DIV 2);
     IF CenterSpaces > 0 THEN FOR Space := 1 TO CenterSpaces DO Write (Lst, ' ');
     WriteLn (Lst, Prompt);
    }
end;

procedure WriteHexByte(HexByte: BYTE);

begin
  Write(HexChars[Lo(HexByte) shr 4], HexChars[Lo(HexByte) and $F]);
end;

procedure WriteHexWord(HexWord: Word);

begin
  Write(HexChars[Hi(HexWord) shr 4], HexChars[Hi(HexWord) and $F],
    HexChars[Lo(HexWord) shr 4], HexChars[Lo(HexWord) and $F]);
end;

procedure WritePortType(port: PortType);

begin
  case port of
    NoPort: Write('None');
    Serial1: Write('COM1');
    Serial2: Write('COM2');
    Serial3: Write('COM3');
    Serial4: Write('COM4');
    Serial5: Write('COM5');
    Serial6: Write('COM6');

    Parallel1: Write('LPT1');
    Parallel2: Write('LPT2');
    Parallel3: Write('LPT3');
  end;
end;

function CheckMouse(var XPos: integer;
  var YPos: integer;
  var Button1: boolean;
  var Button2: boolean): boolean;

//{WLI}VAR Regs: Registers;

begin
 {    Regs.AX := $B;
     Intr ($33, Regs);
 
     Xpos:= Integer (Regs.CX);
     Ypos:= Integer (Regs.DX);
 
     Regs.AX := 5;
     Intr ($33, Regs);
     Button1 := (Regs.AX AND 1) = 1;
     Button2 := (Regs.AX AND 2) = 2;
 
     CheckMouse := (Xpos <> 0) OR (YPos <> 0) OR Button1 OR Button2;
    }
end;

procedure MouseInit;

var //{WLI}Regs: Registers;
  CH                          : Char;

begin
 {    Regs.AX := 0;
     Intr ($33, Regs);
 
     IF Regs.AH = $FF THEN
         BEGIN
         CASE Regs.BL OF
             2: MouseType := TwoButton;
             0: MouseType := OneButton;
             3: MouseType := ThreeButton;
             ELSE MouseType := OneButton;
             END;
         END
     ELSE
         MouseType := NoMouse;
  }
end;

procedure CharacterBuffer.InitializeBuffer;

begin
  Tail := 0;
  Head := 0;

  if List = nil then
    New(List)
  else
    SendMorse('OOPS');
end;

function CharacterBuffer.FreeSpace: integer;

begin
  if Head < Tail then
    FreeSpace := Tail - Head - 1
  else
    FreeSpace := BufferLength - (Head - Tail) - 1;
end;



procedure CharacterBuffer.ClearBuffer;

begin
  Tail := 0;
  Head := 0;

end;








procedure CharacterBuffer.GoAway;

begin
  if List <> nil then
    Dispose(List);

  List := nil;
end;

function CharacterBuffer.IsEmpty;

begin
  IsEmpty := (Head = Tail) or (List = nil);
end;

procedure CharacterBuffer.AddEntry(Entry: BYTE);

begin
  List^[Head] := Entry;
  Head := (Head + 1) mod BufferLength;

  if Tail = Head then
    Tail := (Tail + 1) mod BufferLength;
end;



procedure CharacterBuffer.AddString(Entry: string);

var
  Index                       : integer;

begin
   {  if Length(Entry) > 0 then
     begin
       for Index := 1 to Length(Entry) do
       begin
         List^[Head] := Ord(Entry[Index]);
         Head := (Head + 1) mod BufferLength;
       end;

       if Tail = Head then
         Tail := (Tail + 1) mod BufferLength;
     end;
   }
end;










function CharacterBuffer.GetNextByte(var Entry: BYTE): boolean;

{ Returns TRUE if a byte was there to get }

begin
  if Tail <> Head then
  begin
    Entry := List^[Tail];
    Tail := (Tail + 1) mod BufferLength;
    GetNextByte := true;
  end
  else
    GetNextByte := False;
end;

function CharacterBuffer.GetNextLine(var Entry: string): boolean;

var
  TestTail                    : integer;

begin
 {    GetNextLine := False;
 
     IF Tail = Head THEN Exit;     { Nothing to look at }

 {    TestTail := Tail;
 
     WHILE List^ [TestTail] <> Ord (CarriageReturn) DO
         BEGIN
         TestTail := (TestTail + 1) MOD BufferLength;
 
         IF TestTail = Head THEN Exit;  { We have gone beyond my data }
 {        END;
 
     { We have found a carriage return at TestTail.  We aren't going to
       copy the carriage return, so back up one count. }

 {    TestTail := TestTail - 1;
     IF TestTail < 0 THEN TestTail := BufferLength - 1;
 
     { Copy the string }

 {    Entry := '';
 
     IF TestTail > Tail THEN   { Can use monotonic addressing }
 {        BEGIN
         IF TestTail - Tail < 255 THEN
             BEGIN
             Entry [0] := Chr (TestTail - Tail);
             Move (List^ [Tail], Entry [1], TestTail - Tail);
             END;
         END
     ELSE
         IF BufferLength - Tail + TestTail < 255 THEN
             BEGIN
             Entry [0] := Chr (BufferLength - Tail + TestTail);
             Move (List^ [Tail], Entry [1], BufferLength - Tail);
             Move (List^ [0], Entry [BufferLength - Tail + 1], Length (Entry) - BufferLength + Tail);
             END;
 
     { Tell the guy calling me that we have something for him to look at }

 {    GetNextLine := True;
 
     Tail := TestTail;   { This was missing in get slipeed string! }

 {    WHILE ((List^ [Tail] = Ord (CarriageReturn)) OR (List^ [Tail] = Ord (LineFeed))) DO
         BEGIN
         Tail := (Tail + 1) MOD BufferLength;
         IF Tail = Head THEN Exit;
         END;
    }
end;

function CharacterBuffer.GetSlippedString(var Entry: string): boolean;

{ Returns TRUE if a complete slipped string is found with it as parameter.
  It will always leave a FrameEnd at the tail. }

var
  LengthOfString, CharPointer, RemainingBytes, HeadAtStart, TestTail: integer;

begin
 {    HeadAtStart := Head;
 
     GetSlippedString := False;
 
     { If the tail isn't pointing to a FrameEnd, delete characters until
       one it found, or there aren't any more characters }

 {    WHILE (List^ [Tail] <> FrameEnd) AND (Tail <> HeadAtStart) DO
         Tail := (Tail + 1) MOD BufferLength;
 
     IF Tail = HeadAtStart THEN Exit;
 
     { We have a FrameEnd at the tail.  Now look for consecutive ones to
       ignore. }

 {    TestTail := (Tail + 1) MOD BufferLength;
 
     IF TestTail = HeadAtStart THEN Exit;  { Not any characters after 1st FrameEnd }

 {    REPEAT
         IF List^ [TestTail] = FrameEnd THEN
             Tail := (Tail + 1) MOD BufferLength;  { Move real tail up one }

 {        TestTail := (Tail + 1) MOD BufferLength;
 
         IF TestTail = HeadAtStart THEN Exit;  { No chars after 1st FrameEnd }
 {    UNTIL List^ [TestTail] <> FrameEnd;
 
     { We have Tail = FrameEnd and Tail + 1 <> FrameEnd.  Now see if there
       is a frame end somewhere else - like at the end of a message? }

 {    REPEAT
         TestTail := (TestTail + 1) MOD BufferLength;
     UNTIL (List^ [TestTail] = FrameEnd) OR (TestTail = HeadAtStart);
 
     IF TestTail = HeadAtStart THEN Exit;  { Nothing yet }

     { There is another FrameEnd with data before it.  It is at TestTail. }
     { Increment the tail over the FrameEnd (which we want to ignore.}

 {    Tail := (Tail + 1) MOD BufferLength; { Skip over first FrameEnd }

 {    IF Tail = HeadAtStart THEN Exit;            { This would be weird }

     { Now copy the data into Entry }

 {    Entry := '';
 
     IF TestTail > Tail THEN   { Can use monotonic addressing  }
 {        BEGIN
         IF (TestTail - Tail) < 255 THEN   { Check for too long }
 {            BEGIN
             Entry [0] := Chr (TestTail - Tail);
             Move (List^ [Tail], Entry [1], TestTail - Tail);
             END
         ELSE
             QuickBeep;
         END
     ELSE
         BEGIN
         LengthOfString := BufferLength - Tail + TestTail;
 
         IF LengthOfString < 255 THEN
             BEGIN
             Entry [0] := Chr (LengthOfString);
 
             Move (List^ [Tail], Entry [1], BufferLength - Tail);
 
             RemainingBytes := LengthOfString - (BufferLength - Tail);
 
             { Runtime 201 error on next instruction  273b:94ca or 2736:949b
               or 2742:950a  }

 {            Move (List^ [0], Entry [BufferLength - Tail + 1], RemainingBytes);
             END
         ELSE
             QuickBeep;
   END;
 
 {   Entry := '';
 
     WHILE Tail <> TestTail DO
         BEGIN
         IF Length (Entry) < SizeOf (Entry) - 2 THEN
             Entry := Entry + Chr (List^ [Tail]);
         Tail := (Tail + 1) MOD BufferLength;
         END;                                                   }

 {    Tail := TestTail;          { Missing from < 6.25 }

     { Now look for any Frame Escapes }

 {    FOR CharPointer := 1 TO Length (Entry) DO
         IF Entry [CharPointer] = FrameEscapeChr THEN
             BEGIN
             Delete (Entry, CharPointer, 1);
 
             IF Entry [CharPointer] = TransposedFrameEndChr THEN
                 Entry [CharPointer] := FrameEndChr
             ELSE
                 IF Entry [CharPointer] = TransposedFrameEscapeChr THEN
                     Entry [CharPointer] := FrameEscapeChr;
             END;
 
     GetSlippedString := True;
    }
end;

function CallFoundInFile(Callsign: CallString; FileName: Str40): boolean;
{
var
  FileRead: file;
  DirInfo: TSearchRec;
  MatchStartAddress, BytesInBuffer, Address: integer;
  Match: boolean;
}
begin
 {    CallFoundInFile := False;
 
     Assign  (FileRead, FileName);
     Reset   (FileRead, 1);
 
     Match := False;
 
     New (CBuffer);
 
     WHILE NOT Eof (FileRead) DO
         BEGIN
         BlockRead (FileRead, CBuffer, SizeOf (CBuffer), BytesInBuffer);
 
         IF BytesInBuffer > 0 THEN
             FOR Address := 0 TO BytesInBuffer - 1 DO
                 BEGIN
                 IF Match THEN
                     BEGIN
                     IF (CBuffer^ [Address] = CallSign [(Address - MatchStartAddress) + 1]) THEN
                         BEGIN
                         IF ((Address - MatchStartAddress) + 1) = (Length (CallSign)) THEN
                             BEGIN
                             CallFoundInFile := True;
                             Close (FileRead);
                             Dispose (CBuffer);
                             Exit;
                             END;
                         END
                     ELSE
                         BEGIN
                         Address := MatchStartAddress + 1;
                         Match := CBuffer^ [Address] = CallSign [1];
                         IF Match THEN MatchStartAddress := Address;
                         END;
                     END
                 ELSE
                     IF CBuffer^ [Address] = CallSign [1] THEN
                         BEGIN
                         Match := True;
                         MatchStartAddress := Address;
                         END;
                 END;
 
         MatchStartAddress := MatchStartAddress - BytesInBuffer;
         END;
 
     Close (FileRead);
     Dispose (CBuffer);
    }
end;

procedure IncrementMonth(var DateString: Str20);

{ This procedure will increment the month of the date string to the next
  month and set the day to 1.  If it is in December, the year will also
  be incremented. }

var
  MonthString, YearString     : Str20;
  Year, Result                : integer;

begin
  MonthString := UpperCase(BracketedString(DateString, '-', '-'));

  YearString := Copy(DateString, length(DateString) - 1, 2);
  Val(YearString, Year, Result);

  if MonthString = 'JAN' then
    DateString := '1-FEB-' + YearString;

  if MonthString = 'FEB' then
    DateString := '1-MAR-' + YearString;

  if MonthString = 'MAR' then
    DateString := '1-APR-' + YearString;

  if MonthString = 'APR' then
    DateString := '1-MAY-' + YearString;

  if MonthString = 'MAY' then
    DateString := '1-JUN-' + YearString;

  if MonthString = 'JUN' then
    DateString := '1-JUL-' + YearString;

  if MonthString = 'JUL' then
    DateString := '1-AUG-' + YearString;

  if MonthString = 'AUG' then
    DateString := '1-SEP-' + YearString;

  if MonthString = 'SEP' then
    DateString := '1-OCT-' + YearString;

  if MonthString = 'OCT' then
    DateString := '1-NOV-' + YearString;

  if MonthString = 'NOV' then
    DateString := '1-DEC-' + YearString;

  if MonthString = 'DEC' then
  begin
    inc(Year);
    if Year > 99 then Year := 0;

    Str(Year, YearString);

    while length(YearString) < 2 do
      YearString := '0' + YearString;

    DateString := '1-JAN-' + YearString;
  end;
end;

procedure IncrementMinute(var DateString: Str20; var TimeString: Str80);

{ This procedure will add a day to the DateString passed to it.  The
  string is in the format dd-mon-yr.  It will handle month ends and
  increment the year correctly (including leap years). }

var
  Day, Hour, Minute, Year, Result: integer;
  MinuteString, HourString, DayString, MonthString, YearString: Str20;

begin
  Val(PostcedingString(TimeString, ':'), Minute, Result);
  Val(PrecedingString(TimeString, ':'), Hour, Result);

  inc(Minute);

  if Minute > 59 then
  begin
    Minute := 0;
    inc(Hour);

    if Hour > 23 then
    begin
      Hour := 0;

      Val(PrecedingString(DateString, '-'), Day, Result);
      inc(Day);
      Str(Day, DayString);

      while length(DayString) < 2 do
        DayString := '0' + DayString;

      Delete(DateString, 1, pos('-', DateString) - 1);
      Insert(DayString, DateString, 1);

     { Now check for new month }

      if Day > 28 then { All months have at least 28 days }
      begin
        MonthString := UpperCase(BracketedString(DateString, '-', '-'));

        if (MonthString = 'JAN') or (MonthString = 'MAR') or
          (MonthString = 'MAY') or (MonthString = 'JUL') or
          (MonthString = 'AUG') or (MonthString = 'OCT') or
          (MonthString = 'DEC') then
          if Day > 31 then IncrementMonth(DateString);

        if MonthString = 'FEB' then
        begin
          YearString := Copy(DateString, length(DateString) - 1, 2);
          Val(YearString, Year, Result);

          if (Year mod 4 = 0) and (Year <> 0) then { Leap year }
          begin
            if Day > 29 then IncrementMonth(DateString);
          end
          else
            if Day > 28 then IncrementMonth(DateString);

        end;

        if (MonthString = 'APR') or (MonthString = 'JUN') or
          (MonthString = 'SEP') or (MonthString = 'NOV') then
          if Day > 30 then IncrementMonth(DateString);

      end;
    end;

  end;

  Str(Minute, MinuteString);

  while length(MinuteString) < 2 do
    MinuteString := '0' + MinuteString;

  Str(Hour, HourString);

  while length(HourString) < 2 do
    HourString := '0' + HourString;

  TimeString := HourString + ':' + MinuteString;
end;

function SameMinute(PreviousDateString: Str20; DateString: Str20;
  PreviousTimeString: Str20; TimeString: Str20): boolean;

begin
  SameMinute := (PreviousDateString = DateString) and (PreviousTimeString = TimeString);
end;

function NextMinute(PreviousDateString: Str20; DateString: Str20;
  PreviousTimeString: Str20; TimeString: Str20): boolean;

begin
 //{WLI}    IncrementMinute (PreviousDateString, PreviousTimeString);
 //{WLI}    NextMinute := SameMinute (PreviousDateString, DateString, PreviousTimeString, TimeString);
end;

function NewKeyPressed: boolean;

begin
 //{WLI}    NewKeyPressed := Mem [$40:$1A] <> Mem [$40:$1C];
end;

function NewReadKey: Char;

var
  MemByte                     : BYTE;
  Address                     : BYTE;

begin
 {    Address := Mem [$40:$1A];
 
     IF ExtendedKey <> 0 THEN
         BEGIN
         NewReadKey := Chr (ExtendedKey);
         Address := Address + 2;
         IF Address > $3C THEN Address := $1E;
         Mem [$40:$1A] := Address;
         ExtendedKey := 0;
         Exit;
         END;
 
     REPEAT UNTIL NewKeyPressed;
 
     MemByte := Mem [$40:Address];
 
     IF (MemByte = 0) OR (MemByte = $E0) THEN
         BEGIN
         NewReadKey := Chr (0);
         ExtendedKey := Mem [$40:Address + 1];
         Exit;
         END
     ELSE
         BEGIN
         IF Chr (MemByte) = QuestionMarkChar THEN
             NewReadKey := '?'
         ELSE
             IF Chr (MemByte) = SlashMarkChar THEN
                 NewReadKey := '/'
             ELSE
                 NewReadKey := Chr (MemByte);
 
         Address := Address + 2;
         IF Address > $3C THEN Address := $1E;
         Mem [$40:$1A] := Address;
         END;
    }
end;

function Tan(X: REAL): REAL;

begin
  if Cos(X) = 0 then
  begin
    Tan := 1000000000;
    exit;
  end;

  Tan := Sin(X) / Cos(X);
end;

function ArcCos(X: REAL): REAL;

begin
  if X = 1 then
  begin
    ArcCos := 0;
    exit;
  end
  else
    if X = -1 then
    begin
      ArcCos := Pi / 2;
      exit;
    end;

  ArcCos := (Pi / 2) - ArcTan(X / Sqrt(1 - X * X));
end;

function ATan2(Y, X: REAL): REAL;

{ Returns ArcTan in the rnge 0.. 2Pi.  Input is X and Y points. }

begin
  if X < 0 then
    ATan2 := Pi + ArcTan(Y / X) { Left two quadrants - sign works }
  else
    if X = 0 then { Either up or down the Y axis }
    begin
      if Y < 0 then { Pointing down the Y axis }
        ATan2 := 1.5 * Pi
      else
        if Y = 0 then
          ATan2 := 0.0 { Nicer than blowing up }
        else
          ATan2 := 0.5 * Pi; { Pointing up the Y axis }
    end
    else
      if Y < 0 then
        ATan2 := 2.0 * Pi + ArcTan(Y / X) { Lower right Quadrant }
      else
        ATan2 := ArcTan(Y / X); { Upper right Quadrant }

end; {Atan2}

function GoodLookingGrid(Grid: Str20): boolean;

{ Verifies that the grid square is legitimate }

var
  CharPosition                : integer;

begin
  GoodLookingGrid := False;

  if not ((length(Grid) = 4) or (length(Grid) = 6)) then exit;

  Grid := UpperCase(Grid);

  for CharPosition := 1 to length(Grid) do
    case CharPosition of
      1, 2, 5, 6:
        if (Grid[CharPosition] < 'A') or (Grid[CharPosition] > 'Z') then
          exit;

      3, 4:
        if (Grid[CharPosition] < '0') or (Grid[CharPosition] > '9') then
          exit;
    end;

  GoodLookingGrid := true;
end;

function GetSCPIntegerFromChar(InputChar: Char): integer;

begin
  GetSCPIntegerFromChar := -1;

  if (InputChar >= 'A') and (InputChar <= 'Z') then
  begin
    GetSCPIntegerFromChar := Ord(InputChar) - Ord('A');
    exit;
  end;

  if (InputChar >= '0') and (InputChar <= '9') then
  begin
    GetSCPIntegerFromChar := Ord(InputChar) - Ord('0') + 26;
    exit;
  end;

  if InputChar = '/' then GetSCPIntegerFromChar := 36;
end;

function GetSCPCharFromInteger(Index: integer): Char;

begin
  if Index <= 25 then
    GetSCPCharFromInteger := CHR(Ord('A') + Index)
  else
    if Index <= 35 then
      GetSCPCharFromInteger := CHR(Ord('0') + (Index - 26))
    else
      if Index = 36 then
        GetSCPCharFromInteger := '/'
      else
        GetSCPCharFromInteger := CHR(0);
end;

function PartialCall(Pattern: CallString; Call: CallString): boolean;

label
  NotAPartialCallHere;

var
  CharPos, ComparePos         : integer;

begin
  if pos(Pattern, Call) > 0 then
  begin
    PartialCall := true;
    exit;
  end;

  if pos('?', Pattern) = 0 then
  begin
    PartialCall := False;
    exit;
  end;

  for CharPos := 1 to length(Call) - length(Pattern) + 1 do
  begin
    if (Call[CharPos] = Pattern[1]) or (Pattern[1] = '?') then
    begin
      for ComparePos := 2 to length(Pattern) do
        if (Call[CharPos + ComparePos - 1] <> Pattern[ComparePos]) and (Pattern[ComparePos] <> '?') then
          goto NotAPartialCallHere;

     { We have a match! }

      PartialCall := true;
      exit;
    end;

    NotAPartialCallHere:

  end;

  PartialCall := False;
end;

function CSV(Letter: CallString): integer;

{ Computers character sort value for CallSortValue routine }

begin
  if Letter = '' then
  begin
    CSV := 0;
    exit;
  end;

  if Letter = '/' then
  begin
    CSV := 1;
    exit;
  end;

  if (Letter >= '0') and (Letter <= '9') then
  begin
    CSV := Ord(Letter[1]) - Ord('0') + 1;
    exit;
  end;

  if (Letter >= 'A') and (Letter <= 'Z') then
  begin
    CSV := Ord(Letter[1]) - Ord('A') + 11;
    exit;
  end;
end;

function CallSortValue(Call: CallString): LONGINT;

{ Processes /, 0-9 and A-Z for the first 6 letters }

var
  CharPos                     : integer;
  Total                       : REAL;

begin
  Total := 0;

  if Call = '' then
  begin
    CallSortValue := 0;
    exit;
  end;

  for CharPos := 1 to 6 do
    Total := CSV(Copy(Call, CharPos, 1)) + (Total * 37);

  CallSortValue := round(Total - 2147483648.0);
end;

function GetStateFromSection(Section: Str20): Str20;

begin
  Section := UpperCase(Section);

  if (Section = 'AK') or (Section = 'AL') or (Section = 'AR') or
    (Section = 'AZ') or (Section = 'CO') or (Section = 'CT') or
    (Section = 'DE') or (Section = 'GA') or (Section = 'IA') or
    (Section = 'ID') or (Section = 'IN') or (Section = 'IL') or
    (Section = 'KS') or (Section = 'KY') or (Section = 'LA') or
    (Section = 'ME') or (Section = 'MI') or (Section = 'MN') or
    (Section = 'MO') or (Section = 'MS') or (Section = 'MT') or
    (Section = 'NC') or (Section = 'ND') or (Section = 'NE') or
    (Section = 'NH') or (Section = 'NM') or (Section = 'NV') or
    (Section = 'OH') or (Section = 'OK') or (Section = 'OR') or

  (Section = 'RI') or (Section = 'SD') or (Section = 'TN') or
    (Section = 'UT') or (Section = 'VA') or (Section = 'VT') or
    (Section = 'WI') or (Section = 'WV') or (Section = 'WY') or
    (Section = 'SC') then
  begin
    GetStateFromSection := Section;
    exit;
  end;

  if (Section = 'EB') or (Section = 'LAX') or (Section = 'ORG') or
    (Section = 'SB') or (Section = 'SCV') or (Section = 'SDG') or
    (Section = 'SF') or (Section = 'SJV') or (Section = 'SV') then
  begin
    GetStateFromSection := 'CA';
    exit;
  end;

  if (Section = 'EM') or (Section = 'WM') then
  begin
    GetStateFromSection := 'MA';
    exit;
  end;

  if (Section = 'EN') or (Section = 'WNY') or (Section = 'NNY') or
    (Section = 'ENY') or (Section = 'NLI') then
  begin
    GetStateFromSection := 'NY';
    exit;
  end;

  if (Section = 'EP') or (Section = 'WP') then
  begin
    GetStateFromSection := 'PA';
    exit;
  end;

  if (Section = 'EW') or (Section = 'WWA') or (Section = 'EWA') then
  begin
    GetStateFromSection := 'WA';
    exit;
  end;

  if (Section = 'NF') or (Section = 'SF') then
  begin
    GetStateFromSection := 'FL';
    exit;
  end;

  if (Section = 'NNJ') or (Section = 'SNJ') then
  begin
    GetStateFromSection := 'NJ';
    exit;
  end;

  if (Section = 'NTX') or (Section = 'STX') or (Section = 'WTX') then
  begin
    GetStateFromSection := 'TX';
    exit;
  end;

  GetStateFromSection := '';
end;

function GetDiskStatus(Drive: BYTE): integer;

//{WLI}VAR Regs: Registers;

begin
 {    Regs.AX := $0100;
     Regs.DL := Drive;
     Intr ($13, Regs);
     GetDiskStatus := Regs.AL;
    }
end;

function ReadSectors(NumberSectors: BYTE; Cylinder: Word;
  Sector: BYTE; Head: BYTE;
  Drive: BYTE; Seg, Ofs: Word): integer;

{ Sector is 1 based, everything else is zero }

//{WLI}VAR Regs: Registers;

begin
 {    Regs.AH := $02;
     Regs.AL := NumberSectors;
     Regs.CH := Lo (Cylinder);
 
   { Put the ninth and tenth bits of the cylinder in the top two bits of CL }

 {    Regs.CL := Hi (Cylinder);
 
     Regs.CL := Regs.CL Shl 6;
     Regs.CL := Regs.CL OR Sector;

     Regs.DH := Head;
     Regs.DL := Drive;

     Regs.ES := Seg;
     Regs.BX := Ofs;

     Intr ($13, Regs);

     IF (Regs.Flags AND $01) <> 0 THEN      { Carry set }
 {        ReadSectors := Ord (Regs.AH)
     ELSE
         ReadSectors := 0;                  { It worked }
end;







function OpenLPT(ISRadio1: boolean; LPT: PortType): boolean;
var
  Addr                        : integer;
begin
  Addr := 0;
  TR4WLpt := TLptPortConnection.Create;
  if not TR4WLpt.Ready then
  begin
    ShowMessage('Can`t open LPT');
    halt;
  end;

  try

    case LPT of
      Parallel1: Addr := 32 {lpt1};
         //      Parallel12: addr := 888;
         //      Parallel13: addr := 888;

    end;
    if ISRadio1 = true then
    begin
      Radio1.Keyer_Handle := Addr;
            //      frm.LPT_1.OpenDriver;
    end
    else
    begin
      Radio2.Keyer_Handle := Addr;
            //      frm.LPT_1.OpenDriver;
    end;
    Result := true;

  except Result := False;
  end;
end;

procedure PTTOn;
var
  I                           : integer;
begin
  if not PTTEnable then Exit;
  if ActiveRadio = radioone then
  begin
    if Radio1.SerialKeyerNotParallel then
      EscapeCommFunction(Radio1.Port_Handle, SETRTS)
    else
    begin
      TR4WLpt.WritePort(Radio1.Keyer_Handle, 2, (TR4WLpt.ReadPort((Radio1.Keyer_Handle), 2) or 5));
               //      TR4WLpt.WritePort(RADIO1.Keyer_Handle, 2, (TR4WLpt.ReadPort((RADIO1.Keyer_Handle), 2) Or 1));
               //      TR4WLpt.WritePort(RADIO1.Keyer_Handle, 2, (TR4WLpt.ReadPort((RADIO1.Keyer_Handle), 2) Or 4));

    end;
  end;
  Delay(PTTTurnOnDelay);
  Frm.PTT.Enabled := true;
  Frm.PTT.Color := $800000 {clNavy};
end;

procedure PTTOff;
var
  I                           : integer;
begin
  if not PTTEnable then Exit;
  if ActiveRadio = radioone then
  begin
    if Radio1.SerialKeyerNotParallel
      then
    begin
      EscapeCommFunction(Radio1.Port_Handle, CLRRTS); //ptt
      EscapeCommFunction(Radio1.Port_Handle, CLRDTR); //cw
    end
    else
      TR4WLpt.WritePort(Radio1.Keyer_Handle, 2, (TR4WLpt.ReadPort((Radio1.Keyer_Handle), 2) and 251));
  end;
  Frm.PTT.Color := $8000000F { clbtnface};
  Frm.PTT.Enabled := False;

end;





procedure QuickBeep;

begin
  SpeakerBeep(1000, 300);
end;



function ReadFromSerialPort(port: integer; BytesToRead: Cardinal): string;
var
  d                           : array[1..250] of Char;
  BytesRead                   : Cardinal;
  I                           : BYTE;
begin
  ReadFile(port, d, BytesToRead {SizeOf(d)}, BytesRead, nil);
  Result := '';
  for I := 1 to BytesRead do Result := Result + d[I];
end;

function WriteToSerialPort(data: string; port: integer): Cardinal;
begin
  WriteFile(port, data[1], length(data), Result, nil);
end;













function GetFileSize_TR(FileName: Str80): LONGINT;

var
  FileRead                    : file of BYTE;

begin
  Assign(FileRead, FileName);
  Reset(FileRead);
  GetFileSize_TR := FileSize(FileRead);
  Close(FileRead);
end;



function GetOblast(Call: CallString): Str20;

begin
  Call := StandardCallFormat(Call, False);

  if StringHas(Call, '/') then Call := PrecedingString(Call, '/');

  while Copy(Call, 1, 1) >= 'A' do
  begin
    Delete(Call, 1, 1);

    if Call = '' then
    begin
      GetOblast := '';
      Exit;
    end;
  end;

  GetOblast := Copy(Call, 1, 2);
end;







function InitializeSerialPort(SerialPort: PortType;
  BaudRate: Word;
  Bits: integer;
  Parity: ParityType;
  StopBits: integer): integer;
var
  DCB                         : TDCB;
  CommTimeouts                : TCommTimeouts;
  com_port_name               : BYTE; //WLI
   // DeviceName: array[0..10] of Char;
  Parity_byte                 : BYTE;
  s                           : string;
begin

  Result := -1;

  case SerialPort of
    Serial1: com_port_name := 1;
    Serial2: com_port_name := 2;
    Serial3: com_port_name := 3;
    Serial4: com_port_name := 4;
    Serial5: com_port_name := 5;
    Serial6: com_port_name := 6;
  else Exit;
  end;

   // StrPCopy(DeviceName, com_port_name);

  ComFile :=
    CreateFile(
    PChar('\\.\COM' + inttostr(com_port_name)),
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0);

  if ComFile = INVALID_HANDLE_VALUE then
  begin
    s := 'COM' + inttostr(com_port_name) + #13 + 'INVALID_HANDLE_VALUE';
    MessageBox(frm.Handle, pchar(s), 'TR4W', MB_OK or MB_ICONWARNING);

    Exit;
  end;
  Result := ComFile;

  if not SetupComm(ComFile, 256 {RxBufferSize}, 256 {TxBufferSize}) then Exit;

   {-------DCB--------}
  if not GetCommState(ComFile, DCB) then Exit;

  if Parity = NoParity then Parity_byte := 0;
  if Parity = EvenParity then Parity_byte := 1;
  if Parity = OddParity then Parity_byte := 2;

  DCB.Parity := Parity_byte;
  DCB.BaudRate := BaudRate;
  DCB.ByteSize := Bits;
  DCB.StopBits := StopBits;
   {43210987654321}
  DCB.Flags := {12289} BinToDec('00000000010001');
   {11000000010001-def}
  if not SetCommState(ComFile, DCB) then Exit;
   {-------DCB--------}

  EscapeCommFunction(ComFile, CLRDTR); //CW
  EscapeCommFunction(ComFile, CLRRTS); //PTT

  if not GetCommTimeouts(ComFile, CommTimeouts) then Exit;
  with CommTimeouts do
  begin

         //showmessage(inttostr(WriteTotalTimeoutConstant));
    ReadIntervalTimeout := {maxdword} 0;
    ReadTotalTimeoutMultiplier := 0;
    ReadTotalTimeoutConstant := 0;

    WriteTotalTimeoutMultiplier := 20;
    WriteTotalTimeoutConstant := 0;
  end;

  if not SetCommTimeouts(ComFile, CommTimeouts) then Exit;

end;







function BinToDec(b: string): integer;
var
  I, temp, pow                : Word; {значит так, здесь - счетчик, разряд (он будет выделяться
   из двоичной строки) и степень двойки}
  res                         : integer; {ну а это результат, как и в предыдущей функции}
begin
  res := 0; {начальное значение результата}
  pow := 0; {степень двойки при первом разряде - нулевая}
  for I := length(b) downto 1 do {выделяем последовательно все разряды...}
  begin
    temp := strtoint(b[I]); {...}
    res := res + temp * power(2, pow); {...и рассчитываем результат}
    pow := pow + 1; {степень двойки увеличим, т.к. номер разряда увеличивается}
  end;
  BinToDec := res; {опять-таки присваиваем функции значение результата}
end;
{------------------------------------------------------------------------------}

function power(a, b: integer): integer;
var
  I                           : integer; {это у нас будет счетчиком цикла}
  res                         : integer; {а это - промежуточный результат}
begin
  res := 1; {ведь есть истина - любое число в нулевой степени равно единице!}
  for I := 1 to b do res := res * a; {вот и возведение в степень}
  power := res; {осталось лишь присвоить функции значение результата}
  if a = 0 then power := 0; {любая степень нуля будет равна нулю}
end;
{------------------------------------------------------------------------------}








function GetDriveParameters(Drive: BYTE; var DriveType: BYTE;
  var MaxCylinder: Word; var MaxSector: BYTE;
  var MaxHead: BYTE; var NumberDrives: BYTE): integer;











//{WLI}VAR Regs: Registers;

begin
 {    Regs.AH := $08;
     Regs.DL := Drive;
     Intr ($13, Regs);
     DriveType := Regs.BL;

     MaxCylinder := Regs.CL AND $C0;
     MaxCylinder := MaxCylinder Shr 8;
     MaxCylinder := MaxCylinder OR Regs.CH;

     MaxSector := Regs.CL AND $1F;
     MaxHead   := Regs.DH;
     NumberDrives := Regs.DL;

     IF (Regs.Flags AND $01) <> 0 THEN             { Carry set }
 //{WLI}        GetDriveParameters := Ord (Regs.AH)
 //{WLI}    ELSE
 //{WLI}        GetDriveParameters := 0;                  { It worked }
end;

{    BEGIN
    ExtendedKey := 0;
    Com5PortBaseAddress := 0;
    Com6PortBaseAddress := 0;

    Beat := 500;
    SetMorseSpeed (36, 700);
    HourOffset := 0;
    MouseInit;
    FMMode := False;

    QuestionMarkChar := '?';
    SlashMarkChar    := '/';
   }
end.

