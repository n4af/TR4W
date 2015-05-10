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
unit uMultsFrequencies;

{$IMPORTEDDATA OFF}

interface

uses

  TF,
  VC,
  uNet,
  WinSock2,
  LogEdit,
  LogK1EA,
  LogRadio,
  Tree,
  uCommctrl,
  Windows,
  Messages,
  LogWind;

function MultsFrequenciesDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lp: lParam): BOOL; stdcall;
procedure DisplayMultsFrequencies;
procedure AddFrequencyToMFArray;

var

  MultsFrequenciesHandle      : HWND = 0;

implementation

uses MainUnit;

function MultsFrequenciesDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lp: lParam): BOOL; stdcall;
var
  Band                        : BandType;
  Mode                        : ModeType;
  elvi                        : TLVItem;
  elvc                        : tagLVCOLUMNA;
  I                           : integer;
begin
  RESULT := False;
  case Msg of
    WM_NOTIFY:
      begin

        with PNMHdr(lp)^ do
          case code of
            NM_DBLCLK:
              begin
                I := SendMessage(MultsFrequenciesHandle, LVM_GETNEXTITEM, -1, 1);
                if I > 5 then Mode := Phone else Mode := CW;
                if I > 5 then I := I - 6;
                Band := BandType(I);
                if MF[Mode, Band] = 0 then Exit;
                SetRadioFreq(ActiveRadio, MF[Mode, Band], Mode, 'A');
//                tSetWindowText(CallWindowHandle, VisibleLog.LastCallsign);
//                PlaceCaretToTheEnd(CallWindowHandle);
              end;
            NM_RELEASEDCAPTURE: FrmSetFocus;
          end;
      end;

    WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lp, hwnddlg);
    WM_INITDIALOG:
      begin
        MultsFrequenciesHandle := Get101Window(hwnddlg);
        asm
            mov edx,[MainFixedFont]
            call tWM_SETFONT
        end;
        ListView_SetTextBkColor(MultsFrequenciesHandle, $0000FF00);
        ListView_SetBkColor(MultsFrequenciesHandle, $0000FF00);
//        ListView_SetTextColor(MultsFrequenciesHandle, $00FFFFFF);

        ListView_SetExtendedListViewStyle(MultsFrequenciesHandle, LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT);
        elvc.Mask := LVCF_TEXT or LVCF_WIDTH or LVCF_FMT;

        elvc.fmt := LVCFMT_CENTER;
        elvc.pszText := 'Band';
        elvc.cx := 50 + 13;
        ListView_InsertColumn(MultsFrequenciesHandle, 0, elvc);

        elvc.pszText := 'Mode';
        elvc.cx := 70 - 6;
        ListView_InsertColumn(MultsFrequenciesHandle, 1, elvc);

        elvc.pszText := 'Freq';
        elvc.cx := 70 - 6;
        ListView_InsertColumn(MultsFrequenciesHandle, 2, elvc);

        elvi.Mask := LVIF_TEXT;

        for Mode := Phone downto CW do
          for Band := Band10 downto Band160 do
          begin
            if Mode = Digital then Continue;

            elvi.iItem := 0; ;
            elvi.iSubItem := 0;
            elvi.pszText := BandStringsArray[Band];
            ListView_InsertItem(MultsFrequenciesHandle, elvi);

            elvi.iSubItem := 1;
            elvi.pszText := ModeString[Mode];
            ListView_SetItem(MultsFrequenciesHandle, elvi);

            elvi.iSubItem := 2;
            elvi.pszText := '0';
            ListView_SetItem(MultsFrequenciesHandle, elvi);

          end;

        DisplayMultsFrequencies;
      end;

    WM_CLOSE:
      begin
        MultsFrequenciesHandle := 0;
//        CloseTR4WWindow(tw_MULTSFREQUENCIES_INDEX);
      end;
  end;

end;

procedure DisplayMultsFrequencies;
var
  Band                        : BandType;
  Mode                        : ModeType;
  I                           : integer;
begin
{
  if MultsFrequenciesHandle = 0 then Exit;
  for Mode := CW to Phone do
    for Band := Band160 to Band10 do
    begin
      if Mode = Digital then Continue;
      I := Ord(Band) + (Ord(Mode) div 2) * 6;
//      ListView_SetItemText(MultsFrequenciesHandle, Ord(Band), 1, inttopchar(MF[CW, Band] div 1000));
//      ListView_SetItemText(MultsFrequenciesHandle, Ord(Band), 2, inttopchar(MF[phone, Band] div 1000));

      ListView_SetItemText(MultsFrequenciesHandle, I, 1, ModeString[Mode]);
      ListView_SetItemText(MultsFrequenciesHandle, I, 2, inttopchar(MF[Mode, Band] div 1000));
    end;
}
end;

procedure AddFrequencyToMFArray;
var
  TempFreq                    : integer;
  TempMode                    : ModeType;
  TempBand                    : BandType;
  TempNetMultsFrequencies     : NetMultsFrequencies;
begin
{
  if NetSocket = 0 then Exit;
  if MF[CW, Band160] = 0 then Exit;
  TempFreq := ActiveRadioPtr^.FilteredStatus.Freq;
  if TempFreq = 0 then Exit;
  CalculateBandMode(TempFreq, TempBand, TempMode);
  if not (TempBand in [Band160..Band10]) then Exit;
  if MF[TempMode, TempBand] = TempFreq then Exit;
  MF[TempMode, TempBand] := TempFreq;
  TempNetMultsFrequencies.mfID := NET_MULTSFREQUENCIES_ID;
  TempNetMultsFrequencies.mfQSOTotals := MF;
  SendToNet(TempNetMultsFrequencies, SizeOf(NetMultsFrequencies));
}
end;

end.

