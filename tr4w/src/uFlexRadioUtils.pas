unit uFlexRadioUtils;

{
  Pure utility functions for FlexRadio 6000 SmartSDR TCP protocol.
  No radio object, no network, no UI dependencies — safe to use in unit tests.
}

interface

// FlexParseKeyValue
//   Extract a value from a space-separated key=value status payload.
//   Returns '' if the key is not present.
//   Word-boundary safe: 'tx' will not match inside 'retx=0'.
//
//   Example:
//     FlexParseKeyValue('RF_frequency=14.200000 mode=USB tx=1', 'mode') = 'USB'
//     FlexParseKeyValue('RF_frequency=14.200000 mode=USB tx=1', 'tx')   = '1'
//     FlexParseKeyValue('retx=0 tx=1', 'tx') = '1'   (not '0')
function FlexParseKeyValue(const s, key: string): string;

// FlexFormatFreqMHz
//   Format a frequency in Hz as the 'M.HHHHHH' string used in SmartSDR
//   'slice tune' commands.  The fractional part is always 6 digits (zero-padded).
//
//   Delphi 7 Format('%06d') pads with spaces, not zeros — this function builds
//   the zero-padded fraction by adding 1000000 to guarantee 7 digits, then
//   stripping the leading '1'.
//
//   Examples:
//     FlexFormatFreqMHz(14000000) = '14.000000'
//     FlexFormatFreqMHz(14200000) = '14.200000'
//     FlexFormatFreqMHz(14194900) = '14.194900'
//     FlexFormatFreqMHz( 7000000) =  '7.000000'
//     FlexFormatFreqMHz( 1800000) =  '1.800000'
//     FlexFormatFreqMHz(50125000) = '50.125000'
function FlexFormatFreqMHz(freqHz: integer): string;

implementation

uses
   SysUtils;

// ---------------------------------------------------------------------------

function FlexParseKeyValue(const s, key: string): string;
var
   searchKey: string;
   padded:    string;
   keyPos:    integer;
   afterEq:   string;
   spacePos:  integer;
begin
   Result    := '';
   searchKey := ' ' + key + '=';
   padded    := ' ' + s;   // prepend space so the very first key is also matched
   keyPos    := Pos(searchKey, padded);
   if keyPos = 0 then
      Exit;
   afterEq  := Copy(padded, keyPos + Length(searchKey), Length(padded));
   spacePos := Pos(' ', afterEq);
   if spacePos = 0 then
      Result := afterEq
   else
      Result := Copy(afterEq, 1, spacePos - 1);
end;

// ---------------------------------------------------------------------------

function FlexFormatFreqMHz(freqHz: integer): string;
var
   fracStr: string;
begin
   fracStr := Copy(IntToStr(1000000 + (freqHz mod 1000000)), 2, 6);
   Result  := Format('%d.%s', [freqHz div 1000000, fracStr]);
end;

end.
