set LIB=C:\Indy\Lib\Core;
set LIB=%LIB%C:\Indy\Lib\System;
set LIB=%LIB%C:\tr4w\tr4w\include;
set LIB=%LIB%C:\Indy\Lib\Protocols;
rem set LIB=%LIB%C:\Dev\D6\Source\ToolsApi;
rem set LIB=%LIB%C:\Dev\D6\Source\RTL\Lib;
rem set LIB=%LIB%C:\Infocare\Components\genericSQL;

:: Exe is where your exe is placed
set EXE=C:\TR4W\tr4w\target
cd C:\tr4w\tr4w
"c:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE" C:\TR4W\tr4w\tr4w.dpr -NC:\Temp  /U%LIB% /I%LIB% /E%EXE% > COMPILER.LOG