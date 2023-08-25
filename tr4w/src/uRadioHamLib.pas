unit uRadioHamLib;

interface
uses uNetRadioBase, StrUtils, SysUtils, Math, Classes {for TStringList},
ShellAPI, Windows, TF;

type
  THamLib = class(TNetRadioBase)
  private
    nErrorCode: integer;
    CWBuffer: string;
    StartupInfo: TStartupInfo;
    ProcessInfo: TProcessInformation;
    //slHamLibCommand: TStringList;
    function ExecuteProcess(const FileName, Params: string; Folder: string;
      WaitUntilTerminated, WaitUntilIdle, RunMinimized: boolean;
      var ErrorCode: integer): boolean;
    function ParseIFCommand(cmd: string): boolean;
    function ModeStrToMode(sMode: string; var dataMode: TRadioMode): TRadioMode;
    function BandNumToBand(sBand: string): TRadioBand;
    //procedure ProcessMessage(sMessage: string);
    procedure Initialize;
    procedure SendToRadio(sCmd: string); overload;
    procedure SendToRadio(whichVFO: TVFO; sCmd: string; sData: string);
      overload;
    procedure SendToRadio(whichVFO: TVFO; sCmd: string); overload;
    //function ModeTypeToInteger(mode: TRadioMode; var dataModeInt: integer): integer;
    function ModeTypeToMode(mode: TRadioMode): string;
    function IsDataMode(mode: TRadioMode): boolean;

  public
    radio_BaudRate: integer;
    radio_COMPort: string;
    radio_useIPAddress: boolean;
    radio_IPAddress: string;
    radio_port: integer;
    radio_CIVAddress: string;
    radio_HamLibID: integer;

    constructor Create();
    destructor Destroy(); override;

    function Start: boolean;
    function Connect: integer; overload;
    procedure Transmit;
    procedure Receive;
    procedure BufferCW(cwChars: string);
    procedure SendCW;
    procedure StopCW;
    procedure SetFrequency(freq: longint; vfo: TVFO);
    procedure SetMode(mode: TRadioMode; vfo: TVFO);
    function ToggleMode(vfo: TVFO): TRadioMode;
    procedure SetCWSpeed(speed: integer);
    procedure RITClear(whichVFO: TVFO);
    procedure XITClear(whichVFO: TVFO);

    procedure RITBumpDown;
    procedure RITBumpUp;
    procedure RITOn(whichVFO: TVFO);
    procedure RITOff(whichVFO: TVFO);
    procedure XITOn(whichVFO: TVFO);
    procedure XITOff(whichVFO: TVFO);
    procedure Split(splitOn: boolean);
    procedure SetRITFreq(whichVFO: TVFO; hz: integer);
    procedure SetXITFreq(whichVFO: TVFO; hz: integer);
    procedure SetBand(band: TRadioBand; vfo: TVFO);
    function ToggleBand(vfo: TVFO): TRadioBand;
    procedure SetFilter(whichVFO: TVFO; filter: integer);
    function SetFilterHz(whichVFO: TVFO; hz: integer): integer;
    function MemoryKeyer(mem: integer): boolean;
    procedure SetAIMode(i: integer);
    procedure ProcessMessage(sMessage: string);
    procedure VFOBumpDown(whichVFO: TVFO);
    procedure VFOBumpUp(whichVFO: TVFO);
    procedure SendPollRequests;
    procedure CleanUp;
  end;

var
  firstProcessMessage: boolean = true;
implementation

uses MainUnit, Tree, VC;

constructor THamLib.Create();
var
  shResult: integer;
  WorkingDirP: PChar;
  CMDLine: string;
  hamLibRigParams: string;
begin
  
  //slHamLibCommand := TStringList.Create;
  inherited Create(ProcessMessage);
end;

destructor THamLib.Destroy;
begin

  inherited Destroy;

end;

function THamLib.Start: boolean;
begin
end;


function THamLib.Connect: integer;
var
  shResult: integer;
  WorkingDirP: PChar;
  CMDLine: string;
  hamLibRigParams: string;
  sHamLibPath: string;
begin
  Self.readTerminator := '';
  if TR4W_HAMLIBRUNRIGCTLD then
     begin
     ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
     StartupInfo.cb := SizeOf(StartupInfo);
     StartupInfo.dwFlags := STARTF_USESHOWWINDOW;     // These two lines to run minimized
     StartupInfo.wShowWindow := SW_SHOWMINIMIZED;     // --------------------------------

     WorkingDirP := nil;
     hamLibRigParams :=  ' --model=' + IntToStr(Self.radio_HamLibID) { + ' -vvvvv '};
     if Self.radio_useIPAddress then
        begin
        hamLibRigParams := hamLibRigParams + ' -r ' + Self.radio_IPAddress +
                                              ':' + IntToStr(Self.radio_Port) + ' ';
        end
     else
        begin
        hamLibRigParams := hamLibRigParams +
                           ' --serial-speed=' + IntToStr(Self.radio_BaudRate) +
                           ' --rig-file=' + Self.radio_COMPort;
        end;
     if length(Self.radio_CIVAddress) > 0 then
        begin
        hamLibRigParams := hamLibRigParams +
                         ' --civaddr=' + Self.radio_CIVAddress +  ' ';
        end;


     sHamLibPath := ArrayToString(TR4W_HAMLIBPATH);
     sHamLibPath := Trim(sHamLibPath);
     if length(sHamLibPath) = 0 then
        begin
        logger.warn('HAMLIBPATH does not appear to be set - will look for rigctld.exe in TARGET directory');
        sHamLibPath := 'rigctld.exe';
        end;



     CmdLine := '"' + sHamLibPath + '" ' + hamLibRigParams + ' ' +
       {  '-m 1035 -s 38400 -r COM12} ' -o -T 127.0.0.1';

     if not CreateProcess(nil, PChar(CmdLine), nil, nil, false, 0, nil,
                          WorkingDirP, StartupInfo, ProcessInfo) then
        begin
        logger.Error('Cound not run rigctld - Error = %s'[GetLastError]);
        end;
     logger.Info('[%s] rigctld started with parameters [%s]',[Self.radioModel,CmdLine]);
     sleep(2000);
     CloseHandle(ProcessInfo.hProcess); // This allows the task to continue
     end
  else
     begin
     logger.warn('For HamLib, rigctld not started due to TR4W_HAMLIBRUNRIGCTLD set to %s',[BooleanToStr(TR4W_HAMLIBRUNRIGCTLD)]);
     end;
  Result := inherited Connect;
end;

procedure THamLib.Transmit;
begin
  Self.SendToRadio(nrVFOA, 'T', '1');
end;

procedure THamLib.Receive;
begin
  Self.SendToRadio(nrVFOA, 'T', '0');
end;

procedure THamLib.BufferCW(cwChars: string);
begin
   Self.CWBuffer := Self.CWBuffer + cwChars;
end;

procedure THamLib.StopCW;
begin
   Self.SendToRadio('\stop_morse');
end;

procedure THamLib.SendCW;
var
  s: string;
begin
   if length(Self.CWBuffer) > 24 then
      begin
      logger.error('Hamlib send_morse command is limited to 24 characters - Skipping send');
      end
   else
      begin
      logger.debug('[%s HamLib SendCW] Sending buffer %s', [Self.radioModel,Self.CWBuffer]);
      Self.SendToRadio('b' + Trim(Self.CWBuffer));
      end;
  Self.CWBuffer := '';
end;

procedure THamLib.SetFrequency(freq: longint; vfo: TVFO);
var
  sCmd: string;
begin
logger.debug('[%s THamLib.SetFrequency] SetFrequency to %d',[Self.radioModel,freq]);
  Self.SendToRadio(vfo, 'F', Format('%d', [freq]));
end;

procedure THamLib.SetMode(mode: TRadioMode; vfo: TVFO);
var
  sMode: string;
  sCmd: string;
  modeInt: integer;
  dataModeInt: integer;
  isData: boolean;

begin
  sMode := Self.ModeTypeToMode(mode);
  if sMode <> '' then
  begin
    if vfo = nrVFOB then
    begin
      Self.SendToRadio(nrVFOA, 'G', 'CPY');
        // Some rigs hamlib does not directly address mode for VFOB, CPY does an A=B
    end
    else
    begin
      Self.SendToRadio(vfo, 'M', sMode + ' -1');
        // -1 is the passband command to not change the passband
    end;

    //  if dataModeInt >= 0 then
     //    begin
     //    Self.SendToRadio(vfo,'DT',IntToStr(dataModeInt));
     //    end;
  end
  else
  begin
    logger.error('[SetMode] Invalid mode passed %d', [Ord(mode)]);
    Exit;
  end;
end;

function THamLib.ToggleMode(vfo: TVFO): TRadioMode;
begin
end;

procedure THamLib.SetCWSpeed(speed: integer);
begin
  if IntegerBetween(speed, 8, 60) then
  begin
    Self.localCWSpeed := speed;
    Self.SendToRadio(nrVFOA, 'L', Format('KEYSPD %3d', [speed]));
  end
  else
  begin
    logger.Error('Hamlib supports a CW speed of 8 wpm to 60 wpm');
  end;
end;

procedure THamLib.RITClear(whichVFO: TVFO);
begin
  Self.SendToRadio(whichVFO, 'J', '0');
end;

procedure THamLib.XITClear(whichVFO: TVFO);
begin
  Self.SendToRadio(whichVFO, 'Z', '0');
end;

procedure THamLib.RITBumpDown;
begin
  //Self.SendToRadio('RD;');
  logger.Error('Hamlib RITBump not yet implemented');
end;

procedure THamLib.RITBumpUp;
begin
  //Self.SendToRadio('RU;');
  logger.Error('Hamlib RITBump not yet implemented');
end;

procedure THamLib.RITOn(whichVFO: TVFO);
begin
  Self.SendToRadio(whichVFO, 'U', 'RIT 1');
end;

procedure THamLib.RITOff(whichVFO: TVFO);
begin
  Self.SendToRadio(whichVFO, 'U', 'RIT 0');
end;

procedure THamLib.XITOn(whichVFO: TVFO);
begin
  Self.SendToRadio(whichVFO, 'U', 'XIT 1');
end;

procedure THamLib.XITOff(whichVFO: TVFO);
begin
  Self.SendToRadio(whichVFO, 'U', 'XIT 0');
end;

procedure THamLib.Split(splitOn: boolean);
begin
  if splitOn then
  begin
    logger.debug('Turning on SPLIT');
    Self.SendToRadio(nrVFOA, 'S', '1 VFOB');
  end
  else
  begin
    Self.SendToRadio(nrVFOA, 'S', '0 VFOB');
  end;
end;

procedure THamLib.SetRITFreq(whichVFO: TVFO; hz: integer);
var
  s: string;
begin
  if (hz > -10000) and (hz < 10000) then
  begin
    if hz >= 0 then
    begin
      s := '+';
    end
    else
    begin
      s := '-';
    end;
    s := s + Format('%4d', [Abs(hz)]);
    Self.SendToRadio(whichVFO, 'J' + s);
  end
  else
  begin
    logger.Error('[%s SetRITFreq] RIT frequency must be between -9999 and 9999 (%d)', [Self.radioModel, hz]);
  end;
end;

procedure THamLib.SetXITFreq(whichVFO: TVFO; hz: integer);
begin
  Self.SetRITFreq(whichVFO, hz); // Same on K4
end;

procedure THamLib.SetBand(band: TRadioBand; vfo: TVFO);
var
  s: string;
begin

  case band of
    rb160m: s := 'BAND160M';
    rb80m: s := 'BAND80M';
    rb60m: s := 'BAND60M';
    rb40m: s := 'BAND40M';
    rb30m: s := 'BAND30M';
    rb20m: s := 'BAND20M';
    rb17m: s := 'BAND17M';
    rb15m: s := 'BAND15M';
    rb12m: s := 'BAND12M';
    rb10m: s := 'BAND10M';
    rb6m: s := 'BAND6M';
    rb4m: s := 'BAND4M';
    rb2m: s := 'BAND2M';
    rb70cm: s := 'BAND70CM';
  else
    begin
      logger.Error('Invalid band requested %d', [Ord(band)]);
      Exit;
    end;
  end;
  Self.SendToRadio('P BANDSELECT ' + s);
end;

procedure THamLib.VFOBumpDown(whichVFO: TVFO);
begin
  if whichVFO = nrVFOA then
  begin
    Self.SendToRadio('G DOWN');
  end
    {else if whichVFO = nrVFOB then
       begin
       Self.SendToRadio('DNB;');
       end
    else
       begin
       logger.Warn('[THamLib.VFOBumpDown] Invalid vfo passed in whichVFO');
       end};
end;

procedure THamLib.VFOBumpUp(whichVFO: TVFO);
begin
  if whichVFO = nrVFOA then
  begin
    Self.SendToRadio('G UP');
  end
    {else if whichVFO = nrVFOB then
       begin
       Self.SendToRadio('UPB;');
       end
    else
       begin
       logger.Warn('[THamLib.VFOBumpUp] Invalid vfo passed in whichVFO');
       end};
end;

function THamLib.ToggleBand(vfo: TVFO): TRadioBand;
var
  newBand: TRadioBand;
begin
  //newBand := Self.priorBand;
  //Self.priorBand := Self.band;
  //Self.SetBand(newBand);
  //Result := newBand;
  logger.Warn('ToggleBand not yet implemented');
end;

procedure THamLib.SetFilter(whichVFO: TVFO; filter: integer);
begin
  if IntegerBetween(filter, 1, 5) then
  begin
    logger.Info('[SetFilter] Setting filter on VFO %s to %d',
      [VFOToString(whichVFO), filter]);
    if whichVFO = nrVFOA then
    begin
      Self.SendToRadio(Format('FP%d;', [filter]));
    end
    else if whichVFO = nrVFOB then
    begin
      Self.SendToRadio(Format('FP$%d;', [filter]));
    end;

  end
  else
  begin
    logger.error('[SetFilter] filter out of range 1..5 - %d', [filter]);
  end;

end;

function THamLib.SetFilterHz(whichVFO: TVFO; hz: integer): integer;
begin
 { TODO HAMLIB Implement the setfilter with the mode command where we pass the
    current mode but the passband in hz requested
 
 M, set_mode 'Mode' 'Passband'
Set 'Mode' and 'Passband'.

Mode is a token: ‘USB’, ‘LSB’, ‘CW’, ‘CWR’, ‘RTTY’, ‘RTTYR’, ‘AM’, ‘FM’, ‘WFM’, ‘AMS’, ‘PKTLSB’, ‘PKTUSB’, ‘PKTFM’, ‘ECSSUSB’, ‘ECSSLSB’, ‘FA’, ‘SAM’, ‘SAL’, ‘SAH’, ‘DSB’.

Passband is in Hz as an integer, -1 for no change, or ‘0’ for the radio backend default.
}
  logger.Warn('SetFilterHz is not yet implemented in TR4W HamLib code');
end;

function THamLib.MemoryKeyer(mem: integer): boolean;
begin
  Result := true; // True is an error...default to that value to fail closed        // 0x94 hex (148 decimal) is used as command
  if mem = 0 then
  begin
    logger.debug('[%s HamLib-MemoryKeyer] Stopping DVK', [Self.radioModel]);
    Self.SendToRadio('\stop_voice_mem');
    Result := false;
  end
  else if IntegerBetween(mem, 1, 8) then       // Use hex 94 => Chr(148)
  begin
    logger.debug('[%s HamLib-MemoryKeyer] Playing memory %d', [Self.radioModel, mem]);
    Self.SendToRadio(Format('\send_voice_mem %d',[mem]));
    Result := false;
  end
  else
  begin
    logger.error('[%s] Memory value (%d) out of range for a HamLib in MemoryKeyer',[Self.radioModel, mem]);
    Result := true;
  end;
end;

function THamLib.ParseIFCommand(cmd: string): boolean;
var
  s: string;
  hz: integer;
  ritMultiplier: integer;
  xitMultiplier: integer;
  ritOffset: integer;
  xitOffset: integer;
  sVFO: string;
  sMode: string;
  sDataMode: string;
  vfo: TRadioVFO;
begin
  {
  IF (Transceiver Information; GET only)
  RSP format: IF[f]*****+yyyyrx*00tmvspbd1*; where the fields are defined as follows:
  [f] Operating frequency, excluding any RIT/XIT offset (11 digits; see FA command format)
  * represents a space (BLANK, or ASCII 0x20)
  + either "+" or "-" (sign of RIT/XIT offset)
  yyyy RIT/XIT offset in Hz (range is -9999 to +9999 Hz when computer-controlled)
  r 1 if RIT is on, 0 if off
  x 1 if XIT is on, 0 if off
  t 1 if the K3 is in transmit mode, 0 if receive
  m operating mode (see MD command)
  v receive-mode VFO selection, 0 for VFO A, 1 for VFO B
  s 1 if scan is in progress, 0 otherwise
  p 1 if the transceiver is in split mode, 0 otherwise
  b Basic RSP format: always 0; K2 Extended RSP format (K22): 1 if present IF response
  is due to a band change; 0 otherwise
  d Basic RSP format: always 0; K3 Extended RSP format (K31): DATA sub-mode,
  if applicable (0=DATA A, 1=AFSK A, 2= FSK D, 3=PSK D)
  }
  Result := false;
  {
     if not length(cmd) in [36,38] then
        begin
        logger.Error('[ParseIFCommand] length of IF command not 36 or 38 bytes - %s',[cmd]);
        Exit;
        end;

     s := cmd;
     if AnsiLeftStr(s,2) = 'IF' then
        begin
        Delete(s,1,2);
        end;
     hz := StrToIntDef(AnsiLeftStr(s,11),-999);   //[f]*****+yyyyrx*00tmvspbd1*;
     if hz = -999 then
        begin
        logger.Error('[ParseIFCommand] frequency returned in IF command was not a number %s',[AnsiLeftStr(s,11)]);
        Exit;
        end;


     Delete(s,1,11); // Remove frequency
     Delete(s,1,5); // Remove 5 blanks          // *****+yyyyrx*00tmvspbd1*;
     if AnsiLeftStr(s,1) = '-' then
        begin
        ritMultiplier := -1;
        xitMultiplier := -1;
        end
     else if AnsiLeftStr(s,1) = '+' then
        begin
        ritMultiplier := 1;
        xitMultiplier := 1;
        end;
     Delete(s,1,1);                      // yyyyrx*00tmvspbd1*;
     ritOffset := StrToIntDef(AnsiLeftStr(s,4),-999);
     if ritOffset = -999 then
        begin
        logger.Error('[ParseIFCommand] RIT offset returned in IF command was not a number %s',[AnsiLeftStr(s,4)]);
        Exit;
        end;

     Self.localRITOffset := (ritOffset * ritMultiplier);
     Self.localXITOffset := (Self.localRITOffset); // Because on K4, these are the same
     logger.debug('[ParseIFCommand] RITOffset = %d',[Self.localRITOffset]);

     Delete(s,1,4);                      // rx*00tmvspbd1*;
     Self.RITState := AnsiLeftStr(s,1) = '1';
     logger.Debug('In IF processor, RIT is %s',[AnsiLeftStr(s,1)]);

     Delete(s,1,1);                      // x*00tmvspbd1*;
     Self.XITState := AnsiLeftStr(s,1) = '1';
     logger.Debug('In IF processor, XIT is %s',[AnsiLeftStr(s,1)]);

     Delete(s,1,1);
     Delete(s,1,1); // Skip space       // *00tmvspbd1*;
     Delete(s,1,2); // Skip 00          // 00tmvspbd1*;

     if AnsiLeftStr(s,1) = '1' then     // tmvspbd1*;
        begin
        Self.RadioState := rsTransmit;
        end
     else
        begin
        Self.RadioState := rsReceive;
        end;
     Delete(s,1,1);
     logger.debug('[ParseIFCommand] string at mode = %s',[s]);
     sMode := AnsiLeftStr(s,1);          // mvspbd1*;

     Delete(s,1,1);
     logger.debug('[ParseIFCommand] string at vfo = %s',[s]);
     sVFO := AnsiLeftStr(s,1);           // vspbd1*;

     Delete(s,1,2); // Skip s as we do not care if scanning  // spbd1*;
     logger.debug('[ParseIFComand] Checking split command in %s',[s]);
     Self.localSplitEnabled := AnsiLeftStr(s,1) = '1';           // pbd1*;

     Delete(s,1,1);

     Delete(s,1,1); // Skip the b // bd1*;

     // (0=DATA A, 1=AFSK A, 2= FSK D, 3=PSK D)

     sDataMode := AnsiLeftStr(s,1);

     // Post processing from gathered variables to the right VFO
     if sVFO = '0' then // VFO A
        begin
        vfo := Self.vfo[nrVFOA];
        end
     else
        begin
        vfo := Self.vfo[nrVFOB];
        end;

     vfo.frequency := hz;
     vfo.mode := ModeStrToMode(sMode,sDataMode);

  }
end;

{
Type TRadioMode = (rmNone,rmCW, rmCWRev, rmLSB, rmUSB, rmFM, rmAM,
                   rmData, rmDataRev, rmFSK, rmFSKRev, rmPSK, rmPSKRev,
                   rmAFSK, rmAFSKRev);
                   }

// Helper functions
function THamLib.ModeStrToMode(sMode: string; var dataMode: TRadioMode):
  TRadioMode;
var
  iMode: integer;
begin
  if sMode = 'AM' then
  begin
    Result := rmAM;
  end
  else if sMode = 'FM' then
  begin
    Result := rmFM;
  end
  else if sMode = 'USB' then
  begin
    Result := rmUSB;
  end
  else if sMode = 'LSB' then
  begin
    Result := rmLSB;
  end
  else if sMode = 'CW' then
  begin
    Result := rmCW;
  end
  else if sMode = 'CWR' then
  begin
    Result := rmCWRev;
  end
  else if sMode = 'RTTY' then
  begin
    Result := rmData;
    dataMode := rmFSK;
  end
  else if sMode = 'RTTYR' then
  begin
    Result := rmData;
    dataMode := rmFSKRev;
  end
  else if sMode = 'PKTUSB' then
  begin
    Result := rmData;
    dataMode := rmAFSK;
  end
  else if sMode = 'PKTLSB' then
  begin
    Result := rmData;
    dataMode := rmAFSKRev;
  end
  else
  begin
    Result := rmNone;
  end;
end;


{ RPRT return codes


enum rig_errcode_e {
>      RIG_OK = 0,     /*!< 0 No error, operation completed successfully */
>      RIG_EINVAL,     /*!< 1 invalid parameter */
>      RIG_ECONF,      /*!< 2 invalid configuration (serial,..) */
>      RIG_ENOMEM,     /*!< 3 memory shortage */
>      RIG_ENIMPL,     /*!< 4 function not implemented, but will be */
>      RIG_ETIMEOUT,   /*!< 5 communication timed out */
>      RIG_EIO,        /*!< 6 IO error, including open failed */
>      RIG_EINTERNAL,  /*!< 7 Internal Hamlib error, huh! */
>      RIG_EPROTO,     /*!< 8 Protocol error */
>      RIG_ERJCTED,    /*!< 9 Command rejected by the rig */
>      RIG_ETRUNC,     /*!< 10 Command performed, but arg truncated */
>      RIG_ENAVAIL,    /*!< 11 Function not available */
>      RIG_ENTARGET,   /*!< 12 VFO not targetable */
>      RIG_BUSERROR,   /*!< 13 Error talking on the bus */
>      RIG_BUSBUSY,    /*!< 14 Collision on the bus */
>      RIG_EARG,       /*!< 15 NULL RIG handle or any invalid pointer parameter in get arg */
>      RIG_EVFO,       /*!< 16 Invalid VFO */
>      RIG_EDOM,       /*!< 17 Argument out of domain of func */
>      RIG_EDEPRECATED,/*!< 18 Function deprecated */
>      RIG_ESECURITY,  /*!< 19 Security error */
>      RIG_EPOWER      /*!< 20 Rig not powered on */
> }

procedure THamLib.ProcessMessage(sMessage: string);
var
  sCommand: string;
  sData: string;
  sMode: string;
  hz: integer;
  nPos: integer;
  i: integer;
  RITSign: integer;
  XITSign: integer;
  ritHz: integer;
  xitHz: integer;
  sDataMode: string;
  vfo: TRadioVFO;
  vfoBCommand: boolean;
  sResult: string;
  sResultCode: string;
  slHamLibCommand: TStringList;
  tempBand: BandType;
  tempMode: ModeType;
  vfoIndex: integer;
begin
  // This is called by the process that receives data on the socket - Event
  // K4 messages are seperated by semi-colons (;) but each message should not have the ; as that is the ReadLn delimiter.
  // This is a command that has been parsed into its parts. For example, if the radio
  // sends RX;DT5;, this procedure is called once with RX; and once with DT5;
  try
    slHamLibCommand := TStringList.Create;
    logger.Trace('[%s ProcessMessage] Received from radio: (%s)', [Self.radioModel,sMessage]);
    // Exit;
     //slHamLibCommand.Delimiter := ',';
     //slHamLibCommand.QuoteChar := #0;
    slHamLibCommand.DelimitedText := sMessage;
    logger.trace('slHamLibCommand.Count = %d', [slHamLibCommand.Count]);
    for i := 0 to slHamLibCommand.Count - 1 do
    begin
      logger.Trace('[%s] slHamLibCommand[%d] = %s', [Self.radioModel, i, slHamLibCommand[i]]);
    end;
    if slHamLibCommand.Count < 3 then
    begin
      logger.error('[%s] slHamLibCount too small (%d) - sMessage = %s',
        [Self.radioModel, slHamLibCommand.Count, sMessage]);
      Exit;
    end;
    if Trim(slHamLibCommand[slHamLibCommand.Count - 2]) <> 'RPRT' then
    begin
      logger.Debug('%s hamLib message missing RPRT code - %s', [Self.radioModel,sMessage]);
      // If this is a get_func/get_level message, process it. There is a Hamlib bug where the RPRT is on the next line
      if (AnsiLeftStr(sMessage, 13) = 'get_func: VFO') or
        (AnsiLeftStr(sMessage, 14) = 'get_level: VFO') then
      begin
      end
      else
      begin
        Exit;
      end;
    end;
    sResultCode := Trim(slHamLibCommand[slHamLibCommand.Count - 1]);
    if (AnsiLeftStr(sMessage, 4) = 'test') then
    begin
    end
    else if sResultCode <> '0' then
    begin
      logger.error('[%s] Error response received from hamlib %s - Whole message = %s',
        [Self.radioModel,sResultCode, sMessage]);
      Exit;
    end
    else
    begin
      logger.trace('[%s] Good response from hamlib (%s)', [Self.radioModel,sMessage]);
    end;
    
    vfoIndex := 1;
    if slHamLibCommand[vfoIndex] = 'VFOB' then
    begin
      vfoBCommand := true;
      vfo := Self.vfo[nrVFOB];
    end
    else
    begin
      vfoBCommand := false;
      vfo := Self.vfo[nrVFOA];
    end;

    // Find first : in sMessage
    sCommand := AnsiLeftStr(slHamLibCommand[0], length(slHamLibCommand[0]) - 1);

    logger.Debug('sCommand = %s', [sCommand]);

    //sData := AnsiRightStr(sData,length(sData) - length(sCommand));
    case AnsiIndexText(AnsiUppercase(sCommand), ['set_freq', 'get_freq',
      'get_band', 'get_level', 'get_mode', 'get_func', 'get_ptt', 'get_xit',
      'get_rit', 'get_split_vfo', 'get_vfo_info']) of
      0:
        begin // set_freq
          logger.trace('[ProcessMessage] set_freq command set to %s',
            [sResult]);
        end;
      1:
        begin // get_freq
          {vfo.frequency := StrToIntDef(slHamLibCommand[3], 0);
          CalculateBandMode(vfo.frequency, TempBand, TempMode);
          vfo.band := GetRadioBandFromBandType(TempBand);}
        end;
      2:
        begin // get_band
          vfo.band := Self.BandNumToBand(sData);
          logger.debug('[ProcessMessage] Received band number of %s', [sData]);
        end;
      3:
        begin // get_level
          if slHamLibCommand[2] = 'KEYSPD' then
          begin
            i := StrToIntDef(slHamLibCommand[3], -1);
            if i > -1 then
            begin
              Self.localCWSpeed := i;
            end;
          end;
        end;
      4:
        begin // get_mode
          {vfo.mode := Self.ModeStrToMode(slHamLibCommand[3], vfo.datamode);
          logger.trace('[HamLib ProcessMessage] Mode data = %s',
            [slHamLibCommand[3]]); }
        end;
      5:
        begin // get_func
          if slHamLibCommand[2] = 'RIT' then
          begin
            vfo.RITState := slHamLibCommand[3] = '1';
            logger.debug('[ProcessMsg] RIT Enabled');
          end
          else if slHamLIbCommand[2] = 'XIT' then
          begin
            vfo.XITState := slHamLibCommand[3] = '1';
            logger.debug('[ProcessMsg] RIT Enabled');
          end;
        end;
      6:
        begin // get_ptt
          if Trim(slHamLibCommand[3]) = '1' then
          begin
            Self.radioState := rsTransmit;
          end
          else
          begin
            Self.radioState := rsReceive;
          end;
        end;
      7:
        begin // get_xit Note this is the offset not the state
          sData := Trim(slHamLibCommand[3]);
          XITSign := IfThen(AnsiLeftStr(sData, 1) = '-', -1, 1);
          xitHz := StrToIntDef(sData, 99999);
          if xitHz = 99999 then
          begin
            xitHz := 0;
            logger.error('[ProcessMessage] Invalid value passed in get_xit command: %s', [sMessage]);
          end
          else
          begin
            xitHz := xitHz * xitSign;
            vfo.XITOffset := xitHz;
          end;
        end;
      8:
        begin // get_rit
          sData := Trim(slHamLibCommand[3]);
          RITSign := IfThen(AnsiLeftStr(sData, 1) = '-', -1, 1);
          {if AnsiLeftStr(sData,1) = '-' then
             begin
             RITSign := -1;
             end
          else
             begin
             RITSign := 1;
             end;}
          ritHz := StrToIntDef(sData, 99999);
          if ritHz = 99999 then
          begin
            ritHz := 0;
            logger.error('[ProcessMessage] Invalid value passed in get_rit command: %s', [sMessage]);
          end
          else
          begin
            ritHz := ritHz * ritSign;
            vfo.RITOffset := ritHz;
            //vfo.XITOffset := ritHz;
            //Self.localRITOffset := ritHz;
            //Self.localXITOffset := ritHz; // Because on K4, this is the same value
          end;

        end;
      9:
        begin // get_split_vfo
          Self.localSplitEnabled := slHamLibCommand[3] = '1';
        end;
      10: begin     // get_vfo_info
          if slHamLibCommand[2] = 'VFOB' then
             begin
             vfo := Self.vfo[nrVFOB];
             end
          else
             begin
             vfo := Self.vfo[nrVFOA];
             end;
          vfo.frequency := StrToIntDef(slHamLibCommand[4], 0);
          CalculateBandMode(vfo.frequency, TempBand, TempMode);
          vfo.band := GetRadioBandFromBandType(TempBand);
          vfo.mode := Self.ModeStrToMode(slHamLibCommand[6], vfo.datamode);
          logger.trace('[HamLib ProcessMessage] Mode data = %s',[slHamLibCommand[6]]);
          end;
    end; // of case
    if firstProcessMessage then
    begin
      firstProcessMessage := false;
      Initialize;
    end;
  except
    on E: Exception do
    begin
      logger.error(E.ClassName + ' error raised, with message : ' + E.Message);
      FreeAndNil(slHamLibCommand);
    end;
  end;
  if Assigned(slHamLibCommand) then
  begin
    FreeAndNil(slHamLibCommand);
  end;
end;

function THamLib.BandNumToBand(sBand: string): TRadioBand;
var
  iBand: integer;
begin
  iBand := StrToIntDef(sBand, -9);
  case iBand of
    0: Result := rb160m;
    1: Result := rb80m;
    2: Result := rb60m;
    3: Result := rb40m;
    4: Result := rb30m;
    5: Result := rb20m;
    6: Result := rb17m;
    7: Result := rb15m;
    8: Result := rb12m;
    9: Result := rb10m;
    10: Result := rb6m;
    -9:
      begin
        logger.Error('[BandNumToBand] Invalid band requested %s', [sBand]);
        Result := rbNone;
      end;
  end;
end;

procedure THamLib.SetAIMode(i: integer);
begin
  Self.SendToRadio(Format('AI%d;', [i]));

end;

procedure THamLib.Initialize;
begin
end;

procedure THamLib.SendToRadio(sCmd: string);
begin
  inherited SendToRadio(',' + sCMD + #10);
end;

procedure THamLib.SendToRadio(whichVFO: TVFO; sCmd: string; sData: string);
begin
  if whichVFO = nrVFOB then
  begin
    Self.SendToRadio(Format('%s VFOB %s', [sCmd, sData]));
  end
  else if whichVFO = nrVFOA then
  begin
    Self.SendToRadio(Format('%s VFOA %s', [sCmd, sData]));
  end
  else
  begin
    logger.error('[SendToRadio] Invalid VFO passed for command %s - data = %s',
      [sCmd, sData]);
  end;

end;

procedure THamLib.SendToRadio(whichVFO: TVFO; sCmd: string);
begin
  Self.SendToRadio(whichVFO, sCmd, '');
end;

function THamLib.ModeTypeToMode(mode: TRadioMode): string;
  // This converts the class mode to the hamlib mode string
begin
  case mode of
    rmNone: Result := '';
    rmCW: Result := 'CW';
    rmCWRev: Result := 'CWR';
    rmLSB: Result := 'LSB';
    rmUSB: Result := 'USB';
    rmFM: Result := 'FM';
    rmAM: Result := 'AM';
    rmData:
      begin
        Result := 'PKTUSB';
      end;
    rmDataRev:
      begin
        Result := 'PKTLSB';
      end;
    rmFSK:
      begin
        Result := 'RTTY';
      end;
    rmFSKRev:
      begin
        Result := 'RTTYR';
      end;
    rmPSK:
      begin
        Result := 'PKTUSB';
      end;
    rmPSKRev:
      begin
        Result := 'PKTLSB';
      end;
    rmAFSK:
      begin
        Result := 'PKTUSB';
      end;
    rmAFSKRev:
      begin
        Result := 'PKTLSB';
      end;
  end;

end;

function THamLib.IsDataMode(mode: TRadioMode): boolean;
begin
  Result := mode in [rmData, rmDataRev, rmFSK, rmFSKRev, rmPSK, rmPSKRev,
    rmAFSK, rmAFSKRev];
end;

procedure THamLib.SendPollRequests;
var
  cmd: string;
begin

  { To do a full poll, we need to request the following:

     Active VFO
     Frequency
     Mode
     RIT Offset
     XIT Offset
     Split status
     RIT On/Off status
     XIT On/Off status
     Transmit status
     Keyer speed

     Since these are calls to hamlib, we just send the requests here.
     The TCP socket receive event will process the result when it comes back

     }
  if not Self.IsConnected then
     begin
	 logger.debug('Skipping poll commands send as not connected');
	 Exit;
	 end;
  logger.debug('[%s] Sending polling request to HamLib',[Self.RadioModel]);

  //Self.SendToRadio('v'); // Get current VFO
  //  cmd := socket.IOHandler.ReadLn('\n');
  Self.SendToRadio(nrVFOA, '\get_vfo_info');
  sleep(50);
  Self.SendToRadio(nrVFOB, '\get_vfo_info');
  sleep(50);
  //Self.SendToRadio(nrVFOA, 'f'); // Get frequency
  //sleep(100);
  //Self.SendToRadio(nrVFOB, 'f'); // Get frequency
  //sleep(100);
  //Self.SendToRadio(nrVFOA, 'm'); // Get mode
  //sleep(100);
  //Self.SendToRadio(nrVFOB,'m'); // Get mode
  //sleep(100);
  Self.SendToRadio(nrVFOA, 'j'); // Get RIT offset
  Self.SendToRadio(nrVFOB, 'j'); // Get RIT offset
  Self.SendToRadio(nrVFOA, 'z'); // Get XIT offset
  Self.SendToRadio(nrVFOB, 'z'); // Get XIT offset
  sleep(50);
  Self.SendToRadio(nrVFOA, 's'); // Get split status
  Self.SendToRadio(nrVFOB, 's'); // Get split status

  Self.SendToRadio(nrVFOA, 'u', 'RIT'); // Get RIT status
  Self.SendToRadio(nrVFOB, 'u', 'RIT'); // Get RIT status
  Self.SendToRadio(nrVFOA, 'u', 'XIT'); // Get XIT status
  Self.SendToRadio(nrVFOB, 'u', 'XIT'); // Get XIT status
  Self.SendToRadio(nrVFOA, 't'); // Get PTT (transmit) status
  Self.SendToRadio(nrVFOA, 'l', 'KEYSPD'); // Get PTT (transmit) status
  sleep(50);
end;

function THamLib.ExecuteProcess(const FileName, Params: string; Folder: string;
  WaitUntilTerminated, WaitUntilIdle, RunMinimized: boolean;
  var ErrorCode: integer): boolean;
begin
  {
    Result := true;
    CmdLine := '"' + FileName + '" ' + Params;
    if Folder = '' then Folder := ExcludeTrailingPathDelimiter(ExtractFilePath(FileName));
    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
    if RunMinimized then
      begin
        StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
        StartupInfo.wShowWindow := SW_SHOWMINIMIZED;
      end;
    if Folder <> '' then WorkingDirP := PChar(Folder)
    else WorkingDirP := nil;
    if not CreateProcess(nil, PChar(CmdLine), nil, nil, false, 0, nil, WorkingDirP, StartupInfo, ProcessInfo) then
      begin
        Result := false;
        ErrorCode := GetLastError;
        exit;
      end;
    with ProcessInfo do
      begin
        CloseHandle(hThread);
        if WaitUntilIdle then WaitForInputIdle(hProcess, INFINITE);
        if WaitUntilTerminated then
          repeat
            Application.ProcessMessages;
          until MsgWaitForMultipleObjects(1, hProcess, false, INFINITE, QS_ALLINPUT) <> WAIT_OBJECT_0 + 1;
        CloseHandle(hProcess);
      end;
      }
end;

procedure THamLib.Cleanup;
var bRslt: longBool;
   nError: integer;
begin
   if Self.IsConnected then
      begin
      Self.socket.Disconnect;
      end;
   if TR4W_HAMLIBRUNRIGCTLD then
      begin
      logger.Info('*********************************************');
      logger.info('Terminating rigctld process - processId = %d',[ProcessInfo.dwProcessId]);
      if not TerminateProcess(ProcessInfo.hProcess, nErrorCode) then
         begin
         nError := GetLastError;
         
         if tr4w_osverinfo.dwMajorVersion >= 10 then
            begin
			logger.warn('Error terminating rigctld %d - Using taskkill via ShellExecute', [nError]);
            nError := ShellExecute(0, 'open', PChar('taskkill'), PChar('/PID ' + IntToStr(ProcessInfo.dwProcessId)), nil, // taskkill is on Win10 and 11
                                                      SW_HIDE);
            end
         else
            begin
			logger.warn('Error terminating rigctld %d - Using PowerShell Stop-Process on Windows %d via ShellExecute', [nError, tr4w_osverinfo.dwMajorVersion]);
            nError := ShellExecute(0, 'open', PChar('Powershell.exe'), PChar('-Command "& {Stop-Process -ID ' + IntToStr(ProcessInfo.dwProcessId) + ' -Force"}'), nil, // taskkill is on Win10 and 11
                                                      SW_HIDE);
            end;
         end;
      logger.Info('********************************************');
      end;
end;

end.
