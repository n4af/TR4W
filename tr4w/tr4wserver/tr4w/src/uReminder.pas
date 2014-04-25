unit uReminder; {Reminder WinAPI}
{$IMPORTEDDATA OFF}
interface

uses

  TF,
  VC,
  uCommctrl,
  Windows,
  Messages,
  LogWind;

function ReminderDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  flashreminder                         : boolean = False;
  ReminderDlgHandle                     : HWND;

implementation
uses MainUnit;

function ReminderDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  TempHWND                              : HWND;
begin
  RESULT := False;
  case Msg of
    WM_INITDIALOG:

      begin
        ReminderDlgHandle := hwnddlg;
        TempHWND := GetDlgItem(hwnddlg, 101);
        SendMessage(TempHWND, PBM_SETRANGE, 0, MakeLParam(0, TourDuration));
        SendMessage(TempHWND, PBM_SETSTEP, 1, 0);
        SendMessage(TempHWND, PBM_SETBARCOLOR, 0, 0);
        SendMessage(TempHWND, PBM_SETBKCOLOR, 0, $FFFFFF);
        MoveWindow(hwnddlg, tr4w_WindowsArray[tw_MAINWINDOW_INDEX].WndRect.Right - 290, tr4w_WindowsArray[tw_MAINWINDOW_INDEX].WndRect.Top + 2, 210, 22, True);
        ShowTourDuration;
      end;

    WM_LBUTTONDOWN: DragWindow(hwnddlg);
//    WM_CLOSE: EndDialog(hwnddlg, 0);

  end;

end;

end.

