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
unit uRemMults;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  uCommctrl,
  uCTYDAT,
  uMults,
  Windows,
  LogEdit,
  PostUnit,
  LogWind,
  uGradient,
  Tree,
  //Country9,
  LogDom,
  LogDupe,
  LOGSUBS2,
  Messages
  ;

function RemainingMultsDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure UpdateRemainingMultsWindows;
//var  RemainingMultsWindowHandle            : HWND;

implementation

uses MainUnit;

var
  RemMultsBuf                           : array[0..7] of Char;
//  ShowToolTip                           : boolean;
//  PrevItem                              : integer;

function RemainingMultsDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  p                                     : PChar;
  DS                                    : PDrawItemStruct;
  i                                     : integer;
  Index                                 : integer;
  TempCall                              : CallString;
  Gradient                              : boolean;
  rmt                                   : RemainingMultiplierType;
//  pnt                                   : TPoint;
//  Item                                  : integer;
//  temprect                              : TRect;
const
  WM_NCMOUSELEAVE                       = $02A2;
begin
   p := ''; // 4.79.3
  Result := False;
  case Msg of
    //    WM_WINDOWPOSCHANGING: WINDOWPOSCHANGINGPROC(PWindowPos(lParam));
    //    WM_EXITSIZEMOVE: FrmSetFocus;
    WM_SIZE, WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);
//    WM_CTLCOLORLISTBOX: RESULT := BOOL(tr4wBrushArray[ColorColors.RemainingMultsWindowBackground]);

{
    WM_NCMOUSELEAVE:
//    WM_NCMOUSEMOVE:
      begin
        if ShowToolTip then
        begin
//          ti.lpszText := nil;
//          SendMessage(hwndTT, TTM_UPDATETIPTEXT, 0, integer(@ti));
          SendMessage(hwndTT, TTM_TRACKACTIVATE, 0, integer(@ti));
          ShowToolTip := False;
        end;
      end;
}

    WM_DRAWITEM:
      begin
        Result := True;
        DS := Pointer(lParam);

        if (DS^.itemAction = ODA_FOCUS) then
        begin
//          DrawFocusRect(DS^.HDC, DS^.rcItem);

          Exit;
        end;

        if CleanSweep then
        begin
          Windows.TextOut(DS^.HDC, 0, 0, TC_CLEANSWEEPCONGRATULATIONS, 31);
          Exit;
        end;

        SendMessage(DS^.hwndItem, LB_GETITEMDATA, DS^.ItemID, 0);
        asm
        mov byte ptr rmt,al
        mov al,0
        shr eax,$10
        mov index,eax
        end;
//if ActiveZoneMult = EUHFCYear then        dec(Index);

//        Index := HiWord(SendMessage(DS^.hwndItem, LB_GETITEMDATA, DS^.ItemID, 0));
//        rmt := RemainingMultiplierType(LoWord(SendMessage(DS^.hwndItem, LB_GETITEMDATA, DS^.ItemID, 0)));

        case rmt of

          rmPrefix:
            begin
              Windows.ZeroMemory(@TempCall, SizeOf(TempCall));
              TempCall := mo.PrfList.Get(Index);
              p := @TempCall[1];
              Gradient := mo.PrfList.StringIsDupeByIndex(Index, MultBand, MultMode);
            end;

          rmDomestic:
            begin
              Windows.ZeroMemory(@TempCall, SizeOf(TempCall));

              if tShowDomesticMultiplierName and (mo.DomList.FList[Index].FAltName <> '') then
                TempCall := mo.DomList.FList[Index].FAltName
              else
                TempCall := mo.DomList.Get(Index);

              p := @TempCall[1];
              // Why is this QD here? When the program first starts, it display a mut for no reason.
              // Why would we display the mult in the quick display?
              // We do not do this for other multipler types.
              // I commented this out for now.
              // quickdisplay(p);
              Gradient := mo.DomList.StringIsDupeByIndex(Index, GetAddMultBand(DomesticMultByBand, MultBand), MultMode);
            end;

          rmDX:
            begin
              p := @CTY.ctyTable[Index].ID[1];
              Gradient := not mo.IsDXMult(Index, MultBand, MultMode);
            end;

          rmZone:
            begin
//              if ActiveZoneMult = EUHFCYear then
//                Gradient := not mo.IsZnMult(Index-1, MultBand, MultMode)
//              else
              Gradient := not mo.IsZnMult(Index, MultBand, MultMode);

              if Gradient then
                asm nop end;
              asm
                mov eax, Index
                cmp byte ptr [ActiveZoneMult],EUHFCYear
                jnz @@1
//                sub eax,1
                @@1:
                push eax
              end;
              wsprintf(RemMultsBuf, '%02u');
              asm add esp,12 end;
              p := @RemMultsBuf;
            end;
{
            Zone:
              if ActiveZoneMult <> EUHFCYear then
                Str(Index + 1: 2, TempString)
              else
                Str(Index: 2, TempString);
}
        end;

        i := Windows.lstrlen(p);
{
        if RemMultsColumnWidthArray[rmt] < i then
        begin
          RemMultsColumnWidthArray[rmt] := i;
          tLB_SETCOLUMNWIDTH(hwnddlg, i * 10);
        end;
}
        if RemainingMultDisplayMode = HiLight then

          //if not RemainingMults[Index] then
          if Gradient then
          begin
//            Windows.SetTextColor(DS^.HDC, tr4wColorsArray[trLightGray]);
            Windows.SetTextColor(DS^.HDC, tr4wColorsArray[trWhite]);
            GradientRect(DS^.HDC, DS^.rcItem, tr4wColorsArray[tr4wColors(Ord(rmt) * 1)], tr4wColorsArray[trWhite], gdHorizontal);
          end
          else
          begin
            Windows.SetTextColor(DS^.HDC, tr4wColorsArray[trBlack {ColorColors.RemainingMultsWindowColor}]);
          end;

        SetBkMode(DS^.HDC, TRANSPARENT);

        Windows.TextOut(DS^.HDC, DS^.rcItem.Left + 2, DS^.rcItem.Top, p, i);

      end;

    WM_INITDIALOG:
      begin
        tWM_SETFONT(CreateOwnerDrawListBox(LB_STYLE_1, hwnddlg), MainFixedFont);

        tr4w_WindowsArray[WindowsType(lParam)].WndHandle := hwnddlg;

        case WindowsType(lParam) of

         tw_STATIONS_RM_DOM: p := 'Domestic'; // 4.91.5

          tw_STATIONS_RM_PREFIX:
            begin
//              p := 'Prefixes';
//              if ActivePrefixMult = CallSignPrefix then
//              tLB_SETCOLUMNWIDTH(hwnddlg, PREFIXCOLUMNWIDTH)   // 4.91.4
//               else
                tLB_SETCOLUMNWIDTH(hwnddlg, BASECOLUMNWIDTH);
            end;

          tw_STATIONS_RM_DX:
            begin
//              p := 'DX';
              tLB_SETCOLUMNWIDTH(hwnddlg, BASECOLUMNWIDTH);
            end;


          tw_STATIONS_RM_ZONE:
            begin
//              p := 'Zones';
              tLB_SETCOLUMNWIDTH(hwnddlg, BASECOLUMNWIDTH);
            end;
          tw_REMMULTSWINDOW_INDEX: p := 'Remaining mults';  // 4.91.5
        end;
         Windows.SetWindowText(hwnddlg, p);    // 4.91.5

        SetRemMultsColumnWidth;

   //      tWM_SETFONT(RemainingMultsWindowHandle, MainFixedFont);
    //      if DoingDomesticMults or DoingDXMults or DoingZoneMults then    // 4.68.10         // 4.72.3
        VisibleLog.ShowRemainingMultipliers;

//        if RemMultsColumnWidthArray[RemainingMultDisplay] > 0 then
//          tLB_SETCOLUMNWIDTH(hwnddlg, RemMultsColumnWidthArray[RemainingMultDisplay] * 10);
      end;
{
    WM_COMMAND:
      begin
        if HiWord(wParam) = LBN_DBLCLK then
        begin
          SwapMultDisplay;
          FrmSetFocus;
        end;

      end;
}
    WM_CLOSE: CloseTR4WWindow(GetWindowByHandle(hwnddlg));

  end;
end;

procedure UpdateRemainingMultsWindows;
begin
  SetRemMultsColumnWidth;
  VisibleLog.ShowRemainingMultipliers ;
end;

end.

