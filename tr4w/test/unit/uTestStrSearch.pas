unit uTestStrSearch;

{
  Golden-master tests for src/uStrSearch.pas (PChar search helpers extracted
  from TF.pas for the Issue #997 inline-asm removal).

  These freeze the EXACT behavior of the original x86 inline-asm bodies so the
  Pascal/RTL rewrite can be proven equivalent. Run order:

    1. Add this suite while uStrSearch still holds the asm bodies -> all green
       (this is the frozen baseline).
    2. Replace the asm with RTL / pure Pascal.
    3. Re-run -> must stay green.

  Pointer results are checked as integer offsets into the source buffer
  (-1 == nil), which uniquely pins down each match position.

  StrPosPartial quirk under test: '?' in the pattern matches any single
  character EXCEPT at the pattern's first character, which the asm always
  matches literally (it seeds the scan with an exact match on Str2[0]).
}

interface

uses
   SysUtils, uTR4WTestFramework, uStrSearch;

type
   TStrSearchTests = class(TTestCase)
   protected
      // Returns the offset of p within base, or -1 if p is nil.
      function Off(base, p: PChar): integer;

      // StrPos -- exact substring search
      procedure Test_StrPos_Start;
      procedure Test_StrPos_Middle;
      procedure Test_StrPos_End;
      procedure Test_StrPos_NotFound;
      procedure Test_StrPos_WholeString;
      procedure Test_StrPos_Overlap;
      procedure Test_StrPos_RepeatedFirstChar;
      procedure Test_StrPos_EmptyPattern;
      procedure Test_StrPos_PatternLongerThanText;
      procedure Test_StrPos_NilArgs;

      // StrComp_JOH_IA32_6 -- strcmp (-1 / 0 / +1)
      procedure Test_StrComp_Equal;
      procedure Test_StrComp_Less;
      procedure Test_StrComp_Greater;
      procedure Test_StrComp_PrefixShorter;
      procedure Test_StrComp_PrefixLonger;
      procedure Test_StrComp_BothEmpty;
      procedure Test_StrComp_EmptyVsNonEmpty;
      procedure Test_StrComp_NonEmptyVsEmpty;

      // StrPosPartial -- '?' wildcard (first char literal)
      procedure Test_Partial_NoWildcard;
      procedure Test_Partial_MidWildcard;
      procedure Test_Partial_MultipleWildcards;
      procedure Test_Partial_LeadingQuestionIsLiteral_Found;
      procedure Test_Partial_LeadingQuestionIsLiteral_NotFound;
      procedure Test_Partial_BacktrackRetry;
      procedure Test_Partial_NotFound;
      procedure Test_Partial_PatternLongerThanText;
      procedure Test_Partial_EmptyPattern;
      procedure Test_Partial_NilArgs;
      procedure Test_Partial_SCPStyle;

   public
      procedure RunAllTests; override;
   end;

implementation

function TStrSearchTests.Off(base, p: PChar): integer;
begin
   if p = nil then
      Result := -1
   else
      Result := p - base;
end;

// ---------------------------------------------------------------------------
// StrPos
// ---------------------------------------------------------------------------

procedure TStrSearchTests.Test_StrPos_Start;
var s: PChar;
begin
   BeginTest('Test_StrPos_Start');
   s := 'ABCDEF';
   CheckEquals(0, Off(s, StrPos(s, 'ABC')), 'StrPos start');
end;

procedure TStrSearchTests.Test_StrPos_Middle;
var s: PChar;
begin
   BeginTest('Test_StrPos_Middle');
   s := 'HELLO WORLD';
   CheckEquals(6, Off(s, StrPos(s, 'WORLD')), 'StrPos middle');
end;

procedure TStrSearchTests.Test_StrPos_End;
var s: PChar;
begin
   BeginTest('Test_StrPos_End');
   s := 'ABCDEF';
   CheckEquals(4, Off(s, StrPos(s, 'EF')), 'StrPos end');
end;

procedure TStrSearchTests.Test_StrPos_NotFound;
var s: PChar;
begin
   BeginTest('Test_StrPos_NotFound');
   s := 'ABCDEF';
   CheckEquals(-1, Off(s, StrPos(s, 'XYZ')), 'StrPos not found -> nil');
end;

procedure TStrSearchTests.Test_StrPos_WholeString;
var s: PChar;
begin
   BeginTest('Test_StrPos_WholeString');
   s := 'ABC';
   CheckEquals(0, Off(s, StrPos(s, 'ABC')), 'StrPos whole-string match');
end;

procedure TStrSearchTests.Test_StrPos_Overlap;
var s: PChar;
begin
   BeginTest('Test_StrPos_Overlap');
   s := 'AAB';
   CheckEquals(1, Off(s, StrPos(s, 'AB')), 'StrPos overlap');
end;

procedure TStrSearchTests.Test_StrPos_RepeatedFirstChar;
var s: PChar;
begin
   BeginTest('Test_StrPos_RepeatedFirstChar');
   s := 'XXXY';
   CheckEquals(2, Off(s, StrPos(s, 'XY')), 'StrPos repeated first char');
end;

procedure TStrSearchTests.Test_StrPos_EmptyPattern;
var s: PChar;
begin
   BeginTest('Test_StrPos_EmptyPattern');
   // The asm returns nil for an empty pattern (len(str2)=0 -> JE @@2).
   s := 'ABC';
   CheckEquals(-1, Off(s, StrPos(s, '')), 'StrPos empty pattern -> nil');
end;

procedure TStrSearchTests.Test_StrPos_PatternLongerThanText;
var s: PChar;
begin
   BeginTest('Test_StrPos_PatternLongerThanText');
   s := 'AB';
   CheckEquals(-1, Off(s, StrPos(s, 'ABCDE')), 'StrPos pattern longer -> nil');
end;

procedure TStrSearchTests.Test_StrPos_NilArgs;
begin
   BeginTest('Test_StrPos_NilArgs');
   CheckTrue(StrPos(nil, 'A') = nil, 'StrPos nil str1');
   CheckTrue(StrPos('A', nil) = nil, 'StrPos nil str2');
end;

// ---------------------------------------------------------------------------
// StrComp_JOH_IA32_6
// ---------------------------------------------------------------------------

procedure TStrSearchTests.Test_StrComp_Equal;
begin
   BeginTest('Test_StrComp_Equal');
   CheckEquals(0, StrComp_JOH_IA32_6('ABC', 'ABC'), 'equal');
end;

procedure TStrSearchTests.Test_StrComp_Less;
begin
   BeginTest('Test_StrComp_Less');
   CheckEquals(-1, StrComp_JOH_IA32_6('ABC', 'ABD'), 'less -> -1');
end;

procedure TStrSearchTests.Test_StrComp_Greater;
begin
   BeginTest('Test_StrComp_Greater');
   CheckEquals(1, StrComp_JOH_IA32_6('ABD', 'ABC'), 'greater -> +1');
end;

procedure TStrSearchTests.Test_StrComp_PrefixShorter;
begin
   BeginTest('Test_StrComp_PrefixShorter');
   CheckEquals(-1, StrComp_JOH_IA32_6('AB', 'ABC'), 'prefix shorter -> -1');
end;

procedure TStrSearchTests.Test_StrComp_PrefixLonger;
begin
   BeginTest('Test_StrComp_PrefixLonger');
   CheckEquals(1, StrComp_JOH_IA32_6('ABC', 'AB'), 'prefix longer -> +1');
end;

procedure TStrSearchTests.Test_StrComp_BothEmpty;
begin
   BeginTest('Test_StrComp_BothEmpty');
   CheckEquals(0, StrComp_JOH_IA32_6('', ''), 'both empty -> 0');
end;

procedure TStrSearchTests.Test_StrComp_EmptyVsNonEmpty;
begin
   BeginTest('Test_StrComp_EmptyVsNonEmpty');
   CheckEquals(-1, StrComp_JOH_IA32_6('', 'A'), 'empty vs non-empty -> -1');
end;

procedure TStrSearchTests.Test_StrComp_NonEmptyVsEmpty;
begin
   BeginTest('Test_StrComp_NonEmptyVsEmpty');
   CheckEquals(1, StrComp_JOH_IA32_6('A', ''), 'non-empty vs empty -> +1');
end;

// ---------------------------------------------------------------------------
// StrPosPartial
// ---------------------------------------------------------------------------

procedure TStrSearchTests.Test_Partial_NoWildcard;
var s: PChar;
begin
   BeginTest('Test_Partial_NoWildcard');
   s := 'HELLO';
   CheckEquals(2, Off(s, StrPosPartial(s, 'LLO')), 'partial no-wildcard');
end;

procedure TStrSearchTests.Test_Partial_MidWildcard;
var s: PChar;
begin
   BeginTest('Test_Partial_MidWildcard');
   s := 'HELLO';
   // 'H?LLO' : '?' matches 'E'
   CheckEquals(0, Off(s, StrPosPartial(s, 'H?LLO')), 'partial mid wildcard');
end;

procedure TStrSearchTests.Test_Partial_MultipleWildcards;
var s: PChar;
begin
   BeginTest('Test_Partial_MultipleWildcards');
   s := 'ABCDE';
   // 'A???E' : the three '?' match B,C,D
   CheckEquals(0, Off(s, StrPosPartial(s, 'A???E')), 'partial multi wildcard');
end;

procedure TStrSearchTests.Test_Partial_LeadingQuestionIsLiteral_Found;
var s: PChar;
begin
   BeginTest('Test_Partial_LeadingQuestionIsLiteral_Found');
   // Leading '?' is matched literally: it must find an actual '?' char.
   s := 'X?Y';
   CheckEquals(1, Off(s, StrPosPartial(s, '?Y')), 'leading ? literal, found');
end;

procedure TStrSearchTests.Test_Partial_LeadingQuestionIsLiteral_NotFound;
var s: PChar;
begin
   BeginTest('Test_Partial_LeadingQuestionIsLiteral_NotFound');
   // No literal '?' present -> leading '?' cannot wildcard the first char.
   s := 'XAY';
   CheckEquals(-1, Off(s, StrPosPartial(s, '?Y')), 'leading ? literal, not found');
end;

procedure TStrSearchTests.Test_Partial_BacktrackRetry;
var s: PChar;
begin
   BeginTest('Test_Partial_BacktrackRetry');
   // First 'X' at 0 fails ('C' vs str1[2]='X'); retry finds 'X' at 2 -> match.
   s := 'XAXBC';
   CheckEquals(2, Off(s, StrPosPartial(s, 'X?C')), 'partial backtrack/retry');
end;

procedure TStrSearchTests.Test_Partial_NotFound;
var s: PChar;
begin
   BeginTest('Test_Partial_NotFound');
   s := 'ABC';
   CheckEquals(-1, Off(s, StrPosPartial(s, 'X?Z')), 'partial not found');
end;

procedure TStrSearchTests.Test_Partial_PatternLongerThanText;
var s: PChar;
begin
   BeginTest('Test_Partial_PatternLongerThanText');
   s := 'AB';
   CheckEquals(-1, Off(s, StrPosPartial(s, 'A???')), 'partial pattern longer -> nil');
end;

procedure TStrSearchTests.Test_Partial_EmptyPattern;
var s: PChar;
begin
   BeginTest('Test_Partial_EmptyPattern');
   s := 'ABC';
   CheckEquals(-1, Off(s, StrPosPartial(s, '')), 'partial empty pattern -> nil');
end;

procedure TStrSearchTests.Test_Partial_NilArgs;
begin
   BeginTest('Test_Partial_NilArgs');
   CheckTrue(StrPosPartial(nil, 'A') = nil, 'partial nil str1');
   CheckTrue(StrPosPartial('A', nil) = nil, 'partial nil str2');
end;

procedure TStrSearchTests.Test_Partial_SCPStyle;
var s: PChar;
begin
   BeginTest('Test_Partial_SCPStyle');
   // Representative super-check-partial use: a partial callsign with a '?'
   // standing in for an unknown character, located inside a master record.
   s := 'N6TR';
   CheckEquals(0, Off(s, StrPosPartial(s, 'N?TR')), 'partial SCP-style match');
end;

// ---------------------------------------------------------------------------
// Test runner
// ---------------------------------------------------------------------------

procedure TStrSearchTests.RunAllTests;
begin
   Test_StrPos_Start;
   Test_StrPos_Middle;
   Test_StrPos_End;
   Test_StrPos_NotFound;
   Test_StrPos_WholeString;
   Test_StrPos_Overlap;
   Test_StrPos_RepeatedFirstChar;
   Test_StrPos_EmptyPattern;
   Test_StrPos_PatternLongerThanText;
   Test_StrPos_NilArgs;

   Test_StrComp_Equal;
   Test_StrComp_Less;
   Test_StrComp_Greater;
   Test_StrComp_PrefixShorter;
   Test_StrComp_PrefixLonger;
   Test_StrComp_BothEmpty;
   Test_StrComp_EmptyVsNonEmpty;
   Test_StrComp_NonEmptyVsEmpty;

   Test_Partial_NoWildcard;
   Test_Partial_MidWildcard;
   Test_Partial_MultipleWildcards;
   Test_Partial_LeadingQuestionIsLiteral_Found;
   Test_Partial_LeadingQuestionIsLiteral_NotFound;
   Test_Partial_BacktrackRetry;
   Test_Partial_NotFound;
   Test_Partial_PatternLongerThanText;
   Test_Partial_EmptyPattern;
   Test_Partial_NilArgs;
   Test_Partial_SCPStyle;
end;

end.
