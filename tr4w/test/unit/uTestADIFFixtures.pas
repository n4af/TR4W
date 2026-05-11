unit uTestADIFFixtures;

{
  ADIF import fixture-based tests.

  Each test loads a real-shape ADIF file from test/unit/fixtures/
  (curated representative samples of contest archetypes) and asserts
  the records uADIF parses out of it.

  This harness is intentionally designed to be NOT throwaway:
    * The LoadADIFFixture helper resolves fixtures relative to the
      test exe's directory, so the test runner finds them whether
      invoked from FullBuild.ps1 or interactively.
    * Each per-fixture test method focuses on a specific behaviour
      (record count, rover-call preservation, multi-county handling,
      mode mapping, etc.) so failures name the specific regression.
    * When ExportADIFToString lands (the rest of Issue #887), this
      same file gains a second helper -- RoundTripFixture(path) --
      that imports the file, exports it, re-imports the export, and
      asserts the re-imported records match the first import.  The
      existing per-fixture tests stay valid; differential round-trip
      becomes an opt-in extra check on top.

  Adding a new fixture: drop file into test/unit/fixtures/, add one
  Test_<Name> method below + register it in RunAllTests.  No changes
  to the harness needed.

  Issue #887 -- this is part of the migration test net per
  docs/tr4w-migration-strategy.md (Tier 1, build-before-the-freeze).
}

interface

uses
   uTR4WTestFramework;

type
   TADIFFixtureTests = class(TTestCase)
   public
      procedure RunAllTests; override;

   private
      procedure Test_FQP_RoverAndCountyLine_RecordCount;
      procedure Test_FQP_RoverAndCountyLine_RoverCallPreserved;
      procedure Test_FQP_RoverAndCountyLine_QTHsParsed;
      procedure Test_FQP_RoverAndCountyLine_ModesParsed;
      procedure Test_FQP_RoverAndCountyLine_BandsParsed;
      procedure Test_FQP_RoverAndCountyLine_SerialsParsed;

      procedure Test_CQWW_CW_RecordCount;
      procedure Test_CQWW_CW_CWModeParsed;
      procedure Test_CQWW_CW_ZoneParsed;

      procedure Test_CQWPX_SSB_RecordCount;
      procedure Test_CQWPX_SSB_USBSubmodeMaps;
      procedure Test_CQWPX_SSB_SerialsParsed;

      procedure Test_POTA_RecordCount;
      procedure Test_POTA_USBSubmodeAsBareMode;
      procedure Test_POTA_CallsignsParsed;

      procedure Test_ARRLSS_CW_RecordCount;
      procedure Test_ARRLSS_CW_PrecedenceParsed;
      procedure Test_ARRLSS_CW_CheckParsed;

      procedure Test_ARRLDIGI_RecordCount;
      procedure Test_ARRLDIGI_FT8ModeParsed;
      procedure Test_ARRLDIGI_BandParsed;

      procedure Test_ARRLFD_RecordCount;
      procedure Test_ARRLFD_MixedBandsAndModes;
      procedure Test_ARRLFD_StateAndSectionTempsCaptured;

      procedure Test_ARRLDX_CW_RecordCount;
      procedure Test_ARRLDX_CW_PowerFieldParsed;

      procedure Test_IN7QPNE_RecordCount;
      procedure Test_IN7QPNE_MultiStateQTHsParsed;
      procedure Test_IN7QPNE_NotMarkedCountyLineAllowed;

      procedure Test_GeneralQSO_RecordCount;
      procedure Test_GeneralQSO_BareUSBModeAcceptsFallthrough;
      procedure Test_GeneralQSO_NameFieldParsed;
   end;

implementation

uses
   SysUtils,
   Classes,
   VC,
   uADIF;

// ---------------------------------------------------------------------------
// Harness helpers
// ---------------------------------------------------------------------------

// Resolve a fixture path relative to the test exe's directory, then load
// the file's contents into a single string.
function LoadFixtureText(const relativePath: string): string;
var
   fullPath : string;
   sl       : TStringList;
begin
   fullPath := ExtractFilePath(ParamStr(0)) + 'fixtures\' + relativePath;
   if not FileExists(fullPath) then
      raise Exception.Create('Fixture not found: ' + fullPath);
   sl := TStringList.Create;
   try
      sl.LoadFromFile(fullPath);
      Result := sl.Text;
   finally
      sl.Free;
   end;
end;

// Load a fixture and parse it through ImportADIFFromString.  Caller
// gets a TContestExchangeArray of parsed records (no contest-specific
// tail applied -- that's MainUnit territory and not in the test
// runner's linkage).
function LoadADIFFixture(const relativePath: string): TContestExchangeArray;
begin
   ImportADIFFromString(LoadFixtureText(relativePath), Result);
end;

// ---------------------------------------------------------------------------
// FQP fixture: 3 records -- one rover call (KG1S/MON), two consecutive
// W4AFC records for a county-line entry (HIL + PIN).
// Captured from a real export by TR4W after the Issue #887 part 3
// refactor + the SRX_STRING normalization + the WK3 / CountyLineAllowed
// follow-up fixes.
// ---------------------------------------------------------------------------

procedure TADIFFixtureTests.Test_FQP_RoverAndCountyLine_RecordCount;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_FQP_RoverAndCountyLine_RecordCount');
   records := LoadADIFFixture('fqp_rover_and_county_line.adi');
   CheckEquals(3, Length(records),
               'FQP fixture has 3 records (KG1S/MON rover + W4AFC HIL/PIN)');
end;

procedure TADIFFixtureTests.Test_FQP_RoverAndCountyLine_RoverCallPreserved;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_FQP_RoverAndCountyLine_RoverCallPreserved');
   records := LoadADIFFixture('fqp_rover_and_county_line.adi');
   // The rover full call (KG1S/MON) is emitted via APP_TR4W_ROVERCALL
   // and must override the bare <CALL>KG1S on import.  See the
   // tAdifAPP_TR4W_ROVERCALL handler in uADIF.ApplyADIFFieldsToExchange.
   CheckEquals('KG1S/MON', string(records[0].Callsign),
               '[0] rover call preserved end-to-end');
   CheckEquals('W4AFC',    string(records[1].Callsign), '[1] CALL');
   CheckEquals('W4AFC',    string(records[2].Callsign), '[2] CALL');
end;

procedure TADIFFixtureTests.Test_FQP_RoverAndCountyLine_QTHsParsed;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_FQP_RoverAndCountyLine_QTHsParsed');
   records := LoadADIFFixture('fqp_rover_and_county_line.adi');
   // QTHString must come from the <QTH> ADIF tag and survive the field
   // mapping intact -- this is what populates the on-screen QTH column.
   CheckEquals('MON', string(records[0].QTHString), '[0] QTH=MON');
   CheckEquals('HIL', string(records[1].QTHString), '[1] QTH=HIL');
   CheckEquals('PIN', string(records[2].QTHString), '[2] QTH=PIN');
end;

procedure TADIFFixtureTests.Test_FQP_RoverAndCountyLine_ModesParsed;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_FQP_RoverAndCountyLine_ModesParsed');
   records := LoadADIFFixture('fqp_rover_and_county_line.adi');
   // Record 0: MODE=SSB + SUBMODE=USB -- maps to (Phone, eUSB).
   CheckEquals(Integer(Phone), Integer(records[0].Mode),    '[0] Mode=Phone');
   CheckEquals(Integer(eUSB),  Integer(records[0].ExtMode), '[0] ExtMode=eUSB');
   // Records 1 & 2: MODE=CW.
   CheckEquals(Integer(CW),  Integer(records[1].Mode),    '[1] Mode=CW');
   CheckEquals(Integer(eCW), Integer(records[1].ExtMode), '[1] ExtMode=eCW');
   CheckEquals(Integer(CW),  Integer(records[2].Mode),    '[2] Mode=CW');
   CheckEquals(Integer(eCW), Integer(records[2].ExtMode), '[2] ExtMode=eCW');
end;

procedure TADIFFixtureTests.Test_FQP_RoverAndCountyLine_BandsParsed;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_FQP_RoverAndCountyLine_BandsParsed');
   records := LoadADIFFixture('fqp_rover_and_county_line.adi');
   CheckEquals(Integer(Band20), Integer(records[0].Band), '[0] BAND=20m');
   CheckEquals(Integer(Band6),  Integer(records[1].Band), '[1] BAND=6m');
   CheckEquals(Integer(Band6),  Integer(records[2].Band), '[2] BAND=6m');
end;

procedure TADIFFixtureTests.Test_FQP_RoverAndCountyLine_SerialsParsed;
var
   records : TContestExchangeArray;
begin
   BeginTest('Test_FQP_RoverAndCountyLine_SerialsParsed');
   records := LoadADIFFixture('fqp_rover_and_county_line.adi');
   CheckEquals(33, Integer(records[0].NumberSent), '[0] STX=00033');
   CheckEquals(2,  Integer(records[1].NumberSent), '[1] STX=00002');
   CheckEquals(2,  Integer(records[2].NumberSent), '[2] STX=00002');
end;

// ---------------------------------------------------------------------------
// CQ WW CW fixture: zone-based exchange (RST + CQ zone).
// First 3 records of a real CQ-WW-CW log.
// Exercises: MODE=CW, CQZ field -> exch.Zone, RST 3-digit form.
// ---------------------------------------------------------------------------

procedure TADIFFixtureTests.Test_CQWW_CW_RecordCount;
var records : TContestExchangeArray;
begin
   BeginTest('Test_CQWW_CW_RecordCount');
   records := LoadADIFFixture('cqww_cw_zones.adi');
   CheckEquals(3, Length(records), 'CQWW CW fixture has 3 records');
end;

procedure TADIFFixtureTests.Test_CQWW_CW_CWModeParsed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_CQWW_CW_CWModeParsed');
   records := LoadADIFFixture('cqww_cw_zones.adi');
   CheckEquals(Integer(CW),  Integer(records[0].Mode),    '[0] Mode=CW');
   CheckEquals(Integer(eCW), Integer(records[0].ExtMode), '[0] ExtMode=eCW');
end;

procedure TADIFFixtureTests.Test_CQWW_CW_ZoneParsed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_CQWW_CW_ZoneParsed');
   records := LoadADIFFixture('cqww_cw_zones.adi');
   // First record: CQZ=14 (EF6T, Spain).  Field gets parsed into
   // exch.Zone via tAdifCQ_Z handler.
   CheckEquals(14, Integer(records[0].Zone), '[0] CQZ=14');
   CheckEquals(7,  Integer(records[1].Zone), '[1] CQZ=07 (V47T)');
end;

// ---------------------------------------------------------------------------
// CQ WPX SSB fixture: serial-number exchange (RST + serial).
// Exercises: MODE=SSB + SUBMODE=USB -> (Phone, eUSB), SRX/STX 5-digit
// serials.
// ---------------------------------------------------------------------------

procedure TADIFFixtureTests.Test_CQWPX_SSB_RecordCount;
var records : TContestExchangeArray;
begin
   BeginTest('Test_CQWPX_SSB_RecordCount');
   records := LoadADIFFixture('cqwpx_ssb_serials.adi');
   CheckEquals(3, Length(records), 'CQWPX SSB fixture has 3 records');
end;

procedure TADIFFixtureTests.Test_CQWPX_SSB_USBSubmodeMaps;
var records : TContestExchangeArray;
begin
   BeginTest('Test_CQWPX_SSB_USBSubmodeMaps');
   records := LoadADIFFixture('cqwpx_ssb_serials.adi');
   // The SUBMODE=USB field handler in ApplyADIFFieldsToExchange
   // overwrites whatever MODE=SSB set with (Phone, eUSB).
   CheckEquals(Integer(Phone), Integer(records[0].Mode),    '[0] Mode=Phone');
   CheckEquals(Integer(eUSB),  Integer(records[0].ExtMode), '[0] ExtMode=eUSB');
end;

procedure TADIFFixtureTests.Test_CQWPX_SSB_SerialsParsed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_CQWPX_SSB_SerialsParsed');
   records := LoadADIFFixture('cqwpx_ssb_serials.adi');
   // <SRX:5>03094 / <STX:5>00001 etc.
   CheckEquals(3094, Integer(records[0].NumberReceived), '[0] SRX=03094');
   CheckEquals(1,    Integer(records[0].NumberSent),     '[0] STX=00001');
   CheckEquals(108,  Integer(records[1].NumberReceived), '[1] SRX=00108');
   CheckEquals(2,    Integer(records[1].NumberSent),     '[1] STX=00002');
end;

// ---------------------------------------------------------------------------
// POTA fixture: park-reference exchange.
// Exercises: MY_SIG/SIG=POTA, SIG_INFO=park ref, mix of CW + USB modes.
// Note: ContestExchange.QTHString is set by the contest-tail (in
// MainUnit) for POTA -- not testable here from uADIF alone.  Tests
// only cover what ApplyADIFFieldsToExchange does on its own.
// ---------------------------------------------------------------------------

procedure TADIFFixtureTests.Test_POTA_RecordCount;
var records : TContestExchangeArray;
begin
   BeginTest('Test_POTA_RecordCount');
   records := LoadADIFFixture('pota_park_refs.adi');
   CheckEquals(3, Length(records), 'POTA fixture has 3 records');
end;

procedure TADIFFixtureTests.Test_POTA_USBSubmodeAsBareMode;
var records : TContestExchangeArray;
begin
   BeginTest('Test_POTA_USBSubmodeAsBareMode');
   records := LoadADIFFixture('pota_park_refs.adi');
   // Records 0/1: MODE=CW.
   CheckEquals(Integer(CW), Integer(records[0].Mode), '[0] Mode=CW');
   CheckEquals(Integer(CW), Integer(records[1].Mode), '[1] Mode=CW');
   // Record 2: MODE=USB (no SUBMODE; USB appears directly as MODE).
   // The non-standard "USB as bare MODE" goes through GetADIFMode and
   // falls into the else branch -- Mode = NoMode.  This documents
   // existing behaviour; might want to teach GetADIFMode about bare-
   // USB in MODE field as a follow-up, but for now record it.
   CheckEquals(Integer(NoMode), Integer(records[2].Mode),
               '[2] bare USB in MODE field (not SUBMODE) currently '
               + 'falls through GetADIFMode to NoMode');
end;

procedure TADIFFixtureTests.Test_POTA_CallsignsParsed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_POTA_CallsignsParsed');
   records := LoadADIFFixture('pota_park_refs.adi');
   CheckEquals('AF4O',  string(records[0].Callsign), '[0]');
   CheckEquals('KC1YL', string(records[1].Callsign), '[1]');
   CheckEquals('W2SUB', string(records[2].Callsign), '[2]');
end;

// ---------------------------------------------------------------------------
// ARRL Sweepstakes CW fixture: complex multi-field exchange.
// Exercises: PRECEDENCE, CHECK, ARRL_SECT, STATE fields all in one record.
// ---------------------------------------------------------------------------

procedure TADIFFixtureTests.Test_ARRLSS_CW_RecordCount;
var records : TContestExchangeArray;
begin
   BeginTest('Test_ARRLSS_CW_RecordCount');
   records := LoadADIFFixture('arrlss_cw_sections.adi');
   CheckEquals(3, Length(records), 'ARRL-SS-CW fixture has 3 records');
end;

procedure TADIFFixtureTests.Test_ARRLSS_CW_PrecedenceParsed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_ARRLSS_CW_PrecedenceParsed');
   records := LoadADIFFixture('arrlss_cw_sections.adi');
   // <PRECEDENCE:1>M for record 0/1, <PRECEDENCE:1>A for record 2.
   CheckEquals('M', string(records[0].Precedence), '[0] Precedence=M');
   CheckEquals('M', string(records[1].Precedence), '[1] Precedence=M');
   CheckEquals('A', string(records[2].Precedence), '[2] Precedence=A');
end;

procedure TADIFFixtureTests.Test_ARRLSS_CW_CheckParsed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_ARRLSS_CW_CheckParsed');
   records := LoadADIFFixture('arrlss_cw_sections.adi');
   // <CHECK:2>57 / 70 / 68 -- 2-digit year-of-license check.
   CheckEquals(57, Integer(records[0].Check), '[0] Check=57');
   CheckEquals(70, Integer(records[1].Check), '[1] Check=70');
   CheckEquals(68, Integer(records[2].Check), '[2] Check=68');
end;

// ---------------------------------------------------------------------------
// ARRL Digital Contest fixture: FT8 grid-square exchange.
// Exercises: MODE=FT8, GRIDSQUARE field, RST as SNR (-12, -4) -- which
// hits the int-parse fallback for non-numeric RST values.
// ---------------------------------------------------------------------------

procedure TADIFFixtureTests.Test_ARRLDIGI_RecordCount;
var records : TContestExchangeArray;
begin
   BeginTest('Test_ARRLDIGI_RecordCount');
   records := LoadADIFFixture('arrl_digi_grids.adi');
   CheckEquals(2, Length(records), 'ARRL-DIGI fixture has 2 records');
end;

procedure TADIFFixtureTests.Test_ARRLDIGI_FT8ModeParsed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_ARRLDIGI_FT8ModeParsed');
   records := LoadADIFFixture('arrl_digi_grids.adi');
   CheckEquals(Integer(Digital), Integer(records[0].Mode),    '[0] Mode=Digital');
   CheckEquals(Integer(eFT8),    Integer(records[0].ExtMode), '[0] ExtMode=eFT8');
end;

procedure TADIFFixtureTests.Test_ARRLDIGI_BandParsed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_ARRLDIGI_BandParsed');
   records := LoadADIFFixture('arrl_digi_grids.adi');
   CheckEquals(Integer(Band6), Integer(records[0].Band), '[0] BAND=6m');
   CheckEquals(Integer(Band6), Integer(records[1].Band), '[1] BAND=6m');
end;

// ---------------------------------------------------------------------------
// ARRL Field Day fixture: class + section exchange, multi-band.
// Records span 70cm and 2m so the BAND lookup hits less-common entries.
// First record: SRX_STRING "1F CT" + ARRL_SECT=CT + STATE=CT.
// ---------------------------------------------------------------------------

procedure TADIFFixtureTests.Test_ARRLFD_RecordCount;
var records : TContestExchangeArray;
begin
   BeginTest('Test_ARRLFD_RecordCount');
   records := LoadADIFFixture('arrlfd_sections.adi');
   CheckEquals(3, Length(records), 'ARRL-FD fixture has 3 records');
end;

procedure TADIFFixtureTests.Test_ARRLFD_MixedBandsAndModes;
var records : TContestExchangeArray;
begin
   BeginTest('Test_ARRLFD_MixedBandsAndModes');
   records := LoadADIFFixture('arrlfd_sections.adi');
   // Records 0/1: BAND=70cm (Band432 in TR4W's BandType enum) + MODE=CW.
   // Tests the cm-band lookup, which includes a special-case re-spelling
   // ('70cm' instead of '432') in GetADIFBand's data.
   CheckEquals(Integer(Band432), Integer(records[0].Band), '[0] BAND=70cm (Band432)');
   CheckEquals(Integer(CW),      Integer(records[0].Mode), '[0] Mode=CW');
   // Record 2: BAND=2m + MODE=SSB.
   CheckEquals(Integer(Band2),  Integer(records[2].Band),    '[2] BAND=2m');
   CheckEquals(Integer(Phone),  Integer(records[2].Mode),    '[2] Mode=Phone');
end;

procedure TADIFFixtureTests.Test_ARRLFD_StateAndSectionTempsCaptured;
var
   records : TContestExchangeArray;
   fields  : TADIFFieldList;
   temps   : TADIFRecordTemps;
   exch    : ContestExchange;
   txt     : string;
   sList   : TStringList;
begin
   BeginTest('Test_ARRLFD_StateAndSectionTempsCaptured');
   records := LoadADIFFixture('arrlfd_sections.adi');
   CheckTrue(Length(records) >= 1, 'fixture loaded');
   // The default LoadADIFFixture discards temps.  For this test we
   // re-lex one record and apply directly so we can inspect temps.
   // Record 0: <STATE:2>CT and <ARRL_SECT:2>CT.
   sList := TStringList.Create;
   try
      sList.LoadFromFile(ExtractFilePath(ParamStr(0)) +
                         'fixtures\arrlfd_sections.adi');
      txt := sList.Text;
   finally
      sList.Free;
   end;
   // Crude extraction: take from the first '<CALL:' to the first '<EOR>'.
   txt := Copy(txt, Pos('<CALL:', txt),
               Pos('<EOR>', txt) + 5 - Pos('<CALL:', txt));
   ParseADIFFieldsList(txt, fields);
   InitContestExchangeForParse(exch);
   InitADIFRecordTemps(temps);
   ApplyADIFFieldsToExchange(fields, exch, temps);
   CheckEquals('CT', temps.State,     'STATE captured to temps');
   CheckEquals('CT', temps.ARRL_Sect, 'ARRL_SECT captured to temps');
end;

// ---------------------------------------------------------------------------
// ARRL DX CW fixture: DX exchange (RST + state for US/VE, RST + power
// for DX stations).  Tests RX_PWR field parsing.
// ---------------------------------------------------------------------------

procedure TADIFFixtureTests.Test_ARRLDX_CW_RecordCount;
var records : TContestExchangeArray;
begin
   BeginTest('Test_ARRLDX_CW_RecordCount');
   records := LoadADIFFixture('arrldx_cw_dxexch.adi');
   CheckEquals(3, Length(records), 'ARRL-DX-CW fixture has 3 records');
end;

procedure TADIFFixtureTests.Test_ARRLDX_CW_PowerFieldParsed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_ARRLDX_CW_PowerFieldParsed');
   records := LoadADIFFixture('arrldx_cw_dxexch.adi');
   // <RX_PWR:1>K / <RX_PWR:2>KW / <RX_PWR:3>400 -- DX power code or wattage.
   CheckEquals('K',   string(records[0].Power), '[0] RX_PWR=K');
   CheckEquals('KW',  string(records[1].Power), '[1] RX_PWR=KW');
   CheckEquals('400', string(records[2].Power), '[2] RX_PWR=400');
end;

// ---------------------------------------------------------------------------
// IN7QPNE fixture: multi-state QSO party (Indiana + 7-area + New England,
// concurrent).  The QTH carries county+state codes (NDE, KDE, AZAPH).
// Confirms multi-state QPs are NOT marked CountyLineAllowed, per
// issue #894 (out of scope for the single-state county-line bypass).
// ---------------------------------------------------------------------------

procedure TADIFFixtureTests.Test_IN7QPNE_RecordCount;
var records : TContestExchangeArray;
begin
   BeginTest('Test_IN7QPNE_RecordCount');
   records := LoadADIFFixture('in7qpne_multistate.adi');
   CheckEquals(3, Length(records), 'IN7QPNE fixture has 3 records');
end;

procedure TADIFFixtureTests.Test_IN7QPNE_MultiStateQTHsParsed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_IN7QPNE_MultiStateQTHsParsed');
   records := LoadADIFFixture('in7qpne_multistate.adi');
   // <QTH:3>NDE, <QTH:3>KDE, <QTH:5>AZAPH -- multi-state county codes.
   CheckEquals('NDE',   string(records[0].QTHString), '[0] QTH');
   CheckEquals('KDE',   string(records[1].QTHString), '[1] QTH');
   CheckEquals('AZAPH', string(records[2].QTHString), '[2] QTH');
end;

procedure TADIFFixtureTests.Test_IN7QPNE_NotMarkedCountyLineAllowed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_IN7QPNE_NotMarkedCountyLineAllowed');
   records := LoadADIFFixture('in7qpne_multistate.adi');
   // Documents the current scope: IN7QPNE is a multi-state QP but the
   // ContestType is mapped via the CONTEST_ID handler; until #894
   // adds the multi-state shape, CountyLineAllowed must remain False
   // for this contest's enum value so the import dupe-bypass does
   // NOT fire.  Asserting the flag's state guards against accidental
   // True flips.
   CheckFalse(ContestsArray[records[0].ceContest].CountyLineAllowed,
              'IN7QPNE-style multi-state QP must NOT have '
              + 'CountyLineAllowed=True until issue #894 lands');
end;

// ---------------------------------------------------------------------------
// GENERAL QSO fixture: no CONTEST_ID, MODE=USB directly (not via SUBMODE).
// Tests fallthrough behaviour for bare-USB and NAME field capture.
// ---------------------------------------------------------------------------

procedure TADIFFixtureTests.Test_GeneralQSO_RecordCount;
var records : TContestExchangeArray;
begin
   BeginTest('Test_GeneralQSO_RecordCount');
   records := LoadADIFFixture('generalqso_usb.adi');
   CheckEquals(3, Length(records), 'GENERAL QSO fixture has 3 records');
end;

procedure TADIFFixtureTests.Test_GeneralQSO_BareUSBModeAcceptsFallthrough;
var records : TContestExchangeArray;
begin
   BeginTest('Test_GeneralQSO_BareUSBModeAcceptsFallthrough');
   records := LoadADIFFixture('generalqso_usb.adi');
   // <MODE:3>USB with no SUBMODE.  USB is not in the GetADIFMode
   // lookup (USB lives only in GetADIFSubMode), so this falls through
   // to NoMode.  Documents the existing behaviour; teaching
   // GetADIFMode about bare USB/LSB in MODE field could be a follow-up.
   CheckEquals(Integer(NoMode), Integer(records[0].Mode),
               '[0] bare USB in MODE field falls through to NoMode');
end;

procedure TADIFFixtureTests.Test_GeneralQSO_NameFieldParsed;
var records : TContestExchangeArray;
begin
   BeginTest('Test_GeneralQSO_NameFieldParsed');
   records := LoadADIFFixture('generalqso_usb.adi');
   // First record has <NAME:4>MARK.
   CheckEquals('MARK', string(records[0].Name), '[0] Name=MARK');
end;

// ---------------------------------------------------------------------------
// Test suite dispatch
// ---------------------------------------------------------------------------

procedure TADIFFixtureTests.RunAllTests;
begin
   // FQP - rover + multi-county
   Test_FQP_RoverAndCountyLine_RecordCount;
   Test_FQP_RoverAndCountyLine_RoverCallPreserved;
   Test_FQP_RoverAndCountyLine_QTHsParsed;
   Test_FQP_RoverAndCountyLine_ModesParsed;
   Test_FQP_RoverAndCountyLine_BandsParsed;
   Test_FQP_RoverAndCountyLine_SerialsParsed;

   // CQ WW CW - zone exchange
   Test_CQWW_CW_RecordCount;
   Test_CQWW_CW_CWModeParsed;
   Test_CQWW_CW_ZoneParsed;

   // CQ WPX SSB - serial exchange + USB submode
   Test_CQWPX_SSB_RecordCount;
   Test_CQWPX_SSB_USBSubmodeMaps;
   Test_CQWPX_SSB_SerialsParsed;

   // POTA - park refs
   Test_POTA_RecordCount;
   Test_POTA_USBSubmodeAsBareMode;
   Test_POTA_CallsignsParsed;

   // ARRL SS CW - section + precedence + check
   Test_ARRLSS_CW_RecordCount;
   Test_ARRLSS_CW_PrecedenceParsed;
   Test_ARRLSS_CW_CheckParsed;

   // ARRL DIGI - FT8 grid
   Test_ARRLDIGI_RecordCount;
   Test_ARRLDIGI_FT8ModeParsed;
   Test_ARRLDIGI_BandParsed;

   // ARRL Field Day - class/section + multi-band
   Test_ARRLFD_RecordCount;
   Test_ARRLFD_MixedBandsAndModes;
   Test_ARRLFD_StateAndSectionTempsCaptured;

   // ARRL DX CW - DX power exchange
   Test_ARRLDX_CW_RecordCount;
   Test_ARRLDX_CW_PowerFieldParsed;

   // IN7QPNE - multi-state QP (issue #894)
   Test_IN7QPNE_RecordCount;
   Test_IN7QPNE_MultiStateQTHsParsed;
   Test_IN7QPNE_NotMarkedCountyLineAllowed;

   // GENERAL QSO - no CONTEST_ID, bare USB mode
   Test_GeneralQSO_RecordCount;
   Test_GeneralQSO_BareUSBModeAcceptsFallthrough;
   Test_GeneralQSO_NameFieldParsed;
end;

end.
