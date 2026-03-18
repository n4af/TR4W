unit uTR4WTestFramework;

{
  Minimal unit test framework for TR4W.
  Delphi 7 compatible — no external dependencies.

  DUnit/DUnitX migration path (Phase 4 — Delphi 12):
    1. Replace this unit's uses clause with TestFramework (DUnit)
       or DUnitX.TestFramework.
    2. Add [TestFixture] attribute above each TTestCase subclass.
    3. Add [Test] attribute above each published test method.
    4. Remove the explicit RunAllTests override and test method calls.
    5. Replace RegisterSuite/RunAllSuites with DUnitX runner call.
    The test classes and all Check* logic need no changes.
}

interface

uses
   SysUtils;

type
   ETestFailed = class(Exception);

   // Base class for a group of related tests.
   // Subclasses override RunAllTests to call each test method in turn.
   TTestCase = class
   private
      FName      : string;
      FPassCount : Integer;
      FFailCount : Integer;

      procedure RecordPass(const TestMethod: string);
      procedure RecordFail(const TestMethod, Msg: string);

   protected
      // Current test method name — set by BeginTest before each call.
      FCurrentMethod: string;

      procedure SetUp; virtual;
      procedure TearDown; virtual;

      // Assertion helpers — same names as DUnit/DUnitX.
      procedure Check(Condition: Boolean; const Msg: string = '');
      procedure CheckTrue(Condition: Boolean; const Msg: string = '');
      procedure CheckFalse(Condition: Boolean; const Msg: string = '');
      procedure CheckEquals(Expected, Actual: Integer;       const Msg: string = ''); overload;
      procedure CheckEquals(const Expected, Actual: string;  const Msg: string = ''); overload;

      // Call this at the top of each test method.
      procedure BeginTest(const MethodName: string);

   public
      constructor Create(const AName: string); virtual;

      // Override to call each TestXxx method in sequence.
      procedure RunAllTests; virtual; abstract;

      property Name      : string  read FName;
      property PassCount : Integer read FPassCount;
      property FailCount : Integer read FFailCount;
   end;

// ---------------------------------------------------------------------------
// Suite registry — collect suites, then run them all.
// ---------------------------------------------------------------------------

procedure RegisterSuite(Suite: TTestCase);
function  RunAllSuites: Boolean;  // Returns True if every test passes.

implementation

var
   GSuites     : array[0..63] of TTestCase;
   GSuiteCount : Integer = 0;

// ---------------------------------------------------------------------------
// TTestCase
// ---------------------------------------------------------------------------

constructor TTestCase.Create(const AName: string);
begin
   inherited Create;
   FName      := AName;
   FPassCount := 0;
   FFailCount := 0;
end;

procedure TTestCase.SetUp;
begin
   // Default: nothing
end;

procedure TTestCase.TearDown;
begin
   // Default: nothing
end;

procedure TTestCase.BeginTest(const MethodName: string);
begin
   FCurrentMethod := MethodName;
   SetUp;
end;

procedure TTestCase.RecordPass(const TestMethod: string);
begin
   Inc(FPassCount);
   WriteLn('[PASS] ', FName, ': ', TestMethod);
end;

procedure TTestCase.RecordFail(const TestMethod, Msg: string);
begin
   Inc(FFailCount);
   WriteLn('[FAIL] ', FName, ': ', TestMethod, ' — ', Msg);
end;

procedure TTestCase.Check(Condition: Boolean; const Msg: string);
begin
   if Condition then
      RecordPass(FCurrentMethod)
   else
      begin
      if Msg <> '' then
         RecordFail(FCurrentMethod, Msg)
      else
         RecordFail(FCurrentMethod, 'Condition was False');
      end;
   TearDown;
end;

procedure TTestCase.CheckTrue(Condition: Boolean; const Msg: string);
begin
   Check(Condition, Msg);
end;

procedure TTestCase.CheckFalse(Condition: Boolean; const Msg: string);
begin
   Check(not Condition, Msg);
end;

procedure TTestCase.CheckEquals(Expected, Actual: Integer; const Msg: string);
var
   M: string;
begin
   if Expected = Actual then
      RecordPass(FCurrentMethod)
   else
      begin
      M := Format('Expected %d but got %d', [Expected, Actual]);
      if Msg <> '' then M := Msg + ' (' + M + ')';
      RecordFail(FCurrentMethod, M);
      end;
   TearDown;
end;

procedure TTestCase.CheckEquals(const Expected, Actual: string; const Msg: string);
var
   M: string;
begin
   if Expected = Actual then
      RecordPass(FCurrentMethod)
   else
      begin
      M := Format('Expected "%s" but got "%s"', [Expected, Actual]);
      if Msg <> '' then M := Msg + ' (' + M + ')';
      RecordFail(FCurrentMethod, M);
      end;
   TearDown;
end;

// ---------------------------------------------------------------------------
// Registry
// ---------------------------------------------------------------------------

procedure RegisterSuite(Suite: TTestCase);
begin
   if GSuiteCount < Length(GSuites) then
      begin
      GSuites[GSuiteCount] := Suite;
      Inc(GSuiteCount);
      end;
end;

function RunAllSuites: Boolean;
var
   i          : Integer;
   totalPass  : Integer;
   totalFail  : Integer;
   suite      : TTestCase;
begin
   totalPass := 0;
   totalFail := 0;

   for i := 0 to GSuiteCount - 1 do
      begin
      suite := GSuites[i];
      WriteLn('--- ', suite.Name, ' ---');
      suite.RunAllTests;
      Inc(totalPass, suite.PassCount);
      Inc(totalFail, suite.FailCount);
      suite.Free;
      end;

   WriteLn('');
   WriteLn('PASSED: ', totalPass, '  FAILED: ', totalFail);
   Result := (totalFail = 0);
end;

end.
