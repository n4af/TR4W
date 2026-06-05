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
unit uCAT;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  uCFG,
  Windows,
  Messages,
  LogRadio,
  LogCW,
  CFGCMD,
  LogWind,
  LogK1EA,
  Tree,
  Classes,
  uK4Discovery;

procedure CloseCATAndKeyerForThisRadio;
function CATDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure RestartPollingThread(CATWndHWND: HWND);

var
  CATWTR                                : RadioPtr {= @Radio1};
  TempKeyerPortType                     : PortType;

implementation

uses
  uRadioPolling,
  MainUnit;

// Issue #968 -- the default network TCP port is per radio MODEL, not per CAT
// family: the K4, Flex and the Kenwoods all carry rt = rtKenwood (they share a
// Kenwood-style CAT dialect) yet use four different network ports, so we cannot
// key off RadioParametersArray[].rt for them.  Icom is the one clean family case.
// Returns 0 for a radio that has no network port (serial-only) -> no default.
function DefaultNetworkPortForRadio(rt: InterfacedRadioType): Integer;
begin
   case rt of
      K4:     Result := 9200;
      FLEX:   Result := 4992;
      TS890:  Result := 60000;
      TS990:  Result := 50000;    // NOT the same as the TS-890
   else
      if RadioParametersArray[rt].rt = rtICOM then
         begin
         Result := 50001;         // any Icom network model
         end
      else
         begin
         Result := 0;             // not a network radio -> no default
         end;
   end;
end;

// Issue #968 -- when the dialog is showing a network radio (control-port combo
// 122 = index 21) and the TCP-port edit (131) is empty/0, pre-fill it with the
// selected model's default port.  Never overwrites a port the operator typed.
procedure ApplyDefaultNetworkPort(hwnddlg: HWND);
var
   typeIdx : Integer;
   port    : UINT;
   def     : Integer;
   ok      : BOOL;
begin
   if tCB_GETCURSEL(hwnddlg, 122) <> 21 then   // 21 = Network
      begin
      Exit;
      end;

   typeIdx := tCB_GETCURSEL(hwnddlg, 121);
   if typeIdx < 0 then                          // CB_ERR -- no selection
      begin
      Exit;
      end;

   port := Windows.GetDlgItemInt(hwnddlg, 131, ok, False);
   if port <> 0 then                            // operator already set a port
      begin
      Exit;
      end;

   def := DefaultNetworkPortForRadio(InterfacedRadioType(typeIdx));
   if def <> 0 then
      begin
      Windows.SetDlgItemInt(hwnddlg, 131, def, False);
      end;
end;

// Issue #853 -- run network discovery for the radio type currently selected in
// the RADIO ONE/TWO dialog and, on a single hit, write its IP into the IP edit
// (control 130).  Kept in its own procedure (Delphi 7 codegen hygiene -- avoids
// adding inline logic to the long dialog proc).  K4 only for now; Flex/Icom
// discovery wire in at the type check below.
procedure RunNetworkDiscoveryForRadio(hwnddlg: HWND);
var
  radios       : TList;
  i            : Integer;
  msg          : string;
  savedCursor  : HCURSOR;
  radioName    : string;
  rt           : InterfacedRadioType;
begin
  rt := InterfacedRadioType(tCB_GETCURSEL(hwnddlg, 121));
  radioName := InterfacedRadioTypeSA[rt];

  if rt <> K4 then
     begin
     Format(wsprintfBuffer, TC_DISCOVER_NOT_AVAILABLE, PChar(radioName));
     showwarning(wsprintfBuffer);
     Exit;
     end;

  savedCursor := SetCursor(LoadCursor(0, IDC_WAIT));
  EnableWindowFalse(hwnddlg, 140);
  try
     radios := TK4Discovery.DiscoverRadios(3000);
  finally
     EnableWindowTrue(hwnddlg, 140);
     SetCursor(savedCursor);
  end;

  try
     if radios.Count = 0 then
        begin
        Format(wsprintfBuffer, TC_DISCOVER_NONE_FOUND, PChar(radioName));
        showwarning(wsprintfBuffer);
        end
     else
        begin
        // Fill the IP edit (130) from the first (or only) radio found.
        Windows.SetDlgItemText(hwnddlg, 130,
           PChar(PK4DiscoveredRadio(radios[0])^.IPAddress));
        // Issue #968 -- discovery gives us the IP but not the port; fill the
        // model default (K4 -> 9200) so the radio is immediately connectable.
        ApplyDefaultNetworkPort(hwnddlg);
        if radios.Count > 1 then
           begin
           Format(wsprintfBuffer, TC_DISCOVER_MULTI_FOUND, PChar(radioName));
           msg := string(wsprintfBuffer) + #13#10;
           for i := 0 to radios.Count - 1 do
              msg := msg + #13#10 +
                 TK4Discovery.Hostname(PK4DiscoveredRadio(radios[i])^) + '  (' +
                 PK4DiscoveredRadio(radios[i])^.IPAddress + ')';
           showwarning(PChar(msg));
           end;
        end;
  finally
     for i := 0 to radios.Count - 1 do
        Dispose(PK4DiscoveredRadio(radios[i]));
     radios.Free;
  end;
end;

function CATDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  i, I2                                 : integer;
  BRT                                   : BaudRateType;
  TempKeyerPortType                     : PortType;
//  TempByte                              : Byte;
  TempPchar                             : PChar;
  RadioType                             : InterfacedRadioType;
  hamLibCheckBoxWind                    : HWnd;
  LabelX, LabelW, EditX, EditW, NewY   : Integer;
  Rect111, Rect131, HamLibCheckRect, RectIP : TRect;
  ptTemp                                : TPoint;
  DlgWindowRect                         : TRect;
  hDiscoverBmp                          : HBITMAP;
  hDiscoverBtn                          : HWND;

  procedure ButtonsEnable;
  begin
    EnableWindowTrue(hwnddlg, 117);
    EnableWindowTrue(hwnddlg, 118);
  end;

  // Move a dialog control down by DY screen pixels.
  // Used to shift the CW/PTT section down when Icom credential rows are inserted.
  procedure MoveCtrlDown(CtrlId: Integer; DY: Integer);
  var
     R: TRect;
     P: TPoint;
  begin
     GetWindowRect(GetDlgItem(hwnddlg, CtrlId), R);
     P.x := R.Left;
     P.y := R.Top;
     Windows.ScreenToClient(hwnddlg, P);
     SetWindowPos(GetDlgItem(hwnddlg, CtrlId), 0,
        P.x, P.y + DY, 0, 0,
        SWP_NOSIZE or SWP_NOZORDER);
  end;

  // Show NETWORK USERNAME/PASSWORD fields only when port is TCP/IP
  // AND the selected radio is a network model that requires credentials.
  // Issue #904 -- renamed from "Icom credentials"; same fields cover
  // Kenwood TS-890 (Issue #436) and any future credentialed network radio.
  procedure UpdateNetworkCredentialsVisibility;
  var
     RadioIdx, PortIdx, ShowCmd: Integer;
  begin
     RadioIdx := tCB_GETCURSEL(hwnddlg, 121);
     PortIdx   := tCB_GETCURSEL(hwnddlg, 122);
     if (PortIdx = 21) and  // 21 = TCP/IP in the port combo
        (InterfacedRadioType(RadioIdx) in
         [IC705, IC7300MK2, IC7600, IC7610,
          IC7760, IC7850, IC7851, IC9700, IC905,
          TS890])  // Issue #436 -- TS-890 LAN requires Admin ID/Password
     then
        ShowCmd := SW_SHOW
     else
        ShowCmd := SW_HIDE;
     ShowWindow(GetDlgItem(hwnddlg, 112), ShowCmd);
     ShowWindow(GetDlgItem(hwnddlg, 113), ShowCmd);
     ShowWindow(GetDlgItem(hwnddlg, 132), ShowCmd);
     ShowWindow(GetDlgItem(hwnddlg, 133), ShowCmd);
  end;
begin

  Result := False;
  case Msg of
    WM_INITDIALOG:

      begin
//        CATWTR := RadioPtr(lParam);
        if CATWTR = @Radio1 then
        begin
          TempKeyerPortType := Radio1.tKeyerPort;
          TempPchar := 'RADIO ONE ';
        end;

        if CATWTR = @Radio2 then
        begin
          TempKeyerPortType := Radio2.tKeyerPort;
          TempPchar := 'RADIO TWO ';
        end;
        SetWindowText(hwnddlg, TempPchar);

        {radio}
		for RadioType := Low(InterfacedRadioType) to High(InterfacedRadioType) do
        //for RadioType := NoInterfacedRadio to Orion do
          tCB_ADDSTRING(hwnddlg, 121, InterfacedRadioTypeSA[RadioType]);

        for I2 := 122 to 123 do
        begin
          tCB_ADDSTRING(hwnddlg, I2, 'NONE');
          for i := 1 to 20 do
          begin
            Format(@TempBuffer1, 'SERIAL %u',i);
            tCB_ADDSTRING_PCHAR(hwnddlg, I2, TempBuffer1);
          end;

        end;
       // Format(@TempBuffer1, 'TCP/IP');
        tCB_AddSTRING_PCHAR(hwnddlg,122,'TCP/IP');
        for i := 1 to 3 do
          begin
            Format(@TempBuffer1, 'PARALLEL %u',i);
            tCB_ADDSTRING_PCHAR(hwnddlg, 123, TempBuffer1);
          end;
//          tCB_ADDSTRING(hwnddlg, 123, 'PARALLEL ' + IntToStr(i));

        for I2 := 124 to 125 do
          for i := 1 to 2 do
            tCB_ADDSTRING_PCHAR(hwnddlg, I2, RTS_DTR_Values_Array[i]);

        for I2 := 126 to 127 do
          for i := 1 to 4 do
            tCB_ADDSTRING_PCHAR(hwnddlg, I2, RTS_DTR_Values_Array[i]);

        for BRT := BR1200 to BR115200 do
          tCB_ADDSTRING_PCHAR(hwnddlg, 128, inttopchar(CAT_BAUDRATE_ARRAY[integer(BRT)]));

        // Create NETWORK USERNAME (label 112, edit 132) and NETWORK PASSWORD
        // (label 113, edit 133) dynamically. Positioned below control 131
        // (TCP port), sized to match. Used by Icom CI-V/IP, Kenwood TS-890,
        // and any future credentialed network radio (Issue #904).
        // The label prepend loop below will build the full command names.
        GetWindowRect(GetDlgItem(hwnddlg, 111), Rect111);
        GetWindowRect(GetDlgItem(hwnddlg, 131), Rect131);
        // LabelX: left edge of existing label column (from label 111)
        ptTemp.x := Rect111.Left;
        ptTemp.y := Rect111.Top;
        Windows.ScreenToClient(hwnddlg, ptTemp);
        LabelX := ptTemp.x;
        // EditX: left edge of edit column (from edit 131); also gives us NewY
        ptTemp.x := Rect131.Left;
        ptTemp.y := Rect131.Bottom;
        Windows.ScreenToClient(hwnddlg, ptTemp);
        EditX := ptTemp.x;
        EditW := Rect131.Right - Rect131.Left;
        NewY := ptTemp.y + 5;
        // LabelW spans from label left to edit left so the full text fits
        LabelW := EditX - LabelX - 5;
        GetWindowRect(hwnddlg, DlgWindowRect);
        SetWindowPos(hwnddlg, 0,
           DlgWindowRect.Left, DlgWindowRect.Top,
           DlgWindowRect.Right - DlgWindowRect.Left,
           DlgWindowRect.Bottom - DlgWindowRect.Top + 56,
           SWP_NOZORDER);
        // Short display text — saving is handled explicitly in RestartPollingThread.
        CreateStatic('NETWORK USERNAME', LabelX, NewY, LabelW, hwnddlg, 112);
        CreateEdit(ES_AUTOHSCROLL, EditX, NewY, EditW, 22, hwnddlg, 132);
        CreateStatic('NETWORK PASSWORD', LabelX, NewY + 28, LabelW, hwnddlg, 113);
        // ES_PASSWORD masks the text with bullets
        CreateEdit(ES_AUTOHSCROLL or ES_PASSWORD, EditX, NewY + 28, EditW, 22, hwnddlg, 133);

        // Issue #853: dynamic "Discover" button (ID 140), placed just to the
        // left of the IP-address edit (control 130, which lives in the dialog
        // resource), in the gap after the label.  Runs network discovery for the
        // selected radio type and fills in the IP.  Enabled only for network
        // radios -- see the cat-port enable blocks below.
        GetWindowRect(GetDlgItem(hwnddlg, 130), RectIP);
        ptTemp.x := RectIP.Left;
        ptTemp.y := RectIP.Top;
        Windows.ScreenToClient(hwnddlg, ptTemp);
        // Show the radar-sweep glyph (BITMAP resource 853, imported into each
        // tr4w_<lang>.res).  If the bitmap is not in the linked resources, fall
        // back to a '?' caption so the button still works before the import.
        hDiscoverBmp := LoadBitmap(hInstance, MAKEINTRESOURCE(853));
        if hDiscoverBmp <> 0 then
           begin
           hDiscoverBtn := CreateButton(BS_PUSHBUTTON or BS_BITMAP, '',
              ptTemp.x - 26, ptTemp.y, 22, hwnddlg, 140);
           Windows.SendMessage(hDiscoverBtn, BM_SETIMAGE, IMAGE_BITMAP,
              Integer(hDiscoverBmp));
           end
        else
           begin
           hDiscoverBtn := CreateButton(BS_PUSHBUTTON, '?', ptTemp.x - 26, ptTemp.y, 22, hwnddlg, 140);
           end;

        // Hover tooltip for the Discover button (hardcoded for now -- a
        // TC_TOOLTIP_DISCOVERY resource string can replace the literal later).
        CreateToolTip(hDiscoverBtn, TC_TOOLTIP_DISCOVERY{'Discover radios on the network'});

        // The dialog was expanded 56px to make room for the two Icom credential
        // rows (USERNAME + PASSWORD), inserted at the position of the HamLib
        // checkbox. Without adjustment, the credential rows cover the checkbox
        // and the CW/PTT section overlaps the checkbox when moved.
        //
        // Fix: move the HamLib checkbox and every control at or below the
        // CW/PTT group box down by 56px, and expand the CAT group box height
        // by 56px to keep the checkbox inside the CAT frame visually.

        // Expand the CAT group box (ID 90) to contain USE HAMLIB after it moves.
        GetWindowRect(GetDlgItem(hwnddlg, 90), HamLibCheckRect);
        ptTemp.x := HamLibCheckRect.Left;
        ptTemp.y := HamLibCheckRect.Top;
        Windows.ScreenToClient(hwnddlg, ptTemp);
        SetWindowPos(GetDlgItem(hwnddlg, 90), 0,
           ptTemp.x, ptTemp.y,
           HamLibCheckRect.Right - HamLibCheckRect.Left,
           HamLibCheckRect.Bottom - HamLibCheckRect.Top + 56,
           SWP_NOZORDER);

        // Move USE HAMLIB checkbox below the PASSWORD row.
        MoveCtrlDown(1000, 56);

        // Move CW/PTT group box (91) and all its labels, combos,
        // plus the Name row and the four buttons below it, down 56px.
        // These IDs come from dialog resource 66 (tr4w_eng.rc):
        //   91            CW/PTT group box
        //   103/123       Output Port label + combo
        //   106/126       Keyer RTS label + combo
        //   107/127       Keyer DTR label + combo
        //   109/129       Name label + edit
        //   116-119       Reset / OK / Close / Apply buttons
        MoveCtrlDown(91,  56);
        MoveCtrlDown(103, 56);
        MoveCtrlDown(123, 56);
        MoveCtrlDown(106, 56);
        MoveCtrlDown(126, 56);
        MoveCtrlDown(107, 56);
        MoveCtrlDown(127, 56);
        MoveCtrlDown(109, 56);
        MoveCtrlDown(129, 56);
        MoveCtrlDown(116, 56);
        MoveCtrlDown(117, 56);
        MoveCtrlDown(118, 56);
        MoveCtrlDown(119, 56);

        for i := 101 to 111 do
           begin
           tCB_SETCURSEL(hwnddlg, i + 20, 0);
           Windows.GetDlgItemText(hwnddlg, i, TempBuffer1, SizeOf(TempBuffer1));
           Format(wsprintfBuffer, '%s%s', TempPchar, TempBuffer1);         // This prepends RADIO ONE or RADIO TWO.
           if i = 103 then
              Format(wsprintfBuffer, 'KEYER %s%s', TempPchar, TempBuffer1);
           Windows.SetDlgItemText(hwnddlg, i, wsprintfBuffer);
           end;

        i := 1000;
        Windows.GetDlgItemText(hwnddlg, i, TempBuffer1, SizeOf(TempBuffer1));
        Format(wsprintfBuffer, '%s%s', TempPchar, TempBuffer1);         // This prepends RADIO ONE or RADIO TWO.
        Windows.SetDlgItemText(hwnddlg, i, wsprintfBuffer);


        {radio type}
        tCB_SETCURSEL(hwnddlg, 121, Ord(CATWTR^.RadioModel));

        {keyer port}
        tCB_SETCURSEL(hwnddlg, 123, Ord(TempKeyerPortType));

        {cat port}
        tCB_SETCURSEL(hwnddlg, 122, Ord(CATWTR^.tCATPortType));
        if (CATWTR^.tCATPortType = NETWORK) then
           begin
           EnableWindowTrue(hwnddlg, 130);
           EnableWindowTrue(hwnddlg, 140);
           EnableWindowTrue(hwnddlg, 131);
           EnableWindowTrue(hwnddlg, 132);
           EnableWindowTrue(hwnddlg, 133);
           EnableWindowFalse(hwnddlg, 124);
           EnableWindowFalse(hwnddlg, 125);
           EnableWindowFalse(hwnddlg, 128);
           end
        else
           begin
           EnableWindowTrue(hwnddlg, 124);
           EnableWindowTrue(hwnddlg, 125);
           EnableWindowTrue(hwnddlg, 128);
           EnableWindowFalse(hwnddlg, 130);
           EnableWindowFalse(hwnddlg, 140);
           EnableWindowFalse(hwnddlg, 131);
           EnableWindowFalse(hwnddlg, 132);
           EnableWindowFalse(hwnddlg, 133);
           end;

        {keyer_rts}
        tCB_SETCURSEL(hwnddlg, 126, Ord(CATWTR^.tr4w_keyer_rts_state) - 1);

        {keyer_dtr}
        tCB_SETCURSEL(hwnddlg, 127, Ord(CATWTR^.tr4w_keyer_DTR_state) - 1);

        {cat_rts}
        tCB_SETCURSEL(hwnddlg, 124, Ord(CATWTR^.tr4w_cat_rts_state) - 1);

        {cat_dtr}
        tCB_SETCURSEL(hwnddlg, 125, Ord(CATWTR^.tr4w_cat_dtr_state) - 1);

        for BRT := BR1200 to BR115200 do
          if CATWTR^.RadioBaudRate = CAT_BAUDRATE_ARRAY[integer(BRT)] then
            tCB_SETCURSEL(hwnddlg, 128, Cardinal(brt));
        {freq adder}

//        Windows.SetDlgItemInt(hwnddlg, 129, TempRadio^.FrequencyAdder, False);
        Windows.SetDlgItemText(hwnddlg, 129, PChar(string(CATWTR^.RadioName)));

        Windows.SetDlgItemText(hwnddlg, 130, PChar(string(CATWTR^.IPAddress)));
        Windows.SetDlgItemInt(hwnddlg, 131, CATWTR^.RadioTCPPort, False);
        Windows.SetDlgItemText(hwnddlg, 132, PChar(string(CATWTR^.NetworkUsername)));
        Windows.SetDlgItemText(hwnddlg, 133, PChar(string(CATWTR^.NetworkPassword)));
        hamLibCheckBoxWind := GetDlgItem(hwnddlg, 1000);

        if RadioType in HAMLibONLYRadios then
           begin
           if not CATWTR^.UseHamLib then
              begin
              logger.Info('Setting UseHamLib to true because radioModel is a Hamlib only radio');
              CATWTR^.UseHamLib := true;
              end;
           end;

        if CATWTR^.UseHamLib then
           begin
           Windows.SendDlgItemMessage(hwnddlg, 1000, BM_SETCHECK, BST_CHECKED, 0);
           end;
        UpdateNetworkCredentialsVisibility;
        EnableWindowFalse(hwnddlg, 117);
        EnableWindowFalse(hwnddlg, 118);
      end;

    WM_COMMAND:
      begin
        if (HiWord(wParam) = CBN_SELCHANGE)
          or (HiWord(wParam) = EN_CHANGE)
          then
        begin
          ButtonsEnable;
          if LoWord(wParam) = 122 then   // 122 is port type (serial, network, etc).
             begin
             i := tCB_GETCURSEL(hwnddlg, 122);
             if i = 21 then     // Network
                begin
                EnableWindowTrue(hwnddlg, 130);
                EnableWindowTrue(hwnddlg, 140);
                EnableWindowTrue(hwnddlg, 131);
                EnableWindowTrue(hwnddlg, 132);
                EnableWindowTrue(hwnddlg, 133);
                EnableWindowFalse(hwnddlg,124);
                EnableWindowFalse(hwnddlg,125);
                EnableWindowFalse(hwnddlg,128);
                ApplyDefaultNetworkPort(hwnddlg);   // Issue #968 -- default port on switch to Network
                end
             else
                begin
                EnableWindowTrue(hwnddlg, 124);
                EnableWindowTrue(hwnddlg, 125);
                EnableWindowTrue(hwnddlg, 128);
                EnableWindowFalse(hwnddlg,130);
                EnableWindowFalse(hwnddlg,140);
                EnableWindowFalse(hwnddlg,131);
                EnableWindowFalse(hwnddlg,132);
                EnableWindowFalse(hwnddlg,133);
               end;
             UpdateNetworkCredentialsVisibility;
             end;
          if LoWord(wParam) = 121 then
          begin
            i := tCB_GETCURSEL(hwnddlg, 121);
            tCB_SETCURSEL(hwnddlg, 128, Cardinal(RadioParametersArray[InterfacedRadioType(i)].br));
            UpdateNetworkCredentialsVisibility;
            ApplyDefaultNetworkPort(hwnddlg);   // Issue #968 -- default port when the radio type changes
{
            I := tCB_GETCURSEL(hwnddlg, 121);
            TempByte := 2;
            if (I >= Ord(IC706)) and (I <= Ord(IC7800)) then TempByte := 0;
            if I = Ord(Orion) then TempByte := 6;
            tCB_SETCURSEL(hwnddlg, 128, TempByte);
}
          end;

        end;
        case wParam of
          2, 119: goto 1;
          117: {Apply}
            begin
              EnableWindowFalse(hwnddlg, 117);
              EnableWindowFalse(hwnddlg, 118);
              RestartPollingThread(hwnddlg);
            end;
          118: {OK}
            begin
              RestartPollingThread(hwnddlg);
              goto 1;
            end;

          116:

            begin
            
              for i := 121 to 128 do tCB_SETCURSEL(hwnddlg, i, 0);
              tCB_SETCURSEL(hwnddlg, 128, 2);
              tCB_SETCURSEL(hwnddlg, 126, 3);
              tCB_SETCURSEL(hwnddlg, 127, 2);
              ButtonsEnable;
            end;

          140: {Discover -- Issue #853}
            RunNetworkDiscoveryForRadio(hwnddlg);

          1000:
             begin
             ButtonsEnable;
             // Warn if user is enabling HamLib for a radio that TR4W supports natively.
             // HamLib polling on natively-supported radios causes excessive CI-V traffic
             // that interferes with front-panel operation. Allow it but make the tradeoff clear.
             if boolean(TF.SendDlgItemMessage(hwnddlg, 1000, BM_GETCHECK)) then
                begin
                if not (InterfacedRadioType(tCB_GETCURSEL(hwnddlg, 121)) in HAMLibONLYRadios) then
                   begin
                   MessageBox(hwnddlg,
                     'This radio has native TR4W support. Using HamLib is not recommended.' + #13#10 +
                     #13#10 +
                     'RIT and XIT status will update every 5 seconds due to the HamLib implementation on certain (Icom) rigs.' + #13#10 +
                     #13#10 +
                     'Querying RIT/XIT requires a physical VFO select command that could ' +
                     'interfere with front-panel operations.' + #13#10 +
                     #13#10 +
                     'All other values (frequency, mode, PTT, split) update every second.' + #13#10 +
                     #13#10 +
                     'Check this option only if you have a specific reason to use HamLib.',
                     'HamLib Not Recommended for This Radio',
                     MB_OK or MB_ICONWARNING);
                   end;
                end;
             end;
        end;
      end;

    WM_CLOSE: 1: EndDialog(hwnddlg, 0);
  end;
end;

procedure CloseCATAndKeyerForThisRadio;
begin
  IcomResponseTimeout := 0;
  {Close CAT Port}
  if CATWTR^.tCATPortType in [Serial1..Serial20] then
     begin
     if CPUKeyer.SerialPortConfigured_Handle[CATWTR^.tCATPortType] <> INVALID_HANDLE_VALUE then
        begin
        Windows.CloseHandle(CPUKeyer.SerialPortConfigured_Handle[CATWTR^.tCATPortType]);
        CPUKeyer.SerialPortConfigured_Handle[CATWTR^.tCATPortType] := INVALID_HANDLE_VALUE;
        end;
     end
  else if CATWTR^.tCATPortType = Network then
     begin
     if (CATWTR^.tNetObject <> nil) and CATWTR^.tNetObject.IsConnected then
        begin
        CATWTR^.tNetObject.Disconnect;
        end;
     end;
  CATWTR^.tCATPortHandle := INVALID_HANDLE_VALUE;

  {Close Keyer Port}
  if CATWTR^.tKeyerPort in [Serial1..Serial20] then
    if CPUKeyer.SerialPortConfigured_Handle[CATWTR^.tKeyerPort] <> INVALID_HANDLE_VALUE then
    begin
      Windows.CloseHandle(CPUKeyer.SerialPortConfigured_Handle[CATWTR^.tKeyerPort]);
      CPUKeyer.SerialPortConfigured_Handle[CATWTR^.tKeyerPort] := INVALID_HANDLE_VALUE;
    end;
  CATWTR^.tKeyerPortHandle := INVALID_HANDLE_VALUE;

  //  if (RadioToClose^.tr4w_KeyerPort >= Parallel1) and (RadioToClose^.tr4w_KeyerPort <= Parallel3) then    DestroyDlPortio;

end;

procedure RestartPollingThread(CATWndHWND: HWND);
var
  lpExitCode                            : DWORD;
  i                                     : integer;
  ID, CMD                               : ShortString;
begin

{ TODO: The radio settings changed so restart the thread. If there was a network connection, we have to disconnect and clean that up.
Otherwise, we have to start that up.
}

if (CATWTR^.tCATPortHandle <> INVALID_HANDLE_VALUE) or
   (CATWTR^.tCATPortType = Network)                 then
  begin

    GetExitCodeThread(CATWTR^.tRadioInterfaceThreadHandle, lpExitCode);
    Windows.TerminateThread(CATWTR^.tRadioInterfaceThreadHandle, lpExitCode);
    logger.Info('Terminated Radio %s thread',[CATWTR^.RadioName] );
//    if CPUKeyer.SerialPortDebug then CloseCATDebugFile(CATWTR^.tCATPortType);
    CloseCATAndKeyerForThisRadio;
  end;

  { Labels 101-111 come from the resource file. Value controls have IDs = label
    ID + 20 (121-131). The label text (already prefixed with "RADIO ONE/TWO "
    at init) is used as the config command name passed to CheckCommand.
    Username (132) and password (133) are saved explicitly below.
    }
  for i := 101 to 111 do
  begin
    Windows.ZeroMemory(@ID, SizeOf(ID));
    Windows.ZeroMemory(@CMD, SizeOf(CMD));
    ID := GetDialogItemText(CATWndHWND, i);
    CMD := GetDialogItemText(CATWndHWND, i + 20);
    logger.Trace('[RestartPollingThread] ID = %s, CMD = %s',[ID, CMD]);
    Windows.WritePrivateProfileString('Radio', @ID[1], @CMD[1], TR4W_INI_FILENAME);
//    if not
    CheckCommand(@ID, CMD)
//    then      showwarning(@id[1])
    ;
  end;
  // This handles a checkbox for USE HAMLIB but could be used for any checkbox configuration item. ny4i
  i := 1000;
  Windows.ZeroMemory(@ID, SizeOf(ID));
  Windows.ZeroMemory(@CMD, SizeOf(CMD));
  ID := GetDialogItemText(CATWndHWND, i);
  if boolean(TF.SendDlgItemMessage(CATWndHWND, i, BM_GETCHECK)) then
     begin
     CMD := 'TRUE';
     end
  else
     begin
     CMD := 'FALSE';
     end;

  logger.Trace('[RestartPollingThread] ID = %s, CMD = %s',[ID, CMD]);
  Windows.WritePrivateProfileString('Radio', @ID[1], @CMD[1], TR4W_INI_FILENAME);
  CheckCommand(@ID, CMD);


  // Save NETWORK USERNAME (control 132) and PASSWORD (control 133)
  // explicitly -- these use short display labels, so command names are hardcoded.
  // Issue #904: write the canonical NETWORK names; migrate legacy
  // "ICOM NETWORK ..." keys by deleting them (CFGCA still parses the old
  // names from any .cfg / .ini files that still have them).
  Windows.ZeroMemory(@ID, SizeOf(ID));
  Windows.ZeroMemory(@CMD, SizeOf(CMD));
  if CATWTR = @Radio1 then
     ID := 'RADIO ONE NETWORK USERNAME'
  else
     ID := 'RADIO TWO NETWORK USERNAME';
  CMD := GetDialogItemText(CATWndHWND, 132);
  Windows.WritePrivateProfileString('Radio', @ID[1], @CMD[1], TR4W_INI_FILENAME);
  CheckCommand(@ID, CMD);
  // Delete the legacy ICOM NETWORK USERNAME key (nil value = delete).
  if CATWTR = @Radio1 then
     ID := 'RADIO ONE ICOM NETWORK USERNAME'
  else
     ID := 'RADIO TWO ICOM NETWORK USERNAME';
  Windows.WritePrivateProfileString('Radio', @ID[1], nil, TR4W_INI_FILENAME);

  Windows.ZeroMemory(@ID, SizeOf(ID));
  Windows.ZeroMemory(@CMD, SizeOf(CMD));
  if CATWTR = @Radio1 then
     ID := 'RADIO ONE NETWORK PASSWORD'
  else
     ID := 'RADIO TWO NETWORK PASSWORD';
  CMD := GetDialogItemText(CATWndHWND, 133);
  Windows.WritePrivateProfileString('Radio', @ID[1], @CMD[1], TR4W_INI_FILENAME);
  CheckCommand(@ID, CMD);
  // Delete the legacy ICOM NETWORK PASSWORD key.
  if CATWTR = @Radio1 then
     ID := 'RADIO ONE ICOM NETWORK PASSWORD'
  else
     ID := 'RADIO TWO ICOM NETWORK PASSWORD';
  Windows.WritePrivateProfileString('Radio', @ID[1], nil, TR4W_INI_FILENAME);

  CATWTR^.CheckAndInitializePorts_ForThisRadio;
  InitializeKeyer;
//  tActiveKeyerHandle := ActiveRadioPtr.tKeyerPortHandle;
  DisplayRadio(ActiveRadio);
end;

end.

