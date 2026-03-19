$ErrorActionPreference = "Continue"

$LIB = "C:\Indy\Lib\Core;C:\Indy\Lib\System;C:\tr4w\tr4w\include;C:\Indy\Lib\Protocols"
$DCC32 = "C:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE"
$SRC = "c:\tr4w\tr4w\src"

Write-Host "=== Compiling uHamLibDirect.pas ===" -ForegroundColor Cyan
& $DCC32 "$SRC\uHamLibDirect.pas" -`$D+ -`$L+ -`$Y+ -NC:\Temp "/U$LIB" "/I$LIB" /EC:\TR4W\tr4w\target
$result1 = $LASTEXITCODE

if ($result1 -eq 0) {
    Write-Host ""
    Write-Host "=== uHamLibDirect.pas compiled successfully ===" -ForegroundColor Green
    Write-Host ""

    Write-Host "=== Compiling uRadioHamLibDirect.pas ===" -ForegroundColor Cyan
    & $DCC32 "$SRC\uRadioHamLibDirect.pas" -`$D+ -`$L+ -`$Y+ -NC:\Temp "/U$LIB;$SRC" "/I$LIB;$SRC" /EC:\TR4W\tr4w\target
    $result2 = $LASTEXITCODE

    if ($result2 -eq 0) {
        Write-Host ""
        Write-Host "=== Both units compiled successfully ===" -ForegroundColor Green
        Write-Host ""
        exit 0
    } else {
        Write-Host ""
        Write-Host "=== uRadioHamLibDirect.pas compilation failed ===" -ForegroundColor Red
        Write-Host ""
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "=== uHamLibDirect.pas compilation failed ===" -ForegroundColor Red
    Write-Host ""
    exit 1
}
