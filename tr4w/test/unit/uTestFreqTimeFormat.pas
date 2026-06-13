unit uTestFreqTimeFormat;

{
  Golden-master tests for uFreqTimeFormat (frequency & time formatters extracted
  from TF.pas, Issue #997 / migration Tier-1).

  WHY: each formatter used inline x86 asm (manual cdecl varargs push into
  wsprintf) plus some embedded integer math (idiv).  Phase 3 (64-bit) cannot keep
  inline asm, and these run on the hot path (frequency display).  These tests
  freeze the EXACT string output of the D7 asm path so the asm->Format rewrite is
  proven byte-identical, not "looks the same".

  Procedure: the expected values below were locked against the original asm build
  first; the conversion must reproduce them exactly.
}

interface

uses
   SysUtils, Windows, uTR4WTestFramework, uFreqTimeFormat;

type
   TFreqTimeFormatTests = class(TTestCase)
   protected
      procedure Test_FreqToPChar;
      procedure Test_FreqToPCharWithoutHZ;
      procedure Test_kHzToPChar;
      procedure Test_Milliseconds_NoMsec;
      procedure Test_Milliseconds_WithMsec;
      procedure Test_SystemTimeToString;
   public
      procedure RunAllTests; override;
   end;

implementation

function ST(y, mo, d, h, mi, s: Word): SYSTEMTIME;
begin
   FillChar(Result, SizeOf(Result), 0);
   Result.wYear   := y;
   Result.wMonth  := mo;
   Result.wDay    := d;
   Result.wHour   := h;
   Result.wMinute := mi;
   Result.wSecond := s;
end;

// FreqToPChar(i) = '%u.%02u' of (i div 1000, (i mod 1000) div 10)
procedure TFreqTimeFormatTests.Test_FreqToPChar;
begin
   BeginTest('Test_FreqToPChar');
   CheckEquals('',         string(FreqToPChar(0)),        'FreqToPChar(0) returns nil/empty');
   CheckEquals('14250.00', string(FreqToPChar(14250000)), 'FreqToPChar(14250000)');
   CheckEquals('14250.12', string(FreqToPChar(14250125)), 'FreqToPChar(14250125)');
   CheckEquals('7000.00',  string(FreqToPChar(7000000)),  'FreqToPChar(7000000)');
   CheckEquals('0.99',     string(FreqToPChar(999)),      'FreqToPChar(999)');
   CheckEquals('1.00',     string(FreqToPChar(1000)),     'FreqToPChar(1000)');
   CheckEquals('0.00',     string(FreqToPChar(1)),        'FreqToPChar(1)');
   CheckEquals('28499.99', string(FreqToPChar(28499990)), 'FreqToPChar(28499990)');
end;

// FreqToPCharWithoutHZ(i) = '%6u' of (i div 1000)  [space-padded, width 6]
procedure TFreqTimeFormatTests.Test_FreqToPCharWithoutHZ;
begin
   BeginTest('Test_FreqToPCharWithoutHZ');
   CheckEquals('',        string(FreqToPCharWithoutHZ(0)),         'FreqToPCharWithoutHZ(0) nil');
   CheckEquals(' 14250',  string(FreqToPCharWithoutHZ(14250000)),  'FreqToPCharWithoutHZ(14250000)');
   CheckEquals('  7000',  string(FreqToPCharWithoutHZ(7000000)),   'FreqToPCharWithoutHZ(7000000)');
   CheckEquals('     1',  string(FreqToPCharWithoutHZ(1000)),      'FreqToPCharWithoutHZ(1000)');
   CheckEquals('146520',  string(FreqToPCharWithoutHZ(146520000)), 'FreqToPCharWithoutHZ(146520000)');
   CheckEquals('     0',  string(FreqToPCharWithoutHZ(1)),         'FreqToPCharWithoutHZ(1)');
end;

// kHzToPChar(Freq) = '%6u' of Freq (Word)
procedure TFreqTimeFormatTests.Test_kHzToPChar;
begin
   BeginTest('Test_kHzToPChar');
   CheckEquals('     0',  string(kHzToPChar(0)),     'kHzToPChar(0)');
   CheckEquals(' 14250',  string(kHzToPChar(14250)), 'kHzToPChar(14250)');
   CheckEquals('  7000',  string(kHzToPChar(7000)),  'kHzToPChar(7000)');
   CheckEquals(' 65535',  string(kHzToPChar(65535)), 'kHzToPChar(65535)');
   CheckEquals('   146',  string(kHzToPChar(146)),   'kHzToPChar(146)');
end;

// MillisecondsToFormattedString(ms, False) = '%.2hu:%.2hu:%.2hu' (HH:MM:SS)
procedure TFreqTimeFormatTests.Test_Milliseconds_NoMsec;
begin
   BeginTest('Test_Milliseconds_NoMsec');
   CheckEquals('00:00:00', string(MillisecondsToFormattedString(0, False)),        'msec 0');
   CheckEquals('01:01:01', string(MillisecondsToFormattedString(3661000, False)),  'msec 1h1m1s');
   CheckEquals('23:59:59', string(MillisecondsToFormattedString(86399000, False)), 'msec 23h59m59s');
   CheckEquals('25:01:01', string(MillisecondsToFormattedString(90061000, False)), 'msec 25h1m1s (>24h)');
end;

// MillisecondsToFormattedString(ms, True) = '%.2hu:%.2hu:%.2hu:%.3hu' (HH:MM:SS:mmm)
procedure TFreqTimeFormatTests.Test_Milliseconds_WithMsec;
begin
   BeginTest('Test_Milliseconds_WithMsec');
   CheckEquals('00:00:00:000', string(MillisecondsToFormattedString(0, True)),       'msec 0 +ms');
   CheckEquals('01:01:01:123', string(MillisecondsToFormattedString(3661123, True)), 'msec 1h1m1s123 +ms');
   CheckEquals('00:00:01:500', string(MillisecondsToFormattedString(1500, True)),    'msec 1500 +ms');
   CheckEquals('00:00:00:999', string(MillisecondsToFormattedString(999, True)),     'msec 999 +ms');
end;

// SystemTimeToString = '%.2hu-%.2hu-%.2hu %.2hu:%.2hu:%.2hu'
//   (wYear, wMonth, wDay, wHour, wMinute, wSecond)
procedure TFreqTimeFormatTests.Test_SystemTimeToString;
begin
   BeginTest('Test_SystemTimeToString');
   CheckEquals('2026-06-13 14:05:09', string(SystemTimeToString(ST(2026, 6, 13, 14, 5, 9))),  'STTS normal');
   CheckEquals('1999-12-31 23:59:59', string(SystemTimeToString(ST(1999, 12, 31, 23, 59, 59))),'STTS year-end');
   CheckEquals('2000-01-01 00:00:00', string(SystemTimeToString(ST(2000, 1, 1, 0, 0, 0))),     'STTS midnight');
   CheckEquals('05-03-07 09:08:04',   string(SystemTimeToString(ST(5, 3, 7, 9, 8, 4))),        'STTS low values');
end;

procedure TFreqTimeFormatTests.RunAllTests;
begin
   Test_FreqToPChar;
   Test_FreqToPCharWithoutHZ;
   Test_kHzToPChar;
   Test_Milliseconds_NoMsec;
   Test_Milliseconds_WithMsec;
   Test_SystemTimeToString;
end;

end.
