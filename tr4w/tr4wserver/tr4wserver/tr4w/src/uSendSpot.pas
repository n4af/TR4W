unit uSendSpot;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  uNet,
  Windows,
  LogStuff,
  LogK1EA,
  LogWind,
  LogRadio,
  LogEdit,
  WinSock2,
  PostUnit,
  Messages;

function SendSpotDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation
uses uTelnet,
  MainUnit;

function SendSpotDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  i                                     : integer;
  Hz100                                 : integer;
  p                                     : PChar;
  LastCallsign                          : CallString;
const
  l                                     : array[1..3] of PChar = (RC_CALLSIGN, RC_FREQUENCY, RC_COMMENT);
label
  1;
begin
  Result := False;
  case Msg of
//    WM_HELP: tWinHelp(59);
    WM_INITDIALOG:
      begin
        Windows.SetWindowText(hwnddlg, RC_SENDSPOT);
        for i := 1 to 3 do
        begin
          CreateStatic(l[i], 10, i * 30 - 20, 100, hwnddlg, 100 + i);
          CreateEdit(0, 120, i * 30 - 20, 160, 23, hwnddlg, 106 + i);
        end;

        CreateButton(BS_AUTOCHECKBOX or BS_VCENTER, RC_CONTESTNAMEIC, 10, 100, 200, hwnddlg, 104);

        CreateOKCancelButtons(hwnddlg);

        if CallWindowString <> '' then
          SetDlgItemText(hwnddlg, 107, @CallWindowString[1])
        else
        begin
          Windows.ZeroMemory(@LastCallsign, SizeOf(LastCallsign));
          LastCallsign := VisibleLog.LastEntry(True,letCallsign);
          SetDlgItemText(hwnddlg, 107, @LastCallsign[1]);
        end;

        Hz100 := ActiveRadioPtr.LastDisplayedFreq {LastDisplayedFreq[ActiveRadio]} mod 100;
        i := ActiveRadioPtr.LastDisplayedFreq {LastDisplayedFreq[ActiveRadio]} - Hz100;
        if Hz100 >= 50 then i := i + 100;

        SetDlgItemText(hwnddlg, 108, FreqToPChar(i));

        if tContestNameInComment then
        begin
          Windows.SendDlgItemMessage(hwnddlg, 104, BM_SETCHECK, BST_CHECKED, 0);
          Windows.SetDlgItemText(hwnddlg, 109, ContestTypeSA[Contest]);
        end;
      end;

    WM_COMMAND:
      begin
        if ((HiWord(wParam) = BN_CLICKED) and (LoWord(wParam) = 104)) or (HiWord(wParam) = BM_SETCHECK) then
        begin

          if TF.SendDlgItemMessage(hwnddlg, 104, BM_GETCHECK) = BST_CHECKED
            then
          begin
            p := ContestTypeSA[Contest];
            tContestNameInComment := True;
          end
          else
          begin
            p := nil;
            tContestNameInComment := False;
          end;
          SetDlgItemText(hwnddlg, 109, p);
        end;

        case wParam of
{$IF LANG = 'RUS'}
          110: ShowHelp('ru_dxcluster'); //#отправка_спота');
{$IFEND}

           2: goto 1;

          1:
            begin

              PInteger(@TempBuffer2)^ := $00005844 {DX#0#0};
              TempBuffer1[0] := ' ';
              for i := 107 to 109 do
              begin
                Windows.GetDlgItemText(hwnddlg, i, @TempBuffer1[1], SizeOf(TempBuffer1) - 1);
                Windows.lstrcat(TempBuffer2, TempBuffer1);
              end;
              if TelnetSock <> 0 then
                SendViaTelnetSocket(TempBuffer2)
              else
              begin
                Windows.ZeroMemory(@SendSpotViaNetwork.vnMessage, SizeOf(SendSpotViaNetwork.vnMessage));
                Windows.CopyMemory(@SendSpotViaNetwork.vnMessage, @TempBuffer2, SizeOf(SendSpotViaNetwork.vnMessage) - 1);
                SendToNet(SendSpotViaNetwork, SizeOf(SendSpotViaNetwork));
              end;
//              if I <> 0 then ShowSyserror(I);
              goto 1;
            end;
        end;
      end;
    WM_CLOSE: 1: EndDialog(hwnddlg, 0);
  end;
end;
end.

