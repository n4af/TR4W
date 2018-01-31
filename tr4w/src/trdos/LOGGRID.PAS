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
unit LogGrid;

{$IMPORTEDDATA OFF}

{ Minus lon is east }

interface

uses
  TF,
  VC,
  Windows,
  utils_text,
  utils_math
  ;

type
  DistanceDisplayType = (NoDistanceDisplay, DistanceMiles, DistanceKM);

function ConvertLatLonToGrid(Lat, Lon: REAL): GridString;
function GetBeamHeading(MyGrid, HisGrid: GridString): integer;
function GetDistanceBetweenGrids(Grid1, Grid2: GridString): integer;
function GetEuropeanDistanceBetweenGrids(Grid1, Grid2: GridString): integer;
procedure GetLatLon(Grid: GridString; var Lat, Lon: REAL);
function GetSunriseSunsetString(Lat: REAL; Lon: REAL): Str80;
function LooksLikeAGeoCoordinates(Coordinates: Str40; var LatValue, LongValue: integer): boolean;
//function LooksLikeRadio160Square(Square: Str20): boolean;

const
  DistanceDisplayTypeSA                 : array[DistanceDisplayType] of PChar = ('NONE', 'MILES', 'KM');

var
  DistanceMode                          : DistanceDisplayType = DistanceKM;
  MyGrid                                : GridString;
  RadiusOfEarth                         : REAL {= 0.0};

implementation


procedure ConvertGridToLatLon(Grid: GridString; var Lat, Lon: REAL);

{ Converts a grid to Lat/Lon to the center of the grid }

var
  LonMin, londeg, latmin, latdeg        : REAL;
//  GR                                    : GridRec;
begin
{
  asm
    mov eax, Grid
    mov dword ptr GR, eax
  end;
}
  if length(Grid) = 4 then
  begin
    Grid[5] := 'L';
    Grid[6] := 'L';
  end;

  LonMin := (5 * (Ord(Grid[5]) - Ord('A'))) + 2.5; { center }
  londeg := 180 - (20 * (Ord(Grid[1]) - Ord('A'))) { tens of deg }
    - (2 * (Ord(Grid[3]) - Ord('0'))); { two deg }

  Lon := londeg - (LonMin / 60);

  latdeg := -90 + (10 * (Ord(Grid[2]) - Ord('A'))) { tens of deg }
    + (Ord(Grid[4]) - Ord('0')); { degrees }

  latmin := 2.5 * (Ord(Grid[6]) - Ord('A')) { minutes }
    + 1.25; { for center }

  Lat := latdeg + (latmin / 60);
end;

function ConvertLatLonToGrid(Lat, Lon: REAL): GridString;

{ This procedure will convert a latitude and longitude to a grid square. }
{ Minus lat is east }

var
  c                                     : integer;

  G4, { R, M,} L4                       : REAL;
  m1, m2, m3, m4, m5, m6                : Char;
//  GR                                    : GridRec;
begin
  { First we do the longitude stuff - chars 1 3 and 5 }

  G4 := 180 - Lon;

  c := Trunc(G4 / 20); { Get first letter of Grid }
  m1 := CHR(c + Ord('A'));

  G4 := G4 - c * 20; { Remove that compoenent }

  c := Trunc(G4 / 2); { Get third letter of Grid}
  m3 := CHR(c + Ord('0'));

  G4 := G4 - c * 2; { Remove that component }

  c := Trunc(G4 / (2 / 24)); { Get fifth letter }
  m5 := CHR(c + Ord('A'));

  { Similar process for longitude }

  L4 := Lat + 90;

  c := Trunc(L4 / 10);
  m2 := CHR(c + Ord('A'));

  L4 := L4 - c * 10;

  c := Trunc(L4);
  m4 := CHR(c + Ord('0'));

  L4 := L4 - c;

  c := Trunc(L4 / (1 / 24));
  m6 := CHR(c + Ord('A'));
{
  GR[1] := m1;
  GR[2] := m2;
  GR[3] := m3;
  GR[4] := m4;
  RESULT := PDWORD(@GR)^;
}
  ConvertLatLonToGrid := m1 + m2 + m3 + m4 + m5 + m6;
end;

procedure Calc_GeoDist(MyLat, MyLon, HisLat, HisLon: REAL;
  var Az, Baz, Dist: REAL);

{Taken directly from:       }
{Thomas, P.D., 1970, Spheroidal geodesics, reference systems,}
{    & local geometry, U.S. Naval Oceanographic Office SP-138,}
{    165 pp.}

{ assumes North Latitude and East Longitude are positive}

{MyLat, MyLon = MyLat, MyLon}
{HisLat, HisLon = HisLat, HisLon}
{Az, BAz = direct & reverse azimuith}
{Dist = Dist (km); Deg = central angle, discarded }

const
  {     AL = 6378206.4;   { Clarke 1866 ellipsoid - Equatorial radius in km }
  {     BL = 6356583.8;   { Polar radius in km }

  DefaultRadiusOfEarth                  = 6378137.0; { From K6SE - Dec '98 }
  BL                                    = 6356752.3; { Calculated from K6SE data - Dec '98 - no longer used }

  f                                     = 1.0 / 298.257223563; { Flattening constant based on actual Earth size }
  BDA                                   = 1.0 - f; { Polar diameter divided by equatorial diameter }

  D2R                                   = PI / 180.0; { degrees to radians conversion factor }
  Pi2                                   = 2.0 * PI;

label
  1, 2, 3, 4, 5, 6, 7, 8, 9;

var
  P1R, P2R,
    L1R, L2R,
    DLR,
    T1R, T2R,
    TM, DTM,
    STM, CTM,
    SDTM, CDTM,
    KL, KK,
    SDLMR, TL,
    CD, DL, SD,
    t, U, V, d, X, e, Y, a,
    FF64, TDLPM,
    HAPBR, HAMBR,
    al, A1M2, A2M1                      : REAL;

begin
  if RadiusOfEarth > 0 then
    al := RadiusOfEarth * 1000
  else
    al := DefaultRadiusOfEarth;

  P1R := MyLat * D2R;
  P2R := HisLat * D2R;
  L1R := -MyLon * D2R;
  L2R := -HisLon * D2R;

  DLR := L2R - L1R;
  T1R := ArcTan(BDA * Tan(P1R));
  T2R := ArcTan(BDA * Tan(P2R));

  TM := (T1R + T2R) / 2.0;
  DTM := (T2R - T1R) / 2.0;
  STM := SIN(TM);
  CTM := cos(TM);
  SDTM := SIN(DTM);
  CDTM := cos(DTM);
  SDLMR := SIN(DLR / 2.0);

  TL := SDTM * SDTM + SDLMR * SDLMR * (CDTM * CDTM - STM * STM);
  CD := 1.0 - 2.0 * TL;


  KL := STM * CDTM;
  KK := SDTM * CTM;
  TL := SDTM * SDTM + SDLMR * SDLMR * (CDTM * CDTM - STM * STM);
  DL := ArcCos(CD);
  SD := SIN(DL);

  { Anti divide by zero techniques }

  if SD = 0 then SD := 0.000000001;

  t := DL / SD;
  U := 2.0 * KL * KL / (1.0 - TL);

  { Anti divide by zero techniques }

  if TL = 0 then TL := 0.000000001;

  V := 2.0 * KK * KK / TL;
  d := 4.0 * t * t;
  X := U + V;
  e := -2.0 * CD;
  Y := U - V;
  a := -d * e;
  FF64 := f * f / 64.0;
  Dist := al * SD * (t - (f / 4.0) * (t * X - Y) + FF64 * (X * (a + (t - (a + e) / 2.0) * X) + Y * (-2.0 * d + e * Y) + d * X * Y)) / 1000.0;
  TDLPM := Tan((DLR + (-((e * (4.0 - X) + 2.0 * Y) * ((f / 2.0) * t + FF64 * (32.0 * t + (a - 20.0 * t) * X - 2.0 * (d + 2.0) * Y)) / 4.0) * Tan(DLR))) / 2.0);
  HAPBR := ArcTan2 {ATan2}(SDTM, (CTM * TDLPM));
  HAMBR := ArcTan2 {ATan2}(CDTM, (STM * TDLPM));
  A1M2 := Pi2 + HAMBR - HAPBR;
  A2M1 := Pi2 - HAMBR - HAPBR;

  1:
  if (A1M2 >= 0.0) and (A1M2 < Pi2) then goto 5
  else goto 2;

  2:
  if A1M2 >= Pi2 then goto 3
  else goto 4;

  3: A1M2 := A1M2 - Pi2;
  goto 1;

  4: A1M2 := A1M2 + Pi2;
  goto 1;

  5:
  if (A2M1 >= 0.0) and (A2M1 < Pi2) then goto 9
  else goto 6;

  6:
  if A2M1 >= Pi2 then goto 7
  else goto 8;

  7: A2M1 := A2M1 - Pi2;
  goto 5;

  8: A2M1 := A2M1 + Pi2;
  goto 5;

  9: Az := A1M2 / D2R;
  Baz := A2M1 / D2R;

end; {Calc_GeoDist}

function GetDistanceBetweenGrids(Grid1, Grid2: GridString): integer;

{ This function returns the distance between the two grids specified in
  kilometers. }

var
  Lat1, Lat2, Lon1, Lon2                : REAL;
  ShortHeading, LongHeading, Distance   : REAL;

begin

  if length(Grid1) <> 6 then Grid1 := Grid1 + 'LL';
  strU(Grid1);

  if length(Grid2) <> 6 then Grid2 := Grid2 + 'LL';
  strU(Grid2);

  if Grid1 = Grid2 then
  begin
    GetDistanceBetweenGrids := 0;
    Exit;
  end;

  ConvertGridToLatLon(Grid1, Lat1, Lon1);
  ConvertGridToLatLon(Grid2, Lat2, Lon2);

  Calc_GeoDist(Lat1, Lon1, Lat2, Lon2, ShortHeading, LongHeading, Distance);
  GetDistanceBetweenGrids := round(Distance);
end;

function GetEuropeanDistanceBetweenGrids(Grid1, Grid2: GridString): integer;

const
  r                                     = PI / 180; {to Radian}
  {     RZ=(180 * 111.2)/PI;}
  RZ                                    = 6369; {produces same results as DL2NBU, LOCATOR 9.97b and others }
var
  c1, c2, N1, N2, C3, C4, CC1, CC2, NN1, NN2, CC3, CC4: integer;
  X, KM, a, b, FX, FY                   : REAL;
begin
  Result := 0;
  if Grid1 = '' then Exit;
  if Grid2 = '' then Exit;

  strU(Grid1);
  strU(Grid2);

  c1 := Ord(Grid1[1]) - 74;
  c2 := Ord(Grid1[2]) - 74;
  N1 := Ord(Grid1[3]) - 48;
  N2 := Ord(Grid1[4]) - 48;
  C3 := Ord(Grid1[5]) - 65;
  C4 := Ord(Grid1[6]) - 65;
  CC1 := Ord(Grid2[1]) - 74;
  CC2 := Ord(Grid2[2]) - 74;
  NN1 := Ord(Grid2[3]) - 48;
  NN2 := Ord(Grid2[4]) - 48;
  CC3 := Ord(Grid2[5]) - 65;
  CC4 := Ord(Grid2[6]) - 65;
  a := r * (c1 * 20 + N1 * 2 + C3 / 12);
  b := r * (c2 * 10 + N2 + C4 / 24);
  FX := r * (CC1 * 20 + NN1 * 2 + CC3 / 12);
  FY := r * (CC2 * 10 + NN2 + CC4 / 24);
  X := SIN(b) * SIN(FY) + cos(b) * cos(FY) * cos(FX - a);
  KM := RZ * ArcTan(Sqrt(1 - SQR(X)) / X) + 0.5;
  GetEuropeanDistanceBetweenGrids := round(KM);

end;

function GetBeamHeading(MyGrid, HisGrid: GridString): integer;

var
  Lat1, Lat2, Lon1, Lon2                : REAL;
  ShortHeading, LongHeading, Distance   : REAL;

begin
  Result := -1; //wli
  if not (length(MyGrid) in [4, 6]) then Exit;
  if not (length(HisGrid) in [4, 6]) then Exit;

//  if (length(MyGrid) <> 4) and (length(MyGrid) <> 6) then Exit;
//  if (length(HisGrid) <> 4) and (length(HisGrid) <> 6) then Exit;

  if length(MyGrid) <> 6 then MyGrid := MyGrid + 'LL';
  strU(MyGrid);

  if length(HisGrid) <> 6 then HisGrid := HisGrid + 'LL';
  strU(HisGrid);

  if HisGrid = MyGrid then
  begin
    GetBeamHeading := 0;
    Exit;
  end;

  ConvertGridToLatLon(MyGrid, Lat1, Lon1);
  ConvertGridToLatLon(HisGrid, Lat2, Lon2);

  Calc_GeoDist(Lat1, Lon1, Lat2, Lon2, ShortHeading, LongHeading, Distance);
  GetBeamHeading := round(ShortHeading);
end;

procedure GetLatLon(Grid: GridString; var Lat, Lon: REAL);


begin
//  if length(Grid) <> 6 then Grid := Grid + 'LL';
//  strU(@Grid);
  ConvertGridToLatLon(Grid, Lat, Lon);
end;

function DayOfYear(Year, Month, Day: Word): integer;

var
  TempDay                               : integer;

begin
  TempDay := Trunc((30.55556 * Month) + Day - 30);

  Year := Year mod 100;

  if Month > 2 then
    if (Year mod 4 = 0) and (Year <> 0) then { Leap year }
      TempDay := TempDay - 1
    else
      TempDay := TempDay - 2;
  DayOfYear := TempDay;
end;

function CalculateTime(Year: integer;
  Month: integer;
  Day: integer;
  Lat: REAL;
  Lon: REAL;
  Sunrise: boolean;
  var Hours: integer; var Minutes: integer): boolean;

var
  DOY                                   : Word;
  Doy1, UTC, UTCrad, T1, T2, T3, q, DECSol, Anm, RAsol, LONsol: REAL;


begin
  Lat := Lat * PI / 180;

  DOY := DayOfYear(Year, Month, Day);

  if Sunrise then
    Doy1 := DOY + Lon / 360.0 + 0.25
  else
    Doy1 := DOY + Lon / 360.0 + 0.75;

  { Calculate Solar Mean Anomaly - Anm }

  Anm := (0.017202 * Doy1) - 0.0574039;

  { anm = 0.017202*doy1 - 0.0574039; }

  { Calculate Solar True Longitude - LONsol }

  LONsol := Anm + (0.033405 * SIN(Anm)) + (3.49066E-04 * SIN(2 * Anm)) + 4.93289;

  { lonsol = anm + 0.0334405 * sin(anm) +
                   3.49066e-4 * sin(2*anm) +
                   4.93289; }

  { Force LONsol to be in the range 0 to 2pi by adding/subtracting 2pi }

  while LONsol > (2 * PI) do
    LONsol := LONsol - (2 * PI);

  while LONsol < 0 do
    LONsol := LONsol + (2 * PI);

  {   if (lonsol<0)
   lonsol += (2*PI);

      if (lonsol>(2*PI))
   lonsol -= (2*PI); }

  { Calculate Solar RightAscension - RAsol }

  RAsol := ArcTan(0.91746 * (SIN(LONsol) / cos(LONsol)));

  if (LONsol >= 0) and (LONsol <= (PI / 2)) then
    RAsol := RAsol + (0 * PI)
  else
    if (LONsol > (PI / 2)) and (LONsol <= (3 * PI) / 2) then
      RAsol := RAsol + (1 * PI)
    else
      if (LONsol > ((3 * PI) / 2)) then
        RAsol := RAsol + (2 * PI);

  {   if (lonsol<(PI/2))
   k1 = 0;
      else if (lonsol>(3*PI/2))
   k1 = 2;
      else k1 = 1; }

  {   rasol = atan(0.91746*tan(lonsol)) + k1*PI; }

  { Calculate Solar Declination - DECsol }

  q := 0.39872 * SIN(LONsol);

  DECSol := q / Sqrt(1 - (q * q));

  {   q = 0.39872*sin(lonsol);
      decsol = q/sqrt(1 - q*q); }

  { Calculate Local Apparent Time for Desired Event - T3 }

  T1 := -0.01483 / (cos(ArcTan(DECSol)) * cos(Lat)) - DECSol * Tan(Lat);

  {   t1 = -0.01483/(cos(atan(decsol))*cos(lat)) - decsol*tan(lat); }

  if (T1 > 1) or (T1 < -1) then
  begin
    CalculateTime := False;
    Exit;
  end;

  T2 := -ArcTan(T1 / Sqrt(1 - (T1 * T1))) + (PI / 2);

  if Sunrise then T2 := (2 * PI) - T2;

  {   t2 = -atan(t1/sqrt(1 - t1*t1)) + PI/2;
      if (sr == TRUE)
   t2 = 2*PI - t2; }

  T3 := T2 + RAsol - (0.0172028 * Doy1) - 1.73364;

  {   t3 = t2 + rasol - 0.0172028*doy - 1.73364; }

  UTCrad := T3 + Lon * PI / 180;

  if UTCrad < 0 then UTCrad := UTCrad + 2 * PI;
  if UTCrad > 2 * PI then UTCrad := UTCrad - 2 * PI;

  {   utcrad = t3 + lon*PI/180;
      if (utcrad < 0)
   utcrad += (2*PI);
      if (utcrad >(2*PI))
   utcrad -= (2*PI);  }

  UTC := UTCrad * 12 / PI;

  {   utc = utcrad*12/PI;
      utc_hr = (int)(utc);
      utc_min = 60.0*(utc - utc_hr); }

  Hours := round(Int(UTC));
  Minutes := round(Frac(UTC) * 60);

  if Minutes = 60 then
  begin
    Minutes := 0;
    inc(Hours);

    if Hours = 24 then Hours := 0;
  end;
  Result := True; //wli
end;

function GetSunriseSunsetString(Lat: REAL; Lon: REAL): Str80;

var
  Year, Month, Day, DayOfWeek           : Word;
  HourString, MinuteString, SunString   : Str80;
  Hour, Minute                          : integer;

begin
  GetDate(Year, Month, Day, DayOfWeek);

  if CalculateTime(Year, Month, Day, Lat, Lon, True, Hour, Minute) then
  begin
    Str(Hour, HourString);
    Str(Minute, MinuteString);
    if length(HourString) = 1 then HourString := '0' + HourString;
    if length(MinuteString) = 1 then MinuteString := '0' + MinuteString;
    SunString := HourString + MinuteString + 'z/';
  end
  else
  begin
    if Lat > 0 then
    begin
      if (Month >= 3) and (Month <= 9) then
        GetSunriseSunsetString := TC_ALLSUN
      else
        GetSunriseSunsetString := TC_ALLDARK;
    end
    else
      if (Month >= 3) and (Month <= 9) then
        GetSunriseSunsetString := TC_ALLDARK
      else
        GetSunriseSunsetString := TC_ALLSUN;
    Exit;
  end;

  if CalculateTime(Year, Month, Day, Lat, Lon, False, Hour, Minute) then
  begin
    Str(Hour, HourString);
    Str(Minute, MinuteString);
    if length(HourString) = 1 then HourString := '0' + HourString;
    if length(MinuteString) = 1 then MinuteString := '0' + MinuteString;

    SunString := SunString + HourString + MinuteString + 'z';
  end
  else
  begin
    if Lat > 0 then
    begin
      if (Month >= 3) and (Month <= 9) then
        GetSunriseSunsetString := TC_ALLSUN
      else
        GetSunriseSunsetString := TC_ALLDARK;
    end
    else
      if (Month >= 3) and (Month <= 9) then
        GetSunriseSunsetString := TC_ALLDARK
      else
        GetSunriseSunsetString := TC_ALLSUN;
    Exit;
  end;

  GetSunriseSunsetString := SunString;
end;


function LooksLikeAGeoCoordinates(Coordinates: Str40; var LatValue, LongValue: integer): boolean;
var

  LatPos                                : Cardinal;
  CharPosition                          : Cardinal;
  ConvResult                            : integer;
  TempStr10                             : Str10;
  {
      Number = Lat LatChar Lon LonChar = 51n59o
  }

begin
  Result := False;
  if length(Coordinates) < 4 then Exit;
  LatPos := 0;
  for CharPosition := 2 to 3 do
    if (Coordinates[CharPosition] = 'N') or (Coordinates[CharPosition] = 'S') then LatPos := CharPosition;

  if LatPos = 0 then Exit;
  if (Coordinates[length(Coordinates)] <> 'O') and
  (Coordinates[length(Coordinates)] <> 'E') and
  (Coordinates[length(Coordinates)] <> 'W') then Exit;

  TempStr10 := Copy(Coordinates, 1, LatPos - 1);
  Val(TempStr10, LatValue, ConvResult);
  if ConvResult <> 0 then Exit;
  if LatValue > 89 then Exit;
  if length(TempStr10) > 2 then Exit;

  TempStr10 := Copy(Coordinates, LatPos + 1, length(Coordinates) - LatPos - 1);
  Val(TempStr10, LongValue, ConvResult);
  if ConvResult <> 0 then Exit;
  if LongValue > 179 then Exit;
  if length(TempStr10) > 3 then Exit;

  if Coordinates[LatPos] = 'S' then LatValue := 90 - LatValue else LatValue := 90 + LatValue;
  if Coordinates[length(Coordinates)] = 'W' then LongValue := 180 - LongValue else LongValue := 180 + LongValue;
  Result := True;
end;


end.

