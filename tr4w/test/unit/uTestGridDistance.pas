unit uTestGridDistance;

{
  Unit tests for uGridDistance.GridHaversineKm -- the RTC contest Haversine
  distance between the centers of two 4-character Maidenhead grid squares
  (Issue #902, v4.147.07).

  The headline fixture FN36 -> DM18 = 3664.72 km comes straight from the RTC
  rules and was the value the original LOGGRID.RTCGridDistance was verified
  against.  Freezing it here guards both the extraction (LOGGRID now delegates
  to this unit) and the Phase 3 64-bit rewrite of the asm ArcTan2 it depends on
  (see uTestUtilsMath for that rationale).
}

interface

uses
   SysUtils, uTR4WTestFramework, uGridDistance;

type
   TGridDistanceTests = class(TTestCase)
   protected
      procedure CheckNear(expected, actual, tolerance: Double; const ctx: string);

      procedure Test_FN36_to_DM18_RulesFixture;
      procedure Test_Symmetry;
      procedure Test_SameGrid_IsZero;
      procedure Test_ShortGrid_ReturnsZero;
      procedure Test_CaseInsensitive;
      procedure Test_LongGrid_UsesFirstFour;
   public
      procedure RunAllTests; override;
   end;

implementation

procedure TGridDistanceTests.CheckNear(expected, actual, tolerance: Double;
                                       const ctx: string);
var
   diff: Double;
begin
   diff := Abs(expected - actual);
   if diff <= tolerance then
      begin
      Check(True, '');
      end
   else
      begin
      Check(False, Format('%s: expected %.4f, got %.4f (diff %.4f, tol %.4f)',
                          [ctx, expected, actual, diff, tolerance]));
      end;
end;

procedure TGridDistanceTests.Test_FN36_to_DM18_RulesFixture;
begin
   BeginTest('Test_FN36_to_DM18_RulesFixture');
   // The RTC rules' reference value.  Tolerance is generous (1 km) because the
   // published figure is rounded to 2 decimals.
   CheckNear(3664.72, GridHaversineKm('FN36', 'DM18'), 1.0, 'FN36->DM18');
end;

procedure TGridDistanceTests.Test_Symmetry;
begin
   BeginTest('Test_Symmetry');
   // Distance is symmetric: d(A,B) = d(B,A).
   CheckNear(GridHaversineKm('FN36', 'DM18'),
             GridHaversineKm('DM18', 'FN36'), 1.0e-9, 'symmetry');
end;

procedure TGridDistanceTests.Test_SameGrid_IsZero;
begin
   BeginTest('Test_SameGrid_IsZero');
   // Center-to-center distance of a grid with itself is exactly 0.
   CheckNear(0.0, GridHaversineKm('EL88', 'EL88'), 1.0e-9, 'EL88->EL88');
end;

procedure TGridDistanceTests.Test_ShortGrid_ReturnsZero;
begin
   BeginTest('Test_ShortGrid_ReturnsZero');
   // Guard: fewer than 4 chars on either side returns 0 (no parse).
   CheckNear(0.0, GridHaversineKm('FN3', 'DM18'), 0.0, 'short grid1');
   CheckNear(0.0, GridHaversineKm('FN36', 'DM'),  0.0, 'short grid2');
   CheckNear(0.0, GridHaversineKm('', ''),        0.0, 'both empty');
end;

procedure TGridDistanceTests.Test_CaseInsensitive;
begin
   BeginTest('Test_CaseInsensitive');
   // GridCenterDeg UpperCases its input, so lowercase grids match.
   CheckNear(GridHaversineKm('FN36', 'DM18'),
             GridHaversineKm('fn36', 'dm18'), 1.0e-9, 'case-insensitive');
end;

procedure TGridDistanceTests.Test_LongGrid_UsesFirstFour;
begin
   BeginTest('Test_LongGrid_UsesFirstFour');
   // Only the first four characters drive the 4-char calculation; a 6-char
   // grid with the same first four yields the same distance.
   CheckNear(GridHaversineKm('FN36', 'DM18'),
             GridHaversineKm('FN36ux', 'DM18qr'), 1.0e-9, '6-char uses first 4');
end;

procedure TGridDistanceTests.RunAllTests;
begin
   Test_FN36_to_DM18_RulesFixture;
   Test_Symmetry;
   Test_SameGrid_IsZero;
   Test_ShortGrid_ReturnsZero;
   Test_CaseInsensitive;
   Test_LongGrid_UsesFirstFour;
end;

end.
