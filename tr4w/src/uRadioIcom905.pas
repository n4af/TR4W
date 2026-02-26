unit uRadioIcom905;

{
  Icom IC-905 Radio Implementation

  The IC-905 is a VHF/UHF/SHF transceiver.
  CI-V address: 0xAC
  Controller address: 0xE0 (standard)
  Network capable: Yes
  VFO B format: Standard ($25)
}

interface

uses
  uRadioIcomBase, VC;

type
  TIcom905Radio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  Log4D;

var
  logger: TLogLogger;

constructor TIcom905Radio.Create;
begin
  inherited Create;
  RadioAddress := $AC;
  radioModel := 'Icom IC-905';
  logger.Info('[TIcom905Radio.Create] Created IC-905 instance with CI-V address $AC');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom905');
  logger.Level := All;

end.
