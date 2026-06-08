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
  ClipBrd,
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
  TelnetStringType = (tstTR4W, tstSend, tstReceived, tstReceivedDupe,
    tstReceivedMult, tstError, tstAlert);

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
{$IFDEF AUTOSPOT}
var
  first: boolean;
{$ENDIF}
procedure SendClientStatus;
function TelnetWndDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam:
  lParam): BOOL; stdcall;
function TelnetThreadProc(Param: Pointer): DWORD; stdcall;   // Issue #23 -- DX cluster I/O thread
procedure StartTelnetConnect;                                // Issue #23 -- main-thread launcher
procedure Disconnect;
function TestSocketBuffer: Integer; // Gav 4.44.6
procedure TelnetConnectionError(wsaErr: integer);            // Issue #23 -- explicit code (marshaled)
function SendViaTelnetSocket(p: PChar): integer;
procedure AddStringToTelnetConsole(p: PChar; c: TelnetStringType);
procedure SaveTelnetWindowSpots;
procedure EnableTelnetToolbatButtons(b: boolean);
procedure ProcessTelnetString(const ByteReceived: integer);
function ProcessDX(DX: integer; InListBox: boolean; var Stringtype:
  TelnetStringType): boolean;
procedure tCreateAndAddNewSpot(Call: CallString; Dupe: boolean; Radio:
  RadioPtr);
procedure CheckClusterType(ByteReceived: integer);
procedure AppendTelnetPopupMenu(MenuText: PChar);
procedure EmunTRCLUSTERDAT(FileString: PShortString);
procedure EmunDXCLUSTERALERTLISTTXT(FileString: PShortString);
procedure EnumCLUSTERCOMMANDSTXT(FileString: PShortString);

const
  MAXITEMSINTELNETPOPUPMENU = 70;
  TELNETBUTTONS = 6{$IF LANG = 'RUS'} + 1{$IFEND};

var
  ItemsInTelnetPopupMenu: integer;
  ClientStatus: TClientStatus = (csID: NET_CLIENTSTATUS_ID);
  // BandMapNeedsRefresh moved to LogWind so it is accessible from uRadioPolling without circular dependencies
  //  ClusterTypeDetermined            : boolean;

  //  tClusterType                          : ClusterType = ctDXSpider;

  TelnetServer: Str50; //n4af 04-11-2013
  TempSpot: TSpotRecord;

  tbButtons: array[0..TELNETBUTTONS - 1] of TTBButton = (
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
  SOCK_IDLE = 0;
  SOCK_CLIENT = 3;
  DXSpotLength = 76;

var
  FirstChar: integer;
  //  NextFirstChar                         : integer;
  OldTelnetFreezeMode: boolean;
  TelnetFreezeMode: boolean;
  TelThreadID: Cardinal;
  TelThreadHandle: THandle;     // Issue #23 -- kept so we can join the I/O thread before teardown
  TelnetStopRequested: boolean; // Issue #23 -- set by Disconnect so a thread that is still
                                // connecting bails out after connect instead of orphaning
  TelnetSock: Cardinal;
  TelToolbar: HWND;
  TelnetListBox: HWND;
  TelnetCommandWindow: HWND;
  TelnetListBoxOldProc: Pointer;

  TelPopMemu: HMENU;
  TelLastPopMemu: HMENU;

  telnet_callsign_alert_list_loaded: boolean;
  TelnetCallsignAlertList: HWND;
implementation
uses uNet,
  uBandmap,
  LogGrid,
  MainUnit;

// Issue #23 -- DX cluster I/O thread <-> main-thread message protocol.  The
// cluster thread does ALL blocking network I/O (connect + recv) and never
// touches UI or shared spot/bandmap state; it only posts these to the telnet
// window, which does that work on the main (UI) thread.  Declared here so both
// TelnetWndDlgProc (handler) and TelnetThreadProc (sender) see them.
const
  WM_TELNET_MSG         = WM_USER + 250;
  TELNET_CONNECTED      = 1;   // lParam = 0
  TELNET_CONNECT_FAILED = 2;   // lParam = WSA error code
  TELNET_DATA           = 3;   // lParam = PTelnetChunk (handler disposes it)
  TELNET_CLOSED         = 4;   // lParam = WSA error code (0 = graceful close)

type
  PTelnetChunk = ^TTelnetChunk;
  TTelnetChunk = record
    Len:  integer;
    Data: array[0..8192] of Char;
  end;

var
  PendingTelnetHost: array[0..255] of Char;   // set on the main thread before the I/O thread starts
  PendingTelnetPort: Word;

// ---------------------------------------------------------------------------
//  Issue #973 - field substitution in cluster_commands.txt
//
//  Cluster command lines may embed {TOKEN} placeholders that are expanded to
//  live program values at send time (and previewed in a hover tooltip).
//  Doubled braces are literal escapes: {{ -> {  and  }} -> }.
//  Unknown tokens are left verbatim so a typo is visible in the preview
//  rather than silently transmitted as a blank into a live cluster filter.
// ---------------------------------------------------------------------------

var
  TelCmdTooltip: HWND = 0;                   // tracking tooltip for the preview
  ClusterTooltipText: array[0..511] of Char; // stable storage for the tip text

// Trim surrounding spaces and upper-case A..Z so token matching is
// case-insensitive and tolerant of '{ MY_CALL }'.
function NormalizeClusterToken(const S: AnsiString): AnsiString;
var
   i, First, Last: integer;
   c: Char;
begin
   First := 1;
   Last := Length(S);
   while (First <= Last) and (S[First] = ' ') do
      begin
      Inc(First);
      end;
   while (Last >= First) and (S[Last] = ' ') do
      begin
      Dec(Last);
      end;
   Result := '';
   for i := First to Last do
      begin
      c := S[i];
      if (c >= 'a') and (c <= 'z') then
         begin
         c := Chr(Ord(c) - 32);
         end;
      Result := Result + c;
      end;
end;

{ Returns the live value for a single (already normalized) token name.        }
{ Found is set False for an unrecognized token so the caller can leave it      }
{ verbatim. This is the single source of truth for the token vocabulary.       }
function ClusterTokenValue(const Token: AnsiString; var Found: boolean): AnsiString;
var
   RealFreq: Real;
   FreqStr: ShortString;
begin
   Found := True;
   if Token = 'MY_CALL' then
      Result := MyCall
   else if Token = 'MY_STATE' then
      Result := MyState
   else if Token = 'MY_SECTION' then
      Result := MySection
   else if Token = 'MY_NAME' then
      Result := MyName
   else if Token = 'MY_GRID' then
      Result := MyGrid
   else if Token = 'MY_ZONE' then
      Result := MyZone
   else if Token = 'MY_CHECK' then
      Result := MyCheck
   else if Token = 'MY_PREC' then
      Result := MyPrec
   else if Token = 'MY_CLASS' then
      Result := MyFDClass
   else if Token = 'MY_PARK' then
      Result := MyPark
   else if Token = 'MY_POSTALCODE' then
      Result := MyPostalCode
   else if Token = 'CALL' then
      Result := CallWindowString
   else if Token = 'DATE' then
      Result := GetDateString
   else if Token = 'TIME' then
      Result := GetTimeString
   else if Token = 'BAND' then
      Result := BandStringsArrayWithOutSpaces[ActiveBand]
   else if Token = 'FREQ' then
      begin
      RealFreq := Radio1.FilteredStatus.Freq / 1000.0;   { Hz -> kHz }
      Str(RealFreq: 0: 1, FreqStr);
      Result := FreqStr;
      end
   else
      begin
      Found := False;
      end;
end;

// Expands every {TOKEN} in Src. Pure transform - no global state is mutated -
// so it is safe to call both from the send path and from the menu-hover proc.
function ExpandClusterTokens(Src: PChar): AnsiString;
var
   S, Token, Value: AnsiString;
   i, Len, j: integer;
   Found: boolean;
begin
   S := Src;
   Result := '';
   i := 1;
   Len := Length(S);
   while i <= Len do
      begin
      if (S[i] = '{') and (i < Len) and (S[i + 1] = '{') then
         begin
         Result := Result + '{';
         Inc(i, 2);
         end
      else if (S[i] = '}') and (i < Len) and (S[i + 1] = '}') then
         begin
         Result := Result + '}';
         Inc(i, 2);
         end
      else if S[i] = '{' then
         begin
         j := i + 1;
         while (j <= Len) and (S[j] <> '}') do
            begin
            Inc(j);
            end;
         if j > Len then
            begin
            { Unterminated brace - emit the remainder literally. }
            Result := Result + Copy(S, i, Len - i + 1);
            i := Len + 1;
            end
         else
            begin
            Token := NormalizeClusterToken(Copy(S, i + 1, j - i - 1));
            Value := ClusterTokenValue(Token, Found);
            if Found then
               begin
               Result := Result + Value;
               end
            else
               begin
               Result := Result + Copy(S, i, j - i + 1);   // leave {TOKEN} verbatim
               end;
            i := j + 1;
            end;
         end
      else
         begin
         Result := Result + S[i];
         Inc(i);
         end;
      end;
end;

{ Creates the once-per-window tracking tooltip used to preview expanded        }
{ command values. TrackPopupMenu has no native tooltips, so a manually         }
{ positioned TTF_TRACK tooltip is driven from WM_MENUSELECT.                   }
function CreateClusterCommandTooltip(Owner: HWND): HWND;
const
   TTF_TRACK = $0020;
   TTF_ABSOLUTE = $0080;
var
   ti: TOOLINFO;
begin
   Result := CreateWindowEx(0, 'tooltips_class32', nil,
      WS_POPUP or TTS_NOPREFIX or TTS_ALWAYSTIP,
      0, 0, 0, 0, Owner, 0, hInstance, nil);
   if Result = 0 then
      begin
      Exit;
      end;
   SetWindowPos(Result, HWND_TOPMOST, 0, 0, 0, 0,
      SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);
   Windows.ZeroMemory(@ti, SizeOf(ti));
   ti.cbSize := SizeOf(ti);
   ti.uFlags := TTF_TRACK or TTF_ABSOLUTE;
   ti.HWND := Owner;
   ti.uId := 0;
   ti.lpszText := nil;
   SendMessage(Result, TTM_ADDTOOL, 0, Integer(@ti));
   SendMessage(Result, TTM_SETMAXTIPWIDTH, 0, 600);
end;

{ Hides the preview tooltip (menu closed, or item carries no tokens). }
procedure HideClusterCommandTooltip;
var
   ti: TOOLINFO;
begin
   if TelCmdTooltip = 0 then
      begin
      Exit;
      end;
   Windows.ZeroMemory(@ti, SizeOf(ti));
   ti.cbSize := SizeOf(ti);
   ti.HWND := tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle;
   ti.uId := 0;
   SendMessage(TelCmdTooltip, TTM_TRACKACTIVATE, 0, Integer(@ti));
end;

{ Shows the expanded value of the highlighted command item near the cursor.    }
{ Only real command items (id 1000..) that actually contain a token produce a   }
{ preview; everything else hides the tooltip to avoid noise.                    }
procedure ShowClusterCommandTooltip(ItemId, Flags: word);
var
   Expanded: AnsiString;
   ti: TOOLINFO;
   pt: TPoint;
begin
   if TelCmdTooltip = 0 then
      begin
      Exit;
      end;
   if (ItemId < 1000)                            or
      (ItemId > 1000 + MAXITEMSINTELNETPOPUPMENU) or
      ((Flags and MF_POPUP) <> 0)                 then
      begin
      HideClusterCommandTooltip;
      Exit;
      end;
   GetMenuString(TelPopMemu, ItemId, wsprintfBuffer, 256, MF_BYCOMMAND);
   Expanded := ExpandClusterTokens(wsprintfBuffer);
   if Expanded = AnsiString(wsprintfBuffer) then
      begin
      { No substitution occurred - nothing useful to preview. }
      HideClusterCommandTooltip;
      Exit;
      end;
   lstrcpyn(ClusterTooltipText, PChar(Expanded), SizeOf(ClusterTooltipText));
   Windows.ZeroMemory(@ti, SizeOf(ti));
   ti.cbSize := SizeOf(ti);
   ti.HWND := tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle;
   ti.uId := 0;
   ti.lpszText := ClusterTooltipText;
   SendMessage(TelCmdTooltip, TTM_UPDATETIPTEXT, 0, Integer(@ti));
   GetCursorPos(pt);
   SendMessage(TelCmdTooltip, TTM_TRACKPOSITION, 0,
      MakeLong(pt.X + 16, pt.Y + 16));
   SendMessage(TelCmdTooltip, TTM_TRACKACTIVATE, Integer(True), Integer(@ti));
   // The popup menu is itself a top-most window and re-asserts its z-order on
   // every mouse move (which is what drives WM_MENUSELECT), so lift the tooltip
   // back above the menu after each activation - otherwise it renders behind it.
   SetWindowPos(TelCmdTooltip, HWND_TOPMOST, 0, 0, 0, 0,
      SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);
end;

function TelnetWndDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam:
  lParam): BOOL; stdcall;
label
  1, DrawSpot;
var

  temprect: TRect;

  i : integer;
  TempTextColor: Cardinal;
  TempPoint: TPoint;
  TDIS: PDrawItemStruct;
  InfoBuffer: array[0..1023] of Char;   // Issue #23 -- LB_GETTEXT has no size limit; must hold the
                                        // longest list item (error messages run ~230 chars, far past
                                        // the old 128, overrunning the stack).  AddStringToTelnetConsole
                                        // caps items to this size so this read can never overrun.
  StringType: TelnetStringType;
  ExpandedClusterCommand: AnsiString;   { Issue #973 }
const
  // Issue #23 -- tstTR4W (status messages) was green for no real reason; show it
  // as normal black text.  Errors stay red.
  TelnetStringColor: array[TelnetStringType] of tr4wColors = (trBlack, trBlue,
    trBlack, trLightGray, trRed, trRed, trBlack);
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

        if TDIS^.itemAction = ODA_DRAWENTIRE then
        begin
          i := SendMessage(TDIS^.hwndItem, LB_GETTEXT, TDIS^.ItemID,
            integer(@InfoBuffer));

          StringType := TelnetStringType(SendMessage(TDIS^.hwndItem,
            LB_GETITEMDATA, TDIS^.ItemID, 0));

          if StringType = tstAlert then
            GradientRect(TDIS^.HDC, TDIS^.rcItem, tr4wColorsArray[trYellow],
              tr4wColorsArray[trYellow], gdHorizontal);

          Windows.SetTextColor(TDIS^.HDC,
            tr4wColorsArray[TelnetStringColor[StringType]]);
          SetBkMode(TDIS^.HDC, TRANSPARENT);
          Windows.TextOut(TDIS^.HDC, TDIS^.rcItem.Left + 5
            {TelnetStringOffset[StringType]}, TDIS^.rcItem.Top, InfoBuffer, i);
          Result := True;
        end;
      end;

    WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);

    // Issue #23 -- messages from the DX cluster I/O thread (TelnetThreadProc).
    // All UI and spot/bandmap processing happen here, on the main thread.
    WM_TELNET_MSG:
      begin
        case wParam of
          TELNET_CONNECTED:
            begin
              if TR4W_TELNET_DEBUG then
                 begin
                 logger.Info('[Telnet] Connected to %s:%d', [PChar(@PendingTelnetHost[0]), PendingTelnetPort]);
                 end;
              Format(wsprintfBuffer, '%s%s:%u', TC_CONNECTEDTO,
                @PendingTelnetHost[0], PendingTelnetPort);
              AddStringToTelnetConsole(wsprintfBuffer, tstTR4W);
              Windows.ZeroMemory(@TelnetBuffer, SizeOf(TelnetBuffer));
              if ConnectionCommand <> '' then
                 SendViaTelnetSocket(@ConnectionCommand[1])
              else
                 SetDlgItemText(hwnddlg, 106, @MyCall[1]);
              SendClientStatus;
              EnableTelnetToolbatButtons(True);
              EnableWindowTrue(hwnddlg, 104);
            end;

          TELNET_CONNECT_FAILED:
            begin
              // Issue #23 -- keep the detailed WinSock reason in the log for
              // diagnostics, but show the operator a short message naming the
              // host they tried to reach (the raw message is long and unwrapped).
              logger.Error('[Telnet] Could not connect to %s:%d -- WinSock %d: %s',
                [PChar(@PendingTelnetHost[0]), PendingTelnetPort, lParam,
                 SysErrorMessage(lParam)]);
              Format(wsprintfBuffer, '%s%s:%u', TC_FAILEDTOCONNECTTO,
                @PendingTelnetHost[0], PendingTelnetPort);
              AddStringToTelnetConsole(wsprintfBuffer, tstError);
              Disconnect;
            end;

          TELNET_DATA:
            begin
              if lParam <> 0 then
                 begin
                 Move(PTelnetChunk(lParam)^.Data[0], TelnetBuffer[0],
                      PTelnetChunk(lParam)^.Len);
                 // Issue #23 -- null-terminate like the old recv path did
                 // (TelnetBuffer[i] := #0); ProcessTelnetString treats it as a
                 // C string, so without this it reads past Len into stale data.
                 TelnetBuffer[PTelnetChunk(lParam)^.Len] := #0;
                 ProcessTelnetString(PTelnetChunk(lParam)^.Len);
                 Dispose(PTelnetChunk(lParam));
                 end;
            end;

          TELNET_CLOSED:
            begin
              // Ignore if the user already disconnected (TelnetSock cleared);
              // otherwise this is a server-initiated / network close.
              if TelnetSock <> 0 then
                 begin
                 if lParam <> 0 then
                    begin
                    TelnetConnectionError(lParam);
                    end;
                 Disconnect;
                 end;
            end;
        end;
      end;

    WM_INITDIALOG:
      begin

        CreateComboBox(hwnddlg, 102);
        CreateComboBox(hwnddlg, 106);
        CreateButton(BS_DEFPUSHBUTTON or BS_CENTER or WS_DISABLED, RC_SEND, 0,
          0, 60, hwnddlg, 104);
        CreateOwnerDrawListBox(LBS_NOTIFY or LBS_OWNERDRAWFIXED or LBS_HASSTRINGS
          or LBS_NOINTEGRALHEIGHT or WS_CHILD or WS_VISIBLE or WS_VSCROLL or
          WS_HSCROLL or WS_TABSTOP, hwnddlg);
        //

        tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle := hwnddlg;
        telnet_callsign_alert_list_loaded := False;
        ItemsInTelnetPopupMenu := 0;

        EnumerateLinesInFile('DXCLUSTER_ALERT_LIST.TXT',
          EmunDXCLUSTERALERTLISTTXT, True);

        // Issue 392
        // If the cluster in the config file is not in TRCLUSTER.DAT, this does not connect.
        // We could add it to the EnumTRClusterDAT or just take it as a host and connect.
        // We should check the hosts is valid too but we can see that in the connect.
        // Also, ensure we get a useful error message when we cannot connect.
        // Currently it just says Operation Successful which is false and not helpful.
        EnumerateLinesInFile('TRCLUSTER.DAT', EmunTRCLUSTERDAT, False);
        EmunTRCLUSTERDAT(@TelnetServer);
        // Issue 392 ny4i - This adds the value in the config for telnet server to the drop-down
        i := SendDlgItemMessage(hwnddlg, 102, CB_FINDSTRING, -1,
          integer(@TelnetServer[1])); //n4af 4.35.1
        //     i := SendDlgItemMessage(hwnddlg, 102, CB_FINDSTRINGEXACT, -1,integer(@TelnetServer[1]));
        if i <> CB_ERR then
          tCB_SETCURSEL(hwnddlg, 102, i);

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

        SendMessage(TelToolbar, TB_ADDSTRING, 0,
          integer(PChar(TC_TELNET{$IF LANG = 'RUS'} + '?'#0#0{$IFEND})));
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

        if tConnectionAtStartup then
          SendMessage(hwnddlg, WM_COMMAND, 200, 0);

        TelPopMemu := CreatePopupMenu;
        TelLastPopMemu := TelPopMemu;
        AppendTelnetPopupMenu('HELP');
        AppendTelnetPopupMenu('SHOW/USERS');
        AppendTelnetPopupMenu('SHOW/WWV');
        AppendTelnetPopupMenu('SHOW/FILTER');

        EnumerateLinesInFile('CLUSTER_COMMANDS.TXT', EnumCLUSTERCOMMANDSTXT,
          True);

        // Issue #973: tooltip that previews each command's expanded value.
        TelCmdTooltip := CreateClusterCommandTooltip(hwnddlg);

        //tLB_ADDSTRING(TelnetListBox,'DX DE SM6WET:    28025.0  G0ORH        SRI, THIS IS CORRECT           0953Z JO68  ');
        //tLB_ADDSTRING(TelnetListBox,'DX DE G4MJS:     14180.0  2DONCG       YOUR TURN TO MAKE A BREW       0953Z JO01  ');
        //tLB_ADDSTRING(TelnetListBox,'DX DE LU6FL:      1845.0  LU6FL        CQ CQ TEST SSB                 0953Z FF97  ');
        //tLB_ADDSTRING(TelnetListBox,'DX DE RZ3DSD:    14258.9  RA3RGQ/1                                    0953Z  ');
        //tLB_ADDSTRING(TelnetListBox,'DX DE F5PPO:     18135.0  CQ9U                                        0953Z  ');
        //tLB_ADDSTRING(TelnetListBox,'DX DE PA3C:      24897.2  LZ1PJ                                       0954Z JO33  ');

      end;
    //    WM_HELP: tWinHelp(7);

    // Issue #973: preview the highlighted command's expanded value in a tooltip.
    WM_MENUSELECT:
      begin
        if (HiWord(wParam) = $FFFF) and (lParam = 0) then
          HideClusterCommandTooltip   // menu closed
        else
          ShowClusterCommandTooltip(LoWord(wParam), HiWord(wParam));
      end;

    WM_EXITMENULOOP:
      begin
        HideClusterCommandTooltip;
      end;

    WM_COMMAND:
      begin
        if HiWord(wParam) = LBN_SELCHANGE then
          DlgDirSelectEx(hwnddlg, wsprintfBuffer, SizeOf(wsprintfBuffer), 101);

        if HiWord(wParam) = LBN_DBLCLK then
        begin
          //      DlgDirSelectEx(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, wsprintfBuffer, SizeOf(wsprintfBuffer), 101);  //n4af
          //    DlgDirList(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, wsprintfBuffer, 101, 106, DDL_ARCHIVE or DDL_DIRECTORY);       //n4af
          //   ShowMessage(SysErrorMessage(GetLastError));
          i := SendMessage(TelnetListBox, LB_GETCURSEL, 0, 0);
          if i = LB_ERR then
            Exit;
          SendMessage(TelnetListBox, LB_GETTEXT, i, integer(@TelnetBuffer[0]));
          if PInteger(@TelnetBuffer[0])^ = $64205844 {DX D} then
            if ProcessDX(0, True, StringType) then
              TuneRadioToSpot(TempSpot, RadioOne);

        end;

        if (wParam >= 1000) then
          if (wParam <= 1000 + MAXITEMSINTELNETPOPUPMENU) then
          begin
            GetMenuString(TelPopMemu, wParam, wsprintfBuffer, 256,
              MF_BYCOMMAND);
            //n4af    4.51.1
            // Issue #973: expand {TOKEN} fields to live values before sending.
            // Cap to 250 so SendViaTelnetSocket's CRLF append cannot overflow
            // its 256-byte wsprintfBuffer when expansion grows the string.
            ExpandedClusterCommand := ExpandClusterTokens(wsprintfBuffer);
            if Length(ExpandedClusterCommand) > 250 then
              SetLength(ExpandedClusterCommand, 250);
            SendViaTelnetSocket(PChar(ExpandedClusterCommand));
          end;

        case wParam of
          201: Disconnect;

          202:
            begin
              GetCursorPos(TempPoint);
              TrackPopupMenu(TelPopMemu, TPM_TOPALIGN, TempPoint.X, TempPoint.Y
                + 10, 0, hwnddlg, nil);
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

          //          DialogBox(hInstance, MAKEINTRESOURCE(44), hwnddlg, @SpotsFilterDlgProc);
          200: StartTelnetConnect;   // Issue #23 -- launch the DX cluster I/O thread

          104:
            begin
              SendMessage(TelnetCommandWindow, CB_SHOWDROPDOWN, 0, 0);
              Windows.GetWindowText(TelnetCommandWindow, TempBuffer1,
                SizeOf(TempBuffer1));
              if TempBuffer1[0] = #0 then
                Exit;
              SendViaTelnetSocket(TempBuffer1);
              Windows.SetWindowText(TelnetCommandWindow, nil);
              if
                SendMessage(TelnetCommandWindow, CB_FINDSTRING, -1,
                integer(PChar(@TempBuffer1))) = CB_ERR then
                //  SendMessage(TelnetCommandWindow, CB_FINDSTRINGEXACT, -1, integer(PChar(@TempBuffer1))) = CB_ERR then
                tCB_ADDSTRING_PCHAR(hwnddlg, 106, TempBuffer1);

            end

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

        Windows.SetWindowPos(Windows.GetDlgItem(hwnddlg, 102), HWND_TOP, 0,
          TempTextColor, 160, 300, SWP_SHOWWINDOW);

        Windows.SetWindowPos(Windows.GetDlgItem(hwnddlg, 106), HWND_TOP, 165,
          TempTextColor, temprect.Right - temprect.Left - 210 - 25, 300,
          SWP_SHOWWINDOW);
        Windows.SetWindowPos(Windows.GetDlgItem(hwnddlg, 104), HWND_TOP,
          temprect.Right - temprect.Left - 40 - 25, TempTextColor, 0, 0,
          SWP_NOSIZE
          or SWP_SHOWWINDOW);

        Windows.SetWindowPos(TelnetListBox, HWND_TOP, 0, 27 + 25, temprect.Right
          - temprect.Left, temprect.Bottom - temprect.Top - 55,
          {SWP_NOSIZE or }SWP_SHOWWINDOW);
        MoveWindow(TelToolbar, 0, 0, LoWord(lParam), 0, True);
        SendMessage(TelnetListBox, WM_VSCROLL, SB_BOTTOM, 0);

      end;

  end;
end;

// Runs on the DX cluster I/O thread.  Connects (blocking), then loops on
// blocking recv, posting each chunk to the telnet window.  Posts CONNECTED /
// CONNECT_FAILED / CLOSED for lifecycle.  Does NO UI and touches NO shared
// contest/bandmap state -- that all happens on the main thread in the handler.
function TelnetThreadProc(Param: Pointer): DWORD; stdcall;
var
  localSock: DWORD;
  n:         integer;
  wnd:       HWND;
  chunk:     PTelnetChunk;
  recvBuf:   array[0..8191] of Char;
begin
  Result := 0;
  wnd := tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle;

  if TR4W_TELNET_DEBUG then
     begin
     logger.Info('[Telnet] Connecting to %s:%d', [PChar(@PendingTelnetHost[0]), PendingTelnetPort]);
     end;

  if not GetConnection(localSock, PendingTelnetHost, PendingTelnetPort, SOCK_STREAM) then
     begin
     PostMessage(wnd, WM_TELNET_MSG, TELNET_CONNECT_FAILED, WSAGetLastError);
     Exit;
     end;

  // Issue #23 -- if Disconnect/window-close happened while we were blocked in
  // connect, bail out now (closing the freshly-connected socket) instead of
  // publishing it and entering the recv loop -- avoids an orphaned thread/socket.
  if TelnetStopRequested then
     begin
     closesocket(localSock);
     Exit;
     end;

  TelnetSock := localSock;   // publish for the send path (main thread); recv uses localSock
  PostMessage(wnd, WM_TELNET_MSG, TELNET_CONNECTED, 0);

  while True do
     begin
     n := recv(localSock, recvBuf, SizeOf(recvBuf) - 1, 0);
     if n < 1 then
        begin
        // 0 = graceful close, < 0 = error (incl. a Disconnect that closed the
        // socket out from under us).  Report and end the thread.
        PostMessage(wnd, WM_TELNET_MSG, TELNET_CLOSED, WSAGetLastError);
        Break;
        end;

     New(chunk);
     chunk^.Len := n;
     Move(recvBuf[0], chunk^.Data[0], n);
     chunk^.Data[n] := #0;
     if TR4W_TELNET_DEBUG then
        begin
        logger.Info('[Telnet RX %d] %s', [n, PChar(@chunk^.Data[0])]);
        end;
     PostMessage(wnd, WM_TELNET_MSG, TELNET_DATA, LPARAM(chunk));
     end;
end;

// Runs on the MAIN thread (Connect button).  Reads host:port from the dialog
// (UI access stays on the UI thread), then spawns the I/O thread.
procedure StartTelnetConnect;
var
  StackTelHandle: HWND;
  i: integer;
begin
  if TelThreadID <> 0 then
     begin
     Exit;   // already connecting / connected
     end;

  StackTelHandle := tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle;
  PendingTelnetPort := 23;
  i := Windows.GetDlgItemText(StackTelHandle, 102, TempBuffer1, SizeOf(TempBuffer1));

  // TempBuffer1 is 0-based; scan [length-1 .. 0].  ':' splits host:port; ' '
  // terminates the host.
  dec(i);
  while i >= 0 do
     begin
     if TempBuffer1[i] = ':' then
        begin
        PendingTelnetPort := pchartoint(@TempBuffer1[i + 1]);
        TempBuffer1[i] := #0;
        end;
     if TempBuffer1[i] = ' ' then
        begin
        TempBuffer1[i] := #0;
        end;
     dec(i);
     end;

  Windows.lstrcpyn(PendingTelnetHost, TempBuffer1, SizeOf(PendingTelnetHost));

  // Issue #23 -- immediate visual feedback so connect is not a black box:
  // show the attempt in the window and switch the toolbar to the connected
  // state (grays Connect, enables Disconnect) the instant the user clicks.
  Format(wsprintfBuffer, '%s%s:%u', TC_CONNECTINGTO, @PendingTelnetHost[0],
    PendingTelnetPort);
  AddStringToTelnetConsole(wsprintfBuffer, tstTR4W);
  EnableTelnetToolbatButtons(True);

  // Issue #23 -- start each session live: a Freeze left on from a previous
  // connection would silently suppress auto-scroll on reconnect, looking like
  // the cluster is dead.  Clear the mode and un-press the Freeze toolbar button.
  TelnetFreezeMode := False;
  OldTelnetFreezeMode := False;
  SendMessage(TelToolbar, TB_CHECKBUTTON, 203, 0);

  TelnetStopRequested := False;
  logger.Debug('Starting DX cluster I/O thread');
  TelThreadHandle := tCreateThread(@TelnetThreadProc, TelThreadID);
  logger.Debug('Created DX cluster thread with threadid of %d', [TelThreadID]);
end;

procedure Disconnect;
var
  StackTelHandle: HWND;
begin
  if TR4W_TELNET_DEBUG then   // Issue #23 -- log every disconnect
     begin
     logger.Info('[Telnet] Disconnecting (socket %d)', [TelnetSock]);
     end;
  StackTelHandle := tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle;

  // Issue #23 -- show a disconnect message only if we were actually connected
  // (TelnetSock <> 0).  A failed connect routes through here too but never
  // connected, so "DISCONNECTED from" would be wrong there.
  if TelnetSock <> 0 then
     begin
     Format(wsprintfBuffer, '%s%s:%u', TC_DISCONNECTEDFROM, @PendingTelnetHost[0],
       PendingTelnetPort);
     AddStringToTelnetConsole(wsprintfBuffer, tstTR4W);
     end;

  // Tell a still-connecting thread to bail (it checks this after connect, since
  // we can't unblock its in-progress connect via the socket).
  TelnetStopRequested := True;

  // Close the socket first -- this unblocks the I/O thread's recv so it can
  // exit -- then JOIN the thread before any teardown.  Without the join the
  // main thread tore down (and kept allocating/logging) while the raw I/O
  // thread was still terminating, which corrupted state and crashed.
  closesocket(TelnetSock);
  TelnetSock := 0;
  if TelThreadHandle <> 0 then
     begin
     WaitForSingleObject(TelThreadHandle, 5000);
     CloseHandle(TelThreadHandle);
     TelThreadHandle := 0;
     end;
  TelThreadID := 0;

  EnableWindowFalse(StackTelHandle, 104);
  EnableWindowTrue(StackTelHandle, 102);
  EnableTelnetToolbatButtons(False);
  //  tEnableMenuItem(menu_ctrl_sendspot, MF_BYCOMMAND + MF_GRAYED);
  SendClientStatus;
end;

procedure TelnetConnectionError(wsaErr: integer);
var
  msg: PChar;
begin
  // Issue #23 -- log the WinSock error to the general error log always
  // (independent of TELNET DEBUG) and show it in the telnet window.  The code is
  // passed in (not read from WSAGetLastError) because it may have been captured
  // on the I/O thread and marshaled here -- WSAGetLastError is per-thread.
  msg := SysErrorMessage(wsaErr);
  logger.Error('[Telnet] WinSock error %d: %s', [wsaErr, msg]);
  AddStringToTelnetConsole(msg, tstError);
end;

function SendViaTelnetSocket(p: PChar): integer;
var
  sent: integer;
begin
  Result := 0;
  if TelnetSock = 0 then
    Exit;
  if TR4W_TELNET_DEBUG then   // Issue #23
     begin
     logger.Info('[Telnet TX] %s', [p]);
     end;
  AddStringToTelnetConsole(p, tstSend);
  // Issue #23 -- key off the send() return, not WSAGetLastError (which is only
  // meaningful after SOCKET_ERROR and can read stale after a successful send,
  // wrongly tearing down a healthy link).  Always runs on the main thread now,
  // so a real failure can tear the dead socket down directly (closing it also
  // unblocks the I/O thread's recv).
  sent := WinSock2.Send(TelnetSock, wsprintfBuffer,
    Format(wsprintfBuffer, '%s'#13#10, p), 0);
  if sent = SOCKET_ERROR then
  begin
    Result := WSAGetLastError;
    TelnetConnectionError(Result);
    Disconnect;
  end;
end;

procedure AddStringToTelnetConsole(p: PChar; c: TelnetStringType);
var
  Handle: HWND;
  buf: array[0..1023] of Char;   // Issue #23 -- bound the list item to InfoBuffer's size
begin
  if TR4W_TELNET_DEBUG then   // Issue #23 -- every line written to the telnet window
     begin
     logger.Info('[Telnet WINDOW t=%d] %s', [Ord(c), p]);
     end;

  Handle := TelnetListBox;

  // Issue #23 -- copy into a bounded buffer first.  The owner-draw handler reads
  // each item back via LB_GETTEXT (which has no size limit) into a same-sized
  // stack buffer; capping here guarantees that read can never overrun the stack.
  Windows.lstrcpyn(buf, p, SizeOf(buf));

  SendMessage(Handle, LB_SETITEMDATA, SendMessage(Handle, LB_ADDSTRING, 0,
    integer(@buf)), integer(c));

  if TelnetFreezeMode then
    Exit;
  SendMessage(Handle, WM_HSCROLL, SB_BOTTOM, 0);
  SendMessage(Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure SaveTelnetWindowSpots;
var

  i, Lines: integer;
  LineLength: longword;
  TimeString: PChar;
  TelnetLogHandle: HWND;
begin
  if not tWindowsExist(tw_TELNETWINDOW_INDEX) then
    Exit;
  Lines :=
    SendDlgItemMessage(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, 101,
    LB_GETCOUNT, 0, 0);
  if Lines < 10 then
    Exit;
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

  TelnetLogHandle := CreateFile(wsprintfBuffer, GENERIC_WRITE, FILE_SHARE_WRITE,
    nil, CREATE_NEW, FILE_ATTRIBUTE_ARCHIVE, 0);

  if TelnetLogHandle <> INVALID_HANDLE_VALUE then
  begin
    for i := 0 to Lines - 1 do
    begin
      LineLength :=
        SendDlgItemMessage(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle,
        101, LB_GETTEXT, i, lParam(@wsprintfBuffer));
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
    State: boolean;
  begin
    State := b;
    if Control = 200 then
      InvertBoolean(State);
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

  c: integer;
  AddedSpot: boolean;
  pr: integer;
  StringType: TelnetStringType;
  d: integer;

begin
  //  Windows.CharUpperBuff(TelnetBuffer, ByteReceived);
  AddedSpot := False;
  pr := -1;
  d := 0;
  for c := 0 to ByteReceived do
  begin
    d := d + 1;
    if pr = -1 then
      if TelnetBuffer[c] > #13 then
        pr := c;

    if pr <> -1 then
      if (TelnetBuffer[c] <= #13) or (d > 120) then // n4af 4.50.7   issue # 179
      begin
        d := 0;
        TelnetBuffer[c] := #0;
        StringType := tstReceived;
        if (PInteger(@TelnetBuffer[pr])^ = $64205844) {DX D} and
        (PInteger(@TelnetBuffer[pr + 2])^ = $20656420) { DE } then
          AddedSpot := ProcessDX(pr, False, StringType);

        AddStringToTelnetConsole(@TelnetBuffer[pr], StringType);

        //     SetUpBandMapEntry(@BandMapEntryRecord, ActiveRadio);   // remove hh
        pr := -1;
        //   end;
      end;
  end;

  if AddedSpot then
  begin
    sleep(BMDelay);
    // So we do not drive the serial port and radio too fast.    // 4.93.beta       // 4.102.5
    // Signal the 250ms refresh timer rather than repainting immediately.
    // The timer coalesces bursts of spots into a single repaint, eliminating
    // flashing. The spot data (FList) is always current; the display is at
    // most 250ms behind.
    if BandMapAllBands or (TempSpot.FBand = BandmapBand) then
      if BandMapAllModes or (TempSpot.FMode = BandmapMode) then
        BandMapNeedsRefresh := True;

{$IFDEF AUTOSPOT}
    if TwoRadioMode then
    begin
      if first then
      begin
        //TLogger.GetInstance.Debug(Format('Writing to Radio One: %s',[TempSpot.FFreqString]));
        TuneRadioToSpot(TempSpot, RadioOne); // ny4i test code to exercise radio
        first := false;
      end
      else
      begin
        first := true;
        //TLogger.GetInstance.Debug(Format('Writing to Radio Two: %s',[TempSpot.FFreqString]));
        TuneRadioToSpot(TempSpot, RadioTwo);
      end;
    end
    else
    begin
      //TLogger.GetInstance.Debug(Format('Writing to Radio One: %s',[TempSpot.FFreqString]));
      TuneRadioToSpot(TempSpot, RadioOne);
    end;

{$ENDIF}
  end;

end;

function TestSocketBuffer: Integer; // Gav 4.44.6
begin
  ioctlsocket(TelnetSock, FIONREAD, u_long(Result));
  if TelnetSock <> SOCKET_ERROR then
    ioctlsocket(TelnetSock, FIONREAD, u_long(Result))
  else
    result := 1;
end;

function ProcessDX(DX: integer; InListBox: boolean; var Stringtype:
  TelnetStringType): boolean;
label
  1;
var
  i, i1: integer;
  TempFrequency: integer;

  f: integer;
  QSXPos: integer;
  TempChar: Char;
  Hertz: integer;
  DivHertz: boolean;
  QSXBand: BandType;
  QSXMode: ModeType;
  UpKhz: integer;

  Offset: integer;
  ct: Cardinal;
begin
  Offset := 0;
  Result := False;
  Stringtype := tstReceived;
  Windows.ZeroMemory(@TempSpot, SizeOf(TSpotRecord));
  TempSpot.FBand := NoBand;
  TempSpot.FMode := NoMode;

  //  ShowMessage(@TelnetBuffer[DX + 24]);
  if TelnetBuffer[DX + 24] = '.' then
    Offset := 3; // 4.92.6
  if TelnetBuffer[DX + 25] = '.' then
    Offset := 4;
  if TelnetBuffer[DX + 26] = '.' then
    Offset := 5;
  if TelnetBuffer[Dx + 23] = '.' then
    Offset := 1;
  {Source Callsign}
  for i := DX + 9 to DX + 20 do
  begin
    if ((TelnetBuffer[i] = ' ') or (TelnetBuffer[i] = ':')) then
    begin
      if TelnetBuffer[i + 1] <> ' ' then // 4.92.6
        SetLength(TempSpot.FSourceCall, i - DX - 6);
      Windows.lstrcpyn(@TempSpot.FSourceCall[1], @TelnetBuffer[DX + 6], i - DX -
        5);
      i1 := i;
      Break;
    end;
  end;

  for i := DX + 10 to DX + 20 do
  begin
    // if TelnetBuffer[i] = ' ' then if TelnetBuffer[i + 1] <> ' ' then
    if (TelnetBuffer[i] = ' ') or (TelnetBuffer[i] = ':') then // 4.92.6
      if TelnetBuffer[i + 1] <> ' ' then

      begin
        Windows.lstrcpyn(@TempSpot.FFreqString[0], @TelnetBuffer[i + 1], DX + 24
          - i + Offset);

        TempFrequency := 0;

        for f := 0 to 12 do
        begin
          if TempFrequency > 2100000 { $ 7FFFFFF} then
            Exit;

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
          if TempSpot.FFreqString[f] = #0 then
            Break;
          if TempSpot.FFreqString[f] in ['0'..'9'] then
            TempFrequency := TempFrequency * 10 + (Ord(TempSpot.FFreqString[f])
              - 48);
        end;

      end;
  end;

  //1

  {DX}

//  DXCallStart := 25;
  if Offset = 4 then
    Offset := 3; // 4.92.7
  for i := DX + 27 to DX + 39 do
  begin
    if TelnetBuffer[i] <> ' ' then
      if TelnetBuffer[i + 1] = ' ' then // 4.92.7
      begin
        SetLength(TempSpot.FCall, i - (DX + 25 + Offset));
        Windows.lstrcpyn(@TempSpot.FCall[1], @TelnetBuffer[DX + 26 + Offset], i
          - (DX + 24 + Offset));
        if not GoodCallSyntax(TempSpot.FCall) then
          Exit;
        Break;
      end;
  end;

  {Note}
  if TelnetBuffer[DX + 39 + Offset] <> '                              ' then
    // This is not right as the extensions can be at the end so check if th ewhole comment (30 bytes) is blank // ny4i
  begin
    Windows.lstrcpyn(@TempSpot.FNotes[0], @TelnetBuffer[DX + 39 + Offset], 31);
    //was 31 but allow for null ny4i
    StrUpper(@TelnetBuffer[DX + 39 + Offset]);
    for i := DX + 39 to DX + 65 do
    begin
      //        i1:=
     // i1 := PInteger(@TelnetBuffer[i])^;

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
                  TempSpot.FQSXFrequency := TempSpot.FQSXFrequency * 10 +
                    (Ord(TempChar) - 48);
                  if DivHertz then
                    Hertz := Hertz div 10;
                end;
              '.': DivHertz := True;
            end;
          end;

          TempSpot.FQSXFrequency := TempSpot.FQSXFrequency * Hertz;
          if TempSpot.FQSXFrequency < 10000 then
            TempSpot.FQSXFrequency := TempSpot.FFrequency +
              TempSpot.FQSXFrequency;
          QSXBand := NoBand;
          CalculateBandMode(TempSpot.FQSXFrequency, QSXBand, QSXMode);
          if QSXBand = NoBand then
            TempSpot.FQSXFrequency := 0;
        end;

      end;

      if PInteger(@TelnetBuffer[i])^ = $20315055 {UP1 } then
        TempSpot.FQSXFrequency := TempSpot.FFrequency + 1000;
      if PInteger(@TelnetBuffer[i])^ = $20325055 {UP2 } then
        TempSpot.FQSXFrequency := TempSpot.FFrequency + 2000;
      if PInteger(@TelnetBuffer[i])^ = $20335055 {UP3 } then
        TempSpot.FQSXFrequency := TempSpot.FFrequency + 3000;
      if PInteger(@TelnetBuffer[i])^ = $20345055 {UP4 } then
        TempSpot.FQSXFrequency := TempSpot.FFrequency + 4000;
      if PInteger(@TelnetBuffer[i])^ = $20355055 {UP5 } then
        TempSpot.FQSXFrequency := TempSpot.FFrequency + 5000;

      // Handle "UP <n>" format (space between UP and number, e.g. "UP 5", "UP 10").
      // Word-boundary guard: require a space (or start of comment field) before
      // "UP" so that words like "PUP", "CUP", "SOUP" in spot comments don't
      // trigger a false split.
      // "UP <n>" with space-separated number, e.g. "UP 5", "UP 10".
      // Require a space before 'U' (word boundary) and a digit after "UP ".
      if (TelnetBuffer[i] = 'U') and
         (TelnetBuffer[i + 1] = 'P') and
         (TelnetBuffer[i + 2] = ' ') and
         (TelnetBuffer[i - 1] = ' ') and
         (TelnetBuffer[i + 3] in ['0'..'9']) then
         begin
         UpKhz := 0;
         for QSXPos := 3 to 8 do
            begin
            TempChar := TelnetBuffer[i + QSXPos];
            if not (TempChar in ['0'..'9']) then
               Break;
            UpKhz := UpKhz * 10 + (Ord(TempChar) - 48);
            end;
         if UpKhz > 0 then
            TempSpot.FQSXFrequency := TempSpot.FFrequency + UpKhz * 1000;
         end;
    end;
  end;

  if InListBox then
    goto 1;
  //1

  GetBandMapBandModeFromFrequency(TempSpot.FFrequency, TempSpot.FBand,
    TempSpot.FMode);

  //  if TempSpot.FBand = Band20 then    TempSpot.FQSXFrequency := TempSpot.FFrequency + 1000;

  TempSpot.FDupe :=
    //CallsignsList.CallsignIsDupe(TempSpot.FCall, TempSpot.FBand, TempSpot.FMode, I1);
  VisibleLog.CallIsADupe(TempSpot.FCall, TempSpot.FBand, TempSpot.FMode);

  if TempSpot.FDupe then
    Stringtype := tstReceivedDupe;

  if not TempSpot.FDupe then
  begin
    TempSpot.FMult := VisibleLog.DetermineIfNewMult(TempSpot.FCall,
      TempSpot.FBand, TempSpot.FMode);
    //    TempSpot.FMult := MultString <> 0;
    if TempSpot.FMult then
      Stringtype := tstReceivedMult;

  end;

  //  Windows.GetSystemTime(TempSpot.FSysTime);
  ct := UTC.wMinute + UTC.wHour * 60 + UTC.wDay * 60 * 24 + UTC.wMonth * 60 * 24
    * 30;
  if (TelnetBuffer[DX + 74] = 'Z') then
  begin
    TempSpot.FSysTime := ((Ord(TelnetBuffer[DX + 70]) - $30) * 10 +
      Ord(TelnetBuffer[DX + 71]) - $30) * 60 +
      ((Ord(TelnetBuffer[DX + 72]) - $30) * 10 + Ord(TelnetBuffer[DX + 73]) -
      $30) + UTC.wDay * 60 * 24 + UTC.wMonth * 60 * 24 * 30;
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
  if not TempSpot.FDupe then // 4.93.4
    SpotsList.AddSpot(TempSpot, True);

  if telnet_callsign_alert_list_loaded then
    if Windows.SendMessage(TelnetCallsignAlertList, LB_FINDSTRINGEXACT, -1,
      integer(PChar(@TempSpot.FCall[1]))) <> LB_ERR then
    begin
      Stringtype := tstAlert;

      Format(QuickDisplayBuffer,
        'New DX Cluster spot: %s was spoted by %s on %s', @TempSpot.FCall[1],
        @TempSpot.FSourceCall[1], TempSpot.FFreqString);
      QuickDisplay(QuickDisplayBuffer);

      Tree.QuickBeep;
    end;

  1:
  Result := True;
end;

procedure tCreateAndAddNewSpot(Call: CallString; Dupe: boolean; Radio:
  RadioPtr);
label
  1;
var
  TempFrequency: LONGINT;
  Mult: boolean;
begin
  if not BandMapEnable then
    Exit;
  if bandmappreventrefresh then
    exit;
  if StringIsAllNumbers(Call) then
    Exit;
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
  if TempFrequency <= 0 then
    Exit;

  Windows.ZeroMemory(@TempSpot, SizeOf(TempSpot));

  if PInteger(@Call[1])^ = tCQAsInteger then
  begin
    Mult := False;
    TempSpot.FCQ := True; //GAV changed from true to false
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

  if TempSpot.FCQ then
    //GAV      issue, picking activeband on dupecheck   changed from ActiveBand / mode to BandmapBand / mode  if not CQ
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
  TempSpot.FSysTime := UTC.wMinute + UTC.wHour * 60 + UTC.wDay * 60 * 24 +
    UTC.wMonth * 60 * 24 * 30;
  SpotsList.AddSpot(TempSpot, True);

  DisplayBandMap;
end;

procedure CheckClusterType(ByteReceived: integer);

begin

end;

procedure SendClientStatus;
begin
  ClientStatus.csTelnet := TelnetSock <> 0;
  SendToNet(ClientStatus, SizeOf(ClientStatus));
end;

procedure AppendTelnetPopupMenu(MenuText: PChar);
var
  Flag: Cardinal;
  Offset: integer;
begin
  if ItemsInTelnetPopupMenu > MAXITEMSINTELNETPOPUPMENU - 1 then
    Exit;
  if MenuText[0] = #0 then
    Exit;

  Flag := MF_STRING;
  Offset := 0;

  if MenuText[0] = '-' then
    Flag := MF_SEPARATOR;

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
    Windows.AppendMenu(TelPopMemu, MF_STRING + MF_POPUP, TelLastPopMemu,
      @MenuText[1]);
    inc(ItemsInTelnetPopupMenu);
    Exit;
  end;

  if MenuText[0] = '=' then
  begin
    Flag := MF_STRING;
    Offset := 1;
  end;

  Windows.AppendMenu(TelLastPopMemu, Flag, 1000 + ItemsInTelnetPopupMenu,
    @MenuText[Offset]);

  inc(ItemsInTelnetPopupMenu);
end;

procedure EmunTRCLUSTERDAT(FileString: PShortString);
begin
  tCB_ADDSTRING_PCHAR(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, 102,
    @FileString^[1]);
end;

procedure EmunDXCLUSTERALERTLISTTXT(FileString: PShortString);
begin
  if telnet_callsign_alert_list_loaded = False then
    TelnetCallsignAlertList := CreateWindow(LISTBOX, nil, $50210003, 0, 0, 0, 0,
      tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, 0, hInstance, nil);

  tLB_ADDSTRING(TelnetCallsignAlertList, @FileString^[1]);
  telnet_callsign_alert_list_loaded := True;
end;

procedure EnumCLUSTERCOMMANDSTXT(FileString: PShortString);
begin
  if FileString^[1] = ';' then
    Exit;
  AppendTelnetPopupMenu(@FileString^[1]);
end;

end.

