unit uDXSSpotsFilter;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  uCommctrl,

  Messages;
const
  DXSSpotsFiltersCount             = 8;
var
  DXSSpotsFiltersArray             : array[0..DXSSpotsFiltersCount - 1] of PChar =
    (
    'SHOW/FILTER',
    'CLEAR/SPOTS ALL',
    'ACC/SPOTS ON HF',
    'ACC/SPOTS ON VHF',
    'ACC/SPOTS ON HF/CW',
    'ACC/SPOTS ON HF/SSB',
    'REJECT/ANNOUNCE',
    'CLEAR/ANNOUNCE'
    );

function DXSSpotsFilterDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation

uses MainUnit, uTelnet;

var
  DXSComandToSend                  : integer;

function DXSSpotsFilterDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  I                                : integer;
begin
  RESULT := False;
  case Msg of
    WM_INITDIALOG:
      begin
        DXSComandToSend := -1;
        for I := 0 to DXSSpotsFiltersCount - 1 do
        begin
          tCreateButtonWindow(
            0,
            DXSSpotsFiltersArray[I],
            BS_AUTORADIOBUTTON or WS_CHILD or WS_VISIBLE or WS_TABSTOP,
            10,
            I * 20 + 20,
            150,
            20,
            hwnddlg,
            I + 100);
        end;

      end;

    WM_COMMAND:
      begin
        if wParam = 1 then
        begin
          if DXSComandToSend <> -1 then SendViaSocket(DXSSpotsFiltersArray[DXSComandToSend]);
        end;
        if wParam = 2 then goto 1;
        if wParam in [100..DXSSpotsFiltersCount - 1 + 100] then DXSComandToSend := wParam - 100;
      end;
    WM_CLOSE: 1: EndDialog(hwnddlg, 0);
  end;
end;
end.

