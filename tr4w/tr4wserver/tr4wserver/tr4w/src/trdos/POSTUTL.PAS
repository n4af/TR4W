unit PostUtl;

{$O+}
{$F+}

interface

uses                                    //Crt,
  Tree,
     //SlowTree,
  PostSubs,
  Country9,
  LogDupe,
  ZoneCont,
  LogName,
  LogGrid,
  LogWind,
  LogSCP,
  PostSCP,
  Dialogs,
  PostUnit,
  SysUtils,
  Windows,
  Forms;

function UtilityMenu: boolean;
procedure AppendProcedure;
procedure CountryCheck;
procedure DateTimeChange;
procedure TestEveryCall;
procedure GlobalLogSearch;
procedure GetBeamHeadings;
procedure MergeCabrilloLogs;
procedure NameEditor;
procedure ShowRestartDotBin;

implementation

var
  DaysPerMonth                : array[1..12] of SHORTINT =
    (031, 028, 031, 030, 031, 030, 031, 031, 030, 031, 030, 031);

const
  BufferSize                  = 300;
  CallBufferSize              = 1000;

  DaysPerYear                 : array[1..12] of integer =
    (031, 059, 090, 120, 151, 181, 212, 243, 273, 304, 334, 365);

  DaysPerLeapYear             : array[1..12] of integer =
    (031, 060, 091, 121, 152, 182, 213, 244, 274, 305, 335, 366);

  SecsPerYear                 : LONGINT = 31536000;
  SecsPerLeapYear             : LONGINT = 31622400;
  SecsPerDay                  : LONGINT = 86400;
  SecsPerHour                 : integer = 3600;
  SecsPerMinute               : integer = 60;

type
  FileBuffer = array[0..BufferSize] of Str160;
  FileBufferPointer = ^FileBuffer;

  CallBuffer = array[0..CallbufferSize] of CallString;
  CallBufferPointer = ^CallBuffer;

  SCPArray = array[0..36, 0..36] of LONGINT;
  SCPArrayPtr = ^SCPArray;

  CabrilloRecPtr = ^CabrilloRec;

  CabrilloRec = record
    CabrilloString: string[100];
    Time: LONGINT;
    LogsFound: Word;                    { Bits 0 - 11 true/false }
    PreviousRecord: CabrilloRecPtr;
    NextRecord: CabrilloRecPtr;
  end;

var
  Buffer                      : FileBufferPointer;
  CheckCallBuffer             : CallBufferPointer;
  SCPIndexMatrix              : SCPArrayPtr;

  CabrilloEntryHead, ActiveCabrilloEntry: CabrilloRecPtr;

{ UTILITY Programs }

function BadName(Name: Str80): boolean;

var
  CharPointer                 : integer;

begin
  BadName := true;
  if Name = '' then
    Exit;

  if length(Name) < 2 then
    begin
      WriteLn('That name is really short!!');
      Exit;
    end;

  if (length(Name) > 6) then
    begin
      WriteLn('That name is too long!!' {, Beep});
      Exit;
    end;

  for CharPointer := 1 to length(Name) do
    if Name[CharPointer] < 'A' then
      begin
        WriteLn('That name has a funny character!!' {, Beep});
        Exit;
      end;

  BadName := False;
end;

function BadCall(Call: Str80): boolean;

var
  CharPointer                 : integer;

begin
  BadCall := true;
  if Call = '' then
    Exit;
  if length(Call) < 2 then
    begin
      WriteLn('That call is too short!!' {, Beep});
      Exit;
    end;

  if length(Call) > 6 then
    begin
      WriteLn('That call is too long!!' {, Beep});
      Exit;
    end;

  BadCall := False;

  for CharPointer := 1 to length(Call) do
    if (Call[CharPointer] >= '0') and (Call[CharPointer] <= '9') then
      Exit;

  WriteLn('That call does not have a number!!' {, Beep});
  BadCall := true;
end;

procedure ShowNameEditCommands;

begin
    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('NAME EDITOR PROGRAM');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This editor allows you to access your NAMES.CMQ database.  This name database');
  WriteLn('is no longer used by the TR program.  Instead, the names are stored in the ');
  WriteLn('TRMASTER.DTA file.  You can move the names in your NAMES.CMQ database to the');
  WriteLn('new database.  To do this, save the data in an ASCII file with the F command.');
  WriteLn('Then import the data into the TRMASTER.DTA file using the DTA database editor''s');
  WriteLn('file import menu (accessed with the commands POST U E F N).');
  WriteLn;
  WriteLn('Single letter commands: C - Toggle CW sending of names.');
  WriteLn('                        D - Delete a call from the database.');
  WriteLn('                        F - Make ASCII file with calls and names.');
  WriteLn('                        G - Delete calls from a file.');
  WriteLn('                        I - Input ASCII file with calls and names.');
  WriteLn('                        P - Make possible call list for a call.');
  WriteLn('                        X - Quit editing and save changes.');
  WriteLn;

end;

procedure AddHeadingToOutputFile(Call: Str20;
  Heading: Str20;
  var FileWrite: Text);

begin
  if Call = '' then
    Exit;
  if Heading = '' then
    Exit;

  if Call = '3Y/B' then
    Exit;
  if Call = '3Y/P' then
    Exit;
  if Call = 'CE0/JF' then
    Exit;
  if Call = 'CE0/SF' then
    Exit;
  if Call = 'HK0/M' then
    Exit;
  if Call = 'JD/O' then
    Exit;
  if Call = 'KC6/W' then
    Exit;
  if Call = 'LU4FM' then
    Exit;
  if Call = 'SV/A' then
    Exit;
  if Call = 'VE1/SA' then
    Exit;
  if Call = 'VE1/SP' then
    Exit;
  if Call = 'VE1' then
    Exit;
  if Call = 'VE2' then
    Exit;
  if Call = 'VE3' then
    Exit;
  if Call = 'VE4' then
    Exit;
  if Call = 'VE5' then
    Exit;
  if Call = 'VE6' then
    Exit;
  if Call = 'VE7' then
    Exit;
  if Call = 'VE8' then
    Exit;
  if Call = 'VP8/G' then
    Exit;
  if Call = 'VP8/O' then
    Exit;
  if Call = 'VP8/SA' then
    Exit;
  if Call = 'VP8/SH' then
    Exit;
  if Call = 'VK9/W' then
    Exit;
  if Call = 'VU/A' then
    Exit;
  if Call = 'VU/L' then
    Exit;
  if Call = 'VU7/L' then
    Exit;
  if Call = 'VU7/A' then
    Exit;

  if Call = 'W0' then
    Exit;
  if Call = 'W1' then
    Exit;
  if Call = 'W2' then
    Exit;
  if Call = 'W3' then
    Exit;
  if Call = 'W4' then
    Exit;
  if Call = 'W5' then
    Exit;
  if Call = 'W6' then
    Exit;
  if Call = 'W7' then
    Exit;
  if Call = 'W8' then
    Exit;
  if Call = 'W9' then
    Exit;
  if Call = 'ZK1/S' then
    Exit;
  if Call = '' then
    Exit;
  if Call = '' then
    Exit;
  if Call = '' then
    Exit;
  if Call = '' then
    Exit;
  if Call = '' then
    Exit;
  if Call = '' then
    Exit;
  if Call = '' then
    Exit;
  if Call = '' then
    Exit;

  if Call = '3Y/B' then
    Call := '3Y';
  if Call = '4J' then
    Call := '4J1FS';
  if Call = 'CT' then
    Call := 'CT1';
  if Call = 'EA' then
    Call := 'EA1';
  if Call = 'F' then
    Call := 'F1';
  if Call = 'G' then
    Call := 'G3';
  if Call = 'KC6/E' then
    Call := 'KC6XX';
  if Call = 'HK0/S' then
    Call := 'HK0';
  if Call = 'JD/MT' then
    Call := 'JD1';
  if Call = 'PJ' then
    Call := 'PJ7';
  if Call = 'PJ/SM' then
    Call := 'PJ4';
  if Call = 'UA1/FJ' then
    Call := '4K2';
  if Call = 'UP' then
    Call := 'LY';
  if Call = 'UR' then
    Call := 'ES';
  if Call = 'UQ' then
    Call := 'YL';
  if Call = 'VK9/C' then
    Call := 'VK9Y';
  if Call = 'VK9/M' then
    Call := 'VK9Z';
  if Call = 'VK0/M' then
    Call := 'VK0';
  if Call = 'VP8/F' then
    Call := 'VP8';
  if Call = 'VU' then
    Call := 'VU2';
  if Call = 'W' then
    Call := 'W';
  if Call = 'XE' then
    Call := 'XE1';
  if Call = 'ZK1/N' then
    Call := 'ZK1';
  if Call = 'ZL' then
    Call := 'ZL2';
  if Call = 'ZS3' then
    Call := 'V5';

  if CountryTable.GetCountry(Call, true) = -1 then
    ShowMessage('Unknown country found for ' + Call)
  else
    WriteLn(FileWrite, Call, ' = ', Heading, DegreeSymbol);
end;

function NumberFileQSOs(FileName: Str80): LONGINT;

var
  FileRead                    : Text;

begin
  NumberFileQSOs := 0;

  if FileExists(FileName) then
    NumberFileQSOs := GetFileSize_TR(FileName) div 84;
end;

procedure AppendProcedure;

var
  SourceFileName, DestFileName: Str80;
  NumberLinesRead, Line       : integer;
  FileRead, FileWrite         : Text;
  Key                         : Char;
  ts                          : string;
begin
    //ClrScr;
    //TextColor (Yellow);
{  WriteLnCenter('APPEND PROGRAM');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This program will append a file to another existing file.  It is intended to');
  WriteLn('be used to append a log file to a history file.');
  WriteLn;

  SourceFileName := GetResponse('Enter source file name : ');
  if SourceFileName = '' then exit;

  WriteLn('Source file has about ', NumberFileQSOs(SourceFileName), ' QSOs in it.');

  DestFileName := GetResponse('Enter file to add ' + SourceFileName + ' to : ');
  if DestFileName = '' then exit;

  WriteLn('Destination file has about ', NumberFileQSOs(DestFileName), ' QSOs in it.');
}
  SourceFileName := postform.SourceEdit.Text;
  DestFileName := postform.DestEdit.Text;

  if SourceFileName = '' then
    Exit;
  if DestFileName = '' then
    Exit;

  if SourceFileName = DestFileName then
    begin
      ShowMessage('You cannot copy a file onto itself!!');
      Exit;
    end;

  if not OpenFileForRead(FileRead, SourceFileName) then
    begin
      ShowMessage(SourceFileName + ' does not exist!!');
      Exit;
    end;

  if not OpenFileForAppend(FileWrite, DestFileName) then
    begin
      ShowMessage('Error trying to open ' + DestFileName);
      Exit;
    end;

  New(Buffer);

  repeat
    NumberLinesRead := 0;

    while (not Eof(FileRead)) and (NumberLinesRead < BufferSize) do
      begin
        ReadLn(FileRead, Buffer^[NumberLinesRead]);
        inc(NumberLinesRead);
      end;

    if NumberLinesRead > 0 then
      for Line := 0 to NumberLinesRead - 1 do
        WriteLn(FileWrite, Buffer^[Line]);

    if Eof(FileRead) then
      begin
        Close(FileRead);
        Close(FileWrite);
        Dispose(Buffer);
        ShowMessage(SourceFileName + ' has been successfully added to ' + #13 + DestFileName + '.' + #13 + #13 + #13 + DestFileName + ' now has about ' + inttostr(NumberFileQSOs(DestFileName)) + ' QSOs in it.');

        ts := 'Do you wish to delete ' + SourceFileName + '?';
        if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDYES then
          begin
            Tree.DeleteFile(SourceFileName);
            ShowMessage(SourceFileName + ' has been deleted.');
          end;
        view(DestFileName);
        Exit;
      end;

  until False;
end;

procedure CountryCheck;

var
  QTH                         : QTHRecord;
  ID, Call                    : CallString;

begin
{    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('COUNTRY AND ZONE CHECK UTILITY');
  WriteLn;
    //TextColor (Cyan);
  WriteLn('This utility will allow you to enter a callsign and view the pre-programmed ');
  WriteLn('information.  This will show you the ARRL country, CQ county, continent, CQ');
  WriteLn('zone and ITU zone.');
  WriteLn;

  repeat
   }Call := POSTFORM.CallEdit.Text;
//  if Call = '' then Exit;

//    Write('Callsign = ', Call);

  CountryTable.ZoneMode := ITUZoneMode;

  LocateCall(Call, QTH, true);

  if QTH.StandardCall <> Call then
    POSTFORM.SFCLab.Caption := {Write('    Standard format callsign = ',} QTH.StandardCall;

  CountryTable.CountryMode := ARRLCountryMode;
  POSTFORM.ARRLlAB.Caption := ('ARRL Country = ' + CountryTable.GetCountryName(CountryTable.GetCountry(Call, true)));

  CountryTable.CountryMode := CQCountryMode;
  POSTFORM.CQLab.Caption := ('CQ Country = ' + CountryTable.GetCountryName(CountryTable.GetCountry(Call, true)));

  POSTFORM.CONTLab.Caption := ('Continent = ' + CountryTable.GetContinentName(QTH.Continent));
  POSTFORM.CQZLab.Caption := ('CQ Zone = ' + inttostr(CountryTable.GetCQZone(Call)) + '    ITU Zone = ' + inttostr(CountryTable.GetITUZone(Call)));

  POSTFORM.BEAMLab.Caption := ('Grid square for beam heading purposes = ' + CountryTable.GetGrid(Call, ID));
  POSTFORM.IDLab.Caption := ('The country ID for this country is = ' + ID);

//  until False;
end;

function CallHasNoNumber(Call: CallString): boolean;

var
  CharPointer                 : integer;

begin
  if Call = '' then
    begin
      CallHasNoNumber := true;
      Exit;
    end;

  CallHasNoNumber := False;

  for CharPointer := 1 to length(Call) do
    if ((Call[CharPointer] >= '0') and (Call[CharPointer] <= '9')) then
      Exit;

  CallHasNoNumber := true;
end;

procedure GlobalLogSearch;

var
  FileString, Callsign, CallListFileName, LogFileName, OutputFileName: Str80;
  CallListRead, OutputFileWrite, LogFileRead: Text;
  CallAddress, NumberCallsLeft, NumberCallsMatched, NumberCallsInBuffer: integer;

begin
  NumberCallsLeft := 0;
{
    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('GLOBAL LOG SEARCH');
  WriteLn;
    //TextColor (Cyan);
  WriteLn('This procedure take a list of callsigns and a list of filenames and see if');
  WriteLn('each callsign appears in at least one of the files.  If it does, it will');
  WriteLn('be removed from the list.');
  WriteLn;
  WriteLn('This procedure was initially intended to be used as a way to remove names');
  WriteLn('from the database that are not in your recent logs.  To use it this was,');
  WriteLn('use the F command in the name editor to make an ASCII list of calls and');
  WriteLn('names.  Execute this procedure on all the files you want to look through,');
  WriteLn('then delete the remaining calls using the G command in the name editor.');
  WriteLn;
 }
  CallListFileName := postform.CCFNE.Text;
  if (CallListFileName = '') or (not FileExists(CallListFileName)) then
    Exit;

  LogFileName := postform.CAFNE.Text;
  if (LogFileName = '') or (not FileExists(CallListFileName)) then
    Exit;

  OutputFileName := postform.NFFNE.Text;
  if OutputFileName = '' then
    Exit;

  if CallListFileName = OutputFileName then
    Exit;

  if not OpenFileForRead(CallListRead, CallListfileName) then
    Exit;
  if not OpenFileForWrite(OutputFileWrite, OutputFileName) then
    Exit;

  New(CheckCallBuffer);
  NumberCallsInBuffer := 0;
  NumberCallsMatched := 0;

  while not Eof(CallListRead) do
    begin

      while not Eof(CallListRead) and (NumberCallsInBuffer < CallBufferSize) do
        begin
          ReadLn(CallLIstRead, FileString);

          Callsign := UpperCase(GetFirstString(FileString));

          if Callsign <> '' then
            begin
              CheckCallBuffer^[NumberCallsInBuffer] := Callsign;
              inc(NumberCallsInBuffer);
            end;
        end;

      if NumberCallsInBuffer > 0 then
        begin
          if OpenFileForRead(LogFileRead, LogFileName) then
            begin

              while not Eof(LogFileRead) do
                begin
{                    IF KeyPressed AND (ReadKey = EscapeKey) THEN
          begin
            Close(LogFileRead);
            Close(CallListRead);
            Close(OutputFileWrite);
            WriteLn;
            WriteLn('Procedure aborted.  However, ', OutputFileName, ' is still valid.');
            WriteLn;
            Exit;
            Dispose(CheckCallBuffer);
          end;
}
                  ReadLn(LogFileRead, FileString);

                  FileString := UpperCase(FileString);

                  for CallAddress := 0 to NumberCallsInBuffer - 1 do
                    if CheckCallBuffer^[CallAddress] <> '' then
                      if pos(CheckCallBuffer^[CallAddress], FileString) > 0 then
                        begin
                          inc(NumberCallsMatched);
//                postform.cm.Lines.Add(NumberCallsMatched, ' ', CheckCallBuffer^[CallAddress], ' found in log!!');
                          CheckCallBuffer^[CallAddress] := '';
                          Break;
                        end;

                end;

              Close(LogFileRead);
            end;

          for CallAddress := 0 to NumberCallsInBuffer - 1 do
            if CheckCallBuffer^[CallAddress] <> '' then
              begin
                inc(NumberCallsLeft);
                WriteLn(OutputFileWrite, CheckCallBuffer^[CallAddress]);
//          postform.cm.Lines.Add(inttostr(NumberCallsLeft)+ ' '+ CheckCallBuffer^[CallAddress]+ ' not found in log.  Saved to '+            OutputFileName);
              end;

        end;

      NumberCallsInBuffer := 0;
    end;

  Close(CallListRead);
  Close(OutputFileWrite);
  Dispose(CheckCallBuffer);
//  WriteLn;
  postform.cm.Lines.Add('There were ' + inttostr(NumberCallsMatched) + ' calls found in the log.');
  postform.cm.Lines.Add('There were ' + inttostr(NumberCallsLeft) + ' calls written to ' + OutputFileName);
  view(OutputFilename);
end;

procedure NameEditor;

var
  FileName, Name, TotalString, Call: Str80;
  NumberTimes, NameCode, NamePointer, Offset, CallPointer: integer;
  CWSend                      : boolean;
  StartOfCallEntered          : integer;
  FileRead                    : Text;

  LastPrefix                  : Str20;
  TempBytes                   : fourBYTEs;
  FileString                  : Str20;

begin
    //GoToXY (1, WhereY);
    //ClrEol;
    //TextColor (Cyan);
//  Write('Loading name file.  Please wait...');

  if not Names.Load then
    begin

      ShowMessage('WARNING!! No NAMES.CMQ file found.  You are starting at zero.');
    end;

  LastPrefix := '';

  ShowNameEditCommands;
  CWSend := true;

  repeat
    Str(Names.TotalNumberOfCalls, TotalString);
        //GoToXY (1, WhereY);
        //ClrEol;

        //TextColor (Cyan);

    Write('Enter call to edit (' + TotalString + ') : ');

        //wli
    StartOfCallEntered := 1;

    ReadLn(Call);
    Call := UpperCase(Call);

    if length(Call) = 1 then
      begin
        case Call[1] of
          'C': CWSend := not CWSend;
          'D':
            begin
                     //GoToXY (40, WhereY - 1);
              Call := UpperCase(GetResponse('Callsign to delete : '));
              if Call <> '' then
                Names.DeleteName(Call);
            end;

          'F':
            begin
                     //GoToXY (40, WhereY -1);
              FileName := UpperCase(GetResponse('Filename for list : '));
              if FileName <> '' then
                Names.MakeASCIIList(FileName);
            end;

          'G':
            begin
                     //GoToXY (40, WhereY - 1);
              FileName := UpperCase(GetResponse('File to delete calls of : '));

              if FileName <> '' then
                if OpenFileForRead(FileRead, FileName) then
                  begin
                    while not Eof(FileRead) do
                      begin
                        ReadLn(FileRead, FileString);
                        Names.DeleteName(FileString);
                        WriteLn('Deleting ', FileString);
                      end;

                    Close(FileRead);
                  end;
            end;

          'I': Names.InputASCIIFile;

          'X':
            begin
              Names.Save;
                     //WaitForKeyPressed;
              Exit;
            end;

        else
          ShowNameEditCommands;

        end;                            { of single letter command case }
      end

    else
      begin
        if ((length(Call) = 2) or (length(Call) = 3)) and CallHasNoNumber(Call) then
          begin
            Call := LastPrefix + Call;
                //GoToXY (StartOfCallEntered, WhereY - 1);
            Write(Call);
                //GoToXY (40, WhereY);
          end
        else
                //GoToXY (40, WhereY - 1);

          LastPrefix := GetPrefix(Call);

        if not BadCall(Call) then
          begin
            if Names.GetName(Call) = '' then
              begin
                Name := UpperCase(GetResponse('Name = '));
                if Name = '' then
                  begin
                        //GoToXY (1, WhereY - 1);
                        //ClrEol;
                  end
                else
                  if not BadName(Name) then
                    if Name <> '' then
                      Names.AddName(Call, Name);
              end
            else
              begin
                    //TextColor (Cyan);
                Write('Name = ');
                    //TextColor (Red);
                Name := Names.GetName(Call);
                WriteLn(Name);
//                    IF CWSend THEN SendMorse (Name);
              end;
          end;
      end;
  until False;
end;

procedure ShowRestartDotBin;

var
  FileWrite                   : Text;
  Block, NumberCalls, NumberEntriesInLastBlock, NumberBlocks: integer;
  BlockAddress, CharPointer, EndAddress, Address: integer;

  Band                        : BandType;
  Mode                        : ModeType;
  Callsign                    : Str20;
  TempString                  : string;
  CompressedCall              : fourBYTEs;
  StartMode, EndMode          : ModeType;
  StartBand, EndBand          : BandType;

begin
{    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('GENERATE REPORT OF RESTART.BIN FILE');
  WriteLn;
    //TextColor (Cyan);
  WriteLn('This procedure will generate a file with all of the information contained in');
  WriteLn('the restart bin file.  This includes the QSO totals, dupesheets, exchange');
  WriteLn('memory (if any) and partial call lists.  The output is saved in a file called');
  WriteLn('RESTART.DAT');
  WriteLn;
}

  if ExTRACTFileName(LogFileName) = 'LOG.DAT' then
 //wli   LogRestartFileName := 'LOGCFG.DAT'
    LogRestartFileName := ExpandFileName(LogFileName) + '\RESTART.BIN'
  else
    LogRestartFileName := PrecedingString(LogFileName, '.') + '.RST';

  if not FileExists(LogRestartFileName) then
    begin
      ShowMessage(LogRestartFileName + ' not found in this directory!!');
        //WaitForKeyPressed;
      Exit;
    end;

  ContestName := '';

//  WriteLn('Loading in ', LogRestartFileName);

  if not Sheet.ReadInBinFiles(true) then
    begin
        //WaitForKeyPressed;
      Exit;
    end;

    //GoToXY (1, WhereY);
    //ClrEol;
//  Write('Saving output to RESTART.DAT...');

  OpenFileForWrite(FileWrite, 'RESTART.DAT');

  WriteLn(FileWrite, 'RESTART.BIN file contents.');
  WriteLn(FileWrite);
  WriteLn(FileWrite, 'Format version = ', RestartVersionNumber);
  WriteLn(FileWrite);
  WriteLn(FileWrite, 'Contest name = ', ContestName);
  WriteLn(FileWrite);

  WriteLn(FileWrite, 'DupeSheet totals : ');

  for Band := Band160 to All do
    for Mode := cw to Both do
      WriteLn(FileWrite, BandString[Band], ModeString[Mode], Sheet.DupeSheet.Totals[Band, Mode]: 8);

  WriteLn(FileWrite);

  WriteLn(FileWrite, 'Number of big calls (> 6 characters) = ', Sheet.DupeSheet.NumberBigCalls);
  WriteLn(FileWrite);

  WriteLn(FileWrite, 'QSO totals (includes dupes) : ');

  for Band := Band160 to All do
    for Mode := cw to Both do
      WriteLn(FileWrite, BandString[Band], ModeString[Mode], QSOTotals[Band, Mode]: 8);

  WriteLn(FileWrite);

  WriteLn(FileWrite, 'Total names sent = ', TotalNamesSent);
  WriteLn(FileWrite);

  WriteLn(FileWrite, 'Total QSO points = ', TotalQSOPoints);
  WriteLn(FileWrite);

  WriteLn(FileWrite, 'Code Speed = ', CodeSpeed);
  WriteLn(FileWrite);

  for Band := Band160 to All do
    for Mode := cw to Both do
      if Sheet.DupeSheet.Totals[Band, Mode] > 0 then
        begin
          NumberCalls := Sheet.DupeSheet.Totals[Band, Mode];
          NumberBlocks := (NumberCalls div FourByteBlockSize) + 1;
          NumberEntriesInLastBlock := NumberCalls mod FourByteBlockSize;

          WriteLn(FileWrite, 'Dupesheet for ', BandString[Band], ModeString[Mode], ' : ');

          Block := 1;

          repeat
            if Block = NumberBlocks then
              EndAddress := NumberEntriesInLastBlock
            else
              EndAddress := FourByteBlockSize;

            for Address := 0 to EndAddress - 1 do
              begin
                Write(FileWrite, (Address) + (Block - 1) * FourByteBlockSize + 1: 5, ' ');

                CompressedCall := Sheet.DupeSheet.DupeList[Band, Mode, Block]^[Address];

                if PointsToBigCall(CompressedCall) then
                  TempString := BigExpandedString(Sheet.DupeSheet.BigCallList[1]^
                    [BigEntryAddress(CompressedCall)])

                else
                  TempString := ExpandedString(CompressedCall);

                GetRidOfPrecedingSpaces(TempString);
                GetRidOfPostcedingSpaces(TempString);

                if length(TempString) > 0 then
                  for CharPointer := 1 to length(TempString) do
                    if TempString[CharPointer] = ' ' then
                      TempString[CharPointer] := '/';

                WriteLn(FileWrite, TempString);
              end;

            inc(Block);
          until Block > NumberBlocks;

          WriteLn(FileWrite);
        end;

  for Band := Band160 to All do
    for Mode := cw to Both do
      if (((MultByBand) and (Band <> All)) or
        ((not MultByBand) and (Band = All))) and
        (((MultByMode) and (Mode <> Both)) or
        ((not MultByMode) and (Mode = Both))) then
        with Sheet.Multsheet do
          begin
            if Totals[Band, Mode].NumberDomesticMults > 0 then
              begin
                WriteLn(FileWrite, 'Domestic mult list for ', BandString[Band], ModeString[Mode], ' : ');

                for Address := 0 to Totals[Band, Mode].NumberDomesticMults - 1 do
                  WriteLn(FileWrite, Address + 1: 5, ' ',
                    ExpandedString(DomesticList[Band, Mode]^[Address]));
                WriteLn(FileWrite);
              end;

            if Totals[Band, Mode].NumberDXMults > 0 then
              begin

                WriteLn(FileWrite, 'DX mult list for ', BandString[Band], ModeString[Mode], ' : ');

                for Address := 0 to Totals[Band, Mode].NumberDXMults - 1 do
                  WriteLn(FileWrite, Address + 1: 5, ' ',
                    ExpandedString(DXList[Band, Mode]^[Address]));
                WriteLn(FileWrite);
              end;

            if Totals[Band, Mode].NumberPrefixMults > 0 then
              begin

                WriteLn(FileWrite, 'Prefix mult list for ', BandString[Band], ModeString[Mode], ' : ');

                for Address := 0 to Totals[Band, Mode].NumberPrefixMults - 1 do
                  WriteLn(FileWrite, Address + 1: 5, ' ',
                    ExpandedString(PrefixList[Band, Mode]^[Address]));
                WriteLn(FileWrite);
              end;

            if Totals[Band, Mode].NumberZoneMults > 0 then
              begin

                WriteLn(FileWrite, 'Zone mult list for ', BandString[Band], ModeString[Mode], ' : ');

                for Address := 0 to Totals[Band, Mode].NumberZoneMults - 1 do
                  WriteLn(FileWrite, Address + 1: 5, ' ',
                    ExpandedString(ZoneList[Band, Mode]^[Address]));
                WriteLn(FileWrite);
              end;
          end;

  WriteLn(FileWrite, 'Number of calls in partial call list = ', NumberPartialCalls);
  WriteLn(FileWrite, 'Number different initial exchange = ', NumberInitialExchanges);

  ExchangeMemoryEnable := NumberInitialExchanges <> 0;

  WriteLn(FileWrite);

  if NumberPartialCalls > 0 then
    begin
      Block := 1;
      BlockAddress := 0;

      WriteLn(FileWrite, 'Partial call list with initial exchanges (if any) : ');

      for Address := 0 to NumberPartialCalls - 1 do
        begin
          Callsign := ExpandedString(PartialCallList[Block]^[BlockAddress].Call);

          WriteLn(FileWrite, Address + 1: 5, Callsign: 12, GetInitialExchange(Callsign): 12);

          inc(BlockAddress);

          if BlockAddress = FourByteBlockSize then
            begin
              BlockAddress := 0;
              inc(Block);
            end;

        end;
    end;

  WriteLn(FileWrite);

  if NumberLongPartialCalls > 0 then
    begin
      WriteLn(FileWrite, 'Long partial call list with initial exchanges (if any) : ');

      for Address := 0 to NumberLongPartialCalls - 1 do
        begin
          Callsign := BigExpandedString(LongPartialCallList^[Address]);
          WriteLn(FileWrite, Address + 1: 5, Callsign: 14, GetInitialExchange(Callsign): 12);
          inc(BlockAddress);
        end;
    end;

  Close(FileWrite);
  Sheet.DisposeOfMemoryAndZeroTotals;
  view('RESTART.DAT');
end;

procedure IncrementCall(var Call: CallString);

begin
  if Call[length(Call)] = '9' then
    Call[length(Call)] := 'A'
  else
    if Call[length(Call)] = 'Z' then
      begin
        Delete(Call, length(Call), 1);

        if Call <> '' then
          IncrementCall(Call);

        Call := Call + '0';
      end
    else
      Call[length(Call)] := CHR(Ord(Call[length(Call)]) + 1);

end;

procedure TestEveryCall;

var
  Key                         : Char;
  Partial                     : Str40;
  Call                        : CallString;
  t                           : integer;
begin

  stop_partial := False;
{  repeat
    Key := UpCase(GetKey('Do you want to test every possible prefix (Y/N) : '));
    if (Key = EscapeKey) or (Key = 'N') then Exit;
  until (Key = 'Y');
  WriteLn;
}
    { Save current databse to ASCII file }
  postform.TestM.Clear;
  Call := '000';
  t := -1;
  repeat
        //TextColor (Yellow);

//    Write(Call, ' = ');

        //TextColor (Cyan);

    CD.PartialCallSetup(Call);

    repeat
      Partial := CD.GetNextPartialCall;

      if Partial <> '' then
        begin
//                IF WhereX + Length (Partial) + 2 >= 80 THEN WriteLn;
//                IF WhereX > 1 THEN Write (' ');
//        Write(Partial);
          application.ProcessMessages;
          if stop_partial = true then Break;
          postform.TestM.Lines.Add(Call + ' = ' + Partial);
          inc(t);
          postform.TotT.Caption := inttostr(t);
        end;

//            IF KeyPressed THEN
      begin
//                Key := ReadKey;

        if Key = EscapeKey then
          Exit;
      end;

    until Partial = '';

//    WriteLn;

    IncrementCall(Call);

  until Call = '000';
end;

procedure DTAEditor;

var
  Key                         : Char;
  data                        : DataBaseEntryRecord;
  PCall, Call                 : CallString;
  FileName                    : Str40;
  Address                     : integer;

begin
  repeat
        //ClrScr;
        //TextColor (Yellow);
    WriteLnCenter('CALL DATABASE UTILITY MENU');
    WriteLn;
        //TextColor (Cyan);

    WriteLn('This menu contains all the commands that are needed to maintain your callsign');
    WriteLn('database file (TRMASTER.DTA).  This database file is used for storing known');
    WriteLn('good calls for partial call lookups and various pieces of data that are ');
    WriteLn('associated to the calls (ie: name, QTH, grid, etc).');
    WriteLn;
    WriteLn('  A - Convert the TRMASTER.DTA file to an ASCII File (TRMASTER.ASC).');
    WriteLn('  B - Build TRMASTER.DTA file from TRMASTER.ASC');
    WriteLn('  C - Clear out one of the TRMASTER data fields.');
    WriteLn('  D - Delete entries in the database below hit threshold.');
    WriteLn('  E - Edit data for specific callsigns in database.');
    WriteLn('  F - Add data to TRMASTER database from various type of files.');
    WriteLn('  G - Save calls and names to an ASCII file.');
    WriteLn('  N - Name editor (similar to the old NAMES.CMQ name editor).');
    WriteLn('  P - Partial calls test - pull partial calls out of databse.');
    WriteLn('  R - Get random call (used by simulator).');
    WriteLn('  S - Sort .DTA file so calls are in alphabetical order.');
    WriteLn('  T - Continually fetch random callsigns until a key is pressed.');
    WriteLn('  U - Get Unique+1 (possible) calls for a specific call.');
    WriteLn('  X - Exit menu.');
    WriteLn('  Y - Test every call in the database.');
    WriteLn('  Z - Show database statistics.');
    WriteLn;

    Key := UpCase(GetKey('Enter command : '));

        //ClrScr;

    case Key of
      'A': CD.SaveToASCIIFile;
      'B': CD.BuildNewDatabasefromASCIIfile(CHR(0));

      'C': CD.ClearField;

      'D': CD.DeleteLowHitCalls;

      'E': CD.ASCIIFileEditor;

      'F': AddFileToDatabase;

      'G':
        begin
          FileName := GetResponse('Enter filename to save calls and names to : ');
          if FileName <> '' then
            CD.SaveCallsAndNamesToFile(FileName);
        end;

      'N': TRMasterNameEditor;

      'P': while true do
          begin
            Call := UpperCase(GetResponse('Enter partial call to test : '));

            if Call = '' then
              Break;

            CD.PartialCallSetup(Call);

            repeat
              Call := CD.GetNextPartialCall;

              if Call <> '' then
                begin
{                             IF WhereX + Length (Call) < 79 THEN
                                 BEGIN
                                 IF WhereX > 1 THEN Write (' ');
                                 Write (Call);
                                 END
                             ELSE
                                 BEGIN
                                 WriteLn;
                                 Write (Call);
                                 END;
            }
                end;
            until Call = '';
            WriteLn;
          end;

      'R':
        begin
          WriteLn(CD.GetRandomCall);
                 //WaitForKeyPressed;
        end;

      'S': CD.SortDTAFile;

      'T':
        begin
//                 REPEAT
//                     WriteLn (CD.GetRandomCall)
//                 UNTIL KeyPressed;
//                 WHILE KeyPressed DO ReadKey;
        end;

      'U':
        begin
          CD.PossibleCallAction := AnyCall;

          repeat
            Call := UpperCase(GetResponse('Enter call to get possible calls for : '));

            if Call <> '' then
              begin
                CD.GeneratePossibleCallList(Call);

                if PossibleCallList.NumberPossibleCalls > 0 then
                  for Address := 0 to PossibleCallList.NumberPossibleCalls - 1 do
                    begin
//                                 IF WhereX > 72 THEN WriteLn;
//                                 IF WhereX > 1 THEN Write (' ');
                      Write(PossibleCallList.List[Address].Call);
                    end;
              end
            else
              Break;

            WriteLn;
          until False;
        end;

      'V': repeat
          Call := UpperCase(GetResponse('Enter call to get value of : '));

          if Call = '' then
            Break;

          WriteLn(CallSortValue(Call));
        until False;

      'X', EscapeKey:
        begin
                    //ClrScr;
          Exit;
        end;

      'Y': TestEveryCall;

      'Z': CD.ShowStatistics;
    end;
  until False;
end;

procedure GetBeamHeadings;

var
  Heading, Country            : integer;
  Grid, MyGrid                : Str20;

begin
{    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('GET BEAM HEADINGS');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This procedure will let you enter your grid and then ask for beam headings to');
  WriteLn('other grids.  It will also tell you the distance between them.');
  WriteLn;
}
  MyGrid := postform.HomeGridEdit.Text;

  if not LooksLikeAGrid(MyGrid) then
    begin
      ShowMessage('That does not look like a grid to me!!');
      Exit;
    end;

  Grid := postform.CompGridEdit.Text;

  if Grid = '' then Exit;

  if LooksLikeAGrid(Grid) then
    ShowMessage('Heading = ' + inttostr(round(GetBeamHeading(MyGrid, Grid))) + #13 + 'Distance = ' + inttostr(GetDistanceBetweenGrids(MyGrid, Grid)) + ' km')
  else
    ShowMessage('That does not look like a grid to me!!');

end;

procedure DateTimeChange;

var
  DateString                  : Str40;
  TimeString                  : Str40;
  OutputFileName              : string;
  InputFileName               : string;
  LogString                   : string;
  OutputFile                  : Text;
  InputFile                   : Text;
  Offset                      : integer;

begin
{//    ClearScreenAndTitle ('DATE / TIME CHANGE FOR A LOG');

  WriteLn('This procedure will allow you to change the date and time entries in a log');
  WriteLn('by a fixed number of minutes - either adding or subtracting.  Use a minus');
  WriteLn('minute offset to subtract time.');
  WriteLn;
}
  InputFileName := postform.IFNEdit.Text;
  if InputFileName = '' then
    Exit;

  OutputFileName := postform.OFNEdit.Text;
  if OutputFileName = '' then
    Exit;

  Offset := postform.TOFF.Value;

  if Offset = 0 then
    Exit;

  if not OpenFileForRead(InputFile, InputFileName) then
    begin
      ShowMessage(InputFileName + ' not found!!');
      Exit;
    end;

  OpenFileForWrite(OutputFile, OutputFileName);

  while not Eof(InputFile) do
    begin
      ReadLn(InputFile, LogString);
      ChangeLogStringDateTime(LogString, Offset);
      WriteLn(OutputFile, LogString);
    end;

  Close(OutputFile);
  Close(InputFile);
  view(OutputFileName);
//  WriteLn('All done.');
    //WaitForKeyPressed;
end;

function IsLeapYear(Year: Word): boolean;

begin
  if Year mod 100 = 0 then
    begin
      if (Year mod 400 = 0) then
        IsLeapYear := true
      else
        IsLeapYear := False;

      Exit;
    end;

  IsLeapYear := Year mod 4 = 0;
end;

function GetUnixTimeFromCabrilloEntry(CabrilloString: string): LONGINT;

{ QSO:  1800 CW 2003-12-06 2353 K7RAT         599 OR     W7SE          599 Wy}

var
  DateString, TimeString, YearString, MonthString, DayString: Str20;
  HourString, MinuteString    : Str20;
  Index, Year, Month, Day, Hour, Minute, Result1: Word;
  UnixDate                    : LONGINT;

begin
  RemoveFirstString(CabrilloString);    { QSO: }
  RemoveFirstString(CabrilloString);    { 1800 }
  RemoveFirstString(CabrilloString);    { CW }

  DateString := RemoveFirstString(CabrilloString);
  TimeString := RemoveFirstString(CabrilloString);

  YearString := Copy(DateString, 1, 4);
  MonthString := Copy(DateString, 6, 2);
  DayString := Copy(DateString, 9, 2);

  HourString := Copy(TimeString, 1, 2);
  MinuteString := Copy(TimeString, 3, 2);

  Val(YearString, Year, Result);
  Val(MonthString, Month, Result);
  Val(DayString, Day, Result);
  Val(HourString, Hour, Result);
  Val(MinuteString, Minute, Result);

  UnixDate := 0;                        {initialize}

  inc(UnixDate, SecsPerMinute * Minute); { add minutes}
  inc(UnixDate, SecsPerHour * Hour);    { add hours}

    { add days }

  inc(UnixDate, (SecsPerDay * (Day - 1)));

    { We now have how many seconds have passed so far in the month }

    { Figure out how many hours have passed in this year up to the end
      of the previous day }

  if IsLeapYear(Year) then
    DaysPerMonth[02] := 29
  else
    DaysPerMonth[02] := 28;             {Check for Feb. 29th}

    { Add in seconds for completed months so far }

  Index := 1;

  if Month > 1 then
    for Index := 1 to Month - 1 do      {has one month already passed?}
      inc(UnixDate, (DaysPerMonth[Index] * SecsPerDay));

    { Now do the complete years }

  while Year > 1970 do
    begin
      if IsLeapYear(Year - 1) then
        inc(UnixDate, SecsPerLeapYear)
      else
        inc(UnixDate, SecsPerYear);

      Dec(Year, 1);
    end;

  GetUnixTimeFromCabrilloEntry := UnixDate;
end;

function FileStringsMatch(FStr1, FStr2: string): boolean;

{ Matches all except the last 3 digits of frequency

QSO:  1800 CW 2003-12-06 2348 K7RAT         599 OR     N6RK          599 Sv }

begin
  Delete(FStr1, 8, 3);
  Delete(FStr2, 8, 3);

  FileStringsMatch := FStr1 = FStr2;
end;

procedure AddQSOToLinkedList(FileString: string; QSOTime: LONGINT; LogWorkedValue: Word);

var
  NextCabrilloRecordPtr, PreviousCabrilloRecordPtr: CabrilloRecPtr;

begin
  if CabrilloEntryHead = nil then       { Very first entry }
    begin
      CabrilloEntryHead := New(CabrilloRecPtr);

      CabrilloEntryHead^.CabrilloString := FileString;
      CabrilloEntryHead^.Time := QSOTime;
      CabrilloEntryHead^.LogsFound := LogWorkedValue;
      CabrilloEntryHead^.PreviousRecord := nil;
      CabrilloEntryHead^.NextRecord := nil;

      ActiveCabrilloEntry := CabrilloEntryHead;
      Exit;
    end;

    { Increment the ActiveCabrilloEntry past the time of this QSO, or to
      the last entry in the linked list. }

  while (ActiveCabrilloEntry^.NextRecord <> nil) and (ActiveCabrilloEntry^.Time <= QSOTime) do
    ActiveCabrilloEntry := ActiveCabrilloEntry^.NextRecord;

    { If we are at the last entry, check to see if the time of this QSO is
      after the last entry.  If so, we should add this QSO to the end of
      the linked list. }

  if ActiveCabrilloEntry^.NextRecord = nil then { We are at last entry }
    begin
      if ActiveCabrilloEntry^.Time < QSOTime then { Add new entry at end }
        begin
          PreviousCabrilloRecordPtr := ActiveCabrilloEntry; { Remember }

          ActiveCabrilloEntry^.NextRecord := New(CabrilloRecPtr);

          ActiveCabrilloEntry := ActiveCabrilloEntry^.NextRecord;

          with ActiveCabrilloEntry^ do
            begin
              Time := QSOTime;
              LogsFound := LogWorkedValue;
              CabrilloString := FileString;
              PreviousRecord := PreviousCabrilloRecordPtr;
              NextRecord := nil;
            end;

          Exit;
        end;
    end;

    { We are either at the end of the list with an entry with the same
      time or at an entry where the time is greater than our QSO.  In
      either case, we want to back up until we either match an entry,
      find the time is less than our QSO, or hit the first entry in
      the linked list. }

  while (ActiveCabrilloEntry^.Time >= QSOTime) and (ActiveCabrilloEntry^.PreviousRecord <> nil) do
    begin

        { Check to see if we match up by chance first }

      with ActiveCabrilloEntry^ do
        if (Time = QSOTime) and FileStringsMatch(CabrilloString, FileString) then
          begin
            LogsFound := LogsFound or LogWorkedValue;
            Exit;
          end;

      ActiveCabrilloEntry := ActiveCabrilloEntry^.PreviousRecord;
    end;

    { We have backed up either to a record that has an earlier time, or
      to the very first record in the list.  Let's check to see if it
      matches first }

  with ActiveCabrilloEntry^ do
    if (Time = QSOTime) and FileStringsMatch(CabrilloString, FileString) then
      begin
        LogsFound := LogsFound or LogWorkedValue;
        Exit;
      end;

    { It does not match.  If this QSO matches the time, we can add our new
      QSO to the front of the list }

  if ActiveCabrilloEntry^.Time = QSOTime then
    begin
      CabrilloEntryHead := New(CabrilloRecPtr);

      CabrilloEntryHead^.CabrilloString := FileString;
      CabrilloEntryHead^.Time := QSOTime;
      CabrilloEntryHead^.LogsFound := LogWorkedValue;
      CabrilloEntryHead^.PreviousRecord := nil;
      CabrilloEntryHead^.NextRecord := ActiveCabrilloEntry;
      Exit;
    end;

    { Splice our new entry in.  It will be added after the current active
      record - so the frequencies will match again }

  NextCabrilloRecordPtr := ActiveCabrilloEntry^.NextRecord;
  PreviousCabrilloRecordPtr := ActiveCabrilloEntry;

  ActiveCabrilloEntry^.NextRecord := New(CabrilloRecPtr);

  ActiveCabrilloEntry := ActiveCabrilloEntry^.NextRecord;

  with ActiveCabrilloEntry^ do
    begin
      CabrilloString := FileString;
      Time := QSOTime;
      LogsFound := LogWorkedValue;
      PreviousRecord := PreviousCabrilloRecordPtr;
      NextRecord := NextCabrilloRecordPtr;
    end;
end;

procedure MergeCabrilloLogs;

var
  FileNames                   : array[0..11] of Str20;
  FileNumber, NumberFiles     : integer;
  OutputFileName              : string;
  FileRead, FileWrite         : Text;
  LogWorkedValue              : Word;
  FileString                  : Str160;
  Time                        : LONGINT;

begin
{//    ClearScreenAndTitle ('MERGE CABRILLO LOGS');
  WriteLn('This routine will merge up to twelve cabrillo files at one time into a single');
  WriteLn('Cabrillo file.  The contacts will all be sorted into chronological order and');
  WriteLn('duplicate QSOs found in more than one log will not be saved.');
  WriteLn;
}
  NumberFiles := 0;

  CabrilloEntryHead := nil;             { Make sure these are nil }
{
  repeat
    FileNames[NumberFiles] := GetResponse('Enter filename (none to continue) : ');

    if FileNames[NumberFiles] = '' then begin
        if NumberFiles = 0 then
          Exit;
      end
    else
      if FileExists(FileNames[NumberFiles]) then
        inc(NumberFiles)
      else
        ShowMessage(FileNames[NumberFiles] + ' not found.');

  until (NumberFiles = 12) or (FileNames[NumberFiles] = '');
}
  NumberFiles := postform.CabList.Lines.Count;
  OutputFileName := ExtractFileDir(application.ExeName) + '\' + postform.ResFNEdit.Text;

  if OutputFileName = '' then Exit;

    { Read in each file into the linked list }

  for FileNumber := 0 to NumberFiles - 1 do
    begin
//      WriteLn('Processing file ', FileNames[FileNumber]);

      ActiveCabrilloEntry := CabrilloEntryHead; { Start at the start }

        { Determine binary value to use to set the proper log worked bit in
          the LogsFound word in the Cabrillo records }

      case FileNumber of
        0: LogWorkedValue := $0001;
        1: LogWorkedValue := $0002;
        2: LogWorkedValue := $0004;
        3: LogWorkedValue := $0008;
        4: LogWorkedValue := $0010;
        5: LogWorkedValue := $0020;
        6: LogWorkedValue := $0040;
        7: LogWorkedValue := $0080;
        8: LogWorkedValue := $0100;
        9: LogWorkedValue := $0200;
        10: LogWorkedValue := $0400;
        11: LogWorkedValue := $0800;
      end;

      if not OpenFileForRead(FileRead, postform.CabList.Lines.Strings[FileNumber] {FileNames[FileNumber]}) then
        begin
          ShowMessage('Unable to open ' + postform.CabList.Lines.Strings[FileNumber]);
          halt;
        end;

        { Skip over the header }

      repeat
        ReadLn(FileRead, FileString);

        if Copy(FileString, 1, 4) = 'QSO:' then
          begin
            Time := GetUnixTimeFromCabrilloEntry(FileString);
            AddQSOToLinkedList(FileString, Time, LogWorkedValue);
//                PinWheel;
          end;

//            IF KeyPressed THEN IF ReadKey = EscapeKey THEN Break;

      until Eof(FileRead);

      Close(FileRead);
    end;

    { Okay - now we need to spit out the new log }

  OpenFileForWrite(FileWrite, OutputFileName);

  ActiveCabrilloEntry := CabrilloEntryHead; { Start at the start }

  while ActiveCabrilloEntry <> nil do
    begin
      WriteLn(FileWrite, ActiveCabrilloEntry^.CabrilloString);
      ActiveCabrilloEntry := ActiveCabrilloEntry^.NextRecord;
    end;

  Close(FileWrite);

  view(OutputFilename);
end;

function UtilityMenu: boolean;

var
  Key                         : Char;

begin
  UtilityMenu := true;
    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('UTILITY PROGRAM MENU');
  WriteLn;
    //TextColor (Cyan);
  WriteLn('  A - Append program (append LOG.DAT to history files).');
  WriteLn('  C - Check country and zone for specified callsign.');
  WriteLn('  D - Date/time change for a log.');
  WriteLn('  E - Edit TRMASTER.ASC file (menu).');
  WriteLn('  G - Global log search (list of calls not in a log.');
  WriteLn('  H - Get beam headings and distance between grids.');
  WriteLn('  M - Merge Cabrillo files into single file.');
  WriteLn('  N - NameEdit (old NAMES.CMQ database editor).');
  WriteLn('  S - Show contents of RESTART.BIN file.');
  WriteLn('  X - Exit utility program menu.');
  WriteLn;
    //TextColor (Cyan);
  Write('  Enter command : ');

  repeat
//        REPEAT UNTIL KeyPressed;
//        Key := UpCase (ReadKey);

    case Key of
      'A':
        begin
          AppendProcedure;
          Exit;
        end;
      'C':
        begin
          CountryCheck;
          Exit;
        end;
      'D':
        begin
          DateTimeChange;
          Exit;
        end;
      'E':
        begin
          DTAEditor;
          Exit;
        end;
      'G':
        begin
          GlobalLogSearch;
          Exit;
        end;
      'H':
        begin
          GetBeamHeadings;
          Exit;
        end;
      'M':
        begin
          MergeCabrilloLogs;
          Exit;
        end;
      'N':
        begin
          NameEditor;
          Exit;
        end;
      'S':
        begin
          ShowRestartDotBin;
          Exit;
        end;
      'X', EscapeKey:
        begin
          UtilityMenu := False;
          Exit;
        end;

    end;
  until False;
end;

begin
end.

