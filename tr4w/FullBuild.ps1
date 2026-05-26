param(
    # When set, after the default ENG build, loop through every other
    # supported LANG_xxx (RUS, SER, MNG, CZE, ROM, GER, UKR) and rebuild
    # against each. Excludes ESP/POL/CHN (broken constants, issue #925).
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
    # subdirs). Set $env:INDY_ROOT to override, or pass -IndyRoot.
    [string]$IndyRoot = $(if ($env:INDY_ROOT) { $env:INDY_ROOT } else { "C:\Indy\Indy\Lib" }),

    # NSIS install dir (contains makensis.exe). Only consulted when
    # -BuildInstallers is set. Override with $env:NSIS_BIN or -NSISBin.
    [string]$NSISBin = $(if ($env:NSIS_BIN) { $env:NSIS_BIN } else { "C:\Program Files (x86)\NSIS" }),

    # UPX bin directory (contains upx.exe). Only consulted when
    # -BuildInstallers is set. Resolution order:
    #   1. -UpxBin / $env:UPX_BIN explicit directory (validated below)
    #   2. PATH lookup via Get-Command upx.exe (default if neither set)
    [string]$UpxBin = $(if ($env:UPX_BIN) { $env:UPX_BIN } else { "" })
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
            Write-Host "upx.exe not found (required by -BuildInstallers)." -ForegroundColor Red
            Write-Host ""
            Write-Host "Fix one of these ways:" -ForegroundColor Yellow
            Write-Host "  1. Pass -UpxBin <directory-containing-upx.exe> on the command line, OR" -ForegroundColor Yellow
            Write-Host "  2. Set the UPX_BIN environment variable to that directory (persists), OR" -ForegroundColor Yellow
            Write-Host "  3. Add the directory containing upx.exe to your PATH and reopen the shell." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Download UPX from https://upx.github.io/ if you don't have it." -ForegroundColor Yellow
            exit 2
        }
    }
    Write-Host "Using upx: $UPX" -ForegroundColor DarkGray
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

# Upload one file to VirusTotal and poll for the analysis result.
# Uses curl.exe for the multipart upload because Windows PowerShell 5.1's
# Invoke-RestMethod lacks the -Form switch (PS 7+ only). curl.exe ships
# with Windows 10 1803+ so the dependency is effectively zero.
# Returns the parsed analysis response object on success, or $null on
# upload/poll failure (informational only -- callers don't fail the
# build).
function Invoke-VirusTotalScan {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][string]$ApiKey
    )

    $filesize = (Get-Item $FilePath).Length
    $uploadUrl = 'https://www.virustotal.com/api/v3/files'

    # Files >32MB need a one-shot large-file upload URL.
    if ($filesize -gt 33554432) {
        try {
            $ulResp = Invoke-RestMethod -Uri 'https://www.virustotal.com/api/v3/files/upload_url' `
                                        -Method Get `
                                        -Headers @{ 'x-apikey' = $ApiKey }
            $uploadUrl = $ulResp.data
        } catch {
            Write-Host "    Failed to get large-file upload URL: $_" -ForegroundColor Red
            return $null
        }
    }

    $curlOut = & curl.exe --silent --request POST `
                          --url $uploadUrl `
                          --header "x-apikey: $ApiKey" `
                          --form "file=@$FilePath"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    curl upload failed (exit $LASTEXITCODE)" -ForegroundColor Red
        return $null
    }
    try {
        $upResp = $curlOut | ConvertFrom-Json
    } catch {
        Write-Host "    Upload response not JSON: $curlOut" -ForegroundColor Red
        return $null
    }
    $analysisId = $upResp.data.id
    if (-not $analysisId) {
        Write-Host "    No analysis id in upload response" -ForegroundColor Red
        return $null
    }

    # Poll /analyses/{id} every 15s up to 10 minutes total.
    for ($i = 1; $i -le 40; $i++) {
        Start-Sleep -Seconds 15
        try {
            $poll = Invoke-RestMethod -Uri "https://www.virustotal.com/api/v3/analyses/$analysisId" `
                                       -Method Get `
                                       -Headers @{ 'x-apikey' = $ApiKey }
        } catch {
            Write-Host "    Poll $i/40 error: $_" -ForegroundColor DarkYellow
            continue
        }
        if ($poll.data.attributes.status -eq 'completed') {
            return $poll
        }
        Write-Host "    Poll $i/40: status=$($poll.data.attributes.status)" -ForegroundColor DarkGray
    }
    Write-Host "    Poll timed out after 10 minutes" -ForegroundColor Red
    return $null
}

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

    New-Item -ItemType Directory -Force -Path $RELEASE_DIR | Out-Null

    # UPX --lzma (destructive: overwrites the exe with the compressed copy).
    Write-Host "  upx --lzma $exe" -ForegroundColor DarkGray
    & $UPX $exe --lzma | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "  UPX failed (exit $LASTEXITCODE)" -ForegroundColor Red; return $false }

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

Push-Location $TR4W_DIR
& $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ "/U$LIB" "/I$LIB" "/E$EXE_DIR"
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
        # Step 3: Zip the exe for distribution.
        # The version + branch + timestamp filename means whack-a-mole test
        # cycles with off-site testers never end up with two ambiguous
        # "tr4w.exe" attachments sitting in the inbox.
        # ---------------------------------------------------------------
        New-Item -ItemType Directory -Force -Path $DIST_DIR | Out-Null

        # Extract version from Version.pas (e.g. 4.147.15)
        $versionLine = Select-String -Path $VERSION_PAS `
                                     -Pattern "TR4W_CURRENTVERSION_NUMBER\s*=\s*'([^']+)'" `
                                     | Select-Object -First 1
        if ($versionLine -and $versionLine.Matches[0].Groups[1].Value) {
            $version = $versionLine.Matches[0].Groups[1].Value
        } else {
            $version = "unknown"
        }

        # Current git branch (slash-safe for filenames)
        $branchRaw = (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($LASTEXITCODE -ne 0 -or -not $branchRaw) {
            $branch = "nobranch"
        } else {
            $branch = $branchRaw.Trim() -replace '[/\\:*?"<>|]', '-'
        }

        $stamp   = Get-Date -Format "yyyyMMdd-HHmmss"
        $zipName = "tr4w-$version-$branch-$stamp.zip"
        $zipPath = Join-Path $DIST_DIR $zipName

        Write-Host "=== Packaging EXE ===" -ForegroundColor Cyan
        Write-Host "Archive: $zipPath" -ForegroundColor Yellow

        Compress-Archive -Path "$EXE_DIR\tr4w.exe" -DestinationPath $zipPath -Force
        if (Test-Path $zipPath) {
            $zipInfo = Get-Item $zipPath
            Write-Host "  Size: $($zipInfo.Length) bytes" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "  ZIP STEP FAILED -- archive not created" -ForegroundColor Red
            Write-Host ""
        }

        # ---------------------------------------------------------------
        # Step 3b (optional): build the ENG installer (no language suffix).
        # Zip above captured the un-UPXed ENG exe for dev distribution;
        # now UPX+NSIS produces the shippable installer. UPX is destructive
        # so the order matters: zip first, then UPX, then NSIS.
        # ---------------------------------------------------------------
        if ($BuildInstallers) {
            Invoke-Packaging -Version $version -LangCode "" | Out-Null
        }

        # ---------------------------------------------------------------
        # Step 4 (optional): build every non-English language variant.
        # Runs LAST -- after tr4wserver and zip have packaged the default
        # English build -- because each language iteration clears the
        # TR4W src DCUs and rewrites them under -DLANG_$lang. Nothing
        # downstream consumes target\tr4w.exe or src\*.dcu, so this loop
        # can leave them in whatever state the final language produced.
        #
        # Indy DCUs at C:\Indy\Indy\Lib\* stay cached across iterations,
        # which is the only way to keep per-language builds under ~3 min
        # each instead of ~3 min just for the Indy rebuild alone.
        #
        # ESP/POL/CHN are excluded -- they each have many missing
        # constants tracked separately under issue #925.
        # ---------------------------------------------------------------
        if ($AllLanguages) {
            $langResults = @()
            $otherLangs = @("RUS","SER","MNG","CZE","ROM","GER","UKR")

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

                Write-Host "  DCC32 -DLANG_$lang /N$langCache -> $EXE_DIR\tr4w.exe" -ForegroundColor DarkGray
                Push-Location $TR4W_DIR
                & $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ @extraFlags "-DLANG_$lang" "/U$LIB" "/I$LIB" "/N$langCache" "/E$EXE_DIR"
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
                        $pkgOk = Invoke-Packaging -Version $version -LangCode $lang.ToLower()
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
            Push-Location $TR4W_DIR
            & $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ "/U$LIB" "/I$LIB" "/E$EXE_DIR" | Out-Null
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
# ---------------------------------------------------------------------------
if ($result -eq 0 -and $BuildInstallers -and (Test-Path $RELEASE_DIR)) {
    $installers = @(Get-ChildItem -Path $RELEASE_DIR -Filter 'tr4w_setup_*.exe' -File -ErrorAction SilentlyContinue)
    if ($installers.Count -gt 0) {
        Write-Host ""
        Write-Host "=== VirusTotal Scan ===" -ForegroundColor Cyan
        if (-not $env:VIRUS_TOTAL_API_KEY) {
            Write-Host "VIRUS_TOTAL_API_KEY env var not set -- skipping local scan." -ForegroundColor DarkGray
            Write-Host "  To enable: `$env:VIRUS_TOTAL_API_KEY = '<your-key>' (persist via System -> Env Vars)." -ForegroundColor DarkGray
            Write-Host "  CI runs the authoritative scan on tag push regardless." -ForegroundColor DarkGray
        } else {
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
                $stats   = $vt.data.attributes.stats
                $mal     = [int]$stats.malicious
                $sus     = [int]$stats.suspicious
                $undet   = [int]$stats.undetected
                $harm    = [int]$stats.harmless
                $fail    = [int]$stats.failure
                $total   = $mal + $sus + $undet + $harm + $fail
                $sha     = $vt.meta.file_info.sha256
                if ($mal -ge 4) {
                    $verdict = "BLOCKED (>= CI threshold of 4)"; $color = "Red"
                } elseif ($mal -gt 0 -or $sus -gt 0) {
                    $verdict = "WARN (below CI threshold)"; $color = "Yellow"
                } else {
                    $verdict = "CLEAN"; $color = "Green"
                }
                Write-Host "    $verdict -- $mal malicious / $sus suspicious / $($undet + $harm) clean of $total engines" -ForegroundColor $color
                Write-Host "    https://www.virustotal.com/gui/file/$sha" -ForegroundColor Cyan
            }
            Write-Host ""
            Write-Host "Local scan complete. CI VT-scan is the authoritative gate on tag push." -ForegroundColor DarkGray
        }
    }
}

exit $result
