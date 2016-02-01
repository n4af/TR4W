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
unit LOGSUBS2;
{$IMPORTEDDATA OFF}
{ $ O + }
interface

uses
  uMMTTY,
  uCallSignRoutines,
//  uSCP,
  uIO,
  MMSystem,
  utils_net,
  utils_text,
  utils_file,
//  uTrayBalloon,
  uMP3Recorder,
  uWinKey,
  uAltD,
  uCTYDAT,
//  uMultsFrequencies,
//  uStack,
  uStations,
  uCallsigns,
  uCommctrl,
  //  uMMTTY,
  uEditQSO,
  uTelnet,
  TF,
//  DLPortIO,

  VC,
  //TR,
  uSpots,
  Windows,
  Messages,
  idUDPClient,
  idGlobal,
  WinSock2,
  PostUnit,
  uTotal,
  uNet,
  BeepUnit,
  LOGSUBS1,
  //Country9,
  FCONTEST,
  Math,  // ny4i 4.44.9
  {JCtrl1,}
  {JCtrl2,}
  CFGCMD,
  LogCfg,
  LogCW,
  LogDom,
  LogDupe,
  //LOGDDX,
  LOGDVP,
  LogEdit,
  LogGrid,
//  Help,
//  LOGHP,
  LogK1EA,
//  LOGMENU,
  LogNet,
  LogPack,
//  LOGPROM,
  LogRadio, { Currently not an overlay }
  LOGSend,
  LogSCP,
  LogStuff,
  LOGWAE,
  LogWind,
  {Printer,}
  {Crt,
  SlowTree,}
  SysUtils,
  Tree,
  ZoneCont
  ;

procedure LogContactToUDP(RXData: ContestExchange); // ny4i
procedure ToggleModes;
procedure ToggleStereoPin; {KK1L: 6.71}
procedure LogContact(var RXData: ContestExchange; MyComputer: boolean);
procedure SwapMultDisplay;
procedure PushLogStringIntoEditableLogAndLogPopedQSO(LogString: ShortString {Str80}; MyQSO: boolean);
procedure DeleteLastContact;
//procedure MoveEditableLogIntoLogFile;
procedure DoAltZ({var WindowString: string { VAR KeyChar: CHAR});
function WindowDupeCheck: boolean;
function SearchAndPounce: boolean;
function FoundCommand(var SendString: Str160): boolean;
procedure ShowPartialCallMults(WindowString: CallPtr {CallString});
procedure DupeCheckOnInactiveRadio(Tune: boolean);
function GotExchange: boolean;
procedure ProcessExchangeFunctionKey(ExtendedKey: Char);
procedure ExitProgram(Ask: boolean);
procedure CheckMultiState;
procedure GoToNextBandMapFrequency;
procedure GoToNextMultBandMapFrequency;
procedure GoToNextDisplayedBandMapFrequency;
procedure GoToNextMultDisplayedBandMapFrequency;
function tAddQSOToLog(RXData: ContestExchange): boolean;


implementation

uses
  //OZCHR,
  uProcessCommand,
  MainUnit,
  uRadioPolling;

procedure CreateAndSendPacketSpot(PacketSpotCall: CallString; PacketSpotFreq: LONGINT);
var
  TempStr1, TempStr2, TempString        : string;
begin
{
  TempStr1 := PrecedingString(PacketSpotCall, '/');
  TempStr2 := PostcedingString(PacketSpotCall, '/');

  if (TempStr1 = 'CQ') and StringIsAllNumbers(TempStr2) then
    Exit;

  if PacketSpotPrefixOnly then
    PacketSpotCall := GetPrefix(PacketSpotCall)
  else
    if not GoodCallSyntax(PacketSpotCall) then
      Exit;

  if PacketSpotFreq = 0 then Exit;

  Str(PacketSpotFreq, TempString);

  Delete(TempString, length(TempString) - 1, 2);
  Insert('.', TempString, length(TempString));

  TempString := 'DX ' + TempString + ' ' + PacketSpotCall + ' ' + PacketSpotComment;

  if PacketSpotEditEnable then
  begin
    TempString := TempString + ' ';
      //    SaveSetAndClearActiveWindow(QuickCommandWindow);
    TempString := LineInput('Spot = ', TempString, False, False);
      //    RestorePreviousWindow;
  end;

  if (TempString <> '') and (TempString <> EscapeKey) then
  begin
    if Packet.PacketSerialPort <> Tree.NoPort then
    begin
      Packet.SendPacketMessage(TempString + CarriageReturn);
          //      QuickDisplay('Sent to packet : ' + TempString);
    end
    else
    begin

      if K1EANetworkEnable then
      begin
        SendMultiMessage('A' + K1EAStationID + TempString);
      end
      else
        SendMultiCommand(Tree.MultiBandAddressArray[ActiveBand],
          $FF, MultiPacketMessageToSend, TempString + CarriageReturn);

      QuickDisplay('Sent to packet via network : ' + TempString);
    end;
  end;
}
end;

procedure PutContactIntoLogFile(LogString: string {Str80});

var
  Time, QSONumber, Result               : integer;
  Call, LoggedCallsign                  : Str20;
  Exchange                              : string; {20}

  FileWrite                             : Text;
  TempString                            : Str20;

begin
  {
    if Copy(LogString, 1, 1) = ';' then
    begin
      WriteLogEntry(LogString);
      Exit;
    end;

    GetRidOfPostcedingSpaces(LogString);

    if LogString <> '' then
    begin
      if LogString[LogEntryNameSentAddress] = '*' then
        inc(TotalNamesSent);

      if QSOTotals[Tree.All, Tree.Both] mod ContactsPerPage = 0 then
      begin
        if QSOTotals[Tree.All, Tree.Both] > 0 then
          NextPage;
        PrintLogHeader;
      end;

      if QSOTotals[Tree.All, Tree.Both] mod ContactsPerPage > 9 then
        if QSOTotals[Tree.All, Tree.Both] mod 10 = 0 then
          WriteLogEntry('');

      VisibleLog.PutLogEntryIntoSheet(LogString);
      WriteLogEntry(LogString);

      if UnknownCountryFileEnable then
      begin
        LoggedCallsign := GetLogEntryCall(LogString);
        if CountryTable.GetCountry(LoggedCallsign, True) = -1 then
          if OpenFileForAppend(FileWrite, UnknownCountryFileName) then
          begin
            WriteLn(FileWrite, LogString);
            Close(FileWrite);
          end;
      end;

           // We only add QSOs to the pending list if we got QSO points for it

      if QTCsEnabled and (MyContinent <> Europe) and
        (GetLogEntryQSOPoints(LogString) > 0) then
      begin
        Time := GetLogEntryIntegerTime(LogString);
        Call := GetLogEntryCall(LogString);
        Exchange := GetLogEntryExchangeString(LogString);
        GetRidOfPrecedingSpaces(Exchange);
        Exchange := PostcedingString(Exchange, ' ');
        GetRidOfPrecedingSpaces(Exchange);
        Exchange := PostcedingString(Exchange, ' ');
        GetRidOfPrecedingSpaces(Exchange);
        GetRidOfPostcedingSpaces(Exchange);
        Val(Exchange, QSONumber, RESULT);
        AddQSOToPendingQTCList(Time, Call, QSONumber);
      end;

      if SingleBand <> All then
      begin
        if GetLogEntryBand(LogString) = SingleBand then
          TotalQSOPoints := TotalQSOPoints + GetLogEntryQSOPoints(LogString);
      end
      else
        TotalQSOPoints := TotalQSOPoints + GetLogEntryQSOPoints(LogString);
    end;
   }
end;

procedure PushLogStringIntoEditableLogAndLogPopedQSO(LogString: ShortString {Str80};
  MyQSO: boolean);

var
  RData                                 : ContestExchange;
  TempString                            : string;

begin
  {
    if (ActiveMultiPort <> NoPort) and SendQSOImmediately and MyQSO then
    begin
      GetRidOfPostcedingSpaces(LogString);

      if ((LogString <> '') and not MultiMultsOnly) or
        (GetLogEntryMultString(LogString) <> '') then
        if K1EANetworkEnable then
        begin

                    // Don't send notes

          if LogString[1] <> ';' then
          begin
            TempString := ConvertN6TRLogStringToK1EANetworkFormat(LogString);
            SendMultiMessage(TempString);
          end;

        end
        else
        begin
          SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF, MultiQSOData, LogString);
        end;
    end;
  }
  //  LogString := VisibleLog.PushLogEntry(LogString);

     { LogString is now what popped off the top of the editable window }

  GetRidOfPostcedingSpaces(LogString);

  if LogString <> '' then
  begin
    PutContactIntoLogFile(LogString);

    if ParseExchangeIntoContestExchange(LogString, RData) then
    begin
      ProcessPartialCallAndInitialExchange(RData);
          {
                if (ActiveMultiPort <> NoPort) and (not SendQSOImmediately) then
                begin
                  if (not MultiMultsOnly) or
                    (GetLogEntryMultString(LogString) <> '') then
                    if K1EANetworkEnable then
                    begin

                                        // Don't send notes

                      if Copy(LogString, 1, 1) <> ';' then
                      begin
                        TempString := ConvertN6TRLogStringToK1EANetworkFormat(LogString);
                        SendMultiMessage(TempString);
                      end;

                    end
                    else
                    begin
                      SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF, MultiQSOData, LogString);
                    end;
                end

                else // QSO doesn't make sense - probably a note

                  if (ActiveMultiPort <> NoPort) and (not SendQSOImmediately) then
                    if K1EANetworkEnable then
                    begin

                                     // I don't know how to do this on the K1EA network

                    end
                    else
                    begin
                      SendMultiCommand(MultiBandAddressArray[ActiveBand],
                        $FF, MultiQSOData, LogString);
                    end;
                   }
    end;
  end;
end;

procedure ProcessCallWindowCommand(Command: Str80);

{ This procedure gets called if a command in the call window was typed in
  starting with a \ character. }

var
  Result, ThisBreak                     : integer;
  Freq                                  : LONGINT;
  TempString                            : Str80;

begin
  Delete(Command, 1, 1); // Get rid of the \ character
  {
    if (Command = 'PASSFREQ') and K1EANetworkEnable then
    begin
      Freq := QuickEditFreq('Enter pass freq in kHz : ', 10);
      Str(Freq, TempString);

           // Make sure my display is updated

      UpdateK1EAStationInfo(Pass, K1EAStationID, TempString);

           // Send to K1EA network

      SendMultiMessage('G' + K1EAStationID + ' ' + TempString);
    end;
  }
  if Command = 'RADIO' then TestRadioInterface;

  {   Disabled in 6.46

      IF TakingABreak AND ((Command = 'TIMEON') OR (Command = 'ON')) THEN
          BEGIN
          ThisBreak := ElaspedMinutes (OffTimeStart);

          TotalOffTime := TotalOffTime + ThisBreak;
          TakingABreak := False;

          SaveSetAndClearActiveWindow (QuickCommandWindow);
          Write ('Total off time is now = ', MinutesToTimeString (TotalOffTime), ' minutes');
          ReminderPostedCount := 60;
          RestorePreviousWindow;

          TempString := '; Break finished at ' + GetFullTimeString +
                        '  This break = ' + MinutesToTimeString (ThisBreak) +
                        '  Total off time = ' + MinutesToTimeString (TotalOffTime);

          PushLogStringIntoEditableLogAndLogPopedQSO (TempString, True);
          END;

      IF (NOT TakingABreak) AND ((Command = 'TIMEOFF') OR (Command = 'OFF')) THEN
          BEGIN
          MarkTime (OffTimeStart);
          TakingABreak := True;
          LastDisplayedBreakTime := -1;
          TempString := '; Break started at ' + GetFullTimeString;
          PushLogStringIntoEditableLogAndLogPopedQSO (TempString, True);
          END;
 }
end;
{
procedure MoveEditableLogIntoLogFile;

var
  QSOCount                              : integer;
  TempString                            : str80;

begin
  for QSOCount := 1 to NumberEditableLines do
  begin
    TempString := '';
    PushLogStringIntoEditableLogAndLogPopedQSO(TempString, True);
  end;

  DeleteFile(LogTempFileName);
  if UpdateRestartFileEnable then Sheet.SaveRestartFile;
end;
}

procedure CheckMultiState;

var
  MessageString                         : ShortString;
  MultiString, TempString               : ShortString;
  DeleteCall, DeleteFreqString, ModeString, Call: CallString;
  MultString                            : integer {Str80};

  Band                                  : BandType;
  Mode                                  : ModeType;
  Count, Points                         : integer;
  Freq, QSX, OldScore, DeleteFreq, DeleteTime: LONGINT;
  ControlByte                           : Byte;
  RXData                                : ContestExchange;
  Year, Month, Day, DayOfWeek, Hour, Minute, Second, Sec100: Word;
  NewYear, NewMonth, NewDay, NewHour, NewMinute, NewSecond: Word;
  Dupe, Mult, FirstCommand, NewMult     : boolean;
  FileWrite                             : Text;
  SplitByte                             : Byte;
  k1ea_comp_id                          : Char;

begin
  //???? ???????? ????? ????? ???? ???
  //   if not K1EANetworkEnable then CheckForLostMultiMessages;

  MultiString := GetMultiPortCommand;

  if MultiString = '' then Exit;

  OldScore := TotalScore;

  if 1 = 1 {K1EANetworkEnable} then
  begin

      { Message string to not have message type, source or checksum }

    MessageString := MultiString;

    if MessageString[1] = 'B' then
      Delete(MessageString, 1, 2) { Delete message type & source }
    else
      RemoveFirstString(MessageString); { All but packet have a space }

    GetRidOfPrecedingSpaces(MessageString);
    Delete(MessageString, length(MessageString), 1); { Delete checksum }

    case MultiString[1] of

      'B':
        begin
          Packet.ProcessPacketMessageFromNetWork(MessageString);
        end;

      'C': { Band map message }
        begin

            { C1 599 Freq QSX UnixTime 0 band mode call * 0 1 0 0 }

          RemoveFirstString(MultiString); { C1 }
          RemoveFirstString(MultiString); { 599 }

          Freq := RemoveFirstLongInteger(MultiString);
          QSX := RemoveFirstLongInteger(MultiString);

          RemoveFirstString(MultiString); { UnixTime }
          SplitByte := RemoveFirstLongInteger(MultiString); { 0 or 1 }
          RemoveFirstString(MultiString); { band }

          SplitByte := SplitByte and $01;

          if SplitByte = 0 then QSX := 0;

          ModeString := RemoveFirstString(MultiString); { mode }

          Call := RemoveFirstString(MultiString);

            { Set mode to a safe value in case it can't be calculated }

          if ModeString = '1' then
            Mode := CW
          else
            Mode := Phone;

          CalculateBandMode(Freq, Band, Mode);

          if (Band <> NoBand) and (Mode <> NoMode) then { Added in 6.25 }
          begin
            Dupe := VisibleLog.CallIsADupe(Call, Band, ActiveMode);

                { These didn't have the NOT in them until 6.36 }

            if not MultByBand then Band := All;
            if not MultByMode then Mode := Both;

                { Runtime 201 here when hitting F1s - probably on 160.
                  Initialized Mode to Active mode before calling
                  CalculateBandMode }

            Mult := VisibleLog.DetermineIfNewMult(Call, Band, Mode);

//            Mult := MultString <> 0;

                { SendToMulti = False }

//                NewBandMapEntry(Call, Freq, QSX, Mode, Dupe, Mult, BandMapDecayTime, False, '')
          end;

        end;

      'G':
        begin { Pass frequency information }
          UpdateK1EAStationInfo(Pass, MultiString[2], MessageString);
        end;

      'L', 'U':
        begin { Log QSO }

            { If this is an edited QSO, we need to make a note in our
              log }

          if MultiString[1] = 'U' then
          begin
            TempString := MultiString;

            for Count := 1 to 16 do RemoveFirstString(TempString);

            DeleteFreq := RemoveFirstLongInteger(TempString);
            DeleteTime := RemoveFirstLongInteger(TempString);

            Str(DeleteFreq, DeleteFreqString);

            for Count := 1 to 3 do RemoveFirstString(TempString);

            DeleteCall := RemoveFirstString(TempString);

                //                        TempString := '; DELETE QSO at ' + ConvertUnixToDateAndTimeString(DeleteTime) +
                //                           ' with ' + DeleteCall + ' on ' + DeleteFreqString;

            PushLogStringIntoEditableLogAndLogPopedQSO(TempString, True);
          end;

            //wli
          k1ea_comp_id := MultiString[2];
            //                  MultiString := ConvertK1EANetworkLogMessageToN6TRLogString(MultiString);
          ParseExchangeIntoContestExchange(MultiString, RXData);

          ProcessPartialCallAndInitialExchange(RXData);

            { These next steps are unique for K1EA network entries that
              have no QSO point information, multiplier information or
              even the sent QSO Number when they come in. }

          ctyLocateCall(RXData.Callsign, RXData.QTH);
          if DoingDXMults then GetDXQTH(RXData);
          CalculateQSOPoints(RXData);
          VisibleLog.ProcessMultipliers(RXData);
          RXData.NumberSent := TotalContacts + 1;

            { Need to convert RXData back to a N6TR Log Entry string }

//wli          MessageString := MakeLogString(RXData);

            { Now you can do everything that is normally done with a
              TR Log entry }

          Call := GetLogEntryCall(MessageString);
          Band := GetLogEntryBand(MessageString);
          Mode := GetLogEntryMode(MessageString);
          Points := GetLogEntryQSOPoints(MessageString);

          NewMult := GetLogEntryMultString(MessageString) <> '';

          ParseExchangeIntoContestExchange(MessageString, RXData);
          ProcessPartialCallAndInitialExchange(RXData);

          if SendQSOImmediately then
            PushLogStringIntoEditableLogAndLogPopedQSO(MessageString, False)
          else
            PutContactIntoLogFile(MessageString);

          inc(NumberContactsThisMinute);
          NumberQSOPointsThisMinute := NumberQSOPointsThisMinute + Points;

          if (Band >= Band160) and (Band <= Band10) then
            inc(NumberBandQSOsThisMinute[ActiveBand]);

            //          if ActiveWindow <> DupeSheetWindow then { no packet }
          begin
            DisplayTotalScore {(TotalScore)};
            DisplayNamePercentage({TotalNamesSent + VisibleLog.NumberNamesSentInEditableLog, TotalContacts});
            UpdateTotals2;
              //            CheckAvailableMemory;
          end;

          DisplayTotalScore {(TotalScore)};
          DisplayInsertMode;
          DisplayNextQSONumber;

          if FloppyFileSaveFrequency > 0 then
            if QSOTotals[All, Both] > 0 then
              if QSOTotals[All, Both] mod FloppyFileSaveFrequency = 0 then
                SaveLogFileToFloppy;

          if UpdateRestartFileEnable then Sheet.SaveRestartFile;

          if MultiUpdateMultDisplay and NewMult then
            VisibleLog.ShowRemainingMultipliers;

          if BandMapEnable then {KK1L: 6.69 should get BM matching new data}
          begin
            //UpdateBandMapMultiplierStatus_old;
            UpdateBandMapDupeStatus(RXData.Callsign, RXData.Band, RXData.Mode, True);
          end;

        end;

      'M':
        begin { Run frequency information }
          UpdateK1EAStationInfo(Run, MultiString[2], MessageString);
        end;

      'T', 'P': { Talk or pass message }
        begin
            //          QuickDisplay(MessageString);
          DoABeep(BeepCongrats);
            //                  ReminderPostedCount := 60;

          PushMultiMessageBuffer(MessageString);

            //            if IntercomFileOpen then              WriteLn(IntercomFileWrite, GetTimeString, ' ', MessageString);

        end;

      'Y':
        begin { DOS time sync message }
          NewHour := RemoveFirstLongInteger(MessageString);
          NewMinute := RemoveFirstLongInteger(MessageString);
          NewSecond := RemoveFirstLongInteger(MessageString);
          NewDay := RemoveFirstLongInteger(MessageString);
          NewMonth := RemoveFirstLongInteger(MessageString);
          NewYear := RemoveFirstLongInteger(MessageString);

          GetDate(Year, Month, Day, DayOfWeek);

          if (Year <> NewYear) or (Month <> NewMonth) or (Day <> NewDay) then
              //{WLI}                     SetDate (NewYear, NewMonth, NewDay);

            TF.GetTime(Hour, Minute, Second, Sec100);

          if (Hour <> NewHour) or (Minute <> NewMinute) or (Abs(Second - NewSecond) > 3) then
              //{WLI}                     SetTime (NewHour, NewMinute, NewSecond, 0);
        end;

    end; { of CASE MultiString [1] }

  end

  else { N6TR Network Mode }
  begin
      // in TR MessageString [0] := MultiString [8];
    SetLength(MessageString, Ord(MultiString[8]));
    MessageString := Copy(MultiString, 10, Ord(MultiString[8]));
      //in TR         Move(MultiString[10], MessageString[1], Ord(MultiString[8]));

    ControlByte := Ord(MultiString[3]);

    case ControlByte of
      MultiInformationMessage:
        begin
{
          Band := RemoveBand(MessageString);
          Mode := RemoveMode(MessageString);

          if MultiStatus[Band, Mode] = nil then New(MultiStatus[Band, Mode]);
          MultiStatus[Band, Mode]^ := MessageString;
}
        end;

      MultiTimeMessage:
        begin
          Year := RemoveFirstLongInteger(MessageString);
          Month := RemoveFirstLongInteger(MessageString);
          Day := RemoveFirstLongInteger(MessageString);
          Hour := RemoveFirstLongInteger(MessageString);
          Minute := RemoveFirstLongInteger(MessageString);
          Second := RemoveFirstLongInteger(MessageString);

            //{WLI}                SetTime (Hour, Minute, Second, 0);
            //{WLI}                SetDate (Year, Month, Day);
        end;

      MultiBandMapMessage:
        begin
          Call := RemoveFirstString(MessageString);
          Freq := RemoveFirstLongInteger(MessageString);
          QSX := RemoveFirstLongInteger(MessageString);

          Mode := ActiveMode;

          CalculateBandMode(Freq, Band, Mode);

          if (Band <> NoBand) and (Mode <> NoMode) then { Added in 6.25 }
          begin
            Dupe := VisibleLog.CallIsADupe(Call, Band, ActiveMode);

                { These didn't have the NOT in them until 6.36 }

            if not MultByBand then Band := All;
            if not MultByMode then Mode := Both;

                { Runtime 201 here when hitting F1s - probably on 160.
                  Initialized Mode to Active mode before calling
                  CalculateBandMode }

            Mult := VisibleLog.DetermineIfNewMult(Call, Band, Mode);

//            Mult := MultString <> 0;
                { SendToMulti = False }
//                NewBandMapEntry(Call, Freq, QSX, Mode, Dupe, Mult, BandMapDecayTime, False, '')
          end;
        end;

      MultiTalkMessage:
        begin
          MessageString := BandStringsArray[MultiMessageSourceBand(Ord(MultiString[1]))] + ': ' + MessageString;
            //          QuickDisplay(MessageString);
          DoABeep(BeepCongrats);
            //                  ReminderPostedCount := 60;

          PushMultiMessageBuffer(MessageString);

            //            if IntercomFileOpen then              WriteLn(IntercomFileWrite, GetTimeString, ' ', MessageString);
        end;

      MultiPacketReceivedMessage:
        Packet.ProcessPacketMessageFromNetWork(MessageString);

      MultiPacketMessageToSend:
        if Packet.PacketSerialPort <> NoPort then Packet.SendPacketMessage(MessageString);

      MultiQSOData:
        begin
          Call := GetLogEntryCall(MessageString);
          Band := GetLogEntryBand(MessageString);
          Mode := GetLogEntryMode(MessageString);
          Points := GetLogEntryQSOPoints(MessageString);

          NewMult := GetLogEntryMultString(MessageString) <> '';

          ParseExchangeIntoContestExchange(MessageString, RXData);
          ProcessPartialCallAndInitialExchange(RXData);

          if SendQSOImmediately then
            PushLogStringIntoEditableLogAndLogPopedQSO(MessageString, False)
          else
            PutContactIntoLogFile(MessageString);

          inc(NumberContactsThisMinute);
          NumberQSOPointsThisMinute := NumberQSOPointsThisMinute + Points;

          if (Band >= Band160) and (Band <= Band10) then
            inc(NumberBandQSOsThisMinute[Band]);

            //          if ActiveWindow <> DupeSheetWindow then { no packet }
          begin
            DisplayTotalScore {(TotalScore)};
            DisplayNamePercentage({TotalNamesSent + VisibleLog.NumberNamesSentInEditableLog, TotalContacts});
            UpdateTotals2;
              //            CheckAvailableMemory;
          end;

          DisplayTotalScore {(TotalScore)};
          DisplayInsertMode;
          DisplayNextQSONumber;

          if FloppyFileSaveFrequency > 0 then
            if QSOTotals[All, Both] > 0 then
              if QSOTotals[All, Both] mod FloppyFileSaveFrequency = 0 then
                SaveLogFileToFloppy;

          if UpdateRestartFileEnable then Sheet.SaveRestartFile;

          if MultiUpdateMultDisplay and NewMult then
            VisibleLog.ShowRemainingMultipliers;

          if BandMapEnable then {KK1L: 6.69 should get BM matching new data}
          begin
            //UpdateBandMapMultiplierStatus_old;
            UpdateBandMapDupeStatus(RXData.Callsign, RXData.Band, RXData.Mode, True);
          end;

        end;

      MultiConfigurationMessage:
        begin
          FirstCommand := False;
          ProcessConfigInstruction(MessageString, FirstCommand);
          {
          if OpenFileForAppend(FileWrite, LogConfigFileName) then
          begin
            WriteLn(FileWrite, MessageString);
            Close(FileWrite);
          end;
          }
        end;

    end; { of case }
  end;
end;

function WindowDupeCheck: boolean;

{ Returns TRUE if the call window has a dupe in it. }

var
  Frequency                             : LONGINT;
  Band                                  : BandType;
  Mode                                  : ModeType;
  RememberTime                          : Cardinal {TimeRecord};
  TempInteger                           : integer; //Str80 {40};
  MultString                            : Str80 {40};
  Mult                                  : boolean;
  Dupe                                  : boolean;
begin
  WindowDupeCheck := False;

  if length(CallWindowString) < 2 then Exit;
  WindowDupeCheckCall := CallWindowString;

  BandMapBand := ActiveBand;
  BandMapMode := ActiveMode; {KK1L: 6.69 should be here too for no radio connected.}
  Dupe := VisibleLog.CallIsADupe(CallWindowString, ActiveBand, ActiveMode);
  {if not Dupe then }tCreateAndAddNewSpot(CallWindowString, Dupe, ActiveRadioPtr);
  if Dupe then
  begin
//    if AutoDupeEnableSandP then //wli
    begin
      tCallWindowSetFocus;
      WindowDupeCheck := True;
      DispalayDupe;
{
      asm
      lea eax,[CallWindowString+1]
      push eax
      end;
      wsprintf(QuickDisplayBuffer, TC_WASADUPE);
      asm add esp,12
      end;
      QuickDisplay(QuickDisplayBuffer);
}
//      DispalayB4(SW_HIDE);
//      Windows.ShowWindow(B4StatusWindowHandle, SW_HIDE);
//      if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);
      MarkTime(RememberTime);

      if KeyRecentlyPressed(F1, 200) then FlushCWBufferAndClearPTT; { Withing two seconds }
      ShowStationInformation(@CallWindowString);
      DisplayGridSquareStatus(CallWindowString);

          {
                if BandMapEnable and (OpMode = SearchAndPounceOpMode) then
                  if GetRadioParameters(ActiveRadio, '', Frequency, Band, Mode, False, False) then
                    begin
                      BandMapCursorFrequency := Frequency;
                      VisibleLog.DetermineIfNewMult(CallWindowString, ActiveBand, ActiveMode, MultString);
                      Mult := MultString <> '';
                      NewBandMapEntry(CallWindowString, Frequency, 0, ActiveMode, True, Mult, BandMapDecayTime, True, MyCall);
                    end
                  else
                    if AskForFrequencies then
                      begin
                        asm
                        push CallWindowString
                        end;
                        wsprintf(wsprintfBuffer, FrequencyForCallInkHz);
                        asm add esp,12
                        end;
                        Frequency := QuickEditFreq(wsprintfBuffer, 10);
                        //          Frequency := QuickEditFreq(PChar(string('frequency for ' + CallWindowString + ' in kHz')), 10);

                        if Frequency <> -1 then
                          begin
                            VisibleLog.DetermineIfNewMult(CallWindowString, ActiveBand, ActiveMode, MultString);
                            Mult := MultString <> '';

                            NewBandMapEntry(CallWindowString, Frequency, 0, ActiveMode, True, Mult, BandMapDecayTime, True, MyCall);
                            BandMapCursorFrequency := Frequency; //KK1L: 6.68 band map will track manual entry
                            JustLoadingBandMapWithNoRadio := True; //KK1L: 6.68
                          end;
                      end;
          }
      VisibleLog.DoPossibleCalls(CallWindowString);

      tCleareExchangeWindow;
          {
          ?????? ????? ??????????
                   repeat
                      if ActiveMultiPort <> NoPort then CheckMultiState;
                      UpdateTimeAndRateDisplays(true, true);
                      Packet.CheckPacket;
                   until ElaspedSec100(RememberTime) >= 50;
          }
                   //    RemoveWindow(NameSentWindow);
                   //    RemoveWindow(CountryNameWindow);

    //    DisplayInsertMode(InsertMode);

//      if not QTCsEnabled then
//      begin
//        EscapeDeletedCallEntry := CallWindowString;
              //      CallWindowString := '';
//      end;
//      tCleareCallWindow;
          //{WLI}        ClrScr;
          //{WLI}        Write (CallWindowString);
    end;
  end
  else
  begin
    StationInformationCall := '';
    ShowStationInformation(@CallWindowString);
    DisplayGridSquareStatus(CallWindowString);
      {
            if BandMapEnable then
              if GetRadioParameters(ActiveRadio, '', Frequency, Band, Mode, False, False) then
                begin
                  BandMapCursorFrequency := Frequency;

                  VisibleLog.DetermineIfNewMult(CallWindowString, ActiveBand, ActiveMode, MultString);

                  Mult := MultString <> '';

                  NewBandMapEntry(CallWindowString, Frequency, 0, ActiveMode, False, Mult, BandMapDecayTime, True, MyCall);
                end
              else
                if AskForFrequencies then
                  begin
                    asm
                push CallWindowString
                    end;
                    wsprintf(wsprintfBuffer, FrequencyForCallInkHz);
                    asm add esp,12
                    end;
                    Frequency := QuickEditFreq(wsprintfBuffer, 10);

                    //          Frequency := QuickEditFreq(PChar(string('frequency for ' + CallWindowString + ' in kHz')), 10);

                    if Frequency <> -1 then
                      begin
                        VisibleLog.DetermineIfNewMult(CallWindowString, ActiveBand, ActiveMode, MultString);

                        Mult := MultString <> '';

                        NewBandMapEntry(CallWindowString, Frequency, 0, ActiveMode, False, Mult, BandMapDecayTime, True, MyCall);
                        BandMapCursorFrequency := Frequency; //KK1L: 6.68 band map will track manual entry
                        JustLoadingBandMapWithNoRadio := True; //KK1L: 6.68
                      end;
                  end;
      }
    if DupeCheckSound = DupeCheckGratsIfMult then
    begin
      if VisibleLog.DetermineIfNewMult(CallWindowString, ActiveBand, ActiveMode)
      {if TempInteger <> 0 }then DoABeep(BeepCongrats);
    end;
  end;

end;

function GoodCallPutUp: boolean;

{ This function will move the call with the cursors around it from the
  possible call window to the call window.  It will be checked to see if
  it is a dupe.  If it is, a FALSE return will be generated.  Otherwise,
  a TRUE response is generated and if any initial exchange exists, it is
  put in the exchange window.  The exchange window will always be left
  active, with the cursor at 1, 1  }

var
  InitialExchange                       : Str80;

begin
  GoodCallPutUp := False;

  with PossibleCallList do
    if NumberPossibleCalls > 0 then
    begin
      CallWindowString := List[CursorPosition].Call;
        //      ClearWindow(ExchangeWindow);

//      if ActiveWindow = ExchangeWindow then
           //        RestorePreviousWindow;

               //{WLI}            ClrScr;
               //{WLI}            Write (CallWindowString);

      if WindowDupeCheck then Exit;

        //      ActivateExchangeWindow;

      InitialExchange := InitialExchangeEntry(CallWindowString);

      if InitialExchange <> '' then
      begin
            //{WLI}                ClrScr;
        ExchangeWindowString := InitialExchange;
            //{WLI}                Write (ExchangeWindowString);

                            {TR6.74 - need to do this since IntialExchangeEntry does not }

        if InitialExchangeOverwrite then
          InitialExchangePutUp := ExchangeWindowString <> '';

        if InitialExchangeCursorPos = AtEnd then
               //                    GoToXY (Length (InitialExchange) + 1, 1)
    //    else
              //{WLI}                    GoToXY (1, 1);
      end
      else
          //{WLI}                Write (ExchangeWindowString);
 //         GoToXY (1,1);
        ShowStationInformation(@CallWindowString);
      DisplayGridSquareStatus(CallWindowString);
      GoodCallPutUp := True;
    end;
end;

procedure ToggleStereoPin; {KK1L: 6.71}
begin
  TF.InvertBoolean(StereoPinState);
  SetStereoPin(StereoControlPin, StereoPinState);
end;

procedure ToggleModes;

begin
  if (MultipleModesEnabled) or (TotalContacts = 0) then
  begin
    case ActiveMode of
      CW: if DigitalModeEnable then ActiveMode := Digital else ActiveMode := Phone;
      Phone: if ActiveBand >= Band6 then ActiveMode := FM else ActiveMode := CW;
      Digital: ActiveMode := Phone;
    else ActiveMode := CW;
    end;
      {      if (ActiveMode = Phone) and (ActiveBand >= Band6) and (not FMMode) then
              FMMode := True
            else
              begin
                FMMode := False;

                if DigitalModeEnable then
                  begin
                    case ActiveMode of
                      Phone: ActiveMode := CW;
                      CW: ActiveMode := Digital;
                      Digital: ActiveMode := Phone;
                      else ActiveMode := CW;
                    end;
                  end
                else
                  case ActiveMode of
                    Phone: ActiveMode := CW;
                    CW: ActiveMode := Phone;
                    else ActiveMode := CW;
                  end;
              end;
      }
    EditingCallsignSent := False;

    DisplayBandMode(
      ActiveBand,
      ActiveMode,
        {
        (ActiveBand <= Band10) or
        (ActiveBand = Band30) or
        (ActiveBand = Band17) or
        (ActiveBand = Band12)
        wli
        }
      True
      );

    DisplayCodeSpeed;

      {KK1L: 6.73 This gets done in UpdateTimeAndRateDisplay. Only do if no radio connected.}
    if (ActiveRadio = RadioOne) and ((Radio1.tCATPortType = NoPort) or (not Radio1.PollingEnable)) then
      Radio1.ModeMemory {ModeMemory[RadioOne]} := ActiveMode
    else
      if (ActiveRadio = RadioTwo) and ((Radio2.tCATPortType = NoPort) or (not Radio2.PollingEnable)) then
        Radio2.ModeMemory {ModeMemory[RadioTwo]} := ActiveMode;

    UpdateTotals2;

    CallsignsList.DisplayDupeSheet(ActiveRadioPtr);

    if QSOByMode then VisibleDupeSheetChanged := True;

    if MultByMode then
    begin
      VisibleLog.ShowRemainingMultipliers;
      VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);
    end;

    BandMapBand := ActiveBand;
    BandMapMode := ActiveMode; {KK1L: 6.68 BM now tracks mode with no radio connected on mode change}
    DisplayBandMap;
  end;
end;

procedure DupeCheckOnInactiveRadio(Tune: boolean);

{ This will perform a dupe check on the inactive radio }

var
  Mode                                  : ModeType;
  Band                                  : BandType;
  Frequency                             : LONGINT;
  MultString                            : Str80 {40};
  TempString                            : integer; //Str80 {40};
  Mult                                  : boolean;
  isDupe                                : boolean;
  a                                     : array[0..2] of Pointer;

begin
  if SingleRadioMode then
  begin
    QuickDisplay(TC_ALTDCOMMANDDISABLED);
    Exit;
  end;

  RITEnable := False;

  { VER6.73 - Make up a string of the inactive CW Speed for display }

  Str(InActiveRadioPtr.SpeedMemory, SpeedString);

  BandMapBand := InActiveRadioPtr.BandMemory {BandMemory[InactiveRadio]};
  BandMapMode := InActiveRadioPtr.ModeMemory {ModeMemory[InactiveRadio]};

  DisplayBandMap; { Do we always want to do this?  What if already up? }

  {KK1L: 6.73 Check for DupeInfoCall coming from bandmap and prompt added to procedure}
  {KK1L: 6.73 changed CheckMode to ModeMemory[InactiveRadio]}

{
  if K5KA.AltDString = '' then
  begin
    TempString := UpperCase(QuickEditResponse//QuickEditResponseWithPartials
    (PChar('call to be checked on ' + BandStringsArray[InactiveRadioPtr.BandMemory] + ModeString[InactiveRadioPtr.ModeMemory]), 12));
    if (TempString <> EscapeKey) and (TempString <> '') then DupeInfoCall := TempString;
  end
  else
    DupeInfoCall := K5KA.AltDString;
}
  if K5KA.AltDString <> '' then
  begin
    tClearDupeInfoCall;
    DupeInfoCall := K5KA.AltDString;
  end
  else
  begin
    if not Tune then
//    tDialogBox(54, @AltDDlgProc);
      CreateModalDialog(140, 50, tr4whandle, @AltDDlgProc, 0);
  end;

  { Put the band map on the band/mode of the inactive radio }

  if (DupeInfoCall <> '') {and (DupeInfoCall <> EscapeKey)} then
begin
    DisplayGridSquareStatus(CallWindowString);

    ShowStationInformation(@DupeInfoCall);                                          //gav 4.44.8


    isDupe := VisibleLog.CallIsADupe(DupeInfoCall, InActiveRadioPtr.BandMemory, InActiveRadioPtr.ModeMemory);
    if not Tune then tCreateAndAddNewSpot(DupeInfoCall, isDupe, InActiveRadioPtr);
    if isDupe then
    begin
      DupeInfoCallWindowState := diDupe;
      Format(wsprintfBuffer, '%s DUPE!! on %s%s', @DupeInfoCall[1], BandStringsArray[InActiveRadioPtr.BandMemory], ModeStringArray[InActiveRadioPtr.ModeMemory]);
      SetMainWindowText(mweDupeInfoCall, wsprintfBuffer {DupeInfoCall + ' DUPE!! on ' + BandStringsArray[InActiveRadioPtr.BandMemory] + ModeString[InActiveRadioPtr.ModeMemory]});
{
      a[0] := BandStringsArray[InActiveRadioPtr.BandMemory];
      a[1] := ModeString[InActiveRadioPtr.ModeMemory];
      a[2] := pointer(InActiveRadioPtr.SpeedMemory);
      Windows.wvsprintf(TempBuffer1, 'bandmode is %s%s  on %d wpm', @a);
      ShowMessage(TempBuffer1);
}
      if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);
      tClearDupeInfoCall;
    end
    else
    begin
      DupeInfoCallWindowState := diNotDupe;

      if VisibleLog.DetermineIfNewMult(DupeInfoCall, InActiveRadioPtr.BandMemory, InActiveRadioPtr.ModeMemory)
      {if TempString <> 0 }then
      begin
        if DupeCheckSound = DupeCheckGratsIfMult then DoABeep(BeepCongrats);
        DupeInfoCallWindowState := diNotDupeMult;
      end;
{
      if InActiveRadioPtr.ModeMemory = CW then
        tSetWindowText(wh[mweDupeInfoCall], DupeInfoCall + ' OK!! at ' + SpeedString + ' WPM'#13'Space bar for ' + BandStringsArray[InActiveRadioPtr.BandMemory] + ModeString[InActiveRadioPtr.ModeMemory] + ' QSO')
      else
        tSetWindowText(wh[mweDupeInfoCall], DupeInfoCall + ' OK!!'#13#10'Space bar for ' + BandStringsArray[InActiveRadioPtr.BandMemory] + ModeString[InActiveRadioPtr.ModeMemory] + ' QSO');
}


      Format(wsprintfBuffer, '%s OK!!'#13#10'Space bar for %s%s', @DupeInfoCall[1], BandStringsArray[InActiveRadioPtr.BandMemory], ModeStringArray[InActiveRadioPtr.ModeMemory]);
      SetMainWindowText(mweDupeInfoCall, wsprintfBuffer {DupeInfoCall + ' DUPE!! on ' + BandStringsArray[InActiveRadioPtr.BandMemory] + ModeString[InActiveRadioPtr.ModeMemory]});

      if TwoRadioState <> TwoRadiosDisabled then TwoRadioState := CallReady;

    end;

//    if SendAltDSpotsToPacket and (Frequency <> -1) then CreateAndSendPacketSpot(DupeInfoCall, Frequency);

  end
  else
    if BandMapBlinkingCall <> '' then
    begin
        {KK1L: 6.73 changed CheckMode to ModeMemory[InactiveRadio]}
{?
      VisibleLog.DetermineIfNewMult(BandMapBlinkingCall, InactiveRadioPtr.BandMemory, InactiveRadioPtr.ModeMemory, MultString);
      Mult := MultString <> '';
      NewBandMapEntry(BandMapBlinkingCall, BandMapCursorFrequency, 0, ModeMemory[InactiveRadio], False, Mult, BandMapDecayTime, True, MyCall);
      if SendAltDSpotsToPacket then CreateAndSendPacketSpot(BandMapBlinkingCall, BandMapCursorFrequency);
}
    end;

  RITEnable := True;
end;

procedure SwapMultDisplay;
label
  Next;
//var  no                                    : integer;
begin
  if NumberDifferentMults < 2 then Exit;

//  no := 0;
  Next:
//  inc(no);
//  if no > 10 then Exit;

  if RemainingMultDisplay = rmPrefix then
    RemainingMultDisplay := rmDomestic
  else
    RemainingMultDisplay := RemainingMultiplierType(Ord(RemainingMultDisplay) + 1);

  case RemainingMultDisplay of
    rmDomestic: if not DoingDomesticMults then goto Next;
    rmDX: if not DoingDXMults then goto Next;
    rmZone: if not DoingZoneMults then goto Next;
    rmPrefix: if not DoingPrefixMults then goto Next;
  end;
{
  case RemainingMultDisplay of
    rmDomestic:
      if DoingDXMults then
        RemainingMultDisplay := rmDX
      else
        if DoingZoneMults then
          RemainingMultDisplay := rmZone;

    rmDX:
      if DoingZoneMults then
        RemainingMultDisplay := rmZone
      else
            //IF DoingDomesticMults AND (ActiveDomesticMult <> WYSIWYGDomestic) THEN
        if (DoingDomesticMults and (DomesticQTHDataFileName <> '')) then
              //KK1L: 6.68 changed above to allow domestic mults to be displayed if there is a dom file
          RemainingMultDisplay := rmDomestic;

    rmZone:
          //IF DoingDomesticMults AND (ActiveDomesticMult = DomesticFile)
      if (DoingDomesticMults and (DomesticQTHDataFileName <> '')) then
            //KK1L: 6.68 changed above to allow domestic mults to be displayed if there is a dom file
        RemainingMultDisplay := rmDomestic
      else
        if DoingDXMults then
          RemainingMultDisplay := rmDX;

  end;
}
  SetRemMultsColumnWidth;
  VisibleLog.ShowRemainingMultipliers;

end;

procedure DeleteLastContact;
var
  TempRXData                            : ContestExchange;
  lpNumberOfBytesRead                   : Cardinal;
  p                                     : PChar;
begin
  if not OpenLogFile then Exit;
  tSetFilePointer(-1 * SizeOf(ContestExchange), FILE_END);
  Windows.ReadFile(LogHandle, TempRXData, SizeOf(ContestExchange), lpNumberOfBytesRead, nil);

  if
    (lpNumberOfBytesRead <> SizeOf(ContestExchange)) or
    (TempRXData.ceRecordKind <> rkQSO) or
    (TempRXData.ceQSO_Skiped <> tLastLogEntryIsDeleted)
    then
  begin
    CloseLogFile;
    Exit;
  end;

  if tLastLogEntryIsDeleted then
  begin
     
    TempRXData.ceQSO_Skiped := False;
    p := TC_YOUHAVERESTOREDTHELASTDELETED;
  end
  else
  begin

    TempRXData.ceQSO_Skiped := True;
    p := TC_YOUHAVEDELETEDTHELASTLOGENTRY;
  end;
  InvertBoolean(tLastLogEntryIsDeleted);
  tSetFilePointer(-1 * SizeOf(ContestExchange), FILE_END);
  sWriteFile(LogHandle, TempRXData, SizeOf(ContestExchange));
  SendRecordToServer(NET_EDITEDQSO_ID, TempRXData);
  CloseLogFile;
  LoadinLog;
  ShowMessage(p);
  //  QuickDisplay(p);
end;

procedure LogBackCopy(Seconds: integer);

var
  SecString, TempString                 : Str80;

begin
  Str(Seconds, SecString);
  Str(TotalContacts + 1, TempString);

  TempString := '; Backcopy made for QSO #' + TempString + ' at ' +
    GetTimeString + ' for ' + SecString + ' seconds.';

  PushLogStringIntoEditableLogAndLogPopedQSO(TempString, True);
end;

procedure PlayLastSeconds(Seconds: integer);

var
  FileRead                              : Text;

begin
{
  SaveBackCopyFile(DVPPath + 'TEMP.BCP', Seconds);
  repeat until OpenFileForRead(FileRead, DVPPath + 'TEMP.BCP');
  Sleep(100);

  Close(FileRead);

  DVPListenMessage('TEMP.BCP', True);
}
end;

procedure ExitProgram(Ask: boolean);
begin
{$IF not tDebugMode }
  if Ask then
    if YesOrNo(tr4whandle, TC_DOYOUREALLYWANTTOEXITTHEPROGRAM) = IDno then Exit;
{$IFEND}

//  GetLogColumnsWidth;
//  timeEndPeriod(1);

{$IF MMTTYMODE}
  PostMmttyMessage(RXM_EXIT, 0);
{$IFEND}

{$IF  LANG = 'RUS'}
//  if (OCXHandle <> 0) then FreeLibrary(OCXHandle);
{$IFEND}

  SaveTelnetWindowSpots;
  if WindowsSocketsInitialised then WSACleanup;
  ntBeepClose;
  SaveTR4WPOSFILE;
  if BackCopyEnable then StopBackCopy;

  if NetDebug then
  begin
    Close(NetDebugBinaryOutput);
    Close(NetDebugBinaryInput);
  end;

  if DVKEnable then DVPUnInit;
  {if BandMapEnable then }SaveBandMap;
  wkClose;
  DriverDestroy;
  Sheet.SaveRestartFile;
  UnInitializeKeyer;
  NoSound;
  CD.SCPDisableAndDeAllocateFileBuffer;
//  SaveMissedWAVCallsigns;
//  CallsignsList.Destroy;
//  SpotsList.Destroy;
  if LuconSZLoadded then RemoveFontResource(TR4W_LC_FILENAME);

{$IF SCPDEBUG}
  if scpLoaded then scpClose;
{$IFEND}

//  if TrayBallonDisplayed then Balloon_DeleteTrayIcon;
  FreeAndNil(udp); // ny4i 4.44.9 Destroy the udp object
  tr4w_ShutDown;
end;

procedure TalkToRTTYPort;

var
  Key                                   : Char;

begin
  {    IF ActiveRTTYPort = NoPort THEN Exit;

      QuickDisplay ('What you type will go to the TNC.  Press ESCAPE to stop.');

      REPEAT
          REPEAT
              CheckRTTY;
          UNTIL KeyPressed;

          Key := ReadKey;

          IF Key = EscapeKey THEN
              BEGIN
              QuickDIsplay ('Back to net');
              Exit;
              END;

          CPUKeyer.AddSerialPortCharacter (ActiveRTTYPort, Key);
      UNTIL False;
     }
end;

procedure PacketWindow;

var
  Key                                   : Char;
  MultString, FrequencyString, CallSignString, DateString, TimeString: Str20;
  TempString                            : string;
  CommandLine, PacketLine               : Str80;
  RememberDoingZ80Op                    : boolean;
  RadioFrequency                        : REAL;
  Band                                  : BandType;
  Mode                                  : ModeType;
  StringLength, Result                  : integer;
  PacketByte                            : Byte;
  TimeMark                              : Cardinal {TimeRecord};

begin
  PacketWindowUp := True;

  RITEnable := False;

  QuickDisplay(TC_YOUARENOWTALKINGTOYOURPACKETPORT);

  //  SaveSetAndClearActiveWindow(DupeSheetWindow);
   //{WLI}    ClrScr;

  Packet.DisplayPacketDisplayBuffer;

  { Show chars from incomplete line that isn't in the PacketDisplayBuffer }

//  Write(Packet.PacketDisplayLine);

  CommandLine := '';

  MarkTime(TimeMark);

  repeat
    //      if ActiveMultiPort <> NoPort then CheckMultiState;

    UpdateTimeAndRateDisplays(True, True);

    if NewKeyPressed then
    begin
      MarkTime(TimeMark);

      Key := NewReadKey;

      if Key = ControlB then
      begin
        if PacketAutoCR and (CommandLine <> '') then
          if Packet.PacketSerialPort <> NoPort then
            SendChar(Packet.PacketSerialPort, Key)
          else
            if {ActiveMultiPort } NoPort <> NoPort then
            begin
              if 1 = 1 {K1EANetworkEnable} then
              begin
                        //                SendMultiMessage('A' + K1EAStationID + CommandLine);
              end
              else
                SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF,
                  MultiPacketMessageToSend, CommandLine);
            end;

            //        RestorePreviousWindow;

            //        RemoveWindow(BigWindow);
//        VisibleLog.SetUpEditableLog;
        UpdateTotals2;
        VisibleLog.ShowRemainingMultipliers;
        VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);

            {                  if VisibleDupesheetEnable then
                                 begin
                                    VisibleDupeSheetChanged := true;
                                    VisibleLog.DisplayVisibleDupeSheet(ActiveBand, ActiveMode);
                                 end;
            }
                              //        RemoveWindow(QuickCommandWindow);
        PacketWindowUp := False;
        RITEnable := True;
        Exit;
      end;

      if Key = NullKey then
      begin
        Key := NewReadKey;

            //        case Key of
            //          AltA:
            //            if (CallWindowString = '') and (LastSCPCall = '') then
            //              SetAlarm
            //            else
            //              VisibleLog.SuperCheckPartial(CallWindowString, False, ActiveRadio);

                                 {KK1L: 6.73 Added ActiveRadio}

            //          AltB:
            //            begin

                                       //{WLI}                        RememberFrequency;
            //              BandUp;
                                       {KK1L: 6.73 NOTE the following statement is redundant. It is in BandUp and BandDown.}
            //              if QSONumberByBand then
            //                DisplayNextQSONumber(TotalContacts + 1);
            //            end;

            //          AltD:
            //            if K1EANetworkEnable then
            //              PassStationToCTNetwork
            //            else
            //              DupeCheckOnInactiveRadio;

            //          AltK: ToggleCW(true);

            //          AltM:
            //            begin
                                       //{WLI}                        RememberFrequency;
            //              ToggleModes;
            //            end;

            //          AltR:
            //            begin
                                       //{WLI}                        SwapRadios;
            //              InactiveRigCallingCQ := False;
            //              Str(SpeedMemory[InactiveRadio], SpeedString); {KK1L: 6.73 Used to use a variable CheckSpeed}
            //            end;

            //          AltS: SetNewCodeSpeed;
            //          AltT: TimeAndDateSet;

            //          AltV:
            //            begin
                                       //{WLI}                        RememberFrequency;
            //              BandDown;
            //            end;

            //          AltX: ExitProgram;

            //          AltY:
            //            begin
            //              DeleteLastContact;
            //              LastTwoLettersCrunchedOn := '';
            //            end;

            //          PageUpKey: SpeedUp;
            //          PageDownKey: SlowDown;

            //        else
                                    //{WLI}                      SendFunctionKeyMessage (Key, OpMode);
                                                          {KK1L: note: this is where to add switch to SAPMode if NextBandMap command}
            //        end;

      end

      else
      begin
        if Packet.PacketSerialPort <> NoPort then
          SendChar(Packet.PacketSerialPort, Key)
        else
          if Key <> BackSpace then
          begin
            if Key <> CarriageReturn then
              Write(Key)
            else
              WriteLn(Key);
          end
          else
                {                        IF WhereX > 1 THEN
                                            BEGIN
                                            GoToXY (WhereX - 1, WhereY);
                                            Write (' ');
                                            GoToXY (WhereX - 1, WhereY);
                                            END;
                 }
            if Key <> BackSpace then
              CommandLine := CommandLine + Key
            else
              Delete(CommandLine, length(CommandLine), 1);
      end;

      if Key = CarriageReturn then
      begin
            //                  if (Packet.PacketSerialPort = NoPort) and (ActiveMultiPort <> NoPort) then
        begin
              {
              if K1EANetworkEnable then
              begin
                Delete(CommandLine, length(CommandLine), 1);
                SendMultiMessage('A' + K1EAStationID + CommandLine);
              end
              else
                SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF,
                  MultiPacketMessageToSend, CommandLine);
                  }
        end;

        CommandLine := '';
      end;

    end;

 //   Packet.CheckPacketBuffer(True);
//    Packet.CheckPacketMessage;

    Sleep(4);
  until ({ActiveMultiPort}NoPort <> NoPort) and (ElaspedSec100(TimeMark) > 2000);

  if PacketAutoCR and (CommandLine <> '') then
    if Packet.PacketSerialPort <> NoPort then
      SendChar(Packet.PacketSerialPort, Key)
    else
      //         if ActiveMultiPort <> NoPort then
    begin
        {
         if K1EANetworkEnable then
         begin
           Delete(CommandLine, length(CommandLine), 1);
           SendMultiMessage('A' + K1EAStationID + CommandLine);
         end
         else
           SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF,
             MultiPacketMessageToSend, CommandLine);
         }
    end;

  //  RestorePreviousWindow;

  //  RemoveWindow(BigWindow);
//  VisibleLog.SetUpEditableLog;
  UpdateTotals2;
  VisibleLog.ShowRemainingMultipliers;
  VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);

  {   if VisibleDupesheetEnable then
        begin
           VisibleDupeSheetChanged := true;
           VisibleLog.DisplayVisibleDupeSheet(ActiveBand, ActiveMode);
        end;
  }
     //  RemoveWindow(QuickCommandWindow);
  PacketWindowUp := False;
  RITEnable := True;
end;

function AutoCQLoopKeyCheck: Char;

var
  Key                                   : Char;

begin
  {
    if NewKeyPressed then
    begin
      Key := NewReadKey;

      AutoCQLoopKeyCheck := Key;

      case Key of

        NullKey:
          case (NewReadKey) of
            AltA:
              if (CallWindowString = '') and (LastSCPCall = '') then
                SetAlarm
              else
                VisibleLog.SuperCheckPartial(CallWindowString, False, ActiveRadio);

            AltD:
              if K1EANetworkEnable then
                PassStationToCTNetwork
              else
                DupeCheckOnInactiveRadio;

            AltE:
              begin
                RITEnable := False;
                VisibleLog.EditLog;
                RITEnable := true;
                UpdateTotals;
                VisibleLog.ShowRemainingMultipliers;
                VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);
                DisplayTotalScore(TotalScore);
                DisplayInsertMode(InsertMode);
                DisplayNextQSONumber(TotalContacts + 1);
                LastTwoLettersCrunchedOn := '';

                if VisibleDupesheetEnable then
                begin
                  VisibleDupeSheetChanged := true;
                  VisibleLog.DisplayVisibleDupeSheet(ActiveBand, ActiveMode);
                end;

                VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);
              end;

            AltF: SaveLogFileToFloppy;
            AltG: SwapMultDisplay;

            AltH:
              begin
                PutUpHelpMenu;
                          //              RestorePreviousWindow;
                VisibleDupeSheetRemoved := true;
              end;

            AltL:
              begin
                RITEnable := False;
                VisibleLog.SearchLog(CallWindowString);
                RITEnable := true;
              end;

            AltO:
              begin
                RITEnable := False;
                AddReminder;
                RITEnable := true;
              end;

            AltP:
              begin
                RITEnable := False;
                MemoryProgram;
                RITEnable := true;
                VisibleLog.SetUpEditableLog;
                          //              SaveSetAndClearActiveWindow(QuickCommandWindow);
              end;

            AltS: SetNewCodeSpeed;

            AltT: TimeAndDateSet;

            AltU:
              begin
                MoveEditableLogIntoLogFile;
                UpdateTotals;
              end;

            AltW: WakeUpCount := 0;

            AltX:
              begin
                          //              RestorePreviousWindow;
                ExitProgram;
                          //              SaveSetAndClearActiveWindow(QuickCommandWindow);
              end;

            AltY:
              begin
                DeleteLastContact;
                LastTwoLettersCrunchedOn := '';
              end;

            AltDash:
              begin
                if AutoSendCharacterCount > 0 then
                  AutoSendEnable := not AutoSendEnable;

                DisplayAutoSendCharacterCount;
              end;

            PageDownKey:
              if AutoCQDelayTime > 1 then
                Dec(AutoCQDelayTime);

            PageUpKey:
              inc(AutoCQDelayTime);

            ControlEnd:
              begin
                          //              EditBandMap1;
                          //              SaveSetAndClearActiveWindow(QuickCommandWindow);
              end;

            ControlInsert:
              begin
                AddBandMapPlaceHolder;
              end;

            ControlDelete:
              begin
                if BandMapCursorData^.Frequency > 0 then
                begin
                  DisplayBandMap;
                  if FoundCursor then
                  begin
                    DeleteBandMapEntry(BandMapCursorData);
                    DisplayBandMap;
                  end;
                end;
              end;

          end;

        ControlB:
          if (Packet.PacketSerialPort <> NoPort) or
            (ActiveMultiPort <> NoPort) or
            (ActiveRTTYPort <> NoPort) then
            PacketWindow;

        ControlJ:
          begin
            RITEnable := False;

            ProcessConfigurationInput;
                    //WLI                ClrScr;
            DisplayAutoSendCharacterCount;

            RITEnable := true;
          end;

        ControlL:
          begin
            ViewLogFile;
            VisibleDupeSheetRemoved := true;
          end;

        ControlN:
          begin
            RITEnable := False;

            AddedNoteString := QuickEditResponse('Enter note : ', 60);

            if (AddedNoteString <> '') and (AddedNoteString <> EscapeKey) then
            begin
              if ComputerID = NullKey then
                AddedNoteString := '; ' + GetDateString + ' ' +
                  GetTimeString + ' : ' +
                  AddedNoteString
              else
                AddedNoteString := '; ' + GetDateString + ' ' +
                  GetTimeString + ' ' +
                  ComputerID + ': ' +
                  AddedNoteString;

              while length(AddedNoteString) > 79 do
                Delete(AddedNoteString, length(AddedNoteString), 1);

              PushLogStringIntoEditableLogAndLogPopedQSO(AddedNoteString, true);
            end;

            RITEnable := true;
          end;

        ControlO: VisibleLog.ShowMissingMultiplierReport;

      else
        begin
          FlushCWBufferAndClearPTT;
                    //        RestorePreviousWindow;
                    //        RemoveWindow(QuickCommandWindow);
          KeyPressedMemory := Key;
          AutoCQLoopKeyCheck := EscapeKey;
          Exit;
        end;

      end;

      if (ActiveWindow <> QUICKCOMMANDWINDOW) then
      begin
        ResetSavedWindowListAndPutUpCallWindow;
                 //      SaveSetAndClearActiveWindow(QuickCommandWindow);
      end;

    end;
   }
end;

procedure AutoCQResume(SkipFirstMessage: boolean);

var
  CQMemory, TempChar, SendChar, Key     : Char;
  CharacterCount                        : integer;
  FileName, TempString                  : ShortString;
  QSONumberString                       : Str20;
  LastDisplayedTimeElasped, Count, TimeElasped: integer;
  StartOfLastPhoneMessage               : Cardinal {TimeRecord};
  TimeOut                               : Byte;

begin
  LastDisplayedTimeElasped := 0;
  SetUpToSendOnActiveRadio;
  KeyPressedMemory := CHR(0);
  CWEnabled := True;

  if not (((AutoCQMemory >= F1) and (AutoCQMemory <= AltF10)) or
    ((AutoCQMemory >= F11) and (AutoCQMemory <= AltF12))) then
    Exit;

  if AutoCQDelayTime > 0 then
  begin
      //    SaveSetAndClearActiveWindow(QuickCommandWindow);

    Write('Repeating ', KeyId(AutoCQMemory), '  Listen time = ',
      (AutoCQDelayTime / 2): 2: 1, ' - PgUp/Dn to adjust or ESCAPE     ');
    FlushCWBuffer;   //n4af 4.36.13
    CQMemory := AutoCQMemory;

    repeat
      if FrequencyDisplayed then
      begin
        LastCQFrequency := ActiveRadioPtr.LastDisplayedFreq {LastDisplayedFreq[ActiveRadio]};
        LastCQMode := ActiveMode;
      end
      else
        LastCQFrequency := 0;

      if (AutoCQMemory = F1) and RandomCQMode then
      begin
        Count := 0;

        repeat
          inc(Count);

          case Random(4) of
            0: CQMemory := F1;
            1: CQMemory := F2;
            2: CQMemory := F3;
            3: CQMemory := F4;
          end;

        until (GetCQMemoryString(ActiveMode, CQMemory) <> '') or (Count > 1000); {KK1L: 6.73 Added mode}
      end;

      if ActiveMode <> Phone then
      begin
        TempString := GetCQMemoryString(ActiveMode, CQMemory); {KK1L: 6.73 Added mode}

        if not SkipFirstMessage then
          for CharacterCount := 1 to length(TempString) do
          begin
            SendChar := TempString[CharacterCount];

            case SendChar of
              '\': AddStringToBuffer(MyCall, CWTone);
              '>': RITClear;
            else AddStringToBuffer(SendChar, CWTone);
            end;
          end;

      end

      else { Phone mode }
      begin
        TempString := GetCQMemoryString(ActiveMode, CQMemory); {KK1L: 6.73 Added mode}

            {KK1L: 6.72 Pulled out the DVK code from the REPEAT...UNTIL. Can't tell end of DVK message}
            {REPEAT {KK1L: 6.71}
            {    IF DVPEnable THEN
            {        BEGIN
            {        WHILE TempString <> '' DO
            {            BEGIN
            {            FileName := RemoveFirstString (TempString);
            {            GetRidOfPrecedingSpaces (FileName);
            {            IF NOT SkipFirstMessage THEN DVPPlayMessage (FileName);
            {            END;
            {        END
            {    ELSE
            {        IF (NOT SkipFirstMessage) AND (ActiveDVKPort <> NoPort) THEN {KK1L: 6.71 added DVK check}
            {            SendDVKMessage (TempString);
            {
            {    IF AutoCQLoopKeyCheck = EscapeKey THEN Exit; {KK1L: 6.71a Check if key fell out of loop or escape}
            {
            {    Wait (20); {KK1L: 6.71}
            {UNTIL NOT (DVPMessagePlaying OR DVKMessagePlaying); {KK1L: 6.71 should start timer at END of message}

            {KK1L: 6.72 Replaced above with this}
        if DVKEnable then
          repeat
            while TempString <> '' do
            begin
              FileName := RemoveFirstString(TempString);
              GetRidOfPrecedingSpaces(FileName);
//              if not SkipFirstMessage then DVPPlayMessage(FileName);
            end;

            if AutoCQLoopKeyCheck = EscapeKey then
            begin
              if DVKEnable and DVPMessagePlaying then {KK1L: 6.71b Kill DVP}
              begin
                TimeOut := 0;

                DVPStopPlayback;
                repeat
                  Sleep(5);
                  inc(TimeOut);
                until (not DVPMessagePlaying) or (TimeOut > 30);
              end;
              Exit;
            end;

            Sleep(20);
          until not DVPMessagePlaying
        else
        begin
                //wli                        if (not SkipFirstMessage) and (ActiveDVKPort <> NoPort) then SendDVKMessage(TempString);

          if AutoCQLoopKeyCheck = EscapeKey then
          begin
                    //wli                              if (ActiveDVKPort <> NoPort) then StartDVK(0); {KK1L: 6.71b Kill DVK}
            Exit;
          end;
        end;

        MarkTime(StartOfLastPhoneMessage); {KK1L: 6.72 Or End in the case of DVP}
      end;

      SkipFirstMessage := False;

        {KK1L: 6.68 From here to REPEAT added to put autoCQ in band map and send multi info message.}

      if BandMapEnable and (Radio1.LastDisplayedFreq {LastDisplayedFreq[RadioOne]} <> 0) and (OpMode = CQOpMode) and BandMapDisplayCQ then
      begin
        Str(TotalContacts + 1, QSONumberString);
        BandMapCursorFrequency := ActiveRadioPtr.LastDisplayedFreq {LastDisplayedFreq[ActiveRadio]};
            //            NewBandMapEntry('CQ/ ' + QSONumberString, LastDisplayedFreq[ActiveRadio], 0, ActiveMode, False, False, BandMapDecayTime, True, MyCall);
        tCreateAndAddNewSpot('CQ/ ' + QSONumberString, False, ActiveRadioPtr {?});
        LastCQFrequency := ActiveRadioPtr.LastDisplayedFreq {LastDisplayedFreq[ActiveRadio]};
        LastCQMode := ActiveMode;
      end;

        //            if ActiveMultiPort <> NoPort then CreateAndSendCQMultiInfoMessage;

      repeat

          {        if ActiveMode <> Phone then
                  begin
                    if CPUKeyer.SlowInterrupts then
                      TimeElasped := CountsSinceLastCW div 149
                    else
                      TimeElasped := CountsSinceLastCW div 298;

                  end
                  else
                   }TimeElasped := MicroTimeElapsed(StartOfLastPhoneMessage) div 50;

        if LastDisplayedTimeElasped <> TimeElasped then
        begin
              //{WLI}                     GoToXY (WhereX - 4, WhereY);

          if TimeElasped < 20 then Write(' ');

          Write((TimeElasped / 2): 2: 1);
          LastDisplayedTimeElasped := TimeElasped;
        end;

          { Allow for many commands to get processed - also see if an
            escape key was pressed. }

        if AutoCQLoopKeyCheck = EscapeKey then Exit;

          {KK1L: 6.72 NOTE Timing delays can occur if there are radio communcations problems due to    }
          {                various timeouts, etc in the polling called from UpdateTimeAndRateDisplays. }

        UpdateTimeAndRateDisplays(True, True);

          //               if ActiveMultiPort <> NoPort then CheckMultiState;
      Packet.CheckPacket;
        Sleep(4);

      until TimeElasped >= AutoCQDelayTime;

    until False;
  end;
end;

procedure AutoCQ;

var
  Time, Result                          : integer;
  Key, TempChar                         : Char;
  TempString                            : Str80;

begin
  SetUpToSendOnActiveRadio;
  //  SaveSetAndClearActiveWindow(QuickCommandWindow);

  Write('Press the memory key you want to repeat');

  repeat until NewKeyPressed;

  Key := UpCase(NewReadKey);

  if Key <> NullKey then
  begin
      //    RemoveAndRestorePreviousWindow;
    Exit;
  end;

  Key := NewReadKey;

  if not (((Key >= F1) and (Key <= AltF10)) or ((Key >= F11) and (Key <= AltF12))) then
  begin
      //    RemoveAndRestorePreviousWindow;
    Exit;
  end;

  AutoCQMemory := Key;

  repeat
    //{WLI}         ClrScr;

    if ActiveMode = Phone then
      if DVKEnable then {KK1L: 6.72 Now need to differentiate DVP and DVK}
        {Write ('Number of seconds between start of transmissions : ')}{KK1L: 6.71 fixed this in AutoCQResume}
        Write('Number of seconds of listening time : ') {KK1L: 6.71 fixed this in AutoCQResume}
      else
        Write('Number of seconds between start of transmissions : ') {KK1L: 6.72}
    else
      Write('Number of seconds of listening time : ');

    TempString := '';

    repeat
      repeat until NewKeyPressed;

      Key := UpCase(NewReadKey);

      if Key = EscapeKey then
      begin
          //        RemoveAndRestorePreviousWindow;
        Exit;
      end;

      if Key = BackSpace then
        if length(TempString) > 0 then
        begin
          TempString[0] := CHR(length(TempString) - 1);
            //{WLI}                     GoToXY (WhereX - 1, WhereY);
            //{WLI}                     ClrEol;
        end;

      if (Key >= '0') and (Key <= '9') then
      begin
        TempString := TempString + Key;
        Write(Key);
      end;

    until (length(TempString) = 2) or (Key = CarriageReturn);

    Val(TempString, Time, Result);
    Time := Time * 2;

  until (Time >= 1) and (Time <= 99);

  AutoCQDelayTime := Time;

  //  RemoveAndRestorePreviousWindow;
  AutoCQResume(False);
end;

procedure ShowPartialCallMults(WindowString: CallPtr {CallString});

var
  TestString                            : ShortString;
  //  TestString1                           : string;
  TempString                            : ShortString;
  TempExchange                          : ContestExchange;
  Distance, Heading                     : integer;

begin
//  if not PartialCallMultsEnable then Exit;
  if ActiveMainWindow <> awCallWindow then if ActiveDomesticMult <> GridSquares then Exit;          

  if length(WindowString^) < 2 then Exit;
  if length(WindowString^) < 3 then DispalayNewMult(SW_HIDE);

  if DoingDomesticMults then
   begin                                           // Gav 4.44.8      Uncommented this section
    TempString := WindowString^;
    while TempString <> '' do
    begin
      TestString := RemoveFirstString(TempString);
      TempExchange.QTHString := RemoveFirstString(TestString);
      if not (StringIsAllNumbersOrSpaces(TempExchange.QTHString)) then
        if FoundDomesticQTH(TempExchange) then
        begin
          VisibleLog.ShowDomesticMultiplierStatus(TempExchange.DomesticQTH);
          Exit;
        end;
    end;
  end
 else VisibleLog.ShowMultiplierStatus(WindowString);
end;

procedure CheckEverything(var KeyChar: Char; var WindowString: Str80);

{ This procedure gets called in the WaitForKeyPressed loop from the
  WindowEditor procedure.  If you want something done in the background
  while we are waiting for the operator to press a key while in the
  CQ or Exchange window, this is a good place to put it.  Note that this
  routine does not get called from some of the other possible places to
  be waiting for a key - like the Control-J menu, or while repeating a
  function key message.

  If you do something here that takes a long time, you should keep an
  eye on KeyPressed and exit out of here quickly (obviously - without
  affecting the value of KeyPressed or doing a ReadKey).          }

var
  Result                                : integer;
  BandMapInitialExchange                : Str20;
  TimeOut                               : Byte;
  PacketChar                            : Char;

begin
//  CheckRITKeys;

  //   if ActiveMultiPort <> NoPort then CheckMultiState;
     //  if ActiveRTTYPort <> NoPort then CheckRTTY;

        {KK1L: 6.72 Moved here to speed up SCP. UpdateTimeAndRateDisplays hogs a bit of time now.}

  if (ActiveWindow = CallWindow) and (SCPMinimumLetters > 0) and (not NewKeyPressed) then
    VisibleLog.SuperCheckPartial(WindowString, True, ActiveRadioPtr); {KK1L: 6.73 Added ActiveRadio}

  {UpdateTimeAndRateDisplays (True, True); {KK1L: 6.72 Moved from here to the end of the procedure.}

  Packet.CheckPacket;

  { Updated the MultplierStatus and grid map based upon the active band
    and mode IF they are different than the last time we were here }

  if (ActiveBand <> RememberBand) or (ActiveMode <> RememberMode) then
  begin
    UpdateTotals2;

    if ((MultByBand and (ActiveBand <> RememberBand)) or
      (MultByMode and (ActiveMode <> RememberMode))) then
    begin
      VisibleLog.ShowRemainingMultipliers;
      VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);
    end;

    if ActiveBand <> RememberBand then
    begin
      BandMapBand := ActiveBand;
      BandMapMode := ActiveMode; {KK1L: 6.69}
      DisplayBandMap;
    end;

    RememberBand := ActiveBand;
    RememberMode := ActiveMode;

      //         if VisibleDupesheetEnable then
    VisibleLog.DisplayVisibleDupeSheet(ActiveBand, ActiveMode);
  end;

  { Special trap if we are in debug or read in log mode }

  if Debug {or ReadInLog} then
  begin
    repeat
        //            if ActiveMultiPort <> NoPort then CheckMultiState;
      UpdateTimeAndRateDisplays(True, True);
      Packet.CheckPacket;
    until (not CWStillBeingSent) or NewKeyPressed;

    if NewKeyPressed then
    begin
      Debug := False;
{
      if ReadInLog then
      begin
        ReadInLog := False;
        Close(ReadInLogFileRead);
      end;
}
      KeyChar := EscapeKey;
          //{WLI}             SendMorse ('SK');
    end
    else
    begin

          { If we are in the exchange window, do a Return to log the QSO }

//      if Debug or (ReadInLog and not (ActiveWindow = CallWindow)) then
      begin
        KeyChar := CarriageReturn;
        Exit;
      end;

          { We are in the call window }
{
      if ReadInLog then
      begin
        if (length(ReadInCallsign) = length(WindowString)) and
          (length(ReadInCallsign) > 0) then
          KeyChar := CarriageReturn
        else
          if WindowString = '' then
          begin
            ReadInCallsign := GetNextCallFromReadInLog;
            KeyChar := ReadInCallsign[1];
          end
          else
            KeyChar := ReadInCallsign[length(WindowString) + 1];
      end
      else

//Debug doesn't get a callsign from here - it gets it from either
//a QSL Message or a CQ

        Exit;
}
    end;

  end;

  { Do all the right things with the new callsign }
{
  if (ActiveWindow = CallWindow) and PartialCallEnable then
    if Sheet.TwoLetterCrunchProcess(WindowString) then
      begin
        VisibleLog.GeneratePartialCallList(WindowString,
          ActiveBand,
          ActiveMode,
          PossibleCallList);

        DisplayPossibleCalls(PossibleCallList);
      end;
}
  {KK1L: 6.72 Moved ahead of UpdateTimeAndRateDisplays to boost reation time}
  {IF (ActiveWindow = CallWindow) AND (SCPMinimumLetters > 0) AND (NOT NewKeyPressed) THEN }
  {    VisibleLog.SuperCheckPartial (WindowString, True);                                  }

  if (DualingCQState <> NoDualingCQs) and not (CWStillBeingSent or DVPMessagePlaying or DVKMessagePlaying) then
    case DualingCQState of

      DualSendingQSL, SendingDupeMessage:
        begin
          //{WLI}                 SwapRadios;
          //{WLI}                 SendCrypticMessage (GetCQMemoryString (ActiveMode, AltF1)); {KK1L: 6.73 Added mode}

          if (ActiveMode = Phone) and DVPActive then
          begin
            TimeOut := 0;

            repeat
              Sleep(5);
              inc(TimeOut);
            until DVPMessagePlaying or (TimeOut > 60) or DVKMessagePlaying;
          end;

          DualingCQState := DualSendingCQ;
          InactiveRigCallingCQ := False;
          QuickDisplay('Dualing CQ mode active.  Use Control-Dash to cancel');
        end;

      DualSendingExchange:
        begin
          if GetCQMemoryString(ActiveMode, AltF2) <> '' then {KK1L: 6.73 Added mode}
          begin
              {KK1L: 6.73 Added mode}
       //{WLI}                     SendCrypticMessage (ControlA + ControlB + GetCQMemoryString (ActiveMode, AltF2));
            QuickDisplay('Dualing CQ mode active.  Sending dummy CQ on inactive radio');

            if (ActiveMode = Phone) and DVPActive then
            begin
              TimeOut := 0;

              repeat
                Sleep(5);
                inc(TimeOut);
              until DVPMessagePlaying or (TimeOut > 60) or DVKMessagePlaying;
            end;
          end
          else
            QuickDisplay('Dualing CQ mode active.  No CQ found in AltF2 to send on inactive radio.');

          DualingCQState := DualGettingExchange;
        end;

      DualSendingCQ:
        if (WindowString = '') and (ActiveWindow = CallWindow) then
        begin
            //{WLI}                     SwapRadios;
            //{WLI}                     SendFunctionKeyMessage (AltF1, CQOpMode);

          if (ActiveMode = Phone) and DVPActive then
          begin
            TimeOut := 0;

            repeat
              Sleep(5);
              inc(TimeOut);
            until DVPMessagePlaying or (TimeOut > 60) or DVKMessagePlaying;
          end;
        end;

    end;

  { W9RE }

  if KeyersSwapped then
  begin
    if (ActiveMode = CW) and not CWStillBeingSent then SetUpToSendOnActiveRadio;

    if (ActiveMode = Phone) then
    begin
      if DVPActive and not DVPMessagePlaying then SetUpToSendOnActiveRadio;
          //wli               if (ActiveDVKPort <> NoPort) and not DVKMessagePlaying then SetUpToSendOnActiveRadio;
    end;
  end;

  if (ActiveMode = CW) and (SendExchangeKeyWhenCWHasStopped <> NullKey) then
    if not CWStillBeingSent then
    begin
        //{WLI}             ProcessExchangeFunctionKey (SendExchangeKeyWhenCWHasStopped);
      SendExchangeKeyWhenCWHasStopped := NullKey;
    end;

  if (DualingCQState = DualSendingCQ) and (WindowString <> '') and
    (ActiveWindow = CallWindow) then
  begin
      //{WLI}            SwapRadios;
    DualingCQState := WaitingForCallsignInput;
    QuickDisplay('Dualing CQ mode active.  Enter rest of call that answered then ENTER');
  end;

  { See if there is something to be done as a result of a change in the
    band map blinking call. }

  if BandMapEnable then
    if BandMapBlinkingCall <> BandMapInfoCall then { Different call }
    begin
      if BandMapBlinkingCall <> '' then
      begin
        BandMapInitialExchange := InitialExchangeEntry(BandMapBlinkingCall);

        if TwoRadioState <> CallReady then
        begin
                //          SaveSetAndClearActiveWindow(DupeInfoWindow);
          WriteLn(BandMapBlinkingCall);
          Write(BandMapInitialExchange);
                //          RestorePreviousWindow;
        end;

            {  Moved this down 7 lines because it would over-write info for CQ QSO in
               progress.

                            ShowStationInformation (BandMapBlinkingCall); }

        if (ActiveWindow = CallWindow) and
          (OpMode = SearchAndPounceOpMode) and
          (WindowString <> BandMapBlinkingCall) and
          (BandMapBand = ActiveBand) and
          (OkayToPutUpBandMapCall) and
          (BandMapCallWindowEnable) then
        begin
                { Moved this from up 7 lines in 5.88 }

          ShowStationInformation(@BandMapBlinkingCall);

          WindowString := BandMapBlinkingCall;
                //{WLI}                        ClrScr;
                //{WLI}                        Write (WindowString + '  ' + BandMapInitialExchange);
                //{WLI}                        GoToXY (Length (WindowString) + 1, WhereY);

                                       { Why is this? - Removed in 6.44 }

                                       { RestorePreviousWindow;  }

          BandMapEntryInCallWindow := True;
        end;
      end
      else { Need to clear out the old call }

          { BandMapBlinkingCall is now null }

      begin
        if (ActiveWindow = CallWindow) then
        begin

                { Clear this out if it is what I put up there before }

          if WindowString = BandMapInfoCall then
          begin
            EscapeDeletedCallEntry := WindowString;
            WindowString := '';
                    //{WLI}                         ClrScr;

                                            { In 6.44 - moved this into WindowString = BandMapInfoCall }

            if ExchangeWindowString <> '' then
            begin
              EscapeDeletedExchangeEntry := ExchangeWindowString;
              ExchangeWindowString := '';
                        //              SaveSetAndClearActiveWindow(ExchangeWindow);
              Write(ExchangeWindowString);
              ExchangeWindowCursorPosition := length(ExchangeWindowString) + 1;
                        //              RestorePreviousWindow;
            end;

                    { Added in 6.61 to fix entries not coming up later }

            OkayToPutUpBandMapCall := True;
          end;
        end;
      end;

      BandMapInfoCall := BandMapBlinkingCall;
    end;

  UpdateTimeAndRateDisplays(True, True); {KK1L: 6.72 Moved here to speed up SCP and other things}

  if RadioOnTheMove[ActiveRadio] then {KK1L: 6.73 To fix call popping up after already working them.}
    OkayToPutUpBandMapCall := True
  else
    OkayToPutUpBandMapCall := False;

end;

procedure GoToNextBandMapFrequency;

var
  Frequency                             : LONGINT;

begin

 //  if (CommandUseInactiveRadio) and
 //    (NextNonDupeEntryInBandMap(InActiveRadioPtr.BandMemory {BandMemory[InactiveRadio]}, InActiveRadioPtr.ModeMemory {ModeMemory[InactiveRadio]})) then
 //    SetUpBandMapEntry(BandMapCursorData, InactiveRadio)
 // else
 //    if NextNonDupeEntryInBandMap(ActiveBand, ActiveMode) then
    begin

  //   BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
       {
       SetUpBandMapEntry(BandMapCursorData, ActiveRadio);

      if ActiveWindow = ExchangeWindow then
      begin
                      ClrScr;
        ExchangeWindowString := '';
            //        RestorePreviousWindow;
      end;   }
    end;
end;

{KK1L: 6.68}

procedure GoToNextMultBandMapFrequency;

var
  Frequency                             : LONGINT;

begin
  if (CommandUseInactiveRadio) and {KK1L: 6.73}
    (NextMultiplierEntryInBandMap(InActiveRadioPtr.BandMemory {BandMemory[InactiveRadio]}, InActiveRadioPtr.ModeMemory {ModeMemory[InactiveRadio]})) then
    SetUpBandMapEntry(BandMapCursorData, InactiveRadio)
  else
    if NextMultiplierEntryInBandMap(ActiveBand, ActiveMode) then
    begin
      SetUpBandMapEntry(BandMapCursorData, ActiveRadio); {KK1L: Added ActiveRadio}

      if ActiveWindow = ExchangeWindow then
      begin
            //{WLI}                 ClrScr;
        ExchangeWindowString := '';
            //        RestorePreviousWindow;
      end;
    end;
end;

procedure GoToNextDisplayedBandMapFrequency;

var
  Frequency                             : LONGINT;

begin
  if (CommandUseInactiveRadio) and {KK1L: 6.73}
    (NextNonDupeEntryInDisplayedBandMap(InActiveRadioPtr.BandMemory {BandMemory[InactiveRadio]},
    InActiveRadioPtr.ModeMemory { ModeMemory[InactiveRadio]})) then
    SetUpBandMapEntry(BandMapCursorData, InactiveRadio)
  else
    if NextNonDupeEntryInDisplayedBandMap(ActiveBand, ActiveMode) then
    begin
      SetUpBandMapEntry(BandMapCursorData, ActiveRadio); {KK1L: Added ActiveRadio}

      if ActiveWindow = ExchangeWindow then
      begin
            //{WLI}                 ClrScr;
        ExchangeWindowString := '';
            //        RestorePreviousWindow;
      end;
    end;
end;

{KK1L: 6.68}

procedure GoToNextMultDisplayedBandMapFrequency;

var
  Frequency                             : LONGINT;

begin
  if (CommandUseInactiveRadio) and {KK1L: 6.73}
    (NextMultiplierEntryInDisplayedBandMap(InActiveRadioPtr.BandMemory {BandMemory[InactiveRadio]},
    InActiveRadioPtr.ModeMemory {ModeMemory[InactiveRadio]})) then
    SetUpBandMapEntry(BandMapCursorData, InactiveRadio)
  else
    if NextMultiplierEntryInDisplayedBandMap(ActiveBand, ActiveMode) then
    begin
      SetUpBandMapEntry(BandMapCursorData, ActiveRadio); {KK1L: Added ActiveRadio}

      if ActiveWindow = ExchangeWindow then
      begin
            //{WLI}                 ClrScr;
        ExchangeWindowString := '';
            //        RestorePreviousWindow;
      end;
    end;
end;

function FoundCommand(var SendString: Str160): boolean;
var
  FileName, CommandString               : ShortString;
  FirstCommand                          : boolean;
  TempInt, Result1                      : integer;
begin
  Result := uProcessCommand.FoundCommand(SendString);
end;

procedure DoAltZ({var WindowString: string {; VAR KeyChar: CHAR});

begin

  tSetExchWindInitExchangeEntry;
  CheckAndSetInitialExchangeCursorPos;
  ShowStationInformation(@CallWindowString);

  {

  if FRM.ExchangeWindow.Focused then
          BEGIN
  //        ExchangeWindowString     := InitialExchangeEntry (CallWindowString);
          FRM.ExchangeWindow.Text:= InitialExchangeEntry (CallWindowString);

  //WLI         ClrScr;
  //WLI         Write (ExchangeWindowString);

  //        TR6.74 - because InitialExchangeEntry no longer does this

          IF InitialExchangeOverwrite THEN
              InitialExchangePutUp := FRM.ExchangeWindow.Text <> '';

          IF InitialExchangeCursorPos = AtStart THEN
  //WLI            GoToXY (1, 1)
          ELSE
  //WLI             GoToXY (1, Length (ExchangeWindowString) + 1);

  //WLI         ExchangeWindowCursorPosition := WhereY;
          ShowStationInformation (frm.CallWindow.Text);
          END
      ELSE
          BEGIN
  //        IF ActiveWindow = CallWindow THEN
  if FRM.callWindow.Focused then

              ExchangeWindowString := InitialExchangeEntry (WindowString)
          ELSE
              ExchangeWindowString := InitialExchangeEntry (CallWindowString);

  //        TR6.74 - because InitialExchangeEntry no longer does this

          IF InitialExchangeOverwrite THEN
              InitialExchangePutUp := ExchangeWindowString <> '';

          SaveSetAndClearActiveWindow (ExchangeWindow);
          Write (ExchangeWindowString);

          IF InitialExchangeCursorPos = AtStart THEN
  //WLI             GoToXY (1, 1)
          ELSE
  //WLI             GoToXY (1, Length (ExchangeWindowString) + 1);

  //WLI         ExchangeWindowCursorPosition := WhereY;
          RestorePreviousWindow;

          ShowStationInformation (WindowString);

          KeyChar := ControlX;
          END;
     }
end;

procedure WindowEditor(var WindowString: string;
  var KeyChar: Char;
  var ExtendedKeyChar: Char);

{ This procedure is inteded to do all the editing functions for the
  given window string.  It is assumed that the window is set up already
  for the string.  If there is some inital value for the string, pass it
  in WindowString, otherwise make it a null string.  If a return, a vertical
  cursor move, escape with no input, or a function key is entered, the
  procedure will halt and return the character that was received.  If the
  key is a function key, only the null character is read.

  A new change is to not do anymore dupechecks in this procedure.  If a
  dupe check is attempted, the procedure will exit with the KeyChar =
  SpaceBar.  Dupe checks are attempted in one of two ways:  If the
  space bar is pressed and the active window is the call window or if the
  space bar is pressed and the active window is the exchange window and
  there is no data entered yet.                                          }

var
  Number, Result, CursorPosition, CharPointer, InsertCursorPosition: integer;
  BandMapFreq, BandMapQSX, Freq         : LONGINT;
  TempKey, PreviousCursorChar           : Char;
  TempString                            : string[255];
  PacketSpotCall, Name, BandMapCall, Call: CallString;
  FileName, FirstString                 : Str80;
  TempBand                              : BandType;
  TempFreq                              : LONGINT;
  TempMode                              : ModeType;
  Dest                                  : Byte;
  TempExchange                          : ContestExchange;
  NumberString, FrequencyString         : Str20;
  FirstCommand, FootSwitchPressed       : boolean;
  RealFreq                              : REAL;
  TestByte, TimeOut                     : Byte;
  TempStr, TempStr2, VFOString          : Str80; {KK1L: 6.73 added VFOString}
  VFOChar                               : Char; {KK1L 6.73}
  RadioToSet                            : RadioType; {KK1L: 6.73}

begin
  {    ExtendedKeyChar := Chr (0);

      IF (ControlBMemory <> '') OR (OnDeckCall <> '') THEN
          BEGIN

  {        IF ActiveWindow = CallWindow THEN
              CallWindowString := WindowString;

          Write (WindowString);

          IF (OnDeckCall <> '') AND InactiveRigCallingCQ THEN
              BEGIN
              IF ActiveMode = CW THEN REPEAT UNTIL NOT CWStillBeingSent;
               SwapRadios;
              SetUpToSendOnActiveRadio;
              InactiveRigCallingCQ := False;
              END;

          ControlBMemory := '';
          OnDeckCall := '';
          END;

      REPEAT
          IF SpecialCommand = SendF1Message THEN
              BEGIN
              {KK1L: We get in here when hitting enter from S&P with nothing in either window!}
  {            InactiveRigCallingCQ := False;
              SetUpToSendOnActiveRadio;

              IF MessageEnable AND NOT ((CWTone = 0) AND Debug) THEN
  {                SendFunctionKeyMessage (F1, CQOpMode);

              {KK1L: 6.68 Set LastCQ stuff when calling CQ by the enter key with no call entered}
  {            IF FrequencyDisplayed THEN
                  BEGIN
                  LastCQFrequency := LastDisplayedFreq [ActiveRadio];
                  LastCQMode      := ActiveMode;
                  END
              ELSE
                  LastCQFrequency := 0;

              SpecialCommand := NoSpecialCommand;
              END;

          IF SpecialCommand = AutoAltDSpaceBar THEN  { From AutoAltDEnable }
  {            BEGIN
              KeyChar := SpaceBar;
              Exit;
              END;

  {        CheckForRemovedDupeSheetWindow;

          {IF ((ActiveWindow = CallWindow) AND (WindowString = '')) OR
             ((ActiveWindow = ExchangeWindow) AND (CallWindowString = '')) THEN

  {        IF (ActiveMultiPort <> NoPort) AND (MultiInfoMessage <> '') THEN
              MarkTime (MultiInfoMessageTimeout);

          REPEAT
              IF (ActiveMultiPort <> NoPort) AND (MultiInfoMessage <> '') THEN
                  IF MicroTimeElapsed (MultiInfoMessageTimeout) > 10000 THEN
                      IF NOT K1EANetworkEnable THEN
                          BEGIN
                          SendMultiInfoMessage (ActiveBand, ActiveMode, 'OpeRATor is asleep!');
                          MarkTime (MultiInfoMessageTimeout);
                          END;

              { CheckEverything does a bunch of housecleaning }

  {            CheckEverything (KeyChar, WindowString);

              FootSwitchPressed := FootSwitch;

              IF FootSwitchPressed THEN
                  BEGIN
                  CASE FootSwitchMode OF

                      FootSwitchF1:
                          BEGIN
                          IF OpMode = CQOpMode THEN
                           SendFunctionKeyMessage (F1, CQOpMode)
                          ELSE
  ProcessExchangeFunctionKey (F1);

                          FootSwitchPressed := False;
                          END;

                      FootSwitchControlEnter:
                          BEGIN
                          FootSwitchPressed := False;
                          BeSilent := True;
                          KeyChar := CarriageReturn;
                          Exit;
                          END;

                      FootSwitchDisabled:
                          FootSwitchPressed := False;

                      FootSwitchLastCQFreq:
                          BEGIN
                          FootSwitchPressed := False;
                          END;

                      FootSwitchNextBandMap:
                          BEGIN
                          GoToNextBandMapFrequency;
                          FootSwitchPressed := False;
                          END;

                      FootSwitchNextMultBandMap:
                          BEGIN
                          GoToNextMultBandMapFrequency;
                          FootSwitchPressed := False;
                          END;

                      FootSwitchNextDisplayedBandMap:
                          BEGIN
                          GoToNextDisplayedBandMapFrequency;
                          FootSwitchPressed := False;
                          END;

                      FootSwitchNextMultDisplayedBandMap:
                          BEGIN
                          GoToNextMultDisplayedBandMapFrequency;
                          FootSwitchPressed := False;
                          END;

                      FootSwitchUpdateBandMapBlinkingCall:
                          BEGIN
                          UpdateBlinkingBandMapCall;
                          FootSwitchPressed := False;
                          END;

                      FootSwitchDupeCheck:
                          BEGIN
                          DupeCheckOnInactiveRadio;
                          FootSwitchPressed := False;
                          END;

                      StartSending:
                          IF ActiveMode = CW THEN
                              BEGIN
                              KeyChar := StartSendingNowKey;
                              Exit;
                              END;

                      SwapRadio:
                          BEGIN
                           SwapRadios;
                          FootSwitchPressed := False;
                          Str (SpeedMemory[InactiveRadio], SpeedString); {KK1L: 6.73 Used to use a variable CheckSpeed}
  {                        END;

                      Normal:
                          BEGIN
                          IF TwoRadioState <> TwoRadiosDisabled THEN
                              CheckTwoRadioState (FootswitchWasPressed);

                          FootSwitchPressed := False;
                          END;
                      END;

                  END;

              IF (AutoSAPEnable) AND (OpMode = CQOpMode) THEN
                  IF (RadioMovingInBandMode [ActiveRadio]) THEN
                      BEGIN
                      KeyChar := TabKey;
                      Exit;
                      END;

              Wait (6);

              IF (ParamCount > 0) AND (ParamStr (1) = 'EXIT') THEN ExitProgram;

          UNTIL NewKeyPressed OR ReadInLog OR Debug OR FootSwitchPressed;

          IF FootSwitchPressed THEN
              BEGIN
              CASE FootSwitchMode OF
                  QSONormal: BEGIN
                             KeyChar := CarriageReturn;
                             Exit;
                             END;

                  QSOQuick:  BEGIN
                             IF LookingForCQExchange THEN
                                 KeyChar := QuickQSLKey1
                             ELSE
                                 KeyChar := CarriageReturn;
                             Exit;
                             END;
                  END;
              END;

          IF NOT (ReadInLog OR Debug) THEN
              BEGIN
              KeyChar := Upcase (NewReadKey);

              IF KeyChar IN AccentedChars THEN
                  BEGIN
                  IF KeyChar = Chr(132) THEN KeyChar := Chr(142);
                  IF KeyChar = Chr(134) THEN KeyChar := Chr(143);
                  IF KeyChar = Chr(148) THEN KeyChar := Chr(153);
                  END;
              END;

          CursorPosition := WhereX;

          IF NOT (((KeyChar >= '0') AND (KeyChar <= '9')) OR
                  ((KeyChar >= 'A') AND (KeyChar <= 'Z'))) THEN
                     IF ActiveWindow = ExchangeWindow THEN
                         InitialExchangePutUp := False;

          IF (OpMode = CQOpMode) AND (ActiveMode = CW) THEN
              IF (ActiveWindow = CallWindow) THEN
                  IF Length (CallWindowString) >= 1 THEN
                      IF KeyChar = StartSendingNowKey THEN
                          Exit;

          IF K5KA.ModeEnabled AND CWStillBeingSent AND
             ((TwoRadioState = Idle) OR (TwoRadioState = CallReady)) AND
             (((KeyChar >= '0') AND (KeyChar <= '9')) OR
              ((KeyChar >= 'A') AND (KeyChar <= 'Z')) OR
               (KeyChar = BackSpace)) THEN
                   BEGIN
                   IF KeyChar = BackSpace THEN
                       Delete (K5KA.AltDString, Length (K5KA.AltDString), 1)
                   ELSE
                       K5KA.AltDString := K5KA.AltDString + KeyChar;

                   IF K5KA.AltDString <> '' THEN
                       DupeCheckOnInactiveRadio
                   ELSE
                       RemoveWindow (DupeInfoWindow);

                   Continue;
                   END;

          IF (ActiveWindow = ExchangeWindow) AND (Length (WindowString) >= 2) AND DoingDomesticMults THEN
              BEGIN

              TempExchange.QTHString := GetLastString (WindowString);

              IF DoingDomesticMults AND FoundDomesticQTH (TempExchange) THEN
                  VisibleLog.ShowDomesticMultiplierStatus (TempExchange.DomesticQTH);
              END;

          CASE KeyChar OF

            ControlBackSpace:

                SendMorse ('Undo');

            '"': BEGIN
                 RITEnable := False;
                 RITClear;

                 IF ActiveMultiPort <> NoPort THEN
                     BEGIN
                     TempString := QuickEditResponse ('Enter (BAND MESSAGE) : ', 50);
                     GetRidOfPrecedingSpaces (TempString);

                     IF (TempString <> '') AND (TempString <> EscapeKey) THEN
                         BEGIN
                         FirstString := UpperCase (PrecedingString (TempString, ' '));

                         Dest := $FF;

                         IF FirstString = '160' THEN Dest := MultiBandAddressArray [Band160];
                         IF FirstString =  '80' THEN Dest := MultiBandAddressArray [Band80];
                         IF FirstString =  '40' THEN Dest := MultiBandAddressArray [Band40];
                         IF FirstString =  '30' THEN Dest := MultiBandAddressArray [Band30];
                         IF FirstString =  '20' THEN Dest := MultiBandAddressArray [Band20];
                         IF FirstString =  '17' THEN Dest := MultiBandAddressArray [Band17];
                         IF FirstString =  '15' THEN Dest := MultiBandAddressArray [Band15];
                         IF FirstString =  '12' THEN Dest := MultiBandAddressArray [Band12];
                         IF FirstString =  '10' THEN Dest := MultiBandAddressArray [Band10];
                         IF FirstString =   '6' THEN Dest := MultiBandAddressArray [Band6];
                         IF FirstString =   '2' THEN Dest := MultiBandAddressArray [Band2];
                         IF FirstString = '222' THEN Dest := MultiBandAddressArray [Band222];
                         IF FirstString = '432' THEN Dest := MultiBandAddressArray [Band432];
                         IF FirstString = '902' THEN Dest := MultiBandAddressArray [Band902];
                         IF FirstString = '1GH' THEN Dest := MultiBandAddressArray [Band1296];
                         IF FirstString = '2GH' THEN Dest := MultiBandAddressArray [Band2304];

                         IF Dest <> $FF THEN RemoveFirstString (TempString);

                         IF K1EANetworkEnable THEN
                             SendMultiMessage ('T' + K1EAStationID + '0 ' + TempString)
                         ELSE
                             SendMultiCommand (MultiBandAddressArray [ActiveBand],
                                               Dest,
                                               MultiTalkMessage,
                                               TempString);
                         END;
                     END;

                 RITEnable := True;
                 END;

            EscapeKey:
                BEGIN

                IF (OpMode = CQOpMode) AND (BandMapBand = BandMemory[InactiveRadio]) THEN
                    CallLastTimeIWasHere := '';

                IF (TwoRadioState = StationCalled) THEN
                    BEGIN
                    CheckTwoRadioState (EscapePressed);
                    WindowString := '';
                    ClrScr;
                    NameCallsignPutUp := '';
                    SetUpToSendOnActiveRadio;
                    Exit;
                    END;

                IF DualingCQState <> NoDualingCQs THEN
                    BEGIN
                    DualingCQState := NoDualingCQs;
                    QuickDisplay ('AutoCQ function aborted with ESCAPE key.  Press again to stop CQ');
                    END
                ELSE
                    IF ((ActiveMode = CW) AND CWStillBeingSent) OR
                       ((ActiveMode = Phone) AND DVPEnable AND (DVPMessagePlaying OR DVKMessagePlaying)) OR
                       (ActiveMode = Phone) AND (ActiveDVKPort <> NoPort) AND
                        DVKRecentlyStarted (400) THEN
                            BEGIN
                            IF ActiveMode = CW THEN
                                BEGIN
                                FlushCWBufferAndClearPTT;
                                DualingCQState := NoDualingCQs;
                                QuickDisplay ('ENTER a callsign.  SPACE for dupecheck.  Alt-H for help.');
                                END
                            ELSE
                                IF DVPEnable AND DVPActive THEN
                                    BEGIN
                                    DVPStopPlayback;

                                    TimeOut := 0;

                                    IF ActiveMode = Phone THEN
                                        REPEAT
                                            Wait (5);
                                            Inc (TimeOut);
                                        UNTIL (NOT DVPMessagePlaying) OR (TimeOut > 60);
                                    END
                                ELSE
                                    SendDVKMessage('DVK0');
                            END
                        ELSE
                            BEGIN
                            IF WindowString = '' THEN
                                BEGIN
                                InactiveRigCallingCQ := False;
                                Exit;
                                END;

                            IF ActiveWindow = CallWindow THEN
                                EscapeDeletedCallEntry := WindowString
                            ELSE
                                EscapeDeletedExchangeEntry := WindowString;

                            WindowString := '';
                            ClrScr;
                            NameCallsignPutUp := '';
                            END;
                    END;

            ControlA:
                IF CursorPosition > 1 THEN
                    BEGIN
                    REPEAT
                        Dec (CursorPosition);
                        PreviousCursorChar := WindowString [CursorPosition - 1];
                    UNTIL ((WindowString [CursorPosition] <> ' ') AND
                           (PreviousCursorChar = ' ')) OR (CursorPosition = 1);
                    GoToXY (CursorPosition, WhereY);
                    END;

            ControlB:
                IF (Packet.PacketSerialPort <> NoPort) OR
                   (ActiveMultiPort <> NoPort) OR
                   (ActiveRTTYPort <> NoPort) THEN
                    PacketWindow;

            ControlC: Exit;

            ControlD:
                IF CursorPosition <= Length (WindowString) THEN
                    GoToXY (CursorPosition + 1, WhereY);

            ControlE: IF (MultiInfoMessage <> '') OR K1EANetworkEnable THEN
                          DisplayMultiMessages
                      ELSE
                          Exit;

            ControlF:
                IF CursorPosition <= Length (WindowString) THEN
                    BEGIN
                    REPEAT
                        PreviousCursorChar := WindowString [CursorPosition];
                        Inc (CursorPosition);
                    UNTIL ((WindowString [CursorPosition] <> ' ') AND
                           (PreviousCursorChar = ' ')) OR (CursorPosition = Length (WindowString) + 1);
                    GoToXY (CursorPosition, WhereY);
                    END;

            ControlG:
                IF ActiveDomesticMult = GridSquares THEN
                    VisibleLog.DisplayGridMap (ActiveBand, ActiveMode)
                ELSE
                    IF CursorPosition <= Length (WindowString) THEN
                        BEGIN
                        FOR CharPointer := CursorPosition TO Length (WindowString) - 1 DO
                            WindowString [CharPointer] := WindowString [CharPointer + 1];

                        WindowString [0] := Chr (Length (WindowString) - 1);
                        ClrScr;
                        Write (WindowString);
                        GoToXY (CursorPosition, WhereY);
                        END
                    ELSE
                        IF CursorPosition = Length (WindowString) THEN
                            BEGIN
                            ClrEol;
                            WindowString [0] := Chr (Length (WindowString) - 1);
                            END;

            ControlJ:
                IF Port [$60] = $24 THEN
                    BEGIN
                    ProcessConfigurationInput;
                    RemoveWindow (QuickCommandWindow);

                    END
                ELSE
                    BEGIN

                    VFOString := WindowString;
                    Delete (VFOString, 1, Length (VFOString)-1);
                    VFOChar := VFOString[1];
                    TempString := WindowString;
                    Delete (TempString, Length (TempString), 1);

                    IF ((VFOString = 'A') OR (VFOString = 'B')) AND
                       (StringIsAllNumbersOrDecimal (TempString)) THEN
                        WindowString := TempString
                    ELSE
                        VFOChar := 'A';

                    IF (StringIsAllNumbersOrDecimal (WindowString)) AND
                       (ActiveWindow = CallWindow) AND
                       (Length (WindowString) >= 3) THEN
                           BEGIN
                           IF Length (WindowString) = 3 THEN
                               BEGIN
                               CASE BandMemory[InactiveRadio] OF
                                   Band160: TempString := '1'   + WindowString;
                                   Band80:  TempString := '3'   + WindowString;
                                   Band40:  TempString := '7'   + WindowString;
                                   Band30:  TempString := '10'  + WindowString;
                                   Band20:  TempString := '14'  + WindowString;
                                   Band17:  TempString := '18'  + WindowString;
                                   Band15:  TempString := '21'  + WindowString;
                                   Band12:  TempString := '24'  + WindowString;
                                   Band10:  TempString := '28'  + WindowString;
                                   Band6:   TempString := '50'  + WindowString;
                                   ELSE     TempString := '144' + WindowString;
                                   END;
                               END
                           ELSE
                               TempString := WindowString;

                           IF StringHas (TempString, '.') THEN
                               BEGIN
                               Val (TempString, RealFreq, Result);
                               Freq := Round (RealFreq * 1000.0);
                               END
                           ELSE
                               Val (TempString + '000', Freq, Result);

                           TempMode := ModeMemory[InactiveRadio];

                           IF Result = 0 THEN
                               BEGIN
                               PutRadioOutOfSplit(InactiveRadio);
                               SetRadioFreq (InactiveRadio, Freq, TempMode, VFOChar);
                               END;

                           CalculateBandMode (Freq, TempBand, TempMode);

                           BandMemory [InactiveRadio] := TempBand;

                           WindowString := '';
                           ClrScr;
                           END
                    ELSE
                        BEGIN
                        BeSilent := True;
                        KeyChar := CarriageReturn;
                        Exit;
                        END;
                    END;

            ControlK: BEGIN

                      TempString := QuickEditResponse ('Do you really want to clear the dupesheet? (Spell Y E S/NO ) : ', 3);

                      IF UpperCase (TempString) = 'YES' THEN
                          BEGIN
                          MoveEditableLogIntoLogFile;
                          UpdateTotals;
                          Sheet.ClearDupeSheet;
                          QuickDisplay ('Sheet cleared!  To restore, delete RESTART.BIN and start program over.');
                          END;
                      END;

            ControlL: BEGIN
                      ViewLogFile;
                      VisibleDupeSheetRemoved := True;
                      END;

            ControlN:
                BEGIN
                RITEnable := False;

                AddedNoteString := QuickEditResponse ('Enter note : ', 60);

                IF (AddedNoteString <> '') AND (AddedNoteString <> EscapeKey) THEN
                    BEGIN
                    IF ComputerID = NullKey THEN
                        AddedNoteString := '; ' + GetDateString + ' ' +
                                                  GetTimeString + ' : ' +
                                                  AddedNoteString
                    ELSE
                        AddedNoteString := '; ' + GetDateString + ' ' +
                                                  GetTimeString + ' ' +
                                                  ComputerID + ': ' +
                                                  AddedNoteString;

                    WHILE Length (AddedNoteString) > 79 DO
                        Delete (AddedNoteString, Length (AddedNoteString), 1);

                    PushLogStringIntoEditableLogAndLogPopedQSO (AddedNoteString, True);
                    END;

                RITEnable := True;
                END;

            ControlO: VisibleLog.ShowMissingMultiplierReport;

            ControlP:
                BEGIN
                IF ActiveWindow = CallWindow THEN
                    BEGIN
                    ShowStationInformation (WindowString);
                    DisplayGridSquareStatus (WindowString);
                    VisibleLog.DoPossibleCalls (WindowString);
                    END
                ELSE
                    BEGIN
                    ShowStationInformation (CallWindowString);
                    DisplayGridSquareStatus (CallWindowString);
                    VisibleLog.DoPossibleCalls (CallWindowString);
                    END;

                IF ActiveRotatorPort <> NoPort THEN
                    RotorControl (LastHeadingShown);
                END;

            ControlQ:
                IF QTCsEnabled THEN
                    BEGIN
                    IF (ActiveWindow = ExchangeWindow) THEN
                        WAEQTC (CallWindowString)
                    ELSE
                        WAEQTC (WindowString);

                    DisplayTotalScore (TotalScore);

                    IF QTCNote <> '' THEN
                        BEGIN
                        PushLogStringIntoEditableLogAndLogPopedQSO ('; ' + QTCNote, True);
                        QTCNote := '';
                        END;
                    END;

            ControlR: IF ActiveWindow = CallWindow THEN
                          BEGIN
                          IF EscapeDeletedCallEntry <> '' THEN
                              BEGIN
                              WindowString := EscapeDeletedCallEntry;
                              Write (WindowString);
                              END;
                          END
                      ELSE
                          IF EscapeDeletedExchangeEntry <> '' THEN
                              BEGIN
                              WindowString := EscapeDeletedExchangeEntry;
                              Write (WindowString);
                              END;

            ControlS: IF CursorPosition > 1 THEN
                          GoToXY (CursorPosition - 1, WhereY);

            ControlT:
                IF CursorPosition <= Length (WindowString) THEN
                    BEGIN
                    TempString := WindowString;
                    TempString [0] := Chr (CursorPosition - 1);
                    CharPointer := CursorPosition;
                    REPEAT
                        Inc (CharPointer);
                    UNTIL (CharPointer = Length (WindowString)) OR
                          (WindowString [CharPointer] = ' ');

                    IF CharPointer = Length (WindowString) THEN
                        BEGIN
                        ClrEOL;
                        WindowString [0] := Chr (CursorPosition - 1);
                        END
                    ELSE
                        BEGIN
                        Inc (CharPointer);
                        FOR CharPointer := CharPointer TO Length (WindowString) DO
                            TempString := TempString + WindowString [CharPointer];
                        ClrScr;
                        Write (TempString);
                        WindowString := TempString;
                        GoToXY (CursorPosition, WhereY);
                        END;
                    END
                ELSE
                    IF CursorPosition = Length (WindowString) THEN
                        BEGIN
                        ClrEol;
                        WindowString [0] := Chr (Length (WindowString) - 1);
                        END;

            ControlU: IF Packet.PacketSerialPort <> NoPort THEN
                          BEGIN
                          IF PacketMemoryRequest THEN
                              BEGIN
                              WindowString := CallWindowString;
                              KeyChar := ControlU;
                              Exit;
                              END;
                          END
                      ELSE
                          IF ActiveRTTYPort <> NoPort THEN
                               TalkToRTTYPort;
                
            ControlV:
                BEGIN
                RunningConfigFile := True;
                ClearDupeSheetCommandGiven := False;

                FileName := QuickEditResponse ('Enter config file to execute : ', 20);

                IF (FileName <> '') AND (FileName <> EscapeKey) THEN
                    BEGIN
                    FirstCommand := False;

                    IF FileExists (FileName) THEN
                        LoadInSeparateConfigFile (FileName, FirstCommand, MyCall)
                    ELSE
                        QuickDisplayError('File not found!');

                    IF ClearDupeSheetCommandGiven THEN
                        BEGIN
                        MoveEditableLogIntoLogFile;
                        UpdateTotals;
                        Sheet.ClearDupeSheet;
                        END;

                    RunningConfigFile := False;

                    IF OpMode = CQOpMode THEN
                      PutUpCQMenu
                    ELSE
                      PutUpExchangeMenu;
                    END;
                END;

            ControlW: BEGIN
                      IF ActiveWindow = CallWindow THEN
                          EscapeDeletedCallEntry := WindowString
                      ELSE
                          EscapeDeletedExchangeEntry := WindowString;

                      WindowString := '';
                      ClrScr;
                      NameCallsignPutUp := '';
                      END;

            ControlX: Exit;

            ControlY: UpdateBlinkingBandMapCall;

            ControlZ: Exit;

            ControlDash: IF GetCQMemoryString (ActiveMode, AltF1) = '' THEN
                             QuickDisplay ('No CQ message programmed into CQ MEMORY AltF1.')
                         ELSE
                             BEGIN
                             IF DualingCQState = NoDualingCQs THEN
                                 BEGIN
                                 QuickDisplay ('Dualing CQ active.  Start entering call or Control-Dash/Escape to stop.');
                                 SendFunctionKeyMessage (AltF1, CQOpMode);
                                 DualingCQState := DualSendingCQ;

                                 IF (ActiveMode = Phone) AND DVPActive THEN
                                     BEGIN
                                     TimeOut := 0;

                                     REPEAT
                                         Wait (5);
                                         Inc (TimeOut);
                                     UNTIL DVPMessagePlaying OR (TimeOut > 60) OR DVKMessagePlaying;
                                     END;
                                 END
                             ELSE
                                 BEGIN
                                 DualingCQState := NoDualingCQs;
                                 QuickDisplay ('Dual CQ mode cancelled by Control-Dash');
                                 END;
                             END;

            ControlBackSlash:
                BEGIN
                BeSilent := True;
                KeyChar := CarriageReturn;
                Exit;
                END;

            ControlRightBracket:
                DisplayCT1BOHData;

            CarriageReturn:
                BEGIN
                BeSilent := False;

                IF WindowString = 'DEBUG' THEN
                    BEGIN
                    Debug := True;
                    WindowString := '';
                    ClrScr;
                    END;

                VFOString := WindowString;
                Delete (VFOString, 1, Length (VFOString)-1);
                VFOChar := VFOString[1];
                TempString := WindowString;
                Delete (TempString, Length (TempString), 1);

                IF ((VFOString = 'A') OR (VFOString = 'B')) AND
                   (StringIsAllNumbersOrDecimal (TempString)) THEN
                    WindowString := TempString
                ELSE
                    VFOChar := 'A';

                IF (StringIsAllNumbersOrDecimal (WindowString)) AND
                   (ActiveWindow = CallWindow) AND
                   (Length (WindowString) >= 3) THEN
                    BEGIN
                    IF Length (WindowString) = 3 THEN
                        BEGIN
                        CASE ActiveBand OF
                            Band160: TempString := '1'   + WindowString;
                            Band80:  TempString := '3'   + WindowString;
                            Band40:  TempString := '7'   + WindowString;
                            Band30:  TempString := '10'  + WindowString;
                            Band20:  TempString := '14'  + WindowString;
                            Band17:  TempString := '18'  + WindowString;
                            Band15:  TempString := '21'  + WindowString;
                            Band12:  TempString := '24'  + WindowString;
                            Band10:  TempString := '28'  + WindowString;
                            Band6:   TempString := '50'  + WindowString;
                            ELSE     TempString := '144' + WindowString;
                            END;
                        END
                    ELSE
                        TempString := WindowString;

                    IF StringHas (TempString, '.') THEN
                        BEGIN
                        Val (TempString, RealFreq, Result);
                        Freq := Round (RealFreq * 1000.0);
                        END
                    ELSE
                        Val (TempString + '000', Freq, Result);

                    IF Result = 0 THEN
                        BEGIN
                        PutRadioOutOfSplit (ActiveRadio);
                        SetRadioFreq (ActiveRadio, Freq, ActiveMode, VFOChar);
                        RadioSetFreq := Freq;
                        END;

                    TempMode := ActiveMode;

                    CalculateBandMode (Freq, TempBand, TempMode);

                    ActiveBand := TempBand;

                    IF ActiveRadio = RadioOne THEN
                        BandMemory [RadioOne] := ActiveBand
                    ELSE
                        BandMemory [RadioTwo] := ActiveBand;

                    DisplayBandMode (ActiveBand, ActiveMode, False);
                    WindowString := '';
                    ClrScr;
                    END
                ELSE  }
                    IF (Copy (WindowString, 1, 1) = '\') AND (ActiveWindow = CallWindow) THEN
                        BEGIN
                        ProcessCallWindowCommand (WindowString);
                   //     ClrScr;
                        WindowString := '';
                        END
                        {
                    ELSE
                        Exit;
                END;

            NullKey:
                BEGIN
                ExtendedKeyChar := NewReadKey;

                CASE ExtendedKeyChar OF
                    Alt1: IF BackCopyEnable THEN
                              PlayLastSeconds (2)
                          ELSE
                              IF IncrementTimeEnable THEN IncrementTime (1);

                    Alt2: IF BackCopyEnable THEN
                              PlayLastSeconds (3)
                          ELSE
                              IF IncrementTimeEnable THEN IncrementTime (2);

                    Alt3: IF BackCopyEnable THEN
                              PlayLastSeconds (4)
                          ELSE
                              IF IncrementTimeEnable THEN IncrementTime (3);

                    Alt4: IF BackCopyEnable THEN
                              PlayLastSeconds (8)
                          ELSE
                              IF IncrementTimeEnable THEN IncrementTime (4);

                    Alt5: IF BackCopyEnable THEN
                              PlayLastSeconds (16)
                          ELSE
                              IF IncrementTimeEnable THEN IncrementTime (5);

                    Alt6: IF BackCopyEnable THEN
                              BEGIN
                              SaveBackCopy (TotalContacts + 1, 5);
                              LogBackCopy (5);
                              END
                          ELSE
                              IF IncrementTimeEnable THEN IncrementTime (6);

                    Alt7: IF BackCopyEnable THEN
                              BEGIN
                              SaveBackCopy (TotalContacts + 1, 10);
                              LogBackCopy (10);
                              END
                          ELSE
                              IF IncrementTimeEnable THEN IncrementTime (7);

                    Alt8: IF BackCopyEnable THEN
                              BEGIN
                              SaveBackCopy (TotalContacts + 1, 15);
                              LogBackCopy (15);
                              END
                          ELSE
                              IF IncrementTimeEnable THEN IncrementTime (8);

                    Alt9: IF BackCopyEnable THEN
                              BEGIN
                              SaveBackCopy (TotalContacts + 1, 20);
                              LogBackCopy (20);
                              END
                          ELSE
                              IF IncrementTimeEnable THEN IncrementTime (9);

                    Alt0: IF BackCopyEnable THEN
                              BEGIN
                              SaveBackCopy (TotalContacts + 1, 30);
                              LogBackCopy (30);
                              END
                          ELSE
                              IF IncrementTimeEnable THEN IncrementTime (10);

                    AltEqual:
                        IF (ActiveMode = Phone) AND DVPActive THEN
                            ReviewBackCopyFiles
                        ELSE
                            IF CWTone <> 0 THEN
                                BEGIN
                                OldCWTone := CWTone;
                                CWTone := 0;
                                AddStringToBuffer ('', CWTone);
                                NoSound;
                                END
                            ELSE
                                BEGIN
                                IF OldCWTone = 0 THEN
                                    OldCWTone := 700;
                                CWTone := OldCWTone;
                                AddStringToBuffer ('', CWTone);
                                END;

                    AltA: IF (ActiveWindow = CallWindow) THEN
                              BEGIN
                              IF (WindowString = '') AND (LastSCPCall = '') THEN
                                  SetAlarm
                              ELSE
                                  VisibleLog.SuperCheckPartial (WindowString, False, ActiveRadio);

                              END
                          ELSE
                              IF (CallWindowString = '') AND (LastSCPCall = '')  THEN
                                  SetAlarm
                              ELSE
                                  VisibleLog.SuperCheckPartial (CallWindowString, False, ActiveRadio);

                    AltB: BEGIN
                          RememberFrequency;
                          BandUp;
                          END;

                    AltD: IF K1EANetworkEnable THEN
                              PassStationToCTNetwork
                          ELSE
                              DupeCheckOnInactiveRadio;

                    AltE: BEGIN
                          RITEnable := False;
                          VisibleLog.EditLog;
                          RITEnable := True;
                          UpdateTotals;
                          VisibleLog.ShowRemainingMultipliers;
                          VisibleLog.DisplayGridMap (ActiveBand, ActiveMode);
                          DisplayTotalScore (TotalScore);
                          DisplayInsertMode (InsertMode);
                          DisplayNextQSONumber (TotalContacts + 1);
                          LastTwoLettersCrunchedOn := '';

                          IF VisibleDupeSheetEnable THEN
                              BEGIN
                              VisibleDupesheetChanged := True;
                              VisibleLog.DisplayVisibleDupeSheet (ActiveBand, ActiveMode);
                              END;
                          END;

                    AltF: SaveLogFileToFloppy;
                    AltG: SwapMultDisplay;

                    AltH: BEGIN
                          PutUpHelpMenu;
                          RestorePreviousWindow;
                          VisibleDupeSheetRemoved := True;
                          END;

                    AltI: IF ActiveWindow = ExchangeWindow THEN
                              BEGIN
                              IncrementASCIIInteger (ExchangeWindowString);
                              ClrScr;
                              Write (ExchangeWindowString);
                              END;

                    AltJ: BEGIN
                          MultiplierAlarm := NOT MultiplierAlarm;
                          IF MultiplierAlarm THEN DoABeep (BeepCongrats);
                          END;

                    AltK: ToggleCW (True);

                    AltL: BEGIN
                          RITEnable := False;
                          IF ActiveWindow = CallWindow THEN
                              VisibleLog.SearchLog (WindowString)
                          ELSE
                              VisibleLog.SearchLog (CallWindowString);
                          RITEnable := True;
                          END;

                    AltM: BEGIN
                          RememberFrequency;
                          ToggleModes;
                          DisplayAutoSendCharacterCount;
                          END;

                    AltN:
                        BEGIN
                        Freq := QuickEditFreq ('Enter transmit frequency (kiloHertz) : ', 10);

                        RadioToSet := ActiveRadio;

                        IF Freq < -2 THEN
                            BEGIN
                            Freq := Freq * (-1);
                            RadioToSet := InactiveRadio;
                            END;

                        IF (Freq > 1000) AND (Freq < 1000000) THEN
                            CASE BandMemory[RadioToSet] OF
                                Band80: Freq := Freq +  3000000;
                                Band40: Freq := Freq +  7000000;
                                Band20: Freq := Freq + 14000000;
                                Band15: Freq := Freq + 21000000;
                                Band10: Freq := Freq + 28000000;
                                END;

                        IF Freq > 1000000 THEN
                            BEGIN
                            {SetRadioFreq (ActiveRadio, Freq, ActiveMode, 'B');}

  {                          SetRadioFreq (RadioToSet, Freq, ModeMemory[RadioToSet], 'B'); {KK1L: 6.73}
  {                          PutRadioIntoSplit (RadioToSet); {KK1L: 6.73}
   {                         SplitFreq := Freq;
                            END;
                        BandMapCursorFrequency := Freq; {KK1L: 6.68 Band map tracks transmit freq}
  {                      DisplayBandMap;
                        END;

                    AltO: BEGIN
                          RITEnable := False;
                          AddReminder;
                          RITEnable := True;
                          END;

                    AltP: BEGIN
                          RITEnable := False;
                          MemoryProgram;
                          RITEnable := True;
                          VisibleLog.SetUpEditableLog;
                          END;

                    AltR: BEGIN
                          SwapRadios;
                          InactiveRigCallingCQ := False;
                          Str (SpeedMemory[InactiveRadio], SpeedString); {KK1L: 6.73 Used to use a variable CheckSpeed}
  {                        END;

                    AltS: SetNewCodeSpeed;
                    AltT: TimeAndDateSet;

                    AltU: BEGIN
                          MoveEditableLogIntoLogFile;
                          UpdateTotals;
                          END;

                    AltV: BEGIN
                          RememberFrequency;
                          BandDown;
                          END;

                    AltW: BEGIN
                          WakeUpCount := 0;
                          SaveSetAndClearActiveWindow (QuickCommandWindow);
                          Write ('Wake up count reset to zero.');
                          DelayOrKeyPressed (2000);
                          RemoveAndRestorePreviousWindow;
                          END;

                    AltX: ExitProgram;

                    AltY: BEGIN
                          DeleteLastContact;
                          LastTwoLettersCrunchedOn := '';
                          END;

                    AltZ: BEGIN
                          DoAltZ (WindowString, KeyChar);
                          IF KeyChar = ControlX THEN Exit;
                          END;

                    AltDash:
                        BEGIN
                        IF AutoSendCharacterCount > 0 THEN
                            AutoSendEnable := NOT AutoSendEnable;

                        DisplayAutoSendCharacterCount;
                        END;

                    HomeKey: GoToXY (1, WhereY);

                    EndKey:  GoToXY (Length (WindowString) + 1, WhereY);

                    DeleteKey:
                        BEGIN
                        IF InsertMode THEN
                            BEGIN
                            IF CursorPosition <= Length (WindowString) THEN
                                BEGIN
                                FOR CharPointer := CursorPosition TO Length (WindowString) - 1 DO
                                    WindowString [CharPointer] := WindowString [CharPointer + 1];

                                WindowString [0] := Chr (Length (WindowString) - 1);
                                ClrScr;
                                Write (WindowString);
                                GoToXY (CursorPosition, WhereY);
                                END
                            ELSE
                                IF CursorPosition = Length (WindowString) THEN
                                    BEGIN
                                    ClrEol;
                                    WindowString [0] := Chr (Length (WindowString) - 1);
                                    END;
                            END
                        ELSE
                            BEGIN
                            WindowString [CursorPosition] := ' ';
                            ClrScr;
                            Write (WindowString);
                            GoToXY (CursorPosition, WhereY);
                            END;

                        ShowPartialCallMults (WindowString);
                        END;

                    LeftArrow:
                        IF CursorPosition > 1 THEN
                            GoToXY (CursorPosition - 1, WhereY);

                    RightArrow:
                        IF CursorPosition <= Length (WindowString) THEN
                            GoToXY (CursorPosition + 1, WhereY);

                    PageUpKey: SpeedUp;
                    PageDownKey: SlowDown;

                    ControlPageDown: {KK1L: 6.73 Used CodeSpeedIncrement and change to array for speed}
  {                      BEGIN
                        IF SpeedMemory[InactiveRadio] > CodeSpeedIncrement THEN
                            SpeedMemory[InactiveRadio] := SpeedMemory[InactiveRadio] - CodeSpeedIncrement;
                        Str (SpeedMemory[InactiveRadio], SpeedString); {KK1L: 6.73 Set string to display speed for alt-d}
   {
                        IF (DupeInfoCall <> '') AND (OpMode = CQOpMode) AND (ModeMemory[InactiveRadio] = CW) THEN
                            BEGIN
                            SaveAndSetActiveWindow (DupeInfoWindow);
                            WriteLn (DupeInfoCall + ' OK!! at ' + SpeedString + ' WPM');
                            RestorePreviousWindow;
                            END;
                        END;

                    ControlPageUp: {KK1L: 6.73 Used CodeSpeedIncrement and change to array for speed}
  {                      BEGIN
                        IF SpeedMemory[InactiveRadio] < (99 - CodeSpeedIncrement) THEN
                            SpeedMemory[InactiveRadio] := SpeedMemory[InactiveRadio] + CodeSpeedIncrement;
                        Str (SpeedMemory[InactiveRadio], SpeedString); {KK1L: 6.73 Set string to display speed for alt-d}
                        {KK1L: 6.73}
  {                      IF (DupeInfoCall <> '') AND (OpMode = CQOpMode) AND (ModeMemory[InactiveRadio] = CW) THEN
                            BEGIN
                            SaveAndSetActiveWindow (DupeInfoWindow);
                            WriteLn (DupeInfoCall + ' OK!! at ' + SpeedString + ' WPM');
                            RestorePreviousWindow;
                            END;
                        END;

                    ControlHome:
                        IF ActiveMultiPort <> NoPort THEN
                            DisplayMultiMessageBuffer;

                    ControlInsert: {KK1L: 6.65 Insert BM place holder entry}
  {                      BEGIN
                        AddBandMapPlaceHolder;
                        END;

                    ControlDelete: {KK1L: 6.65 Delete BM entry while logging}
  {                      BEGIN
                        IF BandMapCursorData^.Frequency > 0 THEN
                            BEGIN
                            DisplayBandMap; {sets FoundCursor true if cursor on valid entry}
  {                          IF FoundCursor THEN
                                BEGIN
                                DeleteBandMapEntry (BandMapCursorData);
                                DisplayBandMap;
                                END;
                            END;
                        END;

                    ControlEnd:
                        IF BandMapEnable THEN
                            BEGIN
                            EditBandMap;

                            {KK1L: 6.65 Added NOT EscapeFromEditBandMap to not display call in window on escape}
  {                          IF (BandMapCursorData <> nil) AND (NOT EscapeFromEditBandMap) THEN
                                WITH BandMapCursorData^ DO
                                    BEGIN

                                    BandMapCall := BandMapExpandedString (Call);

                                    IF (OpMode = SearchAndPounceOpMode) THEN
                                        BEGIN
                                        IF ActiveWindow = CallWindow THEN
                                            BEGIN
                                            WindowString := BandMapCall;
                                            ClrScr;
                                            Write (WindowString);
                                            END
                                        ELSE
                                            BEGIN
                                            ClrScr;
                                            WindowString := '';
                                            ExchangeWindowCursorPosition := 1;

                                            CallWindowString := BandMapCall;
                                            RestorePreviousWindow;
                                            ClrScr;
                                            Write (CallWindowString);
                                            ActivateExchangeWindow;
                                            KeyChar := TabKey;
                                            Exit;
                                            END;
                                        END
                                    ELSE
                                        IF (ActiveWindow = CallWindow) THEN
                                            BEGIN
                                            RemoveWindow (ExchangeWindow);
                                            ResetSavedWindowListAndPutUpCallWindow;
                                            ExchangeHasBeenSent := False;

                                            {KK1L: 6.73 For SO2R keeps CQMode when moving in inactive radio bandmap}
  {                                          IF BandMapBand = BandMemory[ActiveRadio] THEN
                                                BEGIN
                                                WindowString := BandMapCall;
                                                Write (WindowString);
                                                KeyChar := TabKey;
                                                END;
                                            Exit;
                                            END
                                        ELSE
                                            QuickDisplay (Beep + 'Please ESCAPE out of this QSO before using bandmap');
                                    END;
                            END;

                    UpArrow:
                        IF ControlKeyPressed THEN
                            MoveGridMap (UpArrow)
                        ELSE
                            IF (ActiveWindow = CallWindow) AND (WindowString = '') THEN
                                BEGIN
                                RITEnable := False;
                                VisibleLog.EditLog;
                                RITEnable := True;
                                UpdateTotals;
                                VisibleLog.ShowRemainingMultipliers;
                                VisibleLog.DisplayGridMap (ActiveBand, ActiveMode);
                                DisplayTotalScore (TotalScore);
                                DisplayInsertMode (InsertMode);
                                DisplayNextQSONumber (TotalContacts + 1);
                                LastTwoLettersCrunchedOn := '';
                                END
                            ELSE
                                Exit;

                    DownArrow: IF ControlKeyPressed THEN
                                   MoveGridMap (DownArrow)
                               ELSE
                                   Exit;

                    ControlLeftArrow,
                    ControlRightArrow:
                        IF GridMapCenter <> '' THEN
                            BEGIN
                            MoveGridMap (ExtendedKeyChar);
                            VisibleLog.DisplayGridMap (ActiveBand, ActiveMode);
                            END;

                    InsertKey:
                        BEGIN
                        InsertMode := NOT InsertMode;
                        DisplayInsertMode (InsertMode);
                        END;

                    ELSE Exit;
                    END;  { of case }
  {              END;

            TabKey: Exit;

            BackSpace:
              IF CursorPosition > 1 THEN
                  BEGIN
                  FOR CharPointer := CursorPosition - 1 TO Length (WindowString) - 1 DO
                      WindowString [CharPointer] := WindowString [CharPointer + 1];
                  WindowString [0] := Chr (Length (WindowString) - 1);

                  ClrScr;
                  Write (WindowString);
                  GoToXY (CursorPosition - 1, WhereY);
                  ShowPartialCallMults (WindowString);
                  END;

           '-': BEGIN
                Freq := QuickEditFreq ('Enter transmit frequency (kiloHertz) : ', 10);

                {KK1L: 6.73 -1 means ESC or null, otherwise if negative then CTRL-Enter used to enter.}
  {              RadioToSet := ActiveRadio;
                IF Freq < -2 THEN
                    BEGIN
                    Freq := Freq * (-1);
                    RadioToSet := InactiveRadio;
                    END;

                IF (Freq > 1000) AND (Freq < 1000000) THEN
                    CASE BandMemory[RadioToSet] OF     {KK1L: 6.73 Was ActiveBand}
  {                      Band80: Freq := Freq +  3000000;
                        Band40: Freq := Freq +  7000000;
                        Band20: Freq := Freq + 14000000;
                        Band15: Freq := Freq + 21000000;
                        Band10: Freq := Freq + 28000000;
                        END;

                IF Freq > 1000000 THEN
                    BEGIN
                    {SetRadioFreq (ActiveRadio, Freq, ActiveMode, 'B'); }
  {                  {PutRadioIntoSplit (ActiveRadio);}{KK1L: 6.71 Moved here from before case for TS850 change}
  {                  SetRadioFreq (RadioToSet, Freq, ModeMemory[RadioToSet], 'B'); {KK1L: 6.73}
  {                  PutRadioIntoSplit (RadioToSet); {KK1L: 6.73}
  {                  SplitFreq := Freq;
                    END;
                END;

            ELSE        { of case }
  {            BEGIN
              IF KeyChar = SpaceBar THEN
                  IF (ActiveWindow = CallWindow) OR (WindowString = '') THEN
                      BEGIN
                      RemoveWindow (PossibleCallWindow);
                      RemoveWindow (NameSentWindow);
                      RemoveWindow (QTCNumberWindow);
                      Exit;
                      END;

              IF KeyChar = PacketSpotKey THEN
                  IF (Packet.PacketSerialPort <> NoPort) OR (ActiveMultiPort <> NoPort) THEN
                      IF NOT PacketSpotDisable THEN
                          BEGIN
                          IF ActiveWindow = CallWindow THEN
                              PacketSpotCall := WindowString
                          ELSE
                              PacketSpotCall := CallWindowString;

                          IF PacketSpotCall = '' THEN PacketSpotCall := VisibleLog.LastCallsign;

                          IF ActiveRadio = RadioOne THEN
                              BEGIN
                              TempFreq := Radio1.FilteredStatus.Freq;
                              END
                          ELSE
                              BEGIN
                              TempFreq := Radio2.FilteredStatus.Freq;
                              END;

                          IF TempFreq = 0 THEN
                              BEGIN
                              TempFreq := QuickEditFreq ('Enter spot frequency for ' + PacketSpotCall + ' : ', 10);
                              IF TempFreq <= 0 THEN Continue;
                              END;

                          CreateAndSendPacketSpot (PacketSpotCall, TempFreq);
                          END;

              IF KeypadCWMemories AND ((KeyChar >= '0') AND (KeyChar <= '9')) THEN
                  BEGIN
                  TestByte := Port [$60];

  {                IF (TestByte >= $47) AND (TestByte <= $52) THEN   { Keypad integer pressed }
  {                    BEGIN
                      SendFunctionKeyMessage (Chr (Ord (KeyChar) - Ord ('0') + Ord (ControlF1)), CQOpMode);
                      Continue;
                      END;
                  END;

              IF (KeyChar = 'I') AND (ActiveWindow = ExchangeWindow) AND
                 (ActiveExchange = RSTQSONumberExchange) AND
                 (StringIsAllNumbers (WindowString)) THEN
                     BEGIN { not null }
  {                   NumberString := GetLastString (WindowString);
                     Val (NumberString, Number, Result);
                     IF Result = 0 THEN
                         BEGIN
                         Inc (Number);
                         Str (Number, NumberString);
                         RemoveLastString (WindowString);
                         GetRidOfPostcedingSpaces (WindowString);
                         IF WindowString <> '' THEN
                             WindowString := WindowString + ' ' + NumberString
                         ELSE
                             WindowString := NumberString;

                         ClrScr;
                         Write (WindowString);
                         Continue;
                         END;
                     END;

              {KK1L: note: This is where "normal" characters are processed in the call window}
  {            IF (KeyChar = ' ') OR (KeyChar = '/') OR
                 ((KeyChar = '\') AND (WindowString = '') AND (ActiveWindow = CallWindow)) OR
                 ((KeyChar >= '0') AND (KeyChar <= '9')) OR
                 ((KeyChar >= 'A') AND (KeyChar <= 'Z')) OR
                 ((ActiveWindow = CallWindow) AND (KeyChar = '?')) OR
                 ((ActiveWindow = CallWindow) AND (KeyChar = '.') AND StringIsAllNumbersOrDecimal (WindowString)) OR
                 ((ActiveWindow = ExchangeWindow) AND (KeyChar IN AccentedChars)) THEN
                 {KK1L: 6.72 Added check for accented characters for the Swedes, etc.}
  {                BEGIN
                  {KK1L: 6.68 Added the OR JustLoadingBandMapWithNoRadio to prevent having to ESC to clear the call}
                  {           window after being asked for the frequency when loading the band map by S&P with no }
                  {           radio interface. Originally added for WRTC 2002 radio B rules.}
  {                IF (ActiveWindow = CallWindow) AND (BandMapEntryInCallWindow OR JustLoadingBandMapWithNoRadio) THEN
                  {KK1L: note: this is where the call window gets cleared when you type a character and the the call}
                  {            had been put there by tuning with the band map enabled.}
  {                    BEGIN
                      WindowString := '';
                      ClrScr;
                      BandMapEntryInCallWindow := False;

  {                    JustLoadingBandMapWithNoRadio := False; {KK1L: 6.68}
  {                    END;

                  IF InitialExchangePutUp AND (ActiveWindow = ExchangeWindow) THEN {KK1L: 6.73 NOTE Single char clears window}
  {                    BEGIN
                      WindowString := KeyChar;
                      ClrScr;
                      Write (WindowString);
                      InitialExchangePutUp := False;
                      END
                  ELSE
                      {KK1L: 6.72 NOTE This is where I can add the auto Alt-Z stuff}
  {                    IF Length (WindowString) < SizeOf (WindowString) - 5 THEN
                          BEGIN
                          { Added overwrite of ? character in 6.22 }

  {                        IF InsertMode AND (CursorPosition <= Length (WindowString)) AND (WindowString [WhereX] <> '?') THEN
                              BEGIN
                              InsertCursorPosition := CursorPosition;

                              IF CursorPosition > 1 THEN
                                  BEGIN
                                  TempString := Copy (WindowString, 1, CursorPosition - 1) +
                                                KeyChar +
                                                Copy (WindowString, CursorPosition, Length (WindowString) - CursorPosition + 1);
                                  END
                              ELSE
                                  TempString := KeyChar + WindowString;

                              WindowString := TempString;

                              ClrScr;
                              Write (WindowString);
                              GoToXY (InsertCursorPosition + 1, WhereY);
                              END
                          ELSE
                              IF CursorPosition <= Length (WindowString) THEN
                                  BEGIN
                                  WindowString [CursorPosition] := KeyChar;
                                  Write (KeyChar);
                                  END
                              ELSE
                                  BEGIN
                                  WindowString := WindowString + KeyChar;
                                  Write (KeyChar);

                                  IF (ActiveMode = CW) AND (OpMode = CQOpMode) AND
                                     AutoSendEnable AND
                                     (AutoSendCharacterCount = Length (WindowString)) AND
                                     (NOT StringIsAllNumbersOrDecimal (WindowString)) AND
  {                                  (NOT (Copy (WindowString, 1, 1) = '\')) THEN 6.44  }
  {                                   (NOT StringHas (WindowString, '/')) THEN
                                         IF NOT CallAlreadySent THEN
                                             BEGIN
                                             KeyChar := StartSendingNowKey;
                                             Exit;
                                             END;
                                  END;

                          ShowPartialCallMults (WindowString);

                          IF (ActiveWindow = CallWindow) AND
                             (Length (WindowString) = 1) AND
                             InactiveRigCallingCQ THEN
                                 BEGIN
                                 SwapRadios;
                                 SetUpToSendOnActiveRadio;
                                 InactiveRigCallingCQ := False;

                                 IF (OpMode = SearchAndPounceOpMode) THEN ControlBMemory := KeyChar;

                                 KeyChar := ControlB;
                                 Exit;
                                 END;
                          END;

                  { To show domestic multiplier status as it is entered in }

  {                IF (ActiveWindow = ExchangeWindow) AND DoingDomesticMults THEN
                      BEGIN
                      TempExchange.QTHString := GetLastString (WindowString);

                      IF DoingDomesticMults AND FoundDomesticQTH (TempExchange) THEN
                          VisibleLog.ShowDomesticMultiplierStatus (TempExchange.DomesticQTH);
                      END;

                  END
              ELSE
                  BEGIN
                  IF (KeyChar = QuickQSLKey1) OR
                     (KeyChar = QuickQSLKey2) OR
                     (KeyChar = TailEndKey) THEN
                         BEGIN
                         BeSilent := False;
                         Exit;
                         END;

                  IF KeyChar = PossibleCallRightKey THEN
                         PossibleCallCursorRight;

                  IF KeyChar = PossibleCallLeftKey THEN
                         PossibleCallCursorLeft;

                  IF KeyChar = PossibleCallAcceptKey THEN
                      BEGIN
                      IF ActiveWindow = CallWindow THEN
                          BEGIN
                          WITH PossibleCallList DO
                              IF NumberPossibleCalls > 0 THEN
                                  BEGIN
                                  WindowString := List [CursorPosition].Call;
                                  ClrScr;
                                  Write (WindowString);
                                  END;
                          END
                      ELSE
                          BEGIN
                          WITH PossibleCallList DO
                              IF NumberPossibleCalls > 0 THEN
                                  BEGIN
                                  RestorePreviousWindow;
                                  ClrScr;
                                  CallWindowString := List [CursorPosition].Call;
                                  Write (CallWindowString);
                                  SaveAndSetActiveWindow (ExchangeWindow);
                                  END;
                          END;
                      END;
                  END;
              END;

            END;  { of case }
  {    UNTIL False;
     }
end;

procedure ProcessExchangeFunctionKey(ExtendedKey: Char);

{ This procedure is used when a function key has been pressed when the
  exchange menu is up (either CQ or pounce).  A function key will send
  the memory that is assigned to that key in the CQ exchange mode. }

begin
  {    SetUpToSendOnActiveRadio;

      SetSpeed (DisplayedCodeSpeed);

      IF ActiveMode <> CW THEN
          BEGIN
          SendFunctionKeyMessage (ExtendedKey, NotCQMode);
          IF (ExtendedKey = F2) THEN ExchangeHasBeenSent := True;
          IF (ExtendedKey = F1) THEN ExchangeHasBeenSent := False;
          Exit;
          END;
  }

  case ExtendedKey of
    F1:
      begin
        if (TwoRadioState = StationCalled) then
          CheckTwoRadioState(F1Pressed)
        else
        begin

            { if KeyRecentlyPressed(F1, 150) then // 1.5 seconds
             begin
               if ActiveMode = CW then
                 FlushCWBufferAndClearPTT
               else
                 if DVPActive then DVPStopPlayback;

               KeyStamp(NullKey);
               Exit;
             end
             else
             }
          begin
            if ActiveMode = CW then
            begin
              if not AllCWMessagesChainable then FlushCWBuffer;

              if (KeyRecentlyPressed(F1, 600)) or (not DEEnable) then
                SendCrypticMessage(MyCall)
              else
              begin
                FlushCWBuffer;
                SendCrypticMessage(DEPlusMyCall);
              end;
              KeyStamp(F1);
            end

            else

              if ActiveMode = Digital then
              begin
                SendCrypticMessage(CallWindowString + ' DE ' + MyCall + ' ' + MyCall {+ ' KK'});
              end
              else
                SendFunctionKeyMessage(F1, SearchAndPounceOpMode);

            InactiveRigCallingCQ := False;
          end;
        end;
        if length(CallWindowString) > 2 then tExchangeWindowSetFocus;
        if ExchangeWindowString = '' then
        begin
          tSetExchWindInitExchangeEntry;
          CheckAndSetInitialExchangeCursorPos;
        end;

        ExchangeHasBeenSent := False;
      end;

    F2:
      begin
        if TwoRadioState = StationCalled then
          CheckTwoRadioState(F2Pressed)
        else
        begin
          if ActiveMode in [CW, Digital] then
          begin
            if ActiveMode = CW then
              if not AllCWMessagesChainable then FlushCWBuffer;

            if ExchangeHasBeenSent and (RepeatSearchAndPounceExchange <> '') then
              SendCrypticMessage(RepeatSearchAndPounceExchange)
            else
            begin
              if (ActiveWindow = CallWindow) and
                (CallWindowString = '') and (ExchangeWindowString = '') then
              begin
                if RepeatSearchAndPounceExchange <> '' then
                  SendCrypticMessage(RepeatSearchAndPounceExchange)
                else
                  SendCrypticMessage(SearchAndPounceExchange);

                KeyStamp(ExtendedKey);
                Exit;
              end
              else
                SendCrypticMessage(SearchAndPounceExchange);
            end;
          end
          else
//            SendFunctionKeyMessage(F2, SearchAndPounceOpMode);
            SendCrypticMessage(SearchAndPouncePhoneExchange);

          ExchangeHasBeenSent := True;
        end;

//        if K5KA.ModeEnabled then K5KA.State := KAMessageStarted;
      end;

  else
    begin
      SendFunctionKeyMessage(ExtendedKey, SearchAndPounceOpMode);

      if ExtendedKey = AltF10 then
      begin
        CallsignICameBackTo := CallWindowString;
        ShowStationInformation(@CallWindowString);
      end;
    end;

  end;

  KeyStamp(ExtendedKey);
end;

procedure LogContact(var RXData: ContestExchange; MyComputer: boolean);

{ This procedure will log the contact just completed.  It will be
  pushed onto the editable log and the log entry popped off the editable
  log will be examined and written to the LOG.DAT file.                 }
label
  1;
var
//  TempString{, LogString }           : Str80;
//  FileWrite                        : Text;
//  OldTotalScore                    : LONGINT;
  Address                               : integer;
  TempPchar                             : PChar;
  TempMode                              : ModeType;
begin
  //  if Trace then Write('!');
  StationInformationCall := '';
  ShowQSOStatusCall := '';

  VisibleDupeSheetChanged := True;

  //if Packet.PacketSerialPort <> NoPort then Packet.DeletePacketEntry(RXData.Callsign, RXData.Band, RXData.Mode);

//  OldTotalScore := TotalScore;

  LastTwoLettersCrunchedOn := '';

  if AutoTimeIncrementQSOs > 0 then
  begin
    inc(AutoTimeQSOCount);
    if AutoTimeQSOCount >= AutoTimeIncrementQSOs then IncrementTime(1);
  end;

//   if LastDeletedLogEntry <> '' then
//      begin
//         LastDeletedLogEntry := '';
//         //    RemoveWindow(QuickCommandWindow);
//      end;
  tLastLogEntryIsDeleted := False;
  WindowDupeCheckCall := RXData.Callsign;

  //  LastQSOLogged := RXData;

  if TenMinuteRule <> NoTenMinuteRule then UpdateTenMinuteDate(rxData.band,rxData.Mode);

  //  if not DDX(VerifyContact) then RXData.QSOPoints := 0;

     //  if not TailEnding then RemoveWindow(PossibleCallWindow);

  //  if Trace then Write('@');
  if MobileCall(RXData.Callsign) and (ActiveDomesticMult = DomesticFile) then    // n4af 4.41.8 Add Q.P. Rover
  RXData.Callsign := PrecedingString(RXData.Callsign,'/')  + '/' + RXData.DomesticQTH;  // n4af 4.41.7
 
  if VisibleLog.CallIsADupe(RXData.Callsign, RXData.Band, RXData.Mode) or
    ((ActiveDomesticMult = GridSquares) and RoverCall(RXData.Callsign) and (NumberGridSquaresInList > 0)) then
    if not (ActiveQSOPointMethod = AlwaysOnePointPerQSO) then
    begin
        //      if Trace then Write('#');
      RXData.ceDupe := True;
        //            RXData.tDupe := True;
      if (ActiveDomesticMult = GridSquares) and RoverCall(RXData.Callsign) then
      begin
        if NumberGridSquaresInList > 0 then
          for Address := 0 to NumberGridSquaresInList - 1 do
            if RXData.DomesticQTH = GridSquareList[Address] then
            begin
              RXData.QSOPoints := 0;
                    //                              if ReminderPostedCount = 0 then
              begin
                Format(QuickDisplayBuffer, TC_YOUALREADYWORKEDIN, @RXData.Callsign[1], @RXData.DomMultQTH[1]);
                QuickDisplay(QuickDisplayBuffer);
                if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);

                      //                                    ReminderPostedCount := 60;
              end;
              Break;
            end;
      end
      else
      begin
            //                  if ReminderPostedCount = 0 then
        begin
          Format(QuickDisplayBuffer, TC_ISADUPEANDWILLBELOGGEDWITHZERO, @RXData.Callsign[1]);
          QuickDisplay(QuickDisplayBuffer);
          if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);
        end;

        RXData.QSOPoints := 0;
      end;
    end;

  VisibleLog.ProcessMultipliers(RXData);

  if MyComputer then
  begin
    RXData.Radio := ActiveRadioPtr^.RadioModel;
    RXData.ceRadio := ActiveRadio;
    tGetQSOSystemTime(RXData.tSysTime);
    RXData.ceQSOID1 := STARTTIMEOFTHETR4W;
    RXData.ceQSOID2 := Windows.GetTickCount;
    RXData.ceOperator := CurrentOperator;

    if RecorderDuration = rdEachQSO then
      if SaveLastQSOToMP3File(@RXData) then
        RXData.MP3Record := True;

    if not SendRecordToServer(NET_QSOINFO_ID, RXData) then inc(tUSQ);
  end;

  // Add code here to send UDP message with contact info
  if UDPBroadcastContact then
     begin
     LogContactToUDP(RXData);
     end;
  if not tAddQSOToLog(RXData) then Exit;

  //if RXData.Band in [Band160..Band10] then
  inc(ContinentQSOCount[RXData.Band, RXData.QTH.Continent]);

  TempMode := RXData.Mode;
  if TempMode = FM then TempMode := Phone;

  if ((RXData.Mode <> NoMode) and (RXData.Band <> NoBand) and (RXData.ceRecordKind = rkQSO)) then
  begin
    inc(QSOTotals[RXData.Band, TempMode]);
    inc(QSOTotals[RXData.Band, Both]);
    inc(QSOTotals[All, TempMode]);
    inc(QSOTotals[All, Both]);

    Sheet.SetMultFlags(RXData);
    Sheet.AddQSOToSheets(@RXData, True);
    CallsignsList.AddCallsign(RXData.Callsign, TempMode, RXData.Band, False);
    CallsignsList.AddIniitialExchange(RXData.Callsign, GetInitialExchangeStringFromContestExchange(RXData));
    SendStationStatus(sstQSOs);
  end;

  if SingleBand <> All then
  begin
    if RXData.Band = SingleBand then TotalQSOPoints := TotalQSOPoints + RXData.QSOPoints;
  end
  else
    TotalQSOPoints := TotalQSOPoints + RXData.QSOPoints;

  //  ProcessPartialCallAndInitialExchange(RXData);
    //  PushLogStringIntoEditableLogAndLogPopedQSO(LogString, True);

    //  if Trace then Write('&');
  if MyComputer then
    if not TailEnding then
    begin
//      ShowStationInformation(@RXData.Callsign);
      UpdateStationStatus(RXData.Callsign, -1);
    end;

  if DoingDomesticMults and                                         // Gav 4.44.8   uncommented section
    (MultByBand or MultByMode) and
    (RXData.DomesticQTH <> '') then
    VisibleLog.ShowDomesticMultiplierStatus(RXData.DomMultQTH);

  {Increment rate data}
  inc(NumberContactsThisMinute);
  NumberQSOPointsThisMinute := NumberQSOPointsThisMinute + RXData.QSOPoints;
  if RXData.Band in [Band160..Band10] then
    if RXData.ceRecordKind = rkQSO then
    begin
      inc(NumberBandQSOsThisMinute[RXData.Band]);
      if HourDisplay = BandChangesThisComputer then if not MyComputer then goto 1;
      if tThisHourPreviousBand <> RXData.Band then
      begin
        if tThisHourPreviousBand <> NoBand then inc(tThisHourBandChanges);

        tThisHourPreviousBand := RXData.Band;
        DisplayHour;
      end;
    end;
  1:
  //    DisplayTotalScore (TotalScore);
  DisplayNamePercentage({TotalNamesSent + VisibleLog.NumberNamesSentInEditableLog, TotalContacts});
  //  CheckAvailableMemory;

  if BeepEvery10QSOs and (TotalContacts mod 10 = 0) then QuickBeep;

  if FloppyFileSaveFrequency > 0 then
    if QSOTotals[All, Both] > 0 then
      if QSOTotals[All, Both] mod FloppyFileSaveFrequency = 0 then
        SaveLogFileToFloppy;

//  if UpdateRestartFileEnable then Sheet.SaveRestartFile;

  BeSilent := False;
  NameCallsignPutUp := '';

  if CheckLogFileSize then
    if not LogFileLooksOkay then
    begin
      DoABeep(Warning);
      showwarning(TC_LOGFILESIZECHECKFAILED);

        //            ReminderPostedCount := 60;
    end;

  if CWSpeedFromDataBase and (RememberCWSpeed <> 0) then
  begin
    SetSpeed(RememberCWSpeed);
    RememberCWSpeed := 0;
    DisplayCodeSpeed;
  end;

  //  if (DDXState <> Off) and Debug and (CWTone = 0) then if Random(100) = 0 then BandUp;

  if BandMapEnable then
  begin
      //UpdateBandMapMultiplierStatus;
    SpotsList.UpdateSpotsMultiplierStatus;
      //        KK1L: 6.64 Need to change dupe status for this contact as well
//      UpdateBandMapDupeStatus(RXData.Callsign, RXData.Band, RXData.Mode, True);
    SpotsList.UpdateSpotsDupeStatus(RXData.Callsign, RXData.Band, TempMode {RXData.Mode});
  end;

end;

procedure loglastcall;
var
  SysTime                               : SYSTEMTIME;
begin
  {
    Windows.GetSystemTime(SysTime);

    with LastQSOLogged do
      begin
        NumberSent := TotalContacts + 1;
        Band := ActiveBand;
        Mode := ActiveMode;
        //    Time := SysTime.wHour * 100 + SysTime.wMinute;
      end;

    LogContact(LastQSOLogged);

    VisibleLog.ShowQSOStatus(LastQSOLogged.Callsign);
    UpdateTotals2;

    if ReceivedData.DomesticMult or
      ReceivedData.DXMult or
      ReceivedData.ZoneMult then
      VisibleLog.ShowRemainingMultipliers;

    if ReceivedData.DomesticMult then
      VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);

    CleanUpDisplay;
  }
end;

function SearchAndPounce: boolean;

label
  ControlEnterCommand1, ControlEnterCommand2;

  { Returns FALSE when we don't want to search and pounce anymore. }

var
  InsertCursorPosition, CharPtr         : integer;
  Key, ExtendedKey                      : Char;
  MultString, WindowString              : Str80;
//  MTotals                               : MultTotalArrayType;
  TempFreq                              : LONGINT;
  TempBand                              : BandType;
  TempMode                              : ModeType;
  Mult                                  : boolean;

begin

  OpMode := SearchAndPounceOpMode;
  BandMapBand := ActiveBand;
  DisplayBandMap;
  //   if ActiveMultiPort <> NoPort then CreateAndSendSAPMultiInfoMessage;
//wli  LogBadQSOString := '';
  CQRITEnabled := False;
  ClearAutoSendDisplay;
  //????????   FRM.ExchangeWindow.Color := clyellow;
     //  FRM.CallWindow . SetFocus;
  tCallWindowSetFocus;
  //{WLI}    PutUpExchangeWindow;
  PutUpExchangeMenu;

  //   if ReminderPostedCount = 0 then      FRM.QUICKCOMMANDWINDOW . Caption := SAP;
     //        QuickDisplay ('You are in the Search And Pounce mode.  Press Shift-Tab to exit.');

  tCleareExchangeWindow;
  //{WLI}    ExchangeWindowString := '';

  if DupeInfoCall <> '' then {KK1L: 6.73 Keeps SO2R message in line with reality}
  begin
      //    SaveAndSetActiveWindow(DupeInfoWindow);
    WriteLn(DupeInfoCall + ' OK!!          ');
    if (TwoRadioState = StationCalled) and (OpMode = CQOpMode) then
      Write('Enter to complete QSO    '); {KK1L: 6.73 The stuff normally following this should remain.}
      //    RestorePreviousWindow;
  end;

  {   Removed in 6.19 - I decided that it would be better to leave the
      cursor in the call window so you can call the guy with a RETURN.

      Whoops - we need this for two radio stuff.  Put back in if
      TwoRadioState = StationCalled. }

  if TwoRadioState = StationCalled then
  begin
      //{WLI}        ActivateExchangeWindow;

    tSetExchWindInitExchangeEntry;

      //{WLI}        ExchangeWindowString := InitialExchangeEntry (CallWindowString);
      //{WLI}//        ClrScr;
      //{WLI}        Write (ExchangeWindowString);

              {TR6.74 - because InitialExchangeEntry no longer does this }

      //{WLI}        IF InitialExchangeOverwrite THEN
      //{WLI}            InitialExchangePutUp := ExchangeWindowString <> '';

      //{WLI}        IF InitialExchangeCursorPos = AtStart THEN
      //{WLI}            GoToXY (1, 1)
      //{WLI}        ELSE
      //{WLI}            GoToXY (1, Length (ExchangeWindowString) + 1);

      //{WLI}        ExchangeWindowCursorPosition := WhereY;
  end;

  //    IF KeyRecentlyPressed (F1, 100) THEN DDX (MaybeRespondToMyCall);

  //{WLI}    SearchAndPounce := False;

  { Presumed exit value unless a QSO is finished
                                  and we aren't using the SprintQSYRule. }

  SearchAndPounce := True;

end;

procedure GetInitialCall;

var
  Key, TempKey, ExtendedKey, DumpKey    : Char;
  CursorPosition, Ptr                   : integer;
  TempString                            : Str80;
  SearchAndPounceStatus, SpecialRadioSwap {, StationCalled}: boolean;
//  MTotals                               : MultTotalArrayType;
  EditingCallsignSent                   : boolean;
  TimeOut                               : Byte;

begin
  OpMode := CQOpMode;

  EditingCallsignSent := False;
  SpecialRadioSwap := False;
  CallAlreadySent := False;

  //  RemoveWindow(ExchangeWindow);
//  ResetSavedWindowListAndPutUpCallWindow;

  EscapeDeletedCallEntry := CallWindowString;
  CallWindowString := '';
  ExchangeWindowString := '';

  CleanUpDisplay;

//  if DDXState = SAndPExchangeSent then    DDX(NormalContactComplete);

  repeat
    //      PutUpCQMenu;

    //      if ReminderPostedCount = 0 then
    QuickDisplay('ENTER a callsign.  SPACE for dupecheck.  Alt-H for help.');

//    DDX(MaybeSendANewCall);
{
    if Debug and (DDXState = CallSentInResponseToACQ) then
    begin
      CallWindowString := DDXCall1;
      Write(CallWindowString);
    end;
}
    if KeyPressedMemory = ' ' then
    begin
      Key := ' ';
      KeyPressedMemory := CHR(0);
    end
    else
      if ActiveWindow = CallWindow then
        asm
nop
        end
//        WindowEditor(CallWindowString, Key, ExtendedKey)
      else
        //wli                WindowEditor(ExchangeWindowString, Key, ExtendedKey);

        if (Key = StartSendingNowKey) and (ActiveWindow = CallWindow) and (length(CallWindowString) >= 1) then
        begin
            //                  if ReminderPostedCount = 0 then
          if AutoCallTerminate then
            QuickDisplay('Continue entering characters.  Auto terminate active!!')
          else
            QuickDisplay('Continue entering characters and press RETURN when done.');

          if length(CallWindowString) > 0 then
          begin
            if MessageEnable then
            begin
              AddStringToBuffer(CallWindowString, CWTone);
//              PTTForceOn;
            end;

            if (SCPMinimumLetters > 0) and (not NewKeyPressed) then {KK1L: 6.73 Added ActiveRadio}
              VisibleLog.SuperCheckPartial(CallWindowString, True, ActiveRadioPtr);

            repeat
              repeat
                if (ActiveMode = CW) and CWEnabled {and (not ReadInLog)} and
                  AutoCallTerminate and not CWStillBeingSent then
                begin
                  CallAlreadySent := True;
                  CallsignICameBackTo := CallWindowString;
                  Exit;
                end;

              until NewKeyPressed {or ReadInLog};

              if 1 > 1 {ReadInLog} then
              begin
                if (length(ReadInCallsign) = length(CallWindowString)) and
                  (length(ReadInCallsign) > 0) then
                  TempKey := CarriageReturn
                else
                begin
                  TempKey := ReadInCallsign[length(CallWindowString) + 1];
                  Sleep(Random(400));
                end;
              end

              else TempKey := UpCase(NewReadKey);

              case TempKey of
                BackSpace:

                  if EditingCallsignSent then
                  begin
                    if length(CallWindowString) > 0 then
                    begin
                      Delete(CallWindowString, length(CallWindowString), 1);
                    end
                  end

                  else

                    if (CWEnabled and DeleteLastCharacter) or not CWEnabled then
                    begin
                      Delete(CallWindowString, length(CallWindowString), 1);
                    end
                    else
                    begin
                      AddStringToBuffer('!', CWTone);
                      Delete(CallWindowString, length(CallWindowString), 1);
                      EditingCallsignSent := True;
                    end;

                NullKey:
                  begin
                    CallAlreadySent := True;
                    CallsignICameBackTo := CallWindowString;

                        {case NewReadKey of
                          AltB:
                            begin

                              BandUp;
                            end;

                          AltD:
                            if K1EANetworkEnable then
                              PassStationToCTNetwork
                            else
                              DupeCheckOnInactiveRadio;

                          AltG: SwapMultDisplay;
                          AltK: ToggleCW(true);
                          AltM:
                            begin
                              ToggleModes;
                              DisplayAutoSendCharacterCount;
                            end;

                          AltR:
                            begin
                              if not SingleRadioMode then
                              begin
                                                       //wli                                          SwapRadios;
                                DisplayAutoSendCharacterCount;
                                Str(SpeedMemory[InactiveRadio], SpeedString);
                              end;
                            end;

                          AltV:
                            begin

                              BandDown;
                            end;

                          AltY: DeleteLastContact;
                          PageUpKey: SpeedUp;
                          PageDownKey: SlowDown;
                        end;
                        }
                  end;

                CarriageReturn:
                  begin
                    CallAlreadySent := True;
                    CallsignICameBackTo := CallWindowString;
                    Exit;
                  end;

                EscapeKey:
                  begin

                    if ((ActiveMode = CW) and CWStillBeingSent) or
                      ((ActiveMode = Phone) and (DVPMessagePlaying or DVKMessagePlaying)) then
                    begin
                      if ActiveMode = CW then
                        FlushCWBufferAndClearPTT
                      else
                        if DVPActive then
                        begin
                          DVPStopPlayback;

                          TimeOut := 0;

                          repeat
                            Sleep(5);
                            inc(TimeOut);
                          until (not DVPMessagePlaying) or (TimeOut > 60);
                        end;
                    end
                    else
                    begin
                      FlushCWBufferAndClearPTT;
                      EscapeDeletedCallEntry := CallWindowString;
                      CallWindowString := '';
                            //wli                                ClrScr;
              //                      RemoveWindow(ExchangeWindow);
//                                          if not VisibleDupesheetEnable then
                      begin
                              //                        RemoveWindow(QSOInformationWindow);
                              //                        RemoveWindow(MultiplierInformationWindow);
                      end;
                      NameCallsignPutUp := '';
                            //                      RemoveWindow(QuickCommandWindow);
                      CleanUpDisplay;
                    end;
                  end;

              else
                if (ValidCallCharacter(TempKey)) or (TempKey = '?') then
                begin
                  EditingCallsignSent := False;
                  CallWindowString := CallWindowString + TempKey;
                  AddStringToBuffer(TempKey, CWTone);
                  Write(TempKey);

                  if PartialCallEnable then
                    if Sheet.TwoLetterCrunchProcess(CallWindowString) then
                    begin
                                {
                                  VisibleLog.GeneratePartialCallList(CallWindowString,
                                    ActiveBand,
                                    ActiveMode,
                                    PossibleCallList);
                                  DisplayPossibleCalls(PossibleCallList);
                                  }
                    end;

                  if (SCPMinimumLetters > 0) and (not NewKeyPressed) then {KK1L: 6.73 Added ActiveRadio}
                    VisibleLog.SuperCheckPartial(CallWindowString, True, ActiveRadioPtr);
                end;

              end; { of case }

            until TempKey = EscapeKey;
          end;
        end
        else
          case Key of

            EscapeKey:
              begin
                if ((ActiveMode = CW) and CWStillBeingSent) or
                  ((ActiveMode = Phone) and (DVPMessagePlaying or DVKMessagePlaying)) then
                begin
                  if ActiveMode = CW then
                    FlushCWBufferAndClearPTT
                  else
                    if DVPActive then
                    begin
                      DVPStopPlayback;

                      TimeOut := 0;

                      repeat
                        Sleep(5);
                        inc(TimeOut);
                      until (not DVPMessagePlaying) or (TimeOut > 60);
                    end;
                end
                else
                  if ActiveWindow = ExchangeWindow then
                  begin
                    if ExchangeWindowString <> '' then
                    begin
                      ExchangeWindowString := '';
                          //wli                               ClrScr;
                    end
                    else
                        //                      RemoveAndRestorePreviousWindow;
                  end
                  else
                  begin
                    EscapeDeletedCallEntry := CallWindowString;
                    CallWindowString := '';
                      //wli                           ClrScr;

                    ExchangeWindowString := '';
                      //                    RemoveWindow(ExchangeWindow);
                      //                    RemoveWindow(QSOInformationWindow);
                      //                    RemoveWindow(MultiplierInformationWindow);
                      //                    RemoveWindow(QuickCommandWindow);
                      //                    RemoveWindow(DupeInfoWindow);
                    NameCallsignPutUp := '';
                    tClearDupeInfoCall;

                      { This is new for 5.88 }

                    if TwoRadioState = CallReady then
                      TwoRadioState := Idle;

                    CleanUpDisplay;
                      //                    DisplayEditableLog(VisibleLog.LogEntries);
                  end;
              end;

            SpaceBar:
              if (DupeInfoCall <> '') and (CallWindowString = '') then
              begin
                FlushCWBufferAndClearPTT;

                if (TwoRadioState = CallReady) then
                    //wli                        CheckTwoRadioState (SpaceBarPressed) {KK1L: 6.73 Should modify to handle Alt-D from SAP mode}
                else
                begin
                      //wli                        SwapRadios;  { Changes band/mode and display }
                  SpecialRadioSwap := True;
                end;

                if TwoRadioState <> CallReady then
                begin
                  CallWindowString := DupeInfoCall; {KK1L: 6.73 NOTE Why are these three lines here?. I know}
                      //                  ResetSavedWindowListAndPutUpCallWindow; {                it puts a call in the window. Does it  }
                  Write(CallWindowString); {                cover the on deck call case???         }

                  ShowStationInformation(@CallWindowString);
                  DisplayGridSquareStatus(CallWindowString);
                  VisibleLog.DoPossibleCalls(CallWindowString);

                  if (length(CallWindowString) >= 3) and (ExchangeWindowString = '') then
                  begin
                          //                    ActivateExchangeWindow;
                    ExchangeWindowString := InitialExchangeEntry(CallWindowString);
                          //wli                            ClrScr;
                          //wli                            Write (ExchangeWindowString);

                                                      {TR6.74 - need to do this since IntialExchangeEntry does not }

                    if InitialExchangeOverwrite then
                      InitialExchangePutUp := ExchangeWindowString <> '';

                          //wli                            IF InitialExchangeCursorPos = AtStart THEN GoToXY (1, 1);
                          //wli                            ExchangeWindowCursorPosition := WhereY;
             //                    RestorePreviousWindow;
                  end;

                  repeat
                        //                                    PutUpExchangeWindow;
                    DisplayNextQSONumber;
                    ClearContestExchange(ReceivedData);
                    ExchangeHasBeenSent := False;
                    SearchAndPounceStatus := SearchAndPounce;
                  until (not SearchAndPounceStatus) or (TwoRadioState = SendingExchange);

                  ClearContestExchange(ReceivedData); { To try and fix a problem
                      with Two Radio mode and DX
                      mults showing up in next QSO }
                  if ActiveRadio = RadioOne then
                  begin
                    CQRITEnabled := Radio1.RadioModel = TS850;
                  end
                  else
                    CQRITEnabled := Radio2.RadioModel = TS850;

                  if (TwoRadioState = SendingExchange) then
                        //wli                            CheckTwoRadioState (ContactDone)
                  else
                    if SpecialRadioSwap then
                    begin
                            //wli                                SwapRadios;
                      SpecialRadioSwap := False;
                    end;

                  DisplayAutoSendCharacterCount;

                  if SearchAndPounceStatus then
                  begin
                    DupeInfoCall := '';
                          //                    RemoveWindow(DupeInfoWindow);

                    EscapeDeletedCallEntry := CallWindowString;
                    CallWindowString := '';
                          //                    RemoveWindow(ExchangeWindow);
//                    ResetSavedWindowListAndPutUpCallWindow;
                  end;
                end;
              end

                  { Still a SpaceBar, but not doing DupeInfoCall }

              else
                if (CallWindowString = '') or not SpaceBarDupeCheckEnable then
                begin
                  if CWStillBeingSent then FlushCWBufferAndClearPTT; { Clear CW sent on Inactive Radio}

                  SetUpToSendOnActiveRadio;

                  InactiveRigCallingCQ := False;

                  if MessageEnable then
                  begin
                    if ActiveMode = CW then
                    begin
                      if DEEnable then
                        SendStringAndStop(DEPlusMyCall)
                      else
                        SendStringAndStop(MyCall);
                    end
                    else
                      if ActiveMode = Digital then
                        SendStringAndStop(CallWindowString + ' DE ' + MyCall + ' KK')
                      else
                            //wli            SendFunctionKeyMessage (F1, SearchAndPounceOpMode);
                  end;

                  KeyStamp(F1);

                  repeat
                      //                                 PutUpExchangeWindow;
                    DisplayNextQSONumber;
                    ClearContestExchange(ReceivedData);
                    ExchangeHasBeenSent := False;
                  until not SearchAndPounce;

                  ClearContestExchange(ReceivedData);

                  if ActiveRadio = RadioOne then
                  begin
                    CQRITEnabled := Radio1.RadioModel = TS850;
                  end
                  else
                    CQRITEnabled := Radio2.RadioModel = TS850;

                    //                  RemoveWindow(ExchangeWindow);

                  DisplayAutoSendCharacterCount;

                  EscapeDeletedCallEntry := CallWindowString;

                    //                  if CallWindowString = '' then                    ResetSavedWindowListAndPutUpCallWindow;
                end
                else
                begin
                    //                  if WindowDupeCheck then RemoveWindow(ExchangeWindow);
                    //                  RestorePreviousWindow;
                end;

            TabKey, ControlU:
              begin
                repeat
                  //                           PutUpExchangeWindow;
                  DisplayNextQSONumber;
                  ClearContestExchange(ReceivedData);
                  ExchangeHasBeenSent := False;
                until not SearchAndPounce;

                ClearContestExchange(ReceivedData);

                if ActiveRadio = RadioOne then
                begin
                  CQRITEnabled := Radio1.RadioModel = TS850;
                end
                else
                  CQRITEnabled := Radio2.RadioModel = TS850;

                DisplayAutoSendCharacterCount;
                {
                if CallWindowString = '' then
                begin
                  RemoveWindow(ExchangeWindow);
                  ResetSavedWindowListAndPutUpCallWindow;
                end;
                }
              end;

            { NullKey:
               begin
                 if (((ExtendedKey >= F1) and (ExtendedKey <= F10)) or
                   ((ExtendedKey >= F11) and (ExtendedKey <= F12)) or
                   ((ExtendedKey >= ControlF1) and (ExtendedKey <= ControlF10)) or
                   ((ExtendedKey >= ControlF11) and (ExtendedKey <= ControlF12)) or
                   ((ExtendedKey >= AltF1) and (ExtendedKey <= AltF10)) or
                   ((ExtendedKey >= AltF11) and (ExtendedKey <= AltF12)) or
                   ((ExtendedKey >= ShiftF1) and (ExtendedKey <= ShiftF10)) or
                   ((ExtendedKey >= ShiftF11) and (ExtendedKey <= ShiftF12))) then
                 begin
                   KeyStamp(ExtendedKey);
                               //wli                        SendFunctionKeyMessage (ExtendedKey, CQOpMode);

                   if (ExtendedKey = F1) or (ExtendedKey = F2) then
                     if FrequencyDisplayed then
                     begin
                       LastCQFrequency := LastDisplayedFreq[ActiveRadio];
                       LastCQMode := ActiveMode;
                     end
                     else
                       LastCQFrequency := 0;

                   if CWMessageCommand = CWCommandSAPMode then
                   begin
                     CWMessageCommand := NoCWCommand;

                     if DupeInfoCall <> '' then
                     begin
                                           //                      SaveAndSetActiveWindow(DupeInfoWindow);
                       WriteLn(DupeInfoCall + ' OK!!          ');
                       Write('CQ mode for   ');
                                           //                      RestorePreviousWindow;
                     end;

                     repeat
                       PutUpExchangeWindow;
                       DisplayNextQSONumber(TotalContacts + 1);
                       ClearContestExchange(ReceivedData);
                       ExchangeHasBeenSent := False;
                     until not SearchAndPounce;

                     ClearContestExchange(ReceivedData);

                     if ActiveRadio = radioone then
                     begin
                       CQRITEnabled := Radio1.RadioModel = TS850;
                     end
                     else
                       CQRITEnabled := Radio2.RadioModel = TS850;

                     DisplayAutoSendCharacterCount;

                     if CallWindowString = '' then
                     begin
                                           //                      RemoveWindow(ExchangeWindow);
                       ResetSavedWindowListAndPutUpCallWindow;
                     end;
                   end;

                   if (CWMessageCommand = CWCommandControlEnter) then
                   begin
                     BeSilent := true;
                     CWMessageCommand := NoCWCommand;

                     if length(CallWindowString) > 1 then
                     begin
                       CallsignICameBackTo := CallWindowString;
                       Exit;
                     end;
                   end;

                   if ((ExtendedKey = F1) or (ExtendedKey = F2)) then
                     if DDXState <> Off then
                     begin
                       DDXState := WaitingForCQ;
                       DDX(MaybeSendANewCall);
                     end;

                   if ExtendedKey = F9 then DDX(RepeatCallsign);
                 end
                 else
                   case ExtendedKey of

                     DownArrow:
                       if ActiveWindow <> ExchangeWindow then
                         if ExchangeWindowString = '' then
                         begin

                             //                          SaveSetAndClearActiveWindow(ExchangeWindow);
                         end
                         else
                         begin

                           ActivateExchangeWindow;
                         end
                       else
                         asm
                       nop
                         end;

                     AltC:
                       if (ActiveMode = cw) or (ActiveDVKPort <> NoPort) or DVPEnable then
                       begin
                         AutoCQResume(False);

                         if ValidCallCharacter(UpCase(KeyPressedMemory)) then
                         begin
                           CallWindowString := UpCase(KeyPressedMemory);
                           Write(CallWindowString);
                         end;
                       end;

                     AltQ:
                       if (ActiveMode = cw) or (ActiveDVKPort <> NoPort) or (DVPEnable) then
                       begin
                         EscapeDeletedCallEntry := CallWindowString;
                         CallWindowString := '';
                                        //                        RemoveWindow(PossibleCallWindow);
                                        //                        ClearWindow(CallWindow);
                         ;

                         if ValidCallCharacter(UpCase(KeyPressedMemory)) then
                         begin
                           CallWindowString := UpCase(KeyPressedMemory);
                           Write(CallWindowString);
                         end;
                       end;

                   end;

               end;
        }        
            CarriageReturn:
              if length(CallWindowString) > 1 then
              begin
                CallsignICameBackTo := CallWindowString;
                Exit;
              end
              else
                if length(CallWindowString) = 0 then
                  //wli                           if (ActiveMode = CW) or DVPEnable or (ActiveDVKPort <> NoPort) then
                begin
                  InactiveRigCallingCQ := False;
                  SetUpToSendOnActiveRadio;

                  if MessageEnable and not ((CWTone = 0) and Debug) then
                      //wli                                SendFunctionKeyMessage (F1, CQOpMode);

                                                  { This is where the initial CQ gets sent if you
                                                    are in debug mode! }
{
                    if DDXState <> Off then
                    begin
                      DDXState := WaitingForCQ;
                      DDX(MaybeSendANewCall);
                    end
}
                end;
          end; { of case }
  until False;
end;

function GotExchange: boolean;

{ This function takes care of putting up the exchange menu and operator
  I/O until an exchange is entered or an escape to quit.  A true response
  means that a good exchange has been found.  If the big + key is used to
  enter the exchange instead of a return, the flag QuickQSL is set true. }

label
  ControlEnterCommand1, ControlEnterCommand2;

var
  InsertCursorPosition, CharPtr         : integer;
  Key, ExtendedKey                      : Char;
  WindowString                          : Str80;

begin
  //    OpMode := CQOpMode;

  GotExchange := False;
  QuickQSL := NoQuickQSLKey;
  //    TailEnding  := False;

  LookingForCQExchange := True;

  //   if ReminderPostedCount = 0 then
  QuickDisplay('Enter exchange.  Press ENTER to log, ESCAPE to abort QSO.');

  if ActiveMode = CW then PutUpExchangeMenu;

  //  if K1EANetworkEnable then DisplayMultiMessages;

     //    SaveSetAndClearActiveWindow (ExchangeWindow);

  if ExchangeWindowString = '' then
  begin
{
    if ReadInLog then
      ExchangeWindowString := ReadInLogExchange
    else
    begin
      tSetExchWindInitExchangeEntry;
    end;
}
  end;

  {KK1L: 6.73 I want to add a space in front of the InitialExchange for K9PG. I do this in InitialExchangeEntry.}
  {GetRidOfPrecedingSpaces (ExchangeWindowString);}

//  DDX(SendExchange);

  if DualingCQState = WaitingForCallsignInput then
    DualingCQState := DualSendingExchange;

  //{WLI}    IF LogWithSingleEnter THEN
  begin
    if ParametersOkay(CallWindowString,
      ExchangeWindowString,
      ActiveBand,
      ActiveMode,
      ActiveRadioPtr.LastDisplayedFreq {LastDisplayedFreq[ActiveRadio]},
      ReceivedData) then
    begin
      GotExchange := True;
        //            RemoveWindow (ExchangeWindow);
      LookingForCQExchange := False;
      Exit;
    end;
  end;

  { We are now ready to accept input.  The CQ EXCHANGE is being sent,
    all of the windows are setup and we are ready to go }

  if (ActiveMode = CW) and AlwaysCallBlindCQ then
    SendExchangeKeyWhenCWHasStopped := F7;

  {    REPEAT
          IF ActiveWindow = CallWindow THEN
              BEGIN
              WindowString := CallWindowString;

              IF Length (WindowString) > 0 THEN
                  FOR CharPtr := 1 TO Length (WindowString) DO
                      IF WindowString [CharPtr] = '?' THEN
                          IF InsertMode THEN                   Version 6.22
                              GoToXY (CharPtr + 1, WhereY)
                          ELSE}
  {                           GoToXY (CharPtr, WhereY);

              WindowEditor (WindowString, Key, ExtendedKey);

              CallWindowString := WindowString;

              CASE Key OF

                  EscapeKey:
                      BEGIN
                      RemoveWindow (ExchangeWindow);
                      GotExchange := False;
                      LookingForCQExchange := False;
                      Exit;
                      END;

                  SpaceBar: IF SpaceBarDupeCheckEnable THEN
                                IF WindowDupeCheck THEN
                                    BEGIN
                                    RemoveWindow (ExchangeWindow);
                                    GotExchange := False;
                                    LookingForCQExchange := False;
                                    Exit;
                                    END;

                  NullKey:
                      CASE ExtendedKey OF
                          UpArrow, DownArrow:
                              BEGIN      {KK1L testing}
  {                            ActivateExchangeWindow;
                              {QuickDisplay2('ActivateExchangeWindow2');}
  {                            END;

                          ELSE
                              BEGIN
                              ProcessExchangeFunctionKey (ExtendedKey);

                              IF CWMessageCommand = CWCommandControlEnter THEN
                                  BEGIN
                                  BeSilent := True;
                                  CWMessageCommand := NoCWCommand;
                                  GoTo ControlEnterCommand1;
                                  END;
                              END;
                          END;

                  CarriageReturn:
                      BEGIN

  ControlEnterCommand1:

                      IF ParametersOkay (CallWindowString,
                                         ExchangeWindowString,
                                         ActiveBand,
                                         ActiveMode,
                                         LastDisplayedFreq [ActiveRadio],
                                         ReceivedData) THEN
                          BEGIN
                          GotExchange := True;
                          RemoveWindow (ExchangeWindow);
                          LookingForCQExchange := False;
                          Exit;
                          END
                      ELSE
                          BEGIN
                          IF ParameterOkayMode = QSLButDoNotLog THEN
                              BEGIN
  //wli                            SendCorrectCallIfNeeded;
  //wli                            Send73Message;
                              QuickDisplay ('PLEASE FIX EXCHANGE for ' + CallsignICameBackTo + '!!');
                              END;

                          ActivateExchangeWindow;
                          END;
                     END

                  ELSE
                      BEGIN
                      IF (Key = QuickQSLKey1) OR
                         (Key = QuickQSLKey2) THEN
                          BEGIN
                          IF ParametersOkay (CallWindowString,
                                             ExchangeWindowString,
                                             ActiveBand,
                                             ActiveMode,
                                             LastDisplayedFreq [ActiveRadio],
                                             ReceivedData) THEN
                                 BEGIN
                                 GotExchange := True;
                                 RemoveWindow (ExchangeWindow);
                                 IF Key = QuickQSLKey1 THEN
                                     QuickQSL := QuickKey1
                                 ELSE
                                     QuickQSL := QuickKey2;

                                 LookingForCQExchange := False;
                                 Exit;
                                 END
                             ELSE
                                 BEGIN
                                 IF ParameterOkayMode = QSLButDoNotLog THEN
                                     BEGIN
  //wli                                   SendCorrectCallIfNeeded;
  //wli                                   Send73Message;
                                     QuickDisplay ('PLEASE FIX EXCHANGE!!');
                                     END;
                                 ActivateExchangeWindow;
                                 END;
                          END
                      ELSE
                          IF Key = TailEndKey THEN
                              BEGIN
                              IF ParametersOkay (CallWindowString,
                                                 ExchangeWindowString,
                                                 ActiveBand,
                                                 ActiveMode,
                                                 LastDisplayedFreq [ActiveRadio],
                                                 ReceivedData) THEN
                                  BEGIN
                                  GotExchange := True;
                                  RemoveWindow (ExchangeWindow);
                                  TailEnding := True;
                                  LookingForCQExchange := False;
                                  Exit;
                                  END
                              ELSE
                                  BEGIN
                                  IF ParameterOkayMode = QSLButDoNotLog THEN
                                      BEGIN
  //wli                                    SendCorrectCallIfNeeded;
  //wli                                    Send73Message;
                                      QuickDisplay ('PLEASE FIX EXCHANGE for ' + CallsignICameBackTo + '!!');
                                      END;
                                  ActivateExchangeWindow;
                                  END;
                              END
                          ELSE
                              ActivateExchangeWindow;
                      END;
                  END; { of case}
  {            END;  { of call window active }

  {        IF ActiveWindow = ExchangeWindow THEN
              BEGIN
  //wli            WindowEditor (ExchangeWindowString, Key, ExtendedKey);

              CASE Key OF

                  EscapeKey: BEGIN
                             RemoveWindow (ExchangeWindow);
                             GotExchange := False;
                             LookingForCQExchange := False;
                             Exit;
                             END;

                  SpaceBar: IF SpaceBarDupeCheckEnable THEN
                                IF WindowDupeCheck THEN
                                    BEGIN
                                    RemoveWindow (ExchangeWindow);
                                    GotExchange := False;
                                    LookingForCQExchange := False;
                                    Exit;
                                    END;

                  NullKey:
                      CASE ExtendedKey OF
                          UpArrow, DownArrow:
                              BEGIN      {KK1L testing}
  {                            RestorePreviousWindow;
                              {QuickDisplay2('RestorePreviousWindow2');}
  {                            END;

                          ELSE
                              BEGIN
                              ProcessExchangeFunctionKey (ExtendedKey);

                              IF CWMessageCommand = CWCommandControlEnter THEN
                                  BEGIN
                                  BeSilent := True;
                                  CWMessageCommand := NoCWCommand;
                                  GoTo ControlEnterCommand2;
                                  END;
                              END;

                          END;

                  CarriageReturn:
                      BEGIN

  ControlEnterCommand2:

                      IF ParametersOkay (CallWindowString,
                                         ExchangeWindowString,
                                         ActiveBand,
                                         ActiveMode,
                                         LastDisplayedFreq [ActiveRadio],
                                         ReceivedData) THEN
                          BEGIN
                          GotExchange := True;
                          RemoveWindow (ExchangeWindow);
                          LookingForCQExchange := False;
                          Exit;
                          END
                      ELSE
                          IF ParameterOkayMode = QSLButDoNotLog THEN
                              BEGIN
  //wli                            SendCorrectCallIfNeeded;
  //wli                            Send73Message;
                              QuickDisplay ('PLEASE FIX EXCHANGE for ' + CallsignICameBackTo + '!!');
                              END;
                      END;

                  ELSE
                      BEGIN
                      IF Key = TailEndKey THEN
                          BEGIN
                          IF ParametersOkay (CallWindowString,
                                             ExchangeWindowString,
                                             ActiveBand,
                                             ActiveMode,
                                             LastDisplayedFreq [ActiveRadio],
                                             ReceivedData) THEN
                              BEGIN
                              GotExchange := True;
                              RemoveWindow (ExchangeWindow);
                              TailEnding := True;
                              LookingForCQExchange := False;
                              Exit;
                              END
                          ELSE
                              IF ParameterOkayMode = QSLButDoNotLog THEN
                                  BEGIN
  //wli                                SendCorrectCallIfNeeded;
  //wli                                Send73Message;
                                  QuickDisplay ('PLEASE FIX EXCHANGE for ' + CallsignICameBackTo + '!!');
                                  END;

                          END
                      ELSE
                          IF (Key = QuickQSLKey1) OR
                             (Key = QuickQSLKey2) THEN
                              BEGIN
                              IF ParametersOkay (CallWindowString,
                                                 ExchangeWindowString,
                                                 ActiveBand,
                                                 ActiveMode,
                                                 LastDisplayedFreq [ActiveRadio],
                                                 ReceivedData) THEN
                                  BEGIN
                                  GotExchange := True;
                                  RemoveWindow (ExchangeWindow);
                                  IF Key = QuickQSLKey1 THEN
                                      QuickQSL := QuickKey1
                                  ELSE
                                      QuickQSL := QuickKey2;
                                  LookingForCQExchange := False;
                                  Exit;
                                  END
                              ELSE
                                  IF ParameterOkayMode = QSLButDoNotLog THEN
                                      BEGIN
  //wli                                    SendCorrectCallIfNeeded;
  //wli                                    Send73Message;
                                      QuickDisplay ('PLEASE FIX EXCHANGE for ' + CallsignICameBackTo + '!!');
                                      END;

                              END
                          ELSE
                              RestorePreviousWindow;
                      END;
                  END; { of case}
  {            END;  { of exchange window active }
  {
      UNTIL FALSE;
     }
end;

procedure OperateContest;

var
//MTotals                               : MultTotalArrayType;
  TempKey                               : Char;
  RememberInactiveCQ                    : boolean;
  RememberTime                          : Cardinal {TimeRecord};
  DXSpot                                : DXSpotType;

begin
//  ReadInConfigFile('');

  if SayHiEnable then
    DisplayNamePercentage({TotalNamesSent + VisibleLog.NumberNamesSentInEditableLog, TotalContacts});
  SetStereoPin(StereoControlPin, StereoPinState); {KK1L: 6.71}
  DisplayRadio(ActiveRadio);
  DisplayTotalScore {(TotalScore)};
  ClearContestExchange(ReceivedData);

  SetUpToSendOnActiveRadio;

  repeat
    SeventyThreeMessageSent := False;
    ExchangeHasBeenSent := False;
//wli    LogBadQSOString := '';

    if TailEnding then
    begin
      PreviousQSOReceivedData := ReceivedData;
      CallsignICameBackTo := TailEndCallString;
      CallWindowString := TailEndCallString;
        //wli            ClrScr;
      Write(CallWindowString);
      ClearContestExchange(ReceivedData);
      ExchangeWindowString := '';
    end
    else
    begin
//      Sheet.MultSheetTotals(MTotals);
      UpdateTotals2;

      if ReceivedData.DomesticMult or ReceivedData.DXMult or ReceivedData.ZoneMult then
        VisibleLog.ShowRemainingMultipliers;

      if ReceivedData.DomesticMult then VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);

      ClearContestExchange(ReceivedData);

      GetInitialCall;

      WindowDupeCheckCall := CallsignICameBackTo;
    end;

    if (ActiveMode = CW) and (not TailEnding) and (not CallAlreadySent) then
    begin
      if MessageEnable and not BeSilent then
        if not (Debug and (CWTone = 0)) then
          AddStringToBuffer(CallsignICameBackTo, CWTone);

      CallAlreadySent := True;
    end;

//    if (ActiveMode = Digital) and (not CallAlreadySent) then
//      StartRTTYTransmission(CallsignICameBackTo + ' ');

    if DualingCQState = DualSendingCQ then
    begin
        //wli            SwapRadios;
      DualingCQState := DualSendingExchange;
    end;

    {??????? ??????  ??????????? ? returnCQopMode}

    if AutoDupeEnableCQ and
      VisibleLog.CallIsADupe(CallsignICameBackTo, ActiveBand, ActiveMode) then
    begin
        //            if ReminderPostedCount = 0 then
//      QuickDisplay(CallsignICameBackTo + ' is a dupe!!');

      if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);

      ShowName(CallsignICameBackTo);
      DisplayCountryName(CallsignICameBackTo);
      DisplayUserInfo(CallsignICameBackTo);

      if ActiveMode = CW then
      begin
        if QTCsEnabled then
        begin
          DisplayQTCNumber(NumberQTCsThisStation(StandardCallFormat(CallWindowString, False)));

          if NumberQTCsThisStation(StandardCallFormat(CallWindowString, False)) < 10 then
          begin
            if QTCsEnabled and (MyContinent = Europe) then
            begin
              AddStringToBuffer(' B4 ', CWTone);
                        //wli                            WAEQTC (CallWindowString);
            end
            else
              if MessageEnable and not BeSilent then
                        //wli                                SendCrypticMessage (QSOBeforeMessage);
          end
          else
            if MessageEnable and not BeSilent then
                    //wli                            SendCrypticMessage (QSOBeforeMessage);
        end
        else
          if MessageEnable and not BeSilent then
                //wli                        SendCrypticMessage (QSOBeforeMessage);

            if DualingCQState <> NoDualingCQs then
              DualingCQState := SendingDupeMessage;
      end;

      if ActiveMode = Digital then
        FinishRTTYTransmission(QSOBeforeMessage);

      if ActiveMode = Phone then
      begin
            //wli                SendCrypticMessage (QSOBeforePhoneMessage);

        Write(' DUPE!!');
        EscapeDeletedCallEntry := CallWindowString;
        CallWindowString := '';

        if QTCsEnabled then
          DisplayQTCNumber(NumberQTCsThisStation(StandardCallFormat(CallWindowString, False)))
        else
        begin
          MarkTime(RememberTime);

          repeat
                  //                           if ActiveMultiPort <> NoPort then CheckMultiState;
            UpdateTimeAndRateDisplays(True, True);
            Packet.CheckPacket;
          until ElaspedSec100(RememberTime) >= 30;

                //wli                    ClrScr;
        end;
      end;

      if AutoDisplayDupeQSO then
      begin
        ShowPreviousDupeQSOs(CallsignICameBackTo, ActiveBand, ActiveMode);
//        EditableLogDisplayed := True;
      end;

      if TailEnding then
      begin
            //        ReceivedData.ceSearchAndPounce := False;
        LogContact(PreviousQSOReceivedData, True);
        TailEnding := False;
      end;

      if Contest <> GENERALQSO then
      begin
        VisibleLog.ShowMultiplierStatus(@CallsignICameBackTo);
        VisibleLog.ShowQSOStatus(@CallsignICameBackTo);
      end;

      DisplayUserInfo(CallsignICameBackTo);
      DisplayBeamHeading(CallsignICameBackTo, '');
    end

    else { not a dupe or not AutoDupeEnable }
    begin
      if MessageEnable and not BeSilent then
        if not (Debug and (CWTone = 0)) then
            //wli                    AddOnCQExchange;

          ShowName(CallsignICameBackTo);
      DisplayGridSquareStatus(CallsignICameBackTo);

      DisplayUserInfo(CallsignICameBackTo);
      DisplayBeamHeading(CallsignICameBackTo, '');
      DisplayCountryName(CallsignICameBackTo);

      if QTCsEnabled then
        DisplayQTCNumber(NumberQTCsThisStation(CallWindowString));

      if Contest <> GENERALQSO then
      begin
        VisibleLog.ShowMultiplierStatus(@CallWindowString);
        VisibleLog.ShowQSOStatus(@CallWindowString);
      end;

      VisibleLog.DoPossibleCalls(CallWindowString);

      if TailEnding then
      begin
            //        ReceivedData.ceSearchAndPounce := False;
        LogContact(PreviousQSOReceivedData, True);
        TailEnding := False;
      end;

//      if K5KA.ModeEnabled then DupeCheckOnInactiveRadio(False);

      if GotExchange then
      begin
        if TailEnding then
        begin
          TailEndCallString := '';
                //wli                    SendCorrectCallIfNeeded;
      //    if MessageEnable then AddStringToBuffer(TailEndMessage + ' ', CWTone);

          repeat
            repeat until NewKeyPressed;
            TempKey := UpCase(NewReadKey);
            if TempKey <> CarriageReturn then
              if ValidCallCharacter(TempKey) or (TempKey = '?') then
              begin
                if MessageEnable then
                  AddStringToBuffer(TempKey, CWTone);

                TailEndCallString := TailEndCallString + TempKey;
              end;
          until TempKey = CarriageReturn;

          if TailEndCallString = '' then
          begin
            TailEnding := False;
                    //            ReceivedData.ceSearchAndPounce := False;
            LogContact(ReceivedData, True);
          end;
        end
        else
        begin
          if ActiveMode = CW then
          begin
            RememberInactiveCQ := InactiveRigCallingCQ;

                    //wli                        SendCorrectCallIfNeeded;

            if not (Debug and (CWTone = 0)) then
            begin
              if MessageEnable and not (BeSilent or TailEnding) then
                if QuickQSL <> NoQuickQSLKey then
                begin
                  if QuickQSL = QuickKey1 then
                                //wli                                        SendCrypticMessage (QuickQSLMessage1)
                  else
                                //wli                                        SendCrypticMessage (QuickQSLMessage2);
                end
                else
                  if ExchangeInformation.Age then
                  begin
                    if ReceivedData.Age = {'00'} 0 then
                      Send88Message
                    else
                                  //wli                                            Send73Message;
                  end
                  else
                              //wli                                        Send73Message;

                    InactiveRigCallingCQ := RememberInactiveCQ;
            end;

          end
          else
            if MessageEnable and not BeSilent then
            begin
              if QuickQSL <> NoQuickQSLKey then
                        //wli                                SendCrypticMessage (QuickQSLPhoneMessage)
              else
                        //                                Send73Message;
            end;

          if DualingCQState = DualGettingExchange then
            DualingCQState := DualSendingQSL;

          BeSilent := False;

          if not TailEnding then
          begin
                    //            ReceivedData.ceSearchAndPounce := False;
            LogContact(ReceivedData, True);
          end;

        end;
      end
      else
        if CWSpeedFromDataBase and (RememberCWSpeed > 0) then
        begin
          SetSpeed(RememberCWSpeed);
          RememberCWSpeed := 0;
        end;
    end;
  until False;
end;

function tAddQSOToLog(RXData: ContestExchange): boolean;
var
  lpNumberOfBytesWritten                : Cardinal;
begin

  Result := False;
  if tPreviousDupeQSOsShowed then ShowPreviousDupeQSOsWnd(False); //DestroyPreviousDupeQSOsWnd;

  LogHandle := CreateFile(TR4W_LOG_FILENAME, GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_FLAG_WRITE_THROUGH, 0);
  if LogHandle = INVALID_HANDLE_VALUE then
  begin
//    showwarning(SysErrorMessage(GetLastError));
    ShowSysErrorMessage('SAVE_LOG');
    Exit;
  end;

//  if not OpenLogFile then Exit;

  tSetFilePointer(0, FILE_END);
  if tWriteFile(LogHandle, RXData, SizeOf(ContestExchange), lpNumberOfBytesWritten) then
    if lpNumberOfBytesWritten = SizeOf(ContestExchange) then
      inc(tRestartInfo.riTotalRecordsInLog);

  CloseLogFile;

  tSetWindowRedraw(wh[mweEditableLog], False);
  if tLogIndex = LinesInEditableLog then
  begin
    ListView_DeleteItem(wh[mweEditableLog], 0);
    tLogIndex := LinesInEditableLog - 1;
  end;
  tAddContestExchangeToLog(RXData, wh[mweEditableLog], tLogIndex);
  EnsureListViewColumnVisible(wh[mweEditableLog]);
  tSetWindowRedraw(wh[mweEditableLog], True);
  Result := True;
//  SendStationStatus;
end;

procedure LogContactToUDP(RXData: ContestExchange);
var
   msg: TIdBytes;
   sBuf: AnsiString;
   sMode : AnsiString;
   nNumberReceived : integer;
   sComputerID : AnsiString;
   sPrecedence : Char;
   freq : integer;
   txFreq : integer;
begin

   if ActiveRadioPtr.CurrentStatus.Split then
      begin
      freq := ActiveRadioPtr.CurrentStatus.Freq;
      txFreq := ActiveRadioPtr.CurrentStatus.VFO[VFOB].Frequency;
      end
   else
      begin
      freq := ActiveRadioPtr.CurrentStatus.Freq;
      txFreq := freq;
      end;
   case RXData.Mode of
       CW: sMode := 'CW';
       Phone: sMode := 'SSB';
       Digital: sMode := 'RTTY';
       else sMode := ' ';
    end; // of case

    if RxData.ceComputerID = #0 then
       begin
       sComputerID := ' ';
       end
    else
       begin
       sComputerID := RxData.ceComputerID;
       end;

    if RxData.Precedence = #0 then
       begin
       sPrecedence := #20;
       end
    else
       begin
       sPrecedence := RxData.Precedence;
       end;

    nNumberReceived := IfThen(RxData.NumberReceived > 0,RxData.NumberReceived,0);
    sBuf := '<?xml version="1.0"?>' +
            '<contactinfo>' +

            '<contestname>' + ContestTypeSA[RxData.ceContest] + '</contestname>' +
            '<contestnr>3</contestnr>' +
            '<timestamp>' +                      // 2008-01-01 07:04:00
               SysUtils.format('20%0.2d-%0.2d-%0.2d %0.2d:%0.2d:%0.2d',[
                      RxData.tSysTime.qtYear,
                      RxData.tSysTime.qtMonth,
                      RxData.tSysTime.qtDay,
                      RxData.tSysTime.qtHour,
                      RxData.tSysTime.qtMinute,
                      RxData.tSysTime.qtSecond]) +

            '</timestamp>' +
            '<mycall>' + MyCall + '</mycall>' +
            '<band>' + BandStringsArrayWithOutSpaces[RxData.Band] + '</band>' +
            '<rxfreq>' + Format('%d',[freq div 10]) + '</rxfreq>' + // 1420100
            '<txfreq>' + Format('%d',[txFreq div 10]) + '</txfreq>' +
            '<operator>' + RxData.ceOperator + '</operator>' +
            '<mode>' + sMode + '</mode>' +
            '<call>' + RXData.Callsign + '</call>' +
            '<countryprefix>' + RxData.QTH.CountryID + '</countryprefix>' +
            '<wpxprefix>' + RxData.QTH.Prefix + '</wpxprefix>' +
            '<stationprefix>' + RXData.QTH.Prefix + '</stationprefix>' +
            '<continent>' + GetContinentName(RXData.QTH.Continent) + '</continent>' +
            '<snt>' + Format('%d',[RxData.RSTSent]) + '</snt>' +
            '<sntnr>' + Format('%d',[RxData.NumberSent]) + '</sntnr>' +
            '<rcv>' + Format('%d',[RxData.RSTReceived]) + '</rcv>' +
            '<rcvnr>' + Format('%d',[nNumberReceived]) + '</rcvnr>' +
            '<gridsquare></gridsquare>' +
            '<exchange1></exchange1>' +
            '<section>' + '</section>' +
            '<comment></comment>' +
            '<qth>' + RxData.QTHString + '</qth>' +
            '<name>' + RxData.Name + '</name>' +
            '<power>' + RxData.Power + '</power>' +
            '<misctext></misctext>' +
            '<zone>' + Format('%d',[RxData.QTH.Zone]) + '</zone>' +
            '<prec>' + {sPrecedence +} '</prec>' +
            '<ck>' + Format('%d',[RxData.Check]) + '</ck>' +                // TODO
            '<ismultiplier1>0</ismultiplier1>' +
            '<ismultiplier2>0</ismultiplier2>' +
            '<ismultiplier3>0</ismultiplier3>' +
            '<points>0</points>' +
            '<radionr>' + Format('%d',[Ord(RxData.ceRadio)]) + '</radionr>' +
            '<RoverLocation></RoverLocation>' +
            '<RadioInterfaced>1</RadioInterfaced>' +
            '<NetworkedCompNr>0</NetworkedCompNr>' + // TODO
            '<IsOriginal>True</IsOriginal>' + // TODO what is this field?
            '<NetBiosName>' + sComputerID + '</NetBiosName>' +
            '<IsRunQSO>' + Format('%d',[IfThen(RxData.ceSearchAndPounce,0,1)]) + '</IsRunQSO>' +
      '</contactinfo>';


   SetLength(msg,Length(sBuf));
   msg := RawToBytes(sBuf[1], Length(sBuf));
   udp.Broadcast(msg, UDPBroadcastPort);     // ny4i 4.44.9

end;

end.

