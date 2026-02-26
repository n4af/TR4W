unit uRadioIcomBase;

{
  Icom Radio Base Class with CI-V Protocol Support

  Implements the Icom CI-V (Computer Interface V) protocol for Icom transceivers.

  CI-V Frame Format:
    FE FE [To Address] [From Address] [Command] [Sub-command/Data] FD

  Where:
    FE FE = Preamble
    To Address = Radio address (e.g., 0x94 for IC-7300)
    From Address = Controller address (usually 0xE0)
    Command = Command byte
    Sub-command/Data = Optional data bytes
    FD = End of message

  Common Commands:
    0x03 = Read operating frequency
    0x04 = Read operating mode
    0x05 = Set operating frequency
    0x06 = Set operating mode
    0x07 = Read/Set VFO mode (Main/Sub)
    0x14 = Read/Set various levels
    0x15 = Read/Set meter
    0x1C = TX/RX control

  Usage:
    Create derived classes (e.g., TIcom7300Radio) that set the radioAddress
    and override any radio-specific behavior.
}

interface

uses
  uNetRadioBase, uIcomNetworkTransport, SysUtils, StrUtils, VC, Log4D;

type
  TIcomRadio = class(TNetRadioBase)
  private
    FRadioAddress: Byte;          // CI-V address of radio (e.g., 0x94 for IC-7300)
    FControllerAddress: Byte;     // CI-V address of controller (usually 0xE0)
    FCIVBuffer: string;           // Buffer for accumulating CI-V frames
    FCWBuffer: string;            // Buffer for CW text to send

    // Network transport (Icom UDP protocol)
    FNetworkTransport: TIcomNetworkTransport;
    FNetworkUsername: string;
    FNetworkPassword: string;

    function BuildCIVCommand(command: Byte; data: string): string;
    function BCDToByte(bcd: Byte): Byte;
    function ByteToBCD(value: Byte): Byte;
    function OffsetToBCD(offset: Integer): string;  // Convert RIT/XIT offset to BCD (2 bytes)
    function BandToFreq(band: TRadioBand): LongInt;  // Map band to typical frequency

    procedure ProcessCIVMessage(msg: string);
    procedure ProcessNetworkCivData(msg: string);
    procedure OnNetworkStateChange(Sender: TObject);

  protected
    function FreqToBCD(freq: LongInt): string;  // Convert frequency to 5-byte BCD
    function BCDToFreq(bcd: string): LongInt;   // Convert 5-byte BCD to frequency
    procedure ProcessCIVFrame(frame: string); virtual;
    function GetIsConnected: boolean; override;
    function IsNetworkConnection: boolean;

  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure ProcessMsg(msg: string); override;
    function Connect: integer; override;
    procedure Disconnect; override;
    procedure SendToRadio(s: string); overload; override;

    // Polling interface implementation
    procedure QueryVFOAFrequency; override;
    procedure QueryVFOBFrequency; override;
    procedure QueryMode; override;
    procedure QueryTXStatus; override;
    procedure QueryRITState; override;
    procedure QueryXITState; override;
    procedure QueryBand; override;
    procedure QuerySplitState; override;

    // Radio control methods
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
    procedure RITOn(vfo: TVFO); override;
    procedure RITOff(vfo: TVFO); override;
    procedure XITOn(vfo: TVFO); override;
    procedure XITOff(vfo: TVFO); override;
    procedure Split(splitOn: boolean); override;
    procedure SetRITFreq(vfo: TVFO; hz: integer); override;
    procedure SetXITFreq(vfo: TVFO; hz: integer); override;
    procedure SetBand(band: TRadioBand; vfo: TVFO = nrVFOA); override;
    function  ToggleBand(vfo: TVFO = nrVFOA): TRadioBand; override;
    procedure SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA); override;
    procedure SendToRadio(whichVFO: TVFO; sCmd: string; sData: string); overload; override;

    property RadioAddress: Byte read FRadioAddress write FRadioAddress;
    property ControllerAddress: Byte read FControllerAddress write FControllerAddress;
    property NetworkUsername: string read FNetworkUsername write FNetworkUsername;
    property NetworkPassword: string read FNetworkPassword write FNetworkPassword;
    property NetworkTransport: TIcomNetworkTransport read FNetworkTransport;
  end;

implementation

var
  logger: TLogLogger;

// CI-V Protocol Constants
const
  CIV_PREAMBLE1 = #$FE;
  CIV_PREAMBLE2 = #$FE;
  CIV_EOM = #$FD;

  // CI-V Commands
  CIV_CMD_READ_FREQ = #$03;
  CIV_CMD_READ_MODE = #$04;
  CIV_CMD_SET_FREQ = #$05;
  CIV_CMD_SET_MODE = #$06;
  CIV_CMD_VFO_MODE = #$07;
  CIV_CMD_SPLIT = #$0F;
  CIV_CMD_LEVELS = #$14;
  CIV_CMD_CW_SEND = #$17;
  CIV_CMD_FILTER = #$1A;
  CIV_CMD_TX_RX = #$1C;
  CIV_CMD_RIT_XIT = #$21;
  CIV_CMD_VFO_SELECT = #$25;

  // CI-V Sub-commands for TX/RX
  CIV_SUBCMD_TX = #$00;
  CIV_SUBCMD_RX = #$01;

  // CI-V Sub-commands for RIT/XIT ($21)
  CIV_SUBCMD_RIT_OFF = #$00;
  CIV_SUBCMD_RIT_ON = #$01;
  CIV_SUBCMD_RIT_FREQ = #$02;
  CIV_SUBCMD_RIT_READ = #$03;
  CIV_SUBCMD_XIT_OFF = #$10;
  CIV_SUBCMD_XIT_ON = #$11;
  CIV_SUBCMD_XIT_FREQ = #$12;
  CIV_SUBCMD_XIT_READ = #$13;

  // CI-V Sub-commands for Split ($0F)
  CIV_SUBCMD_SPLIT_OFF = #$00;
  CIV_SUBCMD_SPLIT_ON = #$01;

  // CI-V Sub-commands for VFO Select ($25)
  CIV_SUBCMD_VFO_A = #$00;
  CIV_SUBCMD_VFO_B = #$01;

  // CI-V Sub-commands for CW ($17)
  CIV_SUBCMD_CW_SEND = #$00;

  // CI-V Sub-commands for Filter ($1A)
  CIV_SUBCMD_FILTER_WIDTH = #$03;

  // CI-V Sub-commands for Levels ($14)
  CIV_SUBCMD_CW_SPEED = #$0C;

constructor TIcomRadio.Create;
begin
  inherited Create(ProcessMsg);

  // Icom radios require polling
  requiresPolling := True;
  autoUpdateCommand := '';
  pollingInterval := 100;  // Poll every 100ms

  // Default addresses (derived classes override)
  FControllerAddress := $E0;  // Standard controller address
  FRadioAddress := $00;       // Set by derived class

  FCIVBuffer := '';
  FCWBuffer := '';
  readTerminator := CIV_EOM;  // CI-V frames end with FD

  FNetworkTransport := nil;
  FNetworkUsername := '';
  FNetworkPassword := '';

  radioModel := 'Icom';  // Will be overridden by derived classes
end;

destructor TIcomRadio.Destroy;
begin
  if FNetworkTransport <> nil then
  begin
    FNetworkTransport.Disconnect;
    FreeAndNil(FNetworkTransport);
  end;
  inherited Destroy;
end;

function TIcomRadio.IsNetworkConnection: boolean;
begin
  // Network connection when serial port is not set and IP address is provided
  // Use TNetRadioBase() cast to access base class radioAddress (string),
  // not TIcomRadio.RadioAddress which is the CI-V address (Byte)
  Result := (serialPort = NoPort) and
            (Length(TNetRadioBase(Self).radioAddress) > 0) and
            (radioPort > 0);
end;

function TIcomRadio.Connect: integer;
begin
  if IsNetworkConnection then
  begin
    logger.Info('[TIcomRadio.Connect] Connecting via Icom network protocol to %s:%d',
                [TNetRadioBase(Self).radioAddress, radioPort]);

    // Create transport if needed
    if FNetworkTransport = nil then
    begin
      FNetworkTransport := TIcomNetworkTransport.Create;
      FNetworkTransport.OnCivData := ProcessNetworkCivData;
      FNetworkTransport.OnStateChange := OnNetworkStateChange;
    end;

    Result := FNetworkTransport.Connect(TNetRadioBase(Self).radioAddress,
                                         radioPort,
                                         FNetworkUsername, FNetworkPassword);
    if Result = 0 then
      logger.Info('[TIcomRadio.Connect] Network connection initiated to %s:%d',
                  [TNetRadioBase(Self).radioAddress, radioPort])
    else
      logger.Error('[TIcomRadio.Connect] Network connection failed: %d', [Result]);
  end
  else
  begin
    // Serial or TCP connection - use base class
    Result := inherited Connect;
  end;
end;

procedure TIcomRadio.Disconnect;
begin
  if IsNetworkConnection and (FNetworkTransport <> nil) then
  begin
    logger.Info('[TIcomRadio.Disconnect] Disconnecting Icom network transport');
    FNetworkTransport.Disconnect;
    FreeAndNil(FNetworkTransport);
  end
  else
    inherited Disconnect;
end;

procedure TIcomRadio.SendToRadio(s: string);
begin
  if IsNetworkConnection and (FNetworkTransport <> nil) then
  begin
    // Send CI-V frame via Icom UDP transport
    FNetworkTransport.SendCivData(s);
  end
  else
    inherited SendToRadio(s);
end;

function TIcomRadio.GetIsConnected: boolean;
begin
  if IsNetworkConnection then
  begin
    if FNetworkTransport <> nil then
      Result := FNetworkTransport.IsConnected
    else
      Result := False;
  end
  else
    Result := inherited GetIsConnected;
end;

procedure TIcomRadio.ProcessNetworkCivData(msg: string);
begin
  // Called from transport thread when CI-V data arrives via UDP
  // Forward to CI-V message parser
  logger.Trace('[TIcomRadio.ProcessNetworkCivData] Received CI-V data, length: %d', [Length(msg)]);
  ProcessCIVMessage(msg);
end;

procedure TIcomRadio.OnNetworkStateChange(Sender: TObject);
begin
  if FNetworkTransport <> nil then
    logger.Info('[TIcomRadio.OnNetworkStateChange] Transport state changed to: %s',
                [FNetworkTransport.RadioName])
  else
    logger.Info('[TIcomRadio.OnNetworkStateChange] Transport state changed');
end;

function TIcomRadio.BuildCIVCommand(command: Byte; data: string): string;
begin
  Result := CIV_PREAMBLE1 + CIV_PREAMBLE2 +
            Chr(FRadioAddress) + Chr(FControllerAddress) +
            Chr(command) + data + CIV_EOM;
end;

function TIcomRadio.ByteToBCD(value: Byte): Byte;
begin
  Result := ((value div 10) shl 4) or (value mod 10);
end;

function TIcomRadio.BCDToByte(bcd: Byte): Byte;
begin
  Result := ((bcd shr 4) * 10) + (bcd and $0F);
end;

function TIcomRadio.FreqToBCD(freq: LongInt): string;
var
  i: Integer;
  freqStr: string;
  bcdByte: Byte;
begin
  // Convert frequency to 10-digit string (pad with zeros)
  freqStr := Format('%.10d', [freq]);

  // Convert to 5 BCD bytes (2 digits per byte), LSB first
  Result := '';
  for i := 5 downto 1 do
  begin
    bcdByte := ByteToBCD(StrToInt(Copy(freqStr, i * 2 - 1, 2)));
    Result := Result + Chr(bcdByte);
  end;
end;

function TIcomRadio.BCDToFreq(bcd: string): LongInt;
var
  i: Integer;
  freqStr: string;
begin
  freqStr := '';
  // BCD is LSB first, so reverse it
  for i := Length(bcd) downto 1 do
  begin
    freqStr := freqStr + Format('%.2d', [BCDToByte(Ord(bcd[i]))]);
  end;
  Result := StrToInt64Def(freqStr, 0);
end;

function TIcomRadio.OffsetToBCD(offset: Integer): string;
var
  absOffset: Integer;
  offsetStr: string;
  bcdByte: Byte;
  i: Integer;
begin
  // Convert offset to absolute value (sign handled separately if needed)
  absOffset := Abs(offset);

  // Convert to 4-digit string (pad with zeros) - max is 9999 Hz
  offsetStr := Format('%.4d', [absOffset]);

  // Convert to 2 BCD bytes (2 digits per byte), LSB first
  Result := '';
  for i := 2 downto 1 do
  begin
    bcdByte := ByteToBCD(StrToInt(Copy(offsetStr, i * 2 - 1, 2)));
    Result := Result + Chr(bcdByte);
  end;
end;

function TIcomRadio.BandToFreq(band: TRadioBand): LongInt;
begin
  // Map band to typical calling frequency (in Hz)
  case band of
    rb160m:  Result := 1900000;    // 1.9 MHz
    rb80m:   Result := 3600000;    // 3.6 MHz
    rb60m:   Result := 5357000;    // 5.357 MHz
    rb40m:   Result := 7100000;    // 7.1 MHz
    rb30m:   Result := 10125000;   // 10.125 MHz
    rb20m:   Result := 14100000;   // 14.1 MHz
    rb17m:   Result := 18100000;   // 18.1 MHz
    rb15m:   Result := 21100000;   // 21.1 MHz
    rb12m:   Result := 24920000;   // 24.92 MHz
    rb10m:   Result := 28400000;   // 28.4 MHz
    rb6m:    Result := 50100000;   // 50.1 MHz
    rb4m:    Result := 70100000;   // 70.1 MHz
    rb2m:    Result := 144100000;  // 144.1 MHz
    rb70cm:  Result := 432100000;  // 432.1 MHz
  else
    Result := 14100000;  // Default to 20m
  end;
end;

procedure TIcomRadio.ProcessMsg(msg: string);
begin
  logger.trace('[%s.ProcessMsg] CALLED with length: %d', [radioModel, Length(msg)]);
  // Forward to ProcessCIVMessage to maintain compatibility
  ProcessCIVMessage(msg);
end;

procedure TIcomRadio.ProcessCIVMessage(msg: string);
var
  frameStart, frameEnd: Integer;
  frame: string;
begin
  logger.trace('[%s.ProcessCIVMessage] CALLED with msg length: %d', [radioModel, Length(msg)]);  // Removed String2Hex to avoid circular dependency

  // TReadingThread strips the terminator, so add it back
  if (Length(msg) > 0) and (msg[Length(msg)] <> CIV_EOM) then
    msg := msg + CIV_EOM;

  // Add received data to buffer
  FCIVBuffer := FCIVBuffer + msg;
  logger.trace('[%s.ProcessCIVMessage] Buffer length: %d', [radioModel, Length(FCIVBuffer)]);

  // Process complete CI-V frames (FE FE ... FD)
  while True do
  begin
    frameStart := Pos(CIV_PREAMBLE1 + CIV_PREAMBLE2, FCIVBuffer);
    if frameStart = 0 then
    begin
      logger.trace('[%s.ProcessCIVMessage] No preamble found in buffer', [radioModel]);
      Break;  // No complete preamble found
    end;

    frameEnd := Pos(CIV_EOM, FCIVBuffer);
    if frameEnd = 0 then
    begin
      logger.trace('[%s.ProcessCIVMessage] Preamble found but no EOM yet', [radioModel]);
      Break;  // No end-of-message found
    end;

    if frameEnd < frameStart then
    begin
      // EOM before preamble - remove garbage
      Delete(FCIVBuffer, 1, frameEnd);
      Continue;
    end;

    // Extract complete frame including preamble and EOM
    frame := Copy(FCIVBuffer, frameStart, frameEnd - frameStart + 1);
    Delete(FCIVBuffer, 1, frameEnd);

    logger.trace('[%s.ProcessCIVMessage] Extracted frame, length: %d', [radioModel, Length(frame)]);

    // Process the frame
    ProcessCIVFrame(frame);
  end;

  // Prevent buffer from growing too large
  if Length(FCIVBuffer) > 1024 then
    FCIVBuffer := '';
end;

procedure TIcomRadio.ProcessCIVFrame(frame: string);
var
  command: Byte;
  data: string;
  freq: LongInt;
  modeNum: Byte;
  radioMode: TRadioMode;
  tempBand: BandType;
  tempMode: ModeType;
begin
  // Minimum frame: FE FE [To] [From] [Cmd] FD = 6 bytes
  if Length(frame) < 6 then
    Exit;

  // Verify preamble
  if (frame[1] <> CIV_PREAMBLE1) or (frame[2] <> CIV_PREAMBLE2) then
    Exit;

  // Verify EOM
  if frame[Length(frame)] <> CIV_EOM then
    Exit;

  // Valid frame received - update timestamp for disconnect detection
  UpdateLastValidResponse;

  // Extract command and data
  command := Ord(frame[5]);
  data := Copy(frame, 6, Length(frame) - 6);  // Everything between command and EOM

  // Log what command we're processing
  case command of
    $03: logger.trace('[%s] Processing frequency response, data length: %d', [radioModel, Length(data)]);
    $04: logger.trace('[%s] Processing mode response, data length: %d', [radioModel, Length(data)]);
    $05: logger.trace('[%s] Processing set frequency command, data length: %d', [radioModel, Length(data)]);
    $06: logger.trace('[%s] Processing set mode command, data length: %d', [radioModel, Length(data)]);
    $FB: logger.trace('[%s] Processing ACK (command OK)', [radioModel]);
    $FA: logger.trace('[%s] Processing NAK (command rejected)', [radioModel]);
  else
    logger.trace('[%s] Processing unknown command: $%.2x, data length: %d', [radioModel, command, Length(data)]);
  end;

  case command of
    $03:  // Read frequency response
      begin
        if Length(data) >= 5 then
        begin
          freq := BCDToFreq(Copy(data, 1, 5));
          logger.trace('[%s] Frequency: %d Hz', [radioModel, freq]);
          Self.vfo[nrVFOA].Frequency := freq;
          // TODO: Calculate and update band from frequency - commented to avoid circular dependency
          // CalculateBandMode(freq, tempBand, tempMode);
          // Self.vfo[nrVFOA].Band := GetRadioBandFromBandType(tempBand);
          // logger.trace('[%s] Band: %d', [radioModel, Ord(Self.vfo[nrVFOA].Band)]);
        end;
      end;

    $04:  // Read mode response
      begin
        if Length(data) >= 1 then
        begin
          modeNum := Ord(data[1]);
          case modeNum of
            $00: radioMode := rmLSB;
            $01: radioMode := rmUSB;
            $02: radioMode := rmAM;
            $03: radioMode := rmCW;
            $04: radioMode := rmFM; // Actually RTTY for IC-7300
            $05: radioMode := rmFM;
            $07: radioMode := rmCWRev;
            else radioMode := rmNone;
          end;
          logger.trace('[%s] Mode: %d', [radioModel, modeNum]);  // Removed ModeToString to avoid circular dependency
          Self.vfo[nrVFOA].Mode := radioMode;
        end;
      end;

    $FB:  // Command OK (ACK)
      logger.trace('[%s] Command acknowledged', [radioModel]);

    $FA:  // Command NG (NAK)
      logger.warn('[%s] Command rejected', [radioModel]);
  end;
end;

// Polling interface
procedure TIcomRadio.QueryVFOAFrequency;
begin
  SendToRadio(BuildCIVCommand($03, ''));  // Read operating frequency
end;

procedure TIcomRadio.QueryVFOBFrequency;
begin
  // Select VFO B, read frequency
  SendToRadio(BuildCIVCommand($25, CIV_SUBCMD_VFO_B));
  SendToRadio(BuildCIVCommand($03, ''));  // Read operating frequency
  // Note: In production code, might want to switch back to VFO A
end;

procedure TIcomRadio.QueryMode;
begin
  SendToRadio(BuildCIVCommand($04, ''));  // Read operating mode
end;

procedure TIcomRadio.QueryTXStatus;
begin
  // Query TX/RX status using command $1C $00
  SendToRadio(BuildCIVCommand($1C, #$00));
end;

procedure TIcomRadio.QueryRITState;
begin
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_RIT_READ));
end;

procedure TIcomRadio.QueryXITState;
begin
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_XIT_READ));
end;

procedure TIcomRadio.QueryBand;
begin
  // Band is derived from frequency
end;

procedure TIcomRadio.QuerySplitState;
begin
  // Query split status using command $0F
  SendToRadio(BuildCIVCommand($0F, ''));
end;

// Radio control methods - basic implementations
procedure TIcomRadio.Transmit;
begin
  SendToRadio(BuildCIVCommand($1C, CIV_SUBCMD_TX));  // TX on
end;

procedure TIcomRadio.Receive;
begin
  SendToRadio(BuildCIVCommand($1C, CIV_SUBCMD_RX));  // RX on
end;

procedure TIcomRadio.SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
var
  bcdFreq: string;
begin
  // Switch to the appropriate VFO if specified
  if vfo = nrVFOB then
    SendToRadio(BuildCIVCommand($25, CIV_SUBCMD_VFO_B))
  else if vfo = nrVFOA then
    SendToRadio(BuildCIVCommand($25, CIV_SUBCMD_VFO_A));

  bcdFreq := FreqToBCD(freq);
  SendToRadio(BuildCIVCommand($05, bcdFreq));  // Set frequency
  logger.trace('[%s.SetFrequency] Setting VFO %s frequency to %d Hz', [radioModel, IfThen(vfo = nrVFOA, 'A', 'B'), freq]);
end;

procedure TIcomRadio.SetMode(mode: TRadioMode; vfo: TVFO = nrVFOA);
var
  modeCmd: Byte;
  filterCmd: Byte;
begin
//TODO: If the radio is in the interface for IcomSupportsVFOBCOmmands, then we do not need to select the VFOB first. We can set VFOB directory with the 26 command
  // Switch to the appropriate VFO if specified
  if vfo = nrVFOB then
    SendToRadio(BuildCIVCommand($25, CIV_SUBCMD_VFO_B))
  else if vfo = nrVFOA then
    SendToRadio(BuildCIVCommand($25, CIV_SUBCMD_VFO_A));

  // Map TRadioMode to Icom mode numbers
  filterCmd := $01;  // Default filter
  case mode of
    rmLSB:    modeCmd := $00;
    rmUSB:    modeCmd := $01;
    rmAM:     modeCmd := $02;
    rmCW:     modeCmd := $03;
    rmFM:     modeCmd := $05;
    rmCWRev:  modeCmd := $07;
  else
    modeCmd := $01;  // Default to USB
  end;

  SendToRadio(BuildCIVCommand($06, Chr(modeCmd) + Chr(filterCmd)));
  logger.trace('[%s.SetMode] Set VFO %s mode', [radioModel, IfThen(vfo = nrVFOA, 'A', 'B')]);  // Removed ModeToString to avoid circular dependency
end;

procedure TIcomRadio.BufferCW(cwChars: string);
begin
  FCWBuffer := FCWBuffer + cwChars;
  logger.trace('[%s.BufferCW] Buffered: "%s", Total buffer: "%s"', [radioModel, cwChars, FCWBuffer]);
end;

procedure TIcomRadio.SendCW;
begin
  if FCWBuffer = '' then
  begin
    logger.warn('[%s.SendCW] CW buffer is empty - nothing to send', [radioModel]);
    Exit;
  end;

  // Send CW message using CI-V command $17 $00
  SendToRadio(BuildCIVCommand($17, CIV_SUBCMD_CW_SEND + FCWBuffer));
  logger.info('[%s.SendCW] Sending CW: "%s"', [radioModel, FCWBuffer]);

  // Clear buffer after sending
  FCWBuffer := '';
end;

procedure TIcomRadio.StopCW;
begin
  // Send break command to stop CW
  // CI-V command $17 $01 stops CW sending
  SendToRadio(BuildCIVCommand($17, #$01));
  logger.trace('[%s.StopCW] CW transmission stopped', [radioModel]);
end;

function TIcomRadio.ToggleMode(vfo: TVFO = nrVFOA): TRadioMode;
var
  currentMode: TRadioMode;
  nextMode: TRadioMode;
begin
  // Get current mode from VFO
  currentMode := Self.vfo[vfo].Mode;

  // Toggle to next mode in sequence
  case currentMode of
    rmNone, rmLSB: nextMode := rmUSB;
    rmUSB:   nextMode := rmCW;
    rmCW:    nextMode := rmCWRev;
    rmCWRev: nextMode := rmAM;
    rmAM:    nextMode := rmFM;
    rmFM:    nextMode := rmLSB;  // Wrap around
  else
    nextMode := rmUSB;  // Default
  end;

  SetMode(nextMode, vfo);
  Result := nextMode;
end;

procedure TIcomRadio.SetCWSpeed(speed: integer);
var
  bcdSpeed: Byte;
begin
  // CW speed is typically 6-48 WPM
  // Convert to BCD (0-255 range, but usually 6-48)
  bcdSpeed := ByteToBCD(speed);
  SendToRadio(BuildCIVCommand($14, CIV_SUBCMD_CW_SPEED + Chr(bcdSpeed)));
  logger.trace('[%s.SetCWSpeed] Set CW speed to %d WPM', [radioModel, speed]);
end;

procedure TIcomRadio.RITClear(whichVFO: TVFO);
begin
  // Clear RIT by setting offset to 0
  SetRITFreq(whichVFO, 0);
  logger.trace('[%s.RITClear] Cleared RIT offset', [radioModel]);
end;

procedure TIcomRadio.XITClear(whichVFO: TVFO);
begin
  // Clear XIT by setting offset to 0
  SetXITFreq(whichVFO, 0);
  logger.trace('[%s.XITClear] Cleared XIT offset', [radioModel]);
end;

procedure TIcomRadio.RITBumpDown;
begin
  // Bump RIT down by 10 Hz
  // Note: Would need to track current RIT offset to implement properly
  logger.trace('[%s.RITBumpDown] RIT bump down not fully implemented', [radioModel]);
end;

procedure TIcomRadio.RITBumpUp;
begin
  // Bump RIT up by 10 Hz
  // Note: Would need to track current RIT offset to implement properly
  logger.trace('[%s.RITBumpUp] RIT bump up not fully implemented', [radioModel]);
end;

procedure TIcomRadio.RITOn(vfo: TVFO);
begin
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_RIT_ON));
  logger.trace('[%s.RITOn] RIT enabled', [radioModel]);
end;

procedure TIcomRadio.RITOff(vfo: TVFO);
begin
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_RIT_OFF));
  logger.trace('[%s.RITOff] RIT disabled', [radioModel]);
end;

procedure TIcomRadio.XITOn(vfo: TVFO);
begin
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_XIT_ON));
  logger.trace('[%s.XITOn] XIT enabled', [radioModel]);
end;

procedure TIcomRadio.XITOff(vfo: TVFO);
begin
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_XIT_OFF));
  logger.trace('[%s.XITOff] XIT disabled', [radioModel]);
end;

procedure TIcomRadio.Split(splitOn: boolean);
begin
  if splitOn then
    SendToRadio(BuildCIVCommand($0F, CIV_SUBCMD_SPLIT_ON))
  else
    SendToRadio(BuildCIVCommand($0F, CIV_SUBCMD_SPLIT_OFF));
  logger.trace('[%s.Split] Split %s', [radioModel, IfThen(splitOn, 'enabled', 'disabled')]);
end;

procedure TIcomRadio.SetRITFreq(vfo: TVFO; hz: integer);
var
  bcdOffset: string;
begin
  bcdOffset := OffsetToBCD(hz);
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_RIT_FREQ + bcdOffset));
  logger.trace('[%s.SetRITFreq] Set RIT offset to %d Hz', [radioModel, hz]);
end;

procedure TIcomRadio.SetXITFreq(vfo: TVFO; hz: integer);
var
  bcdOffset: string;
begin
  bcdOffset := OffsetToBCD(hz);
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_XIT_FREQ + bcdOffset));
  logger.trace('[%s.SetXITFreq] Set XIT offset to %d Hz', [radioModel, hz]);
end;

procedure TIcomRadio.SetBand(band: TRadioBand; vfo: TVFO = nrVFOA);
var
  freq: LongInt;
begin
  // Convert band to frequency and set it
  freq := BandToFreq(band);
  SetFrequency(freq, vfo, rmNone);  // Mode unchanged
  logger.trace('[%s.SetBand] Set band to %d', [radioModel, Ord(band)]);
end;

function TIcomRadio.ToggleBand(vfo: TVFO = nrVFOA): TRadioBand;
var
  currentBand: TRadioBand;
  nextBand: TRadioBand;
begin
  // Get current band from VFO
  currentBand := Self.vfo[vfo].Band;

  // Toggle to next band in sequence
  case currentBand of
    rbNone, rb160m: nextBand := rb80m;
    rb80m:  nextBand := rb60m;
    rb60m:  nextBand := rb40m;
    rb40m:  nextBand := rb30m;
    rb30m:  nextBand := rb20m;
    rb20m:  nextBand := rb17m;
    rb17m:  nextBand := rb15m;
    rb15m:  nextBand := rb12m;
    rb12m:  nextBand := rb10m;
    rb10m:  nextBand := rb6m;
    rb6m:   nextBand := rb4m;
    rb4m:   nextBand := rb2m;
    rb2m:   nextBand := rb70cm;
    rb70cm: nextBand := rb160m;  // Wrap around
  else
    nextBand := rb20m;  // Default
  end;

  SetBand(nextBand, vfo);
  Result := nextBand;
end;

procedure TIcomRadio.SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA);
var
  filterNum: Byte;
begin
  // Map TRadioFilter to Icom filter numbers
  // Note: Filter numbering varies by radio, this is a general mapping
  case filter of
    rfNarrow:  filterNum := $02;  // Narrow filter
    rfMid:     filterNum := $01;  // Medium/default filter
    rfWide:    filterNum := $03;  // Wide filter
  else
    filterNum := $01;  // Default filter
  end;

  SendToRadio(BuildCIVCommand($1A, CIV_SUBCMD_FILTER_WIDTH + Chr(filterNum)));
  logger.trace('[%s.SetFilter] Set filter to %d', [radioModel, filterNum]);
end;

procedure TIcomRadio.SendToRadio(whichVFO: TVFO; sCmd: string; sData: string);
begin
  // For Icom, commands are built differently - this is mainly for compatibility
  SendToRadio(sCmd + sData);
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcomBase');
  logger.Level := All;

end.
