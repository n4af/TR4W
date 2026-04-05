unit uFlexRadio6000;

{
  FlexRadio 6000-Series Direct TCP/IP Integration for TR4W
  Covers FLEX-6300, 6400, 6600, 6700, 6800 and Aurora — all use the same SmartSDR TCP/IP API.

  Protocol:
    - TCP to port 4992, CRLF-terminated lines.
    - Radio initiates: sends V (version), H (client handle), M (message) before client speaks.
    - Client sends subscriptions once the H line is received.
    - All state is pushed unsolicited; no polling required.
    - Commands:  C<seq>|<command>CRLF
    - Responses: R<seq>|<result>|<data>   (result=0 is OK)
    - Status:    S<handle>|<type> key=value...

  VFO mapping:
    VFO A (nrVFOA) = slice 0 (primary RX slice)
    VFO B (nrVFOB) = slice 1 (split TX slice)

  Known limitations:
    - CW injection is not supported via TCP; use the radio's hardware keyer jack.
    - Split mode is not yet implemented (deferred — requires slice create/assign logic).
}

interface

uses
   uNetRadioBase, uRadioBand, StrUtils, SysUtils, Log4D;

type TFlexRadio6000 = class(TNetRadioBase)
   private
      FCmdSeq:        integer;   // Monotonically-increasing command sequence counter (C<n>|)
      FClientHandle:  string;    // Hex handle assigned by radio in 'H<hex>' line
      FPanHandle:     string;    // Panadapter handle from slice 0 status (for band changes)
      FHandshakeDone: boolean;   // True once H line received and subscriptions have been sent
      FSlice0TX:      boolean;   // True when slice 0 is the current TX slice
      FSlice1TX:      boolean;   // True when slice 1 is the current TX slice
      FCWBuffer:      string;    // Accumulates characters until SendCW flushes them
      logger:         TLogLogger;

      function  NextSeq: integer;
      procedure SendFlexCmd(cmd: string);
      function  SplitDelimiter(const s: string; delimiter: Char; index: integer): string;
      function  ParseKeyValue(const s: string; const key: string): string;
      function  FlexModeToRadioMode(const sMode: string): TRadioMode;
      function  RadioModeToFlexMode(mode: TRadioMode): string;
      function  SliceForVFO(whichVFO: TVFO): integer;
      procedure ParseResponseLine(const line: string);
      procedure ParseStatusLine(const line: string);
      procedure ProcessSliceStatus(const payload: string);
      procedure ProcessInterlockStatus(const payload: string);
      procedure ProcessTransmitStatus(const payload: string);
      procedure SendSubscriptions;

   public
      constructor Create;
      function  Connect: integer; override;
      procedure ProcessMsg(msg: string); override;
      procedure SendToRadio(whichVFO: TVFO; sCmd: string; sData: string); overload; override;
      procedure Transmit; override;
      procedure Receive; override;
      procedure BufferCW(cwChars: string); override;
      procedure SendCW; override;
      procedure StopCW; override;
      procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode); override;
      procedure SetMode(mode: TRadioMode; vfo: TVFO = nrVFOA); override;
      function  ToggleMode(vfo: TVFO = nrVFOA): TRadioMode; override;
      procedure SetCWSpeed(speed: integer); override;
      procedure RITClear(whichVFO: TVFO); override;
      procedure XITClear(whichVFO: TVFO); override;
      procedure RITBumpDown; override;
      procedure RITBumpUp; override;
      procedure RITOn(whichVFO: TVFO); override;
      procedure RITOff(whichVFO: TVFO); override;
      procedure XITOn(whichVFO: TVFO); override;
      procedure XITOff(whichVFO: TVFO); override;
      procedure Split(splitOn: boolean); override;
      procedure SetRITFreq(whichVFO: TVFO; hz: integer); override;
      procedure SetXITFreq(whichVFO: TVFO; hz: integer); override;
      procedure SetBand(band: TRadioBand; vfo: TVFO = nrVFOA); override;
      function  ToggleBand(vfo: TVFO = nrVFOA): TRadioBand; override;
      procedure SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA); override;
      function  SetFilterHz(hz: integer; vfo: TVFO = nrVFOA): integer; override;
      function  MemoryKeyer(mem: integer): boolean; override;
      procedure VFOBumpDown(whichVFO: TVFO); override;
      procedure VFOBumpUp(whichVFO: TVFO); override;
   end;

implementation

uses MainUnit;

// ---------------------------------------------------------------------------

constructor TFlexRadio6000.Create;
begin
   inherited Create(ProcessMsg);
   logger            := TLogLogger.GetLogger('TR4WDebugLog.Flex6000-Radio');
   requiresPolling   := False;
   autoUpdateCommand := '';
   pollingInterval   := 0;
   FCmdSeq           := 0;
   FClientHandle     := '';
   FPanHandle        := '';
   FHandshakeDone    := False;
   FSlice0TX         := True;
   FSlice1TX         := False;
   FCWBuffer         := '';
end;

function TFlexRadio6000.Connect: integer;
begin
   // Reset handshake state on every connect so reconnection works cleanly.
   Self.readTerminator := #10;   // Indy ReadLn stops at LF; ProcessMsg trims trailing CR
   FHandshakeDone      := False;
   FClientHandle       := '';
   FPanHandle          := '';
   FCmdSeq             := 0;
   Result := inherited Connect;
   // Note: the base class OnRadioConnected sends 'ID;' after the TCP connection
   // is established.  FlexRadio rejects it (unknown command) and returns an error
   // response.  ProcessMsg handles all R-line errors gracefully — this is harmless.
   // Do NOT send subscriptions here; the radio sends V/H/M lines first and
   // subscriptions are sent from ProcessMsg once the H line arrives.
   if Self.IsConnected then
      begin
      logger.Info('[FlexRadio6000.Connect] TCP connected to %s:%d — awaiting radio handshake',
                  [Self.radioAddress, Self.radioPort]);
      end;
end;

// ---------------------------------------------------------------------------
// SplitDelimiter — emulates TStringList with StrictDelimiter=True.
//
// MIGRATION NOTE (Delphi 7 → Delphi 2006+):
//   TStringList.StrictDelimiter was introduced in Delphi 2006.
//   This helper exists only because Delphi 7 lacks it.
//   When upgrading the compiler, replace calls to SplitDelimiter(s, '|', n)
//   with a TStringList using StrictDelimiter := True and Delimiter := '|'.
//
// Returns the Nth (0-based) field of <s> split by <delimiter>.
// Returns '' if the field index is out of range.
// ---------------------------------------------------------------------------
function TFlexRadio6000.SplitDelimiter(const s: string; delimiter: Char; index: integer): string;
var
   current:  integer;
   startPos: integer;
   endPos:   integer;
begin
   Result   := '';
   current  := 0;
   startPos := 1;
   endPos   := 1;
   while endPos <= Length(s) do
      begin
      if s[endPos] = delimiter then
         begin
         if current = index then
            begin
            Result := Copy(s, startPos, endPos - startPos);
            Exit;
            end;
         Inc(current);
         startPos := endPos + 1;
         end;
      Inc(endPos);
      end;
   // Last field has no trailing delimiter
   if current = index then
      begin
      Result := Copy(s, startPos, Length(s) - startPos + 1);
      end;
end;

// ---------------------------------------------------------------------------
// ParseKeyValue — extracts the value for a given key from a space-separated
// key=value string.  Returns '' if the key is not present.
// Example: ParseKeyValue('RF_frequency=14.156400 mode=USB tx=1', 'mode') = 'USB'
// ---------------------------------------------------------------------------
function TFlexRadio6000.ParseKeyValue(const s: string; const key: string): string;
var
   searchKey: string;
   keyPos:    integer;
   afterEq:   string;
   spacePos:  integer;
begin
   Result    := '';
   searchKey := key + '=';
   keyPos    := Pos(searchKey, s);
   if keyPos = 0 then
      begin
      Exit;
      end;
   afterEq  := Copy(s, keyPos + Length(searchKey), Length(s));
   spacePos := Pos(' ', afterEq);
   if spacePos = 0 then
      begin
      Result := afterEq;
      end
   else
      begin
      Result := Copy(afterEq, 1, spacePos - 1);
      end;
end;

// ---------------------------------------------------------------------------

function TFlexRadio6000.NextSeq: integer;
begin
   // NOTE: Called only from the main (UI) thread via SendFlexCmd.
   // If SendFlexCmd is ever called from the reading thread, add a lock here.
   Inc(FCmdSeq);
   Result := FCmdSeq;
end;

procedure TFlexRadio6000.SendFlexCmd(cmd: string);
var
   fullCmd: string;
begin
   fullCmd := Format('C%d|%s', [NextSeq, cmd]);
   logger.Info('[FlexRadio6000 TX] %s', [fullCmd]);
   inherited SendToRadio(fullCmd);
end;

function TFlexRadio6000.SliceForVFO(whichVFO: TVFO): integer;
begin
   case whichVFO of
      nrVFOA: Result := 0;
      nrVFOB: Result := 1;
   else
      begin
      logger.Error('[FlexRadio6000.SliceForVFO] Unknown VFO ordinal %d — defaulting to slice 0',
                   [Ord(whichVFO)]);
      Result := 0;
      end;
   end;
end;

// ---------------------------------------------------------------------------

procedure TFlexRadio6000.SendSubscriptions;
begin
   logger.Info('[FlexRadio6000] Sending subscription sequence');
   // sub slice all: frequency, mode, RIT/XIT, split — core VFO state
   // sub tx all:    TX/interlock status (transmitting, PTT)
   // keepalive disable: prevents the radio from disconnecting us on a keepalive timeout
   // Deliberately omitted:
   //   sub pan all  — panadapter/display data; the pan handle we need for SetBand
   //                  is included in the slice status (pan= key), so this is redundant
   //   sub spot all — DX spots handled by TR4W's own cluster connection
   //   client udpport — we do not consume VITA-49 UDP streams
   //   info / meter list — not used by TR4W
   SendFlexCmd('sub slice all');
   SendFlexCmd('sub tx all');
   SendFlexCmd('keepalive disable');
end;

// ---------------------------------------------------------------------------
// ProcessMsg: main entry point called by the reading thread for each received line.
// ---------------------------------------------------------------------------
procedure TFlexRadio6000.ProcessMsg(msg: string);
var
   line:   string;
   prefix: Char;
begin
   UpdateLastValidResponse;  // Must be first — prevents spurious 5-second disconnect timeout

   line := TrimRight(msg);   // Strip trailing CR left by ReadLn(#10)
   if Length(line) = 0 then
      begin
      Exit;
      end;

   logger.Trace('[FlexRadio6000.ProcessMsg] RX: (%s)', [line]);

   prefix := line[1];
   case prefix of
      'V':
         begin
         // V1.4.0.0 — radio firmware version
         logger.Info('[FlexRadio6000] Radio firmware: %s', [line]);
         end;

      'H':
         begin
         // H<hex> — client handle assigned by the radio
         FClientHandle := Copy(line, 2, Length(line) - 1);
         logger.Info('[FlexRadio6000] Client handle: %s', [FClientHandle]);
         if not FHandshakeDone then
            begin
            FHandshakeDone := True;
            SendSubscriptions;
            end;
         end;

      'M':
         begin
         // M<code>|<text> — informational message from radio
         logger.Info('[FlexRadio6000] Server message: %s', [line]);
         end;

      'R':
         begin
         // R<seq>|<result>|<data> — command response (result=0 is OK)
         ParseResponseLine(line);
         end;

      'S':
         begin
         // S<handle>|<type> key=value... — unsolicited status push
         ParseStatusLine(line);
         end;

   else
      begin
      logger.Warn('[FlexRadio6000.ProcessMsg] Unrecognised message prefix "%s": %s',
                  [prefix, line]);
      end;
   end;
end;

procedure TFlexRadio6000.ParseResponseLine(const line: string);
var
   resultStr: string;
   resultInt: integer;
begin
   // Format: R<seq>|<result>|<optional data>
   resultStr := SplitDelimiter(line, '|', 1);
   resultInt := StrToIntDef(resultStr, -1);
   if resultInt <> 0 then
      begin
      logger.Debug('[FlexRadio6000] Command error response: %s', [line]);
      end;
end;

procedure TFlexRadio6000.ParseStatusLine(const line: string);
var
   payload:  string;
   typeWord: string;
   spacePos: integer;
begin
   // Format: S<handle>|<type> <key=value...>
   payload := SplitDelimiter(line, '|', 1);
   if payload = '' then
      begin
      logger.Warn('[FlexRadio6000.ParseStatusLine] Missing payload in S-line: %s', [line]);
      Exit;
      end;

   spacePos := Pos(' ', payload);
   if spacePos = 0 then
      begin
      typeWord := payload;
      payload  := '';
      end
   else
      begin
      typeWord := Copy(payload, 1, spacePos - 1);
      payload  := Copy(payload, spacePos + 1, Length(payload) - spacePos);
      end;

   if typeWord = 'slice' then
      begin
      ProcessSliceStatus(payload);
      end
   else if typeWord = 'interlock' then
      begin
      ProcessInterlockStatus(payload);
      end
   else if typeWord = 'transmit' then
      begin
      ProcessTransmitStatus(payload);
      end
   else
      begin
      logger.Debug('[FlexRadio6000.ParseStatusLine] Ignoring status type: %s', [typeWord]);
      end;
end;

procedure TFlexRadio6000.ProcessSliceStatus(const payload: string);
var
   sliceNumStr: string;
   sliceNum:    integer;
   whichVFO:    TVFO;
   vfoObj:      TRadioVFO;
   freqStr:     string;
   modeStr:     string;
   ritOnStr:    string;
   ritFreqStr:  string;
   xitOnStr:    string;
   xitFreqStr:  string;
   txStr:       string;
   panStr:      string;
   mhzInt:      integer;
   mhzFrac:     integer;
   dotPos:      integer;
   fracStr:     string;
   freqHz:      integer;
   parsedMode:  TRadioMode;
begin
   // Payload: '<sliceNum> RF_frequency=<mhz> mode=<m> rit_on=<0/1> ...'
   sliceNumStr := SplitDelimiter(payload, ' ', 0);
   sliceNum    := StrToIntDef(sliceNumStr, -1);

   if sliceNum = 0 then
      begin
      whichVFO := nrVFOA;
      end
   else if sliceNum = 1 then
      begin
      whichVFO := nrVFOB;
      end
   else
      begin
      // Slices 2+ are used in advanced multi-slice setups; ignore silently
      logger.Debug('[FlexRadio6000.ProcessSliceStatus] Ignoring slice %d (only 0 and 1 handled)',
                   [sliceNum]);
      Exit;
      end;

   vfoObj := Self.vfo[whichVFO];

   // Frequency — Flex sends MHz with 6 decimal places, e.g. '14.156400'.
   // Use integer arithmetic to avoid locale decimal separator issues.
   freqStr := ParseKeyValue(payload, 'RF_frequency');
   if freqStr <> '' then
      begin
      dotPos := Pos('.', freqStr);
      if dotPos > 0 then
         begin
         mhzInt  := StrToIntDef(Copy(freqStr, 1, dotPos - 1), -1);
         fracStr := Copy(freqStr, dotPos + 1, 6);
         while Length(fracStr) < 6 do
            begin
            fracStr := fracStr + '0';
            end;
         mhzFrac := StrToIntDef(fracStr, -1);
         if (mhzInt >= 0) and (mhzFrac >= 0) then
            begin
            freqHz           := (mhzInt * 1000000) + mhzFrac;
            logger.Info('[FlexRadio6000] RF_frequency push: slice %d → %d Hz', [sliceNum, freqHz]);
            vfoObj.frequency := freqHz;
            vfoObj.band      := FreqToRadioBand(freqHz);
            end
         else
            begin
            logger.Warn('[FlexRadio6000.ProcessSliceStatus] Bad RF_frequency value: %s', [freqStr]);
            end;
         end
      else
         begin
         logger.Warn('[FlexRadio6000.ProcessSliceStatus] RF_frequency missing decimal: %s', [freqStr]);
         end;
      end;

   // Mode — only store if a real mode was returned; OFF/unknown returns rmNone
   // and must not overwrite the last good mode (OFF is a transient slice state)
   modeStr := ParseKeyValue(payload, 'mode');
   if modeStr <> '' then
      begin
      parsedMode := FlexModeToRadioMode(modeStr);
      if parsedMode <> rmNone then
         begin
         vfoObj.mode := parsedMode;
         end;
      end;

   // RIT
   ritOnStr := ParseKeyValue(payload, 'rit_on');
   if ritOnStr <> '' then
      begin
      vfoObj.RITState := ritOnStr = '1';
      end;

   ritFreqStr := ParseKeyValue(payload, 'rit_freq');
   if ritFreqStr <> '' then
      begin
      vfoObj.RITOffset := StrToIntDef(ritFreqStr, 0);
      end;

   // XIT
   xitOnStr := ParseKeyValue(payload, 'xit_on');
   if xitOnStr <> '' then
      begin
      vfoObj.XITState := xitOnStr = '1';
      end;

   xitFreqStr := ParseKeyValue(payload, 'xit_freq');
   if xitFreqStr <> '' then
      begin
      vfoObj.XITOffset := StrToIntDef(xitFreqStr, 0);
      end;

   // TX assignment — tracks which slice is transmitting for split detection
   txStr := ParseKeyValue(payload, 'tx');
   if txStr <> '' then
      begin
      if sliceNum = 0 then
         begin
         FSlice0TX := txStr = '1';
         end
      else
         begin
         FSlice1TX := txStr = '1';
         end;
      Self.localSplitEnabled := not FSlice0TX;
      end;

   // Pan handle (slice 0 only) — required for SetBand
   if sliceNum = 0 then
      begin
      panStr := ParseKeyValue(payload, 'pan');
      if (panStr <> '') and (panStr <> '0x00000000') then
         begin
         FPanHandle := panStr;
         logger.Debug('[FlexRadio6000.ProcessSliceStatus] Pan handle: %s', [FPanHandle]);
         end;
      end;
end;

procedure TFlexRadio6000.ProcessInterlockStatus(const payload: string);
var
   stateStr: string;
begin
   stateStr := ParseKeyValue(payload, 'state');
   if stateStr = 'TRANSMITTING' then
      begin
      Self.radioState := rsTransmit;
      logger.Debug('[FlexRadio6000] TX active');
      end
   else if (stateStr = 'READY') or (stateStr = 'RECEIVE') then
      begin
      Self.radioState := rsReceive;
      logger.Debug('[FlexRadio6000] RX active');
      end
   else if stateStr <> '' then
      begin
      logger.Debug('[FlexRadio6000.ProcessInterlockStatus] Interlock state: %s', [stateStr]);
      end;
end;

// ---------------------------------------------------------------------------
// ProcessTransmitStatus — handles 'S<handle>|transmit freq=<MHz> ...' pushes.
//
// After a 'slice tune' command, the FlexRadio sends a transmit-type status
// line (NOT a slice RF_frequency update) as the first confirmation.  We parse
// the freq= key and update VFO A so the TR4W display reflects the new frequency
// without waiting for a subsequent slice push.
//
// Limitation: In split mode the TX frequency differs from the RX frequency;
// this path updates VFO A (RX) from the TX freq push, which would be wrong.
// Split is not yet implemented, so this is safe for the current release.
// ---------------------------------------------------------------------------
procedure TFlexRadio6000.ProcessTransmitStatus(const payload: string);
var
   freqStr: string;
   dotPos:  integer;
   mhzInt:  integer;
   mhzFrac: integer;
   fracStr: string;
   freqHz:  integer;
begin
   freqStr := ParseKeyValue(payload, 'freq');
   if freqStr = '' then
      begin
      Exit;
      end;

   dotPos := Pos('.', freqStr);
   if dotPos = 0 then
      begin
      logger.Warn('[FlexRadio6000.ProcessTransmitStatus] freq value missing decimal: %s', [freqStr]);
      Exit;
      end;

   mhzInt  := StrToIntDef(Copy(freqStr, 1, dotPos - 1), -1);
   fracStr := Copy(freqStr, dotPos + 1, 6);
   while Length(fracStr) < 6 do
      begin
      fracStr := fracStr + '0';
      end;
   mhzFrac := StrToIntDef(fracStr, -1);

   if (mhzInt >= 0) and (mhzFrac >= 0) then
      begin
      freqHz := (mhzInt * 1000000) + mhzFrac;
      logger.Info('[FlexRadio6000] transmit freq push: %d Hz → updating VFO A', [freqHz]);
      // In non-split mode TX freq = RX freq; update VFO A so the display reflects
      // the tuned frequency immediately (before any subsequent slice push arrives).
      Self.vfo[nrVFOA].frequency := freqHz;
      Self.vfo[nrVFOA].band      := FreqToRadioBand(freqHz);
      end
   else
      begin
      logger.Warn('[FlexRadio6000.ProcessTransmitStatus] Bad freq value: %s', [freqStr]);
      end;
end;

// ---------------------------------------------------------------------------
// Mode mapping
// ---------------------------------------------------------------------------

function TFlexRadio6000.FlexModeToRadioMode(const sMode: string): TRadioMode;
begin
   // AnsiIndexText is case-insensitive, which makes this robust to firmware variations
   case AnsiIndexText(sMode, ['USB', 'LSB', 'CW', 'CWL', 'AM', 'SAM',
                               'FM', 'NFM', 'DFM', 'DIGU', 'DIGL', 'RTTY',
                               'OFF']) of
      0:  Result := rmUSB;
      1:  Result := rmLSB;
      2:  Result := rmCW;
      3:  Result := rmCWRev;
      4:  Result := rmAM;
      5:  Result := rmAM;      // SAM — Synchronous AM
      6:  Result := rmFM;
      7:  Result := rmFM;      // NFM — Narrow FM
      8:  Result := rmFM;      // DFM — Digital FM
      9:  Result := rmData;
      10: Result := rmDataRev;
      11: Result := rmFSK;     // RTTY
      12:
         begin
         // OFF = slice disabled or transitioning — do not overwrite last good mode
         logger.Debug('[FlexRadio6000.FlexModeToRadioMode] Slice mode is OFF (transitioning)');
         Result := rmNone;
         end;
   else
      begin
      logger.Warn('[FlexRadio6000.FlexModeToRadioMode] Unknown Flex mode string: "%s"', [sMode]);
      Result := rmNone;
      end;
   end;
end;

function TFlexRadio6000.RadioModeToFlexMode(mode: TRadioMode): string;
begin
   case mode of
      rmUSB:     Result := 'USB';
      rmLSB:     Result := 'LSB';
      rmCW:      Result := 'CW';
      rmCWRev:   Result := 'CWL';
      rmAM:      Result := 'AM';
      rmFM:      Result := 'FM';
      rmData:    Result := 'DIGU';
      rmDataRev: Result := 'DIGL';
      rmFSK:     Result := 'RTTY';
      rmFSKRev:  Result := 'RTTY';
   else
      begin
      logger.Warn('[FlexRadio6000.RadioModeToFlexMode] No Flex mapping for mode ordinal %d — defaulting to USB',
                  [Ord(mode)]);
      Result := 'USB';
      end;
   end;
end;

// ---------------------------------------------------------------------------
// SendToRadio — VFO-aware override (satisfies abstract contract from TNetRadioBase).
// Maps (whichVFO, key, value) to a slice set command.
// Most methods call SendFlexCmd directly for cleaner formatting.
// ---------------------------------------------------------------------------
procedure TFlexRadio6000.SendToRadio(whichVFO: TVFO; sCmd: string; sData: string);
begin
   SendFlexCmd(Format('slice set %d %s=%s', [SliceForVFO(whichVFO), sCmd, sData]));
end;

// ---------------------------------------------------------------------------
// Transmit / Receive
// ---------------------------------------------------------------------------

procedure TFlexRadio6000.Transmit;
begin
   SendFlexCmd('xmit 1');
end;

procedure TFlexRadio6000.Receive;
begin
   SendFlexCmd('xmit 0');
end;

// ---------------------------------------------------------------------------
// Frequency
// ---------------------------------------------------------------------------

procedure TFlexRadio6000.SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
begin
   // Frequency is set via "slice tune <index> <MHz>" — NOT "slice set RF_frequency".
   // RF_frequency is a read-only status key pushed by the radio; slice tune is the
   // write command.  Integer arithmetic avoids locale decimal separator issues.
   SendFlexCmd(Format('slice tune %d %d.%06d',
               [SliceForVFO(vfo), freq div 1000000, freq mod 1000000]));
   if mode <> rmNone then
      begin
      SetMode(mode, vfo);
      end;
end;

// ---------------------------------------------------------------------------
// Mode
// ---------------------------------------------------------------------------

procedure TFlexRadio6000.SetMode(mode: TRadioMode; vfo: TVFO = nrVFOA);
begin
   SendFlexCmd(Format('slice set %d mode=%s', [SliceForVFO(vfo), RadioModeToFlexMode(mode)]));
end;

function TFlexRadio6000.ToggleMode(vfo: TVFO = nrVFOA): TRadioMode;
begin
   logger.Warn('[FlexRadio6000.ToggleMode] Not yet implemented');
   Result := rmNone;
end;

// ---------------------------------------------------------------------------
// CW — not supported via TCP API
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// CW — SmartSDR CWX subsystem
//
// The radio maintains its own character queue.  TR4W follows the same
// buffer/flush pattern used by TK4Radio:
//   BufferCW  — appends characters to FCWBuffer (no radio contact yet)
//   SendCW    — flushes FCWBuffer to the radio via 'cwx send "<text>"'
//   StopCW    — cancels any queued/in-progress CW via 'cwx clear'
//
// Space encoding: SmartSDR uses ASCII 127 (DEL, \u007f) inside quoted
// cwx send strings to represent word-spaces, because a literal space
// would terminate the quoted token.  Any space in FCWBuffer is replaced
// before the command is sent.
//
// Speed range: SmartSDR accepts 5–100 WPM for 'cwx wpm'.  TR4W typically
// stays within 5–60 WPM, well inside that range.
// ---------------------------------------------------------------------------

procedure TFlexRadio6000.BufferCW(cwChars: string);
begin
   FCWBuffer := FCWBuffer + cwChars;
   logger.Info('[FlexRadio6000.BufferCW] Buffered: "%s"  total: "%s"',
               [cwChars, FCWBuffer]);
end;

procedure TFlexRadio6000.SendCW;
var
   encoded: string;
   i:       integer;
begin
   if FCWBuffer = '' then
      begin
      logger.Warn('[FlexRadio6000.SendCW] Buffer empty — nothing to send');
      Exit;
      end;

   // Replace spaces with char 127 (SmartSDR word-space encoding inside quotes)
   encoded := '';
   for i := 1 to Length(FCWBuffer) do
      begin
      if FCWBuffer[i] = ' ' then
         begin
         encoded := encoded + #127;
         end
      else
         begin
         encoded := encoded + FCWBuffer[i];
         end;
      end;

   logger.Info('[FlexRadio6000.SendCW] Sending CW: "%s"', [FCWBuffer]);
   SendFlexCmd('cwx send "' + encoded + '"');
   FCWBuffer := '';
end;

procedure TFlexRadio6000.StopCW;
begin
   FCWBuffer := '';
   SendFlexCmd('cwx clear');
end;

procedure TFlexRadio6000.SetCWSpeed(speed: integer);
begin
   Self.localCWSpeed := speed;
   SendFlexCmd(Format('cwx wpm %d', [speed]));
end;

// ---------------------------------------------------------------------------
// RIT
// ---------------------------------------------------------------------------

procedure TFlexRadio6000.RITOn(whichVFO: TVFO);
begin
   SendFlexCmd(Format('slice set %d rit_on=1', [SliceForVFO(whichVFO)]));
end;

procedure TFlexRadio6000.RITOff(whichVFO: TVFO);
begin
   SendFlexCmd(Format('slice set %d rit_on=0', [SliceForVFO(whichVFO)]));
end;

procedure TFlexRadio6000.RITClear(whichVFO: TVFO);
begin
   SendFlexCmd(Format('slice set %d rit_on=0 rit_freq=0', [SliceForVFO(whichVFO)]));
end;

procedure TFlexRadio6000.SetRITFreq(whichVFO: TVFO; hz: integer);
begin
   SendFlexCmd(Format('slice set %d rit_freq=%d', [SliceForVFO(whichVFO), hz]));
end;

procedure TFlexRadio6000.RITBumpDown;
begin
   SetRITFreq(nrVFOA, Self.vfo[nrVFOA].RITOffset - 10);
end;

procedure TFlexRadio6000.RITBumpUp;
begin
   SetRITFreq(nrVFOA, Self.vfo[nrVFOA].RITOffset + 10);
end;

// ---------------------------------------------------------------------------
// XIT
// ---------------------------------------------------------------------------

procedure TFlexRadio6000.XITOn(whichVFO: TVFO);
begin
   SendFlexCmd(Format('slice set %d xit_on=1', [SliceForVFO(whichVFO)]));
end;

procedure TFlexRadio6000.XITOff(whichVFO: TVFO);
begin
   SendFlexCmd(Format('slice set %d xit_on=0', [SliceForVFO(whichVFO)]));
end;

procedure TFlexRadio6000.XITClear(whichVFO: TVFO);
begin
   SendFlexCmd(Format('slice set %d xit_on=0 xit_freq=0', [SliceForVFO(whichVFO)]));
end;

procedure TFlexRadio6000.SetXITFreq(whichVFO: TVFO; hz: integer);
begin
   SendFlexCmd(Format('slice set %d xit_freq=%d', [SliceForVFO(whichVFO), hz]));
end;

// ---------------------------------------------------------------------------
// Split
// ---------------------------------------------------------------------------

procedure TFlexRadio6000.Split(splitOn: boolean);
begin
   // TODO: Implement split by reassigning the TX slice:
   //   Enable:  slice set 0 tx=0  +  slice set 1 tx=1
   //   Disable: slice set 0 tx=1  +  slice set 1 tx=0
   // Requires slice 1 to already exist in SmartSDR.  Deferred pending live testing.
   logger.Warn('[FlexRadio6000.Split] Split mode not yet implemented for FlexRadio 6000');
end;

// ---------------------------------------------------------------------------
// Band
// ---------------------------------------------------------------------------

procedure TFlexRadio6000.SetBand(band: TRadioBand; vfo: TVFO = nrVFOA);
var
   bandStr: string;
begin
   case band of
      rb160m: bandStr := '160m';
      rb80m:  bandStr := '80m';
      rb60m:  bandStr := '60m';
      rb40m:  bandStr := '40m';
      rb30m:  bandStr := '30m';
      rb20m:  bandStr := '20m';
      rb17m:  bandStr := '17m';
      rb15m:  bandStr := '15m';
      rb12m:  bandStr := '12m';
      rb10m:  bandStr := '10m';
      rb6m:   bandStr := '6m';
      rb2m:   bandStr := '2m';
      rb70cm: bandStr := '70cm';
   else
      begin
      logger.Error('[FlexRadio6000.SetBand] Unsupported band ordinal: %d', [Ord(band)]);
      Exit;
      end;
   end;

   if FPanHandle = '' then
      begin
      logger.Warn('[FlexRadio6000.SetBand] Pan handle not yet received from radio — band change ignored');
      Exit;
      end;

   // Band changes act on the panadapter, not the slice directly.
   // All slices sharing this panadapter will move to the new band.
   SendFlexCmd(Format('display pan set %s band=%s', [FPanHandle, bandStr]));
end;

function TFlexRadio6000.ToggleBand(vfo: TVFO = nrVFOA): TRadioBand;
begin
   logger.Warn('[FlexRadio6000.ToggleBand] Not yet implemented');
   Result := rbNone;
end;

// ---------------------------------------------------------------------------
// Filter
// ---------------------------------------------------------------------------

procedure TFlexRadio6000.SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA);
var
   sliceNum: integer;
   loHz:     integer;
   hiHz:     integer;
begin
   sliceNum := SliceForVFO(vfo);
   case filter of
      rfNarrow:
         begin
         loHz := -500;
         hiHz := 500;
         end;
      rfMid:
         begin
         loHz := -1500;
         hiHz := 1500;
         end;
      rfWide:
         begin
         loHz := -3000;
         hiHz := 3000;
         end;
   else
      begin
      loHz := -1500;
      hiHz := 1500;
      end;
   end;
   SendFlexCmd(Format('slice set %d filt_lo=%d filt_hi=%d', [sliceNum, loHz, hiHz]));
end;

function TFlexRadio6000.SetFilterHz(hz: integer; vfo: TVFO = nrVFOA): integer;
var
   sliceNum: integer;
   halfHz:   integer;
begin
   sliceNum := SliceForVFO(vfo);
   halfHz   := hz div 2;
   SendFlexCmd(Format('slice set %d filt_lo=%d filt_hi=%d', [sliceNum, -halfHz, halfHz]));
   Result := hz;
end;

// ---------------------------------------------------------------------------
// VFO tuning steps — Flex has no single-step bump command, so we read/increment
// ---------------------------------------------------------------------------

procedure TFlexRadio6000.VFOBumpDown(whichVFO: TVFO);
begin
   SetFrequency(Self.vfo[whichVFO].frequency - 10, whichVFO, rmNone);
end;

procedure TFlexRadio6000.VFOBumpUp(whichVFO: TVFO);
begin
   SetFrequency(Self.vfo[whichVFO].frequency + 10, whichVFO, rmNone);
end;

// ---------------------------------------------------------------------------
// Memory keyer — not applicable via TCP API
// ---------------------------------------------------------------------------

function TFlexRadio6000.MemoryKeyer(mem: integer): boolean;
begin
   logger.Warn('[FlexRadio6000.MemoryKeyer] Not supported on FlexRadio 6000 via TCP API');
   Result := True;  // True = error (fail-closed, matching K4 convention)
end;

end.
