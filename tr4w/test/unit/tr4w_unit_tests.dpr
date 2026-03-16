program tr4w_unit_tests;

{
  TR4W Automated Unit Test Runner
  Delphi 7 — console application, no VCL.

  Usage:
    tr4w_unit_tests.exe
    Exit code 0 = all tests passed.
    Exit code 1 = one or more failures.

  DUnitX migration (Delphi 12 Phase 4):
    Replace the main block with:
      var Runner := TDUnitX.CreateRunner;
      Runner.Run;
    Add [TestFixture]/[Test] attributes to each suite class.
    Remove RegisterSuite calls and RunAllSuites.
}

{$APPTYPE CONSOLE}

uses
   SysUtils,
   uTR4WTestFramework in 'uTR4WTestFramework.pas',
   uIcomCIV         in '..\..\src\uIcomCIV.pas',
   uTestIcomCIV     in 'uTestIcomCIV.pas',
   uRadioBand       in '..\..\src\uRadioBand.pas',
   uTestRadioBand   in 'uTestRadioBand.pas';

begin
   IsMultiThread := True;  // Match main application setting

   WriteLn('=== TR4W Unit Tests ===');
   WriteLn('');

   RegisterSuite(TIcomCIVTests.Create('IcomCIV'));
   RegisterSuite(TRadioBandTests.Create('RadioBand'));

   if RunAllSuites then
      begin
      WriteLn('');
      WriteLn('All tests passed.');
      ExitCode := 0;
      end
   else
      begin
      WriteLn('');
      WriteLn('FAILURES detected — see above.');
      ExitCode := 1;
      end;
end.
