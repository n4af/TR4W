param(
    # Match FullBuild.ps1's path resolution so the two scripts can be run
    # standalone OR chained together. Defaults are derived from the script
    # location and the same env vars FullBuild.ps1 uses.
    [string]$ProjectRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
    [string]$Delphi7Bin  = $(if ($env:DELPHI7_BIN) { $env:DELPHI7_BIN } else { "C:\Program Files (x86)\Borland\Delphi7\Bin" }),
    [string]$IndyRoot    = $(if ($env:INDY_ROOT)   { $env:INDY_ROOT }   else { Join-Path (Join-Path $ProjectRoot "tr4w") "include" })
)

$ErrorActionPreference = "Continue"

$TR4W_DIR     = Join-Path $ProjectRoot "tr4w"
$SERVER_DIR   = Join-Path $TR4W_DIR "tr4wserver"
$DCC32        = Join-Path $Delphi7Bin "DCC32.EXE"
$PROJECT      = Join-Path $SERVER_DIR "tr4wserver.dpr"
$EXE_DIR      = $SERVER_DIR
$LIB          = "$IndyRoot\Core;$IndyRoot\System;$TR4W_DIR\include;$IndyRoot\Protocols"

Write-Host "=== Building TR4W Server ===" -ForegroundColor Cyan
Write-Host "Project: $PROJECT" -ForegroundColor Yellow
Write-Host "Output:  $EXE_DIR" -ForegroundColor Yellow
Write-Host ""

Push-Location $SERVER_DIR
& $DCC32 $PROJECT -`$D+ -`$L+ -`$Y+ "/U$LIB" "/I$LIB" "/E$EXE_DIR"
$result = $LASTEXITCODE
Pop-Location

Write-Host ""
if ($result -eq 0) {
    Write-Host "=== BUILD SUCCESSFUL ===" -ForegroundColor Green
    if (Test-Path "$EXE_DIR\tr4wserver.exe") {
        $exeInfo = Get-Item "$EXE_DIR\tr4wserver.exe"
        Write-Host "TR4WSERVER.EXE Details:" -ForegroundColor Cyan
        Write-Host "  Size:     $($exeInfo.Length) bytes" -ForegroundColor White
        Write-Host "  Modified: $($exeInfo.LastWriteTime)" -ForegroundColor White
    }
} else {
    Write-Host "=== BUILD FAILED ===" -ForegroundColor Red
    Write-Host "Exit code: $result" -ForegroundColor Red
}

exit $result
