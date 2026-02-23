unit uHamLibDirect;

{
  HamLib Direct DLL Bindings for Delphi 7

  Translated from HamLib 4.7.0 C headers and VB6 bindings

  Purpose: Direct DLL interface to libhamlib-4.dll, eliminating the need
           for rigctld TCP/IP daemon.

  Usage Example:
    var
      myRig: PRIG;
      freq: freq_t;
      mode: rmode_t;
      width: pbwidth_t;
      err: Integer;
    begin
      // Initialize
      rig_set_debug(RIG_DEBUG_TRACE);
      myRig := rig_init(RIG_MODEL_K4);  // Elecraft K4

      // Configure serial port
      rig_set_conf(myRig, TOK_PATHNAME, 'COM3');
      rig_set_conf(myRig, TOK_SERIAL_SPEED, '38400');

      // Open connection
      err := rig_open(myRig);
      if err = RIG_OK then
      begin
        // Get frequency
        err := rig_get_freq(myRig, RIG_VFO_A, freq);
        if err = RIG_OK then
          ShowMessage(Format('VFO A: %.0f Hz', [freq]));

        // Set mode
        err := rig_set_mode(myRig, RIG_VFO_A, RIG_MODE_USB, RIG_PASSBAND_NORMAL);

        // Cleanup
        rig_close(myRig);
      end;
      rig_cleanup(myRig);
    end;

  File References:
    C:\projects\hamlib\include\hamlib\rig.h
    C:\projects\Hamlib-4.6.5\Hamlib-4.6.5\bindings\hamlibvb.bas.in
}

interface

uses
  Windows, SysUtils;

const
  HAMLIB_DLL = 'libhamlib-4.dll';

{-----------------------------------------------------------------------------
  Type Definitions
-----------------------------------------------------------------------------}

type
  // Opaque handle to a RIG structure
  PRIG = Pointer;

  // Frequency type in Hz (can hold SHF frequencies)
  freq_t = Double;

  // Short frequency type for offsets, shifts (31-bit signed)
  shortfreq_t = Integer;

  // VFO identifier
  vfo_t = Cardinal;

  // Radio mode (64-bit bitmask)
  rmode_t = Int64;

  // Passband width
  pbwidth_t = Integer;

  // PTT status
  ptt_t = Integer;

  // DCD status
  dcd_t = Integer;

  // Configuration token
  hamlib_token_t = Integer;

{-----------------------------------------------------------------------------
  Error Codes

  Functions return RIG_OK (0) on success, or negative error code on failure
-----------------------------------------------------------------------------}

const
  RIG_OK          = 0;   // No error, operation completed successfully
  RIG_EINVAL      = -1;  // Invalid parameter
  RIG_ECONF       = -2;  // Invalid configuration (serial, etc.)
  RIG_ENOMEM      = -3;  // Memory shortage
  RIG_ENIMPL      = -4;  // Function not implemented
  RIG_ETIMEOUT    = -5;  // Communication timed out
  RIG_EIO         = -6;  // IO error, including open failed
  RIG_EINTERNAL   = -7;  // Internal Hamlib error
  RIG_EPROTO      = -8;  // Protocol error
  RIG_ERJCTED     = -9;  // Command rejected by the rig
  RIG_ETRUNC      = -10; // Command performed, but arg truncated
  RIG_ENAVAIL     = -11; // Function not available
  RIG_ENTARGET    = -12; // VFO not targetable
  RIG_BUSERROR    = -13; // Error talking on the bus
  RIG_BUSBUSY     = -14; // Collision on the bus
  RIG_EARG        = -15; // NULL RIG handle or invalid pointer
  RIG_EVFO        = -16; // Invalid VFO
  RIG_EDOM        = -17; // Argument out of domain
  RIG_EDEPRECATED = -18; // Function deprecated
  RIG_ESECURITY   = -19; // Security error
  RIG_EPOWER      = -20; // Rig not powered on
  RIG_ELIMIT      = -21; // Limit exceeded
  RIG_EACCESS     = -22; // Access denied (e.g., port already in use)

{-----------------------------------------------------------------------------
  Debug Levels
-----------------------------------------------------------------------------}

type
  rig_debug_level_e = (
    RIG_DEBUG_NONE = 0,  // No debug output
    RIG_DEBUG_BUG,       // Serious bug
    RIG_DEBUG_ERR,       // Error case
    RIG_DEBUG_WARN,      // Warning
    RIG_DEBUG_VERBOSE,   // Verbose
    RIG_DEBUG_TRACE,     // Tracing
    RIG_DEBUG_CACHE      // Cache debugging
  );

{-----------------------------------------------------------------------------
  VFO Definitions
-----------------------------------------------------------------------------}

const
  RIG_VFO_NONE     = $00000000;  // VFO unknown
  RIG_VFO_A        = $00000001;  // VFO A
  RIG_VFO_B        = $00000002;  // VFO B
  RIG_VFO_C        = $00000004;  // VFO C
  RIG_VFO_SUB_A    = $00200000;  // Sub VFO A
  RIG_VFO_SUB_B    = $00400000;  // Sub VFO B
  RIG_VFO_MAIN_A   = $00800000;  // Main VFO A
  RIG_VFO_MAIN_B   = $01000000;  // Main VFO B
  RIG_VFO_SUB      = $02000000;  // Sub VFO
  RIG_VFO_MAIN     = $04000000;  // Main VFO
  RIG_VFO_VFO      = $08000000;  // Last/any VFO mode
  RIG_VFO_MEM      = $10000000;  // Memory mode
  RIG_VFO_CURR     = $20000000;  // Current VFO
  RIG_VFO_TX_FLAG  = $40000000;  // Flag to set if VFO can transmit
  RIG_VFO_ALL      = $80000000;  // All VFOs

  RIG_VFO_TX       = RIG_VFO_CURR or RIG_VFO_TX_FLAG;  // Split TX
  RIG_VFO_RX       = RIG_VFO_CURR;                      // Split RX

{-----------------------------------------------------------------------------
  Mode Definitions (64-bit bitmasks)

  Note: These are bit flags computed as (1 << bit_number)
-----------------------------------------------------------------------------}

const
  RIG_MODE_NONE    = Int64(0);              // No mode
  RIG_MODE_AM      = Int64(1) shl 0;        // Amplitude Modulation
  RIG_MODE_CW      = Int64(1) shl 1;        // CW normal sideband
  RIG_MODE_USB     = Int64(1) shl 2;        // Upper Side Band
  RIG_MODE_LSB     = Int64(1) shl 3;        // Lower Side Band
  RIG_MODE_RTTY    = Int64(1) shl 4;        // Radio Teletype
  RIG_MODE_FM      = Int64(1) shl 5;        // Narrow band FM
  RIG_MODE_WFM     = Int64(1) shl 6;        // Broadcast wide FM
  RIG_MODE_CWR     = Int64(1) shl 7;        // CW reverse sideband
  RIG_MODE_RTTYR   = Int64(1) shl 8;        // RTTY reverse sideband
  RIG_MODE_AMS     = Int64(1) shl 9;        // AM Synchronous
  RIG_MODE_PKTLSB  = Int64(1) shl 10;       // Packet/Digital LSB
  RIG_MODE_PKTUSB  = Int64(1) shl 11;       // Packet/Digital USB
  RIG_MODE_PKTFM   = Int64(1) shl 12;       // Packet/Digital FM
  RIG_MODE_ECSSUSB = Int64(1) shl 13;       // ECSS USB
  RIG_MODE_ECSSLSB = Int64(1) shl 14;       // ECSS LSB
  RIG_MODE_FAX     = Int64(1) shl 15;       // Facsimile
  RIG_MODE_SAM     = Int64(1) shl 16;       // Synchronous AM double sideband
  RIG_MODE_SAL     = Int64(1) shl 17;       // Synchronous AM lower sideband
  RIG_MODE_SAH     = Int64(1) shl 18;       // Synchronous AM upper sideband
  RIG_MODE_DSB     = Int64(1) shl 19;       // Double sideband suppressed carrier
  RIG_MODE_FMN     = Int64(1) shl 21;       // FM Narrow
  RIG_MODE_PKTAM   = Int64(1) shl 22;       // Packet/Digital AM
  RIG_MODE_P25     = Int64(1) shl 23;       // APCO/P25 digital
  RIG_MODE_DSTAR   = Int64(1) shl 24;       // D-Star digital
  RIG_MODE_DPMR    = Int64(1) shl 25;       // dPMR digital
  RIG_MODE_NXDNVN  = Int64(1) shl 26;       // NXDN-VN digital
  RIG_MODE_NXDN_N  = Int64(1) shl 27;       // NXDN-N digital
  RIG_MODE_DCR     = Int64(1) shl 28;       // DCR digital
  RIG_MODE_AMN     = Int64(1) shl 29;       // AM Narrow
  RIG_MODE_PSK     = Int64(1) shl 30;       // PSK
  RIG_MODE_PSKR    = Int64(1) shl 31;       // PSK Reverse
  RIG_MODE_DD      = Int64(1) shl 32;       // DD Mode
  RIG_MODE_C4FM    = Int64(1) shl 33;       // Yaesu C4FM
  RIG_MODE_PKTFMN  = Int64(1) shl 34;       // Packet FM Narrow
  RIG_MODE_SPEC    = Int64(1) shl 35;       // Spectrum (unfiltered)
  RIG_MODE_CWN     = Int64(1) shl 36;       // CW Narrow
  RIG_MODE_IQ      = Int64(1) shl 37;       // IQ mode

  // Composite modes
  RIG_MODE_SSB     = RIG_MODE_USB or RIG_MODE_LSB;
  RIG_MODE_ECSS    = RIG_MODE_ECSSUSB or RIG_MODE_ECSSLSB;

{-----------------------------------------------------------------------------
  Passband Width
-----------------------------------------------------------------------------}

const
  RIG_PASSBAND_NORMAL   = 0;   // Normal passband for mode
  RIG_PASSBAND_NOCHANGE = -1;  // Leave passband unchanged

{-----------------------------------------------------------------------------
  PTT Status
-----------------------------------------------------------------------------}

const
  RIG_PTT_OFF      = 0;  // PTT deactivated
  RIG_PTT_ON       = 1;  // PTT activated
  RIG_PTT_ON_MIC   = 2;  // PTT Mic only
  RIG_PTT_ON_DATA  = 3;  // PTT Data (Mic-muted)

{-----------------------------------------------------------------------------
  Split Mode
-----------------------------------------------------------------------------}

const
  RIG_SPLIT_OFF = 0;  // Split mode disabled
  RIG_SPLIT_ON  = 1;  // Split mode enabled

{-----------------------------------------------------------------------------
  Configuration Tokens

  Common tokens for rig_set_conf() / rig_get_conf()
-----------------------------------------------------------------------------}

const
  TOK_PATHNAME      = 1;  // rig_pathname (e.g., 'COM3', '/dev/ttyS0')
  TOK_WRITE_DELAY   = 2;  // write_delay
  TOK_POST_WRITE_DELAY = 3;  // post_write_delay
  TOK_TIMEOUT       = 4;  // timeout
  TOK_RETRY         = 5;  // retry
  TOK_SERIAL_SPEED  = 10; // serial_speed (e.g., '38400')
  TOK_DATA_BITS     = 11; // data_bits
  TOK_STOP_BITS     = 12; // stop_bits
  TOK_PARITY        = 13; // parity
  TOK_HANDSHAKE     = 14; // handshake
  TOK_RTS_STATE     = 15; // rts_state
  TOK_DTR_STATE     = 16; // dtr_state

  // From hamlib/rig.h
  HAMLIB_FILPATHLEN = 512;  // Maximum pathname length

{-----------------------------------------------------------------------------
  Rig Model IDs

  Common radio model IDs - see riglist.h for complete list
-----------------------------------------------------------------------------}

const
  RIG_MODEL_NONE        = 0;
  RIG_MODEL_DUMMY       = 1;
  RIG_MODEL_NETRIGCTL   = 2;

  // Elecraft
  RIG_MODEL_K3          = 2029;
  RIG_MODEL_K4          = 2039;  // Elecraft K4

  // Yaesu
  RIG_MODEL_FT991       = 1035;
  RIG_MODEL_FTDX101D    = 1043;
  RIG_MODEL_FTDX101MP   = 1044;

  // Icom
  RIG_MODEL_IC7300      = 3073;
  RIG_MODEL_IC7610      = 3079;
  RIG_MODEL_IC9700      = 3081;

{-----------------------------------------------------------------------------
  Core API Functions
-----------------------------------------------------------------------------}

// Debug control
procedure rig_set_debug(debug_level: rig_debug_level_e); cdecl; external HAMLIB_DLL;

// Initialization and cleanup
function rig_init(rig_model: Integer): PRIG; cdecl; external HAMLIB_DLL;
function rig_open(rig: PRIG): Integer; cdecl; external HAMLIB_DLL;
function rig_close(rig: PRIG): Integer; cdecl; external HAMLIB_DLL;
function rig_cleanup(rig: PRIG): Integer; cdecl; external HAMLIB_DLL;

// Configuration
function rig_set_conf(rig: PRIG; token: hamlib_token_t; const val: PChar): Integer; cdecl; external HAMLIB_DLL;
function rig_get_conf(rig: PRIG; token: hamlib_token_t; val: PChar): Integer; cdecl; external HAMLIB_DLL;
function rig_token_lookup(rig: PRIG; const name: PChar): hamlib_token_t; cdecl; external HAMLIB_DLL;

{-----------------------------------------------------------------------------
  Frequency Control
-----------------------------------------------------------------------------}

function rig_set_freq(rig: PRIG; vfo: vfo_t; freq: freq_t): Integer; cdecl; external HAMLIB_DLL;
function rig_get_freq(rig: PRIG; vfo: vfo_t; var freq: freq_t): Integer; cdecl; external HAMLIB_DLL;

{-----------------------------------------------------------------------------
  Mode Control
-----------------------------------------------------------------------------}

function rig_set_mode(rig: PRIG; vfo: vfo_t; mode: rmode_t; width: pbwidth_t): Integer; cdecl; external HAMLIB_DLL;
function rig_get_mode(rig: PRIG; vfo: vfo_t; var mode: rmode_t; var width: pbwidth_t): Integer; cdecl; external HAMLIB_DLL;

{-----------------------------------------------------------------------------
  VFO Control
-----------------------------------------------------------------------------}

function rig_set_vfo(rig: PRIG; vfo: vfo_t): Integer; cdecl; external HAMLIB_DLL;
function rig_get_vfo(rig: PRIG; var vfo: vfo_t): Integer; cdecl; external HAMLIB_DLL;

{-----------------------------------------------------------------------------
  PTT Control
-----------------------------------------------------------------------------}

function rig_set_ptt(rig: PRIG; vfo: vfo_t; ptt: ptt_t): Integer; cdecl; external HAMLIB_DLL;
function rig_get_ptt(rig: PRIG; vfo: vfo_t; var ptt: ptt_t): Integer; cdecl; external HAMLIB_DLL;

{-----------------------------------------------------------------------------
  Split Operation
-----------------------------------------------------------------------------}

function rig_set_split_freq(rig: PRIG; vfo: vfo_t; tx_freq: freq_t): Integer; cdecl; external HAMLIB_DLL;
function rig_get_split_freq(rig: PRIG; vfo: vfo_t; var tx_freq: freq_t): Integer; cdecl; external HAMLIB_DLL;
function rig_set_split_mode(rig: PRIG; vfo: vfo_t; tx_mode: rmode_t; tx_width: pbwidth_t): Integer; cdecl; external HAMLIB_DLL;
function rig_get_split_mode(rig: PRIG; vfo: vfo_t; var tx_mode: rmode_t; var tx_width: pbwidth_t): Integer; cdecl; external HAMLIB_DLL;
function rig_set_split_vfo(rig: PRIG; vfo: vfo_t; split: Integer; tx_vfo: vfo_t): Integer; cdecl; external HAMLIB_DLL;
function rig_get_split_vfo(rig: PRIG; vfo: vfo_t; var split: Integer; var tx_vfo: vfo_t): Integer; cdecl; external HAMLIB_DLL;

{-----------------------------------------------------------------------------
  RIT/XIT Control
-----------------------------------------------------------------------------}

function rig_set_rit(rig: PRIG; vfo: vfo_t; rit: shortfreq_t): Integer; cdecl; external HAMLIB_DLL;
function rig_get_rit(rig: PRIG; vfo: vfo_t; var rit: shortfreq_t): Integer; cdecl; external HAMLIB_DLL;
function rig_set_xit(rig: PRIG; vfo: vfo_t; xit: shortfreq_t): Integer; cdecl; external HAMLIB_DLL;
function rig_get_xit(rig: PRIG; vfo: vfo_t; var xit: shortfreq_t): Integer; cdecl; external HAMLIB_DLL;

{-----------------------------------------------------------------------------
  Utility Functions
-----------------------------------------------------------------------------}

// Get error message for error code
function rigerror(errnum: Integer): PChar; cdecl; external HAMLIB_DLL;

// Mode string conversion
function rig_strrmode(mode: rmode_t): PChar; cdecl; external HAMLIB_DLL;

{-----------------------------------------------------------------------------
  Helper Functions (Delphi-specific)
-----------------------------------------------------------------------------}

// Convert error code to string
function RigErrorToString(errcode: Integer): string;

// Convert mode constant to readable string
function RigModeToString(mode: rmode_t): string;

// Convert VFO constant to readable string
function RigVFOToString(vfo: vfo_t): string;

// Get HamLib version string from DLL
function GetHamLibVersion: string;

// Direct structure access helper for setting pathname
// This bypasses rig_set_conf which may not work for all backends
procedure RigSetPathname(rig: PRIG; const pathname: string);

// Read back pathname for verification
function RigGetPathname(rig: PRIG): string;

// Set timeout for network operations (in milliseconds)
procedure RigSetTimeout(rig: PRIG; timeoutMs: Integer);

implementation

function GetHamLibVersion: string;
var
  hLib: HMODULE;
  pVersion: ^PChar;
begin
  Result := 'unknown';
  hLib := GetModuleHandle(HAMLIB_DLL);
  if hLib = 0 then
    hLib := LoadLibrary(HAMLIB_DLL);
  if hLib <> 0 then
  begin
    pVersion := GetProcAddress(hLib, 'hamlib_version2');
    if pVersion <> nil then
      Result := string(pVersion^);
  end;
end;

function RigErrorToString(errcode: Integer): string;
begin
  case errcode of
    RIG_OK:          Result := 'OK';
    RIG_EINVAL:      Result := 'Invalid parameter';
    RIG_ECONF:       Result := 'Invalid configuration';
    RIG_ENOMEM:      Result := 'Memory shortage';
    RIG_ENIMPL:      Result := 'Function not implemented';
    RIG_ETIMEOUT:    Result := 'Communication timeout';
    RIG_EIO:         Result := 'IO error';
    RIG_EINTERNAL:   Result := 'Internal error';
    RIG_EPROTO:      Result := 'Protocol error';
    RIG_ERJCTED:     Result := 'Command rejected';
    RIG_ETRUNC:      Result := 'Argument truncated';
    RIG_ENAVAIL:     Result := 'Function not available';
    RIG_ENTARGET:    Result := 'VFO not targetable';
    RIG_BUSERROR:    Result := 'Bus error';
    RIG_BUSBUSY:     Result := 'Bus busy';
    RIG_EARG:        Result := 'Invalid argument';
    RIG_EVFO:        Result := 'Invalid VFO';
    RIG_EDOM:        Result := 'Argument out of domain';
    RIG_EDEPRECATED: Result := 'Function deprecated';
    RIG_ESECURITY:   Result := 'Security error';
    RIG_EPOWER:      Result := 'Rig not powered on';
    RIG_ELIMIT:      Result := 'Limit exceeded';
    RIG_EACCESS:     Result := 'Access denied';
  else
    Result := Format('Unknown error (%d)', [errcode]);
  end;
end;

function RigModeToString(mode: rmode_t): string;
begin
  // Check for composite modes first
  if mode = RIG_MODE_SSB then
    Result := 'SSB'
  else if mode = RIG_MODE_ECSS then
    Result := 'ECSS'
  // Individual modes
  else if mode = RIG_MODE_AM then
    Result := 'AM'
  else if mode = RIG_MODE_CW then
    Result := 'CW'
  else if mode = RIG_MODE_USB then
    Result := 'USB'
  else if mode = RIG_MODE_LSB then
    Result := 'LSB'
  else if mode = RIG_MODE_RTTY then
    Result := 'RTTY'
  else if mode = RIG_MODE_FM then
    Result := 'FM'
  else if mode = RIG_MODE_WFM then
    Result := 'WFM'
  else if mode = RIG_MODE_CWR then
    Result := 'CWR'
  else if mode = RIG_MODE_RTTYR then
    Result := 'RTTYR'
  else if mode = RIG_MODE_AMS then
    Result := 'AMS'
  else if mode = RIG_MODE_PKTLSB then
    Result := 'PKT-LSB'
  else if mode = RIG_MODE_PKTUSB then
    Result := 'PKT-USB'
  else if mode = RIG_MODE_PKTFM then
    Result := 'PKT-FM'
  else if mode = RIG_MODE_FAX then
    Result := 'FAX'
  else if mode = RIG_MODE_PKTAM then
    Result := 'PKT-AM'
  else if mode = RIG_MODE_FMN then
    Result := 'FMN'
  else if mode = RIG_MODE_C4FM then
    Result := 'C4FM'
  else if mode = RIG_MODE_DSTAR then
    Result := 'D-STAR'
  else if mode = RIG_MODE_NONE then
    Result := 'NONE'
  else
    Result := Format('Mode($%x)', [mode]);
end;

function RigVFOToString(vfo: vfo_t): string;
begin
  // Note: RIG_VFO_RX = RIG_VFO_CURR, so we check TX flag first
  if (vfo and RIG_VFO_TX_FLAG) <> 0 then
  begin
    Result := 'TX';
    Exit;
  end;

  case vfo of
    RIG_VFO_NONE:   Result := 'NONE';
    RIG_VFO_A:      Result := 'VFO A';
    RIG_VFO_B:      Result := 'VFO B';
    RIG_VFO_C:      Result := 'VFO C';
    RIG_VFO_CURR:   Result := 'CURRENT';  // Also covers RIG_VFO_RX
    RIG_VFO_MEM:    Result := 'MEMORY';
    RIG_VFO_MAIN:   Result := 'MAIN';
    RIG_VFO_SUB:    Result := 'SUB';
    RIG_VFO_MAIN_A: Result := 'MAIN A';
    RIG_VFO_MAIN_B: Result := 'MAIN B';
    RIG_VFO_SUB_A:  Result := 'SUB A';
    RIG_VFO_SUB_B:  Result := 'SUB B';
  else
    Result := Format('VFO($%x)', [vfo]);
  end;
end;

procedure RigSetPathname(rig: PRIG; const pathname: string);
(*
  Directly sets the pathname in rig->state.rigport.pathname field.

  This is equivalent to the C code:
    strncpy(rig->state.rigport.pathname, pathname, HAMLIB_FILPATHLEN - 1);

  Structure layout (32-bit):
    struct rig:
      struct rig_caps *caps;        // +0, 4 bytes (pointer)
      struct rig_state state;       // +4

    struct rig_state:
      hamlib_port_t rigport;        // +0 (first field)

    struct hamlib_port_t:
      int fd;                       // +0, 4 bytes
      void *handle;                 // +4, 4 bytes
      int write_delay;              // +8, 4 bytes
      int post_write_delay;         // +12, 4 bytes
      struct timeout;               // +16, 8 bytes
      int retry;                    // +24, 4 bytes
      char pathname[512];           // +28, 512 bytes  <-- THIS IS WHAT WE SET

  So pathname is at offset: 4 (caps) + 28 (rigport fields) = 32 bytes from rig
*)
const
  PATHNAME_OFFSET = 32;  // Offset of pathname field from start of RIG structure
var
  pathnamePtr: PChar;
  sourceBytes: PChar;
  bytesToCopy: Integer;
  i: Integer;
begin
  if rig = nil then
    Exit;

  // Calculate pointer to pathname field
  pathnamePtr := PChar(Integer(rig) + PATHNAME_OFFSET);

  // Copy pathname string (similar to strncpy)
  sourceBytes := PChar(pathname);
  bytesToCopy := Length(pathname);
  if bytesToCopy > HAMLIB_FILPATHLEN - 1 then
    bytesToCopy := HAMLIB_FILPATHLEN - 1;

  // Copy bytes
  for i := 0 to bytesToCopy - 1 do
    pathnamePtr[i] := sourceBytes[i];

  // Null terminate
  pathnamePtr[bytesToCopy] := #0;
end;

function RigGetPathname(rig: PRIG): string;
const
  PATHNAME_OFFSET = 32;
var
  pathnamePtr: PChar;
begin
  Result := '';
  if rig = nil then
    Exit;

  // Calculate pointer to pathname field
  pathnamePtr := PChar(Integer(rig) + PATHNAME_OFFSET);

  // Read null-terminated string
  Result := string(pathnamePtr);
end;

procedure RigSetTimeout(rig: PRIG; timeoutMs: Integer);
(*
  Sets the timeout in rig->state.rigport.timeout field.

  Based on TR4QT HamlibRadio.cpp:77
    m_rig->state.rigport.timeout = 1000;  // 1000ms = 1 second

  Structure layout shows timeout is before pathname.
  Since pathname is at offset 32, and timeout is typically an int (4 bytes)
  positioned before several other fields and pathname, the timeout offset
  should be at offset 16 (after fd, handle, write_delay, post_write_delay).
*)
const
  TIMEOUT_OFFSET = 16;  // Offset of timeout field from start of RIG structure
var
  timeoutPtr: PInteger;
begin
  if rig = nil then
    Exit;

  // Calculate pointer to timeout field
  timeoutPtr := PInteger(Integer(rig) + TIMEOUT_OFFSET);

  // Set timeout value (in milliseconds)
  timeoutPtr^ := timeoutMs;
end;

end.
