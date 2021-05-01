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
unit CFGCMD;

{$IMPORTEDDATA OFF}

interface

uses {SlowTree,} Tree,

  Windows,
  TF,
  VC,
  utils_text,
  uTelnet,
  LogStuff,

  LogSCP,
  LogCW,
  LogWind,
  LogDupe,
  ZoneCont,
  LogGrid,
  LogDom,
  FCONTEST,
  LOGDVP,
//  Country9,
  LogEdit,
  //LOGDDX,
//  LOGHP,
  LOGWAE,
  LogPack,
  LogK1EA, {DOS, }
//  Help,
//  LOGPROM, {Crt, }
  LogNet,
//  ColorCfg,
  LogRadio 

  ;
var
LPTBaseAddressArray                   : array[Parallel1..Parallel3] of Cardinal = ($378, $278, $3BC);

function ProcessConfigInstruction(var FileString: ShortString; var FirstCommand: boolean): boolean;

function ProcessConfigInstructions1(ID: Str80; CMD: ShortString): boolean;
function ProcessConfigInstructions2(ID: Str80; CMD: ShortString): boolean;
function ProcessConfigInstructions3(ID: Str80; CMD: ShortString): boolean;

procedure SniffOutControlCharacters(var TempString: ShortString);

function ProcessRadioTypeold(CMD: ShortString; RadioPointer: RadioPtr): boolean;
//function ProcessRadioControlPort(CMD: ShortString; RadioPointer: RadioPtr): boolean;
//function ProcessRadioDTR(CMD: ShortString; RadioPointer: RadioPtr): boolean;
//function GetPortFromChar(port: ShortString): PortType;
function GetLPTPortFromChar(port: ShortString): PortType;

var
  ConfigFileRead                        : Text;
  ClearDupeSheetCommandGiven            : boolean;
  RunningConfigFile                     : boolean; { True when using Control-V command }

//  tr4w_BoolValue                        : boolean;
  //const

implementation

uses
  uCFG,
  //   Settings_unit,
//  OZCHR,
  uNet,
  uRadioPolling,
  uBandmap,
  MainUnit;

procedure SniffOutControlCharacters(var TempString: ShortString);

var
  NumericString                         : Str20;
  {wli StringLength, }NumericValue, Result: integer;

begin
  if TempString = '' then Exit;

  //wli  StringLength := length(TempString);

  Count := 1;

  while Count <= length(TempString) - 3 do
  begin
    if (TempString[Count] = '<') and (TempString[Count + 3] = '>') then
    begin
      NumericString := UpperCase(Copy(TempString, Count + 1, 2));

      HexToInteger(NumericString, NumericValue, Result);

      if Result = 0 then
      begin
        Delete(TempString, Count, 4);
        Insert(CHR(NumericValue), TempString, Count);
      end;
    end;

    inc(Count);
  end;
end;

function ProcessConfigInstructions1(ID: Str80; CMD: ShortString): boolean;

begin
  ProcessConfigInstructions1 := False;

  if CheckCommand(@ID, CMD) then
  begin
    ProcessConfigInstructions1 := True;
    Exit;
  end;



end;

function ProcessConfigInstructions2(ID: Str80; CMD: ShortString): boolean;
label
  M_commands;
var
  Result1                               : integer;

begin

  ProcessConfigInstructions2 := False;

  if CheckCommand(@ID, CMD) then
  begin
    ProcessConfigInstructions2 := True;
    Exit;
  end;

  //  if iD[1] >= 'M' then goto M_commands;

 
  if ID = 'LPT1 BASE ADDRESS' then
  begin
    Val(CMD, LPTBaseAddressArray[Parallel1], Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;

  if ID = 'LPT2 BASE ADDRESS' then
  begin
    Val(CMD, LPTBaseAddressArray[Parallel2], Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;

  if ID = 'LPT3 BASE ADDRESS' then
  begin
    Val(CMD, LPTBaseAddressArray[Parallel3], Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;

{  if ID = 'Multiplier Item Width' then
  begin
   Val(CMD, MultiplierItemWIdth,Result1);
   MultiplierItemWidth := StrtoInt(CMD) ;
   tLB_SETCOLUMNWIDTH(tr4w_WindowsArray[tw_REMMULTSWINDOW_INDEX].WndHandle, MultiplierItemWidth);
   end;

  if ID = 'FARNSWORTH ENABLE' then
  begin
    FarnsworthEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'FARNSWORTH SPEED' then
  begin
    Val(CMD, FarnsworthSpeed, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;
}

//  if ID = 'FILTER RADIO MESSAGE LENGTH' then
//  begin
      {
               if UpCase(CMD[1]) = 'T' then
                  begin
                     Radio1.FilterRadioMessageLength := True;
                     Radio2.FilterRadioMessageLength := True;
                  end;
      }
//    asm inc ebx
//    end; //    ProcessConfigInstructions2 := True;
//    Exit;
//  end;
{
  if ID = 'FLOPPY FILE SAVE FREQUENCY' then
  begin
    Val(CMD, FloppyFileSaveFrequency, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;

  if ID = 'FLOPPY FILE SAVE NAME' then
  begin
    FloppyFileSaveName := CMD;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'FOOT SWITCH MODE' then
  begin
    FootSwitchMode := FootSwitchDisabled;

    if CMD = 'NORMAL' then FootSwitchMode := Normal;
    if CMD = 'F1' then FootSwitchMode := FootSwitchF1;
    if CMD = 'LAST CQ FREQ' then FootSwitchMode := FootSwitchLastCQFreq;
    if CMD = 'NEXT BANDMAP' then FootSwitchMode := FootSwitchNextBandMap;
    if CMD = 'NEXT DISP BANDMAP' then FootSwitchMode := FootSwitchNextDisplayedBandMap; //KK1L: 6.64
    if CMD = 'NEXT MULT BANDMAP' then FootSwitchMode := FootSwitchNextMultBandMap; //KK1L: 6.68
    if CMD = 'NEXT MULT DISP BANDMAP' then FootSwitchMode := FootSwitchNextMultDisplayedBandMap; //KK1L: 6.68
    if CMD = 'DUPE CHECK' then FootSwitchMode := FootSwitchDupecheck;
    if CMD = 'DUPECHECK' then FootSwitchMode := FootSwitchDupecheck;
    if CMD = 'QSO NORMAL' then FootSwitchMode := QSONormal;
    if CMD = 'QSO QUICK' then FootSwitchMode := QSOQuick;
    if CMD = 'CONTROL ENTER' then FootSwitchMode := FootSwitchControlEnter;
    if CMD = 'START SENDING' then FootSwitchMode := StartSending;
    if CMD = 'SWAP RADIOS' then FootSwitchMode := SwapRadio;
    if CMD = 'CW GRANT' then FootSwitchMode := CWGrant;

    ProcessConfigInstructions2 := (FootSwitchMode <> FootSwitchDisabled) or (CMD = 'DISABLED');
    Exit;
  end;
}
{
  if ID = 'FOOT SWITCH PORT' then
  begin
      //    ActiveFootSwitchPort := NoPort;
      //
      //    if CMD = '1' then ActiveFootSwitchPort := Parallel1;
      //    if CMD = '2' then ActiveFootSwitchPort := Parallel2;
      //    if CMD = '3' then ActiveFootSwitchPort := Parallel3;
    ActiveFootSwitchPort := GetLPTPortFromChar(CMD);
    ProcessConfigInstructions2 := (ActiveFootSwitchPort <> NoPort);
    Exit;
  end;
}
{
  if ID = 'FREQUENCY ADDER' then
  begin
    Val(CMD, Radio1.FrequencyAdder, Result1);
    Radio2.FrequencyAdder := Radio1.FrequencyAdder;
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;
}
//  if (ID = ('FREQUENCY ADDER RADIO ONE')) { or
//  (ID = ('RADIO ONE FREQUENCY ADDER')) }then
{
  if ID = 'RADIO ONE FREQUENCY ADDER' then
  begin
    Val(CMD, Radio1.FrequencyAdder, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;
}
//  if (ID = ('FREQUENCY ADDER RADIO TWO')) { or
//  (ID = ('RADIO TWO FREQUENCY ADDER')) }then
{
  if ID = 'RADIO TWO FREQUENCY ADDER' then
  begin
    Val(CMD, Radio2.FrequencyAdder, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;
}
{
  if ID = 'FREQUENCY MEMORY' then
  begin
    if StringHas(CMD, 'SSB') then
    begin
      Delete(CMD, pos('SSB ', CMD), 4);

      Val(CMD, TempFreq, Result1);

      if Result1 = 0 then
      begin
        CalculateBandMode(TempFreq, TempBand, TempMode);
        FreqMemory[TempBand, Phone] := TempFreq;
        asm inc ebx
        end; //        ProcessConfigInstructions2 := True;
        Exit;
      end;
    end
    else
    begin
      Val(CMD, TempFreq, Result1);

      if Result1 = 0 then
      begin
        CalculateBandMode(TempFreq, TempBand, TempMode);
        FreqMemory[TempBand, TempMode] := TempFreq;
        asm inc ebx
        end; //        ProcessConfigInstructions2 := True;
      end;
    end;

    Exit;
  end;
}
{
  if ID = 'FREQUENCY MEMORY ENABLE' then
  begin
    FrequencyMemoryEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
  {KK1L: 6.71}
//  if ID = 'FREQUENCY POLL RATE' then
//  begin
//    Val(CMD, TempLongInt, Result1);
//    if (TempLongInt >= 10) and (TempLongInt <= 1000) then {KK1L: 6.72}
//      FreqPollRate := TempLongInt
//    else
//      FreqPollRate := 250; {KK1L: 6.73 Better resutls with Icom and other radios.}
//    asm inc ebx
//    end; //    ProcessConfigInstructions2 := Result1 = 0;
//    Exit;
//  end;
{
  if ID = 'FT1000MP CW REVERSE' then
  begin
    Radio1.FT1000MPCWReverse := StackBool;
    Radio2.FT1000MPCWReverse := Radio1.FT1000MPCWReverse;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'GRID MAP CENTER' then
  begin
//    if LooksLikeAGrid(CMD) or (CMD = '') then
    begin
      GridMapCenter := Copy(CMD, 1, 4);
      asm inc ebx
      end; //      ProcessConfigInstructions2 := True;
    end;
    Exit;
  end;
}
{
  if ID = 'HF BAND ENABLE' then
  begin
    HFBandEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'HOUR DISPLAY' then
  begin
    if CMD = 'THIS HOUR' then HourDisplay := ThisHour;
    if CMD = 'LAST SIXTY MINUTES' then HourDisplay := LastSixtyMins;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'HOUR OFFSET' then
  begin
      //    Val(CMD, HourOffset, Result1);
      //    ProcessConfigInstructions2 := Result1 = 0;
    asm inc ebx
    end;
    Exit;
  end;
}
{
  if ID = 'ICOM RESPONSE TIMEOUT' then
  begin
    Val(CMD, cmdIcomResponseTimeout, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    if Result1 = 0 then cmdIcomResponseTimeout := cmdIcomResponseTimeout div 10 else Exit;
    if not (cmdIcomResponseTimeout in [10..100]) then cmdIcomResponseTimeout := 10;
    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'ICOM COMMAND PAUSE' then
  begin
      //         TR4W_ICOM_COMMAND_PAUSE := StrToInt(CMD);
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
  //??????
{
  if Id = 'ICOM SET MODE' then
     begin
        TR4W_ICOM_SET_MODE := Strtoint(CMD);
        asm inc ebx
        end; //    ProcessConfigInstructions2 := True;
        Exit;
     end;
}
{
  if ID = 'INCREMENT TIME ENABLE' then
  begin
    IncrementTimeEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'INITIAL EXCHANGE' then
  begin
    if CMD = 'NONE' then
    begin
      ActiveInitialExchange := NoInitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'CUSTOM' then
    begin
      ActiveInitialExchange := CustomInitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'NAME' then
    begin
      ActiveInitialExchange := NameInitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'ZONE' then
    begin
      ActiveInitialExchange := ZoneInitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'NAME QTH' then
    begin
      ActiveInitialExchange := NameQTHInitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'CHECK SECTION' then
    begin
      ActiveInitialExchange := CheckSectionInitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'SECTION' then
    begin
      ActiveInitialExchange := SectionInitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'QTH' then
    begin
      ActiveInitialExchange := QTHInitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'GRID' then
    begin
      ActiveInitialExchange := GridInitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'FOC NUMBER' then
    begin
      ActiveInitialExchange := FOCInitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'USER 1' then
    begin
      ActiveInitialExchange := User1InitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'USER 2' then
    begin
      ActiveInitialExchange := User2InitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'USER 3' then
    begin
      ActiveInitialExchange := User3InitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'USER 4' then
    begin
      ActiveInitialExchange := User4InitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    if CMD = 'USER 5' then
    begin
      ActiveInitialExchange := User5InitialExchange;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end;

    Exit;
  end;
}
{
  if ID = 'INITIAL EXCHANGE FILENAME' then
  begin
    InitialExchangeFilename := CMD;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
  {KK1L: 6.70}
{
  if ID = 'INITIAL EXCHANGE OVERWRITE' then
  begin
    InitialExchangeOverwrite := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'INITIAL EXCHANGE CURSOR POS' then
  begin
    if StringHas(CMD, 'END') then InitialExchangeCursorPos := AtEnd;
    if StringHas(CMD, 'START') then InitialExchangeCursorPos := AtStart;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'INSERT MODE' then
  begin
    InsertMode := StackBool;
//    DisplayInsertMode;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'INTERCOM FILE ENABLE' then
  begin
    IntercomFileenable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'K1EA NETWORK ENABLE' then
  begin
      //    K1EANetworkEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'K1EA STATION ID' then
  begin
      //    K1EAStationID := UpCase(CMD[1]);
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'KEYER OUTPUT PORT' then
  begin
          RadioOneKeyerOutputPort := NoPort;

          if StringHas(CMD, 'SERIAL 1') then RadioOneKeyerOutputPort := Serial1;
          if StringHas(CMD, 'SERIAL 2') then RadioOneKeyerOutputPort := Serial2;
          if StringHas(CMD, 'SERIAL 3') then RadioOneKeyerOutputPort := Serial3;
          if StringHas(CMD, 'SERIAL 4') then RadioOneKeyerOutputPort := Serial4;
          if StringHas(CMD, 'SERIAL 5') then RadioOneKeyerOutputPort := Serial5;
          if StringHas(CMD, 'SERIAL 6') then RadioOneKeyerOutputPort := Serial6;

          if StringHas(CMD, 'PARALLEL 1') then RadioOneKeyerOutputPort := Parallel1;
          if StringHas(CMD, 'PARALLEL 2') then RadioOneKeyerOutputPort := Parallel2;
          if StringHas(CMD, 'PARALLEL 3') then RadioOneKeyerOutputPort := Parallel3;

    Radio1.tKeyerPort := GetPortFromChar(CMD);
    Radio1SerialInvert := StringHas(CMD, 'INVERT');
    Radio2SerialInvert := StringHas(CMD, 'INVERT');

    Radio2.tKeyerPort := Radio1.tKeyerPort;
    ProcessConfigInstructions2 := (Radio1.tKeyerPort <> NoPort) or (CMD = 'NONE');
    Exit;
  end;
}
{
  if ID = 'KEYER RADIO ONE OUTPUT PORT' then
  begin
    Radio1.tKeyerPort := GetPortFromChar(CMD);
    Radio1SerialInvert := StringHas(CMD, 'INVERT');
    ProcessConfigInstructions2 := (Radio1.tKeyerPort <> NoPort) or (CMD = 'NONE');
    Exit;
  end;

  if ID = 'KEYER RADIO TWO OUTPUT PORT' then
  begin
    Radio2.tKeyerPort := GetPortFromChar(CMD);
    Radio2SerialInvert := StringHas(CMD, 'INVERT');
    ProcessConfigInstructions2 := Radio2.tKeyerPort <> NoPort;
    Exit;
  end;
}
{
  if ID = 'KEYPAD CW MEMORIES' then
  begin
    KeypadCWMemories := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'LEADING ZEROS' then
  begin

    if StringIsAllNumbers(CMD) then
    begin
      Val(CMD, LeadingZeros, Result1);
      ProcessConfigInstructions2 := (Result1 = 0) and (LeadingZeros in [0..3]);
      Exit;
    end
    else
      if (CMD[1] = 'T')  then
        LeadingZeros := 3
      else
        LeadingZeros := 0;

    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'LEADING ZERO CHARACTER' then
  begin
    LeadingZeroCharacter := CMD[1];
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'LEAVE CURSOR IN CALL WINDOW' then
  begin
    LeaveCursorInCallWindow := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'LITERAL DOMESTIC QTH' then
  begin
    LiteralDomesticQTH := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'LOG FREQUENCY ENABLE' then
  begin
    LogFrequencyEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'LOG RST SENT' then
  begin
    LogRSTSent := StrToInt(CMD);
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'LOG RS SENT' then
  begin
    LogRSSent := StrToInt(CMD);
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'LOG WITH SINGLE ENTER' then
  begin
    LogWithSingleEnter := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'LOOK FOR RST SENT' then
  begin
    LookForRSTSent := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
  M_commands:
{
  if ID = 'MESSAGE ENABLE' then
  begin
    MessageEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'MISSINGCALLSIGNS FILE ENABLE' then
  begin
    tMissCallsFileEnable := StackBool;
    asm inc ebx
    end;
    Exit;
  end;
}
  {
    if ID = 'MMTTY PATH' then
      begin
        //    MMTTYPATH := CMD;
        Windows.CopyMemory(@MMTTYPATH, @CMD[1], length(CMD));
        asm inc ebx
        end;
        Exit;
      end;
  }
{
  if ID = 'MODE' then
  begin
    ActiveMode := NoMode;
    if (CMD = 'SSB') or (CMD = 'PHONE') then
      ActiveMode := Phone;
    if CMD = 'CW' then ActiveMode := CW;
    ProcessConfigInstructions2 := ActiveMode <> NoMode;
    Exit;
  end;
}
  {
    if ID = 'MODEM PORT' then
    begin
      ActiveModemPort := NoPort;

      if StringHas(CMD, 'SERIAL 1') then ActiveModemPort := Serial1;
      if StringHas(CMD, 'SERIAL 2') then ActiveModemPort := Serial2;
      if StringHas(CMD, 'SERIAL 3') then ActiveModemPort := Serial3;
      if StringHas(CMD, 'SERIAL 4') then ActiveModemPort := Serial4;
      if StringHas(CMD, 'SERIAL 5') then ActiveModemPort := Serial5;
      if StringHas(CMD, 'SERIAL 6') then ActiveModemPort := Serial6;

      if StringHas(CMD, 'DRSI') then ActiveModemPort := DRSI;
      ProcessConfigInstructions2 := (ActiveModemPort <> NoPort) or (CMD = 'NONE');
      Exit;
    end;

    if ID = 'MODEM PORT BAUD RATE' then
    begin
      Val(CMD, ModemPortBaudRate, Result1);
      ProcessConfigInstructions2 := (Result1 = 0) and (ModemPortBaudRate <= 4800);
      Exit;
    end;

    if ID = 'MOUSE ENABLE' then
    begin
      MouseEnable := StackBool;
      asm inc ebx end;//    ProcessConfigInstructions2 := True;
      Exit;
    end;

  if ID = 'MULT REPORT MINIMUM BANDS'then
  begin
    Val(CMD, MultReportMinimumBands, Result1);
    ProcessConfigInstructions2 := (Result1 = 0) and (MultReportMinimumBands in [2..5]);
    Exit;
  end;
}
{
  if ID = 'MULTI INFO MESSAGE' then
  begin
    MultiInfoMessage := CMD;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'MULTI MULTS ONLY' then
  begin
    MultiMultsOnly := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
//  if ID = 'MULTI PORT' then
//  begin
      //    TempPort := NoPort;
      //
//         ActiveMultiPort := GetPortFromChar(CMD);

      {    if StringHas(CMD, 'SERIAL ') then
          begin
            if CMD[8] = '1' then TempPort := Serial1;
            if CMD[8] = '2' then TempPort := Serial2;
            if CMD[8] = '3' then TempPort := Serial3;
            if CMD[8] = '4' then TempPort := Serial4;
            if CMD[8] = '5' then TempPort := Serial5;
            if CMD[8] = '6' then TempPort := Serial6;
            ActiveMultiPort:=TempPort;
      end;
      }
      {    if StringHas(CMD, 'SERIAL 1') then ActiveMultiPort := Serial1;
          if StringHas(CMD, 'SERIAL 2') then ActiveMultiPort := Serial2;
          if StringHas(CMD, 'SERIAL 3') then ActiveMultiPort := Serial3;
          if StringHas(CMD, 'SERIAL 4') then ActiveMultiPort := Serial4;
          if StringHas(CMD, 'SERIAL 5') then ActiveMultiPort := Serial5;
          if StringHas(CMD, 'SERIAL 6') then ActiveMultiPort := Serial6;
      }
//         if ActiveMultiPort <> NoPort then Packet.PacketBandSpots := True;
//         ProcessConfigInstructions2 := (ActiveMultiPort <> NoPort) or (CMD = 'NONE');
//    asm inc ebx
//    end;
//    Exit;
//  end;
{
  if ID = 'MULTI PORT BAUD RATE' then
  begin
      //         Val(CMD, MultiPortBaudRate, Result1);
      //         ProcessConfigInstructions2 := (Result1 = 0) and (MultiPortBaudRate <= 4800);
    asm inc ebx
    end;
    Exit;
  end;

  if ID = 'MULTI RETRY TIME' then
  begin
    Val(CMD, MultiRetryTime, Result1);
    ProcessConfigInstructions2 := (Result1 = 0) and (MultiRetryTime >= 3);
    Exit;
  end;

  if ID = 'MULTI UPDATE MULT DISPLAY' then
  begin
    MultiUpdateMultDisplay := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'MULTIPLE BANDS' then
  begin
    MultipleBandsEnabled := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'MULTIPLE MODES' then
  begin
    MultipleModesEnabled := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'MY GRID' then
  begin
    ProcessConfigInstructions2 := LooksLikeAGrid(CMD);
    MyGrid := tMakeGridFromString(CMD);
    Exit;
  end;
}
{
  if ID = 'MY IOTA' then
  begin
    MyIOTA := CMD;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'NAME FLAG ENABLE' then
  begin
    NameFlagEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'NO LOG' then
  begin
    NoLog := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'NO POLL DURING PTT' then
  begin
    NoPollDuringPTT := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}

{
  if ID = 'ORION PORT' then
  begin
    ActiveRotatorType := OrionRotator;
    ActiveRotatorPort := GetPortFromChar(CMD);
    ProcessConfigInstructions2 := ActiveRotatorPort <> NoPort;
    Exit;
  end;
]
{
  if ID = 'PACKET ADD LF' then
  begin
      //    PacketAddLF := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PACKET AUTO CR' then
  begin
      //    PacketAutoCR := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PACKET BAND SPOTS' then
  begin
      //    Packet.PacketBandSpots := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PACKET BAUD RATE' then
  begin
      //    Val(CMD, Packet.PacketBaudRate, Result1);
      //    ProcessConfigInstructions2 := (Result1 = 0) and (Packet.PacketBaudRate <= 9600);
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PACKET BEEP' then
  begin
      //    Packet.PacketBeep := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'PACKET LOG FILENAME' then
  begin
      //    Packet.PacketLogFileName := CMD;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
//  if ID = 'PACKET PORT' then
//  begin
      //    Packet.PacketSerialPort := NoPort;
      //
      {    if StringHas(CMD, 'SERIAL 1') then Packet.PacketSerialPort := Serial1;
          if StringHas(CMD, 'SERIAL 2') then Packet.PacketSerialPort := Serial2;
          if StringHas(CMD, 'SERIAL 3') then Packet.PacketSerialPort := Serial3;
          if StringHas(CMD, 'SERIAL 4') then Packet.PacketSerialPort := Serial4;
          if StringHas(CMD, 'SERIAL 5') then Packet.PacketSerialPort := Serial5;
          if StringHas(CMD, 'SERIAL 6') then Packet.PacketSerialPort := Serial6;
      }

      //    Packet.PacketSerialPort := GetPortFromChar(CMD);
      //    if StringHas(CMD, 'DRSI') then Packet.PacketSerialPort := DRSI;
      //    ProcessConfigInstructions2 := (Packet.PacketSerialPort <> NoPort) or (CMD = 'NONE');
//    asm inc ebx
//    end; //    ProcessConfigInstructions2 := True;
//    Exit;
//  end;
{
  if ID = 'PACKET PORT BAUD RATE' then
  begin
      //    Val(CMD, Packet.PacketBaudRate, Result1);
      //    ProcessConfigInstructions2 := (Result1 = 0) and (Packet.PacketBaudRate <= 4800);
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'PACKET RETURN PER MINUTE' then
  begin
      //    Val(CMD, PacketReturnPerMinute, Result1);
      //    ProcessConfigInstructions2 := Result1 = 0;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PACKET SPOT EDIT ENABLE' then
  begin
      //    PacketSpotEditEnable := StackBool;
      //    asm inc ebx end;//    ProcessConfigInstructions2 := True;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PACKET SPOT DISABLE' then
  begin
    PacketSpotDisable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PACKET SPOT KEY' then
  begin
    PacketSpotKey := CMD[1];
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PACKET SPOT PREFIX ONLY' then //KK1L: 6.72
  begin
    PacketSpotPrefixOnly := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PACKET SPOTS' then
  begin
//    CMD := UpperCase(Copy(CMD, 1, 1));
    TempChar := CMD[1];

    if TempChar = 'A' then
    begin
      Packet.PacketSpots := AllSpots;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end
    else
      if TempChar = 'M' then
      begin
        Packet.PacketSpots := MultSpots;
        asm inc ebx
        end; //    ProcessConfigInstructions2 := True;
      end;
  end;

  if ID = 'PADDLE BUG ENABLE' then
  begin
    PaddleBug := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PADDLE MONITOR TONE' then
  begin
    Val(CMD, PaddleMonitorTone, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;

  if ID = 'PADDLE PORT' then
  begin
    ActivePaddlePort := GetLPTPortFromChar(CMD);
    ProcessConfigInstructions2 := ActivePaddlePort <> NoPort;
    Exit;
  end;

  if ID = 'PADDLE SPEED' then
  begin
    Val(CMD, PaddleSpeed, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    tSetPaddleElementLength;
    Exit;
  end;

  if ID = 'PADDLE PTT HOLD COUNT' then
  begin
    Val(CMD, PaddlePTTHoldCount, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;

  if ID = 'PARTIAL CALL ENABLE' then
  begin
    PartialCallEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PARTIAL CALL LOAD LOG ENABLE' then
  begin
      //         PartialCallLoadLogEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PARTIAL CALL MULT INFO ENABLE' then
  begin
    PartialCallMultsEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'POLL RADIO ONE' then //KK1L: 6.72
  begin
    Radio1.PollingEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'POLL RADIO TWO' then //KK1L: 6.72
  begin
    Radio2.PollingEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'POSSIBLE CALL ACCEPT KEY' then
  begin
    PossibleCallAcceptKey := CMD[1];
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'POSSIBLE CALL LEFT KEY' then
  begin
    PossibleCallLeftKey := CMD[1];
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'POSSIBLE CALL RIGHT KEY' then
  begin
    PossibleCallRightKey := CMD[1];
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'POSSIBLE CALLS' then
  begin
    PossibleCallEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}

{
  if ID = 'POSSIBLE CALL MODE' then
  begin
    if WRTC2002 then //KK1L: 6.69 Don't allow WRTC folks to get SCP data from TRMaste
    begin
      CD.PossibleCallAction := LogOnly;
      asm inc ebx
      end; //    ProcessConfigInstructions2 := True;
    end
    else
    begin
      if CMD = 'ALL' then
      begin
        CD.PossibleCallAction := AnyCall;
        asm inc ebx
        end; //    ProcessConfigInstructions2 := True;
      end;

      if StringHas(CMD, 'NAME') then
      begin
        CD.PossibleCallAction := OnlyCallsWithNames;
        asm inc ebx
        end; //    ProcessConfigInstructions2 := True;
      end;

      if CMD = 'LOG ONLY' then
      begin
        CD.PossibleCallAction := LogOnly;
        asm inc ebx
        end; //    ProcessConfigInstructions2 := True;
      end;
    end;

    Exit;
  end;
}
  {
    if ID = 'PREFIX INFO FILENAME' then
      begin
        PrefixInfoFileName := CMD;
        asm inc ebx
        end; //    ProcessConfigInstructions2 := True;
        Exit;
      end;
  }
    //W_L_I
    {   if ID = 'PRINTER ENABLE' then
          begin
             PrinterEnabled := StackBool;
             asm inc ebx end;//    ProcessConfigInstructions2 := True;
             exit;
          end;
    }
{
  if ID = 'PTT LOCKOUT' then
  begin
    PTTLockout := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'PTT ENABLE' then
  begin
    PTTEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if (ID = 'PTT TURN ON DELAY') then
  begin
    Val(CMD, PTTTurnOnDelay, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;

  if (ID = 'PTT VIA COMMANDS') then
  begin
    tPTTViaCommand := StackBool;
    asm inc ebx
    end;
    Exit;
  end;
}
{
  if (ID = 'QSL MESSAGE') or (ID = 'QSL CW MESSAGE') then
  begin
    SniffOutControlCharacters(CMD);
    QSLMessage := CMD;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'QSL SSB MESSAGE' then
  begin
    QSLPhoneMessage := CMD;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'QSL MODE' then
  begin
    ParameterOkayMode := NoParameterOkayMode;

    if StringHas(CMD, 'STAN') then ParameterOkayMode := Standard;

    if StringHas(CMD, 'BUT') then
      ParameterOkayMode := QSLButDoNotLog
    else
      if StringHas(CMD, 'QSL') then ParameterOkayMode := QSLAndLog;

    ProcessConfigInstructions2 := ParameterOkayMode <> NoParameterOkayMode;
    Exit;
  end;
}
{
  if (ID = 'QSO BEFORE MESSAGE') or (ID = 'QSO BEFORE CW MESSAGE') then
  begin
    SniffOutControlCharacters(CMD);
    QSOBeforeMessage := CMD;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'QSO BEFORE SSB MESSAGE' then
  begin
    QSOBeforePhoneMessage := CMD;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'QSO NUMBER BY BAND' then
  begin
    QSONumberByBand := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'QSX ENABLE' then
  begin
    QSXEnable := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'QTC ENABLE' then
  begin
    QTCsEnabled := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'QTC EXTRA SPACE' then
  begin
    QTCExtraSpace := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'QTC MINUTES' then
  begin
    QTCMinutes := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'QTC QRS' then
  begin
    QTCQRS := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'QUESTION MARK CHAR' then
  begin
    QuestionMarkChar := CMD[1];
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if (ID = 'QUICK QSL KEY') or (ID = 'QUICK QSL KEY 1') then
  begin
    QuickQSLKey1 := CMD[1];
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'QUICK QSL KEY 2' then
  begin
    QuickQSLKey2 := CMD[1];
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}

{
  if ID = 'RADIO ONE BAND OUTPUT PORT' then
  begin
    Radio1.BandOutputPort := GetLPTPortFromChar(CMD);
    ProcessConfigInstructions2 := Radio1.BandOutputPort <> NoPort;

  end;

  if ID = 'RADIO TWO BAND OUTPUT PORT' then
  begin
    Radio2.BandOutputPort := GetLPTPortFromChar(CMD);
    ProcessConfigInstructions2 := Radio2.BandOutputPort <> NoPort;
  end;

  if ID = 'RADIO ONE BAUD RATE' then
  begin
    Val(CMD, Radio1.RadioBaudRate, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;
}
{
  if ID = 'RADIO ONE CAT RTS' then
  begin
    Radio1.tr4w_cat_rts_state := RtsDtr_Nothing;
    if CMD = 'ON' then Radio1.tr4w_cat_rts_state := RtsDtr_ON;
    if CMD = 'OFF' then Radio1.tr4w_cat_rts_state := RtsDtr_OFF;
    ProcessConfigInstructions2 := Radio1.tr4w_cat_rts_state <> RtsDtr_Nothing;
    Exit;
  end;

  if ID = 'RADIO ONE CAT DTR' then
  begin
    Radio1.tr4w_cat_dtr_state := RtsDtr_Nothing;
    if CMD = 'ON' then Radio1.tr4w_cat_dtr_state := RtsDtr_ON;
    if CMD = 'OFF' then Radio1.tr4w_cat_dtr_state := RtsDtr_OFF;
    ProcessConfigInstructions2 := Radio1.tr4w_cat_dtr_state <> RtsDtr_Nothing;
    Exit;
  end;
}
{
  if ID = 'RADIO ONE KEYER RTS' then
  begin
    Radio1.tr4w_keyer_rts_state := RtsDtr_Nothing;
    if CMD = 'CW' then Radio1.tr4w_keyer_rts_state := RtsDtr_CW;
    if CMD = 'PTT' then Radio1.tr4w_keyer_rts_state := RtsDtr_PTT;
    if CMD = 'ON' then Radio1.tr4w_keyer_rts_state := RtsDtr_ON;
    if CMD = 'OFF' then Radio1.tr4w_keyer_rts_state := RtsDtr_OFF;
    ProcessConfigInstructions2 := Radio1.tr4w_keyer_rts_state <> RtsDtr_Nothing;
    Exit;
  end;
}
{
  if ID = 'RADIO ONE KEYER DTR' then
  begin
    ProcessConfigInstructions2 := ProcessRadioDTR(CMD, @Radio1);
    Exit;
  end;
}
  //TWO
{
  if ID = 'RADIO TWO CAT RTS' then
  begin
    Radio2.tr4w_cat_rts_state := RtsDtr_Nothing;
    if CMD = 'ON' then Radio2.tr4w_cat_rts_state := RtsDtr_ON;
    if CMD = 'OFF' then Radio2.tr4w_cat_rts_state := RtsDtr_OFF;
    ProcessConfigInstructions2 := Radio2.tr4w_cat_rts_state <> RtsDtr_Nothing;
    Exit;
  end;

  if ID = 'RADIO TWO CAT DTR' then
  begin
    Radio2.tr4w_cat_dtr_state := RtsDtr_Nothing;
    if CMD = 'ON' then Radio2.tr4w_cat_dtr_state := RtsDtr_ON;
    if CMD = 'OFF' then Radio2.tr4w_cat_dtr_state := RtsDtr_OFF;
    ProcessConfigInstructions2 := Radio2.tr4w_cat_dtr_state <> RtsDtr_Nothing;
    Exit;
  end;

  if ID = 'RADIO TWO KEYER RTS' then
  begin
    Radio2.tr4w_keyer_rts_state := RtsDtr_Nothing;
    if CMD = 'CW' then Radio2.tr4w_keyer_rts_state := RtsDtr_CW;
    if CMD = 'PTT' then Radio2.tr4w_keyer_rts_state := RtsDtr_PTT;
    if CMD = 'ON' then Radio2.tr4w_keyer_rts_state := RtsDtr_ON;
    if CMD = 'OFF' then Radio2.tr4w_keyer_rts_state := RtsDtr_OFF;
    ProcessConfigInstructions2 := Radio2.tr4w_keyer_rts_state <> RtsDtr_Nothing;
    Exit;
  end;

  if ID = 'RADIO TWO KEYER DTR' then
  begin
    ProcessConfigInstructions2 := ProcessRadioDTR(CMD, @Radio2);
    Exit;
  end;
}
{
  if ID = 'RADIO TWO BAUD RATE' then
  begin
    Val(CMD, Radio2.RadioBaudRate, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;
}
  {
    if ID = 'RADIO ONE COMMAND PAUSE' then
      begin
        Val(CMD, Radio1.CommandPause, Result1);
        ProcessConfigInstructions2 := Result1 = 0;
        Exit;
      end;

    if ID = 'RADIO TWO COMMAND PAUSE' then
      begin
        Val(CMD, Radio2.CommandPause, Result1);
        ProcessConfigInstructions2 := Result1 = 0;
        Exit;
      end;
  }
{
  if ID = 'RADIO ONE CONTROL PORT' then
  begin
    ProcessConfigInstructions2 := ProcessRadioControlPort(CMD, @Radio1);
    Exit;
  end;
}
  {  begin
      Radio1.RadioSerialPort := NoPort;

      if StringHas(CMD, 'SERIAL 1') then Radio1.RadioSerialPort := Serial1;
      if StringHas(CMD, 'SERIAL 2') then Radio1.RadioSerialPort := Serial2;
      if StringHas(CMD, 'SERIAL 3') then Radio1.RadioSerialPort := Serial3;
      if StringHas(CMD, 'SERIAL 4') then Radio1.RadioSerialPort := Serial4;
      if StringHas(CMD, 'SERIAL 5') then Radio1.RadioSerialPort := Serial5;
      if StringHas(CMD, 'SERIAL 6') then Radio1.RadioSerialPort := Serial6;

      ProcessConfigInstructions2 := (Radio1.RadioSerialPort <> NoPort) or (CMD = 'NONE');
      Exit;
    end;
  }
{
  if ID = 'RADIO TWO CONTROL PORT' then
  begin
    ProcessConfigInstructions2 := ProcessRadioControlPort(CMD, @Radio2);
    Exit;
  end;
}
  {  begin
      Radio2.RadioSerialPort := NoPort;

      if StringHas(CMD, 'SERIAL 1') then Radio2.RadioSerialPort := Serial1;
      if StringHas(CMD, 'SERIAL 2') then Radio2.RadioSerialPort := Serial2;
      if StringHas(CMD, 'SERIAL 3') then Radio2.RadioSerialPort := Serial3;
      if StringHas(CMD, 'SERIAL 4') then Radio2.RadioSerialPort := Serial4;
      if StringHas(CMD, 'SERIAL 5') then Radio2.RadioSerialPort := Serial5;
      if StringHas(CMD, 'SERIAL 6') then Radio2.RadioSerialPort := Serial6;

      ProcessConfigInstructions2 := (Radio2.RadioSerialPort <> NoPort) or (CMD = 'NONE');
      Exit;
    end;
  }
//  if ID = 'RADIO ONE ID CHARACTER' then
//  begin
{
    TempChar := CHR(0);
    if CMD <> '' then if CMD[1] in ['A'..'Z'] then TempChar := CMD[1];
    if CMD = 'NONE' then TempChar := CHR(0);
    Radio1.IDCharacter := TempChar;
}
//    ProcessConfigInstructions2 := True;
//    Exit;
//  end;

//  if ID = 'RADIO TWO ID CHARACTER' then
//  begin
{
    TempChar := CHR(0);
    if CMD <> '' then if CMD[1] in ['A'..'Z'] then TempChar := CMD[1];
    if CMD = 'NONE' then TempChar := CHR(0);
    Radio2.IDCharacter := TempChar;
}
//    ProcessConfigInstructions2 := True;
//    Exit;
//  end;
{
  if ID = 'RADIO ONE NAME' then
  begin
      //WLI        WHILE Length (CMD) < 7 DO
      //WLI            CMD := ' ' + CMD;

      //WLI        GetRidOfPostcedingSpaces (CMD);

//    RadioOneName := CMD;
    Radio1.RadioName := CMD;
    ProcessConfigInstructions2 := True;
    Exit;
  end;

  if ID = 'RADIO TWO NAME' then
  begin
      //    while length(CMD) < 7 do      CMD := ' ' + CMD;

               //WLI        GetRidOfPostcedingSpaces (CMD);

//    RadioTwoName := CMD;
    Radio2.RadioName := CMD;
    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'RADIO ONE RECEIVER ADDRESS' then
  begin
    Val(CMD, Radio1.ReceiverAddress, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;

  if ID = 'RADIO TWO RECEIVER ADDRESS' then
  begin
    Val(CMD, Radio2.ReceiverAddress, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;
}
  {
    if ID = 'RADIO ONE TRACKING ENABLE' then
      begin
        Radio1.TrackingEnable := StackBool;
        ProcessConfigInstructions2 := True;
        Exit;
      end;

    if ID = 'RADIO TWO TRACKING ENABLE' then
      begin
        Radio2.TrackingEnable := StackBool;
        ProcessConfigInstructions2 := True;
        Exit;
      end;
  }
//  if ID = 'RADIO ONE TYPE' then    ProcessConfigInstructions2 := ProcessRadioType(CMD, @Radio1);
  begin
    {

        Radio1.RadioModel := NoInterfacedRadio;

        if pos(CMD, '-') > 0 then Delete(CMD, pos(CMD, '-'), 1);

             // No radios ending with A

        if Copy(CMD, length(CMD), 1) = 'A' then
          Delete(CMD, length(CMD), 1);

        if Copy(CMD, 1, 2) = 'JS' then
        begin
          Radio1.RadioModel := JST245;

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 0
          else
            Radio1.ControlDelay := 1;
        end;

        if Copy(CMD, 1, 2) = 'K2' then
        begin
                   //Radio1.RadioModel := K2;
          Radio1.RadioModel := TS850; //KK1L:6.73 missing "OR K2"s in TS850 statements in LOGSUBS2. Easier fix!

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 0
          else
            Radio1.ControlDelay := 1;
        end;

        if Copy(CMD, 1, 2) = 'TS' then
        begin

          Radio1.RadioModel := TS850;

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 0
          else
            Radio1.ControlDelay := 1;

        end;

        if Copy(CMD, 1, 3) = 'FT1' then
        begin
          if StringHas(CMD, 'MP') then
            Radio1.RadioModel := FT1000MP
          else
            Radio1.RadioModel := FT1000;

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 0
          else
            Radio1.ControlDelay := 1;
        end;

        if (CMD = 'FT840') or (CMD = 'FT890') or (CMD = 'FT900') then
        begin
          Radio1.RadioModel := FT890;

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 0
          else
            Radio1.ControlDelay := 1;
        end;

        if CMD = 'FT920' then
        begin
          Radio1.RadioModel := FT920;

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 0
          else
            Radio1.ControlDelay := 1;
        end;

        if CMD = 'FT100' then
        begin
          Radio1.RadioModel := FT100;

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 0
          else
            Radio1.ControlDelay := 1;
        end;

        if (CMD = 'FT817') or (CMD = 'FT897') then //KK1L: 6.73 Added FT897 support. Reports say FT817 works well for it.
        begin
          Radio1.RadioModel := FT817;

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 0
          else
            Radio1.ControlDelay := 1;
        end;

        if CMD = 'FT847' then
        begin
          Radio1.RadioModel := FT847;

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 0
          else
            Radio1.ControlDelay := 1;
        end;

        if CMD = 'FT990' then
        begin
          Radio1.RadioModel := FT990;

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 0
          else
            Radio1.ControlDelay := 1;
        end;

        if CMD = 'FTDX9000' then
        begin
          Radio1.RadioModel := FTDX9000;

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 0
          else
            Radio1.ControlDelay := 1;
        end;

        if Copy(CMD, 1, 2) = 'IC' then
        begin
          Radio1.RadioBaudRate := 1200;
          if CMD = 'IC706' then
          begin
            Radio1.RadioModel := IC706;
            Radio1.ReceiverAddress := $48;
          end;

          if CMD = 'IC706II' then
          begin
            Radio1.RadioModel := IC706II;
            Radio1.ReceiverAddress := $4E;
          end;

          if CMD = 'IC706IIG' then
          begin
            Radio1.RadioModel := IC706IIG;
            Radio1.ReceiverAddress := $58;
          end;

          if CMD = 'IC707' then
          begin
            Radio1.RadioModel := IC707;
            Radio1.ReceiverAddress := $3E;
          end;

          if CMD = 'IC725' then
          begin
            Radio1.RadioModel := IC725;
            Radio1.ReceiverAddress := $28;
          end;

          if CMD = 'IC726' then
          begin
            Radio1.RadioModel := IC726;
            Radio1.ReceiverAddress := $30;
          end;

          if CMD = 'IC728' then
          begin
            Radio1.RadioModel := IC728;
            Radio1.ReceiverAddress := $38;
          end;

          if CMD = 'IC729' then
          begin
            Radio1.RadioModel := IC729;
            Radio1.ReceiverAddress := $3A;
          end;

          if CMD = 'IC735' then
          begin
            Radio1.RadioModel := IC735;
            Radio1.ReceiverAddress := $04;
          end;

          if CMD = 'IC736' then
          begin
            Radio1.RadioModel := IC736;
            Radio1.ReceiverAddress := $40;
          end;

          if CMD = 'IC737' then
          begin
            Radio1.RadioModel := IC737;
            Radio1.ReceiverAddress := $3C;
          end;

          if CMD = 'IC738' then
          begin
            Radio1.RadioModel := IC738;
            Radio1.ReceiverAddress := $44;
          end;

          if CMD = 'IC746' then
          begin
            Radio1.RadioModel := IC746;
            Radio1.ReceiverAddress := $56;
          end;

          if CMD = 'IC746PRO' then
          begin
            Radio1.RadioModel := IC746PRO;
            Radio1.ReceiverAddress := $56;
          end;

          if CMD = 'IC756' then
          begin
            Radio1.RadioModel := IC756;
            Radio1.ReceiverAddress := $50;
          end;

          if CMD = 'IC756PRO' then
          begin
            Radio1.RadioModel := IC756PRO;
            Radio1.ReceiverAddress := $5C;
          end;

          if CMD = 'IC756PROII' then
          begin
            Radio1.RadioModel := IC756PROII;
            Radio1.ReceiverAddress := $64;
          end;

          if CMD = 'IC761' then
          begin
            Radio1.RadioModel := IC761;
            Radio1.ReceiverAddress := $1E;
          end;

          if CMD = 'IC765' then
          begin
            Radio1.RadioModel := IC765;
            Radio1.ReceiverAddress := $2C;
          end;

          if CMD = 'IC775' then
          begin
            Radio1.RadioModel := IC775;
            Radio1.ReceiverAddress := $46;
          end;

          if CMD = 'IC781' then
          begin
            Radio1.RadioModel := IC781;
            Radio1.ReceiverAddress := $26;
          end;

          if CPUKeyer.SlowInterrupts then
            Radio1.ControlDelay := 4
          else
            Radio1.ControlDelay := 8;
        end;

             //KK1L: 6.73 Added direct TenTec support

        if StringHas(CMD, 'OMNI') then
        begin
          Radio1.RadioModel := OMNI6;
          Radio1.ReceiverAddress := $04;
        end;

        if CMD = 'ORION' then
        begin
          Radio1.RadioModel := Orion;
          Radio1.RadioBaudRate := 57600;
        end;

        if CMD = 'ARGO' then
    //    if CMD = Radio_Type_Array[ord(argo)] then
        begin
          Radio1.RadioModel := ARGO;
          Radio1.ReceiverAddress := $04;
        end;

        ProcessConfigInstructions2 := (Radio1.RadioModel <> NoInterfacedRadio) or
          (CMD = 'NONE');
    }
  end;

//  if ID = 'RADIO TWO TYPE' then    ProcessConfigInstructions2 := ProcessRadioType(CMD, @Radio2);
  begin
    {    Radio2.RadioModel := NoInterfacedRadio;

        if pos(CMD, '-') > 0 then Delete(CMD, pos(CMD, '-'), 1);

             // No radios ending with A

        if Copy(CMD, length(CMD), 1) = 'A' then
          Delete(CMD, length(CMD), 1);

        if Copy(CMD, 1, 2) = 'JS' then
        begin
          Radio2.RadioModel := JST245;

          if CPUKeyer.SlowInterrupts then
            Radio2.ControlDelay := 0
          else
            Radio2.ControlDelay := 1;
        end;

        if Copy(CMD, 1, 2) = 'K2' then
        begin
                   //Radio2.RadioModel := K2;
          Radio2.RadioModel := TS850; //KK1L:6.73 missing "OR K2"s in TS850 statements in LOGSUBS2. Easier fix!

          if CPUKeyer.SlowInterrupts then
            Radio2.ControlDelay := 0
          else
            Radio2.ControlDelay := 1;
        end;

        if Copy(CMD, 1, 2) = 'TS' then
        begin
          Radio2.RadioModel := TS850;

          if CPUKeyer.SlowInterrupts then
            Radio2.ControlDelay := 0
          else
            Radio2.ControlDelay := 1;
        end;

        if Copy(CMD, 1, 3) = 'FT1' then
        begin
          if StringHas(CMD, 'MP') then
            Radio2.RadioModel := FT1000MP
          else
            Radio2.RadioModel := FT1000;

          if CPUKeyer.SlowInterrupts then
            Radio2.ControlDelay := 0
          else
            Radio2.ControlDelay := 1;
        end;

        if (CMD = 'FT840') or (CMD = 'FT890') or (CMD = 'FT900') then
        begin
          Radio2.RadioModel := FT890;

          if CPUKeyer.SlowInterrupts then
            Radio2.ControlDelay := 0
          else
            Radio2.ControlDelay := 1;
        end;

        if CMD = 'FT920' then
        begin
          Radio2.RadioModel := FT920;

          if CPUKeyer.SlowInterrupts then
            Radio2.ControlDelay := 0
          else
            Radio2.ControlDelay := 1;
        end;

        if (CMD = 'FT817') or (CMD = 'FT897') then //KK1L: 6.73 Added FT897 support. Reports say FT817 works well for it.
        begin
          Radio2.RadioModel := FT817;

          if CPUKeyer.SlowInterrupts then
            Radio2.ControlDelay := 0
          else
            Radio2.ControlDelay := 1;
        end;

        if CMD = 'FT847' then
        begin
          Radio2.RadioModel := FT847;

          if CPUKeyer.SlowInterrupts then
            Radio2.ControlDelay := 0
          else
            Radio2.ControlDelay := 1;
        end;

        if CMD = 'FT990' then
        begin
          Radio2.RadioModel := FT990;

          if CPUKeyer.SlowInterrupts then
            Radio2.ControlDelay := 0
          else
            Radio2.ControlDelay := 1;
        end;

        if Copy(CMD, 1, 2) = 'IC' then
        begin
          Radio2.RadioBaudRate := 1200;
          if CMD = 'IC706' then
          begin
            Radio2.RadioModel := IC706;
            Radio2.ReceiverAddress := $48;
          end;

          if CMD = 'IC706II' then
          begin
            Radio2.RadioModel := IC706II;
            Radio2.ReceiverAddress := $4E;
          end;

          if CMD = 'IC706IIG' then
          begin
            Radio2.RadioModel := IC706IIG;
            Radio2.ReceiverAddress := $58;
          end;

          if CMD = 'IC707' then
          begin
            Radio2.RadioModel := IC707;
            Radio2.ReceiverAddress := $3E;
          end;

          if CMD = 'IC725' then
          begin
            Radio2.RadioModel := IC725;
            Radio2.ReceiverAddress := $28;
          end;

          if CMD = 'IC726' then
          begin
            Radio2.RadioModel := IC726;
            Radio2.ReceiverAddress := $30;
          end;

          if CMD = 'IC728' then
          begin
            Radio2.RadioModel := IC728;
            Radio2.ReceiverAddress := $38;
          end;

          if CMD = 'IC729' then
          begin
            Radio2.RadioModel := IC729;
            Radio2.ReceiverAddress := $3A;
          end;

          if CMD = 'IC735' then
          begin
            Radio2.RadioModel := IC735;
            Radio2.ReceiverAddress := $04;
          end;

          if CMD = 'IC736' then
          begin
            Radio2.RadioModel := IC736;
            Radio2.ReceiverAddress := $40;
          end;

          if CMD = 'IC737' then
          begin
            Radio2.RadioModel := IC737;
            Radio2.ReceiverAddress := $3C;
          end;

          if CMD = 'IC738' then
          begin
            Radio2.RadioModel := IC738;
            Radio2.ReceiverAddress := $44;
          end;

          if CMD = 'IC746' then
          begin
            Radio2.RadioModel := IC746;
            Radio2.ReceiverAddress := $56;
          end;

          if CMD = 'IC746PRO' then
          begin
            Radio2.RadioModel := IC746PRO;
            Radio2.ReceiverAddress := $56;
          end;

          if CMD = 'IC756' then
          begin
            Radio2.RadioModel := IC756;
            Radio2.ReceiverAddress := $50;
          end;

          if CMD = 'IC756PRO' then
          begin
            Radio2.RadioModel := IC756PRO;
            Radio2.ReceiverAddress := $5C;
          end;

          if CMD = 'IC756PROII' then
          begin
            Radio2.RadioModel := IC756PROII;
            Radio2.ReceiverAddress := $64;
          end;

          if CMD = 'IC761' then
          begin
            Radio2.RadioModel := IC761;
            Radio2.ReceiverAddress := $1E;
          end;

          if CMD = 'IC765' then
          begin
            Radio2.RadioModel := IC765;
            Radio2.ReceiverAddress := $2C;
          end;

          if CMD = 'IC775' then
          begin
            Radio2.RadioModel := IC775;
            Radio2.ReceiverAddress := $46;
          end;

          if CMD = 'IC781' then
          begin
            Radio2.RadioModel := IC781;
            Radio2.ReceiverAddress := $26;
          end;

          if CPUKeyer.SlowInterrupts then
            Radio2.ControlDelay := 4
          else
            Radio2.ControlDelay := 8;
        end;

             //KK1L: 6.73 Added direct TenTec support

        if StringHas(CMD, 'OMNI') then
        begin
          Radio2.RadioModel := OMNI6;
          Radio2.ReceiverAddress := $04;
        end;

        if CMD = 'ORION' then
        begin
          Radio2.RadioModel := Orion;
          Radio2.RadioBaudRate := 57600;
        end;

        if CMD = 'ARGO' then
        begin
          Radio2.RadioModel := ARGO;
          Radio2.ReceiverAddress := $04;
        end;

        ProcessConfigInstructions2 := (Radio2.RadioModel <> NoInterfacedRadio) or
          (CMD = 'NONE');
    }
  end;
  {
    if ID = 'RADIO ONE UPDATE SECONDS' then
      begin
        Val(CMD, Radio1.UpdateSeconds, Result1);
        ProcessConfigInstructions2 := Result1 = 0;
        Exit;
      end;

    if ID = 'RADIO TWO UPDATE SECONDS' then
      begin
        Val(CMD, Radio2.UpdateSeconds, Result1);
        ProcessConfigInstructions2 := Result1 = 0;
        Exit;
      end;
  }
{
  if ID = 'RADIUS OF EARTH' then
  begin
    Val(CMD, RadiusOfEarth, Result1);
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;
}
{
  if ID = 'RANDOM CQ MODE' then
  begin
    RandomCQMode := StackBool;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'RATE DISPLAY' then
  begin
    if CMD = 'QSO POINTS' then RateDisplay := Points;

    if CMD = 'BAND QSOS' then RateDisplay := BandQSOs;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}
{
  if ID = 'RELAY CONTROL PORT' then
  begin
    RelayControlPort := GetLPTPortFromChar(CMD);
    ProcessConfigInstructions2 := (RelayControlPort <> NoPort) ;
    Exit;
  end;
}
{
  if ID = 'RECEIVER ADDRESS' then
  begin
    Val(CMD, Radio1.ReceiverAddress, Result1);
    Radio2.ReceiverAddress := Radio1.ReceiverAddress;
    ProcessConfigInstructions2 := Result1 = 0;
    Exit;
  end;
}

  if ID = 'REMAINING MULT DISPLAY MODE' then
  begin
    RemainingMultDisplayMode := NoRemainingMults;

    if CMD = 'ERASE' then RemainingMultDisplayMode := Erase;
    if CMD = 'HILIGHT' then RemainingMultDisplayMode := HiLight;

    ProcessConfigInstructions2 := (RemainingMultDisplayMode <> NoRemainingMults) or
      (CMD = 'NONE');

    Exit;
  end;
 

{
  if ID = 'REMINDER' then
  begin
    if NumberReminderRecords >= MaximumReminderRecords then
    begin
      ShowMessage(TC_MAXIMUMNUMBEROFREMINDERSEXCEEDED);
      Exit;
    end;

    if NumberReminderRecords = 0 then New(Reminders);

    Reminders^[NumberReminderRecords].DateString := '';
    Reminders^[NumberReminderRecords].DayString := '';
    Reminders^[NumberReminderRecords].Alarm := False;

    TimeString := Copy(CMD, 1, 4);

    if not StringIsAllNumbers(TimeString) then
    begin
      asm
          push TimeString
      end;
      wsprintf(wsprintfBuffer, '%s '#13 + TC_INVALIDREMINDERTIME);
      asm add esp,12
      end;
      ShowMessage(wsprintfBuffer);
          //      showmessage(TimeString + #13 + 'Invalid reminder time!!');
      Exit;
    end;

    Val(TimeString, Reminders^[NumberReminderRecords].Time, Result1);

    DateString := BracketedString(CMD, ' ON ', '');

    if StringHas(DateString, 'ALARM') then
    begin
      Reminders^[NumberReminderRecords].Alarm := True;
      DateString := BracketedString(DateString, '', ' ALARM');
    end;

      //WLI
              GetRidOfPostcedingSpaces (DateString);

    if StringHas(DateString, '-') then
    begin
      case length(DateString) of
        8:
          if (DateString[2] <> '-') or (DateString[6] <> '-') then
          begin
            ShowMessage(TC_INVALIDREMINDERDATE);
            Exit;
          end
          else
            DateString := '0' + DateString;

        9:
          if (DateString[3] <> '-') or (DateString[7] <> '-') then
          begin
            ShowMessage(TC_INVALIDREMINDERDATE);
            Exit;
          end;

      else
        ShowMessage(TC_INVALIDREMINDERDATE);
      end;
      Reminders^[NumberReminderRecords].DateString := DateString;
    end
    else
    begin
      DayString := Copy(DateString, length(DateString) - 2, 3);
      if (DayString <> 'DAY') and (DayString <> 'ALL') then
      begin
        ShowMessage(TC_INVALIDREMINDERDATE);
        Exit;
      end;

      Reminders^[NumberReminderRecords].DayString := DateString;
    end;

    ReadLn(ConfigFileRead, Reminders^[NumberReminderRecords].RemMessage);
    inc(NumberReminderRecords);
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
    Exit;
  end;
}

//  if ID = 'ROTATOR PORT' then
//  begin
//    ActiveRotatorPort := GetPortFromChar(CMD);
      {    ActiveRotatorPort := NoPort;

          if StringHas(CMD, 'SERIAL 1') then ActiveRotatorPort := Serial1;
          if StringHas(CMD, 'SERIAL 2') then ActiveRotatorPort := Serial2;
          if StringHas(CMD, 'SERIAL 3') then ActiveRotatorPort := Serial3;
          if StringHas(CMD, 'SERIAL 4') then ActiveRotatorPort := Serial4;
          if StringHas(CMD, 'SERIAL 5') then ActiveRotatorPort := Serial5;
          if StringHas(CMD, 'SERIAL 6') then ActiveRotatorPort := Serial6;
      }
//    ProcessConfigInstructions2 := (ActiveRotatorPort <> NoPort) {or (CMD = 'NONE')};
//    Exit;
//  end;
{
  if ID = 'ROTATOR TYPE' then
  begin
    ActiveRotatorType := NoRotator;

    if StringHas(CMD, 'DCU') then ActiveRotatorType := DCU1Rotator;
    if StringHas(CMD, 'ORI') then ActiveRotatorType := OrionRotator;
    if StringHas(CMD, 'YAE') then ActiveRotatorType := YaesuRotator; //KK1L: 6.71

    ProcessConfigInstructions2 := (ActiveRotatorType <> NoRotator) and (CMD <> 'NONE');
    Exit;
  end;
}
{
  if ID = 'RTTY RECEIVE STRING' then
  begin
      //    RTTYReceiveString := CMD;
    asm inc ebx
    end; //        ProcessConfigInstructions2 := True;
         //        SniffOutControlCharacters (RTTYReceiveString);
    Exit;
  end;

  if ID = 'RTTY SEND STRING' then
  begin
      //    RTTYSendString := CMD;
    asm inc ebx
    end; //    ProcessConfigInstructions2 := True;
      //        SniffOutControlCharacters (RTTYSendString);
    Exit;
  end;
}
//  if ID = 'STEREO CONTROL PORT' then {KK1L: 6.71}
//  begin
      {
          ActiveStereoPort := NoPort;

          if CMD = '1' then ActiveStereoPort := Parallel1;
          if CMD = '2' then ActiveStereoPort := Parallel2;
          if CMD = '3' then ActiveStereoPort := Parallel3;
      }
//    ActiveStereoPort := GetLPTPortFromChar(CMD);
//    ProcessConfigInstructions2 := (ActiveStereoPort <> NoPort) {or (CMD = 'NONE')};
//  end;
{
  if ID = 'USE CONTROL PORT' then
  begin
    tUseControlPort := StackBool;
    asm inc ebx
    end;
    Exit;
  end;
}
  {
    if ID = 'RTTY PORT' then
    begin
      ActiveRTTYPort := NoPort;

      if StringHas(CMD, 'SERIAL 1') then ActiveRTTYPort := Serial1;
      if StringHas(CMD, 'SERIAL 2') then ActiveRTTYPort := Serial2;
      if StringHas(CMD, 'SERIAL 3') then ActiveRTTYPort := Serial3;
      if StringHas(CMD, 'SERIAL 4') then ActiveRTTYPort := Serial4;
      if StringHas(CMD, 'SERIAL 5') then ActiveRTTYPort := Serial5;
      if StringHas(CMD, 'SERIAL 6') then ActiveRTTYPort := Serial6;

      ProcessConfigInstructions2 := (ActiveRTTYPort <> NoPort) or (CMD = 'NONE');
      Exit;
    end;
  }
end;

function ProcessConfigInstructions3(ID: Str80; CMD: ShortString): boolean;

begin
  ProcessConfigInstructions3 := False; //wli

  if CheckCommand(@ID, CMD) then
  begin
    ProcessConfigInstructions3 := True;
    Exit;
  end;





end;

function ProcessConfigInstruction(var FileString: ShortString; var FirstCommand: boolean): boolean;
var
  ID                                    : ShortString;
  CMD                                   : ShortString;
begin
  if FileString = '' then
  begin
    ProcessConfigInstruction := True;
    Exit;
  end;

  if FileString[1] in [';', '[' {, '_'}] then
  begin
    ProcessConfigInstruction := True;
    Exit;
  end;



  ProcessConfigInstruction := CheckCommand(@ID, CMD);

  if ID = '' then ProcessConfigInstruction := True;
end;

function ProcessRadioTypeold(CMD: ShortString; RadioPointer: RadioPtr): boolean;

begin
end;
function GetLPTPortFromChar(port: ShortString): PortType;
begin
  Result := NoPort;
  if PInteger(@port[1])^ = $454E4F4E {NONE} then Exit;
  if port[1] = '1' then Result := Parallel1;
  if port[1] = '2' then Result := Parallel2;
  if port[1] = '3' then Result := Parallel3;
end;

end.

