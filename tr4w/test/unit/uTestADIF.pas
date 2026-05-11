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

   TADIFHelperTests = class(TTestCase)
   public
      procedure RunAllTests; override;

   private
      procedure Test_GetADIFBand_KnownBands;
      procedure Test_GetADIFBand_UnknownBand;
      procedure Test_GetADIFBand_CaseInsensitive;
      procedure Test_GetADIFMode_KnownModes;
      procedure Test_GetADIFMode_UnknownMode;
      procedure Test_GetADIFSubMode_KnownSubModes;
      procedure Test_GetADIFSubMode_UnknownSubMode;
      procedure Test_ADIFDateStringToQSOTime_Valid;
      procedure Test_ADIFDateStringToQSOTime_InvalidLength;
      procedure Test_ADIFDateStringToQSOTime_NonNumeric;
      procedure Test_ADIFTimeStringToQSOTime_HHMM;
      procedure Test_ADIFTimeStringToQSOTime_HHMMSS;
      procedure Test_ADIFTimeStringToQSOTime_InvalidLength;
      procedure Test_IsValidGUID_Hyphenated;
      procedure Test_IsValidGUID_Unhyphenated;
      procedure Test_IsValidGUID_Braced;
      procedure Test_IsValidGUID_RejectsShort;
      procedure Test_IsValidGUID_RejectsNonHex;
      procedure Test_IsValidGUID_RejectsEmpty;
      procedure Test_IsValidGUID_RejectsMisplacedHyphens;
   end;

implementation

uses
   SysUtils,
   VC,
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

// =========================================================================
// Per-field type-conversion helper tests
// =========================================================================

// ---------------------------------------------------------------------------
// GetADIFBand
// ---------------------------------------------------------------------------

procedure TADIFHelperTests.Test_GetADIFBand_KnownBands;
begin
   BeginTest('Test_GetADIFBand_KnownBands');
   CheckEquals(Integer(Band20),  Integer(GetADIFBand('20m')),  '20m');
   CheckEquals(Integer(Band40),  Integer(GetADIFBand('40m')),  '40m');
   CheckEquals(Integer(Band80),  Integer(GetADIFBand('80m')),  '80m');
   CheckEquals(Integer(Band160), Integer(GetADIFBand('160m')), '160m');
   CheckEquals(Integer(Band10),  Integer(GetADIFBand('10m')),  '10m');
   CheckEquals(Integer(Band15),  Integer(GetADIFBand('15m')),  '15m');
   CheckEquals(Integer(Band6),   Integer(GetADIFBand('6m')),   '6m');
end;

procedure TADIFHelperTests.Test_GetADIFBand_UnknownBand;
begin
   BeginTest('Test_GetADIFBand_UnknownBand');
   CheckEquals(Integer(NoBand), Integer(GetADIFBand('garbage')),
               'unknown band -> NoBand');
   CheckEquals(Integer(NoBand), Integer(GetADIFBand('')),
               'empty -> NoBand');
end;

procedure TADIFHelperTests.Test_GetADIFBand_CaseInsensitive;
begin
   BeginTest('Test_GetADIFBand_CaseInsensitive');
   CheckEquals(Integer(Band20), Integer(GetADIFBand('20M')),  'uppercase 20M');
   CheckEquals(Integer(Band20), Integer(GetADIFBand('20m')),  'lowercase 20m');
end;

// ---------------------------------------------------------------------------
// GetADIFMode
// ---------------------------------------------------------------------------

procedure TADIFHelperTests.Test_GetADIFMode_KnownModes;
var
   m : ModeAndExtendedModeType;
begin
   BeginTest('Test_GetADIFMode_KnownModes');

   m := GetADIFMode('CW');
   CheckEquals(Integer(CW),  Integer(m.msmMode),         'CW.Mode');
   CheckEquals(Integer(eCW), Integer(m.msmExtendedMode), 'CW.ExtMode');

   m := GetADIFMode('SSB');
   CheckEquals(Integer(Phone), Integer(m.msmMode),         'SSB.Mode');
   CheckEquals(Integer(eSSB),  Integer(m.msmExtendedMode), 'SSB.ExtMode');

   m := GetADIFMode('FT8');
   CheckEquals(Integer(Digital), Integer(m.msmMode),         'FT8.Mode');
   CheckEquals(Integer(eFT8),    Integer(m.msmExtendedMode), 'FT8.ExtMode');

   m := GetADIFMode('RTTY');
   CheckEquals(Integer(Digital), Integer(m.msmMode),         'RTTY.Mode');
   CheckEquals(Integer(eRTTY),   Integer(m.msmExtendedMode), 'RTTY.ExtMode');

   // Case-insensitive
   m := GetADIFMode('cw');
   CheckEquals(Integer(CW), Integer(m.msmMode), 'lowercase cw');
end;

procedure TADIFHelperTests.Test_GetADIFMode_UnknownMode;
var
   m : ModeAndExtendedModeType;
begin
   BeginTest('Test_GetADIFMode_UnknownMode');
   m := GetADIFMode('garbage');
   CheckEquals(Integer(NoMode), Integer(m.msmMode), 'unknown -> NoMode');
end;

// ---------------------------------------------------------------------------
// GetADIFSubMode
// ---------------------------------------------------------------------------

procedure TADIFHelperTests.Test_GetADIFSubMode_KnownSubModes;
var
   m : ModeAndExtendedModeType;
begin
   BeginTest('Test_GetADIFSubMode_KnownSubModes');

   m := GetADIFSubMode('USB');
   CheckEquals(Integer(Phone), Integer(m.msmMode),         'USB.Mode');
   CheckEquals(Integer(eUSB),  Integer(m.msmExtendedMode), 'USB.ExtMode');

   m := GetADIFSubMode('LSB');
   CheckEquals(Integer(Phone), Integer(m.msmMode),         'LSB.Mode');
   CheckEquals(Integer(eLSB),  Integer(m.msmExtendedMode), 'LSB.ExtMode');

   m := GetADIFSubMode('FT4');
   CheckEquals(Integer(Digital), Integer(m.msmMode),         'FT4.Mode');
   CheckEquals(Integer(eFT4),    Integer(m.msmExtendedMode), 'FT4.ExtMode');
end;

procedure TADIFHelperTests.Test_GetADIFSubMode_UnknownSubMode;
var
   m : ModeAndExtendedModeType;
begin
   BeginTest('Test_GetADIFSubMode_UnknownSubMode');
   m := GetADIFSubMode('garbage');
   CheckEquals(Integer(NoMode), Integer(m.msmMode), 'unknown -> NoMode');
end;

// ---------------------------------------------------------------------------
// ADIFDateStringToQSOTime
// ---------------------------------------------------------------------------

procedure TADIFHelperTests.Test_ADIFDateStringToQSOTime_Valid;
var
   t : TQSOTime;
begin
   BeginTest('Test_ADIFDateStringToQSOTime_Valid');
   FillChar(t, SizeOf(t), 0);
   CheckTrue(ADIFDateStringToQSOTime('20260510', t),
             'YYYYMMDD parses OK');
   // Year is stored as YY (2-digit), so 2026 -> 26.
   CheckEquals(26, Integer(t.qtYear),  'qtYear (2-digit)');
   CheckEquals(5,  Integer(t.qtMonth), 'qtMonth');
   CheckEquals(10, Integer(t.qtDay),   'qtDay');
end;

procedure TADIFHelperTests.Test_ADIFDateStringToQSOTime_InvalidLength;
var
   t : TQSOTime;
begin
   BeginTest('Test_ADIFDateStringToQSOTime_InvalidLength');
   FillChar(t, SizeOf(t), 0);
   CheckFalse(ADIFDateStringToQSOTime('2026', t), 'too short');
   CheckFalse(ADIFDateStringToQSOTime('202605101', t), 'too long');
   CheckFalse(ADIFDateStringToQSOTime('', t), 'empty');
end;

procedure TADIFHelperTests.Test_ADIFDateStringToQSOTime_NonNumeric;
var
   t : TQSOTime;
begin
   BeginTest('Test_ADIFDateStringToQSOTime_NonNumeric');
   FillChar(t, SizeOf(t), 0);
   CheckFalse(ADIFDateStringToQSOTime('2026XX10', t),
              'non-numeric chars rejected');
end;

// ---------------------------------------------------------------------------
// ADIFTimeStringToQSOTime
// ---------------------------------------------------------------------------

procedure TADIFHelperTests.Test_ADIFTimeStringToQSOTime_HHMM;
var
   t : TQSOTime;
begin
   BeginTest('Test_ADIFTimeStringToQSOTime_HHMM');
   FillChar(t, SizeOf(t), 0);
   CheckTrue(ADIFTimeStringToQSOTime('1547', t), '4-digit HHMM parses');
   CheckEquals(15, Integer(t.qtHour),   'qtHour');
   CheckEquals(47, Integer(t.qtMinute), 'qtMinute');
   CheckEquals(0,  Integer(t.qtSecond), 'qtSecond defaults to 0');
end;

procedure TADIFHelperTests.Test_ADIFTimeStringToQSOTime_HHMMSS;
var
   t : TQSOTime;
begin
   BeginTest('Test_ADIFTimeStringToQSOTime_HHMMSS');
   FillChar(t, SizeOf(t), 0);
   CheckTrue(ADIFTimeStringToQSOTime('154729', t),
             '6-digit HHMMSS parses');
   CheckEquals(15, Integer(t.qtHour),   'qtHour');
   CheckEquals(47, Integer(t.qtMinute), 'qtMinute');
   CheckEquals(29, Integer(t.qtSecond), 'qtSecond');
end;

procedure TADIFHelperTests.Test_ADIFTimeStringToQSOTime_InvalidLength;
var
   t : TQSOTime;
begin
   BeginTest('Test_ADIFTimeStringToQSOTime_InvalidLength');
   FillChar(t, SizeOf(t), 0);
   CheckFalse(ADIFTimeStringToQSOTime('154',     t), '3 digits');
   CheckFalse(ADIFTimeStringToQSOTime('15473',   t), '5 digits');
   CheckFalse(ADIFTimeStringToQSOTime('1547290', t), '7 digits');
   CheckFalse(ADIFTimeStringToQSOTime('',        t), 'empty');
end;

// ---------------------------------------------------------------------------
// IsValidGUID
// ---------------------------------------------------------------------------

procedure TADIFHelperTests.Test_IsValidGUID_Hyphenated;
begin
   BeginTest('Test_IsValidGUID_Hyphenated');
   CheckTrue(IsValidGUID('3deea564-2f91-4449-ae14-2525b2a1518d'),
             'lowercase hyphenated');
   CheckTrue(IsValidGUID('3DEEA564-2F91-4449-AE14-2525B2A1518D'),
             'uppercase hyphenated');
   CheckTrue(IsValidGUID('3DeEa564-2F91-4449-Ae14-2525b2a1518D'),
             'mixed case hyphenated');
end;

procedure TADIFHelperTests.Test_IsValidGUID_Unhyphenated;
begin
   BeginTest('Test_IsValidGUID_Unhyphenated');
   CheckTrue(IsValidGUID('3deea56f2c1840c589cd117d3374905e'),
             'lowercase 32-hex');
   CheckTrue(IsValidGUID('3DEEA56F2C1840C589CD117D3374905E'),
             'uppercase 32-hex');
end;

procedure TADIFHelperTests.Test_IsValidGUID_Braced;
begin
   BeginTest('Test_IsValidGUID_Braced');
   CheckTrue(IsValidGUID('{3deea564-2f91-4449-ae14-2525b2a1518d}'),
             'hyphenated with braces');
   CheckTrue(IsValidGUID('{3deea56f2c1840c589cd117d3374905e}'),
             'unhyphenated with braces');
end;

procedure TADIFHelperTests.Test_IsValidGUID_RejectsShort;
begin
   BeginTest('Test_IsValidGUID_RejectsShort');
   CheckFalse(IsValidGUID('3deea56f'),              '8 hex chars');
   CheckFalse(IsValidGUID('3deea56f2c1840c589cd117d3374'),
                                                    '28 hex chars');
end;

procedure TADIFHelperTests.Test_IsValidGUID_RejectsNonHex;
begin
   BeginTest('Test_IsValidGUID_RejectsNonHex');
   CheckFalse(IsValidGUID('3deea56f2c1840c589cd117d337490ZZ'),
              'Z is not hex');
   CheckFalse(IsValidGUID('3deea564-2f91-4449-ae14-2525b2a1518G'),
              'G in hyphenated form');
end;

procedure TADIFHelperTests.Test_IsValidGUID_RejectsEmpty;
begin
   BeginTest('Test_IsValidGUID_RejectsEmpty');
   CheckFalse(IsValidGUID(''), 'empty string');
end;

procedure TADIFHelperTests.Test_IsValidGUID_RejectsMisplacedHyphens;
begin
   BeginTest('Test_IsValidGUID_RejectsMisplacedHyphens');
   // Total of 36 chars but hyphens in wrong positions
   CheckFalse(IsValidGUID('3deea5642f-91-4449-ae14-2525b2a1518d'),
              'hyphen at wrong position');
end;

procedure TADIFHelperTests.RunAllTests;
begin
   Test_GetADIFBand_KnownBands;
   Test_GetADIFBand_UnknownBand;
   Test_GetADIFBand_CaseInsensitive;

   Test_GetADIFMode_KnownModes;
   Test_GetADIFMode_UnknownMode;

   Test_GetADIFSubMode_KnownSubModes;
   Test_GetADIFSubMode_UnknownSubMode;

   Test_ADIFDateStringToQSOTime_Valid;
   Test_ADIFDateStringToQSOTime_InvalidLength;
   Test_ADIFDateStringToQSOTime_NonNumeric;

   Test_ADIFTimeStringToQSOTime_HHMM;
   Test_ADIFTimeStringToQSOTime_HHMMSS;
   Test_ADIFTimeStringToQSOTime_InvalidLength;

   Test_IsValidGUID_Hyphenated;
   Test_IsValidGUID_Unhyphenated;
   Test_IsValidGUID_Braced;
   Test_IsValidGUID_RejectsShort;
   Test_IsValidGUID_RejectsNonHex;
   Test_IsValidGUID_RejectsEmpty;
   Test_IsValidGUID_RejectsMisplacedHyphens;
end;

end.
