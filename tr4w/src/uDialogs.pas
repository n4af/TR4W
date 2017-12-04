{
 Copyright Dmitriy Gulyaev UA4WLI 2015.

 This file is part of TR4W  (SRC)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W in  GPL_License.TXT. 
If not, ref: 
http://www.gnu.org/licenses/gpl-3.0.txt
 }
unit uDialogs;
{$IMPORTEDDATA OFF}
interface

uses
//  shellapi,
  TF,
  VC,
  utils_file,
  Windows,
  Messages;

type
{ TSHItemID -- Item ID }
  PSHItemID = ^TSHItemID;
{$EXTERNALSYM _SHITEMID}
  _SHITEMID = record
    cb: Word; { Size of the ID (including cb itself) }
    abID: array[0..0] of Byte; { The item ID (variable length) }
  end;
  TSHItemID = _SHITEMID;
{$EXTERNALSYM SHITEMID}
  SHITEMID = _SHITEMID;

{ TItemIDList -- List if item IDs (combined with 0-terminator) }
  PItemIDList = ^TItemIDList;
{$EXTERNALSYM _ITEMIDLIST}
  _ITEMIDLIST = record
    mkid: TSHItemID;
  end;
  TItemIDList = _ITEMIDLIST;
{$EXTERNALSYM ITEMIDLIST}
  ITEMIDLIST = _ITEMIDLIST;

type
{$EXTERNALSYM BFFCALLBACK}
  BFFCALLBACK = function(wnd: HWND; uMsg: UINT; lParam, lpData: lParam): integer stdcall;
  TFNBFFCallBack = type BFFCALLBACK;

  PBrowseInfoA = ^TBrowseInfoA;
  PBrowseInfoW = ^TBrowseInfoW;
  PBrowseInfo = PBrowseInfoA;
{$EXTERNALSYM _browseinfoA}
  _browseinfoA = record
    hwndOwner: HWND;
    pidlRoot: PItemIDList;
    pszDisplayName: PAnsiChar; { Return display name of item selected. }
    lpszTitle: PAnsiChar; { text to go in the banner over the tree. }
    ulFlags: UINT; { Flags that control the return stuff }
    lpfn: TFNBFFCallBack;
    lParam: lParam; { extra info that's passed back in callbacks }
    iImage: integer; { output var: where to return the Image index. }
  end;
{$EXTERNALSYM _browseinfoW}
  _browseinfoW = record
    hwndOwner: HWND;
    pidlRoot: PItemIDList;
    pszDisplayName: PWideChar; { Return display name of item selected. }
    lpszTitle: PWideChar; { text to go in the banner over the tree. }
    ulFlags: UINT; { Flags that control the return stuff }
    lpfn: TFNBFFCallBack;
    lParam: lParam; { extra info that's passed back in callbacks }
    iImage: integer; { output var: where to return the Image index. }
  end;
{$EXTERNALSYM _browseinfo}
  _browseinfo = _browseinfoA;
  TBrowseInfoA = _browseinfoA;
  TBrowseInfoW = _browseinfoW;
  TBrowseInfo = TBrowseInfoA;
{$EXTERNALSYM BROWSEINFOA}
  BROWSEINFOA = _browseinfoA;
{$EXTERNALSYM BROWSEINFOW}
  BROWSEINFOW = _browseinfoW;
{$EXTERNALSYM BROWSEINFO}
  BROWSEINFO = BROWSEINFOA;

type
  PShellExecuteInfo = ^_SHELLEXECUTEINFOA;
  _SHELLEXECUTEINFOA = record
    cbSize: DWORD;
    fMask: ULONG;
    wnd: HWND;
    lpVerb: PAnsiChar;
    lpFile: PAnsiChar;
    lpParameters: PAnsiChar;
    lpDirectory: PAnsiChar;
    nShow: integer;
    hInstApp: hInst;
    { Optional fields }
    lpIDList: Pointer;
    lpClass: PAnsiChar;
    hkeyClass: hkey;
    dwHotKey: DWORD;
    HICON: THandle;
    hProcess: THandle;
  end;

const

{$EXTERNALSYM CDN_FIRST}
  CDN_FIRST                             = -601;
{$EXTERNALSYM CDN_LAST}
  CDN_LAST                              = -699;

  { Notifications when Open or Save dialog status changes }

{$EXTERNALSYM CDN_INITDONE}
  CDN_INITDONE                          = CDN_FIRST - 0;
{$EXTERNALSYM CDN_SELCHANGE}
  CDN_SELCHANGE                         = CDN_FIRST - 1;
{$EXTERNALSYM CDN_FOLDERCHANGE}
  CDN_FOLDERCHANGE                      = CDN_FIRST - 2;
{$EXTERNALSYM CDN_SHAREVIOLATION}
  CDN_SHAREVIOLATION                    = CDN_FIRST - 3;
{$EXTERNALSYM CDN_HELP}
  CDN_HELP                              = CDN_FIRST - 4;
{$EXTERNALSYM CDN_FILEOK}
  CDN_FILEOK                            = CDN_FIRST - 5;
{$EXTERNALSYM CDN_TYPECHANGE}
  CDN_TYPECHANGE                        = CDN_FIRST - 6;
{$EXTERNALSYM CDN_INCLUDEITEM}
  CDN_INCLUDEITEM                       = CDN_FIRST - 7;

{$EXTERNALSYM CDM_FIRST}
  CDM_FIRST                             = WM_USER + 100;
{$EXTERNALSYM CDM_LAST}
  CDM_LAST                              = WM_USER + 200;

  (*******************************************************************************
  Вызов диалога "Смена значка":
  var
   filename: String;
   iconindex: Integer;
  begin
   ChangeIconDialog(Handle, filename, iconindex);
   Edit1.Text:= filename;
   Edit2.Text:= IntToStr(iconindex);
  *******************************************************************************)
  //function ChangeIconDialog(hOwner: HWND; var FileName: string; var IconIndex: integer): boolean;

  //Вызов диалога "Цвет"
function SelectColor(hWin: HWND; FullOpen: boolean): TColorRef;

//Вызов диалога "Открыть с помощью..." для файла
//function OpenWith(hOpen: HWND; FileName: string): integer;

//Открытие диалога для выбора каталога
// Edit1 . Text := SelectFolder(Form1.Handle, nil, 'Выберите каталог...', '', True);
//function SelectFolder(hSelFolder: HWND; Text, Title: PChar; OutPutDir: string; showPath: BOOL): string;

// Диалог выбора директории с кнопкой "Создать папку"
//function SelectDirPlus(HWND: HWND; const Caption: string; const Root: WideString; Directory: string): string;

//Открытие диалога для выбора файла
//OpenFileDlg(Handle, Memo1.Handle, 'Текстовый документ (*.txt)'#0'*.txt'#0+'Все файлы (*.*)'#0'*.*'#0#0);
function OpenFileDlg(Title: PChar; hOpenFileOwner: HWND; FilterString: PChar; var fname: FileNameType; Flags: Cardinal): BOOL;

//procedure OpenPathDlg(hOpenFile: HWND; hControl: HWND; FilterString: PChar);

//Открытие диалога для сохранения файла
//SaveFileDlg(Handle, Memo1.Handle, 'Текстовый документ (*.txt)'#0'*.txt'#0#0)
procedure SaveFileDlg(hSaveFile: HWND; hControl: HWND; FilterString: PChar);

//Вызов диалога Windows "Свойства..."
//ShowProperties(Handle, 'C:\windows\regedit.exe');
//function ShowProperties(hwndOwner: HWND; const FileName: string): boolean;

//Следующие две процедуры открывают окно "Запуск программы" (Пуск/Выполнить)
//RunFileDlg(FindWindow('Shell_TrayWnd', nil), 0, PChar('InitialDir'),
// PChar('Запуск программы'), PChar('Введите имя программы, папки или документа, который требуется открыть.'), 0);
//For Win NT
//procedure RunFileDlgW(OwnerWnd: HWND; Icon: HICON; lpstrDirectory: PWideChar; lpstrTitle: PWideChar; lpstrDescription: PWideChar; Flags: LONGINT); stdcall;
//For Win 9x (Win NT to show standard captions )
//procedure RunFileDlg(OwnerWnd: HWND; Icon: HICON; lpstrDirectory: PChar; lpstrTitle: PChar; lpstrDescription: PChar; Flags: LONGINT); stdcall;

//Вызов диалога Windows "О программе..."
//ShowAboutDlg(handle, 'My Program', '(c) 2003 by LENIN INC', LoadIcon(hInstance, 'MAINICON'));
//function ShowAboutDlg(hAbout: HWND; Caption, Text: string; Icon: HICON): integer;

//Вызов диалога "Завершение работы Windows"
//ExitWindowsDialog(0)
//procedure ExitWindowsDialog(ParentWnd: HWND); stdcall;

//Вызов диалога "Изменение параметров системы"
//if RestartDialog(Handle, nil, EWX_REBOOT) = IDYES или IDNO then
//Параметр Flags может быть следующим:
//EWX_LOGOFF - Перезагрузка Windows и вход в систему под другим именем
//EWX_SHUTDOWN - Выключение компьютера
//EW_RESTARTWINDOWS - Перезагрузка Windows (легкая перезагрузка)
//EW_REBOOTSYSTEM - Перезагрузка системы
//EW_EXITANDEXECAPP - Перезагрузка компьютера в режиме MS-DOS

{ $ E X TERNALSYM SHBrowseForFolder}
//function SHBrowseForFolder(var lpbi: TBrowseInfo): PItemIDList; stdcall;
//function SHBrowseForFolder; external shell32 Name 'SHBrowseForFolderA';

{ $ E X TERNALSYM SHGetPathFromIDList}
//function SHGetPathFromIDList(pidl: PItemIDList; pszPath: PChar): BOOL; stdcall;
//function SHGetPathFromIDList; external shell32 Name 'SHGetPathFromIDListA';

function TR4W_OFNHookProc(wnd: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT {boolean} stdcall;

//function RestartDialog(ParentWnd: HWND; Reason: PAnsiChar; Flags: LONGINT): HResult; stdcall;

procedure SelectFolder(Parent: HWND; var Folder: FileNameType);

type

  TSHBrowseForFolder = function(var lpbi: TBrowseInfo): PItemIDList; stdcall;
  TSHGetPathFromIDList = function(pidl: PItemIDList; pszPath: PChar): BOOL; stdcall;

  POpenFilenameA = ^TOpenFilenameA;
  POpenFilenameW = ^TOpenFilenameW;
  POpenFilename = POpenFilenameA;
  TOpenFilenameA = packed record
    lStructSize: DWORD;
    hwndOwner: HWND;
    hInstance: hInst;
    lpstrFilter: PAnsiChar;
    lpstrCustomFilter: PAnsiChar;
    nMaxCustFilter: DWORD;
    nFilterIndex: DWORD;
    lpstrFile: PAnsiChar;
    nMaxFile: DWORD;
    lpstrFileTitle: PAnsiChar;
    nMaxFileTitle: DWORD;
    lpstrInitialDir: PAnsiChar;
    lpstrTitle: PAnsiChar;
    Flags: DWORD;
    nFileOffset: Word;
    nFileExtension: Word;
    lpstrDefExt: PAnsiChar;
    lCustData: lParam;
    lpfnHook: function(wnd: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT stdcall;
    lpTemplateName: PAnsiChar;
  end;
  TOpenFilenameW = packed record
    lStructSize: DWORD;
    hwndOwner: HWND;
    hInstance: hInst;
    lpstrFilter: PWideChar;
    lpstrCustomFilter: PWideChar;
    nMaxCustFilter: DWORD;
    nFilterIndex: DWORD;
    lpstrFile: PWideChar;
    nMaxFile: DWORD;
    lpstrFileTitle: PWideChar;
    nMaxFileTitle: DWORD;
    lpstrInitialDir: PWideChar;
    lpstrTitle: PWideChar;
    Flags: DWORD;
    nFileOffset: Word;
    nFileExtension: Word;
    lpstrDefExt: PWideChar;
    lCustData: lParam;
    lpfnHook: function(wnd: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT stdcall;
    lpTemplateName: PWideChar;
  end;
  TOpenFileName = TOpenFilenameA;

  TGetOpenFileNameFunc = function(var OpenFile: TOpenFilenameA): BOOL; stdcall;

const
  WM_USER                               = $0400;
  BFFM_INITIALIZED                      = 1;
  BFFM_SELCHANGED                       = 2;
  BFFM_SETSTATUSTEXTA                   = WM_USER + 100;
  BFFM_SETSTATUSTEXTW                   = WM_USER + 104;
  BFFM_SETSTATUSTEXT                    = BFFM_SETSTATUSTEXTA;
  BFFM_SETSELECTIONA                    = WM_USER + 102;
  BFFM_SETSELECTIONW                    = WM_USER + 103;
  BFFM_SETSELECTION                     = BFFM_SETSELECTIONA;
  BIF_RETURNONLYFSDIRS                  = $0001; { For finding a folder to start document searching }
  BIF_STATUSTEXT                        = $0004;

const
{$EXTERNALSYM OFN_READONLY}
  OFN_READONLY                          = $00000001;
{$EXTERNALSYM OFN_OVERWRITEPROMPT}
  OFN_OVERWRITEPROMPT                   = $00000002;
{$EXTERNALSYM OFN_HIDEREADONLY}
  OFN_HIDEREADONLY                      = $00000004;
{$EXTERNALSYM OFN_NOCHANGEDIR}
  OFN_NOCHANGEDIR                       = $00000008;
{$EXTERNALSYM OFN_SHOWHELP}
  OFN_SHOWHELP                          = $00000010;
{$EXTERNALSYM OFN_ENABLEHOOK}
  OFN_ENABLEHOOK                        = $00000020;
{$EXTERNALSYM OFN_ENABLETEMPLATE}
  OFN_ENABLETEMPLATE                    = $00000040;
{$EXTERNALSYM OFN_ENABLETEMPLATEHANDLE}
  OFN_ENABLETEMPLATEHANDLE              = $00000080;
{$EXTERNALSYM OFN_NOVALIDATE}
  OFN_NOVALIDATE                        = $00000100;
{$EXTERNALSYM OFN_ALLOWMULTISELECT}
  OFN_ALLOWMULTISELECT                  = $00000200;
{$EXTERNALSYM OFN_EXTENSIONDIFFERENT}
  OFN_EXTENSIONDIFFERENT                = $00000400;
{$EXTERNALSYM OFN_PATHMUSTEXIST}
  OFN_PATHMUSTEXIST                     = $00000800;
{$EXTERNALSYM OFN_FILEMUSTEXIST}
  OFN_FILEMUSTEXIST                     = $00001000;
{$EXTERNALSYM OFN_CREATEPROMPT}
  OFN_CREATEPROMPT                      = $00002000;
{$EXTERNALSYM OFN_SHAREAWARE}
  OFN_SHAREAWARE                        = $00004000;
{$EXTERNALSYM OFN_NOREADONLYRETURN}
  OFN_NOREADONLYRETURN                  = $00008000;
{$EXTERNALSYM OFN_NOTESTFILECREATE}
  OFN_NOTESTFILECREATE                  = $00010000;
{$EXTERNALSYM OFN_NONETWORKBUTTON}
  OFN_NONETWORKBUTTON                   = $00020000;
{$EXTERNALSYM OFN_NOLONGNAMES}
  OFN_NOLONGNAMES                       = $00040000;
{$EXTERNALSYM OFN_EXPLORER}
  OFN_EXPLORER                          = $00080000;
{$EXTERNALSYM OFN_NODEREFERENCELINKS}
  OFN_NODEREFERENCELINKS                = $00100000;
{$EXTERNALSYM OFN_LONGNAMES}
  OFN_LONGNAMES                         = $00200000;
{$EXTERNALSYM OFN_ENABLEINCLUDENOTIFY}
  OFN_ENABLEINCLUDENOTIFY               = $00400000;
{$EXTERNALSYM OFN_ENABLESIZING}
  OFN_ENABLESIZING                      = $00800000;
  { #if (_WIN32_WINNT >= 0x0500) }
{$EXTERNALSYM OFN_DONTADDTORECENT}
  OFN_DONTADDTORECENT                   = $02000000;
{$EXTERNALSYM OFN_FORCESHOWHIDDEN}
  OFN_FORCESHOWHIDDEN                   = $10000000; // Show All files including System and hidden files
  { #endif // (_WIN32_WINNT >= 0x0500) }

  { FlagsEx Values }
  { #if (_WIN32_WINNT >= 0x0500) }
{$EXTERNALSYM OFN_EX_NOPLACESBAR}
  OFN_EX_NOPLACESBAR                    = $00000001;
  { #endif // (_WIN32_WINNT >= 0x0500) }

{ Return values for the registered message sent to the hook function
  when a sharing violation occurs.  OFN_SHAREFALLTHROUGH allows the
  filename to be accepted, OFN_SHARENOWARN rejects the name but puts
  up no warning (returned when the app has already put up a warning
  message), and OFN_SHAREWARN puts up the default warning message
  for sharing violations.

  Note:  Undefined return values map to OFN_SHAREWARN, but are
         reserved for future use. }

{$EXTERNALSYM OFN_SHAREFALLTHROUGH}
  OFN_SHAREFALLTHROUGH                  = 2;
{$EXTERNALSYM OFN_SHARENOWARN}
  OFN_SHARENOWARN                       = 1;
{$EXTERNALSYM OFN_SHAREWARN}
  OFN_SHAREWARN                         = 0;

  {
const
  OFN_READONLY                    = $00000001;
  OFN_OVERWRITEPROMPT             = $00000002;
  OFN_HIDEREADONLY                = $00000004;
  OFN_NOCHANGEDIR                 = $00000008;
  OFN_SHOWHELP                    = $00000010;
  OFN_ENABLEHOOK                  = $00000020;
  OFN_ENABLETEMPLATE              = $00000040;
  OFN_ENABLETEMPLATEHANDLE        = $00000080;
  OFN_NOVALIDATE                  = $00000100;
  OFN_ALLOWMULTISELECT            = $00000200;
  OFN_EXTENSIONDIFFERENT          = $00000400;
  OFN_PATHMUSTEXIST               = $00000800;
  OFN_FILEMUSTEXIST               = $00001000;
  OFN_CREATEPROMPT                = $00002000;
  OFN_SHAREAWARE                  = $00004000;
  OFN_NOREADONLYRETURN            = $00008000;
  OFN_NOTESTFILECREATE            = $00010000;
  OFN_NONETWORKBUTTON             = $00020000;
  OFN_NOLONGNAMES                 = $00040000;
  OFN_EXPLORER                    = $00080000;
  OFN_NODEREFERENCELINKS          = $00100000;
  OFN_LONGNAMES                   = $00200000;
}
  WM_SETTEXT                            = $000C;
  EM_SETSEL                             = $00B1;
  WM_GETTEXT                            = $000D;

  { Note CLASSKEY overrides CLASSNAME }
{$EXTERNALSYM SEE_MASK_CLASSNAME}
  SEE_MASK_CLASSNAME                    = $00000001;
{$EXTERNALSYM SEE_MASK_CLASSKEY}
  SEE_MASK_CLASSKEY                     = $00000003;
  { Note INVOKEIDLIST overrides IDLIST }
{$EXTERNALSYM SEE_MASK_IDLIST}
  SEE_MASK_IDLIST                       = $00000004;
{$EXTERNALSYM SEE_MASK_INVOKEIDLIST}
  SEE_MASK_INVOKEIDLIST                 = $0000000C;
{$EXTERNALSYM SEE_MASK_ICON}
  SEE_MASK_ICON                         = $00000010;
{$EXTERNALSYM SEE_MASK_HOTKEY}
  SEE_MASK_HOTKEY                       = $00000020;
{$EXTERNALSYM SEE_MASK_NOCLOSEPROCESS}
  SEE_MASK_NOCLOSEPROCESS               = $00000040;
{$EXTERNALSYM SEE_MASK_CONNECTNETDRV}
  SEE_MASK_CONNECTNETDRV                = $00000080;
{$EXTERNALSYM SEE_MASK_FLAG_DDEWAIT}
  SEE_MASK_FLAG_DDEWAIT                 = $00000100;
{$EXTERNALSYM SEE_MASK_DOENVSUBST}
  SEE_MASK_DOENVSUBST                   = $00000200;
{$EXTERNALSYM SEE_MASK_FLAG_NO_UI}
  SEE_MASK_FLAG_NO_UI                   = $00000400;
{$EXTERNALSYM SEE_MASK_UNICODE}
  SEE_MASK_UNICODE                      = $00010000; // !!! changed from previous SDK (was $00004000)
{$EXTERNALSYM SEE_MASK_NO_CONSOLE}
  SEE_MASK_NO_CONSOLE                   = $00008000;
{$EXTERNALSYM SEE_MASK_ASYNCOK}
  SEE_MASK_ASYNCOK                      = $00100000;

  //function SHGetPathFromIDListA(pidl: PItemIDList; pszPath: PAnsiChar): BOOL; stdcall;
  //function SHGetPathFromIDListW(pidl: PItemIDList; pszPath: PWideChar): BOOL; stdcall;
  //function SHGetPathFromIDList(pidl: PItemIDList; pszPath: PChar): BOOL; stdcall;
  //function SHBrowseForFolderA(var lpbi: TBrowseInfoA): PItemIDList; stdcall;
  //function SHBrowseForFolderW(var lpbi: TBrowseInfoW): PItemIDList; stdcall;
  //function SHBrowseForFolder(var lpbi: TBrowseInfo): PItemIDList; stdcall;
function GetOpenFileNameA(var OpenFile: TOpenFilenameA): BOOL; stdcall;
function GetOpenFileNameW(var OpenFile: TOpenFilenameW): BOOL; stdcall;

function GetOpenFileName(var OpenFile: TOpenFileName): BOOL; stdcall;

function GetSaveFileNameA(var OpenFile: TOpenFilenameA): BOOL; stdcall;
function GetSaveFileNameW(var OpenFile: TOpenFilenameW): BOOL; stdcall;
function GetSaveFileName(var OpenFile: TOpenFileName): BOOL; stdcall;

function CommDlgExtendedError: DWORD; stdcall;

{ $ EXTERNALSYM ShellExecuteEx}
//function ShellExecuteEx(lpExecInfo: PShellExecuteInfo): BOOL; stdcall;

const
  { registry entries for special paths are kept in : }
  REGSTR_PATH_SPECIAL_FOLDERS           = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders';
  CSIDL_DESKTOP                         = $0000;
  CSIDL_PROGRAMS                        = $0002;
  CSIDL_CONTROLS                        = $0003;
  CSIDL_PRINTERS                        = $0004;
  CSIDL_PERSONAL                        = $0005;
  CSIDL_FAVORITES                       = $0006;
  CSIDL_STARTUP                         = $0007;
  CSIDL_RECENT                          = $0008;
  CSIDL_SENDTO                          = $0009;
  CSIDL_BITBUCKET                       = $000A;
  CSIDL_STARTMENU                       = $000B;
  CSIDL_DESKTOPDIRECTORY                = $0010;
  CSIDL_DRIVES                          = $0011;
  CSIDL_NETWORK                         = $0012;
  CSIDL_NETHOOD                         = $0013;
  CSIDL_FONTS                           = $0014;
  CSIDL_TEMPLATES                       = $0015;
  CSIDL_COMMON_STARTMENU                = $0016;
  CSIDL_COMMON_PROGRAMS                 = $0017;
  CSIDL_COMMON_STARTUP                  = $0018;
  CSIDL_COMMON_DESKTOPDIRECTORY         = $0019;
  CSIDL_APPDATA                         = $001A;
  CSIDL_PRINTHOOD                       = $001B;

//  function SHGetSpecialFolderLocation(hwndOwner: HWND; nFolder: integer;   var ppidl: PItemIDList): HResult; stdcall;

const
  MAXSIZE                               = 260;
  MemSize                               = 65535;

var

  CurrentDir                            : PChar;
  hDlg                                  : DWORD;
  hWndMenu                              : THandle;
  ofn                                   : TOpenFileName; // = (lStructSize: SizeOf(TOpenFileName); nMaxFile: MAXSIZE; lpstrInitialDir: nil);
  sFile                                 : PChar;
  sFilePath                             : PChar;
  // s              : String;
  Lenin_Buffer                          : array[0..MAXSIZE - 1] of Char;
  hFile                                 : THandle;
  hMemory                               : THandle;
  pMemory                               : Pointer;
  SizeReadWrite                         : DWORD;
  ModifyFlag                            : integer;
  FirstCDN_SELCHANGE                    : boolean;

  FileNameEdit                          : HWND;
  //  LB                                    : HWND;

const
  RFF_NOBROWSE                          = 1; //Removes the browse button.
  RFF_NODEFAULT                         = 2; // No default item selected.
  RFF_CALCDIRECTORY                     = 4; // Calculates the working directory from the file name.
  RFF_NOLABEL                           = 8; // Removes the edit box label.
  RFF_NOSEPARATEMEM                     = 14; // Removes the Separate Memory Space check box (Windows NT only).

type
  PChooseColorA = ^TChooseColorA;
  PChooseColorW = ^TChooseColorW;
  PChooseColor = PChooseColorA;
  TChooseColorA = packed record
    lStructSize: DWORD;
    hwndOwner: HWND;
    hInstance: HWND;
    rgbResult: COLORREF;
    lpCustColors: ^COLORREF;
    Flags: DWORD;
    lCustData: lParam;
    lpfnHook: function(wnd: HWND; Message: UINT; wParam: wParam; lParam: lParam): UINT stdcall;
    lpTemplateName: PAnsiChar;
  end;
  TChooseColorW = packed record
    lStructSize: DWORD;
    hwndOwner: HWND;
    hInstance: HWND;
    rgbResult: COLORREF;
    lpCustColors: ^COLORREF;
    Flags: DWORD;
    lCustData: lParam;
    lpfnHook: function(wnd: HWND; Message: UINT; wParam: wParam; lParam: lParam): UINT stdcall;
    lpTemplateName: PWideChar;
  end;
  TCHOOSECOLOR = TChooseColorA;

function ChooseColorA(var CC: TChooseColorA): BOOL; stdcall;
function ChooseColorW(var CC: TChooseColorW): BOOL; stdcall;
function ChooseColor(var CC: TCHOOSECOLOR): BOOL; stdcall;

const
  CC_RGBINIT                            = $00000001;
  CC_FULLOPEN                           = $00000002;
  CC_PREVENTFULLOPEN                    = $00000004;
  CC_SHOWHELP                           = $00000008;
  CC_ENABLEHOOK                         = $00000010;
  CC_ENABLETEMPLATE                     = $00000020;
  CC_ENABLETEMPLATEHANDLE               = $00000040;
  CC_SOLIDCOLOR                         = $00000080;
  CC_ANYCOLOR                           = $00000100;

  OpenMMTTYFlags                        = OFN_ENABLESIZING or OFN_NOREADONLYRETURN or OFN_EXPLORER or OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_HIDEREADONLY;
  OpenCFGFlags                          =
    OFN_ENABLESIZING or
    OFN_NOREADONLYRETURN or
    OFN_EXPLORER or
    OFN_ENABLEHOOK or
    OFN_FILEMUSTEXIST or
    OFN_SHOWHELP or
    OFN_PATHMUSTEXIST or
    OFN_LONGNAMES or
    OFN_HIDEREADONLY;

var
  szFile                                : array[0..2048] of Char {= ''};
  //   tr4w_opencfgfile_dialog_but_hwnd: array[0..2] of HWND;

implementation
uses MainUnit;
//const   myshell32                         = 'shell32.dll';

function ChooseColorA; external 'comdlg32.dll' Name 'ChooseColorA';
function ChooseColorW; external 'comdlg32.dll' Name 'ChooseColorW';
function ChooseColor; external 'comdlg32.dll' Name 'ChooseColorA';

//procedure RunFileDlgW; EXTERNAL shell32 Index 61;
//procedure RunFileDlg; EXTERNAL shell32 Index 61;
//procedure ExitWindowsDialog; EXTERNAL shell32 Index 60;
//function RestartDialog; EXTERNAL shell32 Index 59;
//function SHGetPathFromIDListA; EXTERNAL shell32 Name 'SHGetPathFromIDListA';
//function SHGetPathFromIDListW; EXTERNAL shell32 Name 'SHGetPathFromIDListW';
//function SHGetPathFromIDList; EXTERNAL shell32 Name 'SHGetPathFromIDListA';
//function SHGetSpecialFolderLocation; EXTERNAL shell32 Name 'SHGetSpecialFolderLocation';
//function SHBrowseForFolderA; EXTERNAL shell32 Name 'SHBrowseForFolderA';
//function SHBrowseForFolderW; EXTERNAL shell32 Name 'SHBrowseForFolderW';
//function SHBrowseForFolder; EXTERNAL shell32 Name 'SHBrowseForFolderA';
function GetOpenFileNameA; external 'comdlg32.dll' Name 'GetOpenFileNameA';
function GetOpenFileNameW; external 'comdlg32.dll' Name 'GetOpenFileNameW';

function GetOpenFileName; external 'comdlg32.dll' Name 'GetOpenFileNameA';

function GetSaveFileNameA; external 'comdlg32.dll' Name 'GetSaveFileNameA';
function GetSaveFileNameW; external 'comdlg32.dll' Name 'GetSaveFileNameW';
function GetSaveFileName; external 'comdlg32.dll' Name 'GetSaveFileNameA';
function CommDlgExtendedError; external 'comdlg32.dll' Name 'CommDlgExtendedError';

{
function ChangeIconDialog(hOwner: HWND; var FileName: string; var IconIndex: integer): boolean;
type
   SHChangeIconProc = function(wnd: HWND; szFileName: PChar; Reserved: integer; var lpIconIndex: integer): DWORD; stdcall;
   SHChangeIconProcW = function(wnd: HWND; szFileName: PWideChar; Reserved: integer; var lpIconIndex: integer): DWORD; stdcall;
var
   ShellHandle                     : HWND;
   SHChangeIcon                    : SHChangeIconProc;
   SHChangeIconW                   : SHChangeIconProcW;
   buf                             : array[0..MAX_PATH] of Char;
   BufW                            : array[0..MAX_PATH] of widechar;
begin
   Result := False;
   SHChangeIcon := nil;
   SHChangeIconW := nil;
   ShellHandle := LoadLibrary(PChar(Shell32));
   try
      if ShellHandle <> 0 then
         begin
            if Win32Platform = VER_PLATFORM_WIN32_NT
               then SHChangeIconW := GetProcAddress(ShellHandle, PChar(62))
            else SHChangeIcon := GetProcAddress(ShellHandle, PChar(62));
         end;
      if Assigned(SHChangeIconW) then
         begin
            StringToWideChar(FileName, BufW, SizeOf(BufW));
            Result := SHChangeIconW(hOwner, BufW, SizeOf(BufW), IconIndex) = 1;
            if Result then FileName := BufW;
         end else
         if Assigned(SHChangeIcon) then
            begin
               StrPCopy(buf, FileName);
               Result := SHChangeIcon(hOwner, buf, SizeOf(buf), IconIndex) = 1;
               if Result then FileName := buf;
            end;
   finally
      if ShellHandle <> 0 then FreeLibrary(ShellHandle);
   end;
end;
}

function SelectColor(hWin: HWND; FullOpen: boolean): TColorRef;
var
  custColors                            : array[0..15] of COLORREF; // массив с преопределенными цветами
  CC                                    : TCHOOSECOLOR;
begin
  CC.lStructSize := SizeOf(TCHOOSECOLOR);
  CC.hwndOwner := hWin;
  if FullOpen
    then CC.Flags := CC_RGBINIT or CC_FULLOPEN
  else CC.Flags := CC_RGBINIT;
  CC.hInstance := hWin;
  CC.lpCustColors := @custColors[0];
  CC.rgbResult := GetSysColor(COLOR_BTNFACE);
  if ChooseColor(CC) then
  begin
    SetClassLong(hWin, GCL_HBRBACKGROUND { or GCL_CBCLSEXTRA}, CreateSolidBrush(CC.rgbResult));
    Result := CC.rgbResult;
  end else Result := INVALID_HANDLE_VALUE;
end;
{
function ShowAboutDlg(hAbout: HWND; Caption, Text: string; Icon: HICON): integer;
begin
  Result := ShellAbout(hAbout, PChar(Caption), PChar(Text), Icon);
end;
}
{
function OpenWith(hOpen: HWND; FileName: string): integer;
begin
  Result := Shellexecute(hOpen, 'open', 'Rundll32.exe', PChar('shell32.dll,OpenAs_RunDLL ' + FileName), nil, SW_SHOW);
end;
}
{
function SHCallBack(hCallBack: HWND; Msg: integer; wParam, lParam: integer): integer; STDCALL;
var
   p                               : array[0..255] of Char;
begin
   case Msg of
      BFFM_SELCHANGED:
         begin
            SHGetPathFromIDList(PItemIDList(wParam), p);
            SendMessage(hCallBack, BFFM_SETSTATUSTEXT, 0, integer(@p[0]));
         end;
      BFFM_INITIALIZED:
         SendMessage(hCallBack, BFFM_SETSELECTION, 1, integer(CurrentDir));
   end;
   Result := 0;
end;
}
{
function SelectFolder(hSelFolder: HWND; Text, Title: PChar; OutPutDir: string; showPath: BOOL): string;
var
  pidlRoot, resPIDL                     : PItemIDList;
  tbi                                   : TBrowseInfoA;
  Name, Path                            : array[0..MAX_PATH] of Char;
begin
  CurrentDir := @OutPutDir[1];
  SHGetSpecialFolderLocation(hSelFolder, CSIDL_DRIVES, pidlRoot);
  tbi.pidlRoot := pidlRoot;
  tbi.lpszTitle := Title;
  if (Text <> nil) or showPath then
    tbi.ulFlags := BIF_RETURNONLYFSDIRS or BIF_STATUSTEXT
  else
    tbi.ulFlags := BIF_RETURNONLYFSDIRS;
  tbi.lpfn := @SHCallBack;
  tbi.hwndOwner := hSelFolder;
  tbi.pszDisplayName := Name;
  resPIDL := SHBrowseForFolder(tbi);
  if resPIDL <> nil then
  begin
    SHGetPathFromIDList(resPIDL, Path);
    RESULT := Path;
  end else RESULT := '';
end;
}
{
function SelectDirPlus(HWND: HWND; const Caption: string; const Root: WideString; Directory: string): string;
// Диалог выбора директории с кнопкой "Создать папку"
var
   //  WindowList: Pointer;
  BrowseInfo                  : TBrowseInfo;
  Buffer                      : PChar;
  RootItemIDList, ItemIDList  : PItemIDList;
  ShellMalloc                 : IMalloc;
  IDesktopFolder              : IShellFolder;
begin
  Result := '';
  FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
  if (ShGetMalloc(ShellMalloc) = S_OK) and (ShellMalloc <> nil) then
  begin
    Buffer := ShellMalloc.Alloc(MAX_PATH);
    try
      RootItemIDList := nil;
      if Root <> '' then
        SHGetDesktopFolder(IDesktopFolder);
      with BrowseInfo do
      begin
        hwndOwner := HWND;
        pidlRoot := RootItemIDList;
        pszDisplayName := Buffer;
        lpfn := @SHCallBack;
        lParam := integer(PChar(Directory));
        lpszTitle := PChar(Caption);
        ulFlags := BIF_RETURNONLYFSDIRS or $0040 or $0010 or BIF_STATUSTEXT;
      end;
            //wli    WindowList := DisableTaskWindows(0);
      try
        ItemIDList := SHBrowseForFolder(BrowseInfo);
      finally
               //wli       EnableTaskWindows(WindowList);
      end;
      if ItemIDList <> nil then
      begin
        SHGetPathFromIDList(ItemIDList, Buffer);
        Result := Buffer;
        ShellMalloc.Free(ItemIDList);
        Directory := Buffer;
      end;
    finally
      ShellMalloc.Free(Buffer);
    end;
  end;
end;
}
{
function EnumWindowsProc(wnd: HWND; l: lParam): BOOL; STDCALL;
const
   ClassNameLen                    = 512;
var
   ClassName                       : array[0..ClassNameLen - 1] of Char;
   MaxTop                          : integer;
   temprect                        : TRect;

begin
   MaxTop := 0;
   GetClassName(wnd, ClassName, ClassNameLen);
   ClassName[ClassNameLen - 1] := #0;
   if ClassName = 'Button' then
      begin
         Windows.GetWindowRect(wnd, temprect);
         if temprect.Top > MaxTop then
            begin
               MaxTop := temprect.Top;
//               HelpButton := wnd;
//               showint(GetDlgCtrlID(HelpButton));
            end;
      end;
   //   if ClassName = 'Edit' then      FileNameEdit := wnd;

   EnumChildWindows(wnd, @EnumWindowsProc, 0);
   Result := True;
end;
}

function TR4W_OFNHookProc(wnd: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT {boolean} stdcall;
var
  rec                                   : TRect;
  p                                     : HWND;
  //   IconWindow                      : HWND;
  HelpButton                            : HWND;
begin
  Result := 0 {False};
  //   inc(arrayindex);
  //   ar[arrayindex] := Msg;

  case Msg of

    WM_NOTIFY:
      begin
        if PNMHdr(lParam)^.code = CDN_HELP then
        begin
          TR4W_LOG_FILENAME[0] := '_';
//          PostMessage(GetParent(wnd), WM_CLOSE, 0, 0);
          PostMessage(GetParent(wnd), WM_COMMAND, {Windows.MakeWParam(-IDABORT-IDCANCEL, BN_CLICKED)} 2, 0);
        end;

        if PNMHdr(lParam)^.code = CDN_SELCHANGE then
          if FirstCDN_SELCHANGE then
          begin
            p := GetParent(wnd);
            Windows.GetWindowRect(p, rec);
            SetWindowPos(p, 0, rec.Left, rec.Top, 550, 500, SWP_DRAWFRAME or SWP_NOACTIVATE or SWP_NOZORDER);
            Windows.GetWindowRect(HelpButton, rec);
            SendMessage(p, WM_NEXTDLGCTL, 1, 0);
            FirstCDN_SELCHANGE := False;
          end;
      end;

    {
          ////      WM_TIMER:
          WM_UPDATEUISTATE:
             begin
                //   KILLTIMER(wnd, 1);
                   p := GetParent(wnd);
                   Windows.GetWindowRect(p, rec);
                   SetWindowPos(p, 0, rec.Left, rec.Top, 550, 500, SWP_DRAWFRAME or SWP_NOACTIVATE or SWP_NOZORDER);
                   Windows.GetWindowRect(HelpButton, rec);
                   SendMessage(p, WM_NEXTDLGCTL, 1, 0);
             end;
    }
    WM_INITDIALOG:
      begin
        SetClassLong(wnd, GCL_HICON, LoadIcon(hInstance, 'MAINICON'));

        p := GetParent(wnd);
        //EnumChildWindows(p, @EnumWindowsProc, 0);
        HelpButton := GetDlgItem(p, 1038);
        Windows.SetWindowText(HelpButton, '&Start a new contest');
        Windows.SetWindowLong(HelpButton, GWL_STYLE, $50012000);
        Windows.GetWindowRect(HelpButton, rec);
        MapWindowPoints(0, p, rec, 2);
        SetWindowPos(HelpButton, 0, rec.Left, rec.Top + 30, 75, 33, SWP_DRAWFRAME or SWP_NOACTIVATE or SWP_NOZORDER);

        HelpButton := tCreateStaticWindow(nil, WS_CHILD or SS_ICON or WS_VISIBLE, 10, rec.Top + 30, 0, 0, p, 0);
        SendMessage(HelpButton, STM_SETIMAGE, IMAGE_ICON, LoadIcon(hInstance, 'MAINICON'));
        tCreateStaticWindow(TR4W_CURRENTVERSION, WS_CHILD or WS_VISIBLE, 50, rec.Top + 50, 200, 20, p, 0);
        Windows.GetWindowRect(p, rec);
        SetWindowPos(p, 0, (GetSystemMetrics(SM_CXSCREEN) - 550) div 2, (GetSystemMetrics(SM_CYSCREEN) - 450) div 2, 430, 350, SWP_DRAWFRAME or SWP_NOACTIVATE or SWP_NOZORDER);
        // SetTimer(wnd, 1, 10, nil);
        FirstCDN_SELCHANGE := True;
      end;

  end;

end;

function OpenFileDlg(Title: PChar; hOpenFileOwner: HWND; FilterString: PChar; var fname: FileNameType; Flags: Cardinal): BOOL;
label
  1;
var
  l                                     : integer;
  CommDlgLibHandle                      : DWORD;
  OpenFileF                             : TGetOpenFileNameFunc;
begin
  Result := False;
  CommDlgLibHandle := LoadLibrary('comdlg32.dll');
  if CommDlgLibHandle = 0 then Exit;
  @OpenFileF := GetProcAddress(CommDlgLibHandle, 'GetOpenFileNameA');
  if @OpenFileF = nil then goto 1;
  ofn.lStructSize := SizeOf(TOpenFileName);
  ofn.nMaxFile := MAXSIZE;

  ofn.hwndOwner := hOpenFileOwner;
  ofn.hInstance := hInstance;
  ofn.lpstrFilter := FilterString;
  //Windows.ZeroMemory(@fname, SizeOf(fname));
  ofn.lpstrFile := fname;
  //ofn.nMaxFile := MAXSIZE;
  //ofn.lpstrInitialDir := nil;//@TR4W_PATH_NAME;
  ofn.Flags := Flags{ or OFN_FILEMUSTEXIST} ;   // issue 289

  ofn.lpstrTitle := Title;
//  ofn.lpfnHook := @TR4W_OFNHookProc;
//  Result := GetOpenFileName(ofn);
//  ShowMessage(SysErrorMessage(CommDlgExtendedError));

  Result := OpenFileF(ofn);

  1:
  FreeLibrary(CommDlgLibHandle);
end;
{
procedure OpenPathDlg(hOpenFile: HWND; hControl: HWND; FilterString: PChar);
begin
   ofn.lStructSize := SizeOf(TOpenFileName);
   ofn.hwndOwner := hOpenFile;
   ofn.hInstance := hInstance;
   ofn.lpstrFilter := FilterString;
   ofn.lpstrFile := wsprintfBuffer //Lenin_Buffer;
   ofn.nMaxFile := MAXSIZE;
   ofn.Flags := OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_HIDEREADONLY;
   if GetOpenFileName(ofn)
      then SendMessage(hControl, WM_SETTEXT, 0, integer(ofn.lpstrFile))
   else SendMessage(hControl, EM_SETSEL, 0, 0);
end;
}

procedure SaveFileDlg(hSaveFile: HWND; hControl: {THandle wli} HWND; FilterString: PChar);
begin
  ofn.lStructSize := SizeOf(TOpenFileName);
  ofn.hwndOwner := hSaveFile;
  ofn.hInstance := hInstance;
  ofn.lpstrFilter := FilterString;
  ofn.lpstrFile := wsprintfBuffer {Lenin_Buffer};
  ofn.lpstrDefExt := 'txt';
  ofn.nMaxFile := MAXSIZE;
  ofn.Flags := OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_HIDEREADONLY;
  if GetSaveFileName(ofn) then
  begin
    hFile := CreateFile(wsprintfBuffer {Lenin_Buffer}, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or
      FILE_SHARE_WRITE, nil, CREATE_NEW, FILE_ATTRIBUTE_ARCHIVE, 0);
    hMemory := GlobalAlloc(GMEM_MOVEABLE or GMEM_ZEROINIT, MemSize);
    pMemory := GlobalLock(hMemory);
    SizeReadWrite := SendMessage(hControl, WM_GETTEXT, MemSize - 1, integer(pMemory));
    tWriteFile(hFile, pMemory^, SizeReadWrite, SizeReadWrite);
    SendMessage(hControl, EM_SETSEL, 0, 0);
    sFilePath := ofn.lpstrFile;
    sFile := PChar(@ofn.lpstrFile[ofn.nFileOffset]);
    CloseHandle(hFile);
    GlobalUnlock(DWORD(pMemory));
    GlobalFree(hMemory);
    EnableMenuItem(hWndMenu, 1030, MF_ENABLED);
    ModifyFlag := 0;
  end;
end;

procedure SelectFolder(Parent: HWND; var Folder: FileNameType);
var
  lpItemID                              : PItemIDList;
  BrowseInfo                            : TBrowseInfo;
  DisplayName                           : array[0..MAX_PATH] of Char;
  SHBrowseForFolder                     : TSHBrowseForFolder;
  SHGetPathFromIDList                   : TSHGetPathFromIDList;
begin
  if Shell32LibHandle = 0 then Shell32LibHandle := LoadLibrary('shell32.dll');
  if Shell32LibHandle <> 0 then
  begin
    @SHBrowseForFolder := GetProcAddress(Shell32LibHandle, 'SHBrowseForFolderA');
    @SHGetPathFromIDList := GetProcAddress(Shell32LibHandle, 'SHGetPathFromIDListA');
    if @SHBrowseForFolder <> nil then
    begin
      Windows.ZeroMemory(@BrowseInfo, SizeOf(TBrowseInfo));
      BrowseInfo.hwndOwner := tr4whandle;
      BrowseInfo.pszDisplayName := DisplayName;
      BrowseInfo.ulFlags := BIF_RETURNONLYFSDIRS;
      lpItemID := SHBrowseForFolder(BrowseInfo);
      if lpItemId <> nil then
      begin
        SHGetPathFromIDList(lpItemID, Folder);
        GlobalFreePtr(lpItemID);
      end;
    end;
    FreeLibrary(Shell32LibHandle);
  end;

{
  FillChar(BrowseInfo, SizeOf(TBrowseInfo), #0);
  BrowseInfo.hwndOwner := tr4whandle;
  BrowseInfo.pszDisplayName := DisplayName;
  BrowseInfo.ulFlags := BIF_RETURNONLYFSDIRS;
  lpItemID := SHBrowseForFolder(BrowseInfo);
  if lpItemId <> nil then
  begin
    SHGetPathFromIDList(lpItemID, Folder);
    GlobalFreePtr(lpItemID);
  end;
}
end;

{
function ShowProperties(hwndOwner: HWND; const FileName: string): boolean;
var
  Info                                  : _SHELLEXECUTEINFOA;
begin
//   Fill in the SHELLEXECUTEINFO structure
  with Info do
  begin
    cbSize := SizeOf(Info);
    fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_INVOKEIDLIST or SEE_MASK_FLAG_NO_UI;
    wnd := hwndOwner;
    lpVerb := 'properties';
    lpFile := PChar(FileName);
    lpParameters := nil;
    lpDirectory := nil;
    nShow := 0;
    hInstApp := 0;
    lpIDList := nil;
  end;
   //Call Windows to display the properties dialog
  Result := ShellExecuteEx(@Info);
end;
}
//function ShellExecuteEx; external shell32 Name 'ShellExecuteExA';

end.

