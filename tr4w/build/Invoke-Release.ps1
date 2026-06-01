#requires -Version 5.1
<#
.SYNOPSIS
  TR4W release prep + tag. Regenerates TRMASTER.DTA, refreshes CTY.DAT, bumps
  Version.pas, does a local compile, then commits and tags so CI builds the
  installers.

.DESCRIPTION
  Run on a Windows dev box (Windows PowerShell 5.1 -- same shell the CI runner
  uses, so anything that works here works there).

  Tagging  v<Version>-all  triggers .github/workflows/release.yml, which builds
  ENG + 7 language installers and runs the VirusTotal scan (~25 min). The CI
  "version-guard" requires the tag version (with 'v' and '-all' stripped) to
  EXACTLY equal Version.pas TR4W_CURRENTVERSION_NUMBER -- this script keeps them
  in lockstep so the build can't fail on a version mismatch.

  Order (each step aborts on failure):
    preconditions -> CHANGES check -> TRMASTER regen+validate -> CTY download+
    validate -> Version.pas bump -> LOCAL build -> confirm -> commit -> push
    master -> tag -> push tag.

.PARAMETER Version
  Release version, e.g. 4.147.25  (no leading 'v', no '-all').

.PARAMETER CtyUrl
  URL of the current CTY.DAT. Default points at AD1C / country-files.com --
  VERIFY this is the variant you ship before relying on it.

.PARAMETER EnglishOnly
  Tag without '-all' (ENG-only build). Default is all languages.

.PARAMETER SkipTrmaster
  Don't regenerate TRMASTER.DTA; ship whatever is already in target\.

.PARAMETER SkipCty
  Don't download CTY.DAT; ship whatever is already in target\.

.PARAMETER DryRun
  Do everything locally (regen, download, bump, build) but DO NOT commit, tag,
  or push. Use this to rehearse a release.

.PARAMETER Yes
  Skip the final confirmation prompt before the irreversible commit/tag/push.

.EXAMPLE
  .\Invoke-Release.ps1 -Version 4.147.25
.EXAMPLE
  .\Invoke-Release.ps1 -Version 4.147.25 -DryRun
#>
[CmdletBinding()]
param(
   [Parameter(Mandatory = $true)][string] $Version,
   [string] $CtyUrl = 'https://www.country-files.com/cty/cty.dat',   # from uCTYUpdate.pas CTY_DOWNLOAD_URL (the app's Alt-O fetch)
   [switch] $EnglishOnly,
   [switch] $SkipTrmaster,
   [switch] $SkipCty,
   [switch] $DryRun,
   [switch] $Yes
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Paths (script lives in tr4w\build, so repo root is two levels up)
# ---------------------------------------------------------------------------
$RepoRoot    = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$TrDir       = Join-Path $RepoRoot 'tr4w'
$Target      = Join-Path $TrDir 'target'
$VersionPas  = Join-Path $TrDir 'src\Version.pas'
$FullBuild   = Join-Path $TrDir 'FullBuild.ps1'
$TrmasterDir = Join-Path $TrDir 'tools\trmaster'
$Changes     = Join-Path $RepoRoot 'CHANGES.md'
$RelNotes    = Join-Path $RepoRoot 'RELEASE_NOTES.md'
$CtyFile     = Join-Path $Target 'cty.dat'
$TrmasterFile= Join-Path $Target 'TRMASTER.DTA'

# We CALL the existing build_trmaster.cmd (no duplicated logic). It takes no args,
# writes TRMASTER.DTA in its own dir (OUT=TRMASTER.DTA), returns exit 0/1, and
# deliberately does NOT deploy to target\ -- that copy is this script's job.
$TrmasterBuildCmd = Join-Path $TrmasterDir 'build_trmaster.cmd'
$TrmasterOutput   = Join-Path $TrmasterDir 'TRMASTER.DTA'
$TrmasterCodec    = Join-Path $TrmasterDir 'trmaster_codec.py'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Step([string] $m) { Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Info([string] $m) { Write-Host "    $m" }
function Warn([string] $m) { Write-Host "WARNING: $m" -ForegroundColor Yellow }
function Fail([string] $m) { Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }

# NOTE: invoke the binary as 'git.exe', never bare 'git'. PowerShell command
# resolution is case-insensitive and functions outrank external executables, so
# inside a function named 'Git' a bare '& git' resolves back to THIS function ->
# infinite recursion -> "call depth overflow". '.exe' forces the application.
# git that must succeed
function Git { & git.exe -C $RepoRoot @args; if ($LASTEXITCODE -ne 0) { Fail "git $($args -join ' ') failed (exit $LASTEXITCODE)" } }
# git whose exit code we inspect ourselves
function GitTry { & git.exe -C $RepoRoot @args 2>$null; return $LASTEXITCODE }

# ---------------------------------------------------------------------------
# 0. Validate inputs / compute tag
# ---------------------------------------------------------------------------
Step "Validate"
if ($Version -notmatch '^\d+\.\d+\.\d+$') { Fail "Version '$Version' must look like 4.147.25 (no 'v', no '-all')." }
$suffix = '-all'; if ($EnglishOnly) { $suffix = '' }
$Tag = "v$Version$suffix"
$DateStr = (Get-Date -Format 'MMMM, yyyy')   # e.g. "May, 2026"
Info "Version : $Version"
Info "Tag     : $Tag    (CI: $(if ($EnglishOnly) {'ENG only'} else {'ENG + 7 languages'}))"
Info "Date    : $DateStr"
Info "DryRun  : $DryRun"

foreach ($p in @($VersionPas, $FullBuild)) { if (-not (Test-Path $p)) { Fail "Not found: $p (run from a TR4W checkout)" } }

# ---------------------------------------------------------------------------
# 1. Git preconditions: on master, clean-ish, current, tag is free
# ---------------------------------------------------------------------------
Step "Git preconditions"
$branch = (& git.exe -C $RepoRoot rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne 'master') { Fail "On branch '$branch'; releases are tagged from master. Checkout master first." }

# Pull so we don't tag a stale tree
Git fetch origin master
$behind = (& git.exe -C $RepoRoot rev-list --count 'HEAD..origin/master').Trim()
if ($behind -ne '0') { Git merge --ff-only origin/master }

# Tag must not already exist (local or remote)
if ((GitTry rev-parse -q --verify "refs/tags/$Tag") -eq 0) { Fail "Tag $Tag already exists locally. Bump the version or delete the tag." }
if ((& git.exe -C $RepoRoot ls-remote --tags origin "$Tag") ) { Fail "Tag $Tag already exists on origin." }

# Warn on unexpected dirty files (the data files are expected to change; flag anything else)
$dirty = (& git.exe -C $RepoRoot status --porcelain) | Where-Object {
   $_ -and ($_ -notmatch 'target/cty\.dat') -and ($_ -notmatch 'target/TRMASTER\.DTA') -and ($_ -notmatch 'src/Version\.pas')
}
if ($dirty) {
   Warn "Working tree has changes beyond the release data files:"
   $dirty | ForEach-Object { Write-Host "      $_" }
   if (-not $Yes) { $a = Read-Host "Continue anyway? (y/N)"; if ($a -ne 'y') { Fail "Aborted by user." } }
}

# ---------------------------------------------------------------------------
# 2. CHANGES.md / RELEASE_NOTES.md must mention this version (version-guard / no gaps)
# ---------------------------------------------------------------------------
Step "Changelog check"
foreach ($f in @($Changes, $RelNotes)) {
   if (-not (Test-Path $f)) { Warn "$f not found -- skipping check"; continue }
   if (-not (Select-String -Path $f -SimpleMatch $Version -Quiet)) {
      Warn "$([IO.Path]::GetFileName($f)) does not mention $Version. CI/version-guard may require it, and 'no version gaps' is the convention."
      if (-not $Yes) { $a = Read-Host "Continue without updating it? (y/N)"; if ($a -ne 'y') { Fail "Aborted -- update the changelog first (/update-changes)." } }
   } else { Info "$([IO.Path]::GetFileName($f)): mentions $Version OK" }
}

# ---------------------------------------------------------------------------
# 3. Regenerate + validate TRMASTER.DTA, copy into target\
# ---------------------------------------------------------------------------
if (-not $SkipTrmaster) {
   Step "TRMASTER.DTA regenerate"
   if (-not (Test-Path $TrmasterBuildCmd)) { Fail "Not found: $TrmasterBuildCmd (or pass -SkipTrmaster)" }
   Push-Location $TrmasterDir
   & cmd /c $TrmasterBuildCmd
   $rc = $LASTEXITCODE
   Pop-Location
   if ($rc -ne 0) { Fail "build_trmaster.cmd failed (exit $rc). It needs: the curated seed (tools\trmaster\seed\TRMASTER_seed.DTA), internet (SCP.DB + MASTER.DTA + CWops downloads), and -- for name backfill -- QRZ creds (~/qrz_settings.cfg)." }
   if (-not (Test-Path $TrmasterOutput)) { Fail "Expected output not found: $TrmasterOutput (verify the path at top of this script)." }

   Info "Validating with the codec (round-trip + end-offset)..."
   & python $TrmasterCodec $TrmasterOutput
   if ($LASTEXITCODE -ne 0) { Fail "TRMASTER codec self-test FAILED -- regenerated file is bad; not shipping it." }

   if (Test-Path $TrmasterFile) { Copy-Item $TrmasterFile "$TrmasterFile.bak" -Force }
   Copy-Item $TrmasterOutput $TrmasterFile -Force
   Info "Copied regenerated TRMASTER.DTA into target\ ($((Get-Item $TrmasterFile).Length) bytes)"
} else { Step "TRMASTER.DTA (skipped -- using existing target\ copy)" }

# ---------------------------------------------------------------------------
# 4. Download + validate CTY.DAT into target\
# ---------------------------------------------------------------------------
if (-not $SkipCty) {
   Step "CTY.DAT download"
   $tmp = Join-Path $env:TEMP "cty_dl_$([guid]::NewGuid().ToString('N')).dat"
   Info "GET $CtyUrl   (UA 'TR4W', TLS, follow redirects -- same as the app's Alt-O fetch)"
   & curl.exe -fsSL -A 'TR4W' -o $tmp $CtyUrl   # -A 'TR4W' matches uCTYUpdate.pas http.Request.UserAgent
   if ($LASTEXITCODE -ne 0) { Fail "CTY.DAT download failed (curl exit $LASTEXITCODE). Check the URL / connectivity." }
   $len = (Get-Item $tmp).Length
   if ($len -lt 50000) { Fail "Downloaded CTY.DAT is only $len bytes -- looks truncated/wrong; not shipping it." }
   # Validate the same way the app does: a real CTY.DAT carries a VER<YYYYMMDD> marker (uCTYUpdate.ParseVERDate).
   $verMatch = Select-String -Path $tmp -Pattern 'VER(\d{8})' | Select-Object -First 1
   if (-not $verMatch) { Fail "Downloaded file has no VER<date> marker -- not a valid CTY.DAT; aborting." }
   $verDate = $verMatch.Matches[0].Groups[1].Value
   Info "Downloaded OK ($len bytes, VER$verDate)"
   if (Test-Path $CtyFile) { Copy-Item $CtyFile "$CtyFile.bak" -Force }
   Copy-Item $tmp $CtyFile -Force
   Remove-Item $tmp -Force
} else { Step "CTY.DAT (skipped -- using existing target\ copy)" }

# ---------------------------------------------------------------------------
# 5. Bump Version.pas (number + date), preserving formatting
# ---------------------------------------------------------------------------
Step "Version.pas"
$vtxt = [System.IO.File]::ReadAllText($VersionPas)
$vtxt = [regex]::Replace($vtxt, "(TR4W_CURRENTVERSION_NUMBER\s*=\s*')[^']*(')", "`${1}$Version`${2}")
$vtxt = [regex]::Replace($vtxt, "(TR4W_CURRENTVERSIONDATE\s*=\s*')[^']*(')", "`${1}$DateStr`${2}")
[System.IO.File]::WriteAllText($VersionPas, $vtxt, (New-Object System.Text.UTF8Encoding($false)))
# verify it took
if (-not (Select-String -Path $VersionPas -SimpleMatch "'$Version'" -Quiet)) { Fail "Version.pas did not update to $Version -- check the constant format." }
Info "TR4W_CURRENTVERSION_NUMBER = '$Version'  /  TR4W_CURRENTVERSIONDATE = '$DateStr'"

# ---------------------------------------------------------------------------
# 6. LOCAL build BEFORE tagging (don't burn a full CI run on a compile error)
# ---------------------------------------------------------------------------
Step "Local build (FullBuild.ps1)"
Push-Location $TrDir
& powershell.exe -ExecutionPolicy Bypass -File $FullBuild
$bc = $LASTEXITCODE
Pop-Location
if ($bc -ne 0) { Fail "Local build FAILED (exit $bc). Fix before releasing -- not committing or tagging." }
Info "Local build OK."

# ---------------------------------------------------------------------------
# 7. Confirm the irreversible part
# ---------------------------------------------------------------------------
if ($DryRun) {
   Step "DRY RUN complete"
   Info "Prepared $Version locally (TRMASTER, CTY, Version.pas, build all OK)."
   Info "NOT committing/tagging/pushing. Re-run without -DryRun to release."
   exit 0
}
Step "Ready to release"
Info "Will commit Version.pas + cty.dat + TRMASTER.DTA (+ changelogs if changed),"
Info "push master, tag $Tag, and push the tag (this triggers the CI installer build)."
if (-not $Yes) { $a = Read-Host "Proceed with commit/tag/push? (y/N)"; if ($a -ne 'y') { Fail "Aborted by user (nothing committed)." } }

# ---------------------------------------------------------------------------
# 8. Commit (force-add the gitignored/skip-worktree data files), push, tag, push
# ---------------------------------------------------------------------------
Step "Commit + tag + push"
# Version.pas + changelogs: normal add
Git add $VersionPas
if (Test-Path $Changes)  { Git add $Changes }
if (Test-Path $RelNotes) { Git add $RelNotes }
# Data files: clear skip-worktree (if set) then force past the target/* gitignore
foreach ($df in @($CtyFile, $TrmasterFile)) {
   & git.exe -C $RepoRoot update-index --no-skip-worktree $df 2>$null   # ok if it wasn't set
   Git add -f $df
}

$commitMsg = "Release $Version`n`nVersion.pas -> $Version ($DateStr); refreshed CTY.DAT and TRMASTER.DTA. Tag $Tag triggers the CI installer build."
Git commit -m $commitMsg
Git push origin master
Git tag -a $Tag -m "TR4W $Version"
Git push origin $Tag

# Re-apply skip-worktree so day-to-day runtime rewrites stay out of git status
foreach ($df in @($CtyFile, $TrmasterFile)) { & git.exe -C $RepoRoot update-index --skip-worktree $df 2>$null }

Step "Done"
Info "Pushed master + tag $Tag. CI is building now:"
Info "  https://github.com/n4af/TR4W/actions"
Info "Watch for the version-guard + VirusTotal steps; the Release appears when the build finishes."
