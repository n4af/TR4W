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
 unit uAltP;

interface

uses
  Tree,
  LogCW,
  TF,
  VC,
  uCommctrl,
  uEditMessage,
  Windows,
  Messages,
  LogWind;

type
  TOtherMessageType = packed record
    omCommand: PChar;
    omCWMessage: MessagePointer;
    omSSBMessage: MessagePointer;
  end;

  TOtherShortMessageType = packed record
    osmCommand: PChar;
    osmMessage: PChar;
  end;

function AltPDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure DisplaymessagesList(mt: MesWindowType; MessageMode: ModeType);
procedure EditMessage;

const
  NumberOfOtherMessages                 = 9;
  OthermessagesArray                    : array[0..NumberOfOtherMessages - 1] of TOtherMessageType =
{(*}
    (
    (omCommand: 'CALL OK NOW %s MESSAGE';    omCWMessage: @CorrectedCallMessage;          omSSBMessage: @CorrectedCallPhoneMessage),
    (omCommand: 'CQ %s EXCHANGE';            omCWMessage: @CQExchange;                    omSSBMessage: @CQPhoneExchange),
    (omCommand: 'CQ %s EXCHANGE NAME KNOWN'; omCWMessage: @CQExchangeNameKnown;           omSSBMessage: @CQPhoneExchangeNameKnown),
    (omCommand: 'QSL %s MESSAGE';            omCWMessage: @QSLMessage;                    omSSBMessage: @QSLPhoneMessage),
    (omCommand: 'QSO BEFORE %s MESSAGE';     omCWMessage: @QSOBeforeMessage;              omSSBMessage: @QSOBeforePhoneMessage),
    (omCommand: 'QUICK QSL %s MESSAGE';      omCWMessage: @QuickQSLMessage1;              omSSBMessage: @QuickQSLPhoneMessage),
    (omCommand: 'REPEAT S&P %s EXCHANGE';    omCWMessage: @RepeatSearchAndPounceExchange; omSSBMessage: @RepeatSearchAndPouncePhoneExchange),
    (omCommand: 'S&P %s EXCHANGE';           omCWMessage: @SearchAndPounceExchange;       omSSBMessage: @SearchAndPouncePhoneExchange),
    (omCommand: 'TAIL END %s MESSAGE';       omCWMessage: @TailEndMessage;                omSSBMessage: @TailEndPhoneMessage)
{*)}
  );

  NumberOfOtherShortMessages = 4;
  OtherShortMessagesArray: array[0..NumberOfOtherShortMessages - 1] of TOtherShortMessageType =
{(*}
    (
    (osmCommand: 'SHORT 0'; osmMessage: @Short0  ),
    (osmCommand: 'SHORT 1'; osmMessage: @Short1  ),
    (osmCommand: 'SHORT 2'; osmMessage: @Short2  ),
    (osmCommand: 'SHORT 9'; osmMessage: @Short9  )
{*)}
);

var

  flashreminder                         : boolean;
  ReminderDlgHandle                     : HWND;
  AltPListView                          : HWND;
  LastSelectedMessage                   : integer;

implementation
uses MainUnit;
var
  AltWnd                                : HWND;

const
  CQCWMEMORYF                           = 'CQ CW MEMORY F%u';
  CQCWMEMORYALTF                        = 'CQ CW MEMORY ALTF%u';
  CQCWMEMORYCONTROLF                    = 'CQ CW MEMORY CONTROLF%u';

function AltPDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  elvc                                  : tagLVCOLUMNA;

begin
  Result := False;
  case Msg of

    WM_INITDIALOG:
      begin
        LastSelectedMessage := 0;
        AltWnd := hwnddlg;
//        AltPListView := Get101Window(hwnddlg);

        Windows.SetWindowText(hwnddlg, RC_LISTOFMESS);
        AltPListView := CreateListView2(0, 0, 790, 350, hwnddlg);

        asm
        mov edx,[TerminalFont]
        call tWM_SETFONT
        end;
        ListView_SetExtendedListViewStyle(AltPListView, LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT);
        elvc.Mask := LVCF_TEXT or LVCF_WIDTH or LVCF_FMT;
        elvc.fmt := LVCFMT_LEFT;
        elvc.pszText := 'Command'; //TC_COMMAND;
        elvc.cx := 270;
        ListView_InsertColumn(AltPListView, 0, elvc);

        elvc.pszText := 'Message';
        elvc.cx := 340;
        ListView_InsertColumn(AltPListView, 1, elvc);

        elvc.pszText := 'Caption';
        elvc.cx := 155;
        ListView_InsertColumn(AltPListView, 2, elvc);

        DisplaymessagesList(MesWindow, ActiveMode);

      end;
    WM_COMMAND:
      begin
        if wParam = 2 then goto 1;
        if lParam = 0 then if LoWord(wParam) = 1 then EditMessage;
      end;
    WM_CLOSE: 1: EndDialog(hwnddlg, 0);

    WM_NOTIFY:
      begin
        with PNMHdr(lParam)^ do
          case code of
            NM_DBLCLK: EditMessage;
          end;
      end;
  end;

end;

procedure DisplaymessagesList(mt: MesWindowType; MessageMode: ModeType);
label
  1;
var
  Key                                   : Char;
  TempString                            : ShortString;
  elvi                                  : TLVItem;
//  TempPchar                             : PChar;
  TempInt                               : integer;
  ModeString                            : PChar;
  OpModeString                          : PChar;
  ButtonString                          : PChar;
  TempMessagePointer                    : MessagePointer;
  TempMode                              : ModeType;
begin
  ListView_DeleteAllItems(AltPListView);
//  if Mode in [CW, Digital] then ModeString := 'CW' else ModeString := 'SSB';

  TempMode := MessageMode;
  if TempMode = Digital then TempMode := CW;

  case TempMode of
    Digital, CW: ModeString := 'CW';
//    Digital: ModeString := 'DIG'
  else
    ModeString := 'SSB';
  end;

//  if mt = OtherMsgWin then ModeString := 'CW';

  if mt = CQMsgWin then
    OpModeString := 'CQ' else
    if mt = ExMsgWin then
      OpModeString := 'EX'
    else
    begin

      for TempInt := 0 to NumberOfOtherMessages - 1 do
      begin
        elvi.Mask := LVIF_TEXT;
        elvi.iItem := TempInt;
        elvi.iSubItem := 0;

        asm
            push ModeString
        end;

        wsprintf(wsprintfBuffer, OthermessagesArray[TempInt].omCommand);
        asm add esp,12
        end;
        elvi.pszText := wsprintfBuffer;

        ListView_InsertItem(AltPListView, elvi);

        elvi.iSubItem := 1;
        if TempMode = Phone then
        begin
          elvi.pszText := @OthermessagesArray[TempInt].omSSBMessage^[1];
          OthermessagesArray[TempInt].omSSBMessage^[Ord(OthermessagesArray[TempInt].omSSBMessage^[0]) + 1] := #0;
        end
        else
        begin
          elvi.pszText := @OthermessagesArray[TempInt].omCWMessage^[1];
          OthermessagesArray[TempInt].omCWMessage^[Ord(OthermessagesArray[TempInt].omCWMessage^[0]) + 1] := #0;
        end;

        ListView_SetItem(AltPListView, elvi);

      end;

      if TempMode = CW then
        for TempInt := 0 to NumberOfOtherShortMessages - 1 do
        begin

          elvi.iItem := TempInt + NumberOfOtherMessages;
          elvi.iSubItem := 0;
          elvi.pszText := OtherShortMessagesArray[TempInt].osmCommand;
          ListView_InsertItem(AltPListView, elvi);

          elvi.iSubItem := 1;

          wsprintfBuffer[0] := OtherShortMessagesArray[TempInt].osmMessage[0];
          wsprintfBuffer[1] := #0;
          elvi.pszText := wsprintfBuffer;
          ListView_SetItem(AltPListView, elvi);
        end;

      goto 1;
    end;

  for Key := F1 to AltF12 do
  begin
    elvi.Mask := LVIF_TEXT;
    elvi.iItem := Ord(Key) - Ord(F1);
    elvi.iSubItem := 0;

    if Key in [F1..F12] then
    begin
      ButtonString := '';
      TempInt := Ord(Key) - Ord(F1) + 1;
    end;

    if Key in [ControlF1..ControlF12] then
    begin
      ButtonString := 'CONTROL';
      TempInt := Ord(Key) - Ord(F1) + 1 - 12;
    end;

    if Key in [AltF1..AltF12] then
    begin
      ButtonString := 'ALT';
      TempInt := Ord(Key) - Ord(F1) + 1 - 24;
    end;

    asm
            mov eax, TempInt
            push eax
            push ButtonString
            push ModeString
            push OpModeString
    end;

    wsprintf(wsprintfBuffer, '%s %s MEMORY %sF%u');
    asm add esp,24
    end;

    elvi.pszText := wsprintfBuffer;
    ListView_InsertItem(AltPListView, elvi);

    elvi.iSubItem := 1;
    if mt = CQMsgWin then TempString := GetCQMemoryString(TempMode, Key);
    if mt = ExMsgWin then
    begin
      TempString := GetEXMemoryString(TempMode, Key);
      if Key = F1 then TempString := 'Set by the MY CALL';
      if Key = F2 then TempString := 'Set by S&P EXCHANGE';

//  TC_F1SETBYTHEMYCALLSTATEMENTINCONFIG  = 'F1 - Set by the MY CALL statement in config file';
//  TC_F2SETBYSPEXCHANGEANDREPEATSP       = 'F2 - Set by S&P EXCHANGE and REPEAT S&P EXCHANGE';
    end;
    if TempString <> '' then
    begin
      TempString[Ord(TempString[0]) + 1] := #0;
      elvi.pszText := @TempString[1];
    end
    else
      elvi.pszText := nil;
    ListView_SetItem(AltPListView, elvi);

    elvi.iSubItem := 2;
    if mt = CQMsgWin then
      TempMessagePointer := CQCaptionMemory[TempMode, Key];
    if mt = ExMsgWin then TempMessagePointer := EXCaptionMemory[TempMode, Key];

    if TempMessagePointer <> nil then
    begin
      TempString := TempMessagePointer^;
      TempString[Ord(TempString[0]) + 1] := #0;
      elvi.pszText := @TempString[1];
    end
    else
      elvi.pszText := nil;

    ListView_SetItem(AltPListView, elvi);
  end;
  1:
  elvi.Mask := LVIF_STATE;
  elvi.stateMask := 3;
  elvi.State := LVIS_SELECTED or LVIS_FOCUSED;
  SendMessage(AltPListView, LVM_SETITEMSTATE, LastSelectedMessage, LONGINT(@elvi));
  SendMessage(AltPListView, LVM_ENSUREVISIBLE, LastSelectedMessage, LONGINT(False));

end;

procedure EditMessage;
begin
  LastSelectedMessage := ListView_GetNextItem(AltPListView, -1, LVNI_SELECTED);
  if LastSelectedMessage = -1 then Exit;
  if MesWindow = ExMsgWin then if LastSelectedMessage in [0, 1] then Exit;
//  DialogBoxParam(hInstance, MAKEINTRESOURCE(76), AltWnd, @EditMessageDlgProc, LastSelectedMessage);
  CreateModalDialog(250, 70, AltWnd, @EditMessageDlgProc, LastSelectedMessage);
end;

end.

