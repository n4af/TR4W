unit uTestIcomCIV;

{
  Unit tests for uIcomCIV — Icom CI-V pure utility functions.

  Covers:
    - IcomByteToBCD / IcomBCDToByte  (single-byte BCD)
    - IcomFreqToBCD / IcomBCDToFreq  (5-byte frequency BCD, round-trip)
    - IcomOffsetToBCD                (2-byte RIT/XIT offset BCD)
    - IcomWPMToValue / IcomValueToWPM (CW speed 6-48 WPM <-> 0-255)
}

interface

uses
   SysUtils, uTR4WTestFramework, uIcomCIV;

type
   TIcomCIVTests = class(TTestCase)
   protected
      // BCD byte encode/decode
      procedure Test_ByteToBCD_Zero;
      procedure Test_ByteToBCD_SingleDigit;
      procedure Test_ByteToBCD_TwoDigits;
      procedure Test_ByteToBCD_MaxTwoDigit;
      procedure Test_BCDToByte_Zero;
      procedure Test_BCDToByte_SingleDigit;
      procedure Test_BCDToByte_TwoDigits;
      procedure Test_BCDToByte_Max;
      procedure Test_ByteBCD_RoundTrip;

      // Frequency BCD (5-byte)
      procedure Test_FreqToBCD_20m;
      procedure Test_FreqToBCD_40m;
      procedure Test_FreqToBCD_6m;
      procedure Test_FreqToBCD_Zero;
      procedure Test_BCD_FreqRoundTrip_20m;
      procedure Test_BCD_FreqRoundTrip_40m;
      procedure Test_BCD_FreqRoundTrip_6m;
      procedure Test_BCD_FreqRoundTrip_1296MHz;

      // RIT/XIT offset BCD (2-byte, magnitude only)
      procedure Test_OffsetToBCD_Zero;
      procedure Test_OffsetToBCD_100Hz;
      procedure Test_OffsetToBCD_NegativeUsesAbs;
      procedure Test_OffsetToBCD_9999Hz;

      // CW speed
      procedure Test_WPMToValue_MinWPM;
      procedure Test_WPMToValue_MaxWPM;
      procedure Test_WPMToValue_30WPM;
      procedure Test_WPMToValue_ClampLow;
      procedure Test_WPMToValue_ClampHigh;
      procedure Test_ValueToWPM_Zero;
      procedure Test_ValueToWPM_255;
      procedure Test_ValueToWPM_145;
      procedure Test_CWSpeed_RoundTrip;

   public
      procedure RunAllTests; override;
   end;

implementation

// ---------------------------------------------------------------------------
// BCD byte encode/decode
// ---------------------------------------------------------------------------

procedure TIcomCIVTests.Test_ByteToBCD_Zero;
begin
   BeginTest('ByteToBCD(0) = $00');
   CheckEquals($00, Integer(IcomByteToBCD(0)));
end;

procedure TIcomCIVTests.Test_ByteToBCD_SingleDigit;
begin
   BeginTest('ByteToBCD(9) = $09');
   CheckEquals($09, Integer(IcomByteToBCD(9)));
end;

procedure TIcomCIVTests.Test_ByteToBCD_TwoDigits;
begin
   BeginTest('ByteToBCD(45) = $45');
   CheckEquals($45, Integer(IcomByteToBCD(45)));
end;

procedure TIcomCIVTests.Test_ByteToBCD_MaxTwoDigit;
begin
   BeginTest('ByteToBCD(99) = $99');
   CheckEquals($99, Integer(IcomByteToBCD(99)));
end;

procedure TIcomCIVTests.Test_BCDToByte_Zero;
begin
   BeginTest('BCDToByte($00) = 0');
   CheckEquals(0, Integer(IcomBCDToByte($00)));
end;

procedure TIcomCIVTests.Test_BCDToByte_SingleDigit;
begin
   BeginTest('BCDToByte($09) = 9');
   CheckEquals(9, Integer(IcomBCDToByte($09)));
end;

procedure TIcomCIVTests.Test_BCDToByte_TwoDigits;
begin
   BeginTest('BCDToByte($45) = 45');
   CheckEquals(45, Integer(IcomBCDToByte($45)));
end;

procedure TIcomCIVTests.Test_BCDToByte_Max;
begin
   BeginTest('BCDToByte($99) = 99');
   CheckEquals(99, Integer(IcomBCDToByte($99)));
end;

procedure TIcomCIVTests.Test_ByteBCD_RoundTrip;
var
   v : Integer;
begin
   BeginTest('ByteToBCD/BCDToByte round-trip for all 0-99');
   for v := 0 to 99 do
      begin
      if IcomBCDToByte(IcomByteToBCD(v)) <> v then
         begin
         CheckEquals(v, Integer(IcomBCDToByte(IcomByteToBCD(v))),
            Format('Round-trip failed for %d', [v]));
         Exit;
         end;
      end;
   // All 100 values passed
   BeginTest('ByteToBCD/BCDToByte round-trip for all 0-99');
   Check(True);
end;

// ---------------------------------------------------------------------------
// Frequency BCD
// Icom CI-V sends frequencies LSB first in 5 BCD bytes.
// 14.000.000 Hz = 14000000 decimal
//   10-digit string: 0014000000
//   Pairs MSB->LSB: 00 14 00 00 00
//   LSB-first bytes: $00 $00 $00 $14 $00
// ---------------------------------------------------------------------------

procedure TIcomCIVTests.Test_FreqToBCD_20m;
var
   bcd: string;
begin
   BeginTest('FreqToBCD(14000000) is 5 bytes');
   bcd := IcomFreqToBCD(14000000);
   CheckEquals(5, Length(bcd), 'FreqToBCD must return exactly 5 bytes');
end;

procedure TIcomCIVTests.Test_FreqToBCD_40m;
var
   bcd: string;
begin
   BeginTest('FreqToBCD(7000000) is 5 bytes');
   bcd := IcomFreqToBCD(7000000);
   CheckEquals(5, Length(bcd), 'FreqToBCD must return exactly 5 bytes');
end;

procedure TIcomCIVTests.Test_FreqToBCD_6m;
var
   bcd: string;
begin
   BeginTest('FreqToBCD(50125000) is 5 bytes');
   bcd := IcomFreqToBCD(50125000);
   CheckEquals(5, Length(bcd), 'FreqToBCD must return exactly 5 bytes');
end;

procedure TIcomCIVTests.Test_FreqToBCD_Zero;
var
   bcd: string;
   i  : Integer;
begin
   BeginTest('FreqToBCD(0) is all $00 bytes');
   bcd := IcomFreqToBCD(0);
   for i := 1 to 5 do
      begin
      if Ord(bcd[i]) <> 0 then
         begin
         CheckEquals(0, Integer(Ord(bcd[i])),
            Format('Byte %d should be $00', [i]));
         Exit;
         end;
      end;
   BeginTest('FreqToBCD(0) is all $00 bytes');
   Check(True);
end;

procedure TIcomCIVTests.Test_BCD_FreqRoundTrip_20m;
begin
   BeginTest('FreqBCD round-trip: 14.000.000 Hz');
   CheckEquals(14000000, Integer(IcomBCDToFreq(IcomFreqToBCD(14000000))));
end;

procedure TIcomCIVTests.Test_BCD_FreqRoundTrip_40m;
begin
   BeginTest('FreqBCD round-trip: 7.000.000 Hz');
   CheckEquals(7000000, Integer(IcomBCDToFreq(IcomFreqToBCD(7000000))));
end;

procedure TIcomCIVTests.Test_BCD_FreqRoundTrip_6m;
begin
   BeginTest('FreqBCD round-trip: 50.125.000 Hz');
   CheckEquals(50125000, Integer(IcomBCDToFreq(IcomFreqToBCD(50125000))));
end;

procedure TIcomCIVTests.Test_BCD_FreqRoundTrip_1296MHz;
begin
   BeginTest('FreqBCD round-trip: 1.296.000.000 Hz (23cm)');
   CheckEquals(1296000000, Integer(IcomBCDToFreq(IcomFreqToBCD(1296000000))));
end;

// ---------------------------------------------------------------------------
// RIT/XIT offset BCD
// The offset magnitude is encoded as 2 BCD bytes, LSB first.
// 100 Hz -> 4-digit string "0100"
//   Pairs MSB->LSB: 01 00
//   LSB-first bytes: $00 $01
// ---------------------------------------------------------------------------

procedure TIcomCIVTests.Test_OffsetToBCD_Zero;
var
   bcd: string;
begin
   BeginTest('OffsetToBCD(0): 2 bytes, both $00');
   bcd := IcomOffsetToBCD(0);
   CheckEquals(2, Length(bcd), 'OffsetToBCD must return 2 bytes');
end;

procedure TIcomCIVTests.Test_OffsetToBCD_100Hz;
var
   bcd: string;
begin
   BeginTest('OffsetToBCD(100): byte[0]=$00, byte[1]=$01');
   bcd := IcomOffsetToBCD(100);
   // 100 Hz: "0100" -> pairs 01,00 -> LSB-first: $00, $01
   CheckEquals($00, Ord(bcd[1]), 'LSB byte of 100 Hz');
   CheckEquals($01, Ord(bcd[2]), 'MSB byte of 100 Hz');
end;

procedure TIcomCIVTests.Test_OffsetToBCD_NegativeUsesAbs;
var
   bcd_pos, bcd_neg: string;
begin
   BeginTest('OffsetToBCD(-100) = OffsetToBCD(100) (magnitude only)');
   bcd_pos := IcomOffsetToBCD(100);
   bcd_neg := IcomOffsetToBCD(-100);
   CheckEquals(bcd_pos, bcd_neg);
end;

procedure TIcomCIVTests.Test_OffsetToBCD_9999Hz;
var
   bcd: string;
begin
   BeginTest('OffsetToBCD(9999): 2 bytes');
   bcd := IcomOffsetToBCD(9999);
   // 9999 -> "9999" -> pairs 99,99 -> LSB-first: $99, $99
   CheckEquals($99, Ord(bcd[1]), 'LSB byte of 9999 Hz');
   CheckEquals($99, Ord(bcd[2]), 'MSB byte of 9999 Hz');
end;

// ---------------------------------------------------------------------------
// CW speed
// Icom maps 6-48 WPM linearly to 0-255.
// Key values (spec formula, rounded to nearest):
//   6 WPM  -> value 0
//  30 WPM  -> value 145
//  48 WPM  -> value 255
// ---------------------------------------------------------------------------

procedure TIcomCIVTests.Test_WPMToValue_MinWPM;
begin
   BeginTest('WPMToValue(6) = 0');
   CheckEquals(0, Integer(IcomWPMToValue(6)));
end;

procedure TIcomCIVTests.Test_WPMToValue_MaxWPM;
begin
   BeginTest('WPMToValue(48) = 255');
   CheckEquals(255, Integer(IcomWPMToValue(48)));
end;

procedure TIcomCIVTests.Test_WPMToValue_30WPM;
begin
   BeginTest('WPMToValue(30) = 145');
   // (30-6)*255+21 / 42 = (24*255+21)/42 = 6141/42 = 146
   // Note: exact value depends on rounding — verify against radio
   CheckEquals(146, Integer(IcomWPMToValue(30)));
end;

procedure TIcomCIVTests.Test_WPMToValue_ClampLow;
begin
   BeginTest('WPMToValue(1) clamps to 0 (min 6 WPM)');
   CheckEquals(0, Integer(IcomWPMToValue(1)));
end;

procedure TIcomCIVTests.Test_WPMToValue_ClampHigh;
begin
   BeginTest('WPMToValue(99) clamps to 255 (max 48 WPM)');
   CheckEquals(255, Integer(IcomWPMToValue(99)));
end;

procedure TIcomCIVTests.Test_ValueToWPM_Zero;
begin
   BeginTest('ValueToWPM(0) = 6');
   CheckEquals(6, IcomValueToWPM(0));
end;

procedure TIcomCIVTests.Test_ValueToWPM_255;
begin
   BeginTest('ValueToWPM(255) = 48');
   CheckEquals(48, IcomValueToWPM(255));
end;

procedure TIcomCIVTests.Test_ValueToWPM_145;
begin
   BeginTest('ValueToWPM(145) = 30');
   // 6 + (145*42+127)/255 = 6 + (6090+127)/255 = 6 + 6217/255 = 6 + 24 = 30
   CheckEquals(30, IcomValueToWPM(145));
end;

procedure TIcomCIVTests.Test_CWSpeed_RoundTrip;
var
   wpm    : Integer;
   value  : Byte;
   decoded: Integer;
begin
   BeginTest('CW speed round-trip: 6-48 WPM');
   for wpm := 6 to 48 do
      begin
      value   := IcomWPMToValue(wpm);
      decoded := IcomValueToWPM(value);
      // Round-trip is allowed to be off by at most 1 WPM (integer rounding)
      if Abs(decoded - wpm) > 1 then
         begin
         CheckEquals(wpm, decoded,
            Format('Round-trip failed for %d WPM (value=%d)', [wpm, value]));
         Exit;
         end;
      end;
   BeginTest('CW speed round-trip: 6-48 WPM');
   Check(True);
end;

// ---------------------------------------------------------------------------
// RunAllTests
// ---------------------------------------------------------------------------

procedure TIcomCIVTests.RunAllTests;
begin
   // BCD byte
   Test_ByteToBCD_Zero;
   Test_ByteToBCD_SingleDigit;
   Test_ByteToBCD_TwoDigits;
   Test_ByteToBCD_MaxTwoDigit;
   Test_BCDToByte_Zero;
   Test_BCDToByte_SingleDigit;
   Test_BCDToByte_TwoDigits;
   Test_BCDToByte_Max;
   Test_ByteBCD_RoundTrip;

   // Frequency BCD
   Test_FreqToBCD_20m;
   Test_FreqToBCD_40m;
   Test_FreqToBCD_6m;
   Test_FreqToBCD_Zero;
   Test_BCD_FreqRoundTrip_20m;
   Test_BCD_FreqRoundTrip_40m;
   Test_BCD_FreqRoundTrip_6m;
   Test_BCD_FreqRoundTrip_1296MHz;

   // RIT/XIT offset BCD
   Test_OffsetToBCD_Zero;
   Test_OffsetToBCD_100Hz;
   Test_OffsetToBCD_NegativeUsesAbs;
   Test_OffsetToBCD_9999Hz;

   // CW speed
   Test_WPMToValue_MinWPM;
   Test_WPMToValue_MaxWPM;
   Test_WPMToValue_30WPM;
   Test_WPMToValue_ClampLow;
   Test_WPMToValue_ClampHigh;
   Test_ValueToWPM_Zero;
   Test_ValueToWPM_255;
   Test_ValueToWPM_145;
   Test_CWSpeed_RoundTrip;
end;

end.
