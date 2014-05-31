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
  b                                     : Byte;
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

procedure GetButtonByRDblClick(h: HWND);
var
  i                                     : integer;
begin
  for i := 112 to 123 do
    if h = KeysHandles[i] then
    begin
      if OpMode = SearchAndPounceOpMode then
        MesWindow := ExMsgWin
      else
        MesWindow := CQMsgWin;
//      tDialogBox(72, @MemoryProgramDlgProc);
      OpenListOfMessages;
    end;
end;

end.

