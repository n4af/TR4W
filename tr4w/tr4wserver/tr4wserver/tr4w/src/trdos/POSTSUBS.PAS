unit PostSubs;

{$F+}
{$O+}

interface

uses //Crt,
  Tree, {  444 bytes }
     //SlowTree,
  LogDupe, { 3516 bytes }
  LogWind, { 4842 bytes }
  Country9, { 1454 bytes }
  ZoneCont, {    4 bytes }
  LogDom, {  298 bytes }
  FContest,
  Dialogs,
  SysUtils,
  WINDOWS;
//  PostUnit,
//  ViewUnit,
//  DetMultUnit {,treepas}; {    0 bytes }

const

  PostVersion       = '6.80';

  MaxLogFilesOpen   = 24;

  TempFileName      = 'TR$TR$TR.TMP';

  CallWidth         = 12;
  MaximumCalls      = 65536 div (CallWidth + 1) - 1;

  Columns           = 6;
  PrinterColumns    = 80;

  QSLLabelBlockSize = 500;
  MaxNumberBlocks   = 10;
  MaxQSLLabelAddress = QSLLabelBlockSize * MaxNumberBlocks;

  QSLTempFileName   = 'POSTQSL.TMP';

  DoubleStrike      = CHR(0);
  NormalStrike      = CHR(0);
  Expand            = CHR(0);
  Norm              = CHR(0);

  ArrayIndex        = CallWidth + 1;
  MaximumListCalls  = 65536 div ArrayIndex - 1;

type
  CallArray = array[0..MaximumCalls] of string[CallWidth];
  CallArrayPtr = ^CallArray;

  CallPointerArray = array[0..MaximumCalls] of integer;
  CallPointerArrayPtr = ^CallPointerArray;

  DataArrayEntry = record
    LogEntry: Str80;
    Mult: string[6];
  end;

  WordArrayType = array[BandType, cw..Both] of Word;
  WordArrayPtr = ^WordArrayType;

  ByteArrayType = array[BandType, cw..Both] of BYTE;
  ByteArrayPtr = ^ByteArrayType;

const
  MaximumLogEntries = 65536 div SizeOf(DataArrayEntry) - 1;

type
  DataArray = array[0..MaximumLogEntries] of DataArrayEntry;
  DataArrayPtr = ^DataArray;

  SuffixString = Str80;

  ContactRecord = record
    Band: BandType;
    Mode: ModeType;
    Date: string[9];
    Time: string[5];
    RST: string[3];
  end;

  QSLLabelRecord = record
    Callsign: CallString;
    NumberContacts: integer;
    ContactArray: array[1..3] of ContactRecord;
  end;

  QSLLabelBlock = array[0..QSLLabelBlockSize - 1] of QSLLabelRecord;
  QSLLabelBlockPointer = ^QSLLabelBlock;

  QSLDataRecord = record
    NumberLabels: integer;
    Blocks: array[1..MaxNumberBlocks] of QSLLabelBlockPointer;
  end;

  CountryTotalArrayType = array[0..400] of integer;

  PointerArrayType = array[0..MaxQSLLabelAddress] of integer;
  PointerArrayPointer = ^PointerArrayType;

  RateSheetType = array[1..3, 0..23, BandType, cw..Both] of integer;
  RateSheetPointer = ^RateSheetType;

  ReportEntryArray = array[0..500] of Str20;
  ReportEntryArrayPointer = ^ReportEntryArray;

  OpenLogRecord = record
    Band: BandType;
    Mode: ModeType;
  end;

var
  AccumulateQSOPoints: boolean;
  AccumulateMultipliers: boolean;

  Block             : integer;
  PrintBreak        : integer;

  Call              : CallString;
  CallLists         : array[1..10] of CallArrayPtr;
  CheckForDupes     : boolean;
  Contest           : Str80;
  Continued         : boolean;
  CWEnable          : boolean;

  DupeLogs          : boolean;
  DupeByBand        : boolean;
  DupeByMode        : boolean;
  DupeSheetTitle    : Str80;

  EndOfOtherCallList: integer;
  FirstCallAddress  : integer;

  FileWrite0, FileWrite1, FileWrite2, FileWrite3, FileWrite4: Text;
  FileWrite5, FileWrite6, FileWrite7, FileWrite8, FileWrite9: Text;

  FileWrite10, FileWrite11, FileWrite12, FileWrite13, FileWrite14: Text;
  FileWrite15, FileWrite16, FileWrite17, FileWrite18, FileWrite19: Text;
  FileWrite20, FileWrite21, FileWrite22, FileWrite23: Text;

  Header            : array[0..9] of Str80;

  Key               : Char;

  LastCallAddress   : integer;
  LastPushedLogName : Str20;
  LastNewList       : integer;
  Lines             : integer;
  LogFileOpen       : array[0..MaxLogFilesOpen] of OpenLogRecord;
  LogFileQSOPoints  : WordArrayPtr;
  LogFileQSOsPrinted: WordArrayPtr;
  LogTotals         : QSOTotalArray;
  LogTotalsAccurate : boolean;

  MultByBandAndModeDetermined: boolean;
  MultiplierArray   : DataArrayPtr;

  NCalls            : integer;
  NLines            : integer;
  NumberBufferCalls : integer;
  NumberContactsPerLabel: BYTE;
  NumberCountries   : integer;
  NumberDifferentMults: integer;
  NumberDupes       : integer;
  NumberHeaderLines : integer;
  NumberLines       : integer;
  NumberLogFilesOpen: Word;
  NumberOtherCalls  : integer;

  NumberPageDomesticMults: ByteArrayPtr;
  NumberPageDXMults : ByteArrayPtr;
  NumberPagePrefixMults: ByteArrayPtr;
  NumberPageZoneMults: ByteArrayPtr;
  NumberUSACalls    : integer;

  Offset            : integer;
  OtherCallList     : CallArrayPtr;
  OtherCallPointerList: CallPointerArrayPtr;
  Over              : boolean;

  PageQSOPoints     : WordArrayPtr;
  PageValidContacts : ByteArrayPtr;
  PointerArray      : PointerArrayPointer;
  PrintingRestOfCalls: boolean;

  QSLData           : QSLDataRecord;
  QSOByBandAndModeDetermined: boolean;
  QSOsPerPage       : integer;

  RateSheet         : RateSheetPointer;

  ReNumberQSONumbers: boolean;
  ReportEntries     : ReportEntryArrayPointer;
  Result            : integer;

  SeparateBandLogs  : boolean;
  SeparateModeLogs  : boolean;
  Sheet             : DupeAndMultSheet; { 13,638 bytes }
  Spaces            : Str40;
  StartBand, StopBand: BandType;
  StartMode, StopMode: ModeType;

  temp              : integer;
  TempKey           : Char;
  TempString        : string;
  Title             : Str80;
  TotalCalls        : integer;

  TotalDomesticMults: ByteArrayPtr;
  TotalDXMults      : ByteArrayPtr;
  TotalPrefixMults  : WordArrayPtr;
  TotalZoneMults    : ByteArrayPtr;

  USACallList       : CallArrayPtr;
  USACallPointerList: CallPointerArrayPtr;

  ValidContacts     : WordArrayPtr;

procedure BlankOutMultsAndZeroQSOPoints(var LogString: string {80}; InsertString: Str40);

procedure ChangeLogStringDateTime(var LogString: string; Offset: integer);
function CheckForTempFile: boolean;
procedure CloseAllOpenFiles;

procedure DetermineLogTotals;
function DetermineMultiplierTypes: boolean;
procedure DetermineMultByBandAndMultByMode;
procedure DetermineQSOByBandAndQSOByMode;
procedure DisposeCallBuffer;
function DupingFileName(Band: BandType; Mode: ModeType): Str80;
function DupingFileTitle(Band: BandType; Mode: ModeType): Str80;

function GetCall(CallAddress: integer): CallString;

function GetContestExchangeFromLogEntryExchange(LogEntry: string;
  var RXData: ContestExchange): boolean;

function GetContestExchangeFromMultiplierString(LogEntry: string {80};
  var RXData: ContestExchange): boolean;
procedure OpenFilesForBandsBeingProcessed;
function OpenLogFile(Band: BandType; Mode: ModeType): boolean;

procedure PushLogFiles;

procedure PutCall(CallAddress: integer; Call: CallString);
function PutLogFileIntoCallBuffer(Mode: ModeType; Band: BandType): boolean;

function SetUpPostParametersFromLOGCFGFile: boolean;

procedure ViewLog;
procedure WriteToLogFile(LogEntry: Str80; Band: BandType; Mode: ModeType);

implementation
//wli
uses postcfg;
//wli{$I PostCfg}  { Has the function ProcessPostConfigInstruction }

{ ***************** Callsign Array Support Routines **************** }

function GetCall(CallAddress: integer): CallString;

{ The function will retrieve a callsign from the address specified.  }
{ It computes which array to find the call in along with the proper  }
{ address within the array.  An error message is printed if the      }
{ address is out of range.                                           }

var
  List              : integer;

begin
  List := CallAddress div MaximumListCalls + 1;
  CallAddress := CallAddress mod MaximumListCalls;
  GetCall := CallLists[List]^[CallAddress];
end;

procedure PutCall(CallAddress: integer; Call: CallString);

{ This procedure is used to put a call into the calllist.  The address }
{ of the call is used to compute which array and array address to use. }
{ An error message is printed if the address to out of range. }

var
  List              : integer;

begin
  List := (CallAddress div MaximumListCalls) + 1;
  CallAddress := CallAddress mod MaximumListCalls;

  if List > LastNewList then
  {//        IF MaxAvail > SizeOf (CallArray) THEN}begin
    New(CallLists[List]);
    LastNewList := List;
{            END
        ELSE
            BEGIN
            ReportError ('Not enough memory to add Call List!!');
            WaitForKeyPressed;
            Halt;
           }
  end;

  CallLists[List]^[CallAddress] := Call;
end;

procedure DisposeCallBuffer;

var
  List              : integer;

begin
  if LastNewList > 0 then begin
    for List := 1 to LastNewList do
      Dispose(CallLists[List]);
    LastNewList := 0;
  end;

  LastNewList := 0;
  NumberBufferCalls := 0;
end;

function DupingFileName(Band: BandType; Mode: ModeType): Str80;

var
  TempString        : Str20;

begin
  TempString := ModeString[Mode] + BandString[Band];

  while pos(' ', TempString) > 0 do
    Delete(TempString, pos(' ', TempString), 1);

  DupingFileName := 'L' + TempString;
end;

function DupingFileTitle(Band: BandType; Mode: ModeType): Str80;

var
  TempString        : Str80;

begin
  TempString := BandString[Band] + ModeString[Mode];

  if StringHas(TempString, 'BTH') or StringHas(TempString, 'ALL') then begin
    Delete(TempString, length(TempString) - 2, 3);
    TempString := TempString + ' Meters';
  end;

  DupingFileTitle := Title + '  ' + TempString;
end;

function GetLogFileName(Band: BandType; Mode: ModeType): Str20;

begin
  if SeparateBandLogs then
    if SeparateModeLogs then begin
      if Mode = cw then
        case Band of
          Band160: GetLogFileName := 'L160CW.DAT';
          Band80: GetLogFileName := 'L80CW.DAT';
          Band40: GetLogFileName := 'L40CW.DAT';
          Band20: GetLogFileName := 'L20CW.DAT';
          Band15: GetLogFileName := 'L15CW.DAT';
          Band10: GetLogFileName := 'L10CW.DAT';
          Band30: GetLogFileName := 'L30CW.DAT';
          Band17: GetLogFileName := 'L17CW.DAT';
          Band12: GetLogFileName := 'L12CW.DAT';
          Band6: GetLogFileName := 'L6CW.DAT';
          Band2: GetLogFileName := 'L2CW.DAT';
          Band222: GetLogFileName := 'L222CW.DAT';
          Band432: GetLogFileName := 'L432CW.DAT';
          Band902: GetLogFileName := 'L902CW.DAT';
          Band1296: GetLogFileName := 'L1GHCW.DAT';
          Band2304: GetLogFileName := 'L2GHCW.DAT';
          Band3456: GetLogFileName := 'L3GHCW.DAT';
          Band5760: GetLogFileName := 'L5GHCW.DAT';
          Band10G: GetLogFileName := 'L10GW.DAT';
          Band24G: GetLogFileName := 'L24GW.DAT';
          BandLight: GetLogFileName := 'LLHTCW.DAT';
        end
      else
        case Band of
          Band160: GetLogFileName := 'L160SSB.DAT';
          Band80: GetLogFileName := 'L80SSB.DAT';
          Band40: GetLogFileName := 'L40SSB.DAT';
          Band20: GetLogFileName := 'L20SSB.DAT';
          Band15: GetLogFileName := 'L15SSB.DAT';
          Band10: GetLogFileName := 'L10SSB.DAT';
          Band30: GetLogFileName := 'L30SSB.DAT';
          Band17: GetLogFileName := 'L17SSB.DAT';
          Band12: GetLogFileName := 'L12SSB.DAT';
          Band6: GetLogFileName := 'L6SSB.DAT';
          Band2: GetLogFileName := 'L2SSB.DAT';
          Band222: GetLogFileName := 'L222SSB.DAT';
          Band432: GetLogFileName := 'L432SSB.DAT';
          Band902: GetLogFileName := 'L902SSB.DAT';
          Band1296: GetLogFileName := 'L1GHSSB.DAT';
          Band2304: GetLogFileName := 'L2GHSSB.DAT';
          Band3456: GetLogFileName := 'L3GHSSB.DAT';
          Band5760: GetLogFileName := 'L5GHSSB.DAT';
          Band10G: GetLogFileName := 'L10GW.DAT';
          Band24G: GetLogFileName := 'L24GW.DAT';
          BandLight: GetLogFileName := 'LLHTSSB.DAT';
        end;
    end
    else begin
      case Band of
        Band160: GetLogFileName := 'LOG160.DAT';
        Band80: GetLogFileName := 'LOG80.DAT';
        Band40: GetLogFileName := 'LOG40.DAT';
        Band20: GetLogFileName := 'LOG20.DAT';
        Band15: GetLogFileName := 'LOG15.DAT';
        Band10: GetLogFileName := 'LOG10.DAT';
        Band30: GetLogFileName := 'LOG30.DAT';
        Band17: GetLogFileName := 'LOG17.DAT';
        Band12: GetLogFileName := 'LOG12.DAT';
        Band6: GetLogFileName := 'LOG6.DAT';
        Band2: GetLogFileName := 'LOG2.DAT';
        Band222: GetLogFileName := 'LOG222.DAT';
        Band432: GetLogFileName := 'LOG432.DAT';
        Band902: GetLogFileName := 'LOG902.DAT';
        Band1296: GetLogFileName := 'LOG1GH.DAT';
        Band2304: GetLogFileName := 'LOG2GH.DAT';
        Band3456: GetLogFileName := 'LOG3GH.DAT';
        Band5760: GetLogFileName := 'LOG5GH.DAT';
        Band10G: GetLogFileName := 'LOG10GW.DAT';
        Band24G: GetLogFileName := 'LOG24GW.DAT';
        BandLight: GetLogFileName := 'LOGLHT.DAT';
      end;
    end
  else
    if SeparateModeLogs then
      case Mode of
        cw: GetLogFileName := 'LOGCW.DAT';
        Phone: GetLogFileName := 'LOGSSB.DAT';
      end
    else
      GetLogFileName := 'LALLBOTH.DAT';
end;

function FindOpenFile(Band: BandType; Mode: ModeType): integer;

{ Returns -1 if open file for that band/mode is not found }

var
  LogFile           : integer;

begin
  FindOpenFile := -1;

  if NumberLogFilesOpen > 0 then
    for LogFile := 0 to NumberLogFilesOpen - 1 do
      if (LogFileOpen[LogFile].Band = Band) and
        (LogFileOpen[LogFile].Mode = Mode) then begin
        FindOpenFile := LogFile;
        Exit;
      end;

end;

function OpenLogFile(Band: BandType; Mode: ModeType): boolean;

var
  FileName          : Str20;

begin
  if NumberLogFilesOpen >= MaxLogFilesOpen then begin
    OpenLogFile := False;
    Exit;
  end;

  LogFileOpen[NumberLogFilesOpen].Band := Band;
  LogFileOpen[NumberLogFilesOpen].Mode := Mode;

  FileName := GetLogFileName(Band, Mode);

  case NumberLogFilesOpen of
    0: OpenFileForWrite(FileWrite0, FileName);
    1: OpenFileForWrite(FileWrite1, FileName);
    2: OpenFileForWrite(FileWrite2, FileName);
    3: OpenFileForWrite(FileWrite3, FileName);
    4: OpenFileForWrite(FileWrite4, FileName);
    5: OpenFileForWrite(FileWrite5, FileName);
    6: OpenFileForWrite(FileWrite6, FileName);
    7: OpenFileForWrite(FileWrite7, FileName);
    8: OpenFileForWrite(FileWrite8, FileName);
    9: OpenFileForWrite(FileWrite9, FileName);
    10: OpenFileForWrite(FileWrite10, FileName);
    11: OpenFileForWrite(FileWrite11, FileName);
    12: OpenFileForWrite(FileWrite12, FileName);
    13: OpenFileForWrite(FileWrite13, FileName);
    14: OpenFileForWrite(FileWrite14, FileName);
    15: OpenFileForWrite(FileWrite15, FileName);
    16: OpenFileForWrite(FileWrite16, FileName);
    17: OpenFileForWrite(FileWrite17, FileName);
    18: OpenFileForWrite(FileWrite18, FileName);
    19: OpenFileForWrite(FileWrite19, FileName);
    20: OpenFileForWrite(FileWrite20, FileName);
    21: OpenFileForWrite(FileWrite21, FileName);
    22: OpenFileForWrite(FileWrite22, FileName);
    23: OpenFileForWrite(FileWrite23, FileName);

  else begin
      ShowMessage('K7RAT error!! - report to N6TR.');
      halt;
    end;
  end;

  inc(NumberLogFilesOpen);
end;

procedure WriteToLogFile(LogEntry: Str80; Band: BandType; Mode: ModeType);

var
  LogFile           : integer;

begin
  case FindOpenFile(Band, Mode) of

    -1: Exit; { File not open }

    0: WriteLn(FileWrite0, LogEntry);
    1: WriteLn(FileWrite1, LogEntry);
    2: WriteLn(FileWrite2, LogEntry);
    3: WriteLn(FileWrite3, LogEntry);
    4: WriteLn(FileWrite4, LogEntry);
    5: WriteLn(FileWrite5, LogEntry);
    6: WriteLn(FileWrite6, LogEntry);
    7: WriteLn(FileWrite7, LogEntry);
    8: WriteLn(FileWrite8, LogEntry);
    9: WriteLn(FileWrite9, LogEntry);
    10: WriteLn(FileWrite10, LogEntry);
    11: WriteLn(FileWrite11, LogEntry);
    12: WriteLn(FileWrite12, LogEntry);
    13: WriteLn(FileWrite13, LogEntry);
    14: WriteLn(FileWrite14, LogEntry);
    15: WriteLn(FileWrite15, LogEntry);
    16: WriteLn(FileWrite16, LogEntry);
    17: WriteLn(FileWrite17, LogEntry);
    18: WriteLn(FileWrite18, LogEntry);
    19: WriteLn(FileWrite19, LogEntry);
    20: WriteLn(FileWrite20, LogEntry);
    21: WriteLn(FileWrite21, LogEntry);
    22: WriteLn(FileWrite22, LogEntry);
    23: WriteLn(FileWrite23, LogEntry);

  else begin
      ShowMessage('WA6TUT error!! - report to N6TR');
      halt;
    end;

  end;
end;

procedure CloseAllOpenFiles;

var
  LogFile           : integer;

begin
  if NumberLogFilesOpen > 0 then
    for LogFile := 0 to NumberLogFilesOpen - 1 do
      case LogFile of
        0: Close(FileWrite0);
        1: Close(FileWrite1);
        2: Close(FileWrite2);
        3: Close(FileWrite3);
        4: Close(FileWrite4);
        5: Close(FileWrite5);
        6: Close(FileWrite6);
        7: Close(FileWrite7);
        8: Close(FileWrite8);
        9: Close(FileWrite9);
        10: Close(FileWrite10);
        11: Close(FileWrite11);
        12: Close(FileWrite12);
        13: Close(FileWrite13);
        14: Close(FileWrite14);
        15: Close(FileWrite15);
        16: Close(FileWrite16);
        17: Close(FileWrite17);
        18: Close(FileWrite18);
        19: Close(FileWrite19);
        20: Close(FileWrite20);
        21: Close(FileWrite21);
        22: Close(FileWrite22);
        23: Close(FileWrite23);
      end;

end;

procedure DetermineLogTotals;

var
  Band              : BandType;

begin
  if LogTotalsAccurate then Exit;
//    TextColor (Cyan);
//  postform.cm.Lines.Add('Examining log for QSO totals...');
  Sheet.ExamineLogForQSOTotals(LogTotals);
//    GoToXY (1, WhereY);
//    ClrEol;
  LogTotalsAccurate := true;
end;

procedure DetermineQSOByBandAndQSOByMode;

var
  Key               : Char;

begin
  QSOByBandAndModeDetermined := False;
//DetForm.showmodal;

{  repeat
    Key := UpCase(GetKey('Can you work stations again on each mode? (Y/N or ESCAPE to abort) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;
 }QSOByMode := PostForm.oneachmode.Checked;

{  repeat
    Key := UpCase(GetKey('Can you work stations again on each band? (Y/N or ESCAPE to abort) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;
 }QSOByBand := PostForm.oneachband.Checked;

  if QSOByBand then begin
    StartBand := Band160;
    StopBand := Band10;
  end
  else begin
    StartBand := All;
    StopBand := All;
  end;

  if QSOByMode then begin
    StartMode := cw;
    StopMode := Phone;
  end
  else begin
    StartMode := Both;
    StopMode := Both;
  end;

  QSOByBandAndModeDetermined := true;
end;

procedure DetermineMultByBandAndMultByMode;

var
  Key               : Char;

begin
  DetMultForm.ShowModal;
  QSOByBandAndModeDetermined := False;
{  repeat
    Key := UpCase(GetKey('Do multipliers count again on each mode? (Y/N or ESCAPE to abort) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;
}
  MultByMode := DetMultForm.c1.Checked; //Key = 'Y';

{
  repeat
    Key := UpCase(GetKey('Do multipliers count again on each band? (Y/N or ESCAPE to abort) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;
 }MultByBand := DetMultForm.c2.Checked; //Key = 'Y';

  if MultByBand then begin
    StartBand := Band160;
    StopBand := Band10;
  end
  else begin
    StartBand := All;
    StopBand := All;
  end;

  if MultByMode then begin
    StartMode := cw;
    StopMode := Phone;
  end
  else begin
    StartMode := Both;
    StopMode := Both;
  end;

  MultByBandAndModeDetermined := true;
end;

procedure OpenFilesForBandsBeingProcessed;

var
  Band              : BandType;
  Mode              : ModeType;

begin
  NumberLogFilesOpen := 0;

  for Band := StartBand to StopBand do
    for Mode := StartMode to StopMode do
      if LogTotals[Band, Mode] > 0 then
        OpenLogFile(Band, Mode);
end;

procedure BlankOutMultsAndZeroQSOPoints(var LogString: string {80}; InsertString: Str40);

begin
  Delete(LogString, LogEntryMultAddress, 8);

  while length(InsertString) < 8 do InsertString := InsertString + ' ';
  Insert(InsertString, LogString, LogEntryMultAddress);

  Delete(LogString, LogEntryPointsAddress, LogEntryPointsWidth);
  Insert(' 0', LogString, LogEntryPointsAddress);
end;

function PutLogFileIntoCallBuffer(Mode: ModeType; Band: BandType): boolean;

var
  FileRead          : Text;
  LogBand           : BandType;
  LogMode           : ModeType;
  Call              : {Call} string;
  List              : integer;

begin
//    TextColor (Cyan);
//    GoToXY (1, WhereY);
//    ClrEol;
  postform.cm.Lines.Add('Loading calls from log for ' + BandString[Band] + ModeString[Mode] + '...');

  DisposeCallBuffer;

  if not OpenFileForRead(FileRead, LogFileName) then begin
    PutLogFileIntoCallBuffer := False;
    Exit;
  end;

  while not Eof(FileRead) do begin
    ReadLn(FileRead, TempString);
    LogMode := GetLogEntryMode(TempString);

    if LogMode <> NoMode then
      if ((LogMode = Mode) or (Mode = Both)) then
        if not (StringHas(TempString, 'DUPE') or StringHas(TempString, 'ZERO')) then
          if (Band = All) or (GetLogEntryBand(TempString) = Band) then begin
            ExpandTabs(TempString);
            Call := Copy(TempString, LogEntryCallAddress, 12);
            GetRidOfPostcedingSpaces(Call);
            Call := StandardCallFormat(Call, False);
            PutCall(NumberBufferCalls, Call);
            inc(NumberBufferCalls);
          end;
  end;

  Close(FileRead);
  PutLogFileIntoCallBuffer := true;
//    GoToXY (1, WhereY);
//    ClrEol;
end;

function DetermineMultiplierTypes: boolean;

var
  Key               : Char;

begin
  DetermineMultiplierTypes := False;
{  repeat
    Key := UpCase(GetKey('Domestic mults? (Y/N) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;
 }DoingDomesticMults := postform.MultiplierTypeG.ItemIndex = 0;

{  repeat
    Key := UpCase(GetKey('DX Country mults? (Y/N) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;
 }DoingDXMults := postform.MultiplierTypeG.ItemIndex = 1;

{  repeat
    Key := UpCase(GetKey('Prefix mults? (Y/N) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;
 }DoingPrefixMults := postform.MultiplierTypeG.ItemIndex = 2;

{  repeat
    Key := UpCase(GetKey('Zone mults? (Y/N) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;
 }DoingZoneMults := postform.MultiplierTypeG.ItemIndex = 3;
  DetermineMultiplierTypes := true;
end;

procedure ViewLog;

var
  FileString        : string;
  Call              : Str80;
  SearchStringFound : boolean;
  Line, Count, NumberLinesPrinted, NumberLinesInBuffer: integer;
  AddressOfEntryFoundInBuffer: integer;
  Buffer            : array[0..25] of Str80;
  FileRead          : Text;

begin
{    ClrScr;
    TextColor (Yellow);
    WriteLnCenter ('VIEW LOG SEGMENT PROCEDURE');
    WriteLn;
    TextColor (Cyan);
    WriteLn ('This procedure allows you to search for something in the log and look at the');
    WriteLn ('first log entry that contains the search string.  It also shows you the next');
    WriteLn ('screen full of log entries occuring afterwards.  You can then input a new');
    WriteLn ('search string and the program will continue forward looking for the new search');
    WriteLn ('string.  This allows you to find a QSO that occured at 06:05 on the second day.');
    WriteLn ('You would first search for the proper date, then search for 06:.  The search');
    WriteLn ('is case insensitive.  If you want to continue after seeing 20 QSOs with the');
    WriteLn ('next 20 QSOs, use a space as your search string.');
    WriteLn;
}
  if not OpenFileForRead(FileRead, LogFileName) then begin
    ShowMessage('Unable to open ' + LogFileName);
    Exit;
  end;

  Viewform.c.Clear;
  Call := postform.SearchEdit.Text;
  if Call = '' then Exit;

  NumberLinesInBuffer := 0;

  while (not Eof(FileRead)) { and (not OperatorEscape)}
    do begin

    ReadLn(FileRead, FileString);
    if StringHas(FileString, Call) then
      ViewForm.c.Lines.Add(FileString);

  end;
  Viewform.Caption := 'Search of "' + Call + '" :';
  Viewform.ShowModal;
  Exit;
  {
  begin
  NumberLinesPrinted := 0;
  SearchStringFound := False;
  ReadLn(FileRead, FileString);
  Buffer[0] := FileString;
  NumberLinesInBuffer := 1;

  if (NumberLinesInBuffer > 0) and (Call <> ' ') then
    for Line := 0 to NumberLinesInBuffer - 1 do
      if StringHas(Buffer[Line], Call) then begin
          SearchStringFound := true;
//          WriteLn(Buffer[Line]);
          ViewForm.c.Lines.Add(Buffer[Line]);
          inc(NumberLinesPrinted);
          AddressOfEntryFoundInBuffer := Line;

{                    IF Line = (NumberLinesInBuffer - 1) THEN
                        NumberLinesInBuffer := 0
                    ELSE
                        Line := NumberLinesInBuffer - 1;
                    END;
}
{          if not SearchStringFound then begin
              NumberLinesInBuffer := 0;
              ReadLn(FileRead, FileString);

              if StringHas(UpperCase(FileString), Call) then begin

                  ExpandTabs(FileString);
                  WriteLn(FileString);
                  ViewForm.c.Lines.Add(FileString);
                  inc(NumberLinesPrinted);
                  SearchStringFound := true;
                end;
            end;

          if SearchStringFound then begin
              if NumberLinesInBuffer > 0 then begin
                  for Count := AddressOfEntryFoundInBuffer + 1 to NumberLinesInBuffer - 1 do begin
//                WriteLn(Buffer[Count]);
//          POSTFORM.c.Lines.Add(Buffer[Count]);
                      Buffer[Count - AddressOfEntryFoundInBuffer + 1] := Buffer[Count];
                      inc(NumberLinesPrinted);
                    end;

                  NumberLinesInBuffer := NumberLinesInBuffer - AddressOfEntryFoundInBuffer - 1;
                end;

              while (NumberLinesPrinted < 21) and not Eof(FileRead) do begin
                  ReadLn(FileRead, FileString);
                  ExpandTabs(FileString);
//              WriteLn(FileString);
//          POSTFORM.c.Lines.Add(FileString);
                  Buffer[NumberLinesInBuffer] := FileString;
                  inc(NumberLinesInBuffer);
                  inc(NumberLinesPrinted);
                end;

{            Call := UpperCase(GetResponse('Enter string to search for (none to stop) : '));

            if Call = '' then
            begin
              Close(FileRead);
              exit;
            end;
          }
{            end;
        end;

end;
Close(FileRead);
}
end;

function CheckForTempFile: boolean;

{ Returns FALSE if the procedure should exit. }

var
  Key               : Char;
  FileRead, FileWrite: Text;
  FileString        : Str160;
  TempFileName      : Str20;

begin
  CheckForTempFile := False;

  if LogFileName = 'LOG.DAT' then
    TempFileName := 'LOG.TMP'
  else
    TempFileName := PrecedingString(LogFileName, '.') + '.TMP';

  if FileExists(TempFileName) and (GetFileSize_TR(TempFileName) > 20) then begin

{

    If MessageBox(0,

pchar('The temp file has been found.'+#13+
     'This means the Alt-U command has not been executed in the logging program.'+#13+
     'You can exit this program and execute the Alt-U command or I can append it to the log file for you.'+#13+
     'If I do it for you, there is some chance that the page format will be wrong.'+#13+
     'This is not a problem if you are planning on creating a new log sheet with running totals.')

    ,
      'TR4W', MB_YESNO Or MB_ICONQUESTION) <> IDno Then exit;

}

    if MessageBox(0, PChar('The temp file has been found.' + #13 +
      'This means the Alt-U command has not been executed in the logging program.' + #13 +
      'You can exit this program and execute the Alt-U command or I can append it to the log file for you.' + #13 +
      'If I do it for you, there is some chance that the page format will be wrong.' + #13 +
      'This is not a problem if you are planning on creating a new log sheet with running totals.' + #13 + #13 + 'Append temp file to ' + LogFileName + '?'), 'Post', MB_YESNO or MB_ICONWARNING) = IDno then Exit;

//    repeat
//      Key := UpCase(GetKey('Type A to Append temp file to ' + LogFileName + ' or ESCAPE to exit : '));
//      if Key = EscapeKey then exit;
//    until Key = 'A';

    if not OpenFileForRead(FileRead, TempFileName) then Exit;
    if not OpenFileForAppend(FileWrite, LogFileName) then Exit;

    while not Eof(FileRead) do begin
      ReadLn(FileRead, FileString);
      WriteLn(FileWrite, FileString);
    end;

    Close(FileRead);
    Close(FileWrite);
    SysUtils.DeleteFile(TempFileName);
//        GoToXY (1, WhereY);
//        TextColor (Cyan);
    ShowMessage(TempFileName + ' has been appended to ' + LogFileName + '.' + #13 +
      'Also, ' + TempFileName + ' has been erased so you won''t be tempted to add another 5 QSOs to your log later on.');
  end;

  CheckForTempFile := true;
end;

function SetUpPostParametersFromLOGCFGFile: boolean;

{ This routine will read in the LOGCFG.DAT file found and set up all the
  global variables that might be needed to accurately check multipliers,
  generate summary sheets, or any of the other functions likely to be
  executed during the POST process.  }












var
  FileRead          : Text;
  FileString        : string;
  LogConfigFileName : string;
  ID, CMD           : string;

begin
  ActiveExchange := UnknownExchange;

  SetUpPostParametersFromLOGCFGFile := False;

  ClearDomesticCountryList;
//wli
  if ExtractFileName(LogFileName) = 'LOG.DAT' then
    LogConfigFileName := ExtractFileDir(LogFileName) + '\LOGCFG.DAT'
  else
    LogConfigFileName := ChangeFileExt(LogFileName, '.CFG'); //PrecedingString(LogFileName, '.') + '.CFG';

  if not OpenFileForRead(FileRead, LogConfigFileName) then begin
    ShowMessage('Unable to open ' + LogConfigFileName + ' file!!  Make sure you are in the proper directory.');
    Exit;
  end;

  while not Eof(FileRead) do begin
    ReadLn(FileRead, FileString);
    FileString := UpperCase(FileString);

    ID := PrecedingString(FileString, '=');
    CMD := PostcedingString(FileString, '=');

    GetRidOfPrecedingSpaces(ID);
    GetRidOfPrecedingSpaces(CMD);
    GetRidOfPostcedingSpaces(ID);
    GetRidOfPostcedingSpaces(CMD);

    if ID <> '' then ProcessPostConfigInstruction(ID, CMD);
  end;

  Close(FileRead);

  SetUpExchangeInformation(ActiveExchange, ExchangeInformation);

  DoingDomesticMults := ActiveDomesticMult <> NoDomesticMults;
  DoingDXMults := ActiveDXMult <> NoDXMults;
  DoingPrefixMults := ActivePrefixMult <> NoPrefixMults;
  DoingZoneMults := ActiveZoneMult <> NoZoneMults;

  if DomesticQTHDataFileName <> '' then
    if not DomQTHTable.LoadInDomQTHFile(DomesticQTHDataFileName) then begin
      ShowMessage('Unable to find ' + DomesticQTHDataFileName + '!!');
      Exit;
    end;

  Sheet.SetUpRemainingMultiplierArrays;

  NumberDifferentMults := 0;

  if DoingZoneMults then begin
    inc(NumberDifferentMults);
    RemainingMultDisplay := Zone;
  end;

  if (DoingDomesticMults) and (ActiveDomesticMult <> WYSIWYGDomestic) then
    RemainingMultDisplay := Domestic;

  if DoingDomesticMults then
    inc(NumberDifferentMults);

  if DoingDXMults then begin
    inc(NumberDifferentMults);
    RemainingMultDisplay := DX;
  end;

  if DoingPrefixMults then inc(NumberDifferentMults);

  if NumberDifferentMults > 2 then begin
//    SHOWMESSAGE('Too many multipliers enabled!!');
//    halt;
  end;

  SetUpPostParametersFromLOGCFGFile := ActiveExchange <> UnknownExchange;
end;

function GetContestExchangeFromLogEntryExchange(LogEntry: string;
  var RXData: ContestExchange): boolean;

{ This procedure will take a log entry from a LOG and parse it back into
  the ContestExchange format.  It ignores the multiplier string and
  generates the multiplier flags based upon the exchange string. }

var
  ExchangeString, MultString: Str40;
  Mult, NumberMults : integer;
  MultArray         : array[1..2] of Str20;
  MultIdentified    : boolean;

begin
  GetContestExchangeFromLogEntryExchange := False;

  if (ActiveExchange = UnknownExchange) or (LogEntry = '') then Exit;

  ClearContestExchange(RXData);

  ExpandTabs(LogEntry);

  RXData.Band := GetLogEntryBand(LogEntry);
  RXData.Mode := GetLogEntryMode(LogEntry);
  RXData.Callsign := GetLogEntryCall(LogEntry);

  if (RXData.Band = NoBand) or (RXData.Mode = NoMode) or
    (RXData.Callsign = '') then Exit;

  RXData.Date := GetLogEntryDateString(LogEntry);
  RXData.Time := GetLogEntryIntegerTime(LogEntry);
  RXData.NumberSent := GetLogEntryQSONumber(LogEntry);
  RXData.QSOPoints := GetLogEntryQSOPoints(LogEntry);

  ParseExchangeIntoContestExchange(LogEntry, RXData);

    { We now have all of the log entry elements in RXData.  We need to
      set the DX QTH and prefix variables up, and if we are doing
      domestic QTHs, see if we can figure out what it is. }

  LocateCall(RXData.Callsign, RXData.QTH, true);

  if DoingDXMults then GetDXQTH(RXData);

  if DoingPrefixMults then
    case ActivePrefixMult of

      BelgiumPrefixes:
        if RXData.QTH.CountryID = 'ON' then
          RXData.Prefix := RXData.QTH.Prefix;

      SACDistricts: RXData.Prefix := SACDistrict(RXData.QTH);
      Prefix: RXData.Prefix := RXData.QTH.Prefix;

      SouthAmericanPrefixes:
        if RXData.QTH.Continent = SouthAmerica then
          RXData.Prefix := RXData.QTH.Prefix;
    end;

  if DoingDomesticMults and (RXData.DXQTH = '') then
    FoundDomesticQTH(RXData);

    { Now set the multiplier flags }

  Sheet.SetMultFlags(RXData);
  GetContestExchangeFromLogEntryExchange := true;
end;

function GetContestExchangeFromMultiplierString(LogEntry: string {80};
  var RXData: ContestExchange): boolean;

{ This procedure will recreate the QTHs from the multiplier string and set
  the multiplier flags. }

var
  MultString        : Str20;
  NumberMults, Mult : integer;
  MultArray         : array[1..2] of Str20;
  MultIdentified    : boolean;

begin
  GetContestExchangeFromMultiplierString := False;
  ClearContestExchange(RXData);

  if NumberDifferentMults = 0 then Exit;

  ExpandTabs(LogEntry);

  MultString := GetLogEntryMultString(LogEntry);

  if MultString = '' then Exit;

  if StringHas(MultString, ' ') then begin
    MultArray[1] := PrecedingString(MultString, ' ');
    MultArray[2] := PostcedingString(MultString, ' ');
    NumberMults := 2;
  end
  else begin
    MultArray[1] := MultString;
    NumberMults := 1;
  end;

  for Mult := 1 to NumberMults do begin
    MultIdentified := False;

    if DoingDomesticMults and
      (StringHasLowerCase(MultArray[Mult]) or (NumberDifferentMults = 1)) then begin
      RXData.QTHString := MultArray[Mult];
      RXData.Callsign := GetLogEntryCall(LogEntry);

{ This next step is necessary to fake the FoundDomesticQTH routine into
  thinking the Domestic QTH is valid if you are using GridFields. }

      if (ActiveDomesticMult = GridFields) and (length(RXData.QTHString) = 2) then
        RXData.QTHString := RXData.QTHString + '12';

      FoundDomesticQTH(RXData);
      RXData.DomesticMult := true;
      MultIdentified := true;
    end;

    if DoingZoneMults and StringIsAllNumbers(MultArray[Mult]) and not MultIdentified then begin
      RXData.ZoneMult := true;
      RXData.Zone := MultArray[Mult];
      MultIdentified := true;
    end;

    if DoingPrefixMults and not MultIdentified then begin
      RXData.PrefixMult := true;
      RXData.Prefix := MultArray[Mult];
      MultIdentified := true;
    end;

    if DoingDXMults and not MultIdentified then begin
      RXData.DXQTH := MultArray[Mult];
      RXData.DXMult := true;
    end;
  end;

  GetContestExchangeFromMultiplierString := true;
end;

procedure PushLogFiles;

{ This procedure will take the current active log file and create a
  backup file with the filename PLOG###.BAK.  ## is intially 01, and
  then increments each time.  The active log file is removed. }

var
  FileNumber        : integer;
  TempString        : Str20;

begin
  FileNumber := 0;

  repeat
    Str(FileNumber, TempString);
    while length(TempString) < 3 do TempString := '0' + TempString;

    TempString := 'PLOG' + TempString + '.BAK';

    if not FileExists(TempString) then begin
      SysUtils.RenameFile(LogFileName, TempString);

      LastPushedLogName := TempString;
      Exit;
    end;

    inc(FileNumber);

  until FileNumber > 1000;

  ShowMessage('Unable to create backup file!!');
  halt;
end;

function GetDayOfYear(DateString: Str20; var Year: integer): integer;

var
  Day, Result1, Month, MonthAdder: integer;
  DayString, MonthString, YearString: Str20;

begin
  DayString := Copy(DateString, 1, 2);
  MonthString := Copy(DateString, 4, 3);
  YearString := Copy(DateString, 8, 2);

  Val(DayString, Day, Result);

  Val(YearString, Year, Result);

  MonthString := UpperCase(MonthString);

  if MonthString = 'JAN' then Month := 1;
  if MonthString = 'FEB' then Month := 2;
  if MonthString = 'MAR' then Month := 3;
  if MonthString = 'APR' then Month := 4;
  if MonthString = 'MAY' then Month := 5;
  if MonthString = 'JUN' then Month := 6;
  if MonthString = 'JUL' then Month := 7;
  if MonthString = 'AUG' then Month := 8;
  if MonthString = 'SEP' then Month := 9;
  if MonthString = 'OCT' then Month := 10;
  if MonthString = 'NOV' then Month := 11;
  if MonthString = 'DEC' then Month := 12;

  if Year mod 4 = 0 then { Leap year for my lifetime } begin
    case Month of
      1: MonthAdder := 0;
      2: MonthAdder := 31;
      3: MonthAdder := 31 + 29;
      4: MonthAdder := 31 + 29 + 31;
      5: MonthAdder := 31 + 29 + 31 + 30;
      6: MonthAdder := 31 + 29 + 31 + 30 + 31;
      7: MonthAdder := 31 + 29 + 31 + 30 + 31 + 30;
      8: MonthAdder := 31 + 29 + 31 + 30 + 31 + 30 + 31;
      9: MonthAdder := 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31;
      10: MonthAdder := 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30;
      11: MonthAdder := 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31;
      12: MonthAdder := 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30;
    end;
  end

  else begin
    case Month of
      1: MonthAdder := 0;
      2: MonthAdder := 31;
      3: MonthAdder := 31 + 28;
      4: MonthAdder := 31 + 28 + 31;
      5: MonthAdder := 31 + 28 + 31 + 30;
      6: MonthAdder := 31 + 28 + 31 + 30 + 31;
      7: MonthAdder := 31 + 28 + 31 + 30 + 31 + 30;
      8: MonthAdder := 31 + 28 + 31 + 30 + 31 + 30 + 31;
      9: MonthAdder := 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31;
      10: MonthAdder := 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30;
      11: MonthAdder := 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31;
      12: MonthAdder := 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30;
    end;
  end;

  GetDayOfYear := Day + MonthAdder;
end;

function ComputeDateString(DayOfYear: integer; Year: integer): Str20;

var
  FebDays           : integer;
  DayString, YearString: Str20;

begin
  Str(Year, YearString);

  if length(YearString) = 1 then YearString := '0' + YearString;

  if Year mod 4 = 0 then FebDays := 29 else FebDays := 28;

  if DayOfYear <= 31 then { January } begin
    Str(DayOfYear, DayString);
    if length(DayString) = 1 then DayString := '0' + DayString;
    ComputeDateString := DayString + '-' + 'Jan' + '-' + YearString;
    Exit;
  end;

  DayOfYear := DayOfYear - 31;

  if DayOfYear <= FebDays then { February } begin
    Str(DayOfYear, DayString);
    if length(DayString) = 1 then DayString := '0' + DayString;
    ComputeDateString := DayString + '-' + 'Feb' + '-' + YearString;
    Exit;
  end;

  DayOfYear := DayOfYear - FebDays;

  if DayOfYear <= 31 then { March } begin
    Str(DayOfYear, DayString);
    if length(DayString) = 1 then DayString := '0' + DayString;
    ComputeDateString := DayString + '-' + 'Mar' + '-' + YearString;
    Exit;
  end;

  DayOfYear := DayOfYear - 31;

  if DayOfYear <= 30 then { April } begin
    Str(DayOfYear, DayString);
    if length(DayString) = 1 then DayString := '0' + DayString;
    ComputeDateString := DayString + '-' + 'Apr' + '-' + YearString;
    Exit;
  end;

  DayOfYear := DayOfYear - 30;

  if DayOfYear <= 31 then { May } begin
    Str(DayOfYear, DayString);
    if length(DayString) = 1 then DayString := '0' + DayString;
    ComputeDateString := DayString + '-' + 'May' + '-' + YearString;
    Exit;
  end;

  DayOfYear := DayOfYear - 31;

  if DayOfYear <= 30 then { June } begin
    Str(DayOfYear, DayString);
    if length(DayString) = 1 then DayString := '0' + DayString;
    ComputeDateString := DayString + '-' + 'Jun' + '-' + YearString;
    Exit;
  end;

  DayOfYear := DayOfYear - 30;

  if DayOfYear <= 31 then { July } begin
    Str(DayOfYear, DayString);
    if length(DayString) = 1 then DayString := '0' + DayString;
    ComputeDateString := DayString + '-' + 'Jul' + '-' + YearString;
    Exit;
  end;

  DayOfYear := DayOfYear - 31;

  if DayOfYear <= 31 then { August } begin
    Str(DayOfYear, DayString);
    if length(DayString) = 1 then DayString := '0' + DayString;
    ComputeDateString := DayString + '-' + 'Aug' + '-' + YearString;
    Exit;
  end;

  DayOfYear := DayOfYear - 31;

  if DayOfYear <= 30 then { September } begin
    Str(DayOfYear, DayString);
    if length(DayString) = 1 then DayString := '0' + DayString;
    ComputeDateString := DayString + '-' + 'Sep' + '-' + YearString;
    Exit;
  end;

  DayOfYear := DayOfYear - 30;

  if DayOfYear <= 31 then { October } begin
    Str(DayOfYear, DayString);
    if length(DayString) = 1 then DayString := '0' + DayString;
    ComputeDateString := DayString + '-' + 'Oct' + '-' + YearString;
    Exit;
  end;

  DayOfYear := DayOfYear - 31;

  if DayOfYear <= 30 then { November } begin
    Str(DayOfYear, DayString);
    if length(DayString) = 1 then DayString := '0' + DayString;
    ComputeDateString := DayString + '-' + 'Nov' + '-' + YearString;
    Exit;
  end;

  DayOfYear := DayOfYear - 30;

  Str(DayOfYear, DayString);
  if length(DayString) = 1 then DayString := '0' + DayString;
  ComputeDateString := DayString + '-' + 'Dec' + '-' + YearString;
end;

procedure ChangeTime(var DateString: Str20; var TimeString: Str20; Offset: integer);

var
  Minute, Hour, TimeMinutes, Result: integer;
  DayOffset         : integer;
  DayofYear, Month, Year: integer;
  MinuteString, HourString: Str20;

begin
  Val(PostcedingString(TimeString, ':'), Minute, Result);
  Val(PrecedingString(TimeString, ':'), Hour, Result);

  TimeMinutes := (Hour * 60) + Minute;

    { Compute new minute }

  TimeMinutes := TimeMinutes + Offset;

  DayOffset := 0;

  while TimeMinutes < 0 do begin
    Dec(DayOffset);
    TimeMinutes := TimeMinutes + (24 * 60);
  end;

  while TimeMinutes >= (24 * 60) do begin
    inc(DayOffset);
    TimeMinutes := TimeMinutes - (24 * 60);
  end;

  if DayOffset <> 0 then begin
    DayOfYear := GetDayOfYear(DateString, Year);
    DayOfYear := DayOfYear + DayOffset;
    DateString := ComputeDateString(DayOfYear, Year);
  end;

    { Reconstruct time string }

  Minute := TimeMinutes mod 60;
  Hour := TimeMinutes div 60;

  Str(Minute, MinuteString);
  Str(Hour, HourString);

  if length(MinuteString) = 1 then MinuteString := '0' + MinuteString;
  if length(HourString) = 1 then HourString := '0' + HourString;

  TimeString := HourString + ':' + MinuteString;
end;

procedure ChangeLogStringDateTime(var LogString: string; Offset: integer);

var
  TestString, DateString, TimeString: Str20;

begin
  DateString := GetLogEntryDateString(LogString);
  TimeString := GetLogEntryTimeString(LogString);

  TestString := UpperCase(Copy(DateString, 3, 5));

  if (TestString = '-JAN-') or (TestString = '-FEB-') or
    (TestString = '-MAR-') or (TestString = '-APR-') or
    (TestString = '-MAY-') or (TestString = '-JUN-') or
    (TestString = '-JUL-') or (TestString = '-AUG-') or
    (TestString = '-SEP-') or (TestString = '-OCT-') or
    (TestString = '-NOV-') or (TestString = '-DEC-') then
    if (TimeString[3] = ':') and
      (StringIsAllNumbers(Copy(TimeString, 1, 2))) and
      (StringIsAllNumbers(Copy(TimeString, 4, 2))) and
      (StringIsAllNumbers(Copy(DateString, 1, 2))) and
      (StringIsAllNumbers(Copy(DateString, 8, 2))) then begin
      ChangeTime(DateString, TimeString, Offset);

      Delete(LogString, LogEntryHourAddress, 5);
      Insert(TimeString, LogString, LogEntryHourAddress);

      Delete(LogString, LogEntryDayAddress, 9);
      Insert(DateString, LogString, LogEntryDayAddress);
    end;
end;

begin
  ActiveExchange := UnknownExchange;
  LastPushedLogName := '';
  LogTotalsAccurate := False;
  NumberLogFilesOpen := 0;
  Sheet.DupeSheetEnable := true;
end.

