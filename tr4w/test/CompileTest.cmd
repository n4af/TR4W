@echo off
set LIB=C:\Indy\Lib\Core;
set LIB=%LIB%C:\Indy\Lib\System;
set LIB=%LIB%C:\tr4w\tr4w\include;
set LIB=%LIB%C:\Indy\Lib\Protocols;
set EXE=C:\TR4W\tr4w\target
cd C:\tr4w\tr4w
"c:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE" src\uHamLibDirect.pas -$D+ -$L+ -$Y+ -NC:\Temp /U%LIB% /I%LIB% /E%EXE%
if errorlevel 1 goto error
echo.
echo === First unit compiled successfully ===
echo.
"c:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE" src\uRadioHamLibDirect.pas -$D+ -$L+ -$Y+ -NC:\Temp /U%LIB%;c:\tr4w\tr4w\src /I%LIB%;c:\tr4w\tr4w\src /E%EXE%
if errorlevel 1 goto error
echo.
echo === Second unit compiled successfully ===
echo.
goto end

:error
echo.
echo === Compilation failed ===
echo.
exit /b 1

:end
echo.
echo === All units compiled successfully ===
echo.
