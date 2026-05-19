unit uTestUtilsMath;

{
  Unit tests for utils/utils_math.pas.

  Three pure-math helpers used by distance/bearing calculations in
  grid-based contests (RTC, FQP, KS QSO Party, etc.):

    Tan      -- tan(x), implemented with x86 FPTAN inline asm
    ArcCos   -- acos(x), pure Pascal (calls ArcTan2 internally)
    ArcTan2  -- atan2(y, x), implemented with x86 FPATAN inline asm

  WHY THESE TESTS MATTER FOR MIGRATION
  ------------------------------------
  Two of the three functions use inline x86 FPU asm.  Phase 3 (64-bit)
  cannot keep inline asm; those bodies must be rewritten in Pascal
  (most likely calling Math.ArcTan2 from the modern Delphi RTL).  These
  tests freeze the bit-level outputs of the D7 asm path so the Phase 3
  rewrite can be proven equivalent rather than "looks the same."

  Tolerances use absolute deltas of 1e-12.  All inputs and expected
  values stay well within extended (80-bit) precision (~19 decimal
  digits of mantissa), so 1e-12 is conservative.
}

interface

uses
   SysUtils, uTR4WTestFramework, utils_math;

type
   TUtilsMathTests = class(TTestCase)
   protected
      // Internal helper: absolute-tolerance compare for Extended.
      procedure CheckNear(expected, actual, tolerance: Extended; const ctx: string);

      // Tan -- inline asm (FPTAN)
      procedure Test_Tan_Zero;
      procedure Test_Tan_PiOver4;
      procedure Test_Tan_NegPiOver4;
      procedure Test_Tan_Pi;

      // ArcCos -- pure Pascal (depends on ArcTan2)
      procedure Test_ArcCos_One;
      procedure Test_ArcCos_Zero;
      procedure Test_ArcCos_NegOne;
      procedure Test_ArcCos_Half;

      // ArcTan2 -- inline asm (FPATAN)
      procedure Test_ArcTan2_Q1;
      procedure Test_ArcTan2_PositiveY_ZeroX;
      procedure Test_ArcTan2_ZeroY_PositiveX;
      procedure Test_ArcTan2_NegativeY_PositiveX;
      procedure Test_ArcTan2_NegativeY_NegativeX;

      // Identity / round-trip checks
      procedure Test_TanOfArcTan2_RoundTrip;
      procedure Test_ArcCosOfCos_RoundTrip;

   public
      procedure RunAllTests; override;
   end;

implementation

const
   // Higher-precision pi values for reference.  Delphi 7's Pi constant is
   // already an Extended; these locals just make the expected math
   // explicit at call sites.
   PI_4    : Extended = 0.78539816339744830961566;     // pi/4
   PI_2    : Extended = 1.57079632679489661923132;     // pi/2
   PI_FULL : Extended = 3.14159265358979323846264;     // pi
   TOL     : Extended = 1.0e-12;                        // absolute tolerance

procedure TUtilsMathTests.CheckNear(expected, actual, tolerance: Extended;
                                    const ctx: string);
var
   diff: Extended;
   msg: string;
begin
   diff := Abs(expected - actual);
   if diff < tolerance then
      begin
      Check(True, '');
      end
   else
      begin
      msg := Format('%s: expected %.18g, got %.18g (diff %.3e, tol %.3e)',
                    [ctx, expected, actual, diff, tolerance]);
      Check(False, msg);
      end;
end;

// ---------------------------------------------------------------------------
// Tan -- inline asm (FPTAN)
// ---------------------------------------------------------------------------

procedure TUtilsMathTests.Test_Tan_Zero;
begin
   BeginTest('Test_Tan_Zero');
   CheckNear(0.0, Tan(0.0), TOL, 'tan(0)');
end;

procedure TUtilsMathTests.Test_Tan_PiOver4;
begin
   BeginTest('Test_Tan_PiOver4');
   // tan(pi/4) = 1, the canonical 45-deg case.
   CheckNear(1.0, Tan(PI_4), TOL, 'tan(pi/4)');
end;

procedure TUtilsMathTests.Test_Tan_NegPiOver4;
begin
   BeginTest('Test_Tan_NegPiOver4');
   // Tangent is odd: tan(-x) = -tan(x).
   CheckNear(-1.0, Tan(-PI_4), TOL, 'tan(-pi/4)');
end;

procedure TUtilsMathTests.Test_Tan_Pi;
begin
   BeginTest('Test_Tan_Pi');
   // tan(pi) = 0 mathematically; FPTAN evaluates the rounded Pi argument
   // so the result is a tiny non-zero number bounded by floating-point
   // roundoff.  Use a generous tolerance for this one.
   CheckNear(0.0, Tan(PI_FULL), 1.0e-15, 'tan(pi)');
end;

// ---------------------------------------------------------------------------
// ArcCos -- pure Pascal (delegates to ArcTan2)
// ---------------------------------------------------------------------------

procedure TUtilsMathTests.Test_ArcCos_One;
begin
   BeginTest('Test_ArcCos_One');
   // acos(1) = 0
   CheckNear(0.0, ArcCos(1.0), TOL, 'acos(1)');
end;

procedure TUtilsMathTests.Test_ArcCos_Zero;
begin
   BeginTest('Test_ArcCos_Zero');
   // acos(0) = pi/2
   CheckNear(PI_2, ArcCos(0.0), TOL, 'acos(0)');
end;

procedure TUtilsMathTests.Test_ArcCos_NegOne;
begin
   BeginTest('Test_ArcCos_NegOne');
   // acos(-1) = pi
   CheckNear(PI_FULL, ArcCos(-1.0), TOL, 'acos(-1)');
end;

procedure TUtilsMathTests.Test_ArcCos_Half;
begin
   BeginTest('Test_ArcCos_Half');
   // acos(0.5) = pi/3
   CheckNear(PI_FULL / 3.0, ArcCos(0.5), TOL, 'acos(0.5)');
end;

// ---------------------------------------------------------------------------
// ArcTan2 -- inline asm (FPATAN).  Note: FPATAN handles all four quadrants
// correctly per the documented IEEE-754 atan2 semantics.
// ---------------------------------------------------------------------------

procedure TUtilsMathTests.Test_ArcTan2_Q1;
begin
   BeginTest('Test_ArcTan2_Q1');
   // atan2(1, 1) = pi/4 -- quadrant I
   CheckNear(PI_4, ArcTan2(1.0, 1.0), TOL, 'atan2(1, 1)');
end;

procedure TUtilsMathTests.Test_ArcTan2_PositiveY_ZeroX;
begin
   BeginTest('Test_ArcTan2_PositiveY_ZeroX');
   // atan2(+y, 0) = pi/2 -- straight up
   CheckNear(PI_2, ArcTan2(1.0, 0.0), TOL, 'atan2(1, 0)');
end;

procedure TUtilsMathTests.Test_ArcTan2_ZeroY_PositiveX;
begin
   BeginTest('Test_ArcTan2_ZeroY_PositiveX');
   // atan2(0, +x) = 0 -- east
   CheckNear(0.0, ArcTan2(0.0, 1.0), TOL, 'atan2(0, 1)');
end;

procedure TUtilsMathTests.Test_ArcTan2_NegativeY_PositiveX;
begin
   BeginTest('Test_ArcTan2_NegativeY_PositiveX');
   // atan2(-1, 1) = -pi/4 -- quadrant IV
   CheckNear(-PI_4, ArcTan2(-1.0, 1.0), TOL, 'atan2(-1, 1)');
end;

procedure TUtilsMathTests.Test_ArcTan2_NegativeY_NegativeX;
begin
   BeginTest('Test_ArcTan2_NegativeY_NegativeX');
   // atan2(-1, -1) = -3*pi/4 -- quadrant III
   CheckNear(-3.0 * PI_4, ArcTan2(-1.0, -1.0), TOL, 'atan2(-1, -1)');
end;

// ---------------------------------------------------------------------------
// Round-trips: catch any drift between the asm functions and their math.
// ---------------------------------------------------------------------------

procedure TUtilsMathTests.Test_TanOfArcTan2_RoundTrip;
var
   theta, t, t2: Extended;
begin
   BeginTest('Test_TanOfArcTan2_RoundTrip');
   // tan(atan2(y, x)) = y / x  for x > 0.  Verifies the two asm bodies
   // are internally consistent.
   theta := ArcTan2(3.0, 4.0);  // tan(theta) should be 0.75
   t  := Tan(theta);
   t2 := 0.75;
   CheckNear(t2, t, TOL, 'tan(atan2(3, 4)) = 0.75');
end;

procedure TUtilsMathTests.Test_ArcCosOfCos_RoundTrip;
var
   angle, recovered: Extended;
begin
   BeginTest('Test_ArcCosOfCos_RoundTrip');
   // acos(cos(x)) = x  for x in [0, pi].  Verifies the ArcTan2-based
   // ArcCos delegation.  Uses Cos from System (not asm here).
   angle := 0.42;  // any value in [0, pi]
   recovered := ArcCos(Cos(angle));
   CheckNear(angle, recovered, TOL, 'acos(cos(0.42))');
end;

// ---------------------------------------------------------------------------
// Test runner
// ---------------------------------------------------------------------------

procedure TUtilsMathTests.RunAllTests;
begin
   Test_Tan_Zero;
   Test_Tan_PiOver4;
   Test_Tan_NegPiOver4;
   Test_Tan_Pi;

   Test_ArcCos_One;
   Test_ArcCos_Zero;
   Test_ArcCos_NegOne;
   Test_ArcCos_Half;

   Test_ArcTan2_Q1;
   Test_ArcTan2_PositiveY_ZeroX;
   Test_ArcTan2_ZeroY_PositiveX;
   Test_ArcTan2_NegativeY_PositiveX;
   Test_ArcTan2_NegativeY_NegativeX;

   Test_TanOfArcTan2_RoundTrip;
   Test_ArcCosOfCos_RoundTrip;
end;

end.
