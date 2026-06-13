unit uStrSearch;

{
  String helpers (PChar substring search + ShortString upcase) extracted from
  TF.pas for the Issue #997 inline-asm removal effort.

  These three routines were originally hand-written x86 inline assembler
  (JOH-style IA32). They are extracted here into a dependency-light unit so
  that:

    1. Their exact behavior can be frozen by golden-master unit tests
       (uTestStrSearch) -- TF.pas itself cannot be linked into the test
       harness because it pulls in MainUnit and the whole UI graph.
    2. The asm bodies were then replaced with the Delphi RTL / pure Pascal
       (see implementation) and proven equivalent against the frozen baseline.

  TF.pas keeps the public names (StrPos, StrPosPartial, StrComp_JOH_IA32_6)
  and forwards here, so existing callers are unaffected.

  SEMANTICS (must be preserved exactly):

    StrPos(Str1, Str2)
      Returns a pointer to the first occurrence of Str2 within Str1, or nil
      if not found / either argument nil / Str2 longer than Str1. Identical
      contract to SysUtils.StrPos.

    StrComp_JOH_IA32_6(Str1, Str2)
      Standard C strcmp: <0, 0, >0. Identical contract to SysUtils.StrComp.
      (Currently uncalled in the codebase, retained for API stability.)

    StrPosPartial(Str1, Str2)
      Like StrPos, but a '?' in Str2 matches any single character -- EXCEPT
      for the FIRST character of Str2, which is always matched literally
      (the original asm seeds the scan with an exact match on Str2[0], so a
      leading '?' looks for a literal '?'). Returns a pointer into Str1 to
      the start of the match, or nil.

    StrU(var Str)
      Upcases the ASCII letters 'a'..'z' of a ShortString IN PLACE; all other
      bytes (digits, punctuation, and >127 extended/code-page characters) are
      left untouched. The original TF.pas routine was declared with a by-value
      parameter but, as a bare 'assembler' proc, received a pointer to the
      caller's string and wrote through it -- so it modified the original. The
      whole case-insensitive config loader depends on this (see the LogCfg
      "Case-Sensitivity Problem" note and the ctPassword re-read STOPGAP). The
      parameter is therefore declared 'var' here to make that real contract
      explicit; all call sites (TF only) already pass a local variable.
}

interface

function StrPos(const Str1, Str2: PChar): PChar;
function StrPosPartial(const Str1, Str2: PChar): PChar;
function StrComp_JOH_IA32_6(const Str1, Str2: PChar): integer;
procedure StrU(var Str: ShortString);

implementation

uses
  SysUtils;

// Issue #997: x86 inline-asm bodies replaced by the Delphi RTL / pure Pascal.
// Equivalence to the original asm is frozen by uTestStrSearch (31 golden cases).

function StrComp_JOH_IA32_6(const Str1, Str2: PChar): integer;
var
  Cmp: integer;
begin
  // The original asm normalized its result to exactly -1 / 0 / +1
  // (sbb eax,eax; or al,1). SysUtils.StrComp instead returns the raw byte
  // difference of the first mismatch (e.g. '' vs 'A' -> -65). Normalize the
  // sign to preserve the original contract byte-for-byte.
  Cmp := SysUtils.StrComp(Str1, Str2);
  if Cmp < 0 then
    Result := -1
  else if Cmp > 0 then
    Result := 1
  else
    Result := 0;
end;

function StrPosPartial(const Str1, Str2: PChar): PChar;
var
  Len1, Len2: integer;
  i, j: integer;
  Matched: boolean;
begin
  // Like StrPos, but '?' in Str2 matches any single character -- EXCEPT the
  // FIRST pattern character, which is always matched literally (the original
  // asm seeded its scan with an exact match on Str2[0], so a leading '?'
  // looks for a literal '?'). See uTestStrSearch for the frozen cases.
  Result := nil;
  if (Str1 = nil) or (Str2 = nil) then
    Exit;

  Len2 := SysUtils.StrLen(Str2);
  if Len2 = 0 then          // empty pattern -> nil (matches the asm)
    Exit;

  Len1 := SysUtils.StrLen(Str1);
  if Len1 < Len2 then       // pattern longer than text -> nil
    Exit;

  for i := 0 to Len1 - Len2 do
    begin
    // First character is literal (no wildcard), exactly as the asm scan.
    if Str1[i] <> Str2[0] then
      Continue;

    Matched := True;
    for j := 1 to Len2 - 1 do
      begin
      if (Str1[i + j] <> Str2[j]) and (Str2[j] <> '?') then
        begin
        Matched := False;
        Break;
        end;
      end;

    if Matched then
      begin
      Result := Str1 + i;
      Exit;
      end;
    end;
end;

function StrPos(const Str1, Str2: PChar): PChar;
begin
  // TF's original asm body was Borland's classic StrPos verbatim, so the RTL
  // is bit-equivalent (including empty-pattern / over-length / nil -> nil).
  Result := SysUtils.StrPos(Str1, Str2);
end;

procedure StrU(var Str: ShortString);
var
  i: integer;
begin
  // Upcase only ASCII 'a'..'z' in place (subtract $20); leave every other
  // byte -- digits, punctuation and >127 extended/code-page chars -- alone,
  // exactly as the original asm (CMP 'a'/'z'; JB/JA skip). Equivalence frozen
  // by uTestStrSearch.
  for i := 1 to Length(Str) do
    begin
    if Str[i] in ['a'..'z'] then
      Str[i] := Chr(Ord(Str[i]) - $20);
    end;
end;

end.
