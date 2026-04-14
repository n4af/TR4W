unit uCTYUpdate;
{
  CTY.DAT version check and automatic download.

  Startup: CheckCTYVersionAsync fetches the RSS feed from country-files.com
  on a background thread, compares the date version to the installed file,
  and posts WM_CTY_VERSION_CHECKED(wParam=1, lParam=date) when an update is
  available. The main thread handler shows a QuickDisplay hint.

  Download: DownloadCTYAsync fetches cty.dat on a background thread and
  posts WM_CTY_DOWNLOAD_DONE when done. The main thread handler calls
  ctyLoadInCountryFile to reload — safe because the message handler is a
  quiescent point (CTY tables have no locking).

  Threading model matches uPOTAParks.pas exactly.
}

interface

uses
   Windows, Messages, Classes, SysUtils, IdHTTP, IdSSLOpenSSL;

const
   WM_CTY_VERSION_CHECKED = WM_APP + 210;
   // wParam=1: update available, lParam=latest version date integer (e.g. 20251218)
   // wParam=0: already up to date or check failed silently

   WM_CTY_DOWNLOAD_DONE = WM_APP + 211;
   // wParam=1: file saved successfully; wParam=0: download failed

procedure CheckCTYVersionAsync(ANotifyWnd: HWND);
// Starts a background thread that fetches the RSS feed and compares the
// latest version to the installed CTY.DAT. Posts WM_CTY_VERSION_CHECKED.

procedure DownloadCTYAsync(const ATargetFile: string; ANotifyWnd: HWND);
// Starts a background thread that downloads cty.dat to ATargetFile.
// Posts WM_CTY_DOWNLOAD_DONE on completion.

function GetInstalledCTYVersion: integer;
// Scans the installed CTY.DAT for the embedded =VER\d{8} version marker
// and returns the date as an integer (e.g. 20260414), or 0 if not found.
// Called from background thread only.

implementation

uses
   MainUnit,
   VC;

const
   CTY_RSS_URL      = 'https://www.country-files.com/feed/';
   CTY_DOWNLOAD_URL = 'https://www.country-files.com/cty/cty.dat';

// ---------------------------------------------------------------------------
// ParseVERDate
//
// Scans S for the pattern 'VER' followed immediately by exactly 8 digits.
// Returns the 8-digit integer (e.g. 20251218) or 0 if not found.
// ---------------------------------------------------------------------------

function ParseVERDate(const S: string): integer;
var
   P: integer;
   I: integer;
   Digits: string;
begin
   Result := 0;
   P := Pos('VER', S);
   if P = 0 then
      Exit;
   Inc(P, 3);  // advance past 'VER'
   if (P + 7) > Length(S) then
      Exit;
   Digits := '';
   for I := P to P + 7 do
      begin
      if not (S[I] in ['0'..'9']) then
         Exit;
      Digits := Digits + S[I];
      end;
   Result := StrToIntDef(Digits, 0);
end;

// ---------------------------------------------------------------------------
// ParseCTYRSS
//
// Extracts version info from the RSS feed XML. Locates the first
// <item><description> block and scans it for:
//   VER\d{8}  — date version integer (e.g. 20251218)
//   CTY-\d+   — numeric build (e.g. 3615, for log display only)
//
// No XML library is needed: the WordPress RSS structure is predictable.
// Returns True if a valid date version was found.
// ---------------------------------------------------------------------------

function ParseCTYRSS(const AXML: string;
   out ALatestDate, ANumericBuild: integer): boolean;
var
   P, I:  integer;
   Sub:   string;
   Digits: string;
begin
   Result        := False;
   ALatestDate   := 0;
   ANumericBuild := 0;

   // Narrow to the substring starting at the first <item>
   P := Pos('<item>', AXML);
   if P = 0 then
      Exit;
   Sub := Copy(AXML, P, Length(AXML));

   // Find <description> within that item
   P := Pos('<description>', Sub);
   if P = 0 then
      Exit;
   Inc(P, Length('<description>'));
   Sub := Copy(Sub, P, Length(Sub));

   // Trim at closing tag so we don't scan into the next item
   P := Pos('</description>', Sub);
   if P > 0 then
      Sub := Copy(Sub, 1, P - 1);

   // Extract VER\d{8} date
   ALatestDate := ParseVERDate(Sub);
   if ALatestDate = 0 then
      Exit;

   // Extract CTY-\d+ numeric build (for log display only)
   P := Pos('CTY-', Sub);
   if P > 0 then
      begin
      Inc(P, 4);  // advance past 'CTY-'
      Digits := '';
      I := P;
      while (I <= Length(Sub)) and (Sub[I] in ['0'..'9']) do
         begin
         Digits := Digits + Sub[I];
         Inc(I);
         end;
      ANumericBuild := StrToIntDef(Digits, 0);
      end;

   Result := True;
end;

// ---------------------------------------------------------------------------
// GetInstalledCTYVersion
//
// Scans CTY.DAT line-by-line for the embedded =VER\d{8} version marker.
// Returns the date integer (e.g. 20260414), or 0 if absent or not found.
// ---------------------------------------------------------------------------

function GetInstalledCTYVersion: integer;
var
   F:      TextFile;
   Line:   string;
   P, I:   integer;
   Digits: string;
begin
   Result := 0;
   AssignFile(F, string(PChar(@TR4W_CTY_FILENAME)));
   {$I-}
   Reset(F);
   {$I+}
   if IOResult <> 0 then
      Exit;
   try
      while not EOF(F) do
         begin
         ReadLn(F, Line);
         // Match =VER\d{8} — the '=' prefix makes this unambiguous vs. other
         // occurrences of 'VER' in the file.
         P := Pos('=VER', Line);
         if P = 0 then
            Continue;
         Inc(P, 4);  // advance past '=VER'
         if (P + 7) > Length(Line) then
            Continue;
         Digits := '';
         for I := P to P + 7 do
            begin
            if not (Line[I] in ['0'..'9']) then
               begin
               Digits := '';
               Break;
               end;
            Digits := Digits + Line[I];
            end;
         if Length(Digits) = 8 then
            begin
            Result := StrToIntDef(Digits, 0);
            if Result > 0 then
               Exit;
            end;
         end;
   finally
      CloseFile(F);
   end;
end;

// ---------------------------------------------------------------------------
// DownloadFileToPath
//
// Shared HTTP download helper used by all download threads.
// Downloads AURL to ATargetFile using an atomic .tmp-then-rename pattern
// so the target file is never left in a partial state.
// Returns True on success. Called from background threads only.
// ---------------------------------------------------------------------------

function DownloadFileToPath(const AURL, ATargetFile: string): boolean;
var
   http:    TIdHTTP;
   ssl:     TIdSSLIOHandlerSocketOpenSSL;
   fs:      TFileStream;
   tmpFile: string;
begin
   Result  := False;
   tmpFile := ATargetFile + '.tmp';
   http := TIdHTTP.Create(nil);
   ssl  := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
   try
      ssl.SSLOptions.Method  := TIdSSLVersion(sslvTLSv1_2);
      http.IOHandler         := ssl;
      http.HandleRedirects   := True;
      http.Request.UserAgent := 'TR4W';
      try
         fs := TFileStream.Create(tmpFile, fmCreate);
         try
            http.Get(AURL, fs);
         finally
            fs.Free;
         end;
         // Atomic replace: only remove the live file once .tmp is fully written
         SysUtils.DeleteFile(ATargetFile);
         Result := RenameFile(tmpFile, ATargetFile);
      except
         on E: Exception do
            begin
            logger.Error('[CTYUpdate] Download failed: %s', [E.Message]);
            SysUtils.DeleteFile(tmpFile);
            end;
      end;
   finally
      http.Free;
      ssl.Free;
   end;
end;

// ---------------------------------------------------------------------------
// Version check thread
// ---------------------------------------------------------------------------

type
   TCTYVersionCheckThread = class(TThread)
   private
      FNotifyWnd: HWND;
   protected
      procedure Execute; override;
   public
      constructor Create(ANotifyWnd: HWND);
   end;

constructor TCTYVersionCheckThread.Create(ANotifyWnd: HWND);
begin
   inherited Create(True);  // suspended; caller calls Resume
   FNotifyWnd      := ANotifyWnd;
   FreeOnTerminate := True;
end;

procedure TCTYVersionCheckThread.Execute;
var
   http:          TIdHTTP;
   ssl:           TIdSSLIOHandlerSocketOpenSSL;
   rssXml:        string;
   latestDate:    integer;
   numericBuild:  integer;
   installedDate: integer;
begin
   http := TIdHTTP.Create(nil);
   ssl  := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
   try
      ssl.SSLOptions.Method  := TIdSSLVersion(sslvTLSv1_2);
      http.IOHandler         := ssl;
      http.HandleRedirects   := True;
      http.Request.UserAgent := 'TR4W';
      try
         rssXml := http.Get(CTY_RSS_URL);
         if ParseCTYRSS(rssXml, latestDate, numericBuild) then
            begin
            installedDate := GetInstalledCTYVersion;
            logger.Info('[CTYUpdate] Installed CTY version: %d', [installedDate]);
            logger.Info('[CTYUpdate] Latest CTY version available: %d (CTY-%d)',
               [latestDate, numericBuild]);
            if latestDate > installedDate then
               begin
               logger.Info('[CTYUpdate] Update available — notifying user');
               PostMessage(FNotifyWnd, WM_CTY_VERSION_CHECKED, 1, latestDate);
               end
            else
               begin
               logger.Info('[CTYUpdate] CTY is up to date');
               PostMessage(FNotifyWnd, WM_CTY_VERSION_CHECKED, 0, 0);
               end;
            end
         else
            begin
            logger.Warn('[CTYUpdate] Failed to parse RSS feed');
            PostMessage(FNotifyWnd, WM_CTY_VERSION_CHECKED, 0, 0);
            end;
      except
         on E: Exception do
            begin
            logger.Error('[CTYUpdate] Version check failed: %s', [E.Message]);
            PostMessage(FNotifyWnd, WM_CTY_VERSION_CHECKED, 0, 0);
            end;
      end;
   finally
      http.Free;
      ssl.Free;
   end;
end;

// ---------------------------------------------------------------------------
// Download thread
// ---------------------------------------------------------------------------

type
   TCTYDownloadThread = class(TThread)
   private
      FTargetFile: string;
      FNotifyWnd:  HWND;
   protected
      procedure Execute; override;
   public
      constructor Create(const ATargetFile: string; ANotifyWnd: HWND);
   end;

constructor TCTYDownloadThread.Create(const ATargetFile: string;
   ANotifyWnd: HWND);
begin
   inherited Create(True);  // suspended; caller calls Resume
   FTargetFile     := ATargetFile;
   FNotifyWnd      := ANotifyWnd;
   FreeOnTerminate := True;
end;

procedure TCTYDownloadThread.Execute;
begin
   if DownloadFileToPath(CTY_DOWNLOAD_URL, FTargetFile) then
      PostMessage(FNotifyWnd, WM_CTY_DOWNLOAD_DONE, 1, 0)
   else
      PostMessage(FNotifyWnd, WM_CTY_DOWNLOAD_DONE, 0, 0);
end;

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

procedure CheckCTYVersionAsync(ANotifyWnd: HWND);
var
   Thread: TCTYVersionCheckThread;
begin
   Thread := TCTYVersionCheckThread.Create(ANotifyWnd);
   Thread.Resume;
end;

procedure DownloadCTYAsync(const ATargetFile: string; ANotifyWnd: HWND);
var
   Thread: TCTYDownloadThread;
begin
   Thread := TCTYDownloadThread.Create(ATargetFile, ANotifyWnd);
   Thread.Resume;
end;

end.
