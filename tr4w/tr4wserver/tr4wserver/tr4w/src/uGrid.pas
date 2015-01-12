unit uGrid;
{$IMPORTEDDATA OFF}
interface

uses
  VC,
  TF,
  Windows,
  LogGrid,
  Tree,
  Messages;
function GridDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation
uses MainUnit;

function GridDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose;
var
  Resul                                 : integer;
  Lat, Lon                              : REAL;

begin
  RESULT := False;
  case Msg of

    WM_INITDIALOG: for Resul := 103 to 104 do SendDlgItemMessage(hwnddlg, Resul, EM_LIMITTEXT, 6, 0);

    WM_COMMAND:
      begin
        if HiWord(wParam) = EN_CHANGE then

        begin
          Windows.SetDlgItemText(hwnddlg, 108, nil);
          Val(GetDialogItemText(hwnddlg, 103), Lat, Resul);
          if Resul <> 0 then Exit;

          Val(GetDialogItemText(hwnddlg, 104), Lon, Resul);
          if Resul <> 0 then Exit;
//          tSetDlgItemIntFalse(hwnddlg, 108, ConvertLatLonToGrid(Lat, Lon));
          TR4W_WM_SetTest(hwnddlg, 108, ConvertLatLonToGrid(Lat, Lon));
        end;

        if wParam = 2 then goto ExitAndClose;
      end;
    WM_CLOSE: ExitAndClose: EndDialog(hwnddlg, 0);

  end;
end;
end.

