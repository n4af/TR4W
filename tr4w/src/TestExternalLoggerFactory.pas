program TestExternalLoggerFactory;

{$APPTYPE CONSOLE}

uses
   SysUtils,
   uExternalLoggerBase in 'uExternalLoggerBase.pas',
   uExternalLogger in 'uExternalLogger.pas',
   uExternalLoggerFactory in 'uExternalLoggerFactory.pas',
   uExternalLoggerManager in 'uExternalLoggerManager.pas',
   Log4D,
   VC;

var
   logger: TLogLogger;

procedure ProcessDXKeeperMsg(sMessage: string);
begin
   WriteLn('[DXKeeper] Received: ', sMessage);
end;

procedure ProcessACLogMsg(sMessage: string);
begin
   WriteLn('[ACLog] Received: ', sMessage);
end;

procedure TestSingleLogger;
var
   extLogger: TExternalLoggerBase;
begin
   WriteLn('');
   WriteLn('=== Test 1: Single Logger Creation ===');
   WriteLn('');

   try
      // Create DXKeeper logger
      extLogger := TExternalLoggerFactory.CreateLogger(
         lt_DXKeeper,
         'localhost',
         52001,
         @ProcessDXKeeperMsg
      );

      try
         WriteLn('Created logger: ', extLogger.loggerID);
         WriteLn('Address: ', extLogger.loggerAddress);
         WriteLn('Port: ', extLogger.loggerPort);
         WriteLn('');

         WriteLn('Attempting to connect...');
         extLogger.Connect;

         if extLogger.IsConnected then
            begin
            WriteLn('Connected successfully!');
            end
         else
            begin
            WriteLn('Connection failed (this is normal if DXKeeper is not running)');
            end;

         WriteLn('Test 1 complete');
      finally
         extLogger.Free;
      end;
   except
      on E: Exception do
         begin
         WriteLn('Exception in Test 1: ', E.Message);
         end;
   end;
end;

procedure TestMultipleLoggers;
var
   manager: TExternalLoggerManager;
   logger1, logger2: TExternalLoggerBase;
   statusReport: string;
begin
   WriteLn('');
   WriteLn('=== Test 2: Multiple Loggers with Manager ===');
   WriteLn('');

   manager := TExternalLoggerManager.Create;
   try
      // Create two loggers
      logger1 := TExternalLoggerFactory.CreateLogger(
         lt_DXKeeper,
         'localhost',
         52001,
         @ProcessDXKeeperMsg
      );

      logger2 := TExternalLoggerFactory.CreateLogger(
         lt_ACLog,
         'localhost',
         52002,
         @ProcessACLogMsg
      );

      // Add to manager
      if manager.AddLogger('DXKeeper', logger1) then
         begin
         WriteLn('Added DXKeeper to manager');
         end;

      if manager.AddLogger('ACLog', logger2) then
         begin
         WriteLn('Added ACLog to manager');
         end;

      WriteLn('Total loggers: ', manager.GetLoggerCount);
      WriteLn('Active logger: ', manager.ActiveLoggerId);
      WriteLn('');

      // Get status report
      statusReport := manager.GetStatusReport;
      WriteLn(statusReport);

      // Try to connect all
      WriteLn('Attempting to connect all loggers...');
      manager.ConnectAll;
      WriteLn('Connect attempt complete (may fail if logger programs not running)');
      WriteLn('');

      WriteLn('Test 2 complete');
   finally
      manager.Free;  // Auto-disconnects and frees all loggers
   end;
end;

procedure TestFactoryMethods;
var
   supportedLoggers: string;
begin
   WriteLn('');
   WriteLn('=== Test 3: Factory Methods ===');
   WriteLn('');

   // Get supported loggers
   supportedLoggers := TExternalLoggerFactory.GetSupportedLoggers;
   WriteLn(supportedLoggers);
   WriteLn('');

   // Check individual logger support
   WriteLn('DXKeeper supported: ', BoolToStr(TExternalLoggerFactory.IsLoggerSupported(lt_DXKeeper), True));
   WriteLn('ACLog supported: ', BoolToStr(TExternalLoggerFactory.IsLoggerSupported(lt_ACLog), True));
   WriteLn('HRD supported: ', BoolToStr(TExternalLoggerFactory.IsLoggerSupported(lt_HRD), True));
   WriteLn('');

   WriteLn('Test 3 complete');
end;

procedure TestUnsupportedLogger;
begin
   WriteLn('');
   WriteLn('=== Test 4: Unsupported Logger Handling ===');
   WriteLn('');

   try
      WriteLn('Attempting to create NoExternalLogger (should fail)...');
      TExternalLoggerFactory.CreateLogger(
         lt_NoExternalLogger,
         'localhost',
         52001,
         @ProcessDXKeeperMsg
      );
      WriteLn('ERROR: Should have raised an exception!');
   except
      on E: EExternalLoggerFactoryException do
         begin
         WriteLn('Caught expected exception: ', E.Message);
         WriteLn('Test 4 complete');
         end;
      on E: Exception do
         begin
         WriteLn('Caught unexpected exception: ', E.Message);
         end;
   end;
end;

begin
   // Configure logging
   logger := TLogLogger.GetLogger('TestExternalLoggerFactory');
   TLogLogger.GetRootLogger.Level := Warn;  // Reduce log verbosity for test

   try
      WriteLn('===============================================');
      WriteLn('External Logger Factory Pattern - Test Program');
      WriteLn('===============================================');

      TestSingleLogger;
      TestMultipleLoggers;
      TestFactoryMethods;
      TestUnsupportedLogger;

      WriteLn('');
      WriteLn('===============================================');
      WriteLn('All tests complete!');
      WriteLn('===============================================');
      WriteLn('');
      WriteLn('Press Enter to exit...');
      ReadLn;
   except
      on E: Exception do
         begin
         WriteLn('');
         WriteLn('FATAL ERROR: ', E.Message);
         WriteLn('');
         WriteLn('Press Enter to exit...');
         ReadLn;
         end;
   end;
end.
