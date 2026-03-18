rem UpResource.exe
upx.exe ..\target\tr4w.exe --lzma
"%ProgramFiles(x86)%\NSIS\makensisw.exe" full.nsi
pause