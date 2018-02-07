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
unit uBMCF;

{$IMPORTEDDATA OFF}

interface

uses
  VC,
  TF,
  Messages,
  Windows,
  Tree,
  LogWind;

function BMCFDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

implementation

uses
  MainUnit;

function BMCFDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose;
var
  TempHWND                              : HWND;
  TempColumn                            : integer;
  TempFreq                              : integer;
  TempBand                              : BandType;
  Top                                   : integer;
  pTranslated                           : LongBool;
  TempPos                               : integer;
const
  itemHeight                            = 18;
  itemHeight2                           = 30;
begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin
        Windows.SetWindowText(hwnddlg, RC_BANDPLAN);
        CreateOKCancelButtons( hwnddlg);

        tCreateStaticWindow('Band', defStyle, 10, 5, 40, itemHeight2, hwnddlg, 0);
        tCreateStaticWindow('BAND MAP CUTOFF FREQUENCY', defStyle, 55, 5, 110, itemHeight2, hwnddlg, 0);
        tCreateStaticWindow('FREQUENCY MEMORY CW', defStyle, 170, 5, 110, itemHeight2, hwnddlg, 0);
        tCreateStaticWindow('FREQUENCY MEMORY SSB', defStyle, 285, 5, 110, itemHeight2, hwnddlg, 0);

        for TempBand := Band160 to Band2 do
        begin
              //            Left := 10 + c * 67;
          Top := integer(TempBand) * 20 + 40;

          tCreateStaticWindow(BandStringsArrayWithOutSpaces[TempBand], defStyle, 10, Top, 40, itemHeight, hwnddlg, 0);

          for TempColumn := 1 to 3 do
          begin

            if TempColumn = 1 then TempFreq := BandMapModeCutoffFrequency[TempBand];
            if TempColumn = 2 then TempFreq := DefaultFreqMemory[TempBand, CW];
            if TempColumn = 3 then TempFreq := DefaultFreqMemory[TempBand, Phone];

            TempHWND :=
              tCreateEditWindow(
              WS_EX_STATICEDGE,
              inttopchar(TempFreq),
              WS_TABSTOP or WS_CHILD or WS_VISIBLE or ES_CENTER or ES_NUMBER or ES_AUTOHSCROLL,
              55 + (TempColumn - 1) * 115,
              Top,
              110,
              itemHeight,
              hwnddlg,
              integer(TempBand) + TempColumn * 100);
          end;
        end;

//  WritePrivateProfileSection('BAND MAP CUTOFF FREQUENCY', s, TR4W_INI_FILENAME);
      end;

    WM_COMMAND:
      begin

        if wParam = 1 then
        begin

          Windows.ZeroMemory(@wsprintfBuffer, SizeOf(wsprintfBuffer));
          TempPos := 0;

          for TempColumn := 1 to 3 do
          begin
            for TempBand := Band160 to Band2 do
            begin
              TempFreq := Windows.GetDlgItemInt(hwnddlg, integer(TempBand) + TempColumn * 100, pTranslated, False);
              if not pTranslated then Continue;
              if TempColumn = 1 then
              begin
                BandMapModeCutoffFrequency[TempBand] := TempFreq;
                TempPos := TempPos + Format(@wsprintfBuffer[TempPos], 'BAND MAP CUTOFF FREQUENCY=%u', TempFreq) + 1;
              end;
              if TempColumn = 2 then
              begin
                DefaultFreqMemory[TempBand, CW] := TempFreq;
                TempPos := TempPos + Format(@wsprintfBuffer[TempPos], 'FREQUENCY MEMORY=%u', TempFreq) + 1;
              end;
              if TempColumn = 3 then
              begin
                DefaultFreqMemory[TempBand, Phone] := TempFreq;
                TempPos := TempPos + Format(@wsprintfBuffer[TempPos], 'FREQUENCY MEMORY=SSB %u', TempFreq) + 1;
              end;

            end;

          end;

          WritePrivateProfileSection('BAND PLAN', wsprintfBuffer, TR4W_INI_FILENAME);
          goto ExitAndClose;
        end;

        if wParam = 2 then
        begin
          goto ExitAndClose;
        end;

      end;

    WM_CLOSE:
      begin
        ExitAndClose:
        EndDialog(hwnddlg, 0);
      end;

  end;
end;

end.

