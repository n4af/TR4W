unit PostQSL;

{$O+}
{$F+}

interface

uses Tree,
//     SlowTree,
  PostSubs,
  Country9,
  LogDupe,
//     Crt,
  SysUtils,
  LogWind,
  LogSCP,
  Dialogs,
  PostUnit,
  ViewUnit;

function QSLProcedureMenu: boolean;
procedure ConfirmContacts;
procedure EstimateNumberOfLabels;
procedure PrintLabelsOne;
procedure PrintSpecificLabels;
procedure PrintLabelsThree;

implementation

 { QSL Procedues }

type
  QSOListType = array[0..200] of Str80;
  QSOListPointer = ^QSOListType;

var
  QSOList                     : QSOListPointer;

procedure SetUpSpaces;

var
  Count, NumberSpaces         : integer;

begin
//    TextColor (Cyan);
  WriteLn('You can select how many blank spaces show up in front of each line printed');
  WriteLn('on your QSL labels.  The program used to always put 19 spaces in front of');
  WriteLn('each line, but now you can select the number.');
  WriteLn;

  NumberSpaces := GetValue('Enter number of spaces to start each line with : ');

  Spaces := '';

  if NumberSpaces > 0 then
    for Count := 1 to NumberSpaces do
      Spaces := Spaces + ' ';

end;

procedure ComputeCountryTotals(var CountryTotalArray: CountryTotalArrayType; var TotalQSOs: integer);

var
  Call                        : Str80;
  FileString                  : string;
  FileRead                    : Text;
  Country                     : integer;
  Band                        : BandType;

begin
  TotalQSOs := 0;
  for Country := 0 to CountryTable.NumberCountries - 1 do
    CountryTotalArray[Country] := 0;

  if not OpenFileForRead(FileRead, LogFileName) then
    begin
      ShowMessage(LogFileName + ' has disappeared!!');
        //WaitForKeyPressed;
      Exit;
    end;

  while not Eof(FileRead) do
    begin
      if OperatorEscape then
        begin
          Close(FileRead);
          for Country := 0 to CountryTable.NumberCountries - 1 do
            CountryTotalArray[Country] := 0;
          TotalQSOs := 0;
          Exit;
        end;

      ReadLn(FileRead, FileString);

      Band := GetLogEntryBand(FileString);

      if Band <> NoBand then
        begin
          ExpandTabs(FileString);
          Call := GetLogEntryCall(FileString);
          inc(CountryTotalArray[CountryTable.GetCountry(Call, true)]);
          inc(TotalQSOs);
        end;
    end;

  Close(FileRead);
end;

procedure AddQSLDataToLabels(Call: CallString; data: ContactRecord);

var
  NumberBlocks, Block, Address, FinishAddress: integer;

begin
  NumberBlocks := QSLData.NumberLabels div QSLLabelBlockSize + 1;

  if QSLData.NumberLabels > 0 then
    for Block := 1 to NumberBlocks do
      begin
        if Block = NumberBlocks then
          FinishAddress := (QSLData.NumberLabels - 1) mod QSLLabelBlockSize
        else
          FinishAddress := QSLLabelBlockSize - 1;

        for Address := 0 to FinishAddress do
          if QSLData.Blocks[Block]^[Address].Callsign = Call then
            with QSLData.Blocks[Block]^[Address] do
              if NumberContacts < NumberContactsPerLabel then
                begin
                  inc(NumberContacts);
                  ContactArray[NumberContacts] := data;
                  Exit;
                end;
      end;

  Address := QSLData.NumberLabels mod QSLLabelBlockSize;

  if Address = 0 then
    begin
      if QSLData.NumberLabels >= (QSLLabelBlockSize * MaxNumberBlocks) then
        begin
          ShowMessage('Out of memory!!  ' + Call + ' not added.');
            //WaitForKeyPressed;
          Exit;
        end;

      New(QSLData.Blocks[QSLData.NumberLabels div QSLLabelBlockSize + 1]);
    end;

  with QSLData.Blocks[NumberBlocks]^[Address] do
    begin
      Callsign := Call;
      NumberContacts := 1;
      ContactArray[NumberContacts] := data;
    end;

  inc(QSLData.NumberLabels);
end;

procedure ClearQSLDataMemory;

var
  Block, NumberBlocks         : integer;

begin
  NumberBlocks := QSLData.NumberLabels div QSLLabelBlockSize + 1;
  for Block := 1 to NumberBlocks do
    Dispose(QSLData.Blocks[Block]);
end;

procedure SetUpPointerArray;

var
  Address                     : integer;

begin
  New(PointerArray);

  for Address := 0 to QSLData.NumberLabels do
    PointerArray^[Address] := Address;
end;

procedure SortQSLLabelData;

var
  Address, temp, NumberCallsToSort, AddressA, AddressB: integer;
  BlockA, BlockB, Index, BubbleCount: integer;

begin
  NumberCallsToSort := QSLData.NumberLabels;

  if NumberCallsToSort <= 1 then Exit;

  Index := NumberCallsToSort - 2;

  for BubbleCount := 1 to NumberCallsToSort - 1 do
    begin
      for Address := 0 to Index do
        begin
          AddressA := PointerArray^[Address];
          AddressB := PointerArray^[Address + 1];
          BlockA := AddressA div QSLLabelBlockSize + 1;
          BlockB := AddressB div QSLLabelBlockSize + 1;
          AddressA := AddressA mod QSLLabelBlockSize;
          AddressB := AddressB mod QSLLabelBlockSize;

          if QSLData.Blocks[BlockA]^[AddressA].Callsign > QSLData.Blocks[BlockB]^[AddressB].Callsign then
            begin
              temp := PointerArray^[Address + 1];
              PointerArray^[Address + 1] := PointerArray^[Address];
              PointerArray^[Address] := temp;
            end;

        end;
      Dec(Index);
    end;
end;

procedure CreateSmallCountryTempFile(CountryTotalArray: CountryTotalArrayType);

var
  Country                     : integer;
  FileRead, FileWrite         : Text;
  Call                        : Str80;
  FileString                  : string;
  Band                        : BandType;

begin
  if not OpenFileForRead(FileRead, LogFileName) then
    begin
      ShowMessage(LogFileName + ' has disappeared!!');
        //WaitForKeyPressed;
      Exit;
    end;

  if not OpenFileForWrite(FileWrite, QSLTempFileName) then
    begin
      ShowMessage('Unable to open ' + QSLTempFileName);
      Close(FileRead);
        //WaitForKeyPressed;
      Exit;
    end;

  while not Eof(FileRead) do
    begin
      if OperatorEscape then
        begin
          Close(FileRead);
          Close(FileWrite);
          DeleteFile(QSLTempFileName);
          Exit;
        end;

      ReadLn(FileRead, FileString);

      Band := GetLogEntryBand(FileString);

      if Band <> NoBand then
        begin
          ExpandTabs(FileString);
          Call := StandardCallFormat(GetLogEntryCall(FileString), true);
          if CountryTotalArray[CountryTable.GetCountry(Call, true)] < 20 then
            WriteLn(FileWrite, FileString);
        end;
    end;

  Close(FileWrite);
  Close(FileRead);
end;

procedure ConfirmContacts;

type
  QSOEntryRecord = record
    Call: CallString;
    NumberQSOs: integer;
    EntryIndexList: array[0..20] of integer;
  end;

var
  Call, NumberQSOs, StationsName, NewName: Str80;
  FileString                  : string;
  DoingNames                  : boolean;
  CallAddress, Entry, NumberQSOEntries, NumberCalls: integer;
  CallList                    : array[0..20] of QSOEntryRecord;
  FileCallString              : CallString;
  Key                         : Char;
  NameFileWrite               : Text;
  FileRead                    : Text;

begin
//    Clrscr;
//    TextColor (Yellow);
{  WriteLnCenter('CONFIRM CONTACT PROCEDURE');
//    TextColor (Cyan);
  WriteLn;
  WriteLn('This procedure will allow you to search for individual callsigns in the');
  WriteLn('active log and see all the contacts you have made with that station.  Up');
  WriteLn('to 20 different stations may be processed at once.');
  WriteLn;
  WriteLn('You can also be shown the stations name if it exists in the name database,');
  WriteLn('and be given a chance to enter or correct his name.');
  WriteLn;
}

  if not FileExists(LogFileName) then
    begin
      ShowMessage('No logfile file found.');
      Exit;
    end;

  DoingNames := PostForm.EnCB.Checked;  //'Y' = GetKeyResponse('Do you want to enter names? (Y, N) : ');

  if DoingNames then
    begin
      ShowMessage('New names will be saved in the file NAMES.NEW.' + #13 + 'You can add this to your TRMASTER database.' { with the POST U E F N command.});
  //    WriteLn('New names will be saved in the file NAMES.NEW.  You can add this to your');
//    WriteLn('TRMASTER database with the POST U E F N command.');
      OpenFileForAppend(NameFileWrite, 'NAMES.NEW');
    end;

  New(QSOList);

  repeat
    NumberCalls := 0;
//        ClrScr;

    repeat
      if NumberCalls = 0 then
        Call := UpperCase(GetResponse('Enter a call to confirm QSO of' + #13 + '("Cancel" to stop) : '))
      else
        Call := UpperCase(GetResponse('Enter more calls to check at the same time or "Cancel" to end list : '));

      if (Call = '') and (NumberCalls = 0) then
        begin
          if DoingNames then
            begin
//          Write('Saving new names to NAMES.NEW.');
              Close(NameFileWrite);
            end;

          Dispose(QSOList);
          Exit;

        end;

      if Call <> '' then
        begin

          CallList[NumberCalls].Call := RootCall(Call);
          CallList[NumberCalls].NumberQSOs := 0;
          inc(NumberCalls);

          if (DoingNames and GoodCallSyntax(Call)) then
            begin
              StationsName := CD.GetName(Call);

              if StationsName = '' then
                begin
                  NewName := GetResponse(Call + #13 + 'Enter name : ' { + Beep});
                  if NewName <> '' then WriteLn(NameFileWrite, Call, ' ', NewName);
                end
              else
                begin
                  NewName := GetResponse(Call + #13 + 'Name = ' + StationsName + #13 + 'Enter new name if any : ');
                  if NewName <> '' then WriteLn(NameFileWrite, Call, ' ', NewName);
                end;
            end
          else
//          WriteLn;
        end;
    until (Call = '') or (NumberCalls = 20);

        //GoToXY (1, WhereY - 1);
        //ClrEol;
//    WriteLn;

        //TextColor (Cyan);

{    if NumberCalls > 1 then
      WriteLn('Searching your log for QSOs with ', NumberCalls, ' stations...')
    else
      WriteLn('Searching your log for QSOs with 1 station...');
}
    NumberQSOEntries := 0;

    if not OpenFileForRead(FileRead, LogFileName) then
      begin
        ShowMessage('Unable to open ' + LogFileName + '!!  It was there just a minute ago.');
        if DoingNames then Close(NameFileWrite);
        Exit;
      end;

    while (not Eof(FileRead)) {and (not OperatorEscape)} do
      begin
        ReadLn(FileRead, FileString);
        FileCallString := RootCall(GetLogEntryCall(FileString));

        for CallAddress := 0 to NumberCalls - 1 do
          if FileCallString = CallList[CallAddress].Call then
            if CallList[CallAddress].NumberQSOs < 20 then
              begin
                with CallList[CallAddress] do
                  begin
                    EntryIndexList[NumberQSOs] := NumberQSOEntries;
                    inc(NumberQSOs);
                  end;

                ExpandTabs(FileString);
                QSOList^[NumberQSOEntries] := FileString;
                inc(NumberQSOEntries);
                        //TextColor (Cyan);
                ViewForm.c.lines.Add('+');
              end
            else
              begin
                        //TextColor (Red);
                ViewForm.c.lines.Add('!');
              end;
      end;

    Close(FileRead);

    if NumberQSOEntries = 0 then
      begin
        ShowMessage('Sorry...  There were no QSOs found.');
      end
    else
      for CallAddress := 0 to NumberCalls - 1 do
        begin
          ViewForm.c.lines.Add('QSOs with ' + CallList[CallAddress].Call);
          if CallList[CallAddress].NumberQSOs = 0 then
            ViewForm.c.lines.Add('No QSOs were found with ' + CallList[CallAddress].Call)
          else
            for Entry := 0 to CallList[CallAddress].NumberQSOs - 1 do
              ViewForm.c.lines.Add(QSOList^[CallList[CallAddress].EntryIndexList[Entry]]);
          ViewForm.ShowModal;
//              if DoingNames then Close(NameFileWrite);
        end;

  until False;

end;

procedure EstimateNumberOfLabels;

var
  Key                         : Char;
  QSOsPerLabel, NumberQSOs, SearchAddress, CallAddress: integer;
  DifferentCallsigns, TotalLabels: integer;
  QSODistribution             : array[1..100] of integer;
  ts                          : string;
begin
{    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('ESTIMATE NUMBER OF QSL LABELS');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This procedure will estimate the number of QSL labels that will be printed   ');
  WriteLn('when using the three QSO per label procedure.  You can specify if you want a');
  WriteLn('maximum of 2 or 3 QSOs per label.  This procedure does not generate the labels.');
  WriteLn;
    //TextColor (Cyan);
  WriteLn('You can print up to three QSOs per label.  However, if you want to always   ');
  WriteLn('print at least the first signature, you can limit the number of lines to two.');
  WriteLn('If you want to always print both signatures, you can limit the number of');
  WriteLn('lines to one.');
  WriteLn;
  WriteLn('This procedure will also show you how many times you have worked each station');
  WriteLn('in your log.  This is useful for scoring contests where bonus points are');
  WriteLn('given for working a station on 5 or 6 bands.  Make sure you dupe your log');
  WriteLn('before doing this.');
  WriteLn;
}
  if not FileExists(LogFileName) then
    begin
      ShowMessage('No logfile file found.');
      Exit;
    end;

{  repeat
    Key := UpCase(GetKey('Enter the maximum number of QSOs per label (1-6) : '));
    if Key = EscapeKey then exit;
  until (Key >= '1') and (Key <= '6');
  WriteLn;

  case Key of
    '1': QSOsPerLabel := 1;
    '2': QSOsPerLabel := 2;
    '3': QSOsPerLabel := 3;
    '4': QSOsPerLabel := 4;
    '5': QSOsPerLabel := 5;
    '6': QSOsPerLabel := 6;
  end;
 }QSOsPerLabel := postform.MaxQSO.Value;

    //ClrScr;
    //TextColor (Cyan);
//  WriteLn;
  TotalLabels := 0;
  DifferentCallsigns := 0;
  for NumberQSOs := 1 to 100 do QSODistribution[NumberQSOs] := 0;

  if PutLogFileIntoCallBuffer(Both, All) then
    begin
      if NumberBufferCalls > 0 then
        begin
//      WriteLn('Looking through buffer and counting labels.');

          for CallAddress := 0 to NumberBufferCalls - 1 do
            begin
              Call := GetCall(CallAddress);
              NumberQSOs := 0;

              if Call <> 'DUPE' then
                begin
                  inc(NumberQSOs);
                  inc(DifferentCallsigns);

                  if CallAddress < NumberBufferCalls - 2 then
                    for SearchAddress := CallAddress + 1 to NumberBufferCalls - 1 do
                      if Call = GetCall(SearchAddress) then
                        begin
                          inc(NumberQSOs);
                          PutCall(SearchAddress, 'DUPE');
                        end;

                  TotalLabels := TotalLabels + (NumberQSOs - 1) div QSOsPerLabel + 1;

                  inc(QSODistribution[NumberQSOs]);
                    //GoToXY (1, WhereY);
                    //ClrEol;
//          Write(TotalLabels);
                end;
            end;

          DisposeCallBuffer;
        end;
    end
  else
    begin
      ShowMessage('Unable to find log file!!');
      Exit;
    end;

  for NumberQSOs := 1 to 100 do
    if QSODistribution[NumberQSOs] > 0 then
      if NumberQSOs = 1 then
        ts := ('There are ' + inttostr(QSODistribution[1]) + ' calls that appear only once in your log.')
      else
        ts := ('There are ' + inttostr(QSODistribution[NumberQSOs]) + ' calls that appear ' + inttostr(NumberQSOs) + ' times in your log.');

  ShowMessage('There are' +
    #13 +
    inttostr(TotalLabels) +
    ' labels to be printed with ' +
    inttostr(QSOsPerLabel) +
    ' max QSOs per label.' + #13 + #13 +
    'There are ' + #13 +
    inttostr(DifferentCallsigns) +
    ' different callsigns.' + #13 + #13 +
    'This is how many QSL cards you will need if you put multiple labels for the same station on one QSL card.' + #13 + #13 +
    ts);

end;

procedure PrintLabelsOne;

var
  FileName, FirstCall         : Str80;
  BandString, CallString, TempString, ModeString: string;
  Band                        : BandType;
  Mode                        : ModeType;
  MyCall, DateString,
    TimeString, RSTString, Signature: Str80;
  FirstMode, FirstBand        : Str20;
  UseLogRST, PrintEnable      : boolean;
  Destination, Key            : Char;
  FileRead, FileWrite         : Text;

begin
{    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('PRINT ONE LABEL FOR EVERY QSO PROCEDURE');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This procedure will print a single 15/16 Inch high label for each QSO in the');
  WriteLn('active log file.  The label will look like this:');
  WriteLn;
  WriteLn(Spaces, 'To: WB6ZVC  From: 4U1ITU');
  WriteLn(Spaces, '------------------------------');
  WriteLn(Spaces, 'Confirming 40SSB QSO at 0000Z ');
  WriteLn(Spaces, 'on 25-Dec-90.  Your RS was 59');
  WriteLn(Spaces, 'Signature                    ');
  WriteLn;
  WriteLn('You can enter up to thirty characters as your signature.  This procedure can');
  WriteLn('only print labels in the same order as they appear in your log.  The three');
  WriteLn('QSO per label procedure can sort labels into alphabetical order.');
  WriteLn;
}
  if not FileExists(LogFileName) then
    begin
      ShowMessage('No logfile file found.');
      Exit;
    end;

  MyCall := UpperCase(postform.FromEdit.Text);
  if MyCall = '' then Exit;

{  repeat
    Signature := GetResponse('Enter signature (max 30 chars) : ');
    if length(Signature) > 30 then
      SHOWMESSAGE('That signature is too long!!');
  until length(Signature) <= 30;

  SetUpSpaces;
}
  Signature := postform.SignatureEdit.Text;
  FirstCall := UpperCase(postform.FirstCallEdit.Text);

  if FirstCall <> '' then
    begin
      FirstBand := UpperCase(postform.FirstBandCB.Text);
      FirstMode := UpperCase(postform.FirstModeCB.Text);
      PrintEnable := False;
    end
  else
    PrintEnable := true;

{  repeat
    Key := UpCase(GetKey('Use RSTs from log? (Y/N) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;
 }UseLogRST := postform.UseRSTCB.Checked; //Key = 'Y';
{
  repeat
    Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
    case Destination of
      'F': begin
          WriteLn;
          FileName := UpperCase(postform.QSLFilenameEdit.Text);

          if FileName = UpperCase(LogFileName) then
          begin
            SHOWMESSAGE('Output file must be different than active log file!!');
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

  FileName := (postform.QSLFilenameEdit.Text);

  if FileName = UpperCase(LogFileName) then
    begin
      ShowMessage('Output file must be different than active log file!!');
      Exit;
    end;

  if FileName = '' then Exit;

  if not OpenFileForRead(FileRead, LogFileName) then
    begin
      ShowMessage(LogFileName + ' not found!!');
      Exit;
    end;

  if not OpenFileForWrite(FileWrite, FileName) then
    begin
      ShowMessage('Unable to open output file or device.');
      Exit;
    end;
{
  if Destination = 'P' then
  begin
    WriteLn('Press A to adjust number of spaces.');
    WriteLn('Press S to print sample label.');
    WriteLn('Press P to start printing labels.');

    repeat
//            REPEAT UNTIL KeyPressed;
//            Key := UpCase (ReadKey);

      if Key = 'A' then SetUpSpaces;

      if Key = 'S' then
      begin
        WriteLn(FileWrite, Spaces, 'To: WB6ZVC  From: ', MyCall);
        WriteLn(FileWrite, Spaces, '------------------------------');
        WriteLn(FileWrite, Spaces, 'Confirming 40CW QSO at 0000Z ');
        WriteLn(FileWrite, Spaces, 'on 25-Dec-90.  Ur RST was 599');
        WriteLn(FileWrite, Spaces, Signature);
        WriteLn(FileWrite);
      end;

    until Key = 'P';
  end;

    //ClrScr;
  WriteLn('Printing labels...  Press P to stop.');
}
  repeat

{    begin

      if Key = 'P' then
      begin
        Close(FileRead);
        exit;
      end;
    end;
}
    repeat
      ReadLn(FileRead, TempString);
      Band := GetLogEntryBand(TempString);
      Mode := GetLogEntryMode(TempString);
    until (Mode <> NoMode) or EOF(FileRead);

    if (Mode <> NoMode) and not StringHas(TempString, 'DUPE') then
      begin
        ExpandTabs(TempString);
        BandString := Copy(TempString, LogEntryBandAddress, 3);
        ModeString := Copy(TempString, LogEntryModeAddress, 3);
        DateString := Copy(TempString, LogEntryDayAddress, 9);
        TimeString := Copy(TempString, LogEntryHourAddress, 2) +
          Copy(TempString, LogEntryMinuteAddress, 2);
        CallString := Copy(TempString, LogEntryCallAddress, 12);

        GetRidOfPostcedingSpaces(ModeString);
        GetRidOfPrecedingSpaces(BandString);
        GetRidOfPostcedingSpaces(CallString);

        if UseLogRST then
          RSTString := GetLogEntryRSTString(TempString)
        else
          if ModeString = 'SSB' then
            RSTString := '59'
          else
            RSTString := '599';

        if not PrintEnable then
          if (CallString = FirstCall) and
            (BandString = FirstBand) and
            (ModeString = FirstMode) then
            PrintEnable := true;

        if PrintEnable and not StringHas(TempString, 'DUPE') then
          begin
            WriteLn(FileWrite, Spaces, 'To: ', CallString, '  From: ', MyCall);
            WriteLn(FileWrite, Spaces, '------------------------------');
            WriteLn(FileWrite, Spaces, 'Confirming ', BandString, ModeString, ' QSO at ', TimeString, 'Z');
            if ModeString = 'SSB' then
              WriteLn(FileWrite, Spaces, 'on ', DateString, '.  Your RS was ', RSTString)
            else
              WriteLn(FileWrite, Spaces, 'on ', DateString, '. Your RST was ', RSTString);
            WriteLn(FileWrite, Spaces, Signature);
            WriteLn(FileWrite);
//        Viewform.c.Clear;
//        Viewform.c.Lines.LoadFromFile(FileName);
//        Viewform.ShowModal;

          end;
      end;

    if Eof(FileRead) then
      begin
        Close(FileRead);
        Close(FileWrite);
        view(FileName);
        Exit;
      end;
  until False;

end;

function SignatureWithName(Signature: Str80;
  Call: CallString;
  MaximumNameLength: integer): Str80;

var
  NameString                  : CallString;
  Count                       : integer;

begin
  if not StringHas(Signature, '%') then
    begin
      SignatureWithName := Signature;
      Exit;
    end;

  NameString := CD.GetName(RootCall(Call));

  if (NameString = '') or (NameString = 'CLUB') then
    NameString := 'OM';

  if (MaximumNameLength <> 0) and (length(NameString) > MaximumNameLength) then
    NameString := 'OM';

  SignatureWithName := PrecedingString(Signature, '%') +
    NameString + ' ' +
    PostcedingString(Signature, '%');
end;

procedure PrintSpecificLabels;

var
  Call, TempString, FileName  : Str80;
  BandString, ModeString, CallString, FileString: string;
  Band                        : BandType;
  Mode                        : ModeType;
  MyCall, DateString,
    TimeString, StationsName, NewName, RSTString, Signature: Str80;
  Destination, Key            : Char;
  DoingNames                  : boolean;
  FileWrite                   : Text;
  MaximumNameLength           : integer;
  NameFileWrite               : Text;
  FileRead                    : Text;

begin
    //ClrScr;
    //TextColor (Yellow);
{  WriteLnCenter('PRINT SINGLE LABELS FOR SPECIFIC STATIONS');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This procedure will search your log file for contacts with a specific      ');
  WriteLn('station and allow you to print a label for any of the contacts found.');
  WriteLn('The labels are in the same format as the one label per QSO procedure:');
  WriteLn;
  WriteLn(Spaces, 'To: WB6ZVC  From: 4U1ITU');
  WriteLn(Spaces, '------------------------------');
  WriteLn(Spaces, 'Confirming 40SSB QSO at 0000Z ');
  WriteLn(Spaces, 'on 25-Dec-90.  Your RS was 59');
  WriteLn(Spaces, 'Signature                    ');
  WriteLn;
  WriteLn('You can enter up to thirty characters as your signature.  You can also ');
  WriteLn('enter names into the database when checking QSOs.  You can also include');
  WriteLn('the stations name from the name database in the signature with %.');
  WriteLn;
}
  if not FileExists(LogFileName) then
    begin
      ShowMessage('No logfile file found.');
        //WaitForKeyPressed;
      Exit;
    end;

  MyCall := UpperCase(postform.SelFromEdit.Text);
  if MyCall = '' then Exit;

  Signature := postform.SelSignEdit.Text;
  {
  repeat
    Signature := GetResponse('Enter signature (max 30 chars) : ');
    if length(Signature) > 30 then
      SHOWMESSAGE('That signature is too long!!');
  until length(Signature) <= 30;
}

{  repeat
    Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
    case Destination of
      'F': begin
          WriteLn;
          FileName := UpperCase(GetResponse('Enter filename to save QSL data to : '));

          if FileName = UpperCase(LogFileName) then
          begin
            SHOWMESSAGE('Output file must be different than active log file!!');
                     //WaitForKeyPressed;
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

  FileName := postform.SelFileEdit.Text;
  if FileName = UpperCase(LogFileName) then
    begin
      ShowMessage('Output file must be different than active log file!!');
      Exit;
    end;
  if FileName = '' then Exit;

  if not OpenFileForWrite(FileWrite, FileName) then
    begin
      ShowMessage('Unable to open output file or device.');
      Exit;
    end;

//  SetUpSpaces;
{
  if Destination = 'P' then
  begin
    repeat
      Key := UpCase(GetKey('Do you need to align the printer? (Y/N) : '));
      if Key = EscapeKey then exit;
    until (Key = 'Y') or (Key = 'N');
    WriteLn;

    if Key = 'Y' then
    begin
            //TextColor (Cyan);
      WriteLn('Press S for sample, A to adjust spaces, or any other to go on.');
      repeat
//                REPEAT UNTIL KeyPressed;
//                Key := UpCase (ReadKey);

        if Key = 'A' then SetUpSpaces;

        if Key = 'S' then
        begin
          WriteLn(FileWrite, Spaces, 'To: WB6ZVC  From: ', MyCall);
          WriteLn(FileWrite, Spaces, '------------------------------');
          WriteLn(FileWrite, Spaces, 'Confirming 40CW QSO at 0000Z ');
          WriteLn(FileWrite, Spaces, 'on 25-Dec-90.  Ur RST was 599');
          WriteLn(FileWrite, Spaces, Signature);
          WriteLn(FileWrite);
        end;

      until Key <> 'S';
    end;
        //GoToXY (1, WhereY);
        //ClrEol;
  end;
}
  DoingNames := postform.SelEntNamCB.Checked; //'Y' = GetKeyResponse('Do you want to enter names? (Y, N) : ');

  if DoingNames then
    begin
      ShowMessage('New names will be saved in the file NAMES.NEW.'#13' You can add this to your TRMASTER database.');
      OpenFileForAppend(NameFileWrite, 'NAMES.NEW');
    end;

//  repeat
  Call := postform.SelCallEdit.Text;    // UpperCase(GetResponse('Enter call to print labels for (none to stop) : '));

  if Call = '' then
    begin
      Close(FileWrite);

      if DoingNames then
        begin
          postform.cm.Lines.Add('Name file saved as NAMES.NEW.');
          Close(NameFileWrite);
        end;

      Exit;
    end;

  if DoingNames then
    begin
      StationsName := CD.GetName(Call);

      if StationsName = '' then
        begin
          NewName := GetResponse(Call + #13 + #13 + 'Enter name : ' {+ Beep});
          if NewName <> '' then
            WriteLn(NameFileWrite, Call, ' ', NewName);
        end
      else
        begin
//        Write('Name = ', StationsName);
//                IF CWEnable THEN SendMorse (StationsName);

          NewName := GetResponse('Name = ' + StationsName + #13 + 'Enter new name if any:');

          if NewName <> '' then
            WriteLn(NameFileWrite, Call, ' ', NewName);
        end;
    end;

  if not OpenFileForRead(FileRead, LogFileName) then
    begin
      ShowMessage('Unable to open ' + LogFileName);

      if DoingNames then
        begin
          postform.cm.Lines.Add('Name file saved as NAMES.NEW.');
          Close(NameFileWrite);
                //WaitForKeyPressed;
        end;

            //WaitForKeyPressed;
      Exit;
    end;

  while not Eof(FileRead) do
    begin
      if OperatorEscape then
        begin
          Close(FileRead);

          if DoingNames then
            begin
              postform.cm.Lines.Add('Name file saved as NAMES.NEW.');
              Close(NameFileWrite);
                    //WaitForKeyPressed;
            end;

          Exit;
        end;

      ReadLn(FileRead, FileString);

      if StringHas(FileString, Call) then
        begin
          ExpandTabs(FileString);

          RSTString := GetResponse(Copy(FileString, LogEntryBandAddress, 3) + ' ' + Copy(FileString, LogEntryModeAddress, 3) + ' ' + Copy(FileString, LogEntryDayAddress, 9) + ' ' + Copy(FileString, LogEntryHourAddress, 2) + ' ' + Copy(FileString, LogEntryMinuteAddress, 2) + ' ' + Copy(FileString, LogEntryCallAddress, 12) {FileString} + #13 + #13 + 'Enter RST to be used on label for this contact'#13'("Cancel" for skip):');
          if RSTString <> '' then
            begin
              Band := GetLogEntryBand(FileString);
              Mode := GetLogEntryMode(FileString);

              if Mode <> NoMode then
                begin
                  BandString := Copy(FileString, LogEntryBandAddress, 3);
                  ModeString := Copy(FileString, LogEntryModeAddress, 3);
                  DateString := Copy(FileString, LogEntryDayAddress, 9);
                  TimeString := Copy(FileString, LogEntryHourAddress, 2) +
                    Copy(FileString, LogEntryMinuteAddress, 2);
                  CallString := Copy(FileString, LogEntryCallAddress, 12);

                  GetRidOfPostcedingSpaces(ModeString);
                  GetRidOfPrecedingSpaces(BandString);
                  GetRidOfPostcedingSpaces(CallString);

                  if not GoodCallSyntax(CallString) then
                    CallString := GetResponse('Enter callsign of this station : ');

                  WriteLn(FileWrite, Spaces, 'To: ', CallString, '  From: ', MyCall);
                  WriteLn(FileWrite, Spaces, '------------------------------');
                  WriteLn(FileWrite, Spaces, 'Confirming ', BandString, ModeString, ' QSO at ', TimeString, 'Z');
                  if ModeString = 'SSB' then
                    WriteLn(FileWrite, Spaces, 'on ', DateString, '.  Your RS was ', RSTString)
                  else
                    WriteLn(FileWrite, Spaces, 'on ', DateString, '. Your RST was ', RSTString);
                  WriteLn(FileWrite, Spaces, SignatureWithName(Signature, CallString, MaximumNameLength));

                end;
            end;
        end;
    end;
  Close(FileRead);
  Close(FileWrite);
  view(FileName);
//  until False;
end;

procedure PrintLabelsThree;

var
  FirstCall, LastCall         : CallString;
  FileRead                    : Text;
  Destination, Key            : Char;
  DoingNames, UseLogRST, PrintEnable, AlphabeticalOrder: boolean;
  StartCountry, FinishCountry, Country: integer;
  TempContactData             : ContactRecord;
  Call, DefaultRST            : Str20;
  Signature1, Signature2, TempString, FileName: Str80;
  FileString                  : string;
  TotalNumberQSLs, QSLLabel, Block, Address, QSLLabelAddress, QSO: integer;
  MaximumName1Length, MaximumName2Length, TotalQSOs: integer;
  CountryTotalArray           : CountryTotalArrayType;
  FileWrite                   : Text;

begin
    //ClrScr;
    //TextColor (Yellow);
{  WriteLnCenter('PRINT UP TO THREE QSOs PER LABEL PROCEDURE');
    //TextColor (Cyan);
  WriteLn;
  WriteLn('This procedure will combine up to three QSOs with the same station onto a ');
  WriteLn('single 15/16th inch label.  If you have more than 3 QSOs with the station,');
  WriteLn('a second label will be printed.  You can sort the labels into alphabetical');
  WriteLn('order if you want.  You can enter two different signatures that will appear');
  WriteLn('on any blank lines.');
  WriteLn;
}
  if not FileExists(LogFileName) then
    begin
      ShowMessage('No logfile file found.');
      Exit;
    end;
{
  repeat
    Key := UpCase(GetKey('Use RSTs from the (L)og or (D)efault RST? (L/D) : '));
    if Key = EscapeKey then exit;
  until (Key = 'L') or (Key = 'D');
  WriteLn;
}

  if not postform.RSTLogRb.Checked then
{//  if Key = 'D' then}
    begin
      DefaultRST := postform.DefRSTEdit.Text; //GetResponse('Enter default RST : ');
      UseLogRST := False;
    end
  else
    UseLogRST := true;

  FirstCall := postform.FcallEdit1.Text; //UpperCase(GetResponse('Enter first call to print label for (return for start of log) : '));
  LastCall := postform.LCallEdit1.Text; //UpperCase(GetResponse('Enter last call to print label for (return for end of log) :  '));

  PrintEnable := FirstCall = '';

{  repeat
    Key := UpCase(GetKey('Sort labels in alphabetical order within each country? (Y/N) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');
  WriteLn;
 }AlphabeticalOrder := postform.SortLabels.Checked; //Key = 'Y';

    //TextColor (Cyan);
{  WriteLn;
  WriteLn('The first signature you will enter will appear if there is at least one     ');
  WriteLn('blank line on the label.  The second will appear after the first if there');
  WriteLn('are two blank lines on the label.  Each must be 30 characters or less.');
  WriteLn('You can use the special character % to fetch a name from the name database.');
  WriteLn('If no name exists, the name OM will appear instead.  Do not put a space after');
  WriteLn('the % character.');
  WriteLn;
}
  MaximumName1Length := 12 {0};         //wli
  MaximumName2Length := 12 {0};         //wli
  Signature1 := postform.FSEdit.Text;
  Signature2 := postform.SSEdit.Text;
  {
  repeat
    Signature1 := GetResponse('Enter first signature : ');

    if StringHas(Signature1, '%') then
      MaximumName1Length := GetValue('Enter maximum length of name to use (6-12) : ');

    if length(Signature1) + MaximumName1Length > 30 then
      SHOWMESSAGE('Too many characters!!');

  until length(Signature1) <= 30;

  repeat
    Signature2 := GetResponse('Enter second signature : ');

    if StringHas(Signature2, '%') then
      MaximumName2Length := GetValue('Enter maximum length of name to use (6-12) : ');

    if length(Signature2) + MaximumName2Length > 30 then
      SHOWMESSAGE('Too many characters!!');

  until length(Signature2) <= 30;
}
{  WriteLn;
    //TextColor (Cyan);
  WriteLn('You can print up to three QSOs per label.  However, if you want to always   ');
  WriteLn('print at least the first signature, you can limit the number of lines to two.');
  WriteLn('If you want to always print both signatures, you can limit the number of');
  WriteLn('lines to one.');
  WriteLn;

  repeat
    Key := UpCase(GetKey('Enter the maximum number of QSOs per label (1-3) : '));
    if Key = EscapeKey then exit;
  until (Key = '1') or (Key = '2') or (Key = '3');
  WriteLn;

  case Key of
    '1': NumberContactsPerLabel := 1;
    '2': NumberContactsPerLabel := 2;
    '3': NumberContactsPerLabel := 3;
  end;
}
  NumberContactsPerLabel := postform.QSOPerLab.Value;
  DoingNames := False;
  FileName := postform.FNEdit.Text;
{
  repeat
    Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
    case Destination of
      'F': begin
          WriteLn;
          FileName := UpperCase(GetResponse('Enter filename to save QSL data to : '));

          if FileName = UpperCase(LogFileName) then
          begin
            SHOWMESSAGE('Output file must be different than active log file!!');
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
  if not OpenFileForWrite(FileWrite, FileName) then
    begin
      ShowMessage('Unable to open output file or device.');
      Exit;
    end;

//  SetUpSpaces;
{
  if Destination = 'P' then
  begin
    WriteLn('Press S for sample label, A to adjust spaces, or P to start printing.');

    repeat
//            REPEAT UNTIL KeyPressed;
//            Key := UpCase (ReadKey);

      if Key = 'A' then SetUpSpaces;

      if Key = 'S' then
      begin
        WriteLn(FileWrite, Spaces, '      TO RADIO: WB6ZVC');
        WriteLn(FileWrite, Spaces, 'BAND    DATE     UTC   RST  2X');
        WriteLn(FileWrite, Spaces, ' 10  10-Dec-90  13:03  599  CW');
        WriteLn(FileWrite, Spaces, '160  23-Dec-90  01:47  579  CW');
        WriteLn(FileWrite, Spaces, ' 20   7-Jan-91  03:24  59  SSB');
        WriteLn(FileWrite);
      end;
    until Key = 'P';
  end;
}
    //ClrScr;
    //TextColor (Cyan);
//  WriteLn;
  postform.cm.Lines.Add('Computing QSO totals for each country...');
  ComputeCountryTotals(CountryTotalArray, TotalQSOs);

  postform.cm.Lines.Add('Total QSOs found in log = ' + inttostr(TotalQSOs));
  if TotalQSOs = 0 then Exit;

//  WriteLn;
  postform.cm.Lines.Add('Sorting out countries with fewer than 20 QSOs into temp file...');
  CreateSmallCountryTempFile(CountryTotalArray);

  if FirstCall = '' then
    StartCountry := 0
  else
    StartCountry := CountryTable.GetCountry(FirstCall, true);

  if LastCall = '' then
    FinishCountry := CountryTable.NumberCountries - 1
  else
    FinishCountry := CountryTable.GetCountry(LastCall, true);

//  WriteLn('Press ESCAPE to stop print.');

  if StringHas(Signature1, '%') or StringHas(Signature2, '%') then
    if (CD.SCPIndexArray <> nil) or CD.LoadInIndexArray then
      DoingNames := true;

  TotalNumberQSLs := 0;

  for Country := 0 to CountryTable.NumberCountries - 1 do
    if CountryTotalArray[Country] > 0 then
      begin
        //GoToXY (1, WhereY);
        //ClrEol;
        postform.cm.Lines.Add('Processing ' + CountryTable.GetCountryName(Country) + ' with ' + inttostr(CountryTotalArray[Country]) + ' QSOs.');
        QSLData.NumberLabels := 0;

        if CountryTotalArray[Country] < 20 then
          FileName := QSLTempFileName
        else
          FileName := LogFileName;

        if not OpenFileForRead(FileRead, FileName) then
          begin
            ShowMessage(FileName + ' has disappeared!!');
            Exit;
          end;

        while not Eof(FileRead) do
          begin
            if OperatorEscape then
              begin
                Close(FileRead);
                Close(FileWrite);
                DeleteFile(QSLTempFileName);
                Exit;
              end;

            ReadLn(FileRead, FileString);

            TempContactData.Band := GetLogEntryBand(FileString);

            if (TempContactData.Band <> NoBand) and not StringHas(FileString, 'DUPE') then
              begin
                ExpandTabs(FileString);
                Call := GetLogEntryCall(FileString);

                if Country = CountryTable.GetCountry(Call, true) then
                  begin
                    TempContactData.Mode := GetLogEntryMode(FileString);
                    TempContactData.Date := GetLogEntryDateString(FileString);
                    TempContactData.Time := GetLogEntryTimeString(FileString);
                    if UseLogRST then
                      TempContactData.RST := GetLogEntryRSTString(FileString)
                    else
                      TempContactData.RST := DefaultRST;
                    AddQSLDataToLabels(Call, TempContactData);
                  end;
              end;
          end;

        Close(FileRead);

        SetUpPointerArray;

        if AlphabeticalOrder then SortQSLLabelData;

        if QSLData.NumberLabels > 0 then
          begin
            TotalNumberQSLs := TotalNumberQSLs + QSLData.NumberLabels;
            for QSLLabel := 0 to QSLData.NumberLabels - 1 do
              begin
                QSLLabelAddress := PointerArray^[QSLLabel];
                Block := QSLLabelAddress div QSLLabelBlockSize + 1;
                Address := QSLLabelAddress mod QSLLabelBlockSize;

                with QSLData.Blocks[Block]^[Address] do
                  begin
                    if not PrintEnable then
                      if Callsign = FirstCall then PrintEnable := true;

{            if OperatorEscape then
            begin
              Close(FileRead);
              Close(FileWrite);
              Dispose(PointerArray);
              DeleteFile(QSLTempFileName);
              exit;
            end;
}
                    if PrintEnable then
                      begin
                        WriteLn(FileWrite, Spaces, '      TO RADIO: ', Callsign);
                        WriteLn(FileWrite, Spaces, 'BAND    DATE     UTC   RST  2X');

                        for QSO := 1 to 3 do
                          with ContactArray[QSO] do
                            begin
                              if NumberContacts >= QSO then
                                begin
                                  Write(FileWrite, Spaces, BandString[Band], '  ');
                                  Write(FileWrite, Date, '  ', Time, '  ', RST, '  ', ModeString[Mode]);
                                end
                              else
                                case QSO of
                                  2:
                                    if DoingNames then
                                      Write(FileWrite, Spaces, SignatureWithName(Signature1,
                                        Callsign,
                                        MaximumName1Length))
                                    else
                                      Write(FileWrite, Spaces, Signature1);

                                  3:
                                    if NumberContacts = 1 then
                                      begin
                                        if DoingNames then
                                          Write(FileWrite, Spaces, SignatureWithName(Signature2,
                                            Callsign,
                                            MaximumName2Length))
                                        else
                                          Write(FileWrite, Spaces, Signature2);
                                      end
                                    else
                                      if DoingNames then
                                        Write(FileWrite, Spaces, SignatureWithName(Signature1,
                                          Callsign,
                                          MaximumName1Length))
                                      else
                                        Write(FileWrite, Spaces, Signature1);
                                end;
                              WriteLn(FileWrite);
                            end;

                        WriteLn(FileWrite);
                        if Callsign = LastCall then
                          begin
                            Close(FileWrite);
                            DeleteFile(QSLTempFileName);
                            //TextColor (Cyan);
                            postform.cm.Lines.Add(LastCall + ' has been found.  Printing stopped.');
                            Dispose(PointerArray);
                            //WaitForKeyPressed;
                            Exit;
                          end;
                      end;
                  end;
              end;

            ClearQSLDataMemory;
          end;

        Dispose(PointerArray);
      end;

  Close(FileWrite);
  view(postform.FNEdit.text);
  DeleteFile(QSLTempFileName);
  postform.cm.Lines.Add('All ' + inttostr(TotalNumberQSLs) + ' labels printed.');


end;

function QSLProcedureMenu: boolean;

var
  Key                         : Char;

begin
  QSLProcedureMenu := true;
    //ClrScr;
    //TextColor (Yellow);
  WriteLnCenter('QSL PROCEDURE MENU');
  WriteLn;
    //TextColor (Cyan);
  WriteLn('  C - Confirm contacts with no labels printed.');
  WriteLn('  E - Estimate number of QSL labels.');
  WriteLn('  O - Print labels, one QSO per label.');
  WriteLn('  S - Print labels for QSOs with a selected station.');
  WriteLn('  T - Print labels, up to three QSOs per label.');
  WriteLn('  V - View log segments.');
  WriteLn('  X - Exit QSL Procedure Menu');
  WriteLn;
    //TextColor (Cyan);
  Write('  Enter command : ');

  repeat
//        REPEAT UNTIL KeyPressed;
//        Key := UpCase (ReadKey);

    case Key of
      'C':
        begin
          ConfirmContacts;
          Exit;
        end;
      'E':
        begin
          EstimateNumberOfLabels;
          Exit;
        end;
      'O':
        begin
          PrintLabelsOne;
          Exit;
        end;
      'S':
        begin
          PrintSpecificLabels;
          Exit;
        end;
      'T':
        begin
          PrintLabelsThree;
          Exit;
        end;
      'V':
        begin
          ViewLog;
          Exit;
        end;

      'X', EscapeKey:
        begin
          QSLProcedureMenu := False;
          Exit;
        end;
    end;
  until False;
end;

begin
end.

