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
unit uQTCS;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  utils_file,
  uTotal,
  LogDupe,
  PostUnit,
  LogStuff,
  Windows,
  Tree,
  LogCW,
  uDialogs,
  LogWind,
  LogRadio,
  Messages
  ;

function QTCSDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure SendQTC(QTC: integer);
procedure SaveQTCS;
procedure RegQTCSHotKeys;
procedure SetSendedQSOs;

const
  QTC_HK_RETURN                         = 1;
  QTC_HK_PAGEUP                         = 2;
  QTC_HK_PAGEDOWN                       = 3;
  QTC_HK_F10                            = 4;

  QTC_SEND_NEXT                         = 100;
  QTC_SEND_QRVSTRING                    = 101;
  QTC_SEND_QRV                          = 102;
  QTC_SEND_TIME                         = 103;
  QTC_SEND_CALL                         = 104;
  QTC_SEND_NUMBER                       = 105;
  QTC_SEND_ALL                          = 106;
  QTC_SEND_STOP                         = 107;

  QTCCustomMessages                     = 7;
var
  QTCTXButtonsPChar                     : array[0..QTCCustomMessages] of PChar =
    (
    'N&EXT [return]',
    nil,
    'Q&RV?',
    '&TIME',
    '&CALL',
    '&NR',
    '&ALL',
    '&STOP'
    );
var
  QTCWasSend                            : integer ;
  ArrowWindow                           : HWND;
  CurrentQTC                            : HWND ;
  QTCSWindow                            : HWND ;
  LastSendedQTCHour                     : integer = -1;
implementation
uses
  uNet,
  LOGSUBS2,
  LOGWAE,
  MainUnit;

function QTCSDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ABORT_QTC;
var
  I                                     : integer;
  Time                                  : integer;
  Number                                : integer;
  p                                     : PChar;
  TempString                            : Str160;
  P2                                    : PChar;
begin
  RESULT := False;
  case Msg of
    WM_INITDIALOG:
      begin
//        P2 := PChar(string(QTCCallsign));
        asm
//          push p2
          lea eax,[QTCCallsign+1]
          push eax
          lea eax,[QRVString+1]
          push eax
        end;
        wsprintf(wsprintfBuffer, TC_QTC_FOR);
        asm add esp,16
        end;

        Windows.SetWindowText(hwnddlg, wsprintfBuffer);
        QTCTXButtonsPChar[1] := @QRVString[1];
        {Custom buttons}
        for I := 0 to QTCCustomMessages do
        begin
          if I = 0 then
            Number := BS_VCENTER or BS_MULTILINE or WS_TABSTOP or BS_PUSHBUTTON or BS_CENTER or WS_CHILD or WS_VISIBLE + BS_DEFPUSHBUTTON
          else
            Number := BS_PUSHBUTTON + BS_CENTER + BS_MULTILINE + WS_CHILD + WS_VISIBLE + WS_TABSTOP;

          tCreateButtonWindow(
            0,
            QTCTXButtonsPChar[I],
            Number,
            5 + I * 55,
            255,
             53,
            QTCHEIGHT * 2,
            hwnddlg,
            I + 100
            );
        end;

        QTCSWindow := hwnddlg;
        QTCWasSend := 0;
        LastSendedQTCHour := -1;

        for I := 1 to NumberMessagesToBeSent do
        begin
          Number := QTCsToBeSendArray[I].qsNumber;
          Time := QTCsToBeSendArray[I].qsTime;
          p := @QTCsToBeSendArray[I].qsCall[1];
          asm
          push Number
          push p
          push Time
          end;
          wsprintf(wsprintfBuffer, '%04u %-13s %u');
          asm add esp,20
          end;

          {QTC}
          tCreateStaticWindow
            (
            wsprintfBuffer,
            WS_CHILD or SS_SUNKEN or SS_NOTIFY or SS_LEFT or WS_VISIBLE,
            70,
            (I - 1) * (QTCHEIGHT + QTCROWSDIS) + 5,
          //  310,
           410,     // n4af 4.32.4
            QTCHEIGHT,
            hwnddlg,
            I + 200
            );
          asm
          mov edx,[MainWindowEditFont]
          call tWM_SETFONT
          end;

          asm push i          end;
          wsprintf(wsprintfBuffer, '&%u');
          asm add esp,12      end;
          {ALT+x}
          tCreateButtonWindow
            (
            WS_EX_STATICEDGE,
            wsprintfBuffer,
            WS_TABSTOP or WS_DISABLED or BS_PUSHBUTTON or BS_CENTER or WS_CHILD or WS_VISIBLE,
            380 - 375,
            (I - 1) * (QTCHEIGHT + QTCROWSDIS) + 5,
            55,
            QTCHEIGHT,
            hwnddlg,
            I + 300);
        end;
        SetDlgItemText(hwnddlg, 310, '1&0');

        ArrowWindow :=
          tCreateStaticWindow
          (
          TC_NEXT,
          WS_CHILD or SS_center or WS_VISIBLE,
          390,
          5,
          55,
          17,
          hwnddlg,
          1000
          );

      end;

    WM_ACTIVATE:
      begin
        if LoWord(wParam) = WA_INACTIVE then
          for I := QTC_HK_PAGEUP {QTC_HK_RETURN} to QTC_HK_F10 do UnregisterHotKey(hwnddlg, I)
        else
          RegQTCSHotKeys;
      end;

    WM_HOTKEY:
      begin
        case wParam of
          QTC_HK_PAGEUP: ProcessMenu(menu_cwspeedup);

          QTC_HK_PAGEDOWN: ProcessMenu(menu_cwspeeddown);

          QTC_HK_F10: ProcessMenu(menu_ctrl_sendkeyboardinput);
        end;

      end;

//    WM_HELP: tWinHelp(62);

    WM_CTLCOLORSTATIC:
      begin
        SetBkMode(HDC(wParam), TRANSPARENT);
        if GetDlgCtrlID(lParam) <= QTCWasSend + 200 then RESULT := BOOL(tr4wBrushArray[trYellow]);

        if lParam = integer(ArrowWindow) then
        begin
          SetTextColor(HDC(wParam), $FFFFFF);
          RESULT := BOOL(tr4wBrushArray[trBlue]);
        end;
      end;
    WM_CLOSE:
      begin
        if QTCWasSend <> 0 then if YesOrNo(hwnddlg, TC_DOYOUREALLYWANTTOABORTTHISQTC) = IDno then Exit;
        ABORT_QTC:
        QuickDisplay(TC_QTCABORTEDBYOPERATOR);
        QTCSWindow := 0;
        EndDialog(hwnddlg, 0);

      end;

    WM_COMMAND:

      begin

        case wParam of
          IDCANCEL: if CWStillBeingSent then FlushCWBufferAndClearPTT;

          QTC_SEND_NEXT:
            begin
              if QTCWasSend = NumberMessagesToBeSent - 1 then Windows.ShowWindow(ArrowWindow, SW_HIDE);

              if QTCWasSend = NumberMessagesToBeSent then
              begin
                asm
                push QTCWasSend
                push QTCNumber
                end;
                wsprintf(wsprintfBuffer, 'QSL %u/%u ?');
                asm add esp,16
                end;
                if YesOrNo2(tr4whandle, wsprintfBuffer) <> IDOK then Exit;
                SaveQTCS;
                Exit;
              end;

              inc(QTCWasSend);

              EnableWindowTrue(hwnddlg, QTCWasSend + 200);
              EnableWindowTrue(hwnddlg, QTCWasSend + 300);
              Windows.MoveWindow(ArrowWindow, 390, (QTCWasSend * (QTCHEIGHT + QTCROWSDIS) + 5), 55, 17, True);
              Windows.InvalidateRect(GetDlgItem(hwnddlg, QTCWasSend + 200), nil, True);
              SendQTC(QTCWasSend);
            end;

          QTC_SEND_QRVSTRING:
            asm
            lea eax, [QRVString]
            call SendStringAndStop
            end;

          QTC_SEND_QRV: SendStringAndStop('QRV?');

          QTC_SEND_TIME:
            begin
              if QTCWasSend = 0 then Exit;
              TempString := IntToStr(QTCsToBeSendArray[QTCWasSend].qsTime);
              while length(TempString) <> 4 do TempString := '0' + TempString;
              SendStringAndStop(TempString);
            end;

          QTC_SEND_CALL:
            begin
              if QTCWasSend = 0 then Exit;
              SendStringAndStop(QTCsToBeSendArray[QTCWasSend].qsCall);
            end;

          QTC_SEND_NUMBER:
            begin
              if QTCWasSend = 0 then Exit;
              SendStringAndStop(IntToStr(QTCsToBeSendArray[QTCWasSend].qsNumber));
            end;

          QTC_SEND_ALL: SendQTC(QTCWasSend);

          QTC_SEND_STOP:
            begin
              if YesOrNo(hwnddlg, TC_DOYOUREALLYWANTSTOPNOW) = IDno then Exit;
              if QTCWasSend = 0 then goto ABORT_QTC;

              asm
              push QTCWasSend
              end;
              wsprintf(wsprintfBuffer, TC_WASMESSAGENUMBERCONFIRMED);
              asm add esp,12
              end;

              if YesOrNo(hwnddlg, wsprintfBuffer) = IDno then dec(QTCWasSend);
              if QTCWasSend < 1 then goto ABORT_QTC;
              SaveQTCS;
            end;
          301..310: SendQTC(wParam - 300);
        end;
      end;
  end;
end;

procedure SendQTC(QTC: integer);
var
  TempString                            : Str160;
  Time                                  : integer;
  Number                                : integer;
  p                                     : PChar;
  Format                                : PChar;
  TempQTCMinutes                        : boolean;
const
  FormatArray                           : array[boolean, boolean, boolean] of PChar =
//QTCQRS,QTCExtraSpace,QTCMinutes
//false,true
  (
    (
    ('%04u %s %u', '%02u %s %u'),
    ('%04u  %s  %u', '%02u  %s  %u')
    )
    ,
    (
    (ControlS + '%04u %s %u' + ControlF, ControlS + '%02u %s %u' + ControlF),
    (ControlS + '%04u  %s  %u' + ControlF, ControlS + '%02u  %s  %u' + ControlF)
    )

    );
begin
  if not (QTC in [1..10]) then Exit;
{
  Format := '%04u %s %u';
  if QTCQRS then
  begin
    Format := ControlS + '%04u %s %u' + ControlF;
    if QTCExtraSpace then Format := ControlS + '%04u  %s  %u' + ControlF;
  end
  else
    if QTCExtraSpace then Format := '%04u  %s  %u';
}

  Time := QTCsToBeSendArray[QTC].qsTime;
  p := @QTCsToBeSendArray[QTC].qsCall[1];
  Number := QTCsToBeSendArray[QTC].qsNumber;

  TempQTCMinutes := (LastSendedQTCHour = (Time div 100)) and QTCMinutes;
  Format := FormatArray[QTCQRS, QTCExtraSpace, TempQTCMinutes];

  if QTCMinutes then
  begin
    if LastSendedQTCHour = (Time div 100) then Time := Time mod 100;
    LastSendedQTCHour := QTCsToBeSendArray[QTC].qsTime div 100;
  end;

  SetLength(TempString, 160);
  asm
          push Number
          push p
          push Time
  end;
  TempString[0] := CHR(wsprintf(@TempString[1], Format));
  asm add esp,20  end;
  SendStringAndStop(TempString);
end;

procedure SaveQTCS;
var
  I                                     : integer;
  QTCRXData                             : ContestExchange;
  lpTranslated                          : BOOL;
begin
  for I := 1 to QTCWasSend do
  begin
    IncrementQTCCount(QTCCallsign);
    Windows.ZeroMemory(@QTCRXData, SizeOf(ContestExchange));
    QTCRXData.ceRecordKind := rkQTCS;
//    tGetQSOSystemTime(QTCRXData.tSysTime);
//    QTCRXData.Band := ActiveBand;
//    QTCRXData.Mode := ActiveMode;
//    QTCRXData.ceComputerID := ComputerID;
    QTCRXData.Callsign := QTCCallsign;
    {Time}
    QTCRXData.NumberSent := QTCsToBeSendArray[I].qsTime;
    {EU Callsign}
    QTCRXData.Kids := QTCsToBeSendArray[I].qsCall;
    {Number}
    QTCRXData.NumberReceived := QTCsToBeSendArray[I].qsNumber;
    {QTCNumber}
    QTCRXData.RandomCharsReceived := IntToStr(QTCNumber) + '/' + IntToStr(NumberMessagesToBeSent);
    {QTCNumberQTCBooksSent}
    QTCRXData.QSOPoints := QTCNumber;
//    tAddQSOToLog(QTCRXData);
    if AddRecordToLogAndSendToNetwork(QTCRXData) then
      Sleep(100);
  end;
  inc(NumberQTCBooksSent);
  SetSendedQSOs;
  EndDialog(QTCSWindow, 0);
  QTCSWindow := 0;
end;

procedure SetSendedQSOs;
label
  1, 2;
var
  pNumberOfBytesRead                    : Cardinal;
  I                                     : integer;
  SignedQSOs                            : integer;
begin
  if not OpenLogFile then Exit;
  ReadVersionBlock;
  SignedQSOs := 1;
  1:
  Windows.ReadFile(LogHandle, TempRXData, SizeOf(ContestExchange), pNumberOfBytesRead, nil);
  if pNumberOfBytesRead = SizeOf(ContestExchange) then
  begin
    if TempRXData.ceWasSendInQTC = True then goto 1;
    if (TempRXData.ceQSOID1 = QTCsToBeSendArray[SignedQSOs].qsQSOID1) and (TempRXData.ceQSOID2 = QTCsToBeSendArray[SignedQSOs].qsQSOID2) then
    begin
      TempRXData.ceWasSendInQTC := True;
      tSetFilePointer(-1 * SizeOf(ContestExchange), FILE_CURRENT);
      sWriteFile(LogHandle, TempRXData, SizeOf(ContestExchange));
      if SendRecordToServer(NET_EDITEDQSO_ID, TempRXData) then
        Sleep(50);
      if SignedQSOs = QTCWasSend then goto 2;
      inc(SignedQSOs);
    end;
    goto 1;
  end;
  2:
  CloseLogFile;

end;

procedure RegQTCSHotKeys;
begin
  Windows.RegisterHotKey(QTCSWindow, QTC_HK_PAGEUP, 0, VK_PRIOR);
  Windows.RegisterHotKey(QTCSWindow, QTC_HK_PAGEDOWN, 0, VK_NEXT);
  Windows.RegisterHotKey(QTCSWindow, QTC_HK_F10, 0, VK_F10);
end;

end.

