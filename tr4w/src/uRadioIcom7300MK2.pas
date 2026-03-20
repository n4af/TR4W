unit uRadioIcom7300MK2;

{
  Icom IC-7300MK2 Radio Implementation

  The IC-7300MK2 is the network-capable version of the IC-7300.
  CI-V address: 0xB6 (Icom factory default)
  Controller address: 0xE0 (standard)
  Network capable: Yes
  VFO B format: Standard ($25)

  Note: The original IC-7300 uses CI-V $94 and is serial-only (not network capable).
  Some users change their IC-7300MK2 CI-V address to $94 for compatibility with
  software that only knows the IC-7300. The transport-reported address (from the
  capabilities handshake) always overrides this class default at connect time, so
  both factory-default ($B6) and user-customised ($94 or other) configurations work.
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
  // IC-7300MK2 CI-V transceive is at menu item $0089, not the default $0150 (IC-7610/IC-7760)
  FTransceiveMenuBytes := #$00 + #$89;
  logger.Info('[TIcom7300MK2Radio.Create] Created IC-7300MK2 instance with CI-V address $B6');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom7300MK2');

end.
