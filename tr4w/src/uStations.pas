unit uStations;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Tree,
  Windows,
  uCallsigns,
  uCommctrl,
  LogDupe,
  LogWind,
  Messages
  ;

function StationsDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure FillStationsColumn;
function AddCallsignToStationColumn(Call: CallString): integer;
procedure UpdateStationStatus(Call: CallString; i: integer);
function FindStationInCallsignColumn(Call: CallString): integer;
procedure UpdateAllStationsList;
procedure UpdateCallsignAfterEditing(Before, After: CallString);
procedure SetStationsCallsignMask;
procedure EnumSTATIONSTXT(FileString: PShortString);

var
//  StationsListView                      : HWND;
  StationsListFileInUse                 : boolean;
  StationsStartBand                     : BandType;

implementation
uses MainUnit;

function StationsDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
var
  elvc                                  : tagLVCOLUMNA;
  TempBand                              : BandType;
begin
  Result := False;
  case Msg of
    //    WM_WINDOWPOSCHANGING: WINDOWPOSCHANGINGPROC(PWindowPos(lParam));
    //    WM_EXITSIZEMOVE: FrmSetFocus;
    WM_SIZE, WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);
    WM_NOTIFY: if PNMHdr(lParam)^.code = NM_RELEASEDCAPTURE then FrmSetFocus;

    {
        WM_NOTIFY:
          begin
            if PNMHdr(lParam)^.code = LVN_GETDISPINFO then PLVDispInfo(lParam).Item.pszText := 'asas';
          end;
    }
    WM_INITDIALOG:
      begin
        tr4w_WindowsArray[tw_STATIONS_INDEX].WndHandle := hwnddlg;
        CreateListView(tw_STATIONS_INDEX, mweStations, LVS_SORTASCENDING);

//        ListView_SetExtendedListViewStyle(wh[mweStations], integer(tShowGridlines) * LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT);

        elvc.Mask := LVCF_TEXT or LVCF_WIDTH or LVCF_FMT;

        elvc.fmt := LVCFMT_LEFT;
        elvc.pszText := RC_CALLSIGN;
        elvc.cx := 75;
        ListView_InsertColumn(wh[mweStations], 0, elvc);

        elvc.fmt := LVCFMT_CENTER;
        for TempBand := Band160 to Band10 do
        begin
          elvc.pszText := BandStringsArrayWithOutSpaces[TempBand];
          elvc.cx := 36;
          ListView_InsertColumn(wh[mweStations], Ord(TempBand) + 1, elvc);
        end;
        FillStationsColumn;
      end;

    WM_CLOSE:
      begin
        wh[mweStations] := 0;
        CloseTR4WWindow(tw_STATIONS_INDEX);
      end;

  end;
end;

procedure FillStationsColumn;
var
  Index                                 : integer;
begin
  StationsListFileInUse := False;
  if not EnumerateLinesInFile('STATIONS.TXT', EnumSTATIONSTXT, True) then
{
  if OpenFileForRead(FileRead, TR4W_LOG_PATH_NAME + 'STATIONS.TXT') then
  begin
    StationsListFileInUse := False;
    while not Eof(FileRead) do
    begin
      ReadLn(FileRead, Call);
      if Call <> '' then
        if Call[1] <> ';' then
          AddCallsignToStationColumn(Call);
    end;
    Close(FileRead);
    StationsListFileInUse := True;
  end
  else
}
  begin
    for Index := 0 to CallsignsList.Count - 1 do
      if CallsignsList.GetQSOs(Index) > 0 then
        AddCallsignToStationColumn(CallsignsList.Get(Index));
    StationsListFileInUse := False;
  end;
  UpdateAllStationsList;
end;

function AddCallsignToStationColumn(Call: CallString): integer;
var
  elvi                                  : TLVItem;
begin
  if StationsListFileInUse then Exit;

  if StationsCallsignsMask <> '' then
    if pos(StationsCallsignsMask, Call) = 0 then Exit;
  Call[length(Call) + 1] := #0;
  strU(Call);
  elvi.Mask := LVIF_TEXT;
  elvi.iSubItem := 0;
  elvi.pszText := @Call[1];
  Result := ListView_InsertItem(wh[mweStations], elvi);
end;

procedure UpdateStationStatus(Call: CallString; i: integer);
var
  Index                                 : integer;
  ItemIndex                             : integer;
  da                                    : TDupesArray;
  QSOB4                                 : boolean;
  TempMode                              : ModeType;
  p                                     : PChar;
  h                                     : HWND;
  TempIndex                             : integer;
begin
  if tr4w_WindowsArray[tw_STATIONS_INDEX].WndHandle = 0 then Exit;
  Call[length(Call) + 1] := #0;
  if i = -1 then
  begin
    ItemIndex := FindStationInCallsignColumn(Call);

    if ItemIndex = -1 then
    begin
      if StationsListFileInUse = False then ItemIndex := AddCallsignToStationColumn(Call) else Exit;
    end

  end
  else
    ItemIndex := i;
  h := wh[mweStations];

  if not CallsignsList.FindCallsign(Call, Index) then Exit;
  if not CallsignsList.GetDupesArray(Index, da) then Exit;

  if QSOByMode then TempMode := ActiveMode else TempMode := Both;

  for TempIndex := 0 to 5 { BandType(Ord(StationsStartBand) + 5)} do
  begin
    QSOB4 := (da[TempMode] and (1 shl (Ord(StationsStartBand) + TempIndex))) <> 0;
    if QSOB4 then p := '+' else p := nil;
    ListView_SetItemText(h, ItemIndex, TempIndex + 1, p);
  end;
  if i = -1 then
  begin
    ListView_SetItemState(h, ItemIndex, LVIS_SELECTED, LVIS_SELECTED);
    ListView_EnsureVisible(h, ItemIndex, False);
  end;
end;

function FindStationInCallsignColumn(Call: CallString): integer;
var
  plvfi                                 : TLVFindInfo;
begin
  Call[length(Call) + 1] := #0;
  plvfi.Flags := LVFI_STRING;
  plvfi.psz := @Call[1];
  Result := SendMessage(wh[mweStations], LVM_FINDITEM, -1, LONGINT(@plvfi));
end;

procedure UpdateAllStationsList;
var
  Call                                  : array[0..CallstringLength] of Byte;
  Index                                 : integer;
  elvc                                  : tagLVCOLUMNA;
begin
  if tr4w_WindowsArray[tw_STATIONS_INDEX].WndHandle = 0 then Exit;
  if ActiveBand in [Band6..BandLight] then StationsStartBand := Band6 else StationsStartBand := Band160;
  elvc.Mask := LVCF_TEXT;
  for Index := 0 to 5 do
  begin
    elvc.pszText := BandStringsArrayWithOutSpaces[BandType(Index + Ord(StationsStartBand))];
    ListView_SetColumn(wh[mweStations], Index + 1, elvc);
  end;

  tSetWindowRedraw(wh[mweStations], False);
  for Index := 0 to ListView_GetItemCount(wh[mweStations]) - 1 do
  begin
    Call[0] := ListView_GetItemText(wh[mweStations], Index, 0, @Call[1], 12);
    UpdateStationStatus(CallString(Call), Index);
  end;
  tSetWindowRedraw(wh[mweStations], True);
  Format(wsprintfBuffer, TC_STATIONSINMODE, ModeStringArray[ActiveMode]);
  Windows.SetWindowText(tr4w_WindowsArray[tw_STATIONS_INDEX].WndHandle, wsprintfBuffer);
end;

procedure SelectCallsignInStationsList();
begin

end;

procedure UpdateCallsignAfterEditing(Before, After: CallString);
var
  Index                                 : integer;
begin
  if tr4w_WindowsArray[tw_STATIONS_INDEX].WndHandle = 0 then Exit;
  if Before = After then Exit;
  Index := FindStationInCallsignColumn(Before);
  if Index = -1 then Exit;
  ListView_DeleteItem(wh[mweStations], Index);
  UpdateStationStatus(After, AddCallsignToStationColumn(After));
end;

procedure SetStationsCallsignMask;
begin
  if wh[mweStations] = 0 then Exit;
  ListView_DeleteAllItems(wh[mweStations]);
  FillStationsColumn;
end;

procedure EnumSTATIONSTXT(FileString: PShortString);
begin
  if FileString^[1] <> ';' then
  begin
    AddCallsignToStationColumn(FileString^);
    StationsListFileInUse := True;
  end;
end;

end.

