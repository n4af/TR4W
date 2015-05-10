{
 Copyright Larry Tyree, N6TR, 2011,2012,2013,2014,2015.

 This file is part of TR4W    (TRDOS)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W.  If not, see
 <http: www.gnu.org/licenses/>.
 }
unit LOGDVP;

{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  LogK1EA,
  Messages,
utils_text,
utils_file,
  Windows,
  MMSystem,
  LogRadio,
  LogWind,
  uCTYDAT,
  Tree;

type
  PlayResult = (prOK, prCantPlay, prExitThread);

const
  MaxDVPMessageLength                   = 20;
  DVPArraySize                          = 30;

var

//  CfgDvpPath                            : Str40 = '';
  Count                                 : integer;
//  DVPPath                               : ShortString;

  PlayWAVThread, PlayWAVThreadID        : Cardinal;
  WAVFileToPlay                         : array[0..255] of Char;
  DVPMessagesArray                      : array[1..DVPArraySize] of Str40;
  DVPMessagesArrayIndex                 : integer = 1;
  DVPThreadID                           : Cardinal;
  tUseRecordedSigns                     : boolean;
  tMissCallsFileEnable                  : boolean;
//  MissedCallsignsListInitialized        : boolean;
//  MissedWAVCallsigns                    : integer = -1;
//  MissedWAVCallsignsListbox             : HWND;
  BackCopyEnable                        : boolean;
  DVPSetUp                              : boolean;
  SBDVPActive                           : boolean;

function DVPActive: boolean;
function DVPMessagePlaying: boolean;

//procedure StartBackCopy;
procedure StopBackCopy;
procedure SaveBackCopy(QSONumber: integer; Seconds: integer);
//procedure SaveBackCopyFile(FileName: Str40; Seconds: integer);
procedure DVPCommand(Command: integer; FileName: Str80; UseDVPPath: boolean);
procedure DVPListenMessage(FileName: Str80; UseDVPPath: boolean);
procedure DVPRecordMessage(FileName: Str80; OnAir: boolean);
procedure DVPInit;
procedure DVPUnInit;
procedure DVPStopPlayback;
procedure SetMicGain(Gain: Byte);
procedure SetOutGain(Gain: Byte);

function tGetWAVDurationFromHeader(FileName: PChar; var Duration: Cardinal; DisplayError: boolean): boolean;
procedure tDVPPlayThreadproc;
procedure tWriteCallsignToMissingCallsignsFile(Callsign: PChar);

procedure EnumMISSINGCALLSIGNSTXT(FileString: PShortString);

function tsndPlaySound(lpszSoundName: PChar): BOOL;
function PlayWAVFile(f: PChar; DisplayError: boolean): PlayResult;

implementation
uses
  MainUnit,
  LogStuff;

const
  DVPGetPtr                             = 0;
  DVPRecRX                              = 2;
  DVPRecMic                             = 3; {SBDVP too}
  DVPPlay                               = 4; {SBDVP too}
  DVPStopPlay                           = 5; {SBDVP too}
  DVPStopRec                            = 6;
  DVPCloseAll                           = 10;
  DVPR2H                                = 11;
  DVPF2H                                = 12;
  DVPM2H                                = 13;
  DVPF2M                                = 14;
  DVPM2M                                = 15;
  DVPR2F                                = 16;
  DVPM2F                                = 17;
  DVPRXEn                               = 18;
  DVPRXDis                              = 19;
  DVPMicEn                              = 20;
  DVPMicDis                             = 21;
  DVPInGain                             = 22;
  DVPOutGain                            = 23;
  DVPMon                                = 24;
  DVPNoMon                              = 25;
  DVPOnAir                              = 26; {SBDVP too}
  DVPOffAir                             = 27; {SBDVP too}
  DVPBackCopy                           = 28;
  DVPNoBackCopy                         = 29;
  DVPSaveBackCopy                       = 30;
  DVPPTT                                = 31;
  DVPNoPTT                              = 32;
  DVPRpt                                = 33;
  DVPNoRpt                              = 34;
  DVPBeep                               = 37;
  DVPQuiet                              = 39;
  DVPDisableHK                          = 40;
  DVPEnableHK                           = 41;
  DVPIsActive                           = 43; {SBDVP too}

  R2H                                   = $1; { RX to HeadSet     }
  F2H                                   = $2; { D/A to Headset    }
  M2H                                   = $4; { Mic In to Headset }
  F2M                                   = $8; { D/A to Mic Out    }
  PTT                                   = $40; { PTT control       }

  { Record control values }

  M2M                                   = $10; { Mic In to Mic Out }
  R2F                                   = $20; { RX to A/D         }
  M2F                                   = $40; { Mic to A/D        }

type
  DVPSharedMemory = record
    FileName: array[1..64] of Char;
    FileOpen: integer; { + 40h bytes }
    Command: integer; { + 42h bytes }
    Handle: integer; { + 44h bytes }
    RepeatDelay: integer; { + 46h bytes }
    Start: LONGINT; { + 48h bytes }
    length: LONGINT; { + 4Ch bytes }
    InputGain: Byte; { + 50h bytes }
    OutputGain: Byte; { + 51h bytes }
    XmitControl: Byte; { + 52h bytes }
    RecControl: Byte; { + 53h bytes }
  end;

  SharedMemoryPointer = ^DVPSharedMemory;

var
  SharedMemorySegment, SharedMemoryOffset: Word;
//  SharedMemory                          : SharedMemoryPointer;

function DVPActive: boolean;

var
  DVPEntryOffset, DVPEntrySegment       : Word;

begin
  {    DVPActive := False;
      SBDVPActive := False; //KK1L: 6.65 Added direct support of SBDVP

      DVPEntryOffset  := MemW [0: 4 * $60];
      DVPEntrySegment := MemW [0: 4 * $60 + 2];

      IF (DVPEntryOffset = 0) OR (DVPEntrySegment < 8) THEN Exit;

  //    {KK1L: 6.65 Changed TSR check to allow for SBDVP unique ID
  //    {           This looks for ID from K1EA TSR or SBDVP version
  //    {           1.2 or earlier which had a bug and interpreted
  //    {           DVPIsActive as DVPStopPlay.
      IF Mem [DVPEntrySegment : DVPEntryOffset - 8] = Ord ('D') THEN
        IF Mem [DVPEntrySegment : DVPEntryOffset - 7] = Ord ('V') THEN
          IF Mem [DVPEntrySegment : DVPEntryOffset - 6] = Ord ('P') THEN
            IF Mem [DVPEntrySegment : DVPEntryOffset - 5] = Ord ('T') THEN
              IF Mem [DVPEntrySegment : DVPEntryOffset - 4] = Ord ('S') THEN
                IF Mem [DVPEntrySegment : DVPEntryOffset - 3] = Ord ('R') THEN
                  IF Mem [DVPEntrySegment : DVPEntryOffset - 2] = Ord ('0') THEN
                    IF Mem [DVPEntrySegment : DVPEntryOffset - 1] = Ord ('0') THEN
                      BEGIN
                      DVPActive := True;
                      Exit;
                      END;

  //    {KK1L: 6.65 Look for SBDVP000. Says SBDVP version 1.02 or greater
  //    {           by Kevin Schmidt is loaded
      IF Mem [DVPEntrySegment : DVPEntryOffset - 8] <> Ord ('S') THEN Exit;
      IF Mem [DVPEntrySegment : DVPEntryOffset - 7] <> Ord ('B') THEN Exit;
      IF Mem [DVPEntrySegment : DVPEntryOffset - 6] <> Ord ('D') THEN Exit;
      IF Mem [DVPEntrySegment : DVPEntryOffset - 5] <> Ord ('V') THEN Exit;
      IF Mem [DVPEntrySegment : DVPEntryOffset - 4] <> Ord ('P') THEN Exit;
      IF Mem [DVPEntrySegment : DVPEntryOffset - 3] <> Ord ('0') THEN Exit;
      IF Mem [DVPEntrySegment : DVPEntryOffset - 2] <> Ord ('0') THEN Exit;
      IF Mem [DVPEntrySegment : DVPEntryOffset - 1] <> Ord ('0') THEN Exit;
      DVPActive := True;
      SBDVPActive := True;
     }
end;
{
procedure SetLength(Seconds: integer);

var
  TempInt                               : LONGINT;
  TempString                            : Str80;

begin
  TempInt := Seconds;
  TempInt := TempInt * 2 * 9600;
  SharedMemory^.length := TempInt;
end;
}

procedure SetTransmitControl(Bytes: Byte);

begin
  //{WLI}    Mem [SharedMemorySegment : SharedMemoryOffset + $52] := Bytes;
end;

procedure SetRecordControl(Bytes: Byte);

begin
  //{WLI}    Mem [SharedMemorySegment : SharedMemoryOffset + $53] := Bytes;
end;

procedure DVPCommand(Command: integer; FileName: Str80; UseDVPPath: boolean);

var
  Count, Offset                         : integer;
  //    Regs: Registers;
  TempStr                               : Str80;

begin
  {    DVPSetFileName (FileName, UseDVPPath);

      Regs.AX := $FF;

      Count := 0;

      MemW [SharedMemorySegment : SharedMemoryOffset + $42] := Command;
      WHILE Regs.AX <> 0 DO
          BEGIN
          MemW [SharedMemorySegment : SharedMemoryOffset + $42] := Command;

          Regs.DI := $FF;

          Intr ($60, Regs);
          Inc (Count);

          IF Count > 1000 THEN Exit;

          Wait (2);
          END;

      {IF Command <> 43 THEN
        BEGIN
        Str(Command, TempStr);
        TempStr := 'DVPCommand ' + TempStr + ' press DownArrow';      //”¡–¿ÕŒ Õ≈ ÃÌÓ…!!!!!!!
        QuickDisplay2(TempStr);
        REPEAT UNTIL NewReadKey = DownArrow;
        END
      ELSE

}
end;

procedure SetMicGain(Gain: Byte);

begin
  //    Mem [SharedMemorySegment : SharedMemoryOffset + $50] := Gain;
end;

procedure SetOutGain(Gain: Byte);

begin
  //    Mem [SharedMemorySegment : SharedMemoryOffset + $51] := Gain;
end;

procedure TypicalDVPStartUp;

begin
  DVPCommand(DVPDisableHK, '', False);
  Sleep(10);
  DVPCommand(DVPMicEn, '', False);
  Sleep(10);
  DVPCommand(DVPRXEn, '', False);
  Sleep(10);
  DVPCommand(DVPR2H, '', False);
  Sleep(10);
  DVPCommand(DVPM2M, '', False);
  Sleep(10);
  DVPCommand(DVPPTT, '', False);
  Sleep(10);
  DVPCommand(DVPOnAir, '', False);
  Sleep(10);

  SetMicGain(8);
  DVPCommand(DVPInGain, '', False);
  Sleep(10);

  SetOutGain(8);
  DVPCommand(DVPOutGain, '', False);
  Sleep(10);
end;

procedure DVPRecordMessage(FileName: Str80; OnAir: boolean);

begin
  {    IF NOT DVPSetUp THEN Exit;

      SetLength (MaxDVPMessageLength);

      IF OnAir THEN
          BEGIN
          SetRecordControl (M2F OR F2M OR PTT);
          SetTransmitControl (M2M OR PTT);
          DVPCommand (DVPOnAir, FileName, True);
          END
      ELSE
          BEGIN
          SetRecordControl (M2F);
          SetTransmitControl (M2H);
          END;

      DVPCommand (DVPRecMic, FileName, True);
      REPEAT UNTIL KeyPressed;
      IF ReadKey = NullKey THEN ReadKey;
      DVPCommand (DVPStopRec, '', True);
      DVPCommand (DVPCloseAll, '', True);
      DVPCommand (DVPOffAir, FileName, True);
     }
end;

procedure DVPListenMessage(FileName: Str80; UseDVPPath: boolean);

begin
  if not DVPSetUp then Exit;
  SetTransmitControl(F2H);
  DVPCommand(DVPPlay, FileName, UseDVPPath);
end;

procedure DVPStopPlayback;

begin
  if not ((DVPSetUp) and (DVPMessagePlaying)) then Exit;

  DVPCommand(DVPStopPlay, '', False);
end;

procedure DVPUnInit;

var
  Key                                   : Char;

begin

  {    IF DVPPath <> '' THEN
          BEGIN
          REPEAT
              Key := UpCase (GetKey ('Save DVP files in ' + DVPPath + ' to the current directory? (Y/N) : '));
              IF Key = EscapeKey THEN Exit;
          UNTIL (Key = 'Y') OR (Key = 'N');
          WriteLn;

          IF Key = 'Y' THEN
              BEGIN
              WriteLn ('Copying DVP files from ', DVPPath);
              CopyFiles (DVPPath, '*.DVP', '');
              END;
          END;
     }
end;

procedure DVPInit;
{var
   devs                            : Cardinal;
   WAVEINCAPS1                     : PWaveInCapsA;
   s                               : string;
  }
begin
  //DVPSetUp := False;
  //if MMSystem.waveInGetNumDevs > 0 then
  DVPSetUp := True;
  {   waveInGetDevCaps(0, WAVEINCAPS1, SizeOf(WAVEINCAPS));
     System.SetLength(s, 31);
     s := WAVEINCAPS1.szPname;
     ShowMessage(s);
  }
     {    IF NOT DVPActive THEN
             BEGIN
             WriteLn ('DVPTSR is not loaded!!');
             Halt;
             END;

     //      Determine DVP Path and if it exists, copy messages from the current
     //      directory to it.

         Write ('1');

         DVPPath := '';

         IF CFGDVPPath <> '' THEN
             BEGIN
             Write ('2');
             DVPPath := CFGDVPPath;
             WriteLn ('Copying DVP files to ', DVPPath);

             CopyFiles ('', '*.DVP', DVPPath);
             END
         ELSE
             BEGIN
             Write ('3');
             FOR Count := 1 TO EnvCount DO
                 IF StringHas (UpperCase (EnvStr (Count)), 'DVPPATH') THEN
                     BEGIN
                     DVPPath := PostcedingString (UpperCase (EnvStr (Count)), '=');

                     WriteLn ('Copying DVP files to ', DVPPath);

                     IF DVPPath [Length (DVPPath)] <> '\' THEN
                         DVPPath := DVPPath + '\';

                     WriteLn ('Copying DVP files to ', DVPPath);
                     CopyFiles ('', '*.DVP', DVPPath);
                     Break;
                     END;
             END;

         Write ('4');

         IF NOT SetUpSharedMemoryAddress THEN
             BEGIN
             DVPSetUp := False;
             Exit;
             END;

         TypicalDVPStartup;
         DVPOn := True;
         DVPSetUp := True;
         IF BackCopyEnable THEN StartBackCopy;
        }
end;
{
procedure StartBackCopy;

begin
  if not DVPSetUp then Exit;
  SetLength(30);
  DVPCommand(DVPBackCopy, 'BACKCOPY.WAV', True);
end;
}

procedure StopBackCopy;

begin
  if not DVPSetUp then Exit;
  DVPCommand(DVPNoBackCopy, 'BACKCOPY.WAV', True);
end;

procedure SaveBackCopy(QSONumber: integer; Seconds: integer);

var
  TempString, FileName                  : Str20;

begin
  {    IF NOT DVPSetUp THEN Exit;
      SetLength (Seconds);

      Str (QSONumber, Filename);

      WHILE FileExists (FileName + '.BCP') DO
          BEGIN
          IF Copy (FileName, Length (FileName), 1) >= 'A' THEN
              BEGIN
              TempString := Copy (FileName, Length (FileName), 1);
              Delete (FileName, Length (FileName), 1);

              TempString [1] := Chr (Ord (TempString [1]) + 1);
              FileName := FileName + TempString;
              END
          ELSE
              FileName := FileName + 'A';
          END;

      DVPCommand (DVPSaveBackCopy, FileName + '.BCP', False);
      SetLength (20);
     }
end;
{
procedure SaveBackCopyFile(FileName: Str40; Seconds: integer);

begin
  if not DVPSetUp then Exit;
  SetLength(Seconds);
  DVPCommand(DVPSaveBackCopy, FileName, False);
  SetLength(20);
end;
}

function DVPMessagePlaying: boolean;

begin
  DVPMessagePlaying := False;
  {
         IF NOT DVPSetUp THEN Exit;
         DVPCommand (DVPIsActive, FileName, False);
         DVPMessagePlaying := (Mem [SharedMemorySegment : SharedMemoryOffset + $42] AND 1) = 1;
  }
end;

function tGetWAVDurationFromHeader(FileName: PChar; var Duration: Cardinal; DisplayError: boolean): boolean;
label
  1;
var
  Head                                  : WavHeader;
  r                                     : REAL;
  h                                     : HWND;
  lpNumberOfBytesRead                   : Cardinal;
begin
  Result := False;
{
  asm
    push FileName
    lea  eax,TR4W_PATH_NAME
    push eax
  end;
  wsprintf(WAVFileToPlay, TWO_STRINGS);
  asm add esp,16
  end;
}
  if TF.tOpenFileForRead(h, FileName {WAVFileToPlay}) then
  begin
    if Windows.ReadFile(h, Head, SizeOf(WavHeader), lpNumberOfBytesRead, nil) = True then
    begin
      if lpNumberOfBytesRead = SizeOf(WavHeader) then
      begin
        Result := True;
        r := int64(1000) * Head.BytesFollowing div Head.SampleRate div Head.BytesPerSample;
        Duration := Trunc(r) + 100;
      end;
    end
    else
    begin
      CloseHandle(h);
      goto 1;
    end;
    CloseHandle(h);
    Exit;
  end;
  1:
  if DisplayError then
  begin
    Format(QuickDisplayBuffer, '%s : %s', FileName, SysErrorMessage(GetLastError));
    QuickDisplay(QuickDisplayBuffer);
  end;
end;

procedure tDVPPlayThreadproc;
label
  ExitLabel, PlayNextMessage, NextMessage;
var
  Index                                 : integer;
  i                                     : integer;
  WAVFile                               : array[0..255] of Char;
  Duration                              : Cardinal;
  TempChar                              : Char;
  Pauselenght                           : Cardinal;
  p                                     : PChar;
  TempPlayResult                        : PlayResult;
const
  DOTWAVASINTEGER                       = 1447122734;
begin
  Index := 1;

  PlayNextMessage:
  if DVPMessagesArray[Index][1] = '*' then
  begin
    Pauselenght := 0;
    for i := 1 to length(DVPMessagesArray[Index]) do
      if DVPMessagesArray[Index][i] = '*' then
        Pauselenght := Pauselenght + 20
      else
        goto NextMessage;
    Sleep(Pauselenght);
    goto NextMessage;
  end;

  p := @DVPMessagesArray[Index][1];

     {Some WAV File}
  if StringHas(DVPMessagesArray[Index], '.WAV') then
  begin
{
    asm
    push p
    lea  eax,TR4W_DVPPATH
    push eax
    end;
    wsprintf(WAVFile, '%s\%s');
    asm add esp,16
    end;
}
    if PlayWAVFile(p, True) = prExitThread then goto ExitLabel;
    goto NextMessage;
  end;

  if tUseRecordedSigns then
  begin
      //QSO Number
    if StringIsAllNumbers(DVPMessagesArray[Index]) then
    begin

      Format(WAVFile, 'FULLSERIALNUMBERS\%s.WAV', p);

      TempPlayResult := PlayWAVFile(WAVFile, False);
      if TempPlayResult = prExitThread then goto ExitLabel;

      if TempPlayResult = prCantPlay then
      begin
        for i := 1 to length(DVPMessagesArray[Index]) do
        begin
          TempChar := DVPMessagesArray[Index][i];
          asm
          xor eax,eax
          mov al,TempChar
          push eax
          end;
          wsprintf(WAVFile, 'LETTERSANDNUMBERS\%C.WAV');
          asm add esp,12
          end;
          if PlayWAVFile(WAVFile, True) = prExitThread then goto ExitLabel;
        end;
      end;

      goto NextMessage;
    end;

      //Callsign

    Format(WAVFile, 'FULLCALLSIGNS\%s.WAV', p);

    TempPlayResult := PlayWAVFile(WAVFile, False);
    if TempPlayResult = prExitThread then goto ExitLabel;

    if TempPlayResult = prCantPlay then
    begin
      tWriteCallsignToMissingCallsignsFile(p);
      for i := 1 to length(DVPMessagesArray[Index]) do
      begin
        TempChar := DVPMessagesArray[Index][i];
        if TempChar = '/' then TempChar := '_';
        asm
        xor eax,eax
        mov al,TempChar
        push eax
        end;
        wsprintf(WAVFile, 'LETTERSANDNUMBERS\%C.WAV');
        asm add esp,12
        end;
        if PlayWAVFile(WAVFile, True) = prExitThread then goto ExitLabel;
      end;
    end;

  end
  else
    Sleep(0);

//  asm nop end;

  NextMessage:
  inc(Index);
  if Index = DVPMessagesArrayIndex then goto ExitLabel else goto PlayNextMessage;

  ExitLabel:
  DVPMessagesArrayIndex := 1;
  PTTOff;

  tStartAutoCQ;

  tExitFromDVPThread := False;
  DVPOn := False;
  DVPThreadID := 0;
  DisplayCodeSpeed;
  Windows.ZeroMemory(@DVPMessagesArray, SizeOf(DVPMessagesArray));
  BackToInactiveRadioAfterQSO;
end;

procedure EnumMISSINGCALLSIGNSTXT(FileString: PShortString);
begin
//  tLB_ADDSTRING(MissedWAVCallsignsListbox, @FileString^[1]);
//  MissedCallsignsList.AddString(FileString^, NoBand, NoMode, True);
//  inc(MissedWAVCallsigns);
end;

procedure tWriteCallsignToMissingCallsignsFile(Callsign: PChar);
label
  1, CallsignFound, NextRead;
var
  TempBuffer                            : array[0..1024 - 1] of Char;
  h                                     : HWND;
  lpNumberOfBytesRead                   : Cardinal;
  p                                     : PChar;
begin
  if not tMissCallsFileEnable then Exit;
  if not LooksLikeACallSign(Callsign) then Exit;
  p := GetRealPath(TR4W_DVKPATH, 'FULLCALLSIGNS\MISSINGCALLSIGNS.TXT', nil);
  h := CreateFile(p, GENERIC_WRITE or GENERIC_READ, FILE_SHARE_WRITE or FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if h = INVALID_HANDLE_VALUE then
  begin
//    ShowSysErrorMessage(p);
    Exit;
  end;

  NextRead:
  Windows.ZeroMemory(@TempBuffer, SizeOf(TempBuffer));
  Windows.ReadFile(h, TempBuffer, SizeOf(TempBuffer), lpNumberOfBytesRead, nil);
  if lpNumberOfBytesRead > 0 then
  begin
    if strpos(TempBuffer, Callsign) <> nil then goto CallsignFound;
    if lpNumberOfBytesRead = SizeOf(TempBuffer) then goto NextRead;
  end;

  swriteFile(h, Callsign^, lstrlen(Callsign));
  swriteFile(h, #13#10, 2);

  CallsignFound:
  CloseHandle(h);
end;

function tsndPlaySound(lpszSoundName: PChar): BOOL;
begin
  Result := False;
{
  asm
    push lpszSoundName
    lea  eax,TR4W_PATH_NAME
    push eax
  end;
  wsprintf(WAVFileToPlay, TWO_STRINGS);
  asm add esp,16
  end;
}
  if not FileExists(lpszSoundName {WAVFileToPlay}) then Exit;
  if ActiveRadioPtr.tPTTStatus = PTT_OFF then PTTOn;
  Result := sndPlaySound(lpszSoundName {WAVFileToPlay}, SND_ASYNC or SND_NODEFAULT);
end;

function PlayWAVFile(f: PChar; DisplayError: boolean): PlayResult;
var
  Duration                              : Cardinal;
  WAVFile                               : PChar;
  countrtyId                            : DXMultiplierString;
  tempBuffer                            : array[0..255 + 64] of Char;
begin
  Result := prCantPlay;

  WAVFile := nil;

  if DVKLocalizedMessagesEnable then
    if CallWindowString <> '' then
    begin
      Windows.ZeroMemory(@countrtyId, SizeOf(countrtyId));
      countrtyId := ctyGetCountryID(CallWindowString);
      if (countrtyId <> '') then
      begin
        if (countrtyId[1] = 'U') and (countrtyId[2] = 'A') then countrtyId[3] := #0;

        WAVFile := GetRealPath(TR4W_DVKPATH, f, @countrtyId[1]);
      //ShowMessage(WAVFile);
        if not FileExists(WAVFile) then WAVFile := nil;
      end;
    end;

  if WAVFile = nil then
    WAVFile := GetRealPath(TR4W_DVKPATH, f, nil);

  if tGetWAVDurationFromHeader(WAVFile, Duration, DisplayError) then
  begin
    if tsndPlaySound(WAVFile) = False then
    begin
      if DisplayError then
        QuickDisplay(SysErrorMessage(GetLastError));
    end
    else
    begin
      tDVPTimerEventID := timeSetEvent(Duration, 0, TFNTimeCallBack(tDVP_Event), 0, TIME_CALLBACK_EVENT_SET);
      WaitForSingleObject(tDVP_Event, 30000);
      if tExitFromDVPThread then Result := prExitThread else Result := prOK;
    end;
  end;
end;

end.

