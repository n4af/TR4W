unit uRadioIcom705;

{
  Icom IC-705 Radio Implementation

  The IC-705 is a portable HF/VHF/UHF all-mode transceiver with WiFi/USB.
  CI-V address: 0xA4
  Controller address: 0xE0 (standard)
  Network capable: Yes (WiFi or Ethernet via USB)
  VFO B format: Standard ($25)
}

interface

uses
  uRadioIcomBase, VC;

type
  TIcom705Radio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  Log4D;

var
  logger: TLogLogger;

constructor TIcom705Radio.Create;
begin
  inherited Create;
  RadioAddress := $A4;
  radioModel := 'Icom IC-705';
  logger.Info('[TIcom705Radio.Create] Created IC-705 instance with CI-V address $A4');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom705');
  logger.Level := All;

end.
