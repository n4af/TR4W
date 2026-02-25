unit uRadioManager;

{
  Radio Manager - Manages multiple radio instances

  Purpose: Centralized management of multiple radios for SO2R or multi-op stations

  Usage:
    var manager: TRadioManager;
    manager := TRadioManager.Create;
    manager.AddRadio('Radio1', radio1);
    manager.ConnectAll;
    manager.GetRadio('Radio1').SetFrequency(14025000, nrVFOA);
}

interface

uses
   uNetRadioBase, SysUtils, Classes, Generics.Collections;

type
   TRadioManager = class
   private
      FRadios: TDictionary<string, TNetRadioBase>;
      FActiveRadioId: string;
      function GetActiveRadio: TNetRadioBase;
      procedure SetActiveRadioId(const Value: string);
   public
      constructor Create;
      destructor Destroy; override;

      // Radio management
      function AddRadio(const radioId: string; radio: TNetRadioBase): boolean;
      function RemoveRadio(const radioId: string): boolean;
      function GetRadio(const radioId: string): TNetRadioBase;
      function HasRadio(const radioId: string): boolean;
      function GetRadioCount: integer;
      function GetRadioList: TArray<string>;

      // Connection management
      procedure ConnectAll;
      procedure DisconnectAll;
      function ConnectRadio(const radioId: string): boolean;
      function DisconnectRadio(const radioId: string): boolean;

      // Active radio management
      property ActiveRadioId: string read FActiveRadioId write SetActiveRadioId;
      property ActiveRadio: TNetRadioBase read GetActiveRadio;

      // Utility methods
      procedure ClearAll;
      function GetStatusReport: string;
   end;

   ERadioManagerException = class(Exception);

implementation

uses Log4D;

var
   logger: TLogLogger;

constructor TRadioManager.Create;
begin
   inherited Create;
   FRadios := TDictionary<string, TNetRadioBase>.Create;
   FActiveRadioId := '';
   logger.Info('[RadioManager] Created');
end;

destructor TRadioManager.Destroy;
begin
   logger.Info('[RadioManager] Destroying - cleaning up %d radios', [FRadios.Count]);
   ClearAll;
   FRadios.Free;
   inherited;
end;

function TRadioManager.AddRadio(const radioId: string; radio: TNetRadioBase): boolean;
begin
   Result := False;

   if radioId = '' then
      begin
      logger.Error('[RadioManager.AddRadio] Cannot add radio with empty ID');
      Exit;
      end;

   if not Assigned(radio) then
      begin
      logger.Error('[RadioManager.AddRadio] Cannot add nil radio with ID: %s', [radioId]);
      Exit;
      end;

   if FRadios.ContainsKey(radioId) then
      begin
      logger.Warn('[RadioManager.AddRadio] Radio ID already exists: %s', [radioId]);
      Exit;
      end;

   FRadios.Add(radioId, radio);
   logger.Info('[RadioManager.AddRadio] Added radio: %s (Model: %s)', [radioId, radio.radioModel]);

   // If this is the first radio, make it active
   if FActiveRadioId = '' then
      begin
      FActiveRadioId := radioId;
      logger.Info('[RadioManager.AddRadio] Set as active radio: %s', [radioId]);
      end;

   Result := True;
end;

function TRadioManager.RemoveRadio(const radioId: string): boolean;
var
   radio: TNetRadioBase;
begin
   Result := False;

   if not FRadios.TryGetValue(radioId, radio) then
      begin
      logger.Warn('[RadioManager.RemoveRadio] Radio not found: %s', [radioId]);
      Exit;
      end;

   // Disconnect if connected
   if radio.IsConnected then
      begin
      logger.Info('[RadioManager.RemoveRadio] Disconnecting radio: %s', [radioId]);
      radio.Disconnect;
      end;

   // Free the radio object
   radio.Free;

   // Remove from dictionary
   FRadios.Remove(radioId);
   logger.Info('[RadioManager.RemoveRadio] Removed radio: %s', [radioId]);

   // If this was the active radio, clear active radio
   if FActiveRadioId = radioId then
      begin
      FActiveRadioId := '';
      logger.Info('[RadioManager.RemoveRadio] Cleared active radio');
      end;

   Result := True;
end;

function TRadioManager.GetRadio(const radioId: string): TNetRadioBase;
begin
   if not FRadios.TryGetValue(radioId, Result) then
      begin
      logger.Warn('[RadioManager.GetRadio] Radio not found: %s', [radioId]);
      Result := nil;
      end;
end;

function TRadioManager.HasRadio(const radioId: string): boolean;
begin
   Result := FRadios.ContainsKey(radioId);
end;

function TRadioManager.GetRadioCount: integer;
begin
   Result := FRadios.Count;
end;

function TRadioManager.GetRadioList: TArray<string>;
begin
   Result := FRadios.Keys.ToArray;
end;

procedure TRadioManager.ConnectAll;
var
   radioId: string;
   radio: TNetRadioBase;
   connected: integer;
   failed: integer;
begin
   logger.Info('[RadioManager.ConnectAll] Connecting %d radios', [FRadios.Count]);

   connected := 0;
   failed := 0;

   for radioId in FRadios.Keys do
      begin
      radio := FRadios[radioId];

      if not Assigned(radio) then
         begin
         logger.Error('[RadioManager.ConnectAll] Radio %s is nil', [radioId]);
         Inc(failed);
         Continue;
         end;

      if radio.IsConnected then
         begin
         logger.Debug('[RadioManager.ConnectAll] Radio %s already connected', [radioId]);
         Inc(connected);
         Continue;
         end;

      logger.Info('[RadioManager.ConnectAll] Connecting radio: %s', [radioId]);
      try
         radio.Connect;
         if radio.IsConnected then
            begin
            Inc(connected);
            logger.Info('[RadioManager.ConnectAll] Successfully connected: %s', [radioId]);
            end
         else
            begin
            Inc(failed);
            logger.Error('[RadioManager.ConnectAll] Failed to connect: %s', [radioId]);
            end;
      except
         on E: Exception do
            begin
            Inc(failed);
            logger.Error('[RadioManager.ConnectAll] Exception connecting %s: %s', [radioId, E.Message]);
            end;
      end;
      end;

   logger.Info('[RadioManager.ConnectAll] Complete - Connected: %d, Failed: %d', [connected, failed]);
end;

procedure TRadioManager.DisconnectAll;
var
   radioId: string;
   radio: TNetRadioBase;
begin
   logger.Info('[RadioManager.DisconnectAll] Disconnecting %d radios', [FRadios.Count]);

   for radioId in FRadios.Keys do
      begin
      radio := FRadios[radioId];

      if not Assigned(radio) then
         begin
         Continue;
         end;

      if radio.IsConnected then
         begin
         logger.Info('[RadioManager.DisconnectAll] Disconnecting: %s', [radioId]);
         try
            radio.Disconnect;
         except
            on E: Exception do
               begin
               logger.Error('[RadioManager.DisconnectAll] Exception disconnecting %s: %s', [radioId, E.Message]);
               end;
         end;
         end;
      end;

   logger.Info('[RadioManager.DisconnectAll] Complete');
end;

function TRadioManager.ConnectRadio(const radioId: string): boolean;
var
   radio: TNetRadioBase;
begin
   Result := False;

   if not FRadios.TryGetValue(radioId, radio) then
      begin
      logger.Error('[RadioManager.ConnectRadio] Radio not found: %s', [radioId]);
      Exit;
      end;

   if radio.IsConnected then
      begin
      logger.Warn('[RadioManager.ConnectRadio] Radio already connected: %s', [radioId]);
      Result := True;
      Exit;
      end;

   logger.Info('[RadioManager.ConnectRadio] Connecting: %s', [radioId]);
   try
      radio.Connect;
      Result := radio.IsConnected;

      if Result then
         begin
         logger.Info('[RadioManager.ConnectRadio] Successfully connected: %s', [radioId]);
         end
      else
         begin
         logger.Error('[RadioManager.ConnectRadio] Failed to connect: %s', [radioId]);
         end;
   except
      on E: Exception do
         begin
         logger.Error('[RadioManager.ConnectRadio] Exception connecting %s: %s', [radioId, E.Message]);
         Result := False;
         end;
   end;
end;

function TRadioManager.DisconnectRadio(const radioId: string): boolean;
var
   radio: TNetRadioBase;
begin
   Result := False;

   if not FRadios.TryGetValue(radioId, radio) then
      begin
      logger.Error('[RadioManager.DisconnectRadio] Radio not found: %s', [radioId]);
      Exit;
      end;

   if not radio.IsConnected then
      begin
      logger.Warn('[RadioManager.DisconnectRadio] Radio not connected: %s', [radioId]);
      Result := True;
      Exit;
      end;

   logger.Info('[RadioManager.DisconnectRadio] Disconnecting: %s', [radioId]);
   try
      radio.Disconnect;
      Result := not radio.IsConnected;

      if Result then
         begin
         logger.Info('[RadioManager.DisconnectRadio] Successfully disconnected: %s', [radioId]);
         end
      else
         begin
         logger.Error('[RadioManager.DisconnectRadio] Failed to disconnect: %s', [radioId]);
         end;
   except
      on E: Exception do
         begin
         logger.Error('[RadioManager.DisconnectRadio] Exception disconnecting %s: %s', [radioId, E.Message]);
         Result := False;
         end;
   end;
end;

function TRadioManager.GetActiveRadio: TNetRadioBase;
begin
   if FActiveRadioId = '' then
      begin
      logger.Debug('[RadioManager.GetActiveRadio] No active radio set');
      Result := nil;
      Exit;
      end;

   if not FRadios.TryGetValue(FActiveRadioId, Result) then
      begin
      logger.Error('[RadioManager.GetActiveRadio] Active radio not found: %s', [FActiveRadioId]);
      Result := nil;
      end;
end;

procedure TRadioManager.SetActiveRadioId(const Value: string);
begin
   if Value = '' then
      begin
      FActiveRadioId := '';
      logger.Info('[RadioManager.SetActiveRadioId] Cleared active radio');
      Exit;
      end;

   if not FRadios.ContainsKey(Value) then
      begin
      logger.Error('[RadioManager.SetActiveRadioId] Radio not found: %s', [Value]);
      raise ERadioManagerException.CreateFmt('Radio "%s" not found in manager', [Value]);
      end;

   FActiveRadioId := Value;
   logger.Info('[RadioManager.SetActiveRadioId] Active radio: %s', [Value]);
end;

procedure TRadioManager.ClearAll;
var
   radioId: string;
   radio: TNetRadioBase;
begin
   logger.Info('[RadioManager.ClearAll] Clearing all radios');

   DisconnectAll;

   for radioId in FRadios.Keys do
      begin
      radio := FRadios[radioId];
      if Assigned(radio) then
         begin
         logger.Debug('[RadioManager.ClearAll] Freeing radio: %s', [radioId]);
         radio.Free;
         end;
      end;

   FRadios.Clear;
   FActiveRadioId := '';

   logger.Info('[RadioManager.ClearAll] Complete');
end;

function TRadioManager.GetStatusReport: string;
var
   radioId: string;
   radio: TNetRadioBase;
   sl: TStringList;
begin
   sl := TStringList.Create;
   try
      sl.Add('=== Radio Manager Status Report ===');
      sl.Add(Format('Total Radios: %d', [FRadios.Count]));
      sl.Add(Format('Active Radio: %s', [FActiveRadioId]));
      sl.Add('');

      if FRadios.Count = 0 then
         begin
         sl.Add('No radios configured');
         end
      else
         begin
         sl.Add('Radio Details:');
         for radioId in FRadios.Keys do
            begin
            radio := FRadios[radioId];
            if Assigned(radio) then
               begin
               sl.Add(Format('  [%s]', [radioId]));
               sl.Add(Format('    Model: %s', [radio.radioModel]));
               sl.Add(Format('    Address: %s:%d', [radio.radioAddress, radio.radioPort]));
               sl.Add(Format('    Connected: %s', [BoolToStr(radio.IsConnected, True)]));
               if radio.IsConnected then
                  begin
                  sl.Add(Format('    Frequency A: %d Hz', [radio.frequency[nrVFOA]]));
                  sl.Add(Format('    Mode A: %s', [radio.ModeToString(radio.mode[nrVFOA])]));
                  sl.Add(Format('    Band A: %d', [Ord(radio.band[nrVFOA])]));
                  end;
               end
            else
               begin
               sl.Add(Format('  [%s] - NIL RADIO', [radioId]));
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
   logger := TLogLogger.GetLogger('uRadioManager');
   logger.Info('Radio Manager initialized');

finalization
   logger.Info('Radio Manager finalized');

end.
