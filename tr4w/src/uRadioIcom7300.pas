unit uRadioIcom7300;

{
  Icom IC-7300 Radio Implementation

  The IC-7300 is an HF/50MHz transceiver that uses the CI-V protocol.
  CI-V address: 0x94

  Features:
  - Full CI-V command support via TIcomRadio base class
  - Polling-based operation (no auto-info mode like K4)
  - Standard polling interval: 100ms
  - Supports all HF bands plus 6 meters

  Usage:
    radio := TIcom7300Radio.Create;
    radio.Connect;  // Opens serial or network connection
}

interface

uses
  uRadioIcomBase, VC;

type
  TIcom7300Radio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  Log4D;

var
  logger: TLogLogger;

constructor TIcom7300Radio.Create;
begin
  inherited Create;

  // Set IC-7300 specific CI-V address
  RadioAddress := $94;

  // Radio identification
  radioModel := 'Icom IC-7300';

  logger.Info('[TIcom7300Radio.Create] Created IC-7300 radio instance with CI-V address $94');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom7300');
  logger.Level := All;

end.
