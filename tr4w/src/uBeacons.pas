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
unit uBeacons;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  Tree,
  LogGrid,
  LogRadio,
  LogK1EA,
  //Country9,
  Messages;

function BeaconsMonitorDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure SetBeaconFreq(h: HWND; Control: integer);
procedure ShowBeaconsNames(h: HWND);

var
  BeaconsHandle                         : array[0..17, 0..4] of HWND;
  FC                                    : Byte;

const
  BEACONS                               = 18;
  BeaconsNames                          : array[0..BEACONS - 1] of PChar = ('4U1UN', 'VE8AT', 'W6WX', 'KH6WO', 'ZL6B', 'VK6RBP', 'JA2IGY', 'RR9O', 'VR2B', '4S7B', 'ZS6DN', '5Z4B', '4X6TU', 'OH2B', 'CS3B', 'LU4AA', 'OA4B', 'YV5B');
{
  BeaconsGrids                          : array[0..BEACONS - 1] of string[4] = (
    'FN30',
    'EQ79',
    'CM97',
    'BL11',
    'RE78',
    'OF87',
    'PM84',
    'NO14',
    'OL72',
    'NJ06',
    'KG44',
    'KI88',
    'KM72',
    'KP20',
    'IM12',
    'GF05',
    'FH17',
    'FK60'
    );
}
  FreqArray                             : array[101..110] of Word = (14100, 18110, 21150, 24930, 28200, 10000, 9996, 5000, 4996, 10144);
implementation
uses MainUnit;

function BeaconsMonitorDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose;
var
  r, c                                  : Byte;
  delta                                 : integer;
  Top                                   : integer;
begin
  Result := False;
  case Msg of
//    WM_HELP: tWinHelp(49);

{$IF LANG = 'RUS'}
    WM_HELP: ShowHelp('ru_beaconsmonitor');
{$IFEND}
    WM_INITDIALOG:
      begin

        Windows.SetWindowText(hwnddlg, RC_BEACONSM);

        SetBeaconFreq(hwnddlg, 101);

        for r := 0 to 17 do
          for c := 0 to 4 do
          begin
              //            Left := 10 + c * 67;
            BeaconsHandle[r, c] :=
              tCreateStaticWindow(
              BeaconsNames[r], WS_DISABLED or WS_CHILD or BS_TEXT or WS_VISIBLE or WS_TABSTOP or BS_NOTIFY or SS_SUNKEN or SS_CENTER,
              10 + c * 65, 30 + r * 16, 62, 15, hwnddlg, 0);
{
            asm
            mov edx,[ArialFont]
            call tWM_SETFONT
            end;
}
          end;

        delta := 0;
        Top := 5;
        for c := 101 to 110 do
        begin
          if c > 105 then
          begin
            delta := 325;
            Top := 320;
          end;
          tCreateButtonWindow(WS_EX_STATICEDGE, inttopchar(FreqArray[c]), BS_AUTORADIOBUTTON + BS_PUSHLIKE + WS_CHILD + WS_VISIBLE + WS_TABSTOP,
            10 + (c - 101) * 65 - delta, Top, 62, 20, hwnddlg, c);
        end;

        Windows.SendDlgItemMessage(hwnddlg, 101, BM_SETCHECK, BST_CHECKED, 0);

        SetTimer(hwnddlg, BEACONS_ONE_SECOND_TIMER_HANDLE, 1000, nil);
//        SendDlgItemMessage(hwnddlg, 99, PBM_SETRANGE, 0, MakeLParam(0, 10000));
//        SendDlgItemMessage(hwnddlg, 99, PBM_SETSTEP, 1, 0);
        ShowBeaconsNames(hwnddlg);
      end;
    WM_TIMER:
      begin
        //tGetSystemTime;
        //Sec := UTC.wSecond;
        //SendDlgItemMessage(hwnddlg, 99, PBM_SETPOS, (Sec mod 10) * 1000 + UTC.wMilliseconds, 0);
        if UTC.wSecond mod 10 = 0 then ShowBeaconsNames(hwnddlg);
      end;
    WM_COMMAND:
      begin
        if wParam > 100 then
        begin
          SetBeaconFreq(hwnddlg, wParam);
          FC := wParam - 101;
          ShowBeaconsNames(hwnddlg);
//          if wParam > 105 then SetDlgItemText(hwnddlg, 98, nil);
        end;
        if wParam = 2 then goto ExitAndClose;

      end;

    WM_CLOSE:
      begin
        ExitAndClose:
        Windows.KillTimer(hwnddlg, BEACONS_ONE_SECOND_TIMER_HANDLE);
        EndDialog(hwnddlg, 0);
      end;

  end;
end;

procedure SetBeaconFreq(h: HWND; Control: integer);
begin
  SetRadioFreq(RadioOne, FreqArray[Control] * 1000, CW, 'A');
end;

procedure ShowBeaconsNames(h: HWND);
var
  r, c                                  : Byte;
begin
  begin
    for r := 0 to 17 do
      for c := 0 to 4 do
        Windows.EnableWindow(BeaconsHandle[r, c], False);

    r := (UTC.wMinute mod 3) * 6;
    r := r + UTC.wSecond div 10;
    for c := 0 to 4 do
    begin
      Windows.EnableWindow(BeaconsHandle[r, c], True);
      if r = 0 then r := 18;
      dec(r);
    end;
  end;
end;

{
Schedule of IBP/NCDXF Beacon Transmissions

Frequency
Country            Call   14100 18110 21150 24930 28200

United Nations NY  4U1UN  00.00 00.10 00.20 00.30 00.40
Northern Canada    VE8AT  00.10 00.20 00.30 00.40 00.50
USA (CA)           W6WX   00:20 00.30 00:40 00.50 01:00
Hawaii             KH6WO  00.30 - 00.50 - 01.10
New Zealand        ZL6B   00.40 00.50 01.00 01.10 01.20
West Australia     VK6RBP 00.50 01.00 01.10 01.20 01.30

Japan              JA2IGY 01.00 01.10 01.20 01.30 01.40
Siberia            RR9O   01.10 01.20 01.30 01.40 01.50
China              VR2HK  01.20 01.30 01.40 01.50 02.00
Sri Lanka          4S7B   01.30 01.40 01.50 02.00 02.10
South Africa       ZS6DN  01:40 01.50 02:00 02:10 02:20
Kenya              5Z4B   01.50 02.00 02.10 02.20 02.30

Israel             4X6TU  02:00 02:10 02:20 02.30 02:40
Finland            OH2B   02:10 02:20 02:30 02:40 02:50
Madeira            CS3B   02.20 02.30 02.40 02.50 00.00
Argentina          LU4AA  02:30 02:40 02:50 00.00 00:10
Peru               OA4B   02.40 02.50 00.00 00.10 00.20
Venezuela          YV5B   02:50 00.00 00:10 00:20 00:30

KH6WO is not currently licensed for 18 or 24 MHz.

}

end.

