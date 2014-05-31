unit f_; {Funktion Keys WinAPI}

interface

uses

   WINDOWS,
   Messages;

function FKDlgProc(hwnddlg: HWND; msg: UINT; wparam: WPARAM; lparam: LPARAM): bool; stdcall;

var
   fkeyshandle                     : hwnd;
   CTRLhandle                      : hwnd;
   ALThandle                       : hwnd;

implementation
uses unit1;

function FKDlgProc(hwnddlg: HWND; msg: UINT; wparam: WPARAM; lparam: LPARAM): bool; STDCALL;
var
   w                               : word;
begin
   Result := false;
   case Msg of
      WM_INITDIALOG:
         begin
            fkeyshandle := hwnddlg;
            CTRLhandle := GetDlgItem(hwnddlg, 126);
            ALThandle := GetDlgItem(hwnddlg, 125);
         end;

      WM_LBUTTONDOWN:
         begin
            {drag window}
            Result := BOOL(DefWindowProc(hwnddlg, Msg, wparam, lparam));
            PostMessage(hwnddlg, WM_SYSCOMMAND, $F012, 0);
         end;

      WM_COMMAND:
         begin
            if (wparam >= 112) and (wparam <= 123) then
               begin
                  w := wparam;
                  unit1.FRM.FormKeyDown(nil, w, []);
                  //                  SendDlgItemMessage(hwnddlg, wparam, BM_SETSTYLE, BS_3STATE, 1);
                  SendDlgItemMessage(hwnddlg, wparam, BN_KILLFOCUS, 0, 0);
                  SendDlgItemMessage(hwnddlg, 126, 45068, 0, 0);
                  windows.SetFocus(FRM.Handle);
               end;

         end;

      {WM_DESTROY, }WM_CLOSE: { enddialog(hwnddlg, 0)} destroywindow(hwnddlg);

   end;

end;

end.
