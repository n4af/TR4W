$ErrorActionPreference = "Stop"

$DCC32 = "C:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE"
$PROJECT = "C:\TR4W\tr4w\test\logdump\logdump.dpr"
$OUT_DIR = "C:\TR4W\tr4w\test\logdump"

$DCU_DIR = "C:\Temp\tr4w-logdump"
New-Item -ItemType Directory -Force -Path $DCU_DIR | Out-Null

Write-Host "=== Compiling logdump ===" -ForegroundColor Cyan
Push-Location $OUT_DIR
& $DCC32 $PROJECT "-N$DCU_DIR" "/E$OUT_DIR" "/UC:\TR4W\tr4w\src"
$result = $LASTEXITCODE
Pop-Location

if ($result -eq 0 -and (Test-Path "$OUT_DIR\logdump.exe")) {
    Write-Host "=== BUILD OK ===" -ForegroundColor Green
    Write-Host "  $OUT_DIR\logdump.exe" -ForegroundColor White
} else {
    Write-Host "=== BUILD FAILED ($result) ===" -ForegroundColor Red
}

exit $result
