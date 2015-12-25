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
 }unit LogCW;

{$IMPORTEDDATA OFF}
interface

uses
utils_text,
  MMSystem,
  uWinKey,
  uMixW,
  uMMTTY,
  TF,
  VC,
  LogNet,
  LOGDVP, {SlowTree, }
  Sysutils,
  Tree,
  Windows,
  LogWind, {Dos,}
  LogRadio,
  LogK1EA
  ;

type
  KeyStatusType = (NormalKeys, AltKeys, ControlKeys);

type
  SendBufferType = array[0..255] of Char;

  MessagePointer = ^ShortString;
  CharPointer = ^Char;
  FunctionKeyMemoryArray = array[CW..Phone, F1..AltF12] of MessagePointer;

  CWMessageCommandType = (NoCWCommand,
    CWCommandControlEnter,
    CWCommandCQMode,
    CWCommandSAPMode,
    CWCommandQSY);

var
  CorrectedCallMessage                  : Str40; // = '} OK %';
  CQExchange                            : Str40;
  CQExchangeNameKnown                   : Str40;
  QSLMessage                            : Str40 { = 'TU \ TEST'};
  QSOBeforeMessage                      : Str40 { = ' SRI QSO B4 TU \ TEST'};
  QuickQSLMessage1                      : Str40 { = 'TU'};
  RepeatSearchAndPounceExchange         : Str40;
  SearchAndPounceExchange               : Str40;
  TailEndMessage                        : Str40 { = 'R'};

  CorrectedCallPhoneMessage             : ShortString {= 'CORCALL.WAV'};
  CQPhoneExchange                       : ShortString {= 'CQEXCHNG.WAV'};
  CQPhoneExchangeNameKnown              : ShortString {= 'CQEXNAME.WAV'};
  QSLPhoneMessage                       : ShortString {= 'QSL.WAV'};
  QSOBeforePhoneMessage                 : ShortString {= 'QSOB4.WAV'};
  QuickQSLPhoneMessage                  : ShortString {= 'QUICKQSL.WAV'};
  RepeatSearchAndPouncePhoneExchange    : ShortString {= 'RPTSPEX.WAV'};
  SearchAndPouncePhoneExchange          : ShortString {= 'SAPEXCHG.WAV'};
  TailEndPhoneMessage                   : ShortString {= 'TAILEND.WAV'};

  AutoCQDelayTime                       : integer = 3000;
  AutoCQMemory                          : Char = CHR(112);
  CWEnable                              : boolean = True;
  CWMessageCommand                      : CWMessageCommandType {= NoCWCommand};
  CWSpeedFromDataBase                   : boolean;
  CWTone                                : integer = 700;

  CQMemory                              : FunctionKeyMemoryArray;
  EXMemory                              : FunctionKeyMemoryArray;

  CQCaptionMemory                       : FunctionKeyMemoryArray;
  EXCaptionMemory                       : FunctionKeyMemoryArray;

  KeyerBeingUsed                        : KeyerType {= NoKeyer};
  KeyersSwapped                         : boolean;
  KeyPressedMemory                      : Char { = CHR(0)};

  LastRSTSent                           : Word;
  LeadingZeros                          : integer = 3;
  LeadingZeroCharacter                  : Char = 'T';

  NeedToSetCQMode                       : boolean; {KK1L: 6.69 This variable is used to leap around some AutoS&PMode code.}

  QuickQSLMessage2                      : Str40 { = 'EE'};

//  RadioOneKeyerOutputPort          : PortType = NoPort;
//  RadioTwoKeyerOutputPort          : PortType = NoPort;

  RememberCWSpeed                       : integer;

  //  RTTYTransmissionStarted          : boolean;

  SendingOnRadioOne                     : boolean; {KK1L: 6.72 Moved from local (IMPLIMENTATION section) for use in LOGSUBS}
  SendingOnRadioTwo                     : boolean; {KK1L: 6.72 Moved from local (IMPLIMENTATION section) for use in LOGSUBS}

  Short0                                : Char = 'T';
  Short1                                : Char = 'A';
  Short2                                : Char = '2';
  Short9                                : Char = 'N';

procedure AddStringToBuffer(Msg: Str160; Tone: integer);
procedure AppendConfigFile(AddedLine: Str160);

//procedure ClearPTTForceOn;
procedure CWInit;
function CWStillBeingSent: boolean;

function DeleteLastCharacter: boolean;
procedure DVKRecordMessage(MemoryString: Str20);

procedure FinishRTTYTransmission(Msg: Str160);
procedure FlushCWBuffer;
procedure FlushCWBufferAndClearPTT;

procedure InitializeKeyer;
procedure SendStringAndStop(Msg: Str160);
procedure SetSpeed(Speed: integer {byte});
procedure SetPTT;
procedure UnInitializeKeyer;

function GetCQMemoryString(Mode: ModeType; Key: Char): ShortString; {KK1L: 6.73 Added mode}
function GetEXMemoryString(Mode: ModeType; Key: Char): ShortString; {KK1L: 6.73 Added mode}

procedure MemoryProgram;

//procedure PTTForceOn;
function QSONumberString(QSONumber: integer): Str80;
function TimeString: Str10;

procedure SendKeyboardInput;
procedure SetCQMemoryString(Mode: ModeType; Key: Char; MemoryString: ShortString {Str80});
procedure SetEXMemoryString(Mode: ModeType; Key: Char; MemoryString: ShortString {Str80});

procedure SetCQCaptionMemoryString(Mode: ModeType; Key: Char; MemoryString: ShortString);
procedure SetEXCaptionMemoryString(Mode: ModeType; Key: Char; MemoryString: ShortString);

procedure SetNewCodeSpeed;
procedure SetUpToSendOnActiveRadio;
procedure SetUpToSendOnInactiveRadio;

procedure ToggleCW(DisplayPrompt: boolean);
procedure ShowOtherMemoryStatus;

procedure ShowCQFunctionKeyStatus;
procedure ShowExFunctionKeyStatus;
procedure DisplayCrypticCWMenu;
procedure DisplayCrypticSSBMenu;

var
  KeyStatus                             : KeyStatusType;
implementation

uses
  LogStuff,
  uTelnet,
  CFGCMD,
  uNet,
  MainUnit; {KK1L: 6.72 Allows use of SniffOutControlCharacters}

type
  SendData = record
    SendTime: integer; { Time in milliseconds }
    SendState: boolean; { True for key on }
  end;

  {SendingOnRadioOne: BOOLEAN; {KK1L: 6.72 Moved to global (INTERFACE section) for use in LOGSUBS}
  {SendingOnRadioTwo: BOOLEAN; {KK1L: 6.72 Moved to global (INTERFACE section) for use in LOGSUBS}

//   NEWCW                           : TCW;
{
procedure ClearPTTForceOn;
begin
  if CWEnable then CPUKeyer.PTTUnForce;
end;

procedure PTTForceOn;

begin
  if CWEnable and CWEnabled then CPUKeyer.PTTForceOn;
end;
}

procedure AddStringToBuffer(Msg: Str160; Tone: integer);
var
  i                                     : integer;
begin
{$IF MMTTYMODE}
  if ActiveMode = Digital then
  begin
//    SendMessageToMixW(Msg);
    if ActiveRadioPtr.tPTTStatus = PTT_OFF then
      if PTTEnable then
      begin
        PTTOn;
        PostMmttyMessage(RXM_PTT, RXM_PTT_SWITCH_TO_TX);
      end;

//    if MMTTY_FIRST_TX_CHAR then ProcessMMTTYMessage(TXM_CHAR, 13);
//    MMTTY_FIRST_TX_CHAR := False;
    for i := 1 to length(Msg) do
      PostMmttyMessage(RXM_CHAR, integer(Msg[i]));

    if not ControlAMode then
      PostMmttyMessage(RXM_PTT, RXM_PTT_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED);

    Exit;
  end;
{$IFEND}

  if CWEnable and CWEnabled then
  begin
{$IF OZCR2008}
    CWMessageToNetwork := CWMessageToNetwork + Msg;
{$IFEND}
    if wkActive then
    begin

      wkAddCWMessageToInternalBuffer(Msg);
//      wkBUSY := True;
      Exit;
    end;

    if ActiveRadioPtr.tPTTStatus = PTT_OFF then PTTOn;

    CPUKeyer.AddStringToCWBuffer(Msg, Tone);
//    CountsSinceLastCW := 0;

    if CWThreadID = 0 then
    begin
//      ExitFromCWThread := False;
//      inc(CWThreadCounter);
//      windows.SetWindowText(tr4whandle,inttopchar(CWThreadCounter));

      CWThreadHandle := tCreateThread(@CWThreadProc, CWThreadID);
//                       THREAD_PRIORITY_ABOVE_NORMAL
      asm

      //push THREAD_PRIORITY_ABOVE_NORMAL
      //push THREAD_PRIORITY_HIGHEST
      push THREAD_PRIORITY_TIME_CRITICAL
      push eax
      call SetThreadPriority
      end;

{$IF OZCR2008}
      if tMessagesExhangeEnable then SetTimer(tr4whandle, UPDATE_NET_CW_MESSAGE, 250, @SendMessageStatus);
{$IFEND}

    end;
  end;
end;

function CWStillBeingSent: boolean;
begin
  if wkActive then
  begin
    Result := wkBUSY;
    Exit;
  end;
  CWStillBeingSent := CPUKeyer.CWStillBeingSent;
end;

function DeleteLastCharacter: boolean;
begin
  if wkActive then
  begin
    wkSendByte(wkCMD_BACKSPACE);
    Exit;
  end;
  DeleteLastCharacter := CPUKeyer.DeleteLastCharacter;
end;

procedure FlushCWBuffer;

begin
//  CPUKeyer.PTTUnForce;
  tAutoSendMode := False;
  CPUKeyer.FlushCWBuffer;
//  if wkActive then wkClearBuffer;    // Gav    remove
end;

procedure FlushCWBufferAndClearPTT;

begin
  FlushCWBuffer;
  PTTOff;
end;

procedure FinishRTTYTransmission(Msg: Str160);

var
  CharPointer                           : integer;

begin
  {
    if (ActiveMode = Digital) and (ActiveRTTYPort <> NoPort) then
    begin
      while not CPUKeyer.SerialPortOutputBuffer[ActiveRTTYPort].FreeSpace >= length(Msg) + 1 do ;
 
      if length(Msg) > 0 then
        for CharPointer := 1 to length(Msg) do
          CPUKeyer.SerialPortOutputBuffer[ActiveRTTYPort].AddEntry(ord(Msg[CharPointer]));
 
      if length(RTTYReceiveString) > 0 then
        for CharPointer := 1 to length(RTTYReceiveString) do
          CPUKeyer.SerialPortOutputBuffer[ActiveRTTYPort].AddEntry(ord(RTTYReceiveString[CharPointer]));
 
    end;
 
    RTTYTransmissionStarted := False;
   }
end;

procedure SendStringAndStop(Msg: Str160);

var
  CharPointer                           : integer;

begin
  if ActiveMode = CW then
  begin
    if CWEnable and CWEnabled then
    begin
          //            CPUKeyer.AddStringToCWBuffer (MSG, CWTone);
      AddStringToBuffer(Msg, CWTone);
    end;
    Exit;
  end;

  if (ActiveMode = Digital) then
  begin
    SendMessageToMixW('<TX>' + Msg + '<RXANDCLEAR>');
      {
      PTTOn;
      PostMmttyMessage(RXM_PTT, $00000002);
      AddStringToBuffer(Msg, CWTone);
      PostMessage(MMTTYEXE_Handle, MSG_MMTTY, RXM_PTT, $00000001);
      }
  end;

  {
    if (ActiveMode = Digital) and (ActiveRTTYPort <> NoPort) then
    begin
      CPUKeyer.SerialPortOutputBuffer[ActiveRTTYPort].AddEntry(ord(CarriageReturn));
      CPUKeyer.SerialPortOutputBuffer[ActiveRTTYPort].AddEntry(ord(LineFeed));
 
      while not CPUKeyer.SerialPortOutputBuffer[ActiveRTTYPort].FreeSpace >= length(Msg) + 2 do ;
 
      if length(RTTYSendString) > 0 then
        for CharPointer := 1 to length(RTTYSendString) do
          CPUKeyer.SerialPortOutputBuffer[ActiveRTTYPort].AddEntry(ord(RTTYSendString[CharPointer]));
 
      for CharPointer := 1 to length(Msg) do
        CPUKeyer.SerialPortOutputBuffer[ActiveRTTYPort].AddEntry(ord(Msg[CharPointer]));
 
      if length(RTTYReceiveString) > 0 then
        for CharPointer := 1 to length(RTTYReceiveString) do
          CPUKeyer.SerialPortOutputBuffer[ActiveRTTYPort].AddEntry(ord(RTTYReceiveString[CharPointer]));
 
      CPUKeyer.SerialPortOutputBuffer[ActiveRTTYPort].AddEntry(ord(CarriageReturn));
      CPUKeyer.SerialPortOutputBuffer[ActiveRTTYPort].AddEntry(ord(LineFeed));
    end;
  }
end;

procedure SetSpeed(Speed: integer {byte});

begin
  DisplayedCodeSpeed := Speed;

  if Speed > 0 then
  begin
    CodeSpeed := Speed;
    CPUKeyer.SetSpeed(Speed);
    tSetPaddleElementLength;
    wkSetSpeed(Speed);
  end;
end;

procedure SetPTT;

begin
  if not CWEnabled then Exit; { Pretty weird looking code Tree! }
end;

procedure SetNewCodeSpeed;

{ This procedure will ask what code speed you want to use and set it }

var
  WPM                                   : integer;

begin
  WPM := QuickEditInteger(TC_WPMCODESPEED, 2);
  if WPM <> -1 then
  begin
    SetSpeed(WPM);
    DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
  end;
end;

procedure DisplayBuffer(Buffer: SendBufferType;
  BufferStart: integer;
  BufferEnd: integer);

var
  BufferAddress                         : integer;

begin
  //    ClrScr;

  if BufferStart = BufferEnd then
  begin
    Write('Buffer empty - type something to start sending or RETURN to stop');
    Exit;
  end;

  BufferAddress := BufferStart;

  while BufferAddress <> BufferEnd do
  begin
    Write(Buffer[BufferAddress]);
    inc(BufferAddress);
    if BufferAddress = 256 then BufferAddress := 0;
  end;
end;

procedure SendKeyboardInput;

{ This procedure will take input from the keyboard and send it until a
  return is pressed.                                                    }

var
  Key, ExtendedKey                      : Char;
  TimeMark                              : Cardinal {TimeRecord};
  Buffer                                : SendBufferType;
  BufferStart, BufferEnd                : integer;

begin
  BufferStart := 0;
  BufferEnd := 0;

  if not CWEnable then Exit;

  SetUpToSendOnActiveRadio;

  CWEnabled := True;
  DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};

//  CPUKeyer.PTTForceOn;

  //  SaveAndSetActiveWindow(QuickCommandWindow);
   //    ClrScr;
   //    Write ('Sending CW from the keyboard.  Use ENTER/Escape/F10 to exit.');

  repeat
    MarkTime(TimeMark);

    repeat
      //         if ActiveMultiPort <> NoPort then
      if ElaspedSec100(TimeMark) > 3000 then { 30 second timeout }
      begin
//        CPUKeyer.PTTUnForce;
        CPUKeyer.FlushCWBuffer;
          //          RemoveAndRestorePreviousWindow;
        Exit;
      end;

      UpdateTimeAndRateDisplays(True, False);

      if CPUKeyer.BufferEmpty then
        if BufferStart <> BufferEnd then
        begin
          CPUKeyer.AddCharacterToCWBuffer(Buffer[BufferStart]);
          inc(BufferStart);
          if BufferStart = 256 then BufferStart := 0;
          DisplayBuffer(Buffer, BufferStart, BufferEnd);
        end;

    until NewKeyPressed;
    Key := UpCase(NewReadKey);

    if Key >= ' ' then
    begin
        //            IF BufferStart = BufferEnd THEN ClrScr;
      Buffer[BufferEnd] := Key;
      inc(BufferEnd);
      if BufferEnd = 256 then BufferEnd := 0;
      Write(Key);
    end
    else
      case Key of
        CarriageReturn:
          begin
            while BufferStart <> BufferEnd do
            begin
              InactiveRigCallingCQ := False; // n4af 4.42.11
              CPUKeyer.AddCharacterToCWBuffer(Buffer[BufferStart]);
              inc(BufferStart);
              if BufferStart = 256 then BufferStart := 0;
            end;

//            CPUKeyer.PTTUnForce;
            //            RemoveAndRestorePreviousWindow;
            Exit;
          end;

        BackSpace:
          if BufferEnd <> BufferStart then
          begin
            dec(BufferEnd);
            if BufferEnd < 0 then BufferEnd := 255;
            DisplayBuffer(Buffer, BufferStart, BufferEnd);
          end;

        EscapeKey:
          begin
//            CPUKeyer.PTTUnForce;
            CPUKeyer.FlushCWBuffer;
            //            RemoveAndRestorePreviousWindow;
            Exit;
          end;

        NullKey:
          case NewReadKey of
            F10:
              begin
//                CPUKeyer.PTTUnForce;
                CPUKeyer.FlushCWBuffer;
                //                RemoveAndRestorePreviousWindow;
                Exit;
              end;

            PageUpKey:
              if CodeSpeed < 96 then
              begin
                SetSpeed(CodeSpeed + 3);
                DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
              end;

            PageDownKey:
              if CodeSpeed > 4 then
              begin
                SetSpeed(CodeSpeed - 3);
                DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
              end;

            DeleteKey:
              if BufferEnd <> BufferStart then
              begin
                dec(BufferEnd);
                if BufferEnd < 0 then BufferEnd := 255;
                DisplayBuffer(Buffer, BufferStart, BufferEnd);
              end;

          end;

      end;

  until False;
end;

function TimeString: Str10;
begin
  tGetSystemTime;
  Windows.ZeroMemory(@Result, SizeOf(Result));
  Format(@Result[1], '%.2hu%.2hu', UTC.wHour, UTC.wMinute);
  Result[0] := #4;
end;

function QSONumberString(QSONumber: integer): Str80;
var
  TempString                            : Str80;
begin
  Str(QSONumber, TempString);
  QSONumberString := TempString;
end;

procedure DisplayCrypticCWMenu;

begin
//  Windows.SetDlgItemText(MemProgHWND, 101, TC_CWMENU);

  {    GoToXY (1, Hi (WindMax) - 5);
      WriteLn ('# QSO number   % database name    ~ GM/GA/GE         : Enable keyboard CW');
      WriteLn ('[ RST prompt   ^ half space       ] repeat RST sent  @ Call window contents');
      WriteLn ('$ GM + name    | received name    \ My callsign       partial corrected call');
  //    WriteLn ('^F WPM+2  ^S WPM-2  + AR  < SK  = BT  ! SN  & AS     ) last QSO''s call');
  //    Write   ('To program control characters, press Control-P first then control character.');
     }
end;

procedure DisplayCrypticSSBMenu;

begin
  {
     if DVPEnable then
        Windows.SetDlgItemText(MemProgHWND, 101,
           'Alt-W = Write selected message to DVP'#13'Alt-R = Read selected message from DVP (headphones only)')
     else
        Windows.SetDlgItemText(MemProgHWND, 101,
           'You have not enabled your DVP or DVK.'#13'Set DVP ENABLE or DVK ENABLE to TRUE so you can program messages.')
  }
        {
           if DVPEnable then
              begin
                         GoToXY (1, Hi (WindMax) - 4);
                         WriteLn ('Alt-W = Write selected message to DVP');
                         WriteLn ('Alt-R = Read selected message from DVP (headphones only)');
                         Write   ('');
 
              end
           else
              if ActiveDVKPort <> NoPort then
                 begin
                                GoToXY (1, Hi (WindMax) - 4);
                                WriteLn ('Alt-W = Write selected message to DVK (DVP1 to DVP4 only');
                                WriteLn ('Alt-R = Play selected message from DVK (to transmitter)');
                                Write   ('');
                 end
              else
                 begin
                                GoToXY (1, Hi (WindMax) - 4);
                                WriteLn ('You have not enabled your DVP or DVK.');
                                WriteLn ('Set DVP ENABLE or DVK ENABLE to TRUE so you can program messages.');
                                Write   ('');
                 end;
                               }
end;

procedure ShowCQFunctionKeyStatus;

var
  Key                                   : Char;
  TempString                            : Str160;

begin
  //    GoToXY (1, 1);
//  Windows.SetDlgItemText(MemProgHWND, 102, TC_PRESSCQFUNCTIONKEYTOPROGRAM);
//  Windows.SetWindowText(MemProgHWND, TC_CQFUNCTIONKEYMEMORYSTATUS);
  case KeyStatus of
    NormalKeys:
      begin
        //            WriteLnCenter ('CQ FUNCTION KEY MEMORY STATUS');

        for Key := F1 to F12 do
        begin
          Str(Ord(Key) - Ord(F1) + 1, TempString);
          TempString := 'F' + TempString + ' - ';

          if (ActiveMode = CW) or (ActiveMode = Digital) then
          begin
            if GetCQMemoryString(CW, Key) <> '' then {KK1L: 6.73 Added Mode}
              TempString := TempString + GetCQMemoryString(CW, Key); {KK1L: 6.73 Added Mode}

          end
          else
            if GetCQMemoryString(Phone, Key) <> '' then
              TempString := TempString {+ DVPPath} + GetCQMemoryString(Phone, Key); {KK1L: 6.73 Added Mode}

          if length(TempString) > 79 then
            TempString := Copy(TempString, 1, 78) + '+';
//          Windows.SetWindowText(MessagesValues[Ord(Key)], PChar(string(TempString)));
            //                ClrEol;
            //                WriteLn (TempString);
        end;
      end;

    AltKeys:
      begin
        //            WriteLnCenter ('ALT-CQ FUNCTION KEY MEMORY STATUS');

        for Key := AltF1 to AltF12 do
        begin
          Str(Ord(Key) - Ord(AltF1) + 1, TempString);
          TempString := 'Alt-F' + TempString + ' - ';

          if GetCQMemoryString(ActiveMode, Key) <> '' then {KK1L: 6.73 Added Mode}
            TempString := TempString + GetCQMemoryString(ActiveMode, Key); {KK1L: 6.73 Added Mode}

          if length(TempString) > 79 then
            TempString := Copy(TempString, 1, 78) + '+';
//          Windows.SetWindowText(MessagesValues[Ord(Key) - 24], PChar(string(TempString)));
            //                ClrEol;
            //                WriteLn (TempString);
        end;
      end;

    ControlKeys:
      begin
        //            WriteLnCenter ('CONTROL-CQ FUNCTION KEY MEMORY STATUS');

        for Key := ControlF1 to ControlF12 do
        begin
          Str(Ord(Key) - Ord(ControlF1) + 1, TempString);
          TempString := 'Ctrl-F' + TempString + ' - ';

          if GetCQMemoryString(ActiveMode, Key) <> '' then {KK1L: 6.73 Added mode}
            TempString := TempString + GetCQMemoryString(ActiveMode, Key); {KK1L: 6.73 Added mode}

          if length(TempString) > 79 then
            TempString := Copy(TempString, 1, 78) + '+';
//          Windows.SetWindowText(MessagesValues[Ord(Key) - 12], PChar(string(TempString)));
            //                ClrEol;
            //                WriteLn (TempString);
        end;
      end;
  end;
end;

procedure ShowExFunctionKeyStatus;

var
  Key                                   : Char;
  TempString                            : Str160;

begin
  //    GoToXY (1, 1);
//  Windows.SetDlgItemText(MemProgHWND, 102, TC_PRESSEXFUNCTIONKEYTOPROGRAM);
//  Windows.SetWindowText(MemProgHWND, TC_EXCHANGEFUNCTIONKEYMEMORYSTATUS);
  case KeyStatus of
    NormalKeys:
      begin
        //            WriteLnCenter ('EXCHANGE FUNCTION KEY MEMORY STATUS');

        if ActiveMode = CW then
        begin
//          Windows.SetWindowText(MessagesValues[VK_F1], 'F1 - Set by the MY CALL statement in config file' {TC_F1SETBYTHEMYCALLSTATEMENTINCONFIG});
//          Windows.SetWindowText(MessagesValues[VK_F2], 'F2 - Set by S&P EXCHANGE and REPEAT S&P EXCHANGE' {TC_F2SETBYSPEXCHANGEANDREPEATSP});
            //                  WriteLn('F1 - Set by the MY CALL statement in config file');
            //                  WriteLn('F2 - Set by S&P EXCHANGE and REPEAT S&P EXCHANGE');

          for Key := F3 to F12 do
          begin
            Str(Ord(Key) - Ord(F1) + 1, TempString);
            TempString := 'F' + TempString + ' - ';

                {KK1L: 6.73 Added mode to GetExMemoryString}
            if GetEXMemoryString(ActiveMode, Key) <> '' then
              TempString := TempString + GetEXMemoryString(ActiveMode, Key);

            if length(TempString) > 79 then
              TempString := Copy(TempString, 1, 78) + '+';
//            Windows.SetWindowText(MessagesValues[Ord(Key)], PChar(string(TempString)));
                //                    ClrEol;
                //                    WriteLn (TempString);
          end;
        end
        else
          for Key := F1 to F12 do
          begin
            Str(Ord(Key) - Ord(F1) + 1, TempString);
            TempString := 'F' + TempString + ' - ';

              {KK1L: 6.73 Added mode to GetExMemoryString}
            if GetEXMemoryString(ActiveMode, Key) <> '' then
              TempString := TempString {+ DVPPath} + GetEXMemoryString(ActiveMode, Key);

            if length(TempString) > 79 then
              TempString := Copy(TempString, 1, 78) + '+';
//            Windows.SetWindowText(MessagesValues[Ord(Key)], PChar(string(TempString)));
              //                    ClrEol;
              //                    WriteLn (TempString);
          end;
      end;

    AltKeys:
      begin
        //            WriteLnCenter ('ALT-EXCHANGE FUNCTION KEY MEMORY STATUS');

        for Key := AltF1 to AltF12 do
        begin
          Str(Ord(Key) - Ord(AltF1) + 1, TempString);
          TempString := 'Alt-F' + TempString + ' - ';

            {KK1L: 6.73 Added mode to GetExMemoryString}
          if GetEXMemoryString(ActiveMode, Key) <> '' then
            TempString := TempString + GetEXMemoryString(ActiveMode, Key);

          if length(TempString) > 79 then
            TempString := Copy(TempString, 1, 78) + '+';
            //                 ClrEol;
            //                WriteLn (TempString);
        end;
      end;

    ControlKeys:
      begin
        //            WriteLnCenter ('CONTROL-EXCHANGE FUNCTION KEY MEMORY STATUS');

        for Key := ControlF1 to ControlF12 do
        begin
          Str(Ord(Key) - Ord(ControlF1) + 1, TempString);
          TempString := 'Ctrl-F' + TempString + ' - ';

            {KK1L: 6.73 Added mode to GetExMemoryString}
          if GetEXMemoryString(ActiveMode, Key) <> '' then
            TempString := TempString + GetEXMemoryString(ActiveMode, Key);

          if length(TempString) > 79 then
            TempString := Copy(TempString, 1, 78) + '+';
            //    ClrEol;
             //  WriteLn (TempString);
        end;
      end;
  end;
end;

procedure ShowOtherMemoryStatus;

var
  TempString                            : Str160;

begin
//  Windows.SetDlgItemText(MemProgHWND, 102, TC_NUMBERORLETTEROFMESSAGETOBEPROGRAM);

  if (ActiveMode = CW) or (ActiveMode = Digital) then
  begin
      //         GoToXY(1, 1);
      //         WriteLnCenter('OTHER CW MESSAGE MEMORY STATUS');

//    Windows.SetWindowText(MemProgHWND, TC_OTHERCWMESSAGEMEMORYSTATUS);

      //         ClrEol;
//         TempString := ' 1. Call Okay Now - ' + CorrectedCallMessage;
//         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
//         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[112], PChar(string('Call Okay Now - ' + CorrectedCallMessage)));
      //         ClrEol;
      //         TempString := ' 2. CQ Exchange   - ' + CQExchange;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[113], PChar(string('CQ Exchange   - ' + CQExchange)));

      //         ClrEol;
      //         TempString := ' 3. CQ Ex Name    - ' + CQExchangeNameKnown;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[114], PChar(string('CQ Ex Name    - ' + CQExchangeNameKnown)));

      //         ClrEol;
      //         TempString := ' 4. QSL Message   - ' + QSLMessage;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[115], PChar(string('QSL Message   - ' + QSLMessage)));
      //         ClrEol;
      //         TempString := ' 5. QSO Before    - ' + QSOBeforeMessage;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[116], PChar(string('QSO Before    - ' + QSOBeforeMessage)));

      //         ClrEol;
      //         TempString := ' 6. Quick QSL     - ' + QuickQSLMessage1;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[117], PChar(string('Quick QSL     - ' + QuickQSLMessage1)));

      //         ClrEol;
      //         TempString := ' 7. Repeat S&P Ex - ' + RepeatSearchAndPounceExchange;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[118], PChar(string('Repeat S&P Ex - ' + RepeatSearchAndPounceExchange)));

      //         ClrEol;
      //         TempString := ' 8. S&P Exchange  - ' + SearchAndPounceExchange;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[119], PChar(string('S&P Exchange  - ' + SearchAndPounceExchange)));

      //         ClrEol;
      //         TempString := ' 9. Tail end msg  - ' + TailEndMessage;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[120], PChar(string('Tail end msg  - ' + TailEndMessage)));

//    Windows.SetWindowText(MessagesValues[121], PChar(string('Short 0       - ' + Short0)));
//    Windows.SetWindowText(MessagesValues[122], PChar(string('Short 1       - ' + Short1)));
//    Windows.SetWindowText(MessagesValues[123], PChar(string('Short 9       - ' + Short9)));

      //         ClrEol;
      //         Write('A. Short 0 = ', Short0, '   ',
      //            'B. Short 1 = ', Short1, '   ',
      //            'C. Short 2 = ', Short2, '   ',
      //            'D. Short 9 = ', Short9);
  end
  else
  begin
      //         GoToXY(1, 1);
      //         WriteLnCenter('OTHER SSB MESSAGE MEMORY STATUS');
//    Windows.SetWindowText(MemProgHWND, TC_OTHERSSBMESSAGEMEMORYSTATUS);
      //         ClrEol;
      //         TempString := ' 1. Call Okay Now - ' + DVPPath + CorrectedCallPhoneMessage;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[112], PChar(string('Call Okay Now - ' + CorrectedCallPhoneMessage)));

      //         ClrEol;
      //         TempString := ' 2. CQ Exchange   - ' + DVPPath + CQPhoneExchange;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[113], PChar(string('CQ Exchange   - ' + CQPhoneExchange)));
      //         ClrEol;
      //         TempString := ' 3. CQ Ex Name    - ' + DVPPath + CQPhoneExchangeNameKnown;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[114], PChar(string('CQ Ex Name    - ' + CQPhoneExchangeNameKnown)));
      //         ClrEol;
      //         TempString := ' 4. QSL Message   - ' + DVPPath + QSLPhoneMessage;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[115], PChar(string('QSL Message   - ' + QSLPhoneMessage)));
      //         ClrEol;
      //         TempString := ' 5. QSO Before    - ' + DVPPath + QSOBeforePhoneMessage;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[116], PChar(string('QSO Before    - ' + QSOBeforePhoneMessage)));
      //         ClrEol;
      //         TempString := ' 6. Quick QSL     - ' + DVPPath + QuickQSLPhoneMessage;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[117], PChar(string('Quick QSL     - ' + QuickQSLPhoneMessage)));
      //         ClrEol;
      //         TempString := ' 7. Repeat S&P Ex - ' + DVPPath + RepeatSearchAndPouncePhoneExchange;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[118], PChar(string('Repeat S&P Ex - ' + RepeatSearchAndPouncePhoneExchange)));
      //         ClrEol;
      //         TempString := ' 8. S&P Exchange  - ' + DVPPath + SearchAndPouncePhoneExchange;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[119], PChar(string('S&P Exchange  - ' + SearchAndPouncePhoneExchange)));
      //         ClrEol;
      //         TempString := ' 9. Tail end msg  - ' + DVPPath + TailEndPhoneMessage;
      //         if length(TempString) > 79 then TempString := Copy(TempString, 1, 78) + '+';
      //         WriteLn(TempString);
//    Windows.SetWindowText(MessagesValues[120], PChar(string('Tail end msg  - ' + TailEndPhoneMessage)));
      //         ClrEol;
  end;
end;

procedure AppendConfigFile(AddedLine: Str160);

var
  FileWrite                             : Text;

begin
{
  if OpenFileForAppend(FileWrite, LogConfigFileName) then
  begin
    WriteLn(FileWrite);
    WriteLn(FileWrite, AddedLine);
    Close(FileWrite);
  end;
}
end;

procedure DVKLIstenMessage(MemoryString: Str20);

begin
  DVPOn := True;

  MemoryString := UpperCase(MemoryString);
  if MemoryString = 'DVK1' then StartDVK(1);
  if MemoryString = 'DVK2' then StartDVK(2);
  if MemoryString = 'DVK3' then StartDVK(3);
  if MemoryString = 'DVK4' then StartDVK(4);
  if MemoryString = 'DVK5' then StartDVK(5); {KK1L: 6.71}
  if MemoryString = 'DVK6' then StartDVK(6); {KK1L: 6.71}
  {IF MemoryString = 'DVK7' THEN StartDVK (7); {KK1L: 6.71}{KK1L: 6.72 removed}
end;

procedure DVKRecordMessage(MemoryString: Str20);

begin
  DVPOn := True;

  MemoryString := UpperCase(MemoryString);

  if Copy(MemoryString, 1, 3) <> 'DVK' then Exit;

  DVKEnableWrite;

  if MemoryString = 'DVK1' then StartDVK(1);
  if MemoryString = 'DVK2' then StartDVK(2);
  if MemoryString = 'DVK3' then StartDVK(3);
  if MemoryString = 'DVK4' then StartDVK(4);
  if MemoryString = 'DVK5' then StartDVK(5); {KK1L: 6.71}
  if MemoryString = 'DVK6' then StartDVK(6); {KK1L: 6.71}
  {IF MemoryString = 'DVK7' THEN StartDVK (7); {KK1L: 6.71}{KK1L: 6.72 removed}

 //    REPEAT UNTIL KeyPressed;

  DVKDisableWrite;

  //    IF ReadKey = NullKey THEN ReadKey;
end;

procedure MemoryProgram;

var
  Key, FirstExchangeFunctionKey, FunctionKey: Char;
  TempString                            : Str160;
  TimeMark                              : Cardinal {TimeRecord};

begin
  case ActiveMode of
    Phone: FirstExchangeFunctionKey := F1;
    CW, Digital: FirstExchangeFunctionKey := F3;
  end;

  //  RemoveWindow(QuickCommandWindow);
  //  SaveSetAndClearActiveWindow(EditableLogWindow);

   {    WriteLnCenter ('MEMORY PROGRAM FUNCTION');
       WriteLn ('Press C to program a CQ function key.');
       WriteLn ('Press E to program an exchange/search and pounce function key.');
       WriteLn ('Press O to program the other non function key messages.');
       Write   ('Press ESCAPE to abort.');
   }
  MarkTime(TimeMark);

  repeat
    repeat until NewKeyPressed;
    Key := UpCase(NewReadKey);

    //      if ActiveMultiPort <> NoPort then
    if ElaspedSec100(TimeMark) > 3000 then
    begin
        //        RemoveAndRestorePreviousWindow;
      Exit;
    end;

  until (Key = 'C') or (Key = 'E') or (Key = 'O') or (Key = EscapeKey);

  //  RemoveAndRestorePreviousWindow;

  if Key = EscapeKey then Exit;

  //  RemoveWindow(TotalWindow);
  //  SaveSetAndClearActiveWindow(BigWindow);

  if (ActiveMode = CW) or (ActiveMode = Digital) then
    DisplayCrypticCWMenu
  else
    DisplayCrypticSSBMenu;

  VisibleDupeSheetRemoved := True;

  KeyStatus := NormalKeys;

  case Key of
    'C': repeat
        ShowCQFunctionKeyStatus;
        {                 GoToXY (1, Hi (WindMax));
                         Write (' Press CQ function key to program (F1, AltF1, CtrlF1), or ESCAPE to exit) : '); //KK1L: 6.72 changed
        }
        MarkTime(TimeMark);

        repeat
          repeat
            //                  if ActiveMultiPort <> NoPort then
            if ElaspedSec100(TimeMark) > 3000 then
            begin
                //                RemoveAndRestorePreviousWindow;
              Exit;
            end;

          until NewKeyPressed;
          FunctionKey := UpCase(NewReadKey);

        until (FunctionKey = NullKey) or (FunctionKey = EscapeKey);

        if FunctionKey = EscapeKey then
        begin
            //          RemoveAndRestorePreviousWindow;
          Exit;
        end;

        FunctionKey := NewReadKey;

        if ((FunctionKey >= F1) and (FunctionKey <= F10)) or
          ((FunctionKey >= ControlF1) and (FunctionKey <= ControlF10)) or
          ((FunctionKey >= AltF1) and (FunctionKey <= AltF10)) or
          ((FunctionKey >= F11) and (FunctionKey <= AltF12)) then
        begin
          if FunctionKey >= AltF1 then
          begin
            if KeyStatus <> AltKeys then
            begin
              KeyStatus := AltKeys;
              ShowCQFunctionKeyStatus;
            end;
          end
          else
            if FunctionKey >= ControlF1 then
            begin
              if KeyStatus <> ControlKeys then
              begin
                KeyStatus := ControlKeys;
                ShowCQFunctionKeyStatus;
              end;
            end
            else
              if KeyStatus <> NormalKeys then
              begin
                KeyStatus := NormalKeys;
                ShowCQFunctionKeyStatus;
              end;

            //                            SaveSetAndClearActiveWindow(QuickCommandWindow);

          repeat
            TempString := LineInput('Msg = ',
              GetCQMemoryString(ActiveMode, FunctionKey), {KK1L: 6.73 Added mode}
              True,
              (ActiveMode = Phone) and (DVKEnable or (ActiveDVKPort <> NoPort)));

            if TempString[1] = NullKey then
              if DVKEnable then
              begin
                    //                case TempString[2] of
                               {KK1L: 6.73 Added mode}
                    //                  AltW: DVPRecordMessage(GetCQMemoryString(ActiveMode, FunctionKey), False);
                               {KK1L: 6.73 Added mode}
                    //                  AltR: DVPListenMessage(GetCQMemoryString(ActiveMode, FunctionKey), true);
                    //                end;
              end
              else
              begin
                if ActiveDVKPort <> NoPort then
                      //                  case TempString[2] of
                                  {KK1L: 6.73 Added mode}
                      //                    AltW: DVKRecordMessage(GetCQMemoryString(ActiveMode, FunctionKey));
                                  {KK1L: 6.73 Added mode}
                      //                    AltR: DVKListenMessage(GetCQMemoryString(ActiveMode, FunctionKey));
              end;
              //              end;

          until (TempString[1] <> NullKey);

          if (TempString <> EscapeKey) and
              {KK1L: 6.73 Added mode}
          (GetCQMemoryString(ActiveMode, FunctionKey) <> TempString) then
          begin
            SetCQMemoryString(ActiveMode, FunctionKey, TempString);

            if ActiveMode = Phone then
              AppendConfigFile('CQ SSB MEMORY ' + KeyId(FunctionKey) + ' = ' + TempString)
            else
              AppendConfigFile('CQ MEMORY ' + KeyId(FunctionKey) + ' = ' + TempString);
          end;

            //          RemoveAndRestorePreviousWindow;
        end;
      until False;

    'E': repeat
        ShowExFunctionKeyStatus;
        //                 GoToXY (1, Hi (WindMax));
        //                 Write (' Press ex function key to program (F3-F12, Alt/Ctrl F1-F12) or ESCAPE to exit :');
                         {KK1L: 6.72 changed above line}

        MarkTime(TimeMark);

        repeat
          repeat
            //                  if ActiveMultiPort <> NoPort then
            if ElaspedSec100(TimeMark) > 3000 then
            begin
                //                RemoveAndRestorePreviousWindow;
              Exit;
            end;

          until NewKeyPressed;
          FunctionKey := UpCase(NewReadKey);
        until (FunctionKey = NullKey) or (FunctionKey = EscapeKey);

        if FunctionKey = EscapeKey then
        begin
            //          RemoveAndRestorePreviousWindow;
          Exit;
        end;

        FunctionKey := NewReadKey;

        if ((FunctionKey >= FirstExchangeFunctionKey) and (FunctionKey <= F10)) or
          ((FunctionKey >= ControlF1) and (FunctionKey <= ControlF10)) or
          ((FunctionKey >= AltF1) and (FunctionKey <= AltF10)) or
          ((FunctionKey >= F11) and (FunctionKey <= AltF12)) then
        begin
          if FunctionKey >= AltF1 then
          begin
            if KeyStatus <> AltKeys then
            begin
              KeyStatus := AltKeys;
              ShowExFunctionKeyStatus;
            end;
          end
          else
            if FunctionKey >= ControlF1 then
            begin
              if KeyStatus <> ControlKeys then
              begin
                KeyStatus := ControlKeys;
                ShowExFunctionKeyStatus;
              end;
            end
            else
              if KeyStatus <> NormalKeys then
              begin
                KeyStatus := NormalKeys;
                ShowExFunctionKeyStatus;
              end;

            //          SaveSetAndClearActiveWindow(QuickCommandWindow);

          repeat
            TempString := LineInput('Msg = ',
                {KK1L: 6.73 Added mode to GetExMemoryString}
              GetEXMemoryString(ActiveMode, FunctionKey),
              True,
              (ActiveMode = Phone) and (DVKEnable or (ActiveDVKPort <> NoPort)));

            if TempString[1] = NullKey then
              if DVKEnable then
              begin
                    //                case TempString[2] of
                               {KK1L: 6.73 Added mode to GetExMemoryString}
                    //                  AltW: DVPRecordMessage(GetEXMemoryString(ActiveMode, FunctionKey), False);
                    //                  AltR: DVPListenMessage(GetEXMemoryString(ActiveMode, FunctionKey), true);
                    //                end;
              end
              else
                  //               if ActiveDVKPort <> NoPort then
                 //                  case TempString[2] of
                            {KK1L: 6.73 Added mode to GetExMemoryString}
                 //                    AltW: DVKRecordMessage(GetEXMemoryString(ActiveMode, FunctionKey));
                 //                    AltR: DVKListenMessage(GetEXMemoryString(ActiveMode, FunctionKey));
                 //                  end;

          until (TempString[1] <> NullKey);

          if TempString <> EscapeKey then
          begin
            SetEXMemoryString(ActiveMode, FunctionKey, TempString);

            if ActiveMode = Phone then
              AppendConfigFile('EX SSB MEMORY ' + KeyId(FunctionKey) + ' = ' + TempString)
            else
              AppendConfigFile('EX MEMORY ' + KeyId(FunctionKey) + ' = ' + TempString)
          end;

            //          RemoveAndRestorePreviousWindow;
        end;
      until False;

    'O': repeat
        //            ShowOtherMemoryStatus;
                    //                 GoToXY (1, Hi (WindMax));

                    //                 Write ('Number or letter of message to be programmed (1-9, A-D, or ESCAPE to exit) : ');

        MarkTime(TimeMark);

        repeat
          repeat
            //                  if ActiveMultiPort <> NoPort then
            if ElaspedSec100(TimeMark) > 3000 then
            begin
                //                RemoveAndRestorePreviousWindow;
              Exit;
            end;

          until NewKeyPressed;
          //                     FunctionKey := Upcase (ReadKey);
        until ((FunctionKey >= '1') and (FunctionKey <= '9')) or
          ((FunctionKey >= 'A') and (FunctionKey <= 'D')) or
          (FunctionKey = EscapeKey);

        if FunctionKey = EscapeKey then
        begin
            //          RemoveAndRestorePreviousWindow;
          Exit;
        end;

        //        SaveSetAndClearActiveWindow(QuickCommandWindow);

        case FunctionKey of
          '1':
            begin
              if ActiveMode <> Phone then
              begin
                TempString := LineInput('Msg = ',
                  CorrectedCallMessage,
                  True,
                  False);

                if TempString <> EscapeKey then
                begin
                  CorrectedCallMessage := TempString;
                  AppendConfigFile('CALL OK NOW MESSAGE = ' + TempString);
                end;
              end
              else
              begin
                repeat
                  TempString := LineInput('Msg = ',
                    CorrectedCallPhoneMessage,
                    True,
                    True);

                  if TempString[1] = NullKey then
                    if DVKEnable then
                    begin
                          {                      case TempString[2] of
                                                  AltW: DVPRecordMessage(CorrectedCallPhoneMessage, False);
                                                  AltR: DVPListenMessage(CorrectedCallPhoneMessage, true);
                                                end;
                                              }
                    end
                    else
                        //                    if ActiveDVKPort <> NoPort then
                      //                        case TempString[2] of
                      //                          AltW: DVKRecordMessage(CorrectedCallPhoneMessage);
                      //                          AltR: DVKListenMessage(CorrectedCallPhoneMessage);
                      //                        end;

                until (TempString[1] <> NullKey);

                if TempString <> EscapeKey then
                begin
                  CorrectedCallPhoneMessage := TempString;
                  AppendConfigFile('CALL OK NOW SSB MESSAGE = ' + TempString);
                end;
              end;
            end;

          '2':
            begin
              if ActiveMode <> Phone then
              begin
                TempString := LineInput('Msg = ', CQExchange, True, False);
                if TempString <> EscapeKey then
                begin
                  CQExchange := TempString;
                  AppendConfigFile('CQ EXCHANGE = ' + TempString);
                end;
              end
              else
              begin
                repeat
                  TempString := LineInput('Msg = ',
                    CQPhoneExchange,
                    True,
                    True);

                  if TempString[1] = NullKey then
                    if DVKEnable then
                    begin
                      case TempString[2] of
                        AltW: DVPRecordMessage(CQPhoneExchange, False);
                        AltR: DVPListenMessage(CQPhoneExchange, True);
                      end;
                    end
                    else
                      if ActiveDVKPort <> NoPort then
                        case TempString[2] of
                          AltW: DVKRecordMessage(CQPhoneExchange);
                          AltR: DVKLIstenMessage(CQPhoneExchange);
                        end;

                until (TempString[1] <> NullKey);

                if TempString <> EscapeKey then
                begin
                  CQPhoneExchange := TempString;
                  AppendConfigFile('CQ SSB EXCHANGE = ' + TempString);
                end;
              end;
            end;

          '3':
            begin
              if ActiveMode <> Phone then
              begin
                TempString := LineInput('Msg = ', CQExchangeNameKnown, True, False);
                if TempString <> EscapeKey then
                begin
                  CQExchangeNameKnown := TempString;
                  AppendConfigFile('CQ EXCHANGE NAME KNOWN = ' + TempString);
                end;
              end
              else
              begin
                repeat
                  TempString := LineInput('Msg = ',
                    CQPhoneExchangeNameKnown,
                    True,
                    True);

                  if TempString[1] = NullKey then
                    if DVKEnable then
                    begin
                      case TempString[2] of
                        AltW: DVPRecordMessage(CQPhoneExchangeNameKnown, False);
                        AltR: DVPListenMessage(CQPhoneExchangeNameKnown, True);
                      end;
                    end
                    else
                      if ActiveDVKPort <> NoPort then
                        case TempString[2] of
                          AltW: DVKRecordMessage(CQPhoneExchangeNameKnown);
                          AltR: DVKLIstenMessage(CQPhoneExchangeNameKnown);
                        end;
                until (TempString[1] <> NullKey);

                if TempString <> EscapeKey then
                begin
                  CQPhoneExchangeNameKnown := TempString;
                  AppendConfigFile('CQ SSB EXCHANGE NAME KNOWN = ' + TempString);
                end;
              end;
            end;

          '4':
            begin
              if ActiveMode <> Phone then
              begin
                TempString := LineInput('Msg = ', QSLMessage, True, False);
                if TempString <> EscapeKey then
                begin
                  QSLMessage := TempString;
                  AppendConfigFile('QSL MESSAGE = ' + TempString);
                end;
              end
              else
              begin
                repeat
                  TempString := LineInput('Msg = ',
                    QSLPhoneMessage,
                    True, True);

                  if TempString[1] = NullKey then
                    if DVKEnable then
                    begin
                      case TempString[2] of
                        AltW: DVPRecordMessage(QSLPhoneMessage, False);
                        AltR: DVPListenMessage(QSLPhoneMessage, True);
                      end;
                    end
                    else
                      if ActiveDVKPort <> NoPort then
                        case TempString[2] of
                          AltW: DVKRecordMessage(QSLPhoneMessage);
                          AltR: DVKLIstenMessage(QSLPhoneMessage);
                        end;
                until (TempString[1] <> NullKey);

                if TempString <> EscapeKey then
                begin
                  QSLPhoneMessage := TempString;
                  AppendConfigFile('QSL SSB MESSAGE = ' + TempString);
                end;
              end;
            end;

          '5':
            begin
              if ActiveMode <> Phone then
              begin
                TempString := LineInput('Msg = ', QSOBeforeMessage, True, False);
                if TempString <> EscapeKey then
                begin
                  QSOBeforeMessage := TempString;
                  AppendConfigFile('QSO BEFORE MESSAGE = ' + TempString);
                end;
              end
              else
              begin
                repeat
                  TempString := LineInput('Msg = ',
                    QSOBeforePhoneMessage,
                    True, True);

                  if TempString[1] = NullKey then
                    if DVKEnable then
                    begin
                      case TempString[2] of
                        AltW: DVPRecordMessage(QSOBeforePhoneMessage, False);
                        AltR: DVPListenMessage(QSOBeforePhoneMessage, True);
                      end;
                    end
                    else
                      if ActiveDVKPort <> NoPort then
                        case TempString[2] of
                          AltW: DVKRecordMessage(QSOBeforePhoneMessage);
                          AltR: DVKLIstenMessage(QSOBeforePhoneMessage);
                        end;
                until (TempString[1] <> NullKey);

                if TempString <> EscapeKey then
                begin
                  QSOBeforePhoneMessage := TempString;
                  AppendConfigFile('QSO BEFORE SSB MESSAGE = ' + TempString);
                end;
              end;
            end;

          '6':
            begin
              if ActiveMode <> Phone then
              begin
                TempString := LineInput('Msg = ', QuickQSLMessage1, True, False);
                if TempString <> EscapeKey then
                begin
                  QuickQSLMessage1 := TempString;
                  AppendConfigFile('QUICK QSL MESSAGE= ' + TempString);
                end;
              end
              else
              begin
                repeat
                  TempString := LineInput('Msg = ',
                    QuickQSLPhoneMessage,
                    True, True);

                  if TempString[1] = NullKey then
                    if DVKEnable then
                    begin
                      case TempString[2] of
                        AltW: DVPRecordMessage(QuickQSLPhoneMessage, False);
                        AltR: DVPListenMessage(QuickQSLPhoneMessage, True);
                      end;
                    end
                    else
                      if ActiveDVKPort <> NoPort then
                        case TempString[2] of
                          AltW: DVKRecordMessage(QuickQSLPhoneMessage);
                          AltR: DVKLIstenMessage(QuickQSLPhoneMessage);
                        end;
                until (TempString[1] <> NullKey);

                if TempString <> EscapeKey then
                begin
                  QuickQSLPhoneMessage := TempString;
                  AppendConfigFile('QUICK QSL SSB MESSAGE = ' + TempString);
                end;
              end;
            end;

          '7':
            begin
              if ActiveMode <> Phone then
              begin
                TempString := LineInput('Msg = ', RepeatSearchAndPounceExchange, True, False);
                if TempString <> EscapeKey then
                begin
                  RepeatSearchAndPounceExchange := TempString;
                  AppendConfigFile('REPEAT S&P EXCHANGE = ' + TempString);
                end;
              end
              else
              begin
                repeat
                  TempString := LineInput('Msg = ',
                    RepeatSearchAndPouncePhoneExchange,
                    True, True);

                  if TempString[1] = NullKey then
                    if DVKEnable then
                    begin
                      case TempString[2] of
                        AltW: DVPRecordMessage(RepeatSearchAndPouncePhoneExchange, False);
                        AltR: DVPListenMessage(RepeatSearchAndPouncePhoneExchange, True);
                      end;
                    end
                    else
                      if ActiveDVKPort <> NoPort then
                        case TempString[2] of
                          AltW: DVKRecordMessage(RepeatSearchAndPouncePhoneExchange);
                          AltR: DVKLIstenMessage(RepeatSearchAndPouncePhoneExchange);
                        end;
                until (TempString[1] <> NullKey);

                if TempString <> EscapeKey then
                begin
                  RepeatSearchAndPouncePhoneExchange := TempString;
                  AppendConfigFile('REPEAT S&P SSB EXCHANGE = ' + TempString);
                end;
              end;
            end;

          '8':
            begin
              if ActiveMode <> Phone then
              begin
                TempString := LineInput('Msg = ', SearchAndPounceExchange, True, False);
                if TempString <> EscapeKey then
                begin
                  SearchAndPounceExchange := TempString;
                  AppendConfigFile('S&P EXCHANGE = ' + TempString);
                end;
              end
              else
              begin
                repeat
                  TempString := LineInput('Msg = ',
                    SearchAndPouncePhoneExchange,
                    True, True);

                  if TempString[1] = NullKey then
                    if DVKEnable then
                    begin
                      case TempString[2] of
                        AltW: DVPRecordMessage(SearchAndPouncePhoneExchange, False);
                        AltR: DVPListenMessage(SearchAndPouncePhoneExchange, True);
                      end;
                    end
                    else
                      if ActiveDVKPort <> NoPort then
                        case TempString[2] of
                          AltW: DVKRecordMessage(SearchAndPouncePhoneExchange);
                          AltR: DVKLIstenMessage(SearchAndPouncePhoneExchange);
                        end;
                until (TempString[1] <> NullKey);

                if TempString <> EscapeKey then
                begin
                  SearchAndPouncePhoneExchange := TempString;
                  AppendConfigFile('S&P SSB EXCHANGE = ' + TempString);
                end;
              end;
            end;

          '9':
            begin
              if ActiveMode <> Phone then
              begin
                TempString := LineInput('Msg = ', TailEndMessage, True, False);
                if TempString <> EscapeKey then
                begin
                  TailEndMessage := TempString;
                  AppendConfigFile('TAIL END MESSAGE = ' + TempString);
                end;
              end
              else
              begin
                repeat
                  TempString := LineInput('Msg = ',
                    TailEndPhoneMessage,
                    True, True);

                  if TempString[1] = NullKey then
                    if DVKEnable then
                    begin
                      case TempString[2] of
                        AltW: DVPRecordMessage(TailEndPhoneMessage, False);
                        AltR: DVPListenMessage(TailEndPhoneMessage, True);
                      end;
                    end
                    else
                      if ActiveDVKPort <> NoPort then
                        case TempString[2] of
                          AltW: DVKRecordMessage(TailEndPhoneMessage);
                          AltR: DVKLIstenMessage(TailEndPhoneMessage);
                        end;
                until (TempString[1] <> NullKey);

                if TempString <> EscapeKey then
                begin
                  TailEndPhoneMessage := TempString;
                  AppendConfigFile('TAIL END SSB MESSAGE = ' + TempString);
                end;
              end;
            end;

          'A':
            if ActiveMode <> Phone then
            begin
              TempString := LineInput('Enter character for short zeros : ', '', True, False);
              if (TempString <> EscapeKey) and (TempString <> '') then
              begin
                Short0 := TempString[1];
                AppendConfigFile('SHORT 0 = ' + Short0);
              end;
            end;

          'B':
            if ActiveMode <> Phone then
            begin
              TempString := LineInput('Enter character for short ones : ', '', True, False);
              if (TempString <> EscapeKey) and (TempString <> '') then
              begin
                Short1 := TempString[1];
                AppendConfigFile('SHORT 1 = ' + Short1);
              end;
            end;

          'C':
            if ActiveMode <> Phone then
            begin
              TempString := LineInput('Enter character for short twos : ', '', True, False);
              if (TempString <> EscapeKey) and (TempString <> '') then
              begin
                Short2 := TempString[1];
                AppendConfigFile('SHORT 2 = ' + Short2);
              end;
            end;

          'D':
            if ActiveMode <> Phone then
            begin
              TempString := LineInput('Enter character for short nines : ', '', True, False);
              if (TempString <> EscapeKey) and (TempString <> '') then
              begin
                Short9 := TempString[1];
                AppendConfigFile('SHORT 9 = ' + Short9);
              end;
            end;

        end; { of case }

        //        RemoveAndRestorePreviousWindow;
      until False;
  end;
end;

function GetCQMemoryString(Mode: ModeType; Key: Char): ShortString; {KK1L: 6.73 Added Mode to do split mode}

{VAR Mode: ModeType;}{KK1L: 6.73 Removed}

begin
  {Mode := ActiveMode;}{KK1L: 6.73 Removed}

  if Mode = Digital then Mode := CW;

  GetCQMemoryString := '';
  if Mode < Both then
    if CQMemory[Mode, Key] <> nil then
    begin
      GetCQMemoryString := CQMemory[Mode, Key]^;
   //   sleep(5);    //n4af 4.43.10
    end;
end;

function GetEXMemoryString(Mode: ModeType; Key: Char): ShortString; {KK1L: 6.73 Added Mode to do split mode}

{VAR Mode: ModeType;}{KK1L: 6.73 Removed}

begin
  {Mode := ActiveMode;}{KK1L: 6.73 Removed}

  if Mode = Digital then Mode := CW;

  if EXMemory[Mode, Key] <> nil then
    GetEXMemoryString := EXMemory[Mode, Key]^
  else
    GetEXMemoryString := ''
end;

procedure SetCQCaptionMemoryString(Mode: ModeType; Key: Char; MemoryString: ShortString);

begin
  if Mode = Digital then Mode := CW;

  if CQCaptionMemory[Mode, Key] = nil then New(CQCaptionMemory[Mode, Key]);
  CQCaptionMemory[Mode, Key]^ := MemoryString;
  CQCaptionMemory[Mode, Key]^[length(MemoryString) + 1] := #0;
end;

procedure SetEXCaptionMemoryString(Mode: ModeType; Key: Char; MemoryString: ShortString);

begin
  if Mode = Digital then Mode := CW;
  if EXCaptionMemory[Mode, Key] = nil then New(EXCaptionMemory[Mode, Key]);
  EXCaptionMemory[Mode, Key]^ := MemoryString;
  EXCaptionMemory[Mode, Key]^[length(MemoryString) + 1] := #0;
end;

procedure SetCQMemoryString(Mode: ModeType; Key: Char; MemoryString: ShortString {Str80});

begin
  if Mode = Digital then Mode := CW;

  if CQMemory[Mode, Key] = nil then New(CQMemory[Mode, Key]);
  {KK1L: 6.72 NOTE This is where I should interpret the string just as if it were being read from LOGCFG.DAT}
  SniffOutControlCharacters(MemoryString); {KK1L: 6.72}
  CQMemory[Mode, Key]^ := MemoryString;
  CQMemory[Mode, Key]^[length(MemoryString) + 1] := #0;
end;

procedure SetEXMemoryString(Mode: ModeType; Key: Char; MemoryString: ShortString {Str80});

begin
  if Mode = Digital then Mode := CW;

  if EXMemory[Mode, Key] = nil then New(EXMemory[Mode, Key]);
  {KK1L: 6.72 NOTE This is where I should interpret the string just as if it were being read from LOGCFG.DAT}
  SniffOutControlCharacters(MemoryString); {KK1L: 6.72}
  EXMemory[Mode, Key]^ := MemoryString;
  EXMemory[Mode, Key]^[length(MemoryString) + 1] := #0;
end;

procedure InitializeKeyer;
begin
//  ActiveKeyerPort := Radio1.tKeyerPort;
  SerialInvert := Radio1SerialInvert;
  CPUKeyer.InitializeKeyer;
end;

procedure UnInitializeKeyer;

begin
  //  if CPUKeyer.KeyerInitialized then
  CPUKeyer.UnInitializeKeyer;
end;

procedure SetUpToSendOnActiveRadio;

var
  TimeOut                               : Byte;

begin

  {
    if (ActiveMode = Phone) and DVKEnable and DVPActive and DVPMessagePlaying then
      begin
        TimeOut := 0;
 
        DVPStopPlayback;
 
        repeat
          Wait(5);
          inc(TimeOut);
        until (not DVPMessagePlaying) or (TimeOut > 50);
      end;
  }
  if ActiveRadio = RadioOne then
  begin
    if not SendingOnRadioOne then
    begin
      FlushCWBufferAndClearPTT; { Clear CW sent on Inactive Radio}
//      ActiveKeyerPort := Radio1.tKeyerPort;
//      tActiveKeyerHandle := Radio1.tKeyerPortHandle;
      SerialInvert := Radio1SerialInvert;
          {CodeSpeed := RadioOneSpeed;}
      CodeSpeed := Radio1.SpeedMemory; {KK1L: 6.73}
      SetSpeed(CodeSpeed);
          {KK1L: 6.71 Need to set mode to that of ModeMemory [RadioOne] for split mode SO2R}
          {KK1L: 6.72 Moved this to SendCrypticMessage to only handle CTRL-A requests      }
          {           SwapRadios is run prior to coming here for SO2R and that hoses things}
          {ActiveMode := ModeMemory [RadioOne]; {KK1L: 6.71 for split mode SO2R}
      SendingOnRadioOne := True;
      SendingOnRadioTwo := False;
      SetRelayForActiveRadio(ActiveRadio);
    end;
  end

  else { Radio Two }

    if not SendingOnRadioTwo then
    begin
      FlushCWBufferAndClearPTT; { Clear CW sent on Inactive Radio}

//      ActiveKeyerPort := Radio2.tKeyerPort;
//      tActiveKeyerHandle := Radio2.tKeyerPortHandle;
      SerialInvert := Radio2SerialInvert;
        {CodeSpeed := RadioTwoSpeed;}
      CodeSpeed := Radio2.SpeedMemory; {KK1L: 6.73}
      SetSpeed(CodeSpeed);
        {KK1L: 6.71 Need to set mode to that of ModeMemory [RadioTwo] for split mode SO2R}
        {KK1L: 6.72 Moved this to SendCrypticMessage to only handle CTRL-A requests      }
        {           SwapRadios is run prior to coming here for SO2R and that hoses things}
        {ActiveMode := ModeMemory [RadioTwo]; {KK1L: 6.71 for split mode SO2R}
      SendingOnRadioOne := False;
      SendingOnRadioTwo := True;
      SetRelayForActiveRadio(ActiveRadio);
    end;

  wkSetKeyerOutput(ActiveRadioPtr);

  KeyersSwapped := False;
end;

procedure SetUpToSendOnInactiveRadio;

{ This used to swap ActiveRadio as well, but I decided not to do that
  anymore.  }

var
  TimeOut                               : Byte;

begin

  if KeyersSwapped then Exit; { Already swapped to inactive rig }
{
  if (ActiveMode = Phone) and DVKEnable and DVPActive and DVPMessagePlaying then
  begin
    TimeOut := 0;

      DVPStopPlayback;

      repeat
        Wait(5);
        inc(TimeOut);
      until (not DVPMessagePlaying) or (TimeOut > 50);

  end;
}
  if ActiveRadio = RadioOne then
  begin
    if not SendingOnRadioTwo then
    begin
      FlushCWBufferAndClearPTT; { Clear CW being sent on Active Radio}
//      ActiveKeyerPort := Radio2.tKeyerPort;
//      tActiveKeyerHandle := Radio2.tKeyerPortHandle;
      SerialInvert := Radio2SerialInvert;
          {CodeSpeed := RadioTwoSpeed;}
      CodeSpeed := Radio2.SpeedMemory; {KK1L: 6.73}
      SetSpeed(CodeSpeed);
      SetRelayForActiveRadio(RadioTwo);
          {KK1L: 6.71 Need to set mode to that of ModeMemory [RadioTwo] for split mode SO2R}
          {ActiveMode := ModeMemory [RadioTwo]; {KK1L: 6.71 for split mode SO2R}
      SendingOnRadioOne := False;
      SendingOnRadioTwo := True;
    end;
  end

  else { Active radio = radio two }

    if not SendingOnRadioOne then
    begin
      FlushCWBufferAndClearPTT; { Clear CW being sent on Active Radio}
//      ActiveKeyerPort := Radio1.tKeyerPort;
//      tActiveKeyerHandle := Radio1.tKeyerPortHandle;
      SerialInvert := Radio1SerialInvert;
        {CodeSpeed := RadioOneSpeed;}
      CodeSpeed := Radio1.SpeedMemory; {KK1L: 6.73}
      SetSpeed(CodeSpeed);
      SetRelayForActiveRadio(RadioOne);
        {KK1L: 6.71 Need to set mode to that of ModeMemory [RadioOne] for split mode SO2R}
        {ActiveMode := ModeMemory [RadioOne]; {KK1L: 6.71 for split mode SO2R}
      SendingOnRadioOne := True;
      SendingOnRadioTwo := False;
    end;

  wkSetKeyerOutput(InActiveRadioPtr);

  KeyersSwapped := True;
end;

procedure ToggleCW(DisplayPrompt: boolean);

begin
  if ActiveMode = CW then
  begin
    if CWEnabled then
    begin
      if DisplayPrompt then QuickDisplay(TC_CWDISABLEDWITHALTK);
      FlushCWBufferAndClearPTT;
      CWEnabled := False;
    end
    else
    begin
      CWEnabled := True;
      QuickDisplay(nil);
    end;
  end
  else
  begin

    if DVKEnable then
    begin
      Escape_proc;
      if DisplayPrompt then QuickDisplay(TC_VOICEKEYERDISABLEDWITHALTK);
    end
    else
      SetTextInQuickCommandWindow(nil);

    InvertBoolean(DVKEnable);
  end;

  DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
  SetSpeed(CodeSpeed);
end;

procedure CWInit;
begin

//  SetEXCaptionMemoryString(CW, F1, 'DE+Cl');
//  SetEXCaptionMemoryString(CW, F2, 'Ex');
//  SetEXCaptionMemoryString(CW, F3, 'RST');

//  SetEXCaptionMemoryString(Digital, F1, 'DE+Cl');
//  SetEXCaptionMemoryString(Digital, F2, 'S&P EXCHANGE');

end;

//begin
//  CWInit;
end.

