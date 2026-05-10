unit uTestUtilsText;

{
  Tests for utils_text.pas string predicate functions.

  Functions NOT tested here (easily replaced by Delphi 12 stdlib):
    UpperCase, StringHas, StringHasNumber, StringHasLetters,
    StringHasLowerCase, tCharIsNumbers, tCharIsAlphaNumericOrDash,
    PostcedingString, PrecedingString, tPos, pPos, StrComp,
    StrUpper, safeFloat.

  Functions tested:
    StringIsAllNumbers               -- used in exchange field parsing
    StringIsAllNumbersOrSpaces       -- used in exchange field validation
    StringIsAllNumbersOrDecimal      -- used in frequency/RST parsing
    StringIsAllAlphanumericOrDash    -- park/callsign validation; bNoCase added Issue #877
    StringWithFirstWordDeleted       -- no stdlib equivalent; edge cases non-obvious
}

interface

uses
   uTR4WTestFramework;

type
   TUtilsTextTests = class(TTestCase)
   public
      procedure RunAllTests; override;

   private
      procedure Test_StringIsAllNumbers;
      procedure Test_StringIsAllNumbersOrSpaces;
      procedure Test_StringIsAllNumbersOrDecimal;
      procedure Test_StringIsAllAlphanumericOrDash;
      procedure Test_StringWithFirstWordDeleted;
   end;

implementation

uses
   utils_text;

// ---------------------------------------------------------------------------
// StringIsAllNumbers
// ---------------------------------------------------------------------------

procedure TUtilsTextTests.Test_StringIsAllNumbers;
begin
   BeginTest('Test_StringIsAllNumbers');

   // Empty string must return false — the function guards explicitly
   CheckFalse(StringIsAllNumbers(''), 'empty string');

   // Pure digit strings
   CheckTrue(StringIsAllNumbers('0'), 'single zero');
   CheckTrue(StringIsAllNumbers('12345'), 'multi-digit');
   CheckTrue(StringIsAllNumbers('001'), 'leading zeros');

   // Any non-digit character must reject
   CheckFalse(StringIsAllNumbers('12.3'), 'decimal point');
   CheckFalse(StringIsAllNumbers('12 3'), 'embedded space');
   CheckFalse(StringIsAllNumbers('1A3'), 'embedded letter');
   CheckFalse(StringIsAllNumbers('-1'), 'leading minus');
end;

// ---------------------------------------------------------------------------
// StringIsAllNumbersOrSpaces
// ---------------------------------------------------------------------------

procedure TUtilsTextTests.Test_StringIsAllNumbersOrSpaces;
begin
   BeginTest('Test_StringIsAllNumbersOrSpaces');

   // Empty string must return false
   CheckFalse(StringIsAllNumbersOrSpaces(''), 'empty string');

   // Valid combinations
   CheckTrue(StringIsAllNumbersOrSpaces('123'), 'digits only');
   CheckTrue(StringIsAllNumbersOrSpaces('12 34'), 'digits and space');
   CheckTrue(StringIsAllNumbersOrSpaces('   '), 'spaces only');
   CheckTrue(StringIsAllNumbersOrSpaces(' 1 '), 'leading/trailing spaces');

   // Any other character must reject
   CheckFalse(StringIsAllNumbersOrSpaces('12.3'), 'decimal point');
   CheckFalse(StringIsAllNumbersOrSpaces('1A3'), 'letter');
end;

// ---------------------------------------------------------------------------
// StringIsAllNumbersOrDecimal
// ---------------------------------------------------------------------------

procedure TUtilsTextTests.Test_StringIsAllNumbersOrDecimal;
begin
   BeginTest('Test_StringIsAllNumbersOrDecimal');

   // Empty string must return false
   CheckFalse(StringIsAllNumbersOrDecimal(''), 'empty string');

   // Valid combinations
   CheckTrue(StringIsAllNumbersOrDecimal('14150'), 'integer frequency');
   CheckTrue(StringIsAllNumbersOrDecimal('14.150'), 'standard decimal');
   CheckTrue(StringIsAllNumbersOrDecimal('.5'), 'leading decimal');
   CheckTrue(StringIsAllNumbersOrDecimal('3.'), 'trailing decimal');

   // The function accepts any number of dots — documents current behavior
   // (no structural validation, only character-level)
   CheckTrue(StringIsAllNumbersOrDecimal('1.4.1'), 'two dots passes char check');

   // Non-digit, non-dot characters must reject
   CheckFalse(StringIsAllNumbersOrDecimal('14,150'), 'comma');
   CheckFalse(StringIsAllNumbersOrDecimal('14 150'), 'space');
   CheckFalse(StringIsAllNumbersOrDecimal('14MHz'), 'letters');
end;

// ---------------------------------------------------------------------------
// StringIsAllAlphanumericOrDash
// ---------------------------------------------------------------------------

procedure TUtilsTextTests.Test_StringIsAllAlphanumericOrDash;
begin
   BeginTest('Test_StringIsAllAlphanumericOrDash');

   // Empty string must return false
   CheckFalse(StringIsAllAlphanumericOrDash(''), 'empty string');

   // --- bNoCase = false (default) ---

   // Uppercase and digits pass
   CheckTrue(StringIsAllAlphanumericOrDash('K4A'), 'uppercase letters');
   CheckTrue(StringIsAllAlphanumericOrDash('123'), 'digits');
   CheckTrue(StringIsAllAlphanumericOrDash('K4A-1234'), 'uppercase with dash');
   CheckTrue(StringIsAllAlphanumericOrDash('-'), 'dash alone');

   // tCharIsAlphaNumericOrDash only accepts A-Z (uppercase); lowercase is rejected
   CheckFalse(StringIsAllAlphanumericOrDash('k4a'), 'lowercase rejected without bNoCase');
   CheckFalse(StringIsAllAlphanumericOrDash('k4a-1234'), 'lowercase with dash rejected');

   // Special characters always reject
   CheckFalse(StringIsAllAlphanumericOrDash('K4A!'), 'exclamation mark');
   CheckFalse(StringIsAllAlphanumericOrDash('K 4A'), 'embedded space');
   CheckFalse(StringIsAllAlphanumericOrDash('K4A.1'), 'dot');

   // --- bNoCase = true ---

   // Lowercase now passes because input is uppercased before checking
   CheckTrue(StringIsAllAlphanumericOrDash('k4a', True), 'lowercase passes with bNoCase');
   CheckTrue(StringIsAllAlphanumericOrDash('k4a-1234', True), 'lowercase with dash, bNoCase');
   CheckTrue(StringIsAllAlphanumericOrDash('K4A', True), 'uppercase still passes with bNoCase');

   // Special characters still reject even with bNoCase
   CheckFalse(StringIsAllAlphanumericOrDash('k4a!', True), 'special char rejected with bNoCase');
   CheckFalse(StringIsAllAlphanumericOrDash('', True), 'empty string with bNoCase');
end;

// ---------------------------------------------------------------------------
// StringWithFirstWordDeleted
// ---------------------------------------------------------------------------

procedure TUtilsTextTests.Test_StringWithFirstWordDeleted;
begin
   BeginTest('Test_StringWithFirstWordDeleted');

   // Empty string returns empty
   CheckEquals('', StringWithFirstWordDeleted(''), 'empty string');

   // No space — the whole string is one word, returns empty
   CheckEquals('', StringWithFirstWordDeleted('HELLO'), 'single word');

   // Normal two-word case
   CheckEquals('WORLD', StringWithFirstWordDeleted('HELLO WORLD'), 'two words');

   // Three words — only the first word is deleted
   CheckEquals('TWO THREE', StringWithFirstWordDeleted('ONE TWO THREE'), 'three words');

   // Multiple spaces between words — collapses to the next non-space token
   CheckEquals('WORLD', StringWithFirstWordDeleted('HELLO   WORLD'), 'multiple spaces between words');

   // Leading space — the first "word" is empty (chars before the first space),
   // so everything after the first space is returned
   CheckEquals('HELLO WORLD', StringWithFirstWordDeleted(' HELLO WORLD'), 'leading space');

   // String is only spaces — no non-space token follows any space, so
   // the loop empties the string and returns empty
   CheckEquals('', StringWithFirstWordDeleted('   '), 'only spaces');
end;

// ---------------------------------------------------------------------------
// Suite entry point
// ---------------------------------------------------------------------------

procedure TUtilsTextTests.RunAllTests;
begin
   Test_StringIsAllNumbers;
   Test_StringIsAllNumbersOrSpaces;
   Test_StringIsAllNumbersOrDecimal;
   Test_StringIsAllAlphanumericOrDash;
   Test_StringWithFirstWordDeleted;
end;

end.
