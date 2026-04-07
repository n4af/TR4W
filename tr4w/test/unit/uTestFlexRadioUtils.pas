unit uTestFlexRadioUtils;

{
  Unit tests for uFlexRadioUtils — pure SmartSDR protocol utility functions.

  Covers:
    FlexParseKeyValue:
      - Normal key in middle of payload
      - Key at start of payload (no leading space in raw string)
      - Key at end of payload (no trailing space)
      - Key not present -> returns ''
      - Word-boundary safety: 'tx' must not match inside 'retx=0'
      - Key whose value contains no spaces (last token)
      - Empty payload

    FlexFormatFreqMHz:
      - Whole-MHz frequency (trailing zeros in fraction)
      - Fractional frequency, all 6 digits significant
      - Sub-MHz fraction that needs leading zeros (e.g. 7001000 -> '7.001000')
      - 160m (1.8 MHz)
      - 6m (50 MHz)
      - 1296 MHz (microwave, verifies large values)
      - The specific frequency 14.194900 MHz used in split tests
}

interface

uses
   SysUtils, uTR4WTestFramework, uFlexRadioUtils;

type
   TFlexRadioUtilsTests = class(TTestCase)
   protected
      // FlexParseKeyValue
      procedure Test_ParseKV_KeyInMiddle;
      procedure Test_ParseKV_KeyAtStart;
      procedure Test_ParseKV_KeyAtEnd;
      procedure Test_ParseKV_KeyNotFound;
      procedure Test_ParseKV_WordBoundary_SuffixMatch;
      procedure Test_ParseKV_SingleToken;
      procedure Test_ParseKV_EmptyPayload;
      procedure Test_ParseKV_RFFrequency;

      // FlexFormatFreqMHz
      procedure Test_FormatFreq_14MHz_Whole;
      procedure Test_FormatFreq_14200000;
      procedure Test_FormatFreq_14194900;
      procedure Test_FormatFreq_7MHz_Whole;
      procedure Test_FormatFreq_LeadingZeroFraction;
      procedure Test_FormatFreq_160m;
      procedure Test_FormatFreq_6m;
      procedure Test_FormatFreq_1296MHz;
      procedure Test_FormatFreq_AllSixDigits;

   public
      procedure RunAllTests; override;
   end;

implementation

// ---------------------------------------------------------------------------
// FlexParseKeyValue tests
// ---------------------------------------------------------------------------

procedure TFlexRadioUtilsTests.Test_ParseKV_KeyInMiddle;
begin
   BeginTest('ParseKV: key in middle of payload');
   CheckEquals('USB',
      FlexParseKeyValue('RF_frequency=14.200000 mode=USB tx=1', 'mode'));
end;

procedure TFlexRadioUtilsTests.Test_ParseKV_KeyAtStart;
begin
   BeginTest('ParseKV: key at start of payload');
   CheckEquals('14.200000',
      FlexParseKeyValue('RF_frequency=14.200000 mode=USB tx=1', 'RF_frequency'));
end;

procedure TFlexRadioUtilsTests.Test_ParseKV_KeyAtEnd;
begin
   BeginTest('ParseKV: key at end of payload (no trailing space)');
   CheckEquals('1',
      FlexParseKeyValue('RF_frequency=14.200000 mode=USB tx=1', 'tx'));
end;

procedure TFlexRadioUtilsTests.Test_ParseKV_KeyNotFound;
begin
   BeginTest('ParseKV: key not present returns empty string');
   CheckEquals('',
      FlexParseKeyValue('RF_frequency=14.200000 mode=USB tx=1', 'rit_on'));
end;

procedure TFlexRadioUtilsTests.Test_ParseKV_WordBoundary_SuffixMatch;
begin
   // 'tx=' must not match inside 'retx=0'; correct answer is '1'
   BeginTest('ParseKV: word-boundary — tx must not match inside retx');
   CheckEquals('1',
      FlexParseKeyValue('retx=0 tx=1', 'tx'));
end;

procedure TFlexRadioUtilsTests.Test_ParseKV_SingleToken;
begin
   BeginTest('ParseKV: single key=value payload');
   CheckEquals('1',
      FlexParseKeyValue('in_use=1', 'in_use'));
end;

procedure TFlexRadioUtilsTests.Test_ParseKV_EmptyPayload;
begin
   BeginTest('ParseKV: empty payload returns empty string');
   CheckEquals('',
      FlexParseKeyValue('', 'mode'));
end;

procedure TFlexRadioUtilsTests.Test_ParseKV_RFFrequency;
begin
   // Real SmartSDR transmit push
   BeginTest('ParseKV: freq from transmit status push');
   CheckEquals('14.194900',
      FlexParseKeyValue('freq=14.194900 lo_freq=0.000000 hi_freq=0.000000', 'freq'));
end;

// ---------------------------------------------------------------------------
// FlexFormatFreqMHz tests
// ---------------------------------------------------------------------------

procedure TFlexRadioUtilsTests.Test_FormatFreq_14MHz_Whole;
begin
   BeginTest('FormatFreq: 14000000 Hz -> 14.000000');
   CheckEquals('14.000000', FlexFormatFreqMHz(14000000));
end;

procedure TFlexRadioUtilsTests.Test_FormatFreq_14200000;
begin
   BeginTest('FormatFreq: 14200000 Hz -> 14.200000');
   CheckEquals('14.200000', FlexFormatFreqMHz(14200000));
end;

procedure TFlexRadioUtilsTests.Test_FormatFreq_14194900;
begin
   BeginTest('FormatFreq: 14194900 Hz -> 14.194900 (split test freq)');
   CheckEquals('14.194900', FlexFormatFreqMHz(14194900));
end;

procedure TFlexRadioUtilsTests.Test_FormatFreq_7MHz_Whole;
begin
   BeginTest('FormatFreq: 7000000 Hz -> 7.000000');
   CheckEquals('7.000000', FlexFormatFreqMHz(7000000));
end;

procedure TFlexRadioUtilsTests.Test_FormatFreq_LeadingZeroFraction;
begin
   // 7001000 Hz = 7 MHz + 1000 Hz = 7.001000
   BeginTest('FormatFreq: 7001000 Hz -> 7.001000 (leading zeros in fraction)');
   CheckEquals('7.001000', FlexFormatFreqMHz(7001000));
end;

procedure TFlexRadioUtilsTests.Test_FormatFreq_160m;
begin
   BeginTest('FormatFreq: 1800000 Hz -> 1.800000 (160m)');
   CheckEquals('1.800000', FlexFormatFreqMHz(1800000));
end;

procedure TFlexRadioUtilsTests.Test_FormatFreq_6m;
begin
   BeginTest('FormatFreq: 50125000 Hz -> 50.125000 (6m)');
   CheckEquals('50.125000', FlexFormatFreqMHz(50125000));
end;

procedure TFlexRadioUtilsTests.Test_FormatFreq_1296MHz;
begin
   BeginTest('FormatFreq: 1296000000 Hz -> 1296.000000 (23cm)');
   CheckEquals('1296.000000', FlexFormatFreqMHz(1296000000));
end;

procedure TFlexRadioUtilsTests.Test_FormatFreq_AllSixDigits;
begin
   // 14356789 Hz = 14 MHz + 356789 Hz
   BeginTest('FormatFreq: 14356789 Hz -> 14.356789 (all 6 digits significant)');
   CheckEquals('14.356789', FlexFormatFreqMHz(14356789));
end;

// ---------------------------------------------------------------------------
// RunAllTests
// ---------------------------------------------------------------------------

procedure TFlexRadioUtilsTests.RunAllTests;
begin
   // ParseKeyValue
   Test_ParseKV_KeyInMiddle;
   Test_ParseKV_KeyAtStart;
   Test_ParseKV_KeyAtEnd;
   Test_ParseKV_KeyNotFound;
   Test_ParseKV_WordBoundary_SuffixMatch;
   Test_ParseKV_SingleToken;
   Test_ParseKV_EmptyPayload;
   Test_ParseKV_RFFrequency;

   // FlexFormatFreqMHz
   Test_FormatFreq_14MHz_Whole;
   Test_FormatFreq_14200000;
   Test_FormatFreq_14194900;
   Test_FormatFreq_7MHz_Whole;
   Test_FormatFreq_LeadingZeroFraction;
   Test_FormatFreq_160m;
   Test_FormatFreq_6m;
   Test_FormatFreq_1296MHz;
   Test_FormatFreq_AllSixDigits;
end;

end.
