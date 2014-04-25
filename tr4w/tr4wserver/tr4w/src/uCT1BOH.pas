unit uCT1BOH;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  PostUnit,
  uCommctrl,
  Windows,
  Messages,
  LogWind,
  //Country9,
  Tree
  ;

function ct1bohDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
function CT1BOHInfoString(QSOs: integer; Percents: integer): PChar;

implementation
uses MainUnit;

function ct1bohDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  Band                                  : integer;
  Continent                             : ContinentType;
  hLV                                   : HWND;
  lvi                                   : TLVItem;
  lvc                                   : tagLVCOLUMNA;
  TotalTimeOn                           : integer;
  Percent                               : integer;
  BandTotals                            : array[Band160..Band10] of integer;
  counter                               : integer;
const
  ca                                    : array[1..7] of BandType = (Band160, Band80, Band40, Band20, Band15, Band10, All);
begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin

        Windows.SetWindowText(hwnddlg, RC_CT1BOHIS2);

        hLV := CreateListView2(0, 0, 655+20, 132+20, hwnddlg);

//        hLV := Get101Window(hwnddlg);
        asm
        mov edx,[MainFixedFont]
        call tWM_SETFONT
        end;

        ListView_SetExtendedListViewStyle(hLV, LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT);

        {Insert Header}
        lvc.Mask := LVCF_TEXT or LVCF_WIDTH or LVCF_FMT;
        lvc.cx := 130;
        lvc.fmt := LVCFMT_CENTER;
        lvc.pszText := nil;
        ListView_InsertColumn(hLV, 0, lvc);
        TotalTimeOn := 0;
        counter := 0;
        for Band := 1 to 7 do
        begin
          TotalTimeOn := TotalTimeOn + TimeSpentByBand[ca[Band]];
          lvc.pszText := BandStringsArrayWithOutSpaces[ca[Band]];
          lvc.cx := 75;
          ListView_InsertColumn(hLV, counter + 1, lvc);
          inc(counter);
        end;

        {Time ON}
        lvi.iItem := 1;
        lvi.iSubItem := 0;
        lvi.Mask := LVIF_TEXT or LVIF_STATE;
        lvi.State := LVIS_SELECTED {or LVIS_DROPHILITED};
        lvi.pszText := TC_TIMEON;
        ListView_InsertItem(hLV, lvi);
        lvi.Mask := LVIF_TEXT;
        CalculateTotals;

        for Band := 1 to 7 do
        begin
{
          if TotalTimeOn = 0 then
            Percent := 0
          else
            Percent := round((TimeSpentByBand[ca[Band]] / TotalTimeOn) * 100);
}
          lvi.iItem := 0;
          lvi.iSubItem := Band;
//          lvi.pszText := CT1BOHInfoString(TimeSpentByBand[Band], Percent);
          lvi.pszText := MillisecondsToFormattedString(TimeSpentByBand[ca[Band]] * 1000, False);
          ListView_SetItem(hLV, lvi);

          BandTotals[ca[Band]] := 0;
//          for Continent := NorthAmerica to Oceania do
          for Continent := NorthAmerica to High(ContinentType) do
            BandTotals[ca[Band]] := BandTotals[ca[Band]] + ContinentQSOCount[ca[Band], Continent];
        end;

        for Continent := NorthAmerica to High(ContinentType) do
//        for Continent := NorthAmerica to Oceania do
        begin
          lvi.iSubItem := 0;
          lvi.iItem := Ord(Continent);
          lvi.pszText := tContinentArray[Continent];
          ListView_InsertItem(hLV, lvi);
          for Band := 1 to 7 do
          begin
            if BandTotals[ca[Band]] = 0 then
              Percent := 0
            else
              Percent := round((ContinentQSOCount[ca[Band], Continent] / BandTotals[ca[Band]]) * 100);
            lvi.iItem := Ord(Continent);
            lvi.iSubItem := Band;
            lvi.pszText := CT1BOHInfoString(ContinentQSOCount[ca[Band], Continent], Percent);
            ListView_SetItem(hLV, lvi);
          end;
        end;

      end;
    WM_COMMAND:
      if wParam = 2 then goto 1;

    WM_CLOSE: 1: EndDialog(hwnddlg, 0);

  end;

end;

function CT1BOHInfoString(QSOs: integer; Percents: integer): PChar;
begin
  if QSOs = 0 then
    wsprintfBuffer[0] := #0
  else
    Format(wsprintfBuffer, '%u (%u%%)', QSOs, Percents);

  Result := wsprintfBuffer;
end;

end.

