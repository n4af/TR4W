unit uRadioKenwoodTS890;

{
  Kenwood TS-890S network radio support.

  Issue #436. Implements direct TCP/IP control of the TS-890S over its
  built-in LAN port. The wire protocol is the standard Kenwood ASCII CAT
  (semicolon-terminated commands such as FA;, FB;, OM0;, KS;, RC;) wrapped
  in a TCP stream, preceded by a three-step authentication handshake:

      Client                          Radio
      ------                          -----
      ##CN;                  -------->
                             <-------- ##CN1;
      ##ID0<idLen><pwLen><id><pw>; --->
                             <-------- ##ID1;   (auth success)

  After ##ID1; the connection becomes a plain Kenwood CAT byte stream.

  References:
    - Kenwood TS-890S PC Command Reference (Rev. 1)
      https://www.kenwood.com/i/products/info/amateur/pdf/ts890_pc_command_en_rev1.pdf
    - TR4QT TS890Radio C++ implementation
      https://github.com/ny4i/TR4QT/blob/master/docs/kenwood-direct-connection-flow.md

  Credentials (NetworkUsername / NetworkPassword) are set by
  RadioObject.SetUpRadioInterface in LOGRADIO.PAS after the factory
  constructs the instance. If NetworkUsername is empty, the auth
  handshake is skipped (useful for a future simulator path).
}

interface
uses uNetRadioBase, uRadioBand, StrUtils, SysUtils, Math, TF, Log4D, VC;

type
   TTS890AuthState = (
      ksNone,
      ksWaitingForCN,    // Sent ##CN;, awaiting ##CN1
      ksWaitingForID,    // Sent ##ID0...;, awaiting ##ID1
      ksWaitingForTI,    // legacy/unused: real TS-890 does NOT send ##UE/##TI; auth completes at ##ID1
      ksAuthenticated,   // Auth complete; normal Kenwood CAT
      ksAuthFailed       // Auth was rejected; connection unusable
   );

type TKenwoodTS890Radio = class(TNetRadioBase)
   private
      CWBuffer: string;
      FAuthState: TTS890AuthState;
      FInitialized: Boolean;
      logger: TLogLogger;

      procedure SendAuthCredentials;
      procedure SendPostLoginSetup;
      procedure HandleAuthMessage(const sMessage: string);
      procedure InitializeAfterAuth;
      function ModeCharToMode(ch: Char): TRadioMode;
      function ModeToModeChar(mode: TRadioMode): Char;
      procedure ParseFAOrFBResponse(const sMessage: string; whichVFO: TVFO);
      procedure ParseOMResponse(const sMessage: string);
      procedure ParseKSResponse(const sMessage: string);
      procedure ParseTBResponse(const sMessage: string);
      procedure ParseFTResponse(const sMessage: string);
      procedure ParseRTResponse(const sMessage: string);
      procedure ParseXTResponse(const sMessage: string);
      procedure ParseRFResponse(const sMessage: string);

   public
      NetworkUsername: ShortString;   // Set by LOGRADIO before Connect; "Admin ID" on the radio
      NetworkPassword: ShortString;   // "Admin Password" on the radio

      Constructor Create;
      Destructor  Destroy; override;

      function  Connect: integer; override;
      procedure ProcessMessage(sMessage: string);
      procedure ProcessMsg(msg: string); override;

      // Auto-info / polling
      procedure PollRadioState; override;

      // Required abstract overrides
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
      procedure SetRITFreq(whichVFO: TVFO; hz: integer); override;
      procedure SetXITFreq(whichVFO: TVFO; hz: integer); override;

      procedure Split(splitOn: boolean); override;
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

const
   // TS-890 CW speed range per the PC Command Reference (KS command, P1 = 004..060)
   MIN_CW_SPEED = 4;
   MAX_CW_SPEED = 60;

// ============================================================================
// Constructor / Destructor
// ============================================================================

Constructor TKenwoodTS890Radio.Create;
begin
   inherited Create(ProcessMessage);

   logger := TLogLogger.GetLogger('TR4WDebugLog.TS890-Radio');

   FAuthState   := ksNone;
   FInitialized := False;
   CWBuffer     := '';
   NetworkUsername := '';
   NetworkPassword := '';

   // The TS-890 LAN CAT parser rejects a trailing CR/LF (responds '?;') once
   // authenticated, so send bare ';'-terminated commands. (Proven via telnet:
   // the K4 ignores a trailing CR/LF; the TS-890 does not. The default is set
   // in uNetRadioBase.Create -- see SendToRadio / bAddTermination.)
   Self.bAddTermination := False;

   // TS-890 uses AI2 for state push, but the LAN protocol REQUIRES
   // periodic traffic from the client. Per the LAN HOWTO:
   //   "The TS-890 will close the TCP connection if it does not receive
   //    any data for 10 seconds. ... send the PS; command every 5 seconds"
   // (This is what Kenwood's own ARCP software does.)
   // So we poll PS; at 5-second intervals purely as a keepalive heartbeat;
   // the response is discarded. Without this, the radio drops us ~10s
   // after auth completes and any AI2 push state stops arriving.
   requiresPolling := True;
   autoUpdateCommand := 'AI2;';
   pollingInterval := 5000;
end;

Destructor TKenwoodTS890Radio.Destroy;
begin
   inherited;
end;

// ============================================================================
// Connect / Auth
// ============================================================================

function TKenwoodTS890Radio.Connect: integer;
begin
   Self.readTerminator := ';';

   // Set initial auth state BEFORE TCP connect: when the socket is up and
   // ProcessMessage starts receiving bytes, we already know we are in the
   // auth phase. If the operator never set credentials (empty NetworkUsername),
   // skip auth entirely and go straight to initialization.
   if Length(NetworkUsername) > 0 then
      FAuthState := ksWaitingForCN
   else
      FAuthState := ksAuthenticated;

   Result := Inherited Connect;

   if Self.IsConnected then
      begin
      if FAuthState = ksWaitingForCN then
         begin
         logger.Info('[%s.Connect] TCP connected; starting LAN auth (user=%s)',
                     [Self.rigLabel, NetworkUsername]);
         Self.SendToRadio('##CN;');
         end
      else
         begin
         logger.Info('[%s.Connect] TCP connected; no credentials set, skipping auth',
                     [Self.rigLabel]);
         InitializeAfterAuth;
         end;
      end;
end;

procedure TKenwoodTS890Radio.SendAuthCredentials;
var
   idLen, pwLen: Integer;
   cmd: string;
begin
   idLen := Length(NetworkUsername);
   pwLen := Length(NetworkPassword);

   // Format: ##ID0<idLen:2><pwLen:2><id><pw>;
   // idLen and pwLen are two-digit decimal counts.
   cmd := Format('##ID0%.2d%.2d%s%s;',
                 [idLen, pwLen, string(NetworkUsername), string(NetworkPassword)]);

   FAuthState := ksWaitingForID;
   Self.SendToRadio(cmd);

   // Log the framing without exposing the password.
   logger.Debug('[%s.SendAuthCredentials] Sent ##ID0%.2d%.2d%s******* (pw masked)',
                [Self.rigLabel, idLen, pwLen, string(NetworkUsername)]);
end;

procedure TKenwoodTS890Radio.SendPostLoginSetup;
begin
   // Post-login LAN-session setup the ARCP-890 reference controller sends right
   // after ##ID1; (##VP = version/voice-protocol probe, ##KN = LAN notification
   // channels). Match the reference so the radio keeps the socket open and
   // pushes state over LAN. Responses (##VP0;/##KN21;/##KN02;) are ignored in
   // HandleAuthMessage once authenticated.
   Self.SendToRadio('##VP;');
   Self.SendToRadio('##KN2;');
   Self.SendToRadio('##KN0;');
   logger.Debug('[%s.SendPostLoginSetup] Sent ##VP; ##KN2; ##KN0;', [Self.rigLabel]);
end;

procedure TKenwoodTS890Radio.HandleAuthMessage(const sMessage: string);
begin
   if FAuthState = ksWaitingForCN then
      begin
      if AnsiStartsStr('##CN1', sMessage) then
         begin
         logger.Debug('[%s.HandleAuthMessage] Received ##CN1; sending credentials',
                      [Self.rigLabel]);
         SendAuthCredentials;
         end
      else
         begin
         logger.Warn('[%s.HandleAuthMessage] Unexpected response while waiting for ##CN1: %s',
                     [Self.rigLabel, sMessage]);
         end;
      Exit;
      end;

   if FAuthState = ksWaitingForID then
      begin
      if AnsiStartsStr('##ID1', sMessage) then
         begin
         // ##ID1; = auth success. Real-hardware capture (Kenwood ARCP-890 vs a
         // TS-890S) shows the radio does NOT send ##UE/##TI here -- the
         // controller drives the rest (##VP; / ##KN2; / ##KN0;) and plain CAT
         // (ID;) already works immediately after ##ID1;. The previous
         // "wait for ##TI" left TR4W idle, so the radio closed the socket and
         // we reconnected in a loop. Go straight to CAT.
         FAuthState := ksAuthenticated;
         logger.Info('[%s.HandleAuthMessage] Credentials accepted; CAT-ready',
                     [Self.rigLabel]);
         SendPostLoginSetup;
         InitializeAfterAuth;
         end
      else
         begin
         FAuthState := ksAuthFailed;
         logger.Error('[%s.HandleAuthMessage] AUTH FAILED -- radio responded: %s',
                      [Self.rigLabel, sMessage]);
         end;
      Exit;
      end;

   if FAuthState = ksAuthenticated then
      begin
      // Post-auth ## frames are LAN-control responses/notifications:
      //   ##VP0;/##VP1; (replies to ##VP;), ##KN21;/##KN02;/##KN71; (##KN),
      //   and on some firmwares ##UE;/##TI;. None require action -- the CAT
      //   session is already running -- so just log and ignore them.
      logger.Debug('[%s.HandleAuthMessage] post-auth control frame (ignored): %s',
                   [Self.rigLabel, sMessage]);
      Exit;
      end;
end;

procedure TKenwoodTS890Radio.InitializeAfterAuth;
begin
   if FInitialized then Exit;
   FInitialized := True;

   logger.Info('[%s.InitializeAfterAuth] Sending TS-890 init sequence', [Self.rigLabel]);

   // Enable Auto-Information mode 2 -- the radio will push frequency, mode,
   // split, and other state changes without further polling.
   Self.SendToRadio('AI2;');

   // Prime our cached state with explicit queries.
   Self.SendToRadio('FA;');     // VFO A frequency
   Self.SendToRadio('FB;');     // VFO B frequency
   Self.SendToRadio('OM0;');    // VFO A mode
   Self.SendToRadio('OM1;');    // VFO B mode
   Self.SendToRadio('KS;');     // CW keyer speed
   Self.SendToRadio('TB;');     // Split (TX/RX VFO)
   Self.SendToRadio('FT;');     // TX VFO selection
   Self.SendToRadio('RT;');     // RIT state
   Self.SendToRadio('XT;');     // XIT state
   Self.SendToRadio('ID;');     // Radio identity (expect ID024;)

   Self.UpdateLastValidResponse;
end;

// ============================================================================
// Message Dispatch
// ============================================================================

procedure TKenwoodTS890Radio.ProcessMessage(sMessage: string);
begin
   if sMessage = '' then Exit;

   // Refresh the disconnect watchdog -- any well-formed reply means the
   // radio is alive, even pre-auth handshake bytes.
   Self.UpdateLastValidResponse;

   // Auth-phase frames begin with "##".
   if AnsiStartsStr('##', sMessage) then
      begin
      HandleAuthMessage(sMessage);
      Exit;
      end;

   // Anything else received before auth completes is bytes from a previous
   // session or garbage -- ignore until ##ID1; has been received.
   if FAuthState <> ksAuthenticated then
      begin
      logger.Trace('[%s.ProcessMessage] Pre-auth byte stream ignored: %s',
                   [Self.rigLabel, sMessage]);
      Exit;
      end;

   // ----- Authenticated: normal Kenwood CAT replies follow -----
   // Replies are typically 2-character command + data + ';'. The semicolon
   // was already stripped by the reading thread (we set readTerminator).
   if AnsiStartsStr('FA', sMessage) then
      ParseFAOrFBResponse(sMessage, nrVFOA)
   else if AnsiStartsStr('FB', sMessage) then
      ParseFAOrFBResponse(sMessage, nrVFOB)
   else if AnsiStartsStr('OM', sMessage) then
      ParseOMResponse(sMessage)
   else if AnsiStartsStr('KS', sMessage) then
      ParseKSResponse(sMessage)
   else if AnsiStartsStr('TB', sMessage) then
      ParseTBResponse(sMessage)
   else if AnsiStartsStr('FT', sMessage) then
      ParseFTResponse(sMessage)
   else if AnsiStartsStr('RT', sMessage) then
      ParseRTResponse(sMessage)
   else if AnsiStartsStr('XT', sMessage) then
      ParseXTResponse(sMessage)
   else if AnsiStartsStr('RF', sMessage) then
      // RIT/XIT frequency offset, pushed unsolicited under AI2 as the knob turns.
      ParseRFResponse(sMessage)
   else if AnsiStartsStr('TX', sMessage) then
      // Radio pushes TX0; when it goes to transmit (AI2). Surface it so the
      // main window's TX indicator updates.
      Self.SetTransmitting(True)
   else if AnsiStartsStr('RX', sMessage) then
      Self.SetTransmitting(False)
   else if AnsiStartsStr('PS', sMessage) then
      // Keepalive heartbeat response (PS1; = power on). No state to track;
      // the round-trip itself is what keeps the LAN connection from being
      // dropped by the radio's 10-second idle timeout.
      logger.Trace('[%s.ProcessMessage] Keepalive ack: %s', [Self.rigLabel, sMessage])
   else if AnsiStartsStr('ID', sMessage) then
      begin
      // ID024 = TS-890S. Anything else means we connected to the wrong radio.
      if AnsiStartsStr('ID024', sMessage) then
         logger.Info('[%s.ProcessMessage] Confirmed TS-890S (ID024)', [Self.rigLabel])
      else
         logger.Warn('[%s.ProcessMessage] Unexpected ID response: %s',
                     [Self.rigLabel, sMessage]);
      end
   else
      begin
      logger.Trace('[%s.ProcessMessage] Unhandled reply: %s', [Self.rigLabel, sMessage]);
      end;
end;

procedure TKenwoodTS890Radio.ProcessMsg(msg: string);
begin
   ProcessMessage(msg);
end;

// ============================================================================
// Reply Parsers
// ============================================================================

procedure TKenwoodTS890Radio.ParseFAOrFBResponse(const sMessage: string; whichVFO: TVFO);
var
   freqStr: string;
   freqVal: Int64;
   convErr: Integer;
begin
   // Format: FA<11-digit Hz>;  or  FB<11-digit Hz>;  Semicolon already removed.
   if Length(sMessage) < 13 then
      begin
      logger.Warn('[%s.ParseFAOrFBResponse] Short freq reply: %s',
                  [Self.rigLabel, sMessage]);
      Exit;
      end;

   freqStr := Copy(sMessage, 3, 11);
   Val(freqStr, freqVal, convErr);
   if convErr <> 0 then
      begin
      logger.Warn('[%s.ParseFAOrFBResponse] Non-numeric freq: %s',
                  [Self.rigLabel, freqStr]);
      Exit;
      end;

   Self.vfo[whichVFO].frequency := freqVal;
   // Derive and store the band from the reported frequency. Without this,
   // vfo[].band stays NoBand -> GetBand returns NoBand -> FilteredStatus.Band
   // is NoBand -> ProcessFilteredStatus (uRadioPolling ~3161) skips the whole
   // ActiveBand/ActiveMode/DisplayBandMode update, so the main-window
   // band-above-freq, the band table, AND the mode never follow the radio
   // (only the frequency updates, via a separate path). The Kenwood reports a
   // frequency rather than a band number, so we derive it; the K4 sets
   // vfo[].band for exactly the same reason.
   if Self.vfo[whichVFO].frequency > 0 then
      Self.vfo[whichVFO].band := FreqToRadioBand(Self.vfo[whichVFO].frequency);
   logger.Trace('[%s.ParseFAOrFBResponse] %s = %d Hz (band %d)',
                [Self.rigLabel, VFOToString(whichVFO), freqVal,
                 Ord(Self.vfo[whichVFO].band)]);
end;

procedure TKenwoodTS890Radio.ParseOMResponse(const sMessage: string);
var
   vfoChar, modeChar: Char;
   whichVFO: TVFO;
begin
   // Format: OM<vfoChar><modeChar>;  vfoChar = '0' (VFO A) or '1' (VFO B).
   if Length(sMessage) < 4 then
      begin
      logger.Warn('[%s.ParseOMResponse] Short OM reply: %s', [Self.rigLabel, sMessage]);
      Exit;
      end;

   vfoChar  := sMessage[3];
   modeChar := sMessage[4];

   case vfoChar of
      '0': whichVFO := nrVFOA;
      '1': whichVFO := nrVFOB;
   else
      logger.Warn('[%s.ParseOMResponse] Unexpected VFO char in: %s',
                  [Self.rigLabel, sMessage]);
      Exit;
   end;

   Self.vfo[whichVFO].mode := ModeCharToMode(modeChar);
   logger.Trace('[%s.ParseOMResponse] %s mode = %s (char %s)',
                [Self.rigLabel, VFOToString(whichVFO),
                 Self.ModeToString(Self.vfo[whichVFO].mode), modeChar]);
end;

procedure TKenwoodTS890Radio.ParseKSResponse(const sMessage: string);
var
   wpmStr: string;
   wpmVal: Integer;
   convErr: Integer;
begin
   // Format: KS<3-digit WPM>;
   if Length(sMessage) < 5 then Exit;
   wpmStr := Copy(sMessage, 3, 3);
   Val(wpmStr, wpmVal, convErr);
   if convErr = 0 then
      begin
      Self.localCWSpeed := wpmVal;
      logger.Trace('[%s.ParseKSResponse] CW speed = %d wpm', [Self.rigLabel, wpmVal]);
      end;
end;

// Format: TB<0|1>;  -- 0 = split off, 1 = split on.
// TS-890 Split is a global on/off flag separate from FR/FT VFO selection.
procedure TKenwoodTS890Radio.ParseTBResponse(const sMessage: string);
begin
   if Length(sMessage) < 3 then Exit;
   Self.SetSplitOn(sMessage[3] = '1');   // base setter -> localSplitEnabled the window reads
   logger.Trace('[%s.ParseTBResponse] Split = %s',
                [Self.rigLabel, BoolToStr(Self.localSplitEnabled, True)]);
end;

// Format: FT<0|1>;  -- 0 = VFO A is TX, 1 = VFO B is TX.
// We don't track an explicit TX VFO field today; surface it in the log so the
// state is at least visible. Wire it into TNetRadioBase when split-VFO support
// gets fleshed out.
procedure TKenwoodTS890Radio.ParseFTResponse(const sMessage: string);
begin
   if Length(sMessage) < 3 then Exit;
   logger.Trace('[%s.ParseFTResponse] TX VFO = %s',
                [Self.rigLabel, IfThen(sMessage[3] = '1', 'B', 'A')]);
end;

// Format: RT<0|1>;  -- 0 = RIT off, 1 = RIT on.
procedure TKenwoodTS890Radio.ParseRTResponse(const sMessage: string);
begin
   if Length(sMessage) < 3 then Exit;
   Self.SetRITOn(sMessage[3] = '1');   // base setter -> per-VFO RITState the window reads
   logger.Trace('[%s.ParseRTResponse] RIT = %s',
                [Self.rigLabel, BoolToStr(Self.RITState, True)]);
end;

// Format: XT<0|1>;  -- 0 = XIT off, 1 = XIT on.
procedure TKenwoodTS890Radio.ParseXTResponse(const sMessage: string);
begin
   if Length(sMessage) < 3 then Exit;
   Self.SetXITOn(sMessage[3] = '1');   // base setter -> per-VFO XITState the window reads
   logger.Trace('[%s.ParseXTResponse] XIT = %s',
                [Self.rigLabel, BoolToStr(Self.XITState, True)]);
end;

// Format: RF<P1><P2P2P2P2>;  P1 = direction (0 = +, 1 = -), P2 = 4-digit RIT/XIT
// offset in Hz (0000-9999), e.g. RF10030 = -30 Hz, RF00000 = centered.  The
// TS-890 pushes this UNSOLICITED under AI2 as the RIT/XIT knob turns -- validated
// against N2SKH's capture: 276 RF frames from the radio, zero client RF; queries.
// So there is nothing to poll; we just stop discarding the frames we already
// receive.  Stored as the active VFO's RIT offset; the polling bridge copies
// vfo[].RITOffset -> CurrentStatus.RITFreq, which the main window displays.
// (RIT/XIT on/off arrive separately as RT;/XT; -- see ParseRT/XTResponse.)
procedure TKenwoodTS890Radio.ParseRFResponse(const sMessage: string);
var
   magVal, convErr, offset: Integer;
begin
   // "RF" + direction(1) + 4 digits => 7 chars minimum (semicolon already stripped).
   if Length(sMessage) < 7 then
      begin
      logger.Warn('[%s.ParseRFResponse] Short RF reply: %s', [Self.rigLabel, sMessage]);
      Exit;
      end;

   Val(Copy(sMessage, 4, 4), magVal, convErr);   // P2: 4-digit magnitude in Hz
   if convErr <> 0 then
      begin
      logger.Warn('[%s.ParseRFResponse] Non-numeric RF offset: %s',
                  [Self.rigLabel, sMessage]);
      Exit;
      end;

   offset := magVal;
   if sMessage[3] = '1' then          // P1 = 1 => minus direction
      offset := -offset;

   Self.vfo[nrVFOA].RITOffset := offset;
   logger.Trace('[%s.ParseRFResponse] RIT/XIT offset = %d Hz', [Self.rigLabel, offset]);
end;

// ============================================================================
// Mode mapping (TS-890 PC Command Reference, OM command P2 values)
// ============================================================================

function TKenwoodTS890Radio.ModeCharToMode(ch: Char): TRadioMode;
begin
   // 1=LSB 2=USB 3=CW 4=FM 5=AM 6=FSK 7=CW-R 9=FSK-R
   // A=PSK B=PSK-R C=LSB-DATA D=USB-DATA E=FM-DATA F=AM-DATA
   case ch of
      '1':      Result := rmLSB;
      '2':      Result := rmUSB;
      '3':      Result := rmCW;
      '4':      Result := rmFM;
      '5':      Result := rmAM;
      '6':      Result := rmFSK;
      '7':      Result := rmCWRev;
      '9':      Result := rmFSKRev;
      'A', 'a': Result := rmPSK;
      'B', 'b': Result := rmPSKRev;
      'C', 'c': Result := rmData;        // LSB-DATA
      'D', 'd': Result := rmData;        // USB-DATA
      'E', 'e': Result := rmData;        // FM-DATA
      'F', 'f': Result := rmData;        // AM-DATA
   else
      logger.Warn('[%s.ModeCharToMode] Unknown OM mode char "%s"', [Self.rigLabel, ch]);
      Result := rmNone;
   end;
end;

function TKenwoodTS890Radio.ModeToModeChar(mode: TRadioMode): Char;
begin
   case mode of
      rmLSB:    Result := '1';
      rmUSB:    Result := '2';
      rmCW:     Result := '3';
      rmFM:     Result := '4';
      rmAM:     Result := '5';
      rmFSK:    Result := '6';
      rmCWRev:  Result := '7';
      rmFSKRev: Result := '9';
      rmPSK:    Result := 'A';
      rmPSKRev: Result := 'B';
      rmData:   Result := 'D';           // Default DATA to USB-DATA
      rmDataRev:Result := 'C';           // Reverse DATA = LSB-DATA
   else
      logger.Warn('[%s.ModeToModeChar] No TS-890 OM code for mode %d', [Self.rigLabel, Ord(mode)]);
      Result := #0;
   end;
end;

// ============================================================================
// Polling (only used if requiresPolling is True; we use AI2 instead)
// ============================================================================

procedure TKenwoodTS890Radio.PollRadioState;
begin
   if FAuthState <> ksAuthenticated then Exit;
   // LAN-only requirement: the TS-890 closes the TCP connection if it
   // receives nothing from us for 10 seconds. ARCP and other Kenwood-
   // documented clients send PS; every 5 seconds as a heartbeat. The
   // response is just PS1; (power on) and is discarded. AI2 pushes
   // everything else, so this is keepalive only -- no real polling.
   Self.SendToRadio('PS;');
end;

// ============================================================================
// Transmit / Receive
// ============================================================================

procedure TKenwoodTS890Radio.Transmit;
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('TX;');
end;

procedure TKenwoodTS890Radio.Receive;
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('RX;');
end;

// ============================================================================
// CW (KY buffer-based, identical idiom to K4 / TS-990)
// ============================================================================

procedure TKenwoodTS890Radio.BufferCW(cwChars: string);
begin
   Self.CWBuffer := Self.CWBuffer + cwChars;
end;

procedure TKenwoodTS890Radio.SendCW;
begin
   if FAuthState <> ksAuthenticated then Exit;
   if Self.CWBuffer = '' then Exit;
   Self.SendToRadio('KY ' + Self.CWBuffer + ';');
   Self.CWBuffer := '';
end;

procedure TKenwoodTS890Radio.StopCW;
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('KY0;RX;');
end;

// ============================================================================
// Frequency / Mode
// ============================================================================

procedure TKenwoodTS890Radio.SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
var sCmd: string;
begin
   if FAuthState <> ksAuthenticated then Exit;

   case vfo of
      nrVFOA: sCmd := 'FA';
      nrVFOB: sCmd := 'FB';
   else
      logger.Error('[%s.SetFrequency] Invalid VFO', [Self.rigLabel]);
      Exit;
   end;
   Self.SendToRadio(Format('%s%.11d;', [sCmd, freq]));

   if mode <> rmNone then
      Self.SetMode(mode, vfo);
end;

procedure TKenwoodTS890Radio.SetMode(mode: TRadioMode; vfo: TVFO = nrVFOA);
var
   modeChar: Char;
   vfoChar: Char;
begin
   if FAuthState <> ksAuthenticated then Exit;

   modeChar := ModeToModeChar(mode);
   if modeChar = #0 then Exit;

   // KENWOOD QUIRK: per the TS-890 PC Command Reference, the OM command's
   // P1 (VFO) byte is "ignored with the setting command" -- the radio always
   // applies the mode to the currently active VFO. We still emit a P1 byte
   // to match the documented command shape, but SetMode(mode, nrVFOB) when
   // VFO A is the active VFO will NOT change VFO B's mode; the radio will
   // change VFO A's mode instead. Setting the inactive VFO's mode would
   // require swap-VFO -> OM -> swap-VFO-back; not implemented (TR4W's
   // contest flow operates on the active VFO, so this is acceptable).
   case vfo of
      nrVFOA: vfoChar := '0';
      nrVFOB: vfoChar := '1';
   else
      Exit;
   end;
   Self.SendToRadio(Format('OM%s%s;', [vfoChar, modeChar]));
end;

function TKenwoodTS890Radio.ToggleMode(vfo: TVFO): TRadioMode;
begin
   // Not implemented; TS-890 has no single-shot mode-toggle command.
   Result := rmNone;
end;

procedure TKenwoodTS890Radio.SetCWSpeed(speed: integer);
begin
   if FAuthState <> ksAuthenticated then Exit;
   if not IntegerBetween(speed, MIN_CW_SPEED, MAX_CW_SPEED) then
      begin
      logger.Error('[%s.SetCWSpeed] TS-890 CW range is %d..%d wpm (got %d)',
                   [Self.rigLabel, MIN_CW_SPEED, MAX_CW_SPEED, speed]);
      Exit;
      end;
   Self.localCWSpeed := speed;
   Self.SendToRadio(Format('KS%.3d;', [speed]));
end;

// ============================================================================
// RIT / XIT
// ============================================================================

procedure TKenwoodTS890Radio.RITClear(whichVFO: TVFO);
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('RC;');
end;

procedure TKenwoodTS890Radio.XITClear(whichVFO: TVFO);
begin
   if FAuthState <> ksAuthenticated then Exit;
   // TS-890 shares the offset between RIT and XIT; clearing RC also clears XIT.
   Self.SendToRadio('RC;');
end;

procedure TKenwoodTS890Radio.RITBumpDown;
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('RD;');
end;

procedure TKenwoodTS890Radio.RITBumpUp;
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('RU;');
end;

procedure TKenwoodTS890Radio.RITOn(whichVFO: TVFO);
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('RT1;');
end;

procedure TKenwoodTS890Radio.RITOff(whichVFO: TVFO);
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('RT0;');
end;

procedure TKenwoodTS890Radio.XITOn(whichVFO: TVFO);
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('XT1;');
end;

procedure TKenwoodTS890Radio.XITOff(whichVFO: TVFO);
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('XT0;');
end;

procedure TKenwoodTS890Radio.SetRITFreq(whichVFO: TVFO; hz: integer);
var
   magnitude: Integer;
begin
   if FAuthState <> ksAuthenticated then Exit;

   // TS-890 sets a specific RIT/XIT offset in two steps:
   //   1. Clear the current offset:           RC;
   //   2. Apply magnitude with direction:
   //         RU<nnnnn>;   for a positive offset (RIT up)
   //         RD<nnnnn>;   for a negative offset (RIT down)
   //      where nnnnn is the 5-digit Hz value in the range 00000..09999.
   // The RIT and XIT offsets share one value on the TS-890; setting one
   // changes the other. XITClear / SetXITFreq route through here.
   //
   // When hz exceeds +-9999 we silently clamp to 9999. The TR4W RIT shift
   // keys are press-repeatedly UI affordances; once at the radio's limit,
   // further presses are no-ops, no warning needed.
   Self.SendToRadio('RC;');
   if hz = 0 then Exit;

   magnitude := Abs(hz);
   if magnitude > 9999 then
      magnitude := 9999;

   if hz > 0 then
      Self.SendToRadio(Format('RU%.5d;', [magnitude]))
   else
      Self.SendToRadio(Format('RD%.5d;', [magnitude]));
end;

procedure TKenwoodTS890Radio.SetXITFreq(whichVFO: TVFO; hz: integer);
begin
   // TS-890 has one shared RIT/XIT offset; setting XIT uses the same
   // RC + RU/RD command sequence as RIT.
   Self.SetRITFreq(whichVFO, hz);
end;

// ============================================================================
// Split / Band / Filter (stubs -- to be expanded in follow-up commits)
// ============================================================================

procedure TKenwoodTS890Radio.Split(splitOn: boolean);
begin
   if FAuthState <> ksAuthenticated then Exit;
   if splitOn then
      Self.SendToRadio('FT1;')   // TX = VFO B
   else
      Self.SendToRadio('FT0;');  // TX = VFO A (split off)
end;

procedure TKenwoodTS890Radio.SetBand(band: TRadioBand; vfo: TVFO = nrVFOA);
begin
   if FAuthState <> ksAuthenticated then Exit;
   // The TS-890 changes band via a frequency set, so route through SetFrequency.
   Self.SetFrequency(Self.BandToFreq(band), vfo, rmNone);
end;

function TKenwoodTS890Radio.ToggleBand(vfo: TVFO): TRadioBand;
begin
   Result := Self.band[vfo];
end;

procedure TKenwoodTS890Radio.SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA);
begin
   if FAuthState <> ksAuthenticated then Exit;

   // TS-890 has 3 receive filter slots, A / B / C, selected via the FL0
   // command (P1 = 0/1/2). The bandwidth of each slot is user-configurable
   // in the radio's menu; by convention A is the narrowest and C the widest,
   // so we map rfNarrow/Mid/Wide -> A/B/C.
   //
   // Caveat: the radio rejects FL02; (filter C) when menu [6-10]
   // ("RX Filter Numbers") is set to "2", meaning the operator has restricted
   // their radio to two filter slots. We don't pre-query that menu setting
   // here; if the radio NAKs, the polling thread will log it at trace level.
   case filter of
      rfNarrow: Self.SendToRadio('FL00;');
      rfMid:    Self.SendToRadio('FL01;');
      rfWide:   Self.SendToRadio('FL02;');
   end;
end;

function TKenwoodTS890Radio.SetFilterHz(hz: integer; vfo: TVFO = nrVFOA): integer;
begin
   Result := 0;
end;

function TKenwoodTS890Radio.MemoryKeyer(mem: integer): boolean;
begin
   Result := False;
   if FAuthState <> ksAuthenticated then Exit;
   if not IntegerBetween(mem, 1, 6) then Exit;
   Self.SendToRadio(Format('PB%d;', [mem]));
   Result := True;
end;

procedure TKenwoodTS890Radio.VFOBumpDown(whichVFO: TVFO);
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('DN;');
end;

procedure TKenwoodTS890Radio.VFOBumpUp(whichVFO: TVFO);
begin
   if FAuthState <> ksAuthenticated then Exit;
   Self.SendToRadio('UP;');
end;

end.
