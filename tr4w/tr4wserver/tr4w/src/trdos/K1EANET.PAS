unit K1EANET;

{$O+}
{$F+}
{$IMPORTEDDATA OFF}
interface

uses {Dos, }
  VC,
  Tree,
  LogRadio,
  LogWind,
  LogK1EA {, SlowTree},
  Other;

//var  K1EAStationID                         : Char;

function ConvertUnixToDateAndTimeString(UnixDate: LONGINT): Str40;

function ConvertN6TRLogStringToK1EANetworkFormat(N6TRLogString: string): string;

function ConvertK1EANetworkLogMessageToN6TRLogString(K1EANetworkLogMessage: shortstring): shortstring;

function GetK1EABandIntegerFromFrequency(Frequency: LONGINT): Char;
function GetUnixTime: LONGINT;

procedure TestUnixTimeConversionRoutines;

procedure Unix2Norm(Date: LONGINT; var Year, Month, Day, Hour, Minute, Second: Word);

implementation

var
  DaysPerMonth                : array[1..12] of SHORTINT =
    (031, 028, 031, 030, 031, 030, 031, 031, 030, 031, 030, 031);

const
  DaysPerYear                 : array[1..12] of integer =
    (031, 059, 090, 120, 151, 181, 212, 243, 273, 304, 334, 365);

  DaysPerLeapYear             : array[1..12] of integer =
    (031, 060, 091, 121, 152, 182, 213, 244, 274, 305, 335, 366);

  SecsPerYear                 : LONGINT = 31536000;
  SecsPerLeapYear             : LONGINT = 31622400;
  SecsPerDay                  : LONGINT = 86400;
  SecsPerHour                 : integer = 3600;
  SecsPerMinute               : integer = 60;

function IsLeapYear(Year: Word): boolean;

begin
  if Year mod 100 = 0 then
  begin
    if (Year mod 400 = 0) then
      IsLeapYear := True
    else
      IsLeapYear := False;

    Exit;
  end;

  IsLeapYear := Year mod 4 = 0;
end;

function Norm2Unix(Year, Month, Day, Hour, Minute, Second: Word): LONGINT;

var
  UnixDate                    : LONGINT;
  Index                       : Word;

begin
  UnixDate := 0; {initialize}

  inc(UnixDate, Second); { add seconds}
  inc(UnixDate, SecsPerMinute * Minute); { add minutes}
  inc(UnixDate, SecsPerHour * Hour); { add hours}

  { add days }

  inc(UnixDate, (SecsPerDay * (Day - 1)));

  { We now have how many seconds have passed so far in the month }

  { Figure out how many hours have passed in this year up to the end
    of the previous day }

  if IsLeapYear(Year) then
    DaysPerMonth[02] := 29
  else
    DaysPerMonth[02] := 28; {Check for Feb. 29th}

  { Add in seconds for completed months so far }

  Index := 1;

  if Month > 1 then
    for Index := 1 to Month - 1 do {has one month already passed?}
      inc(UnixDate, (DaysPerMonth[Index] * SecsPerDay));

  { Now do the complete years }

  while Year > 1970 do
  begin
    if IsLeapYear(Year - 1) then
      inc(UnixDate, SecsPerLeapYear)
    else
      inc(UnixDate, SecsPerYear);

    dec(Year, 1);
  end;

  Norm2Unix := UnixDate;
end;

procedure Unix2Norm(Date: LONGINT; var Year, Month, Day, Hour, Minute, Second: Word);

var
  Done                        : boolean;
  X                           : SHORTINT;
  TotDays                     : integer;

begin
  Year := 1970;
  Month := 1;
  Day := 1;
  Hour := 0;
  Minute := 0;
  Second := 0;

  { Count out the years }

  Done := False;

  while not Done do
  begin
    if IsLeapYear(Year) then
    begin
      if Date >= SecsPerLeapYear then
      begin
        inc(Year);
        dec(Date, SecsPerLeapYear);
      end;
    end
    else { not a leap year }
    begin
      if Date >= SecsPerYear then
      begin
        inc(Year);
        dec(Date, SecsPerYear);
      end;
    end;

      { See if we are done yet }

    if IsLeapYear(Year) then
    begin
      if Date < SecsPerLeapYear then
        Done := True;
    end
    else
      if Date < SecsPerYear then
        Done := True;
  end;

  { Okay - we have the right year, and Date has just the remaining
    amount of seconds left in it }

  Done := False;

  TotDays := Date div SecsPerDay; { Number of Days we need to count out }

  if TotDays > 0 then
  begin
    if IsLeapYear(Year) then
    begin
      DaysPerMonth[2] := 29;

      X := 1;

      repeat
        if (TotDays <= DaysPerLeapYear[X]) then
        begin
          Month := X;
          Done := True;
          dec(Date, (TotDays * SecsPerDay));
          Day := DaysPerMonth[Month] - (DaysPerLeapYear[Month] - TotDays) + 1;
        end
        else
          Done := False;

        inc(X);

      until Done or (X > 12);
    end

    else { Not a leap year }
    begin
      DaysPerMonth[02] := 28;

      X := 1;

      repeat
        if (TotDays <= DaysPerYear[X]) then
        begin
          Month := X;
          Done := True;
          dec(Date, (TotDays * SecsPerDay));
          Day := DaysPerMonth[Month] - (DaysPerYear[Month] - TotDays) + 1;
        end
        else
          Done := False;

        inc(X);
      until Done or (X > 12);
    end;
  end;

  { Now we have the month and day - we just need to do the easy stuff }

  Hour := Date div SecsPerHour;

  dec(Date, (Hour * SecsPerHour));

  Minute := Date div SecsPerMinute;
  dec(Date, (Minute * SecsPerMinute));
  Second := Date;
end;

procedure DateStringToYearMonthDay(DateString: Str20; var Year, Month, Day: Word);

var
  RESULT                      : integer;
  YearString, DayString       : Str20;

begin
  DateString := UpperCase(DateString);

  YearString := Copy(DateString, length(DateString) - 1, 2);

  { If I live to be 130, this might be a problem... }

  if YearString >= '70' then
  begin
    Val(YearString, Year, RESULT);
    Year := Year + 1900;
  end
  else
  begin
    Val(YearString, Year, RESULT);
    Year := Year + 2000;
  end;

  if StringHas(DateString, 'JAN') then Month := 1 else
    if StringHas(DateString, 'FEB') then Month := 2 else
      if StringHas(DateString, 'MAR') then Month := 3 else
        if StringHas(DateString, 'APR') then Month := 4 else
          if StringHas(DateString, 'MAY') then Month := 5 else
            if StringHas(DateString, 'JUN') then Month := 6 else
              if StringHas(DateString, 'JUL') then Month := 7 else
                if StringHas(DateString, 'AUG') then Month := 8 else
                  if StringHas(DateString, 'SEP') then Month := 9 else
                    if StringHas(DateString, 'OCT') then Month := 10 else
                      if StringHas(DateString, 'NOV') then Month := 11 else
                        if StringHas(DateString, 'DEC') then Month := 12 else
                          Month := 0;

  DayString := Copy(DateString, 1, 2);
  Val(DayString, Day, RESULT);
end;

procedure TimeStringToHourAndMinute(TimeString: Str20; var Hour, Minute: Word);

{ Works for either hh:mm or hhmm }

var
  TempString                  : Str20;
  RESULT                      : integer;

begin
  TempString := Copy(TimeString, 1, 2);

  Val(TempString, Hour, RESULT);

  TempString := Copy(TimeString, length(TimeString) - 1, 2);

  Val(TempString, Minute, RESULT);
end;

function ConvertN6TRLogStringToK1EANetworkFormat(N6TRLogString: string): string;

{ This procedure will convert a N6TR Log string to format required to send
  to the K1EA netowrk.

Input string format :

 80CW  04-Oct-03 16:57    1  JA1KSO      *  599  599  25            JA 25    3

Output string format :

L7 599 14025000 14025000 1062530106 0 4 1 RU1A 16 0 7 7407 0 ? <cr>

Station 7 has just logged RU1A with a received RST of 599.  Both VFOs are
on 14025000.  The TIME is in seconds since Jan 1, 1980.  0 is the status
which means simplex and the only one we will bother sending.  4 is the band
(160 = 1, 10 = 6).  1=CW (2=SSB).  16 is the received zone.

The next four values are not used.  The ? is a checksum - add up all of
the characters in the string so far, or with $80.  Then a <cr>.   }

var
  TempString                  : string;
  CheckSum                    : Word;
  CharPointer                 : integer;
  BandInteger                 : integer;
  ModeChar                    : Char;
  Band                        : BandType;
  Mode                        : ModeType;
  Call                        : CallString;
  ExchangeString              : string; {STR20} {WLI}
  ZoneString, RSTString, TimeString, DateString: Str20;
  BandStr, FrequencyString, UnixTimeString: Str20;
  Year, Month, Day, Hour, Minute: Word;
  Freq, DefaultFreq, UnixTime : LONGINT;
  K1EAString                  : string;

begin
  Band := GetLogEntryBand(N6TRLogString);

  if ActiveExchange = RSTZoneExchange then
  begin
    case Band of
      Band160:
        begin
          BandInteger := 1;
          DefaultFreq := 1800000;
        end;

      Band80:
        begin
          BandInteger := 2;
          DefaultFreq := 3500000;
        end;

      Band40:
        begin
          BandInteger := 3;
          DefaultFreq := 7000000;
        end;

      Band20:
        begin
          BandInteger := 4;
          DefaultFreq := 14000000;
        end;

      Band15:
        begin
          BandInteger := 5;
          DefaultFreq := 21000000;
        end;

      Band10:
        begin
          BandInteger := 6;
          DefaultFreq := 28000000;
        end;

    else
      begin
        BandInteger := -1;
        DefaultFreq := 0;
      end;
    end;
  end
  else
  begin
    case Band of
      Band160:
        begin
          BandInteger := 1;
          DefaultFreq := 1800000;
        end;

      Band80:
        begin
          BandInteger := 2;
          DefaultFreq := 3500000;
        end;

      Band40:
        begin
          BandInteger := 3;
          DefaultFreq := 7000000;
        end;

      Band30:
        begin
          BandInteger := 4;
          DefaultFreq := 10100000;
        end;

      Band20:
        begin
          BandInteger := 5;
          DefaultFreq := 14000000;
        end;

      Band17:
        begin
          BandInteger := 6;
          DefaultFreq := 18068000;
        end;

      Band15:
        begin
          BandInteger := 7;
          DefaultFreq := 21000000;
        end;

      Band12:
        begin
          BandInteger := 8;
          DefaultFreq := 24890000;
        end;

      Band10:
        begin
          BandInteger := 9;
          DefaultFreq := 28000000;
        end;

      Band6:
        begin
          BandInteger := 10;
          DefaultFreq := 50095000;
        end;

      Band2:
        begin
          BandInteger := 11;
          DefaultFreq := 144200000;
        end;

      Band432:
        begin
          BandInteger := 12;
          DefaultFreq := 432100000;
        end;

    else
      begin
        BandInteger := -1;
        DefaultFreq := 0;
      end;
    end;

  end;
  Mode := GetLogEntryMode(N6TRLogString);

  case Mode of
    CW: ModeChar := '1';
    Phone: ModeChar := '2';
  else ModeChar := '?';
  end;

  Call := GetLogEntryCall(N6TRLogString);

  { Figure out the Unix time }

  DateString := GetLogEntryDateString(N6TRLogString);

  DateStringToYearMonthDay(DateString, Year, Month, Day);

  TimeString := GetLogEntryTimeString(N6TRLogString);

  TimeStringToHourAndMinute(TimeString, Hour, Minute);

  UnixTime := Norm2Unix(Year, Month, Day, Hour, Minute, 0);
  Str(UnixTime, UnixTimeString);

  ExchangeString := GetLogEntryExchangeString(N6TRLogString);

//  RemoveFirstString(ExchangeString); { Dump sent RST }
//  RSTString := RemoveFirstString(ExchangeString); { Received RST }
//  ZoneString := RemoveFirstString(ExchangeString); { Recevied Zone }
  {
     if ActiveRadio = radioone then
        begin
           Freq := Radio1.FilteredStatus.Freq;
           if Freq = 0 then Freq := DefaultFreq;
           Str(Freq, FrequencyString);
        end
     else
        begin
           Freq := Radio2.FilteredStatus.Freq;
           if Freq = 0 then Freq := DefaultFreq;
           Str(Freq, FrequencyString);
        end;
  }
  Str(BandInteger, BandStr);
  {
    K1EAString := 'L' + K1EAStationID + ' ' + RSTString + ' ' +
      FrequencyString + ' ' + FrequencyString + ' ' +
      UnixTimeString + ' 0 ' + BandStr + ' ' + ModeChar +
      ' ' + Call + ' ' + ZoneString + ' 0 ' + K1EAStationID + ' 1 0 ';
  }
  ConvertN6TRLogStringToK1EANetworkFormat := K1EAString;
end;

function ConvertUnixToDateAndTimeString(UnixDate: LONGINT): Str40;

var
  Year, Month, Day, Hour, Minute, Second: Word;
  DayString, MonthString, YearString, HourString, MinuteString: Str20;

begin
  Unix2Norm(UnixDate, Year, Month, Day, Hour, Minute, Second);

  Str(Day, DayString);

  if length(DayString) = 1 then DayString := '0' + DayString;

  case Month of
    1: MonthString := 'JAN';
    2: MonthString := 'FEB';
    3: MonthString := 'MAR';
    4: MonthString := 'APR';
    5: MonthString := 'MAY';
    6: MonthString := 'JUN';
    7: MonthString := 'JUL';
    8: MonthString := 'AUG';
    9: MonthString := 'SEP';
    10: MonthString := 'OCT';
    11: MonthString := 'NOV';
    12: MonthString := 'DEC';
  else
    MonthString := '???';
  end;

  Str(Year, YearString);

  YearString := Copy(YearString, length(YearString) - 1, 2);

  Str(Hour, HourString);

  if length(HourString) = 1 then HourString := '0' + HourString;

  Str(Minute, MinuteString);

  if length(MinuteString) = 1 then MinuteString := '0' + MinuteString;

  ConvertUnixToDateAndTimeString := DayString + '-' +
    MonthString + '-' +
    YearString + ' ' +
    HourString + ':' +
    MinuteString;
end;

function ConvertK1EANetworkLogMessageToN6TRLogString(K1EANetworkLogMessage: shortstring): shortstring;

{ This procedure will convert a K1EA network log message to the N6TR log
  string format

Input string format :

L7 599 14025000 14025000 1062530106 0 4 1 RU1A 16 0 7 7407 0 ? <cr>

Station 7 has just logged RU1A with a received RST of 599.  Both VFOs are
on 14025000.  The TIME is in seconds since Jan 1, 1980.  0 is the status
which means simplex and the only one we will bother sending.  4 is the band
(160 = 1, 10 = 6).  1=CW (2=SSB).  16 is the received zone.

The next four values are not used.  The ? is a checksum - add up all of
the characters in the string so far, or with $80.  Then a <cr>.

Output string format :

 80CW  04-Oct-03 16:57    0  JA1KSO      *  599  599  25                     0

This will also handle the update format:

U7 599 7025000 7025000 1062530106 0 3 1 G4LNS 14 0 2 1 0 599 7025000 7025000 ...

}

var
  RSTString, UnixTimeString, BandString, ModeString, Callsign, ZoneString: Str20;
  ModeStringChar              : Char;
  UnixDate                    : LONGINT;
  Year, Month, Day, Hour, Minute, Second: Word;
  DayString, MonthString, YearString, HourString, MinuteString: Str20;
  TempString                  : Str80;
  Result1 {WORD} {WLI}, BandInteger: integer;

  N6TRLogString               : string;

begin
  { Parse the message into individual strings }

  RemoveFirstString(K1EANetworkLogMessage); { Get rid of message type and source }

  RSTString := RemoveFirstString(K1EANetworkLogMessage);

  RemoveFirstString(K1EANetworkLogMessage); { Don't need frequency }
  RemoveFirstString(K1EANetworkLogMessage); { Don't need second frequency string }

  UnixTimeString := RemoveFirstString(K1EANetworkLogMessage);

  RemoveFirstString(K1EANetworkLogMessage); { Don't need simplex byte }

  BandString := RemoveFirstString(K1EANetworkLogMessage);
  ModeString := RemoveFirstString(K1EANetworkLogMessage);
  Callsign := RemoveFirstString(K1EANetworkLogMessage);
  ZoneString := RemoveFirstString(K1EANetworkLogMessage);

  ModeStringChar := ModeString[1];

  Val(BandString, BandInteger, Result1);

  if ActiveExchange = RSTZoneExchange then
  begin
      {переделать}
    case BandInteger of
      1: N6TRLogString := '160';
      2: N6TRLogString := ' 80';
      3: N6TRLogString := ' 40';
      4: N6TRLogString := ' 20';
      5: N6TRLogString := ' 15';
      6: N6TRLogString := ' 10';
    else N6TRLogString := '???';
    end;
  end
  else
  begin
    case BandInteger of
      1: N6TRLogString := '160';
      2: N6TRLogString := ' 80';
      3: N6TRLogString := ' 40';
      4: N6TRLogString := ' 30';
      5: N6TRLogString := ' 20';
      6: N6TRLogString := ' 17';
      7: N6TRLogString := ' 15';
      8: N6TRLogString := ' 12';
      9: N6TRLogString := ' 10';
      10: N6TRLogString := '  6';
      11: N6TRLogString := '  2';
      12: N6TRLogString := '432';
    else N6TRLogString := '???';
    end;
  end;

  case ModeStringChar of
    '1': N6TRLogString := N6TRLogString + 'CW ';
    '2': N6TRLogString := N6TRLogString + 'SSB';
  else N6TRLogString := N6TRLogString + '???';
  end;

  Val(UnixTimeString, UnixDate, Result1);

  N6TRLogString := N6TRLogString + ' ' + ConvertUnixToDateAndTimeString(UnixDate);

  { We will make the sent QSO number = 0 for now }

  N6TRLogString := N6TRLogString + '    0  ';

  { Add the callsign }

  while length(Callsign) < 12 do Callsign := Callsign + ' ';

  N6TRLogString := N6TRLogString + Callsign + '   ';

  { Now force either 59 or 599 as the sent RS(T) }

  case ModeStringChar of
    '1': N6TRLogString := N6TRLogString + '599  ';
    '2': N6TRLogString := N6TRLogString + '59   ';
  else N6TRLogString := N6TRLogString + '???  ';
  end;

  N6TRLogString := N6TRLogString + RSTString;

  while length(N6TRLogString) < 54 do
    N6TRLogString := N6TRLogString + ' ';

  N6TRLogString := N6TRLogString + ZoneString;

  while length(N6TRLogString) < 77 do
    N6TRLogString := N6TRLogString + ' ';

  { Someone else will have to figure out the QSO points - we will just
    put 3 there for now }

  N6TRLogString := N6TRLogString + '3';

  ConvertK1EANetworkLogMessageToN6TRLogString := N6TRLogString;
end;

procedure TestUnixTimeConversionRoutines;

var
  InputString                 : Str20;
  Year, Month, Day, Hour, Minute, Second: Word;
  UnixDate                    : LONGINT;
  Result1                     : integer;

begin
  repeat
    InputString := GetResponse('Enter either Unix or dd-mmm-yy : ');

    if InputString = '' then Exit;

    if StringIsAllNumbers(InputString) then
    begin
      Val(InputString, UnixDate, Result1);

      Unix2Norm(UnixDate, Year, Month, Day, Hour, Minute, Second);

      WriteLn('Year = ', Year);
      WriteLn('Month = ', Month);
      WriteLn('Day = ', Day);
      WriteLn('Hour = ', Hour);
      WriteLn('Minute = ', Minute);
      WriteLn('Second = ', Second);
    end
    else
    begin
      DateStringToYearMonthDay(InputString, Year, Month, Day);

      WriteLn('Year = ', Year, '  Month = ', Month, '  Day = ', Day);

      InputString := GetResponse('Enter time hh:mm : ');

      TimeStringToHourAndMinute(InputString, Hour, Minute);

      WriteLn('Hour = ', Hour, '  Minute = ', Minute);

      UnixDate := Norm2Unix(Year, Month, Day, Hour, Minute, 0);

      WriteLn('Unix time = ', UnixDate);
    end;

    WriteLn;
  until False;
end;

function GetUnixTime: LONGINT;

var
  Year, Month, Day, DayOfWeek, Hour, Minute, Second, Secs100: Word;

begin
  //  GetDate(Year, Month, Day, DayOfWeek);
  //  GetTime(Hour, Minute, Second, Secs100);
  //  GetUnixTime := Norm2Unix(Year, Month, Day, Hour, Minute, Second);
end;

function GetK1EABandIntegerFromFrequency(Frequency: LONGINT): Char;

begin
  if Frequency < 3000000 then
  begin
    GetK1EABandIntegerFromFrequency := '1';
    Exit;
  end;

  if Frequency < 6000000 then
  begin
    GetK1EABandIntegerFromFrequency := '2';
    Exit;
  end;

  if Frequency < 13000000 then
  begin
    GetK1EABandIntegerFromFrequency := '3';
    Exit;
  end;

  if Frequency < 20000000 then
  begin
    GetK1EABandIntegerFromFrequency := '4';
    Exit;
  end;

  if Frequency < 2400000 then
  begin
    GetK1EABandIntegerFromFrequency := '5';
    Exit;
  end;

  GetK1EABandIntegerFromFrequency := '6';
end;

begin
  //  K1EAStationID := CHR(0);
end.

