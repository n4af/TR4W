param(
    # When set, after the default ENG build, loop through every other
    # supported LANG_xxx (RUS, SER, MNG, CZE, ROM, GER, UKR) and rebuild
    # against each. Excludes POL/CHN (broken constants, issue #925).
    [switch]$AllLanguages,

    # When set, run UPX --lzma + makensis after each (ENG + per-lang) build
    # to produce a per-language installer in tr4w\build\release\:
    #   tr4w_setup_<version>.exe        (ENG -- no suffix)
    #   tr4w_setup_<version>_<lang>.exe (lowercase lang code per full.nsi)
    # This is the historical packaging Howie used to ship and what the CI
    # release workflow produces.
    [switch]$BuildInstallers,

    # Repo root. Defaults to one level above this script -- works for any
    # checkout location (e.g. C:\TR4W or D:\newsrc\TR4W) with zero config.
    # Override for CI / scripted invocations.
    [string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent),

    # Delphi 7 bin directory (contains DCC32.EXE). One-time per-machine
    # setting -- set $env:DELPHI7_BIN if your install differs from the
    # default below, or pass -Delphi7Bin explicitly.
    [string]$Delphi7Bin = $(if ($env:DELPHI7_BIN) { $env:DELPHI7_BIN } else { "C:\Program Files (x86)\Borland\Delphi7\Bin" }),

    # Indy 10 Lib root (the directory containing Core / System / Protocols
    # subdirs). Resolution order:
    #   1. -IndyRoot <path> command-line arg (highest precedence)
    #   2. $env:INDY_ROOT environment variable
    #   3. Bundled Indy at tr4w\include (default -- no external install needed)
    # The bundled tree is Indy 10.6.3.3, byte-identical to upstream's 10.6.3.3
    # tag for the units TR4W actually compiles against. See
    # [[todo_indy_refresh_with_delphi12]] for the planned upgrade path.
    [string]$IndyRoot = $(if ($env:INDY_ROOT) { $env:INDY_ROOT } else { Join-Path $PSScriptRoot "include" }),

    # NSIS install dir (contains makensis.exe). Only consulted when
    # -BuildInstallers is set. Override with $env:NSIS_BIN or -NSISBin.
    [string]$NSISBin = $(if ($env:NSIS_BIN) { $env:NSIS_BIN } else { "C:\Program Files (x86)\NSIS" }),

    # UPX bin directory (contains upx.exe). Only consulted when both
    # -BuildInstallers AND -UseUpx are set. Resolution order:
    #   1. -UpxBin / $env:UPX_BIN explicit directory (validated below)
    #   2. PATH lookup via Get-Command upx.exe (default if neither set)
    [string]$UpxBin = $(if ($env:UPX_BIN) { $env:UPX_BIN } else { "" }),

    # When set (and -BuildInstallers is also set), run upx --lzma on
    # tr4w.exe before passing it to NSIS.  UPX is opt-in as of 2026-05-28
    # because the on-disk savings (~1 MB exe / ~2 MB installer) no longer
    # outweigh the AV false-positive cost on operator machines.  A
    # comparison VirusTotal scan of a no-UPX SER installer (tag
    # v4.147.21-all) dropped flags from 8+ to 3, with Microsoft Defender
    # leaving the flag list.  Setting -UseUpx restores the historical
    # packaging if a future need arises (e.g. distribution to operators
    # on tightly bandwidth-constrained connections).
    [switch]$UseUpx
)

$ErrorActionPreference = "Continue"

# All other paths derive from ProjectRoot / Delphi7Bin / IndyRoot above.
$TR4W_DIR      = Join-Path $ProjectRoot "tr4w"
$SRC_DIR       = Join-Path $TR4W_DIR    "src"
$EXE_DIR       = Join-Path $TR4W_DIR    "target"
$DIST_DIR      = Join-Path $EXE_DIR     "dist"
$LANG_OUT      = Join-Path $DIST_DIR    "lang-test"
$DCU_CACHE_DIR = Join-Path $EXE_DIR     "dcu-cache"
$TEST_DIR      = Join-Path $TR4W_DIR    "test\unit"
$TEST_DPR      = Join-Path $TEST_DIR    "tr4w_unit_tests.dpr"
$TEST_DCU_DIR  = Join-Path $env:TEMP    "tr4w-test"
$SERVER_PS1    = Join-Path $TR4W_DIR    "tr4wserver\BuildServer.ps1"
$VERSION_PAS   = Join-Path $SRC_DIR     "Version.pas"
$PROJECT       = Join-Path $TR4W_DIR    "tr4w.dpr"
$DCC32         = Join-Path $Delphi7Bin  "DCC32.EXE"
$LIB           = "$IndyRoot\Core;$IndyRoot\System;$TR4W_DIR\include;$IndyRoot\Protocols"
# Installer paths (only used when -BuildInstallers is set).
$BUILD_DIR     = Join-Path $TR4W_DIR    "build"
$NSI_FILE      = Join-Path $BUILD_DIR   "full.nsi"
$RELEASE_DIR   = Join-Path $BUILD_DIR   "release"
$MAKENSIS      = Join-Path $NSISBin     "makensis.exe"

# Validate the toolchain paths up front so a typo in env vars / params
# fails loudly instead of in the middle of a 15-minute build.
if (-not (Test-Path $DCC32))    { Write-Host "DCC32.EXE not found at: $DCC32" -ForegroundColor Red; exit 2 }
if (-not (Test-Path $IndyRoot)) { Write-Host "Indy lib root not found at: $IndyRoot" -ForegroundColor Red; exit 2 }
if (-not (Test-Path $TR4W_DIR)) { Write-Host "tr4w project dir not found at: $TR4W_DIR" -ForegroundColor Red; exit 2 }
if ($BuildInstallers) {
    if (-not (Test-Path $MAKENSIS)) { Write-Host "makensis.exe not found at: $MAKENSIS (set NSIS_BIN or pass -NSISBin)" -ForegroundColor Red; exit 2 }
    if (-not (Test-Path $NSI_FILE)) { Write-Host "Installer script not found at: $NSI_FILE" -ForegroundColor Red; exit 2 }

    # UPX is opt-in (see -UseUpx param doc).  Only resolve upx.exe when the
    # operator asked for it; default builds skip the resolution entirely so
    # a missing/uninstalled UPX is not a build blocker.
    $UPX = $null
    if ($UseUpx) {
        # Resolve upx.exe -- explicit override (-UpxBin / $env:UPX_BIN) wins;
        # otherwise discover via PATH. Either way we end up with a full path
        # in $UPX so the packaging step doesn't depend on PATH at call time.
        if ($UpxBin) {
            $UPX = Join-Path $UpxBin "upx.exe"
            if (-not (Test-Path $UPX)) {
                Write-Host "upx.exe not found at: $UPX" -ForegroundColor Red
                Write-Host "Check the -UpxBin parameter or `$env:UPX_BIN value." -ForegroundColor Red
                exit 2
            }
        } else {
            $upxCmd = Get-Command upx.exe -ErrorAction SilentlyContinue
            if ($upxCmd) {
                $UPX = $upxCmd.Source
            } else {
                Write-Host "upx.exe not found (required by -UseUpx)." -ForegroundColor Red
                Write-Host ""
                Write-Host "Fix one of these ways:" -ForegroundColor Yellow
                Write-Host "  1. Pass -UpxBin <directory-containing-upx.exe> on the command line, OR" -ForegroundColor Yellow
                Write-Host "  2. Set the UPX_BIN environment variable to that directory (persists), OR" -ForegroundColor Yellow
                Write-Host "  3. Add the directory containing upx.exe to your PATH and reopen the shell, OR" -ForegroundColor Yellow
                Write-Host "  4. Drop -UseUpx to build without UPX (the default since 2026-05-28)." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Download UPX from https://upx.github.io/ if you do want to use it." -ForegroundColor Yellow
                exit 2
            }
        }
        Write-Host "Using upx: $UPX" -ForegroundColor DarkGray
    } else {
        Write-Host "UPX disabled (default). Pass -UseUpx to enable upx --lzma compression." -ForegroundColor DarkGray
    }
}

# DCU cache architecture (used when -AllLanguages is set):
#   src\*.dcu     -- canonical ENG state. Written by Step 2 (main build).
#                    Never touched by the lang loop. The Delphi 7 IDE
#                    reads/writes DCUs here by default, so leaving src\
#                    pristine means the IDE doesn't have to rebuild
#                    after a script build.
#   dcu-cache\<lang>\
#                 -- per-language DCU cache. The lang loop passes
#                    /N$DCU_CACHE_DIR\<lang> to DCC32 so DCC32 writes
#                    that language's DCUs there, leaving src\ alone.
# First lang build (cache empty): -B forces a full recompile so DCC32
# doesn't accidentally use the ENG DCUs that exist in src\ via the -U
# search path. Subsequent runs read the lang's own cache first (DCC32
# /N takes search precedence over -U), so -B is unnecessary.

function Clear-SrcDcus {
    Get-ChildItem -Path $SRC_DIR -Filter *.dcu -Recurse -File `
        | Remove-Item -Force -ErrorAction SilentlyContinue
}

# Generate tr4w_versioninfo.rc + .res with the right language LANGID and
# the current Version.pas number embedded. Picked up by DCC32 via the
# {$R tr4w_versioninfo.res} directive in tr4w.dpr (gated on the
# VERSIONINFO_RES compiler symbol passed by the build script).
#
# The Windows Properties dialog reads this resource for File version /
# Product name / Language / Copyright fields. Without this resource the
# fields are blank (the historical Delphi 7 default, IncludeVerInfo=0
# in tr4w.dof).
#
# String values are English everywhere (operator confirmed -- only the
# Language field needs to vary per build).
function Write-VersionInfoResource {
    param(
        [Parameter(Mandatory=$true)][string]$Lang,
        [Parameter(Mandatory=$true)][string]$VersionString
    )

    # Parse "4.147.19" into 4 numeric parts; pad with 0 to make it
    # WORD-sized 4-tuple that VERSIONINFO requires.
    $parts = @($VersionString.Split('.'))
    while ($parts.Count -lt 4) { $parts += '0' }
    $major    = [int]$parts[0]
    $minor    = [int]$parts[1]
    $build    = [int]$parts[2]
    $revision = [int]$parts[3]

    # LANGID (Windows locale) + ANSI code page per supported language.
    # Format used by VERSIONINFO's StringFileInfo block name and the
    # VarFileInfo / Translation pair. CP1252 = Western Latin-1,
    # CP1251 = Cyrillic, CP1250 = Central European.
    $langMap = @{
        'ENG' = @{ LangId = 0x0409; CodePage = 1252; Name = 'English (United States)' }
        'RUS' = @{ LangId = 0x0419; CodePage = 1251; Name = 'Russian' }
        'GER' = @{ LangId = 0x0407; CodePage = 1252; Name = 'German' }
        'CZE' = @{ LangId = 0x0405; CodePage = 1250; Name = 'Czech' }
        'ROM' = @{ LangId = 0x0418; CodePage = 1250; Name = 'Romanian' }
        'UKR' = @{ LangId = 0x0422; CodePage = 1251; Name = 'Ukrainian' }
        'SER' = @{ LangId = 0x081A; CodePage = 1251; Name = 'Serbian (Latin)' }
        'MNG' = @{ LangId = 0x0450; CodePage = 1251; Name = 'Mongolian (Cyrillic)' }
    }
    $info = $langMap[$Lang.ToUpper()]
    if (-not $info) {
        Write-Host "    No VERSIONINFO LANGID mapping for '$Lang' -- defaulting to ENG" -ForegroundColor Yellow
        $info = $langMap['ENG']
        $Lang = 'ENG'
    }

    # StringFileInfo block name = 8 hex chars: LANGID (4) + codepage (4).
    $blockName = '{0:X4}{1:X4}' -f $info.LangId, $info.CodePage

    $rc = @"
// AUTO-GENERATED by FullBuild.ps1 (Write-VersionInfoResource).
// Do not edit by hand; regenerated on every build. Gitignored.

1 VERSIONINFO
 FILEVERSION $major,$minor,$build,$revision
 PRODUCTVERSION $major,$minor,$build,$revision
 FILEOS 0x40004L
 FILETYPE 0x1L
{
 BLOCK "StringFileInfo"
 {
  BLOCK "$blockName"
  {
   VALUE "CompanyName",      "TR4W Project (n4af / ny4i)\0"
   VALUE "FileDescription",  "TR4W (TRLOG 4 Windows) Contest Logging Application\0"
   VALUE "FileVersion",      "$major.$minor.$build.$revision\0"
   VALUE "InternalName",     "tr4w\0"
   VALUE "LegalCopyright",   "Free software under GNU GPL v2 or later\0"
   VALUE "OriginalFilename", "tr4w.exe\0"
   VALUE "ProductName",      "TR4W\0"
   VALUE "ProductVersion",   "$major.$minor.$build\0"
   VALUE "Comments",         "Language build: $Lang ($($info.Name))\0"
  }
 }
 BLOCK "VarFileInfo"
 {
  VALUE "Translation", 0x$('{0:X4}' -f $info.LangId), $($info.CodePage)
 }
}
"@

    $rcPath  = Join-Path $TR4W_DIR "tr4w_versioninfo.rc"
    $resPath = Join-Path $TR4W_DIR "tr4w_versioninfo.res"
    Set-Content -Path $rcPath -Value $rc -Encoding ASCII

    $brcc32 = Join-Path $Delphi7Bin "brcc32.exe"
    if (-not (Test-Path $brcc32)) {
        Write-Host "    brcc32.exe not found at $brcc32 -- VERSIONINFO will be blank in this build" -ForegroundColor Yellow
        return $false
    }

    # brcc32 wants -fo<filename> with no space. PowerShell's argument
    # parser splits on the dot in "-fotr4w_versioninfo.res", leaving
    # brcc32 to complain "Could not open input file .res". Use the
    # stop-parsing token --% so PowerShell passes the args verbatim.
    Push-Location $TR4W_DIR
    # Pre-delete stale output so a brcc32 failure can't be masked by a
    # leftover .res from a previous successful run.
    if (Test-Path $resPath) { Remove-Item $resPath -Force }
    & $brcc32 --% -fotr4w_versioninfo.res tr4w_versioninfo.rc | Out-Null
    $rc = $LASTEXITCODE
    Pop-Location

    if ($rc -ne 0 -or -not (Test-Path $resPath)) {
        Write-Host "    brcc32 failed (exit $rc) -- VERSIONINFO will be blank in this build" -ForegroundColor Yellow
        return $false
    }
    return $true
}

# Pre-flight check: every "File <path>" directive in full.nsi resolves
# to an existing file on disk. Called before UPX + makensis so we never
# spend time compressing / packaging when we already know a required
# DLL or data file is missing.
#
# Skips lines with NSIS macros (${TR4WLANG} etc.) -- those are rare and
# substituting them here duplicates makensis logic; if a macro path is
# wrong it will surface as a makensis error a few seconds later.
#
# Lines using "File /flag <path>" (e.g. /nonfatal, /r) are skipped --
# /nonfatal means missing is intentionally tolerated, /r is recursive
# wildcard. Both forms are uncommon in TR4W's full.nsi and the operator
# wrote them knowing the looser semantics.
#
# Returns $true on success, $false with a printed list on any miss.
function Test-InstallerDependencies {
    param([Parameter(Mandatory=$true)][string]$NsiPath)

    if (-not (Test-Path $NsiPath)) {
        Write-Host "  NSI script not found: $NsiPath" -ForegroundColor Red
        return $false
    }

    $nsiDir = Split-Path $NsiPath -Parent
    $missing = New-Object System.Collections.ArrayList
    $checked = 0
    $skippedMacro = 0
    $skippedFlag  = 0

    foreach ($line in Get-Content $NsiPath) {
        # Plain "File <path>" with no flags. Trailing ;comments stripped.
        $m = [regex]::Match($line, '^\s*File\s+(.+?)\s*(?:;.*)?$')
        if (-not $m.Success) { continue }
        $arg = $m.Groups[1].Value.Trim()
        if ($arg.StartsWith('/')) { $skippedFlag++; continue }

        $path = $arg.Trim('"')
        if ($path -match '\$\{') { $skippedMacro++; continue }

        if (-not [System.IO.Path]::IsPathRooted($path)) {
            $path = Join-Path $nsiDir $path
        }
        $checked++

        if (-not (Test-Path -LiteralPath $path)) {
            [void]$missing.Add($path)
        }
    }

    Write-Host "  Verified $checked installer source file(s); skipped $skippedMacro macro / $skippedFlag flag-form line(s)." -ForegroundColor DarkGray
    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host "  $($missing.Count) MISSING installer source file(s):" -ForegroundColor Red
        foreach ($f in $missing) { Write-Host "    $f" -ForegroundColor Red }
        Write-Host ""
        Write-Host "  Likely cause: target\ is not fully populated. Run Build.cmd first to" -ForegroundColor Red
        Write-Host "  produce tr4w.exe, and ensure runtime files (HamLib DLLs, OpenSSL DLLs," -ForegroundColor Red
        Write-Host "  cty.dat, TRMASTER.DTA, dom\*.dom etc.) are present in tr4w\target\." -ForegroundColor Red
        return $false
    }

    return $true
}

# VirusTotal scan logic is shared with the CI release pipeline -- the single
# source of truth lives in .github/scripts/Invoke-VirusTotalScan.ps1. Dot-
# source it to load Invoke-VirusTotalScan (curl-based upload + poll, returns
# the analysis object or $null), ConvertTo-VtResult, and Get-VtVerdict. That
# script no-ops when dot-sourced; it only runs a scan when invoked directly
# (the CI release job does that). $ProjectRoot is one level above tr4w\ (see
# the param block), so the shared script sits at <root>\.github\scripts\.
. (Join-Path $ProjectRoot '.github\scripts\Invoke-VirusTotalScan.ps1')

# Helper: UPX + makensis for the exe currently in target\tr4w.exe.
# Pass empty $langCode for the no-suffix ENG installer, or the lowercase
# language code ('rus', 'cze', etc.) for tagged installers per full.nsi.
function Invoke-Packaging {
    param(
        [Parameter(Mandatory=$true)][string]$Version,
        [string]$LangCode = ""
    )
    $tagDisplay = if ($LangCode) { $LangCode.ToUpper() } else { "ENG (no suffix)" }
    Write-Host ""
    Write-Host "--- Packaging installer ($tagDisplay) ---" -ForegroundColor Cyan

    $exe = Join-Path $EXE_DIR "tr4w.exe"
    if (-not (Test-Path $exe)) {
        Write-Host "  $exe not present -- skipping packaging" -ForegroundColor Red
        return $false
    }

    # Pre-flight: every runtime file the NSIS script bundles must exist
    # on disk BEFORE we spend time UPX-compressing tr4w.exe (which is
    # destructive) and invoking makensis. Latent defect protector: a
    # missing HamLib / OpenSSL DLL gets a clear up-front error instead
    # of producing an installer that's quietly missing those files.
    # Hard-fails the whole script -- if a runtime DLL is missing for
    # ENG, it'll be missing for every other language too.
    Write-Host "  Verifying installer source files..." -ForegroundColor DarkGray
    if (-not (Test-InstallerDependencies -NsiPath $NSI_FILE)) {
        Write-Host ""
        Write-Host "=== INSTALLER DEPENDENCY CHECK FAILED -- aborting build ===" -ForegroundColor Red
        exit 3
    }

    New-Item -ItemType Directory -Force -Path $RELEASE_DIR | Out-Null

    # UPX --lzma (destructive: overwrites the exe with the compressed copy).
    # Opt-in (-UseUpx); skipped by default since 2026-05-28 because the AV
    # false-positive cost on operator machines outweighs the ~1 MB savings.
    if ($UseUpx) {
        Write-Host "  upx --lzma $exe" -ForegroundColor DarkGray
        & $UPX $exe --lzma | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Host "  UPX failed (exit $LASTEXITCODE)" -ForegroundColor Red; return $false }
    } else {
        Write-Host "  Skipping UPX (default since 2026-05-28; -UseUpx restores)" -ForegroundColor DarkGray
    }

    $nsisArgs = @("/DTR4WVERSION=$Version")
    if ($LangCode) { $nsisArgs += "/DTR4WLANG=$LangCode" }
    $nsisArgs += $NSI_FILE

    Push-Location $BUILD_DIR
    & $MAKENSIS @nsisArgs | Out-Null
    $nsisRc = $LASTEXITCODE
    Pop-Location
    if ($nsisRc -ne 0) { Write-Host "  makensis failed (exit $nsisRc)" -ForegroundColor Red; return $false }

    $installerName = if ($LangCode) { "tr4w_setup_${Version}_${LangCode}.exe" } else { "tr4w_setup_${Version}.exe" }
    $installerPath = Join-Path $RELEASE_DIR $installerName
    if (-not (Test-Path $installerPath)) {
        Write-Host "  Expected installer not found at $installerPath" -ForegroundColor Red
        return $false
    }
    $sz = (Get-Item $installerPath).Length
    Write-Host "  Installer: $installerPath ($sz bytes)" -ForegroundColor Green
    return $true
}

# ---------------------------------------------------------------------------
# Step 1: Compile and run unit tests.
# Tests have no Indy/Log4D dependencies — compile without those library paths.
# Exit codes: 0 = all pass, 1 = one or more failures (also fails to compile).
# ---------------------------------------------------------------------------

Write-Host "=== Compiling Unit Tests ===" -ForegroundColor Cyan
Write-Host ""

New-Item -ItemType Directory -Force -Path $TEST_DCU_DIR | Out-Null

Push-Location $TEST_DIR
# /U includes src\ so VC.pas (and Log4D.dcu within it) resolve correctly
& $DCC32 $TEST_DPR -`$D+ -`$L+ -`$Y+ "-N$TEST_DCU_DIR" "/E$TEST_DIR" "/U$SRC_DIR"
$testBuildResult = $LASTEXITCODE
Pop-Location

if ($testBuildResult -ne 0) {
    Write-Host ""
    Write-Host "=== UNIT TEST BUILD FAILED ===" -ForegroundColor Red
    Write-Host "Fix compiler errors in the test project before rebuilding." -ForegroundColor Red
    exit $testBuildResult
}

Write-Host ""
Write-Host "=== Running Unit Tests ===" -ForegroundColor Cyan
Write-Host ""

& "$TEST_DIR\tr4w_unit_tests.exe"
$testRunResult = $LASTEXITCODE

Write-Host ""
if ($testRunResult -ne 0) {
    Write-Host "=== UNIT TESTS FAILED - main build aborted ===" -ForegroundColor Red
    Write-Host "All test failures must be fixed before the main application is built." -ForegroundColor Red
    exit $testRunResult
}

Write-Host "=== All unit tests passed ===" -ForegroundColor Green
Write-Host ""

# ---------------------------------------------------------------------------
# Step 2: Build main TR4W application.
# ---------------------------------------------------------------------------

Write-Host "=== Building TR4W Project ===" -ForegroundColor Cyan
Write-Host "Project: $PROJECT" -ForegroundColor Yellow
Write-Host "Output: $EXE_DIR" -ForegroundColor Yellow
Write-Host ""

# Parse TR4W_CURRENTVERSION_NUMBER once up front so Write-VersionInfoResource
# has a value for every DCC32 invocation. Used by both Step 2 (ENG build)
# and the per-language loop. Failure to parse falls back to "0.0.0" which
# still produces a valid VERSIONINFO record, just with no real version.
$versionLine = Select-String -Path $VERSION_PAS `
                              -Pattern "TR4W_CURRENTVERSION_NUMBER\s*=\s*'([^']+)'" `
                              | Select-Object -First 1
if ($versionLine -and $versionLine.Matches[0].Groups[1].Value) {
    $TR4W_VERSION = $versionLine.Matches[0].Groups[1].Value
} else {
    $TR4W_VERSION = "0.0.0"
    Write-Host "Could not parse TR4W_CURRENTVERSION_NUMBER; VERSIONINFO will use $TR4W_VERSION" -ForegroundColor Yellow
}

# ENG DCUs live canonically in src\ (where the Delphi 7 IDE expects
# them). The script never makes a separate ENG cache copy -- if you
# build with this script and then open the IDE, the IDE sees the same
# DCUs it would have built itself.
#
# Defensive check: an older version of this script left src\*.dcu in
# the LAST lang loop iteration's state (e.g. UKR). To migrate cleanly,
# we drop a marker file the first time the new script completes Step 2
# successfully. If the marker is missing, assume the DCUs in src\ are
# suspect and clear them so Step 2 builds ENG from scratch.
$DCU_MANAGED_MARKER = Join-Path $EXE_DIR ".dcu-managed-by-fullbuild"
if (-not (Test-Path $DCU_MANAGED_MARKER)) {
    Write-Host "First run under managed-DCU script -- clearing src\*.dcu for clean ENG build" -ForegroundColor DarkGray
    Clear-SrcDcus
}

# Generate the VERSIONINFO PE resource for ENG. DCC32 picks it up via
# {$R tr4w_versioninfo.res} in tr4w.dpr -- but only when the build is
# invoked with -DVERSIONINFO_RES (so the IDE compile still works without
# the file). If brcc32 fails or isn't available we drop the flag and
# build without VERSIONINFO -- same behaviour as historic builds (blank
# Properties dialog), no build failure.
Write-Host "Generating VERSIONINFO resource (ENG, $TR4W_VERSION)..." -ForegroundColor DarkGray
$viOk = Write-VersionInfoResource -Lang 'ENG' -VersionString $TR4W_VERSION
$viFlag = if ($viOk) { '-DVERSIONINFO_RES' } else { '' }

Push-Location $TR4W_DIR
if ($viFlag) {
    & $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ $viFlag "/U$LIB" "/I$LIB" "/E$EXE_DIR"
} else {
    & $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ "/U$LIB" "/I$LIB" "/E$EXE_DIR"
}
$result = $LASTEXITCODE
Pop-Location

Write-Host ""
if ($result -eq 0) {
    Write-Host "=== BUILD SUCCESSFUL ===" -ForegroundColor Green
    Write-Host ""

    # Check if exe was created
    if (Test-Path "$EXE_DIR\tr4w.exe") {
        $exeInfo = Get-Item "$EXE_DIR\tr4w.exe"
        Write-Host "TR4W.EXE Details:" -ForegroundColor Cyan
        Write-Host "  Path:     $($exeInfo.FullName)" -ForegroundColor White
        Write-Host "  Size:     $($exeInfo.Length) bytes" -ForegroundColor White
        Write-Host "  Modified: $($exeInfo.LastWriteTime)" -ForegroundColor White
        Write-Host "  Language: ENG (default -- no -DLANG_xxx)" -ForegroundColor White
        Write-Host ""

        # Drop the migration marker so future runs trust src\*.dcu as
        # the canonical ENG state without re-clearing.
        if (-not (Test-Path $DCU_MANAGED_MARKER)) {
            New-Item -ItemType Directory -Force -Path $EXE_DIR | Out-Null
            "" | Out-File -FilePath $DCU_MANAGED_MARKER -Encoding ascii
        }

        # ---------------------------------------------------------------
        # Step 2b: Build tr4wserver.exe (required by the NSIS installer).
        # ---------------------------------------------------------------
        & $SERVER_PS1 -ProjectRoot $ProjectRoot -Delphi7Bin $Delphi7Bin -IndyRoot $IndyRoot
        $serverResult = $LASTEXITCODE
        if ($serverResult -ne 0) {
            Write-Host "=== TR4W SERVER BUILD FAILED -- aborting ===" -ForegroundColor Red
            exit $serverResult
        }
        Write-Host ""

        # ---------------------------------------------------------------
        # Step 3 (optional): build the ENG installer (no language suffix).
        # UPX is destructive (overwrites tr4w.exe with the compressed copy)
        # so this is the last step that consumes target\tr4w.exe.
        # ---------------------------------------------------------------
        if ($BuildInstallers) {
            Invoke-Packaging -Version $TR4W_VERSION -LangCode "" | Out-Null
        }

        # ---------------------------------------------------------------
        # Step 4 (optional): build every non-English language variant.
        # Runs LAST -- after tr4wserver and zip have packaged the default
        # English build -- because each language iteration clears the
        # TR4W src DCUs and rewrites them under -DLANG_$lang. Nothing
        # downstream consumes target\tr4w.exe or src\*.dcu, so this loop
        # can leave them in whatever state the final language produced.
        #
        # Indy DCUs (compiled from the bundled include\ tree) stay cached
        # across iterations, which is the only way to keep per-language
        # builds under ~3 min each instead of ~3 min just for the Indy
        # rebuild alone.
        #
        # POL/CHN are excluded -- they each have many missing
        # constants tracked separately under issue #925.
        # (ESP was backfilled 2026-05-28 and is now in the matrix.)
        # ---------------------------------------------------------------
        if ($AllLanguages) {
            $langResults = @()
            $otherLangs = @("RUS","SER","MNG","CZE","ROM","GER","UKR","ESP")

            # Per-lang DCUs go to dcu-cache\<lang>\ via DCC32's /N flag.
            # src\*.dcu is the canonical ENG state and stays untouched
            # throughout the loop. On the FIRST build of a lang (cache
            # missing or empty) we add -B (build-all) so DCC32 ignores
            # the ENG DCUs in src\ that it would otherwise pick up via
            # the -U search path. On subsequent runs the lang's own
            # cache is populated and DCC32's /N-first read precedence
            # means it never falls through to src\.
            if (-not $BuildInstallers) {
                New-Item -ItemType Directory -Force -Path $LANG_OUT | Out-Null
            }

            foreach ($lang in $otherLangs) {
                Write-Host ""
                Write-Host "=== Building LANG_$lang ===" -ForegroundColor Cyan

                $langCache = Join-Path $DCU_CACHE_DIR $lang.ToLower()
                $cacheHasDcus = (Test-Path $langCache) -and `
                    ((Get-ChildItem -Path $langCache -Filter *.dcu -Recurse -ErrorAction SilentlyContinue).Count -gt 0)
                if (-not $cacheHasDcus) {
                    New-Item -ItemType Directory -Force -Path $langCache | Out-Null
                    Write-Host "  Cache empty -- forcing full rebuild (-B) so DCC32 ignores ENG DCUs in src\" -ForegroundColor DarkGray
                    $extraFlags = @("-B")
                } else {
                    Write-Host "  Cache populated -- incremental compile against $langCache" -ForegroundColor DarkGray
                    $extraFlags = @()
                }

                # Both modes write tr4w.exe to target\ (per tr4w.cfg -E"target").
                # Clear any stale target\tr4w.exe so failed builds don't look
                # successful by leaving a previous run's exe in place.
                $builtExe = Join-Path $EXE_DIR "tr4w.exe"
                if (Test-Path $builtExe) { Remove-Item $builtExe -Force }

                # Regenerate VERSIONINFO for this language so the Properties
                # dialog reports the correct LANGID (e.g. Russian for RUS).
                # Skip -DVERSIONINFO_RES if generation failed so DCC32 doesn't
                # fatal on the missing {$R} file. Inline conditional rather
                # than @viFlags splat: PowerShell mis-parses the splat when
                # combined with the other inline args here, splitting tokens
                # in a way DCC32 ultimately sees as a phantom "D.dpr" project.
                $viOk = Write-VersionInfoResource -Lang $lang -VersionString $TR4W_VERSION

                Write-Host "  DCC32 -DLANG_$lang /N$langCache -> $EXE_DIR\tr4w.exe" -ForegroundColor DarkGray
                Push-Location $TR4W_DIR
                if ($viOk) {
                    & $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ @extraFlags "-DLANG_$lang" "-DVERSIONINFO_RES" "/U$LIB" "/I$LIB" "/N$langCache" "/E$EXE_DIR"
                } else {
                    & $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ @extraFlags "-DLANG_$lang" "/U$LIB" "/I$LIB" "/N$langCache" "/E$EXE_DIR"
                }
                $langRc = $LASTEXITCODE
                Pop-Location

                if ($langRc -eq 0 -and (Test-Path $builtExe)) {
                    $info = Get-Item $builtExe
                    $h = (Get-FileHash $builtExe -Algorithm SHA256).Hash.Substring(0,12)
                    Write-Host "  OK  size=$($info.Length) sha256[12]=$h" -ForegroundColor Green

                    if ($BuildInstallers) {
                        # NSIS reads ..\target\tr4w.exe -- packaging consumes
                        # target\tr4w.exe in place (UPX is destructive, then
                        # makensis bundles the compressed exe).
                        $pkgOk = Invoke-Packaging -Version $TR4W_VERSION -LangCode $lang.ToLower()
                        $status = if ($pkgOk) { "OK" } else { "PKG_FAIL" }
                        $langResults += [PSCustomObject]@{ Lang=$lang; Status=$status; Size=$info.Length; Hash=$h }
                    } else {
                        # Move target\tr4w.exe to lang-test\tr4w-<LANG>.exe so
                        # the per-language exe is preserved for inspection.
                        # target\tr4w.exe is now empty until the post-loop
                        # ENG relink restores it.
                        $langFinalExe = Join-Path $LANG_OUT "tr4w-$lang.exe"
                        if (Test-Path $langFinalExe) { Remove-Item $langFinalExe -Force }
                        Move-Item -Path $builtExe -Destination $langFinalExe -Force
                        Write-Host "  Saved $langFinalExe" -ForegroundColor Green
                        $langResults += [PSCustomObject]@{ Lang=$lang; Status="OK"; Size=$info.Length; Hash=$h }
                    }
                } else {
                    $langResults += [PSCustomObject]@{ Lang=$lang; Status="FAIL"; Size=0; Hash="" }
                    Write-Host "  FAIL (exit code $langRc)" -ForegroundColor Red
                }
            }

            Write-Host ""
            Write-Host "=== LANGUAGE BUILD SUMMARY ===" -ForegroundColor Cyan
            $langResults | Format-Table -AutoSize | Out-String | Write-Host
            $unique = ($langResults | Where-Object Status -eq "OK" | Select-Object -ExpandProperty Hash -Unique).Count
            $totalOk = ($langResults | Where-Object Status -eq "OK").Count
            $totalFail = ($langResults | Where-Object { $_.Status -ne "OK" }).Count
            Write-Host "$totalOk built, $totalFail failed, $unique unique binaries" `
                -ForegroundColor $(if ($totalFail -eq 0 -and $unique -eq $totalOk) {"Green"} else {"Yellow"})
            # src\*.dcu has been untouched all along (lang builds wrote to
            # dcu-cache\<lang>\ via /N). The only thing the loop left in a
            # non-ENG state is target\tr4w.exe -- last iteration's lang.
            # Quick DCC32 relink with the existing ENG src\*.dcu produces
            # target\tr4w.exe = ENG in ~5 sec. No file shuffling required.
            Write-Host ""
            Write-Host "Relinking target\tr4w.exe = ENG (src\*.dcu untouched throughout)..." -ForegroundColor DarkGray
            # Regenerate ENG VERSIONINFO so the final target\tr4w.exe Properties
            # dialog reports English, not whichever language the loop ended on.
            $viOk = Write-VersionInfoResource -Lang 'ENG' -VersionString $TR4W_VERSION
            Push-Location $TR4W_DIR
            if ($viOk) {
                & $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ "-DVERSIONINFO_RES" "/U$LIB" "/I$LIB" "/E$EXE_DIR" | Out-Null
            } else {
                & $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ "/U$LIB" "/I$LIB" "/E$EXE_DIR" | Out-Null
            }
            $engRelinkRc = $LASTEXITCODE
            Pop-Location
            if ($engRelinkRc -eq 0) {
                Write-Host "  target\tr4w.exe = ENG" -ForegroundColor Green
            } else {
                Write-Host "  ENG relink failed (exit $engRelinkRc)" -ForegroundColor Red
            }

            if ($BuildInstallers) {
                Write-Host "Installers (incl. ENG): $RELEASE_DIR\tr4w_setup_<VERSION>[_<lang>].exe" -ForegroundColor White
            } else {
                Write-Host "Per-language exes: $LANG_OUT\tr4w-<LANG>.exe" -ForegroundColor White
            }
            Write-Host "src\*.dcu unchanged (ENG, Delphi IDE-compatible). target\tr4w.exe = ENG. Per-language DCUs in $DCU_CACHE_DIR\<lang>\." -ForegroundColor DarkGray
            Write-Host ""
        }
    }
} else {
    Write-Host "=== BUILD FAILED ===" -ForegroundColor Red
    Write-Host "Exit code: $result" -ForegroundColor Red
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Optional: VirusTotal pre-flight scan of any installers produced.
# Gated on -BuildInstallers AND $env:VIRUS_TOTAL_API_KEY. Informational
# only -- never fails the build. CI runs its own VT-scan job with a
# threshold gate; local is just for catching surprises before tagging.
#
# Mirror the CI threshold so the local pre-flight verdict matches what CI
# will do on tag push. Authoritative value lives in
# .github/workflows/release.yml (env.VT_MALICIOUS_THRESHOLD); bump both
# together. Raised from 4 -> 8 in commit cfdab9a to absorb heuristic
# false positives on unsigned NSIS+inpout32.dll installers.
# ---------------------------------------------------------------------------
$VT_MALICIOUS_THRESHOLD = 8
if ($result -eq 0 -and $BuildInstallers -and (Test-Path $RELEASE_DIR)) {
    # Scan ONLY the installers produced by this build, not anything left over
    # from prior versions. RELEASE_DIR accumulates stale installers because
    # NSIS does not sweep old artifacts; without the version filter the local
    # VT pre-flight burns ~10 min per stale file and the operator sees
    # confusing version mismatches in the log.
    $installers = @(Get-ChildItem -Path $RELEASE_DIR -Filter "tr4w_setup_${TR4W_VERSION}*.exe" -File -ErrorAction SilentlyContinue)
    if ($installers.Count -gt 0) {
        # In CI the secret is deliberately scoped to the dedicated VT scan
        # job, not the build job -- the local pre-flight has nothing to do
        # there. Print one terse line so the log still confirms we
        # considered scanning, but skip the operator-targeted guidance.
        $inCI = ($env:GITHUB_ACTIONS -eq 'true')
        if ($inCI -and -not $env:VIRUS_TOTAL_API_KEY) {
            Write-Host ""
            Write-Host "Local VT scan skipped (CI runs authoritative scan in virustotal-scan job)." -ForegroundColor DarkGray
        } elseif (-not $env:VIRUS_TOTAL_API_KEY) {
            Write-Host ""
            Write-Host "=== VirusTotal Scan ===" -ForegroundColor Cyan
            Write-Host "VIRUS_TOTAL_API_KEY env var not set -- skipping local scan." -ForegroundColor DarkGray
            Write-Host "  To enable: `$env:VIRUS_TOTAL_API_KEY = '<your-key>' (persist via System -> Env Vars)." -ForegroundColor DarkGray
            Write-Host "  CI runs the authoritative scan on tag push regardless." -ForegroundColor DarkGray
        } else {
            Write-Host ""
            Write-Host "=== VirusTotal Scan ===" -ForegroundColor Cyan
            Write-Host "Scanning $($installers.Count) installer(s) via VirusTotal API..." -ForegroundColor Yellow
            Write-Host "  (each scan: upload + up to 10 min poll; informational only -- CI is the gate)" -ForegroundColor DarkGray
            foreach ($inst in $installers) {
                Write-Host ""
                Write-Host "  $($inst.Name) ($($inst.Length) bytes)" -ForegroundColor White
                $vt = Invoke-VirusTotalScan -FilePath $inst.FullName -ApiKey $env:VIRUS_TOTAL_API_KEY
                if (-not $vt) {
                    Write-Host "    Scan unavailable -- continuing." -ForegroundColor Yellow
                    continue
                }
                # Shape via the shared helper so stats parsing + the
                # threshold verdict live in exactly one place (the same code
                # the CI report uses).
                $r = ConvertTo-VtResult -FileName $inst.Name -Analysis $vt -Threshold $VT_MALICIOUS_THRESHOLD
                switch ($r.Verdict) {
                    'BLOCKED' { $verdict = "BLOCKED (>= CI threshold of $VT_MALICIOUS_THRESHOLD)"; $color = "Red" }
                    'WARN'    { $verdict = "WARN (below CI threshold)";                            $color = "Yellow" }
                    default   { $verdict = "CLEAN";                                                $color = "Green" }
                }
                Write-Host "    $verdict -- $($r.Malicious) malicious / $($r.Suspicious) suspicious / $($r.Undetected + $r.Harmless) clean of $($r.Total) engines" -ForegroundColor $color
                Write-Host "    https://www.virustotal.com/gui/file/$($r.Sha)" -ForegroundColor Cyan
            }
            Write-Host ""
            Write-Host "Local scan complete. CI VT-scan is the authoritative gate on tag push." -ForegroundColor DarkGray
        }
    }
}

exit $result
