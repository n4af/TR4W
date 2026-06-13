unit uFreqTimeFormat;

{ Issue #997 / migration Tier-1 extraction.

  Pure frequency & time formatters lifted out of TF.pas so they can be
  golden-master tested (uTestFreqTimeFormat) before and after inline-asm removal.
  TF.pas forwards its FreqToPChar / FreqToPCharWithoutHZ / kHzToPChar /
  MillisecondsToFormattedString / SystemTimeToString to these, so existing call
  sites are unchanged.

  The inline x86 asm (manual cdecl varargs push into wsprintf, plus embedded
  idiv) has been replaced with SysUtils.Format; uTestFreqTimeFormat proves the
  output is byte-identical to the original asm path.

  C->Delphi format-spec mapping used here:
    %02u -> %.2u   (zero-pad width 2  ==  min-2-digit precision, for 0..99)
    %6u  -> %6u    (space-pad width 6, unchanged)
    %.2hu/%.3hu -> %.2u/%.3u  (drop the C 'h' short modifier)

  This unit keeps its OWN scratch buffers (TF still has its copies, used by
  RITFreqToPchar / FreqToPChar2). Dependency-light: Windows + SysUtils. }

interface

uses Windows;

function FreqToPChar(i: integer): PChar;
function FreqToPCharWithoutHZ(i: integer): PChar;
function kHzToPChar(Freq: Word): PChar;
function MillisecondsToFormattedString(msecs: Cardinal; WithMsec: boolean): PChar;
function SystemTimeToString(SysTime: SYSTEMTIME): PChar;
function FormatFullTime(Hour, Minute, Second, Milliseconds: Word; WithMilliseconds: boolean): PChar;

implementation

uses SysUtils;

var
  FreqToPCharBuffer        : array[0..15] of Char;
  MillisecondsBuffer       : array[0..31] of Char;
  SystemTimeToStringBuffer : array[0..31] of Char;
  FullTimeBuffer           : array[0..31] of Char;

function FreqToPChar(i: integer): PChar;
var
  hz                                    : integer;
begin
  if i = 0 then
  begin
    Result := nil;
    Exit;
  end;
  hz := (i mod 1000) div 10;
  // Issue #997: asm wsprintf-push -> SysUtils.Format. khz = i div 1000.
  StrPCopy(FreqToPCharBuffer, SysUtils.Format('%u.%.2u', [i div 1000, hz]));
  Result := FreqToPCharBuffer;
end;

function FreqToPCharWithoutHZ(i: integer): PChar;
begin
  if i = 0 then
  begin
    Result := nil;
    Exit;
  end;

  // Issue #997: asm wsprintf-push -> SysUtils.Format. khz = i div 1000.
  StrPCopy(FreqToPCharBuffer, SysUtils.Format('%6u', [i div 1000]));
  Result := FreqToPCharBuffer;
end;

function kHzToPChar(Freq: Word): PChar;
begin
  // Issue #997: asm wsprintf-push -> SysUtils.Format.
  StrPCopy(FreqToPCharBuffer, SysUtils.Format('%6u', [Freq]));
  Result := FreqToPCharBuffer;
end;

function MillisecondsToFormattedString(msecs: Cardinal; WithMsec: boolean): PChar;
var
  Value                                 : Cardinal;
  minuts                                : Word;
  Seconds                               : Word;
  milliseconds                          : Word;
begin
  Value := msecs;

  milliseconds := Value mod 1000;
  Value := Value div 1000;

  Seconds := Value mod 60;
  Value := Value div 60;

  minuts := Value mod 60;
  Value := Value div 60;
  // Issue #997: asm wsprintf-push -> SysUtils.Format. Order HH:MM:SS[:mmm].
  // (Value = hours; a Cardinal msecs caps hours at ~1193, so it always fits the
  // 16-bit truncation the old asm did.)
  if WithMsec then
    StrPCopy(MillisecondsBuffer, SysUtils.Format('%.2u:%.2u:%.2u:%.3u', [Value, minuts, Seconds, milliseconds]))
  else
    StrPCopy(MillisecondsBuffer, SysUtils.Format('%.2u:%.2u:%.2u', [Value, minuts, Seconds]));
  Result := MillisecondsBuffer;
end;

function SystemTimeToString(SysTime: SYSTEMTIME): PChar;
begin
  // Issue #997: asm wsprintf-push -> SysUtils.Format. YYYY-MM-DD HH:MM:SS.
  StrPCopy(SystemTimeToStringBuffer,
    SysUtils.Format('%.2u-%.2u-%.2u %.2u:%.2u:%.2u',
      [SysTime.wYear, SysTime.wMonth, SysTime.wDay,
       SysTime.wHour, SysTime.wMinute, SysTime.wSecond]));
  Result := SystemTimeToStringBuffer;
end;

function FormatFullTime(Hour, Minute, Second, Milliseconds: Word; WithMilliseconds: boolean): PChar;
{ Pure formatting extracted VERBATIM (asm intact) from tree.GetFullTimeString so
  it can be golden-master tested before/after asm removal. tree forwards the UTC
  fields. Local copies (h/m/s/ms) keep the asm operands in memory (the original
  read the UTC global), avoiding register-param clobber. }
begin
  // Issue #997: asm wsprintf-push -> SysUtils.Format (proven byte-identical to
  // the asm baseline by uTestFreqTimeFormat). %.2hu/%.3hu -> %.2u/%.3u.
  if WithMilliseconds then
    StrPCopy(FullTimeBuffer, SysUtils.Format('%.2u:%.2u:%.2u:%.3u', [Hour, Minute, Second, Milliseconds]))
  else
    StrPCopy(FullTimeBuffer, SysUtils.Format('%.2u:%.2u:%.2u', [Hour, Minute, Second]));
  Result := FullTimeBuffer;
end;

end.
