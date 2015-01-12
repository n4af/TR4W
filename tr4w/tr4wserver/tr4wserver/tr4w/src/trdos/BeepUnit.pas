unit BeepUnit;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  Windows;

procedure SpeakerBeep(Tone, Duration: Word);
procedure Sound(Freq: Word);
procedure NoSound;
procedure SetPort(Address, Value: Word);
function GetPort(Address: Word): Word;
procedure ntBeepInit;
procedure ntBeepClose;
procedure ntBeep(Freq, Duration: Cardinal);

type
  BEEP_SET_PARAMETERS = record
    Frequency, Duration: Cardinal;
  end;

const
  IOCTL_BEEP_SET                        = $10000;
  FileNameStr                           : array[0..9] of Char = '\\.\tr4w'#0;
  BeepFileName                          : PChar = @FileNameStr[0];
  DevName                               : PChar = @FileNameStr[3];
var
  hBeep                                 : HWND = INVALID_HANDLE_VALUE;
  OwnDevName                            : LongBool;

implementation

uses
  MainUnit,
  LogK1EA,
  LogRadio,
  Tree;

procedure SetPort(Address, Value: Word);
var
  bValue                                : Byte;
begin
  bValue := Trunc(Value and 255);
  asm
    mov dx, address
    mov al, bValue
    out dx, al
  end;
end;

function GetPort(Address: Word): Word;
var
  bValue                                : Byte;
begin
  asm
    mov dx, address
    in al, dx
    mov bValue, al
  end;
  GetPort := bValue;
end;

procedure Sound(Freq: Word);
var
  b                                     : Byte;
begin
  if Freq > 18 then
  begin
    Freq := Word(1193167 div LONGINT(Freq));
    b := Byte(GetPort($61));
    if (b and 3) = 0 then
    begin

      SetPort($61, Word(b or 3));
      SetPort($43, $B6);
    end;
    SetPort($42, Freq);
    SetPort($42, Freq shr 8);
  end;
end;

procedure NoSound;
var
  Value                                 : Word;
begin
  if WindowsOSversion = VER_PLATFORM_WIN32_WINDOWS then
  begin
    Value := GetPort($61) and $FC;
    SetPort($61, Value);
  end
  else
//    Windows.Beep(1, 1)
//ntBeep(30000, 40);
end;

procedure SpeakerBeep(Tone, Duration: Word);

begin
 // if Tone < 40 then Exit;
  if not BeepEnable then Exit;

  ntBeep(Tone, Duration);
  Sleep(Duration);
{
  Exit;

  if WindowsOSversion = VER_PLATFORM_WIN32_NT then
    Windows.Beep(Tone, Duration)

  else
  begin
    //if BeepEnable then
    Sound(Tone);
    Sleep(Duration);
    NoSound;
  end;
}
end;

procedure ntBeepInit;
begin
  OwnDevName := False;

  if WindowsOSversion = VER_PLATFORM_WIN32_WINDOWS then Exit;
  if QueryDosDevice(DevName, wsprintfBuffer, MAX_PATH) = 0 then
  begin
    //if not
    DefineDosDevice(DDD_RAW_TARGET_PATH, DevName, '\Device\Beep');
    //then ShowSysErrorMessage('GET SPEAKER');
    OwnDevName := True;

    hBeep := CreateFile(BeepFileName, GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
//    if hBeep = INVALID_HANDLE_VALUE then ShowSysErrorMessage('COMPUTER SPEAKER');
    ntBeep(32767 - 1, 1);
  end;
end;

procedure ntBeepClose;
begin
  if OwnDevName then DefineDosDevice(DDD_REMOVE_DEFINITION, DevName, nil);
  if hBeep <> INVALID_HANDLE_VALUE then CloseHandle(hBeep);
end;

procedure ntBeep(Freq, Duration: Cardinal);
var
  BeepSetParams                         : BEEP_SET_PARAMETERS;
  BytesReturned                         : Cardinal;
begin
  if hBeep = INVALID_HANDLE_VALUE then Exit;
  if Freq < 37 then Exit;
  if Freq > 32767 then Exit;
  BeepSetParams.Frequency := Freq;
  BeepSetParams.Duration := Duration;
//  if not
  DeviceIoControl(hBeep, IOCTL_BEEP_SET, @BeepSetParams, SizeOf(BEEP_SET_PARAMETERS), nil, 0, BytesReturned, nil);
//    then ShowSysErrorMessage('SET SPEAKER');
end;

end.
