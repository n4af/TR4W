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
unit FCONTEST;

{ PLEASE NOTE!!  This file is included with the TR Logging Program as a
  reference document.  It is intended to show you the default values for
  the different contests supported by the program.

  Changing parameters in this file will have no effect on the operation
  of TR or POST.

  Most variable names are the same as their LOGCFG commands, but in
  some cases, they are slightly different. }

{$IMPORTEDDATA OFF}

interface

uses
  VC,
  TF,
  utils_text,
  uCallSignRoutines,
  uRussiaOblasts,
  uCTYDAT,
  uMP3Recorder,
  utils_file,
  PostUnit,
  LogDom,
  Tree,
  LogCW,
  LogWind,
  LogDupe,
  ZoneCont,
  Windows;
//  Help,
//  Country9;


function FoundContest(CMD: ShortString): boolean;
procedure SetUpFileNames;
procedure RecalculateMyCountryContinentAndZone;
procedure RecalculateMyCountryContinentAndZoneNew(Call: CallString);
procedure SetContestTitle;
procedure Add_KVEKH6KL;
procedure Add_KVE;
procedure AddRussianDomesticCountrys;
function FoundMyStateInDomFile: boolean;
procedure EnumDOM2(FileString: PShortString);

procedure SetUpNameAndStateExchange;
procedure SetUpRSTQSONumberExchange;
procedure SetUpRSTMyStateExchange;
procedure SetUpRSTMyZoneExchange;

var
  InState                               : boolean;

implementation

uses LogGrid,
  LogStuff,
  MainUnit,
  LogSCP; {KK1L: 6.71 attempt to get POST to compile. Moved here from INTERFACE section.}

procedure SetUpFileNames;
var
  i                                     : integer;
begin

  Format(TR4W_POS_FILENAME, '%ssettings\tr4w.pos', TR4W_PATH_NAME);
  Format(TR4W_BANDMAPBIN_FILENAME, '%sbandmap.bin', TR4W_PATH_NAME);

//  asm push offset TR4W_PATH_NAME  end;
//  wsprintf(TR4W_IODRIVER_FILENAME, '%sTR4WIO.SYS');
//  asm add esp,12  end;

  Format(TR4W_COMM_HELP_FILENAME, '%scommands_help_' + LANG + '.ini', TR4W_PATH_NAME);

  Windows.CopyMemory(@TR4W_LOG_PATH_NAME, @TR4W_CFG_FILENAME, SizeOf(TR4W_LOG_PATH_NAME));
  for i := SizeOf(TR4W_LOG_PATH_NAME) - 1 downto 0 do
  begin
    if TR4W_LOG_PATH_NAME[i] = '\' then
    begin
      TR4W_LOG_PATH_NAME[i + 1] := #0;
      Break;
    end;
    if TR4W_LOG_PATH_NAME[i] = '.' then
    begin
      TR4W_LOG_PATH_NAME[i] := #0;

      Format(TR4W_LOG_FILENAME, '%s.TRW', TR4W_LOG_PATH_NAME);
      Format(TR4W_RST_FILENAME, '%s.RST', TR4W_LOG_PATH_NAME);
      Format(TR4W_DOM_FILENAME, '%s.DOM', TR4W_LOG_PATH_NAME);     // 4.100.2
    end;
  end;

  Format(TR4W_SYN_FILENAME, '%sSERVERLOG.TMP', TR4W_LOG_PATH_NAME);
  Format(TR4W_REMAININGMULTS_FILENAME, '%sREMAININGMULTS.TXT', TR4W_LOG_PATH_NAME);

  Format(TR4W_CTY_FILENAME, '%sCTY.DAT', TR4W_LOG_PATH_NAME);

  if not FileExists(TR4W_CTY_FILENAME) then
  begin
    Format(TR4W_CTY_FILENAME, '%sCTY.DAT', TR4W_PATH_NAME);    // n4af issue  # 219  & 212
  end;

  Format(CD.ActiveFilename, '%sTRMASTER.DTA', TR4W_LOG_PATH_NAME);

  if not FileExists(CD.ActiveFilename) then
  begin
    Format(CD.ActiveFilename, '%sTRMASTER.DTA', TR4W_PATH_NAME);
    if not FileExists(CD.ActiveFilename) then
    begin
      Format(@CD.ActiveFilename, '%sMASTER.DTA', TR4W_PATH_NAME);
    end;

  end;

{$IF MAKE_DEFAULT_VALUES = false}

  Format(TR4W_MP3PATH, '%sMP3', TR4W_LOG_PATH_NAME);



{$IFEND}

//   CD.ActiveFilename := TR4W_PATH_NAME + 'TRMASTER.DTA';
//  CTYDATFilename := TR4W_PATH_NAME + 'CTY.DAT';
//  BandMapFileName := TR4W_PATH_NAME + 'BANDMAP.BIN';

{ TR4W_LOG_PATH_NAME := TempFoldername;
  if TempFoldername = '' then
  begin
    TempFoldername := TR4W_PATH_NAME;
  end
  else
  begin
    if FileExists(TempFoldername + 'CTY.DAT') then CTYDATFilename := TempFoldername + 'CTY.DAT';
    if FileExists(TempFoldername + 'TRMASTER.DTA') then CD.ActiveFilename := TempFoldername + 'TRMASTER.DTA';
  end;
}
//  LogConfigFileName := TempFoldername + FileRoot + '.CFG';
//  LogRestartFileName := TempFoldername + FileRoot + '.RST';

  Format(TR4W_INTERCOM_FILENAME, '%sINTERCOM.TXT', TR4W_LOG_PATH_NAME);
  Format(TR4W_DEFMESSAGES_FILENAME, '%sCOMMONMESSAGES.INI', TR4W_PATH_NAME);


end;

procedure SetUpRSTMyZoneExchange;
var
  OldMyZone                             : string[31];
const
{$IF MMTTYMODE}
  Code599                               = '599';
{$ELSE}
  Code599                               = '5NN';
{$IFEND}
begin
  Windows.ZeroMemory(@OldMyZone, SizeOf(OldMyZone));

  if MyState <> '' then
    if ActiveExchange = RSTZoneAndPossibleDomesticQTHExchange then
    begin
      OldMyZone := MyZone;
      MyZone := MyZone + ' ' + MyState;
    end;

  CQExchange := ' ' + Code599 + ' ' + MyZone;
  SetCQMemoryString(CW, F3, ' ' + Code599 + ' ' + MyZone);
  SetEXMemoryString(CW, F3, Code599);
  SetEXMemoryString(CW, F4, MyZone);
  SetEXMemoryString(CW, F5, '@ DE \ ' + Code599 + ' ' + MyZone);
  SetEXMemoryString(CW, AltF3, 'RST?');
  SetEXMemoryString(CW, AltF4, 'NR?');
  RepeatSearchAndPounceExchange := ' ' + Code599 + ' ' + MyZone + ' ' + MyZone;
  SearchAndPounceExchange := ' ' + Code599 + ' ' + MyZone;

  if OldMyZone <> '' then MyZone := OldMyZone;
end;

procedure SetUpNameAndStateExchange;
begin
  CQExchange := ' ' + MyName + ' ' + MyState;
  RepeatSearchAndPounceExchange := CQExchange;
  SearchAndPounceExchange := CQExchange;
end;

procedure SetUpRSTMyStateExchange;
begin
  CQExchange := ' 5NN ' + MyState;
  RepeatSearchAndPounceExchange := '5NN ' + MyState;
  SearchAndPounceExchange := '~ %5NN ' + MyState;

  SetCQMemoryString(CW, F3, '5NN ' + MyState);

  SetEXMemoryString(CW, F3, '5NN');
  SetEXMemoryString(CW, F4, MyState);
  SetEXMemoryString(CW, F5, '@ DE \ 5NN ' + MyState);
  SetEXMemoryString(CW, AltF3, 'RST?');
  SetEXMemoryString(CW, AltF4, 'QTH?');
end;

procedure SetUpRSTQSONumberExchange;
begin
  CQExchange := ' 5NN #';
  RepeatSearchAndPounceExchange := ' 5NN #';
  SearchAndPounceExchange := ' 5NN #';
  SetCQMemoryString(CW, F3, '5NN #');

  SetEXMemoryString(CW, F3, '5NN');
  SetEXMemoryString(CW, F4, 'NR #');
  SetEXMemoryString(CW, F5, '@ DE \ 5NN #');
  SetEXMemoryString(CW, AltF3, 'RST?');
  SetEXMemoryString(CW, AltF4, 'NR?');

{$IF LANG = 'RUS'}
  SetEXCaptionMemoryString(CW, F4, '????? ?????');
  SetEXCaptionMemoryString(CW, F5, '??? ???????? + ?????');
{$ELSE}
  SetEXCaptionMemoryString(CW, F4, 'NR');
  SetEXCaptionMemoryString(CW, F5, 'Cl+Ex');
{$IFEND}

  SetEXCaptionMemoryString(CW, F3, 'RST');
end;

procedure AddARRLSectionDomesticCountries;
begin
  Add_KVEKH6KL;

  AddDomesticCountry('KC6');
  AddDomesticCountry('KG4');
  AddDomesticCountry('KH0');
  AddDomesticCountry('KH1');
  AddDomesticCountry('KH2');
  AddDomesticCountry('KH3');
  AddDomesticCountry('KH4');
  AddDomesticCountry('KH5');
  AddDomesticCountry('KH7');
  AddDomesticCountry('KH8');
  AddDomesticCountry('KH9');
  AddDomesticCountry('KP1');
  AddDomesticCountry('KP2');
  AddDomesticCountry('KP3');
  AddDomesticCountry('KP4');
  AddDomesticCountry('KP5');
end;

function FoundContest(CMD: ShortString): boolean;

var

  TempWord                              : Word;

  TempDomesticQTHDataFileName           : PChar;
  TmpBuf                                : array[0..255] of Char;
    TempOblast                          : Str2;
  i,j                                   : integer;
  k                                     : str10;
begin
  CTY.ctyCountryMode := ARRLCountryMode;  

  NoMultMarineMobile := False; {KK1L: 6.68 Added for WRTC 2002 as flag to not count /MM or /AM as mults or countries}

  ContestName := CMD;

//  Contest := GetContestFromString(CMD);
  if Contest <> DUMMYCONTEST then
  begin
    QSOByMode := ContestsBooleanArray[Contest] and (1 shl QSO_BY_MODE_BIT) <> 0;
    QSOByBand := ContestsBooleanArray[Contest] and (1 shl QSO_BY_BAND_BIT) <> 0;
    MultByMode := ContestsBooleanArray[Contest] and (1 shl MULT_BY_MODE_BIT) <> 0;
    MultByBand := ContestsBooleanArray[Contest] and (1 shl MULT_BY_BAND_BIT) <> 0;

    VHFBandsEnabled := ContestsBooleanArray[Contest] and (1 shl VHF_BAND_ENABLE_BIT) <> 0;

    CTY.ctyZoneMode := ZoneModeType(ContestsBooleanArray[Contest] and (1 shl CQ_ZONE_MODE_BIT) = 0);

    CountDomesticCountries := ContestsBooleanArray[Contest] and (1 shl CDC_BIT) <> 0;


    ActiveQSOPointMethod := ContestsArray[Contest].QP;
    ActiveExchange := ContestsArray[Contest].AE;
    ActiveInitialExchange := ContestsArray[Contest].AIE;

    ActiveDomesticMult := ContestsArray[Contest].dm;
    ActiveDXMult := ContestsArray[Contest].XM;
    ActiveZoneMult := ContestsArray[Contest].ZnM;
    ActivePrefixMult := ContestsArray[Contest].PxM;

    //if ActiveZoneMult = ITUZones then
    RecalculateMyCountryContinentAndZoneNew(MyCall);

    TempDomesticQTHDataFileName := nil;

    if ContestsArray[Contest].p <> 0 then
    begin
      if FoundMyStateInDomFile then
      begin
        TempDomesticQTHDataFileName := QSOParties[ContestsArray[Contest].p].InsideStateDOMFile;
        ContestName := ContestTypeSA[Contest] + ' (in state)';
      end
      else
      begin
        Windows.ZeroMemory(@TmpBuf, SizeOf(TmpBuf));
        Format(TmpBuf,'%s_cty',QSOParties[ContestsArray[Contest].p].InsideStateDOMFile);
        TempDomesticQTHDataFileName := @TmpBuf;//QSOParties[ContestsArray[Contest].p].OutsideStateDOMFile;
        ContestName := ContestTypeSA[Contest] + ' (out of state)';
        MultipliersIsCounties := True;
      end;
      Add_KVEKH6KL;
    end
    else
    begin
//      TempInt := StrLen(ContestsArray[Contest].DF);
//      DomesticQTHDataFileName[0] := CHR(TempInt);
//      Windows.CopyMemory(@DomesticQTHDataFileName[1], ContestsArray[Contest].DF, TempInt);
      TempDomesticQTHDataFileName := ContestsArray[Contest].DF;
    end;
  end;


  case Contest of

   LABRE:
   begin
  // if MyCountry <> 'PY' then
    //             activeexchange :=  RSTDomesticQTHExchange;
                  
    SetCQMemoryString(CW, F1, 'CQ TEST \ \ LABRE');
        SetCQMemoryString(CW, F2, 'CQ TEST \ \ LABRE');
        CQExchange := '5NN' + MyState;
        SearchAndPounceExchange :=  '5NN' + MyState;
        QSLMessage := '73 \ ';
    end;

  ARIZONAQSOPARTY:
   begin
   SetCQMemoryString(CW, F1, 'CQ AZ \ \ AZ');
        SetCQMemoryString(CW, F2, 'CQ^AZ CQ^AZ \ \ AZQP');
        CQExchange := MyState;
        SearchAndPounceExchange :=  MySTATE;
        QSLMessage := '73 \/AZ ';
    if  not FoundMyStateInDomFile then
     ActiveExchange := RSTDomesticQTHExchange
      else
      MultbyBand := False;

   end;

  NYQP:
  begin
   //ActiveDxMult := NoDXMults;
   ActiveDomesticMult := DomesticFile;
  end;

 { RSGBDX:
   begin
    if (myCountry[1] = 'G') or (myCountry[1] = 'M') then
     begin
      ActiveDXMult :=  CQDXCC;
      ActivePrefixMult := CQNonEuropeanCountriesAndWAECallRegions;
     end
      else
       begin
        ActiveDXMult := NoDXMults;
       end;;
   end;
 }
  BCQP:
  begin
  ActiveDXMult := NoDXMults;
    if MyCountry = 'VE7' then
       AddDomesticCountry('VE7');     // 4.97.8

   end;


    WINTERFIELDDAY:
      begin
        WARCBandsEnabled := False;
        SetCQMemoryString(CW, F1, 'CQ^WFD \ \ TEST');
        SetCQMemoryString(CW, F2, 'CQ^WFD CQ^WFD \ \ TEST');
        CQExchange := ' ' + MyFDClass + ' ' + MySection;
        SearchAndPounceExchange := MyFDClass + ' ' + MySection;
        QSLMessage := '73 \ WFD';
        ActiveDXMult := ARRLDXCCWithNoARRLSections;
        AddARRLSectionDomesticCountries;
      end;

    ARRLFIELDDAY:
      begin
        ActiveDomesticMult := DomesticFile;
        ActiveDXMult := NoDXMults;
        WARCBandsEnabled := False;         // WARC is not allowed during FD ny4i 4.45.3
        SetCQMemoryString(CW, F1, 'CQ^FD \ \ FD');
        SetCQMemoryString(CW, F2, 'CQ^FD CQ^FD \ \ FD');
        CQExchange := ' ' + MyFDClass + ' ' + MySection;
        SearchAndPounceExchange := MyFDClass + ' ' + MySection;
        QSLMessage := '73 \ FD';
        AddARRLSectionDomesticCountries;
        LiteralDomesticQTH := True;
      end;

      CROATIAN:
       begin
        if MyCountry = '9A' then
         ACTIVEDXMULT := CQDXCC;
       end;

    JIDXSSB, JIDXCW:
      begin
        if MyCountry = 'JA' then
        begin
          ActiveDXMult := ARRLDXCC;
          ActiveInitialExchange := ZoneInitialExchange;
          ActiveExchange := RSTZoneExchange;
          ActiveZoneMult := CQZones;
        end
        else
        begin
          ActiveDomesticMult := DomesticFile;
          ActiveExchange := RSTPrefectureExchange;
          TempDomesticQTHDataFileName := 'JIDX';
        end;

//        ContestName := 'Japan International DX Test';
//        CountryTable.ZoneMode := CQZoneMode;
      end;

    SOUTHAMERICANWW: //, SA-SSPRINT: // issue 177
      begin
        if MyContinent = SouthAmerica then
          ActivePrefixMult := NonSouthAmericanPrefixes
        else
          ActivePrefixMult := SouthAmericanPrefixes;
      end;

    STEWPERRY:
      begin
        ContestName := 'STEW-PERRY';      // 4.76.6
        CQExchange := ' ' + MyGrid;
        SearchAndPounceExchange := MyGrid;
        ActiveBand := Band160;
      end;

    ALLASIANCW, ALLASIANSSB:
      begin
        if MyContinent = Asia then
          ActiveDXMult := ARRLDXCC
        else
          ActivePrefixMult := Prefix;
      end;

    ALLJA, YOTA:
      begin
        ActiveBand := Band80;
//        VHFBandsEnabled := True;
      end;

    JALONGPREFECT:
      begin
        ActiveBand := Band80;
//        ContestName := 'JA PREFECTURE';
//        VHFBandsEnabled := False;
      end;

    ARCI:
      begin
//        ContestName := 'ARCI QSO PARTY';
        Add_KVEKH6KL;
      end;

    ARI_DX:
      begin
//        ContestName := 'ARI International DX Contest';
        AddDomesticCountry('I');
        AddDomesticCountry('IS');
        AddDomesticCountry('*IT9'); //WLI
      end;

    ARRL10:
      begin
        ActiveBand := Band10;
 //        ActiveExchange := RSTDomesticOrDXQTHExchange;    4.106.6
          ActiveDXMult := ARRLDXCCWithNoARRLSections;
//        ContestName := 'ARRL Ten Meter Contest';
 //       ExchangeMemoryEnable := False;      // 4.106.4
        MultipleBandsEnabled := False;
        Add_KVEKH6KL;
        AddDomesticCountry('XE');
      end;

    ARRL160:
      begin
        if ARRLSectionCountry(MyCountry) then
        begin
          ActiveExchange := RSTDomesticOrDXQTHExchange; {*}
          ActiveDXMult := ARRLDXCCWithNoARRLSections;
        end
        else
          ActiveExchange := RSTDomesticQTHExchange; {*}

//        ContestName := 'ARRL 160 Contest';
//        DomesticQTHDataFileName := 'ARRLSECT';
        AddARRLSectionDomesticCountries;
      end;

      ARRLDXCW, ARRLDXSSB:
      begin
        if (MyCountry = 'K') or (MyCountry = 'VE') then
        begin
          ActiveExchange := RSTPowerExchange; {*}
      ActiveDXMult := ARRLDXCCWithNoUSAOrCanada;
        end
        else
        begin
          ActiveDomesticMult := DomesticFile;
          TempDomesticQTHDataFileName := 'S48P14DC';
          ActiveExchange := RSTDomesticQTHExchange; {*}
    end;

        ContestName := 'ARRL DX Test';
        Add_KVE;
      end;

    ARRL_RTTY_ROUNDUP:
      begin
        Add_KVE;
      end;

{
    ARRLRTTYROUNDUP:
      begin
        CountryTable.CountryMode := CQCountryMode;
        CountryTable.ZoneMode := CQZoneMode;
        ActiveDomesticMult := DomesticFile;
        ActiveDXMult := ARRLDXCC;
//        ActiveExchange := RSTDomesticQTHOrQSONumberExchange;
//        ActiveQSOPointMethod := OnePointPerQSO;
        ContestName := 'ARRL RTTY ROUNDUP';
        DigitalModeEnable := True;
        //DomesticQTHDataFileName := 'S48P14DC'; //KK1L: 6.72 Used DC file instead per rules
        //QSOByBand := True;
        Add_KVE;
      end;
}
   WWDIGI:
      begin
      DigitalModeEnable := true;
      QSOByMode := False;
      QSOByBand := True;
 //     LiteralDomesticQTH := true;    // 4.91.5
      end;

    ARRLVHFJUN,ARRLVHFSEP:
      begin
        ActiveBand := Band6;
        ContestName := 'VHF QSO JUNE';
        HFBandEnable := False;
//        VHFBandsEnabled := True;
 //         MyState := MyGrid; //Copy(MyGrid, 1, 4);
      end;

 

    APSPRINT:
      begin
        ActiveBand := Band20;
//        ActivePrefixMult := Prefix;
//        ContestName := 'ASIA PACIFIC SPRINT';
      end;

    BALTIC:
      begin
        ActiveBand := Band80;
      end;
      
  //    BWQP:
  //    ActiveExchange := RSTPowerExchange;

    BATAVIA_FT8:
      begin
      DigitalModeEnable := true;
      QSOByMode := False;
      QSOByBand := True;
      end;


    CALQSOPARTY:
      begin

        if FoundMyStateInDomFile then
        begin

          ActiveExchange := QSONumberDomesticOrDXQTHExchange;

        end
        else
        begin
//          DomesticQTHDataFileName := 'CALCTY';
          ActiveExchange := QSONumberDomesticQTHExchange; {*}
        end;
//        ContestName := 'California QSO Party';
//        Add_KVEKH6KL;
      end;

    CIS:
      begin
        AddRussianDomesticCountrys;

        AddDomesticCountry('UR');
        AddDomesticCountry('EU');
        AddDomesticCountry('4J');
        AddDomesticCountry('EK');
        AddDomesticCountry('UN');
        AddDomesticCountry('EX');
        AddDomesticCountry('ER');
        AddDomesticCountry('EY');
        AddDomesticCountry('EZ');
        AddDomesticCountry('UK');
        AddDomesticCountry('4L');

        //??????, ???????, ????????, ???????????, ???????, ?????????, ??????????, ???????, ???????????,
        // ????????????, ?????????? ? ??????

//        CountDomesticCountries := True;
//        ContestName := 'CIS DX Contest';
      end;

    CQ160SSB, CQ160CW:
      begin
//        CountryTable.ZoneMode := CQZoneMode;
//        ActiveInitialExchange := ZoneInitialExchange;
        MultipleBandsEnabled := False;
        Add_KVE;
      end;

    CQM:
      begin
//        ContestName := 'CQ M Contest';
        CTY.ctyR150SMode := True;
      end;

    CQVHF:
      begin
        ActiveBand := Band2;
//        ContestName := 'CQ WORLD WIDE VHF Contest';
        HFBandEnable := False;
//        VHFBandsEnabled := True;
      end;

{
    CQWWRTTY:
      begin
        CountryTable.CountryMode := CQCountryMode;
        CountryTable.ZoneMode := CQZoneMode;

        ActiveDomesticMult := DomesticFile;
        ActiveDXMult := CQDXCC;
        ActiveExchange := RSTZoneAndPossibleDomesticQTHExchange;
        ActiveInitialExchange := ZoneInitialExchange;
//        ActiveQSOPointMethod := CQWWRTTYQSOPointMethod;
        ActiveZoneMult := CQZones;
        ContestName := 'CQ WW RTTY CONTEST';
        DigitalModeEnable := True;
        //DomesticQTHDataFileName := 'S48P13';
        //MultByBand := True;
        //QSOByBand := True;
        Add_KVE;
      end;
}

    EUSPRINT_SPRING_SSB, EUSPRINT_AUTUMN_CW, EUSPRINT_AUTUMN_SSB, EUSPRINT_SPRING_CW:
      begin
        ActiveBand := Band20;
//        ActiveInitialExchange := NameInitialExchange;
      end;

    RADIOVHFFD:
      begin
        HFBandEnable := False;
        ActiveBand := Band2;
        DigitalModeEnable := False;
        ContestName := 'RF-VHF-FD';
        QSOByMode := False;
        QSOByBand := True;
        QSONumberbyBand := True;
      end;
      



   EUROPEANVHF:
      begin
        ActiveBand := Band6;
//        ContestName := 'EUROPEAN VHF CONTEST';
        HFBandEnable := False;
//        VHFBandsEnabled := True;
      end;


  FOCMARATHON:
  ExchangeMemoryEnable := True;

    GENERALQSO:
      begin
        AutoDupeEnableCQ := False;
        AutoDupeEnableSandP := False;
        ContestName := 'General QSOs';
        WARCBandsEnabled := True;
      end;

    HADX:
      begin
        AddDomesticCountry('HA');
      end;

   IRTS:      // 4.93.1
    begin
     ActiveBand := Band80;
     DIGITALMODEENABLE := FALSE;
     INITIALEXCHANGECURSORPOS := ATSTART;
     if (MyCountry <> 'EI') and (MyCountry <> 'GI') then
      ActiveDXMult := NoDXMults;
    end;

      EUDX:  // 4.95.6
      begin
 //     AddDomesticCountry

      end;

   YUDX:                                // 4.57.5
      begin
      AddDomesticCountry('YU');
      if MyCountry = 'YU' then
       begin
         ActiveDomesticMult :=  NoDomesticMults  ;       // 4.57.7
         ActiveDXMult := ARRLDXCC;
       end
    end;

    UKEI:     // 4.58.2
      begin
       AddDomesticCountry('G');
       AddDomesticCountry('GD');
       AddDomesticCountry('GI');
       AddDomesticCountry('GJ');
       AddDomesticCountry('GM');
       AddDomesticCountry('GM');
       AddDomesticCountry('GW');
       AddDomesticCountry('GU');
       AddDomesticCountry('EI');
       if not UKEIStation(mycountry) then
        SetUpRSTQSONumberExchange;

      end;

    HELVETIA:
      begin
        if MyCountry = 'HB' then
          ActiveDXMult := ARRLDXCC  ;
      //  else          // 4.56.3 issue 232
          AddDomesticCountry('HB');
      end;


    OZCR_Z:
      begin
        ContestName := '????-??????? ????????? ?????? - ??????? ?????????';
      end;

   GagarinCup:
      begin
        CTY.ctyR150SMode := True;
        ContestName := 'Yuri Gagarin International DX Contest';
        QSOBYMODE := TRUE;
        INITIALEXCHANGEOVERWRITE := TRUE;
             end;

    INTERNETSPRINT:
      begin
        ActiveBand := Band20;
        AutoDupeEnableCQ := False;
        AutoDupeEnableSandP := False;
//        ContestName := 'Internet SprINT';
        ExchangeMemoryEnable := False;
        SprintQSYRule := True;

        SearchAndPounceExchange := '@ #   (   ' + MyState + ' \';
        RepeatSearchAndPounceExchange := '@ #   (   ' + MyState;
        CQExchange := ' \ #   (   ' + MyState;
        QSLMessage := 'EE';

        SetCQMemoryString(CW, F1, 'INT \');
        SetCQMemoryString(CW, F2, 'CQ^INT \ \ INT');

        SetCQMemoryString(CW, F5, '  ?');
        SetCQMemoryString(CW, F6, '  INT \');
        SetCQMemoryString(CW, F7, '  CQ^INT \ \ INT');
        SetCQMemoryString(CW, F8, '  CQ^INT CQ^INT \ \ INT');

        SetEXMemoryString(CW, F7, '  CQ^INT \ \ INT');
        SetEXMemoryString(CW, F8, '  CQ^INT CQ^INT \ \ INT');
        SetEXMemoryString(CW, F3, '#');
        SetEXMemoryString(CW, F4, '  (  ');
        SetEXMemoryString(CW, F5, MyState);
        SetEXMemoryString(CW, F6, '@ \ # ( ' + MyState);
        SetEXMemoryString(CW, AltF3, 'NR?');
        SetEXMemoryString(CW, AltF4, 'NAME?');
        SetEXMemoryString(CW, AltF5, 'QTH?');
        Add_KVE;
        AddDomesticCountry('KL');
      end;

      KCJ:
      begin
       ActiveInitialExchange := ZoneInitialExchange;   // 4.114.1
       InitialExchangeOverwrite := True;
      end;


    KIDSDAY:
      begin
        AutoDupeEnableCQ := False;
      end;

    KVP:
      begin
        ActiveBand := Band80;
//        ActiveInitialExchange := ZoneInitialExchange;
//        ActiveZoneMult := BranchZones;
//        ContestName := 'KV Prvenstvo ZRS';
      end;
{
    MICHQSOPARTY:
      begin
        if FoundMyStateInDomFile then
        begin
          DomesticQTHDataFileName := 'MIQP';
//          ActiveExchange := QSONumberDomesticQTHExchange; //KK1L: 6.73
        end
        else
        begin
          DomesticQTHDataFileName := 'MICHCTY';
//          ActiveExchange := QSONumberDomesticQTHExchange; //KK1L: 6.73
        end;
        Add_KVEKH6KL;
      end;
}
    MINNQSOPARTY:
      begin
{
        if FoundMyStateInDomFile then
          DomesticQTHDataFileName := 'MINNESOTA'
        else
          DomesticQTHDataFileName := 'MINNESOTA_CTY';

        Add_KVEKH6KL;
}
//        VHFBandsEnabled := True;
      end;

      MWC:
       begin
        ActiveBand := Band80;
        AddDomesticCountry('MWC');


       end;

       SST:
        begin
         ContestName := 'Slow Speed Test';
         ActiveDomesticMult := DomesticFile;
         Add_KVE;
         CQExchange := ' ' + MyName + ' ' + MyState;
         SearchAndPounceExchange := MyName + ' ' + MyState;
        end;

    NAQSOCW, NAQSOSSB, NAQSORTTY:
      begin
//        ActiveInitialExchange := NameInitialExchange;
//        ContestName := 'North American QSO Party';

        CQExchange := ' ' + MyName + ' ' + MyState;
        QSLMessage := '73 \ NA>';
        QuickQSLMessage1 := 'TU';
        QSOBeforeMessage := ' QSO B4 \ NA';
        SearchAndPounceExchange := MyName + ' ' + MyState;
        CorrectedCallMessage := '} R';

        SetCQMemoryString(CW, F1, 'CQ^NA \ \ NA>');
        SetCQMemoryString(CW, F2, 'CQ^NA CQ^NA \ \ NA>');

        SetCQMemoryString(CW, F5, '   ? ');
        SetCQMemoryString(CW, F6, '   NA \ NA ');
        SetCQMemoryString(CW, F7, '   CQ^NA \ \ NA ');
        SetCQMemoryString(CW, F8, '   CQ^NA CQ^NA \ \ NA ');

        SetCQMemoryString(CW, AltF1, 'NA \ \ NA');
        SetCQMemoryString(CW, AltF1, 'NA \ \ NA');

        SetEXMemoryString(CW, F3, MyName);
        SetEXMemoryString(CW, F4, MyState);
        SetEXMemoryString(CW, F5, '@ DE \ ' + MyName + ' ' + MyState);
        SetEXMemoryString(CW, AltF3, 'NAME?');
        SetEXMemoryString(CW, AltF4, 'QTH?');

        SetEXMemoryString(CW, F7, '   CQ^NA \ \ NA ');
        SetEXMemoryString(CW, F8, '   CQ^NA CQ^NA \ \ NA ');
        Add_KVEKH6KL;
        LiteralDomesticQTH := True;
      end;


    NEWENGLANDQSO:
      begin
        TempWord := PWORD(@MyState[1])^;
        if
          (TempWord = Ord('M') + Ord('E') * $100) or
          (TempWord = Ord('N') + Ord('H') * $100) or
          (TempWord = Ord('V') + Ord('T') * $100) or
          (TempWord = Ord('M') + Ord('A') * $100) or
          (TempWord = Ord('C') + Ord('T') * $100) or
          (TempWord = Ord('R') + Ord('I') * $100) then
        begin
          TempDomesticQTHDataFileName := 'NEQSOW1';
          ActiveDXMult := ARRLDXCCWithNoUSACanadaKH6OrKL7;
          ActiveExchange := RSTDomesticOrDXQTHExchange;
//          ContestName := 'New England QSO Party (within NE)';
        end
        else
        begin
          TempDomesticQTHDataFileName := 'NEQSO';
//          ActiveDXMult := NoCountDXMults;
          ActiveExchange := RSTDomesticQTHExchange;
//          ContestName := 'New England QSO Party (outside NE)';
        end;

        DXMultLimit := 20;
        Add_KVEKH6KL;
      end;

    NRAUBALTICCW, NRAUBALTICSSB:
      begin
        ActiveBand := Band80;
        AddDomesticCountry('ES');
        AddDomesticCountry('JW');
        AddDomesticCountry('JX');
        AddDomesticCountry('LA');
        AddDomesticCountry('LY');
        AddDomesticCountry('OH');
        AddDomesticCountry('OH0');
        AddDomesticCountry('OX');
        AddDomesticCountry('OY');
        AddDomesticCountry('OZ');
        AddDomesticCountry('SM');
        AddDomesticCountry('TF');
        AddDomesticCountry('YL');

      end;
    OKOMSSB:           // 4.80.1
     begin
         AddDomesticCountry('OK');
         AddDomesticCountry('OM');
        ActiveMode := Phone;
     end;

    OKDX:
      begin
        AddDomesticCountry('OK');
        AddDomesticCountry('OM');
        if not OKOMStation(MyCountry) then
        begin
          ActiveDomesticMult := DomesticFile;
          TempDomesticQTHDataFileName := 'OKOM';
        end
        else
        begin
          ActivePrefixMult := Prefix;
        end;
      end;

    PACC:
      begin

        if MyCountry = 'PA' then
        begin
          ActiveDXMult := PACCCountriesAndPrefixes;
          ActiveExchange := RSTAndQSONumberOrDomesticQTHExchange;
          AddDomesticCountry('PA');
          TempDomesticQTHDataFileName := 'PACCPA';
          LiteralDomesticQTH := True;
        end
        else
        begin
          ActiveExchange := RSTDomesticQTHExchange;
          TempDomesticQTHDataFileName := 'PACC';
        end;

      end;

    POTA:
       begin
       tAllowDupeQSOs := TRUE;
       AutoDupeEnableCQ := False;
       AutoDupeEnableSandP := False;
       ContestName := 'POTA';
       WARCBandsEnabled := True;
       end;

    QCWA:
      begin
        AddDomesticCountry('K');
        AddDomesticCountry('KH6');
        AddDomesticCountry('KL');
//        ContestName := 'QCWA QSO Party';
      end;

    RAEM:
      begin
        ActiveBand := Band80;
        ContestName := 'RAEM Ernst Krenkel Memorial Contest';
        InitialExchangeCursorPos := AtStart;
      end;

   CANADA_DAY, CANADA_WINTER:
      begin
      if MyCountry <> 'VE' then      // 4.82.1
         MyState := '';
        AddDomesticCountry('VE');
        AddDomesticCountry('CY0');
        AddDomesticCountry('CY9');
//        VHFBandsEnabled := True;
      end;

    RSGB_ROPOCO_CW, RSGB_ROPOCO_SSB:
      begin
        ActiveBand := Band80;
//        ContestName := 'UK Rotating Postal Code';
        MultipleBandsEnabled := False;
        CQExchange := '_~ %5NN ('; // + MyPostalCode;
        RepeatSearchAndPounceExchange := '5NN (';
        SearchAndPounceExchange := '~ %5NN (';
        SetCQMemoryString(CW, F3, '5NN (');
        SetEXMemoryString(CW, F3, '5NN');
        SetEXMemoryString(CW, F4, '(');
        SetEXMemoryString(CW, F5, '@ DE \ 5NN (');
        SetEXMemoryString(CW, AltF3, 'RST?');
        SetEXMemoryString(CW, AltF4, 'PC?');
      end;

    RDA:
      begin
        AddRussianDomesticCountrys;
//        CountDomesticCountries := True;
        if not RussianID(MyCountry) then ActiveDXMult := NoDXMults;
        DomesticMultByBand := dmbbAllBand;
      end;

    RUSSIANDX, RU3AXMEMORIAL:
      begin
        AddRussianDomesticCountrys;
        AddDomesticCountry('CE9');
        if not RussianID(MyCountry) then        // 4.79.2
         MyState := '';
//        CountDomesticCountries := True;
//        ContestName := 'Russian DX Contest';
      end;

    SALMONRUN:
      begin
//        if PWORD(@MyState[1])^ = $4157 {WA} then
        if FoundMyStateInDomFile then
        begin
//          DomesticQTHDataFileName := 'SALMONWA';
          ActiveExchange := RSTDomesticOrDXQTHExchange;
          ActiveDXMult := ARRLDXCCWithNoUSAOrCanada;
        end
        else
        begin
//          DomesticQTHDataFileName := 'SALMON';
          ActiveExchange := RSTDomesticQTHExchange;
        end;
//        ContestName := 'Washington State Salmon Run';
//        Add_KVEKH6KL;

      end;

    SACCW, SACSSB:
      begin
        if ScandinavianCountry(MyCountry) then
          ActiveDXMult := ARRLDXCC
        else
          ActivePrefixMult := SACDistricts;
      end;

      YBDX:                   // 4.64.1
       begin
          ActiveMode := Phone;
          ActiveDXMult := ARRLDXCC ;
          ActivePrefixMult := IndonesianDistricts;
      end;

    SPDX:
      begin
//        ContestName := 'SP-DX Contest';
        AddDomesticCountry('SP');
      end;

    NASPRINTCW, NASPRINTRTTY:
      begin
        ActiveBand := Band20;
//        ActiveInitialExchange := NameQTHInitialExchange;
//        ContestName := 'North American Sprint';
        SetCQMemoryString(CW, AltF1, 'NA \ NA');

        CQExchange := '^  \   # ' + MyName + ' ' + MyState;
        QSLMessage := 'TU';
        QuickQSLMessage1 := 'EE';
        QSOBeforeMessage := 'B4 \ NA';
        SearchAndPounceExchange := '@ # ' + MyName + ' ' + MyState + '  \ ';
        RepeatSearchAndPounceExchange := '# ' + MyName + ' ' + MyState;
        CorrectedCallMessage := '} R';

        SetCQMemoryString(CW, F1, 'NA \');
        SetCQMemoryString(CW, F2, 'CQ^NA CQ^NA \ \ NA');
        SetCQMemoryString(CW, F5, '   ? ');
        SetCQMemoryString(CW, F6, '   NA \ NA ');
        SetCQMemoryString(CW, F7, '   CQ^NA \ \ NA ');
        SetCQMemoryString(CW, F8, '   CQ^NA CQ^NA \ \ NA ');
        SetCQMemoryString(CW, AltF1, 'NA \ \ NA');

        SetEXMemoryString(CW, F3, 'NR #');
        SetEXMemoryString(CW, F4, MyName);
        SetEXMemoryString(CW, F5, MyState);
        SetEXMemoryString(CW, F6, '@ \ NR^# ' + MyName + ' ' + MyState);
        SetEXMemoryString(CW, F7, '   CQ^NA \ \ NA ');
        SetEXMemoryString(CW, F8, '   CQ^NA CQ^NA \ \ NA ');
        SetEXMemoryString(CW, AltF3, 'NR?');
        SetEXMemoryString(CW, AltF4, 'NAME?');
        SetEXMemoryString(CW, AltF5, 'QTH?');

        //QSOByBand := True;
        SprintQSYRule := True;
        Add_KVE;

        AddDomesticCountry('KL');
      end;

      SPRINTSSB:
      begin
        ActiveBand := Band20;
//        ActiveInitialExchange := NameQTHInitialExchange;
//        ContestName := 'North American Sprint';
        SetCQMemoryString(CW, AltF1, 'NA \ NA');

        CQExchange := '^  \   # ' + MyName + ' ' + MyState;
        QSLMessage := 'TU';
        QuickQSLMessage1 := 'EE';
        QSOBeforeMessage := 'B4 \ NA';
        SearchAndPounceExchange := '@ # ' + MyName + ' ' + MyState + '  \ ';
        RepeatSearchAndPounceExchange := '# ' + MyName + ' ' + MyState;
        CorrectedCallMessage := '} R';

        SetCQMemoryString(CW, F1, 'NA \');
        SetCQMemoryString(CW, F2, 'CQ^NA CQ^NA \ \ NA');
        SetCQMemoryString(CW, F5, '   ? ');
        SetCQMemoryString(CW, F6, '   NA \ NA ');
        SetCQMemoryString(CW, F7, '   CQ^NA \ \ NA ');
        SetCQMemoryString(CW, F8, '   CQ^NA CQ^NA \ \ NA ');
        SetCQMemoryString(CW, AltF1, 'NA \ \ NA');

        SetEXMemoryString(CW, F3, 'NR #');
        SetEXMemoryString(CW, F4, MyName);
        SetEXMemoryString(CW, F5, MyState);
        SetEXMemoryString(CW, F6, '@ \ NR^# ' + MyName + ' ' + MyState);
        SetEXMemoryString(CW, F7, '   CQ^NA \ \ NA ');
        SetEXMemoryString(CW, F8, '   CQ^NA CQ^NA \ \ NA ');
        SetEXMemoryString(CW, AltF3, 'NR?');
        SetEXMemoryString(CW, AltF4, 'NAME?');
        SetEXMemoryString(CW, AltF5, 'QTH?');

        //QSOByBand := True;
        SprintQSYRule := True;
        Add_KVEKH6KL;

   //     AddDomesticCountry('KL');
      end;
  

    ARRLSSCW, ARRLSSSSB:
      begin
//        ActiveInitialExchange := CheckSectionInitialExchange;
        CallsignUpdateEnable := True;
//        ContestName := 'ARRL Sweepstakes';

        AddARRLSectionDomesticCountries;

        SetCQMemoryString(CW, AltF1, 'CQ^SS \ SS');

        CQExchange := '_# ' + MyPrec + '  ' + MyCall + '  ' + MyCheck + ' ' + MySection;
{(*}
        SearchAndPounceExchange       := 'NR # ' + MyPrec + ' ' + MyCall + ' ' + MyCheck + ' ' + MySection;
        RepeatSearchAndPounceExchange := SearchAndPounceExchange;//'NR # ' + MyPrec + ' ' + MyCall + ' ' + MyCheck + ' ' + MySection;
{*)}
        QSLMessage := '73 ' + MyCall + ' SS>';
        QSOBeforeMessage := 'SRI QSO ' + MyCall + ' SS';

        QuickQSLMessage1 := 'TU>';
{(*}
//        SearchAndPounceExchange       := 'NR # ' + MyPrec + ' ' + MyCall + ' ' + MyCheck + ' ' + MySection;
//        RepeatSearchAndPounceExchange := 'NR # ' + MyPrec + ' ' + MyCall + ' ' + MyCheck + ' ' + MySection;
{*)}
        CorrectedCallMessage := '} R';

        SetCQMemoryString(CW, F1, 'SS ' + MyCall + ' SS>');
        SetCQMemoryString(CW, F2, 'CQ^SS ' + MyCall + ' ' + MyCall + ' SS>');
        SetCQMemoryString(CW, F3, 'CQ^SS CQ^SS ' + MyCall + ' ' + MyCall + ' SS>');
        SetCQMemoryString(CW, F7, '  CQ^SS ' + MyCall + ' SS');
        SetCQMemoryString(CW, F8, '  CQ^SS CQ^SS ' + MyCall + ' ' + MyCall + ' SS');

        SetCQMemoryString(CW, AltF1, 'SS ' + MyCall + ' SS');
        SetCQMemoryString(CW, AltF2, 'CQ^SS cq^ss ' + MyCall + ' ' + MyCall + ' SS');
        SetCQMemoryString(CW, AltF3, 'CQ^SS cq^ss ' + MyCall + ' ' + MyCall + ' SS');

        SetEXMemoryString(CW, AltF7, ' CQ^SS CQ^SS ' + MyCall + ' ' + MyCall + ' SS');

        SetEXMemoryString(CW, F3, 'NR #');
        SetEXMemoryString(CW, F4, MyPrec);
        SetEXMemoryString(CW, F5, MyCheck);
        SetEXMemoryString(CW, F6, MySection);
        SetEXMemoryString(CW, F7, '  CQ^SS ' + MyCall + ' SS');
        SetEXMemoryString(CW, F8, '  CQ^SS CQ^SS ' + MyCall + ' SS');

        SetEXMemoryString(CW, AltF3, 'NR?');
        SetEXMemoryString(CW, AltF4, 'PREC?');
        SetEXMemoryString(CW, AltF5, 'CK?');
        SetEXMemoryString(CW, AltF6, 'SEC?');
        SetEXMemoryString(CW, AltF7, ' CQ^SS CQ^SS ' + MyCall + ' ' + MyCall + ' SS');
      end;

    TENTEN:
      begin
//        ContestName := 'Ten Ten QSO Party';
        Add_KVEKH6KL;
      end;


    TEXASQSOPARTY:
      begin
        if FoundMyStateInDomFile then
        begin
          ActiveDXMult := ARRLDXCCWithNoUSACanadaKH6OrKL7;
//          DomesticQTHDataFileName := 'TEXASTX';
//          CQP := True;
        end
        else
        begin
//          DomesticQTHDataFileName := 'TEXAS';
          ActiveExchange := RSTDomesticQTHExchange;
        end;

//        Add_KVEKH6KL;
      end;

    UBACW, UBASSB:
      begin
        LiteralDomesticQTH := True;
        if MyCountry = 'ON' then          // 4.96.2
         begin
          ActiveDXMult := CQDXCC;
          ActiveDomesticMult := NoDomesticMults;
          ActiveBand := Band80;
          ActivePrefixMult := NoPrefixMults;
          end
          else
          begin
           ActivePrefixMult := BelgiumPrefixes;
           ActiveDomesticMult := DomesticFile;
          end;
      end;

    UKRAINIAN:
      begin
        AddDomesticCountry('UR');
        if MyCountry = 'UR' then
          ActiveDomesticMult := NoDomesticMults;
      end;

    VAQP:
      tAllowDupeQSOs := TRUE;
{
    REFCW:
      begin
        AddDomesticCountry('F');
      end;
}
    DARC10M:
      begin
        ActiveBand := Band10;
        AddDomesticCountry('DL');
        QSOByMode := True;
         if MyCountry = 'DL' then
       
          ActiveDXMult := CQDXCC

        else
          ActiveDomesticMult := DOKCodes;

        LiteralDomesticQTH := True;
        AddDomesticCountry('DL');
      end;

    DARCXMAS:
      begin
//        CountryTable.ZoneMode := CQZoneMode;
//        ActivePrefixMult := Prefix;
        LiteralDomesticQTH := True;
        AddDomesticCountry('DL');
        SprintQSYRule := True;
      end;

    WAG:
      begin
//        CountryTable.ZoneMode := CQZoneMode;

        if MyCountry = 'DL' then
        begin
          ActiveDXMult := CQDXCC;
          //For the WAG contest - German stations will need to count Germany as a country multiplier manually after the contest.
        end
        else
          ActiveDomesticMult := DOKCodes;

        LiteralDomesticQTH := True;
        AddDomesticCountry('DL');
      end;

    DARCWAEDCCW, DARCWAEDCSSB {, DARCWAEDCRTTY}:
      begin
//        CountryTable.ZoneMode := CQZoneMode;

        if MyContinent <> Europe then
          ActiveDXMult := CQEuropeanCountries
        else
          ActivePrefixMult := CQNonEuropeanCountriesAndWAECallRegions;

        ActiveBand := Band80;
        ContactsPerPage := 40;
        QTCsEnabled := True;
      end;
{
    ,QSOPARTY:
      begin
        ActiveDomesticMult := DomesticFile;
        if (PWORD(@MyState[1])^ = $4957) //WI
        then
          DomesticQTHDataFileName := 'WIQSOWI'
        else
          DomesticQTHDataFileName := 'WIQSO';

        Add_KVEKH6KL;
      end;
}

    YODX:
      begin
        ContestName := 'YO-DX-HF Contest';
        AddDomesticCountry('YO');
      end;

    CUPRFCW, CUPRFSSB, CUPRFDIG:
      begin
        ActiveMode := CW;
        if Contest = CUPRFSSB then ActiveMode := Phone;
        MyState := MyGrid;
        LiteralDomesticQTH := True;
      end;

    UA4WCHAMPIONSHIP:
      begin
        TourDuration := 15;
      end;

    R9W_UW9WK_MEMORIAL:
      begin
        TourDuration := 20;
      end;

    RFCHAMPIONSHIPCW, RFCHAMPIONSHIPSSB:
      begin
        ActiveMode := Phone;
        if Contest = RFCHAMPIONSHIPCW then ActiveMode := CW;
        DomesticMultByBand := dmbbAllBand;
        InitialExchangeOverwrite := True;
//        ActiveZoneMult := RFChampionchipZones;
//        ActiveInitialExchange := ZoneInitialExchange;
      end;

    MINITEST, MINI80:
      begin
        ActiveBand := Band80;
        MultipleBandsEnabled := False;
        MultipleModesEnabled := False;
        TourDuration := 10;
      end;

    MINI40:
      begin
        ActiveBand := Band40;
        MultipleBandsEnabled := False;
        MultipleModesEnabled := False;
        TourDuration := 10;
      end;

    LZDX:
      begin
        AddDomesticCountry('LZ');
        ActiveBand := Band80;
      end;

    ALRS_UA1DZ_CUP:
      begin
        LiteralDomesticQTH := true;
        if RussianID(MyCountry) then
        begin
          TempOblast := GetOblast(MyCall);
          if not (GetRussiaOblastByTwoChars(TempOblast[1], TempOblast[2]) in [rtUA1A, rtUA1C]) then
          begin
            ActiveDXMult := NoDXMults;
            ActiveDomesticMult := RDADistrict;
            TempDomesticQTHDataFileName:=nil;
            MultByBand := false;
          end;
        end;

      end;

    OLDNEWYEAR:
    begin
     ActiveBand := Band80;
     ExchangeMemoryEnable := True;
    end;

    CQWPXRTTY, WRTC:
      ActiveBand := Band80;

    YOUTHCHAMPIONSHIPRF:
      begin
     
        TourDuration := 60;
        CTY.CtyRFOblMode := True; // n4af 4.42.7
        ActiveMode := Phone;
        ContestName := '?????????? ?????????? ??';
        end;

    RFASCHAMPIONSHIPCW {, RFASCHAMPIONSHIPSSB}:
      begin
//        ActiveMode := CW;
//        if Contest = RFASCHAMPIONSHIPSSB then ActiveMode := Phone;
      end;

    SEVENQP:
      begin
//        if (pos('7', MyCall) > 0) or (pos('/7', MyCall) > 0) then
        if FoundMyStateInDomFile then
        begin
//          DomesticQTHDataFileName := '7QP-W7';
//          ContestName := '7th Area QSO Party Inside W7';
          ActiveExchange := RSTDomesticOrDXQTHExchange;
          ActiveDXMult := ARRLDXCCWithNoUSACanadaKH6OrKL7;
          DXMultLimit := 20;
//          Add_KVEKH6KL;
        end
        else
        begin
//          DomesticQTHDataFileName := '7QP';
//          ContestName := '7th Area QSO Party Outside W7';
          ActiveExchange := RSTDomesticQTHExchange;
        end;
//        VHFBandsEnabled := True;

      end;

    OZCR_O:
      begin
        ContestName := '????-??????? ????????? ?????? - ????? ?????????';
        CTY.ctyR150SMode := True;
      end;

    LQP, NCCCSPRINT:
      begin
        AutoDupeEnableCQ := True;
        AutoDupeEnableSandP := True;
        AddDomesticCountry('KH6');
        Add_KVE;
        ExchangeMemoryEnable := True; //(turns on the Exchange Memory for Initial Exchange pre - fill)
//        ActiveInitialExchange := NameQTHInitialExchange; //(turns on Initial Exchange pre - fill using TRMASTER.DTA)
        SprintQSYRule := True;
        tAllowDupeQSOs := False;
      end;

//    UA4N: TourDuration := 15;

    JTDX:          // 4.67.9
      begin
      ActiveInitialExchange := ZoneInitialExchange;
       ActivePrefixMult := MongolianCallSignPrefix;
      end;



    CQIR:
      begin
        AddDomesticCountry('EI');
      end;

    UNDX:
      begin
        AddDomesticCountry('UN');
//        CountDomesticCountries := True;
      end;

    KINGOFSPAINCW, KINGOFSPAINSSB:
      begin
        AddDomesticCountry('EA');
        AddDomesticCountry('EA6');
        AddDomesticCountry('EA8');
        AddDomesticCountry('EA9');
      end;

    CQMM:
      begin
        if MyContinent = SouthAmerica then ActivePrefixMult := SouthAndNorthAmericanPrefixes;
        DXCCMultByBand := dmbbAllBand;
        ActiveBand := Band80;
      end;

    OZHCRVHF:
      QSONumberByBand := True;

//    RADIOMEMORY:
//      CallsignUpdateEnable := False;

   PCC:
   begin
    ExchangeMemoryEnable := False;
    SetCursorPos(0,1);
    INITIALEXCHANGEOVERWRITE := TRUE;
   end;

   ARRLDIGI:
      begin
      DigitalModeEnable := true;
      QSOByMode := False;
      QSOByBand := True;
 //     LiteralDomesticQTH := true;    // 4.91.5
      end;

  end;

  
  if TempDomesticQTHDataFileName <> nil then
  begin
    Windows.lstrcat(DomQTHDataFileName, TempDomesticQTHDataFileName);
    Windows.lstrcat(DomQTHDataFileName, '.dom');
  end;

  case ActiveExchange of
    NameAndDomesticOrDXQTHExchange: SetUpNameAndStateExchange;

    RSTQSONumberExchange: SetUpRSTQSONumberExchange;

    RSTDomesticQTHExchange,
      RSTAndContinentExchange,
      RSTAndQSONumberOrFrenchDepartmentExchange,
      RSTAndQSONumberOrDomesticQTHExchange,
      RSTDomesticQTHOrQSONumberExchange:

      if MyState = '' then SetUpRSTQSONumberExchange else SetUpRSTMyStateExchange;

    RSTZoneAndPossibleDomesticQTHExchange, RSTZoneExchange:
      if not (Contest in [JIDXCW, JIDXSSB]) then SetUpRSTMyZoneExchange;

    RSTZoneOrSocietyExchange:
      if MyState = '' then SetUpRSTMyZoneExchange else SetUpRSTMyStateExchange;

  end;

  FoundContest := Contest <> DUMMYCONTEST;

  SetContestTitle;

end;

procedure AddRussianDomesticCountrys;
begin
  AddDomesticCountry('UA');
  AddDomesticCountry('UA2');
  AddDomesticCountry('UA9');
  AddDomesticCountry('R1FJ');
  AddDomesticCountry('R1MV');
end;

procedure Add_KVEKH6KL;
begin
  AddDomesticCountry('K');
  AddDomesticCountry('VE');
  AddDomesticCountry('KH6');
  AddDomesticCountry('KL');
end;

procedure Add_KVE;
begin
  AddDomesticCountry('K');
  AddDomesticCountry('VE');
end;

procedure RecalculateMyCountryContinentAndZone;
var
  TempQTH                               : VC.QTHRecord;
begin
//  CTY.ctyLastCountryCall := '';
  Windows.ZeroMemory(@CTY.ctyLastLocatedCall, SizeOf(CTY.ctyLastLocatedCall));
//  CTY.ctyLastLocatedCall := '';
  ctyLocateCall(MyCall, TempQTH);
  MyCountry := TempQTH.CountryID;
  MyContinent := TempQTH.Continent;
  Str(TempQTH.Zone, MyZone);
end;

procedure RecalculateMyCountryContinentAndZoneNew(Call: CallString);
var
  TempQTH                               : VC.QTHRecord;
begin
  Windows.ZeroMemory(@CTY.ctyLastLocatedCall, SizeOf(CTY.ctyLastLocatedCall));

  if MyCountryIsSet then
    ctyLocateCall(MyCountry, TempQTH)
  else
    ctyLocateCall(Call, TempQTH);

  if not MyCountryIsSet then
  begin
    MyCountry := TempQTH.CountryID;
    CountryString := MyCountry;
    if MRC = '' then
    MRC := MyCountry;
  end;

  if not MyZoneIsSet then
  begin
    Str({TempQTH.Zone}ctyGetZone(Call), MyZone);
  end;

  if not MyContinentIsSet then
  begin
    MyContinent := TempQTH.Continent;
    if MyCo = '' then
    MyCo := tContinentArray[MyContinent];
    ContinentString := tContinentArray[MyContinent];
  end;

end;

procedure SetContestTitle;
begin
  ContestTitle[0] := CHR(Format(@ContestTitle[1], '%s %s %s', GetYearString, @ContestName[1], @MyCall[1]));
end;

procedure EnumDOM2(FileString: PShortString);
var
  TempString                            : ShortString;
begin
  if StringHas(FileString^, '=') then
  begin
    TempString := PrecedingString(FileString^, '=');
    if tPos(TempString, '>') <> 0 then TempString := PrecedingString(TempString, '>');
    GetRidOfPrecedingSpaces(TempString);
    GetRidOfPostcedingSpaces(TempString);
    if TempString = MyState then InState := True;
  end;
end;

function FoundMyStateInDomFile: boolean;
var


  TempFileName                          : FileNameType;
begin
  Result := False;
  if Contest = DUMMYCONTEST then Exit;
  InState := False;
   Format(TempFileName, '%sDOM\%s.DOM', TR4W_PATH_NAME, ContestsArray[Contest].DF);
  if not EnumerateLinesInFile(TempFileName, EnumDOM2, True) then Exit;
  Result := InState;
// Result := True;
end;
end.
