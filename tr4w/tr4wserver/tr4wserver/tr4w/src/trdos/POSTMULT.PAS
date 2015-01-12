unit PostMult;

{$O+}
{$F+}

interface

uses //Crt,
  Tree,
     //SlowTree,
  PostSubs,
  Country9,
  LogDupe,
  LogWind,
  ZoneCont,
  Dialogs,
  PostUnit {,treepas};

procedure MultiplierReportMenu;
procedure MultiplierCheckOffSheet;
function GenerateCountryMultiplierTotals: boolean;
procedure PrintFirstCountryMultiplierCallsigns;
function GenerateZoneMultiplierTotals: boolean;
procedure PrintFirstZoneMultiplierCallsigns;
function GenerateAllTotalsPerHour: boolean;
procedure PrintHourTotals;
procedure PrintRateByHourTotals;
procedure PrintQSOsByCountry;
procedure PrintQSOsByZone;

type
  MultCountryTotalRecordType = record
    FirstCall: CallString;
    TotalQSOs: integer;
  end;

  CountryMultiplierArray = array[Band160..Band10, 0..MaxCountries - 1] of MultCountryTotalRecordType;
  CountryMultiplierArrayPointer = ^CountryMultiplierArray;

  HourTotalsRecord = record
    HourName: string[2];
    QSOs: array[BandType, ModeType] of integer;
    QSOPoints: array[BandType, ModeType] of integer;
    Mults: array[BandType, ModeType] of integer;
    Minutes: array[BandType, ModeType] of integer;
  end;

  LogHourTotalArray = array[0..49] of HourTotalsRecord;
  LogHourTotalArrayPointer = ^LogHourTotalArray;

  PLEFTONBIStateType = record
    LastBand: BandType;
    LastMode: ModeType;
    LastDateString: Str20;
    LastTimeString: Str80;
    LastHourIndex: integer;
    DoingBreak: boolean;
    BandsThisMinute: array[BandType] of boolean;
  end;

var
  BandModeUsed      : array[BandType, ModeType] of boolean;

  ContestDates      : array[0..10] of string[10];
  CountryMultTotals : CountryMultiplierArrayPointer;
  CWUsed            : boolean;

  DigitalUsed       : boolean;
  DomesticTotals    : array[BandType, cw..Both] of Word;
  DXTotals          : array[BandType, cw..Both] of Word;

  Header            : Str80;

  LogHourTotals     : LogHourTotalArrayPointer;

  NumberDates       : integer;
  NumberLogHours    : integer;

  PhoneUsed         : boolean;
  PLeftOnBiState    : PLEFTONBIStateType;

  PrefixTotals      : array[BandType, cw..Both] of Word;
  QSOPointTotals    : array[BandType, cw..Both] of Word;
  RawQSOTotals      : array[BandType, cw..Both] of Word;

  SummaryWrite      : Text;

  TotalLogQSOs      : LONGINT;



{ FUNCTION Number (Call: CallString): Char; EXTERNAL;}

implementation

function GenerateCountryMultiplierTotals: boolean;

{ This procedure will go through the log file and determine how many QSOs
  were made with each country - and record the callsign of the first QSO
  for each country.  The results are saved in the structure
  CountryMultTotals. }

var
  FileRead          : Text;
  MultString, FileString: string;
  FileName, TempString: Str80;
  Destination       : Char;
  Band              : BandType;
  Mode              : ModeType;
  CountryIndex      : integer;

begin
  GenerateCountryMultiplierTotals := False;

  for Band := Band160 to Band10 do
    for CountryIndex := 0 to MaxCountries - 1 do
    begin
      CountryMultTotals^[Band, CountryIndex].FirstCall := '';
      CountryMultTotals^[Band, CountryIndex].TotalQSOs := 0;
    end;

  if not OpenFileForRead(FileRead, LogFileName) then
  begin
    ShowMessage(LogFileName + ' file not found!!');
//        WaitForKeyPressed;
    Exit;
  end;

//  Write('Searching log file for country multipliers...');

  TotalLogQSOs := 0;

  repeat
    repeat
      ReadLn(FileRead, FileString);
      Band := GetLogEntryBand(FileString);
      Mode := GetLogEntryMode(FileString);
    until ((Band <> NoBand) and (Mode <> NoMode)) or EOF(FileRead);

    if not (StringHas(FileString, '*DUPE*') or StringHas(FileString, '*ZERO*')) then
    begin
      ExpandTabs(FileString);
      MultString := GetLogEntryMultString(FileString);

      inc(TotalLogQSOs);

      if MultString <> '' then
        while MultString <> '' do
        begin
          TempString := RemoveFirstString(MultString);

          CountryIndex := CountryTable.GetCountry(TempString, true);

          if not StringHasLowerCase(TempString) then
            if not StringIsAllNumbers(TempString) then
              if CountryMultTotals^[Band, CountryIndex].TotalQSOs = 0 then
                CountryMultTotals^[Band, CountryIndex].FirstCall := GetLogEntryCall(FileString);
        end;

      CountryIndex := CountryTable.GetCountry(GetLogEntryCall(FileString), true);
      inc(CountryMultTotals^[Band, CountryIndex].TotalQSOs);
    end;

  until Eof(FileRead);
  Close(FileRead);

//    GoToXY (1, WhereY);
//    ClrEol;

  GenerateCountryMultiplierTotals := true;
end;

function GenerateZoneMultiplierTotals: boolean;

{ This procedure will go through the log file and determine how many QSOs
  were made with each zone - and record the callsign of the first QSO
  for each zone.  The results are saved in the structure
  CountryMultTotals. }

var
  FileRead          : Text;
  MultString, FileString, TempString: string;
  ZoneString, FileName: Str80;
  Destination, BandChar, ModeChar, AlphabetizeChar: Char;
  Band              : BandType;
  Mode              : ModeType;
  ZoneIndex, Result1: integer;

begin
  GenerateZoneMultiplierTotals := False;

  for Band := Band160 to Band10 do
    for ZoneIndex := 0 to MaxCountries - 1 do
    begin
      CountryMultTotals^[Band, ZoneIndex].FirstCall := '';
      CountryMultTotals^[Band, ZoneIndex].TotalQSOs := 0;
    end;

  if not OpenFileForRead(FileRead, LogFileName) then
  begin
    ShowMessage(LogFileName + ' file not found!!');
//        WaitForKeyPressed;
    Exit;
  end;

//  Write('Searching log file for zone multipliers...');

  TotalLogQSOs := 0;

  repeat
    repeat
      ReadLn(FileRead, FileString);
      Band := GetLogEntryBand(FileString);
      Mode := GetLogEntryMode(FileString);
    until ((Band <> NoBand) and (Mode <> NoMode)) or EOF(FileRead);

    if not (StringHas(FileString, '*DUPE*') or StringHas(FileString, '*ZERO*')) then
    begin
      ExpandTabs(FileString);
      MultString := GetLogEntryMultString(FileString);

      inc(TotalLogQSOs);

      if MultString <> '' then
        while MultString <> '' do
        begin
          TempString := RemoveFirstString(MultString);

          if StringIsAllNumbers(TempString) then
          begin
            Val(TempString, ZoneIndex, Result1);

            if (ZoneIndex > 0) and (ZoneIndex <= 100) then
              if CountryMultTotals^[Band, ZoneIndex].TotalQSOs = 0 then
                CountryMultTotals^[Band, ZoneIndex].FirstCall := GetLogEntryCall(FileString);
          end;
        end;

      TempString := GetLogEntryExchangeString(FileString);
      RemoveFirstString(TempString);
      RemoveFirstString(TempString);
      ZoneString := RemoveFirstString(TempString);

      if StringIsAllNumbers(ZoneString) then
      begin
        Val(ZoneString, ZoneIndex, Result1);

        if (ZoneIndex > 0) and (ZoneIndex <= 100) then
          inc(CountryMultTotals^[Band, ZoneIndex].TotalQSOs);
      end;
    end;

  until Eof(FileRead);
  Close(FileRead);

//  GoToXY(1, WhereY);
//  ClrEol;

  GenerateZoneMultiplierTotals := true;
end;

procedure PrintFirstCountryMultiplierCallsigns;

var
  Lines, Count, NumberFillerSpaces, CountryIndex: integer;
  TempString, FileName: Str80;
  FileWrite         : Text;
  Destination       : Char;

begin
{  repeat
    Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
    case Destination of
      'F': begin
          WriteLn;
          FileName := UpperCase(GetResponse('Enter filename to save multiplier report to : '));

          if FileName = UpperCase(LogFileName) then
          begin
            SHOWMESSAGE('Output file must be different than active log file!!');
//            WaitForKeyPressed;
            exit;
          end;

          if FileName = '' then exit;
        end;
      'S': FileName := '';
      'P': FileName := 'PRN';
      EscapeKey: exit;
    end;
  until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
  WriteLn;
}
  FileName := postform.CBBFNEdit.Text;
  if FileName = UpperCase(LogFileName) then
  begin
    ShowMessage('Output file must be different than active log file!!');
    Exit;
  end;
  if FileName = '' then Exit;

  OpenFileForWrite(FileWrite, FileName);

  //if Header = '' then
  Header := GetResponse('Enter contest name and callsign : ');

  Lines := 0;

  WriteLnVarCenter(FileWrite, 'COUNTRIES WORKED - WITH CALL OF FIRST STATION WORKED');
  WriteLn(FileWrite);
  WriteLnVarCenter(FileWrite, Header);
  WriteLn(FileWrite);

  WriteLn(FileWrite, 'Prefix   160        80          40          20          15          10');
  WriteLn(FileWrite, '------ --------   --------    --------    --------    --------    --------');

  Lines := 5;

  CountryIndex := 0;

  while CountryTable.GetCountryID(CountryIndex) <> '' do
  begin

    if (CountryMultTotals^[Band160, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band80, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band40, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band20, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band15, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band10, CountryIndex].TotalQSOs > 0) then

    begin
      if Lines >= 55 then
      begin
        Write(FileWrite, ' ');

        WriteLnVarCenter(FileWrite, 'COUNTRIES WORKED - WITH CALL OF FIRST STATION WORKED');
        WriteLn(FileWrite);
        WriteLnVarCenter(FileWrite, Header);
        WriteLn(FileWrite);
        WriteLn(FileWrite, 'Prefix   160        80          40          20          15          10');
        WriteLn(FileWrite, '------ --------   --------    --------    --------    --------    --------');
        Lines := 5;
      end;

      TempString := CountryTable.GetCountryID(CountryIndex);

      while length(TempString) < 6 do TempString := ' ' + TempString;

      TempString := TempString + ' ';

      if CountryMultTotals^[Band160, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + CountryMultTotals^[Band160, CountryIndex].FirstCall;

      while length(TempString) < 18 do TempString := TempString + ' ';

      if CountryMultTotals^[Band80, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + CountryMultTotals^[Band80, CountryIndex].FirstCall;

      while length(TempString) < 30 do TempString := TempString + ' ';

      if CountryMultTotals^[Band40, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + CountryMultTotals^[Band40, CountryIndex].FirstCall;

      while length(TempString) < 42 do TempString := TempString + ' ';

      if CountryMultTotals^[Band20, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + CountryMultTotals^[Band20, CountryIndex].FirstCall;

      while length(TempString) < 54 do TempString := TempString + ' ';

      if CountryMultTotals^[Band15, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + CountryMultTotals^[Band15, CountryIndex].FirstCall;

      while length(TempString) < 66 do TempString := TempString + ' ';

      if CountryMultTotals^[Band10, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + CountryMultTotals^[Band10, CountryIndex].FirstCall;

      WriteLn(FileWrite, TempString);
      inc(Lines);
    end;

    inc(CountryIndex);
  end;

  Write(FileWrite, ' ');
  Close(FileWrite);
  view(FileName);
end;

procedure PrintFirstZoneMultiplierCallsigns;

var
  Lines, Count, NumberFillerSpaces, MaxNumberOfZones, ZoneIndex: integer;
  TempString, FileName: Str80;
  FileWrite         : Text;
  Destination       : Char;
  Band              : BandType;

begin
{  repeat
    Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
    case Destination of
      'F': begin
          WriteLn;
          FileName := UpperCase(GetResponse('Enter filename to save multiplier report to : '));

          if FileName = UpperCase(LogFileName) then
          begin
            SHOWMESSAGE('Output file must be different than active log file!!');
//            WaitForKeyPressed;
            exit;
          end;

          if FileName = '' then exit;
        end;
      'S': FileName := '';
      'P': FileName := 'PRN';
      EscapeKey: exit;
    end;
  until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
  WriteLn;

}
  FileName := postform.ZBBEdit.Text;
  if FileName = UpperCase(LogFileName) then
  begin
    ShowMessage('Output file must be different than active log file!!');
    Exit;
  end;
  if FileName = '' then Exit;

  OpenFileForWrite(FileWrite, FileName);

//  if Header = '' then
  Header := GetResponse('Enter contest name and callsign : ');

  Lines := 0;

  WriteLnVarCenter(FileWrite, 'ZONES WORKED - WITH CALL OF FIRST STATION WORKED');
  WriteLn(FileWrite);
  WriteLnVarCenter(FileWrite, Header);
  WriteLn(FileWrite);
  WriteLn(FileWrite, 'Zone   160        80          40          20          15          10');
  WriteLn(FileWrite, '---- --------   --------    --------    --------    --------    --------');

  Lines := 5;

  MaxNumberOfZones := 40;

  for Band := Band160 to Band10 do
    for ZoneIndex := 41 to 100 do
      if CountryMultTotals^[Band, ZoneIndex].TotalQSOs > 0 then
        MaxNumberOfZones := ZoneIndex;

  if (MaxNumberOfZones > 40) then
    if MaxNumberOfZones <= 75 then
      MaxNumberOfZones := 75
    else
      MaxNumberOfZones := 100;

  for ZoneIndex := 1 to MaxNumberOfZones do
  begin
    if Lines >= 55 then
    begin
      Write(FileWrite, ' ');

      WriteLnVarCenter(FileWrite, 'ZONES WORKED - WITH CALL OF FIRST STATION WORKED');
      WriteLn(FileWrite);
      WriteLnVarCenter(FileWrite, Header);
      WriteLn(FileWrite);
      WriteLn(FileWrite, 'Zone   160        80          40          20          15          10');
      WriteLn(FileWrite, '---- --------   --------    --------    --------    --------    --------');
      Lines := 5;
    end;

    Str(ZoneIndex: 3, TempString);

    TempString := TempString + '  ';

    if CountryMultTotals^[Band160, ZoneIndex].TotalQSOs > 0 then
      TempString := TempString + CountryMultTotals^[Band160, ZoneIndex].FirstCall;

    while length(TempString) < 16 do TempString := TempString + ' ';

    if CountryMultTotals^[Band80, ZoneIndex].TotalQSOs > 0 then
      TempString := TempString + CountryMultTotals^[Band80, ZoneIndex].FirstCall;

    while length(TempString) < 28 do TempString := TempString + ' ';

    if CountryMultTotals^[Band40, ZoneIndex].TotalQSOs > 0 then
      TempString := TempString + CountryMultTotals^[Band40, ZoneIndex].FirstCall;

    while length(TempString) < 40 do TempString := TempString + ' ';

    if CountryMultTotals^[Band20, ZoneIndex].TotalQSOs > 0 then
      TempString := TempString + CountryMultTotals^[Band20, ZoneIndex].FirstCall;

    while length(TempString) < 52 do TempString := TempString + ' ';

    if CountryMultTotals^[Band15, ZoneIndex].TotalQSOs > 0 then
      TempString := TempString + CountryMultTotals^[Band15, ZoneIndex].FirstCall;

    while length(TempString) < 64 do TempString := TempString + ' ';

    if CountryMultTotals^[Band10, ZoneIndex].TotalQSOs > 0 then
      TempString := TempString + CountryMultTotals^[Band10, ZoneIndex].FirstCall;

    WriteLn(FileWrite, TempString);
    inc(Lines);
  end;

  Write(FileWrite, ' ');
  Close(FileWrite);
  view(FileName);
end;

procedure PrintQSOsByCountry;

var
  Lines, Count, NumberFillerSpaces, CountryIndex: integer;
  TempString, FileName: Str80;
  FileWrite         : Text;
  Destination       : Char;
  TotalCountryQSOs  : LONGINT;

begin
{  repeat
    Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
    case Destination of
      'F': begin
          WriteLn;
          FileName := UpperCase(GetResponse('Enter filename to save multiplier report to : '));

          if FileName = UpperCase(LogFileName) then
          begin
            SHOWMESSAGE('Output file must be different than active log file!!');
//            WaitForKeyPressed;
            exit;
          end;

          if FileName = '' then exit;
        end;
      'S': FileName := '';
      'P': FileName := 'PRN';
      EscapeKey: exit;
    end;
  until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
  WriteLn;
}

  FileName := postform.CBBEdit.Text;
  if FileName = UpperCase(LogFileName) then
  begin
    ShowMessage('Output file must be different than active log file!!');
    Exit;
  end;

  if FileName = '' then Exit;

  OpenFileForWrite(FileWrite, FileName);

//  if Header = '' then
  Header := GetResponse('Enter contest name and callsign : ');

  WriteLnVarCenter(FileWrite, 'QSOs MADE IN EACH COUNTRY');
  WriteLn(FileWrite);
  WriteLnVarCenter(FileWrite, Header);
  WriteLn(FileWrite);
  WriteLn(FileWrite, '          Prefix  160   80    40    20    15    10   Total  Percent');
  WriteLn(FileWrite, '          ------  ---  ----  ----  ----  ----  ----  -----  -------');

  Lines := 5;

  CountryIndex := 0;

  while CountryTable.GetCountryID(CountryIndex) <> '' do
  begin

    if (CountryMultTotals^[Band160, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band80, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band40, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band20, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band15, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band10, CountryIndex].TotalQSOs > 0) then

    begin
      if Lines >= 55 then
      begin
        Write(FileWrite, ' ');

        WriteLn(FileWrite, '                         QSOs MADE IN EACH COUNTRY');
        WriteLnVarCenter(FileWrite, Header);
        WriteLn(FileWrite);
        WriteLn(FileWrite, '          Prefix  160   80    40    20    15    10   Total  Percent');
        WriteLn(FileWrite, '          ------  ---  ----  ----  ----  ----  ----  -----  -------');

        Lines := 5;
      end;

      TempString := CountryTable.GetCountryID(CountryIndex);

      while length(TempString) < 6 do TempString := ' ' + TempString;

      Write(FileWrite, '          ', TempString + ' ');

      if CountryMultTotals^[Band160, CountryIndex].TotalQSOs > 0 then
        Write(FileWrite, CountryMultTotals^[Band160, CountryIndex].TotalQSOs: 4)
      else
        Write(FileWrite, '   -');

      if CountryMultTotals^[Band80, CountryIndex].TotalQSOs > 0 then
        Write(FileWrite, CountryMultTotals^[Band80, CountryIndex].TotalQSOs: 6)
      else
        Write(FileWrite, '     -');

      if CountryMultTotals^[Band40, CountryIndex].TotalQSOs > 0 then
        Write(FileWrite, CountryMultTotals^[Band40, CountryIndex].TotalQSOs: 6)
      else
        Write(FileWrite, '     -');

      if CountryMultTotals^[Band20, CountryIndex].TotalQSOs > 0 then
        Write(FileWrite, CountryMultTotals^[Band20, CountryIndex].TotalQSOs: 6)
      else
        Write(FileWrite, '     -');

      if CountryMultTotals^[Band15, CountryIndex].TotalQSOs > 0 then
        Write(FileWrite, CountryMultTotals^[Band15, CountryIndex].TotalQSOs: 6)
      else
        Write(FileWrite, '     -');

      if CountryMultTotals^[Band10, CountryIndex].TotalQSOs > 0 then
        Write(FileWrite, CountryMultTotals^[Band10, CountryIndex].TotalQSOs: 6)
      else
        Write(FileWrite, '     -');

      TotalCountryQSOs := CountryMultTotals^[Band160, CountryIndex].TotalQSOs +
        CountryMultTotals^[Band80, CountryIndex].TotalQSOs +
        CountryMultTotals^[Band40, CountryIndex].TotalQSOs +
        CountryMultTotals^[Band20, CountryIndex].TotalQSOs +
        CountryMultTotals^[Band15, CountryIndex].TotalQSOs +
        CountryMultTotals^[Band10, CountryIndex].TotalQSOs;

      Write(FileWrite, TotalCountryQSOs: 7);

      WriteLn(FileWrite, ((TotalCountryQSOs * 100) / TotalLogQSOs): 8: 2);
      inc(Lines);
    end;

    inc(CountryIndex);
  end;

  Write(FileWrite, ' ');
  Close(FileWrite);
  view(FileName);
end;

procedure PrintQSOsByZone;

var
  Lines, Count, NumberFillerSpaces, ZoneIndex, MaxNumberOfZones: integer;
  TempString, FileName: Str80;
  FileWrite         : Text;
  Destination       : Char;
  TotalZoneQSOs     : LONGINT;
  Band              : BandType;

begin
{  repeat
    Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
    case Destination of
      'F': begin
          WriteLn;
          FileName := UpperCase(GetResponse('Enter filename to save multiplier report to : '));

          if FileName = UpperCase(LogFileName) then
          begin
            SHOWMESSAGE('Output file must be different than active log file!!');
//            WaitForKeyPressed;
            exit;
          end;

          if FileName = '' then exit;
        end;
      'S': FileName := '';
      'P': FileName := 'PRN';
      EscapeKey: exit;
    end;
  until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
  WriteLn;
}

  FileName := postform.TotZBBEdit.Text;

  if FileName = UpperCase(LogFileName) then
  begin
    ShowMessage('Output file must be different than active log file!!');
    Exit;
  end;

  if FileName = '' then Exit;

  OpenFileForWrite(FileWrite, FileName);

//  if Header = '' then
  Header := GetResponse('Enter contest name and callsign : ');

  WriteLnVarCenter(FileWrite, 'QSOs MADE IN EACH ZONE');
  WriteLn(FileWrite);
  WriteLnVarCenter(FileWrite, Header);
  WriteLn(FileWrite);
  WriteLn(FileWrite, '          Zone  160   80    40    20    15    10   Total  Percent');
  WriteLn(FileWrite, '          ----  ---  ----  ----  ----  ----  ----  -----  -------');

  Lines := 5;

  MaxNumberOfZones := 40;

  for Band := Band160 to Band10 do
    for ZoneIndex := 41 to 100 do
      if CountryMultTotals^[Band, ZoneIndex].TotalQSOs > 0 then
        MaxNumberOfZones := ZoneIndex;

  if (MaxNumberOfZones > 40) then
    if MaxNumberOfZones <= 75 then
      MaxNumberOfZones := 75
    else
      MaxNumberOfZones := 100;

  for ZoneIndex := 1 to MaxNumberOfZones do
  begin
    if Lines >= 55 then
    begin
      Write(FileWrite, ' ');

      WriteLnVarCenter(FileWrite, '                        QSOs MADE IN EACH ZONE');
      WriteLn(FileWrite);
      WriteLnVarCenter(FileWrite, Header);
      WriteLn(FileWrite);
      WriteLn(FileWrite, '          Zone  160   80    40    20    15   10   Total  Percent');
      WriteLn(FileWrite, '          ----  ---  ----  ----  ----  ---- ----  -----  -------');

      Lines := 5;
    end;

    Str(ZoneIndex: 3, TempString);

    TempString := TempString + '  ';

    Write(FileWrite, '          ', TempString);

    if CountryMultTotals^[Band160, ZoneIndex].TotalQSOs > 0 then
      Write(FileWrite, CountryMultTotals^[Band160, ZoneIndex].TotalQSOs: 4)
    else
      Write(FileWrite, '   -');

    if CountryMultTotals^[Band80, ZoneIndex].TotalQSOs > 0 then
      Write(FileWrite, CountryMultTotals^[Band80, ZoneIndex].TotalQSOs: 6)
    else
      Write(FileWrite, '     -');

    if CountryMultTotals^[Band40, ZoneIndex].TotalQSOs > 0 then
      Write(FileWrite, CountryMultTotals^[Band40, ZoneIndex].TotalQSOs: 6)
    else
      Write(FileWrite, '     -');

    if CountryMultTotals^[Band20, ZoneIndex].TotalQSOs > 0 then
      Write(FileWrite, CountryMultTotals^[Band20, ZoneIndex].TotalQSOs: 6)
    else
      Write(FileWrite, '     -');

    if CountryMultTotals^[Band15, ZoneIndex].TotalQSOs > 0 then
      Write(FileWrite, CountryMultTotals^[Band15, ZoneIndex].TotalQSOs: 6)
    else
      Write(FileWrite, '     -');

    if CountryMultTotals^[Band10, ZoneIndex].TotalQSOs > 0 then
      Write(FileWrite, CountryMultTotals^[Band10, ZoneIndex].TotalQSOs: 6)
    else
      Write(FileWrite, '     -');

    TotalZoneQSOs := CountryMultTotals^[Band160, ZoneIndex].TotalQSOs +
      CountryMultTotals^[Band80, ZoneIndex].TotalQSOs +
      CountryMultTotals^[Band40, ZoneIndex].TotalQSOs +
      CountryMultTotals^[Band20, ZoneIndex].TotalQSOs +
      CountryMultTotals^[Band15, ZoneIndex].TotalQSOs +
      CountryMultTotals^[Band10, ZoneIndex].TotalQSOs;

    Write(FileWrite, TotalZoneQSOs: 7);

    WriteLn(FileWrite, ((TotalZoneQSOs * 100) / TotalLogQSOs): 8: 2);
    inc(Lines);
  end;

  Write(FileWrite, ' ');
  Close(FileWrite);
  view(FileName);
end;

procedure MultiplierCheckOffSheet;

var
  Destination, Key  : Char;
  TempString        : Str80;
  FileName          : string;
  DoAllMults        : boolean;
  MaxNumberOfZones, CountryIndex, ZoneIndex, NumberReportEntries: integer;
  RealAddress       : integer;
  Band              : BandType;
  FileWrite         : Text;

begin
{
//  ClrScr;
//  TextColor(Yellow);
  WriteLnCenter('MULTIPLIER CHECK OFF SHEET');
//  TextColor(Cyan);
  WriteLn;
  WriteLn('This report will generate a check off sheet showing the country and zone ');
  WriteLn('multipliers that have been worked.');
  WriteLn;

  repeat
    Key := UpCase(GetKey('Use (C)Q or (A)RRL countries? (C/A) : '));
    if Key = EscapeKey then exit;
  until (Key = 'C') or (Key = 'A');
  WriteLn;
}

  if postform.CQ_ARRL.ItemIndex = 0 then
//  if Key = 'C' then
    CountryTable.CountryMode := CQCountryMode
  else
//  begin
    CountryTable.CountryMode := ARRLCountryMode;

{    repeat
      Key := UpCase(GetKey('Use IARU zones? (Y/N): '));
      if Key = EscapeKey then exit;
    until (Key = 'Y') or (Key = 'N');
    WriteLn;

    if Key = 'Y' then
}
  if postform.UseIARUzcb.Checked then
    CountryTable.ZoneMode := ITUZoneMode
  else
    CountryTable.ZoneMode := CQZoneMode;
//  end;
{
  repeat
    Key := UpCase(GetKey('Do (A)ll multiplier or only ones (W)orked? (A/W) : '));
    if Key = EscapeKey then exit;
  until (Key = 'A') or (Key = 'W');
  WriteLn;
}

  DoAllMults := postform.ALL_ONE_mult.ItemIndex = 0;

//  if Header = '' then
  Header := postform.CN.Text;
{
  repeat
    Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
    case Destination of
      'F': begin
          WriteLn;
          FileName := UpperCase(GetResponse('Enter filename to save multiplier report to : '));

          if FileName = UpperCase(LogFileName) then
          begin
            SHOWMESSAGE('Output file must be different than active log file!!');
//            WaitForKeyPressed;
            exit;
          end;

          if FileName = '' then exit;
        end;
      'S': FileName := '';
      'P': FileName := 'PRN';
      EscapeKey: exit;
    end;
  until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
  WriteLn;
}

  FileName := postform.FnMCOSedit.Text;
  if FileName = UpperCase(LogFileName) then
  begin
    ShowMessage('Output file must be different than active log file!!');
    Exit;
  end;
  if FileName = '' then Exit;

  New(CountryMultTotals);

  if not GenerateCountryMultiplierTotals then Exit;

  OpenFileForWrite(FileWrite, FileName);

  New(ReportEntries);
  NumberReportEntries := 0;

  CountryIndex := 0;

  while CountryTable.GetCountryID(CountryIndex) <> '' do
  begin
    if (CountryMultTotals^[Band160, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band80, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band40, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band20, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band15, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band10, CountryIndex].TotalQSOs > 0) or DoAllMults then
    begin
      TempString := CountryTable.GetCountryID(CountryIndex);

      while length(TempString) < 5 do TempString := ' ' + TempString;
      TempString := TempString + ' ';

      if CountryMultTotals^[Band160, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      if CountryMultTotals^[Band80, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      if CountryMultTotals^[Band40, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      if CountryMultTotals^[Band20, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      if CountryMultTotals^[Band15, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      if CountryMultTotals^[Band10, CountryIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      ReportEntries^[NumberReportEntries] := TempString;
      inc(NumberReportEntries);
    end;

    inc(CountryIndex);
  end;

  while (NumberReportEntries mod 50) <> 0 do
  begin
    ReportEntries^[NumberReportEntries] := '            ';
    inc(NumberReportEntries);
  end;

  if not GenerateZoneMultiplierTotals then Exit;

  MaxNumberOfZones := 40;

  for Band := Band160 to Band10 do
    for ZoneIndex := 41 to 100 do
      if CountryMultTotals^[Band, ZoneIndex].TotalQSOs > 0 then
        MaxNumberOfZones := ZoneIndex;

  if (MaxNumberOfZones > 40) then
    if MaxNumberOfZones <= 75 then
      MaxNumberOfZones := 75
    else
      MaxNumberOfZones := 100;

  for ZoneIndex := 1 to MaxNumberOfZones do
    if (CountryMultTotals^[Band160, ZoneIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band80, ZoneIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band40, ZoneIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band20, ZoneIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band15, ZoneIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band10, ZoneIndex].TotalQSOs > 0) or DoAllMults then
    begin
      Str(ZoneIndex, TempString);

      while length(TempString) < 5 do TempString := ' ' + TempString;
      TempString := TempString + ' ';

      if CountryMultTotals^[Band160, ZoneIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      if CountryMultTotals^[Band80, ZoneIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      if CountryMultTotals^[Band40, ZoneIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      if CountryMultTotals^[Band20, ZoneIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      if CountryMultTotals^[Band15, ZoneIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      if CountryMultTotals^[Band10, ZoneIndex].TotalQSOs > 0 then
        TempString := TempString + 'X'
      else
        TempString := TempString + '_';

      ReportEntries^[NumberReportEntries] := TempString;
      inc(NumberReportEntries);
    end;

  if NumberReportEntries <= 300 then
  begin
    WriteLnVarCenter(FileWrite, 'MULTIPLIER CHECK OFF SHEET');
    WriteLn(FileWrite);
    WriteLnVarCenter(FileWrite, Header);
    WriteLn(FileWrite);
  end
  else
  begin
    WriteLnVarCenter(FileWrite, 'MULTIPLIER CHECK OFF SHEET - Page 1');
    WriteLn(FileWrite);
    WriteLnVarCenter(FileWrite, Header);
    WriteLn(FileWrite);
  end;

  for CountryIndex := 0 to 299 do
  begin
    RealAddress := ((CountryIndex mod 6) * 50) + (CountryIndex div 6);

        { Only print if there is really a call there }

    if RealAddress < NumberReportEntries then
      Write(FileWrite, ReportEntries^[RealAddress])
    else
      Write(FileWrite, '           ');

    if (CountryIndex + 1) mod 6 = 0 then WriteLn(FileWrite);

    ReportEntries^[RealAddress] := '';
  end;

  WriteLn(FileWrite, ' ');

  if NumberReportEntries > 300 then
  begin
    WriteLnVarCenter(FileWrite, 'MULTIPLIER CHECK OFF SHEET - Page 2');
    WriteLn(FileWrite);
    WriteLnVarCenter(FileWrite, Header);
    WriteLn(FileWrite);

    for CountryIndex := 0 to (NumberReportEntries - 301) do
      ReportEntries^[CountryIndex] := ReportEntries^[CountryIndex + 300];

    NumberReportEntries := NumberReportEntries - 300;

    for CountryIndex := 0 to 299 do
    begin
      RealAddress := ((CountryIndex mod 6) * 50) + (CountryIndex div 6);

        { Only print if there is really a call there }

      if RealAddress < NumberReportEntries then
        Write(FileWrite, ReportEntries^[RealAddress])
      else
        Write(FileWrite, '            ');

      if (CountryIndex + 1) mod 6 = 0 then WriteLn(FileWrite);

      ReportEntries^[RealAddress] := '';
    end;

    WriteLn(FileWrite, ' ');
  end;

  Close(FileWrite);
  Dispose(ReportEntries);

  view(FileName);
end;

function ProcessLogEntryForTimeOnBandInformation(Band: BandType;
  Mode: ModeType;
  TimeString: Str20;
  DateString: Str20;
  HourIndex: integer): boolean;

{ This procedure will look at the band/mode/time of each QSO and determine
  how to accumulate the on time for each band (in the global LogHourTotals.

  Returns FALSE if an error was found (illegal time). }

var
  TempTimeString    : Str80;
  TempDateString    : Str20;
  NumberMinutesSinceLastEntry: integer;
  TempBand          : BandType;

begin
  ProcessLogEntryForTimeOnBandInformation := true;

  with PLeftOnBiState do
  begin

        { First, see if it is the same minute as previously processed }

    if ((TimeString = LastTimeString) and (DateString = LastDateString)) or
      (LastTimeString = '') then
    begin
      if not BandsThisMinute[Band] then
      begin
        BandsThisMinute[Band] := true;
        inc(LogHourTotals^[HourIndex].Minutes[Band, Both]);
      end;

      if LastTimeString = '' then
        inc(LogHourTotals^[HourIndex].Minutes[All, Both]);

      LastMode := Mode;
      LastBand := Band;
      LastTimeString := TimeString;
      LastDateString := DateString;
      LastHourIndex := HourIndex;
      Exit;
    end;

        { We are processing a new minute, so make sure BandsThisMinute
          is all cleared out. }

    for TempBand := Band160 to NoBand do
      BandsThisMinute[TempBand] := False;

        { See how long it has been since the last log entry }

    TempTimeString := LastTimeString;
    TempDateString := LastDateString;
    NumberMinutesSinceLastEntry := 0;

    while (TempTimeString <> TimeString) or (TempDateString <> DateString) do
    begin
      IncrementMinute(TempDateString, TempTimeString);
      inc(NumberMinutesSinceLastEntry);

            { See if this count has overflowed }

      if NumberMinutesSinceLastEntry = 0 then
      begin
        ProcessLogEntryForTimeOnBandInformation := False;
        Exit;
      end;
    end;

        { Check number of minutes to see if this should be counted as a
          break or not (15 or more minutes) }

    if NumberMinutesSinceLastEntry < 15 then
    begin

            { Fill in the previous minutes with the last band }

      if LastHourIndex <> HourIndex then
        while not (PostcedingString(LastTimeString, ':') = '59') do
        begin
          IncrementMinute(LastDateString, LastTimeString);

                { If not at the current minute, increment minute totals }

          inc(LogHourTotals^[LastHourIndex].Minutes[LastBand, Both]);
          inc(LogHourTotals^[LastHourIndex].Minutes[All, Both]);
        end;

            { We are now pointing to the last minute processed }

            { Now work on this hour - fill up any previously unassigned minutes
              with the LastBand and LastMode }

      while (LastDateString <> DateString) or (LastTimeString <> TimeString) do
      begin
        IncrementMinute(LastDateString, LastTimeString);

                { If not at the current minute - increment totals }

        if (LastDateString <> DateString) or (LastTimeString <> TimeString) then
        begin
          inc(LogHourTotals^[HourIndex].Minutes[LastBand, Both]);
          inc(LogHourTotals^[HourIndex].Minutes[All, Both]);
        end;
      end;

            { We should now be pointing to the current minute }
    end;

    if not BandsThisMinute[Band] then
    begin
      inc(LogHourTotals^[HourIndex].Minutes[Band, Both]);
      inc(LogHourTotals^[HourIndex].Minutes[All, Both]);
      BandsThisMinute[Band] := true;
    end;

    LastBand := Band;
    LastMode := Mode;
    LastTimeString := TimeString;
    LastDateString := DateString;
    LastHourIndex := HourIndex;
  end;
end;

procedure FinishOutLastHour;

{ This routine will look at the last QSO processed by the PLeftOnBiState
  machine to see if we should fill in the last few minutes of the contest
  with the band of the last QSO.  This is done if the interval is less
  than 10 minutes. }

var
  LastMinuteString  : Str20;
  Minute, LastMinute, Result: integer;

begin
  with PLeftOnBiState do
  begin

    LastMinuteString := PostcedingString(LastTimeString, ':');

    Val(LastMinuteString, LastMinute, Result);

    if (LastMinute >= 50) and (LastMinute < 59) then
      for Minute := LastMinute + 1 to 59 do
      begin
        inc(LogHourTotals^[LastHourIndex].Minutes[LastBand, Both]);
        inc(LogHourTotals^[LastHourIndex].Minutes[All, Both]);
      end;

  end;
end;

procedure CheckTimeOnByBand(LastHour: integer);

{ This procedure will look through the LogHourTotals to make sure that the
  individual band on times add up to the hourly on time (as indicated in
  the All, Both cell).  If the total of the band times exceeds that of
  the All, Both number, the band will the longest on time during the
  hour will have its time adjusted to make the total come out correctly. }

var
  Correction, HourTotal, BiggestBandTotal, HourIndex: integer;
  Band, BiggestBand : BandType;

begin
  for HourIndex := 0 to LastHour do
  begin
    HourTotal := 0;
    BiggestBand := NoBand;
    BiggestBandTotal := 0;

    for Band := Band160 to BandLight do
    begin
      HourTotal := HourTotal + LogHourTotals^[HourIndex].Minutes[Band, Both];

      if LogHourTotals^[HourIndex].Minutes[Band, Both] > BiggestBandTotal then
      begin
        BiggestBandTotal := LogHourTotals^[HourIndex].Minutes[Band, Both];
        BiggestBand := Band;
      end;
    end;

    Correction := LogHourTotals^[HourIndex].Minutes[All, Both] - HourTotal;

    if Correction <> 0 then
      LogHourTotals^[HourIndex].Minutes[BiggestBand, Both] :=
        LogHourTotals^[HourIndex].Minutes[BiggestBand, Both] + Correction;

  end;
end;

function GenerateAllTotalsPerHour: boolean;

{ This routine will fill up the global variable LogHourTotals with data. }

var
  FileRead          : Text;
  TempString        : Str80;
  FileString        : string;
  Band              : BandType;
  Mode              : ModeType;
  LineNumber, CurrentHourIndex, Result1, HourIndex, Minute, QSOPoints: integer;
  TotalLogQSOs      : LONGINT;
  HourString, MinuteString, CallString, LastHourProcessed: Str20;
  MultString        : string;

begin
  for HourIndex := 0 to 49 do
  begin

    LogHourTotals^[HourIndex].HourName := '';

    for Band := Band160 to NoBand do
      for Mode := cw to NoMode do
        with LogHourTotals^[HourIndex] do
        begin
          QSOs[Band, Mode] := 0;
          QSOPoints[Band, Mode] := 0;
          Mults[Band, Mode] := 0;
          Minutes[Band, Mode] := 0;
        end;
  end;

    { Initialize the time on band status }

  with PLeftOnBiState do
  begin
    LastBand := NoBand;
    LastMode := NoMode;
    LastDateString := '';
    LastTimeString := '';
    ;
    LastHourIndex := -1;
    DoingBreak := False;

    for Band := Band160 to NoBand do
      PLeftOnBiState.BandsThisMinute[Band] := False;
  end;

  GenerateAllTotalsPerHour := False; { Default return value }

  if not OpenFileForRead(FileRead, LogFileName) then
  begin
    ShowMessage(LogFileName + ' file not found!!');
//    WaitForKeyPressed;
    Exit;
  end;

    { Initialize variables }

  CurrentHourIndex := 0;
  LastHourProcessed := '';
  NumberLogHours := 0;
  TotalLogQSOs := 0;
  LineNumber := 0;

//  WriteLn('Searching log file for hourly totals...');

    { Look through the log file and process each QSO }

  repeat
    repeat
      ReadLn(FileRead, FileString);
      Band := GetLogEntryBand(FileString);
      Mode := GetLogEntryMode(FileString);
      inc(LineNumber);

    until ((Band <> NoBand) and (Mode <> NoMode)) or EOF(FileRead);

    if (Band <> NoBand) and (Mode <> NoMode) then
    begin
//      PinWheel;
      CallString := GetLogEntryCall(FileString);
      HourString := PrecedingString(GetLogEntryTimeString(FileString), ':');
      MinuteString := PostcedingString(GetLogEntryTimeString(FileString), ':');

      Val(MinuteString, Minute, Result1);

      if LastHourProcessed <> HourString then
      begin
        if CurrentHourIndex = 49 then
        begin
          ShowMessage('More than 50 different hours in this log!!');
          halt;
        end;

        if LastHourProcessed <> '' then inc(CurrentHourIndex);

        LogHourTotals^[CurrentHourIndex].HourName := HourString;
        LastHourProcessed := HourString
      end;

      if not ProcessLogEntryForTimeOnBandInformation(Band,
        Mode,
        GetLogEntryTimeString(FileString),
        GetLogEntryDateString(FileString),
        CurrentHourIndex) then

      begin
//        GoToXY(1, WhereY);
//        ClrEol;
        Str(LineNumber, TempString);
        ShowMessage('Error found at line ' + TempString + '.  Check time and date format.' + #13 + FileString);
//        WriteLn(FileString);
        Close(FileRead);
        Exit;
      end;

      if not (StringHas(FileString, '*DUPE*') or StringHas(FileString, '*ZERO*')) then
      begin
        ExpandTabs(FileString);
        inc(TotalLogQSOs);

        inc(LogHourTotals^[CurrentHourIndex].QSOs[Band, Mode]);
        inc(LogHourTotals^[CurrentHourIndex].QSOs[All, Mode]);
        inc(LogHourTotals^[CurrentHourIndex].QSOs[Band, Both]);
        inc(LogHourTotals^[CurrentHourIndex].QSOs[All, Both]);

        QSOPoints := GetLogEntryQSOPoints(FileString);

        LogHourTotals^[CurrentHourIndex].QSOPoints[Band, Mode] :=
          LogHourTotals^[CurrentHourIndex].QSOPoints[Band, Mode] + QSOPoints;

        LogHourTotals^[CurrentHourIndex].QSOPoints[All, Mode] :=
          LogHourTotals^[CurrentHourIndex].QSOPoints[All, Mode] + QSOPoints;

        LogHourTotals^[CurrentHourIndex].QSOPoints[Band, Both] :=
          LogHourTotals^[CurrentHourIndex].QSOPoints[Band, Both] + QSOPoints;

        LogHourTotals^[CurrentHourIndex].QSOPoints[All, Both] :=
          LogHourTotals^[CurrentHourIndex].QSOPoints[All, Both] + QSOPoints;

        MultString := GetLogEntryMultString(FileString);

        while MultString <> '' do
        begin
          inc(LogHourTotals^[CurrentHourIndex].Mults[Band, Mode]);
          inc(LogHourTotals^[CurrentHourIndex].Mults[All, Mode]);
          inc(LogHourTotals^[CurrentHourIndex].Mults[Band, Both]);
          inc(LogHourTotals^[CurrentHourIndex].Mults[All, Both]);
          RemoveFirstString(MultString);
        end;
      end;
    end;

  until Eof(FileRead);

//  GoToXY(1, WhereY);
//  ClrEol;

  FinishOutLastHour;
  CheckTimeOnByBand(CurrentHourIndex);

  Close(FileRead);
  GenerateAllTotalsPerHour := true;
//  GoToXY(1, WhereY);
//  ClrEol;
end;

procedure PrintHourTotals;

var
  Destination       : Char;
  FileWrite         : Text;
  Band              : BandType;
  TempString, FileName: Str80;
  TotalMults, LastHourPrinted, HourIndex, ThisHour, Result: integer;
  TotalQSOPoints, TotalContacts: LONGINT;
  Score             : REAL;
  Day1QSOTotals, Day1MultTotals, Day2QSOTotals, Day2MultTotals: array[Band160..Band10] of LONGINT;
  DoingDay1         : boolean;
  TotalDay1QSOs, TotalDay1Mults, TotalDay2QSOs, TotalDay2Mults: LONGINT;

begin
{  repeat
    Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
    case Destination of
      'F': begin
          WriteLn;
          FileName := UpperCase(GetResponse('Enter filename to save multiplier report to : '));

          if FileName = UpperCase(LogFileName) then
          begin
            SHOWMESSAGE('Output file must be different than active log file!!');
//            WaitForKeyPressed;
            exit;
          end;

          if FileName = '' then exit;
        end;
      'S': FileName := '';
      'P': FileName := 'PRN';
      EscapeKey: exit;
    end;
  until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
  WriteLn;
}

  FileName := postform.MARSEdit.Text;
  if FileName = UpperCase(LogFileName) then
  begin
    ShowMessage('Output file must be different than active log file!!');
    Exit;
  end;

  OpenFileForWrite(FileWrite, FileName);

//  if Header = '' then
  Header := GetResponse('Enter contest name and callsign : ');

  WriteLnVarCenter(FileWrite, Header);
  WriteLn(FileWrite);
  WriteLn(FileWrite, 'HR    160     80       40       20       15       10    HR TOT CUM TOTAL  SCORE');
  WriteLn(FileWrite, '--   -----  ------- -------- -------- -------- -------- ------ ---------  -----');

  HourIndex := 0;

  TotalMults := 0;
  TotalContacts := 0;
  TotalQSOPoints := 0;

  DoingDay1 := true;

  for Band := Band160 to Band10 do
  begin
    Day1QSOTotals[Band] := 0;
    Day1MultTotals[Band] := 0;
    Day2QSOTotals[Band] := 0;
    Day2MultTotals[Band] := 0;
  end;

  while LogHourTotals^[HourIndex].HourName <> '' do
  begin
    inc(LastHourPrinted);

    if (HourIndex > 0) and (LastHourPrinted > 23) then
    begin
      DoingDay1 := False;
      LastHourPrinted := 0;
    end;

    Val(LogHourTotals^[HourIndex].HourName, ThisHour, Result);

    if HourIndex = 0 then LastHourPrinted := ThisHour;

    while ThisHour <> LastHourPrinted do
    begin
      Write(FileWrite, LastHourPrinted: 2);

      for Band := Band160 to Band80 do
        Write(FileWrite, '    --- ');

      for Band := Band40 to Band10 do
        Write(FileWrite, '     --- ');

      Write(FileWrite, '    --- ');

      Write(FileWrite, TotalContacts: 6, '/', TotalMults);

      if TotalMults < 10 then Write(FileWrite, ' ');
      if TotalMults < 100 then Write(FileWrite, ' ');

      Score := TotalQSOPoints * TotalMults / 1000000;

      WriteLn(FileWrite, Score: 6: 2, 'M');

      inc(LastHourPrinted);
      if LastHourPrinted > 23 then LastHourPrinted := 0;
    end;

    TotalContacts := TotalContacts + LogHourTotals^[HourIndex].QSOs[All, Both];
    TotalMults := TotalMults + LogHourTotals^[HourIndex].Mults[All, Both];
    TotalQSOPoints := TotalQSOPoints + LogHourTotals^[HourIndex].QSOPoints[All, Both];

    if DoingDay1 then
    begin
      Day1QSOTotals[Band160] := Day1QSOTotals[Band160] + LogHourTotals^[HourIndex].QSOs[Band160, Both];
      Day1QSOTotals[Band80] := Day1QSOTotals[Band80] + LogHourTotals^[HourIndex].QSOs[Band80, Both];
      Day1QSOTotals[Band40] := Day1QSOTotals[Band40] + LogHourTotals^[HourIndex].QSOs[Band40, Both];
      Day1QSOTotals[Band20] := Day1QSOTotals[Band20] + LogHourTotals^[HourIndex].QSOs[Band20, Both];
      Day1QSOTotals[Band15] := Day1QSOTotals[Band15] + LogHourTotals^[HourIndex].QSOs[Band15, Both];
      Day1QSOTotals[Band10] := Day1QSOTotals[Band10] + LogHourTotals^[HourIndex].QSOs[Band10, Both];

      Day1MultTotals[Band160] := Day1MultTotals[Band160] + LogHourTotals^[HourIndex].Mults[Band160, Both];
      Day1MultTotals[Band80] := Day1MultTotals[Band80] + LogHourTotals^[HourIndex].Mults[Band80, Both];
      Day1MultTotals[Band40] := Day1MultTotals[Band40] + LogHourTotals^[HourIndex].Mults[Band40, Both];
      Day1MultTotals[Band20] := Day1MultTotals[Band20] + LogHourTotals^[HourIndex].Mults[Band20, Both];
      Day1MultTotals[Band15] := Day1MultTotals[Band15] + LogHourTotals^[HourIndex].Mults[Band15, Both];
      Day1MultTotals[Band10] := Day1MultTotals[Band10] + LogHourTotals^[HourIndex].Mults[Band10, Both];
    end
    else
    begin
      Day2QSOTotals[Band160] := Day2QSOTotals[Band160] + LogHourTotals^[HourIndex].QSOs[Band160, Both];
      Day2QSOTotals[Band80] := Day2QSOTotals[Band80] + LogHourTotals^[HourIndex].QSOs[Band80, Both];
      Day2QSOTotals[Band40] := Day2QSOTotals[Band40] + LogHourTotals^[HourIndex].QSOs[Band40, Both];
      Day2QSOTotals[Band20] := Day2QSOTotals[Band20] + LogHourTotals^[HourIndex].QSOs[Band20, Both];
      Day2QSOTotals[Band15] := Day2QSOTotals[Band15] + LogHourTotals^[HourIndex].QSOs[Band15, Both];
      Day2QSOTotals[Band10] := Day2QSOTotals[Band10] + LogHourTotals^[HourIndex].QSOs[Band10, Both];

      Day2MultTotals[Band160] := Day2MultTotals[Band160] + LogHourTotals^[HourIndex].Mults[Band160, Both];
      Day2MultTotals[Band80] := Day2MultTotals[Band80] + LogHourTotals^[HourIndex].Mults[Band80, Both];
      Day2MultTotals[Band40] := Day2MultTotals[Band40] + LogHourTotals^[HourIndex].Mults[Band40, Both];
      Day2MultTotals[Band20] := Day2MultTotals[Band20] + LogHourTotals^[HourIndex].Mults[Band20, Both];
      Day2MultTotals[Band15] := Day2MultTotals[Band15] + LogHourTotals^[HourIndex].Mults[Band15, Both];
      Day2MultTotals[Band10] := Day2MultTotals[Band10] + LogHourTotals^[HourIndex].Mults[Band10, Both];
    end;

    with LogHourTotals^[HourIndex] do
    begin
      Write(FileWrite, ThisHour: 2);

      for Band := Band160 to Band10 do
      begin
        if Band >= Band40 then
        begin
          if QSOs[Band, Both] > 0 then
          begin
            Write(FileWrite, QSOs[Band, Both]: 6, '/', Mults[Band, Both]);
            if Mults[Band, Both] < 10 then Write(FileWrite, ' ');
          end
          else
            Write(FileWrite, '     --- ');
        end
        else
        begin
          if QSOs[Band, Both] > 0 then
          begin
            Write(FileWrite, QSOs[Band, Both]: 5, '/', Mults[Band, Both]);
            if Mults[Band, Both] < 10 then Write(FileWrite, ' ');
          end
          else
            Write(FileWrite, '    --- ');
        end;
      end;

      Write(FileWrite, QSOs[All, Both]: 5, '/', Mults[All, Both]);

      if Mults[All, Both] < 10 then Write(FileWrite, ' ');

      Write(FileWrite, TotalContacts: 6, '/', TotalMults);

      if TotalMults < 10 then Write(FileWrite, ' ');
      if TotalMults < 100 then Write(FileWrite, ' ');

      Score := TotalQSOPoints * TotalMults / 1000000;

      WriteLn(FileWrite, Score: 6: 2, 'M');
    end;

    Val(LogHourTotals^[HourIndex].HourName, LastHourPrinted, Result);
    inc(HourIndex);
  end;

  TotalDay1QSOs := Day1QSOTotals[Band160] + Day1QSOTotals[Band80] +
    Day1QSOTotals[Band40] + Day1QSOTotals[Band20] +
    Day1QSOTotals[Band15] + Day1QSOTotals[Band10];

  TotalDay1Mults := Day1MultTotals[Band160] + Day1MultTotals[Band80] +
    Day1MultTotals[Band40] + Day1MultTotals[Band20] +
    Day1MultTotals[Band15] + Day1MultTotals[Band10];

  TotalDay2QSOs := Day2QSOTotals[Band160] + Day2QSOTotals[Band80] +
    Day2QSOTotals[Band40] + Day2QSOTotals[Band20] +
    Day2QSOTotals[Band15] + Day2QSOTotals[Band10];

  TotalDay2Mults := Day2MultTotals[Band160] + Day2MultTotals[Band80] +
    Day2MultTotals[Band40] + Day2MultTotals[Band20] +
    Day2MultTotals[Band15] + Day2MultTotals[Band10];

  Write(FileWrite, 'D1');

  for Band := Band160 to Band10 do
    if Band >= Band40 then
    begin
      Write(FileWrite, Day1QSOTotals[Band]: 5, '/', Day1MultTotals[Band]);
      if Day1MultTotals[Band] < 10 then Write(FileWrite, ' ');
      if Day1MultTotals[Band] < 100 then Write(FileWrite, ' ');
    end
    else
    begin
      Write(FileWrite, Day1QSOTotals[Band]: 4, '/', Day1MultTotals[Band]);
      if Day1MultTotals[Band] < 10 then Write(FileWrite, ' ');
      if Day1MultTotals[Band] < 100 then Write(FileWrite, ' ');
    end;

  WriteLn(FileWrite, '        ', TotalDay1QSOs: 6, '/', TotalDay1Mults);

  if not DoingDay1 then
  begin
    Write(FileWrite, 'D2');

    for Band := Band160 to Band10 do
      if Band >= Band40 then
      begin
        Write(FileWrite, Day2QSOTotals[Band]: 5, '/', Day2MultTotals[Band]);
        if Day2MultTotals[Band] < 10 then Write(FileWrite, ' ');
        if Day2MultTotals[Band] < 100 then Write(FileWrite, ' ');
      end
      else
      begin
        Write(FileWrite, Day2QSOTotals[Band]: 4, '/', Day2MultTotals[Band]);
        if Day2MultTotals[Band] < 10 then Write(FileWrite, ' ');
        if Day2MultTotals[Band] < 100 then Write(FileWrite, ' ');
      end;

    WriteLn(FileWrite, '        ', TotalDay2QSOs: 6, '/', TotalDay2Mults);
  end;

  Write(FileWrite, 'TO');

  for Band := Band160 to Band10 do
    if Band >= Band40 then
    begin
      Write(FileWrite, (Day1QSOTotals[Band] + Day2QSOTotals[Band]): 5, '/',
        Day1MultTotals[Band] + Day2MultTotals[Band]);

      if Day1MultTotals[Band] + Day2MultTotals[Band] < 10 then Write(FileWrite, ' ');
      if Day1MultTotals[Band] + Day2MultTotals[Band] < 100 then Write(FileWrite, ' ');
    end
    else
    begin
      Write(FileWrite, (Day1QSOTotals[Band] + Day2QSOTotals[Band]): 4, '/',
        Day1MultTotals[Band] + Day2MultTotals[Band]);
      if Day1MultTotals[Band] + Day2MultTotals[Band] < 10 then Write(FileWrite, ' ');
      if Day1MultTotals[Band] + Day2MultTotals[Band] < 100 then Write(FileWrite, ' ');
    end;

  WriteLn(FileWrite, '        ', TotalDay1QSOs + TotalDay2QSOs: 6, '/', TotalDay1Mults + TotalDay2Mults);

  Write(FileWrite, ' ');
  Close(FileWrite);
  view(FileName);
end;

procedure PrintRateByHourTotals;

var
  Destination       : Char;
  FileWrite         : Text;
  Band              : BandType;
  TempString, RateString, FileName: Str80;
  Rate, TotalMinutes, LastHourPrinted, HourIndex, ThisHour, Result: integer;
  TotalQSOPoints, TotalContacts: LONGINT;
  Score             : REAL;
  Day1QSOTotals, Day1MinTotals, Day2QSOTotals, Day2MinTotals: array[Band160..Band10] of LONGINT;
  DoingDay1         : boolean;
  TotalDay1QSOs, TotalDay1Mins, TotalDay2QSOs, TotalDay2Mins: LONGINT;

begin
{  repeat
    Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
    case Destination of
      'F': begin
          WriteLn;
          FileName := UpperCase(GetResponse('Enter filename to save multiplier report to : '));

          if FileName = UpperCase(LogFileName) then
          begin
            SHOWMESSAGE('Output file must be different than active log file!!');
//            WaitForKeyPressed;
            exit;
          end;

          if FileName = '' then exit;
        end;
      'S': FileName := '';
      'P': FileName := 'PRN';
      EscapeKey: exit;
    end;
  until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
  WriteLn;
}

  FileName := postform.BBHREdit.Text;

  if FileName = UpperCase(LogFileName) then
  begin
    ShowMessage('Output file must be different than active log file!!');
    Exit;
  end;

  if FileName = '' then Exit;

  OpenFileForWrite(FileWrite, FileName);

  if Header = '' then
    Header := GetResponse('Enter contest name and callsign : ');

  WriteLnVarCenter(FileWrite, 'Minutes / Rate Summary  ' + Header);
  WriteLn(FileWrite);

  WriteLn(FileWrite, 'HR     160      80       40       20       15       10    HR TOT   CUM TOTAL');
  WriteLn(FileWrite, '--   ------   ------   ------   ------   ------   ------  ------   ---------');

  HourIndex := 0;

  TotalMinutes := 0;
  TotalContacts := 0;
  TotalQSOPoints := 0;

  DoingDay1 := true;

  for Band := Band160 to Band10 do
  begin
    Day1QSOTotals[Band] := 0;
    Day1MinTotals[Band] := 0;
    Day2QSOTotals[Band] := 0;
    Day2MinTotals[Band] := 0;
  end;

  while LogHourTotals^[HourIndex].HourName <> '' do
  begin
    inc(LastHourPrinted);

    if (HourIndex > 0) and (LastHourPrinted > 23) then
    begin
      DoingDay1 := False;
      LastHourPrinted := 0;
    end;

    Val(LogHourTotals^[HourIndex].HourName, ThisHour, Result);

    if HourIndex = 0 then LastHourPrinted := ThisHour;

    while ThisHour <> LastHourPrinted do
    begin
      Write(FileWrite, LastHourPrinted: 2, '  ');

      for Band := Band160 to Band10 do
        Write(FileWrite, ' ----   ');

      Write(FileWrite, '  ----   ');

      WriteLn(FileWrite, TotalMinutes: 4, '/', round(TotalContacts * (60 / TotalMinutes)));

      inc(LastHourPrinted);
      if LastHourPrinted > 23 then LastHourPrinted := 0;
    end;

    TotalContacts := TotalContacts + LogHourTotals^[HourIndex].QSOs[All, Both];
    TotalMinutes := TotalMinutes + LogHourTotals^[HourIndex].Minutes[All, Both];
    TotalQSOPoints := TotalQSOPoints + LogHourTotals^[HourIndex].QSOPoints[All, Both];

    if DoingDay1 then
    begin
      Day1QSOTotals[Band160] := Day1QSOTotals[Band160] + LogHourTotals^[HourIndex].QSOs[Band160, Both];
      Day1QSOTotals[Band80] := Day1QSOTotals[Band80] + LogHourTotals^[HourIndex].QSOs[Band80, Both];
      Day1QSOTotals[Band40] := Day1QSOTotals[Band40] + LogHourTotals^[HourIndex].QSOs[Band40, Both];
      Day1QSOTotals[Band20] := Day1QSOTotals[Band20] + LogHourTotals^[HourIndex].QSOs[Band20, Both];
      Day1QSOTotals[Band15] := Day1QSOTotals[Band15] + LogHourTotals^[HourIndex].QSOs[Band15, Both];
      Day1QSOTotals[Band10] := Day1QSOTotals[Band10] + LogHourTotals^[HourIndex].QSOs[Band10, Both];

      Day1MinTotals[Band160] := Day1MinTotals[Band160] + LogHourTotals^[HourIndex].Minutes[Band160, Both];
      Day1MinTotals[Band80] := Day1MinTotals[Band80] + LogHourTotals^[HourIndex].Minutes[Band80, Both];
      Day1MinTotals[Band40] := Day1MinTotals[Band40] + LogHourTotals^[HourIndex].Minutes[Band40, Both];
      Day1MinTotals[Band20] := Day1MinTotals[Band20] + LogHourTotals^[HourIndex].Minutes[Band20, Both];
      Day1MinTotals[Band15] := Day1MinTotals[Band15] + LogHourTotals^[HourIndex].Minutes[Band15, Both];
      Day1MinTotals[Band10] := Day1MinTotals[Band10] + LogHourTotals^[HourIndex].Minutes[Band10, Both];
    end
    else
    begin
      Day2QSOTotals[Band160] := Day2QSOTotals[Band160] + LogHourTotals^[HourIndex].QSOs[Band160, Both];
      Day2QSOTotals[Band80] := Day2QSOTotals[Band80] + LogHourTotals^[HourIndex].QSOs[Band80, Both];
      Day2QSOTotals[Band40] := Day2QSOTotals[Band40] + LogHourTotals^[HourIndex].QSOs[Band40, Both];
      Day2QSOTotals[Band20] := Day2QSOTotals[Band20] + LogHourTotals^[HourIndex].QSOs[Band20, Both];
      Day2QSOTotals[Band15] := Day2QSOTotals[Band15] + LogHourTotals^[HourIndex].QSOs[Band15, Both];
      Day2QSOTotals[Band10] := Day2QSOTotals[Band10] + LogHourTotals^[HourIndex].QSOs[Band10, Both];

      Day2MinTotals[Band160] := Day2MinTotals[Band160] + LogHourTotals^[HourIndex].Minutes[Band160, Both];
      Day2MinTotals[Band80] := Day2MinTotals[Band80] + LogHourTotals^[HourIndex].Minutes[Band80, Both];
      Day2MinTotals[Band40] := Day2MinTotals[Band40] + LogHourTotals^[HourIndex].Minutes[Band40, Both];
      Day2MinTotals[Band20] := Day2MinTotals[Band20] + LogHourTotals^[HourIndex].Minutes[Band20, Both];
      Day2MinTotals[Band15] := Day2MinTotals[Band15] + LogHourTotals^[HourIndex].Minutes[Band15, Both];
      Day2MinTotals[Band10] := Day2MinTotals[Band10] + LogHourTotals^[HourIndex].Minutes[Band10, Both];
    end;

    with LogHourTotals^[HourIndex] do
    begin
      Write(FileWrite, ThisHour: 2, '  ');

      for Band := Band160 to Band10 do
      begin
        if QSOs[Band, Both] > 0 then
        begin
          Str(Minutes[Band, Both]: 3, TempString);
          TempString := TempString + '/';

          Rate := round(QSOs[Band, Both] * (60 / Minutes[Band, Both]));
          Str(Rate, RateString);

          TempString := TempString + RateString;
          while length(TempString) < 9 do TempString := TempString + ' ';
          Write(FileWrite, TempString);
        end
        else
          Write(FileWrite, '  ----   ');
      end;

      Str(Minutes[All, Both]: 2, TempString);
      TempString := TempString + '/';

      Rate := round(QSOs[All, Both] * (60 / Minutes[All, Both]));
      Str(Rate, RateString);

      TempString := TempString + RateString;
      while length(TempString) < 9 do TempString := TempString + ' ';
      Write(FileWrite, TempString);

      WriteLn(FileWrite, TotalMinutes: 4, '/', round(TotalContacts * (60 / TotalMinutes)));
    end;

    Val(LogHourTotals^[HourIndex].HourName, LastHourPrinted, Result);
    inc(HourIndex);
  end;

  TotalDay1QSOs := Day1QSOTotals[Band160] + Day1QSOTotals[Band80] +
    Day1QSOTotals[Band40] + Day1QSOTotals[Band20] +
    Day1QSOTotals[Band15] + Day1QSOTotals[Band10];

  TotalDay1Mins := Day1MinTotals[Band160] + Day1MinTotals[Band80] +
    Day1MinTotals[Band40] + Day1MinTotals[Band20] +
    Day1MinTotals[Band15] + Day1MinTotals[Band10];

  TotalDay2QSOs := Day2QSOTotals[Band160] + Day2QSOTotals[Band80] +
    Day2QSOTotals[Band40] + Day2QSOTotals[Band20] +
    Day2QSOTotals[Band15] + Day2QSOTotals[Band10];

  TotalDay2Mins := Day2MinTotals[Band160] + Day2MinTotals[Band80] +
    Day2MinTotals[Band40] + Day2MinTotals[Band20] +
    Day2MinTotals[Band15] + Day2MinTotals[Band10];

  Write(FileWrite, 'D1 ');

  for Band := Band160 to Band10 do
  begin
    Write(FileWrite, (Day1MinTotals[Band] / 60): 4: 1, '/');
    if Day1MinTotals[Band] <> 0 then
      Rate := round(Day1QSOTotals[Band] * (60 / Day1MinTotals[Band]))
    else rate := 0;

    Str(Rate, RateString);
    while length(RateString) < 4 do RateString := RateString + ' ';
    Write(FileWrite, RateString);
  end;

  Write(FileWrite, '         ', (TotalDay1Mins / 60): 5: 1, '/');

  Rate := round(TotalDay1QSOs * (60 / TotalDay1Mins));
  WriteLn(FileWrite, Rate);

  if not DoingDay1 then
  begin
    Write(FileWrite, 'D2 ');

    for Band := Band160 to Band10 do
    begin
      Write(FileWrite, (Day2MinTotals[Band] / 60): 4: 1, '/');

      if Day2MinTotals[Band] <> 0 then
        Rate := round(Day2QSOTotals[Band] * (60 / Day2MinTotals[Band]))
      else
        rate := 0;

      Str(Rate, RateString);
      while length(RateString) < 4 do RateString := RateString + ' ';
      Write(FileWrite, RateString);
    end;

    Write(FileWrite, '         ', (TotalDay2Mins / 60): 5: 1, '/');

    Rate := round(TotalDay2QSOs * (60 / TotalDay2Mins));
    WriteLn(FileWrite, Rate);
  end;

  Write(FileWrite, 'TO ');

  for Band := Band160 to Band10 do
  begin
    Write(FileWrite, ((Day1MinTotals[Band] + Day2MinTotals[Band]) / 60): 4: 1, '/');
    if Day1MinTotals[Band] + Day2MinTotals[Band]>0 then //wli
      Rate := round((Day1QSOTotals[Band] + Day2QSOTotals[Band]) *
        (60 / (Day1MinTotals[Band] + Day2MinTotals[Band])))
    else rate := 0; //wli
    Str(Rate, RateString);
    while length(RateString) < 4 do RateString := RateString + ' ';
    Write(FileWrite, RateString);
  end;

  Write(FileWrite, '         ', ((TotalDay1Mins + TotalDay2Mins) / 60): 5: 1, '/');
  Rate := round((TotalDay1QSOs + TotalDay2QSOs) * (60 / (TotalDay1Mins + TotalDay2Mins)));
  WriteLn(FileWrite, Rate);
  Write(FileWrite, ' ');
  Close(FileWrite);
  view(FileName);
end;

procedure MultiplierReportMenu;

var
  Key               : Char;

begin
//  ClrScr;
//  TextColor(Yellow);
  WriteLnCenter('MULTIPLIER REPORT MENU');
//  TextColor(Cyan);
  WriteLn;

  Header := '';
{
  repeat
//    ClrScr;
//    TextColor(Yellow);
    WriteLnCenter('OH2MM CQ WW REPORT MENU');
//    TextColor(Cyan);

    WriteLn;
    WriteLn('These reports were originally inspired by OH2MM for the CQ WW contest, ');
    WriteLn('however many of them are also useful for other contests.');
    WriteLn;
    WriteLn(' C - Multiplier check off sheet');
    WriteLn(' F - First callsigns worked by country by band.');
    WriteLn(' G - First callsigns worked by zone by band.');
    WriteLn(' H - Rate sheet with multipliers and running score.');
    WriteLn(' R - Rate by band by hour report.');
    WriteLn(' T - Total QSOs worked by country by band.');
    WriteLn(' Z - Total Zones worked by zone by band.');
    WriteLn;
    Write(' Enter desired report (ESCAPE to exit this menu) : ');

    repeat until KeyPressed;
    Key := UpCase(ReadKey);
}
  case Key of

    'C': MultiplierCheckOffSheet;

{    'F': begin
//          ClearScreenAndTitle('SHOW FIRST COUNTRY CALLSIGN WORKED BY BAND');
        WriteLn('This report will show the first callsign worked in each country by band');
        WriteLn;

        New(CountryMultTotals);

        repeat
          Key := UpCase(GetKey('Use (C)Q or (A)RRL countries? (C/A) : '));
          if Key = EscapeKey then exit;
        until (Key = 'C') or (Key = 'A');
        WriteLn;

        if Key = 'C' then
          CountryTable.CountryMode := CQCountryMode
        else
          CountryTable.CountryMode := ARRLCountryMode;

        if GenerateCountryMultiplierTotals then
          PrintFirstCountryMultiplierCallsigns;

        Dispose(CountryMultTotals);
//          WaitForKeyPressed;
      end;
}
{    'G': begin
//          ClrScr;
//          TextColor(Yellow);
        WriteLnCenter('SHOW FIRST ZONE CALLSIGN WORKED BY BAND');
//          TextColor(Cyan);
        WriteLn;
        WriteLn('This report will show the first callsign worked in each zone by band');
        WriteLn;

        New(CountryMultTotals);

        if GenerateZoneMultiplierTotals then
          PrintFirstZoneMultiplierCallsigns;

        Dispose(CountryMultTotals);
//          WaitForKeyPressed;
      end;
}
{    'H': begin
///          ClrScr;
//          TextColor(Yellow);
        WriteLnCenter('GENERATE REPORT OF SCORE BY HOUR');
//          TextColor(Cyan);
        WriteLn;
        WriteLn('This report will show the score at the end of each hour.');
        WriteLn;

        New(LogHourTotals);

        if GenerateAllTotalsPerHour then PrintHourTotals;

        Dispose(LogHourTotals);
//          WaitForKeyPressed;
      end;
}
{    'R': begin
//          ClrScr;
//          TextColor(Yellow);
        WriteLnCenter('GENERATE REPORT OF RATE BY BAND BY HOUR');
//          TextColor(Cyan);
        WriteLn;
        WriteLn('This report will show the score at the end of each hour.');
        WriteLn;

        New(LogHourTotals);

        if GenerateAllTotalsPerHour then
          PrintRateByHourTotals;

        Dispose(LogHourTotals);
//          WaitForKeyPressed;
      end;
}
{    'T': begin
//          ClrScr;
//          TextColor(Yellow);
        WriteLnCenter('SHOW TOTAL QSOs BY COUNTRY BY BAND');
//          TextColor(Cyan);
        WriteLn;
        WriteLn('This report will show the number of QSOs made in each country by band');
        WriteLn;

        New(CountryMultTotals);

        if GenerateCountryMultiplierTotals then
          PrintQSOsByCountry;

        Dispose(CountryMultTotals);
//          WaitForKeyPressed;
      end;
}
{    'Z': begin
//          ClrScr;
//          TextColor(Yellow);
        WriteLnCenter('SHOW TOTAL QSOs BY ZONE BY BAND');
//          TextColor(Cyan);
        WriteLn;
        WriteLn('This report will show the number of QSOs made in each zone by band');
        WriteLn;

        New(CountryMultTotals);

        if GenerateZoneMultiplierTotals then
          PrintQSOsByZone;

        Dispose(CountryMultTotals);
//          WaitForKeyPressed;
      end;
}
    'X', EscapeKey: Exit;
  end;

//wli  until False;
end;




















begin
end.

