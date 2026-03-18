unit uRadioIcom705;

{
  Icom IC-705 Radio Implementation

  The IC-705 is a portable HF/VHF/UHF all-mode transceiver with WiFi/USB.
  CI-V address: 0xA4
  Controller address: 0xE0 (standard)
  Network capable: Yes (WiFi or Ethernet via USB)
  VFO B format: Standard ($25)

  Supported bands: 160m-6m (HF), 2m, 70cm.
  Does NOT support 4m (70 MHz band). ToggleBand skips rb4m to avoid sending
  a frequency the radio will reject (leaving the display out of sync).
}

interface

uses
  uRadioIcomBase, uNetRadioBase, uRadioBand, VC;

type
  TIcom705Radio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
    function ToggleBand(vfo: TVFO = nrVFOA): TRadioBand; override;
  end;

implementation

uses
  SysUtils, Log4D;

var
  logger: TLogLogger;

constructor TIcom705Radio.Create;
begin
  inherited Create;
  RadioAddress := $A4;
  radioModel := 'Icom IC-705';
  // IC-705 CI-V transceive is at menu item $0131, not the default $0150 (IC-7610/IC-7760)
  FTransceiveMenuBytes := #$01 + #$31;
  logger.Info('[TIcom705Radio.Create] Created IC-705 instance with CI-V address $A4');
end;

function TIcom705Radio.ToggleBand(vfo: TVFO = nrVFOA): TRadioBand;
var
  currentBand: TRadioBand;
  nextBand: TRadioBand;
begin
  currentBand := Self.vfo[vfo].Band;

  // IC-705 supports: 160m-6m (HF), 2m, 70cm. No 4m (70 MHz).
  // Skip rb4m in the cycle to avoid sending a frequency the radio rejects.
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
    rb6m:   nextBand := rb2m;   // Skip rb4m — IC-705 has no 4m band
    rb4m:   nextBand := rb2m;   // If somehow on rb4m, step to 2m
    rb2m:   nextBand := rb70cm;
    rb70cm: nextBand := rb160m;
  else
    nextBand := rb20m;
  end;

  SetBand(nextBand, vfo);
  logger.debug('[TIcom705Radio.ToggleBand] %s -> %s (skipping 4m)',
    [IntToStr(Ord(currentBand)), IntToStr(Ord(nextBand))]);
  Result := nextBand;
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom705');

end.
