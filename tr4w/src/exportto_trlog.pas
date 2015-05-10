{
 Copyright Dmitriy Gulyaev UA4WLI 2015.

 This file is part of TR4W  (SRC)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W in  GPL_License.TXT. 
If not, ref http://www.gnu.org/licenses/gpl-3.0.txt
 }
unit exportto_trlog;

interface

uses
  LogWind,
//  LogStuff,
  PostUnit,
  LogDom,
  TF,
  LogK1EA,
  LogRadio,
  LogDupe,
  VC,
  Windows;

function MakeLogString(RXData: ContestExchange): Str80;

implementation

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


procedure TenTenNumReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + ' 1010# ';
  Underline := Underline + ' ----- ';
end;

procedure ZoneReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Zone ';
  Underline := Underline + '---- ';
end;

procedure CheckReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Ck ';
  Underline := Underline + '-- ';
end;

procedure PrecedenceReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'P ';
  Underline := Underline + '- ';
end;

procedure AgeReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Age ';
  Underline := Underline + '--- ';
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

procedure PowerReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Power ';
  Underline := Underline + '----- ';
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

procedure RSTReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Rcvd ';
  Underline := Underline + '---- ';
end;

procedure FOCNumberHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Rcvd ';
  Underline := Underline + '---- ';
end;
procedure QSONumberReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Rcvd  ';
  Underline := Underline + '----  ';
end;

procedure RSTSentHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Sent ';
  Underline := Underline + '---- ';
end;

procedure RandomCharsSentAndReceivedHeader(var LogString: Str80; var Underline: Str80);

begin
  LogString := LogString + 'Sent   Rcvd   ';
  Underline := Underline + '----   ----   ';
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

procedure ClassReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  ClassString                           : Str20;

begin
  ClassString := Exchange.ceClass;
  while length(ClassString) < 7 do
    ClassString := ClassString + ' ';

  LogString := LogString + '  ' + ClassString;
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
  CharsString := Exchange.QTHString; //PostalCode;

  while length(CharsString) < 10 do
    CharsString := CharsString + ' ';

  LogString := LogString + CharsString;
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

procedure PrecedenceReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  PrecedenceString                      : Str80;

begin
  PrecedenceString := Exchange.Precedence + '   ';
  //{WLI}    PrecedenceString [0] := Chr (2);
  PrecedenceString := Copy(PrecedenceString, 1, 2);
  LogString := LogString + PrecedenceString;
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

procedure FOCReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  TempString                            : Str80;

begin
  TempString := Exchange.Power;



    while length(TempString) < 5 do
      TempString := ' ' + TempString;

  LogString := LogString + TempString + ' ';
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

procedure ChapterReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  TempString                            : Str20;

begin
  TempString := Copy(Exchange.Chapter, 1, 4);

  TempString := TempString + ' ';

  while length(TempString) < 4 do TempString := ' ' + TempString;

  LogString := LogString + TempString;
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
  LogString := string(BandStringsArray[Exchange.Band]) + ModeStringArray[Exchange.Mode];

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

procedure RSTReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

var
  RSTString                             : Str80;

begin

  RSTString := ' ' + IntToStr(Exchange.RSTReceived) + '     ';
  RSTString[0] := CHR(5);
  RSTString := Copy(RSTString, 1, 5);
  LogString := LogString + RSTString;

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
      if Contest = FOCMARATHON then FOCReceivedStamp(RXData, LogString);
    end
    else
    begin
      if Kids then KidsReceivedStamp(RXData, LogString);
      if ClassEI then ClassReceivedStamp(RXData, LogString);
      if QSONumber then QSONumberReceivedStamp(RXData, LogString);
//      if PostalCode then PostalCodeReceivedStamp(RXData, LogString);
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
  // if ActiveExchange = RSTAndFOCNumberExchange then
  if Contest = FOCMARATHON then  //n4af 4.32.5
  begin
    LogString := LogString + ' TXR  RXR QTH    FOC NUM';
    Underline := Underline + ' ---  --- ---    -------';
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
//      if PostalCode then PostalCodeReceivedHeader(LogString, Underline);
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

end.

