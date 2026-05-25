param(
    # When set, build the default (English) tr4w.exe first, then loop
    # through every other supported LANG_xxx (RUS, SER, ESP, MNG, POL,
    # CZE, ROM, CHN, GER, UKR) producing tr4w-<lang>.exe in
    # target\dist\lang-test\. Used to smoke-test the LANG ifdef
    # mechanism introduced in PR #924; not part of the normal dev loop.
    [switch]$AllLanguages
)

$ErrorActionPreference = "Continue"

$LIB = "C:\Indy\Indy\Lib\Core;C:\Indy\Indy\Lib\System;C:\tr4w\tr4w\include;C:\Indy\Indy\Lib\Protocols"
$DCC32 = "C:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE"
$PROJECT = "C:\TR4W\tr4w\tr4w.dpr"
$EXE_DIR = "C:\TR4W\tr4w\target"
$TEST_DPR = "C:\TR4W\tr4w\test\unit\tr4w_unit_tests.dpr"
$TEST_DIR = "C:\TR4W\tr4w\test\unit"
$SRC_DIR  = "C:\TR4W\tr4w\src"

# ---------------------------------------------------------------------------
# Step 1: Compile and run unit tests.
# Tests have no Indy/Log4D dependencies — compile without those library paths.
# Exit codes: 0 = all pass, 1 = one or more failures (also fails to compile).
# ---------------------------------------------------------------------------

Write-Host "=== Compiling Unit Tests ===" -ForegroundColor Cyan
Write-Host ""

$TEST_DCU_DIR = "C:\Temp\tr4w-test"
New-Item -ItemType Directory -Force -Path $TEST_DCU_DIR | Out-Null

Push-Location $TEST_DIR
# /U includes src\ so VC.pas (and Log4D.dcu within it) resolve correctly
& $DCC32 $TEST_DPR -`$D+ -`$L+ -`$Y+ "-N$TEST_DCU_DIR" "/E$TEST_DIR" "/UC:\TR4W\tr4w\src"
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

Push-Location "C:\TR4W\tr4w"
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
        Write-Host "  Size: $($exeInfo.Length) bytes" -ForegroundColor White
        Write-Host "  Modified: $($exeInfo.LastWriteTime)" -ForegroundColor White
        Write-Host ""

        # ---------------------------------------------------------------
        # Step 2b: Build tr4wserver.exe (required by the NSIS installer).
        # ---------------------------------------------------------------
        & "C:\TR4W\tr4w\tr4wserver\BuildServer.ps1"
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
        $DIST_DIR = "C:\TR4W\tr4w\target\dist"
        New-Item -ItemType Directory -Force -Path $DIST_DIR | Out-Null

        # Extract version from Version.pas (e.g. 4.147.15)
        $versionLine = Select-String -Path "C:\TR4W\tr4w\src\Version.pas" `
                                     -Pattern "TR4W_CURRENTVERSION_NUMBER\s*=\s*'([^']+)'" `
                                     | Select-Object -First 1
        if ($versionLine -and $versionLine.Matches[0].Groups[1].Value) {
            $version = $versionLine.Matches[0].Groups[1].Value
        } else {
            $version = "unknown"
        }

        # Current git branch (slash-safe for filenames)
        $branchRaw = (git -C "C:\TR4W" rev-parse --abbrev-ref HEAD 2>$null)
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
            $LANG_OUT = "C:\TR4W\tr4w\target\dist\lang-test"
            New-Item -ItemType Directory -Force -Path $LANG_OUT | Out-Null

            # Capture the ENG build that Steps 2/2b/3 already produced
            # so the summary table includes it alongside the variants.
            $engHash = (Get-FileHash "$EXE_DIR\tr4w.exe" -Algorithm SHA256).Hash.Substring(0,12)
            Copy-Item "$EXE_DIR\tr4w.exe" "$LANG_OUT\tr4w-ENG.exe" -Force
            $langResults = @()
            $langResults += [PSCustomObject]@{ Lang="ENG"; Status="OK"; Size=(Get-Item "$EXE_DIR\tr4w.exe").Length; Hash=$engHash }

            $otherLangs = @("RUS","SER","MNG","CZE","ROM","GER","UKR")
            
            foreach ($lang in $otherLangs) {
                Write-Host ""
                Write-Host "=== Building LANG_$lang ===" -ForegroundColor Cyan

                # Clear TR4W src DCUs only (Indy DCUs in C:\Indy\... untouched).
                # Forces VC.pas and every downstream unit to recompile against
                # the new -DLANG_$lang flag while Indy stays cached.
                # -Recurse handles src\trdos\ and src\utils\ subdirs.
                Get-ChildItem -Path $SRC_DIR -Filter *.dcu -Recurse -File `
                    | Remove-Item -Force -ErrorAction SilentlyContinue
                if (Test-Path "$EXE_DIR\tr4w.exe") { Remove-Item "$EXE_DIR\tr4w.exe" -Force }

                Push-Location "C:\TR4W\tr4w"
                & $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ "-DLANG_$lang" "/U$LIB" "/I$LIB" "/E$EXE_DIR"
                $langRc = $LASTEXITCODE
                Pop-Location

                if ($langRc -eq 0 -and (Test-Path "$EXE_DIR\tr4w.exe")) {
                    $info = Get-Item "$EXE_DIR\tr4w.exe"
                    $h = (Get-FileHash "$EXE_DIR\tr4w.exe" -Algorithm SHA256).Hash.Substring(0,12)
                    Copy-Item "$EXE_DIR\tr4w.exe" "$LANG_OUT\tr4w-$lang.exe" -Force
                    $langResults += [PSCustomObject]@{ Lang=$lang; Status="OK"; Size=$info.Length; Hash=$h }
                    Write-Host "  OK  size=$($info.Length) sha256[12]=$h" -ForegroundColor Green
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
            $totalFail = ($langResults | Where-Object Status -eq "FAIL").Count
            Write-Host "$totalOk built, $totalFail failed, $unique unique binaries" `
                -ForegroundColor $(if ($totalFail -eq 0 -and $unique -eq $totalOk) {"Green"} else {"Yellow"})
            Write-Host "Per-language exes: $LANG_OUT\tr4w-<LANG>.exe" -ForegroundColor White
            Write-Host ""
            Write-Host "Note: target\tr4w.exe and src\*.dcu are in the state of the LAST language built." -ForegroundColor DarkGray
            Write-Host "      Re-run FullBuild.ps1 (no -AllLanguages) to restore the ENG baseline." -ForegroundColor DarkGray
            Write-Host ""
        }
    }
} else {
    Write-Host "=== BUILD FAILED ===" -ForegroundColor Red
    Write-Host "Exit code: $result" -ForegroundColor Red
    Write-Host ""
}

exit $result
