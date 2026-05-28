unit uCabrillo;

{
  Cabrillo line builders for use outside the final-log writer.

  WHY THIS UNIT EXISTS
  --------------------
  Several consumers need to render a single QSO as a Cabrillo "QSO:" /
  "X-QSO:" line without going through the full final-log writer in
  trdos/PostUnit.tGenerateLogPortionOfCabrilloFile (which is 1,200+
  lines of inline asm tightly coupled to its own globals).

  Currently the only consumer is the RTC 3.0 protocol's
  <CabrilloString> field (issue #920), where each contactinfo /
  contactdelete payload carries the QSO as a Cabrillo line.  Future
  consumers (header builder, score-row formatter, contest-specific
  mode/band normalization) live here too rather than fragmenting the
  source tree into one-purpose files.

  Pre-migration test target -- see docs/tr4w-migration-strategy.md
  ("Tier 1 Extraction Pattern").  The single-QSO builder here uses:

    uCabrilloFormat    -- FormatCabrilloFreq / FormatCabrilloMode
    uExchangeBuilder   -- BuildSentExchangeText / BuildRxExchangeText

  ...which are the same pure helpers PostUnit.PAS now imports, so the
  Cabrillo lines this unit produces agree with the final-log writer
  on freq, mode, and exchange shape.

  What we DO NOT promise: byte-identical column alignment with the
  final-log writer.  The Cabrillo spec only requires whitespace
  separation between fields; parsers (HAMSCORE, COS, log checkers)
  tokenize.  Operators submitting their log through the official
  Cabrillo file path are unaffected.
}

interface

uses
   VC;

// ---------------------------------------------------------------------------
// BuildSingleQsoCabrilloLine
//
// Returns a single Cabrillo "QSO:" or "X-QSO:" line for the given QSO,
// terminated with no line break (caller adds CRLF or wraps in XML).
//
// Format (whitespace-separated, per Cabrillo spec):
//   QSO: <freq> <mode> <date> <time> <mycall> <sent-exch> <hiscall> <rcv-exch>
//
// X-QSO records (RXData.ceXQSO = True) get an "X-QSO: " prefix instead of
// "QSO: " per Issue #750 / Cabrillo spec.
// ---------------------------------------------------------------------------
function BuildSingleQsoCabrilloLine(const RXData: ContestExchange): AnsiString;

implementation

uses
   SysUtils,
   uCabrilloFormat,        // FormatCabrilloFreq / FormatCabrilloMode
   uExchangeBuilder,       // BuildSentExchangeText / BuildRxExchangeText
   LogWind;                // MyCall global

function BuildSingleQsoCabrilloLine(const RXData: ContestExchange): AnsiString;
var
   sFreq:     AnsiString;
   sMode:     AnsiString;
   sPrefix:   AnsiString;
   sentExch:  string;
   rcvExch:   string;
   begin
   sFreq := FormatCabrilloFreq(RXData.Band, RXData.Frequency, True);
   sMode := FormatCabrilloMode(RXData.Mode, RXData.ExtMode, False);

   sentExch := BuildSentExchangeText(RXData);
   rcvExch  := BuildRxExchangeText(RXData);

   if RXData.ceXQSO then
      sPrefix := 'X-QSO: '
   else
      sPrefix := 'QSO: ';

   // YYYY-MM-DD HHMM per Cabrillo spec (time is 4 digits, no colon).
   Result := AnsiString(Format(
      '%s%s %s 20%.2d-%.2d-%.2d %.2d%.2d %s %s %s %s',
      [string(sPrefix),
       string(sFreq),
       string(sMode),
       RXData.tSysTime.qtYear, RXData.tSysTime.qtMonth, RXData.tSysTime.qtDay,
       RXData.tSysTime.qtHour, RXData.tSysTime.qtMinute,
       string(MyCall),
       sentExch,
       string(RXData.Callsign),
       rcvExch]));
   end;

end.
