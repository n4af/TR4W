unit LOGPROM;

{$O+}
{$F+}
{$IMPORTEDDATA OFF}
interface

uses
  VC,
  Country9,
  LogGrid,
  ZoneCont,
  LogWind,
  LOGMENU, {Crt, }
  FCONTEST, {SlowTree,}
  Windows,
  Tree;

procedure PullLogCfgInformationOutOfThisPerson;
procedure ManualConfigFileGenerator;

implementation
uses MainUnit;
var
  FileWrite                   : Text;

procedure SetUpCWStuff;

var
  TypeKey, PortKey, PaddleKey, CWKey: Char;

begin
  {    ClearScreenAndTitle ('SET UP CW OUTPUT PORTS');

      WriteLn ('If you are going to send CW from the program, you will need to tell the ');
      WriteLn ('program which port to use for each radio.  The ports can be serial or ');
      WriteLn ('parallel.  If you are using a serial port, you can optionally invert the ');
      WriteLn ('signal which make it easier to interface to a negative voltage radio.  If');
      WriteLn ('you select a parallel port, you can also specify the port to have a paddle');
      WriteLn ('connected to it.');

      WriteLn;
  }
  repeat
    CWKey := UpCase(GetKey('Do you want to set up a port to send CW with? (Y/N) : '));
    if CWKey = EscapeKey then Exit;
  until (CWKey = 'Y') or (CWKey = 'N');
  WriteLn;

  if CWKey = 'N' then Exit;

  repeat
    TypeKey := UpCase(GetKey('Serial or parallel CW port for radio one? (S/P) : '));
    if TypeKey = EscapeKey then Exit;
  until (TypeKey = 'S') or (TypeKey = 'P');
  WriteLn;

  if TypeKey = 'S' then
  begin
      {        TextColor (Cyan);

              WriteLn;
              WriteLn ('If you are keying a negative voltage radio with a serial port, you can have');
              WriteLn ('the signal inverted so you can simply use a PNP transistor to key the radio.');
              WriteLn ('To use the INVERT option, add 4 to the port number (i.e. ports 5 to 8).');
              WriteLn;
      }
    repeat
      PortKey := UpCase(GetKey('Which serial port are you going to use for radio one? (1-4) : '));
    until (PortKey = '1') or (PortKey = '2') or (PortKey = '3') or (PortKey = '4') or
      (PortKey = '5') or (PortKey = '6') or (PortKey = '7') or (PortKey = '8');

    WriteLn;

    case PortKey of
      '1': WriteLn(FileWrite, 'KEYER RADIO ONE OUTPUT PORT = SERIAL 1');
      '2': WriteLn(FileWrite, 'KEYER RADIO ONE OUTPUT PORT = SERIAL 2');
      '3': WriteLn(FileWrite, 'KEYER RADIO ONE OUTPUT PORT = SERIAL 3');
      '4': WriteLn(FileWrite, 'KEYER RADIO ONE OUTPUT PORT = SERIAL 4');
      '5': WriteLn(FileWrite, 'KEYER RADIO ONE OUTPUT PORT = SERIAL 1 INVERT');
      '6': WriteLn(FileWrite, 'KEYER RADIO ONE OUTPUT PORT = SERIAL 2 INVERT');
      '7': WriteLn(FileWrite, 'KEYER RADIO ONE OUTPUT PORT = SERIAL 3 INVERT');
      '8': WriteLn(FileWrite, 'KEYER RADIO ONE OUTPUT PORT = SERIAL 4 INVERT');
    end;
  end
  else
  begin
    repeat
      PortKey := UpCase(GetKey('Which parallel port are you going to use for radio one? (1-3) : '));
    until (PortKey = '1') or (PortKey = '2') or (PortKey = '3');
    WriteLn;

    case PortKey of
      '1': WriteLn(FileWrite, 'KEYER RADIO ONE OUTPUT PORT = PARALLEL 1');
      '2': WriteLn(FileWrite, 'KEYER RADIO ONE OUTPUT PORT = PARALLEL 2');
      '3': WriteLn(FileWrite, 'KEYER RADIO ONE OUTPUT PORT = PARALLEL 3');
    end;

    repeat
      PaddleKey := UpCase(GetKey
        ('Do you want to enable the paddle input for this parallel port? (Y/N) : '));
      if PaddleKey = EscapeKey then Exit;
    until (PaddleKey = 'Y') or (PaddleKey = 'N');
    WriteLn;

    if PaddleKey = 'Y' then
      case PortKey of
        '1': WriteLn(FileWrite, 'PADDLE PORT = 1');
        '2': WriteLn(FileWrite, 'PADDLE PORT = 2');
        '3': WriteLn(FileWrite, 'PADDLE PORT = 3');
      end;
  end;

  WriteLn;

  repeat
    CWKey := UpCase(GetKey('Do you want to set up a port to send CW with on the second radio? (Y/N) : '));
    if CWKey = EscapeKey then Exit;
  until (CWKey = 'Y') or (CWKey = 'N');
  WriteLn;

  if CWKey = 'N' then Exit;

  repeat
    TypeKey := UpCase(GetKey('Serial or parallel CW port interface for radio two? (S/P) : '));
    if TypeKey = EscapeKey then Exit;
  until (TypeKey = 'S') or (TypeKey = 'P');
  WriteLn;

  if TypeKey = 'S' then
  begin
      {        TextColor (Cyan);

              WriteLn;
              WriteLn ('If you are keying a negative voltage radio with a serial port, you can have');
              WriteLn ('the signal inverted so you can simply use a PNP transistor to key the radio.');
              WriteLn ('To use the INVERT option, add 4 to the port number (i.e. ports 5 to 8).');
              WriteLn;
      }
    repeat
      PortKey := UpCase(GetKey('Which serial port are you going to use? (1-4) : '));
    until (PortKey = '1') or (PortKey = '2') or (PortKey = '3') or (PortKey = '4');
    WriteLn;

    case PortKey of
      '1': WriteLn(FileWrite, 'KEYER RADIO TWO OUTPUT PORT = SERIAL 1');
      '2': WriteLn(FileWrite, 'KEYER RADIO TWO OUTPUT PORT = SERIAL 2');
      '3': WriteLn(FileWrite, 'KEYER RADIO TWO OUTPUT PORT = SERIAL 3');
      '4': WriteLn(FileWrite, 'KEYER RADIO TWO OUTPUT PORT = SERIAL 4');
      '5': WriteLn(FileWrite, 'KEYER RADIO TWO OUTPUT PORT = SERIAL 1 INVERT');
      '6': WriteLn(FileWrite, 'KEYER RADIO TWO OUTPUT PORT = SERIAL 2 INVERT');
      '7': WriteLn(FileWrite, 'KEYER RADIO TWO OUTPUT PORT = SERIAL 3 INVERT');
      '8': WriteLn(FileWrite, 'KEYER RADIO TWO OUTPUT PORT = SERIAL 4 INVERT');
    end;

  end
  else
  begin
    repeat
      PortKey := UpCase(GetKey('Which parallel port are you going to use? (1-3) : '));
    until (PortKey = '1') or (PortKey = '2') or (PortKey = '3');
    WriteLn;

    case PortKey of
      '1': WriteLn(FileWrite, 'KEYER RADIO TWO OUTPUT PORT = PARALLEL 1');
      '2': WriteLn(FileWrite, 'KEYER RADIO TWO OUTPUT PORT = PARALLEL 2');
      '3': WriteLn(FileWrite, 'KEYER RADIO TWO OUTPUT PORT = PARALLEL 3');
    end;

    repeat
      PaddleKey := UpCase(GetKey
        ('Do you want to enable the paddle input for this parallel port? (Y/N) : '));
      if PaddleKey = EscapeKey then Exit;
    until (PaddleKey = 'Y') or (PaddleKey = 'N');
    WriteLn;

    if PaddleKey = 'Y' then
      case PortKey of
        '1': WriteLn(FileWrite, 'PADDLE PORT = 1');
        '2': WriteLn(FileWrite, 'PADDLE PORT = 2');
        '3': WriteLn(FileWrite, 'PADDLE PORT = 3');
      end;
  end;
end;

procedure SetUpRadioStuff;

var
  PortKey, RadioKey           : Char;
  TempString                  : Str40;
  Address                     : integer;

begin
  {    ClrScr;
      TextColor (Yellow);

      WriteLnCenter ('SET UP SERIAL INTERFACE TO RADIO CONNECTED TO COMPUTER');
      WriteLn;
      TextColor (Cyan);

      WriteLn ('If you have a radio connected interfaced to your computer via a serial port');
      WriteLn ('so that you can send and receive commands, you can answer these questions to');
      WriteLn ('set up the interface.  The default baud rate is 4800 baud.  If you need a ');
      WriteLn ('different baud rate, add RADIO ONE BAUD RATE or RADIO TWO BAUD RATE to your');
      WriteLn ('config file after this procedure is over.');

      WriteLn;
  }
  repeat
    RadioKey := UpCase(GetKey('Do you want to set up a serial port for radio one? (Y/N) : '));
    if RadioKey = EscapeKey then Exit;
  until (RadioKey = 'Y') or (RadioKey = 'N');
  WriteLn;

  if RadioKey = 'N' then Exit;

  repeat
    RadioKey := UpCase(GetKey('First letter of radio brand (K)enwood or K2, (Y)aesu, (I)com, (T)en-Tec, (J)RC : '));
    if RadioKey = EscapeKey then Exit;
  until (RadioKey = 'K') or (RadioKey = 'Y') or (RadioKey = 'I') or (RadioKey = 'T') or (RadioKey = 'J');
  WriteLn;

  case RadioKey of
    'I':
      begin
        TempString := GetResponse('Enter the Icomomdem number (i.e. IC781) : ');
        WriteLn(FileWrite, 'RADIO ONE TYPE = ', TempString);

        Address := GetValue('Enter receiver address for this radio (check you manual) : ');

        if Address >= 0 then
          WriteLn(FileWrite, 'RADIO ONE RECEIVER ADDRESS = ', Address);

      end;

    'J': WriteLn(FileWrite, 'RADIO ONE TYPE = JST245');

    'K': WriteLn(FileWrite, 'RADIO ONE TYPE = TS850S');

    'T': WriteLn(FileWrite, 'RADIO ONE TYPE = IC735');

    'Y':
      begin
        TempString := GetResponse('Enter Yaesu model number (i.e. FT1000MP) : ');
        WriteLn(FileWrite, 'RADIO ONE TYPE = ', TempString);
      end;
  end;

  repeat
    PortKey := UpCase(GetKey('Which serial port are you connecting a radio to? (1-4) : '));
  until (PortKey = '1') or (PortKey = '2') or (PortKey = '3') or (PortKey = '4');
  WriteLn;

  case PortKey of
    '1': WriteLn(FileWrite, 'RADIO ONE CONTROL PORT = SERIAL 1');
    '2': WriteLn(FileWrite, 'RADIO ONE CONTROL PORT = SERIAL 2');
    '3': WriteLn(FileWrite, 'RADIO ONE CONTROL PORT = SERIAL 3');
    '4': WriteLn(FileWrite, 'RADIO ONE CONTROL PORT = SERIAL 4');
  end;

  WriteLn;

  repeat
    RadioKey := UpCase(GetKey('Do you want to set up a serial port for radio two? (Y/N) : '));
    if RadioKey = EscapeKey then Exit;
  until (RadioKey = 'Y') or (RadioKey = 'N');
  WriteLn;

  if RadioKey = 'N' then Exit;

  repeat
    RadioKey := UpCase(GetKey('First letter of radio two brand (K)enwood or K2, (Y)aesu, (I)com, (T)en-Tec, (J)RC : '));
    if RadioKey = EscapeKey then Exit;
  until (RadioKey = 'K') or (RadioKey = 'Y') or (RadioKey = 'I') or (RadioKey = 'T') or (RadioKey = 'J');
  WriteLn;

  case RadioKey of
    'I':
      begin
        TempString := GetResponse('Enter the Icom model number (i.e. IC781) : ');
        WriteLn(FileWrite, 'RADIO TWO TYPE = ', TempString);

        Address := GetValue('Enter receiver address for this radio (check you manual) : ');

        if Address >= 0 then
          WriteLn(FileWrite, 'RADIO TWO RECEIVER ADDRESS = ', Address);

      end;

    'J': WriteLn(FileWrite, 'RADIO TWO TYPE = JST245');

    'K': WriteLn(FileWrite, 'RADIO TWO TYPE = TS850S');

    'T': WriteLn(FileWrite, 'RADIO TWO TYPE = IC735');

    'Y':
      begin
        TempString := GetResponse('Enter Yaesu model number (i.e. FT1000MP) : ');
        WriteLn(FileWrite, 'RADIO TWO TYPE = ', TempString);
      end;
  end;

  repeat
    PortKey := UpCase(GetKey('Which serial port are you connecting a radio to? (1-4) : '));
  until (PortKey = '1') or (PortKey = '2') or (PortKey = '3') or (PortKey = '4');
  WriteLn;

  case PortKey of
    '1': WriteLn(FileWrite, 'RADIO TWO CONTROL PORT = SERIAL 1');
    '2': WriteLn(FileWrite, 'RADIO TWO CONTROL PORT = SERIAL 2');
    '3': WriteLn(FileWrite, 'RADIO TWO CONTROL PORT = SERIAL 3');
    '4': WriteLn(FileWrite, 'RADIO TWO CONTROL PORT = SERIAL 4');
  end;

end;

procedure SetUpPacketStuff;

var
  PortKey, RadioKey           : Char;

begin
  {    ClrScr;
      TextColor (Yellow);
      WriteLnCenter ('SET UP PACKET PORT');
      WriteLn;
      TextColor (Cyan);

      WriteLn ('If you have a packet TNC connected to your computer, this is where you can');
      WriteLn ('tell the program which port the TNC is connected to.  The default baud rate');
      WriteLn ('is 4800 baud.  There is no flow control used, and since some of the control');
      WriteLn ('signals (RTS/CTS) can be used for CW or PTT signals, they should not be');
      WriteLn ('connected to your cable.  You might need to jumper RTS to CTS on the modem');
      WriteLn ('to make it send characters to the computer.');
      WriteLn;
  }
  repeat
    RadioKey := UpCase(GetKey('Do you want to set up a serial packet port? (Y/N) : '));
    if RadioKey = EscapeKey then Exit;
  until (RadioKey = 'Y') or (RadioKey = 'N');
  WriteLn;

  if RadioKey = 'N' then Exit;

  repeat
    PortKey := UpCase(GetKey('Which serial port is your TNC on? (1-4) : '));
  until (PortKey = '1') or (PortKey = '2') or (PortKey = '3') or (PortKey = '4');
  WriteLn;

  case PortKey of
    '1': WriteLn(FileWrite, 'PACKET PORT = SERIAL 1');
    '2': WriteLn(FileWrite, 'PACKET PORT = SERIAL 2');
    '3': WriteLn(FileWrite, 'PACKET PORT = SERIAL 3');
    '4': WriteLn(FileWrite, 'PACKET PORT = SERIAL 4');
  end;

  WriteLn;
end;

procedure SetUpMultiStuff;

var
  PortKey, RadioKey           : Char;

begin
  {    ClrScr;
      TextColor (Yellow);
      WriteLnCenter ('MULTI PORT SET UP');
      WriteLn;
      TextColor (Cyan);

      WriteLn ('If you are using a multi network by connecting computers together with the ');
      WriteLn ('serial port, this is where you tell the program which port you are using.');
      WriteLn;
      WriteLn ('You can also select a COMPUTER ID for this computer.  The COMPUTER ID gets');
      WriteLn ('appended to the QSO number for QSOs made on this computer.  This allows you');
      WriteLn ('to sort out the logs by computer after the contest (using POST).');
      WriteLn;
  }
  repeat
    RadioKey := UpCase(GetKey('Do you need to set up the multi port? (Y/N) : '));
    if RadioKey = EscapeKey then Exit;
  until (RadioKey = 'Y') or (RadioKey = 'N');
  WriteLn;

  if RadioKey = 'N' then Exit;

  repeat
    PortKey := UpCase(GetKey('Which serial port is the network on? (1-4) : '));
  until (PortKey = '1') or (PortKey = '2') or (PortKey = '3') or (PortKey = '4');
  WriteLn;

  case PortKey of
    '1': WriteLn(FileWrite, 'MULTI PORT = SERIAL 1');
    '2': WriteLn(FileWrite, 'MULTI PORT = SERIAL 2');
    '3': WriteLn(FileWrite, 'MULTI PORT = SERIAL 3');
    '4': WriteLn(FileWrite, 'MULTI PORT = SERIAL 4');
  end;

  WriteLn;

  repeat
    RadioKey := UpCase(GetKey('Do you want to set a computer ID letter for this computer? (Y/N) : '));
    if RadioKey = EscapeKey then Exit;
  until (RadioKey = 'Y') or (RadioKey = 'N');
  WriteLn;

  if RadioKey = 'N' then Exit;

  repeat
    PortKey := UpCase(GetKey('Enter single character ID for this computer (A-Z or escape for none) : '));
    if PortKey = EscapeKey then Exit;
  until (PortKey >= 'A') and (PortKey <= 'Z');
  WriteLn;

  WriteLn(FileWrite, 'COMPUTER ID = ', PortKey);
end;

procedure ManualConfigurationTitle;

begin
  {    ClrScr;
      TextColor (Yellow);
      WriteLnCenter ('CONFIGURATION FILE GENERATOR');
      WriteLn;
      TextColor (Cyan);
     }
end;

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

function GetContestName: Str80;

var
  Contests                    : array[0..80] of Str20;
  NumberContests, Address, Index, StartX, StartY, Entry: integer;
  ActiveEntry, NumberRows, BubbleCount: integer;
  EntryString, TempString     : Str80;
  Key                         : Char;

begin
  {    ClrScr;
      WriteLn ('Select the contest you wish to operate (use arrow keys) : ');
      WriteLn;
  }
  GetContestName := '';
  EntryString := '';

  { You get these for free }

  Contests[0] := 'REGION 1 FIELD DAY';
  Contests[1] := 'FIELD DAY';
  Contests[2] := 'JA INTERNATIONAL DX';
  Contests[3] := 'NZ FIELD DAY';
  Contests[4] := 'SOUTH AMERICAN WW';
  Contests[5] := 'STEW PERRY';
  Contests[6] := 'WRTC 2002'; {KK1L: 6.68 moved here for TRFree 1.04}

  NumberContests := 7;

  //  if not TRFree then
  begin
    Contests[7] := 'YO DX';
    Contests[8] := 'ALL ASIAN';
    Contests[9] := 'ALL JA';
    Contests[10] := 'ARCI';
    Contests[11] := 'ARI';
    Contests[12] := 'ARRL 10';
    Contests[13] := 'ARRL 160';
    Contests[14] := 'ARRL DX';
    Contests[15] := 'ARRL VHF QSO';
    Contests[16] := 'ARRL VHF SS';
    Contests[17] := 'CAL QSO PARTY';
    Contests[18] := 'COUNTY HUNTER';
    Contests[19] := 'CQ 160';
    Contests[20] := 'CQ M';
    Contests[21] := 'CQ WPX';
    Contests[22] := 'CQ WW';
    Contests[23] := 'CROATIAN';
    Contests[24] := 'EUROPEAN HFC';
    Contests[25] := 'EUROPEAN VHF';
    Contests[26] := 'GENERAL QSO';
    Contests[27] := 'GRID LOC';
    Contests[28] := 'HA DX';
    Contests[29] := 'HELVETIA';
    Contests[30] := 'IARU';
    Contests[31] := 'INTERNET SPRINT';
    Contests[32] := 'IOTA';
    Contests[33] := 'KCJ';
    Contests[34] := 'KVP';
    Contests[35] := 'MICH QSO PARTY';
    Contests[36] := 'MINN QSO PARTY';
    Contests[37] := 'NA QSO';
    Contests[38] := 'NEW ENGLAND QSO';
    Contests[39] := 'NRAU BALTIC';
    Contests[40] := 'OK DX';
    Contests[41] := 'PACC';
    Contests[42] := 'QCWA';
    Contests[43] := 'QCWA GOLDEN';
    Contests[44] := 'RAC';
    Contests[45] := 'ROPOCO';
    Contests[46] := 'RUSSIAN DX';
    Contests[47] := 'SAC';
    Contests[48] := 'SALMON RUN';
    Contests[49] := 'SP DX';
    Contests[50] := 'SPRINT';
    Contests[51] := 'SWEEPSTAKES';
    Contests[52] := 'TEN TEN';
    Contests[53] := 'TEXAS QSO PARTY';
    Contests[54] := 'TOEC';
    Contests[55] := 'OCEANIA'; { Was VK/ZL }
    Contests[56] := 'WAE';
    Contests[57] := 'WAG';
    Contests[58] := 'WISCONSIN QSO PARTY';
    Contests[59] := 'WWL';
    Contests[60] := 'XMAS';
    Contests[61] := 'CQ VHF';
    Contests[62] := 'EU SPRINT';
    Contests[63] := 'KIDS DAY';
    Contests[64] := 'FLORIDA QSO PARTY';
    Contests[65] := 'AP SPRINT';
    Contests[66] := 'OHIO QSO PARTY';
    Contests[67] := 'UKRAINIAN';
    Contests[68] := 'CQ WW RTTY';
    Contests[69] := 'CQ WPX RTTY';
    Contests[70] := 'UBA';
    Contests[71] := 'FISTS';
    Contests[72] := 'BALTIC';
    Contests[73] := 'ARRL RTTY ROUNDUP';

    NumberContests := 74; { One more than last index value }
  end;

  {    StartX := WhereX;
      StartY := WhereY;
     }ActiveEntry := 0;

  { Sort them in case I put one in the wrong place or the end }

  if NumberContests > 1 then
  begin
    Index := NumberContests - 2;

    for BubbleCount := 1 to NumberContests - 1 do
    begin
      for Address := 0 to Index do
        if Contests[Address] > Contests[Address + 1] then
        begin
          TempString := Contests[Address + 1];
          Contests[Address + 1] := Contests[Address];
          Contests[Address] := TempString;
        end;
      dec(Index);
    end;
  end;

  NumberRows := NumberContests div 4 + 1;

  { Put up Initial Display }

  InverseVideo(0, StartY, NumberRows, Contests[0]);

  for Entry := 1 to NumberContests - 1 do
    NormalVideo(Entry, StartY, NumberRows, Contests[Entry]);

  ActiveEntry := 0;

  repeat
    //{WLI}        Key := UpCase (ReadKey);

    case Key of
      EscapeKey, ControlC:
        begin
          GetContestName := '';
          {                TextBackground (Black);
                          TextColor (Yellow);
                          SmallCursor;
                          ClrScr;
                          TextMode (LastMode);
                         }halt;
        end;

      CarriageReturn:
        begin
          GetContestName := Contests[ActiveEntry];
          {                TextBackground (Black);
                          TextColor (Yellow);
                          SmallCursor;
                          ClrScr;
                         }Exit;
        end;

      BackSpace:
        if EntryString <> '' then
          Delete(EntryString, length(EntryString), 1);

      NullKey:
        begin
          //{WLI}                Key := ReadKey;

          case Key of
            DeleteKey:
              if EntryString <> '' then
                Delete(EntryString, length(EntryString), 1);

            RightArrow:
              if ActiveEntry < NumberContests - NumberRows then
              begin
                NormalVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
                ActiveEntry := ActiveEntry + NumberRows;
                InverseVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
              end;

            LeftArrow:
              if ActiveEntry >= NumberRows then
              begin
                NormalVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
                ActiveEntry := ActiveEntry - NumberRows;
                InverseVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
              end;

            UpArrow:
              if ActiveEntry > 0 then
              begin
                NormalVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
                ActiveEntry := ActiveEntry - 1;
                InverseVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
              end;

            DownArrow:
              if ActiveEntry + 1 < NumberContests then
              begin
                NormalVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
                ActiveEntry := ActiveEntry + 1;
                InverseVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
              end;

            HomeKey:
              begin
                NormalVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
                ActiveEntry := 0;
                InverseVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
              end;

            EndKey:
              begin
                NormalVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
                ActiveEntry := NumberContests - 1;
                InverseVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
              end;

          end;
        end;

    else
      if ((Key >= 'A') and (Key <= 'Z')) or (Key = ' ') or ((Key >= '0') or (Key <= '9')) then
      begin
        EntryString := EntryString + Key;

        for Entry := 0 to NumberContests - 1 do
          if Copy(Contests[Entry], 1, length(EntryString)) = EntryString then
          begin
            NormalVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
            ActiveEntry := Entry;
            InverseVideo(ActiveEntry, StartY, NumberRows, Contests[ActiveEntry]);
            Break;
          end;
      end;
    end;
  until False;
end;

procedure ManualConfigFileGenerator;

var
  PortKey, TypeKey, PaddleKey, CWKey, Key, ColorKey, SimulatorKey: Char;
  FileName, ColorMode, MyState, MyName, MyQTH, TempString: Str20;
  FileString, ContestName     : Str80;
  TempQTH                     : QTHRecord;
  FileRead                    : Text;

begin
  //  ManualConfigurationTitle;

  //  if not CountryTable.LoadInCountryFile then
  //  begin
  //    ShowMessage('Unable to find CTY.DAT country file!!+Make sure this file is in the same directory as the program.');
  //    halt;
  //  end;

  MyName := '';
  MyState := '';
  MyQTH := '';

  //  MyCall := UpperCase(GetResponse('Enter your complete callsign (none to abort) : '));

  //  if MyCall = '' then
  //  begin
           //{WLI}        TextMode (LastMode);
  //    halt;
  //  end;

  //  LocateCall(MyCall, TempQTH, True);
  //  MyCountry := CountryTable.GetCountryID(TempQTH.Country);
  //  MyContinent := TempQTH.Continent;
  //  Str(TempQTH.Zone, MyZone);
  //  CountryString := MyCountry;
   // ContinentString := CountryTable.GetContinentName(MyContinent);

  //  ContestName := GetContestName;
  //
  //  if ContestName = '' then
  //  begin
           {        TextMode (LastMode);
                   ReportError ('No contest chosen.');
                  halt;}
  //  end;

  //  if not FoundContest(ContestName) then
  //  begin
           {        ReportError ('I am sorry - I do not know that contest.  Please tell N6TR.');
                   TextMode (LastMode);
                  }
  //                halt;
  //  end;

  if UpperCase(ContestName) = 'NEW ENGLAND QSO' then
  begin
      //    repeat
    if YesOrNo(0, 'Are you in New England?') = IDYES then
        {
              if Key = EscapeKey then
              begin
                          //                TextMode (LastMode);
                halt;
              end;

            until (Key = 'Y') or (Key = 'N');
            WriteLn;
            if Key = 'Y' then
            }
    begin

      MyState := GetResponse('Enter your New England state abreviation (ME, NH, VT, MA, CT, RI): ');
          {        until (UpperCase(Copy(MyState, 1, 2)) = 'ME') or
                    (UpperCase(Copy(MyState, 1, 2)) = 'NH') or
                    (UpperCase(Copy(MyState, 1, 2)) = 'VT') or
                    (UpperCase(Copy(MyState, 1, 2)) = 'MA') or
                    (UpperCase(Copy(MyState, 1, 2)) = 'CT') or
                    (UpperCase(Copy(MyState, 1, 2)) = 'RI');
                end;
               }MyState := (UpperCase(Copy(MyState, 1, 2)));
    end;

      {KK1L: 6.69}
    if UpperCase(ContestName) = 'FIELD DAY' then
    begin
      Key := UpCase(GetKey('Are you operating from North or South America? (Y/N) : '));
      if Key = 'Y' then
      begin
        MyFDClass := UpperCase(GetResponse('Enter your Field Day Class (2A, 1D, 34A, etc) : '));
        MySection := UpperCase(GetResponse('Enter your ARRL section or "DX" : '));
        WriteLn('Thanks!!  I will use this information to generate your CW messages.');
      end
      else
        MyFDClass := 'DX';
    end;

    if UpperCase(ContestName) = 'CAL QSO PARTY' then
    begin
      repeat
        Key := UpCase(GetKey('Are you in California? (Y/N) : '));

        if Key = EscapeKey then
        begin
                //                TextMode (LastMode);
          halt;
        end;

      until (Key = 'Y') or (Key = 'N');
      WriteLn;
      if Key = 'Y' then MyState := 'CA' else MyState := '';
    end;

      {KK1L: 6.71 One user configured WRTC instead of IARU. This is an attempt to eliminate that error.}
    if pos('WRTC', UpperCase(ContestName)) > 0 then
    begin
      repeat
        WriteLn('WRTC is by invitation only. It is different than the IARU HF Championship.');
        Key := UpCase(GetKey('Did you really mean to configure the IARU HF Championship instead? (Y/N) : '));

        if Key = EscapeKey then
        begin
                //                TextMode (LastMode);
          halt;
        end;

      until (Key = 'Y') or (Key = 'N');
      WriteLn;
      if Key = 'Y' then
      begin
        ContestName := 'IARU';
        WriteLn;
        WriteLn('I will set you up for the IARU HF Championship.');
        WriteLn;
      end;
    end;

    if UpperCase(ContestName) = 'FLORIDA QSO PARTY' then
    begin
      repeat
        Key := UpCase(GetKey('Are you in Florida? (Y/N) : '));

        if Key = EscapeKey then
        begin
                //                TextMode (LastMode);
          halt;
        end;

      until (Key = 'Y') or (Key = 'N');
      WriteLn;
      if Key = 'Y' then MyState := 'FL' else MyState := '';
    end;

    if UpperCase(ContestName) = 'MICH QSO PARTY' then
    begin
      repeat
        Key := UpCase(GetKey('Are you in Michigan? (Y/N) : '));

        if Key = EscapeKey then
        begin
                //                TextMode (LastMode);
          halt;
        end;

      until (Key = 'Y') or (Key = 'N');
      WriteLn;
      if Key = 'Y' then MyState := 'MI' else MyState := '';
    end;

    if UpperCase(ContestName) = 'MINN QSO PARTY' then
    begin
      repeat
        Key := UpCase(GetKey('Are you in Minnesota? (Y/N) : '));

        if Key = EscapeKey then
        begin
                //                TextMode (LastMode);
          halt;
        end;

      until (Key = 'Y') or (Key = 'N');
      WriteLn;
      if Key = 'Y' then MyState := 'MN' else MyState := '';
    end;

    if UpperCase(ContestName) = 'OHIO QSO PARTY' then
    begin
      repeat
        Key := UpCase(GetKey('Are you in Ohio? (Y/N) : '));

        if Key = EscapeKey then
        begin
                //                TextMode (LastMode);
          halt;
        end;

      until (Key = 'Y') or (Key = 'N');
      WriteLn;
      if Key = 'Y' then MyState := 'OH' else MyState := '';
    end;

    if UpperCase(ContestName) = 'SALMON RUN' then
    begin
      repeat
        Key := UpCase(GetKey('Are you in Washington? (Y/N) : '));

        if Key = EscapeKey then
        begin
                //                TextMode (LastMode);
          halt;
        end;

      until (Key = 'Y') or (Key = 'N');
      WriteLn;
      if Key = 'Y' then MyState := 'WA' else MyState := '';
    end;
{
    if UpperCase(ContestName) = 'STEW PERRY' then
    begin
      MyGrid := UpperCase(GetResponse('Enter your four digit grid square : '));
    end;
}
    if UpperCase(ContestName) = 'WISCONSIN QSO PARTY' then
    begin
      repeat
        Key := UpCase(GetKey('Are you in Wisconsin? (Y/N) : '));

        if Key = EscapeKey then
        begin
                //                TextMode (LastMode);
          halt;
        end;

      until (Key = 'Y') or (Key = 'N');
      WriteLn;
      if Key = 'Y' then MyState := 'WI' else MyState := '';
    end;

    if UpperCase(ContestName) = 'ARRL 10' then
      if (MyCountry = 'K') or (MyCountry = 'VE') or
        (MyCountry = 'KH6') or (MyCountry = 'KL') then
      begin
        MyState := UpperCase(GetResponse('Enter the QTH that you want to send : '));
        WriteLn('Thanks!!  I will use this information to generate your CW messages.');
      end;

    if UpperCase(ContestName) = 'SWEEPSTAKES' then
    begin
      MyPrec := UpperCase(GetResponse('Enter your precedence : '));
      MyCheck := UpperCase(GetResponse('Enter your check (last two digits of year licensed) : '));
      MySection := UpperCase(GetResponse('Enter your ARRL section : '));
      WriteLn('Thanks!!  I will use this information to generate your CW messages.');
    end;

    if UpperCase(ContestName) = 'SPRINT' then
    begin
      MyName := UpperCase(GetResponse('Enter the name you want to use : '));
      MyState := UpperCase(GetResponse('Enter your QTH that you want to send : '));
      WriteLn('Thanks!!  I will use this information to generate your CW messages.');
    end;

    if UpperCase(ContestName) = 'TEXAS QSO PARTY' then
    begin
      repeat
        Key := UpCase(GetKey('Are you in Texas? (Y/N) : '));

        if Key = EscapeKey then
        begin
                //                TextMode (LastMode);
          halt;
        end;

      until (Key = 'Y') or (Key = 'N');
      WriteLn;
      if Key = 'Y' then MyState := 'TX' else MyState := '';
    end;
      {
          TextColor (Cyan);

          WriteLn ('TR is about to save this information to your configuration file.  Normally,');
          WriteLn ('the configuration file is called LOGCFG.DAT.  However, you can choose to use');
          WriteLn ('a name that is more descriptive, like 98SSCW.CFG.  This will also allow you');
          WriteLn ('to have different contest files reside in the same directory.  Your log file');
          WriteLn ('will be named 98SSCW.LOG instead of LOG.DAT, and the RESTART.BIN file will be');
          WriteLn ('named 98SSCW.RST.  The LOG.TMP file would be named 98SSCW.TMP.');
          WriteLn;
          WriteLn ('If you have more than one set of files present when TR starts up, it will show');
          WriteLn ('you a menu of the different contest files, and you can select which one to use.');
          WriteLn;
      }
    repeat
      FileName := GetResponse('Enter filename or just RETURN to use the default names : ');

      if StringHas(FileName, '.') then FileName := PrecedingString(FileName, '.');

      if FileName = '' then
        FileName := 'LOGCFG.DAT'
      else
        FileName := FileName + '.CFG';

      if FileExists(@FileName[1]) then
      begin
        repeat
          Key := UpCase(GetKey(FileName + ' already exists.  Okay to overwrite? (Y/N) : '));

          if Key = EscapeKey then
          begin
                  //                TextMode (LastMode);
            halt;
          end;

        until (Key = 'Y') or (Key = 'N');
      end;

    until (not FileExists(@FileName[1])) or (Key = 'Y');

    if FileName = 'LOGCFG.DAT' then
      DeleteFile('RESTART.BIN')
    else
      DeleteFile(PrecedingString(FileName, '.') + '.RST');

//    SetUpFileNames(PrecedingString(FileName, '.'));

//    OpenFileForWrite(FileWrite, LogConfigFileName);

    WriteLn(FileWrite, 'MY CALL = ', MyCall);

    if MyQTH <> '' then WriteLn(FileWrite, 'MY QTH = ', MyQTH);
    if MyState <> '' then WriteLn(FileWrite, 'MY STATE = ', MyState);
    if MyName <> '' then WriteLn(FileWrite, 'MY NAME = ', MyName);
    if MyPrec <> '' then WriteLn(FileWrite, 'MY PREC = ', MyPrec);
    if MyCheck <> '' then WriteLn(FileWrite, 'MY CHECK = ', MyCheck);
    if MySection <> '' then WriteLn(FileWrite, 'MY SECTION = ', MySection);
    if MyFDClass <> '' then WriteLn(FileWrite, 'MY FD CLASS = ', MyFDClass); {KK1L: 6.69}

    WriteLn(FileWrite, 'CONTEST = ', ContestName);

    ManualConfigurationTitle;

    repeat
      ColorKey := UpCase(GetKey('Do you want to use the Color or Monochrome palette? (C/M) : '));

      if Key = EscapeKey then
      begin
            //                TextMode (LastMode);
        halt;
      end;

    until (ColorKey = 'C') or (ColorKey = 'M');
    WriteLn;

    if ColorKey = 'C' then WriteLn(FileWrite, 'DISPLAY MODE = COLOR');

    repeat
      SimulatorKey := UpCase(GetKey('Do you want to use the simulator? (Y/N) : '));

      if Key = EscapeKey then
      begin
            //                TextMode (LastMode);
        halt;
      end;

    until (SimulatorKey = 'Y') or (SimulatorKey = 'N');
    WriteLn;

    if SimulatorKey = 'Y' then
      WriteLn(FileWrite, 'SIMULATOR ENABLE = TRUE')

    else
    begin
      SetUpCWStuff;
      SetUpRadioStuff;
      SetUpPacketStuff;
      SetUpMultiStuff;
    end;

    Close(FileWrite);

      {    ClrScr;

          TextColor (Cyan);
          WriteLn ('Your config file has been saved as ', LogConfigFileName, '.  Here is what it');
          WriteLn ('looks like: ');
          WriteLn;
      }
//    OpenFileForRead(FileRead, LogConfigFileName);

    while not Eof(FileRead) do
    begin
      ReadLn(FileRead, FileString);
      WriteLn(FileString);
    end;

    Close(FileRead);
      //    WaitForKeyPressed;
  end;
end;

procedure PullLogCfgInformationOutOfThisPerson;

var
  Key                         : Char;

begin
  {    ClrScr;
      TextColor (Yellow);
      WriteLnCenter ('WELCOME TO THE TR LOGGING PROGRAM');
      WriteLn;
      TextColor (Cyan);
      WriteLn;

      REPEAT
          Key := UpCase (GetKey ('Do you want to step through setting up a new contest? (Y/N) : '));

          IF Key = EscapeKey THEN
              BEGIN
  //            TextMode (LastMode);
              Halt;
              END;

      UNTIL (Key = 'Y') OR (Key = 'N');
      WriteLn;

      IF Key = 'N' THEN
          BEGIN
          WriteLn;
          WriteLn ('Bye-bye');
  //        TextMode (LastMode);
          Halt;
          END;

     }

//  ManualConfigFileGenerator;
end;

begin
end.

