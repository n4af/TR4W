unit PostSCP;

{$O+}
{$F+}

interface

uses Country9,
  LogSCP,
  Tree,
  Dialogs;
     //SlowTree,
     //Crt,
//     DOS;

procedure AddFileToDatabase;
procedure ExportOldCallsFromASCIIFile;
procedure ReadDataFromAnotherDTAFile;
procedure TRMasterNameEditor;


implementation

function CheckForOverwriteUpdates: boolean;

var
  Key: Char;

begin
  repeat
    Key := UpCase(GetKey('Do you want to check the overwrite flag status? (Y/N) : '));

    if Key = EscapeKey then
    begin
      CheckForOverwriteUpdates := False;
      WriteLn;
      exit;
    end;

  until (Key = 'Y') or (Key = 'N');
  WriteLn;

  if Key = 'Y' then
  begin
    CheckForOverwriteUpdates := CD.OverwriteFlagStatus;
    WriteLn;
  end;
end;

procedure ExportOldCallsFromASCIIFile;

var
  FileName: Str80;
  FileString: string;
  FileRead: Text;
  Key: Char;
  CallCount: integer;
  data: DatabaseEntryRecord;
  SaveNewCalls: boolean;

begin
    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('UPDATE DATABASE WITH NEW CALLSIGNS');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This procedure will update callsigns in the database with new callsigns.');
  WriteLn('The previous call will be stored in the OldCall field.  If the old call');
  WriteLn('was not found in a database, a new record will be created for the new');
  WriteLn('call if you want.');
  WriteLn;
  WriteLn('The input file format is an ASCII list with old call followed by a space,');
  WriteLn('then the new call.');
  WriteLn;

  FileName := GetResponse('Enter callsign change file to process (none to quit) : ');
  if FileName = '' then exit;

  if not OpenFileForRead(FileRead, FileName) then
  begin
    SHOWMESSAGE(FileName + ' was not found!!');
        //WaitForKeyPressed;
    exit;
  end;

  SaveNewCalls := 'Y' = GetKeyResponse('Save new calls which were not found in the database? (Y, N) : ');

  CD.FirstMergeDataListEntry := nil;

  if not CD.ASCIIFileIsCurrent then CD.SaveToASCIIFile;

  repeat
        //TextColor (Yellow);
    WriteLn('Reading data from ', FileName, ' into memory...');
    CallCount := 0;

//        WHILE (NOT Eof (FileRead)) AND (MemAvail - 100000 > SizeOf (DataListEntryRecord)) DO
    begin
      CD.ClearDataEntry(data);
      ReadLn(FileRead, FileString);

      data.OldCall := UpperCase(RemoveFirstString(FileString));
      data.Call := UpperCase(RemoveFirstString(FileString));

      if data.Call <> '' then
      begin
        CD.AddRecordToMergeList(data);
        inc(CallCount);
//                IF CallCount MOD 10 = 0 THEN PinWheel;
      end;
    end;

        //TextColor (Cyan);
        //GoToXY (1, WhereY);
        //ClrEol;
    if Eof(FileRead) then Write('All ');

    WriteLn(CallCount, ' entries read from ', FileName, ' into memory.');

    CD.TransferMergeDataToASCIIFile(true, SaveNewCalls);
  until Eof(FileRead);

  Close(FileRead);
  CD.BuildNewDatabaseFromASCIIFile(CHR(0));
end;

procedure ShowTypicalLogEntry(FileName: Str80);

var
  FileRead: Text;
  FileString: string;

begin
  if OpenFileForRead(FileRead, FileName) then
  begin
    while not Eof(FileRead) do
    begin
      ReadLn(FileRead, FileString);
      ExpandTabs(FileString);

      if (GetLogEntryBand(FileString) <> NoBand) and
        (GetLogEntryMode(FileString) <> NoMode) and
        (GoodCallSyntax(GetLogEntryCall(FileString))) then
      begin
        WriteLn('Here is a typical log entry to help you compute cursor positions:');
        WriteLn;
        WriteLn(FileString);
        WriteLn('123456789112345678921234567893123456789412345678951234567896123456789712345678');
        WriteLn('         0         0         0         0         0         0         0 ');
        WriteLn;
        Close(FileRead);
        exit;
      end

    end;
    Close(FileRead);
  end;
end;

procedure MoveDataIntoField(DataString: Str20; FieldKey: Char; var data: DataBaseEntryRecord);

var
  Result: integer;

begin
  case FieldKey of
    '1': begin
        if length(DataString) > 5 then DataString := Copy(DataString, 1, 5);
        data.Section := DataString;
      end;

    '2': begin
        if length(DataString) > 6 then DataString := Copy(DataString, 1, 6);
        if LooksLikeAGrid(DataString) then data.Grid := DataString;
      end;

    '3': begin
        if length(DataString) > 2 then DataString := Copy(DataString, 1, 2);
        data.Check := DataString;
      end;

    '4': begin
        if length(DataString) > 10 then DataString := Copy(DataString, 1, 10);
        data.QTH := DataString;
      end;

    '5': begin
        if length(DataString) > 2 then DataString := Copy(DataString, 1, 2);
        data.CQZone := DataString;
      end;

    '6': begin
        if length(DataString) > 5 then DataString := Copy(DataString, 1, 5);
        data.ITUZone := DataString;
      end;

    '7': begin
        data.mName := DataString;
        if length(DataString) > 12 then DataString := Copy(DataString, 1, 12);
      end;

    '8': begin
        if StringIsAllNumbers(DataString) then
          Val(DataString, data.Speed, Result);
      end;

    '9': begin
        if length(DataString) > 5 then DataString := Copy(DataString, 1, 5);
        data.FOC := DataString;
      end;

    'A': begin
        if length(DataString) > 6 then DataString := Copy(DataString, 1, 6);
        data.TenTen := DataString;
      end;

    'B': begin
        if length(DataString) > 12 then DataString := Copy(DataString, 1, 12);
        data.User1 := DataString;
      end;

    'C': begin
        if length(DataString) > 12 then DataString := Copy(DataString, 1, 12);
        data.User2 := DataString;
      end;

    'D': begin
        if length(DataString) > 12 then DataString := Copy(DataString, 1, 12);
        data.User3 := DataString;
      end;

    'E': begin
        if length(DataString) > 12 then DataString := Copy(DataString, 1, 12);
        data.User4 := DataString;
      end;

    'F': begin
        if length(DataString) > 12 then DataString := Copy(DataString, 1, 12);
        data.User5 := DataString;
      end;
  end;
end;

procedure GeneralPurposeLogFileExtract;

{ This procedure is intended to allow any exchange data field to be moved
  from a log file into the TRMASTER database, along with adding new calls. }

type
  SearchInfoType = record
    CursorPosition: SHORTINT;
    IgnoreCount: SHORTINT;
    FieldKey: Char;
  end;

var
  NumberSearchItems: integer;
  SearchItemData: array[0..10] of SearchInfoType;
  TempKey, Key, FieldKey: Char;
  DoingLogFile: boolean;
  FileName: Str40;
  FileRead: Text;
  DataString, FileString: string;
  data: DatabaseEntryRecord;
  CallCursorPosition, CallCount, Count: integer;
  Ignore, Result: integer;
  TotalCallCount: LONGINT;

begin
  TotalCallCount := 0;
  NumberSearchItems := 0;

    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('GENERAL PURPOSE FILE TO TRMASTER PROCEDURE');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This procedure allows you to pull data from an ASCII file and put it into your');
  WriteLn('TRMASTER database.  The file can be either be a LOG.DAT format file, or an');
  WriteLn('ASCII file.');
  WriteLn;
  WriteLn('This procedure will add any new callsigns found into the database, along with');
  WriteLn('one data parameter.  If there is more than one type of data that you wish to');
  WriteLn('to pull out of the log, you will have to run this procedure again for each');
  WriteLn('type of data. (ie: once for names and again for QTHs).');
  WriteLn;
  WriteLn('Old data will be over-written if the overwrite flag for the data field is set');
  WriteLn('to true.  Execute the O command on the menu to view/edit these flags.');
  WriteLn;

  repeat
    FileName := GetResponse('Enter the name of the file to process (none to quit) : ');
    if FileName = '' then exit;

    if not FileExists(FileName) then
      SHOWMESSAGE(FileName + ' not found!!');

  until FileExists(FileName);

  repeat
    Key := UpCase(GetKey('Is this a TR log file? (Y/N) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;

  DoingLogFile := Key = 'Y';

  WriteLn;

  repeat
        //TextColor (Cyan);

    if DoingLogFile then
    begin
      ShowTypicalLogEntry(FileName);

      WriteLn('You have selected TR log file format.  I will find the callsigns of the ');
      WriteLn('stations (calls always start character position 30), but I need you to ');
      WriteLn('specify the character position where the data you want to pull from the');
      WriteLn('log starts.  Only entries with a valid looking call, band and mode will');
      WriteLn('be processed.  Data will be copied starting at the specified position ');
      WriteLn('until a space is found.  If there is a space found at the position you ');
      WriteLn('select, the data is assumed to be blank.');
      WriteLn;
      WriteLn('Also, I can get fancy and ignore a certain number of entries starting at');
      WriteLn('this position.  You would need to do this if you wanted to access the');
      WriteLn('third entry in the exchange, and the first two entries were not always the');
      WriteLn('same length.');
      WriteLn;

      SearchItemData[NumberSearchItems].CursorPosition :=
        GetValue('Enter character position to start looking at data from (zero for none): ');

      if SearchItemData[NumberSearchItems].CursorPosition >= 80 then exit;

      if SearchItemData[NumberSearchItems].CursorPosition > 0 then
        SearchItemData[NumberSearchItems].IgnoreCount :=
          GetValue('Enter number of entries to ignore (zero for none) : ');
    end
    else
    begin
      WriteLn('You can use most any ASCII format with this routine.  The only requirement');
      WriteLn('is that the callsign and data must appear on the same line and there must');
      WriteLn('be one entry per line.  Lines with no data - or calls that does not look');
      WriteLn('like a callsign will be ignored.  You will need to specify the character');
      WriteLn('positions to use for the callsign and any data you want to save.  If there');
      WriteLn('is a space found at the data position, the data is assumed to be blank.');
      WriteLn;
      WriteLn('Also, I can get fancy and ignore a certain number of entries starting at');
      WriteLn('the data position.  You would need to do this if you wanted to access the');
      WriteLn('third entry in the exchange, and the first two entries were not always the');
      WriteLn('same length.');
      WriteLn;

      if OpenFileForRead(FileRead, FileName) then
      begin
        repeat
          ReadLn(FileRead, FileString);
          ExpandTabs(FileString);
          GetRidOfPrecedingSpaces(FileString);
        until Eof(FileRead) or (FileString <> '');

        if FileString <> '' then
        begin
          WriteLn(FileString);
          WriteLn('123456789112345678921234567893123456789412345678951234567896123456789712345678');
          WriteLn('         0         0         0         0         0         0         0 ');
          WriteLn;
        end;

        Close(FileRead);
      end;

      CallCursorPosition := GetValue('Enter cursor position for callsign : ');
      SearchItemData[NumberSearchItems].CursorPosition :=
        GetValue('Enter cursor position to start looking for data (zero for none) : ');

      if SearchItemData[NumberSearchItems].CursorPosition > 0 then
        SearchItemData[NumberSearchItems].IgnoreCount :=
          GetValue('Enter number of entries to ignore (zero for none) : ');
    end;

        //TextColor (Cyan);
    WriteLn;

    if SearchItemData[NumberSearchItems].CursorPosition > 0 then
    begin
      WriteLn('Here are the available places to save your data.  Choose none if you only');
      WriteLn('want to process the callsigns : ');
      WriteLn;
      WriteLn('0 - None            5 - CQ Zone         A - TenTen Number   F - User 5');
      WriteLn('1 - ARRL Section    6 - ITU Zone        B - User 1');
      WriteLn('2 - Grid            7 - Name            C - User 2');
      WriteLn('3 - Check           8 - Speed           D - User 3');
      WriteLn('4 - QTH             9 - FOC Number      E - User 4');
      WriteLn;

      repeat
        TempKey := UpCase(GetKey('Select field (0-12 or escape to quit) : '));
        if TempKey = EscapeKey then exit;

      until (TempKey = '1') or (TempKey = '2') or (TempKey = '3') or
        (TempKey = '4') or (TempKey = '5') or (TempKey = '6') or
        (TempKey = '7') or (TempKey = '8') or (TempKey = '9') or
        (TempKey = '0') or (TempKey = 'A') or (TempKey = 'B') or
        (TempKey = 'C') or (TempKey = 'D') or (TempKey = 'E') or
        (TempKey = 'F');

      SearchItemData[NumberSearchItems].FieldKey := TempKey;
      inc(NumberSearchItems);

      if NumberSearchItems > 10 then Break;

      repeat
        TempKey := UpCase(GetKey('Do you want to process another data field at the same time? (Y/N) : '));
        if TempKey = EscapeKey then exit;
      until (TempKey = 'Y') or (TempKey = 'N');

      WriteLn;
    end
    else
      TempKey := 'N';

  until TempKey = 'N';

  if not CheckForOverwriteUpdates then exit;

  if not CD.ASCIIFileIsCurrent then CD.SaveToASCIIFile;

  CD.FirstMergeDataListEntry := nil;

  if not OpenFileForRead(FileRead, FileName) then exit;

  repeat
        //TextColor (Yellow);
    WriteLn('Reading data from ', FileName, ' into memory...');
    CallCount := 0;

//        WHILE (NOT Eof (FileRead)) AND (MemAvail - 100000 > SizeOf (DataListEntryRecord)) DO
    begin
      CD.ClearDataEntry(data);

      ReadLn(FileRead, FileString);
      ExpandTabs(FileString);

      if DoingLogFile then
      begin
        if (GetLogEntryBand(FileString) <> NoBand) then
          if (GetLogEntryMode(FileString) <> NoMode) then
            if (GoodCallSyntax(GetLogEntryCall(FileString))) then
            begin
              inc(CallCount);
//                            IF CallCount MOD 10 = 0 THEN PinWheel;

              data.Call := GetLogEntryCall(FileString);

              if NumberSearchItems > 0 then
                for Count := 0 to NumberSearchItems - 1 do
                  with SearchItemData[Count] do
                  begin
                    if (CursorPosition > 0) and (FieldKey <> '0') then
                    begin
                      DataString := Copy(FileString, CursorPosition, 40);

                      if DataString[1] <> ' ' then
                      begin
                        if IgnoreCount > 0 then
                          for Ignore := 1 to IgnoreCount do
                            RemoveFirstString(DataString);

                        DataString := RemoveFirstString(DataString);
                        MoveDataIntoField(DataString, FieldKey, data);
                      end;
                    end;
                  end;

              CD.AddRecordToMergeList(data);
            end;
      end
      else
      begin
        GetRidOfPrecedingSpaces(FileString);

        if FileString <> '' then
        begin
          DataString := Copy(FileString, CallCursorPosition, 12);
          data.Call := UpperCase(RemoveFirstString(DataString));

          if GoodCallSyntax(data.Call) then
          begin
            inc(CallCount);
//                        IF CallCount MOD 10 = 0 THEN PinWheel;

            if NumberSearchItems > 0 then
              for Count := 0 to NumberSearchItems - 1 do
                with SearchItemData[Count] do
                begin
                  if (CursorPosition > 0) and (FieldKey <> '0') then
                  begin
                    DataString := Copy(FileString, CursorPosition, 40);

                    if DataString[1] <> ' ' then
                    begin
                      if IgnoreCount > 0 then
                        for Ignore := 1 to IgnoreCount do
                          RemoveFirstString(DataString);

                      DataString := RemoveFirstString(DataString);
                      MoveDataIntoField(DataString, FieldKey, data);
                    end;
                  end;
                end;

            CD.AddRecordToMergeList(data);
          end;
        end;
      end;

            //GoToXY (1, WhereY);
    end;

        //TextColor (Cyan);
        //GoToXY (1, WhereY);
        //ClrEol;
    if Eof(FileRead) then Write('All ');

    WriteLn(CallCount, ' entries read from ', FileName, ' into memory.');

    if CallCount > 0 then
      CD.TransferMergeDataToASCIIFile(False, true);

    TotalCallCount := TotalCallCount + CallCount;
  until Eof(FileRead);

  Close(FileRead);

  if TotalCallCount > 0 then
    CD.BuildNewDatabaseFromASCIIFile(CHR(0));
end;

procedure ReadDataFromAnotherDTAFile;

var
  RememberActiveFileName, RememberASCIIFileName: Str80;
  ExchangeString, FileString, FileName: Str80;
  FileRead: Text;
  CallCount: integer;
  data: DatabaseEntryRecord;

begin
    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('TRANSFER DATA FROM ANOTHER DTA FILE TO TRMASTER DATABASE');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This procedure will take data from another .DTA file (MASTER OR TRMASTER) and');
  WriteLn('put it into the TRMASTER.DTA file.  Data for existing callsigns will be over-');
  WriteLn('written depending on the state of the over-write flags.');
  WriteLn;

  FileName := GetResponse('Enter name of database file to read (none to quit): ');
  if FileName = '' then exit;

  if not FileExists(FileName) then
  begin
    SHOWMESSAGE(FileName + ' was not found!!');
        //WaitForKeyPressed;
    exit;
  end;

  if not CheckForOverwriteUpdates then exit;

    { Save the current TRMASTER.DTA file to ascii.  We use this file to
      get the data from to compare to the merge list. }

  if not CD.ASCIIFileIsCurrent then
  begin
    CD.SaveToASCIIFile;

        { Get rid of current .DTA file's index array }

    Close(CD.TRMasterFileRead);
    Dispose(CD.SCPIndexArray);
    CD.IndexArrayAllocated := False;
    CD.TRMasterFileOpen := False;
  end;

    { Save the input .DTA file to DTATEMP.ASC in ASCII format. }

    { Remember the filenames that the current .DTA file uses }

  RememberActiveFileName := CD.ActiveFileName;
  RememberASCIIFileName := CD.ActiveASCIIFileName;

    { Point to .DTA file to be merged and temporary ASCII file }

  CD.ActiveFileName := FileName;
  CD.ActiveASCIIFileName := 'DTATEMP.ASC';

    { Go get input .DTA file's index array }

  if not CD.LoadInIndexArray then
  begin
    CD.ActiveFileName := RememberActiveFileName;
    CD.ActiveASCIIFileName := RememberASCIIFileName;
    exit;
  end;

    { Save data to DTATEMP.ASC file in ASCII }

  CD.SaveToASCIIFile;

    { Close the index array }

  Close(CD.TRMasterFileRead);
  Dispose(CD.SCPIndexArray);
  CD.IndexArrayAllocated := False;
  CD.TRMasterFileOpen := False;

    { Restore normal filenames }

  CD.ActiveFileName := RememberActiveFileName;
  CD.ActiveASCIIFileName := RememberASCIIFileName;

    { Open up the input ASCII file }

  if not OpenFileForRead(FileRead, CD.WorkingDirectory + 'DTATEMP.ASC')
    then exit;

    { Initialize first merge data pointer }

  CD.FirstMergeDataListEntry := nil;

    { Suck data from the input ASCII file into the merge array }

  while not Eof(FileRead) do
  begin
        //TextColor (Yellow);
    WriteLn('Reading ASCII data for ', FileName, ' into memory...');
    CallCount := 0;

//        WHILE (NOT Eof (FileRead)) AND (MemAvail - 100000 > SizeOf (DataListEntryRecord)) DO
    begin
      CD.ClearDataEntry(data);
      ReadLn(FileRead, FileString);

      if FileString <> '' then
      begin
        CD.GetDataFromASCIIEntry(FileString, data, CHR(0));
        CD.AddRecordToMergeList(data);
        inc(CallCount);
//                IF CallCount MOD 10 = 0 THEN PinWheel;
      end;

    end;

        //TextColor (Cyan);
        //GoToXY (1, WhereY);
        //ClrEol;
    if Eof(FileRead) then Write('All ');

    WriteLn(CallCount, ' entries read from ', FileName, ' into memory.');

        { Go create a new ASCII file with merged data included }

    CD.TransferMergeDataToASCIIFile(False, true);
  end;

  Close(FileRead);

  CD.BuildNewDatabaseFromASCIIFile(CHR(0));
  DeleteFile(CD.WorkingDirectory + 'DTATEMP.ASC');
end;

procedure ExportNamesFromASCIIFile;

var
  FileName: Str80;
  FileString: string;
  FileRead: Text;
  ActiveRecord: DataListEntryPointer;
  CallCount: integer;
  data: DatabaseEntryRecord;

begin
    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('ASCII NAME FILE TO TRMASTER DATABASE');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This procedure will take an ASCII file with calls and names and move the data');
  WriteLn('into the TRMASTER.DTA file.  This file can be generated from the old name');
  WriteLn('database files using the name editor.  The format is simply a callsign,');
  WriteLn('followed by a space, then the name, then a new line.');
  WriteLn;

  FileName := GetResponse('ASCII file with names and calls to process (none to quit) : ');
  if FileName = '' then exit;

  if not OpenFileForRead(FileRead, FileName) then
  begin
    SHOWMESSAGE(FileName + ' was not found!!');
        //WaitForKeyPressed;
    exit;
  end;

  if not CheckForOverwriteUpdates then exit;

  if not CD.ASCIIFileIsCurrent then CD.SaveToASCIIFile;

  CD.FirstMergeDataListEntry := nil;

  repeat
        //TextColor (Yellow);
    WriteLn('Reading data from ', FileName, ' into memory...');
    CallCount := 0;

//        WHILE (NOT Eof (FileRead)) AND (MemAvail - 100000 > SizeOf (DataListEntryRecord)) DO
    begin
      CD.ClearDataEntry(data);
      ReadLn(FileRead, FileString);
      data.Call := RemoveFirstString(FileString);
      data.mName := RemoveFirstString(FileString);
      CD.AddRecordToMergeList(data);
      inc(CallCount);
//            IF CallCount MOD 10 = 0 THEN PinWheel;
    end;

        //TextColor (Cyan);
        //GoToXY (1, WhereY);
        //ClrEol;
    if Eof(FileRead) then Write('All ');

    WriteLn(CallCount, ' entries read from ', FileName, ' into memory.');

    CD.TransferMergeDataToASCIIFile(False, true);
  until Eof(FileRead);

  Close(FileRead);
  CD.BuildNewDatabaseFromASCIIFile(CHR(0));
end;

procedure AddFileToDatabase;

var
  Key: Char;

begin
{    IF MemAvail <= 150000 THEN
        BEGIN
        showmessage ('Insufficient memory to function.  Please free up some memory and retry.');
        //WaitForKeyPressed;
        Exit;
        END;
}
  repeat
        //ClrScr;
        //TextColor (Yellow);
    WriteLnCenter('ADD DATA FROM FILE TO TRMASTER.DTA');
        //TextColor (Cyan);

    WriteLn;
    WriteLn('  D - Load calls and data from another .DTA file.');
    WriteLn('  F - Load calls and data from a LOG.DAT or other ASCII file.');
    WriteLn('  N - Load ASCII file generated from NAMES file by name editor.');
    WriteLn('  O - Overwrite data flag status - view and set.');
    WriteLn('  V - Vanity callsign update procedure.');
    WriteLn('  X - Exit menu.');
    WriteLn;

    Key := UpCase(GetKey('Enter desired operation (escape to exit) : '));
    if Key = EscapeKey then exit;

    case Key of
      'D': ReadDataFromAnotherDTAFile;
      'F': GeneralPurposeLogFileExtract;
      'N': ExportNamesFromASCIIFile;
      'O': CD.OverwriteFlagStatus;
      'V': ExportOldCallsFromASCIIFile;
      'X': exit;
    end;

  until False;
end;

procedure ShowNameEditorCommands;

begin
    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('TRMASTER NAME EDITOR PROGRAM');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This editor allows you to quickly edit the names in your TRMASTER database.');
  WriteLn;
  WriteLn('Since the TRMASTER.DTA file can''t be edited quickly, this procedure will');
  WriteLn('stop occasionally to update the files.  Because of this, the changes you');
  WriteLn('had just typed in will not take effect until this process occurs.');
  WriteLn;
  WriteLn('Changes are first made to the TRMASTER.ASC file.  They are not saved in');
  WriteLn('the TRMASTER.DTA file until the end of this procedure.');
  WriteLn;
  WriteLn('Single letter commands: C - Toggle CW sending of names.');
  WriteLn('                        D - Delete a call from the database.');
  WriteLn('                        F - Make ASCII file with calls and names.');
  WriteLn('                        X - Quit editing and save changes.');
  WriteLn;
end;

function CallHasNoNumber(Call: CallString): boolean;

var
  CharPointer: integer;

begin
  if Call = '' then
  begin
    CallHasNoNumber := true;
    exit;
  end;

  CallHasNoNumber := False;

  for CharPointer := 1 to length(Call) do
    if ((Call[CharPointer] >= '0') and (Call[CharPointer] <= '9')) then
      exit;

  CallHasNoNumber := true;
end;

procedure TRMasterNameEditor;

label
  DataAdded;

var
  FileName: Str80;
  CWSend: boolean;
  StartOfCallEntered: integer;
  Name, Call, LastPrefix, FileString: Str20;
  TempData: DataBaseEntryRecord;

begin
  CD.NameOverwrite := true;

  ShowNameEditorCommands;

  CD.FirstMergeDataListEntry := nil;

  if not CD.ASCIIFileIsCurrent then CD.SaveToASCIIFile;

  LastPrefix := '';

  CWSend := true;
  CD.NumberDeleteCalls := 0;

  repeat
        //GoToXY (1, WhereY);
        //ClrEol;

        //TextColor (Cyan);

    Write('Enter call to edit : ');

//wli
    StartOfCallEntered := 1;
        //        StartOfCallEntered := WhereX;

        //TextColor (Yellow);

    ReadLn(Call);
    Call := UpperCase(Call);

    if length(Call) = 1 then
    begin
      case Call[1] of
        'C': CWSend := not CWSend;

        'D': begin
                     //GoToXY (40, WhereY - 1);
            Call := UpperCase(GetResponse('Callsign to delete : '));

            if Call <> '' then
            begin
              CD.DeleteCallList[CD.NumberDeleteCalls] := Call;
              inc(CD.NumberDeleteCalls);

              if CD.NumberDeleteCalls >= 20 then
              begin
                WriteLn('Please wait - I need to update files.');
                CD.TransferMergeDataToASCIIFile(False, true);
              end;
            end;

          end;

        'E': begin
                     //GoToXY (40, WhereY - 1);
            Call := UpperCase(GetResponse('Callsign to change name of : '));

            if GoodCallSyntax(Call) then
            begin
              Name := GetResponse('Old name = ' + CD.GetName(Call) + '.  Enter new name for ' + Call + ' : ');

              if Name <> '' then
              begin
                CD.ClearDataEntry(TempData);
                TempData.Call := Call;
                TempData.mName := Name;

                CD.AddRecordToMergeList(TempData);

{                             IF MemAvail < 100000 THEN
                                 BEGIN
                                 WriteLn;
                                 WriteLn ('Please wait, I need to update the files now...');
                                 CD.TransferMergeDataToASCIIFile (False, True);
                                 END;
              }end;
            end
            else
              WriteLn('Sorry - that call looks funny to me.');
          end;

        'F': begin
                     //GoToXY (40, WhereY -1);
            FileName := UpperCase(GetResponse('Filename for list : '));
            if FileName <> '' then CD.SaveCallsAndNamestoFile(FileName);
          end;

        'X': begin
            WriteLn('Okay - give me a minute to update the files.');
            CD.TransferMergeDataToASCIIFile(False, true);
            CD.BuildNewDatabaseFromASCIIFile(CHR(0));
            WriteLn('All done!!');
                     //WaitForKeyPressed;
            CD.NameOverwrite := False;
            exit;
          end;

      else
        ShowNameEditorCommands;

      end; { of single letter command case }
    end

    else

            { More than one character }

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

      if GoodCallSyntax(Call) then
      begin
        if CD.GetName(Call) = '' then
        begin
          Name := UpperCase(GetResponse('Name = '));

          if Name = '' then
          begin
                        //GoToXY (1, WhereY - 1);
                        //ClrEol;
          end
          else
            if Name <> '' then
            begin
              CD.ClearDataEntry(TempData);
              TempData.Call := Call;
              TempData.mName := Name;

              CD.AddRecordToMergeList(TempData);

{                            IF MemAvail < 100000 THEN
                                BEGIN
                                WriteLn;
                                WriteLn ('Please wait, I need to update the files now...');
                                CD.TransferMergeDataToASCIIFile (False, True);
                                END;
            }end;
        end
        else
        begin
                    //TextColor (Cyan);
          Write('Name = ');
                    //TextColor (Red);
          Name := CD.GetName(Call);
          WriteLn(Name);
//                    IF CWSend THEN SendMorse (Name);
        end;
      end
      else
      begin
                //TextColor (Red);
        WriteLn('That call does not look right!', Beep);
      end;

    end;
  until False;
end;

begin
end.
