$ErrorActionPreference = "Continue"

$LIB     = "C:\Indy\Indy\Lib\Core;C:\Indy\Indy\Lib\System;C:\tr4w\tr4w\include;C:\Indy\Indy\Lib\Protocols"
$DCC32   = "C:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE"
$PROJECT = "C:\TR4W\tr4w\tr4wserver\tr4wserver.dpr"
$EXE_DIR = "C:\TR4W\tr4w\tr4wserver"

Write-Host "=== Building TR4W Server ===" -ForegroundColor Cyan
Write-Host "Project: $PROJECT" -ForegroundColor Yellow
Write-Host "Output:  $EXE_DIR" -ForegroundColor Yellow
Write-Host ""

Push-Location "C:\TR4W\tr4w\tr4wserver"
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
