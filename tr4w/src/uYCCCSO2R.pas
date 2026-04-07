{ uYCCCSO2R.pas

  YCCC SO2R+ box support via USB HID (OTRSP protocol).
  VID = 0x16C0  PID = 0x065E

  Reference: trlinux/src/keyeryccc.pas (uses hid_set_nonblocking — non-blocking I/O)
             trlinux/src/ycccprotocol.pas

  Threading model
  ---------------
  The device is opened with FILE_FLAG_OVERLAPPED so no I/O call ever blocks.

  Main thread  : calls YCCCSendCmd — enqueues cmd+val, signals FWriteEvent.
                 Never touches FHandle directly. Always returns immediately.
  Write thread : WaitForMultipleObjects([FWriteEvent, FStopEvent]);
                 drains write queue via overlapped WriteFile (50ms timeout).
  Read thread  : overlapped ReadFile + WaitForMultipleObjects([readOvl, FStopEvent]).
                 Calls CancelIo and exits cleanly when FStopEvent fires.

  Shutdown sequence (YCCCClose)
  -----------------------------
  1. SetEvent(FStopEvent)  -- wakes both threads
  2. WaitForSingleObject   -- read thread: CancelIo then exits
  3. WaitForSingleObject   -- write thread exits
  4. CloseHandle(FHandle)  -- now safe (no pending I/O)
  5. CloseHandle events

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
   WRITE_TIMEOUT_MS = 100;  { overlapped WriteFile timeout in milliseconds }

   ERROR_IO_PENDING = 997;

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

function CancelIo(hFile: THandle): BOOL; stdcall;
   external 'kernel32.dll' name 'CancelIo';

{ ---- Module state ------------------------------------------------------- }

var
   FHandle:     THandle = INVALID_HANDLE_VALUE;

   { SO2R state register - mirrors the box's internal state byte }
   FSO2RState:  byte = 0;
   FKeyerSpeed: integer = 25;

   { Local CW character buffer.
     Main thread writes FCWBufEnd; read thread reads FCWBufStart. }
   FCWBuffer:   array[0..CW_BUFFER_SIZE-1] of AnsiChar;
   FCWBufStart: integer = 0;
   FCWBufEnd:   integer = 0;

   { FMirror: ASCII value of character currently in the keyer hardware (0 = free) }
   FMirror:     integer = 0;
   FKeyerIdle:  boolean = True;

   { Write queue: main thread produces (FWriteQueueTail), write thread consumes (FWriteQueueHead) }
   FWriteQueue:     array[0..WRITE_QUEUE_SIZE-1] of TWriteEntry;
   FWriteQueueHead: integer = 0;
   FWriteQueueTail: integer = 0;

   { Synchronisation handles }
   FWriteEvent:  THandle = 0;   { auto-reset: signals write thread there is data }
   FStopEvent:   THandle = 0;   { manual-reset: signals both threads to stop }

   { Overlapped structures for each thread's I/O }
   FReadOvl:    OVERLAPPED;
   FWriteOvl:   OVERLAPPED;

   FReadThread:  THandle = 0;
   FReadThID:    DWORD   = 0;
   FWriteThread: THandle = 0;
   FWriteThID:   DWORD   = 0;

   logger: TLogLogger;

{ ---- Internal helpers --------------------------------------------------- }

{ Enqueue a command and wake the write thread.  Never blocks - safe from any thread. }
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
      logger.Debug('YCCC write queue full, dropping cmd=$' + IntToHex(cmd, 2));
      Exit;
      end;
   FWriteQueue[FWriteQueueTail].cmd := cmd;
   FWriteQueue[FWriteQueueTail].val := val;
   FWriteQueueTail := nextTail;
   SetEvent(FWriteEvent);
end;

{ Send the next CW character to the keyer.  Called from read thread only. }
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

function YCCCWriteThreadProc(param: Pointer): DWORD; stdcall;
var
   pkt:      array[0..HID_PACKET_SIZE-1] of byte;
   written:  DWORD;
   err:      DWORD;
   entry:    TWriteEntry;
   handles:  array[0..1] of THandle;
   waitRes:  DWORD;
begin
   logger.Debug('YCCC write thread started');
   handles[0] := FWriteEvent;
   handles[1] := FStopEvent;

   while True do
      begin
      waitRes := WaitForMultipleObjects(2, @handles[0], False, INFINITE);
      if waitRes = WAIT_OBJECT_0 + 1 then
         begin
         Break;   { stop event }
         end;

      while FWriteQueueHead <> FWriteQueueTail do
         begin
         entry           := FWriteQueue[FWriteQueueHead];
         FWriteQueueHead := (FWriteQueueHead + 1) mod WRITE_QUEUE_SIZE;
         pkt[0] := 0;
         pkt[1] := entry.cmd;
         pkt[2] := entry.val;
         logger.Debug('YCCC TX: cmd=$' + IntToHex(entry.cmd, 2) +
            ' val=$' + IntToHex(entry.val, 2));
         ResetEvent(FWriteOvl.hEvent);
         written := 0;
         if not WriteFile(FHandle, pkt, HID_PACKET_SIZE, written, @FWriteOvl) then
            begin
            err := GetLastError;
            if err = ERROR_IO_PENDING then
               begin
               { Wait for write completion with timeout }
               WaitForSingleObject(FWriteOvl.hEvent, WRITE_TIMEOUT_MS);
               end
            else
               begin
               logger.Debug('YCCC WriteFile error: ' + IntToStr(err));
               end;
            end;
         end;
      end;

   logger.Debug('YCCC write thread stopped');
   Result := 0;
end;

{ ---- Read thread -------------------------------------------------------- }

function YCCCReadThreadProc(param: Pointer): DWORD; stdcall;
var
   buf:      array[0..HID_PACKET_SIZE-1] of byte;
   nRead:    DWORD;
   err:      DWORD;
   cmd, val: byte;
   handles:  array[0..1] of THandle;
   waitRes:  DWORD;
begin
   logger.Debug('YCCC read thread started');
   handles[0] := FReadOvl.hEvent;
   handles[1] := FStopEvent;

   while True do
      begin
      FillChar(buf, SizeOf(buf), 0);
      nRead := 0;
      ResetEvent(FReadOvl.hEvent);

      if ReadFile(FHandle, buf, SizeOf(buf), nRead, @FReadOvl) then
         begin
         { Completed synchronously - fall through to process }
         end
      else
         begin
         err := GetLastError;
         if err <> ERROR_IO_PENDING then
            begin
            logger.Debug('YCCC ReadFile error: ' + IntToStr(err));
            Break;
            end;
         { Wait for data or stop signal }
         waitRes := WaitForMultipleObjects(2, @handles[0], False, INFINITE);
         if waitRes = WAIT_OBJECT_0 + 1 then
            begin
            { Stop event - cancel pending read and exit }
            CancelIo(FHandle);
            logger.Debug('YCCC read thread: stop requested');
            Break;
            end;
         if not GetOverlappedResult(FHandle, FReadOvl, nRead, False) then
            begin
            logger.Debug('YCCC GetOverlappedResult failed: ' + IntToStr(GetLastError));
            Break;
            end;
         end;

      if nRead < 2 then
         begin
         Continue;
         end;

      { Windows HID prepends a report-ID byte (0x00) }
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

      logger.Debug('YCCC RX: $' + IntToHex(buf[0], 2) + ' $' +
         IntToHex(buf[1], 2) + ' $' + IntToHex(buf[2], 2));

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

         { Open with FILE_FLAG_OVERLAPPED so all I/O is non-blocking }
         h := CreateFileA(detailData.DevicePath,
            GENERIC_READ or GENERIC_WRITE,
            FILE_SHARE_READ or FILE_SHARE_WRITE,
            nil, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);

         if h = INVALID_HANDLE_VALUE then
            begin
            Continue;
            end;

         FillChar(attrs, SizeOf(attrs), 0);
         attrs.Size := SizeOf(THIDD_ATTRIBUTES);

         if HidD_GetAttributes(h, attrs) and
            (attrs.VendorID  = YCCC_VENDOR_ID) and
            (attrs.ProductID = YCCC_PRODUCT_ID) then
            begin
            logger.Debug('YCCC device found at HID index ' + IntToStr(idx - 1));
            Result := h;
            Exit;
            end;

         CloseHandle(h);
      until False;

   finally
      SetupDiDestroyDeviceInfoList(devInfo);
   end;

   logger.Debug('YCCC device not found (VID=$16C0 PID=$065E)');
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
   FSO2RState      := 0;
   FKeyerSpeed     := 25;
   FCWBufStart     := 0;
   FCWBufEnd       := 0;
   FMirror         := 0;
   FKeyerIdle      := True;
   FWriteQueueHead := 0;
   FWriteQueueTail := 0;

   { Events }
   FWriteEvent := CreateEvent(nil, False, False, nil);  { auto-reset }
   FStopEvent  := CreateEvent(nil, True,  False, nil);  { manual-reset }

   FillChar(FReadOvl,  SizeOf(FReadOvl),  0);
   FillChar(FWriteOvl, SizeOf(FWriteOvl), 0);
   FReadOvl.hEvent  := CreateEvent(nil, True, False, nil);
   FWriteOvl.hEvent := CreateEvent(nil, True, False, nil);

   if (FWriteEvent = 0) or (FStopEvent = 0) or
      (FReadOvl.hEvent = 0) or (FWriteOvl.hEvent = 0) then
      begin
      logger.Debug('YCCC CreateEvent failed');
      YCCCClose;
      Exit;
      end;

   { Start write thread first so queued init commands get sent immediately }
   FWriteThread := CreateThread(nil, 0, @YCCCWriteThreadProc, nil, 0, FWriteThID);
   if FWriteThread = 0 then
      begin
      logger.Debug('YCCC write thread creation failed');
      YCCCClose;
      Exit;
      end;

   { Queue init commands }
   YCCCSendCmd(CMD_SO2R_STATE,  FSO2RState);
   YCCCSendCmd(CMD_KEYER_SPEED, FKeyerSpeed);
   YCCCSendCmd(CMD_KEYER_CONFIG, 0);

   { Start read thread }
   FReadThread := CreateThread(nil, 0, @YCCCReadThreadProc, nil, 0, FReadThID);
   if FReadThread = 0 then
      begin
      logger.Debug('YCCC read thread creation failed');
      YCCCClose;
      Exit;
      end;

   ycccActive := True;
   Result     := True;
   logger.Debug('YCCC opened successfully (overlapped I/O)');
end;

procedure YCCCClose;
begin
   ycccActive := False;

   { Signal both threads to stop }
   if FStopEvent <> 0 then
      begin
      SetEvent(FStopEvent);
      end;

   { Wait for threads to exit cleanly.
     Read thread calls CancelIo on itself when it sees FStopEvent.
     Write thread exits its WaitForMultipleObjects loop. }
   if FReadThread <> 0 then
      begin
      WaitForSingleObject(FReadThread, 3000);
      CloseHandle(FReadThread);
      FReadThread := 0;
      end;

   if FWriteThread <> 0 then
      begin
      WaitForSingleObject(FWriteThread, 3000);
      CloseHandle(FWriteThread);
      FWriteThread := 0;
      end;

   { Now safe to close the device handle }
   if FHandle <> INVALID_HANDLE_VALUE then
      begin
      CloseHandle(FHandle);
      FHandle := INVALID_HANDLE_VALUE;
      end;

   if FReadOvl.hEvent <> 0 then
      begin
      CloseHandle(FReadOvl.hEvent);
      FReadOvl.hEvent := 0;
      end;

   if FWriteOvl.hEvent <> 0 then
      begin
      CloseHandle(FWriteOvl.hEvent);
      FWriteOvl.hEvent := 0;
      end;

   if FWriteEvent <> 0 then
      begin
      CloseHandle(FWriteEvent);
      FWriteEvent := 0;
      end;

   if FStopEvent <> 0 then
      begin
      CloseHandle(FStopEvent);
      FStopEvent := 0;
      end;

   if logger <> nil then
      begin
      logger.Debug('YCCC closed');
      end;
end;

procedure YCCCSetActiveRadio(radio: integer);
begin
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
     YCCCSendNextChar -> YCCCSendCmd -> SetEvent only, no blocking. }
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
   if FCWBufStart <> FCWBufEnd then
      begin
      FCWBufEnd := (FCWBufEnd - 1 + CW_BUFFER_SIZE) mod CW_BUFFER_SIZE;
      Result    := True;
      Exit;
      end;
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
   if wpm < 2 then wpm := 2;
   if wpm > 99 then wpm := 99;
   FKeyerSpeed := wpm;
   logger.Debug('YCCC CW speed ' + IntToStr(wpm) + ' wpm');
   YCCCSendCmd(CMD_KEYER_SPEED, FKeyerSpeed);
end;

end.
