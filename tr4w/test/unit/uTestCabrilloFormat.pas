unit uTestCabrilloFormat;

{
  Unit tests for uCabrilloFormat.FormatCabrilloFreq and FormatCabrilloMode.

  Extracted from PostUnit.tGenerateLogPortionOfCabrilloFile.  The two
  helpers are stateless and contest-correctness-critical: they decide
  what goes in the freq and mode columns of every Cabrillo log line.

  Reference: https://wwrof.org/cabrillo/cabrillo-qso-data/

  Coverage:
    FormatCabrilloFreq
      - showFreqInLog = False: always returns the band default per
        tCabrilloFreqString (Cabrillo spec: caller may suppress real freq)
      - showFreqInLog = True, freqHz = 0: returns the band default
      - showFreqInLog = True, 0 < freqHz < 30 MHz: returns kHz integer
      - showFreqInLog = True, freqHz >= 30 MHz: returns the band default
        (Cabrillo spec: above 30 MHz the actual freq is not used)
      - Band defaults match the published Cabrillo per-band frequency labels

    FormatCabrilloMode
      - mode = CW: returns 'CW'
      - mode = Phone: returns 'PH'
      - mode = Digital + extMode = eRTTY/eNoMode: returns 'RY'
      - mode = Digital + any other extMode: returns 'DG'
      - mode = FM, modeOverridesToPhone = True: returns 'PH' (Winter Field Day)
      - mode = FM, modeOverridesToPhone = False: returns 'FM'

  Pre-migration regression net: these tests must pass identically on
  Delphi 7 today and on Delphi 12 after the migration.
}

interface

uses
   SysUtils, uTR4WTestFramework, VC, uCabrilloFormat;

type
   TCabrilloFormatTests = class(TTestCase)
   protected
      // FormatCabrilloFreq -- showFreqInLog branches
      procedure Test_Freq_ShowFalse_AlwaysBandDefault;
      procedure Test_Freq_ShowTrue_ZeroFreq_BandDefault;
      procedure Test_Freq_ShowTrue_HFFreq_ReturnsKHz;
      procedure Test_Freq_ShowTrue_Above30MHz_BandDefault;
      procedure Test_Freq_ShowTrue_Exactly30MHz_BandDefault;

      // FormatCabrilloFreq -- band default spot checks
      procedure Test_Freq_BandDefault_160m;
      procedure Test_Freq_BandDefault_20m;
      procedure Test_Freq_BandDefault_6m;
      procedure Test_Freq_BandDefault_2m;
      procedure Test_Freq_BandDefault_1296;
      procedure Test_Freq_BandDefault_24GHz;
      procedure Test_Freq_BandDefault_Light;

      // FormatCabrilloMode -- per-mode branches
      procedure Test_Mode_CW;
      procedure Test_Mode_Phone;
      procedure Test_Mode_FM_NoOverride;
      procedure Test_Mode_FM_OverrideToPhone;
      procedure Test_Mode_Digital_RTTY_IsRY;
      procedure Test_Mode_Digital_NoMode_IsRY;
      procedure Test_Mode_Digital_FT8_IsDG;
      procedure Test_Mode_Digital_PSK_IsDG;
      procedure Test_Mode_Digital_JT65_IsDG;

   public
      procedure RunAllTests; override;
   end;

implementation

// ---------------------------------------------------------------------------
// FormatCabrilloFreq -- showFreqInLog branches
// ---------------------------------------------------------------------------

procedure TCabrilloFormatTests.Test_Freq_ShowFalse_AlwaysBandDefault;
begin
   BeginTest('Test_Freq_ShowFalse_AlwaysBandDefault');
   // Caller has tShowFrequencyInLog = False -- regardless of freqHz, we get
   // the per-band Cabrillo default string.
   CheckEquals('14000', string(FormatCabrilloFreq(Band20, 14250000, False)),
               '20m + real freq + showFalse');
   CheckEquals('14000', string(FormatCabrilloFreq(Band20, 0, False)),
               '20m + zero freq + showFalse');
end;

procedure TCabrilloFormatTests.Test_Freq_ShowTrue_ZeroFreq_BandDefault;
begin
   BeginTest('Test_Freq_ShowTrue_ZeroFreq_BandDefault');
   // freqHz = 0 means "no logged frequency"; fall back to band default.
   CheckEquals('14000', string(FormatCabrilloFreq(Band20, 0, True)), 'zero freq');
end;

procedure TCabrilloFormatTests.Test_Freq_ShowTrue_HFFreq_ReturnsKHz;
begin
   BeginTest('Test_Freq_ShowTrue_HFFreq_ReturnsKHz');
   // 0 < freqHz < 30 MHz -- return freqHz / 1000 (kHz integer).
   CheckEquals('14025',  string(FormatCabrilloFreq(Band20, 14025000, True)), '20m CW');
   CheckEquals('14250',  string(FormatCabrilloFreq(Band20, 14250000, True)), '20m Phone');
   CheckEquals('1825',   string(FormatCabrilloFreq(Band160, 1825000, True)), '160m');
   CheckEquals('7042',   string(FormatCabrilloFreq(Band40, 7042000, True)), '40m');
end;

procedure TCabrilloFormatTests.Test_Freq_ShowTrue_Above30MHz_BandDefault;
begin
   BeginTest('Test_Freq_ShowTrue_Above30MHz_BandDefault');
   // Per Cabrillo spec: above 30 MHz, use band default string, not the
   // actual frequency.  Verify with a 6 m and 2 m QSO.
   CheckEquals('50',  string(FormatCabrilloFreq(Band6, 50125000, True)),  '6m above-30 fallback');
   CheckEquals('144', string(FormatCabrilloFreq(Band2, 146000000, True)), '2m above-30 fallback');
end;

procedure TCabrilloFormatTests.Test_Freq_ShowTrue_Exactly30MHz_BandDefault;
begin
   BeginTest('Test_Freq_ShowTrue_Exactly30MHz_BandDefault');
   // The boundary is strict less-than 30 MHz in the original (Frequency < 30000000).
   // 30 MHz exactly should fall into the band-default branch.
   CheckEquals('28000', string(FormatCabrilloFreq(Band10, 30000000, True)),
               '30.000000 MHz exactly -- band default');
end;

// ---------------------------------------------------------------------------
// FormatCabrilloFreq -- band default spot checks
// (Verifies the tCabrilloFreqString array values match the spec.)
// ---------------------------------------------------------------------------

procedure TCabrilloFormatTests.Test_Freq_BandDefault_160m;
begin
   BeginTest('Test_Freq_BandDefault_160m');
   CheckEquals('1800', string(FormatCabrilloFreq(Band160, 0, True)), '');
end;

procedure TCabrilloFormatTests.Test_Freq_BandDefault_20m;
begin
   BeginTest('Test_Freq_BandDefault_20m');
   CheckEquals('14000', string(FormatCabrilloFreq(Band20, 0, True)), '');
end;

procedure TCabrilloFormatTests.Test_Freq_BandDefault_6m;
begin
   BeginTest('Test_Freq_BandDefault_6m');
   CheckEquals('50', string(FormatCabrilloFreq(Band6, 0, True)), '');
end;

procedure TCabrilloFormatTests.Test_Freq_BandDefault_2m;
begin
   BeginTest('Test_Freq_BandDefault_2m');
   CheckEquals('144', string(FormatCabrilloFreq(Band2, 0, True)), '');
end;

procedure TCabrilloFormatTests.Test_Freq_BandDefault_1296;
begin
   BeginTest('Test_Freq_BandDefault_1296');
   CheckEquals('1.2G', string(FormatCabrilloFreq(Band1296, 0, True)), '');
end;

procedure TCabrilloFormatTests.Test_Freq_BandDefault_24GHz;
begin
   BeginTest('Test_Freq_BandDefault_24GHz');
   CheckEquals('24G', string(FormatCabrilloFreq(Band24G, 0, True)), '');
end;

procedure TCabrilloFormatTests.Test_Freq_BandDefault_Light;
begin
   BeginTest('Test_Freq_BandDefault_Light');
   CheckEquals('LIGHT', string(FormatCabrilloFreq(BandLight, 0, True)), '');
end;

// ---------------------------------------------------------------------------
// FormatCabrilloMode
// ---------------------------------------------------------------------------

procedure TCabrilloFormatTests.Test_Mode_CW;
begin
   BeginTest('Test_Mode_CW');
   CheckEquals('CW', string(FormatCabrilloMode(CW, eNoMode, False)), '');
end;

procedure TCabrilloFormatTests.Test_Mode_Phone;
begin
   BeginTest('Test_Mode_Phone');
   CheckEquals('PH', string(FormatCabrilloMode(Phone, eNoMode, False)), '');
end;

procedure TCabrilloFormatTests.Test_Mode_FM_NoOverride;
begin
   BeginTest('Test_Mode_FM_NoOverride');
   // FM contest in a non-WFD contest -- Cabrillo column = 'FM'
   CheckEquals('FM', string(FormatCabrilloMode(FM, eNoMode, False)), '');
end;

procedure TCabrilloFormatTests.Test_Mode_FM_OverrideToPhone;
begin
   BeginTest('Test_Mode_FM_OverrideToPhone');
   // Winter Field Day flag overrides FM to PH per its scoring rules.
   CheckEquals('PH', string(FormatCabrilloMode(FM, eNoMode, True)), '');
end;

procedure TCabrilloFormatTests.Test_Mode_Digital_RTTY_IsRY;
begin
   BeginTest('Test_Mode_Digital_RTTY_IsRY');
   CheckEquals('RY', string(FormatCabrilloMode(Digital, eRTTY, False)), '');
end;

procedure TCabrilloFormatTests.Test_Mode_Digital_NoMode_IsRY;
begin
   BeginTest('Test_Mode_Digital_NoMode_IsRY');
   // Pre-WSJT-X-era digital QSO with no explicit submode -- treated as RTTY.
   CheckEquals('RY', string(FormatCabrilloMode(Digital, eNoMode, False)), '');
end;

procedure TCabrilloFormatTests.Test_Mode_Digital_FT8_IsDG;
begin
   BeginTest('Test_Mode_Digital_FT8_IsDG');
   // FT8 was historically logged as RY which mislabelled it on most
   // contest aggregators.  The bug fix made all non-RTTY digital QSOs
   // log as 'DG' per the modern Cabrillo spec.
   CheckEquals('DG', string(FormatCabrilloMode(Digital, eFT8, False)), '');
end;

procedure TCabrilloFormatTests.Test_Mode_Digital_PSK_IsDG;
begin
   BeginTest('Test_Mode_Digital_PSK_IsDG');
   CheckEquals('DG', string(FormatCabrilloMode(Digital, ePSK31, False)), '');
end;

procedure TCabrilloFormatTests.Test_Mode_Digital_JT65_IsDG;
begin
   BeginTest('Test_Mode_Digital_JT65_IsDG');
   CheckEquals('DG', string(FormatCabrilloMode(Digital, eJT65, False)), '');
end;

// ---------------------------------------------------------------------------
// Test runner
// ---------------------------------------------------------------------------

procedure TCabrilloFormatTests.RunAllTests;
begin
   Test_Freq_ShowFalse_AlwaysBandDefault;
   Test_Freq_ShowTrue_ZeroFreq_BandDefault;
   Test_Freq_ShowTrue_HFFreq_ReturnsKHz;
   Test_Freq_ShowTrue_Above30MHz_BandDefault;
   Test_Freq_ShowTrue_Exactly30MHz_BandDefault;

   Test_Freq_BandDefault_160m;
   Test_Freq_BandDefault_20m;
   Test_Freq_BandDefault_6m;
   Test_Freq_BandDefault_2m;
   Test_Freq_BandDefault_1296;
   Test_Freq_BandDefault_24GHz;
   Test_Freq_BandDefault_Light;

   Test_Mode_CW;
   Test_Mode_Phone;
   Test_Mode_FM_NoOverride;
   Test_Mode_FM_OverrideToPhone;
   Test_Mode_Digital_RTTY_IsRY;
   Test_Mode_Digital_NoMode_IsRY;
   Test_Mode_Digital_FT8_IsDG;
   Test_Mode_Digital_PSK_IsDG;
   Test_Mode_Digital_JT65_IsDG;
end;

end.
