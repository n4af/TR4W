unit uExternalLoggerFactory;

{
  External Logger Factory Pattern Implementation

  Purpose: Centralized creation of external logger instances based on logger type

  Usage:
    var logger: TExternalLoggerBase;
    logger := TExternalLoggerFactory.CreateLogger(lt_DXKeeper, 'localhost', 52001, @MyProcessMsg);
    logger.Connect;
}

interface

uses
   uExternalLoggerBase, uExternalLogger, SysUtils;

type
   TExternalLoggerFactory = class
   private
      class function LoggerTypeToString(loggerType: ExternalLoggerType): string;
   public
      class function CreateLogger(loggerType: ExternalLoggerType;
                                   address: string;
                                   port: integer;
                                   msgCallback: TProcessMsgRef): TExternalLoggerBase;
      class function GetSupportedLoggers: string;
      class function IsLoggerSupported(loggerType: ExternalLoggerType): boolean;
   end;

   EExternalLoggerFactoryException = class(Exception);

implementation

uses Log4D;

var
   logger: TLogLogger;

class function TExternalLoggerFactory.CreateLogger(loggerType: ExternalLoggerType;
                                                    address: string;
                                                    port: integer;
                                                    msgCallback: TProcessMsgRef): TExternalLoggerBase;
var
   extLogger: TExternalLogger;
begin
   Result := nil;

   logger.Info('[ExternalLoggerFactory] Creating logger: Type=%s, Address=%s, Port=%d',
               [LoggerTypeToString(loggerType), address, port]);

   case loggerType of
      lt_NoExternalLogger:
         begin
         raise EExternalLoggerFactoryException.Create('Cannot create logger of type NoExternalLogger');
         end;

      lt_DXKeeper:
         begin
         extLogger := TExternalLogger.Create(loggerType);
         extLogger.loggerAddress := address;
         extLogger.loggerPort := port;
         extLogger.loggerID := 'DXKeeper';
         Result := extLogger;
         logger.Info('[ExternalLoggerFactory] Created DXKeeper logger instance');
         end;

      lt_ACLog:
         begin
         extLogger := TExternalLogger.Create(loggerType);
         extLogger.loggerAddress := address;
         extLogger.loggerPort := port;
         extLogger.loggerID := 'ACLog';
         Result := extLogger;
         logger.Info('[ExternalLoggerFactory] Created ACLog logger instance');
         logger.Warn('[ExternalLoggerFactory] ACLog implementation is incomplete');
         end;

      lt_HRD:
         begin
         extLogger := TExternalLogger.Create(loggerType);
         extLogger.loggerAddress := address;
         extLogger.loggerPort := port;
         extLogger.loggerID := 'HRD';
         Result := extLogger;
         logger.Info('[ExternalLoggerFactory] Created HRD logger instance');
         logger.Warn('[ExternalLoggerFactory] HRD implementation is incomplete');
         end;

      else
         begin
         raise EExternalLoggerFactoryException.CreateFmt('Unknown logger type: %d', [Ord(loggerType)]);
         end;
   end;
end;

class function TExternalLoggerFactory.LoggerTypeToString(loggerType: ExternalLoggerType): string;
begin
   case loggerType of
      lt_NoExternalLogger:  Result := 'None';
      lt_DXKeeper:          Result := 'DXKeeper';
      lt_ACLog:             Result := 'ACLog';
      lt_HRD:               Result := 'Ham Radio Deluxe';
   else
      Result := 'Unknown';
   end;
end;

class function TExternalLoggerFactory.GetSupportedLoggers: string;
begin
   Result := 'Supported external loggers:'#13#10 +
             '  - DXKeeper (implemented)'#13#10 +
             '  - ACLog (planned)'#13#10 +
             '  - Ham Radio Deluxe / HRD (planned)';
end;

class function TExternalLoggerFactory.IsLoggerSupported(loggerType: ExternalLoggerType): boolean;
begin
   // Currently only DXKeeper is fully implemented
   Result := (loggerType = lt_DXKeeper);
end;

initialization
   logger := TLogLogger.GetLogger('uExternalLoggerFactory');
   logger.Info('External Logger Factory initialized');

finalization
   logger.Info('External Logger Factory finalized');

end.
