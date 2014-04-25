unit LogPack;

{ This unit has most of the stuff used to make the packet work.  }

{ $ O+}
{ $ F+}
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  utils_text,
  Windows,
  LogDupe,
  LogEdit,
  LogStuff,
  LogK1EA,
  //Country9,
uCallSignRoutines,
  Tree,
  LogWind,
  LogNet,
  LogGrid;

const
  PacketSpotListLength                  = 10;
type
  PacketSpotModeType = (AllSpots, MultSpots);

  DXSpotType = record
    Band: BandType; { The band of the spot }
    Call: CallString; { The callsign spotted }
    Frequency: LONGINT; { LONGINT of spotted frequency }
    FrequencyString: Str20; { The frequency in string format }
    Mode: ModeType; { The mode of the spot }
    Notes: Str40; { Any notes }
    PacketString: Str160 {WLIstring}; { Original packet string as received }
    QSXFrequency: LONGINT; { Any QSX frequency }
    SpotMode: SpotModeType; { NormalSpot or SHDXSpot }
    SourceCall: CallString; { Callsign of station making the post }
    TimeString: string[5]; { Time shown in packet spot - includes the Z }
  end;

  PacketEntry = record
    Frequency: LONGINT;
    QSXFrequency: LONGINT;
    Call: CallString;
    Time: string[5];
  end;

  PacketObject = object
    BroadcastAllPacketData: boolean;

    PacketBandSpots: boolean;
    PacketBaudRate: integer;
    PacketBeep: boolean;

    PacketDebug: boolean;
    PacketDisplayBuffer: array[0..13] of Str80;
    PacketDisplayBufferStart: integer;
    PacketDisplayBufferEnd: integer;
//    PacketDisplayLine: string;

    PacketInputFileName: Str40;
    PacketInputFileOpen: boolean;
    PacketInputFileRead: Text;

    PacketLogFileName: Str40;

    PacketMemory: array[0..PacketSpotListLength] of PacketEntry;
    //      PacketNumberBits: integer;

          { Start = first entry of list.  End = cell after last data }

    PacketMemoryStart: integer;
    PacketMemoryEnd: integer;
//    PacketMessage: string;
    PacketMessageFromNetwork: Str80;
    PacketParity: ParityType;
    PacketPortNumberBits: integer;
    PacketSerialPort: PortType;
    PacketSpots: PacketSpotModeType;
    PacketStopBits: integer;

    procedure AnalyzePacketString(PacketString: ShortString);

    { This procedure will look at the packet message and try to
      determine what kind of message it is, and route it to the
      right place.  Note that the PacketDisplay during control-B
      and data the PacketDisplayBuffer is handled by a different
      routine.  It can identify a DX announcmenet, a talk message
      sent to MyCall or ALL, and responses to a SH/DX command.}

    procedure CheckPacket;

    { This is the hearbeat of all of the packet stuff.  Needs to be
      called often so things don't pileup in the input buffer. }

    procedure CheckPacketBuffer(DisplayNewData: boolean);

    { Looks at the packet input buffer to see if any new data is
      there.  It places it in the DisplayBuffer, PacketDisplayLine
      and PacketMessage so other routines can find it.  If
      DisplayNewData is set - new data will be written to the CRT also. }

    procedure CheckPacketDisplayLine(var DisplayLine: string);

    { Checks the PacketDisplayLine string to see if there is now a
      completed line (terminated by line feed) there that can be
      pushed into the PacketDisplayBuffer. }

    procedure CheckPacketMessage;

    { Checks the PacketMessage variable to see if there is any data
      there that needs to be acted on by AnalyzePacketMessage.  Gets
      called whenever CheckPacket is called. }

    procedure DeletePacketEntry(DeleteCall: CallString;
      DeleteBand: BandType;
      DeleteMode: ModeType);

    { Removes the specified spot from the Control-U memory }

    procedure DeletePacketSpot(SpotAddress: integer);

    { Removes the selected spot from the Control-U memory }

    procedure DisplayPacketDisplayBuffer;

    { Does NOT display the PacketDisplayLine which has incompleted
      line data in it. }

    procedure Init;

    { Gets executed at power up automatically }

    procedure ProcessPacketMessageFromNetWork(MessageString: string);

    { Gets called when a packet message is received over the network }

//ua4wli  procedure ProcessPacketSpot(DXSpot: DXSpotType);
    function ProcessPacketSpot(DXSpot: DXSpotType): Char;

    { Gets called when a packet spot (DX de) has been detected by
      AnalyzePacketMessage }

    procedure PushPacketSpot(DXSpot: DXSpotType);

    { Gets called by ProcessPacketSpot if it decides to save the DX spot
      for the Control-U command to access. }

    procedure PushPacketMemory(DXSpot: DXSpotType);

    { Used to push a spot into the Control-U packet spot buffer. }

    procedure SendPacketMessage(Message: string);

    { Sends the string to the packet port }

    procedure SetUpPacketPortAndBuffer;

    { Sets up the serial port specific by PacketSerialPort with the
      parameters PacketBaudRate and PacketNumberBits considered. }

  end;
function FoundDXSpot(InputString: ShortString; var DXSpot: DXSpotType): boolean;
var
  Packet                                : PacketObject;
  PacketSpotKey                         : Char = '`';
  PacketWindowUp                        : boolean;
  StartTime                             : Cardinal {TimeRecord};
  PacketInputFileDelay                  : integer;
  PacketSpotPrefixOnly                  : boolean; {KK1L: 6.72}

implementation
uses
  uBandmap,
  uSpots,
  uNet;

procedure FixUpQSXFreq(var QSXFreq: REAL; PacketFrequency: LONGINT);

var
  BaseFreq                              : LONGINT;

begin
  if QSXFreq = 0 then Exit;

  BaseFreq := Trunc(PacketFrequency / 1000000) * 1000000;

  if QSXFreq < 10.0 then { Someone put mHz in? }
  begin
    QSXFreq := Int(QSXFreq * 1000000.0);
    Exit;
  end;

  if QSXFreq < 1000.0 then { Someone entered last three digits }
  begin
    QSXFreq := BaseFreq + (QSXFreq * 1000.0);
    Exit;
  end;

  { Someone entered the whole frequency in kilohertz }

  QSXFreq := QSXFreq * 1000.0;
end;

function LookForQSXFrequency(PacketFrequency: LONGINT; Notes: Str40): LONGINT;

{ Returns zero if nothing found. }

var
  QSXFreq                               : REAL;
  Result1                               : integer;
  BaseFreq                              : LONGINT;
  FrequencyString                       : Str80;
  TempString                            : string;

begin

  LookForQSXFrequency := 0;

  if not QSXEnable then Exit;

  if Notes = '' then Exit;

  strU(Notes);

  if StringHas(Notes, 'QSX') or StringHas(Notes, 'LISTENING') then
  begin
    if StringHas(Notes, 'QSX') then
      TempString := PostcedingString(Notes, 'QSX')
    else
      if StringHas(Notes, 'LISTENING') then
        TempString := PostcedingString(Notes, 'LISTENING');

    FrequencyString := GetFirstString(TempString);

    if StringIsAllNumbersOrDecimal(FrequencyString) then
    begin
      if StringHas(FrequencyString, '.') then
      begin
        Val(FrequencyString, QSXFreq, Result1);

              { Convert MHz to Hz }

        if QSXFreq < 1500 then { Assume MHz }
          LookForQSXFrequency := round(QSXFreq * 1000000.0)
        else
          LookForQSXFrequency := round(QSXFreq * 1000.0);
        Exit;
      end;

          { String is all numbers - probably in kHz }

      if length(FrequencyString) >= 4 then { Entered complete kHz }
      begin
        Val(FrequencyString, QSXFreq, Result1);

              { Convert KHz to Hz }

        LookForQSXFrequency := round(QSXFreq * 1000.0);
        Exit;
      end;

      if length(FrequencyString) = 3 then { Entered kHz w/o MHz }
      begin
        Val(FrequencyString, QSXFreq, Result1);

              { Compute MHz part of PacketFrequency }

        BaseFreq := Trunc(PacketFrequency / 1000000) * 1000000;

              { Add them together }

        LookForQSXFrequency := round(BaseFreq + (QSXFreq * 1000.0));
        Exit;
      end;
    end;
  end;

  if StringHas(Notes, 'UP') then
  begin
    TempString := PostcedingString(Notes, 'UP');

    FrequencyString := GetFirstString(TempString);

    if length(FrequencyString) <= 2 then { Entered kHz offset }
    begin
      Val(FrequencyString, QSXFreq, Result1);

          { Add them together }

      LookForQSXFrequency := round(PacketFrequency + (QSXFreq * 1000.0));
      Exit;
    end;
  end;

  if StringHas(Notes, 'DOWN') then
  begin
    TempString := PostcedingString(Notes, 'DOWN');

    FrequencyString := GetFirstString(TempString);

    if length(FrequencyString) <= 2 then { Entered kHz offset }
    begin
      Val(FrequencyString, QSXFreq, Result1);

          { Add them together }

      LookForQSXFrequency := round(PacketFrequency - (QSXFreq * 1000.0));
      Exit;
    end;
  end;

end;

function TalkOrAnnounceMessage(PacketSpot: string): boolean;

var
  FirstString, LastString               : Str80;

begin
  FirstString := GetFirstString(PacketSpot);
  LastString := GetLastString(PacketSpot);

  TalkOrAnnounceMessage := False;

  if LastString = '>' then Exit;

  if (FirstString = 'ALL') or StringHas(FirstString, MyCall) then
    TalkOrAnnounceMessage := True;
end;

function FoundDXSpot(InputString: ShortString; var DXSpot: DXSpotType): boolean;

{ Looks at the string passed to it to determine if it looks like a DX
  packet spot.  The format expected is as follows:

         1         2         3         4         5         6         7
123456789012345678901234567890123456789012345678901234567890123456789012345

DX de OK1CF:     10107.1  WP4KGR       Marconi station                2148Z
}

var
  Result1                               : integer;
  TempFrequency                         : REAL;

begin
  FoundDXSpot := False;

  if UpperCase(Copy(InputString, 1, 5)) <> 'DX DE' then Exit;

  RemoveFirstString(InputString); { DX }
  RemoveFirstString(InputString); { de }

  with DXSpot do
  begin
    PacketString := InputString;

    SourceCall := UpperCase(RemoveFirstString(InputString));
    SourceCall := PrecedingString(SourceCall, ':');

    FrequencyString := RemoveFirstString(InputString);

    Val(FrequencyString, TempFrequency, Result1);

    if Result1 <> 0 then Exit;

    if TempFrequency < MaxLongInt div 9 then
      TempFrequency := TempFrequency * 1000; { Convert kHz to Hz }

      { See if more than 2,000,000,000 Hz or 2 GHz }

    if (TempFrequency > 2000000000) or (TempFrequency < 0) then
      Exit;

      { Convert real frequency to LONGINT }

    Frequency := round(TempFrequency);

    Mode := ActiveMode; { In case on 160 }

    CalculateBandMode(Frequency, Band, Mode);

    if Band = NoBand then Exit;
    if Mode = NoMode then Exit;

    GetRidOfPrecedingSpaces(InputString);

    Call := RemoveFirstString(InputString);

    if not GoodCallSyntax(Call) then Exit;

    TimeString := RemoveLastString(InputString);

    GetRidOfPrecedingSpaces(InputString);
    GetRidOfPostcedingSpaces(InputString);

    Notes := InputString;

    QSXFrequency := LookForQSXFrequency(Frequency, Notes);

    SpotMode := NormalSpot;

    FoundDXSpot := True;
  end;
end;

function ShowDXResponse(InputString: ShortString; var DXSpot: DXSpotType): boolean;

{ Processes responses to SH/DX commands.  Examples include :

3503.2   DL7ON       16-Nov-1999 0603Z                             DL <N4ZR>
3503.0   V47BY       16-Nov-1999 0559Z  QSX 3506.4                 V4 <VE2ZP>
14202.0  CU3EYS      16-Nov-1999 0555Z                             CU <K7WT>
14084.3  ZD7MY       16-Nov-1999 0555Z  RTTY. 569 in Toronto,On   ZD7 <VA3NA>
14240.0  V31JP       16-Nov-1999 0554Z                             V3 <KA8ZPE>
144200.0  WB9TFS     14-Nov-1999 0508Z  EM72 > EM55                 K <N4LGY>
144200.0  W4KPA      14-Nov-1999 0446Z  EM73 > EM55                 K <N4LGY>
144209.0  W1REZ      13-Nov-1999 2208Z  fn55 peaking 330 degs       K <KU2A>
144205.0  W8KX       13-Nov-1999 2111Z  en72>fn43                   K <WA1T>
144219.7  K3KYR      13-Nov-1999 2110Z  FN24 aurora qtf 330         K <KU2A> }

var
  DateString                            : Str40;
  Result1                               : integer;
  TempFrequency                         : REAL;

begin
  ShowDXResponse := False;

  if StringHas(InputString, 'SH/DX') then Exit;

  with DXSpot do
  begin
    PacketString := InputString;

    FrequencyString := RemoveFirstString(InputString);
    Call := RemoveFirstString(InputString);
    DateString := RemoveFirstString(InputString);
    TimeString := RemoveFirstString(InputString);

    SourceCall := RemoveLastString(InputString);

    Notes := InputString;

    if not GoodCallSyntax(Call) then Exit;

    if not StringHas(FrequencyString, '.') then Exit;

    Val(FrequencyString, TempFrequency, Result1);
    if Result1 <> 0 then Exit;

      { Look at the date and time syntax }

    if not StringHas(DateString, '-') then Exit;

    if not StringHas(TimeString, 'Z') then Exit;
    if not length(TimeString) = 5 then Exit;
    if not StringIsAllNumbers(Copy(TimeString, 1, 4)) then Exit;

      { Convert the frequency }

    if TempFrequency < MaxLongInt div 9 then
      TempFrequency := TempFrequency * 1000; { Convert kHz to Hz }

      { See if more than 2,000,000,000 Hz or 2 GHz }

    if (TempFrequency > 2000000000) or (TempFrequency < 0) then
      Exit;

    Frequency := round(TempFrequency);

    Mode := ActiveMode; { In case on 160 }

    CalculateBandMode(Frequency, Band, Mode);

    if Band = NoBand then Exit;
    if Mode = NoMode then Exit;

    QSXFrequency := LookForQSXFrequency(Frequency, Notes);

      { Get rid of <>'s around source call }

    if Copy(SourceCall, 1, 1) = '<' then Delete(SourceCall, 1, 1);

    if Copy(SourceCall, length(SourceCall), 1) = '>' then
      Delete(SourceCall, length(SourceCall), 1);

    SpotMode := SHDXSpot;

    ShowDXResponse := True;
  end;

end;

function OH2AQFileInputSpot(InputString: ShortString; var DXSpot: DXSpotType): boolean;

{
JG3UVN    21420.5 IH9P        33                            0922 31 Oct 1999
MI0BTM    28435.0 TA2KB                                     0934 31 Oct 1999
RX3DCX    14296.5 R3K                                       1025 31 Oct 1999
2E1GOR    28377.4 UA1QV                                     1027 31 Oct 1999
DL9YAJ    21227.7 4U1VIC                                    1029 31 Oct 1999
CT2CVE    28614.5 OK1ARI      contest                       1030 31 Oct 1999
}

var
  DateString                            : Str40;
  Result1                               : integer;
  TempFrequency                         : REAL;

begin
  OH2AQFileInputSpot := False;

  with DXSpot do
  begin
    PacketString := InputString;

    SourceCall := RemoveFirstString(InputString);
    FrequencyString := RemoveFirstString(InputString);
    Call := RemoveFirstString(InputString);

      { Get rid of date }

    RemoveLastString(InputString);
    RemoveLastString(InputString);
    RemoveLastString(InputString);

    TimeString := RemoveLastString(InputString) + 'Z';

    Notes := InputString;

    if not GoodCallSyntax(Call) then Exit;

    if not StringHas(FrequencyString, '.') then Exit;

    Val(FrequencyString, TempFrequency, Result1);
    if Result1 <> 0 then Exit;

      { Look at the date and time syntax }

    if not StringHas(TimeString, 'Z') then Exit;
    if not length(TimeString) = 5 then Exit;
    if not StringIsAllNumbers(Copy(TimeString, 1, 4)) then Exit;

      { Convert the frequency }

    if TempFrequency < MaxLongInt div 9 then
      TempFrequency := TempFrequency * 1000; { Convert kHz to Hz }

      { See if more than 2,000,000,000 Hz or 2 GHz }

    if (TempFrequency > 2000000000) or (TempFrequency < 0) then
      Exit;

    Frequency := round(TempFrequency);

    Mode := ActiveMode; { In case on 160 }

    CalculateBandMode(Frequency, Band, Mode);

    if Band = NoBand then Exit;
    if Mode = NoMode then Exit;

    QSXFrequency := LookForQSXFrequency(Frequency, Notes);

      { Get rid of <>'s around source call }

    if Copy(SourceCall, 1, 1) = '<' then Delete(SourceCall, 1, 1);

    if Copy(SourceCall, length(SourceCall), 1) = '>' then
      Delete(SourceCall, length(SourceCall), 1);

    SpotMode := SHDXSpot;

    OH2AQFileInputSpot := True;
  end;

end;

function PacketFileInputSpot(InputString: ShortString; var DXSpot: DXSpotType): boolean;

{
7002.0   EL2WW       01-Oct-1999 0001Z  workable                   EL <W7IUV>
28480.1  VK1TX       01-Oct-1999 0001Z  TEX                        VK <W8KVU>
7066.4   9H0VRZ      01-Oct-1999 0002Z                             9H <9K2HN>
}

var
  DateString                            : Str40;
  Result1                               : integer;
  TempFrequency                         : REAL;

begin
  PacketFileInputSpot := False;

  with DXSpot do
  begin
    PacketString := InputString;

    FrequencyString := RemoveFirstString(InputString);
    Call := RemoveFirstString(InputString);

      { Get rid of date }

    RemoveFirstString(InputString);

    TimeString := RemoveFirstString(InputString);

    SourceCall := RemoveLastString(InputString);

    Notes := InputString;

    if not GoodCallSyntax(Call) then Exit;

    if not StringHas(FrequencyString, '.') then Exit;

    Val(FrequencyString, TempFrequency, Result1);
    if Result1 <> 0 then Exit;

      { Look at the date and time syntax }

    if not StringHas(TimeString, 'Z') then Exit;
    if not length(TimeString) = 5 then Exit;
    if not StringIsAllNumbers(Copy(TimeString, 1, 4)) then Exit;

      { Convert the frequency }

    if TempFrequency < MaxLongInt div 9 then
      TempFrequency := TempFrequency * 1000; { Convert kHz to Hz }

      { See if more than 2,000,000,000 Hz or 2 GHz }

    if (TempFrequency > 2000000000) or (TempFrequency < 0) then
      Exit;

    Frequency := round(TempFrequency);

    Mode := ActiveMode; { In case on 160 }

    CalculateBandMode(Frequency, Band, Mode);

    if Band = NoBand then Exit;
    if Mode = NoMode then Exit;

    QSXFrequency := LookForQSXFrequency(Frequency, Notes);

      { Get rid of <>'s around source call }

    if Copy(SourceCall, 1, 1) = '<' then Delete(SourceCall, 1, 1);

    if Copy(SourceCall, length(SourceCall), 1) = '>' then
      Delete(SourceCall, length(SourceCall), 1);

    SpotMode := SHDXSpot;

    PacketFileInputSpot := True;
  end;

end;

procedure PacketObject.AnalyzePacketString(PacketString: ShortString);

{ This procedure will look at the packet message and try to determine what
  kind of message it is, and route it to the right place.  Note that the
  PacketDisplay during control-B and data the PacketDisplayBuffer is
  handled by a different routine.

  It can identify a DX announcmenet, a talk message sent to MyCall or ALL,
  and responses to a SH/DX command.}

var
  DXSpot                                : DXSpotType;
  Message                               : string;

begin
  while pos(CarriageReturn, PacketString) > 0 do
    Delete(PacketString, pos(CarriageReturn, PacketString), 1);

  while pos(LineFeed, PacketString) > 0 do
    Delete(PacketString, pos(LineFeed, PacketString), 1);

  GetRidOfPrecedingSpaces(PacketString);

  Message := UpperCase(PacketString);

  if FoundDXSpot(PacketString, DXSpot) or ShowDXResponse(PacketString, DXSpot) then
  begin
    ProcessPacketSpot(DXSpot);
    Exit;
  end;

  { Might this be a talk or an announce message that I need to display? }

  if TalkOrAnnounceMessage(PacketString) then
  begin
    if PacketBeep then Write(Beep);
      {
          if length(PacketString) > 72 then
            QuickDisplay(Copy(PacketString, 1, 72))
          else
            QuickDisplay(PacketString);
      }
    QuickDisplay(@PacketString[1]);
    Exit;

  end;
end;

procedure PacketObject.CheckPacketBuffer(DisplayNewData: boolean);

{ This procedure examines the PacketBuffer to see if there is any new
  data there.

  If new data is found, and the DisplayNewData flag is TRUE, the data
  will be displayed.  This is used if the Control-B packet window is up.

  Any complete lines found will be pushed into the PacketDisplayBuffer
  and also sent to the network it is enabled.

  Any remainig characters from incomplete lines will be saved in the
  global string PacketDisplayLine.  This string should be displayed
  whenever painting a new Control-B window - since the data won't be
  in the PacketDisplayBuffer (yet).

  Finally, all new data will be appended to the global string
  PacketMessage.  This is what gets looked at for new commands coming
  in from packet.  }

//var
//  TempString                            : string;
//  PacketByte                            : Byte;

begin
  {
    if CPUKeyer.SerialPortInputBuffer[Packet.PacketSerialPort].IsEmpty then Exit; // No new characters

     // Suck characters from PacketReceiveBuffer into TempString.

    TempString := '';

    while CPUKeyer.SerialPortInputBuffer[Packet.PacketSerialPort].GetNextByte(PacketByte) do
    begin
      TempString := TempString + CHR(PacketByte);
      if length(TempString) = 255 then Break; // The rest can wait
    end;

     // If the Control-B window is up, then we will be told to write this     data so it appears in real time on the screen (instead of waiting     until the line is complete.

    if DisplayNewData then Write(TempString);

     //Append data to PacketDisplayLine

    PacketDisplayLine := PacketDisplayLine + TempString;

     // See if we have a new line that can be pushed into the DisplayBuffer.     If the MultiNetwork is up and packet data is enabled, this routine     will also send the new complete line out on the network.

    CheckPacketDisplayLine(PacketDisplayLine);

     // We don't need any control-G's to process commands

    while pos(ControlG, TempString) > 0 do
      Delete(TempString, pos(ControlG, TempString), 1);

      Update the PacketMessage global with this data

    PacketMessage := PacketMessage + TempString;
  }
end;

procedure PacketObject.CheckPacketDisplayLine(var DisplayLine: string);

{ Looks at the string passed to it to see if a complete line (terminated
  with a line feed) is present.  If so, it removes it from the string
  and puts into the PacketDisplayBuffer.

  It also sends the completed line to the multi network if it is enabled.

  The PacketDisplayBuffer [0..12] of String80 is an indexed rotating
  buffer defined by PacketDisplayBufferStart and PacketDisplayBufferEnd.
  Start is the first line displayed and end is the last line displayed. }

var
  TempString                            : string;
  LineWidth                             : integer;
  FileWrite                             : Text;

begin
  { Remove any beeps - we don't want them in the display buffer. }

  while pos(ControlG, DisplayLine) > 0 do
    Delete(DisplayLine, pos(ControlG, DisplayLine), 1);

  { Make sure we don't have any leading LineFeeds or CarriageReturns }

  while (Copy(DisplayLine, 1, 1) = LineFeed) or (Copy(DisplayLine, 1, 1) = CarriageReturn) do
    Delete(DisplayLine, 1, 1);

  while pos(LineFeed, DisplayLine) > 0 do
  begin
    LineWidth := pos(LineFeed, DisplayLine);

      { We are going to ignore the last two characters for now - they
        are assumed to be carriage return and line feed }

    if LineWidth > 2 then { If more than just CR/LF }
    begin
      TempString := Copy(DisplayLine, 1, LineWidth - 2);

      if LineWidth >= 80 then TempString := Copy(TempString, 1, 79);

          { Send this message to the network if appropriate }

//               if BroadcastAllPacketData and (Packet.PacketSerialPort <> NoPort) and (ActiveMultiPort <> NoPort) then
//                  SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF,
//                     MultiPacketReceivedMessage, TempString);

          { Save this message to the packet log file if there is one }

      if PacketLogFileName <> '' then
        if OpenFileForAppend(FileWrite, PacketLogFileName) then
        begin
          WriteLn(FileWrite, TempString);
          Close(FileWrite);
        end;

          { Put the message into the packet display buffer }

      PacketDisplayBuffer[PacketDisplayBufferEnd] := TempString;
      inc(PacketDisplayBufferEnd);

      if PacketDisplayBufferEnd >= 13 then PacketDisplayBufferEnd := 0;

      if PacketDisplayBufferStart = PacketDisplayBufferEnd then
      begin
        inc(PacketDisplayBufferStart);
        if PacketDisplayBufferStart >= 13 then PacketDisplayBufferStart := 0;
      end;
    end;

      { Remove the line we just processed from the string. }

    Delete(DisplayLine, 1, LineWidth);

      { Remove any leading line feeds or carriage returns }

    while (Copy(DisplayLine, 1, 1) = LineFeed) or (Copy(DisplayLine, 1, 1) = CarriageReturn) do
      Delete(DisplayLine, 1, 1);

  end;
end;

procedure PacketObject.Init;

begin
//  PacketDisplayLine := '';
//  PacketMessage := '';
  PacketMessageFromNetwork := '';
  PacketMemoryStart := 0;
  PacketMemoryEnd := 0;
  PacketDisplayBufferStart := 0;
  PacketDisplayBufferEnd := 0;
  PacketInputFileName := '';
  PacketInputFileOpen := False;
  PacketInputFileDelay := 1;
end;

procedure PacketObject.ProcessPacketMessageFromNetWork(MessageString: string);

{ This routine will handle a packet message that came in over the multi
  network }

begin
  { If we are hooked up to the TNC, we can ignore it }

  if Packet.PacketSerialPort <> NoPort then Exit;

  { If the ControlB window is up - display the message as it comes in }

  if PacketWindowUp then WriteLn(MessageString);

  { We feed the message to both PacketMessage and PacketDisplayLine for
    processing. }

//  PacketMessage := MessageString + CarriageReturn + LineFeed;
//  PacketDisplayLine := PacketMessage;

  CheckPacketMessage;
//  CheckPacketDisplayLine(PacketDisplayLine);
end;

function PacketObject.ProcessPacketSpot(DXSpot: DXSpotType): Char;

{ Processes a packet spot.  Puts it in the band map (if enabled).  Pushes
  it onto the packet spot buffer. }

var
  MultString                            : integer; //Str80 {Str20};
  Dupe, Mult                            : boolean;
begin
  Result := ' ';
  with DXSpot do
  begin

      //         if (Band = Band160) and StringHas(MyCall, 'N6TR') then
      //            CheckForNewCountryForTreeOn160(Call);

               { We ignore dupes, except to put on the band map if enabled.  We
                 don't send this around to the network because they will get the
                 information themselves from the packet spot. }

    if VisibleLog.CallIsADupe(Call, Band, Mode) then
    begin
      Result := '*';
          //               if BandMapEnable then {Dupe, Mult} {Send to mult}
          //                  NewBandMapEntry(Call, Frequency, QSXFrequency, Mode, True, False, BandMapDecayTime, False, SourceCall);
      Exit;
    end;

      { Call is not a dupe }

    if BandMapEnable or (PacketSpots = MultSpots) then
    begin
      Mult := VisibleLog.DetermineIfNewMult(Call, Band, Mode);
//      Mult := MultString <> 0;
      if Mult then Result := '@';
    end;

      //         if BandMapEnable then            NewBandMapEntry(Call, Frequency, QSXFrequency, Mode, False, Mult, BandMapDecayTime, False, SourceCall);

    if (not PacketBandSpots) or (Band = ActiveBand) then
      if (PacketSpots <> MultSpots) or Mult then PushPacketSpot(DXSpot);

    if Call = MyCall then
    begin
      DoABeep(Congrats);
      Result := '#';
    end;

  end;
end;

procedure PacketObject.PushPacketSpot(DXSpot: DXSpotType);

{ Takes the spot information and saves it for Control-U. }

var
  TempString                            : Str80;

begin
  with DXSpot do
    if SpotMode = NormalSpot then
    begin
        //wli            if PacketBeep then Write(Beep);

//      QuickDisplay(SourceCall + ' says ' + Call + ' is on ' + FrequencyString + '  ' + Notes);
//      SendMessage(QuickCommandWindowHandle, SB_SETTEXT, 1, lParam(PChar(string(SourceCall + ' says ' + Call + ' is on ' + FrequencyString + '  ' + Notes))));

        //            ReminderPostedCount := 60;
    end;

  PushPacketMemory(DXSpot);
end;

procedure PacketObject.PushPacketMemory(DXSpot: DXSpotType);

var
  Address                               : integer;

begin
  with DXSpot do
    if SpotMode = NormalSpot then { Normal spot - put at the start }

    begin
      dec(PacketMemoryStart);

      if PacketMemoryStart < 0 then
        PacketMemoryStart := PacketSpotListLength;

      PacketMemory[PacketMemoryStart].Call := Call;
      PacketMemory[PacketMemoryStart].Frequency := Frequency;
      PacketMemory[PacketMemoryStart].QSXFrequency := QSXFrequency;
      PacketMemory[PacketMemoryStart].Time := TimeString;

      if PacketMemoryStart = PacketMemoryEnd then
      begin
        dec(PacketMemoryEnd);

        if PacketMemoryEnd < 0 then
          PacketMemoryEnd := PacketSpotListLength;
      end;
    end

    else { SH/DX response = put it at the end }

    begin
      PacketMemory[PacketMemoryEnd].Call := Call;
      PacketMemory[PacketMemoryEnd].Frequency := Frequency;
      PacketMemory[PacketMemoryEnd].QSXFrequency := QSXFrequency;
      PacketMemory[PacketMemoryEnd].Time := TimeString;
      inc(PacketMemoryEnd);

      if PacketMemoryEnd > PacketSpotListLength then
        PacketMemoryEnd := 0;

      if PacketMemoryStart = PacketMemoryEnd then
      begin
        inc(PacketMemoryStart);

        if PacketMemoryStart > PacketSpotListLength then
          PacketMemoryStart := 0;
      end;
    end;
end;

procedure PacketObject.DeletePacketSpot(SpotAddress: integer);

var
  SourceAddress                         : integer;

begin
  if SpotAddress = PacketMemoryStart then
  begin
    inc(PacketMemoryStart);

    if PacketMemoryStart > PacketSpotListLength then
      PacketMemoryStart := 0;
    Exit;
  end;

  { This loop gets stuck!! }

  repeat
    SourceAddress := SpotAddress + 1; { Point to next cell }

    if SourceAddress > PacketSpotListLength then { See if we looped }
      SourceAddress := 0;

    if SourceAddress = PacketMemoryEnd then { We are done? }
    begin
      dec(PacketMemoryEnd);

      if PacketMemoryEnd < 0 then { Back end up by one }
        PacketMemoryEnd := PacketSpotListLength;

      Exit;
    end;

    PacketMemory[SpotAddress] := PacketMemory[SourceAddress];

    inc(SpotAddress);

    if SpotAddress > PacketSpotListLength then
      SpotAddress := 0;

  until False;
end;

procedure PacketObject.DeletePacketEntry(DeleteCall: CallString;
  DeleteBand: BandType;
  DeleteMode: ModeType);

var
  PacketAddress, Spot                   : integer;
  Band                                  : BandType;
  Mode                                  : ModeType;

begin
  for Spot := 1 to PacketSpotListLength do
  begin
    PacketAddress := PacketMemoryStart + Spot - 1;

    if PacketAddress > PacketSpotListLength then
      PacketAddress := PacketAddress - (PacketSpotListLength + 1);

    if PacketAddress = PacketMemoryEnd then Exit;

    with PacketMemory[PacketAddress] do
      if (Call = DeleteCall) then
      begin
        Mode := ActiveMode;

        CalculateBandMode(Frequency, Band, Mode);

        if (Band = DeleteBand) and (Mode = DeleteMode) then
        begin
          DeletePacketSpot(PacketAddress);
          Exit;
        end;
      end;
  end;
end;

procedure PacketObject.DisplayPacketDisplayBuffer;

var
  Address                               : integer;

begin
  Address := PacketDisplayBufferStart;

  while Address <> PacketDisplayBufferEnd do
  begin
    WriteLn(PacketDisplayBuffer[Address]);

    inc(Address);
    if Address >= 13 then Address := 0;
  end;

end;

procedure PacketObject.CheckPacketMessage;

begin
{
  while StringHas(PacketMessage, LineFeed) do
  begin
    AnalyzePacketString(PrecedingString(PacketMessage, LineFeed));

//      Remove the data we have processed

    PacketMessage := PostcedingString(PacketMessage, LineFeed);

    while (Copy(PacketMessage, 1, 1) = CarriageReturn) or
      (Copy(PacketMessage, 1, 1) = LineFeed) do
      Delete(PacketMessage, 1, 1);
  end;
}
end;

procedure PacketObject.CheckPacket;

{ This is the routine that needs to be called often by the program so
  the packet stuff all works.   }

var
  PacketInputString                     : string;
  DXSpot                                : DXSpotType;

begin
{
  if PacketInputFileName <> '' then
  begin
    if not PacketInputFileOpen then
    begin
      PacketInputFileOpen := OpenFileForRead(PacketInputFileRead, PacketInputFileName);
      MarkTime(StartTime);
    end;

    if PacketInputFileOpen then
    begin
      if ElaspedSec100(StartTime) >= PacketInputFileDelay then
      begin
        ReadLn(PacketInputFileRead, PacketInputString);

        if OH2AQFileInputSpot(PacketInputString, DXSpot) then
        begin
                  //          QuickDisplay(Copy(DXSpot.PacketString, 1, 70));
          ProcessPacketSpot(DXSpot);
        end;

        if PacketFileInputSpot(PacketInputString, DXSpot) then
        begin
                  //          QuickDisplay(Copy(DXSpot.PacketString, 1, 70));
          ProcessPacketSpot(DXSpot);

                  //                           if BroadcastAllPacketData and (Packet.PacketSerialPort <> NoPort) and (ActiveMultiPort <> NoPort) then
                  //                              SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF,
                  //                                 MultiPacketReceivedMessage, DXSpot.PacketString);
        end;

        if Eof(PacketInputFileRead) then
        begin
          Close(PacketInputFileRead);
          PacketInputFileName := '';
        end;

        MarkTime(StartTime);
      end;
    end;
  end;

  if Packet.PacketSerialPort <> NoPort then // Added in 6.25
  begin
    CheckPacketBuffer(False);
    CheckPacketMessage;
  end;
}
end;

procedure PacketObject.SetUpPacketPortAndBuffer;

{ Sets up the serial port and buffers }

begin

  { Default delay = 1 }

//  CPUKeyer.SetUpSerialPort(PacketSerialPort,    PacketBaudRate,    PacketNumberBits,    PacketParity,    PacketStopBits,    1);

end;

procedure PacketObject.SendPacketMessage(Message: string);

begin
//  CPUKeyer.AddSerialPortString(Packet.PacketSerialPort, Message);
end;

begin
//  PacketWindowUp := False;
//  Packet.Init;
end.

