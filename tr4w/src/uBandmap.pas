{
 Copyright Dmitriy Gulyaev UA4WLI 2015.

 This file is part of TR4W  (SRC)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W in  GPL_License.TXT. 
If not, ref: 
http://www.gnu.org/licenses/gpl-3.0.txt
 }
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
procedure KillFocus;                                         // Gav 4.47.4 #141
procedure SetTextInBMSB(Index: integer; Text: PChar);
function GetBMSelItemData: integer;
function NEWBMLBPROC(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): integer; stdcall;


const

  CheckRectWidth                        = 17;
                                            //      Below line was (80, 130, 240, 350, 510, 580); ny4i
  BMPanelWidth                          : array[0..5] of integer = (80, 130, 240, 350, 580, 650); //ny4i added 70 to last two to extend the comment section
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
  BandMapPreventRefresh                 : boolean;             // Gav 4.37.12
  //  DoNotAddToBandMap                : boolean;
  // BandMapListBoxHDC                     : HDC;
 // tr4w_NetedToBlink                      : boolean;
  BMWSBUFFER                            : array[0..16] of Char;
  PreviousDisplayedBandmapBand          : BandType {= NoBand};
  BandColor                             : Cardinal;
  BandMapItemHeight                     : integer = CheckRectWidth;
  BandMapItemWidth                      : integer = 150;
  BandMapFreqWidthCalculated            : boolean;
  BandMapDisplayGhz                     : boolean;
  
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
//  TempHDC                               : HDC;
const
  BMWIDE                                = 10; // n4af 4.42.8
  GHZ                                   = 10; // n4af 4.42.8
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

     //   BandMapItemWidth := FreqRectWidth + 1 + CheckRectWidth + 1 + 65;  

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
            if not BandMapDisplayGhz then                            // n4af 4.42.8
            FreqRectWidth := Size.cx + BMWide
            else
            FreqRectWidth := Size.cx + BMWide + Ghz;
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
    
        //WM_ERASEBKGND:WINDOWS.TextOut(hdc(WPARAM),50,50,'aaaaaa',6);
    WM_INITDIALOG:
      begin
        BandMapListBox := CreateOwnerDrawListBox(LB_STYLE_1, hwnddlg);
        asm
            mov edx,[MainFixedFont]
            call tWM_SETFONT
        end;

        BandMapStatusBar := Windows.GetDlgItem(hwnddlg, 102);

        BandMapStatusBar := tWM_SETFONT(CreateWindow(STATUSCLASSNAME, nil, {SBT_NOBORDERS or} CCS_TOP or CCS_NOMOVEY or WS_CHILD or WS_VISIBLE, 100, 100, 100, 100, hwnddlg, 101, hInstance, nil), MainFixedFont);
        Windows.SendMessage(BandMapStatusBar, SB_SETBKCOLOR, 0, $00FFFF00);

//        tLB_SETCOLUMNWIDTH(hwnddlg, BandMapItemWidth);

        BandMapEnable := True;
        SendMessage(BandMapStatusBar, SB_SETPARTS, 6, integer(@BMPanelWidth));
//      SetTimer(hwnddlg, BANDMAP_BLINK_TIMER_HANDLE, 600, nil);     //n4af
        tr4w_WindowsArray[tw_BANDMAPWINDOW_INDEX].WndHandle := hwnddlg;
   //      BandMapListBoxHDC := Windows.GetDC(BandMapListBox);
     //           DoNotAddToBandMap := False;       

        DisplayBandMap;
      end;

    WM_COMMAND:
      begin

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
              KillFocus;                                         // Gav 4.47.4 #141
            end;
          205: If TwoRadioMode then InvertBooleanCommand(@QSYInactiveRadio);   // Gav     4.37.12

        end;

        case HiWord(wParam) of
          LBN_SETFOCUS:
            begin
              BandMapPreventRefresh := True;      // Gav     4.37.12
              SpotsList.SetCursor;
              ShowSpotInfo;
            end;
          LBN_KILLFOCUS:
            begin
              KillFocus;                                         // Gav 4.47.4 #141
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
              if  QSYInactiveRadio and  TwoRadioMode then          // 4.92.1                         //Gav 4.37.12
                begin
                TuneRadioToSpot(SpotsList.Get(TempInt), InActiveRadio);
               end
              else
              begin
                TuneRadioToSpot(SpotsList.Get(TempInt), ActiveRadio);
              end;
              KillFocus;                                  // Gav 4.47.4 #141
            end;
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
  if QSYInactiveRadio and TwoRadioMode then Windows.CheckMenuItem(BandMapMenu, 205, MF_CHECKED); //GAV  4.37.12

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
//  Index                                 : integer;
  QZBOffset                             : integer;
const
  MAX_QZB_OFFSET                        = 30;
begin
  QZBOffset := 0;       // 4.92.4
  if (OpMode = SearchAndPounceOpMode)
    then
  begin
    LastSPFrequency := ActiveRadioPtr^.LastDisplayedFreq;
    LastSPMode := ActiveMode;
  end;

//?
  EntryBand := NoBand;
  EntryMode := NoMode;
 // logger.Trace('trace output');
  GetBandMapBandModeFromFrequency(Spot.FFrequency, EntryBand, EntryMode);
//  logger.Trace('>>>Entering GetBandMapMode freq = %s',[spot.FFrequency]);
 logger.debug(' Freq = <%s> ',[spot.ffrequency]);
 // logger.trace( 'Band = <%s>', Entryband);
  //  logger.debug ('Calling ParametersOkay with call = %s, Band = %s, Mode = %s, freq = %d, ExchangeString = %s', [call,BandStringsArray[Band], ModeStringArray[Mode], freq, ExchangeString]);

  if (EntryBand = NoBand) then exit;
  if ((radio1.filteredstatus.freq=0) or (radio2.filteredstatus.freq=0)) then
   begin
    QSYInActiveRadio := False;
    InBandLock := False;
   end ;
//     else                  // 4.94.2
 //     QSYInActiveRadio := True;
  if ((InBandLock) and (TwoRadioMode)) then
   begin
    if QSYInactiveRadio then
     if ((InActiveRadioPtr.BandMemory <> EntryBand) and (EntryBand = ActiveRadioPtr.BandMemory)) then
      begin
       QuickDisplay(TC_2radio_warn);
       exit;
      end;
  if not QSYInactiveRadio then
    if ((ActiveBand <> EntryBand) and (EntryBand = InActiveRadioPtr.BandMemory))  then        // 4.92.1
       begin
        QuickDisplay(TC_2radio_warn);
        exit;
       end;
    end;

  // Sleep(100);  4.92.4
  SetRadioFreq(Radio, Spot.FFrequency + QZBOffset, EntryMode, 'A');
  PutRadioOutOfSplit(Radio);
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
  end ;

  if Radio = InactiveRadio then
    begin
      InActiveRadioPtr.BandMemory := Spot.FBand;       //Gav 4.37
      InActiveRadioPtr.ModeMemory := Spot.FMode;       //Gav 4.37
      Exit;
    end;
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
//  TempString                            : ShortString;
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


procedure KillFocus;                                         // Gav 4.47.4 #141
begin
  BandMapPreventRefresh := False;
  SpotsList.SendAndClearBuffer;
  DisplayBandMap;
  Windows.SetFocus(wh[mweCall]);
end;


function GetBMSelItemData: integer;
begin
  if BandMapListBox = 0 then Exit;
  begin
      Result := SendMessage(BandMapListBox, LB_GETCURSEL, 0, 0);
        if Result = LB_ERR then Exit;
        Result := SendMessage(BandMapListBox, LB_GETITEMDATA, Result , 0);
  end;

end;

function NEWBMLBPROC(hwnddlg: HWND; Msg: UINT; wParam: LONGINT; lParam: LONGINT): integer; stdcall;

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

