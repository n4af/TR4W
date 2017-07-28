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
unit CFGDEF;
{$IMPORTEDDATA OFF}
interface

uses
  Windows,
  LogDom,
  TF,
  VC,
  Tree,
  LogCW,
  LogWind,
  LogDupe,
  ZoneCont,
//  Country9,
  LogK1EA,
  LogStuff,
  LogPack,
  LOGDVP,
  //LOGDDX,
  LogGrid,
  LogNet,
  LOGWAE,
  LogRadio;

procedure SetConfigurationDefaultValues;

implementation
uses MainUnit;
{ Here are the default values that are used if nothing else in the
  configuration file addresses these variables.                     }

procedure SetConfigurationDefaultValues;
var
  c                                     : Char;
  TempString                            : ShortString;
begin
  //  ActiveBand := Band160;
  //  ActiveDomesticMult := NoDomesticMults;
      //  не нужно ActiveDVKPort := NoPort;
  //  ActiveDXMult := NoDXMults;
  //  ActiveExchange := NoExchangeReceived;
  //  ActiveFootSwitchPort := NoPort;
  //  ActiveInitialExchange := NoInitialExchange;
  //  ActiveKeyerPort := NoPort;
      //  не нужно ActiveModemPort := NoPort;
    ActiveMode := CW;        // 4.51.3
  //  ActivePaddlePort := NoPort;
  //  ActivePrefixMult := NoPrefixMults;
  //  ActiveQSOPointMethod := NoQSOPointMethod;
  //  ActiveRadio := RadioOne;
  //  ActiveRotatorType := NoRotator;
  //  ActiveStereoPort := NoPort;
  //  ActiveZoneMult := NoZoneMults;
  //  AllCWMessagesChainable := False;
  //  AltDBufferEnable := False;
  //  AlwaysCallBlindCQ := False;
  //  AskForFrequencies := {wli True} False;
  //  AskIfContestOver := True;
  //  AutoCallTerminate := False;
  //  AutoDupeEnableCQ := True;
  //  AutoDupeEnableSandP := True;
  //  AutoQSONumberDecrement := False;
  //  AutoReturnToCQMode := True;
  //  AutoSAPEnable := False;
  //  AutoSAPEnableRate := 1000; {KK1L 6.72}
  //  AutoSendCharacterCount := 0;
  //  AutoTimeIncrementQSOs := 0;

  //  BandMapAllBands := False;
  //  BandMapAllModes := False;
  //  BandMapMultsOnly := False; {KK1L: 6.68}
  //  BandMapCallWindowEnable := True;
  //  BandMapDisplayCQ := True;
  {
    BandMapModeCutoffFrequency[Band160] := 1840000;
    BandMapModeCutoffFrequency[Band80] := 3700000;
    BandMapModeCutoffFrequency[Band40] := 7100000;
    BandMapModeCutoffFrequency[Band30] := 10150000;
    BandMapModeCutoffFrequency[Band20] := 14100000;
    BandMapModeCutoffFrequency[Band17] := 18110000;
    BandMapModeCutoffFrequency[Band15] := 21150000;
    BandMapModeCutoffFrequency[Band12] := 24930000;
    BandMapModeCutoffFrequency[Band10] := 28300000;
    BandMapModeCutoffFrequency[Band6] := 50100000;
    BandMapModeCutoffFrequency[Band2] := 144200000;
  }
  //  BandMapDecayTime := 60;
  //  BandMapDecayValue := 60; {KK1L: 6.65}
  //  BandMapDecayMultiplier := 1; {KK1L: 6.65}
  //  BandMapDupeDisplay := True;
  //  BandMapGuardBand := 200;
  //  BeepEnable := True;
  //  BeepEvery10QSOs := False;
  //  не нужно BigRemainingList := False;
  //  BandMapSplitMode := ByCutoffFrequency; {KK1L: 6.64}

    CallsignUpdateEnable := True; // 4.61.2
  //  CallWindowPosition := NormalCallWindowPosition;
  //  CallWindowShowAllSpots := False;
  //  CfgDvpPath := '';
  //  CheckLogFileSize := False;
  //  CodeSpeed := 35;
  //  ColumnDupeSheetEnable := False;
  //  ComputerID := CHR(0);
  //  ContactsPerPage := 50;
  //  ConfirmEditChanges := True;
  //  ContestTitle := '';
  //  ContinentString := '';
//   CorrectedCallMessage := '} OK %';

//   CorrectedCallPhoneMessage := 'CORCALL.WAV';
  //  CountDomesticCountries := False;
  //  CountryInformationFile := '';
  //  CountryString := '';
  //  CQExchange := '';
  //  CQExchangeNameKnown := '';

     //   CQMenu := 'F1/2-CQ F3-Ex F4-73 F5-Call F6-DECall F7-WkdB4 F8-Agn F9-? F10-Keyboard CW';

  //  CQP := False;
//  CQPhoneExchange := 'CQECXHNG.WAV';
//  CQPhoneExchangeNameKnown := 'CQEXNAME.WAV';
  //  CustomInitialExchangeString := '';
  //  CustomUserString := '';
  //  CWEnable := True;
  //  CWEnabled := True;
  //  CWSpeedFromDataBase := False;
  //  CWTone := 700;

  //  DDXCall1 := '';
  //  DDXCall2 := '';
  //  DDXState := Off; //ini
  //  DEEnable := True;
  //  DigitalModeEnable := False;
  //  DistanceMode := NoDistanceDisplay;

     //   DoingColors := False;

  //  DomesticQTHDataFileName := '';
  //  DupeCheckSound := DupeCheckBeepIfDupe;
  //  DVPEnable := False;

//   Packet.PacketNumberBits := 7;

  //   EightBitRTTYPort := False; {KK1L: 6.71}

//  EnableSixDVKMessages := True; {KK1L: 6.72}
//  EscapeExitsSearchAndPounce := True;
  //   ExchangeFunctionKeyMenu := '';

//  windows.ZeroMemory(@ExchangeInformation, sizeof(ExchangeInformation));
{
 ExchangeInformation.Age := False;
 ExchangeInformation.Check := False;
 ExchangeInformation.ClassEI := False;
 ExchangeInformation.Name := False;
 ExchangeInformation.Precedence := False;
 ExchangeInformation.power := False;
 ExchangeInformation.RandomChars := False;
 ExchangeInformation.RST := False;
 ExchangeInformation.QSONumber := False;
 ExchangeInformation.QTH := False;
 ExchangeInformation.Zone := False;
 ExchangeInformation.ZoneOrSociety := False;
}
//  ExchangeMemoryEnable := True;

//  FarnsworthEnable := False;
//  FarnsworthSpeed := 25;

  //FloppyFileSaveName := 'logback.dat';
  //  FloppyFileSaveFrequency := 0;

  //  FootSwitchMode := FootSwitchDisabled;

  //  ForcedEntry := False; {KK1L: 6.70 switch used in JCTRL2 to add comments to LOGCFG}

//  FreqMemory[Band160, CW] := 1820000;
//  FreqMemory[Band80, CW] := 3525000;
//  FreqMemory[Band40, CW] := 7025000;
//  FreqMemory[Band30, CW] := 10105000;
//  FreqMemory[Band20, CW] := 14025000;
//  FreqMemory[Band17, CW] := 18068000;
//  FreqMemory[Band15, CW] := 21025000;
//  FreqMemory[Band12, CW] := 24890000;
//  FreqMemory[Band10, CW] := 28050000;
//  FreqMemory[Band6, CW] := 50125000;
//  FreqMemory[Band2, CW] := 144100000;
//  FreqMemory[Band222, CW] := 222100000;
//  FreqMemory[Band432, CW] := 433100000;
//  FreqMemory[Band902, CW] := 902000000;
//  FreqMemory[Band1296, CW] := 1296200000;
  //FreqMemory[Band2304, CW] := 2320200000;
  //FreqMemory[Band3456, CW] := 3400100000;
  //  FreqMemory[Band5760, CW] := 5760100000;

//  FreqMemory[Band160, Phone] := 1840000;
//  FreqMemory[Band80, Phone] := 3850000;
//  FreqMemory[Band40, Phone] := 7225000;
//  FreqMemory[Band30, Phone] := 10000000;
//  FreqMemory[Band20, Phone] := 14225000;
//  FreqMemory[Band17, Phone] := 18110000;
//  FreqMemory[Band15, Phone] := 21300000;
//  FreqMemory[Band12, Phone] := 24930000;
//  FreqMemory[Band10, Phone] := 28400000;
//  FreqMemory[Band6, Phone] := 50125000;
//  FreqMemory[Band2, Phone] := 144200000;
//  FreqMemory[Band222, Phone] := 222100000;
//  FreqMemory[Band432, Phone] := 433200000;
//  FreqMemory[Band902, Phone] := 902000000;
//  FreqMemory[Band1296, Phone] := 1296200000;
  //FreqMemory[Band2304, Phone] := 2320200000;
  //FreqMemory[Band3456, Phone] := 3400100000;
  //  FreqMemory[Band5760, Phone] := 5760100000;
    {
      FreqMemory[Band160, Digital] := 1840000;
      FreqMemory[Band80, Digital] := 3880000;
      FreqMemory[Band40, Digital] := 7040000;
      FreqMemory[Band30, Digital] := 10125000;
      FreqMemory[Band20, Digital] := 14080000;
      FreqMemory[Band17, Digital] := 18110000;
      FreqMemory[Band15, Digital] := 21080000;
      FreqMemory[Band12, Digital] := 24920000;
      FreqMemory[Band10, Digital] := 28080000;
    //  FreqMemory[Band6, Digital] := 50125000;
    //  FreqMemory[Band2, Digital] := 144200000;
    }
    //  FrequencyMemoryEnable := True;

    //  GridMapCenter := '';

    //  HFBandEnable := True;
    //  HourDisplay := ThisHour;

    //  IncrementTimeEnable := False;
    //  InitialExchangeCursorPos := AtEnd;
    //  InitialExchangeOverwrite := False; {KK1L: 6.70}
    //  InsertMode := True;
    //  IntercomFileenable := False;

    //  K1EANetworkEnable := False;
//  K5KA.ModeEnabled := False;
  //  KeypadCWMemories := False;

  //  LeaveCursorInCallWindow := False;
  //  LeadingZeros := 0;
  //  LeadingZeroCharacter := 'T';
  //  LiteralDomesticQTH := False;

  //  LogFrequencyEnable := False;
  //  LogRSTSent := '599';
  //  LogRSSent := '59';
  //  LogSubTitle := '';
  //  LogWithSingleEnter := False;
  //  LookForRSTSent := False;

  //  MessageEnable := True;
     //   ModemPortBaudRate := 4800;
  //  MultiInfoMessage := '';
  //  MultiMultsOnly := False;
  //  MultipleBandsEnabled := True;
  //  MultipleModesEnabled := True;
  //  MultiPortBaudRate := 4800;
  //  MultiRetryTime := 30;
  //  MultiUpdateMultDisplay := True;
  //  MultReportMinimumBands := 4;
  {
    MyCall := '';
    MyCheck := '';
    MyContinent := UnknownContinent;
    MyCountry := '';
    MyFDClass := '';
    MyGrid := '';
    MyIOTA := '';
    MyPostalCode := '';
    MyPrec := '';
    MySection := '';
    MyState := '';
    MyZone := '';
  }
  //  NameFlagEnable := True;
  //  NoLog := False;
  //  NoPollDuringPTT := False;

  //  PacketAddLF := False;
  //  PacketAutoCR := False;
  //  PacketMessMode := False;
  //  PacketReturnPerMinute := 0;
  //  PacketSpotComment := ''; {KK1L: 6.68} {KK1L: 6.71 moved here from LOGWIND.PAS}
  //  PacketSpotDisable := False;
  //  PacketSpotEditEnable := False;
  //  PacketSpotKey := '`';
  //  PacketSpotPrefixOnly := False; {KK1L: 6.72}

  Packet.PacketBandSpots := False;
  //  Packet.PacketBaudRate := 2400;
  Packet.PacketBeep := False;
  Packet.PacketLogFileName := '';
  Packet.PacketSpots := MultSpots;
  Packet.BroadcastAllPacketData := True;

  //  PaddleMonitorTone := 700;
  //  PaddleBug := False;
  //  PaddleSpeed := 0;
  //  ParameterOkayMode := Standard;
  //  PartialCallEnable := True;
  //  PartialCallLoadLogEnable := False;
  //  PartialCallMultsEnable := True;
//  PossibleCallAcceptKey := ';';
//  PossibleCallEnable := True;
//  PossibleCallLeftKey := ',';
//  PossibleCallRightKey := '.';

//  PrefixInfoFileName := '';
  //W_L_I  PrinterEnabled := False;
//  PTTEnable := True;

//  QSLMessage := 'TU \ TEST';
//  QSLPhoneMessage := 'QSL.WAV';
//  QSOBeforeMessage := ' SRI QSO B4 TU \ TEST';
//  QSOBeforePhoneMessage := 'QSOB4.WAV';
  //  QTCMinutes := False;
  //  QTCsEnabled := False;
  //  QSONumberByBand := False;
  //  QSOPointsDomesticCW := -1;
  //  QSOPointsDomesticPhone := -1;
  // QSOPointsDXCW := -1;
  //  QSOPointsDXPhone := -1;
  //  QSXEnable := True;
  //  QTCExtraSpace := True;
  //  QTCQRS := True;
//  QuickQSLKey1 := '\';
//  QuickQSLKey2 := '=';
//  QuickQSLMessage1 := 'TU';
//  QuickQSLMessage2 := 'EE';
//  QuickQSLPhoneMessage := 'QUICKQSL.WAV';
  {
    Radio1.CommandPause := 0;
    Radio1.FT1000MPCWReverse := False;
    Radio1.IDCharacter := CHR(0);
    Radio1.PollTimeout := 500; // one half second
    Radio1.RadioBaudRate := 4800;
    Radio1.RadioModel := NoInterfacedRadio;
    Radio1.RadioNumberBits := 8;
    Radio1.tr4w_CATPort := NoPort;
    Radio1.RadioStopBits := 2;
    Radio1.RadioParity := tNoParity;
    Radio1.ReceiverAddress := 4;
    Radio1.TrackingEnable := True;
    Radio1.UpdateSeconds := 0;

    Radio2.CommandPause := 0;

     //   RADIO1.FilterRadioMessageLength := False;
     //   radio2.FilterRadioMessageLength := False;

    Radio2.FT1000MPCWReverse := False;
    Radio2.IDCharacter := CHR(0);
    Radio2.PollTimeout := 500; // one half second

    Radio2.RadioBaudRate := 4800;
    Radio2.RadioModel := NoInterfacedRadio;
    Radio2.RadioNumberBits := 8;
    Radio2.tr4w_CATPort := NoPort;
    Radio2.RadioStopBits := 2;
    Radio2.RadioParity := tNoParity;
    Radio2.ReceiverAddress := 4;
    Radio2.TrackingEnable := True;
    Radio2.UpdateSeconds := 0;
  }

//  RadioOneName := 'Rig 1';
//  RadioTwoName := 'Rig 2';
//  RememberDDXCallsign := '';
//  RemoteTerminalPort := NoPort;
//  RepeatSearchAndPounceExchange := '';
//  RepeatSearchAndPouncePhoneExchange := 'RPTSPEX.WAV';

//  RTTYReceiveString := ControlR;
//  RTTYSendString := ControlT;

//  SayHiEnable := False;
//  SayHiRateCutOff := 200;

//  SCPDupeBackground := trWhite;
//  SCPDupeColor := trRed;
//  SCPMinimumLetters := 0;

//  SearchAndPounceExchange := '';
//  SearchAndPouncePhoneExchange := 'SAPEXCHG.WAV';
//  SendAltDSpotsToPacket := False;
//  SendCompleteFourLetterCall := False;
//  SendQSOImmediately := True;

  SetCQMemoryString(CW, F1, 'CQ TEST \  \ TEST');
  SetCQMemoryString(CW, F2, 'CQ TEST CQ TEST CQ TEST \  \ TEST');
  SetCQMemoryString(CW, F4, 'TU \ TEST');
  SetCQMemoryString(CW, F6, 'DE \');
  SetCQMemoryString(CW, F7, 'SRI QSO B4 TU \ TEST');
  SetCQMemoryString(CW, F8, 'AGN');
  SetCQMemoryString(CW, F9, '?');
  SetCQMemoryString(CW, F10, ':');

  SetCQMemoryString(CW, ControlF11, 'QRL?'); //wli

  SetEXMemoryString(CW, F8, 'EE');
  SetEXMemoryString(CW, F9, '?');
  SetEXMemoryString(CW, F10, ':');
  SetEXMemoryString(CW, AltF1, 'UR CALL?');
  SetEXMemoryString(CW, AltF2, 'AGN?');
  SetEXMemoryString(CW, AltF10, 'IS UR CALL @?');

{$IF LANG = 'RUS'}
  SetEXCaptionMemoryString(CW, F1, 'Мой позывной');
  SetEXCaptionMemoryString(CW, F2, 'Контр. номер');
{$ELSE}
 SetEXCaptionMemoryString(CW, F1, 'DE+Call');
  SetEXCaptionMemoryString(CW, F2, 'S&P Exchange');
  SetEXCaptionMemoryString(Phone, F2, 'S&P Exchange');

{$IFEND}

{$IF MMTTYMODE}

  SetCQMemoryString(CW, F1, 'CQ CQ \  \ TEST');
  SetCQMemoryString(CW, F2, 'CQ CQ CQ CQ CQ CQ \  \ TEST');

  SetCQMemoryString(CW, F9, '?');       // n4af 4.51.5 issue #185

  SetEXMemoryString(CW, F9, '?');        // n4af 4.5.5

  SetCQMemoryString(CW, F11, '<03>MM_GRABLASTCALL<04>');
  SetCQCaptionMemoryString(CW, F11, 'GRAB');

  SetEXMemoryString(CW, F11, '<03>MM_GRABLASTCALL<04>');
  SetEXCaptionMemoryString(CW, F11, 'GRAB');

  LeadingZeroCharacter := '0';
  Short0 := '0';
  Short1 := '1';
  Short9 := '9';
  DigitalModeEnable := True;
{$IFEND}

  for c := F1 to F12 do
  begin
    TempString[0] := CHR(Format(@TempString[1], 'CQF%u.WAV', Ord(c) - 111));
    SetCQMemoryString(Phone, c, TempString);
//    SetCQMemoryString(Phone, c, 'CQF' + IntToStr(Ord(c) - 111) + '.WAV');
  end;

  SetEXMemoryString(Phone, F1, 'MYCALL.WAV');

  for c := F3 to F12 do
  begin
    TempString[0] := CHR(Format(@TempString[1], 'EXF%u.WAV', Ord(c) - 111));
    SetEXMemoryString(Phone, c, TempString);
//    SetEXMemoryString(Phone, c, 'EXF' + IntToStr(Ord(c) - 111) + '.WAV');
  end;

  for c := AltF1 to AltF12 do
  begin
    TempString[0] := CHR(Format(@TempString[1], 'ALTEXF%u.WAV', Ord(c) - 135));
    SetEXMemoryString(Phone, c, TempString);
    //SetEXMemoryString(Phone, c, 'ALTEXF' + IntToStr(Ord(c) - 135) + '.WAV');
  end;

  Sheet.DupeSheetEnable := True;

  //  ShiftKeyEnable := True;

  //  Short0 := 'T';
  //  Short1 := 'A';
  //  Short2 := '2';
  //  Short9 := 'N';
  //  ShortIntegers := False;
  //  ShowSearchAndPounce := False;
  //  SingleBand := All;
  //  SingleRadioMode := False;
  //  SkipActiveBand := False;
  //  SpaceBarDupeCheckEnable := True;
  //  SprintQSYRule := False;
  {
    StartingFrequencies[Band160] := 1800000;
    StartingFrequencies[Band80] := 3500000;
    StartingFrequencies[Band40] := 7000000;
    StartingFrequencies[Band30] := 10000000;
    StartingFrequencies[Band20] := 14000000;
    StartingFrequencies[Band17] := 18000000;
    StartingFrequencies[Band15] := 21000000;
    StartingFrequencies[Band12] := 24000000;
    StartingFrequencies[Band10] := 28000000;
    StartingFrequencies[Band6] := 50000000;
    StartingFrequencies[Band2] := 144000000;
  }
  //  StartSendingNowKey := '''';

  {
    StoppingFrequencies[Band160] := 2000000;
    StoppingFrequencies[Band80] := 4000000;
    StoppingFrequencies[Band40] := 7500000;
    StoppingFrequencies[Band30] := 11000000;
    StoppingFrequencies[Band20] := 14500000;
    StoppingFrequencies[Band17] := 19000000;
    StoppingFrequencies[Band15] := 21500000;
    StoppingFrequencies[Band12] := 25000000;
    StoppingFrequencies[Band10] := 30000000;
    StoppingFrequencies[Band6] := 54000000;
    StoppingFrequencies[Band2] := 148000000;
  }
  //  SwapPacketSpotRadios := False;
  //  SwapPaddles := False;
  //  SwapRadioRelaySense := False;

  //  TabMode := NormalTabMode;
  //  TailEndKey := ']';
  //  TailEndMessage := 'R';
  //  TailEndPhoneMessage := 'TAILEND.WAV';
  //  TenMinuteRule := NoTenMinuteRule;
  //  TuneWithDits := False;
  //  TuneDupeCheckEnable := False; {KK1L: 6.73}
  //  TwoRadioState := TwoRadiosDisabled;

  //  UnknownCountryFileEnable := False;
  //  UnknownCountryFileName := 'UNKNOWN.CTY';
  //  UpdateRestartFileEnable := True;
     //   UseBIOSKeyCalls := False;
  //  UserInfoShown := NoUserInfo;

     //   VGADisplayEnable := true;
  //  VHFBandsEnabled := False;
     //   VisibleDupesheetEnable := False;

  //  WakeUpTimeOut := 0;
  //  WaitForStrength := True;
  //  WARCBandsEnabled := False;
  //  WildCardPartials := True;
{
  with MonoColors do
    begin
      AlarmWindowBackground := Black;
      AlarmWindowColor := White;
      AltCallWindowBackground := Black;
      AltCallWindowColor := White;
      BandMapWindowBackground := Black;
      BandMapWindowColor := White;
      BandModeWindowBackground := Black;
      BandModeWindowColor := White;
      BeamHeadingWindowBackground := Black;
      BeamHeadingWindowColor := White;
      BigWindowBackground := Black;
      BigWindowColor := White;
      CallWindowBackground := Black;
      CallWindowColor := White;
      ClockWindowBackground := Black;
      ClockWindowColor := White;
      CodeSpeedWindowBackground := Black;
      CodeSpeedWindowColor := White;
      ContestTitleWindowBackground := Black;
      ContestTitleWindowColor := White;
      CountryNameWindowBackground := Black;
      CountryNameWindowColor := White;
      DateWindowBackground := Black;
      DateWindowColor := White;
      DupeInfoWindowBackground := Black;
      DupeInfoWindowColor := White;
      DupeSheetWindowBackground := Black;
      DupeSheetWindowColor := White;
      EditableLogWindowBackground := Black;
      EditableLogWindowColor := White;
      ExchangeSAndPWindowBackground := Black;
      ExchangeWindowBackground := Black;
      ExchangeWindowColor := White;
      FreeMemoryWindowBackground := Black;
      FreeMemoryWindowColor := White;

      FrequencyOneWindowBackground := Black;
      FrequencyTwoWindowBackground := Black;

      FrequencyOneWindowColor := White;
      FrequencyTwoWindowColor := White;

      FrequencyOneWindowHighlight := White;
      FrequencyTwoWindowHighlight := White;

      FunctionKeyWindowBackground := Black;
      FunctionKeyWindowColor := White;
      InsertWindowBackground := Black;
      InsertWindowColor := White;
      MultiplierInformationWindowBackground := Black;
      MultiplierInformationWindowColor := White;
      NamePercentageWindowBackground := Black;
      NamePercentageWindowColor := White;
      NameSentWindowBackground := Black;
      NameSentWindowColor := White;

      PossibleCallWindowBackground := Black;
      PossibleCallWindowColor := White;
      PossibleCallWindowDupeBackground := Black;
      PossibleCallWindowDupeColor := Yellow;

      QSOInformationWindowBackground := Black;
      QSOInformationWindowColor := White;
      QSONumberWindowBackground := Black;
      QSONumberWindowColor := White;
      QTCNumberWindowBackground := Black;
      QTCNumberWindowColor := White;
      QuickCommandWindowBackground := Black;
      QuickCommandWindowColor := White;
      RadioOneWindowBackground := Black;
      RadioOneWindowColor := White;
      RadioTwoWindowBackground := Black;
      RadioTwoWindowColor := White;
      RateWindowBackground := Black;
      RateWindowColor := White;
      RTTYWindowBackground := Black;
      RTTYWindowColor := White;
      RemainingMultsWindowBackground := Black;
      RemainingMultsWindowColor := White;
      RemainingMultsWindowSubdue := Black;
      TotalScoreWindowBackground := Black;
      TotalScoreWindowColor := White;
      TotalWindowBackground := Black;
      TotalWindowColor := White;
      UserInfoWindowColor := White;
      UserInfoWindowBackground := Black;
      WholeScreenColor := White;
      WholeScreenBackground := Black;
    end;
}

//  with ColorColors do
//  begin
//    AlarmWindowBackground := trRed;
//    AlarmWindowColor := trBlack;
      //      AltCallWindowBackground := clBlue; //KK1L: 6.73
      //      AltCallWindowColor := clLightGray; //KK1L: 6.73
      {
            BandMapWindowBackground := clCyan;
            BandMapWindowColor := clBlack;
            BandModeWindowBackground := Cyan;
            BandModeWindowColor := clBlack;
            BeamHeadingWindowBackground := White;
            BeamHeadingWindowColor := clBlack;
            BigWindowBackground := Cyan;
            BigWindowColor := clBlack;
}
    //CallWindowBackground := trWhite {trMagenta};
    //CallWindowColor := trBlack {trYellow};
      {
                  ClockWindowBackground := Cyan;
                  ClockWindowColor := clBlack;

                  CodeSpeedWindowBackground := Cyan;
                  CodeSpeedWindowColor := clBlack;

                  ContestTitleWindowBackground := White;
                  ContestTitleWindowColor := clBlack;

                  CountryNameWindowBackground := Cyan;
                  CountryNameWindowColor := clBlack;

                  DateWindowBackground := Cyan;
                  DateWindowColor := clBlack;

                  DupeInfoWindowBackground := Cyan;
                  DupeInfoWindowColor := clBlack;

                  DupeSheetWindowBackground := Cyan;
                  DupeSheetWindowColor := clBlack;
      }
//    EditableLogWindowBackground := trWhite {trCyan};
//    EditableLogWindowColor := trBlack;
//    ExchangeSAndPWindowBackground := trGreen;

      {
                  ExchangeWindowBackground := Magenta;
                  ExchangeWindowColor := Yellow;

                  FreeMemoryWindowBackground := White;
                  FreeMemoryWindowColor := clBlack;
            }
//    FrequencyOneWindowBackground := trBtnFace;
//    FrequencyOneWindowColor := trLightGray;
//    FrequencyOneWindowHighlight := trBlack;

//    FrequencyTwoWindowBackground := trBtnFace;
//    FrequencyTwoWindowColor := trLightGray;
//    FrequencyTwoWindowHighlight := trBlack;
      {
            FunctionKeyWindowBackground := White;
            FunctionKeyWindowColor := clBlack;

            InsertWindowBackground := Cyan;
            InsertWindowColor := clBlack;

            MultiplierInformationWindowBackground := Cyan;
            MultiplierInformationWindowColor := clBlack;

            NamePercentageWindowBackground := Cyan;
            NamePercentageWindowColor := clBlack;

            NameSentWindowBackground := Cyan;
            NameSentWindowColor := clBlack;

            PossibleCallWindowBackground := Cyan;
            PossibleCallWindowColor := clBlack;

            PossibleCallWindowDupeBackground := clBlack;
            PossibleCallWindowDupeColor := Red;

            QSOInformationWindowBackground := Cyan;
            QSOInformationWindowColor := clBlack;

            QSONumberWindowBackground := Cyan;
            QSONumberWindowColor := clBlack;

            QTCNumberWindowBackground := Cyan;
            QTCNumberWindowColor := clBlack;

            QuickCommandWindowBackground := White;
            QuickCommandWindowColor := clBlue;

            RadioOneWindowBackground := Cyan; //KK1L: 6.73 Changed from RadioWindowBackground
            RadioOneWindowColor := clBlack; //KK1L: 6.73 Changed from RadioWindowColor
            RadioTwoWindowBackground := Cyan; //KK1L: 6.73
            RadioTwoWindowColor := clBlack; //KK1L: 6.73
            RateWindowBackground := Cyan;
            RateWindowColor := clBlack;
      }
//    RemainingMultsWindowBackground := trLightBlue {trBlue};
//    RemainingMultsWindowColor := trWhite;
//    RemainingMultsWindowSubdue := trCyan;
      {
            RTTYWindowColor := Cyan;
            RTTYWindowBackground := clBlack;
            RTTYInverseWindowColor := clBlack;
            RTTYInverseWindowBackground := White;

            TotalScoreWindowBackground := White;
            TotalScoreWindowColor := clBlack;

            TotalWindowBackground := clBlue;
            TotalWindowColor := White;

            UserInfoWindowBackground := clBlue;
            UserInfoWindowColor := White;

            WholeScreenColor := Yellow;

      }
//    WholeScreenBackground := trBtnFace;
//  end;

  //  SelectedColors := MonoColors;

//  SelectedColors := ColorColors;

end;

end.

