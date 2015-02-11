unit uRadioPolling;
{$IMPORTEDDATA OFF}
interface

uses
//FmtBcd,
  LogDupe,
  VC,
  TF,
  uSpots,
  uNet,
  Tree,
  LogRadio,
  LogEdit,
  uFunctionKeys,
  utils_file,
  MainUnit,
  Messages,
  LogWind,
  LogStuff,
  LogK1EA,
  Windows;

type
  DebugFileMessagetype = (dfmTX, dfmRX, dfmError);

function ReadFromSerialPort(BytesToRead: Cardinal; rig: RadioPtr): boolean;
function ReadFromCOMPort(b: Cardinal; rig: RadioPtr): boolean;
//function ReadFromCOMPortOnEvent(b: Cardinal; rig: RadioPtr): boolean;
procedure pKenwood(rig: RadioPtr);
procedure pKenwood2(rig: RadioPtr);
procedure pKenwoodNew(rig: RadioPtr);
procedure pFT990_FT1000(rig: RadioPtr);
procedure pFT747GX(rig: RadioPtr);
procedure pFT840_FT890_FT900(rig: RadioPtr);
procedure pFT920(rig: RadioPtr);
procedure pFT767(rig: RadioPtr);
procedure pFT736R(rig: RadioPtr);
procedure pFT817_FT847_FT857_FT897(rig: RadioPtr);
procedure pFT1000MP(rig: RadioPtr);
procedure pFT100(rig: RadioPtr);

procedure pIcom(rig: RadioPtr);
procedure pIcomNew(rig: RadioPtr);
function icomCheckBuffer(rig: RadioPtr): boolean;

procedure pFTDX9000(rig: RadioPtr);
procedure pOrion(rig: RadioPtr);
procedure pOrion3(rig: RadioPtr);
//procedure pOrionNew(rig: RadioPtr);

procedure UpdateStatus(rig: RadioPtr);
procedure ClearRadioStatus(rig: RadioPtr);

procedure WriteToDebugFile(port: PortType; MessageType: DebugFileMessagetype; p: PChar; Count: Cardinal);
//function WriteToSerialCATPort(data: Str80; port: HWND): Cardinal;
function GetFrequencyForYaesu3(p: PChar): Cardinal;
function GetFrequencyForYaesu4(p: PChar): Cardinal;
function GetFrequencyFromBCD(Count: Cardinal; Addr: PChar): Cardinal;
function GetFrequencyForYaesuFT747(a: PChar): Cardinal;
procedure BeginPolling(rig: RadioPtr); stdcall;
procedure SetDCBForIcom(port: HWND);
function ReadICOM(b: Cardinal; rig: RadioPtr): boolean;

procedure DisplayCurrentStatus(rig: RadioPtr);
procedure ProcessFilteredStatus(rig: RadioPtr);
function BufferToInt(buf: PChar; StartPos, EndPos: integer): integer;
procedure GetVFOInfoForFT2000(buf: PChar; var VFO: VFOStatusType; FrequencyAdder: integer);
procedure SetVFOA(rig: RadioPtr);
procedure SetVFOB(rig: RadioPtr);
function getIcomResponceSpeed(rig: RadioPtr): boolean;
procedure PTTStatusChanged;

const
  POLLINGDEBUG                          = False;
  ICOM_DEBUG                            = False;

implementation

{
procedure pOrionNew(rig: RadioPtr);
label
  1;
var
  TempMode                         : ModeType;
begin
  repeat
    inc(rig^.tPollCount);

    if rig.OutPutBufferPoiner <> 0 then
    begin
      rig.WritePollRequest(rig.OutPutBuffer, rig.OutPutBufferPoiner);
      Sleep(rig.OutPutBufferPoiner * 10);
      rig.OutPutBufferPoiner := 0;
    end;

    if rig.tOrionFreq[0] <> #0 then
    begin
      rig.WriteBufferToCATPort(rig.tOrionFreq);
      Windows.ZeroMemory(@rig.tOrionFreq, SizeOf(rig.tOrionFreq));
      Sleep(200);
    end;

    if rig.tOrionMode[0] <> #0 then
    begin
      rig.WriteBufferToCATPort(rig.tOrionMode);
      Windows.ZeroMemory(@rig.tOrionMode, SizeOf(rig.tOrionMode));
      Sleep(200);
    end;

    rig.WritePollRequest('?AF'#13, 4);
    if not ReadFromCOMPortOnEvent(12, rig) then begin ClearRadioStatus(rig); goto 1; end;

//?
    if rig.tBuf[2] <> 'A' then
    begin
      Sleep(500);
      PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);
      ClearRadioStatus(rig);
      goto 1;
    end;

//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@AF03526900');
    rig^.CurrentStatus.VFO[VFOA].Frequency := BufferToInt(@rig^.tBuf, 4, 8);

    rig.WritePollRequest('?BF'#13, 4);
    if not ReadFromCOMPortOnEvent(12, rig) or (rig.tBuf[2] <> 'B') then begin ClearRadioStatus(rig); goto 1; end;
//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@BF14173490');
    rig^.CurrentStatus.VFO[VFOB].Frequency := BufferToInt(@rig^.tBuf, 4, 8);

    rig.WritePollRequest('?KV'#13, 4);
    if not ReadFromCOMPortOnEvent(7, rig) or (rig.tBuf[2] <> 'K') then begin ClearRadioStatus(rig); goto 1; end;
//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@KVAAA');

    if rig.tBuf[4] = 'A' then
    begin
      rig^.CurrentStatus.Freq := rig^.CurrentStatus.VFO[VFOA].Frequency;
      rig^.CurrentStatus.VFOStatus := VFOA;
    end
    else
    begin
      rig^.CurrentStatus.Freq := rig^.CurrentStatus.VFO[VFOB].Frequency;
      rig^.CurrentStatus.VFOStatus := VFOB;
    end;
    CalculateBandMode(rig^.CurrentStatus.Freq, rig^.CurrentStatus.Band, TempMode);

    rig.WritePollRequest('?RMM'#13, 5);
    if not ReadFromCOMPortOnEvent(6, rig) or (rig.tBuf[2] <> 'R') then begin ClearRadioStatus(rig); goto 1; end;
//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@RMM2');

    case rig.tBuf[5] of
      '0', '1', '4': TempMode := Phone;
      '2', '3': TempMode := CW;
      '5': TempMode := FM;
      '6': TempMode := Digital;
    end;
    rig^.CurrentStatus.Mode := TempMode;

    1:
    UpdateStatus(rig);
  until rig^.tPollCount < 0;
end;
}

procedure pKenwood2(rig: RadioPtr);
label
  NextWait;

type
  tKenwoodCommands = (kcIF, kcFA, kcFB);
var
  PollNumber                            : tKenwoodCommands;
  stat                                  : TComStat;
  Errs                                  : DWORD;
  BytesInBuffer                         : integer;
  BufferNotChanged                      : integer;
  NumberOfSucceffulPolls                : integer;
  i                                     : integer;
  TempCommand                           : tKenwoodCommands;
const
  KenwoodPollRequests                   : array[tKenwoodCommands] of PChar = ('IF;', 'FA;', 'FB;');
  KenwoodPollRequestsAnswerLength       : array[tKenwoodCommands] of integer = (38, 14, 14);
begin
  repeat
    inc(rig^.tPollCount);
{
    if rig.tOrionFreq[0] <> #0 then
    begin
      rig.WriteBufferToCATPort(rig.tOrionFreq);
      Windows.ZeroMemory(@rig.tOrionFreq, SizeOf(rig.tOrionFreq));
      Sleep(200);
    end;

    if rig.tOrionMode[0] <> #0 then
    begin
      rig.WriteBufferToCATPort(rig.tOrionMode);
      Windows.ZeroMemory(@rig.tOrionMode, SizeOf(rig.tOrionMode));
      Sleep(200);
    end;
}
    NumberOfSucceffulPolls := 0;

    for PollNumber := Low(tKenwoodCommands) to High(tKenwoodCommands) do
    begin

      if PollNumber in [kcFA, kcFB] then
      begin
        if rig^.CurrentStatus.VFOStatus = VFOA then if PollNumber = kcFA then Continue;
        if rig^.CurrentStatus.VFOStatus = VFOB then if PollNumber = kcFB then Continue;

        if rig^.tPollCount mod 10 <> 0 then Continue;
      end;

      Sleep(FreqPollRate);

      rig.WritePollRequest(KenwoodPollRequests[PollNumber]^, 3);
      BytesInBuffer := 0;
      BufferNotChanged := 0;

      NextWait:
      Sleep(80);
      ClearCommError(rig^.tCATPortHandle, Errs, @stat);
      if stat.cbInQue > BytesInBuffer then
      begin
        BytesInBuffer := stat.cbInQue;
        goto NextWait;
      end
      else
      begin
        inc(BufferNotChanged);
        if BufferNotChanged < 3 then goto NextWait;
      end;

      if BytesInBuffer > 0 then
      begin
        inc(NumberOfSucceffulPolls);

        ReadFromSerialPort(BytesInBuffer, rig);

        for i := 1 to BytesInBuffer - 1 + 1 do
          if rig.tBuf[i] = ';' then
          begin

            for TempCommand := Low(tKenwoodCommands) to High(tKenwoodCommands) do
              if i >= KenwoodPollRequestsAnswerLength[TempCommand] then
                if rig.tBuf[i - KenwoodPollRequestsAnswerLength[TempCommand] + 2] =
                  KenwoodPollRequests[TempCommand][1] then
//                  asm nop end;

                begin
                  case TempCommand of
                    kcFA:
                      begin
                        rig^.CurrentStatus.VFO[VFOA].Frequency := BufferToInt(@rig^.tBuf[i - 13], 3, 11);
                      end;
                    kcFB:
                      begin
                        rig^.CurrentStatus.VFO[VFOB].Frequency := BufferToInt(@rig^.tBuf[i - 13], 3, 11);
                      end;

                    kcIF:
                      begin
                        rig^.CurrentStatus.Freq := BufferToInt(@rig^.tBuf[i - 37], 3, 11);
                        CalculateBandMode(rig^.CurrentStatus.Freq, rig^.CurrentStatus.Band, rig^.CurrentStatus.Mode);
                        case rig^.tBuf[i - 8] of
                          '4': rig^.CurrentStatus.Mode := FM;
                          '1', '2', '5': rig^.CurrentStatus.Mode := Phone;
                          '6', '9': rig^.CurrentStatus.Mode := Digital;
                          '3', '7', '8': rig^.CurrentStatus.Mode := CW;
                        end;

                        if rig^.tBuf[i - 7] = '0' then
                        begin
                          rig^.CurrentStatus.VFO[VFOA].Frequency := rig^.CurrentStatus.Freq;
//        ActiveVFO_is_A := True;
                          rig^.CurrentStatus.VFOStatus := VFOA;
                        end
                        else
                        begin
                          rig^.CurrentStatus.VFO[VFOB].Frequency := rig^.CurrentStatus.Freq;
//        ActiveVFO_is_A := False;
                          rig^.CurrentStatus.VFOStatus := VFOB;
                        end;

//      rig^.CurrentStatus.Freq := rig^.CurrentStatus.Freq + rig^.FrequencyAdder;
                        rig^.CurrentStatus.RITFreq := BufferToInt(@rig^.tBuf[i - 37], 19, 5);

                        rig^.CurrentStatus.Split := rig^.tBuf[i - 5] <> '0';
                        rig^.CurrentStatus.RIT := rig^.tBuf[i - 14] = '1';
                        rig^.CurrentStatus.XIT := rig^.tBuf[i - 13] = '1';

                      end;
                  end;
                end;

          end;
        Windows.ZeroMemory(@rig.tBuf, 128);

      end;
    end;

    if NumberOfSucceffulPolls = 0 then
    begin
      ClearRadioStatus(rig);
      Sleep(500);
    end;

    UpdateStatus(rig);
  until rig^.tPollCount < 0;
end;

procedure pOrion3(rig: RadioPtr);
label
  1, NextWait;
var
  TempMode                              : ModeType;
  PollNumber                            : integer;
  stat                                  : TComStat;
  Errs                                  : DWORD;
  BytesInBuffer                         : integer;
  BufferNotChanged                      : integer;
  NumberOfSucceffulPolls                : integer;
  i                                     : integer;
const
  PollsCount                            = 4;
  OrionPollRequests                     : array[0..PollsCount - 1] of PChar = ('?AF'#13, '?BF'#13, '?KV'#13, '?RMM'#13);
  OrionPollRequestsLength               : array[0..PollsCount - 1] of integer = (4, 4, 4, 5);
//  OrionPollRequestsAnswerLength         : array[0..PollsCount - 1] of integer = (12, 12, 7, 6);
begin
  repeat
    inc(rig^.tPollCount);

    if rig.tOrionFreq[0] <> #0 then
    begin
      rig.WriteBufferToCATPort(rig.tOrionFreq);
      Windows.ZeroMemory(@rig.tOrionFreq, SizeOf(rig.tOrionFreq));
      Sleep(200);
    end;

    if rig.tOrionMode[0] <> #0 then
    begin
      rig.WriteBufferToCATPort(rig.tOrionMode);
      Windows.ZeroMemory(@rig.tOrionMode, SizeOf(rig.tOrionMode));
      Sleep(200);
    end;

    NumberOfSucceffulPolls := 0;

    for PollNumber := 0 to PollsCount - 1 do
    begin
      rig.WritePollRequest(OrionPollRequests[PollNumber]^, OrionPollRequestsLength[PollNumber]);
      BytesInBuffer := 0;
      BufferNotChanged := 0;

      NextWait:
      Sleep(20 {n5aw} {OrionWaitTime});
      ClearCommError(rig^.tCATPortHandle, Errs, @stat);
      if stat.cbInQue > BytesInBuffer then
      begin
        BytesInBuffer := stat.cbInQue;
        goto NextWait;
      end
      else
      begin
        inc(BufferNotChanged);
        if BufferNotChanged < 3 then goto NextWait;
      end;

      if BytesInBuffer > 0 then
      begin
        inc(NumberOfSucceffulPolls);

        ReadFromSerialPort(BytesInBuffer, rig);

        for i := 1 to BytesInBuffer - 1 do
          if rig.tBuf[i] = '@' then
          begin
            case rig.tBuf[i + 1] of
              'A':
                begin
                  if rig.tBuf[i + 11] = #13 then
                    rig^.CurrentStatus.VFO[VFOA].Frequency := BufferToInt(@rig^.tBuf[i], 4, 8);
                end;
              'B':
                begin
                  if rig.tBuf[i + 11] = #13 then
                    rig^.CurrentStatus.VFO[VFOB].Frequency := BufferToInt(@rig^.tBuf[i], 4, 8);
                end;
              'K':
                if rig.tBuf[i + 6] = #13 then
                begin
                  if rig.tBuf[i + 3] = 'A' then
                  begin
                    rig^.CurrentStatus.Freq := rig^.CurrentStatus.VFO[VFOA].Frequency;
                    rig^.CurrentStatus.VFOStatus := VFOA;
                  end
                  else
                  begin
                    rig^.CurrentStatus.Freq := rig^.CurrentStatus.VFO[VFOB].Frequency;
                    rig^.CurrentStatus.VFOStatus := VFOB;
                  end;
                end;
              'R':
                if rig.tBuf[i + 5] = #13 then
                begin
                  CalculateBandMode(rig^.CurrentStatus.Freq, rig^.CurrentStatus.Band, rig^.CurrentStatus.Mode);
                  case rig.tBuf[i + 4] of
                    '0', '1', '4': rig^.CurrentStatus.Mode := Phone;
                    '2', '3': rig^.CurrentStatus.Mode := CW;
                    '5': rig^.CurrentStatus.Mode := FM;
                    '6': rig^.CurrentStatus.Mode := Digital;
                  end;
                end;
            end;
          end;
        Windows.ZeroMemory(@rig.tBuf, 64);

      end;
    end;

    if NumberOfSucceffulPolls = 0 then
    begin
      ClearRadioStatus(rig);
      Sleep(500);
    end;

{
    rig.WritePollRequest('?AF'#13, 4);
    if not ReadFromCOMPort(12, rig) then begin ClearRadioStatus(rig); goto 1; end;

//?
    if rig.tBuf[2] <> 'A' then
    begin
      Sleep(500);
      PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);
      ClearRadioStatus(rig);
      goto 1;
    end;

//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@AF03526900');
    rig^.CurrentStatus.VFO[VFOA].Frequency := BufferToInt(@rig^.tBuf, 4, 8);

    rig.WritePollRequest('?BF'#13, 4);
    if not ReadFromCOMPort(12, rig) or (rig.tBuf[2] <> 'B') then begin ClearRadioStatus(rig); goto 1; end;
//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@BF14173490');
    rig^.CurrentStatus.VFO[VFOB].Frequency := BufferToInt(@rig^.tBuf, 4, 8);

    rig.WritePollRequest('?KV'#13, 4);
    if not ReadFromCOMPort(7, rig) or (rig.tBuf[2] <> 'K') then begin ClearRadioStatus(rig); goto 1; end;
//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@KVAAA');

    if rig.tBuf[4] = 'A' then
    begin
      rig^.CurrentStatus.Freq := rig^.CurrentStatus.VFO[VFOA].Frequency;
      rig^.CurrentStatus.VFOStatus := VFOA;
    end
    else
    begin
      rig^.CurrentStatus.Freq := rig^.CurrentStatus.VFO[VFOB].Frequency;
      rig^.CurrentStatus.VFOStatus := VFOB;
    end;
    CalculateBandMode(rig^.CurrentStatus.Freq, rig^.CurrentStatus.Band, TempMode);

    rig.WritePollRequest('?RMM'#13, 5);
    if not ReadFromCOMPort(6, rig) or (rig.tBuf[2] <> 'R') then begin ClearRadioStatus(rig); goto 1; end;
//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@RMM2');

    case rig.tBuf[5] of
      '0', '1', '4': TempMode := Phone;
      '2', '3': TempMode := CW;
      '5': TempMode := FM;
      '6': TempMode := Digital;
    end;
    rig^.CurrentStatus.Mode := TempMode;
}
    1:
    UpdateStatus(rig);
  until rig^.tPollCount < 0;
end;

procedure pOrion(rig: RadioPtr);
label
  1;
var
  TempMode                              : ModeType;
begin
  repeat
    inc(rig^.tPollCount);

    if rig.tOrionFreq[0] <> #0 then
    begin
      rig.WriteBufferToCATPort(rig.tOrionFreq);
      Windows.ZeroMemory(@rig.tOrionFreq, SizeOf(rig.tOrionFreq));
      Sleep(200);
    end;

    if rig.tOrionMode[0] <> #0 then
    begin
      rig.WriteBufferToCATPort(rig.tOrionMode);
      Windows.ZeroMemory(@rig.tOrionMode, SizeOf(rig.tOrionMode));
      Sleep(200);
    end;

    rig.WritePollRequest('?AF'#13, 4);
    if not ReadFromCOMPort(12, rig) then begin ClearRadioStatus(rig);
      goto 1;
    end;

{?}
    if rig.tBuf[2] <> 'A' then
    begin
      Sleep(500);
      PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);
      ClearRadioStatus(rig);
      goto 1;
    end;

//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@AF03526900');
    rig^.CurrentStatus.VFO[VFOA].Frequency := BufferToInt(@rig^.tBuf, 4, 8);

    rig.WritePollRequest('?BF'#13, 4);
    if not ReadFromCOMPort(12, rig) or (rig.tBuf[2] <> 'B') then begin ClearRadioStatus(rig);
      goto 1;
    end;
//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@BF14173490');
    rig^.CurrentStatus.VFO[VFOB].Frequency := BufferToInt(@rig^.tBuf, 4, 8);

    rig.WritePollRequest('?KV'#13, 4);
    if not ReadFromCOMPort(7, rig) or (rig.tBuf[2] <> 'K') then begin ClearRadioStatus(rig);
      goto 1;
    end;
//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@KVAAA');

    if rig.tBuf[4] = 'A' then
    begin
      rig^.CurrentStatus.Freq := rig^.CurrentStatus.VFO[VFOA].Frequency;
      rig^.CurrentStatus.VFOStatus := VFOA;
    end
    else
    begin
      rig^.CurrentStatus.Freq := rig^.CurrentStatus.VFO[VFOB].Frequency;
      rig^.CurrentStatus.VFOStatus := VFOB;
    end;
    CalculateBandMode(rig^.CurrentStatus.Freq, rig^.CurrentStatus.Band, TempMode);

    rig.WritePollRequest('?RMM'#13, 5);
    if not ReadFromCOMPort(6, rig) or (rig.tBuf[2] <> 'R') then begin ClearRadioStatus(rig);
      goto 1;
    end;
//    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@RMM2');

    case rig.tBuf[5] of
      '0', '1', '4': TempMode := Phone;
      '2', '3': TempMode := CW;
      '5': TempMode := FM;
      '6': TempMode := Digital;
    end;
    rig^.CurrentStatus.Mode := TempMode;

    1:
    UpdateStatus(rig);
  until rig^.tPollCount < 0;
end;

procedure pKenwoodNew(rig: RadioPtr);
label
  NextPoll;
var
  Step                                  : integer;
  TempVFO                               : ActiveVFOStatusType;
const
  KenwoodVFORequests                    : array[ActiveVFOStatusType] of PChar = (nil, 'FA;', 'FB;', 'FB;');
  KenwoodPollCount                      = 10;
begin
  Step := KenwoodPollCount;
  NextPoll:
  Sleep(FreqPollRate);

  if rig.CommandsBufferPointer <> 0 then
  begin
    rig.WritePollRequest(rig.CommandsBuffer[0], rig.CommandsBufferPointer);
    Windows.ZeroMemory(@rig.CommandsBuffer[0], SizeOf(rig.CommandsBuffer[0]));
    rig.CommandsBufferPointer := 0;
    Sleep(100);
  end;

{
  if rig.OutPutBufferPoiner <> 0 then
  begin
    rig.WritePollRequest(rig.OutPutBuffer, rig.OutPutBufferPoiner);
    Sleep(rig.OutPutBufferPoiner * 10);
    rig.OutPutBufferPoiner := 0;
  end;
}
//  if step = KenwoodPollCount then
  if rig.WritePollRequest('IF;', 3) then
  begin
    if not ReadFromCOMPort {OnEvent}(38, rig) then ClearRadioStatus(rig)
    else
    begin
//      Windows.SetWindowText(tr4whandle, @rig^.tBuf);
      rig.CurrentStatus.VFOStatus := ActiveVFOStatusType(Ord(rig^.tBuf[31]) - Ord('0') + 1);

      rig.CurrentStatus.Freq := BufferToInt(@rig^.tBuf, 3, 11);
      if rig.CurrentStatus.Freq = rig.PreviousStatus.Freq then Sleep(250);

      CalculateBandMode(rig^.CurrentStatus.Freq, rig^.CurrentStatus.Band, rig^.CurrentStatus.Mode);
      case rig^.tBuf[30] of
        '4': rig^.CurrentStatus.Mode := FM;
        '1', '2', '5': rig^.CurrentStatus.Mode := Phone;
        '6', '9': rig^.CurrentStatus.Mode := Digital;
        '3', '7', '8': rig^.CurrentStatus.Mode := CW;
      end;

      rig^.CurrentStatus.RITFreq := BufferToInt(@rig^.tBuf, 19, 5);

      rig^.CurrentStatus.Split := rig^.tBuf[33] <> '0';
      rig^.CurrentStatus.RIT := rig^.tBuf[24] = '1';
      rig^.CurrentStatus.XIT := rig^.tBuf[25] = '1';

      rig.CurrentStatus.VFO[rig.CurrentStatus.VFOStatus].Frequency := rig.CurrentStatus.Freq;
      rig.CurrentStatus.VFO[rig.CurrentStatus.VFOStatus].Mode := rig.CurrentStatus.Mode;
      dec(Step);
    end;
  end;

  if step = 0 then
  begin
    if rig.CurrentStatus.VFOStatus = VFOA then TempVFO := VFOB else TempVFO := VFOA;
    if rig.WritePollRequest(KenwoodVFORequests[TempVFO]^, 3) then
      if ReadFromCOMPort {OnEvent}(14, rig) then
      begin
        rig^.CurrentStatus.VFO[TempVFO].Frequency := BufferToInt(@rig^.tBuf, 3, 11);
      end;
  end;

  if Step = 0 then step := KenwoodPollCount;

  UpdateStatus(rig);
  goto NextPoll;
end;

procedure pKenwood(rig: RadioPtr);
var
  PollSecVFO                            : Cardinal;
  ActiveVFO_is_A                        : boolean;
  TempCardinal                          : Cardinal;
  TempMode                              : ModeType;
label
  DontPollSecondVfos, NextPoll;

begin

  repeat
    NextPoll:
    Sleep(FreqPollRate);
    inc(rig^.tPollCount);
    inc(PollSecVFO);
//    if not rig.WritePollRequest('IF;', 3) then goto DontPollSecondVfos;
//    if not rig.WritePollRequest('IF;', 3) then goto NextPoll;
    rig.WritePollRequest('IF;', 3);

    if not ReadFromCOMPort(38, rig) then
    begin
      ClearRadioStatus(rig);
      PollSecVFO := 0;
      goto DontPollSecondVfos;
    end;

    if rig^.tBuf[1] = 'I' then
    begin
//IF00028017660     -003000 18<0-tx/rx>30000   ;
      rig^.CurrentStatus.TXOn := rig^.tBuf[29] = '1';
//      Windows.SetWindowText(tr4whandle, inttopchar(integer(rig^.CurrentStatus.TXOn)));
      rig^.CurrentStatus.Freq := BufferToInt(@rig^.tBuf, 3, 11);

      if rig^.tBuf[31] = '0' then
      begin
        rig^.CurrentStatus.VFO[VFOA].Frequency := rig^.CurrentStatus.Freq;
        ActiveVFO_is_A := True;
        rig^.CurrentStatus.VFOStatus := VFOA;
      end
      else
      begin
        rig^.CurrentStatus.VFO[VFOB].Frequency := rig^.CurrentStatus.Freq;
        ActiveVFO_is_A := False;
        rig^.CurrentStatus.VFOStatus := VFOB;
      end;

      rig^.CurrentStatus.Freq := rig^.CurrentStatus.Freq + rig^.FrequencyAdder;
      rig^.CurrentStatus.RITFreq := BufferToInt(@rig^.tBuf, 19, 5);

      CalculateBandMode(rig^.CurrentStatus.Freq, rig^.CurrentStatus.Band, rig^.CurrentStatus.Mode);

      case rig^.tBuf[30] of
        '4': rig^.CurrentStatus.Mode := FM;
        '1', '2', '5': rig^.CurrentStatus.Mode := Phone;
        '6', '9': rig^.CurrentStatus.Mode := Digital;
        '3', '7', '8': rig^.CurrentStatus.Mode := CW;
      end;

      rig^.CurrentStatus.Split := rig^.tBuf[33] <> '0';
      rig^.CurrentStatus.RIT := rig^.tBuf[24] = '1';
      rig^.CurrentStatus.XIT := rig^.tBuf[25] = '1';
{
      if rig.tRadioInterfaceWndHandle <> 0 then
      begin
        rig.WritePollRequest('SM;', 3);
        if ReadFromCOMPort(7, rig) then
        begin

          Windows.SendDlgItemMessage(rig.tRadioInterfaceWndHandle, 111, PBM_SETPOS, ((Ord(rig.tBuf[5]) - Ord('0')) * 10 + Ord(rig.tBuf[6]) - Ord('0')) * 3, 0);          Windows.SetWindowText(wh[mweInsert], @rig.tBuf);
        end;
      end;
}
      if PollSecVFO < 10 then goto DontPollSecondVfos;

      if ActiveVFO_is_A = True then
        rig.WritePollRequest('FB;', 3)
      else
        rig.WritePollRequest('FA;', 3);

      if ReadFromCOMPort(14, rig) then
        if rig^.tBuf[14] = ';' then
        begin
          TempCardinal := BufferToInt(@rig^.tBuf, 3, 11);
          if ActiveVFO_is_A = True then
            rig^.CurrentStatus.VFO[VFOB].Frequency := TempCardinal
          else
            rig^.CurrentStatus.VFO[VFOA].Frequency := TempCardinal
        end;
    end;

    PollSecVFO := 0;
    DontPollSecondVfos:
    UpdateStatus(rig);
  until rig^.tPollCount < 0;

end;

procedure pFT990_FT1000(rig: RadioPtr);
label
  1;
var
  F1, TempFreq                          : LONGINT;
  TempBand                              : BandType;
  TempMode                              : ModeType;
begin
  repeat
    inc(rig^.tPollCount);
    rig.WritePollRequest(FT1000MPPoll1String, length(FT1000MPPoll1String));
//    WriteToSerialCATPort(FT1000MPPoll1String, rig^.tCATPortHandle);
    if rig^.RadioModel = FT1000 then
      F1 := 16
    else
      F1 := 32;
    if not ReadFromCOMPort(F1, rig) then
    begin
      ClearRadioStatus(rig);
      goto 1;
    end;
    with rig^.CurrentStatus do
    begin
      rig^.CurrentStatus.RITFreq := 10 * (SHORTINT(rig^.tBuf[6]) * 255 + Ord(rig^.tBuf[7]));
      rig^.CurrentStatus.RIT := (Ord(rig^.tBuf[5]) and (1 shl 1)) <> 0;
      rig^.CurrentStatus.XIT := (Ord(rig^.tBuf[5]) and (1 shl 0)) <> 0;

      Freq := GetFrequencyForYaesu3(@rig^.tBuf[2]);
      Freq := Freq + rig^.FrequencyAdder;
      CalculateBandMode(Freq, Band, Mode);

      case Ord(rig^.tBuf[8]) of
        0, 1, 3: Mode := Phone;
        2: Mode := CW;
        4: Mode := FM;
        5, 6: Mode := Digital;
      end;
    end;

    {2}
    rig.WritePollRequest(FT1000MPPoll2String, length(FT1000MPPoll2String));
//    WriteToSerialCATPort(FT1000MPPoll2String, rig^.tCATPortHandle);
    if ReadFromCOMPort(32, rig) then
      with rig^.CurrentStatus do
      begin
        TempFreq := GetFrequencyForYaesu3(@rig^.tBuf[2]);
        CalculateBandMode(TempFreq, TempBand, TempMode);

        case Ord(rig^.tBuf[8]) of
          0, 1, 3: TempMode := Phone;
          2: TempMode := CW;
          4: TempMode := FM;
          5, 6: TempMode := Digital;
        end;

        VFO[VFOA].Frequency := TempFreq;
        VFO[VFOA].Band := TempBand;
        VFO[VFOA].Mode := TempMode;

        TempFreq := GetFrequencyForYaesu3(@rig^.tBuf[17 + 1]);
        CalculateBandMode(TempFreq, TempBand, TempMode);

        case Ord(rig^.tBuf[24]) of
          0, 1, 3: TempMode := Phone;
          2: TempMode := CW;
          4: TempMode := FM;
          5, 6: TempMode := Digital;
        end;

        VFO[VFOB].Frequency := TempFreq;
        VFO[VFOB].Band := TempBand;
        VFO[VFOB].Mode := TempMode;
      end;

    rig.WritePollRequest(FT1000MPPoll3String, length(FT1000MPPoll3String));
//    WriteToSerialCATPort(FT1000MPPoll3String, rig.tCATPortHandle);
    //������ 3 ����� - �������� ����������, ��������� ��� - Model ID
    if ReadFromCOMPort(5, rig) then

      with rig.CurrentStatus do
      begin
        Split := (Ord(rig.tBuf[1]) and $01) > 0;
        if (Ord(rig.tBuf[1]) and (1 shl 1)) <> 0 then
          rig^.CurrentStatus.VFOStatus := VFOB
        else
          rig^.CurrentStatus.VFOStatus := VFOA;
      end;
    1:
    UpdateStatus(rig);
  until rig^.tPollCount < 0;
end;

procedure pFT747GX(rig: RadioPtr);
label
  1;
var
  ActiveVFO_is_B                        : boolean;
  c                                     : integer;
  b                                     : Byte;
begin
  repeat
    inc(rig.tPollCount);
    rig.WritePollRequest(FT747GXPollString, length(FT747GXPollString));
//    WriteToSerialCATPort(FT747GXPollString, rig.tCATPortHandle);

    if not ReadFromCOMPort(344, rig) then
    begin
      ClearRadioStatus(rig);
      goto 1;
    end;

{
    rig.tBuf[01] := CHR($00); //Split

    rig.tBuf[02] := CHR($00); //Frequency
    rig.tBuf[03] := CHR($14); //Frequency
    rig.tBuf[04] := CHR($16); //Frequency
    rig.tBuf[05] := CHR($80); //Frequency
    rig.tBuf[06] := CHR(Random(255)); //Frequency

    rig.tBuf[07] := CHR($00); //Cur band
    rig.tBuf[08] := CHR($02); //vfo a status flag

    rig.tBuf[09] := CHR($00); //Frequency
    rig.tBuf[10] := CHR($14); //Frequency
    rig.tBuf[11] := CHR($16); //Frequency
    rig.tBuf[12] := CHR($80); //Frequency
    rig.tBuf[13] := CHR($25); //Frequency

    rig.tBuf[14] := CHR($14); //?
    rig.tBuf[15] := CHR($16); //?
    rig.tBuf[16] := CHR($80); //?

    rig.tBuf[17] := CHR($00); //Frequency
    rig.tBuf[18] := CHR($03); //Frequency
    rig.tBuf[19] := CHR($68); //Frequency
    rig.tBuf[20] := CHR($00); //Frequency
    rig.tBuf[21] := CHR(Random(255)); //Frequency

    Sleep(400);
}
    with rig.CurrentStatus do
    begin
{(*}
      Split          := (Ord(rig.tBuf[1]) and (1 shl 1)) <> 0;
      RIT            := (Ord(rig.tBuf[1]) and (1 shl 2)) <> 0;
      ActiveVFO_is_B := (Ord(rig.tBuf[1]) and (1 shl 3)) <> 0;
      if ActiveVFO_is_B then VFOStatus:= vfoB else VFOStatus:= vfoA;
{*)}

      Freq := GetFrequencyForYaesuFT747(@rig.tBuf[2]);

      CalculateBandMode(Freq, Band, Mode);

      case Ord(rig^.tBuf[22] {?!}) of
        1: Mode := FM;
        2, 8, 16: Mode := Phone;
        4: Mode := CW;
      end;

    end;

    with rig.CurrentStatus.VFO[VFOA] do
    begin
      Frequency := GetFrequencyForYaesuFT747(@rig.tBuf[9]);
      CalculateBandMode(Frequency, Band, Mode);
    end;

    with rig.CurrentStatus.VFO[VFOB] do
    begin
      Frequency := GetFrequencyForYaesuFT747(@rig.tBuf[17]);
      CalculateBandMode(Frequency, Band, Mode);
    end;

    1:
    UpdateStatus(rig);
  until rig.tPollCount < 0;
end;

procedure pFT840_FT890_FT900(rig: RadioPtr);
label
  1;
var
  RITFreqPtr                            : ^Smallint;
begin
  repeat
    inc(rig.tPollCount);
    rig.WritePollRequest(FT1000MPPoll1String, length(FT1000MPPoll1String));
//    WriteToSerialCATPort(FT1000MPPoll1String, rig.tCATPortHandle);

    if not ReadFromCOMPort(19, rig) then
    begin
      ClearRadioStatus(rig);
      goto 1;
    end;

    {
        rig.tBuf[1] := CHR(255 - 100); //Split
        rig.tBuf[2] := CHR(20); //BPF Selection
        rig.tBuf[3] := CHR(21); //Frequency
        rig.tBuf[4] := CHR(99); //Frequency
        rig.tBuf[5] := CHR(Random(255)); //Frequency

        rig.tBuf[6] := CHR($00); //Frequency
        rig.tBuf[7] := CHR($00); //Frequency

        rig.tBuf[8] := CHR(2); //Frequency

        rig.tBuf[12] := CHR(21); //Frequency
        rig.tBuf[13] := CHR(99); //Frequency
        rig.tBuf[14] := CHR(Random(255)); //Frequency

        Sleep(400);
    }
    with rig.CurrentStatus do
    begin
      if Ord(rig.tBuf[1]) and $40 > 0 then Split := True else Split := False;
      Freq := GetFrequencyForYaesu3(@rig.tBuf[3]) + rig^.FrequencyAdder;
      CalculateBandMode(Freq, Band, Mode);

      case Ord(rig^.tBuf[8]) of
        0, 1, 3: Mode := Phone;
        2: Mode := CW;
        4: Mode := FM;
        5, 6: Mode := Digital;
      end;

      RITFreqPtr := @rig.tBuf[6];
      RITFreq := RITFreqPtr^;
    end;
    rig.CurrentStatus.VFO[VFOA].Frequency := rig.CurrentStatus.Freq;
    rig.CurrentStatus.VFO[VFOA].Mode := rig.CurrentStatus.Mode;
    rig.CurrentStatus.VFO[VFOA].Band := rig.CurrentStatus.Band;

    with rig.CurrentStatus.VFO[VFOB] do
    begin
      Frequency := GetFrequencyForYaesu3(@rig.tBuf[12]);
      CalculateBandMode(Frequency, Band, Mode);

      case Ord(rig^.tBuf[17]) of
        0, 1, 3: Mode := Phone;
        2: Mode := CW;
        4: Mode := FM;
        5, 6: Mode := Digital;
      end;

    end;

    1:
    UpdateStatus(rig);
  until rig.tPollCount < 0;
end;

procedure pFT817_FT847_FT857_FT897(rig: RadioPtr);
label
  1;
var
  F1                                    : integer;
begin
  if rig^.RadioModel in [{FT817, }FT847] then
    rig.WritePollRequest(TurnOn847CATString, length(TurnOn847CATString));

  repeat
    inc(rig.tPollCount);
    rig.WritePollRequest(FT847PollString, length(FT847PollString));

    if not ReadFromCOMPort(5, rig) then
    begin
      ClearRadioStatus(rig);
      goto 1;
    end;

{
    rig.tBuf[1] := CHR($01);
    rig.tBuf[2] := CHR($42);
    rig.tBuf[3] := CHR($00);
    rig.tBuf[4] := CHR($00);
    rig.tBuf[5] := CHR($01);
    Sleep(400);
}
    with rig.CurrentStatus do
    begin
      F1 := (Ord(rig.tBuf[1]) and $F0) shr 4; { 100s of mhz }
      F1 := F1 * 10;
      F1 := F1 + (Ord(rig.tBuf[1]) and $0F); { 10s of mhz}
      F1 := F1 * 10;

      F1 := F1 + ((Ord(rig.tBuf[2]) and $F0) shr 4); { MHz }
      F1 := F1 * 10;
      F1 := F1 + (Ord(rig.tBuf[2]) and $0F); { 100 kHz }
      F1 := F1 * 10;

      F1 := F1 + ((Ord(rig.tBuf[3]) and $F0) shr 4); { 10 kHz }
      F1 := F1 * 10;
      F1 := F1 + (Ord(rig.tBuf[3]) and $0F); { kHz }
      F1 := F1 * 10;

      F1 := F1 + ((Ord(rig.tBuf[4]) and $F0) shr 4); { 100 hz }
      F1 := F1 * 10;

      F1 := F1 + (Ord(rig.tBuf[4]) and $0F); { 10 hz }
      F1 := F1 * 10;
      Freq := F1 + rig^.FrequencyAdder;
      CalculateBandMode(Freq, Band, Mode);

      case Ord(rig.tBuf[5]) of
        $00, $01, $04, $84: Mode := Phone;
        $02, $03, $82, $83: Mode := CW;
        $0A, $0C: Mode := Digital;
        $06, $08, $88: Mode := FM;
      end;

    end;

    rig^.CurrentStatus.VFO[VFOA].Frequency := rig.CurrentStatus.Freq;

    if rig^.RadioModel in [FT857, FT897] then
    begin
      if rig.tYaesuSendFreq then
      begin
        rig.WritePollRequest(rig.tYaesuFreq5Bytes, 5);
        rig.tYaesuSendFreq := False;
        Sleep(100);
        PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR);
      end;

      if rig.tYaesuSendMode then
      begin
        rig.WritePollRequest(rig.tYaesuMode5Bytes, 5);
        rig.tYaesuSendMode := False;
        Sleep(100);
        PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR);
      end;
    end;

    1:
    UpdateStatus(rig);
  until rig.tPollCount < 0;
end;

function icomCheckBuffer(rig: RadioPtr): boolean;
label
  NextLongCheck, NextShortCheck, NewCheck;
var
  stat                                  : TComStat;
  Errs                                  : DWORD;
  counter                               : integer;
  BytesInFuffer                         : integer;
  i                                     : integer;
  FDPos                                 : integer;
  DummyMode                             : ModeType;
const
  FD_NOT_FOUND                          = 12;
  ICOM_MAX_IN_BUFFER                    = 256;
begin

  Result := False;

  NewCheck:
  counter := 0;

  NextLongCheck:
  Sleep(100);
  ClearCommError(rig^.tCATPortHandle, Errs, @stat);
  if stat.cbInQue = 0 then
  begin
    inc(counter);
    if counter < 3 then goto NextLongCheck else Exit;
  end;

  BytesInFuffer := stat.cbInQue;
  counter := 0;

  NextShortCheck:
  Sleep({newIcomResponseTimeout}newIcomResponseTimeoutAuto);
  ClearCommError(rig^.tCATPortHandle, Errs, @stat);

  if BytesInFuffer < stat.cbInQue then
  begin
    BytesInFuffer := stat.cbInQue;
    counter := 0;
    goto NextShortCheck;
  end
  else
  begin
    inc(counter);
    if counter < 2 then
      if stat.cbInQue < ICOM_MAX_IN_BUFFER then
        goto NextShortCheck;
  end;

  if Errs = 0 then
  begin
    ReadFromSerialPort(stat.cbInQue, rig);
    Result := True;

    for i := 1 to stat.cbInQue do
      if rig.tBuf[i] = ICOM_PREAMBLE_CODE then
        if rig.tBuf[i + 1] = ICOM_PREAMBLE_CODE then
          if rig.tBuf[i + 2] in [ICOM_CONTROLLER_ADDRESS, ICOM_OTHER_RADIOS_ADDRESS] then
          begin

            for FDPos := 6 to FD_NOT_FOUND do if rig.tBuf[i + FDPos] = #$FD then Break;
            if FDPos = FD_NOT_FOUND then Continue;

            case rig.tBuf[i + 4] of

              ICOM_TRANSFER_FREQ, ICOM_GET_FREQ:
                if FDPos in [9, 10] then
                begin
                    //------------------00.01.02.03.04.05.06.07.08.09.10
                    //FE.FE.ra.E0.03.FD.FE.FE.E0.ra.03.00.00.00.00.00.FD - ic765 and others
                    //FE.FE.ra.E0.03.FD.FE.FE.E0.ra.03.00.00.00.00.FD    - ic735
                  rig.CurrentStatus.Freq := GetFrequencyFromBCD(FDPos - 5 {5}, @rig.tBuf[i + 5 {12}]) + rig^.FrequencyAdder;
                  rig.CurrentStatus.VFO[VFOA].Frequency := rig.CurrentStatus.Freq;
                  with rig.CurrentStatus do CalculateBandMode(Freq, Band, DummyMode);
                  UpdateStatus(rig);
                end;

              ICOM_TRANSFER_MODE, ICOM_GET_MODE:
                if FDPos in [6, 7] then
                begin
                  //------------------00.01.02.03.04.05.06.07
                  //FE.FE.ra.E0.04.FD.FE.FE.E0.ra.04.00.00.FD + IF passband width data (06)
                  //FE.FE.ra.E0.04.FD.FE.FE.E0.ra.04.00.FD

                  case Ord(rig.tBuf[i + 5]) of
                    5: rig.CurrentStatus.Mode := FM;
                    3, 7: rig.CurrentStatus.Mode := CW;
                    4, 8: rig.CurrentStatus.Mode := Digital;
                  else rig.CurrentStatus.Mode := Phone;
                  end;
                  UpdateStatus(rig);
                end;
            end
          end;
    Windows.ZeroMemory(@rig.tBuf, stat.cbInQue);
    if stat.cbInQue >= ICOM_MAX_IN_BUFFER then goto NewCheck;
  end;
end;

procedure pIcomNew(rig: RadioPtr);
label
  NextPoll;
var
  i                                     : integer;
begin
  if rig.RadioBaudRate >= 1200 then newIcomResponseTimeoutAuto := 60;
  if rig.RadioBaudRate >= 2400 then newIcomResponseTimeoutAuto := 40;
  if rig.RadioBaudRate >= 4800 then newIcomResponseTimeoutAuto := 30;
  if rig.RadioBaudRate >= 9600 then newIcomResponseTimeoutAuto := 20 - 10;
  if rig.RadioBaudRate >= 19200 then newIcomResponseTimeoutAuto := 10;
//  1200, 2400, 4800, 9600, 19200,
//if newIcomResponseTimeoutAuto

  NextPoll:
  for i := 0 to 7 do
    if rig.CommandsBuffer[i][0] <> #0 then
    begin
      rig.WritePollRequest(rig.CommandsBuffer[i][1], Ord(rig.CommandsBuffer[i][0]) - 1);
      rig.CommandsBuffer[i][0] := #0;
      icomCheckBuffer(rig);
    end;

//  sleep(200);
  Sleep(FreqPollRate);

  rig.SendIcomCommand(Ord(ICOM_GET_MODE));
  if not icomCheckBuffer(rig) then
  begin
    ClearRadioStatus(rig);
    UpdateStatus(rig);
    Sleep(1000);
    goto NextPoll;
  end;

  rig.SendIcomCommand(Ord(ICOM_GET_FREQ));
  if not icomCheckBuffer(rig) then
  begin
    ClearRadioStatus(rig);
    UpdateStatus(rig);
    Sleep(1000);
    goto NextPoll;
  end;

  goto NextPoll;
end;

procedure pIcom(rig: RadioPtr);
label
  1, 2, 3, 4, 5, NextPoll, ModeReceived;
var
  c                                     : Cardinal;
  failures                              : integer;
  stat                                  : TComStat;
  Errs                                  : DWORD;
  ModePollCount                         : integer;
  ModeBytes                             : integer;
begin
//  SetDCBForIcom(rig.tr4w_CATPortHandle);
//  rig.ICOM_OVERLAPPED.hEvent := CreateEvent(nil, FALSE, FALSE, nil);
  if cmdIcomResponseTimeout = -1 then
    IcomResponseTimeout := 48000 div rig.RadioBaudRate
  else
    IcomResponseTimeout := cmdIcomResponseTimeout;

  if IcomResponseTimeout < 10 then IcomResponseTimeout := 10;

  5:
//  if getIcomResponceSpeed(rig) = False then goto 5;

  failures := 0;
  3:

  repeat

    inc(rig.tPollCount);

{$IF ICOM_DEBUG}
    rig.tBuf[01] := CHR($FE);
    rig.tBuf[02] := CHR($FE);
    rig.tBuf[03] := CHR($5E);
    rig.tBuf[04] := CHR($E0);
    rig.tBuf[05] := CHR($03);
    rig.tBuf[06] := CHR($FD);
    rig.tBuf[07] := CHR($FE);
    rig.tBuf[08] := CHR($FE);
    rig.tBuf[09] := CHR($E0);
    rig.tBuf[10] := CHR($5E);
    rig.tBuf[11] := CHR($03);
    rig.tBuf[12] := CHR($00);
    rig.tBuf[13] := CHR($00);
    rig.tBuf[14] := CHR($05);
    rig.tBuf[15] := CHR($07);
    rig.tBuf[16] := CHR($00);
{$ELSE}
    rig.SendIcomCommand(Ord(ICOM_GET_FREQ));
    if rig.RadioModel = IC735 then c := 16 else c := 17;
    if not ReadICOM(c, rig) then
    begin
      4:
      inc(failures);
      if failures > 5 then
      begin
        ClearRadioStatus(rig);
        goto 2;
      end
      else
        goto 3;
    end;
{$IFEND}
    if rig.RadioModel = IC735 then c := 4 else c := 5;

    rig.CurrentStatus.Freq := GetFrequencyFromBCD(c, @rig.tBuf[12]) + rig^.FrequencyAdder;
    rig.CurrentStatus.VFO[VFOA].Frequency := rig.CurrentStatus.Freq;

    with rig.CurrentStatus do CalculateBandMode(Freq, Band, Mode);

{$IF NOT ICOM_DEBUG}
    rig.SendIcomCommand(Ord(ICOM_GET_MODE));

    ModePollCount := 0;
    ModeBytes := 0;

    NextPoll:

    Sleep(IcomResponseTimeout);
    ClearCommError(rig^.tCATPortHandle, Errs, @stat);
    if stat.cbInQue > ModeBytes then
    begin
      ModeBytes := stat.cbInQue;
      goto NextPoll;
    end
    else
    begin
      inc(ModePollCount);
      if ModePollCount < 8 then goto NextPoll;
    end;

    if ModeBytes > 0 then
    begin
      ReadFromSerialPort(ModeBytes, rig);
      if ModeBytes in [13, 14] then
        goto ModeReceived
      else
      begin
        PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);
        goto 1;
      end;
    end
    else
      goto 1;

    ModeReceived:

//    if rig.RadioModel = IC735 then c := 13 else c := 14;
//    if not ReadICOM(c, rig) then goto 1;

{$IFEND}

{$IF ICOM_DEBUG}
    rig.tBuf[01] := CHR($FE);
    rig.tBuf[02] := CHR($FE);
    rig.tBuf[03] := CHR($5E);
    rig.tBuf[04] := CHR($E0);
    rig.tBuf[05] := CHR($04);
    rig.tBuf[06] := CHR($FD);
    rig.tBuf[07] := CHR($FE);
    rig.tBuf[08] := CHR($FE);
    rig.tBuf[09] := CHR($E0);
    rig.tBuf[10] := CHR($5E);
    rig.tBuf[11] := CHR($04);
    rig.tBuf[12] := CHR($03);
    rig.tBuf[13] := CHR($01);
    rig.tBuf[14] := CHR($FD);
{$IFEND}
    if rig.tBuf[ModeBytes] = #$FD then
      case Ord(rig.tBuf[12]) of
        5: rig.CurrentStatus.Mode := FM;
        3, 7: rig.CurrentStatus.Mode := CW;
        4, 8: rig.CurrentStatus.Mode := Digital;
      else rig.CurrentStatus.Mode := Phone;
      end;

    {����� ������ = ����� �������+6 ����}
    1:

//    if rig.ICOM_COMMAND_B1 <> '' then {7 bytes $FE $FE RA $E0 $07 $01 $FD}
//    begin
//      rig.WritePollRequest(rig.ICOM_COMMAND_B1[1], length(rig.ICOM_COMMAND_B1));
//      rig.ICOM_COMMAND_B1 := '';
//      if not ReadICOM {ReadFromCOMPort}(13, rig) then goto 2;
//    end;

//    if rig.ICOM_COMMAND_SET_MODE <> '' then {8 bytes #$FE #$FE RA #$E0 #$06 #mode #filterwidth #$FD}
//    begin
//      rig.WritePollRequest(rig.ICOM_COMMAND_SET_MODE[1], length(rig.ICOM_COMMAND_SET_MODE));
//      rig.ICOM_COMMAND_SET_MODE := '';
//      if not ReadICOM {ReadFromCOMPort}(
{$IF ICOM_LONG_MODECOMMAND}
//        14
{$ELSE}
//        13
{$IFEND}
//        , rig) then goto 2;
//    end;

//    if rig.ICOM_COMMAND_SET_FREQ <> '' then {11 bytes #$FE #$FE RA #$E0 #$05 #1 #1 #1 #1 #00 #$FD}
//    begin
//      rig.WritePollRequest(rig.ICOM_COMMAND_SET_FREQ[1], length(rig.ICOM_COMMAND_SET_FREQ));
//      rig.ICOM_COMMAND_SET_FREQ := '';
//      if rig.RadioModel = IC735 then c := 16 else c := 17;
//      if not ReadICOM {ReadFromCOMPort}(c, rig) then goto 2;
//    end;

//    if rig.ICOM_COMMAND_B2 <> '' then {7 bytes $FE $FE RA $E0 $07 $00 $FD}
//    begin
//      rig.WritePollRequest(rig.ICOM_COMMAND_B2[1], length(rig.ICOM_COMMAND_B2));
//      rig.ICOM_COMMAND_B2 := '';
//      if not ReadICOM {ReadFromCOMPort}(13, rig) then goto 2;
//    end;

//    if rig.ICOM_COMMAND_CUSTOM <> '' then
//    begin
//      rig.WritePollRequest(rig.ICOM_COMMAND_CUSTOM[1], length(rig.ICOM_COMMAND_CUSTOM));
//      c := length(rig.ICOM_COMMAND_CUSTOM);
//      rig.ICOM_COMMAND_CUSTOM := '';
//      if not ReadICOM {ReadFromCOMPort}(c + 6, rig) then goto 2;
//    end;
{
    if rig.ICOM_COMMAND_PTT <> #255 then
    begin
      rig.ICOM_SET_PTT[0] := #$FE;
      rig.ICOM_SET_PTT[1] := #$FE;
      rig.ICOM_SET_PTT[2] := CHR(rig.ReceiverAddress);
      rig.ICOM_SET_PTT[3] := #$E0;
      rig.ICOM_SET_PTT[4] := #$1C;
      rig.ICOM_SET_PTT[5] := #$00;
      rig.ICOM_SET_PTT[6] := rig.ICOM_COMMAND_PTT;
      rig.ICOM_SET_PTT[7] := #$FD;
      rig.WritePollRequest(rig.ICOM_SET_PTT, SizeOf(rig.ICOM_SET_PTT));
      rig.ICOM_COMMAND_PTT := #255;
      if not ReadICOM(14, rig) then goto 2;
    end;
}
    2:
    failures := 0;
    UpdateStatus(rig);
  until rig.tPollCount < 0;
end;

procedure pFT100(rig: RadioPtr);
label
  1;
var
  TempFreq                              : integer;
  TempBand                              : BandType;
  TempMode                              : ModeType;
begin
  repeat
    inc(rig.tPollCount);
    rig.WritePollRequest(FT100StatusUpdate, length(FT100StatusUpdate));
//    WriteToSerialCATPort(FT100StatusUpdate, rig.tCATPortHandle);
    if not ReadFromCOMPort(32, rig) then begin ClearRadioStatus(rig);
      goto 1;
    end;
{
    rig.tBuf[1] := #$10;
    rig.tBuf[2] := #$01;
    rig.tBuf[3] := #$03;
    rig.tBuf[4] := #$d9;
    rig.tBuf[5] := #$40;
    rig.tBuf[6] := #$11;

    rig.tBuf[11] := #$1F;
    rig.tBuf[12] := #$38;

    Sleep(400);
}
    with rig.CurrentStatus do
    begin
      Freq := round(GetFrequencyForYaesu4(@rig.tBuf[2]) * 1.25) + rig^.FrequencyAdder;
      CalculateBandMode(Freq, Band, Mode);

      case (Ord(rig.tBuf[6]) and $07) of
        0, 1, 4: Mode := Phone;
        2, 3: Mode := CW;
        5: Mode := Digital;
        6, 7: Mode := FM;
      end;
      RITFreq := round(1.25 * (SHORTINT(rig^.tBuf[11]) * 255 + Ord(rig^.tBuf[12])));
    end;

//    WriteToSerialCATPort(FT100ReadStatusFlags, rig.tCATPortHandle);
    rig.WritePollRequest(FT100ReadStatusFlags, length(FT100ReadStatusFlags));
    if ReadFromCOMPort(8, rig) then
    begin
      rig^.CurrentStatus.Split := (Ord(rig.tBuf[1]) and (1 shl 0)) <> 0;
      rig^.CurrentStatus.VFOStatus := ActiveVFOStatusType((Ord(rig.tBuf[2]) and (1 shl 2)) + 1);
    end;

    1:
    UpdateStatus(rig);
  until rig.tPollCount < 0;
end;

procedure pFT1000MP(rig: RadioPtr);
label
  1;
var
  TempFreq                              : integer;
  TempBand                              : BandType;
  TempMode                              : ModeType;
begin
  repeat
    inc(rig.tPollCount);
    rig.WritePollRequest(FT1000MPPoll1String, length(FT1000MPPoll1String));
//    WriteToSerialCATPort(FT1000MPPoll1String, rig.tCATPortHandle);
    if not ReadFromCOMPort(16, rig) then begin ClearRadioStatus(rig);
      goto 1;
    end;

    with rig.CurrentStatus do
    begin
      Freq := round(GetFrequencyForYaesu4(@rig.tBuf[2]) * 0.625) + rig^.FrequencyAdder;
      CalculateBandMode(Freq, Band, Mode);

      case (Ord(rig.tBuf[8]) and $07) of
        0, 1, 3: Mode := Phone;
        2: Mode := CW;
        4: Mode := FM;
        5, 6: Mode := Digital;
      end;
    end;

    rig.WritePollRequest(FT1000MPPoll2String, length(FT1000MPPoll2String));
//    WriteToSerialCATPort(FT1000MPPoll2String, rig.tCATPortHandle);
    if ReadFromCOMPort(32, rig) then
      with rig.CurrentStatus do
      begin
        TempFreq := round(GetFrequencyForYaesu4(@rig.tBuf[2]) * 0.625);
        CalculateBandMode(TempFreq, TempBand, TempMode);

        case (Ord(rig.tBuf[8]) and $07) of 2, 5, 6: TempMode := CW;
        else TempMode := Phone;
        end;

        VFO[VFOA].Frequency := TempFreq;
        VFO[VFOA].Band := TempBand;
        VFO[VFOA].Mode := TempMode;

        if rig.tBuf[2 + 16] = #$20 then rig.tBuf[2 + 16] := #0;
        TempFreq := round(GetFrequencyForYaesu4(@rig.tBuf[18]) * 0.625);
        CalculateBandMode(TempFreq, TempBand, TempMode);

          { Look at band/mode information from radio }

        case (Ord(rig.tBuf[8 + 16]) and $07) of
          2, 5, 6: TempMode := CW;
        else TempMode := Phone;
        end;

        VFO[VFOB].Frequency := TempFreq;
        VFO[VFOB].Band := TempBand;
        VFO[VFOB].Mode := TempMode;
      end;
    rig.WritePollRequest(FT1000MPPoll3String, length(FT1000MPPoll3String));
//    WriteToSerialCATPort(FT1000MPPoll3String, rig.tCATPortHandle);
    if ReadFromCOMPort(6, rig) then
    begin
//      rig.CurrentStatus.Split := ((Ord(rig.tBuf[1]) and $01) > 0);
      rig^.CurrentStatus.Split := (Ord(rig.tBuf[1]) and (1 shl 0)) <> 0;
      rig^.CurrentStatus.VFOStatus := ActiveVFOStatusType((Ord(rig.tBuf[2]) and (1 shl 2)) + 1);
    end;

    1:
    UpdateStatus(rig);
  until rig.tPollCount < 0;
end;

procedure pFT920(rig: RadioPtr);
label
  1;
var
  TempFreq                              : integer;
  TempBand                              : BandType;
  TempMode                              : ModeType;
begin

  //  WriteToSerialCATPort(TurnOn847CATString, rig.Port_Handle);
  repeat

    inc(rig.tPollCount);
    rig.WritePollRequest(FT1000MPPoll1String, length(FT1000MPPoll1String));
//    WriteToSerialCATPort(FT1000MPPoll1String, rig.tCATPortHandle);
    if not ReadFromCOMPort(28, rig) then
    begin
      ClearRadioStatus(rig);
      goto 1;
    end;

{
    rig.tBuf[1] := #$B;
    rig.tBuf[2] := #$0;
    rig.tBuf[3] := #$6B;
    rig.tBuf[4] := #$27;
    rig.tBuf[5] := #$90;
    rig.tBuf[6] := #$0;
    rig.tBuf[7] := #$0;
    rig.tBuf[8] := #$81;
    rig.tBuf[9] := #$10;
    rig.tBuf[10] := #$20;
    rig.tBuf[11] := #$0;
    rig.tBuf[12] := #$0;
    rig.tBuf[13] := #$0;
    rig.tBuf[14] := #$4;
    rig.tBuf[15] := #$B;
    rig.tBuf[16] := #$0;
    rig.tBuf[17] := #$6A;
    rig.tBuf[18] := #$F0;
    rig.tBuf[19] := #$7F;
    rig.tBuf[20] := #$0;
    rig.tBuf[21] := #$0;
    rig.tBuf[22] := #$81;
    rig.tBuf[23] := #$10;
    rig.tBuf[24] := #$20;
    rig.tBuf[25] := #$0;
    rig.tBuf[26] := #$0;
    rig.tBuf[27] := #$0;
    rig.tBuf[28] := #$0;
}
    with rig.CurrentStatus do
    begin
      Freq := GetFrequencyForYaesu4(@rig.tBuf[2]) + rig^.FrequencyAdder;
      CalculateBandMode(Freq, Band, Mode);

      case (Ord(rig.tBuf[8]) and $07) of
        1: Mode := CW;
        3: Mode := FM;
        4, 5, 6: Mode := Digital;
      else Mode := Phone;
      end;
      XIT := LongBool(Ord(rig.tBuf[9]) and (1 shl 0));
      RIT := LongBool(Ord(rig.tBuf[9]) and (1 shl 1));
    end;
    rig.WritePollRequest(FT1000MPPoll2String, length(FT1000MPPoll2String));
//    WriteToSerialCATPort(FT1000MPPoll2String, rig.tCATPortHandle);
    if not ReadFromCOMPort(28, rig) then
    begin
//      ClearRadioStatus(rig);
      goto 1;
    end;

    with rig.CurrentStatus do
    begin
      TempFreq := GetFrequencyForYaesu4(@rig.tBuf[2]);
      CalculateBandMode(TempFreq, TempBand, TempMode);
      case (Ord(rig.tBuf[8]) and $07) of
        1: TempMode := CW;
        3: TempMode := FM;
        4, 5, 6: TempMode := Digital;
      else TempMode := Phone;
      end;

      VFO[VFOA].Frequency := TempFreq;
      VFO[VFOA].Band := TempBand;
      VFO[VFOA].Mode := TempMode;

      TempFreq := GetFrequencyForYaesu4(@rig.tBuf[16]);
      CalculateBandMode(TempFreq, TempBand, TempMode);
      case (Ord(rig.tBuf[22]) and $07) of
        1: TempMode := CW;
        3: TempMode := FM;
        4, 5, 6: TempMode := Digital;
      else TempMode := Phone;
      end;

      VFO[VFOB].Frequency := TempFreq;
      VFO[VFOB].Band := TempBand;
      VFO[VFOB].Mode := TempMode;
    end;

    //3
{
    WriteToSerialCATPort(FT1000MPPoll3String, rig.tr4w_CATPortHandle);
    if not ReadFromCOMPort(8) then
       begin
          ClearRadioStatus;
          goto 1;
       end;

    with rig.CurrentStatus do
       begin
          case (Ord(rig.tBuf[1]) and $13) of

             0:
                begin // Transceive on VFO A
                   Split := NoSplit;
                   VFOA.TXRX := Transceive;
                   VFOB.TXRX := VFODisabled;
                end;

             1:
                begin // Split - VFOB on TX
                   Split := SplitOn;
                   VFOA.TXRX := RXOnly;
                   VFOB.TXRX := TXOnly;
                end;

             2:
                begin // Split - VFOB on RX
                   Split := SplitOn;
                   VFOA.TXRX := TXOnly;
                   VFOB.TXRX := RXOnly;
                end;

             $10:
                begin // Transceive on VFO B
                   Split := NoSplit;
                   VFOA.TXRX := VFODisabled;
                   VFOB.TXRX := Transceive;
                end;

          end;

       end;
}
    1:
    UpdateStatus(rig);
  until rig.tPollCount < 0;
end;

procedure pFT736R(rig: RadioPtr);
begin
//  WriteToSerialCATPort(FT767CATEnablePollingString, rig.tCATPortHandle)
  rig.WritePollRequest(FT767CATEnablePollingString, length(FT767CATEnablePollingString));
end;

procedure pFT767(rig: RadioPtr);
label
  1;
var
  TempMode                              : ModeType;
begin
  repeat

    if rig.tPollCount mod 2 <> 0 then
//      WriteToSerialCATPort(FT767CATEnablePollingString, rig.tCATPortHandle)
      rig.WritePollRequest(FT767CATEnablePollingString, length(FT767CATEnablePollingString))
    else
//      WriteToSerialCATPort(FT767PollString, rig.tCATPortHandle);
      rig.WritePollRequest(FT767PollString, length(FT767PollString));

    if not ReadFromCOMPort(5, rig) then goto 1;
//    WriteToSerialCATPort(FT767ACKString, rig.tCATPortHandle);
    rig.WritePollRequest(FT767ACKString, length(FT767ACKString));

    inc(rig.tPollCount);
    if not ReadFromCOMPort(86, rig) then
    begin
      ClearRadioStatus(rig);
      goto 1;
    end;

    {
    //    rig.tBuf[86] := #$82;
        rig.tBuf[85] := #0;
        rig.tBuf[84] := #$70;
        rig.tBuf[83] := #$04;
        rig.tBuf[82] := #$10;
    //VFOA
        rig.tBuf[85 - 7] := #0;
        rig.tBuf[84 - 7] := #$70;
        rig.tBuf[83 - 7] := #$04;
        rig.tBuf[82 - 7] := #$10;
    //VFOB
        rig.tBuf[85 - 19] := #0;
        rig.tBuf[84 - 19] := #$70;
        rig.tBuf[83 - 19] := #$00;
        rig.tBuf[82 - 19] := #$00;
    }
    rig.CurrentStatus.Freq := GetFrequencyFromBCD(4, @rig.tBuf[82]) * 10 + rig^.FrequencyAdder;
    rig.CurrentStatus.VFO[VFOA].Frequency := GetFrequencyFromBCD(4, @rig.tBuf[82 - 7]) * 10;
    rig.CurrentStatus.VFO[VFOB].Frequency := GetFrequencyFromBCD(4, @rig.tBuf[82 - 19]) * 10;
    CalculateBandMode(rig.CurrentStatus.Freq, rig.CurrentStatus.Band, rig.CurrentStatus.Mode);

    case Ord(rig.tBuf[86]) mod 8 of
      0: TempMode := Phone;
      1: TempMode := Phone;
      2: TempMode := CW;
      3: TempMode := Phone;
      4: TempMode := FM;
      5: TempMode := Digital;
    end;
    rig.CurrentStatus.Mode := TempMode;

    1:
    UpdateStatus(rig);
  until rig.tPollCount < 0;
end;

procedure pFTDX9000(rig: RadioPtr);
label
  1;
var
  TempVFO                               : VFOStatusType;
begin
  repeat
    inc(rig.tPollCount);

//    WriteToSerialCATPort('IF;', rig.tCATPortHandle); {information}
    rig.WritePollRequest('IF;', 3);
{$IF NOT POLLINGDEBUG}
    if ((not ReadFromCOMPort(27, rig)) or (PWORD(@rig.tBuf)^ <> $4649)) then begin ClearRadioStatus(rig);
      goto 1;
    end;
{$IFEND}

{$IF POLLINGDEBUG}
    SetVFOA(rig);
{$IFEND}
    GetVFOInfoForFT2000(@rig.tBuf, rig.CurrentStatus.VFO[VFOA], rig.FrequencyAdder);

    {opposite band information}
    //WriteToSerialCATPort('OI;', rig.tCATPortHandle);
    rig.WritePollRequest('OI;', 3);

{$IF NOT POLLINGDEBUG}
    if ((not ReadFromCOMPort(27, rig)) or (PWORD(@rig.tBuf)^ <> $494F)) then begin ClearRadioStatus(rig);
      goto 1;
    end;
{$IFEND}

{$IF POLLINGDEBUG}
    SetVFOB(rig);
{$IFEND}
    GetVFOInfoForFT2000(@rig.tBuf, rig.CurrentStatus.VFO[VFOB], rig.FrequencyAdder);
{
FR
FT450  - NO
FT950  - FUNCTION RX
FT2000 - FUNCTION RX
FT9000 - RECEIVER STATUS
}
    TempVFO := rig.CurrentStatus.VFO[VFOA];
    rig^.CurrentStatus.VFOStatus := VFOA;

    if rig.RadioModel in [FT950, FT2000, FTDX9000] then
    begin
      {function rx}
//      WriteToSerialCATPort('FR;', rig.tCATPortHandle);
      rig.WritePollRequest('FR;', 3);
{$IF NOT POLLINGDEBUG}
      if ((not ReadFromCOMPort(4, rig)) or (PWORD(@rig.tBuf)^ <> $5246)) then begin ClearRadioStatus(rig);
        goto 1;
      end;
{$IFEND}

{$IF POLLINGDEBUG}
      rig.tBuf[3] := '1';
{$IFEND}
      if rig.tBuf[3] = '4' then
      begin
        TempVFO := rig.CurrentStatus.VFO[VFOB];
        rig^.CurrentStatus.VFOStatus := VFOB;
      end
      else
      begin
//        TempVFO := rig.CurrentStatus.VFOA;
//        rig^.CurrentStatus.VFOStatus := vfoA;
      end;
    end;

    rig.CurrentStatus.Freq := TempVFO.Frequency;
    rig.CurrentStatus.Band := TempVFO.Band;
    rig.CurrentStatus.Mode := TempVFO.Mode;
//    Windows.SetWindowText(tr4whandle, inttopchar(integer(rig.CurrentStatus.Mode)));
    rig.CurrentStatus.RITFreq := TempVFO.RITFreq;
    rig.CurrentStatus.RIT := TempVFO.RIT;
    rig.CurrentStatus.XIT := TempVFO.XIT;
    1:
    UpdateStatus(rig);
  until rig.tPollCount < 0;
end;

function ReadFromSerialPort(BytesToRead: Cardinal; rig: RadioPtr): boolean;
var
  BytesRead                             : Cardinal;
begin
  Result := False;
  if BytesToRead > SizeOf(rig^.tBuf) then Exit;

  if Windows.ReadFile(rig.tCATPortHandle, rig^.tBuf, BytesToRead, BytesRead, nil {rig^.pOver}) then
    if BytesToRead = BytesRead then Result := True;
end;

procedure ClearRadioStatus(rig: RadioPtr);
begin
{
  if rig.FilteredStatus.TXOn then
  begin
    tPTTStatus := PTT_OFF;
    PTTStatusChanged;
  end;
}
  Windows.ZeroMemory(@rig^.CurrentStatus, SizeOf(rig^.CurrentStatus));
  Windows.ZeroMemory(@rig^.FilteredStatus, SizeOf(rig^.FilteredStatus));
  rig.CurrentStatus.Mode := NoMode;
  rig.FilteredStatus.Mode := NoMode;
  rig.LastDisplayedFreq := 0;
end;

procedure WriteToDebugFile(port: PortType; MessageType: DebugFileMessagetype; p: PChar; Count: Cardinal);
var
  DirectionChar                         : PChar;
  i, lpNumberOfBytesWritten             : Cardinal;
  P1                                    : PChar;
  tChar                                 : Char;
  bgColor                               : PChar;
  h                                     : HWND;

const
  InOutArray                            : array[DebugFileMessagetype] of PChar = ('PC >', 'PC <', 'Error');
begin
  if MessageType = dfmRX then bgColor := ' BGCOLOR=#00FF00';
  if MessageType = dfmTX then bgColor := nil;
  if MessageType = dfmError then bgColor := ' BGCOLOR=#FFFF00';

  DirectionChar := InOutArray[MessageType];

  P1 := GetFullTimeString(True);
  asm
  push count
  push p
  push DirectionChar
  push p1
  push bgcolor
  end;
  lpNumberOfBytesWritten := wsprintf(TempBuffer1, '<TR%s><TD>%s</TD><TD>%s</TD><TD>%s</TD><TD>%d</TD><TD>');
  asm add esp,28
  end;
  h := CPUKeyer.tDebugFile[port];
  sWriteFile(h, TempBuffer1, lpNumberOfBytesWritten);
  if Count > 0 then
  begin
    for i := 0 to Count - 1 do
    begin
      tChar := p[i]; //rig.tBuf[I];
      asm
               movzx eax,tChar
               push eax
      end;
      lpNumberOfBytesWritten := wsprintf(TempBuffer1, '[%#x]');
      asm add esp,12
      end;
      sWriteFile(h, TempBuffer1, lpNumberOfBytesWritten);
    end;
  end;
  sWriteFile(h, '</TD></TR>'#13#10, 12);
end;
{
function WriteToSerialCATPort(data: Str80; port: HWND): Cardinal;
begin
//  if NoPollDuringPTT then while tPTTStatus = PTT_ON do Sleep(100);
  tWriteFile(port, data[1], length(data), Result);
  if CPUKeyer.SerialPortDebug then
  begin
    if port = Radio1.tCATPortHandle then
      WriteToDebugFile(Radio1.tCATPortType, dfmTX, @data[1], Result);

    if port = Radio2.tCATPortHandle then
      WriteToDebugFile(Radio2.tCATPortType, dfmTX, @data[1], Result);
  end;
end;
}

function GetFrequencyForYaesu3(p: PChar): Cardinal;
{
begin
  Result := (Ord(p[0]) * 65536 + Ord(p[1]) * 256 + Ord(p[2])) * 10;
end;

function GetFrequencyForYaesu4(p: PChar): Cardinal;

begin

  Result :=
    Ord(p[0]) * 256 * 256 * 256 +
    Ord(p[1]) * 256 * 256 +
    Ord(p[2]) * 256 +
    Ord(p[3]);

end;

function GetFrequencyFromBCD(Count: Cardinal; Addr: PChar): Cardinal;

var
  F1                                    : Cardinal;
const
  c                                     = 1;
begin
  if Count = 5 then
  begin
    F1 := (Ord(Addr[5 - c]) and $F0) shr 4;  // 1000s of mhz
    F1 := F1 * 10;
    F1 := F1 + (Ord(Addr[5 - c]) and $0F); // 100s of mhz
    F1 := F1 * 10;
  end
  else
    F1 := 0;

  F1 := F1 + ((Ord(Addr[4 - c]) and $F0) shr 4); // 10s of mhz
  F1 := F1 * 10;
  F1 := F1 + (Ord(Addr[4 - c]) and $0F); // 1s of mhz
  F1 := F1 * 10;

  F1 := F1 + ((Ord(Addr[3 - c]) and $F0) shr 4);
  F1 := F1 * 10;
  F1 := F1 + (Ord(Addr[3 - c]) and $0F);
  F1 := F1 * 10;

  F1 := F1 + ((Ord(Addr[2 - c]) and $F0) shr 4);
  F1 := F1 * 10;
  F1 := F1 + (Ord(Addr[2 - c]) and $0F);

  if F1 > $CCCCCCC then //MAXLONG/10
  begin
    Result := 0;
    Exit;
  end;

  F1 := F1 * 10;

  F1 := F1 + ((Ord(Addr[1 - c]) and $F0) shr 4);

  if F1 > $CCCCCCC - 256 then //MAXLONG/10-256
  begin
    Result := 0;
    Exit;
  end;

  F1 := F1 * 10;

  F1 := F1 + (Ord(Addr[1 - c]) and $0F);

  Result := F1;
end;

procedure UpdateStatus(rig: RadioPtr);
var
  StatusChanged                         : boolean;
  TempInteger                           : integer;
begin
  StatusChanged := False;
  //CompareString(LOCALE_SYSTEM_DEFAULT, 0, @rig.CurrentStatus, SizeOf(RadioStatusRecord), @rig.PreviousStatus, SizeOf(RadioStatusRecord)) <> 2;
  for TempInteger := 0 to SizeOf(RadioStatusRecord) - 1 do
  begin
    if PChar(@rig.CurrentStatus)[TempInteger] <> PChar(@rig.PreviousStatus)[TempInteger] then
    begin
      StatusChanged := True;
      Break;
    end;
  end;

  if StatusChanged = True then
  begin
    DisplayCurrentStatus(rig);
    rig.FilteredStatusChanged := True;
  end
  else
  begin
    if rig.FilteredStatusChanged then
    begin
      rig.FilteredStatus := rig.CurrentStatus;
      ProcessFilteredStatus(rig);
      rig.FilteredStatusChanged := False;
    end;
  end;
  rig.PreviousStatus := rig.CurrentStatus;
end;

procedure ProcessFilteredStatus(rig: RadioPtr);
var
  dif                                   : integer;
begin
  if rig = ActiveRadioPtr then
  begin
    dif := Abs(rig.FilteredStatus.Freq - rig.LastDisplayedFreq);
    if rig.LastDisplayedFreq <> 0 then
      if dif > AutoSAPEnableRate then
        if dif <= 10000 then
          if AutoSAPEnable then
            if OpMode = CQOpMode then
              SetOpMode(SearchAndPounceOpMode);
     pTTStatusChanged;
    if rig.FilteredStatus.Freq = 0 then Exit;

    if (rig.BandMemory <> rig.FilteredStatus.Band) or (rig.ModeMemory <> rig.FilteredStatus.Mode) then
    begin
      ActiveBand := rig.FilteredStatus.Band;
      ActiveMode := rig.FilteredStatus.Mode;
      DisplayBandMode(ActiveBand, ActiveMode, False);
      VisibleDupeSheetChanged := True;

      DisplayCodeSpeed;
      DisplayAutoSendCharacterCount;
      VisibleLog.ShowRemainingMultipliers; //wli

      if QSONumberByBand then DisplayNextQSONumber;

      ShowFMessages(0);
    end;

    if ((rig.FilteredStatus.Freq <> BandMapCursorFrequency) or
      (BandMapMode <> ActiveMode)) and (rig.FilteredStatus.Freq <> 0) then
    begin
      SpotsList.DisplayCallsignOnThisFreq(rig.FilteredStatus.Freq);
      BandMapCursorFrequency := rig.FilteredStatus.Freq;
      BandMapBand := ActiveBand;
      BandMapMode := ActiveMode;
      DisplayBandMap;
    end;
  end
  else
  begin
    if TuneDupeCheckEnable then
    begin
      SpotsList.TuneDupeCheck(rig.FilteredStatus.Freq);
    end;

    if (rig.BandMemory <> rig.FilteredStatus.Band) or (rig.ModeMemory <> rig.FilteredStatus.Mode) then
    begin
      InActiveRadioPtr.UpdateBandOutputInfo(rig.FilteredStatus.Band, rig.FilteredStatus.Mode);
    end;

//GAV added this section. Changes BandmapBand & Bandmap Mode to follow inactive radio when inactive radio is tuned

    if ((rig.FilteredStatus.Freq <> BandMapCursorFrequency) or
      (BandMapMode <> ActiveMode)) and (rig.FilteredStatus.Freq <> 0) then
    begin
      BandmapBand := rig.FilteredStatus.Band;
      BandMapMode := rig.FilteredStatus.Mode;
      VisibleDupeSheetChanged := True;
      BandMapCursorFrequency := rig.FilteredStatus.Freq;
      DisplayBandMap;
    end;

 //GAV End of added

  end;
{$IF tDebugMode}
{
  if boolean(tPTTStatus) <> rig.FilteredStatus.TXOn then
  begin
    tPTTStatus := PTTStatusType(rig.FilteredStatus.TXOn);
    PTTStatusChanged;
  end;
 
{$IFEND}
  rig.BandMemory := rig.FilteredStatus.Band;
  rig.ModeMemory := rig.FilteredStatus.Mode;
  rig.LastDisplayedFreq := rig.FilteredStatus.Freq;

end;

procedure DisplayCurrentStatus(rig: RadioPtr);
var
  h                                     : HWND;
begin
  if rig = ActiveRadioPtr then SendStationStatus(sstBandModeFreq);
  Windows.SetWindowText(rig^.FreqWindowHandle, FreqToPChar(rig.CurrentStatus.Freq));
  h := rig.tRadioInterfaceWndHandle;
  if h = 0 then Exit;
  SetDlgItemText(h, 102, FreqToPChar(rig.CurrentStatus.VFO[VFOA].Frequency));
  SetDlgItemText(h, 104, FreqToPChar(rig.CurrentStatus.VFO[VFOB].Frequency));

  if rig.CurrentStatus.PrevRITFreq <> rig.CurrentStatus.RITFreq then
  begin
{ $ R A NGECHECKS OFF}
    SetDlgItemInt(h, 120, Cardinal(rig.CurrentStatus.RITFreq), rig.CurrentStatus.RITFreq < 0);
{ $ R A NGECHECKS ON}
    rig.CurrentStatus.PrevRITFreq := rig.CurrentStatus.RITFreq;
  end;

  if rig.CurrentStatus.PrevVFOStatus <> rig.CurrentStatus.VFOStatus then
  begin
    if rig.CurrentStatus.VFOStatus = VFOA then
    begin
      EnableWindowTrue(h, 102);
      EnableWindowFalse(h, 104);
    end;
    if rig.CurrentStatus.VFOStatus = VFOB then
    begin
      EnableWindowTrue(h, 104);
      EnableWindowFalse(h, 102);
    end;
    if rig.CurrentStatus.VFOStatus = vfoUnknown then
    begin
      EnableWindowTrue(h, 104);
      EnableWindowTrue(h, 102);
    end;
    rig.CurrentStatus.PrevVFOStatus := rig.CurrentStatus.VFOStatus;
  end;

  Windows.EnableWindow(rig.RITWndHandle, rig.CurrentStatus.RIT);
  Windows.EnableWindow(rig.XITWndHandle, rig.CurrentStatus.XIT);
  Windows.EnableWindow(rig.SplitWndHandle, rig.CurrentStatus.Split);

end;
{
function ReadFromCOMPortOnEvent(b: Cardinal; rig: RadioPtr): boolean;
label
  Start, Wait;
var
  lpEvtMask                             : DWORD;
  lpErrors                              : DWORD;
  lpStat                                : ComStat;
  trial                                 : integer;
begin
//  WaitCommEvent(rig^.tCATPortHandle, lpEvtMask, rig^.pOver);
  Start:
  if not WaitCommEvent(rig^.tCATPortHandle, lpEvtMask, rig^.pOver) then
    if GetLastError = ERROR_IO_PENDING then
//      if SetCommMask(rig^.tCATPortHandle, EV_RXFLAG) then
      if WaitForSingleObject(rig^.lpOverlapped.hEvent, 5000) = WAIT_OBJECT_0 then
      begin
        trial := 0;
        Wait:
        ClearCommError(rig^.tCATPortHandle, lpErrors, @lpStat);
        if lpStat.cbInQue = b then
        begin
          Result := ReadFromSerialPort(b, rig);
          Exit;
        end
        else
          if trial < 5 then
          begin
            inc(trial);
            Sleep(100);
            goto Wait;
          end;
      end;

  ClearCommError(rig^.tCATPortHandle, lpErrors, @lpStat);
  if lpStat.cbInQue <> 0 then
  begin
    ReadFromSerialPort(lpStat.cbInQue, rig);
    PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);
  end;
  Sleep(1000);
  Result := False;

end;
}

function ReadFromCOMPort(b: Cardinal; rig: RadioPtr): boolean;
label
  1;
var
  stat                                  : TComStat;
  Errs                                  : DWORD;
  c                                     : Cardinal;
  SleepMs                               : Cardinal;
begin
{$IF MASKEVENT}
  if rig^.RadioModel = TS850 then
  begin
    Result := ReadFromCOMPortOnEvent(b, rig);
    Exit;
  end;
{$IFEND}

//  if NoPollDuringPTT then while rig.tPTTStatus = PTT_ON do Sleep(100);
  Result := False;
  c := 0;
  stat.cbInQue := 0;

  if rig^.RadioModel in [IC706..OMNI6] then
    SleepMs := IcomResponseTimeout
  else
  begin
    if b < 5 then SleepMs := 100 else SleepMs := 50 {+50};
    if rig^.RadioModel = Orion then SleepMs := 100;
  end;

  while stat.cbInQue < {<>} b do
  begin
    Sleep(SleepMs);
    if rig^.tPollCount < 0 then Exit;
    if not ClearCommError(rig^.tCATPortHandle, Errs, @stat) then
//      asm nop end;
      ShowSysErrorMessage('READ');

    inc(c);
    if c >= b then
    begin
      1:
{
      if CPUKeyer.SerialPortDebug then
      begin
        ReadFromSerialPort(rig^.tCATPortHandle, stat.cbInQue, rig);
        WriteToDebugFile(rig.tCATPortType, dfmError, @rig.tBuf, stat.cbInQue);
      end;
}

      {To view data in Portmon}
      if Errs = 0 then
      begin
        if stat.cbInQue <> 0 then
          ReadFromSerialPort(stat.cbInQue, rig);
      end
      else
      begin
        showint(Errs);
        Sleep(100);
      end;

      PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);
      ClearCommError(rig^.tCATPortHandle, Errs, @stat);
      Result := False;
      Exit;
    end;
  end;
  rig.tBuf[b + 1] := #0;
  Result := ReadFromSerialPort(b, rig);

  if rig^.RadioModel in [Orion] then
  begin
    if rig.tBuf[1] <> '@' then goto 1;
    if rig.tBuf[b] <> #$0D then goto 1;
  end;

  if rig^.RadioModel in [TS850] then if rig.tBuf[b] <> ';' then goto 1;

  if rig^.RadioModel in [IC706..OMNI6] then
  begin
    if (PWORD(@rig.tBuf[1])^ <> $FEFE) then goto 1;

    if rig.tBuf[3] = #0 then
      if not rig.tDisableCIVTransceive then
      begin
        rig.tDisableCIVTransceive := True;
        showwarning(TC_DISBALE_CIV);
      end;

    if (rig.tBuf[b] <> ICOM_END_OF_MESSAGE_CODE) or
      (rig.tBuf[4] <> ICOM_CONTROLLER_ADDRESS) then goto 1;
  end;

end;

procedure BeginPolling(rig: RadioPtr); stdcall;
begin
  Sleep(100);
  PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);

  Windows.ZeroMemory(@rig.tBuf, SizeOf(rig.tBuf));

  case rig^.RadioModel of
    TS850, K2, K3:
      begin
{$IF MASKEVENT}
        pKenwoodNew(rig);
{$ELSE}
        pKenwood2(rig);
{$IFEND}

      end;
    FT767: pFT767(rig);
    FT736R: pFT736R(rig);
    FT747GX: pFT747GX(rig);
    FT817, FT847, FT857, FT897: pFT817_FT847_FT857_FT897(rig);
    FT840, FT890, FT900: pFT840_FT890_FT900(rig);
    FT920: pFT920(rig);
    FT990, FT1000: pFT990_FT1000(rig);
    FT1000MP: pFT1000MP(rig);
    FT100: pFT100(rig);
    FT450, FT950, FT2000, FTDX9000: pFTDX9000(rig);
    IC706..IC7800, OMNI6:
      pIcomNew(rig);
//    pIcom(rig);

{$IF MASKEVENT}
//    Orion: pOrionNew(rig);
{$ELSE}
//    Orion: pOrion(rig);
    Orion: pOrion3(rig);
{$IFEND}

  end;
end;

procedure SetDCBForIcom(port: HWND);
var
  TDCB                                  : _DCB;
begin
  GetCommState(port, TDCB);
//  tDCB.EofChar := #$FD;
//  tdcb.XoffLim := 1;
//  tdcb.XonLim := 1;
  SetCommState(port, TDCB);
  SetCommMask(port, EV_RXCHAR);
end;

function ReadICOM(b: Cardinal; rig: RadioPtr): boolean;
//var
//  Mask                        : Cardinal;
//  stat                        : TComStat;
//  Errs                        : DWORD;
begin
  Result := ReadFromCOMPort(b, rig);
{
  exit;
  result := false;
  WaitCommEvent(rig.tr4w_CATPortHandle, mask, @rig.ICOM_OVERLAPPED);
  if mask = EV_RXCHAR then
  begin
    rig.tBuf[b + 1] := #0;
    Result := ReadFromSerialPort(rig^.tr4w_CATPortHandle, b, True, rig);
  end;
}
end;

function BufferToInt(buf: PChar; StartPos, EndPos: integer): integer;
var
  i                                     : integer;
  negative                              : boolean;
begin
  negative := False;
  Result := 0;
  for i := StartPos - 1 to StartPos + EndPos - 2 do
  begin
    if not (buf[i] in ['0'..'9', '+', '-']) then
    begin
      Result := 0;
      Exit;
    end;
    if buf[i] in ['0'..'9'] then Result := Result * 10 + (Ord(buf[i]) - 48);
    if buf[i] = '-' then negative := True;
  end;
  if negative then Result := Result * -1;
end;

procedure GetVFOInfoForFT2000(buf: PChar; var VFO: VFOStatusType; FrequencyAdder: integer);
var
  TempMode                              : ModeType;
begin
  VFO.Frequency := BufferToInt(buf, 6, 8) + FrequencyAdder;
  CalculateBandMode(VFO.Frequency, VFO.Band, VFO.Mode);
  VFO.RITFreq := BufferToInt(buf, 14, 5);
  VFO.RIT := buf[19 - 1] = '1';
  VFO.XIT := buf[20 - 1] = '1';
  case buf[21 - 1] of
    '1': TempMode := Phone;
    '2': TempMode := Phone;
    '3': TempMode := CW;
    '4': TempMode := FM;
    '5': TempMode := Phone;

    '6': TempMode := Digital;
    '7': TempMode := CW;
    '8': TempMode := Digital;
    '9': TempMode := Digital;

  end;
  VFO.Mode := TempMode;

end;

procedure SetVFOA(rig: RadioPtr);
begin
{$IF POLLINGDEBUG}
  Sleep(500);

  rig.tBuf[6] := '0';
  rig.tBuf[7] := '3';
  rig.tBuf[8] := '6';
  rig.tBuf[9] := CHR(Random(8) + Ord('0'));
  rig.tBuf[10] := '0';
  rig.tBuf[11] := '0';
  rig.tBuf[12] := '0';
  rig.tBuf[13] := '0';

  rig.tBuf[14] := '+';
  rig.tBuf[15] := '1';
  rig.tBuf[16] := '2';
  rig.tBuf[17] := '3';
  rig.tBuf[18] := '4';

  rig.tBuf[21] := '2';
{$IFEND}
end;

procedure SetVFOB(rig: RadioPtr);
begin
{$IF POLLINGDEBUG}
  Sleep(500);
  rig.tBuf[6] := '2';
  rig.tBuf[7] := '1';
  rig.tBuf[8] := '2';
  rig.tBuf[9] := CHR(Random(8) + Ord('0'));
  rig.tBuf[10] := '0';
  rig.tBuf[11] := '0';
  rig.tBuf[12] := '0';
  rig.tBuf[13] := '0';

  rig.tBuf[14] := '+';
  rig.tBuf[15] := '1';
  rig.tBuf[16] := '2';
  rig.tBuf[17] := '3';
  rig.tBuf[18] := '4';

  rig.tBuf[21] := '1';
{$IFEND}
end;

function getIcomResponceSpeed(rig: RadioPtr): boolean;
label
  1;
var
  c                                     : Cardinal;
  stat                                  : TComStat;
  Errs                                  : DWORD;
  counter                               : integer;
begin
  Result := False;
  counter := 0;
  rig.SendIcomCommand(3);
  if rig.RadioModel = IC735 then c := 16 else c := 17;
  ClearCommError(rig^.tCATPortHandle, Errs, @stat);
  1:
  if stat.cbInQue <> c then
  begin
    inc(counter);
    Sleep(10);
    if counter < 100 then goto 1;
  end
  else
  begin
    Result := True;
    IcomResponseTimeout := (counter * 10) div c;
  end;
  PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);
end;

procedure PTTStatusChanged;
begin
  if ActiveRadioPtr.tPTTStatus = PTT_ON then      
    tr4w_PTTStartTime := GetTickCount  ;
//  else      //n4af 04.30.3
   begin          
    if tr4w_PTTStartTime <> 0 then
      tRestartInfo.riPTTOnTotalTime := tRestartInfo.riPTTOnTotalTime + GetTickCount - tr4w_PTTStartTime;
    tDispalyOnAirTime;
  end;
  SetMainWindowText(mwePTTStatus, PTTStatusString[ActiveRadioPtr.tPTTStatus]);
  SendStationStatus(sstPTT);
end;

function GetFrequencyForYaesuFT747(a: PChar): Cardinal;
var
  c                                     : integer;
begin
  Result := 0;
  for c := 0 to 4 do
  begin
    Result := Ord(a[c]) div 16 + (Result * 10);
    Result := Ord(a[c]) mod 16 + (Result * 10);
  end;
end;

end.
