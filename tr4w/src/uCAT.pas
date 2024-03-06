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
  Tree;

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

  procedure ButtonsEnable;
  begin
    EnableWindowTrue(hwnddlg, 117);
    EnableWindowTrue(hwnddlg, 118);
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
           EnableWindowTrue(hwnddlg, 131);
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
           EnableWindowFalse(hwnddlg, 131);
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
                EnableWindowTrue(hwnddlg, 131);
                EnableWindowFalse(hwnddlg,124);
                EnableWindowFalse(hwnddlg,125);
                EnableWindowFalse(hwnddlg,128);
                end
             else
                begin
                EnableWindowTrue(hwnddlg, 124);
                EnableWindowTrue(hwnddlg, 125);
                EnableWindowTrue(hwnddlg, 128);
                EnableWindowFalse(hwnddlg,130);
                EnableWindowFalse(hwnddlg,131);
               end;
             end;
          if LoWord(wParam) = 121 then
          begin
            i := tCB_GETCURSEL(hwnddlg, 121);
            tCB_SETCURSEL(hwnddlg, 128, Cardinal(RadioParametersArray[InterfacedRadioType(i)].br));
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

          1000:
             begin
             ButtonsEnable;
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
     if CATWTR^.tNetObject.IsConnected then
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

  { In the resource file, the labels are 101 - 111. The value controls have an ID of 20 greater.
    This code loops around based on the ID of the label and grabs the value to store it to the INI file.

    The plot thickens... I found out that the name of the label on the form is added to RADIO ONE|TWO and that is what creates
    the name that is written to the config file.
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


  CATWTR^.CheckAndInitializePorts_ForThisRadio;
  InitializeKeyer;
//  tActiveKeyerHandle := ActiveRadioPtr.tKeyerPortHandle;
  DisplayRadio(ActiveRadio);
end;

end.

