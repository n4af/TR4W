unit uTestUtilsFile;

{
  Unit tests for utils_file.sWriteFileFromString.

  Regression net for the v4.147.04 stack-buffer-overflow fix (Issue #887):
  the prior implementation copied its input into a fixed 256-byte stack buffer
  via StrLCopy and then asked WriteFile to write Length(sBuffer) bytes -- so any
  input >= 256 chars wrote 256 valid bytes followed by uninitialized stack data
  (truncation + garbage).  It only mattered once the ADIF export refactor wrote
  a whole document in one call.

  These tests write a string through sWriteFileFromString to a real temp file,
  read the raw bytes back, and assert the file contents match the input exactly
  -- byte count AND content -- across the 256-byte boundary.
}

interface

uses
   SysUtils, Windows, uTR4WTestFramework, utils_file;

type
   TUtilsFileTests = class(TTestCase)
   protected
      // Write s via sWriteFileFromString, read the raw file back as a string.
      function RoundTrip(const s: string): string;

      procedure Test_LongString_NoTruncationOrGarbage;
      procedure Test_BoundaryLengths_255_256_257;
      procedure Test_ShortString;
      procedure Test_EmptyString_WritesNothing;
   public
      procedure RunAllTests; override;
   end;

implementation

function TUtilsFileTests.RoundTrip(const s: string): string;
var
   tmpDir  : array[0..MAX_PATH] of Char;
   tmpFile : array[0..MAX_PATH] of Char;
   h       : THandle;
   buf     : string;
   got     : DWORD;
begin
   Result := '';
   GetTempPath(MAX_PATH, tmpDir);
   GetTempFileName(tmpDir, 'tr4', 0, tmpFile);   // creates a unique temp file

   // Write phase
   h := CreateFile(tmpFile, GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
                   FILE_ATTRIBUTE_TEMPORARY, 0);
   Check(h <> INVALID_HANDLE_VALUE, 'temp file opened for write');
   try
      sWriteFileFromString(h, s);
   finally
      CloseHandle(h);
   end;

   // Read phase -- request more than we wrote so a length mismatch (extra
   // garbage bytes) would be visible, not silently clipped.
   h := CreateFile(tmpFile, GENERIC_READ, 0, nil, OPEN_EXISTING, 0, 0);
   Check(h <> INVALID_HANDLE_VALUE, 'temp file opened for read');
   try
      SetLength(buf, Length(s) + 64);
      got := 0;
      ReadFile(h, PChar(buf)^, Length(buf), got, nil);
      SetLength(buf, got);
      Result := buf;
   finally
      CloseHandle(h);
      DeleteFile(tmpFile);
   end;
end;

procedure TUtilsFileTests.Test_LongString_NoTruncationOrGarbage;
var
   s, got : string;
   i      : Integer;
begin
   BeginTest('Test_LongString_NoTruncationOrGarbage');
   // 1000 chars -- well past the old 256-byte stack buffer.
   s := '';
   for i := 1 to 1000 do
      s := s + Chr(Ord('A') + (i mod 26));
   got := RoundTrip(s);
   CheckEquals(Length(s), Length(got), 'byte count matches (no truncation, no extra)');
   CheckEquals(s, got, 'content matches exactly past the 256-byte boundary');
end;

procedure TUtilsFileTests.Test_BoundaryLengths_255_256_257;
var
   n : Integer;
   s, got : string;
   i : Integer;
begin
   BeginTest('Test_BoundaryLengths_255_256_257');
   for n := 255 to 257 do
      begin
      s := '';
      for i := 1 to n do
         s := s + Chr(Ord('0') + (i mod 10));
      got := RoundTrip(s);
      CheckEquals(n, Length(got), Format('length %d round-trips', [n]));
      CheckEquals(s, got, Format('content of length %d matches', [n]));
      end;
end;

procedure TUtilsFileTests.Test_ShortString;
var
   got : string;
begin
   BeginTest('Test_ShortString');
   // The historically-safe case (short fragments) must still work.
   got := RoundTrip('<CALL:4>KG1S<EOR>');
   CheckEquals('<CALL:4>KG1S<EOR>', got, 'short string round-trips');
end;

procedure TUtilsFileTests.Test_EmptyString_WritesNothing;
var
   got : string;
begin
   BeginTest('Test_EmptyString_WritesNothing');
   // Empty string: sWriteFileFromString returns True and writes zero bytes.
   got := RoundTrip('');
   CheckEquals(0, Length(got), 'empty string produces a 0-byte file');
end;

procedure TUtilsFileTests.RunAllTests;
begin
   Test_LongString_NoTruncationOrGarbage;
   Test_BoundaryLengths_255_256_257;
   Test_ShortString;
   Test_EmptyString_WritesNothing;
end;

end.
