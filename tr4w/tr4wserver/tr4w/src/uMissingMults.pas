unit uMissingMults; {Missing Mults Report WinAPI}
{$IMPORTEDDATA OFF}
interface

uses

  Windows,
  LogEdit,
  Messages;

function MissingMultsReportProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation

function MissingMultsReportProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
begin
  RESULT := False;
  case Msg of
    WM_INITDIALOG:
      VisibleLog.ShowMissingMultiplierReport(hwnddlg);

    WM_COMMAND:
      if wParam = 2 then goto 1;

    WM_CLOSE: 1: EndDialog(hwnddlg, 0);

  end;

end;

end.

