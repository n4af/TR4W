unit uWinManager;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  Messages;

function WindowsManagerDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

var
  ManageWindow                          : HWND;

implementation
uses MainUnit;

var
  Manager                               : HWND;

function Enumtr4wWindowsProc(wnd: HWND; l: lParam): BOOL; stdcall;
begin
  Result := True;
  if (Windows.GetParent(wnd) = tr4whandle) or (wnd = tr4whandle) then
    if IsWindowVisible(wnd) then
    begin
      Windows.GetWindowText(wnd, wsprintfBuffer, 100);
//      if wnd = tr4w_WindowsArray[tw_FUNCTIONKEYSWINDOW_INDEX].WndHandle then Exit;
      Windows.SendMessage(Manager, LB_SETITEMDATA, Windows.SendMessage(Manager, LB_ADDSTRING, 0, integer(@wsprintfBuffer)), wnd);
    end;
end;

function WindowsManagerDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  FlashWind, SelectItem, ExitAndClose;
begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin
        Windows.SetWindowText(hwnddlg, RC_WINCONTROL2);
        Manager := CreateListBox(0, 0, 300, 200, hwnddlg, 101);
        CreateOKCancelButtons(hwnddlg);

        //Manager := Get101Window(hwnddlg);
        ManageWindow := 0;
//        WindowIndexInManager := 0;
//        wmhwnd := hwnddlg;
//        Windows.RegisterHotKey(hwnddlg, 1, MOD_ALT or MOD_CONTROL, Ord('M'));
        EnumWindows(@Enumtr4wWindowsProc, 0);
        Windows.SendMessage(Manager, LB_SETCURSEL, 0, 0);
      end;
{
    WM_HOTKEY:
      begin
        i := tLB_GETCURSEL(Manager);
        if i = Windows.SendMessage(Manager, LB_GETCOUNT, 0, 0) - 1 then i := 0
        else inc(i);
        Windows.SendMessage(Manager, LB_SETCURSEL, i, 0);
        goto FlashWind;
      end;
}
    WM_CLOSE:
      begin
        ManageWindow := 0;
        ExitAndClose:
//        UnregisterHotKey(hwnddlg, 1);
        EndDialog(hwnddlg, 0);
      end;
{$IF LANG = 'RUS'}
    WM_HELP: ShowHelp('ru_windowscontrol');
{$IFEND}

    WM_COMMAND:

      begin

        if HiWord(wParam) = LBN_SELCHANGE then goto FlashWind;
        if HiWord(wParam) = LBN_DBLCLK then goto SelectItem;

        case wParam of
          2:
            begin
              ManageWindow := 0;
              goto ExitAndClose;
            end;
          1:
            begin
              SelectItem:
              ManageWindow := Windows.SendMessage(Manager, LB_GETITEMDATA, tLB_GETCURSEL(Manager), 0);
              goto ExitAndClose;
            end;

        end;
      end;
  end;
  Exit;
  FlashWind:
  ManageWindow := Windows.SendMessage(Manager, LB_GETITEMDATA, tLB_GETCURSEL(Manager), 0);
  Windows.FlashWindow(ManageWindow, True)
end;

end.

