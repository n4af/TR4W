unit uExchangeBuilder;

(*
  Shared exchange string builders for RTC / HamScore / N1MM-style UDP
  ContactInfo broadcasts.

  The TR4W exchange parser is intentionally forgiving about field order --
  for a grid contest you can type either "EL88 1234" or "1234 EL88" and
  parse both correctly into NumberReceived / QTHString.  But scoring
  consumers (HamScore RTC, external loggers) want a canonical form so
  that the same QSO doesn't appear two different ways depending on what
  the operator typed.

  These helpers rebuild the SentExchange and RxExchange strings from the
  ContestExchange record's typed fields, per contest type, in the
  scoring-canonical order.  Output is plain text; XML escaping is the
  caller's job.

  Future: when the radio/contest factory grows an "RTC exchange template"
  field per contest, these dispatchers move there and the case statement
  disappears.
*)

interface

uses
  VC;

// Plain-text builders (no XML escaping).
function BuildSentExchangeText(const RXData: ContestExchange): string;
function BuildRxExchangeText  (const RXData: ContestExchange): string;

implementation

uses
  SysUtils, StrUtils,
  LogCW;     // CQExchange template global

// Collapse runs of whitespace (space + tab) to a single space and trim
// both ends.  Used after substituting into the CQExchange template so
// the template's leading space and any double spaces from optional
// fields don't survive.
function CollapseWhitespace(const s: string): string;
var
   i: Integer;
   prevSpace: Boolean;
begin
   Result := '';
   prevSpace := True;
   for i := 1 to Length(s) do
      begin
      if (s[i] = ' ') or (s[i] = #9) then
         begin
         if not prevSpace then
            begin
            Result := Result + ' ';
            prevSpace := True;
            end;
         end
      else
         begin
         Result := Result + s[i];
         prevSpace := False;
         end;
      end;
   while (Length(Result) > 0) and (Result[Length(Result)] = ' ') do
      SetLength(Result, Length(Result) - 1);
end;

// 599 on CW/Digital, 59 on Phone/FM -- used when RSTReceived = 0 because
// the operator accepted the parser default and it never picked up an
// explicit value.
function DefaultRST(mode: ModeType): string;
begin
   case mode of
      CW, Digital: Result := '599';
   else
      Result := '59';
   end;
end;

function RSTReceivedString(const RXData: ContestExchange): string;
begin
   if RXData.RSTReceived > 0 then
      Result := IntToStr(RXData.RSTReceived)
   else
      Result := DefaultRST(RXData.Mode);
end;

function BuildSentExchangeText(const RXData: ContestExchange): string;
var
   tpl: string;
begin
   tpl := string(CQExchange);
   if tpl = '' then
      begin
      // No template configured -- fall back to whatever the operator
      // typed.  Still echoes the received exchange, but no worse than
      // pre-fix behaviour and avoids fabricating data we don't have.
      Result := Trim(string(RXData.ExchString));
      Exit;
      end;

   // '#' -> our sent serial number for this QSO.
   tpl := StringReplace(tpl, '#',   IntToStr(RXData.NumberSent), [rfReplaceAll]);
   // CW shorthand '5NN' -> '599' (T = N in CW).  RTC consumers want
   // canonical numeric RST, not keyer shorthand.
   tpl := StringReplace(tpl, '5NN', '599',                       [rfReplaceAll, rfIgnoreCase]);

   Result := CollapseWhitespace(tpl);
end;

function BuildRxExchangeText(const RXData: ContestExchange): string;
var
   rst, serial, age, zone, qth, pwr, nm, cls: string;
begin
   rst    := RSTReceivedString(RXData);
   serial := IntToStr(RXData.NumberReceived);
   age    := IntToStr(RXData.Age);
   zone   := IntToStr(RXData.Zone);
   qth    := Trim(string(RXData.QTHString));
   pwr    := Trim(string(RXData.Power));
   nm     := Trim(string(RXData.Name));
   cls    := Trim(string(RXData.ceClass));

   case RXData.ceContest of
      // RST + serial
      CQWPXCW, CQWPXSSB, DARCWAEDCCW:
         Result := rst + ' ' + serial;

      // RST + zone
      CQWWCW, CQWWSSB, IARU:
         Result := rst + ' ' + zone;

      // RST + state/section literal
      CQ160CW:
         Result := rst + ' ' + qth;

      // ARRL DX: US side sends RST+state, DX side sends RST+power.
      // TR4W's parser puts state in QTHString and power in Power; pick
      // whichever the worked station actually sent.
      ARRLDXCW, ARRLDXSSB:
         if qth <> '' then
            Result := rst + ' ' + qth
         else
            Result := rst + ' ' + pwr;

      // RST + age
      ALLASIANCW, ALLASIANSSB:
         Result := rst + ' ' + age;

      // CWT: Name + (member# or QTH) -- both go through QTHString.
      CWOPS:
         Result := nm + ' ' + qth;

      // CWOpen: serial + Name
      CWOPEN:
         Result := serial + ' ' + nm;

      // RTC (Real-Time Contest, Issue #902): serial + grid.
      // Parser uses RSTQSONumberAndGridSquareExchange (which accepts RST
      // optionally) but the actual on-air exchange is just serial + grid.
      RTC:
         Result := serial + ' ' + qth;

      // ARRL Field Day / Winter Field Day: class + section.
      // Both contests use ClassDomesticOrDXQTHExchange; class lands in
      // ceClass (e.g. "2A"), section in QTHString (e.g. "FL" or "DX").
      ARRLFIELDDAY, WINTERFIELDDAY:
         Result := cls + ' ' + qth;

   else
      // Unknown contest -- emit the raw operator-typed string.  Same as
      // pre-fix behaviour; no worse, and avoids fabricating fields.
      Result := Trim(string(RXData.ExchString));
   end;

   Result := CollapseWhitespace(Result);
end;

end.
