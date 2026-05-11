unit uADIF;

{
  TR4W ADIF lexer — focused, dependency-light, testable.

  This unit contains a lightweight ADIF field-list lexer used as the first
  step of ADIF import.  It is deliberately small and free of MainUnit /
  windowing / contest-state dependencies so the unit-test runner can link
  it without dragging in the rest of TR4W.

  Issue #887 — first incremental commit.  This commit ships:
    - TADIFField / TADIFFieldList types
    - ParseADIFFieldsList — single-record field lexer

  Follow-up commits will add the field-name -> ContestExchange mapping
  (currently inlined in MainUnit.ParseADIFRecord) and the multi-record
  ImportADIFFromString entry point.

  See docs/tr4w-migration-strategy.md for the larger context: ADIF string
  handling is the highest-risk surface for Phase 2 (Unicode correctness),
  so a focused regression net here pays back later.

  Delphi 12 migration note:
    Bare `string` is used here.  In D7 this is AnsiString; in D12 it
    becomes UnicodeString.  ADIF is fundamentally a text format with
    occasional UTF-8 in NAME/QTH/COMMENT fields, so the UnicodeString
    transition is the correct semantic.  Wire-byte data (CI-V, etc.)
    elsewhere in TR4W explicitly types AnsiString — the migration strategy
    doc (line 70-72) flags this distinction.
}

interface

uses
   SysUtils,
   StrUtils,
   Log4D;

type
   TADIFField = record
      Name  : string;
      Value : string;
   end;

   TADIFFieldList = array of TADIFField;

// Parse a single ADIF record's field list from `s`.
//
// The lexer reads fields of the form `<NAME:n>VALUE` (optionally `<NAME:n:T>`
// where T is the ADIF data-type indicator — type is discarded).  Whitespace
// and free-form text between fields is ignored.  The lexer stops at the
// first `<EOR>` or `<EOH>` it encounters (case-insensitive).
//
// Returns True if a terminator (<EOR> or <EOH>) was found.  Returns False
// when the end of `s` is reached without a terminator, OR when a malformed
// tag is encountered.  Even on False, `fields` contains the fields that
// were successfully parsed before the error/end.
function ParseADIFFieldsList(const s: string; out fields: TADIFFieldList): Boolean;

implementation

var
   logger : TLogLogger;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

procedure AppendField(var fields: TADIFFieldList;
                     const name, value: string);
var
   idx : Integer;
begin
   idx := Length(fields);
   SetLength(fields, idx + 1);
   fields[idx].Name := name;
   fields[idx].Value := value;
end;

// ---------------------------------------------------------------------------
// Lexer
// ---------------------------------------------------------------------------

function ParseADIFFieldsList(const s: string;
                             out fields: TADIFFieldList): Boolean;
var
   p           : Integer;
   sLen        : Integer;
   gtPos       : Integer;
   tagBody     : string;
   tagUpper    : string;
   tagName     : string;
   tagLenStr   : string;
   tagLen      : Integer;
   colonPos    : Integer;
   secondColon : Integer;
   value       : string;
begin
   Result := False;
   SetLength(fields, 0);
   sLen := Length(s);
   p := 1;

   while p <= sLen do
      begin
      // Skip text between tags
      while (p <= sLen) and (s[p] <> '<') do
         Inc(p);
      if p > sLen then
         Break;

      Inc(p);  // skip '<'

      // Find matching '>'
      gtPos := p;
      while (gtPos <= sLen) and (s[gtPos] <> '>') do
         Inc(gtPos);
      if gtPos > sLen then
         begin
         // '<' without matching '>' — malformed; stop with what we have
         if Assigned(logger) then
            logger.Warn('[ADIF lexer] unclosed tag at position %d', [p - 1]);
         Exit;
         end;

      tagBody := Copy(s, p, gtPos - p);
      p := gtPos + 1;  // advance past '>'

      // Terminators
      tagUpper := AnsiUpperCase(tagBody);
      if (tagUpper = 'EOR') or (tagUpper = 'EOH') then
         begin
         Result := True;
         Exit;
         end;

      // Parse '<NAME:LEN>' or '<NAME:LEN:TYPE>'
      colonPos := AnsiPos(':', tagBody);
      if colonPos = 0 then
         begin
         if Assigned(logger) then
            logger.Warn('[ADIF lexer] tag without length: <%s>', [tagBody]);
         Continue;
         end;

      tagName   := Copy(tagBody, 1, colonPos - 1);
      tagLenStr := Copy(tagBody, colonPos + 1, Length(tagBody) - colonPos);

      // Strip optional ':TYPE' suffix
      secondColon := AnsiPos(':', tagLenStr);
      if secondColon > 0 then
         tagLenStr := Copy(tagLenStr, 1, secondColon - 1);

      if not TryStrToInt(tagLenStr, tagLen) then
         begin
         if Assigned(logger) then
            logger.Warn('[ADIF lexer] tag <%s> has non-numeric length [%s]',
                        [tagName, tagLenStr]);
         Continue;
         end;

      if tagLen < 0 then
         begin
         if Assigned(logger) then
            logger.Warn('[ADIF lexer] tag <%s> has negative length %d',
                        [tagName, tagLen]);
         Continue;
         end;

      // Read exactly tagLen characters as the value
      if p + tagLen - 1 > sLen then
         begin
         // truncated value — take whatever is left, then stop
         value := Copy(s, p, sLen - p + 1);
         AppendField(fields, tagName, value);
         if Assigned(logger) then
            logger.Warn('[ADIF lexer] tag <%s:%d> truncated; got %d bytes',
                        [tagName, tagLen, Length(value)]);
         Exit;
         end;

      value := Copy(s, p, tagLen);
      p := p + tagLen;
      AppendField(fields, tagName, value);
      end;

   // Ran off the end without seeing <EOR> or <EOH>
   Result := False;
end;

initialization
   logger := TLogLogger.GetLogger('uADIF');

end.
