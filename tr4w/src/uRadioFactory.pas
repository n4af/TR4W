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
   Windows, uNetRadioBase, uRadioElecraftK4, uFlexRadio6000, SysUtils, VC;

type
   TRadioModel = (
      rmNone,
      rmElecraftK4,
      rmElecraftK3,
      rmYaesuFTdx101,
      rmYaesuFT991,
      rmIcomIC7610,
      rmIcomIC7300,
      rmIcomIC9700,
      rmIcomIC705,
      rmIcomIC7300MK2,
      rmIcomIC7600,
      rmIcomIC7760,
      rmIcomIC7850,
      rmIcomIC905,
      rmIcomIC7100,
      rmFlexRadio6000,
      rmKenwoodTS890,   // Issue #436 -- TS-890 network (Kenwood CAT over TCP + ##CN/##ID auth)
      rmKenwoodTS990,   // TS-990 network (reuses the TS-890 CAT/auth path)
      rmHamLibDirect
   );

   TConnectionType = (ctNetwork, ctSerial);

   TRadioFactory = class
   public
      class function ModelToString(model: TRadioModel): string;
      // Network connection
      class function CreateRadioNetwork(model: TRadioModel;
                                         address: string;
                                         port: integer;
                                         msgCallback: TProcessMsgRef): TNetRadioBase;
      // Serial connection
      class function CreateRadioSerial(model: TRadioModel;
                                        serialPort: PortType;
                                        baudRate: DWORD;
                                        dataBits: Byte;
                                        stopBits: Byte;
                                        parity: Byte;
                                        msgCallback: TProcessMsgRef;
                                        rts: Boolean = False;
                                        dtr: Boolean = False): TNetRadioBase;
      class function GetSupportedModels: string;
      class function IsModelSupported(model: TRadioModel): boolean;

      // Network metadata (Issue #1028) -- single source of truth for "is this a
      // network radio", its default TCP/UDP port, and whether TR4W can auto-
      // discover it on the LAN.  Keyed by TRadioModel; legacy InterfacedRadioType
      // callers bridge via ModelForInterfacedType.
      class function ModelForInterfacedType(rt: InterfacedRadioType): TRadioModel;
      class function DefaultNetworkPort(model: TRadioModel): integer;
      class function IsNetworkModel(model: TRadioModel): boolean;
      class function IsDiscoverable(model: TRadioModel): boolean;
   end;

   ERadioFactoryException = class(Exception);

implementation

uses Log4D, uRadioHamLibDirect, uRadioIcomBase,
     uRadioIcom7300, uRadioIcom7610, uRadioIcom9700,
     uRadioIcom705, uRadioIcom7300MK2, uRadioIcom7600,
     uRadioIcom7760, uRadioIcom7850, uRadioIcom905, uRadioIcom7100,
     uRadioKenwoodTS890;  // Issue #436

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
         Result := TIcom7610Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         Result.radioModel := 'Icom IC-7610';
         logger.Info('[RadioFactory] Created Icom IC-7610 instance');
         end;

      rmIcomIC7300:
         begin
         Result := TIcom7300Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         Result.radioModel := 'Icom IC-7300';
         logger.Info('[RadioFactory] Created Icom IC-7300 instance');
         end;

      rmIcomIC9700:
         begin
         Result := TIcom9700Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         Result.radioModel := 'Icom IC-9700';
         logger.Info('[RadioFactory] Created Icom IC-9700 instance');
         end;

      rmIcomIC705:
         begin
         Result := TIcom705Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         logger.Info('[RadioFactory] Created Icom IC-705 instance');
         end;

      rmIcomIC7300MK2:
         begin
         Result := TIcom7300MK2Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         logger.Info('[RadioFactory] Created Icom IC-7300MK2 instance');
         end;

      rmIcomIC7600:
         begin
         Result := TIcom7600Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         logger.Info('[RadioFactory] Created Icom IC-7600 instance');
         end;

      rmIcomIC7760:
         begin
         Result := TIcom7760Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         logger.Info('[RadioFactory] Created Icom IC-7760 instance');
         end;

      rmIcomIC7850:
         begin
         Result := TIcom7850Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         logger.Info('[RadioFactory] Created Icom IC-7850 instance');
         end;

      rmIcomIC905:
         begin
         Result := TIcom905Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         logger.Info('[RadioFactory] Created Icom IC-905 instance');
         end;

      rmFlexRadio6000:
         begin
         Result := TFlexRadio6000.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         Result.radioModel := 'FlexRadio 6000';
         logger.Info('[RadioFactory] Created FlexRadio 6000 instance');
         end;

      rmKenwoodTS890:
         begin
         Result := TKenwoodTS890Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         Result.radioModel := 'Kenwood TS-890S';
         logger.Info('[RadioFactory] Created Kenwood TS-890 instance (Issue #436)');
         logger.Info('[RadioFactory] Remember to set NetworkUsername/NetworkPassword before Connect');
         end;

      rmKenwoodTS990:
         begin
         // Reuses the TS-890 network class (shared Kenwood CAT-over-TCP + ##CN/##ID auth).
         Result := TKenwoodTS890Radio.Create;
         Result.radioAddress := address;
         Result.radioPort := port;
         Result.radioModel := 'Kenwood TS-990S';
         logger.Info('[RadioFactory] Created Kenwood TS-990 instance (via TS-890 class)');
         logger.Info('[RadioFactory] Remember to set NetworkUsername/NetworkPassword before Connect');
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
                                                baudRate: DWORD;
                                                dataBits: Byte;
                                                stopBits: Byte;
                                                parity: Byte;
                                                msgCallback: TProcessMsgRef;
                                                rts: Boolean;
                                                dtr: Boolean): TNetRadioBase;
begin
   Result := nil;

   logger.Info('[RadioFactory] Creating radio for serial: Model=%s, Port=%d, Baud=%d, %dN%d',
               [ModelToString(model), Ord(serialPort), baudRate, dataBits, stopBits]);

   case model of
      rmElecraftK4:
         begin
         Result := TK4Radio.Create;
         Result.serialPort := serialPort;
         Result.serialBaudRate := baudRate;
         Result.serialDataBits := dataBits;
         Result.serialStopBits := stopBits;
         Result.serialParity := parity;
         Result.serialRts := rts;
         Result.serialDtr := dtr;
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
         Result := TIcom7610Radio.Create;
         Result.serialPort := serialPort;
         Result.serialBaudRate := baudRate;
         Result.serialDataBits := dataBits;
         Result.serialStopBits := stopBits;
         Result.serialParity := parity;
         Result.serialRts := rts;
         Result.serialDtr := dtr;
         Result.radioModel := 'Icom IC-7610 (Serial)';
         logger.Info('[RadioFactory] Created Icom IC-7610 instance for serial connection');
         end;

      rmIcomIC7300:
         begin
         Result := TIcom7300Radio.Create;
         Result.serialPort := serialPort;
         Result.serialBaudRate := baudRate;
         Result.serialDataBits := dataBits;
         Result.serialStopBits := stopBits;
         Result.serialParity := parity;
         Result.serialRts := rts;
         Result.serialDtr := dtr;
         Result.radioModel := 'Icom IC-7300 (Serial)';
         logger.Info('[RadioFactory] Created Icom IC-7300 instance for serial connection');
         end;

      rmIcomIC9700:
         begin
         Result := TIcom9700Radio.Create;
         Result.serialPort := serialPort;
         Result.serialBaudRate := baudRate;
         Result.serialDataBits := dataBits;
         Result.serialStopBits := stopBits;
         Result.serialParity := parity;
         Result.serialRts := rts;
         Result.serialDtr := dtr;
         Result.radioModel := 'Icom IC-9700 (Serial)';
         logger.Info('[RadioFactory] Created Icom IC-9700 instance for serial connection');
         end;

      rmIcomIC705:
         begin
         Result := TIcom705Radio.Create;
         Result.serialPort := serialPort;
         Result.serialBaudRate := baudRate;
         Result.serialDataBits := dataBits;
         Result.serialStopBits := stopBits;
         Result.serialParity := parity;
         Result.serialRts := rts;
         Result.serialDtr := dtr;
         logger.Info('[RadioFactory] Created Icom IC-705 instance for serial connection');
         end;

      rmIcomIC7300MK2:
         begin
         Result := TIcom7300MK2Radio.Create;
         Result.serialPort := serialPort;
         Result.serialBaudRate := baudRate;
         Result.serialDataBits := dataBits;
         Result.serialStopBits := stopBits;
         Result.serialParity := parity;
         Result.serialRts := rts;
         Result.serialDtr := dtr;
         logger.Info('[RadioFactory] Created Icom IC-7300MK2 instance for serial connection');
         end;

      rmIcomIC7600:
         begin
         Result := TIcom7600Radio.Create;
         Result.serialPort := serialPort;
         Result.serialBaudRate := baudRate;
         Result.serialDataBits := dataBits;
         Result.serialStopBits := stopBits;
         Result.serialParity := parity;
         Result.serialRts := rts;
         Result.serialDtr := dtr;
         logger.Info('[RadioFactory] Created Icom IC-7600 instance for serial connection');
         end;

      rmIcomIC7760:
         begin
         Result := TIcom7760Radio.Create;
         Result.serialPort := serialPort;
         Result.serialBaudRate := baudRate;
         Result.serialDataBits := dataBits;
         Result.serialStopBits := stopBits;
         Result.serialParity := parity;
         Result.serialRts := rts;
         Result.serialDtr := dtr;
         logger.Info('[RadioFactory] Created Icom IC-7760 instance for serial connection');
         end;

      rmIcomIC7850:
         begin
         Result := TIcom7850Radio.Create;
         Result.serialPort := serialPort;
         Result.serialBaudRate := baudRate;
         Result.serialDataBits := dataBits;
         Result.serialStopBits := stopBits;
         Result.serialParity := parity;
         Result.serialRts := rts;
         Result.serialDtr := dtr;
         logger.Info('[RadioFactory] Created Icom IC-7850 instance for serial connection');
         end;

      rmIcomIC905:
         begin
         Result := TIcom905Radio.Create;
         Result.serialPort := serialPort;
         Result.serialBaudRate := baudRate;
         Result.serialDataBits := dataBits;
         Result.serialStopBits := stopBits;
         Result.serialParity := parity;
         Result.serialRts := rts;
         Result.serialDtr := dtr;
         logger.Info('[RadioFactory] Created Icom IC-905 instance for serial connection');
         end;

      rmIcomIC7100:
         begin
         Result := TIcom7100Radio.Create;
         Result.serialPort := serialPort;
         Result.serialBaudRate := baudRate;
         Result.serialDataBits := dataBits;
         Result.serialStopBits := stopBits;
         Result.serialParity := parity;
         Result.serialRts := rts;
         Result.serialDtr := dtr;
         logger.Info('[RadioFactory] Created Icom IC-7100 instance for serial connection');
         end;

      rmFlexRadio6000:
         begin
         // FlexRadio 6000 serial is not handled by the factory — the caller's
         // legacy serial path handles it directly.  Return nil to signal this.
         logger.Warn('[RadioFactory] FlexRadio 6000 serial not handled by factory — use legacy serial path');
         Result := nil;
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
      rmIcomIC9700:     Result := 'Icom IC-9700';
      rmIcomIC705:      Result := 'Icom IC-705';
      rmIcomIC7300MK2:  Result := 'Icom IC-7300MK2';
      rmIcomIC7600:     Result := 'Icom IC-7600';
      rmIcomIC7760:     Result := 'Icom IC-7760';
      rmIcomIC7850:     Result := 'Icom IC-7850';
      rmIcomIC905:      Result := 'Icom IC-905';
      rmIcomIC7100:     Result := 'Icom IC-7100';
      rmFlexRadio6000:  Result := 'FlexRadio 6000';
      rmKenwoodTS890:   Result := 'Kenwood TS-890S';
      rmKenwoodTS990:   Result := 'Kenwood TS-990S';
      rmHamLibDirect:   Result := 'HamLib Direct (DLL)';
   else
      Result := 'Unknown';
   end;
end;

class function TRadioFactory.GetSupportedModels: string;
begin
   Result := 'Supported radio models:'#13#10 +
             '  - Elecraft K4 (implemented)'#13#10 +
             '  - Icom IC-7610 (implemented)'#13#10 +
             '  - Icom IC-7300 (implemented)'#13#10 +
             '  - Icom IC-9700 (implemented)'#13#10 +
             '  - Icom IC-705 (implemented)'#13#10 +
             '  - Icom IC-7300MK2 (implemented)'#13#10 +
             '  - Icom IC-7600 (implemented)'#13#10 +
             '  - Icom IC-7760 (implemented)'#13#10 +
             '  - Icom IC-7850 (implemented)'#13#10 +
             '  - Icom IC-905 (implemented)'#13#10 +
             '  - Kenwood TS-890S (implemented, Issue #436)'#13#10 +
             '  - Kenwood TS-990S (implemented, via TS-890 class)'#13#10 +
             '  - HamLib Direct via DLL (implemented)'#13#10 +
             '  - Elecraft K3 (planned)'#13#10 +
             '  - Yaesu FTdx101 (planned)'#13#10 +
             '  - Yaesu FT-991 (planned)'#13#10 +
             '  - FlexRadio 6000 (implemented)';
end;

class function TRadioFactory.IsModelSupported(model: TRadioModel): boolean;
begin
   Result := (model = rmElecraftK4) or
             (model = rmIcomIC7610) or
             (model = rmIcomIC7300) or
             (model = rmIcomIC9700) or
             (model = rmIcomIC705) or
             (model = rmIcomIC7300MK2) or
             (model = rmIcomIC7600) or
             (model = rmIcomIC7760) or
             (model = rmIcomIC7850) or
             (model = rmIcomIC905) or
             (model = rmIcomIC7100) or
             (model = rmFlexRadio6000) or
             (model = rmKenwoodTS890) or
             (model = rmKenwoodTS990) or
             (model = rmHamLibDirect);
end;

// Maps the legacy InterfacedRadioType (LOGRADIO RadioParametersArray order) to
// the factory's TRadioModel.  Single source of truth -- RadioObject.MapRadio
// ModelToFactory delegates here.  Radios with no factory model -> rmNone.
class function TRadioFactory.ModelForInterfacedType(rt: InterfacedRadioType): TRadioModel;
begin
   case rt of
      K4:             Result := rmElecraftK4;
      IC7610:         Result := rmIcomIC7610;
      IC7300:         Result := rmIcomIC7300;
      IC9700:         Result := rmIcomIC9700;
      IC705:          Result := rmIcomIC705;
      IC7300MK2:      Result := rmIcomIC7300MK2;
      IC7600:         Result := rmIcomIC7600;
      IC7760:         Result := rmIcomIC7760;
      IC7850, IC7851: Result := rmIcomIC7850;
      IC905:          Result := rmIcomIC905;
      IC7100:         Result := rmIcomIC7100;
      FLEX:           Result := rmFlexRadio6000;
      TS890:          Result := rmKenwoodTS890;
      TS990:          Result := rmKenwoodTS990;
   else
      Result := rmNone;
   end;
end;

// The default network port per model.  0 means "not a network radio".
class function TRadioFactory.DefaultNetworkPort(model: TRadioModel): integer;
begin
   case model of
      rmElecraftK4:     Result := 9200;
      rmFlexRadio6000:  Result := 4992;
      rmKenwoodTS890:   Result := 60000;
      rmKenwoodTS990:   Result := 50000;
      rmIcomIC7610, rmIcomIC9700, rmIcomIC705, rmIcomIC7300MK2,
      rmIcomIC7600, rmIcomIC7760, rmIcomIC7850, rmIcomIC905:
                        Result := 50001;   // Icom network models (CI-V over UDP)
   else
      Result := 0;                          // serial-only / not a network radio
   end;
end;

// A model is a network radio iff it carries a default network port.
class function TRadioFactory.IsNetworkModel(model: TRadioModel): boolean;
begin
   Result := DefaultNetworkPort(model) > 0;
end;

// Discoverable = a network radio with LAN auto-discovery.  Every network radio
// qualifies EXCEPT the Kenwoods (network, but no discovery protocol wired yet).
class function TRadioFactory.IsDiscoverable(model: TRadioModel): boolean;
begin
   Result := IsNetworkModel(model)
             and (model <> rmKenwoodTS890)
             and (model <> rmKenwoodTS990);
end;

initialization
   logger := TLogLogger.GetLogger('uRadioFactory');
   logger.Info('Radio Factory initialized');

finalization
   logger.Info('Radio Factory finalized');

end.
