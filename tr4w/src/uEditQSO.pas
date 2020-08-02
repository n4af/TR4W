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
unit uEditQSO;

{$IMPORTEDDATA OFF}

(* ---------- I M P O R T A N T    Form is in the RES file -------------------*)
interface

uses
//  shellapi,
  uCTYDAT,
  uMP3Recorder,
  uStations,
  WinSock2,
  uNet,
  TF,
  VC,
  //Country9,
  Windows,
  uCallSignRoutines,
  utils_file,
  LogCW,
  uTotal,
  Tree,
  LOGSUBS1,
  LOGSUBS2,
  LogDupe,
  LogStuff,
  uCommctrl,
  ZoneCont,
  LogK1EA,
  LogEdit,
  LogWind,
  Messages
  ;

function EditQSODlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;

procedure OpenEditQSOWindow(Parent: HWND);
function SaveQSOToEditableLog: boolean;
function CheckSystemTimeRecord(Time: TQSOTime): boolean;
procedure ShowNote(CE: ContestExchange);
procedure MakeEditWindows;
procedure MakeEditWindow(Caption: PChar; FType: CFGType; ValueAdr: Pointer);
//procedure ShowSysMonthCal32(show: integer);

const
  FLD_FREQUENCY                         = 106;
  FLD_RSTRECEIVED                       = 108;
  FLD_BAND                              = 112;
  FLD_MODE                              = 113;
  FLD_RADIO                             = 114;
  FLD_COUNTRYNAME                       = 115;
  FLD_NUMBERSEND                        = 116;

  FLD_COMPUTERID                        = 117;
  FLD_CALLSIGN                          = 118;
  FLD_RSTSEND                           = 119;
  FLD_TENTENNUM                         = 120;
  FLD_PREFECTURE                        = 121;
  FLD_QSOPOINTS                         = 122;

  FLD_SAVE_BUTTON                       = 123;
  FLD_CANCEL_BUTTON                     = 124;
  FLD_PLAY_BUTTON                       = 201;

  FLD_SAP                               = 125;

  FLD_ZONEMULT                          = 126;
  FLD_PREFIXMULT                        = 127;
  FLD_DOMESTICMULT                      = 129;
  FLD_DUPE                              = 130;
  FLD_DELETED                           = 132;
  FLD_CLASS                             = 133;
  FLD_AGE                               = 136;
  FLD_CHAPTER                           = 138;
  FLD_CHECK                             = 141;
  FLD_PRECEDENCE                        = 142;
  FLD_INHIBITMULTS                      = 143;
  FLD_POWER                             = 144;
  FLD_NUMBERRECEIVED                    = 146;
  FLD_DXQTH                             = 148;
  FLD_DOMMULTQTH                        = 150;
  FLD_PREFIX                            = 152;
  FLD_ZONE                              = 154;
  FLD_DXMULT                            = 156;
  FLD_NAME                              = 158;
  FLD_QTHSTRING                         = 160;
  FLD_POSTALCODE                        = 162;
{
  FLD_HOUR                              = 180;
  FLD_MINUTE                            = 181;
  FLD_SECOND                            = 182;
  FLD_DAY                               = 183;
  FLD_MONTH                             = 184;
  FLD_YEAR                              = 185;
}

//  SETLIMITTEXTARRAY           : array[0..3] of integer;
var
  eq_handle                             : HWND;
  EditableQSORXData                     : ContestExchange;
  CurrentEditRow                        : integer;
//const  eqMultsArray                          : array[1..5] of PBoolean = (nil, nil, nil, nil, nil);

implementation
uses
  MainUnit,
  uLogEdit;

function EditQSODlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  TempString {, DString}                : ShortString;
  bt                                    : BandType;
  mt                                    : ModeType;
  extMode                               : ExtendedModeType;
  IndexInMap                            : integer;
  lpNumberOfBytesRead                   : Cardinal;
//  w                                     : Word;
//  TempInteger                           : integer;
  TempSysTime                           : SYSTEMTIME;
const
  f                                     = 'HH:mm dd-MM-yyyy';
begin
  Result := False;
  case Msg of
{
    WM_CTLCOLORSTATIC:
      begin
        SetBkMode(HDC(wParam), TRANSPARENT);
        SetTextColor(HDC(wParam), $FFFFFF);
        RESULT := BOOL(tr4wBrushArray[trBlue]);
      end;
}
//    WM_HELP: tWinHelp(46);

    WM_INITDIALOG:
      begin
        eq_handle := hwnddlg;

        IndexInMap := IndexOfItemInLogForEdit;

        if not OpenLogFile then goto 1;

        tSetFilePointer(IndexInMap, FILE_BEGIN);
        Windows.ReadFile(LogHandle, EditableQSORXData, SizeOf(ContestExchange), lpNumberOfBytesRead, nil);
        CloseLogFile;

        if EditableQSORXData.ceRecordKind = rkNote then
        begin
          ShowNote(EditableQSORXData);
          goto 1;
        end;

        if EditableQSORXData.MP3Record then
          if FileExists(DeleteSlashes(MakeMP3Filename(@EditableQSORXData))) then
            EnableWindowTrue(hwnddlg, FLD_PLAY_BUTTON);

        if (EditableQSORXData.ceQSO_Skiped) or (EditableQSORXData.ceRecordKind <> rkQSO) then goto 1;

//        MakeEditWindows;
//        EditabledLogFocused := True;
        for IndexInMap := 180 to 184 do Windows.SendDlgItemMessage(hwnddlg, IndexInMap, EM_SETLIMITTEXT, 2, 0);
        {ComputerID}
        Windows.SendDlgItemMessage(hwnddlg, FLD_COMPUTERID, EM_SETLIMITTEXT, 1, 0);
        {Zone}
        Windows.SendDlgItemMessage(hwnddlg, FLD_ZONE, EM_SETLIMITTEXT, 2, 0);
        {RST}
        // Reset the form field to not be a number so the user can enter a negative
        //Windows.SetWindowLong(hwnddlg, FLD_RSTSENT,)
        Windows.SendDlgItemMessage(hwnddlg, FLD_RSTSEND, EM_SETLIMITTEXT, 3, 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_RSTRECEIVED, EM_SETLIMITTEXT, 3, 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_CALLSIGN, EM_SETLIMITTEXT, SizeOf(CallString) - 2, 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_AGE, EM_SETLIMITTEXT, 3, 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_TENTENNUM, EM_SETLIMITTEXT, 5, 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_PREFECTURE, EM_SETLIMITTEXT, 3, 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_PRECEDENCE, EM_SETLIMITTEXT, 1, 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_CHECK, EM_SETLIMITTEXT, 2, 0);

        Windows.SetDlgItemText(hwnddlg, FLD_CALLSIGN, @EditableQSORXData.Callsign[1]);

        for bt := Band160 to NoBand do tCB_ADDSTRING_PCHAR(hwnddlg, FLD_BAND, BandStringsArrayWithOutSpaces {BandStringsArray} [bt]);

        tCB_SETCURSEL(hwnddlg, FLD_BAND, Ord(EditableQSORXData.Band));

        // Add new modes from extended modes
        for extMode := Low(ExtendedModeType) to High(ExtendedModeType) do
           begin
           tCB_ADDSTRING_PCHAR(hwnddlg, FLD_MODE, PChar(ExtendedModeStringArray[extMode]));
           end;
        if EditableQSORXData.ExtMode = eNoMode then
           begin
           case EditableQSORXData.Mode of
              CW:EditableQSORXData.ExtMode := eCW;
              Phone: EditableQSORXData.ExtMode := eSSB;
              Digital: EditableQSORXData.ExtMode := eRTTY;
              FM: EditableQSORXData.ExtMode := eFM;
              end; // of case
           end; 

        tCB_SETCURSEL(hwnddlg, FLD_MODE, Ord(EditableQSORXData.ExtMode));

        {
        for mt := CW to FM do tCB_ADDSTRING_PCHAR(hwnddlg, FLD_MODE, ModeStringArray[mt]);  // NY4I to show extended modes

        //        if EditableQSORXData.ceFMMode then mt := FM else mt := EditableQSORXData.Mode;
        tCB_SETCURSEL(hwnddlg, FLD_MODE, Ord(EditableQSORXData.Mode));
        }
        tSetDlgItemIntFalse(hwnddlg, FLD_FREQUENCY, EditableQSORXData.Frequency);
{
        lpNumberOfBytesRead :=
          CreateWindowEx(0,
          'SysDateTimePick32',
          nil,
          WS_BORDER or WS_CHILD or WS_VISIBLE or DTS_UPDOWN,
          20, 50, 220, 20,
          hwnddlg,
          0,
          hInstance
          ,
          nil);
}
        SendDlgItemMessage(hwnddlg, 180, DTM_SETFORMAT, 0, integer(PChar(f)));

        Windows.ZeroMemory(@TempSysTime, SizeOf(TempSysTime));
        TempSysTime.wYear := EditableQSORXData.tSysTime.qtYear + 2000;
        TempSysTime.wMonth := EditableQSORXData.tSysTime.qtMonth;
        TempSysTime.wDay := EditableQSORXData.tSysTime.qtDay;

        TempSysTime.wHour := EditableQSORXData.tSysTime.qtHour;
        TempSysTime.wMinute := EditableQSORXData.tSysTime.qtMinute;
        TempSysTime.wSecond := EditableQSORXData.tSysTime.qtSecond;

        SendDlgItemMessage(hwnddlg, 180, DTM_SETSYSTEMTIME, GDT_VALID, integer(@TempSysTime));
{
        tSetDlgItemIntFalse(hwnddlg, FLD_DAY, EditableQSORXData.tSysTime.qtDay);
        tSetDlgItemIntFalse(hwnddlg, FLD_MONTH, EditableQSORXData.tSysTime.qtMonth);
        tSetDlgItemIntFalse(hwnddlg, FLD_YEAR, EditableQSORXData.tSysTime.qtYear + 2000);

        tSetDlgItemIntFalse(hwnddlg, FLD_HOUR, EditableQSORXData.tSysTime.qtHour);
        tSetDlgItemIntFalse(hwnddlg, FLD_MINUTE, EditableQSORXData.tSysTime.qtMinute);
        tSetDlgItemIntFalse(hwnddlg, FLD_SECOND, EditableQSORXData.tSysTime.qtSecond);

}
        CID_TWO_BYTES[0] := EditableQSORXData.ceComputerID;
        Windows.SetDlgItemText(hwnddlg, FLD_COMPUTERID, @CID_TWO_BYTES);

        Windows.SetDlgItemInt(hwnddlg, FLD_QSOPOINTS, Cardinal(EditableQSORXData.QSOPoints), True);

        if EditableQSORXData.Age <> 0 then
          tSetDlgItemIntFalse(hwnddlg, FLD_AGE, EditableQSORXData.Age);

        if EditableQSORXData.Check <> 0 then
          tSetDlgItemIntFalse(hwnddlg, FLD_CHECK, Cardinal(EditableQSORXData.Check));

        Windows.SetDlgItemText(hwnddlg, FLD_CHAPTER, @EditableQSORXData.Chapter[1]);
        Windows.SetDlgItemText(hwnddlg, FLD_CLASS, @EditableQSORXData.ceClass[1]);

        Windows.SendDlgItemMessage(hwnddlg, FLD_SAP, BM_SETCHECK, integer(EditableQSORXData.ceSearchAndPounce), 0);
        //            Windows.SendDlgItemMessage(hwnddlg, 125, BM_SETCHECK, integer(EditableQSORXData.tSearchAndPounce), 0);

        Windows.SendDlgItemMessage(hwnddlg, FLD_DELETED, BM_SETCHECK, integer(EditableQSORXData.ceQSO_Deleted), 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_DUPE, BM_SETCHECK, integer(EditableQSORXData.ceDupe), 0);

        Windows.SetDlgItemInt(hwnddlg, FLD_NUMBERSEND, Cardinal(EditableQSORXData.NumberSent), True);

        if EditableQSORXData.NumberReceived <> -1 then
          tSetDlgItemIntFalse(hwnddlg, FLD_NUMBERRECEIVED, EditableQSORXData.NumberReceived);

        SetDlgItemText(hwnddlg, 148, @EditableQSORXData.DXQTH[1]);

        //Windows.SetDlgItemText(hwnddlg, 150, @EditableQSORXData.DomMultQTH[1]);
        SetDlgItemText(hwnddlg, FLD_DOMMULTQTH, @EditableQSORXData.DomMultQTH[1]);

        //Windows.SetDlgItemText(hwnddlg, 152, @EditableQSORXData.Prefix[1]);
        SetDlgItemText(hwnddlg, FLD_PREFIX, @EditableQSORXData.Prefix[1]);

        if EditableQSORXData.Zone <> DUMMYZONE then
          Windows.SetDlgItemText(hwnddlg, FLD_ZONE, inttopchar(EditableQSORXData.Zone));

        Windows.SetDlgItemText(hwnddlg, FLD_NAME, @EditableQSORXData.Name[1]);
        //tSetDlgItemTypText(hwnddlg, FLD_NAME, @EditableQSORXData.Name);

        //Windows.SetDlgItemText(hwnddlg, 160, PChar(string(EditableQSORXData.QTHString)));
        SetDlgItemText(hwnddlg, FLD_QTHSTRING, @EditableQSORXData.QTHString[1]);

        //Windows.SetDlgItemText(hwnddlg, 162, @EditableQSORXData.PostalCode[1]);
        //SetDlgItemText(hwnddlg, FLD_POSTALCODE, @EditableQSORXData.PostalCode[1]);

        SetDlgItemText(hwnddlg, FLD_POWER, @EditableQSORXData.Power[1]);

        CID_TWO_BYTES[0] := EditableQSORXData.Precedence;
        Windows.SetDlgItemText(hwnddlg, FLD_PRECEDENCE, @CID_TWO_BYTES);

        if EditableQSORXData.Prefecture <> MAXBYTE then
          Windows.SetDlgItemText(hwnddlg, FLD_PREFECTURE, inttopchar(EditableQSORXData.Prefecture));

        if EditableQSORXData.TenTenNum <> MAXWORD then
          Windows.SetDlgItemText(hwnddlg, FLD_TENTENNUM, inttopchar(EditableQSORXData.TenTenNum));

        tSetDlgItemIntSigned(hwnddlg, FLD_RSTSEND, EditableQSORXData.RSTSent);
        tSetDlgItemIntSigned(hwnddlg, FLD_RSTRECEIVED, EditableQSORXData.RSTReceived);

        Windows.SendDlgItemMessage(hwnddlg, FLD_INHIBITMULTS, BM_SETCHECK, integer(EditableQSORXData.InhibitMults), 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_DXMULT, BM_SETCHECK, integer(EditableQSORXData.DXMult), 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_DOMESTICMULT, BM_SETCHECK, integer(EditableQSORXData.DomesticMult), 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_PREFIXMULT, BM_SETCHECK, integer(EditableQSORXData.PrefixMult), 0);
        Windows.SendDlgItemMessage(hwnddlg, FLD_ZONEMULT, BM_SETCHECK, integer(EditableQSORXData.ZoneMult), 0);

        if EditableQSORXData.ceRadio = RadioTwo then Windows.SetDlgItemText(hwnddlg, FLD_RADIO, 'RADIO TWO');

        EnableWindowFalse(hwnddlg, FLD_SAVE_BUTTON);
        Windows.SetFocus(GetDlgItem(hwnddlg, FLD_CALLSIGN));
        SendDlgItemMessage(hwnddlg, FLD_CALLSIGN, EM_SETSEL, 16, 16); //в конец

      end;

    WM_NOTIFY: //with PNMHdr(lParam)^ do
      if PNMHdr(lParam)^.code =
        DTN_DATETIMECHANGE then EnableWindowTrue(hwnddlg, FLD_SAVE_BUTTON);

    WM_COMMAND:
      begin
        case wParam of
          {
                    114:
                      begin
                        SendEditedQSOToNetwork(EditableQSORXData);
                        EnableWindowFalse(hwnddlg, 114);
                      end;
          }

          FLD_PLAY_BUTTON:
            begin
              if TR4W_MP3_PLAYER_FILENAME[0] = #0 then
              begin
                SetCommand('MP3 PLAYER');
                Exit;
              end;

              Format(wsprintfBuffer, '"%s" "%s"', TR4W_MP3_PLAYER_FILENAME, DeleteSlashes(MakeMP3Filename(@EditableQSORXData)));
//                wsprintf(wsprintfBuffer, '"E:\Program Files\Windows Media Player\wmplayer.exe" "%s"');

              Windows.WinExec(wsprintfBuffer, SW_SHOWNORMAL);
            end;

          FLD_CANCEL_BUTTON, 2: goto 1;
          FLD_SAVE_BUTTON:
            begin
              if SaveQSOToEditableLog then goto 1;
            end;
        end;

        if ((HiWord(wParam) = EN_CHANGE)) and (LoWord(wParam) = FLD_CALLSIGN) then
        begin
          TempString := GetDialogItemText(hwnddlg, FLD_CALLSIGN);
          Windows.ZeroMemory(@EditableQSORXData.QTH, SizeOf(EditableQSORXData.QTH));
          ctyLocateCall(TempString, EditableQSORXData.QTH);

          if DoingPrefixMults then
          begin
            Windows.ZeroMemory(@EditableQSORXData.Prefix, SizeOf(EditableQSORXData.Prefix));
            SetPrefix(EditableQSORXData);
            Windows.SetDlgItemText(eq_handle, FLD_PREFIX, @EditableQSORXData.Prefix[1])
          end;

          Windows.SetDlgItemText(hwnddlg, FLD_COUNTRYNAME, ctyGetCountryNamePchar(ctyGetCountry(TempString)));

          if ActiveDXMult <> NoDXMults then
            Windows.SetDlgItemText(hwnddlg, FLD_DXQTH, @EditableQSORXData.QTH.CountryID[1]);
        end;

        case HiWord(wParam) of
          EN_CHANGE, CBN_EDITUPDATE, CBN_SELCHANGE, BN_CLICKED:
            begin
              if HiWord(wParam) = BN_CLICKED then
              begin
//                wParam := 0;
//                RESULT := True;
//                exit;
//                asm
//                nop
//                end;
              end;
              //              if LoWord(wParam) <> 114 then

              EnableWindowTrue(hwnddlg, FLD_SAVE_BUTTON);
            end;
          {
                    CBN_DROPDOWN:
                      if LoWord(wParam) = 114 then
                      begin
                                  //                        Windows.ShowWindow(GetDlgItem(hwnddlg, 200), 1);
                        if SysMonthCal32Visible then ShowSysMonthCal32(0) else ShowSysMonthCal32(1);

                      end;
          }
        end;
      end;
    //    WM_LBUTTONDOWN: ShowSysMonthCal32(0);

    WM_CLOSE: 1:
      begin
//        EditabledLogFocused := False;
//  ActiveMainWindow = awExchangeWindow;
        EndDialog(hwnddlg, 0);
        tCallWindowSetFocus;
        //        LogEnsureVisible;
      end;

  end;
end;

{
One notable thing missing from this code below is validation. A few items such as
CALLSIGN are checked but not items like QTH. I can edit a record to make the
state WC or the ARRl section WSX (both invalid). Considering we are editing
the current contest, it seems reasonable to add code to validate the edit
just like when the contact was first entered.
I will make this a seperate Issue to track it.
} // ny4i 25 Feb 2016
function SaveQSOToEditableLog: boolean;
label
  1, 2;
var
//  TCE                                   : ContestExchange;
  IndexInMap                            : integer;
  lpNumberOfBytesWritten                : Cardinal;
  TempInteger                           : integer;
  lpTranslated                          : LongBool;
//  TempString                            : ShortString;
  TempWord                              : Word;
//  TempPointer                           : PWORD;
  TempByte                              : Byte;
  TempSysTime                           : SYSTEMTIME;
begin
  Result := True;
  if ConfirmEditChanges then if YesOrNo(eq_handle, TC_SAVECHANGES) = IDno then Exit;

  {
    Windows.ZeroMemory(@EditableQSORXData.tSysTime, SizeOf(EditableQSORXData.tSysTime));

    TempPointer := @EditableQSORXData.tSysTime.wYear;
    for TempInteger := 185 downto 180 do
      begin
        TempWord := Windows.GetDlgItemInt(eq_handle, TempInteger, lpTranslated, False);
        TempPointer^ := TempWord;
        inc(integer(TempPointer), 2);
        if TempInteger = 184 then inc(integer(TempPointer), 2);
      end;
  }

//EditableQSORXData.QTH

  SendDlgItemMessage(eq_handle, 180, DTM_GETSYSTEMTIME, 0, integer(@TempSysTime));

  if TempSysTime.wYear >= 2000 then
    EditableQSORXData.tSysTime.qtYear := TempSysTime.wYear - 2000;
  EditableQSORXData.tSysTime.qtMonth := TempSysTime.wMonth;
  EditableQSORXData.tSysTime.qtDay := TempSysTime.wDay;
  //Time
  EditableQSORXData.tSysTime.qtSecond := TempSysTime.wSecond;
  EditableQSORXData.tSysTime.qtMinute := TempSysTime.wMinute;
  EditableQSORXData.tSysTime.qtHour := TempSysTime.wHour;

{
    //Date
  lpNumberOfBytesWritten := Windows.GetDlgItemInt(eq_handle, FLD_YEAR, lpTranslated, False);

  if (lpNumberOfBytesWritten >= 2000) and (lpNumberOfBytesWritten <= 2255) then
    EditableQSORXData.tSysTime.qtYear := lpNumberOfBytesWritten - 2000;
  EditableQSORXData.tSysTime.qtMonth := Windows.GetDlgItemInt(eq_handle, FLD_MONTH, lpTranslated, False);
  EditableQSORXData.tSysTime.qtDay := Windows.GetDlgItemInt(eq_handle, FLD_DAY, lpTranslated, False);
  //Time
  EditableQSORXData.tSysTime.qtSecond := Windows.GetDlgItemInt(eq_handle, FLD_SECOND, lpTranslated, False);
  EditableQSORXData.tSysTime.qtMinute := Windows.GetDlgItemInt(eq_handle, FLD_MINUTE, lpTranslated, False);
  EditableQSORXData.tSysTime.qtHour := Windows.GetDlgItemInt(eq_handle, FLD_HOUR, lpTranslated, False);

  if not CheckSystemTimeRecord(EditableQSORXData.tSysTime) then
  begin
    Result := False;
    Exit;
  end;
}
  {Callsign}
//  EditableQSORXData.Callsign := GetDialogItemText(eq_handle, 118);
  Windows.ZeroMemory(@EditableQSORXData.Callsign, SizeOf(CallString)); //на всякий случай
  EditableQSORXData.Callsign[0] := Char(Windows.GetDlgItemText(eq_handle, FLD_CALLSIGN, @EditableQSORXData.Callsign[1], 12));

  if not GoodCallSyntax(EditableQSORXData.Callsign) then
  begin
    showwarning(TC_CHECKCALLSIGN);
    Result := False;
    Exit;
  end;

  //  LocateCall(EditableQSORXData.Callsign, EditableQSORXData.QTH, true);
  if ActiveDXMult <> NoDXMults then
     begin
     ZeroMemory(@EditableQSORXData.DXQTH, SizeOf(EditableQSORXData.DXQTH));
     EditableQSORXData.DXQTH := EditableQSORXData.QTH.CountryID;
     end;

  //   Sheet.SetMultFlags(EditableQSORXData);
  CalculateQSOPoints(EditableQSORXData);

  {Band}
  EditableQSORXData.Band := BandType(tCB_GETCURSEL(eq_handle, FLD_BAND));

  {Mode}
  // Mode has an extendedMode so grab it and convert it to a modeType and store both
  EditableQSORXData.ExtMode := ExtendedModeType(tCB_GETCURSEL(eq_handle, FLD_MODE));
  EditableQSORXData.Mode := GetModeFromExtendedMode(EditableQSORXData.ExtMode);

    {Frequency}
  lpNumberOfBytesWritten := Windows.GetDlgItemInt(eq_handle, FLD_FREQUENCY, lpTranslated, False);
  //if lpNumberOfBytesWritten < MAXDWORD then
  ZeroMemory(@EditableQSORXData.Frequency, SizeOf(EditableQSORXData.Frequency));
  EditableQSORXData.Frequency := lpNumberOfBytesWritten;

  {ComputerID}
  Windows.GetDlgItemText(eq_handle, FLD_COMPUTERID, @TempInteger, 2);
  EditableQSORXData.ceComputerID := PChar(@TempInteger)[0];
  if not (EditableQSORXData.ceComputerID in ['A'..'Z']) then EditableQSORXData.ceComputerID := #0;

  {Age}
  lpNumberOfBytesWritten := Windows.GetDlgItemInt(eq_handle, FLD_AGE, lpTranslated, False);
  if lpNumberOfBytesWritten < MAXBYTE then
     begin
     ZeroMemory(@EditableQSORXData.Age, SizeOf(EditableQSORXData.Age));
     EditableQSORXData.Age := lpNumberOfBytesWritten;
     end;

  {Chapter}
  ZeroMemory(@EditableQSORXData.Chapter, SizeOf(EditableQSORXData.Chapter));
  EditableQSORXData.Chapter := GetDialogItemText(eq_handle, FLD_CHAPTER);
  {Check}
  ZeroMemory(@EditableQSORXData.Check, SizeOf(EditableQSORXData.Check));
  EditableQSORXData.Check := Windows.GetDlgItemInt(eq_handle, FLD_CHECK, lpTranslated, False);
  {ClassCE}
  ZeroMemory(@EditableQSORXData.ceClass, SizeOf(EditableQSORXData.ceClass));
  EditableQSORXData.ceClass := GetDialogItemText(eq_handle, FLD_CLASS);

  {NumberSent}
  ZeroMemory(@EditableQSORXData.NumberSent, SizeOf(EditableQSORXData.NumberSent));
  EditableQSORXData.NumberSent := Windows.GetDlgItemInt(eq_handle, FLD_NUMBERSEND, lpTranslated, True);

  {NumberReceived}
  TempInteger := integer(Windows.GetDlgItemInt(eq_handle, FLD_NUMBERRECEIVED, lpTranslated, True));
  if lpTranslated then
     begin
     ZeroMemory(@EditableQSORXData.NumberReceived, SizeOf(EditableQSORXData.NumberReceived));
     EditableQSORXData.NumberReceived := TempInteger;
     end;

  {DomMultQTH}
//  EditableQSORXData.DomMultQTH := GetDialogItemText(eq_handle, FLD_DOMMULTQTH);
//  EditableQSORXData.DomMultQTH[0] := Char(Windows.GetDlgItemText(eq_handle, FLD_DOMMULTQTH, @EditableQSORXData.DomMultQTH[1], SizeOf(EditableQSORXData.DomMultQTH) - 1));

  {Prefix}
  ZeroMemory(@EditableQSORXData.Prefix, SizeOf(EditableQSORXData.Prefix));
  EditableQSORXData.Prefix := GetDialogItemText(eq_handle, FLD_PREFIX);

  {Zone}

  TempByte := Byte(Windows.GetDlgItemInt(eq_handle, FLD_ZONE, lpTranslated, True));
  if lpTranslated then
     begin
     ZeroMemory(@EditableQSORXData.Zone, SizeOf(EditableQSORXData.Zone));
     EditableQSORXData.Zone := TempByte
     end
  else
     begin
     if TempByte = 0 then
        begin
        ZeroMemory(@EditableQSORXData.Zone, SizeOf(EditableQSORXData.Zone));
        EditableQSORXData.Zone := DUMMYZONE;
        end;
     end;

  {Name}
  ZeroMemory(@EditableQSORXData.Name, SizeOf(EditableQSORXData.Name));
  EditableQSORXData.Name[0] := Char(Windows.GetDlgItemText(eq_handle, FLD_NAME, @EditableQSORXData.Name[1], SizeOf(EditableQSORXData.Name) - 1));

  {QTHString}
  // The next line was commented out - so test this well ny4i Issue112
  Windows.ZeroMemory(@EditableQSORXData.QTHString, SizeOf(EditableQSORXData.QTHString));
  EditableQSORXData.QTHString[0] := Char(Windows.GetDlgItemText(eq_handle, FLD_QTHSTRING, @EditableQSORXData.QTHString[1], SizeOf(EditableQSORXData.QTHString) - 1));
  if DoingDomesticMults then
  begin
    FoundDomesticQTH(EditableQSORXData); {then showwarning(TC_IMPROPERDOMESITCQTH)}
    ;
  end;

  {Postal Code}
//  EditableQSORXData.PostalCode := GetDialogItemText(eq_handle, FLD_POSTALCODE);
  //windows.GetDlgItemText(eq_handle,FLD_POSTALCODE,EditableQSORXData.PostalCode,sizeof(PostalCodeString));

  {Power}
  ZeroMemory(@EditableQSORXData.Power, SizeOf(EditableQSORXData.Power));
  EditableQSORXData.Power := {Windows.GetDlgItemInt(eq_handle, FLD_POWER, lpTranslated, True);} GetDialogItemText(eq_handle, FLD_POWER);

  {Precedence}
  Windows.GetDlgItemText(eq_handle, FLD_PRECEDENCE, CID_TWO_BYTES, 2);
  ZeroMemory(@EditableQSORXData.Precedence, SizeOf(EditableQSORXData.Precedence));
  EditableQSORXData.Precedence := CID_TWO_BYTES[0];

  {Prefecture}
  TempByte := Byte(Windows.GetDlgItemInt(eq_handle, FLD_PREFECTURE, lpTranslated, True));
  if lpTranslated then
     begin
     ZeroMemory(@EditableQSORXData.Prefecture, SizeOf(EditableQSORXData.Prefecture));
     EditableQSORXData.Prefecture := TempByte;
     end;

  {TenTenNum}
  TempWord := Word(Windows.GetDlgItemInt(eq_handle, FLD_TENTENNUM, lpTranslated, True));
  if lpTranslated then
     begin
     ZeroMemory(@EditableQSORXData.TenTenNum, SizeOf(EditableQSORXData.TenTenNum));
     EditableQSORXData.TenTenNum := TempWord;
     end;

  {RSTSent}
  TempInteger {TempWord} := {Word}Integer(Windows.GetDlgItemInt(eq_handle, FLD_RSTSEND, lpTranslated, True));
  if lpTranslated then
     begin
     ZeroMemory(@EditableQSORXData.RSTSent, SizeOf(EditableQSORXData.RSTSent));
     EditableQSORXData.RSTSent := TempInteger {TempWord};
     end;

  {RSTReceived}
  TempInteger {TempWord} := {Word}Integer(Windows.GetDlgItemInt(eq_handle, FLD_RSTRECEIVED, lpTranslated, True));
  if lpTranslated then
     begin
     ZeroMemory(@EditableQSORXData.RSTReceived, SizeOf(EditableQSORXData.RSTReceived));
     EditableQSORXData.RSTReceived := TempInteger {TempWord};
     end;

  IndexInMap := IndexOfItemInLogForEdit;
  {SAP}
  EditableQSORXData.ceSearchAndPounce := boolean(TF.SendDlgItemMessage(eq_handle, FLD_SAP, BM_GETCHECK));

  {DELETED}
  EditableQSORXData.ceQSO_Deleted := boolean(TF.SendDlgItemMessage(eq_handle, FLD_DELETED, BM_GETCHECK));

  // The way UDP handles an edited QSO is to delete it first and then add it again.  Issue 165 ny4i
  // In the case of an actual delete, we do NOT send the subsequent record to re-add the QSO.
 SendDeletedContactToUDP(EditableQSORXData);
 if not EditableQSORXData.ceQSO_Deleted then
     begin
     LogContactToUDP(EditableQSORXData);
     end;

  if not OpenLogFile then Exit;
//2560
{
  if EditableQSORXData.ceQSO_Deleted then
  begin
    tSetFilePointer(IndexInMap + SizeOf(ContestExchange), FILE_BEGIN);
    2:
    if Windows.ReadFile(LogHandle, TCE, SizeOf(ContestExchange), lpNumberOfBytesWritten, nil) then
      if lpNumberOfBytesWritten = SizeOf(ContestExchange) then
      begin
        if TCE.ceQSO_Skiped = False then goto 1;
        goto 2;
      end;
  end;

  EditableQSORXData.ceQSO_Skiped := True;
  1:
}
  tSetFilePointer(IndexInMap, FILE_BEGIN);

  EditableQSORXData.ceNeedSendToServerAE := True;
  SendRecordToServer(NET_EDITEDQSO_ID, EditableQSORXData);

  sWriteFile(LogHandle, EditableQSORXData, SizeOf(ContestExchange));
  CloseLogFile;
  if FullLogEditHandle <> 0 then
  begin
    ListView_DeleteItem(LogEditListView, FullLogEditIndex);
    tAddContestExchangeToLog(EditableQSORXData, LogEditListView, FullLogEditIndex);
    ListView_SetItemState(LogEditListView, FullLogEditIndex - 1, LVIS_FOCUSED or LVIS_SELECTED, LVIS_FOCUSED or LVIS_SELECTED);
  end;

  tUpdateLog(actRescore);
  LoadinLog;
  if FindStationInCallsignColumn(EditableQSORXData.Callsign) = -1 then AddCallsignToStationColumn(EditableQSORXData.Callsign);
  UpdateAllStationsList;

end;

function CheckSystemTimeRecord(Time: TQSOTime): boolean;
begin
  Result := True;
  if not (Time.qtYear in [0..255]) then Result := False;
  if not (Time.qtMonth in [1..12]) then Result := False;
  if not (Time.qtDay in [1..31]) then Result := False;
  if not (Time.qtHour in [0..23]) then Result := False;
  if not (Time.qtMinute in [0..59]) then Result := False;
  if not (Time.qtSecond in [0..59]) then Result := False;
  if Result = False then showwarning(TC_CHECKDATETIME);
end;

procedure ShowNote(CE: ContestExchange);
begin
  Format(wsprintfBuffer, RC_NOTE + ' :'#13#10#13#10'%s', @EditableQSORXData.Prefix);
  ShowMessageParent(wsprintfBuffer, eq_handle);
end;

procedure MakeEditWindows;

begin
  MakeEditWindow('Callsign', ctString, @EditableQSORXData.Callsign[1]);
  inc(CurrentEditRow, 1);
  if ExchangeInformation.QTH then MakeEditWindow('QTH', ctString, @EditableQSORXData.QTHString[1]);
  if ExchangeInformation.Power then MakeEditWindow('Power', ctString, @EditableQSORXData.Power[1]);
 // if ExchangeInformation.FOCNumber then MakeEditWindow('FOC', ctByte, @EditableQSORXData.FOCNumber[1]);
  if ExchangeInformation.RST then
  begin
    MakeEditWindow('RST recv', ctInteger {ctWord}, @EditableQSORXData.RSTReceived);
    MakeEditWindow('RST sent', ctInteger {ctWord}, @EditableQSORXData.RSTSent);
  end;

  if ExchangeInformation.QSONumber then
  begin
    MakeEditWindow('Number recv', ctInteger, @EditableQSORXData.NumberReceived);
    MakeEditWindow('Number sent', ctInteger, @EditableQSORXData.NumberSent);
  end;
end;

procedure MakeEditWindow(Caption: PChar; FType: CFGType; ValueAdr: Pointer);
var
  Value                                 : PChar;
  w                                     : integer;
begin
  Value := PChar(ValueAdr);
  if FType in [ctWord, ctInteger] then
  begin
    if FType = ctWord then w := PWORD(ValueAdr)^;
//    if FType = ctByte then w := PByte(ValueAdr)^;
    if FType = ctInteger then w := PDWORD(ValueAdr)^;

    asm
      xor eax,eax
      mov eax,dword ptr W
      push eax
    end;

    wsprintf(IntToPCharBuffer, '%d');
    asm add esp,12    end;
    Value := IntToPCharBuffer;
  end;
  tCreateStaticWindow(Caption, LeftStyle, 10, CurrentEditRow * 20 + 400, 70, ws, eq_handle, 0);
  tCreateEditWindow($00020004, Value, $50010088, 90, CurrentEditRow * 20 + 400, 150, ws, eq_handle, 0);
  inc(CurrentEditRow);
end;

procedure OpenEditQSOWindow(Parent: HWND);
var
  icex1                                 : TInitCommonControlsEx;
begin
  icex1.dwSize := SizeOf(icex1);
  icex1.dwICC := ICC_DATE_CLASSES;
  INITCOMMONCONTROLSEX(icex1);
  DialogBox(hInstance, MAKEINTRESOURCE(46), Parent, @EditQSODlgProc);
end;

end.

