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
unit uInputQuery;
{$IMPORTEDDATA OFF}
interface

uses
  VC,
  TF,
  Windows,
  Messages;

var
  IQresult                              : ShortString;
  IQMaxInputLength                      : integer;

function IQDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation

uses MainUnit;

function IQDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  iqicon                                : integer;
  TempPchar                             : PChar;
  dwNewLong                             : LONGINT;
const
  MainStyle                             = WS_CHILD + WS_VISIBLE + WS_TABSTOP + ES_CENTER + ES_AUTOHSCROLL;
  l                                     = 40;
  w                                     = 370;
begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin
        tWM_SETFONT(CreateEdit(ES_CENTER or ES_AUTOHSCROLL or ES_UPPERCASE or WS_CHILD or WS_VISIBLE or WS_TABSTOP, l, 40, w, 28, hwnddlg, 101), MainWindowEditFont);
        CreateOKCancelButtons(hwnddlg);

        CreateStatic(IQPrompt, l , 10, w , hwnddlg, 102);
        CreateWindow(StaticPChar, nil, SS_ICON or WS_CHILD or WS_VISIBLE, 3, 10, 32, 32, hwnddlg, 106, hInstance, nil);

        dwNewLong := MainStyle;

        if not tInputDialogLowerCase then dwNewLong := dwNewLong + ES_UPPERCASE;
        if tInputDialogInteger then dwNewLong := dwNewLong + ES_NUMBER;

//        SetDlgItemText(hwnddlg, 102, IQPrompt);
        Windows.SetWindowText(hwnddlg, 'TR4W');
        SendDlgItemMessage(hwnddlg, 101, EM_LIMITTEXT, IQMaxInputLength, 0);
{
        TempPchar := IDI_QUESTION;
        if tInputDialogWarning then TempPchar := IDI_WARNING;
        iqicon := LoadIcon(0, TempPchar);
        SendDlgItemMessage(hwnddlg, 106, STM_SETIMAGE, IMAGE_ICON, iqicon);
}
        SendDlgItemMessage(hwnddlg, 106, STM_SETIMAGE, IMAGE_ICON, LoadIcon(0, integer(IDI_QUESTION) + PChar(integer(tInputDialogWarning))));

        Windows.SetWindowLong(Get101Window(hwnddlg), GWL_STYLE, dwNewLong);
        SetDlgItemText(hwnddlg, 101, @tInputDialogPreviousValue[1]);

        tInputDialogWarning := False;
        tInputDialogInteger := False;
        tInputDialogLowerCase := False;
        Windows.ZeroMemory(@tInputDialogPreviousValue, SizeOf(tInputDialogPreviousValue));
        Windows.ZeroMemory(@IQresult, SizeOf(IQresult));
      end;

    WM_COMMAND:
      case wParam of
        2:
          begin
            IQresult := '';
            goto 1; //    SendMessage(hwnddlg, WM_CLOSE, 0, 0);
          end;

        1:
          begin
            IQresult := GetDialogItemText(hwnddlg, 101);
            goto 1;
          end;

      end;

    WM_CLOSE: 1:
      begin
        tLoadKeyboardLayout;
        EndDialog(hwnddlg, 0);
      end;
  end;

end;
end.

