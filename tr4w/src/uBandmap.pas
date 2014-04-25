unit uBandmap;
{$IMPORTEDDATA OFF}
interface

uses
  uMenu,
  uCommctrl,
  uCTYDAT,
  uSpots,
  TF,
  VC,
  uTelnet,
  Windows,
  LogEdit,
  uGradient,
  uCallsigns,
  Messages,
  LogStuff,
  LogK1EA,
  LogWind,
  LogRadio,
  LogDupe,
  LOGSUBS1,
  Tree
  ;

{
const
  bm_hotkey_escape                      = 1;
  bm_hotkey_delete                      = 2;
  bm_hotkey_return                      = 3;
  bm_hotkey_pause                       = 4;
}

type
  TBandMapButtons = record
    Menu: HMENU;
    Text: PChar;
  end;
{
const
  BandMapButtonsCount                   = 6;
  BandMapButtonsArray                   : array[0..BandMapButtonsCount - 1] of TBandMapButtons =
    (
    (Menu: Ord(BAB); Text: 'All bands'),
    (Menu: Ord(BAM); Text: 'All modes'),
    (Menu: Ord(BCQ); Text: 'Display CQ'),
    (Menu: Ord(BDD); Text: 'Dupe display'),
    (Menu: Ord(VBE); Text: 'VHF band'),
    (Menu: Ord(WBE); Text: 'WARC band')
    );
}
function BandmapDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure ShowBandMapPopupMenu;
procedure TuneRadioToSpot(Spot: TSpotRecord; Radio: RadioType);
procedure DeleteSpotFromBandmap;
procedure ShowSpotInfo;
procedure ClearSpotInfo;
procedure SetTextInBMSB(Index: integer; Text: PChar);
function GetBMSelItemData: integer;
function NEWBMLBPROC(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): integer; stdcall;

const

  CheckRectWidth                        = 17;
  BMPanelWidth                          : array[0..5] of integer = (80, 130, 240, 350, 510, 580);
var
  FreqRectWidth                         : integer; // = 55 - 20;
  BandmapDRAWITEMSTRUCT                 : PDrawItemStruct;
  CursorEntryNumber, MaxEntriesPerPage  : integer;
  OLDBMLBPROC                           : Pointer;
  BandMapListBox                        : HWND;
  BandMapStatusBar                      : HWND;
  BandMapBckgrndBrush                   : HBRUSH;
  tBlinkerRect                          : TRect;
  tIvertedBlinker                       : boolean;
  //  DoNotAddToBandMap                : boolean;
  // BandMapListBoxHDC                     : HDC;
  tr4w_NetedToBlink                      : boolean;
  BMWSBUFFER                            : array[0..16] of Char;
  PreviousDisplayedBandmapBand          : BandType {= NoBand};
  BandColor                             : Cardinal;
  BandMapItemHeight                     : integer = CheckRectWidth;
  BandMapItemWidth                      : integer = 150;
  BandMapFreqWidthCalculated            : boolean;

implementation
uses MainUnit;

function BandmapDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1, 2, DrawCallsign;
var
  CallsignColor                         : Cardinal;
  FrequencyRect                         : TRect;
  CallsignRect                          : TRect;
  CheckRect                             : TRect;
  temprect                              : TRect;
  SelectedItem                          : boolean;
  CursorFontColor                       : Cardinal;
  TempInt                               : integer;
  memDC                                 : HDC;
  Spot                                  : TSpotRecord;
  p                                     : PChar;
  Size                                  : TSIZE;
  TempHDC                               : HDC;
const
  Shift                                 = 1;
  button_style                          = BS_PUSHLIKE + BS_AUTOCHECKBOX + WS_CHILD + WS_VISIBLE + WS_TABSTOP;
  button_width                          = 70;
begin
  Result := False;

  //    if Msg <> 308 then
  //  if Msg <> WM_DRAWITEM then
  //        if Msg <> 3 then
  //          if Msg <> 70 then

  //  AddStringToTelnetConsole(IntToStr(Msg) + '---');
  //  if Msg = 305 then

  case Msg of

    WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);

    WM_CONTEXTMENU:
      if HWND(wParam) = BandMapListBox then ShowBandMapPopupMenu;

    //    WM_ERASEBKGND: Result := True;

    WM_CTLCOLORLISTBOX: Result := BOOL(BandMapBckgrndBrush);

    WM_MEASUREITEM:
      begin

//        BandMapItemWidth := FreqRectWidth + 1 + CheckRectWidth + 1 + 65;

        PMeasureItemStruct(lParam).itemHeight := BandMapItemHeight;
        PMeasureItemStruct(lParam).itemWidth := BandMapItemWidth;
      end;

    WM_DRAWITEM:
      if wParam <> 0 then
      begin
        BandmapDRAWITEMSTRUCT := Pointer(lParam);
        begin

          if (BandmapDRAWITEMSTRUCT^.itemAction = ODA_FOCUS) then
          begin
            DrawFocusRect(BandmapDRAWITEMSTRUCT^.HDC, BandmapDRAWITEMSTRUCT^.rcItem);
            Exit;
          end;

          Windows.FillRect(BandmapDRAWITEMSTRUCT^.HDC, BandmapDRAWITEMSTRUCT^.rcItem, BandMapBckgrndBrush);
          memDC := BandmapDRAWITEMSTRUCT^.HDC;

          if not BandMapFreqWidthCalculated then
          begin

            GetTextExtentPoint32(memDC, '28888.8', 7, Size);
            FreqRectWidth := Size.cx + 10;
            BandMapFreqWidthCalculated := True;
          end;

          SelectedItem := False;

            {Rects}
          temprect := BandmapDRAWITEMSTRUCT^.rcItem;
          temprect.Top := temprect.Top + Shift;
          temprect.Bottom := temprect.Bottom - Shift;
          temprect.Right := temprect.Right - Shift;
          temprect.Left := temprect.Left + Shift;

          FrequencyRect := temprect; // BandmapDRAWITEMSTRUCT^.rcItem;
          CallsignRect := temprect; //BandmapDRAWITEMSTRUCT^.rcItem;
          CheckRect := temprect; // BandmapDRAWITEMSTRUCT^.rcItem;
            //          LeftFreqRect := TempRect;

            //          LeftFreqRect.Right := LeftFreqRect.Left + 20;

          FrequencyRect.Right := FrequencyRect.Left + FreqRectWidth;
          CheckRect.Left := FrequencyRect.Right + 1;
          CheckRect.Right := CheckRect.Left + CheckRectWidth;
          CallsignRect.Left := CheckRect.Right + Shift;

            ///            TempBandMapEntryPointer := Pointer(BandmapDRAWITEMSTRUCT^.itemData);

          Windows.SetTextColor(memDC, 0);
          SetBkMode(memDC, TRANSPARENT);

          Spot := SpotsList.Get(BandmapDRAWITEMSTRUCT^.itemData);

          SetBkMode(memDC, TRANSPARENT);

          CursorFontColor := clwhite;

          if Spot.FBand = BandmapBand then                                                    //GAV change Activeband to BandmapBand
            begin
              if (Abs(spot.FFrequency - BandMapCursorFrequency) <= BandMapGuardBand)  then    //GAV added to change turn current spot in bandmap red
                BandColor := clred
               else
                BandColor := clblue;
             end
          else
            BandColor := clsilver;


          if (lobyte(BandmapDRAWITEMSTRUCT^.itemState) = ODS_SELECTED) then SelectedItem := True;

          if SelectedItem then
          begin
            DrawFrameControl(memDC, BandmapDRAWITEMSTRUCT^.rcItem, DFC_BUTTON, DFCS_BUTTONPUSH);
            {
            BandmapDRAWITEMSTRUCT^.rcItem.Bottom:=
            BandmapDRAWITEMSTRUCT^.rcItem.Bottom+100;
            DrawFrameControl(memDC, BandmapDRAWITEMSTRUCT^.rcItem, DFC_CAPTION	, DFCS_CAPTIONHELP);
            }
            CursorFontColor := 0;
            Windows.SetTextColor(memDC, $FFFFFF);
            CallsignColor := 0;
          end
          else
          begin
            if BandmapDRAWITEMSTRUCT^.itemAction = ODA_SELECT then
              if lobyte(BandmapDRAWITEMSTRUCT^.itemState) = 0 then
                Windows.FillRect(memDC, BandmapDRAWITEMSTRUCT^.rcItem, BandMapBckgrndBrush);
            GradientRect(memDC, FrequencyRect, BandColor, BandColor, gdHorizontal);
          end;

            {Draw Frequency}
          Windows.SetTextColor(memDC, CursorFontColor);

          Windows.DrawText
            (memDC,
            FreqToPChar2(Spot.FFrequency),
            -1,
            FrequencyRect,
            DT_END_ELLIPSIS + DT_SINGLELINE + DT_RIGHT + DT_VCENTER);
          p := nil;

          if Spot.FMult then
          begin
            GradientRect(memDC, CheckRect, clred, clwhite, gdHorizontal);
            p := 'M';
          end;

//          if Spot.FLoudSignal then p := '+';
          if Spot.FQSXFrequency <> 0 then p := 'S';
          if Spot.FDupe then
              //            Ellipse(memDC, CheckRect.Left, CheckRect.Top, CheckRect.Right, CheckRect.Bottom);
          begin
            GradientRect(memDC, CheckRect, clYellow, clYellow, gdHorizontal);
            p := 'D';
          end;

          if p <> nil then
          begin
            Windows.SetTextColor(memDC, 0);
            Windows.DrawText(memDC, p, 1, CheckRect, DT_END_ELLIPSIS + DT_SINGLELINE + DT_CENTER + DT_VCENTER);
          end;

          if SelectedItem then
            CallsignColor := 0
          else
          begin
            if Spot.FMinutesLeft in [00..02] then
            begin
              GradientRect(memDC, CallsignRect, clblack, clblack, gdHorizontal);
              CallsignColor := $FFFFFF;
            end;
            if Spot.FMinutesLeft in [03..10] then CallsignColor := clblue;
            if Spot.FMinutesLeft in [11..20] then CallsignColor := $505050;
            if Spot.FMinutesLeft in [21..30] then CallsignColor := $808080;
            if Spot.FMinutesLeft > 30 then CallsignColor := $C0C0C0;
          end;

          Windows.SetTextColor(memDC, CallsignColor);

          DrawCallsign:
          CallsignRect.Left := CallsignRect.Left + 2;
          Windows.DrawText(
            memDC,
            @Spot.FCall[1],
            length(Spot.FCall),
            CallsignRect,
            DT_END_ELLIPSIS + DT_SINGLELINE + DT_LEFT + DT_VCENTER);

          2:

        end;
      end;

    WM_SIZE:
      begin
        tListBoxClientAlign(hwnddlg);
        MoveWindow(BandMapStatusBar, 0, HiWord(lParam), LoWord(lParam), HiWord(lParam), True);
        DisplayBandMap;
      end;
    {
        WM_CTLCOLORBTN:
          begin
            SetBkMode(hdc(wParam), TRANSPARENT);
            SetTextColor(hdc(wParam), $000000FF);
            Result := BOOL(tr4wBrushArray[trGreen]);
          end;
    }
        //WM_ERASEBKGND:WINDOWS.TextOut(hdc(WPARAM),50,50,'aaaaaa',6);
    WM_INITDIALOG:
      begin
        BandMapListBox := CreateOwnerDrawListBox(LB_STYLE_1, hwnddlg);
        asm
            mov edx,[MainFixedFont]
            call tWM_SETFONT
        end;

        //        OLDBMLBPROC := Pointer(Windows.SetWindowLong(BandMapListBox, GWL_WNDPROC, integer(@NEWBMLBPROC)));
                //for BandColor:=1 to 100 do
                //                SendMessage(BandMapListBox, LB_ADDSTRING, 0, 0);
        BandMapStatusBar := Windows.GetDlgItem(hwnddlg, 102);

        BandMapStatusBar := tWM_SETFONT(CreateWindow(STATUSCLASSNAME, nil, {SBT_NOBORDERS or} CCS_TOP or CCS_NOMOVEY or WS_CHILD or WS_VISIBLE, 100, 100, 100, 100, hwnddlg, 101, hInstance, nil), MainFixedFont);
        Windows.SendMessage(BandMapStatusBar, SB_SETBKCOLOR, 0, $00FFFF00);

//        tLB_SETCOLUMNWIDTH(hwnddlg, BandMapItemWidth);

        BandMapEnable := True;
        SendMessage(BandMapStatusBar, SB_SETPARTS, 6, integer(@BMPanelWidth));
      SetTimer(hwnddlg, BANDMAP_BLINK_TIMER_HANDLE, 600, nil);     //n4af
        tr4w_WindowsArray[tw_BANDMAPWINDOW_INDEX].WndHandle := hwnddlg;
   //      BandMapListBoxHDC := Windows.GetDC(BandMapListBox);
     //           DoNotAddToBandMap := False;       
{
        for TempInt := 0 to BandMapButtonsCount - 1 do
          begin
            CreateWindow('BUTTON', BandMapButtonsArray[TempInt].Text,
              button_style,
              TempInt * button_width,
              1,
              button_width - 1,
              19,
              hwnddlg,
              BandMapButtonsArray[TempInt].Menu, hInstance, nil);
            asm
        mov edx,[MSSansSerifFont]
        call tWM_SETFONT
            end;
            if ParameterToString(MenuEntryType(BandMapButtonsArray[TempInt].Menu)) = 'TRUE' then
              Windows.SendDlgItemMessage(hwnddlg, BandMapButtonsArray[TempInt].Menu, BM_SETCHECK, BST_CHECKED, 0);
          end;
}
        DisplayBandMap;
      end;
{                                
    WM_TIMER:
      begin
      if tr4w_NeedToBlink then          //n4af
        begin

           if Windows.InvertRect(BandMapListBox, tBlinkerRect) then       //n4af
		   if (Abs(spot.FFrequency = BandMapCursorFrequency)
            TF.InvertBoolean(tIvertedBlinker)
          else
            asm
            nop
            end;
        end;

      end;
}
    WM_COMMAND:
      begin
        {
                if HiWord(wParam) = BN_CLICKED then
                  begin
                    ProcessInput(MenuEntryType(LoWord(wParam)));
                    FrmSetFocus;
                    Exit;
                  end;
        }
                //       if lParam = integer(CPUButtonHandle) then CPUButtonProc;
        case wParam of
          66: InvertBooleanCommand(@BandMapAllBands);
          68: InvertBooleanCommand(@BandMapDupeDisplay);
          69: InvertBooleanCommand(@BandMapMultsOnly);
          77: InvertBooleanCommand(@BandMapAllModes);
          202: InvertBooleanCommand(@BandMapDisplayCQ);

          203: DeleteSpotFromBandmap;
          204:
            begin
              SpotsList.Clear;
              SpotsList.Display;
            end;
          205:
            begin
              TempInt := GetBMSelItemData;
              if TempInt = LB_ERR then Exit;
              TuneRadioToSpot(SpotsList.Get(TempInt), InactiveRadio);
//              SwapRadios;
            end;
        end;

        case HiWord(wParam) of
          LBN_SETFOCUS:
            begin

            end;
          LBN_SELCHANGE:
            begin
              SpotsList.SetCursor;
              ShowSpotInfo;

            end;

          LBN_DBLCLK:
            begin
              TempInt := GetBMSelItemData;
              if TempInt = LB_ERR then Exit;
              TuneRadioToSpot(SpotsList.Get(TempInt), ActiveRadio);
            end;
          //            TuneOnSpotFromBandmap;

        end;
      end;
    WM_CLOSE: 1: CloseTR4WWindow(tw_BANDMAPWINDOW_INDEX);

    WM_DESTROY:
      begin
        BandMapEnable := False;
        BandMapListBox := 0;
 //      ReleaseDC(BandMapListBox, BandMapListBoxHDC);
      end;

  end;

end;
{
procedure UnregisterBMHotKeys;
begin
  UnregisterHotKey(tr4w_WindowsArray[tr4w_BANDMAPWINDOW_INDEX].tr4w_WndHandle, bm_hotkey_escape);
  UnregisterHotKey(tr4w_WindowsArray[tr4w_BANDMAPWINDOW_INDEX].tr4w_WndHandle, bm_hotkey_delete);
  UnregisterHotKey(tr4w_WindowsArray[tr4w_BANDMAPWINDOW_INDEX].tr4w_WndHandle, bm_hotkey_return);
  UnregisterHotKey(tr4w_WindowsArray[tr4w_BANDMAPWINDOW_INDEX].tr4w_WndHandle, bm_hotkey_pause);

end;
}
{
procedure CheckUncheckAllBandMapPopupMenus;

begin
  CheckUncheckBandMapPopupMenu(200, @BandMapAllBands);
  CheckUncheckBandMapPopupMenu(201, @BandMapAllModes);
  CheckUncheckBandMapPopupMenu(202, @BandMapDisplayCQ);
  CheckUncheckBandMapPopupMenu(203, @BandMapDupeDisplay);
end;

procedure CheckUncheckBandMapPopupMenu(Position: Cardinal; CommandAddress: PBoolean);
var
  c                                     : Cardinal;
begin
  if CommandAddress^ = True then c := MF_CHECKED else c := MF_UNCHECKED;
  Windows.CheckMenuItem(BandMapMenu, Position, c);
end;
}

{
procedure WriteBandMapMenuValue(Command: PChar; BoolCommand: Boolean);
var
//  command                               : string;
//  command                               : PChar;
  value                                 : PChar;
//  CBuffer                               : array[0..40] of Char;
//  I                                     : integer;
begin
  if BoolCommand = True then value := 'TRUE' else value := 'FALSE';
//  command := 'a';
//  I := GetMenuString(BandMapMenu, Position, @CBuffer , 40, MF_BYCOMMAND);
//  command := CBuffer;
//  if CBuffer[I - 2] = #9 then setstring(command, PChar(command), I - 2); //if hotkey char in menustring

  Windows.WritePrivateProfileString(_COMMANDS, Command, value, PChar(TR4W_INI_FILENAME));

end;
}

procedure ShowBandMapPopupMenu;
var
  CPos                                  : TPoint;
  BandMapMenu                           : HMENU;
  //const  res                                   = 140;
begin
  BandMapMenu := CreateTR4WMenu(@B_MENU_ARRAY, B_MENU_ARRAY_SIZE, True);

  //LoadMenu(hInstance, 'B');

  //  CheckUncheckAllBandMapPopupMenus;

  if BandMapAllBands then Windows.CheckMenuItem(BandMapMenu, 66, MF_CHECKED);
  if BandMapAllModes then Windows.CheckMenuItem(BandMapMenu, 77, MF_CHECKED);
  if BandMapDisplayCQ then Windows.CheckMenuItem(BandMapMenu, 202, MF_CHECKED);
  if BandMapDupeDisplay then Windows.CheckMenuItem(BandMapMenu, 68, MF_CHECKED);
  if BandMapMultsOnly then Windows.CheckMenuItem(BandMapMenu, 69, MF_CHECKED);

  //  SetMenuItemBitmaps(tr4w_main_menu, menu_alt_swapmults, MF_BYCOMMAND,
  //    LoadImage(GetModuleHandle('comctl32.dll'), PChar(140), IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR), 0);

  GetCursorPos(CPos);
  TrackPopupMenu(BandMapMenu, TPM_LEFTALIGN or TPM_BOTTOMALIGN, CPos.X, CPos.Y, 0, tr4w_WindowsArray[tw_BANDMAPWINDOW_INDEX].WndHandle, nil);
  {  WriteBandMapMenuValue(200, BandMapAllBands);
    WriteBandMapMenuValue(201, BandMapAllModes);
    WriteBandMapMenuValue(202, BandMapDisplayCQ);
    WriteBandMapMenuValue(203, BandMapDupeDisplay);
  }
  DestroyMenu(BandMapMenu);
  FrmSetFocus;
end;

procedure TuneRadioToSpot(Spot: TSpotRecord; Radio: RadioType);
var
  EntryBand                             : BandType;
  EntryMode                             : ModeType;
  Index                                 : integer;
  QZBOffset                             : integer;
const
  MAX_QZB_OFFSET                        = 30;
begin

  if OpMode = SearchAndPounceOpMode
    then
  begin
    LastSPFrequency := ActiveRadioPtr^.LastDisplayedFreq;
    LastSPMode := ActiveMode;
  end;

//?
  EntryBand := NoBand;
  EntryMode := NoMode;

  GetBandMapBandModeFromFrequency(Spot.FFrequency, EntryBand, EntryMode);
  if EntryBand = NoBand then Exit;

  if (QZBRandomOffsetEnable and (EntryMode = CW)) then
  begin
    QZBOffset := Windows.GetTickCount mod (MAX_QZB_OFFSET * 2);
    if QZBOffset > MAX_QZB_OFFSET then
      QZBOffset := QZBOffset - MAX_QZB_OFFSET * 2;
  end
  else
    QZBOffset := 0;

  if Spot.FQSXFrequency <> 0 then
  begin
    case BandMapSplitMode of
      ByCutoffFrequency:
        begin
          SetRadioFreq(Radio, Spot.FQSXFrequency + QZBOffset, EntryMode, 'B');
          SetRadioFreq(Radio, Spot.FFrequency, EntryMode, 'A');
        end;
      AlwaysPhone:
        begin
          SetRadioFreq(Radio, Spot.FQSXFrequency + QZBOffset, Phone, 'B');
          SetRadioFreq(Radio, Spot.FFrequency, Phone, 'A');
        end;
    end;
    PutRadioIntoSplit(Radio);
  end
  else
  begin
    SetRadioFreq(Radio, Spot.FFrequency + QZBOffset, EntryMode, 'A');
    Sleep(100);
    PutRadioOutOfSplit(Radio);
  end;

  if Radio = InactiveRadio then Exit;

  tCleareExchangeWindow;
  tCallWindowSetFocus;
  CallAlreadySent := False;
  ExchangeHasBeenSent := False;
  SetOpMode(SearchAndPounceOpMode);

  if PInteger(@Spot.FCall[1])^ = tCQAsInteger then Exit;
  if PInteger(@Spot.FCall[1])^ = tNEWAsInteger then Exit;
  PutCallToCallWindow(Spot.FCall);

  if not QSOByMode then EntryMode := Both;
  DispalayB4(integer(
//  CallsignsList.CallsignIsDupe(CallWindowString, EntryBand, EntryMode, Index)
    VisibleLog.CallIsADupe(CallWindowString, EntryBand, EntryMode)
    ));

end;

procedure DeleteSpotFromBandmap;
var
  i                                     : integer;
begin
  i := SendMessage(BandMapListBox, LB_GETCURSEL, 0, 0);
  if i = LB_ERR then Exit;
  SpotsList.Delete(SendMessage(BandMapListBox, LB_GETITEMDATA, i, 0));
  SpotsList.Display;
  if tLB_SETCURSEL(BandMapListBox, i) = LB_ERR then tLB_SETCURSEL(BandMapListBox, i - 1);
  ShowSpotInfo;
end;

procedure SetTextInBMSB(Index: integer; Text: PChar);
begin
  SendMessage(BandMapStatusBar, SB_SETTEXT, Index, integer(Text));
end;

procedure ShowSpotInfo;
var
  i                                     : integer;
  Spot                                  : TSpotRecord;
  TempString                            : ShortString;
begin
  ClearSpotInfo;
  i := GetBMSelItemData; //SendMessage(BandMapListBox, LB_GETITEMDATA, tLB_GETCURSEL(BandMapListBox), 0);
  if i = LB_ERR then Exit;

  Spot := SpotsList.Get(i);
  SetTextInBMSB(0, @Spot.FCall[1]);

  Format(wsprintfBuffer, TC_MIN, Spot.FMinutesLeft);

  SetTextInBMSB(1, wsprintfBuffer);

  i := PInteger(@Spot.FCall[1])^;
  if i = tCQAsInteger then Exit;
  if i = tNEWAsInteger then Exit;

//  TempString := CountryTable.GetCountryName(CountryTable.GetCountry(Spot.FCall, True));
  SetTextInBMSB(2, ctyGetCountryNamePchar(ctyGetCountry(Spot.FCall)));

  Format(wsprintfBuffer, TC_SOURCE, @Spot.FSourceCall[1]);

  SetTextInBMSB(3, wsprintfBuffer);

  SetTextInBMSB(4, Spot.FNotes);
end;

procedure ClearSpotInfo;
var
  i                                     : integer;
begin
  for i := 0 to 4 do SetTextInBMSB(i, nil);
end;

function GetBMSelItemData: integer;
begin
  if BandMapListBox = 0 then
  begin
    Result := LB_ERR;
    Exit;
  end;
  Result := SendMessage(BandMapListBox, LB_GETCURSEL, 0, 0);
  if Result = LB_ERR then Exit;
  Result := SendMessage(BandMapListBox, LB_GETITEMDATA, Result, 0);
end;

function NEWBMLBPROC(hwnddlg: HWND; Msg: UINT; wParam: LONGINT; lParam: LONGINT): integer; stdcall;
var
  i                                     : integer;
  TempWord                              : Word;
  zDelta                                : Smallint;
begin
  //WM_ERASEBKGND WM_PAINT WM_SETREDRAW WM_NCPAINT
  Result := 0;
  if Msg = WM_MOUSEWHEEL then
  begin
    if wParam > 0 then VFOBumpUp else VFOBumpDown;
    Exit;
  end;
  Result := CallWindowProc(OLDBMLBPROC, hwnddlg, Msg, wParam, lParam);

end;

end.

