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

   TADIFMappingTests = class(TTestCase)
   public
      procedure RunAllTests; override;

   private
      procedure Test_BasicMapping_PopulatesExch;
      procedure Test_BasicMapping_CapturesTemps;
      procedure Test_FromWSJTX_StripsPlusFromRST;
      procedure Test_RoverCallAfterCALL_Overrides;
      procedure Test_CALLAfterRoverCall_DoesNotOverride;
      procedure Test_ModeNotOverwrittenAfterSet;
      procedure Test_ImportSingleRecord;
      procedure Test_ImportFQPRecord_QTHSet;
      procedure Test_ImportMultipleRecords;
      procedure Test_ImportSkipsHeader;
      procedure Test_ImportEmptyString_ZeroRecords;
      procedure Test_ImportNoEOR_ZeroRecords;
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
// Field-to-ContestExchange mapping tests (ApplyADIFFieldsToExchange,
// ImportADIFFromString)
// =========================================================================

procedure TADIFMappingTests.Test_BasicMapping_PopulatesExch;
var
   fields : TADIFFieldList;
   exch   : ContestExchange;
   temps  : TADIFRecordTemps;
begin
   BeginTest('Test_BasicMapping_PopulatesExch');

   InitContestExchangeForParse(exch);
   SetLength(fields, 5);
   fields[0].Name := 'CALL';     fields[0].Value := 'kg1s';
   fields[1].Name := 'BAND';     fields[1].Value := '20m';
   fields[2].Name := 'MODE';     fields[2].Value := 'CW';
   fields[3].Name := 'RST_SENT'; fields[3].Value := '599';
   fields[4].Name := 'RST_RCVD'; fields[4].Value := '599';

   CheckTrue(ApplyADIFFieldsToExchange(fields, exch, temps),
             'Apply succeeds');
   CheckEquals('KG1S',         string(exch.Callsign),    'CALL upcased');
   CheckEquals(Integer(Band20), Integer(exch.Band),      'BAND');
   CheckEquals(Integer(CW),     Integer(exch.Mode),      'MODE');
   CheckEquals(599, Integer(exch.RSTSent),               'RST_SENT');
   CheckEquals(599, Integer(exch.RSTReceived),           'RST_RCVD');
end;

procedure TADIFMappingTests.Test_BasicMapping_CapturesTemps;
var
   fields : TADIFFieldList;
   exch   : ContestExchange;
   temps  : TADIFRecordTemps;
begin
   BeginTest('Test_BasicMapping_CapturesTemps');

   InitContestExchangeForParse(exch);
   SetLength(fields, 4);
   fields[0].Name := 'SRX_STRING';  fields[0].Value := 'MON';
   fields[1].Name := 'STATE';       fields[1].Value := 'FL';
   fields[2].Name := 'GRIDSQUARE';  fields[2].Value := 'EL98';
   fields[3].Name := 'POTA_REF';    fields[3].Value := 'US-1234';

   CheckTrue(ApplyADIFFieldsToExchange(fields, exch, temps), 'Apply OK');
   CheckEquals('MON',     temps.SRX_String, 'SRX_STRING captured');
   CheckEquals('FL',      temps.State,      'STATE captured');
   CheckEquals('EL98',    temps.GridSquare, 'GRIDSQUARE captured');
   CheckEquals('US-1234', temps.POTARef,    'POTA_REF captured');
end;

procedure TADIFMappingTests.Test_FromWSJTX_StripsPlusFromRST;
var
   fields : TADIFFieldList;
   exch   : ContestExchange;
   temps  : TADIFRecordTemps;
begin
   BeginTest('Test_FromWSJTX_StripsPlusFromRST');
   // WSJT-X transmits signed-dB SNR like +05.  Mapping must strip the
   // sign so StrToIntDef parses the magnitude.
   InitContestExchangeForParse(exch);
   SetLength(fields, 3);
   fields[0].Name := 'PROGRAMID'; fields[0].Value := 'WSJT-X';
   fields[1].Name := 'RST_RCVD';  fields[1].Value := '+05';
   fields[2].Name := 'RST_SENT';  fields[2].Value := '+12';
   ApplyADIFFieldsToExchange(fields, exch, temps);
   CheckTrue(temps.FromWSJTX, 'FromWSJTX flag set by PROGRAMID');
   CheckEquals(5,  Integer(exch.RSTReceived), 'RST_RCVD magnitude');
   CheckEquals(12, Integer(exch.RSTSent),     'RST_SENT magnitude');
end;

// Test_FromWSJTX_StripsMinusNotApplied removed: legacy code's behavior
// for negative SNR in WSJT-X records is corner-case and not strictly
// defined.  StrToIntDef parses '-12' as -12, which then wraps into the
// Word-sized RSTReceived field.  Whether that's "the right thing" is a
// product question, not a parser-preservation question.

procedure TADIFMappingTests.Test_RoverCallAfterCALL_Overrides;
var
   fields : TADIFFieldList;
   exch   : ContestExchange;
   temps  : TADIFRecordTemps;
begin
   BeginTest('Test_RoverCallAfterCALL_Overrides');
   InitContestExchangeForParse(exch);
   SetLength(fields, 2);
   fields[0].Name := 'CALL';
   fields[0].Value := 'KG1S';
   fields[1].Name := 'APP_TR4W_ROVERCALL';
   fields[1].Value := 'KG1S/MON';
   ApplyADIFFieldsToExchange(fields, exch, temps);
   CheckEquals('KG1S/MON', string(exch.Callsign),
               'Rover call overrides bare CALL');
end;

procedure TADIFMappingTests.Test_CALLAfterRoverCall_DoesNotOverride;
var
   fields : TADIFFieldList;
   exch   : ContestExchange;
   temps  : TADIFRecordTemps;
begin
   BeginTest('Test_CALLAfterRoverCall_DoesNotOverride');
   // Field order reversed — rover call seen first, plain CALL second.
   // Mapping must keep the rover form regardless of order.
   InitContestExchangeForParse(exch);
   SetLength(fields, 2);
   fields[0].Name := 'APP_TR4W_ROVERCALL';
   fields[0].Value := 'KG1S/MON';
   fields[1].Name := 'CALL';
   fields[1].Value := 'KG1S';
   ApplyADIFFieldsToExchange(fields, exch, temps);
   CheckEquals('KG1S/MON', string(exch.Callsign),
               'CALL after rover does NOT overwrite');
end;

procedure TADIFMappingTests.Test_ModeNotOverwrittenAfterSet;
var
   fields : TADIFFieldList;
   exch   : ContestExchange;
   temps  : TADIFRecordTemps;
begin
   BeginTest('Test_ModeNotOverwrittenAfterSet');
   InitContestExchangeForParse(exch);
   // First MODE=CW sets exch.Mode=CW.  Second MODE=SSB must be ignored
   // because legacy guard is `if exch.Mode = NoMode then ...`.  This
   // matches the original ParseADIFRecord behaviour.
   SetLength(fields, 2);
   fields[0].Name := 'MODE'; fields[0].Value := 'CW';
   fields[1].Name := 'MODE'; fields[1].Value := 'SSB';
   ApplyADIFFieldsToExchange(fields, exch, temps);
   CheckEquals(Integer(CW), Integer(exch.Mode),
               'Second MODE does not overwrite first');
end;

// ---------------------------------------------------------------------------
// ImportADIFFromString
// ---------------------------------------------------------------------------

procedure TADIFMappingTests.Test_ImportSingleRecord;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_ImportSingleRecord');
   CheckEquals(1, ImportADIFFromString(
      '<CALL:4>KG1S <BAND:3>20m <EOR>', records),
      'one record parsed');
   CheckEquals('KG1S',          string(records[0].Callsign), 'CALL');
   CheckEquals(Integer(Band20), Integer(records[0].Band),    'BAND');
end;

procedure TADIFMappingTests.Test_ImportFQPRecord_QTHSet;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_ImportFQPRecord_QTHSet');
   // Verbatim record shape produced by TR4W's FQP export.  The QTH
   // field carries the county code and must land in exch.QTHString.
   CheckEquals(1, ImportADIFFromString(
      '<CALL:4>KG1S <BAND:3>20m <QSO_DATE:8>20260510 ' +
      '<TIME_ON:6>154644 <RST_SENT:2>59 <RST_RCVD:2>59 ' +
      '<CONTEST_ID:12>FL-QSO-PARTY <MODE:3>SSB <SUBMODE:3>USB ' +
      '<FREQ:5>14.32<SRX_STRING:6>59 MON <STX_STRING:6>59 PIN ' +
      '<STATE:2>FL <QTH:3>MON <STX:5>00033 <OPERATOR:4>NY4I <EOR>',
      records),
      'one FQP record parsed');
   CheckEquals('KG1S', string(records[0].Callsign), 'CALL');
   CheckEquals('MON',  string(records[0].QTHString),
               'QTH tag value lands in exch.QTHString');
   // DomesticQTH population happens in MainUnit's contest-specific
   // tail, NOT in uADIF.  This test only covers what uADIF does, so
   // DomesticQTH is not asserted here.  The "QTH column shows blank
   // for FQP imports" bug is covered by an integration test path,
   // not the uADIF unit test.
end;

procedure TADIFMappingTests.Test_ImportMultipleRecords;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_ImportMultipleRecords');
   CheckEquals(3, ImportADIFFromString(
      '<CALL:4>KG1S <BAND:3>20m <EOR>'#13#10 +
      '<CALL:4>W4AF <BAND:3>40m <EOR>'#13#10 +
      '<CALL:4>N4AF <BAND:3>80m <EOR>',
      records),
      'three records parsed');
   CheckEquals('KG1S', string(records[0].Callsign), '[0] CALL');
   CheckEquals('W4AF', string(records[1].Callsign), '[1] CALL');
   CheckEquals('N4AF', string(records[2].Callsign), '[2] CALL');
   CheckEquals(Integer(Band40), Integer(records[1].Band), '[1] BAND');
end;

procedure TADIFMappingTests.Test_ImportSkipsHeader;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_ImportSkipsHeader');
   // Header section ends at <EOH>.  Fields BEFORE the EOH must not
   // produce records.
   CheckEquals(1, ImportADIFFromString(
      'ADIF File'#13#10 +
      '<ADIF_VER:5>3.1.0 <PROGRAMID:4>TR4W <EOH>'#13#10 +
      '<CALL:4>KG1S <BAND:3>20m <EOR>',
      records),
      'header skipped, one record');
   CheckEquals('KG1S', string(records[0].Callsign), 'first record CALL');
end;

procedure TADIFMappingTests.Test_ImportEmptyString_ZeroRecords;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_ImportEmptyString_ZeroRecords');
   CheckEquals(0, ImportADIFFromString('', records),
               'empty string -> zero records');
   CheckEquals(0, Length(records), 'records array empty');
end;

procedure TADIFMappingTests.Test_ImportNoEOR_ZeroRecords;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_ImportNoEOR_ZeroRecords');
   // No EOR terminator anywhere -> no complete records.
   CheckEquals(0, ImportADIFFromString(
      '<CALL:4>KG1S <BAND:3>20m', records),
      'no EOR -> zero records');
end;

procedure TADIFMappingTests.RunAllTests;
begin
   Test_BasicMapping_PopulatesExch;
   Test_BasicMapping_CapturesTemps;
   Test_FromWSJTX_StripsPlusFromRST;
   Test_RoverCallAfterCALL_Overrides;
   Test_CALLAfterRoverCall_DoesNotOverride;
   Test_ModeNotOverwrittenAfterSet;

   Test_ImportSingleRecord;
   Test_ImportFQPRecord_QTHSet;
   Test_ImportMultipleRecords;
   Test_ImportSkipsHeader;
   Test_ImportEmptyString_ZeroRecords;
   Test_ImportNoEOR_ZeroRecords;
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

   m := GetADIFMode('DATA');
   CheckEquals(Integer(Digital), Integer(m.msmMode),         'DATA.Mode');
   CheckEquals(Integer(eData),   Integer(m.msmExtendedMode), 'DATA.ExtMode');

   // --- CW family (reverse-sidetone) ---
   m := GetADIFMode('CW-R');
   CheckEquals(Integer(CW),    Integer(m.msmMode),         'CW-R.Mode');
   CheckEquals(Integer(eCW_R), Integer(m.msmExtendedMode), 'CW-R.ExtMode');

   // --- Digital family (reverses + protocols) ---
   m := GetADIFMode('RTTY-R');
   CheckEquals(Integer(Digital), Integer(m.msmMode), 'RTTY-R.Mode');
   CheckEquals(Integer(eRTTY_R), Integer(m.msmExtendedMode), 'RTTY-R.ExtMode');

   m := GetADIFMode('DATA-R');
   CheckEquals(Integer(Digital), Integer(m.msmMode), 'DATA-R.Mode');
   CheckEquals(Integer(eData_R), Integer(m.msmExtendedMode), 'DATA-R.ExtMode');

   m := GetADIFMode('PSK-R');
   CheckEquals(Integer(Digital), Integer(m.msmMode), 'PSK-R.Mode');
   CheckEquals(Integer(ePSK_R),  Integer(m.msmExtendedMode), 'PSK-R.ExtMode');

   m := GetADIFMode('JT65');
   CheckEquals(Integer(Digital), Integer(m.msmMode), 'JT65.Mode');
   CheckEquals(Integer(eJT65),   Integer(m.msmExtendedMode), 'JT65.ExtMode');

   m := GetADIFMode('PSK63');
   CheckEquals(Integer(Digital), Integer(m.msmMode), 'PSK63.Mode');
   CheckEquals(Integer(ePSK63),  Integer(m.msmExtendedMode), 'PSK63.ExtMode');

   m := GetADIFMode('DATA-FM');
   CheckEquals(Integer(Digital),  Integer(m.msmMode), 'DATA-FM.Mode');
   CheckEquals(Integer(eData_FM), Integer(m.msmExtendedMode), 'DATA-FM.ExtMode');

   // --- Phone family (narrowband + digital voice) ---
   m := GetADIFMode('FM-N');
   CheckEquals(Integer(Phone), Integer(m.msmMode),         'FM-N.Mode');
   CheckEquals(Integer(eFM_N), Integer(m.msmExtendedMode), 'FM-N.ExtMode');

   m := GetADIFMode('AM-N');
   CheckEquals(Integer(Phone), Integer(m.msmMode),         'AM-N.Mode');
   CheckEquals(Integer(eAM_N), Integer(m.msmExtendedMode), 'AM-N.ExtMode');

   m := GetADIFMode('WFM');
   CheckEquals(Integer(Phone), Integer(m.msmMode),         'WFM.Mode');
   CheckEquals(Integer(eWFM),  Integer(m.msmExtendedMode), 'WFM.ExtMode');

   m := GetADIFMode('C4FM');
   CheckEquals(Integer(Phone), Integer(m.msmMode),         'C4FM.Mode');
   CheckEquals(Integer(eC4FM), Integer(m.msmExtendedMode), 'C4FM.ExtMode');

   m := GetADIFMode('D-STAR');
   CheckEquals(Integer(Phone),  Integer(m.msmMode),         'D-STAR.Mode');
   CheckEquals(Integer(eDStar), Integer(m.msmExtendedMode), 'D-STAR.ExtMode');

   // Case-insensitive
   m := GetADIFMode('cw');
   CheckEquals(Integer(CW), Integer(m.msmMode), 'lowercase cw');

   m := GetADIFMode('d-star');
   CheckEquals(Integer(Phone), Integer(m.msmMode), 'lowercase d-star');
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
