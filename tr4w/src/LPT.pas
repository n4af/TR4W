unit LPT;
{$IMPORTEDDATA OFF}
interface

uses
  uCFG,
  TF,
  VC,
  CFGCMD,
  LogK1EA,
  uIO,
  LogWind,
  LogCfg,
  LogRadio,
  Tree,
  Windows,
  Messages;

var
LPTBaseAddressArray                   : array[Parallel1..Parallel3] of Cardinal = ($378, $278, $3BC);  
function LPTDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation
uses MainUnit;

function LPTDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose;
var
  c                                     : Cardinal;
  Top                                   : Cardinal;
  ID, CMD                               : ShortString;
  Style                                 : Cardinal;
//  p                                     : PChar;
const
  LPTPortNamesArray                     : array[1..6] of PChar = ('FOOT SWITCH', 'PADDLE', 'RADIO ONE BAND OUTPUT', 'RADIO TWO BAND OUTPUT', 'RELAY CONTROL', 'STEREO CONTROL');
begin
  Result := False;
  case Msg of
    //    WM_HELP: tWinHelp(49);
    WM_INITDIALOG:
      begin

        CreateOKCancelButtons(hwnddlg);
        Windows.SetWindowText(hwnddlg, 'LPT');

        for c := 1 to 3 do
        begin
          Top := c * (17 + 8);

          Format(wsprintfBuffer, 'LPT%u BASE ADDRESS', c);

          tCreateStaticWindow(wsprintfBuffer, LeftVisNoSunStyle, 10, Top, 180, 17, hwnddlg, 100 + c);
          tCreateEditWindow(WS_EX_STATICEDGE, nil, ES_UPPERCASE or ES_NUMBER or WS_TABSTOP or WS_CHILD or SS_center or WS_VISIBLE, 200, Top, 80, 17, hwnddlg, 200 + c);
        end;
        tSetDlgItemIntFalse(hwnddlg, 201, LPTBaseAA[Parallel1]);
        tSetDlgItemIntFalse(hwnddlg, 202, LPTBaseAA[Parallel2]);
        tSetDlgItemIntFalse(hwnddlg, 203, LPTBaseAA[Parallel3]);

        for c := 1 to 6 do
        begin
          Top := c * (17 + 8) + 100;

          Format(wsprintfBuffer, '%s PORT', LPTPortNamesArray[c]);

          tCreateStaticWindow(wsprintfBuffer, LeftVisNoSunStyle, 10, Top, 180, 17, hwnddlg, 103 + c);
          Style := CBS_DROPDOWNLIST or WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_TABSTOP;
          if tUseControlPort and (c < 3) then Style := Style or WS_DISABLED;

          tCreateComboBoxWindow(Style, 200, Top, 80, hwnddlg, 203 + c);

          tCB_ADDSTRING(hwnddlg, 203 + c, 'NONE');
          for Top := 1 to 3 do
            tCB_ADDSTRING(hwnddlg, 203 + c, IntToStr(Top));
          tCB_SETCURSEL(hwnddlg, 203 + c, 0);
        end;
        if ActiveFootSwitchPort <> NoPort then tCB_SETCURSEL(hwnddlg, 204, Ord(ActiveFootSwitchPort) - 20);
        if ActivePaddlePort <> NoPort then tCB_SETCURSEL(hwnddlg, 205, Ord(ActivePaddlePort) - 20);

        if Radio1.BandOutputPort <> NoPort then tCB_SETCURSEL(hwnddlg, 206, Ord(Radio1.BandOutputPort) - 20);
        if Radio2.BandOutputPort <> NoPort then tCB_SETCURSEL(hwnddlg, 207, Ord(Radio2.BandOutputPort) - 20);
        if RelayControlPort <> NoPort then tCB_SETCURSEL(hwnddlg, 208, Ord(RelayControlPort) - 20);
        if ActiveStereoPort <> NoPort then tCB_SETCURSEL(hwnddlg, 209, Ord(ActiveStereoPort) - 20);
        EnableWindowFalse(hwnddlg, 50);
      end;
    WM_COMMAND:
      begin
        if wParam = 2 then goto ExitAndClose;
        if wParam = 1 then
        begin
          for c := 101 to 109 - 0 do
          begin
            Windows.ZeroMemory(@ID, SizeOf(ID));
            Windows.ZeroMemory(@CMD, SizeOf(CMD));

            ID := GetDialogItemText(hwnddlg, c);
            CMD := GetDialogItemText(hwnddlg, c + 100);
            Windows.WritePrivateProfileString(_COMMANDS, @ID[1], @CMD[1], TR4W_INI_FILENAME);
            CheckCommand(@ID, CMD);

            tDoingFootSwitchEnable := ActiveFootSwitchPort <> NoPort;
            DoingPaddle := ActivePaddlePort <> NoPort;
          end;

          if tUseControlPort then
            if Radio1.tCATPortHandle <> INVALID_HANDLE_VALUE then
            begin
              DoingPaddle := True;
              tDoingFootSwitchEnable := True;
            end;

          tDispalyPaddleAndFootSwitchStatus;

          if (DoingPaddle = False) and (tDoingFootSwitchEnable = False) then
          begin
            tExitFromPaddleFootSwitchThread := True;
            tPaddleFootSwitchThread := INVALID_HANDLE_VALUE;
          end
          else
          begin
            TryRunPaddleAndFootSwitchThread;
          end;
          InitializeOtherLPTPorts;
            //              end;
          goto ExitAndClose;
        end;
        if wParam = 51 then goto ExitAndClose;
        if wParam = 52 then MainUnit.ProcessMenu(item_calculator);

        if (HiWord(wParam) = CBN_SELCHANGE) or (HiWord(wParam) = EN_CHANGE) then
          EnableWindowTrue(hwnddlg, 50);
      end;

    WM_CLOSE:
      begin
        ExitAndClose:
        EndDialog(hwnddlg, 0);
      end;

  end;
end;
end.

