program TestRadioFactory;

{$APPTYPE CONSOLE}

{
  Test Program for Radio Factory and Radio Manager

  This demonstrates the usage of the factory pattern for creating
  and managing multiple radio instances.

  Compile: dcc32 TestRadioFactory.pas
}

uses
  SysUtils,
  uNetRadioBase,
  uRadioFactory,
  uRadioManager,
  Log4D;

var
  logger: TLogLogger;
  radioManager: TRadioManager;
  radio1, radio2: TNetRadioBase;

procedure ProcessRadio1Message(msg: string);
begin
  WriteLn('[Radio1] Received: ', msg);
end;

procedure ProcessRadio2Message(msg: string);
begin
  WriteLn('[Radio2] Received: ', msg);
end;

procedure TestSingleRadio;
var
  radio: TNetRadioBase;
begin
  WriteLn('=== Test 1: Single Radio Creation ===');
  WriteLn;

  try
    // Create a single K4 radio using factory
    radio := TRadioFactory.CreateRadio(rmElecraftK4,
                                       '192.168.1.100',
                                       7373,
                                       ProcessRadio1Message);

    WriteLn('Created radio: ', radio.radioModel);
    WriteLn('Address: ', radio.radioAddress);
    WriteLn('Port: ', radio.radioPort);
    WriteLn;

    // Attempt to connect (will fail if no radio at this address)
    WriteLn('Attempting to connect...');
    radio.Connect;

    if radio.IsConnected then
    begin
      WriteLn('Connected successfully!');
      radio.Disconnect;
    end
    else
    begin
      WriteLn('Connection failed (this is normal if no radio present)');
    end;

    // Cleanup
    radio.Free;
    WriteLn('Test 1 complete');
  except
    on E: Exception do
      WriteLn('Exception: ', E.Message);
  end;

  WriteLn;
end;

procedure TestMultipleRadios;
begin
  WriteLn('=== Test 2: Multiple Radios with Manager ===');
  WriteLn;

  try
    radioManager := TRadioManager.Create;
    try
      // Create two radios
      radio1 := TRadioFactory.CreateRadio(rmElecraftK4,
                                          '192.168.1.100',
                                          7373,
                                          ProcessRadio1Message);

      radio2 := TRadioFactory.CreateRadio(rmElecraftK4,
                                          '192.168.1.101',
                                          7373,
                                          ProcessRadio2Message);

      // Add to manager
      if radioManager.AddRadio('Radio1', radio1) then
        WriteLn('Added Radio1 to manager');

      if radioManager.AddRadio('Radio2', radio2) then
        WriteLn('Added Radio2 to manager');

      WriteLn('Total radios: ', radioManager.GetRadioCount);
      WriteLn('Active radio: ', radioManager.ActiveRadioId);
      WriteLn;

      // Get status report
      WriteLn(radioManager.GetStatusReport);

      // Attempt to connect all
      WriteLn('Attempting to connect all radios...');
      radioManager.ConnectAll;
      WriteLn('(Connections may fail if no radios present)');
      WriteLn;

      // Access individual radios
      WriteLn('Accessing Radio1:');
      if radioManager.HasRadio('Radio1') then
      begin
        WriteLn('  Connected: ', radioManager.GetRadio('Radio1').IsConnected);
      end;

      WriteLn('Accessing Radio2:');
      if radioManager.HasRadio('Radio2') then
      begin
        WriteLn('  Connected: ', radioManager.GetRadio('Radio2').IsConnected);
      end;

      WriteLn;
      WriteLn('Test 2 complete');

    finally
      radioManager.Free;  // Automatically disconnects and frees all radios
    end;

  except
    on E: Exception do
      WriteLn('Exception: ', E.Message);
  end;

  WriteLn;
end;

procedure TestFactoryMethods;
begin
  WriteLn('=== Test 3: Factory Methods ===');
  WriteLn;

  WriteLn(TRadioFactory.GetSupportedModels);
  WriteLn;

  WriteLn('Is K4 supported? ', BoolToStr(TRadioFactory.IsModelSupported(rmElecraftK4), True));
  WriteLn('Is Yaesu supported? ', BoolToStr(TRadioFactory.IsModelSupported(rmYaesuFTdx101), True));
  WriteLn;

  WriteLn('Test 3 complete');
  WriteLn;
end;

procedure TestUnsupportedRadio;
begin
  WriteLn('=== Test 4: Unsupported Radio (Expected to Fail) ===');
  WriteLn;

  try
    // Try to create unsupported radio
    radio1 := TRadioFactory.CreateRadio(rmYaesuFTdx101,
                                        '192.168.1.100',
                                        7373,
                                        ProcessRadio1Message);
    WriteLn('ERROR: Should have thrown exception!');
  except
    on E: ERadioFactoryException do
      WriteLn('Caught expected exception: ', E.Message);
    on E: Exception do
      WriteLn('Unexpected exception: ', E.Message);
  end;

  WriteLn;
  WriteLn('Test 4 complete');
  WriteLn;
end;

begin
  // Initialize logging
  TLogBasicConfigurator.Configure;
  TLogLogger.GetRootLogger.Level := Info;
  logger := TLogLogger.GetLogger('TestRadioFactory');

  WriteLn('===============================================');
  WriteLn('Radio Factory Pattern - Test Program');
  WriteLn('===============================================');
  WriteLn;

  try
    // Run tests
    TestFactoryMethods;
    TestSingleRadio;
    TestMultipleRadios;
    TestUnsupportedRadio;

    WriteLn('===============================================');
    WriteLn('All tests complete!');
    WriteLn('===============================================');

  except
    on E: Exception do
    begin
      WriteLn('FATAL ERROR: ', E.Message);
      ExitCode := 1;
    end;
  end;

  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
