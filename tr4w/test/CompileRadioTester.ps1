$ErrorActionPreference = "Continue"

$LIB = "C:\Indy\Lib\Core;C:\Indy\Lib\System;C:\tr4w\tr4w\include;C:\Indy\Lib\Protocols;C:\tr4w\tr4w\src;C:\tr4w\tr4w\src\trdos;C:\tr4w\tr4w\src\utils"
$DCC32 = "C:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE"
$PROJECT = "C:\TR4W\tr4w\test\RadioFactoryTester.dpr"
$EXE_DIR = "C:\TR4W\tr4w\target"

Write-Host "=== Building RadioFactoryTester ===" -ForegroundColor Cyan
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
    if (Test-Path "$EXE_DIR\RadioFactoryTester.exe") {
        $exeInfo = Get-Item "$EXE_DIR\RadioFactoryTester.exe"
        Write-Host "RadioFactoryTester.EXE Details:" -ForegroundColor Cyan
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
