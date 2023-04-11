unit utils_text;

interface
uses VC, SysUtils;

function UpperCase(const s: ShortString): ShortString;

function tCharIsNumbers(c: Char): boolean;
function tCharIsAlphaNumericOrDash(c: Char): boolean;

function safeFloat(sStringFloat : AnsiString) : double;
function StringHas(LongString: Str160; SearchString: Str80): boolean;
function StringHasNumber(Prompt: Str80): boolean;
function StringHasLowerCase(InputString: Str160): boolean;
function StringIsAllNumbers(InputString: Str160): boolean;
function StringIsAllNumbersOrSpaces(InputString: Str160): boolean;
function StringIsAllNumbersOrDecimal(InputString: Str160): boolean;
function StringIsAllAlphanumericOrDash(InputString: Str160): boolean;
function StringHasLetters(InputString: Str160): boolean;
function StringWithFirstWordDeleted(InputString: Str160): Str160;

function PostcedingString(LongString: ShortString; Deliminator: ShortString): ShortString;
function PrecedingString(LongString: ShortString; Deliminator: ShortString): ShortString;

function tPos(s: ShortString; c: Char): integer; //wli
function pPos(c: Char; p: PChar): integer;

function StrComp(const Str1, Str2: PChar): integer;
procedure StrUpper(Str: PChar);

implementation

function UpperCase(const s: ShortString): ShortString;
var
  ch                                    : Char;
  l                                     : integer;
  Source, Dest                          : PChar;
begin
//  inc(tempshowcty);
  //      Result := UpperCase_JOH_IA32_5(s);
//  RESULT := s;
//  Exit;
  l := length(s);
  SetLength(Result, l);
  Source := @s[1];
  Dest := @Result[1];
  while l <> 0 do
  begin
    ch := Source^;
    if (ch >= 'a') and (ch <= 'z') then dec(ch, 32);
    Dest^ := ch;
    inc(Source);
    inc(Dest);
    dec(l);
  end;

end;

function StringHas(LongString: Str160; SearchString: Str80): boolean;

{ This function will return TRUE if the SearchString is contained in the
    LongString.                                                                }

begin
  StringHas := pos(SearchString, LongString) <> 0;
end;

function StringIsAllAlphanumericOrDash(InputString: Str160): boolean;
var
  CharPos                               : integer;
begin
   StringIsAllAlphanumericOrDash := False;
   if InputString = '' then Exit;

   for CharPos := 1 to length(InputString) do
      begin
      if not tCharIsAlphanumericOrDash(InputString[CharPos]) then
         begin
         Exit;
         end;
      end;

  StringIsAllAlphanumericOrDash := True;
end;




function StringHasLetters(InputString: Str160): boolean;

var
  CharPos                               : integer;

begin
  for CharPos := 1 to length(InputString) do

    if (UpCase(InputString[CharPos]) <= 'Z') and (UpCase(InputString[CharPos]) >= 'A') then
    begin
      StringHasLetters := True;
      Exit;
    end;

  StringHasLetters := False;
end;

function StringHasLowerCase(InputString: Str160): boolean;

var
  CharPos                               : integer;

begin
  for CharPos := 1 to length(InputString) do
    if (InputString[CharPos] <= 'z') and (InputString[CharPos] >= 'a') then
    begin
      StringHasLowerCase := True;
      Exit;
    end;

  StringHasLowerCase := False;
end;

function StringHasNumber(Prompt: Str80): boolean;

var
  ChrPtr                                : integer;

begin
  StringHasNumber := False;
  if length(Prompt) = 0 then Exit;

  for ChrPtr := 1 to length(Prompt) do
    //      if (Prompt[ChrPtr] >= '0') and (Prompt[ChrPtr] <= '9') then
    if tCharIsNumbers(Prompt[ChrPtr]) then
    begin
      StringHasNumber := True;
      Exit;
    end;
end;

function StringIsAllNumbers(InputString: Str160): boolean;

var
  CharPos                               : integer;

begin
  StringIsAllNumbers := False;
  if InputString = '' then Exit;

  for CharPos := 1 to length(InputString) do
    if not tCharIsNumbers(InputString[CharPos]) then
      Exit;

  StringIsAllNumbers := True;
end;

function tCharIsNumbers(c: Char): boolean;
begin
  Result := c in ['0'..'9'];
end;

function tCharIsAlphaNumericOrDash(c: Char): boolean;
begin
   Result := (c in ['0'..'9']) or
             (c in ['A'..'Z']) or
             (c in ['-']);
end;

function StringIsAllNumbersOrSpaces(InputString: Str160): boolean;

var
  CharPos                               : integer;

begin
  StringIsAllNumbersOrSpaces := False;
  if InputString = '' then Exit;

  for CharPos := 1 to length(InputString) do
    if not tCharIsNumbers(InputString[CharPos]) then
      //      if (InputString[CharPos] < '0') or (InputString[CharPos] > '9') then
      if InputString[CharPos] <> ' ' then Exit;

  StringIsAllNumbersOrSpaces := True;
end;

function StringIsAllNumbersOrDecimal(InputString: Str160): boolean;

var
  CharPos                               : integer;

begin
  StringIsAllNumbersOrDecimal := False;
  if InputString = '' then Exit;

  for CharPos := 1 to length(InputString) do
    //      if (InputString[CharPos] < '0') or (InputString[CharPos] > '9') then
    if not tCharIsNumbers(InputString[CharPos]) then
      if InputString[CharPos] <> '.' then Exit;

  StringIsAllNumbersOrDecimal := True;
end;

function StringWithFirstWordDeleted(InputString: Str160): Str160;

{ This function performs a wordstar like control-T operation on the
    string passed to it.                                                   }

var
  DeletedChar                           : Char;

begin
  if (InputString = '') or (not StringHas(InputString, ' ')) then
  begin
    StringWithFirstWordDeleted := '';
    Exit;
  end;

  repeat
    DeletedChar := InputString[1];
    Delete(InputString, 1, 1);

    if length(InputString) = 0 then
    begin
      StringWithFirstWordDeleted := '';
      Exit;
    end;

  until (DeletedChar = ' ') and (InputString[1] <> ' ');
  StringWithFirstWordDeleted := InputString;
end;

function PostcedingString(LongString: ShortString; Deliminator: ShortString): ShortString;

var
  Position                              : integer;

begin

  Position := pos(Deliminator, LongString);

  if Position > 0 then
    PostcedingString := Copy(LongString,
      Position + length(Deliminator),
      length(LongString) - Position - (length(Deliminator) - 1))
  else
    PostcedingString := '';
end;

function PrecedingString(LongString: ShortString; Deliminator: ShortString): ShortString;

var
  Position                              : integer;

begin

  Position := pos(Deliminator, LongString);

  if Position >= 2 then
    PrecedingString := Copy(LongString, 1, Position - 1)
  else
    PrecedingString := '';
end;

function pPos(c: Char; p: PChar): integer;
var
  i                                     : Cardinal;
begin
  Result := -1;
  for i := 0 to 255 do
  begin
    if p[i] = #0 then Break;
    if p[i] = c then
    begin
      Result := i;
      Break;
    end;
  end;
end;

function tPos(s: ShortString; c: Char): integer; //
var
  i                                     : Cardinal;
begin
  Result := 0;
  if s = '' then Exit;
  for i := 1 to length(s) do
    if s[i] = c then
    begin
      Result := i;
      Exit;
    end;
end;

function StrComp(const Str1, Str2: PChar): integer; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        MOV     EDI,EDX
        MOV     ESI,EAX
        MOV     ECX,0FFFFFFFFH
        XOR     EAX,EAX
        REPNE   SCASB
        NOT     ECX
        MOV     EDI,EDX
        XOR     EDX,EDX
        REPE    CMPSB
        MOV     AL,[ESI-1]
        MOV     DL,[EDI-1]
        SUB     EAX,EDX
        POP     ESI
        POP     EDI
end;

procedure StrUpper(Str: PChar); assembler;
asm
//        PUSH    ECX
//        XOR     ECX , ECX
        PUSH    ESI
        MOV     ESI,Str
//        LODSB
//        XCHG    CL,AL
//        MOV     ECX,Str
@@1:    LODSB
        OR      AL,AL
        JE      @@2
        CMP     AL,'a'
        JB      @@1
        CMP     AL,'z'
        JA      @@1
        SUB     AL,20H
        MOV     [ESI-1],AL
        JMP     @@1
@@2:    POP     ESI
//        POP     ECX
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  safeFloat

  Strips many bad characters from a string and returns it as a double.
}
function safeFloat(sStringFloat : AnsiString) : double;
var
  dReturn : double;

begin
  sStringFloat := stringReplace(sStringFloat, '%', '', [rfIgnoreCase, rfReplaceAll]);
  sStringFloat := stringReplace(sStringFloat, CurrencyString , '', [rfIgnoreCase, rfReplaceAll]);
  sStringFloat := stringReplace(sStringFloat, ' ', '', [rfIgnoreCase, rfReplaceAll]);
  sStringFloat := stringReplace(sStringFloat, ',', '', [rfIgnoreCase, rfReplaceAll]);
  sStringFloat := stringReplace(sStringFloat, ThousandSeparator, '', [rfIgnoreCase, rfReplaceAll]);
  try
    dReturn := strToFloat(sStringFloat);
  except
    dReturn := 0;
  end;
  result := dReturn;

end;
end.

