unit uCabrilloFormat;

{
  Cabrillo per-field formatters extracted from
  trdos/PostUnit.tGenerateLogPortionOfCabrilloFile.

  WHY THIS UNIT EXISTS
  --------------------
  The full per-QSO Cabrillo line writer is 1,226 lines inside PostUnit.PAS
  with deep global-state and contest-specific branches.  Lifting the whole
  thing out is L-effort and not warranted in the pre-migration window.

  What IS lifted out here are the two pure, atomic, contest-correctness-
  critical pieces:

    FormatCabrilloFreq  -- "what string goes in the freq column for this QSO?"
    FormatCabrilloMode  -- "what string goes in the mode column for this QSO?"

  Both have well-defined inputs, no global state in the function bodies,
  and are easy to unit-test against the Cabrillo spec
  (https://wwrof.org/cabrillo/cabrillo-qso-data/).

  PostUnit.PAS calls these helpers; the two source-of-truth tables
  (tCabrilloFreqString, tCabrilloModeString) live here so any unit that
  used to import them from PostUnit only needs to `uses uCabrilloFormat`
  going forward.

  Pre-migration test target -- see docs/tr4w-migration-strategy.md
  ("Tier 1 Extraction Pattern").
}

interface

uses VC;

const
   // Cabrillo "frequency" column default per band (kHz string).
   // Used when the QSO frequency is unknown (0) or above 30 MHz, per the
   // Cabrillo spec.
   //
   // BandType enum order must match the QSOTotals/ContestExchange band order
   // -- this array is also referenced by LOGContactToUDP.
   tCabrilloFreqString : array[Band160..BandLight] of PChar =
      (
         '1800',
         '3500',
         '7000',
         '14000',
         '21000',
         '28000',
         '10100',
         '18100',
         '24900',
         '50',
         '144',
         '222',
         '432',
         '902',
         '1.2G',
         '2.3G',
         '3.4G',
         '5.7G',
         '10G',
         '24G',
         'LIGHT'
      );

   // Cabrillo "mode" column default per mode.  Indexed by ModeType.
   // Digital and FM have callers-side overrides (see FormatCabrilloMode);
   // nil entries correspond to ModeType slots that do not appear in
   // Cabrillo logs.
   tCabrilloModeString : array[ModeType] of PChar =
      (
         'CW',
         'RY',
         'PH',
         nil,
         nil,
         'FM'
      );

// ---------------------------------------------------------------------------
// FormatCabrilloFreq
//
// Returns the Cabrillo "frequency" column string per spec:
//   - showFreqInLog = False  -> always the band default (tCabrilloFreqString)
//   - freqHz = 0             -> band default
//   - 0 < freqHz < 30 MHz    -> kHz integer (freqHz div 1000)
//   - freqHz >= 30 MHz       -> band default (spec: do not use actual freq)
//
// freqHz is the QSO frequency in Hz; the result is in kHz (or the band
// label string for above-30-MHz).
// ---------------------------------------------------------------------------
function FormatCabrilloFreq(band: BandType; freqHz: LongInt;
                            showFreqInLog: Boolean): AnsiString;

// ---------------------------------------------------------------------------
// FormatCabrilloMode
//
// Returns the Cabrillo "mode" column string per spec.  Caller passes
// modeOverridesToPhone = True for FM contacts in contests where the
// log must show 'PH' rather than 'FM' (e.g. WINTERFIELDDAY).  This
// keeps the function ignorant of ContestType.
//
//   - Digital + (eNoMode or eRTTY)  -> 'RY'
//   - Digital + anything else        -> 'DG'
//   - FM with modeOverridesToPhone   -> 'PH'
//   - Otherwise                      -> tCabrilloModeString[mode]
//                                      (may be empty for slots set to nil)
// ---------------------------------------------------------------------------
function FormatCabrilloMode(mode: ModeType; extMode: ExtendedModeType;
                            modeOverridesToPhone: Boolean): AnsiString;

implementation

uses SysUtils;

function FormatCabrilloFreq(band: BandType; freqHz: LongInt;
                            showFreqInLog: Boolean): AnsiString;
begin
   if showFreqInLog then
      begin
      if freqHz = 0 then
         begin
         Result := AnsiString(tCabrilloFreqString[band]);
         end
      else if (freqHz > 0) and (freqHz < 30000000) then
         begin
         Result := AnsiString(IntToStr(freqHz div 1000));
         end
      else
         begin
         // freqHz >= 30 MHz -- Cabrillo spec: use band default
         Result := AnsiString(tCabrilloFreqString[band]);
         end;
      end
   else
      begin
      Result := AnsiString(tCabrilloFreqString[band]);
      end;
end;

function FormatCabrilloMode(mode: ModeType; extMode: ExtendedModeType;
                            modeOverridesToPhone: Boolean): AnsiString;
begin
   if mode = Digital then
      begin
      if extMode in [eNoMode, eRTTY] then
         begin
         Result := 'RY';
         end
      else
         begin
         Result := 'DG';
         end;
      end
   else if (mode = FM) and modeOverridesToPhone then
      begin
      Result := 'PH';
      end
   else
      begin
      Result := AnsiString(tCabrilloModeString[mode]);
      end;
end;

end.
