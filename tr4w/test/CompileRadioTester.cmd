@echo off
REM Compile RadioFactoryTester.dpr using Delphi 7 command-line compiler

set LIB=C:\Indy\Lib\Core;
set LIB=%LIB%C:\Indy\Lib\System;
set LIB=%LIB%C:\tr4w\tr4w\include;
set LIB=%LIB%C:\Indy\Lib\Protocols;

set EXE=C:\TR4W\tr4w\target
cd C:\tr4w\tr4w

echo Compiling RadioFactoryTester...

"c:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE" test\RadioFactoryTester.dpr ^
  -NC:\Temp ^
  /U%LIB% ^
  /I%LIB% ^
  /E%EXE%

if %ERRORLEVEL% NEQ 0 (
    echo Compilation FAILED with error code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo.
echo Compilation SUCCESSFUL
echo Output: target\RadioFactoryTester.exe
exit /b 0
