unit uGridDistance;

(*
  Pure Haversine distance, in kilometres, between the CENTERS of two
  4-character Maidenhead grid squares.  R = 6371 km.

  Extracted from LOGGRID.RTCGridDistance (Issue #902, RTC contest scoring) so
  the math can be unit-tested without linking the heavy trdos LOGGRID unit.
  LOGGRID.RTCGridDistance is now a thin delegate to GridHaversineKm.

  Reference fixture from the RTC rules: FN36 -> DM18 = 3664.72 km.

  NOTE: distinct from LOGGRID.GetDistanceBetweenGrids, which pads 4-char grids
  with 'LL' (half-sub-square offset) and uses a Vincenty-style geodesic.  RTC
  rules require the geometric center of the 4-char square AND Haversine, so the
  two are numerically different by design.

  Uses utils_math.ArcTan2 (the x86 FPATAN inline-asm helper) deliberately, to
  keep bit-for-bit numeric parity with the original LOGGRID implementation. See
  uTestUtilsMath for the asm-freeze rationale ahead of the Phase 3 64-bit port.
*)

interface

// Haversine km between the centers of two 4-char Maidenhead grids.
// Returns 0.0 if either grid is shorter than 4 characters.
function GridHaversineKm(const Grid1, Grid2: string): Double;

implementation

uses
   SysUtils,    // UpperCase
   utils_math;  // ArcTan2

const
   R_EARTH_KM = 6371.0;
   DEG2RAD    = Pi / 180.0;

procedure GridCenterDeg(const G: string; var Lat, Lon: Double);
var
   g4: string;
begin
   g4 := UpperCase(G);
   // 4-char Maidenhead: 20 deg lon field x 2 deg lon square;
   //                    10 deg lat field x 1 deg lat square.
   // Center = corner + half square width.
   Lon := -180.0
        + (Ord(g4[1]) - Ord('A')) * 20.0
        + (Ord(g4[3]) - Ord('0')) *  2.0
        + 1.0;
   Lat :=  -90.0
        + (Ord(g4[2]) - Ord('A')) * 10.0
        + (Ord(g4[4]) - Ord('0')) *  1.0
        + 0.5;
end;

function GridHaversineKm(const Grid1, Grid2: string): Double;
var
   Lat1, Lon1, Lat2, Lon2 : Double;
   dLat, dLon, A, C       : Double;
begin
   Result := 0.0;
   if (Length(Grid1) < 4) or (Length(Grid2) < 4) then
      begin
      Exit;
      end;

   GridCenterDeg(Grid1, Lat1, Lon1);
   GridCenterDeg(Grid2, Lat2, Lon2);

   Lat1 := Lat1 * DEG2RAD;
   Lat2 := Lat2 * DEG2RAD;
   dLat := Lat2 - Lat1;
   dLon := (Lon2 - Lon1) * DEG2RAD;

   A := Sin(dLat / 2.0) * Sin(dLat / 2.0)
      + Cos(Lat1) * Cos(Lat2) * Sin(dLon / 2.0) * Sin(dLon / 2.0);
   C := 2.0 * ArcTan2(Sqrt(A), Sqrt(1.0 - A));

   Result := R_EARTH_KM * C;
end;

end.
