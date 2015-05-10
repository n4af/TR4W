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
unit POSTCFG;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  Ucfg, VC,
  Windows,
  Country9,
  Tree,
  LogWind,
  FCONTEST,
  ZoneCont,
  LogDupe,
  MainUnit,
  LogDom;

function ProcessPostConfigInstruction(ID: Str80; CMD: ShortString {80}): boolean;
//function GetExchangeFromString(CMD: ShortString): ExchangeType;
//function GetQSOPointsMethodFromString(CMD: ShortString): QSOPointMethodType;
//function GetDXMultTypeFromString(CMD: pShortString): DXMultType;
//function GetActivePrefixMultFromString(CMD: pShortString): PrefixMultType;
//function GetActiveDomesticMultFromString(CMD: pShortString): DomesticMultType;

{ This is a file that gets included into LOGCFG.PAS and POSTSUBS.PAS }

implementation
//uses Settings_unit;

function ProcessPostConfigInstruction(ID: Str80; CMD: ShortString {80}): boolean;

var
  TempValue, Result1                    : integer;
  TempQTH                               : QTHRecord;

begin
  ProcessPostConfigInstruction := False;

  if CheckCommand(@ID, CMD) then
  begin
    ProcessPostConfigInstruction := True;
    Exit;
  end;

  { These are free }
{
  if ID = 'CONTACTS PER PAGE' then
  begin
    Val(CMD, TempValue, Result1);
    if Result1 = 0 then
    begin
      ContactsPerPage := TempValue;
      ProcessPostConfigInstruction := True;
    end;
    Exit;
  end;
}
{
  if ID = 'CONTEST' then
  begin
    ProcessPostConfigInstruction := FoundContest(CMD);
    Exit;
  end;
}
//  if ID = 'LOG FILE NAME' then
//  begin
//    if {wli  (length(CMD) <= 8) and } not StringHas(CMD, '.') then
//    begin
//      SetUpFileNames(@CMD[1]);
//      ProcessPostConfigInstruction := True;
//    end
//    else
        //            ReportError ('LOG FILE NAME command has illegal format.  Must be <= 8 chars and no dot.');
//      Exit;
//  end;
{
  if ID = 'LOG SUB TITLE' then
  begin
    LogSubTitle := CMD;
    ProcessPostConfigInstruction := True;
    Exit;
  end;
}
{
  if ID = 'MY CALL' then
  begin
    MyCall := CMD;

    DEPlusMyCall := 'DE ' + MyCall;

    LocateCall(MyCall, TempQTH, True);
    MyCountry := CountryTable.GetCountryID(TempQTH.Country);
    MyContinent := TempQTH.Continent;
    Str(TempQTH.Zone, MyZone);
    CountryString := MyCountry;
    ContinentString := CountryTable.GetContinentName(MyContinent);
    ProcessPostConfigInstruction := True;
    Exit;
  end;
}
{
  if ID = 'MY CHECK' then
  begin
    MyCheck := CMD;
    ProcessPostConfigInstruction := True;
    Exit;
  end;
}
//  if ID = 'MY CONTINENT' then
//  begin

//    MyContinent := RemoveContinentStringAndDetermineContinent(CMD);
//    ProcessPostConfigInstruction := MyContinent <> UnknownContinent;
      {
          ContinentString := CMD;
          if UpperCase(CMD) = 'EU' then
          begin
            MyContinent := Europe;
            ProcessPostConfigInstruction := True;
          end;

          if UpperCase(CMD) = 'NA' then
          begin
            MyContinent := NorthAmerica;
            ProcessPostConfigInstruction := True;
          end;

          if UpperCase(CMD) = 'SA' then
          begin
            MyContinent := SouthAmerica;
            ProcessPostConfigInstruction := True;
          end;

          if UpperCase(CMD) = 'AF' then
          begin
            MyContinent := Africa;
            ProcessPostConfigInstruction := True;
          end;

          if UpperCase(CMD) = 'AS' then
          begin
            MyContinent := Asia;
            ProcessPostConfigInstruction := True;
          end;

          if UpperCase(CMD) = 'OC' then
          begin
            MyContinent := Oceania;
            ProcessPostConfigInstruction := True;
          end;
      }
//    Exit;
//  end;
{
  if ID = 'MY COUNTRY' then
  begin
    LocateCall(CMD, TempQTH, True);
    MyCountry := CountryTable.GetCountryID(TempQTH.Country);
    MyContinent := TempQTH.Continent;
    Str(TempQTH.Zone, MyZone);
    CountryString := MyCountry;
    ContinentString := CountryTable.GetContinentName(MyContinent);
    ProcessPostConfigInstruction := True;
    Exit;
  end;
}
{
  if ID = 'MY ZONE' then
  begin
    MyZone := CMD;
    ProcessPostConfigInstruction := True;
    Exit;
  end;

  if ID = 'MY FD CLASS' then
  begin
    MyFDClass := CMD;
    ProcessPostConfigInstruction := True;
    Exit;
  end;

  if ID = 'MY NAME' then
  begin
    MyName := CMD;
    ProcessPostConfigInstruction := True;
    Exit;
  end;

  if ID = 'MY POSTAL CODE' then
  begin
    MyPostalCode := CMD;
    ProcessPostConfigInstruction := True;
    Exit;
  end;

  if ID = 'MY PREC' then
  begin
    MyPrec := CMD;
    ProcessPostConfigInstruction := True;
    Exit;
  end;

  if ID = 'MY SECTION' then
  begin
    MySection := CMD;
    ProcessPostConfigInstruction := True;
    Exit;
  end;

  if (ID = 'MY STATE') or (ID = 'MY QTH') then
  begin
    MyState := CMD;
    ProcessPostConfigInstruction := True;
    Exit;
  end;
}
{
  if ID = 'SINGLE BAND SCORE' then
  begin
    SingleBand := tGetBandFromString(CMD);
    if SingleBand > Band10 then SingleBand := NoBand;
    ProcessPostConfigInstruction := SingleBand <> NoBand;
    Exit;
  end;
}
{
  if ID = 'UNKNOWN COUNTRY FILE ENABLE' then
  begin
    UnknownCountryFileEnable := CMD[1] = 'T';
    ProcessPostConfigInstruction := True;
    Exit;
  end;

  if ID = 'UNKNOWN COUNTRY FILE NAME' then
  begin
    UnknownCountryFileName := CMD;
    ProcessPostConfigInstruction := True;
    Exit;
  end;
}
  { These you pay for }

//  if not TRFree then
  begin
{
    if ID = 'ADD DOMESTIC COUNTRY' then
    begin
      if CMD = 'CLEAR' then ClearDomesticCountryList else AddDomesticCountry(CMD);
      ProcessPostConfigInstruction := True;
      Exit;
    end;
}
{
    if ID = 'CONTEST NAME' then
    begin
      ContestName := CMD;
      ProcessPostConfigInstruction := True;
        //      ContestTitle := GetYearString + ' ' + ContestName + ' ' + MyCall;
      SetContestTitle;
      Exit;
    end;
}
{
    if ID = 'CONTEST TITLE' then
    begin
      ContestTitle := CMD;
      ProcessPostConfigInstruction := True;
      Exit;
    end;
}
{
    if (ID = 'DOMESTIC FILENAME') or (ID = 'DOMESTIC QTH DATA FILENAME') then
    begin
      if CMD <> '' then DomesticQTHDataFileName := CMD;
      ProcessPostConfigInstruction := True;
      Exit;
    end;
 }
{
    if ID = 'DOMESTIC MULTIPLIER' then
    begin
      ActiveDomesticMult := NoDomesticMults;
      if CMD = 'DOMESTIC FILE' then ActiveDomesticMult := DomesticFile;
      if CMD = 'GRID SQUARES' then ActiveDomesticMult := GridSquares;
      if CMD = 'GRID FIELDS' then ActiveDomesticMult := GridFields;
      if CMD = 'WYSIWYG' then ActiveDomesticMult := WYSIWYGDomestic;
      ProcessPostConfigInstruction := (ActiveDomesticMult <> NoDomesticMults) or (CMD = 'NONE');
      Exit;
    end;
}
{
    if ID = 'DX MULTIPLIER' then
    begin
      ActiveDXMult := GetDXMultTypeFromString(@CMD);
      ProcessPostConfigInstruction := (ActiveDXMult <> NoDXMults) or (CMD = 'NONE');
      Exit;
    end;
}
{
    if ID = 'EXCHANGE RECEIVED' then
    begin
      ActiveExchange := GetExchangeFromString(CMD);
      ProcessPostConfigInstruction := ActiveExchange <> NoExchangeReceived;
      Exit;
    end;
}
{
    if ID = 'MINITOUR DURATION' then
    begin
      Val(CMD, TourDuration, Result1);
      if not (TourDuration in [5..60]) then TourDuration := 0;
      ProcessPostConfigInstruction := Result1 = 0;
      Exit;
    end;

    if ID = 'MULT BY BAND' then
    begin
      MultByBand := CMD[1] = 'T';
      ProcessPostConfigInstruction := True;
      Exit;
    end;

    if ID = 'MULT BY MODE' then
    begin
      MultByMode := CMD[1] = 'T';
      ProcessPostConfigInstruction := True;
      Exit;
    end;
}
{
    if ID = 'PREFIX MULTIPLIER' then
    begin
      ActivePrefixMult := GetActivePrefixMultFromString(@CMD);
      ProcessPostConfigInstruction := True;
      Exit;
}
{
      if CMD = 'NONE' then
      begin
        ActivePrefixMult := NoPrefixMults;
        ProcessPostConfigInstruction := True;
      end;

      if CMD = 'PREFIX' then
      begin
        ActivePrefixMult := Prefix;
        ProcessPostConfigInstruction := True;
      end;

      if CMD = 'SOUTH AMERICAN PREFIXES' then
      begin
        ActivePrefixMult := SouthAmericanPrefixes;
        ProcessPostConfigInstruction := True;
      end;

      if CMD = 'CALLSIGN' then
      begin
        ActivePrefixMult := CallSignPrefix;
        ProcessPostConfigInstruction := True;
      end;

      Exit;
}
  end;
{
    if ID = 'QSO BY BAND' then
    begin
      QSOByBand := CMD[1] = 'T';
      ProcessPostConfigInstruction := True;
      Exit;
    end;

    if ID = 'QSO BY MODE' then
    begin
      QSOByMode := CMD[1] = 'T';
      ProcessPostConfigInstruction := True;
      Exit;
    end;
}
{
    if ID = 'QSO POINT METHOD' then
    begin
      ActiveQSOPointMethod := GetQSOPointsMethodFromString(CMD);
      ProcessPostConfigInstruction := (ActiveQSOPointMethod <> NoQSOPointMethod);
      Exit;
    end;
}
{
    if ID = 'QSO POINTS DOMESTIC CW' then
    begin
      Val(CMD, QSOPointsDomesticCW, Result1);
      ProcessPostConfigInstruction := Result1 = 0;
      Exit;
    end;

    if ID = 'QSO POINTS DOMESTIC PHONE' then
    begin
      Val(CMD, QSOPointsDomesticPhone, Result1);
      ProcessPostConfigInstruction := Result1 = 0;
      Exit;
    end;

    if ID = 'QSO POINTS DX CW' then
    begin
      Val(CMD, QSOPointsDXCW, Result1);
      ProcessPostConfigInstruction := Result1 = 0;
      Exit;
    end;

    if ID = 'QSO POINTS DX PHONE' then
    begin
      Val(CMD, QSOPointsDXPhone, Result1);
      ProcessPostConfigInstruction := Result1 = 0;
      Exit;
    end;

    if ID = 'R150S MODE' then
    begin
      tr4w_R150SMode := CMD[1] = 'T';
      ProcessPostConfigInstruction := True;
      Exit;
    end;
}
{
  if ID = 'ZONE MULTIPLIER' then
  begin
    ActiveZoneMult := ZoneMultType(GetValueFromArray(@ZoneMultTypeSA, Byte(High(ZoneMultType)), @CMD));

    ProcessPostConfigInstruction := ActiveZoneMult <> ZoneMultType(UNKNOWNTYPE);
    if RESULT then
    begin
      if ActiveZoneMult = CQZones then
      begin
        ActiveInitialExchange := ZoneInitialExchange;
        CountryTable.ZoneMode := CQZoneMode;
      end;

      if ActiveZoneMult = ITUZones then
      begin
        ActiveInitialExchange := ZoneInitialExchange;
        CountryTable.ZoneMode := ITUZoneMode;
      end;
    end;
}
{
    if CMD = 'NONE' then
    begin
      ActiveZoneMult := NoZoneMults;
      ProcessPostConfigInstruction := True;
    end;

    if CMD = 'BRANCH ZONES' then
    begin
      ActiveZoneMult := BranchZones;
      ProcessPostConfigInstruction := True;
    end;

    if CMD = 'CQ ZONES' then
    begin
      CountryTable.ZoneMode := CQZoneMode;
      ActiveZoneMult := CQZones;
      ActiveInitialExchange := ZoneInitialExchange;
      ProcessPostConfigInstruction := True;
    end;

    if CMD = 'ITU ZONES' then
    begin
      CountryTable.ZoneMode := ITUZoneMode;
      ActiveZoneMult := ITUZones;
      ActiveInitialExchange := ZoneInitialExchange;
      ProcessPostConfigInstruction := True;
    end;

    if CMD = 'JA PREFECTURES' then
    begin
      ActiveZoneMult := JAPrefectures;
      ProcessPostConfigInstruction := True;
    end;
}
//    Exit;
//  end;
//  end;

end;
{
function GetExchangeFromString(CMD: ShortString): ExchangeType;
var
  et                                    : ExchangeType;
begin
  RESULT := NoExchangeReceived;
  for et := RSTZoneOrDomesticQTH downto NoExchangeReceived do
  begin
    if Windows.CompareString(LOCALE_SYSTEM_DEFAULT, NORM_IGNORECASE, @CMD[1], length(CMD), ActiveExchangeArray[ET], lstrlen(ActiveExchangeArray[ET])) = 2 then
    begin
      RESULT := et;
      Break;
    end;
  end;
end;
}
{
function GetQSOPointsMethodFromString(CMD: ShortString): QSOPointMethodType;
var
  qpm                                   : QSOPointMethodType;
begin
  RESULT := NoQSOPointMethod;
  for qpm := JTDXQSOPointMethod downto NoQSOPointMethod do
  begin
    if Windows.CompareString(LOCALE_SYSTEM_DEFAULT, NORM_IGNORECASE, @CMD[1], length(CMD), QSOPointMethodArray[qpm], lstrlen(QSOPointMethodArray[qpm])) = 2 then
    begin
      RESULT := qpm;
      Break;
    end;
  end;
end;
}
{
function GetDXMultTypeFromString(CMD: pShortString): DXMultType;
var
  mt                                    : DXMultType;
begin
  CMD^[Ord(CMD^[0]) + 1] := #0;
  RESULT := NoDXMults;
  for mt := CQNonEuropeanCountriesAndWAECallRegions downto NoCountDXMults do
//  for mt := High(DXMultType) downto Low(DXMultType) do
  begin
    if Windows.lstrcmp(@CMD^[1], DXMultTypenameArray[mt]) = 0 then
    begin
      RESULT := mt;
      Break;
    end;
  end;
end;
}
{
function GetActivePrefixMultFromString(CMD: pShortString): PrefixMultType;
var
  Pt                                    : PrefixMultType;
begin
  CMD^[Ord(CMD^[0]) + 1] := #0;
  RESULT := NoPrefixMults;
  for Pt := High(PrefixMultType) downto Low(PrefixMultType) do
  begin
    if Windows.lstrcmp(@CMD^[1], PrefixMultStringArray[Pt]) = 0 then
    begin
      RESULT := Pt;
      Break;
    end;
  end;
end;
}
{
function GetActiveDomesticMultFromString(CMD: pShortString): DomesticMultType;
var
  Pt                                    : DomesticMultType;
begin
  CMD^[Ord(CMD^[0]) + 1] := #0;
  RESULT := NoDomesticMults;
  for Pt := High(DomesticMultType) downto Low(DomesticMultType) do
  begin
    if Windows.lstrcmp(@CMD^[1], DomesticMultStringArray[Pt]) = 0 then
    begin
      RESULT := Pt;
      Break;
    end;
  end;
end;
}
end.

