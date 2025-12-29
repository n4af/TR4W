unit uExternalLoggerManager;

{
  External Logger Manager - Manages multiple external logger instances

  Purpose: Centralized management of multiple external loggers for simultaneous logging

  Usage:
    var manager: TExternalLoggerManager;
    manager := TExternalLoggerManager.Create;
    manager.AddLogger('DXKeeper', dxkLogger);
    manager.AddLogger('ACLog', aclogLogger);
    manager.ConnectAll;
    manager.LogQSOToAll(qsoExchange);
}

interface

uses
   uExternalLoggerBase, SysUtils, Classes, Generics.Collections, VC;

type
   TExternalLoggerManager = class
   private
      FLoggers: TDictionary<string, TExternalLoggerBase>;
      FActiveLoggerId: string;
      function GetActiveLogger: TExternalLoggerBase;
      procedure SetActiveLoggerId(const Value: string);
   public
      constructor Create;
      destructor Destroy; override;

      // Logger management
      function AddLogger(const loggerId: string; logger: TExternalLoggerBase): boolean;
      function RemoveLogger(const loggerId: string): boolean;
      function GetLogger(const loggerId: string): TExternalLoggerBase;
      function HasLogger(const loggerId: string): boolean;
      function GetLoggerCount: integer;
      function GetLoggerList: TArray<string>;

      // Connection management
      procedure ConnectAll;
      procedure DisconnectAll;
      function ConnectLogger(const loggerId: string): boolean;
      function DisconnectLogger(const loggerId: string): boolean;

      // Active logger management
      property ActiveLoggerId: string read FActiveLoggerId write SetActiveLoggerId;
      property ActiveLogger: TExternalLoggerBase read GetActiveLogger;

      // Bulk operations
      function LogQSOToAll(ce: ContestExchange): integer;
      function DeleteQSOFromAll(ce: ContestExchange): integer;

      // Utility methods
      procedure ClearAll;
      function GetStatusReport: string;
   end;

   EExternalLoggerManagerException = class(Exception);

implementation

uses Log4D, uExternalLogger;

var
   logger: TLogLogger;

constructor TExternalLoggerManager.Create;
begin
   inherited Create;
   FLoggers := TDictionary<string, TExternalLoggerBase>.Create;
   FActiveLoggerId := '';
   logger.Info('[ExternalLoggerManager] Created');
end;

destructor TExternalLoggerManager.Destroy;
begin
   logger.Info('[ExternalLoggerManager] Destroying - cleaning up %d loggers', [FLoggers.Count]);
   ClearAll;
   FLoggers.Free;
   inherited;
end;

function TExternalLoggerManager.AddLogger(const loggerId: string; logger: TExternalLoggerBase): boolean;
begin
   Result := False;

   if loggerId = '' then
      begin
      logger.Error('[ExternalLoggerManager.AddLogger] Cannot add logger with empty ID');
      Exit;
      end;

   if not Assigned(logger) then
      begin
      logger.Error('[ExternalLoggerManager.AddLogger] Cannot add nil logger with ID: %s', [loggerId]);
      Exit;
      end;

   if FLoggers.ContainsKey(loggerId) then
      begin
      logger.Warn('[ExternalLoggerManager.AddLogger] Logger ID already exists: %s', [loggerId]);
      Exit;
      end;

   FLoggers.Add(loggerId, logger);
   logger.Info('[ExternalLoggerManager.AddLogger] Added logger: %s (ID: %s)', [loggerId, logger.loggerID]);

   // If this is the first logger, make it active
   if FActiveLoggerId = '' then
      begin
      FActiveLoggerId := loggerId;
      logger.Info('[ExternalLoggerManager.AddLogger] Set as active logger: %s', [loggerId]);
      end;

   Result := True;
end;

function TExternalLoggerManager.RemoveLogger(const loggerId: string): boolean;
var
   extLogger: TExternalLoggerBase;
begin
   Result := False;

   if not FLoggers.TryGetValue(loggerId, extLogger) then
      begin
      logger.Warn('[ExternalLoggerManager.RemoveLogger] Logger not found: %s', [loggerId]);
      Exit;
      end;

   // Disconnect if connected
   if extLogger.IsConnected then
      begin
      logger.Info('[ExternalLoggerManager.RemoveLogger] Disconnecting logger: %s', [loggerId]);
      extLogger.Disconnect;
      end;

   // Free the logger object
   extLogger.Free;

   // Remove from dictionary
   FLoggers.Remove(loggerId);
   logger.Info('[ExternalLoggerManager.RemoveLogger] Removed logger: %s', [loggerId]);

   // If this was the active logger, clear active logger
   if FActiveLoggerId = loggerId then
      begin
      FActiveLoggerId := '';
      logger.Info('[ExternalLoggerManager.RemoveLogger] Cleared active logger');
      end;

   Result := True;
end;

function TExternalLoggerManager.GetLogger(const loggerId: string): TExternalLoggerBase;
begin
   if not FLoggers.TryGetValue(loggerId, Result) then
      begin
      logger.Warn('[ExternalLoggerManager.GetLogger] Logger not found: %s', [loggerId]);
      Result := nil;
      end;
end;

function TExternalLoggerManager.HasLogger(const loggerId: string): boolean;
begin
   Result := FLoggers.ContainsKey(loggerId);
end;

function TExternalLoggerManager.GetLoggerCount: integer;
begin
   Result := FLoggers.Count;
end;

function TExternalLoggerManager.GetLoggerList: TArray<string>;
begin
   Result := FLoggers.Keys.ToArray;
end;

procedure TExternalLoggerManager.ConnectAll;
var
   loggerId: string;
   extLogger: TExternalLoggerBase;
   connected: integer;
   failed: integer;
begin
   logger.Info('[ExternalLoggerManager.ConnectAll] Connecting %d loggers', [FLoggers.Count]);

   connected := 0;
   failed := 0;

   for loggerId in FLoggers.Keys do
      begin
      extLogger := FLoggers[loggerId];

      if not Assigned(extLogger) then
         begin
         logger.Error('[ExternalLoggerManager.ConnectAll] Logger %s is nil', [loggerId]);
         Inc(failed);
         Continue;
         end;

      if extLogger.IsConnected then
         begin
         logger.Debug('[ExternalLoggerManager.ConnectAll] Logger %s already connected', [loggerId]);
         Inc(connected);
         Continue;
         end;

      logger.Info('[ExternalLoggerManager.ConnectAll] Connecting logger: %s', [loggerId]);
      try
         extLogger.Connect;
         if extLogger.IsConnected then
            begin
            Inc(connected);
            logger.Info('[ExternalLoggerManager.ConnectAll] Successfully connected: %s', [loggerId]);
            end
         else
            begin
            Inc(failed);
            logger.Error('[ExternalLoggerManager.ConnectAll] Failed to connect: %s', [loggerId]);
            end;
      except
         on E: Exception do
            begin
            Inc(failed);
            logger.Error('[ExternalLoggerManager.ConnectAll] Exception connecting %s: %s', [loggerId, E.Message]);
            end;
      end;
      end;

   logger.Info('[ExternalLoggerManager.ConnectAll] Complete - Connected: %d, Failed: %d', [connected, failed]);
end;

procedure TExternalLoggerManager.DisconnectAll;
var
   loggerId: string;
   extLogger: TExternalLoggerBase;
begin
   logger.Info('[ExternalLoggerManager.DisconnectAll] Disconnecting %d loggers', [FLoggers.Count]);

   for loggerId in FLoggers.Keys do
      begin
      extLogger := FLoggers[loggerId];

      if not Assigned(extLogger) then
         begin
         Continue;
         end;

      if extLogger.IsConnected then
         begin
         logger.Info('[ExternalLoggerManager.DisconnectAll] Disconnecting: %s', [loggerId]);
         try
            extLogger.Disconnect;
         except
            on E: Exception do
               begin
               logger.Error('[ExternalLoggerManager.DisconnectAll] Exception disconnecting %s: %s', [loggerId, E.Message]);
               end;
         end;
         end;
      end;

   logger.Info('[ExternalLoggerManager.DisconnectAll] Complete');
end;

function TExternalLoggerManager.ConnectLogger(const loggerId: string): boolean;
var
   extLogger: TExternalLoggerBase;
begin
   Result := False;

   if not FLoggers.TryGetValue(loggerId, extLogger) then
      begin
      logger.Error('[ExternalLoggerManager.ConnectLogger] Logger not found: %s', [loggerId]);
      Exit;
      end;

   if extLogger.IsConnected then
      begin
      logger.Warn('[ExternalLoggerManager.ConnectLogger] Logger already connected: %s', [loggerId]);
      Result := True;
      Exit;
      end;

   logger.Info('[ExternalLoggerManager.ConnectLogger] Connecting: %s', [loggerId]);
   try
      extLogger.Connect;
      Result := extLogger.IsConnected;

      if Result then
         begin
         logger.Info('[ExternalLoggerManager.ConnectLogger] Successfully connected: %s', [loggerId]);
         end
      else
         begin
         logger.Error('[ExternalLoggerManager.ConnectLogger] Failed to connect: %s', [loggerId]);
         end;
   except
      on E: Exception do
         begin
         logger.Error('[ExternalLoggerManager.ConnectLogger] Exception connecting %s: %s', [loggerId, E.Message]);
         Result := False;
         end;
   end;
end;

function TExternalLoggerManager.DisconnectLogger(const loggerId: string): boolean;
var
   extLogger: TExternalLoggerBase;
begin
   Result := False;

   if not FLoggers.TryGetValue(loggerId, extLogger) then
      begin
      logger.Error('[ExternalLoggerManager.DisconnectLogger] Logger not found: %s', [loggerId]);
      Exit;
      end;

   if not extLogger.IsConnected then
      begin
      logger.Warn('[ExternalLoggerManager.DisconnectLogger] Logger not connected: %s', [loggerId]);
      Result := True;
      Exit;
      end;

   logger.Info('[ExternalLoggerManager.DisconnectLogger] Disconnecting: %s', [loggerId]);
   try
      extLogger.Disconnect;
      Result := not extLogger.IsConnected;

      if Result then
         begin
         logger.Info('[ExternalLoggerManager.DisconnectLogger] Successfully disconnected: %s', [loggerId]);
         end
      else
         begin
         logger.Error('[ExternalLoggerManager.DisconnectLogger] Failed to disconnect: %s', [loggerId]);
         end;
   except
      on E: Exception do
         begin
         logger.Error('[ExternalLoggerManager.DisconnectLogger] Exception disconnecting %s: %s', [loggerId, E.Message]);
         Result := False;
         end;
   end;
end;

function TExternalLoggerManager.GetActiveLogger: TExternalLoggerBase;
begin
   if FActiveLoggerId = '' then
      begin
      logger.Debug('[ExternalLoggerManager.GetActiveLogger] No active logger set');
      Result := nil;
      Exit;
      end;

   if not FLoggers.TryGetValue(FActiveLoggerId, Result) then
      begin
      logger.Error('[ExternalLoggerManager.GetActiveLogger] Active logger not found: %s', [FActiveLoggerId]);
      Result := nil;
      end;
end;

procedure TExternalLoggerManager.SetActiveLoggerId(const Value: string);
begin
   if Value = '' then
      begin
      FActiveLoggerId := '';
      logger.Info('[ExternalLoggerManager.SetActiveLoggerId] Cleared active logger');
      Exit;
      end;

   if not FLoggers.ContainsKey(Value) then
      begin
      logger.Error('[ExternalLoggerManager.SetActiveLoggerId] Logger not found: %s', [Value]);
      raise EExternalLoggerManagerException.CreateFmt('Logger "%s" not found in manager', [Value]);
      end;

   FActiveLoggerId := Value;
   logger.Info('[ExternalLoggerManager.SetActiveLoggerId] Active logger: %s', [Value]);
end;

function TExternalLoggerManager.LogQSOToAll(ce: ContestExchange): integer;
var
   loggerId: string;
   extLogger: TExternalLoggerBase;
   typedLogger: TExternalLogger;
   successCount: integer;
   failCount: integer;
begin
   logger.Info('[ExternalLoggerManager.LogQSOToAll] Logging QSO to %d loggers', [FLoggers.Count]);

   successCount := 0;
   failCount := 0;

   for loggerId in FLoggers.Keys do
      begin
      extLogger := FLoggers[loggerId];

      if not Assigned(extLogger) then
         begin
         logger.Error('[ExternalLoggerManager.LogQSOToAll] Logger %s is nil', [loggerId]);
         Inc(failCount);
         Continue;
         end;

      if not extLogger.IsConnected then
         begin
         logger.Warn('[ExternalLoggerManager.LogQSOToAll] Logger %s not connected, skipping', [loggerId]);
         Inc(failCount);
         Continue;
         end;

      try
         // Cast to TExternalLogger to access LogQSO method
         typedLogger := extLogger as TExternalLogger;
         typedLogger.LogQSO(ce);
         Inc(successCount);
         logger.Debug('[ExternalLoggerManager.LogQSOToAll] Logged QSO to %s', [loggerId]);
      except
         on E: Exception do
            begin
            Inc(failCount);
            logger.Error('[ExternalLoggerManager.LogQSOToAll] Exception logging to %s: %s', [loggerId, E.Message]);
            end;
      end;
      end;

   logger.Info('[ExternalLoggerManager.LogQSOToAll] Complete - Success: %d, Failed: %d', [successCount, failCount]);
   Result := successCount;
end;

function TExternalLoggerManager.DeleteQSOFromAll(ce: ContestExchange): integer;
var
   loggerId: string;
   extLogger: TExternalLoggerBase;
   typedLogger: TExternalLogger;
   successCount: integer;
   failCount: integer;
begin
   logger.Info('[ExternalLoggerManager.DeleteQSOFromAll] Deleting QSO from %d loggers', [FLoggers.Count]);

   successCount := 0;
   failCount := 0;

   for loggerId in FLoggers.Keys do
      begin
      extLogger := FLoggers[loggerId];

      if not Assigned(extLogger) then
         begin
         logger.Error('[ExternalLoggerManager.DeleteQSOFromAll] Logger %s is nil', [loggerId]);
         Inc(failCount);
         Continue;
         end;

      if not extLogger.IsConnected then
         begin
         logger.Warn('[ExternalLoggerManager.DeleteQSOFromAll] Logger %s not connected, skipping', [loggerId]);
         Inc(failCount);
         Continue;
         end;

      try
         // Cast to TExternalLogger to access DeleteQSO method
         typedLogger := extLogger as TExternalLogger;
         typedLogger.DeleteQSO(ce);
         Inc(successCount);
         logger.Debug('[ExternalLoggerManager.DeleteQSOFromAll] Deleted QSO from %s', [loggerId]);
      except
         on E: Exception do
            begin
            Inc(failCount);
            logger.Error('[ExternalLoggerManager.DeleteQSOFromAll] Exception deleting from %s: %s', [loggerId, E.Message]);
            end;
      end;
      end;

   logger.Info('[ExternalLoggerManager.DeleteQSOFromAll] Complete - Success: %d, Failed: %d', [successCount, failCount]);
   Result := successCount;
end;

procedure TExternalLoggerManager.ClearAll;
var
   loggerId: string;
   extLogger: TExternalLoggerBase;
begin
   logger.Info('[ExternalLoggerManager.ClearAll] Clearing all loggers');

   DisconnectAll;

   for loggerId in FLoggers.Keys do
      begin
      extLogger := FLoggers[loggerId];
      if Assigned(extLogger) then
         begin
         logger.Debug('[ExternalLoggerManager.ClearAll] Freeing logger: %s', [loggerId]);
         extLogger.Free;
         end;
      end;

   FLoggers.Clear;
   FActiveLoggerId := '';

   logger.Info('[ExternalLoggerManager.ClearAll] Complete');
end;

function TExternalLoggerManager.GetStatusReport: string;
var
   loggerId: string;
   extLogger: TExternalLoggerBase;
   sl: TStringList;
begin
   sl := TStringList.Create;
   try
      sl.Add('=== External Logger Manager Status Report ===');
      sl.Add(Format('Total Loggers: %d', [FLoggers.Count]));
      sl.Add(Format('Active Logger: %s', [FActiveLoggerId]));
      sl.Add('');

      if FLoggers.Count = 0 then
         begin
         sl.Add('No external loggers configured');
         end
      else
         begin
         sl.Add('Logger Details:');
         for loggerId in FLoggers.Keys do
            begin
            extLogger := FLoggers[loggerId];
            if Assigned(extLogger) then
               begin
               sl.Add(Format('  [%s]', [loggerId]));
               sl.Add(Format('    Logger ID: %s', [extLogger.loggerID]));
               sl.Add(Format('    Address: %s:%d', [extLogger.loggerAddress, extLogger.loggerPort]));
               sl.Add(Format('    Connected: %s', [BoolToStr(extLogger.IsConnected, True)]));
               end
            else
               begin
               sl.Add(Format('  [%s] - NIL LOGGER', [loggerId]));
               end;
            sl.Add('');
            end;
         end;

      Result := sl.Text;
   finally
      sl.Free;
   end;
end;

initialization
   logger := TLogLogger.GetLogger('uExternalLoggerManager');
   logger.Info('External Logger Manager initialized');

finalization
   logger.Info('External Logger Manager finalized');

end.
