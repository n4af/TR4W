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
unit uFunctionKeys;

{$IMPORTEDDATA OFF}

interface

uses
  uGradient,
  TF,
  VC,
  Windows,
  Messages,
utils_text,
  uAltP,
  LogWind,
  LogCW,
  Tree;

function FunctionKeysWindowDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure ShowFMessages(VirtualKey: Byte);
procedure GetButtonByRDblClick(h: HWND);
procedure EditFunctionKeyMessage(h: HWND);
procedure ShowFunctionKeyContextMenu(h: HWND);

const
  ButtonsColor                          : array[112..123] of tcolor =

  (
    clwhite,
    clwhite,
    clwhite,
    clwhite,

    clYellow,
    clYellow,
    clYellow,
    clYellow,

    clwhite,
    clwhite,
    clwhite,
    clwhite
    );

{
  (
    clblue,
    clblue,
    clblue,
    clblue,

    clYellow,
    clYellow,
    clYellow,
    clYellow,

    clblue,
    clblue,
    clblue,
    clblue
    );
}
var
  KeysHandles                           : array[112..123] of HWND;
  ButtonsText                           : array[112..123] of Str40;

//  FKCloseButton                         : HWND;
  FKRButtonTimerHAndle                  : HWND;
  tIncludeFKeyNumber                    : boolean;

implementation
uses
  MainUnit;

function FunctionKeysWindowDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  i                                     : integer;
  Left                                  : integer;
  temprect                              : TRect;
  Width                                 : integer;
  Height                                : integer;
  FKDRAWITEMSTRUCT                      : PDrawItemStruct;
  TempCardinal                          : Cardinal;
  TempColor                             : tcolor;
//  b                                     : Byte;
const
//  fkbstleft                             = 26;
  delta                                 = 2;
//  FKCloseButtonID                       = 222;
//  ClosrButWidth                         = 14-14;
begin
  Result := False;
  case Msg of
    WM_LBUTTONDOWN, WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);

    WM_DRAWITEM:
      begin
        Result := True;
        FKDRAWITEMSTRUCT := Pointer(lParam);
{
        if FKDRAWITEMSTRUCT^.hwndItem = FKCloseButton then
        begin
          TempCardinal := DFCS_CAPTIONCLOSE or DFCS_FLAT;
          if (lobyte(FKDRAWITEMSTRUCT^.itemState) = ODS_SELECTED or ODS_FOCUS) then TempCardinal := DFCS_CAPTIONCLOSE or DFCS_PUSHED;
          DrawFrameControl(FKDRAWITEMSTRUCT^.HDC, FKDRAWITEMSTRUCT^.rcItem, DFC_CAPTION, TempCardinal);
          Exit;
        end;
}
        if (lobyte(PDrawItemStruct(lParam).itemState) = ODS_SELECTED or ODS_FOCUS) then

          TempCardinal := EDGE_SUNKEN
        else
        begin
          TempCardinal := {EDGE_RAISED; //} EDGE_ETCHED;
        end;

        DrawEdge(FKDRAWITEMSTRUCT^.HDC, FKDRAWITEMSTRUCT^.rcItem, TempCardinal, BF_TOPLEFT or BF_BOTTOMRIGHT);

//        DrawFrameControl(FKDRAWITEMSTRUCT^.HDC, FKDRAWITEMSTRUCT^.rcItem, DFC_BUTTON, DFCS_BUTTONPUSH	);

        FKDRAWITEMSTRUCT^.rcItem.Right := FKDRAWITEMSTRUCT^.rcItem.Right - delta;
        FKDRAWITEMSTRUCT^.rcItem.Left := FKDRAWITEMSTRUCT^.rcItem.Left + delta;
        FKDRAWITEMSTRUCT^.rcItem.Top := FKDRAWITEMSTRUCT^.rcItem.Top + delta;
        FKDRAWITEMSTRUCT^.rcItem.Bottom := FKDRAWITEMSTRUCT^.rcItem.Bottom - delta;

        SetBkMode(FKDRAWITEMSTRUCT^.HDC, TRANSPARENT);
        TempColor := ButtonsColor[FKDRAWITEMSTRUCT^.CtlID];
//        TempColor := tr4wColorsArray[tr4wColors(FKDRAWITEMSTRUCT^.CtlID - 112+4)];
        GradientRect(FKDRAWITEMSTRUCT^.HDC, FKDRAWITEMSTRUCT^.rcItem, TempColor, TempColor, gdVertical);

//        b := GetGValue(Cardinal(ButtonsColor[FKDRAWITEMSTRUCT^.CtlID]));
//        if b < 128 then
//        if TempColor = 0 then
        Windows.SetTextColor(FKDRAWITEMSTRUCT^.HDC, 0);

{
        TempColor := ButtonsColor[FKDRAWITEMSTRUCT^.CtlID];
        asm
        mov eax,TempColor
        cmp eax,0
        jnz @@1
        mov eax,clWhite
        @@1:
        bswap eax
        mov TempColor,eax
        end;
        Windows.SetTextColor(FKDRAWITEMSTRUCT^.HDC, TempColor);
}
        if (lobyte(FKDRAWITEMSTRUCT^.itemState) = ODS_SELECTED or ODS_FOCUS) then
        begin
          FKDRAWITEMSTRUCT^.rcItem.Bottom := FKDRAWITEMSTRUCT^.rcItem.Bottom + delta;
          FKDRAWITEMSTRUCT^.rcItem.Right := FKDRAWITEMSTRUCT^.rcItem.Right + delta;
        end;
        Windows.DrawText(
          FKDRAWITEMSTRUCT^.HDC,
          @ButtonsText[FKDRAWITEMSTRUCT^.CtlID][1],
          length(ButtonsText[FKDRAWITEMSTRUCT^.CtlID]),
          FKDRAWITEMSTRUCT^.rcItem,
          {DT_END_ELLIPSIS + }DT_EDITCONTROL + DT_WORDBREAK + DT_CENTER + DT_VCENTER);
      end;

    WM_SIZE:
      begin
        Windows.GetClientRect(hwnddlg, temprect);
        Width := (temprect.Right - temprect.Left - 30) div 12;
        Height := temprect.Bottom - temprect.Top;
        Left := 0;
        for i := 112 to 123 do
        begin

          Windows.MoveWindow(KeysHandles[i], Left, 0, Width, Height, True);
          inc(Left, Width + 1);
          if (i = 115) or (i = 119) then inc(Left, 10);
        end;
//        Windows.MoveWindow(FKCloseButton, temprect.Right - temprect.Left - ClosrButWidth, 0, ClosrButWidth, ClosrButWidth, True);
        InvalidateRect(hwnddlg, nil, False);
      end;

    WM_INITDIALOG:
      begin
        tr4w_WindowsArray[tw_FUNCTIONKEYSWINDOW_INDEX].WndHandle := hwnddlg;

        for i := 112 to 123 do
        begin
          KeysHandles[i] := tCreateButtonWindow(0, nil, BS_OWNERDRAW or BS_AUTORADIOBUTTON or BS_PUSHLIKE or BS_LEFT or WS_CHILD or WS_VISIBLE or BS_NOTIFY, 0, 0, 0, 0, hwnddlg, i);
          asm
            mov edx,[MainFixedFont]
            call tWM_SETFONT
          end;
        end;
//        FKCloseButton := tCreateButtonWindow(0, nil, BS_OWNERDRAW or BS_PUSHLIKE or WS_CHILD or WS_VISIBLE or BS_NOTIFY, 0, 0, 0, 0, hwnddlg, FKCloseButtonID);

        ShowFMessages(0);
//        for I := 112 to 115 do ButtonsColor[I] := $FFFFFF;
//        for I := 116 to 119 do ButtonsColor[I] := $FF0000;
//        for I := 120 to 123 do ButtonsColor[I] := $0000FF;
      end;

    WM_CLOSE: 1: CloseTR4WWindow(tw_FUNCTIONKEYSWINDOW_INDEX);

    WM_COMMAND:
      begin
//        if wParam = FKCloseButtonID then goto 1;
        if HiWord(wParam) = BN_CLICKED then
          if LoWord(wParam) in [112..123] then
          begin
            FrmSetFocus;
            ProcessFuntionKeys(LoWord(wParam));
          end;
      end;
  end;

end;

procedure ShowFMessages(VirtualKey: Byte);
var
  i                                     : integer;
  s                                     : string;
  plus                                  : Byte;
  PosOfAmp                              : integer;
  b                                     : Char;
  TempMode                              : ModeType;
begin

  if not tWindowsExist(tw_FUNCTIONKEYSWINDOW_INDEX) then Exit;
  TempMode := ActiveMode;
  if TempMode = FM then TempMode := Phone;
  if TempMode = Digital then TempMode := CW;

  if not (TempMode in [CW, Phone {, FM, Digital}]) then Exit;
  plus := VirtualKey;
  for i := 112 to 123 do
  begin
    b := CHR(i + plus);
    if OpMode2 {OpMode} = CQOpMode then
    begin
      if ((CQCaptionMemory[TempMode, b] <> nil) and (CQCaptionMemory[TempMode, b]^ <> '')) then
        s := CQCaptionMemory[TempMode, b]^
      else
        s := GetCQMemoryString(TempMode, b);
    end
    else
    begin
      if ((EXCaptionMemory[TempMode, b] <> nil) and (EXCaptionMemory[TempMode, b]^ <> '')) then
        s := EXCaptionMemory[TempMode, b]^
      else
        s := GetEXMemoryString(TempMode, b);
    end;
    PosOfAmp := tPos(s, '&');
    if PosOfAmp <> 0 then Insert('&', s, PosOfAmp);
    if tIncludeFKeyNumber then
      ButtonsText[i] := 'F' + IntToStr(i - 111) + #13#10 + s
    else
      ButtonsText[i] := s;
    InvalidateRect(KeysHandles[i], nil, False);
  end;
end;

// Resolve which Alt-P editor row the on-screen function-key button `h` maps to,
// and set the CQ vs S&P target window. The 12 buttons are labelled F1..F12 but
// display whichever shift bank the window currently shows (plain / Ctrl / Alt),
// so we read the live modifier state. The editor lists F1..AltF12, hence
// row = (button - 112) + bank offset (0/12/24). Returns -1 if `h` is not a
// function-key button. Caller must capture this BEFORE the modifier is released
// (e.g. before popping a menu). Issue #1001.
function ResolveFunctionKeyRow(h: HWND): integer;
var
  i                                     : integer;
  plus                                  : integer;
begin
  Result := -1;
  for i := 112 to 123 do
     begin
     if h = KeysHandles[i] then
        begin
        if OpMode = SearchAndPounceOpMode then
           MesWindow := ExMsgWin
        else
           MesWindow := CQMsgWin;
        plus := 0;
        if (GetKeyState(VK_MENU) and $8000) <> 0 then
           plus := 24
        else if (GetKeyState(VK_CONTROL) and $8000) <> 0 then
           plus := 12;
        Result := (i - 112) + plus;
        Break;
        end;
     end;
end;

// Open the Alt-P message editor focused on the function key whose button is `h`
// (mode- and shift-bank-aware). Used by the legacy right-double-click path.
procedure EditFunctionKeyMessage(h: HWND);
var
  row                                   : integer;
begin
  row := ResolveFunctionKeyRow(h);
  if row < 0 then Exit;
  InitialAltPSelection := row;
//tDialogBox(72, @MemoryProgramDlgProc);
  OpenListOfMessages;
  FrmSetFocus;   // see note in ShowFunctionKeyContextMenu
end;

procedure GetButtonByRDblClick(h: HWND);
begin
  EditFunctionKeyMessage(h);
end;

// Right-click a function-key button -> show a one-item context menu that opens
// the editor on that key. The target row is captured NOW (while any Alt/Ctrl
// modifier is still held) so the bank stays correct even after the user
// releases the modifier to click the menu. Label is composed from translated
// words; the key name (e.g. "F3") is not translated. Issue #1001.
procedure ShowFunctionKeyContextMenu(h: HWND);
const
  ID_EDITFKEY                           = 1;
var
  row                                   : integer;
  prefix                                : string;
  keyName                               : string;
  caption                               : string;
  p                                     : integer;
  hMenu                                 : Windows.HMENU;   // qualified: an 'HMENU' identifier in this unit's scope shadows the type
  pt                                    : Windows.TPoint;
  cmd                                   : integer;
begin
  // Issue #1007: ignore right-click while Alt or Ctrl is held. The window is
  // showing the Alt-F/Ctrl-F bank then, and popping the menu + the FrmSetFocus
  // that follows would flash the labels back to plain (WM_SETFOCUS ->
  // ShowFMessages(0)). Right-click edits the plain F-keys only; edit the
  // Alt-F/Ctrl-F messages via the Alt-P editor.
  if ((GetKeyState(VK_MENU) and $8000) <> 0)    or
     ((GetKeyState(VK_CONTROL) and $8000) <> 0) then
     begin
     Exit;
     end;
  row := ResolveFunctionKeyRow(h);
  if row < 0 then Exit;

  case row div 12 of            // 0 = plain, 1 = Ctrl, 2 = Alt
     1: prefix := 'Ctrl-F';
     2: prefix := 'Alt-F';
  else
     prefix := 'F';
  end;
  keyName := prefix + IntToStr((row mod 12) + 1);   // e.g. 'F3', 'Ctrl-F10' (not translated)
  // TC_EDITFUNCTIONKEY is the per-language 'Edit %s message' format; substitute
  // the key name for %s. Pos/Copy avoids a wsprintf varargs call.
  caption := TC_EDITFUNCTIONKEY;
  p := Pos('%s', caption);
  if p > 0 then
     caption := Copy(caption, 1, p - 1) + keyName + Copy(caption, p + 2, Length(caption));

  hMenu := Windows.CreatePopupMenu;
  Windows.AppendMenu(hMenu, MF_STRING, ID_EDITFKEY, PChar(caption));
  Windows.GetCursorPos(pt);
  // NB: do NOT SetForegroundWindow here -- it fires WM_SETFOCUS, whose handler
  // calls ShowFMessages(0) and reverts the function-key window to the plain
  // bank while the menu is up (mismatching an "Edit Ctrl-Fn" label). The app is
  // already foreground on right-click, so the menu dismisses fine without it
  // (same as the band-map popup). Issue #1001.
  cmd := integer(Windows.TrackPopupMenu(hMenu,
                 TPM_RETURNCMD or TPM_LEFTALIGN or TPM_TOPALIGN or TPM_LEFTBUTTON,
                 pt.x, pt.y, 0, tr4whandle, nil));
  Windows.DestroyMenu(hMenu);

  if cmd = ID_EDITFKEY then
     begin
     InitialAltPSelection := row;    // captured before the modifier was released
     OpenListOfMessages;
     end;

  // Right-clicking the button + showing the menu (and the modal editor) leaves
  // focus off the Call window. Restore it -- the Ctrl/Alt bank-switch handler in
  // the main loop only fires when focus is the Call/Exchange window, so without
  // this those keys stop updating the F-key labels. Mirrors the left-click
  // (BN_CLICKED) handler above. Issue #1001.
  FrmSetFocus;
end;

end.

