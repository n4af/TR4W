program RadioFactoryTester;

{
  Radio Factory Test Harness

  Interactive tool for testing radio commands against physical hardware.
  Supports K4 (network/serial) and IC-9700 (serial) via factory pattern.
}

uses
  Forms,
  uTestMain in 'test\uTestMain.pas' {frmTestMain},
  uTestDefinitions in 'test\uTestDefinitions.pas',
  uRadioFactory in 'src\uRadioFactory.pas',
  uNetRadioBase in 'src\uNetRadioBase.pas',
  uRadioElecraftK4 in 'src\uRadioElecraftK4.pas',
  uRadioIcomBase in 'src\uRadioIcomBase.pas',
  uRadioIcom9700 in 'src\uRadioIcom9700.pas',
  Log4D in 'src\Log4D.pas';

// {$R *.res}  // Resource file not needed for testing

begin
  Application.Initialize;
  Application.Title := 'TR4W Radio Factory Tester';
  Application.CreateForm(TfrmTestMain, frmTestMain);
  Application.Run;
end.
