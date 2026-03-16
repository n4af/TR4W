unit uTestRadioBand;

{
  Unit tests for uRadioBand — FreqToRadioBand and RadioBandToFreq.

  Covers:
    - FreqToRadioBand: centre-of-band spot checks for every band
    - FreqToRadioBand: boundary frequencies (just inside / just outside)
    - FreqToRadioBand: edge cases (0 Hz, very high frequencies)
    - RadioBandToFreq: default calling frequency for each band
    - Round-trip: RadioBandToFreq → FreqToRadioBand for all named bands
}

interface

uses
   SysUtils, uTR4WTestFramework, uRadioBand;

type
   TRadioBandTests = class(TTestCase)
   protected
      // FreqToRadioBand — centre of each band
      procedure Test_FreqToBand_160m;
      procedure Test_FreqToBand_80m;
      procedure Test_FreqToBand_60m;
      procedure Test_FreqToBand_40m;
      procedure Test_FreqToBand_30m;
      procedure Test_FreqToBand_20m;
      procedure Test_FreqToBand_17m;
      procedure Test_FreqToBand_15m;
      procedure Test_FreqToBand_12m;
      procedure Test_FreqToBand_10m;
      procedure Test_FreqToBand_6m;
      procedure Test_FreqToBand_4m;
      procedure Test_FreqToBand_2m;
      procedure Test_FreqToBand_70cm;

      // FreqToRadioBand — boundary and edge cases
      procedure Test_FreqToBand_ZeroIsBelow160m;
      procedure Test_FreqToBand_Above500MHzIsNone;
      procedure Test_FreqToBand_40m_UpperEdgeIn;
      procedure Test_FreqToBand_40m_UpperEdgeOut;
      procedure Test_FreqToBand_20m_UpperEdgeIn;
      procedure Test_FreqToBand_20m_UpperEdgeOut;

      // RadioBandToFreq — default calling frequency per band
      procedure Test_BandToFreq_160m;
      procedure Test_BandToFreq_20m;
      procedure Test_BandToFreq_None_Defaults20m;

      // Round-trip
      procedure Test_BandFreq_RoundTrip;

   public
      procedure RunAllTests; override;
   end;

implementation

// ---------------------------------------------------------------------------
// FreqToRadioBand — centre of each band
// ---------------------------------------------------------------------------

procedure TRadioBandTests.Test_FreqToBand_160m;
begin
   BeginTest('FreqToRadioBand(1800000) = rb160m');
   CheckEquals(Ord(rb160m), Ord(FreqToRadioBand(1800000)));
end;

procedure TRadioBandTests.Test_FreqToBand_80m;
begin
   BeginTest('FreqToRadioBand(3700000) = rb80m');
   CheckEquals(Ord(rb80m), Ord(FreqToRadioBand(3700000)));
end;

procedure TRadioBandTests.Test_FreqToBand_60m;
begin
   BeginTest('FreqToRadioBand(5357000) = rb60m');
   CheckEquals(Ord(rb60m), Ord(FreqToRadioBand(5357000)));
end;

procedure TRadioBandTests.Test_FreqToBand_40m;
begin
   BeginTest('FreqToRadioBand(7050000) = rb40m');
   CheckEquals(Ord(rb40m), Ord(FreqToRadioBand(7050000)));
end;

procedure TRadioBandTests.Test_FreqToBand_30m;
begin
   BeginTest('FreqToRadioBand(10125000) = rb30m');
   CheckEquals(Ord(rb30m), Ord(FreqToRadioBand(10125000)));
end;

procedure TRadioBandTests.Test_FreqToBand_20m;
begin
   BeginTest('FreqToRadioBand(14200000) = rb20m');
   CheckEquals(Ord(rb20m), Ord(FreqToRadioBand(14200000)));
end;

procedure TRadioBandTests.Test_FreqToBand_17m;
begin
   BeginTest('FreqToRadioBand(18100000) = rb17m');
   CheckEquals(Ord(rb17m), Ord(FreqToRadioBand(18100000)));
end;

procedure TRadioBandTests.Test_FreqToBand_15m;
begin
   BeginTest('FreqToRadioBand(21200000) = rb15m');
   CheckEquals(Ord(rb15m), Ord(FreqToRadioBand(21200000)));
end;

procedure TRadioBandTests.Test_FreqToBand_12m;
begin
   BeginTest('FreqToRadioBand(24940000) = rb12m');
   CheckEquals(Ord(rb12m), Ord(FreqToRadioBand(24940000)));
end;

procedure TRadioBandTests.Test_FreqToBand_10m;
begin
   BeginTest('FreqToRadioBand(28500000) = rb10m');
   CheckEquals(Ord(rb10m), Ord(FreqToRadioBand(28500000)));
end;

procedure TRadioBandTests.Test_FreqToBand_6m;
begin
   BeginTest('FreqToRadioBand(50125000) = rb6m');
   CheckEquals(Ord(rb6m), Ord(FreqToRadioBand(50125000)));
end;

procedure TRadioBandTests.Test_FreqToBand_4m;
begin
   BeginTest('FreqToRadioBand(70200000) = rb4m');
   CheckEquals(Ord(rb4m), Ord(FreqToRadioBand(70200000)));
end;

procedure TRadioBandTests.Test_FreqToBand_2m;
begin
   BeginTest('FreqToRadioBand(144200000) = rb2m');
   CheckEquals(Ord(rb2m), Ord(FreqToRadioBand(144200000)));
end;

procedure TRadioBandTests.Test_FreqToBand_70cm;
begin
   BeginTest('FreqToRadioBand(432100000) = rb70cm');
   CheckEquals(Ord(rb70cm), Ord(FreqToRadioBand(432100000)));
end;

// ---------------------------------------------------------------------------
// FreqToRadioBand — boundary and edge cases
// ---------------------------------------------------------------------------

procedure TRadioBandTests.Test_FreqToBand_ZeroIsBelow160m;
begin
   BeginTest('FreqToRadioBand(0) = rb160m  (0 < 2 MHz threshold)');
   CheckEquals(Ord(rb160m), Ord(FreqToRadioBand(0)));
end;

procedure TRadioBandTests.Test_FreqToBand_Above500MHzIsNone;
begin
   BeginTest('FreqToRadioBand(1000000000) = rbNone  (>= 500 MHz)');
   CheckEquals(Ord(rbNone), Ord(FreqToRadioBand(1000000000)));
end;

procedure TRadioBandTests.Test_FreqToBand_40m_UpperEdgeIn;
begin
   // 7.299.999 Hz is still inside the 40m window (< 7.300.000)
   BeginTest('FreqToRadioBand(7299999) = rb40m  (just inside upper edge)');
   CheckEquals(Ord(rb40m), Ord(FreqToRadioBand(7299999)));
end;

procedure TRadioBandTests.Test_FreqToBand_40m_UpperEdgeOut;
begin
   // 7.300.000 Hz steps into the 30m window (>= 7.300.000)
   BeginTest('FreqToRadioBand(7300000) = rb30m  (just above 40m upper edge)');
   CheckEquals(Ord(rb30m), Ord(FreqToRadioBand(7300000)));
end;

procedure TRadioBandTests.Test_FreqToBand_20m_UpperEdgeIn;
begin
   BeginTest('FreqToRadioBand(14999999) = rb20m  (just inside upper edge)');
   CheckEquals(Ord(rb20m), Ord(FreqToRadioBand(14999999)));
end;

procedure TRadioBandTests.Test_FreqToBand_20m_UpperEdgeOut;
begin
   BeginTest('FreqToRadioBand(15000000) = rb17m  (just above 20m upper edge)');
   CheckEquals(Ord(rb17m), Ord(FreqToRadioBand(15000000)));
end;

// ---------------------------------------------------------------------------
// RadioBandToFreq — default calling frequency per band
// ---------------------------------------------------------------------------

procedure TRadioBandTests.Test_BandToFreq_160m;
begin
   BeginTest('RadioBandToFreq(rb160m) = 1900000');
   CheckEquals(1900000, Integer(RadioBandToFreq(rb160m)));
end;

procedure TRadioBandTests.Test_BandToFreq_20m;
begin
   BeginTest('RadioBandToFreq(rb20m) = 14100000');
   CheckEquals(14100000, Integer(RadioBandToFreq(rb20m)));
end;

procedure TRadioBandTests.Test_BandToFreq_None_Defaults20m;
begin
   BeginTest('RadioBandToFreq(rbNone) = 14100000  (default to 20m)');
   CheckEquals(14100000, Integer(RadioBandToFreq(rbNone)));
end;

// ---------------------------------------------------------------------------
// Round-trip: RadioBandToFreq -> FreqToRadioBand
//
// For every named band (rb160m .. rb70cm), the default calling frequency
// must map back to the same band.  rbNone is excluded because
// RadioBandToFreq(rbNone) returns the 20m default, not a None frequency.
// ---------------------------------------------------------------------------

procedure TRadioBandTests.Test_BandFreq_RoundTrip;
const
   BandNames: array[rb160m..rb70cm] of string = (
      '160m','80m','60m','40m','30m','20m','17m','15m','12m','10m',
      '6m','4m','2m','70cm');
var
   band  : TRadioBand;
   freq  : LongInt;
   back  : TRadioBand;
begin
   BeginTest('RadioBandToFreq -> FreqToRadioBand round-trip for all named bands');
   for band := rb160m to rb70cm do
      begin
      freq := RadioBandToFreq(band);
      back := FreqToRadioBand(freq);
      if back <> band then
         begin
         CheckEquals(Ord(band), Ord(back),
            Format('Round-trip failed for %s (freq=%d)', [BandNames[band], freq]));
         Exit;
         end;
      end;
   Check(True);
end;

// ---------------------------------------------------------------------------
// RunAllTests
// ---------------------------------------------------------------------------

procedure TRadioBandTests.RunAllTests;
begin
   // FreqToRadioBand — band centres
   Test_FreqToBand_160m;
   Test_FreqToBand_80m;
   Test_FreqToBand_60m;
   Test_FreqToBand_40m;
   Test_FreqToBand_30m;
   Test_FreqToBand_20m;
   Test_FreqToBand_17m;
   Test_FreqToBand_15m;
   Test_FreqToBand_12m;
   Test_FreqToBand_10m;
   Test_FreqToBand_6m;
   Test_FreqToBand_4m;
   Test_FreqToBand_2m;
   Test_FreqToBand_70cm;

   // FreqToRadioBand — boundaries and edge cases
   Test_FreqToBand_ZeroIsBelow160m;
   Test_FreqToBand_Above500MHzIsNone;
   Test_FreqToBand_40m_UpperEdgeIn;
   Test_FreqToBand_40m_UpperEdgeOut;
   Test_FreqToBand_20m_UpperEdgeIn;
   Test_FreqToBand_20m_UpperEdgeOut;

   // RadioBandToFreq — default frequencies
   Test_BandToFreq_160m;
   Test_BandToFreq_20m;
   Test_BandToFreq_None_Defaults20m;

   // Round-trip
   Test_BandFreq_RoundTrip;
end;

end.
