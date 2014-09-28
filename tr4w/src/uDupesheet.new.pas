unit uDupesheet;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  uCallsigns,
  VC,
  LogRadio,
  Windows,
  LogEdit,
  LogStuff,
  LogWind,
  uGradient,
  Messages;

function DupesheetDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure ClearAltD;
const
  VDColorsArray                         : array[Ord('0')..Ord('9') + 1] of tr4wColors =
    (
    trBlue, //0
    trRed, //1
    trGreen, //2
    trMagenta, //3
    trBrown, //4
    trBlue, //5
    trRed, //6
    trGreen, //7
    trMagenta, //8
    trBrown, ///9
    trBrown ///10
    );

implementation
uses MainUnit;

//var
//  VDCurrentCallDistrict                 : Byte;

procedure ClearAltD;

begin
DupeInfoCallWindowState := diNone;
SetMainWindowText(mweDupeInfoCall, nil);
DupeInfoCallWindowCleared := True;
Windows.ShowWindow(wh[mweDupeInfoCall], SW_HIDE);


end;

function DupesheetDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  c                                     : Cardinal;
  tHWND                                 : HWND;
  temprect                              : TRect;
  Width                                 : integer;
  Height                                : integer;
  LengthOfTheString                     : integer;
  VDDRAWITEMSTRUCT                      : PDrawItemStruct;
  CallsBuf                              : array[0..63] of Char;
  bgColor                               : integer;
  VDCurrentCallDistrict                 : integer;
  Left                                  : integer;
begin
  Result := False;
  case Msg of
    WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);

    WM_CTLCOLORLISTBOX: //RESULT := BOOL(WhiteBrush);
      if ColumnDupeSheetEnable then

      begin
        SetTextColor(HDC(wParam), $FFFFFF);
        Result := BOOL(tr4wBrushArray[trWhite]);
       Windows.GetClientRect(HWND(lParam), temprect);
  //      GradientRect(HDC(wParam), temprect, VDColorsArray[GetDlgCtrlID(HWND(lParam))], clwhite, gdVertical);
      end;

    WM_DRAWITEM:
      begin
        VDDRAWITEMSTRUCT := Pointer(lParam);

        if (VDDRAWITEMSTRUCT^.itemAction = ODA_FOCUS) then
        begin
          DrawFocusRect(VDDRAWITEMSTRUCT^.HDC, VDDRAWITEMSTRUCT^.rcItem);
          Exit;
        end;

        LengthOfTheString := SendMessage(VDDRAWITEMSTRUCT^.hwndItem, LB_GETTEXT, VDDRAWITEMSTRUCT^.ItemID, integer(@CallsBuf));

        while LengthOfTheString < 6 do
        begin
          CallsBuf[LengthOfTheString] := '-';
          inc(LengthOfTheString);
        end;
 
        bgColor := SendMessage(VDDRAWITEMSTRUCT^.hwndItem, LB_GETITEMDATA, VDDRAWITEMSTRUCT^.ItemID, 0);

       if Left <> 0 then
        GradientRect(
          VDDRAWITEMSTRUCT^.HDC,
          VDDRAWITEMSTRUCT^.rcItem,
          tr4wColorsArray[VDColorsArray[bgColor]],
          tr4wColorsArray[VDColorsArray[bgColor]],
          gdHorizontal
          )
        else
        begin
         GradientRect(VDDRAWITEMSTRUCT^.HDC, VDDRAWITEMSTRUCT^.rcItem, tr4wColorsArray[VDColorsArray[VDCurrentCallDistrict]], tr4wColorsArray[VDColorsArray[VDCurrentCallDistrict + 1]], gdVertical);
         GradientRect(VDDRAWITEMSTRUCT^.HDC, VDDRAWITEMSTRUCT^.rcItem, clWhite, clwhite, gdVertical);
         inc(VDCurrentCallDistrict);
         if VDCurrentCallDistrict = Ord('9') + 1 then VDCurrentCallDistrict := Ord('0');
       end;

        SetBkMode(VDDRAWITEMSTRUCT^.HDC, TRANSPARENT);

            Windows.TextOut(VDDRAWITEMSTRUCT^.HDC, VDDRAWITEMSTRUCT^.rcItem.Left, VDDRAWITEMSTRUCT^.rcItem.Top + 1, @CallsBuf, Left);
        Windows.DrawText(VDDRAWITEMSTRUCT^.HDC, @CallsBuf, LengthOfTheString, VDDRAWITEMSTRUCT^.rcItem, DT_END_ELLIPSIS + DT_SINGLELINE + DT_CENTER + DT_VCENTER);
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
//        tHWND := Get101Window(hwnddlg);
        tHWND := CreateOwnerDrawListBox(LB_STYLE_2,hwnddlg);

         if ColumnDupeSheetEnable then
        begin
          ShowWindow(tHWND, SW_HIDE);
          for c := 0 to 9 do
          begin
            CreateWindowEx(0, LISTBOX, nil, WS_CHILD or WS_VISIBLE or LBS_EXTENDEDSEL or LBS_NOINTEGRALHEIGHT or LBS_NOSEL or LBS_OWNERDRAWFIXED or LBS_HASSTRINGS,
              c * 50, 100, 50, 200, hwnddlg, 48 + c, hInstance, nil);
            asm
            mov edx,[MainFixedFont]
            call tWM_SETFONT
            end;

            tCreateStaticWindow(inttopchar(c), defStyle, c * 50, 80, 50, 0, hwnddlg, 300 + c);
          end;
        end
        else
        begin
          tLB_SETCOLUMNWIDTH(hwnddlg, 80+Ord(BoldFont)*15);
          tWM_SETFONT(tHWND, LucidaConsoleFont {MainFixedFont});
        end;
       VDCurrentCallDistrict := Ord('0');

        tr4w_WindowsArray[WindowsType(lParam) {tw_DUPESHEETWINDOW1_INDEX}].WndHandle := hwnddlg;

        if WindowsType(lParam) = tw_DUPESHEETWINDOW1_INDEX then
        begin
          Radio1.tDupeSheetWnd := hwnddlg;
          CallsignsList.DisplayDupeSheet(@Radio1 {ActiveBand, ActiveMode});
        end;

        if WindowsType(lParam) = tw_DUPESHEETWINDOW2_INDEX then
        begin
          Radio2.tDupeSheetWnd := hwnddlg;
          CallsignsList.DisplayDupeSheet(@Radio2 {ActiveBand, ActiveMode});
        end;

      end;
    WM_CLOSE:
      begin
        if hwnddlg = Radio1.tDupeSheetWnd then
        begin
          CloseTR4WWindow(tw_DUPESHEETWINDOW1_INDEX);
          Radio1.tDupeSheetWnd := 0;
        end;

        if hwnddlg = Radio2.tDupeSheetWnd then
        begin
          CloseTR4WWindow(tw_DUPESHEETWINDOW2_INDEX);
          Radio2.tDupeSheetWnd := 0;
        end;

      end;
  end;
end;
end.

