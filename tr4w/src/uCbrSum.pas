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
unit uCbrSum;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Tree,
  uCallSignRoutines,
  uErmak,
  LogRadio,
  PostUnit,
  LogWind,
  Windows,
  Messages;

function CreateCabrilloDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

type
  CabrilloTags =
    (
    ctCategoryAssisted,
    ctCategoryBand,
    ctCategoryMode,
    ctCategoryOperator,
    ctCategoryPower,
    ctCategoryStation,
    ctCategoryTime,
    ctCategoryTransmitter,
    ctCategoryOverlay,
    ctCertificate,
    ctOperators,
    ctClub,
    ctLocation,
    ctName,
    ctAddress,
    ctAddressCity,
    ctAddressStateProvince,
    ctAddressPostalcode,
    ctAddressCountry,
    ctEmail,
    ctSoapbox
//    ctRig,
//    ctAntennas
    );

  TCategoriesValuesRecord = record
    cvrStart: PChar;
    cvrCount: integer;
  end;

  TCabrilloTagRecord = record
    ctrTag: PChar;
    ctrCFG: boolean; //do not used
    ctrSave: boolean;
    ctrList: boolean;
  end;

const

    CategoriesArray                       : array[ctCategoryAssisted..ctCategoryOverlay] of TCategoriesValuesRecord =
   //    CategoriesArray                       : array[0..8] of TCategoriesValuesRecord =
    (
{   ctCategoryAssisted    }(cvrStart: @tCategoryAssistedSA; cvrCount: integer(High(tCategoryAssisted))),
{   ctCategoryBand        }(cvrStart: @tCategoryBandSA; cvrCount: integer(High(tCategoryBand))),
{   ctCategoryMode        }(cvrStart: @tCategoryModeSA; cvrCount: integer(High(tCategoryMode))),
//{   ctCertificate         }(cvrStart: @tCertificateSA; cvrCount: integer(High(tCertificate))),
{   ctCategoryOperator    }(cvrStart: @tCategoryOperatorSA; cvrCount: integer(High(tCategoryOperator))),
{   ctCategoryPower       }(cvrStart: @tCategoryPowerSA; cvrCount: integer(High(tCategoryPower))),
{   ctCategoryStation     }(cvrStart: @StationCategory; cvrCount: NumberStationCategories - 1),
{   ctCategoryTime        }(cvrStart: @TimeCategory; cvrCount: NumberTimeCategories - 1),
{   ctCategoryTransmitter }(cvrStart: @TransmitterCategory; cvrCount: NumberTransmitterCategories - 1),
{   ctCategoryOverlay     }(cvrStart: @OverlayCategory; cvrCount: NumberOverlayCategories - 1)
    );

 // 4.72.8 allow most tags to save to tr4w.ini in settings, allowing preload
  CabrilloTagsArray                     : array[CabrilloTags] of TCabrilloTagRecord =
    (
{(*}
    (ctrTag: '_CATEGORY-ASSISTED';      ctrCFG:True;  ctrSave: False; ctrList: True),
    (ctrTag: '_CATEGORY-BAND';          ctrCFG:True;  ctrSave: False; ctrList: True),
    (ctrTag: '_CATEGORY-MODE';          ctrCFG:True;  ctrSave: True; ctrList: True),
    (ctrTag: '_CATEGORY-OPERATOR';      ctrCFG:True;  ctrSave: False; ctrList: True),    // ny4i changed this since we dete3rmine from the log
    (ctrTag: '_CATEGORY-POWER';         ctrCFG:True;  ctrSave: True; ctrList: True),
    (ctrTag: '_CATEGORY-STATION';       ctrCFG:False; ctrSave: True; ctrList: False),
    (ctrTag: '_CATEGORY-TIME';          ctrCFG:True;  ctrSave: False; ctrList: True),
    (ctrTag: '_CATEGORY-TRANSMITTER';   ctrCFG:False; ctrSave: True; ctrList: False),
    (ctrTag: '_CATEGORY-OVERLAY';       ctrCFG:True;  ctrSave: False; ctrList: True),
    (ctrTag: '_CERTIFICATE';            ctrCFG:True;  ctrSave: True; ctrList: False),
    (ctrTag: '_OPERATORS';              ctrCFG:True;  ctrSave: True; ctrList: False),
    (ctrTag: '_CLUB';                   ctrCFG:False; ctrSave: True;  ctrList: False),
    (ctrTag: '_LOCATION';               ctrCFG:True;  ctrSave: True; ctrList: False),
    (ctrTag: '_NAME';                   ctrCFG:False; ctrSave: True;  ctrList: False),
    (ctrTag: '_ADDRESS';                ctrCFG:False; ctrSave: True;  ctrList: False),
    (ctrTag: '_ADDRESS-CITY';           ctrCFG:False; ctrSave: True;  ctrList: False),
    (ctrTag: '_ADDRESS-STATE-PROVINCE'; ctrCFG:False; ctrSave: True;  ctrList: False),
    (ctrTag: '_ADDRESS-POSTALCODE';     ctrCFG:False; ctrSave: True;  ctrList: False),
    (ctrTag: '_ADDRESS-COUNTRY';        ctrCFG:False; ctrSave: True;  ctrList: False),
    (ctrTag: '_EMAIL';                  ctrCFG:False; ctrSave: True;  ctrList: False),
    (ctrTag: '_SOAPBOX';                ctrCFG:True;  ctrSave: False; ctrList: False)
//    (ctrTag: '_RIG';                    ctrCFG:False; ctrSave: True;  ctrList: False),
//    (ctrTag: '_ANTENNAS';               ctrCFG:False; ctrSave: True;  ctrList: False)
{*)}
    );

var

  CabrilloSummaryProc                   : Pointer;
  FormatSpecification                   : PChar;
const
  siCreate                              = 1;
  siCancel                              = 2;
  CabrSumLabels111                      : array[147..168] of PChar = (
    'CATEGORY-ASSISTED',
    'CATEGORY-BAND',
    'CATEGORY-MODE',
    'CATEGORY-OPERATOR',
    'CATEGORY-POWER',
    'CATEGORY-STATION',
    'CATEGORY-TIME',
    'CATEGORY-TRANSMITTER',
    'CATEGORY-OVERLAY',
    'CERTIFICATE',
    'OPERATORS',
    'CLUB',
    'LOCATION',
    'NAME',
    'ADDRESS-CITY',
    'ADDRESS-STATE-PROVINCE',
    'ADDRESS-POSTALCODE',
    'ADDRESS-COUNTRY',
    'EMAIL',
    'SOAPBOX',
    'RIG',
    'ANTENNAS'
    );

  VALUE_OPERATORS                       = 156;
  VALUE_RIG                             = 166 - 30;

implementation
uses MainUnit;

function CreateCabrilloDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose;
var
  TempByte                              : Byte;
  i                                     : Cardinal;
  TempCardinal                          : Cardinal;
  TempPointer                           : Pointer;
  Top                                   : integer;
//  ComboBoxStyle                         : integer;
  
  TempTag                               : CabrilloTags;
  TempHWND                              : HWND;
const
  Left                                  = 10;
  TagHeight                             = 20;
  InitialTagsValuesArray                : array[ctCategoryAssisted..ctCategoryPower] of PByte = (@CategoryAssisted,@CategoryBand,@CategoryMode, @CategoryOperator, @CategoryPower);
begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin
        CreateCabrilloWindow := hwnddlg;
        FormatSpecification := CABRILLOSECTION;

        Windows.SetWindowText(hwnddlg, RC_STATIONINFO);
        CreateOKCancelButtons(hwnddlg);

        if ErmakSpecification then
        begin
//          tCreateStaticWindow(KIR_, defStyle, 10, 5, 355, 20, hwnddlg, 0);
          FormatSpecification := ERMAKSECTION;
        end;

        for TempTag := Low(CabrilloTags) to High(CabrilloTags) do
        begin
          Top := 30 + integer(TempTag) * (TagHeight + 2);
          tCreateStaticWindow(@CabrilloTagSArray[TempTag].ctrTag[1], LeftStyle, 10, Top, 160, TagHeight, hwnddlg, integer(TempTag) + 100);
          if ErmakSpecification and (TempTag = ctOperators) then
          begin
            tCreateButtonWindow(WS_EX_STATICEDGE, 'Выбрать ...', WS_TABSTOP or WS_CHILD or WS_VISIBLE, 173, Top, 190, TagHeight, hwnddlg, 3);
            Continue;
          end;

          if CabrilloTagSArray[TempTag].ctrList then
          begin
            TempHWND := tCreateComboBoxWindow(CBS_DROPDOWNLIST or WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_TABSTOP, 173, Top, 190, hwnddlg, integer(TempTag) + 200);

            for TempByte := 0 to CategoriesArray[TempTag].cvrCount do
            begin
              TempPointer := CategoriesArray[TempTag].cvrStart + TempByte * 4;
              SendMessage(TempHWND, CB_ADDSTRING, 0, integer(TempPointer^));
            end;

            if TempTag in [ctCategoryAssisted..ctCategoryPower] then
              SendMessage(TempHWND, CB_SETCURSEL, integer(InitialTagsValuesArray[TempTag]^), 0);
          end
          else
          begin
            TempHWND := tCreateEditWindow(WS_EX_STATICEDGE, nil, WS_TABSTOP or WS_CHILD or SS_LEFT or WS_VISIBLE or ES_AUTOHSCROLL, 173, Top, 190, 20, hwnddlg, integer(TempTag) + 200);
            ;

            if CabrilloTagSArray[TempTag].ctrSave then
            begin
              TempCardinal := GetPrivateProfileString(FormatSpecification,
                CabrilloTagSArray[TempTag].ctrTag,
                nil,
                TempBuffer1,
                SizeOf(TempBuffer1),
                TR4W_INI_FILENAME);

              if TempCardinal <> 0 then
                Windows.SetWindowText(TempHWND, TempBuffer1);
            end;
          end;
        end;

        if ErmakSpecification then
        begin
          tCB_ADDSTRING_PCHAR(hwnddlg, integer(ctCategoryMode) + 200, 'DIGI');
          tCB_ADDSTRING_PCHAR(hwnddlg, integer(ctCategoryOperator) + 200, 'MULTI-OP-2');
          tCB_ADDSTRING_PCHAR(hwnddlg, integer(ctCategoryBand) + 200, '10M-15M-20M');
          tCB_ADDSTRING_PCHAR(hwnddlg, integer(ctCategoryBand) + 200, '80M-40M-160M');

          SendDlgItemMessage(hwnddlg, integer(ctCategoryOverlay) + 200, CB_RESETCONTENT, 0, 0);
          for i := 0 to NumberErmakOverlayCategories - 1 do
            tCB_ADDSTRING_PCHAR(hwnddlg, integer(ctCategoryOverlay) + 200, ErmakOverlayCategory[i]);
        end;

        CabrilloSummaryProc := Pointer(lParam);

      end;

    WM_CLOSE:
      begin
        ExitAndClose:
        for TempTag := Low(CabrilloTags) to High(CabrilloTags) do
          if CabrilloTagSArray[TempTag].ctrSave then
          begin
            if Windows.GetDlgItemText(hwnddlg, integer(TempTag) + 200, TempBuffer1, SizeOf(TempBuffer1)) > 0 then
              WritePrivateProfileString(FormatSpecification, CabrilloTagSArray[TempTag].ctrTag, TempBuffer1, TR4W_INI_FILENAME);

          end;

        CreateCabrilloWindow := 0;
        EndDialog(hwnddlg, 0);
      end;

    //    WM_HELP: tWinHelp(43);
    WM_COMMAND:
      begin
        case wParam of
            1: asm call CabrilloSummaryProc; end;
          2: goto ExitAndClose;
          3:
          //DialogBox(hInstance, MAKEINTRESOURCE(50), hwnddlg, @ErmakDlgProc);
            CreateModalDialog(320, 155, hwnddlg, @ErmakDlgProc, 0);
        end;
      end;
  end;
end;

end.

