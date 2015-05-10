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
unit Help;

{$O+}
{$F+}
{$IMPORTEDDATA OFF}
interface

uses

  VC,

  Country9,
  Windows,
  Messages,
  LogSCP,
  LogK1EA,
  Tree,
  LogGrid,
  LogWind,
  LogNet,
  LogRadio;

type
  HelpSubject = (NoSubject);

  //  TabModeType = (NormalTabMode, ControlFTabMode);

var
  ConfirmEditChanges               : boolean = True;
  //  TabMode                               : TabModeType = NormalTabMode;
  UserNameString                   : Str40;
  VideoGameLength                  : integer;

var
  QTCFileName                      : string; //    = 'QTC.DAT';
  QTCListFileName                  : string; //    = 'QTCLIST.DAT';

procedure AddReminder;
procedure Bin64Decode;
procedure CheckForName;
procedure CoaxLength;
procedure ComputeGridDistance;
procedure ContextHelp(Subject: HelpSubject);
procedure DisplayCountryInformation(FileName: Str80; Call: CallString);

procedure EditWindowEditor(var EditLines: LogEntryArray;
  CursorX: integer; CursorY: integer;
  var DataChanged: boolean);

procedure FreeStartUpScreen;
procedure HexDump;
procedure HexConvert;
procedure Inductance;
procedure IOPort;

procedure KeyCode;

procedure LoadQTCDataFile;
procedure LoopBackTest;
procedure PacketMess;
procedure PacketSimulate;
procedure PassThrough;
procedure PortToFile;
procedure PutUpHelpMenu;
procedure SaveQTCDataFile;
procedure SetAlarm;
procedure ShowIOPorts;
procedure StartUpHelp;
procedure SunriseSunset;
procedure TellMeMyGrid;
procedure UUDecode;
procedure ViewLogFile;
procedure ViewRadioDebug;

implementation

uses LogCfg,
  MainUnit;

const
  PageBufferSize                   = BigWindowRX * (BigWindowRY - BigWindowLY + 2);
  MaxBuffers                       = 100;

type
  PageBuffer = record
    List: array[0..PageBufferSize - 1] of Char;
    NumberChars: integer;
  end;

  PageBufferPointer = ^PageBuffer;

var
  DisplayedBuffer                  : integer;
  FirstBuffer                      : integer;
  LogFileRead                      : Text;
  NumberBuffers                    : integer;
  TextBuffer                       : array[0..MaxBuffers - 1] of PageBufferPointer;

procedure TellMeMyGrid;

var
  LatString, LonString             : Str40;
  Result                           : integer;
  Lat, Lon                         : REAL;

begin
  WriteLn('Okay, I will tell you the grid of a given lat/lon.');

  repeat
    WriteLn;
    LatString := GetResponse('Enter lat (minus is south - none to quit) : ');
    if LatString = '' then Exit;
    Val(LatString, Lat, Result);
    if Result <> 0 then Exit;

    LonString := GetResponse('Enter lon (minus is east) : ');
    if LonString = '' then Exit;
    Val(LonString, Lon, Result);
    if Result <> 0 then Exit;

    WriteLn('Grid is ', ConvertLatLonToGrid(Lat, Lon));
  until False;
end;

procedure UUDecode;

var
  Mode                             : Str80;
  OutFileName, InputfileName       : Str80;
  CharacterPointer                 : integer;
  FileRead                         : Text;
  FileWrite                        : file;
  FileString                       : string;
  Key                              : Char;
  OutputByte1, OutputByte2, OutputByte3: Byte;

begin
  if ParamStr(2) = '' then
    InputfileName := GetResponse('Enter file to uudecode : ')
  else
    InputfileName := ParamStr(2);

  if InputfileName = '' then Exit;

  if not OpenFileForRead(FileRead, InputfileName) then Exit;

  if not Eof(FileRead) then ReadLn(FileRead, FileString);

  while UpperCase(Copy(FileString, 1, 6)) <> 'BEGIN ' do
    begin
      ReadLn(FileRead, FileString);

      if Eof(FileRead) then
        begin
          Close(FileRead);
          Exit;
        end;
    end;

  { We have found the begin statement }

  FileString := UpperCase(FileString);
  FileString := PostcedingString(FileString, 'BEGIN ');
  Mode := RemoveFirstString(FileString);
  OutFileName := RemoveFirstString(FileString);

  if OutFileName = '' then
    begin
      Close(FileRead);
      Exit;
    end;

  { See if output file exists, and if so, make sure overwrite is okay }

  WriteLn('Output file = ', OutFileName);

  if FileExists(OutFileName) then
    begin
      repeat
        Key := UpCase(GetKey(OutFileName + ' already exists.  Overwrite? (Y/N/) : '));

        if (Key = EscapeKey) or (Key = 'N') then
          begin
            Close(FileRead);
            Exit;
          end;

      until Key = 'Y';
      WriteLn;
    end
  else
    WriteLn('Output file = ', OutFileName);

  { Open output file }

  Assign(FileWrite, OutFileName);
  ReWrite(FileWrite, 1);

  while not Eof(FileRead) do
    begin
      ReadLn(FileRead, FileString);

      if (FileString = '') or (UpperCase(FileString) = 'END') then Continue;

      if not (FileString[1] in [' ', '`']) then
        begin
          Delete(FileString, 1, 1); { Get rid of length character }

          for CharacterPointer := 1 to length(FileString) do
            begin
              if not (FileString[CharacterPointer] in [' '..'`']) then
                begin
                  Close(FileRead);
                  Close(FileWrite);
                  //                   ReportError ('Illegal character found!!');
                  WriteLn(FileString);
                  Exit;
                end;

              if FileString[CharacterPointer] = '`' then
                FileString[CharacterPointer] := ' ';
            end;

          { We have legal characters - process 4 bytes at a time }

          while FileString <> '' do
            begin

              { Suppressed space at end of line protetion }

              while length(FileString) < 4 do
                FileString := FileString + ' ';

              OutputByte1 := ((Ord(FileString[1]) - 32) shl 2) + ((Ord(FileString[2]) - 32) shr 4);
              OutputByte2 := ((Ord(FileString[2]) - 32) shl 4) + ((Ord(FileString[3]) - 32) shr 2);
              OutputByte3 := ((Ord(FileString[3]) - 32) shl 6) + ((Ord(FileString[4]) - 32));

              BlockWrite(FileWrite, OutputByte1, 1);
              BlockWrite(FileWrite, OutputByte2, 1);
              BlockWrite(FileWrite, OutputByte3, 1);

              Delete(FileString, 1, 4);
            end;
        end;
    end;

  Close(FileWrite);
  Close(FileRead);
end;

procedure Bin64Decode;

var
  n                                : integer;
  t                                : array[0..255] of Byte;
  InputFile, OutputFile            : Str40;
  FileRead                         : Text;
  FileWrite                        : file;
  FileString                       : string;
  NumberBytes                      : LONGINT;
  ByteValue                        : integer;
  CharSet                          : Str80;
  SaveByte                         : Byte;
  Started                          : boolean;
  LeftOverChars                    : Str20;

begin
  if ParamStr(2) = '' then
    InputFile := GetResponse('Enter file to decode : ')
  else
    InputFile := ParamStr(2);

  if InputFile = '' then Exit;

  CharSet := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  for n := 0 to 255 do t[n] := 0;
  for n := 0 to 63 do t[Ord(CharSet[n + 1])] := n;

  NumberBytes := 0;
  OutputFile := '';

  if OpenFileForRead(FileRead, InputFile) then
    begin
      while not Eof(FileRead) do
        begin
          ReadLn(FileRead, FileString);
          FileString := UpperCase(FileString);
          WriteLn(FileString);

          if StringHas(FileString, 'NAME=') then
            begin
              OutputFile := PostcedingString(FileString, 'NAME=');

              if OutputFile[1] = '"' then
                Delete(OutputFile, 1, 1);

              if StringHas(OutputFile, '"') then
                OutputFile := PrecedingString(OutputFile, '"')
              else
                OutputFile := PrecedingString(OutputFile, ';');

              WriteLn('Output file command found = ', OutputFile);
            end;

          if (StringHas(FileString, 'CONTENT-TRANSFER-ENCOD') and
            StringHas(FileString, 'BASE64')) then
            begin
              ReadLn(FileRead, FileString);

              FileString := UpperCase(FileString);

              if StringHas(FileString, 'NAME=') then
                begin
                  OutputFile := PostcedingString(FileString, 'NAME=');

                  if OutputFile[1] = '"' then
                    Delete(OutputFile, 1, 1);

                  if StringHas(OutputFile, '"') then
                    OutputFile := PrecedingString(OutputFile, '"')
                  else
                    OutputFile := PrecedingString(OutputFile, ';');

                  WriteLn('Output file command found = ', OutputFile);
                end;

              if OutputFile = '' then
                begin
                  OutputFile := GetResponse('Output file name = ');

                  if OutputFile = '' then
                    begin
                      Close(FileRead);
                      Exit;
                    end;
                end;

              Assign(FileWrite, OutputFile);
              ReWrite(FileWrite, 1);

              Started := False;
              LeftOverChars := '';

              while not Eof(FileRead) do
                begin
                  ReadLn(FileRead, FileString);

                  GetRidOfPrecedingSpaces(FileString);
                  GetRidOfPostcedingSpaces(FileString);

                  if Started and (FileString = '') then
                    begin
                      Close(FileWrite);
                      Close(FileRead);
                      WriteLn(NumberBytes, ' bytes saved to ', OutputFile);
                      Exit;
                    end;

                  if (length(FileString) > 40) and (not StringHas(FileString, '=')) then
                    Started := True;

                  if Started then
                    begin
                      FileString := LeftOverChars + FileString;

                      while length(FileString) >= 4 do
                        begin
                          ByteValue := t[Ord(FileString[1])];

                          { Push six bits to the left }

                          ByteValue := ByteValue * 64;

                          { Fill in next six bits }

                          ByteValue := ByteValue + t[Ord(FileString[2])];

                          { Four more shifts to get first byte in hi byte }

                          ByteValue := ByteValue * 16;

                          { Save first byte }

                          SaveByte := Hi(ByteValue);
                          BlockWrite(FileWrite, SaveByte, 1);

                          { Push two more places to make room for six bits }

                          ByteValue := ByteValue * 4;

                          { Get next 6 bits }

                          ByteValue := ByteValue + t[Ord(FileString[3])];

                          { Push 6 times to make second byte }

                          ByteValue := ByteValue * 64;

                          { Save second byte }

                          SaveByte := Hi(ByteValue);
                          BlockWrite(FileWrite, SaveByte, 1);

                          { Get last 6 bits and you have the byte in Lo }

                          ByteValue := ByteValue + t[Ord(FileString[4])];

                          { Save third byte }

                          SaveByte := Lo(ByteValue);
                          BlockWrite(FileWrite, SaveByte, 1);

                          { Delete the bits we have processed }

                          Delete(FileString, 1, 4);
                          NumberBytes := NumberBytes + 3;
                        end;

                      LeftOverChars := FileString;
                    end;
                end;
              Close(FileWrite);
            end;
        end;
      Close(FileRead);
      WriteLn(NumberBytes, ' bytes saved to ', OutputFile);
    end;
end;

procedure LastQTCSent(var Call: CallString; var Time: Str20; var QSONumber: integer);

var
  TempString, LastFirstString, LastSecondString: string;
  FileString                       : string;
  FileRead                         : Text;

begin
  NumberQTCBooksSent := 0;

  if OpenFileForRead(FileRead, QTCFileName) then
    begin
      while not Eof(FileRead) do
        begin
          ReadLn(FileRead, FileString);

          GetRidOfPostcedingSpaces(FileString);

          if FileString = '' then Continue;

          if Copy(FileString, 1, 3) = 'QTC' then
            begin
              inc(NumberQTCBooksSent);
              LastFirstString := '';
              LastSecondString := '';
              Continue;
            end;

          TempString := Copy(FileString, 1, 40);

          if (Copy(TempString, 1, 3) = ' 1:') or
            (Copy(TempString, 1, 3) = ' 2:') or
            (Copy(TempString, 1, 3) = ' 3:') or
            (Copy(TempString, 1, 3) = ' 4:') or
            (Copy(TempString, 1, 3) = ' 5:') then
            begin
              RemoveFirstString(TempString);
              LastFirstString := TempString;
            end;

          TempString := Copy(FileString, 41, 30);

          if (Copy(TempString, 1, 3) = ' 6:') or
            (Copy(TempString, 1, 3) = ' 7:') or
            (Copy(TempString, 1, 3) = ' 8:') or
            (Copy(TempString, 1, 3) = ' 9:') or
            (Copy(TempString, 1, 3) = '10:') then
            begin
              RemoveFirstString(TempString);
              LastSecondString := TempString;
            end;
        end;

      Close(FileRead);

      if LastSecondString <> '' then
        begin
          Time := RemoveFirstString(LastSecondString);
          Call := RemoveFirstString(LastSecondString);
          QSONumber := RemoveFirstLongInteger(LastSecondString);
        end
      else
        begin
          Time := RemoveFirstString(LastFirstString);
          Call := RemoveFirstString(LastFirstString);
          QSONumber := RemoveFirstLongInteger(LastFirstString);
        end;

      Insert(':', Time, 3);

      Exit;
    end;

  Call := '';
  Time := '';
  QSONumber := 0;
end;

function GetLogEntryQSONumberReceived(FileString: Str80): integer;

var
  Exchange                         : string;
  QSONumber, Result1               : integer;

begin
  Exchange := GetLogEntryExchangeString(FileString);
  GetRidOfPrecedingSpaces(Exchange);
  Exchange := PostcedingString(Exchange, ' ');
  GetRidOfPrecedingSpaces(Exchange);
  Exchange := PostcedingString(Exchange, ' ');
  GetRidOfPrecedingSpaces(Exchange);
  GetRidOfPostcedingSpaces(Exchange);
  Val(Exchange, QSONumber, Result1);

  if Result1 = 0 then
    GetLogEntryQSONumberReceived := QSONumber
  else
    GetLogEntryQSONumberReceived := 0;
end;

procedure LoadQTCDataFile;

var
  Band                             : BandType;
  Mode                             : ModeType;
  FileRead                         : Text;
  LastQTCTime                      : Str20;
  FileString, Exchange, TempString : Str80;
  QSOPoints, TotalQTCs, QSONumber, Line, LastQTCQSONumber, Result: integer;
  LogQSONumber, LogTime            : integer;
  Call, LogCall, LastQTCCall       : CallString;
  Started                          : boolean;

begin
  {
    if MyContinent <> Europe then New(PendingQTCArray);
    New(QTCDataArray);

    NumberQTCStations := 0;

    if OpenFileForRead(FileRead, QTCListFileName) then
    begin
      while not Eof(FileRead) do
      begin
        ReadLn(FileRead, Call);
        BigCompressFormat(Call, QTCDataArray^[NumberQTCStations].Call);
        ReadLn(FileRead, QTCDataArray^[NumberQTCStations].NumberQTCs);
        inc(NumberQTCStations);
      end;

      Close(FileRead);
    end;

    if MyContinent <> Europe then // We are sending QTCs
    begin
      New(PendingQTCArray);

      TotalQTCs := TotalNumberQTCsProcessed; // TotalNumberQTCs is a FUNCTION
      NextQTCToBeSent := 0;
      NextQTCToBeAdded := 0;
      NumberQTCBooksSent := 0;

          // Find out callsign, time and QSO Number of last QTC sent

      LastQTCSent(LastQTCCall, LastQTCTime, LastQTCQSONumber);

      Started := LastQTCCall = ''; // None sent yet

          // Okay - read in QTC data from LOG file

      if OpenFileForRead(FileRead, LogFileName) then
      begin
        while not Eof(FileRead) do
        begin

          ReadLn(FileRead, FileString);

          Band := GetLogEntryBand(FileString);
          Mode := GetLogEntryMode(FileString);
          QSOPoints := GetLogEntryQSOPoints(FileString);

          if (Band <> NoBand) and (Mode <> NoMode) and (QSOPoints > 0) then
          begin
            LogCall := GetLogEntryCall(FileString);
            LogQSONumber := GetLogEntryQSONumberReceived(FileString);
            LogTime := GetLogEntryIntegerTime(FileString);

            if Started then
              AddQSOToPendingQTCList(LogTime, LogCall, LogQSONumber)
            else
              if (LogCall = LastQTCCall) and (LogQSONumber = LastQTCQSONumber) then
                Started := True;
          end;

        end;

        Close(FileRead);
      end;
    end;
   }
end;

procedure SaveQTCDataFile;

var
  FileWrite                        : Text;
  TempString                       : Str80;
  Station                          : integer;

begin
  if NumberQTCStations > 0 then
    if OpenFileForWrite(FileWrite, QTCListFileName) then
      begin
        for Station := 0 to NumberQTCStations - 1 do
          begin
            WriteLn(FileWrite, BigExpandedString(QTCDataArray^[Station].Call));
            WriteLn(FileWrite, QTCDataArray^[Station].NumberQTCs);
          end;
        Close(FileWrite);
      end;
end;

procedure AddReminder;

var
  TimeString, DayString, DateString, ReminderString: string;
  Result                           : integer;
  FileWrite                        : Text;

begin
  if NumberReminderRecords >= MaximumReminderRecords then
    begin
      //    SaveSetAndClearActiveWindow(QuickCommandWindow);
      QuickDisplay('Sorry, you have used up all your reminders!!');
      //    Delay(2000);
      //    RemoveAndRestorePreviousWindow;
      Exit;
    end;

  TimeString := QuickEditResponse('Enter time for reminder (XX:XX) : ', 12);
  if (TimeString = EscapeKey) or (Copy(TimeString, 3, 1) <> ':') then Exit;
  Delete(TimeString, 3, 1);

  if not StringIsAllNumbers(TimeString) then Exit;
  if length(TimeString) <> 4 then Exit;

  DateString := UpperCase(QuickEditResponse('Enter day or date : ', 12));
  if (DateString = '') or (DateString = EscapeKey) then Exit;

  if NumberReminderRecords = 0 then New(Reminders);

  Reminders^[NumberReminderRecords].DateString := '';
  Reminders^[NumberReminderRecords].DayString := '';
  Reminders^[NumberReminderRecords].Alarm := False;

  Val(TimeString, Reminders^[NumberReminderRecords].Time, Result);

  if StringHas(UpperCase(DateString), 'ALARM') then
    begin
      Reminders^[NumberReminderRecords].Alarm := True;
      DateString := BracketedString(DateString, '', 'ALARM');
    end;

  GetRidOfPostcedingSpaces(DateString);
  su(DateString);

  if StringHas(DateString, '-') then
    begin
      case length(DateString) of
        8: if (DateString[2] <> '-') or (DateString[6] <> '-') then
            begin
              //          SaveSetAndClearActiveWindow(QuickCommandWindow);
              QuickDisplay('Invalid date!!');
              //          Delay(1000);
              //          RestorePreviousWindow;
              Exit;
            end
          else
            DateString := '0' + DateString;

        9: if (DateString[3] <> '-') or (DateString[7] <> '-') then
            begin
              //          SaveSetAndClearActiveWindow(QuickCommandWindow);
              QuickDisplay('Invalid date!!');
              //          Delay(1000);
              //          RestorePreviousWindow;
              Exit;
            end;

        else
          begin
            //        SaveSetAndClearActiveWindow(QuickCommandWindow);
            QuickDisplay('Invalid date!!');
            //        Delay(1000);
            //        RestorePreviousWindow;
            Exit;
          end;
      end; { of case }

      Reminders^[NumberReminderRecords].DateString := DateString;
    end
  else
    begin
      if Copy(DateString, 1, 2) = 'MO' then DateString := 'MONDAY';
      if Copy(DateString, 1, 2) = 'TU' then DateString := 'TUESDAY';
      if Copy(DateString, 1, 2) = 'WE' then DateString := 'WEDNESDAY';
      if Copy(DateString, 1, 2) = 'TH' then DateString := 'THURSDAY';
      if Copy(DateString, 1, 2) = 'FR' then DateString := 'FRIDAY';
      if Copy(DateString, 1, 2) = 'SA' then DateString := 'SATURDAY';
      if Copy(DateString, 1, 2) = 'SU' then DateString := 'SUNDAY';

      DayString := Copy(DateString, length(DateString) - 2, 3);

      if (DayString <> 'DAY') and (DateString <> 'ALL') and (DateString <> 'TMW') then
        begin
          //      SaveSetAndClearActiveWindow(QuickCommandWindow);
          QuickDisplay('Invalid date!!');
          //      Delay(1000);
          //      RestorePreviousWindow;
          Exit;
        end;

      if DateString = 'TODAY' then DateString := UpperCase(GetDayString);
      if DateString = 'TMW' then DateString := UpperCase(GetTomorrowString);

      Reminders^[NumberReminderRecords].DayString := DateString;
    end;

  ReminderString := QuickEditResponse('Msg = ', 75);
  if (ReminderString = '') or (ReminderString = EscapeKey) then Exit;

  Reminders^[NumberReminderRecords].Message := ReminderString;
  inc(NumberReminderRecords);

  //  SaveSetAndClearActiveWindow(QuickCommandWindow);
  //wli временно удалил
  {
    Write('Reminder number ', NumberReminderRecords, ' added on ');
    Write(Reminders^[NumberReminderRecords - 1].DateString);
    Write(Reminders^[NumberReminderRecords - 1].DayString);
    Write(' at ');
    if Reminders^[NumberReminderRecords - 1].Time < 1000 then
      Write('0', Reminders^[NumberReminderRecords - 1].Time)
    else
      Write(Reminders^[NumberReminderRecords - 1].Time);

    Delay(2000);

    if OpenFileForAppend(FileWrite, LogConfigFileName) then
    begin
      WriteLn(FileWrite, ';   Reminder added by operator on line');
      Write(FileWrite, 'REMINDER = ');
      Write(FileWrite, TimeString, ' ON ');
      Write(FileWrite, Reminders^[NumberReminderRecords - 1].DateString);
      Write(FileWrite, Reminders^[NumberReminderRecords - 1].DayString);
      Write(FileWrite, ' ');
      if Reminders^[NumberReminderRecords - 1].Alarm then
        Write(FileWrite, 'ALARM');
      WriteLn(FileWrite);
      WriteLn(FileWrite, Reminders^[NumberReminderRecords - 1].Message);
      Close(FileWrite);
    end;
  }
  //  RemoveAndRestorePreviousWindow;
end;

procedure CheckForName;

var
  FileRead, FileWrite              : Text;
  Directory, CityString, AddressString: Str80;

begin
  Directory := FindDirectory('name.dat');

  if Directory = '' then Directory := FindDirectory('TR.EXE');

  if OpenFileForRead(FileRead, Directory + '\name.dat') then
    begin
      ReadLn(FileRead, UserNameString);
      WriteLn('TR Program registered to ', UserNameString);
      Close(FileRead);
    end
  else
    begin
      Directory := FindDirectory('TR.OVR');

      UserNameString := GetResponse('Please enter your name and call : ');

      if UserNameString = '' then halt;

      OpenFileForWrite(FileWrite, Directory + '\name.dat');
      WriteLn(FileWrite, UserNameString);
      WriteLn(FileWrite, AddressString);
      WriteLn(FileWrite, CityString);
      Close(FileWrite);
    end;
end;

procedure LoopBackTest;

var
  Key, RXChar                      : Char;
  BaudString                       : Str20;
  BaudRate, Result                 : integer;
  SerialPort                       : PortType;
  SevenBitMode                     : boolean;
  Parity                           : ParityType;
  FileWrite                        : file;

begin
  {
  //  ClrScr;
  //  TextColor(Yellow);
    WriteLnCenter('SERIAL PORT LOOP BACK TEST');
    WriteLn;
  //  TextColor(Cyan);
    WriteLn('This procedure will test the serial port to see if it appears to be working.');
    WriteLn('It can also be used as a primative dumb terminal for testing TNCs and the');
    WriteLn('like.  The data you get back will be saved in the binary file LOOPBACK.BIN');
    WriteLn;
    WriteLn('Please connect pin 2 to pin 3 if you are doing a loopback test.');
    WriteLn;

    repeat
      Key := UpCase(GetKey('Use (B)ios or (D)irect hardware access? (B/D/Escape) : '));
      if Key = EscapeKey then Exit;
    until (Key = 'B') or (Key = 'D');
    WriteLn;

    if Key = 'B' then UseBIOSCOMIO := True;

    repeat
      Key := UpCase(GetKey('Enter serial port to test (1-4): '));
      if Key = EscapeKey then Exit;
    until (Key = '1') or (Key = '2') or (Key = '3') or (Key = '4');
    WriteLn;

    case Key of
      '1': SerialPort := Serial1;
      '2': SerialPort := Serial2;
      '3': SerialPort := Serial3;
      '4': SerialPort := Serial4;
    else Exit;
    end;

    repeat
      BaudString := UpperCase(GetResponse('Baud rate (300, 1200, 2400, 4800, 9600, 19200 or 57600) : '));
      if BaudString = '' then Exit;
    until (BaudString = '300') or (BaudString = '1200') or
      (BaudString = '2400') or (BaudString = '4800') or
      (BaudString = '9600') or (BaudString = '19200') or
      (BaudString = '57600');

    Val(BaudString, BaudRate, Result);

    repeat
      Key := UpCase(GetKey('7 or 8 bits? : '));
      if Key = EscapeKey then Exit;
    until (Key = '7') or (Key = '8');
    WriteLn;

    SevenBitMode := Key = '7';

    repeat
      Key := UpCase(GetKey('(E)ven, (O)dd or (N)o parity? (E/O/N) : '));
      if Key = EscapeKey then Exit;
    until (Key = 'E') or (Key = 'O') or (Key = 'N');
    WriteLn;

    case Key of
      'E': Parity := EvenParity;
      'O': Parity := OddParity;
      'N': Parity := NoParity;
    end;

    if SevenBitMode then
      InitializeSerialPort(SerialPort, BaudRate, 7, Parity, 1)
    else
      InitializeSerialPort(SerialPort, BaudRate, 8, Parity, 2);

    WriteLn;
    WriteLn('Okay, you are all set.  Press ESCAPE to stop.');
    WriteLn;

    Assign(FileWrite, 'LOOPBACK.BIN');
    Rewrite(FileWrite, 1);

    repeat
  //    if KeyPressed then
      begin
        Key := ReadKey;

        if Key = EscapeKey then
        begin
          Close(FileWrite);
          Exit;
        end;

        SendChar(SerialPort, Key);
      end;

      if CharReady(SerialPort) then
      begin
        RXChar := ReadChar(SerialPort);
        BlockWrite(FileWrite, RXChar, 1);

        if SevenBitMode then
          RXChar := Chr(Ord(RXChar) and $7F);

        Write(RXChar);
      end;

    until False;
  }
end;

procedure PortToFile;

var
  Key                              : Char;
  FileName, BaudString             : Str20;
  FileWrite                        : file;
  Result, BaudRate                 : integer;
  SerialPort                       : PortType;
  RChar                            : Char;

begin
  {
    ClrScr;
    TextColor(Yellow);
    WriteLnCenter('PORT TO FILE');
    WriteLn;
    TextColor(Cyan);
    WriteLn('This procedure will take whatever data is coming in on the serial port ');
    WriteLn('specified and dump it into a file.  Any keys pressed will be sent to the');
    WriteLn('the port.');
    WriteLn;

    repeat
      Key := UpCase(GetKey('Enter serial port to test (1-4): '));
      if Key = EscapeKey then Exit;
    until (Key = '1') or (Key = '2') or (Key = '3') or (Key = '4');
    WriteLn;

    case Key of
      '1': SerialPort := Serial1;
      '2': SerialPort := Serial2;
      '3': SerialPort := Serial3;
      '4': SerialPort := Serial4;
    else Exit;
    end;

    repeat
      BaudString := UpperCase(GetResponse('Enter baud rate : '));
      if BaudString = '' then Exit;
    until (BaudString = '300') or (BaudString = '1200') or
      (BaudString = '2400') or (BaudString = '4800') or
      (BaudString = '9600');

    WriteLn;

    FileName := GetResponse('Enter filename to save data to : ');

    if FileName = '' then Exit;

    Assign(FileWrite, Filename);
    ReWrite(FileWrite, 1);

    Val(BaudString, BaudRate, Result);

    InitializeSerialPort(SerialPort, BaudRate, 8, NoParity, 1);

    WriteLn('Saving data to file.  Use the ESCAPE key to exit.');

    repeat
      if KeyPressed then
      begin
        Key := ReadKey;

        if Key = EscapeKey then
        begin
          Close(FileWrite);
          Exit;
        end;

        SendChar(SerialPort, Key);
      end;

      if CharReady(SerialPort) then
      begin
        RChar := ReadChar(SerialPort);
        BlockWrite(FileWrite, RChar, SizeOf(RChar), Result);
        Write(RChar);
      end;

    until False;
   }
end;

procedure DisplayEditableLogString(LineData: Str80; Cursor: integer);

var
  Inverse                          : boolean;
  Block                            : integer;

begin
  {  GoToXY(1, WhereY);

    while Length(LineData) < 79 do
      LineData := LineData + ' ';

    if Length(LineData) > 79 then
    begin
      LineData := Copy(LineData, 1, 78);
      LineData := LineData + '+';
    end;

    for Block := 1 to 10 do
    begin
      Inverse := False;

      if ActiveExchange = RSTNameAndQTHExchange then
      begin
        case Block of
          1: if ((Cursor >= 1) and (Cursor <= 7)) then Inverse := True;
          2: if ((Cursor >= 8) and (Cursor <= 17)) then Inverse := True;
          3: if ((Cursor >= 18) and (Cursor <= 23)) then Inverse := True;
          4: if ((Cursor >= 24) and (Cursor <= 29)) then Inverse := True;
          5: if ((Cursor >= 30) and (Cursor <= 41)) then Inverse := True;
          6: if ((Cursor >= 45) and (Cursor <= 47)) then Inverse := True;
          7: if ((Cursor >= 50) and (Cursor <= 52)) then Inverse := True;
          8: if ((Cursor >= 54) and (Cursor <= 77)) then Inverse := True;
          9: if ((Cursor >= 77) and (Cursor <= 78)) then Inverse := True;
        end;
      end
      else
        case Block of
          1: if ((Cursor >= 1) and (Cursor <= 7)) then Inverse := True;
          2: if ((Cursor >= 8) and (Cursor <= 17)) then Inverse := True;
          3: if ((Cursor >= 18) and (Cursor <= 23)) then Inverse := True;
          4: if ((Cursor >= 24) and (Cursor <= 29)) then Inverse := True;
          5: if ((Cursor >= 30) and (Cursor <= 41)) then Inverse := True;
          6: if ((Cursor >= 42) and (Cursor <= 43)) then Inverse := True;
          7: if ((Cursor >= 44) and (Cursor <= 68)) then Inverse := True;
          8: if ((Cursor >= 69) and (Cursor <= 76)) then Inverse := True;
          9: if ((Cursor >= 77) and (Cursor <= 78)) then Inverse := True;
        end;

      if Inverse then
      begin
        TextColor(ActiveBackground);
        TextBackground(ActiveColor);
      end
      else
      begin
        TextColor(ActiveColor);
        TextBackground(ActiveBackground);
      end;

      if ActiveExchange = RSTNameAndQTHExchange then
      begin
        case Block of
          1: Write(Copy(LineData, 1, 7));
          2: Write(Copy(LineData, 8, 10));
          3: Write(Copy(LineData, 18, 6));
          4: Write(Copy(LineData, 24, 6));
          5: Write(Copy(LineData, 30, 15));
          6: Write(Copy(LineData, 45, 5));
          7: Write(Copy(LineData, 50, 4));
          8: Write(Copy(LineData, 54, 23));
          9: Write(Copy(LineData, 77, 2));
        end;
      end
      else
      begin
        case Block of
          1: Write(Copy(LineData, 1, 7));
          2: Write(Copy(LineData, 8, 10));
          3: Write(Copy(LineData, 18, 6));
          4: Write(Copy(LineData, 24, 6));
          5: Write(Copy(LineData, 30, 12));
          6: Write(Copy(LineData, 42, 2));
          7: Write(Copy(LineData, 44, 25));
          8: Write(Copy(LineData, 69, 8));
          9: Write(Copy(LineData, 77, 2));
          10: Write(Copy(LineData, 79, 1));
        end;
      end;
    end;

    if Cursor < 80 then
    begin
      GoToXY(Cursor, WhereY);
      TextColor(ActiveBackground);
      TextBackground(ActiveColor);
    end;
  }
end;

procedure EditWindowEditor(var EditLines: LogEntryArray;
  CursorX: integer; CursorY: integer;
  var DataChanged: boolean);

var
  CharPointer, CursorPosition, InsertCursorPosition, NewCursor, Line: integer;
  PreviousCursorChar               : Char;
  WindowString, TempString         : Str160;
  KeyChar                          : Char;
  InsertMode                       : boolean;
  OriginalEditLines                : LogEntryArray;
  TimeMark                         : TimeRecord;

begin
  {  DataChanged := False;
    OriginalEditLines := EditLines;
    InsertMode := False;
    DisplayInsertMode(InsertMode);
    SaveAndSetActiveWindow(EditableLogWindow);
    GoToXY(CursorX, CursorY);

    WindowString := EditLines[CursorY];
    DisplayEditableLogString(WindowString, CursorX);

    repeat
      MarkTime(TimeMark);

      repeat
        UpdateTimeAndRateDisplays(True, False);

        if ElaspedSec100(TimeMark) > 2000 then
        begin
          EditLines[WhereY] := WindowString;
          DisplayEditableLogString(WindowString, 80);
          EditLines := OriginalEditLines;
          ClrScr;

          for Line := 1 to 5 do
          begin
            GoToXY(1, Line);
            DisplayEditableLogString(EditLines[Line], 80);
          end;
          DataChanged := False;
          RestorePreviousWindow;
          Exit;
        end;

      until (KeyPressed);

      KeyChar := ReadKey;
      CursorPosition := WhereX;

      case KeyChar of

        EscapeKey:
          begin
            EditLines[WhereY] := WindowString;
            DisplayEditableLogString(WindowString, 80);

            if DataChanged and ConfirmEditChanges then
            begin
              TempString := UpperCase(QuickEditResponse('Save changes? (Y/N) : ', 1));

              if TempString[1] <> 'Y' then
              begin
                EditLines := OriginalEditLines;
                ClrScr;
                for Line := 1 to 5 do
                begin
                  GoToXY(1, Line);
                  DisplayEditableLogString(EditLines[Line], 80);
                end;
                DataChanged := False;
              end;
            end;

            RestorePreviousWindow;
            Exit;
          end;

        TabKey:
          if TabMode = NormalTabMode then
          begin
            NewCursor := 8;
            if ActiveExchange = RSTNameAndQTHExchange then
            begin
              if CursorPosition > 7 then NewCursor := 18;
              if CursorPosition > 17 then NewCursor := 24;
              if CursorPosition > 23 then NewCursor := 30;
              if CursorPosition > 29 then NewCursor := 45;
              if CursorPosition > 44 then NewCursor := 50;
              if CursorPosition > 49 then NewCursor := 54;
              if CursorPosition > 53 then NewCursor := 77;
              if CursorPosition > 77 then
                if WhereY < NumberEditableLines then
                begin
                  EditLines[WhereY] := WindowString;
                  DisplayEditableLogString(WindowString, 80);
                  GoToXY(1, WhereY + 1);
                  WindowString := EditLines[WhereY];
                  NewCursor := 1;
                end;
            end
            else
            begin
              if CursorPosition > 7 then NewCursor := 18;
              if CursorPosition > 17 then NewCursor := 24;
              if CursorPosition > 23 then NewCursor := 30;
              if CursorPosition > 29 then NewCursor := 42;
              if CursorPosition > 41 then NewCursor := 44;
              if CursorPosition > 43 then NewCursor := 69;
              if CursorPosition > 68 then NewCursor := 77;
              if CursorPosition > 77 then
                if WhereY < NumberEditableLines then
                begin
                  EditLines[WhereY] := WindowString;
                  DisplayEditableLogString(WindowString, 80);
                  GoToXY(1, WhereY + 1);
                  WindowString := EditLines[WhereY];
                  NewCursor := 1;
                end;
            end;

            DisplayEditableLogString(WindowString, NewCursor);
          end
          else
            if CursorPosition <= Length(WindowString) then
            begin
              repeat
                PreviousCursorChar := WindowString[CursorPosition];
                Inc(CursorPosition);
              until ((WindowString[CursorPosition] <> ' ') and
                (PreviousCursorChar = ' ')) or (CursorPosition = Length(WindowString) + 1);
              DisplayEditableLogString(WindowString, CursorPosition);
            end
            else
              if WhereY < NumberEditableLines then
              begin
                EditLines[WhereY] := WindowString;
                DisplayEditableLogString(WindowString, 80);
                GoToXY(1, WhereY + 1);
                WindowString := EditLines[WhereY];
                DisplayEditableLogString(WindowString, 1);
              end;

        ControlA:
          if CursorPosition > 1 then
          begin
            repeat
              Dec(CursorPosition);
              PreviousCursorChar := WindowString[CursorPosition - 1];
            until ((WindowString[CursorPosition] <> ' ') and
              (PreviousCursorChar = ' ')) or (CursorPosition = 1);

            DisplayEditableLogString(WindowString, CursorPosition);
          end
          else
            if WhereY > 1 then
            begin
              EditLines[WhereY] := WindowString;
              DisplayEditableLogString(WindowString, 80);
              WindowString := EditLines[WhereY];
              DisplayEditableLogString(WindowString, 79);
            end;

        ControlC:
          begin
            EditLines[WhereY] := WindowString;
            DisplayEditableLogString(WindowString, 80);
            WindowString := EditLines[NumberEditableLines];
            DisplayEditableLogString(WindowString, CursorPosition);
          end;

        ControlD:
          begin
            if CursorPosition <= Length(WindowString) then
              Inc(CursorPosition);
            DisplayEditableLogString(WindowString, CursorPosition);
          end;

        ControlE, ControlW:
          if WhereY > 1 then
          begin
            EditLines[WhereY] := WindowString;
            DisplayEditableLogString(WindowString, 80);
            GoToXY(1, WhereY - 1);
            WindowString := EditLines[WhereY];
            DisplayEditableLogString(WindowString, CursorPosition);
          end;

        ControlF:
          if CursorPosition <= Length(WindowString) then
          begin
            repeat
              PreviousCursorChar := WindowString[CursorPosition];
              Inc(CursorPosition);
            until ((WindowString[CursorPosition] <> ' ') and
              (PreviousCursorChar = ' ')) or (CursorPosition = Length(WindowString) + 1);
            DisplayEditableLogString(WindowString, CursorPosition);
          end
          else
            if WhereY < NumberEditableLines then
            begin
              EditLines[WhereY] := WindowString;
              DisplayEditableLogString(WindowString, 80);
              GoToXY(1, WhereY + 1);
              WindowString := EditLines[WhereY];
              DisplayEditableLogString(WindowString, 1);
            end;

        ControlS:
          begin
            if CursorPosition > 1 then
              Dec(CursorPosition);
            DisplayEditableLogString(WindowString, CursorPosition);
          end;

        ControlY:
          begin
            WindowString := '                                                                            ';
            CursorPosition := 1;
            DisplayEditableLogString(WindowString, CursorPosition);
            DataChanged := True;
          end;

        ControlX, ControlZ:
          if WhereY < NumberEditableLines then
          begin
            EditLines[WhereY] := WindowString;
            DisplayEditableLogString(WindowString, 80);
            GoToXY(WhereX, WhereY + 1);
            WindowString := EditLines[WhereY];
            DisplayEditableLogString(WindowString, CursorPosition);
          end;

        CarriageReturn:
          if WhereY < NumberEditableLines then
          begin
            EditLines[WhereY] := WindowString;
            DisplayEditableLogString(WindowString, 80);
            GoToXY(1, WhereY + 1);
            WindowString := EditLines[WhereY];
            DisplayEditableLogString(WindowString, 1);
          end;

        BackSpace:
          if CursorPosition > 1 then
          begin
            Dec(CursorPosition);
            WindowString[CursorPosition] := ' ';
            DisplayEditableLogString(WindowString, CursorPosition);
          end;

        NullCharacter:
          begin
            KeyChar := ReadKey;

            case KeyChar of
              UpArrow:
                if WhereY > 1 then
                begin
                  EditLines[WhereY] := WindowString;
                  DisplayEditableLogString(WindowString, 80);
                  GoToXY(CursorPosition, WhereY - 1);
                  WindowString := EditLines[WhereY];
                  DisplayEditableLogString(WindowString, CursorPosition);
                end;

              DownArrow:
                if WhereY < NumberEditableLines then
                begin
                  EditLines[WhereY] := WindowString;
                  DisplayEditableLogString(WindowString, 80);
                  GoToXY(CursorPosition, WhereY + 1);
                  WindowString := EditLines[WhereY];
                  DisplayEditableLogString(WindowString, CursorPosition);
                end
                else
                begin
                  EditLines[WhereY] := WindowString;
                  DisplayEditableLogString(WindowString, 80);

                  if DataChanged and ConfirmEditChanges then
                  begin
                    TempString := UpperCase(QuickEditResponse('Save changes? (Y/N) : ', 1));

                    if TempString[1] <> 'Y' then
                    begin
                      EditLines := OriginalEditLines;
                      ClrScr;
                      for Line := 1 to 5 do
                      begin
                        GoToXY(1, Line);
                        DisplayEditableLogString(EditLines[Line], 80);
                      end;
                      DataChanged := False;
                    end;
                  end;

                  RestorePreviousWindow;
                  Exit;
                end;

              LeftArrow:
                begin
                  if CursorPosition > 1 then
                    Dec(CursorPosition);
                  DisplayEditableLogString(WindowString, CursorPosition);
                end;

              RightArrow:
                begin
                  if CursorPosition <= Length(WindowString) then
                    Inc(CursorPosition);
                  DisplayEditableLogString(WindowString, CursorPosition);
                end;

              HomeKey:
                begin
                  EditLines[WhereY] := WindowString;
                  DisplayEditableLogString(WindowString, 80);
                  GoToXY(1, 1);
                  WindowString := EditLines[1];
                  DisplayEditableLogString(WindowString, 1);
                end;

              EndKey:
                begin
                  EditLines[WhereY] := WindowString;
                  DisplayEditableLogString(WindowString, 80);
                  GoToXY(1, NumberEditableLines);
                  WindowString := EditLines[NumberEditableLines];
                  DisplayEditableLogString(WindowString, 1);
                end;

              ShiftTab:
                if TabMode = NormalTabMode then
                begin
                  NewCursor := 69;
                  if CursorPosition < 77 then NewCursor := 44;
                  if CursorPosition < 69 then NewCursor := 42;
                  if CursorPosition < 44 then NewCursor := 30;
                  if CursorPosition < 42 then NewCursor := 24;
                  if CursorPosition < 30 then NewCursor := 18;
                  if CursorPosition < 24 then NewCursor := 8;
                  if CursorPosition < 18 then NewCursor := 1;
                  if CursorPosition < 8 then
                    if WhereY > 1 then
                    begin
                      EditLines[WhereY] := WindowString;
                      DisplayEditableLogString(WindowString, 80);
                      GoToXY(1, WhereY - 1);
                      WindowString := EditLines[WhereY];
                      NewCursor := 77;
                    end;
                  DisplayEditableLogString(WindowString, NewCursor);
                end
                else
                  if CursorPosition > 1 then
                  begin
                    repeat
                      Dec(CursorPosition);
                      PreviousCursorChar := WindowString[CursorPosition - 1];
                    until ((WindowString[CursorPosition] <> ' ') and
                      (PreviousCursorChar = ' ')) or (CursorPosition = 1);

                    DisplayEditableLogString(WindowString, CursorPosition);
                  end
                  else
                    if WhereY > 1 then
                    begin
                      EditLines[WhereY] := WindowString;
                      DisplayEditableLogString(WindowString, 80);
                      WindowString := EditLines[WhereY];
                      DisplayEditableLogString(WindowString, 79);
                    end;

            end; // of case
          end; // of null string case

      else
        begin
          if KeyChar >= ' ' then
            if CursorPosition <= Length(WindowString) then
            begin
              WindowString[CursorPosition] := KeyChar;
              DisplayEditableLogString(WindowString, CursorPosition + 1);
              DataChanged := True;
            end
            else
              if CursorPosition < 79 then
              begin
                WindowString := WindowString + KeyChar;
                DisplayEditableLogString(WindowString, CursorPosition + 1);
                DataChanged := True;
              end;

        end;
      end; // of case

    until False;
   }
end;

procedure LoadPageBuffer(BufferNumber: integer);

{ This procedure will load up the PageBuffer with one screen full of text
  from the file indicated by FileRead.  If the end of the file is found,
  the rest of the PageBuffer will be blank. }

var
  Result, NumberLines              : integer;
  FileChar                         : Char;
  TempString                       : Str80;

begin
  TextBuffer[BufferNumber]^.NumberChars := 0;
  NumberLines := 0;

  while not Eof(LogFileRead) do
    begin
      Read(LogFileRead, FileChar);

      if FileChar = LineFeed then
        begin
          inc(NumberLines);
          if NumberLines >= BigWindowRY - BigWindowLY + 1 then
            Exit;
        end;

      TextBuffer[BufferNumber]^.List[TextBuffer[BufferNumber]^.NumberChars] := FileChar;
      inc(TextBuffer[BufferNumber]^.NumberChars);
    end;
end;

procedure DisplayBuffer(BufferNumber: integer);

var
  Address                          : integer;

begin
  //  ClrScr;

  if TextBuffer[BufferNumber]^.NumberChars > 0 then
    for Address := 0 to TextBuffer[BufferNumber]^.NumberChars - 1 do
      Write(TextBuffer[BufferNumber]^.List[Address]);

  DisplayedBuffer := BufferNumber;
end;

procedure StartLogFileView(FileName: Str80);

begin
  {
    if MaxAvail < SizeOf(PageBuffer) then Exit;

    FirstBuffer := 0;
    NumberBuffers := 1;

    New(TextBuffer[FirstBuffer]);

    Assign(LogFileRead, FileName);
    Reset(LogFileRead);

    LoadPageBuffer(FirstBuffer);
    DisplayBuffer(FirstBuffer);

    if (not Eof(LogFileRead)) and (MaxAvail > SizeOf(PageBuffer)) then
    begin
      New(TextBuffer[NumberBuffers]);
      LoadPageBuffer(NumberBuffers);
      Inc(NumberBuffers);
    end;
   }
end;

procedure LoadNextPage;

begin
  {
    if not Eof(LogFileRead) then // there is more to load
    begin
      if (MaxAvail > SizeOf(PageBuffer)) and (NumberBuffers < MaxBuffers - 1) then // there is more memory
      begin
        New(TextBuffer[NumberBuffers]);
        LoadPageBuffer(NumberBuffers);
        Inc(NumberBuffers);
      end
      else // no new buffers, wrap
      begin
        LoadPageBuffer(FirstBuffer);
        Inc(FirstBuffer);
        if FirstBuffer = NumberBuffers then FirstBuffer := 0;
      end;
    end;
   }
end;

procedure ShowNextPage;

{ This procedure will display the next page and load the next page after
  that into the appropriate buffer.   }

begin
  if NumberBuffers > 1 then { multiple buffers }
    begin
      inc(DisplayedBuffer); { is already loaded }

      if DisplayedBuffer = NumberBuffers then { need to wrap to 0 }
        DisplayedBuffer := 0;

      if DisplayedBuffer <> FirstBuffer then
        DisplayBuffer(DisplayedBuffer)
      else
        begin
          Dec(DisplayedBuffer);
          if DisplayedBuffer < 0 then DisplayedBuffer := NumberBuffers - 1;
        end;

      LoadNextPage;
    end
  else { we are using just one buffer }
    if not Eof(LogFileRead) then
      begin
        LoadPageBuffer(0);
        DisplayBuffer(0);
      end;
end;

procedure ShowPreviousPage;

begin
  if DisplayedBuffer <> FirstBuffer then
    begin
      Dec(DisplayedBuffer);

      if DisplayedBuffer < 0 then { need to wrap }
        DisplayedBuffer := NumberBuffers - 1;

      DisplayBuffer(DisplayedBuffer);
    end;
end;

procedure ViewRadioDebug;

var
  Key                              : Char;
  FileString, FileName, TempString : string;
  FileRead                         : file;
  Lines, RecordNumber, Result      : integer;
  Band                             : BandType;
  Mode                             : ModeType;
  Freq                             : LONGINT;
  RealFreq                         : REAL;

begin
  {
    ClrScr;
    TextColor(Yellow);

    WriteLnCenter('Look at Radio1Object.RadioModel.DBG file');
    WriteLn;

    TextColor(Cyan);

    WriteLn('This procedure will allow you to look at a Radio1Object.RadioModel.DddBG file and have the');
    WriteLn('program calculate the frequency and mode from that data using the same');
    WriteLn('algorithm that the program would us if it was interfaced to that Radio1Object.RadioModel.');
    WriteLn;

    FileName := GetResponse('Enter filename of Radio1Object.RadioModel debug file to process : ');
    if FIleName = '' then Exit;

    if not FileExists(FileName) then
    begin
      ReportError('Unable to find ' + FileName);
      Exit;
    end;

    repeat
      Key := UpCase(GetKey('Enter Radio1Object.RadioModel type: (K)enwood (Y)aesu (J)ST (I)com or (T)enTec : '));
      if Key = EscapeKey then Exit;
    until (Key = 'K') or (Key = 'Y') or (Key = 'J') or (Key = 'I') or (Key = 'T');
    WriteLn;

    case Key of
      'K': Radio1.RadioModel := TS850; //KK1L: 6.73 NOTE This covers the K2 case as well!

      'J': Radio1.RadioModel := JST245;

      'I': Radio1.RadioModel := IC781; //KK1L: 6.73 Was IC735. This rig uses the wrong freq data length

      'T': begin
          repeat
            Key := UpCase(GetKey('Enter 1 for Omni-VI or 2 for Orion : '));
            if Key = EscapeKey then Exit;
          until (Key = '1') or (Key = '2');
          WriteLn;

          if Key = '1' then Radio1.RadioModel := OMNI6 else Radio1.RadioModel := Orion;
        end;

      'Y': begin
          repeat
            TempString := UpperCase(GetResponse('Enter full model number (i.e., FT1000MP) : '));

            if TempString = '' then Exit;

            Radio1.RadioModel := NoInterfacedRadio;

            if TempString = 'FT1000MP' then Radio1.RadioModel := FT1000MP;
            if TempString = 'FT1000' then Radio1.RadioModel := FT1000;
            if TempString = 'FT100' then Radio1.RadioModel := FT100;
            if TempString = 'FT847' then Radio1.RadioModel := FT847;
            if TempString = 'FT890' then Radio1.RadioModel := FT890;
            if TempString = 'FT920' then Radio1.RadioModel := FT920;
            if TempString = 'FT990' then Radio1.RadioModel := FT990;
          until Radio1.RadioModel <> NoInterfacedRadio;
        end;
    end;

    Assign(FileRead, FileName);
    Reset(FileRead, 1);

    RecordNumber := 1;
    Lines := 7;

    TextColor(Cyan);

    while not Eof(FileRead) do
    begin
      BlockRead(FileRead, FileString, SizeOf(FileString), Result);

      if GetRadioParameters(RadioOne, FileString, Freq, Band, Mode, TRUE, False) then
      begin
        RealFreq := Freq / 1000;
        WriteLn('Record #', RecordNumber, ' ', RealFreq: 8: 3, ' kHz  ', BandString[Band], ModeString[Mode]);
      end
      else
        WriteLn('Error found at record ', RecordNumber);

      Inc(RecordNumber);
      Inc(Lines);

      if (Lines >= 22) and not Eof(FileRead) then
      begin
        WaitForKeyPressed;
        Lines := 1;
        TextColor(Cyan);
        ClrScr;
      end;

    end;

    Close(FileRead);
   }
end;

procedure ViewLogFile;

var
  Buffer                           : integer;
  Key                              : Char;
  TempString                       : Str20;
  TimeMark                         : TimeRecord;
  FileName                         : Str80;

begin
  {  if QTCsEnabled then
    begin

      repeat
        TempString := UpperCase(QuickEditResponse('(Q)TC file or (L)og file view? (Q/L) : ', 1));
        if TempString = EscapeKey then Exit;
        Key := TempString[1];
      until (Key = 'Q') or (Key = 'L');

      if Key = 'Q' then
        FileName := QTCFileName
      else
        FileName := LogFileName;
    end
    else
      FileName := LogFileName;

    QuickDisplay('File view.  Use PageUp/Down, HOME and END.  ESCAPE to quit');

    SaveAndSetActiveWindow(BigWindow);
    StartLogFileView(FileName);
    DisplayFreeMemory;

    if Key = 'Q' then // Go to end of file as starting point
    begin
      ClrScr;
      Write('Reading file...  Use ESCAPE to stop.');

      while (not Eof(LogFileRead)) and (not KeyPressed) do
        LoadNextPage;

      if KeyPressed then
        while KeyPressed do Key := ReadKey;

      DisplayedBuffer := FirstBuffer - 1;
      if DisplayedBuffer < 0 then
        DisplayedBuffer := NumberBuffers - 1;
      DisplayBuffer(DisplayedBuffer);
    end;

    MarkTime(TimeMark);

    repeat
      while KeyPressed do ReadKey;

      repeat
        UpdateTimeAndRateDisplays(False, False);

        if ActiveMultiPort <> NoPort then
          if ElaspedSec100(TimeMark) > 2000 then
          begin
            RestorePreviousWindow;
            RemoveWindow(QuickCommandWindow);
            Close(LogFileRead);

            for Buffer := 0 to NumberBuffers - 1 do
              Dispose(TextBuffer[Buffer]);
            DisplayFreeMemory;
            Exit;
          end;

      until KeyPressed;

      Key := ReadKey;

      MarkTime(TimeMark);

      case Key of
        NullKey:
          begin
            Key := ReadKey;

            case Key of
              PageUpKey: ShowPreviousPage;

              PageDownKey: ShowNextPage;

              HomeKey:
                begin
                  if MaxAvail > SizeOf(PageBuffer) then
                    DisplayBuffer(0)
                  else
                  begin
                    Close(LogFileRead);
                    for Buffer := 0 to NumberBuffers - 1 do
                      Dispose(TextBuffer[Buffer]);
                    StartLogFileView(FileName);
                  end;
                end;

              EndKey:
                begin
                  ClrScr;
                  Write('Reading file...  Use ESCAPE to stop.');

                  while (not Eof(LogFileRead)) and (not KeyPressed) do
                    LoadNextPage;

                  if KeyPressed then
                    while KeyPressed do Key := ReadKey;

                  DisplayedBuffer := FirstBuffer - 1;
                  if DisplayedBuffer < 0 then
                    DisplayedBuffer := NumberBuffers - 1;
                  DisplayBuffer(DisplayedBuffer);
                end;

            end;
          end;

        EscapeKey:
          begin
            RestorePreviousWindow;
            RemoveWindow(QuickCommandWindow);
            Close(LogFileRead);

            for Buffer := 0 to NumberBuffers - 1 do
              Dispose(TextBuffer[Buffer]);
            DisplayFreeMemory;
            Exit;
          end;

      end;

      DisplayFreeMemory;
    until False;
  }
end;

procedure SetAlarm;

var
  Hour, Minute, Second, Sec100     : Word;
  TempString, HourTempString, MinuteTempString: Str80;
  CharPointer, Result, Year, Month, Day: integer;

begin
  {  if AlarmSet then
    begin
      RemoveWindow(AlarmWindow);
      AlarmSet := False;
      Exit;
    end;

    SaveSetAndClearActiveWindow(QuickCommandWindow);

    repeat
      ClrScr;

      TempString := LineInput('Enter alarm time (HH:MM) : ', '', False, False);

      if (TempString = '') or (TempString = EscapeKey) then
      begin
        RemoveAndRestorePreviousWindow;
        Exit;
      end;

    until TempString[3] = ':';

    HourTempString := '';

    CharPointer := 1;

    while TempString[CharPointer] <> ':' do
    begin
      HourTempString[CharPointer] := TempString[CharPointer];
      Inc(CharPointer);
    end;

    HourTempString[0] := Chr(CharPointer - 1);

    Inc(CharPointer);

    MinuteTempString[1] := TempString[CharPointer];
    Inc(CharPointer);
    MinuteTempString[2] := TempString[CharPointer];
    MinuteTempString[0] := Chr(2);

    Val(HourTempString, AlarmHour, Result);
    Val(MinuteTempString, AlarmMinute, Result);

    RemoveAndRestorePreviousWindow;
    SaveSetAndClearActiveWindow(AlarmWindow);

    Write(' Alarm = ', HourTempString, ':', MinuteTempString);
    AlarmSet := True;
    RestorePreviousWindow;
   }
end;

procedure ContextHelp(Subject: HelpSubject);

var
  Key                              : Char;

begin
  {
    RemoveWindow(EditableLogWindow);
    RemoveWindow(TotalWindow);

    SaveSetAndClearActiveWindow(BigWindow);
    ClrScr;
    WriteLnCenter('HELP MENU');
    WriteLn;

    case Subject of
      NoSubject:
        begin
        end;
    end;

    WriteLn;
    Write('Press any key to continue...');
    RestorePreviousWindow;

    repeat
      UpdateTimeAndRateDisplays(False, False)
    until KeyPressed;

    Key := ReadKey;
    if Key = NullKey then Key := ReadKey;
  }
end;

procedure ProcessAltHelp;

begin
  {  case ReadKey of
      AltDash:
        begin
          WriteLn('The Alt-- (Alt Dash) command will toggle the Auto Send feature if the AUTO');
          WriteLn('SEND CHARACTER COUNT has been set to something greater than zero.  When ');
          WriteLn('enabled, an arrow will appear above the call window showing you the cursor');
          WriteLn('position where CW will be automatically started when entering a callsign.');
          WriteLn('When the Auto Send feature is disabled, this arrow will disappear.');
        end;

      AltEqual:
        begin
          WriteLn('The Alt-= does two different things depending on the active mode.');
          WriteLn;
          WriteLn('If you are in the CW mode, this command will toggle the sidetone on or off.');
          WriteLn('If the sidetone was set to zero in LOGCFG.DAT, it will be turned on at 700');
          WriteLn('hertz.');
          WriteLn;
          WriteLn('If you are in the SSB mode and the DVP is enabled, you will be shown a list');
          WriteLn('of the backcopy files you have made and can review or delete them.');
        end;

      AltA:
        begin
          WriteLn('The Alt-A has two functions.  If you have entered some characters in the call');
          WriteLn('window and have specified a SCP FILENAME (e.g. MASTER.DTA) then a manual super');
          WriteLn('check partial will be performmed.  Otherwise, this command will allow you to');
          WriteLn('control a built in alarm clock.');
          WriteLn;
          WriteLn('When setting the alarm, you will be asked to enter the time you want the alarm');
          WriteLn('sound.  This time will be displayed in the lower right corner of the screen.');
          WriteLn('To stop or clear the alarm, press Alt-A again.  It will signal you every few');
          WriteLn('minutes until you turn it off.');
          WriteLn;
          WriteLn('When performming a super check partial, the results are shown in the editable');
          WriteLn('log window.  Press Alt-A again to clear the results.  A minimum of 2 characters');
          WriteLn('need to be entered and you can use question marks to match any character.');
        end;

      AltB:
        begin
          WriteLn('The Alt-B command will move you up one band.  If the MULTIPLE BANDS flag');
          WriteLn('has been set to FALSE (as it would automatically in a single band');
          WriteLn('contest), and you have made at least one QSO, nothing will happen.');
        end;

      AltC:
        begin
          WriteLn('The Alt-C command will continue the last auto CQ that was set up using the');
          WriteLn('Alt-Q command.  Remember the PageUp and PageDown keys are redefined while ');
          WriteLn('you are auto CQing.  Pressing them will change the delay time between CQs.');
        end;

      AltD:
        begin
          WriteLn('The Alt-D command will perform a dupecheck on the inactive radio''s band and');
          WriteLn('mode.  You will be asked for the callsign of the station you want to have');
          WriteLn('checked.  The QSO and multiplier status windows will be updated with the');
          WriteLn('information for that station.  If you decide to work the station, pressing');
          WriteLn('the space bar will put you in the Search and Pounce mode with the proper');
          WriteLn('band and mode set.  After the QSO is complete, you will be returned to the');
          WriteLn('CQ mode with your original band and mode set.');
          WriteLn;
          WriteLn('This command is even more powerful if you are using the TWO RADIO MODE on CW.');
          WriteLn('In this case, pressing the space bar will also call the station as if you');
          WriteLn('pressed F1, wait for the CW to stop, and then call CQ on the original radio.');
          WriteLn('Pressing F2 or RETURN will interrupt this CQ and send the exchange on the');
          WriteLn('second radio.  Finally a CQ will start back on the first radio automatically.');
        end;

      AltE:
        begin
          WriteLn('The Alt-E command will allow you to edit the editable log which contains the');
          WriteLn('last five QSOs you have made.  The TAB and Shift-TAB keys can be used to move');
          WriteLn('the highlighted cursor field forward or backward.  This is a low level edit,');
          WriteLn('so if you make changes to the QTH, you need to make the changes to the');
          WriteLn('multiplier field.  This editor will only allow you to overwrite data so the');
          WriteLn('other columns will not be misaligned by adding characters.');
          WriteLn;
          WriteLn('When you are done editing the log, press ESCAPE.  You will then be asked if you');
          WriteLn('want to save the changes you have made, or go back to what you had before');
          WriteLn('executing the Alt-E command.  CONFIRM EDIT CHANGES can be set FALSE to disable');
          WriteLn('being asked if you want to save the changes.');
          WriteLn;
          WriteLn('You can also activate the editor if your cursor is in a blank call window by');
          WriteLn('pressing the up arrow.');
        end;

      AltF:
        begin
          WriteLn('The Alt-F command will force a save of the LOG.DAT file to the floppy that');
          WriteLn('was set up with a FLOPPY FILE SAVE NAME command in LOGCFG.DAT.  If the name');
          WriteLn('was not set up, no save will be done.  You can make these saves happen auto-');
          WriteLn('matically by using the FLOPPY FILE SAVE FREQUENCY command in LOGCFG.DAT');
        end;

      AltG:
        begin
          WriteLn('If there is more than one type of remaining multiplier display, the Alt-G');
          WriteLn('command will switch between them.  For example, in the CQ WW contest, the');
          WriteLn('Alt-G command will switch between the remaining country display and the');
          WriteLn('remaining zone list.  Please note that there is not a remaining prefix list.');
        end;

      AltH:
        begin
          WriteLn('The Alt-H command enters the online help function that you are now using.');
        end;

      AltI:
        begin
          WriteLn('The Alt-I command will increment a (received) numeric value in the exchange');
          WriteLn('window by one.  This is handy when you are searching and pouncing and didn''t');
          WriteLn('bust through the pileup.');
        end;

      AltJ:
        begin
          WriteLn('The Alt-J command will toggle the enable for a multiplier bell.  You can tell');
          WriteLn('it is enabled when the bell rings when pressing Alt-J.');
        end;

      AltK:
        begin
          WriteLn('The Alt-K command will disable the sending of CW immediately. Sending will be');
          WriteLn('restored when either another Alt-K command is issued, or when a CW function');
          WriteLn('key memory is pressed.  While sending is disabled, the code speed window will');
          WriteLn('show NO CW!!.  This mode is very handy when having to take over a QSO by');
          WriteLn('sending manually.');
          WriteLn;
          WriteLn('If you are using the DVP, the Alt-K command will enable or disable DVP sending.');
        end;

      AltL:
        begin
          WriteLn('The Alt-L command will allow you to look through your LOG.DAT file for all');
          WriteLn('occurances of a search string.  This can be used to find a previous QSO and');
          WriteLn('prove to someone that they really are a dupe.  If you are looking for N6AR,');
          WriteLn('it will help to put a space after the N6AR so you won''t also get entries ');
          WriteLn('that start with N6AR (ie: N6ARA).  The question mark will match any character.');
          WriteLn('Searches are case insensitive.  It can be used anywhere except as the first');
          WriteLn('character of the search string.  If there is something in the call window,');
          WriteLn('it will be used as a default which you can simply type over if you don''t want');
          WriteLn('to use it.');
        end;

      AltM:
        begin
          WriteLn('The Alt-M command will swap modes between CW and SSB.  If the MULTIPLE MODES');
          WriteLn('ENABLED flag has been set to FALSE (as it would in a single mode contest),');
          WriteLn('and you have made at least one QSO, nothing will happen.');
        end;

      AltN:
        begin
          WriteLn('The Alt-N command will put your Kenwood or Yaesu radio into split mode and');
          WriteLn('set the transmit VFO to the frequency entered.  You can enter just the last');
          WriteLn('three digits of the frequency in most cases.  You can also activate this');
          WriteLn('function with the single dash key, allowing you to enter the frequency by');
          WriteLn('using only the numeric keypad (in NUM LOCK mode).');
        end;

      AltO:
        begin
          WriteLn('The Alt-O command allows you to add reminders on line without having to stop');
          WriteLn('the program and edit the LOGCFG.DAT file.  Added reminders will automatically');
          WriteLn('be written to the LOGCFG.DAT file so they will be remembered in the case of');
          WriteLn('a power failure.  Control characters can be entered by pressing control-P and');
          WriteLn('then the control character.');
        end;

      AltP:
        begin
          WriteLn('The Alt-P command will allow you to change the contents of a function key');
          WriteLn('memory or other QSO message.  Keep in mind that there are two sets of function');
          WriteLn('key memories, those for CQ mode and those for the exchange/search and pounce');
          WriteLn('mode.  Follow the prompts to edit other messages such as CQ Exchange.  In all');
          WriteLn('cases, you will be shown the existing message which you can either edit or');
          WriteLn('overwrite.  ESCAPE will exit you from the AltP function with no changes made');
          WriteLn('to the message.  Your new message will be appended to your LOGCFG.DAT file so');
          WriteLn('it will be there if you restart the program.');
        end;

      AltQ:
        begin
          WriteLn('The Alt-Q command will allow you to set up a given memory to be repeated at');
          WriteLn('selected intervals.  This is handy for making a CQ repeat automatically.');
          WriteLn('When any key is pressed, the CQ will stop immediately.  If the key is a valid');
          WriteLn('callsign key, it will be entered into the call window.  To resume the last');
          WriteLn('auto CQ setup, use the Alt-C command.  While you are auto CQing, you can ');
          WriteLn('use the PageUp and PageDown keys to change the delay time between messages');
          WriteLn('in half second steps.');
        end;

      AltR:
        begin
          WriteLn('The Alt-R command will toggle between the two radios you have set up.');
          WriteLn('The mode and band will be updated to the proper values and the radio name');
          WriteLn('display in the lower left corner of the screen will be updated.');
          WriteLn;
          WriteLn('If you are on CW mode, the code speed will be remembered for each radio');
          WriteLn('separately.');
        end;

      AltS:
        begin
          WriteLn('The Alt-S command will allow you to enter the desired code speed.  If you');
          WriteLn('want to use the speed knob on the MM3, enter 0 WPM.  You can also change');
          WriteLn('the code speed by using the PageUp and PageDown keys.');
          WriteLn;
          WriteLn('If you are using two radios, the code speed is set separately for each');
          WriteLn('radio.');
        end;

      AltT:
        begin
          WriteLn('The Alt-T command will allow you to set the time and date.  The time will');
          WriteLn('be set with the seconds at zero.');
          WriteLn;
          WriteLn('If you are using the multi network, you will be asked if you would like to');
          WriteLn('send the date and time to all of the computers on the network.');
        end;

      AltU:
        begin
          WriteLn('The Alt-U command will move the contents of the editable log into the LOG.DAT');
          WriteLn('file.  This is normally done after the contest is over so all your contacts are');
          WriteLn('in the LOG.DAT file.  The LOG.TMP file will be erased.  This command is also');
          WriteLn('useful when QTCs are enabled as the contacts in the editable log window must');
          WriteLn('be moved into the LOG.DAT file before they can be sent as QTCs.');
        end;

      AltV:
        begin
          WriteLn('The Alt-V command will move you down one band.  If the MULTIPLE BANDS ENABLED');
          WriteLn('has been set to FALSE (as it would for a single band contest), nothing will');
          WriteLn('happen.');
        end;

      AltW:
        begin
          WriteLn('The Alt-W command will allow you to reset the wake up counter to zero.');
          WriteLn('You would do this when the wake up timeout alarm has sounded and you want');
          WriteLn('it to stop as if you had made another QSO.');
        end;

      AltX:
        begin
          WriteLn('The Alt-X command will allow you to exit the program.  You will be asked if');
          WriteLn('you really want to exit in case you hit Alt-X by mistake.');
        end;

      AltY:
        begin
          WriteLn('The Alt-Y command will delete the last QSO you have made that is displayed');
          WriteLn('on the bottom of the editable log window.  This contact can be restored');
          WriteLn('by pressing Alt-Y again before another contact is made.');
        end;

      AltZ:
        begin
          WriteLn('The Alt-Z command will recalculate the initial exchange entry based upon');
          WriteLn('the callsign entered in the call window.  This is handy if you came back');
          WriteLn('to a station, then change his prefix, and want to have the program to tell');
          WriteLn('you his zone.');
        end;

      Alt1:
        begin
          WriteLn('Pressing Alt and a number key (ie: Alt-1) will increment the time to the');
          WriteLn('next even minute.  This function is quite handy if you are entering QSOs');
          WriteLn('manually from another log.  You would set the time and date to the first');
          WriteLn('QSO of the log and then use this function to increment the time as needed');
          WriteLn('for each QSO.  This feature must be enabled by putting the following ');
          WriteLn('command in your LOGCFG.DAT file: INCREMENT TIME ENABLE = TRUE.');
          WriteLn;
          WriteLn('This function should not be used if you have set the HOUR OFFSET to a non');
          WriteLn('zero value as it will affect your system clock.');
        end;

    end;
  }
end;

procedure PutUpHelpMenu;

var
  Key                              : Char;

begin
  {  RemoveWindow(EditableLogWindow);
    RemoveWindow(TotalWindow);

    repeat
      SaveSetAndClearActiveWindow(BigWindow);
      ClrScr;
      WriteLn('Alt-A - Alarm set      Alt-P - Pgrm CW mem       Ctrl-B - Talk to packet TNC');
      WriteLn('Alt-B - Band up        Alt-Q - Auto CQ setup     Ctrl-J - LOGCFG value edit');
      WriteLn('Alt-C - Auto CQ resume Alt-R - Radio toggle      Ctrl-K - Clear dupesheet');
      WriteLn('Alt-D - Dupecheck      Alt-S - Set CW speed      Ctrl-L - LOG.DAT file view');
      WriteLn('Alt-E - Edit QSOs      Alt-T - Time/date set     Ctrl-N - Note entry into log');
      WriteLn('Alt-F - Floppy save    Alt-U - Flush edit log    Ctrl-O - Missing mult report');
      WriteLn('Alt-G - Swap mults     Alt-V - Band down         Ctrl-P - Possible call redo');
      WriteLn('Alt-H - Help menu      Alt-W - Wake up reset     Ctrl-Q - QTC functions');
      WriteLn('Alt-I - Inc rcvd #     Alt-X - Exit program      Ctrl-R - Last erased call');
      WriteLn('Alt-J - Mult bell      Alt-Y - Delete last QSO   Ctrl-U - Last 10 packet spots');
      WriteLn('Alt-K - Kill CW        Alt-Z - Redo initial ex   Ctrl-V - Execute config file');
      WriteLn('Alt-L - Log search     Alt-= - CW tone/Backcopy  Ctrl-Y - Retime band map call');
      WriteLn('Alt-M - SSB/CW Mode    Alt-- - AutoSend toggle   Ctrl-- - 2 radio dualing CQs');
      WriteLn('Alt-N - XMIT freq      Alt-1 - Increment time    Ctrl-Ent Same as RET w/o msg');
      WriteLn('Alt-O - Add reminder   " - Send multi message    ` - Send spot to packet.');
      WriteLn('SPACE BAR - Check if dupe or if no call, go into S&P and send call');
      Write('      Press the key you want more information for or ESCAPE to exit help:');
      RestorePreviousWindow;

      repeat
        UpdateTimeAndRateDisplays(False, False)
      until KeyPressed;

      SaveSetAndClearActiveWindow(BigWindow);
      ClrScr;

      Key := ReadKey;

      case UpCase(Key) of

        EscapeKey: Exit;
        NullKey: ProcessAltHelp;

        ' ':
          begin
            WriteLn('The most common use for the SPACE BAR is to check if a callsign entered');
            WriteLn('in the call window is a dupe or not.  This is not a necessary step in ');
            WriteLn('normal operation because the program does check the call itself when you');
            WriteLn('press RETURN, but if you are interested in finding out it is a dupe before');
            WriteLn('pressing RETURN (and possibly sending CW), then the SPACE BAR is an easy');
            WriteLn('way to do this.  You will also be shown the station''s name, if known.');
            WriteLn;
            WriteLn('If the call window is empty and there is not any dupe information on the');
            WriteLn('screen in the upper right corner, then pressing SPACE BAR is a short cut way');
            WriteLn('to enter the search and pounce mode AND send your callsign.');
            WriteLn;
            WriteLn('When you use the Alt-D command to check for a dupe on the inactive radio');
            WriteLn('or a packet spot comes up, there will be station information shown in the');
            WriteLn('upper right hand corner of the screen.  If this information is present, ');
            WriteLn('pressing the SPACE BAR will allow you to work that station.');
          end;

        '"':
          begin
            WriteLn('If you are using the program in the multi mode, you can send messages to ');
            WriteLn('the other computers connected.  Use the " key to open a window and enter');
            WriteLn('who you want the message to go to, a spaceq, and then the message.  You');
            WriteLn('can address a message to the band you want the message to go to (160, 80');
            WriteLn('75, 40, 20, 15 or 10) or to ALL of the computers.  The message will be');
            WriteLn('instantly displayed on the proper computers with an audiable alert.');
          end;

        '`':
          begin
            WriteLn('The ` key will send a spot to packet when a valid call is in the call');
            WriteLn('window, you have the packet port set up and the program can read the');
            WriteLn('the frequency from your interfaced radio.');
          end;

        ControlB:
          begin
            WriteLn('The Control-B command allows you to access a 13 line window for talking to ');
            WriteLn('packet TNC.  Typically you would access this window to log onto a packet');
            WriteLn('cluster and then exit from it to operate a contest.  DX Spots that are new');
            WriteLn('multipliers will be shown to you.  You can also type sh/dx while the packet');
            WriteLn('window is up and then exit before the data shows up, and the spot information');
            WriteLn('will be loaded into the spot memory that you can access with the Control-U');
            WriteLn('command.');
            WriteLn;
            WriteLn('While the packet window is active, you can press F1 to call CQ.  This is');
            WriteLn('handy if you are talking to a friend on packet and want to continue to  call');
            WriteLn('CQ in the contest.  If someone answers you, press ESCAPE to exit the window');
            WriteLn('and then work the station.  When you press Control-B after the QSO, the window');
            WriteLn('will show any data that you missed while you were busy.');
            WriteLn;
            WriteLn('You need the PACKET PORT command in LOGCFG.DAT to enable packet operations.');
          end;

        ControlJ:
          begin
            WriteLn('The Control-J command can be used to change many of the LOGCFG.DAT commands');
            WriteLn('while the program is running.  To see which ones can be accessed, simply try');
            WriteLn('running the command.');
            WriteLn;
            WriteLn('You can select which parameter you want to modify using the cursor keys.  For');
            WriteLn('each entry, you are shown the LOGCFG.DAT name for the parameter, the current');
            WriteLn('value of the parameter, and a short description explaining what the result of');
            WriteLn('the current value is.  You can change the value by pressing RETURN.  For most');
            WriteLn('of the parameters, this will toggle the value to the next value.  For others,');
            WriteLn('you will have to enter a new value for the parameter.');
            WriteLn;
            WriteLn('The Alt-W command may be used to write the selected entry to the LOGCFG.DAT ');
            WriteLn('file.  This will make the change permanent even if the program is restarted.');
          end;

        ControlK:
          begin
            WriteLn('The Control-K command will clear the dupesheet.  This is used for those');
            WriteLn('contests where you can work people again on the second day of the contest');
            WriteLn('Use this command after the first day so you can work people again without');
            WriteLn('the program flagging them as dupes.');
          end;

        ControlL:
          begin
            WriteLn('The Control-L command will allow you to browse through the LOG.DAT file.');
            WriteLn('The PageUp, PageDown, Home and End keys can be used to move around. ');
            WriteLn('No editing of the LOG.DAT is supported.  To exit, simply press ESCAPE.');
          end;

        ControlN:
          begin
            WriteLn('The Control-N command will allow you to input a single line note to the log.');
            WriteLn('The note will appear with a semi-colon in front of it which makes sure the ');
            WriteLn('line is not counted as a QSO.  After the contest, POST can create a file with');
            WriteLn('all the notes you have made.  Any notes in your log will not appear in your');
            WriteLn('final band/mode log as generated by POST.');
            WriteLn;
          end;

        ControlO:
          begin
            WriteLn('The Control-O command can be used when you have any kind of country DX     ');
            WriteLn('multiplier.  This command will display a list of countries that you have   ');
            WriteLn('worked on at least 4 bands, but not all 6 bands.  It will show you the bands');
            WriteLn('with QSOs indicated with asterisks.  This display is quite useful to make ');
            WriteLn('sure you are not missing any of the active countries on easy bands.');
          end;

        ControlP:
          begin
            WriteLn('The Control-P command will show you all the information known for the call');
            WriteLn('presently in the call window, including possible calls (if enabled).');
          end;

        ControlQ:
          begin
            WriteLn('When using QTCs, the Control-Q command is used to either send or receive QTCs');
            WriteLn('with the station you are currently working.');
          end;

        ControlR:
          begin
            WriteLn('If you have erased a callsign using the ESCAPE key, you can recall the ');
            WriteLn('callsign with the Control-R command.  This can also be used for erased');
            WriteLn('exchanges.');
          end;

        ControlU:
          begin
            WriteLn('The Control-U command allows you to review the last 10 packet spots.  The');
            WriteLn('spots were either shown to you as new multipliers or they can come from');
            WriteLn('a sh/dx command that was executed using the packet window (Control-B).  To');
            WriteLn('load the spot memory using a sh/dx command, you must exit the packet window');
            WriteLn('before the data comes back from the cluster.');
            WriteLn;
            WriteLn('You can move a cursor to any of the listed stations and press RETURN to set');
            WriteLn('up the program and your radio to work that station.');
          end;

        ControlY:
          begin
            WriteLn('When using the band map, the Control-Y command will refresh the time for');
            WriteLn('whatever entry is currently blinking.');
          end;

        ControlDash:
          begin
            WriteLn('If you are using two radios, the Control-Dash function will send the      ');
            WriteLn('message programmed in CQ memory Alt-F1 alternately on each radio.  This   ');
            WriteLn('is typically a short CQ message so you can CQ on two bands at once.  If   ');
            WriteLn('you get a response, simply type in the call as you normally would.  The CQ');
            WriteLn('on the other band will finish and then the station will be called on the  ');
            WriteLn('correct band.  While the station is sending you the exchange, another CQ  ');
            WriteLn('will be sent on the other band.  This technique allows you to be          ');
            WriteLn('transmitting 100 percent of the time!  It is best used when the rate is ');
            WriteLn('fairly slow on both bands (ie: around 40 per hour or less) and with short ');
            WriteLn('CQ messages (e.g. TEST N6TR TEST).');
          end;

        ControlBackSlash:
          begin
            WriteLn('The Control-\ or Control-Enter key will allow you to take a CQ mode QSO to ');
            WriteLn('the next step without sending CW.  This applies to either the CQ EXCHANGE or');
            WriteLn('the QSL MESSAGE.');
          end;

      else
        begin
          ClrScr;
          WriteLn;
          WriteLn('No help available for that command', Beep);
        end;
      end;

      WriteLn;
      Write('Press any key to continue...');
      RestorePreviousWindow;

      repeat
        UpdateTimeAndRateDisplays(False, False)
      until KeyPressed;

      if ReadKey = NullKey then ReadKey;
    until False;
   }
end;

procedure DisplayCountryInformation(FileName: Str80; Call: CallString);

{ This procedure will go search through the file specified and if it
  finds an entry with the country ID for the callsign indicated, it
  will display the data contained after that line, until the next blank
  line if found (up to five lines).  The information will be displayed
  in the editable log window. }

var
  FileRead                         : Text;
  CountryID                        : Str20;
  FileString                       : Str80;
  WhereY                           : integer;
begin
  //  if tr4w_WindowsArray[tr4w_LAST5WINDOW_INDEX].tr4w_WndHandle = 0 then Exit;
  if not OpenFileForRead(FileRead, FileName) then Exit;

  CountryID := CountryTable.GetCountryID(CountryTable.GetCountry(Call, True));

  strU(@CountryID);
  WhereY := 1;
  while not Eof(FileRead) do
    begin
      ReadLn(FileRead, FileString);

      if UpperCase(FileString) = CountryID then
        begin
          //      SaveSetAndClearActiveWindow(EditableLogWindow);

          repeat
            ReadLn(FileRead, FileString);

            if FileString <> '' then
              begin
                //          if WhereX > 1 then WriteLn;
                //          Write(FileString);
                //          SendDlgItemMessage(tr4w_WindowsArray[tr4w_LAST5WINDOW_INDEX].tr4w_WndHandle, 101, LB_ADDSTRING, 0, integer(PChar(string(FileString))));
                //          SendMessage(_EditableLogWindow, LB_ADDSTRING, 0, integer(PChar(string(FileString))));
                inc(WhereY);
              end;

          until (WhereY = 5) or (FileString = '');

          Close(FileRead);
          //      RestorePreviousWindow;
          Exit;

        end;

    end;

  Close(FileRead);
end;

procedure ComputeGridDistance;

var
  Grid1, Grid2                     : Str20;
  Distance                         : REAL;

begin
  {  ClrScr;
    TextColor(Yellow);
    WriteLnCenter('COMPUTE DISTANCE BETWEEN TWO GRID SQUARES');
    TextColor(Cyan);
    WriteLn;
    WriteLn('This routine will compute the distance between two grid squares in kilometers.');
    WriteLn;

    repeat
      Grid1 := UpperCase(GetResponse('Enter first grid (none to exit) : '));
      if Grid1 = '' then Exit;
      Grid2 := UpperCase(GetResponse('Enter second grid (none to exit) : '));
      if Grid2 = '' then Exit;

      Distance := GetDistanceBetweenGrids(Grid1, Grid2);
      WriteLn('Distance = ', Distance: 6: 1, ' kilometers');

      Distance := GetEuropeanDistanceBetweenGrids(Grid1, Grid2);
      WriteLn('European VHF Distance = ', Distance: 6: 1, ' kilometers');

    until False;
   }
end;

procedure HexConvert;

var
  TempString                       : Str20;
  TempInt                          : LONGINT;
  Result                           : integer;

begin
  {  ClearScreenAndTitle('CONVERT NUMBERS TO/FROM HEX');

    WriteLn('This procedure will let you convert a base 10 number to / from HEX.  If you');
    WriteLn('are entering a HEX (base 16) number, put an H after it.  Otherwise, the');
    WriteLn('routine will assume it is a base 10 number to be converted to hex.');
    WriteLn;
    WriteLn('Enter a null string to exit.');
    WriteLn;

    repeat
      TempString := UpperCase(GetResponse('Enter number to convert (put an H after a hex number) : '));

      if TempString = '' then Exit;

      if StringHas(TempString, 'H') then
      begin
        Delete(TempString, Pos('H', TempString), 1);
        HexToLongInteger(TempString, TempInt, Result);
        WriteLn(TempInt);
      end
      else
      begin
        Val(TempString, TempInt, Result);
        WriteHexLongInt(TempInt);
        WriteLn;
      end;

    until False;
   }
end;

procedure HexDump;

{ Procedure to dump a HEX file so you can see what is in it. }

label
  ContinueSearch;

var
  FileName, ASCIIString            : Str20;
  SearchString                     : Str80;
  FileRead                         : file;
  FileByte                         : Byte;
  Key                              : Char;
  SizeOFFIle, NewAddress           : LONGINT;
  CharPos                          : integer;
  FileChar                         : Char;

begin
  {  if ParamStr(2) <> '' then
      FileName := ParamStr(2)
    else
      FileName := GetResponse('Enter file to do hex dump of : ');

    if (FileName = '') or not FileExists(FileName) then Exit;

    Assign(FileRead, FileName);
    Reset(FileRead, 1);

    ASCIIString := '';

    SizeOfFile := FileSize(FileRead);

    repeat
      if ((FilePos(FileRead) mod 256) = 0) or Eof(FileRead) then
      begin
        if (FilePos(FileRead) > 0) or Eof(FileRead) then
        begin
          WriteLn;
          WriteLn;

          repeat
            TextColor(Green);

            Key := UpCase(GetKey('ESCAPE, (S)earch, HOME, END, PAGE UP or PAGE DOWN'));

            if Key = EscapeKey then
            begin
              Close(FileRead);
              GoToXY(1, WhereY);
              ClrEol;
              Exit;
            end;

            if Key = 'S' then
            begin
              GoToXY(1, WhereY);
              ClrEol;
              SearchString := GetResponse('Enter string to search for : ');

              if SearchString <> '' then
              begin

                ContinueSearch:

                repeat
                  BlockRead(FileRead, FileChar, 1);
                  if FilePos(FileRead) mod 1000 = 0 then PinWheel;
                until (FilePos(FileRead) = SizeOfFile) or (FileChar = SearchString[1]);

                Seek(FileRead, FilePos(FileRead) - 1);

                if FilePos(FileRead) < (SizeOfFile - Length(SearchString)) then
                begin
                  for CharPos := 1 to Length(SearchString) do
                  begin
                    BlockRead(FileRead, FileChar, 1);

                    if not (SearchString[CharPos] = FileChar) then
                      goto ContinueSearch;
                  end;
                end
                else
                begin
                  GoToXY(1, WhereY);
                  ReportError(SearchString + ' not found!!');
                  WaitForKeyPressed;
                end;

                              // We found the search string!

                NewAddress := FilePos(FileRead) - 16 - Length(SearchString);
                while (NewAddress mod 256) <> 0 do Dec(NewAddress);
                Seek(FileRead, NewAddress);
              end;
            end;

            if Key = NullKey then Key := ReadKey;

          until (Key = PageUpKey) or
            ((Key = PageDownKey) and not Eof(FileRead)) or
            (Key = HomeKey) or
            (Key = AltA) or
            (Key = 'S') or
            (Key = EndKey);

          case Key of
            PageUpKey:
              begin
                NewAddress := FilePos(FileRead);

                if NewAddress > 0 then
                  NewAddress := NewAddress - 257;

                while (NewAddress mod 256) <> 0 do Dec(NewAddress);

                if NewAddress < 0 then NewAddress := 0;

                Seek(FileRead, NewAddress);
              end;

            HomeKey:
              begin
                NewAddress := 0;
                Seek(FileRead, NewAddress);
              end;

            EndKey:
              begin
                NewAddress := FileSize(FileRead) - 1;
                while ((NewAddress mod 256) <> 0) do Dec(NewAddress);
                Seek(FileRead, NewAddress);
              end;

          end;
        end;

        ClrScr;
        TextColor(Yellow);
        WriteLnCenter('HEX DUMP FOR ' + FileName);
        WriteLn;

        ASCIIString := '';
      end;

      TextColor(Cyan);

      if (FilePos(FileRead) mod 16) = 0 then
      begin
        WriteHexWord(FilePos(FileRead) div 65536);
        WriteHexWord(FilePos(FileRead) mod 65536);
        Write('  ');
      end;

      BlockRead(FileRead, FileByte, 1);

      if (FileByte >= 32) and (FileByte <= 126) then
        ASCIIString := ASCIIString + Chr(FileByte)
      else
        ASCIIString := ASCIIString + '.';

      WriteHexByte(FileByte);
      Write(' ');

      if (WhereX >= 35) and (WhereX <= 37) then Write(' ');

      if (FilePos(FileRead) mod 16) = 0 then
      begin
        WriteLn('   ', ASCIIString);
        ASCIIString := '';
      end;

    until False;
  }
end;

procedure ShowIOPorts;

begin
  {  ClrScr;
    TextColor(Yellow);
    WriteLnCenter('IO PORT ADDRESS TABLE');
    TextColor(Cyan);
    WriteLn;
    WriteLn('Here are the addresses found for the various I/O ports.  These addresses are');
    WriteLn('found in a table located in RAM starting at 40:0.  Your BIOS should be');
    WriteLn('initializing the values for you.  If TR finds no value in the table, it will');
    WriteLn('use the "industry standard" I/O address for that port (as shown).');
    WriteLn;

    Write('  COM1 = $');
    WriteHexWord(MemW[$40: 0]);

    if MemW[$40: 0] = 0 then
    begin
      Write('   Program will use $');
      WriteHexWord(Com1PortBaseAddress);
    end;

    WriteLn;

    Write('  COM2 = $');
    WriteHexWord(MemW[$40: 2]);

    if MemW[$40: 2] = 0 then
    begin
      Write('   Program will use $');
      WriteHexWord(Com2PortBaseAddress);
    end;

    WriteLn;

    Write('  COM3 = $');
    WriteHexWord(MemW[$40: 4]);

    if MemW[$40: 4] = 0 then
    begin
      Write('   Program will use $');
      WriteHexWord(Com3PortBaseAddress);
    end;

    WriteLn;

    Write('  COM4 = $');
    WriteHexWord(MemW[$40: 6]);

    if MemW[$40: 6] = 0 then
    begin
      Write('   Program will use $');
      WriteHexWord(Com4PortBaseAddress);
    end;

    WriteLn;
    WriteLn;

    Write('  LPT1 = $');
    WriteHexWord(MemW[$40: 8]);

    if MemW[$40: 8] = 0 then
    begin
      Write('   Program will use $');
      WriteHexWord(LPT1BaseAddress);
    end;

    WriteLn;

    Write('  LPT2 = $');
    WriteHexWord(MemW[$40: $A]);

    if MemW[$40: $A] = 0 then
    begin
      Write('   Program will use $');
      WriteHexWord(LPT2BaseAddress);
    end;

    WriteLn;

    Write('  LPT3 = $');
    WriteHexWord(MemW[$40: $C]);

    if MemW[$40: $C] = 0 then
    begin
      Write('   Program will use $');
      WriteHexWord(LPT3BaseAddress);
    end;

    WriteLn;

  }
end;

procedure IOPort;

var
  TempString, PortString, OutputString: Str80;
  OutputValue, InputValue, PortAddress, Result: integer;
  LoopMode                         : boolean;
  Key                              : Char;

begin
  {  LoopMode := False;
    TextColor(Cyan);
    WriteLn;
    WriteLn('Use L to change loop mode.');

    repeat
      WriteLn;

      if LoopMode then
        TempString := UpperCase(GetResponse('Loop Input or Output : '))
      else
        TempString := UpperCase(GetResponse('Input or Output : '));

      if TempString = '' then Exit;

      if (TempString[1] = 'I') or (TempString[1] = 'O') then
      begin
        PortString := GetResponse('Hex address : ');
        HexToInteger(PortString, PortAddress, Result);

        if Result = 0 then
        begin
          case TempString[1] of

            'I': begin
                if LoopMode then
                begin
                  Key := UpCase(GetKey('Constant display of value (slows down looping) (Y/N) : '));
                  WriteLn;
                  Write('Looping until key pressed.');
                end;

                GoToXY(1, WhereY);
                ClrEol;

                repeat
                  InputValue := Port[PortAddress];

                  if ((Key = 'Y') and LoopMode) or not LoopMode then
                  begin
                    GoToXY(1, WhereY);
                    Write('Value from port ', PortString, ' = ');
                    WriteHexByte(InputValue);
                  end;

                  if LoopMode then
                  begin
                    if KeyPressed then
                    begin
                      LoopMode := False;
                      ReadKey;
                      WriteLn;
                    end;
                  end
                  else
                    WriteLn;

                until not LoopMode;
              end;

            'O': begin
                OutputString := GetResponse('Enter hex value to output : ');
                HexToInteger(OutputString, OutputValue, Result);

                if Result = 0 then
                begin
                  WriteLn('Output ', OutputString, ' to ', PortString);
                  repeat
                    Port[PortAddress] := OutputValue;
                    if LoopMode then
                      if KeyPressed then
                      begin
                        GoToXY(1, WhereY);
                        ClrEol;
                        LoopMode := False;
                        ReadKey;
                      end;

                  until not LoopMode;
                end;
              end;

          end;
        end;
      end
      else
        if TempString = 'L' then LoopMode := not LoopMode;

    until False;
   }
end;

function DetermineRadioType(SerialPort: PortType): InterfacedRadioType;

{ This procedure will do its best to determine what kind of radio is
  connected to the specified serial port.  It is assumed the serial
  port is already initialized.}

var
  Count                            : LONGINT;
  Response                         : Str40;

begin
  { Looking for Kenwood ID response }
{
SendString(SerialPort, 'ID;');

Count := 0;
Response := '';

repeat
  if CharReady(SerialPort) then
  begin
    Response := Response + ReadChar(SerialPort);
    Count := 0;
  end;

  if (Copy(Response, 1, 2) = 'ID') and (Copy(Response, 6, 1) = ';') then
  begin
    WriteLn('Found a Kenwood radio!');
    DetermineRadioType := TS850;
    Exit;
  end;

  Delay(1);
  Inc(Count);
until (Count = 200);

Count := 0;
Response := '';

  // Now we try for Yaesu ID bytes

SendString(SerialPort, Chr(0) + Chr(0) + Chr(0) + Chr(0) + Chr($FA));

repeat
  if CharReady(SerialPort) then
  begin
    Response := Response + ReadChar(SerialPort);
    Count := 0;
  end;

  if Length(Response) = 5 then
  begin
    if (Ord(Response[4]) = 3) and (Ord(Response[5]) = $93) then
    begin
      DetermineRadioType := FT1000MP;
      Exit;
    end;

  end;

  Delay(1);
  Inc(Count);
until (Count = 300);
}
end;

procedure Inductance;

var
  l, f, c                          : REAL;

begin
  f := GetReal('Enter Frequency of resonance (MHz) : ');

  f := f * f;

  f := f * 0.00003948;

  c := GetReal('Enter Capacitance (pf) or Inductance (uH) : ');

  l := f * c;

  l := 1.0 / l;

  WriteLn(l: 3: 2, ' uH or pf')
end;

procedure PassThrough;

var
  FirstSerialPort, SecondSerialPort: PortType;
  Key                              : Char;
  BaudString                       : Str20;
  Result, BaudRate                 : integer;

begin
  {  ClrScr;
    WriteLn('Serial port pass through.  Connects to serial ports together so that data');
    WriteLn('flows from one port to the other (and visa versa).');
    WriteLn;

    repeat
      Key := UpCase(GetKey('Enter first serial port (1-4): '));
      if Key = EscapeKey then Exit;
    until (Key = '1') or (Key = '2') or (Key = '3') or (Key = '4');
    WriteLn;

    case Key of
      '1': FirstSerialPort := Serial1;
      '2': FirstSerialPort := Serial2;
      '3': FirstSerialPort := Serial3;
      '4': FirstSerialPort := Serial4;
    else Exit;
    end;

    repeat
      BaudString := UpperCase(GetResponse('Enter baud rate : '));
      if BaudString = '' then Exit;
    until (BaudString = '300') or (BaudString = '1200') or
      (BaudString = '2400') or (BaudString = '4800') or
      (BaudString = '9600');

    WriteLn;
    Val(BaudString, BaudRate, Result);

    repeat
      Key := UpCase(GetKey('Enter number of bits (7 or 8) : '));
      if Key = EscapeKey then Exit;
    until (Key = '7') or (Key = '8');
    WriteLn;

    case Key of
      '7': InitializeSerialPort(FirstSerialPort, BaudRate, 7, EvenParity, 1);
      '8': InitializeSerialPort(FirstSerialPort, BaudRate, 8, NoParity, 1);
    end;

    repeat
      Key := UpCase(GetKey('Enter Second serial port (1-4): '));
      if Key = EscapeKey then Exit;
    until (Key = '1') or (Key = '2') or (Key = '3') or (Key = '4');
    WriteLn;

    case Key of
      '1': SecondSerialPort := Serial1;
      '2': SecondSerialPort := Serial2;
      '3': SecondSerialPort := Serial3;
      '4': SecondSerialPort := Serial4;
    else Exit;
    end;

    repeat
      BaudString := UpperCase(GetResponse('Enter baud rate : '));
      if BaudString = '' then Exit;
    until (BaudString = '300') or (BaudString = '1200') or
      (BaudString = '2400') or (BaudString = '4800') or
      (BaudString = '9600');

    WriteLn;
    Val(BaudString, BaudRate, Result);

    repeat
      Key := UpCase(GetKey('Enter number of bits (7 or 8) : '));
      if Key = EscapeKey then Exit;
    until (Key = '7') or (Key = '8');
    WriteLn;

    case Key of
      '7': InitializeSerialPort(SecondSerialPort, BaudRate, 7, EvenParity, 1);
      '8': InitializeSerialPort(SecondSerialPort, BaudRate, 8, NoParity, 1);
    end;

    WriteLn;
    WriteLn('Press ESCAPE to stop');

    repeat
      if KeyPressed then
        if ReadKey = EscapeKey then
          Halt;

      if CharReady(FirstSerialPort) then
        SendChar(SecondSerialPort, ReadChar(FirstSerialPort));

      if CharReady(SecondSerialPort) then
        SendChar(FirstSerialPort, ReadChar(SecondSerialPort));

    until False;
   }
end;

procedure PacketSimulate;

var
  SerialPort                       : PortType;
  Key                              : Char;
  FreqString, RandomCall, TempString: Str80;
  Frequency                        : REAL;
  Time                             : TimeRecord;

begin
  {  ClrScr;
    WriteLn('Simulate large amounts of packet spots.');
    WriteLn;
    WriteLn('This procedure will generate random packet spots and send them out to the');
    WriteLn('serial port indicated at 4800 baud with 7 bits, even parity, one stop bit.');
    WriteLn;

    repeat
      Key := UpCase(GetKey('Enter  serial port (1-4): '));
      if Key = EscapeKey then Exit;
    until (Key = '1') or (Key = '2') or (Key = '3') or (Key = '4');
    WriteLn;

    case Key of
      '1': SerialPort := Serial1;
      '2': SerialPort := Serial2;
      '3': SerialPort := Serial3;
      '4': SerialPort := Serial4;
    else Exit;
    end;

    InitializeSerialPort(SerialPort, 4800, 7, EvenParity, 1);

    WriteLn('Press ESCAPE key to stop packet spot generation.');

    repeat
      if KeyPressed then
        if ReadKey = EscapeKey then
          Exit;

      case Random(4) of
        0: RandomCall := GetRandomLetter +
          GetRandomNumber +
            GetRandomLetter +
            GetRandomLetter;

        1: RandomCall := GetRandomLetter +
          GetRandomNumber +
            GetRandomLetter +
            GetRandomLetter +
            GetRandomLetter;

        2: RandomCall := GetRandomLetter +
          GetRandomLetter +
            GetRandomNumber +
            GetRandomLetter +
            GetRandomLetter +
            GetRandomLetter;

        3: RandomCall := GetRandomLetter +
          GetRandomLetter +
            GetRandomNumber +
            GetRandomLetter;
      end;

      Frequency := (7000000 + Random(50000) + Random(50000)) / 1000.0;

      case Random(5) of
        0: TempString := 'DX de N6TR: ';
        1: TempString := 'DX de K7RAT: ';
        2: TempString := 'DX de WB6ZVC: ';
        3: TempString := 'DX de WA6TUT: ';
        4: TempString := 'DX de KC7KMC: ';
      end;

      while Length(TempString) < 18 do TempString := TempString + ' ';

      Str(Frequency: 5: 1, FreqString);

      TempString := TempString + FreqString + '  ' + RandomCall;

      case Random(20) of
        0: TempString := TempString + '  QSX 7255.1';
        1: TempString := TempString + '  7247.3';
        2: TempString := TempString + '  203.5';
        3: TempString := TempString + '  Gus in Helsinki';
      end;

      SendString(SerialPort, TempString + CarriageReturn + LineFeed);

      MarkTime(Time);

      repeat until ElaspedSec100(Time) >= 50;

    until False;
   }
end;

procedure FindLogEntriesOnDisk;

var
  StartDate, StartTime, EndDate, EndTime: Str20;
  Drive, DriveType, MaxSector, MaxHead, NumberDrives: Byte;
  Address, MaxCylinder             : Word;
  Buffer                           : array[0..4095] of Byte;

begin
  {  ClrScr;

    TextColor(Yellow);

    WriteLnCenter('RECOVER DELETED QSOS ON DISK');
    TextColor(Cyan);
    WriteLn;

    WriteLn('Okay, you are here because you have some QSOs that you believe are on your ');
    WriteLn('disk somewhere and you would like to recover them.  You are probably stressed');
    WriteLn('out and there is probably a contest going on as well.');
    WriteLn;
    WriteLn('Well, this routine is being written after N6TR just deleted his own personal');
    WriteLn('log with some new countries on 160 meters in it.  So, be assured we are going');
    WriteLn('to do everything we can to find you QSOs.  However, it is going to take some');
    WriteLn('time to search through the disk and do this, so relax and take it easy.');
    WriteLn;
    WriteLn('The first step is for you to tell me the range of dates/times to be looking');
    WriteLn('for.  That way, when I find something that looks like a QSO, I can test it to');
    WriteLn('see if it is part of the log you are missing.');
    WriteLn;
  }
  {
  удалено в исходнике
     StartDate := UpperCase (GetResponse ('Enter the starting date (i.e. 01-Nov-97) : '));
      StartTime := UpperCase (GetResponse ('Enter starting time (i.e. 18:30) : '));
      EndDate   := UpperCase (GetResponse ('Enter the ending date (i.e. 01-Nov-97) : '));
      EndTime   := UpperCase (GetResponse ('Enter ending time (i.e. 18:30) : '));
  }
  {
    Drive := $80;

    WriteLn(GetDriveParameters(Drive,
      DriveType,
      MaxCylinder,
      MaxSector,
      MaxHead,
      NumberDrives));

    WriteLn('DriveType = ', DriveType);
    WriteLn('MaxCylinder = ', MaxCylinder);
    WriteLn('MaxSector = ', MaxSector);
    WriteLn('MaxHead = ', MaxHead);
    WriteLn('NumberDrives = ', NumberDrives);

    WriteHexWord(Seg(Buffer));
    Write(':');
    WriteHexWord(Ofs(Buffer));
    WriteLn;

    WriteLn(ReadSectors(8,
      100,
      1,
      0,
      $80,
      Seg(Buffer),
      Ofs(Buffer)));

    for Address := 0 to 4095 do
      Write(Chr(Buffer[Address]));
     }
end;

procedure SunriseSunset;

var
  Lat, Lon                         : REAL;

begin
  repeat
    Lat := GetReal('Enter Lat (0 to exit) ');
    if Lat = 0 then Exit;
    Lon := GetReal('Enter Lon ');

    WriteLn('Sunrise/Sunset = ', GetSunriseSunsetString(Lat, Lon));
  until False;
end;

procedure StartUpHelp;

begin
  {  ClrScr;
    TextColor(Yellow);
    WriteLnCenter('TR LOG STARTUP HELP SCREEN');
    WriteLn;
    TextColor(Cyan);
    WriteLn('Legal commands include the following (see manual for details) : ');
    WriteLn;
    WriteLn('B64Decode           BandMap             Coax                Debug');
    WriteLn('Distance            FindFile            FootSwitchDebug     Grid');
    WriteLn('Help                HexConvert          HexDump             IOPort');
    WriteLn('HP                  KeyCode             LC                  LoopBack');
    WriteLn('NetDebug            New                 Packet              PacketFile');
    WriteLn('PacketInputFile     Port                PacketSimulate      PassThrough');
    WriteLn('PortToFile          RadioDebug          Read                Rescore');
    WriteLn('Slow                Sun                 TalkDebug           Trace');
    WriteLn('UnixTime            UUDecode            ViewRadioDebug');
    WriteLn;
   }
end;

procedure CoaxLength;

var
  c1, c2, Avg, L1, L2, F1, F2      : REAL;
  n                                : integer;
  Base                             : integer;

begin
  {  ClrScr;

    TextColor(Yellow);
    WriteLnCenter('COAX Length Calculator');
    WriteLn;

    F1 := GetReal('Enter a low impedance frequency in MHz (0 to exit) : ');

    if F1 = 0 then Exit;

    F2 := GetReal('Enter the next highest impedance null in MHz (0 to exit) : ');

    if F2 = 0 then Exit;

    L1 := 300 / F1;
    L2 := 300 / F2;

    N := Round((2 * L2) / (L1 - L2));

    WriteLn('F1 = ', N, ' quarter wavelenths.');

    C1 := (L1 * N) / 4;
    C2 := (L2 * (N + 2)) / 4;

    Avg := (C1 + C2) / 2;

    WriteLn('Length from F1 = ', C1: 4: 2, ' meters.');
    WriteLn('Length from F2 = ', C2: 4: 2, ' meters.');
    WriteLn('Average = ', Avg: 4: 2, ' meters.');

    WriteLn('Length from new equation = ', 150 / (F2 - F1): 4: 2);
    WriteLn('Do not forget to divide by the velocity factor for physical length.');
   }
end;

procedure FreeStartUpScreen;

begin
  {  ClrScr;

    TextColor(Yellow);
    WriteLnCenter('1.06 - Freeware version based on TR Log 6.69');
    WriteLn;
    TextColor(Cyan);

    WriteLn('This free version only supports the following contests: ARRL Field Day, Region');
    WriteLn('One Field Day, Japanese DX (JIDX), New Zealand Field Day, South American WW,');
    WriteLn('the Stew Perry 160, and WRTC 2002.  Other than the contest selection parameters');
    WriteLn('and associated parameters (such as exchange received and multiplier types),');
    WriteLn('this is the same as TR Log version 6.68 - released in June 2002.');
    WriteLn;
    WriteLn('The manual for the program can be downloaded from http://www.qth.com/tr.');
    WriteLn;
    WriteLn('We hope that after using this program in one of these contests, you will want');
    WriteLn('to purchase the commercial version of the program, which supports over 50');
    WriteLn('different contests.  Also, since TR Log is constantly being enhanced, there');
    WriteLn('will be many new features as well.  You can order the program on the web at');
    WriteLn('http:\\www.qth.com\tr or from one of the following distributors:');
    WriteLn;
    WriteLn('NA/SA: George Fremin III; 624 Lost Oak Trail, Johnson City, TX  78636');
    WriteLn('       Tel: (830) 868-2510; FAX: (512) 732-7099 e-mail: geoiii@kkn.net');
    WriteLn('   EU: Jon Silvergran; Box 178; SE-83122 OSTERSUND Sweden infor@jonit.com');
    WriteLn('   JA: Tack Kumagai; PO Box 22 Mitaka; Tokyo 181, Japan je1cka@nal.go.jp');
    WriteLn('VK/ZL: John McRae; 13 Francis St; Kapunda; So. Australia 5373');
    WriteLn('       e-mail: vkspojfm@dove.net.au');

    while KeyPressed do ReadKey;
    WaitForKeyPressed;
   }
end;

procedure PacketMess;

var
  Password                         : Str40;

begin
  {  ClearScreenAndTitle('Welcome to Packet Mess');

    WriteLn('This is a demonstration only.');

    Password := GetResponse('Enter password : ');

    if Length(Password) <> 4 then Exit;

    if Password[1] <> 'K' then Exit;
    if Password[2] <> '1' then Exit;
    if Password[3] <> 'Z' then Exit;
    if Password[4] <> 'M' then Exit;

    WriteLn('Packet Mess Enabled.  May God have mercy on your soul.');

    WaitForKeyPressed;

    PacketMessMode := True;
   }
end;

procedure KeyCode;

var
  TempKey                          : Char;

begin
  {  ClearScreenAndTitle('KEY CODE');

    WriteLn('Reads the key codes for keys you press.  Escape will exit.');

    repeat
      repeat until KeyPressed;
      TempKey := ReadKey;

      if TempKey = EscapeKey then Break;

      if TempKey = NullKey then
      begin
        TempKey := ReadKey;
        Write('00 ', Ord(TempKey), '   Hex = 00 ');
        WriteHexWord(Ord(TempKey));
        TempKey := Chr(Port[$60]);
        Write('  Port $60 = ');
        WriteHexWord(Ord(TempKey));
        WriteLn;
      end
      else
      begin
        Write(Ord(TempKey), '   Hex = ');
        WriteHexWord(Ord(TempKey));
        TempKey := Chr(Port[$60]);
        Write('  Port $60 = ');
        WriteHexWord(Ord(TempKey));
        WriteLn;
      end;

    until False;
   }
end;

begin
end.
