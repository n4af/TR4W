unit uTestADIFRegression;

{
  Targeted regression tests for ADIF bugs fixed during the 4.147.x cycle.
  These complement the broader uTestADIF / uTestADIFFixtures suites by pinning
  the specific defects so they cannot silently return.

  All three exercise uADIF's pure, MainUnit-free entry points
  (ImportADIFFromString, EmitADIFRecord), so no trdos/UI linkage is needed.
}

interface

uses
   SysUtils, VC, uADIF, uTR4WTestFramework;

type
   TADIFRegressionTests = class(TTestCase)
   public
      procedure RunAllTests; override;
   private
      procedure Test_Import_CQZField_PopulatesZone;
      procedure Test_Import_NoModeField_StaysNoMode;
      procedure Test_Emit_ContestID_FallbackForMajors;
   end;

implementation

procedure TADIFRegressionTests.Test_Import_CQZField_PopulatesZone;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_Import_CQZField_PopulatesZone');
   // v4.147.04: the import field-name table had 'CQ_Z' instead of 'CQZ', so
   // TR4W's own <CQZ:N> export never re-imported the CQ zone -- silent data
   // loss on every CQ-zone contest.  Import must now land CQZ into exch.Zone.
   CheckEquals(1, ImportADIFFromString(
      '<CALL:4>KG1S <BAND:3>20m <CQZ:2>14 <EOR>', records),
      'one record parsed');
   CheckEquals(14, Integer(records[0].Zone), 'CQZ field populated exch.Zone');
end;

procedure TADIFRegressionTests.Test_Import_NoModeField_StaysNoMode;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_Import_NoModeField_StaysNoMode');
   // v4.147.04: FillChar zero-init left Mode = first enum (CW), so an imported
   // record lacking a <MODE> field silently became CW.  InitContestExchangeForParse
   // now sets Mode := NoMode explicitly; a MODE-less record must stay NoMode.
   CheckEquals(1, ImportADIFFromString(
      '<CALL:4>KG1S <BAND:3>20m <EOR>', records),
      'one record parsed');
   CheckEquals(Integer(NoMode), Integer(records[0].Mode),
               'no MODE field -> NoMode, not CW');
end;

procedure TADIFRegressionTests.Test_Emit_ContestID_FallbackForMajors;
var
   rec : ContestExchange;
   s   : string;
begin
   BeginTest('Test_Emit_ContestID_FallbackForMajors');
   // v4.147.13 (#887 follow-up): EmitADIFRecord dropped CONTEST_ID for the
   // ~156 contests whose ContestsArray[].ADIFName is empty (CQ-WW, CQ-WPX,
   // ARRL-DX, ...).  It must fall back to the parallel ContestTypeSA[] string,
   // which is the standard ADIF Contest_ID for the majors.
   FillChar(rec, SizeOf(rec), 0);
   rec.ceContest := CQWWCW;
   rec.Band      := Band20;
   rec.Callsign  := 'KG1S';
   s := EmitADIFRecord(rec);
   CheckTrue(Pos('<CONTEST_ID', s) > 0,
             'CONTEST_ID emitted for CQ-WW-CW (not dropped)');
   CheckTrue(Pos('CQ-WW-CW', s) > 0,
             'CONTEST_ID value falls back to ContestTypeSA');
end;

procedure TADIFRegressionTests.RunAllTests;
begin
   Test_Import_CQZField_PopulatesZone;
   Test_Import_NoModeField_StaysNoMode;
   Test_Emit_ContestID_FallbackForMajors;
end;

end.
