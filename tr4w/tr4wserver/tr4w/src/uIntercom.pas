unit uIntercom;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Tree,
  uGradient,
  utils_file,
  Windows,
  LogEdit,
  LogWind,
  LogStuff,
  Messages;

function IntercomDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure AddMessageToIntercomWindow(mes: PChar; Sender: Char);
procedure FlashIntercomListBox;
procedure EnumINTERCOMTXT(FileString: PShortString);

var
  IntercomListBoxHandle            : HWND;
  LastItemInIntercomListBox        : integer;

implementation
uses MainUnit;

function IntercomDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var

  i                                : integer;
  MessageBuf                       : array[0..79] of Char;
  Color                            : integer;
  TextColor                        : integer;
begin
  Result := False;
  case Msg of
{
    WM_DRAWITEM:

      begin
        IntercomDIS := Pointer(lParam);
        if (IntercomDIS^.itemAction = ODA_FOCUS) then
        begin
          DrawFocusRect(IntercomDIS^.HDC, IntercomDIS^.rcItem);
          Exit;
        end;

        if IntercomDIS^.itemAction = ODA_DRAWENTIRE then
        begin
          i := SendMessage(IntercomDIS^.hwndItem, LB_GETTEXT, IntercomDIS^.ItemID, integer(@MessageBuf));
          Color := tr4wColorsArray[tr4wColors(((Ord(MessageBuf[6]) - Ord('A')) mod integer(High(tr4wColors))))];

//          Color := clgreen;
          GradientRect(IntercomDIS^.HDC, IntercomDIS^.rcItem, Color, Color, gdHorizontal);
          asm
          mov eax,Color
          bswap eax
          mov TextColor,eax
          end;
          TextColor := $00FFFFFF - Color;
          Windows.SetTextColor(IntercomDIS^.HDC, TextColor);
          SetBkMode(IntercomDIS^.HDC, TRANSPARENT);
          Windows.TextOut(IntercomDIS^.HDC, IntercomDIS^.rcItem.Left + 2, IntercomDIS^.rcItem.Top, MessageBuf, i);
          Result := True;
        end;
      end;
}
    //    WM_WINDOWPOSCHANGING: WINDOWPOSCHANGINGPROC(PWindowPos(lParam));
    //    WM_EXITSIZEMOVE: FrmSetFocus;
    WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);

    WM_SIZE:
      begin
        tListBoxClientAlign(hwnddlg);
        SendMessage(IntercomListBoxHandle, WM_VSCROLL, SB_BOTTOM, 0);
      end;

    WM_INITDIALOG:
      begin
        IntercomListBoxHandle := CreateOwnerDrawListBox(LB_STYLE_3,hwnddlg);
        asm
            mov edx,[MainFixedFont]
            call tWM_SETFONT
        end;

        EnumerateLinesInFile('INTERCOM.TXT', EnumINTERCOMTXT, false);
      end;

    WM_COMMAND:
      begin
        if HiWord(wParam) = LBN_DBLCLK then ProcessMenu(menu_send_message);
      end;

    WM_CLOSE: 1:
      begin
        IntercomListBoxHandle := 0;
        CloseTR4WWindow(tw_INTERCOMWINDOW_INDEX);
      end;

  end;
end;

procedure AddMessageToIntercomWindow(mes: PChar; Sender: Char);
var
  stored                           : integer;
  h                                : HWND;
  lpThreadId                       : DWORD;
begin
  if tr4w_WindowsArray[tw_INTERCOMWINDOW_INDEX].WndHandle = 0 then
    ProcessMenu(menu_windows_intercom);

  asm
  push mes

  xor eax,eax
  mov al,byte ptr  Sender
  push eax

  xor eax,eax
  call GetTimeString
  push eax
  end;
  stored := wsprintf(wsprintfBuffer, '%s %C :   %s');
  asm add esp,20
  end;

  if IntercomFileenable then
  begin
    h := CreateFile(TR4W_INTERCOM_FILENAME, GENERIC_WRITE or GENERIC_READ, FILE_SHARE_WRITE or FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);
    if h <> INVALID_HANDLE_VALUE then
    begin
      SetFilePointer(h, 0, nil, FILE_END);
      sWriteFile(h, wsprintfBuffer, stored);
      sWriteFile(h, #13#10, 2);
      CloseHandle(h);
    end;
  end;
  h := IntercomListBoxHandle;
  if h = 0 then Exit;
  LastItemInIntercomListBox := tLB_ADDSTRING(h, @wsprintfBuffer);
  SendMessage(h, WM_VSCROLL, SB_BOTTOM, 0);
  tCreateThread(@FlashIntercomListBox, lpThreadId);
end;

procedure FlashIntercomListBox;
var
  counter                          : Cardinal;
  h                                : HWND;
  r                                : TRect;
  DC                               : HDC;
begin
  counter := 0;
  h := IntercomListBoxHandle;
  SendMessage(h, LB_SETSEL, 0, -1);
//  SendMessage(h, LB_GETITEMRECT, LastItemInIntercomListBox, integer(@r));
//  DC := Windows.GetWindowDC(h);
  while counter < 49 do
  begin
    SendMessage(h, LB_SETSEL, counter mod 2, LastItemInIntercomListBox);

//    Windows.TextOut(DC, 0, r.Top, inttopchar(counter), 2);
//Windows.InvertRect(DC, r);
//    InvalidateRect(h, @r, true);
    Sleep(150);
    inc(counter);
  end;
end;

procedure EnumINTERCOMTXT(FileString: PShortString);
begin
  tLB_ADDSTRING(IntercomListBoxHandle, @FileString^[1]);
end;

end.

