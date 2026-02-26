unit uRadioIcom7760;

{
  Icom IC-7760 Radio Implementation

  The IC-7760 has several protocol differences from standard Icom radios:
    - CI-V address: 0xB2
    - Controller address: 0xE1 (NOT the typical 0xE0)
    - VFO B commands $25/$26 require sub-command byte $01
    - Shared RIT/XIT offset (single offset for both)

  Reference: docs/ICOM_NETWORK_DELPHI_REFERENCE.md
}

interface

uses
  uRadioIcomBase, uNetRadioBase, VC, SysUtils;

type
  TIcom7760Radio = class(TIcomRadio)
  private
    function BuildCIVCommand7760(command: Byte; data: string): string;
  public
    constructor Create; reintroduce;

    // Override VFO B to use extended format with sub-command $01
    procedure QueryVFOBFrequency; override;
    procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode); override;

    // Override CI-V frame parsing for extended VFO B format
    procedure ProcessCIVFrame(frame: string); override;
  end;

implementation

uses
  Log4D, StrUtils;

var
  logger: TLogLogger;

const
  CIV_PREAMBLE1 = #$FE;
  CIV_PREAMBLE2 = #$FE;
  CIV_EOM       = #$FD;
  IC7760_VFO_B_SUBCMD = #$01;

constructor TIcom7760Radio.Create;
begin
  inherited Create;
  RadioAddress := $B2;
  ControllerAddress := $E1;  // NOT the typical $E0
  radioModel := 'Icom IC-7760';
  logger.Info('[TIcom7760Radio.Create] Created IC-7760 instance, CI-V=$B2, Controller=$E1');
end;

function TIcom7760Radio.BuildCIVCommand7760(command: Byte; data: string): string;
begin
  Result := CIV_PREAMBLE1 + CIV_PREAMBLE2 +
            Chr(RadioAddress) + Chr(ControllerAddress) +
            Chr(command) + data + CIV_EOM;
end;

procedure TIcom7760Radio.QueryVFOBFrequency;
begin
  // IC-7760 requires sub-command $01 for VFO B frequency
  // TX: FE FE B2 E1 25 01 FD
  SendToRadio(BuildCIVCommand7760($25, IC7760_VFO_B_SUBCMD));
end;

procedure TIcom7760Radio.SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
var
  bcdFreq: string;
begin
  bcdFreq := FreqToBCD(freq);

  if vfo = nrVFOB then
  begin
    // IC-7760: VFO B set uses $25 $01 <BCD>
    SendToRadio(BuildCIVCommand7760($25, IC7760_VFO_B_SUBCMD + bcdFreq));
    logger.Trace('[IC-7760.SetFrequency] Setting VFO B frequency to %d Hz', [freq]);
  end
  else
  begin
    // VFO A uses standard command $05
    SendToRadio(BuildCIVCommand7760($05, bcdFreq));
    logger.Trace('[IC-7760.SetFrequency] Setting VFO A frequency to %d Hz', [freq]);
  end;
end;

procedure TIcom7760Radio.ProcessCIVFrame(frame: string);
var
  command: Byte;
  data: string;
  freq: LongInt;
  modeNum: Byte;
  radioMode: TRadioMode;
begin
  // Minimum frame: FE FE [To] [From] [Cmd] FD = 6 bytes
  if Length(frame) < 6 then Exit;

  // Verify preamble and EOM
  if (frame[1] <> CIV_PREAMBLE1) or (frame[2] <> CIV_PREAMBLE2) then Exit;
  if frame[Length(frame)] <> CIV_EOM then Exit;

  // Valid frame received
  UpdateLastValidResponse;

  command := Ord(frame[5]);
  data := Copy(frame, 6, Length(frame) - 6);

  case command of
    $25:  // VFO B frequency (IC-7760 extended format)
      begin
        // IC-7760 format: $25 $01 <5 BCD bytes>
        if (Length(data) >= 6) and (Ord(data[1]) = $01) then
        begin
          freq := BCDToFreq(Copy(data, 2, 5));
          Self.vfo[nrVFOB].Frequency := freq;
          logger.Trace('[IC-7760] VFO B Frequency: %d Hz', [freq]);
        end
        else if Length(data) >= 5 then
        begin
          // Standard format fallback
          freq := BCDToFreq(Copy(data, 1, 5));
          Self.vfo[nrVFOB].Frequency := freq;
          logger.Trace('[IC-7760] VFO B Frequency (std): %d Hz', [freq]);
        end;
      end;

    $26:  // VFO B mode (IC-7760 extended format)
      begin
        if (Length(data) >= 2) and (Ord(data[1]) = $01) then
        begin
          modeNum := Ord(data[2]);
          case modeNum of
            $00: radioMode := rmLSB;
            $01: radioMode := rmUSB;
            $02: radioMode := rmAM;
            $03: radioMode := rmCW;
            $05: radioMode := rmFM;
            $07: radioMode := rmCWRev;
            else radioMode := rmNone;
          end;
          Self.vfo[nrVFOB].Mode := radioMode;
          logger.Trace('[IC-7760] VFO B Mode: %d', [modeNum]);
        end;
      end;

    $21:  // RIT/XIT (shared offset on IC-7760)
      begin
        if Length(data) >= 1 then
        begin
          case Ord(data[1]) of
            $00:  // RIT/XIT offset
              begin
                if Length(data) >= 4 then
                begin
                  // BCD offset: high, low, sign
                  freq := ((Ord(data[2]) shr 4) and $0F) * 1000 +
                          (Ord(data[2]) and $0F) * 100 +
                          ((Ord(data[3]) shr 4) and $0F) * 10 +
                          (Ord(data[3]) and $0F);
                  if Ord(data[4]) <> $00 then
                    freq := -freq;
                  Self.vfo[nrVFOA].RITOffset := freq;
                  Self.vfo[nrVFOA].XITOffset := freq;  // Shared
                  logger.Trace('[IC-7760] RIT/XIT offset: %d Hz', [freq]);
                end;
              end;
            $01:  // RIT on/off
              begin
                if Length(data) >= 2 then
                begin
                  Self.vfo[nrVFOA].RITState := (Ord(data[2]) = $01);
                  logger.Trace('[IC-7760] RIT %s', [IfThen(Self.vfo[nrVFOA].RITState, 'ON', 'OFF')]);
                end;
              end;
            $02:  // XIT on/off (Delta TX)
              begin
                if Length(data) >= 2 then
                begin
                  Self.vfo[nrVFOA].XITState := (Ord(data[2]) = $01);
                  logger.Trace('[IC-7760] XIT %s', [IfThen(Self.vfo[nrVFOA].XITState, 'ON', 'OFF')]);
                end;
              end;
          end;
        end;
      end;

  else
    // For all other commands, use the base class handler
    inherited ProcessCIVFrame(frame);
  end;
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom7760');
  logger.Level := All;

end.
