unit uOption;
{$IMPORTEDDATA OFF}
interface

uses
  uBMCF,
  uWinKey,
  uDialogs,
  uCFG,
  TF,
  VC,
  uNet,
  WinSock2,
  uCommctrl,
  Windows,
  LogWind,
  LogNet,
  Tree,
  Messages
  ;

const

  COMMAND_FIELD                         = 0;
  VALUE_FIELD                           = 1;
  NUMBER_FIELD                          = 2;
  FILE_FIELD                            = 3;

var
  SomeCommandWasChanged                 : boolean;
  CommandsFilter                        : CFGFunc;
  CommandToSet                          : PChar;
  PreviousHelpRow                       : integer;
  settingswindowhandle                  : HWND;
  OldSLVProc                            : Pointer;
  tShouldRestartProgram                 : boolean;
  //  Buffer                                : array[1..250] of Char;
  //  lvi                                   : tagLVITEM;
  //  lvc                                   : tagLVCOLUMNA;
  //  lvc                                   : tagLVCOLUMNA;
  //  lvi                                   : TLVItem;

  //  c, V                                  : string;

      {SettingsListviev variables}
  Settingslvc                           : tagLVCOLUMNA;
  Settingslvi                           : TLVItem;
  SettingshLV                           : HWND;
//  SettingshLV2                          : HWND;
procedure ShowHelpMessageForCommand;
function SettingsDlgProc2(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): longword {BOOL}; stdcall;
procedure ChangeValue2;
procedure CommandsToListView2(f: CFGFunc);
procedure SaveValue2(Row: integer);
procedure SendParameterToNetwork;

function NewSLVProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT; stdcall;

implementation
uses MainUnit;

var
  IndexArray                            : array[1..CommandsArraySize] of Word;

function SettingsDlgProc2(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): longword {BOOL}; stdcall;
label
  1;
var
  TempInteger                           : integer;
  plvfi                                 : TLVFindInfo;
  St                                    : Cardinal;
  m                                     : HMENU;
const
  l                                     : array[0..4] of PChar = (RC_RETURNTOMOD, RC_ALTW, RC_ALTG, RC_ALTN, EXIT_WORD);
begin
  Result := 0; // False;
  case Msg of
//    WM_HELP: tWinHelp(61);
    WM_INITDIALOG:
      begin
        Windows.SetWindowText(hwnddlg, RC_OPTIONS);

        SettingshLV := tWM_SETFONT(CreateListView2(0, 0, 548, 432, hwnddlg), MainFixedFont);

        for TempInteger := 0 to 4 do
        begin
          St := 0;
          M := 200 + TempInteger;
          if TempInteger = 0 then
          begin
            St := BS_DEFPUSHBUTTON or BS_NOTIFY or BS_CENTER;
            m := 1;
          end;

          CreateButton(St, l[TempInteger], TempInteger * 110 + 5, 470, 107, hwnddlg, M);
        end;

        CreateStatic(RC_ARROWTOSELIT, 0, 433, 548, hwnddlg, 106);

        CreateStatic(RC_DEFAULT, 560, 5, 210, hwnddlg, 103);
        CreateStatic(nil, 560, 30, 210, hwnddlg, 104);
        CreateStatic(RC_DESCRIPTION, 560, 55, 210, hwnddlg, 109);
        CreateEdit(ES_MULTILINE or ES_READONLY or WS_VSCROLL, 560, 80, 210, 350, hwnddlg, 105);

        EnableWindowFalse(hwnddlg, 202);

        SomeCommandWasChanged := False;
        tShouldRestartProgram := False;
        PreviousHelpRow := MAXWORD;
        settingswindowhandle := hwnddlg;

        tWM_SETFONT(GetDlgItem(hwnddlg, 105), MainFixedFont);
        tWM_SETFONT(GetDlgItem(hwnddlg, 104), MainFixedFont);

        CommandsToListView2(CFGFunc(lParam));
        OldSLVProc := Pointer(Windows.SetWindowLong(hwnddlg, GWL_WNDPROC, integer(@NewSLVProc)));

        TempInteger := 0;

        if CommandToSet <> nil then
        begin
          plvfi.Flags := LVFI_STRING;
          plvfi.psz := CommandToSet;
          TempInteger := ListView_FindItem(SettingshLV, -1, plvfi);
          if TempInteger = -1 then TempInteger := 0;
          CommandToSet := nil;
        end;

        Settingslvi.Mask := LVIF_STATE;
        Settingslvi.stateMask := LVIS_FOCUSED or LVIS_SELECTED;
        Settingslvi.State := LVIS_SELECTED or LVIS_FOCUSED;
        SendMessage(SettingshLV, LVM_SETITEMSTATE, TempInteger, LONGINT(@Settingslvi));
        ListView_EnsureVisible(SettingshLV, TempInteger, False);
        Windows.ZeroMemory(@Changed, SizeOf(Changed));
      end;

    WM_COMMAND:
      begin
        case wParam of
          112: ShowHelp('ru_configcommandswindow');
          204, 2: goto 1; //Close

          1: ChangeValue2; //Modify

          202:
            begin
              for TempInteger := 0 to CommandsArraySize - 1 do if Changed[TempInteger] = True then
                begin
                  SaveValue2(TempInteger);
                end;
              SendMessage(SettingshLV, LVM_UPDATE, 0, 0);

              EnableWindowFalse(hwnddlg, 202);
              EnableWindowFalse(hwnddlg, 201);
            end;

          201:
            begin
              SaveValue2(ListView_GetNextItem(SettingshLV, -1, LVNI_SELECTED));
              EnableWindowFalse(hwnddlg, 201);
//              EnableWindowFalse(hwnddlg, 202);
            end;

          203: SendParameterToNetwork;

        end;
      end;

    WM_CLOSE:
      begin
        1:
        settingswindowhandle := 0;

        if SomeCommandWasChanged then
          if CommandsFilter = cfWK then
          begin
            wkClose;
            wkOpen;
          end;

//        SendMessage(SettingshLV, LVM_FIRST + 160, 0, 0);
        EndDialog(hwnddlg, 0);
        if tShouldRestartProgram then ShowMessage(
//        'Restart of the program is required for configuration change to take effect.'
            'To apply the changes TR4W needs to restart.'
            );

      end;
{
    WM_NOTIFY:
      begin

        with PNMHdr(lParam)^ do
          if (hWndFrom = SettingshLV) then
            case code of
              NM_DBLCLK: ChangeValue;
            end;
      end;
}
  end;

end;

procedure CommandsToListView2(f: CFGFunc);

var
  i                                     : integer;
  Command                               : integer;
  p                                     : Pointer;
  TempInteger                           : integer;
  TempWindowElement                     : TMainWindowElement;
  TempPchar                             : PChar;
begin

  ListView_SetExtendedListViewStyle(SettingshLV, LVS_EX_INFOTIP or LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT);

  Settingslvc.Mask := LVCF_TEXT or LVCF_WIDTH or LVCF_FMT;
  Settingslvc.pszText := TC_COMMAND;
  Settingslvc.cx := 225;
  if CommandsFilter = cfCol then Settingslvc.cx := 275;
  ListView_InsertColumn(SettingshLV, COMMAND_FIELD, Settingslvc);

  Settingslvc.pszText := TC_VALUE;
  Settingslvc.cx := 220;
  if CommandsFilter = cfCol then Settingslvc.cx := 170;
  ListView_InsertColumn(SettingshLV, VALUE_FIELD, Settingslvc);

  Settingslvc.pszText := '#';
  Settingslvc.cx := 35;
  ListView_InsertColumn(SettingshLV, NUMBER_FIELD, Settingslvc);

  Settingslvc.pszText := RC_FILE;
  Settingslvc.cx := 45;
  ListView_InsertColumn(SettingshLV, FILE_FIELD, Settingslvc);

  Settingslvi.Mask := LVIF_TEXT;
  i := 0;

  if CommandsFilter = cfCol then
  begin
    for TempWindowElement := Low(TMainWindowElement) to High(TMainWindowElement) do
    begin
      {color begin}
      inc(i);
      Settingslvi.iItem := i - 1;
      Settingslvi.iSubItem := COMMAND_FIELD;

      Format(wsprintfBuffer, '%s WINDOW COLOR', TWindows[TempWindowElement].mweName);

      Settingslvi.pszText := wsprintfBuffer;
      ListView_InsertItem(SettingshLV, Settingslvi);

      Settingslvi.iSubItem := VALUE_FIELD;
      Settingslvi.pszText := tr4wColorsSA[TWindows[TempWindowElement].mweColor];
      ListView_SetItem(SettingshLV, Settingslvi);

      Settingslvi.iSubItem := NUMBER_FIELD;
      Settingslvi.pszText := inttopchar(i);
      ListView_SetItem(SettingshLV, Settingslvi);
      {color end}

      inc(i);
      {background begin}
      Settingslvi.iItem := i - 1;
      Settingslvi.iSubItem := COMMAND_FIELD;

      Format(wsprintfBuffer, '%s WINDOW BACKGROUND', TWindows[TempWindowElement].mweName);

      Settingslvi.pszText := wsprintfBuffer;
      ListView_InsertItem(SettingshLV, Settingslvi);

      Settingslvi.iSubItem := VALUE_FIELD;
      Settingslvi.pszText := tr4wColorsSA[TWindows[TempWindowElement].mweBackG];
      ListView_SetItem(SettingshLV, Settingslvi);

      Settingslvi.iSubItem := NUMBER_FIELD;
      Settingslvi.pszText := inttopchar(i);
      ListView_SetItem(SettingshLV, Settingslvi);
      {background end}

    end;
    Exit;
  end;

  for Command := 1 to CommandsArraySize do
    if not (CFGCA[Command].crS in [csRem]) then
      if CFGCA[Command].crType in [ctFreqList, ctURL, ctPortLPT, ctDirectory, ctFileName, ctAlphaChar, ctChar, ctBand, ctReal, ctByte, ctInteger, ctWord, ctString, ctBoolean, ctOther, ctMultiplier] then
      begin

//        if CommandsFilter <> cfAll then
        if CFGCA[Command].cfFunc <> CommandsFilter then Continue;

//        if pos('WINDOW',CFGCA[Command].crCommand) = 0 then Continue;

        inc(i);

        IndexArray[i] := Command;

        Settingslvi.iItem := i - 1;
        Settingslvi.iSubItem := COMMAND_FIELD;
        Settingslvi.pszText := CFGCA[Command].crCommand;
        ListView_InsertItem(SettingshLV, Settingslvi);
{-----------------------------------------------}
        Settingslvi.pszText := nil;
        Settingslvi.iSubItem := VALUE_FIELD;

        if CFGCA[Command].crKind in [ckArray] then
        begin
          Settingslvi.pszText := inttopchar(ArrayRecordArray[integer(CFGCA[Command].crAddress)].arVar^);
        end;

        if CFGCA[Command].crKind in [ckNormal, ckList] then
        begin

          case CFGCA[Command].crType of
            ctFreqList:
              Settingslvi.pszText := '...';

            ctDirectory, ctFileName:
              Settingslvi.pszText := CFGCA[Command].crAddress;

            ctURL, ctMessage, ctString:
              begin
                Settingslvi.pszText := CFGCA[Command].crAddress;
                inc(Settingslvi.pszText);
              end;

            ctBoolean: Settingslvi.pszText := BA[PBoolean(CFGCA[Command].crAddress)^];

            ctReal:
              Settingslvi.pszText := PChar(RealToStr2(PDouble(CFGCA[Command].crAddress)^));

            ctInteger:
              Settingslvi.pszText := inttopchar(PInteger(CFGCA[Command].crAddress)^);

            ctWord:
              Settingslvi.pszText := inttopchar(PWORD(CFGCA[Command].crAddress)^);

            ctByte:
              Settingslvi.pszText := inttopchar(PByte(CFGCA[Command].crAddress)^);

            ctChar, ctAlphaChar:
              begin
                CID_TWO_BYTES[0] := PChar(CFGCA[Command].crAddress)^;
                Settingslvi.pszText := CID_TWO_BYTES;
                if CID_TWO_BYTES[0] = ' ' then
                  Settingslvi.pszText := 'SPACE';
              end;

          end;

          if CFGCA[Command].crKind = ckList then
          begin
            TempInteger := integer(CFGCA[Command].crAddress);
            p := PChar(ListParamArray[TempInteger].lpArray) + (ListParamArray[TempInteger].lpVar^ * 4);
            p := Pointer(p^);
            Settingslvi.pszText := PChar(p);
          end;

        end;
        ListView_SetItem(SettingshLV, Settingslvi);
{-----------------------------------------------}

        Settingslvi.iSubItem := NUMBER_FIELD;
        Settingslvi.pszText := inttopchar(i);
        ListView_SetItem(SettingshLV, Settingslvi);

        if CFGCA[Command].crC = 1 then
        begin
          Settingslvi.iSubItem := FILE_FIELD;
          Settingslvi.pszText := 'CFG';
          ListView_SetItem(SettingshLV, Settingslvi);
        end;
      end;

end;

procedure ChangeValue2;
label
  Change, EnableButtons;
var
  Row                                   : integer;
  Index                                 : integer;
  Index2                                : integer;
  TempString                            : ShortString;
  TempInteger                           : integer;
  TempReal                              : REAL;
  p                                     : Pointer;
  c                                     : integer;
  TempColor                             : Ptr4wColors;

begin

  Row := SendMessage(SettingshLV, LVM_GETNEXTITEM, -1, 1);

  if CommandsFilter = cfCol then
  begin
    TempInteger := Row div 2; //window
    if (Row mod 2) = 0 then
      TempColor := @TWindows[TMainWindowElement(TempInteger)].mweColor //1-back
    else
      TempColor := @TWindows[TMainWindowElement(TempInteger)].mweBackG;
    if TempColor^ = High(tr4wColors) then TempColor^ := Low(tr4wColors) else inc(TempColor^);

    if TWindows[TMainWindowElement(TempInteger)].mweiStyle = 1 then
//   if TMainWindowElement(TempInteger) = mweEditableLog then
      SetListViewColor(TMainWindowElement(TempInteger))
    else

      Windows.InvalidateRect(wh[TMainWindowElement(TempInteger)], nil, False);
//    Windows.FlashWindow(wh[TMainWindowElement(TempInteger)], false);

    ListView_SetItemText(SettingshLV, Row, VALUE_FIELD, tr4wColorsSA[TempColor^]);

{
    Index2 := integer(CFGCA[Index].crAddress);
    if ListParamArray[Index2].lpVar^ = High(tr4wColors) then
      ListParamArray[Index2].lpVar^ := 0 else inc(ListParamArray[Index2].lpVar^);
    p := PChar(ListParamArray[Index2].lpArray) + (ListParamArray[Index2].lpVar^ * 4);
    p := Pointer(p^);
    ListView_SetItemText(SettingshLV, Row, 1, PChar(p));
}
    goto EnableButtons;
  end;

  Index := IndexArray[Row + 1];

  if CFGCA[Index].crJ = 2 then Exit;

  if
    (CFGCA[Index].crType in [ctFreqList, ctURL, ctDirectory, ctFileName, ctAlphaChar, ctChar, ctBoolean, ctString, ctByte, ctInteger, ctReal, ctWord])
    or (CFGCA[Index].crKind in [ckArray, ckList]) then
  begin

    if CFGCA[Index].crKind = ckList then
    begin
      Index2 := integer(CFGCA[Index].crAddress);
      if ListParamArray[Index2].lpVar^ = ListParamArray[Index2].lpLength then
        ListParamArray[Index2].lpVar^ := 0 else inc(ListParamArray[Index2].lpVar^);
      p := PChar(ListParamArray[Index2].lpArray) + (ListParamArray[Index2].lpVar^ * 4);
      p := Pointer(p^);
      ListView_SetItemText(SettingshLV, Row, 1, PChar(p));
      goto Change;
    end;

    if CFGCA[Index].crKind in [ckArray] then
    begin
      Index2 := integer(CFGCA[Index].crAddress);
      for c := 0 to ArrayRecordArray[Index2].arArrayLength do
      begin
//        if PChar(PChar(ArrayRecordArray[Index2].arArrayPtr) + (c * 4))^ = Char(ArrayRecordArray[Index2].arVar^) then
        if PInteger(integer(ArrayRecordArray[Index2].arArrayPtr) + (c * 4))^ = integer(ArrayRecordArray[Index2].arVar^) then
          Break;
      end;

      if (c) = ArrayRecordArray[Index2].arArrayLength - 0 then c := 0 else inc(c);
      ArrayRecordArray[Index2].arVar^ := PInteger(PChar(ArrayRecordArray[Index2].arArrayPtr) + (c * 4))^;
      ListView_SetItemText(SettingshLV, Row, 1, inttopchar(ArrayRecordArray[Index2].arVar^));
      goto Change;
    end;

    case CFGCA[Index].crType of
      ctBoolean:
        begin
          InvertBoolean(PBoolean(CFGCA[Index].crAddress)^);
          ListView_SetItemText(SettingshLV, Row, 1, BA[PBoolean(CFGCA[Index].crAddress)^]);
        end;

      ctByte:
        begin
          Windows.ZeroMemory(@TempString, SizeOf(TempString));
          tInputDialogPreviousValue := IntToStr(PByte(CFGCA[Index].crAddress)^);
          TempInteger := QuickEditInteger(TC_NEWVALUE, 5);
          if TempInteger = -1 then Exit;

          ListView_GetItemText(SettingshLV, Row, 0, @TempBuffer1[1], 40);
          if CheckCommand(@TempBuffer1, IntToStr(TempInteger)) then
          begin
            PByte(CFGCA[Index].crAddress)^ := TempInteger;
            ListView_SetItemText(SettingshLV, Row, 1, inttopchar(TempInteger));
          end
          else
            Exit;
        end;

      ctWord:
        begin
          Windows.ZeroMemory(@TempString, SizeOf(TempString));
          tInputDialogPreviousValue := IntToStr(PWORD(CFGCA[Index].crAddress)^);
          TempInteger := QuickEditInteger(TC_NEWVALUE, 5);
          if TempInteger = -1 then Exit;

          ListView_GetItemText(SettingshLV, Row, 0, @TempBuffer1[1], 40);
          if CheckCommand(@TempBuffer1, IntToStr(TempInteger)) then
          begin
            PWORD(CFGCA[Index].crAddress)^ := TempInteger;
            ListView_SetItemText(SettingshLV, Row, 1, inttopchar(TempInteger));
          end
          else
            Exit;
        end;

      ctReal:
        begin
          Windows.ZeroMemory(@TempString, SizeOf(TempString));

          Val(tInputDialogPreviousValue, PDouble(CFGCA[Index].crAddress)^, TempInteger);
          TempReal := QuickEditReal(TC_NEWVALUE, 9);
          if TempReal = -1 then Exit;

          ListView_GetItemText(SettingshLV, Row, 0, @TempBuffer1[1], 40);
          Str(TempReal: 2: 2, TempString);
          if CheckCommand(@TempBuffer1, TempString) then
          begin
            PDouble(CFGCA[Index].crAddress)^ := TempReal;

            ListView_SetItemText(SettingshLV, Row, 1, @TempString[1]);
          end
          else
            Exit;
        end;

      ctInteger:
        begin
          Windows.ZeroMemory(@TempString, SizeOf(TempString));
          tInputDialogPreviousValue := IntToStr(PInteger(CFGCA[Index].crAddress)^);
          TempInteger := QuickEditInteger(TC_NEWVALUE, 9);
          if TempInteger = -1 then Exit;

          ListView_GetItemText(SettingshLV, Row, 0, @TempBuffer1[1], 40);
          if CheckCommand(@TempBuffer1, IntToStr(TempInteger)) then
          begin
            PInteger(CFGCA[Index].crAddress)^ := TempInteger;
            ListView_SetItemText(SettingshLV, Row, 1, inttopchar(TempInteger));
          end
          else
            Exit;
        end;

      ctAlphaChar, ctChar:
        begin
          Windows.ZeroMemory(@TempString, SizeOf(TempString));
          TempString := QuickEditResponse(TC_NEWVALUE, 1);
          if TempString = '' then Exit;

          ListView_GetItemText(SettingshLV, Row, 0, @TempBuffer1[1], 40);
          if CheckCommand(@TempBuffer1, TempString) then
          begin
            PChar(CFGCA[Index].crAddress)^ := TempString[1];
            if TempString[1] = ' ' then
            begin
              Windows.ZeroMemory(@TempString, SizeOf(TempString));
              TempString := 'SPACE';
            end;
            ListView_SetItemText(SettingshLV, Row, 1, @TempString[1]);
          end;
        end;

      ctDirectory:
        begin
          SelectFolder(settingswindowhandle, FileNameType(CFGCA[Index].crAddress^));
          SetFocus(settingswindowhandle);
          ListView_SetItemText(SettingshLV, Row, 1, PChar(CFGCA[Index].crAddress));
        end;

      ctFileName:
        begin
          //SelectFileOfFolder(settingswindowhandle, FileNameType(CFGCA[Index].crAddress^), nil, CFGCA[Index].crType);
          //Windows.SetFocus(settingswindowhandle);
          if not OpenFileDlg(nil, settingswindowhandle, nil, FileNameType(CFGCA[Index].crAddress^), 0) then Exit;
          ListView_SetItemText(SettingshLV, Row, 1, PChar(CFGCA[Index].crAddress));
        end;

      ctFreqList:
        begin
//          tDialogBox(44, @BMCFDlgProc);
//          DialogBox(hInstance, MAKEINTRESOURCE(44), settingswindowhandle, @BMCFDlgProc);
          CreateModalDialog(200, 155, settingswindowhandle, @BMCFDlgProc, 0);
          Exit;
        end;

      ctURL, ctString:
        begin
          Windows.ZeroMemory(@TempString, SizeOf(TempString));

          if CFGCA[Index].crType = ctURL then tInputDialogLowerCase := True;
          tInputDialogPreviousValue := pShortString(CFGCA[Index].crAddress)^;
          TempString := QuickEditResponse(TC_NEWVALUE, CFGCA[Index].crMax);

          if TempString = '' then Exit;

          ListView_GetItemText(SettingshLV, Row, 0, @TempBuffer1[1], 40);
          if CheckCommand(@TempBuffer1, TempString {CMD}) then
          begin
            pShortString(CFGCA[Index].crAddress)^ := TempString;
            ListView_SetItemText(SettingshLV, Row, 1, @TempString[1]);
          end;
        end;
    end;

    Change:
    if CFGCA[Index].crP <> 0 then
    begin
      p := CommandsProcArray[CFGCA[Index].crP];
      asm call P end;
    end;

    EnableButtons:
    Changed[Row] := True;
    SomeCommandWasChanged := True;
//    if CFGCA[Index].crJ = 1 then tShouldRestartProgram := True;
    EnableWindowTrue(settingswindowhandle, 201);
    EnableWindowTrue(settingswindowhandle, 202);
  end;
end;

procedure SaveValue2(Row: integer);
label
  NoText;
var
  Index                                 : integer;
  p                                     : PChar;
  lpAppName                             : PChar;
begin
  Changed[Row] := False;
  Index := IndexArray[Row + 1];
  ListView_GetItemText(SettingshLV, Row, COMMAND_FIELD, @TempBuffer1, SizeOf(TempBuffer1));
  ListView_GetItemText(SettingshLV, Row, VALUE_FIELD, @TempBuffer2, SizeOf(TempBuffer2));
  asm
  cmp eax,0
  jz NoText;
  end;

  p := TR4W_INI_FILENAME;
  lpAppName := _COMMANDS;

  case CommandsFilter of
    cfCol: lpAppName := 'COLORS';
    cfWK: lpAppName := 'WINKEYER';
  else
    begin
      tShouldRestartProgram := CFGCA[Index].crJ = 1;
      if CFGCA[Index].crC = 1 then p := TR4W_CFG_FILENAME;
    end;
  end;
{
  if CommandsFilter <> cfCol then
  begin
    tShouldRestartProgram := CFGCA[Index].crJ = 1;
    if CFGCA[Index].crC = 1 then p := TR4W_CFG_FILENAME;
  end
  else
    lpAppName := 'COLORS';
}
  Windows.WritePrivateProfileString(lpAppName, TempBuffer1, TempBuffer2, p);
  NoText:
end;

function NewSLVProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT; stdcall;
var
  lplvcd                                : PNMLVCustomDraw;
  Index                                 : integer;
begin
  if Msg = WM_NOTIFY then
  begin

    with PNMHdr(lParam)^ do
//      if (hWndFrom = SettingshLV) then
      case code of
        LVN_ITEMCHANGED: ShowHelpMessageForCommand;
        NM_DBLCLK: ChangeValue2;
        NM_CUSTOMDRAW:
          begin
            lplvcd := PNMLVCustomDraw(lParam);

            case lplvcd.nmcd.dwDrawStage of
              CDDS_PREPAINT:
                begin
                  Result := CDRF_NOTIFYITEMDRAW;
                  Exit;
                end;
              CDDS_ITEMPREPAINT:
                begin
                  if CommandsFilter <> cfCol then
                  begin
                    Index := IndexArray[lplvcd.nmcd.dwItemSpec + 1];
                    if (CFGCA[Index].crJ in [2, 3]) {RO} then lplvcd.clrText := $00B0B0B0;
                    if CFGCA[Index].crJ = 1 then lplvcd.clrText := $00FF0000;
                  end;
                  if Changed[lplvcd.nmcd.dwItemSpec {Index}] then lplvcd.clrTextBk := $0000FFFF;
                end;
            end;
          end;

      end;
  end;

  Result := CallWindowProc(OldSLVProc, hwnddlg, Msg, wParam, lParam);
end;

procedure ShowHelpMessageForCommand;
var
  Row                                   : integer;
  Index                                 : integer;
begin
  Row := SendMessage(SettingshLV, LVM_GETNEXTITEM, -1, LVNI_SELECTED or LVNI_FOCUSED);
  if Row = -1 then Exit;
  if Row = PreviousHelpRow then Exit;
  PreviousHelpRow := Row;
  Index := IndexArray[Row + 1];
  Windows.EnableWindow(GetDlgItem(settingswindowhandle, 203), (NetSocket <> 0) and (CFGCA[Index].crJ <> 2));
  Windows.EnableWindow(GetDlgItem(settingswindowhandle, 201), Changed[Row] = True);

  ListView_GetItemText(SettingshLV, Row, COMMAND_FIELD, @TempBuffer1, SizeOf(TempBuffer1));
  GetPrivateProfileString(TempBuffer1, 'DESCRIPTION', nil, wsprintfBuffer, SizeOf(wsprintfBuffer), TR4W_COMM_HELP_FILENAME);
  Windows.SetDlgItemText(settingswindowhandle, 105, wsprintfBuffer);
  GetPrivateProfileString(TempBuffer1, 'DEFAULT', nil, wsprintfBuffer, SizeOf(wsprintfBuffer), TR4W_COMM_HELP_FILENAME);
  Windows.SetDlgItemText(settingswindowhandle, 104, wsprintfBuffer);

end;

procedure SendParameterToNetwork();
var
  Row                                   : integer;
begin
  if NetSocket = 0 then Exit;
  Row := ListView_GetNextItem(SettingshLV, -1, LVNI_SELECTED);
  if CommandsFilter <> cfCol then
    if CFGCA[IndexArray[Row + 1]].crJ = 2 then Exit;

  Windows.ZeroMemory(@ParameterToNetwork.pnCommand, SizeOf(ParameterToNetwork.pnCommand) + SizeOf(ParameterToNetwork.pnValue));
{(*}
  ParameterToNetwork.pnCommand[0] := Char(ListView_GetItemText(SettingshLV, Row, COMMAND_FIELD, @ParameterToNetwork.pnCommand[1], SizeOf(ParameterToNetwork.pnCommand)));
  ParameterToNetwork.pnValue[0]   := Char(ListView_GetItemText(SettingshLV, Row, VALUE_FIELD,   @ParameterToNetwork.pnValue[1],   SizeOf(ParameterToNetwork.pnValue)));
{*)}
  SendToNet(ParameterToNetwork, SizeOf(ParameterToNetwork));
end;

end.

