unit uMessagesList;

interface

uses
  VC,
  TF,
  Windows,
  Messages;

function MessagesListDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation

uses
  uProcessCommand,
  MainUnit;

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
        asm nop end;
      end;

    WM_INITDIALOG:
      begin
//        CreateButton('OK', 180, 305, 70, hwnddlg, 1);
        CreateOKCancelButtons( hwnddlg);
        Windows.SetWindowText(hwnddlg, TC_LIST_OF_COMMAND);
        TempHWND := CreateListBox(5, 5, 440, 280, hwnddlg, 90);

        for i := 0 to sCommands - 1 do
        begin
          Format(wsprintfBuffer, '<03>%s<04>', sCommandsArray[i].caCommand);
          tLB_ADDSTRING(TempHWND, wsprintfBuffer);
        end;

      end;

    WM_COMMAND:
      begin
        case wParam of
          1, 2: goto 1;
        end;
//        if HiWord(wParam) = LBN_DBLCLK then ProcessMenu(menu_send_message);
      end;

    WM_CLOSE: 1: EndDialog(hwnddlg, 0);

  end;
end;

end.

