unit uRadioIcom7100;

{
  Icom IC-7100 Radio Implementation

  The IC-7100 is an HF/VHF/UHF all-mode transceiver (serial CI-V only).
  CI-V address: 0x88
  Controller address: 0xE0 (standard)
  CI-V transceive menu: 1A 05 00 95
}

interface

uses
  uRadioIcomBase, VC;

type
  TIcom7100Radio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  Log4D;

var
  logger: TLogLogger;

constructor TIcom7100Radio.Create;
begin
  inherited Create;
  RadioAddress := $88;
  radioModel := 'Icom IC-7100';
  // IC-7100 CI-V transceive is at menu item $0095 (1A 05 00 95)
  FTransceiveMenuBytes := #$00 + #$95;
  logger.Info('[TIcom7100Radio.Create] Created IC-7100 instance with CI-V address $88');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom7100');

end.
