unit utils_file;

interface

uses SysUtils, Windows;

function FileExists(FileName: PChar): boolean;

function sWriteFile(hFile: THandle; const Buffer; nNumberOfBytesToWrite: DWORD): BOOL;
function sWriteFileFromString(hFile: THandle; sBuffer: string): BOOL;
function tWriteFile(hFile: THandle; const Buffer; nNumberOfBytesToWrite: DWORD; var lpNumberOfBytesWritten: DWORD): BOOL;
function sReadFile(hFile: THandle; var Buffer; nNumberOfBytesToRead: DWORD): BOOL;

function tOpenFileForWrite(var h: HWND; FileName: PChar): boolean;
function OpenFileForWrite(var FileHandle: Text; FileName: string): boolean;

implementation

var
  tr4w_FIND_DATA                        : WIN32_FIND_DATA;

function FileExists(FileName: PChar): boolean;
{ This function will return TRUE if the filename specified exists. }
var
  h                                     : HWND;
begin
  Result := False;
  h := Windows.FindFirstFile(FileName, tr4w_FIND_DATA);
  if h <> INVALID_HANDLE_VALUE then
  begin
    FindClose(h);
    Result := True;
  end;
 end;

function tWriteFile(hFile: THandle; const Buffer; nNumberOfBytesToWrite: DWORD; var lpNumberOfBytesWritten: DWORD): BOOL;
begin
  Result := Windows.WriteFile(hFile, Buffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, nil);
end;

function sReadFile(hFile: THandle; var Buffer; nNumberOfBytesToRead: DWORD): BOOL;
var
  lpNumberOfBytesRead                   : DWORD;
begin
  Result := Windows.ReadFile(hFile, Buffer, nNumberOfBytesToRead, lpNumberOfBytesRead, nil);
end;

function sWriteFile(hFile: THandle; const Buffer; nNumberOfBytesToWrite: DWORD): BOOL;
var
  lpNumberOfBytesWritten                : DWORD;
begin
  Result := Windows.WriteFile(hFile, Buffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, nil);
end;

function sWriteFileFromString(hFile: THandle; sBuffer: string): BOOL;
// Write the entire string to hFile.  Bug history: prior versions copied
// sBuffer into a fixed 256-byte stack buffer via StrLCopy and then asked
// WriteFile to write length(sBuffer) bytes -- which read random stack
// data past the end of the buffer for any input >= 256 chars.  Old code
// happened to work because every caller passed a short fragment; the
// ADIF export refactor (Issue #887) writes the whole document in one
// call and immediately tripped the bug.  Write the string contents
// directly -- no fixed buffer, no length cap.
var
   lpNumberOfBytesWritten                : DWORD;
begin
   if sBuffer = '' then
      begin
      Result := True;
      Exit;
      end;
   Result := Windows.WriteFile(hFile, PChar(sBuffer)^, Length(sBuffer),
                               lpNumberOfBytesWritten, nil);
end;

function tOpenFileForWrite(var h: HWND; FileName: PChar): boolean;
begin
  h := CreateFile(FileName, GENERIC_READ + GENERIC_WRITE, FILE_SHARE_READ + FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);
  Result := h <> INVALID_HANDLE_VALUE;
end;

function OpenFileForWrite(var FileHandle: Text; FileName: string): boolean;

begin
  Assign(FileHandle, FileName);
{$I-}
  ReWrite(FileHandle);
{$I+}
  OpenFileForWrite := IORESULT = 0;
end;


end.


