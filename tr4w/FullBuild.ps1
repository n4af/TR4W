$ErrorActionPreference = "Continue"

$LIB = "C:\Indy\Lib\Core;C:\Indy\Lib\System;C:\tr4w\tr4w\include;C:\Indy\Lib\Protocols"
$DCC32 = "C:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE"
$PROJECT = "C:\TR4W\tr4w\tr4w.dpr"
$EXE_DIR = "C:\TR4W\tr4w\target"
$TEST_DPR = "C:\TR4W\tr4w\test\unit\tr4w_unit_tests.dpr"
$TEST_DIR = "C:\TR4W\tr4w\test\unit"

# ---------------------------------------------------------------------------
# Step 1: Compile and run unit tests.
# Tests have no Indy/Log4D dependencies — compile without those library paths.
# Exit codes: 0 = all pass, 1 = one or more failures (also fails to compile).
# ---------------------------------------------------------------------------

Write-Host "=== Compiling Unit Tests ===" -ForegroundColor Cyan
Write-Host ""

Push-Location $TEST_DIR
& $DCC32 $TEST_DPR -`$D+ -`$L+ -`$Y+ -NC:\Temp "/E$TEST_DIR"
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

& $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ -NC:\Temp "/U$LIB" "/I$LIB" "/E$EXE_DIR"

$result = $LASTEXITCODE

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
    }
} else {
    Write-Host "=== BUILD FAILED ===" -ForegroundColor Red
    Write-Host "Exit code: $result" -ForegroundColor Red
    Write-Host ""
}

exit $result
