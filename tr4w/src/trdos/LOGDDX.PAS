unit LOGDDX;

{$IMPORTEDDATA OFF}
interface

uses {Dos, Printer, } Tree,
  VC,
  Windows,
  Country9,
  ZoneCont,
  LogSCP,
  LogWind,
  LogCW,
  LogDupe,
  LogGrid,
//  Help,
  LogK1EA,
  LOGDVP,
  LogDom,
  LogStuff,
  LogEdit;

type
  DDXActivity = (MaybeSendANewCall,
    MaybeRespondToMyCall,
    NormalContactComplete,
    QSLMyExchange,
    RepeatCallsign,
    RepeatExchange,
    SendCorrectedCallMessage,
    SendExchange,
    SendNewCall,
    VerifyContact);

  DDXStates = (Off,
    CallSentInResponseToACQ,
    CQExchangeSent,
    CQSent,
    QTCInProgress,
    ReadyForAnotherCall,
    RepeatCall,
    SAndPExchangeSent,
    SAndPExchangeSentAndAskedForQTC,
    StandBy,
    WaitingForCQ,
    WaitingForYourCall,
    WaitingForYourExchange);

var
  DDXState                              : DDXStates = Off;
  DDXCall1                              : CallString;
  DDXCall2                              : CallString;
  DDXNextExchange                       : Str20;
  DDXNextExCall                         : CallString;
  DDXTone1                              : integer;
  DDXTone2                              : integer;
  RememberDDXCallsign                   : CallString;

function DDX(Activity: DDXActivity): boolean;

procedure DDXAnswerACQ(var Call: CallString;
  var Tone: integer;
  StationToBeCalled: CallString);

function DDXExchange(SendingStation: CallString;
  ReceivingStation: CallString): Str80;

procedure DDXSendSAndPExchange(SendingStation: CallString;
  ReceivingStation: CallString;
  Tone: integer);
function GetNextCallFromReadInLog: CallString;
function GetRandomDDXCallsign(Exchange: ExchangeType): CallString;
function GetRandomDomesticQTH(Call: CallString): Str80;

implementation

function RandomRST: Str20;

begin
  case Random(40) of
    0: RandomRST := '559 ';
    1: RandomRST := '569 ';
    2: RandomRST := '579 ';
    3: RandomRST := '589 ';
    4..9: RandomRST := '599 ';
    10..25: RandomRST := '5NN ';
  else RandomRST := '5NN';
  end;
end;

function PossiblyMakeCallsignRare(InputCall: CallString): CallString;

var
  ID, Call                              : CallString;
  Country                               : integer;

begin
  if Random(15) = 0 then
  begin
    repeat
      repeat
        Call := CD.GetRandomCall;
      until (pos('?', Call) = 0);

      Country := CountryTable.GetCountry(Call, True);
      ID := CountryTable.GetCountryID(Country);
    until (ID <> 'DA') and (ID <> 'F') and
      (ID <> 'EA') and (ID <> 'HC') and
      (ID <> 'HL') and (ID <> 'LA') and
      (ID <> 'LZ') and (ID <> 'OE') and
      (ID <> 'G') and (ID <> 'HA') and
      (ID <> 'HB') and (ID <> 'I') and
      (ID <> 'JA') and (ID <> 'OH') and
      (ID <> 'OK') and (ID <> 'PA') and
      (ID <> 'SM') and (ID <> 'SP') and
      (ID <> 'UA') and (ID <> 'UA9') and
      (ID <> 'UR') and (ID <> 'LY') and
      (ID <> 'EU') and (ID <> '4L') and
      (ID <> 'VE') and (ID <> 'VK') and
      (ID <> 'K') and (ID <> 'YU') and
      (ID <> 'XE') and (ID <> 'KH6') and
      (ID <> 'KL') and (ID <> 'IS0');

    PossiblyMakeCallsignRare := Call;
  end
  else
    PossiblyMakeCallsignRare := InputCall;
end;

function GetRandomDDXCallsign(Exchange: ExchangeType): CallString;

var
  Country                               : integer;
  CountryID, Call                       : CallString;

begin
  Call := '';

  case Exchange of
    QSONumberNameDomesticOrDXQTHExchange:
      repeat
        Call := CD.GetRandomCall;
      until (DomesticCountryCall(Call)) and
        (pos('?', Call) = 0) and
        (CD.GetName(Call) <> '');

    ClassDomesticOrDXQTHExchange,
      QSONumberDomesticOrDXQTHExchange,
      QSONumberDomesticQTHExchange,
      //{WLI-DUP}        QSONumberNameDomesticOrDXQTHExchange,
    QSONumberPrecedenceCheckDomesticQTHExchange,
      RSTDomesticOrDXQTHExchange,
      RSTDomesticQTHExchange:
      begin
        if ActiveDomesticMult = DomesticFile then
        begin
        {
          if DomQTHTable.ActiveDomQTHFile = 'ARRLSECT' then
            repeat
              Call := CD.GetRandomCall;
            until (DomesticCountryCall(Call)) and (pos('?', Call) = 0);

          if DomQTHTable.ActiveDomQTHFile = 'HUNGARY' then
            repeat
              Call := CD.GetRandomCall;
            until CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) = 'HA';

          if (DomQTHTable.ActiveDomQTHFile[1] = 'S') and (DomQTHTable.ActiveDomQTHFile[4] = 'P') then
            repeat
              Call := CD.GetRandomCall;
            until (DomesticCountryCall(Call)) and (pos('?', Call) = 0);

          if DomQTHTable.ActiveDomQTHFile = 'SWISS' then
            repeat
              Call := CD.GetRandomCall;
            until CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) = 'HB';

          if DomQTHTable.ActiveDomQTHFile = 'JAPREF' then
            repeat
              Call := CD.GetRandomCall;
            until CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) = 'JA';
        }
        end;

      end;

    RSTAgeExchange:
      begin
        if MyContinent <> Asia then
        begin
          repeat
            Call := CD.GetRandomCall;
          until CountryTable.GetContinent(Call) = Asia;
        end
        else
        begin
          repeat
            Call := CD.GetRandomCall;
          until CountryTable.GetContinent(Call) <> Asia;
        end;
      end;

    RSTPowerExchange:
      begin
        repeat
          Call := CD.GetRandomCall;
        until not DomesticCountryCall(Call);
        Call := PossiblyMakeCallsignRare(Call);
      end;

    RSTQSONumberExchange,
      RSTZoneExchange:
      begin
        if ActiveZoneMult = JAPrefectures then
        begin
          repeat
            Call := CD.GetRandomCall
          until CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) = 'JA';
          GetRandomDDXCallsign := Call;
          Exit;
        end;

        if ContestName = 'Scandinavian Contest' then
        begin
          if ScandinavianCountry(MyCountry) then
          begin
            repeat
              Call := CD.GetRandomCall;
            until not ScandinavianCountry(CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)));
          end
          else
          begin
            repeat
              Call := CD.GetRandomCall;
            until ScandinavianCountry(CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)));
          end;

          GetRandomDDXCallsign := Call;
          Exit;
        end;

        case ActiveDXMult of
          ARRLDXCC: { Must be the JA INTL DX contest in Japan }
            begin
              repeat
                Call := CD.GetRandomCall;
              until CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) <> 'JA';
              GetRandomDDXCallsign := Call;
              Exit;
            end;

          CQDXCCWithNoUSAOrCanada,
            ARRLDXCCWithNoUSAOrCanada:
            repeat
              Call := CD.GetRandomCall;
              Call := PossiblyMakeCallsignRare(Call);
              CountryID := CountryTable.GetCountryID(CountryTable.GetCountry(Call, True));
            until (CountryID <> 'K') and (CountryID <> 'VE');

          ARRLDXCCWithNoUSACanadaKH6OrKL7,
            ARRLDXCCWithNoARRLSections:
            repeat
              Call := CD.GetRandomCall;
              Call := PossiblyMakeCallsignRare(Call);
              CountryID := CountryTable.GetCountryID(CountryTable.GetCountry(Call, True));
            until (CountryID <> 'K') and (CountryID <> 'VE') and
              (CountryID <> 'KH6') and (CountryID <> 'KL');

          ARRLDXCCWithNoIOrIS0:
            repeat
              Call := CD.GetRandomCall;
              Call := PossiblyMakeCallsignRare(Call);
              CountryID := CountryTable.GetCountryID(CountryTable.GetCountry(Call, True));
            until (CountryID <> 'I') and (CountryID <> 'IS0');

          CQNonEuropeanCountries, CQNonEuropeanCountriesAndWAECallRegions: {KK1L: 6.70 added for new WAE rules}
            begin
              repeat
                Call := CD.GetRandomCall;
                Call := PossiblyMakeCallsignRare(Call);
              until CountryTable.GetContinent(Call) <> Europe;
            end;

          CQEuropeanCountries:
            begin
              repeat
                Call := CD.GetRandomCall;
                Call := PossiblyMakeCallsignRare(Call);
              until CountryTable.GetContinent(Call) = Europe;
            end;

          CQDXCCWithNoHB9:
            repeat
              Call := CD.GetRandomCall;
              Call := PossiblyMakeCallsignRare(Call);
              CountryID := CountryTable.GetCountryID(CountryTable.GetCountry(Call, True));
            until (CountryID <> 'HB');

          NorthAmericanARRLDXCCWithNoUSACanadaOrkL7:
            begin
              repeat
                Call := CD.GetRandomCall;
                Call := PossiblyMakeCallsignRare(Call);
                CountryID := CountryTable.GetCountryID(CountryTable.GetCountry(Call, True));
              until (CountryID <> 'K') and (CountryID <> 'VE') and
                (CountryID <> 'KL') and
                (CountryTable.GetContinent(Call) = NorthAmerica);
            end;

          NonSouthAmericanCountries:
            begin
              repeat
                Call := CD.GetRandomCall;
                Call := PossiblyMakeCallsignRare(Call);
              until CountryTable.GetContinent(Call) <> SouthAmerica;
            end;

        else
          begin
            Call := CD.GetRandomCall;
            Call := PossiblyMakeCallsignRare(Call);
          end;

        end;
      end;

    RSTZoneOrSocietyExchange:
      begin
        Call := CD.GetRandomCall;
        Call := PossiblyMakeCallsignRare(Call);
      end;

  end;

  if Call = '' then Call := CD.GetRandomCall;

  GetRandomDDXCallsign := Call;
end;

procedure DDXAnswerACQ(var Call: CallString;
  var Tone: integer;
  StationToBeCalled: CallString);

{ This procedure can be called when you would like the DDX to answer a
  CQ that has just been sent by the LOG user.  If it decides to actually
  answer the CQ, it will set DDXState to AnsweredACQ, otherwise it will
  be left unchanged.  The parameter Call will be set to the callsign.
  This will be null if no call was made.  The parameter Tone is the tone
  the call was made at.  You will need to remember this so you can send
  the exchange at the same tone.                                          }

begin
  if (Random(15) > 0) or (CWTone = 0) then
  begin
    Call := GetRandomDDXCallsign(ActiveExchange);

    if CWTone <> 0 then
    begin
      Tone := Random(1000) + 200;

      case Random(15) of
        1: AddStringToBuffer('DE ' + Call, Tone);
        2: AddStringToBuffer(StationToBeCalled + ' DE ' + Call, Tone);
        3: AddStringToBuffer('DE ' + Call, Tone);
        4: AddStringToBuffer('DE ' + Call, Tone);
      else AddStringToBuffer(Call, Tone);
      end;
    end;

    DDXState := CallSentInResponseToACQ;
    RememberDDXCallsign := Call;
  end
  else
    Call := '';
end;

function GetRandomDomesticQTH(Call: CallString): Str80;

var
  TempString                            : Str80;
  QTH                                   : Str20;
  Number                                : Char;

begin
  TempString := NumberPartOfString(Call);
  Number := TempString[1];

//  if (ActiveDomesticMult = DomesticFile) and
//    ((DomQTHTable.ActiveDomQTHFile = 'JAPREF') or
//    (DomQTHTable.ActiveDomQTHFile = 'JAPREFCT')) then

    if CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) = 'JA' then
    begin
      case Number of
        '1': case Random(8) of
            0: QTH := 'TK';
            1: QTH := 'KN';
            2: QTH := 'CB';
            3: QTH := 'IB';
            4: QTH := 'ST';
            5: QTH := 'YN';
            6: QTH := 'TG';
            7: QTH := 'GM';
          end;

        '2': case Random(4) of
            0: QTH := 'AC';
            1: QTH := 'ME';
            2: QTH := 'SO';
            3: QTH := 'GF';
          end;

        '3': case Random(6) of
            0: QTH := 'KT';
            1: QTH := 'OS';
            2: QTH := 'WK';
            3: QTH := 'HG';
            4: QTH := 'SI';
            5: QTH := 'NR';
          end;

        '4': case Random(6) of
            0: QTH := 'OY';
            1: QTH := 'HS';
            2: QTH := 'YG';
            3: QTH := 'SN';
            4: QTH := 'TT';
            5: QTH := 'YG';
          end;

        '5': case Random(4) of
            0: QTH := 'KC';
            1: QTH := 'EH';
            2: QTH := 'KA';
            3: QTH := 'TS';
          end;

        '6': case Random(8) of
            0: QTH := 'KG';
            1: QTH := 'OT';
            2: QTH := 'KM';
            3: QTH := 'MZ';
            4: QTH := 'FO';
            5: QTH := 'SG';
            6: QTH := 'ON';
            7: QTH := 'NS';
          end;

        '7': case Random(6) of
            0: QTH := 'MG';
            1: QTH := 'AT';
            2: QTH := 'FS';
            3: QTH := 'YM';
            4: QTH := 'IT';
            5: QTH := 'AM';
          end;

        '8': case Random(14) of
            0: QTH := 'AB';
            1: QTH := 'HD';
            2: QTH := 'HY';
            3: QTH := 'IR';
            4: QTH := 'IS';
            5: QTH := 'KK';
            6: QTH := 'KR';
            7: QTH := 'NM';
            8: QTH := 'OM';
            9: QTH := 'RM';
            10: QTH := 'SB';
            11: QTH := 'SC';
            12: QTH := 'SY';
            13: QTH := 'TC';
          end;

        '9': case Random(3) of
            0: QTH := 'FI';
            1: QTH := 'TY';
            2: QTH := 'IK';
          end;

        '0': case Random(2) of
            0: QTH := 'NN';
            1: QTH := 'NI';
          end;
      end;
    end
    else
    begin
      QTH := GetContinentName(CountryTable.GetContinent(Call));
        {
                    case CountryTable.GetContinent(Call) of
                       Africa: QTH := 'AF';
                       Asia: QTH := 'AS';
                       Europe: QTH := 'EU';
                       NorthAmerica: QTH := 'NA';
                       SouthAmerica: QTH := 'SA';
                       Oceania: QTH := 'OC';
                    end;
        }
      GetRandomDomesticQTH := QTH;
      Exit;
    end;

  if CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) = 'KH6' then QTH := 'HAW';
  if CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) = 'KL' then QTH := 'AK';

  if CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) = 'VE' then
  begin
    case Number of
      '1', '9':
        begin
          case Random(4) of
            0: QTH := 'NB';
            1: QTH := 'NS';
            2: QTH := 'PEI';
            3: QTH := 'NL';
          end;
          if Copy(Call, 1, 3) = 'VY1' then QTH := 'NT';
          if Copy(Call, 1, 3) = 'VO1' then QTH := 'NF';
        end;

      '2':
        if Copy(Call, 1, 3) = 'VY2' then
          QTH := 'LAB'
        else
          QTH := 'QUE';

      '3': QTH := 'ON';
      '4': QTH := 'MB';
      '5': QTH := 'SK';
      '6': QTH := 'AB';
      '7': QTH := 'BC';
      '8': QTH := 'NT';
    end;
  end;

  if CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) = 'KP4' then
    QTH := 'PR';

  if CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) = 'KP2' then
    QTH := 'VI';

  if CountryTable.GetCountryID(CountryTable.GetCountry(Call, True)) = 'K' then
  begin
    if Random(30) = 0 then
    begin
      Str(Random(10), TempString);
      Number := TempString[1];
    end;

    case Number of
      '1':
        if (ActiveExchange = QSONumberPrecedenceCheckDomesticQTHExchange) or
          (ActiveExchange = ClassDomesticOrDXQTHExchange) then
        begin
          case Random(7) of
            0: QTH := 'CT';
            1: QTH := 'EMA';
            2: QTH := 'WMA';
            3: QTH := 'ME';
            4: QTH := 'NH';
            5: QTH := 'RI';
            6: QTH := 'VT';
          end;
        end
        else
          case Random(6) of
            0: QTH := 'CT';
            1: QTH := 'MA';
            2: QTH := 'ME';
            3: QTH := 'NH';
            4: QTH := 'RI';
            5: QTH := 'VT';
          end;

      '2':
        if (ActiveExchange = QSONumberPrecedenceCheckDomesticQTHExchange) or
          (ActiveExchange = ClassDomesticOrDXQTHExchange) then
        begin
          case Random(6) of
            0: QTH := 'ENY';
            1: QTH := 'WNY';
            2: QTH := 'NLI';
            3: QTH := 'NNJ';
            4: QTH := 'SNJ';
            5: QTH := 'NNY';
          end;
        end
        else
          case Random(2) of
            0: QTH := 'NY';
            1: QTH := 'NJ';
          end;

      '3':
        if (ActiveExchange = QSONumberPrecedenceCheckDomesticQTHExchange) or
          (ActiveExchange = ClassDomesticOrDXQTHExchange) then
        begin
          case Random(4) of
            0: QTH := 'EPA';
            1: QTH := 'WPA';
            2: QTH := 'MD';
            3: QTH := 'DEL';
          end;
        end
        else
          case Random(4) of
            0: QTH := 'MD';
            1: QTH := 'PA';
            2: QTH := 'DEL';
            3: QTH := 'MD';
          end;

      '4':
        if (ActiveExchange = QSONumberPrecedenceCheckDomesticQTHExchange) or
          (ActiveExchange = ClassDomesticOrDXQTHExchange) then
        begin
          case Random(10) of
            0: QTH := 'ALA';
            1: QTH := 'NFL';
            2: QTH := 'GA';
            3: QTH := 'KY';
            4: QTH := 'NC';
            5: QTH := 'SC';
            6: QTH := 'TN';
            7: QTH := 'VA';
            8: QTH := 'SFL';
            9: QTH := 'WCF';
          end;
        end
        else
          case Random(12) of
            0: QTH := 'ALA';
            1, 8: QTH := 'FLA';
            2, 9: QTH := 'GA';
            3: QTH := 'KY';
            4: QTH := 'NC';
            5: QTH := 'SC';
            6, 10: QTH := 'TN';
            7, 11: QTH := 'VA';
          end;

      '5':
        if (ActiveExchange = QSONumberPrecedenceCheckDomesticQTHExchange) or
          (ActiveExchange = ClassDomesticOrDXQTHExchange) then
        begin
          case Random(8) of
            0: QTH := 'ARK';
            1: QTH := 'LA';
            2: QTH := 'MS';
            3: QTH := 'NM';
            4: QTH := 'OK';
            5: QTH := 'NTX';
            6: QTH := 'STX';
            7: QTH := 'WTX';
          end;
        end
        else
          case Random(9) of
            0: QTH := 'ARK';
            1: QTH := 'LA';
            2: QTH := 'MS';
            3: QTH := 'NM';
            4: QTH := 'OK';
            5, 6, 7, 8: QTH := 'TX';
          end;

      '6':
        if (ActiveExchange = QSONumberPrecedenceCheckDomesticQTHExchange) or
          (ActiveExchange = ClassDomesticOrDXQTHExchange) then
        begin
          case Random(9) of
            0: QTH := 'EBAY';
            1: QTH := 'LAX';
            2: QTH := 'SDGO';
            3: QTH := 'ORG';
            4: QTH := 'SBAR';
            5: QTH := 'SCV';
            6: QTH := 'SF';
            7: QTH := 'SJV';
            8: QTH := 'SV';
          end;
        end
        else
          QTH := 'CA';

      '7':
        if (ActiveExchange = QSONumberPrecedenceCheckDomesticQTHExchange) or
          (ActiveExchange = ClassDomesticOrDXQTHExchange) then
        begin
          case Random(9) of
            0: QTH := 'AZ';
            1: QTH := 'IDA';
            2: QTH := 'MT';
            3: QTH := 'NV';
            4: QTH := 'ORE';
            5: QTH := 'UT';
            6: QTH := 'WWA';
            7: QTH := 'EWA';
            8: QTH := 'WYO';
          end;
        end
        else
          case Random(12) of
            0, 8, 9: QTH := 'AZ';
            1: QTH := 'IDA';
            2: QTH := 'MT';
            3: QTH := 'NV';
            4: QTH := 'ORE';
            5: QTH := 'UT';
            6, 10, 11: QTH := 'WA';
            7: QTH := 'WYO';
          end;

      '8': case Random(7) of
          0, 3, 4: QTH := 'MI';
          1, 5, 6: QTH := 'OH';
          2: QTH := 'WVA';
        end;

      '9': case Random(5) of
          0, 3: QTH := 'IN';
          1, 4: QTH := 'IL';
          2: QTH := 'WI';
        end;

      '0': case Random(15) of
          0, 8, 9: QTH := 'CO';
          1, 10: QTH := 'IA';
          2: QTH := 'KS';
          3, 11, 12: QTH := 'MN';
          4, 13, 14: QTH := 'MO';
          5: QTH := 'NE';
          6: QTH := 'ND';
          7: QTH := 'SD';
        end;

    end; { of case statement }
  end;

  GetRandomDomesticQTH := QTH;
end;

function GetNextCallFromReadInLog: CallString;

var
  Band                                  : BandType;
  Mode                                  : ModeType;
  FileString                            : Str80;

begin
  GetNextCallFromReadInLog := '';

  if not ReadInLogFileOpen then
  begin
    if OpenFileForRead(ReadInLogFileRead, ReadInLogFileName) then
      ReadInLogFileOpen := True
    else
    begin
//      ReadInLog := False;
      Exit;
    end;
  end;

  while not Eof(ReadInLogFileRead) do
  begin
    repeat
      ReadLn(ReadInLogFileRead, FileString);
        {    FileString := UpperCase (FileString);    removed 6.27 }
      Band := GetLogEntryBand(FileString);
      Mode := GetLogEntryMode(FileString);
    until Eof(ReadInLogFileRead) or (Band <> NoBand);

    if (Band <> NoBand) and (Mode <> NoMode) then
    begin
      GetNextCallFromReadInLog := UpperCase(GetLogEntryCall(FileString));
      ReadInLogComputerID := GetLogEntryComputerID(FileString);
      ReadInLogDateString := GetLogEntryDateString(FileString);
      ReadinLogTimeString := GetLogEntryTimeString(FileString);
      ReadInLogExchange := GetLogEntryExchangeString(FileString);

      if StringHas(ReadInLogExchange, 'DUPE') then
        ReadInLogExchange := PrecedingString(ReadInLogExchange, 'DUPE');

      if not ((ActiveExchange = CheckAndChapterOrQTHExchange) or
        (ActiveExchange = ClassDomesticOrDXQTHExchange) or
        (ActiveExchange = NameAndDomesticOrDXQTHExchange) or
        (ActiveExchange = NameQTHAndPossibleTenTenNumber) or
        (ActiveExchange = NameAndPossibleGridSquareExchange) or
        (ActiveExchange = QSONumberDomesticOrDXQTHExchange) or
        (ActiveExchange = QSONumberDomesticQTHExchange) or
        (ActiveExchange = QSONumberNameChapterAndQTHExchange) or
        (ActiveExchange = QSONumberNameDomesticOrDXQTHExchange) or
        (ActiveExchange = QSONumberPrecedenceCheckDomesticQTHExchange)) then
        ReadInLogRST := RemoveFirstString(ReadInLogExchange);

      if (Mode <> ReadInLogMode) or (Band <> ReadInLogBand) then
      begin
        ActiveMode := Mode;
        ActiveBand := Band;

              {                IF ((ActiveRadio = RadioOne) AND (Radio1Type <> NoInterfacedRadio)) OR
                                 ((ActiveRadio = RadioTwo) AND (Radio2Type <> NoInterfacedRadio)) THEN
                                     DisplayBandMode (ActiveBand, ActiveMode, True)
                                 ELSE
                                     DisplayBandMode (ActiveBand, ActiveMode, False);
              }
        ReadInLogMode := Mode;
        ReadInLogBand := Band;
      end;

      Exit;
    end;
  end;

  Close(ReadInLogFileRead);
//  ReadInLog := False;
  ReadInLogFileOpen := False;
end;

function DDXExchange(SendingStation: CallString;
  ReceivingStation: CallString): Str80;

var
  CallSent                              : boolean;
  CharPointer, Power, QSONumber         : integer;
  NameString, QTHString, QSONumberString: Str20;
  TempString                            : Str40;
  CheckSection, Exchange                : ShortString;
  Number                                : Char;

begin
  case ActiveExchange of

    ClassDomesticOrDXQTHExchange:

      { We have the following five cases:
           1. InitialExchangeEntry is null.
           2. InitialExchangeEntry is complete exchange with space.
           3. InitialExchangeEntry is class only.
           4. InitialExchangeEntry is section only.
           5. InitialExchangeEntry is class and section.  }

      begin
        Exchange := InitialExchangeEntry(SendingStation);

        { Band aid to fix this is a space is at the start }

        GetRidOfPrecedingSpaces(Exchange);

        { Let's see if we need to add a class to the exchange 1 & 4 }

        if (Exchange = '') or (not StringIsAllNumbers(Copy(Exchange, 1, 1))) then
        begin
          case Random(20) of
            0, 1, 2, 3: QSONumber := 1;
            4, 5, 6: QSONumber := 2;
            7, 8: QSONumber := 3;
            9, 10: QSONumber := 4;
            11: QSONumber := 5;
            12: QSONumber := 6;
            13: QSONumber := 7;
            14: QSONumber := 8;
            15: QSONumber := 9;
            16: QSONumber := 10;
            17: QSONumber := 11;
            18: QSONumber := 12;
            19: QSONumber := 47;
          end;

          Str(QSONumber, QSONumberString);

          case Random(8) of
            0, 1, 2: Exchange := QSONumberString + 'A ' + Exchange;
            3, 4: Exchange := QSONumberString + 'B ' + Exchange;
            5: Exchange := QSONumberString + 'C ' + Exchange;
            6: Exchange := QSONumberString + 'D ' + Exchange;
            7: Exchange := QSONumberString + 'E ' + Exchange;
          end;
        end;

        { Do we need to add a section? 1 & 3 }

        if PostcedingString(Exchange, ' ') = '' then
          Exchange := Exchange + GetRandomDomesticQTH(SendingStation);

        DDXExchange := Exchange;
      end;

    QSONumberNameDomesticOrDXQTHExchange:
      begin
        CallSent := False;
        Exchange := ReceivingStation + ' ';

        if Random(2) = 0 then
        begin
          CallSent := True;
          Exchange := Exchange + SendingStation + ' ';
        end;

        if Random(3) = 0 then Exchange := Exchange + 'NR ';

        if SendingStation = DDXNextExCall then
          Exchange := Exchange + DDXNextExchange
        else
        begin
          QSONumber := Random(TotalContacts + 10) + 1;
          Str(QSONumber, QSONumberString);
          NameString := CD.GetName(SendingStation);
          QTHString := GetRandomDomesticQTH(SendingStation);

          Exchange := Exchange + QSONumberString + ' ' + NameString + ' '
            + QTHString;

          inc(QSONumber);
          Str(QSONumber, QSONumberString);

          DDXNextExchange := QSONumberString + ' ' + NameString + ' ' + QTHString;
          DDXNextExCall := SendingStation;
        end;

        if not CallSent then
          Exchange := Exchange + ' ' + SendingStation;

        DDXExchange := Exchange;
      end;

    QSONumberPrecedenceCheckDomesticQTHExchange:
      begin
        Str(Random(TotalContacts + 10 + (TotalContacts div 100)) + 1, Exchange);

        if Random(4) = 0 then
          while length(Exchange) < 3 do
            if Random(7) = 0 then
              Exchange := 'O' + Exchange
            else
              Exchange := '0' + Exchange;

        case Random(12) of
          0: Exchange := Exchange + ' ' + 'Q';
          1: Exchange := Exchange + ' ' + 'A';
          2: Exchange := Exchange + ' ' + 'B';
          3: Exchange := 'NR' + ' ' + Exchange + ' ' + 'Q';
          4: Exchange := 'NR' + ' ' + Exchange + ' ' + 'A';
          5: Exchange := 'NR' + ' ' + Exchange + ' ' + 'B';
          6: Exchange := ReceivingStation + Exchange + ' ' + 'Q';
          7: Exchange := ReceivingStation + Exchange + ' ' + 'A';
          8: Exchange := ReceivingStation + Exchange + ' ' + 'B';
          9: Exchange := ReceivingStation + ' NR' + ' ' + Exchange + ' ' + 'Q';
          10: Exchange := ReceivingStation + ' NR' + ' ' + Exchange + ' ' + 'A';
          11: Exchange := ReceivingStation + ' NR' + ' ' + Exchange + ' ' + 'B';
        end;

        CheckSection := InitialExchangeEntry(SendingStation);

        GetRidOfPrecedingSpaces(CheckSection);

        if CheckSection = '' then
        begin
          Str(Random(40) + 55, TempString);
          CheckSection := TempString + ' ' + GetRandomDomesticQTH(SendingStation);
        end
        else
          while pos('  ', CheckSection) > 0 do
            Delete(CheckSection, pos('  ', CheckSection), 1);

        DDXExchange := Exchange + ' ' + SendingStation + ' ' + CheckSection;
      end;

    RSTAgeExchange:
      begin
        Exchange := InitialExchangeEntry(SendingStation);

        GetRidOfPrecedingSpaces(Exchange);

        if Exchange = '' then
        begin
          Power := Random(60);
          if (Power > 0) and (Power < 12) then Power := Power + 25;
          Str(Power, Exchange);
        end;
        if Exchange = '0' then Exchange := '00';
        DDXExchange := RandomRST + Exchange;
      end;

    RSTDomesticQTHExchange:
      begin
        Exchange := InitialExchangeEntry(SendingStation);

        GetRidOfPrecedingSpaces(Exchange);

        if Exchange = '' then
          Exchange := GetRandomDomesticQTH(SendingStation);
        DDXExchange := RandomRST + Exchange;
      end;

    RSTPowerExchange:
      begin
        Exchange := InitialExchangeEntry(SendingStation);

        GetRidOfPrecedingSpaces(Exchange);

        if Exchange = '' then
        begin
          Power := Random(12);
          case Power of
            0: Exchange := '005';
            1: Exchange := '020';
            2: Exchange := '100';
            3: Exchange := '200';
            4: Exchange := '300';
            5: Exchange := '400';
            6: Exchange := '500';
            7: Exchange := '600';
            8: Exchange := '800';
            9: Exchange := '1000';
            10, 11: Exchange := 'KW';
          end;
        end;

        DDXExchange := RandomRST + Exchange;
      end;

    RSTQSONumberExchange:
      begin
        QSONumber := Random(100) + 1;
        if Random(5) = 0 then QSONumber := QSONumber * 10 + Random(10);
        Str(QSONumber, Exchange);

        if Random(2) = 0 then
        begin
          if QSONumber < 10 then Exchange := '0' + Exchange;
          if QSONumber < 100 then Exchange := '0' + Exchange;
        end;

        if Random(2) = 0 then
          for CharPointer := 1 to length(Exchange) do
          begin
            if Exchange[CharPointer] = '1' then Exchange[CharPointer] := 'A';
            if Exchange[CharPointer] = '9' then Exchange[CharPointer] := 'N';
            if Exchange[CharPointer] = '0' then Exchange[CharPointer] := 'T';
          end;

        DDXExchange := RandomRST + Exchange;
      end;

    RSTZoneExchange,
      RSTZoneOrSocietyExchange,
      RSTZoneAndPossibleDomesticQTHExchange:
      begin
        if ActiveZoneMult = JAPrefectures then
        begin
          TempString := NumberPartOfString(SendingStation);
          Number := TempString[1];

          case Number of
            '1': Str(Random(8) + 10, Exchange);
            '2': Str(Random(4) + 18, Exchange);
            '3': Str(Random(5) + 22, Exchange);
            '4': Str(Random(5) + 31, Exchange);
            '5': Str(Random(4) + 36, Exchange);
            '6': Str(Random(7) + 40, Exchange);
            '7': Str(Random(6) + 2, Exchange);
            '8': Exchange := '1';
            '9': Str(Random(3) + 28, Exchange);
            '0': Str(Random(2) + 8, Exchange);
          end;

          if length(Exchange) < 2 then Exchange := '0' + Exchange;
        end
        else
          Exchange := InitialExchangeEntry(SendingStation);

        GetRidOfPrecedingSpaces(Exchange);

        DDXExchange := RandomRST + Exchange;
      end;

  else
    DDXExchange := '';
  end;
end;

procedure DDXSendSAndPExchange(SendingStation: CallString;
  ReceivingStation: CallString;
  Tone: integer);

var
  CorrectDDXCallSent                    : boolean;
  Name                                  : Str20;

begin
  if CWTone = 0 then
  begin
    DDXState := SAndPExchangeSent;
    Exit;
  end;

  CorrectDDXCallSent := CallsignICameBackTo = SendingStation;
  Sleep(100);
  sleep(Random(200));

  if ReceivingStation = DDXCall1 then
    case Random(7) of
      0: AddStringToBuffer('R ', Tone);
      1: AddStringToBuffer('QSL ', Tone);
    end;

  if not CorrectDDXCallSent then
  begin
    if Random(2) = 0 then
    begin
      AddStringToBuffer('DE ' + SendingStation + ' ', Tone);
      CorrectDDXCallSent := True;
    end;
  end
  else
  begin
    Name := CD.GetName(ReceivingStation);

    if ReceivingStation = 'N6ZZ' then
      if Random(2) = 0 then Name := 'DICK';

    if Name <> '' then
      case Random(15) of
        0: AddStringToBuffer('HI ' + Name + ' ', Tone);
        1: AddStringToBuffer(ProperSalutation(ReceivingStation) + ' ' + Name + ' ', Tone);
        2: AddStringToBuffer('FB ' + Name + ' ', Tone);
      end;
  end;

  AddStringToBuffer(DDXExchange(SendingStation, ReceivingStation), Tone);

  if not CorrectDDXCallSent then
    AddStringToBuffer(' DE ' + SendingStation, Tone);

  DDXState := SAndPExchangeSent;

  if QTCsEnabled then
    if Random(5) = 0 then
    begin
      AddStringToBuffer(' QTC?', Tone);
      DDXState := SAndPExchangeSentAndAskedForQTC;
    end;
end;

function DDX(Activity: DDXActivity): boolean;

var
  Key                                   : Char;
  QSONumber, QTH                        : Str20;
  Tone                                  : integer;

begin
  DDX := True;
  if DDXState = Off then Exit;

  case Activity of
    MaybeSendANewCall:
      begin
        if DDXState <> WaitingForCQ then Exit;

        if (CWTone <> 0) then
        begin
          repeat until not CWStillBeingSent;
          sleep(100 + Random(200));
        end;

        DDXAnswerACQ(DDXCall1, DDXTone1, MyCall);

        if DDXState <> CallSentInResponseToACQ then
          DDXState := WaitingForCQ;
      end;

    RepeatCallsign:
      begin
        repeat until not CWStillBeingSent;

        if DDXState = CallSentInResponseToACQ then
          case Random(2) of
            0: AddStringToBuffer(DDXCall1, DDXTone1);
            1: AddStringToBuffer('DE ' + DDXCall1, DDXTone1);
          end;
      end;

    SendExchange:
      begin
        if CWTone <> 0 then
          repeat until not CWStillBeingSent;

        if DDXState = CallSentInResponseToACQ then
          DDXSendSAndPExchange(DDXCall1, MyCall, DDXTone1);
      end;

    VerifyContact:
      if (ReceivedData.Callsign <> RememberDDXCallsign) and (RememberDDXCallsign <> '') then
      begin
        DDX := False;
        repeat until not CWStillBeingSent;
        sleep(100);
        sleep(Random(300));

        if RememberDDXCallsign = DDXCall2 then
          Tone := DDXTone2
        else
          Tone := DDXTone1;

        case Random(4) of
          0: AddStringToBuffer('U GOT MY CALL WRONG DE ' + RememberDDXCallsign, Tone);
          1: AddStringToBuffer('PSE CORRECT MY CALL DE ' + RememberDDXCallsign, Tone);
          2: AddStringToBuffer('NO  MY CALL IS ' + RememberDDXCallsign, Tone);
          3: AddStringToBuffer(ReceivedData.Callsign + ' is wrong  DE ' + RememberDDXCallsign, Tone);
        end;
      end;

    NormalContactComplete:
      if SprintQSYRule then
      begin
        repeat
          if NewKeyPressed then
            if NewReadKey = EscapeKey then
            begin
              DDXState := WaitingForCQ;
              FlushCWBufferAndClearPTT;
              Exit;
            end;
        until not CWStillBeingSent;

        if Random(2) = 0 then
        begin
          sleep(200 + Random(200));

          while Random(2) = 0 do
          begin
            case Random(4) of
              0: AddStringToBuffer('CQ NA ' + DDXCall1, DDXTone1);
              1: AddStringToBuffer('NA ' + DDXCall1, DDXTone1);
              2: AddStringToBuffer('CQ NA ' + DDXCall1 + ' ' + DDXCall1 + ' NA', DDXTone1);
              3: AddStringToBuffer('NA ' + DDXCall1 + ' NA', DDXTone1);
            end;
            repeat until not CWStillBeingSent;
            sleep(1000 + Random(2000));
          end;
        end
        else
          sleep(50 + Random(100));

        repeat
          DDXAnswerACQ(DDXCall2, DDXTone2, DDXCall1);
        until DDXCall2 <> '';

        CallsignICameBackTo := DDXCall1;

        repeat
          if NewKeyPressed then
            if NewReadKey = EscapeKey then
            begin
              DDXState := WaitingForCQ;
              FlushCWBufferAndClearPTT;
              Exit;
            end;
        until not CWStillBeingSent;

        sleep(100 + Random(200));

        DDXSendSAndPExchange(DDXCall1, DDXCall2, DDXTone1);

        CallsignICameBackTo := DDXCall2;

        repeat
          if NewKeyPressed then
            if NewReadKey = EscapeKey then
            begin
              DDXState := WaitingForCQ;
              FlushCWBufferAndClearPTT;
              Exit;
            end;
        until not CWStillBeingSent;

        sleep(100 + Random(200));

        DDXSendSAndPExchange(DDXCall2, DDXCall1, DDXTone2);
        DDXState := CQSent;

        repeat
          if NewKeyPressed then
            if NewReadKey = EscapeKey then
            begin
              DDXState := WaitingForCQ;
              FlushCWBufferAndClearPTT;
              Exit;
            end;
        until not CWStillBeingSent;

        sleep(100 + Random(200));

        case Random(3) of
          0: AddStringToBuffer('TU', DDXTone1);
          1: AddStringToBuffer('EE', DDXTone1);
          2: AddStringToBuffer('QSL', DDXTone1);
        end;

        DDXState := WaitingForYourCall;

        repeat
          if NewKeyPressed then
            if NewReadKey = EscapeKey then
            begin
              DDXState := WaitingForCQ;
              FlushCWBufferAndClearPTT;
              Exit;
            end;
        until not CWStillBeingSent;

        while NewKeyPressed do Key := NewReadKey;

        DelayOrKeyPressed(200 + Random(200));
        if NewKeyPressed then Exit;

        repeat
          case Random(4) of
            0: AddStringToBuffer('CQ NA ' + DDXCall2, DDXTone2);
            1: AddStringToBuffer('NA ' + DDXCall2, DDXTone2);
            2: AddStringToBuffer('CQ NA ' + DDXCall2 + ' ' + DDXCall2 + ' NA', DDXTone2);
            3: AddStringToBuffer('NA ' + DDXCall2 + ' NA', DDXTone2);
          end;

          repeat
            if NewKeyPressed then
              if NewReadKey = EscapeKey then
              begin
                DDXState := WaitingForCQ;
                FlushCWBufferAndClearPTT;
                Exit;
              end;
          until not CWStillBeingSent;

          DelayOrKeyPressed(2000 + Random(2000));
          if NewKeyPressed then Exit;
        until False;
      end
      else
        DDXState := WaitingForCQ;

    MaybeRespondToMyCall:
      if DDXState = WaitingForYourCall then
      begin
        if CWTone <> 0 then
        begin
          repeat until not CWStillBeingSent;
          sleep(100 + Random(200));
        end;

        DDXSendSAndPExchange(DDXCall2, MyCall, DDXTone2);
        DDXState := WaitingForYourExchange;
      end;

    QSLMyExchange:
      if DDXState = WaitingForYourExchange then
      begin
        if CWTone <> 0 then
        begin
          repeat until not CWStillBeingSent;
          sleep(100 + Random(200));

          case Random(3) of
            0: AddStringToBuffer('TU', DDXTone2);
            1: AddStringToBuffer('EE', DDXTone2);
            2: AddStringToBuffer('QSL', DDXTone2);
          end;
        end;

        DDXState := WaitingForCQ;
      end;

  end;
end;

begin
  DDXNextExchange := '';
  DDXNextExCall := '';
  Debug := False;
end.


