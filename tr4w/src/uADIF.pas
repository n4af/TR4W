unit uADIF;

{
  TR4W ADIF lexer + helpers — focused, dependency-light, testable.

  This unit contains the migration-touchy core of ADIF import: the
  string-slicing lexer and the small helpers that map ADIF field text
  into TR4W types (band, mode, date, time, contest).

  It deliberately depends only on SysUtils / StrUtils / Log4D / VC so
  the unit-test runner can link it without pulling MainUnit and its
  window / contest-state globals.

  Issue #887 — second incremental commit.  This commit adds:
    - TADIF_Fields enum (moved from MainUnit)
    - GetADIFBand / GetADIFMode / GetADIFSubMode (moved)
    - ADIFDateStringToQSOTime / ADIFTimeStringToQSOTime (moved)
    - GetContestByADIFName (moved; cache preserved as unit-private)
    - IsValidGUID (local copy; avoids dragging trdos/LOGSTUFF.PAS)

  Previously shipped (first incremental commit):
    - ParseADIFFieldsList (the lexer)
    - TADIFField / TADIFFieldList types

  Still in MainUnit, will move in follow-up commits:
    - The field-name -> ContestExchange mapping case statement
    - The contest-specific post-processing tail
    - ImportADIFFromString multi-record entry point

  See docs/tr4w-migration-strategy.md.  ADIF string handling is the
  highest-risk surface for Phase 2 (Unicode correctness); each function
  here is reachable from the unit-test runner without MainUnit baggage.

  Delphi 12 migration note:
    Bare `string` is used here.  In D7 this is AnsiString; in D12 it
    becomes UnicodeString.  ADIF is fundamentally a text format with
    UTF-8 in NAME/QTH/COMMENT fields, so the UnicodeString transition
    is the correct semantic.  Wire-byte data (CI-V, etc.) elsewhere in
    TR4W explicitly types AnsiString.
}

interface

uses
   SysUtils,
   StrUtils,
   Log4D,
   VC;

type
   TADIFField = record
      Name  : string;
      Value : string;
   end;

   TADIFFieldList = array of TADIFField;

   // Transient fields populated by ApplyADIFFieldsToExchange that the
   // contest-specific post-processing (in MainUnit) needs.  Some ADIF
   // tags map directly to ContestExchange fields; others need contest-
   // aware re-interpretation (e.g. STATE in ARRL_RTTY_ROUNDUP becomes
   // part of QTHString in a contest-defined format).  This record
   // carries the raw field values forward so the contest tail can do
   // its job without re-parsing.
   TADIFRecordTemps = record
      SRX_String : string;
      STX_String : string;
      State      : string;
      ARRL_Sect  : string;
      VE_Prov    : string;
      POTARef    : string;
      SIG        : string;
      SIG_Info   : string;
      GridSquare : string;
      FOC_Num    : string;
      APP_HQ     : string;
      FromWSJTX  : Boolean;
   end;

   TContestExchangeArray = array of ContestExchange;

   // ADIF field-name dispatch enum.  Order MUST match the AnsiIndexText
   // string array in MainUnit.ParseADIFRecord (and in the future, in
   // ApplyADIFFieldsToExchange when that moves here).  Adding entries
   // requires updating both the enum and the lookup array.
   TADIF_Fields = (tAdifARRL_SECT = 0, tAdifBAND, tAdifCALL, tAdifCHECK,
      tAdifCLASS, tAdifCQ_Z,
      tAdifCONTEST_ID, tAdifCNTY, tadifFOC_NUM, tAdifGRIDSQUARE, tAdifFREQ,
      tAdifFREQ_RX,
      tAdifIOTA, tAdifITUZ, tAdifMODE, tAdifNAME, tAdifOPERATOR, tAdifPRECEDENCE,
      tAdifQSO_DATE, tAdifQSO_DATE_OFF, tAdifTIME_ON, tAdifTIME_OFF,
      tAdifRST_RCVD, tAdifRST_SENT, tAdifRX_PWR, tAdifSRX, tAdifSRX_STRING,
      tAdifSTATE, tAdifSTX, tAdifSTX_STRING, tAdifSUBMODE, tAdifTEN_TEN,
      tAdifVE_PROV, tAdifAPP_TR4W_HQ, tAdifAPP_N1MM_HQ, tAdifSTATION_CALLSIGN,
      tAdifQTH, tAdifPROGRAMID, tAdifAPP_N1MM_EXCHANGE1, tAdifAPP_N1MM_ID,
      tAdifAPP_TR4W_ID, tAdifSIG, tAdifSIG_INFO, tAdifPOTAREF,
      tAdifAPP_TR4W_ROVERCALL);

// =========================================================================
// Lexer
// =========================================================================

// Parse a single ADIF record's field list from `s`.
//
// The lexer reads fields of the form `<NAME:n>VALUE` (optionally
// `<NAME:n:T>` where T is the ADIF data-type indicator — type is
// discarded).  Whitespace and free-form text between fields is ignored.
// The lexer stops at the first `<EOR>` or `<EOH>` it encounters
// (case-insensitive).
//
// Returns True if a terminator (<EOR> or <EOH>) was found.  Returns False
// when the end of `s` is reached without a terminator OR when a malformed
// tag is encountered.  Even on False, `fields` contains the fields that
// were successfully parsed before the error/end.
function ParseADIFFieldsList(const s: string;
                             out fields: TADIFFieldList): Boolean;

// =========================================================================
// Per-field type-conversion helpers
// =========================================================================

// Convert an ADIF BAND string ("20m", "70cm") to a TR4W BandType.
// Returns NoBand for unrecognized input.  Case-insensitive.
function GetADIFBand(sBand: string): BandType;

// Convert an ADIF MODE string ("CW", "SSB", "FT8", ...) to a TR4W
// (Mode, ExtendedMode) pair.  Returns NoMode for unrecognized input.
// Case-insensitive.
function GetADIFMode(sMode: string): ModeAndExtendedModeType;

// Convert an ADIF SUBMODE string ("FT4", "USB", "LSB", ...) to a TR4W
// (Mode, ExtendedMode) pair.  Returns NoMode for unrecognized input.
// Case-insensitive.
function GetADIFSubMode(sSubMode: string): ModeAndExtendedModeType;

// Parse an ADIF QSO_DATE string ("YYYYMMDD", 8 chars).  Returns True on
// success and sets qsoTime.qtYear/qtMonth/qtDay.  Returns False (without
// modifying qsoTime) on invalid input.
function ADIFDateStringToQSOTime(sDate: string;
                                 var qsoTime: TQSOTime): Boolean;

// Parse an ADIF TIME_ON / TIME_OFF string ("HHMM" or "HHMMSS").  Returns
// True on success and sets qsoTime.qtHour/qtMinute/qtSecond (seconds = 0
// when only HHMM provided).  Returns False on invalid input.
function ADIFTimeStringToQSOTime(sTime: string;
                                 var qsoTime: TQSOTime): Boolean;

// Look up a contest by its ADIF CONTEST_ID value.  Returns the first
// ContestType whose ContestsArray[].ADIFName matches sADIFName; otherwise
// returns the contest at Low(ContestsArray) (DummyContest).  Caller must
// then verify ContestsArray[Result].ADIFName = sADIFName to distinguish
// "not found" from "first contest".  Cached single-entry for the common
// case of all QSOs in a file sharing the same contest.
function GetContestByADIFName(sADIFName: string): ContestType;

// Validate an ADIF GUID/UUID string.  Accepts 32 hex characters with
// optional 8-4-4-4-12 hyphens and optional `{...}` braces.  Used to gate
// the APP_N1MM_ID / APP_TR4W_ID assignment to exch.id.
function IsValidGUID(const guid: string): Boolean;

// =========================================================================
// Field-to-ContestExchange mapping
// =========================================================================

// Clear a TADIFRecordTemps to empty/false state.
procedure InitADIFRecordTemps(var temps: TADIFRecordTemps);

// Apply a parsed field list to a ContestExchange record, populating
// "obvious" exch.X fields (CALL, BAND, MODE, FREQ, RST, SRX, STX, etc.)
// directly, and capturing the contest-aware temp values (SRX_STRING,
// STATE, ARRL_SECT, POTA_REF, etc.) into `temps` for the caller's
// contest-specific post-processing step.
//
// Returns False on parse error inside an individual field (e.g.
// StrToInt failure on RST_RCVD); the function continues processing the
// remaining fields and the partial exch is preserved.  Returns True
// when all fields were processed without exception.
function ApplyADIFFieldsToExchange(const fields: TADIFFieldList;
                                   var exch: ContestExchange;
                                   var temps: TADIFRecordTemps): Boolean;

// =========================================================================
// Multi-record entry point
// =========================================================================

// Parse a multi-record ADIF string into `records`.  Splits on <EOR>
// (case-insensitive), lexes each record, and applies the field mapping
// for each.  The contest-specific post-processing tail is NOT applied
// here -- the caller is responsible for that (e.g. MainUnit.ImportFromADIF
// applies it via ApplyContestSpecificADIFTail).
//
// Skips an optional ADIF header section (everything up to the first
// <EOH>, also case-insensitive).
//
// `records` is resized via SetLength to fit the parsed records.  Returns
// the count of records successfully parsed (= Length(records)).
function ImportADIFFromString(const s: string;
                              var records: TContestExchangeArray): Integer;

implementation

var
   logger : TLogLogger;

   // Single-entry cache for GetContestByADIFName.  All QSOs in a typical
   // import file share the same CONTEST_ID, so this is a hot path.
   saveLastADIFName : string;
   saveLastContest  : ContestType;

// ---------------------------------------------------------------------------
// Lexer helpers
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

// ---------------------------------------------------------------------------
// Per-field type-conversion helpers
// ---------------------------------------------------------------------------

function GetADIFBand(sBand: string): BandType;
var
   sBandLower : string;
   iBand      : BandType;
   entry      : PChar;
begin
   Result := NoBand;
   // Reject empty input — ADIFBANDSTRINGSARRAY has nil entries for the
   // tail of BandType (placeholders), and an empty string would match
   // those PChar(nil) entries on string comparison, yielding a spurious
   // band.  No legitimate ADIF input has BAND=''.
   if sBand = '' then
      Exit;
   sBandLower := AnsiLowerCase(sBand);
   for iBand := Low(BandType) to High(BandType) do
      begin
      entry := ADIFBANDSTRINGSARRAY[iBand];
      if (entry <> nil) and (sBandLower = entry) then
         begin
         Result := iBand;
         Break;
         end;
      end;
end;

function GetADIFMode(sMode: string): ModeAndExtendedModeType;
begin
   case AnsiIndexText(AnsiUpperCase(sMode),
                      ['CW', 'SSB', 'AM', 'FM', 'FT8',
                       'RTTY', 'MFSK', 'PSK31', 'PSK']) of
      0:                              // CW
         begin
         Result.msmMode := CW;
         Result.msmExtendedMode := eCW;
         end;
      1:                              // SSB
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eSSB;
         end;
      2:                              // AM
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eAM;
         end;
      3:                              // FM
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eFM;
         end;
      4:                              // FT8
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eFT8;
         end;
      5:                              // RTTY
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eRTTY;
         end;
      6:                              // MFSK
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eMFSK;
         end;
      7, 8:                           // PSK31, PSK
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := ePSK31;
         end;
   else
      Result.msmMode := NoMode;
   end;
end;

function GetADIFSubMode(sSubMode: string): ModeAndExtendedModeType;
begin
   case AnsiIndexText(AnsiUpperCase(sSubMode),
                      ['FT4', 'JS8', 'USB', 'LSB', 'PSK31']) of
      0:                              // FT4
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eFT4;
         end;
      1:                              // JS8
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eJS8;
         end;
      2:                              // USB
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eUSB;
         end;
      3:                              // LSB
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eLSB;
         end;
      4:                              // PSK31
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := ePSK31;
         end;
   else
      Result.msmMode := NoMode;
   end;
end;

function ADIFDateStringToQSOTime(sDate: string;
                                 var qsoTime: TQSOTime): Boolean;
begin
   Result := False;
   try
      if Length(sDate) = 8 then
         begin
         qsoTime.qtYear  := Ord(StrToInt(MidStr(sDate, 1, 4)) mod 100);
         qsoTime.qtMonth := Ord(StrToInt(MidStr(sDate, 5, 2)));
         qsoTime.qtDay   := Ord(StrToInt(MidStr(sDate, 7, 2)));
         Result := True;
         end;
   except
      Result := False;
   end;
end;

function ADIFTimeStringToQSOTime(sTime: string;
                                 var qsoTime: TQSOTime): Boolean;
begin
   Result := False;
   if Length(sTime) in [4, 6] then
      begin
      try
         qsoTime.qtHour   := Ord(StrToInt(MidStr(sTime, 1, 2)));
         qsoTime.qtMinute := Ord(StrToInt(MidStr(sTime, 3, 2)));
         if Length(sTime) = 6 then
            qsoTime.qtSecond := Ord(StrToInt(MidStr(sTime, 5, 2)))
         else
            qsoTime.qtSecond := 0;
         Result := True;
      except
         Result := False;
      end;
      end;
end;

function GetContestByADIFName(sADIFName: string): ContestType;
var
   i : ContestType;
begin
   if sADIFName = saveLastADIFName then
      begin
      Result := saveLastContest;
      Exit;
      end;

   Result := Low(ContestsArray); // first contest = DummyContest
   for i := Low(ContestsArray) to High(ContestsArray) do
      begin
      if ContestsArray[i].ADIFName = sADIFName then
         begin
         Result := i;
         saveLastADIFName := sADIFName;
         saveLastContest  := i;
         Break;
         end;
      end;
end;

// ---------------------------------------------------------------------------
// IsValidGUID
//
// Standalone GUID validator that does NOT depend on TPerlRegEx (the
// LOGSTUFF.PAS version uses TPerlRegEx, which would drag in a much
// heavier dependency surface).  Accepts:
//   - 32 raw hex characters (no separators)
//   - 8-4-4-4-12 hyphenated form (36 characters)
//   - Either of the above wrapped in `{...}` braces
// ---------------------------------------------------------------------------

function IsValidGUID(const guid: string): Boolean;
const
   HEX_CHARS = ['0'..'9', 'a'..'f', 'A'..'F'];
var
   s        : string;
   i        : Integer;
   hexCount : Integer;
begin
   Result := False;
   if guid = '' then
      Exit;

   s := guid;

   // Strip optional surrounding braces
   if (Length(s) >= 2) and (s[1] = '{') and (s[Length(s)] = '}') then
      s := Copy(s, 2, Length(s) - 2);

   if (Length(s) <> 32) and (Length(s) <> 36) then
      Exit;

   hexCount := 0;
   for i := 1 to Length(s) do
      begin
      if s[i] in HEX_CHARS then
         Inc(hexCount)
      else if s[i] = '-' then
         begin
         // Hyphens only at positions 9, 14, 19, 24 in 8-4-4-4-12 layout
         if (Length(s) <> 36) or
            ((i <> 9) and (i <> 14) and (i <> 19) and (i <> 24)) then
            Exit;
         end
      else
         Exit;
      end;

   Result := hexCount = 32;
end;

// ---------------------------------------------------------------------------
// Field-to-ContestExchange mapping
// ---------------------------------------------------------------------------

procedure InitADIFRecordTemps(var temps: TADIFRecordTemps);
begin
   temps.SRX_String := '';
   temps.STX_String := '';
   temps.State      := '';
   temps.ARRL_Sect  := '';
   temps.VE_Prov    := '';
   temps.POTARef    := '';
   temps.SIG        := '';
   temps.SIG_Info   := '';
   temps.GridSquare := '';
   temps.FOC_Num    := '';
   temps.APP_HQ     := '';
   temps.FromWSJTX  := False;
end;

const
   // Order MUST match the TADIF_Fields enum declaration.  Adding a field
   // requires updating BOTH this array AND the enum.
   ADIF_FIELD_NAMES : array[0..44] of string = (
      'ARRL_SECT', 'BAND', 'CALL', 'CHECK', 'CLASS', 'CQ_Z',
      'CONTEST_ID', 'CNTY', 'FOC_NUM', 'GRIDSQUARE', 'FREQ', 'FREQ_RX',
      'IOTA', 'ITUZ', 'MODE', 'NAME', 'OPERATOR', 'PRECEDENCE',
      'QSO_DATE', 'QSO_DATE_OFF', 'TIME_ON', 'TIME_OFF',
      'RST_RCVD', 'RST_SENT', 'RX_PWR', 'SRX', 'SRX_STRING',
      'STATE', 'STX', 'STX_STRING', 'SUBMODE', 'TEN_TEN',
      'VE_PROV', 'APP_TR4W_HQ', 'APP_N1MM_HQ', 'STATION_CALLSIGN',
      'QTH', 'PROGRAMID', 'APP_N1MM_EXCHANGE1', 'APP_N1MM_ID',
      'APP_TR4W_ID', 'SIG', 'SIG_INFO', 'POTA_REF',
      'APP_TR4W_ROVERCALL');

function ApplyADIFFieldsToExchange(const fields: TADIFFieldList;
                                   var exch: ContestExchange;
                                   var temps: TADIFRecordTemps): Boolean;
var
   i                    : Integer;
   fieldName            : string;
   fieldValue           : string;
   tempRST              : string;
   neFreq               : Extended;
   msm                  : ModeAndExtendedModeType;
   contest              : ContestType;
   saveDecimalSeparator : Char;
   haveRoverCall        : Boolean;
begin
   Result := True;
   InitADIFRecordTemps(temps);
   haveRoverCall := False;

   for i := 0 to High(fields) do
      begin
      fieldName  := fields[i].Name;
      fieldValue := fields[i].Value;

      try
         case TADIF_Fields(AnsiIndexText(AnsiUpperCase(fieldName),
                                         ADIF_FIELD_NAMES)) of

            tAdifARRL_SECT:
               temps.ARRL_Sect := fieldValue;

            tAdifBAND:
               exch.Band := GetADIFBand(fieldValue);

            tAdifCALL:
               // If we have already seen APP_TR4W_ROVERCALL in this
               // record, it carries the full rover form (KG1S/MON)
               // and we keep that instead of the bare CALL value.
               if not haveRoverCall then
                  exch.Callsign := AnsiUpperCase(fieldValue);

            tAdifAPP_TR4W_ROVERCALL:
               begin
               exch.Callsign := AnsiUpperCase(fieldValue);
               haveRoverCall := True;
               end;

            tAdifCHECK:
               exch.Check := StrToInt(fieldValue);

            tAdifCLASS:
               exch.ceClass := AnsiUpperCase(fieldValue);

            tAdifCQ_Z:
               exch.Zone := StrToInt(fieldValue);

            tAdifCONTEST_ID:
               begin
               contest := GetContestByADIFName(fieldValue);
               if ContestsArray[contest].ADIFName = fieldValue then
                  exch.ceContest := contest;
               end;

            tAdifCNTY:
               logger.Info('[ApplyADIFFields] CNTY=%s but no destination field',
                           [fieldValue]);

            tAdifFOC_NUM:
               temps.FOC_Num := fieldValue;

            tAdifGRIDSQUARE:
               temps.GridSquare := fieldValue;

            tAdifFREQ:
               begin
               saveDecimalSeparator := DecimalSeparator;
               try
                  DecimalSeparator := '.';
                  neFreq := StrToFloat(fieldValue);
                  neFreq := neFreq * 1000000;
                  exch.Frequency := Trunc(neFreq);
               finally
                  DecimalSeparator := saveDecimalSeparator;
               end;
               end;

            tAdifITUZ:
               exch.Zone := StrToInt(fieldValue);

            tAdifMODE:
               if exch.Mode = NoMode then
                  begin
                  msm := GetADIFMode(fieldValue);
                  exch.Mode    := msm.msmMode;
                  exch.ExtMode := msm.msmExtendedMode;
                  end;

            tAdifNAME:
               exch.Name := fieldValue;

            tAdifOPERATOR:
               StrPLCopy(exch.ceOperator, fieldValue, High(exch.ceOperator));

            tAdifPRECEDENCE:
               if Length(fieldValue) > 0 then
                  exch.Precedence := fieldValue[1];

            tAdifQSO_DATE:
               ADIFDateStringToQSOTime(fieldValue, exch.tSysTime);

            tAdifTIME_ON, tAdifTIME_OFF:
               ADIFTimeStringToQSOTime(fieldValue, exch.tSysTime);

            tAdifRST_RCVD:
               begin
               tempRST := fieldValue;
               // WSJT-X uses signed dB SNR like "+05" / "-12".  Strip
               // the sign so StrToIntDef can parse the magnitude.  The
               // sign is dropped (TR uses a Word; negative SNRs are
               // not representable in the legacy log format).
               if temps.FromWSJTX and (Pos('+', fieldValue) > 0) then
                  tempRST := AnsiMidStr(fieldValue, 2, Length(fieldValue));
               exch.RSTReceived := StrToIntDef(tempRST, 599);
               end;

            tAdifRST_SENT:
               begin
               tempRST := fieldValue;
               if temps.FromWSJTX and (Pos('+', fieldValue) > 0) then
                  tempRST := AnsiMidStr(fieldValue, 2, Length(fieldValue));
               exch.RSTSent := StrToIntDef(tempRST, 599);
               end;

            tAdifRX_PWR:
               exch.Power := fieldValue;

            tAdifSRX:
               exch.NumberReceived := StrToInt(fieldValue);

            tAdifSRX_STRING:
               temps.SRX_String := fieldValue;

            tAdifSTATE:
               temps.State := fieldValue;

            tAdifSTX:
               exch.NumberSent := StrToInt(fieldValue);

            tAdifSTX_STRING:
               temps.STX_String := fieldValue;

            tAdifSUBMODE:
               begin
               msm := GetADIFSubMode(fieldValue);
               exch.Mode    := msm.msmMode;
               exch.ExtMode := msm.msmExtendedMode;
               end;

            tAdifTEN_TEN:
               exch.TenTenNum := StrToInt(fieldValue);

            tAdifVE_PROV:
               temps.VE_Prov := fieldValue;

            tAdifAPP_TR4W_HQ, tAdifAPP_N1MM_HQ:
               temps.APP_HQ := fieldValue;

            tAdifSTATION_CALLSIGN:
               ; // ignored on import

            tAdifQTH:
               exch.QTHString := fieldValue;

            tAdifPROGRAMID:
               if fieldValue = 'WSJT-X' then
                  temps.FromWSJTX := True;

            tAdifAPP_N1MM_EXCHANGE1:
               // N1MM stores CLASS in APP_N1MM_EXCHANGE1 instead of
               // the standard CLASS field.  Map back depending on
               // the active contest.
               if exch.ceContest in [ARRLFIELDDAY, WINTERFIELDDAY] then
                  exch.ceClass := AnsiUpperCase(fieldValue)
               else if exch.ceContest in [FOCMARATHON] then
                  exch.Power := fieldValue;

            tAdifAPP_N1MM_ID, tAdifAPP_TR4W_ID:
               if IsValidGUID(fieldValue) then
                  exch.id := fieldValue;

            tAdifSIG:
               temps.SIG := fieldValue;

            tAdifSIG_INFO:
               temps.SIG_Info := fieldValue;

            tAdifPOTAREF:
               temps.POTARef := fieldValue;

         else
            // Unknown / unhandled field.  Silently accept anything
            // prefixed with APP_ (third-party extensions).  Log others.
            if Copy(fieldName, 1, 4) <> 'APP_' then
               logger.Warn('[ApplyADIFFields] %s is present but no handler',
                           [fieldName]);
         end;

      except
         on e: Exception do
            begin
            Result := False;
            logger.Warn('[ApplyADIFFields] %s=[%s] threw: %s',
                        [fieldName, fieldValue, e.Message]);
            end;
      end;
      end;
end;

// ---------------------------------------------------------------------------
// Multi-record entry point
// ---------------------------------------------------------------------------

function ImportADIFFromString(const s: string;
                              var records: TContestExchangeArray): Integer;
var
   p          : Integer;
   sLen       : Integer;
   eorPosUp   : Integer;
   eohPosUp   : Integer;
   sUpper     : string;
   chunk      : string;
   fields     : TADIFFieldList;
   exch       : ContestExchange;
   temps      : TADIFRecordTemps;
   recordEnd  : Integer;
begin
   Result := 0;
   SetLength(records, 0);
   sLen := Length(s);
   if sLen = 0 then
      Exit;

   sUpper := AnsiUpperCase(s);

   // Skip optional ADIF header (everything up to and including <EOH>).
   eohPosUp := AnsiPos('<EOH>', sUpper);
   if eohPosUp > 0 then
      p := eohPosUp + 5   // length of '<EOH>'
   else
      p := 1;

   while p <= sLen do
      begin
      // Find the next <EOR> (case-insensitive) starting at p.
      eorPosUp := PosEx('<EOR>', sUpper, p);
      if eorPosUp = 0 then
         Break;  // no more complete records

      recordEnd := eorPosUp + 5;  // include the '<EOR>' itself
      chunk := Copy(s, p, recordEnd - p);

      // Lex + apply
      ParseADIFFieldsList(chunk, fields);
      FillChar(exch, SizeOf(exch), 0);
      InitADIFRecordTemps(temps);
      ApplyADIFFieldsToExchange(fields, exch, temps);

      SetLength(records, Result + 1);
      records[Result] := exch;
      Inc(Result);

      p := recordEnd;
      end;
end;

initialization
   logger := TLogLogger.GetLogger('uADIF');
   saveLastADIFName := '';

end.
