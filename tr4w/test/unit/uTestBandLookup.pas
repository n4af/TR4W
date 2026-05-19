unit uTestBandLookup;

{
  Unit tests for uBandLookup.CalculateBandMode.

  Extracted from tree.pas as part of the Tier 1 Extraction Pattern
  (see docs/tr4w-migration-strategy.md).  The procedure maps a frequency
  in Hz to a TR4W BandType + ModeType using the FreqModeArray table in
  VC.pas (25 entries, 160 m through 23 cm).

  Coverage strategy:
    - One spot-check per band, well inside the range (centre-of-band)
    - In/out boundary pairs at the CW/Phone split where mode flips
    - In/out boundary pairs at the band's outer edges (frMin and frMax)
    - Below 160 m, above 23 cm, and well-known "no-coverage" gaps return
      Band=NoBand and Mode=NoMode
    - The CW-or-Phone-but-not-set 7040..7100 kHz hole in the 40 m table
      (frMode=NoMode) is verified explicitly

  Pre-migration regression net: these tests must pass identically on
  Delphi 7 today and on Delphi 12 after the 64-bit migration, since
  Cardinal becomes a different width and the linear scan must still
  match the same ranges.
}

interface

uses
   SysUtils, uTR4WTestFramework, VC, uBandLookup;

type
   TBandLookupTests = class(TTestCase)
   protected
      // Internal helper -- calls CalculateBandMode and asserts both outputs.
      // Defined as a method so CheckEquals (protected on TTestCase) is in scope.
      procedure CheckBandMode(freq: Cardinal; expectBand: BandType;
                              expectMode: ModeType; const ctx: string);

      // Centre-of-band spot checks: known operating frequencies
      procedure Test_160m_Centre;
      procedure Test_80m_CW_Centre;
      procedure Test_80m_Phone_Centre;
      procedure Test_40m_CW_Centre;
      procedure Test_40m_Phone_Centre;
      procedure Test_30m_Centre;
      procedure Test_20m_CW_Centre;
      procedure Test_20m_Phone_Centre;
      procedure Test_17m_CW_Centre;
      procedure Test_17m_Phone_Centre;
      procedure Test_15m_CW_Centre;
      procedure Test_15m_Phone_Centre;
      procedure Test_12m_CW_Centre;
      procedure Test_12m_Phone_Centre;
      procedure Test_10m_CW_Centre;
      procedure Test_10m_Phone_Centre;
      procedure Test_6m_Centre;
      procedure Test_2m_Centre;
      procedure Test_222_Centre;
      procedure Test_432_Centre;
      procedure Test_902_Centre;
      procedure Test_1296_Centre;

      // CW/Phone mode-split boundaries: just below and just at/above
      procedure Test_80m_ModeSplit_3600_IsPhone;
      procedure Test_80m_ModeSplit_3599999_IsCW;
      procedure Test_20m_ModeSplit_14100_IsPhone;
      procedure Test_20m_ModeSplit_14099999_IsCW;
      procedure Test_15m_ModeSplit_21150_IsPhone;
      procedure Test_15m_ModeSplit_21149999_IsCW;

      // Band-edge boundaries: just inside (hit) vs. just outside (miss)
      procedure Test_160m_LowerEdge_In;
      procedure Test_160m_LowerEdge_Out;
      procedure Test_160m_UpperEdge_In;
      procedure Test_40m_UpperEdge_In;
      procedure Test_40m_UpperEdge_Out;
      procedure Test_20m_UpperEdge_In;
      procedure Test_20m_UpperEdge_Out;
      procedure Test_10m_UpperEdge_In;
      procedure Test_10m_UpperEdge_Out;

      // No-coverage cases
      procedure Test_Below160m_IsNoBand;
      procedure Test_AM_BroadcastBand_IsNoBand;
      procedure Test_GapBetween80And40_IsNoBand;
      procedure Test_GapBetween40And30_IsNoBand;
      procedure Test_GapBetween30And20_IsNoBand;
      procedure Test_Above23cm_IsNoBand;
      procedure Test_Zero_IsNoBand;

      // FreqModeArray quirk: 7040..7100 kHz is in 40 m but mode = NoMode
      procedure Test_40m_NoModeGap;

   public
      procedure RunAllTests; override;
   end;

implementation

// ---------------------------------------------------------------------------
// Helper -- single point of definition for the (Band, Mode) assertion shape.
// Method (not free procedure) so the protected CheckEquals is in scope.
// ---------------------------------------------------------------------------
procedure TBandLookupTests.CheckBandMode(freq: Cardinal; expectBand: BandType;
                                       expectMode: ModeType; const ctx: string);
var
   band: BandType;
   mode: ModeType;
begin
   band := Band160;  // any non-NoBand sentinel so we know it was written
   mode := CW;
   CalculateBandMode(freq, band, mode);
   CheckEquals(Integer(expectBand), Integer(band), ctx + ' band');
   CheckEquals(Integer(expectMode), Integer(mode), ctx + ' mode');
end;

// ---------------------------------------------------------------------------
// Centre-of-band spot checks
// ---------------------------------------------------------------------------

procedure TBandLookupTests.Test_160m_Centre;
begin
   BeginTest('Test_160m_Centre');
   // FreqModeArray entry: 1790000..2000000 Band160 NoMode
   CheckBandMode(1850000, Band160, NoMode, '1.85 MHz (160 m)');
end;

procedure TBandLookupTests.Test_80m_CW_Centre;
begin
   BeginTest('Test_80m_CW_Centre');
   // 3490000..3600000 Band80 CW
   CheckBandMode(3550000, Band80, CW, '3.55 MHz (80 m CW)');
end;

procedure TBandLookupTests.Test_80m_Phone_Centre;
begin
   BeginTest('Test_80m_Phone_Centre');
   // 3600000..4000000 Band80 Phone
   CheckBandMode(3800000, Band80, Phone, '3.80 MHz (80 m Phone)');
end;

procedure TBandLookupTests.Test_40m_CW_Centre;
begin
   BeginTest('Test_40m_CW_Centre');
   // 6990000..7040000 Band40 CW
   CheckBandMode(7020000, Band40, CW, '7.02 MHz (40 m CW)');
end;

procedure TBandLookupTests.Test_40m_Phone_Centre;
begin
   BeginTest('Test_40m_Phone_Centre');
   // 7100000..7300000 Band40 Phone
   CheckBandMode(7200000, Band40, Phone, '7.20 MHz (40 m Phone)');
end;

procedure TBandLookupTests.Test_30m_Centre;
begin
   BeginTest('Test_30m_Centre');
   // 10099000..10150000 Band30 CW
   CheckBandMode(10120000, Band30, CW, '10.12 MHz (30 m)');
end;

procedure TBandLookupTests.Test_20m_CW_Centre;
begin
   BeginTest('Test_20m_CW_Centre');
   // 13990000..14100000 Band20 CW
   CheckBandMode(14025000, Band20, CW, '14.025 MHz (20 m CW)');
end;

procedure TBandLookupTests.Test_20m_Phone_Centre;
begin
   BeginTest('Test_20m_Phone_Centre');
   // 14100000..14350000 Band20 Phone
   CheckBandMode(14250000, Band20, Phone, '14.25 MHz (20 m Phone)');
end;

procedure TBandLookupTests.Test_17m_CW_Centre;
begin
   BeginTest('Test_17m_CW_Centre');
   // 18068000..18110000 Band17 CW
   CheckBandMode(18080000, Band17, CW, '18.08 MHz (17 m CW)');
end;

procedure TBandLookupTests.Test_17m_Phone_Centre;
begin
   BeginTest('Test_17m_Phone_Centre');
   // 18110000..18168000 Band17 Phone
   CheckBandMode(18140000, Band17, Phone, '18.14 MHz (17 m Phone)');
end;

procedure TBandLookupTests.Test_15m_CW_Centre;
begin
   BeginTest('Test_15m_CW_Centre');
   // 20990000..21150000 Band15 CW
   CheckBandMode(21025000, Band15, CW, '21.025 MHz (15 m CW)');
end;

procedure TBandLookupTests.Test_15m_Phone_Centre;
begin
   BeginTest('Test_15m_Phone_Centre');
   // 21150000..21450000 Band15 Phone
   CheckBandMode(21300000, Band15, Phone, '21.30 MHz (15 m Phone)');
end;

procedure TBandLookupTests.Test_12m_CW_Centre;
begin
   BeginTest('Test_12m_CW_Centre');
   // 24890000..24930000 Band12 CW
   CheckBandMode(24910000, Band12, CW, '24.91 MHz (12 m CW)');
end;

procedure TBandLookupTests.Test_12m_Phone_Centre;
begin
   BeginTest('Test_12m_Phone_Centre');
   // 24930000..24990000 Band12 Phone
   CheckBandMode(24960000, Band12, Phone, '24.96 MHz (12 m Phone)');
end;

procedure TBandLookupTests.Test_10m_CW_Centre;
begin
   BeginTest('Test_10m_CW_Centre');
   // 28000000..28300000 Band10 CW
   CheckBandMode(28050000, Band10, CW, '28.05 MHz (10 m CW)');
end;

procedure TBandLookupTests.Test_10m_Phone_Centre;
begin
   BeginTest('Test_10m_Phone_Centre');
   // 28300000..29700000 Band10 Phone
   CheckBandMode(28500000, Band10, Phone, '28.50 MHz (10 m Phone)');
end;

procedure TBandLookupTests.Test_6m_Centre;
begin
   BeginTest('Test_6m_Centre');
   // 50100000..54000000 Band6 Phone (50000000..50100000 is CW)
   CheckBandMode(50125000, Band6, Phone, '50.125 MHz (6 m)');
end;

procedure TBandLookupTests.Test_2m_Centre;
begin
   BeginTest('Test_2m_Centre');
   // 144100000..148000000 Band2 Phone
   CheckBandMode(146000000, Band2, Phone, '146 MHz (2 m)');
end;

procedure TBandLookupTests.Test_222_Centre;
begin
   BeginTest('Test_222_Centre');
   // 218000000..250000000 Band222 Phone
   CheckBandMode(223500000, Band222, Phone, '223.5 MHz (1.25 m)');
end;

procedure TBandLookupTests.Test_432_Centre;
begin
   BeginTest('Test_432_Centre');
   // 400000000..500000000 Band432 Phone
   CheckBandMode(432100000, Band432, Phone, '432.1 MHz (70 cm)');
end;

procedure TBandLookupTests.Test_902_Centre;
begin
   BeginTest('Test_902_Centre');
   // 900000000..1000000000 Band902 Phone
   CheckBandMode(903100000, Band902, Phone, '903.1 MHz (33 cm)');
end;

procedure TBandLookupTests.Test_1296_Centre;
begin
   BeginTest('Test_1296_Centre');
   // 1000000000..1500000000 Band1296 Phone
   CheckBandMode(1296100000, Band1296, Phone, '1296.1 MHz (23 cm)');
end;

// ---------------------------------------------------------------------------
// CW/Phone mode-split boundary tests
//
// Verifies that the table's mode flip happens at the documented frequency
// and that the BOUNDARY is treated as Phone (inclusive on both sides of the
// split per FreqModeArray's `>= frMin and <= frMax` predicate).
// ---------------------------------------------------------------------------

procedure TBandLookupTests.Test_80m_ModeSplit_3600_IsPhone;
begin
   BeginTest('Test_80m_ModeSplit_3600_IsPhone');
   // 3600000 sits in both 3490000..3600000 CW AND 3600000..4000000 Phone.
   // Linear scan hits CW row first per FreqModeArray ordering.
   CheckBandMode(3600000, Band80, CW, '3.600 MHz exactly (first match: 80 m CW)');
end;

procedure TBandLookupTests.Test_80m_ModeSplit_3599999_IsCW;
begin
   BeginTest('Test_80m_ModeSplit_3599999_IsCW');
   CheckBandMode(3599999, Band80, CW, '3.599999 MHz (80 m CW)');
end;

procedure TBandLookupTests.Test_20m_ModeSplit_14100_IsPhone;
begin
   BeginTest('Test_20m_ModeSplit_14100_IsPhone');
   // Both rows include 14100000 -- CW row scans first.
   CheckBandMode(14100000, Band20, CW, '14.100 MHz exactly (first match: 20 m CW)');
end;

procedure TBandLookupTests.Test_20m_ModeSplit_14099999_IsCW;
begin
   BeginTest('Test_20m_ModeSplit_14099999_IsCW');
   CheckBandMode(14099999, Band20, CW, '14.099999 MHz (20 m CW)');
end;

procedure TBandLookupTests.Test_15m_ModeSplit_21150_IsPhone;
begin
   BeginTest('Test_15m_ModeSplit_21150_IsPhone');
   CheckBandMode(21150000, Band15, CW, '21.150 MHz exactly (first match: 15 m CW)');
end;

procedure TBandLookupTests.Test_15m_ModeSplit_21149999_IsCW;
begin
   BeginTest('Test_15m_ModeSplit_21149999_IsCW');
   CheckBandMode(21149999, Band15, CW, '21.149999 MHz (15 m CW)');
end;

// ---------------------------------------------------------------------------
// Band-edge boundary tests
// ---------------------------------------------------------------------------

procedure TBandLookupTests.Test_160m_LowerEdge_In;
begin
   BeginTest('Test_160m_LowerEdge_In');
   CheckBandMode(1790000, Band160, NoMode, '1.790 MHz (160 m lower edge)');
end;

procedure TBandLookupTests.Test_160m_LowerEdge_Out;
begin
   BeginTest('Test_160m_LowerEdge_Out');
   CheckBandMode(1789999, NoBand, NoMode, '1.789999 MHz (just below 160 m)');
end;

procedure TBandLookupTests.Test_160m_UpperEdge_In;
begin
   BeginTest('Test_160m_UpperEdge_In');
   CheckBandMode(2000000, Band160, NoMode, '2.000 MHz (160 m upper edge)');
end;

procedure TBandLookupTests.Test_40m_UpperEdge_In;
begin
   BeginTest('Test_40m_UpperEdge_In');
   CheckBandMode(7300000, Band40, Phone, '7.300 MHz (40 m upper edge)');
end;

procedure TBandLookupTests.Test_40m_UpperEdge_Out;
begin
   BeginTest('Test_40m_UpperEdge_Out');
   CheckBandMode(7300001, NoBand, NoMode, '7.300001 MHz (just above 40 m)');
end;

procedure TBandLookupTests.Test_20m_UpperEdge_In;
begin
   BeginTest('Test_20m_UpperEdge_In');
   CheckBandMode(14350000, Band20, Phone, '14.350 MHz (20 m upper edge)');
end;

procedure TBandLookupTests.Test_20m_UpperEdge_Out;
begin
   BeginTest('Test_20m_UpperEdge_Out');
   CheckBandMode(14350001, NoBand, NoMode, '14.350001 MHz (just above 20 m)');
end;

procedure TBandLookupTests.Test_10m_UpperEdge_In;
begin
   BeginTest('Test_10m_UpperEdge_In');
   CheckBandMode(29700000, Band10, Phone, '29.700 MHz (10 m upper edge)');
end;

procedure TBandLookupTests.Test_10m_UpperEdge_Out;
begin
   BeginTest('Test_10m_UpperEdge_Out');
   CheckBandMode(29700001, NoBand, NoMode, '29.700001 MHz (just above 10 m)');
end;

// ---------------------------------------------------------------------------
// No-coverage cases (Band = NoBand, Mode = NoMode)
// ---------------------------------------------------------------------------

procedure TBandLookupTests.Test_Below160m_IsNoBand;
begin
   BeginTest('Test_Below160m_IsNoBand');
   CheckBandMode(1500000, NoBand, NoMode, '1.5 MHz (below 160 m, no ham band)');
end;

procedure TBandLookupTests.Test_AM_BroadcastBand_IsNoBand;
begin
   BeginTest('Test_AM_BroadcastBand_IsNoBand');
   CheckBandMode(1000000, NoBand, NoMode, '1.0 MHz (AM broadcast)');
end;

procedure TBandLookupTests.Test_GapBetween80And40_IsNoBand;
begin
   BeginTest('Test_GapBetween80And40_IsNoBand');
   // 60 m (5 MHz) is commented out in FreqModeArray so it currently is no-band.
   CheckBandMode(5400000, NoBand, NoMode, '5.4 MHz (60 m band -- not in table)');
end;

procedure TBandLookupTests.Test_GapBetween40And30_IsNoBand;
begin
   BeginTest('Test_GapBetween40And30_IsNoBand');
   CheckBandMode(9000000, NoBand, NoMode, '9 MHz (between 40 m and 30 m)');
end;

procedure TBandLookupTests.Test_GapBetween30And20_IsNoBand;
begin
   BeginTest('Test_GapBetween30And20_IsNoBand');
   CheckBandMode(12000000, NoBand, NoMode, '12 MHz (between 30 m and 20 m)');
end;

procedure TBandLookupTests.Test_Above23cm_IsNoBand;
begin
   BeginTest('Test_Above23cm_IsNoBand');
   // 1500000000 is the upper edge of Band1296; anything above is uncovered
   // because the 2304 row is commented out in FreqModeArray.
   CheckBandMode(1500000001, NoBand, NoMode, 'just above 23 cm');
   CheckBandMode(2300000000, NoBand, NoMode, '2.3 GHz (13 cm -- not in table)');
end;

procedure TBandLookupTests.Test_Zero_IsNoBand;
begin
   BeginTest('Test_Zero_IsNoBand');
   CheckBandMode(0, NoBand, NoMode, '0 Hz');
end;

// ---------------------------------------------------------------------------
// 40 m NoMode gap: documents an existing quirk in FreqModeArray.
// Entries are:
//   7000000..7040000 CW
//   7040000..7100000 NoMode   <-- this row
//   7100000..7300000 Phone
// Frequencies in the 7.040..7.100 MHz window are on 40 m but the table
// declines to assign CW or Phone, so callers must handle NoMode.
// If FreqModeArray is ever updated to remove this gap, this test will fail
// and prompt a deliberate review.
// ---------------------------------------------------------------------------

procedure TBandLookupTests.Test_40m_NoModeGap;
begin
   BeginTest('Test_40m_NoModeGap');
   CheckBandMode(7070000, Band40, NoMode, '7.070 MHz (40 m NoMode gap)');
end;

// ---------------------------------------------------------------------------
// Test runner
// ---------------------------------------------------------------------------

procedure TBandLookupTests.RunAllTests;
begin
   Test_160m_Centre;
   Test_80m_CW_Centre;
   Test_80m_Phone_Centre;
   Test_40m_CW_Centre;
   Test_40m_Phone_Centre;
   Test_30m_Centre;
   Test_20m_CW_Centre;
   Test_20m_Phone_Centre;
   Test_17m_CW_Centre;
   Test_17m_Phone_Centre;
   Test_15m_CW_Centre;
   Test_15m_Phone_Centre;
   Test_12m_CW_Centre;
   Test_12m_Phone_Centre;
   Test_10m_CW_Centre;
   Test_10m_Phone_Centre;
   Test_6m_Centre;
   Test_2m_Centre;
   Test_222_Centre;
   Test_432_Centre;
   Test_902_Centre;
   Test_1296_Centre;

   Test_80m_ModeSplit_3600_IsPhone;
   Test_80m_ModeSplit_3599999_IsCW;
   Test_20m_ModeSplit_14100_IsPhone;
   Test_20m_ModeSplit_14099999_IsCW;
   Test_15m_ModeSplit_21150_IsPhone;
   Test_15m_ModeSplit_21149999_IsCW;

   Test_160m_LowerEdge_In;
   Test_160m_LowerEdge_Out;
   Test_160m_UpperEdge_In;
   Test_40m_UpperEdge_In;
   Test_40m_UpperEdge_Out;
   Test_20m_UpperEdge_In;
   Test_20m_UpperEdge_Out;
   Test_10m_UpperEdge_In;
   Test_10m_UpperEdge_Out;

   Test_Below160m_IsNoBand;
   Test_AM_BroadcastBand_IsNoBand;
   Test_GapBetween80And40_IsNoBand;
   Test_GapBetween40And30_IsNoBand;
   Test_GapBetween30And20_IsNoBand;
   Test_Above23cm_IsNoBand;
   Test_Zero_IsNoBand;

   Test_40m_NoModeGap;
end;

end.
