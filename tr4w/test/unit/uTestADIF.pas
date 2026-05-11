unit uTestADIF;

{
  Tests for uADIF.pas — the ADIF field-list lexer.

  These tests verify the string-slicing core of ADIF parsing.  Per
  docs/tr4w-migration-strategy.md, ADIF string handling is high-risk
  surface for Phase 2 (Unicode correctness), so this regression net
  is part of the Tier 1 build-before-the-freeze work.

  Issue #887 — first incremental commit.  Subsequent commits will add
  tests for field-name -> ContestExchange mapping and the multi-record
  ImportADIFFromString entry point.
}

interface

uses
   uTR4WTestFramework;

type
   TADIFLexerTests = class(TTestCase)
   public
      procedure RunAllTests; override;

   private
      procedure Test_EmptyString;
      procedure Test_SingleField_EORTerminated;
      procedure Test_MultipleFields;
      procedure Test_BareEOR;
      procedure Test_EOHTreatedSameAsEOR;
      procedure Test_NoTerminator_ReturnsFalseButKeepsFields;
      procedure Test_EmptyValue;
      procedure Test_MultilineRecord;
      procedure Test_EmbeddedSpacesInValue;
      procedure Test_LowercaseEORAccepted;
      procedure Test_MixedCaseEORAccepted;
      procedure Test_FreeFormTextBetweenFields;
      procedure Test_NonNumericLength_FieldSkipped;
      procedure Test_TruncatedValue_PartialFieldReturned;
      procedure Test_TypedField_TypeStripped;
      procedure Test_UnclosedTag_ReturnsFalse;
      procedure Test_RealishADIFRecord;
   end;

implementation

uses
   SysUtils,
   uADIF;

// ---------------------------------------------------------------------------
// Basic shapes
// ---------------------------------------------------------------------------

procedure TADIFLexerTests.Test_EmptyString;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_EmptyString');
   CheckFalse(ParseADIFFieldsList('', fields),
              'empty string has no terminator -> False');
   CheckEquals(0, Length(fields), 'no fields parsed');
end;

procedure TADIFLexerTests.Test_SingleField_EORTerminated;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_SingleField_EORTerminated');
   CheckTrue(ParseADIFFieldsList('<CALL:4>KG1S<EOR>', fields),
             'EOR terminator -> True');
   CheckEquals(1, Length(fields), 'one field parsed');
   CheckEquals('CALL', fields[0].Name, 'field name');
   CheckEquals('KG1S', fields[0].Value, 'field value');
end;

procedure TADIFLexerTests.Test_MultipleFields;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_MultipleFields');
   CheckTrue(ParseADIFFieldsList(
      '<CALL:4>KG1S <BAND:3>20m <MODE:2>CW <EOR>', fields),
      'three fields + EOR -> True');
   CheckEquals(3, Length(fields), 'three fields parsed');
   CheckEquals('CALL', fields[0].Name, '[0].Name');
   CheckEquals('KG1S', fields[0].Value, '[0].Value');
   CheckEquals('BAND', fields[1].Name, '[1].Name');
   CheckEquals('20m', fields[1].Value, '[1].Value');
   CheckEquals('MODE', fields[2].Name, '[2].Name');
   CheckEquals('CW', fields[2].Value, '[2].Value');
end;

procedure TADIFLexerTests.Test_BareEOR;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_BareEOR');
   CheckTrue(ParseADIFFieldsList('<EOR>', fields),
             'bare EOR returns True');
   CheckEquals(0, Length(fields), 'no fields');
end;

procedure TADIFLexerTests.Test_EOHTreatedSameAsEOR;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_EOHTreatedSameAsEOR');
   CheckTrue(ParseADIFFieldsList('<PROGRAMID:4>TR4W<EOH>', fields),
             'EOH is also a valid terminator');
   CheckEquals(1, Length(fields), 'one header field');
   CheckEquals('PROGRAMID', fields[0].Name, 'name');
   CheckEquals('TR4W', fields[0].Value, 'value');
end;

procedure TADIFLexerTests.Test_NoTerminator_ReturnsFalseButKeepsFields;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_NoTerminator_ReturnsFalseButKeepsFields');
   CheckFalse(ParseADIFFieldsList('<CALL:4>KG1S <BAND:3>20m', fields),
              'no terminator -> False');
   CheckEquals(2, Length(fields), 'fields still extracted');
   CheckEquals('KG1S', fields[0].Value, '[0]');
   CheckEquals('20m', fields[1].Value, '[1]');
end;

// ---------------------------------------------------------------------------
// Value-shape edge cases
// ---------------------------------------------------------------------------

procedure TADIFLexerTests.Test_EmptyValue;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_EmptyValue');
   CheckTrue(ParseADIFFieldsList('<COMMENT:0><EOR>', fields),
             'empty value, EOR terminator');
   CheckEquals(1, Length(fields), 'one field');
   CheckEquals('COMMENT', fields[0].Name, 'name');
   CheckEquals('', fields[0].Value, 'empty value');
end;

procedure TADIFLexerTests.Test_MultilineRecord;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_MultilineRecord');
   CheckTrue(ParseADIFFieldsList(
      '<CALL:4>KG1S'#13#10'<BAND:3>20m'#13#10'<EOR>', fields),
      'record split across lines');
   CheckEquals(2, Length(fields), 'two fields');
   CheckEquals('KG1S', fields[0].Value, 'first value across newline');
   CheckEquals('20m', fields[1].Value, 'second value');
end;

procedure TADIFLexerTests.Test_EmbeddedSpacesInValue;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_EmbeddedSpacesInValue');
   CheckTrue(ParseADIFFieldsList('<NAME:8>John Doe<EOR>', fields),
             'value contains a space');
   CheckEquals(1, Length(fields), 'one field');
   CheckEquals('John Doe', fields[0].Value, 'space preserved by length-honored read');
end;

// ---------------------------------------------------------------------------
// Terminator case sensitivity
// ---------------------------------------------------------------------------

procedure TADIFLexerTests.Test_LowercaseEORAccepted;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_LowercaseEORAccepted');
   CheckTrue(ParseADIFFieldsList('<eor>', fields),
             'lowercase eor accepted');
end;

procedure TADIFLexerTests.Test_MixedCaseEORAccepted;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_MixedCaseEORAccepted');
   CheckTrue(ParseADIFFieldsList('<EoR>', fields),
             'mixed case EoR accepted');
end;

// ---------------------------------------------------------------------------
// Free-form / malformed
// ---------------------------------------------------------------------------

procedure TADIFLexerTests.Test_FreeFormTextBetweenFields;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_FreeFormTextBetweenFields');
   // ADIF allows arbitrary text between tags (typical in headers/comments).
   CheckTrue(ParseADIFFieldsList(
      'Created by TR4W'#13#10'<CALL:4>KG1S<EOR>', fields),
      'leading free-form text ignored');
   CheckEquals(1, Length(fields), 'still parses the field after free text');
   CheckEquals('KG1S', fields[0].Value, 'value extracted');
end;

procedure TADIFLexerTests.Test_NonNumericLength_FieldSkipped;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_NonNumericLength_FieldSkipped');
   // A non-numeric length is malformed; lexer skips the tag and continues.
   CheckTrue(ParseADIFFieldsList(
      '<CALL:abc>?? <BAND:3>20m<EOR>', fields),
      'bad-length tag skipped, parsing continues to EOR');
   // The malformed tag is dropped; the second field is parsed.
   CheckEquals(1, Length(fields), 'only the well-formed field survives');
   CheckEquals('BAND', fields[0].Name, 'second field name');
   CheckEquals('20m', fields[0].Value, 'second field value');
end;

procedure TADIFLexerTests.Test_TruncatedValue_PartialFieldReturned;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_TruncatedValue_PartialFieldReturned');
   // CALL declared length 10 but only 4 chars follow.  Lexer returns the
   // partial value and stops (no terminator => False).
   CheckFalse(ParseADIFFieldsList('<CALL:10>KG1S', fields),
              'truncated value -> False');
   CheckEquals(1, Length(fields), 'one (partial) field');
   CheckEquals('KG1S', fields[0].Value, 'whatever bytes were left');
end;

procedure TADIFLexerTests.Test_TypedField_TypeStripped;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_TypedField_TypeStripped');
   // ADIF allows <NAME:LEN:TYPE>VALUE where TYPE is a single-character
   // data-type indicator.  Lexer must accept the suffix and ignore it.
   CheckTrue(ParseADIFFieldsList('<CALL:4:S>KG1S<EOR>', fields),
             ':TYPE suffix ignored');
   CheckEquals(1, Length(fields), 'one field');
   CheckEquals('KG1S', fields[0].Value, 'value extracted');
end;

procedure TADIFLexerTests.Test_UnclosedTag_ReturnsFalse;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_UnclosedTag_ReturnsFalse');
   // '<' with no matching '>' at all in the rest of the string.
   CheckFalse(ParseADIFFieldsList('<CALL:4 unclosed', fields),
              'unclosed tag header -> False');
   CheckEquals(0, Length(fields), 'no fields parsed');
end;

// ---------------------------------------------------------------------------
// End-to-end shape: a real-ish ADIF record body
// ---------------------------------------------------------------------------

procedure TADIFLexerTests.Test_RealishADIFRecord;
var
   fields : TADIFFieldList;
begin
   BeginTest('Test_RealishADIFRecord');
   CheckTrue(ParseADIFFieldsList(
      '<CALL:4>KG1S <BAND:3>20m <QSO_DATE:8>20260510 ' +
      '<TIME_ON:6>154644 <RST_SENT:2>59 <RST_RCVD:2>59 ' +
      '<MODE:3>SSB <SUBMODE:3>USB <FREQ:5>14.32' +
      '<SRX_STRING:3>MON <STX_STRING:6>59 PIN <STATE:3>MON ' +
      '<QTH:3>MON <STX:5>00033 <OPERATOR:4>NY4I <EOR>', fields),
      'realistic record parses to EOR');
   CheckEquals(15, Length(fields), 'fifteen fields in this record');
   CheckEquals('CALL',       fields[0].Name,  '[0] name');
   CheckEquals('KG1S',       fields[0].Value, '[0] value');
   CheckEquals('OPERATOR',   fields[14].Name, '[14] name');
   CheckEquals('NY4I',       fields[14].Value,'[14] value');
end;

// ---------------------------------------------------------------------------
// Test suite dispatch
// ---------------------------------------------------------------------------

procedure TADIFLexerTests.RunAllTests;
begin
   Test_EmptyString;
   Test_SingleField_EORTerminated;
   Test_MultipleFields;
   Test_BareEOR;
   Test_EOHTreatedSameAsEOR;
   Test_NoTerminator_ReturnsFalseButKeepsFields;

   Test_EmptyValue;
   Test_MultilineRecord;
   Test_EmbeddedSpacesInValue;

   Test_LowercaseEORAccepted;
   Test_MixedCaseEORAccepted;

   Test_FreeFormTextBetweenFields;
   Test_NonNumericLength_FieldSkipped;
   Test_TruncatedValue_PartialFieldReturned;
   Test_TypedField_TypeStripped;
   Test_UnclosedTag_ReturnsFalse;

   Test_RealishADIFRecord;
end;

end.
