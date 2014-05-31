unit uRemMults_DOM;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  LogEdit,
  uGradient,
  Country9,
  LogDom,
  LogDupe,
  Messages;

function RemainingMultsDOMDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  RemainingMultsDOMWindowHandle         : HWND;

implementation
uses MainUnit;

function RemainingMultsDOMDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  p                                     : PChar;
  DS                                    : PDrawItemStruct;
  I                                     : integer;
  Index                                 : integer;
begin
  RESULT := False;
  case Msg of
    WM_SIZE, WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);
    WM_DRAWITEM:
      begin
        DS := PDrawItemStruct(lParam);

        if (DS^.itemAction = ODA_FOCUS) then
        begin
          DrawFocusRect(DS^.HDC, DS^.rcItem);
          Exit;
        end;

        Index := SendMessage(DS^.hwndItem, LB_GETITEMDATA, DS^.ItemID, 0);

        if tShowDomesticMultiplierName then
          p := @DomQTHTable.RemainingDomMults^[Index].Name[1]
        else
          p := @DomQTHTable.RemainingDomMults^[Index].ID[1];

        I := Windows.lstrlen(p);
        if RemainingMultDisplayMode = HiLight then

          if not RemainingMultsDOM^[Index] then
          begin
            Windows.SetTextColor(DS^.HDC, tr4wColorsArray[trWhite {ColorColors.RemainingMultsWindowSubdue}]);
            GradientRect(DS^.HDC, DS^.rcItem, tr4wColorsArray[trBlack {ColorColors.RemainingMultsWindowSubdue}], tr4wColorsArray[trWhite {ColorColors.RemainingMultsWindowBackground}], gdHorizontal);
          end
          else
          begin
            Windows.SetTextColor(DS^.HDC, tr4wColorsArray[trBlack {ColorColors.RemainingMultsWindowColor}]);
          end;

        SetBkMode(DS^.HDC, TRANSPARENT);
        Windows.TextOut(DS^.HDC, DS^.rcItem.Left + 2, DS^.rcItem.Top, p, I);

      end;

    WM_INITDIALOG:
      begin
        tr4w_WindowsArray[tw_STATIONS_RM_DOM].WndHandle := hwnddlg;
        RemainingMultsDOMWindowHandle := GetDlgItem(hwnddlg, 101);
        asm
        mov edx,[MainFixedFont]
        call tWM_SETFONT
        end;
        SetRemMultsColumnWudth;

        VisibleLog.ShowRemainingMultipliers;
      end;

    WM_CLOSE: CloseTR4WWindow(tw_STATIONS_RM_DOM);

  end;
end;
end.

