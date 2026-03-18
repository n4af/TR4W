unit uRadioBand;

{
  Band/frequency pure utility functions.

  No dependencies on radio hardware, protocols, or UI — fully testable
  in isolation with the console test runner.

  TRadioBand is the canonical definition.  uNetRadioBase includes this unit
  in its interface uses clause so all existing consumers see TRadioBand
  unchanged — no other files need updating.

  D12 migration note:
    LongInt is 32-bit on both D7 and D12/32-bit.  Frequencies up to ~4.3 GHz
    fit safely.  If microwave bands above 2.1 GHz are ever added, switch to
    Int64 in Phase 3.
}

interface

// ---------------------------------------------------------------------------
// Band enum — canonical definition (moved from uNetRadioBase).
// Order matters: routines in this unit rely on the enum ordinal values only
// indirectly (via case statements), so the order is stable.
// ---------------------------------------------------------------------------

type TRadioBand = (rbNone,
                   rb160m, rb80m, rb60m, rb40m, rb30m,
                   rb20m,  rb17m, rb15m, rb12m, rb10m,
                   rb6m,   rb4m,  rb2m,  rb70cm);

// ---------------------------------------------------------------------------
// FreqToRadioBand — classify a frequency (Hz) into a ham band.
//
// Uses conventional band-edge frequencies.  Frequencies below 1.8 MHz
// (including 0) map to rb160m; frequencies at or above 500 MHz map to rbNone.
// Thread-safe: pure function, no side effects.
// ---------------------------------------------------------------------------

function FreqToRadioBand(freq: LongInt): TRadioBand;

// ---------------------------------------------------------------------------
// RadioBandToFreq — return the typical calling frequency for a band (Hz).
//
// Used when SetBand is called and no band-memory frequency is available.
// rbNone and unrecognised values default to 20m (14.100 MHz).
// ---------------------------------------------------------------------------

function RadioBandToFreq(band: TRadioBand): LongInt;

implementation

function FreqToRadioBand(freq: LongInt): TRadioBand;
begin
   if      freq < 2000000   then Result := rb160m
   else if freq < 4000000   then Result := rb80m
   else if freq < 6000000   then Result := rb60m
   else if freq < 7300000   then Result := rb40m
   else if freq < 11000000  then Result := rb30m
   else if freq < 15000000  then Result := rb20m
   else if freq < 19000000  then Result := rb17m
   else if freq < 22000000  then Result := rb15m
   else if freq < 25000000  then Result := rb12m
   else if freq < 30000000  then Result := rb10m
   else if freq < 54000000  then Result := rb6m
   else if freq < 80000000  then Result := rb4m
   else if freq < 170000000 then Result := rb2m
   else if freq < 500000000 then Result := rb70cm
   else                          Result := rbNone;
end;

function RadioBandToFreq(band: TRadioBand): LongInt;
begin
   case band of
      rb160m:  Result := 1900000;
      rb80m:   Result := 3600000;
      rb60m:   Result := 5357000;
      rb40m:   Result := 7100000;
      rb30m:   Result := 10125000;
      rb20m:   Result := 14100000;
      rb17m:   Result := 18100000;
      rb15m:   Result := 21100000;
      rb12m:   Result := 24920000;
      rb10m:   Result := 28400000;
      rb6m:    Result := 50100000;
      rb4m:    Result := 70100000;
      rb2m:    Result := 144100000;
      rb70cm:  Result := 432100000;
   else
      Result := 14100000;  // Default to 20m (covers rbNone)
   end;
end;

end.
