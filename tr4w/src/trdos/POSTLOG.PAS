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
unit PostLog;

{$O+}
{$F+}

interface

uses Tree,
  Forms, //     SlowTree,
  PostSubs,
  Country9,
  LogDupe,
  LogWind,
//     Crt,
  ZoneCont,
  Dialogs,
  PostUnit,
  ViewUnit,
  SysUtils,
  Windows;

function DupeLog: boolean;
function LogProcedureMenu: boolean;
procedure MultCheck;
procedure ARRLCompatibleLog;
procedure CreateFinalLog;
procedure FilterLog;
procedure Merge;
procedure MakeKCJLog;
procedure K1EANetworkCleanup;
procedure PullSpecificComputerLog;

implementation

//wli

const
  MaxDeleteEntries = 2000; { We had about 300 at HC8N wwith 17K QSOs }

type
  WorkedArrayType = array[BandType, cw..Both, 0..400] of boolean;
  WorkedArrayPtr = ^WorkedArrayType;

  PrefixArrayType = array[0..2000] of fourBYTEs;

  PrefixArrayPtr = ^PrefixArrayType;

  PrefixArrayRecordType = record
    List: PrefixArrayPtr;
    NumberPrefixes: integer;
  end;

  DeleteEntryRecord = record
    Band: BandType;
    Date: string[10];
    Time: string[5];
    Call: CallString;
  end;

  DeleteEntryArrayType = array[0..MaxDeleteEntries - 1] of DeleteEntryRecord;
  DeleteEntryArrayPtr = ^DeleteEntryArrayType;

var
  Worked: WorkedArrayPtr;
  PrefixLists: array[BandType, cw..Both] of PrefixArrayRecordType;
  DeleteEntryArray: DeleteEntryArrayPtr;

procedure TotalStamp(Band: BandType; Mode: ModeType);

var
  TempString: Str80;
  PageQSOPointsString, LogQSOPointsString, ValidContactsString: Str20;
  PageValidContactsString, PageMultString, TotalMultString: Str20;

begin
  TempString := '';
  WriteToLogFile('', Band, Mode);

  Str(PageValidContacts^[Band, Mode], PageValidContactsString);
  Str(ValidContacts^[Band, Mode], ValidContactsString);
  TempString := TempString + 'Valid QSOs = ' + PageValidContactsString;
  TempString := TempString + '/' + ValidContactsString + '  ';
  PageValidContacts^[Band, Mode] := 0;

  if AccumulateQSOPoints then begin
    Str(PageQSOPoints^[Band, Mode], PageQSOPointsString);
    Str(LogFileQSOPoints^[Band, Mode], LogQSOPointsString);
    TempString := TempString + 'Pts = ' + PageQSOPointsString;
    TempString := TempString + '/' + LogQSOPointsString + '  ';
    PageQSOPoints^[Band, Mode] := 0;
  end;

  if AccumulateMultipliers then begin
    if DoingDomesticMults then begin
      TotalDomesticMults^[Band, Mode] := TotalDomesticMults^[Band, Mode] + NumberPageDomesticMults^[Band, Mode];
      Str(NumberPageDomesticMults^[Band, Mode], PageMultString);
      Str(TotalDomesticMults^[Band, Mode], TotalMultString);
      TempString := TempString + 'Dom Mult = ' + PageMultString;
      TempString := TempString + '/' + TotalMultString + '  ';
      NumberPageDomesticMults^[Band, Mode] := 0;
    end;

    if DoingZoneMults then begin
      TotalZoneMults^[Band, Mode] := TotalZoneMults^[Band, Mode] + NumberPageZoneMults^[Band, Mode];
      Str(NumberPageZoneMults^[Band, Mode], PageMultString);
      Str(TotalZoneMults^[Band, Mode], TotalMultString);
      TempString := TempString + 'Zone = ' + PageMultString;
      TempString := TempString + '/' + TotalMultString + '  ';
      NumberPageZoneMults^[Band, Mode] := 0;
    end;

    if DoingDXMults then begin
      TotalDXMults^[Band, Mode] := TotalDXMults^[Band, Mode] + NumberPageDXMults^[Band, Mode];
      Str(NumberPageDXMults^[Band, Mode], PageMultString);
      Str(TotalDXMults^[Band, Mode], TotalMultString);
      TempString := TempString + 'DX Mult = ' + PageMultString;
      TempString := TempString + '/' + TotalMultString + '  ';
      NumberPageDXMults^[Band, Mode] := 0;
    end;

    if DoingPrefixMults then begin
      TotalPrefixMults^[Band, Mode] := TotalPrefixMults^[Band, Mode] + NumberPagePrefixMults^[Band, Mode];
      Str(NumberPagePrefixMults^[Band, Mode], PageMultString);
      Str(TotalPrefixMults^[Band, Mode], TotalMultString);
      TempString := TempString + 'Prefix = ' + PageMultString;
      TempString := TempString + '/' + TotalMultString + '  ';
      NumberPagePrefixMults^[Band, Mode] := 0;
    end;

  end;

  WriteToLogFile(TempString, Band, Mode);
end;

procedure GetCopyOfHeader;

var
  TempString: string {80};
  Band: BandType;
  FileRead: Text;

begin
  if not OpenFileForRead(FileRead, LogFileName) then begin
    ShowMessage('Unable to open ' + LogFileName + '!!!!');
//        WaitForKeyPressed;
    halt;
  end;

  NumberHeaderLines := 0;

  repeat
    ReadLn(FileRead, TempString);
    Band := GetLogEntryBand(TempString);
    if Band = NoBand then begin
      ExpandTabs(TempString);
      Header[NumberHeaderLines] := TempString;
      inc(NumberHeaderLines);
    end;
  until Band <> NoBand;

  Close(FileRead);
end;

procedure WriteHeader(Band: BandType; Mode: ModeType);

var
  Line, PageNumber, NumberPages: integer;
  PageNumberString, NumberPagesString: Str80;

begin
  for Line := 0 to NumberHeaderLines - 1 do begin
    if Line = 1 then begin
      while length(Header[Line]) < 65 do Header[Line] := Header[Line] + ' ';
      Header[Line] := Copy(Header[Line], 1, 65);
      PageNumber := (LogFileQSOsPrinted^[Band, Mode] div QSOsPerPage) + 1;
      Str(PageNumber, PageNumberString);
      NumberPages := ((LogTotals[Band, Mode] - 1) div QSOsPerPage) + 1;
      Str(NumberPages, NumberPagesString);
      Header[Line] := Header[Line] + 'PAGE ' + PageNumberString + ' OF ' + NumberPagesString;
    end;

    WriteToLogFile(Header[Line], Band, Mode);
  end;
end;

procedure WriteLogEntry(LogEntry: Str80; Band: BandType; Mode: ModeType);

var
  TempString: Str80;
  MultString, DomesticString, UnknownString, NumberString: Str20;
  QSOPoints, Mult, NumberMults: Word;
  MultArray: array[1..2] of Str20;
  MultIdentified: boolean;

begin
  if QSOsPerPage > 0 then begin
    if LogFileQSOsPrinted^[Band, Mode] mod QSOsPerPage = 0 then begin
      if LogfileQSOsPrinted^[Band, Mode] > 0 then begin
        TotalStamp(Band, Mode);
        WriteToLogFile(ControlL, Band, Mode);
      end
      else
        WriteToLogFile(' ', Band, Mode);

      WriteHeader(Band, Mode);
    end
    else
      if LogFileQSOsPrinted^[Band, Mode] mod 10 = 0 then
        WriteToLogfile('', Band, Mode);
  end;

  inc(LogFileQSOsPrinted^[Band, Mode]);

  if ReNumberQSONumbers then begin
    Delete(LogEntry, LogEntryQSONumberAddress, LogEntryQSONumberWidth);
    Str(LogFileQSOsPrinted^[Band, Mode], TempString);
    while length(TempString) < 4 do TempString := ' ' + TempString;
    Insert(TempString, LogEntry, LogEntryQSONumberAddress);
  end;

  WriteToLogFile(LogEntry, Band, Mode);

  if not ((StringHas(LogEntry, '*DUPE*')) or (StringHas(LogEntry, '*ZERO*'))) then begin
    inc(ValidContacts^[Band, Mode]);
    inc(PageValidContacts^[Band, Mode]);

    if AccumulateQSOPoints then begin
      QSOPoints := GetLogEntryQSOPoints(LogEntry);
      PageQSOPoints^[Band, Mode] := PageQSOPoints^[Band, Mode] + QSOPoints;
      LogFileQSOPoints^[Band, Mode] := LogFileQSOPoints^[Band, Mode] + QSOPoints;
    end;

    if AccumulateMultipliers then begin
      MultString := GetLogEntryMultString(LogEntry);

      if MultString <> '' then begin
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

          if DoingDomesticMults and StringHasLowerCase(MultArray[Mult]) then begin
            inc(NumberPageDomesticMults^[Band, Mode]);
            MultIdentified := true;
          end;

          if DoingZoneMults and StringIsAllNumbers(MultArray[Mult]) and not MultIdentified then begin
            inc(NumberPageZoneMults^[Band, Mode]);
            MultIdentified := true;
          end;

          if DoingPrefixMults and not MultIdentified then begin
            inc(NumberPagePrefixMults^[Band, Mode]);
            MultIdentified := true;
          end;

          if DoingDXMults and not MultIdentified then
            if MultArray[Mult] <> '' then
              inc(NumberPageDXMults^[Band, Mode]);
        end;
      end;
    end;
  end;
end;

function EditLine(InitialString: Str160): Str160;

var
  Key: Char;
  InputString, TempString: Str80;
  SavedCursorPosition: integer;

begin
//    ClrEol;
  Write(InitialString);
  InputString := InitialString;

  repeat
//        REPEAT UNTIL KeyPressed;
//        Key := ReadKey;

    case Key of
      EscapeKey: begin
//                GoToXY (1, WhereY);
//                TextColor (Cyan);
          Write(InitialString);
          EditLine := InitialString;
          Exit;
        end;

      ControlA: begin
//                IF WhereX > 1 THEN
//                    REPEAT
//                        GoToXY (WhereX - 1, WhereY);
//                    UNTIL (WhereX = 1) OR
//                          ((InputString [WhereX - 1] = ' ') AND (InputString [WhereX] <> ' '));
        end;

      BackSpace: begin
//                GoToXY (WhereX - 1, WhereY);
//                InputString [WhereX] := ' ';
//                Write (' ');
//                GoToXY (WhereX - 1, WhereY);
        end;

      Controls: begin
//                IF WhereX > 1 THEN
//                    GoToXY (WhereX - 1, WhereY);
        end;

      ControlD: begin
//                IF WhereX < 1 + Length (InputString) THEN
//                    GoToXY (WhereX + 1, WhereY);
        end;

      ControlF: begin
//                IF WhereX < 1 + Length (InputString) THEN
//                    REPEAT
//                        GoToXY (WhereX + 1, WhereY);
//                    UNTIL ((InputString [WhereX - 1] = ' ') AND (InputString [WhereX] <> ' ')) OR
//                          (WhereX >= 1 + Length (InputString));
        end;

      NullKey: begin
//                Key := ReadKey;

//                CASE Key OF
//                    HomeKey: GoToXY (1, WhereY);

//                    LeftArrow:
//                        IF WhereX > 1 THEN
//                            GoToXY (WhereX - 1, WhereY);
//
 //                   RightArrow:
 //                       IF WhereX < 1 + Length (InputString) THEN
 //                           GoToXY (WhereX + 1, WhereY);

//                    EndKey: GoToXY (1 + Length (InputString), WhereY);
//                    END;
        end;

    else
      if Key >= ' ' then begin
//                    SavedCursorPosition := WhereX;
//wli
        TempString := Copy(InputString, 1, 100);
//                    TempString := Copy (InputString, WhereX, 100);

        Delete(InputString, 1, 100);
//                    Delete (InputString, WhereX, 100);
        Delete(TempString, 1, 1);
//                    TextColor (Yellow);
        Write(Key);
        TempString := Key + TempString;
        InputString := InputString + TempString;
//                    GoToXY (SavedCursorPosition + 1, WhereY);
      end
      else
        if Key = CarriageReturn then begin
          EditLine := InputString;
          Exit;
        end;

    end; { of case }
  until False;
end;

procedure ARRLCompatibleLog;

var
  ARRLString, LogString, DateString, TimeString, TempString, OutputFileName: string;
  NumberString: Str20;
  FileRead, FileWrite: Text;
  Band: BandType;
  Mode: ModeType;
  QSONumber: integer;
  ExchangeString, SentInformation: Str40;

begin
//    ClrScr;
//    TextColor (Yellow);
//  WriteLnCenter('PRODUCE ARRL DISK LOG');
//    TextColor (Cyan);
//  WriteLn;
//  WriteLn('This procedure will produce an ARRL compatible disk log from the active log ');
//  WriteLn('file.  This file can be submitted along with a summary sheet to the ARRL for');
//  WriteLn('any of their contests.  It also can be used for the CQ WPX contests.');

//  WriteLn;

  OutputFileName := postform.arrlfnedit.Text;
  if OutputFileName = '' then Exit;

  if not OpenFileForRead(FileRead, LogFileName) then begin
    ShowMessage(LogFileName + 'not found!!');
    Exit;
  end;

  if not OpenFileForWrite(FileWrite, OutputFileName) then begin
    ShowMessage('Unable to open ' + OutputFileName);
    Exit;
  end;

//    TextColor (Cyan);

//  WriteLn('The ARRL log checkers like to have all of your exchange sent on each log');
//  WriteLn('entry.  Your log already has your QSO number and RS(T) sent.');
//  WriteLn;

  SentInformation := postform.AddExEdit.Text;

  QSONumber := 0;
//  Write(QSONumber);

  repeat
    repeat
      ReadLn(FileRead, LogString);
      Band := GetLogEntryBand(LogString);
    until (Band <> NoBand) or EOF(FileRead);

    if Band <> NoBand then begin
      if (LogString[1] = ';') then Continue;

      ExpandTabs(LogString);

      if LogString[42] = '*' then LogString[42] := ' ';

            { Save the exchange part for later }

      ExchangeString := Copy(LogString, 44, length(LogString) - 43);

            { Get rid of any S&P indicator }

      if pos('$', LogString) > 0 then LogString[pos('$', LogString)] := ' ';

      Mode := GetLogEntryMode(LogString);

      TimeString := Copy(LogString, LogEntryHourAddress, 2) +
        Copy(LogString, LogEntryMinuteAddress, 2);

      DateString := UpperCase(Copy(LogString, LogEntryMonthAddress, 3));

      if DateString = 'JAN' then DateString := '01';
      if DateString = 'FEB' then DateString := '02';
      if DateString = 'MAR' then DateString := '03';
      if DateString = 'APR' then DateString := '04';
      if DateString = 'MAY' then DateString := '05';
      if DateString = 'JUN' then DateString := '06';
      if DateString = 'JUL' then DateString := '07';
      if DateString = 'AUG' then DateString := '08';
      if DateString = 'SEP' then DateString := '09';
      if DateString = 'OCT' then DateString := '10';
      if DateString = 'NOV' then DateString := '11';
      if DateString = 'DEC' then DateString := '12';

      DateString := Copy(LogString, LogEntryDayAddress, 2) + '/' + DateString;
      DateString := DateString + '/' + Copy(LogString, LogEntryYearAddress, 2);

      ARRLString := Copy(LogString, LogEntryBandAddress, LogEntryBandWidth);

      if ARRLString = '  6' then
        ARRLString := '50 '
      else
        if ARRLString = '  2' then
          ARRLString := '144'
        else begin
          GetRidOfPrecedingSpaces(ARRLString);
          while length(ARRLString) < 3 do
            ARRLString := ARRLString + ' ';
        end;

      if Mode = cw then
        ARRLString := ARRLString + ' CW'
      else
        ARRLString := ARRLString + ' PH';

      ARRLString := ARRLString + ' ' + DateString + ' ' + TimeString + ' ';

      Delete(LogString, 1, LogEntryQSONumberAddress - 1);

      NumberString := RemoveFirstString(LogString);

{ Took this out so two xmtr multi-mutil works

            IF Copy (NumberString, Length (NumberString), 1) > '9' THEN
                Delete (NumberString, Length (NumberString), 1);
}

      while length(NumberString) < 6 do
        NumberString := NumberString + ' ';

      ARRLString := ARRLString + ' ' + NumberString;

      Call := RemoveFirstString(LogString);

      while length(Call) < 12 do Call := Call + ' ';

      ARRLString := ARRLString + ' ' + Call;
      ARRLString := ARRLString + ' ' + SentInformation + ' ' + ExchangeString;

      GetRidOfPrecedingSpaces(ARRLString);
      WriteLn(FileWrite, ARRLString);
      inc(QSONumber);
//            GoToXY (1, WhereY);
//      Write(QSONumber);
    end;
  until Eof(FileRead);
  Close(FileRead);
  Close(FileWrite);

  view(OutputFileName);
end;

procedure CreateFinalLog;

var
  TempString: string {80};
  Band: BandType;
  Mode: ModeType;
  QSONumber, NumberZeroContacts: integer;
  Command, Key: Char;
  FileRead: Text;

begin
//    ClrScr;
//    TextColor (Yellow);
//  WriteLnCenter('CREATE FINAL LOG');
//    TextColor (Cyan);
//  WriteLn;
//  WriteLn('This procedure will allow you to create final logs with running totals of  ');
//  WriteLn('QSOs, QSO points and multipliers.  You can have you logs printed separatly ');
//  WriteLn('by band or mode and have the QSO numbers renumbered.  This procedure will ');
//  WriteLn('only output the logs to the disk.  The files can be found with .DAT as');
//  WriteLn('their extension.');
//  WriteLn;

{  repeat
    Command := UpCase(GetKey('Separate logs by band? (Y/N) : '));
  until (Command = 'Y') or (Command = 'N') or (Command = EscapeKey);
  WriteLn;

  if Command = EscapeKey then exit;
  SeparateBandLogs := Command = 'Y';

  repeat
    Command := UpCase(GetKey('Separate logs by mode? (Y/N) : '));
  until (Command = 'Y') or (Command = 'N') or (Command = EscapeKey);
  WriteLn;

  if Command = EscapeKey then exit;
  SeparateModeLogs := Command = 'Y';
}

  SeparateBandLogs := postform.Separatelogsbyband.Checked;
  SeparateModeLogs := postform.Separatelogsbymode.Checked;
  ReNumberQSONumbers := postform.RenumberQSOnumbers.Checked;
  AccumulateQSOPoints := postform.AccumulateQSOpoints.Checked;
  AccumulateMultipliers := postform.Accumulatemultipliers.Checked;

  if SeparateBandLogs then begin
    StartBand := Band160;
    StopBand := Band2304;
  end
  else begin
    StartBand := All;
    StopBand := All;
  end;

  if SeparateModeLogs then begin
    StartMode := cw;
    StopMode := Phone;
  end
  else begin
    StartMode := Both;
    StopMode := Both;
  end;

{  repeat
    Command := UpCase(GetKey('Renumber QSO numbers? (Y/N) : '));
  until (Command = 'Y') or (Command = 'N') or (Command = EscapeKey);
  WriteLn;

  if Command = EscapeKey then exit;
  ReNumberQSONumbers := Command = 'Y';

  repeat
    Command := UpCase(GetKey('Accumulate QSO points? (Y/N) : '));
  until (Command = 'Y') or (Command = 'N') or (Command = EscapeKey);
  WriteLn;

  if Command = EscapeKey then exit;
  AccumulateQSOPoints := Command = 'Y';

  repeat
    Command := UpCase(GetKey('Accumulate multipliers? (Y/N) : '));
  until (Command = 'Y') or (Command = 'N') or (Command = EscapeKey);
  WriteLn;

  if Command = EscapeKey then exit;
  AccumulateMultipliers := Command = 'Y';
}
  if AccumulateMultipliers then
    if not DetermineMultiplierTypes then Exit;

  NumberZeroContacts := 0;

  if not FileExists(LogFileName) then begin
    ShowMessage('No logfile file found!!');
//        WaitForKeyPressed;
    Exit;
  end;

  QSOsPerPage := postform.sp1.Value; // GetValue('Enter number of contacts per page for output : ');

  DetermineLogTotals;
  OpenFilesForBandsBeingProcessed;

  GetCopyOfHeader;

  if not OpenFileForRead(FileRead, LogFileName) then Exit;

  QSONumber := 0;
//  Write(QSONumber);

  repeat
    repeat
      ReadLn(FileRead, TempString);
      Band := GetLogEntryBand(TempString);
    until (Band <> NoBand) or EOF(FileRead);

    if (Band <> NoBand) then begin
      ExpandTabs(TempString);
      Mode := GetLogEntryMode(TempString);

      if not SeparateBandLogs then Band := All;
      if not SeparateModeLogs then Mode := Both;

      WriteLogEntry(TempString, Band, Mode);

      inc(QSONumber);
//            GoToXY (1, WhereY);
//            TextColor (Yellow);
//      Write(QSONumber);
    end;
  until EOF(FileRead);

  for Band := StartBand to StopBand do
    for Mode := StartMode to StopMode do
      if LogTotals[Band, Mode] > 0 then begin
        TotalStamp(Band, Mode);
        WriteToLogFile(ControlL, Band, Mode);
      end;

  Close(FileRead);
  CloseAllOpenFiles;
//postform.LogRE.clear;
//postform.LogRE.Lines.LoadFromFile(LogFileName);
  postform.cm.Lines.Add('The files can be found with .DAT as their extension.');
  //    GoToXY (1, WhereY);
//    ClrEol;
  view(LogFileName);

end;

function DupeLog: boolean;

var
  Band, DupeBand: BandType;
  Mode, DupeMode: ModeType;
  FileRead, FileWrite: Text;
  DupeFileName: Str80;
  FileString, TempString: string;
  QSONumber, DupePos, NumberDupesUnmarked, NumberZeros: integer;
  RXData: ContestExchange;
  Key, Command: Char;
  PossibleDupeList: array[0..100] of CallString;
  PossibleDupe, NumberPossibleDupes: integer;
  FileDupe: Text;
  Grid: Str20;
//wli
  oldname: string;
  tstring: string;
  cancelall: boolean;
begin
  DupeLog := False;
  cancelall := False;
  ViewForm.c.Clear;
//    ClrScr;
//    TextColor (Yellow);
//  WriteLnCenter('CHECK ACTIVE LOG FOR DUPES');
//    TextColor (Cyan);
{  WriteLn;
  WriteLn('This procedure will look through the active log file and flag any duplicate');
  WriteLn('contacts.  It actually performs a dupe check for each callsign.  If a dupe is');
  WriteLn('found, it will be marked with the word DUPE and the QSO points will be set to');
  WriteLn('zero.  It is always a good idea to execute this procedure after a contest as ');
  WriteLn('it is possible for you to use the edit log feature to create duplicate contacts');
  WriteLn('without your knowledge.  The original unduped log will be saved as PLOG###.BAK.');
  WriteLn('The duped log will have the active log file name.  This option also generates a');
  WriteLn('list of the QSOs that are dupes, and saves the list to a separate file.');
  WriteLn;
}
  DetermineQSOByBandAndQSOByMode;
  if not QSOByBandAndModeDetermined then Exit;

  DoingDomesticMults := False;
  DoingDXMults := False;
  DoingZoneMults := False;
  DoingPrefixMults := False;

  RXData.DomesticMult := False;
  RXData.DXMult := False;
  RXData.ZoneMult := False;
  RXData.PrefixMult := False;

  Sheet.DisposeOfMemoryAndZeroTotals;

  NumberZeros := 0;
  NumberPossibleDupes := 0;
  NumberDupesUnmarked := 0;

//  if MessageBox(0, ('Do you want to save a copy of the duplicate QSOs in "Dupes.txt"?'), 'POST', MB_YESNO or MB_ICONQUESTION) <> IDno
//  then  DupeFileName := 'Dupes.txt'else  DupeFileName := '';
  {
  repeat
    Key := UpCase(GetKey('Do you want to save a copy of the duplicate QSOs? (Y/N) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;

  if Key = 'Y' then
    DupeFileName := GetResponse('Enter filename to save dupes to (use PRN for printer) : ')
  else
    DupeFileName := '';
}

  DupeFileName := postform.DupEdit.Text;

  if not OpenFileForRead(FileRead, LogFileName) then begin
    ShowMessage('Unable to open ' + LogFileName + '!!');
    Exit;
  end;

  if not OpenFileForWrite(FileWrite, TempFileName) then begin
    Close(FileRead);
    ShowMessage('Unable to open ' + TempFileName + ' for output!!');
    Exit;
  end;

  if DupeFileName <> '' then
    if not OpenFileForWrite(FileDupe, DupeFileName) then Exit;

  QSONumber := 0;
//  Write(QSONumber);

  while not Eof(FileRead) do begin
    ReadLn(FileRead, FileString);
    Band := GetLogEntryBand(FileString);

    if (Band <> NoBand) then begin
      ExpandTabs(FileString);
      Mode := GetLogEntryMode(FileString);

      if QSOByBand then RXData.Band := Band else RXData.Band := All;
      if QSOByMode then RXData.Mode := Mode else RXData.Mode := Both;

      RXData.Callsign := UpperCase(StandardCallFormat(GetLogEntryCall(FileString), true));

      if RoverCall(RXData.Callsign) then begin
        TempString := GetLogEntryExchangeString(FileString);

        RemoveFirstString(TempString);
        RemoveFirstString(TempString);
        Grid := UpperCase(RemoveFirstString(TempString));

        RXData.Callsign := PrecedingString(RXData.Callsign, '/R') + '/' + Grid;
      end;

      if Sheet.CallIsADupe(RXData.Callsign, RXData.Band, RXData.Mode) then
        BlankOutMultsAndZeroQSOPoints(FileString, '*DUPE*')
      else
        if RXData.Callsign = '' then
          BlankOutMultsAndZeroQSOPoints(FileString, '*ZERO*')
        else begin
          Sheet.AddQSOToSheets(RXData);

          DupePos := pos('*DUPE*', FileString);

          if DupePos > 0 then
            if cancelall = False then begin

              tstring := FileString + #13 + #13 + 'This QSO should not be marked as a dupe.  Okay to fix?';
              case MessageBox(0, PChar(tstring), P, MB_YESNOCancel or MB_ICONQUESTION) of
                IDyes: begin
                    inc(NumberDupesUnMarked);
                    Delete(FileString, DupePos, 6);
                    Insert('      ', FileString, DupePos);

                  end;
                idcancel: cancelall := true;

              end;

            end;

        end;

      if (StringHas(FileString, '*DUPE*')) or (StringHas(FileString, '*ZERO*')) then begin
        ViewForm.c.Lines.Add(FileString);
        if DupeFileName <> '' then WriteLn(FileDupe, FileString);
        inc(NumberZeros);
      end;

      inc(QSONumber);
    end;

    WriteLn(FileWrite, FileString);
  end;

  if DupeFileName <> '' then Close(FileDupe);

  Close(FileRead);
  Close(FileWrite);
  oldname := LogFileName;
  PushLogFiles;

  SysUtils.RenameFile(TempFileName, oldname {LogFileName});

//    TextColor (Cyan);
//    GoToXY (1, WhereY);
//    ClrEol;
//  WriteLn;
  postform.cm.Lines.Add('Original log saved as ' + LastPushedLogName);

  postform.cm.Lines.Add('Now doing second pass to look for possible portable dupes...');

  if not OpenFileForRead(FileRead, LogFileName) then Exit;

  QSONumber := 0;
//  Write(QSONumber);

  Sheet.DisposeOfMemoryAndZeroTotals;

  while not Eof(FileRead) do begin
    ReadLn(FileRead, FileString);
    Band := GetLogEntryBand(FileString);

    if (Band <> NoBand) then begin
      ExpandTabs(FileString);
      Mode := GetLogEntryMode(FileString);

      if QSOByBand then RXData.Band := Band else RXData.Band := All;
      if QSOByMode then RXData.Mode := Mode else RXData.Mode := Both;

      RXData.Callsign := RootCall(StandardCallFormat(GetLogEntryCall(FileString), true));

      if not RoverCall(GetLogEntryCall(FileString)) then begin
        if Sheet.CallIsADupe(RXData.Callsign, RXData.Band, RXData.Mode) then begin
          if not (StringHas(FileString, '*DUPE*') or StringHas(FileString, '*ZERO*')) then begin
            PossibleDupeList[NumberPossibleDupes] := RootCall(RXData.Callsign);
            inc(NumberPossibleDupes);
          end;
        end
        else
          Sheet.AddQSOToSheets(RXData);
      end;

      inc(QSONumber);
//            GoToXY (1, WhereY);
//            ClrEol;
//      Write(QSONumber);
    end;
  end;

  Close(FileRead);

  Sheet.DisposeOfMemoryAndZeroTotals;

//    GoToXY (1, WhereY);
//    ClrEol;

  postform.cm.Lines.Add('There were ' + inttostr(QSONumber) + ' contacts found in the log.');
  postform.cm.Lines.Add('There were ' + inttostr(NumberZeros) + ' exact match dupes marked.');

  if NumberPossibleDupes > 0 then begin
//    WriteLn;

    if NumberPossibleDupes = 1 then
      postform.cm.Lines.Add({Beep + }'There was one possible dupe found in your log.  It is suggested that you   ')
    else
      postform.cm.Lines.Add({Beep + }'There were ' + inttostr(NumberPossibleDupes) + ' possible dupes found.  It is suggested that you');

    postform.cm.Lines.Add('use the Edit command and look carefully at the QSOs with the stations listed.');
    postform.cm.Lines.Add('You will probably decide that there is a duplicate QSO somewhere.  Edit the');
    postform.cm.Lines.Add('duplicate QSO so the callsigns are the same and rerun this procedure.');

    TempString := '';
//        TextColor (Yellow);

    for PossibleDupe := 0 to NumberPossibleDupes - 1 do begin
      if length(TempString) > 70 then begin
        postform.cm.Lines.Add(TempString);
        TempString := '';
      end;
      TempString := TempString + PossibleDupeList[PossibleDupe] + ' ';
    end;

    if TempString <> '' then WriteLn(TempString);
//        WaitForKeyPressed;
    Exit;
  end
  else
    postform.cm.Lines.Add('There were no possible portable dupes found.');

  if NumberDupesUnmarked > 0 then begin
    postform.cm.Lines.Add('');
    postform.cm.Lines.Add('There were QSOs in your log that were marked as dupes but no longer are.');
    postform.cm.Lines.Add('You will need to fix the QSO points for those contacts one of two ways.');
    postform.cm.Lines.Add('Either edit the log file and insert the correct points manuall, or use the');
    postform.cm.Lines.Add('TR READ feature of TR to "rework" the log and assure the proper QSO points');
    postform.cm.Lines.Add('appear.  To use the TR READ feature, rename the log file to LOGREAD.DAT, and ');
    postform.cm.Lines.Add('type TR READ LOGREAD.DAT.');

  end;

//    WaitForKeyPressed;
  DupeLog := true;
//  postform.LogRE.Clear;
//  postform.LogRE.Lines.LoadFromFile(LogFileName);
  view(LogFileName);
end;

procedure EditLog;

var
  Call, TempString: Str80;
  FileString: string;
  FileWrite: Text;
  Key: Char;
var
  FileRead: Text;

begin
//    ClrScr;
//    TextColor (Yellow);
  WriteLnCenter('LINE EDIT PROCEDURE');
  WriteLn;
//    TextColor (Cyan);
  WriteLn('This procedure allows you to edit specific lines of the log.  You will be');
  WriteLn('asked for a search string (case sensitive).  Then each log entry found');
  WriteLn('with the search string will be shown to you one at a time.  You can edit each');
  WriteLn('entry using the cursor keys, backspace and overwrite.  The non insert mode is');
  WriteLn('the only mode available to you.  Be careful to keep columns aligned.');
  WriteLn;

  if not FileExists(LogFileName) then begin
    ShowMessage('No logfile file found.');
//        WaitForKeyPressed;
    Exit;
  end;

  Call := GetResponse('Enter search string to find (none to quit) : ');
  if Call = '' then Exit;

  WriteLn;
//    TextColor (Cyan);
  WriteLn('For each entry found, edit the line and press return when done.');
  WriteLn('Escape will abort any changes made for the line being edited.');
//    GoToXY (LogEntryMultAddress - 8, WhereY);
  Write('Mults start here');
  WriteLn;
//    GoToXY (LogEntryMultAddress, WhereY);
  WriteLn(' ');

  RenameFile(LogFileName, 'POST.TMP');

  if not OpenFileForRead(FileRead, 'POST.TMP') then begin
    ShowMessage('Unable to open POST.TMP');
//        WaitForKeyPressed;
    Exit;
  end;

  if not OpenFileForWrite(FileWrite, LogFileName) then begin
    ShowMessage('Unable to open ' + LogFileName + ' for output.');
//        WaitForKeyPressed;
    Exit;
  end;

  while not Eof(FileRead) do begin
    ReadLn(FileRead, FileString);

    if StringHas(FileString, Call) then begin
      ExpandTabs(FileString);
//      TextColor(Cyan);
      WriteLn(FileWrite, EditLine(FileString));
      WriteLn;
    end
    else
      WriteLn(FileWrite, FileString);
  end;

  Close(FileRead);
  Close(FileWrite);

  WriteLn;
  repeat
    Key := UpCase(GetKey('Do you want to save the changes you have just made? (Y/N) : '));
  until (Key = 'Y') or (Key = 'N');
  WriteLn;

  if Key = 'N' then begin
    Tree.DeleteFile(LogFileName);
    RenameFile('POST.TMP', LogFileName);
    WriteLn('Original ', LogFileName, ' restored.');
  end
  else
    WriteLn('Changes saved to ', LogFileName, '.  Old file saved as POST.TMP.');

//  WaitForKeyPressed;
end;

procedure FilterLog;

var
  QSONumber, Country: integer;
  LogEntryCountry: integer;
  NumberEntriesSaved, NumberCountries: integer;
  CountryList: array[0..19] of integer;

  CludeString, Call: CallString;
  FileName, TempString: Str80;
  TempStr, FileString: string;
  Destination, CludeKey, Key: Char;
  FileRead, FileWrite: Text;
  FoundCountry: boolean;
  Band: BandType;

begin

//  ClrScr;
//  TextColor(Yellow);
//postform.Des.Lines.Add('FILTER LOG PROCEDURE');
//  TextColor(Cyan);
//  WriteLn;
//postform.Des.Lines.Add('This procedure will allow you to filter a log file by including or excluding');
//postform.Des.Lines.Add('up to 20 ARRL countries.  The output is a new log file with a different name.');
//postform.Des.Lines.Add('To enter the countries, simply enter any callsign from that country.');
//exit;

{  if MessageBox(0, 'Press "Yes" to Include', 'TR4W', MB_yesNO or MB_ICONQUESTION) = IDno then exit;

  repeat
    CludeKey := UpCase(GetKey('(I)nclude or (E)xclude countries? (I/E) : '));
    if CludeKey = EscapeKey then exit;
  until (CludeKey = 'I') or (CludeKey = 'E');
}
//if postform.inclRb.Checked then CludeKey='I';//else CludeKey='E'

//  WriteLn;
//  if CludeKey = 'I' then CludeString := 'include' else CludeString := 'exclude';

//  TextColor(Cyan);
//  WriteLn;
//  WriteLn('Enter callsigns of countries you want to ', CludeString, '.  Press RETURN with no');
//  WriteLn('entry to stop entering callsigns.');

  if postform.inclRb.Checked then CludeKey := 'I';
  if CludeKey = 'I' then CludeString := 'include' else CludeString := 'exclude';

  NumberCountries := 0;
  NumberEntriesSaved := 0;
  for Country := 0 to postform.CludeMemo.Lines.Count - 1 do
    if NumberCountries < 20 then begin
      CountryList[NumberCountries] := CountryTable.GetCountry(UpperCase(postform.CludeMemo.Lines.Strings[Country]), False);
      inc(NumberCountries);
    end;

  {
  repeat
    Call := UpperCase(GetResponse('Enter callsign of country to ' + CludeString + ' : '));

    if Call <> '' then
      if NumberCountries < 20 then
      begin
        CountryList[NumberCountries] := CountryTable.GetCountry(Call, False);
        inc(NumberCountries);
      end
      else
        SHOWMESSAGE('Too many coutries!!  Input ignored.  Press RETURN with no entry to stop.');
  until Call = '';
}
  if NumberCountries = 0 then Exit;

//        CountryList[NumberCountries] := CountryTable.GetCountry(Call, False);

//  ClrScr;
//  TextColor(Cyan);
  TempStr := 'You have choosen to ' + CludeString + ' the following countries:' + #13 + #13;
  for Country := 0 to NumberCountries - 1 do
    TempStr := TempStr + (inttostr(Country + 1) + '.  ' + CountryTable.GetCountryName(CountryList[Country])) + #13;
  TempStr := TempStr + #13 + #13 + 'Is this list correct?';

  if MessageBox(0, PChar(TempStr), P, MB_yesNO or MB_ICONQUESTION) = IDno then Exit;

//  WriteLn('You have choosen to ', CludeString, ' the following countries: ');

//  for Country := 0 to NumberCountries - 1 do
//    WriteLn(Country + 1, '.  ', CountryTable.GetCountryName(CountryList[Country]));

//  WriteLn;

{  repeat
    Key := UpCase(GetKey('Is this list correct? (Y/N) : '));
    if (Key = EscapeKey) or (Key = 'N') then exit;
  until (Key = 'Y');
}
//  ClrScr;

{  repeat
    Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
    case Destination of
      'F': begin
          WriteLn;
          FileName := UpperCase(GetResponse('Enter filename to filtered log file to : '));

}
  FileName := postform.FiltEdit.Text;
  if FileName = UpperCase(LogFileName) then begin
    ShowMessage('Output file must be different than active log file!!');
    Exit;
  end;

  if FileName = '' then Exit;
{        end;
      'S': FileName := '';
      'P': FileName := 'PRN';
      EscapeKey: exit;
    end;
  until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
//  WriteLn;
}
  if not OpenFileForRead(FileRead, LogFileName) then begin
    ShowMessage(LogFileName + ' not found!!');
    Exit;
  end;

  if not OpenFileForWrite(FileWrite, FileName) then begin
    ShowMessage('Unable to open output file or device.');
    Exit;
  end;

//  TextColor(Cyan);
  QSONumber := 0;

  repeat
    repeat
      ReadLn(FileRead, FileString);
      Band := GetLogEntryBand(FileString);
    until (Band <> NoBand) or EOF(FileRead);

    if Band <> NoBand then begin
      inc(QSONumber);
//      GoToXY(1, WhereY);
//      Write(QSONumber);
      ExpandTabs(FileString);
      Call := UpperCase(StandardCallFormat(GetLogEntryCall(FileString), False));
      LogEntryCountry := CountryTable.GetCountry(Call, true);

      if CludeKey = 'I' then begin
        for Country := 0 to NumberCountries - 1 do
          if LogEntryCountry = CountryList[Country] then begin
            WriteLn(FileWrite, FileString);
            inc(NumberEntriesSaved);
          end;
      end
      else begin
        FoundCountry := False;
        for Country := 0 to NumberCountries - 1 do
          if LogEntryCountry = CountryList[Country] then
            FoundCountry := true;
        if not FoundCountry then begin
          WriteLn(FileWrite, FileString);
          inc(NumberEntriesSaved);
        end;
      end;
    end;

  until Eof(FileRead);
  Close(FileRead);
  Close(FileWrite);
//  GoToXY(1, WhereY);
//  ClrEol;
  postform.cm.Lines.Add('There were ' + inttostr(NumberEntriesSaved) + ' entries saved.');
  view(FileName);
end;

function QuasiDayOfYear(DateString: Str20): integer;

var
  TempDay, Result1, Day: integer;
  DayString: Str20;

begin
  DateString := UpperCase(DateString);
  Day := 0;

  if StringHas(DateString, 'FEB') then Day := 31;
  if StringHas(DateString, 'MAR') then Day := 62;
  if StringHas(DateString, 'APR') then Day := 93;
  if StringHas(DateString, 'MAY') then Day := 124;
  if StringHas(DateString, 'JUN') then Day := 155;
  if StringHas(DateString, 'JUL') then Day := 186;
  if StringHas(DateString, 'AUG') then Day := 217;
  if StringHas(DateString, 'SEP') then Day := 248;
  if StringHas(DateString, 'OCT') then Day := 279;
  if StringHas(DateString, 'NOV') then Day := 310;
  if StringHas(DateString, 'DEC') then Day := 341;

  DayString := PrecedingString(DateString, '-');

  Val(DayString, TempDay, Result);
  if Result = 0 then Day := Day + TempDay;

  QuasiDayOfYear := Day;
end;

function GetNextLogEntry(var FileHandle: Text): string;

var
  FileString: string;

begin
  GetNextLogEntry := '';

  while not Eof(FileHandle) do begin
    ReadLn(FileHandle, FileString);

    if (GetLogEntryBand(FileString) <> NoBand) and
      (GetLogEntryMode(FileString) <> NoMode) then begin
      GetNextLogEntry := FileString;
      Exit;
    end;
  end;
end;

procedure Merge;

var
  FileOneName, FileTwoName, OutputFileName: Str80;
  FileOne, FileTwo, OutputFile: Text;
  FileStringOne, FileStringTwo: Str80;
  Address, DayOfYearOne, DayOfYearTwo: integer;
  IntegerTimeOne, IntegerTimeTwo: integer;
  NeedNewQSOForFileOne, NeedNewQSOForFileTwo: boolean;
  Command: Char;
  TotalFileOneContacts, TotalFileTwoContacts, TotalContacts: integer;
  LTQW: array[0..29] of Str80;
  LTQWHead, LTQWTail: integer;

begin
//  ClrScr;
//  TextColor(Yellow);
{  WriteLnCenter('MERGE UTILITY');
//  TextColor(Cyan);

  WriteLn;
  WriteLn('This procedure will merge two .log files together into a single log file');
  WriteLn('They will be shuffled so the result is in order by time and date.  Obvious');
  WriteLn('duplicate contacts will be removed when they appear in both logs.');
  WriteLn;
  WriteLn('If you have more than two logs to combine, you will need to run this procedure');
  WriteLn('multiple times and use a unique intermediate file name for the output file each');
  WriteLn('time.  Use the desired finished log name when merging the last log.');
  WriteLn;
}
  FileOneName := postform.FFEdit.Text; //GetResponse('Enter the filename of the first file to merge : ');
  if FileOneName = '' then Exit;

  FileTwoName := postform.SFEdit.Text; //GetResponse('Enter the filename of the second file to merge : ');
  if FileTwoName = '' then Exit;

  OutputFileName := postform.CFEdit.Text; //GetResponse('Enter filename for the combined log : ');
  if OutputFileName = '' then Exit;

  if (OutputFileName = FileOneName) or (OutputFileName = FileTwoName) then begin
    ShowMessage('ERROR!! You have specified on of the input files as the output file!!');
    Exit;
  end;

  if not OpenFileForRead(FileOne, FileOneName) then begin
    ShowMessage(FileOneName + ' not found!!');
//    WaitForKeyPressed;
    Exit;
  end;

  if not OpenFileForRead(FileTwo, FileTwoName) then begin
    ShowMessage(FileTwoName + ' not found!!');
//    WaitForKeyPressed;
    Exit;
  end;

  OpenFileForWrite(OutputFile, OutputFileName);

//  WriteLn('Loading in logs...');

  TotalContacts := 0;
  TotalFileOneContacts := 0;
  TotalFileTwoContacts := 0;

  NeedNewQSOForFileOne := true;
  NeedNewQSOForFileTwo := true;

  LTQWHead := 0;
  LTQWTail := 0;

  repeat
    if NeedNewQSOForFileOne then
      repeat
        FileStringOne := GetNextLogEntry(FileOne);

        DayOfYearOne := QuasiDayOfYear(GetLogEntryDateString(FileStringOne));
        IntegerTimeOne := GetLogEntryIntegerTime(FileStringOne);

        if FileStringOne <> '' then inc(TotalFileOneContacts);
        NeedNewQSOForFileOne := False;

        if LTQWHead <> LTQWTail then begin
          Address := LTQWTail;

          repeat
            if (GetLogEntryCall(LTQW[Address]) = GetLogEntryCall(FileStringOne)) and
              (GetLogEntryBand(LTQW[Address]) = GetLogEntryBand(FileStringOne)) and
              (GetLogEntryMode(LTQW[Address]) = GetLogEntryMode(FileStringOne)) and
              (GetLogEntryIntegerTime(LTQW[Address]) = GetLogEntryIntegerTime(FileStringOne)) then
              NeedNewQSOForFileOne := true;

            Address := (Address + 1) mod 30;
          until (Address = LTQWHead) or NeedNewQSOForFileOne;
        end;
      until not NeedNewQSOForFileOne;

    if NeedNewQSOForFileTwo then
      repeat
        FileStringTwo := GetNextLogEntry(FileTwo);

        DayOfYearTwo := QuasiDayOfYear(GetLogEntryDateString(FileStringTwo));
        IntegerTimeTwo := GetLogEntryIntegerTime(FileStringTwo);

        if FileStringTwo <> '' then inc(TotalFileTwoContacts);
        NeedNewQSOForFileTwo := False;

        if LTQWHead <> LTQWTail then begin
          Address := LTQWTail;

          repeat
            if (GetLogEntryCall(LTQW[Address]) = GetLogEntryCall(FileStringTwo)) and
              (GetLogEntryBand(LTQW[Address]) = GetLogEntryBand(FileStringTwo)) and
              (GetLogEntryMode(LTQW[Address]) = GetLogEntryMode(FileStringTwo)) and
              (GetLogEntryIntegerTime(LTQW[Address]) = GetLogEntryIntegerTime(FileStringTwo)) then
              NeedNewQSOForFileTwo := true;

            Address := (Address + 1) mod 30;
          until (Address = LTQWHead) or NeedNewQSOForFileTwo;
        end;

      until not NeedNewQSOForFileTwo;

//    GoToXY(1, WhereY);
//    postform.cm.Lines.Add('File 1 = ' + inttostr(TotalFileOneContacts) + '   File 2 = ' + inttostr(TotalFileTwoContacts));

    if (FileStringOne = '') and (FileStringTwo = '') then begin
      Close(OutputFile);
      Close(FileOne);
      Close(FileTwo);
//      GoToXY(1, WhereY);

      postform.cm.Lines.Add('There were ' + inttostr(TotalFileOneContacts) + ' contacts found in ' + FileOneName);
      postform.cm.Lines.Add('There were ' + inttostr(TotalFileTwoContacts) + ' contacts found in ' + FileTwoName);
      postform.cm.Lines.Add('There are ' + inttostr(TotalContacts) + ' total contacts saved in ' + OutputFileName);

      if TotalContacts <> (TotalFileOneContacts + TotalFileTwoContacts) then
        postform.cm.Lines.Add('There were ' + inttostr((TotalFileOneContacts + TotalFileTwoContacts) - TotalContacts) + ' matched QSOs found which were only saved once.');
      view(outputfilename);
      Exit;
    end;

    if ((FileStringOne <> '') and (DayOfYearOne < DayOfYearTwo)) or (FileStringTwo = '') then begin
      inc(TotalContacts);
      WriteLn(OutputFile, FileStringOne);

      LTQW[LTQWHead] := FileStringOne;
      LTQWHead := (LTQWHead + 1) mod 30;
      if LTQWHead = LTQWTail then LTQWTail := (LTQWTail + 1) mod 30;

      NeedNewQSOForFileOne := true;
    end
    else
      if ((FileStringTwo <> '') and (DayOfYearOne > DayOfYearTwo)) or (FileStringOne = '') then begin
        inc(TotalContacts);
        WriteLn(OutputFile, FileStringTwo);

        LTQW[LTQWHead] := FileStringTwo;
        LTQWHead := (LTQWHead + 1) mod 30;
        if LTQWHead = LTQWTail then LTQWTail := (LTQWTail + 1) mod 30;

        NeedNewQSOForFileTwo := true;
      end
      else
        if IntegerTimeOne < IntegerTimeTwo then begin
          inc(TotalContacts);
          WriteLn(OutputFile, FileStringOne);

          LTQW[LTQWHead] := FileStringOne;
          LTQWHead := (LTQWHead + 1) mod 30;
          if LTQWHead = LTQWTail then LTQWTail := (LTQWTail + 1) mod 30;

          NeedNewQSOForFileOne := true;
        end
        else
          if IntegerTimeOne > IntegerTimeTwo then begin
            inc(TotalContacts);
            WriteLn(OutputFile, FileStringTwo);

            LTQW[LTQWHead] := FileStringTwo;
            LTQWHead := (LTQWHead + 1) mod 30;
            if LTQWHead = LTQWTail then LTQWTail := (LTQWTail + 1) mod 30;

            NeedNewQSOForFileTwo := true;
          end
          else begin
            if (GetLogEntryCall(FileStringOne) = GetLogEntryCall(FileStringTwo)) and
              (GetLogEntryBand(FileStringOne) = GetLogEntryBand(FileStringTwo)) and
              (GetLogEntryMode(FileStringOne) = GetLogEntryMode(FileStringTwo)) then begin
              inc(TotalContacts);
              WriteLn(OutputFile, FileStringOne); { A dupe }
              NeedNewQSOForFileOne := true;
              NeedNewQSOForFileTwo := true;
            end
            else begin
              inc(TotalContacts);
              WriteLn(OutputFile, FileStringOne);
              NeedNewQSOForFIleOne := true;
            end;
          end;

  until False;

end;

procedure MakeKCJLog;

var
  KCJString, TimeString, OutputFileName: Str80;
  LogString, TempString: string;
  FileRead, FileWrite: Text;
  Band: BandType;
  Mode: ModeType;
  DayNumber, QSONumber: integer;
  BandChar: Char;
  Call: CallString;
  LastTime, RSTSent, RSTReceived, QTHReceived: Str20;

begin
//  ClrScr;
//  TextColor(Yellow);
{  WriteLnCenter('PRODUCE KCJ DISK FILE');
//  TextColor(Cyan);
  WriteLn;
  WriteLn('This procedure will produce a disk file in the format used by the KCJ contest');
  WriteLn('log checkers.  Submission of this file does not excuse you from sending in a');
  WriteLn('printed log.  It is just a nice thing to do, so they don''t have to manually');
  WriteLn('enter your log.');
  WriteLn;
}
  OutputFileName := postform.KCJEdit.Text; //GetResponse('Enter file name for output : ');
  if OutputFileName = '' then Exit;

  if not OpenFileForRead(FileRead, LogFileName) then begin
    ShowMessage(LogFileName + 'not found!!');
    Exit;
  end;

  if not OpenFileForWrite(FileWrite, OutputFileName) then begin
    ShowMessage('Unable to open ' + OutputFileName);
    Exit;
  end;

  QSONumber := 0;
//  Write(QSONumber);
  DayNumber := 0;
  LastTime := '0000';

  repeat
    repeat
      ReadLn(FileRead, LogString);
      Band := GetLogEntryBand(LogString);
    until (Band <> NoBand) or EOF(FileRead);

    if Band <> NoBand then begin
      case Band of
        Band160: BandChar := 'A';
        Band80: BandChar := 'B';
        Band40: BandChar := 'C';
        Band20: BandChar := 'D';
        Band15: BandChar := 'E';
        Band10: BandChar := 'F';
        Band6: BandChar := 'G';
      else BandChar := '?';
      end;

      ExpandTabs(LogString);

      TimeString := Copy(LogString, LogEntryHourAddress, 2) +
        Copy(LogString, LogEntryMinuteAddress, 2);

      if LastTime > TimeString then
        inc(DayNumber);

      if DayNumber > 0 then begin
        TimeString[1] := CHR(Ord(TimeString[1]) + 2);
        TimeString[2] := CHR(Ord(TimeString[2]) + 4);

        if TimeString[2] > '9' then begin
          TimeString[2] := CHR(Ord(TimeString[2]) - 10);
          TimeString[1] := CHR(Ord(TimeString[1]) + 1);
        end;
      end;

      LastTime := TimeString;

      Call := GetLogEntryCall(LogString);

      while length(Call) < 11 do
        Call := Call + ' ';

      TempString := GetLogEntryExchangeString(LogString);
      RSTSent := RemoveFirstString(TempString);
      RSTReceived := RemoveFirstString(TempString);
      QTHReceived := UpperCase(RemoveFirstString(TempString));

      KCJString := TimeString + BandChar + Call + RSTSent +
        RSTReceived + QTHReceived;

      if GetLogEntryQSOPoints(LogString) = 0 then
        KCJString := KCJString + ' '
      else
        if GetLogEntryMultString(LogString) <> '' then
          KCJString := KCJString + ':'
        else
          KCJString := KCJString + '.';

      KCJString := KCJString + '     ';
      WriteLn(FileWrite, KCJString);

      inc(QSONumber);
//      GoToXY(1, WhereY);
//      Write(QSONumber);
    end;

  until Eof(FileRead);
  Close(FileRead);
  Close(FileWrite);

  view(OutputFileName);

end;

function CheckGetPrefix(Call: CallString): Str20;

var
  Prefix, StandardCall: CallString;

begin
  StandardCall := StandardCallFormat(Call, true);

  if StringHas(StandardCall, '/') then begin
    Prefix := PrecedingString(StandardCallFormat(Call, true), '/');

        {KK1L: 6.68 Added AM to allow for aeronautical mobile stations}
    if (Copy(Prefix, 1, 2) = 'MM') or (Copy(Prefix, 1, 2) = 'AM') then begin
      Prefix := GetPrefix(PostcedingString(Prefix, '/'));
      Exit;
    end;

    if not StringHasNumber(Prefix) then
      Prefix := Prefix + '0';

    CheckGetPrefix := GetPrefix(Prefix);
  end
  else
    CheckGetPrefix := GetPrefix(StandardCall);
end;

procedure AddPrefix(Prefix: Str20; Band: BandType; Mode: ModeType);

var
  TempBytes: fourBYTEs;

begin
  if PrefixLists[Band, Mode].NumberPrefixes = 0 then
    New(PrefixLists[Band, Mode].List);

  with PrefixLists[Band, Mode] do begin
    CompressFormat(Prefix, TempBytes);
    List^[NumberPrefixes] := TempBytes;
    inc(NumberPrefixes);
  end;
end;

function WorkedPrefix(Prefix: Str20; Band: BandType; Mode: ModeType): boolean;

var
  Address: integer;
  TempBytes: fourBYTEs;

begin
  if PrefixLists[Band, Mode].NumberPrefixes = 0 then begin
    WorkedPrefix := False;
    Exit;
  end;

  CompressFormat(Prefix, TempBytes);

  with PrefixLists[Band, Mode] do
    for Address := 0 to NumberPrefixes - 1 do
      if (List^[Address][1] = TempBytes[1]) and
        (List^[Address][2] = TempBytes[2]) and
        (List^[Address][3] = TempBytes[3]) and
        (List^[Address][4] = TempBytes[4]) then begin
        WorkedPrefix := true;
        Exit;
      end;

  WorkedPrefix := False;
end;

function DomesticMultsOkay(FileString: string;
  var EData, MData: ContestExchange;
  var MultString: Str20): boolean;

{ This is the routine that works out if there is a multiplier problem for
  domestic multipliers. }

var
  CharPosition: integer;
  b: BYTE;
  ts: string;
begin
  DomesticMultsOkay := true;
  b := 0;

  if EData.DomMultQTH <> MData.DomMultQTH then { Different } begin

        { First case is if this should be marked as a domestic mult,
          but it isn't.  }

    if EData.DomesticMult and not MData.DomesticMult then begin
      DomesticMultsOkay := False;
//      TextColor(Yellow);
//      WriteLn(FileString);

      ts := FileString + #13 + #13 + EData.DomMultQTH + ' multiplier is missing!' + #13 + #13 + 'Okay to add it?';
      if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDYes then

{      repeat
        Key := UpCase(GetKey(EData.DomMultQTH + ' multiplier is missing!  Okay to add it? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
//      GoToXY(1, WhereY);
//      ClrEol;

      if Key = 'Y' then
       }if MultString = '' then
          MultString := EData.DomMultQTH
        else begin
          CharPosition := pos(MData.QTHString, MultString);

          if CharPosition > 0 then
            Delete(MultString, CharPosition, length(MData.QTHString) + 1);

          Insert(EData.DomMultQTH + ' ', MultString, CharPosition);
        end;
    end;

            { Here, they are both domestic mults, but are different }

    if EData.DomesticMult and MData.DomesticMult then begin
      DomesticMultsOkay := False;
//      TextColor(Yellow);
//      WriteLn(FileString);

      ts := FileString + #13 + #13 + 'Domestic multiplier should be ' + EData.DomMultQTH + #13 + #13 + 'Okay to change it?';
      if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDYes then

{      repeat
        Key := UpCase(GetKey('Domestic multiplier should be ' +
          EData.DomMultQTH + '!  Okay to change it? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
//      GoToXY(1, WhereY);
//      ClrEol;

      if Key = 'Y' then
      }begin
        CharPosition := pos(Mdata.DomMultQTH, MultString);

        if CharPosition > 0 then begin
          Delete(MultString, CharPosition, length(MData.DomMultQTH));
          Insert(EData.DomMultQTH, MultString, CharPosition);
        end
        else begin
          CharPosition := pos(Mdata.QTHString, MultString);

          if CharPosition > 0 then begin
            Delete(MultString, CharPosition, length(MData.QTHString));
            Insert(EData.DomMultQTH, MultString, CharPosition);
          end;
        end;
      end;
    end;
  end;

    { Now we may or may not have the same domestic qth as the mult. }

  if (not EData.DomesticMult) and Mdata.DomesticMult then begin
    DomesticMultsOkay := False;
//    TextColor(Yellow);
//    WriteLn(FileString);

    if EData.DomMultQTH = MData.DomMultQTH then begin
      ts := FileString + #13 + #13 + 'You have already worked ' + EData.DomMultQTH + #13 + #13 + 'Okay to remove it?';
      b := MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION);

    {      repeat
        Key := UpCase(GetKey('You have already worked ' + EData.DomMultQTH + '!  Okay to remove it? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
}
      //      GoToXY(1, WhereY);
//      ClrEol;
    end
    else begin
      ts := FileString + #13 + #13 + 'This station is not in ' + MData.DomMultQTH + #13 + #13 + 'Okay to remove mult?';
      b := MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION);

    {      repeat
        Key := UpCase(GetKey('This station is not in ' + MData.DomMultQTH + '!  Okay to remove mult? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
}
      //      GoToXY(1, WhereY);
//      ClrEol;
    end;

//    if Key = 'Y' then
    if b = idyes then begin
      CharPosition := pos(MData.DomMultQTH, MultString);

      if CharPosition > 0 then
        Delete(MultString, CharPosition, length(MData.DomMultQTH) + 1)
      else begin
        CharPosition := pos(MData.QTHString, MultString);

        if CharPosition > 0 then
          Delete(MultString, CharPosition, length(MData.QTHString) + 1)
      end;
    end;
  end;
end;

function DXMultsOkay(FileString: string; var EData, MData: ContestExchange; var MultString: Str20): boolean;

{ This is the routine that works out if there is a multiplier problem for
  DX multipliers. }

var
  CharPosition: integer;
  ts: string;
  b: BYTE;
begin
  b := 0;
  DXMultsOkay := true;

  if EData.DXQTH <> MData.DXQTH then { Different } begin

    { First case is if this should be marked as a DX mult, but it isn't. }

    if EData.DXMult and not MData.DXMult then begin
      DXMultsOkay := False;
//      TextColor(Yellow);
//      WriteLn(FileString);
      ts := FileString + #13 + #13 + EData.DXQTH + ' multiplier is missing!' + #13 + #13 + 'Okay to add it?';
      if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDYes then

{      repeat
        Key := UpCase(GetKey((Y / n): '));
      until (Key = 'Y') or (Key = 'N');
//      GoToXY(1, WhereY);
//      ClrEol;
}
//      if Key = 'Y' then
        if MultString = '' then
          MultString := EData.DXQTH
        else begin
          CharPosition := pos(MData.QTHString, MultString);

          if CharPosition > 0 then
            Delete(MultString, CharPosition, length(MData.QTHString) + 1);

          Insert(EData.DXQTH + ' ', MultString, CharPosition);
        end;
    end;

        { Here, they are both DX mults, but are different }

    if EData.DXMult and MData.DXMult then begin
      DXMultsOkay := False;
//      TextColor(Yellow);
//      WriteLn(FileString);

      ts := FileString + #13 + #13 + 'DX multiplier should be ' + EData.DXQTH + #13 + #13 + 'Okay to change it?';
      if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDYes then

{      repeat
        Key := UpCase(GetKey('DX multiplier should be ' + EData.DXQTH + '!  Okay to change it? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
//      GoToXY(1, WhereY);
//      ClrEol;

      if Key = 'Y' then
      }begin
        CharPosition := pos(Mdata.DXQTH, MultString);

        if CharPosition > 0 then begin
          Delete(MultString, CharPosition, length(MData.DXQTH));
          if not StringHas(MultString, EData.DXQTH) then
            Insert(EData.DXQTH, MultString, CharPosition);
        end
        else begin
          CharPosition := pos(Mdata.QTHString, MultString);

          if CharPosition > 0 then begin
            Delete(MultString, CharPosition, length(MData.QTHString));
            if not StringHas(MultString, EData.DXQTH) then
              Insert(EData.DXQTH, MultString, CharPosition);
          end;
        end;
      end;
    end;
  end;

    { Now we may or may not have the same DX qth as the mult. }

  if (not EData.DXMult) and Mdata.DXMult then begin
    DXMultsOkay := False;

//    WriteLn(FileString);

    if EData.DXQTH = MData.DXQTH then begin
      ts := FileString + #13 + #13 + 'You have already worked ' + EData.DXQTH + #13 + #13 + 'Okay to remove mult?';
      b := MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION)

    {      repeat
        Key := UpCase(GetKey('You have already worked ' + EData.DXQTH + '!  Okay to remove mult? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
    }
    end
    else begin

      ts := FileString + #13 + #13 + 'This station is not in ' + MData.DXQTH + #13 + #13 + 'Okay to remove mult?';
      b := MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION)

    {      repeat
        Key := UpCase(GetKey('This station is not in ' + MData.DXQTH + '!  Okay to remove mult? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
    }
    end;

//    if Key = 'Y' then
    if b = idyes then begin
      CharPosition := pos(MData.DXQTH, MultString);

      if CharPosition > 0 then
        Delete(MultString, CharPosition, length(MData.DXQTH) + 1);
    end;
  end;
end;

function PrefixMultsOkay(FileString: string;
  var EData, MData: ContestExchange;
  var MultString: Str20): boolean;

{ This is the routine that works out if there is a multiplier problem for
  Prefix multipliers. }

var
  CharPosition: integer;
  ts: string;
  b: BYTE;
begin
  PrefixMultsOkay := true;
  b := 0;

  if EData.Prefix <> MData.Prefix then { Different } begin

    { First case is if this should be marked as a Prefix mult, but it isn't. }

    if EData.PrefixMult and not MData.PrefixMult then begin
      PrefixMultsOkay := False;
//      TextColor(Yellow);
//      WriteLn(FileString);
      ts := FileString + #13 + #13 + 'Prefix multiplier is missing!' + #13 + #13 + 'Okay to add it?';
      if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDYes then
{
      repeat
        Key := UpCase(GetKey('Prefix multiplier is missing!  Okay to add it? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
}
//      GoToXY(1, WhereY);
//      ClrEol;

//      if Key = 'Y' then
        if MultString = '' then
          MultString := EData.Prefix
        else begin
          CharPosition := pos(MData.QTHString, MultString);

          if CharPosition > 0 then
            Delete(MultString, CharPosition, length(MData.QTHString) + 1);

          Insert(EData.Prefix + ' ', MultString, CharPosition);
        end;
    end;

            { Here, they are both Prefix mults, but are different }

    if EData.PrefixMult and MData.PrefixMult then begin
      PrefixMultsOkay := False;
//      TextColor(Yellow);
//      WriteLn(FileString);
      ts := FileString + #13 + #13 + 'Prefix multiplier should be ' + Edata.Prefix + #13 + #13 + 'Okay to change it?';
      if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDYes then
{      repeat
        Key := UpCase(GetKey('Prefix multiplier should be ' + Edata.Prefix + '!  Okay to change it? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
//      GoToXY(1, WhereY);
//      ClrEol;

      if Key = 'Y' then
      }begin
        CharPosition := pos(Mdata.Prefix, MultString);

        if CharPosition > 0 then begin
          Delete(MultString, CharPosition, length(MData.Prefix));
          Insert(EData.Prefix, MultString, CharPosition);
        end
        else begin
          CharPosition := pos(Mdata.QTHString, MultString);

          if CharPosition > 0 then begin
            Delete(MultString, CharPosition, length(MData.QTHString));
            Insert(EData.Prefix, MultString, CharPosition);
          end;
        end;
      end;
    end;
  end;

    { Now we may or may not have the same Prefix qth as the mult. }

  if (not EData.PrefixMult) and Mdata.PrefixMult then begin
    PrefixMultsOkay := False;
//    TextColor(Yellow);
//    WriteLn(FileString);

    if EData.Prefix = MData.Prefix then begin
      ts := FileString + #13 + #13 + 'You have already worked the ' + Edata.Prefix + ' prefix!' + #13 + #13 + 'Okay to remove it?';
      b := MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION);
    {      repeat
        Key := UpCase(GetKey('You have already worked the ' + EData.Prefix +
          ' prefix!  Okay to remove it? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
}
      //      GoToXY(1, WhereY);
//      ClrEol;
    end
    else begin
      ts := FileString + #13 + #13 + MData.Prefix + ' is not the correct prefix!' + Edata.Prefix + ' prefix!' + #13 + #13 + 'Okay to remove mult?';
      b := MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION);

{      repeat
        Key := UpCase(GetKey(MData.Prefix + ' is not the correct prefix!  Okay to remove mult? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
}
      //      GoToXY(1, WhereY);
//      ClrEol;
    end;

//    if Key = 'Y' then
    if b = idyes then begin
      CharPosition := pos(MData.Prefix, MultString);

      if CharPosition > 0 then
        Delete(MultString, CharPosition, length(MData.Prefix) + 1);
    end;
  end;
end;

function ZoneMultsOkay(var FileString: string;
  var EData, MData: ContestExchange;
  var MultString: Str20;
  CheckZoneAgainstCTYDotDat: boolean): boolean;

{ This is the routine that works out if there is a multiplier problem for
  Zone multipliers.  It will also look at the zone suggested by the callsign
  and make sure that it looks correct. }

var
  CharPosition: integer;
  ExchangeZone, Result1, CallsignZone: integer;
  CallsignZoneString: Str40;
  ExchangeString: string;
  ts: string;
  b: BYTE;
begin
  ZoneMultsOkay := true;
  b := 0;
//  TextColor(Yellow);

  if CheckZoneAgainstCTYDotDat then begin
    CallsignZone := CountryTable.GetZone(EData.Callsign);

    if CallsignZone > 0 then begin
      Val(EData.Zone, ExchangeZone, Result1);

      if (Result1 <> 0) or
        ((CountryTable.ZoneMode = ITUZoneMode) and (ExchangeZone <> CallsignZone)) or
        ((CountryTable.ZoneMode = CQZoneMode) and (ExchangeZone <> CallsignZone) and
        (ExchangeZone <> 3) and (ExchangeZone <> 4) and (ExchangeZone <> 5)) then begin
        Str(CallsignZone, CallsignZoneString);

        while length(CallsignZoneString) < 2 do
          CallsignZoneString := '0' + CallsignZoneString;

        ts := FileString + #13 + #13 + 'Zone incorrect?' + #13 + #13 + 'Change to zone ' + CallsignZoneString + ' ?';
        if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDYes then

//        TextColor(Yellow);
{        WriteLn(FileString);

        repeat
          Key := UpCase(GetKey('Zone incorrect?  Change to zone ' + CallsignZoneString + '? (Y/N) : '));
        until (Key = 'Y') or (Key = 'N');

}
       //        GoToXY(1, WhereY);
 //       ClrEol;

        {//          if Key = 'Y' then}begin
          ZoneMultsOkay := False;

          EData.Zone := CallsignZoneString;
          Sheet.SetMultFlags(EData);

          ExchangeString := Copy(FileString, LogEntryExchangeAddress, LogEntryExchangeWidth);

          RemoveLastString(ExchangeString);
          ExchangeString := ExchangeString + ' ' + CallsignZoneString;

          while length(ExchangeString) < LogEntryExchangeWidth do
            ExchangeString := ExchangeString + ' ';

          Delete(FileString, LogEntryExchangeAddress, LogEntryExchangeWidth);

          Insert(ExchangeString, FileString, LogEntryExchangeAddress);
        end;
      end;
    end;
  end;

{    MakeSureMults are not DUPE or ZERO.}

  if EData.Zone <> MData.Zone then { Different } begin

    { First case is if this should be marked as a Zone mult, but it isn't. }

    if EData.ZoneMult and not MData.ZoneMult then begin
      ZoneMultsOkay := False;

      ts := FileString + #13 + #13 + 'Zone ' + Edata.Zone + ' multiplier is missing!' + #13 + #13 + 'Okay to add it?';
      if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDYes then

      //      TextColor(Yellow);
{      WriteLn(FileString);

      repeat
        Key := UpCase(GetKey('Zone ' + Edata.Zone + ' multiplier is missing!  Okay to add it? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
}
      //      GoToXY(1, WhereY);
//      ClrEol;

//      if Key = 'Y' then
        if MultString = '' then
          MultString := EData.Zone
        else
          MultString := MultString + ' ' + EData.Zone;
    end;

            { Here, they are both Zone mults, but are different }

    if EData.ZoneMult and MData.ZoneMult then begin
      ZoneMultsOkay := False;

      ts := FileString + #13 + #13 + 'Zone multiplier should be ' + Edata.Zone + #13 + #13 + 'Okay to change it?';
      if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDYes then

//      TextColor(Yellow);
{      WriteLn(FileString);

      repeat
        Key := UpCase(GetKey('Zone multiplier should be ' + EData.Zone + '!  Okay to change it? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');

}
      //      GoToXY(1, WhereY);
//      ClrEol;

      {//      if Key = 'Y' then}begin
        CharPosition := pos(Mdata.Zone, MultString);

        if CharPosition > 0 then
          Delete(MultString, CharPosition, length(MData.Zone));

        MultString := MultString + EData.Zone;
      end;
    end;
  end;

    { Now we may or may not have the same Zone qth as the mult. }

  if (not EData.ZoneMult) and Mdata.ZoneMult then begin
    ZoneMultsOkay := False;
//    TextColor(Yellow);
//    WriteLn(FileString);

    if EData.Zone = MData.Zone then begin
      ts := FileString + #13 + #13 + 'You have already worked zone ' + Edata.Zone + #13 + #13 + 'Okay to remove mult?';
      b := MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION);

 {     repeat
        Key := UpCase(GetKey('You have already worked zone ' + EData.Zone + '!  Okay to remove mult? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
}
//      GoToXY(1, WhereY);
//      ClrEol;
    end
    else begin
      ts := FileString + #13 + #13 + 'Incorrect Zone multiplier!!' + #13 + #13 + 'Okay to remove mult?';
      b := MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION);
    {      repeat
        Key := UpCase(GetKey('Incorrect Zone multiplier!!  Okay to remove mult? (Y/N) : '));
      until (Key = 'Y') or (Key = 'N');
}
//      GoToXY(1, WhereY);
//      ClrEol;
    end;

//    if Key = 'Y' then
    if b = idyes then begin
      CharPosition := pos(MData.Zone, MultString);

      if CharPosition > 0 then
        Delete(MultString, CharPosition, length(MData.Zone) + 1);
    end;
  end;
end;

procedure MultCheck;

{ This routine will do a complete log check as follows:
    - Checks for LOG.TMP and appends it to LOG.DAT file.
    - Looks at the LOGCFG.DAT file to determine exchange and mult types.
    - Goes through the log and verifies all multipliers.
}

var
  EData, MData: ContestExchange;
  MultString: Str20;
  CharPosition, QSONumber: integer;
  FileString: string;
  CheckZones, ProblemFound: boolean;
  Key: Char;
  FileRead, FileWrite: Text;

begin
  ViewForm.c.Clear;
//  ClrScr;
//  TextColor(Yellow);
{  WriteLnCenter('MULTIPLIER CHECK PROCEDURE');
//  TextColor(Cyan);
  WriteLn;
  WriteLn('This procedure will look through your log and check all of your multipliers.');
  WriteLn('If it finds a duplicate or missing multiplier, it will show you the contact.');
  WriteLn;
  WriteLn('It is necessary to be logged into the same directory you used during the');
  WriteLn('contest so the LOGCFG.DAT file can be used to determine the proper format for');
  WriteLn('the multiplier information.');
  WriteLn;

  if not OkayToProceed then exit;
}
    { This needs do be done before the SetUpPostParameters command.  Fixed
      crashing occurring in 6.24 that didn't happen in 6.20. }

  DupeInit;
  Sheet.DisposeOfMemoryAndZeroTotals;

//  WriteLn;

  if not SetUpPostParametersFromLOGCFGFile then begin
//    WaitForKeyPressed;
    Exit;
  end;

  if DoingZoneMults then begin
//    TextColor(Cyan);
    ShowMessage('This contest uses zone multipliers.  If you want, this procedure can check the zones entered into the log against the CTY.DAT file and alert you to any differences and give you the option of changing it.');

{    repeat
      Key := UpCase(GetKey('Would you like to perform this zone check? (Y/N): '));
      if Key = EscapeKey then exit;
    until (Key = 'Y') or (Key = 'N');
    WriteLn;
}
    CheckZones := postform.CheckZonesCB.Checked //Key = 'Y';
  end;

  if not OpenFileForRead(FileRead, LogFileName) then begin
    ShowMessage('Unable to open ' + LogFileName + '!!');
    Exit;
  end;

  if not OpenFileForWrite(FileWrite, TempFileName) then begin
    Close(FileRead);
    ShowMessage('Unable to open ' + TempFileName + ' for output!!');
//    WaitForKeyPressed;
    Exit;
  end;

  QSONumber := 0;
//  Write(QSONumber);
  ProblemFound := False;

  while not Eof(FileRead) do begin
    ReadLn(FileRead, FileString);

    TempString := UpperCase(FileString);

    if StringHas(FileString, '*DUPE*') or StringHas(FileString, '*ZERO*') then begin
      WriteLn(FileWrite, FileString);
//      TextColor(Cyan);
      inc(QSONumber);
 //     GoToXY(1, WhereY);
//      postform.cm.Lines.Add(inttostr(QSONumber));
  //    GoToXY(1, WhereY);
//      TextColor(Yellow);
      Continue;
    end;

    if GetContestExchangeFromLogEntryExchange(FileString, EData) then begin
//      TextColor(Cyan);
      inc(QSONumber);
//      GoToXY(1, WhereY);

//      postform.cm.Lines.Add(inttostr(QSONumber));
//      GoToXY(1, WhereY);
 //     TextColor(Yellow);

      GetContestExchangeFromMultiplierString(FileString, MData);

      MultString := GetLogEntryMultString(FileString);

            { First we look at the Domestic multipliers }

      if DoingDomesticMults and
        (DomesticCountryCall(EData.Callsign) or StringHasLowerCase(EData.QTHString)) then
        if not DomesticMultsOKay(FileString, EData, MData, MultString) then
          ProblemFound := true;

      if ProblemFound then begin
        Delete(FileString, LogEntryMultAddress, LogEntryMultWidth);
        while length(MultString) < 8 do MultString := MultString + ' ';
        Insert(MultString, FileString, LogEntryMultAddress);

//        GoToXY(1, WhereY - 1);
//        ClrEol;
//        TextColor(Cyan);
        ViewForm.c.Lines.Add(FileString);
        ProblemFound := False;
        MultString := GetLogEntryMultString(FileString);
      end;

      if DoingDXMults and not DomesticCountryCall(EData.Callsign) then
        if not DXMultsOKay(FileString, EData, MData, MultString) then
          ProblemFound := true;

      if ProblemFound then begin
        Delete(FileString, LogEntryMultAddress, LogEntryMultWidth);
        while length(MultString) < 8 do MultString := MultString + ' ';
        Insert(MultString, FileString, LogEntryMultAddress);

//        GoToXY(1, WhereY - 1);
//        ClrEol;
//        TextColor(Cyan);
        ViewForm.c.Lines.Add(FileString);
        ProblemFound := False;
        MultString := GetLogEntryMultString(FileString);
      end;

      if DoingPrefixMults then
        if not PrefixMultsOKay(FileString, EData, MData, MultString) then
          ProblemFound := true;

      if ProblemFound then begin
        Delete(FileString, LogEntryMultAddress, LogEntryMultWidth);
        while length(MultString) < 8 do MultString := MultString + ' ';
        Insert(MultString, FileString, LogEntryMultAddress);

//        GoToXY(1, WhereY - 1);
//        ClrEol;
//        TextColor(Cyan);
        ViewForm.c.Lines.Add(FileString);
        ProblemFound := False;
        MultString := GetLogEntryMultString(FileString);
      end;

      if DoingZoneMults then
        if not ZoneMultsOKay(FileString, EData, MData, MultString, CheckZones) then
          ProblemFound := true;

      if ProblemFound then begin
//        TextColor(Yellow);
        Delete(FileString, LogEntryMultAddress, LogEntryMultWidth);
        while length(MultString) < 8 do MultString := MultString + ' ';
        Insert(MultString, FileString, LogEntryMultAddress);

  //      GoToXY(1, WhereY - 1);
   //     ClrEol;
    //    TextColor(Cyan);
        ViewForm.c.Lines.Add(FileString);
        ProblemFound := False;
      end;

      Sheet.AddQSOToSheets(EData);
    end;

    WriteLn(FileWrite, FileString);
  end;

  Close(FileRead);
  Close(FileWrite);
  Sheet.DisposeOfMemoryAndZeroTotals;

  PushLogFiles;
  SysUtils.RenameFile(TempFileName, LogFileName);
//  TextColor(Yellow);
//  WriteLn;
  postform.cm.Lines.Add('Multiplier check completed.  Your original log can be found as ' + LastPushedLogName);
//  WaitForKeyPressed;
end;

procedure PrefixMultCheck;

var
  NameString, FileName: Str80;
  FileString: string;
  Prefix, MultString: Str20;
  Band: BandType;
  Mode: ModeType;
  CharPointer, StringLength, QSONumber: integer;
  Command, Key: Char;
  MultByBand, MultByMode: boolean;
  MultiplierString, Call: CallString;
  FileRead, FileWrite, FileAppend: Text;

begin
//  ClrScr;
//  TextColor(Yellow);
  WriteLnCenter('PREFIX MULTIPLIER CHECK PROCEDURE');
//  TextColor(Cyan);
  WriteLn;
  WriteLn('This procedure will examine your log to verify the prefix multipliers.  It');
  WriteLn('looks at each callsign, determines its prefix, and then checks to see if');
  WriteLn('it is a new multiplier.  It will check to make sure the proper entry is in');
  WriteLn('the multiplier column.  If a multiplier is missing that should be marked, or');
  WriteLn('if a multiplier is flagged that should not be, the contact will be displayed');
  WriteLn('and you will be asked if a correction should be made.  Your original log will');
  WriteLn('be saved as PLOG###.BAK and the new log file will be saved to the active log');
  WriteLn('name.  If this is not what you want to do, press ESCAPE now.');
  WriteLn;

  for Band := Band160 to NoBand do
    for Mode := cw to Both do
      PrefixLists[Band, Mode].NumberPrefixes := 0;

  repeat
    Key := UpCase(GetKey('Do prefix multipliers count again on each mode? (Y/N or ESCAPE to abort) : '));
    if Key = EscapeKey then Exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;

  MultByMode := Key = 'Y';

  repeat
    Key := UpCase(GetKey('Do prefix multipliers count again on each band? (Y/N or ESCAPE to abort) : '));
    if Key = EscapeKey then Exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;

  MultByBand := Key = 'Y';

  PushLogFiles;
//  TextColor(Cyan);
  WriteLn('Original copy of ', LogFileName, ' saved as ', LastPushedLogName);

  if not OpenFileForRead(FileRead, LastPushedLogName) then begin
    ShowMessage(LastPushedLogName + ' not found!!');
//    WaitForKeyPressed;
    Exit;
  end;

  if not OpenFileForWrite(FileWrite, LogFileName) then begin
    Close(FileRead);
    ShowMessage('Unable to open ' + LogFileName + ' for output!!');
//    WaitForKeyPressed;
    Exit;
  end;

  QSONumber := 0;
  Write(QSONumber);

  repeat
    repeat
      ReadLn(FileRead, FileString);
      Band := GetLogEntryBand(FileString);
      if ((Band = NoBand) and not EOF(FileRead)) then
        WriteLn(FileWrite, FileString);
    until (Band <> NoBand) or EOF(FileRead);

    if (Band <> NoBand) and not StringHas(FileString, 'DUPE') then begin
      inc(QSONumber);
//      GoToXY(1, WhereY);
      Write(QSONumber);

      ExpandTabs(FileString);
      Mode := GetLogEntryMode(FileString);
      Call := StandardCallFormat(GetLogEntryCall(FileString), False);

      if not MultByBand then Band := All;
      if not MultByMode then Mode := Both;

      Prefix := UpperCase(CheckGetPrefix(Call));

      MultString := UpperCase(GetLogEntryMultString(FileString));

      if (MultString = '') then begin
        if not WorkedPrefix(Prefix, Band, Mode) then begin
          while length(Prefix) < length(MultString) do
            Prefix := Prefix + ' ';

          Delete(FileString, LogEntryMultAddress, length(Prefix));
          Insert(Prefix, FileString, LogEntryMultAddress);
          AddPrefix(Prefix, Band, Mode);
        end;

        WriteLn(FileWrite, FileString);
        Continue;
      end;

      if MultString <> Prefix then begin
    //    GoToXY(1, WhereY);
        WriteLn('I am about to change the prefix for ', Call, ' from ', MultString, ' to ', Prefix, '.');

        repeat
          Key := UpCase(GetKey('Is this okay? (Y/N) : '));
        until (Key = 'Y') or (Key = 'N');
        WriteLn;

        if Key = 'Y' then
          if not WorkedPrefix(Prefix, Band, Mode) then begin
            while length(Prefix) < length(MultString) do
              Prefix := Prefix + ' ';

            Delete(FileString, LogEntryMultAddress, length(Prefix));
            Insert(Prefix, FileString, LogEntryMultAddress);
            AddPrefix(Prefix, Band, Mode);
          end;

        WriteLn(FileWrite, FileString);
        Continue;
      end;

      if MultString = Prefix then begin
        if WorkedPrefix(Prefix, Band, Mode) then begin
          Delete(FileString, LogEntryMultAddress, length(Prefix));

          for CharPointer := 1 to length(Prefix) do
            Prefix[CharPointer] := ' ';

          Insert(Prefix, FileString, LogEntryMultAddress);
        end
        else
          AddPrefix(Prefix, Band, Mode);

        WriteLn(FileWrite, FileString);
        Continue;
      end;
    end;

  until Eof(FileRead);

  Close(FileRead);
  Close(FileWrite);
  WriteLn;
  WriteLn('Completed');
end;

procedure PullSpecificComputerLog;

var
  //Key,
  ComputerID: Str20;
  KeepID: boolean;
  FileRead, FileWrite: Text;
  OutputFileName: Str40;
  FileString: Str160;
  NumberQSOs, NumberNotes, Line: integer;
  Band: BandType;
  ts: string;
begin
//  ClrScr;
//  TextColor(Yellow);
{  WriteLnCenter('PULL OUT LOG FOR ONE SPECIFIC COMPUTER');
//  TextColor(Cyan);
  WriteLn;
  WriteLn('This procedure will create a new log file with only the QSOs and notes from');
  WriteLn('a specific computer.  It is assume you used the COMPUTER ID feature of the');
  WriteLn('TR program.  This puts a single character (A-Z) just after the QSO number in');
  WriteLn('the log.');
  WriteLn;
}
{  repeat
    ComputerID := UpCase(GetKey('Computer ID to pull out (SPACE for no ID QSOs, ESCAPE to exit) : '));
    if ComputerID = EscapeKey then exit;
  until ((ComputerID >= 'A') and (ComputerID <= 'Z')) or (ComputerID = ' ');
  WriteLn;
}
  ComputerID := postform.CompIDedit.Text;

//  if ComputerID <> '' then
  KeepID := postform.RemoveIDCB.Checked;
  {  begin
    repeat
      Key := UpCase(GetKey('Do you want to remove the computer ID in the new log? (Y/N) : '));
      if Key = EscapeKey then exit;
    until (Key = 'Y') or (Key = 'N');
    WriteLn;
    KeepID := Key = 'N';
  end

  else
    KeepID := true;
}

  OutputFileName := postform.SaveIDEdit.Text;
  if OutputFileName = '' then Exit;
  if FileExists(OutputFileName) then begin
    ts := OutputFileName + ' already exists!!  Okay to overwrite?';
    if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDno then Exit;
  end;
    {  while true do
  begin
    OutputFileName := GetResponse('Enter filename to save specific log to : ');
    if OutputFileName = '' then exit;

    if OutputFileName = LogFileName then exit;

    if FileExists(OutputFileName) then
    begin
      repeat
        Key := UpCase(GetKey(OutputFileName + ' already exists!!  Okay to overwrite? (Y/N) : ' ));
        if Key = EscapeKey then exit;
      until (Key = 'Y') or (Key = 'N');
      WriteLn;

      if Key = 'Y' then Break;
    end
    else
      Break;
  end;
}
  GetCopyOfHeader;

  NumberQSOs := 0;
  NumberNotes := 0;

  if not OpenFileForRead(FileRead, LogFileName) then begin
    ShowMessage(LogFileName + 'not found!!');
//    WaitForKeyPressed;
    Exit;
  end;

  if not OpenFileForWrite(FileWrite, OutputFileName) then begin
    ShowMessage('Unable to open ' + OutputFileName);
//    WaitForKeyPressed;
    Exit;
  end;

  repeat
    repeat
      ReadLn(FileRead, FileString);
      Band := GetLogEntryBand(FileString);
    until (Band <> NoBand) or EOF(FileRead) or (Copy(FileString, 1, 1) = ';');

    if Copy(FileString, 1, 1) = ';' then { This is a note } begin
      if StringHas(FileString, ComputerID + ':') then { A note for us } begin
        WriteLn(FileWrite, FileString);
        inc(NumberNotes);
      end;
    end

    else
      if Band <> NoBand then
        if GetLogEntryComputerID(FileString) = ComputerID then begin
          if (NumberQSOs mod 50) = 0 then begin
            if NumberQSOs <> 0 then Write(FileWrite, ControlL);

            for Line := 0 to NumberHeaderLines - 1 do
              WriteLn(FileWrite, Header[Line]);
          end
          else
            if (NumberQSOs mod 10) = 0 then WriteLn(FileWrite);

          if not KeepID then FileString[LogEntryComputerIDAddress] := ' ';
          WriteLn(FileWrite, FileString);
          inc(NumberQSOs);
        end;

  until Eof(FileRead);

  Close(FileRead);
  Close(FileWrite);

  postform.cm.Lines.Add('There were, ' + inttostr(NumberQSOs) + ' QSOs written to ' + OutputFileName);
  postform.cm.Lines.Add('There were, ' + inttostr(NumberNotes) + ' notes saved.');

  View(OutputFileName);
end;

procedure K1EANetworkCleanup;

var
  k1eaInputFileName, OutputFileName: String;
  LogDate, LogTime, LogCall, Callsign: CallString;
  LogBand: BandType;
  DateString, TimeString, FreqString: Str20;
  FileRead, FileWrite: Text;
  NumberLogEntriesSaved, NumberDeletesMatched, NumberDeleteEntries, Index: integer;
  UnmatchedEntryCount: integer;
  FileString: string;
  TooManyDeleteEntriesFound, DeleteThisEntry: boolean;
  Frequency: LONGINT;
  BandEntry: BandType;
  LogMode, Mode: ModeType;

begin
//  ClearScreenAndTitle('K1EA NETWORK LOG CLEANUP');
{
  WriteLn('This procedure will process the delete commands saved in the TR log file');
  WriteLn('as a result of using the K1EA edit feature during the contest.  If the');
  WriteLn('log entry for a delete command can not be found, it will be listed at the');
  WriteLn('end of the procedure.');
  WriteLn;
}
  k1eaInputFileName := postform.K1EAEdit.Text; //GetResponse('Enter filename to process (none to exit) : ');

  if k1eaInputFileName = '' then Exit;

  if not OpenFileForRead(FileRead, k1eaInputFileName) then begin
    ShowMessage('Unable to find ' + k1eaInputFilename);
    exit;
  end;

  New(DeleteEntryArray);
  NumberDeleteEntries := 0;
  TooManyDeleteEntriesFound := False;

//  WriteLn('First pass - collected delete commands from the log...');

    { A deleted entry looks like this:

; DELETE QSO at 29-NOV-03 00:00 with WK0EX on 21010000  }

  while not Eof(FileRead) do begin
    ReadLn(FileRead, FileString);

    if Copy(FileString, 1, 12) = '; DELETE QSO' then
      if NumberDeleteEntries < MaxDeleteEntries then begin
        Delete(FileString, 1, 16);

        DateString := RemoveFirstString(FileString);
        TimeString := RemoveFirstString(FileString);
        RemoveFirstString(FileString); { with }
        Callsign := RemoveFirstString(FileString);
        RemoveFirstString(FileString); { on }
        FreqString := RemoveFirstString(FileString);

        Val(FreqString, Frequency, Result);

        if Result <> 0 then begin
          ShowMessage('Improper delete entry found with ' + Callsign);
          Dispose(DeleteEntryArray);
     //     WaitForKeyPressed;
          Exit;
        end;

        CalculateBandMode(Frequency, BandEntry, Mode);

        if BandEntry = NoBand then begin
          ShowMessage('Improper delete entry found with ' + Callsign);
          Dispose(DeleteEntryArray);
     //     WaitForKeyPressed;
          Exit;
        end;

        with DeleteEntryArray^[NumberDeleteEntries] do begin
          Band := BandEntry;
          Call := Callsign;
          Date := DateString;
          Time := TimeString;
        end;

        inc(NumberDeleteEntries);
      end

      else
        TooManyDeleteEntriesFound := true;

  end;

  Close(FileRead);

  showmessage('There were ' + inttostr(NumberDeleteEntries) + ' delete entries found in the log.');

  if NumberDeleteEntries = 0 then begin
    Dispose(DeleteEntryArray);
    showmessage('No edits need to be made to your log.');
//    WaitForKeyPressed;
    Exit;
  end;

  OutputFileName := postform.k1eaEDE.Text; //GetResponse('Entry filename to save edited log file to : ');

  if OutputFileName = '' then begin
    Dispose(DeleteEntryArray);
    Exit;
  end;

  if not OpenFileForRead(FileRead, k1eaInputFileName) then Exit;
  if not OpenFileForWrite(FileWrite, OutputFileName) then Exit;

//  WriteLn('Second pass - creating new log file..');

  NumberLogEntriesSaved := 0;
  NumberDeletesMatched := 0;

{ A normal log entry looks like this

 15CW  29-NOV-03 00:00   12  WK0EX          599  599  04            04       3 }

  while not Eof(FileRead) do begin
    DeleteThisEntry := False;

    ReadLn(FileRead, FileString);

    LogBand := GetLogEntryBand(FileString);
    LogMode := GetLogEntryMode(FileString);

    if (LogBand <> NoBand) and (LogMode <> NoMode) then begin
      LogCall := GetLogEntryCall(FileString);
      LogDate := GetLogEntryDateString(FileString);
      LogTime := GetLogEntryTimeString(FileString);

            { I look first at the .Band entry.  I'll set it to NoBand if the edit
              has already been processed and therefore it won't match up with a
              new one }

      for Index := 0 to NumberDeleteEntries - 1 do
        if (DeleteEntryArray^[Index].Band = LogBand) and
          (DeleteEntryArray^[Index].Call = LogCall) and
          (DeleteEntryArray^[Index].Date = LogDate) and
          (DeleteEntryArray^[Index].Time = LogTime) then begin
          inc(NumberDeletesMatched);
          DeleteEntryArray^[Index].Band := NoBand;
//                WriteLn('Found delete entry for ', LogCall, ' at ', LogDate, ' ', LogTime);
          DeleteThisEntry := true;
        end;

      if not DeleteThisEntry then
        WriteLn(FileWrite, FileString);
    end
    else
      if not (Copy(FileString, 1, 12) = '; DELETE QSO') then
        WriteLn(FileWrite, FileString);
  end;

  Close(FileRead);
  Close(FileWrite);


   UnMatchedEntryCount := 0;

  for Index := 0 to NumberDeleteEntries - 1 do
    if DeleteEntryArray^[Index].Band <> NoBand then
      inc(UnmatchedEntryCount);


  if UnMatchedEntryCount = 0 then
    FileString:=('All delete entries were matched with log entries.')
  else
    FileString:=(inttostr(UnmatchedEntryCount)+ ' delete entries were not matched up with log entries.');


  showmessage('Procedure complete.' + #13 + 'There were ' + inttostr(NumberLogEntriesSaved) + ' log entries saved to ' + OutputFileName +
    #13 + 'There were ' + inttostr(NumberDeletesMatched) + ' matched delete entries.'+#13+FileString);




{
  if UnMatchedEntryCount = 0 then
    WriteLn('All delete entries were matched with log entries.')
  else
    WriteLn(UnmatchedEntryCount, ' delete entries were not matched up with log entries.');
}





//  WaitForKeyPressed;
end;

function LogProcedureMenu: boolean;

var
  Key: Char;

begin
  LogProcedureMenu := true;
//  ClrScr;
//  TextColor(Yellow);
  WriteLnCenter('LOG PROCEDURE MENU');
  WriteLn;
//  TextColor(Cyan);
  WriteLn('  A - Create copy of log in the ARRL suggested format.');
  WriteLn('  C - Create final logs (By band or mode and with running totals).');
  WriteLn('  D - Dupe log (marks any dupes that may be left in the log).');
  WriteLn('  E - Edit log (simple line editor to change specific lines).');
  WriteLn('  F - Filter log (create new log including or excluding desired countries).');
  WriteLn('  G - Merge two log files together, checking for dupes/mults.');
  WriteLn('  J - Create log check file for KCJ contest.');
  WriteLn('  K - K1EA network cleanup - process delete / edits.');
  WriteLn('  M - Multiplier check.  Complete check of all multiplier types.');
  WriteLn('  P - Pull out log for one specific computer ID in a multi-multi.');
  WriteLn('  V - View log segments.');
  WriteLn('  X - Exit log procedure menu.');
  WriteLn;

  repeat
    WriteLn;
  //  TextColor(Cyan);
    Write('  Enter command : ');

//    repeat until KeyPressed;
//    Key := UpCase(ReadKey);

    case Key of
      'A': begin
          ARRLCompatibleLog;
          Exit;
        end;
      'C': begin
          CreateFinalLog;
          Exit;
        end;
      'D': begin
          DupeLog;
          Exit;
        end;
      'E': begin
          EditLog;
          Exit;
        end;
      'F': begin
          FilterLog;
          Exit;
        end;
      'G': begin
          Merge;
          Exit;
        end;
      'J': begin
          MakeKCJLog;
          Exit;
        end;
      'K': begin
          K1EANetworkCleanup;
          Exit;
        end;
      'M': begin
          MultCheck;
          Exit;
        end;
      'P': begin
          PullSpecificComputerLog;
          Exit;
        end;
      'V': begin
          ViewLog;
          Exit;
        end;

      'X', EscapeKey: begin
          LogProcedureMenu := False;
          Exit;
        end;
    end;
  until False;
end;

begin
end.

