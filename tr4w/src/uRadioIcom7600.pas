unit uRadioIcom7600;

{
  Icom IC-7600 Radio Implementation

  The IC-7600 is an HF/50MHz transceiver with network capability.
  CI-V address: 0x7A
  Controller address: 0xE0 (standard)
  Network capable: Yes
  VFO B format: Standard ($25)
}

interface

uses
  uRadioIcomBase, VC;

type
  TIcom7600Radio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  Log4D;

var
  logger: TLogLogger;

constructor TIcom7600Radio.Create;
begin
  inherited Create;
  RadioAddress := $7A;
  radioModel := 'Icom IC-7600';
  logger.Info('[TIcom7600Radio.Create] Created IC-7600 instance with CI-V address $7A');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom7600');
  logger.Level := All;

end.
