unit uTrayBalloon;

interface

uses
  VC, TF, Windows, Messages {, ShellAPI};

function Balloon_AddTrayIcon(hWin: HWND; ID: Cardinal; Icon: HICON; CallbackMessage: Cardinal; Hint: ShortString): boolean;
function Balloon_ShowTrayTips(TipInfo: ShortString): boolean;
function Balloon_DeleteTrayIcon: boolean;
function ShowTrayTips(TipInfo: ShortString): boolean;

type

  PNotifyIconDataA = ^TNotifyIconDataA;
  PNotifyIconDataW = ^TNotifyIconDataW;
  PNotifyIconData = PNotifyIconDataA;
{$EXTERNALSYM _NOTIFYICONDATAA}
  _NOTIFYICONDATAA = record
    cbSize: DWORD;
    wnd: HWND;
    uId: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    HICON: HICON;
    szTip: array[0..63] of AnsiChar;
  end;
{$EXTERNALSYM _NOTIFYICONDATAW}
  _NOTIFYICONDATAW = record
    cbSize: DWORD;
    wnd: HWND;
    uId: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    HICON: HICON;
    szTip: array[0..63] of widechar;
  end;
{$EXTERNALSYM _NOTIFYICONDATA}
  _NOTIFYICONDATA = _NOTIFYICONDATAA;
  TNotifyIconDataA = _NOTIFYICONDATAA;
  TNotifyIconDataW = _NOTIFYICONDATAW;
  TNotifyIconData = TNotifyIconDataA;
{$EXTERNALSYM NOTIFYICONDATAA}
  NOTIFYICONDATAA = _NOTIFYICONDATAA;
{$EXTERNALSYM NOTIFYICONDATAW}
  NOTIFYICONDATAW = _NOTIFYICONDATAW;
{$EXTERNALSYM NOTIFYICONDATA}
  NOTIFYICONDATA = NOTIFYICONDATAA;

  FShell_NotifyIcon = function(dwMessage: DWORD; lpData: PNotifyIconData): BOOL; stdcall;
//function Shell_NotifyIcon(dwMessage: DWORD; lpData: PNotifyIconData): BOOL; stdcall;

(*******************************************************************************
 TRAY_CALLBACK:
  case Msg.lParam of
    WM_MOUSEMOVE:
    WM_LBUTTONDOWN:
    WM_LBUTTONUP:
    WM_LBUTTONDBLCLK:
    WM_RBUTTONDOWN:
    WM_RBUTTONUP:
    WM_RBUTTONDBLCLK:
    NIN_BALLOONSHOW:
    NIN_BALLOONHIDE:
    NIN_BALLOONTIMEOUT:
    NIN_BALLOONUSERCLICK:
  end;
*******************************************************************************)

const
  NIF_INFO                              = $10;
  NIF_MESSAGE                           = 1;
  NIF_ICON                              = 2;
  NOTIFYICON_VERSION                    = 3;
  NIF_TIP                               = 4;
  NIM_SETVERSION                        = $00000004;
  NIM_SETFOCUS                          = $00000003;
  NIIF_INFO                             = $00000001;
  NIIF_WARNING                          = $00000002;
  NIIF_ERROR                            = $00000003;
  NIN_BALLOONSHOW                       = WM_USER + 2;
  NIN_BALLOONHIDE                       = WM_USER + 3;
  NIN_BALLOONTIMEOUT                    = WM_USER + 4;
  NIN_BALLOONUSERCLICK                  = WM_USER + 5;
  NIN_SELECT                            = WM_USER + 0;
  NINF_KEY                              = $1;
  NIN_KEYSELECT                         = NIN_SELECT or NINF_KEY;

const
  NIM_ADD                               = $00000000;
  NIM_MODIFY                            = $00000001;
  NIM_DELETE                            = $00000002;
//  NIF_MESSAGE                           = $00000001;
//  NIF_ICON                              = $00000002;
//  NIF_TIP                               = $00000004;

  {define the callback message}
  TRAY_CALLBACK                         = WM_USER + $7258;

  {new NotifyIconData structure definition}
type
  PNewNotifyIconData = ^TNewNotifyIconData;
  TDUMMYUNIONNAME = record
    case integer of
      0: (uTimeout: UINT);
      1: (uVersion: UINT);
  end;

  TNewNotifyIconData = record
    cbSize: DWORD;
    wnd: HWND;
    uId: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    HICON: HICON;
  //Version 5.0 is 128 chars, old ver is 64 chars
    szTip: array[0..127] of Char;
    dwState: DWORD; //Version 5.0
    dwStateMask: DWORD; //Version 5.0
    szInfo: array[0..255] of Char; //Version 5.0
    DUMMYUNIONNAME: TDUMMYUNIONNAME;
    szInfoTitle: array[0..63] of Char; //Version 5.0
    dwInfoFlags: DWORD; //Version 5.0
  end;

var
  IconData                              : TNewNotifyIconData;
  tShell_NotifyIcon                     : FShell_NotifyIcon;
  TrayBallonDisplayed                   : boolean;
//  TR4WREMINDER                          : PChar = 'TR4W';

implementation

function Balloon_AddTrayIcon(hWin: HWND; ID: Cardinal; Icon: HICON; CallbackMessage: Cardinal; Hint: ShortString): boolean;
begin
  IconData.cbSize := SizeOf(IconData);
  IconData.wnd := hWin;
  IconData.uId := ID;
  IconData.uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
  IconData.uCallbackMessage := CallbackMessage;
  IconData.HICON := Icon;
  Windows.CopyMemory(@IconData.szTip, @Hint[1], length(Hint));
  Result := tShell_NotifyIcon(NIM_ADD, @IconData);
end;

function Balloon_ShowTrayTips(TipInfo: ShortString): boolean;
begin
  IconData.cbSize := SizeOf(IconData);
  IconData.uFlags := NIF_INFO;
  Windows.CopyMemory(@IconData.szInfo, @TipInfo[1], length(TipInfo));
  IconData.DUMMYUNIONNAME.uTimeout := 60;
  Windows.CopyMemory(@IconData.szInfoTitle, @tr4w_ClassName, length(tr4w_ClassName));
  IconData.dwInfoFlags := NIIF_INFO;
  tShell_NotifyIcon(NIM_MODIFY, @IconData);
  IconData.DUMMYUNIONNAME.uVersion := NOTIFYICON_VERSION;
  Result := tShell_NotifyIcon(NIM_SETVERSION, @IconData);
end;

function Balloon_DeleteTrayIcon: boolean;
begin
  Result := tShell_NotifyIcon(NIM_DELETE, @IconData);
  TrayBallonDisplayed := False;
end;

function ShowTrayTips(TipInfo: ShortString): boolean;
begin
  if Shell32LibHandle = 0 then Shell32LibHandle := LoadLibrary('shell32.dll');
  if Shell32LibHandle <> 0 then
  begin
    @tShell_NotifyIcon := GetProcAddress(Shell32LibHandle, 'Shell_NotifyIcon');
    if @tShell_NotifyIcon <> nil then
    begin
      if TrayBallonDisplayed then Balloon_DeleteTrayIcon;
      if Balloon_AddTrayIcon(tr4whandle, 11, tr4w_WinClass.HICON, WM_TRAYBALLON, tr4w_ClassName) then
        if Balloon_ShowTrayTips(TipInfo) then
          TrayBallonDisplayed := True;
    end;
  end;
end;

end.

