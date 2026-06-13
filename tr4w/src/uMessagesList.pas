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
unit uMessagesList;

interface

uses
  VC,
  TF,
  Windows,
  Messages;

function MessagesListDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

var
  LastSelectedCommand                   : String;

implementation

uses
  uProcessCommand,
  MainUnit;

// Extract the insertable command token from a caCommand display string.
// Entries have the form "  CMD = description" or just "CMDNAME".
// We strip leading spaces, then take everything up to the first " = "
// separator (searching from position 1 so that "  = = BT" yields "=").
// Trailing spaces are also stripped.

function GetInsertableCommand(src: PChar): String;
var
  start, p, eqStart: PChar;
  len: Integer;
begin
  Result := '';

  // Skip leading spaces
  start := src;
  while start^ = ' ' do
    Inc(start);
  if start^ = #0 then
    Exit;

  // Look for ' = ' separator beginning one character past start
  // so that a command that IS '=' (e.g. "  = = BT") is not treated
  // as a separator itself.
  eqStart := nil;
  p := start + 1;
  while p^ <> #0 do
    begin
    if (p[0] = ' ') and (p[1] = '=') and (p[2] = ' ') then
      begin
      eqStart := p;
      Break;
      end;
    Inc(p);
    end;

  if eqStart <> nil then
    begin
    p := eqStart;
    while (p > start) and (p[-1] = ' ') do
      Dec(p);
    len := p - start;
    end
  else
    begin
    p := start + Windows.lstrlen(start);
    while (p > start) and (p[-1] = ' ') do
      Dec(p);
    len := p - start;
    end;

  if len > 0 then
    SetString(Result, start, len);
end;

// Fetch the text of the currently selected listbox item (ID 90) and store
// the extracted command in LastSelectedCommand. Returns True if an item was
// selected. We go through LB_GETTEXT rather than indexing sCommandsArray
// because the listbox is created with LBS_SORT — its visible index order
// does not match the array's insertion order.

function TryCaptureSelectedCommand(hwnddlg: HWND): Boolean;
var
  lb: HWND;
  sel, textLen: Integer;
  buf: array[0..255] of Char;
begin
  Result := False;
  lb := GetDlgItem(hwnddlg, 90);
  sel := SendMessage(lb, LB_GETCURSEL, 0, 0);
  if sel = -1 then
    Exit;
  textLen := SendMessage(lb, LB_GETTEXTLEN, sel, 0);
  if (textLen < 0) or (textLen >= SizeOf(buf)) then
    Exit;
  SendMessage(lb, LB_GETTEXT, sel, Integer(@buf));
  LastSelectedCommand := GetInsertableCommand(@buf);
  Result := True;
end;

function MessagesListDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  TempHWND                              : HWND;
  i                                     : integer;
begin
  Result := False;
  case Msg of
    WM_SETFONT:
      begin
        // Issue #997: removed asm nop. WM_SETFONT is intentionally ignored
        // (Result stays False -> default processing).
      end;

    WM_INITDIALOG:
      begin
//        CreateButton('OK', 180, 305, 70, hwnddlg, 1);
        CreateOKCancelButtons( hwnddlg);
        Windows.SetWindowText(hwnddlg, TC_LIST_OF_COMMAND);
        TempHWND := CreateListBox(5, 5, 440, 280, hwnddlg, 90);

        for i := 0 to sCommands - 1 do
        begin
          Format(wsprintfBuffer, '%s', sCommandsArray[i].caCommand);
          tLB_ADDSTRING(TempHWND, wsprintfBuffer);
        end;

      end;

    WM_COMMAND:
      begin
      // Double-click on list box: insert selected command and close
      if (HiWord(wParam) = LBN_DBLCLK) and (LoWord(wParam) = 90) then
        begin
        if TryCaptureSelectedCommand(hwnddlg) then
          EndDialog(hwnddlg, 1);
        end;
      case wParam of
        1:  // OK: insert if something is selected, otherwise just close
          begin
          if TryCaptureSelectedCommand(hwnddlg) then
            EndDialog(hwnddlg, 1)
          else
            goto 1;
          end;
        2: goto 1;  // Cancel
      end;
      end;

    WM_CLOSE: 1: EndDialog(hwnddlg, 0);

  end;
end;

end.

