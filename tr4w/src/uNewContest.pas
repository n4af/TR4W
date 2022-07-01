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
unit uNewContest;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  Version,
  VC,
  Windows,
  Tree,
  LogDupe,
  LogGrid,
  PostUnit,
  uGradient,
  uCallSignRoutines,
  utils_file,
  Messages
  ;
type
  InitialCommands =
    (icmyCheck, icmyFDClass, icmyGrid, icmyFOC, icmyIOTA, icmyName, icmyPrec, icmyQTH, icmySection, icmyState, icmyZone, icmyPostalCode);

function  NewContestDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure BeginNewContest(h: HWND);
procedure ClearFields;
procedure SaveNewContest(h: HWND);
procedure DisplayCheckBox(Text: PChar);
procedure SetCommentAndEnableEditControl(comment: PChar; EditControl: InitialCommands);
procedure EnterCountyOrState(State: PChar);
procedure StartContestFromListbox();
function NewSelectContestListBoxProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): integer; stdcall;
procedure ChangeDir;
procedure DisplayInitialCommand(Command: InitialCommands);
//procedure FillMyStateComboBox;

implementation
uses MainUnit;

const

  CSAS                                  = 10;
  InitialCommandsSA2                    : array[1..CSAS] of PChar = (
    nil,
    nil,
    nil,
    'CATEGORY-ASSISTED',
    'CATEGORY-BAND',
    'CATEGORY-MODE',
    'CATEGORY-OPERATOR',
    'CATEGORY-POWER',
    'CATEGORY-TRANSMITTER',
    'CATEGORY-OVERLAY'
    );

  InitialCommandsSA                     : array[InitialCommands] of PChar =
    (
    'MY CHECK',
    'MY FD CLASS',
    'MY GRID',
    'My FOC NUMBER',
    'MY IOTA',
    'MY NAME',
    'MY PREC',
    'MY QTH',
    'MY SECTION',
    'MY STATE',
    'MY ZONE',
    'MY POSTAL CODE'
    );

var
  InitialCommandsHWNDArray              : array[1..CSAS, 1..2] of HWND;
  NewContestDisplayedCommands           : integer;
  NewContestCheckBox                    : HWND;
  NewContestDlgWndHandle                : HWND;
  NewContestListBoxHandle               : HWND;
  NewContestCommentWndHandle            : HWND;
//  NewContestAllowReturn                 : boolean;
  SelectedContest                       : ContestType;
  OldSelectContestListBoxProc           : Pointer;

const

{(*}
  NC_CALL_EDIT                               = 221;
  NC_CONTEST_COMBOBOX                        = 233;
  NC_BUTTON_OK                               = 101;
  NC_BUTTON_CANCEL                           = 102;
  NC_BUTTON_LATEST_CONFIG                    = 73;
  NC_CHECKBOX_IAMIN                          = 107;
  NC_LISTBOX                                 = 444;
  {*)}

  sfFLAG                                = DDL_ARCHIVE or DDL_READWRITE or DDL_DIRECTORY;

function NewContestDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1, ExitAndClose;
var
  TempCardinal                          : Cardinal;
  ct                                    : ContestType;
  Top                                   : integer;

  TempCategoryAssisted                  : tCategoryAssisted;
  TempCategoryBand                      : tCategoryBand;
  TempCategoryMode                      : tCategoryMode;
  TempCategoryOperator                  : tCategoryOperator;
  TempCategoryPower                     : tCategoryPower;
  TempCategoryTransmitter               : tCategoryTransmitter;
  TempCategoryOverlay                   : tCategoryOverlay;

//  TempActiveExchange                    : ExchangeType;
//  TempExchangeInformation               : ExchangeInformationRecord;
const
  h                                     = 18;
  BS_COMMANDLINK                        = $0000000E;

begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin
        NewContestDlgWndHandle := hwnddlg;

        CreateStatic(RC_CAPTION, 5, 5, 280, hwnddlg, 445);
         {LISTBOX}
        CreateListBox(5, 35, 280, 370, hwnddlg, NC_LISTBOX);

        GetPrivateProfileString(_COMMANDS, LATEST_CONFIG_FILE, nil, TR4W_LATESTCFG_FILENAME, SizeOf(FileNameType), TR4W_INI_FILENAME);
        if TR4W_LATESTCFG_FILENAME[0] <> #0 then
        begin

          if FileExists(TR4W_LATESTCFG_FILENAME) then

          begin

        {BUTTON LATEST CONFIG}
            TempCardinal := tWM_SETFONT(
              CreateWindowEx(0, ButtonPChar, nil, BS_MULTILINE or WS_CHILD or BS_TEXT or WS_VISIBLE {or WS_TABSTOP}, 5, 415, 280, 50 {nHeight}, hwnddlg, NC_BUTTON_LATEST_CONFIG, hInstance, nil),
              MSSansSerifFont);

            Windows.CopyMemory(@TempBuffer1, @TR4W_LATESTCFG_FILENAME, SizeOf(FileNameType));
            Windows.CharLower(TempBuffer1);
            Format(wsprintfBuffer, TC_LATEST_CONFIG_FILE + ' (Alt+&A):'#13#10'%s', TempBuffer1);
            //i := GetDlgItem(hwnddlg, NC_BUTTON_LATEST_CONFIG);

            Windows.SetWindowText(TempCardinal, wsprintfBuffer);
            EnableWindow(TempCardinal, True);
            Windows.ShowWindow(TempCardinal, SW_SHOW);
          end;
        end;

        tCreateStaticWindow('MY CALL', WS_CHILD or SS_NOTIFY or SS_RIGHT or SS_NOPREFIX or WS_VISIBLE, 300, 5, 125 + 20, h, hwnddlg, 0);

        tCreateStaticWindow('CONTEST', WS_CHILD or SS_NOTIFY or SS_RIGHT or SS_NOPREFIX or WS_VISIBLE, 300, 33, 125 + 20, h, hwnddlg, 0);
        tWM_SETFONT(CreateWindow(StaticPChar, nil, SS_SUNKEN or SS_center or WS_CHILD or WS_VISIBLE, 305, 95, 300, 40, hwnddlg, 106, hInstance, nil), MSSansSerifFont);

        {MY CALL}
        CreateEdit(ES_UPPERCASE, 455, 5, 150, 23, hwnddlg, NC_CALL_EDIT);
        {CONTEST}
        tCreateComboBoxWindow(WS_VSCROLL + CBS_SORT + CBS_UPPERCASE + CBS_DROPDOWNLIST or CBS_AUTOHSCROLL or WS_CHILD or WS_VISIBLE or WS_TABSTOP, 455, 30, 150, hwnddlg, NC_CONTEST_COMBOBOX);
        {I AM IN}
         Windows.ShowWindow(CreateButton(BS_AUTOCHECKBOX or BS_LEFT or BS_TOP or BS_MULTILINE or WS_CHILD or WS_TABSTOP, nil, 420, 60, 430, hwnddlg, NC_CHECKBOX_IAMIN), SW_HIDE); // 4.76.3

        Windows.SetWindowText(hwnddlg, TR4W_CURRENTVERSION + TC_OPENCONFIGURATIONFILE);

        NewContestListBoxHandle := GetDlgItem(hwnddlg, NC_LISTBOX);

        Format(wsprintfBuffer, '%s*.CFG', TR4W_PATH_NAME);

        DlgDirList(hwnddlg, wsprintfBuffer, NC_LISTBOX, 445, sfFLAG + DDL_DRIVES);
        SelectParentDir(NewContestListBoxHandle);
        OldSelectContestListBoxProc := Pointer(Windows.SetWindowLong(NewContestListBoxHandle, GWL_WNDPROC, integer(@NewSelectContestListBoxProc)));
        tWM_SETFONT(NewContestListBoxHandle, MainFixedFont);

        for ct := Succ(DUMMYCONTEST) to High(ContestType) do tCB_ADDSTRING_PCHAR(hwnddlg, NC_CONTEST_COMBOBOX, ContestTypeSA[ct]);

        NewContestCheckBox := GetDlgItem(hwnddlg, NC_CHECKBOX_IAMIN);


        NewContestCommentWndHandle := GetDlgItem(hwnddlg, 106);
        tLoadKeyboardLayout;

        for TempCardinal := 1 to CSAS do
        begin
          Top := 120 + TempCardinal * (h + 6);
          InitialCommandsHWNDArray[TempCardinal, 1] := tCreateStaticWindow(InitialCommandsSA2[TempCardinal], WS_CHILD or SS_NOTIFY or SS_RIGHT or SS_NOPREFIX or WS_VISIBLE, 300, Top, 128 + 20, h, hwnddlg, 0);
          if TempCardinal < 4 then
            InitialCommandsHWNDArray[TempCardinal, 2] := tCreateEditWindow(WS_EX_STATICEDGE, nil, WS_TABSTOP or WS_CHILD or ES_UPPERCASE, 435 + 20, Top, 173 - 20, h, hwnddlg, 0)
          else
            InitialCommandsHWNDArray[TempCardinal, 2] := tCreateComboBoxWindow({CBS_SORT + }CBS_UPPERCASE + CBS_DROPDOWNLIST or WS_CHILD or {WS_VSCROLL or } WS_VISIBLE or WS_TABSTOP, 435 + 20, Top, 173 - 20, hwnddlg, 0);
        end;

        for TempCategoryAssisted := Low(tCategoryAssisted) to High(tCategoryAssisted) do
          SendMessage(InitialCommandsHWNDArray[4, 2], CB_ADDSTRING, 0, integer(tCategoryAssistedSA[TempCategoryAssisted]));

        for TempCategoryBand := Low(tCategoryBand) to High(tCategoryBand) do
          SendMessage(InitialCommandsHWNDArray[5, 2], CB_ADDSTRING, 0, integer(tCategoryBandSA[TempCategoryBand]));

        for TempCategoryMode := Low(tCategoryMode) to High(tCategoryMode) do
          SendMessage(InitialCommandsHWNDArray[6, 2], CB_ADDSTRING, 0, integer(tCategoryModeSA[TempCategoryMode]));

        for TempCategoryOperator := Low(tCategoryOperator) to High(tCategoryOperator) do
          SendMessage(InitialCommandsHWNDArray[7, 2], CB_ADDSTRING, 0, integer(tCategoryOperatorSA[TempCategoryOperator]));

        for TempCategoryPower := Low(tCategoryPower) to High(tCategoryPower) do
          SendMessage(InitialCommandsHWNDArray[8, 2], CB_ADDSTRING, 0, integer(tCategoryPowerSA[TempCategoryPower]));

        for TempCategoryTransmitter := Low(tCategoryTransmitter) to High(tCategoryTransmitter) do
          SendMessage(InitialCommandsHWNDArray[9, 2], CB_ADDSTRING, 0, integer(tCategoryTransmitterSA[TempCategoryTransmitter]));

        for TempCategoryOverlay := Low(tCategoryOverlay) to High(tCategoryOverlay) do
          SendMessage(InitialCommandsHWNDArray[10, 2], CB_ADDSTRING, 0, integer(tCategoryOverlaySA[TempCategoryOverlay]));

        for TempCardinal := 4 to CSAS do
          SendMessage(InitialCommandsHWNDArray[TempCardinal, 2], CB_SETCURSEL, 0, 0);

        MainCallsign[0] := CHR(GetPrivateProfileString(_COMMANDS, MAIN_CALLSIGN, nil, @MainCallsign[1], SizeOf(MainCallsign), TR4W_INI_FILENAME));
        if MainCallsign <> '' then
          Windows.SetDlgItemText(hwnddlg, NC_CALL_EDIT, @MainCallsign[1]);

        {OK}
        CreateButton(BS_DEFPUSHBUTTON, OK_WORD, 350, 430, 80, hwnddlg, NC_BUTTON_OK);
        SendMessage(hwnddlg, DM_SETDEFID, NC_BUTTON_OK, 0);
        {CANCEL}
        CreateButton(0, CANCEL_WORD, 350 + 90, 430, 80, hwnddlg, NC_BUTTON_CANCEL);

      end;

    WM_CLOSE:
      begin
        ExitAndClose:
        TR4W_CFG_FILENAME[0] := '_';
        EndDialog(hwnddlg, 0);
      end;

    WM_COMMAND:
      begin
        if HiWord(wParam) = LBN_DBLCLK then ChangeDir;

        if HiWord(wParam) = BN_CLICKED then
        begin
          if LoWord(wParam) = NC_BUTTON_LATEST_CONFIG then
          begin
            Windows.CopyMemory(@TR4W_CFG_FILENAME, @TR4W_LATESTCFG_FILENAME, SizeOf(FileNameType));
            DestroyWindow(NewContestDlgWndHandle);
          end;

          if LoWord(wParam) = NC_CHECKBOX_IAMIN then
          begin
            ClearFields;

            Windows.SetWindowText(NewContestCommentWndHandle, nil);
             if Windows.SendMessage(NewContestCheckBox, BM_GETCHECK, 0, 0) = BST_UNCHECKED then


            begin
{
              if SelectedContest = NYQP then
              begin
                SetCommentAndEnableEditControl(TC_ENTERSTATEFORUSPROVINCEFORCANADA, nc_MyState);
                EnableWindow(GetDlgItem(hwnddlg, 101), False);
              end;
}
              Exit;
            end;
            case SelectedContest of
            MWC:
            ;
            VAQP:
            ;

              ALRS_UA1DZ_CUP:
                SetCommentAndEnableEditControl(TC_ENTERYOURRDAIDORGRID, icmyState);

              NEWENGLANDQSO:
                SetCommentAndEnableEditControl(TC_NEWENGLANDSTATEABREVIATION, icmyState);

              ARRL10, ARRL160, ARRLDXCW, ARRL_RTTY_ROUNDUP:
                begin
                   Windows.SendMessage(107, BM_SETCHECK, BST_CHECKED, 0);
                  SetCommentAndEnableEditControl(TC_ENTERTHEQTHTHATYOUWANTTOSEND, icmyState);
                end;

              CQWWRTTY, CQ160CW, CQ160SSB:
                SetCommentAndEnableEditControl(TC_ENTERSTATEFORUSPROVINCEFORCANADA, icmyState);

                  IRTS:
                   SetCommentAndEnableEditControl(TC_EnterYourCountyCode,icmyState);

              RAC_CANADA_DAY, RAC_CANADA_WINTER:
                SetCommentAndEnableEditControl(TC_ENTERYOURPROVINCEID, icmyState);

              REFSSB, REFCW:
                SetCommentAndEnableEditControl(TC_DEPARTMENT, icmyState);

              UKRAINIAN, RUSSIANDX, UNDX, CIS, RU3AXMEMORIAL:
                SetCommentAndEnableEditControl(TC_ENTERYOUROBLASTID, icmyState);

              KINGOFSPAINCW, KINGOFSPAINSSB, UBACW, UBASSB, PACC, ARI_DX, HELVETIA:
                SetCommentAndEnableEditControl(TC_ENTERYOURPROVINCEID, icmyState);

              CQIR, HADX, YUDX: SetCommentAndEnableEditControl(TC_ENTERYOURCOUNTYCODE, icmyState);

              UKEI: SetCommentAndEnableEditControl(TC_EnterYourDistrictCode, icmyState);

              DARC10M, WAG, DARCXMAS: SetCommentAndEnableEditControl(TC_ENTERYOURDOK, icmyState);

              SPDX, OKDX, OKOMSSB, YODX, RSGB18, LZDX, EUDX:                // 4.80.1
                SetCommentAndEnableEditControl(TC_ENTERYOURDISTRICTABBREVIATION, icmyState);

              RDA: SetCommentAndEnableEditControl(TC_ENTERYOURRDAID, icmyState);

              BSCI, IARU:
                SetCommentAndEnableEditControl(nil, icmyState);

              IOTA:
                SetCommentAndEnableEditControl(TC_ENTERYOURIOTAREFERENCEDESIGNATOR, icmyState);

              WWPMC:
                SetCommentAndEnableEditControl(TC_ENTERYOURCITYIDENTIFIER, icmyState);

              PCC, ARKTIKA_SPRING:
                SetCommentAndEnableEditControl(TC_ENTERYOURMEMBERSHIPNUMBER, icmyState);

              JIDXCW, JIDXSSB:
                SetCommentAndEnableEditControl(TC_PREFECTURE, icmyState);

            end;
          end;

        end;

        if HiWord(wParam) = CBN_SELCHANGE then
          if LoWord(wParam) = NC_CONTEST_COMBOBOX then
          begin
            SelectedContest := GetContestFromString(GetDialogItemText(hwnddlg, NC_CONTEST_COMBOBOX));
            ClearFields;
            Windows.SetWindowText(NewContestCommentWndHandle, nil);
            Windows.ShowWindow(NewContestCheckBox, SW_HIDE);
            Windows.SendMessage(NewContestCheckBox, BM_SETCHECK, BST_UNCHECKED, 0);

            if (ContestsArray[SelectedContest].p <> 0) and (SelectedContest <> BCQP)  then
              EnterCountyOrState(QSOParties[ContestsArray[SelectedContest].p].StateName);

            case SelectedContest of
            
               BCQP:            // 4.97.7
                 SetCommentAndEnableEditControl(TC_ENTERYOURISTRICTIFINVE7,icmyState);


              COLORADOQSOPARTY, MINNQSOPARTY :
                begin
                   DisplayInitialCommand(icmyName);
                end;

              ALRS_UA1DZ_CUP:
                SetCommentAndEnableEditControl(TC_ENTERYOURRDAIDORGRID, icmyState);

              EUSPRINT_SPRING_SSB, EUSPRINT_AUTUMN_CW, EUSPRINT_AUTUMN_SSB, EUSPRINT_SPRING_CW: SetCommentAndEnableEditControl(TC_ENTERYOURNAME, icMyName);

              NZFIELDDAY: SetCommentAndEnableEditControl(TC_ENTERYOURBRANCHNUMBER, icmyZone);

              EUROPEANHFC: SetCommentAndEnableEditControl(TC_ENTERTHELASTTWODIGITSOFTHEYEAR, icmyZone);

              KVP: SetCommentAndEnableEditControl(TC_ENTERTHELASTTWODIGITSOFTHEYEAR, icmyZone);      // 4.65.3

              RFCHAMPIONSHIPCW, RFCHAMPIONSHIPSSB: SetCommentAndEnableEditControl(TC_ENTERYOURZONE, icmyState);
              RAEM: SetCommentAndEnableEditControl(TC_ENTERYOURGEOGRAPHICALCOORDINATES, icmyQTH);

              OLDNEWYEAR: SetCommentAndEnableEditControl(TC_ENTERSUMOFYOURAGEANDAMOUNT, icmyQTH);
              RSGB_ROPOCO_CW, RSGB_ROPOCO_SSB: SetCommentAndEnableEditControl(TC_ENTERYOURPOSTCODE, icmyPostalCode);

             
              RADIOMEMORY: SetCommentAndEnableEditControl(TC_AGECALLSIGNAGE, icmyQTH);
              CQMM: SetCommentAndEnableEditControl(TC_ENTERYOURCONTINENT, icmyState);

              NRAUBALTICCW, NRAUBALTICSSB: SetCommentAndEnableEditControl(TC_ENTERYOURPROVINCEID, icmyState);
              OZCR_O: SetCommentAndEnableEditControl(TC_OZCR, icmyState);

              //RUSSIAN160: SetCommentAndEnableEditControl(TC_ENTERYOURSQUAREID, icmyState);
              R9W_UW9WK_MEMORIAL: SetCommentAndEnableEditControl(TC_STATIONCLASS, icmyState);

              CUPRFCW, CUPRFSSB, CUPRFDIG: SetCommentAndEnableEditControl(TC_ENTERYOURFOURDIGITGRIDSQUARE, icmyGrid);
              RFASCHAMPIONSHIPCW: SetCommentAndEnableEditControl(TC_RFAS, icMyQTH);
               CQVHF,ARRLVHFJAN,ARRLVHFJUN, ARRLVHFSEP,ARRLDIGI, STEWPERRY, BATAVIA_FT8, WWDIGI, MAKROTHEN: SetCommentAndEnableEditControl(TC_ENTERYOURFOURDIGITGRIDSQUARE, icmyGrid);

              OZHCRVHF, EUROPEANVHF, RADIOVHFFD: SetCommentAndEnableEditControl(TC_ENTERYOURSIXDIGITGRIDSQUARE, icmyGrid);

              TESLA:
               SetCommentandEnableEditControl(TC_ENTERYOURFOURDIGITGRIDSQUARE,icmyGrid);
         

              NEWENGLANDQSO: DisplayCheckBox(TC_NEWENGLAND);

              CQWWRTTY, CQ160CW, CQ160SSB, ARRL10, ARRL160, ARRL_RTTY_ROUNDUP: DisplayCheckBox(TC_NORTHAMERICA);

              RDA, RUSSIANDX, RU3AXMEMORIAL: DisplayCheckBox(TC_RUSSIA);
              CQIR: DisplayCheckBox(TC_IRELAND);
              RAC_CANADA_DAY, RAC_CANADA_WINTER: DisplayCheckBox(TC_CANADA);
              REFSSB, REFCW: DisplayCheckBox(TC_FRANCE);
              IRTS: DisplayCheckBox(TC_IRTS);   // 4.93.2
             EUDX:
               DisplayCheckBox(TC_EUDX);  // 4.95.6     
              KINGOFSPAINCW, KINGOFSPAINSSB: DisplayCheckBox(TC_SPAIN);
              JIDXCW, JIDXSSB: DisplayCheckBox(TC_JAPAN);
              HELVETIA: DisplayCheckBox(TC_SWITZERLAND);
              ARI_DX: DisplayCheckBox(TC_ITALY);
              UNDX: DisplayCheckBox(TC_KAZAKHSTAN);
              UKRAINIAN: DisplayCheckBox(TC_UKRAINE);
              OKDX, OKOMSSB: DisplayCheckBox(TC_CZECHREPUBLICORINSLOVAKIA);
              LZDX: DisplayCheckBox(TC_BULGARIA);
              YODX: DisplayCheckBox(TC_ROMANIA);
              HADX: DisplayCheckBox(TC_HUNGARY);
              YUDX: DisplayCheckBox(TC_YUGOSLAVIA);
              UKEI: DisplayCheckBox(TC_UKEI);
            //  UKEI: SetCommentAndEnableEditControl(TC_EnterYourDistrictCode, icmyState);
              UBACW, UBASSB: DisplayCheckBox(TC_BELGIUM);
              PACC: DisplayCheckBox(TC_NETHERLANDS);
              DARC10M, WAG, DARCXMAS: DisplayCheckBox(TC_GERMANY);
              RSGB18: DisplayCheckBox(TC_UK);
              CIS: DisplayCheckBox(TC_CIS);
              SPDX: DisplayCheckBox(TC_POLAND);
              BSCI, IARU: DisplayCheckBox(TC_HQ_OR_MEMBER);
              IOTA:
                begin
                  Windows.SetWindowText(NewContestCheckBox, TC_ISLANDSTATION);
                  Windows.ShowWindow(NewContestCheckBox, SW_SHOW);
                end;

              WWPMC: DisplayCheckBox('PMC');
              PCC,ARKTIKA_SPRING: DisplayCheckBox(TC_ARKTIKACLUB);

              NAQSOCW, NAQSOSSB, NAQSORTTY:
                begin
                  SetCommentAndEnableEditControl(TC_ENTERYOURNAMEANDSTATE, icmyState);
                  DisplayInitialCommand(icmyName);
                end;

              CWOPEN, MST:
                begin
                  SetCommentAndEnableEditControl(TC_ENTERYOURNAME, icmyName);
                end;

              CWOPS, LQP, NCCCSPRINT:
                begin
                  DisplayInitialCommand(icmyName);
                  SetCommentAndEnableEditControl(TC_ENTERYOURNAMEANDQTH, icmyState);
                end;

             FOCMarathon:
             begin
          //    DisplayInitialCommand(icmyFOC);
             SetCommentAndEnableEditControl(TC_ENTERYOURFOCNUMBER,icmyFOC);
             end;

             WINTERFIELDDAY:
                begin
                  DisplayInitialCommand(icmyFDClass);
                  DisplayInitialCommand(icmySection);
                end;

              ARRLFIELDDAY:
                begin
                  DisplayInitialCommand(icmyFDClass);
                  DisplayInitialCommand(icmySection);
                end;

              ARRLSSCW, ARRLSSSSB:
                begin
                  SetCommentAndEnableEditControl(TC_ENTERYOURPRECEDENCECHECKSECTION, icMyPrec);
                  DisplayInitialCommand(icmyCheck);
                  DisplayInitialCommand(icmySection);
                end;

              NASPRINTCW, SPRINTSSB, NASPRINTRTTY:
                begin
                  SetCommentAndEnableEditControl(TC_ENTERYOURQTHANDTHENAME, icmyState);
                  DisplayInitialCommand(icmyName);
                end;



              UA4WCHAMPIONSHIP:
                SetCommentAndEnableEditControl('Enter your RDA (for Russian stations) or four digit grid square:', icMyQTH);

              ALLASIANCW, ALLASIANSSB, YOUTHCHAMPIONSHIPRF, YOTA:
                SetCommentAndEnableEditControl(TC_ENTERYOURAGEINMYSTATEFIELD, icmyState);

               UKRAINECHAMPIONSHIP:
                SetCommentAndEnableEditControl(TC_ENTERYOUROBLASTID, icmyState);

              ARRLDXCW,
                ARRLDXSSB:
                SetCommentAndEnableEditControl(TC_ENTERYOURQTHORPOWER, icmyState);

              CUPURAL:
                SetCommentAndEnableEditControl(TC_ENTERFIRSTTWOLETTERSOFYOURGRID, icmyState);


       //        IN7QPNE:
       //'/}         SetCommentAndEnableEditControl(TC_IN7QPNE, icmyState);

            end;

          end;
        BeginNewContest(hwnddlg);

        case wParam of
{$IF LANG = 'RUS'}
//          104: ShowHelp('ru_selectingacontest');
{$IFEND}
          NC_BUTTON_CANCEL, 2: goto ExitAndClose;
          NC_BUTTON_OK: SaveNewContest(hwnddlg);
        end;
      end;
  end;
end;

procedure ClearFields;
var
  i                                     : integer;
begin
  NewContestDisplayedCommands := 0;
  for i := 1 to 3 do
  begin
    ShowWindow(InitialCommandsHWNDArray[i, 1], SW_HIDE);
    ShowWindow(InitialCommandsHWNDArray[i, 2], SW_HIDE);
    Windows.SetWindowText(InitialCommandsHWNDArray[i, 2], nil);
  end;
end;

procedure BeginNewContest(h: HWND);
var
  res                                   : LongBool;
  i                                     : Cardinal;
  Call                                  : CallString;
begin
  res := True;
  if tCB_GETCURSEL(h, NC_CONTEST_COMBOBOX) = -1 then res := False;
  i := GetDlgItemText(h, NC_CALL_EDIT, @Call[1], SizeOf(CallString));
  if i < 3 then res := False;
  Call[0] := CHR(i);
  if not GoodCallSyntax(Call) then res := False;

  for i := 1 to NewContestDisplayedCommands do
    if Windows.GetWindowTextLength(InitialCommandsHWNDArray[i, 2]) = 0 then
      res := False;
  EnableWindow(GetDlgItem(h, NC_BUTTON_OK), res);

end;

procedure SaveNewContest(h: HWND);
var
  f                                     : HWND;
  i                                     : Cardinal;
  BytesToWrite                          : Cardinal;
begin
  begin
      {callsign}
    i := Windows.GetDlgItemText(h, NC_CALL_EDIT, TempBuffer1, SizeOf(TempBuffer1));
    if MainCallsign = '' then
    begin
      MainCallsign[0] := CHR(i);
      Windows.CopyMemory(@MainCallsign[1], @TempBuffer1, i);
      Windows.WritePrivateProfileString(_COMMANDS, MAIN_CALLSIGN, TempBuffer1, TR4W_INI_FILENAME);
    end;
    DeleteSlashes(TempBuffer1);

      {Contest Name}
    Windows.GetDlgItemText(h, NC_CONTEST_COMBOBOX, TempBuffer2, SizeOf(TempBuffer2));
    Format(wsprintfBuffer, '%s%s %s %s\', TR4W_PATH_NAME, GetYearString, TempBuffer2, TempBuffer1);

    Windows.CreateDirectory(wsprintfBuffer, nil);
  end;

  {CFGFileName}
  Windows.GetDlgItemText(h, NC_CONTEST_COMBOBOX, TempBuffer1, SizeOf(TempBuffer1));
  Format(TR4W_CFG_FILENAME, '%s%s.CFG', wsprintfBuffer, TempBuffer1);

  if FileExists(TR4W_CFG_FILENAME) then
  begin
    Format(SYSERRORBUFFER, TC_FOLDERALREADYEXISTSOVERWRITE, TR4W_CFG_FILENAME);
    if YesOrNo(h, SYSERRORBUFFER) = IDno then Exit;
  end;

  f := CreateFile(TR4W_CFG_FILENAME, GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);
  if f <> INVALID_HANDLE_VALUE then
  begin

    Windows.GetDlgItemText(h, NC_CALL_EDIT, TempBuffer1, SizeOf(TempBuffer1));
    BytesToWrite := Format(wsprintfBuffer, ';Created by ' + TR4W_CURRENTVERSION + #13#10#13#10'[COMMANDS]'#13#10'MY CALL=%s'#13#10, TempBuffer1);
    sWriteFile(f, wsprintfBuffer, BytesToWrite);

    for i := 1 to CSAS do
    begin
      GetWindowText(InitialCommandsHWNDArray[i, 1], TempBuffer1, SizeOf(TempBuffer1));
      if GetWindowText(InitialCommandsHWNDArray[i, 2], TempBuffer2, SizeOf(TempBuffer2)) = 0 then Continue;
      BytesToWrite := Format(wsprintfBuffer, '%s=%s'#13#10, TempBuffer1, TempBuffer2);
      sWriteFile(f, wsprintfBuffer, BytesToWrite);
    end;

    Windows.GetDlgItemText(h, NC_CONTEST_COMBOBOX, TempBuffer1, SizeOf(TempBuffer1));
    BytesToWrite := Format(wsprintfBuffer, 'CONTEST=%s', TempBuffer1);
    sWriteFile(f, wsprintfBuffer, BytesToWrite);

    CloseHandle(f);

    DestroyWindow(h);
  end
  else
    ShowSysErrorMessage('CFG FILE');

end;

procedure DisplayCheckBox(Text: PChar);
begin
  asm
  push Text
  end;
  wsprintf(wsprintfBuffer, TC_IAMIN);
  asm add esp,12
  end;
  Windows.SetWindowText(NewContestCheckBox, wsprintfBuffer);
  Windows.ShowWindow(NewContestCheckBox, SW_SHOW);
end;

procedure SetCommentAndEnableEditControl(comment: PChar; EditControl: InitialCommands);
begin
  DisplayInitialCommand(EditControl);
  Windows.SetWindowText(NewContestCommentWndHandle, comment);
end;


procedure EnterCountyOrState(State: PChar);
begin
  DisplayInitialCommand(icmyState);
  asm
  push State
  push State
  end;
  wsprintf(wsprintfBuffer, TC_ENTERYOURCOUNTYORSTATEPOROVINCEDX);
  asm add esp,16
  end;
  Windows.SetWindowText(NewContestCommentWndHandle, wsprintfBuffer);
end;

procedure StartContestFromListbox();
var
  p                                     : PChar;
begin
  p := TR4W_CFG_FILENAME;
  GetDlgItemText(NewContestDlgWndHandle, 445, TR4W_CFG_FILENAME, SizeOf(TR4W_CFG_FILENAME));
  Windows.GetFullPathName(@TempBuffer1, 256, @TR4W_CFG_FILENAME, p);
  DestroyWindow(NewContestDlgWndHandle);
end;

function NewSelectContestListBoxProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): integer; stdcall;
begin
  if Msg = WM_KEYUP then
    if wParam = VK_RETURN then
      ChangeDir;
  Result := CallWindowProc(OldSelectContestListBoxProc, hwnddlg, Msg, wParam, lParam);
end;

procedure ChangeDir;
begin
  if DlgDirSelectEx(NewContestDlgWndHandle, TempBuffer1, SizeOf(TempBuffer1), NC_LISTBOX) = False then
  begin
    StartContestFromListbox;
    Exit;
  end;
  Windows.lstrcat(TempBuffer1, '*.CFG');
  DlgDirList(NewContestDlgWndHandle, TempBuffer1, NC_LISTBOX, 445, sfFLAG);

  SelectParentDir(NewContestListBoxHandle);
end;

procedure DisplayInitialCommand(Command: InitialCommands);
begin
  inc(NewContestDisplayedCommands);
  ShowWindow(InitialCommandsHWNDArray[NewContestDisplayedCommands, 1], SW_SHOWNORMAL);
  ShowWindow(InitialCommandsHWNDArray[NewContestDisplayedCommands, 2], SW_SHOWNORMAL);
  Windows.SetWindowText(InitialCommandsHWNDArray[NewContestDisplayedCommands, 1], InitialCommandsSA[Command]);
end;

end.

