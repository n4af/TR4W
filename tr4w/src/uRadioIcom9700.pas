unit uRadioIcom9700;

{
  Icom IC-9700 Radio Implementation

  The IC-9700 is a VHF/UHF/1.2GHz all-mode transceiver that uses the CI-V protocol.
  CI-V address: 0xA2

  Features:
  - Full CI-V command support via TIcomRadio base class
  - Polling-based operation (no auto-info mode like K4)
  - Standard polling interval: 100ms
  - Triple receivers (Main/Sub/Sub2)
  - Supports 2m, 70cm, and 23cm bands

  Usage:
    radio := TIcom9700Radio.Create;
    radio.Connect;  // Opens serial or network connection
}

interface

uses
  uRadioIcomBase, VC;

type
  TIcom9700Radio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  Log4D;

var
  logger: TLogLogger;

constructor TIcom9700Radio.Create;
begin
  inherited Create;

  // Set IC-9700 specific CI-V address
  RadioAddress := $A2;

  // Radio identification
  radioModel := 'Icom IC-9700';

  logger.Info('[TIcom9700Radio.Create] Created IC-9700 radio instance with CI-V address $A2');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom9700');
  logger.Level := All;

end.
