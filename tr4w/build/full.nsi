!define TR4WVERSION    '37.0'
!define TR4WINSTFOLDER 'Software\TR4W'
!define TR4WDRVREG     'SYSTEM\CurrentControlSet\Services\TR4WIO'

;!define MMTTYMODE    'mmtty'
;!define TR4WLANG    'rus'
;!define TR4WLANG    'ser'
;!define TR4WLANG    'esp'
;!define TR4WLANG    'mng'
;!define TR4WLANG    'pol'
;!define TR4WLANG    'cze'
;!define TR4WLANG    'rom'
;!define TR4WLANG    'chn'


!ifdef MMTTYMODE
Name    "TR4W v.4.${TR4WVERSION} - MMTTY"
!else
Name    "TR4W v.4.${TR4WVERSION}"
!endif

!ifdef TR4WLANG
OutFile release\tr4w_setup_4_${TR4WVERSION}_${TR4WLANG}.exe
!else
OutFile release\tr4w_setup_4_${TR4WVERSION}.exe
!ifdef MMTTYMODE
OutFile release\tr4w_setup_4_${TR4WVERSION}_mmtty.exe
!endif
!endif

!If ${TR4WLANG} == "rus"
	LoadLanguageFile "${NSISDIR}\Contrib\Language files\Russian.nlf"
	!define include_ini_file
!EndIf

!If ${TR4WLANG} == "ser"
	LoadLanguageFile "${NSISDIR}\Contrib\Language files\SerbianLatin.nlf"
!EndIf

!If ${TR4WLANG} == "esp"
	LoadLanguageFile "${NSISDIR}\Contrib\Language files\SpanishInternational.nlf"
!EndIf

!If ${TR4WLANG} == "mng"
	LoadLanguageFile "${NSISDIR}\Contrib\Language files\Mongolian.nlf"
!EndIf

!If ${TR4WLANG} == "pol"
	LoadLanguageFile "${NSISDIR}\Contrib\Language files\Polish.nlf"
!EndIf

!If ${TR4WLANG} == "cze"
	LoadLanguageFile "${NSISDIR}\Contrib\Language files\Czech.nlf"
	!define include_ini_file
!EndIf

!If ${TR4WLANG} == "rom"
	LoadLanguageFile "${NSISDIR}\Contrib\Language files\Romanian.nlf"
!EndIf

!If ${TR4WLANG} == "chn"
	LoadLanguageFile "${NSISDIR}\Contrib\Language files\SimpChinese.nlf"
!EndIf

InstallDir "$PROGRAMFILES\TR4W"

;Get installation folder from registry if available
InstallDirRegKey HKCU "Software\TR4W" ""


Page components
Page directory
Page instfiles


;BGGradient 0000FF FFFFFF
InstallColors  0000FF FFFFFF
;ShowInstDetails show


;Section "" SecCheckDLPortIO
; SEtRebootFlag false
; IfFileExists $SYSDIR\dlportio.dll checksys 0
; SEtRebootFlag true
; checksys:
; IfFileExists $SYSDIR\DRIVERS\dlportio.sys dlportioexist 0
; SEtRebootFlag true
; dlportioexist:
;SectionEnd



Section "tr4w.exe" secexe
	SectionIn RO
	SetOutPath "$INSTDIR"
	File ..\target\tr4w.exe
	File ..\target\r150s.dat
!ifdef TR4WLANG
!ifdef include_ini_file
;!If (${TR4WLANG} == "rus") || (${TR4WLANG} == "cze")
	File ..\target\commands_help_${TR4WLANG}.ini
!endif
!else
File ..\target\commands_help_eng.ini
!endif



;File commands_help_eng.ini
;File Help\TR4W_RUS.hlp
;SetOutPath "$FONTS"
;File luconsz.ttf

;Store installation folder
WriteRegStr HKCU "Software\TR4W" "" $INSTDIR

SectionEnd

Section "tr4wserver.exe" secserv
  SectionIn RO
  SetOutPath "$INSTDIR\server"
  File ..\tr4wserver\target\tr4wserver.exe
  SetOutPath "$INSTDIR"
SectionEnd

;Section "DLPORTIO Driver" seclpt
;	SectionIn RO
;	SetOutPath "$SYSDIR"
;	File dlportio.dll
;	SetOutPath "$SYSDIR\DRIVERS"
;	File dlportio.sys
;	SetOutPath "$INSTDIR"
;SectionEnd

!ifdef TR4WLANG
!If ${TR4WLANG} == "rus"
Section "tr4w_manual_rus.chm" secrusmanual
;	File tr4w_manual_rus.chm
SectionEnd
!endif
!endif

;Section /o "tr4wio.sys" Sectr4wiosys

;	SetRebootFlag false

;	ClearErrors
;	ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
;	IfErrors lbl_win98ME 0

;	IfFileExists "$SYSDIR\DRIVERS\tr4wio.sys" rebootisneed 0
;	SetRebootFlag true
;rebootisneed:
	
;	WriteRegDWORD HKLM ${TR4WDRVREG} "Type"          1
;	WriteRegDWORD HKLM ${TR4WDRVREG} "Start"         2
;	WriteRegDWORD HKLM ${TR4WDRVREG} "ErrorControl"  1
;	;	WriteRegStr   HKLM ${TR4WDRVREG} "ImagePath"     "SYSTEM32\DRIVERS\TR4WIO.SYS"
;	WriteRegStr   HKLM ${TR4WDRVREG} "DisplayName"   "TR4W IO Access"

;	SetOutPath "$SYSDIR\DRIVERS"
;	File tr4wio.sys

;lbl_win98ME:
;	SetOutPath "$INSTDIR"
;SectionEnd


Section /o "cluster_commands.txt" Secclustercomm
  File ..\target\cluster_commands.txt
SectionEnd


Section "cty.dat" Seccty
  File ..\target\cty.dat
SectionEnd

Section "cursor.bmp" seccursor
  File ..\target\cursor.bmp
SectionEnd

Section "Desktop shortcut"
  CreateShortCut "$DESKTOP\TR4W.lnk" "$INSTDIR\tr4w.exe"
SectionEnd

Section "Domestic multiplier files" Secdom

;  SetOutPath "$INSTDIR\Plugins"
;  File Plugins\tr4wSortLog.dll
  
  SetOutPath "$INSTDIR\dom"
   File ..\target\dom\alaska.dom
   File ..\target\dom\allja.dom
   File ..\target\dom\ari.dom
   File ..\target\dom\arrl10.dom
   File ..\target\dom\arrlsect.dom
   File ..\target\dom\california.dom
   File ..\target\dom\california_cty.dom
   File ..\target\dom\cis.dom
   File ..\target\dom\colorado.dom
   File ..\target\dom\colorado_cty.dom
   File ..\target\dom\ea.dom
   File ..\target\dom\florida.dom
   File ..\target\dom\florida_cty.dom
   File ..\target\dom\grids.dom
   File ..\target\dom\hawaii.dom
   File ..\target\dom\hungary.dom
   File ..\target\dom\iaruhq.dom
   File ..\target\dom\ireland.dom
   File ..\target\dom\jacg3.dom
   File ..\target\dom\japref.dom
   File ..\target\dom\japrefct.dom
   File ..\target\dom\jidx.dom
   File ..\target\dom\kda.dom
   File ..\target\dom\lz.dom
   File ..\target\dom\mexico.dom
   File ..\target\dom\michigan.dom
   File ..\target\dom\michigan_cty.dom
   File ..\target\dom\minnesota.dom
   File ..\target\dom\minnesota_cty.dom
   File ..\target\dom\naqp.dom
   File ..\target\dom\neqso.dom
   File ..\target\dom\neqsow1.dom
   File ..\target\dom\newyork.dom
   File ..\target\dom\newyork_cty.dom
   File ..\target\dom\nrau.dom
   File ..\target\dom\ohio.dom
   File ..\target\dom\ohio_cty.dom
   File ..\target\dom\okom.dom
   File ..\target\dom\p12.dom
   File ..\target\dom\p13.dom
   File ..\target\dom\p14.dom
   File ..\target\dom\p8.dom
   File ..\target\dom\pacc.dom
   File ..\target\dom\paccpa.dom
   File ..\target\dom\pmc.dom
   File ..\target\dom\ref.dom
   File ..\target\dom\romania.dom
   File ..\target\dom\rsgb.dom
   File ..\target\dom\russian.dom
   File ..\target\dom\s48.dom
   File ..\target\dom\s48p14dc.dom
   File ..\target\dom\s49p13.dom
   File ..\target\dom\s49p8.dom
   File ..\target\dom\s50.dom
   File ..\target\dom\s50p12.dom
   File ..\target\dom\s50p14dc.dom
   File ..\target\dom\seven.dom
   File ..\target\dom\seven_cty.dom
   File ..\target\dom\spdx.dom
   File ..\target\dom\swiss.dom
   File ..\target\dom\tennessee.dom
   File ..\target\dom\tennessee_cty.dom
   File ..\target\dom\texas.dom
   File ..\target\dom\texas_cty.dom
   File ..\target\dom\uba.dom
   File ..\target\dom\ukraine.dom
   File ..\target\dom\washington.dom
   File ..\target\dom\washington_cty.dom
   File ..\target\dom\wisconsin.dom
   File ..\target\dom\wisconsin_cty.dom
  SetOutPath "$INSTDIR"  
SectionEnd


Section "trcluster.dat" Seccluster
  File ..\target\trcluster.dat
SectionEnd


!ifdef TR4WLANG
Section "" SecLan
SetOutPath "$INSTDIR\${TR4WLANG}"
;	File ..\MakeRES\${TR4WLANG}\def.h
;	File ..\tr4w_consts_${TR4WLANG}.ini
	File ..\src\lang\tr4w_consts_${TR4WLANG}.pas
SectionEnd
!endif


Section "" SecSC
  CreateDirectory "$SMPROGRAMS\TR4W"
  CreateShortCut "$SMPROGRAMS\TR4W\TR4W.lnk" "$INSTDIR\tr4w.exe" "" "$INSTDIR\tr4w.exe" 0
  CreateShortCut "$SMPROGRAMS\TR4W\history.lnk" "$INSTDIR\history.txt" "" "$INSTDIR\history.txt" 0

!ifdef TR4WLANG
	!If ${TR4WLANG} == "rus"
		CreateShortCut "$SMPROGRAMS\TR4W\TR4W Help.lnk" "$INSTDIR\tr4w_manual_rus.chm" "" "" 0
	!endif
!endif  

  CreateDirectory "$INSTDIR\dxcluster"
  SetOutPath "$INSTDIR\dvk"
  SetOutPath "$INSTDIR\dvk\lettersandnumbers"
  SetOutPath "$INSTDIR\dvk\fullcallsigns"
  SetOutPath "$INSTDIR\dvk\fullserialnumbers"
  SetOutPath "$INSTDIR"
  SetOutPath "$INSTDIR\settings"

;    WriteRegStr HKCR ".TRW" "" "TR4W Log file"
	IfRebootFlag 0 noreboot
	MessageBox MB_YESNO "Reboot is required to finish the installation. Do you wish to reboot now?" IDNO noreboot
    Reboot
noreboot:

;ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
;ReadRegStr $0 HKLM Software\NSIS ""
;DetailPrint "VERSION: $R0"


SectionEnd