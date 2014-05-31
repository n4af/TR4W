unit uErmak;
{$IMPORTEDDATA OFF}
interface

uses

  TF,
  VC,
  uCommctrl,
  Windows,
  Messages {,
  LogWind};

type
  TErmakFields = (efOp, efName1, efName2, efName3, efYear, efLevel, efCallsign, efCategory, efTrainer);

const

  ZVANIYA                               : array[0..7] of PChar = ('б/р', '1', '2', '3', 'КМС', 'МС', 'МСМК', 'ЗМС');

  ERMAKFIELDS                           = 8;

  eOpFields                             : array[TErmakFields] of PChar = (
    'Оператор',
    'Фамилия',
    'Имя',
    'Отчество',
    'Год рожден.',
    'Разряд',
    'Позывной',
    'Категория',
    'Тренер'
    );

  eOpFieldsLength                       : array[TErmakFields] of Byte = (
    90,
    80,
    70,
    90,
    50,
    55,
    60,
    60,
    45
    );

  eOpFieldsLimit                        : array[TErmakFields] of Byte = (
    0,
    20,
    20,
    20,
    4,
    4,
    12,
    1,
    0);

function ErmakDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure SetErmakFieldEnabled(Field: integer);

var
  ErmakWindow                           : HWND;

implementation
uses MainUnit;

function ErmakDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose;
const
  FIRSTLEFT                             = 10;
  FIELDLENGTH                           = 20;
  FIELDHEIGTH                           = 21;
  FIELD2LENGTH                          = 110;
  ec                                    = WS_DISABLED + ES_AUTOHSCROLL + ES_CENTER + WS_CHILD + WS_VISIBLE + WS_TABSTOP;
var
  Operator                              : integer;
  ControlID                             : integer;
  Left                                  : integer;
  Top                                   : integer;

  TempInteger                           : integer;
  h                                     : HWND;
  TempErmakField                        : TErmakFields;
begin
  Result := False;
  case Msg of

    WM_INITDIALOG:
      begin
        ErmakWindow := hwnddlg;
        Left := FIRSTLEFT;
//        Windows.SetDlgItemText(hwnddlg, 73, KIR_);

        Windows.SetWindowText(hwnddlg, 'Данные для отчета в формате Ермак');
        CreateOKCancelButtons(hwnddlg);

        for TempErmakField := Low(TErmakFields) to High(TErmakFields) do
        begin
          tCreateStaticWindow(eOpFields[TempErmakField], defStyle, Left, 10, eOpFieldsLength[TempErmakField], 30, hwnddlg, integer(TempErmakField));
          inc(Left, eOpFieldsLength[TempErmakField] + 1);
        end;

        for Operator := 1 to 10 do
        begin
          Left := FIRSTLEFT;
          Top := 20 + Operator * (FIELDHEIGTH + 1);

          for TempErmakField := Low(TErmakFields) to High(TErmakFields) do
          begin
            ControlID := integer(TempErmakField) + (Operator) * 100;

            Format(TempBuffer2, OPERATORINFO, ControlID);

            TempInteger := GetPrivateProfileString(ERMAKSECTION, TempBuffer2, nil, TempBuffer1, SizeOf(TempBuffer1), TR4W_INI_FILENAME);

            case TempErmakField of
              efOp:
                begin
                  Format(TempBuffer2, 'Оператор %u', Operator);
                  tCreateButtonWindow(WS_EX_STATICEDGE, TempBuffer2, BS_AUTOCHECKBOX + WS_CHILD + WS_VISIBLE + WS_TABSTOP, 10, Top, 89, FIELDHEIGTH, hwnddlg, ControlID);
                  Windows.SendDlgItemMessage(hwnddlg, ControlID, BM_SETCHECK, integer(TempBuffer1[0] = '1'), 0);
                end;

              efLevel:
                begin
                  CreateWindowEx(0, COMBOBOX, nil, CBS_DROPDOWNLIST or WS_DISABLED or WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_TABSTOP, Left, Top, eOpFieldsLength[efLevel], 200, hwnddlg, ControlID, hInstance, nil);
                  asm
                  mov edx,[MSSansSerifFont]
                  call tWM_SETFONT
                  end;
                  for TempInteger := 0 to 7 do
                    tCB_ADDSTRING_PCHAR(hwnddlg, ControlID, ZVANIYA[TempInteger]);
                  if TempBuffer1[0] in ['0'..'7'] then
                    tCB_SETCURSEL(hwnddlg, ControlID, Ord(TempBuffer1[0]) - Ord('0'))
                  else
                    tCB_SETCURSEL(hwnddlg, ControlID, 1)
                end;

              efName1, efName2, efName3, efYear, efCallsign, efCategory:
                begin
                  h := tCreateEditWindow(WS_EX_STATICEDGE, TempBuffer1, ec, Left, Top, eOpFieldsLength[TempErmakField], FIELDHEIGTH, hwnddlg, ControlID);
                  if TempErmakField in [efYear, efCategory] then Windows.SetWindowLong(h, GWL_STYLE, ec + ES_NUMBER);
                  if TempErmakField in [efCallsign] then Windows.SetWindowLong(h, GWL_STYLE, ec + ES_UPPERCASE);
                  SendMessage(h, EM_LIMITTEXT, eOpFieldsLimit[TempErmakField], 0);
                end;

              efTrainer:
                begin
                  tCreateButtonWindow(0, nil, BS_RIGHTBUTTON + BS_AUTORADIOBUTTON + WS_DISABLED + WS_CHILD + WS_VISIBLE + WS_TABSTOP, Left, Top, eOpFieldsLength[TempErmakField], FIELDHEIGTH, hwnddlg, ControlID);
                  Windows.SendDlgItemMessage(hwnddlg, ControlID, BM_SETCHECK, integer(TempBuffer1[0] = '1'), 0);
                end;
            end;

            inc(Left, eOpFieldsLength[TempErmakField] + 1);
          end;
          SetErmakFieldEnabled(Operator * 100);

        end;

      end;

    WM_CLOSE:
      begin
        ExitAndClose:

        EndDialog(hwnddlg, 0);
      end;
    WM_COMMAND:
      begin
        if HiWord(wParam) = BN_CLICKED then
          if (LoWord(wParam) mod 100) = 0 then
            SetErmakFieldEnabled(LoWord(wParam));

        case wParam of

          1: begin

              for Operator := 1 to 10 do
                for TempErmakField := Low(TErmakFields) to High(TErmakFields) do
                begin
                  ControlID := integer(TempErmakField) + (Operator) * 100;
                  case TempErmakField of
                    efOp, efTrainer:
                      begin
                        TempInteger := TF.SendDlgItemMessage(hwnddlg, ControlID, BM_GETCHECK);

//                        if TempErmakField = efOp then if TempInteger = BST_UNCHECKED then Break;
                        Format(wsprintfBuffer, '%d', TempInteger);
                      end;

                    efLevel:
                      begin
                        TempInteger := TF.SendDlgItemMessage(hwnddlg, ControlID, CB_GETCURSEL);
                        Format(wsprintfBuffer, '%d', TempInteger);
                      end;
                  else
                    begin
                      Windows.GetDlgItemText(hwnddlg, ControlID, wsprintfBuffer, SizeOf(wsprintfBuffer));
                    end;
                  end;

                  Format(TempBuffer1, OPERATORINFO, ControlID);

                  if wsprintfBuffer[0] <> #0 then
                    WritePrivateProfileString(ERMAKSECTION, TempBuffer1, wsprintfBuffer, TR4W_INI_FILENAME);

                end;

              goto ExitAndClose;
            end;

          2: goto ExitAndClose;
        end;
      end;
  end;
end;

procedure SetErmakFieldEnabled(Field: integer);
var
  bEnable                               : LongBool;
  i                                     : integer;
begin
  bEnable := Windows.SendDlgItemMessage(ErmakWindow, Field, BM_GETCHECK, 0, 0) = BST_CHECKED;
  for i := Field + 1 + integer(Low(TErmakFields)) to Field + 1 + integer(High(TErmakFields)) do
  begin
    Windows.EnableWindow(Windows.GetDlgItem(ErmakWindow, i), bEnable);
  end;
end;

end.

