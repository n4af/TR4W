unit uTestCRC32;

{
  Unit tests for uCRC32.GetCRC32.

  uCRC32 implements the standard CRC-32 (polynomial $EDB88320, initial
  $FFFFFFFF, output one's-complemented).  This is the same CRC used by
  PKZIP, Ethernet (IEEE 802.3), ITU-T V.42, PNG, and gzip.  It is also
  what TR4WServer uses for log/packet integrity, so a regression here
  would silently corrupt multi-op log synchronization.

  The implementation is hand-written x86 inline assembly (Crc32Next,
  Crc32Done, Crc32Initialization).  Phase 3 will need to replace those
  asm blocks with Pascal; these tests freeze the D7 behavior bit-exactly
  so the rewrite is provably equivalent.

  Reference vectors are from the published CRC-32 test suite -- see
  https://reveng.sourceforge.io/crc-catalogue/all.htm ("CRC-32/ISO-HDLC")
  and the standard "check" value for "123456789".
}

interface

uses
   SysUtils, uTR4WTestFramework, uCRC32;

type
   TCRC32Tests = class(TTestCase)
   protected
      // Internal helper: assertion with hex formatting.  LongWord values
      // cast to Integer wrap negative for the high half, which produces
      // unreadable "Expected -876016858 got -876016858" messages; hex
      // makes failures investigable.
      procedure CheckCRC(const data; count: LongWord;
                         expected: LongWord; const ctx: string);

      // Reference-vector tests
      procedure Test_EmptyInput_IsZero;
      procedure Test_Standard_Check_123456789;
      procedure Test_SingleByte_a;
      procedure Test_Three_abc;
      procedure Test_QuickBrownFox;

      // Edge / boundary
      procedure Test_SingleZeroByte;
      procedure Test_AllFFsOneByte;
      procedure Test_LongerInput_PreservesAlgorithm;

   public
      procedure RunAllTests; override;
   end;

implementation

// ---------------------------------------------------------------------------
// Helper: format LongWord as 8-hex-digit uppercase for readable failures.
// ---------------------------------------------------------------------------
function HexLW(v: LongWord): string;
begin
   Result := '$' + IntToHex(Integer(v), 8);
end;

procedure TCRC32Tests.CheckCRC(const data; count: LongWord;
                              expected: LongWord; const ctx: string);
var
   actual: LongWord;
   msg: string;
begin
   actual := GetCRC32(data, count);
   if actual = expected then
      begin
      // Reuse the framework's pass path via a true Check
      Check(True, '');
      end
   else
      begin
      msg := Format('%s: expected %s, got %s', [ctx, HexLW(expected), HexLW(actual)]);
      Check(False, msg);
      end;
end;

// ---------------------------------------------------------------------------
// Reference vectors
// ---------------------------------------------------------------------------

procedure TCRC32Tests.Test_EmptyInput_IsZero;
var
   dummy: Byte;
begin
   BeginTest('Test_EmptyInput_IsZero');
   // CRC32("") = 0.  Algorithm short-circuits when Count = 0; the input
   // buffer is unread, so we pass any valid memory for `data`.
   dummy := 0;
   CheckCRC(dummy, 0, $00000000, 'empty input');
end;

procedure TCRC32Tests.Test_Standard_Check_123456789;
var
   s: AnsiString;
begin
   BeginTest('Test_Standard_Check_123456789');
   // The published "check" value for CRC-32/ISO-HDLC.  Every conforming
   // CRC-32 implementation MUST return $CBF43926 for the ASCII string
   // "123456789".  If this ever fails, the algorithm is wrong.
   s := '123456789';
   CheckCRC(s[1], Length(s), $CBF43926, 'CRC32("123456789")');
end;

procedure TCRC32Tests.Test_SingleByte_a;
var
   s: AnsiString;
begin
   BeginTest('Test_SingleByte_a');
   s := 'a';
   CheckCRC(s[1], Length(s), $E8B7BE43, 'CRC32("a")');
end;

procedure TCRC32Tests.Test_Three_abc;
var
   s: AnsiString;
begin
   BeginTest('Test_Three_abc');
   s := 'abc';
   CheckCRC(s[1], Length(s), $352441C2, 'CRC32("abc")');
end;

procedure TCRC32Tests.Test_QuickBrownFox;
var
   s: AnsiString;
begin
   BeginTest('Test_QuickBrownFox');
   // The canonical 43-byte test sentence -- multiple full passes through
   // the inner loop, exercises the asm path with realistic input.
   s := 'The quick brown fox jumps over the lazy dog';
   CheckCRC(s[1], Length(s), $414FA339, 'CRC32("The quick brown fox...")');
end;

// ---------------------------------------------------------------------------
// Edge / boundary
// ---------------------------------------------------------------------------

procedure TCRC32Tests.Test_SingleZeroByte;
var
   b: Byte;
begin
   BeginTest('Test_SingleZeroByte');
   // CRC32 of a single $00 byte -- ensures the algorithm produces a
   // non-zero result for non-empty input even when every byte is zero.
   b := $00;
   CheckCRC(b, 1, $D202EF8D, 'CRC32(<$00>)');
end;

procedure TCRC32Tests.Test_AllFFsOneByte;
var
   b: Byte;
begin
   BeginTest('Test_AllFFsOneByte');
   // CRC32 of a single $FF byte.
   b := $FF;
   CheckCRC(b, 1, $FF000000, 'CRC32(<$FF>)');
end;

procedure TCRC32Tests.Test_LongerInput_PreservesAlgorithm;
var
   s: AnsiString;
   i: Integer;
begin
   BeginTest('Test_LongerInput_PreservesAlgorithm');
   // 256-byte input ensures the inner loop iterates many times, and
   // the table-driven step at each byte position is correct across
   // a full byte's worth of distinct values.  CRC32 of bytes 0..255
   // in order.
   SetLength(s, 256);
   for i := 1 to 256 do
      begin
      s[i] := AnsiChar(i - 1);
      end;
   CheckCRC(s[1], 256, $29058C73, 'CRC32(0x00..0xFF)');
end;

// ---------------------------------------------------------------------------
// Test runner
// ---------------------------------------------------------------------------

procedure TCRC32Tests.RunAllTests;
begin
   Test_EmptyInput_IsZero;
   Test_Standard_Check_123456789;
   Test_SingleByte_a;
   Test_Three_abc;
   Test_QuickBrownFox;
   Test_SingleZeroByte;
   Test_AllFFsOneByte;
   Test_LongerInput_PreservesAlgorithm;
end;

end.
