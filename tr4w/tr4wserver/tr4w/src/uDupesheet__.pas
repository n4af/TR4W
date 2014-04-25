unit uDupesheet;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  uCallsigns,
  VC,
  Windows,
  LogEdit,
  LogStuff,
  LogWind,
  uGradient,
  Messages;

function DupesheetDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

const
  VDColorsArray                         : array[48..57] of tcolor =
    (clYellow,
    clLime,
    clAqua,
    $80FF80,
    $C0C0C0,
    clYellow,
    clLime,
    clAqua,
    $80FF80,
    $C0C0C0);

implementation
uses MainUnit;

function DupesheetDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  c                                     : Cardinal;
  tHWND                                 : HWND;
  temprect                              : TRect;
  Width                                 : integer;
  Height                                : integer;
  Left                                  : integer;
  PreviousRight                         : integer;
  VDDRAWITEMSTRUCT                      : PDrawItemStruct;
  CallsBuf                              : array[0..63] of Char;
  h                                     : HWND;
begin
  Result := False;
  case Msg of

    WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);
{
    WM_CTLCOLORLISTBOX: //RESULT := BOOL(WhiteBrush);
      if ColumnDupeSheetEnable then
      begin
        Windows.GetClientRect(HWND(lParam), temprect);
        GradientRect(HDC(wParam), temprect, VDColorsArray[GetDlgCtrlID(HWND(lParam))], VDColorsArray[GetDlgCtrlID(HWND(lParam))] , gdVertical);
      end;
}
    WM_DRAWITEM:
      begin
        VDDRAWITEMSTRUCT := Pointer(lParam);

        if (VDDRAWITEMSTRUCT^.itemAction = ODA_FOCUS) then
        begin
          DrawFocusRect(VDDRAWITEMSTRUCT^.HDC, VDDRAWITEMSTRUCT^.rcItem);
          Exit;
        end;

        Left := SendMessage(VDDRAWITEMSTRUCT^.hwndItem, LB_GETTEXT, VDDRAWITEMSTRUCT^.ItemID, integer(@CallsBuf));
        //        GradientRect(VDDRAWITEMSTRUCT^.HDC, VDDRAWITEMSTRUCT^.rcItem, clLime, clWhite, gdHorizontal);

        SetBkMode(VDDRAWITEMSTRUCT^.HDC, TRANSPARENT);
        //        Windows.TextOut(VDDRAWITEMSTRUCT^.HDC, VDDRAWITEMSTRUCT^.rcItem.Left, VDDRAWITEMSTRUCT^.rcItem.Top + 1, @CallsBuf, Left);

//        VDDRAWITEMSTRUCT^.rcItem.Right := VDDRAWITEMSTRUCT^.rcItem.Right - 35;
        PreviousRight := VDDRAWITEMSTRUCT^.rcItem.Right;
        VDDRAWITEMSTRUCT^.rcItem.Right := 32;
        Windows.SetTextColor(VDDRAWITEMSTRUCT^.HDC, $888888);
        Windows.DrawText(VDDRAWITEMSTRUCT^.HDC, @CallsBuf, 3 {Left}, VDDRAWITEMSTRUCT^.rcItem, DT_END_ELLIPSIS + DT_SINGLELINE + DT_RIGHT {DT_CENTER } + DT_VCENTER);

        VDDRAWITEMSTRUCT^.rcItem.Right := PreviousRight;

        VDDRAWITEMSTRUCT^.rcItem.Left := 50;
        GradientRect(VDDRAWITEMSTRUCT^.HDC, VDDRAWITEMSTRUCT^.rcItem, VDColorsArray[VDDRAWITEMSTRUCT^.CtlID], VDColorsArray[VDDRAWITEMSTRUCT^.CtlID], gdHorizontal);
        Windows.SetTextColor(VDDRAWITEMSTRUCT^.HDC, $FF0000);
        Windows.DrawText(VDDRAWITEMSTRUCT^.HDC, @CallsBuf[3], Left - 3 {Left}, VDDRAWITEMSTRUCT^.rcItem, DT_END_ELLIPSIS + DT_SINGLELINE + DT_LEFT {DT_CENTER } + DT_VCENTER);
//        windows.InvertRect(VDDRAWITEMSTRUCT^.HDC,VDDRAWITEMSTRUCT^.rcItem);

        CallsBuf[0] := CHR(VDDRAWITEMSTRUCT^.CtlID);
        VDDRAWITEMSTRUCT^.rcItem.Left := 34;
        VDDRAWITEMSTRUCT^.rcItem.Right := 47;
        GradientRect(VDDRAWITEMSTRUCT^.HDC, VDDRAWITEMSTRUCT^.rcItem, clBlack, clBlack, gdHorizontal);
        Windows.SetTextColor(VDDRAWITEMSTRUCT^.HDC, $ffffff);
        Windows.DrawText(VDDRAWITEMSTRUCT^.HDC, CallsBuf, 1 {Left}, VDDRAWITEMSTRUCT^.rcItem, DT_END_ELLIPSIS + DT_SINGLELINE + DT_CENTER  + DT_VCENTER);
//       windows.InvertRect(VDDRAWITEMSTRUCT^.HDC,VDDRAWITEMSTRUCT^.rcItem);

      end;

    WM_SIZE:
      begin
        if ColumnDupeSheetEnable then
        begin
          Windows.GetClientRect(hwnddlg, temprect);
          Width := (temprect.Right - temprect.Left) div 10;
          Height := temprect.Bottom - temprect.Top - ws;
          for c := 0 to 9 do
          begin
            Left := c * Width;
            Windows.MoveWindow(GetDlgItem(hwnddlg, 48 + c), Left, ws, Width, Height, True);
            Windows.MoveWindow(GetDlgItem(hwnddlg, 300 + c), Left, 0, Width, ws, True);
          end;
          InvalidateRect(hwnddlg, nil, False);
        end
        else
          tListBoxClientAlign(hwnddlg);

      end;
    WM_INITDIALOG:
      begin
        tHWND := Get101Window(hwnddlg);
        if ColumnDupeSheetEnable then
        begin
          ShowWindow(tHWND, SW_HIDE);
          for c := 0 to 9 do
          begin
            h := CreateWindowEx(0, LISTBOX, nil,
              WS_CHILD or WS_VISIBLE or

//              LBS_MULTICOLUMN or
              LBS_EXTENDEDSEL or
              LBS_NOINTEGRALHEIGHT or
              LBS_NOSEL or
              LBS_OWNERDRAWFIXED or
              LBS_HASSTRINGS,

              c * 50, 100, 50, 200, hwnddlg, 48 + c, hInstance, nil);

            tWM_SETFONT(h, MainFixedFont);
//            asm
//            mov edx,[MainFixedFont]
//            mov edx,[MSSansSerifFont]
//            call tWM_SETFONT
//            end;

//            tLB_SETCOLUMNWIDTH(h, 10);

            tCreateStaticWindow(inttopchar(c), defStyle, c * 50, 80, 50, 0, hwnddlg, 300 + c);
          end;
        end
        else
        begin
          tLB_SETCOLUMNWIDTH(hwnddlg, 80);
          tWM_SETFONT(tHWND, MainFixedFont);
        end;

        tr4w_WindowsArray[tw_DUPESHEETWINDOW_INDEX].WndHandle := hwnddlg;
        CallsignsList.Display(ActiveBand, ActiveMode);

      end;
    WM_CLOSE: CloseTR4WWindow(tw_DUPESHEETWINDOW_INDEX);
  end;
end;
end.

