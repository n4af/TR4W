unit uSerialPort;

interface

uses
  Windows, SysUtils;

type
  ESerialError = class(Exception);

  TSerialBaudRate = (
    sbr110, sbr300, sbr600, sbr1200, sbr2400, sbr4800,
    sbr9600, sbr19200, sbr38400, sbr57600, sbr115200
  );

  TSerialParity = (spNone, spOdd, spEven, spMark, spSpace);
  TSerialStopBits = (ssb1, ssb1_5, ssb2);

  TSerialPort = class
  private
    FHandle: THandle;
    FPortName: string;
    function GetIsOpen: Boolean;
    function BaudToConst(ABaud: TSerialBaudRate): DWORD;
    function ParityToConst(AParity: TSerialParity): Byte;
    function StopBitsToConst(AStopBits: TSerialStopBits): Byte;
    procedure CheckHandle;
  public
    constructor Create(const APortName: string);
    destructor Destroy; override;

    procedure Open(
      ABaud: TSerialBaudRate = sbr9600;
      ADataBits: Byte = 8;
      AParity: TSerialParity = spNone;
      AStopBits: TSerialStopBits = ssb1
    );
    procedure OpenRaw(
      ABaudRate: DWORD;
      ADataBits: Byte;
      AStopBits: Byte;
      AParity: Byte
    );
    procedure Close;

    function Read(var Buffer; Count: DWORD): DWORD;
    function Write(const Buffer; Count: DWORD): DWORD;
    function ReadString(MaxLen: Integer): string;
    procedure WriteString(const S: string);

    property Handle: THandle read FHandle;
    property PortName: string read FPortName;
    property IsOpen: Boolean read GetIsOpen;
  end;

implementation

{ TSerialPort }

constructor TSerialPort.Create(const APortName: string);
begin
  inherited Create;
  FHandle := INVALID_HANDLE_VALUE;
  FPortName := APortName;  // e.g. 'COM1', 'COM3', 'COM10'
end;

destructor TSerialPort.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TSerialPort.GetIsOpen: Boolean;
begin
  Result := FHandle <> INVALID_HANDLE_VALUE;
end;

procedure TSerialPort.CheckHandle;
begin
  if not IsOpen then
    raise ESerialError.Create('Serial port not open');
end;

function TSerialPort.BaudToConst(ABaud: TSerialBaudRate): DWORD;
begin
  case ABaud of
    sbr110:     Result := CBR_110;
    sbr300:     Result := CBR_300;
    sbr600:     Result := CBR_600;
    sbr1200:    Result := CBR_1200;
    sbr2400:    Result := CBR_2400;
    sbr4800:    Result := CBR_4800;
    sbr9600:    Result := CBR_9600;
    sbr19200:   Result := CBR_19200;
    sbr38400:   Result := CBR_38400;
    sbr57600:   Result := CBR_57600;
    sbr115200:  Result := CBR_115200;
  else
    Result := CBR_9600;
  end;
end;

function TSerialPort.ParityToConst(AParity: TSerialParity): Byte;
begin
  case AParity of
    spNone:  Result := NOPARITY;
    spOdd:   Result := ODDPARITY;
    spEven:  Result := EVENPARITY;
    spMark:  Result := MARKPARITY;
    spSpace: Result := SPACEPARITY;
  else
    Result := NOPARITY;
  end;
end;

function TSerialPort.StopBitsToConst(AStopBits: TSerialStopBits): Byte;
begin
  case AStopBits of
    ssb1:    Result := ONESTOPBIT;
    ssb1_5:  Result := ONE5STOPBITS;
    ssb2:    Result := TWOSTOPBITS;
  else
    Result := ONESTOPBIT;
  end;
end;

procedure TSerialPort.Open(
  ABaud: TSerialBaudRate;
  ADataBits: Byte;
  AParity: TSerialParity;
  AStopBits: TSerialStopBits);
var
  DCB: TDCB;
  Timeouts: COMMTIMEOUTS;
  PortStr: string;
begin
  if IsOpen then
    Exit;

  // For COM10+ you MUST use the \\.\ prefix
  if Pos('\\.\', FPortName) = 0 then
    PortStr := '\\.\' + FPortName
  else
    PortStr := FPortName;

  FHandle := CreateFile(
    PChar(PortStr),
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
  );
  if FHandle = INVALID_HANDLE_VALUE then
    raise ESerialError.CreateFmt('Cannot open %s (error %d)',
      [FPortName, GetLastError]);

  // Configure line settings
  FillChar(DCB, SizeOf(DCB), 0);
  DCB.DCBlength := SizeOf(DCB);
  if not GetCommState(FHandle, DCB) then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
    raise ESerialError.Create('GetCommState failed');
  end;

  DCB.BaudRate := BaudToConst(ABaud);
  DCB.ByteSize := ADataBits;
  DCB.Parity   := ParityToConst(AParity);
  DCB.StopBits := StopBitsToConst(AStopBits);
  // Flags are set via Flags field in Delphi 7
  DCB.Flags := DCB.Flags or $0001;  // fBinary = 1
  if AParity <> spNone then
    DCB.Flags := DCB.Flags or $0002;  // fParity = 1

  if not SetCommState(FHandle, DCB) then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
    raise ESerialError.Create('SetCommState failed');
  end;

  // Non-blocking timeouts for thread-based reading
  FillChar(Timeouts, SizeOf(Timeouts), 0);
  Timeouts.ReadIntervalTimeout         := 10;   // Max 10ms between characters
  Timeouts.ReadTotalTimeoutMultiplier  := 0;    // No per-byte timeout
  Timeouts.ReadTotalTimeoutConstant    := 10;   // Max 10ms total wait
  Timeouts.WriteTotalTimeoutMultiplier := 10;
  Timeouts.WriteTotalTimeoutConstant   := 50;

  if not SetCommTimeouts(FHandle, Timeouts) then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
    raise ESerialError.Create('SetCommTimeouts failed');
  end;

  // Clear buffers
  PurgeComm(FHandle, PURGE_RXCLEAR or PURGE_TXCLEAR);
end;

procedure TSerialPort.OpenRaw(
  ABaudRate: DWORD;
  ADataBits: Byte;
  AStopBits: Byte;
  AParity: Byte);
var
  DCB: TDCB;
  Timeouts: COMMTIMEOUTS;
  PortStr: string;
begin
  if IsOpen then
    Exit;

  // For COM10+ you MUST use the \\.\ prefix
  if Pos('\\.\', FPortName) = 0 then
    PortStr := '\\.\' + FPortName
  else
    PortStr := FPortName;

  FHandle := CreateFile(
    PChar(PortStr),
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
  );
  if FHandle = INVALID_HANDLE_VALUE then
    raise ESerialError.CreateFmt('Cannot open %s (error %d)',
      [FPortName, GetLastError]);

  // Configure line settings
  FillChar(DCB, SizeOf(DCB), 0);
  DCB.DCBlength := SizeOf(DCB);
  if not GetCommState(FHandle, DCB) then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
    raise ESerialError.Create('GetCommState failed');
  end;

  // Use raw values directly
  DCB.BaudRate := ABaudRate;
  DCB.ByteSize := ADataBits;
  DCB.Parity   := AParity;

  // Convert stop bits: 1=ONESTOPBIT(0), 2=TWOSTOPBITS(2)
  if AStopBits = 1 then
    DCB.StopBits := ONESTOPBIT
  else if AStopBits = 2 then
    DCB.StopBits := TWOSTOPBITS
  else
    DCB.StopBits := ONESTOPBIT;  // Default to 1

  // Flags are set via Flags field in Delphi 7
  DCB.Flags := DCB.Flags or $0001;  // fBinary = 1
  if AParity <> 0 then  // 0 = no parity
    DCB.Flags := DCB.Flags or $0002;  // fParity = 1

  if not SetCommState(FHandle, DCB) then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
    raise ESerialError.Create('SetCommState failed');
  end;

  // Non-blocking timeouts for thread-based reading
  FillChar(Timeouts, SizeOf(Timeouts), 0);
  Timeouts.ReadIntervalTimeout         := 10;   // Max 10ms between characters
  Timeouts.ReadTotalTimeoutMultiplier  := 0;    // No per-byte timeout
  Timeouts.ReadTotalTimeoutConstant    := 10;   // Max 10ms total wait
  Timeouts.WriteTotalTimeoutMultiplier := 10;
  Timeouts.WriteTotalTimeoutConstant   := 50;

  if not SetCommTimeouts(FHandle, Timeouts) then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
    raise ESerialError.Create('SetCommTimeouts failed');
  end;

  // Clear buffers
  PurgeComm(FHandle, PURGE_RXCLEAR or PURGE_TXCLEAR);
end;

procedure TSerialPort.Close;
begin
  if IsOpen then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
  end;
end;

function TSerialPort.Read(var Buffer; Count: DWORD): DWORD;
begin
  CheckHandle;
  if not ReadFile(FHandle, Buffer, Count, Result, nil) then
    raise ESerialError.CreateFmt('ReadFile failed (error %d)', [GetLastError]);
end;

function TSerialPort.Write(const Buffer; Count: DWORD): DWORD;
begin
  CheckHandle;
  if not WriteFile(FHandle, Buffer, Count, Result, nil) then
    raise ESerialError.CreateFmt('WriteFile failed (error %d)', [GetLastError]);
end;

function TSerialPort.ReadString(MaxLen: Integer): string;
var
  Buffer: array[0..1023] of Char;
  BytesRead: DWORD;
  Len: Integer;
begin
  Result := '';
  if MaxLen > SizeOf(Buffer) then
    Len := SizeOf(Buffer)
  else
    Len := MaxLen;

  BytesRead := Read(Buffer, Len);
  if BytesRead > 0 then
  begin
    SetString(Result, Buffer, BytesRead);
  end;
end;

procedure TSerialPort.WriteString(const S: string);
begin
  if Length(S) > 0 then
    Write(S[1], Length(S));
end;

end.
