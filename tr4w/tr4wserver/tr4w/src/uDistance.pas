unit uDistance; {Distance WinAPI}
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  LogGrid,
  Tree,
  Messages;

function DistanceDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation
uses MainUnit;

function DistanceDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose;
var

  I                                     : integer;
  Grid1, Grid2                          : Str20;
  s                                     : string;
begin
  RESULT := False;
  case Msg of

    WM_INITDIALOG:
      begin
        for I := 103 to 104 do
          SendDlgItemMessage(hwnddlg, I, EM_LIMITTEXT, 6, 0);

      end;
    WM_COMMAND:
      begin
        if HiWord(wParam) = EN_CHANGE then

        begin
          for I := 108 to 109 do Windows.SetDlgItemText(hwnddlg, I, nil);

          Grid1 := GetDialogItemText(hwnddlg, 103);
          if Grid1 = '' then Exit;

          Grid2 := GetDialogItemText(hwnddlg, 104);
          if Grid2 = '' then Exit;

          I := GetDistanceBetweenGrids(Grid1, Grid2);
          asm
          push i
          end;
          wsprintf(wsprintfBuffer, '%u km');
          asm add esp,12    end;
          Windows.SetDlgItemText(hwnddlg, 108, wsprintfBuffer);

          TR4W_WM_SetTest(hwnddlg, 108, IntToStr(GetDistanceBetweenGrids(Grid1, Grid2)) + ' km');
          TR4W_WM_SetTest(hwnddlg, 109, IntToStr(GetEuropeanDistanceBetweenGrids(Grid1, Grid2)) + ' km');
        end;

        if wParam = 2 then goto ExitAndClose;
      end;
    WM_CLOSE: ExitAndClose: EndDialog(hwnddlg, 0);

  end;
end;
end.

