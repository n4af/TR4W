unit LOGWAE;

{$IMPORTEDDATA OFF}
interface

uses
  uCallSignRoutines,
  Windows,
  Tree,
  uQTCS,
  uTotal,
  VC,
  TF,
  //Country9,
  ZoneCont,
  LogSCP,
  LogWind,
  LogCW,
  //LOGDDX,
  LogDupe,
  LogStuff,
  LogGrid,
//  Help,
  LogK1EA,
  LOGDVP,
  LogDom,
  PostUnit,
  LogEdit
  ;

type
  QTCActionType = (NoQTCAction, AbortThisQTC, SaveThisQTC);

  TQTCsToBeSend = record
   {02}qsID: Word;
   {02}qsTime: Word;
   {04}qsNumber: integer;
   {04}qsQSOID1: Cardinal;
   {04}qsQSOID2: Cardinal;
   {14}qsCall: CallString;
   {01}qsReserved1: Byte;
   {01}qsReserved2: Byte;
  end;

var
  QTCsToBeSendArray                     : array[1..10] of TQTCsToBeSend;
  QTCExtraSpace                         : boolean = True;
//  QTCNote                          : Str80;
  QTCQRS                                : boolean = True;
  QTCNumber                             : integer;
  NumberMessagesToBeSentString {, QTCNumberString}: string;

  QRVString                             : array[0..160] of Char;

  //  QTCBuffer                        : LogEntryArray;
  {MaxQTCString, }QTCCallsign           : CallString;
  NumberQTCsAlreadySent                 : integer;

  NumberMessagesToBeSent, {MessageINT, } MaxQTCsThisStation: integer;
const
  QTCTOP                                = 15;
  QTCHEIGHT                             = 22;
  QTCROWSDIS                            = 2;

//procedure WAEQTC(var QTCCallsign: CallString);
procedure WAEQTC2;
procedure LastQTCSent(var Call: CallString; var Time: Str20; var QSONumber: integer);
function NumberAvailableQTCsForThisCall(Call: CallString): integer;

implementation
uses uQTCR,
  MainUnit;

function QTCQuickEditResponse(Prompt: Str80;
  var QTCAction: QTCActionType;
  var ControlEnterUsed: boolean): Str80;

var
  TempString, InputString               : Str80;
  Key, PreviousCursorChar               : Char;
  CursorPosition, StartOfInputCursorPosition, RememberX, CharPointer: integer;

begin
  {    QTCAction := NoQTCAction;

      ControlEnterUsed := False;

      SaveSetAndClearActiveWindow (QuickCommandWindow);

      Write (Prompt);

      StartOfInputCursorPosition := WhereX;

      InputString := '';

      REPEAT
          REPEAT UNTIL NewKeyPressed;

          Key := UpCase (NewReadKey);

          CASE Key OF
              EscapeKey:
                  IF CWStillBeingSent THEN
                      FlushCWBufferAndClearPTT
                  ELSE
                      IF InputString <> '' THEN
                          BEGIN
                          GoToXY (WhereX - Length (InputString), WhereY);
                          ClrEol;
                          InputString := '';
                          END
                      ELSE
                          BEGIN
                          GoToXY (1, WhereY);

                          Write ('Do you want to (A)bort, (C)ontinue or (S)ave this QTC? : ');

                          REPEAT
                              REPEAT UNTIL KeyPressed;
                              Key := UpCase (ReadKey);
                          UNTIL (Key = 'A') OR (Key = 'C') OR (Key = 'S');

                          CASE Key OF
                              'A': BEGIN
                                   QTCAction := AbortThisQTC;
                                   ClrScr;
                                   Exit;
                                   END;

                              'C': BEGIN
                                   ClrScr;
                                   Write (Prompt);
                                   END;

                              'S': BEGIN
                                   QTCAction := SaveThisQTC;
                                   ClrScr;
                                   Exit;
                                   END;
                              END;
                          END;

              BackSpace:
                  IF Length (InputString) > 0 THEN
                      IF WhereX > StartOfInputCursorPosition THEN
                          BEGIN
                          Delete (InputString, WhereX - StartOfInputCursorPosition, 1);
                          RememberX := WhereX;
                          GoToXY (RememberX - 1, WhereY);
                          ClrEol;
                          Write (Copy (InputString, WhereX - StartOfInputCursorPosition + 1, 50));
                          GoToXY (RememberX - 1, WhereY);
                          END;

              ControlA:
                  BEGIN
                  CursorPosition := WhereX - StartOfInputCursorPosition + 1;

                  IF CursorPosition > 1 THEN
                      BEGIN
                      REPEAT
                          Dec (CursorPosition);
                          PreviousCursorChar := InputString [CursorPosition - 1];
                      UNTIL ((InputString [CursorPosition] <> ' ') AND
                             (PreviousCursorChar = ' ')) OR (CursorPosition = 1);
                      GoToXY (CursorPosition + StartOfInputCursorPosition - 1, WhereY);
                      END;
                  END;

              ControlD:
                  IF WhereX - StartOfInputCursorPosition < Length (InputString) + 1 THEN
                      GoToXY (WhereX + 1, WhereY);

              ControlF:
                  BEGIN
                  CursorPosition := WhereX - StartOfInputCursorPosition + 1;

                  IF CursorPosition <= Length (InputString) THEN
                      BEGIN
                      REPEAT
                          PreviousCursorChar := InputString [CursorPosition];
                          Inc (CursorPosition);
                      UNTIL ((InputString [CursorPosition] <> ' ') AND
                             (PreviousCursorChar = ' ')) OR (CursorPosition = Length (InputString) + 1);
                      GoToXY (CursorPosition + StartOfInputCursorPosition - 1, WhereY);
                      END;
                  END;

              ControlG:
                  IF WhereX - StartOfInputCursorPosition + 1 <= Length (InputString) THEN
                      BEGIN
                      Delete (InputString, WhereX - StartOfInputCursorPosition + 1, 1);
                      RememberX := WhereX;
                      ClrEol;
                      Write (Copy (InputString, WhereX - StartOfInputCursorPosition + 1, 50));
                      GoToXY (RememberX, WhereY);
                      END;

              ControlJ:  // Might be ControlCarriageReturn
                  IF Port [$60] <> $24 THEN
                      BEGIN
                      ControlEnterUsed := True;

                      TempString := InputString;

                      RemoveFirstString (TempString);
                      RemoveFirstString (TempString);

                      IF TempString <> '' THEN
                          BEGIN
                          QTCQuickEditResponse := InputString;
                          RemoveAndRestorePreviousWindow;
                          Exit;
                          END;

                      Exit;
                      END;

              ControlS:
                  IF WhereX - StartOfInputCursorPosition >= 1 THEN
                      GoToXY (WhereX - 1, WhereY);

              ControlT:
                  BEGIN
                  CursorPosition := WhereX - StartOfInputCursorPosition + 1;

                  IF CursorPosition <= Length (InputString) THEN
                      BEGIN
                      TempString := InputString;
                      TempString [0] := Chr (CursorPosition - 1);
                      CharPointer := CursorPosition;

                      REPEAT
                          Inc (CharPointer);
                      UNTIL (CharPointer = Length (InputString)) OR
                            (InputString [CharPointer] = ' ');

                      IF CharPointer = Length (InputString) THEN
                          BEGIN
                          ClrEOL;
                          InputString [0] := Chr (CursorPosition - 1);
                          END
                      ELSE
                          BEGIN
                          Inc (CharPointer);
                          FOR CharPointer := CharPointer TO Length (InputString) DO
                              TempString := TempString + InputString [CharPointer];

                          GoToXY (StartOfInputCursorPosition, WhereY);
                          ClrEOL;

                          Write (TempString);
                          InputString := TempString;
                          GoToXY (CursorPosition + StartOfInputCursorPosition - 1, WhereY);
                          END;
                      END
                  ELSE
                      IF CursorPosition = Length (InputString) THEN
                          BEGIN
                          ClrEol;
                          InputString [0] := Chr (Length (InputString) - 1);
                          END;
                  END;

              CarriageReturn:
                  BEGIN
                  TempString := InputString;

                  RemoveFirstString (TempString);
                  RemoveFirstString (TempString);

                  IF TempString <> '' THEN
                      BEGIN
                      QTCQuickEditResponse := InputString;
                      RemoveAndRestorePreviousWindow;
                      Exit;
                      END;
                  END;

              NullKey:
                  BEGIN
                  Key := ReadKey;

                  CASE Key OF
                      AltA: SendStringAndStop ('AGN');
                      AltC: SendStringAndStop ('CALL?');
                      AltK: ToggleCW (False);
                      AltN: SendStringAndStop ('NR?');
                      AltR: SendStringAndStop ('RPT?');
                      AltT: SendStringAndStop ('TIME?');

                      HomeKey: GoToXY (StartOfInputCursorPosition, 1);

                      LeftArrow:
                          IF WhereX - StartOfInputCursorPosition >= 1 THEN
                              GoToXY (WhereX - 1, WhereY);

                      RightArrow:
                          IF WhereX - StartOfInputCursorPosition < Length (InputString) + 1 THEN
                              GoToXY (WhereX + 1, WhereY);

                      EndKey:
                          GoToXY (Length (InputString) + StartOfInputCursorPosition , WhereY);

                      InsertKey:
                          BEGIN
                          InsertMode := NOT InsertMode;
                          DisplayInsertMode (InsertMode);
                          END;

                      DeleteKey:
                          IF WhereX - StartOfInputCursorPosition + 1 <= Length (InputString) THEN
                              BEGIN
                              Delete (InputString, WhereX - StartOfInputCursorPosition + 1, 1);
                              RememberX := WhereX;
                              ClrEol;
                              Write (Copy (InputString, WhereX - StartOfInputCursorPosition + 1, 50));
                              GoToXY (RememberX, WhereY);
                              END;

                      END;
                  END;

              ELSE
                  BEGIN
                  IF InsertMode THEN
                      BEGIN
                      Insert (Key, InputString, WhereX - StartOfInputCursorPosition + 1);
                      ClrEol;
                      RememberX := WhereX;
                      Write (Copy (InputString, WhereX - StartOfInputCursorPosition + 1, 50));
                      GotoXY (RememberX + 1, WhereY);
                      END
                  ELSE
                      BEGIN
                      IF WhereX - StartOfInputCursorPosition + 1 <= Length (InputString) THEN
                          InputString [WhereX - StartOfInputCursorPosition + 1] := Key
                      ELSE
                          InputString := InputString + Key;

                      Write (Key);
                      END;
                  END;

              END;  // of case

      UNTIL FALSE;
     }
end;

procedure WAEQTC(var QTCCallsign: CallString);

{ This procedure gets called whenever we are asking for a QTC.  It will
  handle everything needed to do the QTC.  It will return after everything
  has been done.  }

label
  SaveQTC, StopQTC, KeepGoing;

var
  QTCString, TempString                 : string;
  NumberMessagesString, MessageString   : Str80;
  MaxQTCString, CommandString           : Str80;
  NumberQTCsAlreadySent, NumberMessagesToBeSent, MaxQTCsThisStation: integer;
  //  FullTimeString                        : Str20;
  Line, Index, Result                   : integer;

  ControlEnterUsed, DataChanged, ValidKey: boolean;

  ExtendedKey, Key                      : Char;
  QTCAction                             : QTCActionType;

begin
  {
    QTCNote := '';

    LastQTCTimeSent := 'AA';

    if (DDXState <> Off) then
    begin
      if DDXState <> SAndPExchangeSentAndAskedForQTC then Exit;
      DDXState := QTCInProgress;
    end;

    if QTCCallsign = '' then
      if WindowDupeCheckCall <> '' then
      begin
        QTCCallsign := WindowDupeCheckCall;
        if ActiveWindow <> CallWindow then
        begin
                    //        SaveSetAndClearActiveWindow(CallWindow);
          Write(QTCCallsign);
                    //        RestorePreviousWindow;
        end
        else
        begin
  //        ClrScr;
          Write(QTCCallsign);

        end;
      end
      else
        Exit;

    if not GoodCallSyntax(QTCCallsign) then
    begin
      DoABeep(Warning);
      QuickDisplay('Invalid callsign in call window!!');
      Exit;
    end;

    QTCCallsign := StandardCallFormat(QTCCallsign, False);

    for Line := 1 to 5 do QTCBuffer[Line] := '';

    NumberQTCsAlreadySent := NumberQTCsThisStation(QTCCallsign);

    if NumberQTCsAlreadySent >= 10 then
    begin
      DoABeep(Warning);
      QuickDisplay('Sorry, you already have 10 QTCs with ' + QTCCallsign);
      Exit;
    end;

    MaxQTCsThisStation := 10 - NumberQTCsAlreadySent;
    Str(MaxQTCsThisStation, MaxQTCString);

    if MyContinent = Europe then // We are receiving QTCs
    begin
      if NumberQTCsAlreadySent = 0 then
        SendStringAndStop('QTC?')
      else
        SendStringAndStop('PSE ' + MaxQTCString + ' QTC?');

      ClearPTTForceOn;

      repeat
        TempString := QuickEditResponse('Enter QTC #/# (max of ' + MaxQTCString + ') or RETURN if QRU : ', 8);

        if TempString = EscapeKey then
          if CWStillBeingSent then
            FlushCWBufferAndClearPTT
          else
            Exit;

        if TempString = '' then Exit;
      until TempString <> EscapeKey;

      if not DetermineQTCNumberAndQuanity(TempString, QTCNumber, NumberMessagesToBeSent) then Exit;

      if NumberMessagesToBeSent > MaxQTCsThisStation then
      begin
        Str(MaxQTCsThisStation, TempString);
        AddStringToBuffer('PSE ONLY ' + TempString + ' QTCS ', CWTone);
        QuickDisplay('That is too many messages.  We will only take ' + TempString);
        NumberMessagesToBeSent := MaxQTCsThisStation;
      end;

      Str(NumberMessagesToBeSent, NumberMessagesToBeSentString);

      SendStringAndStop('QRV');

      MessageINT := 1;
      Str(QTCNumber, QTCNumberString);
           //    ClearWindow(EditableLogwindow);

      while MessageINT <= NumberMessagesToBeSent do
      begin
        Str(MessageINT, MessageString);

        KeepGoing:

        QTCString := QTCQuickEditResponse('Enter QTC #' + MessageString +
          ' of ' + NumberMessagesToBeSentString +
          ' : ', QTCAction, ControlEnterUsed);

        case QTCAction of

          AbortThisQTC:
            begin
              NextQTCToBeSent := NextQTCToBeSent - NumberMessagesToBeSent;
              DecrementQTCCount(QTCCallsign, MessageINT - 1);
              VisibleLog.SetUpEditableLog;
              DoABeep(Warning);
              QuickDisplay('QTC cancelled since it was not QSLed');
              Exit;
            end;

          SaveThisQTC:
            begin
              Dec(MessageINT);
              Str(MessageINT, MessageString);
              NumberMessagesToBeSent := -1;
              NumberMessagesToBeSentString := MessageString;
                          //            RestorePreviousWindow;
              goto SaveQTC;
            end;
        end;

        if not ControlEnterUsed then SendStringAndStop('R');

        AddQTCToQTCBuffer(QTCBuffer, QTCString, MessageINT);

        IncrementQTCCount(QTCCallsign);
        inc(MessageINT);
      end;

      repeat
        TempString := UpperCase(QuickEditResponse('Press RETURN to log or E to Edit : ', 1));
      until (TempString = '') or (TempString = 'E');

      if TempString = 'E' then
      begin
        QuickDisplay('You are editing the QTC data.  Press ESCAPE to exit.');
        EditWindowEditor(QTCBuffer, 5, 1, DataChanged);
      end;

      SendStringAndStop('QSL ' + QTCNumberString + '/' + MessageString);
    end

    else
    begin // We are sending QTCs
      NumberMessagesToBeSent := NumberAvailableQTCsForThisCall(QTCCallsign);

      if NumberMessagesToBeSent = 0 then
      begin
        SendStringAndStop('QRU');
        DoABeep(Warning);
        QuickDisplay('No QTCs pending, QRU.');
        Exit;
      end;

      if NumberMessagesToBeSent > MaxQTCsThisStation then
        NumberMessagesToBeSent := MaxQTCsThisStation;

      Str(NumberMessagesToBeSent, NumberMessagesToBeSentString);
      Str(NumberQTCBooksSent + 1, QTCNumberString);

      SendStringAndStop('QTC ' + QTCNumberString + '/' + NumberMessagesToBeSentString + ' QRV?');

      ClearPTTForceOn;

      if DDXState = QTCInProgress then
      begin
        repeat until not CWStillBeingSent;
        Wait(100);
        Wait(Random(300));
        AddStringToBuffer('QRV', DDXTone1);
      end;

           //    ClearWindow(EditableLogwindow);

      repeat
        CommandString := UpperCase(QuickEditResponse('Is ' + QTCCallsign + ' QRV for QTC '
          + QTCNumberString + '/' + NumberMessagesToBeSentString
          + '? (RETURN to start or ESCAPE to abort) : ', 1));

        if CommandString = EscapeKey then
        begin
          if CommandString = EscapeKey then
            if CWStillBeingSent then
              FlushCWBufferAndClearPTT
            else
            begin
              TempString := UpperCase(QuickEditResponse
                ('Do you really want to abort this QTC? (Y/N) : ', 1));

              if TempString = 'Y' then
              begin
                QuickDisplay('QTC aborted by operator.');
                VisibleLog.SetUpEditableLog;
                Exit;
              end;
            end;
        end;
      until CommandString = '';

      for MessageINT := 1 to NumberMessagesToBeSent do
      begin
                 //WLI
                 //            QTCString :=   PopNextQTCToBeSent (FullTimeString);

        FixUpQTCString(QTCString);

        if QTCQRS then
          SendStringAndStop(Controls + QTCString + ControlF)
        else
          SendStringAndStop(QTCString);

        AddQTCToQTCBuffer(QTCBuffer, FullTimeString, MessageINT);

        repeat
          if DDXState = QTCInProgress then
          begin
            QuickDisplay(QTCNumberString + '/' + NumberMessagesToBeSentString +
              '  RETURN-next  ESCAPE-abort  S-Stop  T-time  C-call  N-qso#  A-all');

            repeat
            until not CWStillBeingSent;
            Wait(100);
            Wait(Random(300));

            Index := Random(50);

            case Index of
              0, 1: AddStringToBuffer('AGN', DDXTone1);
              2, 3: AddStringToBuffer('CL?', DDXTone1);
              3, 4: AddStringToBuffer('NR?', DDXTone1);
              5: AddStringToBuffer('QTR?', DDXTone1);
              6: AddStringToBuffer('Time?', DDXTone1);

            else
              begin
                AddStringToBuffer('R', DDXTone1);
                if MessageINT = NumberMessagesToBeSent then
                  if Index > 20 then
                    AddStringToBuffer(' QSL TU', DDXTone1)
                  else
                    AddStringToBuffer(' QSL 73 DE ' + QTCCallsign, DDXTone1);
              end;
            end;
            x end;

          repeat
            QuickDisplay(QTCNumberString + '/' + NumberMessagesToBeSentString +
              '  RETURN-next  ESCAPE-abort  S-Stop  T-time  C-call  N-qso#  A-all');

            ValidKey := True;
                       //WLI                    Key := UpCase (ReadKey);

            case Key of
              'A': SendStringAndStop(QTCString);

              'C':
                begin
                  TempString := QTCString;
                  RemoveFirstString(TempString);
                  TempString := RemoveFirstString(TempString);
                  SendStringAndStop(TempString);
                end;

              'N':
                begin
                  TempString := GetLastString(QTCString);
                  SendStringAndStop(TempString);
                end;

              'S':
                begin
                  Str(MessageINT, MessageString);
                  TempString := UpperCase(QuickEditResponse
                    ('Do you really want stop now? (Y/N) : ', 1));

                  if TempString = 'Y' then
                  begin
                    TempString := UpperCase(QuickEditResponse
                      ('Was message number ' + MessageString + ' confirmed (Y/N) : ', 1));

                    if TempString <> 'Y' then
                    begin
                                            //WLI                                     Dec (MessageINT);
                      Dec(NextQTCToBeSent);

                      if MessageINT = 0 then
                      begin
                        VisibleLog.SetUpEditableLog;
                        QuickDisplay('QTC aborted.  No messages were QSLed.');
                        Exit;
                      end;
                    end;

                    NumberMessagesToBeSent := MessageINT;
                    Str(NumberMessagesToBeSent, NumberMessagesToBeSentString);
                    goto StopQTC;
                  end;

                  QuickDisplay(QTCNumberString + '/' + NumberMessagesToBeSentString +
                    '  RETURN-next  ESCAPE-abort  S-Stop  T-time  C-call  N-qso#  A-all');
                end;

              'T': SendStringAndStop(PrecedingString(QTCString, ' '));

              CarriageReturn: ;

              NullKey:
                begin
                                //WLI                            ExtendedKey := ReadKey;

                  case ExtendedKey of

                                   //                  AltK: ToggleCW(False);

                    PageUpKey:
                      if CodeSpeed < 96 then
                      begin
                        SetSpeed(CodeSpeed + 3);
                        DisplayCodeSpeed(CodeSpeed, CWEnabled, DVPOn, ActiveMode);
                      end;

                    PageDownKey:
                      if CodeSpeed > 4 then
                      begin
                        SetSpeed(CodeSpeed - 3);
                        DisplayCodeSpeed(CodeSpeed, CWEnabled, DVPOn, ActiveMode);
                      end;

                  end;

                  ValidKey := False;
                end;

              EscapeKey:
                begin
                  if CWStillBeingSent then
                    FlushCWBufferAndClearPTT
                  else
                  begin
                    TempString := UpperCase(QuickEditResponse
                      ('Do you really want to abort the whole QTC? (Y/N) : ', 1));

                    if TempString = 'Y' then
                    begin
                      NextQTCToBeSent := NextQTCToBeSent - MessageINT;
                      VisibleLog.SetUpEditableLog;
                      QuickDisplay('QTC aborted by operator.');
                      Exit;
                    end;
                  end;

                  ValidKey := False;
                end;

            else ValidKey := False;
            end;
          until ValidKey;

        until Key = CarriageReturn;
      end;

      StopQTC:

      repeat
        TempString := UpperCase(QuickEditResponse('QSL ' +
          QTCNumberString +
          '/' +
          NumberMessagesToBeSentString +
          '? (Y/N) : ', 1));

        if TempString[1] = 'N' then
        begin
          NextQTCToBeSent := NextQTCToBeSent - NumberMessagesToBeSent;
          VisibleLog.SetUpEditableLog;
          QuickDisplay('QTC cancelled since it was not QSLed');
          Exit;
        end;
      until TempString[1] = 'Y';

      for MessageINT := 1 to NumberMessagesToBeSent do
        IncrementQTCCount(QTCCallsign);

      inc(NumberQTCBooksSent);
      QTCNumber := NumberQTCBooksSent;
      DisplayQTCNumber(NumberQTCsThisStation(StandardCallFormat(QTCCallsign, False)));
    end;

    SaveQTC:

    Str(QTCNumber, QTCNumberString);

    TempString := 'QTC ' + QTCNumberString + '/' + NumberMessagesToBeSentString +
      ' with ' + QTCCallsign + ' on ' + GetDateString + ' at ' +
      GetTimeString + ' on ' + BandString[ActiveBand] + ModeString[ActiveMode];

    if OpenFileForAppend(FileWrite, QTCFileName) then
    begin
      WriteLn(FileWrite);

      WriteLn(FileWrite, TempString);

      for Line := 1 to 5 do
        if QTCBuffer[Line] <> '' then
          WriteLn(FileWrite, QTCBuffer[Line]);

      Close(FileWrite);
    end;

    SaveQTCDataFile;
    DisplayQTCNumber(NumberQTCsThisStation(StandardCallFormat(CallWindowString, False)));
    VisibleLog.SetUpEditableLog;

    QTCNote := TempString;

    QuickDisplay(TempString);

    UpdateTotals2;

    if DDXState = QTCInProgress then DDXState := SAndPExchangeSent;
  }
end;

procedure WAEQTC2;

{ This procedure gets called whenever we are asking for a QTC.  It will
  handle everything needed to do the QTC.  It will return after everything
  has been done.  }

label
  SaveQTC, StopQTC, KeepGoing;

var
  TempString                            : string;
  NumberMessagesString                  : string;
  {  NumberMessagesToBeSentString,}CommandString: string;

  FullTimeString                        : Str20;
  MessageINT, Line, Index, Result       : integer;
  QTCBuffer                             : LogEntryArray;
  ControlEnterUsed, DataChanged, ValidKey: boolean;
  FileWrite                             : Text;
  ExtendedKey, Key                      : Char;
  QTCAction                             : QTCActionType;
  p                                     : PChar;
begin

//  QTCNote := '';

//  LastQTCTimeSent := 'AA';
  {
    if (DDXState <> Off) then
    begin
      if DDXState <> SAndPExchangeSentAndAskedForQTC then Exit;
      DDXState := QTCInProgress;
    end;
  }
  {
    if QTCCallsign = '' then
      if WindowDupeCheckCall <> '' then
      begin
        QTCCallsign := WindowDupeCheckCall;
        if ActiveWindow <> CallWindow then
        begin
                    //        SaveSetAndClearActiveWindow(CallWindow);
          Write(QTCCallsign);
                    //        RestorePreviousWindow;
        end
        else
        begin
  //        ClrScr;
          Write(QTCCallsign);

        end;
      end
      else
        Exit;
  }

  Windows.ZeroMemory(@QTCCallsign, 13);
  QTCCallsign := CallWindowString;
  if QTCCallsign = '' then QTCCallsign := VisibleLog.LastEntry(False,letCallsign);

  if QTCCallsign = '' then Exit;

  if not GoodCallSyntax(QTCCallsign) then
  begin
    DoABeep(Warning);
    QuickDisplay(TC_INVALIDCALLSIGNINCALLWINDOW);
    Exit;
  end;

  QTCCallsign := StandardCallFormat(QTCCallsign, False);

  //  for Line := 1 to 5 do QTCBuffer[Line] := '';

  NumberQTCsAlreadySent := NumberQTCsThisStation(QTCCallsign);

  if NumberQTCsAlreadySent >= 10 then
  begin
    DoABeep(Warning);
    p := @QTCCallsign[1];
    asm
    push p
    end;
    wsprintf(wsprintfBuffer, TC_SORRYYOUALREADYHAVE10QTCSWITH);
    asm add esp,12
    end;
    QuickDisplay(wsprintfBuffer);
    Exit;
  end;

  MaxQTCsThisStation := 10 - NumberQTCsAlreadySent;
//  Str(MaxQTCsThisStation, MaxQTCString);

  if MyContinent = Europe then // We are receiving QTCs
  begin
      {
          if NumberQTCsAlreadySent = 0 then
            SendStringAndStop('QTC?')
          else
            SendStringAndStop('PSE ' + MaxQTCString + ' QTC?');
      }
      //    ClearPTTForceOn;
      {
          repeat
            TempString := QuickEditResponse(PChar('Enter QTC #/# (max of ' + MaxQTCString + ') or RETURN if QRU'), 8);

            if TempString = EscapeKey then
              if CWStillBeingSent then
                FlushCWBufferAndClearPTT
              else
                Exit;

            if TempString = '' then Exit;
          until TempString <> EscapeKey;
      }

    SetMainWindowText(mweCall, @QTCCallsign[1]);
      {
          QTCHeaderString := QuickEditResponse(PChar('Enter QTC #/# (max of ' + MaxQTCString + ') or RETURN if QRU'), 8);

          if QTCHeaderString = '' then
          begin
            if CWStillBeingSent then FlushCWBufferAndClearPTT;
            Exit;
          end;
          if not DetermineQTCNumberAndQuanity(QTCHeaderString, QTCNumber, NumberMessagesToBeSent) then Exit;
      }
//    tDialogBox(62, @QTCRDlgProc);
      CreateModalDialog(230, 180, tr4whandle, @QTCRDlgProc, 0);

      //    ClearWindow(EditableLogwindow);

{
 while MessageINT <= NumberMessagesToBeSent do
 begin
   Str(MessageINT, MessageString);

   KeepGoing:

   QTCString := QTCQuickEditResponse('Enter QTC #' + MessageString +
     ' of ' + NumberMessagesToBeSentString +
     ' : ', QTCAction, ControlEnterUsed);

   case QTCAction of

     AbortThisQTC:
       begin
         NextQTCToBeSent := NextQTCToBeSent - NumberMessagesToBeSent;
         DecrementQTCCount(QTCCallsign, MessageINT - 1);
         VisibleLog.SetUpEditableLog;
         DoABeep(Warning);
         QuickDisplay('QTC cancelled since it was not QSLed');
         Exit;
       end;

     SaveThisQTC:
       begin
         Dec(MessageINT);
         Str(MessageINT, MessageString);
         NumberMessagesToBeSent := -1;
         NumberMessagesToBeSentString := MessageString;
                     //            RestorePreviousWindow;
         goto SaveQTC;
       end;
   end;

   if not ControlEnterUsed then SendStringAndStop('R');

   AddQTCToQTCBuffer(QTCBuffer, QTCString, MessageINT);

   IncrementQTCCount(QTCCallsign);
   inc(MessageINT);
 end;
}
{
 repeat
   TempString := UpperCase(QuickEditResponse('Press RETURN to log or E to Edit : ', 1));
 until (TempString = '') or (TempString = 'E');

 if TempString = 'E' then
 begin
   QuickDisplay('You are editing the QTC data.  Press ESCAPE to exit.');
   EditWindowEditor(QTCBuffer, 5, 1, DataChanged);
 end;

 SendStringAndStop('QSL ' + QTCNumberString + '/' + MessageString);
}
  end

  else

  begin // We are sending QTCs

    NumberMessagesToBeSent := NumberAvailableQTCsForThisCall(QTCCallsign);

    if NumberMessagesToBeSent = 0 then
    begin
      SendStringAndStop('QRU');
      DoABeep(Warning);
      QuickDisplay(TC_NOQTCSPENDINGQRU);
      Exit;
    end;

    if NumberMessagesToBeSent > MaxQTCsThisStation then NumberMessagesToBeSent := MaxQTCsThisStation;

    QTCNumber := NumberQTCBooksSent + 1;
{
    asm
    push NumberMessagesToBeSent
    push QTCNumber
    end;
}
    QRVString[0] := Char(Format(@QRVString[1], 'QTC %u/%u', QTCNumber, NumberMessagesToBeSent));
//    asm add esp,16 end;

    asm
    lea eax, [QRVString]
    call SendStringAndStop
    end;
    SendStringAndStop(' QRV?');

    asm
    lea eax, [QRVString+1]
    push eax
    lea eax, [QTCCallsign+1]
    push eax
    end;
    wsprintf(wsprintfBuffer, TC_ISQRVFOR);
    asm add esp,16
    end;

    if YesOrNo2(tr4whandle, wsprintfBuffer) <> IDOK then Exit;
    //tDialogBox(63, @QTCSDlgProc);
    CreateModalDialog(230, 160, tr4whandle, @QTCSDlgProc, 0);

      {
          ClearPTTForceOn;

          repeat
            CommandString := UpperCase(QuickEditResponse(PChar('Is ' + QTCCallsign + ' QRV for QTC '
              + QTCNumberString + '/' + NumberMessagesToBeSentString
              + '? (RETURN to start or ESCAPE to abort)'), 1));

            if CommandString = EscapeKey then
            begin
              if CommandString = EscapeKey then
                if CWStillBeingSent then
                  FlushCWBufferAndClearPTT
                else
                begin
                  TempString := UpperCase(QuickEditResponse
                    ('Do you really want to abort this QTC? (Y/N) : ', 1));

                  if TempString = 'Y' then
                  begin
                    QuickDisplay('QTC aborted by operator.');
                    VisibleLog.SetUpEditableLog;
                    Exit;
                  end;
                end;
            end;
          until CommandString = '';

          for MessageINT := 1 to NumberMessagesToBeSent do
          begin
                     //WLI
                     //            QTCString :=   PopNextQTCToBeSent (FullTimeString);

            FixUpQTCString(QTCString);

            if QTCQRS then
              SendStringAndStop(Controls + QTCString + ControlF)
            else
              SendStringAndStop(QTCString);

            AddQTCToQTCBuffer(QTCBuffer, FullTimeString, MessageINT);

            repeat

              repeat
                QuickDisplay(QTCNumberString + '/' + NumberMessagesToBeSentString +
                  '  RETURN-next  ESCAPE-abort  S-Stop  T-time  C-call  N-qso#  A-all');

                ValidKey := True;
                           //WLI                    Key := UpCase (ReadKey);

                case Key of
                  'A': SendStringAndStop(QTCString);

                  'C':
                    begin
                      TempString := QTCString;
                      RemoveFirstString(TempString);
                      TempString := RemoveFirstString(TempString);
                      SendStringAndStop(TempString);
                    end;

                  'N':
                    begin
                      TempString := GetLastString(QTCString);
                      SendStringAndStop(TempString);
                    end;

                  'S':
                    begin
                      Str(MessageINT, MessageString);
                      TempString := UpperCase(QuickEditResponse
                        ('Do you really want stop now? (Y/N) : ', 1));

                      if TempString = 'Y' then
                      begin
      //                  TempString := UpperCase(QuickEditResponse('Was message number ' + MessageString + ' confirmed (Y/N) : ', 1));

                        if TempString <> 'Y' then
                        begin
                                                //WLI                                     Dec (MessageINT);
                          Dec(NextQTCToBeSent);

                          if MessageINT = 0 then
                          begin
                            VisibleLog.SetUpEditableLog;
                            QuickDisplay('QTC aborted.  No messages were QSLed.');
                            Exit;
                          end;
                        end;

                        NumberMessagesToBeSent := MessageINT;
                        Str(NumberMessagesToBeSent, NumberMessagesToBeSentString);
                        goto StopQTC;
                      end;

                      QuickDisplay(QTCNumberString + '/' + NumberMessagesToBeSentString +
                        '  RETURN-next  ESCAPE-abort  S-Stop  T-time  C-call  N-qso#  A-all');
                    end;

                  'T': SendStringAndStop(PrecedingString(QTCString, ' '));

                  CarriageReturn: ;

                  NullKey:
                    begin
                                    //WLI                            ExtendedKey := ReadKey;

                      case ExtendedKey of

                                       //                  AltK: ToggleCW(False);

                        PageUpKey:
                          if CodeSpeed < 96 then
                          begin
                            SetSpeed(CodeSpeed + 3);
                            DisplayCodeSpeed(CodeSpeed, CWEnabled, DVPOn, ActiveMode);
                          end;

                        PageDownKey:
                          if CodeSpeed > 4 then
                          begin
                            SetSpeed(CodeSpeed - 3);
                            DisplayCodeSpeed(CodeSpeed, CWEnabled, DVPOn, ActiveMode);
                          end;

                      end;

                      ValidKey := False;
                    end;

                  EscapeKey:
                    begin
                      if CWStillBeingSent then
                        FlushCWBufferAndClearPTT
                      else
                      begin
                        TempString := UpperCase(QuickEditResponse
                          ('Do you really want to abort the whole QTC? (Y/N) : ', 1));

                        if TempString = 'Y' then
                        begin
                          NextQTCToBeSent := NextQTCToBeSent - MessageINT;
                          VisibleLog.SetUpEditableLog;
                          QuickDisplay('QTC aborted by operator.');
                          Exit;
                        end;
                      end;

                      ValidKey := False;
                    end;

                else ValidKey := False;
                end;
              until ValidKey;

            until Key = CarriageReturn;
          end;

          StopQTC:

          repeat
      //      TempString := UpperCase(QuickEditResponse('QSL ' + QTCNumberString + '/' + NumberMessagesToBeSentString + '? (Y/N) : ', 1));

            if TempString[1] = 'N' then
            begin
              NextQTCToBeSent := NextQTCToBeSent - NumberMessagesToBeSent;
              VisibleLog.SetUpEditableLog;
              QuickDisplay('QTC cancelled since it was not QSLed');
              Exit;
            end;
          until TempString[1] = 'Y';

          for MessageINT := 1 to NumberMessagesToBeSent do
            IncrementQTCCount(QTCCallsign);

          inc(NumberQTCBooksSent);
          QTCNumber := NumberQTCBooksSent;
          DisplayQTCNumber(NumberQTCsThisStation(StandardCallFormat(QTCCallsign, False)));
        }
  end;
  {
    SaveQTC:

    Str(QTCNumber, QTCNumberString);

    TempString := 'QTC ' + QTCNumberString + '/' + NumberMessagesToBeSentString +
      ' with ' + QTCCallsign + ' on ' + GetDateString + ' at ' +
      GetTimeString + ' on ' + BandString[ActiveBand] + ModeString[ActiveMode];

    if OpenFileForAppend(FileWrite, QTCFileName) then
    begin
      WriteLn(FileWrite);

      WriteLn(FileWrite, TempString);

      for Line := 1 to 5 do
        if QTCBuffer[Line] <> '' then
          WriteLn(FileWrite, QTCBuffer[Line]);

      Close(FileWrite);
    end;

    SaveQTCDataFile;
    DisplayQTCNumber(NumberQTCsThisStation(StandardCallFormat(CallWindowString, False)));
    VisibleLog.SetUpEditableLog;

    QTCNote := TempString;

    QuickDisplay(TempString);

    UpdateTotals2;

    if DDXState = QTCInProgress then DDXState := SAndPExchangeSent;
  }
end;

procedure LastQTCSent(var Call: CallString; var Time: Str20; var QSONumber: integer);

var
  FileString                            : Str80;
  FileRead                              : Text;
  LastFirstString, LastSecondString, TempString: string;

begin
{
  NumberQTCBooksSent := 0;

  if OpenFileForRead(FileRead, QTCFileName) then
  begin
    while not Eof(FileRead) do
    begin
      ReadLn(FileRead, FileString);

//      GetRidOfPostcedingSpaces(FileString);

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
}
end;

function NumberAvailableQTCsForThisCall(Call: CallString): integer;
label
  1, 2;
var
//  QTC, NumberQTCsPending           : integer;
//  CompressedCall                   : EightBytes;
  h                                     : HWND;
  QTCs                                  : integer;
begin
  Result := 0;
  if not OpenLogFile then Exit;
  QTCs := 0;
  ReadVersionBlock;
  Windows.ZeroMemory(@QTCsToBeSendArray, SizeOf(QTCsToBeSendArray));
  QTCsToBeSendArray[1].qsID := NET_THIS_QTC_WAS__SEND_ID;
  1:
  if ReadLogFile then
  begin
    if GoodLookingQSO then
      if TempRXData.ceDupe = False then
      begin
        if (TempRXData.ceWasSendInQTC = False) and (TempRXData.Callsign <> Call) then
        begin
          inc(QTCs);
          QTCsToBeSendArray[QTCs].qsTime := TempRXData.tSysTime.qtHour * 100 + TempRXData.tSysTime.qtMinute;
          QTCsToBeSendArray[QTCs].qsCall := TempRXData.Callsign;
          QTCsToBeSendArray[QTCs].qsNumber := TempRXData.NumberReceived;
          QTCsToBeSendArray[QTCs].qsQSOID1 := TempRXData.ceQSOID1;
          QTCsToBeSendArray[QTCs].qsQSOID2 := TempRXData.ceQSOID2;
        end;
        if QTCs = 10 then goto 2;
      end;
    goto 1;
  end;
  2:
  CloseLogFile;
  Result := QTCs;
{
  NumberQTCsPending := TotalPendingQTCs;

  if NumberQTCsPending = 0 then
  begin
    NumberAvailableQTCsForThisCall := 0;
    Exit;
  end;

  if NumberQTCsPending > 10 then
    NumberQTCsPending := 10;

//BigCompressFormat(Call, CompressedCall);

  for QTC := 0 to NumberQTCsPending - 1 do
//    if BigCompressedCallsAreEqual(CompressedCall, PendingQTCArray^[NextQTCToBeSent + QTC].Call) then
    if PendingQTCArray^[NextQTCToBeSent + QTC].Call = Call then
    begin
      NumberAvailableQTCsForThisCall := QTC;
      Exit;
    end;

  NumberAvailableQTCsForThisCall := NumberQTCsPending;
}
end;

end.

