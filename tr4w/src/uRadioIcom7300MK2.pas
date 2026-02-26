unit uRadioIcom7300MK2;

{
  Icom IC-7300MK2 Radio Implementation

  The IC-7300MK2 is the network-capable version of the IC-7300.
  CI-V address: 0xB6
  Controller address: 0xE0 (standard)
  Network capable: Yes
  VFO B format: Standard ($25)

  Note: The original IC-7300 (CI-V $94) is serial-only and NOT network capable.
}

interface

uses
  uRadioIcomBase, VC;

type
  TIcom7300MK2Radio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  Log4D;

var
  logger: TLogLogger;

constructor TIcom7300MK2Radio.Create;
begin
  inherited Create;
  RadioAddress := $B6;
  radioModel := 'Icom IC-7300MK2';
  logger.Info('[TIcom7300MK2Radio.Create] Created IC-7300MK2 instance with CI-V address $B6');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom7300MK2');
  logger.Level := All;

end.
