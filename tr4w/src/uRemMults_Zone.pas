unit uRemMults_Zone;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  LogWind,
  LogEdit,
  uGradient,
  Country9,
  LogDom,
  LogDupe,
  Messages;

function RemainingMultsZoneDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  RemainingMultsZoneWindowHandle: HWND;
var
  RemMultsBuf                 : array[0..7] of Char;
implementation
uses MainUnit;

function RemainingMultsZoneDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  p                           : PChar;
  DS                          : PDrawItemStruct;
  I                           : integer;
  Index                       : integer;
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
        asm
        mov eax, Index
        cmp byte ptr [ActiveZoneMult],EUHFCYear
        jz @@1
        add eax,1
        @@1:
        push eax
        end;
        wsprintf(RemMultsBuf, '%02u');
        asm add esp,12 end;
        p := @RemMultsBuf;

        I := Windows.lstrlen(p);
        if RemainingMultDisplayMode = HiLight then

          if not RemainingMultsZone^[Index] then
          begin
            Windows.SetTextColor(DS^.HDC, tr4wColorsArray[trWhite {ColorColors.RemainingMultsWindowSubdue}]);
            GradientRect(DS^.HDC, DS^.rcItem, tr4wColorsArray[trRed {ColorColors.RemainingMultsWindowSubdue}], tr4wColorsArray[trWhite {ColorColors.RemainingMultsWindowBackground}], gdHorizontal);
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
        RemainingMultsZoneWindowHandle := GetDlgItem(hwnddlg, 101);
        asm
        mov edx,[MainFixedFont]
        call tWM_SETFONT
        end;
        tLB_SETCOLUMNWIDTH(hwnddlg, 40);
        tr4w_WindowsArray[tw_STATIONS_RM_ZONE].WndHandle := hwnddlg;
        VisibleLog.ShowRemainingMultipliers;
      end;

    WM_CLOSE: CloseTR4WWindow(tw_STATIONS_RM_ZONE);

  end;
end;
end.

