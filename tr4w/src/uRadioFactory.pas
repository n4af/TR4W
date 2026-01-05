unit uRadioFactory;

{
  Radio Factory Pattern Implementation

  Purpose: Centralized creation of radio instances based on model type

  Usage:
    var radio: TNetRadioBase;
    radio := TRadioFactory.CreateRadio(rmElecraftK4, '192.168.1.100', 7373, @MyProcessMsg);
    radio.Connect;
}

interface

uses
   uNetRadioBase, uRadioElecraftK4, SysUtils, VC;

type
   TRadioModel = (
      rmNone,
      rmElecraftK4,
      rmElecraftK3,
      rmYaesuFTdx101,
      rmYaesuFT991,
      rmIcomIC7610,
      rmIcomIC7300,
      rmFlexRadio6000,
      rmHamLibDirect
   );

   TConnectionType = (ctNetwork, ctSerial);

   TRadioFactory = class
   private
      class function ModelToString(model: TRadioModel): string;
   public
      // Network connection
      class function CreateRadioNetwork(model: TRadioModel;
                                         address: string;
                                         port: integer;
                                         msgCallback: TProcessMsgRef): TNetRadioBase;
      // Serial connection
      class function CreateRadioSerial(model: TRadioModel;
                                        serialPort: PortType;
                                        msgCallback: TProcessMsgRef): TNetRadioBase;
      class function GetSupportedModels: string;
      class function IsModelSupported(model: TRadioModel): boolean;
   end;

   ERadioFactoryException = class(Exception);

implementation

uses Log4D, uRadioHamLibDirect;

var
   logger: TLogLogger;

class function TRadioFactory.CreateRadioNetwork(model: TRadioModel;
                                                 address: string;
                                                 port: integer;
                                                 msgCallback: TProcessMsgRef): TNetRadioBase;
begin
   Result := nil;

   logger.Info('[RadioFactory] Creating radio: Model=%s, Address=%s, Port=%d',
               [ModelToString(model), address, port]);

   case model of
      rmElecraftK4:
         begin
         Result := TK4Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         Result.radioModel := 'Elecraft K4';
         logger.Info('[RadioFactory] Created Elecraft K4 instance');
         end;

      rmElecraftK3:
         begin
         raise ERadioFactoryException.Create('Elecraft K3 not yet implemented');
         end;

      rmYaesuFTdx101:
         begin
         raise ERadioFactoryException.Create('Yaesu FTdx101 not yet implemented');
         end;

      rmYaesuFT991:
         begin
         raise ERadioFactoryException.Create('Yaesu FT991 not yet implemented');
         end;

      rmIcomIC7610:
         begin
         raise ERadioFactoryException.Create('Icom IC-7610 not yet implemented');
         end;

      rmIcomIC7300:
         begin
         raise ERadioFactoryException.Create('Icom IC-7300 not yet implemented');
         end;

      rmFlexRadio6000:
         begin
         raise ERadioFactoryException.Create('FlexRadio 6000 series not yet implemented');
         end;

      rmHamLibDirect:
         begin
         Result := THamLibDirect.Create(msgCallback);
         Result.radioAddress := address;
         Result.radioPort := port;
         Result.radioModel := 'HamLib Direct';
         logger.Info('[RadioFactory] Created HamLib Direct instance');
         logger.Info('[RadioFactory] Direct DLL mode - no rigctld process needed');
         logger.Info('[RadioFactory] Remember to set HamLibModelID and serial port before connecting');
         end;

      else
         begin
         raise ERadioFactoryException.CreateFmt('Unknown radio model: %d', [Ord(model)]);
         end;
   end;
end;

class function TRadioFactory.CreateRadioSerial(model: TRadioModel;
                                                serialPort: PortType;
                                                msgCallback: TProcessMsgRef): TNetRadioBase;
begin
   Result := nil;

   logger.Info('[RadioFactory] Creating radio for serial: Model=%s, Port=%d',
               [ModelToString(model), Ord(serialPort)]);

   case model of
      rmElecraftK4:
         begin
         Result := TK4Radio.Create;
         Result.serialPort := serialPort;
         Result.radioModel := 'Elecraft K4 (Serial)';
         logger.Info('[RadioFactory] Created Elecraft K4 instance for serial connection');
         end;

      rmElecraftK3:
         begin
         raise ERadioFactoryException.Create('Elecraft K3 serial not yet implemented');
         end;

      rmYaesuFTdx101:
         begin
         raise ERadioFactoryException.Create('Yaesu FTdx101 serial not yet implemented');
         end;

      rmYaesuFT991:
         begin
         raise ERadioFactoryException.Create('Yaesu FT991 serial not yet implemented');
         end;

      rmIcomIC7610:
         begin
         raise ERadioFactoryException.Create('Icom IC-7610 serial not yet implemented');
         end;

      rmIcomIC7300:
         begin
         raise ERadioFactoryException.Create('Icom IC-7300 serial not yet implemented');
         end;

      rmFlexRadio6000:
         begin
         raise ERadioFactoryException.Create('FlexRadio 6000 does not support serial connections');
         end;

      rmHamLibDirect:
         begin
         Result := THamLibDirect.Create(msgCallback);
         Result.serialPort := serialPort;
         Result.radioModel := 'HamLib Direct (Serial)';
         logger.Info('[RadioFactory] Created HamLib Direct instance for serial connection');
         end;

      else
         begin
         raise ERadioFactoryException.CreateFmt('Unknown radio model for serial: %d', [Ord(model)]);
         end;
   end;
end;

class function TRadioFactory.ModelToString(model: TRadioModel): string;
begin
   case model of
      rmNone:           Result := 'None';
      rmElecraftK4:     Result := 'Elecraft K4';
      rmElecraftK3:     Result := 'Elecraft K3';
      rmYaesuFTdx101:   Result := 'Yaesu FTdx101';
      rmYaesuFT991:     Result := 'Yaesu FT-991';
      rmIcomIC7610:     Result := 'Icom IC-7610';
      rmIcomIC7300:     Result := 'Icom IC-7300';
      rmFlexRadio6000:  Result := 'FlexRadio 6000';
      rmHamLibDirect:   Result := 'HamLib Direct (DLL)';
   else
      Result := 'Unknown';
   end;
end;

class function TRadioFactory.GetSupportedModels: string;
begin
   Result := 'Supported radio models:'#13#10 +
             '  - Elecraft K4 (implemented)'#13#10 +
             '  - HamLib Direct via DLL (implemented)'#13#10 +
             '  - Elecraft K3 (planned)'#13#10 +
             '  - Yaesu FTdx101 (planned)'#13#10 +
             '  - Yaesu FT-991 (planned)'#13#10 +
             '  - Icom IC-7610 (planned)'#13#10 +
             '  - Icom IC-7300 (planned)'#13#10 +
             '  - FlexRadio 6000 (planned)';
end;

class function TRadioFactory.IsModelSupported(model: TRadioModel): boolean;
begin
   // Currently K4 and HamLib Direct (DLL) are fully implemented
   Result := (model = rmElecraftK4) or (model = rmHamLibDirect);
end;

initialization
   logger := TLogLogger.GetLogger('uRadioFactory');
   logger.Info('Radio Factory initialized');

finalization
   logger.Info('Radio Factory finalized');

end.
