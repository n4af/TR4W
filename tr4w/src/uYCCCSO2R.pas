{ uYCCCSO2R.pas

  YCCC SO2R+ box support via USB HID (OTRSP protocol).
  VID = 0x16C0  PID = 0x065E

  All communication goes through a single HID device — there is no serial
  COM port.  The box handles CW keying AND SO2R antenna/headphone switching.

  Reference implementation: trlinux/src/keyeryccc.pas + ycccprotocol.pas
  Protocol spec:            http://www.k1xm.org/OTRSP/OTRSP_Protocol.pdf

  Phase 1 scope:
    - HID device open/close (SetupAPI enumeration by VID/PID)
    - TX switching  (TX1 / TX2) — driven by SwapRadios in LOGSUBS1.PAS
    - RX switching  (RX1 / RX2 mono) — follows TX automatically
    - CW keyer      — replaces WinKeyer when ycccActive is True
    - Speed setting
    - YCCC SO2R ENABLE config command
}
unit uYCCCSO2R;

{$IMPORTEDDATA OFF}

interface

uses
   Windows;

{ Global enable flag — target of the 'YCCC SO2R ENABLE' config command }
var
   YCCCSo2rEnable: boolean = False;

{ True once the HID device is open and the read thread is running }
   ycccActive: boolean = False;

{ Lifecycle }
function  YCCCOpen: boolean;
procedure YCCCClose;

{ SO2R switching — call from SwapRadios with 1=Radio1 or 2=Radio2 }
procedure YCCCSetActiveRadio(radio: integer);

{ CW keyer interface — mirrors WinKeyer API used in LogCW.pas }
procedure YCCCAddCWMessageToBuffer(const msg: string);
procedure YCCCFlushCWBuffer;
function  YCCCCWBusy: boolean;
function  YCCCDeleteLastChar: boolean;
procedure YCCCSetSpeed(wpm: integer);

implementation

{ ---- OTRSP protocol constants (from ycccprotocol.pas) ------------------- }

const
   YCCC_VENDOR_ID  = $16C0;
   YCCC_PRODUCT_ID = $065E;

   CMD_KEYER_SPEED     = $11;
   CMD_KEYER_CONFIG    = $12;
   CMD_KEYER_CHAR      = $13;
   CMD_KEYER_OVERWRITE = $14;
   CMD_KEYER_ABORT     = $15;
   CMD_KEYER_EVENT     = $17;

   CMD_SO2R_STATE = $30;

   { SO2R state bitmask (so2r_state_t in ycccprotocol.pas) }
   SO2R_TX2    = $01;
   SO2R_RX2    = $02;
   SO2R_STEREO = $04;
   SO2R_PTT    = $08;

   { Keyer event values }
   KEYER_EVENT_END_CHAR = 1;
   KEYER_EVENT_IDLE     = 2;
   KEYER_EVENT_CLEAR    = 3;
   KEYER_EVENT_PADDLE   = 4;

   CW_BUFFER_SIZE  = 1024;
   HID_PACKET_SIZE = 3;   { report-ID byte + cmd + val }

{ ---- Windows SetupAPI / HID type declarations --------------------------- }

type
   HDEVINFO = THandle;

   TSP_DEVICE_INTERFACE_DATA = record
      cbSize:             DWORD;
      InterfaceClassGuid: TGUID;
      Flags:              DWORD;
      Reserved:           DWORD;
   end;

   { cbSize must be 5 on 32-bit (sizeof(DWORD) + 1 char) }
   TSP_DEVICE_INTERFACE_DETAIL_DATA = record
      cbSize:     DWORD;
      DevicePath: array[0..511] of AnsiChar;
   end;

   THIDD_ATTRIBUTES = record
      Size:          ULONG;
      VendorID:      Word;
      ProductID:     Word;
      VersionNumber: Word;
   end;

const
   DIGCF_PRESENT         = $00000002;
   DIGCF_DEVICEINTERFACE = $00000010;

function SetupDiGetClassDevsA(ClassGuid: PGUID; Enumerator: PAnsiChar;
   hwndParent: HWND; Flags: DWORD): HDEVINFO; stdcall;
   external 'setupapi.dll' name 'SetupDiGetClassDevsA';

function SetupDiEnumDeviceInterfaces(DeviceInfoSet: HDEVINFO;
   DeviceInfoData: Pointer; var InterfaceClassGuid: TGUID;
   MemberIndex: DWORD; var DeviceInterfaceData: TSP_DEVICE_INTERFACE_DATA): BOOL; stdcall;
   external 'setupapi.dll' name 'SetupDiEnumDeviceInterfaces';

function SetupDiGetDeviceInterfaceDetailA(DeviceInfoSet: HDEVINFO;
   DeviceInterfaceData: Pointer; DeviceInterfaceDetailData: Pointer;
   DeviceInterfaceDetailDataSize: DWORD; var RequiredSize: DWORD;
   DeviceInfoData: Pointer): BOOL; stdcall;
   external 'setupapi.dll' name 'SetupDiGetDeviceInterfaceDetailA';

function SetupDiDestroyDeviceInfoList(DeviceInfoSet: HDEVINFO): BOOL; stdcall;
   external 'setupapi.dll' name 'SetupDiDestroyDeviceInfoList';

procedure HidD_GetHidGuid(var HidGuid: TGUID); stdcall;
   external 'hid.dll' name 'HidD_GetHidGuid';

function HidD_GetAttributes(HidDeviceObject: THandle;
   var Attributes: THIDD_ATTRIBUTES): BOOL; stdcall;
   external 'hid.dll' name 'HidD_GetAttributes';

{ ---- Module state ------------------------------------------------------- }

var
   FHandle:     THandle = INVALID_HANDLE_VALUE;

   { SO2R state register — mirrors the box's internal state byte.
     Bits: 0=TX2, 1=RX2, 2=STEREO, 3=PTT }
   FSO2RState:  byte = 0;

   FKeyerSpeed: integer = 25;

   { Local CW character buffer.
     Main thread writes FCWBufEnd; read thread reads FCWBufStart. }
   FCWBuffer:   array[0..CW_BUFFER_SIZE-1] of AnsiChar;
   FCWBufStart: integer = 0;
   FCWBufEnd:   integer = 0;

   { FMirror: ASCII value of the character currently in the keyer hardware.
     0 means the keyer is free to accept the next character. }
   FMirror:     integer = 0;

   FKeyerIdle:  boolean = True;

   FReadThread: THandle = 0;
   FReadThID:   DWORD   = 0;
   FStopThread: boolean = False;

{ ---- Internal helpers --------------------------------------------------- }

procedure YCCCSendCmd(cmd, val: byte);
var
   pkt:     array[0..HID_PACKET_SIZE-1] of byte;
   written: DWORD;
begin
   if FHandle = INVALID_HANDLE_VALUE then
      begin
      Exit;
      end;
   pkt[0] := 0;    { HID report ID — always 0 for YCCC box }
   pkt[1] := cmd;
   pkt[2] := val;
   WriteFile(FHandle, pkt, HID_PACKET_SIZE, written, nil);
end;

{ Send the next character from the local buffer to the keyer.
  Called from the read thread on KEYER_EVENT_END_CHAR/IDLE, and from
  YCCCAddCWMessageToBuffer when the keyer is already idle. }
procedure YCCCSendNextChar;
begin
   if FMirror <> 0 then
      begin
      Exit;
      end;
   if FCWBufStart = FCWBufEnd then
      begin
      Exit;
      end;
   FMirror    := Ord(FCWBuffer[FCWBufStart]);
   FCWBufStart := (FCWBufStart + 1) mod CW_BUFFER_SIZE;
   FKeyerIdle  := False;
   YCCCSendCmd(CMD_KEYER_CHAR, byte(FMirror));
end;

{ ---- HID read thread ---------------------------------------------------- }

{ Reads 2-byte responses from the box in a blocking loop.
  Windows HID prepends a report-ID byte (0x00), so we read 3 bytes
  and skip the first byte when it is 0. }
function YCCCReadThreadProc(param: Pointer): DWORD; stdcall;
var
   buf:      array[0..HID_PACKET_SIZE-1] of byte;
   nRead:    DWORD;
   cmd, val: byte;
begin
   while not FStopThread do
      begin
      nRead := 0;
      if not ReadFile(FHandle, buf, SizeOf(buf), nRead, nil) then
         begin
         Break;   { handle was closed — exit cleanly }
         end;
      if nRead < 2 then
         begin
         Continue;
         end;

      { Determine cmd/val: Windows HID prepends a report-ID byte (0x00) }
      if (nRead = 3) and (buf[0] = 0) then
         begin
         cmd := buf[1];
         val := buf[2];
         end
      else
         begin
         cmd := buf[0];
         val := buf[1];
         end;

      if cmd = CMD_KEYER_EVENT then
         begin
         case val of
            KEYER_EVENT_END_CHAR:
            begin
               FMirror    := 0;
               FKeyerIdle := False;
               YCCCSendNextChar;
            end;

            KEYER_EVENT_IDLE:
            begin
               FMirror    := 0;
               FKeyerIdle := True;
               YCCCSendNextChar;
            end;

            KEYER_EVENT_CLEAR:
            begin
               FMirror    := 0;
               FKeyerIdle := True;
            end;

            KEYER_EVENT_PADDLE:
            begin
               { Paddle grabbed the keyer — discard pending local buffer }
               FCWBufStart := FCWBufEnd;
               FMirror     := 0;
            end;
         end;
         end;
      end;

   Result := 0;
end;

{ ---- HID device enumeration by VID / PID -------------------------------- }

function YCCCFindDevice: THandle;
var
   hidGuid:    TGUID;
   devInfo:    HDEVINFO;
   ifData:     TSP_DEVICE_INTERFACE_DATA;
   detailData: TSP_DEVICE_INTERFACE_DETAIL_DATA;
   attrs:      THIDD_ATTRIBUTES;
   reqSize:    DWORD;
   idx:        integer;
   h:          THandle;
begin
   Result := INVALID_HANDLE_VALUE;
   HidD_GetHidGuid(hidGuid);

   devInfo := SetupDiGetClassDevsA(@hidGuid, nil, 0,
      DIGCF_PRESENT or DIGCF_DEVICEINTERFACE);
   if devInfo = INVALID_HANDLE_VALUE then
      begin
      Exit;
      end;

   try
      idx := 0;
      repeat
         FillChar(ifData, SizeOf(ifData), 0);
         ifData.cbSize := SizeOf(TSP_DEVICE_INTERFACE_DATA);

         if not SetupDiEnumDeviceInterfaces(devInfo, nil, hidGuid, idx, ifData) then
            begin
            Break;
            end;
         Inc(idx);

         reqSize := 0;
         FillChar(detailData, SizeOf(detailData), 0);
         detailData.cbSize := 5;   { 32-bit: sizeof(DWORD) + 1 char = 5 }

         if not SetupDiGetDeviceInterfaceDetailA(devInfo, @ifData,
               @detailData, SizeOf(detailData), reqSize, nil) then
            begin
            Continue;
            end;

         h := CreateFileA(detailData.DevicePath,
            GENERIC_READ or GENERIC_WRITE,
            FILE_SHARE_READ or FILE_SHARE_WRITE,
            nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

         if h = INVALID_HANDLE_VALUE then
            begin
            Continue;
            end;

         FillChar(attrs, SizeOf(attrs), 0);
         attrs.Size := SizeOf(THIDD_ATTRIBUTES);

         if HidD_GetAttributes(h, attrs) and
            (attrs.VendorID  = YCCC_VENDOR_ID)  and
            (attrs.ProductID = YCCC_PRODUCT_ID) then
            begin
            Result := h;
            Exit;
            end;

         CloseHandle(h);
      until False;

   finally
      SetupDiDestroyDeviceInfoList(devInfo);
   end;
end;

{ ---- Public API --------------------------------------------------------- }

function YCCCOpen: boolean;
begin
   Result := False;

   FHandle := YCCCFindDevice;
   if FHandle = INVALID_HANDLE_VALUE then
      begin
      Exit;
      end;

   { Initialise SO2R state: TX1, RX1, mono, no PTT }
   FSO2RState := 0;
   YCCCSendCmd(CMD_SO2R_STATE, FSO2RState);

   { Initialise keyer }
   YCCCSendCmd(CMD_KEYER_SPEED, FKeyerSpeed);
   YCCCSendCmd(CMD_KEYER_CONFIG, 0);

   FCWBufStart := 0;
   FCWBufEnd   := 0;
   FMirror     := 0;
   FKeyerIdle  := True;
   FStopThread := False;

   FReadThread := CreateThread(nil, 0, @YCCCReadThreadProc, nil, 0, FReadThID);

   ycccActive := FReadThread <> 0;
   Result     := ycccActive;
end;

procedure YCCCClose;
begin
   ycccActive  := False;
   FStopThread := True;

   { Close the handle first — this unblocks the blocking ReadFile in the thread }
   if FHandle <> INVALID_HANDLE_VALUE then
      begin
      CloseHandle(FHandle);
      FHandle := INVALID_HANDLE_VALUE;
      end;

   if FReadThread <> 0 then
      begin
      WaitForSingleObject(FReadThread, 2000);
      CloseHandle(FReadThread);
      FReadThread := 0;
      end;
end;

procedure YCCCSetActiveRadio(radio: integer);
begin
   { TX and RX both follow the active radio (mono mode).
     Radio 2: set TX2 + RX2, clear STEREO.
     Radio 1: clear TX2 + RX2 + STEREO. }
   if radio = 2 then
      begin
      FSO2RState := (FSO2RState or (SO2R_TX2 or SO2R_RX2)) and not SO2R_STEREO;
      end
   else
      begin
      FSO2RState := FSO2RState and not (SO2R_TX2 or SO2R_RX2 or SO2R_STEREO);
      end;
   YCCCSendCmd(CMD_SO2R_STATE, FSO2RState);
end;

procedure YCCCAddCWMessageToBuffer(const msg: string);
var
   i: integer;
   c: AnsiChar;
begin
   for i := 1 to Length(msg) do
      begin
      c := AnsiChar(UpCase(msg[i]));
      case c of
         'A'..'Z', '0'..'9', ' ', '.', ',', '?', '/', '+', '=':
         begin
            FCWBuffer[FCWBufEnd] := c;
            FCWBufEnd := (FCWBufEnd + 1) mod CW_BUFFER_SIZE;
         end;
      end;
      end;

   { Kick off sending if the keyer is idle and nothing is in flight }
   if FKeyerIdle and (FMirror = 0) then
      begin
      YCCCSendNextChar;
      end;
end;

procedure YCCCFlushCWBuffer;
begin
   FCWBufStart := FCWBufEnd;
   FMirror     := 0;
   YCCCSendCmd(CMD_KEYER_ABORT, 0);
   FKeyerIdle  := True;
end;

function YCCCCWBusy: boolean;
begin
   Result := (not FKeyerIdle) or
             (FCWBufStart <> FCWBufEnd) or
             (FMirror <> 0);
end;

function YCCCDeleteLastChar: boolean;
begin
   { Remove the last character from the local buffer if possible }
   if FCWBufStart <> FCWBufEnd then
      begin
      FCWBufEnd := (FCWBufEnd - 1 + CW_BUFFER_SIZE) mod CW_BUFFER_SIZE;
      Result    := True;
      Exit;
      end;

   { Otherwise ask the box to cancel the character currently in flight }
   Result := FMirror <> 0;
   if Result then
      begin
      YCCCSendCmd(CMD_KEYER_OVERWRITE, 0);
      FMirror := 0;
      end;
end;

procedure YCCCSetSpeed(wpm: integer);
begin
   if wpm < 2 then
      begin
      wpm := 2;
      end;
   if wpm > 99 then
      begin
      wpm := 99;
      end;
   FKeyerSpeed := wpm;
   if FHandle <> INVALID_HANDLE_VALUE then
      begin
      YCCCSendCmd(CMD_KEYER_SPEED, FKeyerSpeed);
      end;
end;

end.
