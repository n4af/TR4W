unit uRadioInterfaces;

interface

uses
  uNetRadioBase;  // For TVFO, TRadioMode, TRadioBand, TRadioFilter types

type
  // Core interface - all radios must support basic operations
  IRadioBasic = interface
    ['{D1A1B2C3-4D5E-6F78-9ABC-DEF012345678}']
    function IsConnected: boolean;
    procedure Transmit;
    procedure Receive;
    procedure ProcessMsg(msg: string);
  end;

  // Radios that support frequency control with VFO
  IRadioFrequency = interface
    ['{E2B2C3D4-5E6F-7890-ABCD-EF0123456789}']
    procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
    function GetFrequency(vfo: TVFO): longint;
  end;

  // Radios that support mode control
  IRadioMode = interface
    ['{F3C3D4E5-6F78-90AB-CDEF-012345678901}']
    procedure SetMode(mode: TRadioMode; vfo: TVFO);
    function GetMode(vfo: TVFO): TRadioMode;
    function ToggleMode(vfo: TVFO): TRadioMode;
  end;

  // Radios with dual VFO capability
  IRadioDualVFO = interface
    ['{04D4E5F6-7890-ABCD-EF01-23456789012A}']
    procedure VFOBumpDown(whichVFO: TVFO);
    procedure VFOBumpUp(whichVFO: TVFO);
  end;

  // Radios with RIT (Receiver Incremental Tuning) support
  IRadioRIT = interface
    ['{15E5F607-890A-BCDE-F012-3456789012AB}']
    procedure RITOn(vfo: TVFO);
    procedure RITOff(vfo: TVFO);
    procedure RITClear(vfo: TVFO);
    procedure RITBumpDown;
    procedure RITBumpUp;
    procedure SetRITFreq(vfo: TVFO; hz: integer);
  end;

  // Radios with XIT (Transmitter Incremental Tuning) support
  IRadioXIT = interface
    ['{26F60718-90AB-CDEF-0123-456789012ABC}']
    procedure XITOn(vfo: TVFO);
    procedure XITOff(vfo: TVFO);
    procedure XITClear(vfo: TVFO);
    procedure SetXITFreq(vfo: TVFO; hz: integer);
  end;

  // Radios with split operation support
  IRadioSplit = interface
    ['{37071829-0ABC-DEF0-1234-56789012ABCD}']
    procedure Split(splitOn: boolean);
  end;

  // Radios with CW keyer capability
  IRadioCW = interface
    ['{4818293A-BCDE-F012-3456-789012ABCDEF}']
    procedure BufferCW(msg: string);
    procedure SendCW;
    procedure StopCW;
    procedure SetCWSpeed(speed: integer);
  end;

  // Radios with voice keyer/DVK capability
  IRadioVoiceKeyer = interface
    ['{5929304B-CDEF-0123-4567-89012ABCDEF0}']
    function MemoryKeyer(mem: integer): boolean;
  end;

  // Radios with filter control
  IRadioFilter = interface
    ['{6A30415C-DEF0-1234-5678-9012ABCDEF01}']
    procedure SetFilter(filter: TRadioFilter; vfo: TVFO);
    function SetFilterHz(hz: integer; vfo: TVFO): integer;
  end;

  // Radios with band control
  IRadioBand = interface
    ['{7B41526D-EF01-2345-6789-012ABCDEF012}']
    procedure SetBand(band: TRadioBand; vfo: TVFO);
    function GetBand(vfo: TVFO): TRadioBand;
    function ToggleBand(vfo: TVFO): TRadioBand;
  end;

  // Radios that support sending commands directly
  IRadioCommand = interface
    ['{8C52637E-F012-3456-789A-BCDEF0123456}']
    procedure SendToRadio(whichVFO: TVFO; sCmd: string; sData: string);
  end;

implementation

end.
