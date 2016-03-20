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
unit LOGSend;

{$IMPORTEDDATA OFF}
interface

uses
  TF,
utils_text,
  Tree,
  uCallSignRoutines,
  VC,
  Messages,
  Windows,
  LogWind,
  LogDupe,
  LogStuff,
  ZoneCont,
  //Country9,
  LogEdit,
  LogCW,
  LOGDVP,
  LogDom, {Printer,}
  LogK1EA,
//  Help,
  LogGrid, {Crt,}
  LogSCP,
  BeepUnit,
  uWinKey
  ;

procedure SendCrypticDVPString(SendString: ShortString);
procedure SendCrypticCWString(SendString: Str160);
procedure SendCrypticDigitalString(SendString: Str160);
procedure SendDVKMessage(Message: Str20);
implementation

uses uTelnet,
  MainUnit;

procedure SendCrypticDVPString(SendString: ShortString);

var
  FileName                              : ShortString;
  i                                     : integer;
  QSONumber                             : integer;
begin
  if (not DVKEnable) or (not CWEnabled) then Exit;
//  if not DVPEnabled then Exit;

  while SendString <> '' do
  begin

    FileName := RemoveFirstString(SendString);
    GetRidOfPrecedingSpaces(FileName);
    if DVPMessagesArrayIndex = DVPArraySize then Exit;
    if FileName = '#' then
    begin
      QSONumber := TotalContacts + 1;
      if AutoQSONumberDecrement then
        if (ActiveMainWindow = awCallWindow)
        //if tr4w_CallWindowActive
        and (CallWindowString = '') and (ExchangeWindowString = '') then dec(QSONumber);
      FileName := IntToStr(QSONumber);
    end;

    if FileName = '@' then
      if CallWindowString <> '' then FileName := CallWindowString;

    if (StringHas(FileName, '.WAV')) or tUseRecordedSigns then
    begin
      DVPMessagesArray[DVPMessagesArrayIndex] := FileName;
      inc(DVPMessagesArrayIndex);
      if DVPThreadID = 0 then
      begin
        DVPOn := True;
        tExitFromDVPThread := False;
        DisplayCodeSpeed;
        tCreateThread(@tDVPPlayThreadproc, DVPThreadID);
      end;
    end;

  end;

end;

procedure SendCrypticCWString(SendString: Str160);

{ Control-A will put the message out on the InactiveRadio and set the flag
  InactiveRadioSendingCW.  It does not change the ActiveRadio any more.

  If you decide to answer someone who responds to CW on the inactive radio,
  you will want to call SwapRadios.  This will now make Control-A messages
  be sent on the new inactive radio (which is probably what you want).   }

var
  CharPointer, NumberCharsBeingSent, CharacterCount, QSONumber: integer;
  Result, Entry, Offset                 : integer;
  Key, SendChar, TempChar               : Char;
  CommandMode, WarningSounded           : boolean;
  TempCall                              : CallString;
  TempString                            : Str80;
  i                                     : integer;
  TempReceivedData                      : ContestExchange;
  pendingCWBuffer                       : Str50;
begin
// For CQ TEST NY4I , this sends the C, then the Q, then T, then E, then S, then T, then NY4I

// Why doesn't it send the whole thing.  I know..it is because it processed each character. The call is a single character  (\)
// So, it's more efficient to use \ than NY4I
// I wonder if this could be improved to buffer the characters? // 4.44.5

  if CWEnabled = False then Exit;
  if length(SendString) = 0 then Exit;
  //SetSpeed(DisplayedCodeSpeed); //ny4i This seems superflous. The speed should be set already


  //SetPTT;

  NumberCharsBeingSent := 0;

  CommandMode := False;
  DebugMsg('CrypticCWString = [' + SendString + ']');
  //    FOR CharacterCount := 1 TO Length (SendString) DO
  CharacterCount := 1;
  repeat
    begin
      SendChar := SendString[CharacterCount];

      if CommandMode then
      begin
        case SendChar of
          '@':
            if StringHas(CallWindowString, '?') then
              AddStringToBuffer(' ' + CallWindowString, CWTone);

        else AddStringToBuffer(ControlLeftBracket + SendChar, CWTone);
        end;
        CommandMode := False;
        Continue;
      end;



       case SendChar of
           '^':
            AddStringTOBuffer('',CWTone);

           '.':
          begin
          AddStringToBuffer('.', CWTone);     // n4af 04.35.2
 {            case SendString[CharacterCount + 1] of
              'T':
                begin
                  AddStringToBuffer(TimeString, CWTone);
                  inc(CharacterCount);
                end;
             end;    }
            end;

        '#':
          begin
            QSONumber := TotalContacts + 1;

            if TailEnding then inc(QSONumber);

            if AutoQSONumberDecrement then
              //              if (ActiveWindow = CallWindow) and
//              if tr4w_CallWindowActive and
              if (ActiveMainWindow = awCallWindow) and
                (CallWindowString = '') and (ExchangeWindowString = '') then
                dec(QSONumber);

            if length(SendString) >= CharacterCount + 2 then
            begin
              TempChar := SendString[CharacterCount + 1];

              if TempChar = '+' then
              begin
                TempChar := SendString[CharacterCount + 2];
                Val(TempChar, Offset, Result);
                if Result = 0 then
                begin
                  QSONumber := QSONumber + Offset;
                  CharacterCount := CharacterCount + 2;
                end;
              end;

              if TempChar = '-' then
              begin
                TempChar := SendString[CharacterCount + 2];
                Val(TempChar, Offset, Result);
                if Result = 0 then
                begin
                  QSONumber := QSONumber - Offset;
                  CharacterCount := CharacterCount + 2;
                end;
              end;
            end;

            TempString := QSONumberString(QSONumber);

            while LeadingZeros > length(TempString) do
              TempString := LeadingZeroCharacter + TempString;

            if ShortIntegers then
              for CharPointer := 1 to length(TempString) do
              begin
                if TempString[CharPointer] = '0' then TempString[CharPointer] := Short0;
                if TempString[CharPointer] = '1' then TempString[CharPointer] := Short1;
                if TempString[CharPointer] = '2' then TempString[CharPointer] := Short2;
                if TempString[CharPointer] = '9' then TempString[CharPointer] := Short9;
              end;

            AddStringToBuffer(TempString, CWTone);
          end;

        '_': AddStringToBuffer(' ', CWTone);

        ControlD:
          if CWStillBeingSent then AddStringToBuffer(' ', CWTone);

        '*':
          begin //KK1L: 6.72 New character to send Alt-D dupe checked call or call in call window
            if (DupeInfoCall <> '') and (DupeInfoCall <> EscapeKey) then
              AddStringToBuffer(DupeInfoCall, CWTone)
            else
            begin
              if CallsignUpdateEnable then
              begin
                TempString := GetCorrectedCallFromExchangeString(ExchangeWindowString);

                if TempString <> '' then
                begin
                  CallWindowString := TempString;
                  CallsignICameBackTo := TempString;
                end;
              end;

              if CallWindowString <> '' then
                AddStringToBuffer(CallWindowString, CWTone);
            end;
          end;

        '@':
          begin
            if CallsignUpdateEnable then
            begin
              TempString := ExchangeWindowString;
              TempString := GetCorrectedCallFromExchangeString(TempString);

              if TempString <> '' then
              begin
                CallWindowString := TempString;
                CallsignICameBackTo := TempString;
              end;
            end;

            if CallWindowString <> '' then
              AddStringToBuffer(CallWindowString, CWTone);
          end;

        '$':
          if SayHiEnable and (Rate < SayHiRateCutOff) then SayHello(CallWindowString);
        '%':
          if SayHiEnable and (Rate < SayHiRateCutOff) then SayName(CallWindowString);

        ':':
          begin
            RITEnable := False;
            ProcessMenu(menu_ctrl_sendkeyboardinput);
            RITEnable := True;
          end;
  
        '~': SendSalutation(CallWindowString);
        '\': AddStringToBuffer(MyCall, CWTone);
        '&': AddStringToBuffer(MyState, CWTone);

        '|':
          begin
            TempString := ExchangeWindowString;
            GetRidOfPrecedingSpaces(TempString);
            GetRidOfPostcedingSpaces(TempString);
            Windows.ZeroMemory(@TempReceivedData, SizeOf(TempReceivedData));
            ProcessExchange(TempString, TempReceivedData);
            if TempReceivedData.Name <> '' then
              AddStringToBuffer(TempReceivedData.Name + ' ', CWTone);
          end;

        '[':
          begin
            WarningSounded := False;

            //            QuickDisplay('WAITING FOR YOU ENTER STRENGTH OF RST (Single digit)!!');
            //            AddStringToBuffer('5', CWTone);
            if WaitForStrength then
              i := QuickEditInteger(TC_WAITINGFORYOUENTERSTRENGTHOFRST, 1)
            else i := 9;

            //            Key := '0';

                              {                 REPEAT
                                                   REPEAT
                                                       IF NOT CWStillBeingSent THEN
                                                           BEGIN
                                                           IF NOT WaitForStrength THEN
                                                               BEGIN
                                                               Key := '9';
                                                               Break;
                                                               END
                                                           ELSE
                                                               IF NOT WarningSounded THEN
                                                                   BEGIN
                                                                   WarningSounded := True;
                                                                   DoABeep (ThreeHarmonics);
                                                                   END;
                                                           END;

                                                   UNTIL KeyPressed;

                                                   IF Key <> '9' THEN Key := ReadKey;

                                               UNTIL ((Key >= '1') AND (Key <= '9')) OR (Key = EscapeKey);
                              }

  {                       if Key = EscapeKey then
                        begin
                          FlushCWBufferAndClearPTT;
                          Exit;
                        end;
  }
            if i = -1 then
            begin
              FlushCWBufferAndClearPTT;
              Exit;
            end;

            Key := IntToStr(i)[1];
            if i = 9 then
              AddStringToBuffer('5NN', CWTone)
            else
              AddStringToBuffer('5' + Key + 'N', CWTone);
            ReceivedData.RSTSent := 509 + i * 10;

            LastRSTSent := ReceivedData.RSTSent;
          end;

        ']': AddStringToBuffer(IntToStr(LastRSTSent), CWTone);

        '{': AddStringToBuffer(ReceivedData.Callsign, CWTone);

        '}':
          if StringHas(ReceivedData.Callsign, '/') or
            ((length(ReceivedData.Callsign) = 4) and SendCompleteFourLetterCall) or
            StringHas(CallsignICameBackTo, '/') then
            AddStringToBuffer(ReceivedData.Callsign, CWTone)
          else
            if GetPrefix(ReceivedData.Callsign) =
              GetPrefix(CallsignICameBackTo) then
            begin
              TempString := GetSuffix(ReceivedData.Callsign);
              if length(TempString) = 1 then
                TempString := Copy(ReceivedData.Callsign, length(ReceivedData.Callsign) - 1, 2);
              AddStringToBuffer(TempString, CWTone);
            end
            else
              if GetSuffix(ReceivedData.Callsign) =
                GetSuffix(CallsignICameBackTo) then
                AddStringToBuffer(GetPrefix(ReceivedData.Callsign), CWTone)
              else
                AddStringToBuffer(ReceivedData.Callsign, CWTone);

        ')': AddStringToBuffer(VisibleLog.LastEntry(False, letCallsign), CWTone);

        '(':
          if TotalContacts = 0 then
          begin
            if MyName <> '' then
              AddStringToBuffer(MyName, CWTone)
            else
              AddStringToBuffer(MyPostalCode, CWTone);
          end
          else
          begin

            AddStringToBuffer(VisibleLog.LastEntry(False, letQTHString), CWTone);
 {
            TempString := '';
            Entry := 5;

            while (TempString = '') and (Entry >= 0) do
            begin
              TempString := VisibleLog.LastName(Entry);
               dec(Entry);
            end;

            AddStringToBuffer(TempString, CWTone);
}
          end;

        ControlW: AddStringToBuffer(VisibleLog.LastName(4), CWTone);

        ControlR:
          begin
            ReceivedData.RandomCharsSent := '';

            repeat
              ReceivedData.RandomCharsSent :=
                ReceivedData.RandomCharsSent +
                CHR(Random(25) + Ord('A'));
            until length(ReceivedData.RandomCharsSent) = 5;

            AddStringToBuffer(ReceivedData.RandomCharsSent, CWTone);

            //                      SaveSetAndClearActiveWindow (DupeInfoWindow);
            //                      Write ('Sent = ', ReceivedData.RandomCharsSent);
            //                      RestorePreviousWindow;
          end;

        ControlT: AddStringToBuffer(ReceivedData.RandomCharsSent, CWTone);

        ControlU:
          begin
            TempCall := GetCorrectedCallFromExchangeString(ExchangeWindowString);

            if TempCall <> '' then
              CallsignICameBackTo := TempString
            else
              CallsignICameBackTo := CallWindowString;

            ShowStationInformation(@CallsignICameBackTo);
          end;

        ControlLeftBracket: CommandMode := True;

      else AddStringToBuffer(SendChar, CWTone);
      end;
      inc(CharacterCount);

    end;
  until CharacterCount = length(SendString) + 1;
  //   Frm.SendCW(CWTone, message_to_send);
  //   message_to_send := '';

//  ClearPTTForceOn;
 { if (wkActive) and (not wkBusy) then
     begin
     flushcwbuffer;
     end;
  }
  InactiveRigCallingCQ := False;
  if IsCWByCATActive then
     begin
     AddStringToBuffer(CWByCATBufferTerminator,CWTone); // Flushes the buffer when the $242 is passed to SendCW - by only By CAT
     end;

//if if ActiveRadioPtr^.CWByCAT then backtoinactiveradioafterqso;
end;


procedure SendCrypticDigitalString(SendString: Str160);

{ Control-A will put the message out on the InactiveRadio and set the flag
  InactiveRadioSendingCW.  It does not change the ActiveRadio any more.

  If you decide to answer someone who responds to CW on the inactive radio,
  you will want to call SwapRadios.  This will now make Control-A messages
  be sent on the new inactive radio (which is probably what you want).   }

//var
//  CharPointer, NumberCharsBeingSent, CharacterCount, QSONumber: integer;
//  RESULT, Entry, Offset                 : integer;
//  Key, SendChar, TempChar               : Char;
//  TempCall                              : CallString;
//  WarningSounded                        : boolean;
//  TempString                            : str80;

begin
  {    IF Length (SendString) = 0 THEN Exit;

      IF NOT RTTYTransmissionStarted THEN
          StartRTTYTransmission ('');

      NumberCharsBeingSent := 0;

      FOR CharacterCount := 1 TO Length (SendString) DO
          BEGIN
          SendChar := SendString [CharacterCount];

          CASE SendChar OF
              '#': BEGIN
                   QSONumber := TotalContacts + 1;

                   IF TailEnding THEN Inc (QSONumber);

                   IF AutoQSONumberDecrement THEN
                       IF (ActiveWindow = CallWindow) AND
                          (CallWindowString = '') AND (ExchangeWindowString = '') THEN
                              Dec (QSONumber);

                   IF Length (SendString) >= CharacterCount + 2 THEN
                       BEGIN
                       TempChar := SendString [CharacterCount + 1];

                       IF TempChar = '+' THEN
                           BEGIN
                           TempChar := SendString [CharacterCount + 2];
                           Val (TempChar, Offset, Result);
                           IF Result = 0 THEN
                               BEGIN
                               QSONumber := QSONumber + Offset;
                               CharacterCount := CharacterCount + 2;
                               END;
                           END;

                       IF TempChar = '-' THEN
                           BEGIN
                           TempChar := SendString [CharacterCount + 2];
                           Val (TempChar, Offset, Result);
                           IF Result = 0 THEN
                               BEGIN
                               QSONumber := QSONumber - Offset;
                               CharacterCount := CharacterCount + 2;
                               END;
                           END;
                       END;

                   TempString := QSONumberString (QSONumber);

                   WHILE LeadingZeros > Length (TempString) DO
                       TempString := LeadingZeroCharacter + TempString;

                   ContinueRTTYTransmission (TempString);
                   END;

              '*': BEGIN {KK1L: 6.72 New character to send Alt-D dupe checked call or call in call window}
  {                 IF (DupeInfoCall <> '') AND (DupeInfoCall <> EscapeKey) THEN
                       AddStringToBuffer (DupeInfoCall, CWTone)
                   ELSE
                       BEGIN
                       IF (CallsignUpdateEnable) AND (TempString <> '') THEN
                           BEGIN
                           TempString := GetCorrectedCallFromExchangeString (ExchangeWindowString);

                           IF TempString <> '' THEN
                               BEGIN
                               CallWindowString := TempString;
                               CallsignICameBackTo := TempString;
                               END;
                           END;

                       IF CallWindowString <> '' THEN
                           ContinueRTTYTransmission (CallWindowString);
                       END;
                   END;

              '@': BEGIN
                   IF CallsignUpdateEnable THEN
                       BEGIN
                       TempString := GetCorrectedCallFromExchangeString (ExchangeWindowString);

                       IF TempString <> '' THEN
                           BEGIN
                           CallWindowString := TempString;
                           CallsignICameBackTo := TempString;
                           END;
                       END;

                  IF CallWindowString <> '' THEN
                       ContinueRTTYTransmission (CallWindowString);
                  END;

              ':': BEGIN
                   SendKeysToRTTY;
                   END;

              '\': ContinueRTTYTransmission (MyCall);

              '|': IF ReceivedData.Name <> '' THEN
                       ContinueRTTYTransmission (ReceivedData.Name + ' ');

              '[': BEGIN
                   WarningSounded := False;

                   QuickDisplay ('WAITING FOR YOU ENTER STRENGTH OF RST (Single digit)!!');

                   ContinueRTTYTransmission ('5');

                   Key := '0';

                   REPEAT
                       REPEAT
                           IF NOT CWStillBeingSent THEN
                               BEGIN
                               IF NOT WaitForStrength THEN
                                   BEGIN
                                   Key := '9';
                                   Break;
                                   END
                               ELSE
                                   IF NOT WarningSounded THEN
                                       BEGIN
                                       WarningSounded := True;
                                       DoABeep (ThreeHarmonics);
                                       END;
                               END;

                       UNTIL KeyPressed;

                       IF Key <> '9' THEN Key := ReadKey;

                   UNTIL ((Key >= '1') AND (Key <= '9')) OR (Key = EscapeKey);

                   IF Key = EscapeKey THEN
                       BEGIN
                       FinishRTTYTransmission ('');
                       Exit;
                       END;

                   IF Key = '9' THEN
                       ContinueRTTYTransmission ('NN')
                   ELSE
                       ContinueRTTYTransmission (Key + 'N');

                   ReceivedData.RSTSent := '5' + Key + '9';
                   LastRSTSent := ReceivedData.RSTSent;
                   END;

              ']': ContinueRTTYTransmission (LastRSTSent);

              '{': ContinueRTTYTransmission (ReceivedData.Callsign);

              ')': ContinueRTTYTransmission (VisibleLog.LastCallsign);

              '(': IF TotalContacts = 0 THEN
                       BEGIN
                       IF MyName <> '' THEN
                           ContinueRTTYTransmission (MyName)
                       ELSE
                           ContinueRTTYTransmission (MyPostalCode);
                       END
                   ELSE
                       BEGIN
                       TempString := '';
                       Entry := 5;

                       WHILE (TempString= '') AND (Entry > 0) DO
                           BEGIN
                           TempString := VisibleLog.LastName (Entry);
                           Dec (Entry);
                           END;

                       ContinueRTTYTransmission (TempString);
                       END;

              ControlW: ContinueRTTYTransmission (VisibleLog.LastName (4));

              ControlR: BEGIN
                        ReceivedData.RandomCharsSent := '';

                        REPEAT
                            ReceivedData.RandomCharsSent :=
                              ReceivedData.RandomCharsSent +
                              Chr (Random (25) + Ord ('A'));
                        UNTIL Length (ReceivedData.RandomCharsSent) = 5;

                        ContinueRTTYTransmission (ReceivedData.RandomCharsSent);

                        SaveSetAndClearActiveWindow (DupeInfoWindow);
                        Write ('Sent = ', ReceivedData.RandomCharsSent);
                        RestorePreviousWindow;
                        END;

              ControlT: ContinueRTTYTransmission (ReceivedData.RandomCharsSent);

              ControlU: BEGIN
                        TempCall := GetCorrectedCallFromExchangeString (ExchangeWindowString);

                        IF TempCall <> '' THEN
                            CallSignICameBackTo := TempString
                        ELSE
                            CallsignICameBackTo := CallWindowString;

                        ShowStationInformation (CallsignICameBackTo);
                        END;

              ELSE ContinueRTTYTransmission (SendChar);
              END;
          END;

      FinishRTTYTransmission ('');
     }
end;

procedure SendDVKMessage(Message: Str20);

begin
{
  Message := UpperCase(Message);

  if (Message = 'DVK0') or DVKMessagePlaying then //KK1L: 6.71 If already playing then stop it first
  begin
    StartDVK(0);
    DVKPlaying := False;
  end;

  if Message = 'DVK1' then
  begin
    StartDVK(1);
    DVKStamp;
  end;

  if Message = 'DVK2' then
  begin
    StartDVK(2);
    DVKStamp;
  end;

  if Message = 'DVK3' then
  begin
    StartDVK(3);
    DVKStamp;
  end;

  if Message = 'DVK4' then
  begin
    StartDVK(4);
    DVKStamp;
  end;

  if Message = 'DVK5' then //KK1L: 6.71
  begin
    StartDVK(5);
    DVKStamp;
  end;

  if Message = 'DVK6' then //KK1L: 6.71
  begin
    StartDVK(6);
    DVKStamp;
  end;
}
end;

begin
end.

