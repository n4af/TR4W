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
unit MemProg;
{$IMPORTEDDATA OFF}
interface

uses
  LogCW,
  TF,
  VC,
  Windows,
  LogEdit,
  LogStuff,
  LogWind,
  LogK1EA,
  Tree,
  Messages
{$IF LANG = 'ENG'}, TR4W_CONSTS_ENG{$IFEND}
{$IF LANG = 'RUS'}, TR4W_CONSTS_RUS{$IFEND}
  ;

type
  MesWindowType = (CQMsgWin, ExMsgWin, OtherMsgWin);

function MemoryProgramDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
function GetCorrectMessageValue(s: string): string;
function NewMsgEditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT; stdcall;
procedure SetOtherMessageString(s: string);

var
  //   MessagesKeys                    : array[1..12] of HWND;
  MessagesValues                        : array[VK_F1..vk_f12] of HWND;
  MemProgHWND                           : HWND;
  MsgEditLabelHWND                      : HWND;
  MsgEditHWND                           : HWND;
  MsgLastFunctionKey                    : Char;
  OtherMsgLastFunctionKey               : integer;
  MesWindow                             : MesWindowType;
  OldMsgEditProc                        : Pointer;
  OldProc                               : Pointer;
  MsgListBoxEdit                        : HWND;
  owp                                   : Pointer;
  lastSelection                         : integer = 0;
  AllowEscapes                          : boolean = False;
implementation
uses MainUnit;

function MemoryProgramDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1, 2, 3;
var
  I                                     : Cardinal;
  Left                                  : integer;
  Top                                   : integer;
  ButtonText                            : PChar;
const
  LineHeight                            = 18;
  ValueLeft                             = 130;
begin
  RESULT := False;
  case Msg of
    WM_INITDIALOG:
      begin
        MemProgHWND := hwnddlg;
        KeyStatus := NormalKeys;
        for I := VK_F1 to vk_f12 do
        begin
          Left := 5;
          Top := (I - 111) * LineHeight - 10;
          if MesWindow = OtherMsgWin then
          begin
            if I < VK_F10 then
              ButtonText := PChar('&' + IntToStr(I - 111))
            else
            begin
              ButtonText := PChar(string('&' + CHR(I - 56)));
              if ActiveMode = Phone then goto 3;
            end;
            tCreateButtonWindow(WS_EX_STATICEDGE, ButtonText, BS_PUSHLIKE + BS_NOTIFY + WS_CHILD + WS_VISIBLE,
              10, Top, 25, LineHeight, hwnddlg, I);
            3:
            Left := 40;
          end;

          MessagesValues[I] := CreateWindowEx(0, StaticPChar, nil, SS_NOPREFIX or SS_LEFTNOWORDWRAP + WS_CHILD + WS_VISIBLE, Left, Top, 600, LineHeight - 2 + 2, hwnddlg, 0, hInstance, nil);
          asm
                  mov edx,[TerminalFont]
                  call tWM_SETFONT
          end;

            //                  if RegisterHotKey(hwnddlg, I + 100, 0, I) = False then ShowMessage(inttopchar(I));
          if RegisterHotKey(hwnddlg, I, 0, I) = False then
          begin
//            sm;
//            ShowMessage(SysErrorMessage(GetLastError));
          end;
          RegisterHotKey(hwnddlg, I + 12, MOD_CONTROL, I);
          RegisterHotKey(hwnddlg, I + 24, MOD_ALT, I);
        end;
        MsgEditLabelHWND := CreateWindowEx(0, StaticPChar, 'Msg =', {SS_SUNKEN + } SS_NOPREFIX or SS_LEFTNOWORDWRAP + WS_CHILD {+ WS_VISIBLE}, 5, 400 - 40, 70, LineHeight, hwnddlg, 73, hInstance, nil);
        asm
                  mov edx,[TerminalFont]
                  call tWM_SETFONT
        end;

        MsgEditHWND := CreateWindowEx(0, EditPChar, nil, ES_AUTOHSCROLL or {WS_HSCROLL or} ES_UPPERCASE or {WS_BORDER + } WS_CHILD { WS_VISIBLE}, 75, 400 - 40, 510, LineHeight, hwnddlg, 88, hInstance, nil);
        asm
            mov edx,[TerminalFont]
            call tWM_SETFONT
        end;
        OldMsgEditProc := Pointer(Windows.SetWindowLong(MsgEditHWND, GWL_WNDPROC, integer(@NewMsgEditProc)));
        if MesWindow = ExMsgWin then ShowExFunctionKeyStatus;
        if MesWindow = CQMsgWin then ShowCQFunctionKeyStatus;
        if MesWindow = OtherMsgWin then ShowOtherMemoryStatus;

        if (ActiveMode = CW) or (ActiveMode = Digital) then
          DisplayCrypticCWMenu
        else
          DisplayCrypticSSBMenu;

      end;

    WM_CTLCOLORSTATIC: if lParam = integer(MsgEditLabelHWND) then RESULT := BOOL(tr4wBrushArray[trWhite]);

    WM_CLOSE: 1:
      begin
        for I := VK_F1 to vk_f12 + 24 do UnregisterHotKey(hwnddlg, I);
        EndDialog(hwnddlg, 0);
      end;

    WM_COMMAND:
      begin

        if HiWord(wParam) = LBN_SELCHANGE then
        begin
          lastSelection := Windows.SendMessage(MsgListBoxEdit, LB_GETCURSEL, 0, 0);
            //                  Windows.SetWindowPos(MsgListBoxEdit, HWND_TOP, ValueLeft, MPDRAWITEMSTRUCT^.rcItem.Top, 400, 18, SWP_SHOWWINDOW);
            //                  MainUnit.tSetWindowText(MsgListBoxEdit, 'TempString');
            //                  Windows.SetFocus(MsgListBoxEdit);
        end;

        if wParam in [VK_F1..vk_f12] then OtherMsgLastFunctionKey := wParam;

        if ActiveMode = Phone then
        begin
          if wParam = VK_F1 then SetOtherMessageString(CorrectedCallPhoneMessage);
          if wParam = VK_F2 then SetOtherMessageString(CQPhoneExchange);
          if wParam = VK_F3 then SetOtherMessageString(CQPhoneExchangeNameKnown);
          if wParam = VK_F4 then SetOtherMessageString(QSLPhoneMessage);
          if wParam = VK_F5 then SetOtherMessageString(QSOBeforePhoneMessage);
          if wParam = VK_F6 then SetOtherMessageString(QuickQSLPhoneMessage);
          if wParam = VK_F7 then SetOtherMessageString(RepeatSearchAndPouncePhoneExchange);
          if wParam = VK_F8 then SetOtherMessageString(SearchAndPouncePhoneExchange);
          if wParam = VK_F9 then SetOtherMessageString(TailEndPhoneMessage);
        end
        else
        begin
          if wParam = VK_F1 then SetOtherMessageString(CorrectedCallMessage);
          if wParam = VK_F2 then SetOtherMessageString(CQExchange);
          if wParam = VK_F3 then SetOtherMessageString(CQExchangeNameKnown);
          if wParam = VK_F4 then SetOtherMessageString(QSLMessage);
          if wParam = VK_F5 then SetOtherMessageString(QSOBeforeMessage);
          if wParam = VK_F6 then SetOtherMessageString(QuickQSLMessage1);
          if wParam = VK_F7 then SetOtherMessageString(RepeatSearchAndPounceExchange);
          if wParam = VK_F8 then SetOtherMessageString(SearchAndPounceExchange);
          if wParam = VK_F9 then SetOtherMessageString(TailEndMessage);
          if wParam = VK_F10 then SetOtherMessageString(Short0);
          if wParam = VK_F11 then SetOtherMessageString(Short1);
          if wParam = vk_f12 then SetOtherMessageString(Short9);
        end;
        case wParam of

          2:
            begin
              if Windows.IsWindowVisible(MsgEditHWND) then
              begin
                if Windows.GetWindowText(MsgEditHWND, TempBuffer2, 255) <> 0 then
                begin
                  Windows.SetWindowText(MsgEditHWND, nil);
                  Exit;
                end;
                2:
                Windows.ShowWindow(MsgEditHWND, SW_HIDE);
                Windows.ShowWindow(MsgEditLabelHWND, SW_HIDE);
                Exit;
              end;
              goto 1;
            end;

        end;
      end;

    WM_HOTKEY:
      begin
        //         windows.Beep(200,200);
 //  windows.SetWindowText(hwnddlg,inttopchar(wParam));

        if MesWindow = OtherMsgWin then Exit;
        if Windows.IsWindowVisible(MsgEditHWND) then Exit;
        if (wParam < VK_F1) or (wParam > vk_f12 + 24) then Exit;
        //            Windows.SendMessage(MsgListBoxEdit, LB_SETCURSEL, 4 {lastSelection + 1}, 0);
        MsgLastFunctionKey := Char(wParam);
        KeyStatus := NormalKeys;
        if LoWord(lParam) = MOD_CONTROL then KeyStatus := ControlKeys;
        if LoWord(lParam) = MOD_ALT then KeyStatus := AltKeys;

        if MesWindow = CQMsgWin then
        begin
          ShowCQFunctionKeyStatus;
          Windows.SetWindowText(MsgEditHWND, PChar(string(GetCQMemoryString(ActiveMode, Char(wParam)))));
        end;
        if MesWindow = ExMsgWin then
        begin
          if (wParam = VK_F1) or (wParam = VK_F2) then Exit;
          ShowExFunctionKeyStatus;
          Windows.SetWindowText(MsgEditHWND, PChar(string(GetEXMemoryString(ActiveMode, Char(wParam)))));
        end;
        Windows.ShowWindow(MsgEditHWND, SW_SHOW);
        Windows.ShowWindow(MsgEditLabelHWND, SW_SHOW);
        Windows.SetFocus(MsgEditHWND);
        //Windows.SendMessage(MsgEditHWND, EM_SETSEL, 255, 255);
        PlaceCaretToTheEnd(MsgEditHWND);

      end;
  end;
end;

function GetCorrectMessageValue(s: string): string;
var
  I                                     : Cardinal;
  l                                     : Cardinal;
begin
  l := length(s);
  if l = 0 then
  begin
    RESULT := ' ';
    Exit;
  end;
  RESULT := '';
  for I := 1 to l do
  begin

    if s[I] >= CHR(27) then
      RESULT := RESULT + s[I]
    else
      RESULT := RESULT + '<' + DisplayByte(Ord(s[I])) + '>';
  end;
end;

function NewMsgEditProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): UINT; stdcall;
var
  TempString                            : string;
  c                                     : Cardinal;
  Selection                             : TSelection;
  I                                     : integer;
  OtherMsg                              : string;
begin
  RESULT := 0;
  if Msg = WM_KEYUP then if wParam = VK_RETURN then
    begin
      TempString := GetCorrectMessageValue(GetDialogItemText(MsgEditHWND, -1));
      if MesWindow = ExMsgWin then
      begin
        if (GetEXMemoryString(ActiveMode, MsgLastFunctionKey) <> TempString) then
        begin
          SetEXMemoryString(ActiveMode, MsgLastFunctionKey, TempString);

          if ActiveMode = Phone then
            SaveMessageToConfig('EX SSB MEMORY ' + KeyId(MsgLastFunctionKey), TempString)
          else
            SaveMessageToConfig('EX MEMORY ' + KeyId(MsgLastFunctionKey), TempString);
          ShowExFunctionKeyStatus;

        end;
      end;

      if MesWindow = CQMsgWin then
      begin

        if (GetCQMemoryString(ActiveMode, MsgLastFunctionKey) <> TempString) then
        begin
          SetCQMemoryString(ActiveMode, MsgLastFunctionKey, TempString);

          if ActiveMode = Phone then
            SaveMessageToConfig('CQ SSB MEMORY ' + KeyId(MsgLastFunctionKey), TempString)
          else
            SaveMessageToConfig('CQ MEMORY ' + KeyId(MsgLastFunctionKey), TempString);
          ShowCQFunctionKeyStatus;

        end;
      end;

      if MesWindow = OtherMsgWin then
      begin
        TempString := GetDialogItemText(MsgEditHWND, -1);
        if ActiveMode = Phone then
        begin
          if OtherMsgLastFunctionKey = VK_F1 then OtherMsg := 'CALL OK NOW SSB MESSAGE';
          if OtherMsgLastFunctionKey = VK_F2 then OtherMsg := 'CQ SSB EXCHANGE';
          if OtherMsgLastFunctionKey = VK_F3 then OtherMsg := 'CQ SSB EXCHANGE NAME KNOWN';
          if OtherMsgLastFunctionKey = VK_F4 then OtherMsg := 'QSL SSB MESSAGE';
          if OtherMsgLastFunctionKey = VK_F5 then OtherMsg := 'QSO BEFORE SSB MESSAGE';
          if OtherMsgLastFunctionKey = VK_F6 then OtherMsg := 'QUICK QSL SSB MESSAGE';
          if OtherMsgLastFunctionKey = VK_F7 then OtherMsg := 'REPEAT S&P SSB EXCHANGE';
          if OtherMsgLastFunctionKey = VK_F8 then OtherMsg := 'S&P SSB EXCHANGE';
          if OtherMsgLastFunctionKey = VK_F9 then OtherMsg := 'TAIL END SSB MESSAGE';
        end
        else
        begin

          if OtherMsgLastFunctionKey = VK_F1 then OtherMsg := 'CALL OK NOW MESSAGE';
          if OtherMsgLastFunctionKey = VK_F2 then OtherMsg := 'CQ EXCHANGE';
          if OtherMsgLastFunctionKey = VK_F3 then OtherMsg := 'CQ EXCHANGE NAME KNOWN';
          if OtherMsgLastFunctionKey = VK_F4 then OtherMsg := 'QSL MESSAGE';
          if OtherMsgLastFunctionKey = VK_F5 then OtherMsg := 'QSO BEFORE MESSAGE';
          if OtherMsgLastFunctionKey = VK_F6 then OtherMsg := 'QUICK QSL MESSAGE';
          if OtherMsgLastFunctionKey = VK_F7 then OtherMsg := 'REPEAT S&P EXCHANGE';
          if OtherMsgLastFunctionKey = VK_F8 then OtherMsg := 'S&P EXCHANGE';
          if OtherMsgLastFunctionKey = VK_F9 then OtherMsg := 'TAIL END MESSAGE';
          if OtherMsgLastFunctionKey = VK_F10 then OtherMsg := 'SHORT 0';
          if OtherMsgLastFunctionKey = VK_F11 then OtherMsg := 'SHORT 1';
          if OtherMsgLastFunctionKey = vk_f12 then OtherMsg := 'SHORT 9';
        end;

        if ActiveMode = Phone then
        begin
          if OtherMsgLastFunctionKey = VK_F1 then CorrectedCallPhoneMessage := TempString;
          if OtherMsgLastFunctionKey = VK_F2 then CQPhoneExchange := TempString;
          if OtherMsgLastFunctionKey = VK_F3 then CQPhoneExchangeNameKnown := TempString;
          if OtherMsgLastFunctionKey = VK_F4 then QSLPhoneMessage := TempString;
          if OtherMsgLastFunctionKey = VK_F5 then QSOBeforePhoneMessage := TempString;
          if OtherMsgLastFunctionKey = VK_F6 then QuickQSLPhoneMessage := TempString;
          if OtherMsgLastFunctionKey = VK_F7 then RepeatSearchAndPouncePhoneExchange := TempString;
          if OtherMsgLastFunctionKey = VK_F8 then SearchAndPouncePhoneExchange := TempString;
          if OtherMsgLastFunctionKey = VK_F9 then TailEndPhoneMessage := TempString;
        end
        else
        begin

          if OtherMsgLastFunctionKey = VK_F1 then CorrectedCallMessage := TempString;
          if OtherMsgLastFunctionKey = VK_F2 then CQExchange := TempString;
          if OtherMsgLastFunctionKey = VK_F3 then CQExchangeNameKnown := TempString;
          if OtherMsgLastFunctionKey = VK_F4 then QSLMessage := TempString;
          if OtherMsgLastFunctionKey = VK_F5 then QSOBeforeMessage := TempString;
          if OtherMsgLastFunctionKey = VK_F6 then QuickQSLMessage1 := TempString;
          if OtherMsgLastFunctionKey = VK_F7 then RepeatSearchAndPounceExchange := TempString;
          if OtherMsgLastFunctionKey = VK_F8 then SearchAndPounceExchange := TempString;
          if OtherMsgLastFunctionKey = VK_F9 then TailEndMessage := TempString;
          if OtherMsgLastFunctionKey = VK_F10 then Short0 := TempString[1];
          if OtherMsgLastFunctionKey = VK_F11 then Short1 := TempString[1];
          if OtherMsgLastFunctionKey = vk_f12 then Short9 := TempString[1];
        end;

            //                  showmessage(PChar(GetDialogItemText(MessagesValues[OtherMsgLastFunctionKey], -1)));
            //                  showmessage(PChar(TempString));
        SaveMessageToConfig(OtherMsg, GetCorrectMessageValue(TempString));
        ShowOtherMemoryStatus;
      end;

      Windows.ShowWindow(MsgEditHWND, SW_HIDE);
      Windows.ShowWindow(MsgEditLabelHWND, SW_HIDE);
    end;

  if Msg = WM_PASTE then
    if GetKeyState(VK_CONTROL) < -126 then Exit;
  //   if AllowEscapes then Exit;

  if Msg = WM_KEYDOWN then
  begin

    if GetKeyState(VK_CONTROL) < -126 then
      if wParam <> 17 then
      begin
        if wParam = 80 then
          if not AllowEscapes then
          begin
            AllowEscapes := True;
            Exit;
          end;
        if not AllowEscapes then Exit;
        SendMessage(MsgEditHWND, EM_GETSEL, LONGINT(@Selection.StartPos), LONGINT(@Selection.EndPos));
        c := Windows.GetWindowText(MsgEditHWND, TempBuffer1, 255);

        TempBuffer1[c + 1] := #0;
        if c <> 0 then
          for I := c - 1 downto Selection.EndPos do
            TempBuffer1[I + 1] := TempBuffer1[I];
        TempBuffer1[Selection.StartPos] := CHR(wParam - 64);

        Windows.SetWindowText(MsgEditHWND, TempBuffer1);
        Windows.SendMessage(MsgEditHWND, EM_SETSEL, Selection.StartPos + 1, Selection.EndPos + 1);
        AllowEscapes := False;
      end;
  end;
  RESULT := CallWindowProc(OldMsgEditProc, hwnddlg, Msg, wParam, lParam);

end;

procedure SetOtherMessageString(s: string);
var
  h                                     : HWND;
begin
  h := MsgEditHWND;
  if Windows.IsWindowVisible(h) then Exit;
  Windows.ShowWindow(h, SW_SHOW);
  Windows.ShowWindow(MsgEditLabelHWND, SW_SHOW);
  Windows.SetWindowText(h, PChar(s));
  Windows.SetFocus(h);
  PlaceCaretToTheEnd(h);
end;

end.

