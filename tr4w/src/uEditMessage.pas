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
unit uEditMessage;
{$IMPORTEDDATA OFF}
interface
//
uses
  uMessagesList,
  uGradient,
  CFGCMD,
  TF,
  VC,
  uCommctrl,
  utils_file,
  Windows,
  Messages,
  MMSystem,
  Tree,
  LogWind

  ;

function EditMessageDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam:
  lParam): BOOL; stdcall;
function NewMsgEditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam:
  lParam): UINT; stdcall;
procedure CreateHintListBox;
function DestroyHintListBox: boolean;
procedure AddHintsToHintListBox;
procedure MoveSelectedItemInHintListBox(wParam: integer);
procedure DeleteEscapeChars(var s: ShortString);

type
  THintMessageType = packed record
    hmVisibleCommand: PChar;
    hmCommand: PChar;
    hmComment: PChar;

  end;
const
  MESSAGESHINTS = 55;

var
  flashreminder: boolean;
  ReminderDlgHandle: HWND;
  MsgEditHWND: HWND;
  OldMsgEditProc: Pointer;
  AllowEscapes: boolean;
  ControlSpace: boolean;
  HintListView: HWND;
  EditMessageWnd: HWND;
  //  EditMessageWndRect                    : TRect;
  SelectedItemInHitListBox: integer;
  HintListBoxCreated: boolean;
  SelPos: array[102..103] of integer = (255, 255);
implementation
uses uCFG,
  uAltP,
  MainUnit;

function EditMessageDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam:
  lParam): BOOL; stdcall;
label
  1 ;
var
  i: Cardinal;
  ID: Str80;
  CMD: ShortString;
  h: HWND;
  p: PChar;
  //  HDS                                   : PDrawItemStruct;
  //  Color1                                : Cardinal;
const
  m = 'Messages';

begin
  Result := False;
  case Msg of

    WM_INITDIALOG:
      begin

        Windows.SetWindowText(hwnddlg, RC_PROGRMESS);

        CreateStatic(nil, 5, 5, 450 + 40, hwnddlg, 101);
        CreateStatic(RC_MESSAGE, 5, 35, 60, hwnddlg, 107);
        CreateStatic(RC_CAPTION, 5, 60, 60, hwnddlg, 106);

        CreateEdit(0, 70, 35, 385 + 40, 23, hwnddlg, 102);
        CreateEdit(0, 70, 60, 385 + 40, 23, hwnddlg, 103);

        EditMessageWnd := hwnddlg;
        for i := 0 to 2 do
        begin
          ListView_GetItemText(AltPListView, lParam, i, TempBuffer1,
            SizeOf(TempBuffer1));
          Windows.SetDlgItemText(hwnddlg, 101 + i, TempBuffer1);
          //if I = 2 then Continue;

          GetDlgItem(hwnddlg, 101 + i);
          asm
          mov edx,[TerminalFont]
          call tWM_SETFONT
          end;

        end;
        if MesWindow = OtherMsgWin then
          EnableWindowFalse(hwnddlg, 103);
        MsgEditHWND := GetDlgItem(hwnddlg, 102);
        OldMsgEditProc := Pointer(Windows.SetWindowLong(MsgEditHWND,
          GWL_WNDPROC, integer(@NewMsgEditProc)));

        CreateOKCancelButtons(hwnddlg);
        CreateButton(0, TC_LIST_OF_COMMAND, 385, 105, 110, hwnddlg, 3);
        CreateButton(0, RC_EDIT_WORD, 5, 105, 110, hwnddlg, 109);

        if ActiveMode <> Phone then
          TF.EnableWindowFalse(hwnddlg, 109);

        //        goto 2;
      end;

    WM_CLOSE: 1:
      begin
        //if ActiveMode = Phone then sndPlaySound(nil, SND_ASYNC or SND_NODEFAULT);
        EndDialog(hwnddlg, 0);
      end;

    //    WM_MOUSEACTIVATE, WM_MOVING: begin DestroyHintListBox; end;
    //    WM_MOVE: 2: Windows.GetWindowRect(EditMessageWnd, EditMessageWndRect);
    WM_COMMAND:
      begin

        //        if HiWord(wParam) = LBN_DBLCLK then PutCommandFromHintListBox;
        if HiWord(wParam) = EN_SETFOCUS then
        begin
          Windows.SendDlgItemMessage(hwnddlg, LoWord(wParam), EM_SETSEL,
            SelPos[LoWord(wParam)], SelPos[LoWord(wParam)]);
        end;

        if HiWord(wParam) = EN_KILLFOCUS then
        begin
          Windows.SendDlgItemMessage(hwnddlg, LoWord(wParam), EM_GETSEL,
            integer(@SelPos[LoWord(wParam)]), integer(@SelPos[LoWord(wParam)]));
        end;
        //        if lParam = integer(MsgEditHWND) then if HiWord(wParam) = EN_KILLFOCUS then DestroyHintListBox;

        case wParam of
          3: CreateModalDialog(225, 170, EditMessageWnd, @MessagesListDlgProc,
            0);
          109:
            begin
              i := Windows.GetDlgItemText(hwnddlg, 102, @TempBuffer2,
                SizeOf(ID));
              if i < 5 then
                Exit;
              if PInteger(@TempBuffer2[i - 4])^ <> 1447122734 then
                Exit;

              if TR4W_DVP_RECORDER_FILENAME[0] = #0 then
              begin
                SetCommand('DVP RECORDER');
                Exit;
              end;

              p := GetRealPath(TR4W_DVKPATH, TempBuffer2, nil);

              if not FileExists(p) then
              begin
                if YesOrNo(hwnddlg, TC_THIS_FILE_DOES_NOT_EXIST) = IDno then
                  Exit;
                if tOpenFileForWrite(h, p) then
                begin
                  sWriteFile(h, waveheader, length(waveheader));
                  CloseHandle(h);
                end;
              end;

              Format(TempBuffer1, '"%s" "%s"', TR4W_DVP_RECORDER_FILENAME, p);
              WinExec(TempBuffer1, SW_SHOWNORMAL);
              //              if FileExists(TempBuffer1) then if sndPlaySound(TempBuffer1, SND_ASYNC or SND_NODEFAULT) then Exit;
              //              ShowSysErrorMessage('PLAY FILE');
            end;

         
          1: //if not PutCommandFromHintListBox then
            begin
              ID[0] := Char(Windows.GetDlgItemText(hwnddlg, 101, @ID[1], 80));

              CMD[0] := Char(Windows.GetDlgItemText(hwnddlg, 102, @CMD[1], 255));
           {   if (ord(CMD[1]) > 32) then
               if (ord(CMD[1]) <  122) then
                begin
                 CMD[1] := '_';
                end;    }
              DeleteEscapeChars(CMD);
              Windows.WritePrivateProfileString(m, @ID[1], @CMD{@CMD[1]},
                @TR4W_CFG_FILENAME);
              CheckCommand(@ID, CMD);

              if MesWindow <> OtherMsgWin then
              begin
                i := Windows.GetDlgItemText(hwnddlg, 103, @CMD[1], 255);
                //              if I <> 0 then
                begin
                  CMD[0] := CHR(i);
                  Windows.lstrcat(@ID[1], ' CAPTION');
                  inc(Byte(ID[0]), 8);
                  p := @CMD[1];
                  if CMD = '' then
                    p := nil;
                  Windows.WritePrivateProfileString(m, @ID[1], p,
                    @TR4W_CFG_FILENAME);
                  CheckCommand(@ID, CMD);
                end;
              end;

              DisplaymessagesList(MesWindow, ActiveMode);
              goto 1;
            end;
        end;
      end;
  end;
end;

function NewMsgEditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam:
  lParam): UINT; stdcall;
var
  c: Cardinal;
  Selection: TSelection;
  i: integer;
begin
  Result := 0;
  if Msg = WM_CHAR then
  begin
    // 3  -1070071807
    // 4  -1070071807
    //    if wParam = $2665 then showint(wParam);
    //    wParam := 65;
    //    Exit;
    if ControlSpace then
    begin
      ControlSpace := False;
      Exit;
    end;
  end;
  {
    if Msg = WM_KEYUP then
    begin
      if wParam = 32 then
        if GetKeyState(VK_CONTROL) < -126 then
        begin
          CreateHintListBox;
          wParam := 0;
        end;
    end;
  }
  if Msg = WM_PASTE then
    if GetKeyState(VK_CONTROL) < -126 then
      Exit;

  if Msg = WM_KEYDOWN then
  begin
    //    Windows.SetWindowText(EditMessageWnd, inttopchar(wParam));
    if HintListBoxCreated then
      if wParam in [VK_UP, VK_DOWN, VK_HOME, VK_END, VK_PRIOR, VK_NEXT] then
      begin
        MoveSelectedItemInHintListBox(wParam);
        Exit;
      end;
    if GetKeyState(VK_CONTROL) < -126 then
    begin

      //      if wParam = 32 then
      //      begin
      //        ControlSpace := True;
      //        CreateHintListBox;
      //      end;

      if wParam <> 17 then
      begin

        if wParam = 80 then
          if not AllowEscapes then
          begin
            AllowEscapes := True;
            Exit;
          end;
        if not AllowEscapes then
          Exit;

        SendMessage(MsgEditHWND, EM_GETSEL, LONGINT(@Selection.StartPos),
          LONGINT(@Selection.EndPos));
        c := Windows.GetWindowText(MsgEditHWND, TempBuffer1, 255);

        TempBuffer1[c + 1] := #0;
        if c <> 0 then
          for i := c - 1 downto Selection.EndPos do
            TempBuffer1[i + 1] := TempBuffer1[i];
        TempBuffer1[Selection.StartPos] := CHR(wParam - 64);

        Windows.SetWindowText(MsgEditHWND, TempBuffer1);
        Windows.SendMessage(MsgEditHWND, EM_SETSEL, Selection.StartPos + 1,
          Selection.EndPos + 1);
        AllowEscapes := False;
      end;
    end;
  end;

  Result := CallWindowProc(OldMsgEditProc, hwnddlg, Msg, wParam, lParam);

  //  if Msg = WM_CHAR then showint(RESULT);
end;

procedure CreateHintListBox;
begin
  if HintListBoxCreated then
    Exit;
  HintListView := CreateWindowEx
    (WS_EX_DLGMODALFRAME,
    'SysListView32' {LISTBOX},
    nil,

    //    WS_BORDER + LBS_NOTIFY or LBS_OWNERDRAWFIXED or LBS_NOINTEGRALHEIGHT or WS_POPUP { WS_CHILD } or WS_VISIBLE + WS_VSCROLL,
    WS_POPUP or WS_VISIBLE or LVS_SINGLESEL or LVS_REPORT or LVS_NOCOLUMNHEADER
      + LVS_SHOWSELALWAYS,
    //    40, 40,

        {EditMessageWndRect.Left +}15,
    {EditMessageWndRect.Top + }105,

    485 + 30,
    200,
    EditMessageWnd,
    0,
    hInstance,
    nil);
  asm
            mov edx,[MainFixedFont]
            call tWM_SETFONT
  end;
  ListView_SetExtendedListViewStyle(HintListView, LVS_EX_GRIDLINES +
    LVS_EX_FULLROWSELECT);
  AddHintsToHintListBox;
  HintListBoxCreated := True;
  SetFocus(EditMessageWnd);
end;

function DestroyHintListBox: boolean;
begin
  Result := HintListBoxCreated;
  if HintListBoxCreated then
    Windows.DestroyWindow(HintListView);
  HintListBoxCreated := False;
end;

procedure AddHintsToHintListBox;
//var  elvc                                  : tagLVCOLUMNA;
begin
  {
    elvc.Mask := LVCF_WIDTH or LVCF_FMT;
    elvc.fmt := LVCFMT_LEFT;
    elvc.cx := 120;
    ListView_InsertColumn(HintListView, 0, elvc);

    elvc.cx := 340;
    ListView_InsertColumn(HintListView, 1, elvc);

    for I := 0 to MESSAGESHINTS - 1 do
    begin
      elvi.Mask := LVIF_TEXT;
      elvi.iItem := I;
      elvi.iSubItem := 0;
      elvi.pszText := HintMessageArray[I].hmVisibleCommand;

      ListView_InsertItem(HintListView, elvi);

      elvi.iSubItem := 1;
      elvi.pszText := HintMessageArray[I].hmComment;
      ListView_SetItem(HintListView, elvi);
    end;
    elvi.Mask := LVIF_STATE;
    elvi.stateMask := 3;
    elvi.State := LVIS_SELECTED or LVIS_FOCUSED;
    ListView_SetItemState(HintListView, 0, LVIS_SELECTED or LVIS_FOCUSED, 3);
  }
  //  SendMessage(HintListBox, LVM_SETITEMSTATE, 0, LONGINT(@elvi));
  //  SendMessage(HintListBox, LVM_SETBKCOLOR, 0, $FFFFff00);
  //  SendMessage(HintListBox, LVM_SETTEXTBKCOLOR, 0, $0000ffff);

  {
    for I := 0 to MESSAGESHINTS - 1 do SendMessage(HintListBox, LB_ADDSTRING, 0, I);
    tLB_SETCURSEL(HintListBox, 0);
  }
  SelectedItemInHitListBox := 0;
end;

procedure MoveSelectedItemInHintListBox(wParam: integer);
begin

  if wParam = VK_UP then
  begin
    if SelectedItemInHitListBox > 0 then
      dec(SelectedItemInHitListBox)
    else
      Exit;
  end;

  if wParam = VK_DOWN then
  begin
    if SelectedItemInHitListBox < MESSAGESHINTS - 1 then
      inc(SelectedItemInHitListBox)
    else
      Exit;
  end;

  if wParam = VK_END then
    SelectedItemInHitListBox := MESSAGESHINTS - 1;
  if wParam = VK_HOME then
    SelectedItemInHitListBox := 0;

  if wParam = VK_NEXT then
  begin
    SelectedItemInHitListBox := SelectedItemInHitListBox + 11;
    if SelectedItemInHitListBox > (MESSAGESHINTS - 1) then
      SelectedItemInHitListBox := MESSAGESHINTS - 1;
  end;

  if wParam = VK_PRIOR then
  begin
    SelectedItemInHitListBox := SelectedItemInHitListBox - 11;
    if SelectedItemInHitListBox < 0 then
      SelectedItemInHitListBox := 0;
  end;
  ListView_SetItemState(HintListView, SelectedItemInHitListBox, LVIS_SELECTED or
    LVIS_FOCUSED, 3);
  SendMessage(HintListView, LVM_ENSUREVISIBLE, SelectedItemInHitListBox,
    LONGINT(False));
  //  SendMessage(HintListBox, LVM_REDRAWITEMS, 0, 100);

  //  tLB_SETCURSEL(HintListBox, SelectedItemInHitListBox);
end;

procedure DeleteEscapeChars(var s: ShortString);
const
  HexChars: array[0..$F] of Char = '0123456789ABCDEF';
var
  TempString: ShortString;
  i: integer;
  l: integer;
begin
  l := 0;
  for i := 1 to length(s) do
  begin
    inc(l);
    if s[i] > CHR(31) then
    begin
      TempString[l] := s[i];
    end
    else
    begin
      TempString[l] := '<';
      TempString[l + 1] := HexChars[Ord(s[i]) shr $4];
      TempString[l + 2] := HexChars[Ord(s[i]) and $F];
      TempString[l + 3] := '>';
      inc(l, 3);
    end;
  end;
  TempString[0] := Char(l);
  s := TempString;
  s[l + 1] := #0;
end;

end.

