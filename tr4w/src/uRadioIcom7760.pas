unit uRadioIcom7760;

{
  Icom IC-7760 Radio Implementation

  The IC-7760 has several protocol differences from standard Icom radios:
    - CI-V address: 0xB2
    - Controller address: 0xE1 (NOT the typical 0xE0)
    - VFO B commands use $25/$26 extended format (FSupportsExtendedVFOBCommands = True,
      which is the base class default — no override needed)
    - Shared RIT/XIT offset (single offset for both)
}

interface

uses
  uRadioIcomBase, VC;

type
  TIcom7760Radio = class(TIcomRadio)
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  Log4D;

var
  logger: TLogLogger;

constructor TIcom7760Radio.Create;
begin
  inherited Create;
  RadioAddress := $B2;
  ControllerAddress := $E1;  // NOT the typical $E0
  radioModel := 'Icom IC-7760';
  logger.Info('[TIcom7760Radio.Create] Created IC-7760 instance, CI-V=$B2, Controller=$E1');
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcom7760');

end.
