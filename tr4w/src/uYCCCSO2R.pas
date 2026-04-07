{ uYCCCSO2R.pas

  YCCC SO2R+ box support via USB HID (OTRSP protocol).
  VID = 0x16C0  PID = 0x065E

  All communication goes through a single HID device - there is no serial
  COM port.  The box handles CW keying AND SO2R antenna/headphone switching.

  Reference implementation: trlinux/src/keyeryccc.pas + ycccprotocol.pas
  Protocol spec:            http://www.k1xm.org/OTRSP/OTRSP_Protocol.pdf

  Threading model
  ---------------
  Main thread  : never touches FHandle, never calls WriteFile/ReadFile.
                 YCCCSendCmd only enqueues a command and sets FWriteEvent.
  Write thread : wakes on FWriteEvent, drains write queue via WriteFile.
  Read thread  : blocking ReadFile loop; advances CW buffer on keyer events.

  Phase 1 scope:
    - HID device open/close (SetupAPI enumeration by VID/PID)
    - TX switching  (TX1 / TX2) - driven by SwapRadios in LOGSUBS1.PAS
    - RX switching  (RX1 / RX2 mono) - follows TX automatically
    - CW keyer      - replaces WinKeyer when ycccActive is True
    - Speed setting
    - YCCC SO2R ENABLE config command
}
unit uYCCCSO2R;

{$IMPORTEDDATA OFF}

interface

uses
   Windows;

{ Global enable flag - target of the 'YCCC SO2R ENABLE' config command }
var
   YCCCSo2rEnable: boolean = False;

{ True once the HID device is open and threads are running }
   ycccActive: boolean = False;

{ Lifecycle }
function  YCCCOpen: boolean;
procedure YCCCClose;

{ SO2R switching - call from SwapRadios with 1=Radio1 or 2=Radio2 }
procedure YCCCSetActiveRadio(radio: integer);

{ CW keyer interface - mirrors WinKeyer API used in LogCW.pas }
procedure YCCCAddCWMessageToBuffer(const msg: string);
procedure YCCCFlushCWBuffer;
function  YCCCCWBusy: boolean;
function  YCCCDeleteLastChar: boolean;
procedure YCCCSetSpeed(wpm: integer);

implementation

uses
   Log4D, SysUtils;

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

   CW_BUFFER_SIZE   = 1024;
   HID_PACKET_SIZE  = 3;    { report-ID byte + cmd + val }
   WRITE_QUEUE_SIZE = 64;

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

   TWriteEntry = record
      cmd: byte;
      val: byte;
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

   { SO2R state register - mirrors the box's internal state byte.
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

   { Write queue - main thread enqueues here, write thread drains it.
     Main thread only updates FWriteQueueTail.
     Write thread only updates FWriteQueueHead. }
   FWriteQueue:     array[0..WRITE_QUEUE_SIZE-1] of TWriteEntry;
   FWriteQueueHead: integer = 0;
   FWriteQueueTail: integer = 0;
   FWriteEvent:     THandle = 0;   { auto-reset event }

   FReadThread:  THandle = 0;
   FReadThID:    DWORD   = 0;
   FWriteThread: THandle = 0;
   FWriteThID:   DWORD   = 0;
   FStopThread:  boolean = False;

   logger: TLogLogger;

{ ---- Internal helpers --------------------------------------------------- }

{ Enqueue a command and wake the write thread.  Safe to call from any thread.
  Never blocks - just a memory write + SetEvent. }
procedure YCCCSendCmd(cmd, val: byte);
var
   nextTail: integer;
begin
   if FHandle = INVALID_HANDLE_VALUE then
      begin
      Exit;
      end;
   nextTail := (FWriteQueueTail + 1) mod WRITE_QUEUE_SIZE;
   if nextTail = FWriteQueueHead then
      begin
      { Queue full - drop the command rather than block }
      logger.Debug('YCCC write queue full, dropping command');
      Exit;
      end;
   FWriteQueue[FWriteQueueTail].cmd := cmd;
   FWriteQueue[FWriteQueueTail].val := val;
   FWriteQueueTail := nextTail;
   SetEvent(FWriteEvent);
end;

{ Send the next character from the local buffer to the keyer.
  Called from the read thread only - never from main thread. }
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
   FMirror     := Ord(FCWBuffer[FCWBufStart]);
   FCWBufStart := (FCWBufStart + 1) mod CW_BUFFER_SIZE;
   FKeyerIdle  := False;
   logger.Debug('YCCC CW send char: ' + Chr(FMirror));
   YCCCSendCmd(CMD_KEYER_CHAR, byte(FMirror));
end;

{ ---- Write thread ------------------------------------------------------- }

{ Drains FWriteQueue via WriteFile.  Never runs on the main thread. }
function YCCCWriteThreadProc(param: Pointer): DWORD; stdcall;
var
   pkt:     array[0..HID_PACKET_SIZE-1] of byte;
   written: DWORD;
   entry:   TWriteEntry;
begin
   logger.Debug('YCCC write thread started');
   while not FStopThread do
      begin
      WaitForSingleObject(FWriteEvent, 100);
      while (FWriteQueueHead <> FWriteQueueTail) and not FStopThread do
         begin
         entry           := FWriteQueue[FWriteQueueHead];
         FWriteQueueHead := (FWriteQueueHead + 1) mod WRITE_QUEUE_SIZE;
         pkt[0] := 0;
         pkt[1] := entry.cmd;
         pkt[2] := entry.val;
         logger.Debug('YCCC TX: cmd=$' + IntToHex(entry.cmd, 2) +
            ' val=$' + IntToHex(entry.val, 2));
         WriteFile(FHandle, pkt, HID_PACKET_SIZE, written, nil);
         end;
      end;
   logger.Debug('YCCC write thread stopped');
   Result := 0;
end;

{ ---- Read thread -------------------------------------------------------- }

{ Reads 2-byte responses from the box in a blocking loop.
  Windows HID prepends a report-ID byte (0x00), so we read 3 bytes. }
function YCCCReadThreadProc(param: Pointer): DWORD; stdcall;
var
   buf:      array[0..HID_PACKET_SIZE-1] of byte;
   nRead:    DWORD;
   cmd, val: byte;
begin
   logger.Debug('YCCC read thread started');
   while not FStopThread do
      begin
      nRead := 0;
      if not ReadFile(FHandle, buf, SizeOf(buf), nRead, nil) then
         begin
         logger.Debug('YCCC read thread: ReadFile failed - handle closed');
         Break;
         end;
      if nRead < 2 then
         begin
         Continue;
         end;

      logger.Debug('YCCC RX: ' + IntToStr(nRead) + ' bytes: $' +
         IntToHex(buf[0], 2) + ' $' + IntToHex(buf[1], 2) +
         ' $' + IntToHex(buf[2], 2));

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
         logger.Debug('YCCC keyer event: ' + IntToStr(val));
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
               { Paddle grabbed the keyer - discard pending local buffer }
               FCWBufStart := FCWBufEnd;
               FMirror     := 0;
               logger.Debug('YCCC paddle interrupt - CW buffer cleared');
            end;
         end;
         end;
      end;

   logger.Debug('YCCC read thread stopped');
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
      logger.Debug('YCCC SetupDiGetClassDevsA failed');
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
            logger.Debug('YCCC device found at index ' + IntToStr(idx - 1));
            Result := h;
            Exit;
            end;

         CloseHandle(h);
      until False;

   finally
      SetupDiDestroyDeviceInfoList(devInfo);
   end;

   logger.Debug('YCCC device not found (VID=16C0 PID=065E)');
end;

{ ---- Public API --------------------------------------------------------- }

function YCCCOpen: boolean;
begin
   Result := False;

   logger := TLogLogger.GetLogger('uYCCCSO2R');
   logger.Debug('YCCC opening device');
   FHandle := YCCCFindDevice;
   if FHandle = INVALID_HANDLE_VALUE then
      begin
      logger.Debug('YCCC device not found');
      Exit;
      end;

   { Initialise state }
   FSO2RState  := 0;
   FKeyerSpeed := 25;
   FCWBufStart := 0;
   FCWBufEnd   := 0;
   FMirror     := 0;
   FKeyerIdle  := True;
   FStopThread := False;
   FWriteQueueHead := 0;
   FWriteQueueTail := 0;

   { Create write event (auto-reset) }
   FWriteEvent := CreateEvent(nil, False, False, nil);
   if FWriteEvent = 0 then
      begin
      logger.Debug('YCCC CreateEvent failed');
      CloseHandle(FHandle);
      FHandle := INVALID_HANDLE_VALUE;
      Exit;
      end;

   { Start write thread first so queued init commands get sent }
   FWriteThread := CreateThread(nil, 0, @YCCCWriteThreadProc, nil, 0, FWriteThID);
   if FWriteThread = 0 then
      begin
      logger.Debug('YCCC write thread creation failed');
      CloseHandle(FWriteEvent);
      FWriteEvent := 0;
      CloseHandle(FHandle);
      FHandle := INVALID_HANDLE_VALUE;
      Exit;
      end;

   { Queue init commands - write thread will send them }
   YCCCSendCmd(CMD_SO2R_STATE,  FSO2RState);
   YCCCSendCmd(CMD_KEYER_SPEED, FKeyerSpeed);
   YCCCSendCmd(CMD_KEYER_CONFIG, 0);

   { Start read thread }
   FReadThread := CreateThread(nil, 0, @YCCCReadThreadProc, nil, 0, FReadThID);
   if FReadThread = 0 then
      begin
      logger.Debug('YCCC read thread creation failed');
      FStopThread := True;
      SetEvent(FWriteEvent);
      WaitForSingleObject(FWriteThread, 2000);
      CloseHandle(FWriteThread);
      FWriteThread := 0;
      CloseHandle(FWriteEvent);
      FWriteEvent := 0;
      CloseHandle(FHandle);
      FHandle := INVALID_HANDLE_VALUE;
      Exit;
      end;

   ycccActive := True;
   Result     := True;
   logger.Debug('YCCC opened successfully');
end;

procedure YCCCClose;
begin
   ycccActive  := False;
   FStopThread := True;

   { Close the HID handle first - this unblocks the blocking ReadFile }
   if FHandle <> INVALID_HANDLE_VALUE then
      begin
      CloseHandle(FHandle);
      FHandle := INVALID_HANDLE_VALUE;
      end;

   { Wake the write thread so it sees FStopThread }
   if FWriteEvent <> 0 then
      begin
      SetEvent(FWriteEvent);
      end;

   if FReadThread <> 0 then
      begin
      WaitForSingleObject(FReadThread, 2000);
      CloseHandle(FReadThread);
      FReadThread := 0;
      end;

   if FWriteThread <> 0 then
      begin
      WaitForSingleObject(FWriteThread, 2000);
      CloseHandle(FWriteThread);
      FWriteThread := 0;
      end;

   if FWriteEvent <> 0 then
      begin
      CloseHandle(FWriteEvent);
      FWriteEvent := 0;
      end;

   logger.Debug('YCCC closed');
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
   logger.Debug('YCCC SO2R state -> radio ' + IntToStr(radio) +
      ' (state=$' + IntToHex(FSO2RState, 2) + ')');
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

   logger.Debug('YCCC CW buffer: "' + msg + '"');

   { Kick off sending if the keyer is idle and nothing is in flight.
     YCCCSendNextChar calls YCCCSendCmd which only sets an event - safe from main thread. }
   if FKeyerIdle and (FMirror = 0) then
      begin
      YCCCSendNextChar;
      end;
end;

procedure YCCCFlushCWBuffer;
begin
   FCWBufStart := FCWBufEnd;
   FMirror     := 0;
   FKeyerIdle  := True;
   logger.Debug('YCCC CW flush');
   YCCCSendCmd(CMD_KEYER_ABORT, 0);
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
      logger.Debug('YCCC CW delete last char (overwrite)');
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
   logger.Debug('YCCC CW speed ' + IntToStr(wpm) + ' wpm');
   YCCCSendCmd(CMD_KEYER_SPEED, FKeyerSpeed);
end;

end.
