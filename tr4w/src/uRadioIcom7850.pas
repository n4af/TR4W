unit uRadioIcom7850;

{
  Icom IC-7850/IC-7851 Radio Implementation

  The IC-7850 and IC-7851 are identical from a protocol perspective.
  CI-V address: 0x8E
  Controller address: 0xE0 (standard)
  Network capable: Yes
  VFO B format: Standard ($25)
}

interface

uses
  uRadioIcomBase, VC;

type
  TIcom7850Radio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  Log4D;

var
  logger: TLogLogger;

constructor TIcom7850Radio.Create;
begin
  inherited Create;
  RadioAddress := $8E;
  radioModel := 'Icom IC-7850';
  logger.Info('[TIcom7850Radio.Create] Created IC-7850 instance with CI-V address $8E');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom7850');
  logger.Level := All;

end.
