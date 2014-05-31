unit uSpotsFilter;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows,
  uCommctrl,

  Messages;
const
  SpotsFiltersCount                = 41;
var
  SpotsFiltersArray                : array[0..SpotsFiltersCount - 1] of PChar =
    (
    '160-CW',
    '160-SSB',
    '80-CW',
    '80-RTTY',
    '80-SSB',
    '40-CW',
    '40-RTTY',
    '40-SSB',
    '20-CW',
    '20-RTTY',
    '20-SSB',
    '15-CW',
    '15-RTTY',
    '15-SSB',
    '10-CW',
    '10-RTTY',
    '10-SSB',
    '30-CW',
    '30-RTTY',
    '17-CW',
    '17-RTTY',
    '17-SSB',
    '12-CW',
    '12-RTTY',
    '12-SSB',
    '6-CW',
    '6-SSB',
    '6-FM',
    '2-CW',
    '2-SSB',
    '2-FM',
    '1-CW',
    '1-SSB',
    '1-FM',
    '70-CW',
    '70-SSB',
    '70-FM',
    'MW',
    '4-MTR',
    'VLF',
    'HF'
    );

function ARSpotsFilterDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  SpotsFilterListView              : HWND;
implementation

uses MainUnit, uTelnet;

function ARSpotsFilterDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1, setitem;
var
  elvi                             : TLVItem;
  elvc                             : tagLVCOLUMNA;
  I                                : integer;
  Selected                         : boolean;
  p                                : PChar;
begin
  RESULT := False;
  case Msg of
    WM_INITDIALOG:
      begin
        Windows.SendDlgItemMessage(hwnddlg, 103, BM_SETCHECK, BST_CHECKED, 0);
        SpotsFilterListView := Get101Window(hwnddlg);

        ListView_SetExtendedListViewStyle(SpotsFilterListView, LVS_EX_CHECKBOXES);
        elvc.Mask := LVCF_TEXT or LVCF_WIDTH or LVCF_FMT;

        elvc.fmt := LVCFMT_LEFT;
        elvc.pszText := nil;
        elvc.cx := 90;
        ListView_InsertColumn(SpotsFilterListView, 0, elvc);

        elvi.Mask := LVIF_TEXT;
        for I := 0 to SpotsFiltersCount - 1 do
        begin
          elvi.iItem := I;
          elvi.iSubItem := 0;
          elvi.pszText := SpotsFiltersArray[I];
          ListView_InsertItem(SpotsFilterListView, elvi);
        end;

      end;

    WM_COMMAND:
      begin
        case wParam of
          106, 2: goto 1;
          102:
            begin
              SendViaSocket('SET/NOFILTER');
              goto 1;
            end;
          105:
            begin
              Selected := False;
              if Windows.SendDlgItemMessage(hwnddlg, 104, BM_GETCHECK, 0, 0) = 1 then
                p := 'SET/FILTER DXBANDMODE/REJECT '
              else
                p := 'SET/FILTER DXBANDMODE/PASS ';
              Windows.ZeroMemory(@wsprintfBuffer, SizeOf(wsprintfBuffer));
              Windows.lstrcat(wsprintfBuffer, p);

              for I := 0 to SpotsFiltersCount - 1 do
              begin
                if ListView_GetCheckState(SpotsFilterListView, I) <> 0 then
                begin
                  Selected := True;
                  ListView_GetItemText(SpotsFilterListView, I, 0, TempBuffer1, 10);
                  Windows.lstrcat(wsprintfBuffer, TempBuffer1);
                  Windows.lstrcat(wsprintfBuffer, ',');
                end;
              end;
              if Selected then
              begin
                wsprintfBuffer[StrLen(wsprintfBuffer) - 1] := #0;
                SendViaSocket(wsprintfBuffer);
              end;

              goto 1;
            end;
        end;
      end;
    WM_CLOSE: 1: EndDialog(hwnddlg, 0);
  end;
end;
end.

