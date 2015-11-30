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
unit uTelnet;
{$IMPORTEDDATA OFF}

interface

uses
  uCTYDAT,
  uGradient,
  PostUnit,
//  uTrayBalloon,
  VC,
  TF,
  utils_net,
  utils_text,
  utils_file,
  uCallSignRoutines,
  LogK1EA,
  uCallsigns,
  LogStuff,
  //Country9,
  LogRadio,
  uSpots,
  Windows,
  LogEdit,
  LogDupe,
  LogWind,
  WinSock2,
//  uSpotsFilter,
//  uDXSSpotsFilter,
  Tree,
  LogPack,
  uCommctrl,
  Messages
  ;

//type  ClusterType = (ctDXSpider, ctARCluster);
type
  TelnetStringType = (tstTR4W, tstSend, tstReceived, tstReceivedDupe, tstReceivedMult, tstError, tstAlert);

type
  TTBButton = packed record
    iBitmap: integer;
    idCommand: integer;
    fsState: Byte;
    fsStyle: Byte;
    bReserved: array[1..2] of Byte;
    dwData: LONGINT;
    iString: integer;
  end;

procedure SendClientStatus;
function TelnetWndDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure ConnectToTelnetCluster;
procedure Disconnect;

procedure TelnetConnectionError;
function SendViaTelnetSocket(p: PChar): integer;
procedure AddStringToTelnetConsole(p: PChar; c: TelnetStringType);
procedure SaveTelnetWindowSpots;
procedure EnableTelnetToolbatButtons(b: boolean);
procedure ProcessTelnetString(const ByteReceived: integer);
function ProcessDX(DX: integer; InListBox: boolean; var Stringtype: TelnetStringType): boolean;
procedure tCreateAndAddNewSpot(Call: CallString; Dupe: boolean; Radio: RadioPtr);
procedure CheckClusterType(ByteReceived: integer);
procedure AppendTelnetPopupMenu(MenuText: PChar);
procedure EmunTRCLUSTERDAT(FileString: PShortString);
procedure EmunDXCLUSTERALERTLISTTXT(FileString: PShortString);
procedure EnumCLUSTERCOMMANDSTXT(FileString: PShortString);

const
  MAXITEMSINTELNETPOPUPMENU             = 70;
  TELNETBUTTONS                         = 6{$IF LANG = 'RUS'} + 1{$IFEND};

var
  ItemsInTelnetPopupMenu                : integer;
  ClientStatus                          : TClientStatus = (csID: NET_CLIENTSTATUS_ID);
//  ClusterTypeDetermined            : boolean;

//  tClusterType                          : ClusterType = ctDXSpider;

  TelnetServer                          : Str50;  //n4af 04-11-2013
  TempSpot                              : TSpotRecord;

  tbButtons                             : array[0..TELNETBUTTONS - 1] of TTBButton = (
    (iBitmap: VIEW_NETCONNECT;
    idCommand: 200;
    fsState: TBSTATE_ENABLED;
    fsStyle: TBSTYLE_BUTTON or TBSTYLE_AUTOSIZE;
    dwData: 0;
    iString: 0;
    ),
    (iBitmap: VIEW_NETDISCONNECT;
    idCommand: 201;
    fsState: TBSTATE_ENABLED;
    fsStyle: TBSTYLE_BUTTON or TBSTYLE_AUTOSIZE;
    dwData: 0;
    iString: 1;
    ),
    (iBitmap: VIEW_SORTTYPE;
    idCommand: 203;
    fsState: TBSTATE_ENABLED;
    fsStyle: TBSTYLE_CHECK or TBSTYLE_AUTOSIZE;
    dwData: 0;
    iString: 3;
    ),
    //CLEAR
    (iBitmap: VIEW_NEWFOLDER;
    idCommand: 204;
    fsState: TBSTATE_ENABLED;
    fsStyle: TBSTYLE_BUTTON or TBSTYLE_AUTOSIZE;
    dwData: 0;
    iString: 4;
    ),
    //COMMANDS
    (iBitmap: VIEW_DETAILS;
    idCommand: 202;
    fsState: TBSTATE_ENABLED;
    fsStyle: TBSTYLE_BUTTON or TBSTYLE_AUTOSIZE;
    dwData: 0;
    iString: 2;
    ),
{
    (iBitmap: VIEW_PARENTFOLDER;
    idCommand: 205;
    fsState: TBSTATE_ENABLED;
    fsStyle: TBSTYLE_BUTTON or TBSTYLE_AUTOSIZE;
    dwData: 0;
    iString: 5;
    ),
 }

     //SH/FDX 100
    (iBitmap: VIEW_PARENTFOLDER;
    idCommand: 206;
    fsState: TBSTATE_ENABLED;
    fsStyle: TBSTYLE_BUTTON or TBSTYLE_AUTOSIZE;
    dwData: 0;
    iString: 5;
    )
{$IF LANG = 'RUS'}
    ,
    (iBitmap: - 1; //VIEW_SORTNAME;
    idCommand: 207;
    fsState: TBSTATE_ENABLED;
    fsStyle: TBSTYLE_BUTTON or TBSTYLE_AUTOSIZE;
    dwData: 0;
    iString: 6;
    )

{$IFEND}
{
    (iBitmap: VIEW_PARENTFOLDER;
    idCommand: 207;
    fsState: TBSTATE_ENABLED;
    fsStyle: TBSTYLE_BUTTON or TBSTYLE_AUTOSIZE;
    dwData: 0;
    iString: 7;
    ),
}

     //FILTER
{
    (iBitmap: VIEW_SORTSIZE;
    idCommand: 208;
    fsState: TBSTATE_ENABLED;
    fsStyle: TBSTYLE_BUTTON or TBSTYLE_AUTOSIZE;
    dwData: 0;
    iString: 6;
    )
}
    );

const
  SOCK_IDLE                             = 0;
  SOCK_CLIENT                           = 3;
  DXSpotLength                          = 76;

var
  FirstChar                             : integer;
//  NextFirstChar                         : integer;
  OldTelnetFreezeMode                   : boolean;
  TelnetFreezeMode                      : boolean;
  TelThreadID                           : Cardinal;
  TelnetSock                            : Cardinal;
  TelToolbar                            : HWND;
  TelnetListBox                         : HWND;
  TelnetCommandWindow                   : HWND;
  TelnetListBoxOldProc                  : Pointer;

  TelPopMemu                            : HMENU;
  TelLastPopMemu                        : HMENU;

  telnet_callsign_alert_list_loaded     : boolean;
  TelnetCallsignAlertList               : HWND;
implementation
uses uNet,
  uBandmap,
  MainUnit;

function TelnetWndDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1, DrawSpot;
var

  temprect                              : TRect;
  TempFile                              : Text;
  i                                     : integer;
  TempTextColor                         : Cardinal;
  TempPoint                             : TPoint;
  TDIS                                  : PDrawItemStruct;
  InfoBuffer                            : array[0..127] of Char;
  StringType                            : TelnetStringType;
const
  TelnetStringColor                     : array[TelnetStringType] of tr4wColors = (trGreen, trBlue, trBlack, trLightGray, trRed, trRed, trBlack);
//  TelnetStringOffset                    : array[TelnetStringType] of integer = (15, 2, 15, 15, 15, 20, 15);
begin
  Result := False;
  case Msg of

    WM_MEASUREITEM:
      begin
        PMeasureItemStruct(lParam).itemHeight := 13;
      end;

    WM_DRAWITEM:

      begin
        TDIS := Pointer(lParam);
{
        if (TDIS^.itemAction = ODA_FOCUS) then
        begin
//          DrawFocusRect(MDIS^.HDC, MDIS^.rcItem);
//GradientRect(TDIS^.HDC, TDIS^.rcItem, tr4wColorsArray[trYellow], tr4wColorsArray[trWhite], gdHorizontal);
//          Exit;
        end;
}
        if TDIS^.itemAction = ODA_DRAWENTIRE then
        begin
          i := SendMessage(TDIS^.hwndItem, LB_GETTEXT, TDIS^.ItemID, integer(@InfoBuffer));

          StringType := TelnetStringType(SendMessage(TDIS^.hwndItem, LB_GETITEMDATA, TDIS^.ItemID, 0));

          if StringType = tstAlert then
            GradientRect(TDIS^.HDC, TDIS^.rcItem, tr4wColorsArray[trYellow], tr4wColorsArray[trYellow], gdHorizontal);

          Windows.SetTextColor(TDIS^.HDC, tr4wColorsArray[TelnetStringColor[StringType]]);
          SetBkMode(TDIS^.HDC, TRANSPARENT);
          Windows.TextOut(TDIS^.HDC, TDIS^.rcItem.Left + 5 {TelnetStringOffset[StringType]}, TDIS^.rcItem.Top, InfoBuffer, i);
          Result := True;
        end;
      end;

    WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);

    WM_SOCK:
      begin

        i := recv(TelnetSock, TelnetBuffer, SizeOf(TelnetBuffer) - 1, 0);
        if i < 1 then
          if WindowsOSversion = VER_PLATFORM_WIN32_NT then
          begin
            TelnetConnectionError;
            Disconnect;
            Exit;
          end;

//          showmessage(@TelnetBuffer);
{
        if i > 50 then
          if TelnetBuffer[i - 1] <> #10 then
          begin
            NextFirstChar := NextFirstChar + i;
            if NextFirstChar < 10000 then Exit;
          end;
}
        TelnetBuffer[i] := #0;
        ProcessTelnetString(i);

      end;

    WM_INITDIALOG:
      begin

        CreateComboBox(hwnddlg, 102);
        CreateComboBox(hwnddlg, 106);
        CreateButton(BS_DEFPUSHBUTTON or BS_CENTER or WS_DISABLED, RC_SEND, 0, 0, 60, hwnddlg, 104);
        CreateOwnerDrawListBox(LBS_NOTIFY or LBS_OWNERDRAWFIXED or LBS_HASSTRINGS or LBS_NOINTEGRALHEIGHT or WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_HSCROLL or WS_TABSTOP, hwnddlg);
//

        tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle := hwnddlg;
        telnet_callsign_alert_list_loaded := False;
        ItemsInTelnetPopupMenu := 0;

        EnumerateLinesInFile('DXCLUSTER_ALERT_LIST.TXT', EmunDXCLUSTERALERTLISTTXT, True);
{
        if OpenFileForRead(TempFile, TR4W_PATH_NAME + 'DXCLUSTER_ALERT_LIST.TXT') then
        begin
          while not Eof(TempFile) do
          begin
            Windows.ZeroMemory(@wsprintfBuffer, SizeOf(wsprintfBuffer));
            ReadLn(TempFile, wsprintfBuffer);
            if StrLen(wsprintfBuffer) > 2 then
            begin
              Windows.CharUpper(wsprintfBuffer);
              if telnet_callsign_alert_list_loaded = False then
                TelnetCallsignAlertList := CreateWindow(LISTBOX, nil, $50210003, 0, 0, 0, 0, hwnddlg, 0, hInstance, nil);

              tLB_ADDSTRING(TelnetCallsignAlertList, wsprintfBuffer);
              telnet_callsign_alert_list_loaded := True;
            end;
          end;
          Close(TempFile);
        end;
}
        EnumerateLinesInFile('TRCLUSTER.DAT', EmunTRCLUSTERDAT, False);

         i := SendDlgItemMessage(hwnddlg, 102, CB_FINDSTRING, -1, integer(@TelnetServer[1]));    //n4af 4.35.1
   //     i := SendDlgItemMessage(hwnddlg, 102, CB_FINDSTRINGEXACT, -1,integer(@TelnetServer[1]));
        if i <> CB_ERR then tCB_SETCURSEL(hwnddlg, 102, i);

        TelToolbar := uCommctrl.CreateToolBarEx(hwnddlg,
          WS_CHILD or
          WS_VISIBLE or
          TBSTYLE_TOOLTIPS or
          TBSTYLE_LIST or
          TBSTYLE_TRANSPARENT or
          TBSTYLE_AUTOSIZE or
          TBSTYLE_FLAT,
          0, 13, HINST_COMMCTRL, IDB_VIEW_SMALL_COLOR, @tbButtons,
          TELNETBUTTONS, 0, 0, 0, 0, SizeOf(TTBButton));

        SendMessage(TelToolbar, TB_ADDSTRING, 0, integer(PChar(TC_TELNET{$IF LANG = 'RUS'} + '?'#0#0{$IFEND})));
        EnableTelnetToolbatButtons(False);

        TelnetListBox := Get101Window(hwnddlg);
        asm
            mov edx,[LucidaConsoleFont]
            call tWM_SETFONT
        end;

        TelnetCommandWindow := GetDlgItem(hwnddlg, 106);

        //        TelnetListBoxOldProc := Pointer(Windows.SetWindowLong(TelnetListBox, GWL_WNDPROC, integer(@TelnetListBoxNewProc)));
                //        SendMessage(hwnddlg, WM_SETICON, ICON_SMALL, DisconnectedIcon);
        //            SendMessage(TelnetConnectionStatus, STM_SETICON, 0, 0);

        if tConnectionAtStartup then SendMessage(hwnddlg, WM_COMMAND, 200, 0);

        TelPopMemu := CreatePopupMenu;
        TelLastPopMemu := TelPopMemu;
        AppendTelnetPopupMenu('HELP');
        AppendTelnetPopupMenu('SHOW/USERS');
        AppendTelnetPopupMenu('SHOW/WWV');
        AppendTelnetPopupMenu('SHOW/FILTER');
        AppendTelnetPopupMenu('SHOW/DX/100');

        EnumerateLinesInFile('CLUSTER_COMMANDS.TXT', EnumCLUSTERCOMMANDSTXT, True);
{
        if OpenFileForRead(TempFile, TR4W_PATH_NAME + 'CLUSTER_COMMANDS.TXT') then
        begin
//          TempBkGrColor := 1002;
          while not Eof(TempFile) do
          begin
            Windows.ZeroMemory(@wsprintfBuffer, SizeOf(wsprintfBuffer));
            ReadLn(TempFile, wsprintfBuffer);
            if wsprintfBuffer[0] = ';' then Continue;
            Windows.CharUpper(wsprintfBuffer);
            AppendTelnetPopupMenu(wsprintfBuffer);
          end;
          Close(TempFile);
        end;
}
//tLB_ADDSTRING(TelnetListBox,'DX DE SM6WET:    28025.0  G0ORH        SRI, THIS IS CORRECT           0953Z JO68  ');
//tLB_ADDSTRING(TelnetListBox,'DX DE G4MJS:     14180.0  2DONCG       YOUR TURN TO MAKE A BREW       0953Z JO01  ');
//tLB_ADDSTRING(TelnetListBox,'DX DE LU6FL:      1845.0  LU6FL        CQ CQ TEST SSB                 0953Z FF97  ');
//tLB_ADDSTRING(TelnetListBox,'DX DE RZ3DSD:    14258.9  RA3RGQ/1                                    0953Z  ');
//tLB_ADDSTRING(TelnetListBox,'DX DE F5PPO:     18135.0  CQ9U                                        0953Z  ');
//tLB_ADDSTRING(TelnetListBox,'DX DE PA3C:      24897.2  LZ1PJ                                       0954Z JO33  ');

      end;
    //    WM_HELP: tWinHelp(7);

//    WM_MENUSELECT:      if lParam = 0 then        DestroyMenu(TelPopMemu);

  //     if HiWord(wParam) = MF_CHECKED then     //n4af
    //    GetMenuString(TelPopMemu, 1000, wsprintfBuffer, 100, MF_BYCOMMAND);      

    WM_COMMAND:
      begin
        if HiWord(wParam) = LBN_SELCHANGE then DlgDirSelectEx(hwnddlg, wsprintfBuffer, SizeOf(wsprintfBuffer), 101);     //n4af

        if HiWord(wParam) = LBN_DBLCLK then
        begin
      //      DlgDirSelectEx(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, wsprintfBuffer, SizeOf(wsprintfBuffer), 101);  //n4af
      //    DlgDirList(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, wsprintfBuffer, 101, 106, DDL_ARCHIVE or DDL_DIRECTORY);       //n4af
      //   ShowMessage(SysErrorMessage(GetLastError));
          i := SendMessage(TelnetListBox, LB_GETCURSEL, 0, 0);
          if i = LB_ERR then Exit;
          SendMessage(TelnetListBox, LB_GETTEXT, i, integer(@TelnetBuffer[0]));
          if PInteger(@TelnetBuffer[0])^ = $64205844 {DX D} then
            if ProcessDX(0, True, StringType) then
              TuneRadioToSpot(TempSpot, RadioOne);
              
                  {
                        if FoundDXSpot(ListBox_GetSelectedItem(TelnetListBox), TelnetDXspot) then
                          begin
                            BigCompressFormat(TelnetDXspot.Call, CompressedCall);
                            BandMapEntryRecord.Call := CompressedCall;
                            BandMapEntryRecord.Frequency := TelnetDXspot.Frequency;
                            BandMapEntryRecord.QSXOffset := TelnetDXspot.QSXFrequency;
                            SetUpBandMapEntry(@BandMapEntryRecord, ActiveRadio);
                          end;
                }
        end;

        if (wParam >= 1000) then if
          (wParam <= 1000 + MAXITEMSINTELNETPOPUPMENU) then
          begin
            GetMenuString(TelPopMemu, wParam, wsprintfBuffer, 200, MF_BYCOMMAND);    //n4af
            SendViaTelnetSocket(wsprintfBuffer);
          end;

        case wParam of
          201: Disconnect;

          202:
            begin
              GetCursorPos(TempPoint);
              TrackPopupMenu(TelPopMemu, TPM_TOPALIGN, TempPoint.X, TempPoint.Y + 10, 0, hwnddlg, nil);
            end;

          203: InvertBoolean(TelnetFreezeMode);
          //            PostMessage(hwnddlg, WM_SYSCOMMAND, SC_MOVE, 0);
          204: SendDlgItemMessage(hwnddlg, 101, LB_RESETCONTENT, 0, 0);

          //            ScrollWindowEx(TelnetListBox, 0, -50, 0, 0, 0, 0, SW_SMOOTHSCROLL);
//          205: SendViaSocket('SH/USERS');
          206: SendViaTelnetSocket('SH/DX 50'); //n4af 04-11-2014

{$IF LANG = 'RUS'}
          207: ShowHelp('ru_dxcluster');
{$IFEND}
{
          208:
            begin
              if tClusterType = ctARCluster then tDialogBox(44, @ARSpotsFilterDlgProc);
              if tClusterType = ctDXSpider then tDialogBox(65, @DXSSpotsFilterDlgProc);
            end;
 
 }
          //          DialogBox(hInstance, MAKEINTRESOURCE(44), hwnddlg, @SpotsFilterDlgProc);
          200: if TelThreadID = 0 then
            begin
              tCreateThread(@ConnectToTelnetCluster, TelThreadID);
//              ConnectToTelnetCluster;
            end;

          104:
            begin
              SendMessage(TelnetCommandWindow, CB_SHOWDROPDOWN, 0, 0);
              Windows.GetWindowText(TelnetCommandWindow, TempBuffer1, SizeOf(TempBuffer1));
              if TempBuffer1[0] = #0 then Exit;
              SendViaTelnetSocket(TempBuffer1);
              Windows.SetWindowText(TelnetCommandWindow, nil);
              if
               SendMessage(TelnetCommandWindow, CB_FINDSTRING, -1, integer(PChar(@TempBuffer1))) = CB_ERR then
              //  SendMessage(TelnetCommandWindow, CB_FINDSTRINGEXACT, -1, integer(PChar(@TempBuffer1))) = CB_ERR then
                tCB_ADDSTRING_PCHAR(hwnddlg, 106, TempBuffer1);

            end;
        end;
        {
                if HiWord(wParam) = LBN_KILLFOCUS then TelnetFreezeMode := OldTelnetFreezeMode;

                if HiWord(wParam) = LBN_SETFOCUS then
                  begin
                    OldTelnetFreezeMode := TelnetFreezeMode;
                    TelnetFreezeMode := True;
                  end;
        }
      end;

    //    WM_NCHITTEST:      if TelnetHint <> 0 then PostMessage(TelnetHint, WM_CLOSE, 0, 0);

    WM_LBUTTONDOWN: DragWindow(hwnddlg);

    WM_CLOSE: 1:
      begin
        CloseTR4WWindow(tw_TELNETWINDOW_INDEX);
      end;

    WM_DESTROY:
      begin
        Disconnect;
        TelnetCommandWindow := 0;
        TelnetListBox := 0;
        SaveTelnetWindowSpots;
        DestroyMenu(TelPopMemu);
      end;
    {
        WM_NCLBUTTONDBLCLK:
          begin
            if IsIconic(hwnddlg) = False then
              PostMessage(hwnddlg, WM_SYSCOMMAND, SC_MINIMIZE, 10000);
          end;
    }
    WM_SIZE:
      begin

        Windows.GetClientRect(hwnddlg, temprect);
        TempTextColor := temprect.Top + 28;

        Windows.SetWindowPos(Windows.GetDlgItem(hwnddlg, 102), HWND_TOP, 0, TempTextColor, 160, 300, SWP_SHOWWINDOW);

        Windows.SetWindowPos(Windows.GetDlgItem(hwnddlg, 106), HWND_TOP, 165, TempTextColor, temprect.Right - temprect.Left - 210 - 25, 300, SWP_SHOWWINDOW);
        Windows.SetWindowPos(Windows.GetDlgItem(hwnddlg, 104), HWND_TOP, temprect.Right - temprect.Left - 40 - 25, TempTextColor, 0, 0, SWP_NOSIZE or SWP_SHOWWINDOW);

        Windows.SetWindowPos(TelnetListBox, HWND_TOP, 0, 27 + 25, temprect.Right - temprect.Left, temprect.Bottom - temprect.Top - 55, {SWP_NOSIZE or } SWP_SHOWWINDOW);
        MoveWindow(TelToolbar, 0, 0, LoWord(lParam), 0, True);
        SendMessage(TelnetListBox, WM_VSCROLL, SB_BOTTOM, 0);

      end;

  end;
end;

procedure ConnectToTelnetCluster;
var
  TempHostent                           : Phostent;
  StackTelHandle                        : HWND;
  p                                     : PChar;
  port                                  : Word;
  i                                     : integer;
  TempBuffer                            : array[0..127] of Char;
label
  processed;
begin
  StackTelHandle := tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle;

  port := 23;
  i := Windows.GetDlgItemText(StackTelHandle, 102, TempBuffer1, SizeOf(TempBuffer1));

  while i <> 0 do
  begin
    if TempBuffer1[i] = ':' then
      begin
      port := pchartoint(@TempBuffer1[i + 1]);
      TempBuffer1[i] := #0;
      end;
    if TempBuffer1[i] = ' ' then    // ny4i
      begin                              // ny4i
      TempBuffer1[i] := #0;              // ny4i
      end;                               // ny4i

    dec(i);
  end;

  if not GetConnection(TelnetSock, TempBuffer1, port, SOCK_STREAM) then

  begin
    TelnetConnectionError;
    TelThreadID := 0;
    Disconnect;
    Exit;
  end;

  AddStringToTelnetConsole(TC_CONNECTED, tstTR4W);

  if WSAAsyncSelect(TelnetSock, StackTelHandle, WM_SOCK, FD_READ or FD_CLOSE) <> 0 then
  begin
    TelnetConnectionError;
    Disconnect;
    Exit;
  end;

//  ClusterTypeDetermined := False;
  Windows.ZeroMemory(@TelnetBuffer, SizeOf(TelnetBuffer));
  //  Status := SOCK_CLIENT;

  if ConnectionCommand <> '' then
    SendViaTelnetSocket(@ConnectionCommand[1])
  else
    SetDlgItemText(StackTelHandle, 106, @MyCall[1]);

  SendClientStatus;
  EnableTelnetToolbatButtons(True);
  EnableWindowTrue(StackTelHandle, 104);
//  tEnableMenuItem(menu_ctrl_sendspot, MF_ENABLED);
  processed:

end;

procedure Disconnect;
var
  StackTelHandle                        : HWND;
begin
  StackTelHandle := tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle;
  closesocket(TelnetSock);
  EnableWindowFalse(StackTelHandle, 104);
  EnableWindowTrue(StackTelHandle, 102);
  EnableTelnetToolbatButtons(False);
  TelnetSock := 0;
  TelThreadID := 0;
//  tEnableMenuItem(menu_ctrl_sendspot, MF_BYCOMMAND + MF_GRAYED);
  SendClientStatus;
end;

procedure TelnetConnectionError;
begin
  AddStringToTelnetConsole(SysErrorMessage(WSAGetLastError), tstError);
end;

function SendViaTelnetSocket(p: PChar): integer;
begin
  if TelnetSock = 0 then Exit;
  AddStringToTelnetConsole(p, tstSend);
  WinSock2.Send(TelnetSock, wsprintfBuffer, Format(wsprintfBuffer, '%s'#13#10, p), 0);
  Result := WSAGetLastError;
  if Result <> 0 then TelnetConnectionError;
end;

procedure AddStringToTelnetConsole(p: PChar; c: TelnetStringType);
var
  Handle                                : HWND;
begin
  Handle := TelnetListBox;

  SendMessage(Handle, LB_SETITEMDATA, SendMessage(Handle, LB_ADDSTRING, 0, integer(p)), integer(c));

  if TelnetFreezeMode then Exit;
  SendMessage(Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure SaveTelnetWindowSpots;
var

  i, Lines                              : integer;
  LineLength                            : longword;
  TimeString                            : PChar;
  TelnetLogHandle                       : HWND;
begin
  if not tWindowsExist(tw_TELNETWINDOW_INDEX) then Exit;
  Lines := SendDlgItemMessage(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, 101, LB_GETCOUNT, 0, 0);
  if Lines < 10 then Exit;
  TimeString := GetTimeString;
  TimeString[2] := '-';
  asm
  push TimeString
  call GetDateString
  push eax
  lea  eax,TR4W_PATH_NAME
  push eax
  end;
  wsprintf(wsprintfBuffer, '%sDXCluster\dxcluster %s %s.txt');
  asm add esp,20
  end;

  TelnetLogHandle := CreateFile(wsprintfBuffer, GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_NEW, FILE_ATTRIBUTE_ARCHIVE, 0);

  if TelnetLogHandle <> INVALID_HANDLE_VALUE then
  begin
    for i := 0 to Lines - 1 do
    begin
      LineLength := SendDlgItemMessage(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, 101, LB_GETTEXT, i, lParam(@wsprintfBuffer));
      wsprintfBuffer[LineLength + 0] := #13;
      wsprintfBuffer[LineLength + 1] := #10;
      sWriteFile(TelnetLogHandle, wsprintfBuffer, LineLength + 2);
    end;
    CloseHandle(TelnetLogHandle);
  end;

end;

procedure EnableTelnetToolbatButtons(b: boolean);

  procedure SetToolButSt(Control: Byte);
  var
    State                               : boolean;
  begin
    State := b;
    if Control = 200 then InvertBoolean(State);
    SendMessage(TelToolbar, TB_ENABLEBUTTON, integer(Control), integer(State));
  end;
begin

  SetToolButSt(200);
  SetToolButSt(201);
  SetToolButSt(202);
//  SetToolButSt(205);
 // SetToolButSt(206);
//  SetToolButSt(207);
//  SetToolButSt(208);
end;

procedure ProcessTelnetString(const ByteReceived: integer);
label
  Start;
var
 BandMapEntryRecord, EntryToBeDisposed, PreviousBandMapEntryRecord: BandMapEntryPointer;
  c                                     : integer;
  AddedSpot                             : boolean;
  pr                                    : integer;
  StringType                            : TelnetStringType;
begin
//  Windows.CharUpperBuff(TelnetBuffer, ByteReceived);
  AddedSpot := False;
  pr := -1;
  for c := 0 to ByteReceived do
  begin
    if pr = -1 then
      if TelnetBuffer[c] > #13 then pr := c;

    if pr <> -1 then
      if TelnetBuffer[c] <= #13 then
      begin
        TelnetBuffer[c] := #0;
        StringType := tstReceived;
        if (PInteger(@TelnetBuffer[pr])^ = $64205844) {DX D} and (PInteger(@TelnetBuffer[pr + 2])^ = $20656420) { DE } then
          AddedSpot := ProcessDX(pr, False, StringType);

        AddStringToTelnetConsole(@TelnetBuffer[pr], StringType);
    //     SetUpBandMapEntry(@BandMapEntryRecord, ActiveRadio);   // remove hh
        pr := -1;
      end;
  end;

  if AddedSpot then SpotsList.Display;
{
  Exit;

  FirstChar := 0;
  c := 0;
  AddedSpot := False;

  CheckClusterType(ByteReceived);

  Start:

  if (PInteger(@TelnetBuffer[c])^ = 1142970436) and (PInteger(@TelnetBuffer[c + 2])^ = 541410336) then
  begin
    if (ByteReceived - c) > DXSpotLength then AddedSpot := ProcessDX(c, False);
    c := c + 74;
  end;

  if (TelnetBuffer[c] in [#13]) or (c = ByteReceived - 1) then
  begin
    TelnetBuffer[c] := #0;
//    tLB_ADDSTRING(TelnetListBox, @TelnetBuffer[FirstChar]);
    if TelnetBuffer[FirstChar] <> #0 then
      AddStringToTelnetConsole(@TelnetBuffer[FirstChar], trBlack);
//    if not TelnetFreezeMode then SendMessage(TelnetListBox, WM_VSCROLL, SB_BOTTOM, 0);
    FirstChar := c + 2;
  end;

  inc(c);
  //  Windows.SetWindowText(tr4whandle, inttopchar(c));
  //  Windows.SetWindowText(TotalScoreWindowHandle, inttopchar(ByteReceived));
  if c < ByteReceived then goto Start;
//  NextFirstChar := 0;
  if AddedSpot then SpotsList.Display;
}
end;

function ProcessDX(DX: integer; InListBox: boolean; var Stringtype: TelnetStringType): boolean;
label
  1;
var
  i, i1                                 : integer;
  TempFrequency                         : integer;
  MultString                            : integer;
  f                                     : integer;
  QSXPos                                : integer;
  TempChar                              : Char;
  Hertz                                 : integer;
  DivHertz                              : boolean;
  QSXBand                               : BandType;
  QSXMode                               : ModeType;
  CountryID                             : Word;
  Offset                                : integer;
  ct                                    : Cardinal;
  AMode                                 : pChar;
  Buffer                                : pChar;
begin
  Result := False;
  Stringtype := tstReceived;
  Windows.ZeroMemory(@TempSpot, SizeOf(TSpotRecord));
  TempSpot.FBand := NoBand;
  TempSpot.FMode := NoMode;

//  ShowMessage(@TelnetBuffer[DX + 24]);
  if TelnetBuffer[DX + 24] = '.' then Offset := 2 else Offset := 0;

  {Source Callsign}
  for i := DX + 9 to DX + 20 do
  begin
    if TelnetBuffer[i] = ':' then
    begin
//      if TelnetBuffer[i - 1] = '#' then Offset := 2 else Offset := 0;

      SetLength(TempSpot.FSourceCall, i - DX - 6);
      Windows.lstrcpyn(@TempSpot.FSourceCall[1], @TelnetBuffer[DX + 6], i - DX - 5);
      i1 := i;
      Break;
    end;
  end;

  for i := DX + 10 to DX + 20 do
  begin
    if TelnetBuffer[i] = ' ' then if TelnetBuffer[i + 1] <> ' ' then
      begin
        Windows.lstrcpyn(@TempSpot.FFreqString[0], @TelnetBuffer[i + 1], DX + 24 - i + Offset);
{
        TempSpot.FFreqString[0] := '1';
        TempSpot.FFreqString[1] := '1';
        TempSpot.FFreqString[2] := '1';
        TempSpot.FFreqString[3] := '1';
        TempSpot.FFreqString[4] := '1';
        TempSpot.FFreqString[5] := '1';
        TempSpot.FFreqString[6] := '1';
        TempSpot.FFreqString[7] := '1';
        TempSpot.FFreqString[8] := '1';
        TempSpot.FFreqString[9] := '1';
        TempSpot.FFreqString[10] := '.';
        TempSpot.FFreqString[11] := '1';
}
        TempFrequency := 0;

        for f := 0 to 12 do
        begin
          if TempFrequency > 2100000 { $ 7FFFFFF} then Exit;

          if TempSpot.FFreqString[f] = '.' then
          begin
//            try

// 0010368100 - 009E3464
// 1778165408 - 69FCA6A0
// 2147483647   7FFFFFFF
//            TempFrequency := 10368970*1000;
            TempFrequency :=
              (
              TempFrequency * 10 +
              (Ord(TempSpot.FFreqString[f + 1]) - 48)
              ) * 100;
//            if TempFrequency < 10000000 then TempFrequency := TempFrequency * 100;
//            except
//              asm
//            nop
//              end;
//          end;
//103 681 190 00
            if (TempFrequency > 1300000000) or (TempFrequency < 0) then

              Exit;
            TempSpot.FFrequency := TempFrequency;
            Break;
          end;
          if TempSpot.FFreqString[f] = #0 then Break;
          if TempSpot.FFreqString[f] in ['0'..'9'] then
            TempFrequency := TempFrequency * 10 + (Ord(TempSpot.FFreqString[f]) - 48);
        end;

      end;
  end;

  //1

  {DX}

//  DXCallStart := 25;

  for i := DX + 27 to DX + 39 do
  begin
    if TelnetBuffer[i] <> ' ' then
      if TelnetBuffer[i + 1] = ' ' then
      begin
        SetLength(TempSpot.FCall, i - (DX + 25 + Offset));
        Windows.lstrcpyn(@TempSpot.FCall[1], @TelnetBuffer[DX + 26 + Offset], i - (DX + 24 + Offset));
        if not GoodCallSyntax(TempSpot.FCall) then Exit;
        Break;
      end;
  end;

  {Note}
  if TelnetBuffer[DX + 39 + Offset] <> ' ' then
  begin
    Windows.lstrcpyn(@TempSpot.FNotes[0], @TelnetBuffer[DX + 39 + Offset], 30);
    StrUpper(@TelnetBuffer[DX + 39 + Offset]);
    for i := DX + 39 to DX + 65 do
    begin
          //        i1:=
      i1 := PInteger(@TelnetBuffer[i])^;
{
      asm
          mov eax,i1
          bswap eax
          cmp eax,'BIG '
          jz @@loud
          cmp eax,'5/9 '
          jz @@loud
          cmp eax,'LOUD'
          jz @@loud
          cmp eax,'59++'
          jz @@loud
          cmp eax,'599+'
          jz @@loud
          cmp eax,'59+ '
          jz @@loud
          cmp eax,' 59 '
          jz @@loud
          cmp eax,'5-9 '
          jz @@loud
          cmp eax,'59PL'
          jz @@loud
          cmp eax,'5/9+'
          jz @@loud
          cmp eax,'599 '
          jz @@loud
          cmp eax,'STRO'
          jz @@loud
          cmp eax,'NICE'
          jz @@loud
          cmp eax,'STRN'
          jz @@loud
          cmp eax,'GOOD'
          jz @@loud
          cmp eax,'EASY'
          jz @@loud

          jmp @@notloud
          @@loud:
          mov TempSpot.FLoudSignal,1
          @@notloud:
      end;
}

      if PInteger(@TelnetBuffer[i])^ = 542659409 {QSX } then
      begin
        if TelnetBuffer[i + 4] in ['0'..'9'] then
        begin

          Hertz := 1000;
          DivHertz := False;

          for QSXPos := 4 to 12 do
          begin
            TempChar := TelnetBuffer[i + QSXPos];
            case TempChar of
              ' ': Break;
              '0'..'9':
                begin
                  TempSpot.FQSXFrequency := TempSpot.FQSXFrequency * 10 + (Ord(TempChar) - 48);
                  if DivHertz then Hertz := Hertz div 10;
                end;
              '.': DivHertz := True;
            end;
          end;

          TempSpot.FQSXFrequency := TempSpot.FQSXFrequency * Hertz;
          if TempSpot.FQSXFrequency < 10000 then TempSpot.FQSXFrequency := TempSpot.FFrequency + TempSpot.FQSXFrequency;
          QSXBand := NoBand;
          CalculateBandMode(TempSpot.FQSXFrequency, QSXBand, QSXMode);
          if QSXBand = NoBand then TempSpot.FQSXFrequency := 0;
        end;

      end;

      if PInteger(@TelnetBuffer[i])^ = $20315055 {UP1 } then TempSpot.FQSXFrequency := TempSpot.FFrequency + 1000;
      if PInteger(@TelnetBuffer[i])^ = $20325055 {UP2 } then TempSpot.FQSXFrequency := TempSpot.FFrequency + 2000;
      if PInteger(@TelnetBuffer[i])^ = $20335055 {UP3 } then TempSpot.FQSXFrequency := TempSpot.FFrequency + 3000;
      if PInteger(@TelnetBuffer[i])^ = $20345055 {UP4 } then TempSpot.FQSXFrequency := TempSpot.FFrequency + 4000;
      if PInteger(@TelnetBuffer[i])^ = $20355055 {UP5 } then TempSpot.FQSXFrequency := TempSpot.FFrequency + 5000;
    end;
  end;

  if InListBox then goto 1;
  //1

  GetBandMapBandModeFromFrequency(TempSpot.FFrequency, TempSpot.FBand, TempSpot.FMode);

//  if TempSpot.FBand = Band20 then    TempSpot.FQSXFrequency := TempSpot.FFrequency + 1000;

  TempSpot.FDupe := //CallsignsList.CallsignIsDupe(TempSpot.FCall, TempSpot.FBand, TempSpot.FMode, I1);
    VisibleLog.CallIsADupe(TempSpot.FCall, TempSpot.FBand, TempSpot.FMode);
    {
     Buffer := TelnetBuffer;
    if StrPos(Buffer,'CW') = Nil then exit;
    if StrPos(Buffer,'BEACON') <> Nil then exit;
    if StrPos(Buffer,'NCDXF') <> Nil then exit;
  } 
  if TempSpot.FDupe then Stringtype := tstReceivedDupe;

  if not TempSpot.FDupe then
  begin
    TempSpot.FMult := VisibleLog.DetermineIfNewMult(TempSpot.FCall, TempSpot.FBand, TempSpot.FMode);
//    TempSpot.FMult := MultString <> 0;
    if TempSpot.FMult then Stringtype := tstReceivedMult;

  end;

//  Windows.GetSystemTime(TempSpot.FSysTime);
  ct := UTC.wMinute + UTC.wHour * 60 + UTC.wDay * 60 * 24 + UTC.wMonth * 60 * 24 * 30;
  if (TelnetBuffer[DX + 74] = 'Z') then
  begin
    TempSpot.FSysTime := ((Ord(TelnetBuffer[DX + 70]) - $30) * 10 + Ord(TelnetBuffer[DX + 71]) - $30) * 60 +
      ((Ord(TelnetBuffer[DX + 72]) - $30) * 10 + Ord(TelnetBuffer[DX + 73]) - $30) + UTC.wDay * 60 * 24 + UTC.wMonth * 60 * 24 * 30;
    if ct >= TempSpot.FSysTime then
      TempSpot.FMinutesLeft := ct - TempSpot.FSysTime;

  end
  else
    TempSpot.FSysTime := ct;

  //  TempSpot.FSysTime.wHour := (Ord(TelnetBuffer[DX + 70]) - $30) * 10 + Ord(TelnetBuffer[DX + 71]) - $30;
  //  TempSpot.FSysTime.wMinute := (Ord(TelnetBuffer[DX + 72]) - $30) * 10 + Ord(TelnetBuffer[DX + 73]) - $30;
  if TempSpot.FCall = MyCall then
  begin
    Stringtype := tstAlert;
    QuickDisplay(TC_YOUARESPOTTEDBYANOTHERSTATION);
    QuickBeep;
  end;
  SpotsList.AddSpot(TempSpot, True);

  if telnet_callsign_alert_list_loaded then
    if Windows.SendMessage(TelnetCallsignAlertList, LB_FINDSTRINGEXACT, -1, integer(PChar(@TempSpot.FCall[1]))) <> LB_ERR then
    begin
      Stringtype := tstAlert;

      Format(QuickDisplayBuffer, 'New DX Cluster spot: %s was spoted by %s on %s', @TempSpot.FCall[1], @TempSpot.FSourceCall[1], TempSpot.FFreqString);
      QuickDisplay(QuickDisplayBuffer);
{
      QuickDisplay(PChar(
        'New DX Cluster spot: ' +
        TempSpot.FCall +
        ' was spoted by ' +
        TempSpot.FSourceCall +
        ' on ' + string(TempSpot.FFreqString)));
}
      Tree.QuickBeep;
    end;

  {
    TelnetBuffer[DX + 4] := ' ';
    if TempSpot.FMult then
      begin
        TelnetBuffer[DX + 0] := 'M';
        TelnetBuffer[DX + 1] := 'U';
        TelnetBuffer[DX + 2] := 'L';
        TelnetBuffer[DX + 3] := 'T';
      end
    else
      if TempSpot.FDupe then
        begin
          TelnetBuffer[DX + 0] := ' ';
          TelnetBuffer[DX + 1] := '-';
          TelnetBuffer[DX + 2] := 'D';
          TelnetBuffer[DX + 3] := '-';
        end
      else
        begin
          TelnetBuffer[DX + 0] := ' ';
          TelnetBuffer[DX + 1] := ' ';
          TelnetBuffer[DX + 2] := ' ';
          TelnetBuffer[DX + 3] := ' ';
        end;
  }
  1:
  Result := True;
end;

{
function TelnetListBoxNewProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT; STDCALL;
begin

  if Msg = WM_KEYUP then

    if wParam = VK_RETURN then
      begin
        sm;
        Exit;
      end;
  Result := CallWindowProc(TelnetListBoxOldProc, hwnddlg, Msg, wParam, lParam);

end;
}
{
procedure ShowSpots;
var
  i                                     : integer;
  dc                                    : HDC;
begin
  dc := GetDC(tr4w_WindowsArray[tr4w_TELNETWINDOW_INDEX].tr4w_WndHandle);
  for i := 0 to 20 do
    textout(dc, 10, i * 20 + 50, PChar(SpotsArray[i]), length(SpotsArray[i]));
end;
}

procedure tCreateAndAddNewSpot(Call: CallString; Dupe: boolean; Radio: RadioPtr);
label
  1;
var
  TempFrequency                         : LONGINT;
  MultString                            : integer;
  Mult                                  : boolean;
begin
//  if not BandMapEnable then Exit;
  if StringIsAllNumbers(Call) then Exit;
//  if ActiveRadio = RadioOne then TempFrequency := Radio1.FilteredStatus.Freq;
//  if ActiveRadio = RadioTwo then TempFrequency := Radio2.FilteredStatus.Freq;
  TempFrequency := Radio^.FilteredStatus.Freq;
  if TempFrequency = 0 then
//    if OpMode = SearchAndPounceOpMode then
    if AskForFrequencies then
    begin
      Call[length(Call) + 1] := #0;
      asm
        lea  eax, Call+1
        push eax
      end;
      wsprintf(wsprintfBuffer, TC_FREQUENCYFORCALLINKHZ);
      asm add esp,12
      end;
      TempFrequency := QuickEditFreq(wsprintfBuffer, 10);
    end;
  if TempFrequency <= 0 then Exit;

  Windows.ZeroMemory(@TempSpot, SizeOf(TempSpot));

  if PInteger(@Call[1])^ = tCQAsInteger then
  begin
    Mult := False;
	 TempSpot.FCQ := True;                         //GAV changed from true to false
    goto 1;
  end;

  if PInteger(@Call[1])^ = tNEWAsInteger then
  begin
    Mult := False;
    goto 1;
  end;

  Mult := VisibleLog.DetermineIfNewMult(Call, ActiveBand, ActiveMode);
//  Mult := MultString <> 0;

  1:
  TempSpot.FCall := Call;

  TempSpot.FFrequency := TempFrequency;
  
    if  TempSpot.FCQ then                     //GAV      issue, picking activeband on dupecheck   changed from ActiveBand / mode to BandmapBand / mode  if not CQ
    begin
        TempSpot.FBand := ActiveBand;
        TempSpot.FMode := ActiveMode;
    end
  else
    begin
        TempSpot.FBand := BandmapBand;
        TempSpot.FMode := BandmapMode;
     end;
  
  TempSpot.FQSXFrequency := 0;
  TempSpot.FDupe := Dupe;
  TempSpot.FMult := Mult;
  TempSpot.FMinutesLeft := 0;
  TempSpot.FSourceCall := MyCall + '-' + ComputerID;
  TempSpot.FNotes[0] := #0;
//  Windows.GetSystemTime(TempSpot.FSysTime);
  TempSpot.FSysTime := UTC.wMinute + UTC.wHour * 60 + UTC.wDay * 60 * 24 + UTC.wMonth * 60 * 24 * 30;
  SpotsList.AddSpot(TempSpot, True);

  DisplayBandMap;

end;

procedure CheckClusterType(ByteReceived: integer);
var
  ii                                    : integer;
begin
{
  if ClusterTypeDetermined then Exit;
  for ii := 0 to ByteReceived - 8 do
  begin
    if PInteger(@TelnetBuffer[ii])^ = 1347639364  then begin tClusterType := ctDXSpider;//DXSP
      ClusterTypeDetermined := True;
    end;
    if PInteger(@TelnetBuffer[ii])^ = 1127043649  then begin tClusterType := ctARCluster;//AR-C
      ClusterTypeDetermined := True;
    end;
  end;
} 
end;

procedure SendClientStatus;
begin
  ClientStatus.csTelnet := TelnetSock <> 0;
  SendToNet(ClientStatus, SizeOf(ClientStatus));
end;

procedure AppendTelnetPopupMenu(MenuText: PChar);
var
  Flag                                  : Cardinal;
  Offset                                : integer;
begin
  if ItemsInTelnetPopupMenu > MAXITEMSINTELNETPOPUPMENU - 1 then Exit;
  if MenuText[0] = #0 then Exit;

  Flag := MF_STRING;
  Offset := 0;

  if MenuText[0] = '-' then Flag := MF_SEPARATOR;

  if MenuText[0] = '.' then
  begin
    TelLastPopMemu := TelPopMemu;
    Exit;
  end;

  if MenuText[0] = '#' then
  begin
    Flag := MF_STRING + MF_DISABLED + MF_GRAYED;
    Offset := 1;
  end;

  if MenuText[0] = '!' then
  begin
    Flag := MF_STRING + MF_CHECKED;
    Offset := 1;
  end;

  if MenuText[0] = '>' then
  begin
    TelLastPopMemu := CreatePopupMenu;
    Windows.AppendMenu(TelPopMemu, MF_STRING + MF_POPUP, TelLastPopMemu, @MenuText[1]);
    inc(ItemsInTelnetPopupMenu);
    Exit;
  end;

  if MenuText[0] = '=' then
  begin
    Flag := MF_STRING;
    Offset := 1;
  end;

  Windows.AppendMenu(TelLastPopMemu, Flag, 1000 + ItemsInTelnetPopupMenu, @MenuText[Offset]);

  inc(ItemsInTelnetPopupMenu);
end;

procedure EmunTRCLUSTERDAT(FileString: PShortString);
begin
  GetRidOfPostcedingSpaces(FileString^);
  tCB_ADDSTRING_PCHAR(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, 102, @FileString^[1]);
end;

procedure EmunDXCLUSTERALERTLISTTXT(FileString: PShortString);
begin
  if telnet_callsign_alert_list_loaded = False then
    TelnetCallsignAlertList := CreateWindow(LISTBOX, nil, $50210003, 0, 0, 0, 0, tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, 0, hInstance, nil);

  tLB_ADDSTRING(TelnetCallsignAlertList, @FileString^[1]);
  telnet_callsign_alert_list_loaded := True;
end;

procedure EnumCLUSTERCOMMANDSTXT(FileString: PShortString);
begin
  if FileString^[1] = ';' then Exit;
  AppendTelnetPopupMenu(@FileString^[1]);
end;

end.

