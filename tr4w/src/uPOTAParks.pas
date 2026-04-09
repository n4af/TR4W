unit uPOTAParks;
{
  POTA (Parks on the Air) parks database.

  Downloads all_parks_ext.csv from pota.app and provides fast park name
  lookup by reference code (e.g. 'US-1274').

  Also normalizes abbreviated references typed by the operator:
    'US1274'  -> 'US-1274'  (letters+digits, no hyphen -> insert it)
    '1274'    -> 'US-1274'  (4+ digits only -> prepend country from MY PARK)
    'US-1274' -> 'US-1274'  (already canonical -> uppercase)
    '59'      -> ''          (2-3 digits -> RST, not a park ref)

  Usage:
    - At startup: if POTAParksFilePath exists, call LoadPOTAParks silently.
    - ExchangeWindowChange: call NormalizePOTAPark then GetPOTAParkName.
    - ProcessRSTAndPOTAPark: normalize tokens before IsValidPOTAPark checks.
    - Menu handler: call DownloadPOTAParksAsync; handle WM_POTA_DOWNLOAD_DONE.
}

interface

uses
   Windows, Messages, Classes, SysUtils, IdHTTP, IdSSLOpenSSL;

const
   POTA_PARKS_URL        = 'https://pota.app/all_parks_ext.csv';
   POTA_PARKS_FILENAME   = 'pota_parks.csv';

   // Posted to ANotifyWnd when async download completes.
   // wParam = 1 (download OK, file saved), 0 (download failed).
   // Main thread should call LoadPOTAParks then QuickDisplay the result.
   WM_POTA_DOWNLOAD_DONE = WM_APP + 200;

   // Posted to ANotifyWnd when async startup load completes.
   // lParam = TStringList pointer (already parsed; main thread owns it after this).
   // Main thread must call ApplyLoadedParks(lParam) from the handler.
   WM_POTA_LOAD_DONE = WM_APP + 201;

// Returns full path to the parks CSV (same directory as tr4w.exe).
function POTAParksFilePath: string;

// Loads parks from CSV file. Returns number of parks loaded, or -1 on error.
// Safe to call from the main thread only.
function LoadPOTAParks(const AFilename: string): Integer;

// Returns True when the park database is loaded and non-empty.
function POTAParksLoaded: Boolean;

// Look up park name by canonical reference (e.g. 'US-1274').
// Returns '' if not found or database not loaded.
function GetPOTAParkName(const AReference: string): string;

// Normalize a raw exchange token to canonical park reference form.
// AMyPark is the operator's own park (e.g. 'US-0663'), used to derive the
// country prefix for digits-only tokens.
// Returns '' if the token does not look like a park reference.
function NormalizePOTAPark(const AToken: string; const AMyPark: string): string;

// Start an asynchronous download of the parks CSV from pota.app.
// Saves to ATargetFile. On completion posts WM_POTA_DOWNLOAD_DONE to ANotifyWnd.
// The main thread should handle that message by calling LoadPOTAParks.
procedure DownloadPOTAParksAsync(const ATargetFile: string; ANotifyWnd: HWND);

// Start an asynchronous load of an already-downloaded parks CSV.
// Does all parsing off the UI thread. On completion posts WM_POTA_LOAD_DONE
// to ANotifyWnd with lParam = parsed TStringList pointer.
// The main thread MUST call ApplyLoadedParks(lParam) from that handler.
procedure LoadPOTAParksAsync(ANotifyWnd: HWND);

// Apply a pre-parsed parks list delivered via WM_POTA_LOAD_DONE lParam.
// Must be called on the main thread. Takes ownership of the TStringList.
procedure ApplyLoadedParks(ALParam: LPARAM);

implementation

// ---------------------------------------------------------------------------
// Internal state
// ---------------------------------------------------------------------------

var
   // Sorted TStringList: entries are 'REFERENCE=Park Name' (uppercase keys).
   FParks: TStringList = nil;

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function IsAllDigits(const S: string): Boolean;
var
   I: Integer;
begin
   Result := S <> '';
   for I := 1 to Length(S) do
      if not (S[I] in ['0'..'9']) then
         begin
         Result := False;
         Exit;
         end;
end;

function IsAllAlpha(const S: string): Boolean;
var
   I: Integer;
begin
   Result := S <> '';
   for I := 1 to Length(S) do
      if not (S[I] in ['A'..'Z', 'a'..'z']) then
         begin
         Result := False;
         Exit;
         end;
end;

// Extract the Nth (0-based) field from a CSV line.
// Handles double-quote quoting (RFC 4180 style).
function GetCSVField(const ALine: string; AIndex: Integer): string;
var
   I, Field: Integer;
   InQuote: Boolean;
   FieldStart: Integer;
begin
   Result := '';
   Field := 0;
   InQuote := False;
   FieldStart := 1;
   I := 1;
   while I <= Length(ALine) do
      begin
      if InQuote then
         begin
         if ALine[I] = '"' then
            begin
            if (I < Length(ALine)) and (ALine[I + 1] = '"') then
               Inc(I)  // escaped double-quote: skip extra quote
            else
               InQuote := False;
            end;
         end
      else
         begin
         if ALine[I] = '"' then
            InQuote := True
         else if ALine[I] = ',' then
            begin
            if Field = AIndex then
               begin
               Result := Copy(ALine, FieldStart, I - FieldStart);
               if (Length(Result) >= 2) and (Result[1] = '"') and
                  (Result[Length(Result)] = '"') then
                  Result := Copy(Result, 2, Length(Result) - 2);
               Exit;
               end;
            Inc(Field);
            FieldStart := I + 1;
            end;
         end;
      Inc(I);
      end;
   // Handle the last field (no trailing comma)
   if Field = AIndex then
      begin
      Result := Copy(ALine, FieldStart, Length(ALine));
      if (Length(Result) >= 2) and (Result[1] = '"') and
         (Result[Length(Result)] = '"') then
         Result := Copy(Result, 2, Length(Result) - 2);
      end;
end;

// ---------------------------------------------------------------------------
// Public implementation
// ---------------------------------------------------------------------------

function POTAParksFilePath: string;
begin
   Result := ExtractFilePath(ParamStr(0)) + POTA_PARKS_FILENAME;
end;

function LoadPOTAParks(const AFilename: string): Integer;
var
   Lines: TStringList;
   NewParks: TStringList;
   I: Integer;
   Ref, Name: string;
begin
   Result := -1;
   if not FileExists(AFilename) then
      Exit;
   Lines := TStringList.Create;
   NewParks := TStringList.Create;
   try
      NewParks.Sorted := True;
      NewParks.CaseSensitive := False;
      Lines.LoadFromFile(AFilename);
      // Row 0 is the CSV header — skip it
      for I := 1 to Lines.Count - 1 do
         begin
         Ref := UpperCase(Trim(GetCSVField(Lines[I], 0)));
         Name := Trim(GetCSVField(Lines[I], 1));
         if (Ref <> '') and (Name <> '') then
            NewParks.Add(Ref + '=' + Name);
         end;
      // Atomically swap in the new database
      FParks.Free;
      FParks := NewParks;
      NewParks := nil;  // Ownership transferred
      Result := FParks.Count;
   finally
      Lines.Free;
      if Assigned(NewParks) then
         NewParks.Free;
   end;
end;

function POTAParksLoaded: Boolean;
begin
   Result := Assigned(FParks) and (FParks.Count > 0);
end;

function GetPOTAParkName(const AReference: string): string;
begin
   Result := '';
   if not Assigned(FParks) then
      Exit;
   Result := FParks.Values[UpperCase(Trim(AReference))];
end;

function NormalizePOTAPark(const AToken: string; const AMyPark: string): string;
var
   I, DashPos: Integer;
   LetterPart, NumberPart, Prefix: string;
   S: string;
begin
   Result := '';
   S := Trim(AToken);
   if S = '' then
      Exit;

   // Case 1: Already canonical — 1-2 letters, hyphen, 1-5 digits.
   // e.g. 'US-1274' -> 'US-1274'  (just uppercase it)
   DashPos := Pos('-', S);
   if DashPos >= 2 then
      begin
      LetterPart := Copy(S, 1, DashPos - 1);
      NumberPart := Copy(S, DashPos + 1, MaxInt);
      if (Length(LetterPart) <= 2) and IsAllAlpha(LetterPart) and
         IsAllDigits(NumberPart) and (Length(NumberPart) >= 1) then
         begin
         Result := UpperCase(LetterPart) + '-' + NumberPart;
         Exit;
         end;
      end;

   // Case 2: Letters immediately followed by digits, no hyphen.
   // e.g. 'US1274' -> 'US-1274'
   I := 1;
   while (I <= Length(S)) and (S[I] in ['A'..'Z', 'a'..'z']) do
      Inc(I);
   if (I > 1) and (I <= 3) then  // 1-2 leading letters
      begin
      LetterPart := UpperCase(Copy(S, 1, I - 1));
      NumberPart := Copy(S, I, MaxInt);
      if IsAllDigits(NumberPart) and (Length(NumberPart) >= 1) then
         begin
         Result := LetterPart + '-' + NumberPart;
         Exit;
         end;
      end;

   // Case 3: All digits, 4 or more characters.
   // Treated as a park number; prepend country prefix from MyPark.
   // e.g. '1274' with MyPark='US-0663' -> 'US-1274'
   // Tokens with 2-3 digits (e.g. '59', '599') are RST values — ignored.
   if IsAllDigits(S) and (Length(S) >= 4) then
      begin
      DashPos := Pos('-', AMyPark);
      if DashPos >= 2 then
         Prefix := UpperCase(Copy(AMyPark, 1, DashPos - 1))
      else
         Exit;  // MyPark not set or has no hyphen — cannot determine prefix
      Result := Prefix + '-' + S;
      Exit;
      end;

   // Anything else ('59', '599', random words) — not a park reference.
   // Return the token unchanged so callers (RST detection, etc.) still work.
   Result := S;
end;

// ---------------------------------------------------------------------------
// Async startup load thread
// Parses the CSV entirely off the UI thread and hands the result to the
// main thread via PostMessage so FParks is only ever written from one thread.
// ---------------------------------------------------------------------------

type
   TPOTALoadThread = class(TThread)
   private
      FNotifyWnd: HWND;
   protected
      procedure Execute; override;
   public
      constructor Create(ANotifyWnd: HWND);
   end;

constructor TPOTALoadThread.Create(ANotifyWnd: HWND);
begin
   inherited Create(True);  // Create suspended
   FNotifyWnd := ANotifyWnd;
   FreeOnTerminate := True;
end;

procedure TPOTALoadThread.Execute;
var
   Lines: TStringList;
   NewParks: TStringList;
   I: Integer;
   Ref, Name: string;
   Filename: string;
begin
   Filename := POTAParksFilePath;
   if not FileExists(Filename) then
      Exit;  // Nothing to load; no notification needed
   Lines := TStringList.Create;
   NewParks := TStringList.Create;
   try
      NewParks.Sorted := True;
      NewParks.CaseSensitive := False;
      Lines.LoadFromFile(Filename);
      for I := 1 to Lines.Count - 1 do  // Row 0 is the CSV header
         begin
         Ref := UpperCase(Trim(GetCSVField(Lines[I], 0)));
         Name := Trim(GetCSVField(Lines[I], 1));
         if (Ref <> '') and (Name <> '') then
            NewParks.Add(Ref + '=' + Name);
         end;
      // Post the parsed list to the main thread. Ownership transfers on receipt.
      PostMessage(FNotifyWnd, WM_POTA_LOAD_DONE, 0, LPARAM(NewParks));
      NewParks := nil;  // Ownership passed via PostMessage
   except
      // Silently discard on any file/parse error
   end;
   Lines.Free;
   if Assigned(NewParks) then
      NewParks.Free;
end;

procedure LoadPOTAParksAsync(ANotifyWnd: HWND);
var
   Thread: TPOTALoadThread;
begin
   Thread := TPOTALoadThread.Create(ANotifyWnd);
   Thread.Resume;
end;

procedure ApplyLoadedParks(ALParam: LPARAM);
var
   NewParks: TStringList;
begin
   NewParks := TStringList(ALParam);
   if not Assigned(NewParks) then
      Exit;
   FParks.Free;
   FParks := NewParks;
end;

// ---------------------------------------------------------------------------
// Async download thread
// ---------------------------------------------------------------------------

type
   TPOTADownloadThread = class(TThread)
   private
      FTargetFile: string;
      FNotifyWnd: HWND;
   protected
      procedure Execute; override;
   public
      constructor Create(const ATargetFile: string; ANotifyWnd: HWND);
   end;

constructor TPOTADownloadThread.Create(const ATargetFile: string;
   ANotifyWnd: HWND);
begin
   inherited Create(True);  // Create suspended
   FTargetFile := ATargetFile;
   FNotifyWnd := ANotifyWnd;
   FreeOnTerminate := True;
end;

procedure TPOTADownloadThread.Execute;
var
   http: TIdHTTP;
   ssl: TIdSSLIOHandlerSocketOpenSSL;
   FileStream: TFileStream;
   Success: Boolean;
begin
   Success := False;
   http := TIdHTTP.Create(nil);
   ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
   try
      ssl.SSLOptions.Method := TIdSSLVersion(sslvTLSv1_2);
      http.IOHandler := ssl;
      http.HandleRedirects := True;
      http.Request.UserAgent := 'TR4W';
      try
         FileStream := TFileStream.Create(FTargetFile, fmCreate);
         try
            http.Get(POTA_PARKS_URL, FileStream);
            Success := True;
         finally
            FileStream.Free;
         end;
      except
         // Remove any partial file so a retry starts clean
         if FileExists(FTargetFile) then
            SysUtils.DeleteFile(FTargetFile);
      end;
   finally
      http.Free;
      ssl.Free;
   end;
   // Notify main thread: wParam=1 success, 0 failure.
   // Main thread calls LoadPOTAParks and shows result via QuickDisplay.
   PostMessage(FNotifyWnd, WM_POTA_DOWNLOAD_DONE, Ord(Success), 0);
end;

procedure DownloadPOTAParksAsync(const ATargetFile: string; ANotifyWnd: HWND);
var
   Thread: TPOTADownloadThread;
begin
   Thread := TPOTADownloadThread.Create(ATargetFile, ANotifyWnd);
   Thread.Resume;
end;

// ---------------------------------------------------------------------------

initialization
   FParks := nil;

finalization
   FParks.Free;
   FParks := nil;

end.
