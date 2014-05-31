unit LOGMENU;

{$O+}
{$F+}
{$IMPORTEDDATA OFF}
interface

uses
  VC,
  LogWind,
  FCONTEST,
  Tree;

//PROCEDURE MakeListOfAvailableContestFiles;
{WLI}
//FUNCTION SelectAvailableLog: Str20;  { Returns null if no log selected }

implementation
uses MainUnit;

type
  AvailableFileArray = array[0..100] of Str20;
  AvailableFileArrayPtr = ^AvailableFileArray;

var
  ConfigFiles                 : AvailableFileArrayPtr;
  NumberConfigFiles           : integer;

procedure CheckForOldLogCfgFile;

{ This procedure will look for a LOGCFG.DAT file.  If one is found, it will
  ask the user if he would like to rename it to the appropriate .CFG file. }

var
  FileRead                    : Text;
  FileString                  : Str160;
  ID, CMD                     : shortstring {Str80};
  Key                         : Char;

begin
  if FileExists('LOGCFG.DAT') then
  begin
      {        ClrScr;
              TextColor (Yellow);
              WriteLnCenter ('LOGCFG.DAT FILE CONVERSION');
              WriteLn;
              TextColor (Cyan);

              WriteLn ('You are seeing this message because the file LOGCFG.DAT has been found in');
              WriteLn ('the active directory.  TR Log now uses configuration files that have unique');
              WriteLn ('names for each of the 60+ contests it knows how to operate.  This allows you');
              WriteLn ('to keep all of your files for various contests in one directory.');
              WriteLn;
              WriteLn ('You are about to see a list of the different configuration files that exist');
              WriteLn ('in the active directory.  One of these will be LOGCFG which you can select');
              WriteLn ('as the active contest, and it will run just like before.');
              WriteLn;
              WriteLn ('However, if you would like to have your LOGCFG.DAT file and corresponding log');
              WriteLn ('files renamed to the new convention, I can do that for you.');
              WriteLn;
      }
    repeat
      Key := UpCase(GetKey('Would you like you files updated to the new method? (Y/N) : '));
      if (Key = EscapeKey) or (Key = 'N') then Exit;
    until Key = 'Y';
    WriteLn;

      //{WLI}        TextColor (Cyan);

    if OpenFileForRead(FileRead, 'LOGCFG.DAT') then
    begin
      while not Eof(FileRead) do
      begin
        ReadLn(FileRead, FileString);

        FileString := UpperCase(FileString);

        ID := UpperCase(PrecedingString(FileString, '='));
        CMD := PostcedingString(FileString, '=');

        GetRidOfPrecedingSpaces(ID);
        GetRidOfPrecedingSpaces(CMD);
        GetRidOfPostcedingSpaces(ID);
        GetRidOfPostcedingSpaces(CMD);

        if ID = 'CONTEST' then
          if FoundContest(CMD) then
          begin
            Close(FileRead);

//            WriteLn('Renaming LOGCFG.DAT to ', LogConfigFileName);
//            RenameFile('LOGCFG.DAT', LogConfigFileName);
                    {
                                if FileExists('LOG.DAT') then
                                begin
                                  WriteLn('Renaming LOG.DAT to ', LogFileName);
                                  RenameFile('LOG.DAT', LogFileName);
                                end;

                                if FileExists('LOG.TMP') then
                                begin
                                  WriteLn('Renaming LOG.TMP to ', LogTempFileName);
                                  RenameFile('LOG.TMP', LogTempFileName);
                                end;
                    }
            if FileExists('RESTART.BIN') then
            begin
//              WriteLn('Renaming RESTART.BIN to ', LogRestartFileName);
//              RenameFile('RESTART.BIN', LogRestartFileName);
            end;

                    {                        TextColor (Cyan);
                                            WriteLn;
                                            WriteLn ('Process completed - press any key to continue.');
                    }
                    //{WLI}                        REPEAT UNTIL KeyPressed;
                    //{WLI}                        WHILE KeyPressed DO ReadKey;
            Exit;
          end
          else
          begin
            Close(FileRead);
            ShowMessage('I found a contest name I do no understand in your LOGCFG.DAT file.');
                    //{WLI}                        WaitForKeyPressed;
            Exit;
          end;
      end;

      Close(FileRead);

      ShowMessage('I did not fine a contest name in your LOGCFG.DAT file.');
          //{WLI}            WaitForKeyPressed;
    end;
  end;
end;
{
procedure MakeListOfAvailableContestFiles;

var
  DirInfo                     : TSearchRec;

begin
  New(ConfigFiles);

  NumberConfigFiles := 0;

  FindFirst('*.cfg', faArchive, DirInfo);

  while IORESULT  = 0 do
  begin
    ConfigFiles^[NumberConfigFiles] := PrecedingString(DirInfo.Name, '.');
    inc(NumberConfigFiles);
    FindNext(DirInfo);
  end;

  if FileExists('LOGCFG.DAT') then
  begin
    ConfigFiles^[NumberConfigFiles] := ('LOGCFG');
    inc(NumberConfigFiles);
  end;
end;
}

procedure InverseVideo(Entry: integer; StartY: integer; NumberRows: integer; Contest: Str20);

var
  Row, col                    : integer;

begin
  while length(Contest) < 20 do Contest := Contest + ' ';

  //  NoCursor;
  col := (Entry div NumberRows) * 20 + 1;
  Row := (Entry mod NumberRows);
  {    GoToXY (Col, Row + StartY);

      TextBackGround (White);
      TextColor (Black);
      Write (Contest);
     }
end;

procedure NormalVideo(Entry: integer; StartY: integer; NumberRows: integer; Contest: Str20);

var
  Row, col                    : integer;

begin
  while length(Contest) < 20 do Contest := Contest + ' ';

  col := (Entry div NumberRows) * 20 + 1;
  Row := (Entry mod NumberRows);

  //  NoCursor;
   {    GoToXY (Col, Row + StartY);

       TextBackGround (Black);
       TextColor (Yellow);
       Write (Contest);
      }
end;

procedure DeleteOrMoveLog(RootName: Str20);

var
  Key                         : Char;
  DestFileName                : Str80;

begin
  {WLI}
  {   GoToXY (1, 22);

     REPEAT
          Key := UpCase (GetKey ('Do you want to (M)ove or (D)elete this log? (escape to abort) : '));
          IF Key = EscapeKey THEN Exit;
      UNTIL (Key = 'M') OR (Key = 'D');

      GoToXY (1, WhereY);
      ClrEol;

      IF Key = 'D' THEN    // Delete the log
          BEGIN
          Showmessage ('WARNING!!  You are about to delete this log.');

          REPEAT
              Key := UpCase (GetKey ('Okay to delete? (Y/N) : '));
              IF (Key = EscapeKey) OR (Key = 'N') THEN Exit;
          UNTIL Key = 'Y';

          IF RootName = 'LOGCFG' THEN
              BEGIN
              DeleteFile ('logcfg.dat');
              DeleteFile ('restart.bin');
              DeleteFile ('log.tmp');
              DeleteFile ('log.dat');
              END
          ELSE
              BEGIN
              DeleteFile (RootName + '.cfg');
              DeleteFile (RootName + '.rst');
              DeleteFile (RootName + '.tmp');
              DeleteFile (RootName + '.log');
              END;

          Exit;
          END;

  //     Append the .tmp file if it exists

      DestFileName := GetResponse ('File to move this log into (none to abort) : ');

      IF DestFileName = '' THEN Exit;

  // Move the file

      IF RootName = 'LOGCFG' THEN
          BEGIN
          DeleteFile ('RESTART.BIN');

          IF FileExists ('LOG.TMP') THEN
              BEGIN
              IF AppendFile ('LOG.TMP', 'LOG.DAT') THEN
                  DeleteFile ('LOG.TMP')
              ELSE
                  BEGIN
                  ReportError ('W7EW error!!');
                  Halt;
                  END;
              END;

          IF NOT AppendFile ('LOG.DAT', DestFileName) THEN Halt;
          END
      ELSE
          BEGIN
          DeleteFile (RootName + '.rst');

          IF FileExists (RootName + '.tmp') THEN
              BEGIN
              IF AppendFile (RootName + '.tmp', RootName + '.dat') THEN
                  DeleteFile (RootName + '.tmp')
              ELSE
                  BEGIN
                  ReportError ('W7EW error!!');
                  Halt;
                  END;
              END;

          IF NOT AppendFile (RootName + '.dat', DestFileName) THEN Halt;
          END;

      WriteLn ('File moved to ', DestFileName);

      REPEAT
          Key := UpCase (GetKey ('Do you want to delete the log file? (Y/N) : '));
          IF Key = EscapeKey THEN Exit;
      UNTIL (Key = 'Y') OR (Key = 'N');
      WriteLn;

      IF Key = 'Y' THEN
          IF Rootname = 'LOGCFG' THEN
              DeleteFile ('LOG.DAT')
          ELSE
              DeleteFile (RootName + '.dat');

      REPEAT
          Key := UpCase (GetKey ('Do you want to delete the config file? (Y/N) : '));
          IF Key = EscapeKey THEN Exit;
      UNTIL (Key = 'Y') OR (Key = 'N');
      WriteLn;

      IF Key = 'Y' THEN
          IF Rootname = 'LOGCFG' THEN
              DeleteFile ('LOGCFG.DAT')
          ELSE
              DeleteFile (RootName + '.CFG');

      END;

  

  FUNCTION SelectAvailableLog: Str20;

  VAR ActiveEntry, Entry, Address, BubbleCount, Index, StartX, StartY: INTEGER;
      NumberRows: INTEGER;
      Key: CHAR;
      TempString, EntryString: Str20;

      BEGIN
      MakeListOfAvailableContestFiles;

      IF NumberConfigFiles = 0 THEN
          BEGIN
          Dispose (ConfigFiles);
          SelectAvailableLog := '';
          Exit;
          END;

      IF NumberConfigFiles = 1 THEN
          BEGIN
          SelectAvailableLog := ConfigFiles^ [0];
          Dispose (ConfigFiles);
          Exit;
          END;

  // We need operator interventio

      ClrScr;
      TextColor (Yellow);
      WriteLnCenter ('CONTEST SELECTION MENU');
      WriteLn;
      TextColor (Cyan);

      WriteLn ('Use arrow keys to select an existing logs or F1 to start a new contest.');
      WriteLn ('Use DELETE to move or delete the highlighted entry.  ESCAPE will exit TR.');
      WriteLn;

       List the files and allow the user to select one of them

      StartX := WhereX;
      StartY := WhereY;
      ActiveEntry := 0;
      EntryString := '';

  //Sort them in case I put one in the wrong place or the end

      IF NumberConfigFiles > 1 THEN
          BEGIN
          Index := NumberConfigFiles - 2;

          FOR BubbleCount := 1 TO NumberConfigFiles - 1 DO
              BEGIN
              FOR Address := 0 TO Index DO
                  IF ConfigFiles^ [Address] > ConfigFiles^ [Address + 1] THEN
                      BEGIN
                      TempString := ConfigFiles^ [Address + 1];
                      ConfigFiles^ [Address + 1] := ConfigFiles^ [Address];
                      ConfigFiles^ [Address] := TempString;
                      END;
              Dec (Index);
              END;
          END;

      NumberRows := NumberConfigFiles DIV 4 + 1;

  //Put up Initial Display

      InverseVideo (0, StartY, NumberRows, ConfigFiles^ [0]);

      FOR Entry := 1 TO NumberConfigFiles - 1 DO
          NormalVideo (Entry, StartY, NumberRows, ConfigFiles^ [Entry]);

      ActiveEntry := 0;

      REPEAT
          Key := UpCase (ReadKey);

          CASE Key OF
              EscapeKey:
                  BEGIN
                  SelectAvailableLog := '';
                  TextBackground (Black);
                  TextColor (Yellow);
                  SmallCursor;
                  ClrScr;
                  SelectAvailableLog := '';
                  Dispose (ConfigFiles);
                  SelectAvailableLog := 'EscapeKeyPressed';
                  Exit;
                  END;

              CarriageReturn:
                  BEGIN
                  SelectAvailableLog := ConfigFiles^ [ActiveEntry];
                  TextBackground (Black);
                  TextColor (Yellow);
                  SmallCursor;
                  ClrScr;
                  Dispose (ConfigFiles);
                  Exit;
                  END;

              BackSpace:
                  IF EntryString <> '' THEN
                      Delete (EntryString, Length (EntryString), 1);

              NullKey:
                  BEGIN
                  Key := ReadKey;

                  CASE Key OF
                      F1: BEGIN
                          SelectAvailableLog := '';
                          TextBackground (Black);
                          TextColor (Yellow);
                          SmallCursor;
                          ClrScr;
                          SelectAvailableLog := '';
                          Dispose (ConfigFiles);
                          SelectAvailableLog := 'F1KeyPressed';
                          Exit;
                          END;

                      DeleteKey:
                          BEGIN
                          DeleteOrMoveLog (ConfigFiles^ [ActiveEntry]);

  //Reinitialize display

                          MakeListOfAvailableContestFiles;

                          IF NumberConfigFiles = 0 THEN
                              BEGIN
                              Dispose (ConfigFiles);
                              SelectAvailableLog := '';
                              Exit;
                              END;

                          IF NumberConfigFiles = 1 THEN
                              BEGIN
                              SelectAvailableLog := ConfigFiles^ [0];
                              Dispose (ConfigFiles);
                              Exit;
                              END;

  //We need operator intervention

                          ClrScr;
                          TextColor (Yellow);
                          WriteLnCenter ('CONTEST SELECTION MENU');
                          WriteLn;
                          TextColor (Cyan);

                          WriteLn ('Select one of the following existing logs or ESCAPE to select a new contest.');
                          WriteLn ('You can use DELETE to move or delete the highlighted entry.');
                          WriteLn;

  //List the files and allow the user to select one of them

                          StartX := WhereX;
                          StartY := WhereY;
                          ActiveEntry := 0;
                          EntryString := '';

  //Sort them in case I put one in the wrong place or the end

                          IF NumberConfigFiles > 1 THEN
                              BEGIN
                              Index := NumberConfigFiles - 2;

                              FOR BubbleCount := 1 TO NumberConfigFiles - 1 DO
                                  BEGIN
                                  FOR Address := 0 TO Index DO
                                      IF ConfigFiles^ [Address] > ConfigFiles^ [Address + 1] THEN
                                          BEGIN
                                          TempString := ConfigFiles^ [Address + 1];
                                          ConfigFiles^ [Address + 1] := ConfigFiles^ [Address];
                                          ConfigFiles^ [Address] := TempString;
                                          END;
                                  Dec (Index);
                                  END;
                              END;

                          NumberRows := NumberConfigFiles DIV 4 + 1;

                          InverseVideo (0, StartY, NumberRows, ConfigFiles^ [0]);

                          FOR Entry := 1 TO NumberConfigFiles - 1 DO
                              NormalVideo (Entry, StartY, NumberRows, ConfigFiles^ [Entry]);

                          ActiveEntry := 0;
                          END;

                      RightArrow:
                          IF ActiveEntry < NumberConfigFiles - NumberRows THEN
                              BEGIN
                              NormalVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                              ActiveEntry := ActiveEntry + NumberRows;
                              InverseVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                              END;

                      LeftArrow:
                          IF ActiveEntry >= NumberRows THEN
                              BEGIN
                              NormalVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                              ActiveEntry := ActiveEntry - NumberRows;
                              InverseVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                              END;

                      UpArrow:
                          IF ActiveEntry > 0 THEN
                              BEGIN
                              NormalVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                              ActiveEntry := ActiveEntry - 1;
                              InverseVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                              END;

                      DownArrow:
                          IF ActiveEntry + 1 < NumberConfigFiles THEN
                              BEGIN
                              NormalVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                              ActiveEntry := ActiveEntry + 1;
                              InverseVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                              END;

                      HomeKey:
                          BEGIN
                          NormalVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                          ActiveEntry := 0;
                          InverseVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                          END;

                      EndKey:
                          BEGIN
                          NormalVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                          ActiveEntry := NumberConfigFiles - 1;
                          InverseVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                          END;

                      END;
                  END;

              ELSE
                  IF ((Key >= 'A') AND (Key <= 'Z')) OR (Key = ' ') OR ((Key >= '0') OR (Key <= '9')) THEN
                      BEGIN
                      EntryString := EntryString + Key;

                      FOR Entry := 0 TO NumberConfigFiles - 1 DO
                          IF Copy (ConfigFiles^ [Entry], 1, Length (EntryString)) = EntryString THEN
                              BEGIN
                              NormalVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                              ActiveEntry := Entry;
                              InverseVideo (ActiveEntry, StartY, NumberRows, ConfigFiles^ [ActiveEntry]);
                              Break;
                              END;
                      END;
              END;
      UNTIL False;
     }
end;

begin
end.

