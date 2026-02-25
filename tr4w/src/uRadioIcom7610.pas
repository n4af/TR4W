unit uRadioIcom7610;

{
  Icom IC-7610 Radio Implementation

  The IC-7610 is an HF/50MHz SDR transceiver that uses the CI-V protocol.
  CI-V address: 0x98

  Features:
  - Full CI-V command support via TIcomRadio base class
  - Polling-based operation (no auto-info mode like K4)
  - Standard polling interval: 100ms
  - Dual receivers (Main/Sub)
  - Supports all HF bands plus 6 meters

  Usage:
    radio := TIcom7610Radio.Create;
    radio.Connect;  // Opens serial or network connection
}

interface

uses
  uRadioIcomBase, VC;

type
  TIcom7610Radio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  Log4D;

var
  logger: TLogLogger;

constructor TIcom7610Radio.Create;
begin
  inherited Create;

  // Set IC-7610 specific CI-V address
  RadioAddress := $98;

  // Radio identification
  radioModel := 'Icom IC-7610';

  logger.Info('[TIcom7610Radio.Create] Created IC-7610 radio instance with CI-V address $98');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom7610');
  logger.Level := All;

end.
