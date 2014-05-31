unit ZoneCont;

{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  Tree,
  uCTYDAT,
  utils_text,
  uCallSignRoutines;

  //Country9;

//const
//  UpdateListDate                        = '3 Apr 93';

type
  DomesticCountryRecordPointer = ^DomesticCountryRecord;

  DomesticCountryRecord = record
    CountryID: string[6];
    NextRecord: DomesticCountryRecordPointer;
  end;

var
  FirstDomesticCountryRecord            : DomesticCountryRecordPointer;
//  LastLocateCall                        : CallString;
  LastLocateQTH                         : QTHRecord;
  tAddDomesticCountryString             : CallString;

procedure AddDomesticCountry(ID: CallString);
procedure ClearDomesticCountryList;
function DomesticCountryCall(Call: CallString): boolean;

function ClubCall(Call: CallString): boolean;

function GetVEInitialExchange(Call: CallString): Str20;

//procedure LocateCall(Call: VC.CallString; var QTH: VC.QTHRecord; UseStandardCallFormat: boolean);

function GetContinentName(Cont: ContinentType): Str20;
function GetContinentFromString(Cont: ShortString): ContinentType;
function SACDistrict(QTH: QTHRecord): Str20;
function EuropeanCountriesAndWAECallRegions(QTH: QTHRecord): Str20;

implementation
uses LogWind;

function GetVEInitialExchange(Call: CallString): Str20;

var
  CountryID                             : Str20;
  QTH                                   : QTHRecord;
begin
  GetVEInitialExchange := '';

  Call := StandardCallFormat(Call, True);
  ctyLocateCall(Call, QTH);
  CountryID := QTH.CountryID;

  if ActiveQSOPointMethod = RussianDXQSOPointMethod then
    if (CountryID[1] = 'U') then
      if (CountryID[2] = 'A') then
      begin
        Result := GetRussiaOblastID(Call);
        Exit;
      end;

  if CountryID <> 'VE' then Exit;
  Call := Copy(Call, 1, 3);

  if StringHas(Call, '3') then GetVEInitialExchange := 'Ont ';
  if StringHas(Call, '4') then GetVEInitialExchange := 'Man';
  if StringHas(Call, '5') then GetVEInitialExchange := 'Sask';
  if StringHas(Call, '6') then GetVEInitialExchange := 'Ab';
  if StringHas(Call, '7') then GetVEInitialExchange := 'Bc';
  if StringHas(Call, '8') then GetVEInitialExchange := 'NWT';

  if Call = 'VE2' then GetVEInitialExchange := 'Que';
  if Call = 'VY2' then GetVEInitialExchange := 'vy2';
  if Call = 'VY1' then GetVEInitialExchange := 'Yuk';
  if Call = 'VO1' then GetVEInitialExchange := 'vo1';
  if Call = 'VO2' then GetVEInitialExchange := 'vo2';
  if Call = 'VE1' then GetVEInitialExchange := 've1';
end;

procedure AddDomesticCountry(ID: CallString);

var
  ActiveRecord                          : DomesticCountryRecordPointer;

begin
  strU(ID);

  if FirstDomesticCountryRecord = nil then
  begin
    FirstDomesticCountryRecord := New(DomesticCountryRecordPointer);
    FirstDomesticCountryRecord^.CountryID := ID;
    FirstDomesticCountryRecord^.NextRecord := nil;
    Exit;
  end;

  ActiveRecord := FirstDomesticCountryRecord;

  while ActiveRecord^.NextRecord <> nil do
    ActiveRecord := ActiveRecord^.NextRecord;

  ActiveRecord^.NextRecord := New(DomesticCountryRecordPointer);

  ActiveRecord := ActiveRecord^.NextRecord;

  ActiveRecord^.CountryID := ID;
  ActiveRecord^.NextRecord := nil;
end;

function DomesticCountryCall(Call: CallString): boolean;

{ Returns TRUE if the callsign is in one of the countries identified as
  domestic countries. }

var
  ActiveRecord                          : DomesticCountryRecordPointer;
  ID                                    : CallString;
  QTH                                   : QTHRecord;
begin
  ActiveRecord := FirstDomesticCountryRecord;

  if ActiveRecord = nil then
  begin
    DomesticCountryCall := False;
    Exit;
  end;

  ctyLocateCall(Call, QTH);
  ID := QTH.CountryID;

  repeat
    if ActiveRecord^.CountryID = ID then
    begin
      DomesticCountryCall := True;
      Exit;
    end;

    ActiveRecord := ActiveRecord^.NextRecord;

  until ActiveRecord = nil;

  DomesticCountryCall := False;
end;

procedure ClearDomesticCountryList;

var
  NextRecord, ActiveRecord              : DomesticCountryRecordPointer;

begin
  ActiveRecord := FirstDomesticCountryRecord;

  while ActiveRecord <> nil do
  begin
    NextRecord := ActiveRecord^.NextRecord;
    Dispose(ActiveRecord);
    ActiveRecord := NextRecord;
  end;
  FirstDomesticCountryRecord := nil;
end;

function CallDistrict(Call: CallString): Str20;

var
  TempString                            : Str20;
  FoundLetter, FoundNumber              : boolean;
  CharacterCount                        : integer;

begin
  Call := StandardCallFormat(Call, True);

  if StringHas(Call, '/') then Call := PrecedingString(Call, '/');

  CallDistrict := '';
  TempString := '';

  if Call = '' then Exit;

  FoundLetter := False;
  FoundNumber := False;

  for CharacterCount := 1 to length(Call) do
    if not FoundLetter then
    begin
      if (Call[CharacterCount] >= 'A') and (Call[CharacterCount] <= 'Z') then
        FoundLetter := True;
    end
    else
      if not FoundNumber then
      begin
        if (Call[CharacterCount] >= '0') and (Call[CharacterCount] <= '9') then
        begin
          TempString := Call[CharacterCount];
          FoundNumber := True;
        end;
      end
      else
        if Call[CharacterCount] > '9' then
        begin
          CallDistrict := TempString;
          Exit;
        end
        else
          TempString := TempString + Call[CharacterCount];

  CallDistrict := TempString;
end;

function EuropeanCountriesAndWAECallRegions(QTH: QTHRecord): Str20;
var
  NumberChar                            : Char;
begin
  Result := '';
  if QTH.Continent = Europe then Exit;
  Result := QTH.CountryID;
//W, VE, VK, ZL, ZS, JA, PY, ? ????? RA8/RA9 ? RA0
  if (QTH.CountryID = 'K') or
    (QTH.CountryID = 'VE') or
    (QTH.CountryID = 'VK') or
    (QTH.CountryID = 'ZL') or
    (QTH.CountryID = 'ZS') or
    (QTH.CountryID = 'JA') or
    (QTH.CountryID = 'PY') or
    (QTH.CountryID = 'UA9') then
  begin
    NumberChar := GetNumber(QTH.StandardCall);
    Result := QTH.CountryID + NumberChar;
  end;

end;

function SACDistrict(QTH: QTHRecord): Str20;
var
  Oblast                                : Str2;
begin
  SACDistrict := '';
  if ScandinavianCountry(QTH.CountryID) then
  begin
    Oblast := GetOblast(QTH.StandardCall);
    if length(Oblast) = 0 then Oblast := '0';
    SACDistrict := QTH.CountryID + Oblast[1];
    if (QTH.CountryID = 'OH0') or (QTH.CountryID = 'OJ0') then SACDistrict := QTH.CountryID;
  end;
end;

function ClubCall(Call: CallString): boolean;

var
  ID, StandardCall                      : Str20;

begin
{
  ClubCall := False;
  StandardCall := UpperCase(StandardCallFormat(Call, True));
  ID := ctyGetCountryID(ctyGetCountry(StandardCall));

  if (ID = 'CT') or (ID = 'CT3') then
    ClubCall := (Copy(Call, 1, 2) = 'CS') and (length(Call) = 6);

  if ID = 'DL' then
    if Call[1] = 'D' then
      ClubCall := (Copy(Call, 1, 3) = 'DF0') or
        (Copy(Call, 1, 3) = 'DK0') or
        (Copy(Call, 1, 3) = 'DL0');

  if (ID = 'EA') or (ID = 'EA6') or (ID = 'EA8') or (ID = 'EA9') then
    case length(Call) of
      4: ClubCall := True;
      6: ClubCall := Call[4] = 'R';
    end;

  if (ID = 'ES') then
    case length(Call) of
      4: ClubCall := True;
      5: ClubCall := Call[4] >= 'W';
    end;

  if (ID = 'F') then
    if Call[2] = 'F' then ClubCall := True;

  if ID = 'G' then
    if Call[2] = 'X' then ClubCall := True;
  if ID = 'GD' then
    if Call[2] = 'T' then ClubCall := True;
  if ID = 'GI' then
    if Call[2] = 'N' then ClubCall := True;
  if ID = 'GJ' then
    if Call[2] = 'H' then ClubCall := True;
  if ID = 'GM' then
    if Call[2] = 'S' then ClubCall := True;
  if ID = 'GU' then
    if Call[2] = 'P' then ClubCall := True;
  if ID = 'GW' then
    if Call[2] = 'C' then ClubCall := True;

  if ID = 'JA' then
    if length(Call) = 6 then
      ClubCall := (Call[4] = 'Y') or (Call[4] = 'Z');

  if (ID = 'HA') or (ID = 'LZ') or (ID = 'OK') or (ID = 'OM') or
    (ID = 'SP') or (ID = 'YO') then
    case length(Call) of
      4: ClubCall := True;
      6: ClubCall := Call[4] = 'W';
    end;

  if ID = 'LY' then
    case length(Call) of
      4: ClubCall := True;
      5: ClubCall := Call[4] >= 'W';
    end;

  if ID = 'PA' then
    ClubCall := (Copy(Call, 1, 3) = 'PI4') or
      (Copy(Call, 1, 3) = 'PI5') or
      (Copy(Call, 1, 3) = 'PI9');

  if ID = 'OE' then
    if Call[4] = 'X' then ClubCall := True;

  if (ID = 'OH') or (ID = 'OH0') or (ID = 'OH0M') then
    if length(Call) = 5 then
      ClubCall := Call[4] = 'A';

  if ID = 'S5' then
    ClubCall := (length(Call) = 6) and
      ((Copy(Call, 1, 3) = 'S51') or
      (Copy(Call, 1, 3) = 'S52') or
      (Copy(Call, 1, 3) = 'S53') or
      (Copy(Call, 1, 3) = 'S59'));

  if ID = 'SM' then
    ClubCall := (Copy(Call, 1, 2) = 'SI') or
      (Copy(Call, 1, 2) = 'SJ') or
      (Copy(Call, 1, 2) = 'SK');

  if (ID = 'UA') or (ID = 'UA2') or (ID = 'UA0') or (ID = 'UJ') or
    (ID = 'UN') or (ID = 'UR') or (ID = '4K2') then
    if length(Call) = 6 then
      ClubCall := (Call[5] >= 'W') and (Call[5] <= 'Z');

  if ID = 'K' then
    ClubCall := (Call = 'W1AW') or (Call = 'W1MX') or
      (Call = 'W6LS') or (Call = 'W6YRA') or
      (Call = 'W9YB') or (Call = 'W9YH') or
      (Call = 'W9YT');

  if ID = 'YL' then
    case length(Call) of
      4: ClubCall := True;
      5: ClubCall := Call[4] >= 'W';
    end;

  if ID = 'YU' then
    case length(Call) of
      4: ClubCall := True;
      6:
        begin
          if (Copy(Call, 1, 3) = 'YU1') or
            (Copy(Call, 1, 3) = 'YU5') or
            (Copy(Call, 1, 3) = 'YU6') or
            (Copy(Call, 1, 3) = 'YU7') or
            (Copy(Call, 1, 3) = 'YU8') then
            ClubCall := Call[4] <= 'W';
        end;
    end;

  if ID = 'ZP' then
    ClubCall := (length(Call) = 5) and (Copy(Call, 4, 2) = 'AA');

  if (ID = 'Z2') or (ID = '3A') then
    ClubCall := length(Call) = 6;

  if (ID = '4X') then
    if length(Call) = 5 then
      ClubCall := (Call[4] = 'E') or (Call[4] = 'H') or
        (Copy(Call, 1, 4) = '4Z4S') or
        (Copy(Call, 1, 4) = '4Z4Y');

  if ID = '9A' then
    ClubCall := length(Call) = 4;
}
end;

function GetNumber(Call: CallString): Char;

{ This function will look at the callsign passed to it and return the
  single number that is in it.  If the call is portable, the number from
  the portable designator will be given if there is one.  If the call
  or prefix has two numbers in it, the last one will be given.         }

var
  CharPtr                               : integer;
  TempString                            : Str80;

begin
  if StringHas(Call, '/') then
    Call := PrecedingString(Call, '/');

  for CharPtr := length(Call) downto 1 do
    if (Call[CharPtr] <= '9') and (Call[CharPtr] >= '0') then
    begin
      GetNumber := Call[CharPtr];
      Exit;
    end;
  GetNumber := CHR(0);
end;
{
procedure LocateCall(Call: CallString; var QTH: QTHRecord; UseStandardCallFormat: boolean);
// This is the procedure that gets everything done
var
  TempString                            : Str80;
  Prefix                                : integer;
  Country                               : integer;
begin
  if Call = LastLocateCall then
  begin
    QTH := LastLocateQTH;
    Exit;
  end;

  Windows.ZeroMemory(@QTH, SizeOf(QTH));

  LastLocateCall := Call;
  QTH.StandardCall := StandardCallFormat(Call, True);
//4
  if StringHas(QTH.StandardCall, '/') then
  begin
    TempString := PrecedingString(StandardCallFormat(Call, True), '/');

    //KK1L: 6.68 Added AM check to allow /AM as aeronautical mobile rather than Spain

    if (Copy(TempString, 1, 2) = 'MM') or (Copy(TempString, 1, 2) = 'AM') then
    begin
      Call := PostcedingString(QTH.StandardCall, '/');
      QTH.Prefix := GetPrefix(Call);
      //QTH.Country   := CountryTable.GetCountry   (Call, UseStandardCallFormat);
      //QTH.CountryID := CountryTable.GetCountryID (QTH.Country);
      QTH.Country := UNKNOWN_COUNTRY;
      QTH.CountryID := '';
      QTH.Continent := ctyGetContinent(Call);
      //QTH.Zone := CountryTable.GetZone(Call);
      QTH.CountryID := ctyGetCountryID(QTH.Country);
      LastLocateQTH := QTH;
      Exit;
    end;

    if not StringHasNumber(TempString) then TempString := TempString + '0';

    TempString := GetPrefix(TempString);
    QTH.Prefix := TempString;
  end
  else
    QTH.Prefix := GetPrefix(QTH.StandardCall);
//10
  QTH.Country := ctyGetCountry(Call); //-2FM
//14
  if QTH.Country <> UNKNOWN_COUNTRY then
  begin
    QTH.Continent := CTY.ctyTable[CountryTable.LastLocatedCountry^.Country].DefaultContinent; // CountryTable.GetContinent(Call); //0fm
    QTH.CountryID := CTY.ctyTable[CountryTable.LastLocatedCountry^.Country].ID; //CountryTable.GetCountryID(QTH.Country);
  end
  else
    asm
  nop
    end;
//18
  //QTH.Zone := CountryTable.GetZone(Call); //0fm
//22

//22
  LastLocateQTH := QTH;
end;
}

function GetContinentName(Cont: ContinentType): Str20;
begin
  case Cont of
    NorthAmerica: GetContinentName := 'NA';
    SouthAmerica: GetContinentName := 'SA';
    Europe: GetContinentName := 'EU';
    Africa: GetContinentName := 'AF';
    Asia: GetContinentName := 'AS';
    Oceania: GetContinentName := 'OC';
  else GetContinentName := '';
  end;
end;

function GetContinentFromString(Cont: ShortString): ContinentType;
begin
  Result := UnknownContinent;
  if Cont = 'NA' then Result := NorthAmerica;
  if Cont = 'NO' then Result := NorthAmerica;

  if Cont = 'SA' then Result := SouthAmerica;
  if Cont = 'SO' then Result := SouthAmerica;

  if Cont = 'EU' then Result := Europe;
  if Cont = 'AF' then Result := Africa;
  if Cont = 'AS' then Result := Asia;
  if Cont = 'OC' then Result := Oceania;
end;

//begin
  //  LastLocateCall := '';
end.

